#!/usr/bin/env python3
"""Écrit les profils types du banc (`profiles/*.json`) et les contrôle.

Les profils sont décrits ici de façon compacte ; les fichiers JSON écrits
font foi pour le banc (ils sont lus par `bin/`). Lancer depuis la racine du
dépôt : `python3 packages/kalis_bench/tool/gen_profiles.py` (`--check` :
vérifie que les fichiers sont à jour, sans écrire).

Contrôles faits ici (les mêmes, en Dart, dans `test/profiles_test.dart`) :
identifiants d'exercice et matériel connus du catalogue, parts de discipline
à 100, mode street cohérent, types d'attente connus, clés uniques.
"""
from __future__ import annotations

import gzip
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT.parent / "kalis_core" / "data" / "catalog_v1.json.gz"
OUT = ROOT / "profiles"

# ----------------------------------------------------------------- matériel
PARC = ["barre fixe", "barres parallèles", "barre basse"]
PARC_ELASTIQUE = PARC + ["élastique"]
STREET_SALLE = PARC + [
    "élastique", "ceinture de lest", "disques", "barre olympique",
    "cage / rack", "magnésie", "banc plat", "haltères", "poulie", "anneaux",
    "tapis", "box / plinth",
]
SALLE = [
    "barre olympique", "disques", "cage / rack", "banc plat",
    "banc inclinable", "haltères", "poulie", "machine guidée",
    "presse à cuisses", "machine à mollets", "barre EZ", "kettlebell",
    "barre fixe", "barres parallèles", "tapis", "rameur",
    "vélo / home-trainer", "tapis de course", "élastique", "box / plinth",
]
INCR_LEST = [{"loadType": "lest", "stepKg": 1.25}]
INCR_SALLE = [
    {"loadType": "barre", "stepKg": 2.5, "minKg": 20.0},
    {"loadType": "halteres", "stepKg": 2.0, "minKg": 2.0},
    {"loadType": "machine", "stepKg": 5.0, "minKg": 5.0},
    {"loadType": "poulie", "stepKg": 2.5, "minKg": 2.5},
    {"loadType": "kettlebell", "stepKg": 4.0, "minKg": 4.0},
    {"loadType": "lest", "stepKg": 1.25},
]
SANTE_OK = {
    "questionnaireId": "kalis-sante-l13-v1",
    "answeredOn": "2026-10-01",
    "outcome": "standard",
}
SANTE_PRUDENT = dict(SANTE_OK, outcome="cautious")

STREET_DISC = {
    "streetlifting": "streetlifting",
    "sets_reps": "street_workout",
    "calisthenics": "calisthenics",
}


def street(primary: str, sl: int, sr: int, cal: int) -> dict:
    """Mode street et son image en disciplines (kalis_core, D3.3)."""
    pct = {"streetlifting": sl, "sets_reps": sr, "calisthenics": cal}
    assert sl + sr + cal == 100 and pct[primary] == max(pct.values())
    return {
        "streetMode": {
            "primary": primary,
            "streetliftingPct": sl,
            "setsRepsPct": sr,
            "calisthenicsPct": cal,
        },
        "disciplines": {
            "primary": STREET_DISC[primary],
            "primaryPct": pct[primary],
            "secondaries": [
                {"discipline": STREET_DISC[s], "pct": pct[s]}
                for s in ("streetlifting", "sets_reps", "calisthenics")
                if s != primary and pct[s] > 0
            ],
        },
    }


def mix(primary: str, pct: int, *others: tuple[str, int]) -> dict:
    assert pct + sum(o[1] for o in others) == 100
    return {
        "disciplines": {
            "primary": primary,
            "primaryPct": pct,
            "secondaries": [{"discipline": d, "pct": p} for d, p in others],
        }
    }


def days(*slots: tuple) -> list:
    out = []
    for s in slots:
        d = {"weekday": s[0], "minutes": s[1]}
        if len(s) > 2:
            d["place"] = s[2]
        out.append(d)
    return out


def core(sex, birth, height, weight, disc, avail, places, equipment, *,
         incr=None, experience, guidance="assisted", sante=SANTE_OK,
         liked=(), disliked=(), known=(), cannot=()) -> dict:
    c = {
        "sex": sex,
        "birthYear": birth,
        "heightCm": height,
        "bodyWeightKg": weight,
        **disc,
        "availability": avail,
        "places": places,
        "equipment": equipment,
        "loadIncrements": incr or [],
        "likedExerciseIds": list(liked),
        "dislikedExerciseIds": list(disliked),
        "experience": experience,
        "guidanceMode": guidance,
        "healthScreening": sante,
    }
    if known:
        c["knownExerciseIds"] = list(known)
    if cannot:
        c["cannotDoExerciseIds"] = list(cannot)
    return c


def rec(ex, measure, value, **kw) -> dict:
    return {"exerciseId": ex, "measure": measure, "value": value, **kw}


def target(ex, metric, value=None, **kw) -> dict:
    t = {"exerciseId": ex, "metric": metric}
    if value is not None:
        t["targetValue"] = value
    t.update(kw)
    return t


def check(cid, ctype, label, **params) -> dict:
    return {"id": cid, "type": ctype, "label": label, **params}


TRACTION = "sw-traction-pronation"
DIPS = "sw-dips-barres-paralleles"
POMPE = "sw-pompe"
MU = "cd-muscle-up-barre-strict"
T_LEST = "sl-traction-lestee"
D_LEST = "sl-dips-leste"
MU_LEST = "sl-muscle-up-leste"
SQUAT_SL = "sl-squat-competition"
FL = "cs-front-lever"
PLANCHE = "cs-planche"

P: list[dict] = []


def add(key, group, title, summary, level, age_months, core_, *, records=(),
        unknown=(), events=(), goals=(), habit=None, weak=(), injuries=(),
        recovery=None, pause=None, special=None, simulation=None, text=(),
        checks=()):
    d = {
        "schemaVersion": 1,
        "key": key,
        "group": group,
        "title": title,
        "summary": summary,
        "level": level,
        "trainingAgeMonths": age_months,
        "core": core_,
        "records": list(records),
    }
    if unknown:
        d["unknownLevels"] = list(unknown)
    if events:
        d["events"] = list(events)
    if goals:
        d["goals"] = list(goals)
    if habit:
        d["habitGoal"] = habit
    if weak:
        d["weakPoints"] = list(weak)
    if injuries:
        d["injuries"] = list(injuries)
    if recovery:
        d["recovery"] = recovery
    if pause:
        d["break"] = {"weeksOff": pause}
    if special:
        d["specialization"] = special
    if simulation:
        d["simulation"] = simulation
    d["expectations"] = {"text": list(text), "checks": list(checks)}
    P.append(d)


# ======================================================================
# STREET (17 profils)
# ======================================================================

add(
    "street_01_debutant_complet", "street",
    "Débutant complet, aucune traction",
    "Homme de 24 ans, jamais entraîné, ne fait aucune traction ni aucun dips. "
    "Veut réussir ses premières tractions. Trois séances de 45 minutes au "
    "parc, avec un élastique.",
    "beginner", 0,
    core("male", 2002, 180, 78.0, street("sets_reps", 0, 70, 30),
         days((1, 45), (3, 45), (5, 45)), ["exterieur"], PARC_ELASTIQUE,
         experience="beginner"),
    records=[rec(TRACTION, "max_reps", 0), rec(DIPS, "max_reps", 0),
             rec(POMPE, "max_reps", 8), rec("sw-row-australien", "max_reps", 6)],
    goals=[{"id": "g1", **target(TRACTION, "max_reps", 3), "weeksOut": 12}],
    text=[
        "Corps entier trois fois par semaine, mêmes mouvements d'une semaine à "
        "l'autre pour apprendre le geste (R5-P2, R3-P2).",
        "Chemin vers la première traction : suspension active, row australien, "
        "traction assistée à l'élastique, négatives courtes et peu nombreuses "
        "(2 à 3 séries de 2 à 3 descentes de 3 à 5 s au départ, R5-P8) ; "
        "autant de tirage horizontal que de tirage vertical.",
        "4 à 6 séries dures par groupe et par semaine au départ, jamais plus de "
        "12 (R1-P1, R5-P1) ; 3 à 4 répétitions en réserve le premier mois, "
        "aucun échec (R5-P4).",
        "Double progression simple, pas de bloc, pas de décharge planifiée, un "
        "test toutes les 4 à 6 semaines (R3-P2, R3-P16).",
        "Jambes et tronc présents à chaque séance ou presque.",
    ],
    checks=[
        check("c1", "min_rir_first_weeks", "Au moins 3 répétitions en réserve "
              "les quatre premières semaines", weeks=4, rir=3),
        check("c2", "pattern_present", "Tirage horizontal au moins deux fois "
              "par semaine", patterns=["tirage_horizontal"], perWeek=2),
        check("c3", "min_frequency", "Travail de traction adapté (assistée, "
              "négative ou suspension) au moins deux fois par semaine",
              exerciseIds=["sw-traction-assistee-elastique",
                           "sw-traction-negative", "sw-active-hang",
                           "sw-traction-assistee-pieds-au-sol",
                           "sw-traction-scapulaire"], exact=True, perWeek=2),
        check("c4", "pattern_present", "Jambes (squat ou fente) au moins deux "
              "fois par semaine", patterns=["squat", "fente"], perWeek=2),
        check("c5", "max_group_sets", "Grand dorsal : pas plus de 12 séries "
              "dures par semaine", group="lats", sets=12),
        check("c6", "max_session_minutes", "Séances de 50 minutes au plus",
              minutes=50),
        check("c7", "max_exercise_level", "Aucun exercice de niveau avancé ou "
              "élite", level="Intermédiaire"),
    ],
)

add(
    "street_02_debutant_surpoids", "street",
    "Débutant sédentaire en surpoids",
    "Homme de 38 ans, sédentaire, 104 kg pour 1,76 m. Veut reprendre une "
    "activité et perdre du poids. Trois séances de 40 minutes, à la maison "
    "et au parc.",
    "beginner", 0,
    core("male", 1988, 176, 104.0, street("sets_reps", 0, 80, 20),
         days((2, 40), (4, 40), (6, 40)), ["maison", "exterieur"],
         PARC_ELASTIQUE + ["tapis"], experience="beginner"),
    records=[rec(TRACTION, "max_reps", 0), rec(POMPE, "max_reps", 2),
             rec(DIPS, "max_reps", 0)],
    habit={"sessionsPerWeek": 3, "weeks": 12},
    recovery={"sleepHours": 6.5, "stress": 3, "energyDeficit": True},
    text=[
        "Au poids du corps, la charge est la masse corporelle : chaque variante "
        "doit permettre 6 à 8 répétitions avec 3 en réserve (pompes surélevées, "
        "row australien peu incliné, squat sur box) (R5-P9).",
        "Ni sauts ni pliométrie ni course au début ; suspensions et appuis sur "
        "les poignets à volume réduit (R5-P9, R6-P32).",
        "La force progresse normalement en déficit énergétique : progression "
        "simple, volume non réduit par défaut mais bas (4 à 6 séries par "
        "groupe) (R5-P16, R5-P1).",
        "L'adhésion d'abord : séances courtes, réussies, répétées (R5-P1).",
    ],
    checks=[
        check("c1", "forbid_patterns", "Ni pliométrie, ni sprint, ni corde à "
              "sauter, ni balistique", patterns=["pliometrie", "sprint",
                                                 "corde_a_sauter", "balistique"]),
        check("c2", "min_rir_first_weeks", "Au moins 3 répétitions en réserve "
              "les quatre premières semaines", weeks=4, rir=3),
        check("c3", "max_exercise_level", "Exercices de niveau débutant "
              "seulement", level="Débutant"),
        check("c4", "pattern_present", "Tirage horizontal au moins deux fois "
              "par semaine", patterns=["tirage_horizontal"], perWeek=2),
        check("c5", "max_session_minutes", "Séances de 45 minutes au plus",
              minutes=45),
        check("c6", "max_group_sets", "Pectoraux : pas plus de 10 séries "
              "dures par semaine", group="chest", sets=10),
    ],
)

