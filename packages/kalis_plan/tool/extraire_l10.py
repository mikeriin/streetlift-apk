#!/usr/bin/env python3
"""Réduit l'export de l'ancien générateur L10 à ce que la comparaison lit.

L'ancien générateur (lib/program_generator.dart de l'application) dépend de
Flutter : il ne tourne que sous `flutter test`. `tool/l10_export_test.dart.txt`
est le test jetable qui l'a fait tourner sur les 40 profils types de kalis_core
(à copier dans `test/` de l'application, extension `.dart`) ; il écrit
`l10_outputs.json`. Ce script en tire `docs/data/l10_sorties.json.gz` :

    python3 tool/extraire_l10.py <l10_outputs.json[.gz]> docs/data/l10_sorties.json.gz

Semaine retenue : la troisième (première semaine de charge sans série de
calibrage). Rien n'est recalculé ici, sauf le nombre de séries lu dans le texte
de la prescription et le groupe musculaire de chaque muscle de l'ancienne base
(table ci-dessous, alignée sur `muscleGroupOf` de kalis_plan).
"""
import gzip
import json
import re
import sys

REFERENCE_WEEK = 3

# Muscle de l'ancienne base -> groupe musculaire majeur de kalis_plan
# (lib/src/traits.dart, `MuscleGroup`). Les muscles absents ne comptent pas.
MUSCLE_GROUP = {
    "grand_pectoral_claviculaire": "chest",
    "grand_pectoral_sterno_costal": "chest",
    "grand_pectoral_abdominal": "chest",
    "deltoide_anterieur": "delt_anterior",
    "deltoide_moyen": "delt_middle",
    "deltoide_posterieur": "delt_posterior",
    "grand_dorsal": "lats",
    "grand_rond": "lats",
    "trapeze_moyen": "upper_back",
    "trapeze_inferieur": "upper_back",
    "rhomboides": "upper_back",
    "erecteurs_lombaires": "lower_back",
    "erecteurs_thoraciques": "lower_back",
    "multifides": "lower_back",
    "carre_des_lombes": "lower_back",
    "biceps_chef_court": "biceps",
    "biceps_chef_long": "biceps",
    "brachial": "biceps",
    "brachio_radial": "biceps",
    "triceps_chef_long": "triceps",
    "triceps_chef_lateral": "triceps",
    "triceps_chef_medial": "triceps",
    "droit_abdomen": "abs",
    "oblique_externe": "abs",
    "oblique_interne": "abs",
    "transverse_abdomen": "abs",
    "grand_fessier": "glutes",
    "moyen_fessier": "glutes",
    "petit_fessier": "glutes",
    "droit_femoral": "quads",
    "vaste_lateral": "quads",
    "vaste_medial": "quads",
    "vaste_intermediaire": "quads",
    "biceps_femoral": "hamstrings",
    "biceps_femoral_chef_court": "hamstrings",
    "semi_tendineux": "hamstrings",
    "semi_membraneux": "hamstrings",
    "gastrocnemien_lateral": "calves",
    "gastrocnemien_medial": "calves",
    "soleaire": "calves",
}

NO_PROGRAMME = re.compile(r"^discipline (\w+): L10 has no (\w+)")


def read(path):
    opener = gzip.open if path.endswith(".gz") else open
    with opener(path, "rt", encoding="utf-8") as f:
        return json.load(f)


def sets_of(text):
    """Nombre de séries d'une prescription en texte (0 : bloc en durée)."""
    m = re.match(r"^(\d+)×", text)
    if m:
        return int(m.group(1))
    m = re.match(r"^(\d+) échelles", text)
    if m:
        return int(m.group(1))
    return 0


def minutes_of(text):
    """Durée d'un bloc en minutes, ou 0."""
    m = re.search(r"(\d+) min", text)
    return int(m.group(1)) if m else 0


def groups_of(exercise):
    """Crédit par groupe : 2 = muscle principal, 1 = muscle secondaire."""
    out = {}
    for name in exercise["musclesSecondaires"]:
        g = MUSCLE_GROUP.get(name)
        if g:
            out[g] = max(out.get(g, 0), 1)
    for name in exercise["musclesPrimaires"]:
        g = MUSCLE_GROUP.get(name)
        if g:
            out[g] = 2
    return dict(sorted(out.items()))


def main():
    source, target = sys.argv[1], sys.argv[2]
    data = read(source)
    used = set()
    profiles = {}
    for key, p in data["profiles"].items():
        if p.get("error"):
            raise SystemExit(f"{key} : {p['error']}")
        without, approximated = [], []
        for note in p["mappingNotes"]:
            m = NO_PROGRAMME.match(note)
            if not m:
                continue
            (approximated if m.group(1) == "musculation" else without).append(
                m.group(1)
            )
        week = next(
            w for w in p["program"]["weeks"] if w["n"] == REFERENCE_WEEK
        )
        days = []
        for day in week["days"]:
            items = []
            for e in day.get("exercises", []):
                text = e["sets"]["value"]
                used.add(e["exId"])
                items.append(
                    {
                        "exerciseId": e["exId"],
                        "role": e["role"],
                        "sets": sets_of(text),
                        "minutes": 0 if sets_of(text) else minutes_of(text),
                        "text": text,
                    }
                )
            if items:
                days.append(
                    {
                        "weekday": day["j"],
                        "budgetMinutes": day["minutes"],
                        "estimateSeconds": day["estimate"],
                        "items": items,
                    }
                )
        inputs = p["inputs"]
        profiles[key] = {
            "disciplinesWithoutProgramme": sorted(set(without)),
            "disciplinesApproximated": sorted(set(approximated)),
            "goalPrimary": inputs["goalPrimary"],
            "sessionMinutes": inputs["sessionMinutes"],
            "caution": inputs["caution"],
            "globalLevel": p["summary"]["levels"]["global"],
            "split": p["summary"]["split"],
            "programmeWeeks": len(p["program"]["weeks"]),
            "weekKind": week["kind"],
            "days": days,
        }
    exercises = {}
    for ex_id in sorted(used):
        e = data["exercises"].get(ex_id)
        if e is None:
            continue
        exercises[ex_id] = {
            "name": e["nom"],
            "family": e["family"],
            "difficulty": e["difficulty"],
            "groups": groups_of(e),
            "joints": {k: v for k, v in sorted(e["joints"].items()) if v},
        }
    out = {
        "note": "Sorties de l'ancien générateur L10 (lecture seule), "
        "réduites par tool/extraire_l10.py pour la comparaison de "
        "docs/COMPARAISON_L10.md.",
        "generatorVersion": data["generatorVersion"],
        "modelsVersion": data["modelsVersion"],
        "seed": data["seed"],
        "start": data["start"],
        "referenceWeek": REFERENCE_WEEK,
        "oldDatabase": data["oldDatabase"],
        "exercises": exercises,
        "profiles": profiles,
    }
    text = json.dumps(out, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    with gzip.GzipFile(target, "wb", mtime=0) as f:
        f.write(text.encode("utf-8"))
    print(f"{len(profiles)} profils, {len(exercises)} exercices -> {target}")


if __name__ == "__main__":
    main()
