"""Spécification du parcours de questions du profil d'athlète v3 (lot CQ).

Source unique : `gen_parcours.py` en tire `data/parcours_v3.json` (lu par
`ProfileQuestionnaire`, `lib/src/questionnaire.dart`), les profils types v3
(`test/fixtures/profiles_v3.json`) et `docs/PARCOURS_V3.md`.

Chaque question dit : à qui elle est posée (`when`, condition sur le profil
en cours de saisie), sous quelle forme, dans quel champ elle écrit, et ce
qu'elle change dans le programme. La revue des facteurs qui justifie chaque
question (références vérifiées, verdict posée / déduite / écartée) est dans
`docs/PROFIL_V3.md` ; la clé `factor` y renvoie.

Langage des conditions (objets JSON, évalués sur le JSON du profil) :
    {"op": "always"}
    {"op": "all", "of": [...]}, {"op": "any", "of": [...]}, {"op": "not", "of": c}
    {"op": "present", "path": p}      une valeur non nulle existe à ce chemin
    {"op": "in", "path": p, "values": [...]}   une valeur du chemin est dans la liste
    {"op": "at_least", "path": p, "scale": s, "value": v}   rang dans l'échelle ≥ rang de v
    {"op": "min_number", "path": p, "value": n}   un nombre du chemin est ≥ n
    {"op": "age_at_least", "value": n}   année du jour − `birthYear` ≥ n
Chemin : clés séparées par des points ; `cle[*]` parcourt une liste.
Une valeur absente rend la condition fausse (sauf sous `not`) : sans réponse,
on montre le parcours le plus court.
"""
from __future__ import annotations

VERSION = "0.4.0"

SCALES = {
    "experience": ["beginner", "intermediate", "advanced", "elite"],
    "trainingAge": ["under_6_months", "months_6_to_24", "years_2_to_5", "over_5_years"],
}

ALWAYS = {"op": "always"}


def all_of(*c):
    return {"op": "all", "of": list(c)}


def any_of(*c):
    return {"op": "any", "of": list(c)}


def not_(c):
    return {"op": "not", "of": c}


def present(path):
    return {"op": "present", "path": path}


def is_in(path, *values):
    return {"op": "in", "path": path, "values": list(values)}


def at_least(path, scale, value):
    return {"op": "at_least", "path": path, "scale": scale, "value": value}


def min_number(path, value):
    return {"op": "min_number", "path": path, "value": value}


def age_at_least(value):
    return {"op": "age_at_least", "value": value}


def discipline(*codes):
    """La discipline principale ou une secondaire est parmi `codes`."""
    return any_of(is_in("disciplines.primary", *codes), is_in("disciplines.secondaries[*].discipline", *codes))


INTERMEDIATE = at_least("experience", "experience", "intermediate")
ADVANCED = at_least("experience", "experience", "advanced")
FIGURES = any_of(discipline("calisthenics"), min_number("streetMode.calisthenicsPct", 1))
STRENGTH_DISCIPLINES = discipline("streetlifting", "street_workout", "calisthenics", "musculation", "crossfit")
HEALTH_STANDARD = is_in("healthScreening.outcome", "standard")

SCREENS = [
    {"id": "accueil", "title": "Bienvenue", "since": 2,
     "koach": "Salut ! Quelques questions et je te prépare un programme à ta mesure.",
     "note": "Accueil de Koach et avertissement santé L13 (inchangés)."},
    {"id": "toi", "title": "Toi", "since": 2, "koach": "On commence par toi."},
    {"id": "discipline", "title": "Ta discipline", "since": 2, "koach": "Qu'est-ce qui te fait envie ?"},
    {"id": "dosage", "title": "Le dosage", "since": 2, "koach": "Un peu d'autre chose à côté ?"},
    {"id": "experience", "title": "Ton expérience", "since": 2,
     "koach": "Dis-moi d'où tu pars : je règle le volume et le rythme là-dessus."},
    {"id": "niveaux", "title": "Ton niveau", "since": 2,
     "koach": "Une fourchette me suffit. Si tu ne sais pas, on mesurera ensemble."},
    {"id": "objectifs", "title": "Tes objectifs", "since": 2, "koach": "Où veux-tu aller ?"},
    {"id": "disponibilites", "title": "Tes disponibilités", "since": 2, "koach": "Quels jours, et combien de temps ?"},
    {"id": "lieux", "title": "Lieux et matériel", "since": 2, "koach": "Où t'entraînes-tu, et avec quoi ?"},
    {"id": "recuperation", "title": "Ta récupération", "since": 3,
     "koach": "Ton corps récupère aussi en dehors des séances. Trois questions rapides.",
     "note": "Nouvel écran (schéma 3). Les trois premières questions tiennent sur un écran ; chacune a « Passer »."},
    {"id": "sante", "title": "Ta santé", "since": 2, "koach": "Une zone à ménager ? Je la protège.",
     "note": "Questionnaire santé L13 inchangé ; les gênes sont des contraintes d'entraînement, jamais un diagnostic."},
    {"id": "preferences", "title": "Tes préférences", "since": 2, "koach": "Des exercices que tu adores, ou pas du tout ?"},
    {"id": "mode", "title": "Assisté ou libre", "since": 2, "koach": "Je décide, ou je propose ?"},
    {"id": "recap", "title": "Récapitulatif", "since": 2, "koach": "Tout est bon ? Tu peux tout modifier."},
]


