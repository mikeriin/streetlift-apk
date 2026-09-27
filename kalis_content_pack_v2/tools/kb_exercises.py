"""Rattachement des 505 exercices de la base v1 (assets/exercises_db.json.gz) au
schéma v2, et exercices ajoutés (KT-044). Généré par Claude (L9) — à relire.

E(nom_v1, archétype, difficulté, **options)
Options : pose, eq (matériel), charge, mesure, uni, mods (liste), base (nom de
l'exercice dont c'est une variante de méthode ou de charge), doublon (nom v1 du
doublon canonique), nc (non-conformité détectée), role (exercice | test |
hors_generateur), type, prim, sec, nom (nom v2 corrigé), alias.
"""

EX = []


def E(name, arch, diff, **kw):
    EX.append(dict(name=name, arch=arch, diff=diff, **kw))


# ------------------------------------------------------------------ A – C
E("Ab wheel", "ab_wheel", 6, alias=["roue abdominale à genoux"])
E("Ab wheel debout", "ab_wheel", 9, pose="debout.ab_wheel", nc="Matériel v1 « poids de corps » : une roue est nécessaire.")
E("Abducteurs machine", "abducteurs", 1)
E("Adducteurs machine", "adducteurs_machine", 1)
E("Arch rocks", "superman", 3, mesure="repetitions")
E("Archer rows anneaux", "rowing_anneaux", 7, uni=True)
E("Around the world (suspendu)", "windshield", 8)
E("Assault bike", "ergo_velo", 2, nc="Matériel v1 « poids de corps » : ergomètre nécessaire.", doublon="Echo bike (calories)")
E("Assault bike — sprints", "ergo_velo", 5, mods=["sprint"], base="Assault bike")
E("ATR (équilibre)", "atr", 7)
E("ATR dos au mur (tenue)", "atr_dos_mur", 4)
E("ATR poitrine au mur (tenue)", "atr_poitrine_mur", 5)
E("Australian pull-ups (rows barre basse)", "rowing_australien", 2)
E("Back lever advanced tuck", "back_lever", 7, pose="levier.back_adv")
E("Back lever complet", "back_lever", 9, pose="levier.back_full")
E("Back lever straddle", "back_lever", 8, pose="levier.back_straddle")
E("Back lever tuck", "back_lever", 6, pose="levier.back_tuck")
E("Back squat", "squat_barre", 4)
E("Bar dips (dips à la barre fixe)", "dips_barre_fixe", 5)
E("Bar dips lestés", "dips_barre_fixe", 6, mods=["leste"], base="Bar dips (dips à la barre fixe)")
E("Battle ropes", "battle_rope", 3)
E("Bear crawl", "crawl", 3)
E("Bicycle crunchs", "crunch", 2, type="gainage_anti_rotation", prim="droit_abdomen obliques", sec="ilio_psoas droit_femoral transverse_abdomen")
E("Bilan", "respiration", 1, role="hors_generateur", type="hors_categorie",
  nc="Entrée de suivi (report de résultats), pas un exercice.")
E("Bird dog", "bird_dog", 1)
E("Body saw (sliders)", "body_saw", 4)
E("Box jumps", "box_jump", 4)
E("Box jumps step-down", "box_jump", 3, alias=["box jump redescente en marchant"])
E("Box squat", "box_squat", 4)
E("Box step-overs", "step_up", 3, type="conditionnement", eq=["box"])
E("Bridge (pont dorsal)", "pont_dorsal", 5)
E("Broad jumps (sauts en longueur)", "saut", 4, pose="saut.longueur")
E("Burpees", "burpee", 4)
E("Burpees box jump-over", "burpee", 6, eq=["box"])
E("Burpees broad jump", "burpee", 5)
E("Burpees lestés (gilet)", "burpee", 6, mods=["leste"], base="Burpees")
E("Burpees over the bar", "burpee", 5, eq=["barre"])
E("Burpees pull-up", "burpee", 6, eq=["barre_fixe"])
E("Butterfly pull-ups", "traction_kipping", 8)
E("Chest-to-bar kipping", "traction_kipping", 7)
E("Chin-up lesté", "traction", 7, mods=["leste"], base="Traction supination")
E("Ciseaux (scissors)", "flutter", 2)
E("Clamshell élastique", "clamshell", 1)
E("Clean & jerk", "clean", 9, pose="olympique.clean_press")
E("Contraste français", "respiration", 5, role="hors_generateur", type="hors_categorie",
  nc="Méthode d'entraînement (enchaînement lourd puis explosif), pas un exercice ; le programme l'associe au squat et au muscle-up.")
E("Copenhagen plank", "copenhague", 5)
E("Corde à sauter", "corde_a_sauter", 2, nc="Matériel v1 « poids de corps » : corde nécessaire.", eq=["corde_a_sauter"])
E("Course à pied (footing)", "course", 3)
E("Course — fartlek", "course", 4, mods=["intervalles"], base="Course à pied (footing)")
E("Course — fractionné 200 m", "sprint", 6, base="Course à pied (footing)")
E("Course — fractionné 400 m", "sprint", 6, base="Course à pied (footing)")
E("Crab walk", "crab_walk", 3)
E("Crunchs inversés", "relevé_jambes", 2, pose="dos_au_sol.leg_raise")
E("Crunchs lestés", "crunch", 3, mods=["leste"], base="Crunchs inversés", eq=["disques"])
E("Crunchs poulie haute", "crunch_poulie", 3)
E("Cuban press", "cuban_press", 3)
E("Curl araignée", "curl", 3, eq=["halteres", "banc"])
E("Curl barre EZ", "curl_barre", 2)
E("Curl concentration", "curl", 2, uni=True)
E("Curl élastique", "curl", 1, charge="elastique", eq=["elastique"])
E("Curl haltères", "curl", 2)
E("Curl incliné", "curl", 3, eq=["halteres", "banc"])
E("Curl marteau", "curl_marteau", 2)
E("Curl marteau (par haltère)", "curl_marteau", 2, doublon="Curl marteau")
E("Curl poignet", "poignet_flexion", 1, prim="flechisseurs_du_poignet", sec="flechisseurs_superficiels_des_doigts flechisseurs_profonds_des_doigts")
E("Curl poulie basse", "curl_poulie", 2, pose="curl.poulie")
E("Curl pronation (reverse curl)", "curl_barre", 3, prim="brachio_radial brachial extenseurs_du_poignet", sec="biceps flechisseurs_du_poignet")
E("Curl pupitre (Larry Scott)", "curl_pupitre", 3)
E("Curl Zottman", "curl", 3, prim="biceps brachial brachio_radial", sec="extenseurs_du_poignet flechisseurs_du_poignet")
# ------------------------------------------------------------------ D
E("Dead bug", "dead_bug", 1)
E("Dead-hang", "dead_hang", 1)
E("Dead-hang lesté ou PdC", "dead_hang", 3, mods=["leste_optionnel"], base="Dead-hang",
  nc="Nom ambigu (« lesté ou PdC ») : deux modes de charge dans une seule entrée.")
E("Dead-hang serviette", "dead_hang", 4, eq=["barre_fixe", "serviette"])
E("Dead-hang une main", "dead_hang", 6, uni=True)
E("Développé Arnold", "developpe_halteres", 4)
E("Développé couché", "developpe_couche", 3)
E("Développé couché haltères", "developpe_couche_halteres", 3)
E("Développé couché pause", "developpe_couche", 4, mods=["pause"], base="Développé couché", pose="banc.pause")
E("Développé couché prise serrée", "developpe_couche", 4, prim="triceps grand_pectoral_sterno_costal", sec="deltoide_anterieur grand_pectoral_claviculaire")
E("Développé décliné", "developpe_couche", 4)
E("Développé haltères assis", "developpe_assis", 3)
E("Développé incliné", "developpe_incline", 3)
E("Développé incliné haltères", "developpe_incline", 3, charge="halteres", eq=["halteres", "banc"])
E("Développé kettlebell (par bras)", "developpe_halteres", 4, charge="kettlebell", eq=["kettlebell"], uni=True)
E("Développé militaire assis", "developpe_assis", 4, charge="barre", eq=["barre", "banc", "rack"])
E("Développé militaire debout", "developpe_militaire", 4)
E("Développé militaire haltères debout", "developpe_halteres", 3)
E("Devil press", "devil_press", 6)
E("Dip", "dips_barres", 5, doublon="Dips")
E("Dip Lesté", "dips_barres", 6, mods=["leste"], base="Dips", doublon="Dips lestés")
E("Dips", "dips_barres", 5)
E("Dips à résistance accommodante (élastique depuis le sol)", "dips_barres", 7, mods=["elastique_resistance"], base="Dips",
  eq=["barres_paralleles", "elastique"])
E("Dips assistés élastique", "dips_barres", 3, mods=["assiste"], base="Dips", eq=["barres_paralleles", "elastique"],
  nc="Matériel v1 « élastique » seul : les barres parallèles sont aussi nécessaires.")
