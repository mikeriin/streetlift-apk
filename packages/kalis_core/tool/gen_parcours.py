#!/usr/bin/env python3
"""Génère le parcours de questions du profil d'athlète v3 (lot CQ).

    python3 packages/kalis_core/tool/gen_parcours.py          # écrit
    python3 packages/kalis_core/tool/gen_parcours.py --check  # vérifie qu'ils sont à jour

Sorties (depuis `tool/parcours_spec.py`) :
- data/parcours_v3.json : arbre de questions adaptatif, préréglages de
  règlement, protocoles de tests guidés (lu par `ProfileQuestionnaire`) ;
- test/fixtures/profiles_v3.json : profils types au schéma 3 et, pour chacun,
  les questions vues (oracle des tests Dart et de l'application) ;
- docs/PARCOURS_V3.md : le parcours écrit pour le lot CU.

Déterministe ; aucune horloge.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import contracts_spec as spec  # noqa: E402
import gen_fixtures as gf  # noqa: E402
import parcours_spec as ps  # noqa: E402
import spec_validate  # noqa: E402

PKG = Path(__file__).resolve().parents[1]
TODAY_YEAR = 2026  # année de création des profils types (gen_fixtures.JOUR0)


# ------------------------------------------------------------ conditions ----

def values_at(obj, path: str) -> list:
    """Valeurs non nulles au bout de `path` (`cle[*]` parcourt une liste)."""
    current = [obj]
    for part in path.split("."):
        star = part.endswith("[*]")
        key = part[:-3] if star else part
        nxt = []
        for c in current:
            if not isinstance(c, dict) or key not in c or c[key] is None:
                continue
            v = c[key]
            if star:
                if isinstance(v, list):
                    nxt.extend(x for x in v if x is not None)
            else:
                nxt.append(v)
        current = nxt
    return current


def evaluate(cond: dict, profile: dict, today_year: int) -> bool:
    op = cond["op"]
    if op == "always":
        return True
    if op == "all":
        return all(evaluate(c, profile, today_year) for c in cond["of"])
    if op == "any":
        return any(evaluate(c, profile, today_year) for c in cond["of"])
    if op == "not":
        return not evaluate(cond["of"], profile, today_year)
    if op == "present":
        return bool(values_at(profile, cond["path"]))
    if op == "in":
        return any(v in cond["values"] for v in values_at(profile, cond["path"]))
    if op == "at_least":
        scale = ps.SCALES[cond["scale"]]
        floor = scale.index(cond["value"])
        return any(v in scale and scale.index(v) >= floor for v in values_at(profile, cond["path"]))
    if op == "min_number":
        return any(isinstance(v, (int, float)) and not isinstance(v, bool) and v >= cond["value"]
                   for v in values_at(profile, cond["path"]))
    if op == "age_at_least":
        birth = profile.get("birthYear")
        return isinstance(birth, int) and today_year - birth >= cond["value"]
    raise ValueError(f"opération inconnue : {op}")


def visible(profile: dict, today_year: int = TODAY_YEAR, since: int | None = None) -> list[dict]:
    return [q for q in ps.QUESTIONS
            if evaluate(q["when"], profile, today_year) and (since is None or q["since"] >= since)]


def eligible_tests(profile: dict, today_year: int = TODAY_YEAR) -> list[str]:
    return [t["id"] for t in ps.TESTS if evaluate(t["eligible"], profile, today_year)]


# --------------------------------------------------------- profils types ----

def _v3(base: dict, **fields) -> dict:
    p = dict(base["profile"])
    p["schemaVersion"] = 3
    # Les champs du schéma 3 suivent ceux du schéma 2, dans l'ordre du contrat.
    order = [f.name for f in next(t for t in spec.TYPES if t.name == "AthleteProfile").fields]
    p.update(fields)
    p = {k: p[k] for k in order if k in p}
    return {"key": base["key"], "description": base["description"], "profile": p}


def bench(ex, kind, source="declared", **kw):
    b = {"exerciseId": ex, "kind": kind, "source": source}
    for k in ("date", "externalLoadKg", "reps", "rir", "seconds", "distanceMeters", "bodyWeightKg", "protocolId"):
        if k in kw:
            v = kw[k]
            b[k] = float(v) if k in ("externalLoadKg", "rir", "distanceMeters", "bodyWeightKg") else v
    return b


def lift(ex, attempts=3, inc=1.25, best=None, target=None):
    out = {"exerciseId": ex, "attempts": attempts, "minIncrementKg": inc}
    if best is not None:
        out["bestKg"] = float(best)
    if target is not None:
        out["targetKg"] = float(target)
    return out


def profils_v3() -> list[dict]:
    P, lvl, perf, habit, lim = gf.profile, gf.lvl, gf.perf, gf.habit, gf.lim
    out = []

    out.append(_v3(
        P("v3_debutant_forme_generale", "Débutant complet, forme générale, 2 × 30 min à la maison sans matériel.",
          sex="male", birth=1994, height=178, weight=82, disciplines=gf.mix("general_fitness", 80, ("mobility", 20)),
          days=[(2, 30), (5, 30)], places=["home"], equipment=gf.SANS, experience="beginner",
          levels=[lvl("sw-pompe", "max_reps", 5, 10), lvl("mu-air-squat", "max_reps", 15, 25),
                  lvl("mu-gainage-ventral-coudes", "max_hold_seconds")],
          goals=[habit("g1", 2, 8)]),
        trainingAge="under_6_months", sleep="hours_6_to_7", stress="moderate", occupationalLoad="seated",
        otherSports=[], lifestyleUpdatedOn=gf.JOUR0))

    genou = lim("knee", "left", 2)
    genou.update(since="over_12_months", aggravatedBy=["knee_flexion", "running_jumping"])
    out.append(_v3(
        P("v3_intermediaire_musculation", "Femme de 34 ans, musculation en salle depuis 3 ans, 4 × 60 min, un footing par semaine.",
          sex="female", birth=1992, height=166, weight=64, disciplines=gf.mix("musculation", 80, ("mobility", 20)),
          days=[(1, 60), (2, 60), (4, 60), (6, 60)], places=["gym"], equipment=gf.SALLE, increments="salle",
          experience="intermediate",
          levels=[lvl("mu-back-squat-barre-haute", "one_rm_kg", 75, 85), lvl("mu-developpe-couche-barre", "one_rm_kg", 45, 52.5),
                  lvl("mu-souleve-de-terre-conventionnel", "one_rm_kg", 95, 105), lvl("sw-traction-pronation", "max_reps", 3, 5)],
          goals=[perf("g1", "mu-back-squat-barre-haute", "one_rm_kg", 95, "2027-06-01"), habit("g2", 4, 12)],
          limitations=[genou], liked=["mu-hip-thrust-barre"], disliked=["cf-burpee"]),
        trainingAge="years_2_to_5", trainingGap="none", sleep="hours_7_plus", stress="moderate",
        occupationalLoad="on_feet",
        otherSports=[{"kind": "running", "sessionsPerWeek": 1, "minutesPerSession": 40, "weekdays": [7]}],
        bodyWeightGoal="lose",
        benchmarks=[bench("mu-back-squat-barre-haute", "load_reps", externalLoadKg=70, reps=5, rir=1, date="2026-09-20"),
                    bench("mu-developpe-couche-barre", "load_reps", externalLoadKg=50, reps=1, rir=0, date="2026-08-30")],
        events=[], lifestyleUpdatedOn=gf.JOUR0))

    coude = lim("elbow", "both", 2)
    coude.update(since="months_3_to_12", aggravatedBy=["straight_arm_support", "pull_bent_arm"])
    out.append(_v3(
        P("v3_competiteur_elite_streetlifting", "Compétiteur élite de streetlifting (catégorie −73 kg), mode street 70/15/15, 5 séances, compétition principale dans 28 semaines.",
          sex="male", birth=1999, height=174, weight=72.4, street_mode=gf.street("streetlifting", 70, 15, 15),
          days=[(1, 105), (2, 90), (4, 105), (5, 90), (6, 120)], places=["gym", "outdoor"], equipment=gf.STREETLIFT,
          increments="street", experience="elite", mode="free",
          known=["cd-muscle-up-barre-strict", "sw-traction-chest-to-bar"],
          levels=[lvl("sl-traction-lestee", "one_rm_kg", 72.5, 77.5), lvl("sl-dips-leste", "one_rm_kg", 100, 107.5),
                  lvl("sl-muscle-up-leste", "one_rm_kg", 22.5, 27.5), lvl("sl-squat-competition", "one_rm_kg", 175, 185),
                  lvl("sw-traction-pronation", "max_reps", 32, 36)],
          goals=[perf("g1", "sl-traction-lestee", "one_rm_kg", 82.5, "2027-04-17"),
                 perf("g2", "sl-dips-leste", "one_rm_kg", 112.5, "2027-04-17"),
                 perf("g3", "sl-muscle-up-leste", "one_rm_kg", 30, "2027-04-17"),
                 perf("g4", "sl-squat-competition", "one_rm_kg", 190, "2027-04-17")],
          limitations=[coude]),
        trainingAge="over_5_years", trainingGap="none", sleep="hours_6_to_7", stress="low", occupationalLoad="on_feet",
        otherSports=[], bodyWeightGoal="maintain",
        benchmarks=[
            bench("sl-traction-lestee", "load_reps", "competition", externalLoadKg=75, reps=1, rir=0, date="2026-06-06", bodyWeightKg=72.8),
            bench("sl-dips-leste", "load_reps", "competition", externalLoadKg=105, reps=1, rir=0, date="2026-06-06", bodyWeightKg=72.8),
            bench("sl-muscle-up-leste", "load_reps", "competition", externalLoadKg=25, reps=1, rir=0, date="2026-06-06", bodyWeightKg=72.8),
            bench("sl-squat-competition", "load_reps", "competition", externalLoadKg=180, reps=1, rir=0, date="2026-06-06"),
            bench("sw-traction-pronation", "max_reps", reps=34, date="2026-09-12", bodyWeightKg=72.5),
        ],
        events=[
            {"id": "e1", "kind": "strength_competition", "priority": "main", "date": "2027-04-17",
             "name": "Championnat national", "ruleset": "final_rep_all4", "weightClassKg": 73.0,
             "lifts": [lift("sl-muscle-up-leste", best=25, target=30), lift("sl-traction-lestee", best=75, target=82.5),
                       lift("sl-dips-leste", best=105, target=112.5), lift("sl-squat-competition", inc=2.5, best=180, target=190)],
             "goalIds": ["g1", "g2", "g3", "g4"]},
            {"id": "e2", "kind": "strength_competition", "priority": "preparation", "date": "2027-01-23",
             "name": "Open régional", "ruleset": "final_rep_2lift", "weightClassKg": 73.0,
             "lifts": [lift("sl-traction-lestee", best=75), lift("sl-dips-leste", best=105)]},
        ],
        skills=[{"targetExerciseId": "cs-front-lever", "currentExerciseId": "cs-front-lever-straddle",
                 "bestHoldSeconds": 8, "assessedOn": "2026-09-25"}],
        weakPoints=[{"exerciseId": "sl-dips-leste", "kind": "bottom"},
                    {"exerciseId": "sl-muscle-up-leste", "kind": "transition"}],
        specialization={"kind": "exercise", "exerciseId": "sl-muscle-up-leste", "weeks": 8, "maintenance": "maintain"},
        lifestyleUpdatedOn=gf.JOUR0))

    out.append(_v3(
        P("v3_coureuse_10km", "Autre discipline : coureuse régulière (cardio 70 %, musculation 20 %, mobilité 10 %), 10 km visé en mars, reprise après deux semaines d'arrêt.",
          sex="female", birth=1990, height=168, weight=59, disciplines=gf.mix("cardio", 70, ("musculation", 20), ("mobility", 10)),
          days=[(2, 45), (4, 45), (7, 75)], places=["outdoor", "home"], equipment=gf.COURSE + ["élastique"],
          experience="intermediate",
          levels=[lvl("ca-footing-endurance-fondamentale", "time_seconds", 1530, 1620, distance=5000),
                  lvl("mu-air-squat", "max_reps", 30, 40)],
          goals=[perf("g1", "ca-footing-endurance-fondamentale", "time_seconds", 2880, "2027-03-14", distance=10000)]),
        trainingAge="years_2_to_5", trainingGap="under_3_weeks", sleep="hours_7_plus", stress="high",
        occupationalLoad="seated",
        otherSports=[{"kind": "cycling", "sessionsPerWeek": 1, "minutesPerSession": 60}],
        bodyWeightGoal="no_goal",
        benchmarks=[bench("ca-footing-endurance-fondamentale", "time_trial", distanceMeters=5000, seconds=1560, date="2026-09-06")],
        events=[{"id": "e1", "kind": "race", "priority": "main", "date": "2027-03-14", "name": "10 km de printemps",
                 "distanceMeters": 10000.0, "targetSeconds": 2880, "goalIds": ["g1"]}],
        lifestyleUpdatedOn=gf.JOUR0))

    out.append(_v3(
        P("v3_sets_reps_avance", "Mode street, principale sets & reps (20/60/20), avancé, compétition de répétitions contre la montre, sport de combat deux fois par semaine.",
          sex="male", birth=2001, height=172, weight=66, street_mode=gf.street("sets_reps", 20, 60, 20),
          days=[(1, 75), (3, 75), (5, 75), (7, 60)], places=["outdoor"], equipment=gf.PARC + ["gilet lesté", "ceinture de lest", "disques"],
          increments="street", experience="advanced",
          levels=[lvl("sw-traction-pronation", "max_reps", 26, 30), lvl("sw-dips-barres-paralleles", "max_reps", 45, 50),
                  lvl("sw-pompe", "max_reps", 65, 75), lvl("cd-muscle-up-barre-strict", "max_reps", 10, 12)],
          goals=[perf("g1", "sw-traction-pronation", "max_reps", 35, "2027-05-22")]),
        trainingAge="years_2_to_5", trainingGap="none", sleep="under_6_hours", stress="moderate",
        occupationalLoad="heavy",
        otherSports=[{"kind": "combat_sport", "sessionsPerWeek": 2, "minutesPerSession": 90, "weekdays": [2, 4], "hard": True}],
        bodyWeightGoal="maintain",
        benchmarks=[bench("sw-traction-pronation", "max_reps", reps=28, date="2026-09-18", bodyWeightKg=66),
                    bench("cd-muscle-up-barre-strict", "max_reps", reps=11, date="2026-09-18", bodyWeightKg=66)],
        events=[{"id": "e1", "kind": "reps_competition", "priority": "main", "date": "2027-05-22", "name": "Coupe d'endurance",
                 "mode": "for_time", "rounds": 2, "timeLimitSeconds": 600,
                 "stations": [{"exerciseId": "cd-muscle-up-barre-strict", "reps": 5, "unbroken": True},
                              {"exerciseId": "sw-dips-barres-paralleles", "reps": 30},
                              {"exerciseId": "sw-traction-pronation", "reps": 30},
                              {"exerciseId": "sw-pompe", "reps": 30},
                              {"exerciseId": "mu-air-squat", "reps": 20, "externalLoadKg": 20.0}],
                 "goalIds": ["g1"]}],
        skills=[{"targetExerciseId": "cs-back-lever", "currentExerciseId": "cs-back-lever-straddle", "bestHoldSeconds": 6}],
        weakPoints=[{"exerciseId": "sw-dips-barres-paralleles", "kind": "late_set_fatigue"}],
        lifestyleUpdatedOn=gf.JOUR0))
    return out


def fixtures() -> dict:
    items = []
    for p in profils_v3():
        vis = visible(p["profile"])
        items.append({
            "key": p["key"], "description": p["description"], "profile": p["profile"],
            "expected": {
                "questionIds": [q["id"] for q in vis],
                "questions": len(vis),
                "newQuestions": sum(1 for q in vis if q["since"] >= 3),
                "testIds": eligible_tests(p["profile"]),
            },
        })
    return {"schema": 1, "todayYear": TODAY_YEAR, "profiles": items}


def controle(fx: dict) -> list[str]:
    err: list[str] = []
    ids = [q["id"] for q in ps.QUESTIONS]
    if len(set(ids)) != len(ids):
        err.append("identifiants de question en double")
    ecrans = {s["id"] for s in ps.SCREENS}
    champs = {f.name for f in next(t for t in spec.TYPES if t.name == "AthleteProfile").fields}
    enums = {e.name: [c for _, c in e.values] for e in spec.ENUMS}
    for q in ps.QUESTIONS:
        if q["screen"] not in ecrans:
            err.append(f"{q['id']} : écran inconnu")
        for f in q["fields"]:
            if f.split(".")[0] not in champs:
                err.append(f"{q['id']} : champ {f} inconnu du profil")
        if q["required"] and (q["skip"] or q["unknown"]):
            err.append(f"{q['id']} : obligatoire et passable")
    # Les options des questions à choix du schéma 3 sont exactement les codes de leur enum.
    lie = {"training_age": "TrainingAge", "training_gap": "TrainingGap", "sleep": "SleepBand", "stress": "StressBand",
           "body_weight_goal": "BodyWeightGoal", "experience_level": "ExperienceLevel", "sex": "Sex",
           "guidance_mode": "GuidanceMode", "places": "Place"}
    par_id = {q["id"]: q for q in ps.QUESTIONS}
    for qid, enum in lie.items():
        codes = [o["code"] for o in par_id[qid]["options"]]
        if codes != enums[enum]:
            err.append(f"{qid} : options {codes} ≠ {enum} {enums[enum]}")
    assert ps.SCALES["experience"] == enums["ExperienceLevel"]
    assert ps.SCALES["trainingAge"] == enums["TrainingAge"]
    sous = {"benchmarks": {"kind": "BenchmarkKind"}, "events": {"kind": "EventKind", "priority": "EventPriority", "mode": "RepsEventMode"},
            "specialization": {"kind": "SpecializationKind", "maintenance": "MaintenancePolicy"},
            "weak_points": {"kind": "WeakPointKind"}, "outside_load": {"kind": "OtherSportKind", "regions": "BodyRegion"},
            "limitations": {"since": "ConstraintSince", "aggravatedBy": "AggravatingMovement"}}
    for qid, table in sous.items():
        for it in par_id[qid]["items"]:
            if it["field"] in table:
                codes = [o["code"] for o in it["options"]]
                if codes != enums[table[it["field"]]]:
                    err.append(f"{qid}.{it['field']} : options ≠ {table[it['field']]}")
    for t in ps.TESTS:
        if t["benchmarkKind"] is not None and t["benchmarkKind"] not in enums["BenchmarkKind"]:
            err.append(f"{t['id']} : nature inconnue")
        if t["testKind"] is not None and t["testKind"] not in enums["TestKind"]:
            err.append(f"{t['id']} : test inconnu")
    for preset in ps.RULESET_PRESETS:
        for l in preset.get("lifts", []) + preset.get("stations", []):
            if l["exerciseId"] not in gf.EX:
                err.append(f"{preset['code']} : exercice {l['exerciseId']} inconnu")
    for p in fx["profiles"]:
        err += spec_validate.validate("AthleteProfile", p["profile"], p["key"])
        for i in spec_validate.exercise_ids("AthleteProfile", p["profile"], set()):
            if i not in gf.EX:
                err.append(f"{p['key']} : exercice {i} inconnu")
        for m in p["profile"]["equipment"]:
            if m not in gf.MATERIEL:
                err.append(f"{p['key']} : matériel {m} inconnu")
    return err


# -------------------------------------------------------------- sorties ----

def parcours_json() -> dict:
    return {"schema": 1, "version": ps.VERSION, "scales": ps.SCALES, "screens": ps.SCREENS,
            "questions": ps.QUESTIONS, "rulesetPresets": ps.RULESET_PRESETS, "tests": ps.TESTS}


QUI = {
    "always": "tous",
}


def qui(cond: dict) -> str:
    """Condition en français simple."""
    op = cond["op"]
    if op == "always":
        return "tous"
    if op == "all":
        return " ET ".join(_par(c) for c in cond["of"])
    if op == "any":
        return " OU ".join(_par(c) for c in cond["of"])
    if op == "not":
        return "pas (" + qui(cond["of"]) + ")"
    if op == "present":
        return f"`{cond['path']}` renseigné"
    if op == "in":
        return f"`{cond['path']}` ∈ {{{', '.join(cond['values'])}}}"
    if op == "at_least":
        return f"`{cond['path']}` ≥ {cond['value']}"
    if op == "min_number":
        return f"`{cond['path']}` ≥ {cond['value']}"
    if op == "age_at_least":
        return f"âge ≥ {cond['value']} ans"
    raise ValueError(op)


def _par(c: dict) -> str:
    return "(" + qui(c) + ")" if c["op"] in ("all", "any") else qui(c)


FORME = {"choice": "un choix", "multi": "plusieurs choix", "number": "nombre", "text": "texte", "group": "éditeur de liste",
         "composite": "plusieurs choix + éditeur", "date": "date"}


def doc(fx: dict) -> str:
    o: list[str] = []
    w = o.append
    w("# Parcours de création du profil v3 — pour le lot CU\n\n")
    w("Fichier généré par `tool/gen_parcours.py` depuis `tool/parcours_spec.py` — ne pas modifier à la main. "
      "Données lues par l'application : [`data/parcours_v3.json`](../data/parcours_v3.json) "
      "(`ProfileQuestionnaire`, `lib/src/questionnaire.dart`). Pourquoi chaque question existe, à qui elle est posée et "
      "ce qui a été écarté : [`PROFIL_V3.md`](PROFIL_V3.md).\n\n")
    w("## 1. Principe\n\n"
      "- Le parcours v3 **reprend l'écran de création du profil du lot G6** (mêmes écrans, mêmes composants, même ton) et y "
      "ajoute les questions du schéma 3, **posées seulement à ceux pour qui elles comptent**. Une question = un écran ou un "
      "bloc d'écran clair ; Koach présente chaque écran (texte `koach`).\n"
      "- **Arbre adaptatif** : chaque question porte une condition d'apparition (`when`) évaluée sur le profil en cours de "
      "saisie. L'application ne code aucune condition : elle appelle "
      "`ProfileQuestionnaire.visibleQuestions(profilJson, todayYear: …)` après chaque réponse. Une réponse absente rend la "
      "condition fausse : **sans réponse, on montre le parcours le plus court**.\n"
      "- **« Passer »** (`skip`) : le champ reste absent du profil — jamais de valeur par défaut (D5.8). "
      "**« Je ne sais pas »** (`unknown`) : même effet, et un test guidé sera proposé (§ 5).\n"
      "- **Liste vide ≠ champ absent** : `otherSports: []` = « aucun autre sport » ; `events: []` = « aucune échéance » ; "
      "champ absent = question non posée ou passée.\n"
      "- **Santé** : la règle L13 et son questionnaire sont inchangés. Les gênes sont des **contraintes d'entraînement** "
      "(zone, côté, gêne perçue, depuis quand, mouvements qui la réveillent), jamais un diagnostic ; elles ne sont écrites "
      "qu'avec l'accord santé (G6, KT-042).\n"
      "- **Valeurs habituelles, pas valeurs du jour** : sommeil, stress et charge hors programme du profil sont des "
      "habitudes ; la nuit dernière, le stress et les douleurs du jour restent dans le bilan de séance (D5.8-D5.9). Aucun "
      "doublon : le bilan de séance n'est pas modifié.\n\n")

    w("## 2. Nombre de questions vues par profil type\n\n"
      "Convention : une question = une entrée de `questions` visible (un champ, ou un éditeur de liste compté une fois, "
      "quel que soit le nombre d'éléments saisis). Les écrans d'accueil et de récapitulatif ne posent pas de question. "
      "« Nouvelles » = questions du schéma 3. Profils : `test/fixtures/profiles_v3.json` ; les mêmes nombres sont "
      "vérifiés en Dart (`test/questionnaire_test.dart`) — CU les revérifie dans l'application.\n\n"
      "| Profil type | Questions vues | dont nouvelles (schéma 3) | Nouvelles questions vues |\n| --- | ---: | ---: | --- |\n")
    par_id = {q["id"]: q for q in ps.QUESTIONS}
    for p in fx["profiles"]:
        e = p["expected"]
        nouvelles = [i for i in e["questionIds"] if par_id[i]["since"] >= 3]
        w(f"| `{p['key']}` — {p['description']} | {e['questions']} | {e['newQuestions']} | "
          f"{', '.join('`' + i + '`' for i in nouvelles)} |\n")
    total_v2 = sum(1 for q in ps.QUESTIONS if q["since"] == 2)
    w(f"\nRepère : le parcours G6 (schéma 2) posait {total_v2} questions à tout le monde. Le parcours v3 en pose **moins "
      "de schéma 2 à un débutant** (les exercices aimés ou détestés lui sont demandés pendant la revue du programme, D4.5) "
      "et lui ajoute 4 questions à un seul appui. Parcours le plus court possible à information égale : chaque question du "
      "schéma 3 retenue change une décision du moteur (colonne « Ce que ça change ») ; celles qui n'en changent aucune sont "
      "écartées dans `PROFIL_V3.md`.\n\n")

    w("## 3. Écrans et questions, dans l'ordre\n\n")
    for s in ps.SCREENS:
        qs = [q for q in ps.QUESTIONS if q["screen"] == s["id"]]
        tag = " — **nouvel écran**" if s["since"] >= 3 else ""
        w(f"### Écran `{s['id']}` — {s['title']}{tag}\n\n")
        w(f"Koach : « {s['koach']} »\n\n")
        if "note" in s:
            w(s["note"] + "\n\n")
        if not qs:
            continue
        w("| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |\n| --- | --- | --- | --- | --- | --- | ---: |\n")
        for q in qs:
            forme = FORME[q["kind"]]
            extra = [x for x, on in (("« Passer »", q["skip"]), ("« Je ne sais pas »", q["unknown"])) if on]
            if extra:
                forme += " ; " + ", ".join(extra)
            w(f"| `{q['id']}` | {q['text']} | {forme} | {', '.join('`' + f + '`' for f in q['fields'])} | {qui(q['when'])} | "
              f"{'oui' if q['required'] else 'non'} | {q['since']} |\n")
        w("\n")
        for q in qs:
            details = []
            if "koach" in q:
                details.append(f"Koach : « {q['koach']} »")
            if "options" in q:
                details.append("Réponses : " + " · ".join(
                    f"{o['label']}" + (f" ({o['hint']})" if "hint" in o else "") + f" → `{o['code']}`" for o in q["options"]))
            if "validation" in q:
                details.append("Validation : " + q["validation"])
            if "effect" in q:
                details.append("Ce que ça change : " + q["effect"])
            if "note" in q:
                details.append("Note : " + q["note"])
            if "factor" in q:
                details.append(f"Justification : `PROFIL_V3.md`, facteur `{q['factor']}`.")
            if details or "items" in q:
                w(f"**`{q['id']}`**\n\n")
                for d in details:
                    w(f"- {d}\n")
                if "items" in q:
                    w("- Champs d'un élément :\n\n")
                    w("  | Champ | Texte | Forme | Obligatoire | Réponses / note |\n  | --- | --- | --- | --- | --- |\n")
                    for it in q["items"]:
                        rep = []
                        if "options" in it:
                            rep.append(" · ".join(f"{o['label']} → `{o['code']}`" for o in it["options"]))
                        if "note" in it:
                            rep.append(it["note"])
                        w(f"  | `{it['field']}` | {it['text']} | {it['kind']} | {'oui' if it['required'] else 'non'} | "
                          f"{' — '.join(rep) or '—'} |\n")
                w("\n")

    w("## 4. Échéances : préréglages de règlement\n\n"
      "L'éditeur d'échéance propose ces préréglages (`rulesetPresets`) ; ils pré-remplissent mouvements, tentatives et sauts "
      "de charge, **que l'utilisateur peut toujours modifier** : les formats varient d'un organisateur à l'autre, et aucun "
      "règlement unifié n'existe pour les compétitions de répétitions (sets & reps). Le moteur ne lit que les données de "
      "l'échéance (`SeasonEvent`), jamais le code du règlement.\n\n"
      "| Code | Libellé | Contenu | Source | État de la vérification |\n| --- | --- | --- | --- | --- |\n")
    for r in ps.RULESET_PRESETS:
        if "lifts" in r:
            contenu = " ; ".join(f"`{l['exerciseId']}` × {l['attempts']} tentatives (saut ≥ {l['minIncrementKg']} kg)" for l in r["lifts"])
        else:
            contenu = f"{r['mode']}, {r['timeLimitSeconds']} s : " + ", ".join(f"`{s['exerciseId']}`" for s in r["stations"])
        if "weightClassesKg" in r:
            c = r["weightClassesKg"]
            contenu += f" ; catégories femmes {', '.join(str(x) for x in c['female'])} kg et plus ; hommes {', '.join(str(x) for x in c['male'])} kg et plus"
        w(f"| `{r['code']}` | {r['label']} | {contenu} | {r['source']} | {r['status']} |\n")
    w("\nFormats de compétition de répétitions réellement observés (pour l'éditeur de postes) : maximum de répétitions "
      "lestées en 2 minutes (ISF Multirep) ; total de répétitions sur trois exercices lestés (WSWCF « Power ») ; volume "
      "imposé au poids du corps contre la montre (WSWCF « Strength ») ; duel à élimination sur une routine imposée "
      "différente à chaque tour, avec pyramides, maintiens et séries indivisibles (Calisthenics Cup 2025). D'où un type "
      "d'épreuve générique : mode, suite ordonnée de postes (exercice, répétitions ou durée, lest, série indivisible), "
      "tours, limite de temps.\n\n")

    w("## 5. Tests guidés\n\n"
      "Quand une capacité est inconnue (« Je ne sais pas », ou aucun record pour un mouvement dont le programme a besoin), "
      "l'application propose un test guidé. **À la création du profil : uniquement des déclarations, aucun test physique.** "
      "Les tests sous-maximaux se font **dans la première séance** (le moteur les prescrit comme séries de rôle `test`, "
      "`ExercisePrescription.test`) ; les tests maximaux et de course, **plus tard**, après 3 à 4 séances de "
      "familiarisation. Les valeurs des deux à trois premières séances sont « provisoires » : l'apprentissage du geste fait "
      "monter un maximum de 5 à 10 % sans gain de force réel.\n\n"
      "Le résultat d'un test est un `Benchmark` (`source: guided_test`, `protocolId`) que l'application ajoute à "
      "`AthleteProfile.benchmarks` (ou que le moteur dynamique rend dans `AdaptReview.testResults`). Conversions : "
      "`lib/src/estimation.dart`. `ProfileQuestionnaire.eligibleTests(profilJson, todayYear: …)` rend les protocoles "
      "permis pour un profil.\n\n")
    for t in ps.TESTS:
        w(f"### `{t['id']}` — {t['title']}\n\n")
        w(f"- **Pour qui** : {t['forWhom']}\n")
        w(f"- **Quand** : {'à la création (déclaratif)' if t['stage'] == 'creation' else 'première séance' if t['stage'] == 'first_session' else 'plus tard (après familiarisation)'}"
          f" ; permis si : {qui(t['eligible'])}.\n")
        w("- **Sécurité** : " + " ".join(t["safety"]) + "\n")
        w("- **Déroulé** :\n")
        for i, s in enumerate(t["steps"], 1):
            w(f"  {i}. {s}\n")
        if t["stop"]:
            w("- **Arrêt** : " + " ".join(t["stop"]) + "\n")
        w(f"- **Conversion** : {t['conversion']['text']}"
          + (f" (`{t['conversion']['function']}`)" if "function" in t["conversion"] else "") + "\n")
        w(f"- **Incertitude** : {t['uncertainty']}\n")
        w(f"- Références (`PROFIL_V3.md`, § 5) : {', '.join(t['refs'])}.\n\n")
    w("Tests permis par profil type (`expected.testIds`) :\n\n| Profil type | Tests permis |\n| --- | --- |\n")
    for p in fx["profiles"]:
        w(f"| `{p['key']}` | {', '.join('`' + i + '`' for i in p['expected']['testIds'])} |\n")

    w("\n## 6. Utilisateurs existants, édition, sauvegarde\n\n"
      "- **Migration** : `profile.toSchema3()` (ou `migrateAthleteProfileJsonToSchema3`) ne change que `schemaVersion` : "
      "aucun champ perdu, aucun inventé — toutes les réponses du schéma 3 restent absentes tant que l'utilisateur ne les a "
      "pas données. Le programme en cours n'est pas régénéré ; le programme importé du propriétaire ne l'est jamais (D5.10).\n"
      "- **« Compléter mon profil »** : montrer les seules questions du schéma 3 visibles pour ce profil — "
      "`visibleQuestions(profilJson, todayYear: …, since: 3)` — dans l'ordre du § 3. Invitation discrète de Koach, une "
      "seule fois. L'application retient elle-même (hors du profil) quelles questions ont été passées, pour ne pas les "
      "reproposer d'office.\n"
      "- **Édition** : chaque réponse du schéma 3 est modifiable depuis Réglages › Profil, rubrique par rubrique, comme "
      "celles du schéma 2. Les réponses de l'écran `recuperation` portent une date (`lifestyleUpdatedOn`) : Koach peut "
      "proposer de les revoir quand elles ont plus de 3 mois (choix raisonné : le stress et le sommeil changent).\n"
      "- **Avant d'enregistrer** : `profile.validate()` et `catalog.checkProfile(profile)` vides. Un profil qui porte un "
      "champ du schéma 3 doit être au schéma 3 (`schema3_field` sinon).\n"
      "- **Sauvegarde, export, import** : le profil se sérialise en entier par `toJson()` ; les champs du schéma 3 y sont, "
      "rien d'autre à ajouter. Un profil au schéma 2 relu par `fromJson` se réécrit à l'identique.\n"
      "- **Moteurs actuels** : `kalis_plan` 0.1.0 et `kalis_adapt` 0.1.0 lisent un profil au schéma 3 sans changement (ils "
      "ignorent les champs nouveaux) ; les moteurs calibrés (CP1, CA1) les liront.\n")
    return "".join(o)


def dumps(obj) -> str:
    return json.dumps(obj, ensure_ascii=False, indent=1) + "\n"


def sorties() -> dict[Path, str]:
    fx = fixtures()
    err = controle(fx)
    if err:
        raise SystemExit("parcours invalide :\n" + "\n".join(err))
    return {
        PKG / "data/parcours_v3.json": dumps(parcours_json()),
        PKG / "test/fixtures/profiles_v3.json": dumps(fx),
        PKG / "docs/PARCOURS_V3.md": doc(fx),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    ok = True
    for path, text in sorties().items():
        if args.check:
            if not path.exists() or path.read_text(encoding="utf-8") != text:
                print(f"pas à jour : {path.relative_to(PKG)}")
                ok = False
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")
    print("à jour" if ok and args.check else ("écrit" if not args.check else "relancer tool/gen_parcours.py"))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
