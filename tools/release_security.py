"""Barrières de livraison KT-001. Les diagnostics ne reproduisent jamais le contenu."""
import base64
import binascii
from pathlib import PurePosixPath
from pathlib import Path
import re
import stat
import subprocess
import zipfile

# CI1 (dev6.9.0) : 30 Mo (au lieu de 25) — les moteurs calibrés du pipeline
# CP (`kalis_plan` 0.2, `kalis_adapt` 0.2, `kalis_core` 0.4.2, récupérés par
# étiquette avec leurs tests et leur documentation) portent l'arbre hors
# ressources chiffrées à environ 25,1 Mo. Limite de taille, pas de contenu :
# les contrôles de secrets, de fichiers exclus et de modèles en clair sont
# inchangés.
LIMIT = 30_000_000
# M6c : ressources sous licence chiffrées (`assets_secure/*.enc` : personnage
# Mixamo, mannequin d'exécution, écorché acheté) comptées à part, dans leur
# propre budget ; le reste de l'arbre garde sa limite (30 Mo depuis CI1).
SECURE_LIMIT = 60_000_000
# M6c : aucun modèle 3D suivi en clair (ressources sous licence : chiffrées
# dans assets_secure/, déchiffrées par la CI avec le secret KT_ASSETS_KEY).
MODEL_SUFFIXES = {'.glb', '.gltf', '.fbx', '.fsceneb', '.obj', '.blend', '.dae'}
CACHE_DIRS = {'.dart_tool', 'build', '.gradle', '__pycache__', '.git', '.idea',
              '.pub-cache', '.pub', 'node_modules'}
LOCAL_FILES = {'local.properties', '.flutter-plugins', '.flutter-plugins-dependencies',
               'key.properties', 'keystore.properties', 'gradle.properties.local', '.DS_Store'}
PRIVATE_SUFFIXES = {'.p12', '.pfx', '.jks', '.keystore', '.key'}
ARTIFACT_SUFFIXES = {'.apk', '.aab', '.apks', '.zip', '.7z', '.tar', '.tgz', '.pyc', '.class'}


class PackagingError(ValueError):
    pass


def secure_asset(path):
    """M6c : ressource chiffrée de `assets_secure/` (budget à part)."""
    path = PurePosixPath(path)
    return len(path.parts) == 2 and path.parts[0] == 'assets_secure' and path.suffix == '.enc'


def clear_model(path):
    """M6c : modèle 3D en clair (interdit dans l'arbre suivi)."""
    return PurePosixPath(path).suffix.lower() in MODEL_SUFFIXES


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
    if path.stat().st_size > LIMIT + SECURE_LIMIT:
        raise PackagingError('ZIP supérieur à 85 000 000 octets.')
    names = set()
    total = secure = 0
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
            if clear_model(relative):
                raise PackagingError(f'Modèle 3D en clair interdit : {relative}.')
            if secure_asset(relative):
                secure += entry.file_size
                if secure > SECURE_LIMIT:
                    raise PackagingError('Ressources chiffrées supérieures à 60 000 000 octets.')
                continue
            total += entry.file_size
            if total > LIMIT:
                raise PackagingError('Contenu extrait supérieur à 30 000 000 octets.')
            check_content(relative, archive.read(entry))
        if archive.testzip() is not None:
            raise PackagingError('CRC du ZIP invalide.')
    return len(names), total


def tracked_files(root):
    """M4c : fichiers suivis par git sous [root] (arbre du dépôt), chemins relatifs.

    Hors dépôt git (copie extraite d'un artefact), tous les fichiers du dossier."""
    root = Path(root)
    try:
        listing = subprocess.run(['git', 'ls-files', '-z', '--cached'], cwd=root, check=True,
                                 capture_output=True).stdout
    except (OSError, subprocess.CalledProcessError):
        return sorted(p.relative_to(root) for p in root.rglob('*')
                      if (p.is_file() or p.is_symlink()) and '.git' not in p.relative_to(root).parts)
    return sorted(Path(name) for name in listing.decode('utf-8').split('\0') if name)


def check_tree(root, files=None):
    """M4c : les contrôles de livraison appliqués à l'arbre du dépôt, fichier par fichier.

    Refuse tout fichier suivi que la livraison exclurait (clé, secret local,
    cache, artefact, ZIP), tout lien symbolique, tout contenu secret (même
    renommé ou encodé) et un arbre de plus de 30 Mo (25 avant CI1). M6c : tout modèle 3D en
    clair ; ressources chiffrées de assets_secure/ (en-tête OpenSSL exigé)
    dans un budget à part de 60 Mo."""
    root = Path(root)
    files = tracked_files(root) if files is None else [Path(f) for f in files]
    total = secure = 0
    for relative in files:
        path = root / relative
        if path.is_symlink():
            raise PackagingError(f'Lien symbolique interdit : {relative.as_posix()}.')
        if excluded(PurePosixPath(relative.as_posix())):
            raise PackagingError(f'Fichier local, secret ou artefact suivi : {relative.as_posix()}.')
        if clear_model(relative.as_posix()):
            raise PackagingError(f'Modèle 3D suivi en clair (ressource sous licence : à chiffrer '
                                 f'dans assets_secure/) : {relative.as_posix()}.')
        if not path.is_file():
            continue  # supprimé de la copie de travail, pas encore du dépôt
        data = path.read_bytes()
        if secure_asset(relative.as_posix()):
            if data[:8] != b'Salted__':
                raise PackagingError(f'Ressource de assets_secure/ non chiffrée : {relative.as_posix()}.')
            secure += len(data)
            if secure > SECURE_LIMIT:
                raise PackagingError('Ressources chiffrées supérieures à 60 000 000 octets.')
            continue
        total += len(data)
        if total > LIMIT:
            raise PackagingError('Arbre du dépôt supérieur à 30 000 000 octets.')
        check_content(PurePosixPath(relative.as_posix()), data)
    return len(files), total + secure