E("Dips aux anneaux", "dips_anneaux", 7, nc="Groupe v1 « dos, pectoraux » : le dos n'est pas moteur.")
E("Dips aux anneaux lestés", "dips_anneaux", 8, mods=["leste"], base="Dips aux anneaux")
E("Dips aux anneaux RTO (tournés)", "dips_anneaux", 8)
E("Dips bulgares (prise large)", "dips_barres", 6, prim="pectoraux_bas triceps", precautions_plus=["epaule_anterieure"])
E("Dips coréens", "dips_barre_fixe", 8, pose="dips.barre_fixe", precautions_plus=["epaule_anterieure"])
E("Dips excentriques lestés", "dips_barres", 6, mods=["leste", "negatif"], base="Dips lestés")
E("Dips explosifs", "dips_barres", 6, mods=["explosif"], base="Dips")
E("Dips isométriques mi-course", "iso_dips", 4, base="Dips")
E("Dips lestés", "dips_barres", 6, mods=["leste"], base="Dips")
E("Dips lestés cluster", "dips_barres", 6, mods=["leste", "clusters"], base="Dips lestés")
E("Dips lestés pause", "dips_barres", 6, mods=["leste", "pause"], base="Dips lestés")
E("Dips lestés tempo", "dips_barres", 6, mods=["leste", "tempo"], base="Dips lestés")
E("Dips lestés — singles lourds", "dips_barres", 7, mods=["leste", "singles_lourds"], base="Dips lestés")
E("Dips négatifs", "dips_barres", 3, mods=["negatif"], base="Dips")
E("Dips pause basse", "dips_barres", 5, mods=["pause"], base="Dips")
E("Dips PdC", "dips_barres", 5, doublon="Dips")
E("Dips sur banc (triceps)", "dips_banc", 3)
E("Dips tempo (3 s excentrique)", "dips_barres", 5, mods=["tempo"], base="Dips")
E("Dislocations épaules bâton", "dislocations", 1)
E("Dislocations épaules élastique", "dislocations", 1, eq=["elastique"])
E("Double-unders", "corde_a_sauter", 5)
E("Dragon flag (progression)", "dragon_flag", 7)
E("Dragon flag complet", "dragon_flag", 9)
E("Dragon flag négatif", "dragon_flag", 7, mods=["negatif"], base="Dragon flag complet")
# ------------------------------------------------------------------ E – F
E("Écarté haltères", "ecarte", 3)
E("Écarté poulie vis-à-vis", "ecarte_poulie", 2)
E("Echo bike (calories)", "ergo_velo", 3)
E("Élévations en ATR (tenue)", "atr_poitrine_mur", 6, nc="Intitulé imprécis : interprété comme montées en ATR contre le mur avec tenue.")
E("Élévations frontales", "elevation_frontale", 2)
E("Élévations latérales", "elevation_laterale", 2)
E("Élévations latérales (par haltère)", "elevation_laterale", 2, doublon="Élévations latérales")
E("Élévations latérales élastique", "elevation_laterale", 1, charge="elastique", eq=["elastique"])
E("Élévations latérales poulie", "elevation_laterale", 2, charge="poulie", eq=["poulie"], uni=True)
E("Enrouleur de poignet (wrist roller)", "wrist_roller", 3)
E("Étirements chaîne postérieure", "etirement_posterieur", 1)
E("Étirements fléchisseurs de hanche", "etirement_flechisseurs", 1)
E("Excentrique de transition muscle-up", "muscle_up_negatif", 6, base="Muscle-up")
E("Excentriques de transition LESTÉS", "muscle_up_negatif", 7, mods=["leste"], base="Excentrique de transition muscle-up")
E("Extension corde", "extension_triceps_poulie", 2, doublon="Extension triceps poulie corde")
E("Extension poignet", "poignet_flexion", 1, prim="extenseurs_du_poignet", sec="extenseurs_des_doigts")
E("Extension poignet barre", "poignet_flexion", 1, charge="barre", eq=["barre"], prim="extenseurs_du_poignet", sec="extenseurs_des_doigts")
E("Extension triceps couché (barre EZ)", "barre_front", 3, doublon="Barre au front EZ")
E("Extension triceps haltère à deux mains", "extension_triceps_nuque", 3)
E("Extension triceps nuque", "extension_triceps_nuque", 3)
E("Extension triceps poulie", "extension_triceps_poulie", 2)
E("Extension triceps poulie corde", "extension_triceps_poulie", 2)
E("Extension triceps unilatérale poulie", "extension_triceps_poulie", 2, uni=True)
E("Extensions de doigts élastique", "extension_doigts", 1)
E("Face pulls", "face_pull", 2)
E("Face pulls aux anneaux", "rowing_anneaux", 3, prim="deltoide_posterieur", sec="rhomboides trapeze_moyen_inferieur infra_epineux petit_rond", pose="cable.face_pull")
E("Face pulls élastique", "face_pull", 1, charge="elastique", eq=["elastique"])
E("False grip hang", "false_grip", 5, eq=["barre_fixe"])
E("False grip hold (anneaux ou barre)", "false_grip", 5, eq=["anneaux"], alias=["false grip hold barre"])
E("Farmer hold (tenue)", "farmer_hold", 2)
E("Farmer walk", "farmer", 2)
E("Farmer walk kettlebells", "farmer", 2, charge="kettlebell", eq=["kettlebell"])
E("Farmer walk lourd (trap bar)", "farmer", 4, charge="barre", eq=["barre"])
E("Fentes arrière", "fente", 2)
E("Fentes avant", "fente", 3)
E("Fentes bulgares", "fente_bulgare", 5)
E("Fentes déficit", "fente", 4, eq=["support_stable"], pose="fente.deficit")
E("Fentes latérales", "fente_laterale", 3)
E("Fentes marchées", "fente", 3, type="fente")
E("Fentes marchées (par haltère)", "fente", 4, charge="halteres", eq=["halteres"], doublon="Fentes marchées haltères",
  nc="Matériel v1 « poids de corps » alors que l'exercice est chargé en haltères.")
E("Fentes marchées haltères", "fente", 4, charge="halteres", eq=["halteres"])
E("Fentes marchées lestées (sac)", "fente", 4, charge="objet_leste", eq=["sac_leste"])
E("Fentes sautées", "fente_sautee", 5)
E("Floor press", "floor_press", 3)
E("Flutter kicks", "flutter", 2)
E("Foam roller (auto-massage)", "foam", 1)
E("Front lever advanced tuck", "front_lever", 7, pose="levier.front_adv")
E("Front lever complet", "front_lever", 10, pose="levier.front_full")
E("Front lever hold à l'élastique", "front_lever", 6, mods=["assiste"], base="Front lever complet", eq=["barre_fixe", "elastique"],
  pose="levier.front_straddle")
E("Front lever négatif", "front_lever_dyn", 8, mods=["negatif"], base="Front lever complet", pose="levier.front_straddle.dynamique")
E("Front lever one leg", "front_lever", 8, pose="levier.front_one")
E("Front lever pull-ups (tuck)", "front_lever_dyn", 8, pose="levier.front_tuck.dynamique")
E("Front lever raises", "front_lever_dyn", 7, pose="levier.front_adv.dynamique")
E("Front lever straddle", "front_lever", 9, pose="levier.front_straddle")
E("Front lever tuck", "front_lever", 6, pose="levier.front_tuck")
E("Front squat", "front_squat", 5)
# ------------------------------------------------------------------ G – K
E("German hang (tenue)", "german_hang", 6, eq=["barre_fixe"])
E("Good mornings", "good_morning", 5, nc="Groupe v1 « quadriceps, fessiers » : les moteurs sont les ischio-jambiers et les érecteurs.")
E("Hack squat", "hack_squat", 3)
E("Half burpees", "burpee", 3, alias=["burpee sans saut ni pompe"])
E("Hand gripper", "prehension", 1, nc="Matériel v1 « poids de corps » : pince de préhension nécessaire.")
E("Handstand push-ups (mur)", "hspu", 7)
E("Handstand walk (marche en ATR)", "handstand_walk", 8)
E("Hang clean", "clean", 6)
E("High knees (montées de genoux)", "genoux_hauts", 2)
E("HIIT course 30/30", "sprint", 5, mesure="temps", base="Course à pied (footing)")
E("HIIT court", "burpee", 4, role="hors_generateur", type="conditionnement",
  nc="Format de séance générique sans exercice défini ; représenté par une pose de burpee.")
E("Hip thrust", "hip_thrust", 3)
E("Hip thrust unilatéral", "hip_thrust", 4, uni=True, charge="poids_de_corps", eq=["banc"])
E("Hollow body hold", "hollow", 3)
E("Hollow hold lesté", "hollow", 5, mods=["leste"], base="Hollow body hold", eq=["disques"])
E("Hollow rocks", "hollow_rocks", 4)
E("HSPU freestanding (progression)", "hspu", 9, eq=["aucun"], precautions_plus=["equilibre", "chute_arriere"], pose="atr.hspu_libre")
E("HSPU kipping", "hspu", 7, precautions_plus=["technique_prioritaire"])
E("HSPU stricts en déficit", "hspu", 8, eq=["mur", "poignees"], pose="atr.hspu_deficit")
E("Human flag (drapeau)", "drapeau", 9, pose="drapeau.full", nc="Matériel v1 « poids de corps » : un poteau vertical ou un espalier est nécessaire.")
E("Human flag tuck", "drapeau", 7, pose="drapeau.tuck")
E("Hyperextensions (banc 45°)", "hyperextension", 2)
E("Ice cream makers", "front_lever_dyn", 8, pose="levier.front_tuck.dynamique")
E("Inchworms", "inchworm", 2)
E("Isométrie bas de dip", "iso_dips", 5)
E("Isométrie maximale", "iso_dips", 6, doublon="Isométrie bas de dip",
  nc="Intitulé générique : le programme l'emploie pour deux positions (bas de dip, transition de muscle-up), séparées en v2.")
