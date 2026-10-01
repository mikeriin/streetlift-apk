#!/usr/bin/env python3
"""Génère les jeux de données communs de kalis_core (test/fixtures/).

    python3 packages/kalis_core/tool/gen_fixtures.py          # écrit
    python3 packages/kalis_core/tool/gen_fixtures.py --check  # vérifie qu'ils sont à jour

- profiles.json : 40 profils types (AthleteProfile v2) ;
- journals.json.gz : journaux synthétiques de 4 à 24 semaines (TrainingLog),
  simulés par un modèle d'athlète dont les paramètres vrais sont fournis ;
- owner_program_v33.json.gz : le programme du propriétaire normalisé, en
  lecture seule (test de non-ressemblance de kalis_plan, D4.1) ;
- legacy_journal.json : un journal anonymisé au format actuel de
  l'application et sa conversion (docs/CONVERSION_JOURNAL.md).

Tout est déterministe (graines fixes, aucune horloge). Les séances simulées
ne viennent d'aucun moteur : des gabarits simples écrits ici, qui ne servent
qu'à produire des données plausibles.
"""
from __future__ import annotations

import argparse
import datetime as dt
import gzip
import hashlib
import io
import json
import math
import random
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import spec_validate  # noqa: E402

PKG = Path(__file__).resolve().parents[1]
RACINE = PKG.parents[1]
FIX = PKG / "test/fixtures"
CATALOGUE = json.loads(gzip.decompress((PKG / "data/catalog_v1.json.gz").read_bytes()).decode("utf-8"))
EX = {e["id"]: e for e in CATALOGUE["exercices"]}
MATERIEL = set(CATALOGUE["vocabulaires"]["materiel"])
JOUR0 = "2026-10-01"  # jour de création des profils


def fromrir(rir: float) -> int:
    """Même règle que Flames.fromRir (lib/src/flames.dart)."""
    if rir >= 5:
        return 1
    halves = math.ceil(rir * 2 - 0.5)
    if halves <= 0:
        return 10
    return 9 if halves == 1 else 11 - halves


def tojir(flames: int) -> float:
    return 0.0 if flames == 10 else (11 - flames) / 2


# ---------------------------------------------------------------------------
# 1. Profils types
# ---------------------------------------------------------------------------

SANS = ["tapis"]
MAISON_BASE = ["tapis", "élastique", "haltères"]
MAISON_BARRE = ["tapis", "élastique", "barre fixe", "anneaux", "parallettes"]
PARC = ["barre fixe", "barres parallèles", "barre basse", "élastique"]
SALLE = [
    "barre fixe", "barres parallèles", "barre basse", "barre olympique", "barre EZ", "disques",
    "haltères", "kettlebell", "élastique", "poulie", "machine guidée", "Smith machine",
    "presse à cuisses", "machine à mollets", "banc plat", "banc inclinable", "banc à lombaires",
    "cage / rack", "box / plinth", "step", "tapis", "corde à sauter", "rameur",
    "vélo / home-trainer", "tapis de course", "médecine-ball", "roue abdominale",
    "rouleau de massage (foam roller)", "corde",
]
STREETLIFT = PARC + ["ceinture de lest", "disques", "barre olympique", "cage / rack", "magnésie",
                     "banc plat", "haltères", "poulie", "barre EZ", "anneaux", "tapis", "box / plinth"]
CROSSFIT = ["barre fixe", "barre olympique", "disques", "haltères", "kettlebell", "box / plinth",
            "corde à sauter", "rameur", "air bike (assault / echo)", "médecine-ball",
            "cible murale (wall ball)", "anneaux", "corde", "tapis", "mur", "cage / rack", "GHD"]
COURSE = ["piste ou terrain extérieur", "côte ou escaliers", "tapis", "corde à sauter"]

INC = {
    "salle": [("barre", 2.5, 20.0), ("halteres", 2.0, 2.0), ("machine", 5.0, 5.0), ("poulie", 2.5, 2.5),
              ("kettlebell", 4.0, 4.0), ("lest", 1.25, 0.0)],
    "maison": [("halteres", 2.0, 2.0), ("kettlebell", 4.0, 8.0)],
    "street": [("lest", 1.25, 0.0), ("barre", 2.5, 20.0), ("halteres", 2.0, 2.0), ("poulie", 2.5, 2.5)],
    "aucun": [],
}


def mix(primary: str, pct: int = 100, *sec: tuple[str, int]) -> dict:
    return {"primary": primary, "primaryPct": pct,
            "secondaries": [{"discipline": d, "pct": p} for d, p in sec]}


def lvl(ex: str, measure: str, low=None, high=None, distance=None) -> dict:
    out = {"exerciseId": ex, "measure": measure, "known": low is not None}
    if low is not None:
        out["low"], out["high"] = float(low), float(high)
    if distance is not None:
        out["distanceMeters"] = float(distance)
    return out


def perf(i: str, ex: str, metric: str, value, date: str, origin="user", distance=None) -> dict:
    g = {"id": i, "kind": "performance", "origin": origin, "createdOn": JOUR0, "exerciseId": ex, "metric": metric}
    if value is not None:
        g["targetValue"] = float(value)
    if distance is not None:
        g["distanceMeters"] = float(distance)
    g["targetDate"] = date
    return g


def habit(i: str, per_week: int, weeks: int, origin="user") -> dict:
    return {"id": i, "kind": "habit", "origin": origin, "createdOn": JOUR0,
            "sessionsPerWeek": per_week, "weeks": weeks}


ZONE_JOINT = {"shoulder": "epaule", "elbow": "coude", "wrist_hand": "poignet", "lower_back": "lombaires",
              "hip": "hanche", "knee": "genou", "ankle_foot": "cheville"}


def lim(zone: str, side: str, discomfort: int) -> dict:
    out = {"zone": zone, "side": side}
    if zone in ZONE_JOINT:
        out["joint"] = ZONE_JOINT[zone]
    out["discomfort"] = discomfort
    return out


def street(primary: str, sl: int, sr: int, ca: int) -> dict:
    return {"primary": primary, "streetliftingPct": sl, "setsRepsPct": sr, "calisthenicsPct": ca}


STYLE_DISC = {"streetlifting": "streetlifting", "sets_reps": "street_workout", "calisthenics": "calisthenics"}


def street_mix(s: dict) -> dict:
    pct = {"streetlifting": s["streetliftingPct"], "sets_reps": s["setsRepsPct"], "calisthenics": s["calisthenicsPct"]}
    return {"primary": STYLE_DISC[s["primary"]], "primaryPct": pct[s["primary"]],
            "secondaries": [{"discipline": STYLE_DISC[k], "pct": v} for k, v in pct.items() if k != s["primary"] and v > 0]}


def profile(key, description, *, sex, birth, height, weight, disciplines=None, street_mode=None, days,
            places, equipment, increments="aucun", levels=(), goals=(), limitations=(), liked=(), disliked=(),
            mode="assisted", name=None, health="standard", created=JOUR0) -> dict:
    p: dict = {"schemaVersion": 2}
    if name:
        p["displayName"] = name
    p.update(sex=sex, birthYear=birth, heightCm=height)
    if weight is not None:
        p["bodyWeightKg"] = float(weight)
    p["disciplines"] = street_mix(street_mode) if street_mode else disciplines
    if street_mode:
        p["streetMode"] = street_mode
    p["movementLevels"] = list(levels)
    p["goals"] = list(goals)
    p["availability"] = [{"weekday": d, "minutes": m} for d, m in days]
    p["places"] = [{"gym": "salle", "home": "maison", "outdoor": "exterieur"}[x] for x in places]
    p["equipment"] = list(equipment)
    p["loadIncrements"] = [
        ({"loadType": t, "stepKg": s, "minKg": m} if m else {"loadType": t, "stepKg": s}) for t, s, m in INC[increments]
    ]
    p["limitations"] = list(limitations)
    p["likedExerciseIds"] = list(liked)
    p["dislikedExerciseIds"] = list(disliked)
    p["guidanceMode"] = mode
    hs = {"questionnaireId": "kalis-sante-l13-v1"}
    if health != "not_answered":
        hs["answeredOn"] = created
    hs["outcome"] = health
    p["healthScreening"] = hs
    p["createdOn"] = created
    p["updatedOn"] = created
    return {"key": key, "description": description, "profile": p}


