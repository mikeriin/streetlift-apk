#!/usr/bin/env python3
"""Contrôle des jetons de la refonte UI (cahier UI §6.1, lot UI0).

Compte, fichier par fichier de ``lib/`` (hors ``lib/kit/`` et hors liste
blanche), les valeurs de présentation écrites en dur au lieu des jetons et
des composants du kit :

- ``fontSize``, ``fontWeight``, ``letterSpacing`` littéraux ;
- ``Color(0x…)`` / ``Color.fromARGB(…)`` / ``Color.fromRGBO(…)`` ;
- ``BorderRadius.circular(n)`` / ``Radius.circular(n)`` avec un nombre ;
- ``EdgeInsets`` (et ``EdgeInsetsDirectional``) construits avec un nombre ;
- ``Card(`` et ``BoxDecoration(`` bruts ;
- ``toUpperCase()`` (capitales par le style seulement, U3) ;
- avec ``--menus`` : ``PopupMenuButton``, ``showModalBottomSheet``,
  ``showDialog`` directs (gabarits du cahier §4.5).

Usage :
  python3 tools/check_ui_tokens.py                 # relevé complet (n'échoue pas)
  python3 tools/check_ui_tokens.py --zone UI1      # fichiers de UI1 : échoue si > 0
  python3 tools/check_ui_tokens.py --zone UI1 --menus
  python3 tools/check_ui_tokens.py --baseline tools/ui_tokens_depart.json
  python3 tools/check_ui_tokens.py --json          # relevé lisible par une machine

Zones : cahier UI §7.2 (propriété des fichiers). Un fichier hors zone et hors
liste blanche revient à UI5. Les commentaires sont ignorés ; les chaînes
aussi (un libellé qui contient « fontSize » ne compte pas).
"""
from __future__ import annotations

import argparse
import fnmatch
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / 'lib'

# Cahier §7.2. Motifs relatifs à lib/.
ZONES: dict[str, list[str]] = {
    'UI0': [
        'kit/**', 'app_theme.dart', 'ui.dart', 'main.dart', 'nav_bar.dart',
        'motion.dart', 'filter_menu.dart', 'search.dart', 'alerts.dart',
        'store_widget.dart',
    ],
    'UI1': [
        'home_screen.dart', 'program_screens.dart', 'program_explainer.dart',
        'program_origin.dart', 'resume_banner.dart', 'levelup.dart',
        'plan/season_view.dart', 'plan/event_day_screen.dart',
        'plan/evolution_widgets.dart', 'plan/plan_sheets.dart',
        'plan/program_position.dart', 'koach/koach_home_card.dart',
        'koach/koach_bubble.dart',
    ],
    'UI2': [
        'session_screen.dart', 'session_host.dart', 'session_history.dart',
        'set_validation.dart', 'estimate_view.dart', 'rewards.dart', 'adapt/**',
    ],
    'UI3': [
        'stats_*.dart', 'progression_screen.dart', 'records_screen.dart',
        'game_widgets.dart',
    ],
    'UI4': [
        'settings_screen.dart', 'notification_settings.dart', 'data_control.dart',
        'pilotage_screen.dart', 'wellbeing_screens.dart',
        'retired_notice_screen.dart', 'startup.dart', 'arsenal_screen.dart',
        'exercise_screens.dart', 'atlas.dart', 'anatomy_screen.dart',
        'athlete_profile*.dart', 'profile_completion.dart',
        'settings_search.dart', 'guided_tests.dart', 'program_start.dart',
        'plan/plan_screens.dart', 'plan/plan_creation.dart',
        'koach/koach_gallery_screen.dart',
    ],
}

# Le kit lui-même : seul endroit où vivent les valeurs (jamais compté).
KIT = ['kit/**']

