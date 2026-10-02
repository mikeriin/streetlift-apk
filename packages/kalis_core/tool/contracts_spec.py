"""Spécification des contrats de kalis_core (lot GC).

Source unique des types d'échange : `gen_contracts.py` en tire le code Dart
(`lib/src/generated/`), les générateurs de valeurs aléatoires des tests de
propriétés, le registre des codes de raison et les tableaux de CONTRAT.md.

Règle d'évolution (PIPELINE_GP.md §0) : après la livraison 0.1.0, ce fichier
n'évolue que de façon additive — nouveaux types, nouvelles valeurs d'enum en
fin de liste, nouveaux champs **optionnels** (suffixe `?`). Rien n'est retiré
ni renommé sans décision du propriétaire.

Notation des types de champ : int, double, bool, string, date (jour civil
AAAA-MM-JJ), json (objet JSON libre), enum:Nom, obj:Nom ; préfixe `list:` ;
suffixe `?` = optionnel (absent du JSON quand il est nul).
"""
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class Enum:
    name: str
    values: list[tuple[str, str]]  # (identifiant Dart, code JSON)
    doc: str
    module: str = "enums"


@dataclass
class Field:
    name: str
    type: str
    doc: str
    min: float | None = None
    max: float | None = None
    min_len: int | None = None
    max_len: int | None = None
    ref: str | None = None  # 'exercise' : identifiant du catalogue


@dataclass
class Type:
    name: str
    module: str
    doc: str
    fields: list[Field]
    schema_version: int | None = None  # type racine versionné
    custom: bool = False  # invariants supplémentaires dans custom_validation.dart
    invariants: list[str] = field(default_factory=list)  # pour CONTRAT.md
    # (0.4.0) Type à variantes : (champ discriminant, {code: (champs obligatoires, champs permis)}).
    # Les champs cités au moins une fois sont « contrôlés » : présents seulement
    # pour les variantes qui les exigent ou les permettent.
    variants: tuple[str, dict[str, tuple[list[str], list[str]]]] | None = None


def camel(code: str) -> str:
    parts = code.split("_")
    return parts[0] + "".join(p.capitalize() for p in parts[1:])


def E(name: str, codes, doc: str) -> Enum:
    vals = [(c if isinstance(c, tuple) else (camel(c), c)) for c in codes]
    return Enum(name, vals, doc)


F = Field

ENUMS: list[Enum] = [
    # ---- vocabulaires du catalogue (codes = ceux du catalogue compilé) ----
    E("CatalogDiscipline", [
        ("musculation", "Musculation"), ("streetWorkout", "Street workout"),
        ("streetlifting", "Streetlifting"), ("calisthenicsStatic", "Calisthénie statique"),
        ("calisthenicsDynamic", "Calisthénie dynamique"), ("crossfit", "CrossFit / WOD"),
        ("cardio", "Cardio"), ("mobility", "Mobilité"),
    ], "Discipline d'un exercice dans la base v1.1 (8 valeurs)."),
    E("ExerciseLevel", [
        ("beginner", "Débutant"), ("intermediate", "Intermédiaire"),
        ("advanced", "Avancé"), ("elite", "Élite"),
    ], "Niveau d'un exercice dans la base (ordre croissant)."),
    E("MovementPattern", [
        "adducteurs_abducteurs", "auto_massage", "balistique", "cardio_continu",
        "cardio_fractionne", "charniere_hanche", "compression", "conditionnement",
        "corde_a_sauter", "cou", "equilibre_mains", "etirement_dynamique",
        "etirement_statique", "extension_genou", "extension_hanche", "extension_rachis",
        "fente", "figure_dynamique_poussee", "figure_dynamique_tirage",
        "figure_statique_mixte", "figure_statique_poussee", "figure_statique_tirage",
        "flexion_genou", "flexion_hanche", "flexion_tronc", "freestyle",
        "gainage_anti_extension", "gainage_anti_flexion_laterale", "gainage_anti_rotation",
        "gymnastique_crossfit", "halterophilie", "isolation_biceps", "isolation_dos",
        "isolation_epaules", "isolation_pectoraux", "isolation_trapezes",
        "isolation_triceps", "marche", "mobilite_articulaire", "mollets", "pliometrie",
        "porte", "poussee_horizontale", "poussee_inclinee", "poussee_verticale_basse",
        "poussee_verticale_haute", "prehension", "preparation_scapulaire", "respiration",
        "rotation_tronc", "souplesse", "sprint", "squat", "tirage_horizontal",
        "tirage_vertical", "transition_muscle_up",
    ], "Schéma de mouvement calculé (56 valeurs)."),
    E("MovementFamily", [
        "cardio", "conditionnement", "cou", "explosif", "figure_dynamique",
        "figure_statique", "gainage", "isolation_bras", "isolation_haut",
        "isolation_jambes", "jambes_genou", "jambes_hanche", "mobilite", "porte",
        "poussee", "recuperation", "tirage", "tronc",
    ], "Famille de schémas de mouvement (18 valeurs)."),
    E("MovementPlane", ["sagittal", "frontal", "transversal", "multiple"],
      "Plan dominant du mouvement."),
    E("Articularity", [
        ("multiJoint", "polyarticulaire"), ("singleJoint", "monoarticulaire"),
        ("notApplicable", "non_applicable"),
    ], "Poly- ou mono-articulaire ; sans objet pour les tenues, le cardio, la mobilité."),
    E("ContractionMode", [
        ("dynamicEffort", "dynamique"), ("isometric", "isometrique"), ("eccentric", "excentrique"),
        ("explosive", "explosif"), ("cyclic", "cyclique"), ("passive", "passif"),
    ], "Régime de contraction dominant."),
    E("Place", [("gym", "salle"), ("home", "maison"), ("outdoor", "exterieur")],
      "Lieu d'entraînement."),
    E("Joint", [
        ("shoulder", "epaule"), ("elbow", "coude"), ("wrist", "poignet"),
        ("lumbar", "lombaires"), ("knee", "genou"), ("hip", "hanche"), ("ankle", "cheville"),
    ], "Articulation suivie par les contraintes articulaires (7 valeurs)."),
    E("JointStress", [("low", "faible"), ("moderate", "moyenne"), ("high", "forte")],
      "Niveau de contrainte articulaire (ordre croissant)."),
    E("LoadType", [
        ("none", "aucune"), ("bodyweight", "poids_du_corps"), ("addedWeight", "lest"),
        ("barbell", "barre"), ("dumbbells", "halteres"), ("kettlebell", "kettlebell"),
        ("machine", "machine"), ("cable", "poulie"), ("band", "elastique"), ("other", "autre"),
    ], "Type de charge d'un exercice."),
    E("MeasureUnit", [
        ("repetitions", "repetitions"), ("seconds", "secondes"),
        ("distance", "distance"), ("calories", "calories"),
    ], "Unité principale d'une série (distance en mètres)."),
    E("Laterality", [("bilateral", "bilateral"), ("unilateral", "unilateral"), ("alternating", "alterne")],
      "Latéralité de l'exercice."),
    E("FractionSource", [("published", "publiee"), ("derived", "derivee"), ("estimated", "estimee")],
      "Origine de la fraction du poids du corps."),
    # ---- profil ----
    E("Sex", ["female", "male", "undisclosed"], "Sexe déclaré (standards de rang, D7.5)."),
    E("TrainingDiscipline", [
        "musculation", "street_workout", "streetlifting", "calisthenics", "crossfit",
        "cardio", "mobility", "general_fitness",
    ], "Discipline d'entraînement du profil (D3.1, 8 valeurs)."),
    E("StreetStyle", ["streetlifting", "sets_reps", "calisthenics"],
      "Composante du mode street (D3.3)."),
    E("GuidanceMode", ["assisted", "free"], "Mode assisté ou libre (D3.7, D5.6)."),
    E("BodyZone", [
        "neck", "shoulder", "elbow", "wrist_hand", "upper_back", "lower_back", "chest",
        "abdomen", "hip", "thigh", "knee", "lower_leg", "ankle_foot",
    ], "Zone du corps (blessures, limitations, douleurs)."),
    E("BodySide", ["left", "right", "both"], "Côté du corps."),
    E("LevelMeasure", ["max_reps", "one_rm_kg", "max_hold_seconds", "time_seconds"],
      "Mesure d'un niveau déclaré : répétitions max, 1RM de charge externe en kg (lest seul pour un exercice lesté), tenue max, temps sur une distance."),
    E("GoalKind", ["performance", "habit"], "Nature d'un objectif (D3.8)."),
    E("GoalOrigin", ["user", "suggested"], "Objectif saisi ou suggéré par Koach."),
    E("GoalMetric", ["one_rm_kg", "max_reps", "max_hold_seconds", "skill_unlocked", "time_seconds", "distance_meters"],
      "Grandeur visée par un objectif de performance : 1RM de charge externe en kg, répétitions max (à une charge donnée si `loadKg`), tenue max, figure débloquée, temps sur une distance, distance en une durée."),
    E("ExperienceLevel", ["beginner", "intermediate", "advanced", "elite"],
      "Niveau global d'expérience déclaré (ordre croissant)."),
    E("HealthScreeningOutcome", ["standard", "cautious", "not_answered"],
      "Résultat du questionnaire santé L13 (référence, aucune réponse n'est copiée)."),
    # ---- journal ----
    E("SessionOrigin", ["program", "imported"],
      "Séance du programme, ou reprise de l'ancien journal de l'application."),
    E("SetKind", ["warmup", "work", "calibration", "test"], "Rôle d'une série."),
    E("PainPhase", ["before", "during", "after"], "Moment où la douleur est signalée."),
    # ---- plan ----
    E("SlotRole", ["main", "secondary", "accessory", "skill", "core", "conditioning", "mobility", "warmup", "cooldown"],
      "Rôle d'un exercice dans la séance."),
    E("LockKind", ["keep_slot", "require_exercise", "exclude_exercise", "keep_day"],
      "Verrou posé par la revue (D4.6)."),
    E("ReviewKind", ["can_do", "cannot_do", "dislike", "add", "remove", "replace"],
      "Action de revue de la passe 1 (D4.5)."),
    E("VariantKind", ["easier", "equivalent", "other_equipment", "other"],
      "Nature d'une variante proposée (3 ciblées + toutes)."),
    E("ChangeKind", [
        "exercise_added", "exercise_removed", "exercise_replaced", "exercise_moved",
        "order_changed", "prescription_changed", "day_added", "day_removed",
    ], "Changement typé d'un diff de programme."),
    E("WeekKind", ["intro", "build", "deload", "test"], "Nature d'une semaine du bloc."),
    E("LoadBasis", ["external", "bodyweight", "bodyweight_plus_external", "unloaded"],
      "Ce que désigne la charge d'une prescription."),
    E("RestructureScope", ["session", "week", "block"], "Portée d'une restructuration."),
    # ---- adapt ----
    E("ProposalKind", [
        "load", "reps", "volume", "exercise_swap", "session_restructure",
        "block_restructure", "deload", "pain_sparing", "schedule",
    ], "Type de proposition du moteur dynamique."),
    E("ProposalScope", ["set", "exercise", "session", "week", "block"], "Portée d'une proposition."),
    E("UnlockLevel", ["loads_reps", "volume", "exercise_swap", "session_restructure", "block_restructure"],
      "Niveau de déblocage des propositions (D5.7, ordre croissant)."),
    E("AdjustmentKind", ["load_reduced", "sets_reduced", "exercise_swapped", "exercise_removed", "rest_increased", "load_increased"],
      "Ajustement d'une séance après le bilan santé."),
    E("IntraSessionAction", ["keep", "load_up", "load_down", "reps_up", "reps_down", "stop_exercise", "rest_more"],
      "Conseil pour la série suivante."),
    E("CapacityUnit", ["one_rm_kg", "max_reps", "max_hold_seconds", "meters_per_second"],
      "Unité de la capacité estimée d'un exercice : 1RM de charge TOTALE en kg (charge externe + fraction du poids du corps), répétitions max, tenue max, vitesse."),
    E("ProposalStatus", ["auto_applied", "accepted", "refused", "undone"],
      "Suite donnée à une proposition (D5.6) : appliquée automatiquement, acceptée, refusée, annulée."),
    # ---- quest ----
    E("XpSource", ["effort", "consistency", "record", "milestone", "quest"], "Origine d'un gain d'XP (D7.2)."),
    E("AthleteAttribute", ["strength", "endurance", "power", "technique", "mobility", "consistency"],
      "Attribut façon RPG (D7.5)."),
    E("MovementRankTier", ["unranked", "bronze", "silver", "gold", "platinum", "diamond", "elite"],
      "Rang d'un mouvement (ordre croissant)."),
    E("QuestKind", ["daily", "weekly", "campaign", "koach"], "Famille de quête (D7.6)."),
    E("QuestStatus", ["active", "completed", "expired"], "État d'une quête."),
    E("KreditSource", ["quest", "chest", "level_up", "milestone", "record"], "Origine d'un gain de Krédits."),
    E("DelightKind", ["record", "chest", "week_streak", "session_grade", "combo", "ghost",
                      "first_time", "level_up", "rank_up", "goal_milestone", "quest_completed"],
      "Événement de plaisir (D8.1). Les cinq derniers sont ajoutés en 0.3.0 (première fois, passage de niveau, nouveau rang, jalon d'objectif, quête terminée)."),
    E("SessionGrade", ["s", "a", "b", "c"], "Note de séance."),
    E("RecordKind", ["one_rm_kg", "max_reps", "max_hold_seconds", "volume_kg", "time_seconds", "distance_meters"],
      "Nature d'un record (même vocabulaire que les niveaux et les objectifs)."),
    E("BreakReason", ["vacation", "illness", "injury", "other"], "Motif d'une pause déclarée."),
]

EXID = dict(ref="exercise")