E("Jefferson curl", "jefferson", 6)
E("JM press", "barre_front", 5, pose="banc.couche")
E("Jumping jacks", "jumping_jacks", 1)
E("Kettlebell clean", "clean_press", 4, pose="olympique.clean")
E("Kettlebell clean & press", "clean_press", 5)
E("Kettlebell snatch", "kb_snatch", 7)
E("Kettlebell swing", "swing", 4)
E("Kettlebell swing une main", "swing", 5, uni=True)
E("Kettlebell windmill", "windmill", 6)
E("Kick-back fessiers poulie", "kick_back_poulie", 2)
E("Kickback triceps", "kickback", 2)
E("Kipping pull-ups", "traction_kipping", 6)
E("Knee raises suspendu", "suspension_genoux", 3)
E("Knees to elbows", "toes_to_bar", 5, pose="suspension.knee_raise.barre_fixe")
# ------------------------------------------------------------------ L
E("L-sit", "lsit", 5)
E("L-sit à la barre fixe (tenue)", "lsit", 5, pose="suspension.l_sit_barre.barre_fixe", eq=["barre_fixe"], contrainte="21100000")
E("L-sit au sol (tenue)", "lsit", 6, pose="lsit.sol", eq=["aucun"])
E("L-sit tuck (tenue)", "lsit_tuck", 3)
E("Landmine press", "landmine_press", 3, uni=True)
E("Landmine rotations", "landmine_rotation", 5)
E("Leg curl", "leg_curl_machine", 2)
E("Leg curl sliders", "leg_curl_sol", 4)
E("Leg curl swiss ball", "leg_curl_sol", 3, eq=["swiss_ball"])
E("Leg extension", "leg_extension", 1)
E("Leg raises lestés", "relevé_jambes", 5, mods=["leste"], base="Relevés de jambes au sol", eq=["halteres"])
E("Leg raises lestés (suspendu)", "suspension_jambes", 7, mods=["leste"], base="Leg raises suspendu")
E("Leg raises suspendu", "suspension_jambes", 5, nc="Matériel v1 « poids de corps » : barre fixe nécessaire.")
# ------------------------------------------------------------------ M
E("Man makers", "man_maker", 7)
E("Manna progression", "manna", 10)
E("Marche de récupération", "marche", 1)
E("Marche latérale élastique (monster walk)", "monster_walk", 1)
E("Marche lestée (ruck)", "marche_lestee", 3)
E("Marche ou vélo très léger", "marche", 1, role="hors_generateur",
  nc="Deux activités dans une seule entrée ; consigne de récupération plus qu'exercice.")
E("Marche rapide", "marche", 2, type="locomotion")
E("Mobilité complète", "mobilite_complete", 1, nc="Routine générique sans contenu défini.")
E("Mobilité épaules + poignets", "mobilite_poignets", 1, eq=["aucun"],
  nc="Matériel v1 « haltères » pour une routine de mobilité sans charge.")
E("Mobilité hanches (90/90)", "mobilite_hanches", 1)
E("Mobilité thoracique (cat-cow, rotations)", "mobilite_thoracique", 1)
E("Mollets assis", "mollets_assis", 1)
E("Mollets debout", "mollets", 2, charge="machine", eq=["machine"])
E("Mollets debout barre", "mollets", 2, charge="barre", eq=["barre", "rack"])
E("Mollets sur presse", "mollets", 2, charge="machine", eq=["machine"], pose="assis.calf_seated")
E("Mollets unilatéraux sur marche", "mollets_unijambe", 2)
E("Mountain climbers", "mountain_climbers", 3)
E("Muscle-up", "muscle_up", 8)
E("Muscle-up aux anneaux", "muscle_up_anneaux", 8)
E("Muscle-up aux anneaux strict", "muscle_up_anneaux", 9)
E("Muscle-up kipping", "muscle_up", 7)
E("Muscle-up lesté", "muscle_up", 9, mods=["leste"], base="Muscle-up strict")
E("Muscle-up lesté cluster", "muscle_up", 9, mods=["leste", "clusters"], base="Muscle-up lesté")
E("Muscle-up lesté — singles", "muscle_up", 10, mods=["leste", "singles_lourds"], base="Muscle-up lesté")
E("Muscle-up négatif lesté", "muscle_up_negatif", 8, mods=["leste"], base="Négatifs de muscle-up")
E("Muscle-up strict", "muscle_up", 9)
# ------------------------------------------------------------------ N – O
E("Négatif de muscle-up", "muscle_up_negatif", 6, doublon="Négatifs de muscle-up")
E("Négatifs de muscle-up", "muscle_up_negatif", 6)
E("Négatifs de muscle-up complets", "muscle_up_negatif", 6, doublon="Négatifs de muscle-up")
E("Nordic curl (excentrique)", "nordic", 7, nc="Groupe v1 « quadriceps, fessiers » : le moteur est l'ischio-jambier.")
E("Nordic curl assisté élastique", "nordic", 5, mods=["assiste"], base="Nordic curl (excentrique)", eq=["support_stable", "elastique"])
E("Oiseau (élévations buste penché)", "oiseau", 2)
E("Oiseau à la poulie", "oiseau", 2, charge="poulie", eq=["poulie"])
E("Overhead carry", "overhead_carry", 4)
# ------------------------------------------------------------------ P
E("Pallof press", "pallof", 2, charge="poulie", eq=["poulie"])
E("Pallof press élastique", "pallof", 2)
E("Pec deck", "pec_deck", 2)
E("Pike push-ups", "pompe_pike", 4)
E("Pike push-ups surélevés (pieds sur banc)", "pompe_pike", 5, eq=["support_stable"])
E("Pinch grip disques (tenue)", "pinch", 3)
E("Pistol squat", "pistol", 8)
E("Pistol squat assisté", "pistol_assiste", 5)
E("Pistol squat lesté", "pistol", 9, mods=["leste"], base="Pistol squat", eq=["kettlebell"])
E("Planche (gainage)", "planche_coudes", 2, nc="Intitulé ambigu avec la figure « planche » du street workout ; renommé en v2.",
  nom="Planche de gainage sur les coudes")
E("Planche advanced tuck", "planche_skill", 8, pose="planche_skill.adv")
E("Planche avec sortie (walkout)", "inchworm", 3)
E("Planche bras tendus + taps", "planche_bras_tendus", 3, type="gainage_anti_rotation", mesure="repetitions")
E("Planche latérale", "planche_laterale", 2)
E("Planche latérale lestée", "planche_laterale", 4, mods=["leste"], base="Planche latérale", eq=["disques"])
E("Planche lean", "planche_lean", 4)
E("Planche lean à l'élastique", "planche_lean", 3, mods=["assiste"], base="Planche lean", eq=["elastique", "barre_fixe"])
E("Planche lestée (gainage)", "planche_coudes", 4, mods=["leste"], base="Planche (gainage)", eq=["lest"])
E("Planche RKC (coudes)", "planche_rkc", 4)
E("Planche straddle", "planche_skill", 9, pose="planche_skill.straddle")
E("Plate pinch carry", "pinch", 3, mesure="distance")
E("Pompes", "pompe", 3)
E("Pompes à genoux", "pompe_genoux", 2)
E("Pompes archer", "pompe_archer", 6)
E("Pompes aux anneaux", "pompe", 5, eq=["anneaux"], nc="Groupe v1 « dos, pectoraux » : le dos n'est pas moteur.")
E("Pompes aux anneaux RTO", "pompe", 6, eq=["anneaux"])
E("Pompes déclinées", "pompe_declinee", 4)
E("Pompes déficit (poignées)", "pompe", 4, eq=["poignees"])
E("Pompes diamant", "pompe_diamant", 5)
E("Pompes diamant surélevées", "pompe_diamant", 6, eq=["support_stable"])
E("Pompes explosives (clap)", "pompe_explosive", 6)
E("Pompes hindu", "pompe", 4, pose="pompe.pike", prim="pectoraux deltoide_anterieur triceps", sec="dentele_anterieur erecteurs_lombaires")
E("Pompes inclinées (mains surélevées)", "pompe_inclinee", 2)
E("Pompes lestées", "pompe", 5, mods=["leste"], base="Pompes", nc="Matériel v1 « poids de corps » : lest nécessaire.")
E("Pompes lestées (lest ajouté)", "pompe", 5, mods=["leste"], base="Pompes", doublon="Pompes lestées")
E("Pompes pause au sol", "pompe", 3, mods=["pause"], base="Pompes")
E("Pompes PdC", "pompe", 3, doublon="Pompes")
E("Pompes pliométriques (mains sur boxes)", "pompe_explosive", 7, eq=["box"])
E("Pompes prise large", "pompe", 3)
E("Pompes prise serrée", "pompe_diamant", 4)
E("Pompes pseudo-planche", "pompe_pseudo", 6)
E("Pompes spiderman", "pompe", 4, prim="pectoraux triceps", sec="deltoide_anterieur obliques ilio_psoas dentele_anterieur")
E("Pompes sur les poings", "pompe", 3, contrainte="21110000", alias=["pompes poings fermés (poignet neutre)"])
E("Pompes surélevées (pieds sur banc)", "pompe_declinee", 4, doublon="Pompes déclinées")
E("Pompes tempo", "pompe", 3, mods=["tempo"], base="Pompes")
E("Pompes typewriter", "pompe_archer", 7)
E("Pompes une main (progression)", "pompe_un_bras", 7, nc="Intitulé « progression » sans étape précise ; interprété comme pompe à un bras mains surélevées.",
  eq=["support_stable"], pose="pompe.inclinee")
