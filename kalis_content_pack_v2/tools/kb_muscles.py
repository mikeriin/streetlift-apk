"""Taxonomie musculaire détaillée du pack v2 (L9R, étape 3).

Chaque entrée : id stable, nom français, nom latin (Terminologia Anatomica),
famille fonctionnelle (libellé de regroupement pour les fiches), groupe parmi
les 11 groupes de la carte musculaire actuelle de l'application
(lib/muscle_body.dart : pectoraux, épaules, biceps, triceps, avant-bras,
gainage, dos, quadriceps, ischios, fessiers, mollets), vues où le muscle est
visible sur l'atlas (face, dos), profondeur (superficiel = région dessinée
dans atlas.svg ; profond = listé en texte), actions principales (texte rédigé
pour Kalis Track, vocabulaire d'entraînement, sans vocabulaire médical).

Les noms latins et les actions ont été vérifiés le 26/09/2026 sur les pages
Wikipédia (fr/en) des muscles cités et sur la liste des muscles de wger
(fixture `muscles.json`, dépôt GitHub wger-project/wger) : voir licences.md.
Texte rédigé par Claude (L9R) ; aucune reprise de texte.
"""

GROUPES_APP = ["pectoraux", "épaules", "biceps", "triceps", "avant-bras", "gainage",
               "dos", "quadriceps", "ischios", "fessiers", "mollets"]

MUSCLES = []


def M(id_, nom, latin, famille, groupe, vues, prof, actions, note=None):
    assert groupe in GROUPES_APP, (id_, groupe)
    assert prof in ("superficiel", "profond"), id_
    assert all(v in ("face", "dos") for v in vues), id_
    MUSCLES.append({"id": id_, "nom": nom, "latin": latin, "famille": famille, "groupe": groupe,
                    "vues": list(vues), "profondeur": prof, "actions": actions, "note": note})


# ------------------------------------------------------------------ cou
M("sterno_cleido_mastoidien", "Sterno-cléido-mastoïdien", "Musculus sternocleidomastoideus", "Cou", "dos",
  ["face"], "superficiel", "Flexion et rotation de la tête ; stabilise la nuque dans les gainages et les figures.")
M("extenseurs_cervicaux", "Extenseurs de la nuque (splénius, semi-épineux)", "Mm. splenius capitis et semispinalis capitis",
  "Cou", "dos", ["dos"], "profond", "Extension et maintien de la tête ; travaillés dans les ponts, les portés et les figures tête en bas.")
M("flechisseurs_cervicaux_profonds", "Fléchisseurs profonds du cou", "Mm. longus colli et longus capitis", "Cou", "gainage",
  ["face"], "profond", "Maintien du menton rentré ; gainage de la nuque dans les creux (hollow) et les tractions.")

# ------------------------------------------------------------------ épaule et ceinture scapulaire
M("deltoide_anterieur", "Deltoïde antérieur", "M. deltoideus, pars clavicularis", "Deltoïde", "épaules",
  ["face"], "superficiel", "Élévation du bras vers l'avant, rotation interne ; moteur des poussées et des figures bras tendus.")
M("deltoide_moyen", "Deltoïde moyen", "M. deltoideus, pars acromialis", "Deltoïde", "épaules",
  ["face", "dos"], "superficiel", "Élévation du bras sur le côté ; poussées verticales, élévations latérales, équilibres.")
M("deltoide_posterieur", "Deltoïde postérieur", "M. deltoideus, pars spinalis", "Deltoïde", "épaules",
  ["dos"], "superficiel", "Recul du bras, rotation externe ; tirages horizontaux, oiseau, face pull.")
M("supra_epineux", "Supra-épineux", "M. supraspinatus", "Coiffe des rotateurs", "épaules",
  ["dos"], "profond", "Amorce l'élévation du bras et centre la tête de l'humérus ; sollicité dans toutes les élévations.")
