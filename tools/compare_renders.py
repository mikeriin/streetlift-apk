#!/usr/bin/env python3
"""L6 — Compare deux dossiers de rendus Flutter de test, pixel à pixel.

Usage :
    python3 tools/compare_renders.py DOSSIER_AVANT DOSSIER_APRES [--prefix-avant apres_] [--prefix-apres l6_]

Les fichiers sont appariés par nom, préfixe de lot retiré (« apres_x.png »
et « l6_x.png » → « x.png »). Pour chaque paire : identique, taille
différente, ou nombre de pixels différents et rectangle qui les contient.
Nécessite Pillow (`pip install pillow`). Code de sortie 0 si toutes les
paires sont identiques, 1 sinon (une différence n'est pas forcément une
régression : l'horloge affichée, par exemple, change d'une exécution à
l'autre ; chaque différence doit être examinée).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path


def _key(name: str, prefixes: tuple[str, ...]) -> str:
    for prefix in prefixes:
        if prefix and name.startswith(prefix):
            return name[len(prefix):]
    return name


def compare(before: Path, after: Path, prefixes: tuple[str, ...]) -> tuple[list, list]:
    from PIL import Image, ImageChops  # import local : Pillow facultatif

    olds = {_key(p.name, prefixes): p for p in before.glob("*.png")}
    news = {_key(p.name, prefixes): p for p in after.glob("*.png")}
    rows, missing = [], sorted(set(olds) ^ set(news))
    for key in sorted(set(olds) & set(news)):
        a = Image.open(olds[key]).convert("RGBA")
        b = Image.open(news[key]).convert("RGBA")
        if a.size != b.size:
            rows.append((key, "taille différente", f"{a.size} / {b.size}"))
            continue
        # Écart maximal des quatre canaux (R, V, B, alpha) : `getbbox` d'une
        # image RGBA ne regarderait que l'alpha.
        r, g, bl, al = ImageChops.difference(a, b).split()
        mask = ImageChops.lighter(ImageChops.lighter(r, g), ImageChops.lighter(bl, al))
        mask = mask.point(lambda v: 255 if v else 0)
        box = mask.getbbox()
        if box is None:
            rows.append((key, "identique", ""))
            continue
        count = mask.histogram()[255]
        rows.append((key, f"{count} pixels différents", f"zone {box}"))
    return rows, missing


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("before", type=Path)
    parser.add_argument("after", type=Path)
    parser.add_argument("--prefix-avant", default="apres_")
    parser.add_argument("--prefix-apres", default="l6_")
    args = parser.parse_args(argv)
    rows, missing = compare(args.before, args.after, (args.prefix_avant, args.prefix_apres))
    same = sum(1 for r in rows if r[1] == "identique")
    for key, verdict, detail in rows:
        print(f"{key}\t{verdict}\t{detail}")
    for key in missing:
        print(f"{key}\tsans correspondance")
    print(f"Total : {len(rows)} paires, {same} identiques, {len(rows) - same} différentes, "
          f"{len(missing)} sans correspondance")
    return 0 if same == len(rows) and not missing else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