E("Pont fessier au sol", "pont_fessier", 1)
E("Pont fessier une jambe", "pont_fessier", 3, uni=True, pose="pont.unijambe")
E("Power clean", "clean", 7)
E("Presse à cuisses", "presse", 2)
E("Pronation / supination haltère", "poignet_rotation", 1)
E("Prone Y raises", "ytw", 2)
E("Pseudo-planche hold", "pseudo_planche_hold", 5)
E("Pull-apart élastique", "pull_apart", 1)
E("Pull-over poulie", "pullover", 2)
E("Push jerk", "push_press", 7, precautions_plus=["technique_prioritaire"])
E("Push press", "push_press", 5)
E("Push press haltères", "push_press", 5, charge="halteres", eq=["halteres"])
# ------------------------------------------------------------------ R
E("Rack pulls", "sdt", 4, prim="erecteurs_lombaires grand_fessier trapezes", sec="ischios grand_dorsal rhomboides prehension", eq=["barre", "rack"])
E("Rameur", "ergo_rameur", 2, nc="Matériel v1 « poids de corps » : ergomètre nécessaire.")
E("Rameur — intervalles 500 m", "ergo_rameur", 5, mods=["intervalles"], base="Rameur", mesure="distance")
E("Relevés de jambes au sol", "relevé_jambes", 3)
E("Repos actif", "marche", 1, role="hors_generateur", type="hors_categorie", nc="Consigne de repos, pas un exercice.")
E("Respiration / cohérence cardiaque", "respiration", 1, role="hors_generateur")
E("Reverse hyper", "hyperextension", 3, prim="grand_fessier ischios", sec="erecteurs_lombaires multifides grand_adducteur", eq=["machine"])
E("Rice bucket (seau de riz)", "rice_bucket", 1, eq=["aucun"], nc="Matériel v1 « poids de corps » : un seau de riz est nécessaire.")
E("Rollout barre", "ab_wheel", 7, eq=["barre"])
E("Rotations externes (par haltère)", "rotation_externe", 1, charge="halteres", eq=["halteres"], pose="cable.rotation_ext")
E("Rotations externes élastique", "rotation_externe", 1)
E("Rotations internes élastique", "rotation_externe", 1, prim="sous_scapulaire", sec="grand_pectoral_sterno_costal grand_dorsal grand_rond deltoide_anterieur")
E("Rowing barre penché", "rowing_barre", 4)
E("Rowing haltère appui poitrine", "rowing_appui", 2)
E("Rowing haltère unilatéral (par haltère)", "rowing_halteres", 3, uni=True, doublon="Rowing unilatéral haltère",
  nc="Matériel v1 « barre » pour un rowing à un haltère.")
E("Rowing haltères penché", "rowing_halteres", 3)
E("Rowing kettlebell", "rowing_halteres", 3, charge="kettlebell", eq=["kettlebell"], uni=True)
E("Rowing Meadows", "rowing_barre", 5, uni=True)
E("Rowing Pendlay", "rowing_barre", 5)
E("Rowing T-bar", "rowing_barre", 4)
E("Rowing unilatéral haltère", "rowing_halteres", 3, uni=True)
E("Rows archer barre basse", "rowing_australien", 6, uni=True, pose="rowing.archer")
E("Rows aux anneaux", "rowing_anneaux", 3)
E("Rows aux sangles (TRX)", "rowing_anneaux", 3, eq=["sangles"])
E("Rows barre basse pieds surélevés", "rowing_australien", 4, eq=["barre_basse", "support_stable"], pose="rowing.australien_pieds_hauts")
E("Rows une main anneaux", "rowing_anneaux", 6, uni=True)
E("Russian dips", "dips_barres", 7, precautions_plus=["epaule_anterieure"])
E("Russian twists", "russian_twist", 2)
E("Russian twists lestés", "russian_twist", 3, mods=["leste"], base="Russian twists", eq=["medecine_ball"], charge="objet_leste")
# ------------------------------------------------------------------ S
E("Sandbag carry", "sandbag_carry", 3)
E("Sandbag clean", "clean", 5, charge="objet_leste", eq=["sac_leste"])
E("Sandbag squat (bear hug)", "squat_gobelet", 4, charge="objet_leste", eq=["sac_leste"])
E("Sauts à la corde unipodaux", "corde_a_sauter", 4, uni=True)
E("Sauts de mollets (pogo)", "pogo", 3)
E("Sauts en contrebas (depth jumps)", "depth_jump", 7)
E("Scapular pull-ups", "scap_pull", 2)
E("Scapular pull-ups lestés", "scap_pull", 4, mods=["leste"], base="Scapular pull-ups")
E("Scapular push-ups", "scapular_pushup", 1)
E("Serratus push-ups (protraction)", "scapular_pushup", 1, doublon="Scapular push-ups")
E("Shoulder taps en ATR", "atr_taps", 6)
E("Shrimp squat", "shrimp_squat", 7)
E("Shrugs barre", "shrug", 2)
E("Shrugs haltères", "shrug", 2, charge="halteres", eq=["halteres"])
E("Shuttle runs (navettes)", "sprint", 5)
E("Side bend haltère", "side_bend", 2)
E("Sissy squat", "sissy_squat", 6)
E("Sissy squat assisté", "sissy_squat", 4, mods=["assiste"], base="Sissy squat")
E("Sit-ups", "situp", 2)
E("Sit-ups butterfly", "situp", 2)
E("Sit-ups GHD", "situp", 6, eq=["ghd"], precautions_plus=["lombaire"])
E("Skater squat", "skater_squat", 6)
E("Skaters", "skaters", 3)
E("SkiErg", "ergo_ski", 2)
E("Skin the cat", "skin_the_cat", 6)
E("Slam ball", "slam", 3)
E("Sled drag arrière", "sled_pull", 4, prim="quadriceps", sec="grand_fessier mollets tibial_anterieur", stab="transverse_abdomen erecteurs_lombaires prehension")
E("Sled pull (traîneau, corde)", "sled_pull", 4)
E("Sled push", "sled_push", 4)
E("Snatch (arraché)", "snatch", 9)
E("Soulevé de terre", "sdt", 5)
E("Soulevé de terre jambes tendues", "sdt_roumain", 5)
E("Soulevé de terre kettlebell", "sdt", 2, charge="kettlebell", eq=["kettlebell"])
E("Soulevé de terre roumain", "sdt_roumain", 4)
E("Soulevé de terre sumo", "sdt", 5, prim="grand_fessier quadriceps adducteurs", sec="ischios erecteurs_lombaires trapezes prehension")
E("Soulevé de terre trap bar", "sdt", 4, prim="quadriceps grand_fessier ischios", sec="erecteurs_lombaires trapezes prehension grand_adducteur")
E("Soulevé de terre unilatéral haltère", "sdt_unijambe", 5)
E("Sprint", "sprint", 6)
E("Sprint en côte", "sprint", 6)
E("Squat 1 ¼", "squat_barre", 5, mods=["tempo"], base="Back squat")
E("Squat au poids de corps", "squat_pdc", 2)
E("Squat bulgare haltères", "fente_bulgare", 5, charge="halteres", eq=["halteres", "support_stable"], doublon="Fentes bulgares")
E("Squat bulgare lesté (gilet)", "fente_bulgare", 6, mods=["leste"], base="Fentes bulgares")
E("Squat cosaque", "squat_cosaque", 4)
E("Squat endurance @ 70 kg", "squat_barre", 5, mods=["series_longues"], base="Back squat",
  nc="Charge absolue (70 kg) inscrite dans le nom : spécifique au propriétaire.")
E("Squat gobelet", "squat_gobelet", 2)
E("Squat overhead", "squat_overhead", 7)
E("Squat pause", "squat_barre", 5, mods=["pause"], base="Back squat")
E("Squat sauté", "squat_saute", 4)
E("Squat sauté lesté", "squat_saute", 6, mods=["leste"], base="Squat sauté")
E("Squat sumo haltère", "squat_gobelet", 2, charge="halteres", eq=["halteres"])
E("Squat tempo", "squat_barre", 5, mods=["tempo"], base="Back squat")
E("Squat Zercher", "squat_barre", 6, pose="squat.zercher", precautions_plus=["coude"])
E("Squat — walkout lourd", "squat_barre", 6, mods=["singles_lourds"], base="Back squat", mesure="temps",
  alias=["walkout (sortie de rack) lourd"])
E("Step-ups", "step_up", 2)
E("Step-ups hauts (box)", "step_up", 4, eq=["box"], pose="step.haut")
E("Step-ups lestés", "step_up", 3, charge="halteres", eq=["halteres", "support_stable"])
E("Straight-arm pulldown", "straight_arm_pulldown", 2)
E("Suitcase carry", "suitcase_carry", 2)
E("Superman dynamique", "superman", 1, mesure="repetitions")
E("Superman hold", "superman", 1)
E("Support hold anneaux/barres", "support_hold", 3, alias=["support hold aux anneaux"], nc="Deux supports dans une même entrée.")
E("Support hold lesté", "support_hold", 4, mods=["leste"], base="Support hold anneaux/barres")
E("Suspension active (active hang)", "active_hang", 2)
# ------------------------------------------------------------------ T
E("Tapis incliné (marche)", "marche", 2, eq=["ergometre"])
E("Tate press", "barre_front", 3, charge="halteres", eq=["halteres", "banc"])
E("Test 1Rm Back Squat", "squat_barre", 6, role="test", mods=["test_1rm"], base="Back squat", precautions_plus=["effort_maximal"])
E("Test 1RM Développé couché", "developpe_couche", 5, role="test", mods=["test_1rm"], base="Développé couché", precautions_plus=["effort_maximal"])
E("Test 1Rm Dip Lesté", "dips_barres", 7, role="test", mods=["leste", "test_1rm"], base="Dips lestés", precautions_plus=["effort_maximal"])
E("Test 1RM Front squat", "front_squat", 6, role="test", mods=["test_1rm"], base="Front squat", precautions_plus=["effort_maximal"])
E("Test 1Rm Muscle-Up Lesté", "muscle_up", 10, role="test", mods=["leste", "test_1rm"], base="Muscle-up lesté", precautions_plus=["effort_maximal"])
E("Test 1RM Soulevé de terre", "sdt", 6, role="test", mods=["test_1rm"], base="Soulevé de terre", precautions_plus=["effort_maximal"])
E("Test 1Rm Traction Lestée", "traction", 8, role="test", mods=["leste", "test_1rm"], base="Traction lestée", precautions_plus=["effort_maximal"])
E("Test 2 km rameur", "ergo_rameur", 5, role="test", mesure="distance", base="Rameur", precautions_plus=["cardio_intense"])
E("Test 5 km course", "course", 5, role="test", mesure="distance", base="Course à pied (footing)", precautions_plus=["cardio_intense"])
E("Test Cooper 12 min", "course", 5, role="test", base="Course à pied (footing)", precautions_plus=["cardio_intense"])
E("Test max burpees 3 min", "burpee", 6, role="test", base="Burpees", precautions_plus=["cardio_intense"])
E("Test max dead-hang", "dead_hang", 3, role="test", base="Dead-hang")
E("TEST MAX DIPS PdC", "dips_barres", 6, role="test", mods=["test_max_reps"], base="Dips")
E("Test max handstand hold", "atr", 7, role="test", base="ATR (équilibre)")
E("Test max L-sit", "lsit", 5, role="test", base="L-sit")
E("TEST MAX MUSCLE-UPS PdC", "muscle_up", 9, role="test", mods=["test_max_reps"], base="Muscle-up strict")
E("TEST MAX POMPES PdC", "pompe", 4, role="test", mods=["test_max_reps"], base="Pompes")
E("TEST MAX SQUAT @ 70 kg", "squat_barre", 6, role="test", mods=["test_max_reps"], base="Back squat",
  nc="Charge absolue (70 kg) inscrite dans le nom : spécifique au propriétaire.")