M("infra_epineux", "Infra-épineux", "M. infraspinatus", "Coiffe des rotateurs", "épaules",
  ["dos"], "superficiel", "Rotation externe du bras ; stabilise l'épaule dans les tirages, les dips et les figures.")
M("petit_rond", "Petit rond", "M. teres minor", "Coiffe des rotateurs", "épaules",
  ["dos"], "superficiel", "Rotation externe du bras avec l'infra-épineux ; stabilisation de l'épaule.")
M("sous_scapulaire", "Sous-scapulaire", "M. subscapularis", "Coiffe des rotateurs", "épaules",
  ["face"], "profond", "Rotation interne du bras ; stabilise l'avant de l'épaule dans les poussées et le drapeau.")
M("trapeze_superieur", "Trapèze supérieur", "M. trapezius, pars descendens", "Trapèze", "dos",
  ["face", "dos"], "superficiel", "Élévation et rotation vers le haut de l'omoplate ; haussements, portés, poussées au-dessus de la tête.")
M("trapeze_moyen", "Trapèze moyen", "M. trapezius, pars transversa", "Trapèze", "dos",
  ["dos"], "superficiel", "Rapprochement des omoplates ; tirages horizontaux et tenue du dos dans les squats et soulevés.")
M("trapeze_inferieur", "Trapèze inférieur", "M. trapezius, pars ascendens", "Trapèze", "dos",
  ["dos"], "superficiel", "Abaissement et rotation vers le haut de l'omoplate ; tirages verticaux, équilibre sur les mains, Y raises.")
M("elevateur_scapula", "Élévateur de la scapula", "M. levator scapulae", "Ceinture scapulaire", "dos",
  ["dos"], "profond", "Élévation de l'omoplate ; haussements et portés lourds.")
M("rhomboides", "Rhomboïdes (grand et petit)", "Mm. rhomboideus major et minor", "Ceinture scapulaire", "dos",
  ["dos"], "profond", "Rapprochement et stabilisation des omoplates ; tirages, rowing, tenue de la posture.")
M("dentele_anterieur", "Dentelé antérieur", "M. serratus anterior", "Ceinture scapulaire", "pectoraux",
  ["face"], "superficiel", "Avancée et rotation vers le haut de l'omoplate ; pompes scapulaires, planche, poussées au-dessus de la tête.")
M("petit_pectoral", "Petit pectoral", "M. pectoralis minor", "Pectoraux", "pectoraux",
  ["face"], "profond", "Abaissement et bascule de l'omoplate ; dips, pompes, respiration forcée.")
M("grand_pectoral_claviculaire", "Grand pectoral, chef claviculaire", "M. pectoralis major, pars clavicularis", "Pectoraux", "pectoraux",
  ["face"], "superficiel", "Élévation et rapprochement du bras vers l'avant ; poussées inclinées, dips serrés, planche.")
M("grand_pectoral_sterno_costal", "Grand pectoral, chef sterno-costal", "M. pectoralis major, pars sternocostalis", "Pectoraux", "pectoraux",
  ["face"], "superficiel", "Rapprochement du bras devant le buste, abaissement du bras ; pompes, développés, dips, écartés.")
M("grand_pectoral_abdominal", "Grand pectoral, chef abdominal", "M. pectoralis major, pars abdominalis", "Pectoraux", "pectoraux",
  ["face"], "superficiel", "Abaissement du bras vers le bas et l'avant ; dips, pompes déclinées, développé décliné.")
M("grand_dorsal", "Grand dorsal", "M. latissimus dorsi", "Dos", "dos",
  ["face", "dos"], "superficiel", "Abaissement et recul du bras, rotation interne ; tractions, tirages, dips, figures de levier.")
M("grand_rond", "Grand rond", "M. teres major", "Dos", "dos",
  ["dos"], "superficiel", "Assiste le grand dorsal : abaissement et recul du bras ; tractions et tirages.")