TYPES: list[Type] = [
    # ======================= commun =======================
    Type("Reason", "common", "Code de raison et ses paramètres (aucun texte : les phrases viennent de kalis_koach et de l'application).", [
        F("code", "string", "Identifiant stable du registre des codes de raison.", min_len=1),
        F("params", "json", "Paramètres typés du code (nombres, chaînes, booléens), écrits par clés triées."),
    ], custom=True, invariants=["`code` figure au registre ; `params` contient exactement les paramètres déclarés, du bon type."]),
    # ======================= profil =======================
    Type("DisciplineShare", "profile", "Discipline secondaire et son dosage.", [
        F("discipline", "enum:TrainingDiscipline", "Discipline."),
        F("pct", "int", "Part en pour cent.", min=1, max=99),
    ]),
    Type("DisciplineMix", "profile", "Discipline principale et 0 à 2 secondaires dosées (D3.2).", [
        F("primary", "enum:TrainingDiscipline", "Discipline principale."),
        F("primaryPct", "int", "Part de la principale, en pour cent.", min=1, max=100),
        F("secondaries", "list:obj:DisciplineShare", "Disciplines secondaires.", max_len=2),
    ], custom=True, invariants=["Somme des parts = 100 ; disciplines distinctes ; la principale a la plus grande part."]),
    Type("StreetMode", "profile", "Mode street : une principale parmi trois, les deux autres dosées (D3.3).", [
        F("primary", "enum:StreetStyle", "Composante principale."),
        F("streetliftingPct", "int", "Part du streetlifting.", min=0, max=100),
        F("setsRepsPct", "int", "Part du sets & reps.", min=0, max=100),
        F("calisthenicsPct", "int", "Part de la calisthénie.", min=0, max=100),
    ], custom=True, invariants=["Somme = 100 ; la principale a la plus grande part, strictement positive."]),
    Type("MovementLevel", "profile", "Niveau déclaré sur un mouvement : fourchette ou « je ne sais pas » (D3.5).", [
        F("exerciseId", "string", "Exercice de référence.", **EXID),
        F("measure", "enum:LevelMeasure", "Grandeur déclarée."),
        F("known", "bool", "false = « je ne sais pas » (aucune valeur)."),
        F("low", "double?", "Borne basse de la fourchette.", min=0),
        F("high", "double?", "Borne haute de la fourchette.", min=0),
        F("distanceMeters", "double?", "Distance, pour `time_seconds`.", min=0),
    ], custom=True, invariants=["`known` ⇒ `low` ≤ `high` renseignés ; sinon `low` et `high` absents ; `distanceMeters` seulement pour `time_seconds`."]),
    Type("Goal", "profile", "Objectif : performance chiffrée datée, ou habitude (D3.8).", [
        F("id", "string", "Identifiant stable de l'objectif.", min_len=1),
        F("kind", "enum:GoalKind", "Performance ou habitude."),
        F("origin", "enum:GoalOrigin", "Saisi par l'utilisateur ou suggéré par Koach."),
        F("createdOn", "date", "Jour de création."),
        F("exerciseId", "string?", "Exercice visé (performance).", **EXID),
        F("metric", "enum:GoalMetric?", "Grandeur visée (performance)."),
        F("targetValue", "double?", "Valeur cible, dans l'unité de `metric` (charge EXTERNE pour `one_rm_kg` ; absente pour `skill_unlocked`).", min=0),
        F("distanceMeters", "double?", "Distance de référence pour `time_seconds`.", min=0),
        F("loadKg", "double?", "Charge externe de référence pour `max_reps` (« 38 répétitions à 70 kg »).", min=0),
        F("durationSeconds", "int?", "Durée de référence pour `distance_meters`.", min=1),
        F("targetDate", "date?", "Échéance (performance)."),
        F("sessionsPerWeek", "int?", "Séances par semaine (habitude).", min=1, max=14),
        F("weeks", "int?", "Durée en semaines (habitude).", min=1, max=104),
    ], custom=True, invariants=["Performance : `exerciseId`, `metric`, `targetDate` renseignés, champs d'habitude absents. Habitude : `sessionsPerWeek` et `weeks` renseignés, champs de performance absents."]),
    Type("DaySlot", "profile", "Disponibilité d'un jour précis (D3.6).", [
        F("weekday", "int", "Jour ISO : 1 = lundi … 7 = dimanche.", min=1, max=7),
        F("minutes", "int", "Durée disponible, en minutes.", min=10, max=300),
        F("place", "enum:Place?", "Lieu de ce jour-là (absent : n'importe quel lieu du profil)."),
    ]),
    Type("PlaceEquipment", "profile", "Matériel disponible dans un lieu.", [
        F("place", "enum:Place", "Lieu."),
        F("equipment", "list:string", "Matériel disponible dans ce lieu (vocabulaire `materiel` de la base)."),
    ]),
    Type("LoadIncrement", "profile", "Plus petit pas de charge disponible pour un type de charge.", [
        F("loadType", "enum:LoadType", "Type de charge."),
        F("stepKg", "double", "Pas de charge, en kg.", min=0.05, max=50),
        F("minKg", "double?", "Plus petite charge disponible, en kg.", min=0),
    ]),
    Type("Limitation", "profile", "Blessure ou limitation déclarée.", [
        F("zone", "enum:BodyZone", "Zone du corps."),
        F("side", "enum:BodySide", "Côté."),
        F("joint", "enum:Joint?", "Articulation concernée, si la zone en désigne une."),
        F("discomfort", "int", "Gêne de 0 à 10.", min=0, max=10),
    ]),
    Type("HealthScreeningRef", "profile", "Référence au questionnaire santé L13 (aucune réponse n'est copiée ici).", [
        F("questionnaireId", "string", "Identifiant et version du questionnaire.", min_len=1),
        F("answeredOn", "date?", "Jour de réponse."),
        F("outcome", "enum:HealthScreeningOutcome", "Résultat : standard, mode prudent, non répondu."),
    ]),
    Type("AthleteProfile", "profile", "Profil d'athlète v2 (D3).", [
        F("schemaVersion", "int", "Version du schéma (2).", min=2),
        F("displayName", "string?", "Prénom ou pseudo, facultatif.", max_len=40),
        F("sex", "enum:Sex", "Sexe déclaré."),
        F("birthYear", "int", "Année de naissance.", min=1900, max=2100),
        F("heightCm", "int", "Taille en centimètres.", min=100, max=250),
        F("bodyWeightKg", "double?", "Poids de corps en kg, facultatif.", min=25, max=300),
        F("disciplines", "obj:DisciplineMix", "Disciplines et dosages."),
        F("streetMode", "obj:StreetMode?", "Mode street, s'il est activé."),
        F("movementLevels", "list:obj:MovementLevel", "Niveaux déclarés par mouvement."),
        F("goals", "list:obj:Goal", "Objectifs."),
        F("availability", "list:obj:DaySlot", "Jours et durées disponibles.", min_len=1, max_len=7),
        F("places", "list:enum:Place", "Lieux d'entraînement.", min_len=1, max_len=3),
        F("equipment", "list:string", "Matériel disponible, tous lieux confondus (vocabulaire `materiel` de la base)."),
        F("equipmentByPlace", "list:obj:PlaceEquipment?", "Matériel par lieu, quand il diffère d'un lieu à l'autre (absent : `equipment` vaut partout)."),
        F("loadIncrements", "list:obj:LoadIncrement", "Incréments de charge par type de charge."),
        F("limitations", "list:obj:Limitation", "Blessures et limitations."),
        F("likedExerciseIds", "list:string", "Exercices aimés.", **EXID),
        F("dislikedExerciseIds", "list:string", "Exercices détestés.", **EXID),
        F("knownExerciseIds", "list:string?", "Exercices que l'utilisateur a dit savoir faire (revue, D4.5).", **EXID),
        F("cannotDoExerciseIds", "list:string?", "Exercices que l'utilisateur a dit ne pas savoir faire (revue, D4.5).", **EXID),
        F("experience", "enum:ExperienceLevel?", "Niveau global d'expérience déclaré."),
        F("guidanceMode", "enum:GuidanceMode", "Mode assisté ou libre."),
        F("healthScreening", "obj:HealthScreeningRef?", "Référence au questionnaire santé."),
        F("createdOn", "date", "Jour de création du profil."),
        F("updatedOn", "date", "Jour de dernière modification."),
    ], schema_version=2, custom=True, invariants=[
        "Jours de `availability` distincts ; lieux, matériel, exercices aimés et détestés sans doublon ; aimés ∩ détestés = ∅.",
        "Un seul incrément par type de charge ; `updatedOn` ≥ `createdOn`.",
        "Mode street activé ⇒ `disciplines` est l'image du mode street (`StreetMode.toDisciplineMix()`).",
        "`equipmentByPlace` : un lieu au plus une fois, parmi `places`, matériel inclus dans `equipment` ; `DaySlot.place` parmi `places` ; su ∩ pas su = ∅.",
    ]),
    # ======================= journal =======================
    Type("PainReport", "journal", "Douleur signalée.", [
        F("zone", "enum:BodyZone", "Zone."),
        F("side", "enum:BodySide", "Côté."),
        F("joint", "enum:Joint?", "Articulation, si la zone en désigne une."),
        F("intensity", "int", "Intensité de 0 à 10.", min=0, max=10),
        F("phase", "enum:PainPhase", "Avant, pendant ou après la séance."),
        F("exerciseId", "string?", "Exercice pendant lequel elle est apparue.", **EXID),
    ]),
    Type("HealthCheck", "journal", "Bilan santé de début de séance (D5.8). Chaque question est facultative : une réponse absente reste absente (aucune valeur par défaut). Échelles de 1 à 5 : 5 = état le plus favorable.", [
        F("overall", "int?", "« Comment tu te sens ? »", min=1, max=5),
        F("sleepQuality", "int?", "Qualité du sommeil.", min=1, max=5),
        F("sleepHours", "double?", "Heures de sommeil.", min=0, max=24),
        F("energy", "int?", "Énergie.", min=1, max=5),
        F("mood", "int?", "Humeur.", min=1, max=5),
        F("soreness", "int?", "Courbatures (5 = aucune).", min=1, max=5),
        F("stress", "int?", "Stress (5 = aucun).", min=1, max=5),
        F("motivation", "int?", "Motivation.", min=1, max=5),
        F("nutrition", "int?", "Alimentation.", min=1, max=5),
        F("hydration", "int?", "Hydratation.", min=1, max=5),
        F("minutesAvailable", "int?", "Temps disponible aujourd'hui, en minutes.", min=0, max=600),
        F("pains", "list:obj:PainReport?", "Douleurs localisées (absent : question non posée ou sans réponse ; liste vide : aucune douleur)."),
    ]),
    Type("SetTarget", "journal", "Cible prescrite d'une série, telle qu'elle était affichée.", [
        F("repsLow", "int?", "Bas de la plage de répétitions.", min=0, max=1000),
        F("repsHigh", "int?", "Haut de la plage de répétitions.", min=0, max=1000),
        F("secondsLow", "int?", "Bas de la plage de temps, en secondes.", min=0, max=86400),
        F("secondsHigh", "int?", "Haut de la plage de temps, en secondes.", min=0, max=86400),
        F("distanceMeters", "double?", "Distance visée, en mètres.", min=0),
        F("calories", "double?", "Calories visées.", min=0),
        F("loadKg", "double?", "Charge externe prescrite, en kg (même convention que `SetRecord.externalLoadKg`).", min=-300, max=1000),
        F("flames", "int?", "Flammes visées.", min=1, max=10),
    ], custom=True, invariants=["Bornes basses ≤ bornes hautes quand les deux sont renseignées."]),
    Type("SetRecord", "journal", "Série réalisée.", [
        F("exerciseId", "string", "Exercice.", **EXID),
        F("exerciseOrder", "int", "Rang de l'exercice dans la séance (0 = premier).", min=0),
        F("setIndex", "int", "Rang de la série dans l'exercice (0 = première).", min=0),
        F("kind", "enum:SetKind", "Rôle de la série."),
        F("externalLoadKg", "double?", "Charge externe en kg, telle que l'utilisateur la lit : barre et disques compris ; par haltère ou par kettlebell ; valeur affichée d'une machine ou d'une poulie ; lest seul pour un exercice lesté (le poids du corps n'y est jamais ajouté) ; négative = assistance ; absente = aucune.", min=-300, max=1000),
        F("reps", "int?", "Répétitions réalisées (par côté pour un exercice unilatéral).", min=0, max=1000),
        F("seconds", "int?", "Durée réalisée, en secondes (par côté pour un exercice unilatéral).", min=0, max=86400),
        F("distanceMeters", "double?", "Distance réalisée, en mètres.", min=0),
        F("calories", "double?", "Calories réalisées.", min=0),
        F("flames", "int?", "Note de difficulté de 1 à 10 flammes ; absente = « pas de note ».", min=1, max=10),
        F("success", "bool", "La série a atteint sa cible."),
        F("excluded", "bool", "Série écartée (incident), gardée au journal, ignorée des moteurs."),
        F("slotId", "string?", "Emplacement du programme dont vient la série."),
        F("side", "enum:BodySide?", "Côté travaillé (exercice unilatéral) : `both` = une série par côté, comptée une fois ; `left` ou `right` = un seul côté."),
        F("target", "obj:SetTarget?", "Cible prescrite."),
    ], custom=True, invariants=["Au moins une mesure parmi `reps`, `seconds`, `distanceMeters`, `calories`."]),
    Type("TrainingBreak", "journal", "Pause déclarée (vacances, maladie…) : ni manquement ni perte de série.", [
        F("startDate", "date", "Premier jour de la pause."),
        F("endDate", "date?", "Dernier jour de la pause (absent : en cours)."),
        F("reason", "enum:BreakReason", "Motif."),
    ], custom=True, invariants=["`startDate` ≤ `endDate`."]),
    Type("ProgramRef", "journal", "Place d'une séance dans le programme.", [
        F("blockId", "string", "Identifiant du bloc.", min_len=1),
        F("weekIndex", "int", "Semaine dans le bloc (0 = première).", min=0),
        F("dayIndex", "int", "Rang du jour dans la semaine du bloc, celui de `DayPrescription.dayIndex` (0 = premier).", min=0),
    ]),
    Type("SessionRecord", "journal", "Séance du journal. Dates en jours civils.", [
        F("id", "string", "Identifiant unique de la séance.", min_len=1),
        F("date", "date", "Jour civil de la séance."),
        F("origin", "enum:SessionOrigin", "Origine."),
        F("programRef", "obj:ProgramRef?", "Place dans le programme."),
        F("resume", "bool", "Marqueur « reprise » (D4.9) : séance neutre, ignorée des moteurs (ni XP, ni statistiques, ni série, ni records)."),
        F("completed", "bool", "Séance terminée."),
        F("durationMinutes", "int?", "Durée de la séance, en minutes.", min=0, max=600),
        F("bodyWeightKg", "double?", "Poids de corps du jour, en kg.", min=25, max=300),
        F("place", "enum:Place?", "Lieu de la séance."),
        F("healthCheck", "obj:HealthCheck?", "Bilan santé de début de séance."),
        F("sets", "list:obj:SetRecord", "Séries, dans l'ordre de réalisation."),
        F("pains", "list:obj:PainReport", "Douleurs signalées pendant ou après la séance."),
        F("plannedWorkSets", "int?", "Nombre de séries de travail prescrites pour cette séance, telle qu'elle a été affichée (après l'ajustement du bilan santé, de la douleur, du lieu et du temps du jour) (0.3.0). Sert à `kalis_quest` pour rapporter l'effort au programme : une séance allégée et faite en entier vaut une séance complète.", min=0, max=500),
    ]),
    Type("TrainingLog", "journal", "Journal de séances.", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("sessions", "list:obj:SessionRecord", "Séances, par date croissante."),
        F("breaks", "list:obj:TrainingBreak?", "Pauses déclarées."),
    ], schema_version=1, custom=True, invariants=["Identifiants de séance uniques ; dates croissantes (au sens large)."]),
    # ======================= plan =======================
    Type("PlanLock", "plan", "Verrou : ce que la revue a figé (D4.6).", [
        F("kind", "enum:LockKind", "Nature du verrou."),
        F("dayIndex", "int?", "Jour concerné.", min=0),
        F("slotId", "string?", "Emplacement concerné."),
        F("exerciseId", "string?", "Exercice concerné.", **EXID),
    ], custom=True, invariants=["`keep_slot` : `slotId` et `exerciseId` ; `require_exercise`, `exclude_exercise` : `exerciseId` ; `keep_day` : `dayIndex`."]),
    Type("PlanSlot", "plan", "Exercice placé dans une séance (passe 1).", [
        F("slotId", "string", "Identifiant stable de l'emplacement dans le bloc.", min_len=1),
        F("exerciseId", "string", "Exercice.", **EXID),
        F("role", "enum:SlotRole", "Rôle dans la séance."),
        F("locked", "bool", "Validé par l'utilisateur : ne bouge plus."),
        F("reasons", "list:obj:Reason", "Pourquoi cet exercice."),
    ]),
    Type("PlanDay", "plan", "Séance type d'un jour d'entraînement (passe 1).", [
        F("dayIndex", "int", "Rang du jour d'entraînement dans la semaine (0 = premier).", min=0),
        F("weekday", "int", "Jour ISO : 1 = lundi … 7 = dimanche.", min=1, max=7),
        F("minutesBudget", "int", "Durée prévue, en minutes.", min=0, max=300),
        F("focus", "string", "Code du thème de la séance."),
        F("slots", "list:obj:PlanSlot", "Exercices, dans l'ordre."),
    ]),
    Type("ScoreComponent", "plan", "Composante de la note d'un programme (D4.2).", [
        F("code", "string", "Code de la composante.", min_len=1),
        F("value", "double", "Valeur, de 0 à 1.", min=0, max=1),
        F("weight", "double", "Poids dans la note.", min=0),
    ]),
    Type("PlanScore", "plan", "Note d'un programme candidat.", [
        F("total", "double", "Note globale, de 0 à 1.", min=0, max=1),
        F("components", "list:obj:ScoreComponent", "Détail."),
    ]),
    Type("Pass1Plan", "plan", "Passe 1 : le bloc, ses jours, ses exercices et leurs rôles, sans séries ni répétitions (D4.4). C'est la semaine type du bloc ; la passe 2 fait foi semaine par semaine.", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("blockId", "string", "Identifiant du bloc.", min_len=1),
        F("blockIndex", "int", "Rang du bloc dans le programme (0 = premier).", min=0),
        F("weeks", "int", "Durée du bloc, en semaines. `kalis_plan` produit des blocs de 4 à 6 semaines (D4.8) ; un programme importé (celui du propriétaire, D5.10) peut en compter jusqu'à 52.", min=1, max=52),
        F("startDate", "date", "Premier jour du bloc."),
        F("seed", "int", "Graine utilisée.", min=0),
        F("engineVersion", "string", "Version de kalis_plan."),
        F("days", "list:obj:PlanDay", "Jours d'entraînement."),
        F("score", "obj:PlanScore", "Note du programme retenu."),
        F("reasons", "list:obj:Reason", "Raisons au niveau du bloc."),
    ], schema_version=1, custom=True, invariants=["`dayIndex` = rang dans `days` ; `slotId` uniques dans le bloc."]),
    Type("ReviewAction", "plan", "Action de revue de la passe 1 (D4.5).", [
        F("kind", "enum:ReviewKind", "Action."),
        F("slotId", "string?", "Emplacement visé."),
        F("dayIndex", "int?", "Jour visé (ajout).", min=0),
        F("exerciseId", "string?", "Exercice ajouté.", **EXID),
        F("replacementExerciseId", "string?", "Variante choisie (remplacement).", **EXID),
    ], custom=True, invariants=["`can_do`, `cannot_do`, `dislike`, `remove` : `slotId` ; `add` : `dayIndex` et `exerciseId` ; `replace` : `slotId` et `replacementExerciseId`."]),
    Type("ProfileDelta", "plan", "Ce que la revue apprend sur l'utilisateur (à reporter dans le profil par l'application).", [
        F("knownExerciseIds", "list:string", "« Je sais faire ».", **EXID),
        F("unknownExerciseIds", "list:string", "« Je ne sais pas faire ».", **EXID),
        F("likedExerciseIds", "list:string", "Exercices ajoutés parce qu'aimés.", **EXID),
        F("dislikedExerciseIds", "list:string", "« Je n'aime pas ».", **EXID),
    ]),
    Type("PlanChange", "plan", "Changement typé entre deux programmes.", [
        F("kind", "enum:ChangeKind", "Nature du changement."),
        F("dayIndex", "int?", "Jour concerné.", min=0),
        F("weekIndex", "int?", "Semaine concernée (prescriptions).", min=0),
        F("slotId", "string?", "Emplacement concerné."),
        F("fromExerciseId", "string?", "Exercice avant.", **EXID),
        F("toExerciseId", "string?", "Exercice après.", **EXID),
        F("fromDayIndex", "int?", "Jour d'origine (déplacement).", min=0),
        F("fromPrescription", "obj:ExercisePrescription?", "Prescription avant (`prescription_changed`)."),
        F("toPrescription", "obj:ExercisePrescription?", "Prescription après (`prescription_changed`) : appliquer le changement = remplacer la prescription de (`weekIndex`, `dayIndex`, `slotId`) par celle-ci."),
        F("reasons", "list:obj:Reason", "Pourquoi."),
    ]),
    Type("PlanDiff", "plan", "Ce qui a bougé entre deux programmes, et pourquoi (D4.6).", [
        F("changes", "list:obj:PlanChange", "Changements, dans un ordre stable."),
    ]),
    Type("ReviewResult", "plan", "Résultat d'une action de revue : programme ré-optimisé, diff, verrous à jour.", [
        F("plan", "obj:Pass1Plan", "Programme après l'action."),
        F("diff", "obj:PlanDiff", "Ce qui a bougé."),
        F("locks", "list:obj:PlanLock", "Verrous à repasser dans la requête suivante."),
        F("profileDelta", "obj:ProfileDelta", "Ce que l'action apprend sur l'utilisateur."),
    ]),
    Type("Variant", "plan", "Variante proposée pour un emplacement.", [
        F("exerciseId", "string", "Exercice proposé.", **EXID),
        F("kind", "enum:VariantKind", "Plus facile, équivalente, autre matériel, autre."),
        F("similarity", "double", "Proximité avec l'exercice remplacé, de 0 à 1.", min=0, max=1),
        F("reasons", "list:obj:Reason", "Pourquoi."),
    ]),
    Type("VariantSet", "plan", "Variantes d'un emplacement : 3 ciblées + toutes (D4.5).", [
        F("slotId", "string", "Emplacement.", min_len=1),
        F("targeted", "list:obj:Variant", "Jusqu'à 3 variantes ciblées.", max_len=3),
        F("all", "list:obj:Variant", "Toutes les variantes admissibles, par proximité décroissante."),
    ]),
    Type("ExercisePrescription", "plan", "Prescription d'un exercice pour une séance (passe 2, D4.7).", [
        F("slotId", "string", "Emplacement.", min_len=1),
        F("exerciseId", "string", "Exercice.", **EXID),
        F("sets", "int", "Nombre de séries.", min=1, max=20),
        F("repsLow", "int?", "Bas de la plage de répétitions.", min=1, max=1000),
        F("repsHigh", "int?", "Haut de la plage de répétitions.", min=1, max=1000),
        F("secondsLow", "int?", "Bas de la plage de temps, en secondes.", min=1, max=86400),
        F("secondsHigh", "int?", "Haut de la plage de temps, en secondes.", min=1, max=86400),
        F("distanceMeters", "double?", "Distance par série, en mètres.", min=0),
        F("calories", "double?", "Calories par série.", min=0),
        F("targetFlames", "int?", "Flammes visées (absent : sans cible de difficulté — mobilité, échauffement).", min=1, max=10),
        F("restSeconds", "int?", "Repos entre les séries, en secondes (absent : libre).", min=0, max=900),
        F("startLoadKg", "double?", "Charge externe de départ, en kg (prudente ; même convention que `SetRecord.externalLoadKg`).", min=-300, max=1000),
        F("percentOfOneRm", "double?", "Charge exprimée en part du 1RM de charge totale, de 0 à 1,5 (programme importé, ou repère du moteur).", min=0, max=1.5),
        F("toCalibrate", "bool", "Charge à calibrer sur les premières séances."),
        F("loadBasis", "enum:LoadBasis", "Ce que désigne la charge."),
        F("setTargets", "list:obj:SetTarget?", "Cible série par série, quand les séries diffèrent (montée de calibrage, série lourde puis séries allégées) ; sa longueur est `sets`. Absent : toutes les séries suivent la prescription."),
        F("groupId", "string?", "Groupe d'exercices enchaînés dans la séance (superset, tours, circuit) : même valeur pour les membres du groupe."),
        F("format", "string?", "Code du format du groupe ou de l'exercice (`superset`, `rounds`, `amrap`, `emom`, `intervals`…)."),
        F("kind", "enum:SetKind?", "Rôle des séries (absent : travail) ; `test` pour une séance de test."),
        F("reasons", "list:obj:Reason", "Pourquoi."),
    ], custom=True, invariants=["Une seule famille de mesure : répétitions, temps, distance ou calories ; bornes basses ≤ bornes hautes, renseignées ensemble ; `setTargets`, s'il est présent, a `sets` éléments."]),
    Type("DayPrescription", "plan", "Prescriptions d'une séance.", [
        F("dayIndex", "int", "Jour d'entraînement.", min=0),
        F("items", "list:obj:ExercisePrescription", "Exercices, dans l'ordre."),
    ]),
    Type("WeekPrescription", "plan", "Prescriptions d'une semaine du bloc.", [
        F("weekIndex", "int", "Semaine dans le bloc (0 = première).", min=0),
        F("kind", "enum:WeekKind", "Nature de la semaine."),
        F("days", "list:obj:DayPrescription", "Séances."),
    ]),
    Type("Pass2Plan", "plan", "Passe 2 : prescriptions par semaine.", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("blockId", "string", "Identifiant du bloc (celui de la passe 1).", min_len=1),
        F("engineVersion", "string", "Version de kalis_plan."),
        F("weeks", "list:obj:WeekPrescription", "Semaines du bloc."),
        F("reasons", "list:obj:Reason", "Logique du bloc."),
    ], schema_version=1, custom=True, invariants=["`weekIndex` = rang dans `weeks`."]),
    Type("ProgramBlock", "plan", "Bloc de programme complet (passes 1 et 2), stocké par l'application.", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("pass1", "obj:Pass1Plan", "Passe 1."),
        F("pass2", "obj:Pass2Plan", "Passe 2."),
    ], schema_version=1, custom=True, invariants=["Même `blockId` ; autant de semaines de passe 2 que `pass1.weeks` ; `slotId` uniques dans une séance ; chaque séance prescrite renvoie à un jour de la passe 1. La passe 2 fait foi : une semaine peut prescrire un autre exercice que la semaine type pour un emplacement (échange en cours de bloc, semaine de test), ou un emplacement propre à cette semaine."]),
    # ======================= adapt =======================
    Type("ExerciseEstimate", "adapt", "Capacité estimée sur un exercice (D5.2).", [
        F("exerciseId", "string", "Exercice.", **EXID),
        F("unit", "enum:CapacityUnit", "Unité de la capacité."),
        F("capacity", "double", "Capacité estimée, dans l'unité `unit` (1RM de charge TOTALE en kg, répétitions max, tenue max, vitesse).", min=0),
        F("standardError", "double", "Écart-type de l'estimation, même unité.", min=0),
        F("weeklyTrend", "double", "Tendance par semaine, même unité."),
        F("observations", "int", "Nombre de séries utilisées.", min=0),
        F("lastObservedOn", "date?", "Dernière séance observée."),
    ]),
    Type("FatigueState", "adapt", "État du modèle forme / fatigue.", [
        F("fitness", "double", "Forme (unités arbitraires du modèle).", min=0),
        F("fatigue", "double", "Fatigue (unités arbitraires du modèle).", min=0),
        F("readiness", "double", "Forme du jour, de 0 à 1.", min=0, max=1),
    ]),
    Type("PainTrend", "adapt", "Suivi d'une zone douloureuse.", [
        F("zone", "enum:BodyZone", "Zone."),
        F("side", "enum:BodySide", "Côté."),
        F("sessionsReported", "int", "Séances où elle a été signalée.", min=0),
        F("lastIntensity", "int", "Dernière intensité, de 0 à 10.", min=0, max=10),
        F("consecutiveAboveThreshold", "int", "Séances de suite au-dessus du seuil de la règle santé L13.", min=0),
    ]),
    Type("AdaptationSummary", "adapt", "Résumé d'adaptation : ce que le moteur dynamique a appris (entrée de `PlanEngine.nextBlock`).", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("asOf", "date", "Jour du résumé."),
        F("weeksObserved", "int", "Semaines de données réelles.", min=0),
        F("sessionsPlanned", "int", "Séances prévues sur la période.", min=0),
        F("sessionsCompleted", "int", "Séances terminées (hors « reprise »).", min=0),
        F("unlockLevel", "enum:UnlockLevel", "Niveau de déblocage atteint (D5.7)."),
        F("confidence", "double", "Confiance globale du modèle, de 0 à 1.", min=0, max=1),
        F("estimates", "list:obj:ExerciseEstimate", "Capacités estimées."),
        F("fatigue", "obj:FatigueState?", "Forme et fatigue."),
        F("pains", "list:obj:PainTrend", "Zones douloureuses suivies."),
        F("avoidedExerciseIds", "list:string", "Exercices régulièrement sautés ou refusés.", **EXID),
        F("reasons", "list:obj:Reason", "Faits marquants."),
    ], schema_version=1),
    Type("AdaptInput", "adapt", "Entrée du moteur dynamique.", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("profile", "obj:AthleteProfile", "Profil."),
        F("block", "obj:ProgramBlock", "Bloc en cours."),
        F("log", "obj:TrainingLog", "Journal complet."),
        F("today", "date", "« Aujourd'hui », fourni par l'application."),
        F("state", "json?", "État opaque rendu par le dernier appel (propriété de kalis_adapt)."),
        F("decisions", "list:obj:ProposalDecision?", "Suites données aux propositions passées (D5.6, D9.2)."),
    ], schema_version=1),
    Type("SessionRequest", "adapt", "Requête de prescription de la séance du jour.", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("input", "obj:AdaptInput", "Profil, bloc, journal, « aujourd'hui », état."),
        F("weekIndex", "int", "Semaine dans le bloc.", min=0),
        F("dayIndex", "int", "Jour d'entraînement.", min=0),
        F("healthCheck", "obj:HealthCheck?", "Bilan santé du jour (une réponse absente n'est jamais remplacée)."),
        F("place", "enum:Place?", "Lieu du jour, s'il diffère du lieu prévu."),
    ], schema_version=1),
    Type("AdviceRequest", "adapt", "Requête de conseil pour la série suivante.", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("input", "obj:AdaptInput", "Profil, bloc, journal, « aujourd'hui », état."),
        F("session", "obj:SessionPlan", "Séance en cours."),
        F("done", "list:obj:SetRecord", "Séries déjà faites dans la séance, dans l'ordre."),
        F("slotId", "string", "Emplacement de l'exercice dont on demande la série suivante.", min_len=1),
        F("healthCheck", "obj:HealthCheck?", "Bilan santé du jour, tel qu'il a été donné à `prescribeSession` (0.2.0 ; une réponse absente n'est jamais remplacée)."),
    ], schema_version=1),
    Type("ProposalDecision", "adapt", "Suite donnée par l'utilisateur (ou par le mode assisté) à une proposition.", [
        F("proposalId", "string", "Proposition concernée.", min_len=1),
        F("date", "date", "Jour de la décision."),
        F("status", "enum:ProposalStatus", "Suite donnée."),
    ]),
    Type("PersonalRecord", "adapt", "Record personnel établi sur un exercice.", [
        F("exerciseId", "string", "Exercice.", **EXID),
        F("kind", "enum:RecordKind", "Nature du record."),
        F("value", "double", "Valeur, dans l'unité de `kind` (charge TOTALE pour `one_rm_kg`).", min=0),
        F("date", "date", "Jour du record."),
        F("sessionId", "string?", "Séance du record."),
        F("previousValue", "double?", "Record précédent.", min=0),
    ]),
    Type("SessionAdjustment", "adapt", "Ajustement d'une séance (bilan santé, douleur, temps disponible : D5.9).", [
        F("kind", "enum:AdjustmentKind", "Nature."),
        F("exerciseId", "string?", "Exercice concerné.", **EXID),
        F("replacementExerciseId", "string?", "Exercice de remplacement.", **EXID),
        F("loadFactor", "double?", "Facteur appliqué à la charge.", min=0, max=2),
        F("setsDelta", "int?", "Séries ajoutées (négatif = retirées).", min=-20, max=20),
        F("reasons", "list:obj:Reason", "Pourquoi."),
    ]),
    Type("SessionPlan", "adapt", "Prescription de la séance du jour, ajustée.", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("date", "date", "Jour de la séance."),
        F("blockId", "string", "Bloc.", min_len=1),
        F("weekIndex", "int", "Semaine dans le bloc.", min=0),
        F("dayIndex", "int", "Jour d'entraînement.", min=0),
        F("items", "list:obj:ExercisePrescription", "Exercices prescrits."),
        F("adjustments", "list:obj:SessionAdjustment", "Ajustements par rapport au bloc."),
        F("confidence", "double", "Confiance, de 0 à 1.", min=0, max=1),
        F("reasons", "list:obj:Reason", "Pourquoi."),
    ], schema_version=1),
    Type("IntraSessionAdvice", "adapt", "Ajustement intra-séance : conseil pour la série suivante.", [
        F("exerciseId", "string", "Exercice.", **EXID),
        F("action", "enum:IntraSessionAction", "Conseil."),
        F("nextLoadKg", "double?", "Charge externe conseillée, en kg.", min=-300, max=1000),
        F("nextRepsLow", "int?", "Bas de la plage conseillée.", min=0, max=1000),
        F("nextRepsHigh", "int?", "Haut de la plage conseillée.", min=0, max=1000),
        F("nextSeconds", "int?", "Durée conseillée, en secondes (tenues).", min=0, max=86400),
        F("slotId", "string?", "Emplacement concerné."),
        F("restSeconds", "int?", "Repos conseillé, en secondes.", min=0, max=900),
        F("confidence", "double", "Confiance, de 0 à 1.", min=0, max=1),
        F("reasons", "list:obj:Reason", "Pourquoi."),
    ]),
    Type("Proposal", "adapt", "Proposition du moteur dynamique (D5.6, D5.7).", [
        F("id", "string", "Identifiant stable.", min_len=1),
        F("kind", "enum:ProposalKind", "Type."),
        F("scope", "enum:ProposalScope", "Portée."),
        F("createdOn", "date", "Jour de création."),
        F("confidence", "double", "Confiance, de 0 à 1.", min=0, max=1),
        F("unlockLevel", "enum:UnlockLevel", "Niveau de déblocage requis."),
        F("autoApplicable", "bool", "Applicable automatiquement en mode assisté."),
        F("exerciseId", "string?", "Exercice concerné.", **EXID),
        F("diff", "obj:PlanDiff?", "Changement de programme proposé."),
        F("block", "obj:ProgramBlock?", "Bloc résultant, pour une restructuration."),
        F("reasons", "list:obj:Reason", "Pourquoi."),
    ]),
    Type("EngineLogEntry", "adapt", "Entrée du journal du moteur (inspecteur et export du mode dev, D2.5).", [
        F("sequence", "int", "Rang dans le journal.", min=0),
        F("date", "date", "Jour."),
        F("engine", "string", "Moteur (`plan`, `adapt`, `quest`).", min_len=1),
        F("event", "string", "Code de l'événement.", min_len=1),
        F("confidence", "double?", "Confiance de la décision.", min=0, max=1),
        F("reasons", "list:obj:Reason", "Raisons."),
        F("data", "json", "Détail (scores, valeurs du modèle)."),
    ]),
    Type("AdaptReview", "adapt", "Résultat d'une revue du moteur dynamique.", [
        F("summary", "obj:AdaptationSummary", "Résumé d'adaptation."),
        F("proposals", "list:obj:Proposal", "Propositions."),
        F("state", "json", "État opaque à repasser au prochain appel."),
        F("log", "list:obj:EngineLogEntry", "Entrées de journal du moteur."),
        F("records", "list:obj:PersonalRecord?", "Records personnels établis d'après le journal."),
    ]),
    # ======================= quest =======================
    Type("XpEntry", "quest", "Écriture du registre d'XP (ajout seul, D7.3).", [
        F("sequence", "int", "Rang dans le registre.", min=0),
        F("date", "date", "Jour."),
        F("source", "enum:XpSource", "Origine."),
        F("amount", "int", "XP gagnés (jamais négatifs).", min=0),
        F("sessionId", "string?", "Séance à l'origine."),
        F("refId", "string?", "Quête, objectif ou record à l'origine."),
        F("reasons", "list:obj:Reason", "Pourquoi."),
    ]),
    Type("KreditEntry", "quest", "Écriture du registre de Krédits (D7.7).", [
        F("sequence", "int", "Rang dans le registre.", min=0),
        F("date", "date", "Jour."),
        F("source", "enum:KreditSource", "Origine."),
        F("amount", "int", "Krédits gagnés.", min=0),
        F("refId", "string?", "Référence de l'origine."),
    ]),
    Type("LevelState", "quest", "Niveau et prestige (D7.4).", [
        F("level", "int", "Niveau.", min=1, max=100),
        F("prestige", "int", "Prestige.", min=0),
        F("totalXp", "int", "XP acquis à vie.", min=0),
        F("xpIntoLevel", "int", "XP dans le niveau en cours.", min=0),
        F("xpForNextLevel", "int", "XP du niveau en cours au suivant.", min=0),
    ]),
    Type("AttributeScore", "quest", "Attribut façon RPG (D7.5).", [
        F("attribute", "enum:AthleteAttribute", "Attribut."),
        F("value", "double", "Valeur, de 0 à 100.", min=0, max=100),
        F("best", "double?", "Meilleure valeur atteinte, de 0 à 100 (0.3.0) : elle ne baisse jamais, alors que `value` reflète le niveau actuel.", min=0, max=100),
    ]),
    Type("MovementRank", "quest", "Rang sur un mouvement (D7.5).", [
        F("exerciseId", "string", "Mouvement.", **EXID),
        F("tier", "enum:MovementRankTier", "Rang."),
        F("score", "double", "Performance normalisée utilisée pour le rang (échelle définie et publiée par kalis_quest : standards par sexe et poids de corps).", min=0),
        F("nextTierAt", "double?", "Performance normalisée du rang suivant, même échelle.", min=0),
    ]),
    Type("Quest", "quest", "Quête (D7.6).", [
        F("id", "string", "Identifiant.", min_len=1),
        F("kind", "enum:QuestKind", "Famille."),
        F("template", "string", "Code du modèle de quête.", min_len=1),
        F("params", "json", "Paramètres du modèle."),
        F("startsOn", "date", "Début."),
        F("endsOn", "date?", "Fin."),
        F("progress", "double", "Avancement.", min=0),
        F("target", "double", "Cible.", min=0),
        F("status", "enum:QuestStatus", "État."),
        F("rewardXp", "int", "XP à la clé.", min=0),
        F("rewardKredits", "int", "Krédits à la clé.", min=0),
        F("reasons", "list:obj:Reason", "Pourquoi cette quête."),
    ]),
    Type("Milestone", "quest", "Jalon automatique d'un objectif.", [
        F("fraction", "double", "Part de l'objectif, de 0 à 1.", min=0, max=1),
        F("reachedOn", "date?", "Jour d'atteinte."),
    ]),
    Type("Prediction", "quest", "Prédiction de la date d'atteinte d'un objectif.", [
        F("expectedOn", "date", "Date attendue."),
        F("earliestOn", "date", "Borne basse."),
        F("latestOn", "date", "Borne haute."),
        F("confidence", "double", "Confiance, de 0 à 1.", min=0, max=1),
        F("method", "string", "Code de la méthode.", min_len=1),
    ], custom=True, invariants=["`earliestOn` ≤ `expectedOn` ≤ `latestOn`."]),
    Type("GoalProgress", "quest", "Avancement d'un objectif du profil.", [
        F("goalId", "string", "Objectif.", min_len=1),
        F("current", "double", "Valeur actuelle, dans l'unité de l'objectif (`Goal.metric` ; séances faites pour une habitude)."),
        F("target", "double", "Valeur cible, même unité."),
        F("fraction", "double", "Avancement, de 0 à 1.", min=0, max=1),
        F("achievedOn", "date?", "Jour d'atteinte."),
        F("milestones", "list:obj:Milestone", "Jalons."),
        F("prediction", "obj:Prediction?", "Prédiction."),
        F("baseline", "double?", "Valeur de départ, mesurée à la création de l'objectif, même unité (0.3.0)."),
        F("overdue", "bool?", "Vrai si l'objectif est en retard : la date prédite dépasse l'échéance, ou la cible est hors d'atteinte au rythme actuel (0.3.0)."),
        F("suggestedDate", "date?", "Échéance proposée pour un objectif en retard, cible inchangée (0.3.0)."),
        F("suggestedTarget", "double?", "Cible proposée pour un objectif en retard, échéance inchangée, même unité (0.3.0).", min=0),
        F("reasons", "list:obj:Reason?", "Pourquoi (prédiction mise à jour, retard) (0.3.0)."),
    ]),
    Type("DelightEvent", "quest", "Événement de plaisir (D8.1).", [
        F("kind", "enum:DelightKind", "Nature."),
        F("date", "date", "Jour."),
        F("sessionId", "string?", "Séance."),
        F("exerciseId", "string?", "Exercice.", **EXID),
        F("recordKind", "enum:RecordKind?", "Nature du record."),
        F("value", "double?", "Valeur atteinte."),
        F("previousValue", "double?", "Valeur précédente."),
        F("grade", "enum:SessionGrade?", "Note de séance."),
        F("combo", "int?", "Longueur du combo.", min=0),
        F("streakWeeks", "int?", "Série de semaines.", min=0),
        F("kredits", "int?", "Krédits du coffre.", min=0),
        F("reasons", "list:obj:Reason", "Raisons."),
    ]),
    Type("QuestState", "quest", "État persistant du leveling, stocké par l'application.", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("xp", "list:obj:XpEntry", "Registre d'XP."),
        F("kredits", "list:obj:KreditEntry", "Registre de Krédits."),
        F("quests", "list:obj:Quest", "Quêtes en cours et passées."),
        F("lastEvaluatedOn", "date?", "Dernier jour évalué."),
        F("data", "json", "État opaque de kalis_quest."),
    ], schema_version=1, custom=True, invariants=["Registres en ajout seul : `sequence` = rang dans la liste (0, 1, 2…) ; dates croissantes au sens large."]),
    Type("QuestClaim", "quest", "Déclaration de l'utilisateur : une quête déclarative (récupération d'un jour de repos : sommeil, hydratation, marche légère…) est faite (0.3.0).", [
        F("questId", "string", "Quête déclarée faite.", min_len=1),
        F("date", "date", "Jour de la déclaration."),
    ]),
    Type("QuestInput", "quest", "Entrée du moteur de leveling.", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("profile", "obj:AthleteProfile", "Profil."),
        F("log", "obj:TrainingLog", "Journal complet."),
        F("block", "obj:ProgramBlock?", "Bloc en cours."),
        F("adaptation", "obj:AdaptationSummary?", "Résumé d'adaptation."),
        F("state", "obj:QuestState", "État précédent."),
        F("today", "date", "« Aujourd'hui », fourni par l'application."),
        F("seed", "int?", "Graine de l'utilisateur pour les tirages (coffres, quêtes du jour) ; le moteur la combine à la date.", min=0),
        F("claims", "list:obj:QuestClaim?", "Quêtes déclaratives que l'utilisateur dit avoir faites depuis le dernier appel (0.3.0). Une déclaration déjà prise en compte peut être redonnée sans effet."),
    ], schema_version=1),
    Type("QuestOutcome", "quest", "Résultat du moteur de leveling.", [
        F("state", "obj:QuestState", "Nouvel état (les registres ne perdent jamais d'écriture)."),
        F("level", "obj:LevelState", "Niveau et prestige."),
        F("attributes", "list:obj:AttributeScore", "Attributs."),
        F("ranks", "list:obj:MovementRank", "Rangs par mouvement."),
        F("goals", "list:obj:GoalProgress", "Avancement des objectifs."),
        F("events", "list:obj:DelightEvent", "Événements de plaisir nouveaux."),
        F("kreditBalance", "int", "Solde de Krédits.", min=0),
        F("weekStreak", "int?", "Série de semaines en cours.", min=0),
        F("suggestedGoals", "list:obj:Goal?", "Objectifs suggérés par Koach d'après le profil et les données (D3.8), à proposer à l'utilisateur."),
        F("records", "list:obj:PersonalRecord?", "Records personnels connus."),
        F("extras", "json?", "Données de présentation propres à kalis_quest (récapitulatif hebdomadaire, comparaisons dans le temps, fantôme), documentées par ce paquet."),
    ]),
    # ---- requêtes du plan (après AdaptationSummary et ProgramBlock) ----
    Type("PlanRequest", "plan", "Requête de création d'un programme.", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("profile", "obj:AthleteProfile", "Profil."),
        F("seed", "int", "Graine (« Autre proposition » = nouvelle graine, D4.3).", min=0),
        F("startDate", "date", "Premier jour du bloc."),
        F("blockWeeks", "int?", "Durée souhaitée du bloc, en semaines.", min=4, max=6),
        F("locks", "list:obj:PlanLock", "Verrous."),
        F("previousBlock", "obj:ProgramBlock?", "Bloc précédent."),
        F("adaptation", "obj:AdaptationSummary?", "Résumé d'adaptation."),
    ], schema_version=1),
    Type("NextBlockRequest", "plan", "Requête du bloc suivant (D4.8).", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("profile", "obj:AthleteProfile", "Profil."),
        F("seed", "int", "Graine.", min=0),
        F("startDate", "date", "Premier jour du nouveau bloc."),
        F("previous", "obj:ProgramBlock", "Bloc qui se termine."),
        F("adaptation", "obj:AdaptationSummary", "Résumé d'adaptation."),
        F("locks", "list:obj:PlanLock", "Verrous."),
    ], schema_version=1),
    Type("RestructureRequest", "plan", "Requête de restructuration (D5.1 : le moteur dynamique appelle le statique).", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("profile", "obj:AthleteProfile", "Profil."),
        F("seed", "int", "Graine.", min=0),
        F("today", "date", "« Aujourd'hui »."),
        F("current", "obj:ProgramBlock", "Bloc en cours."),
        F("scope", "enum:RestructureScope", "Portée."),
        F("dayIndex", "int?", "Jour visé (portée séance).", min=0),
        F("fromWeekIndex", "int?", "Première semaine modifiable.", min=0),
        F("reasons", "list:obj:Reason", "Raisons de la restructuration."),
        F("locks", "list:obj:PlanLock", "Verrous."),
        F("adaptation", "obj:AdaptationSummary?", "Résumé d'adaptation."),
    ], schema_version=1, custom=True, invariants=["Portée `session` ⇒ `dayIndex` renseigné."]),
    Type("ReviewRequest", "plan", "Requête d'action de revue de la passe 1.", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("request", "obj:PlanRequest", "Requête de création (avec les verrous déjà posés)."),
        F("current", "obj:Pass1Plan", "Programme en cours de revue."),
        F("action", "obj:ReviewAction", "Action de l'utilisateur."),
    ], schema_version=1),
    Type("VariantsRequest", "plan", "Requête de variantes pour un emplacement.", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("request", "obj:PlanRequest", "Requête de création."),
        F("current", "obj:Pass1Plan", "Programme en cours de revue."),
        F("slotId", "string", "Emplacement.", min_len=1),
    ], schema_version=1),
    Type("Pass2Request", "plan", "Requête de passe 2.", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("request", "obj:PlanRequest", "Requête de création."),
        F("pass1", "obj:Pass1Plan", "Passe 1 validée par l'utilisateur."),
    ], schema_version=1),
    Type("BlockProposal", "plan", "Bloc proposé et ce qui change par rapport au précédent.", [
        F("block", "obj:ProgramBlock", "Bloc proposé."),
        F("diff", "obj:PlanDiff", "Changements par rapport au bloc de référence."),
    ]),
]

