# Registre des points à faire valider — pack Kalis Track v2 (L9R)

Le contenu de ce pack n'a pas été relu par un professionnel diplômé (décision du propriétaire). Les faits anatomiques (muscles, type de mouvement) ont été vérifiés sur au moins deux sources publiques concordantes par archétype (voir `sources/archetypes_sources.json` et le champ `sources` de chaque exercice) ; les textes, difficultés, seuils, contraintes, précautions et démonstrations ont été produits par Claude (provenance `genere_l9r`). Les précautions sont des consignes d'entraînement, jamais des avis médicaux.

Priorité de relecture : **P1** = peut exposer un pratiquant débutant ou en reprise à une charge excessive ; **P2** = influence directe sur le générateur ou sur l'affichage anatomique ; **P3** = qualité et confort.

## 0. Sources et attributions anatomiques (P2)

### 0.1 Concordance établie par une source de variante proche

Pour ces archétypes, la seconde source décrit une variante très proche (même schéma moteur) et non l'exercice exact. Le propriétaire décide si cette concordance suffit ; sinon les muscles restent ceux de la source directe et l'exercice est marqué « à confirmer » dans l'application.

- **dips_barre_fixe** : Wikipédia (Dip) et free-exercise-db (Dips chest version) concordent sur pectoraux et triceps ; aucune source dédiée aux dips à la barre droite : variante des dips (même schéma moteur, buste plus penché).
- **manna** : calisthenics.com (Manna) et Wikipédia (L-sit, dont le manna est la progression) concordent sur les abdominaux ; deltoïde postérieur et triceps depuis calisthenics.com seulement (signalé au registre).
- **muscle_up_iso** : Calixpert (transition) et Wikipédia (Muscle-up) concordent : grand dorsal, pectoraux, triceps, biceps. L'isométrie est une phase du muscle-up.
- **respiration** : Deux articles encyclopédiques concordent : diaphragme muscle principal, intercostaux et abdominaux accessoires.
- **sandbag_carry** : fitmetrics (Sandbag carry) et free-exercise-db (Sandbag load) concordent : quadriceps, fessiers, abdominaux ; le port et le chargement du sac partagent les moteurs.
- **skin_the_cat** : Calixpert et Muscle & Strength concordent : grand dorsal primaire ; abdominaux, biceps, épaules secondaires. Le deltoïde antérieur est conservé en primaire (Calixpert) et signalé au registre.

### 0.2 Désaccords entre sources (arbitrage retenu)

Quand les sources divergent, le pack retient l'attribution majoritaire ou, à égalité, la source la plus détaillée (Wikipédia / organisme) ; le désaccord est conservé ici et dans `sources_meta.desaccord`.

