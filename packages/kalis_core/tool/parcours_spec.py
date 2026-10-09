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

Deux conditions facultatives par question : `deferWhen` (la question n'est
pas posée à la création mais proposée après la première semaine) et
`requiredWhen` (la réponse devient obligatoire).
"""
from __future__ import annotations

VERSION = "0.4.3"

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
BEGINNER_PATH = not_(INTERMEDIATE)  # débutant, ou niveau non renseigné
FIGURES = any_of(discipline("calisthenics", "streetlifting", "crossfit"), min_number("streetMode.calisthenicsPct", 1))
BODYWEIGHT_DISCIPLINES = any_of(present("streetMode"), discipline("streetlifting", "street_workout", "calisthenics"))
STRENGTH_DISCIPLINES = discipline("streetlifting", "street_workout", "calisthenics", "musculation", "crossfit")
HEALTH_STANDARD = is_in("healthScreening.outcome", "standard")

SCREENS = [
    {"id": "accueil", "title": "Bienvenue", "since": 2,
     "koach": "Salut ! Quelques minutes de questions et je te prépare un programme à ta mesure.",
     "note": "Accueil de Koach et avertissement santé L13 (inchangés)."},
    {"id": "toi", "title": "Toi", "since": 2, "koach": "On commence par toi."},
    {"id": "discipline", "title": "Ta discipline", "since": 2, "koach": "Qu'est-ce qui te fait envie ?"},
    {"id": "dosage", "title": "Le reste du programme", "since": 2,
     "koach": "Choisis une ou deux autres activités à ajouter, et la place que tu leur donnes."},
    {"id": "experience", "title": "Ton expérience", "since": 2,
     "koach": "Dis-moi d'où tu pars : je règle la difficulté dessus."},
    {"id": "niveaux", "title": "Ce que tu sais faire", "since": 2,
     "koach": "Donne-moi une idée, même vague. Si tu ne sais pas, pas d'examen : on verra tranquillement pendant tes premières séances."},
    {"id": "objectifs", "title": "Tes objectifs", "since": 2, "koach": "Où veux-tu aller ?"},
    {"id": "disponibilites", "title": "Tes disponibilités", "since": 2, "koach": "Quels jours, et combien de temps ?"},
    {"id": "lieux", "title": "Lieux et matériel", "since": 2, "koach": "Où t'entraînes-tu, et avec quoi ?"},
    {"id": "recuperation", "title": "Ta récupération", "since": 3,
     "koach": "Ton corps récupère aussi en dehors des séances. Quelques questions rapides.",
     "note": "Nouvel écran (schéma 3). Les trois premières questions tiennent sur un écran ; chacune a « Passer ». Pour un débutant, cet écran n'est pas montré à la création : ses questions (les quatre portent `deferWhen`) sont proposées après la première semaine."},
    {"id": "sante", "title": "Ta santé", "since": 2, "koach": "Parlons de ta santé : ce que tu me dis ici me sert à te protéger.",
     "note": "Questionnaire santé L13 inchangé ; les gênes sont des contraintes d'entraînement, jamais un diagnostic."},
    {"id": "preferences", "title": "Tes préférences", "since": 2, "koach": "Des exercices que tu adores, ou pas du tout ?"},
    {"id": "mode", "title": "Assisté ou libre", "since": 2,
     "koach": "Si une séance se passe mal ou trop bien, j'adapte la suite. Tu préfères que je le fasse tout seul, ou que je te demande ?"},
    {"id": "recap", "title": "Récapitulatif", "since": 2, "koach": "Tout est bon ? Tu peux tout modifier."},
]


def opt(code, label, hint=None):
    o = {"code": code, "label": label}
    if hint:
        o["hint"] = hint
    return o


def q(id, screen, since, kind, text, fields, *, when=ALWAYS, required=False, skip=False, unknown=False,
      options=None, koach=None, factor=None, effect=None, items=None, note=None, validation=None,
      defer_when=None, required_when=None):
    out = {"id": id, "screen": screen, "since": since, "kind": kind, "text": text, "fields": fields,
           "required": required, "skip": skip, "unknown": unknown, "when": when}
    for k, v in (("deferWhen", defer_when), ("requiredWhen", required_when), ("options", options), ("koach", koach),
                 ("factor", factor), ("effect", effect), ("items", items), ("note", note), ("validation", validation)):
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
      koach="Ça ne change pas ton programme : ça sert aux repères de classement et aux catégories de compétition.",
      factor="sexe",
      effect="Aucun effet sur le programme (mêmes volumes relatifs) ; sert aux repères de rang et aux catégories de compétition. « Je préfère ne pas le dire » : l'éditeur d'échéance propose les catégories des deux listes."),
    q("birth_year", "toi", 2, "number", "Ton année de naissance ?", ["birthYear"], required=True,
      validation="18 ans et plus (règle L13).", factor="age",
      koach="Il faut avoir 18 ans. Ton âge me sert aussi à rester prudent sur les tests.",
      effect="Prudence des tests (pas de maximum direct après 65 ans sans expérience) ; attentes de progression."),
    q("height", "toi", 2, "number", "Ta taille, en cm ?", ["heightCm"], required=True, validation="100 à 250 cm.",
      factor="taille", effect="Aucun effet sur le programme ; champ obligatoire du schéma 2, gardé."),
    q("body_weight", "toi", 2, "number", "Ton poids, en kg ?", ["bodyWeightKg"], skip=True, validation="25 à 300 kg.",
      required_when=BODYWEIGHT_DISCIPLINES,
      koach="Aux pompes ou aux tractions, c'est ton propre poids que tu soulèves. Si je le connais, je dose mieux. Personne d'autre ne le voit.",
      factor="poids_de_corps",
      effect="Charge totale des exercices au poids du corps ou lestés, force relative, catégories de poids.",
      note="Obligatoire en mode street, en streetlifting, en street workout et en calisthénie (`requiredWhen`) : sans lui, ni charge totale, ni pourcentage, ni test lesté. Passable ailleurs, avec un bouton « Passer » aussi visible que « Valider »."),
    # ------------------------------------------------------ discipline ----
    q("discipline", "discipline", 2, "group", "Tu veux faire quoi, surtout ?",
      ["disciplines.primary", "streetMode"], required=True,
      note="8 disciplines (D3.1) ou mode street : principale parmi streetlifting, sets & reps, calisthénie (D3.3). Une ligne d'explication en mots courants sous chaque choix (« Calisthénie : des exercices avec le poids de ton corps », « Musculation : des charges, en salle ou à la maison »…). Le mode street est rangé à part, sous « Je pratique déjà le street workout ». Dernier choix : « Je ne sais pas, choisis pour moi », qui sélectionne la forme générale (`general_fitness`) — une réponse est bien écrite, modifiable ensuite."),
    q("secondaries", "dosage", 2, "group", "Une ou deux disciplines en plus, et leur dosage",
      ["disciplines.secondaries", "disciplines.primaryPct"], required=True,
      note="1 à 2 secondaires, somme 100 % (D3.2) ; en mode street, le dosage des deux autres styles."),
    # ------------------------------------------------------ expérience ----
    q("experience_level", "experience", 2, "choice", "Globalement, tu te situes où ?", ["experience"], skip=True,
      options=[opt("beginner", "Débutant", "Je découvre, ou presque"),
               opt("intermediate", "Intermédiaire", "Je connais les mouvements de base et je me suis entraîné régulièrement, même si j'ai arrêté un moment"),
               opt("advanced", "Avancé", "Je progresse lentement, je sais ce qui marche pour moi"),
               opt("elite", "Élite", "Je fais de la compétition au niveau national ou au-dessus")],
      factor="anciennete",
      effect="Ouvre les questions avancées (tests, compétition, points faibles) et borne les techniques servies.",
      note="Un ancien pratiquant qui reprend après un long arrêt ne se dit pas débutant : il choisit son niveau d'avant, et la question `training_gap` dit depuis quand il a arrêté (ses tendons, eux, repartent de plus bas). Passée : le parcours reste celui d'un débutant (le plus court). Le moteur recale ensuite le niveau sur les performances (force rapportée au poids de corps) : le dire au récapitulatif."),
    q("training_age", "experience", 3, "choice", "Depuis combien de temps tu pratiques régulièrement ta discipline principale ?",
      ["trainingAge"], skip=True, when=INTERMEDIATE,
      options=[opt("under_6_months", "Moins de 6 mois"), opt("months_6_to_24", "6 mois à 2 ans"),
               opt("years_2_to_5", "2 à 5 ans"), opt("over_5_years", "Plus de 5 ans")],
      koach="Ne compte pas les périodes où tu as arrêté plusieurs mois.",
      factor="anciennete",
      effect="Volume et intensité de départ, vitesse de progression attendue, besoin de périodisation, prérequis des techniques avancées et des figures en bras tendus.",
      note="L'ancienneté est celle de la discipline principale (un haltérophile qui commence la planche est récent en bras tendus). Non posée à un débutant : « je découvre » le dit déjà."),
    q("training_gap", "experience", 3, "choice", "En ce moment, tu t'entraînes ?", ["trainingGap"], skip=True,
      when=at_least("trainingAge", "trainingAge", "months_6_to_24"),
      options=[opt("none", "Oui, régulièrement"), opt("reduced", "Oui, mais en allégé depuis quelques semaines"),
               opt("under_3_weeks", "J'ai arrêté depuis moins de 3 semaines"),
               opt("weeks_3_to_10", "J'ai arrêté depuis 3 à 10 semaines"),
               opt("weeks_10_to_26", "J'ai arrêté depuis 10 semaines à 6 mois"),
               opt("months_6_to_24", "J'ai arrêté depuis 6 mois à 2 ans"),
               opt("over_2_years", "J'ai arrêté depuis plus de 2 ans")],
      factor="interruption",
      effect="Reprise progressive après un arrêt de plus de 3 semaines, d'autant plus longue que l'arrêt l'a été ; figures à forte contrainte tendineuse reprises une étape en dessous après un mois d'arrêt.",
      note="Posée une fois, à la création ; ensuite les coupures se lisent dans le journal (`TrainingLog.breaks`, dates des séances)."),
    # --------------------------------------------------------- niveaux ----
    q("benchmarks", "niveaux", 3, "group", "Tes meilleures performances récentes", ["benchmarks"], skip=True, unknown=True,
      when=INTERMEDIATE,
      koach="Un chiffre exact et récent (3 derniers mois de préférence) vaut mieux qu'une fourchette : je calcule tes charges dessus. Sinon, on fera un test ensemble.",
      factor="tests_records",
      effect="Charges en part du maximum dès le premier bloc, choix des tentatives, séries de test seulement là où il manque une valeur.",
      items=[
          item("exerciseId", "Quel mouvement ?", "exercise",
               note="Proposés d'abord : mouvements de compétition de la discipline, puis ses mouvements principaux ; quand le cardio est la discipline principale, la course d'abord (record en `time_trial`)."),
          item("kind", "Quel genre de record ?", "choice", options=[
              opt("load_reps", "Une charge soulevée (1 répétition ou plus)"), opt("max_reps", "Un maximum de répétitions"),
              opt("max_hold", "Un maintien le plus long possible"), opt("time_trial", "Un temps sur une distance"),
              opt("distance_trial", "Une distance en un temps donné"),
              opt("reps_for_time", "Un volume imposé, le plus vite possible")]),
          item("externalLoadKg", "Quelle charge ? (le lest seul pour un exercice lesté)", "number"),
          item("reps", "Combien de répétitions ?", "number"),
          item("rir", "Il t'en restait combien sous le pied ?", "choice", required=False, options=[
              opt("0", "Aucune, c'était mon maximum"), opt("1", "1"), opt("2", "2"), opt("3", "3 ou plus")],
               note="Seulement pour une charge soulevée ; passée : réserve inconnue (absente)."),
          item("seconds", "Combien de temps ?", "duration"),
          item("distanceMeters", "Quelle distance ?", "number"),
          item("date", "C'était quand ?", "date", required=False,
               note="Raccourcis de saisie : « ce mois-ci », « il y a 1 à 3 mois », ou une date. Sans date, ou à plus de 6 mois : le record est gardé, mais le moteur le reteste avant de s'y fier. Aucune date n'est inventée : un record plus ancien se saisit avec son mois."),
          item("source", "D'où vient ce chiffre ?", "choice", options=[
              opt("declared", "Je l'ai fait à l'entraînement"), opt("competition", "En compétition")]),
          item("bodyWeightKg", "Ton poids ce jour-là ?", "number", required=False,
               note="Seulement pour un exercice au poids du corps ou lesté ; pré-rempli avec le poids du profil, à confirmer."),
          item("competitionStandard", "C'était au standard de compétition (amplitude complète, arrêts marqués) ?", "choice",
               required=False, options=[opt("true", "Oui"), opt("false", "Non")],
               note="Seulement en streetlifting ou si une compétition de force est déclarée ; « Je ne sais pas » laisse le champ absent. Les tentatives ne se fondent que sur des records au standard."),
      ],
      note="Placée AVANT les fourchettes : les fourchettes (`movement_levels`) ne sont ensuite demandées que pour les mouvements sans record. « Je ne sais pas » : aucun record n'est écrit ; les tests guidés sont proposés (§ tests guidés). Liste vide = aucun record connu. Une barre unique « avec de la réserve » sert aux charges d'entraînement, pas au choix des tentatives."),
    q("movement_levels", "niveaux", 2, "group", "Ce que tu fais aujourd'hui sur quelques mouvements", ["movementLevels"], unknown=True,
      note="Fourchettes par mouvement (D3.5). Un seul bouton « Je ne sais pas, on verra ensemble » pour tout l'écran, en haut. Débutant : 4 mouvements au plus ; sinon 9 au plus, choisis selon les disciplines, sans ceux qui ont déjà un record."),
    q("skills", "niveaux", 3, "group", "Les figures que tu travailles", ["skills"], skip=True, when=FIGURES,
      koach="Montre-moi où tu en es sur chaque figure : je reprends juste après.",
      factor="figures",
      effect="Étape de départ de chaque progression, durées de maintien prescrites, critère de passage à l'étape suivante.",
      items=[
          item("targetExerciseId", "Quelle figure vises-tu ?", "exercise",
               note="Figures du catalogue qui ont une chaîne `variante_de` (front lever, planche, équilibre, back lever, L-sit, muscle-up, drapeau…)."),
          item("currentExerciseId", "Où en es-tu ?", "exercise",
               note="Choix parmi les étapes de la chaîne `variante_de` de la figure, dans l'ordre de la base, puis la figure elle-même."),
          item("bestHoldSeconds", "Ton meilleur maintien propre sur cette étape ?", "duration", required=False),
          item("bestReps", "Ou ton meilleur nombre de répétitions propres ?", "number", required=False),
          item("atStepSince", "Depuis quand tu en es là ?", "choice", required=False, options=[
              opt("under_1_month", "Moins d'un mois"), opt("months_1_to_3", "1 à 3 mois"),
              opt("months_3_to_6", "3 à 6 mois"), opt("over_6_months", "Plus de 6 mois")],
               note="Évite de te faire repartir de zéro sur une étape que tu tiens depuis longtemps ; plus de 6 mois : la méthode change."),
      ],
      note="L'ordre de la liste est l'ordre de priorité (« fais glisser la plus importante en haut »). Étapes proposées : `Catalog.progressionCandidates` (variantes de la figure dans l'ordre de la base, puis la figure). Posée aussi en streetlifting et en CrossFit (muscle-up, équilibre, L-sit proposés d'abord)."),
    q("recent_training", "niveaux", 3, "group", "En ce moment, tu fais quoi ?", ["recentTraining", "currentPhase"],
      skip=True, when=ADVANCED,
      koach="Je cale ton premier bloc sur ce que tu fais vraiment aujourd'hui : ni semaine trop facile, ni marche trop haute.",
      factor="charge_actuelle",
      effect="Volume et fréquence du premier bloc par mouvement (ni décharge involontaire, ni saut de charge) ; exposition actuelle des coudes et des épaules aux bras tendus.",
      items=[
          item("exerciseId", "Mouvement ou figure", "exercise",
               note="3 à 4 lignes pré-remplies : mouvements des records saisis (`benchmarks`), mouvements de compétition ou principaux de la discipline, figures saisies juste avant (`skills`)."),
          item("sessionsPerWeek", "Combien de fois par semaine tu le travailles ?", "choice", options=[
              opt("0", "Pas en ce moment"), opt("1", "1"), opt("2", "2"), opt("3", "3"), opt("4", "4 ou plus")]),
          item("hardSets", "Combien de séries dures par semaine (à 3 répétitions ou moins de l'échec) ?", "choice",
               required=False, options=[
                   opt("under_5", "Moins de 5"), opt("sets_5_to_9", "5 à 9"), opt("sets_10_to_14", "10 à 14"),
                   opt("sets_15_to_20", "15 à 20"), opt("over_20", "Plus de 20")]),
          item("currentPhase", "En ce moment, tu es plutôt…", "choice", required=False, options=[
              opt("volume", "En volume"), opt("heavy", "En lourd"),
              opt("post_peak", "Je sors d'un pic ou d'une compétition"), opt("unstructured", "Sans structure")],
               note="Une seule fois pour tout l'écran : écrit `currentPhase`."),
      ],
      note="« 4 ou plus » écrit 4. Ces réponses datent : elles portent `lifestyleUpdatedOn`, et le journal les remplace dès les premières semaines. Dernière question de l'écran, après les records et les figures, pour que ses lignes soient pré-remplies avec eux."),
    # ------------------------------------------------------- objectifs ----
    q("goals", "objectifs", 2, "group", "Tes objectifs", ["goals"],
      note="« Laisse Koach proposer » (D3.8) en premier, présélectionné pour un débutant : l'écran se valide en un appui. Puis « M'entraîner régulièrement » (habitude) et « J'ai un chiffre en tête (ex. 10 pompes) » (performance chiffrée datée). Le premier objectif est le principal."),
    q("emphasis", "objectifs", 3, "choice", "En musculation, tu cherches surtout…", ["emphasis"], skip=True,
      when=discipline("musculation"),
      options=[opt("muscle", "Du muscle"), opt("strength", "De la force"), opt("both", "Les deux")],
      factor="orientation",
      effect="Plages de répétitions, proximité de l'échec et répartition du volume des séances de musculation.",
      note="Un objectif du profil est une performance chiffrée ou une habitude : « prendre du muscle » se dit ici. À partir du niveau intermédiaire, la question suivante (`specialization`) permet de nommer une zone à développer en priorité."),
    q("events", "objectifs", 3, "group", "Une date en vue (compétition, course, test) ?", ["events"], skip=True,
      when=any_of(INTERMEDIATE, is_in("goals[*].kind", "performance"), discipline("cardio")),
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
          item("date", "Quel jour ?", "date",
               note="Date pas encore fixée : choisir un mois, `dateApproximate: true` et le 15 du mois."),
          item("priority", "Elle compte comment ?", "choice", options=[
              opt("main", "C'est mon objectif principal"), opt("secondary", "Importante, mais pas la principale"),
              opt("preparation", "Juste pour m'entraîner à la compétition")]),
          item("name", "Son nom ?", "text", required=False),
          item("ruleset", "Quel règlement ?", "choice", required=False,
               note="Préréglages de `rulesetPresets` (ils pré-remplissent mouvements, tentatives et sauts de charge) ou « Autre » ; tout reste modifiable."),
          item("weightClassKg", "Ta catégorie de poids ?", "number", required=False,
               note="Compétition de force ; « plus de … » coche `openWeightClass`. Les préréglages listent les catégories des deux sexes quand le sexe n'est pas renseigné."),
          item("plannedBodyWeightKg", "Tu comptes peser combien ce jour-là ?", "number", required=False,
               note="Compétition à catégories de poids (force, répétitions lestées) ; pré-rempli avec le poids du profil. Aucune question sur la méthode."),
          item("lifts", "Les mouvements, dans l'ordre", "list",
               note="Compétition de force : mouvement, tentatives (3 par défaut), meilleure barre, barre visée."),
          item("mode", "Le format", "choice", options=[
              opt("max_reps", "Le plus de répétitions"), opt("max_reps_in_time", "Le plus de répétitions en un temps"),
              opt("for_time", "Un volume imposé, le plus vite possible"), opt("max_hold", "Le maintien le plus long")],
               note="Compétition de répétitions."),
          item("stations", "Les exercices, dans l'ordre", "list", required=False,
               note="Compétition de répétitions : exercice, répétitions ou durée imposées, lest, série indivisible, limite de temps et repos imposé du poste. « Le format sera annoncé le jour même » : `formatKnown: false`, aucune liste (préparation générale)."),
          item("heats", "Combien de passages dans la journée ?", "number", required=False,
               note="Tableau à élimination, manches ; avec le repos attendu entre deux passages (`restBetweenHeatsSeconds`)."),
          item("bestSeconds|bestTotalReps", "Tu l'as déjà fait ? Ton meilleur résultat", "duration", required=False,
               note="Épreuve de répétitions, test perso, course : meilleur temps ou meilleur total de répétitions, et sa date (`bestDate`)."),
          item("distanceMeters", "Quelle distance ?", "number", note="Course."),
          item("targetSeconds", "Ton temps visé ?", "duration", required=False),
          item("elements", "Les figures que tu veux présenter", "list", required=False, note="Freestyle."),
      ],
      note="Réponse « Non » : liste vide (aucune échéance). Passée : champ absent. Plusieurs échéances possibles ; une seule `main` conseillée par saison."),
    q("specialization", "objectifs", 3, "group", "Un mouvement, une figure ou un muscle à faire passer avant tout ?",
      ["specialization"], skip=True, when=any_of(ADVANCED, all_of(INTERMEDIATE, discipline("musculation"))),
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
      ],
      note="Une seule cible. S'il existe une échéance principale, la question devient « Lequel de tes mouvements de compétition est le plus en retard ? », le reste est forcément entretenu (`maintain`) et la priorité n'est servie que loin de l'échéance (phase d'accumulation) : le plan de saison prime. En musculation, dès le niveau intermédiaire, elle se présente comme « Une zone à développer en priorité ? » (groupe musculaire)."),
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
      note="Posée après les records, sur les mouvements saisis. Les réponses sont filtrées et libellées par mouvement (traction : « au départ, bras tendus », « à mi-hauteur », « en haut, le menton ne passe pas », « la prise lâche » ; muscle-up : « tirage pas assez haut », « transition », « sortie en dips ») ; les codes ne changent pas. Une douleur n'est pas un point faible : elle se déclare à l'écran Santé."),
    q("running_base", "objectifs", 3, "group", "Ces 4 dernières semaines, tu cours combien ?", ["enduranceBase"], skip=True,
      when=any_of(discipline("cardio"), is_in("events[*].kind", "race")),
      factor="base_endurance",
      effect="Distance hebdomadaire et sortie longue du premier bloc de course : on repart de ce qui est fait, pas de ce qui est possible.",
      items=[
          item("weeklyVolume", "Par semaine, en tout", "choice", options=[
              opt("none", "Je ne cours pas encore"), opt("under_10_km", "Moins de 10 km"), opt("km_10_to_20", "10 à 20 km"),
              opt("km_20_to_35", "20 à 35 km"), opt("km_35_to_50", "35 à 50 km"), opt("over_50_km", "Plus de 50 km")]),
          item("sessionsPerWeek", "Combien de sorties par semaine ?", "choice", options=[
              opt("0", "Aucune"), opt("1", "1"), opt("2", "2"), opt("3", "3"), opt("4", "4 ou plus")]),
          item("longRun", "Ta plus longue sortie récente ?", "choice", required=False, options=[
              opt("under_30_min", "Moins de 30 min"), opt("min_30_to_60", "30 à 60 min"),
              opt("min_60_to_90", "60 à 90 min"), opt("over_90_min", "Plus de 90 min")]),
      ]),
    # --------------------------------------------------- disponibilités ----
    q("availability", "disponibilites", 2, "group", "Tes jours et ta durée par jour", ["availability"], required=True,
      note="Jours précis + durée par jour (D3.6)."),
    q("places", "lieux", 2, "multi", "Où t'entraînes-tu ?", ["places"], required=True,
      options=[opt("salle", "En salle"), opt("maison", "À la maison"), opt("exterieur", "Dehors")]),
    q("equipment", "lieux", 2, "group", "Ton matériel", ["equipment", "equipmentByPlace"], required=True,
      note="Vocabulaire de la base, regroupé, préréglages, matériel par lieu (G6). Premier bouton : « Rien du tout », qui valide l'écran en un appui (liste vide)."),
    # ----------------------------------------------------- récupération ----
    q("sleep", "recuperation", 3, "choice", "En général, tu dors combien par nuit ?", ["sleep"], skip=True,
      defer_when=BEGINNER_PATH, koach="Si tu dors peu, je dose plus doucement.",
      options=[opt("under_6_hours", "Moins de 6 h"), opt("hours_6_to_7", "Entre 6 et 7 h"), opt("hours_7_plus", "Plus de 7 h")],
      factor="sommeil",
      effect="Moins de 6 h : volume proche de l'échec et cardio intense dosés avec prudence, jamais de baisse de charge ; aucune promesse sur les blessures.",
      note="Valeur HABITUELLE, qui sert de valeur de départ. La nuit dernière se dit dans le bilan de séance (D5.8) : pas de doublon. « Plus de 7 h » comprend 7 h juste."),
    q("stress", "recuperation", 3, "choice", "En ce moment, tu es stressé ?", ["stress"], skip=True,
      defer_when=BEGINNER_PATH, koach="Si tu es très stressé, j'espace un peu plus les séances dures.",
      options=[opt("low", "Pas vraiment"), opt("moderate", "Un peu"), opt("high", "Beaucoup")],
      factor="stress",
      effect="Stress élevé : séances lourdes d'un même groupe plus espacées, pas de hausse de volume, décharge avancée.",
      note="Valeur des dernières semaines ; redemandée de temps en temps (`lifestyleUpdatedOn`). Le stress du jour reste dans le bilan de séance."),
    q("outside_load", "recuperation", 3, "composite", "Tes journées, c'est plutôt…",
      ["occupationalLoad", "otherSports"], skip=True, defer_when=BEGINNER_PATH,
      options=[opt("seated", "Surtout assis"), opt("on_feet", "Debout ou en mouvement (ou un peu des deux)"),
               opt("heavy", "Physiques : je porte, je soulève"),
               opt("other_sport", "Et je fais déjà un autre sport, en dehors de ce programme")],
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
          item("mainSport", "C'est ton sport principal ?", "choice", required=False,
               options=[opt("true", "Oui"), opt("false", "Non")],
               note="Si oui : pas de séance lourde des régions concernées la veille de ce sport."),
          item("regions", "Ça fait surtout travailler…", "multi", required=False,
               options=[opt("lower_body", "Les jambes"), opt("upper_pull", "Le tirage (dos, bras)"),
                        opt("upper_push", "La poussée (épaules, pectoraux)"), opt("trunk", "Le tronc"),
                        opt("whole_body", "Tout le corps")],
               note="Pour tous les sports sauf course, vélo, natation et escalade (régions connues) ; sport de combat pré-coché « tout le corps », corrigeable."),
      ],
      note="Une seule question : l'une des trois premières réponses (exclusives entre elles) écrit `occupationalLoad` ; la quatrième s'y ajoute et ouvre sur place l'éditeur d'`otherSports` ; sans elle, `otherSports` est écrit vide (aucun). Les codes des réponses ne sont pas des codes du contrat, sauf les trois premiers. Passée : les deux champs restent absents. « Autre sport » n'est pas une discipline du programme : c'est ce que tu fais déjà ailleurs."),
    q("body_weight_goal", "recuperation", 3, "choice", "Ton poids, en ce moment, tu veux…", ["bodyWeightGoal", "targetBodyWeightKg"], skip=True,
      when=any_of(INTERMEDIATE, BODYWEIGHT_DISCIPLINES), defer_when=BEGINNER_PATH,
      options=[opt("lose", "Le faire baisser"), opt("maintain", "Le garder"), opt("gain", "Le faire monter"),
               opt("no_goal", "Je n'y pense pas")],
      factor="bilan_energetique",
      effect="En perte de poids : attentes réglées (la force peut monter, pas le muscle), volume gardé, tests moins fréquents ; lest et charge totale recalculés quand le poids change.",
      note="« Baisser » ou « monter » propose « Jusqu'à combien ? » (`targetBodyWeightKg`, facultatif). Aucun conseil alimentaire n'est donné. Le rythme réel se lit dans les pesées. Pour un débutant d'une discipline au poids du corps, la question est reportée après la première semaine, avec les trois autres de l'écran (`deferWhen`) : son premier bloc, prudent par construction, n'en dépend pas."),
    # ----------------------------------------------------------- santé ----
    q("health_screening", "sante", 2, "group", "Questionnaire santé", ["healthScreening"], required=True,
      note="Questionnaire L13 inchangé ; seule sa référence est dans le profil (aucune réponse copiée). Koach annonce sa taille avant de commencer (le nombre de questions oui / non du questionnaire du lot G6) : c'est un questionnaire entier, compté ici pour une question."),
    q("limitations", "sante", 2, "group", "Tu as mal quelque part, ou une ancienne blessure ?", ["limitations"],
      koach="Une ancienne blessure, une articulation sensible : dis-moi ce qui la réveille, je la protège. Je ne pose aucun diagnostic.",
      factor="antecedents",
      effect="Mouvements qui chargent la zone : départ une variante en dessous, progression plus lente, pas de test maximal tant que la gêne est d'au moins 4/10.",
      items=[
          item("zone", "Quelle zone ?", "body_map"),
          item("side", "Quel côté ?", "choice"),
          item("discomfort", "La gêne en ce moment, de 0 à 10 ?", "slider",
               note="« C'est ancien, je ne sens plus rien » écrit 0 sans montrer le curseur."),
          item("effortDiscomfort", "Quand elle se réveille pendant l'effort, elle monte à combien ?", "slider", required=False,
               note="Schéma 3. Une tendinopathie est à 0 au repos et à 6 sous charge : c'est cette valeur qui décide des tests maximaux."),
          item("since", "Depuis quand ?", "choice", required=False, options=[
              opt("under_6_weeks", "Moins de 6 semaines"), opt("weeks_6_to_12", "6 semaines à 3 mois"),
              opt("months_3_to_12", "3 mois à 1 an"), opt("over_12_months", "Plus d'un an"),
              opt("past_resolved", "C'est ancien, je ne sens plus rien")],
               note="Schéma 3."),
          item("aggravatedBy", "Qu'est-ce qui la réveille ?", "multi", required=False, options=[
              opt("pull_bent_arm", "Tirer vers moi en pliant les bras (tractions)"),
              opt("hang_straight_arm", "Rester suspendu, bras tendus"),
              opt("push_support", "Pousser (pompes, haut du dips)"),
              opt("straight_arm_support", "M'appuyer sur les mains, bras tendus (équilibre, planche)"),
              opt("overhead", "Lever les bras au-dessus de la tête"), opt("knee_flexion", "M'accroupir, plier les genoux"),
              opt("hip_hinge", "Me pencher en avant avec une charge"),
              opt("wrist_extension_grip", "Serrer fort, ou le poignet plié vers l'arrière"), opt("rings", "Les anneaux"),
              opt("running_jumping", "Courir ou sauter"),
              opt("deep_shoulder_extension", "Le bas du dips, la transition du muscle-up, le back lever"),
              opt("axial_loading", "Une barre lourde sur le dos"),
              opt("elbow_lockout", "Tendre le coude à fond sous charge"),
              opt("explosive_pull", "Tirer fort et vite")],
               note="Schéma 3. « Je ne sais pas » laisse le champ absent. Un débutant ne voit que les six premières réponses et « Courir ou sauter »."),
      ],
      note="Premier bouton : « Non, rien », en un appui. Côté : « les deux / au milieu » pour le dos. La carte du corps n'a ni bras ni avant-bras (énumération d'avant 0.4.0, fermée) : libeller « Coude / avant-bras » et « Épaule / bras ». Donnée de santé : écrite seulement avec l'accord santé (G6, KT-042). Une gêne de plus de 5/10, une douleur la nuit, une perte de force ou une aggravation sur deux semaines : Koach oriente vers un professionnel de santé, sans interpréter (règle L13)."),
    # ----------------------------------------------------- préférences ----
    q("preferences", "preferences", 2, "group", "Exercices aimés, exercices détestés",
      ["likedExerciseIds", "dislikedExerciseIds"], skip=True, when=INTERMEDIATE,
      note="Schéma 3 : masquée pour un débutant, qui dira « je n'aime pas » pendant la revue du programme (D4.5) ; toujours accessible dans Réglages › Profil. Un exercice aimé ne déplace jamais un mouvement de compétition ni son travail d'assistance (règle pour les moteurs, `PROFIL_V3.md` § 6)."),
    q("guidance_mode", "mode", 2, "choice", "Quand ton programme doit bouger, on fait comment ?", ["guidanceMode"], required=True,
      options=[opt("assisted", "Assisté : Koach change ton programme tout seul et te dit pourquoi"),
               opt("free", "Libre : Koach te propose le changement, c'est toi qui décides")],
      note="Décision D3.7 : la question reste à la création. Modifiable à tout moment dans les réglages."),
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
     "mode": "max_reps_in_time",
     "stations": [{"exerciseId": "sl-traction-lestee", "timeLimitSeconds": 120},
                  {"exerciseId": "sl-dips-leste", "timeLimitSeconds": 120}],
     "source": "https://streetlifting.ru/docs/isf-rules/faq",
     "status": "FAQ de la version 5.2 lue le 02/10/2026 : une tentative, 2 minutes, lest fixe ; lests par catégorie non relevés (à saisir)."},
]

# --------------------------------------------------------------------------
# Tests guidés : protocoles pour mesurer ce que l'utilisateur ne sait pas.
# `stage` : creation (déclaratif seulement), first_session (sous-maximal,
# dans la séance), later (après familiarisation). Références : PROFIL_V3.md §5.
# `eligible` dit si un test est PERMIS pour un profil ; il n'est PROPOSÉ que
# pour un mouvement du programme dont la capacité est inconnue, avec le
# matériel du profil, et quand son prérequis par mouvement (`requires`) est
# tenu d'après les niveaux et les records déclarés.
TESTABLE = all_of(HEALTH_STANDARD, INTERMEDIATE)
# --------------------------------------------------------------------------
TESTS = [
    {"id": "t1_serie_lourde", "title": "Série lourde d'estimation (barre, haltères, machine)",
     "benchmarkKind": "load_reps", "testKind": "amrap_estimate", "stage": "first_session",
     "eligible": TESTABLE,
     "forWhom": "Pratiquant qui sait exécuter le mouvement ; test par défaut pour un mouvement chargé dont le maximum est inconnu.",
     "requires": "Le mouvement est au programme et le matériel est dans le profil.",
     "safety": ["Barres de sécurité ou pareur au squat et au développé couché.",
                "Arrêt dès que la technique se dégrade."],
     "steps": ["Échauffement général de 5 minutes.",
               "Barre à vide × 8, puis environ 50 % de la charge visée × 5, 70 % × 3, 85 % × 1.",
               "Repos de 2 à 3 minutes.",
               "Série test : une charge que tu penses pouvoir soulever 5 fois ; arrête-toi en gardant 1 à 2 répétitions sous le pied."],
     "stop": ["1 à 2 répétitions en réserve, ou la barre ralentit nettement, ou la technique se dégrade.",
              "Série valable de 3 à 6 répétitions ; de 7 à 10, valeur gardée avec une incertitude plus large ; au-delà de 10, une seule reprise plus lourde après 3 à 5 minutes."],
     "conversion": {"formula": "brzycki", "function": "estimateOneRm",
                    "text": "r = répétitions + réserve déclarée ; 1RM = charge × 36 / (37 − r), sur la charge de la barre (squat, développé, soulevé de terre : jamais le poids du corps). Refusé au-delà de r = 10."},
     "uncertainty": "±5 % (série au maximum, jusqu'à 6 répétitions) ; ±7,5 % (réserve déclarée, ou 7 à 10 répétitions) ; ±10 % et valeur « provisoire » avant 6 mois de pratique. Calcul de ce lot à partir de la variabilité publiée, pas un chiffre publié.",
     "refs": ["brzycki1993", "nuzzo2024", "reynolds2006", "mayhew2008", "halperin2022", "steele2017"]},
    {"id": "t2_leste", "title": "Série lourde d'estimation lestée (traction, dips)",
     "benchmarkKind": "load_reps", "testKind": "amrap_estimate", "stage": "first_session",
     "eligible": all_of(TESTABLE, present("bodyWeightKg")),
     "forWhom": "Pratiquant capable d'au moins 8 répétitions strictes au poids du corps. Pas pour le muscle-up lesté (mouvement technique : aucune estimation par équation).",
     "requires": "Au moins 8 répétitions strictes au poids du corps sur le mouvement (niveau ou record déclaré) ; ceinture de lest et disques au profil.",
     "safety": ["Ceinture de lest fermée, descente contrôlée, pas de lâcher en bas des dips.", "Épaules et coudes échauffés."],
     "steps": ["Pesée du jour.",
               "Montée : 5 répétitions au poids du corps, puis 3 répétitions à la moitié du lest visé, puis 1 répétition au lest visé moins 5 kg.",
               "Lest visé supérieur à 40 % du poids de corps : montée en quatre marches — poids du corps × 5, 40 % du lest visé × 3, 65 % × 2, 85 % × 1.",
               "Repos de 3 minutes.", "Série test visant 3 à 6 répétitions, arrêtée avec 1 répétition sous le pied."],
     "stop": ["1 répétition en réserve, ou première répétition hors amplitude (menton sous la barre ; épaule au-dessus du coude en bas des dips)."],
     "conversion": {"formula": "brzycki_total", "function": "estimateOneRm + externalFromTotal",
                    "text": "Charge totale = lest + fraction du poids du corps × poids du jour ; 1RM total par Brzycki ; lest maximal = 1RM total − fraction × poids. Seulement pour les exercices qui ont une fraction du poids du corps au catalogue."},
     "uncertainty": "±5 à ±7,5 % de la charge TOTALE, soit souvent ±15 à ±20 % du lest : la fourchette est affichée en kilos de lest. Extrapolation : aucune étude ne valide l'équation sur ces mouvements. Ne sert pas au choix des tentatives.",
     "refs": ["brzycki1993", "ortega2021", "coyne2015", "nuzzo2024"]},
    {"id": "t3_max_direct", "title": "Maximum direct (1 répétition)",
     "benchmarkKind": "load_reps", "testKind": "one_rm", "stage": "later",
     "eligible": all_of(TESTABLE, at_least("trainingAge", "trainingAge", "months_6_to_24"),
                        any_of(not_(age_at_least(65)), at_least("trainingAge", "trainingAge", "years_2_to_5"))),
     "forWhom": "Pratiquant confirmé du mouvement (plus de 6 mois), questionnaire santé sans réserve ; jamais après 65 ans sans au moins 2 ans de pratique. Seul test proposé pour le muscle-up lesté.",
     "requires": "Aucune gêne d'au moins 4/10 (au repos ou à l'effort) sur une zone que le mouvement charge. Muscle-up lesté : au moins 5 muscle-ups stricts au poids du corps, et aucune gêne au coude, à l'épaule ou au sternum.",
     "safety": ["Pareur ou sécurités ; ceinture fermée.",
                "Un échec technique (forme perdue, amplitude manquée) arrête le test ; après un échec de force, une seule reprise plus légère.",
                "Muscle-up lesté : tout échec arrête le test ; 4 essais lourds au plus."],
     "steps": ["5 à 10 répétitions légères ; repos 1 minute.", "Charge plus lourde × 3 à 5 répétitions ; repos 2 minutes.",
               "Charge plus lourde × 2 à 3 répétitions ; repos 2 à 4 minutes.",
               "Essais d'une répétition, repos de 2 à 4 minutes entre deux essais. Barre (squat, développé) : +5 à 10 % après une réussite, −2,5 à 5 % après un échec de force.",
               "Mouvements lestés : les sauts se comptent en kilos de LEST, pas en pourcentage — +5 kg, puis +2,5 kg, puis +1,25 kg à l'approche du maximum."],
     "stop": ["Échec technique, deuxième échec de force, ou 5 essais.", "Le maximum est trouvé en 3 à 5 essais."],
     "conversion": {"formula": "none", "text": "La meilleure charge réussie est le maximum (réserve 0, 1 répétition)."},
     "uncertainty": "±4 % d'un jour à l'autre (coefficient de variation médian du test de 1RM).",
     "refs": ["grgic2020", "nsca2016", "pollock1991", "seo2012"]},
    {"id": "t4_reps_max", "title": "Répétitions max au poids du corps (traction, dips, pompes, muscle-up)",
     "benchmarkKind": "max_reps", "testKind": "max_reps", "stage": "first_session", "eligible": TESTABLE,
     "forWhom": "Pratiquant qui fait déjà plusieurs répétitions strictes ; qui n'en fait aucune travaille une variante plus facile, sans test.",
     "requires": "Le mouvement est au programme.",
     "safety": ["Échauffement ; une seule série test par mouvement et par séance."],
     "steps": ["2 séries d'échauffement à environ un tiers du nombre attendu.", "Repos de 3 minutes.",
               "Série maximale, amplitude complète, sans élan."],
     "stop": ["Première répétition hors amplitude, ou pause de plus de 3 secondes."],
     "conversion": {"formula": "none",
                    "text": "Valeur brute. Aucune conversion en maximum lesté au-delà de 10 répétitions. Muscle-up : moins de 5 répétitions strictes, pas de lest (usage d'entraîneur)."},
     "uncertainty": "±1 répétition jusqu'à 10, ±2 au-delà pour la traction et les dips (estimation de ce lot : aucune étude de fiabilité lue pour ces mouvements) ; pompes : un écart de moins de 4 à 5 répétitions entre deux tests ne prouve pas un changement.",
     "refs": ["kardor2023", "sanchezmoreno2017", "mitter2022"]},
    {"id": "t5_maintien_max", "title": "Maintien max (suspension, gainage, L-sit, étape de figure)",
     "benchmarkKind": "max_hold", "testKind": "max_hold", "stage": "first_session", "eligible": TESTABLE,
     "forWhom": "Sur l'étape de progression tenue proprement au moins 5 secondes.",
     "requires": "L'étape est au programme ; équilibre : au mur tant que la sortie n'est pas acquise.",
     "safety": ["Poignets et épaules échauffés ; sortie contrôlée.", "Tapis sous les figures en appui renversé ou en suspension."],
     "steps": ["2 maintiens courts d'échauffement (environ un tiers du temps attendu).", "Repos de 2 à 3 minutes.",
               "Maintien long (gainage, suspension) : un seul maintien maximal chronométré.",
               "Maintien court de figure (moins de 15 secondes attendues) : 3 essais, 2 à 3 minutes de repos ; on garde le meilleur essai propre."],
     "stop": ["Perte de la forme (hanches qui tombent, bras qui fléchissent), pas la chute."],
     "conversion": {"formula": "none",
                    "text": "Valeur brute. Les durées de travail en sont une part (60 à 70 % : usage d'entraîneur, réglé par les moteurs)."},
     "uncertainty": "±5 à 10 % pour un maintien long (gainage) ; ±1 à 2 secondes pour un maintien court de figure, soit jusqu'à ±25 % sur 6 secondes (estimation : aucune étude de fiabilité sur les figures).",
     "refs": ["rodriguezperea2025", "martinezromero2020", "low2016"]},
    {"id": "t6_course_6min", "title": "Course : test de 6 minutes",
     "benchmarkKind": "distance_trial", "testKind": "distance_trial", "stage": "later", "eligible": TESTABLE,
     "forWhom": "Personne capable de courir 10 minutes sans s'arrêter.",
     "requires": "La course est au programme.",
     "safety": ["Terrain plat, pas de forte chaleur.", "Échauffement de 10 à 15 minutes et 3 accélérations.",
                "Arrêt immédiat en cas de douleur dans la poitrine, de vertige ou d'essoufflement anormal."],
     "steps": ["Courir la plus grande distance possible en 6 minutes, à allure régulière (première minute prudente)."],
     "stop": ["Fin du chronomètre ; un arrêt avant la fin invalide le test (à refaire un autre jour)."],
     "conversion": {"formula": "speed", "function": "trialSpeed",
                    "text": "Vitesse moyenne = distance / 360 s ; les allures d'entraînement en sont des parts (`speed_fraction`)."},
     "uncertainty": "±5 à 8 % sur la vitesse (estimation ; aucune étude de validation lue).",
     "refs": ["mayorgavega2016", "cooper1968"]},
    {"id": "t7_course_chrono", "title": "Course : contre-la-montre de 5 km (3 km pour les moins aguerris)",
     "benchmarkKind": "time_trial", "testKind": "time_trial", "stage": "later", "eligible": TESTABLE,
     "forWhom": "Coureur régulier (30 minutes en continu).",
     "requires": "La course est au programme.",
     "safety": ["Comme le test de 6 minutes.", "Échauffement de 15 minutes."],
     "steps": ["Distance fixe au meilleur temps, à allure régulière. Le 5 km est préféré pour prédire un 10 km."],
     "stop": ["Distance terminée."],
     "conversion": {"formula": "riegel", "function": "riegelSeconds",
                    "text": "Temps prédit sur une autre distance = temps × (distance voulue / distance du test)^1,06, jusqu'au semi-marathon. Prédiction « provisoire » : elle suppose un volume de course suffisant pour la distance visée."},
     "uncertainty": "±2 à 3 % sur le temps du test (coureurs entraînés), davantage chez un coureur qui gère mal son allure ; prédiction d'une distance plus longue : au moins ±4 % à faible volume hebdomadaire (estimation) ; au-delà du semi-marathon la formule est trop optimiste : aucune prédiction.",
     "refs": ["laursen2007", "riegel1981", "vickers2016"]},
    {"id": "t8_sans_test", "title": "Sans test : calage au fil des séances",
     "benchmarkKind": None, "testKind": None, "stage": "creation",
     "eligible": not_(TESTABLE),
     "forWhom": "Débutant (ou niveau non renseigné) ; questionnaire santé en mode prudent ou sans réponse.",
     "requires": "Rien.",
     "safety": ["Aucun effort maximal, aucun examen."],
     "steps": ["Charges de départ prudentes choisies par le moteur (D4.7).",
               "Calage en 2 à 3 séances d'après les répétitions faites et les flammes (D3.5).",
               "Course : allure de conversation."],
     "stop": [],
     "conversion": {"formula": "none", "text": "Aucune valeur n'est écrite dans le profil ; les estimations du moteur dynamique font foi."},
     "uncertainty": "Valeur « non mesurée » ; les valeurs des deux à trois premières séances sont provisoires (apprentissage du geste).",
     "refs": ["ploutzsnyder2001"]},
    {"id": "t9_reps_temps", "title": "Épreuves de répétitions : maximum en temps limité",
     "benchmarkKind": "max_reps", "testKind": "max_reps", "stage": "later",
     "eligible": all_of(TESTABLE, any_of(min_number("streetMode.setsRepsPct", 1), discipline("street_workout"),
                                         is_in("events[*].kind", "reps_competition"))),
     "forWhom": "Pratiquant de sets & reps ou compétiteur d'une épreuve de répétitions, après familiarisation.",
     "requires": "Au moins 10 répétitions strictes d'une traite sur le mouvement.",
     "safety": ["Échauffement complet ; amplitude jugée comme en compétition.", "Arrêt si la technique se dégrade ou si une douleur apparaît."],
     "steps": ["Maximum de répétitions en 2 minutes (ou dans la durée de l'épreuve visée), pauses libres.",
               "Noter le total et le découpage (répétitions de chaque série, repos pris)."],
     "stop": ["Fin du chronomètre."],
     "conversion": {"formula": "none",
                    "text": "Valeur brute : `Benchmark` de nature `max_reps` avec `seconds` ; le découpage se lit dans le journal (`SetRecord.parts`)."},
     "uncertainty": "Non connue : usage d'entraîneur, aucune étude de fiabilité lue. Un écart de moins de 2 à 3 répétitions entre deux tests ne prouve pas un changement (estimation).",
     "refs": ["mitter2022"]},
    {"id": "t10_series_repetees", "title": "Épreuves de répétitions : trois séries maximales",
     "benchmarkKind": "max_reps", "testKind": "max_reps", "stage": "later",
     "eligible": all_of(TESTABLE, any_of(min_number("streetMode.setsRepsPct", 1), discipline("street_workout"),
                                         is_in("events[*].kind", "reps_competition"))),
     "forWhom": "Pratiquant de sets & reps ou compétiteur d'une épreuve de répétitions, après familiarisation.",
     "requires": "Au moins 10 répétitions strictes d'une traite sur le mouvement.",
     "safety": ["Comme le test précédent."],
     "steps": ["3 séries maximales du même mouvement, 90 secondes de repos entre les séries."],
     "stop": ["Fin de la troisième série."],
     "conversion": {"formula": "none",
                    "text": "La première série est le maximum (`max_reps`) ; la chute de la première à la troisième série dit comment découper et espacer les séries (réglage des moteurs)."},
     "uncertainty": "Non connue : usage d'entraîneur, aucune étude de fiabilité lue.",
     "refs": ["mitter2022"]},
]