# Registre des codes de raison : (code, {paramètre: type}, sens).
# Types : int, double, string, bool, exercise (identifiant du catalogue).
REASONS: list[tuple[str, dict[str, str], str]] = [
    # ---- plan ----
    ("plan.discipline_share", {"discipline": "string", "pct": "int"}, "Exercice ou séance choisi pour respecter le dosage d'une discipline."),
    ("plan.movement_coverage", {"pattern": "string"}, "Couvre un schéma de mouvement qui manquait."),
    ("plan.muscle_volume", {"muscle": "string", "weeklySets": "double", "targetLow": "double", "targetHigh": "double"}, "Ramène le volume hebdomadaire d'un muscle dans sa plage."),
    ("plan.fatigue_balance", {"dayIndex": "int"}, "Répartit la fatigue entre les séances."),
    ("plan.time_budget", {"minutes": "int"}, "Tient dans le temps disponible ce jour-là."),
    ("plan.equipment_available", {"place": "string"}, "Faisable avec le matériel et le lieu du profil."),
    ("plan.equipment_missing", {"equipment": "string"}, "Écarté : matériel absent du profil."),
    ("plan.level_match", {"difficulty": "int"}, "Difficulté adaptée au niveau déclaré."),
    ("plan.prerequisite_missing", {"exerciseId": "exercise"}, "Écarté : un palier précédent n'est pas acquis."),
    ("plan.joint_limitation", {"joint": "string", "discomfort": "int"}, "Écarté ou remplacé : contrainte sur une articulation limitée."),
    ("plan.user_likes", {}, "Exercice aimé par l'utilisateur."),
    ("plan.user_dislikes", {}, "Écarté : l'utilisateur n'aime pas cet exercice."),
    ("plan.user_cannot_do", {}, "Remplacé : l'utilisateur ne sait pas le faire."),
    ("plan.user_added", {}, "Ajouté à la demande de l'utilisateur."),
    ("plan.user_removed", {}, "Retiré à la demande de l'utilisateur."),
    ("plan.user_replaced", {}, "Variante choisie par l'utilisateur."),
    ("plan.lock_kept", {}, "Inchangé : validé par l'utilisateur."),
    ("plan.goal_support", {"goalId": "string"}, "Sert un objectif du profil."),
    ("plan.variety", {}, "Évite une redondance avec un exercice déjà présent."),
    ("plan.reoptimized", {"scoreBefore": "double", "scoreAfter": "double"}, "A bougé parce que le reste du programme a été ré-optimisé."),
    ("plan.variant_easier", {"difficultyDelta": "int"}, "Variante plus facile."),
    ("plan.variant_equivalent", {"similarity": "double"}, "Variante équivalente."),
    ("plan.variant_other_equipment", {"equipment": "string"}, "Variante avec un autre matériel."),
    ("plan.start_load_conservative", {"fractionOfEstimate": "double"}, "Charge de départ prudente."),
    ("plan.to_calibrate", {}, "Charge à caler sur les premières séances."),
    ("plan.week_kind", {"kind": "string"}, "Logique de la semaine (introduction, montée, décharge, test)."),
    ("plan.progression_from_previous_block", {"exerciseId": "exercise"}, "Reprend ou fait progresser un exercice du bloc précédent."),
    ("plan.adaptation_applied", {"proposalKind": "string"}, "Tient compte du résumé d'adaptation."),
    ("plan.cautious_health", {}, "Programme prudent : questionnaire santé en mode prudent."),
    ("plan.restructure_scope", {"scope": "string"}, "Restructuration limitée à cette portée."),
    # ---- adapt ----
    ("adapt.flames_below_target", {"delta": "double", "sets": "int"}, "Séries notées plus faciles que la cible."),
    ("adapt.flames_above_target", {"delta": "double", "sets": "int"}, "Séries notées plus dures que la cible."),
    ("adapt.set_failed", {"missingReps": "int"}, "Série manquée."),
    ("adapt.load_up", {"deltaKg": "double"}, "Charge augmentée."),
    ("adapt.load_down", {"deltaKg": "double"}, "Charge diminuée."),
    ("adapt.reps_up", {"delta": "int"}, "Répétitions augmentées."),
    ("adapt.reps_down", {"delta": "int"}, "Répétitions diminuées."),
    ("adapt.volume_up", {"sets": "int"}, "Séries ajoutées."),
    ("adapt.volume_down", {"sets": "int"}, "Séries retirées."),
    ("adapt.calibration", {"session": "int"}, "Séance de calibrage : la charge se cale."),
    ("adapt.estimate_updated", {"exerciseId": "exercise", "capacity": "double", "standardError": "double"}, "Capacité estimée mise à jour."),
    ("adapt.low_confidence", {"confidence": "double"}, "Confiance du modèle insuffisante pour proposer davantage."),
    ("adapt.unlock_level", {"level": "string"}, "Niveau de déblocage atteint ou requis."),
    ("adapt.health_low", {"overall": "int"}, "Bilan santé bas : séance allégée."),
    ("adapt.sleep_low", {"sleepQuality": "int"}, "Sommeil mauvais."),
    ("adapt.time_short", {"minutesAvailable": "int", "minutesPlanned": "int"}, "Moins de temps que prévu."),
    ("adapt.pain_reported", {"zone": "string", "intensity": "int"}, "Douleur signalée : la zone est épargnée."),
    ("adapt.pain_persistent", {"zone": "string", "sessions": "int"}, "Douleur persistante : règle santé L13 (renvoi vers un professionnel)."),
    ("adapt.fatigue_high", {"readiness": "double"}, "Fatigue accumulée élevée."),
    ("adapt.deload", {"weekIndex": "int"}, "Semaine de décharge proposée."),
    ("adapt.plateau", {"exerciseId": "exercise", "weeks": "int"}, "Stagnation sur un exercice."),
    ("adapt.exercise_skipped", {"exerciseId": "exercise", "times": "int"}, "Exercice régulièrement sauté."),
    ("adapt.missed_sessions", {"missed": "int", "planned": "int"}, "Séances manquées."),
    ("adapt.resume_after_break", {"days": "int"}, "Reprise après une coupure."),
    ("adapt.no_rating", {"sets": "int"}, "Séries sans note : non prises en compte."),
    # ---- quest ----
    ("quest.xp_effort", {"sets": "int", "capped": "bool"}, "XP de l'effort réel de la séance (plafonné)."),
    ("quest.xp_consistency", {"weeks": "int"}, "XP de régularité."),
    ("quest.xp_record", {"exerciseId": "exercise", "recordKind": "string"}, "XP d'un record."),
    ("quest.xp_milestone", {"goalId": "string", "fraction": "double"}, "XP d'un jalon d'objectif."),
    ("quest.xp_quest", {"questId": "string"}, "XP d'une quête terminée."),
    ("quest.level_up", {"level": "int"}, "Passage de niveau."),
    ("quest.prestige", {"prestige": "int"}, "Passage de prestige."),
    ("quest.rank_up", {"exerciseId": "exercise", "tier": "string"}, "Nouveau rang sur un mouvement."),
    ("quest.weak_point", {"attribute": "string"}, "Quête Koach ciblant un point faible."),
    ("quest.campaign_chapter", {"blockIndex": "int"}, "Chapitre de campagne lié à un bloc."),
    ("quest.goal_suggested", {"exerciseId": "exercise"}, "Objectif suggéré d'après le profil et les données."),
    ("quest.prediction_updated", {"goalId": "string"}, "Prédiction de date mise à jour."),
    # ---- adapt, ajoutés en 0.2.0 (lot G8, évolution additive) ----
    ("adapt.ratings_uninformative", {"confirmRate": "double", "sets": "int"}, "Notes presque toujours confirmées telles quelles : elles pèsent moins, la performance réelle pèse davantage."),
    ("adapt.benchmark_set", {"rir": "double"}, "Série repère : dernière série ouverte, autant de répétitions que possible en gardant la réserve indiquée."),
    ("adapt.place_changed", {"place": "string"}, "Lieu du jour différent du lieu prévu : exercice remplacé par un équivalent faisable sur place."),
    ("adapt.load_held", {"cause": "string"}, "Charge non augmentée (échec non prévu, douleur, bilan bas, plafond de hausse)."),
    ("adapt.increment_coarse", {"stepKg": "double"}, "Plus petit incrément de charge trop grand : la progression passe par les répétitions."),
    ("adapt.readiness", {"readiness": "double"}, "Forme du jour estimée (bilan santé, fatigue modélisée, séries déjà faites)."),
    ("adapt.volume_response", {"muscle": "string", "weeklySets": "double"}, "Volume hebdomadaire d'un groupe musculaire ajusté d'après la réponse observée."),
    ("adapt.load_floor", {"minKg": "double"}, "Plus petite charge disponible encore trop lourde pour cet exercice : il est remplacé ou retiré de la séance."),
    # ---- quest, ajoutés en 0.3.0 (lot G11, évolution additive) ----
    ("quest.no_reward_pain", {"zone": "string", "intensity": "int"}, "Séance faite malgré une douleur déclarée avant la séance : aucune récompense (ni XP, ni coffre, ni note, ni quête)."),
    ("quest.xp_capped", {"scope": "string", "cap": "int"}, "Gain d'XP borné par un plafond (`session`, `week`, `records`)."),
    ("quest.combo", {"length": "int", "bonus": "int"}, "Combo : séries consécutives dans la cible, bonus plafonné."),
    ("quest.session_grade", {"completion": "double", "accuracy": "double", "records": "int"}, "Composantes de la note de séance : réalisation, justesse des flammes, records."),
    ("quest.daily", {"dayKind": "string"}, "Quête du jour, adaptée au jour (`training`, `rest`, `break`)."),
    ("quest.weekly", {"planned": "int"}, "Quête de la semaine, bornée par les séances prévues."),
    ("quest.campaign_boss", {"blockIndex": "int"}, "Boss de campagne : séance de test ou dernière séance du bloc."),
    ("quest.lagging_exercise", {"exerciseId": "exercise"}, "Quête Koach : exercice du programme le plus souvent écourté ou sauté."),
    ("quest.weekday_focus", {"weekday": "int"}, "Quête Koach : jour de la semaine le moins régulier."),
    ("quest.xp_rest", {"days": "int"}, "Part de l'XP de régularité due aux jours de repos respectés."),
    ("quest.streak", {"weeks": "int"}, "Série de semaines réussies (jalon ou longueur atteinte)."),
    ("quest.streak_paused", {"cause": "string"}, "Semaine en pause : la série ne bouge pas. `cause` : motif de la pause déclarée (`vacation`, `illness`, `injury`, `other`) ou `pain` (séance faite malgré une douleur)."),
    ("quest.chest", {"guaranteed": "bool"}, "Coffre surprise (tirage, ou garantie après une série de séances sans coffre)."),
    ("quest.goal_late", {"goalId": "string"}, "Objectif en retard : une date ou une cible ajustée est proposée."),
    ("quest.first_time", {"exerciseId": "exercise"}, "Première fois sur un exercice."),
    ("quest.ghost_beaten", {"exerciseId": "exercise", "reference": "string"}, "Fantôme battu : mieux que la dernière fois (`last`) ou que la meilleure fois (`best`)."),
    ("quest.start_bonus", {"sessions": "int"}, "Bonus de départ plafonné (désactivé par défaut)."),
]