add(
    "street_03_debutante", "street",
    "Débutante, objectif première traction",
    "Femme de 29 ans, 58 kg, active mais jamais entraînée en force. Veut sa "
    "première traction et de vraies pompes. Trois séances d'une heure, à la "
    "maison (barre de traction) et au parc.",
    "beginner", 2,
    core("female", 1997, 165, 58.0, street("sets_reps", 0, 70, 30),
         days((1, 60), (3, 60), (6, 60)), ["maison", "exterieur"],
         PARC_ELASTIQUE + ["tapis"], experience="beginner"),
    records=[rec(TRACTION, "max_reps", 0), rec(POMPE, "max_reps", 3),
             rec(DIPS, "max_reps", 0),
             rec("sw-dead-hang", "max_hold_seconds", 25)],
    goals=[{"id": "g1", **target(TRACTION, "max_reps", 1), "weeksOut": 12},
           {"id": "g2", **target(POMPE, "max_reps", 10), "weeksOut": 12}],
    text=[
        "Même programme qu'un débutant : le sexe ne change ni les volumes, ni "
        "les intensités relatives, ni la progression ; seuls changent les "
        "paliers de départ au haut du corps (R5-P11).",
        "Davantage de paliers intermédiaires vers la traction et le dips "
        "(assistance dégressive, négatives, row) (R5-P8, R5-P11).",
        "Aucune périodisation sur le cycle menstruel (R5-P12).",
    ],
    checks=[
        check("c1", "min_rir_first_weeks", "Au moins 3 répétitions en réserve "
              "les quatre premières semaines", weeks=4, rir=3),
        check("c2", "min_frequency", "Travail de traction adapté au moins deux "
              "fois par semaine",
              exerciseIds=["sw-traction-assistee-elastique",
                           "sw-traction-negative", "sw-active-hang",
                           "sw-traction-assistee-pieds-au-sol",
                           "sw-traction-scapulaire"], exact=True, perWeek=2),
        check("c3", "min_frequency", "Pompes (ou un palier) au moins deux fois "
              "par semaine", exerciseIds=[POMPE], perWeek=2),
        check("c4", "pattern_present", "Jambes au moins deux fois par semaine",
              patterns=["squat", "fente"], perWeek=2),
        check("c5", "max_exercise_level", "Aucun exercice de niveau avancé ou "
              "élite", level="Intermédiaire"),
    ],
)

add(
    "street_04_reprise_longue_pause", "street",
    "Reprise après neuf mois d'arrêt",
    "Homme de 34 ans, trois ans de street workout, arrêté neuf mois "
    "(déménagement, naissance). Faisait 12 tractions et 20 dips. Reprend à "
    "quatre séances d'une heure au parc.",
    "intermediate", 36,
    core("male", 1992, 178, 80.0, street("sets_reps", 10, 60, 30),
         days((1, 60), (2, 60), (4, 60), (6, 60)), ["exterieur"],
         PARC_ELASTIQUE, experience="intermediate"),
    records=[rec(TRACTION, "max_reps", 12, testedWeeksAgo=40),
             rec(DIPS, "max_reps", 20, testedWeeksAgo=40),
             rec(POMPE, "max_reps", 35, testedWeeksAgo=40)],
    pause=36,
    text=[
        "Plus de seize semaines d'arrêt : réévaluation, reprise à 1 ou 2 séries "
        "par exercice, 4 répétitions en réserve la première semaine, retour au "
        "niveau antérieur en 6 à 10 semaines (R5-P7).",
        "Ni excentrique accentué, ni échec, ni séance de test les deux "
        "premières semaines (R5-P7) ; les anciens records ne sont pas des "
        "charges de travail.",
        "Ensuite progression 1,5 à 2 fois plus rapide que celle d'un débutant "
        "jusqu'à 90 % des anciens repères (R5-P6).",
    ],
    checks=[
        check("c1", "min_rir_first_weeks", "Au moins 3 répétitions en réserve "
              "les deux premières semaines", weeks=2, rir=3),
        check("c2", "max_group_sets", "Grand dorsal : pas plus de 16 séries "
              "dures par semaine", group="lats", sets=16),
        check("c3", "forbid_exercises", "Pas de négatives ni d'excentriques "
              "accentués", exerciseIds=["sw-traction-negative",
                                        "sw-dips-negatifs",
                                        "sw-traction-tempo-excentrique"]),
        check("c4", "min_frequency", "Tractions (ou un palier) au moins deux "
              "fois par semaine", exerciseIds=[TRACTION], perWeek=2),
    ],
)

add(
    "street_05_inter_calisthenie_front_lever", "street",
    "Intermédiaire calisthénie, premiers muscle-ups, objectif front lever",
    "Homme de 26 ans, 70 kg, deux ans de pratique. 12 tractions, 20 dips, "
    "2 muscle-ups, front lever tuck avancé tenu 12 s. Veut le front lever "
    "complet. Quatre séances de 75 minutes au parc.",
    "intermediate", 24,
    core("male", 2000, 175, 70.0, street("calisthenics", 10, 30, 60),
         days((1, 75), (2, 75), (4, 75), (6, 75)), ["exterieur"],
         PARC_ELASTIQUE + ["anneaux"], experience="intermediate",
         known=[MU]),
    records=[rec(TRACTION, "max_reps", 12), rec(DIPS, "max_reps", 20),
             rec(MU, "max_reps", 2),
             rec("cs-front-lever-tuck-avance", "max_hold_seconds", 12),
             rec("cs-l-sit", "max_hold_seconds", 15)],
    goals=[{"id": "g1", **target(FL, "skill_unlocked"), "weeksOut": 16}],
    weak=[{"kind": "movement", "exerciseId": MU,
           "note": "transition du muscle-up encore heurtée"}],
    text=[
        "Front lever deux à trois fois par semaine, jamais deux jours de "
        "suite : tenues à 50-70 % de la tenue maximale, 30 à 60 s cumulées par "
        "séance (R4-F2, R4-F10).",
        "Un seul palier à la fois : au moins 8 semaines sur un levier avant le "
        "suivant, avec des demi-pas (une jambe, straddle) (R4-F7, R4-F9).",
        "Moitié statique, moitié dynamique dans le même schéma : front lever "
        "raises, tractions, rows (R4-F5).",
        "Muscle-up travaillé frais, en début de séance, loin de l'échec "
        "(R4-F1, R5-P27).",
        "Décharge toutes les 5 à 6 semaines (R3-P9).",
    ],
    checks=[
        check("c1", "min_frequency", "Front lever (un palier) au moins deux "
              "fois par semaine", exerciseIds=[FL], perWeek=2),
        check("c2", "straight_arm_days_max", "Tenues bras tendus d'une même "
              "famille : trois jours par semaine au plus", days=3),
        check("c3", "min_frequency", "Muscle-up (ou un palier) au moins deux "
              "fois par semaine", exerciseIds=[MU], perWeek=2),
        check("c4", "relief_every", "Pas plus de 6 semaines de charge sans "
              "allègement", weeks=6),
        check("c5", "pattern_present", "Tirage dynamique (vertical ou "
              "horizontal) au moins trois fois par semaine",
              patterns=["tirage_vertical", "tirage_horizontal",
                        "figure_dynamique_tirage"], perWeek=3),
        check("c6", "pattern_present", "Jambes au moins une fois par semaine",
              patterns=["squat", "fente"], perWeek=1),
    ],
)

add(
    "street_06_inter_sets_reps", "street",
    "Intermédiaire sets & reps",
    "Homme de 23 ans, 68 kg, dix-huit mois de pratique. 15 tractions, "
    "25 dips, 40 pompes, 3 muscle-ups. Veut 20 tractions et 35 dips. Quatre "
    "séances d'une heure au parc.",
    "intermediate", 18,
    core("male", 2003, 174, 68.0, street("sets_reps", 10, 70, 20),
         days((1, 60), (3, 60), (5, 60), (6, 60)), ["exterieur"],
         PARC_ELASTIQUE, experience="intermediate", known=[MU]),
    records=[rec(TRACTION, "max_reps", 15), rec(DIPS, "max_reps", 25),
             rec(POMPE, "max_reps", 40), rec(MU, "max_reps", 3)],
    goals=[{"id": "g1", **target(TRACTION, "max_reps", 20), "weeksOut": 12},
           {"id": "g2", **target(DIPS, "max_reps", 35), "weeksOut": 12}],
    text=[
        "Tractions, dips et pompes trois fois par semaine chacun (R4-G8) ; "
        "moitié du volume en force ou technique (10 répétitions ou moins), "
        "moitié en endurance (R4-G1).",
        "Le gros du volume à 2 ou 3 répétitions de l'échec ; au plus une série "
        "à l'échec par mouvement et par séance, la dernière (R4-G3).",
        "Formats de densité : EMOM à 40 % du maximum sur 10 à 15 minutes, "
        "échelles, séries dégressives ; repos de 45 à 90 s en endurance, "
        "2 min 30 et plus en force (R4-G4, R4-G6).",
        "Test du maximum toutes les 4 à 6 semaines, décharge toutes les 5 à 6 "
        "(R3-P17, R3-P9).",
    ],
    checks=[
        check("c1", "min_frequency", "Tractions au moins trois fois par "
              "semaine", exerciseIds=[TRACTION], perWeek=3),
        check("c2", "min_frequency", "Dips au moins trois fois par semaine",
              exerciseIds=[DIPS], perWeek=3),
        check("c3", "short_rest_share", "Au moins un tiers des séries de "
              "tractions et de dips en densité (repos de 90 s au plus, EMOM, "
              "tours)", exerciseIds=[TRACTION, DIPS], maxRestSeconds=90,
              minShare=0.33),
        check("c4", "format_present", "Au moins un format de densité (EMOM, "
              "AMRAP, tours, série dégressive)",
              formats=["emom", "amrap", "rounds", "drop_set", "ladder"]),
        check("c5", "relief_every", "Pas plus de 6 semaines de charge sans "
              "allègement", weeks=6),
        check("c6", "pattern_present", "Jambes au moins une fois par semaine",
              patterns=["squat", "fente"], perWeek=1),
    ],
)

