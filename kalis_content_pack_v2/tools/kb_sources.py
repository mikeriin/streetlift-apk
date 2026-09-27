"""Muscles sourcés par archétype (L9R, étape 2).

`sources/archetypes_sources.json` contient, pour chacun des 237 archétypes, les
références consultées (URL, date, muscles tels que la source les nomme), le
consensus retenu (primaires, secondaires, stabilisateurs, en ids ou alias de la
taxonomie `kb_muscles`), le nombre de sources concordantes, les désaccords et
les erreurs de la v1. Ce module l'expose au constructeur du pack.

Règle : aucun texte de source n'est repris ; seuls les faits (listes de
muscles, niveau, matériel) ont été relevés. Voir licences.md.
"""
import json
import os

import kb_muscles as KM

HERE = os.path.dirname(os.path.abspath(__file__))
PATH = os.path.join(HERE, "..", "sources", "archetypes_sources.json")

with open(PATH, encoding="utf-8") as f:
    SOURCES = json.load(f)


def _dedup(seq):
    out = []
    for x in seq:
        if x not in out:
            out.append(x)
    return out


def muscles_for(arch, prim_override=None, sec_override=None, stab_override=None):
    """Listes détaillées (ids) : primaires, secondaires, stabilisateurs.

    Les surcharges par exercice sont des chaînes de tokens (ids ou alias).
    Un muscle ne figure que dans une liste : primaire > secondaire > stabilisateur.
    """
    c = SOURCES[arch]["consensus"]
    prim = KM.expand(prim_override.split() if prim_override else c["primaires"])
    sec = KM.expand(sec_override.split() if sec_override else c["secondaires"])
    stab = KM.expand(stab_override.split() if stab_override else c["stabilisateurs"])
    sec = [m for m in sec if m not in prim]
    stab = [m for m in stab if m not in prim and m not in sec]
    return _dedup(prim), _dedup(sec), _dedup(stab)


def sources_for(arch):
    """Références consultées pour l'archétype : URL, date, type, entrée."""
    out = []
    for s in SOURCES[arch]["sources"]:
        out.append({"url": s["url"], "consulte_le": s["consulte_le"], "type": s.get("type", "autre"),
                    "entree": s.get("entree")})
    return out


def meta_for(arch):
    v = SOURCES[arch]
    return {
        "nb_sources_concordantes": v.get("nb_sources_concordantes", 0),
        "desaccord": v.get("desaccord"),
        "note_concordance": v.get("note_concordance"),
        "v1_erreur": v.get("v1_erreur"),
        "stabilisateurs_origine": "raisonnement" if str(v.get("stab_source", "")).startswith("raisonnement") else "source",
        "difficulte_reference": v.get("difficulte_reference"),
        "mobilite": v.get("mobilite"),
    }


if __name__ == "__main__":
    n1 = [k for k, v in SOURCES.items() if v.get("nb_sources_concordantes", 0) < 2]
    print(len(SOURCES), "archétypes ;", len(n1), "avec moins de 2 sources concordantes :", n1)
    for k in SOURCES:
        muscles_for(k)
    print("expansion OK")