# ===========================================================================
# 0.4.0 — lot CQ (pipeline « Calibrage des programmes ») : évolution additive.
#
# Profil d'athlète v3 (schéma 3 : champs nouveaux, tous optionnels),
# prescriptions avancées, périodisation, spécialisation, figures,
# compétition. Rien n'est retiré ni renommé ; AUCUNE valeur n'est ajoutée à
# une énumération existante (un `switch` exhaustif des moteurs 0.1 ou de
# l'application ne compilerait plus) : les vocabulaires nouveaux sont de
# nouvelles énumérations, portées par de nouveaux champs optionnels.
# Justifications : docs/PROFIL_V3.md, docs/PARCOURS_V3.md, CONTRAT.md §11-§16.
# ===========================================================================

_TYPE_BY_NAME = {t.name: t for t in TYPES}


def _add(type_name: str, fields: list[Field]) -> None:
    """Ajoute des champs optionnels en fin de type (ordre du contrat inchangé)."""
    ty = _TYPE_BY_NAME[type_name]
    for f in fields:
        assert f.type.endswith("?"), f"{type_name}.{f.name} : un ajout est optionnel"
        assert all(g.name != f.name for g in ty.fields), f"{type_name}.{f.name} existe déjà"
    ty.fields.extend(fields)


ENUMS += [
    # ---- profil v3 ----
    E("TrainingAge", ["under_6_months", "months_6_to_24", "years_2_to_5", "over_5_years"],
      "Ancienneté d'entraînement régulier, sans compter les arrêts longs (0.4.0, ordre croissant)."),
    E("TrainingGap", ["none", "under_3_weeks", "weeks_3_to_10", "over_10_weeks"],
      "Interruption en cours au moment de répondre (0.4.0) : aucune (entraînement régulier), moins de 3 semaines, 3 à 10 semaines, plus de 10 semaines."),
    E("SleepBand", ["under_6_hours", "hours_6_to_7", "hours_7_plus"],
      "Durée habituelle de sommeil par nuit (0.4.0). Valeur HABITUELLE : la nuit précédente est dans le bilan de séance (`HealthCheck.sleepHours`)."),
    E("StressBand", ["low", "moderate", "high"],
      "Stress habituel de la vie hors entraînement, ces dernières semaines (0.4.0). Le stress du jour est dans le bilan de séance (`HealthCheck.stress`)."),
    E("OccupationalLoad", ["seated", "on_feet", "heavy"],
      "Charge physique habituelle du métier ou des journées (0.4.0) : assis, debout ou en mouvement, travail physique lourd (port de charges)."),
    E("BodyWeightGoal", ["lose", "maintain", "gain", "no_goal"],
      "Évolution voulue du poids de corps en ce moment (0.4.0)."),
    E("OtherSportKind", ["running", "cycling", "swimming", "other_endurance", "team_sport", "combat_sport",
                         "climbing", "racket_sport", "other_strength", "other"],
      "Autre sport pratiqué régulièrement en plus du programme (0.4.0)."),
    E("BodyRegion", ["lower_body", "upper_pull", "upper_push", "trunk", "whole_body"],
      "Grande région sollicitée (0.4.0) : jambes, tirage du haut du corps, poussée du haut du corps, tronc, tout le corps."),
    E("ConstraintSince", ["under_6_weeks", "weeks_6_to_12", "months_3_to_12", "over_12_months", "past_resolved"],
      "Ancienneté d'une gêne déclarée (0.4.0) ; `past_resolved` : antécédent ancien, sans gêne actuelle."),
    E("AggravatingMovement", ["pull_bent_arm", "hang_straight_arm", "push_support", "straight_arm_support", "overhead",
                              "knee_flexion", "hip_hinge", "wrist_extension_grip", "rings", "running_jumping"],
      "Famille de mouvements qui réveille une gêne (0.4.0) : tirage bras fléchis ; suspension ou tirage bras tendus ; poussée en appui (dips, pompes) ; appui bras tendus (planche, équilibre) ; au-dessus de la tête ; flexion de genou (squat, fente) ; charnière de hanche ; prise ou poignet en extension ; anneaux ; course ou sauts."),
    E("BenchmarkKind", ["load_reps", "max_reps", "max_hold", "time_trial", "distance_trial"],
      "Nature d'un test ou d'un record (0.4.0) : charge × répétitions (1 répétition = maximum), répétitions max, maintien max, temps sur une distance, distance en une durée."),
    E("BenchmarkSource", ["declared", "guided_test", "competition", "training_set"],
      "Origine d'un test ou d'un record (0.4.0) : déclaré par l'utilisateur, test guidé, compétition, série d'entraînement retenue par le moteur."),
    E("EventKind", ["strength_competition", "reps_competition", "freestyle_competition", "race", "other_competition",
                    "personal_test"],
      "Nature d'une échéance (0.4.0) : compétition de force à tentatives (streetlifting), compétition de répétitions (sets & reps, endurance de force), freestyle jugé, course, autre compétition, test personnel daté."),
    E("EventPriority", ["main", "secondary", "preparation"],
      "Priorité d'une échéance dans la saison (0.4.0) : principale (pic de forme), secondaire, préparation (faite sans affûtage)."),
    E("RepsEventMode", ["max_reps", "max_reps_in_time", "for_time", "max_hold"],
      "Format d'une épreuve de répétitions (0.4.0) : maximum de répétitions, maximum en un temps limité, volume imposé au meilleur temps, maintien le plus long."),
    E("WeakPointKind", ["bottom", "mid_range", "lockout", "dead_start", "transition", "grip", "late_set_fatigue",
                        "balance", "mobility", "speed"],
      "Point faible exprimé simplement (0.4.0) : bas du mouvement, milieu, fin (verrouillage), départ arrêté, transition (muscle-up), prise, fatigue en fin de série, équilibre, mobilité, vitesse."),
    E("SpecializationKind", ["exercise", "skill", "muscle", "pattern"],
      "Cible d'une spécialisation (0.4.0) : un mouvement, une figure, un groupe musculaire, un schéma de mouvement."),
    E("MaintenancePolicy", ["maintain", "minimal", "pause"],
      "Sort du reste pendant une spécialisation (0.4.0) : entretenu à volume réduit, dose minimale, mis en pause (hors objectifs)."),
    # ---- prescriptions avancées ----
    E("SetTechniqueKind", ["standard", "top_set_backoff", "cluster", "rest_pause", "myo_reps", "drop_set",
                           "isometric_hold", "accentuated_eccentric", "contrast", "wave", "amrap", "emom",
                           "density", "ladder", "pyramid", "skill_practice"],
      "Technique de série (0.4.0) : normale, série de tête puis séries allégées, clusters, rest-pause, myo-reps, dégressive, isométrie ou maintien, excentrique accentuée, contraste, vagues, AMRAP, EMOM, densité, échelle, pyramide, pratique de figure."),
    E("SetRole", ["straight", "top", "back_off", "activation", "mini", "drop", "wave", "test", "attempt"],
      "Rôle d'une série dans une technique (0.4.0) : normale, série de tête, série allégée, série d'activation, mini-série, palier de dégressive, palier de vague, test, tentative de compétition."),
    E("IntensityBasis", ["percent_one_rm", "percent_benchmark", "rir", "hold_fraction", "progression_step",
                         "speed_fraction", "heart_rate_fraction"],
      "Ce que désigne une intensité (0.4.0) : part du 1RM de charge totale ; part d'un test de référence ; répétitions en réserve ; part du maintien max ; étape d'une progression de figure ; part d'une vitesse de référence ; part de la fréquence cardiaque maximale."),
    E("AutoregulationKind", ["backoff_from_top_set", "load_from_rir", "stop_at_rir", "stop_on_rep_drop",
                             "hold_from_best", "last_set_amrap"],
      "Règle d'autorégulation portée par une prescription (0.4.0) : séries allégées calculées sur la série de tête RÉALISÉE ; charge corrigée quand le RIR sort de sa plage ; arrêt des séries quand le RIR passe sous un plancher ; arrêt quand les répétitions chutent ; durée de maintien tirée du meilleur maintien du jour ; dernière série ouverte."),
    E("TestKind", ["amrap_estimate", "rep_max", "one_rm", "max_reps", "max_hold", "time_trial", "distance_trial",
                   "attempt_simulation"],
      "Série ou séance de test (0.4.0) : série d'estimation sous-maximale (répétitions + RIR), xRM, maximum sur une répétition, répétitions max, maintien max, temps sur une distance, distance en une durée, simulation de tentatives."),
    # ---- périodisation ----
    E("PhaseKind", ["accumulation", "intensification", "realization", "taper", "competition", "transition", "test",
                    "deload"],
      "Phase d'un plan de saison (0.4.0)."),
    E("WeekIntent", ["intro", "accumulation", "intensification", "realization", "deload", "taper", "test",
                     "competition", "transition", "maintenance"],
      "Intention d'une semaine (0.4.0) ; complète `WeekKind`, qui reste renseigné."),
    E("DayStress", ["heavy", "medium", "light"],
      "Ondulation dans la semaine (0.4.0) : jour lourd, moyen ou léger, pour une séance ou pour un mouvement."),
    E("UndulationModel", ["none", "weekly", "daily"],
      "Modèle d'ondulation d'un bloc (0.4.0) : aucune, d'une semaine à l'autre, d'un jour à l'autre."),
    E("ProposalDetail", ["skill_step_up", "skill_step_down", "technique_change", "test_scheduled", "taper_adjust",
                         "specialization", "season_update"],
      "Précision d'une proposition du moteur dynamique (0.4.0) ; complète `ProposalKind`, qui reste renseigné."),
]

