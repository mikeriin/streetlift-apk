"""Contrôles des vrais APK/AAB : signature, manifeste, versions et bibliothèques natives."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import xml.etree.ElementTree as ET
import zipfile
from signing import BASE64_NAME, PASSWORD_NAME, ROOT, expected_certificate, verify_apk

ANDROID = '{http://schemas.android.com/apk/res/android}'
PACKAGE = 'fr.tchoupi.streetlift_tracker'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def run(command):
    env = {k: v for k, v in os.environ.items() if k not in (BASE64_NAME, PASSWORD_NAME)}
    result = subprocess.run([str(x) for x in command], env=env, capture_output=True, text=True, timeout=180)
    require(result.returncode == 0, f'Échec du contrôle : {Path(str(command[0])).name}.')
    return result.stdout


def manifest_info(xml, build_number, version_name):
    manifest = ET.fromstring(xml)
    require(manifest.tag == 'manifest', 'Manifeste final absent.')
    sdk, app = manifest.find('uses-sdk'), manifest.find('application')
    require(sdk is not None and app is not None, 'Manifeste final incomplet.')
    info = {
        'application_id': manifest.get('package'),
        'version_code': manifest.get(ANDROID + 'versionCode'),
        'version_name': manifest.get(ANDROID + 'versionName'),
        'min_sdk': sdk.get(ANDROID + 'minSdkVersion'),
        'target_sdk': sdk.get(ANDROID + 'targetSdkVersion'),
        'debuggable': app.get(ANDROID + 'debuggable', 'false'),
        'permissions': sorted(x.get(ANDROID + 'name') for x in manifest.findall('uses-permission')),
        'application_attributes': {k.removeprefix(ANDROID): v for k, v in app.attrib.items()},
        'components': [{'type': c.tag, 'name': c.get(ANDROID + 'name'),
                        'exported': c.get(ANDROID + 'exported', 'non spécifié')}
                       for c in app if c.tag in ('activity', 'activity-alias', 'service', 'receiver', 'provider')],
    }
    for key, expected in [('application_id', PACKAGE), ('version_code', str(build_number)),
                          ('version_name', version_name), ('min_sdk', '21'),
                          ('target_sdk', '36'), ('debuggable', 'false')]:
        require(info[key] == expected, f'Manifeste : {key} inattendu ({info[key]}).')
    return info


def elf_info(data, abi):
    require(len(data) >= 64 and data[:4] == b'\x7fELF' and data[5] == 1,
            'Bibliothèque ELF absente, tronquée ou encodage inconnu.')
    bits = {1: 32, 2: 64}.get(data[4])
    expected = {'armeabi-v7a': (32, 40), 'arm64-v8a': (64, 183), 'x86_64': (64, 62)}
    require(abi in expected and (bits, struct.unpack_from('<H', data, 18)[0]) == expected[abi],
            'ABI et en-tête ELF incohérents.')
    if bits == 64:
        offset = struct.unpack_from('<Q', data, 32)[0]
        size, count = struct.unpack_from('<HH', data, 54)
        fmt = '<IIQQQQQQ'
    else:
        offset = struct.unpack_from('<I', data, 28)[0]
        size, count = struct.unpack_from('<HH', data, 42)
        fmt = '<IIIIIIII'
    require(count > 0 and size >= struct.calcsize(fmt) and offset + size * count <= len(data),
            'Table de segments ELF invalide.')
    loads, relro, load_ranges = [], [], []
    for index in range(count):
        fields = struct.unpack_from(fmt, data, offset + size * index)
        if bits == 64:
            kind, _, position, virtual, _, file_size, memory_size, alignment = fields
        else:
            kind, position, virtual, _, file_size, memory_size, _, alignment = fields
        require(position + file_size <= len(data), 'Segment ELF tronqué.')
        if kind == 1:
            loads.append(alignment)
            load_ranges.append((virtual, virtual + memory_size))
            if bits == 64:
                require(alignment >= 16384 and alignment & (alignment - 1) == 0
                        and (virtual - position) % 16384 == 0, 'Segment LOAD non aligné 16 Ko.')
        if kind == 0x6474e552:
            relro.append((virtual, virtual + memory_size))
    require(loads, 'Aucun segment LOAD ELF.')
    relro_checks = []
    if bits == 64:
        # Prefix/suffix rules from Android PageAlignUtils, commit 7765a1e4.
        section_offset = struct.unpack_from('<Q', data, 40)[0]
        section_size, section_count = struct.unpack_from('<HH', data, 58)
        sections = []
        if section_count:
            require(section_size >= 64 and section_offset + section_size * section_count <= len(data),
                    'Table de sections ELF invalide.')
            for index in range(section_count):
                at = section_offset + index * section_size
                start = struct.unpack_from('<Q', data, at + 16)[0]
                length = struct.unpack_from('<Q', data, at + 32)[0]
                sections.append((start, start + length))
        load_ranges.sort()
        for start, end in relro:
            candidates = [i for i, load in enumerate(load_ranges) if load[0] <= start]
            require(candidates, 'Segment RELRO sans LOAD contenant.')
            index = candidates[-1]
            load_start, load_end = load_ranges[index]
            require(index + 1 == len(load_ranges) or end <= load_ranges[index + 1][0],
                    'RELRO chevauche le LOAD suivant.')
            in_load = [x for x in sections if load_start <= x[0] and x[1] <= load_end]
            in_relro = [x for x in sections if start <= x[0] and x[1] <= end]
            whole = bool(in_load) and in_load == in_relro
            prefix = start % 16384 == 0 or start == load_start
            suffix = end % 16384 == 0 or end == load_end
            require(whole or (prefix and suffix), 'Bornes RELRO incompatibles 16 Ko.')
            relro_checks.append({'start': start, 'end': end, 'whole_load_sections': whole,
                                 'prefix_or_aligned': prefix, 'suffix_or_aligned': suffix})
    return {'bits': bits, 'load_alignments': loads, 'relro_checks': relro_checks,
            'page_16k_check': 'réussi' if bits == 64 else 'non applicable à cette ABI 32 bits'}


def native_libraries(archive, bundle=False):
    prefix = 'base/lib/' if bundle else 'lib/'
    libraries = {}
    with zipfile.ZipFile(archive) as z:
        for entry in z.infolist():
            if entry.filename.startswith(prefix) and entry.filename.endswith('.so'):
                name = entry.filename.removeprefix(prefix)
                require(name not in libraries and len(name.split('/')) == 2, 'Bibliothèque dupliquée ou chemin invalide.')
                raw = z.read(entry)
                try:
                    checked = elf_info(raw, name.split('/')[0])
                except ValueError as error:
                    raise ValueError(f'{archive.name}, {name} : {error}') from None
                libraries[name] = {**checked, 'sha256': hashlib.sha256(raw).hexdigest()}
    require(libraries, 'Aucune bibliothèque native trouvée.')
    require({n.split('/')[0] for n in libraries} == {'armeabi-v7a', 'arm64-v8a', 'x86_64'}, 'Liste des ABI inattendue.')
    for abi in ('armeabi-v7a', 'arm64-v8a', 'x86_64'):
        require(f'{abi}/libflutter.so' in libraries and f'{abi}/libapp.so' in libraries, 'Bibliothèque Flutter/app manquante.')
    return libraries


def check(args):
    args.output.mkdir(parents=True, exist_ok=True)
    expected = expected_certificate(ROOT)
    version = re.search(r'^version:\s*([^+\s]+)', (ROOT / 'pubspec.yaml').read_text(), re.M)[1]
    tools = args.android_sdk / 'build-tools' / '36.0.0'
    analyzer = args.android_sdk / 'cmdline-tools/latest/bin/apkanalyzer'
    verify_apk(args.apk, tools / 'apksigner')  # Contrôle L1-R2 conservé.
    result = run(['java', ROOT / 'tools/VerifyBundleSignature.java', args.aab, expected])
    require(result == f'KT_AAB_CERT_V1 OK {expected}\n', 'Réponse du contrôle AAB invalide.')
    bundletool = ['java', '-jar', args.bundletool]
    run([*bundletool, 'validate', f'--bundle={args.aab}'])
    xml_apk = run([analyzer, 'manifest', 'print', args.apk])
    xml_aab = run([*bundletool, 'dump', 'manifest', f'--bundle={args.aab}', '--module=base'])
    (args.output / 'apk-manifest.xml').write_text(xml_apk)
    (args.output / 'aab-manifest.xml').write_text(xml_aab)
    apk_manifest = manifest_info(xml_apk, args.build_number, version)
    aab_manifest = manifest_info(xml_aab, args.build_number, version)
    require(apk_manifest['permissions'] == aab_manifest['permissions'], 'Permissions APK/AAB différentes.')
    config = run([*bundletool, 'dump', 'config', f'--bundle={args.aab}'])
    (args.output / 'aab-config.json').write_text(config)
    alignment = json.loads(config).get('optimizations', {}).get('uncompressNativeLibraries', {}).get('alignment')
    require(alignment == 'PAGE_ALIGNMENT_16K', 'L’AAB ne demande pas un alignement ZIP 16 Ko.')
    zipalign = run([tools / 'zipalign', '-v', '-c', '-P', '16', '4', args.apk])
    (args.output / 'apk-zipalign.txt').write_text(zipalign)
    apk_native, aab_native = native_libraries(args.apk), native_libraries(args.aab, bundle=True)
    require({k: v['sha256'] for k, v in apk_native.items()} == {k: v['sha256'] for k, v in aab_native.items()},
            'Bibliothèques APK/AAB différentes.')
    report = {'signature_certificate_sha256': expected, 'apk_manifest': apk_manifest,
              'aab_manifest': aab_manifest, 'native_libraries': apk_native,
              'aab_zip_alignment': alignment, 'apk_zipalign': 'réussi', 'bundle_structure': 'valide',
              'same_native_payloads': True, 'runtime_16k': 'non exécuté ; essai sur appareil/émulateur 16 Ko restant',
              'build_number': args.build_number, 'artifacts': {}}
    for artifact in (args.apk, args.aab):
        report['artifacts'][artifact.name] = {'size_bytes': artifact.stat().st_size,
                                             'sha256': hashlib.sha256(artifact.read_bytes()).hexdigest()}
    (args.output / 'android-artifacts.json').write_text(json.dumps(report, indent=2, ensure_ascii=False))
    print('OK : APK et AAB signés, identité/versions/manifeste vérifiés, alignements ZIP/ELF 16 Ko vérifiés.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('apk', 'aab', 'android-sdk', 'bundletool', 'output'):
        parser.add_argument('--' + name, type=Path, required=True)
    parser.add_argument('--build-number', type=int, required=True)
    args = parser.parse_args()
    try:
        check(args)
    except (ValueError, OSError, subprocess.SubprocessError, ET.ParseError, zipfile.BadZipFile) as error:
        parser.exit(1, f'Validation Android refusée : {error}\n')