# Liste blanche (cahier §6.1, §7.2) : illustrations, peintres de données,
# mannequin et moteur 3D, outils du mode dev.
WHITELIST = [
    'brand.dart', 'koach/koach_view.dart', 'koach/flame_icon.dart',
    'muscle_body.dart', 'muscle_map_2d.dart', 'muscle_map_regions.dart',
    'mannequin*.dart', 'engine3d.dart', 'exercise_mannequin.dart',
    'mixamo_skeleton.dart', 'pose_*.dart', 'dev/**', 'plan/plan_inspector.dart',
    'animation_test_screen.dart',
]

CRITERIA = [
    'fontSize', 'fontWeight', 'letterSpacing', 'couleur', 'rayon',
    'EdgeInsets', 'Card', 'BoxDecoration', 'toUpperCase',
]
MENU_CRITERIA = ['PopupMenuButton', 'showModalBottomSheet', 'showDialog']

_NUM = r'-?\d+(?:\.\d+)?'
SIMPLE = {
    'fontSize': re.compile(r'\bfontSize\s*:\s*' + _NUM + r'\b'),
    'fontWeight': re.compile(r'\bfontWeight\s*:\s*(?:const\s+)?FontWeight\.(?:w\d00|bold|normal)\b'),
    'letterSpacing': re.compile(r'\bletterSpacing\s*:\s*' + _NUM + r'\b'),
    'couleur': re.compile(r'\bColor\s*\(\s*0x[0-9A-Fa-f]+\s*\)|\bColor\.from(?:ARGB|RGBO)\s*\('),
    'rayon': re.compile(r'\b(?:BorderRadius|Radius)\.circular\s*\(\s*' + _NUM + r'\s*\)'),
    'Card': re.compile(r'(?<![\w.])Card\s*\('),
    'BoxDecoration': re.compile(r'(?<![\w.])BoxDecoration\s*\('),
    'toUpperCase': re.compile(r'\.toUpperCase\s*\(\s*\)'),
    'PopupMenuButton': re.compile(r'(?<![\w.])PopupMenuButton\b'),
    'showModalBottomSheet': re.compile(r'(?<![\w.])showModalBottomSheet\b'),
    'showDialog': re.compile(r'(?<![\w.])showDialog\b'),
}
_EDGE = re.compile(r'(?<![\w.])EdgeInsets(?:Directional)?\.(\w+)\s*\(')
_DIGIT = re.compile(r'(?<![\w.])\d')


def strip_code(text: str) -> str:
    """Remplace commentaires et contenus de chaînes par des espaces (les
    numéros de ligne sont conservés)."""
    out = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if text.startswith('//', i):
            j = text.find('\n', i)
            j = n if j < 0 else j
            out.append(' ' * (j - i))
            i = j
        elif text.startswith('/*', i):
            j = text.find('*/', i + 2)
            j = n if j < 0 else j + 2
            out.append(re.sub(r'[^\n]', ' ', text[i:j]))
            i = j
        elif c in '\'"':
            raw = i > 0 and text[i - 1] == 'r'
            triple = text.startswith(c * 3, i)
            q = c * 3 if triple else c
            j = i + len(q)
            while j < n:
                if not raw and text[j] == '\\':
                    j += 2
                    continue
                if text.startswith(q, j):
                    break
                if not triple and text[j] == '\n':
                    break
                j += 1
            j = min(n, j + len(q))
            body = text[i + len(q):j - len(q)]
            # Les interpolations restent du code ; le reste devient blanc.
            body = re.sub(r'\$\{[^}]*\}', lambda m: m.group(0), body)
            out.append(q + re.sub(r'[^\n$]', ' ', body) + q if j - i >= 2 * len(q) else text[i:j])
            i = j
        else:
            out.append(c)
            i += 1
    return ''.join(out)


def _edge_hits(code: str) -> list[int]:
    hits = []
    for m in _EDGE.finditer(code):
        if m.group(1) == 'zero':
            continue
        depth, j = 1, m.end()
        while j < len(code) and depth:
            if code[j] == '(':
                depth += 1
            elif code[j] == ')':
                depth -= 1
            j += 1
        if _DIGIT.search(code[m.end():j - 1]):
            hits.append(code.count('\n', 0, m.start()) + 1)
    return hits