def profils() -> list[dict]:
    P = profile
    return [
        P("debutant_forme_generale_maison_2x30", "Débutant, forme générale, 2 × 30 min à la maison sans matériel.",
          sex="male", birth=1994, height=178, weight=82, disciplines=mix("general_fitness"),
          days=[(2, 30), (5, 30)], places=["home"], equipment=SANS,
          levels=[lvl("sw-pompe", "max_reps", 5, 10), lvl("mu-air-squat", "max_reps", 15, 25),
                  lvl("mu-gainage-ventral-coudes", "max_hold_seconds")],
          goals=[habit("g1", 2, 8)]),
        P("femme_45_musculation_salle_4x60", "Femme de 45 ans, musculation, 4 × 60 min en salle.",
          sex="female", birth=1981, height=165, weight=63, disciplines=mix("musculation", 80, ("mobility", 20)),
          days=[(1, 60), (2, 60), (4, 60), (6, 60)], places=["gym"], equipment=SALLE, increments="salle",
          levels=[lvl("mu-back-squat-barre-haute", "one_rm_kg", 50, 60), lvl("mu-developpe-couche-barre", "one_rm_kg", 30, 37.5),
                  lvl("mu-souleve-de-terre-conventionnel", "one_rm_kg", 70, 80), lvl("sw-traction-pronation", "max_reps", 0, 1)],
          goals=[perf("g1", "mu-back-squat-barre-haute", "one_rm_kg", 75, "2027-04-01"), habit("g2", 4, 12)],
          liked=["mu-hip-thrust-barre"], disliked=["cf-burpee"]),
        P("coureur_cardio_3x45", "Coureur : cardio principal, mobilité et musculation en appoint, 3 × 45 min dehors.",
          sex="male", birth=1988, height=176, weight=68, disciplines=mix("cardio", 70, ("musculation", 20), ("mobility", 10)),
          days=[(2, 45), (4, 45), (7, 75)], places=["outdoor", "home"], equipment=COURSE + ["élastique"],
          levels=[lvl("ca-footing-endurance-fondamentale", "time_seconds", 1500, 1620, distance=5000),
                  lvl("mu-air-squat", "max_reps", 30, 40)],
          goals=[perf("g1", "ca-footing-endurance-fondamentale", "time_seconds", 2880, "2027-03-14", distance=10000)]),
        P("crossfit_5x60", "CrossFit, 5 × 60 min en box.",
          sex="female", birth=1996, height=170, weight=66, disciplines=mix("crossfit", 80, ("mobility", 20)),
          days=[(1, 60), (2, 60), (3, 60), (5, 60), (6, 60)], places=["gym"], equipment=CROSSFIT, increments="salle",
          levels=[lvl("mu-back-squat-barre-haute", "one_rm_kg", 80, 90), lvl("mu-epaule-jete", "one_rm_kg", 55, 62.5),
                  lvl("sw-traction-pronation", "max_reps", 6, 9), lvl("cf-burpee", "max_reps", 20, 30)],
          goals=[perf("g1", "cd-muscle-up-barre-strict", "skill_unlocked", None, "2027-06-01")]),
        P("calisthenie_figures_4x75", "Calisthénie orientée figures (front lever, planche), 4 × 75 min au parc.",
          sex="male", birth=1999, height=174, weight=70, disciplines=mix("calisthenics", 80, ("mobility", 20)),
          days=[(1, 75), (3, 75), (5, 75), (6, 75)], places=["outdoor", "home"], equipment=PARC + ["anneaux", "parallettes", "tapis"],
          levels=[lvl("sw-traction-pronation", "max_reps", 14, 18), lvl("sw-dips-barres-paralleles", "max_reps", 20, 25),
                  lvl("cs-front-lever-tuck-avance", "max_hold_seconds", 8, 12), lvl("cs-planche-tuck", "max_hold_seconds", 10, 15),
                  lvl("cs-handstand", "max_hold_seconds", 15, 30)],
          goals=[perf("g1", "cs-front-lever", "hold_seconds", 5, "2027-09-01"), perf("g2", "cs-planche-straddle", "skill_unlocked", None, "2027-12-01")],
          liked=["cs-front-lever-tuck-avance", "cs-handstand"]),
        P("street_streetlifting_4x90", "Mode street, principale streetlifting (60/25/15), 4 × 90 min.",
          sex="male", birth=1997, height=180, weight=78, street_mode=street("streetlifting", 60, 25, 15),
          days=[(1, 90), (2, 90), (4, 90), (6, 90)], places=["gym", "outdoor"], equipment=STREETLIFT, increments="street",
          levels=[lvl("sl-traction-lestee", "one_rm_kg", 30, 35), lvl("sl-dips-leste", "one_rm_kg", 45, 50),
                  lvl("sl-squat-competition", "one_rm_kg", 110, 120), lvl("sw-traction-pronation", "max_reps", 15, 18)],
          goals=[perf("g1", "sl-traction-lestee", "one_rm_kg", 50, "2027-05-01")]),
        P("street_sets_reps_4x60", "Mode street, principale sets & reps (20/60/20), 4 × 60 min au parc.",
          sex="male", birth=2001, height=172, weight=65, street_mode=street("sets_reps", 20, 60, 20),
          days=[(1, 60), (3, 60), (5, 60), (7, 60)], places=["outdoor"], equipment=PARC + ["gilet lesté"], increments="street",
          levels=[lvl("sw-traction-pronation", "max_reps", 18, 22), lvl("sw-dips-barres-paralleles", "max_reps", 30, 35),
                  lvl("sw-pompe", "max_reps", 45, 55), lvl("cd-muscle-up-barre-strict", "max_reps", 3, 5)],
          goals=[perf("g1", "sw-traction-pronation", "max_reps", 30, "2027-04-01")]),
        P("street_calisthenie_5x60", "Mode street, principale calisthénie (0/40/60), 5 × 60 min.",
          sex="female", birth=1998, height=162, weight=54, street_mode=street("calisthenics", 0, 40, 60),
          days=[(1, 60), (2, 60), (4, 60), (5, 60), (7, 60)], places=["outdoor", "home"], equipment=PARC + ["anneaux", "tapis"],
          levels=[lvl("sw-traction-pronation", "max_reps", 6, 8), lvl("cs-handstand-dos-au-mur", "max_hold_seconds", 30, 45),
                  lvl("cs-l-sit", "max_hold_seconds", 8, 12)],
          goals=[perf("g1", "cs-handstand", "hold_seconds", 30, "2027-06-01")]),
        P("blessure_epaule_musculation_3x60", "Musculation avec une blessure d'épaule droite (gêne 6/10).",
          sex="male", birth=1985, height=183, weight=88, disciplines=mix("musculation"),
          days=[(1, 60), (3, 60), (5, 60)], places=["gym"], equipment=SALLE, increments="salle",
          levels=[lvl("mu-developpe-couche-barre", "one_rm_kg", 80, 90), lvl("mu-back-squat-barre-haute", "one_rm_kg", 110, 120)],
          limitations=[lim("shoulder", "right", 6)], disliked=["mu-developpe-nuque-barre"]),
        P("minimal_1x20", "Une seule séance de 20 min par semaine, à la maison.",
          sex="undisclosed", birth=1990, height=170, weight=None, disciplines=mix("general_fitness"),
          days=[(3, 20)], places=["home"], equipment=SANS,
          levels=[lvl("sw-pompe", "max_reps"), lvl("mu-air-squat", "max_reps")], goals=[habit("g1", 1, 12)]),
        P("six_jours_musculation_avance_6x75", "Musculation avancée, 6 × 75 min en salle.",
          sex="male", birth=1993, height=181, weight=90, disciplines=mix("musculation"),
          days=[(1, 75), (2, 75), (3, 75), (4, 75), (5, 75), (6, 75)], places=["gym"], equipment=SALLE, increments="salle",
          levels=[lvl("mu-developpe-couche-barre", "one_rm_kg", 130, 140), lvl("mu-back-squat-barre-haute", "one_rm_kg", 170, 185),
                  lvl("mu-souleve-de-terre-conventionnel", "one_rm_kg", 210, 225), lvl("mu-developpe-militaire-barre-debout", "one_rm_kg", 80, 85)],
          goals=[perf("g1", "mu-developpe-couche-barre", "one_rm_kg", 150, "2027-06-01")], mode="free"),
        P("senior_65_forme_generale_3x40", "Senior de 65 ans, forme générale, 3 × 40 min, questionnaire santé en mode prudent.",
          sex="female", birth=1961, height=160, weight=64, disciplines=mix("general_fitness", 60, ("mobility", 40)),
          days=[(1, 40), (3, 40), (5, 40)], places=["home", "outdoor"], equipment=["tapis", "élastique", "step", "bâton"],
          levels=[lvl("mu-air-squat", "max_reps", 8, 12), lvl("sw-pompe-murale", "max_reps", 8, 12)],
          goals=[habit("g1", 3, 12)], limitations=[lim("knee", "both", 3)], health="cautious"),
        P("proprietaire_streetlifting_avance", "Profil calqué sur le propriétaire : streetlifting avancé, environ 71,5 kg, mode street.",
          sex="male", birth=1996, height=175, weight=71.5, street_mode=street("streetlifting", 70, 20, 10),
          days=[(1, 90), (2, 90), (3, 75), (5, 90), (6, 90)], places=["gym", "outdoor"], equipment=STREETLIFT, increments="street",
          levels=[lvl("sl-traction-lestee", "one_rm_kg", 52.5, 57.5), lvl("sl-dips-leste", "one_rm_kg", 72.5, 77.5),
                  lvl("sl-muscle-up-leste", "one_rm_kg", 12.5, 17.5), lvl("sl-squat-competition", "one_rm_kg", 115, 125),
                  lvl("sw-traction-pronation", "max_reps", 28, 32), lvl("sw-dips-barres-paralleles", "max_reps", 65, 75),
                  lvl("sw-pompe", "max_reps", 60, 70), lvl("cd-muscle-up-barre-strict", "max_reps", 9, 11)],
          goals=[perf("g1", "sl-traction-lestee", "one_rm_kg", 65, "2027-04-18"), perf("g2", "sl-dips-leste", "one_rm_kg", 88, "2027-04-18"),
                 perf("g3", "sl-muscle-up-leste", "one_rm_kg", 20, "2027-04-18"), perf("g4", "sl-squat-competition", "one_rm_kg", 150, "2027-04-18")],
          limitations=[lim("elbow", "both", 2)], mode="free"),
        P("homme_25_musculation_debutant_3x60", "Homme de 25 ans, débutant en musculation, 3 × 60 min en salle.",
          sex="male", birth=2001, height=177, weight=70, disciplines=mix("musculation"),
          days=[(1, 60), (3, 60), (5, 60)], places=["gym"], equipment=SALLE, increments="salle",
          levels=[lvl("mu-developpe-couche-barre", "one_rm_kg"), lvl("mu-back-squat-barre-haute", "one_rm_kg"), lvl("sw-pompe", "max_reps", 10, 15)],
          goals=[perf("g1", "mu-developpe-couche-barre", "one_rm_kg", 80, "2027-10-01")]),
        P("femme_30_street_workout_parc_3x45", "Femme de 30 ans, street workout au parc, 3 × 45 min.",
          sex="female", birth=1996, height=168, weight=60, disciplines=mix("street_workout", 80, ("mobility", 20)),
          days=[(2, 45), (4, 45), (6, 45)], places=["outdoor"], equipment=PARC,
          levels=[lvl("sw-traction-pronation", "max_reps", 0, 1), lvl("sw-pompe", "max_reps", 8, 12), lvl("sw-row-australien", "max_reps", 8, 10)],
          goals=[perf("g1", "sw-traction-pronation", "max_reps", 5, "2027-04-01")]),
        P("mobilite_seule_5x20", "Mobilité seule, 5 × 20 min à la maison.",
          sex="female", birth=1979, height=164, weight=58, disciplines=mix("mobility"),
          days=[(1, 20), (2, 20), (3, 20), (4, 20), (5, 20)], places=["home"],
          equipment=["tapis", "rouleau de massage (foam roller)", "bâton", "balle de massage"],
          goals=[habit("g1", 5, 6)]),
        P("cardio_debutant_marche_3x30", "Débutant en cardio (marche, vélo), 3 × 30 min.",
          sex="male", birth=1975, height=174, weight=96, disciplines=mix("cardio"),
          days=[(1, 30), (3, 30), (6, 30)], places=["outdoor", "home"], equipment=["piste ou terrain extérieur", "vélo / home-trainer"],
          goals=[habit("g1", 3, 8)], health="cautious"),
        P("homme_50_reprise_genou_3x45", "Homme de 50 ans en reprise, genou gauche sensible (gêne 4/10).",
          sex="male", birth=1976, height=179, weight=85, disciplines=mix("musculation", 70, ("cardio", 30)),
          days=[(2, 45), (4, 45), (6, 45)], places=["gym"], equipment=SALLE, increments="salle",
          levels=[lvl("mu-presse-cuisses-45", "one_rm_kg", 120, 140), lvl("mu-developpe-couche-barre", "one_rm_kg", 60, 70)],
          limitations=[lim("knee", "left", 4)]),
        P("lombalgie_musculation_3x50", "Musculation avec le bas du dos sensible (gêne 5/10).",
          sex="female", birth=1989, height=169, weight=67, disciplines=mix("musculation", 80, ("mobility", 20)),
          days=[(1, 50), (3, 50), (5, 50)], places=["gym"], equipment=SALLE, increments="salle",
          levels=[lvl("mu-back-squat-barre-haute", "one_rm_kg", 55, 65)],
          limitations=[lim("lower_back", "both", 5)], disliked=["mu-souleve-de-terre-conventionnel", "mu-good-morning-barre"]),
        P("poignet_calisthenie_3x60", "Calisthénie avec un poignet droit sensible (gêne 4/10).",
          sex="male", birth=2000, height=171, weight=64, disciplines=mix("calisthenics"),
          days=[(1, 60), (3, 60), (6, 60)], places=["outdoor"], equipment=PARC + ["anneaux", "parallettes"],
          levels=[lvl("sw-traction-pronation", "max_reps", 12, 15), lvl("cs-l-sit", "max_hold_seconds", 15, 20)],
          limitations=[lim("wrist_hand", "right", 4)]),
        P("femme_22_calisthenie_debutante_maison", "Débutante en calisthénie à la maison, avec barre de traction.",
          sex="female", birth=2004, height=166, weight=57, disciplines=mix("calisthenics", 70, ("mobility", 30)),
          days=[(1, 45), (3, 45), (5, 45)], places=["home"], equipment=MAISON_BARRE,
          levels=[lvl("sw-pompe-genoux", "max_reps", 8, 12), lvl("sw-dead-hang", "max_hold_seconds", 20, 30), lvl("sw-traction-pronation", "max_reps")],
          goals=[perf("g1", "sw-traction-pronation", "max_reps", 1, "2027-03-01"), perf("g2", "cs-crow", "skill_unlocked", None, "2027-02-01")]),
        P("homme_35_crossfit_maison_kettlebell", "CrossFit à la maison avec kettlebell et corde à sauter, 4 × 40 min.",
          sex="male", birth=1991, height=182, weight=84, disciplines=mix("crossfit", 70, ("cardio", 30)),
          days=[(1, 40), (2, 40), (4, 40), (6, 40)], places=["home", "outdoor"],
          equipment=["kettlebell", "corde à sauter", "tapis", "box / plinth", "barre fixe"], increments="maison",
          levels=[lvl("cf-burpee", "max_reps", 25, 35), lvl("sw-traction-pronation", "max_reps", 8, 10)]),
        P("musculation_maison_halteres_4x45", "Musculation à la maison avec haltères et banc, 4 × 45 min.",
          sex="male", birth=1987, height=175, weight=77, disciplines=mix("musculation"),
          days=[(1, 45), (2, 45), (4, 45), (5, 45)], places=["home"], equipment=MAISON_BASE + ["banc plat"], increments="maison",
          levels=[lvl("mu-developpe-couche-halteres", "one_rm_kg", 26, 30), lvl("sw-pompe", "max_reps", 25, 30)]),
        P("elite_calisthenie_6x90", "Calisthénie de niveau élite, 6 × 90 min.",
          sex="male", birth=1998, height=170, weight=66, disciplines=mix("calisthenics", 90, ("mobility", 10)),
          days=[(1, 90), (2, 90), (3, 90), (4, 90), (5, 90), (6, 90)], places=["gym", "outdoor"],
          equipment=PARC + ["anneaux", "parallettes", "tapis", "mur", "poteau vertical", "espalier"],
          levels=[lvl("cs-front-lever", "max_hold_seconds", 12, 15), lvl("cs-planche-straddle", "max_hold_seconds", 8, 10),
                  lvl("cd-traction-un-bras", "max_reps", 1, 2), lvl("cd-hspu-libre", "max_reps", 4, 6)],
          goals=[perf("g1", "cs-planche", "hold_seconds", 5, "2027-12-01")], mode="free"),
        P("streetlifting_debutant_3x60", "Débutant en streetlifting : peu de tractions, pas encore de lest.",
          sex="male", birth=2002, height=178, weight=74, street_mode=street("streetlifting", 50, 40, 10),
          days=[(1, 60), (3, 60), (5, 60)], places=["gym"], equipment=STREETLIFT, increments="street",
          levels=[lvl("sw-traction-pronation", "max_reps", 4, 6), lvl("sw-dips-barres-paralleles", "max_reps", 8, 10),
                  lvl("sl-squat-competition", "one_rm_kg", 70, 80), lvl("sl-traction-lestee", "one_rm_kg")]),
        P("forme_generale_exterieur_3x40", "Forme générale en extérieur, 3 × 40 min.",
          sex="female", birth=1992, height=167, weight=62, disciplines=mix("general_fitness", 70, ("cardio", 30)),
          days=[(2, 40), (4, 40), (7, 40)], places=["outdoor"], equipment=["piste ou terrain extérieur", "barre basse", "élastique", "corde à sauter"],
          levels=[lvl("sw-pompe", "max_reps", 6, 10)], goals=[habit("g1", 3, 10)]),
        P("senior_72_mobilite_marche_4x30", "Senior de 72 ans : mobilité et marche, 4 × 30 min, mode prudent.",
          sex="male", birth=1954, height=172, weight=79, disciplines=mix("mobility", 60, ("cardio", 40)),
          days=[(1, 30), (3, 30), (5, 30), (7, 30)], places=["home", "outdoor"], equipment=["tapis", "bâton", "piste ou terrain extérieur"],
          limitations=[lim("hip", "left", 3), lim("lower_back", "both", 2)], health="cautious"),
        P("femme_60_musculation_salle_2x45", "Femme de 60 ans, musculation sur machines, 2 × 45 min.",
          sex="female", birth=1966, height=161, weight=70, disciplines=mix("musculation", 80, ("mobility", 20)),
          days=[(2, 45), (5, 45)], places=["gym"], equipment=SALLE, increments="salle",
          levels=[lvl("mu-presse-cuisses-45", "one_rm_kg", 60, 80)], goals=[habit("g1", 2, 12)]),
        P("homme_40_cardio_musculation_50_50", "Cardio et musculation à parts égales (50/50), 4 × 50 min.",
          sex="male", birth=1986, height=180, weight=80, disciplines=mix("cardio", 50, ("musculation", 50)),
          days=[(1, 50), (3, 50), (5, 50), (7, 50)], places=["gym", "outdoor"], equipment=SALLE + ["piste ou terrain extérieur"], increments="salle",
          levels=[lvl("ca-footing-endurance-fondamentale", "time_seconds", 1650, 1800, distance=5000), lvl("mu-developpe-couche-barre", "one_rm_kg", 70, 80)]),
        P("trois_disciplines_70_20_10", "Trois disciplines dosées : musculation 70 %, mobilité 20 %, cardio 10 % (exemple de D3.2).",
          sex="male", birth=1990, height=176, weight=75, disciplines=mix("musculation", 70, ("mobility", 20), ("cardio", 10)),
          days=[(1, 60), (3, 45), (6, 90)], places=["gym"], equipment=SALLE, increments="salle",
          levels=[lvl("mu-back-squat-barre-haute", "one_rm_kg", 90, 100)]),
        P("niveaux_inconnus_sans_poids", "Aucun niveau connu (« je ne sais pas » partout), poids non renseigné.",
          sex="female", birth=1995, height=163, weight=None, disciplines=mix("musculation"),
          days=[(2, 60), (4, 60)], places=["gym"], equipment=SALLE, increments="salle",
          levels=[lvl("mu-back-squat-barre-haute", "one_rm_kg"), lvl("mu-developpe-couche-barre", "one_rm_kg"),
                  lvl("sw-pompe", "max_reps"), lvl("mu-gainage-ventral-coudes", "max_hold_seconds")], health="not_answered"),
        P("sans_objectif_mode_libre", "Aucun objectif, mode libre.",
          sex="male", birth=1983, height=185, weight=92, disciplines=mix("street_workout", 60, ("musculation", 40)),
          days=[(1, 60), (4, 60), (6, 60)], places=["gym", "outdoor"], equipment=SALLE,
          levels=[lvl("sw-traction-pronation", "max_reps", 8, 10)], mode="free", increments="salle"),
        P("objectif_habitude_seul", "Un seul objectif d'habitude suggéré par Koach.",
          sex="female", birth=1993, height=170, weight=65, disciplines=mix("general_fitness"),
          days=[(1, 30), (3, 30), (5, 30)], places=["home"], equipment=MAISON_BASE, increments="maison",
          goals=[habit("g1", 3, 8, origin="suggested")]),
        P("objectif_figure_front_lever", "Objectif de figure : front lever débloqué.",
          sex="male", birth=2000, height=173, weight=68, disciplines=mix("calisthenics", 60, ("street_workout", 40)),
          days=[(1, 60), (3, 60), (5, 60), (6, 60)], places=["outdoor"], equipment=PARC + ["anneaux"],
          levels=[lvl("sw-traction-pronation", "max_reps", 12, 14), lvl("cs-front-lever-tuck", "max_hold_seconds", 15, 20)],
          goals=[perf("g1", "cs-front-lever", "skill_unlocked", None, "2027-10-01")], liked=["cd-front-lever-raise-tuck"]),
        P("semi_marathon", "Objectif de temps sur semi-marathon.",
          sex="female", birth=1990, height=168, weight=59, disciplines=mix("cardio", 80, ("mobility", 10), ("musculation", 10)),
          days=[(2, 60), (4, 60), (6, 45), (7, 120)], places=["outdoor"], equipment=COURSE,
          levels=[lvl("ca-footing-endurance-fondamentale", "time_seconds", 3000, 3180, distance=10000)],
          goals=[perf("g1", "ca-sortie-longue", "time_seconds", 6600, "2027-04-11", distance=21097.5)]),
        P("prudent_sante_musculation", "Questionnaire santé en mode prudent, musculation légère.",
          sex="male", birth=1970, height=177, weight=89, disciplines=mix("musculation", 60, ("cardio", 40)),
          days=[(1, 45), (4, 45)], places=["gym"], equipment=SALLE, increments="salle", health="cautious"),
        P("tres_grand_lourd", "Grand gabarit : 198 cm, 130 kg.",
          sex="male", birth=1992, height=198, weight=130, disciplines=mix("musculation", 70, ("cardio", 30)),
          days=[(1, 60), (3, 60), (5, 60)], places=["gym"], equipment=SALLE, increments="salle",
          levels=[lvl("mu-back-squat-barre-haute", "one_rm_kg", 140, 160), lvl("sw-traction-pronation", "max_reps", 0, 0)]),
        P("petite_legere", "Petit gabarit : 150 cm, 45 kg.",
          sex="female", birth=1999, height=150, weight=45, disciplines=mix("street_workout", 70, ("mobility", 30)),
          days=[(2, 45), (4, 45), (6, 45)], places=["outdoor", "home"], equipment=PARC + ["tapis"],
          levels=[lvl("sw-traction-pronation", "max_reps", 3, 5), lvl("sw-pompe", "max_reps", 12, 15)]),
        P("sept_jours_courts_7x20", "Tous les jours, 20 min.",
          sex="male", birth=1984, height=178, weight=76, disciplines=mix("general_fitness", 50, ("mobility", 30), ("cardio", 20)),
          days=[(d, 20) for d in range(1, 8)], places=["home"], equipment=MAISON_BASE + ["corde à sauter"], increments="maison",
          goals=[habit("g1", 7, 4)]),
        P("materiel_complet_gouts_marques", "Salle complète, nombreux exercices aimés et détestés.",
          sex="female", birth=1994, height=171, weight=68, disciplines=mix("musculation", 60, ("street_workout", 20), ("cardio", 20)),
          days=[(1, 60), (2, 60), (4, 60), (5, 60)], places=["gym", "home", "outdoor"], equipment=sorted(MATERIEL - {"aucun (sol)", "mur"}),
          increments="salle",
          levels=[lvl("mu-back-squat-barre-haute", "one_rm_kg", 85, 95), lvl("sw-traction-pronation", "max_reps", 5, 7)],
          liked=["mu-hip-thrust-barre", "mu-souleve-de-terre-roumain-barre", "sw-traction-supination", "mu-face-pull-corde", "ca-rameur-endurance"],
          disliked=["cf-burpee", "mu-fente-marchee-halteres", "ca-corde-double-unders", "mu-leg-extension"], name="Zoé"),
    ]