# ------------------------------------------------------------------ bras
M("biceps_chef_long", "Biceps brachial, chef long", "M. biceps brachii, caput longum", "Biceps", "biceps",
  ["face"], "superficiel", "Flexion du coude et supination ; curls, tractions supination, stabilise l'épaule bras tendu.")
M("biceps_chef_court", "Biceps brachial, chef court", "M. biceps brachii, caput breve", "Biceps", "biceps",
  ["face"], "superficiel", "Flexion du coude et supination ; curls prise large ou bras devant, tirages supination.")
M("brachial", "Brachial", "M. brachialis", "Biceps", "biceps",
  ["face", "dos"], "superficiel", "Fléchisseur principal du coude quelle que soit la prise ; tractions, curls marteau et pronation.")
M("coraco_brachial", "Coraco-brachial", "M. coracobrachialis", "Biceps", "biceps",
  ["face"], "profond", "Élévation du bras vers l'avant et rapprochement ; assiste les poussées et les figures bras tendus.")
M("triceps_chef_long", "Triceps brachial, chef long", "M. triceps brachii, caput longum", "Triceps", "triceps",
  ["dos"], "superficiel", "Extension du coude et recul du bras ; dips, extensions bras au-dessus de la tête, pompes serrées.")
M("triceps_chef_lateral", "Triceps brachial, chef latéral", "M. triceps brachii, caput laterale", "Triceps", "triceps",
  ["face", "dos"], "superficiel", "Extension du coude ; toutes les poussées et les extensions à la poulie.")
M("triceps_chef_medial", "Triceps brachial, chef médial", "M. triceps brachii, caput mediale", "Triceps", "triceps",
  ["dos"], "superficiel", "Extension du coude, actif dès les charges légères ; poussées et extensions, fin d'extension.")
M("ancone", "Anconé", "M. anconeus", "Triceps", "triceps",
  ["dos"], "superficiel", "Assiste l'extension du coude et stabilise l'articulation dans les poussées.")

# ------------------------------------------------------------------ avant-bras et main
M("brachio_radial", "Brachio-radial", "M. brachioradialis", "Avant-bras", "avant-bras",
  ["face", "dos"], "superficiel", "Flexion du coude en prise neutre ou pronation ; curls marteau, tractions pronation, portés.")
M("extenseurs_du_poignet", "Extenseurs du poignet", "Mm. extensor carpi radialis longus, brevis et ulnaris", "Avant-bras", "avant-bras",
  ["face", "dos"], "superficiel", "Extension et stabilisation du poignet ; appuis mains à plat, extensions de poignet, équilibre sur les mains.")
M("extenseurs_des_doigts", "Extenseurs des doigts", "M. extensor digitorum", "Avant-bras", "avant-bras",
  ["dos"], "superficiel", "Ouverture des doigts ; équilibre de la préhension (extensions contre élastique).")
M("flechisseurs_du_poignet", "Fléchisseurs du poignet", "Mm. flexor carpi radialis, palmaris longus, flexor carpi ulnaris", "Avant-bras", "avant-bras",
  ["face"], "superficiel", "Flexion du poignet ; curls de poignet, prise en faux grip, tenue de la barre.")
M("flechisseurs_superficiels_des_doigts", "Fléchisseur superficiel des doigts", "M. flexor digitorum superficialis", "Avant-bras", "avant-bras",
  ["face"], "superficiel", "Fermeture des doigts ; préhension sur barre, anneaux et haltères.")
M("flechisseurs_profonds_des_doigts", "Fléchisseurs profonds des doigts et du pouce", "Mm. flexor digitorum profundus et flexor pollicis longus", "Avant-bras", "avant-bras",
  ["face"], "profond", "Serrage des doigts ; suspensions, portés lourds, pince de préhension.")
M("rond_pronateur", "Rond pronateur", "M. pronator teres", "Avant-bras", "avant-bras",
  ["face"], "superficiel", "Pronation de l'avant-bras et assistance à la flexion du coude ; tractions pronation, curls inversés.")