E("TEST MAX TRACTIONS PdC", "traction", 6, role="test", mods=["test_max_reps"], base="Traction pronation")
E("Thruster", "thruster", 6)
E("Thruster haltères", "thruster", 5, charge="halteres", eq=["halteres"])
E("Tibialis raises", "tibial", 1)
E("Tirage bûcheron à la barre fixe", "traction_archer", 8, alias=["tirage latéral alterné à la barre (bûcheron)"])
E("Tirage horizontal poulie", "tirage_horizontal_poulie", 2)
E("Tirage horizontal unilatéral poulie", "tirage_horizontal_poulie", 2, uni=True)
E("Tirage menton barre", "tirage_menton", 3)
E("Tirage menton haltères", "tirage_menton", 3, charge="halteres", eq=["halteres"], nc="Groupe v1 « dos » : moteurs deltoïdes et trapèzes.")
E("Tirage vertical prise neutre", "tirage_vertical_poulie", 2)
E("Tirage vertical pronation", "tirage_vertical_poulie", 2)
E("Tirage vertical supination", "tirage_vertical_poulie", 2)
E("Tirage vertical unilatéral", "tirage_vertical_poulie", 3, uni=True)
E("Toes to bar", "toes_to_bar", 6)
E("Toes to bar kipping", "toes_to_bar", 6, precautions_plus=["technique_prioritaire"])
E("Toes to bar strict", "toes_to_bar", 7)
E("Traction à la serviette", "traction", 7, eq=["barre_fixe", "serviette"], pose="traction.serviette.barre_fixe", prim="grand_dorsal biceps prehension", sec="brachial brachio_radial grand_rond trapeze_moyen_inferieur rhomboides")
E("Traction archer", "traction_archer", 8)
E("Traction assistée élastique", "traction_assistee", 3)
E("Traction autour du monde", "traction_archer", 8)
E("Traction aux anneaux", "traction_anneaux", 5)
E("Traction aux anneaux prise neutre", "traction_anneaux", 5, doublon="Traction aux anneaux")
E("Traction commando", "traction", 6)
E("Traction excentrique lestée", "traction_negative", 6, mods=["leste"], base="Traction lestée")
E("Traction explosive", "traction_explosive", 7)
E("Traction haute explosive (high pull-up)", "traction_explosive", 8)
E("Traction isométrique (menton au-dessus)", "traction_iso", 4)
E("Traction isométrique 90°", "traction_iso", 5, pose="suspension.iso90.barre_fixe")
E("Traction L-sit", "traction_l", 7)
E("Traction lestée", "traction", 6, mods=["leste"], base="Traction pronation")
E("Traction lestée cluster", "traction", 6, mods=["leste", "clusters"], base="Traction lestée")
E("Traction lestée élastique (accommodante)", "traction", 7, mods=["leste", "elastique_resistance"], base="Traction lestée",
  eq=["barre_fixe", "lest", "elastique"], nc="Matériel v1 « élastique » seul : barre fixe et lest nécessaires.")
E("Traction lestée pause", "traction", 6, mods=["leste", "pause"], base="Traction lestée")
E("Traction lestée tempo", "traction", 6, mods=["leste", "tempo"], base="Traction lestée")
E("Traction lestée — singles lourds", "traction", 7, mods=["leste", "singles_lourds"], base="Traction lestée")
E("Traction négative lente", "traction_negative", 3)
E("Traction pause haute", "traction", 5, mods=["pause"], base="Traction pronation")
E("Traction poitrine-barre", "traction_poitrine", 6)
E("Traction prise large", "traction", 6)
E("Traction prise mixte", "traction", 5)
E("Traction prise neutre", "traction", 5)
E("Traction prise serrée", "traction", 5)
E("Traction pronation", "traction", 5)
E("Traction sternum", "traction_poitrine", 8)
E("Traction supination", "traction", 5, prim="grand_dorsal biceps", sec="brachial grand_rond trapeze_moyen_inferieur rhomboides deltoide_posterieur", alias=["chin-up"])
E("Traction tempo (3 s excentrique)", "traction", 5, mods=["tempo"], base="Traction pronation")
E("Traction typewriter", "traction_archer", 8)
E("Traction une main (assistée)", "traction_un_bras", 9, mods=["assiste"], base="Traction une main (négative)")
E("Traction une main (négative)", "traction_un_bras", 9, mods=["negatif"])
E("Tractions explosives poitrine-barre", "traction_explosive", 7)
E("Tractions PdC", "traction", 5, doublon="Traction pronation")
E("Transition muscle-up à l'élastique", "muscle_up_transition", 6, doublon="Transitions de muscle-up à l'élastique")
E("Transition muscle-up assistée pieds au sol", "muscle_up_transition", 4, charge="assistance", eq=["barre_basse"])
E("Transitions de muscle-up à l'élastique", "muscle_up_transition", 6)
E("Travail poignet excentrique (haltère)", "poignet_flexion", 1, mods=["negatif"], prim="flechisseurs_du_poignet extenseurs_du_poignet")
E("Tuck jumps", "saut", 5, pose="saut.tuck")
E("Tuck planche", "planche_skill", 7, pose="planche_skill.tuck")
E("Tuck-ups", "v_ups", 3)
E("Turkish get-up", "turkish", 6)
# ------------------------------------------------------------------ V – Z
E("V-sit (tenue)", "vsit", 9)
E("V-sit progression", "vsit", 8, nc="Intitulé « progression » sans étape précise.")
E("V-ups", "v_ups", 4)
E("Vélo — intervalles", "ergo_velo", 4, mods=["intervalles"], base="Echo bike (calories)")
E("Wall balls", "wall_ball", 4)
E("Wall sit (chaise)", "wall_sit", 2)
E("Wall slides (glissés au mur)", "wall_slides", 1)
E("Wall walks", "wall_walk", 5)
E("Windshield wipers (essuie-glaces)", "windshield", 8)
E("Woodchop poulie", "woodchop", 3)
E("Wrist push-ups (poignets)", "mobilite_poignets", 2, pose="planche_gainage.bras_tendus", mesure="repetitions")
E("YTW à plat ventre (banc incliné)", "ytw", 2)
E("YTW allongé", "ytw", 2, eq=["halteres"], doublon="YTW à plat ventre (banc incliné)")
E("Z-press", "developpe_assis", 5, charge="barre", eq=["barre"], pose="press.assis")
E("Barre au front EZ", "barre_front", 3, added=True, nom="Barre au front EZ",
  source_note="Présent dans le pilotage du programme (B35) mais absent de la base v1.")

# ------------------------------------------------------------------ EXERCICES AJOUTÉS (progressions, mobilité, couverture)
E("Pompes au mur", "pompe_mur", 1, added=True)
E("Pompe à un bras", "pompe_un_bras", 9, added=True, eq=["aucun"])
E("Suspension passive pieds au sol", "dead_hang", 1, added=True, charge="assistance", alias=["suspension assistée"], pose="suspension.passif.pieds_sol")
E("Rowing australien barre haute", "rowing_australien", 2, added=True)
E("Traction lestée lourde", "traction", 8, added=True, mods=["leste"], base="Traction lestée", role="hors_generateur",
  nc="Entrée de palier (lest ≥ 25 % du poids de corps) utilisée uniquement comme étape d'arbre.")
E("Dips sur banc genoux fléchis", "dips_banc_genoux", 2, added=True)
E("Support hold aux barres", "support_hold", 2, added=True)
E("Squat assisté (appui)", "squat_assiste", 1, added=True)
E("Squat sur chaise", "squat_chaise", 1, added=True)
E("Pistol squat sur box", "pistol_box", 6, added=True)
E("Fente statique (split squat)", "fente", 2, added=True)
E("Charnière de hanche au bâton", "charniere_baton", 1, added=True)
E("Soulevé de terre roumain haltères", "sdt_roumain", 3, added=True, charge="halteres", eq=["halteres"])
E("Planche sur les genoux", "planche_genoux", 1, added=True)
E("Ab wheel à genoux (amplitude courte)", "ab_wheel", 4, added=True)
E("Hollow body groupé", "hollow_groupe", 2, added=True)
E("Isométrie de transition muscle-up", "muscle_up_iso", 7, added=True, base="Muscle-up")
E("Planche complète", "planche_skill", 10, added=True, pose="planche_skill.full")
E("Pike hold (V inversé)", "pompe_pike", 2, added=True, type="figure_statique", mesure="temps")
E("L-sit une jambe", "lsit_une_jambe", 4, added=True)
E("Planche latérale sur les genoux", "planche_laterale", 1, added=True)
E("Drapeau vertical (tenue)", "drapeau", 6, added=True, pose="drapeau.vertical")
E("Drapeau straddle", "drapeau", 8, added=True, pose="drapeau.straddle")
E("Cercles de bras", "cercles_bras", 1, added=True)
E("Squat profond tenu", "squat_profond_tenu", 2, added=True)
E("Mobilisation cheville genou au mur", "mobilite_chevilles", 1, added=True)
E("Fente basse étirement (hanche)", "etirement_flechisseurs", 1, added=True)
E("Rowing à la serviette (porte)", "rowing_australien", 2, added=True, eq=["serviette"], pose="rowing.penche",
  precautions_plus=["suspension"], alias=["tirage serviette coincée dans une porte fermée"])