# ---------------------------------------------------------------------------
# 2. Journaux synthétiques
# ---------------------------------------------------------------------------
# Gabarits de simulation : jour → [(exercice, séries, mode, bas, haut, flammes visées, pas)]
#   mode « load » : charge externe, bas-haut = plage de répétitions, pas = incrément (kg)
#   mode « reps » : poids du corps, bas-haut = plage de répétitions
#   mode « hold » : tenue, bas-haut = plage de secondes
#   mode « run »  : durée (secondes) = bas, vitesse vraie en m/s dans la vérité
#   mode « easy » : mobilité ou gainage facile, durée = bas, flammes visées basses

GABARITS = {
    "maison_poids_du_corps": [
        [("sw-pompe", 3, "reps", 6, 12, 7, 0), ("mu-air-squat", 3, "reps", 12, 20, 6, 0),
         ("mu-gainage-ventral-coudes", 3, "hold", 20, 45, 6, 0), ("mu-pont-fessier-sol", 2, "reps", 12, 15, 6, 0)],
        [("sw-pompe-inclinee", 3, "reps", 8, 15, 6, 0), ("mu-fente-arriere-poids-du-corps", 3, "reps", 8, 12, 7, 0),
         ("mu-dead-bug", 3, "reps", 8, 12, 5, 0), ("mo-etirement-chiot", 1, "easy", 60, 60, 2, 0)],
    ],
    "salle_musculation": [
        [("mu-back-squat-barre-haute", 4, "load", 5, 8, 7, 2.5), ("mu-developpe-couche-barre", 4, "load", 5, 8, 7, 2.5),
         ("mu-rowing-poulie-assis-triangle", 3, "load", 8, 12, 7, 2.5), ("mu-gainage-ventral-coudes", 3, "hold", 30, 60, 6, 0)],
        [("mu-souleve-de-terre-roumain-barre", 3, "load", 6, 10, 7, 2.5), ("mu-developpe-halteres-assis", 3, "load", 8, 12, 7, 2.0),
         ("mu-tirage-vertical-prise-large-pronation", 3, "load", 8, 12, 7, 2.5), ("mu-curl-halteres-simultane", 3, "load", 10, 15, 8, 2.0)],
        [("mu-presse-cuisses-45", 3, "load", 8, 12, 7, 5.0), ("mu-developpe-incline-halteres", 3, "load", 8, 12, 7, 2.0),
         ("mu-rowing-haltere-unilateral-banc", 3, "load", 8, 12, 7, 2.0), ("mu-pushdown-corde", 3, "load", 10, 15, 8, 2.5)],
        [("mu-hip-thrust-barre", 3, "load", 8, 12, 7, 2.5), ("mu-leg-curl-couche", 3, "load", 10, 15, 8, 5.0),
         ("mu-elevation-laterale-halteres", 3, "load", 12, 15, 8, 2.0), ("mo-pigeon-sol", 2, "easy", 45, 45, 2, 0)],
    ],
    "streetlifting": [
        [("sl-traction-lestee", 5, "load", 3, 5, 7, 1.25), ("mu-rowing-barre-pronation", 3, "load", 6, 10, 7, 2.5),
         ("mu-curl-barre-ez", 3, "load", 8, 12, 8, 2.5), ("sw-dead-hang", 2, "hold", 30, 60, 6, 0)],
        [("sl-dips-leste", 5, "load", 3, 5, 7, 1.25), ("mu-developpe-militaire-barre-debout", 3, "load", 6, 10, 7, 2.5),
         ("sw-pompe", 3, "reps", 15, 30, 7, 0), ("mu-pushdown-corde", 3, "load", 10, 15, 8, 2.5)],
        [("sl-squat-competition", 5, "load", 3, 5, 7, 2.5), ("mu-souleve-de-terre-roumain-barre", 3, "load", 6, 10, 7, 2.5),
         ("mu-hollow-body-hold", 3, "hold", 20, 40, 6, 0)],
        [("sl-muscle-up-leste", 4, "load", 2, 3, 7, 1.25), ("sw-traction-pronation", 3, "reps", 8, 15, 7, 0),
         ("sw-dips-barres-paralleles", 3, "reps", 12, 25, 7, 0), ("mu-face-pull-corde", 3, "load", 12, 15, 8, 2.5)],
    ],
    "course": [
        [("ca-footing-endurance-fondamentale", 1, "run", 2400, 2400, 4, 0), ("mo-etirement-gastrocnemiens-mur", 2, "easy", 30, 30, 2, 0)],
        [("ca-fractionne-400m", 6, "run", 100, 100, 8, 0), ("mu-air-squat", 2, "reps", 15, 25, 5, 0)],
        [("ca-sortie-longue", 1, "run", 4200, 4200, 5, 0)],
    ],
    "calisthenie": [
        [("cs-front-lever-tuck-avance", 5, "hold", 6, 15, 8, 0), ("sw-traction-pronation", 4, "reps", 6, 12, 7, 0),
         ("cs-l-sit", 4, "hold", 10, 25, 7, 0), ("sw-row-australien", 3, "reps", 10, 15, 6, 0)],
        [("cs-planche-tuck", 5, "hold", 6, 15, 8, 0), ("sw-dips-barres-paralleles", 4, "reps", 8, 15, 7, 0),
         ("cs-handstand-dos-au-mur", 4, "hold", 20, 45, 6, 0), ("sw-pompe-pike", 3, "reps", 6, 12, 7, 0)],
        [("cd-muscle-up-barre-strict", 5, "reps", 1, 4, 8, 0), ("sw-releve-jambes-tendues-suspendu", 3, "reps", 6, 12, 7, 0),
         ("mo-etirement-pectoral-cadre-porte", 2, "easy", 40, 40, 2, 0)],
    ],
    "minimal": [
        [("sw-pompe", 2, "reps", 5, 10, 7, 0), ("mu-air-squat", 2, "reps", 10, 20, 6, 0), ("mu-gainage-ventral-coudes", 2, "hold", 20, 40, 6, 0)],
    ],
}