def scan_text(text: str, menus: bool = False) -> dict[str, list[int]]:
    code = strip_code(text)
    found: dict[str, list[int]] = {}
    names = CRITERIA + (MENU_CRITERIA if menus else [])
    for name in names:
        if name == 'EdgeInsets':
            lines = _edge_hits(code)
        else:
            lines = [code.count('\n', 0, m.start()) + 1 for m in SIMPLE[name].finditer(code)]
        if lines:
            found[name] = lines
    return found


def _match(rel: str, patterns: list[str]) -> bool:
    for p in patterns:
        if p.endswith('/**'):
            if rel.startswith(p[:-3] + '/'):
                return True
        elif fnmatch.fnmatchcase(rel, p):
            return True
    return False


def zone_of(rel: str) -> str:
    if _match(rel, KIT):
        return 'kit'
    if _match(rel, WHITELIST):
        return 'liste blanche'
    for z, pats in ZONES.items():
        if _match(rel, pats):
            return z
    return 'UI5'


def scan(lib: Path = LIB, menus: bool = False) -> dict[str, dict]:
    report = {}
    for path in sorted(lib.rglob('*.dart')):
        rel = path.relative_to(lib).as_posix()
        zone = zone_of(rel)
        if zone in ('kit', 'liste blanche'):
            continue
        found = scan_text(path.read_text(encoding='utf-8'), menus=menus)
        report[rel] = {
            'zone': zone,
            'total': sum(len(v) for v in found.values()),
            'detail': {k: len(v) for k, v in found.items()},
            'lignes': found,
        }
    return report


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--zone', help='lot dont les fichiers doivent être à 0 (UI0 à UI4, ou UI5 = tout lib/)')
    ap.add_argument('--menus', action='store_true', help='compter aussi les menus hors gabarit')
    ap.add_argument('--baseline', type=Path, help='écrire le relevé par fichier (JSON) dans ce fichier')
    ap.add_argument('--json', action='store_true', help='relevé JSON sur la sortie standard')
    ap.add_argument('--lib', type=Path, default=LIB, help=argparse.SUPPRESS)
    args = ap.parse_args(argv)

    report = scan(args.lib, menus=args.menus)
    if args.baseline:
        data = {rel: {'zone': r['zone'], 'total': r['total'], **r['detail']} for rel, r in report.items()}
        args.baseline.write_text(json.dumps(data, indent=1, ensure_ascii=False, sort_keys=True) + '\n', encoding='utf-8')
    if args.json:
        print(json.dumps(report, indent=1, ensure_ascii=False))
    else:
        by_zone: dict[str, int] = {}
        for r in report.values():
            by_zone[r['zone']] = by_zone.get(r['zone'], 0) + r['total']
        print('Relevé des valeurs écrites en dur (cahier UI §6.1)' + (' et des menus hors gabarit' if args.menus else ''))
        for z in sorted(by_zone):
            print(f'  {z} : {by_zone[z]}')
        print(f'  total : {sum(by_zone.values())}')

    if not args.zone:
        return 0
    zone = args.zone.upper()
    if zone != 'UI5' and zone not in ZONES:
        print(f'zone inconnue : {args.zone}', file=sys.stderr)
        return 2
    failing = {rel: r for rel, r in report.items() if r['total'] and (zone == 'UI5' or r['zone'] == zone)}
    print(f'\nZone {zone} : {sum(r["total"] for r in failing.values())} valeur(s) à remplacer'
          + (f' dans {len(failing)} fichier(s)' if failing else ''))
    for rel, r in failing.items():
        for crit, lines in r['lignes'].items():
            print(f'  lib/{rel} : {crit} ×{len(lines)} (lignes {", ".join(map(str, lines[:12]))}{"…" if len(lines) > 12 else ""})')
    return 1 if failing else 0


if __name__ == '__main__':
    sys.exit(main())
