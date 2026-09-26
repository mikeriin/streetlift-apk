"""Archétypes de mouvement : valeurs par défaut partagées par les variantes (KT-044).

Contenu généré par Claude (L9), non relu par un professionnel diplômé : voir
validation_register.md. Contrainte articulaire : chaîne de 8 chiffres (0 à 3)
dans l'ordre épaule, coude, poignet, rachis lombaire, rachis cervical, hanche,
genou, cheville.
"""

ARCH = {}

R_EXP_EFF = "Inspire en phase de descente ou de retour, expire pendant l'effort."
R_TENUE = "Respiration courte et régulière, sans bloquer ; ventre gainé."
R_LOURD = "Inspire et gaine avant la descente, bloque brièvement dans la phase difficile, expire après le passage."
R_CARDIO = "Respiration continue et rythmée ; accélère sans jamais bloquer."
R_MOB = "Respiration lente et ample ; expire en entrant dans l'amplitude."


def A(key, type_, prim, sec, charge, mesure, diff, stress, prec, equip, pose, cues, errs, resp=R_EXP_EFF,
      uni=False, plane=None, famille=None):
    assert len(stress) == 8, key
    ARCH[key] = {
        "type_mouvement": type_, "muscles_primaires": prim.split(), "muscles_secondaires": sec.split(),
        "mode_charge": charge, "mesure": mesure, "difficulte": diff,
        "contrainte": [int(c) for c in stress], "precautions": prec.split(), "materiel": equip.split(),
        "pose": pose, "points_cles": cues, "erreurs": errs, "respiration": resp, "unilateral": uni,
        "plan": plane, "famille": famille or key,
    }


# ---------------------------------------------------------------- POUSSÉES
A("pompe", "poussee_horizontale", "pectoraux triceps", "deltoide_anterieur dentele_anterieur abdominaux",
  "poids_de_corps", "repetitions", 3, "21210000", "poignet_extension epaule_anterieure", "aucun", "pompe.standard",
  ["Mains sous les épaules, doigts écartés", "Corps gainé en planche de la tête aux talons", "Coudes à environ 45° du buste, poitrine proche du sol"],
  ["Bassin qui s'affaisse ou remonte", "Coudes ouverts à 90° du corps"])
A("pompe_genoux", "poussee_horizontale", "pectoraux triceps", "deltoide_anterieur abdominaux",
  "poids_de_corps", "repetitions", 2, "11200000", "poignet_extension", "aucun", "pompe.genoux",
  ["Genoux au sol, alignement genoux-bassin-épaules", "Mains sous les épaules", "Descends la poitrine entre les mains"],
  ["Fesses en arrière (flexion de hanche)", "Amplitude réduite"])
A("pompe_inclinee", "poussee_horizontale", "pectoraux triceps", "deltoide_anterieur abdominaux",
  "poids_de_corps", "repetitions", 2, "11100000", "poignet_extension", "support_stable", "pompe.inclinee",
  ["Mains sur un support stable à hauteur de hanches", "Corps droit et gainé", "Poitrine jusqu'au bord du support"],
  ["Support qui glisse", "Tête qui avance avant la poitrine"])
A("pompe_mur", "poussee_horizontale", "pectoraux triceps", "deltoide_anterieur",
  "poids_de_corps", "repetitions", 1, "11100000", "", "mur", "pompe.mur",
  ["Pieds à un pas du mur, mains à hauteur d'épaules", "Corps droit, talons au sol", "Plie les coudes jusqu'à approcher le nez du mur"],
  ["Hanches cassées", "Mouvement trop rapide sans contrôle"])
A("pompe_declinee", "poussee_horizontale", "pectoraux deltoide_anterieur", "triceps abdominaux dentele_anterieur",
  "poids_de_corps", "repetitions", 4, "21210000", "poignet_extension epaule_anterieure", "support_stable", "pompe.declinee",
  ["Pieds surélevés, mains au sol", "Corps gainé, fessiers serrés", "Front vers l'avant des mains en bas"],
  ["Lombaires creusées", "Nuque cassée"])
A("pompe_diamant", "poussee_horizontale", "triceps pectoraux", "deltoide_anterieur abdominaux",
  "poids_de_corps", "repetitions", 5, "22310000", "poignet_extension coude", "aucun", "pompe.diamant",
  ["Mains rapprochées sous le sternum", "Coudes le long du corps", "Poitrine vers les mains"],
  ["Coudes qui s'ouvrent", "Poignets douloureux par manque d'échauffement"])
A("pompe_pseudo", "poussee_horizontale", "deltoide_anterieur pectoraux", "triceps biceps dentele_anterieur abdominaux",
  "poids_de_corps", "repetitions", 6, "32310000", "poignet_extension tendons_bras_tendus", "aucun", "pompe.pseudo",
  ["Mains au niveau des hanches, doigts vers l'extérieur ou l'arrière", "Épaules projetées en avant des mains", "Omoplates écartées, corps gainé"],
  ["Épaules qui reculent en descendant", "Bassin qui tombe"])
A("pompe_pike", "poussee_verticale", "deltoide_anterieur triceps", "trapezes dentele_anterieur",
  "poids_de_corps", "repetitions", 4, "22200000", "poignet_extension epaule_au_dessus_tete", "aucun", "pompe.pike",
  ["Hanches hautes, corps en V inversé", "Tête qui descend devant les mains", "Coudes vers l'arrière, pas sur les côtés"],
  ["Pousser vers l'avant au lieu du haut", "Hanches qui descendent"])
A("pompe_explosive", "poussee_horizontale", "pectoraux triceps", "deltoide_anterieur abdominaux",
  "poids_de_corps", "repetitions", 6, "22310000", "poignet_extension impacts", "aucun", "pompe.standard",
  ["Descente contrôlée puis poussée maximale", "Mains qui décollent du sol", "Réception bras légèrement fléchis"],
  ["Réception bras tendus", "Corps qui se désaxe en l'air"])
A("pompe_archer", "poussee_horizontale", "pectoraux triceps", "deltoide_anterieur abdominaux obliques",
  "poids_de_corps", "repetitions", 6, "22210000", "poignet_extension", "aucun", "pompe.standard",
  ["Mains très écartées", "Descends vers un bras, l'autre reste tendu", "Alterne les côtés"],
  ["Bras d'appui qui se plie", "Bassin qui tourne"], uni=True)
A("pompe_un_bras", "poussee_horizontale", "pectoraux triceps", "deltoide_anterieur obliques abdominaux",
  "poids_de_corps", "repetitions", 8, "32310000", "poignet_extension epaule_anterieure", "aucun", "pompe.standard",
  ["Pieds écartés, main sous l'épaule", "Tronc gainé contre la rotation", "Coude près du corps"],
  ["Bassin qui tourne vers le haut", "Amplitude partielle"], uni=True)
A("dips_barres", "poussee_verticale", "pectoraux triceps", "deltoide_anterieur",
  "poids_de_corps", "repetitions", 5, "22200000", "epaule_anterieure coude", "barres_paralleles", "dips.barres",
  ["Épaules basses, loin des oreilles", "Buste légèrement penché, coudes vers l'arrière", "Descends jusqu'à environ 90° aux coudes"],
  ["Épaules qui roulent en avant en bas", "Descente trop profonde sans contrôle"])
A("dips_banc", "poussee_verticale", "triceps", "pectoraux deltoide_anterieur",
  "poids_de_corps", "repetitions", 3, "32200000", "epaule_anterieure", "support_stable", "dips.banc",
  ["Mains au bord du support, doigts vers l'avant", "Dos proche du support", "Descends jusqu'à 90° aux coudes, pas plus bas"],
  ["Descente trop profonde qui tire sur l'avant de l'épaule", "Coudes qui s'écartent"])
A("dips_banc_genoux", "poussee_verticale", "triceps", "pectoraux deltoide_anterieur",
  "poids_de_corps", "repetitions", 2, "22200000", "epaule_anterieure", "support_stable", "dips.banc_genoux",
  ["Genoux fléchis, pieds à plat pour s'aider", "Dos proche du support", "Amplitude courte et contrôlée"],
  ["Pousser avec les jambes seulement", "Épaules qui montent aux oreilles"])
A("dips_anneaux", "poussee_verticale", "pectoraux triceps", "deltoide_anterieur coiffe_rotateurs abdominaux",
  "poids_de_corps", "repetitions", 7, "32200000", "epaule_anterieure", "anneaux", "dips.anneaux",
  ["Anneaux serrés contre le corps", "Stabilise avant de descendre", "Remonte en tournant les anneaux vers l'extérieur"],
  ["Anneaux qui s'écartent", "Épaules qui s'enroulent"])
A("dips_barre_fixe", "poussee_verticale", "pectoraux triceps", "deltoide_anterieur abdominaux",
  "poids_de_corps", "repetitions", 5, "22200000", "epaule_anterieure", "barre_fixe", "dips.barre_fixe",
  ["Barre devant les hanches, bras tendus", "Jambes légèrement devant pour l'équilibre", "Poitrine vers la barre, coudes en arrière"],
  ["Basculer en avant sans contrôle", "Descente partielle"])
A("support_hold", "figure_statique", "triceps deltoide_anterieur", "pectoraux trapezes abdominaux",
  "poids_de_corps", "temps", 3, "21200000", "", "barres_paralleles", "dips.support",
  ["Bras verrouillés, épaules basses", "Corps gainé, pointes de pieds tendues", "Regard devant"],
  ["Épaules haussées", "Coudes fléchis"], resp=R_TENUE)
A("iso_dips", "figure_statique", "pectoraux triceps", "deltoide_anterieur",
  "poids_de_corps", "temps", 5, "32200000", "epaule_anterieure", "barres_paralleles", "dips.iso_bas",
  ["Tiens la position basse contrôlée", "Épaules basses et en arrière", "Pousse fort dans les barres"],
  ["Descendre plus bas que l'amplitude maîtrisée", "Épaules qui avancent"], resp=R_TENUE)
A("developpe_couche", "poussee_horizontale", "pectoraux triceps", "deltoide_anterieur",
  "barre", "repetitions", 3, "21100000", "epaule_anterieure charge_axiale", "barre banc rack", "banc.couche",
  ["Omoplates serrées, pieds ancrés au sol", "Barre qui descend vers le bas des pectoraux", "Coudes à 45-70° du buste"],
  ["Fesses qui décollent du banc", "Barre qui rebondit sur la poitrine"], resp=R_LOURD)
A("developpe_couche_halteres", "poussee_horizontale", "pectoraux triceps", "deltoide_anterieur coiffe_rotateurs",
  "halteres", "repetitions", 3, "21100000", "epaule_anterieure", "halteres banc", "banc.couche",
  ["Omoplates serrées sur le banc", "Haltères qui descendent au niveau de la poitrine", "Poignets au-dessus des coudes"],
  ["Haltères qui partent vers l'extérieur", "Amplitude trop grande en bas"], resp=R_LOURD)
A("developpe_incline", "poussee_horizontale", "pectoraux deltoide_anterieur", "triceps",
  "barre", "repetitions", 3, "21100000", "epaule_anterieure", "barre banc rack", "banc.incline",
  ["Banc incliné à 30-45°", "Barre vers le haut des pectoraux", "Omoplates serrées"],
  ["Lombaires très cambrées", "Coudes trop ouverts"], resp=R_LOURD)
A("floor_press", "poussee_horizontale", "pectoraux triceps", "deltoide_anterieur",
  "barre", "repetitions", 3, "11100000", "", "barre rack", "banc.floor",
  ["Allongé au sol, genoux fléchis", "Coudes qui touchent le sol en douceur", "Pousse sans rebond"],
  ["Coudes qui claquent au sol", "Poignets cassés"], resp=R_LOURD)
A("ecarte", "isolation", "pectoraux", "deltoide_anterieur",
  "halteres", "repetitions", 3, "21000000", "epaule_anterieure", "halteres banc", "banc.ecarte",
  ["Coudes légèrement fléchis et fixes", "Ouvre jusqu'à sentir l'étirement sans douleur", "Referme comme pour enlacer un tronc"],
  ["Plier puis tendre les coudes (développé)", "Descente trop basse"])