# Vérité de l'athlète simulé : capacité de départ et gain relatif par semaine.
#   load : 1RM de charge totale (charge externe + fraction × poids du corps) en kg
#   reps : répétitions max ; hold : secondes max ; run : vitesse en m/s
JOURNAUX = [
    dict(key="j04_debutant_maison", profil="debutant_forme_generale_maison_2x30", gabarit="maison_poids_du_corps", weeks=4,
         description="4 semaines, débutant à la maison : progression rapide, notes parfois absentes.",
         gain=0.03, absent=0.10, sans_note=0.15, bilan=0.5,
         cap={"sw-pompe": 9, "mu-air-squat": 22, "mu-gainage-ventral-coudes": 50, "mu-pont-fessier-sol": 20,
              "sw-pompe-inclinee": 14, "mu-fente-arriere-poids-du-corps": 12, "mu-dead-bug": 14}),
    dict(key="j08_femme_musculation_salle", profil="femme_45_musculation_salle_4x60", gabarit="salle_musculation", weeks=8,
         description="8 semaines de musculation en salle, assidue, bilans santé fréquents.",
         gain=0.012, absent=0.05, sans_note=0.02, bilan=0.9,
         cap={"mu-back-squat-barre-haute": 56, "mu-developpe-couche-barre": 34, "mu-rowing-poulie-assis-triangle": 42,
              "mu-gainage-ventral-coudes": 70, "mu-souleve-de-terre-roumain-barre": 62, "mu-developpe-halteres-assis": 12,
              "mu-tirage-vertical-prise-large-pronation": 40, "mu-curl-halteres-simultane": 9, "mu-presse-cuisses-45": 110,
              "mu-developpe-incline-halteres": 13, "mu-rowing-haltere-unilateral-banc": 16, "mu-pushdown-corde": 18,
              "mu-hip-thrust-barre": 80, "mu-leg-curl-couche": 30, "mu-elevation-laterale-halteres": 6}),
    dict(key="j12_coureur", profil="coureur_cardio_3x45", gabarit="course", weeks=12,
         description="12 semaines de course : endurance, fractionné, sortie longue.",
         gain=0.006, absent=0.08, sans_note=0.05, bilan=0.6,
         cap={"ca-footing-endurance-fondamentale": 3.05, "ca-fractionne-400m": 4.3, "ca-sortie-longue": 2.9, "mu-air-squat": 35}),
    dict(key="j16_proprietaire_streetlifting", profil="proprietaire_streetlifting_avance", gabarit="streetlifting", weeks=16,
         description="16 semaines de streetlifting avancé (profil calqué sur le propriétaire), progression lente.",
         gain=0.004, absent=0.04, sans_note=0.0, bilan=0.8,
         cap={"sl-traction-lestee": 124.4, "sl-dips-leste": 143.6, "sl-squat-competition": 120.0, "sl-muscle-up-leste": 84.4,
              "mu-rowing-barre-pronation": 92, "mu-curl-barre-ez": 38, "sw-dead-hang": 95, "mu-developpe-militaire-barre-debout": 52,
              "sw-pompe": 65, "mu-pushdown-corde": 24, "mu-souleve-de-terre-roumain-barre": 125, "mu-hollow-body-hold": 60,
              "sw-traction-pronation": 30, "sw-dips-barres-paralleles": 70, "mu-face-pull-corde": 22}),
    dict(key="j24_musculation_avance", profil="six_jours_musculation_avance_6x75", gabarit="salle_musculation", weeks=24,
         description="24 semaines de musculation avancée, 6 jours par semaine.",
         gain=0.003, absent=0.06, sans_note=0.01, bilan=0.7,
         cap={"mu-back-squat-barre-haute": 178, "mu-developpe-couche-barre": 135, "mu-rowing-poulie-assis-triangle": 105,
              "mu-gainage-ventral-coudes": 150, "mu-souleve-de-terre-roumain-barre": 170, "mu-developpe-halteres-assis": 38,
              "mu-tirage-vertical-prise-large-pronation": 95, "mu-curl-halteres-simultane": 24, "mu-presse-cuisses-45": 330,
              "mu-developpe-incline-halteres": 44, "mu-rowing-haltere-unilateral-banc": 52, "mu-pushdown-corde": 45,
              "mu-hip-thrust-barre": 210, "mu-leg-curl-couche": 75, "mu-elevation-laterale-halteres": 16}),
    dict(key="j06_blessure_epaule", profil="blessure_epaule_musculation_3x60", gabarit="salle_musculation", weeks=6,
         description="6 semaines avec une épaule droite douloureuse sur les développés (douleurs signalées).",
         gain=0.004, absent=0.08, sans_note=0.03, bilan=0.9, douleur=("shoulder", "right", {"mu-developpe-couche-barre", "mu-developpe-halteres-assis", "mu-developpe-incline-halteres"}),
         cap={"mu-back-squat-barre-haute": 116, "mu-developpe-couche-barre": 84, "mu-rowing-poulie-assis-triangle": 75,
              "mu-gainage-ventral-coudes": 90, "mu-souleve-de-terre-roumain-barre": 110, "mu-developpe-halteres-assis": 24,
              "mu-tirage-vertical-prise-large-pronation": 70, "mu-curl-halteres-simultane": 16, "mu-presse-cuisses-45": 220,
              "mu-developpe-incline-halteres": 28, "mu-rowing-haltere-unilateral-banc": 34, "mu-pushdown-corde": 30,
              "mu-hip-thrust-barre": 140, "mu-leg-curl-couche": 50, "mu-elevation-laterale-halteres": 10}),
    dict(key="j08_irregulier", profil="homme_25_musculation_debutant_3x60", gabarit="salle_musculation", weeks=8,
         description="8 semaines irrégulières : une séance sur trois manquée, bilans bas, une coupure de 12 jours.",
         gain=0.015, absent=0.33, sans_note=0.10, bilan=0.8, forme_basse=0.35, coupure=(4, 12),
         cap={"mu-back-squat-barre-haute": 62, "mu-developpe-couche-barre": 48, "mu-rowing-poulie-assis-triangle": 45,
              "mu-gainage-ventral-coudes": 60, "mu-souleve-de-terre-roumain-barre": 60, "mu-developpe-halteres-assis": 14,
              "mu-tirage-vertical-prise-large-pronation": 45, "mu-curl-halteres-simultane": 10, "mu-presse-cuisses-45": 120,
              "mu-developpe-incline-halteres": 16, "mu-rowing-haltere-unilateral-banc": 20, "mu-pushdown-corde": 20,
              "mu-hip-thrust-barre": 70, "mu-leg-curl-couche": 32, "mu-elevation-laterale-halteres": 7}),
    dict(key="j12_calisthenie", profil="calisthenie_figures_4x75", gabarit="calisthenie", weeks=12,
         description="12 semaines de calisthénie : tenues en secondes et répétitions au poids du corps.",
         gain=0.012, absent=0.07, sans_note=0.02, bilan=0.6,
         cap={"cs-front-lever-tuck-avance": 11, "sw-traction-pronation": 16, "cs-l-sit": 22, "sw-row-australien": 22,
              "cs-planche-tuck": 13, "sw-dips-barres-paralleles": 22, "cs-handstand-dos-au-mur": 50, "sw-pompe-pike": 12,
              "cd-muscle-up-barre-strict": 3.4, "sw-releve-jambes-tendues-suspendu": 12}),
    dict(key="j05_reprise", profil="street_streetlifting_4x90", gabarit="streetlifting", weeks=5,
         description="5 semaines dont les 3 premières marquées « reprise » (D4.9) : neutres pour les moteurs.",
         gain=0.005, absent=0.0, sans_note=0.0, bilan=0.3, reprise=3,
         cap={"sl-traction-lestee": 109, "sl-dips-leste": 123, "sl-squat-competition": 115.0, "sl-muscle-up-leste": 84,
              "mu-rowing-barre-pronation": 80, "mu-curl-barre-ez": 34, "sw-dead-hang": 80, "mu-developpe-militaire-barre-debout": 48,
              "sw-pompe": 45, "mu-pushdown-corde": 22, "mu-souleve-de-terre-roumain-barre": 110, "mu-hollow-body-hold": 50,
              "sw-traction-pronation": 17, "sw-dips-barres-paralleles": 28, "mu-face-pull-corde": 20}),
    dict(key="j10_sans_notes", profil="musculation_maison_halteres_4x45", gabarit="maison_poids_du_corps", weeks=10,
         description="10 semaines où 60 % des séries n'ont pas de note (« pas de note » ≠ une valeur).",
         gain=0.01, absent=0.10, sans_note=0.60, bilan=0.2,
         cap={"sw-pompe": 28, "mu-air-squat": 45, "mu-gainage-ventral-coudes": 100, "mu-pont-fessier-sol": 30,
              "sw-pompe-inclinee": 38, "mu-fente-arriere-poids-du-corps": 22, "mu-dead-bug": 20}),
    dict(key="j20_plateau", profil="trois_disciplines_70_20_10", gabarit="salle_musculation", weeks=20,
         description="20 semaines sans progrès réel (gain nul) : stagnation.",
         gain=0.0, absent=0.10, sans_note=0.03, bilan=0.7,
         cap={"mu-back-squat-barre-haute": 96, "mu-developpe-couche-barre": 72, "mu-rowing-poulie-assis-triangle": 68,
              "mu-gainage-ventral-coudes": 95, "mu-souleve-de-terre-roumain-barre": 100, "mu-developpe-halteres-assis": 22,
              "mu-tirage-vertical-prise-large-pronation": 62, "mu-curl-halteres-simultane": 14, "mu-presse-cuisses-45": 190,
              "mu-developpe-incline-halteres": 25, "mu-rowing-haltere-unilateral-banc": 30, "mu-pushdown-corde": 28,
              "mu-hip-thrust-barre": 125, "mu-leg-curl-couche": 45, "mu-elevation-laterale-halteres": 9}),
    dict(key="j04_minimal", profil="minimal_1x20", gabarit="minimal", weeks=4,
         description="4 semaines à une séance de 20 min par semaine : très peu de données.",
         gain=0.02, absent=0.0, sans_note=0.25, bilan=0.0,
         cap={"sw-pompe": 8, "mu-air-squat": 18, "mu-gainage-ventral-coudes": 35}),
]