def opt(code, label, hint=None):
    o = {"code": code, "label": label}
    if hint:
        o["hint"] = hint
    return o


def q(id, screen, since, kind, text, fields, *, when=ALWAYS, required=False, skip=False, unknown=False,
      options=None, koach=None, factor=None, effect=None, items=None, note=None, validation=None):
    out = {"id": id, "screen": screen, "since": since, "kind": kind, "text": text, "fields": fields,
           "required": required, "skip": skip, "unknown": unknown, "when": when}
    for k, v in (("options", options), ("koach", koach), ("factor", factor), ("effect", effect),
                 ("items", items), ("note", note), ("validation", validation)):
        if v is not None:
            out[k] = v
    return out


def item(field, text, kind, *, required=True, options=None, note=None):
    out = {"field": field, "text": text, "kind": kind, "required": required}
    if options is not None:
        out["options"] = options
    if note is not None:
        out["note"] = note
    return out


QUESTIONS = [
    # ------------------------------------------------------------- toi ----
    q("display_name", "toi", 2, "text", "Comment je t'appelle ?", ["displayName"], skip=True,
      validation="40 caractères au plus."),
    q("sex", "toi", 2, "choice", "Tu es…", ["sex"], required=True,
      options=[opt("female", "Une femme"), opt("male", "Un homme"), opt("undisclosed", "Je préfère ne pas le dire")],
      factor="sexe", effect="Aucun effet sur le programme (gains relatifs identiques) ; sert aux repères de rang."),
    q("birth_year", "toi", 2, "number", "Ton année de naissance ?", ["birthYear"], required=True,
      validation="18 ans et plus (règle L13).", factor="age",
      effect="Prudence des tests (pas de maximum direct après 65 ans sans expérience) ; attentes de progression."),
    q("height", "toi", 2, "number", "Ta taille ?", ["heightCm"], required=True, validation="100 à 250 cm.",
      factor="taille", effect="Aucun effet sur le programme ; champ obligatoire du schéma 2, gardé."),
    q("body_weight", "toi", 2, "number", "Ton poids ?", ["bodyWeightKg"], skip=True, validation="25 à 300 kg.",
      koach="C'est ta charge sur les tractions, les dips, les pompes : avec lui, je calcule juste.",
      factor="poids_de_corps",
      effect="Charge totale des exercices au poids du corps ou lestés, force relative, catégories de poids.",
      note="En mode street ou en calisthénie, Koach explique que sans le poids les charges lestées ne peuvent pas être calculées ; la question reste passable."),
    # ------------------------------------------------------ discipline ----
    q("discipline", "discipline", 2, "group", "Ta discipline principale (ou le mode street)",
      ["disciplines.primary", "streetMode"], required=True,
      note="8 disciplines (D3.1) ou mode street : principale parmi streetlifting, sets & reps, calisthénie (D3.3)."),
    q("secondaries", "dosage", 2, "group", "Une ou deux disciplines en plus, et leur dosage",
      ["disciplines.secondaries", "disciplines.primaryPct"], required=True,
      note="1 à 2 secondaires, somme 100 % (D3.2) ; en mode street, le dosage des deux autres styles."),
    # ------------------------------------------------------ expérience ----
    q("experience_level", "experience", 2, "choice", "Ton niveau aujourd'hui ?", ["experience"], skip=True,
      options=[opt("beginner", "Débutant", "Je découvre, ou je reprends de zéro"),
               opt("intermediate", "Intermédiaire", "Je m'entraîne régulièrement et je connais les mouvements de base"),
               opt("advanced", "Avancé", "Je progresse lentement, je sais ce qui marche pour moi"),
               opt("elite", "Élite", "Je fais de la compétition à bon niveau")],
      factor="anciennete",
      effect="Ouvre les questions avancées (tests, compétition, points faibles) et borne les techniques servies.",
      note="Passée : le parcours reste celui d'un débutant (le plus court)."),
    q("training_age", "experience", 3, "choice", "Depuis combien de temps tu t'entraînes régulièrement ?",
      ["trainingAge"], skip=True,
      options=[opt("under_6_months", "Moins de 6 mois"), opt("months_6_to_24", "6 mois à 2 ans"),
               opt("years_2_to_5", "2 à 5 ans"), opt("over_5_years", "Plus de 5 ans")],
      koach="Sans compter les longues coupures.",
      factor="anciennete",
      effect="Volume et intensité de départ, vitesse de progression attendue, besoin de périodisation, prérequis des techniques avancées et des figures en bras tendus."),
    q("training_gap", "experience", 3, "choice", "En ce moment, tu t'entraînes ?", ["trainingGap"], skip=True,
      when=at_least("trainingAge", "trainingAge", "months_6_to_24"),
      options=[opt("none", "Oui, régulièrement"), opt("under_3_weeks", "J'ai arrêté depuis moins de 3 semaines"),
               opt("weeks_3_to_10", "J'ai arrêté depuis 3 à 10 semaines"),
               opt("over_10_weeks", "J'ai arrêté depuis plus de 10 semaines")],
      factor="interruption",
      effect="Reprise progressive après un arrêt de plus de 3 semaines ; figures à forte contrainte tendineuse reprises une étape en dessous après un mois d'arrêt.",
      note="Posée une fois, à la création ; ensuite les coupures se lisent dans le journal (`TrainingLog.breaks`, dates des séances)."),
    # --------------------------------------------------------- niveaux ----
    q("movement_levels", "niveaux", 2, "group", "Ton niveau sur quelques mouvements", ["movementLevels"], unknown=True,
      note="Fourchettes par mouvement (D3.5), « Je ne sais pas » toujours possible. Débutant : 4 mouvements au plus ; sinon 9 au plus, choisis selon les disciplines."),
    q("benchmarks", "niveaux", 3, "group", "Tu connais tes records précis ?", ["benchmarks"], skip=True, unknown=True,
      when=INTERMEDIATE,
      koach="Un chiffre exact vaut mieux qu'une fourchette : je calcule tes charges dessus. Sinon, on fera un test ensemble.",
      factor="tests_records",
      effect="Charges en part du maximum dès le premier bloc, choix des tentatives, séries de test seulement là où il manque une valeur.",
      items=[
          item("exerciseId", "Quel mouvement ?", "exercise",
               note="Proposés d'abord : mouvements de compétition de la discipline, puis ceux de `movementLevels`."),
          item("kind", "Quel genre de record ?", "choice", options=[
              opt("load_reps", "Une charge soulevée (1 répétition ou plus)"), opt("max_reps", "Un maximum de répétitions"),
              opt("max_hold", "Un maintien le plus long possible"), opt("time_trial", "Un temps sur une distance"),
              opt("distance_trial", "Une distance en un temps donné")]),
          item("externalLoadKg", "Quelle charge ? (le lest seul pour un exercice lesté)", "number"),
          item("reps", "Combien de répétitions ?", "number"),
          item("rir", "Il t'en restait combien sous le pied ?", "choice", required=False, options=[
              opt("0", "Aucune, c'était mon maximum"), opt("1", "1"), opt("2", "2"), opt("3", "3 ou plus")],
               note="Seulement pour une charge soulevée ; passée : réserve inconnue (absente)."),
          item("seconds", "Combien de temps ?", "duration"),
          item("distanceMeters", "Quelle distance ?", "number"),
          item("date", "C'était quand ?", "date", required=False,
               note="Un record de plus de 6 mois est gardé, mais le moteur le reteste avant de s'y fier."),
          item("source", "D'où vient ce chiffre ?", "choice", options=[
              opt("declared", "Je l'ai fait à l'entraînement"), opt("competition", "En compétition")]),
          item("bodyWeightKg", "Ton poids ce jour-là ?", "number", required=False,
               note="Seulement pour un exercice au poids du corps ou lesté."),
      ],
      note="« Je ne sais pas » : aucun record n'est écrit ; les tests guidés sont proposés à la première séance (§ tests guidés). Liste vide = aucun record connu."),
    q("skills", "niveaux", 3, "group", "Les figures que tu travailles", ["skills"], skip=True, when=FIGURES,
      koach="Montre-moi où tu en es sur chaque figure : je reprends juste après.",
      factor="figures",
      effect="Étape de départ de chaque progression, durées de maintien prescrites, critère de passage à l'étape suivante.",
      items=[
          item("targetExerciseId", "Quelle figure vises-tu ?", "exercise",
               note="Figures du catalogue qui ont une chaîne `variante_de` (front lever, planche, équilibre, back lever, L-sit, muscle-up, drapeau…)."),
          item("currentExerciseId", "Où en es-tu ?", "exercise",
               note="Choix parmi les étapes de la chaîne `variante_de` de la figure, de la plus facile à la figure elle-même."),
          item("bestHoldSeconds", "Ton meilleur maintien propre sur cette étape ?", "duration", required=False),
          item("bestReps", "Ou ton meilleur nombre de répétitions propres ?", "number", required=False),
      ]),
    # ------------------------------------------------------- objectifs ----
    q("goals", "objectifs", 2, "group", "Tes objectifs", ["goals"],
      note="Performance chiffrée datée, habitude, ou « Laisse Koach proposer » (D3.8) ; le premier est le principal."),
    q("events", "objectifs", 3, "group", "Une compétition ou un test daté en vue ?", ["events"], skip=True,
      when=any_of(INTERMEDIATE, is_in("goals[*].kind", "performance")),
      koach="Si tu as une date, je construis toute ta saison pour que tu arrives en forme ce jour-là.",
      factor="competition",
      effect="Plan de saison (phases, affûtage, pic de forme), travail spécifique des épreuves, tentatives le jour J.",
      items=[
          item("kind", "C'est quoi ?", "choice", options=[
              opt("strength_competition", "Compétition de force (streetlifting : une répétition, la plus lourde)"),
              opt("reps_competition", "Compétition de répétitions (sets & reps, endurance)"),
              opt("freestyle_competition", "Compétition de freestyle (figures jugées)"),
              opt("race", "Une course"), opt("other_competition", "Une autre compétition"),
              opt("personal_test", "Un test perso à une date précise")]),
          item("date", "Quel jour ?", "date"),
          item("priority", "Elle compte comment ?", "choice", options=[
              opt("main", "C'est mon objectif principal"), opt("secondary", "Importante, mais pas la principale"),
              opt("preparation", "Juste pour m'entraîner à la compétition")]),
          item("name", "Son nom ?", "text", required=False),
          item("ruleset", "Quel règlement ?", "choice", required=False,
               note="Préréglages de `rulesetPresets` (ils pré-remplissent mouvements, tentatives et sauts de charge) ou « Autre » ; tout reste modifiable."),
          item("weightClassKg", "Ta catégorie de poids ?", "number", required=False,
               note="Compétition de force ; « plus de … » coche `openWeightClass`."),
          item("lifts", "Les mouvements, dans l'ordre", "list",
               note="Compétition de force : mouvement, tentatives (3 par défaut), meilleure barre, barre visée."),
          item("mode", "Le format", "choice", options=[
              opt("max_reps", "Le plus de répétitions"), opt("max_reps_in_time", "Le plus de répétitions en un temps"),
              opt("for_time", "Un volume imposé, le plus vite possible"), opt("max_hold", "Le maintien le plus long")],
               note="Compétition de répétitions."),
          item("stations", "Les exercices, dans l'ordre", "list", required=False,
               note="Compétition de répétitions : exercice, répétitions ou durée imposées, lest, série indivisible. « Je ne connais pas encore le format » : liste d'une épreuve générique que l'utilisateur complétera."),
          item("distanceMeters", "Quelle distance ?", "number", note="Course."),
          item("targetSeconds", "Ton temps visé ?", "duration", required=False),
      ],
      note="Réponse « Non » : liste vide (aucune échéance). Passée : champ absent. Plusieurs échéances possibles ; une seule `main` conseillée par saison."),
    q("specialization", "objectifs", 3, "group", "Un mouvement, une figure ou un muscle à faire passer avant tout ?",
      ["specialization"], skip=True, when=ADVANCED,
      koach="Je peux lui donner la priorité pendant quelques semaines et entretenir le reste.",
      factor="specialisation",
      effect="Cycle de spécialisation : volume et fréquence concentrés sur la cible, reste entretenu à dose réduite.",
      items=[
          item("kind", "Quoi ?", "choice", options=[
              opt("exercise", "Un mouvement"), opt("skill", "Une figure"), opt("muscle", "Un groupe musculaire"),
              opt("pattern", "Un type de mouvement (tirage, poussée…)")]),
          item("exerciseId|muscle|pattern", "Lequel ?", "exercise"),
          item("weeks", "Pendant combien de temps ?", "choice", required=False, options=[
              opt("4", "4 semaines"), opt("8", "8 semaines"), opt("12", "12 semaines")],
               note="Passée : au moteur de la fixer."),
          item("maintenance", "Et le reste ?", "choice", required=False, options=[
              opt("maintain", "Je l'entretiens"), opt("minimal", "Le strict minimum"), opt("pause", "En pause")]),
      ]),
    q("weak_points", "objectifs", 3, "group", "Sur tes mouvements principaux, où est-ce que ça bloque ?",
      ["weakPoints"], skip=True, when=all_of(ADVANCED, STRENGTH_DISCIPLINES),
      koach="Par exemple : « je bloque en bas du dips », « je cale à la transition du muscle-up ».",
      factor="points_faibles",
      effect="Choix des exercices d'assistance (pauses, partiels, isométrie à l'angle faible). Usage d'entraîneur : aucun effet démontré sur la progression.",
      items=[
          item("exerciseId", "Quel mouvement ?", "exercise"),
          item("kind", "Où ça bloque ?", "choice", options=[
              opt("bottom", "En bas"), opt("mid_range", "Au milieu"), opt("lockout", "En fin de mouvement"),
              opt("dead_start", "Au départ arrêté"), opt("transition", "À la transition"), opt("grip", "La prise lâche"),
              opt("late_set_fatigue", "Je m'écroule en fin de série"), opt("balance", "L'équilibre"),
              opt("mobility", "La souplesse"), opt("speed", "Je manque de vitesse")]),
      ],
      note="Une douleur n'est pas un point faible : elle se déclare à l'écran Santé."),
    # --------------------------------------------------- disponibilités ----
    q("availability", "disponibilites", 2, "group", "Tes jours et ta durée par jour", ["availability"], required=True,
      note="Jours précis + durée par jour (D3.6)."),
    q("places", "lieux", 2, "multi", "Où t'entraînes-tu ?", ["places"], required=True,
      options=[opt("salle", "En salle"), opt("maison", "À la maison"), opt("exterieur", "Dehors")]),
    q("equipment", "lieux", 2, "group", "Ton matériel", ["equipment", "equipmentByPlace"], required=True,
      note="Vocabulaire de la base, regroupé, préréglages, matériel par lieu (G6)."),
    # ----------------------------------------------------- récupération ----
    q("sleep", "recuperation", 3, "choice", "En général, tu dors combien par nuit ?", ["sleep"], skip=True,
      options=[opt("under_6_hours", "Moins de 6 h"), opt("hours_6_to_7", "6 à 7 h"), opt("hours_7_plus", "7 h ou plus")],
      factor="sommeil",
      effect="Moins de 6 h : volume proche de l'échec et cardio intense dosés avec prudence, jamais de baisse de charge ; aucune promesse sur les blessures.",
      note="Valeur HABITUELLE. La nuit dernière se dit dans le bilan de séance (D5.8) : pas de doublon."),
    q("stress", "recuperation", 3, "choice", "En ce moment, ta vie hors entraînement est…", ["stress"], skip=True,
      options=[opt("low", "Plutôt tranquille"), opt("moderate", "Chargée, mais ça va"), opt("high", "Très stressante")],
      factor="stress",
      effect="Stress élevé : séances lourdes d'un même groupe plus espacées, pas de hausse de volume, décharge avancée.",
      note="Valeur des dernières semaines ; redemandée de temps en temps (`lifestyleUpdatedOn`). Le stress du jour reste dans le bilan de séance."),
    q("outside_load", "recuperation", 3, "composite", "En dehors de ce programme, ton corps travaille déjà ?",
      ["occupationalLoad", "otherSports"], skip=True,
      options=[opt("seated", "Non : je suis surtout assis"), opt("on_feet", "Je suis debout ou je marche toute la journée"),
               opt("heavy", "J'ai un métier physique (je porte, je soulève)"),
               opt("other_sport", "Je fais un autre sport régulièrement")],
      factor="charge_hors_programme",
      effect="Autre sport : séances lourdes des mêmes muscles placées à distance (au moins un jour) ; métier physique : départ prudent (choix raisonné, sans preuve directe).",
      items=[
          item("kind", "Quel sport ?", "choice", options=[
              opt("running", "Course à pied"), opt("cycling", "Vélo"), opt("swimming", "Natation"),
              opt("other_endurance", "Autre sport d'endurance"), opt("team_sport", "Sport collectif"),
              opt("combat_sport", "Sport de combat"), opt("climbing", "Escalade"), opt("racket_sport", "Sport de raquette"),
              opt("other_strength", "Autre sport de force"), opt("other", "Autre")]),
          item("sessionsPerWeek", "Combien de fois par semaine ?", "number"),
          item("minutesPerSession", "Combien de temps à chaque fois ?", "duration"),
          item("weekdays", "Toujours les mêmes jours ?", "multi", required=False),
          item("hard", "C'est intense (matchs, combats, fractionné) ?", "choice", required=False,
               options=[opt("true", "Oui"), opt("false", "Non")]),
          item("regions", "Ça fait surtout travailler…", "multi", required=False,
               options=[opt("lower_body", "Les jambes"), opt("upper_pull", "Le tirage (dos, bras)"),
                        opt("upper_push", "La poussée (épaules, pectoraux)"), opt("trunk", "Le tronc"),
                        opt("whole_body", "Tout le corps")],
               note="Seulement pour « Autre sport de force » et « Autre »."),
      ],
      note="Une seule question, plusieurs réponses possibles : une des trois premières écrit `occupationalLoad` (la première est exclusive des deux suivantes) ; « un autre sport » ouvre sur place l'éditeur d'`otherSports` ; sans cette réponse, `otherSports` est écrit vide (aucun). Passée : les deux champs restent absents."),
    q("body_weight_goal", "recuperation", 3, "choice", "Ton poids, en ce moment, tu veux…", ["bodyWeightGoal"], skip=True,
      when=any_of(INTERMEDIATE, present("streetMode")),
      options=[opt("lose", "Le faire baisser"), opt("maintain", "Le garder"), opt("gain", "Le faire monter"),
               opt("no_goal", "Je n'y pense pas")],
      factor="bilan_energetique",
      effect="En perte de poids : attentes réglées (la force peut monter, pas le muscle), volume gardé, tests moins fréquents ; lest et charge totale recalculés quand le poids change.",
      note="Aucun conseil alimentaire n'est donné. Le rythme réel se lit dans les pesées."),
    # ----------------------------------------------------------- santé ----
    q("health_screening", "sante", 2, "group", "Questionnaire santé", ["healthScreening"], required=True,
      note="Questionnaire L13 inchangé ; seule sa référence est dans le profil (aucune réponse copiée)."),
    q("limitations", "sante", 2, "group", "Une zone à ménager ?", ["limitations"],
      koach="Une ancienne blessure, une articulation sensible : dis-moi ce qui la réveille, je la protège.",
      factor="antecedents",
      effect="Mouvements qui chargent la zone : départ une variante en dessous, progression plus lente, pas de test maximal tant que la gêne est d'au moins 4/10.",
      items=[
          item("zone", "Quelle zone ?", "body_map"),
          item("side", "Quel côté ?", "choice"),
          item("discomfort", "La gêne en ce moment, de 0 à 10 ?", "slider"),
          item("since", "Depuis quand ?", "choice", required=False, options=[
              opt("under_6_weeks", "Moins de 6 semaines"), opt("weeks_6_to_12", "6 semaines à 3 mois"),
              opt("months_3_to_12", "3 mois à 1 an"), opt("over_12_months", "Plus d'un an"),
              opt("past_resolved", "C'est ancien, je ne sens plus rien")],
               note="Schéma 3."),
          item("aggravatedBy", "Qu'est-ce qui la réveille ?", "multi", required=False, options=[
              opt("pull_bent_arm", "Tirer bras fléchis (tractions, rowing)"),
              opt("hang_straight_arm", "Être suspendu ou tirer bras tendus"),
              opt("push_support", "Pousser en appui (dips, pompes)"),
              opt("straight_arm_support", "L'appui bras tendus (planche, équilibre)"),
              opt("overhead", "Les bras au-dessus de la tête"), opt("knee_flexion", "Plier les genoux (squat, fentes)"),
              opt("hip_hinge", "Se pencher en avant avec une charge"),
              opt("wrist_extension_grip", "La prise, ou le poignet en extension"), opt("rings", "Les anneaux"),
              opt("running_jumping", "Courir ou sauter")],
               note="Schéma 3."),
      ],
      note="Donnée de santé : écrite seulement avec l'accord santé (G6, KT-042). Une gêne de plus de 5/10, une douleur la nuit, une perte de force ou une aggravation sur deux semaines : Koach oriente vers un professionnel de santé, sans interpréter (règle L13)."),
    # ----------------------------------------------------- préférences ----
    q("preferences", "preferences", 2, "group", "Exercices aimés, exercices détestés",
      ["likedExerciseIds", "dislikedExerciseIds"], skip=True, when=INTERMEDIATE,
      note="Schéma 3 : masquée pour un débutant, qui dira « je n'aime pas » pendant la revue du programme (D4.5) ; toujours accessible dans Réglages › Profil."),
    q("guidance_mode", "mode", 2, "choice", "Assisté ou libre ?", ["guidanceMode"], required=True,
      options=[opt("assisted", "Assisté : Koach applique ses ajustements"), opt("free", "Libre : Koach propose, tu décides")]),
]