A("ecarte_poulie", "isolation", "pectoraux", "deltoide_anterieur",
  "poulie", "repetitions", 2, "21000000", "", "poulie", "cable.pallof",
  ["Buste légèrement penché, un pied devant", "Coudes légèrement fléchis", "Mains qui se rejoignent devant la poitrine"],
  ["Épaules qui montent", "Charge trop lourde qui transforme le geste"])
A("pec_deck", "isolation", "pectoraux", "deltoide_anterieur",
  "machine", "repetitions", 2, "21000000", "epaule_anterieure", "machine", "assis.pec_deck",
  ["Dos plaqué au dossier", "Poignées à hauteur de poitrine", "Retour lent jusqu'à l'étirement confortable"],
  ["Épaules qui avancent", "Retour qui claque"])
A("developpe_militaire", "poussee_verticale", "deltoide_anterieur triceps", "deltoide_lateral trapezes abdominaux",
  "barre", "repetitions", 4, "21130000", "epaule_au_dessus_tete lombaire", "barre rack", "press.debout",
  ["Fessiers et abdos serrés", "Barre qui monte près du visage puis passe au-dessus de la tête", "Bras verrouillés, oreilles entre les bras"],
  ["Cambrure lombaire", "Barre qui part vers l'avant"], resp=R_LOURD)
A("developpe_halteres", "poussee_verticale", "deltoide_anterieur triceps", "deltoide_lateral trapezes",
  "halteres", "repetitions", 3, "21110000", "epaule_au_dessus_tete", "halteres", "press.debout",
  ["Haltères au niveau des épaules", "Pousse au-dessus de la tête sans cambrer", "Descente contrôlée"],
  ["Cambrure", "Coudes qui partent très en arrière"], resp=R_LOURD)
A("developpe_assis", "poussee_verticale", "deltoide_anterieur triceps", "deltoide_lateral trapezes",
  "halteres", "repetitions", 3, "21110000", "epaule_au_dessus_tete", "halteres banc", "press.assis",
  ["Dos contre le dossier", "Pousse à la verticale", "Descends jusqu'aux oreilles"],
  ["Décoller le dos", "Verrouiller brutalement les coudes"], resp=R_LOURD)
A("push_press", "poussee_verticale", "deltoide_anterieur triceps quadriceps", "fessiers trapezes abdominaux",
  "barre", "repetitions", 5, "21130220", "epaule_au_dessus_tete technique_prioritaire", "barre rack", "press.push",
  ["Petite flexion des genoux, buste vertical", "Impulsion des jambes puis poussée des bras", "Réception bras tendus, gainé"],
  ["Flexion trop profonde", "Barre qui part vers l'avant"], resp=R_LOURD)
A("landmine_press", "poussee_verticale", "deltoide_anterieur pectoraux triceps", "dentele_anterieur abdominaux",
  "barre", "repetitions", 3, "11100000", "", "barre", "press.debout",
  ["Barre calée dans un coin, main à l'épaule", "Pousse en diagonale vers le haut", "Tronc gainé sans rotation"],
  ["Rotation du buste", "Cambrure"], uni=True)
A("hspu", "poussee_verticale", "deltoide_anterieur triceps", "trapezes dentele_anterieur abdominaux",
  "poids_de_corps", "repetitions", 7, "32220300", "epaule_au_dessus_tete tete_en_bas cervical poignet_extension", "mur", "atr.hspu",
  ["Mains à 15-20 cm du mur", "Tête qui forme un triangle avec les mains", "Corps gainé, pousse le sol loin"],
  ["Chute de la tête sur le sol", "Dos qui s'arque contre le mur"])
A("elevation_laterale", "isolation", "deltoide_lateral", "trapezes deltoide_anterieur",
  "halteres", "repetitions", 2, "21000000", "", "halteres", "elevation.laterale",
  ["Coudes légèrement fléchis", "Monte jusqu'à l'horizontale", "Descente lente"],
  ["Élan du buste", "Épaules qui montent vers les oreilles"])
A("elevation_frontale", "isolation", "deltoide_anterieur", "deltoide_lateral dentele_anterieur",
  "halteres", "repetitions", 2, "21000000", "epaule_anterieure", "halteres", "elevation.frontale",
  ["Bras presque tendus", "Monte jusqu'à hauteur des yeux", "Buste immobile"],
  ["Élan", "Cambrure"])
A("oiseau", "isolation", "deltoide_posterieur rhomboides", "trapezes coiffe_rotateurs",
  "halteres", "repetitions", 2, "10110000", "", "halteres", "elevation.oiseau",
  ["Buste penché, dos plat", "Ouvre les bras sur les côtés, coudes souples", "Serre les omoplates en haut"],
  ["Dos rond", "Mouvement qui devient un rowing"])
A("extension_triceps_nuque", "isolation", "triceps", "",
  "halteres", "repetitions", 3, "22000000", "coude epaule_au_dessus_tete", "halteres", "triceps.nuque",
  ["Coudes pointés vers le haut", "Descends derrière la tête", "Tends complètement"],
  ["Coudes qui s'écartent", "Cambrure"])
A("extension_triceps_poulie", "isolation", "triceps", "",
  "poulie", "repetitions", 2, "02000000", "", "poulie", "triceps.poulie",
  ["Coudes collés au corps", "Tends complètement en bas", "Remonte jusqu'à 90°"],
  ["Épaules qui aident", "Coudes qui avancent"])
A("barre_front", "isolation", "triceps", "",
  "barre", "repetitions", 3, "13000000", "coude", "barre banc", "banc.barre_front",
  ["Bras verticaux, coudes fixes", "Barre vers le front ou derrière la tête", "Remonte sans ouvrir les coudes"],
  ["Coudes qui s'ouvrent", "Charge trop lourde"])
A("kickback", "isolation", "triceps", "deltoide_posterieur",
  "halteres", "repetitions", 2, "12100000", "", "halteres", "triceps.kickback",
  ["Buste penché, bras collé au corps", "Tends l'avant-bras vers l'arrière", "Pause bras tendu"],
  ["Balancer l'haltère", "Coude qui descend"])

# ---------------------------------------------------------------- TIRAGES
A("traction", "tirage_vertical", "grand_dorsal biceps", "rhomboides trapezes avant_bras abdominaux",
  "poids_de_corps", "repetitions", 5, "22100000", "suspension", "barre_fixe", "traction.standard.barre_fixe",
  ["Part bras tendus, épaules engagées", "Tire les coudes vers les hanches", "Menton au-dessus de la barre sans élan"],
  ["Demi-amplitude", "Balancement du corps"])
A("traction_anneaux", "tirage_vertical", "grand_dorsal biceps", "rhomboides avant_bras coiffe_rotateurs",
  "poids_de_corps", "repetitions", 5, "12100000", "suspension", "anneaux", "traction.standard.anneaux",
  ["Anneaux en prise neutre qui tournent librement", "Tire jusqu'aux épaules", "Descente contrôlée"],
  ["Anneaux qui s'écartent", "Balancement"])
A("traction_poitrine", "tirage_vertical", "grand_dorsal biceps rhomboides", "trapezes avant_bras",
  "poids_de_corps", "repetitions", 7, "22100000", "suspension", "barre_fixe", "traction.poitrine.barre_fixe",
  ["Poitrine vers la barre", "Coudes qui passent derrière le corps", "Buste légèrement incliné en arrière en haut"],
  ["Élan de jambes", "Menton qui cherche la barre"])
A("traction_explosive", "tirage_vertical", "grand_dorsal biceps", "rhomboides trapezes avant_bras",
  "poids_de_corps", "repetitions", 7, "22100000", "suspension", "barre_fixe", "traction.poitrine.barre_fixe",
  ["Départ bras tendus, sans élan", "Tire le plus vite et le plus haut possible", "Descente contrôlée"],
  ["Élan de jambes", "Descente relâchée"])
A("traction_l", "tirage_vertical", "grand_dorsal biceps abdominaux", "flechisseurs_hanche avant_bras",
  "poids_de_corps", "repetitions", 7, "22100000", "suspension", "barre_fixe", "traction.l_sit.barre_fixe",
  ["Jambes tendues à l'horizontale", "Tire sans laisser tomber les jambes", "Épaules basses"],
  ["Jambes qui descendent", "Dos rond"])
A("traction_archer", "tirage_vertical", "grand_dorsal biceps", "rhomboides avant_bras",
  "poids_de_corps", "repetitions", 8, "22100000", "suspension", "barre_fixe", "traction.standard.barre_fixe",
  ["Prise très large", "Monte vers une main, l'autre bras reste tendu", "Alterne les côtés"],
  ["Bras d'aide qui plie", "Élan"], uni=True)
A("traction_un_bras", "tirage_vertical", "grand_dorsal biceps avant_bras", "rhomboides abdominaux",
  "poids_de_corps", "repetitions", 10, "33200000", "suspension coude", "barre_fixe", "traction.standard.barre_fixe",
  ["Prise ferme, épaule engagée", "Corps gainé contre la rotation", "Descente très lente"],
  ["Rotation du corps", "Épaule qui s'étire passivement"], uni=True)
A("traction_negative", "tirage_vertical", "grand_dorsal biceps", "avant_bras rhomboides",
  "poids_de_corps", "repetitions", 3, "22100000", "suspension", "barre_fixe support_stable", "traction.standard.barre_fixe",
  ["Monte en sautant ou avec un support", "Descends en 3 à 5 secondes", "Contrôle jusqu'aux bras tendus"],
  ["Chute libre en fin de descente", "Épaules relâchées en bas"])
A("traction_assistee", "tirage_vertical", "grand_dorsal biceps", "avant_bras rhomboides",
  "assistance", "repetitions", 3, "12100000", "suspension", "barre_fixe elastique", "traction.standard.barre_fixe",
  ["Élastique sous un pied ou un genou", "Même technique que la traction complète", "Réduis l'élastique progressivement"],
  ["Rebondir sur l'élastique", "Amplitude partielle"])
A("traction_iso", "figure_statique", "grand_dorsal biceps", "avant_bras",
  "poids_de_corps", "temps", 4, "22100000", "suspension", "barre_fixe", "suspension.iso_haut.barre_fixe",
  ["Monte en position et bloque", "Épaules basses, poitrine ouverte", "Corps immobile"],
  ["Menton posé sur la barre", "Épaules qui montent aux oreilles"], resp=R_TENUE)
A("traction_kipping", "tirage_vertical", "grand_dorsal", "biceps abdominaux flechisseurs_hanche",
  "poids_de_corps", "repetitions", 6, "32100000", "suspension technique_prioritaire epaule_anterieure", "barre_fixe", "traction.standard.barre_fixe",
  ["Maîtrise d'abord 8 tractions strictes", "Balancement creux-creux contrôlé", "Le bassin lance, les bras finissent"],
  ["Balancement non contrôlé", "Kipping avant la force stricte"])
A("tirage_vertical_poulie", "tirage_vertical", "grand_dorsal biceps", "rhomboides trapezes",
  "poulie", "repetitions", 2, "11000000", "", "poulie", "assis.pulldown",
  ["Cuisses calées, buste légèrement incliné", "Tire la barre vers le haut de la poitrine", "Remonte bras tendus sans lâcher les épaules"],
  ["Tirer derrière la nuque", "Balancer le buste"])
A("rowing_australien", "tirage_horizontal", "grand_dorsal rhomboides biceps", "deltoide_posterieur abdominaux avant_bras",
  "poids_de_corps", "repetitions", 2, "11100000", "", "barre_basse", "traction.standard.barre_fixe",
  ["Barre à hauteur de taille, corps droit dessous", "Tire la poitrine vers la barre", "Serre les omoplates en haut"],
  ["Bassin qui tombe", "Cou tendu vers la barre"])
A("rowing_anneaux", "tirage_horizontal", "grand_dorsal rhomboides biceps", "deltoide_posterieur abdominaux",
  "poids_de_corps", "repetitions", 3, "11100000", "", "anneaux", "traction.standard.anneaux",
  ["Corps gainé, pieds au sol", "Tire les anneaux vers les côtes", "Plus le corps est horizontal, plus c'est dur"],
  ["Hanches qui cassent", "Épaules qui montent"])