E("Tirage isométrique à la serviette", "traction_iso", 1, added=True, type="tirage_vertical", eq=["serviette"], pose="debout.grip",
  alias=["tirage vertical isométrique serviette"])
E("Tractions australiennes pieds au sol (table)", "rowing_australien", 2, added=True, eq=["support_stable"],
  precautions_plus=["suspension"], alias=["rowing sous une table solide"])
E("Marche en fente", "fente", 2, added=True)
E("Pont fessier marché", "pont_fessier", 2, added=True, mesure="repetitions")
E("Superman W", "superman", 1, added=True, prim="deltoide_posterieur rhomboides trapeze_moyen_inferieur", sec="erecteurs infra_epineux petit_rond grand_fessier")
E("Gainage anti-rotation en planche (épaules)", "planche_bras_tendus", 3, added=True, type="gainage_anti_rotation", mesure="repetitions")
E("Tirage élastique horizontal", "rowing_australien", 1, added=True, charge="elastique", eq=["elastique"], pose="assis.row")
E("Tirage élastique vertical", "tirage_vertical_poulie", 1, added=True, charge="elastique", eq=["elastique"])
E("Développé élastique au-dessus de la tête", "developpe_halteres", 1, added=True, charge="elastique", eq=["elastique"])
E("Pompes élastique", "pompe", 4, added=True, mods=["elastique_resistance"], base="Pompes", eq=["elastique"])
E("Squat élastique", "squat_pdc", 2, added=True, charge="elastique", eq=["elastique"], pose="squat.elastique")
E("Pallof isométrique au partenaire ou à la serviette", "pallof", 1, added=True, charge="poids_de_corps", eq=["serviette"])
E("Pompes lestées lourdes", "pompe", 7, added=True, mods=["leste"], base="Pompes lestées", role="hors_generateur",
  nc="Entrée de palier (lest ≥ 20 % du poids de corps) utilisée uniquement comme étape d'arbre.")
E("Dips lestés lourds", "dips_barres", 8, added=True, mods=["leste"], base="Dips lestés", role="hors_generateur",
  nc="Entrée de palier (lest ≥ 30 % du poids de corps) utilisée uniquement comme étape d'arbre.")
# Ajouts de couverture « maison sans matériel » (manques de la matrice KT-048)
E("Pompes pike sur les genoux", "pompe_pike", 3, added=True)
E("Soulevé de terre sur une jambe au poids de corps", "sdt_unijambe", 4, added=True, charge="poids_de_corps", eq=["aucun"])
E("Hip thrust une jambe (épaules sur une chaise)", "hip_thrust", 4, added=True, charge="poids_de_corps", eq=["support_stable"], uni=True)
E("Planche bras et jambe opposés levés", "planche_bras_tendus", 4, added=True, type="gainage_anti_rotation", mesure="repetitions")
E("Planche de l'ours avec touchers d'épaules", "crawl", 4, added=True, type="gainage_anti_rotation", mesure="repetitions",
  pose="quadrupedie.bear_crawl")
E("Planche latérale bras tendu", "planche_laterale", 3, added=True, contrainte="21100100", pose="planche_laterale.bras_tendu")
E("Planche latérale avec abduction de jambe", "planche_laterale", 5, added=True, prim="obliques carre_des_lombes moyen_fessier", sec="petit_fessier tenseur_fascia_lata transverse_abdomen")


# ------------------------------------------------------------------ AJOUTS L9R : couverture de la matrice type × lieu × difficulté
# Règle (prompt L9R) : au moins 3 exercices par case quand un exercice réel existe. Chaque ajout est une variante
# d'un archétype sourcé (D-L9-02) ; la difficulté suit la progression usuelle de la variante (voir coverage_report §3).
L9R = "l9r"
# poussée verticale, maison sans matériel 4-6
E("HSPU négatives (mur)", "hspu", 6, added=L9R, mods=["negatif"], eq=["mur"],
  cues=["Monte en ATR dos au mur, descends en 3 à 5 s jusqu'à effleurer le sol avec la tête", "Coudes à 45° du buste, pas écartés", "Redescends du mur entre les répétitions"])
# tirage horizontal
E("Tractions australiennes sous table genoux fléchis", "rowing_australien", 1, added=L9R, eq=["support_stable"], precautions_plus=["suspension"], pose="rowing.australien_genoux",
  cues=["Allongé sous une table solide, genoux fléchis pieds à plat", "Tire la poitrine vers le bord de la table", "Table lourde et stable, jamais une table pliante"])
E("Tractions australiennes sous table pieds surélevés", "rowing_australien", 4, added=L9R, eq=["support_stable"], precautions_plus=["suspension"], pose="rowing.australien_pieds_hauts",
  cues=["Pieds posés sur une chaise, corps horizontal sous la table", "Omoplates serrées puis coudes tirés vers les côtes", "Bassin gainé, aucun creux lombaire"])
E("Rowing à la serviette à une main (porte)", "rowing_australien", 5, added=L9R, eq=["serviette"], uni=True, pose="rowing.penche", precautions_plus=["suspension"],
  cues=["Serviette coincée dans une porte fermée, un bras tendu, corps incliné", "Tire jusqu'à toucher les côtes, l'autre main derrière le dos", "Épaules face à la porte : pas de rotation du buste"])
E("Rows archer sous table", "rowing_australien", 6, added=L9R, eq=["support_stable"], precautions_plus=["suspension"], pose="rowing.archer",
  cues=["Un bras tire, l'autre reste tendu et glisse le long du bord", "Poitrine au bord de la table côté bras qui tire", "Change de côté à chaque répétition"])
E("Rowing inversé à un bras sous table", "rowing_australien", 7, added=L9R, eq=["support_stable"], uni=True, precautions_plus=["suspension"],
  cues=["Une seule main sur le bord, l'autre sur le ventre", "Tire jusqu'au contact sans tourner le buste", "Genoux fléchis pour régler la difficulté"])
E("Rowing inversé à un bras (barre basse)", "rowing_australien", 7, added=L9R, eq=["barre_basse"], uni=True,
  cues=["Une main sur la barre, l'autre sur le ventre, corps rigide", "Tire la poitrine vers la barre sans rotation", "Pieds au sol ou surélevés pour ajuster"])
E("Rows australiens lestés (gilet)", "rowing_australien", 7, added=L9R, mods=["leste"], eq=["barre_basse", "lest"], base="Australian pull-ups (rows barre basse)")
# squat 7-10 sans matériel
E("Shrimp squat avancé (pied tenu à deux mains)", "shrimp_squat", 9, added=L9R, eq=["aucun"], precautions_plus=["equilibre"],
  cues=["Pied arrière tenu des deux mains derrière le dos", "Descends jusqu'à toucher le sol avec le genou arrière, buste droit", "Remonte sans élan ni appui"])
E("Pistol squat sauté", "pistol", 9, added=L9R, mods=["explosif"], eq=["aucun"], precautions_plus=["impacts", "equilibre"],
  cues=["Pistol complet puis extension explosive jusqu'au décollage", "Réception amortie sur la même jambe, genou dans l'axe", "Peu de répétitions, technique parfaite"])
# charnière de hanche
E("Pont fessier une jambe pieds surélevés", "pont_fessier", 4, added=L9R, eq=["support_stable"], uni=True, pose="pont.unijambe_pieds_hauts",
  cues=["Talon posé sur une chaise, l'autre jambe tendue en l'air", "Pousse le bassin vers le plafond jusqu'à l'alignement épaule-hanche-genou", "Redescends lentement sans toucher le sol"])
E("Soulevé de terre roumain une jambe sac lesté", "sdt_unijambe", 5, added=L9R, charge="objet_leste", eq=["sac_leste"],
  cues=["Sac tenu à deux mains, jambe libre tendue vers l'arrière", "Bascule du buste par la hanche, dos plat", "Hanches restent face au sol"])
E("Soulevé de terre roumain une jambe haltères lourd", "sdt_unijambe", 7, added=L9R, mods=["leste"], eq=["halteres"], base="Soulevé de terre unilatéral haltère",
  cues=["Deux haltères lourds, jambe libre tendue vers l'arrière", "Bascule contrôlée jusqu'à l'étirement des ischio-jambiers", "Un appui stable : pose le pied libre entre les répétitions si besoin"])
E("Soulevé de terre en déficit", "sdt", 7, added=L9R, eq=["barre", "disques"], base="Soulevé de terre",
  cues=["Debout sur un disque ou une plateforme basse : amplitude augmentée", "Dos plat, hanches un peu plus basses qu'au sol", "Charge plus légère qu'au soulevé classique"])
E("Hip thrust barre lourd", "hip_thrust", 7, added=L9R, eq=["barre", "banc"], base="Hip thrust",
  cues=["Barre calée sur le pli des hanches (coussin), haut du dos sur le banc", "Pousse par les talons jusqu'à l'alignement épaules-hanches-genoux", "Menton rentré, côtes basses en haut"])