DEBUT = dt.date(2026, 1, 5)  # un lundi


def arrondi(x: float, pas: float) -> float:
    return round(round(x / pas) * pas, 3)


def simuler(j: dict, profil: dict) -> tuple[dict, dict]:
    rnd = random.Random("kalis_core/" + j["key"])
    jours = [d["weekday"] for d in profil["availability"]]
    gabarit = GABARITS[j["gabarit"]]
    poids = profil.get("bodyWeightKg", 70.0)
    sessions = []
    etat: dict[str, dict] = {}  # par exercice : charge, cible
    coupure = j.get("coupure")
    douleur = j.get("douleur")
    numero = 0
    for semaine in range(j["weeks"]):
        for rang, jour in enumerate(jours):
            date = DEBUT + dt.timedelta(days=7 * semaine + jour - 1)
            modele = gabarit[numero % len(gabarit)]
            numero += 1
            if coupure and coupure[0] * 7 <= (date - DEBUT).days < coupure[0] * 7 + coupure[1]:
                continue
            if rnd.random() < j["absent"]:
                continue
            reprise = semaine < j.get("reprise", 0)
            # Bilan santé : chaque question est facultative.
            bilan = None
            forme = 1.0
            if rnd.random() < j["bilan"]:
                bas = rnd.random() < j.get("forme_basse", 0.12)
                overall = rnd.choice([1, 2]) if bas else rnd.choice([3, 3, 4, 4, 4, 5])
                bilan = {"overall": overall}
                if bas:
                    forme = 0.95 if overall == 2 else 0.92
                    bilan["sleepQuality"] = rnd.choice([1, 2, 3])
                    bilan["sleepHours"] = rnd.choice([4.5, 5.0, 5.5, 6.0])
                    if rnd.random() < 0.6:
                        bilan["energy"] = rnd.choice([1, 2])
                    if rnd.random() < 0.5:
                        bilan["stress"] = rnd.choice([1, 2, 3])
                    if rnd.random() < 0.4:
                        bilan["soreness"] = rnd.choice([2, 3])
                    if rnd.random() < 0.3:
                        bilan["minutesAvailable"] = rnd.choice([20, 30, 40])
                elif rnd.random() < 0.25:
                    bilan["sleepHours"] = rnd.choice([7.0, 7.5, 8.0])
                bilan["pains"] = []
            elif rnd.random() < 0.1:
                bilan = {"sleepHours": rnd.choice([6.5, 7.0, 8.0]), "pains": []}
            forme *= 1 + rnd.gauss(0, 0.015)
            series = []
            douleurs = []
            for ordre, (ex, n, mode, bas_, haut, cible, pas) in enumerate(modele):
                cap = j["cap"].get(ex, 1.0) * (1 + j["gain"] * semaine) * forme
                e = etat.setdefault(ex, {})
                frac = (EX[ex]["calc"]["fraction_pdc"] or {}).get("valeur", 0.0) if EX[ex]["calc"]["type_charge"] in ("lest", "poids_du_corps") else 0.0
                notes = []
                complet = True
                rir_cible = tojir(cible)
                for k in range(n):
                    rec = {"exerciseId": ex, "exerciseOrder": ordre, "setIndex": k,
                           "kind": "calibration" if (semaine == 0 and k == 0 and mode == "load") else "work"}
                    cible_rec: dict = {}
                    fatigue_serie = 1 - 0.012 * k
                    if mode == "load":
                        if "charge" not in e:
                            # Départ prudent : charge qui laisse environ RIR visé + 2 en haut de plage.
                            total = cap / (1 + (haut + rir_cible + 2) / 30)
                            e["charge"] = max(0.0, arrondi(total - frac * poids, pas))
                        ext = e["charge"]
                        total = ext + frac * poids
                        rtf = 30 * (cap * fatigue_serie / total - 1) if total > 0 else 99
                        reps = max(0, min(haut, math.floor(rtf - rir_cible + 0.5)))
                        if reps < bas_:
                            reps = max(0, min(haut, math.floor(rtf)))
                        rir = rtf - reps
                        rec["externalLoadKg"] = float(ext)
                        rec["reps"] = reps
                        cible_rec.update(repsLow=bas_, repsHigh=haut, loadKg=float(ext))
                        ok = reps >= bas_
                    elif mode == "reps":
                        haut = max(haut, round(cap * 0.7))
                        cible_reps = e.setdefault("cible", max(bas_, min(haut, round(cap * 0.6))))
                        maxi = cap * fatigue_serie
                        reps = max(0, min(cible_reps, math.floor(maxi)))
                        rir = maxi - reps
                        rec["reps"] = reps
                        cible_rec.update(repsLow=cible_reps, repsHigh=cible_reps)
                        ok = reps >= cible_reps
                    elif mode == "hold":
                        haut = max(haut, 5 * round(cap * 0.7 / 5))
                        cible_s = e.setdefault("cible", max(bas_, min(haut, 5 * round(cap * 0.6 / 5))))
                        maxi = cap * fatigue_serie
                        secs = max(1, min(cible_s, math.floor(maxi)))
                        # Une tenue : chaque « répétition en réserve » vaut environ 10 % de la tenue max.
                        rir = (maxi - secs) / max(1.0, cap * 0.1)
                        rec["seconds"] = secs
                        cible_rec.update(seconds=cible_s)
                        ok = secs >= cible_s
                    elif mode == "run":
                        secs = bas_
                        rec["seconds"] = secs
                        rec["distanceMeters"] = float(round(cap * secs * (1 - 0.01 * k)))
                        rir = rir_cible + rnd.gauss(0, 0.5)
                        cible_rec.update(seconds=secs)
                        ok = True
                    else:  # easy
                        rec["seconds"] = bas_
                        rir = 5.0
                        cible_rec.update(seconds=bas_)
                        ok = True
                    rir = max(0.0, rir + rnd.gauss(0, 0.4))
                    note = 10 if (not ok and mode in ("load", "reps")) else fromrir(rir)
                    if rnd.random() >= j["sans_note"]:
                        rec["flames"] = note
                    notes.append(note)
                    complet = complet and ok
                    rec["success"] = ok
                    rec["excluded"] = False
                    if EX[ex]["calc"]["lateralite"] == "unilateral" and mode != "easy":
                        rec["side"] = "both"
                    cible_rec["flames"] = cible
                    rec["target"] = cible_rec
                    series.append(rec)
                    if douleur and ex in douleur[2] and k == 0 and rnd.random() < 0.6:
                        douleurs.append({"zone": douleur[0], "side": douleur[1], "joint": ZONE_JOINT[douleur[0]],
                                         "intensity": rnd.choice([2, 3, 3, 4, 5]), "phase": "during", "exerciseId": ex})
                # Progression simple, pour que les charges vivent : double progression.
                moyenne = sum(notes) / len(notes)
                if mode == "load":
                    au_sommet = all(s["reps"] >= haut for s in series[-n:])
                    if complet and ((au_sommet and moyenne <= cible) or moyenne <= cible - 2):
                        e["charge"] = arrondi(e["charge"] + pas, pas)
                    elif not complet or moyenne >= cible + 1.5:
                        e["charge"] = max(0.0, arrondi(e["charge"] - pas, pas))
                elif mode in ("reps", "hold"):
                    palier = max(1, round(0.08 * e["cible"])) if mode == "reps" else 5
                    if complet and moyenne <= cible - 1:
                        e["cible"] += palier
                    elif not complet and e["cible"] - palier >= bas_:
                        e["cible"] -= palier
            if bilan is not None and douleur and rnd.random() < 0.3:
                bilan["pains"].append({"zone": douleur[0], "side": douleur[1], "joint": ZONE_JOINT[douleur[0]],
                                       "intensity": rnd.choice([2, 3, 4]), "phase": "before"})
            # Une série écartée (incident) de temps en temps.
            if rnd.random() < 0.03 and series:
                series[rnd.randrange(len(series))]["excluded"] = True
            s = {"id": f"{j['key']}-{date.isoformat()}", "date": date.isoformat(), "origin": "program",
                 "programRef": {"blockId": f"sim-{j['key']}-b{semaine // 4}", "weekIndex": semaine % 4, "dayIndex": rang},
                 "resume": reprise, "completed": True,
                 "durationMinutes": max(10, round(sum(3 if m[2] != "run" else m[3] / 60 for m in modele for _ in range(m[1])) + rnd.randint(0, 8)))}
            if rang == 0 and "bodyWeightKg" in profil:
                s["bodyWeightKg"] = round(poids + rnd.gauss(0, 0.4), 1)
            if bilan is not None:
                s["healthCheck"] = bilan
            s["sets"] = series
            s["pains"] = douleurs
            sessions.append(s)
    log = {"schemaVersion": 1, "sessions": sessions}
    verite = {ex: {"mode": next(m[2] for jour in gabarit for m in jour if m[0] == ex),
                   "capacityStart": float(c), "weeklyGain": j["gain"]} for ex, c in sorted(j["cap"].items())}
    return log, verite