add(
    "street_07_avance_streetlifting_competition", "street",
    "Avancé streetlifting, compétition dans 12 semaines",
    "Homme de 28 ans, 80 kg, cinq ans de pratique dont deux de compétition. "
    "1RM : traction +60 kg, dips +90 kg, muscle-up +20 kg, squat 160 kg. "
    "Compétition dans 12 semaines. Cinq séances, en salle.",
    "advanced", 60,
    core("male", 1998, 178, 80.0, street("streetlifting", 80, 10, 10),
         days((1, 90), (2, 90), (4, 90), (5, 60), (6, 90)), ["salle"],
         STREET_SALLE, incr=INCR_SALLE, experience="advanced",
         guidance="free", known=[MU]),
    records=[rec(T_LEST, "one_rm_kg", 60, testedWeeksAgo=3),
             rec(D_LEST, "one_rm_kg", 90, testedWeeksAgo=3),
             rec(MU_LEST, "one_rm_kg", 20, testedWeeksAgo=3),
             rec(SQUAT_SL, "one_rm_kg", 160, testedWeeksAgo=3),
             rec(TRACTION, "max_reps", 24), rec(DIPS, "max_reps", 40)],
    events=[{"id": "e1", "kind": "competition", "label": "compétition de "
             "streetlifting", "weeksOut": 12, "priority": "A",
             "format": "streetlifting", "targets": [
                 target(T_LEST, "one_rm_kg", 65),
                 target(D_LEST, "one_rm_kg", 97.5),
                 target(MU_LEST, "one_rm_kg", 22.5),
                 target(SQUAT_SL, "one_rm_kg", 170)]}],
    weak=[{"kind": "movement", "exerciseId": T_LEST,
           "note": "départ bras tendus lent en traction lestée"}],
    text=[
        "Blocs : accumulation 3 à 6 semaines (6 à 12 répétitions, volume), "
        "puis force spécifique 3 à 4 semaines (2 à 5 répétitions, 80 à 92 %), "
        "puis réalisation 1 à 2 semaines (R3-P4).",
        "Chaque mouvement de compétition deux à quatre fois par semaine, dont "
        "une exposition à 85 % et plus ; muscle-up lesté une à deux fois "
        "(R2-P1, R2-P7). Les pourcentages portent sur la charge totale, lest "
        "plus poids de corps (R2-P4).",
        "Série haute de 1 à 3 répétitions à 1 ou 2 en réserve, puis 2 à 5 "
        "séries allégées à 80-90 % (R2-P6) ; clusters possibles en bloc de "
        "force (R2-P12).",
        "Affûtage d'une à deux semaines, volume réduit de 40 à 60 %, intensité "
        "à 85 % et plus, fréquence maintenue ; dernier lourd entre J-10 et "
        "J-7 (J-7 à J-5 pour les dips), 2 à 4 jours de repos (R3-P12 à P14).",
        "Une variante ciblée sur le point faible (traction lestée pause en "
        "bas), 60 à 75 % du volume sur le geste de compétition, 80 % et plus "
        "les dernières semaines (R2-P9).",
        "Décharge toutes les 4 à 5 semaines (R3-P9).",
    ],
    checks=[
        check("c1", "has_taper", "Volume réduit de 40 à 70 % la semaine de la "
              "compétition", minDrop=0.4, maxDrop=0.7),
        check("c2", "min_frequency", "Traction lestée au moins deux fois par "
              "semaine", exerciseIds=[T_LEST], perWeek=2),
        check("c3", "min_frequency", "Dips lesté au moins deux fois par "
              "semaine", exerciseIds=[D_LEST], perWeek=2),
        check("c4", "min_frequency", "Squat au moins deux fois par semaine",
              exerciseIds=[SQUAT_SL], perWeek=2),
        check("c5", "heavy_exposure", "Au moins une exposition lourde (85 % et "
              "plus, ou 5 répétitions au plus sous charge) par semaine en "
              "traction lestée", exerciseIds=[T_LEST], minPercent=0.85,
              maxReps=5, perWeek=1),
        check("c6", "load_prescribed", "Charges chiffrées (kg ou % du 1RM) sur "
              "les quatre mouvements de compétition",
              exerciseIds=[T_LEST, D_LEST, MU_LEST, SQUAT_SL]),
        check("c7", "relief_every", "Pas plus de 5 semaines de charge sans "
              "allègement", weeks=5),
        check("c8", "distinct_week_types", "Ondulation : au moins deux plages "
              "de répétitions par semaine en traction lestée",
              exerciseIds=[T_LEST], min=2),
        check("c9", "format_present", "Série haute puis séries allégées, ou "
              "clusters", formats=["top_set_backoff", "cluster"]),
        check("c10", "min_frequency", "Variante pour le point faible (traction "
              "lestée pause en bas) au moins une fois par semaine",
              exerciseIds=["sl-traction-lestee-pause-bas"], exact=True,
              perWeek=1),
    ],
)

add(
    "street_08_avance_sets_reps_competition", "street",
    "Avancé sets & reps, compétition dans 8 semaines",
    "Homme de 25 ans, 72 kg, quatre ans de pratique. 12 muscle-ups, "
    "28 tractions, 50 dips, 65 pompes ; traction +45 kg, dips +70 kg. "
    "Compétition de sets & reps dans 8 semaines. Cinq séances de 75 minutes, "
    "parc et salle.",
    "advanced", 48,
    core("male", 2001, 176, 72.0, street("sets_reps", 20, 70, 10),
         days((1, 75), (2, 75), (4, 75), (5, 75), (6, 75)),
         ["exterieur", "salle"], STREET_SALLE, incr=INCR_SALLE,
         experience="advanced", guidance="free", known=[MU]),
    records=[rec(MU, "max_reps", 12), rec(TRACTION, "max_reps", 28),
             rec(DIPS, "max_reps", 50), rec(POMPE, "max_reps", 65),
             rec(T_LEST, "one_rm_kg", 45), rec(D_LEST, "one_rm_kg", 70)],
    events=[{"id": "e1", "kind": "competition", "label": "compétition de "
             "sets & reps", "weeksOut": 8, "priority": "A",
             "format": "sets_reps", "targets": [
                 target(MU, "max_reps", 14),
                 target(TRACTION, "max_reps", 32),
                 target(DIPS, "max_reps", 56)]}],
    text=[
        "Muscle-ups, tractions et dips quatre fois par semaine ou plus, dont "
        "une ou deux expositions légères (R4-G8) ; les trois quarts du volume "
        "dans la zone et la densité de l'épreuve en bloc spécifique (R4-G1).",
        "Circuits et sets au format de l'épreuve, dans l'ordre de l'épreuve, "
        "simulation complète toutes les une à deux semaines, la dernière 7 à "
        "10 jours avant (R4-G7, R3-P17).",
        "Une séance lourde par semaine et par mouvement pour entretenir la "
        "force (lest, 3 à 6 répétitions) (R4-G2, R3-P18).",
        "Affûtage de 8 à 14 jours, volume réduit de 40 à 60 %, allure et "
        "densité de compétition conservées sur des fractions courtes, 1 à 2 "
        "jours de repos seulement (R3-P21).",
        "Échec réservé aux simulations ; ailleurs 1 à 3 répétitions en réserve "
        "(R4-G3).",
    ],
    checks=[
        check("c1", "has_taper", "Volume réduit de 40 à 60 % la semaine de la "
              "compétition", minDrop=0.4, maxDrop=0.65),
        check("c2", "min_frequency", "Tractions au moins quatre fois par "
              "semaine", exerciseIds=[TRACTION], perWeek=4),
        check("c3", "min_frequency", "Muscle-ups au moins trois fois par "
              "semaine", exerciseIds=[MU], perWeek=3),
        check("c4", "min_frequency", "Dips au moins trois fois par semaine",
              exerciseIds=[DIPS], perWeek=3),
        check("c5", "short_rest_share", "Au moins la moitié des séries de "
              "tractions, dips et muscle-ups en densité",
              exerciseIds=[TRACTION, DIPS, MU], maxRestSeconds=90,
              minShare=0.5),
        check("c6", "format_present", "Formats de l'épreuve : tours, EMOM, "
              "AMRAP, séries dégressives",
              formats=["emom", "amrap", "rounds", "drop_set", "ladder"]),
        check("c7", "min_frequency", "Une séance lestée lourde par semaine en "
              "traction", exerciseIds=[T_LEST], exact=True, perWeek=1),
        check("c8", "test_at_event", "Épreuve sur les mouvements visés la "
              "semaine de la compétition"),
    ],
)