- **ab_wheel** : wger 41 code l'oblique externe comme seul primaire (les autres : droit de l'abdomen). Grand dorsal : seulement FED « Rollout from Bench » (secondaire) ; retenu en secondaire (retour du bras en extension d'épaule).
- **abducteurs** : wger n'a que le grand fessier (pas de moyen fessier dans sa taxonomie).
- **adducteurs_machine** : wger 12 attribue le grand fessier (taxonomie sans adducteurs) : non retenu. FED ajoute fessiers et ischios en secondaire.
- **atr** : Wikipédia cite grand dorsal et biceps (équilibre) que les autres sources ignorent ; wger ne donne que le deltoïde antérieur
- **atr_dos_mur** : wger 711 'Wall Handstand' sans muscles ; calixpert ne précise pas l'orientation (dos/poitrine)
- **atr_poitrine_mur** : mêmes sources que dos au mur : aucune fiche ne distingue les deux orientations
- **back_lever** : désaccord réel : Wikipédia et Kovo → dos (lats, trapèzes) + biceps ; dieringe → deltoïde antérieur + biceps, pectoraux ; le biceps (chef long, bras tendu) est le seul muscle commun aux trois
- **barre_front** : JM press : compound pour FED (hybride développé serré / extension) ; wger lui donne le biceps en secondaire (douteux). Pectoraux/deltoïde antérieur en secondaire seulement pour JM press et Tate press (FED, wger), pas pour la barre au front stricte.
- **battle_rope** : FED : épaules en primaire, pectoraux/avant-bras en secondaire, rien pour le bas du corps ; wger : bas du corps et tronc en primaire, épaules/bras en secondaire. Consensus sur épaules + pectoraux + tronc, désaccord sur la hiérarchie.
- **bird_dog** : wger 1572 met le droit de l'abdomen en primaire ; ACE/wger 957/Peloton mettent le fessier et l'épaule en avant. Aucune source lisible ne nomme les multifides (l'étude EMG PubMed 37368569 n'a pas pu être lue).
- **body_saw** : Muscle & Strength ne code que « Abs » ; l'implication de l'épaule (deltoïde antérieur, dentelé, grand dorsal) est déduite de la mécanique (planche sur coudes qui recule).
- **box_jump** : FED met les ischios en primaire sur ses entrées box jump (quadriceps/fessiers en secondaire), contre ACE, wger et MuscleWiki qui ciblent fessiers + cuisses + mollets.
- **box_squat** : Fessiers : primaires pour wger, StrengthLog, Wikipédia ; secondaires pour FED. Lower back : primaire pour StrengthLog, secondaire pour FED.
- **burpee** : Aucune base ne détaille les muscles : wger et MuscleWiki classent en Chest/Abdominals, ACE et Wikipédia en « corps entier ». MuscleWiki met les abdominaux en primaire et les pectoraux en secondaire.
- **charniere_baton** : Érecteurs : primaires (isométriques) pour Wikipédia, non cités par ACE ni wger.
- **clamshell** : wger ne nomme que le grand fessier et le droit de l'abdomen (taxonomie sans moyen fessier) ; Bodybuilding-Wizard donne moyen/petit fessier. FED n'a pas d'entrée.
- **clean** : free-exercise-db met les ischios (clean, power clean) ou les quadriceps (hang clean) en primaire, wger fessiers + quadriceps ; trapèzes secondaires dans toutes les bases ; wger 683 'Power Clean' (pectoraux) erroné ; clean & jerk : épaules primaires (jerk)
- **clean_press** : Kovo (fiche centrée press) ne liste pas les jambes ; free-exercise-db clean seul : ischios primaire ; clean & press barre : épaules primaire
- **copenhague** : wger 1605 code grand fessier + quadriceps en primaires : incompatible avec l'EMG (long adducteur ≈108 % MVIC) ; rejeté. Moyen fessier : IJSPT (jambe du bas en abduction).
- **corde_a_sauter** : FED met les quadriceps en primaire et les mollets en secondaire ; wger et MuscleWiki ne citent que les gastrocnémiens/mollets.
- **course** : FED met les quadriceps seuls en primaire ; wger 1584 et Nike mettent quadriceps, ischios, fessiers, mollets ensemble. Fléchisseurs de hanche : primaires pour Nike, phase oscillante pour Wikipédia.
- **crab_walk** : SET FOR SET met grand dorsal et pectoraux en primaire ; FitnessVolt ne les cite pas ; Sweat décrit un autre exercice (marche élastique). « Deltoids » sans chef : bras en extension derrière → deltoïde postérieur (raisonnement).
- **crawl** : wger 57 met pectoraux, dentelé, mollets et triceps en primaire ; wger 1687 et ACE mettent cuisses/fessiers en primaire avec deltoïde et abdominaux ; FED (traîneau) ne voit que les jambes.
- **cuban_press** : Primaire : coiffe pour BarBend, deltoïde antérieur pour StrengthLog, « shoulders » pour FED. Type : FED classe compound (trois phases dont un développé) ; v1 isolation → à discuter. wger n'a pas d'entrée.
- **curl** : wger 202 met le brachial en primaire et le biceps en secondaire pour le curl concentration (les autres entrées font l'inverse).
- **curl_barre** : Curl pronation (reverse curl) : FED/wger gardent le biceps en primaire, Wikipédia et StrengthLog donnent l'avant-bras (brachio-radial) en primaire.
- **curl_marteau** : Les bases gardent le biceps en primaire ; Wikipédia place le brachio-radial en tête pour la prise neutre. Ordre retenu : brachio-radial, brachial, biceps.
- **curl_pupitre** : Chef accentué : Wikipédia (tel que lu) parle du chef long en fin d'extension ; le raisonnement anatomique (épaule fléchie, bras devant → chef long raccourci) fait plutôt attendre le chef court : signalé, non tranché. wger 465 ne nomme que le brachial.
- **dead_hang** : free-exercise-db (one-handed hang, catégorie stretching) met les lats en primaire ; FitCraft les donne étirés passivement, calixpert secondaires
- **depth_jump** : Niveau : FED note beginner/intermediate alors que Wikipédia décrit le depth jump comme exercice de haute intensité (méthode de choc).
- **developpe_assis** : Triceps : secondaire (FED, wger) ; v1 primaire.
- **developpe_couche** : Triceps : primaire pour Wikipédia, secondaire pour FED et wger (primaire uniquement en prise serrée : FED, wger, ACE).
- **developpe_couche_halteres** : Triceps : primaire pour Wikipédia, secondaire pour FED et wger.
- **developpe_halteres** : Triceps : secondaire (FED), absent de wger ; la v1 le met en primaire.
- **developpe_incline** : Deltoïde antérieur : « accentué » (Wikipédia) mais secondaire dans FED et wger ; aucune base ne le classe primaire.
- **developpe_militaire** : Triceps : secondaire dans FED, absent de wger, non détaillé par Wikipédia ; la v1 le met en primaire. Deltoïde moyen et trapèze supérieur : par raisonnement (aucune base ne détaille les chefs).
- **devil_press** : Ischios : secondaire chez wger, primaire (chaîne postérieure) chez BarBend. Quadriceps : cités seulement par PureGym (« legs »).
- **dips_anneaux** : Pectoraux : secondaires dans FED et Wikipédia, absents de wger ; la v1 les met en primaire (justifié par l'inclinaison du buste aux anneaux, mais non confirmé par les bases).
- **dips_barre_fixe** : Aucune base (FED, wger) n'a d'entrée pour les dips à la barre fixe ; Wikipédia nomme la variante sans lister ses muscles.
- **dips_barres** : Ordre triceps/pectoraux selon l'inclinaison : version « chest » (FED) et wger mettent le pectoral en premier ; Wikipédia et les versions « triceps » de FED mettent le triceps en premier.
- **dragon_flag** : wger met l'oblique externe en primaire ; StrengthLog et MusclesWorked en secondaire.
- **drapeau** : Gymless : quadriceps/fessiers/ischios/mollets en secondaire ; Kovo : biceps/triceps/trapèzes en soutien ; Wikipédia ne nomme aucun muscle
- **ecarte** : FED classe l'écarté incliné en compound ; wger et FED ne donnent aucun secondaire, Wikipédia et FED (incliné) donnent le deltoïde antérieur.
- **elevation_frontale** : Wikipédia met le chef claviculaire du grand pectoral en primaire ; les bases n'ont que le deltoïde antérieur.
- **elevation_laterale** : wger nomme le deltoïde antérieur en primaire (sa taxonomie de 16 muscles n'a pas de deltoïde moyen) ; FED/StrengthLevel : « shoulders » sans chef.
- **ergo_rameur** : FED ne garde que les quadriceps en primaire ; wger met 13 muscles en primaire sans hiérarchie ; Concept2 hiérarchise par phase. Deltoïde : wger cite l'antérieur, le geste de tirage sollicite plutôt le postérieur.
- **ergo_ski** : wger met les mollets en primaire (Concept2 : primaire au start seulement) ; Concept2 ajoute fléchisseurs de hanche et tibias que wger ne peut pas nommer.
- **ergo_velo** : wger 1376 met ischios et gastrocnémiens en primaire ; FED les met en secondaire. wger 177 « Cycling » a une attribution aberrante. Attention au faux ami FED « Air Bike » = exercice d'abdominaux au sol, pas le vélo à air.
- **etirement_flechisseurs** : FED classe l'étirement des fléchisseurs de hanche sous « quadriceps » (groupe le plus proche dans son vocabulaire) ; ACE sous « Butt/Hips ».
- **extension_doigts** : Aucune base (FED, wger) n'a d'entrée « finger extension ». Extenseur du pouce (StrengthLog) compris dans extenseurs_des_doigts faute d'id dédié.
- **extension_triceps_nuque** : wger 1519 « Overhead Triceps Extension » attribue le trapèze (erreur, non retenue). FED met « shoulders » en secondaire ; ici classés stabilisateurs (tenue isométrique du bras).
- **face_pull** : wger (1732) met le grand dorsal en primaire : incohérent avec FED, PureGym et Healthline (deltoïde postérieur). Coiffe : nommée par PureGym seulement.
- **farmer** : Trapèzes : secondaires pour FED, primaires pour la v1 (la charge est tenue bras tendus : élévation de l'omoplate en isométrie). ACE ne détaille pas les muscles.
- **farmer_hold** : Aucune source ne distingue la tenue statique de la marche ; consensus transposé (sans locomotion, les jambes deviennent de simples stabilisateurs).
- **fente** : Fessiers : primaires pour wger 1651/1907, Wikipédia, ACE ; secondaires pour FED et wger 205/206. Ischios : primaires pour Wikipédia, secondaires pour FED, wger 1907.
- **fente_bulgare** : Fessiers primaires pour wger 1706 et StrengthLog, secondaires pour FED. Adducteurs : primaires pour StrengthLog, secondaires pour FED Suspended, absents ailleurs.
- **fente_laterale** : Adducteurs nommés par ACE seulement (les bases ne les listent pas). Ischios primaires pour wger 1604, secondaires pour FED et wger 1653. FED omet les fessiers.
- **fente_sautee** : Fessiers primaires pour StrengthLog et Wikipédia, secondaires pour FED. Adducteurs : StrengthLog seul.
- **floor_press** : FED met le triceps en primaire et le pectoral en secondaire ; wger l'inverse. Amplitude coupée au niveau des coudes → part du triceps accrue (Wikipédia).
- **flutter** : L'entrée FED « Flutter Kicks » décrit la variante sur le ventre (fessiers, ischios) : non comparable ; l'entrée FED « Scissor Kick » et wger 235/545 (abdominaux) correspondent au geste v1.
- **foam** : Wikipédia ne nomme aucun muscle (page générale) ; les bases codent une entrée par région.
- **front_lever** : wger 'Front lever tuck' met le deltoïde antérieur et le biceps en primaire (atypique) ; Gymless place obliques/dentelé/rhomboïdes/petit rond en primaire
- **front_lever_dyn** : wger 'Front lever pull-up' met le biceps en primaire (traction), calixpert 'raises' en secondaire
- **front_squat** : Wger 257 omet les quadriceps en primaire (erreur manifeste). Abdominaux : secondaires pour FED Clean Grip et wger, stabilisateurs pour Wikipédia.
- **genoux_hauts** : wger 285 (sauts) met jambes/mollets en primaire, wger 1318 (skips) met les abdominaux en primaire et les jambes en secondaire.
- **german_hang** : Aucune base locale ; deux sources web concordantes sur deltoïde antérieur / pectoraux / biceps étirés. Niveau : advanced (Calixpert) vs intermediate (GymnasticBodies).
- **good_morning** : Primaire : hamstrings (FED, wger) ou lower back (FED stiff-leg/seated) ou les trois (Wikipédia). Fessiers : primaires pour Wikipédia, secondaires pour FED.
- **hack_squat** : Fessiers primaires pour StrengthLog, secondaires pour FED et wger.
- **handstand_walk** : Secondaires : triceps (Fitbod, FED) vs abdominaux + dos (WorkoutLabs). Aucune source ne nomme le trapèze.
- **hip_thrust** : ACE (article CE) met ischios, grand adducteur et petits fessiers au rang d'extenseurs de hanche moteurs ; FED et wger les mettent en secondaire ou les omettent.
- **hollow** : Fitness Volt met l'ilio-psoas et le droit fémoral en primaires, StrengthLog en secondaires ; ici secondaires (jambes tendues tenues).
- **hollow_rocks** : BarBend met quadriceps et fléchisseurs de hanche en primaires ; Hevy/StrengthLog en secondaires.
- **hspu** : Triceps : primaire pour wger (907, 282) et Wikipédia, secondaire pour FED. Trapèze : primaire pour wger 282 et Wikipédia (supérieur), absent de FED.
- **hyperextension** : Banc 45° : lower back / érecteurs primaires (FED, Wikipédia), fessiers et ischios secondaires. Reverse hyper : ischios + fessiers primaires (FED, wger 1809), érecteurs primaires pour Wikipédia. Wger 301 (trapèze) non retenu.
- **inchworm** : Niveau : FED beginner vs ACE advanced.
- **iso_dips** : free-exercise-db distingue version triceps (triceps primaire) et version pectoraux (pectoraux primaire) ; calixpert et wger donnent les deux
- **jefferson** : Aucune base locale ni page Wikipédia ; deux sources web concordantes (érecteurs, ischios, fessiers).
- **jumping_jacks** : wger 1669 cite le deltoïde antérieur (seul chef disponible dans wger) alors que le geste est une abduction (deltoïde moyen).
- **kb_snatch** : free-exercise-db : épaules en primaire, hanches en secondaire ; CrossFit : liste non hiérarchisée dominée par fessiers/ischios (swing) ; consensus = hanches + épaules
- **kickback** : Deltoïde postérieur en secondaire : FitCraft et FED (« shoulders », variante penchée) seulement ; wger et FED kickback n'en donnent pas.
- **landmine_press** : Triceps : primaire pour LiftVault, secondaire pour wger et FED (jammer). Aucune source ne met les pectoraux en primaire.
- **landmine_rotation** : Muscle & Strength classe la force en « isometric » (le tronc tient, la rotation vient des hanches) ; StrengthLog/FED décrivent une rotation.
- **leg_curl_machine** : Gastrocnémiens en secondaire : nommés par FED pour la version ballon (« calves ») seulement ; pour la machine, raisonnement anatomique (fléchisseur accessoire du genou). Wikipédia ne les cite pas.
- **leg_curl_sol** : ACE met les fessiers au même rang que les ischios (extension de hanche maintenue) ; FED les met en secondaire.
- **leg_extension** : wger 851 ajoute le biceps fémoral en secondaire (antagoniste, non retenu).
- **lsit** : grand dorsal primaire pour wger et GMB (dépression scapulaire), secondaire/absent pour calixpert et Wikipédia ; triceps secondaire partout (primaire en v1)
- **man_maker** : MuscleFitProgram met tronc/obliques et triceps en primaire, pectoraux/quadriceps/fessiers en secondaire ; Experience Life ne hiérarchise pas (tronc, haut du corps, bas du corps).
- **manna** : une seule fiche avec muscles (calisthenics.com) ; Wikipédia confirme seulement la hiérarchie L-sit < V-sit < manna. calisthenics.com met les fléchisseurs de hanche en stabilisateurs, retenus en primaire par raisonnement (compression extrême)
- **marche** : FED met les quadriceps seuls en primaire ; wger 1104 met tout en primaire (y compris grand dorsal et abdominaux, non retenus comme moteurs).
- **marche_lestee** : Jetti classe trapèzes/deltoïdes/pectoraux en stabilisateurs du haut du corps ; Cleveland Clinic ne détaille pas ; FED Yoke Walk ajoute abducteurs/adducteurs.
- **mobilite_complete** : Archétype composite sans entrée unique : consensus construit sur les composantes usuelles (World's Greatest Stretch, cercles de hanches/bras, cat-cow, inchworm).
- **mobilite_hanches** : Niveau : Cleveland Clinic « aggressive/advanced » vs Healthline intermediate.
- **mobilite_thoracique** : wger 1244 code deltoïde antérieur/grand dorsal en primaires (appui des mains) ; FED : bas du dos. Aucune source nominative pour les multifides.
- **mollets_assis** : wger 1494 et 1620 attribuent le gastrocnémien seul aux mollets assis (contradiction avec wger 590 et Wikipédia) : non retenu.
- **monster_walk** : Hinge Health met tous les fessiers et les adducteurs en primaire ; FED ne cite que les abducteurs ; wger le grand fessier.
- **mountain_climbers** : free-exercise-db met les quadriceps en primaire et ne cite pas les abdominaux ; MuscleWiki met les abdominaux seuls en primaire ; ACE cite fessiers/cuisses/corps entier.
- **muscle_up** : Wikipédia met biceps, triceps et pectoraux en primaire ; free-exercise-db ne garde que les lats en primaire ; wger 423 erroné (biceps fémoral)
- **muscle_up_iso** : aucune fiche 'isométrie de transition' trouvée ; muscles déduits de la transition dynamique (calixpert) et des phases du muscle-up (Wikipédia)
- **nordic** : FED classe le natural GHR en compound, le floor GHR en isolation ; v1 isolation gardée (un seul axe : le genou).
- **oiseau** : wger nomme le deltoïde antérieur en primaire (pas de deltoïde postérieur dans sa taxonomie) : non retenu. Wikipédia classe rhomboïdes et trapèze en stabilisateurs/assistants, FED (poulie) les met en secondaire (« middle back », « traps »).
- **overhead_carry** : Sources faibles (blog Breaking Muscle + entrée FED voisine) ; aucune base n'a d'entrée « overhead carry » avec muscles détaillés. Triceps : par raisonnement (verrouillage du coude), non nommé.
- **pallof** : wger code deltoïde antérieur, grand fessier, dentelé, trapèze en primaires ; FED/StrengthLog : abdominaux/obliques seuls.
- **pec_deck** : FED note la force « pull » (incohérent : c'est une adduction horizontale, classée push ailleurs).
- **pinch** : wger (1430) met le deltoïde antérieur en primaire : erreur manifeste (FED, Muscle & Strength, Breaking Muscle : avant-bras / pince).
- **pistol** : Wger 456 omet les quadriceps et met les ischios en primaire (non retenu). Fessiers : primaires pour ACE, StrengthLog, wger ; secondaires pour FED.
- **pistol_assiste** : Fessiers secondaires pour Fitbod et FED, primaires pour ACE et StrengthLog.
- **pistol_box** : Fessiers secondaires pour FED, primaires pour ACE/StrengthLog.
- **planche_bras_tendus** : wger 1317 met le grand pectoral et le trapèze en primaires ; les autres sources les mettent en secondaires/stabilisateurs.
- **planche_coudes** : Wikipédia classe les érecteurs du rachis en moteurs primaires ; aucune base ne les liste (ici : stabilisateurs). wger 458 liste biceps/triceps en secondaires (appui sur les avant-bras), non retenu.
- **planche_laterale** : wger 580 met le droit de l'abdomen en primaire (les autres : obliques). Wikipédia met moyen/petit fessier et adducteurs en primaires ; ACE en secondaires (glutes). Carré des lombes retenu en primaire par raisonnement anatomique (flexion latérale isométrique du bassin) sans source nominative.
- **planche_rkc** : Fitness Volt liste deltoïdes, érecteurs, fléchisseurs de hanche et pectoraux en primaires ; ici stabilisateurs (isométrie d'appui).
- **planche_skill** : biceps primaire pour Wikipédia, secondaire pour calixpert ; pectoraux secondaires dans 3 sources sur 4 ; dentelé primaire pour wger et calixpert (full), secondaire pour calixpert (tuck)
- **pogo** : Garage Strength ajoute les fessiers ; NIFS ne les cite pas (genoux quasi tendus).
- **poignet_flexion** : wger 51 (deltoïde antérieur, biceps fémoral) est manifestement erroné : non retenu.
- **poignet_rotation** : wger n'a pas d'entrée. FED et ACE ne donnent que « forearms » ; seul Rehab Hero nomme les rotateurs.
- **pompe** : Triceps : primaire pour Wikipédia, secondaire pour FED et wger. Deltoïde antérieur : primaire pour Wikipédia, secondaire pour FED/wger.
- **pompe_archer** : wger (Side to Side) met l'oblique externe et le deltoïde antérieur en primaires ; NASM les met en secondaire/stabilisateurs.
- **pompe_declinee** : Deltoïde antérieur : « accentué » selon Wikipédia mais secondaire dans FED et wger (aucune base ne le met en primaire).
- **pompe_diamant** : wger (386) place le grand pectoral en primaire et le triceps en secondaire ; FED et Wikipédia mettent le triceps en premier.
- **pompe_explosive** : FED classe le Plyo Push-up « beginner » et la version kettlebell « expert » : le niveau dépend du support.
- **pompe_genoux** : wger place le deltoïde antérieur en primaire et le triceps en secondaire ; Wikipédia et FED (pompe standard) mettent le triceps devant.
- **pompe_mur** : wger place triceps et deltoïde antérieur en primaires (à égalité avec le grand pectoral) ; Wikipédia ne détaille pas cette variante.
- **pompe_pike** : Triceps : primaire pour Hinge Health, secondaire pour NASM et wger. wger met le grand pectoral seul en primaire (peu plausible pour une poussée verticale).
- **pompe_pseudo** : Triceps : primaire pour FitCraft, absent de wger. Aucune source ne nomme le biceps en secondaire.
- **pompe_un_bras** : FED note « intermediate » alors que c'est une progression avancée (Wikipédia la range parmi les variantes difficiles).
- **pont_dorsal** : wger ne code aucun primaire ; Wikipédia : bas du dos, fessiers, deltoïdes ; GMB insiste sur l'extension thoracique et l'étirement des fléchisseurs de hanche/épaule.
- **pont_fessier** : Droit de l'abdomen primaire pour wger 1906 seulement ; ACE le classe en gainage. Lombaires citées par aucune base (v1) : conservées en secondaire par raisonnement (extension de hanche + tenue du bassin), une seule source indirecte.
- **prehension** : Aucune base n'a d'entrée « hand gripper » : FED plate squeeze et finger curls pris comme gestes voisins. Gym Mikolo ajoute le brachio-radial (non retenu : ne participe pas au serrage).
- **presse** : Ischios : primaires pour wger 371 et Wikipédia, secondaires pour FED, StrengthLog. Adducteurs : StrengthLog seul en primaire.
- **pull_apart** : Rhomboïdes/trapèze moyen : primaires pour Aerobis, secondaires (« middle back ») pour FED. wger n'a pas renseigné les muscles.
- **pullover** : Ordre pectoraux / grand dorsal : FED straight-arm et wger 1273 mettent le grand pectoral en premier, wger 1488/161 et FED bent-arm le grand dorsal, Wikipédia cite une étude favorable au pectoral pour le pullover barre. FED classe le pullover en compound.
- **push_press** : wger met le trapèze en primaire et le grand fessier en secondaire (entrée peu détaillée) ; FED et Wikipédia mettent les épaules en primaire.
- **relevé_jambes** : Wikipédia met l'ilio-psoas en primaire et le droit de l'abdomen en secondaire ; les bases mettent les abdominaux seuls. Le crunch inversé (bassin décollé) est plus abdominal, le relevé jambes tendues plus fléchisseurs de hanche.
- **rice_bucket** : Aucune base (FED, wger) n'a d'entrée ; deux pages web concordent sur fléchisseurs/extenseurs des doigts et du poignet, sans nommer les muscles individuellement. Rotateurs (pronation/supination) déduits des mouvements décrits (rotations, « swirls »).
- **rotation_externe** : FED (« shoulders ») et wger (« anterior deltoid », « brachialis ») ne savent pas nommer la coiffe : seules les sources anatomiques/web tranchent. Rotation interne (exemple « Rotations internes élastique ») : sous-scapulaire primaire, grand pectoral et grand dorsal secondaires (Bodybuilding-Wizard, Wikipédia).
- **rowing_anneaux** : Biceps : primaire pour wger, secondaire pour FED et Wikipédia. wger liste le deltoïde antérieur (probable erreur, cf. rowing australien).
- **rowing_appui** : Biceps : primaire pour wger, secondaire pour FED/Wikipédia.
- **rowing_australien** : Biceps : primaire pour wger (1219, 1198), secondaire pour FED et Wikipédia. wger 1219 liste le deltoïde antérieur en primaire (probable erreur de saisie : le deltoïde postérieur est le chef sollicité).
- **rowing_barre** : FED met « middle back » (rhomboïdes/trapèze moyen) en primaire et les lats en secondaire ; wger et Wikipédia mettent le grand dorsal en primaire. wger 83 liste le deltoïde antérieur en secondaire (probable erreur : postérieur).
- **rowing_halteres** : FED : « middle back » primaire, lats secondaire ; wger/Wikipédia : grand dorsal primaire.
- **russian_twist** : wger 1193 met le grand dorsal en primaire (bras qui balaient avec charge) ; non repris par les autres.
- **sandbag_carry** : Une seule source directe (FitMetrics) ; FED décrit le chargement (Sandbag Load) et Breaking Muscle ne donne que des stabilisateurs. FitMetrics met jambes et abdominaux en primaire, trapèzes et avant-bras en secondaire : inverse de la v1.
- **saut** : FED Knee Tuck Jump met les ischios en primaire (isolé) ; MuscleWiki met fessiers en primaire et quadriceps en secondaire ; wger/FED Long Jump l'inverse.
- **scap_pull** : free-exercise-db : traps primaire / lats secondaire ; wger, calixpert : les deux primaires ; Rehab Hero précise trapèze inférieur + dentelé
- **scapular_pushup** : Aucune base (FED, wger) n'a d'entrée pour la pompe scapulaire (le « Scapular Pull-Up » FED est un autre geste). Physiopedia cite le trapèze supérieur comme muscle activé (à minimiser selon l'EMG rapportée), non retenu.
- **sdt** : Muscle primaire : lower back (FED conventionnel), hamstrings (FED sumo), quadriceps (FED trap bar), gluteus maximus (Wikipédia, wger 484), glutes + hamstrings (ACE), latissimus dorsi (wger 184, erreur). Quadriceps : secondaire partout sauf trap bar.
- **sdt_roumain** : Fessiers : primaires pour wger 1652/1750 et Wikipédia, secondaires pour FED et wger 627. Wger 1700 (grand dorsal) non retenu.
- **sdt_unijambe** : Ischios seuls (wger 1211), fessiers seuls (wger 1641, ACE) ou les deux (FED, wger 1736) en primaire.
- **shrimp_squat** : FitnessVolt met ischios, abducteurs, mollets et core en primaire ; dieringe ne retient que quadriceps et fessiers.
- **shrug** : wger 571/572/575 attribuent le deltoïde antérieur aux shrugs barre/haltères/multipress : erreur manifeste, non retenue.
- **sissy_squat** : Fessiers et ischios : secondaires pour FED, isométriques (stabilisateurs) pour Garage Gym Reviews.
- **situp** : Toutes les sources ne codent que les abdominaux (+ obliques) ; l'ilio-psoas primaire (v1) repose sur le raisonnement anatomique, pas sur une source nominative.
- **skater_squat** : Ischios primaires pour Inspire US, absents pour dieringe.
- **skaters** : FED Lateral Bound met les adducteurs en primaire (freinage latéral) là où ACE et wger ciblent fessiers/cuisses/mollets ; MuscleWiki (variante) met les mollets en primaire.
- **skin_the_cat** : une seule fiche avec muscles (calixpert) ; Gymless le cite comme étape 1 du front lever, Wikipédia (back lever) comme position de départ (suspension inversée), sans muscles
- **slam** : FED Overhead Slam ne cite que les lats ; MuscleWiki ne cite que les abdominaux hauts ; wger réunit les deux.
- **sled_pull** : Le grand dorsal n'est primaire que sur le tirage à la corde (FED Sled Row : dos moyen primaire, lats secondaire) ; sur le drag arrière au harnais, quadriceps seuls en primaire (FED, Muscle & Strength, Fitbod).
- **sled_push** : FED Prowler Sprint met les ischios en primaire ; FED Sled Push et wger s'accordent sur quadriceps (+ fessiers, mollets chez wger).
- **snatch** : free-exercise-db : quadriceps (snatch) ou ischios (power/hang) en primaire, épaules secondaires ; wger : deltoïde antérieur + jambes en primaire ; StrengthLevel : jambes, dos, épaules, core
- **sprint** : FED : quadriceps primaires, fessiers/ischios secondaires ; Nike et Contreras : fessiers et ischios dominants, quadriceps au freinage. FED Wind Sprints (abdominaux) non retenu.
- **squat_assiste** : Fessiers en secondaire pour Fitbod, en primaire pour ACE (squat libre).
- **squat_barre** : Grand fessier : primaire pour wger 1801/1627, Wikipédia, ACE ; secondaire pour FED et wger 615. Ischios : primaire pour wger 1801/1627 et ACE, secondaire pour FED. Wger 1627 omet les quadriceps (erreur manifeste, non retenue).
- **squat_chaise** : Grand fessier primaire pour wger 977 et ACE, secondaire pour FED. Soléaire primaire pour wger 977, « calves » secondaire pour FED.
- **squat_cosaque** : Fléchisseurs de hanche en primaire pour StrengthLog seulement. Adducteurs : cibles pour Healthline et ACE, secondaires pour StrengthLog, absents pour wger.
- **squat_gobelet** : « Shoulders » en secondaire pour FED (tenue de la charge) ; non repris par les autres : classé stabilisateur.
- **squat_overhead** : Épaules : secondaires pour FED, « travaillent très dur » (stabilisation) pour Bosse, absentes pour StrengthLog (trapèze secondaire) : classées stabilisatrices. Lower back : primaire pour StrengthLog, secondaire pour FED.
- **squat_pdc** : Grand fessier : primaire pour wger 1315, Wikipédia et ACE ; secondaire pour FED et wger 1312. Ischios : secondaires pour FED/ACE, absents des autres. Grand adducteur : primaire pour Wikipédia seulement.
- **squat_profond_tenu** : Aucune base ne code le squat profond tenu ; wger Wall-sit et FED Groin stretch servent d'analogues partiels.
- **squat_saute** : Grand fessier primaire pour ACE, secondaire pour FED, absent pour wger.
- **step_up** : Fessiers primaires pour ACE, StrengthLog et FED Knee Raise ; secondaires pour FED haltères/barre. Adducteurs : StrengthLog seul.
- **straight_arm_pulldown** : SET FOR SET classe trapèze/rhomboïdes en secondaires ; ici en stabilisateurs (bras tendus, omoplates fixées).
- **suitcase_carry** : Préhension : primaire pour la v1, secondaire pour Bodybuilding-Wizard ; ACE ne détaille pas (« Full Body »).
- **superman** : wger 636 met le grand dorsal en primaire (bras levés) ; FED/ACE : bas du dos + fessiers. Ischios : FED secondaire, wger 1910 primaire.
- **support_hold** : dieringe (anneaux) place les pectoraux en primaire, calixpert (barres) en secondaire
- **suspension_genoux** : Wikipédia : ilio-psoas primaire, abdominaux secondaires ; wger/FED : abdominaux seuls.
- **suspension_jambes** : Wikipédia : ilio-psoas primaire ; bases : abdominaux. Retenus tous deux en primaires (jambes tendues = fort bras de levier de hanche).
- **swing** : Primaire : hamstrings (FED) vs glutes (wger, StrengthLog, Wikipédia). Lower back : primaire pour StrengthLog, secondaire pour FED. Deltoïde antérieur primaire pour wger 960 (non retenu : bras passifs selon ACE/Wikipédia).
- **thruster** : Hiérarchie haut/bas : FED et wger 650 mettent les épaules en primaire ; wger 1684 et MuscleWiki mettent fessiers/quadriceps en primaire. Tous citent les deux groupes.
- **tibial** : Aucune base n'a d'entrée renseignée (FED : seulement un auto-massage du tibial ; wger 1200 vide).
- **tirage_horizontal_poulie** : FED : « middle back » primaire ; wger : grand dorsal primaire. wger 1621 ajoute le dentelé antérieur (version unilatérale, protraction en fin d'amplitude).
- **tirage_menton** : wger nomme le deltoïde antérieur, Wikipédia 'deltoids' sans chef, StrengthLevel 'shoulders' ; free-exercise-db met les trapèzes seuls en primaire
- **tirage_vertical_poulie** : biceps primaire en v1 ; toutes les bases le donnent secondaire (primaire seulement en supination, wger 684)
- **toes_to_bar** : Grand dorsal : primaire pour Fitness Volt, secondaire pour BarBend → retenu secondaire (il ramène les hanches vers la barre, surtout en kipping).
- **traction** : Wikipédia et ACE placent le trapèze en primaire, free-exercise-db et wger en secondaire ; wger liste le deltoïde antérieur (atypique, non retenu)
- **traction_assistee** : free-exercise-db ne liste pas le biceps pour la version élastique ; wger et Wikipédia le donnent
- **traction_kipping** : Hevy liste 7 muscles primaires (dont érecteurs, infra-épineux) ; Wikipédia indique une activation du haut du corps réduite au profit des jambes et du gainage
- **traction_l** : wger 1741 'L-Sit Pull-ups' n'a aucun muscle renseigné : consensus construit en combinant tenue L suspendue (calixpert) et traction
- **traction_poitrine** : aucune source ne place les rhomboïdes en primaire (v1) ; ils restent secondaires avec le trapèze moyen
- **traction_un_bras** : free-exercise-db place 'middle back' en primaire et lats en secondaire ; GorNation : lats et biceps primaires
- **turkish** : free-exercise-db : épaules seules en primaire ; wger/Physiopedia/Hevy ajoutent abdominaux (obliques) et fessiers en primaire ; niveau intermediate (free-exercise-db) vs advanced (Physiopedia, Hevy)
- **v_ups** : Fitness Volt met les fléchisseurs de hanche en primaires ; Weight Training Guide/Hevy en synergistes. Niveau : FED beginner (jackknife) vs Hevy/WTG advanced.
- **vsit** : dieringe ne liste pas les fléchisseurs de hanche (met triceps et deltoïde antérieur en primaire) ; GMB (progression L-sit → V-sit) les donne primaires
- **wall_ball** : MuscleWiki ne retient que les quadriceps ; wger ajoute fessiers + deltoïde antérieur en primaire. Triceps non cités par les sources (ajout par raisonnement : extension des coudes au lancer).
- **wall_sit** : Ischios primaires pour wger 718, secondaires pour Wikipédia ; grand fessier primaire pour wger 1733, secondaire pour Wikipédia.
- **wall_slides** : wger 716 code biceps fémoral et triceps : implausible, rejeté. JOSPT (jospt.org) inaccessible (403) ; lu via la synthèse Brookbush.
- **wall_walk** : niveau : StrengthLog advanced, calixpert beginner
- **windmill** : FED : abdominaux seuls en primaire ; BarBend/Fitness Volt : épaule (coiffe/deltoïdes) et chaîne postérieure en primaires. Carré des lombes : Fitness Volt secondaire, ici primaire (inclinaison sous charge).
- **windshield** : StrengthLog et MuscleWiki décrivent la version allongée au sol ; seule wger 1743 code la version à la barre (mêmes abdominaux).
- **woodchop** : wger 1433 (variante bas→haut) met grand fessier et grand dorsal en primaires ; pour le woodchop haut→bas ils restent secondaires.
- **ytw** : wger 1885 attribue le deltoïde antérieur (erreur de taxonomie) : non retenu. Aucune base n'a d'entrée exacte ; FED lying rear delt raise pris comme geste voisin.

### 0.3 Découpage en chefs par raisonnement anatomique

Les sources nomment le muscle ; le découpage en chefs ou faisceaux (utile à l'atlas) est un raisonnement anatomique de Claude, appliqué uniformément :

- `pectoraux` → grand pectoral : chef sterno-costal + chef claviculaire (le chef abdominal n'est ajouté que pour les dips et le développé décliné)
- `triceps` → triceps : chef long + chef latéral + chef médial
- `quadriceps` → quadriceps : droit fémoral + vaste latéral + vaste médial + vaste intermédiaire
- `ischios` → ischio-jambiers : biceps fémoral (chef long et chef court) + semi-tendineux + semi-membraneux
- `deltoides` → deltoïde : faisceaux antérieur, moyen, postérieur
- `trapezes` → trapèze : faisceaux supérieur, moyen, inférieur
- `erecteurs` → érecteurs du rachis : lombaires + thoraciques
- `obliques` → obliques : externe + interne
- `adducteurs` → adducteurs : long, court, grand, gracile, pectiné
- `mollets` → triceps sural : gastrocnémien médial + latéral + soléaire
- `biceps` → biceps brachial : chef long + chef court
- `prehension` → préhension : fléchisseurs superficiels et profonds des doigts, muscles intrinsèques de la main
- `coiffe` → coiffe des rotateurs : supra-épineux, infra-épineux, petit rond, sub-scapulaire
- `flechisseurs_hanche` → fléchisseurs de hanche : grand psoas + iliaque (+ droit fémoral)

### 0.4 Stabilisateurs déduits par raisonnement

85 archétypes sur 237 ont des stabilisateurs déduits (aucune source ne les listait) : `adducteurs_machine`, `battle_rope`, `box_jump`, `burpee`, `clean`, `clean_press`, `corde_a_sauter`, `crunch`, `crunch_poulie`, `curl_barre`, `curl_poulie`, `curl_pupitre`, `dead_bug`, `depth_jump`, `developpe_halteres`, `devil_press`, `dips_anneaux`, `dips_banc`, `dips_banc_genoux`, `dips_barre_fixe`, `elevation_frontale`, `ergo_velo`, `etirement_flechisseurs`, `etirement_posterieur`, `extension_doigts`, `false_grip`, `farmer`, `farmer_hold`, `fente_bulgare`, `fente_sautee`, `floor_press`, `flutter`, `foam`, `genoux_hauts`, `german_hang`, `hack_squat`, `hip_thrust`, `hollow_groupe`, `hspu`, `hyperextension`, `jumping_jacks`, `kb_snatch`, `leg_curl_machine`, `leg_extension`, `mobilite_complete`, `mollets_assis`, `monster_walk`, `mountain_climbers`, `muscle_up_iso`, `pistol_assiste`, `pistol_box`, `planche_genoux`, `pogo`, `poignet_flexion`, `poignet_rotation`, `presse`, `pull_apart`, `pullover`, `respiration`, `rice_bucket`, `rowing_appui`, `saut`, `sdt_roumain`, `side_bend`, `situp`, `skaters`, `slam`, `sled_pull`, `sled_push`, `snatch`, `squat_assiste`, `squat_chaise`, `squat_saute`, `step_up`, `suspension_genoux`, `thruster`, `tirage_horizontal_poulie`, `tirage_menton`, `tirage_vertical_poulie`, `traction_anneaux`, `traction_archer`, `traction_un_bras`, `wall_ball`, `wall_walk`, `windshield`.

### 0.5 Surcharges par exercice

Exercices dont les muscles diffèrent de leur archétype (variante de prise, d'angle ou de cible) :

- Bicycle crunchs (`bicycle-crunchs`, archétype `crunch`) : primaires = droit_abdomen, oblique_externe, oblique_interne
- Curl poignet (`curl-poignet`, archétype `poignet_flexion`) : primaires = flechisseurs_du_poignet
- Curl pronation (reverse curl) (`curl-pronation-reverse-curl`, archétype `curl_barre`) : primaires = brachio_radial, brachial, extenseurs_du_poignet
- Curl Zottman (`curl-zottman`, archétype `curl`) : primaires = biceps_chef_long, biceps_chef_court, brachial, brachio_radial
- Développé couché prise serrée (`developpe-couche-prise-serree`, archétype `developpe_couche`) : primaires = triceps_chef_long, triceps_chef_lateral, triceps_chef_medial, grand_pectoral_sterno_costal
- Dips bulgares (prise large) (`dips-bulgares-prise-large`, archétype `dips_barres`) : primaires = grand_pectoral_sterno_costal, grand_pectoral_abdominal, triceps_chef_long, triceps_chef_lateral, triceps_chef_medial
- Extension poignet (`extension-poignet`, archétype `poignet_flexion`) : primaires = extenseurs_du_poignet
- Extension poignet barre (`extension-poignet-barre`, archétype `poignet_flexion`) : primaires = extenseurs_du_poignet
- Face pulls aux anneaux (`face-pulls-aux-anneaux`, archétype `rowing_anneaux`) : primaires = deltoide_posterieur
- Pompes hindu (`pompes-hindu`, archétype `pompe`) : primaires = grand_pectoral_sterno_costal, grand_pectoral_claviculaire, deltoide_anterieur, triceps_chef_long, triceps_chef_lateral, triceps_chef_medial
- Pompes spiderman (`pompes-spiderman`, archétype `pompe`) : primaires = grand_pectoral_sterno_costal, grand_pectoral_claviculaire, triceps_chef_long, triceps_chef_lateral, triceps_chef_medial
- Rack pulls (`rack-pulls`, archétype `sdt`) : primaires = erecteurs_lombaires, grand_fessier, trapeze_superieur, trapeze_moyen, trapeze_inferieur
- Reverse hyper (`reverse-hyper`, archétype `hyperextension`) : primaires = grand_fessier, biceps_femoral, biceps_femoral_chef_court, semi_tendineux, semi_membraneux
- Rotations internes élastique (`rotations-internes-elastique`, archétype `rotation_externe`) : primaires = sous_scapulaire
- Sled drag arrière (`sled-drag-arriere`, archétype `sled_pull`) : primaires = droit_femoral, vaste_lateral, vaste_medial, vaste_intermediaire
- Soulevé de terre sumo (`souleve-de-terre-sumo`, archétype `sdt`) : primaires = grand_fessier, droit_femoral, vaste_lateral, vaste_medial, vaste_intermediaire, long_adducteur, court_adducteur, grand_adducteur, gracile, pectine
- Soulevé de terre trap bar (`souleve-de-terre-trap-bar`, archétype `sdt`) : primaires = droit_femoral, vaste_lateral, vaste_medial, vaste_intermediaire, grand_fessier, biceps_femoral, biceps_femoral_chef_court, semi_tendineux, semi_membraneux
- Traction à la serviette (`traction-a-la-serviette`, archétype `traction`) : primaires = grand_dorsal, biceps_chef_long, biceps_chef_court, flechisseurs_superficiels_des_doigts, flechisseurs_profonds_des_doigts, flechisseurs_du_poignet, muscles_intrinseques_main
- Traction supination (`traction-supination`, archétype `traction`) : primaires = grand_dorsal, biceps_chef_long, biceps_chef_court
- Travail poignet excentrique (haltère) (`travail-poignet-excentrique-haltere`, archétype `poignet_flexion`) : primaires = flechisseurs_du_poignet, extenseurs_du_poignet
- Superman W (`superman-w`, archétype `superman`) : primaires = deltoide_posterieur, rhomboides, trapeze_moyen, trapeze_inferieur
- Planche latérale avec abduction de jambe (`planche-laterale-avec-abduction-de-jambe`, archétype `planche_laterale`) : primaires = oblique_externe, oblique_interne, carre_des_lombes, moyen_fessier
- Pancake à plat (poitrine au sol) (`pancake-a-plat-poitrine-au-sol`, archétype `mobilite_hanches`) : primaires = long_adducteur, court_adducteur, grand_adducteur, gracile, pectine, biceps_femoral, biceps_femoral_chef_court, semi_tendineux, semi_membraneux
- Pancake assis (écart facial) (`pancake-assis-ecart-facial`, archétype `mobilite_hanches`) : primaires = long_adducteur, court_adducteur, grand_adducteur, gracile, pectine, biceps_femoral, biceps_femoral_chef_court, semi_tendineux, semi_membraneux

### 0.6 Erreurs de la v1 corrigées par les sources

- **ab_wheel** : Le triceps (v1 secondaire) n'est listé par aucune source : rétrogradé en stabilisateur (coude verrouillé). Le deltoïde antérieur (FED « shoulders », MusclesWorked) manquait.
- **abducteurs** : Tenseur du fascia lata manquant (Nishaana, PureGym) ; « fessiers » → petit fessier + fibres supérieures du grand fessier (FED glutes).
- **atr** : triceps classés secondaires en v1 ; primaires pour Kovo et calixpert (verrouillage du coude). Deltoïde moyen absent de la v1
- **barre_front** : v1_sec vide : pour JM press et Tate press, deux bases donnent pectoraux et deltoïde antérieur en secondaire. Chef long accentué quand la barre descend derrière la tête ou sur banc incliné (Wikipédia).
- **battle_rope** : Avant-bras en primaire : FED les met en secondaire (préhension) ; abdominaux en secondaire alors que wger les met en primaire ; grand dorsal, trapèzes et pectoraux absents.
- **bird_dog** : ERREUR v1 : deltoïde postérieur en secondaire ; le bras monte devant (flexion d'épaule) : deltoïde antérieur (wger 1572, wger 957) + dentelé antérieur. Ischios (extension de hanche) et moyen fessier (bassin) manquaient.
- **box_squat** : Adducteurs (FED, StrengthLog, Wikipédia) et mollets (FED, StrengthLog) manquaient en secondaire.
- **burpee** : Abdominaux seulement en secondaire (primaire chez MuscleWiki) ; mollets et fléchisseurs de hanche (saut, retour en squat) absents.
- **cercles_bras** : v1 « deltoide_lateral » → deltoide_moyen ; « coiffe_rotateurs » → coiffe. Cohérent sinon.
- **charniere_baton** : v1 confirmée (ischios, fessiers ; lombaires).
- **clamshell** : Rotateurs latéraux de la hanche (piriforme, obturateurs, jumeaux) manquants ; petit fessier en primaire ; « fessiers » → grand fessier (rotation externe) en secondaire.
- **clean** : trapezes classés primaires en v1 ; secondaires dans free-exercise-db et wger (le shrug du 2e tirage est bref)
- **copenhague** : v1 cohérente (adducteurs, obliques ; transverse, moyen fessier). Préciser : long adducteur = chef le plus sollicité.
- **corde_a_sauter** : Deltoïde latéral et avant-bras en secondaire : aucune source ne les cite ; ils tiennent la rotation de la corde (poignets) et passent en stabilisateurs par raisonnement.
- **course** : v1 confirmée. Tibial antérieur (dorsiflexion pendant l'oscillation, raisonnement) ajouté en secondaire ; stabilisateurs de bassin/cheville (Nike « glutes stabilize the pelvis », core) ajoutés.
- **crab_walk** : Quadriceps (les deux sources) et moyen fessier manquaient en secondaire. Deltoïde : v1 antérieur en secondaire ; la position bras derrière le tronc suggère le chef postérieur en moteur (raisonnement, non tranché par les sources).
- **crawl** : Dentelé antérieur, pectoraux, oblique externe, mollets (wger 57) et fessiers (wger, ACE) manquaient en secondaire. Fléchisseurs de hanche (montée des genoux) gardés en secondaire par raisonnement (aucune source ne les nomme).
- **crunch** : v1 cohérente. Bicycle crunch : obliques passent en primaires (ACE 241, wger 1412).
- **cuban_press** : « coiffe_rotateurs » → infra-épineux + petit rond (phase de rotation externe) ; deltoïde antérieur et triceps (phase développé) manquants ; « trapezes » → trapèze supérieur.
- **curl** : Brachial manquant en primaire (Wikipédia, wger). « avant_bras » → brachio-radial + fléchisseurs du poignet ; Zottman : la descente en pronation charge brachio-radial et extenseurs du poignet.
- **curl_barre** : Brachial manquant en primaire. Pour l'exemple « Curl pronation (reverse curl) », le brachio-radial et le brachial deviennent primaires, le biceps secondaire, avec extenseurs du poignet en secondaire (Wikipédia, StrengthLog).
- **curl_marteau** : Brachial manquant ; « avant_bras » → brachio-radial précisément ; le biceps passe derrière brachio-radial et brachial en prise neutre (Wikipédia).
- **curl_poulie** : Brachial manquant en primaire (wger 1109, Wikipédia).
- **curl_pupitre** : Brachial manquant en primaire (wger 465, Wikipédia).
- **dead_bug** : v1 cohérente ; obliques (NASM) ajoutés en secondaires. Les fléchisseurs de hanche ne sont listés par aucune source : maintenus en secondaires par raisonnement.
- **dead_hang** : grand_dorsal en primaire v1 : en suspension passive il est surtout étiré (FitCraft) ; retenu en secondaire
- **developpe_assis** : Triceps en primaire non confirmé (secondaire).
- **developpe_couche** : Triceps en primaire non confirmé pour la prise médiane (secondaire dans les bases) ; il devient primaire en prise serrée. Ancône et petit pectoral (Wikipédia) manquaient.
- **developpe_couche_halteres** : Coiffe des rotateurs en secondaire : c'est un stabilisateur (Wikipédia). Triceps primaire non confirmé par les bases.
- **developpe_halteres** : Triceps en primaire non confirmé (secondaire). Trapèzes : trapèze supérieur secondaire (raisonnement), pas les trois chefs.
- **developpe_incline** : Deltoïde antérieur en primaire non confirmé par les bases (secondaire). Le chef claviculaire du grand pectoral doit être nommé explicitement.
- **developpe_militaire** : Triceps en primaire non confirmé (secondaire, FED). Trapèzes et abdominaux : le trapèze supérieur (rotation de l'omoplate) reste secondaire ; les abdominaux sont des stabilisateurs (Wikipédia : version debout = plus de stabilisation).
- **devil_press** : Grand dorsal, abdominaux/obliques et érecteurs (swing) absents alors que wger et BarBend les citent.
- **dips_anneaux** : Coiffe des rotateurs et abdominaux étaient en secondaire : ce sont des stabilisateurs (instabilité des anneaux). Pectoraux primaires non confirmés par les bases (secondaires).
- **dislocations** : v1 « coiffe_rotateurs » → alias coiffe ; deltoïde antérieur/pectoraux sont étirés (pas moteurs) ; la coiffe et les trapèzes travaillent activement. Grand dorsal étiré manquait.
- **dragon_flag** : v1 cohérente (abdominaux, transverse ; grand dorsal, fléchisseurs de hanche) ; manquaient grand fessier (wger : extension de hanche pour garder le corps droit), triceps/deltoïde et préhension sur le banc.
- **elevation_frontale** : Chef claviculaire du grand pectoral manquant (Wikipédia). Deltoïde moyen et dentelé antérieur de la v1 ne sont nommés par aucune source pour ce geste : gardés en secondaire par raisonnement (élévation dans le plan sagittal, rotation haute de l'omoplate) ; trapèze supérieur ajouté (wger 254).
- **elevation_laterale** : « trapezes » trop large : seul le trapèze supérieur (rotation haute de l'omoplate, Wikipédia) ; supra-épineux manquant (Wikipédia coiffe : amorce l'abduction) ; dentelé antérieur (Wikipédia) absent de la v1.
- **ergo_rameur** : Ischios seulement en secondaire (primaire chez wger, cités au drive et au finish par Concept2) ; trapèzes/rhomboïdes (middle back FED), mollets et abdominaux absents.
- **ergo_ski** : Trapèzes (primaire chez wger et Concept2) et mollets absents ; abdominaux confirmés en primaire.
- **etirement_flechisseurs** : v1 cohérente (fléchisseurs de hanche, quadriceps) ; la taxonomie permet de nommer ilio-psoas + droit fémoral + TFL/sartorius/pectiné.
- **etirement_posterieur** : v1 cohérente (ischios, mollets, lombaires). Ajouter soléaire (genou plié) et grand fessier en étirés secondaires.
- **face_pull** : Coiffe des rotateurs en primaire non confirmée : secondaire (PureGym), absente des autres sources ; retenue en secondaire (infra-épineux, petit rond : rotation externe en fin de mouvement).
- **farmer** : Aucune erreur ; le transverse (v1) fait partie des « abdominals » de FED ; ajouter érecteurs et ischios (FED, secondaires).
- **fente** : Adducteurs en secondaire : aucune source ne les nomme pour la fente avant/arrière → stabilisateurs du bassin (raisonnement). Moyen fessier (ACE glute activation lunges, unilatéral) manquait.
- **fente_bulgare** : Moyen fessier (« abductors » FED Suspended) et mollets (FED) manquaient en secondaire.
- **fente_laterale** : Adducteurs en primaire : une seule source (ACE) les cite, sans hiérarchie → secondaires. Moyen fessier (ACE) et mollets (wger, FED) manquaient.
- **fente_sautee** : Ischios (FED, Wikipédia) manquaient en secondaire.
- **floor_press** : Ordre : le triceps devrait être cité en premier (FED), la v1 met les pectoraux d'abord.
- **flutter** : v1 sans secondaires : ajouter obliques (wger 235) et transverse.
- **foam** : v1 cohérente (quadriceps, ischios, mollets = régions roulées). Ajouter fessiers, TFL/bandelette, adducteurs, dorsal, haut du dos comme régions secondaires.
- **front_squat** : Lombaires en secondaire : les sources les donnent en stabilisation isométrique (Wikipédia) ; les érecteurs thoraciques (dos droit sous barre avant, Wikipédia « haut du dos ») manquaient. Ischios et mollets (FED, wger 1361) manquaient.
- **genoux_hauts** : Rien de faux ; ischios et fessiers (wger, FED) manquaient en secondaire. Les fléchisseurs de hanche ne sont nommés par aucune base (absents des vocabulaires wger/FED) : maintenus par raisonnement (flexion de hanche = geste principal).
- **german_hang** : v1 « prim » = muscles ÉTIRÉS (deltoïde antérieur, pectoraux, biceps) : correct comme étirés ; préciser biceps chef long + coraco-brachial. Aucun secondaire en v1 : ajouter préhension et coiffe (actifs).
- **good_morning** : Fessiers en secondaire : Wikipédia les classe moteurs (extension de hanche) avec FED en secondaire → remontés en primaire (2 sources concordantes sur leur rôle moteur). Abdominaux (FED) manquaient en secondaire.
- **hack_squat** : Ischios (FED, wger) et mollets (FED, wger, StrengthLog) manquaient en secondaire.
- **handstand_walk** : Trapèzes en primaire : aucune source ne les cite (les quatre donnent « shoulders »/deltoïde antérieur) → trapèze supérieur et dentelé en secondaire par raisonnement (élévation/rotation de l'omoplate). « Avant-bras » précisé en muscles du poignet et de la main (stabilisation de l'équilibre).
- **hip_thrust** : v1 confirmée (fessiers ; ischios, quadriceps via wger 1234). Grand adducteur (ACE) et moyen fessier (ACE, unilatéral) manquaient en secondaire.
- **hollow_groupe** : Régression du hollow : genoux repliés, le bras de levier des jambes diminue, les fléchisseurs de hanche passent de secondaires à mineurs. v1 cohérente.
- **hspu** : Grand pectoral (chef claviculaire) manquait : nommé par wger 907 et Wikipédia. Dentelé antérieur : par raisonnement (rotation haute de l'omoplate), non nommé par les sources.
- **hyperextension** : v1 (trois primaires) reflète la fusion de deux gestes : l'archétype mêle hyperextension 45° (érecteurs dominants) et reverse hyper (fessiers/ischios dominants). « Middle back » (FED ball) et multifides ajoutés en secondaire.
- **inchworm** : v1 cohérente (ischios étirés ; abdominaux et deltoïde antérieur actifs). Le walkout depuis la planche ajoute triceps/pectoraux.
- **jefferson** : Matériel v1 « aucun » incohérent avec charge « barre » : le Jefferson curl se fait avec barre légère ou haltère, debout sur un box/step. Muscles v1 (lombaires, ischios) confirmés ; ajouter érecteurs thoraciques (flexion vertèbre par vertèbre) et fessiers.
- **jumping_jacks** : Quadriceps en secondaire alors que les trois entrées wger et FED les mettent en primaire ; deltoïde en primaire alors que toutes les sources le mettent en secondaire ; fessiers/abdominaux absents.
- **landmine_press** : Pectoraux en primaire non confirmés (secondaires dans les 2 sources directes, chef claviculaire). Triceps : secondaire (wger). Dentelé antérieur confirmé (LiftVault).
- **landmine_rotation** : Type : rotation dynamique (bras tendus qui balaient un arc) — même remarque que le woodchop.
- **leg_curl_machine** : « mollets » → seulement les gastrocnémiens (le soléaire ne croise pas le genou). Gracile, sartorius, poplité (fléchisseurs accessoires du genou) ajoutés par raisonnement.
- **lsit** : triceps classés primaires en v1 ; secondaires dans wger, calixpert et GMB. Grand dorsal (dépression scapulaire) absent de la v1
- **lsit_tuck** : triceps classés primaires en v1 ; secondaires dans wger et calixpert
- **lsit_une_jambe** : triceps classés primaires en v1 ; secondaires dans calixpert et GMB
- **man_maker** : Triceps en secondaire (primaire chez MuscleFitProgram, extension au press) ; biceps, rhomboïdes/trapèzes (renegade row) et préhension absents.
- **manna** : pectoraux (secondaire v1) non cités par la source ; deltoïde postérieur confirmé
- **marche** : Fléchisseurs de hanche (Wikipédia, phase oscillante) et tibial antérieur (attaque du talon, raisonnement) manquaient en secondaire.
- **marche_lestee** : Trapèzes en primaire : Jetti les classe stabilisateurs (portage du sac), aucune source ne les rend moteurs → stabilisateurs. Ischios (Jetti, FED) manquaient en secondaire.
- **mobilite_chevilles** : v1 cohérente (mollets ; tibial antérieur). Préciser : genou au mur = genou fléchi → soléaire principalement.
- **mobilite_complete** : v1 « deltoide_anterieur » seul pour l'épaule : les cercles/dislocations mobilisent les trois chefs + coiffe. Les fléchisseurs de hanche et adducteurs (WGS, cercles de hanche) manquaient.
- **mobilite_hanches** : v1 cohérente (fessiers, adducteurs, fléchisseurs de hanche) ; préciser les rotateurs latéraux (piriforme) et les abducteurs, tous étirés ; en version active (switches) rotateurs et moyen fessier travaillent.
- **mobilite_poignets** : v1 « avant_bras » (groupe) → distinguer fléchisseurs (étirés en appui paume au sol) et extenseurs du poignet (actifs dans les wrist push-ups). L'exemple « Mobilité épaules + poignets » ajoute deltoïdes/coiffe.
- **mobilite_thoracique** : v1 « lombaires » en primaire : la cible est le rachis THORACIQUE (érecteurs thoraciques, rotation) ; les obliques (v1) sont confirmés (rotations en quadrupédie). Trapèzes : secondaires (FED).
- **mollets_assis** : « mollets » indifférencié : genou fléchi → soléaire primaire, gastrocnémiens secondaires (Wikipédia, wger 590).
- **monster_walk** : Petit fessier (abducteur, Hinge Health) et tenseur du fascia lata (alias abducteurs) manquaient. Sinon v1 confirmée (moyen fessier ; grand fessier, quadriceps).
- **mountain_climbers** : Quadriceps relégués en secondaire alors que FED (primaire) et ACE (cuisses) les placent en cible ; pectoraux (FED, catégorie wger) et fessiers (ACE) absents.
- **oiseau** : Rhomboïdes en primaire non confirmés : Wikipédia les classe stabilisateurs/assistants, aucune base ne les met en primaire → secondaires. « coiffe_rotateurs » → préciser infra-épineux + petit rond (rotation externe). Trapèze : parties moyenne et inférieure, pas supérieure.
- **overhead_carry** : Transverse en primaire : les sources parlent de « core » sans distinguer ; retenu en secondaire. Triceps : non confirmé (raisonnement).
- **pallof** : v1 sans membres supérieurs : ajouter deltoïde antérieur, dentelé, pectoraux, triceps (bras qui pressent devant) en secondaires.
- **pinch** : Aucune erreur ; « avant_bras » → préciser fléchisseurs des doigts et muscles intrinsèques de la main (pouce en opposition). Version carry : trapèzes, gainage en stabilisateurs (Muscle & Strength).
- **pistol** : Abdominaux et fléchisseurs de hanche en secondaire : aucune source ne les classe moteurs ; fléchisseurs de hanche (tenue de la jambe libre) et gainage passent en stabilisateurs. Moyen fessier (ACE) manquait.
- **pistol_assiste** : Abdominaux en secondaire non confirmés (stabilisateurs). Ischios, mollets, moyen fessier manquaient.
- **pistol_box** : Abdominaux en secondaire non confirmés (stabilisateurs). Ischios (FED, ACE), moyen fessier et mollets (ACE) manquaient.
- **planche_bras_tendus** : Manquaient en v1 : triceps (bras tendus, wger 1406/458), grand fessier (wger 1091/1410) et obliques ; pour les variantes unilatérales (taps, bras/jambe opposés) le moyen fessier stabilise le bassin.
- **planche_coudes** : Les obliques (wger 458, wger 1307, Wikipédia) et les quadriceps (wger ×2, Wikipédia) manquaient en v1 ; « transverse » n'est confirmé que par Wikipédia (les bases ne le codent pas).
- **planche_genoux** : Aucune entrée dédiée à la planche sur les genoux dans les bases ; attribution v1 cohérente. Quadriceps et gastrocnémiens (secondaires de la planche complète) ne travaillent plus, genoux au sol.
- **planche_laterale** : Manquaient en v1 : adducteurs (Wikipédia primaire) et carré des lombes. Variante avec abduction de jambe : moyen fessier passe en primaire.
- **planche_rkc** : Le grand fessier est secondaire fort (contraction volontaire maximale, EMG Contreras) : la v1 le mettait en secondaire, cohérent ; manquaient obliques (EMG ×2–3) et grand dorsal (traction des coudes vers les pieds).
- **planche_skill** : pectoraux classés primaires en v1 (secondaires pour Wikipédia, wger, calixpert) ; dentele_anterieur classé secondaire en v1 (primaire pour wger et calixpert full planche)
- **poignet_flexion** : « avant_bras » indifférencié : curl poignet → fléchisseurs du poignet (+ fléchisseurs des doigts) ; extension poignet → extenseurs du poignet (+ extenseur des doigts) ; l'archétype mélange les deux, à répartir par exemple.
- **pompe** : Les abdominaux étaient en secondaire : les sources (Wikipédia, wger) les classent comme stabilisateurs (droit et transverse). Le dentelé antérieur est confirmé (wger, Wikipédia).
- **pompe_archer** : Aucune erreur ; obliques confirmés (wger) mais plutôt stabilisateurs anti-rotation que secondaires.
- **pompe_declinee** : Deltoïde antérieur en primaire non confirmé par les bases (secondaire) ; le chef claviculaire du grand pectoral doit être mis en avant. Abdominaux : stabilisateurs.
- **pompe_diamant** : Aucune erreur (triceps puis pectoraux). Abdominaux : stabilisateurs, pas secondaires.
- **pompe_explosive** : Triceps en primaire non confirmé (secondaire dans les 3 sources). Abdominaux : stabilisateurs.
- **pompe_genoux** : Triceps en primaire non confirmé pour cette régression (secondaire dans wger ; Wikipédia ne distingue pas). Abdominaux : stabilisateurs, pas secondaires.
- **pompe_inclinee** : Triceps en primaire non confirmé (secondaire dans FED et wger). Abdominaux : FED les liste en secondaire, Wikipédia en stabilisateur ; retenu en stabilisateur.
- **pompe_mur** : Aucune erreur ; la v1 met triceps en primaire (wger le confirme, Wikipédia non).
- **pompe_pike** : Le grand pectoral (chef claviculaire) manquait : nommé par les 3 sources. Le dentelé antérieur est confirmé (NASM, Hinge).
- **pompe_pseudo** : Biceps en secondaire non confirmé par les sources ; retenu en stabilisateur (chef long, épaule en avant des mains, raisonnement). Abdominaux : stabilisateurs.
- **pompe_un_bras** : Obliques et abdominaux en secondaire : non confirmés comme secondaires (wger : droit de l'abdomen secondaire ; obliques nommés par aucune source) ; retenus en stabilisateurs anti-rotation.
- **pont_dorsal** : v1 cohérente (deltoïde antérieur, lombaires, fessiers ; triceps, quadriceps). Ajouter érecteurs thoraciques et muscles étirés (fléchisseurs de hanche, pectoraux, grand dorsal, droit de l'abdomen).
- **pont_fessier** : Stabilisateurs abdominaux (wger 1906, ACE) et moyen fessier pour la version une jambe manquaient.
- **presse** : Mollets (FED, wger, Wikipédia) et grand adducteur (StrengthLog) manquaient en secondaire.
- **pull_apart** : Aucune erreur ; « trapezes » v1 → trapèze moyen/inférieur ; coiffe = infra-épineux (Aerobis).
- **pullover** : Pectoraux en secondaire seulement : deux bases et Wikipédia les mettent en primaire (au moins pour la version couchée bras tendus). Pour le pull-over poulie debout (bras tendus, tirage vers les hanches), le grand dorsal reste dominant ; ordre retenu : grand dorsal puis chef sterno-costal.
- **push_press** : Quadriceps et triceps en primaire non confirmés : FED les classe secondaires (l'impulsion des jambes est un assistant, Wikipédia). Fessiers : secondaires confirmés (wger).
- **relevé_jambes** : v1 cohérente (abdominaux + fléchisseurs de hanche ; obliques). Lesté : haltère entre les pieds.
- **respiration** : Transverse en primaire alors que la seule source nomme le diaphragme (et les intercostaux, hors taxonomie) ; le transverse n'intervient qu'à l'expiration active (raisonnement).
- **rotation_externe** : « coiffe_rotateurs » entière en primaire : seuls infra-épineux et petit rond tournent en externe ; le sous-scapulaire n'intervient que dans la rotation interne, le supra-épineux est secondaire.
- **rowing_anneaux** : Biceps en primaire non confirmé (secondaire). Trapèze moyen/inférieur manquait. Abdominaux : stabilisateurs.
- **rowing_appui** : Aucune erreur ; trapèze moyen/inférieur manquait (wger « Trapezius », FED « middle back »).
- **rowing_australien** : Biceps en primaire non confirmé par FED et Wikipédia (secondaire). Trapèze moyen/inférieur manquait (FED « middle back », Wikipédia « trapezius »). Abdominaux : stabilisateurs (Wikipédia : hip extensors, spinal stabilizers). « avant_bras » = brachio-radial + préhension.
- **rowing_barre** : Lombaires et ischios étaient en secondaire : ce sont des stabilisateurs isométriques (Wikipédia : lower back stabilizer). Trapèze moyen/inférieur et infra-épineux/petit rond (Wikipédia) manquaient.
- **rowing_halteres** : Aucune erreur majeure ; trapèze moyen/inférieur manquait. La v1 note uni=false alors que 3 des 4 exemples sont unilatéraux (anti-rotation : obliques, carré des lombes en stabilisation).
- **russian_twist** : Type : rotation dynamique du tronc, pas anti-rotation. v1 fléchisseurs de hanche en secondaire : confirmé (Wikipédia « hips », jambes décollées).
- **sandbag_carry** : Trapèzes et avant-bras en primaire non confirmés (secondaires pour FitMetrics) ; quadriceps et fessiers sont primaires (FitMetrics ; FED pour le chargement). Biceps et pectoraux (serrage bear hug) manquaient (FED biceps).
- **scapular_pushup** : Petit pectoral manquant (MusclesWorked, Physiopedia).
- **sdt** : Grand dorsal (FED « lats », Wikipédia) et rhomboïdes/trapèze moyen (« middle back » FED) manquaient en secondaire ; « avant-bras » précisé en préhension. Sinon v1 confirmée.
- **sdt_roumain** : Mollets (FED RDL) manquaient en secondaire ; grand adducteur ajouté par raisonnement (extenseur de hanche, cf. Wikipédia deadlift). « Avant-bras » précisé en préhension.
- **sdt_unijambe** : v1 confirmée (ischios, fessiers ; moyen fessier, lombaires). Stabilisateurs de cheville et gainage latéral (Wikipédia « équilibre, core ») ajoutés.
- **shrimp_squat** : Abdominaux en secondaire : FitnessVolt « core », dieringe « stabilisateurs » → stabilisateurs. Ischios, moyen fessier, mollets manquaient.
- **shrug** : « trapezes » (3 parties) → seul le trapèze supérieur est moteur (Wikipédia) ; « avant_bras » = préhension en stabilisation, pas un secondaire ; élévateur de la scapula manquant (raisonnement).
- **side_bend** : Type : flexion latérale DYNAMIQUE (concentrique/excentrique), pas anti-flexion latérale. Carré des lombes manquait.
- **sissy_squat** : Abdominaux en secondaire → stabilisateurs (Garage Gym Reviews). Mollets (FED) manquaient en secondaire.
- **situp** : v1 cohérente. Sit-ups GHD : fléchisseurs de hanche et droit fémoral dominants ; butterfly : obliques (wger 1476).
- **skater_squat** : Abdominaux en secondaire → stabilisateurs (Inspire US : obliques et abdominaux). Ischios, moyen fessier et mollets manquaient.
- **skaters** : Rien de faux ; adducteurs absents (primaire chez FED, réception latérale) et ischios absents.
- **sled_pull** : Grand dorsal en primaire pour tout l'archétype alors qu'il ne l'est que pour le sled pull à la corde ; trapèzes/rhomboïdes (dos moyen, primaire FED Sled Row) absents ; ischios et mollets absents.
- **sled_push** : Abdominaux en secondaire : aucune source ne les cite (gainage → stabilisateurs par raisonnement) ; pectoraux (FED), ischios (FED, wger) et deltoïde antérieur (wger) manquaient.
- **snatch** : trapezes classés primaires en v1 ; secondaires dans free-exercise-db (wger ne les cite pas). Deltoïde antérieur primaire confirmé par wger seulement
- **sprint** : v1 confirmée (quadriceps, ischios, fessiers, mollets ; fléchisseurs de hanche). Adducteurs (Contreras) ajoutés en secondaire.
- **squat_assiste** : Adducteurs en secondaire : aucune source ne les nomme pour la version assistée ; remplacés par les ischios (Fitbod, FED, ACE).
- **squat_barre** : Abdominaux en secondaire : Wikipédia les classe en travail isométrique (stabilisateurs), wger 1801 en secondaire. Ischios et mollets (FED, wger 1801) manquaient en secondaire. « Adducteurs » v1 précisé en grand adducteur (Wikipédia).
- **squat_chaise** : Adducteurs en secondaire non confirmés ; ischios (FED, ACE) et soléaire (FED, wger) manquaient.
- **squat_cosaque** : Adducteurs en primaire : une seule source les classe cible sans hiérarchie (Healthline), StrengthLog les met en secondaire → rétrogradés en secondaire. Moyen fessier (ACE) et mollets (wger) manquaient.
- **squat_gobelet** : Abdominaux en secondaire : FED Plie Squat les donne en secondaire mais Wikipédia en isométrique → stabilisateurs. Ischios et mollets (FED) manquaient. Adducteurs : confirmés surtout pour la variante sumo (grand adducteur Wikipédia).
- **squat_overhead** : Deltoïde antérieur en primaire : aucune source ne le classe moteur (FED secondaire, Bosse stabilisateur) → stabilisateur. Trapèzes en secondaire : StrengthLog secondaire, sinon stabilisation. Ischios, adducteurs, lombaires, mollets manquaient.
- **squat_pdc** : Les abdominaux et les lombaires étaient en secondaire : Wikipédia les classe en travail isométrique (stabilisateurs) ; wger 1312 met droit et oblique externe en secondaire. Les ischios (FED, ACE) et les mollets (wger) manquaient en secondaire.
- **squat_profond_tenu** : v1 mélange actifs et étirés : quadriceps = actifs (isométrie légère), fessiers/adducteurs/mollets = étirés. Le soléaire (genou fléchi) est le mollet réellement limitant.
- **squat_saute** : Ischios manquaient en secondaire (FED, deux fiches). Mollets confirmés (FED, triple extension ACE).
- **step_up** : Moyen fessier (appui unipodal, cohérent avec ACE single-leg squat) manquait ; sinon v1 confirmée.
- **straight_arm_pulldown** : Abdominaux classés secondaires en v1 : ce sont des stabilisateurs (SET FOR SET). « triceps » → chef long seulement (extension d'épaule ; wger, SET FOR SET).
- **suitcase_carry** : Le carré des lombes manquait (Bodybuilding-Wizard, primaire). Avant-bras : secondaire selon la source, pas primaire. Transverse : primaire (source), pas secondaire.
- **superman** : Type : le superman est une EXTENSION du tronc (dynamique ou tenue), pas un gainage anti-extension. Les ischios (FED, wger) manquaient en v1.
- **suspension_genoux** : v1 « avant_bras » → prehension ; grand dorsal en stabilisateur plutôt que secondaire (il ne produit pas le mouvement).
- **suspension_jambes** : v1 « avant_bras » → prehension ; grand dorsal → stabilisateur. Droit fémoral ajouté (wger quadriceps).
- **swing** : Abdominaux en secondaire : Wikipédia les nomme mais en gainage/anti-rotation → stabilisateurs. Trapèzes (wger, StrengthLog) et grand dorsal (Wikipédia) manquaient en secondaire ; « avant-bras » précisé en préhension.
- **thruster** : Triceps en primaire : FED seul les cite, en secondaire. Abdominaux et trapèzes en secondaire confirmés (wger 650 pour les trapèzes ; abdominaux par raisonnement).
- **tirage_horizontal_poulie** : Aucune erreur ; « trapezes » v1 → préciser trapèze moyen/inférieur.
- **tirage_vertical_poulie** : biceps classés primaires en v1 ; secondaires dans free-exercise-db, wger et ACE
- **toes_to_bar** : v1 grand_dorsal en primaire : les sources le placent plutôt secondaire ; « avant_bras » → prehension. Knees-to-elbows = régression.
- **traction_l** : flechisseurs_hanche classés secondaires en v1 ; primaires dans la tenue L suspendue (calixpert : iliopsoas primaire)
- **traction_poitrine** : rhomboides classés primaires en v1 ; secondaires dans toutes les sources (haut du dos)
- **traction_un_bras** : avant_bras en primaire v1 : la préhension est un facteur limitant mais les sources la donnent secondaire
- **v_ups** : v1 cohérente. Tuck-ups = wger 1105 (genoux repliés, régression).
- **wall_sit** : Ischios manquaient en secondaire (Wikipédia, wger 718). Mollets et adducteurs (Wikipédia) ajoutés en stabilisateurs (tenue isométrique).
- **wall_slides** : v1 cohérente (dentelé, trapèzes ; coiffe en secondaire). Préciser trapèze inférieur + supérieur (EMG) et rotateurs externes (infra-épineux, petit rond).
- **wall_walk** : triceps classés primaires en v1 ; secondaires pour StrengthLog et calixpert
- **windmill** : v1 « deltoide_lateral » n'existe pas dans la taxonomie → deltoide_moyen ; l'épaule qui tient la kettlebell travaille surtout en stabilisation (coiffe). Ischios : étirés autant que moteurs.
- **windshield** : v1 « avant_bras » → prehension. Type : rotation contrôlée des jambes par les obliques (concentrique/excentrique), pas anti-rotation stricte.
- **woodchop** : Type : ROTATION dynamique du tronc, pas anti-rotation. v1 fessiers/deltoïde antérieur en secondaires : confirmé.
- **wrist_roller** : Deltoïde antérieur classé secondaire en v1 : c'est une tenue isométrique (bras tendus devant), donc stabilisateur (Wikipédia, FED « shoulders »).
- **ytw** : « trapezes » → trapèze inférieur (Y) et moyen (T), pas supérieur ; coiffe (infra-épineux, petit rond) = secondaire, dominante seulement dans le W ; supra-épineux ajouté par raisonnement pour le Y (élévation dans le plan de l'omoplate).

## 1. Seuils de passage des arbres de progression (P1)

| Arbre | Étape | Niveau | Seuil pour passer à l'étape suivante |
| --- | --- | --- | --- |
| Pompes : du mur à la pompe à un bras | Pompes au mur | 1 | 3 × 15 propres |
| Pompes : du mur à la pompe à un bras | Pompes inclinées (mains surélevées) | 2 | 3 × 12 propres |
| Pompes : du mur à la pompe à un bras | Pompes à genoux | 2 | 3 × 12 propres |
| Pompes : du mur à la pompe à un bras | Pompes | 3 | 3 × 12 propres |
| Pompes : du mur à la pompe à un bras | Pompes archer | 6 | 3 × 6 par côté propres |
| Pompes : du mur à la pompe à un bras | Pompes une main (progression) | 7 | 3 × 5 par côté propres |
| Pompes : du mur à la pompe à un bras | Pompe à un bras | 9 | — (dernière étape) |
| Pompes lestées | Pompes | 3 | 3 × 20 propres |
| Pompes lestées | Pompes lestées | 5 | 8 répétition(s) propres avec un lest de 20 % du poids de corps |
| Pompes lestées | Pompes lestées lourdes | 7 | — (dernière étape) |
| Pompes orientées triceps | Pompes | 3 | 3 × 15 propres |
| Pompes orientées triceps | Pompes diamant | 5 | 3 × 12 propres |
| Pompes orientées triceps | Pompes diamant surélevées | 6 | — (dernière étape) |
| Tractions : de la suspension aux tractions lestées | Suspension passive pieds au sol | 1 | 3 × 30 s tenues propres |
| Tractions : de la suspension aux tractions lestées | Dead-hang | 1 | 3 × 30 s tenues propres |
| Tractions : de la suspension aux tractions lestées | Scapular pull-ups | 2 | 3 × 10 propres |
| Tractions : de la suspension aux tractions lestées | Rowing australien barre haute | 2 | 3 × 12 propres |
| Tractions : de la suspension aux tractions lestées | Australian pull-ups (rows barre basse) | 2 | 3 × 12 propres |
| Tractions : de la suspension aux tractions lestées | Traction assistée élastique | 3 | 3 × 8 propres |
| Tractions : de la suspension aux tractions lestées | Traction négative lente | 3 | 3 × 5 propres |
| Tractions : de la suspension aux tractions lestées | Traction pronation | 5 | 3 × 10 propres |
| Tractions : de la suspension aux tractions lestées | Traction lestée | 6 | 5 répétition(s) propres avec un lest de 25 % du poids de corps |
| Tractions : de la suspension aux tractions lestées | Traction lestée lourde | 8 | — (dernière étape) |
| Tractions : vers la traction à un bras | Traction pronation | 5 | 3 × 12 propres |
| Tractions : vers la traction à un bras | Traction poitrine-barre | 6 | 3 × 8 propres |
| Tractions : vers la traction à un bras | Traction archer | 8 | 3 × 5 par côté propres |
| Tractions : vers la traction à un bras | Traction une main (négative) | 9 | 3 × 3 par côté propres |
| Tractions : vers la traction à un bras | Traction une main (assistée) | 9 | — (dernière étape) |
| Dips : du banc aux dips lestés | Dips sur banc genoux fléchis | 2 | 3 × 12 propres |
| Dips : du banc aux dips lestés | Support hold aux barres | 2 | 3 × 30 s tenues propres |
| Dips : du banc aux dips lestés | Dips sur banc (triceps) | 3 | 3 × 15 propres |
| Dips : du banc aux dips lestés | Dips assistés élastique | 3 | 3 × 8 propres |
| Dips : du banc aux dips lestés | Dips négatifs | 3 | 3 × 5 propres |
| Dips : du banc aux dips lestés | Dips | 5 | 3 × 12 propres |
| Dips : du banc aux dips lestés | Dips lestés | 6 | 5 répétition(s) propres avec un lest de 30 % du poids de corps |
| Dips : du banc aux dips lestés | Dips lestés lourds | 8 | — (dernière étape) |
| Squat : du squat assisté au pistol | Squat assisté (appui) | 1 | 3 × 15 propres |
| Squat : du squat assisté au pistol | Squat sur chaise | 1 | 3 × 15 propres |
| Squat : du squat assisté au pistol | Squat au poids de corps | 2 | 3 × 20 propres |
| Squat : du squat assisté au pistol | Fente statique (split squat) | 2 | 3 × 12 par côté propres |
| Squat : du squat assisté au pistol | Fentes bulgares | 5 | 3 × 10 par côté propres |
| Squat : du squat assisté au pistol | Pistol squat assisté | 5 | 3 × 6 par côté propres |
| Squat : du squat assisté au pistol | Pistol squat sur box | 6 | 3 × 5 par côté propres |
| Squat : du squat assisté au pistol | Pistol squat | 8 | 3 × 5 par côté propres |
| Squat : du squat assisté au pistol | Pistol squat lesté | 9 | — (dernière étape) |
| Squat sur une jambe, variante crevette | Fentes bulgares | 5 | 3 × 12 par côté propres |
| Squat sur une jambe, variante crevette | Skater squat | 6 | 3 × 6 par côté propres |
| Squat sur une jambe, variante crevette | Shrimp squat | 7 | — (dernière étape) |
| Squat chargé : vers le back squat | Squat au poids de corps | 2 | 3 × 20 propres |
| Squat chargé : vers le back squat | Squat gobelet | 2 | 3 × 10 propres |
| Squat chargé : vers le back squat | Box squat | 4 | 3 × 8 propres |
| Squat chargé : vers le back squat | Back squat | 4 | — (dernière étape) |
| Charnière de hanche : du pont fessier au soulevé de terre roumain | Pont fessier au sol | 1 | 3 × 15 propres |
| Charnière de hanche : du pont fessier au soulevé de terre roumain | Charnière de hanche au bâton | 1 | 3 × 10 propres |
| Charnière de hanche : du pont fessier au soulevé de terre roumain | Pont fessier une jambe | 3 | 3 × 12 par côté propres |
| Charnière de hanche : du pont fessier au soulevé de terre roumain | Hip thrust | 3 | 3 × 10 propres |
| Charnière de hanche : du pont fessier au soulevé de terre roumain | Soulevé de terre roumain haltères | 3 | 3 × 10 propres |
| Charnière de hanche : du pont fessier au soulevé de terre roumain | Soulevé de terre roumain | 4 | — (dernière étape) |
| Gainage anti-extension : de la planche à la roue debout | Planche sur les genoux | 1 | 3 × 30 s tenues propres |
| Gainage anti-extension : de la planche à la roue debout | Planche de gainage sur les coudes | 2 | 3 × 45 s tenues propres |
| Gainage anti-extension : de la planche à la roue debout | Planche RKC (coudes) | 4 | 3 × 20 s tenues propres |
| Gainage anti-extension : de la planche à la roue debout | Body saw (sliders) | 4 | 3 × 10 propres |
| Gainage anti-extension : de la planche à la roue debout | Ab wheel à genoux (amplitude courte) | 4 | 3 × 10 propres |
| Gainage anti-extension : de la planche à la roue debout | Ab wheel | 6 | 3 × 10 propres |
| Gainage anti-extension : de la planche à la roue debout | Ab wheel debout | 9 | — (dernière étape) |
| Gainage creux : du dead bug au dragon flag | Dead bug | 1 | 3 × 10 par côté propres |
| Gainage creux : du dead bug au dragon flag | Hollow body groupé | 2 | 3 × 30 s tenues propres |
| Gainage creux : du dead bug au dragon flag | Hollow body hold | 3 | 3 × 30 s tenues propres |
| Gainage creux : du dead bug au dragon flag | Hollow rocks | 4 | 3 × 15 propres |
| Gainage creux : du dead bug au dragon flag | Dragon flag (progression) | 7 | 3 × 5 propres |
| Gainage creux : du dead bug au dragon flag | Dragon flag négatif | 7 | 3 × 5 propres |
| Gainage creux : du dead bug au dragon flag | Dragon flag complet | 9 | — (dernière étape) |
| Gainage latéral | Planche latérale sur les genoux | 1 | 3 × 30 s par côté tenues propres |
| Gainage latéral | Planche latérale | 2 | 3 × 45 s par côté tenues propres |
| Gainage latéral | Copenhagen plank | 5 | — (dernière étape) |
| Muscle-up | Traction pronation | 5 | 3 × 10 propres |
| Muscle-up | Traction poitrine-barre | 6 | 3 × 6 propres |
| Muscle-up | Transitions de muscle-up à l'élastique | 6 | 3 × 5 propres |
| Muscle-up | Négatifs de muscle-up | 6 | 3 × 3 propres |
| Muscle-up | Tractions explosives poitrine-barre | 7 | 3 × 5 propres |
| Muscle-up | Muscle-up kipping | 7 | 3 × 3 propres |
| Muscle-up | Muscle-up strict | 9 | 3 × 3 propres |
| Muscle-up | Muscle-up lesté | 9 | — (dernière étape) |
| Front lever | Dead-hang | 1 | 3 × 30 s tenues propres |
| Front lever | Scapular pull-ups | 2 | 3 × 10 propres |
| Front lever | Front lever tuck | 6 | 3 × 15 s tenues propres |
| Front lever | Front lever advanced tuck | 7 | 3 × 12 s tenues propres |
| Front lever | Front lever one leg | 8 | 3 × 10 s par côté tenues propres |
| Front lever | Front lever straddle | 9 | 3 × 8 s tenues propres |
| Front lever | Front lever complet | 10 | — (dernière étape) |
| Back lever | German hang (tenue) | 6 | 3 × 20 s tenues propres |
| Back lever | Back lever tuck | 6 | 3 × 15 s tenues propres |
| Back lever | Back lever advanced tuck | 7 | 3 × 12 s tenues propres |
| Back lever | Back lever straddle | 8 | 3 × 8 s tenues propres |
| Back lever | Back lever complet | 9 | — (dernière étape) |
| Planche (figure) | Planche de gainage sur les coudes | 2 | 3 × 45 s tenues propres |
| Planche (figure) | Planche bras tendus + taps | 3 | 3 × 10 par côté propres |
| Planche (figure) | Planche lean | 4 | 3 × 20 s tenues propres |
| Planche (figure) | Pseudo-planche hold | 5 | 3 × 15 s tenues propres |
| Planche (figure) | Pompes pseudo-planche | 6 | 3 × 8 propres |
| Planche (figure) | Tuck planche | 7 | 3 × 12 s tenues propres |
| Planche (figure) | Planche advanced tuck | 8 | 3 × 10 s tenues propres |
| Planche (figure) | Planche straddle | 9 | 3 × 6 s tenues propres |
| Planche (figure) | Planche complète | 10 | — (dernière étape) |
| Équilibre sur les mains | Pike hold (V inversé) | 2 | 3 × 30 s tenues propres |
| Équilibre sur les mains | Pike push-ups | 4 | 3 × 8 propres |
| Équilibre sur les mains | ATR dos au mur (tenue) | 4 | 3 × 30 s tenues propres |
| Équilibre sur les mains | ATR poitrine au mur (tenue) | 5 | 3 × 45 s tenues propres |
| Équilibre sur les mains | Shoulder taps en ATR | 6 | 3 × 5 par côté propres |
| Équilibre sur les mains | ATR (équilibre) | 7 | 3 × 20 s tenues propres |
| Équilibre sur les mains | Handstand walk (marche en ATR) | 8 | — (dernière étape) |
| Pompes en équilibre (HSPU) | Pike push-ups | 4 | 3 × 10 propres |
| Pompes en équilibre (HSPU) | Pike push-ups surélevés (pieds sur banc) | 5 | 3 × 8 propres |
| Pompes en équilibre (HSPU) | Handstand push-ups (mur) | 7 | 3 × 5 propres |
| Pompes en équilibre (HSPU) | HSPU stricts en déficit | 8 | 3 × 5 propres |
| Pompes en équilibre (HSPU) | HSPU freestanding (progression) | 9 | — (dernière étape) |
| L-sit | Support hold aux barres | 2 | 3 × 30 s tenues propres |
| L-sit | L-sit tuck (tenue) | 3 | 3 × 20 s tenues propres |
| L-sit | L-sit une jambe | 4 | 3 × 15 s par côté tenues propres |
| L-sit | L-sit | 5 | 3 × 20 s tenues propres |
| L-sit | V-sit progression | 8 | 3 × 10 s tenues propres |
| L-sit | V-sit (tenue) | 9 | 3 × 5 s tenues propres |
| L-sit | Manna progression | 10 | — (dernière étape) |
| Drapeau | Planche latérale | 2 | 3 × 60 s par côté tenues propres |
| Drapeau | Drapeau vertical (tenue) | 6 | 3 × 10 s par côté tenues propres |
| Drapeau | Human flag tuck | 7 | 3 × 8 s par côté tenues propres |
| Drapeau | Drapeau straddle | 8 | 3 × 5 s par côté tenues propres |
| Drapeau | Human flag (drapeau) | 9 | — (dernière étape) |
| Mobilité des épaules | Cercles de bras | 1 | 2 × 10 propres |
| Mobilité des épaules | Wall slides (glissés au mur) | 1 | 2 × 12 propres |
| Mobilité des épaules | Dislocations épaules élastique | 1 | 2 × 12 propres |
| Mobilité des épaules | Dislocations épaules bâton | 1 | 2 × 12 propres |
| Mobilité des épaules | Bridge (pont dorsal) | 5 | 3 × 20 s tenues propres |
| Mobilité des épaules | German hang (tenue) | 6 | — (dernière étape) |
| Mobilité des hanches | Étirements fléchisseurs de hanche | 1 | 2 × 45 s par côté tenues propres |
| Mobilité des hanches | Fente basse étirement (hanche) | 1 | 2 × 45 s par côté tenues propres |
| Mobilité des hanches | Mobilité hanches (90/90) | 1 | 2 × 60 s par côté tenues propres |
| Mobilité des hanches | Squat profond tenu | 2 | 3 × 60 s tenues propres |
| Mobilité des hanches | Squat cosaque | 4 | — (dernière étape) |
| Mobilité des chevilles | Mobilisation cheville genou au mur | 1 | 2 × 12 par côté propres |
| Mobilité des chevilles | Mollets unilatéraux sur marche | 2 | 3 × 15 par côté propres |
| Mobilité des chevilles | Squat profond tenu | 2 | — (dernière étape) |

Prérequis transverses (en plus de l'étape précédente) :

- Transitions de muscle-up à l'élastique ← Dips : 3 × 10 propres
- Muscle-up kipping ← Dips : 3 × 12 propres
- Front lever tuck ← Traction pronation : 3 × 8 propres
- Front lever tuck ← Hollow body hold : 3 × 30 s tenues propres
- Tuck planche ← Dips : 3 × 10 propres
- Handstand push-ups (mur) ← ATR dos au mur (tenue) : 3 × 30 s tenues propres
- L-sit ← Hollow body hold : 3 × 30 s tenues propres
- Human flag tuck ← Traction pronation : 3 × 8 propres
- Human flag tuck ← Pike push-ups : 3 × 8 propres
- Back lever tuck ← Traction pronation : 3 × 8 propres
- Ab wheel debout ← Hollow rocks : 3 × 15 propres

## 2. Exercices à forte contrainte articulaire (P1)

Exercices utilisables par le générateur ayant au moins une zone cotée 3/3, avec leurs précautions.

| Exercice | Niveau | Zones à 3 | Précautions |
| --- | --- | --- | --- |
| Soulevé de terre kettlebell | 2 | Rachis lombaire | lombaire, charge_axiale, technique_prioritaire |
| Barre au front EZ | 3 | Coude | coude |
| Box jumps step-down | 3 | Hanche | impacts |
| Crunchs lestés | 3 | Rachis cervical | cervical |
| Curl pupitre (Larry Scott) | 3 | Coude | coude |
| Dips sur banc (triceps) | 3 | Épaule | epaule_anterieure |
| Frog stand (crow) | 3 | Poignet | poignet_extension, tete_en_bas, equilibre, chute_arriere |
| Hack squat | 3 | Genou | genou_flexion |
| Montée en ATR contre le mur (kick-up) | 3 | Poignet | poignet_extension, tete_en_bas, equilibre |
| Planche lean à l'élastique | 3 | Poignet | poignet_extension, tendons_bras_tendus |
| Russian twists lestés | 3 | Poignet | lombaire |
| Sauts de mollets (pogo) | 3 | Cheville | impacts |
| Tate press | 3 | Coude | coude |
| Wall walks partiels (mi-hauteur) | 3 | Poignet | poignet_extension, tete_en_bas |
| ATR dos au mur (tenue) | 4 | Poignet | poignet_extension, tete_en_bas |
| Back squat | 4 | Genou | charge_axiale, genou_flexion, lombaire |
| Box jumps | 4 | Hanche | impacts |
| Broad jumps (sauts en longueur) | 4 | Hanche, Genou | impacts |
| Dips isométriques mi-course | 4 | Épaule | epaule_anterieure |
| Développé militaire debout | 4 | Rachis lombaire | epaule_au_dessus_tete, lombaire |
| Extension triceps au poids de corps (mains au sol) | 4 | Coude | coude |
| Planche latérale lestée | 4 | Épaule | — |
| Planche lean | 4 | Poignet | poignet_extension, tendons_bras_tendus |
| Pompes prise serrée | 4 | Poignet | poignet_extension, coude |
| Rack pulls | 4 | Rachis lombaire | lombaire, charge_axiale, technique_prioritaire |
| Sissy squat assisté | 4 | Hanche | genou_flexion |
| Soulevé de terre trap bar | 4 | Rachis lombaire | lombaire, charge_axiale, technique_prioritaire |
| Squat cosaque | 4 | Hanche | genou_flexion, adducteurs |
| Squat sauté | 4 | Hanche | impacts |
| Support hold lesté | 4 | Épaule, Poignet | — |
| Transition muscle-up assistée pieds au sol | 4 | Épaule | suspension |
| ATR poitrine au mur (tenue) | 5 | Poignet | poignet_extension, tete_en_bas |
| Bridge (pont dorsal) | 5 | Poignet | lombaire, poignet_extension, epaule_au_dessus_tete |
| False grip hang | 5 | Poignet | suspension, poignet_extension |
| False grip hold (anneaux ou barre) | 5 | Poignet | suspension, poignet_extension |
| Fentes bulgares | 5 | Hanche | genou_flexion, equilibre |
| Fentes sautées | 5 | Hanche, Genou | impacts, genou_flexion |
| Front squat | 5 | Genou | charge_axiale, genou_flexion |
| Good mornings | 5 | Rachis lombaire | lombaire, charge_axiale |
| HIIT course 30/30 | 5 | Genou, Cheville | impacts, cardio_intense |
| Isométrie bas de dip | 5 | Épaule | epaule_anterieure |
| JM press | 5 | Coude | coude |
| Nordic curl assisté (mains) | 5 | Hanche | genou_flexion |
| Nordic curl assisté élastique | 5 | Hanche | genou_flexion |
| Pistol squat assisté | 5 | Hanche | genou_flexion |
| Pompes diamant | 5 | Poignet | poignet_extension, coude |
| Pompes lestées | 5 | Épaule, Poignet | poignet_extension, epaule_anterieure |
| Pseudo-planche hold | 5 | Poignet | poignet_extension, tendons_bras_tendus |
| Push press | 5 | Rachis lombaire | epaule_au_dessus_tete, technique_prioritaire |
| Push press haltères | 5 | Rachis lombaire | epaule_au_dessus_tete, technique_prioritaire |
| Sandbag clean | 5 | Rachis lombaire | technique_prioritaire, lombaire |
| Shuttle runs (navettes) | 5 | Genou, Cheville | impacts, cardio_intense |
| Soulevé de terre | 5 | Rachis lombaire | lombaire, charge_axiale, technique_prioritaire |
| Soulevé de terre sumo | 5 | Rachis lombaire | lombaire, charge_axiale, technique_prioritaire |
| Squat 1 ¼ | 5 | Genou | charge_axiale, genou_flexion, lombaire |
| Squat endurance @ 70 kg | 5 | Genou | charge_axiale, genou_flexion, lombaire |
| Squat pause | 5 | Genou | charge_axiale, genou_flexion, lombaire |
| Squat tempo | 5 | Genou | charge_axiale, genou_flexion, lombaire |
| Thruster haltères | 5 | Genou | epaule_au_dessus_tete, charge_axiale |
| Tuck jumps | 5 | Hanche, Genou | impacts |
| Wall walks | 5 | Poignet | poignet_extension, tete_en_bas |
| Back lever tuck | 6 | Épaule | suspension, tendons_bras_tendus, epaule_anterieure |
| Bar dips lestés | 6 | Épaule, Coude, Poignet | epaule_anterieure |
| Burpees lestés (gilet) | 6 | Épaule, Poignet, Hanche, Genou | cardio_intense, impacts, poignet_extension |
| Course — fractionné 200 m | 6 | Genou, Cheville | impacts, cardio_intense |
| Course — fractionné 400 m | 6 | Genou, Cheville | impacts, cardio_intense |
| Dips excentriques lestés | 6 | Épaule, Coude, Poignet | epaule_anterieure, coude |
| Dips explosifs | 6 | Épaule, Coude, Poignet | epaule_anterieure, coude |
| Dips lestés | 6 | Épaule, Coude, Poignet | epaule_anterieure, coude |
| Dips lestés cluster | 6 | Épaule, Coude, Poignet | epaule_anterieure, coude |
| Dips lestés pause | 6 | Épaule, Coude, Poignet | epaule_anterieure, coude |
| Dips lestés tempo | 6 | Épaule, Coude, Poignet | epaule_anterieure, coude |
| Drapeau vertical (tenue) | 6 | Épaule | tendons_bras_tendus |
| Excentrique de transition muscle-up | 6 | Épaule | suspension |
| German hang (tenue) | 6 | Épaule | epaule_anterieure, tendons_bras_tendus |
| HSPU négatives (mur) | 6 | Épaule, Hanche | epaule_au_dessus_tete, tete_en_bas, cervical, poignet_extension |
| Hang clean | 6 | Rachis lombaire | technique_prioritaire, lombaire |
| Jefferson curl | 6 | Rachis lombaire | lombaire, technique_prioritaire |
| Kipping pull-ups | 6 | Épaule | suspension, technique_prioritaire, epaule_anterieure |
| Négatifs de muscle-up | 6 | Épaule | suspension |
| Pistol squat sur box | 6 | Hanche | genou_flexion |
| Pompes diamant surélevées | 6 | Poignet | poignet_extension, coude |
| Pompes explosives (clap) | 6 | Poignet | poignet_extension, impacts |
| Pompes pseudo-planche | 6 | Épaule, Poignet | poignet_extension, tendons_bras_tendus |
| Shoulder taps en ATR | 6 | Épaule, Poignet | poignet_extension, tete_en_bas |
| Sissy squat | 6 | Hanche | genou_flexion |
| Skater squat | 6 | Hanche | genou_flexion, equilibre |
| Skin the cat | 6 | Épaule | suspension, tete_en_bas, epaule_anterieure |
| Sprint | 6 | Genou, Cheville | impacts, cardio_intense |
| Sprint en côte | 6 | Genou, Cheville | impacts, cardio_intense |
| Squat Zercher | 6 | Genou | charge_axiale, genou_flexion, lombaire, coude |
| Squat bulgare lesté (gilet) | 6 | Hanche, Genou | genou_flexion, equilibre |
| Squat sauté lesté | 6 | Hanche, Genou, Cheville | impacts, charge_axiale |
| Squat — walkout lourd | 6 | Rachis lombaire, Hanche, Genou | charge_axiale, genou_flexion, lombaire, effort_maximal |
| Thruster | 6 | Genou | epaule_au_dessus_tete, charge_axiale |
| Traction excentrique lestée | 6 | Épaule, Coude | suspension |
| Traction lestée | 6 | Épaule, Coude | suspension |
| Traction lestée cluster | 6 | Épaule, Coude | suspension |
| Traction lestée pause | 6 | Épaule, Coude | suspension |
| Traction lestée tempo | 6 | Épaule, Coude | suspension |
| Transitions de muscle-up à l'élastique | 6 | Épaule | suspension |
| Élévations en ATR (tenue) | 6 | Poignet | poignet_extension, tete_en_bas |
| ATR (équilibre) | 7 | Poignet | poignet_extension, tete_en_bas, equilibre, chute_arriere |
| Back lever advanced tuck | 7 | Épaule | suspension, tendons_bras_tendus, epaule_anterieure |
| Bear crawl lesté (gilet) | 7 | Poignet | poignet_extension |
| Chest-to-bar kipping | 7 | Épaule | suspension, technique_prioritaire, epaule_anterieure |
| Chin-up lesté | 7 | Épaule, Coude | suspension |
| Dips aux anneaux | 7 | Épaule | epaule_anterieure |
| Dips lestés — singles lourds | 7 | Épaule, Coude, Poignet | epaule_anterieure, coude, effort_maximal |
| Dragon flag (progression) | 7 | Rachis cervical | lombaire, cervical |
| Dragon flag négatif | 7 | Rachis cervical | lombaire, cervical |
| Dragon flag négatif (support au sol) | 7 | Rachis cervical | lombaire, cervical |
| Excentriques de transition LESTÉS | 7 | Épaule, Coude | suspension |
| Extension triceps au poids de corps pieds surélevés | 7 | Coude | coude |
| Fentes arrière en déficit lestées | 7 | Hanche, Genou | genou_flexion, equilibre |
| Fentes bulgares sautées | 7 | Hanche, Genou | genou_flexion, equilibre, impacts |
| Fentes marchées lestées lourdes (gilet) | 7 | Hanche, Genou | genou_flexion, equilibre |
| Foulées bondissantes (bounding) | 7 | Genou, Cheville | impacts, cardio_intense |
| HSPU kipping | 7 | Épaule, Hanche | epaule_au_dessus_tete, tete_en_bas, cervical, poignet_extension, technique_prioritaire |
| Handstand push-ups (mur) | 7 | Épaule, Hanche | epaule_au_dessus_tete, tete_en_bas, cervical, poignet_extension |
| Hip thrust une jambe lesté | 7 | Hanche | — |
| Human flag tuck | 7 | Épaule | tendons_bras_tendus |
| Isométrie de transition muscle-up | 7 | Épaule | suspension |
| Kettlebell swing lourd (deux mains) | 7 | Rachis lombaire | lombaire, technique_prioritaire |
| Muscle-up kipping | 7 | Épaule | suspension, technique_prioritaire |
| Nordic curl (excentrique) | 7 | Hanche | genou_flexion |
| Planche latérale bras tendu lestée | 7 | Épaule | — |
| Pompes pliométriques (mains sur boxes) | 7 | Poignet | poignet_extension, impacts |
| Pompes une main (progression) | 7 | Épaule, Poignet | poignet_extension, epaule_anterieure |
| Pont dorsal une jambe | 7 | Poignet | lombaire, poignet_extension, epaule_au_dessus_tete |
| Power clean | 7 | Rachis lombaire | technique_prioritaire, lombaire |
| Push jerk | 7 | Rachis lombaire | epaule_au_dessus_tete, technique_prioritaire |
| Sandbag carry lourd | 7 | Poignet | lombaire |
| Sauts en contrebas (depth jumps) | 7 | Hanche, Genou, Cheville | impacts |
| Shrimp squat | 7 | Hanche, Genou | genou_flexion, equilibre |
| Soulevé de terre en déficit | 7 | Rachis lombaire | lombaire, charge_axiale, technique_prioritaire |
| Sprints répétés (10 × 50 m) | 7 | Genou, Cheville | impacts, cardio_intense |
| Squat bulgare gilet lesté lourd | 7 | Hanche, Genou | genou_flexion, equilibre |
| Squat bulgare haltères lourd | 7 | Hanche, Genou | genou_flexion, equilibre |
| Squat overhead | 7 | Épaule, Genou | epaule_au_dessus_tete, technique_prioritaire |
| Thruster haltères lourd | 7 | Épaule, Rachis lombaire, Hanche, Genou | epaule_au_dessus_tete, charge_axiale |
| Traction lestée élastique (accommodante) | 7 | Épaule, Coude | suspension |
| Traction lestée — singles lourds | 7 | Épaule, Coude | suspension, effort_maximal |
| Tuck planche | 7 | Épaule, Poignet | poignet_extension, tendons_bras_tendus |
| Back lever straddle | 8 | Épaule | suspension, tendons_bras_tendus, epaule_anterieure |
| Burpees pull-up lestés (gilet) | 8 | Épaule, Poignet, Hanche, Genou | cardio_intense, impacts, poignet_extension |
| Butterfly pull-ups | 8 | Épaule | suspension, technique_prioritaire, epaule_anterieure |
| Descente en pont le long du mur | 8 | Poignet | lombaire, poignet_extension, epaule_au_dessus_tete, tete_en_bas |
| Dips aux anneaux RTO (tournés) | 8 | Épaule | epaule_anterieure |
| Dips aux anneaux lestés | 8 | Épaule, Coude, Poignet | epaule_anterieure |
| Drapeau straddle | 8 | Épaule | tendons_bras_tendus |
| HSPU stricts en déficit | 8 | Épaule, Hanche | epaule_au_dessus_tete, tete_en_bas, cervical, poignet_extension |
| Handstand walk (marche en ATR) | 8 | Poignet | poignet_extension, tete_en_bas, equilibre, chute_arriere |
| Muscle-up | 8 | Épaule | suspension, technique_prioritaire |
| Muscle-up aux anneaux | 8 | Épaule, Poignet | suspension, technique_prioritaire, poignet_extension |
| Muscle-up négatif lesté | 8 | Épaule, Coude | suspension |
| Pistol squat | 8 | Hanche, Genou | genou_flexion, equilibre |
| Planche advanced tuck | 8 | Épaule, Poignet | poignet_extension, tendons_bras_tendus |
| V-sit progression | 8 | Épaule | poignet_extension |
| Back lever complet | 9 | Épaule | suspension, tendons_bras_tendus, epaule_anterieure |
| Clean & jerk | 9 | Rachis lombaire | technique_prioritaire, lombaire |
| Dragon flag (support au sol) | 9 | Rachis cervical | lombaire, cervical |
| Dragon flag complet | 9 | Rachis cervical | lombaire, cervical |
| HSPU freestanding (progression) | 9 | Épaule, Hanche | epaule_au_dessus_tete, tete_en_bas, cervical, poignet_extension, equilibre, chute_arriere |
| Human flag (drapeau) | 9 | Épaule | tendons_bras_tendus |
| Muscle-up aux anneaux strict | 9 | Épaule, Poignet | suspension, technique_prioritaire, poignet_extension |
| Muscle-up lesté | 9 | Épaule, Coude | suspension, technique_prioritaire |
| Muscle-up lesté cluster | 9 | Épaule, Coude | suspension, technique_prioritaire |
| Muscle-up strict | 9 | Épaule | suspension, technique_prioritaire |
| Nordic curl complet | 9 | Hanche | genou_flexion |
| Pistol squat lesté | 9 | Hanche, Genou, Cheville | genou_flexion, equilibre, charge_axiale |
| Pistol squat sauté | 9 | Hanche, Genou, Cheville | genou_flexion, equilibre, impacts |
| Planche straddle | 9 | Épaule, Poignet | poignet_extension, tendons_bras_tendus |
| Pompe à un bras | 9 | Épaule, Poignet | poignet_extension, epaule_anterieure |
| Press to handstand (pike press) | 9 | Poignet | poignet_extension, tete_en_bas, equilibre, chute_arriere |
| Shrimp squat avancé (pied tenu à deux mains) | 9 | Hanche, Genou | genou_flexion, equilibre |
| Snatch (arraché) | 9 | Épaule, Rachis lombaire, Hanche, Genou | technique_prioritaire, epaule_au_dessus_tete, lombaire |
| Traction une main (assistée) | 9 | Épaule, Coude | suspension, coude |
| Traction une main (négative) | 9 | Épaule, Coude | suspension, coude |
| V-sit (tenue) | 9 | Épaule | poignet_extension |
| Manna progression | 10 | Épaule, Coude, Poignet | poignet_extension, tendons_bras_tendus |
| Muscle-up lesté — singles | 10 | Épaule, Coude | suspension, technique_prioritaire, effort_maximal |
| Nordic curl lesté | 10 | Hanche | genou_flexion |
| Planche complète | 10 | Épaule, Poignet | poignet_extension, tendons_bras_tendus |

## 3. Difficultés (P2)

Échelle 1 à 10 calibrée pour un adulte non entraîné au poids de corps. Pour les exercices chargés, la cote mesure la technicité et l'accessibilité, pas la charge. Quand une source donne un niveau de référence (free-exercise-db, ACE, StrengthLevel), il est rappelé pour comparaison.

| Archétype | Référence externe | Exercices (niveau) |
| --- | --- | --- |
| ab_wheel | FED : intermediate (à genoux : expert, incohérent) ; MusclesWorked : advanced ; StrengthLevel : reps | Ab wheel à genoux (amplitude courte) (4), Ab wheel (6), Rollout barre (7), Ab wheel debout (9) |
| abducteurs | FED : beginner ; Nishaana : beginner ; StrengthLevel intermédiaire ≈ 222 lb (170 lb) | Abducteurs machine (1) |
| active_hang | calixpert : beginner | Suspension active (active hang) (2) |
| adducteurs_machine | FED : beginner | Adducteurs machine (1) |
| atr | Kovo : advanced (libre) ; calixpert (mur) : intermediate ; Wikipédia : basique/intermédiaire/avancé selon la forme | Frog stand (crow) (3), ATR (équilibre) (7), Test max handstand hold (7), Press to handstand (pike press) (9) |
| atr_dos_mur | calixpert : intermediate | Montée en ATR contre le mur (kick-up) (3), ATR dos au mur (tenue) (4) |
| atr_poitrine_mur | calixpert : intermediate | ATR poitrine au mur (tenue) (5), Élévations en ATR (tenue) (6) |
| atr_taps | Kovo : advanced | Shoulder taps en ATR (6) |
| back_lever | FIG : valeur A ; dieringe : advanced ; Kovo : expert | Back lever tuck (6), Back lever advanced tuck (7), Back lever straddle (8), Back lever complet (9) |
| barre_front | FED : beginner (skullcrusher, JM press), intermediate (lying triceps press, Tate press) ; StrengthLevel intermédiaire ≈ 92 lb (170 lb) | Barre au front EZ (3), Extension triceps couché (barre EZ) (3), Tate press (3), Extension triceps au poids de corps (mains au sol) (4), JM press (5), Extension triceps au poids de corps pieds surélevés (7) |
| battle_rope | FED : beginner | Battle ropes (3) |
| bird_dog | ACE : intermediate ; Peloton : beginner | Bird dog (1) |
| body_saw | Muscle & Strength : intermediate ; Fitness Volt : modulable | Body saw (sliders) (4), Body saw amplitude complète (7) |
| box_jump | ACE : Intermediate ; FED : beginner ; MuscleWiki (unipodal) : Advanced | Box jumps step-down (3), Box jumps (4) |
| box_squat | FED : intermediate ; StrengthLevel homme 80 kg : intermédiaire ≈ 157 kg | Box squat (4) |
| burpee | MuscleWiki : Intermediate ; ACE : Advanced (variante BOSU) ; wger/Wikipédia : non noté | Half burpees (3), Burpees (4), HIIT court (4), Burpees broad jump (5), Burpees over the bar (5), Burpees box jump-over (6), Burpees lestés (gilet) (6), Burpees pull-up (6), Test max burpees 3 min (6), Burpees Navy Seal (7), Tuck jump burpees (7), Burpees pull-up lestés (gilet) (8) |
| cercles_bras | FED, Fitness Volt, Motra : beginner | Cercles de bras (1) |
| charniere_baton | ACE : beginner ; Wikipédia (bâton) : débutants / échauffement | Charnière de hanche au bâton (1) |
| clamshell | Bodybuilding-Wizard : beginner to advanced | Clamshell élastique (1) |
| clean | StrengthLevel (homme ~80 kg, 1RM) : beginner 57 kg, novice 74, intermediate 95, advanced 117, elite 142 ; free-exercise-db : intermediate (clean, power, hang), expert (clean & jerk) | Sandbag clean (5), Hang clean (6), Power clean (7), Clean & jerk (9) |
| clean_press | free-exercise-db : intermediate (KB clean, clean & jerk, clean & press barre) ; Kovo : advanced | Kettlebell clean (4), Kettlebell clean & press (5) |
| copenhague | E3 Rehab : progressions (levier court = facile, levier long avec mouvement = avancé) ; pas de niveau chiffré | Copenhagen plank (5), Copenhagen plank à levier long (7) |
| corde_a_sauter | MuscleWiki : Beginner ; FED : intermediate | Corde à sauter (2), Sauts à la corde unipodaux (4), Double-unders (5) |
| course | FED : beginner ; tests (Cooper, 5 km) sans standard musculaire | Course à pied (footing) (3), Course — fartlek (4), Test 5 km course (5), Test Cooper 12 min (5) |
| crab_walk | SET FOR SET : beginner–intermediate ; FitnessVolt : beginner | Crab walk (3) |
| crawl | ACE : intermediate ; FED (sled) : beginner | Bear crawl (3), Planche de l'ours avec touchers d'épaules (4), Bear crawl lesté (gilet) (7) |
| crunch | FED, ACE crunch : beginner ; ACE bicycle : intermediate ; StrengthLevel : reps | Bicycle crunchs (2), Crunchs lestés (3) |
| crunch_poulie | FED : beginner ; StrengthLevel : charge | Crunchs poulie haute (3) |
| cuban_press | FED : intermediate ; BarBend : accessible aux débutants avec charge très légère | Cuban press (3) |
| curl | FED : beginner (Zottman : intermediate) ; StrengthLevel intermédiaire ≈ 47 lb par haltère | Curl élastique (1), Curl concentration (2), Curl haltères (2), Curl Zottman (3), Curl araignée (3), Curl incliné (3) |
| curl_barre | FED : beginner ; StrengthLog : intermediate (reverse curl) | Curl barre EZ (2), Curl pronation (reverse curl) (3) |
| curl_marteau | FED : beginner | Curl marteau (2), Curl marteau (par haltère) (2) |
| curl_poulie | FED : beginner | Curl poulie basse (2) |
| curl_pupitre | FED : beginner | Curl pupitre (Larry Scott) (3) |
| dead_bug | FED, ACE, NASM : beginner | Dead bug (1) |
| dead_hang | calixpert : pre-beginner ; FitCraft : beginner (pieds assistés) / intermediate 30-60 s / advanced lesté >60 s | Dead-hang (1), Suspension passive pieds au sol (1), Dead-hang lesté ou PdC (3), Test max dead-hang (3), Dead-hang serviette (4), Dead-hang une main (6) |
| depth_jump | Wikipédia : haute intensité (avancé) ; FED : beginner (Depth Jump Leap) / intermediate (Linear Depth Jump) | Sauts en contrebas (depth jumps) (7) |
| developpe_assis | FED : intermediate | Développé haltères assis (3), Développé militaire assis (4), Z-press (5) |
| developpe_couche | FED : beginner ; ACE (prise serrée) : intermediate ; StrengthLevel homme 80 kg : intermédiaire ≈ 100 kg | Développé couché (3), Développé couché pause (4), Développé couché prise serrée (4), Développé décliné (4), Test 1RM Développé couché (5) |
| developpe_couche_halteres | FED : beginner | Développé couché haltères (3) |
| developpe_halteres | FED : intermediate | Développé élastique au-dessus de la tête (1), Développé militaire haltères debout (3), Développé Arnold (4), Développé kettlebell (par bras) (4) |
| developpe_incline | FED : beginner | Développé incliné (3), Développé incliné haltères (3) |
| developpe_militaire | FED : beginner (Standing Military Press) / intermediate (Barbell Shoulder Press) ; ACE : advanced | Développé militaire debout (4) |
| devil_press | BarBend : Advanced ; PureGym : Advanced | Devil press (6) |
| dips_anneaux | FED : intermediate | Dips aux anneaux (7), Dips aux anneaux RTO (tournés) (8), Dips aux anneaux lestés (8) |
| dips_banc | FED : beginner | Dips sur banc (triceps) (3) |
| dips_banc_genoux | Régression des dips sur banc (genoux fléchis = moins de poids sur les bras) ; niveau débutant par déduction | Dips sur banc genoux fléchis (2) |
| dips_barre_fixe | Aucun niveau donné ; plus exigeant que les barres parallèles (buste incliné, hollow) par raisonnement | Bar dips (dips à la barre fixe) (5), Bar dips lestés (6), Dips coréens (8) |
| dips_barres | FED : beginner (version triceps) / intermediate (version chest) ; StrengthLevel : standards bodyweight disponibles | Dips assistés élastique (3), Dips négatifs (3), Dip (5), Dips (5), Dips PdC (5), Dips pause basse (5), Dips tempo (3 s excentrique) (5), Dip Lesté (6), Dips bulgares (prise large) (6), Dips excentriques lestés (6), Dips explosifs (6), Dips lestés (6), Dips lestés cluster (6), Dips lestés pause (6), Dips lestés tempo (6), Test max dips PdC (6), Dips lestés — singles lourds (7), Dips à résistance accommodante (élastique depuis le sol) (7), Russian dips (7), Test 1RM Dip Lesté (7), Dips lestés lourds (8) |
| dislocations | beginner (Horton Barbell : adaptable par la largeur de prise) | Dislocations épaules bâton (1), Dislocations épaules élastique (1) |
| dragon_flag | StrengthLog, MusclesWorked : advanced | Dragon flag (progression) (7), Dragon flag négatif (7), Dragon flag négatif (support au sol) (7), Dragon flag (support au sol) (9), Dragon flag complet (9) |
| drapeau | Gymless : advanced (prérequis ~15 tractions x5) ; calisthenics.com : advanced/elite ; Kovo : expert | Drapeau vertical (tenue) (6), Human flag tuck (7), Drapeau straddle (8), Human flag (drapeau) (9) |
| ecarte | FED : beginner ; StrengthLevel intermédiaire ≈ 50 lb par haltère (170 lb) | Écarté haltères (3) |
| ecarte_poulie | FED : beginner (vis-à-vis), intermediate (banc) | Écarté poulie vis-à-vis (2) |
| elevation_frontale | FED : beginner | Élévations frontales (2) |
| elevation_laterale | FED : beginner ; StrengthLevel intermédiaire ≈ 35 lb par haltère | Élévations latérales élastique (1), Élévations latérales (2), Élévations latérales (par haltère) (2), Élévations latérales poulie (2) |
| ergo_rameur | FED : intermediate | Rameur (2), Rameur — intervalles 500 m (5), Test 2 km rameur (5) |
| ergo_ski | aucun niveau donné par les sources | SkiErg (2) |
| ergo_velo | FED : beginner | Assault bike (2), Echo bike (calories) (3), Vélo — intervalles (4), Assault bike — sprints (5) |
| etirement_flechisseurs | FED, ACE : beginner | Fente basse étirement (hanche) (1), Étirements fléchisseurs de hanche (1) |
| etirement_posterieur | FED, ACE : beginner | Étirements chaîne postérieure (1) |
| extension_doigts | StrengthLog : beginner | Extensions de doigts élastique (1) |
| extension_triceps_nuque | FED : beginner (à deux mains), intermediate (un bras) | Extension triceps haltère à deux mains (3), Extension triceps nuque (3) |
| extension_triceps_poulie | FED : beginner | Extension corde (2), Extension triceps poulie (2), Extension triceps poulie corde (2), Extension triceps unilatérale poulie (2) |
| face_pull | FED : intermediate | Face pulls élastique (1), Face pulls (2) |
| false_grip | calixpert : beginner (barre) ; aux anneaux plus exigeant pour le poignet | False grip hang (5), False grip hold (anneaux ou barre) (5) |
| farmer | FED : intermediate ; ACE : intermediate ; StrengthLevel homme 80 kg : intermédiaire ≈ 35 kg par main sur 20 m | Farmer walk (2), Farmer walk kettlebells (2), Farmer walk sacs lestés (3), Farmer walk lourd (trap bar) (4), Rack carry kettlebells (4), Farmer walk haltères lourds (7), Farmer walk très lourd (trap bar) (7) |
| farmer_hold | Aucun niveau spécifique ; farmer walk FED : intermediate | Farmer hold (tenue) (2) |
| fente | FED : beginner (haltères, marchées) à intermediate (arrière) ; ACE : intermediate ; Wikipédia : mouvement de base pour débutants ; StrengthLevel homme ~77 kg : intermédiaire ≈ 36 reps | Fente statique (split squat) (2), Fentes arrière (2), Marche en fente (2), Fentes avant (3), Fentes marchées (3), Fentes déficit (4), Fentes marchées (par haltère) (4), Fentes marchées haltères (4), Fentes marchées lestées (sac) (4), Fentes arrière en déficit lestées (7), Fentes marchées lestées lourdes (gilet) (7) |
| fente_bulgare | FED : beginner (haltères) / intermediate (suspendu) ; StrengthLevel homme 80 kg : intermédiaire ≈ 66 kg (haltères) | Fentes bulgares (5), Squat bulgare haltères (5), Squat bulgare lesté (gilet) (6), Fentes bulgares sautées (7), Squat bulgare gilet lesté lourd (7), Squat bulgare haltères lourd (7) |
| fente_laterale | ACE : intermediate ; FED : beginner | Fentes latérales (3) |
| fente_sautee | FED : beginner (plyometrics) ; pas de standard StrengthLevel | Fentes sautées (5) |
| floor_press | FED : intermediate | Floor press (3) |
| flutter | FED : beginner ; StrengthLevel : reps | Ciseaux (scissors) (2), Flutter kicks (2) |
| foam | FED : beginner | Foam roller (auto-massage) (1) |
| front_lever | FIG : valeur A ; calixpert advanced tuck : intermediate ; Gymless : advanced ; full front lever = avancé/expert | Front lever hold à l'élastique (6), Front lever tuck (6), Front lever advanced tuck (7), Front lever one leg (8), Front lever straddle (9), Front lever complet (10) |
| front_lever_dyn | calixpert raises (advanced tuck) : intermediate ; GorNation ice cream makers : advanced | Front lever raises (7), Front lever négatif (8), Front lever pull-ups (tuck) (8), Ice cream makers (8) |
| front_squat | FED : expert (barbell) / intermediate (clean grip) ; ACE : intermediate ; StrengthLevel homme 80 kg : intermédiaire ≈ 101 kg | Front squat (5), Test 1RM Front squat (6) |
| genoux_hauts | FED (Fast Skipping) : beginner | High knees (montées de genoux) (2) |
| german_hang | Calixpert : advanced ; GymnasticBodies : intermediate | German hang (tenue) (6) |
| good_morning | FED : intermediate ; Wikipédia : exercice « controversé » (risque si mal exécuté) ; StrengthLevel homme 80 kg : intermédiaire ≈ 86 kg | Good mornings (5) |
| hack_squat | FED : beginner ; StrengthLevel homme 80 kg : intermédiaire ≈ 155 kg | Hack squat (3) |
| handstand_walk | Fitbod : advanced ; WorkoutLabs : avancé ; FED HSPU : expert | Handstand walk (marche en ATR) (8) |
| hip_thrust | FED : intermediate ; StrengthLevel homme ~77 kg : intermédiaire ≈ 191 kg | Hip thrust (3), Hip thrust une jambe (épaules sur une chaise) (4), Hip thrust unilatéral (4), Hip thrust barre lourd (7), Hip thrust une jambe lesté (7) |
| hollow | Fitness Volt : intermediate ; Peloton : intermediate–advanced | Hollow body hold (3), Hollow hold lesté (5) |
| hollow_groupe | beginner (régression ; sources du hollow : intermediate) | Hollow body groupé (2) |
| hollow_rocks | Hevy : intermediate ; BarBend : débutant à avancé selon progression | Hollow rocks (4) |
| hspu | FED : expert ; Wikipédia : version libre exige force + équilibre | HSPU négatives (mur) (6), HSPU kipping (7), Handstand push-ups (mur) (7), HSPU stricts en déficit (8), HSPU freestanding (progression) (9) |
| hyperextension | FED : beginner (banc) / intermediate (reverse) ; StrengthLevel homme ~77 kg : intermédiaire ≈ 30 reps | Hyperextensions (banc 45°) (2), Reverse hyper (3) |
| inchworm | FED : beginner ; ACE : advanced | Inchworms (2), Planche avec sortie (walkout) (3) |
| iso_dips | calixpert 90° hold : intermediate ; free-exercise-db : beginner (triceps) / intermediate (chest) | Dips isométriques mi-course (4), Isométrie bas de dip (5), Isométrie maximale (6) |
| jefferson | Fitness Volt : intermediate ; Legion : commencer à vide | Jefferson curl (6) |
| jumping_jacks | FED (Star Jump) : beginner | Jumping jacks (1) |
| kb_snatch | free-exercise-db : expert ; CrossFit : advanced | Kettlebell snatch (7) |
| kick_back_poulie | FED : intermediate ; Bodybuilding-Wizard : beginner to advanced | Kick-back fessiers poulie (2) |
| kickback | FED : beginner ; FitCraft : beginner-intermediate | Kickback triceps (2) |
| landmine_press | Aucun niveau donné (LiftVault : tous niveaux) ; FED jammer : intermediate | Landmine press (3) |
| landmine_rotation | Muscle & Strength : intermediate ; FED 180's : beginner | Landmine rotations (5) |
| leg_curl_machine | FED : beginner ; StrengthLevel intermédiaire ≈ 178 lb (170 lb, assis) | Leg curl (2) |
| leg_curl_sol | FED : beginner ; ACE : intermediate | Leg curl swiss ball (3), Leg curl sliders (4), Curl ischio glissé une jambe (serviette) (6) |
| leg_extension | FED : beginner ; StrengthLevel intermédiaire ≈ 214 lb | Leg extension (1) |
| lsit | calixpert : beginner ; GMB : plusieurs semaines de progression pour la tenue complète ; Wikipédia : base des équerres (V-sit puis manna plus durs) | L-sit (5), L-sit à la barre fixe (tenue) (5), Test max L-sit (5), L-sit au sol (tenue) (6) |
| lsit_tuck | calixpert : beginner ; étape 3 de la progression GMB | L-sit genoux fléchis au sol (3), L-sit tuck (tenue) (3) |
| lsit_une_jambe | calixpert : beginner ; étape 5 (single leg extension) de la progression GMB | L-sit une jambe (4) |
| man_maker | MuscleFitProgram : Advanced ; Experience Life : Advanced | Man makers (7) |
| manna | calisthenics.com : elite ; Wikipédia : plus dur que le V-sit | Manna progression (10) |
| marche | FED : beginner | Marche de récupération (1), Marche ou vélo très léger (1), Repos actif (1), Marche rapide (2), Tapis incliné (marche) (2) |
| marche_lestee | Cleveland Clinic : progression prudente pour débutants (5 lb puis +10 %/sem) ; FED marche : beginner | Marche lestée (ruck) (3) |
| mobilite_chevilles | ACE, FED : beginner | Mobilisation cheville genou au mur (1) |
| mobilite_complete | beginner (routine ; composantes FED/ACE beginner à intermediate) | Mobilité complète (1) |
| mobilite_hanches | Healthline : intermediate ; Cleveland Clinic : avancé | Mobilité hanches (90/90) (1), Pancake assis (écart facial) (4), Pancake à plat (poitrine au sol) (8) |
| mobilite_poignets | FED : beginner | Mobilité épaules + poignets (1), Wrist push-ups (poignets) (2) |
| mobilite_thoracique | ACE, FED : beginner | Mobilité thoracique (cat-cow, rotations) (1) |
| mollets | FED : beginner ; StrengthLevel intermédiaire ≈ 310 lb (machine) | Mollets debout (2), Mollets debout barre (2), Mollets sur presse (2) |
| mollets_assis | FED : beginner | Mollets assis (1) |
| mollets_unijambe | FED : intermediate (unilatéral haltère) ; wger sans niveau | Mollets unilatéraux sur marche (2) |
| monster_walk | FED : beginner ; Hinge Health : réglable (bande aux genoux plus facile, aux chevilles plus dure) | Marche latérale élastique (monster walk) (1) |
| mountain_climbers | FED : beginner ; MuscleWiki : Novice ; ACE : Advanced | Mountain climbers (3) |
| muscle_up | StrengthLevel (homme ~80 kg) : novice 2 reps, intermediate 7, advanced 11, elite 16 ; free-exercise-db : intermediate ; Wikipédia : intermédiaire à avancé, kipping avant strict | Muscle-up kipping (7), Muscle-up (8), Muscle-up lesté (9), Muscle-up lesté cluster (9), Muscle-up strict (9), Test max muscle-ups PdC (9), Muscle-up lesté — singles (10), Test 1RM Muscle-Up Lesté (10) |
| muscle_up_anneaux | Wikipédia : anneaux strict = avancé ; calixpert transition : beginner (exercice d'apprentissage) ; record 21 reps | Muscle-up aux anneaux (8), Muscle-up aux anneaux strict (9) |
| muscle_up_iso | null ; tenue en transition = avancé (position la plus faible du muscle-up) | Isométrie de transition muscle-up (7) |
| muscle_up_negatif | calixpert (assisté sol) : beginner ; négatif complet lesté : avancé | Excentrique de transition muscle-up (6), Négatif de muscle-up (6), Négatifs de muscle-up (6), Négatifs de muscle-up complets (6), Excentriques de transition LESTÉS (7), Muscle-up négatif lesté (8) |
| muscle_up_transition | calixpert : beginner (exercice d'apprentissage assisté) | Transition muscle-up assistée pieds au sol (4), Transition muscle-up à l'élastique (6), Transitions de muscle-up à l'élastique (6) |
| nordic | FED : intermediate ; Wikipédia : progression assistée (élastique) → complète | Nordic curl assisté (mains) (5), Nordic curl assisté élastique (5), Nordic curl (excentrique) (7), Nordic curl complet (9), Nordic curl lesté (10) |
| oiseau | FED : beginner (haltères, poulie), intermediate (assis penché) | Oiseau (élévations buste penché) (2), Oiseau à la poulie (2) |
| overhead_carry | Aucun niveau donné ; FED (sled overhead walk) : beginner | Overhead carry (4), Overhead carry sac lesté (5), Overhead carry barre (7) |
| pallof | FED : beginner | Pallof isométrique au partenaire ou à la serviette (1), Pallof press (2), Pallof press élastique (2) |
| pec_deck | FED : beginner | Pec deck (2) |
| pinch | FED : intermediate ; Muscle & Strength : intermediate | Pinch grip disques (tenue) (3), Plate pinch carry (3) |
| pistol | FED : expert ; ACE : intermediate (version orteils au sol) ; StrengthLevel homme 80 kg : intermédiaire ≈ 13 reps | Pistol squat (8), Pistol squat lesté (9), Pistol squat sauté (9) |
| pistol_assiste | Fitbod : beginner ; FED Smith Machine : intermediate ; ACE : intermediate | Pistol squat assisté (5) |
| pistol_box | FED : beginner (box haute) ; ACE : intermediate | Pistol squat sur box (6) |
| planche_bras_tendus | FED plank : beginner ; ACE front plank : intermediate | Gainage anti-rotation en planche (épaules) (3), Planche bras tendus + taps (3), Planche avec passage d'objet sous le corps (4), Planche bras et jambe opposés levés (4), Planche bras et jambe opposés (tenue) (7), Planche à levier long (mains avancées) (7), Planche à un bras (8), Planche superman (tenue) (9) |
| planche_coudes | FED : beginner ; ACE : intermediate ; StrengthLevel : temps (voir entrée) | Planche de gainage sur les coudes (2), Planche lestée (gainage) (4) |
| planche_genoux | beginner (régression ; ACE classe la planche latérale modifiée sur genou en Beginner) | Planche sur les genoux (1) |
| planche_laterale | FED : beginner ; ACE : intermediate (modifiée sur genou : beginner) | Planche latérale sur les genoux (1), Planche latérale (2), Planche latérale bras tendu (3), Planche latérale lestée (4), Planche latérale avec abduction de jambe (5), Planche latérale pieds surélevés (5), Planche latérale bras tendu lestée (7), Planche latérale étoile (7) |
| planche_lean | calixpert : beginner ; étape d'entrée de la planche | Planche lean à l'élastique (3), Planche lean (4) |
| planche_rkc | Fitness Volt : advanced | Planche RKC (coudes) (4) |
| planche_skill | FIG : straddle planche = A, full planche = C ; calixpert : tuck beginner, full advanced ; Wikipédia : frog stand → tuck → advanced tuck → straddle → full | Tuck planche (7), Planche advanced tuck (8), Planche straddle (9), Planche complète (10) |
| pogo | NIFS : échauffement, faible intensité ; aucune base ne note de niveau | Sauts de mollets (pogo) (3) |
| poignet_flexion | FED : beginner ; StrengthLevel intermédiaire ≈ 93 lb (barre, 170 lb) | Curl poignet (1), Extension poignet (1), Extension poignet barre (1), Travail poignet excentrique (haltère) (1) |
| poignet_rotation | ACE : beginner | Pronation / supination haltère (1) |
| pompe | FED : beginner ; ACE : intermediate ; StrengthLevel homme 80 kg : intermédiaire ≈ 39 reps | Pompes (3), Pompes PdC (3), Pompes pause au sol (3), Pompes prise large (3), Pompes sur les poings (3), Pompes tempo (3), Pompes déficit (poignées) (4), Pompes hindu (4), Pompes spiderman (4), Pompes élastique (4), Test max pompes PdC (4), Pompes aux anneaux (5), Pompes avec touchers d'épaules (5), Pompes lestées (5), Pompes lestées (lest ajouté) (5), Pompes aux anneaux RTO (6), Pompes lestées lourdes (7) |
| pompe_archer | NASM : advanced | Pompes archer (6), Pompes typewriter (7) |
| pompe_declinee | FED : beginner | Pompes déclinées (4), Pompes surélevées (pieds sur banc) (4) |
| pompe_diamant | FED : intermediate | Pompes prise serrée (4), Pompes diamant (5), Pompes diamant surélevées (6) |
| pompe_explosive | FED : beginner (au sol) / expert (sur kettlebells) | Pompes explosives (clap) (6), Pompes pliométriques (mains sur boxes) (7) |
| pompe_genoux | Régression de la pompe (Wikipédia) ; niveau débutant par déduction (aucune base ne la note) | Pompes à genoux (2) |
| pompe_inclinee | FED : beginner | Pompes inclinées (mains surélevées) (2) |
| pompe_mur | Régression la plus facile de la pompe (Wikipédia) ; aucune base ne la note | Pompes au mur (1) |
| pompe_pike | NASM : advanced ; FED : pas d'entrée | Pike hold (V inversé) (2), Pompes pike sur les genoux (3), Pike push-ups (4), Pike push-ups surélevés (pieds sur banc) (5) |
| pompe_pseudo | FitCraft : advanced ; wger : non noté | Pompes pseudo-planche (6) |
| pompe_un_bras | FED : intermediate (sous-évalué) | Pompes une main (progression) (7), Pompe à un bras (9) |
| pont_dorsal | GMB : avancé (pont complet) avec régressions (pont d'épaules, pont sur la tête) | Bridge (pont dorsal) (5), Pont dorsal une jambe (7), Descente en pont le long du mur (8) |
| pont_fessier | FED : beginner ; ACE : intermediate ; StrengthLevel homme 80 kg : intermédiaire ≈ 38 reps | Pont fessier au sol (1), Pont fessier marché (2), Pont fessier une jambe (3), Pont fessier une jambe pieds surélevés (4) |
| prehension | Aucun niveau ; les grippers sont gradués par résistance (kg) | Hand gripper (1) |
| presse | FED : beginner ; StrengthLevel homme 80 kg : intermédiaire ≈ 210 kg | Presse à cuisses (2) |
| pseudo_planche_hold | calixpert (planche lean) : beginner | Pseudo-planche hold (5) |
| pull_apart | FED : beginner | Pull-apart élastique (1) |
| pullover | FED : intermediate | Pull-over poulie (2) |
| push_press | FED : expert (barre) / intermediate (kettlebells) | Push press (5), Push press haltères (5), Push jerk (7) |
| relevé_jambes | FED : beginner ; ACE reverse crunch : intermediate ; Wikipédia : moderate ; StrengthLevel : reps | Crunchs inversés (2), Relevés de jambes au sol (3), Leg raises lestés (5), Relevés de jambes au sol avec élévation du bassin (5) |
| respiration | — | Bilan (1), Respiration / cohérence cardiaque (1), Contraste français (5) |
| rice_bucket | Aucun niveau ; progression par durée (Boulderflash : 2-3 × 30 s → 3-5 × 1 min) | Rice bucket (seau de riz) (1) |
| rotation_externe | FED : beginner ; Bodybuilding-Wizard : beginner to advanced | Rotations externes (par haltère) (1), Rotations externes élastique (1), Rotations internes élastique (1) |
| rowing_anneaux | FED : beginner | Face pulls aux anneaux (3), Rows aux anneaux (3), Rows aux sangles (TRX) (3), Rows une main anneaux (6), Archer rows anneaux (7) |
| rowing_appui | FED : beginner | Rowing haltère appui poitrine (2) |
| rowing_australien | FED : beginner ; Wikipédia : difficulté réglable par la hauteur de la barre | Tirage élastique horizontal (1), Tractions australiennes sous table genoux fléchis (1), Australian pull-ups (rows barre basse) (2), Rowing australien barre haute (2), Rowing à la serviette (porte) (2), Tractions australiennes pieds au sol (table) (2), Rows barre basse pieds surélevés (4), Tractions australiennes sous table pieds surélevés (4), Rowing à la serviette à une main (porte) (5), Rows archer barre basse (6), Rows archer sous table (6), Rowing inversé à un bras (barre basse) (7), Rowing inversé à un bras sous table (7), Rows australiens lestés (gilet) (7) |
| rowing_barre | FED : beginner ; ACE : advanced ; StrengthLevel homme 80 kg : intermédiaire ≈ 80 kg | Rowing T-bar (4), Rowing barre penché (4), Rowing Meadows (5), Rowing Pendlay (5) |
| rowing_halteres | FED : beginner (haltère) / intermediate (kettlebell) | Rowing haltère unilatéral (par haltère) (3), Rowing haltères penché (3), Rowing kettlebell (3), Rowing unilatéral haltère (3) |
| russian_twist | FED : intermediate ; StrengthLevel : reps | Russian twists (2), Russian twists lestés (3) |
| sandbag_carry | FitMetrics : intermediate | Sandbag carry (3), Bear hug carry sac lesté (4), Zercher carry sac lesté (5), Sandbag carry lourd (7) |
| saut | ACE : Beginner ; MuscleWiki : Beginner ; FED : beginner (long jump, tuck) / intermediate (jump squat) | Broad jumps (sauts en longueur) (4), Tuck jumps (5) |
| scap_pull | free-exercise-db et calixpert : beginner | Scapular pull-ups (2), Scapular pull-ups lestés (4) |
| scapular_pushup | MusclesWorked : beginner ; Physiopedia : progression mur → sol → lesté | Scapular push-ups (1), Serratus push-ups (protraction) (1) |
| sdt | FED : intermediate (barre), beginner (trap bar) ; ACE : advanced ; StrengthLevel homme 80 kg : intermédiaire ≈ 158 kg | Soulevé de terre kettlebell (2), Rack pulls (4), Soulevé de terre trap bar (4), Soulevé de terre (5), Soulevé de terre sumo (5), Test 1RM Soulevé de terre (6), Soulevé de terre en déficit (7) |
| sdt_roumain | FED : intermediate (barre) / beginner (haltères) ; StrengthLevel homme 80 kg : intermédiaire ≈ 127 kg | Soulevé de terre roumain haltères (3), Soulevé de terre roumain (4), Soulevé de terre jambes tendues (5) |
| sdt_unijambe | FED : intermediate ; ACE : advanced (poids de corps) ; StrengthLevel homme 80 kg : intermédiaire ≈ 67 kg (haltère) | Soulevé de terre sur une jambe au poids de corps (4), Soulevé de terre roumain une jambe sac lesté (5), Soulevé de terre unilatéral haltère (5), Soulevé de terre roumain une jambe haltères lourd (7) |
| shrimp_squat | FitnessVolt : intermediate ; dieringe : intermediate à advanced ; StrengthLevel shrimp squat non lisible | Shrimp squat (7), Shrimp squat avancé (pied tenu à deux mains) (9) |
| shrug | FED : beginner ; StrengthLevel intermédiaire ≈ 266 lb (170 lb) | Shrugs barre (2), Shrugs haltères (2) |
| side_bend | FED : beginner ; StrengthLevel : charge | Side bend haltère (2) |
| sissy_squat | FED : expert (lesté) ; Garage Gym Reviews : moderate–advanced ; StrengthLevel homme 80 kg : intermédiaire ≈ 21 reps | Sissy squat assisté (4), Sissy squat (6) |
| situp | FED : beginner ; StrengthLevel : reps | Sit-ups (2), Sit-ups butterfly (2), Sit-ups jambes tendues bras levés (4), Sit-ups GHD (6) |
| skater_squat | Inspire US et dieringe : intermediate à advanced | Skater squat (6) |
| skaters | FED : beginner ; ACE : Intermediate ; MuscleWiki (variante burpee) : Advanced | Skaters (3) |
| skin_the_cat | calixpert : advanced ; considéré comme étape d'entrée des leviers par Gymless | Skin the cat (6) |
| slam | FED : beginner ; MuscleWiki : Beginner | Slam ball (3) |
| sled_pull | FED : beginner ; Muscle & Strength : Beginner ; Fitbod : Beginner | Sled drag arrière (4), Sled pull (traîneau, corde) (4) |
| sled_push | FED : beginner | Sled push (4) |
| snatch | StrengthLevel (homme ~80 kg, 1RM) : beginner 36 kg, novice 54, intermediate 76, advanced 101, elite 128 ; free-exercise-db : intermediate (snatch) / expert (power, hang) | Snatch (arraché) (9) |
| sprint | FED : beginner (drills) ; pas de standard | HIIT course 30/30 (5), Shuttle runs (navettes) (5), Course — fractionné 200 m (6), Course — fractionné 400 m (6), Sprint (6), Sprint en côte (6), Foulées bondissantes (bounding) (7), Sprints répétés (10 × 50 m) (7) |
| squat_assiste | Fitbod : beginner ; programme.app : régression pour débutants ou personnes à mobilité réduite | Squat assisté (appui) (1) |
| squat_barre | FED : beginner (Barbell Squat) à expert (Zercher) ; ACE : advanced ; StrengthLevel homme 80 kg : intermédiaire ≈ 120 kg | Back squat (4), Squat 1 ¼ (5), Squat endurance @ 70 kg (5), Squat pause (5), Squat tempo (5), Squat Zercher (6), Squat — walkout lourd (6), Test 1RM Back Squat (6), Test max squat @ 70 kg (6) |
| squat_chaise | FED Chair Squat : beginner ; ACE bodyweight squat : beginner | Squat sur chaise (1) |
| squat_cosaque | Healthline : difficile pour débutants ; ACE side lunge : intermediate ; pas de standard StrengthLevel | Squat cosaque (4) |
| squat_gobelet | FED : beginner ; ACE : intermediate ; StrengthLevel homme ~77 kg : intermédiaire ≈ 40 kg | Squat gobelet (2), Squat sumo haltère (2), Sandbag squat (bear hug) (4) |
| squat_overhead | FED : expert ; StrengthLevel homme 80 kg : intermédiaire ≈ 77 kg | Squat overhead (7) |
| squat_pdc | FED : beginner ; ACE : beginner ; StrengthLevel homme 80 kg : intermédiaire ≈ 54 reps | Squat au poids de corps (2), Squat élastique (2) |
| squat_profond_tenu | beginner–intermediate (aucun niveau chiffré ; [P]rehab : dépend des restrictions cheville/hanche) | Squat profond tenu (2) |
| squat_saute | FED : intermediate ; ACE : beginner ; StrengthLevel homme ~77 kg : intermédiaire ≈ 33 reps | Squat sauté (4), Squat sauté lesté (6) |
| step_up | FED : intermediate (lesté) / beginner (poids de corps) ; ACE : beginner ; StrengthLevel step-up non lisible | Step-ups (2), Box step-overs (3), Step-ups lestés (3), Step-ups hauts (box) (4) |
| straight_arm_pulldown | FED : beginner ; SET FOR SET : intermediate-advanced | Straight-arm pulldown (2) |
| suitcase_carry | ACE : intermediate ; Bodybuilding-Wizard : débutant à avancé selon la charge | Suitcase carry (2), Suitcase carry sac lesté (3) |
| superman | FED, ACE : beginner | Superman W (1), Superman dynamique (1), Superman hold (1), Arch rocks (3) |
| support_hold | calixpert : beginner (barres) ; dieringe : advanced (anneaux) ; wger : pas de niveau | Support hold aux barres (2), Support hold anneaux/barres (3), Support hold lesté (4) |
| suspension_genoux | FED : beginner ; StrengthLevel : reps | Knee raises suspendu (3) |
| suspension_jambes | FED : expert ; StrengthLevel : reps | Leg raises suspendu (5), Leg raises lestés (suspendu) (7) |
| swing | FED : intermediate ; ACE : intermediate ; StrengthLevel kettlebell swing non lisible | Kettlebell swing (4), Kettlebell swing une main (5), Kettlebell swing lourd (deux mains) (7) |
| thruster | FED : intermediate ; MuscleWiki : Intermediate ; StrengthLevel : standards Beginner→Elite | Thruster haltères (5), Thruster (6), Thruster haltères lourd (7) |
| tibial | MusclesWorked : beginner | Tibialis raises (1) |
| tirage_horizontal_poulie | FED : beginner ; ACE : beginner | Tirage horizontal poulie (2), Tirage horizontal unilatéral poulie (2) |
| tirage_menton | StrengthLevel (homme ~80 kg, 1RM) : beginner 22 kg, novice 37, intermediate 57, advanced 81, elite 108 ; free-exercise-db : beginner | Tirage menton barre (3), Tirage menton haltères (3) |
| tirage_vertical_poulie | StrengthLevel (homme ~80 kg, 1RM) : beginner 45 kg, novice 62, intermediate 83, advanced 106, elite 130 ; ACE : intermediate ; free-exercise-db : beginner | Tirage élastique vertical (1), Tirage vertical prise neutre (2), Tirage vertical pronation (2), Tirage vertical supination (2), Tirage vertical unilatéral (3) |
| toes_to_bar | BarBend : advanced (strict) ; Fitness Volt : intermediate ; StrengthLevel : reps | Knees to elbows (5), Toes to bar (6), Toes to bar kipping (6), Toes to bar strict (7), Toes to bar strict tempo (8) |
| traction | StrengthLevel (homme ~80 kg) : novice 7 reps, intermediate 13, advanced 21, elite 29 ; ACE : intermediate ; free-exercise-db : beginner | Traction pause haute (5), Traction prise mixte (5), Traction prise neutre (5), Traction prise serrée (5), Traction pronation (5), Traction supination (5), Traction tempo (3 s excentrique) (5), Tractions PdC (5), Test max tractions PdC (6), Traction commando (6), Traction lestée (6), Traction lestée cluster (6), Traction lestée pause (6), Traction lestée tempo (6), Traction prise large (6), Chin-up lesté (7), Traction lestée élastique (accommodante) (7), Traction lestée — singles lourds (7), Traction à la serviette (7), Test 1RM Traction Lestée (8), Traction lestée lourde (8) |
| traction_anneaux | aucun standard spécifique aux anneaux ; se rapporter aux tractions (StrengthLevel) ; instabilité = plus dur qu'à la barre | Traction aux anneaux (5), Traction aux anneaux prise neutre (5) |
| traction_archer | dieringe : typewriter intermediate, archer plus dur ; wger sans niveau | Tirage bûcheron à la barre fixe (8), Traction archer (8), Traction autour du monde (8), Traction typewriter (8) |
| traction_assistee | free-exercise-db : beginner | Traction assistée élastique (3) |
| traction_explosive | calixpert : intermediate (box pour la sortie haute) | Traction explosive (7), Tractions explosives poitrine-barre (7), Traction haute explosive (high pull-up) (8) |
| traction_iso | calixpert 90° hold : advanced ; top hold (menton au-dessus) plus facile | Tirage isométrique à la serviette (1), Traction isométrique (menton au-dessus) (4), Traction isométrique 90° (5) |
| traction_kipping | Hevy : intermediate | Kipping pull-ups (6), Chest-to-bar kipping (7), Butterfly pull-ups (8) |
| traction_l | calixpert hanging L-sit hold : intermediate ; traction L plus dure qu'une traction | Traction L-sit (7) |
| traction_negative | régression de la traction (Wikipédia liste 'eccentric/negative' parmi les variantes) ; lestée = surcharge excentrique avancée | Traction négative lente (3), Traction excentrique lestée (6) |
| traction_poitrine | calixpert explosive/high pull-ups : intermediate ; plus dur qu'une traction menton (amplitude) | Traction poitrine-barre (6), Traction sternum (8) |
| traction_un_bras | free-exercise-db : expert ; GorNation : skill de tirage le plus avancé | Traction une main (assistée) (9), Traction une main (négative) (9) |
| turkish | free-exercise-db : intermediate ; Physiopedia et Hevy : advanced | Turkish get-up (6) |
| v_ups | Hevy, Weight Training Guide : advanced ; Fitness Volt : intermediate ; FED jackknife : beginner | Tuck-ups (3), V-ups (4) |
| vsit | dieringe : advanced ; Wikipédia : plus dur que le L-sit, moins que le manna | V-sit progression (8), V-sit (tenue) (9) |
| wall_ball | MuscleWiki : Beginner ; StrengthLevel : standards Beginner→Elite | Wall balls (4) |
| wall_sit | Aucune base ne donne de niveau ; Wikipédia le décrit comme très intense à tenir longtemps ; StrengthLevel wall sit non lisible | Wall sit (chaise) (2) |
| wall_slides | beginner (exercice de rééducation) | Wall slides (glissés au mur) (1) |
| wall_walk | StrengthLog : advanced ; calixpert : beginner (désaccord) | Wall walks partiels (mi-hauteur) (3), Wall walks (5) |
| windmill | FED : intermediate ; BarBend : intermediate–advanced ; Fitness Volt : intermediate | Kettlebell windmill (6) |
| windshield | MuscleWiki : intermediate | Around the world (suspendu) (8), Windshield wipers (essuie-glaces) (8) |
| woodchop | FED : beginner ; StrengthLevel : charge | Woodchop poulie (3) |
| wrist_roller | FED : beginner ; StrengthLog : intermediate-advanced | Enrouleur de poignet (wrist roller) (3) |
| ytw | 1pixelworkout : beginner ; FED (rear delt) : intermediate | Prone Y raises (2), YTW allongé (2), YTW à plat ventre (banc incliné) (2) |

### 3.1 Exercices ajoutés en L9R (couverture de la matrice)

Variantes d'archétypes sourcés ; leur difficulté suit la progression usuelle de la variante et mérite confirmation :

- Pont fessier une jambe pieds surélevés (`pont-fessier-une-jambe-pieds-sureleves`) : type Charnière de hanche, niveau 4, matériel support_stable
- Soulevé de terre roumain une jambe sac lesté (`souleve-de-terre-roumain-une-jambe-sac-leste`) : type Charnière de hanche, niveau 5, matériel sac_leste
- Soulevé de terre roumain une jambe haltères lourd (`souleve-de-terre-roumain-une-jambe-halteres-lourd`) : type Charnière de hanche, niveau 7, matériel halteres
- Soulevé de terre en déficit (`souleve-de-terre-en-deficit`) : type Charnière de hanche, niveau 7, matériel barre, disques
- Hip thrust barre lourd (`hip-thrust-barre-lourd`) : type Charnière de hanche, niveau 7, matériel barre, banc
- Hip thrust une jambe lesté (`hip-thrust-une-jambe-leste`) : type Charnière de hanche, niveau 7, matériel support_stable, lest
- Kettlebell swing lourd (deux mains) (`kettlebell-swing-lourd-deux-mains`) : type Charnière de hanche, niveau 7, matériel kettlebell
- Tuck jump burpees (`tuck-jump-burpees`) : type Conditionnement, niveau 7, matériel aucun
- Burpees Navy Seal (`burpees-navy-seal`) : type Conditionnement, niveau 7, matériel aucun
- Thruster haltères lourd (`thruster-halteres-lourd`) : type Conditionnement, niveau 7, matériel halteres
- Burpees pull-up lestés (gilet) (`burpees-pull-up-lestes-gilet`) : type Conditionnement, niveau 8, matériel lest, barre_fixe
- Fentes bulgares sautées (`fentes-bulgares-sautees`) : type Fente, niveau 7, matériel support_stable
- Squat bulgare haltères lourd (`squat-bulgare-halteres-lourd`) : type Fente, niveau 7, matériel halteres, support_stable
- Squat bulgare gilet lesté lourd (`squat-bulgare-gilet-leste-lourd`) : type Fente, niveau 7, matériel support_stable, lest
- Fentes arrière en déficit lestées (`fentes-arriere-en-deficit-lestees`) : type Fente, niveau 7, matériel halteres, support_stable
- Fentes marchées lestées lourdes (gilet) (`fentes-marchees-lestees-lourdes-gilet`) : type Fente, niveau 7, matériel lest
- Montée en ATR contre le mur (kick-up) (`montee-en-atr-contre-le-mur-kick-up`) : type Figure dynamique, niveau 3, matériel mur
- Wall walks partiels (mi-hauteur) (`wall-walks-partiels-mi-hauteur`) : type Figure dynamique, niveau 3, matériel mur
- Press to handstand (pike press) (`press-to-handstand-pike-press`) : type Figure dynamique, niveau 9, matériel aucun
- Frog stand (crow) (`frog-stand-crow`) : type Figure statique, niveau 3, matériel aucun
- L-sit genoux fléchis au sol (`l-sit-genoux-flechis-au-sol`) : type Figure statique, niveau 3, matériel aucun
- Sit-ups jambes tendues bras levés (`sit-ups-jambes-tendues-bras-leves`) : type Flexion du tronc, niveau 4, matériel aucun
- Relevés de jambes au sol avec élévation du bassin (`releves-de-jambes-au-sol-avec-elevation-du-bassin`) : type Flexion du tronc, niveau 5, matériel aucun
- Toes to bar strict tempo (`toes-to-bar-strict-tempo`) : type Flexion du tronc, niveau 8, matériel barre_fixe
- Planche à levier long (mains avancées) (`planche-a-levier-long-mains-avancees`) : type Gainage anti-extension, niveau 7, matériel aucun
- Body saw amplitude complète (`body-saw-amplitude-complete`) : type Gainage anti-extension, niveau 7, matériel serviette
- Dragon flag négatif (support au sol) (`dragon-flag-negatif-support-au-sol`) : type Gainage anti-extension, niveau 7, matériel support_stable
- Planche superman (tenue) (`planche-superman-tenue`) : type Gainage anti-extension, niveau 9, matériel aucun
- Dragon flag (support au sol) (`dragon-flag-support-au-sol`) : type Gainage anti-extension, niveau 9, matériel support_stable
- Planche latérale pieds surélevés (`planche-laterale-pieds-sureleves`) : type Gainage anti-flexion latérale, niveau 5, matériel support_stable
- Planche latérale étoile (`planche-laterale-etoile`) : type Gainage anti-flexion latérale, niveau 7, matériel aucun
- Copenhagen plank à levier long (`copenhagen-plank-a-levier-long`) : type Gainage anti-flexion latérale, niveau 7, matériel support_stable
- Planche latérale bras tendu lestée (`planche-laterale-bras-tendu-lestee`) : type Gainage anti-flexion latérale, niveau 7, matériel lest
- Planche avec passage d'objet sous le corps (`planche-avec-passage-d-objet-sous-le-corps`) : type Gainage anti-rotation, niveau 4, matériel aucun
- Pompes avec touchers d'épaules (`pompes-avec-touchers-d-epaules`) : type Gainage anti-rotation, niveau 5, matériel aucun
- Planche bras et jambe opposés (tenue) (`planche-bras-et-jambe-opposes-tenue`) : type Gainage anti-rotation, niveau 7, matériel aucun
- Planche à un bras (`planche-a-un-bras`) : type Gainage anti-rotation, niveau 8, matériel aucun
- Extension triceps au poids de corps (mains au sol) (`extension-triceps-au-poids-de-corps-mains-au-sol`) : type Isolation (mono-articulaire), niveau 4, matériel aucun
- Nordic curl assisté (mains) (`nordic-curl-assiste-mains`) : type Isolation (mono-articulaire), niveau 5, matériel support_stable
- Curl ischio glissé une jambe (serviette) (`curl-ischio-glisse-une-jambe-serviette`) : type Isolation (mono-articulaire), niveau 6, matériel serviette
- Extension triceps au poids de corps pieds surélevés (`extension-triceps-au-poids-de-corps-pieds-sureleves`) : type Isolation (mono-articulaire), niveau 7, matériel support_stable
- Nordic curl complet (`nordic-curl-complet`) : type Isolation (mono-articulaire), niveau 9, matériel support_stable
- Nordic curl lesté (`nordic-curl-leste`) : type Isolation (mono-articulaire), niveau 10, matériel support_stable, lest
- Foulées bondissantes (bounding) (`foulees-bondissantes-bounding`) : type Locomotion, niveau 7, matériel espace_exterieur
- Sprints répétés (10 × 50 m) (`sprints-repetes-10-50-m`) : type Locomotion, niveau 7, matériel espace_exterieur
- Bear crawl lesté (gilet) (`bear-crawl-leste-gilet`) : type Locomotion, niveau 7, matériel lest, sol_degage
- Pancake assis (écart facial) (`pancake-assis-ecart-facial`) : type Mobilité, niveau 4, matériel aucun
- Pont dorsal une jambe (`pont-dorsal-une-jambe`) : type Mobilité, niveau 7, matériel aucun
- Pancake à plat (poitrine au sol) (`pancake-a-plat-poitrine-au-sol`) : type Mobilité, niveau 8, matériel aucun
- Descente en pont le long du mur (`descente-en-pont-le-long-du-mur`) : type Mobilité, niveau 8, matériel mur
- Suitcase carry sac lesté (`suitcase-carry-sac-leste`) : type Portés, niveau 3, matériel sac_leste
- Farmer walk sacs lestés (`farmer-walk-sacs-lestes`) : type Portés, niveau 3, matériel sac_leste
- Bear hug carry sac lesté (`bear-hug-carry-sac-leste`) : type Portés, niveau 4, matériel sac_leste
- Rack carry kettlebells (`rack-carry-kettlebells`) : type Portés, niveau 4, matériel kettlebell
- Overhead carry sac lesté (`overhead-carry-sac-leste`) : type Portés, niveau 5, matériel sac_leste
- Zercher carry sac lesté (`zercher-carry-sac-leste`) : type Portés, niveau 5, matériel sac_leste
- Farmer walk haltères lourds (`farmer-walk-halteres-lourds`) : type Portés, niveau 7, matériel halteres
- Sandbag carry lourd (`sandbag-carry-lourd`) : type Portés, niveau 7, matériel sac_leste
- Overhead carry barre (`overhead-carry-barre`) : type Portés, niveau 7, matériel barre
- Farmer walk très lourd (trap bar) (`farmer-walk-tres-lourd-trap-bar`) : type Portés, niveau 7, matériel barre
- HSPU négatives (mur) (`hspu-negatives-mur`) : type Poussée verticale, niveau 6, matériel mur
- Shrimp squat avancé (pied tenu à deux mains) (`shrimp-squat-avance-pied-tenu-a-deux-mains`) : type Squat, niveau 9, matériel aucun
- Pistol squat sauté (`pistol-squat-saute`) : type Squat, niveau 9, matériel aucun
- Tractions australiennes sous table genoux fléchis (`tractions-australiennes-sous-table-genoux-flechis`) : type Tirage horizontal, niveau 1, matériel support_stable
- Tractions australiennes sous table pieds surélevés (`tractions-australiennes-sous-table-pieds-sureleves`) : type Tirage horizontal, niveau 4, matériel support_stable
- Rowing à la serviette à une main (porte) (`rowing-a-la-serviette-a-une-main-porte`) : type Tirage horizontal, niveau 5, matériel serviette
- Rows archer sous table (`rows-archer-sous-table`) : type Tirage horizontal, niveau 6, matériel support_stable
- Rowing inversé à un bras sous table (`rowing-inverse-a-un-bras-sous-table`) : type Tirage horizontal, niveau 7, matériel support_stable
- Rowing inversé à un bras (barre basse) (`rowing-inverse-a-un-bras-barre-basse`) : type Tirage horizontal, niveau 7, matériel barre_basse
- Rows australiens lestés (gilet) (`rows-australiens-lestes-gilet`) : type Tirage horizontal, niveau 7, matériel barre_basse, lest

## 4. Non-conformités détectées dans la base v1 (P2)

Aucune entrée n'a été supprimée. Correction proposée : voir la fiche de l'exercice.

- **Ab wheel** (`ab-wheel`) : Matériel v1 « poids de corps » alors que l'exercice nécessite : roue abdominale.
- **Ab wheel debout** (`ab-wheel-debout`) : Matériel v1 « poids de corps » : une roue est nécessaire.
- **Assault bike** (`assault-bike`) : Matériel v1 « poids de corps » : ergomètre nécessaire.
- **Bilan** (`bilan`) : Entrée de suivi (report de résultats), pas un exercice.
- **Contraste français** (`contraste-francais`) : Méthode d'entraînement (enchaînement lourd puis explosif), pas un exercice ; le programme l'associe au squat et au muscle-up.
- **Corde à sauter** (`corde-a-sauter`) : Matériel v1 « poids de corps » : corde nécessaire.
- **Crunchs lestés** (`crunchs-lestes`) : Matériel v1 « poids de corps » alors que l'exercice nécessite : disques.
- **Dead-hang lesté ou PdC** (`dead-hang-leste-ou-pdc`) : Nom ambigu (« lesté ou PdC ») : deux modes de charge dans une seule entrée.
- **Dips assistés élastique** (`dips-assistes-elastique`) : Matériel v1 « élastique » seul : les barres parallèles sont aussi nécessaires.
- **Dips aux anneaux** (`dips-aux-anneaux`) : Groupe v1 « dos, pectoraux » : le dos n'est pas moteur.
- **Dragon flag (progression)** (`dragon-flag-progression`) : Matériel v1 « poids de corps » alors que l'exercice nécessite : banc de musculation.
- **Dragon flag complet** (`dragon-flag-complet`) : Matériel v1 « poids de corps » alors que l'exercice nécessite : banc de musculation.
- **Dragon flag négatif** (`dragon-flag-negatif`) : Matériel v1 « poids de corps » alors que l'exercice nécessite : banc de musculation.
- **Élévations en ATR (tenue)** (`elevations-en-atr-tenue`) : Intitulé imprécis : interprété comme montées en ATR contre le mur avec tenue.
- **Fentes marchées (par haltère)** (`fentes-marchees-par-haltere`) : Matériel v1 « poids de corps » alors que l'exercice est chargé en haltères.
- **Foam roller (auto-massage)** (`foam-roller-auto-massage`) : Matériel v1 « poids de corps » alors que l'exercice nécessite : rouleau de massage.
- **Good mornings** (`good-mornings`) : Groupe v1 « quadriceps, fessiers » : les moteurs sont les ischio-jambiers et les érecteurs.
- **Hand gripper** (`hand-gripper`) : Matériel v1 « poids de corps » : pince de préhension nécessaire.
- **HIIT court** (`hiit-court`) : Format de séance générique sans exercice défini ; représenté par une pose de burpee.
- **HSPU stricts en déficit** (`hspu-stricts-en-deficit`) : Matériel v1 « poids de corps » alors que l'exercice nécessite : poignées de pompes ou parallettes.
- **Human flag (drapeau)** (`human-flag-drapeau`) : Matériel v1 « poids de corps » : un poteau vertical ou un espalier est nécessaire.
- **Human flag tuck** (`human-flag-tuck`) : Matériel v1 « poids de corps » alors que l'exercice nécessite : poteau ou espalier vertical.
- **Isométrie maximale** (`isometrie-maximale`) : Intitulé générique : le programme l'emploie pour deux positions (bas de dip, transition de muscle-up), séparées en v2.
- **Leg curl swiss ball** (`leg-curl-swiss-ball`) : Matériel v1 « poids de corps » alors que l'exercice nécessite : ballon de gymnastique.
- **Leg raises lestés** (`leg-raises-lestes`) : Matériel v1 « poids de corps » alors que l'exercice nécessite : haltères.
- **Leg raises suspendu** (`leg-raises-suspendu`) : Matériel v1 « poids de corps » : barre fixe nécessaire.
- **Marche ou vélo très léger** (`marche-ou-velo-tres-leger`) : Deux activités dans une seule entrée ; consigne de récupération plus qu'exercice.
- **Mobilité complète** (`mobilite-complete`) : Routine générique sans contenu défini.
- **Mobilité épaules + poignets** (`mobilite-epaules-poignets`) : Matériel v1 « haltères » pour une routine de mobilité sans charge.
- **Nordic curl (excentrique)** (`nordic-curl-excentrique`) : Groupe v1 « quadriceps, fessiers » : le moteur est l'ischio-jambier.
- **Pallof press** (`pallof-press`) : Matériel v1 « poids de corps » alors que l'exercice nécessite : poulie.
- **Planche de gainage sur les coudes** (`planche-gainage`) : Intitulé ambigu avec la figure « planche » du street workout ; renommé en v2.
- **Pompes aux anneaux** (`pompes-aux-anneaux`) : Groupe v1 « dos, pectoraux » : le dos n'est pas moteur.
- **Pompes déficit (poignées)** (`pompes-deficit-poignees`) : Matériel v1 « poids de corps » alors que l'exercice nécessite : poignées de pompes ou parallettes.
- **Pompes lestées** (`pompes-lestees`) : Matériel v1 « poids de corps » : lest nécessaire.
- **Pompes lestées (lest ajouté)** (`pompes-lestees-lest-ajoute`) : Matériel v1 « poids de corps » alors que l'exercice nécessite : lest (gilet, ceinture et disques).
- **Pompes une main (progression)** (`pompes-une-main-progression`) : Intitulé « progression » sans étape précise ; interprété comme pompe à un bras mains surélevées.
- **Rameur** (`rameur`) : Matériel v1 « poids de corps » : ergomètre nécessaire.
- **Repos actif** (`repos-actif`) : Consigne de repos, pas un exercice.
- **Rice bucket (seau de riz)** (`rice-bucket-seau-de-riz`) : Matériel v1 « poids de corps » : un seau de riz est nécessaire.
- **Rowing haltère unilatéral (par haltère)** (`rowing-haltere-unilateral-par-haltere`) : Matériel v1 « barre » pour un rowing à un haltère.
- **Squat endurance @ 70 kg** (`squat-endurance-70-kg`) : Charge absolue (70 kg) inscrite dans le nom : spécifique au propriétaire.
- **Support hold anneaux/barres** (`support-hold-anneaux-barres`) : Deux supports dans une même entrée.
- **Test max squat @ 70 kg** (`test-max-squat-70-kg`) : Charge absolue (70 kg) inscrite dans le nom : spécifique au propriétaire.
- **Tirage menton haltères** (`tirage-menton-halteres`) : Groupe v1 « dos » : moteurs deltoïdes et trapèzes.
- **Traction lestée élastique (accommodante)** (`traction-lestee-elastique-accommodante`) : Matériel v1 « élastique » seul : barre fixe et lest nécessaires.
- **V-sit progression** (`v-sit-progression`) : Intitulé « progression » sans étape précise.
- **Traction lestée lourde** (`traction-lestee-lourde`) : Entrée de palier (lest ≥ 25 % du poids de corps) utilisée uniquement comme étape d'arbre.
- **Pompes lestées lourdes** (`pompes-lestees-lourdes`) : Entrée de palier (lest ≥ 20 % du poids de corps) utilisée uniquement comme étape d'arbre.
- **Dips lestés lourds** (`dips-lestes-lourds`) : Entrée de palier (lest ≥ 30 % du poids de corps) utilisée uniquement comme étape d'arbre.

## 5. Doublons signalés (P2)

Le générateur n'utilise que l'entrée canonique ; l'entrée doublon reste pour l'historique des séances.

- Assault bike → Echo bike (calories)
- Curl marteau (par haltère) → Curl marteau
- Dip → Dips
- Dip Lesté → Dips lestés
- Dips PdC → Dips
- Élévations latérales (par haltère) → Élévations latérales
- Extension corde → Extension triceps poulie corde
- Extension triceps couché (barre EZ) → Barre au front EZ
- Fentes marchées (par haltère) → Fentes marchées haltères
- Isométrie maximale → Isométrie bas de dip
- Négatif de muscle-up → Négatifs de muscle-up
- Négatifs de muscle-up complets → Négatifs de muscle-up
- Pompes lestées (lest ajouté) → Pompes lestées
- Pompes PdC → Pompes
- Pompes surélevées (pieds sur banc) → Pompes déclinées
- Rowing haltère unilatéral (par haltère) → Rowing unilatéral haltère
- Serratus push-ups (protraction) → Scapular push-ups
- Squat bulgare haltères → Fentes bulgares
- Traction aux anneaux prise neutre → Traction aux anneaux
- Tractions PdC → Traction pronation
- Transition muscle-up à l'élastique → Transitions de muscle-up à l'élastique
- YTW allongé → YTW à plat ventre (banc incliné)

## 6. Démonstrations (P3)

Chaque image clé est calculée par cinématique directe depuis des angles articulaires de référence, puis contrôlée automatiquement (longueurs, amplitudes, contacts, sol, appui, accessoires, interpolation) et visuellement (planches `planches/*.png`). Limites du modèle à connaître :

- Le rachis est un segment rigide : cambrures et enroulements (pont, cat-cow, Jefferson curl, dragon flag) sont schématisés.
- Vue de profil ou de face uniquement : les gestes hors du plan sont projetés ou réduits à une position de départ (statut `statique`).
- Les épaules ne s'élèvent pas et les omoplates ne bougent pas : shrugs, tractions scapulaires et dépression d'épaule sont représentés par le déplacement de la charge ou du corps.
- La main est un segment rigide : en vue de face elle prolonge l'avant-bras (planche latérale bras tendu).
- La longueur bras + main du modèle place l'épaule à 0,33 de la taille au-dessus d'un appui manuel : les L-sit au sol montrent le bassin très près du sol.

### 6.1 Démonstrations indisponibles

- Butterfly pull-ups (`butterfly-pull-ups`) : kipping (balancier) non modélisé : voir la traction stricte
- Chest-to-bar kipping (`chest-to-bar-kipping`) : kipping (balancier) non modélisé : voir la traction stricte
- Clamshell élastique (`clamshell-elastique`) : couché sur le côté, abduction de hanche : hors du plan des vues disponibles
- Cuban press (`cuban-press`) : mouvement en trois temps avec rotation externe : aucun gabarit fidèle
- Descente en pont le long du mur (`descente-en-pont-le-long-du-mur`) : descente progressive le long du mur : aucun gabarit fidèle (le pont final est montré par « Bridge »)
- Écarté poulie vis-à-vis (`ecarte-poulie-vis-a-vis`) : écarté à la poulie : mouvement dans le plan frontal, aucun gabarit fidèle
- Kick-back fessiers poulie (`kick-back-fessiers-poulie`) : aucun gabarit fidèle (extension de hanche à la poulie)
- Kipping pull-ups (`kipping-pull-ups`) : kipping (balancier) non modélisé : voir la traction stricte
- Manna progression (`manna-progression`) : figure très spécifique (jambes au-delà des mains) : aucun gabarit fidèle
- Marche latérale élastique (monster walk) (`marche-laterale-elastique-monster-walk`) : marche latérale avec élastique : hors du plan de la vue
- Mobilité complète (`mobilite-complete`) : routine composée de plusieurs mouvements : pas de démonstration unique
- Mobilité hanches (90/90) (`mobilite-hanches-90-90`) : rotations de hanche assis (90/90) : geste hors du plan de la vue, aucun gabarit fidèle
- Muscle-up kipping (`muscle-up-kipping`) : élan (kip) et balancier non modélisés : voir le muscle-up strict
- Pompe à un bras (`pompe-a-un-bras`) : appui asymétrique : non représentable de profil
- Pompes archer (`pompes-archer`) : geste asymétrique dans le plan frontal : non représentable de profil
- Pompes typewriter (`pompes-typewriter`) : geste asymétrique dans le plan frontal : non représentable de profil
- Pompes une main (progression) (`pompes-une-main-progression`) : appui sur une seule main : non représentable de profil (le gabarit incliné à deux mains serait trompeur)
- Press to handstand (pike press) (`press-to-handstand-pike-press`) : montée en ATR par compression : aucun gabarit fidèle (transition complexe)

### 6.2 Démonstrations statiques (position de départ seulement)

- Abducteurs machine (`abducteurs-machine`) : geste hors du plan de la vue : position de départ seulement
- Adducteurs machine (`adducteurs-machine`) : geste hors du plan de la vue : position de départ seulement
- Bear hug carry sac lesté (`bear-hug-carry-sac-leste`) : sac contre la poitrine non dessiné : porté de base montré
- Bilan (`bilan`) : geste hors du plan de la vue : position de départ seulement
- Burpees Navy Seal (`burpees-navy-seal`) : genoux-coudes non représentés : burpee de base montré
- Contraste français (`contraste-francais`) : geste hors du plan de la vue : position de départ seulement
- Écarté haltères (`ecarte-halteres`) : geste hors du plan de la vue : position de départ seulement
- Enrouleur de poignet (wrist roller) (`enrouleur-de-poignet-wrist-roller`) : geste hors du plan de la vue : position de départ seulement
- Extensions de doigts élastique (`extensions-de-doigts-elastique`) : geste hors du plan de la vue : position de départ seulement
- Farmer hold (tenue) (`farmer-hold-tenue`) : geste hors du plan de la vue : position de départ seulement
- Hand gripper (`hand-gripper`) : geste hors du plan de la vue : position de départ seulement
- Handstand walk (marche en ATR) (`handstand-walk-marche-en-atr`) : geste hors du plan de la vue : position de départ seulement
- Montée en ATR contre le mur (kick-up) (`montee-en-atr-contre-le-mur-kick-up`) : lancer de jambe non modélisé : position finale (ATR dos au mur) montrée
- Pancake à plat (poitrine au sol) (`pancake-a-plat-poitrine-au-sol`) : écart des jambes hors du plan : flexion avant assise montrée
- Pancake assis (écart facial) (`pancake-assis-ecart-facial`) : écart des jambes hors du plan : flexion avant assise montrée
- Pec deck (`pec-deck`) : geste hors du plan de la vue : position de départ seulement
- Pinch grip disques (tenue) (`pinch-grip-disques-tenue`) : geste hors du plan de la vue : position de départ seulement
- Planche avec passage d'objet sous le corps (`planche-avec-passage-d-objet-sous-le-corps`) : passage d'objet hors du plan de la vue : planche de départ seulement
- Plate pinch carry (`plate-pinch-carry`) : geste hors du plan de la vue : position de départ seulement
- Pompes avec touchers d'épaules (`pompes-avec-touchers-d-epaules`) : touchers d'épaules hors du plan : la pompe est montrée, pas le toucher
- Pull-apart élastique (`pull-apart-elastique`) : geste hors du plan de la vue : position de départ seulement
- Rack carry kettlebells (`rack-carry-kettlebells`) : position rack non dessinée : porté de base montré
- Respiration / cohérence cardiaque (`respiration-coherence-cardiaque`) : geste hors du plan de la vue : position de départ seulement
- Rotations externes élastique (`rotations-externes-elastique`) : geste hors du plan de la vue : position de départ seulement
- Rotations externes (par haltère) (`rotations-externes-par-haltere`) : geste hors du plan de la vue : position de départ seulement
- Rotations internes élastique (`rotations-internes-elastique`) : geste hors du plan de la vue : position de départ seulement
- Russian twists (`russian-twists`) : geste hors du plan de la vue : position de départ seulement
- Russian twists lestés (`russian-twists-lestes`) : geste hors du plan de la vue : position de départ seulement
- Scapular push-ups (`scapular-push-ups`) : geste hors du plan de la vue : position de départ seulement
- Serratus push-ups (protraction) (`serratus-push-ups-protraction`) : geste hors du plan de la vue : position de départ seulement
- Shrugs barre (`shrugs-barre`) : geste hors du plan de la vue : position de départ seulement
- Shrugs haltères (`shrugs-halteres`) : geste hors du plan de la vue : position de départ seulement
- Tirage isométrique à la serviette (`tirage-isometrique-a-la-serviette`) : geste hors du plan de la vue : position de départ seulement
- Zercher carry sac lesté (`zercher-carry-sac-leste`) : portée dans le pli des coudes non dessinée : porté de base montré

### 6.3 Gabarits avec amplitudes étendues (figures avancées, autorisées explicitement)

- `assis.leg_press` : hanche [-30, 150]
- `assis.pulldown` : epaule [-70, 195]
- `assis_sol.flexion` : hanche [-30, 160]
- `atr.dos_mur` : cou [-60, 80]
- `atr.frog` : cou [-60, 80], hanche [-30, 150], genou [-5, 160]
- `atr.hspu` : cou [-60, 80]
- `atr.hspu_deficit` : cou [-60, 80]
- `atr.hspu_libre` : cou [-60, 80]
- `atr.libre` : cou [-60, 80]
- `atr.poitrine_mur` : cou [-60, 80]
- `atr.taps` : cou [-60, 80]
- `atr.wall_walk` : cou [-60, 80], poignet [-90, 100]
- `banc.barre_front` : epaule [-70, 195]
- `banc.couche` : epaule [-70, 195]
- `banc.ecarte` : epaule [-70, 195]
- `banc.floor` : epaule [-70, 195]
- `banc.hyperextension` : hanche [-30, 150], cou [-60, 80]
- `banc.incline` : epaule [-70, 195]
- `banc.pause` : epaule [-70, 195]
- `cardio.jacks` : hanche_abd [-30, 100]
- `debout.ab_wheel` : epaule [-70, 195]
- `debout.cheville` : cheville [-60, 45]
- `debout.dislocation` : epaule [-70, 215]
- `debout.etirement_post` : hanche [-30, 150]
- `dips.anneaux` : epaule [-90, 195]
- `dips.banc` : epaule [-90, 195]
- `dips.banc_genoux` : epaule [-90, 195]
- `dips.barre_fixe` : epaule [-90, 195]
- `dips.barres` : epaule [-90, 195]
- `dips.iso_bas` : epaule [-90, 195]
- `dips.support` : epaule [-90, 195]
- `dos_au_sol.bridge` : epaule [-170, 195], cou [-60, 80], hanche [-45, 160], poignet [-95, 108]
- `dos_au_sol.bridge_unijambe` : epaule [-170, 195], cou [-60, 80], hanche [-45, 160], poignet [-95, 108]
- `dos_au_sol.crunch` : epaule [-170, 195], cou [-60, 80], hanche [-45, 160], poignet [-95, 108]
- `dos_au_sol.dead_bug` : epaule [-170, 195], cou [-60, 80], hanche [-45, 160], poignet [-95, 108]
- `dos_au_sol.dragon_flag` : epaule [-170, 195], cou [-60, 80], hanche [-45, 160], poignet [-95, 108]
- `dos_au_sol.flutter` : epaule [-170, 195], cou [-60, 80], hanche [-45, 160], poignet [-95, 108]
- `dos_au_sol.hollow` : epaule [-170, 195], cou [-60, 80], hanche [-45, 160], poignet [-95, 108]
- `dos_au_sol.hollow_rocks` : epaule [-170, 195], cou [-60, 80], hanche [-45, 160], poignet [-95, 108]
- `dos_au_sol.hollow_tuck` : epaule [-170, 195], cou [-60, 80], hanche [-45, 160], poignet [-95, 108]
- `dos_au_sol.leg_raise` : epaule [-170, 195], cou [-60, 80], hanche [-45, 160], poignet [-95, 108]
- `dos_au_sol.situp` : epaule [-170, 195], cou [-60, 80], hanche [-45, 160], poignet [-95, 108]
- `dos_au_sol.situp_jambes_tendues` : epaule [-170, 195], cou [-60, 80], hanche [-45, 160], poignet [-95, 108]
- `dos_au_sol.twist` : epaule [-170, 195], cou [-60, 80], hanche [-45, 160], poignet [-95, 108]
- `dos_au_sol.vup` : epaule [-170, 195], cou [-60, 80], hanche [-45, 160], poignet [-95, 108]
- `drapeau.full` : epaule_abd [-10, 200], hanche_abd [-30, 100]
- `drapeau.straddle` : epaule_abd [-10, 200], hanche_abd [-30, 100]
- `drapeau.tuck` : epaule_abd [-10, 200], hanche_abd [-30, 100]
- `drapeau.vertical` : epaule_abd [-10, 200], hanche_abd [-30, 100]
- `ergo.rameur` : epaule [-70, 195]
- `ergo.skierg` : epaule [-70, 195]
- `ergo.velo` : epaule [-70, 195]
- `face.windmill` : hanche [-30, 150]
- `genoux.ab_wheel` : epaule [-70, 195]
- `genoux.hip_flexor` : epaule [-70, 195], cou [-60, 80], hanche [-45, 160]
- `genoux.nordic` : epaule [-70, 195], cou [-60, 80], hanche [-45, 160]
- `lancer.slam` : cheville [-60, 45]
- `lancer.wall_ball` : cheville [-60, 45]
- `levier.back_adv` : epaule [-120, 195]
- `levier.back_full` : epaule [-120, 195]
- `levier.back_straddle` : epaule [-120, 195]
- `levier.back_tuck` : epaule [-120, 195]
- `levier.front_adv` : epaule [-70, 195]
- `levier.front_adv.dynamique` : epaule [-70, 195]
- `levier.front_full` : epaule [-70, 195]
- `levier.front_one` : epaule [-70, 195]
- `levier.front_straddle` : epaule [-70, 195]
- `levier.front_straddle.dynamique` : epaule [-70, 195]
- `levier.front_tuck` : epaule [-70, 195]
- `levier.front_tuck.dynamique` : epaule [-70, 195]
- `lsit.l` : hanche [-30, 150]
- `lsit.one` : hanche [-30, 150]
- `lsit.sol` : hanche [-30, 150]
- `lsit.tuck` : hanche [-30, 150]
- `lsit.tuck_sol` : hanche [-30, 150]
- `lsit.v` : hanche [-30, 150]
- `muscle_up.complet.anneaux` : epaule [-90, 195], poignet [-90, 90]
- `muscle_up.complet.barre_fixe` : epaule [-90, 195], poignet [-90, 90]
- `muscle_up.iso_transition.barre_fixe` : epaule [-90, 195], poignet [-90, 90]
- `muscle_up.negatif.barre_fixe` : epaule [-90, 195], poignet [-90, 90]
- `muscle_up.transition.barre_fixe` : epaule [-90, 195], poignet [-90, 90]
- `olympique.clean` : cheville [-60, 45]
- `olympique.clean_press` : cheville [-60, 45]
- `olympique.snatch` : cheville [-60, 45]
- `olympique.thruster` : cheville [-60, 45]
- `planche_gainage.superman` : epaule [-70, 195]
- `planche_laterale.bras_tendu` : epaule_abd [-10, 190]
- `planche_laterale.copenhague` : epaule_abd [-10, 190], hanche_abd [-40, 100]
- `planche_laterale.etoile` : epaule_abd [-10, 190], hanche_abd [-40, 100]
- `planche_laterale.pieds_sureleves` : epaule_abd [-10, 190]
- `planche_laterale.standard` : epaule_abd [-10, 190]
- `planche_skill.adv` : poignet [-95, 140], cou [-60, 80]
- `planche_skill.full` : poignet [-95, 140], cou [-60, 80]
- `planche_skill.straddle` : poignet [-95, 140], cou [-60, 80]
- `planche_skill.tuck` : poignet [-95, 140], cou [-60, 80]
- `quadrupedie.bear_crawl` : poignet [-95, 95], epaule [-90, 195]
- `quadrupedie.crab` : poignet [-95, 95], epaule [-90, 195]
- `quadrupedie.mountain` : poignet [-95, 95], epaule [-90, 195]
- `rowing.anneaux` : epaule [-70, 195]
- `rowing.archer` : epaule [-70, 195]
- `rowing.australien` : epaule [-70, 195]
- `rowing.australien_genoux` : epaule [-70, 195]
- `rowing.australien_pieds_hauts` : epaule [-70, 195]
- `saut.box` : cheville [-60, 45]
- `saut.longueur` : cheville [-60, 45]
- `saut.tuck` : cheville [-60, 45]
- `saut.vertical` : cheville [-60, 45]
- `sol.foam` : poignet [-95, 95], epaule [-90, 195]
- `sol.inchworm` : hanche [-30, 150]
- `sol.triceps_extension` : epaule [-70, 195]
- `suspension.actif.barre_fixe` : epaule [-70, 195]
- `suspension.german.barre_fixe` : epaule [-180, 195], cou [-60, 80]
- `suspension.iso90.barre_fixe` : epaule [-70, 195]
- `suspension.iso_haut.barre_fixe` : epaule [-70, 195]
- `suspension.knee_raise.barre_fixe` : epaule [-70, 195], hanche [-30, 160]
- `suspension.l_sit_barre.barre_fixe` : epaule [-70, 195], hanche [-30, 160]
- `suspension.leg_raise.barre_fixe` : epaule [-70, 195], hanche [-30, 160]
- `suspension.passif.anneaux` : epaule [-70, 195]
- `suspension.passif.barre_fixe` : epaule [-70, 195]
- `suspension.passif.pieds_sol` : epaule [-70, 195]
- `suspension.scap.barre_fixe` : epaule [-70, 195]
- `suspension.skin_cat.barre_fixe` : epaule [-180, 195], cou [-60, 80]
- `suspension.toes_to_bar.barre_fixe` : epaule [-70, 195], hanche [-30, 160]
- `suspension.windshield.barre_fixe` : hanche [-30, 160], epaule [-70, 195]
- `traction.archer.barre_fixe` : epaule [-70, 195]
- `traction.assistee.barre_fixe` : epaule [-70, 195]
- `traction.explosive.barre_fixe` : epaule [-70, 195]
- `traction.l_sit.barre_fixe` : epaule [-70, 195]
- `traction.negative.barre_fixe` : epaule [-70, 195]
- `traction.poitrine.barre_fixe` : epaule [-70, 195]
- `traction.serviette.barre_fixe` : epaule [-70, 195]
- `traction.standard.anneaux` : epaule [-70, 195]
- `traction.standard.barre_fixe` : epaule [-70, 195]
- `traction.un_bras.barre_fixe` : epaule [-70, 195]
- `triceps.kickback` : epaule [-70, 195]
- `triceps.nuque` : epaule [-70, 195]
- `triceps.poulie` : epaule [-70, 195]
- `turkish.getup` : epaule [-90, 195], poignet [-95, 95]
- `ventre.bird_dog` : epaule [-70, 195], cou [-60, 80], hanche [-45, 160]
- `ventre.cat_cow` : epaule [-70, 195], cou [-60, 80], hanche [-45, 160]
- `ventre.superman` : epaule [-70, 195], cou [-60, 80], hanche [-45, 160]
- `ventre.ytw` : epaule [-70, 195], cou [-60, 80], hanche [-45, 160]

### 6.4 Notes des gabarits

- `assis.leg_press` : presse à cuisses (la plateforme est figurée par le montant)
- `atr.dos_mur` : ATR dos au mur : talons contre le mur
- `atr.frog` : frog stand / crow
- `atr.hspu` : HSPU dos au mur
- `atr.hspu_deficit` : HSPU en déficit : la tête descend sous le niveau des mains
- `atr.hspu_libre` : HSPU en équilibre libre
- `atr.libre` : équilibre sur les mains
- `atr.poitrine_mur` : ATR poitrine au mur : corps aligné le long du mur
- `atr.taps` : shoulder taps : dos au mur, une main touche l'épaule opposée
- `atr.wall_walk` : wall walk
- `banc.barre_front` : barre_front
- `banc.couche` : couche
- `banc.ecarte` : ecarte
- `banc.floor` : floor
- `banc.hyperextension` : extensions lombaires sur banc à 45° (le banc est schématisé)
- `banc.incline` : couche
- `banc.pause` : couche
- `cardio.burpee` : burpee
- `cardio.jacks` : jumping jacks
- `corde.battle` : battle
- `corde.saut` : saut
- `debout.cheville` : mobilité de cheville genou au mur
- `debout.dislocation` : dislocations à l'élastique ou au bâton
- `debout.etirement_post` : flexion avant jambes tendues, mains vers les pieds
- `debout.jefferson` : enroulement vertébral segment par segment (le tronc rigide du modèle approxime l'enroulement)
- `debout.poignets` : travail du poignet
- `dips.banc` : dips sur banc
- `dips.banc_genoux` : dips sur banc (genoux fléchis)
- `dips.barre_fixe` : dips à la barre fixe : buste très penché, corps devant la barre
- `dos_au_sol.bridge` : bridge
- `dos_au_sol.bridge_unijambe` : bridge_unijambe
- `dos_au_sol.crunch` : crunch
- `dos_au_sol.dead_bug` : dead_bug
- `dos_au_sol.dragon_flag` : dragon_flag
- `dos_au_sol.flutter` : flutter
- `dos_au_sol.hollow` : hollow
- `dos_au_sol.hollow_rocks` : hollow_rocks
- `dos_au_sol.hollow_tuck` : hollow_tuck
- `dos_au_sol.leg_raise` : leg_raise
- `dos_au_sol.situp` : situp
- `dos_au_sol.situp_jambes_tendues` : situp_jambes_tendues
- `dos_au_sol.twist` : twist
- `dos_au_sol.vup` : vup
- `drapeau.full` : drapeau full
- `drapeau.straddle` : drapeau straddle
- `drapeau.tuck` : drapeau tuck
- `drapeau.vertical` : drapeau vertical
- `ergo.rameur` : rameur
- `ergo.skierg` : skierg
- `ergo.velo` : velo
- `face.inclinaison` : side bend
- `face.windmill` : windmill
- `genoux.hip_flexor` : hip_flexor
- `genoux.nordic` : nordic
- `hinge.baton` : bâton dans le dos : contact tête, dos, sacrum
- `hinge.good_morning` : good morning
- `hinge.sol` : soulevé de terre depuis le sol
- `hinge.unijambe` : jambe libre tendue vers l'arrière
- `levier.back_adv` : back lever adv
- `levier.back_full` : back lever full
- `levier.back_straddle` : back lever straddle
- `levier.back_tuck` : back lever tuck
- `levier.front_adv` : front lever adv
- `levier.front_adv.dynamique` : front lever raises adv
- `levier.front_full` : front lever full
- `levier.front_one` : front lever one
- `levier.front_straddle` : front lever straddle
- `levier.front_straddle.dynamique` : front lever raises straddle
- `levier.front_tuck` : front lever tuck
- `levier.front_tuck.dynamique` : front lever raises tuck
- `lsit.l` : L-sit l
- `lsit.one` : L-sit one
- `lsit.sol` : L-sit sol
- `lsit.tuck` : L-sit tuck
- `lsit.tuck_sol` : L-sit groupé mains à plat au sol
- `lsit.v` : L-sit v
- `mollets.debout` : mollets
- `mollets.tibial` : tibialis raises
- `mollets.unijambe` : mollets une jambe
- `muscle_up.complet.anneaux` : muscle_up.complet.anneaux
- `muscle_up.complet.barre_fixe` : muscle_up.complet.barre_fixe
- `muscle_up.iso_transition.barre_fixe` : muscle_up.iso_transition.barre_fixe
- `muscle_up.negatif.barre_fixe` : muscle_up.negatif.barre_fixe
- `muscle_up.transition.barre_fixe` : muscle_up.transition.barre_fixe
- `olympique.clean` : épaulé (clean)
- `olympique.clean_press` : épaulé-développé
- `olympique.snatch` : arraché (snatch)
- `olympique.thruster` : thruster
- `pistol.assiste` : pistol : jambe libre tendue devant
- `pistol.box` : pistol : jambe libre tendue devant
- `pistol.libre` : pistol : jambe libre tendue devant
- `pistol.shrimp` : squat crevette : jambe arrière fléchie, genou vers le sol
- `planche_gainage.body_saw` : body saw
- `planche_gainage.bras_tendus` : bras_tendus
- `planche_gainage.coudes` : coudes
- `planche_gainage.genoux` : genoux
- `planche_gainage.lean` : lean
- `planche_gainage.levier_long` : levier_long
- `planche_gainage.opposes` : opposes
- `planche_gainage.pseudo_hold` : pseudo_hold
- `planche_gainage.rkc` : rkc
- `planche_gainage.superman` : superman
- `planche_gainage.un_bras` : un_bras
- `planche_laterale.bras_tendu` : planche latérale (vue de face du modèle)
- `planche_laterale.copenhague` : planche de Copenhague
- `planche_laterale.etoile` : planche latérale étoile
- `planche_laterale.pieds_sureleves` : planche latérale pieds surélevés
- `planche_laterale.standard` : planche latérale (vue de face du modèle)
- `planche_skill.adv` : planche adv — mains tournées vers l'extérieur : l'extension apparente du poignet en 2D dépasse l'amplitude réelle
- `planche_skill.full` : planche full — mains tournées vers l'extérieur : l'extension apparente du poignet en 2D dépasse l'amplitude réelle
- `planche_skill.straddle` : planche straddle — mains tournées vers l'extérieur : l'extension apparente du poignet en 2D dépasse l'amplitude réelle
- `planche_skill.tuck` : planche tuck — mains tournées vers l'extérieur : l'extension apparente du poignet en 2D dépasse l'amplitude réelle
- `pompe.diamant` : mains rapprochées : coudes le long du corps
- `pompe.mur` : pompe au mur
- `pompe.pike` : pompe piquée
- `pompe.pseudo` : mains au niveau des hanches, épaules très en avant des mains
- `quadrupedie.bear_crawl` : bear_crawl
- `quadrupedie.crab` : crab
- `quadrupedie.mountain` : mountain
- `rowing.anneaux` : rowing australien
- `rowing.archer` : rowing australien
- `rowing.australien` : rowing australien
- `rowing.australien_genoux` : rowing australien genoux fléchis (version facile)
- `rowing.australien_pieds_hauts` : rowing australien
- `saut.box` : box
- `saut.longueur` : longueur
- `saut.tuck` : tuck
- `saut.vertical` : vertical
- `sol.foam` : rouleau de massage
- `sol.inchworm` : inchworm
- `sol.triceps_extension` : extension triceps au poids de corps (bodyweight skull crusher)
- `squat.assiste` : mains sur un support (poteau) : bras tendus devant
- `squat.chaise` : squat sur chaise : la box figure la chaise
- `squat.sissy` : sissy squat
- `suspension.actif.barre_fixe` : suspension active tenue
- `suspension.german.barre_fixe` : german hang
- `suspension.passif.pieds_sol` : suspension passive assistée par les pieds
- `suspension.scap.barre_fixe` : tractions scapulaires : bras tendus, seules les omoplates s'abaissent
- `suspension.skin_cat.barre_fixe` : skin the cat
- `suspension.windshield.barre_fixe` : essuie-glaces
- `tirage.shrug` : shrug : représentation limitée
- `traction.archer.barre_fixe` : traction archer : un bras se tend sur la barre
- `traction.assistee.barre_fixe` : traction assistée par élastique
- `traction.poitrine.barre_fixe` : poitrine à la barre : coudes très en arrière, tronc penché
- `traction.serviette.barre_fixe` : prise sur une serviette (représentée par la barre)
- `traction.un_bras.barre_fixe` : traction à un bras
- `traineau.pull` : traîneau pull
- `traineau.push` : traîneau push
- `turkish.getup` : relevé turc
- `ventre.bird_dog` : bird_dog
- `ventre.cat_cow` : cat_cow
- `ventre.superman` : superman
- `ventre.ytw` : ytw

## 7. Précautions (P1)

Libellés standard utilisés (consignes d'entraînement) :

- `epaule_anterieure` (76 exercices) : Éviter en cas de douleur à l'avant de l'épaule ; réduire l'amplitude basse.
- `epaule_au_dessus_tete` (41 exercices) : Bras au-dessus de la tête : éviter en cas de douleur d'épaule dans cette position.
- `coude` (36 exercices) : Réduire l'amplitude ou la charge en cas de douleur au coude.
- `poignet_extension` (103 exercices) : Appui main à plat, poignet en extension : utiliser poings ou poignées en cas de gêne au poignet.
- `lombaire` (84 exercices) : Éviter en cas de douleur lombaire ; garder le dos neutre et gainé.
- `cervical` (12 exercices) : Éviter l'appui ou la charge sur la tête et la nuque en cas de gêne cervicale.
- `genou_flexion` (56 exercices) : Limiter la profondeur en cas de douleur au genou.
- `impacts` (43 exercices) : Sauts et réceptions : éviter en cas de douleur aux genoux, chevilles ou tendons d'Achille ; reprendre progressivement.
- `tete_en_bas` (19 exercices) : Position tête en bas : éviter en cas de vertiges ou de contre-indication connue ; prévoir une sortie sûre.
- `charge_axiale` (31 exercices) : Charge sur la colonne : progresser par petits paliers, dos gainé, pareur ou sécurités réglées.
- `effort_maximal` (12 exercices) : Effort maximal : jamais en reprise ni sans échauffement complet ; arrêter au premier défaut technique.
- `cardio_intense` (25 exercices) : Effort cardio intense : progresser graduellement ; arrêter en cas de malaise, vertige ou douleur thoracique.
- `equilibre` (35 exercices) : Travail d'équilibre : espace dégagé, sortie de chute maîtrisée avant de progresser.
- `suspension` (107 exercices) : Suspension : vérifier la solidité du support et la sécurité de la prise.
- `tendons_bras_tendus` (28 exercices) : Figure bras tendus : progresser lentement, les tendons du coude et du biceps s'adaptent moins vite que les muscles.
- `chute_arriere` (6 exercices) : Risque de chute en arrière : apprendre la sortie (roulade ou pas de côté) avant de tenir longtemps.
- `technique_prioritaire` (40 exercices) : Mouvement technique : apprendre avec une charge légère et un retour vidéo ou un regard extérieur.
- `reprise_senior` (0 exercices) : Reprise ou âge avancé : commencer par la version assistée et un tempo contrôlé.
- `adducteurs` (5 exercices) : Tension forte sur l'intérieur de cuisse : entrer progressivement dans l'amplitude.