M("supinateur", "Supinateur", "M. supinator", "Avant-bras", "avant-bras",
  ["dos"], "profond", "Supination de l'avant-bras ; curls supination et rotations du poignet.")

M("carre_pronateur", "Carré pronateur", "M. pronator quadratus", "Avant-bras", "avant-bras",
  ["face"], "profond", "Pronation de l'avant-bras ; rotations du poignet, tenue de la barre en pronation.")
M("muscles_intrinseques_main", "Muscles intrinsèques de la main (éminences thénar et hypothénar, interosseux)", "Mm. thenaris, hypothenaris, interossei", "Main", "avant-bras",
  ["face"], "profond", "Serrage fin et opposition du pouce ; pince de préhension, prise sur barre épaisse, suspensions.")

# ------------------------------------------------------------------ tronc
M("droit_abdomen", "Droit de l'abdomen", "M. rectus abdominis", "Abdominaux", "gainage",
  ["face"], "superficiel", "Flexion du tronc et bascule du bassin ; creux (hollow), crunchs, relevés de jambes, gainage anti-extension.")
M("oblique_externe", "Oblique externe", "M. obliquus externus abdominis", "Abdominaux", "gainage",
  ["face", "dos"], "superficiel", "Rotation et inclinaison du tronc, gainage anti-rotation ; essuie-glaces, planche latérale, drapeau.")
M("oblique_interne", "Oblique interne", "M. obliquus internus abdominis", "Abdominaux", "gainage",
  ["face"], "profond", "Rotation et inclinaison du tronc du même côté ; gainage anti-rotation et portés unilatéraux.")
M("transverse_abdomen", "Transverse de l'abdomen", "M. transversus abdominis", "Abdominaux", "gainage",
  ["face"], "profond", "Serrage de la ceinture abdominale ; gainage sous charge, respiration de bracing.")
M("carre_des_lombes", "Carré des lombes", "M. quadratus lumborum", "Rachis", "gainage",
  ["dos"], "profond", "Inclinaison du tronc et stabilisation latérale du bassin ; portés unilatéraux, planche latérale.")
M("erecteurs_lombaires", "Érecteurs du rachis, région lombaire", "M. erector spinae (pars lumbalis)", "Rachis", "dos",
  ["dos"], "superficiel", "Extension et maintien du bas du dos ; soulevés de terre, good morning, extensions lombaires, tenue du dos plat.")
M("erecteurs_thoraciques", "Érecteurs du rachis, région thoracique", "M. erector spinae (pars thoracica)", "Rachis", "dos",
  ["dos"], "profond", "Maintien du haut du dos droit sous charge ; squats avant, tirages, portés.")
M("multifides", "Multifides", "Mm. multifidi", "Rachis", "dos",
  ["dos"], "profond", "Stabilisation fine des vertèbres ; bird dog, gainages, mouvements de mobilité du rachis.")

M("diaphragme", "Diaphragme", "Diaphragma", "Respiration", "gainage",
  ["face"], "profond", "Muscle principal de l'inspiration ; respiration de bracing sous charge et exercices de respiration.")
M("plancher_pelvien", "Muscles du plancher pelvien", "Mm. diaphragmatis pelvis", "Respiration", "gainage",
  ["face"], "profond", "Soutien du bassin sous pression abdominale ; gainage respiratoire, reprise après une longue pause.")

# ------------------------------------------------------------------ hanche
M("grand_psoas", "Grand psoas", "M. psoas major", "Fléchisseurs de hanche", "quadriceps",
  ["face"], "profond", "Flexion de la hanche ; relevés de jambes, L-sit, montées de genoux, course.")
M("iliaque", "Iliaque", "M. iliacus", "Fléchisseurs de hanche", "quadriceps",
  ["face"], "profond", "Flexion de la hanche avec le psoas ; relevés de jambes et figures en équerre.")