add(
    "street_09_elite_streetlifting", "street",
    "Élite streetlifting, niveau national",
    "Homme de 30 ans, 78 kg, huit ans de pratique, podiums nationaux. 1RM : "
    "traction +85 kg, dips +125 kg, muscle-up +35 kg, squat 190 kg. "
    "Championnat dans 12 semaines. Cinq séances de deux heures, en salle.",
    "elite", 96,
    core("male", 1996, 174, 78.0, street("streetlifting", 90, 5, 5),
         days((1, 120), (2, 120), (4, 120), (5, 90), (6, 120)), ["salle"],
         STREET_SALLE + ["chaînes"], incr=INCR_SALLE, experience="elite",
         guidance="free", known=[MU]),
    records=[rec(T_LEST, "one_rm_kg", 85, testedWeeksAgo=5),
             rec(D_LEST, "one_rm_kg", 125, testedWeeksAgo=5),
             rec(MU_LEST, "one_rm_kg", 35, testedWeeksAgo=5),
             rec(SQUAT_SL, "one_rm_kg", 190, testedWeeksAgo=5),
             rec(TRACTION, "max_reps", 34), rec(DIPS, "max_reps", 80)],
    events=[{"id": "e1", "kind": "competition", "label": "championnat de "
             "streetlifting", "weeksOut": 12, "priority": "A",
             "format": "streetlifting", "targets": [
                 target(T_LEST, "one_rm_kg", 90),
                 target(D_LEST, "one_rm_kg", 130),
                 target(MU_LEST, "one_rm_kg", 37.5),
                 target(SQUAT_SL, "one_rm_kg", 200)]}],
    weak=[{"kind": "movement", "exerciseId": D_LEST,
           "note": "verrouillage en haut du dips lourd"},
          {"kind": "movement", "exerciseId": MU_LEST,
           "note": "transition du muscle-up lesté"}],
    injuries=[{"zone": "elbow", "side": "both", "discomfort": 1,
               "status": "history", "monthsAgo": 14,
               "label": "coudes sensibles en fin de gros cycle de traction"}],
    text=[
        "Blocs de 2 à 4 semaines avec ondulation interne ; un gain de 1 à 2 % "
        "par cycle est un bon résultat à ce niveau (R3-P4, R5-P13).",
        "8 à 15 séries directes par mouvement et par semaine, sur 3 à 5 "
        "séances, dont 3 à 6 à 85 % et plus ; alternance de séances lourdes "
        "et légères (R1-P5, R2-P7, R2-P8).",
        "Série haute de 1 à 3 répétitions puis séries allégées à 80-90 % ; "
        "clusters, pauses, variantes ciblées sur les points faibles ; "
        "excentrique surchargé seulement loin de l'échéance (R2-P6, P12, P16, "
        "P17).",
        "Semaine de surcharge possible à S-3, puis deux semaines d'affûtage : "
        "volume en baisse exponentielle de 40 à 60 %, accessoires supprimés la "
        "dernière semaine, dernier lourd de J-10 à J-7 (R3-P12 à P15).",
        "Fréquence plafonnée par les coudes et les épaules, pas par le muscle "
        "(R2-P7) ; décharge toutes les 3 à 5 semaines (R3-P9).",
    ],
    checks=[
        check("c1", "has_taper", "Volume réduit de 40 à 70 % la semaine du "
              "championnat", minDrop=0.4, maxDrop=0.7),
        check("c2", "min_frequency", "Traction lestée au moins trois fois par "
              "semaine", exerciseIds=[T_LEST], perWeek=3),
        check("c3", "min_frequency", "Dips lesté au moins trois fois par "
              "semaine", exerciseIds=[D_LEST], perWeek=3),
        check("c4", "min_frequency", "Squat au moins deux fois par semaine",
              exerciseIds=[SQUAT_SL], perWeek=2),
        check("c5", "heavy_exposure", "Une exposition lourde par semaine au "
              "moins sur chaque mouvement de compétition",
              exerciseIds=[T_LEST, D_LEST, SQUAT_SL], minPercent=0.85,
              maxReps=5, perWeek=2),
        check("c6", "load_prescribed", "Charges chiffrées sur les quatre "
              "mouvements de compétition",
              exerciseIds=[T_LEST, D_LEST, MU_LEST, SQUAT_SL]),
        check("c7", "relief_every", "Pas plus de 5 semaines de charge sans "
              "allègement", weeks=5),
        check("c8", "format_present", "Série haute puis séries allégées, "
              "clusters ou vagues",
              formats=["top_set_backoff", "cluster", "wave"]),
        check("c9", "weekly_sets_between", "8 à 18 séries dures par semaine en "
              "traction lestée et ses variantes", exerciseIds=[T_LEST],
              min=8, max=18),
        check("c10", "test_at_event", "Épreuve sur les mouvements de "
              "compétition la semaine du championnat"),
    ],
)

add(
    "street_10_elite_figures", "street",
    "Élite figures : planche et front lever complets en cours",
    "Homme de 27 ans, 64 kg, sept ans de pratique. Front lever complet tenu "
    "8 s, planche straddle tenue 6 s, 22 tractions, handstand 60 s. Veut la "
    "planche complète et un front lever de 15 s. Six séances de 90 minutes.",
    "elite", 84,
    core("male", 1999, 170, 64.0, street("calisthenics", 5, 15, 80),
         days((1, 90), (2, 90), (3, 90), (5, 90), (6, 90), (7, 90)),
         ["exterieur", "salle"],
         PARC_ELASTIQUE + ["anneaux", "parallettes", "tapis",
                           "ceinture de lest", "disques"],
         incr=INCR_LEST, experience="elite", guidance="free",
         known=[MU, FL, "cs-planche-straddle", "cs-handstand"]),
    records=[rec(FL, "max_hold_seconds", 8),
             rec("cs-planche-straddle", "max_hold_seconds", 6),
             rec("cs-handstand", "max_hold_seconds", 60),
             rec(TRACTION, "max_reps", 22), rec(DIPS, "max_reps", 35),
             rec(T_LEST, "one_rm_kg", 55)],
    goals=[{"id": "g1", **target(PLANCHE, "skill_unlocked"), "weeksOut": 16},
           {"id": "g2", **target(FL, "max_hold_seconds", 15), "weeksOut": 16}],
    injuries=[{"zone": "wrist_hand", "side": "both", "discomfort": 2,
               "status": "current",
               "label": "poignets raides après les grosses séances de planche"}],
    text=[
        "Planche et front lever : trois à quatre séances lourdes par semaine "
        "et par famille au plus, lourd et léger alternés ; planche et back "
        "lever comptés ensemble (même maillon) (R4-F10).",
        "Deux formats : force (4 à 8 s sur un levier tenu 8 à 12 s au "
        "maximum, 5 à 8 séries, 2 à 3 min de repos) et durée (10 à 20 s sur un "
        "levier plus facile) ; 40 à 75 s cumulées par figure et par séance "
        "(R4-F2, R4-F6).",
        "Passage straddle vers complète par demi-pas (half-lay, une jambe), "
        "jamais avant 6 à 8 semaines sur le palier ; hausse de 5 à 10 % par "
        "semaine au plus du temps sous tension (R4-F7, R4-F9, R5-P22).",
        "60 à 70 % de statique et de transitions, 30 à 40 % de dynamique "
        "(planche push-ups, front lever raises, tractions lestées) (R4-F5).",
        "Préparation des poignets avant chaque séance d'appui ; jambes en "
        "entretien (R4-F12, R4-H4).",
        "Aucun échec sur les figures ; un essai maximal toutes les une à deux "
        "semaines (R4-F2, R5-P27).",
    ],
    checks=[
        check("c1", "min_frequency", "Planche (un palier) au moins trois fois "
              "par semaine", exerciseIds=[PLANCHE], perWeek=3),
        check("c2", "min_frequency", "Front lever (un palier) au moins deux "
              "fois par semaine", exerciseIds=[FL], perWeek=2),
        check("c3", "straight_arm_days_max", "Tenues bras tendus d'une même "
              "famille : quatre jours par semaine au plus", days=4),
        check("c4", "relief_every", "Pas plus de 5 semaines de charge sans "
              "allègement", weeks=5),
        check("c5", "pattern_present", "Préparation ou mobilité des poignets "
              "et des épaules au moins trois fois par semaine",
              patterns=["mobilite_articulaire", "preparation_scapulaire"],
              perWeek=3),
        check("c6", "pattern_present", "Dynamique dans le schéma des figures "
              "au moins trois fois par semaine",
              patterns=["figure_dynamique_poussee", "figure_dynamique_tirage"],
              perWeek=3),
        check("c7", "pattern_present", "Jambes en entretien au moins une fois "
              "par semaine", patterns=["squat", "fente"], perWeek=1),
    ],
)

add(
    "street_11_master_51_ans", "street",
    "Athlète de 51 ans, intermédiaire",
    "Homme de 51 ans, 76 kg, six ans de pratique régulière. 10 tractions, "
    "15 dips, 30 pompes ; traction +15 kg. Veut continuer à progresser sans "
    "se blesser. Trois séances d'une heure, en salle.",
    "intermediate", 72,
    core("male", 1975, 177, 76.0, street("sets_reps", 30, 50, 20),
         days((1, 60), (3, 60), (5, 60)), ["salle"], STREET_SALLE,
         incr=INCR_SALLE, experience="intermediate"),
    records=[rec(TRACTION, "max_reps", 10), rec(DIPS, "max_reps", 15),
             rec(POMPE, "max_reps", 30), rec(T_LEST, "one_rm_kg", 15)],
    goals=[{"id": "g1", **target(TRACTION, "max_reps", 14), "weeksOut": 16}],
    recovery={"sleepHours": 7.0, "stress": 2},
    text=[
        "L'âge seul ne réduit pas l'intensité relative : même volume de départ "
        "qu'un intermédiaire, progression de volume ralentie, échauffement "
        "spécifique allongé (R5-P10).",
        "48 à 72 heures entre deux séances lourdes d'un même groupe ; décharge "
        "toutes les 5 à 6 semaines (R5-P10, R3-P9).",
        "Aucun échec sur les mouvements à risque ; 1 à 3 répétitions en "
        "réserve (R5-P4, R5-P27).",
        "Garder du lourd : c'est l'intensité qui entretient la force avec "
        "l'âge (R5-P10, R1-P7).",
    ],
    checks=[
        check("c1", "relief_every", "Pas plus de 6 semaines de charge sans "
              "allègement", weeks=6),
        check("c2", "min_frequency", "Tractions au moins deux fois par "
              "semaine", exerciseIds=[TRACTION], perWeek=2),
        check("c3", "min_rir_first_weeks", "Jamais moins d'une répétition en "
              "réserve sur les 12 semaines", weeks=12, rir=1),
        check("c4", "pattern_present", "Jambes au moins deux fois par semaine",
              patterns=["squat", "fente", "charniere_hanche"], perWeek=2),
        check("c5", "max_group_sets", "Grand dorsal : pas plus de 18 séries "
              "dures par semaine", group="lats", sets=18),
    ],
)

add(
    "street_12_antecedent_coude", "street",
    "Antécédent de tendinopathie du coude",
    "Homme de 33 ans, 82 kg, quatre ans de streetlifting. Traction +30 kg, "
    "dips +50 kg. Douleur à la face interne du coude droit il y a cinq mois "
    "(suivie par un kinésithérapeute), gêne résiduelle de 3 sur 10 sur les "
    "tractions lourdes. Quatre séances de 75 minutes.",
    "intermediate", 48,
    core("male", 1993, 181, 82.0, street("streetlifting", 60, 30, 10),
         days((1, 75), (2, 75), (4, 75), (6, 75)), ["salle"], STREET_SALLE,
         incr=INCR_SALLE, experience="intermediate"),
    records=[rec(T_LEST, "one_rm_kg", 30), rec(D_LEST, "one_rm_kg", 50),
             rec(TRACTION, "max_reps", 14), rec(DIPS, "max_reps", 22),
             rec(SQUAT_SL, "one_rm_kg", 110)],
    goals=[{"id": "g1", **target(D_LEST, "one_rm_kg", 57.5), "weeksOut": 12}],
    injuries=[{"zone": "elbow", "side": "right", "discomfort": 3,
               "status": "current", "monthsAgo": 5,
               "label": "douleur à la face interne du coude droit, suivie par "
                        "un kinésithérapeute"}],
    text=[
        "Antécédent de moins de 12 mois avec gêne résiduelle : volume de "
        "tirage et de préhension réduit de 30 à 50 % au départ, progression à "
        "demi-vitesse, aucun échec, aucun excentrique accentué (R5-P20, "
        "R5-P24).",
        "Retirer d'abord fausses prises, tractions lestées lourdes, "
        "excentriques lents de traction, bras tendus ; prises neutres ou "
        "anneaux ; plafond de douleur à 3 sur 10 (R5-P24).",
        "Jamais d'exclusion de la zone : charge graduée, réintroduction d'un "
        "exercice à la fois (R5-P20, R5-P24).",
        "Le reste (dips, squat) progresse normalement ; tirage horizontal au "
        "moins égal au vertical.",
        "Le programme ne pose aucun diagnostic et renvoie au professionnel si "
        "la douleur dure ou augmente (R5-P23, R5-P25).",
    ],
    checks=[
        check("c1", "forbid_joint_stress", "Aucun exercice à contrainte forte "
              "sur le coude", joint="coude", stress="forte"),
        check("c2", "forbid_exercises", "Ni négatives, ni excentriques lents, "
              "ni surcharges en traction",
              exerciseIds=["sw-traction-negative",
                           "sw-traction-tempo-excentrique",
                           "sl-traction-negative-lestee-supramaximale",
                           "sl-traction-lestee-partielle-haute"]),
        check("c3", "max_group_sets", "Biceps : pas plus de 10 séries dures "
              "par semaine", group="biceps", sets=10),
        check("c4", "min_frequency", "Dips lesté au moins deux fois par "
              "semaine", exerciseIds=[D_LEST], perWeek=2),
        check("c5", "pattern_present", "Tirage horizontal au moins deux fois "
              "par semaine", patterns=["tirage_horizontal"], perWeek=2),
        check("c6", "min_rir_first_weeks", "Jamais moins de 2 répétitions en "
              "réserve sur les 12 semaines", weeks=12, rir=2),
    ],
)

