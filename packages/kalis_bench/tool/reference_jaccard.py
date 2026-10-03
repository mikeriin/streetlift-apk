#!/usr/bin/env python3
"""Non-ressemblance aux programmes de référence privés (PIPELINE_CP.md §2).

Les références ne sont jamais dans le dépôt : ce script se lance dans une
session qui a déchiffré l'archive d'analyse (`analyse_<LOT>.tar.gpg` de la
branche `cp-references`) et lit son fichier `couples_references.json` :
`{"<code>": [["exercice|schéma", …] par semaine, …], …}` (codes anonymes,
même définition des couples que `programWeekPairs` : identifiant du
catalogue et schéma `séries x bas-haut`).

Il rend, par profil, le plus fort indice de Jaccard entre une semaine du
programme généré et une semaine d'une référence. Exigé : < 0,30. Seul ce
résultat est publiable.

usage : reference_jaccard.py couples_references.json programmes/*.json
"""
import json
import sys

LIMIT = 0.30


def jaccard(a, b):
    if not a and not b:
        return 0.0
    return len(a & b) / len(a | b)


def week_pairs(program):
    return [{f"{i['id']}|{i['scheme']}" for d in w["days"] for i in d["items"]}
            for w in program["weeks"]]


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    with open(argv[1], encoding="utf-8") as f:
        references = {code: [set(week) for week in weeks]
                      for code, weeks in json.load(f).items()}
    worst = 0.0
    print("| Profil | Jaccard le plus haut | Sous 0,30 |")
    print("| --- | --- | --- |")
    for path in argv[2:]:
        with open(path, encoding="utf-8") as f:
            program = json.load(f)
        best = 0.0
        for pairs in week_pairs(program):
            for weeks in references.values():
                for ref in weeks:
                    best = max(best, jaccard(pairs, ref))
        worst = max(worst, best)
        print(f"| `{program['key']}` | {best:.3f} | "
              f"{'oui' if best < LIMIT else 'NON'} |")
    print(f"\nMaximum : {worst:.3f} (seuil {LIMIT:.2f}).")
    return 0 if worst < LIMIT else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
