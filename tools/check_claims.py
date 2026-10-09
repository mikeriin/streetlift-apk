"""L13 (KT-074) : recherche automatique des allégations interdites.

Kalis Track est une application de bien-être et d'entraînement. Aucun texte
affiché ne doit promettre un résultat, soigner, traiter, prévenir une maladie
ou poser un diagnostic. Ce contrôle parcourt :
- les chaînes de caractères des fichiers Dart de `lib/` (textes affichés) ;
- les textes des données embarquées (`assets/**/*.json(.gz)`, `assets/**/*.md`).

La liste des termes est documentée dans `docs/CONTRAT_L13.md` §5. Une
occurrence n'est tolérée que si la phrase est une négation ou un renvoi vers
un professionnel (liste `ALLOWED` : motif exact, jamais un fichier entier).

Usage : python3 tools/check_claims.py  (code de sortie 1 si une allégation
est trouvée).
"""
from pathlib import Path
import gzip
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

# Termes interdits (expressions régulières, insensibles à la casse).
FORBIDDEN = {
    'guérison': r'\bgu[ée]ri(r|t|son|ssent|sse)?\b',
    'soigner': r'\bsoign(er|e|ent|ez)\b',
    'traitement': r'\btraitements?\b',
    'traiter une maladie': r'\btrait(er|e|ent)\s+(une?|la|les|ta|ton|tes)\s+(maladie|douleur|blessure|pathologie|tendinite|hernie)',
    'thérapie': r'\bth[ée]rap(ie|ies|eutique|eutiques)\b',
    'rééducation': r'\br[ée][ée]ducation\b',
    'réadaptation': r'\br[ée]adaptation\b',
    'kinésithérapie (programme)': r'\bprogramme\s+de\s+kin[ée]',
    'diagnostic': r'\bdiagnosti(c|cs|quer|que)\b',
    'prévenir les blessures': r'\bpr[ée]v(enir|ient|iennent|ention)\s+(des|les)\s+blessures\b',
    'anti-blessure': r'\banti[- ]blessures?\b',
    'prévention d\'une maladie': r'\bpr[ée]vention\s+(de|des|du)\s+(maladies?|diab[èe]te|cancers?|hypertension)',
    'résultat garanti': r'\bgaranti(e|s|es)?\b',
    'promesse de perte de poids': r'\b(perdre|perte\s+de)\s+(du\s+)?poids\b',
    'brûler les graisses': r'\bbr[ûu]l(er|e)\s+(les\s+|la\s+|des\s+)?graisses?\b',
    'cliniquement / médicalement prouvé': r'\b(cliniquement|m[ée]dicalement)\s+(prouv|test|valid|approuv)',
    'dispositif médical (allégation)': r'\best\s+un\s+dispositif\s+m[ée]dical\b',
    'renforce l\'immunité': r'\bimmunit[ée]\b',
    'soulager la douleur': r'\bsoulag(er|e|ent)\b',
}

# Occurrences tolérées : négations et renvois (motif exact dans la phrase).
ALLOWED = [
    r'aucun diagnostic',
    r'pas de diagnostic',
    r'ni diagnostic',
    r'sans diagnostic',
    r'ne pose (aucun|pas de) diagnostic',
    r'n[’\']est pas un dispositif médical',
    r'aucun traitement',
    r'ni traitement',
    r'ne remplace (pas|aucun)',
    r'aucune promesse',
    r'aucun résultat (n[’\']est )?garanti',
    r'rien n[’\']est garanti',
    r'sans garantie',
    r'n[’\']est pas garanti',
    r'ne (sont|est) pas garanti',
    r'objectif de poids',
    r'aucun objectif de (perte de )?poids',
]

STRING = re.compile(r"'((?:[^'\\\n]|\\.)*)'|\"((?:[^\"\\\n]|\\.)*)\"")


def dart_strings(text):
    """Chaînes littérales d'un fichier Dart (commentaires ignorés). Les
    littéraux adjacents (`'a ' 'b'`, sur une ou plusieurs lignes) sont
    concaténés, comme le fait Dart, pour juger la phrase entière."""
    lines = [
        '' if l.lstrip().startswith(('//', 'import ', 'export ', 'part ')) else l
        for l in text.split('\n')
    ]
    code = '\n'.join(lines)
    out = []
    last_end = None
    for m in STRING.finditer(code):
        s = m.group(1) if m.group(1) is not None else m.group(2)
        n = code.count('\n', 0, m.start()) + 1
        if last_end is not None and code[last_end:m.start()].strip() == '' and out:
            out[-1] = (out[-1][0], out[-1][1] + s)
        else:
            out.append((n, s))
        last_end = m.end()
    return [(n, s) for n, s in out if s]


# Textes des données embarquées figées (empreinte contrôlée par les tests
# LC1/LC1b) corrigés à l'affichage par `kWellnessWording` (lib/models.dart).
CORRECTED_AT_DISPLAY = {
    'Ischios : assurance anti-blessure sur le squat lourd.',
}


def json_strings(value, path=''):
    if isinstance(value, str):
        yield path, value
    elif isinstance(value, dict):
        for k, v in value.items():
            yield from json_strings(v, f'{path}.{k}')
    elif isinstance(value, list):
        for i, v in enumerate(value):
            yield from json_strings(v, f'{path}[{i}]')


def texts(root=ROOT):
    for path in sorted((root / 'lib').rglob('*.dart')):
        for n, s in dart_strings(path.read_text(encoding='utf-8')):
            yield f'{path.relative_to(root)}:{n}', s
    for path in sorted((root / 'assets').rglob('*')):
        rel = path.relative_to(root)
        if path.name.endswith('.json.gz'):
            data = json.loads(gzip.decompress(path.read_bytes()))
        elif path.suffix == '.json':
            data = json.loads(path.read_text(encoding='utf-8'))
        elif path.suffix == '.md':
            for n, line in enumerate(path.read_text(encoding='utf-8').split('\n'), 1):
                yield f'{rel}:{n}', line
            continue
        else:
            continue
        for p, s in json_strings(data):
            yield f'{rel}{p}', s


def allowed(sentence):
    return any(re.search(a, sentence, re.I) for a in ALLOWED)


def scan(root=ROOT, items=None):
    """Liste (emplacement, terme, texte) des allégations trouvées."""
    found = []
    for where, s in (items if items is not None else texts(root)):
        if items is None and s in CORRECTED_AT_DISPLAY:
            continue
        # Découpe en phrases pour que la tolérance reste locale.
        for sentence in re.split(r'(?<=[.!?;:])\s+|\n', s):
            if allowed(sentence):
                continue
            for label, rx in FORBIDDEN.items():
                if re.search(rx, sentence, re.I):
                    found.append((where, label, sentence.strip()[:160]))
    return found


def main():
    found = scan()
    for where, label, text in found:
        print(f'{where} : « {label} » → {text}')
    if found:
        print(f'{len(found)} allégation(s) à corriger.')
        return 1
    print('OK : aucune allégation interdite dans lib/ et assets/.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
