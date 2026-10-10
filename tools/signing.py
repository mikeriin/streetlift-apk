"""Restaure et contrôle la clé existante ; aucune génération de clé."""
import argparse
import base64
import binascii
import hashlib
import os
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
KEY_PATH = Path('signing/kalis_track.p12')
BASE64_NAME = 'KALIS_KEYSTORE_BASE64'
PASSWORD_NAME = 'KALIS_KEYSTORE_PASSWORD'


class SigningError(ValueError):
    pass


def secret_bytes(env):
    for name in (BASE64_NAME, PASSWORD_NAME):
        if not env.get(name):
            raise SigningError(f'Secret obligatoire absent : {name}. Release refusée.')
    encoded = env[BASE64_NAME].strip()
    if len(encoded) > 48_000:
        raise SigningError('KALIS_KEYSTORE_BASE64 dépasse la taille autorisée.')
    try:
        result = base64.b64decode(encoded, validate=True)
    except (ValueError, binascii.Error):
        raise SigningError('KALIS_KEYSTORE_BASE64 invalide : Base64 strict attendu.') from None
    if not result:
        raise SigningError('KALIS_KEYSTORE_BASE64 ne contient aucun keystore.')
    return result


def expected_certificate(root):
    expected = (root / 'signing/certificate.sha256').read_text().strip().lower()
    if not re.fullmatch(r'[0-9a-f]{64}', expected):
        raise SigningError('Référence publique certificate.sha256 invalide.')
    return expected


def keytool(path, env, operation):
    command = ['keytool', *operation, '-keystore', str(path), '-storetype', 'PKCS12',
               '-alias', 'kalis', '-storepass:env', PASSWORD_NAME]
    try:
        result = subprocess.run(command, env=env, capture_output=True, timeout=30)
    except FileNotFoundError:
        raise SigningError('keytool (Java 17) est nécessaire au contrôle de signature.') from None
    except subprocess.TimeoutExpired:
        raise SigningError('Le contrôle keytool a dépassé le délai autorisé.') from None
    if result.returncode:
        # Ne jamais recopier stdout/stderr : les outils tiers peuvent contenir des secrets.
        raise SigningError('Keystore illisible, mot de passe invalide, alias kalis absent '
                           'ou clé privée inaccessible. Release refusée.')
    return result.stdout


def verify_key(root, path, env):
    cert = keytool(path, env, ['-exportcert'])
    if hashlib.sha256(cert).hexdigest() != expected_certificate(root):
        raise SigningError('Certificat différent de la référence locale. Release refusée.')
    # Signer une requête en mémoire prouve l'accès à la clé privée existante.
    # Rien n'est généré comme nouvelle clé, écrit comme CSR ou envoyé à un service.
    keytool(path, env, ['-certreq', '-keypass:env', PASSWORD_NAME])


def verify_restored(root=ROOT, env=None):
    env = dict(os.environ if env is None else env)
    raw = secret_bytes(env)
    path = root / KEY_PATH
    if path.is_symlink() or not path.is_file():
        raise SigningError('Clé locale absente ou lien interdit. Exécuter tools/signing.py restore.')
    if path.read_bytes() != raw:
        raise SigningError('Clé locale différente de KALIS_KEYSTORE_BASE64. Release refusée.')
    verify_key(root, path, env)


def restore(root=ROOT, env=None):
    env = dict(os.environ if env is None else env)
    raw = secret_bytes(env)
    target = root / KEY_PATH
    if target.parent.is_symlink() or target.is_symlink():
        raise SigningError('Restauration refusée : lien symbolique dans le chemin de signature.')
    target.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix='.restore-', dir=target.parent)
    temporary = Path(name)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(raw)
        verify_key(root, temporary, env)
        # Une copie locale différente ne doit pas être écrasée, même par un secret valide.
        if target.exists() and target.read_bytes() != raw:
            raise SigningError('Une autre copie locale existe. Conservation de cette copie ; restauration refusée.')
        temporary.replace(target)
    finally:
        temporary.unlink(missing_ok=True)