A("rowing_barre", "tirage_horizontal", "grand_dorsal rhomboides", "biceps deltoide_posterieur lombaires ischios",
  "barre", "repetitions", 4, "11020100", "lombaire", "barre", "rowing.penche",
  ["Buste penché à 45°, dos plat", "Tire la barre vers le nombril", "Serre les omoplates"],
  ["Dos rond", "Buste qui se redresse pour tirer"], resp=R_LOURD)
A("rowing_halteres", "tirage_horizontal", "grand_dorsal rhomboides", "biceps deltoide_posterieur",
  "halteres", "repetitions", 3, "11010000", "lombaire", "halteres", "rowing.penche",
  ["Dos plat, appui stable", "Coude le long du corps vers la hanche", "Descente contrôlée"],
  ["Rotation du buste", "Haussement d'épaule"])
A("rowing_appui", "tirage_horizontal", "grand_dorsal rhomboides", "biceps deltoide_posterieur",
  "halteres", "repetitions", 2, "11000000", "", "halteres banc", "rowing.appui",
  ["Poitrine sur un banc incliné", "Tire les coudes vers le haut", "Pause en haut"],
  ["Poitrine qui décolle", "Élan"])
A("tirage_horizontal_poulie", "tirage_horizontal", "grand_dorsal rhomboides", "biceps deltoide_posterieur trapezes",
  "poulie", "repetitions", 2, "11000000", "", "poulie", "assis.row",
  ["Dos droit, genoux fléchis", "Tire la poignée vers le ventre", "Omoplates serrées en fin de course"],
  ["Buste qui balance", "Dos rond au retour"])
A("face_pull", "tirage_horizontal", "deltoide_posterieur coiffe_rotateurs", "rhomboides trapezes",
  "poulie", "repetitions", 2, "11000000", "", "poulie", "cable.face_pull",
  ["Poulie à hauteur de visage, corde", "Tire vers le front, coudes hauts", "Rotation externe en fin de course"],
  ["Charge trop lourde", "Coudes qui descendent"])
A("pull_apart", "tirage_horizontal", "deltoide_posterieur rhomboides", "coiffe_rotateurs trapezes",
  "elastique", "repetitions", 1, "10000000", "", "elastique", "cable.pull_apart",
  ["Bras tendus devant à hauteur d'épaules", "Écarte l'élastique jusqu'à la poitrine", "Retour lent"],
  ["Épaules qui montent", "Cambrure"])
A("straight_arm_pulldown", "isolation", "grand_dorsal", "triceps abdominaux",
  "poulie", "repetitions", 2, "10000000", "", "poulie", "cable.straight_arm",
  ["Bras tendus, buste légèrement penché", "Descends la barre vers les cuisses en arc", "Dos fixe"],
  ["Plier les coudes", "Balancer le buste"])
A("pullover", "isolation", "grand_dorsal", "pectoraux triceps",
  "poulie", "repetitions", 2, "20000000", "epaule_au_dessus_tete", "poulie", "cable.pullover",
  ["Bras presque tendus", "Arc de cercle au-dessus de la tête vers les cuisses", "Gainage fort"],
  ["Cambrure", "Flexion des coudes"])
A("shrug", "isolation", "trapezes", "avant_bras",
  "barre", "repetitions", 2, "10001000", "", "barre", "tirage.shrug",
  ["Bras tendus, épaules qui montent vers les oreilles", "Pause 1 s en haut", "Pas de rotation"],
  ["Rouler les épaules", "Tirer avec les bras"])
A("tirage_menton", "tirage_vertical", "deltoide_lateral trapezes", "biceps",
  "barre", "repetitions", 3, "21100000", "epaule_anterieure", "barre", "tirage.menton",
  ["Prise largeur d'épaules ou plus", "Coudes plus hauts que les mains", "Monte jusqu'au bas de la poitrine"],
  ["Prise trop serrée", "Monter trop haut avec douleur"])
A("curl", "isolation", "biceps", "avant_bras",
  "halteres", "repetitions", 2, "02000000", "", "halteres", "curl.debout",
  ["Coudes fixes le long du corps", "Monte en contractant", "Descends bras tendus"],
  ["Élan du buste", "Coudes qui avancent"])
A("curl_barre", "isolation", "biceps", "avant_bras",
  "barre", "repetitions", 2, "02100000", "", "barre", "curl.debout",
  ["Coudes fixes", "Poignets neutres", "Descente contrôlée"],
  ["Élan", "Poignets cassés"])
A("curl_poulie", "isolation", "biceps", "avant_bras",
  "poulie", "repetitions", 2, "02000000", "", "poulie", "curl.debout",
  ["Coudes fixes", "Tension continue", "Descente lente"], ["Élan", "Coudes qui avancent"])
A("curl_pupitre", "isolation", "biceps", "avant_bras",
  "barre", "repetitions", 2, "03000000", "coude", "barre banc", "curl.pupitre",
  ["Bras calés sur le pupitre", "Ne verrouille pas brutalement en bas", "Monte en contractant"],
  ["Descendre trop vite en extension", "Décoller les coudes"])
A("curl_marteau", "isolation", "biceps avant_bras", "",
  "halteres", "repetitions", 2, "02000000", "", "halteres", "curl.debout",
  ["Prise neutre, pouces vers le haut", "Coudes fixes", "Descente contrôlée"], ["Élan", "Poignets qui tournent"])

# ---------------------------------------------------------------- MEMBRES INFÉRIEURS
A("squat_pdc", "squat", "quadriceps fessiers", "adducteurs lombaires abdominaux",
  "poids_de_corps", "repetitions", 2, "00000220", "genou_flexion", "aucun", "squat.pdc",
  ["Pieds largeur d'épaules, pointes légèrement ouvertes", "Genoux dans l'axe des pieds", "Descends en gardant le dos droit, talons au sol"],
  ["Genoux qui rentrent vers l'intérieur", "Talons qui décollent"])
A("squat_assiste", "squat", "quadriceps fessiers", "adducteurs",
  "assistance", "repetitions", 1, "00000110", "", "support_stable", "squat.assiste",
  ["Tiens un support stable devant toi", "Descends en poussant les fesses en arrière", "Remonte en poussant dans les talons"],
  ["Tirer avec les bras", "Descente trop rapide"])
A("squat_chaise", "squat", "quadriceps fessiers", "adducteurs",
  "poids_de_corps", "repetitions", 1, "00000110", "", "support_stable", "squat.chaise",
  ["Chaise derrière toi", "Effleure l'assise sans t'asseoir complètement", "Remonte en poussant dans les pieds"],
  ["Se laisser tomber sur la chaise", "Genoux qui rentrent"])
A("squat_saute", "squat", "quadriceps fessiers", "mollets",
  "poids_de_corps", "repetitions", 4, "00000322", "impacts", "aucun", "squat.saute",
  ["Descente en squat contrôlé", "Saute en extension complète", "Réception souple, genoux dans l'axe"],
  ["Réception jambes tendues", "Genoux qui rentrent à la réception"])
A("squat_barre", "squat", "quadriceps fessiers", "adducteurs lombaires abdominaux",
  "barre", "repetitions", 4, "10020230", "charge_axiale genou_flexion lombaire", "barre rack", "squat.dos",
  ["Barre sur le haut du dos, gainage avant la descente", "Genoux dans l'axe, descente au moins à la parallèle", "Remonte en poussant le sol, poitrine haute"],
  ["Dos qui s'arrondit en bas", "Genoux qui rentrent en remontant"], resp=R_LOURD)
A("front_squat", "squat", "quadriceps fessiers", "abdominaux lombaires",
  "barre", "repetitions", 5, "12110230", "charge_axiale genou_flexion", "barre rack", "squat.front",
  ["Barre sur l'avant des épaules, coudes hauts", "Buste vertical", "Descente profonde contrôlée"],
  ["Coudes qui tombent", "Buste qui plonge"], resp=R_LOURD)
A("squat_gobelet", "squat", "quadriceps fessiers", "abdominaux adducteurs",
  "kettlebell", "repetitions", 2, "00010220", "genou_flexion", "kettlebell", "squat.gobelet",
  ["Charge tenue contre la poitrine", "Coudes entre les genoux en bas", "Buste droit"],
  ["Dos rond", "Talons qui décollent"])
A("squat_overhead", "squat", "quadriceps fessiers deltoide_anterieur", "trapezes abdominaux",
  "barre", "repetitions", 7, "30120230", "epaule_au_dessus_tete technique_prioritaire", "barre", "squat.overhead",
  ["Barre verrouillée au-dessus de la tête", "Pousse la barre vers le plafond pendant la descente", "Mobilité d'épaule et de cheville préalable"],
  ["Barre qui part vers l'avant", "Coudes qui fléchissent"], resp=R_LOURD)
A("box_squat", "squat", "quadriceps fessiers", "ischios lombaires",
  "barre", "repetitions", 4, "10020220", "charge_axiale", "barre rack box", "squat.box",
  ["Assieds-toi en contrôle sur la box", "Garde le gainage assis", "Remonte explosif"],
  ["Se relâcher sur la box", "Rebondir"], resp=R_LOURD)
A("wall_sit", "squat", "quadriceps", "fessiers",
  "poids_de_corps", "temps", 2, "00000200", "genou_flexion", "mur", "squat.wall_sit",
  ["Dos plaqué au mur", "Cuisses parallèles au sol", "Genoux au-dessus des chevilles"],
  ["Genoux devant les orteils", "Mains sur les cuisses"], resp=R_TENUE)
A("pistol", "squat", "quadriceps fessiers", "abdominaux flechisseurs_hanche mollets",
  "poids_de_corps", "repetitions", 8, "00010332", "genou_flexion equilibre", "aucun", "pistol.libre",
  ["Jambe libre tendue devant", "Talon d'appui au sol", "Descente lente jusqu'en bas"],
  ["Genou qui rentre", "Chute en bas de l'amplitude"], uni=True)
A("pistol_assiste", "squat", "quadriceps fessiers", "abdominaux",
  "assistance", "repetitions", 5, "00000322", "genou_flexion", "support_stable", "pistol.libre",
  ["Tiens un support ou un élastique", "Jambe libre devant", "Contrôle toute la descente"],
  ["Tirer uniquement avec les bras", "Genou qui rentre"], uni=True)
A("pistol_box", "squat", "quadriceps fessiers", "abdominaux",
  "poids_de_corps", "repetitions", 5, "00000322", "genou_flexion", "support_stable", "pistol.box",
  ["Box ou chaise derrière toi", "Descends sur une jambe jusqu'à effleurer", "Remonte sans élan"],
  ["S'asseoir lourdement", "Talon qui décolle"], uni=True)
A("shrimp_squat", "squat", "quadriceps fessiers", "abdominaux",
  "poids_de_corps", "repetitions", 7, "00000332", "genou_flexion equilibre", "aucun", "pistol.shrimp",
  ["Tiens le pied arrière derrière toi", "Genou arrière vers le sol", "Buste penché en avant pour l'équilibre"],
  ["Genou qui tape le sol", "Chute"], uni=True)
A("sissy_squat", "squat", "quadriceps", "abdominaux",
  "poids_de_corps", "repetitions", 6, "00000320", "genou_flexion", "support_stable", "squat.pdc",
  ["Sur la pointe des pieds, tiens un support", "Genoux vers l'avant, corps incliné en arrière", "Ligne genoux-épaules droite"],
  ["Casser à la hanche", "Descente trop profonde d'emblée"])
A("squat_cosaque", "fente", "quadriceps adducteurs fessiers", "ischios",
  "poids_de_corps", "repetitions", 4, "00000322", "genou_flexion adducteurs", "aucun", "fente.laterale",
  ["Grand écart latéral", "Descends sur une jambe, l'autre tendue, pointe vers le haut", "Talon de la jambe fléchie au sol"],
  ["Talon qui décolle", "Dos rond"], uni=True, plane="frontal")
A("presse", "squat", "quadriceps fessiers", "ischios",
  "machine", "repetitions", 2, "00010220", "genou_flexion", "machine", "assis.press",
  ["Pieds largeur de bassin sur le plateau", "Descends sans décoller le bassin", "Ne verrouille pas les genoux"],
  ["Bassin qui s'enroule en bas", "Genoux verrouillés"])