# Préréglages de règlement de l'éditeur d'échéance. Faits relevés le
# 02/10/2026 sur les pages officielles (lues à travers un outil de résumé :
# à relire avant d'en faire une règle du moteur) ; tout reste modifiable par
# l'utilisateur, les formats variant d'un organisateur à l'autre.
RULESET_PRESETS = [
    {"code": "final_rep_all4", "label": "Final Rep — 4 mouvements", "kind": "strength_competition",
     "lifts": [{"exerciseId": "sl-muscle-up-leste", "attempts": 3, "minIncrementKg": 1.25},
               {"exerciseId": "sl-traction-lestee", "attempts": 3, "minIncrementKg": 1.25},
               {"exerciseId": "sl-dips-leste", "attempts": 3, "minIncrementKg": 1.25},
               {"exerciseId": "sl-squat-competition", "attempts": 3, "minIncrementKg": 2.5}],
     "weightClassesKg": {"female": [52, 57, 63, 70], "male": [66, 73, 80, 87, 94, 101]},
     "source": "https://final-rep.com/weighted/about ; https://final-rep.com/rulebook/",
     "status": "Page lue le 02/10/2026 ; règlement VI26.2 non lu en entier (formule de l'indice relatif non relevée)."},
    {"code": "final_rep_2lift", "label": "Final Rep — traction et dips", "kind": "strength_competition",
     "lifts": [{"exerciseId": "sl-traction-lestee", "attempts": 3, "minIncrementKg": 1.25},
               {"exerciseId": "sl-dips-leste", "attempts": 3, "minIncrementKg": 1.25}],
     "weightClassesKg": {"female": [52, 57, 63, 70], "male": [66, 73, 80, 87, 94, 101]},
     "source": "https://final-rep.com/weighted/about", "status": "Page lue le 02/10/2026."},
    {"code": "isf_classic", "label": "ISF — Streetlifting Classic", "kind": "strength_competition",
     "lifts": [{"exerciseId": "sl-traction-lestee", "attempts": 3, "minIncrementKg": 1.25},
               {"exerciseId": "sl-dips-leste", "attempts": 3, "minIncrementKg": 1.25}],
     "source": "https://streetlifting.ru/docs/isf-rules/faq",
     "status": "FAQ de la version 5.2 lue le 02/10/2026 ; texte complet non lu (catégories non relevées)."},
    {"code": "isf_multirep", "label": "ISF — Multirep (maximum de répétitions lestées)", "kind": "reps_competition",
     "mode": "max_reps_in_time", "timeLimitSeconds": 120,
     "stations": [{"exerciseId": "sl-traction-lestee"}, {"exerciseId": "sl-dips-leste"}],
     "source": "https://streetlifting.ru/docs/isf-rules/faq",
     "status": "FAQ de la version 5.2 lue le 02/10/2026 : une tentative, 2 minutes, lest fixe ; lests par catégorie non relevés (à saisir)."},
]

