"""Vocabulaires normalisés du schéma v2 (KT-044). Contenu généré par Claude (L9)."""

LIEUX = {
    "maison_sans_materiel": "Maison sans matériel",
    "maison_equipee": "Maison équipée",
    "parc_street_workout": "Parc de street workout",
    "salle": "Salle",
}
ALL_LIEUX = list(LIEUX)

TYPES_MOUVEMENT = {
    "poussee_horizontale": "Poussée horizontale",
    "poussee_verticale": "Poussée verticale",
    "tirage_horizontal": "Tirage horizontal",
    "tirage_vertical": "Tirage vertical",
    "squat": "Squat",
    "charniere_hanche": "Charnière de hanche",
    "fente": "Fente",
    "gainage_anti_extension": "Gainage anti-extension",
    "gainage_anti_rotation": "Gainage anti-rotation",
    "gainage_anti_flexion_laterale": "Gainage anti-flexion latérale",
    "portes": "Portés",
    "locomotion": "Locomotion",
    "mobilite": "Mobilité",
    "figure_statique": "Figure statique",
    "figure_dynamique": "Figure dynamique",
    "conditionnement": "Conditionnement",
    # Extensions (décision par défaut D-L9-02) : isolation et flexion du tronc,
    # absentes de la liste du prompt mais indispensables pour ne pas polluer les
    # types de base (un curl n'est pas un tirage).
    "isolation": "Isolation (mono-articulaire)",
    "flexion_tronc": "Flexion du tronc",
    # Réservé aux entrées non conformes (bilan, repos…), exclues du générateur.
    "hors_categorie": "Hors catégorie",
}

MUSCLES = {
    "pectoraux": "Pectoraux",
    "deltoide_anterieur": "Deltoïde antérieur",
    "deltoide_lateral": "Deltoïde latéral",
    "deltoide_posterieur": "Deltoïde postérieur",
    "triceps": "Triceps",
    "biceps": "Biceps",
    "avant_bras": "Avant-bras et préhension",
    "grand_dorsal": "Grand dorsal",
    "trapezes": "Trapèzes",
    "rhomboides": "Rhomboïdes",
    "coiffe_rotateurs": "Coiffe des rotateurs",
    "dentele_anterieur": "Dentelé antérieur",
    "lombaires": "Érecteurs du rachis",
    "abdominaux": "Grand droit de l'abdomen",
    "obliques": "Obliques",
    "transverse": "Transverse",
    "fessiers": "Grand fessier",
    "moyen_fessier": "Moyen fessier",
    "quadriceps": "Quadriceps",
    "ischios": "Ischio-jambiers",
    "adducteurs": "Adducteurs",
    "flechisseurs_hanche": "Fléchisseurs de hanche",
    "mollets": "Mollets",
    "tibial_anterieur": "Tibial antérieur",
}

# Segment(s) du squelette mis en couleur « accent » pour chaque muscle
MUSCLE_SEGMENTS = {
    "pectoraux": ["tronc"], "deltoide_anterieur": ["bras", "ceinture"], "deltoide_lateral": ["bras", "ceinture"],
    "deltoide_posterieur": ["bras", "ceinture"], "triceps": ["bras"], "biceps": ["bras"],
    "avant_bras": ["avant_bras"], "grand_dorsal": ["tronc"], "trapezes": ["cou", "ceinture"],
    "rhomboides": ["tronc"], "coiffe_rotateurs": ["ceinture"], "dentele_anterieur": ["tronc"],
    "lombaires": ["tronc"], "abdominaux": ["tronc"], "obliques": ["tronc"], "transverse": ["tronc"],
    "fessiers": ["bassin", "cuisse"], "moyen_fessier": ["bassin", "cuisse"], "quadriceps": ["cuisse"],
    "ischios": ["cuisse"], "adducteurs": ["cuisse"], "flechisseurs_hanche": ["cuisse"],
    "mollets": ["jambe"], "tibial_anterieur": ["jambe"],
}