A("hack_squat", "squat", "quadriceps", "fessiers",
  "machine", "repetitions", 3, "00010230", "genou_flexion", "machine", "squat.dos",
  ["Dos plaqué, pieds au milieu du plateau", "Descente contrôlée", "Remonte sans verrouiller"],
  ["Talons qui décollent", "Rebond en bas"])
A("leg_extension", "isolation", "quadriceps", "",
  "machine", "repetitions", 2, "00000200", "genou_flexion", "machine", "assis.leg_extension",
  ["Axe de la machine aligné sur le genou", "Monte jusqu'à l'extension", "Descente lente"], ["Élan", "Bassin qui décolle"])
A("fente", "fente", "quadriceps fessiers", "adducteurs ischios mollets",
  "poids_de_corps", "repetitions", 3, "00000221", "genou_flexion equilibre", "aucun", "fente.avant",
  ["Grand pas, buste droit", "Genou arrière vers le sol", "Genou avant dans l'axe du pied"],
  ["Genou avant qui rentre", "Pas trop court"], uni=True)
A("fente_laterale", "fente", "quadriceps adducteurs fessiers", "ischios",
  "poids_de_corps", "repetitions", 3, "00000221", "adducteurs", "aucun", "fente.laterale",
  ["Grand pas sur le côté", "Pousse les fesses en arrière sur la jambe fléchie", "Jambe opposée tendue"],
  ["Genou qui dépasse vers l'intérieur", "Dos rond"], uni=True, plane="frontal")
A("fente_bulgare", "fente", "quadriceps fessiers", "adducteurs ischios",
  "poids_de_corps", "repetitions", 5, "00000321", "genou_flexion equilibre", "support_stable", "fente.bulgare",
  ["Pied arrière posé sur un support", "Descends à la verticale", "Genou avant dans l'axe"],
  ["Pied avant trop proche", "Bascule du bassin"], uni=True)
A("fente_sautee", "fente", "quadriceps fessiers", "mollets",
  "poids_de_corps", "repetitions", 5, "00000332", "impacts genou_flexion", "aucun", "fente.avant",
  ["Fente basse, saut et changement de jambe en l'air", "Réception souple", "Buste droit"],
  ["Réception genou arrière qui tape", "Perte d'équilibre"], uni=True)
A("step_up", "fente", "quadriceps fessiers", "ischios mollets",
  "poids_de_corps", "repetitions", 2, "00000221", "", "support_stable", "step.bas",
  ["Pied entier sur le support", "Pousse avec la jambe du haut", "Redescends lentement"],
  ["Pousser avec la jambe du bas", "Genou qui rentre"], uni=True)
A("skater_squat", "squat", "quadriceps fessiers", "abdominaux",
  "poids_de_corps", "repetitions", 6, "00000322", "genou_flexion equilibre", "aucun", "pistol.shrimp",
  ["Jambe arrière fléchie derrière", "Genou arrière vers le sol", "Bras devant pour l'équilibre"],
  ["Chute en bas", "Genou avant qui rentre"], uni=True)
A("sdt", "charniere_hanche", "fessiers ischios lombaires", "quadriceps trapezes avant_bras",
  "barre", "repetitions", 5, "10030210", "lombaire charge_axiale technique_prioritaire", "barre", "hinge.sol",
  ["Barre au-dessus du milieu du pied", "Dos neutre, gainage avant de tirer", "Pousse le sol et verrouille les hanches"],
  ["Dos rond", "Barre qui s'éloigne des jambes"], resp=R_LOURD)
A("sdt_roumain", "charniere_hanche", "ischios fessiers", "lombaires avant_bras",
  "barre", "repetitions", 4, "10020100", "lombaire", "barre", "hinge.barre",
  ["Genoux légèrement fléchis et fixes", "Pousse les hanches en arrière, barre au contact des cuisses", "Descends jusqu'à l'étirement des ischios, dos plat"],
  ["Dos rond", "Plier les genoux comme un squat"], resp=R_LOURD)
A("sdt_unijambe", "charniere_hanche", "ischios fessiers", "moyen_fessier lombaires",
  "halteres", "repetitions", 5, "00010111", "equilibre lombaire", "halteres", "hinge.unijambe",
  ["Jambe libre dans le prolongement du buste", "Bassin horizontal", "Genou d'appui souple"],
  ["Bassin qui s'ouvre", "Dos rond"], uni=True)
A("good_morning", "charniere_hanche", "ischios lombaires", "fessiers",
  "barre", "repetitions", 5, "10030100", "lombaire charge_axiale", "barre rack", "hinge.barre",
  ["Barre sur le haut du dos", "Hanches en arrière, dos neutre", "Charge légère"], ["Dos rond", "Charge excessive"], resp=R_LOURD)
A("charniere_baton", "charniere_hanche", "ischios fessiers", "lombaires",
  "poids_de_corps", "repetitions", 1, "00010100", "", "baton", "hinge.barre",
  ["Bâton le long du dos : tête, haut du dos et sacrum au contact", "Recule les hanches, genoux souples", "Remonte en serrant les fessiers"],
  ["Bâton qui décolle de la tête ou du bassin", "Flexion de genoux excessive"])
A("pont_fessier", "charniere_hanche", "fessiers", "ischios lombaires",
  "poids_de_corps", "repetitions", 1, "00010100", "", "aucun", "pont.fessier",
  ["Pieds à plat, près des fesses", "Monte le bassin en serrant les fessiers", "Pause 1 s en haut, sans cambrer"],
  ["Cambrure lombaire en haut", "Pousser sur la nuque"])
A("hip_thrust", "charniere_hanche", "fessiers", "ischios quadriceps",
  "barre", "repetitions", 3, "00010200", "", "barre banc", "banc.hip_thrust",
  ["Haut du dos sur le banc", "Menton rentré, pousse les hanches", "Pause en haut, tibias verticaux"],
  ["Cambrure", "Pieds trop loin"])
A("swing", "charniere_hanche", "fessiers ischios", "lombaires abdominaux avant_bras",
  "kettlebell", "repetitions", 4, "10020100", "lombaire technique_prioritaire", "kettlebell", "olympique.swing",
  ["Charnière de hanche, pas un squat", "Explosion des hanches, bras relâchés", "Kettlebell à hauteur de poitrine"],
  ["Lever avec les bras", "Dos rond en bas"])
A("hyperextension", "charniere_hanche", "lombaires fessiers ischios", "",
  "poids_de_corps", "repetitions", 2, "00020100", "lombaire", "ghd", "hinge.barre",
  ["Bassin calé sur le coussin", "Descends dos neutre", "Remonte jusqu'à l'alignement, pas plus"],
  ["Hyperextension en haut", "Élan"])
A("leg_curl_machine", "isolation", "ischios", "mollets",
  "machine", "repetitions", 2, "00000200", "", "machine", "assis.leg_curl",
  ["Axe aligné sur le genou", "Fléchis complètement", "Retour lent"], ["Bassin qui décolle", "Élan"])
A("leg_curl_sol", "isolation", "ischios", "fessiers",
  "poids_de_corps", "repetitions", 4, "00010200", "", "serviette", "pont.fessier",
  ["Pont fessier, talons sur les disques ou le ballon", "Ramène les talons en gardant le bassin haut", "Retour lent"],
  ["Bassin qui tombe", "Mouvement saccadé"])
A("nordic", "isolation", "ischios", "fessiers",
  "poids_de_corps", "repetitions", 7, "00000300", "genou_flexion", "support_stable", "genoux.nordic",
  ["Chevilles bloquées, genoux sur un coussin", "Corps droit des genoux à la tête", "Freine la chute le plus longtemps possible"],
  ["Casser à la hanche", "Chute sans freinage"])
A("mollets", "isolation", "mollets", "",
  "poids_de_corps", "repetitions", 1, "00000002", "", "aucun", "mollets.debout",
  ["Monte sur la pointe des pieds", "Pause en haut", "Descends talons sous la marche si possible"],
  ["Rebond", "Amplitude courte"])
A("mollets_unijambe", "isolation", "mollets", "",
  "poids_de_corps", "repetitions", 2, "00000002", "", "support_stable", "mollets.unijambe",
  ["Sur une marche, une jambe", "Amplitude complète", "Tiens un appui pour l'équilibre"], ["Rebond", "Genou qui plie"], uni=True)
A("mollets_assis", "isolation", "mollets", "",
  "machine", "repetitions", 1, "00000002", "", "machine", "assis.calf_seated",
  ["Genoux calés", "Amplitude complète", "Pause en haut"], ["Rebond", "Amplitude courte"])
A("tibial", "isolation", "tibial_anterieur", "",
  "poids_de_corps", "repetitions", 1, "00000002", "", "mur", "mollets.debout",
  ["Dos au mur, talons en avant", "Lève les pointes de pieds", "Descente lente"], ["Plier les genoux", "Élan"])
A("abducteurs", "isolation", "moyen_fessier", "fessiers",
  "machine", "repetitions", 1, "00000100", "", "machine", "assis.abduction",
  ["Dos plaqué", "Écarte en contrôle", "Retour lent"], ["Élan", "Buste qui bascule"], plane="frontal")
A("adducteurs_machine", "isolation", "adducteurs", "",
  "machine", "repetitions", 1, "00000100", "adducteurs", "machine", "assis.adduction",
  ["Amplitude confortable", "Serre en contrôle", "Retour lent"], ["Amplitude forcée", "Élan"], plane="frontal")
A("clamshell", "isolation", "moyen_fessier", "fessiers",
  "elastique", "repetitions", 1, "00000100", "", "elastique", "pont.fessier",
  ["Allongé sur le côté, genoux fléchis", "Ouvre le genou du dessus sans rouler le bassin", "Retour lent"],
  ["Bassin qui roule en arrière", "Vitesse excessive"], plane="frontal")
A("monster_walk", "locomotion", "moyen_fessier", "fessiers quadriceps",
  "elastique", "distance", 1, "00000110", "", "elastique", "locomotion.marche",
  ["Élastique au-dessus des genoux ou aux chevilles", "Demi-squat, pas latéraux", "Genoux vers l'extérieur"],
  ["Pieds qui se rejoignent", "Buste qui oscille"], plane="frontal")
A("kick_back_poulie", "isolation", "fessiers", "ischios",
  "poulie", "repetitions", 2, "00010100", "", "poulie", "hinge.unijambe",
  ["Buste légèrement penché, appui stable", "Pousse la jambe en arrière en serrant le fessier", "Sans cambrer"],
  ["Cambrure", "Élan"], uni=True)

# ---------------------------------------------------------------- GAINAGE ET TRONC
A("planche_coudes", "gainage_anti_extension", "abdominaux transverse", "deltoide_anterieur fessiers",
  "poids_de_corps", "temps", 2, "10100000", "", "aucun", "planche_gainage.coudes",
  ["Coudes sous les épaules", "Fessiers et abdos serrés", "Ligne droite de la tête aux talons"],
  ["Bassin qui s'affaisse", "Fesses trop hautes"], resp=R_TENUE)
A("planche_genoux", "gainage_anti_extension", "abdominaux transverse", "deltoide_anterieur",
  "poids_de_corps", "temps", 1, "10000000", "", "aucun", "planche_gainage.genoux",
  ["Genoux au sol, coudes sous les épaules", "Ligne genoux-épaules droite", "Respire calmement"],
  ["Fesses en arrière", "Nuque cassée"], resp=R_TENUE)
A("planche_bras_tendus", "gainage_anti_extension", "abdominaux transverse", "deltoide_anterieur dentele_anterieur",
  "poids_de_corps", "temps", 2, "11200000", "poignet_extension", "aucun", "planche_gainage.bras_tendus",
  ["Mains sous les épaules", "Pousse le sol, omoplates écartées", "Corps gainé"],
  ["Bassin qui tombe", "Épaules enfoncées"], resp=R_TENUE)
A("planche_rkc", "gainage_anti_extension", "abdominaux transverse", "fessiers dentele_anterieur",
  "poids_de_corps", "temps", 4, "10100000", "", "aucun", "planche_gainage.coudes",
  ["Coudes tirés vers les pieds, pieds tirés vers les coudes", "Fessiers contractés au maximum", "Séries courtes de 10 à 20 s"],
  ["Tenue longue et relâchée", "Respiration bloquée"], resp=R_TENUE)