# --------------------------------------------------------------------------
# Tests guidés : protocoles pour mesurer ce que l'utilisateur ne sait pas.
# `stage` : creation (déclaratif seulement), first_session (sous-maximal,
# dans la séance), later (après familiarisation). Références : PROFIL_V3.md §5.
# --------------------------------------------------------------------------
TESTS = [
    {"id": "t1_serie_lourde", "title": "Série lourde d'estimation (barre, haltères, machine)",
     "benchmarkKind": "load_reps", "testKind": "amrap_estimate", "stage": "first_session",
     "eligible": HEALTH_STANDARD,
     "forWhom": "Toute personne qui sait exécuter le mouvement ; test par défaut pour un mouvement chargé dont le maximum est inconnu.",
     "safety": ["Barres de sécurité ou pareur au squat et au développé couché.",
                "Arrêt dès que la technique se dégrade."],
     "steps": ["Échauffement général de 5 minutes.",
               "Barre à vide × 8, puis environ 50 % de la charge visée × 5, 70 % × 3, 85 % × 1.",
               "Repos de 2 à 3 minutes.",
               "Série test : une charge que tu penses pouvoir soulever 5 fois ; arrête-toi en gardant 1 à 2 répétitions sous le pied."],
     "stop": ["1 à 2 répétitions en réserve, ou la barre ralentit nettement, ou la technique se dégrade.",
              "Série valable de 3 à 6 répétitions ; de 7 à 10, valeur gardée avec une incertitude plus large ; au-delà de 10, une seule reprise plus lourde après 3 à 5 minutes."],
     "conversion": {"formula": "brzycki", "function": "estimateOneRm",
                    "text": "r = répétitions + réserve déclarée ; 1RM = charge × 36 / (37 − r). Refusé au-delà de r = 10."},
     "uncertainty": "±5 % (série au maximum, 2 à 6 répétitions) ; ±7,5 % (réserve déclarée, ou 7 à 10 répétitions) ; ±10 % et valeur « provisoire » avant 6 mois de pratique.",
     "refs": ["brzycki1993", "nuzzo2024", "reynolds2006", "mayhew2008", "halperin2022", "steele2017"]},
    {"id": "t2_leste", "title": "Série lourde d'estimation lestée (traction, dips)",
     "benchmarkKind": "load_reps", "testKind": "amrap_estimate", "stage": "first_session",
     "eligible": all_of(HEALTH_STANDARD, present("bodyWeightKg")),
     "forWhom": "Personne capable d'au moins 8 répétitions strictes au poids du corps. Pas pour le muscle-up lesté (mouvement technique : aucune estimation par équation).",
     "safety": ["Ceinture de lest fermée, descente contrôlée, pas de lâcher en bas des dips.", "Épaules et coudes échauffés."],
     "steps": ["Pesée du jour.", "5 répétitions au poids du corps, 3 répétitions à la moitié du lest visé, 1 répétition au lest visé moins 5 kg.",
               "Repos de 3 minutes.", "Série test visant 3 à 6 répétitions, arrêtée avec 1 répétition sous le pied."],
     "stop": ["1 répétition en réserve, ou première répétition hors amplitude (menton sous la barre ; épaule au-dessus du coude en bas des dips)."],
     "conversion": {"formula": "brzycki_total", "function": "estimateOneRm + externalFromTotal",
                    "text": "Charge totale = lest + fraction du poids du corps × poids du jour ; 1RM total par Brzycki ; lest maximal = 1RM total − fraction × poids."},
     "uncertainty": "±5 à ±7,5 % de la charge TOTALE, soit souvent ±15 à ±20 % du lest : la fourchette est affichée en kilos de lest. Extrapolation : aucune étude ne valide l'équation sur ces mouvements.",
     "refs": ["brzycki1993", "ortega2021", "coyne2015", "nuzzo2024"]},
    {"id": "t3_max_direct", "title": "Maximum direct (1 répétition)",
     "benchmarkKind": "load_reps", "testKind": "one_rm", "stage": "later",
     "eligible": all_of(HEALTH_STANDARD, INTERMEDIATE, at_least("trainingAge", "trainingAge", "months_6_to_24"),
                        any_of(not_(age_at_least(65)), at_least("trainingAge", "trainingAge", "years_2_to_5"))),
     "forWhom": "Pratiquant confirmé du mouvement (plus de 6 mois), questionnaire santé sans réserve ; jamais après 65 ans sans au moins 2 ans de pratique. Seul test proposé pour le muscle-up lesté.",
     "safety": ["Pareur ou sécurités ; ceinture fermée.", "5 essais au plus ; aucune tentative après un échec technique.",
                "Jamais sur une zone dont la gêne est d'au moins 4/10."],
     "steps": ["5 à 10 répétitions légères ; repos 1 minute.", "+5 à 10 % × 3 à 5 répétitions ; repos 2 minutes.",
               "+5 à 10 % × 2 à 3 répétitions ; repos 2 à 4 minutes.",
               "Essais d'une répétition : +5 à 10 % après une réussite, −2,5 à 5 % après un échec ; repos 2 à 4 minutes entre les essais."],
     "stop": ["Échec, défaut technique, ou 5 essais.", "Le maximum est trouvé en 3 à 5 essais."],
     "conversion": {"formula": "none", "text": "La meilleure charge réussie est le maximum (réserve 0, 1 répétition)."},
     "uncertainty": "±4 % d'un jour à l'autre (coefficient de variation médian du test de 1RM).",
     "refs": ["grgic2020", "nsca2016", "pollock1991", "seo2012"]},
    {"id": "t4_reps_max", "title": "Répétitions max au poids du corps (traction, dips, pompes)",
     "benchmarkKind": "max_reps", "testKind": "max_reps", "stage": "first_session", "eligible": HEALTH_STANDARD,
     "forWhom": "Tous ; qui ne fait aucune répétition passe sur une variante plus facile ou sur un maintien (test suivant).",
     "safety": ["Échauffement ; une seule série test par mouvement et par séance."],
     "steps": ["2 séries d'échauffement à environ un tiers du nombre attendu.", "Repos de 3 minutes.",
               "Série maximale, amplitude complète, sans élan."],
     "stop": ["Première répétition hors amplitude, ou pause de plus de 3 secondes.",
              "Débutant : arrêt quand la technique se dégrade, sans aller à l'échec."],
     "conversion": {"formula": "none", "text": "Valeur brute. Aucune conversion en maximum lesté au-delà de 10 répétitions."},
     "uncertainty": "±1 répétition jusqu'à 10, ±2 au-delà (traction, dips) ; pompes : un écart de moins de 4 à 5 répétitions entre deux tests ne prouve pas un changement.",
     "refs": ["kardor2023", "sanchezmoreno2017", "mitter2022"]},
    {"id": "t5_maintien_max", "title": "Maintien max (suspension, gainage, L-sit, étape de figure)",
     "benchmarkKind": "max_hold", "testKind": "max_hold", "stage": "first_session", "eligible": HEALTH_STANDARD,
     "forWhom": "Tous, sur l'étape de progression tenue proprement au moins 5 secondes.",
     "safety": ["Poignets et épaules échauffés ; sortie contrôlée.", "Tapis sous les figures en appui renversé ou en suspension."],
     "steps": ["2 maintiens courts d'échauffement (environ un tiers du temps attendu).", "Repos de 2 à 3 minutes.",
               "Un seul maintien maximal chronométré."],
     "stop": ["Perte de la forme (hanches qui tombent, bras qui fléchissent), pas la chute."],
     "conversion": {"formula": "none",
                    "text": "Valeur brute. Les durées de travail en sont une part (60 à 70 % : usage d'entraîneur, réglé par les moteurs)."},
     "uncertainty": "±5 à 10 % pour un maintien long (gainage) ; ±1 à 2 secondes pour un maintien court de figure (estimation : aucune étude de fiabilité sur les figures).",
     "refs": ["rodriguezperea2025", "martinezromero2020", "low2016"]},
    {"id": "t6_course_6min", "title": "Course : test de 6 minutes",
     "benchmarkKind": "distance_trial", "testKind": "distance_trial", "stage": "later", "eligible": HEALTH_STANDARD,
     "forWhom": "Personne capable de courir 10 minutes sans s'arrêter.",
     "safety": ["Terrain plat, pas de forte chaleur.", "Échauffement de 10 à 15 minutes et 3 accélérations.",
                "Arrêt immédiat en cas de douleur dans la poitrine, de vertige ou d'essoufflement anormal."],
     "steps": ["Courir la plus grande distance possible en 6 minutes, à allure régulière (première minute prudente)."],
     "stop": ["Fin du chronomètre ; un arrêt avant la fin invalide le test (à refaire un autre jour)."],
     "conversion": {"formula": "speed", "function": "trialSpeed",
                    "text": "Vitesse moyenne = distance / 360 s ; les allures d'entraînement en sont des parts (`speed_fraction`)."},
     "uncertainty": "±5 à 8 % sur la vitesse (estimation ; aucune étude de validation lue).",
     "refs": ["mayorgavega2016", "cooper1968"]},
    {"id": "t7_course_chrono", "title": "Course : contre-la-montre de 3 ou 5 km",
     "benchmarkKind": "time_trial", "testKind": "time_trial", "stage": "later",
     "eligible": all_of(HEALTH_STANDARD, INTERMEDIATE),
     "forWhom": "Coureur régulier (30 minutes en continu) ; 3 km pour les moins aguerris.",
     "safety": ["Comme le test de 6 minutes.", "Échauffement de 15 minutes."],
     "steps": ["Distance fixe au meilleur temps, à allure régulière."],
     "stop": ["Distance terminée."],
     "conversion": {"formula": "riegel", "function": "riegelSeconds",
                    "text": "Temps prédit sur une autre distance = temps × (distance voulue / distance du test)^1,06, jusqu'au semi-marathon."},
     "uncertainty": "±2 à 3 % sur le temps du test (coureurs entraînés), davantage chez un coureur qui gère mal son allure ; au-delà du semi-marathon la formule est trop optimiste : aucune prédiction.",
     "refs": ["laursen2007", "riegel1981", "vickers2016"]},
    {"id": "t8_sans_test", "title": "Sans test : calage au fil des séances",
     "benchmarkKind": None, "testKind": None, "stage": "creation",
     "eligible": not_(HEALTH_STANDARD),
     "forWhom": "Questionnaire santé en mode prudent ou sans réponse ; débutant complet qui ne veut pas de test.",
     "safety": ["Aucun effort maximal."],
     "steps": ["Charges de départ prudentes choisies par le moteur (D4.7).",
               "Calage en 2 à 3 séances d'après les répétitions faites et les flammes (D3.5).",
               "Course : allure de conversation."],
     "stop": [],
     "conversion": {"formula": "none", "text": "Aucune valeur n'est écrite dans le profil ; les estimations du moteur dynamique font foi."},
     "uncertainty": "Valeur « non mesurée » ; un premier test est proposé après 3 à 4 séances de familiarisation si le questionnaire santé le permet.",
     "refs": ["ploutzsnyder2001"]},
]