# ---------------------------------------------------------------------------
# 3. Programme du propriétaire, normalisé (lecture seule)
# ---------------------------------------------------------------------------

# Correspondance INDICATIVE des noms du programme v33 vers le catalogue (la
# correspondance de référence, pour l'historique, est celle du lot G3).
CORRESPONDANCE = [
    (r"^test 1rm muscle-up|^muscle-up leste", "sl-muscle-up-leste"),
    (r"^test 1rm traction|^traction lestee", "sl-traction-lestee"),
    (r"^test 1rm dip|^dip leste|^dip — simulation", "sl-dips-leste"),
    (r"^test 1rm back squat|^back squat", "sl-squat-competition"),
    (r"^squat endurance|^test max squat", "mu-back-squat-barre-haute"),
    (r"^squat pause", "mu-squat-pause"),
    (r"^tractions pdc|^test max tractions", "sw-traction-pronation"),
    (r"^dips pdc|^test max dips", "sw-dips-barres-paralleles"),
    (r"^pompes pdc|^test max pompes", "sw-pompe"),
    (r"^pompes lestees", "sl-pompe-lestee-gilet"),
    (r"^gtg muscle-up|^muscle-ups pdc|^test max muscle-ups", "cd-muscle-up-barre-strict"),
    (r"^negatifs de muscle-up", "cd-muscle-up-barre-negatif"),
    (r"^excentriques de transition lestes", "sl-muscle-up-negatif-leste"),
    (r"^transitions de muscle-up a l'elastique", "cd-muscle-up-barre-assiste-elastique"),
    (r"^isometrie maximale — bas de dip", "sl-dips-isometrie-lestee-blocage"),
    (r"^dips a resistance accommodante", "sl-dips-leste-elastique"),
    (r"^false grip hold", "cs-tenue-haute-false-grip-anneaux"),
    (r"^tractions explosives", "cd-traction-explosive-poitrine-barre"),
    (r"^scapular pull-ups", "sw-traction-scapulaire"),
    (r"^dead-hang", "sl-dead-hang-leste"),
    (r"^leg raises lestes", "sl-releve-jambes-suspendu-leste"),
    (r"^rowing barre penche", "mu-rowing-barre-pronation"),
    (r"^rowing haltere unilateral", "mu-rowing-haltere-unilateral-banc"),
    (r"^tirage vertical prise neutre", "mu-tirage-vertical-prise-neutre"),
    (r"^tirage horizontal poulie", "mu-rowing-poulie-assis-triangle"),
    (r"^curl barre ez", "mu-curl-barre-ez"),
    (r"^curl marteau", "mu-curl-marteau-halteres"),
    (r"^developpe militaire debout", "mu-developpe-militaire-barre-debout"),
    (r"^developpe couche", "mu-developpe-couche-barre"),
    (r"^elevations laterales", "mu-elevation-laterale-halteres"),
    (r"^extension triceps poulie corde", "mu-pushdown-corde"),
    (r"^barre au front", "mu-barre-au-front-ez"),
    (r"^face pulls", "mu-face-pull-corde"),
    (r"^rotations externes", "mu-rotation-externe-haltere-couche"),
    (r"^ytw", "mu-y-raise-banc-incline"),
    (r"^souleve de terre roumain", "mu-souleve-de-terre-roumain-barre"),
    (r"^leg curl", "mu-leg-curl-couche"),
    (r"^fentes marchees", "mu-fente-marchee-halteres"),
    (r"^hip thrust", "mu-hip-thrust-barre"),
    (r"^mollets debout", "mu-mollets-debout-machine"),
    (r"^ab wheel", "mu-roue-abdominale-genoux"),
    (r"^hollow body hold", "mu-hollow-body-hold"),
    (r"^pallof press", "mu-pallof-press-debout"),
    (r"^mobilite epaules \+ poignets", "mo-routine-mobilite-epaules-poignets"),
    (r"^mobilite complete", "mo-routine-mobilite-complete"),
    (r"^marche ou velo", "ca-marche-recuperation"),
]