def verify_apk(apk, apksigner, root=ROOT):
    """Vérification directe par l'API du JAR SDK, sans lire les messages apksigner."""
    expected = expected_certificate(root)
    apk = Path(apk).resolve()
    jar = Path(apksigner).resolve().parent / 'lib/apksigner.jar'
    helper = (root / 'tools/VerifyApkCertificate.java').resolve()
    if not apk.is_file():
        raise SigningError('APK absent ou illisible. Aucun APK publié.')
    if not jar.is_file():
        raise SigningError('Bibliothèque SDK lib/apksigner.jar introuvable auprès de l’outil sélectionné. Aucun APK publié.')
    if not helper.is_file():
        raise SigningError('Contrôleur tools/VerifyApkCertificate.java absent. Aucun APK publié.')
    # Aucun secret de signature nécessaire ni transmis au lecteur de certificat.
    env = {name: value for name, value in os.environ.items()
           if name not in (BASE64_NAME, PASSWORD_NAME)}
    try:
        result = subprocess.run(
            ['java', '--class-path', str(jar), str(helper), str(apk), expected],
            env=env, capture_output=True, text=True, timeout=60)
    except FileNotFoundError:
        raise SigningError('Java 17 avec compilateur est nécessaire au contrôle APK. Aucun APK publié.') from None
    except subprocess.TimeoutExpired:
        raise SigningError('Le contrôle du certificat APK a dépassé le délai autorisé. Aucun APK publié.') from None
    # Protocole propre au projet, indépendant des messages et de la langue du SDK.
    # Un code nul seul ne suffit jamais ; stdout/stderr externes restent privés.
    success = re.fullmatch(r'KT_APK_CERT_V1 OK ([0-9a-f]{64})\r?\n', result.stdout)
    mismatch = re.fullmatch(
        r'KT_APK_CERT_V1 MISMATCH ([0-9a-f]{64}(?:,[0-9a-f]{64})*)\r?\n', result.stdout)
    if result.returncode == 0 and success and success[1] == expected:
        print(f'OK : API apksig, signature vérifiée ; identité unique ; SHA-256 public : {expected}.')
        return
    if result.returncode == 1 and mismatch:
        raise SigningError('Certificat APK différent de la référence locale. Aucun APK publié. '
                           f'SHA-256 attendu (public) : {expected} ; '
                           f'SHA-256 observé(s) (publics) : {mismatch[1]}.')
    status = re.fullmatch(r'KT_APK_CERT_V1 (CRYPTO|SIGNERS|ROTATION|TOOL)\r?\n', result.stdout)
    messages = {
        'CRYPTO': 'La vérification cryptographique de l’APK a échoué.',
        'SIGNERS': 'APK refusé : exactement un signataire est requis.',
        'ROTATION': 'APK refusé : rotation de certificat non autorisée dans L1.',
        'TOOL': 'Contrôle APK impossible : fichier invalide ou API SDK incompatible.',
    }
    if result.returncode == 1 and status:
        raise SigningError(messages[status[1]] + ' Aucun APK publié.')
    raise SigningError('Contrôleur APK Java indisponible ou réponse invalide '
                       '(Java 17 avec compilateur et API apksig requis). Aucun APK publié.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('restore')
    apk = sub.add_parser('apk')
    apk.add_argument('apk', type=Path)
    apk.add_argument('apksigner', type=Path)
    args = parser.parse_args()
    try:
        if args.command == 'restore':
            restore()
            print('OK : clé existante restaurée ; accès privé et certificat local vérifiés.')
        else:
            verify_apk(args.apk, args.apksigner)
            print('OK : signature de l’APK vérifiée et certificat égal à la référence locale.')
    except (SigningError, OSError, subprocess.TimeoutExpired) as error:
        message = str(error) if isinstance(error, SigningError) else 'Échec du contrôle de signature (outil ou fichier inaccessible).'
        parser.exit(1, message + '\n')


if __name__ == '__main__':
    main()