E("Hip thrust une jambe lesté", "hip_thrust", 7, added=L9R, eq=["support_stable", "lest"], uni=True, mods=["leste"], base="Hip thrust unilatéral",
  cues=["Épaules sur un support, un pied au sol, lest sur le bassin", "Pousse jusqu'à l'alignement, sans rotation du bassin", "Redescends lentement"])
# fente 7-10
E("Fentes bulgares sautées", "fente_bulgare", 7, added=L9R, mods=["explosif"], eq=["support_stable"], precautions_plus=["impacts"],
  cues=["Pied arrière sur le support, descente contrôlée puis saut", "Réception amortie sur le pied avant, genou dans l'axe", "Bras pour l'équilibre, buste droit"])
E("Squat bulgare haltères lourd", "fente_bulgare", 7, added=L9R, mods=["leste"], eq=["halteres", "support_stable"], base="Fentes bulgares",
  cues=["Haltères lourds tenus le long du corps", "Descente jusqu'à la cuisse horizontale, buste légèrement penché", "Pousse par le pied avant entier"])
E("Squat bulgare gilet lesté lourd", "fente_bulgare", 7, added=L9R, mods=["leste"], eq=["support_stable", "lest"], base="Squat bulgare lesté (gilet)",
  cues=["Gilet ou ceinture lestée, mains libres pour l'équilibre", "Genou arrière vers le sol, buste droit", "Séries courtes, charge progressive"])
E("Fentes arrière en déficit lestées", "fente", 7, added=L9R, mods=["leste"], eq=["halteres", "support_stable"], base="Fentes déficit", pose="fente.deficit",
  cues=["Pied avant sur une marche, haltères en main", "Recule en fente jusqu'à frôler le sol du genou", "Remonte par le talon avant"])
# gainage anti-extension 7-10
E("Planche à levier long (mains avancées)", "planche_bras_tendus", 7, added=L9R, pose="planche_gainage.levier_long",
  cues=["Mains posées bien en avant des épaules", "Bassin rentré, aucun creux lombaire", "Respire sans relâcher le gainage"])
E("Planche superman (tenue)", "planche_bras_tendus", 9, added=L9R, pose="planche_gainage.superman", precautions_plus=["lombaire"],
  cues=["Mains très loin devant, corps presque parallèle au sol", "Bassin en rétroversion permanente", "Tenues courtes, arrêt dès que le bas du dos se creuse"])
E("Body saw amplitude complète", "body_saw", 7, added=L9R, eq=["serviette"], base="Body saw (sliders)",
  cues=["Coudes au sol, pieds sur serviettes", "Recule le corps le plus loin possible sans creuser le dos", "Reviens en tirant avec les abdominaux"])
E("Dragon flag négatif (support au sol)", "dragon_flag", 7, added=L9R, eq=["support_stable"],
  cues=["Allongé, mains agrippées à un meuble lourd derrière la tête", "Corps monté en chandelle puis descendu en 4 à 6 s, droit comme une planche", "Seules les omoplates touchent le sol"])
E("Dragon flag (support au sol)", "dragon_flag", 9, added=L9R, eq=["support_stable"], base="Dragon flag complet",
  cues=["Mains sur un meuble lourd, corps droit des épaules aux pieds", "Descente et montée contrôlées sans plier les hanches", "Arrêt dès que le bas du dos se cambre"])
# gainage anti-rotation
E("Planche avec passage d'objet sous le corps", "planche_bras_tendus", 4, added=L9R, type="gainage_anti_rotation", mesure="repetitions", eq=["aucun"],
  cues=["Planche bras tendus, pieds écartés", "Passe un objet d'une main à l'autre sous le buste sans bouger le bassin", "Alterne les côtés lentement"])
E("Pompes avec touchers d'épaules", "pompe", 5, added=L9R, type="gainage_anti_rotation", mesure="repetitions", eq=["aucun"],
  cues=["Une pompe complète puis touche chaque épaule avec la main opposée", "Pieds écartés, bassin immobile pendant les touchers", "Rythme lent"])
E("Planche bras et jambe opposés (tenue)", "planche_bras_tendus", 7, added=L9R, type="gainage_anti_rotation", pose="planche_gainage.opposes", mesure="temps",
  cues=["Bras tendu devant et jambe opposée levée, tenue 10 à 30 s", "Bassin horizontal, aucune rotation", "Change de côté"])
E("Planche à un bras", "planche_bras_tendus", 8, added=L9R, type="gainage_anti_rotation", pose="planche_gainage.un_bras", mesure="temps",
  cues=["Pieds largement écartés, une main sous le sternum", "L'autre main dans le dos, bassin parfaitement horizontal", "Tenues courtes des deux côtés"])
# gainage anti-flexion latérale
E("Planche latérale pieds surélevés", "planche_laterale", 5, added=L9R, eq=["support_stable"], pose="planche_laterale.pieds_sureleves",
  cues=["Pieds superposés sur une chaise, coude au sol", "Corps aligné de la tête aux pieds", "Hanche haute pendant toute la tenue"])
E("Planche latérale étoile", "planche_laterale", 7, added=L9R, pose="planche_laterale.etoile",
  cues=["Planche latérale puis bras et jambe du dessus levés", "Hanche poussée vers le plafond", "Tenue 10 à 20 s de chaque côté"])
E("Copenhagen plank à levier long", "copenhague", 7, added=L9R, eq=["support_stable"], base="Copenhagen plank",
  cues=["Pied (et non le genou) du dessus posé sur le support", "Jambe du dessous tendue dans le vide, bassin haut", "Progression lente : les adducteurs s'adaptent doucement"])
E("Planche latérale bras tendu lestée", "planche_laterale", 7, added=L9R, mods=["leste"], eq=["lest"], base="Planche latérale bras tendu", pose="planche_laterale.bras_tendu",
  cues=["Gilet lesté ou disque sur la hanche", "Main sous l'épaule, bras tendu", "Corps aligné, tenue 20 à 40 s"])
# portés
E("Suitcase carry sac lesté", "suitcase_carry", 3, added=L9R, eq=["sac_leste"], charge="objet_leste", uni=True,
  cues=["Sac tenu d'une main le long de la cuisse", "Buste parfaitement droit, l'autre bras libre", "Change de main à mi-parcours"])
E("Bear hug carry sac lesté", "sandbag_carry", 4, added=L9R, eq=["sac_leste"],
  cues=["Sac serré contre la poitrine, bras enroulés", "Marche à pas courts, dos droit", "Respiration courte et régulière"])
E("Overhead carry sac lesté", "overhead_carry", 5, added=L9R, eq=["sac_leste"], charge="objet_leste", precautions_plus=["epaule_au_dessus_tete"],
  cues=["Sac tenu bras tendus au-dessus de la tête", "Côtes basses, regard devant", "Marche lente et régulière"])
E("Rack carry kettlebells", "farmer", 4, added=L9R, eq=["kettlebell"], charge="kettlebell",
  cues=["Deux kettlebells en position rack (coudes serrés, poignets neutres)", "Buste droit, respiration continue", "Distance ou temps définis"])
E("Farmer walk haltères lourds", "farmer", 7, added=L9R, mods=["leste"], eq=["halteres"], base="Farmer walk",
  cues=["Charge très lourde, prise ferme", "Pas courts et rapides, épaules basses", "Arrête-toi avant que la prise ne lâche"])
E("Sandbag carry lourd", "sandbag_carry", 7, added=L9R, mods=["leste"], eq=["sac_leste"], base="Sandbag carry",
  cues=["Sac lourd serré contre la poitrine ou sur l'épaule", "Dos gainé, pas courts", "Pose le sac au sol de façon contrôlée"])
E("Overhead carry barre", "overhead_carry", 7, added=L9R, eq=["barre"], charge="barre", precautions_plus=["epaule_au_dessus_tete"],
  cues=["Barre verrouillée au-dessus de la tête, prise large", "Côtes basses, marche lente", "Charge prudente : la fatigue dégrade vite le verrouillage"])
E("Farmer walk très lourd (trap bar)", "farmer", 7, added=L9R, mods=["singles_lourds"], eq=["barre"], charge="barre", base="Farmer walk lourd (trap bar)",
  cues=["Charge maximale tenue sur une courte distance", "Épaules basses, buste droit", "Repos complet entre les passages"])
E("Farmer walk sacs lestés", "farmer", 3, added=L9R, eq=["sac_leste"], charge="objet_leste",
  cues=["Un sac dans chaque main, bras le long du corps", "Buste droit, épaules basses", "Pas courts et réguliers"])
E("Zercher carry sac lesté", "sandbag_carry", 5, added=L9R, eq=["sac_leste"],
  cues=["Sac porté dans le pli des coudes, mains jointes", "Coudes hauts, buste droit, gainage fort", "Marche lente"])
E("Fentes marchées lestées lourdes (gilet)", "fente", 7, added=L9R, mods=["leste"], eq=["lest"], base="Fentes marchées",
  cues=["Gilet lesté, grands pas, genou arrière vers le sol", "Buste droit, poussée par le talon avant", "Distance ou nombre de pas définis"])
E("Kettlebell swing lourd (deux mains)", "swing", 7, added=L9R, mods=["leste"], eq=["kettlebell"], base="Kettlebell swing",
  cues=["Kettlebell lourde, hanches qui claquent en extension", "Bras relâchés : la charge monte par la hanche, pas par les épaules", "Séries courtes et explosives"])
E("Pancake à plat (poitrine au sol)", "mobilite_hanches", 8, added=L9R, prim="adducteurs ischios", sec="grand_fessier", pose="assis_sol.flexion",
  cues=["Jambes très écartées, buste couché jusqu'au sol", "Bassin basculé vers l'avant, dos long", "Progression lente sur plusieurs mois"])