TYPES += [
    # ======================= profil v3 =======================
    Type("OtherSport", "profile", "Autre sport pratiqué régulièrement en plus du programme (0.4.0). Sert à placer les séances (pas de coefficient de volume).", [
        F("kind", "enum:OtherSportKind", "Sport."),
        F("sessionsPerWeek", "int", "Séances par semaine.", min=1, max=14),
        F("minutesPerSession", "int", "Durée habituelle d'une séance, en minutes.", min=10, max=600),
        F("weekdays", "list:int?", "Jours ISO habituels (1 = lundi … 7 = dimanche), s'ils sont fixes.", max_len=7),
        F("regions", "list:enum:BodyRegion?", "Régions sollicitées, quand le sport ne le dit pas (`other`, `other_strength`).", max_len=5),
        F("hard", "bool?", "Séances intenses (fractionné, matchs, combats)."),
    ], custom=True, invariants=["`weekdays` : jours de 1 à 7, distincts ; `regions` distinctes."]),
    Type("Benchmark", "profile", "Test ou record sur un exercice (0.4.0) : valeur exacte, datée, avec son origine. Convention de charge : EXTERNE, comme l'utilisateur la lit (lest seul pour un exercice lesté).", [
        F("exerciseId", "string", "Exercice.", **EXID),
        F("kind", "enum:BenchmarkKind", "Nature."),
        F("source", "enum:BenchmarkSource", "Origine."),
        F("date", "date?", "Jour du test ou du record (absent : inconnu)."),
        F("externalLoadKg", "double?", "Charge externe, en kg (0 : sans charge ; négative : assistance).", min=-300, max=1000),
        F("reps", "int?", "Répétitions réalisées.", min=1, max=1000),
        F("rir", "double?", "Répétitions en réserve déclarées à la fin de la série (0 : série au maximum ; absent : inconnu).", min=0, max=10),
        F("seconds", "int?", "Durée, en secondes (maintien, temps réalisé, durée imposée).", min=1, max=86400),
        F("distanceMeters", "double?", "Distance, en mètres.", min=0),
        F("bodyWeightKg", "double?", "Poids de corps le jour du test, en kg (exercices au poids du corps ou lestés).", min=25, max=300),
        F("protocolId", "string?", "Protocole de test guidé suivi (`docs/PARCOURS_V3.md`, § tests guidés).", min_len=1, max_len=40),
    ], variants=("kind", {
        "load_reps": (["externalLoadKg", "reps"], ["rir"]),
        "max_reps": (["reps"], ["externalLoadKg", "seconds"]),
        "max_hold": (["seconds"], ["externalLoadKg"]),
        "time_trial": (["distanceMeters", "seconds"], []),
        "distance_trial": (["distanceMeters", "seconds"], []),
    }), invariants=["`load_reps` : charge externe et répétitions (1 répétition, RIR 0 = maximum mesuré) ; `max_reps` : répétitions (charge externe si l'épreuve est lestée, durée si elle est limitée en temps) ; `max_hold` : secondes ; `time_trial`, `distance_trial` : distance et durée."]),
    Type("WeakPoint", "profile", "Point faible déclaré sur un mouvement (0.4.0). Sert à choisir les exercices d'assistance ; ce n'est pas une douleur (voir `Limitation`).", [
        F("exerciseId", "string", "Mouvement concerné.", **EXID),
        F("kind", "enum:WeakPointKind", "Où ça bloque."),
    ]),
    # ======================= saison, compétition, figures =======================
    Type("CompetitionLift", "season", "Mouvement d'une compétition de force à tentatives (0.4.0).", [
        F("exerciseId", "string", "Mouvement.", **EXID),
        F("attempts", "int", "Tentatives accordées.", min=1, max=4),
        F("minIncrementKg", "double?", "Plus petit saut de charge admis entre deux tentatives, en kg.", min=0.25, max=10),
        F("bestKg", "double?", "Meilleure barre déjà validée, en kg de charge externe (lest seul).", min=-300, max=1000),
        F("targetKg", "double?", "Barre visée, en kg de charge externe.", min=-300, max=1000),
    ]),
    Type("EventStation", "season", "Poste d'une épreuve de répétitions (0.4.0) : un exercice, son volume imposé ou son maximum.", [
        F("exerciseId", "string", "Exercice.", **EXID),
        F("reps", "int?", "Répétitions imposées (absent : maximum).", min=1, max=1000),
        F("seconds", "int?", "Durée imposée d'un maintien, en secondes.", min=1, max=3600),
        F("externalLoadKg", "double?", "Lest imposé, en kg.", min=-300, max=1000),
        F("unbroken", "bool?", "Série indivisible (aucun repos pendant le poste)."),
    ], custom=True, invariants=["`reps` et `seconds` ne sont pas renseignés ensemble."]),
    Type("SeasonEvent", "season", "Échéance de la saison (0.4.0) : compétition ou test daté. Les formats varient d'un organisateur à l'autre : rien n'est figé (mouvements, tentatives, postes et temps sont des données).", [
        F("id", "string", "Identifiant stable de l'échéance.", min_len=1),
        F("kind", "enum:EventKind", "Nature."),
        F("priority", "enum:EventPriority", "Priorité dans la saison."),
        F("date", "date", "Jour de l'échéance."),
        F("name", "string?", "Nom donné par l'utilisateur.", max_len=60),
        F("ruleset", "string?", "Code libre du règlement (`final_rep`, `isf_classic`, `isf_multirep`…), s'il est connu.", min_len=1, max_len=40),
        F("weightClassKg", "double?", "Limite haute de la catégorie de poids de corps visée, en kg.", min=25, max=300),
        F("openWeightClass", "bool?", "Catégorie « plus de » : `weightClassKg` est alors la limite basse."),
        F("lifts", "list:obj:CompetitionLift?", "Mouvements, dans l'ordre de la compétition (compétition de force).", min_len=1, max_len=6),
        F("mode", "enum:RepsEventMode?", "Format de l'épreuve de répétitions."),
        F("stations", "list:obj:EventStation?", "Postes, dans l'ordre (épreuve de répétitions).", min_len=1, max_len=40),
        F("rounds", "int?", "Nombre de tours de la suite de postes.", min=1, max=50),
        F("timeLimitSeconds", "int?", "Limite de temps, en secondes.", min=10, max=14400),
        F("distanceMeters", "double?", "Distance de la course, en mètres.", min=0),
        F("targetSeconds", "int?", "Temps visé, en secondes.", min=1, max=86400),
        F("goalIds", "list:string?", "Objectifs du profil que sert cette échéance."),
    ], variants=("kind", {
        "strength_competition": (["lifts"], ["timeLimitSeconds"]),
        "reps_competition": (["mode", "stations"], ["rounds", "timeLimitSeconds", "targetSeconds"]),
        "freestyle_competition": ([], ["timeLimitSeconds"]),
        "race": (["distanceMeters"], ["targetSeconds", "timeLimitSeconds"]),
        "other_competition": ([], ["lifts", "mode", "stations", "rounds", "timeLimitSeconds", "distanceMeters", "targetSeconds"]),
        "personal_test": ([], ["lifts", "mode", "stations", "rounds", "timeLimitSeconds", "distanceMeters", "targetSeconds"]),
    }), custom=True, invariants=[
        "Compétition de force : `lifts` ; compétition de répétitions : `mode` et `stations` ; course : `distanceMeters`.",
        "Mouvements de `lifts` distincts ; `stations` renseigné ⇒ `mode` renseigné.",
    ]),
    Type("Specialization", "season", "Spécialisation (0.4.0) : priorité donnée à un mouvement, une figure, un groupe musculaire ou un schéma, et sort du reste.", [
        F("kind", "enum:SpecializationKind", "Nature de la cible."),
        F("exerciseId", "string?", "Mouvement ou figure visé.", **EXID),
        F("muscle", "string?", "Groupe musculaire visé (vocabulaire `muscles` de la base).", min_len=1),
        F("pattern", "enum:MovementPattern?", "Schéma de mouvement visé."),
        F("weeks", "int?", "Durée voulue, en semaines (absent : au moteur de la fixer).", min=2, max=26),
        F("maintenance", "enum:MaintenancePolicy?", "Sort du reste (absent : au moteur de le fixer)."),
        F("startedOn", "date?", "Premier jour de la spécialisation en cours."),
    ], variants=("kind", {
        "exercise": (["exerciseId"], []),
        "skill": (["exerciseId"], []),
        "muscle": (["muscle"], []),
        "pattern": (["pattern"], []),
    }), invariants=["Exactement la cible de `kind` : `exerciseId` (mouvement, figure), `muscle` ou `pattern`."]),
    Type("SkillState", "season", "Où en est l'utilisateur sur une figure (0.4.0) : figure visée, étape actuelle de sa progression (graphe `variante_de` du catalogue), meilleure performance sur cette étape.", [
        F("targetExerciseId", "string", "Figure visée.", **EXID),
        F("currentExerciseId", "string", "Étape actuelle (la figure elle-même si elle est acquise).", **EXID),
        F("bestHoldSeconds", "int?", "Meilleur maintien propre sur l'étape actuelle, en secondes.", min=0, max=3600),
        F("bestReps", "int?", "Meilleur nombre de répétitions propres sur l'étape actuelle.", min=0, max=1000),
        F("assessedOn", "date?", "Jour de cette mesure."),
    ]),
    Type("StepCriterion", "season", "Critère de passage d'une étape de figure (0.4.0). Paramétrable : les valeurs sont un usage d'entraîneur, pas une norme.", [
        F("holdSeconds", "int?", "Maintien exigé par série, en secondes.", min=1, max=600),
        F("reps", "int?", "Répétitions exigées par série.", min=1, max=200),
        F("sets", "int", "Nombre de séries qui doivent atteindre le critère dans une séance.", min=1, max=10),
        F("minQuality", "int?", "Propreté minimale déclarée (`SetRecord.quality`, de 1 à 5).", min=1, max=5),
        F("sessions", "int?", "Nombre de séances de suite où le critère doit être tenu.", min=1, max=20),
        F("minWeeks", "int?", "Durée minimale à cette étape, en semaines (adaptation des tendons).", min=0, max=52),
    ], custom=True, invariants=["Au moins `holdSeconds` ou `reps`."]),
    Type("SkillStep", "season", "Étape d'une échelle de figure (0.4.0).", [
        F("exerciseId", "string", "Exercice de l'étape.", **EXID),
        F("criterion", "obj:StepCriterion", "Critère pour passer à l'étape suivante (pour la dernière étape : figure acquise)."),
    ]),
    Type("SkillLadder", "season", "Échelle de progression d'une figure (0.4.0), de la plus facile à la figure visée.", [
        F("targetExerciseId", "string", "Figure visée.", **EXID),
        F("steps", "list:obj:SkillStep", "Étapes, dans l'ordre de difficulté.", min_len=1, max_len=20),
    ], custom=True, invariants=["Étapes distinctes ; la dernière est la figure visée."]),
    Type("SkillProgress", "season", "Suivi d'une figure par le moteur dynamique (0.4.0).", [
        F("targetExerciseId", "string", "Figure visée.", **EXID),
        F("currentExerciseId", "string", "Étape actuelle.", **EXID),
        F("stepIndex", "int", "Rang de l'étape actuelle dans l'échelle (0 = première).", min=0),
        F("weeksAtStep", "int", "Semaines passées à cette étape.", min=0),
        F("criterionMet", "bool", "Le critère de passage est tenu."),
        F("bestHoldSeconds", "int?", "Meilleur maintien propre sur l'étape, en secondes.", min=0, max=3600),
        F("bestReps", "int?", "Meilleur nombre de répétitions propres sur l'étape.", min=0, max=1000),
        F("reasons", "list:obj:Reason", "Pourquoi."),
    ]),
    Type("SeasonPhase", "season", "Phase d'un plan de saison (0.4.0).", [
        F("index", "int", "Rang de la phase (0 = première).", min=0),
        F("kind", "enum:PhaseKind", "Nature."),
        F("startDate", "date", "Premier jour de la phase."),
        F("weeks", "int", "Durée, en semaines.", min=1, max=26),
        F("eventId", "string?", "Échéance que prépare la phase."),
        F("volumeFactor", "double?", "Volume visé, rapporté au volume de pointe de la saison (1 = pointe).", min=0, max=2),
        F("intensityFactor", "double?", "Intensité moyenne visée, rapportée à celle de la phase la plus intense (1 = pointe).", min=0, max=2),
        F("reasons", "list:obj:Reason", "Pourquoi."),
    ]),
    Type("SeasonPlan", "season", "Plan de saison (0.4.0) : squelette de phases au-dessus des blocs de 4 à 6 semaines (D4.8 inchangé : les blocs restent générés au fil de l'eau).", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("createdOn", "date", "Jour de création ou de dernière révision."),
        F("engineVersion", "string", "Version de kalis_plan."),
        F("eventIds", "list:string", "Échéances du profil prises en compte (`SeasonEvent.id`)."),
        F("phases", "list:obj:SeasonPhase", "Phases, dans l'ordre.", min_len=1, max_len=60),
        F("reasons", "list:obj:Reason", "Logique de la saison."),
    ], schema_version=1, custom=True, invariants=["`index` = rang dans `phases` ; les phases se suivent sans trou ni chevauchement (chacune commence 7 × `weeks` jours après la précédente)."]),
    Type("BlockIntent", "season", "Intention d'un bloc (0.4.0) : sa place dans la saison.", [
        F("phase", "enum:PhaseKind", "Phase que réalise le bloc."),
        F("seasonPhaseIndex", "int?", "Rang de la phase dans le plan de saison.", min=0),
        F("eventId", "string?", "Échéance préparée."),
        F("weeksToEvent", "int?", "Semaines entre le début du bloc et l'échéance.", min=0, max=104),
        F("undulation", "enum:UndulationModel?", "Modèle d'ondulation du bloc."),
        F("specialization", "obj:Specialization?", "Spécialisation servie par le bloc."),
    ]),
    Type("VolumeTolerance", "season", "Volume hebdomadaire toléré par un groupe musculaire, appris par le moteur dynamique (0.4.0).", [
        F("muscle", "string", "Groupe musculaire (vocabulaire de `kalis_plan`).", min_len=1),
        F("weeklySetsLow", "double", "Bas de la plage de séries hebdomadaires bien tolérées.", min=0, max=80),
        F("weeklySetsHigh", "double", "Haut de la plage.", min=0, max=80),
        F("confidence", "double", "Confiance, de 0 à 1.", min=0, max=1),
    ], custom=True, invariants=["`weeklySetsLow` ≤ `weeklySetsHigh`."]),
    Type("AttemptResult", "season", "Tentative déjà faite le jour d'une compétition (0.4.0).", [
        F("exerciseId", "string", "Mouvement.", **EXID),
        F("index", "int", "Rang de la tentative (0 = ouverture).", min=0, max=3),
        F("loadKg", "double", "Charge externe tentée, en kg.", min=-300, max=1000),
        F("success", "bool", "Tentative validée."),
    ]),
    Type("AttemptSuggestion", "season", "Tentative proposée (0.4.0).", [
        F("index", "int", "Rang de la tentative (0 = ouverture).", min=0, max=3),
        F("loadKg", "double", "Charge externe proposée, en kg.", min=-300, max=1000),
        F("successProbability", "double?", "Probabilité de réussite estimée, de 0 à 1.", min=0, max=1),
        F("reasons", "list:obj:Reason", "Pourquoi."),
    ]),
    Type("LiftAttempts", "season", "Tentatives proposées pour un mouvement (0.4.0).", [
        F("exerciseId", "string", "Mouvement.", **EXID),
        F("estimateKg", "double?", "Maximum du jour estimé, en kg de charge externe.", min=-300, max=1000),
        F("standardErrorKg", "double?", "Écart-type de cette estimation, en kg.", min=0),
        F("attempts", "list:obj:AttemptSuggestion", "Tentatives restantes, dans l'ordre.", max_len=4),
    ], custom=True, invariants=["Charges proposées croissantes au sens large (une charge ne baisse jamais)."]),
    Type("PacingSegment", "season", "Stratégie de rythme sur un poste d'une épreuve de répétitions (0.4.0).", [
        F("exerciseId", "string", "Exercice.", **EXID),
        F("setReps", "list:int", "Répétitions prévues par série, dans l'ordre.", max_len=60),
        F("restSeconds", "int?", "Repos prévu entre les séries, en secondes.", min=0, max=900),
        F("targetSeconds", "int?", "Temps visé sur ce poste, en secondes.", min=1, max=14400),
    ]),
    Type("EventDayRequest", "season", "Requête du jour d'une échéance (0.4.0).", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("input", "obj:AdaptInput", "Profil, bloc, journal, « aujourd'hui », état."),
        F("eventId", "string", "Échéance du profil (`SeasonEvent.id`).", min_len=1),
        F("bodyWeightKg", "double?", "Poids de corps du jour (pesée), en kg.", min=25, max=300),
        F("done", "list:obj:AttemptResult", "Tentatives déjà faites, dans l'ordre."),
        F("healthCheck", "obj:HealthCheck?", "Bilan santé du jour (une réponse absente n'est jamais remplacée)."),
    ], schema_version=1),
    Type("EventDayPlan", "season", "Plan du jour d'une échéance (0.4.0) : tentatives d'une compétition de force, ou objectif et rythme d'une épreuve de répétitions.", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("eventId", "string", "Échéance.", min_len=1),
        F("lifts", "list:obj:LiftAttempts", "Tentatives par mouvement (compétition de force)."),
        F("pacing", "list:obj:PacingSegment?", "Rythme par poste (épreuve de répétitions)."),
        F("targetTotalReps", "int?", "Objectif de répétitions totales.", min=0, max=100000),
        F("targetSeconds", "int?", "Objectif de temps, en secondes.", min=1, max=86400),
        F("confidence", "double", "Confiance, de 0 à 1.", min=0, max=1),
        F("reasons", "list:obj:Reason", "Pourquoi."),
    ], schema_version=1),
    Type("SeasonRequest", "season", "Requête de plan de saison (0.4.0) : les échéances sont celles du profil (`AthleteProfile.events`).", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("profile", "obj:AthleteProfile", "Profil."),
        F("seed", "int", "Graine.", min=0),
        F("today", "date", "« Aujourd'hui »."),
        F("startDate", "date", "Premier jour à planifier."),
        F("previous", "obj:SeasonPlan?", "Plan de saison en cours, à réviser."),
        F("currentBlock", "obj:ProgramBlock?", "Bloc en cours."),
        F("adaptation", "obj:AdaptationSummary?", "Résumé d'adaptation."),
    ], schema_version=1),
    # ======================= prescriptions avancées =======================
    Type("Tempo", "plan", "Tempo d'une répétition, en secondes par phase (0.4.0) ; 0 = sans consigne (ou explosif pour la phase concentrique).", [
        F("eccentricSeconds", "int", "Descente (phase excentrique).", min=0, max=30),
        F("bottomPauseSeconds", "int", "Pause en bas.", min=0, max=30),
        F("concentricSeconds", "int", "Montée (phase concentrique).", min=0, max=30),
        F("topPauseSeconds", "int", "Pause en haut.", min=0, max=30),
    ]),
    Type("SetTechnique", "plan", "Technique de série et ses paramètres (0.4.0). Sens de `ExercisePrescription.sets` et de la plage de répétitions pour chaque technique : CONTRAT.md §12.", [
        F("kind", "enum:SetTechniqueKind", "Technique."),
        F("backoffSets", "int?", "Séries allégées après la série de tête.", min=1, max=10),
        F("backoffDropPct", "double?", "Baisse de charge des séries allégées, en part de la charge de tête (0,10 = −10 %).", min=0, max=0.6),
        F("backoffRepsLow", "int?", "Bas de la plage de répétitions des séries allégées.", min=1, max=100),
        F("backoffRepsHigh", "int?", "Haut de la plage de répétitions des séries allégées.", min=1, max=100),
        F("miniSets", "int?", "Mini-séries par série (clusters) ; plafond de mini-séries (rest-pause, myo-reps).", min=1, max=20),
        F("miniSetReps", "int?", "Répétitions par mini-série.", min=1, max=30),
        F("intraRestSeconds", "int?", "Repos entre deux mini-séries, en secondes.", min=1, max=120),
        F("activationRepsLow", "int?", "Bas de la plage de la série d'activation (myo-reps).", min=1, max=100),
        F("activationRepsHigh", "int?", "Haut de la plage de la série d'activation (myo-reps).", min=1, max=100),
        F("totalRepsTarget", "int?", "Répétitions totales visées (rest-pause, densité).", min=1, max=1000),
        F("drops", "int?", "Nombre de baisses de charge (dégressive).", min=1, max=6),
        F("dropPct", "double?", "Baisse de charge à chaque palier, en part de la charge précédente.", min=0.05, max=0.6),
        F("eccentricLoadPct", "double?", "Charge de la phase excentrique, en part du 1RM de charge totale (peut dépasser 1).", min=0, max=1.5),
        F("eccentricOnly", "bool?", "Négatives seules (la montée est aidée ou sautée)."),
        F("pairedSlotId", "string?", "Emplacement de l'exercice explosif enchaîné (contraste).", min_len=1),
        F("pairedRestSeconds", "int?", "Repos avant l'exercice enchaîné, en secondes.", min=0, max=900),
        F("waves", "int?", "Nombre de vagues.", min=1, max=6),
        F("waveReps", "list:int?", "Répétitions de chaque palier d'une vague, dans l'ordre (ex. 3, 2, 1).", min_len=1, max_len=8),
        F("waveStepPct", "double?", "Hausse de charge d'une vague à la suivante, en part de la charge.", min=0, max=0.2),
        F("durationSeconds", "int?", "Durée du bloc, en secondes (AMRAP, densité).", min=10, max=7200),
        F("intervalSeconds", "int?", "Durée d'un intervalle, en secondes (EMOM).", min=10, max=900),
        F("intervals", "int?", "Nombre d'intervalles (EMOM).", min=1, max=120),
        F("repsPerInterval", "int?", "Répétitions par intervalle (EMOM).", min=1, max=100),
        F("ladderStart", "int?", "Première marche de l'échelle, en répétitions.", min=1, max=100),
        F("ladderStep", "int?", "Pas de l'échelle, en répétitions.", min=1, max=20),
        F("ladderTop", "int?", "Dernière marche de l'échelle, en répétitions.", min=1, max=100),
        F("ladderCount", "int?", "Nombre d'échelles enchaînées.", min=1, max=20),
        F("pyramidReps", "list:int?", "Répétitions de chaque palier de la pyramide, dans l'ordre (ex. 10, 8, 6, 4, 2).", min_len=2, max_len=20),
        F("qualityFloor", "int?", "Propreté minimale (1 à 5) : la pratique s'arrête dès qu'un essai passe dessous.", min=1, max=5),
        F("maxAttempts", "int?", "Plafond d'essais (pratique de figure).", min=1, max=30),
    ], variants=("kind", {
        "standard": ([], []),
        "top_set_backoff": (["backoffSets", "backoffDropPct"], ["backoffRepsLow", "backoffRepsHigh"]),
        "cluster": (["miniSets", "miniSetReps", "intraRestSeconds"], []),
        "rest_pause": (["intraRestSeconds"], ["miniSets", "totalRepsTarget"]),
        "myo_reps": (["miniSetReps", "intraRestSeconds"], ["miniSets", "activationRepsLow", "activationRepsHigh"]),
        "drop_set": (["drops", "dropPct"], []),
        "isometric_hold": ([], []),
        "accentuated_eccentric": ([], ["eccentricLoadPct", "eccentricOnly"]),
        "contrast": (["pairedSlotId"], ["pairedRestSeconds"]),
        "wave": (["waves", "waveReps"], ["waveStepPct"]),
        "amrap": ([], ["durationSeconds"]),
        "emom": (["intervalSeconds", "intervals"], ["repsPerInterval"]),
        "density": (["durationSeconds"], ["totalRepsTarget"]),
        "ladder": (["ladderStart", "ladderStep", "ladderTop"], ["ladderCount"]),
        "pyramid": (["pyramidReps"], []),
        "skill_practice": ([], ["qualityFloor", "maxAttempts"]),
    }), custom=True, invariants=[
        "Chaque technique porte exactement ses paramètres (tableau de CONTRAT.md §12) : un paramètre d'une autre technique est une violation.",
        "Plages basses ≤ plages hautes, renseignées ensemble ; `ladderStart` ≤ `ladderTop` ; répétitions de `waveReps` et de `pyramidReps` de 1 à 100.",
    ]),
    Type("IntensityTarget", "plan", "Intensité visée, exprimée autrement qu'en flammes (0.4.0). `ExercisePrescription.percentOfOneRm` et `targetFlames` restent valables ; ce type ajoute les intensités relatives à un test, au maintien max, à une étape de figure, à une vitesse.", [
        F("basis", "enum:IntensityBasis", "Ce que désigne `value`."),
        F("value", "double?", "Valeur visée (ou bas de la plage) : part de 0 à 1,5 pour les bases en part ; répétitions en réserve pour `rir`.", min=0, max=10),
        F("valueHigh", "double?", "Haut de la plage, même unité.", min=0, max=10),
        F("referenceExerciseId", "string?", "Exercice du test de référence, s'il diffère de l'exercice prescrit.", **EXID),
        F("referenceKind", "enum:BenchmarkKind?", "Nature du test de référence (`percent_benchmark` : part des répétitions max, du maintien max…)."),
        F("stepExerciseId", "string?", "Étape de progression visée (`progression_step`).", **EXID),
        F("rirCap", "double?", "Plafond d'effort : ne jamais finir une série avec moins de répétitions en réserve que cette valeur ; la charge est abaissée sinon.", min=0, max=10),
    ], variants=("basis", {
        "percent_one_rm": (["value"], ["valueHigh", "referenceExerciseId"]),
        "percent_benchmark": (["value", "referenceKind"], ["valueHigh", "referenceExerciseId"]),
        "rir": (["value"], ["valueHigh"]),
        "hold_fraction": (["value"], ["valueHigh", "referenceExerciseId"]),
        "progression_step": (["stepExerciseId"], []),
        "speed_fraction": (["value"], ["valueHigh", "referenceKind", "referenceExerciseId"]),
        "heart_rate_fraction": (["value"], ["valueHigh"]),
    }), custom=True, invariants=["`value` ≤ `valueHigh` ; bases en part : `value` et `valueHigh` ≤ 1,5."]),
    Type("AutoregulationRule", "plan", "Règle d'autorégulation portée par une prescription (0.4.0) : le moteur dynamique l'exécute pendant la séance.", [
        F("kind", "enum:AutoregulationKind", "Règle."),
        F("pct", "double?", "Part : baisse appliquée à la série de tête réalisée (`backoff_from_top_set`), part du meilleur maintien du jour (`hold_from_best`), pas de correction de charge par répétition d'écart (`load_from_rir`).", min=0, max=1),
        F("rirFloor", "double?", "Plancher de répétitions en réserve.", min=0, max=10),
        F("rirCeiling", "double?", "Plafond de répétitions en réserve.", min=0, max=10),
        F("minSets", "int?", "Nombre minimal de séries.", min=0, max=20),
        F("maxSets", "int?", "Nombre maximal de séries.", min=1, max=30),
        F("repDrop", "int?", "Chute de répétitions, par rapport à la première série, qui arrête l'exercice.", min=1, max=50),
    ], variants=("kind", {
        "backoff_from_top_set": (["pct"], ["rirCeiling", "minSets", "maxSets"]),
        "load_from_rir": (["rirFloor", "rirCeiling"], ["pct"]),
        "stop_at_rir": (["rirFloor"], ["minSets", "maxSets"]),
        "stop_on_rep_drop": (["repDrop"], ["minSets", "maxSets"]),
        "hold_from_best": (["pct"], []),
        "last_set_amrap": ([], ["rirFloor"]),
    }), custom=True, invariants=["`rirFloor` ≤ `rirCeiling` ; `minSets` ≤ `maxSets`."]),
    Type("TestSpec", "plan", "Série ou exercice de test (0.4.0), porté par une prescription dont `kind` vaut `test`.", [
        F("kind", "enum:TestKind", "Nature du test."),
        F("protocolId", "string?", "Protocole de test guidé (`docs/PARCOURS_V3.md`, § tests guidés).", min_len=1, max_len=40),
        F("targetRir", "double?", "Répétitions en réserve à garder (série d'estimation).", min=0, max=5),
        F("attempts", "int?", "Nombre d'essais au plus (maximum, simulation de tentatives).", min=1, max=6),
        F("benchmarkKind", "enum:BenchmarkKind?", "Nature de la valeur à reporter dans le profil (`AdaptReview.testResults`)."),
    ]),
]