add(
    "street_13_peu_de_temps", "street",
    "Peu de temps : trois séances de 45 minutes",
    "Femme de 35 ans, 62 kg, deux ans de pratique. 6 tractions, 10 dips, "
    "20 pompes. Travail prenant, deux enfants : trois séances de 45 minutes "
    "au plus, au parc. Veut entretenir et progresser un peu.",
    "intermediate", 24,
    core("female", 1991, 167, 62.0, street("sets_reps", 10, 70, 20),
         days((2, 45), (4, 45), (7, 45)), ["exterieur"], PARC_ELASTIQUE,
         experience="intermediate"),
    records=[rec(TRACTION, "max_reps", 6), rec(DIPS, "max_reps", 10),
             rec(POMPE, "max_reps", 20)],
    goals=[{"id": "g1", **target(TRACTION, "max_reps", 9), "weeksOut": 12}],
    recovery={"sleepHours": 6.5, "stress": 3},
    text=[
        "Dose minimale efficace : au moins 4 séries dures par groupe et par "
        "semaine, un mouvement de jambes, un tirage, une poussée à chaque "
        "séance (R5-P1).",
        "Supersets de mouvements antagonistes pour tenir dans le temps sans "
        "raccourcir le repos réel ; si le temps manque, on retire des séries "
        "avant de descendre sous 60 s de repos (R1-P15, R2-P15).",
        "Corps entier trois fois par semaine ; maximum de tractions entre 3 et "
        "12 : priorité mixte force et répétitions (R4-G2).",
    ],
    checks=[
        check("c1", "max_session_minutes", "Séances de 48 minutes au plus",
              minutes=48),
        check("c2", "min_frequency", "Tractions au moins deux fois par "
              "semaine", exerciseIds=[TRACTION], perWeek=2),
        check("c3", "pattern_present", "Jambes au moins deux fois par semaine",
              patterns=["squat", "fente"], perWeek=2),
        check("c4", "min_group_sets", "Grand dorsal : au moins 6 séries dures "
              "par semaine", group="lats", sets=6),
        check("c5", "min_group_sets", "Pectoraux : au moins 4 séries dures par "
              "semaine", group="chest", sets=4),
        check("c6", "format_present", "Supersets pour gagner du temps",
              formats=["superset"]),
    ],
)

add(
    "street_14_parc_sans_lest", "street",
    "Parc seulement, sans lest ni élastique",
    "Homme de 22 ans, 66 kg, trois ans de pratique. 18 tractions, 30 dips, "
    "50 pompes, 5 muscle-ups, pistol squat acquis. Aucun matériel : barres du "
    "parc seulement. Veut 25 tractions. Quatre séances d'une heure.",
    "intermediate", 36,
    core("male", 2004, 172, 66.0, street("sets_reps", 0, 70, 30),
         days((1, 60), (3, 60), (5, 60), (7, 60)), ["exterieur"], PARC,
         experience="intermediate", known=[MU, "sw-pistol-squat"]),
    records=[rec(TRACTION, "max_reps", 18), rec(DIPS, "max_reps", 30),
             rec(POMPE, "max_reps", 50), rec(MU, "max_reps", 5),
             rec("sw-pistol-squat", "max_reps", 6)],
    goals=[{"id": "g1", **target(TRACTION, "max_reps", 25), "weeksOut": 12}],
    text=[
        "Plus de 15 tractions : priorité à l'endurance spécifique, la force en "
        "entretien (R4-G2) ; sans lest, la force passe par les variantes "
        "dures (archer, typewriter, poitrine à la barre, tempo) (R1-P17).",
        "Tractions trois fois par semaine, densité progressive : d'abord plus "
        "de répétitions à repos fixe, puis repos réduit par paliers de 10 à "
        "15 s (R4-G4, R4-G8).",
        "Jambes au poids du corps en unilatéral (pistol, shrimp), avec une "
        "vraie progression.",
        "Volume hebdomadaire en hausse de 10 à 20 % par bloc, une semaine "
        "allégée ensuite (R4-G8).",
    ],
    checks=[
        check("c1", "min_frequency", "Tractions au moins trois fois par "
              "semaine", exerciseIds=[TRACTION], perWeek=3),
        check("c2", "short_rest_share", "Au moins un tiers des séries de "
              "tractions en densité", exerciseIds=[TRACTION],
              maxRestSeconds=90, minShare=0.33),
        check("c3", "pattern_present", "Jambes au moins deux fois par semaine",
              patterns=["squat", "fente"], perWeek=2),
        check("c4", "relief_every", "Pas plus de 6 semaines de charge sans "
              "allègement", weeks=6),
        check("c5", "min_frequency", "Une variante dure de traction (archer, "
              "typewriter, poitrine à la barre) au moins une fois par semaine",
              exerciseIds=["sw-traction-archer", "sw-traction-typewriter",
                           "sw-traction-chest-to-bar", "sw-traction-l-sit"],
              exact=True, perWeek=1),
    ],
)

add(
    "street_15_travail_physique_sommeil_court", "street",
    "Travail physique et sommeil court",
    "Homme de 41 ans, 84 kg, maçon, trois ans de pratique. 9 tractions, "
    "18 dips, 35 pompes. Dort 5 h 30 par nuit en semaine, stress élevé. Trois "
    "séances d'une heure au parc, après le travail.",
    "intermediate", 36,
    core("male", 1985, 179, 84.0, street("sets_reps", 10, 70, 20),
         days((2, 60), (4, 60), (6, 60)), ["exterieur"], PARC_ELASTIQUE,
         experience="intermediate"),
    records=[rec(TRACTION, "max_reps", 9), rec(DIPS, "max_reps", 18),
             rec(POMPE, "max_reps", 35)],
    goals=[{"id": "g1", **target(TRACTION, "max_reps", 12), "weeksOut": 12}],
    recovery={"sleepHours": 5.5, "sleepQuality": 2, "stress": 4,
              "physicalJob": "heavy"},
    text=[
        "Sommeil habituel sous 6 heures : volume réduit de 10 à 20 %, une "
        "répétition en réserve de plus, aucune hausse de volume tant que cela "
        "dure, intensité conservée (R5-P14, choix raisonné).",
        "Stress élevé : mêmes ajustements, fréquence conservée (R5-P15).",
        "Métier physique lourd : départ à la borne basse du volume sur le dos, "
        "la préhension et les jambes ; séance la plus lourde avant le jour de "
        "repos (R5-P18, choix raisonné).",
        "Les réductions se cumulent sans dépasser 40 % du volume de référence "
        "et sans passer sous la dose minimale (R5-P21).",
        "Réévaluer après 4 semaines : si la progression est normale, lever les "
        "réductions (R5-P18).",
    ],
    checks=[
        check("c1", "max_group_sets", "Grand dorsal : pas plus de 12 séries "
              "dures par semaine", group="lats", sets=12),
        check("c2", "max_group_sets", "Quadriceps : pas plus de 10 séries "
              "dures par semaine", group="quads", sets=10),
        check("c3", "min_rir_first_weeks", "Jamais moins de 2 répétitions en "
              "réserve sur les 12 semaines", weeks=12, rir=2),
        check("c4", "min_frequency", "Tractions au moins deux fois par "
              "semaine", exerciseIds=[TRACTION], perWeek=2),
        check("c5", "max_session_minutes", "Séances de 62 minutes au plus",
              minutes=62),
        check("c6", "min_group_sets", "Grand dorsal : au moins 6 séries dures "
              "par semaine", group="lats", sets=6),
    ],
)

add(
    "street_16_specialisation_traction_lestee", "street",
    "Spécialisation : priorité à la traction lestée",
    "Homme de 29 ans, 75 kg, cinq ans de pratique. Traction +50 kg, dips "
    "+85 kg, squat 150 kg. Veut +57,5 kg en traction dans 10 semaines ; dips "
    "et squat en entretien. Quatre séances de 90 minutes, en salle.",
    "advanced", 60,
    core("male", 1997, 176, 75.0, street("streetlifting", 80, 10, 10),
         days((1, 90), (3, 90), (5, 90), (6, 90)), ["salle"], STREET_SALLE,
         incr=INCR_SALLE, experience="advanced", guidance="free"),
    records=[rec(T_LEST, "one_rm_kg", 50, testedWeeksAgo=2),
             rec(D_LEST, "one_rm_kg", 85, testedWeeksAgo=2),
             rec(SQUAT_SL, "one_rm_kg", 150, testedWeeksAgo=2),
             rec(TRACTION, "max_reps", 22)],
    events=[{"id": "e1", "kind": "test", "label": "test de 1RM en traction "
             "lestée", "weeksOut": 10, "priority": "A", "format": "test",
             "targets": [target(T_LEST, "one_rm_kg", 57.5)]}],
    special={"priorityExerciseIds": [T_LEST],
             "maintainExerciseIds": [D_LEST, SQUAT_SL]},
    text=[
        "Volume de la traction lestée à +20 % du volume habituel au départ, "
        "puis +10 à +20 % toutes les deux semaines si la récupération tient ; "
        "le volume ajouté est pris sur le reste (R4-H2).",
        "Dips et squat en entretien : un tiers à la moitié du volume habituel, "
        "une à deux expositions par semaine, sans baisser la charge (R4-H1).",
        "Traction lestée trois à quatre fois par semaine : une séance lourde, "
        "une de volume, une variante ou technique (R2-P7).",
        "Bloc de 8 à 12 semaines, semaine allégée toutes les 3 à 5 semaines, "
        "test après un allègement (R4-H3, R3-P16).",
        "Sortie : la traction repasse en entretien, le reste remonte par "
        "paliers (R4-H3).",
    ],
    checks=[
        check("c1", "min_frequency", "Traction lestée au moins trois fois par "
              "semaine", exerciseIds=[T_LEST], perWeek=3),
        check("c2", "priority_share", "Au moins 30 % des séries dures sur la "
              "traction lestée et ses variantes", exerciseIds=[T_LEST],
              minShare=0.30),
        check("c3", "weekly_sets_between", "Dips lesté en entretien : 3 à 8 "
              "séries dures par semaine", exerciseIds=[D_LEST], min=3, max=8),
        check("c4", "weekly_sets_between", "Squat en entretien : 3 à 8 séries "
              "dures par semaine", exerciseIds=[SQUAT_SL], min=3, max=8),
        check("c5", "has_taper", "Volume réduit de 30 à 60 % la semaine du "
              "test", minDrop=0.3, maxDrop=0.6),
        check("c6", "test_at_event", "Épreuve de traction lestée la semaine "
              "du test"),
        check("c7", "heavy_exposure", "Une exposition lourde par semaine au "
              "moins en traction lestée", exerciseIds=[T_LEST],
              minPercent=0.85, maxReps=5, perWeek=1),
        check("c8", "relief_every", "Pas plus de 5 semaines de charge sans "
              "allègement", weeks=5),
    ],
)

