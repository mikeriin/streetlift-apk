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
    E("DelightKind", ["record", "chest", "week_streak", "session_grade", "combo", "ghost"],
      "Événement de plaisir (D8.1)."),
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
    Type("QuestInput", "quest", "Entrée du moteur de leveling.", [
        F("schemaVersion", "int", "Version du schéma (1).", min=1),
        F("profile", "obj:AthleteProfile", "Profil."),
        F("log", "obj:TrainingLog", "Journal complet."),
        F("block", "obj:ProgramBlock?", "Bloc en cours."),
        F("adaptation", "obj:AdaptationSummary?", "Résumé d'adaptation."),
        F("state", "obj:QuestState", "État précédent."),
        F("today", "date", "« Aujourd'hui », fourni par l'application."),
        F("seed", "int?", "Graine de l'utilisateur pour les tirages (coffres, quêtes du jour) ; le moteur la combine à la date.", min=0),
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
]

SCHEMA_VERSIONS = {t.name: t.schema_version for t in TYPES if t.schema_version is not None}
MODULES = ["common", "profile", "journal", "plan", "adapt", "quest"]