ZONES = ["epaule", "coude", "poignet", "rachis_lombaire", "rachis_cervical", "hanche", "genou", "cheville"]
ZONES_LABELS = {"epaule": "Épaule", "coude": "Coude", "poignet": "Poignet", "rachis_lombaire": "Rachis lombaire",
                "rachis_cervical": "Rachis cervical", "hanche": "Hanche", "genou": "Genou", "cheville": "Cheville"}

MODES_CHARGE = {
    "poids_de_corps": "Poids de corps", "lest": "Lest", "barre": "Barre", "halteres": "Haltères",
    "kettlebell": "Kettlebell", "machine": "Machine", "poulie": "Poulie", "elastique": "Élastique",
    "assistance": "Assistance", "objet_leste": "Objet lesté (sac, médecine-ball, traîneau)",
}

MESURES = {"repetitions": "Répétitions", "temps": "Temps", "distance": "Distance"}

# matériel : libellé, lieux compatibles
MATERIEL = {
    "aucun": ("Aucun", ALL_LIEUX),
    "sol_degage": ("Espace au sol dégagé", ALL_LIEUX),
    "mur": ("Mur", ALL_LIEUX),
    "support_stable": ("Support stable (chaise, marche, banc public)", ALL_LIEUX),
    "espace_exterieur": ("Espace de course ou de marche", ALL_LIEUX),
    "serviette": ("Serviette ou disques glissants", ["maison_sans_materiel", "maison_equipee", "salle"]),
    "baton": ("Bâton ou manche", ["maison_sans_materiel", "maison_equipee", "salle"]),
    "barre_fixe": ("Barre fixe", ["maison_equipee", "parc_street_workout", "salle"]),
    "barres_paralleles": ("Barres parallèles ou station de dips", ["maison_equipee", "parc_street_workout", "salle"]),
    "barre_basse": ("Barre basse (rowing australien)", ["maison_equipee", "parc_street_workout", "salle"]),
    "anneaux": ("Anneaux", ["maison_equipee", "parc_street_workout", "salle"]),
    "sangles": ("Sangles de suspension", ["maison_equipee", "parc_street_workout", "salle"]),
    "poteau": ("Poteau ou espalier vertical", ["parc_street_workout", "salle"]),
    "elastique": ("Élastique de résistance", ["maison_equipee", "parc_street_workout", "salle"]),
    "lest": ("Lest (gilet, ceinture et disques)", ["maison_equipee", "parc_street_workout", "salle"]),
    "halteres": ("Haltères", ["maison_equipee", "salle"]),
    "kettlebell": ("Kettlebell", ["maison_equipee", "salle"]),
    "banc": ("Banc de musculation", ["maison_equipee", "salle"]),
    "box": ("Box ou plateforme stable", ["maison_equipee", "parc_street_workout", "salle"]),
    "poignees": ("Poignées de pompes ou parallettes", ["maison_equipee", "parc_street_workout", "salle"]),
    "roue_abdos": ("Roue abdominale", ["maison_equipee", "salle"]),
    "corde_a_sauter": ("Corde à sauter", ["maison_equipee", "parc_street_workout", "salle"]),
    "sac_leste": ("Sac lesté", ["maison_equipee", "parc_street_workout", "salle"]),
    "medecine_ball": ("Médecine-ball", ["maison_equipee", "salle"]),
    "gripper": ("Pince de préhension", ["maison_equipee", "salle"]),
    "foam_roller": ("Rouleau de massage", ["maison_equipee", "salle"]),
    "swiss_ball": ("Ballon de gymnastique", ["maison_equipee", "salle"]),
    "barre": ("Barre olympique et disques", ["salle"]),
    "rack": ("Cage ou rack à squat", ["salle"]),
    "disques": ("Disques", ["salle"]),
    "poulie": ("Poulie", ["salle"]),
    "machine": ("Machine guidée", ["salle"]),
    "ergometre": ("Ergomètre (rameur, vélo, SkiErg)", ["salle"]),
    "battle_rope": ("Corde ondulatoire", ["salle"]),
    "traineau": ("Traîneau", ["salle"]),
    "ghd": ("Banc GHD ou à lombaires", ["salle"]),
}