M("tenseur_fascia_lata", "Tenseur du fascia lata", "M. tensor fasciae latae", "Fléchisseurs de hanche", "fessiers",
  ["face"], "superficiel", "Flexion et abduction de la hanche, rotation interne ; stabilise le genou dans les appuis unipodaux.")
M("sartorius", "Sartorius", "M. sartorius", "Fléchisseurs de hanche", "quadriceps",
  ["face"], "superficiel", "Flexion, abduction et rotation externe de la hanche ; position en tailleur, montées de genoux.")
M("grand_fessier", "Grand fessier", "M. gluteus maximus", "Fessiers", "fessiers",
  ["dos"], "superficiel", "Extension et rotation externe de la hanche ; squats, soulevés, ponts, fentes, sprints, montées.")
M("moyen_fessier", "Moyen fessier", "M. gluteus medius", "Fessiers", "fessiers",
  ["face", "dos"], "superficiel", "Abduction de la hanche et maintien du bassin sur un pied ; fentes, pistols, marches latérales.")
M("petit_fessier", "Petit fessier", "M. gluteus minimus", "Fessiers", "fessiers",
  ["dos"], "profond", "Abduction et rotation interne de la hanche ; stabilise le bassin sous le moyen fessier.")
M("rotateurs_lateraux_hanche", "Rotateurs latéraux de la hanche (piriforme, obturateurs, jumeaux, carré fémoral)",
  "Mm. piriformis, obturatorii, gemelli, quadratus femoris", "Fessiers", "fessiers",
  ["dos"], "profond", "Rotation externe de la hanche ; clamshells, squats profonds, stabilité du bassin.")
M("pectine", "Pectiné", "M. pectineus", "Adducteurs", "quadriceps",
  ["face"], "superficiel", "Adduction et flexion de la hanche ; squats larges, fentes latérales.")
M("long_adducteur", "Long adducteur", "M. adductor longus", "Adducteurs", "quadriceps",
  ["face"], "superficiel", "Adduction de la hanche ; squat sumo, fentes latérales, Copenhague, adducteurs machine.")
M("court_adducteur", "Court adducteur", "M. adductor brevis", "Adducteurs", "quadriceps",
  ["face"], "profond", "Adduction et flexion de la hanche ; mêmes exercices que le long adducteur.")
M("grand_adducteur", "Grand adducteur", "M. adductor magnus", "Adducteurs", "ischios",
  ["face", "dos"], "superficiel", "Adduction et extension de la hanche ; squats profonds, soulevés sumo, fentes, Copenhague.")
M("gracile", "Gracile", "M. gracilis", "Adducteurs", "quadriceps",
  ["face", "dos"], "superficiel", "Adduction de la hanche et assistance à la flexion du genou ; Copenhague, fentes latérales.")

# ------------------------------------------------------------------ cuisse
M("droit_femoral", "Droit fémoral", "M. rectus femoris", "Quadriceps", "quadriceps",
  ["face"], "superficiel", "Extension du genou et flexion de la hanche ; squats, fentes, relevés de jambes, sprints.")
M("vaste_lateral", "Vaste latéral", "M. vastus lateralis", "Quadriceps", "quadriceps",
  ["face", "dos"], "superficiel", "Extension du genou ; squats, presse, pistols, sissy squats.")
M("vaste_medial", "Vaste médial", "M. vastus medialis", "Quadriceps", "quadriceps",
  ["face"], "superficiel", "Extension du genou, fin de course et stabilité de la rotule ; squats profonds, fentes, extensions.")
M("vaste_intermediaire", "Vaste intermédiaire", "M. vastus intermedius", "Quadriceps", "quadriceps",
  ["face"], "profond", "Extension du genou ; tous les squats et fentes.")