# ---- champs optionnels ajoutés aux types existants (0.4.0) ----
_add("Limitation", [
    F("since", "enum:ConstraintSince?", "Depuis quand (0.4.0). Une gêne décrit une contrainte d'entraînement, jamais un diagnostic."),
    F("aggravatedBy", "list:enum:AggravatingMovement?", "Familles de mouvements qui la réveillent (0.4.0).", max_len=10),
])
_add("AthleteProfile", [
    F("trainingAge", "enum:TrainingAge?", "Ancienneté d'entraînement régulier (schéma 3)."),
    F("trainingGap", "enum:TrainingGap?", "Interruption en cours au moment de répondre (schéma 3) ; ensuite, les coupures se lisent dans le journal."),
    F("sleep", "enum:SleepBand?", "Durée habituelle de sommeil (schéma 3)."),
    F("stress", "enum:StressBand?", "Stress habituel de la vie hors entraînement (schéma 3)."),
    F("occupationalLoad", "enum:OccupationalLoad?", "Charge physique habituelle du métier ou des journées (schéma 3)."),
    F("otherSports", "list:obj:OtherSport?", "Autres sports réguliers (schéma 3). Absent : question non posée ou passée ; liste vide : aucun.", max_len=6),
    F("bodyWeightGoal", "enum:BodyWeightGoal?", "Évolution voulue du poids de corps en ce moment (schéma 3)."),
    F("benchmarks", "list:obj:Benchmark?", "Tests et records connus (schéma 3). Absent : question non posée ou passée.", max_len=200),
    F("events", "list:obj:SeasonEvent?", "Compétitions et tests datés (schéma 3). Absent : question non posée ou passée ; liste vide : aucune échéance.", max_len=20),
    F("skills", "list:obj:SkillState?", "Figures visées et étape actuelle (schéma 3).", max_len=30),
    F("weakPoints", "list:obj:WeakPoint?", "Points faibles déclarés (schéma 3).", max_len=30),
    F("specialization", "obj:Specialization?", "Priorité voulue par l'utilisateur (schéma 3)."),
    F("lifestyleUpdatedOn", "date?", "Jour de la dernière réponse aux questions de récupération et de vie (sommeil, stress, métier, autres sports, poids) (schéma 3) : elles se redemandent de temps en temps."),
])
_add("SetTarget", [
    F("role", "enum:SetRole?", "Rôle de la série dans la technique (0.4.0)."),
    F("percentOfOneRm", "double?", "Charge de la série, en part du 1RM de charge totale (0.4.0).", min=0, max=1.5),
    F("restSeconds", "int?", "Repos après la série, en secondes (0.4.0).", min=0, max=900),
])
_add("SetRecord", [
    F("technique", "enum:SetTechniqueKind?", "Technique de la série (0.4.0)."),
    F("role", "enum:SetRole?", "Rôle de la série dans la technique (0.4.0)."),
    F("miniSetIndex", "int?", "Rang de la mini-série dans la série (0 = première) (0.4.0) : les mini-séries d'un cluster, d'un rest-pause, d'une dégressive partagent le même `setIndex`.", min=0, max=99),
    F("restBeforeSeconds", "int?", "Repos pris avant la série, en secondes (0.4.0).", min=0, max=3600),
    F("elapsedSeconds", "int?", "Temps écoulé depuis le début du bloc chronométré, en secondes (AMRAP, EMOM, densité, épreuve pour le temps) (0.4.0).", min=0, max=86400),
    F("rounds", "int?", "Tours complets réalisés (AMRAP, circuit) (0.4.0).", min=0, max=1000),
    F("quality", "int?", "Propreté déclarée de 1 à 5 (5 = parfaite) pour une figure ou un maintien (0.4.0) ; absente = non notée.", min=1, max=5),
    F("attemptIndex", "int?", "Rang de la tentative de compétition (0 = ouverture) (0.4.0).", min=0, max=3),
])
_add("SessionRecord", [
    F("eventId", "string?", "Échéance du profil dont cette séance est le jour (0.4.0).", min_len=1),
])
_add("ExercisePrescription", [
    F("technique", "obj:SetTechnique?", "Technique de série (0.4.0) ; absente : séries normales."),
    F("tempo", "obj:Tempo?", "Tempo des répétitions (0.4.0)."),
    F("intensity", "obj:IntensityTarget?", "Intensité relative à un test, au maintien max, à une étape, à une vitesse ; plafond de RIR (0.4.0)."),
    F("autoregulation", "list:obj:AutoregulationRule?", "Règles d'autorégulation que le moteur dynamique exécute (0.4.0).", max_len=3),
    F("test", "obj:TestSpec?", "Description du test, quand `kind` vaut `test` (0.4.0)."),
    F("dayStress", "enum:DayStress?", "Ondulation : jour lourd, moyen ou léger pour ce mouvement (0.4.0)."),
    F("skillTargetId", "string?", "Figure visée dont cet exercice est une étape (0.4.0).", **EXID),
])
_add("DayPrescription", [
    F("stress", "enum:DayStress?", "Ondulation : séance lourde, moyenne ou légère (0.4.0)."),
])
_add("WeekPrescription", [
    F("intent", "enum:WeekIntent?", "Intention de la semaine (0.4.0) ; `kind` reste renseigné."),
])
_add("Pass1Plan", [
    F("intent", "obj:BlockIntent?", "Intention du bloc : sa place dans la saison (0.4.0)."),
    F("skillLadders", "list:obj:SkillLadder?", "Échelles de progression des figures travaillées dans le bloc (0.4.0).", max_len=30),
])
_add("AdaptationSummary", [
    F("benchmarks", "list:obj:Benchmark?", "Tests réalisés et maxima retenus sur la période (0.4.0) ; leur incertitude est dans `estimates`.", max_len=200),
    F("skills", "list:obj:SkillProgress?", "Suivi des figures (0.4.0).", max_len=30),
    F("volumeTolerance", "list:obj:VolumeTolerance?", "Volume hebdomadaire toléré par groupe musculaire (0.4.0).", max_len=40),
])
_add("AdaptInput", [
    F("season", "obj:SeasonPlan?", "Plan de saison en cours (0.4.0)."),
])
_add("SessionPlan", [
    F("phase", "enum:PhaseKind?", "Phase en cours (0.4.0)."),
    F("weekIntent", "enum:WeekIntent?", "Intention de la semaine (0.4.0)."),
    F("eventId", "string?", "Échéance dont c'est le jour (0.4.0).", min_len=1),
])
_add("IntraSessionAdvice", [
    F("miniSetsLeft", "int?", "Mini-séries conseillées encore à faire dans la série en cours (0.4.0).", min=0, max=50),
    F("stepExerciseId", "string?", "Étape de progression conseillée pour la suite (figure : étape plus facile un mauvais jour) (0.4.0).", **EXID),
])
_add("Proposal", [
    F("detail", "enum:ProposalDetail?", "Précision de la proposition (0.4.0)."),
    F("season", "obj:SeasonPlan?", "Plan de saison résultant, pour une révision de la saison (0.4.0)."),
])
_add("AdaptReview", [
    F("testResults", "list:obj:Benchmark?", "Résultats de tests à reporter dans `AthleteProfile.benchmarks` par l'application (0.4.0).", max_len=200),
    F("skillStates", "list:obj:SkillState?", "États des figures à reporter dans `AthleteProfile.skills` par l'application (0.4.0).", max_len=30),
])
_add("PlanRequest", [
    F("season", "obj:SeasonPlan?", "Plan de saison en cours (0.4.0)."),
])
_add("NextBlockRequest", [
    F("season", "obj:SeasonPlan?", "Plan de saison en cours (0.4.0)."),
])
_add("RestructureRequest", [
    F("season", "obj:SeasonPlan?", "Plan de saison en cours (0.4.0)."),
])
_add("BlockProposal", [
    F("season", "obj:SeasonPlan?", "Plan de saison révisé, si le bloc proposé le modifie (0.4.0)."),
])