add(
    "street_17_hybride_street_course", "street",
    "Hybride street et course",
    "Femme de 31 ans, 60 kg, deux ans de street workout et de course. "
    "8 tractions, 14 dips, 25 pompes ; 10 km en 52 minutes. Veut progresser "
    "sur les deux. Cinq séances.",
    "intermediate", 24,
    core("female", 1995, 168, 60.0,
         mix("street_workout", 60, ("cardio", 40)),
         days((1, 60), (2, 45), (4, 60), (6, 60), (7, 75)), ["exterieur"],
         PARC_ELASTIQUE + ["piste ou terrain extérieur", "côte ou escaliers"],
         experience="intermediate"),
    records=[rec(TRACTION, "max_reps", 8), rec(DIPS, "max_reps", 14),
             rec(POMPE, "max_reps", 25),
             rec("ca-footing-endurance-fondamentale", "time_seconds", 3120,
                 distanceMeters=10000)],
    goals=[{"id": "g1", **target(TRACTION, "max_reps", 11), "weeksOut": 12},
           {"id": "g2", **target("ca-footing-endurance-fondamentale",
                                 "time_seconds", 3000, distanceMeters=10000),
            "weeksOut": 12}],
    text=[
        "Force et course séparées de 6 heures ou sur des jours différents ; "
        "force d'abord si même séance (R6-P30, R5-P19).",
        "Jambes lourdes à distance des séances de course intenses ; volume de "
        "jambes modéré (R5-P19).",
        "Course : 75 à 85 % du temps en endurance facile, une séance de "
        "qualité par semaine ; aucune sortie au-delà de 110 % de la plus "
        "longue des 30 derniers jours (R6-P15, R6-P16).",
        "Street : tractions et dips deux à trois fois par semaine.",
    ],
    checks=[
        check("c1", "min_weekly_minutes", "Au moins 90 minutes de course par "
              "semaine", kind="cardio", minutes=90),
        check("c2", "min_frequency", "Tractions au moins deux fois par "
              "semaine", exerciseIds=[TRACTION], perWeek=2),
        check("c3", "min_frequency", "Dips au moins deux fois par semaine",
              exerciseIds=[DIPS], perWeek=2),
        check("c4", "pattern_present", "Au plus une séance de course intense "
              "par semaine : une séance de fractionné présente",
              patterns=["cardio_fractionne"], perWeek=0.5),
        check("c5", "max_group_sets", "Quadriceps : pas plus de 12 séries "
              "dures par semaine", group="quads", sets=12),
        check("c6", "relief_every", "Pas plus de 6 semaines de charge sans "
              "allègement", weeks=6),
    ],
)

# ======================================================================
# AUTRES DISCIPLINES (10 profils)
# ======================================================================

SQ = "mu-back-squat-barre-haute"
SQ_LOW = "mu-back-squat-barre-basse"
DC = "mu-developpe-couche-barre"
SDT = "mu-souleve-de-terre-conventionnel"
FOOTING = "ca-footing-endurance-fondamentale"
SORTIE = "ca-sortie-longue"

add(
    "autres_01_debutant_musculation", "autres",
    "Débutant en musculation",
    "Homme de 22 ans, 68 kg, jamais entraîné. Veut prendre du muscle et de "
    "la force. Trois séances d'une heure, en salle.",
    "beginner", 0,
    core("male", 2004, 179, 68.0, mix("musculation", 100),
         days((1, 60), (3, 60), (5, 60)), ["salle"], SALLE, incr=INCR_SALLE,
         experience="beginner"),
    unknown=[SQ, DC],
    habit={"sessionsPerWeek": 3, "weeks": 12},
    text=[
        "Corps entier trois fois par semaine, 6 à 10 séries dures par groupe, "
        "8 à 15 répétitions, 2 à 4 en réserve (R6-P1 à P3).",
        "Polyarticulaires d'abord (squat ou presse, développé, tirage, "
        "charnière), un exercice par muscle, amplitude complète (R6-P4, P5).",
        "Double progression, charges à calibrer sur les premières séances, "
        "aucun 1RM vrai (R5-P3, R3-P16).",
    ],
    checks=[
        check("c1", "min_rir_first_weeks", "Au moins 2 répétitions en réserve "
              "les quatre premières semaines", weeks=4, rir=2),
        check("c2", "pattern_present", "Squat ou presse au moins deux fois par "
              "semaine", patterns=["squat"], perWeek=2),
        check("c3", "pattern_present", "Tirage au moins deux fois par semaine",
              patterns=["tirage_vertical", "tirage_horizontal"], perWeek=2),
        check("c4", "max_group_sets", "Pectoraux : pas plus de 12 séries "
              "dures par semaine", group="chest", sets=12),
        check("c5", "min_group_sets", "Quadriceps : au moins 5 séries dures "
              "par semaine", group="quads", sets=5),
        check("c6", "max_exercise_level", "Aucun exercice avancé ou élite",
              level="Intermédiaire"),
    ],
)

add(
    "autres_02_hypertrophie_intermediaire", "autres",
    "Hypertrophie esthétique, intermédiaire",
    "Femme de 27 ans, 61 kg, trois ans de musculation. Squat 80 kg, "
    "développé couché 45 kg, hip thrust 110 kg. Veut développer fessiers et "
    "épaules. Cinq séances de 75 minutes, en salle.",
    "intermediate", 36,
    core("female", 1999, 166, 61.0, mix("musculation", 100),
         days((1, 75), (2, 75), (4, 75), (5, 75), (6, 75)), ["salle"], SALLE,
         incr=INCR_SALLE, experience="intermediate"),
    records=[rec(SQ, "one_rm_kg", 80), rec(DC, "one_rm_kg", 45),
             rec("mu-hip-thrust-barre", "one_rm_kg", 110)],
    weak=[{"kind": "muscle", "muscleGroup": "glutes",
           "note": "fessiers à développer en priorité"},
          {"kind": "muscle", "muscleGroup": "delt_middle",
           "note": "épaules (faisceau moyen) en retard"}],
    text=[
        "10 à 16 séries dures par groupe et par semaine ; points faibles à "
        "+30 à 50 % de séries, en début de séance, deux à trois fois par "
        "semaine ; le reste en entretien (R6-P1, R6-P6).",
        "Polyarticulaires en 6 à 10 répétitions à 1-3 en réserve, isolations "
        "en 10 à 20 à 0-2 ; un exercice en position étirée par muscle (R6-P2, "
        "R6-P4).",
        "Répartition déduite des cinq jours : haut / bas ou poussée / tirage / "
        "jambes, pas plus de 10 séries par muscle et par séance (R6-P3).",
        "Décharge toutes les 4 à 8 semaines (R6-P1).",
    ],
    checks=[
        check("c1", "min_group_sets", "Fessiers : au moins 14 séries dures "
              "par semaine", group="glutes", sets=14),
        check("c2", "min_group_sets", "Deltoïde moyen : au moins 10 séries "
              "dures par semaine", group="delt_middle", sets=10),
        check("c3", "max_group_sets", "Fessiers : pas plus de 25 séries dures "
              "par semaine", group="glutes", sets=25),
        check("c4", "relief_every", "Pas plus de 7 semaines de charge sans "
              "allègement", weeks=7),
        check("c5", "pattern_present", "Isolation des épaules au moins deux "
              "fois par semaine", patterns=["isolation_epaules"], perWeek=2),
    ],
)

add(
    "autres_03_powerlifter_competition", "autres",
    "Powerlifter, compétition dans 10 semaines",
    "Homme de 32 ans, 93 kg, six ans de force athlétique. Squat 220 kg, "
    "développé couché 150 kg, soulevé de terre 260 kg. Compétition dans "
    "10 semaines. Quatre séances de deux heures.",
    "advanced", 72,
    core("male", 1994, 180, 93.0, mix("musculation", 100),
         days((1, 120), (2, 120), (4, 120), (6, 120)), ["salle"], SALLE,
         incr=INCR_SALLE, experience="advanced", guidance="free"),
    records=[rec(SQ_LOW, "one_rm_kg", 220, testedWeeksAgo=4),
             rec(DC, "one_rm_kg", 150, testedWeeksAgo=4),
             rec(SDT, "one_rm_kg", 260, testedWeeksAgo=4)],
    events=[{"id": "e1", "kind": "competition", "label": "compétition de "
             "force athlétique", "weeksOut": 10, "priority": "A",
             "format": "powerlifting", "targets": [
                 target(SQ_LOW, "one_rm_kg", 227.5),
                 target(DC, "one_rm_kg", 155),
                 target(SDT, "one_rm_kg", 267.5)]}],
    text=[
        "Squat deux à trois fois, couché trois à quatre fois, terre une à deux "
        "fois par semaine (R6-P8) ; intensité moyenne de 75 à 85 % avec des "
        "expositions régulières à 90 % et plus (R6-P9).",
        "Une variante par mouvement ciblant la phase faible, accessoires en "
        "baisse à l'approche de la compétition (R6-P10).",
        "Affûtage de 10 à 14 jours, volume réduit de 30 à 60 %, dernier squat "
        "et dernier terre lourds de J-10 à J-7, couché de J-7 à J-5 (R6-P11).",
    ],
    checks=[
        check("c1", "has_taper", "Volume réduit de 30 à 70 % la semaine de la "
              "compétition", minDrop=0.3, maxDrop=0.7),
        check("c2", "min_frequency", "Squat au moins deux fois par semaine",
              exerciseIds=[SQ_LOW, SQ], perWeek=2),
        check("c3", "min_frequency", "Développé couché au moins trois fois "
              "par semaine", exerciseIds=[DC], perWeek=3),
        check("c4", "min_frequency", "Soulevé de terre au moins une fois par "
              "semaine", exerciseIds=[SDT], perWeek=1),
        check("c5", "load_prescribed", "Charges chiffrées sur les trois "
              "mouvements", exerciseIds=[SQ_LOW, DC, SDT]),
        check("c6", "heavy_exposure", "Une exposition lourde par semaine au "
              "moins au squat", exerciseIds=[SQ_LOW, SQ], minPercent=0.85,
              maxReps=5, perWeek=1),
        check("c7", "test_at_event", "Épreuve sur les trois mouvements la "
              "semaine de la compétition"),
    ],
)