M("biceps_femoral", "Biceps fémoral", "M. biceps femoris", "Ischio-jambiers", "ischios",
  ["dos"], "superficiel", "Flexion du genou et extension de la hanche ; nordic curl, soulevé roumain, pont, leg curl.")
M("biceps_femoral_chef_court", "Biceps fémoral, chef court", "M. biceps femoris, caput breve", "Ischio-jambiers", "ischios",
  ["dos"], "profond", "Flexion du genou seulement (ne croise pas la hanche) ; leg curl, nordic curl.")
M("semi_tendineux", "Semi-tendineux", "M. semitendinosus", "Ischio-jambiers", "ischios",
  ["dos"], "superficiel", "Flexion du genou et extension de la hanche ; curls, ponts, good morning.")
M("semi_membraneux", "Semi-membraneux", "M. semimembranosus", "Ischio-jambiers", "ischios",
  ["dos"], "superficiel", "Flexion du genou et extension de la hanche ; soulevés jambes tendues, curls.")
M("poplite", "Poplité", "M. popliteus", "Ischio-jambiers", "ischios",
  ["dos"], "profond", "Déverrouillage et stabilisation du genou ; appuis unipodaux et squats profonds.")

# ------------------------------------------------------------------ jambe
M("gastrocnemien_medial", "Gastrocnémien, chef médial", "M. gastrocnemius, caput mediale", "Mollets", "mollets",
  ["dos"], "superficiel", "Extension de la cheville genou tendu, assistance à la flexion du genou ; mollets debout, sauts, corde.")
M("gastrocnemien_lateral", "Gastrocnémien, chef latéral", "M. gastrocnemius, caput laterale", "Mollets", "mollets",
  ["dos"], "superficiel", "Extension de la cheville genou tendu ; mollets debout, sauts, sprints.")
M("soleaire", "Soléaire", "M. soleus", "Mollets", "mollets",
  ["face", "dos"], "superficiel", "Extension de la cheville genou fléchi, maintien debout ; mollets assis, marche, course.")
M("tibial_anterieur", "Tibial antérieur", "M. tibialis anterior", "Jambe antérieure", "mollets",
  ["face"], "superficiel", "Relevé du pied (flexion dorsale) ; tibialis raises, réceptions, marche sur les talons.")
M("long_extenseur_des_orteils", "Long extenseur des orteils et de l'hallux", "Mm. extensor digitorum longus et extensor hallucis longus", "Jambe antérieure", "mollets",
  ["face"], "superficiel", "Relevé des orteils et du pied ; réceptions, tibialis raises.")
M("fibulaires", "Fibulaires (long et court)", "Mm. fibularis longus et brevis", "Jambe latérale", "mollets",
  ["face", "dos"], "superficiel", "Éversion du pied et stabilité latérale de la cheville ; appuis unipodaux, sauts latéraux.")
M("tibial_posterieur", "Tibial postérieur", "M. tibialis posterior", "Jambe postérieure profonde", "mollets",
  ["dos"], "profond", "Inversion du pied et soutien de la voûte ; mollets, équilibres, marche.")
M("flechisseurs_profonds_des_orteils", "Long fléchisseur des orteils et de l'hallux", "Mm. flexor digitorum longus et flexor hallucis longus", "Jambe postérieure profonde", "mollets",
  ["dos"], "profond", "Flexion des orteils et assistance à l'extension de la cheville ; mollets sur marche, poussée finale de la foulée.")

M("muscles_intrinseques_pied", "Muscles intrinsèques du pied", "Mm. plantae pedis", "Pied", "mollets",
  ["face"], "profond", "Soutien de la voûte et agrippement des orteils ; équilibres, pied court, marche pieds nus.")