def norm(text: str) -> str:
    import unicodedata
    t = unicodedata.normalize("NFD", text)
    return "".join(c for c in t if unicodedata.category(c) != "Mn").lower().replace("’", "'")


def id_catalogue(nom: str) -> str | None:
    n = norm(nom)
    for motif, ident in CORRESPONDANCE:
        if re.search(motif, n):
            assert ident in EX, ident
            return ident
    return None


def programme_proprietaire() -> dict:
    chemin = RACINE / "assets/programme_v33.json.gz"
    brut = chemin.read_bytes()
    prog = json.loads(gzip.decompress(brut).decode("utf-8"))
    semaines = []
    for w in prog["weeks"]:
        jours = []
        for d in w["days"]:
            exos = []
            for e in d["exercises"]:
                s = e["sets"]
                item = {"id": e["id"], "name": e["name"], "normalizedName": norm(e["name"]),
                        "sets": s.get("value") if s["type"] == "text" else (s.get("prefix") or "") + "volume" + (s.get("suffix") or ""),
                        "intensity": e.get("intensity", ""), "loadType": e["load"]["type"],
                        "main": bool(e.get("main", False)), "prevention": bool(e.get("prevention", False))}
                if e.get("restSec") is not None:
                    item["restSeconds"] = e["restSec"]
                cid = id_catalogue(e["name"])
                if cid is not None:
                    item["catalogId"] = cid
                exos.append(item)
            jours.append({"day": d["j"], "title": d["title"], "exercises": exos})
        semaines.append({"week": w["n"], "blockKey": w["blockKey"], "block": w["block"], "days": jours})
    noms = sorted({e["name"] for w in semaines for d in w["days"] for e in d["exercises"]})
    return {
        "schemaVersion": 1,
        "readOnly": True,
        "note": "Programme personnel du propriétaire (programme_v33), normalisé pour les tests. Lecture seule : "
                "aucun moteur ne s'en sert comme gabarit (D4.1) ni ne le régénère (D5.10). catalogId est une "
                "correspondance indicative, absente quand aucun exercice du catalogue ne correspond clairement.",
        "source": {"file": "assets/programme_v33.json.gz", "sha256": hashlib.sha256(brut).hexdigest(),
                   "version": prog["meta"]["version"], "weeks": len(prog["weeks"])},
        "bodyWeightKg": prog["pilotage"]["bodyweight"],
        "mainLifts": [{"key": m["key"], "name": m["name"], "oneRmKg": m["oneRm"], "targetKg": m["target"], "unit": m["unit"]}
                      for m in prog["pilotage"]["mainLifts"]],
        "repMax": [{"name": m["name"], "max": m["max"], "target": m["target"]} for m in prog["pilotage"]["repMax"]],
        "exerciseNames": [{"name": n, "catalogId": id_catalogue(n)} for n in noms],
        "weeks": semaines,
    }


# ---------------------------------------------------------------------------
# 4. Journal au format actuel de l'application et sa conversion
# ---------------------------------------------------------------------------