add(
    "autres_04_force_generale_46_ans", "autres",
    "Force générale après 40 ans",
    "Homme de 46 ans, 85 kg, deux ans de musculation. Squat 100 kg, "
    "développé couché 80 kg, soulevé de terre 130 kg. Lombalgie il y a huit "
    "mois, plus de gêne. Trois séances de 75 minutes.",
    "intermediate", 24,
    core("male", 1980, 182, 85.0, mix("musculation", 80, ("mobility", 20)),
         days((1, 75), (3, 75), (5, 75)), ["salle"], SALLE, incr=INCR_SALLE,
         experience="intermediate"),
    records=[rec(SQ, "one_rm_kg", 100), rec(DC, "one_rm_kg", 80),
             rec(SDT, "one_rm_kg", 130)],
    goals=[{"id": "g1", **target(SQ, "one_rm_kg", 115), "weeksOut": 16}],
    injuries=[{"zone": "lower_back", "side": "both", "discomfort": 0,
               "status": "history", "monthsAgo": 8,
               "label": "lombalgie il y a huit mois, résolue"}],
    recovery={"sleepHours": 6.5, "stress": 3},
    text=[
        "Trois séances corps entier ou presque, 75 à 90 % sur les mouvements "
        "de base, 8 à 12 séries par mouvement et par semaine (R6-P9).",
        "Antécédent lombaire de moins de 12 mois : progression à demi-vitesse "
        "sur la charnière et le squat lourds, aucun échec dessus, vigilance "
        "dès 3 sur 10 (R5-P20).",
        "40 à 59 ans : progression de volume ralentie, échauffement allongé "
        "(R5-P10) ; mobilité utile en complément (R6-P24).",
    ],
    checks=[
        check("c1", "min_frequency", "Squat au moins deux fois par semaine",
              exerciseIds=[SQ, SQ_LOW], perWeek=2),
        check("c2", "load_prescribed", "Charges chiffrées au squat et au "
              "développé couché", exerciseIds=[SQ, DC]),
        check("c3", "relief_every", "Pas plus de 6 semaines de charge sans "
              "allègement", weeks=6),
        check("c4", "min_rir_first_weeks", "Jamais moins d'une répétition en "
              "réserve", weeks=16, rir=1),
        check("c5", "min_weekly_minutes", "Au moins 20 minutes de mobilité par "
              "semaine", kind="mobility", minutes=20),
    ],
)

add(
    "autres_05_course_10_km_debutante", "autres",
    "Course : premier 10 km",
    "Femme de 34 ans, 64 kg, court depuis six mois : 5 km en 35 minutes. "
    "Veut finir un 10 km dans 12 semaines. Trois séances de 45 à 60 minutes.",
    "beginner", 6,
    core("female", 1992, 166, 64.0, mix("cardio", 90, ("mobility", 10)),
         days((2, 45), (4, 45), (7, 60)), ["exterieur"],
         ["piste ou terrain extérieur", "côte ou escaliers", "tapis"],
         experience="beginner"),
    records=[rec(FOOTING, "time_seconds", 2100, distanceMeters=5000)],
    events=[{"id": "e1", "kind": "competition", "label": "course de 10 km",
             "weeksOut": 12, "priority": "A", "format": "course",
             "targets": [target(FOOTING, "time_seconds", 4200,
                                distanceMeters=10000)]}],
    text=[
        "Tout en endurance facile pendant 6 à 8 semaines, puis au plus une "
        "séance de qualité par semaine (R6-P15).",
        "Progression en minutes ; aucune sortie au-delà de 110 % de la plus "
        "longue des 30 derniers jours ; semaine allégée toutes les 3 à 4 "
        "semaines (R6-P16).",
        "Sortie longue de 20 à 30 % du volume hebdomadaire (R6-P19) ; affûtage "
        "court de 5 à 7 jours (R6-P20).",
        "Deux petites séances de renforcement (mollets, hanches) dès le début "
        "(R6-P17, R6-P22).",
    ],
    checks=[
        check("c1", "min_weekly_minutes", "Au moins 90 minutes de course par "
              "semaine", kind="cardio", minutes=90),
        check("c2", "forbid_patterns", "Pas de sprint", patterns=["sprint"]),
        check("c3", "has_taper", "Semaine de la course allégée d'au moins "
              "20 %", minDrop=0.0, maxDrop=1.0),
        check("c4", "relief_every", "Pas plus de 4 semaines de charge sans "
              "allègement", weeks=4),
        check("c5", "max_session_minutes", "Séances de 65 minutes au plus",
              minutes=65),
    ],
)

add(
    "autres_06_semi_marathon_intermediaire", "autres",
    "Semi-marathon, intermédiaire",
    "Homme de 38 ans, 72 kg, court depuis quatre ans : 10 km en 48 minutes, "
    "30 km par semaine. Semi-marathon dans 12 semaines, objectif 1 h 45. "
    "Quatre séances.",
    "intermediate", 48,
    core("male", 1988, 178, 72.0,
         mix("cardio", 80, ("musculation", 10), ("mobility", 10)),
         days((2, 60), (4, 60), (6, 45), (7, 120)), ["exterieur"],
         ["piste ou terrain extérieur", "côte ou escaliers", "tapis",
          "élastique"], experience="intermediate"),
    records=[rec(FOOTING, "time_seconds", 2880, distanceMeters=10000)],
    events=[{"id": "e1", "kind": "competition", "label": "semi-marathon",
             "weeksOut": 12, "priority": "A", "format": "course",
             "targets": [target(SORTIE, "time_seconds", 6300,
                                distanceMeters=21097.5)]}],
    text=[
        "Volume de pointe de 35 à 55 km par semaine, sortie longue de 18 à "
        "22 km, quatre à cinq séances (R6-P19).",
        "80 % en endurance facile, une à deux séances de qualité (seuil, "
        "intervalles de 3 à 4 minutes), jamais deux jours intenses de suite "
        "(R6-P15, R6-P18).",
        "Hausse hebdomadaire de 10 à 20 %, jamais 30 % ; semaine allégée "
        "toutes les 3 à 4 semaines (R6-P16).",
        "Affûtage de 10 à 14 jours, volume réduit de 40 à 60 %, rappels "
        "d'allure conservés (R6-P20).",
        "Un à deux renforcements par semaine, coupés 7 à 10 jours avant "
        "(R6-P22).",
    ],
    checks=[
        check("c1", "min_weekly_minutes", "Au moins 180 minutes de course par "
              "semaine", kind="cardio", minutes=180),
        check("c2", "pattern_present", "Une séance de qualité (fractionné) par "
              "semaine", patterns=["cardio_fractionne"], perWeek=1),
        check("c3", "min_frequency", "Sortie longue chaque semaine",
              exerciseIds=[SORTIE], exact=True, perWeek=1),
        check("c4", "relief_every", "Pas plus de 4 semaines de charge sans "
              "allègement", weeks=4),
        check("c5", "weeks_kind_present", "Une semaine allégée ou de test "
              "avant la course", kind="test", min=1),
    ],
)

add(
    "autres_07_mobilite_sante_senior", "autres",
    "Mobilité et santé, senior",
    "Femme de 68 ans, 63 kg, marche régulièrement, jamais de musculation. "
    "Veut rester autonome, gagner en souplesse et en équilibre. Quatre "
    "séances de 30 minutes à la maison. Questionnaire santé : mode prudent.",
    "beginner", 0,
    core("female", 1958, 160, 63.0,
         mix("mobility", 50, ("general_fitness", 50)),
         days((1, 30), (3, 30), (5, 30), (7, 30)), ["maison", "exterieur"],
         ["tapis", "élastique", "bâton", "piste ou terrain extérieur"],
         experience="beginner", sante=SANTE_PRUDENT),
    habit={"sessionsPerWeek": 4, "weeks": 12},
    text=[
        "Programme multicomposant : équilibre au moins trois jours par "
        "semaine, renforcement deux à trois jours, marche pour viser 150 "
        "minutes par semaine (R6-P26, R6-P21).",
        "Senior débutant : assis-debout, appui disponible, 1 à 2 séries de 10 "
        "à 15 répétitions à effort modéré ; la difficulté d'équilibre "
        "progresse avant la charge (R6-P26).",
        "Aucun impact ni saut ; étirements de 30 à 60 s, cinq jours par "
        "semaine pour progresser (R6-P23).",
        "L'intensité relative n'est pas bridée par l'âge quand la personne "
        "progresse (R5-P10).",
    ],
    checks=[
        check("c1", "forbid_patterns", "Ni saut, ni sprint, ni corde",
              patterns=["pliometrie", "sprint", "corde_a_sauter",
                        "balistique", "halterophilie"]),
        check("c2", "min_weekly_minutes", "Au moins 30 minutes de mobilité par "
              "semaine", kind="mobility", minutes=30),
        check("c3", "max_session_minutes", "Séances de 33 minutes au plus",
              minutes=33),
        check("c4", "min_rir_first_weeks", "Au moins 3 répétitions en réserve",
              weeks=12, rir=3),
        check("c5", "pattern_present", "Renforcement des jambes (squat, "
              "fente, assis-debout) au moins deux fois par semaine",
              patterns=["squat", "fente", "extension_hanche"], perWeek=2),
    ],
)

