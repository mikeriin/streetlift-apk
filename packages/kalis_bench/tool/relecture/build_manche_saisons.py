#!/usr/bin/env python3
"""Prépare une manche « saisons » de la page « Relecture Kalis Track » (lot CX).

usage : build_manche_saisons.py <numéro> "<titre>" "<date>" "<moteurs>" <sortie.json>
        <dossier saisons> <profil>[:<scénario>] …

Pour chaque profil : le programme de la saison tel que les blocs l'ont écrit
(`saisons/<profil>.json`, même forme que les manches précédentes), puis la
saison simulée (`saisons/<profil>.md` : plan de saison et blocs, bilan,
mouvements suivis semaine par semaine, journal des décisions, tentatives) et,
si un scénario est donné, la même saison dans ce scénario
(`saisons/scenarios/<profil>_<scénario>.md`). Aucune donnée de référence :
seulement les programmes créés par les moteurs, les profils types et les
trajectoires simulées.
"""
import json
import re
import sys


def sections(text):
    """Sections de niveau 2 d'un export Markdown : {titre: corps}."""
    out = {}
    current = None
    lines = []
    for line in text.splitlines():
        m = re.match(r"^## (.+)$", line)
        if m:
            if current is not None:
                out[current] = "\n".join(lines).strip()
            current = m.group(1).strip()
            lines = []
        elif current is not None:
            lines.append(line)
    if current is not None:
        out[current] = "\n".join(lines).strip()
    return out


def saison(md):
    s = sections(md)
    keep = [
        "Plan de saison et blocs",
        "Bilan",
        "Mouvements suivis, semaine par semaine",
        "Journal des décisions",
        "Figures",
        "Tentatives de maximum",
    ]
    return [{"titre": k, "texte": s[k]} for k in keep if k in s]


def programme(p):
    return {
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
    }


def main(argv):
    if len(argv) < 8:
        print(__doc__)
        return 2
    number, title, date, engines, out, folder = (
        int(argv[1]), argv[2], argv[3], argv[4], argv[5], argv[6])
    programmes = []
    for spec in argv[7:]:
        key, _, scenario = spec.partition(":")
        with open(f"{folder}/{key}.json", encoding="utf-8") as f:
            p = programme(json.load(f))
        with open(f"{folder}/{key}.md", encoding="utf-8") as f:
            p["saison"] = saison(f.read())
        if scenario:
            with open(f"{folder}/scenarios/{key}_{scenario}.md",
                      encoding="utf-8") as f:
                text = f.read()
            m = re.search(r"\*\*Scénario\*\* : (.+?)\.\n", text)
            p["scenario"] = {
                "titre": m.group(1) if m else scenario,
                "sections": saison(text),
            }
        programmes.append(p)
    with open(out, "w", encoding="utf-8") as f:
        json.dump({"manche": number, "titre": title, "date": date,
                   "moteurs": engines, "programmes": programmes},
                  f, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
