#!/usr/bin/env python3
"""Prépare les données d'une manche de la page « Relecture Kalis Track ».

usage : build_manche.py <numéro> "<titre>" "<date>" "<moteurs>" <sortie.json> programmes/<profil>.json …

Lit les exports JSON du banc (`ci-out/packages/kalis_bench/programmes/`) et
écrit le fichier de la manche (`manches/<numéro>.json`), à publier à côté de
la page avec `manches/index.json` mis à jour. Aucune donnée de référence :
seulement les programmes créés par les moteurs et les profils types.
"""
import json
import sys


def main(argv):
    if len(argv) < 7:
        print(__doc__)
        return 2
    number, title, date, engines, out = int(argv[1]), argv[2], argv[3], argv[4], argv[5]
    programmes = []
    for path in argv[6:]:
        with open(path, encoding="utf-8") as f:
            p = json.load(f)
        programmes.append({
            "cle": p["key"], "groupe": p["group"], "niveau": p["level"],
            "titre": p["title"], "resume": p["summary"], "profil": p["profile"],
            "echeance": p["eventWeek"],
            "semaines": [{
                "n": w["week"], "bloc": w["block"], "nature": w["kind"],
                "series": w["hardSets"],
                "jours": [{
                    "jour": d["day"], "theme": d["focus"],
                    "minutes": d["minutes"], "estime": d["estimated"],
                    "items": [[i["name"], i["volume"], i["load"], i["effort"],
                               i["rest"], i["notes"]] for i in d["items"]],
                } for d in w["days"]],
            } for w in p["weeks"]],
        })
    with open(out, "w", encoding="utf-8") as f:
        json.dump({"manche": number, "titre": title, "date": date,
                   "moteurs": engines, "programmes": programmes},
                  f, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