# ------------------------------------------------------------------ regroupements de commodité (pour la saisie des exercices)
# Un alias développe un groupe en la liste de ses chefs. Les exercices sont
# toujours stockés avec les ids détaillés.
ALIAS = {
    "pectoraux": ["grand_pectoral_sterno_costal", "grand_pectoral_claviculaire"],
    "pectoraux_tous": ["grand_pectoral_sterno_costal", "grand_pectoral_claviculaire", "grand_pectoral_abdominal"],
    "pectoraux_bas": ["grand_pectoral_sterno_costal", "grand_pectoral_abdominal"],
    "deltoides": ["deltoide_anterieur", "deltoide_moyen", "deltoide_posterieur"],
    "coiffe": ["supra_epineux", "infra_epineux", "petit_rond", "sous_scapulaire"],
    "trapezes": ["trapeze_superieur", "trapeze_moyen", "trapeze_inferieur"],
    "trapeze_moyen_inferieur": ["trapeze_moyen", "trapeze_inferieur"],
    "biceps": ["biceps_chef_long", "biceps_chef_court"],
    "flechisseurs_coude": ["biceps_chef_long", "biceps_chef_court", "brachial", "brachio_radial"],
    "triceps": ["triceps_chef_long", "triceps_chef_lateral", "triceps_chef_medial"],
    "flechisseurs_avant_bras": ["flechisseurs_du_poignet", "flechisseurs_superficiels_des_doigts", "flechisseurs_profonds_des_doigts"],
    "prehension": ["flechisseurs_superficiels_des_doigts", "flechisseurs_profonds_des_doigts", "flechisseurs_du_poignet", "muscles_intrinseques_main"],
    "extenseurs_avant_bras": ["extenseurs_du_poignet", "extenseurs_des_doigts"],
    "abdominaux": ["droit_abdomen", "oblique_externe", "oblique_interne", "transverse_abdomen"],
    "obliques": ["oblique_externe", "oblique_interne"],
    "erecteurs": ["erecteurs_lombaires", "erecteurs_thoraciques"],
    "erecteurs_profonds": ["erecteurs_lombaires", "erecteurs_thoraciques", "multifides"],
    "flechisseurs_hanche": ["grand_psoas", "iliaque", "droit_femoral", "tenseur_fascia_lata", "sartorius"],
    "ilio_psoas": ["grand_psoas", "iliaque"],
    "fessiers": ["grand_fessier", "moyen_fessier", "petit_fessier"],
    "abducteurs_hanche": ["moyen_fessier", "petit_fessier", "tenseur_fascia_lata"],
    "adducteurs": ["long_adducteur", "court_adducteur", "grand_adducteur", "gracile", "pectine"],
    "quadriceps": ["droit_femoral", "vaste_lateral", "vaste_medial", "vaste_intermediaire"],
    "vastes": ["vaste_lateral", "vaste_medial", "vaste_intermediaire"],
    "ischios": ["biceps_femoral", "biceps_femoral_chef_court", "semi_tendineux", "semi_membraneux"],
    "mollets": ["gastrocnemien_medial", "gastrocnemien_lateral", "soleaire"],
    "gastrocnemiens": ["gastrocnemien_medial", "gastrocnemien_lateral"],
    "cheville_lateral": ["fibulaires", "tibial_posterieur"],
    "cou_extenseurs": ["extenseurs_cervicaux", "trapeze_superieur"],
}

IDS = [m["id"] for m in MUSCLES]
BY_ID = {m["id"]: m for m in MUSCLES}


def expand(tokens):
    """Développe une liste de tokens (ids ou alias) en ids détaillés, sans doublon."""
    out = []
    for t in tokens:
        ids = ALIAS.get(t, [t])
        for i in ids:
            if i not in BY_ID:
                raise KeyError(f"muscle inconnu : {i}")
            if i not in out:
                out.append(i)
    return out


if __name__ == "__main__":
    import collections
    print(len(MUSCLES), "muscles")
    print(collections.Counter(m["profondeur"] for m in MUSCLES))
    print(collections.Counter(m["groupe"] for m in MUSCLES))
    assert len(IDS) == len(set(IDS))