A("planche_laterale", "gainage_anti_flexion_laterale", "obliques transverse", "moyen_fessier abdominaux",
  "poids_de_corps", "temps", 2, "20000100", "", "aucun", "planche_laterale.standard",
  ["Coude sous l'épaule", "Hanches hautes, corps aligné", "Épaule loin de l'oreille"],
  ["Bassin qui tombe", "Buste qui tourne"], resp=R_TENUE, uni=True, plane="frontal")
A("copenhague", "gainage_anti_flexion_laterale", "adducteurs obliques", "transverse moyen_fessier",
  "poids_de_corps", "temps", 5, "20000210", "adducteurs", "support_stable", "planche_laterale.copenhague",
  ["Jambe du dessus sur le banc", "Bassin haut, corps aligné", "Commence genou posé (levier court)"],
  ["Bassin qui tombe", "Levier long trop tôt"], resp=R_TENUE, uni=True, plane="frontal")
A("hollow", "gainage_anti_extension", "abdominaux transverse", "flechisseurs_hanche",
  "poids_de_corps", "temps", 3, "00100000", "", "aucun", "dos_au_sol.hollow",
  ["Lombaires plaquées au sol", "Bras et jambes tendus, décollés", "Menton rentré"],
  ["Bas du dos qui décolle", "Jambes trop basses pour son niveau"], resp=R_TENUE)
A("hollow_groupe", "gainage_anti_extension", "abdominaux transverse", "flechisseurs_hanche",
  "poids_de_corps", "temps", 2, "00000000", "", "aucun", "dos_au_sol.hollow_tuck",
  ["Genoux ramenés, tibias parallèles au sol", "Lombaires plaquées", "Épaules légèrement décollées"],
  ["Dos qui se creuse", "Nuque tirée par les mains"], resp=R_TENUE)
A("hollow_rocks", "gainage_anti_extension", "abdominaux transverse", "flechisseurs_hanche",
  "poids_de_corps", "repetitions", 4, "00100000", "", "aucun", "dos_au_sol.hollow",
  ["Position creuse verrouillée", "Bascule d'avant en arrière", "Garde la forme, pas de pliage"],
  ["Casser la position en se pliant", "Bas du dos qui décolle"])
A("dead_bug", "gainage_anti_extension", "abdominaux transverse", "flechisseurs_hanche",
  "poids_de_corps", "repetitions", 1, "00000000", "", "aucun", "dos_au_sol.dead_bug",
  ["Bras vers le plafond, genoux à 90°", "Tends bras et jambe opposés en expirant", "Lombaires plaquées"],
  ["Dos qui se creuse", "Mouvement rapide"])
A("bird_dog", "gainage_anti_rotation", "lombaires fessiers transverse", "deltoide_posterieur",
  "poids_de_corps", "repetitions", 1, "00100000", "", "aucun", "ventre.bird_dog",
  ["À quatre pattes, dos plat", "Tends bras et jambe opposés", "Bassin horizontal, sans rotation"],
  ["Cambrure", "Bassin qui tourne"])
A("ab_wheel", "gainage_anti_extension", "abdominaux transverse", "grand_dorsal dentele_anterieur triceps",
  "poids_de_corps", "repetitions", 6, "20120000", "lombaire", "roue_abdos", "genoux.ab_wheel",
  ["Genoux au sol, bassin rentré", "Roule loin sans laisser le dos se creuser", "Reviens en tirant avec les abdos"],
  ["Lombaires qui s'affaissent", "Amplitude au-delà du contrôle"])
A("body_saw", "gainage_anti_extension", "abdominaux transverse", "deltoide_anterieur dentele_anterieur",
  "poids_de_corps", "repetitions", 4, "20100000", "", "serviette", "planche_gainage.coudes",
  ["Planche coudes, pieds sur disques glissants", "Recule et avance par les épaules", "Bassin fixe"],
  ["Bassin qui tombe", "Amplitude trop grande"])
A("pallof", "gainage_anti_rotation", "obliques transverse", "abdominaux",
  "elastique", "repetitions", 2, "10000000", "", "elastique", "cable.pallof",
  ["De profil par rapport à l'ancrage", "Pousse les mains devant la poitrine", "Résiste à la rotation, bassin fixe"],
  ["Buste qui tourne", "Épaules qui montent"], plane="transversal")
A("woodchop", "gainage_anti_rotation", "obliques abdominaux", "deltoide_anterieur fessiers",
  "poulie", "repetitions", 3, "10100000", "lombaire", "poulie", "cable.woodchop",
  ["Rotation depuis les hanches et le haut du dos", "Bras tendus", "Contrôle au retour"],
  ["Rotation lombaire forcée", "Tirer avec les bras"], plane="transversal")
A("landmine_rotation", "gainage_anti_rotation", "obliques abdominaux", "deltoide_anterieur",
  "barre", "repetitions", 5, "10200000", "lombaire", "barre", "cable.woodchop",
  ["Barre en arc de cercle d'une hanche à l'autre", "Pieds qui pivotent", "Bras presque tendus"],
  ["Rotation lombaire forcée", "Vitesse excessive"], plane="transversal")
A("suitcase_carry", "portes", "obliques avant_bras", "trapezes transverse moyen_fessier",
  "kettlebell", "distance", 2, "00100000", "", "kettlebell", "locomotion.porte",
  ["Une charge d'un seul côté", "Buste parfaitement droit", "Pas réguliers"],
  ["Pencher du côté de la charge", "Épaule qui s'affaisse"], uni=True, plane="frontal")
A("side_bend", "gainage_anti_flexion_laterale", "obliques", "lombaires",
  "halteres", "repetitions", 2, "00100000", "lombaire", "halteres", "face.inclinaison",
  ["Haltère d'un côté", "Inclinaison latérale contrôlée", "Pas de rotation"], ["Élan", "Rotation"], uni=True, plane="frontal")
A("windmill", "gainage_anti_flexion_laterale", "obliques deltoide_lateral", "ischios fessiers",
  "kettlebell", "repetitions", 6, "20200100", "epaule_au_dessus_tete lombaire technique_prioritaire", "kettlebell", "face.windmill",
  ["Kettlebell verrouillée au-dessus de la tête", "Regard sur la kettlebell", "Descends la main libre le long de la jambe"],
  ["Coude qui plie", "Dos rond"], uni=True, plane="frontal")
A("crunch", "flexion_tronc", "abdominaux", "obliques",
  "poids_de_corps", "repetitions", 1, "00002000", "cervical", "aucun", "dos_au_sol.crunch",
  ["Genoux fléchis, pieds au sol", "Enroule le haut du dos", "Ne tire pas sur la nuque"],
  ["Tirer la tête avec les mains", "Élan"])
A("crunch_poulie", "flexion_tronc", "abdominaux", "obliques",
  "poulie", "repetitions", 3, "00101000", "", "poulie", "cable.crunch",
  ["À genoux, corde près de la tête", "Enroule le buste vers les genoux", "Hanches immobiles"], ["Tirer avec les bras", "S'asseoir sur les talons"])
A("situp", "flexion_tronc", "abdominaux flechisseurs_hanche", "obliques",
  "poids_de_corps", "repetitions", 2, "00111000", "lombaire", "aucun", "dos_au_sol.situp",
  ["Genoux fléchis, pieds calés ou libres", "Enroule jusqu'à la position assise", "Redescends vertèbre par vertèbre"],
  ["Élan des bras", "Tirer la nuque"])
A("relevé_jambes", "flexion_tronc", "abdominaux flechisseurs_hanche", "obliques",
  "poids_de_corps", "repetitions", 3, "00100000", "lombaire", "aucun", "dos_au_sol.leg_raise",
  ["Lombaires plaquées", "Monte les jambes tendues à la verticale", "Descends sans que le dos se creuse"],
  ["Dos qui décolle en bas", "Élan"])
A("v_ups", "flexion_tronc", "abdominaux flechisseurs_hanche", "obliques",
  "poids_de_corps", "repetitions", 4, "00100000", "", "aucun", "dos_au_sol.vup",
  ["Bras et jambes tendus", "Ferme le corps en V", "Redescends en contrôle"], ["Jambes pliées", "Chute"])
A("flutter", "gainage_anti_extension", "abdominaux flechisseurs_hanche", "",
  "poids_de_corps", "temps", 2, "00100000", "lombaire", "aucun", "dos_au_sol.flutter",
  ["Lombaires plaquées", "Petits battements jambes tendues", "Jambes plus hautes si le dos décolle"],
  ["Dos qui se creuse", "Amplitude trop grande"], resp=R_TENUE)
A("russian_twist", "gainage_anti_rotation", "obliques abdominaux", "flechisseurs_hanche",
  "poids_de_corps", "repetitions", 2, "00200000", "lombaire", "aucun", "dos_au_sol.twist",
  ["Assis, buste incliné, dos long", "Tourne les épaules, pas seulement les bras", "Pieds au sol pour commencer"],
  ["Dos rond", "Rotation des bras seuls"], plane="transversal")
A("suspension_genoux", "flexion_tronc", "abdominaux flechisseurs_hanche", "avant_bras grand_dorsal",
  "poids_de_corps", "repetitions", 3, "10100000", "suspension", "barre_fixe", "suspension.knee_raise.barre_fixe",
  ["Suspendu, épaules engagées", "Monte les genoux en enroulant le bassin", "Descente sans balancer"],
  ["Balancement", "Monter les genoux sans enrouler le bassin"])
A("suspension_jambes", "flexion_tronc", "abdominaux flechisseurs_hanche", "avant_bras grand_dorsal",
  "poids_de_corps", "repetitions", 5, "10100000", "suspension", "barre_fixe", "suspension.leg_raise.barre_fixe",
  ["Jambes tendues", "Monte au moins à l'horizontale", "Contrôle la descente"], ["Balancement", "Genoux qui plient"])
A("toes_to_bar", "flexion_tronc", "abdominaux flechisseurs_hanche grand_dorsal", "avant_bras obliques",
  "poids_de_corps", "repetitions", 6, "20100000", "suspension", "barre_fixe", "suspension.toes_to_bar.barre_fixe",
  ["Épaules actives, bras tendus", "Pointes de pieds jusqu'à la barre", "Descente contrôlée"], ["Balancement non maîtrisé", "Genoux pliés"])
A("windshield", "gainage_anti_rotation", "obliques abdominaux", "grand_dorsal avant_bras",
  "poids_de_corps", "repetitions", 8, "20200100", "suspension lombaire", "barre_fixe", "suspension.windshield.barre_fixe",
  ["Jambes à la verticale sous la barre", "Bascule d'un côté à l'autre", "Épaules fixes"], ["Jambes qui descendent", "Élan"], plane="transversal")
A("dragon_flag", "gainage_anti_extension", "abdominaux transverse", "grand_dorsal flechisseurs_hanche",
  "poids_de_corps", "repetitions", 8, "20203100", "lombaire cervical", "banc", "dos_au_sol.dragon_flag",
  ["Appui sur le haut du dos, mains agrippées", "Corps droit comme une planche", "Descente lente sans casser aux hanches"],
  ["Bassin qui se plie", "Appui sur la nuque"])
A("superman", "gainage_anti_extension", "lombaires fessiers", "deltoide_posterieur trapezes",
  "poids_de_corps", "temps", 1, "00100000", "lombaire", "aucun", "ventre.superman",
  ["Allongé sur le ventre", "Décolle bras et jambes légèrement", "Regard vers le sol"], ["Cambrure excessive", "Nuque en extension"], resp=R_TENUE)
A("ytw", "isolation", "deltoide_posterieur trapezes coiffe_rotateurs", "rhomboides",
  "halteres", "repetitions", 2, "10000000", "", "halteres banc", "ventre.ytw",
  ["Buste sur un banc incliné", "Dessine Y, T puis W avec les bras", "Charge très légère"], ["Élan", "Charge trop lourde"])