PRECAUTIONS = {
    "epaule_anterieure": "Éviter en cas de douleur à l'avant de l'épaule ; réduire l'amplitude basse.",
    "epaule_au_dessus_tete": "Bras au-dessus de la tête : éviter en cas de douleur d'épaule dans cette position.",
    "coude": "Réduire l'amplitude ou la charge en cas de douleur au coude.",
    "poignet_extension": "Appui main à plat, poignet en extension : utiliser poings ou poignées en cas de gêne au poignet.",
    "lombaire": "Éviter en cas de douleur lombaire ; garder le dos neutre et gainé.",
    "cervical": "Éviter l'appui ou la charge sur la tête et la nuque en cas de gêne cervicale.",
    "genou_flexion": "Limiter la profondeur en cas de douleur au genou.",
    "impacts": "Sauts et réceptions : éviter en cas de douleur aux genoux, chevilles ou tendons d'Achille ; reprendre progressivement.",
    "tete_en_bas": "Position tête en bas : éviter en cas de vertiges ou de contre-indication connue ; prévoir une sortie sûre.",
    "charge_axiale": "Charge sur la colonne : progresser par petits paliers, dos gainé, pareur ou sécurités réglées.",
    "effort_maximal": "Effort maximal : jamais en reprise ni sans échauffement complet ; arrêter au premier défaut technique.",
    "cardio_intense": "Effort cardio intense : progresser graduellement ; arrêter en cas de malaise, vertige ou douleur thoracique.",
    "equilibre": "Travail d'équilibre : espace dégagé, sortie de chute maîtrisée avant de progresser.",
    "suspension": "Suspension : vérifier la solidité du support et la sécurité de la prise.",
    "tendons_bras_tendus": "Figure bras tendus : progresser lentement, les tendons du coude et du biceps s'adaptent moins vite que les muscles.",
    "chute_arriere": "Risque de chute en arrière : apprendre la sortie (roulade ou pas de côté) avant de tenir longtemps.",
    "technique_prioritaire": "Mouvement technique : apprendre avec une charge légère et un retour vidéo ou un regard extérieur.",
    "reprise_senior": "Reprise ou âge avancé : commencer par la version assistée et un tempo contrôlé.",
    "adducteurs": "Tension forte sur l'intérieur de cuisse : entrer progressivement dans l'amplitude.",
}

METHODES = {
    "clusters": "Séries fractionnées (clusters) : courtes pauses à l'intérieur de la série.",
    "series_longues": "Séries longues sous-maximales.",
    "serie_reference": "Série de référence (test sous-maximal standardisé).",
    "emom": "Chaque minute (EMOM).",
    "echelles": "Échelles dégressives.",
    "series_continues": "Séries continues.",
    "tres_leger": "Volume très léger (récupération).",
    "enchaine": "Enchaîné sans repos après l'exercice précédent.",
    "gtg": "« Graisser le geste » : séries courtes réparties dans la journée.",
    "contraste": "Contraste français : exercice lourd puis explosif en enchaînement.",
    "simulation_competition": "Simulation d'essai de compétition.",
    "isometrie_multi_angles": "Isométrie maximale à plusieurs angles.",
    "test_1rm": "Test de charge maximale sur une répétition.",
    "test_max_reps": "Test du maximum de répétitions.",
    "explosif": "Exécution explosive.",
    "singles_lourds": "Répétitions uniques lourdes.",
    "tempo": "Tempo imposé.",
    "pause": "Pause marquée.",
}