def journal_ancien(programme: dict) -> dict:
    """Journal synthétique (anonymisé : aucune donnée réelle, aucune note
    libre) au format `logs` de la sauvegarde de l'application (lib/store.dart :
    SessionLog, ExerciseLog, SetEntry) pour les semaines 1 et 2 du programme."""
    rnd = random.Random("kalis_core/legacy")
    depart = dt.date(2026, 7, 13)
    logs: dict = {}
    reponses: dict = {}
    for w in programme["weeks"][:2]:
        for d in w["days"]:
            if not d["exercises"] or d["day"] == 7:
                continue
            cle = f"S{w['week']}-J{d['day']}"
            date = depart + dt.timedelta(days=(w["week"] - 1) * 7 + d["day"] - 1)
            inacheve = (w["week"], d["day"]) == (2, 5)
            ex_logs, noms = {}, {}
            for rang, e in enumerate(d["exercises"]):
                m = re.match(r"^(\d+)\s*[×x]\s*(\d+)", e["sets"] or "")
                n, reps = (int(m.group(1)), int(m.group(2))) if m else (1, 10)
                if inacheve and rang >= 2:
                    break
                noms[e["id"]] = e["name"]
                series = []
                for k in range(n):
                    fait = not (inacheve and rang == 1 and k >= 2)
                    kg = {"system": "17,5", "barbell": "100", "acc": "30", "fixed": "10"}.get(e["loadType"], "")
                    entree = {"kg": kg if fait else "", "reps": str(reps) if fait else "", "rir": "", "v": "",
                              "done": fait, "completedAt": f"{date.isoformat()}T18:{10 + rang:02d}:{k:02d}.000" if fait else None}
                    if fait and e["main"]:
                        entree["effort"] = rnd.choice([0.5, 1.0, 1.5, 2.0, 2.5, 3.0])
                    elif fait and rnd.random() < 0.5:
                        entree["rir"] = rnd.choice(["2", "3", "1,5", "5"])
                    if fait and e["main"] and k == n - 1 and rnd.random() < 0.15:
                        entree["excluded"] = True
                    series.append(entree)
                ex_logs[e["id"]] = {"sets": series, "note": "", "showKg": None, "showRir": None, "showV": None}
            logs[cle] = {"done": not inacheve, "finishedAt": None if inacheve else f"{date.isoformat()}T19:05:00.000",
                         "title": f"S{w['week']} · J{d['day']}", "customId": None, "exerciseNames": noms, "ex": ex_logs}
            if rnd.random() < 0.6:
                r: dict = {}
                if rnd.random() < 0.8:
                    r["sleep"] = rnd.choice([6.0, 6.5, 7.0, 7.5, 8.0])
                if rnd.random() < 0.7:
                    r["form"] = rnd.choice([4, 6, 7, 8, 9])
                if rnd.random() < 0.2:
                    r["pain"] = {"pull": rnd.choice([1, 2, 3])}
                if r:
                    reponses[cle] = r
            if cle == "S1-J2":  # cas fixe : réponse complète avec une douleur par mouvement
                reponses[cle] = {"sleep": 6.5, "form": 7, "pain": {"pull": 2}}
    # Une séance manuelle (week 0) : supprimée par D1.1, non convertie.
    logs["S0-J1700000000000"] = {"done": True, "finishedAt": "2026-07-19T10:30:00.000", "title": "Séance perso",
                                 "customId": "1700000000000", "exerciseNames": {"c1": "Pompes"},
                                 "ex": {"c1": {"sets": [{"kg": "", "reps": "20", "rir": "", "v": "", "done": True,
                                                         "completedAt": "2026-07-19T10:20:00.000"}],
                                               "note": "", "showKg": None, "showRir": None, "showV": None}}}
    return {"programStart": {"status": "set", "date": depart.isoformat(), "origin": "user"},
            "logs": logs, "koach": {"answers": reponses}}


def nombre(texte: str) -> float | None:
    t = texte.strip().replace(",", ".")
    try:
        return float(t)
    except ValueError:
        return None


def convertir(ancien: dict, programme: dict) -> tuple[dict, dict]:
    """Conversion de référence (docs/CONVERSION_JOURNAL.md, règles C1 à C12)."""
    depart = dt.date.fromisoformat(ancien["programStart"]["date"])
    ordre_prog = {(w["week"], d["day"]): [e["id"] for e in d["exercises"]] for w in programme["weeks"] for d in w["days"]}
    rapport = {"sessionsRead": 0, "sessionsConverted": 0, "manualSessionsDropped": 0, "emptySessionsDropped": 0,
               "setsConverted": 0, "setsNotDone": 0, "setsUnmappedExercise": 0, "unmappedExerciseNames": [],
               "painAnswersDropped": 0}
    sessions = []
    for cle, s in ancien["logs"].items():
        rapport["sessionsRead"] += 1
        m = re.match(r"^S(\d+)-J(\d+)$", cle)
        if not m or int(m.group(1)) == 0:
            rapport["manualSessionsDropped"] += 1  # C2
            continue
        w, j = int(m.group(1)), int(m.group(2))
        date = (s["finishedAt"] or "")[:10] or (depart + dt.timedelta(days=(w - 1) * 7 + j - 1)).isoformat()  # C3
        ordre = ordre_prog.get((w, j), [])
        cles_ex = sorted(s["ex"], key=lambda k: (ordre.index(k) if k in ordre else len(ordre), k))  # C5
        series = []
        rang = 0
        for k in cles_ex:
            nom = s["exerciseNames"].get(k, "")
            cid = id_catalogue(nom)
            faites = [x for x in s["ex"][k]["sets"] if x.get("done")]
            rapport["setsNotDone"] += len(s["ex"][k]["sets"]) - len(faites)
            if cid is None:  # C6
                rapport["setsUnmappedExercise"] += len(faites)
                if faites and nom not in rapport["unmappedExerciseNames"]:
                    rapport["unmappedExerciseNames"].append(nom)
                continue
            if not faites:
                continue
            unite = EX[cid]["calc"]["unite"]
            for i, x in enumerate(faites):
                rec = {"exerciseId": cid, "exerciseOrder": rang, "setIndex": i, "kind": "work"}
                kg = nombre(x.get("kg", ""))
                if kg is not None:
                    rec["externalLoadKg"] = kg  # C7
                val = nombre(x.get("reps", ""))
                mesure = int(val) if val is not None else 0
                rec["seconds" if unite == "secondes" else "reps"] = mesure  # C8
                rir = x.get("effort")
                if rir is None:
                    rir = nombre(x.get("rir", ""))
                if rir is not None and rir >= 0:
                    rec["flames"] = fromrir(float(rir))  # C9
                rec["success"] = mesure > 0  # C10
                rec["excluded"] = bool(x.get("excluded", False))
                series.append(rec)
                rapport["setsConverted"] += 1
            rang += 1
        if not series:
            rapport["emptySessionsDropped"] += 1
            continue
        out = {"id": f"legacy-{cle}", "date": date, "origin": "imported",
               "programRef": {"blockId": "legacy-programme-v33", "weekIndex": w - 1, "dayIndex": j - 1},
               "resume": False, "completed": bool(s.get("done"))}
        rep = ancien.get("koach", {}).get("answers", {}).get(cle)
        if rep:  # C11
            bilan: dict = {}
            if "form" in rep:
                bilan["overall"] = max(1, min(5, math.ceil(rep["form"] / 2)))
            if "sleep" in rep:
                bilan["sleepHours"] = float(rep["sleep"])
            if rep.get("pain"):
                rapport["painAnswersDropped"] += len(rep["pain"])
            bilan["pains"] = []
            if len(bilan) > 1:
                out["healthCheck"] = bilan
        out["sets"] = series
        out["pains"] = []
        sessions.append(out)
        rapport["sessionsConverted"] += 1
    sessions.sort(key=lambda s: (s["date"], s["id"]))  # C12
    return {"schemaVersion": 1, "sessions": sessions}, rapport


# ---------------------------------------------------------------------------

def gz(obj) -> bytes:
    tampon = io.BytesIO()
    with gzip.GzipFile(fileobj=tampon, mode="wb", compresslevel=9, mtime=0, filename="") as f:
        f.write(json.dumps(obj, ensure_ascii=False, separators=(",", ":")).encode("utf-8"))
    return tampon.getvalue()


def joli(obj) -> bytes:
    return (json.dumps(obj, ensure_ascii=False, indent=1) + "\n").encode("utf-8")


def construire() -> dict[str, bytes]:
    erreurs: list[str] = []
    profs = profils()
    assert len(profs) == 40 and len({p["key"] for p in profs}) == 40, len(profs)
    for p in profs:
        erreurs += spec_validate.validate("AthleteProfile", p["profile"], p["key"])
        ids = spec_validate.exercise_ids("AthleteProfile", p["profile"], set())
        erreurs += [f"{p['key']} : exercice inconnu {i}" for i in ids if i not in EX]
        erreurs += [f"{p['key']} : matériel inconnu {m}" for m in p["profile"]["equipment"] if m not in MATERIEL]
    par_cle = {p["key"]: p["profile"] for p in profs}
    journaux = []
    for j in JOURNAUX:
        log, verite = simuler(j, par_cle[j["profil"]])
        erreurs += spec_validate.validate("TrainingLog", log, j["key"])
        ids = spec_validate.exercise_ids("TrainingLog", log, set())
        erreurs += [f"{j['key']} : exercice inconnu {i}" for i in ids if i not in EX]
        journaux.append({"key": j["key"], "profileKey": j["profil"], "weeks": j["weeks"],
                         "description": j["description"], "truth": verite, "log": log})
    programme = programme_proprietaire()
    ancien = journal_ancien(programme)
    converti, rapport = convertir(ancien, programme)
    erreurs += spec_validate.validate("TrainingLog", converti, "legacy")
    if erreurs:
        raise SystemExit("\n".join(erreurs[:40]))
    return {
        "profiles.json": joli({"schemaVersion": 1, "profiles": profs}),
        "journals.json.gz": gz({"schemaVersion": 1, "startDate": DEBUT.isoformat(), "journals": journaux}),
        "owner_program_v33.json.gz": gz(programme),
        "legacy_journal.json": joli({"schemaVersion": 1,
                                     "note": "Journal synthétique au format actuel de l'application (avant) et sa conversion (après).",
                                     "before": ancien, "after": converti, "report": rapport}),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    sorties = construire()
    ok = True
    for nom, octets in sorties.items():
        chemin = FIX / nom
        if args.check:
            actuel = chemin.read_bytes() if chemin.exists() else b""
            if nom.endswith(".gz"):
                meme = bool(actuel) and gzip.decompress(actuel) == gzip.decompress(octets)
            else:
                meme = actuel == octets
            if not meme:
                print(f"pas à jour : {nom}")
                ok = False
        else:
            FIX.mkdir(parents=True, exist_ok=True)
            chemin.write_bytes(octets)
            print(f"{nom} : {len(octets)} octets")
    if args.check:
        print("à jour" if ok else "relancer tool/gen_fixtures.py")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
