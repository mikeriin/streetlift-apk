"""Barrières de livraison KT-001. Les diagnostics ne reproduisent jamais le contenu."""
import base64
import binascii
from pathlib import PurePosixPath
import re
import stat
import zipfile

LIMIT = 25_000_000
CACHE_DIRS = {'.dart_tool', 'build', '.gradle', '__pycache__', '.git', '.idea',
              '.pub-cache', '.pub', 'node_modules'}
LOCAL_FILES = {'local.properties', '.flutter-plugins', '.flutter-plugins-dependencies',
               'key.properties', 'keystore.properties', 'gradle.properties.local', '.DS_Store'}
PRIVATE_SUFFIXES = {'.p12', '.pfx', '.jks', '.keystore', '.key'}
ARTIFACT_SUFFIXES = {'.apk', '.aab', '.apks', '.zip', '.7z', '.tar', '.tgz', '.pyc', '.class'}


class PackagingError(ValueError):
    pass


def excluded(path):
    parts = [part.lower() for part in path.parts]
    name = parts[-1]
    return (bool(set(parts) & CACHE_DIRS) or name in LOCAL_FILES
            or name == '.env' or name.startswith('.env.')
            or path.suffix.lower() in PRIVATE_SUFFIXES | ARTIFACT_SUFFIXES
            or ('signing' in parts and path.as_posix() != 'signing/certificate.sha256'))


def private_container(data):
    # JKS/JCEKS ou structure PKCS#12 (version 3, ContentInfo PKCS#7).
    if data[:4] in (bytes.fromhex('feedfeed'), bytes.fromhex('cececece')):
        return True
    return (data[:1] == b'\x30' and b'\x02\x01\x03\x30' in data[:16]
            and bytes.fromhex('06092a864886f70d0107') in data[:40])


def check_content(path, data):
    label = path.as_posix()
    reason = None
    if private_container(data):
        reason = 'conteneur de clé privée, même renommé'
    text = data.decode('utf-8', errors='replace')
    if re.search(r'-----BEGIN (?:[A-Z0-9]+ )*PRIVATE KEY-----', text):
        reason = 'clé privée PEM'
    # Affectations littérales, fichiers properties/YAML/JSON et anciens replis Gradle/Actions.
    for line in text.splitlines():
        if not re.search(r'(?i)(?:storePassword|keyPassword|(?:keystore[_-]?)?password)', line):
            continue
        literal = re.search(r'''(?ix)(?:storePassword|keyPassword|(?:keystore[_-]?)?password)["']?\s*[:=]\s*["']([^"']+)["']''', line)
        property_value = re.search(r'(?i)^\s*(?:storePassword|keyPassword|(?:keystore[_-]?)?password)\s*=\s*([^\s]+)', line)
        fallback = re.search(r'''(?:\?:|\|\|)\s*["'][^"']+["']''', line)
        env_default = re.search(r'''(?i)(?:get|setdefault)\(\s*["'][^"']*password["']\s*,\s*["'][^"']+["']''', line)
        if literal or fallback or env_default or (property_value and path.suffix.lower() == '.properties'):
            reason = 'mot de passe littéral ou valeur de secours'
    # Copies Base64 de keystores, y compris blocs répartis sur plusieurs lignes.
    for match in re.finditer(r'(?:[A-Za-z0-9+/]{40,}[\r\n]*)+[=]{0,2}', text):
        try:
            decoded = base64.b64decode(''.join(match.group().split()), validate=True)
        except (ValueError, binascii.Error):
            continue
        if private_container(decoded):
            reason = 'conteneur de clé encodé en Base64'
    if reason:
        raise PackagingError(f'Livraison refusée : {label} ({reason}).')


def check_archive(path):
    if path.stat().st_size > LIMIT:
        raise PackagingError('ZIP supérieur à 25 000 000 octets.')
    names = set()
    total = 0
    with zipfile.ZipFile(path) as archive:
        for entry in archive.infolist():
            p = PurePosixPath(entry.filename)
            if (not p.parts or p.parts[0] != 'streetlift_tracker' or len(p.parts) < 2
                    or '..' in p.parts or '\\' in entry.filename or p.is_absolute()
                    or entry.filename in names):
                raise PackagingError('Chemin ZIP invalide, doublon ou racine incorrecte.')
            names.add(entry.filename)
            if stat.S_ISLNK(entry.external_attr >> 16):
                raise PackagingError('Lien symbolique interdit dans le ZIP.')
            if entry.is_dir():
                continue
            relative = PurePosixPath(*p.parts[1:])
            if excluded(relative):
                raise PackagingError(f'Fichier local ou secret interdit : {relative}.')
            total += entry.file_size
            if total > LIMIT:
                raise PackagingError('Contenu extrait supérieur à 25 000 000 octets.')
            check_content(relative, archive.read(entry))
        if archive.testzip() is not None:
            raise PackagingError('CRC du ZIP invalide.')
    return len(names), total
