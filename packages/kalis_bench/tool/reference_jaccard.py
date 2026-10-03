#!/usr/bin/env python3
"""Non-ressemblance aux programmes de référence privés (PIPELINE_CP.md §2).

Les références ne sont jamais dans le dépôt : ce script se lance dans une
session qui a déchiffré l'archive d'analyse (`analyse_<LOT>.tar.gpg` de la
branche `cp-references`) et lit son fichier `couples_references.json` :
`{"<code>": [["famille|schéma", …] par semaine, …], …}` (codes anonymes ;
schéma `séries x bas-haut` comme dans `programWeekPairs`).

Les exercices sont ramenés à leur famille (traction, dips, muscle-up, pompe,
squat, développé couché, suspension, front lever) des deux côtés, ce qui ne
peut que relever l'indice par rapport à une comparaison par identifiant.

Par profil, le script rend le plus fort indice entre une semaine du
programme généré et une semaine d'une référence, sous deux lectures :
 - exact : même famille et même schéma ;
 - tolérant : même famille, même nombre de séries, répétitions de la
   référence dans la plage du programme généré.
Exigé : < 0,30 pour les deux. Seul ce résultat est publiable.

usage : reference_jaccard.py couples_references.json programmes/*.json
"""
import json
import re
import sys

LIMIT = 0.30


def family(exercise_id):
    if "muscle-up" in exercise_id:
        return "mu"
    if ("traction" in exercise_id and "retraction" not in exercise_id) \
            or "chest-to-bar" in exercise_id:
        return "pull"
    if "dips" in exercise_id:
        return "dips"
    if "pompe" in exercise_id:
        return "push"
    if "squat" in exercise_id:
        return "squat"
    if "developpe-couche" in exercise_id:
        return "bench"
    if "suspension" in exercise_id:
        return "hang"
    if "front-lever" in exercise_id:
        return "fl"
    return None


def jaccard(a, b):
    if not a and not b:
        return 0.0
    return len(a & b) / len(a | b)


def parse(scheme):
    m = re.match(r"(\d+)x(\d+)-(\d+)$", scheme)
    return (int(m.group(1)), int(m.group(2)), int(m.group(3))) if m else None


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    with open(argv[1], encoding="utf-8") as f:
        references = [set(week) for weeks in json.load(f).values()
                      for week in weeks]
    parsed_refs = []
    for week in references:
        rows = []
        for couple in week:
            fam, scheme = couple.split("|")
            p = parse(scheme)
            if p:
                rows.append((fam, p[0], p[1]))
        parsed_refs.append(rows)
    worst_exact = worst_tolerant = 0.0
    print("| Profil | Jaccard exact | Jaccard tolérant | Sous 0,30 |")
    print("| --- | --- | --- | --- |")
    for path in sorted(argv[2:]):
        with open(path, encoding="utf-8") as f:
            program = json.load(f)
        exact = tolerant = 0.0
        for week in program["weeks"]:
            items = {(i["id"], i["scheme"])
                     for d in week["days"] for i in d["items"]}
            if not items:
                continue
            pairs = {f"{family(i) or i}|{s}" for i, s in items}
            ranges = [(family(i), parse(s)) for i, s in items]
            for ref, rows in zip(references, parsed_refs):
                exact = max(exact, jaccard(pairs, ref))
                common = sum(
                    1 for fam, p in ranges
                    if fam and p and any(f == fam and n == p[0]
                                         and p[1] <= r <= p[2]
                                         for f, n, r in rows))
                tolerant = max(
                    tolerant, common / (len(items) + len(ref) - common))
        worst_exact = max(worst_exact, exact)
        worst_tolerant = max(worst_tolerant, tolerant)
        ok = exact < LIMIT and tolerant < LIMIT
        print(f"| `{program['key']}` | {exact:.3f} | {tolerant:.3f} | "
              f"{'oui' if ok else 'NON'} |")
    print(f"\nMaximum : exact {worst_exact:.3f}, tolérant "
          f"{worst_tolerant:.3f} (seuil {LIMIT:.2f}).")
    return 0 if max(worst_exact, worst_tolerant) < LIMIT else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