# locomotion 7-10
E("Foulées bondissantes (bounding)", "sprint", 7, added=L9R, eq=["espace_exterieur"], precautions_plus=["impacts"],
  cues=["Grandes foulées sautées, genou haut, bras opposé", "Réception active sur l'avant du pied", "20 à 40 m, récupération complète"])
E("Sprints répétés (10 × 50 m)", "sprint", 7, added=L9R, mods=["intervalles"], eq=["espace_exterieur"], base="Sprint",
  cues=["Sprint maximal sur 50 m, retour en marchant", "Échauffement progressif obligatoire", "Arrêt à la première baisse nette de vitesse"])
E("Bear crawl lesté (gilet)", "crawl", 7, added=L9R, mods=["leste"], eq=["lest", "sol_degage"], base="Bear crawl",
  cues=["Gilet lesté, genoux à 5 cm du sol", "Main et pied opposés avancent ensemble", "Bassin stable, pas de balancement"])
# mobilité
E("Pancake assis (écart facial)", "mobilite_hanches", 4, added=L9R, prim="adducteurs ischios", sec="grand_fessier", pose="assis_sol.flexion",
  cues=["Assis jambes écartées, buste penché vers l'avant par les hanches", "Dos long, pieds en flexion", "Respire et gagne quelques centimètres à chaque expiration"])
E("Pont dorsal une jambe", "pont_dorsal", 7, added=L9R, pose="dos_au_sol.bridge_unijambe",
  cues=["Depuis le pont complet, une jambe tendue vers le plafond", "Coudes verrouillés, poussée par l'autre jambe", "Tenue courte, change de jambe"])
E("Descente en pont le long du mur", "pont_dorsal", 8, added=L9R, eq=["mur"], precautions_plus=["tete_en_bas"],
  cues=["Dos au mur, mains qui descendent le mur jusqu'au pont complet", "Remonte en marchant les mains si possible", "Échauffement complet des épaules et du dos avant"])
# figure statique 1-3 sans matériel
E("Frog stand (crow)", "atr", 3, added=L9R, eq=["aucun"], pose="atr.frog", precautions_plus=["poignet_extension"],
  cues=["Accroupi, mains au sol, genoux calés sur l'arrière des bras", "Bascule le poids vers l'avant jusqu'à décoller les pieds", "Regard devant les mains, doigts actifs"])
E("L-sit genoux fléchis au sol", "lsit_tuck", 3, added=L9R, eq=["aucun"], pose="lsit.tuck_sol",
  cues=["Mains à plat au sol le long des hanches, bras tendus", "Pousse le sol pour décoller les fesses, genoux fléchis pieds levés", "Épaules abaissées, tenue 5 à 20 s"])
# figure dynamique 1-3
E("Montée en ATR contre le mur (kick-up)", "atr_dos_mur", 3, added=L9R, type="figure_dynamique", mesure="repetitions", precautions_plus=["equilibre", "poignet_extension"],
  cues=["Mains à 15 cm du mur, une jambe lance, l'autre suit", "Talons au mur, corps aligné", "Redescends une jambe après l'autre"])
E("Wall walks partiels (mi-hauteur)", "wall_walk", 3, added=L9R, eq=["mur"],
  cues=["Depuis la planche pieds au mur, marche les mains jusqu'à ce que les pieds soient à mi-hauteur", "Bassin rentré, pas de creux lombaire", "Redescends en marchant les mains"])
E("Press to handstand (pike press)", "atr", 9, added=L9R, eq=["aucun"], type="figure_dynamique", mesure="repetitions", precautions_plus=["equilibre", "chute_arriere"],
  cues=["Depuis la flexion avant pieds près des mains, épaules poussées loin devant", "Les hanches montent au-dessus des mains, les jambes suivent sans élan", "Compression et équilibre : progresser depuis le pike press assisté"])
# conditionnement 7-10
E("Tuck jump burpees", "burpee", 7, added=L9R, precautions_plus=["impacts", "cardio_intense"],
  cues=["Burpee complet terminé par un saut genoux à la poitrine", "Réception amortie, gainage à chaque phase", "Rythme régulier plutôt que maximal"])
E("Burpees Navy Seal", "burpee", 7, added=L9R, precautions_plus=["cardio_intense"],
  cues=["En planche : pompe, genou droit au coude, pompe, genou gauche au coude, pompe", "Retour debout et saut", "Bassin stable pendant les genoux-coudes"])
E("Thruster haltères lourd", "thruster", 7, added=L9R, mods=["leste"], eq=["halteres"], base="Thruster haltères",
  cues=["Haltères lourds en position rack, squat complet", "Montée explosive prolongée par le développé", "Poignets neutres, coudes devant"])
E("Burpees pull-up lestés (gilet)", "burpee", 8, added=L9R, mods=["leste"], eq=["lest", "barre_fixe"], base="Burpees pull-up",
  cues=["Gilet lesté : burpee puis traction", "Menton au-dessus de la barre à chaque répétition", "Séries courtes"])
# isolation
E("Extension triceps au poids de corps (mains au sol)", "barre_front", 4, added=L9R, eq=["aucun"], charge="poids_de_corps", pose="sol.triceps_extension",
  cues=["Planche bras tendus, mains un peu en avant des épaules", "Plie les coudes vers l'avant jusqu'à poser les avant-bras", "Repousse par les triceps, corps gainé"])
E("Nordic curl assisté (mains)", "nordic", 5, added=L9R, mods=["assiste"], eq=["support_stable"], base="Nordic curl (excentrique)",
  cues=["Chevilles calées sous un meuble lourd, mains prêtes à freiner", "Descente lente, hanches ouvertes", "Les mains amortissent la fin puis aident à remonter"])
E("Curl ischio glissé une jambe (serviette)", "leg_curl_sol", 6, added=L9R, uni=True, eq=["serviette"], base="Leg curl sliders",
  cues=["Pont fessier une jambe sur une serviette glissante", "Tire le talon vers les fesses sans laisser tomber le bassin", "Retour lent jambe tendue"])
E("Extension triceps au poids de corps pieds surélevés", "barre_front", 7, added=L9R, eq=["support_stable"], charge="poids_de_corps", pose="sol.triceps_extension",
  cues=["Pieds sur une chaise, mains au sol en avant des épaules", "Coudes pliés vers l'avant jusqu'aux avant-bras au sol", "Extension complète sans creuser le dos"])
E("Nordic curl complet", "nordic", 9, added=L9R, eq=["support_stable"], base="Nordic curl (excentrique)",
  cues=["Descente contrôlée puis remontée sans aide des mains", "Hanches ouvertes tout le mouvement", "Peu de répétitions, repos long"])
E("Nordic curl lesté", "nordic", 10, added=L9R, mods=["leste"], eq=["support_stable", "lest"], base="Nordic curl (excentrique)",
  cues=["Disque ou gilet tenu contre la poitrine", "Descente et remontée complètes", "Réservé aux profils très avancés"])
# flexion du tronc
E("Sit-ups jambes tendues bras levés", "situp", 4, added=L9R, pose="dos_au_sol.situp_jambes_tendues",
  cues=["Allongé jambes tendues, bras au-dessus de la tête", "Enroule le buste jusqu'à toucher les pieds", "Redescends vertèbre par vertèbre"])
E("Relevés de jambes au sol avec élévation du bassin", "relevé_jambes", 5, added=L9R,
  cues=["Jambes montent à la verticale puis le bassin décolle vers le plafond", "Mains au sol, bas du dos plaqué", "Retour lent sans balancement"])
E("Toes to bar strict tempo", "toes_to_bar", 8, added=L9R, mods=["tempo"], base="Toes to bar strict",
  cues=["Suspension active, jambes tendues", "Montée contrôlée jusqu'à la barre, descente en 3 s", "Aucun balancement"])


# Démonstrations refusées exercice par exercice (contrôle visuel L9R) : le gabarit de l'archétype ne représente pas fidèlement le geste.
DEMO_INDISPONIBLE = {
    "muscle-up-kipping": "élan (kip) et balancier non modélisés : voir le muscle-up strict",
    "mobilite-hanches-90-90": "rotations de hanche assis (90/90) : geste hors du plan de la vue, aucun gabarit fidèle",
    "pompes-une-main-progression": "appui sur une seule main : non représentable de profil (le gabarit incliné à deux mains serait trompeur)",
    "press-to-handstand-pike-press": "montée en ATR par compression : aucun gabarit fidèle (transition complexe)",
    "descente-en-pont-le-long-du-mur": "descente progressive le long du mur : aucun gabarit fidèle (le pont final est montré par « Bridge »)",
}

# Démonstrations réduites à la position de départ ou à une phase (geste hors du plan ou composé).
DEMO_STATIQUE = {
    "planche-avec-passage-d-objet-sous-le-corps": "passage d'objet hors du plan de la vue : planche de départ seulement",
    "pompes-avec-touchers-d-epaules": "touchers d'épaules hors du plan : la pompe est montrée, pas le toucher",
    "burpees-navy-seal": "genoux-coudes non représentés : burpee de base montré",
    "rack-carry-kettlebells": "position rack non dessinée : porté de base montré",
    "bear-hug-carry-sac-leste": "sac contre la poitrine non dessiné : porté de base montré",
    "montee-en-atr-contre-le-mur-kick-up": "lancer de jambe non modélisé : position finale (ATR dos au mur) montrée",
    "pancake-assis-ecart-facial": "écart des jambes hors du plan : flexion avant assise montrée",
    "pancake-a-plat-poitrine-au-sol": "écart des jambes hors du plan : flexion avant assise montrée",
    "zercher-carry-sac-leste": "portée dans le pli des coudes non dessinée : porté de base montré",
}