# ---------------------------------------------------------------- FIGURES (street workout)
A("dead_hang", "figure_statique", "avant_bras grand_dorsal", "coiffe_rotateurs",
  "poids_de_corps", "temps", 1, "11100000", "suspension", "barre_fixe", "suspension.passif.barre_fixe",
  ["Prise complète, pouce autour de la barre", "Laisse le corps pendre, respiration calme", "Pieds qui peuvent toucher le sol au début"],
  ["Lâcher brutalement", "Balancer"], resp=R_TENUE)
A("active_hang", "figure_statique", "grand_dorsal trapezes avant_bras", "coiffe_rotateurs",
  "poids_de_corps", "temps", 2, "11100000", "suspension", "barre_fixe", "suspension.scap.barre_fixe",
  ["Suspendu bras tendus", "Tire les épaules vers le bas", "Garde la position active"], ["Coudes qui plient", "Épaules relâchées"], resp=R_TENUE)
A("scap_pull", "tirage_vertical", "trapezes grand_dorsal", "rhomboides avant_bras",
  "poids_de_corps", "repetitions", 2, "11100000", "suspension", "barre_fixe", "suspension.scap.barre_fixe",
  ["Bras tendus", "Abaisse et resserre les omoplates", "Relâche lentement"], ["Plier les coudes", "Mouvement trop rapide"])
A("false_grip", "figure_statique", "avant_bras", "biceps grand_dorsal",
  "poids_de_corps", "temps", 5, "12300000", "suspension poignet_extension", "anneaux", "suspension.passif.anneaux",
  ["Poignet posé sur l'anneau ou la barre", "Tiens la prise sans glisser", "Durées courtes au début"], ["Prise qui glisse", "Douleur au poignet ignorée"], resp=R_TENUE)
A("german_hang", "mobilite", "deltoide_anterieur pectoraux biceps", "",
  "poids_de_corps", "temps", 6, "32000000", "epaule_anterieure tendons_bras_tendus", "anneaux", "suspension.german.barre_fixe",
  ["Pieds au sol au début pour doser", "Descends lentement en rotation arrière", "Durées courtes"],
  ["Forcer l'amplitude", "Rester trop longtemps"], resp=R_MOB)
A("skin_the_cat", "figure_dynamique", "grand_dorsal abdominaux", "deltoide_anterieur biceps",
  "poids_de_corps", "repetitions", 6, "32000100", "suspension tete_en_bas epaule_anterieure", "barre_fixe", "suspension.skin_cat.barre_fixe",
  ["Genoux groupés, passe les jambes entre les bras", "Descends jusqu'au German hang contrôlé", "Reviens par le même chemin"],
  ["Chute en arrière", "Amplitude forcée"])
A("front_lever", "figure_statique", "grand_dorsal abdominaux", "rhomboides biceps deltoide_posterieur",
  "poids_de_corps", "temps", 7, "22110000", "suspension tendons_bras_tendus", "barre_fixe", "levier.front_tuck",
  ["Bras tendus, omoplates abaissées", "Corps horizontal sous la barre", "Bassin aligné, sans cassure"],
  ["Coudes qui plient", "Hanches qui tombent"], resp=R_TENUE)
A("back_lever", "figure_statique", "grand_dorsal pectoraux biceps", "abdominaux lombaires",
  "poids_de_corps", "temps", 6, "32100000", "suspension tendons_bras_tendus epaule_anterieure", "barre_fixe", "levier.back_tuck",
  ["Passe par le German hang", "Corps horizontal, face vers le sol", "Bras tendus, gainage fort"],
  ["Épaules en extension forcée", "Bassin cassé"], resp=R_TENUE)
A("front_lever_dyn", "figure_dynamique", "grand_dorsal abdominaux", "rhomboides biceps",
  "poids_de_corps", "repetitions", 7, "22110000", "suspension tendons_bras_tendus", "barre_fixe", "levier.front_tuck.dynamique",
  ["Bras tendus", "Monte le corps d'une traite jusqu'à l'horizontale", "Descente contrôlée"], ["Plier les bras", "Élan"])
A("muscle_up", "figure_dynamique", "grand_dorsal pectoraux triceps", "biceps abdominaux avant_bras",
  "poids_de_corps", "repetitions", 8, "32100000", "suspension technique_prioritaire", "barre_fixe", "muscle_up.complet.barre_fixe",
  ["Tirage explosif jusqu'au bas de la poitrine", "Passe les poignets et bascule le buste au-dessus", "Finis en dip bras tendus"],
  ["Transition d'un seul bras (chicken wing)", "Tirage trop bas"])
A("muscle_up_anneaux", "figure_dynamique", "grand_dorsal pectoraux triceps", "biceps avant_bras abdominaux",
  "poids_de_corps", "repetitions", 8, "32300000", "suspension technique_prioritaire poignet_extension", "anneaux", "muscle_up.complet.anneaux",
  ["Fausse prise (false grip)", "Tire les anneaux vers les côtes", "Transition rapide, anneaux près du corps"], ["Perdre la fausse prise", "Anneaux qui s'écartent"])
A("muscle_up_negatif", "figure_dynamique", "grand_dorsal pectoraux triceps", "biceps",
  "poids_de_corps", "repetitions", 6, "32100000", "suspension", "barre_fixe support_stable", "muscle_up.negatif.barre_fixe",
  ["Monte en appui au-dessus de la barre", "Descends lentement à travers la transition", "Contrôle jusqu'aux bras tendus"], ["Chute dans la transition", "Descente trop rapide"])
A("muscle_up_transition", "figure_dynamique", "pectoraux triceps grand_dorsal", "biceps",
  "assistance", "repetitions", 5, "32100000", "suspension", "barre_fixe elastique", "muscle_up.transition.barre_fixe",
  ["Barre basse ou élastique d'assistance", "Travaille le passage des coudes au-dessus de la barre", "Poitrine qui passe devant les mains"], ["Assistance trop forte", "Coudes qui s'écartent"])
A("muscle_up_iso", "figure_statique", "pectoraux triceps grand_dorsal", "biceps",
  "poids_de_corps", "temps", 7, "32100000", "suspension", "barre_fixe", "muscle_up.iso_transition.barre_fixe",
  ["Bloque dans la zone de transition", "Poitrine au-dessus des mains", "Tiens 3 à 6 s par angle"], ["Épaules qui s'enroulent", "Tenue trop longue"], resp=R_TENUE)
A("lsit", "figure_statique", "abdominaux flechisseurs_hanche triceps", "quadriceps deltoide_anterieur",
  "poids_de_corps", "temps", 5, "21210000", "poignet_extension", "barres_paralleles", "lsit.l",
  ["Bras verrouillés, épaules basses", "Jambes tendues à l'horizontale", "Pointes de pieds tendues"], ["Épaules haussées", "Genoux pliés"], resp=R_TENUE)
A("lsit_tuck", "figure_statique", "abdominaux flechisseurs_hanche triceps", "deltoide_anterieur",
  "poids_de_corps", "temps", 3, "21100000", "", "barres_paralleles", "lsit.tuck",
  ["Genoux ramenés vers la poitrine", "Épaules basses", "Bassin décollé"], ["Épaules haussées", "Coudes pliés"], resp=R_TENUE)
A("lsit_une_jambe", "figure_statique", "abdominaux flechisseurs_hanche triceps", "quadriceps",
  "poids_de_corps", "temps", 4, "21100000", "", "barres_paralleles", "lsit.one",
  ["Une jambe tendue, l'autre groupée", "Alterne les jambes", "Épaules basses"], ["Jambe tendue qui tombe", "Épaules haussées"], resp=R_TENUE, uni=True)
A("vsit", "figure_statique", "abdominaux flechisseurs_hanche triceps", "quadriceps deltoide_anterieur",
  "poids_de_corps", "temps", 9, "31210000", "poignet_extension", "barres_paralleles", "lsit.v",
  ["Passe par un L-sit solide", "Monte les jambes au-dessus de l'horizontale", "Pousse fort, épaules en avant"], ["Dos rond non contrôlé", "Genoux pliés"], resp=R_TENUE)
A("manna", "figure_statique", "abdominaux flechisseurs_hanche triceps deltoide_posterieur", "pectoraux",
  "poids_de_corps", "temps", 10, "33310000", "poignet_extension tendons_bras_tendus", "barres_paralleles", "lsit.v",
  ["Figure élite : V-sit maîtrisé requis", "Épaules en extension, mains derrière", "Tenue très courte"], ["Forcer l'amplitude d'épaule", "Progression trop rapide"], resp=R_TENUE)
A("planche_skill", "figure_statique", "deltoide_anterieur pectoraux", "biceps triceps dentele_anterieur abdominaux",
  "poids_de_corps", "temps", 7, "32310000", "poignet_extension tendons_bras_tendus", "aucun", "planche_skill.tuck",
  ["Bras tendus, épaules en avant des mains", "Omoplates écartées, dos légèrement rond", "Bassin à hauteur d'épaules"], ["Coudes qui plient", "Épaules qui reculent"], resp=R_TENUE)
A("planche_lean", "figure_statique", "deltoide_anterieur pectoraux", "biceps dentele_anterieur abdominaux",
  "poids_de_corps", "temps", 4, "22300000", "poignet_extension tendons_bras_tendus", "aucun", "planche_gainage.lean",
  ["Position de pompe, épaules avancées au-delà des mains", "Bras verrouillés", "Omoplates écartées"], ["Bassin qui tombe", "Coudes qui plient"], resp=R_TENUE)
A("pseudo_planche_hold", "figure_statique", "deltoide_anterieur pectoraux", "biceps dentele_anterieur",
  "poids_de_corps", "temps", 5, "22300000", "poignet_extension tendons_bras_tendus", "aucun", "planche_gainage.pseudo_hold",
  ["Mains aux hanches, doigts vers l'arrière", "Épaules en avant", "Corps gainé"], ["Épaules qui reculent", "Bassin qui tombe"], resp=R_TENUE)
A("atr", "figure_statique", "deltoide_anterieur trapezes", "triceps abdominaux avant_bras",
  "poids_de_corps", "temps", 7, "22300000", "poignet_extension tete_en_bas equilibre chute_arriere", "aucun", "atr.libre",
  ["Mains largeur d'épaules, doigts écartés", "Corps aligné, épaules ouvertes", "Équilibre par les doigts"], ["Dos creusé en banane", "Coudes fléchis"], resp=R_TENUE)
A("atr_dos_mur", "figure_statique", "deltoide_anterieur trapezes", "triceps abdominaux",
  "poids_de_corps", "temps", 4, "22300000", "poignet_extension tete_en_bas", "mur", "atr.dos_mur",
  ["Mains à 15-20 cm du mur", "Talons au mur, corps gainé", "Pousse le sol"], ["Dos en banane", "Tête qui rentre"], resp=R_TENUE)
A("atr_poitrine_mur", "figure_statique", "deltoide_anterieur trapezes", "triceps abdominaux",
  "poids_de_corps", "temps", 5, "22300000", "poignet_extension tete_en_bas", "mur", "atr.poitrine_mur",
  ["Monte en marchant les pieds au mur", "Poitrine vers le mur, corps droit", "Mains proches du mur"], ["Dos creusé", "Épaules fermées"], resp=R_TENUE)
A("atr_taps", "figure_dynamique", "deltoide_anterieur trapezes", "triceps abdominaux obliques",
  "poids_de_corps", "repetitions", 6, "32300000", "poignet_extension tete_en_bas", "mur", "atr.taps",
  ["ATR poitrine au mur", "Transfère le poids puis touche l'épaule opposée", "Corps immobile"], ["Hanches qui tournent", "Chute"])
A("wall_walk", "figure_dynamique", "deltoide_anterieur triceps", "abdominaux trapezes",
  "poids_de_corps", "repetitions", 5, "22300000", "poignet_extension tete_en_bas", "mur", "atr.wall_walk",
  ["Départ en planche, pieds au mur", "Monte en marchant les mains vers le mur", "Redescends en contrôle"], ["Dos creusé", "Descente précipitée"])
A("handstand_walk", "locomotion", "deltoide_anterieur trapezes", "triceps abdominaux avant_bras",
  "poids_de_corps", "distance", 8, "22300000", "poignet_extension tete_en_bas equilibre chute_arriere", "aucun", "atr.libre",
  ["Équilibre stable d'abord", "Petits pas de mains", "Épaules au-dessus des mains"], ["Grands pas déséquilibrants", "Dos creusé"])