# Profil d'athlète : schéma 3 (le schéma 2 reste lu et valide ; `min` = 2).
_TYPE_BY_NAME["AthleteProfile"].schema_version = 3
_TYPE_BY_NAME["AthleteProfile"].doc = "Profil d'athlète (D3). Schéma 3 depuis 0.4.0 : le schéma 2 reste lu tel quel ; les champs du schéma 3 sont tous optionnels."
_TYPE_BY_NAME["AthleteProfile"].fields[0].doc = "Version du schéma (2 ou 3)."
_TYPE_BY_NAME["AthleteProfile"].invariants.append(
    "Un champ du schéma 3 renseigné ⇒ `schemaVersion` ≥ 3 ; identifiants d'`events` distincts ; figures visées de `skills` distinctes ; un seul test par (exercice, nature, origine, jour) dans `benchmarks`.")
_TYPE_BY_NAME["Limitation"].custom = True
_TYPE_BY_NAME["Limitation"].invariants.append("`aggravatedBy` sans doublon.")
_TYPE_BY_NAME["ExercisePrescription"].invariants.append(
    "(0.4.0) `test` renseigné ⇒ `kind` vaut `test` ; série de tête et séries allégées : `technique.backoffSets` < `sets`.")

REASONS += [
    # ---- plan, ajoutés en 0.4.0 (lot CQ, évolution additive) ----
    ("plan.season_phase", {"phase": "string", "weeksToEvent": "int"}, "Le bloc réalise une phase du plan de saison, à tant de semaines de l'échéance."),
    ("plan.taper", {"volumeFactor": "double", "daysToEvent": "int"}, "Affûtage : volume réduit, intensité gardée, avant une échéance."),
    ("plan.peak_event", {"eventId": "string"}, "La saison est construite pour arriver en forme à cette échéance."),
    ("plan.undulation", {"stress": "string"}, "Ondulation : jour lourd, moyen ou léger."),
    ("plan.technique", {"technique": "string"}, "Technique de série choisie pour cet exercice."),
    ("plan.technique_withheld", {"technique": "string", "cause": "string"}, "Technique avancée non servie : un prérequis manque (ancienneté, niveau, test, récupération, gêne)."),
    ("plan.specialization", {"target": "string", "weeks": "int"}, "Spécialisation : priorité donnée à une cible pendant tant de semaines."),
    ("plan.maintenance_volume", {"muscle": "string", "weeklySets": "double"}, "Volume d'entretien du reste pendant une spécialisation ou un affûtage."),
    ("plan.skill_step", {"exerciseId": "exercise", "stepIndex": "int"}, "Étape de la progression d'une figure."),
    ("plan.test_scheduled", {"testKind": "string"}, "Test programmé (série d'estimation, maximum, maintien, course)."),
    ("plan.benchmark_used", {"exerciseId": "exercise", "source": "string"}, "Charge ou durée calculée d'après un test ou un record du profil."),
    ("plan.percent_based", {"pct": "double"}, "Charge donnée en part du maximum."),
    ("plan.recovery_profile", {"factor": "string", "level": "string"}, "Tient compte d'une réponse de récupération et de vie (sommeil, stress, métier physique, déficit énergétique)."),
    ("plan.constraint_history", {"zone": "string", "since": "string"}, "Zone à antécédent : progression plus prudente des mouvements qui la chargent."),
    ("plan.concurrent_sport", {"sport": "string", "sessions": "int"}, "Tient compte d'un autre sport : séances lourdes placées à distance."),
    ("plan.training_age", {"band": "string"}, "Volume, intensité ou techniques réglés sur l'ancienneté d'entraînement."),
    ("plan.return_from_gap", {"gap": "string"}, "Reprise après une interruption : redémarrage progressif."),
    ("plan.weak_point", {"exerciseId": "exercise", "kind": "string"}, "Exercice d'assistance choisi pour un point faible déclaré."),
    ("plan.event_specific", {"eventId": "string"}, "Travail spécifique d'une épreuve (mouvements, enchaînements, durées de la compétition)."),
    # ---- adapt, ajoutés en 0.4.0 ----
    ("adapt.backoff_from_top_set", {"topLoadKg": "double", "pct": "double"}, "Séries allégées calculées sur la série de tête réalisée."),
    ("adapt.rir_cap", {"rir": "double"}, "Plafond d'effort atteint : charge abaissée pour garder la réserve prévue."),
    ("adapt.test_result", {"exerciseId": "exercise", "value": "double", "standardError": "double"}, "Résultat d'un test et son incertitude."),
    ("adapt.skill_step_up", {"exerciseId": "exercise"}, "Critère de passage tenu : étape suivante de la figure."),
    ("adapt.skill_step_down", {"exerciseId": "exercise"}, "Mauvais jour ou critère perdu : étape plus facile."),
    ("adapt.skill_hold", {"exerciseId": "exercise", "weeksAtStep": "int"}, "Étape gardée : critère non tenu, ou durée minimale à l'étape non atteinte (tendons)."),
    ("adapt.phase_respected", {"phase": "string"}, "Ajustement limité par l'intention de la phase."),
    ("adapt.taper_no_volume", {}, "Affûtage : aucun volume ajouté, intensité gardée."),
    ("adapt.event_near", {"days": "int"}, "Échéance proche : décisions prudentes."),
    ("adapt.attempt_opener", {"pct": "double"}, "Ouverture choisie comme une part du maximum estimé : une barre sûre."),
    ("adapt.attempt_next", {"successProbability": "double"}, "Tentative suivante choisie d'après la précédente et l'incertitude du maximum."),
    ("adapt.attempt_conservative", {"cause": "string"}, "Tentative prudente (incertitude élevée, échec précédent, bilan bas, pesée)."),
    ("adapt.pacing", {"targetReps": "int"}, "Stratégie de rythme d'une épreuve de répétitions."),
    ("adapt.recovery_profile", {"factor": "string", "level": "string"}, "Tolérance réglée sur une réponse de récupération et de vie du profil."),
    ("adapt.tendon_load", {"zone": "string", "weeks": "int"}, "Charge des tendons surveillée : progression en bras tendus ou en appui ralentie."),
    ("adapt.technique_executed", {"technique": "string"}, "Technique de série exécutée telle que prescrite."),
    ("adapt.mini_set_stop", {"cause": "string"}, "Mini-séries arrêtées (répétitions manquées, plafond atteint, qualité)."),
]

SCHEMA_VERSIONS = {t.name: t.schema_version for t in TYPES if t.schema_version is not None}
MODULES = ["common", "profile", "journal", "plan", "adapt", "quest", "season"]