add(
    "autres_08_crossfit_intermediaire", "autres",
    "CrossFit, intermédiaire",
    "Homme de 29 ans, 80 kg, deux ans de CrossFit. Squat 120 kg, épaulé-jeté "
    "80 kg, 10 tractions strictes. Cinq séances d'une heure en box.",
    "intermediate", 24,
    core("male", 1997, 178, 80.0, mix("crossfit", 80, ("mobility", 20)),
         days((1, 60), (2, 60), (3, 60), (5, 60), (6, 60)), ["salle"],
         ["barre fixe", "barre olympique", "disques", "haltères",
          "kettlebell", "box / plinth", "corde à sauter", "rameur",
          "air bike (assault / echo)", "médecine-ball",
          "cible murale (wall ball)", "anneaux", "corde", "tapis", "mur",
          "cage / rack", "GHD"], incr=INCR_SALLE, experience="intermediate"),
    records=[rec(SQ, "one_rm_kg", 120), rec("mu-epaule-jete", "one_rm_kg", 80),
             rec(TRACTION, "max_reps", 10), rec("cf-burpee", "max_reps", 25)],
    goals=[{"id": "g1", **target(MU, "skill_unlocked"), "weeksOut": 16}],
    text=[
        "Séance type : échauffement, bloc de force ou de technique de 15 à 20 "
        "minutes, conditionnement de 8 à 20 minutes ; durées mélangées sur la "
        "semaine (court, moyen, long) (R6-P27).",
        "Formats codifiés attendus : AMRAP, EMOM, tours chronométrés (R6-P27).",
        "Pas d'haltérophilie lourde ni de gymnastique technique sous fatigue "
        "pour qui ne les maîtrise pas frais ; strict avant kipping (R6-P28).",
        "Trois à cinq séances ; pas deux jours longs et lourds de suite sur "
        "les mêmes schémas (R6-P27).",
    ],
    checks=[
        check("c1", "format_present", "Formats codifiés (AMRAP, EMOM, tours)",
              formats=["amrap", "emom", "rounds"]),
        check("c2", "pattern_present", "Haltérophilie ou force à la barre au "
              "moins trois fois par semaine",
              patterns=["halterophilie", "squat", "charniere_hanche"],
              perWeek=3),
        check("c3", "min_weekly_minutes", "Au moins 30 minutes de "
              "conditionnement par semaine", kind="conditioning", minutes=30),
        check("c4", "relief_every", "Pas plus de 7 semaines de charge sans "
              "allègement", weeks=7),
        check("c5", "min_frequency", "Travail vers le muscle-up au moins deux "
              "fois par semaine", exerciseIds=[MU], perWeek=2),
    ],
)

add(
    "autres_09_perte_de_poids_debutante", "autres",
    "Perte de poids, débutante",
    "Femme de 42 ans, 92 kg pour 1,68 m, sédentaire. Veut perdre du poids "
    "durablement. Trois séances de 45 minutes en salle, et de la marche.",
    "beginner", 0,
    core("female", 1984, 168, 92.0, mix("general_fitness", 100),
         days((1, 45), (3, 45), (6, 45)), ["salle", "exterieur"],
         SALLE + ["piste ou terrain extérieur"], incr=INCR_SALLE,
         experience="beginner"),
    habit={"sessionsPerWeek": 3, "weeks": 12},
    recovery={"sleepHours": 6.5, "stress": 3, "energyDeficit": True},
    text=[
        "Musculation corps entier deux à trois fois par semaine, 6 à 8 "
        "exercices, 2 à 3 séries de 8 à 12 répétitions à 2-3 en réserve ; la "
        "charge progresse normalement, même en déficit (R6-P31).",
        "Cardio à faible impact : marche, vélo, rameur ; ni course, ni sauts, "
        "ni burpees au début (R6-P32).",
        "Exercices stables où la personne se sent compétente (machines, appuis "
        "stables) (R6-P32).",
        "Aucune prescription alimentaire (R6-P31).",
    ],
    checks=[
        check("c1", "forbid_patterns", "Ni saut, ni sprint, ni corde, ni "
              "burpees", patterns=["pliometrie", "sprint", "corde_a_sauter",
                                   "balistique", "conditionnement"]),
        check("c2", "forbid_exercises", "Pas de course à pied au début",
              exerciseIds=[FOOTING, SORTIE, "ca-course-tapis-endurance",
                           "ca-course-seuil-tempo", "ca-course-30-30",
                           "ca-fartlek"]),
        check("c3", "min_weekly_minutes", "Au moins 30 minutes de cardio à "
              "faible impact par semaine", kind="cardio", minutes=30),
        check("c4", "min_rir_first_weeks", "Au moins 2 répétitions en réserve "
              "les quatre premières semaines", weeks=4, rir=2),
        check("c5", "min_group_sets", "Quadriceps : au moins 4 séries dures "
              "par semaine", group="quads", sets=4),
        check("c6", "max_exercise_level", "Exercices de niveau débutant ou "
              "intermédiaire", level="Intermédiaire"),
    ],
)

add(
    "autres_10_contraintes_multiples", "autres",
    "Contraintes multiples",
    "Homme de 55 ans, 88 kg, reprend après des années. Genou droit sensible "
    "(gêne 5 sur 10), épaule gauche opérée il y a deux ans, sommeil de six "
    "heures, questionnaire santé en mode prudent. Deux séances de 40 minutes "
    "et une de 30, à la maison avec haltères et élastiques.",
    "beginner", 3,
    core("male", 1971, 175, 88.0,
         mix("musculation", 60, ("mobility", 20), ("cardio", 20)),
         days((2, 40), (4, 30), (6, 40)), ["maison"],
         ["haltères", "élastique", "tapis", "banc plat",
          "vélo / home-trainer"],
         incr=[{"loadType": "halteres", "stepKg": 2.0, "minKg": 2.0}],
         experience="beginner", sante=SANTE_PRUDENT),
    habit={"sessionsPerWeek": 3, "weeks": 12},
    injuries=[{"zone": "knee", "side": "right", "discomfort": 5,
               "status": "current",
               "label": "genou droit douloureux à la flexion profonde"},
              {"zone": "shoulder", "side": "left", "discomfort": 0,
               "status": "history", "monthsAgo": 24,
               "label": "épaule gauche opérée il y a deux ans, sans gêne"}],
    recovery={"sleepHours": 6.0, "stress": 3},
    pause=200,
    text=[
        "Mode prudent : aucun impact, charges modérées, 3 répétitions en "
        "réserve au moins, aucune isométrie maximale longue, respiration "
        "continue (R5-P28, R5-P26).",
        "Genou à 5 sur 10 : aucune flexion profonde sous charge, variantes "
        "dans l'amplitude indolore, cardio sans appui contraignant (vélo) "
        "(R5-P23).",
        "Reprise après une très longue coupure : 1 à 2 séries par exercice, "
        "montée sur 6 à 10 semaines (R5-P7).",
        "Épaule opérée il y a plus de 12 mois, sans gêne : volume normal, "
        "vigilance (R5-P20).",
        "Séances courtes : 3 à 5 mouvements, dose minimale (R5-P1).",
    ],
    checks=[
        check("c1", "forbid_joint_stress", "Aucun exercice à contrainte forte "
              "sur le genou", joint="genou", stress="forte"),
        check("c2", "forbid_patterns", "Ni saut, ni sprint, ni course",
              patterns=["pliometrie", "sprint", "corde_a_sauter",
                        "balistique"]),
        check("c3", "min_rir_first_weeks", "Au moins 3 répétitions en réserve "
              "sur les 12 semaines", weeks=12, rir=3),
        check("c4", "max_session_minutes", "Séances de 44 minutes au plus",
              minutes=44),
        check("c5", "max_group_sets", "Quadriceps : pas plus de 8 séries dures "
              "par semaine", group="quads", sets=8),
        check("c6", "min_weekly_minutes", "Au moins 15 minutes de mobilité par "
              "semaine", kind="mobility", minutes=15),
    ],
)


# ======================================================================
CHECK_TYPES = {
    "min_frequency", "max_frequency", "has_taper", "test_at_event",
    "relief_every", "min_group_sets", "max_group_sets", "min_weekly_minutes",
    "max_session_minutes", "pattern_present", "forbid_patterns",
    "forbid_exercises", "forbid_joint_stress", "format_present",
    "load_prescribed", "heavy_exposure", "min_rir_first_weeks",
    "max_exercise_level", "priority_share", "weekly_sets_between",
    "short_rest_share", "straight_arm_days_max", "distinct_week_types",
    "weeks_kind_present",
}
GROUPS = {
    "chest", "delt_anterior", "delt_middle", "delt_posterior", "lats",
    "upper_back", "biceps", "triceps", "abs", "lower_back", "glutes", "quads",
    "hamstrings", "calves", "forearms", "adductors", "upper_traps",
}


def validate() -> None:
    cat = json.load(gzip.open(CATALOG))
    ids = {e["id"] for e in cat["exercices"]}
    patterns = {e["calc"]["schema"] for e in cat["exercices"]}
    equipment = set(cat["vocabulaires"]["materiel"])
    keys = set()
    for p in P:
        key = p["key"]
        assert key not in keys, key
        keys.add(key)

        def need(x, where):
            assert x in ids, f"{key} : exercice inconnu {x} ({where})"

        c = p["core"]
        for e in c["equipment"]:
            assert e in equipment, f"{key} : matériel inconnu {e}"
        d = c["disciplines"]
        assert d["primaryPct"] + sum(s["pct"] for s in d["secondaries"]) == 100
        assert all(d["primaryPct"] >= s["pct"] for s in d["secondaries"]), key
        assert len(d["secondaries"]) <= 2
        for f in ("likedExerciseIds", "dislikedExerciseIds",
                  "knownExerciseIds", "cannotDoExerciseIds"):
            for x in c.get(f, []):
                need(x, f)
        for r in p["records"]:
            need(r["exerciseId"], "records")
        for x in p.get("unknownLevels", []):
            need(x, "unknownLevels")
        for e in p.get("events", []):
            for t in e["targets"]:
                need(t["exerciseId"], "events")
        for g in p.get("goals", []):
            need(g["exerciseId"], "goals")
        for w in p.get("weakPoints", []):
            if "exerciseId" in w:
                need(w["exerciseId"], "weakPoints")
            if "muscleGroup" in w:
                assert w["muscleGroup"] in GROUPS, key
        s = p.get("specialization", {})
        for x in s.get("priorityExerciseIds", []) + s.get(
                "maintainExerciseIds", []):
            need(x, "specialization")
        seen = set()
        for ch in p["expectations"]["checks"]:
            assert ch["type"] in CHECK_TYPES, f"{key} : {ch['type']}"
            assert ch["id"] not in seen, key
            seen.add(ch["id"])
            for x in ch.get("exerciseIds", []):
                need(x, ch["id"])
            for x in ch.get("patterns", []):
                assert x in patterns, f"{key} : schéma inconnu {x}"
            if "group" in ch:
                assert ch["group"] in GROUPS, key
    street_n = sum(1 for p in P if p["group"] == "street")
    assert street_n >= 16 and len(P) - street_n >= 10, (street_n, len(P))


def main() -> int:
    validate()
    check_only = "--check" in sys.argv
    OUT.mkdir(exist_ok=True)
    stale = []
    for p in P:
        text = json.dumps(p, ensure_ascii=False, indent=1) + "\n"
        path = OUT / f"{p['key']}.json"
        if check_only:
            if not path.exists() or path.read_text(encoding="utf-8") != text:
                stale.append(path.name)
        else:
            path.write_text(text, encoding="utf-8")
    expected = {f"{p['key']}.json" for p in P}
    extra = sorted(f.name for f in OUT.glob("*.json") if f.name not in expected)
    if check_only and (stale or extra):
        print("profils à régénérer :", stale, "en trop :", extra)
        return 1
    print(f"{len(P)} profils ({sum(1 for p in P if p['group'] == 'street')} "
          f"street, {sum(1 for p in P if p['group'] == 'autres')} autres)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