A("drapeau", "figure_statique", "obliques grand_dorsal deltoide_lateral", "abdominaux triceps",
  "poids_de_corps", "temps", 9, "32100100", "tendons_bras_tendus", "poteau", "drapeau.full",
  ["Bras du haut tire, bras du bas pousse", "Bras verrouillés", "Corps horizontal aligné"], ["Bassin qui tombe", "Coude du bas qui plie"], resp=R_TENUE, plane="frontal")

# ---------------------------------------------------------------- PORTÉS, LOCOMOTION, CONDITIONNEMENT
A("farmer", "portes", "avant_bras trapezes", "transverse fessiers quadriceps",
  "halteres", "distance", 2, "11100000", "", "halteres", "locomotion.porte",
  ["Une charge dans chaque main", "Buste droit, épaules basses", "Pas courts et réguliers"], ["Épaules qui s'enroulent", "Pencher"])
A("farmer_hold", "portes", "avant_bras trapezes", "transverse",
  "halteres", "temps", 2, "11100000", "", "halteres", "debout.grip",
  ["Tiens deux charges lourdes immobile", "Épaules basses", "Respire calmement"], ["Épaules qui montent", "Dos rond"], resp=R_TENUE)
A("overhead_carry", "portes", "deltoide_anterieur trapezes transverse", "triceps obliques",
  "kettlebell", "distance", 4, "21100000", "epaule_au_dessus_tete", "kettlebell", "locomotion.overhead",
  ["Bras verrouillé au-dessus de la tête", "Côtes basses, pas de cambrure", "Marche lente"], ["Coude qui plie", "Cambrure"], uni=True)
A("sandbag_carry", "portes", "trapezes abdominaux avant_bras", "quadriceps fessiers",
  "objet_leste", "distance", 3, "11200000", "lombaire", "sac_leste", "locomotion.porte",
  ["Sac serré contre la poitrine", "Dos droit", "Pas réguliers"], ["Dos rond", "Pencher en arrière"])
A("marche", "locomotion", "quadriceps fessiers mollets", "ischios",
  "poids_de_corps", "temps", 1, "00000111", "", "espace_exterieur", "locomotion.marche",
  ["Posture droite, bras relâchés", "Pas réguliers", "Allure confortable permettant de parler"], ["Allure trop rapide", "Épaules crispées"], resp=R_CARDIO)
A("marche_lestee", "locomotion", "quadriceps fessiers mollets trapezes", "lombaires",
  "lest", "distance", 3, "00100111", "charge_axiale", "lest espace_exterieur", "locomotion.marche",
  ["Sac bien ajusté, charge haute", "Pas réguliers", "Augmente la charge progressivement"], ["Charge trop lourde d'emblée", "Pencher en avant"], resp=R_CARDIO)
A("course", "locomotion", "quadriceps ischios mollets fessiers", "flechisseurs_hanche",
  "poids_de_corps", "temps", 3, "00000122", "impacts", "espace_exterieur", "locomotion.course",
  ["Foulée courte, pied sous le bassin", "Buste légèrement penché", "Allure conversationnelle pour l'endurance"], ["Attaque talon loin devant", "Allure trop rapide"], resp=R_CARDIO)
A("sprint", "locomotion", "quadriceps ischios fessiers mollets", "flechisseurs_hanche",
  "poids_de_corps", "distance", 6, "00010233", "impacts cardio_intense", "espace_exterieur", "locomotion.sprint",
  ["Échauffement progressif obligatoire", "Bras actifs, genoux hauts", "Récupération complète entre les répétitions"], ["Sprinter à froid", "Enchaîner sans récupérer"], resp=R_CARDIO)
A("crawl", "locomotion", "deltoide_anterieur abdominaux quadriceps", "triceps flechisseurs_hanche",
  "poids_de_corps", "distance", 3, "11200110", "poignet_extension", "sol_degage", "quadrupedie.bear_crawl",
  ["Genoux à quelques centimètres du sol", "Bras et jambe opposés avancent ensemble", "Dos plat"], ["Fesses trop hautes", "Genoux qui touchent"])
A("crab_walk", "locomotion", "triceps fessiers", "deltoide_anterieur ischios",
  "poids_de_corps", "distance", 3, "22200110", "poignet_extension epaule_anterieure", "sol_degage", "quadrupedie.crab",
  ["Mains derrière, doigts vers les pieds", "Bassin haut", "Petits pas coordonnés"], ["Bassin qui tombe", "Épaules qui s'enroulent"])
A("inchworm", "mobilite", "ischios abdominaux deltoide_anterieur", "",
  "poids_de_corps", "repetitions", 2, "11110100", "poignet_extension", "sol_degage", "cardio.burpee",
  ["Mains au sol jambes presque tendues", "Avance les mains jusqu'à la planche", "Ramène les pieds en petits pas"], ["Genoux très pliés", "Bassin qui s'affaisse"])
A("burpee", "conditionnement", "quadriceps pectoraux", "triceps fessiers abdominaux",
  "poids_de_corps", "repetitions", 4, "21200221", "cardio_intense impacts poignet_extension", "aucun", "cardio.burpee",
  ["Mains au sol, saute en planche", "Poitrine au sol ou pompe", "Remonte et saute bras en haut"], ["Dos qui s'affaisse en planche", "Réception jambes tendues"], resp=R_CARDIO)
A("mountain_climbers", "conditionnement", "abdominaux flechisseurs_hanche", "deltoide_anterieur quadriceps",
  "poids_de_corps", "temps", 3, "11200100", "poignet_extension", "aucun", "quadrupedie.mountain",
  ["Planche bras tendus", "Genoux vers la poitrine en alternance", "Bassin stable"], ["Fesses hautes", "Épaules qui reculent"], resp=R_CARDIO)
A("jumping_jacks", "conditionnement", "mollets deltoide_lateral", "quadriceps",
  "poids_de_corps", "temps", 1, "10000012", "impacts", "aucun", "cardio.jacks",
  ["Sur l'avant des pieds", "Bras et jambes coordonnés", "Réception souple"], ["Réception talons lourds", "Genoux verrouillés"], resp=R_CARDIO, plane="frontal")
A("genoux_hauts", "conditionnement", "flechisseurs_hanche quadriceps mollets", "abdominaux",
  "poids_de_corps", "temps", 2, "00000112", "impacts", "aucun", "locomotion.course",
  ["Genoux à hauteur de hanches", "Sur l'avant des pieds", "Bras actifs"], ["Buste en arrière", "Réception lourde"], resp=R_CARDIO)
A("skaters", "conditionnement", "fessiers quadriceps moyen_fessier", "mollets",
  "poids_de_corps", "repetitions", 3, "00000122", "impacts equilibre", "aucun", "fente.laterale",
  ["Bond latéral d'une jambe à l'autre", "Réception stable genou fléchi", "Buste penché"], ["Réception genou qui rentre", "Déséquilibre"], resp=R_CARDIO, plane="frontal")
A("corde_a_sauter", "conditionnement", "mollets", "deltoide_lateral avant_bras quadriceps",
  "poids_de_corps", "temps", 2, "01100012", "impacts", "corde_a_sauter", "corde.saut",
  ["Petits sauts sur l'avant des pieds", "Rotation par les poignets", "Coudes près du corps"], ["Sauts trop hauts", "Bras qui tournent"], resp=R_CARDIO)
A("pogo", "conditionnement", "mollets", "quadriceps",
  "poids_de_corps", "repetitions", 3, "00000013", "impacts", "aucun", "corde.saut",
  ["Genoux presque tendus", "Rebonds rapides sur l'avant des pieds", "Contact au sol le plus court possible"], ["Talons qui touchent", "Genoux qui plient"], resp=R_CARDIO)
A("saut", "conditionnement", "quadriceps fessiers mollets", "ischios",
  "poids_de_corps", "repetitions", 4, "00010332", "impacts", "aucun", "saut.vertical",
  ["Élan des bras", "Extension complète chevilles-genoux-hanches", "Réception souple et silencieuse"], ["Réception jambes tendues", "Genoux qui rentrent"])
A("box_jump", "conditionnement", "quadriceps fessiers mollets", "ischios",
  "poids_de_corps", "repetitions", 4, "00000322", "impacts", "box", "saut.box",
  ["Box à hauteur maîtrisée", "Réception pieds entiers au centre", "Redescends en marchant"], ["Box trop haute", "Redescendre en sautant en arrière"])
A("depth_jump", "conditionnement", "quadriceps fessiers mollets", "ischios",
  "poids_de_corps", "repetitions", 7, "00010333", "impacts", "box", "saut.vertical",
  ["Tombe d'une box basse", "Contact au sol très court", "Rebondis immédiatement vers le haut"], ["Box trop haute", "Réception écrasée"])
A("ergo_rameur", "conditionnement", "grand_dorsal quadriceps fessiers", "biceps ischios lombaires",
  "machine", "temps", 2, "11010110", "", "ergometre", "ergo.rameur",
  ["Ordre : jambes, buste, bras", "Retour : bras, buste, jambes", "Dos droit"], ["Tirer d'abord avec les bras", "Dos rond"], resp=R_CARDIO)
A("ergo_velo", "conditionnement", "quadriceps fessiers", "mollets ischios",
  "machine", "temps", 1, "00000110", "", "ergometre", "ergo.velo",
  ["Selle à hauteur de hanche", "Genou légèrement fléchi en bas", "Cadence régulière"], ["Selle trop basse", "Balancer les épaules"], resp=R_CARDIO)
A("ergo_ski", "conditionnement", "grand_dorsal triceps abdominaux", "quadriceps fessiers",
  "machine", "temps", 2, "11010100", "", "ergometre", "ergo.skierg",
  ["Bras hauts, tire en fléchissant les hanches", "Gainage fort", "Retour bras en haut"], ["Dos rond", "Tirer seulement avec les bras"], resp=R_CARDIO)
A("battle_rope", "conditionnement", "deltoide_anterieur avant_bras", "abdominaux quadriceps",
  "objet_leste", "temps", 3, "21100110", "", "battle_rope", "corde.battle",
  ["Demi-squat, gainage", "Vagues alternées régulières", "Épaules basses"], ["Dos rond", "Épaules crispées"], resp=R_CARDIO)
A("sled_push", "conditionnement", "quadriceps fessiers mollets", "triceps abdominaux",
  "objet_leste", "distance", 4, "11000122", "", "traineau", "traineau.push",
  ["Bras tendus, corps penché", "Pas puissants", "Dos plat"], ["Dos rond", "Bras pliés"], resp=R_CARDIO)
A("sled_pull", "conditionnement", "quadriceps fessiers grand_dorsal", "biceps avant_bras",
  "objet_leste", "distance", 4, "11100121", "", "traineau", "traineau.pull",
  ["Recule en tirant la corde", "Genoux fléchis", "Tronc gainé"], ["Tirer avec le dos", "Buste trop penché"], resp=R_CARDIO)
A("slam", "conditionnement", "grand_dorsal abdominaux", "deltoide_anterieur fessiers",
  "objet_leste", "repetitions", 3, "21110100", "lombaire", "medecine_ball", "lancer.slam",
  ["Balle au-dessus de la tête, extension complète", "Lance au sol de toutes tes forces", "Ramasse dos plat"], ["Dos rond au ramassage", "Rebond dans le visage"])
A("wall_ball", "conditionnement", "quadriceps fessiers deltoide_anterieur", "triceps abdominaux",
  "objet_leste", "repetitions", 4, "21000220", "genou_flexion", "medecine_ball mur", "lancer.wall_ball",
  ["Squat complet balle contre la poitrine", "Pousse jambes et bras vers la cible", "Rattrape et enchaîne"], ["Squat partiel", "Lancer seulement avec les bras"])
A("thruster", "conditionnement", "quadriceps fessiers deltoide_anterieur triceps", "abdominaux trapezes",
  "barre", "repetitions", 6, "21120230", "epaule_au_dessus_tete charge_axiale", "barre", "olympique.thruster",
  ["Front squat complet", "Utilise l'élan des jambes pour pousser", "Verrouille au-dessus de la tête"], ["Coudes qui tombent en bas", "Cambrure en haut"])
A("clean", "figure_dynamique", "fessiers ischios quadriceps trapezes", "lombaires deltoide_anterieur avant_bras",
  "barre", "repetitions", 7, "21230220", "technique_prioritaire lombaire", "barre", "olympique.clean",
  ["Départ dos plat, barre proche", "Extension explosive des hanches", "Réception coudes hauts en front squat"], ["Tirer avec les bras", "Barre loin du corps"], resp=R_LOURD)
A("snatch", "figure_dynamique", "fessiers ischios quadriceps trapezes deltoide_anterieur", "lombaires triceps",
  "barre", "repetitions", 9, "31230330", "technique_prioritaire epaule_au_dessus_tete lombaire", "barre", "olympique.snatch",
  ["Prise large, barre proche", "Extension explosive puis passage sous la barre", "Réception bras verrouillés en squat"], ["Barre loin du corps", "Bras qui tirent trop tôt"], resp=R_LOURD)
A("clean_press", "figure_dynamique", "fessiers ischios deltoide_anterieur triceps", "trapezes abdominaux",
  "kettlebell", "repetitions", 5, "21220110", "technique_prioritaire epaule_au_dessus_tete", "kettlebell", "olympique.clean_press",
  ["Épaulé : la charge roule sur l'avant-bras", "Pause en rack", "Développé sans cambrer"], ["Charge qui tape l'avant-bras", "Cambrure"])
A("kb_snatch", "figure_dynamique", "fessiers ischios deltoide_anterieur", "trapezes avant_bras abdominaux",
  "kettlebell", "repetitions", 7, "22220100", "technique_prioritaire epaule_au_dessus_tete", "kettlebell", "olympique.snatch",
  ["Swing puissant", "Poing qui passe à travers la poignée", "Verrouille au-dessus de la tête"], ["Kettlebell qui tape le poignet", "Tirer avec le bras"], uni=True)
A("turkish", "figure_dynamique", "deltoide_anterieur abdominaux fessiers", "obliques triceps quadriceps",
  "kettlebell", "repetitions", 6, "21210110", "technique_prioritaire", "kettlebell", "turkish.getup",
  ["Bras chargé verrouillé, regard sur la charge", "Étapes : coude, main, pont, genou, debout", "Chaque étape contrôlée"], ["Coude chargé qui plie", "Perdre la charge des yeux"])
A("man_maker", "conditionnement", "pectoraux grand_dorsal quadriceps deltoide_anterieur", "triceps abdominaux fessiers",
  "halteres", "repetitions", 7, "22210220", "cardio_intense poignet_extension", "halteres", "cardio.burpee",
  ["Pompe sur haltères", "Rowing de chaque côté", "Épaulé puis développé"], ["Bassin qui tourne au rowing", "Dos rond au relevé"], resp=R_CARDIO)
A("devil_press", "conditionnement", "fessiers ischios deltoide_anterieur pectoraux", "triceps trapezes",
  "halteres", "repetitions", 6, "22220110", "cardio_intense", "halteres", "cardio.burpee",
  ["Burpee sur les haltères", "Swing des haltères entre les jambes", "Finis bras tendus au-dessus de la tête"], ["Dos rond", "Tirer avec les bras"], resp=R_CARDIO)

# ---------------------------------------------------------------- MOBILITÉ, PRÉVENTION, RÉCUPÉRATION
A("rotation_externe", "isolation", "coiffe_rotateurs", "deltoide_posterieur",
  "elastique", "repetitions", 1, "10000000", "", "elastique", "cable.rotation_ext",
  ["Coude collé au corps, fléchi à 90°", "Tourne l'avant-bras vers l'extérieur", "Retour lent"], ["Coude qui s'écarte", "Charge trop lourde"])
A("cuban_press", "isolation", "coiffe_rotateurs deltoide_lateral", "trapezes",
  "halteres", "repetitions", 3, "20000000", "epaule_au_dessus_tete", "halteres", "tirage.menton",
  ["Tirage menton léger", "Rotation externe coudes à 90°", "Développé au-dessus de la tête"], ["Charge trop lourde", "Mouvement précipité"])
A("dislocations", "mobilite", "deltoide_anterieur coiffe_rotateurs pectoraux", "",
  "poids_de_corps", "repetitions", 1, "10000000", "epaule_au_dessus_tete", "baton", "debout.dislocation",
  ["Prise très large", "Passe au-dessus de la tête bras tendus", "Resserre la prise avec les progrès"], ["Plier les coudes", "Cambrure"], resp=R_MOB)
A("wall_slides", "mobilite", "dentele_anterieur trapezes", "coiffe_rotateurs",
  "poids_de_corps", "repetitions", 1, "10000000", "", "mur", "debout.wall_slide",
  ["Dos, tête et avant-bras contre le mur", "Glisse les bras vers le haut", "Côtes basses"], ["Cambrure", "Avant-bras qui décollent"], resp=R_MOB)
A("scapular_pushup", "isolation", "dentele_anterieur", "pectoraux",
  "poids_de_corps", "repetitions", 1, "10100000", "poignet_extension", "aucun", "planche_gainage.bras_tendus",
  ["Planche bras tendus", "Rapproche puis écarte les omoplates", "Coudes verrouillés"], ["Plier les coudes", "Bassin qui tombe"])
A("pont_dorsal", "mobilite", "deltoide_anterieur lombaires fessiers", "triceps quadriceps",
  "poids_de_corps", "temps", 5, "22310000", "lombaire poignet_extension epaule_au_dessus_tete", "aucun", "dos_au_sol.bridge",
  ["Mains près des oreilles, doigts vers les pieds", "Pousse les épaules au-dessus des mains", "Bras tendus"], ["Tout forcer dans le bas du dos", "Épaules fermées"], resp=R_MOB)
A("mobilite_hanches", "mobilite", "fessiers adducteurs flechisseurs_hanche", "",
  "poids_de_corps", "temps", 1, "00000100", "", "aucun", "assis_sol.flexion",
  ["Assis, jambes en 90/90", "Buste long, bascule vers la jambe avant", "Change de côté"], ["Dos rond", "Forcer sur le genou"], resp=R_MOB)
A("etirement_flechisseurs", "mobilite", "flechisseurs_hanche quadriceps", "",
  "poids_de_corps", "temps", 1, "00000100", "", "aucun", "genoux.hip_flexor",
  ["Genou arrière au sol", "Serre le fessier arrière, bassin rétroversé", "Avance légèrement le bassin"], ["Cambrure", "Genou avant qui dépasse beaucoup"], resp=R_MOB, uni=True)
A("etirement_posterieur", "mobilite", "ischios mollets lombaires", "",
  "poids_de_corps", "temps", 1, "00010000", "", "aucun", "debout.etirement_post",
  ["Genoux légèrement fléchis", "Bascule depuis les hanches", "Respire dans l'étirement"], ["Rebondir", "Forcer dos rond"], resp=R_MOB)
A("mobilite_thoracique", "mobilite", "lombaires obliques", "trapezes",
  "poids_de_corps", "repetitions", 1, "00100000", "", "aucun", "ventre.cat_cow",
  ["À quatre pattes", "Alterne dos rond et dos creux lentement", "Rotations bras vers le plafond"], ["Mouvement brusque", "Coudes pliés"], resp=R_MOB, plane="transversal")
A("mobilite_complete", "mobilite", "fessiers ischios deltoide_anterieur", "",
  "poids_de_corps", "temps", 1, "00000000", "", "aucun", "debout.rotations_bras",
  ["Enchaîne épaules, hanches, chevilles", "Amplitude progressive", "Sans douleur"], ["Aller trop vite", "Forcer"], resp=R_MOB)
A("mobilite_poignets", "mobilite", "avant_bras", "",
  "poids_de_corps", "repetitions", 1, "00100000", "", "aucun", "debout.poignets",
  ["Cercles de poignets", "Appuis doigts vers l'avant puis vers l'arrière", "Charge progressive"], ["Forcer l'extension", "Aller trop vite"], resp=R_MOB)
A("mobilite_chevilles", "mobilite", "mollets", "tibial_anterieur",
  "poids_de_corps", "repetitions", 1, "00000011", "", "mur", "debout.cheville",
  ["Pied à 10 cm du mur", "Genou vers le mur, talon au sol", "Recule le pied avec les progrès"], ["Talon qui décolle", "Genou qui rentre"], resp=R_MOB)
A("squat_profond_tenu", "mobilite", "quadriceps fessiers adducteurs", "mollets",
  "poids_de_corps", "temps", 2, "00000221", "genou_flexion", "aucun", "debout.squat_profond",
  ["Descends au fond du squat", "Talons au sol, dos long", "Coudes poussent les genoux vers l'extérieur"], ["Talons qui décollent", "Dos rond"], resp=R_MOB)
A("cercles_bras", "mobilite", "deltoide_anterieur deltoide_lateral coiffe_rotateurs", "",
  "poids_de_corps", "repetitions", 1, "10000000", "", "aucun", "debout.rotations_bras",
  ["Cercles lents, bras tendus", "Amplitude croissante", "Dans les deux sens"], ["Amplitude forcée", "Cambrure"], resp=R_MOB)
A("jefferson", "mobilite", "lombaires ischios", "",
  "barre", "repetitions", 6, "00030000", "lombaire technique_prioritaire", "aucun", "debout.jefferson",
  ["À vide d'abord, charge très légère ensuite", "Enroule vertèbre par vertèbre", "Déroule lentement"], ["Charge lourde", "Mouvement rapide"], resp=R_MOB)
A("foam", "mobilite", "quadriceps ischios mollets", "",
  "poids_de_corps", "temps", 1, "00000000", "", "foam_roller", "sol.foam",
  ["Passe lentement sur le muscle", "Pause sur les zones tendues", "Évite les os et articulations"], ["Rouler trop vite", "Appui sur une articulation"], resp=R_MOB)
A("respiration", "hors_categorie", "transverse", "",
  "poids_de_corps", "temps", 1, "00000000", "", "aucun", "debout.respiration",
  ["Inspire 5 s par le nez", "Expire 5 s", "Épaules relâchées"], ["Respiration thoracique haute", "Forcer"], resp=R_MOB)
A("prehension", "isolation", "avant_bras", "",
  "poids_de_corps", "repetitions", 1, "01100000", "", "gripper", "debout.grip",
  ["Serre complètement", "Relâche lentement", "Alterne les mains"], ["Poignet cassé", "Volume excessif"], uni=True)
A("poignet_flexion", "isolation", "avant_bras", "",
  "halteres", "repetitions", 1, "01100000", "", "halteres", "debout.poignets",
  ["Avant-bras posé, poignet dans le vide", "Amplitude complète", "Charge légère"], ["Charge lourde", "Élan"])
A("poignet_rotation", "isolation", "avant_bras", "",
  "halteres", "repetitions", 1, "01100000", "", "halteres", "debout.poignets",
  ["Coude fléchi à 90°, près du corps", "Tourne lentement l'haltère", "Tiens l'haltère par une extrémité"], ["Coude qui s'écarte", "Rotation rapide"])
A("rice_bucket", "isolation", "avant_bras", "",
  "poids_de_corps", "temps", 1, "01100000", "", "aucun", "debout.poignets",
  ["Mains dans un seau de riz", "Ouvre, ferme, tourne", "Séries de 30 à 60 s"], ["Forcer", "Volume excessif"], resp=R_TENUE)
A("extension_doigts", "isolation", "avant_bras", "",
  "elastique", "repetitions", 1, "00100000", "", "elastique", "debout.grip",
  ["Élastique autour des doigts", "Ouvre les doigts", "Retour lent"], ["Élan", "Élastique trop dur"])
A("wrist_roller", "isolation", "avant_bras", "deltoide_anterieur",
  "lest", "repetitions", 3, "12100000", "", "lest", "debout.grip",
  ["Bras tendus devant", "Enroule la corde en tournant les poignets", "Déroule lentement"], ["Bras qui baissent", "Épaules crispées"])
A("pinch", "portes", "avant_bras", "",
  "lest", "temps", 3, "01100000", "", "disques", "debout.grip",
  ["Pince les disques entre le pouce et les doigts", "Bras le long du corps", "Temps court et intense"], ["Poignet cassé", "Épaules haussées"], resp=R_TENUE)
