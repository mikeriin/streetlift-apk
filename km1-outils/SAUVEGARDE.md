# Sauvegarde KM1 (méthode Koach : référence Python et banc)

Session Fable 5.1 lancée le 09/10/2026 vers 16:10 UTC (pas de ligne « Lot : » : KM1 seul lot moteur « à faire »). Ligne d'état « en cours depuis 2026-10-09 16:14 UTC » poussée sur `pipeline` (9c9420fa). `add_repo` absent de la session et de ses sous-agents ; push vérifié (pipeline poussé). Base : `moteurs` aacbe054. Arbre de travail : worktree `/home/claude/moteurs` (branche locale `moteurs`). Outils de session : `km1-outils/` (save.sh, ci.sh).

## Constats de démarrage
- **Pas de SDK Dart dans la session** (storage.googleapis.com refusé par la politique de sortie) : tout ce qui est Dart passe par le contrôle `claude/ci-cp-a` (comme CY : `ci.sh`), résultats dans `ci-out/`.
- Journal du propriétaire : `journal_proprietaire.tar.gpg` **absent** de `cp-references` au démarrage (brique 8 en attente, C13.6).
- Témoin 0.3.1 déjà mesuré par le contrôle complet de CY (run 37922562342, `ci-out/packages/kalis_bench/SAISONS.md`, 100 graines) : échéance (meilleure barre / max du jour) 94,4 % en saison de référence, progression 0,313 %/sem., écart d'effort 1,45.

## Architecture décidée (voir packages/kalis_adapt/reference/CONCEPTION.md quand il existe)
- Dart (ajouts dans kalis_bench seulement, `bin/km1.dart` + `lib/src/km/`) : export JSON des modèles de vérité (profils × scénarios × modèles A/B/C × graines), des programmes de référence kalis_plan, traces de parité du modèle de vérité, mesures du témoin par saison, témoin sur athlètes adversariaux, critères de sécurité du banc sur des blocs exportés par Python.
- Python (`packages/kalis_adapt/reference/`) : portage du modèle de vérité (vérifié contre les traces Dart), meneur de saison, moteur Koach 1.0, banc adversarial, critères.
- 10 qualités : pousser, tirer, jambes, tronc, figures (bras tendus, équilibre), endurance_force, explosivite, aerobie, anaerobie, mobilite.

## Fait
- Lectures : PIPELINE_CP, CAHIER_KM, prompt KM1, LANCEMENTS (KM1), DECISIONS C11-C13, truth.dart, runner.dart, endurance_truth.dart, season.dart, coach_metrics.dart, policy.dart, common.dart, book.dart, grid.dart, Flames.

## En cours
- Outil d'export Dart `km1` (brique 0).

## Reste
- Briques 1 à 7, critères, fixtures, relecture indépendante, fin de lot ; brique 8 dès que le journal est déposé.

## 09/10 17:25 UTC — brique 0 faite
- Export Dart `km1` (packages/kalis_bench/lib/src/km/km_export.dart, bin/km_common.dart, bin/km1.dart) : analysé et formaté par le contrôle dev (run 37964997316), exports dans `packages/kalis_adapt/reference/donnees/` (catalogue_infos, reference/, temoin/ 16 graines, traces_verite, traces_endurance).
- Portage Python du modèle de vérité (`reference/banc/verite.py`, `verite_endurance.py`) : **3 tests de parité verts à 1e-9** (traces force > 20 000 séries, endurance, tirages de départ de toutes les saisons).
- Notes : `km1-outils/notes/SECURITE_0_3_1.md` (règles de sécurité 0.3.1 et critères du banc), `SOURCES_RECHERCHE.md` (sources vérifiées).
- Fichier de paramètres v1 ébauché (`reference/params/koach_params_v1.json`), `koach/numerique.py` (erfc 1e-13, moments d'intervalle = réponse graduée ogive normale).
- Conception de l'estimation : état gaussien (10 qualités, réponse ρ + 5 classes, sensibilités fatigue, biais RIR additif et proportionnel, courbe c1·ln R + c2·(R−1) avec échelle par exercice, fatigue intra-séance, part de tenue, effet de jour séance + exercice ; par exercice δ et échelle de courbe), mises à jour par appariement de moments sur intervalles (catégories de flammes), deux branches par séance (jour normal / mauvais jour) fusionnées en fin de séance.

## 09/10 ~18:30 UTC — briques 2-3 en cours
- `qualites/regles.py` → `vecteurs_qualites_v1.json` (1 039 exercices, 10 qualités, types de réponse identiques aux modes du banc Dart, charge tendineuse) ; relecture Opus à faire.
- `koach/modele.py` (filtre gaussien, observations par intervalles en sens génératif : réserve PERÇUE = (réserve vraie − biais)/(1+biais pop.), courbe g(R)=e^(ku+ke)[(1−λ)·0,0265(R−1)+λ·0,0892 ln R], deux branches par séance), `koach/securite.py` (douleur, arrêt, reprise, bilan), `koach/seance.py` (charges, plages au ressenti, séries repères, vrai test, tentatives), `koach/moteur.py` (observe/posterior/plan/explain), `banc/meneur.py` (portage du meneur Dart), `banc/politique_koach.py`, `banc/mesures.py`.
- Outils : `km1-outils/essai.py <profils> <scénarios> <graines>` (mesures), `trace.py <profil> <modèle> <graine> <exercices|?> [n]`.
- Témoin (16 graines, tous profils) : e1RM principaux chargés MAE 7,1 % au rang 6 (jamais sous 3 % en moyenne), premier passage sous 3 % : moyenne 6,2 séances, 31 % jamais ; échéance : meilleure barre / max du jour 92,6 %, / capacité de départ 91,6 % ; 114 violations réalisées et 150 poussées de douleur sur 11 520 saisons, 0 hausse sur douleur.
- État de l'estimation Koach (4 profils, 2 graines) : MAE principaux chargés ~9-11 % → À AMÉLIORER (dérive négative ; leçon : jamais de correction du RIR dans le sens inverse (erreurs sur la variable), paramètres globaux à a priori serrés, pas de bornes dures sur l'état).
- Interprétation retenue : « intervalle à 90 % dépasse 6 % » = demi-largeur ± 6 %.

## 09/10 ~19:15 UTC — estimation : état et leçons (LIRE AVANT DE REPRENDRE)
Mesures actuelles (6 profils chargés, 3 graines, saison de référence, rang = jour d'entraînement de l'exercice) : principaux chargés MAE 6,6 % au rang 6 (témoin 7,1 %), biais −4 % ; A 5,5 %, B 8,8 %, C 5,5 % ; échéance meilleure barre / max du jour 91,9 % (témoin 92,6 %) ; 0 hausse > 10 % ; écart d'effort ~5 (témoin 1,45) → loin des critères (3 %).
Décisions de modèle prises (toutes dans le code) :
- Mesure en sens GÉNÉRATIF : note en flammes = catégorie de la réserve perçue p = (v − BA)/(1 + BP), v = R(charge)·garde − reps ; à partir de RIR 4 la note est une catégorie ouverte (« 4 ou plus », `rir_ouvert` 4) ; bruit du cahier (2/1,5/1) valable à RIR 5 et décroissant vers l'échec ; mélange « note paresseuse » quand la note = la note préremplie.
- Courbe g(R) = e^k[(1−λ)·0,0265(R−1) + λ·0,0892 ln R] ; k = échelle par exercice (sd 0,23) ; λ utilisateur (0,1 ± 0,3). BP, KU, KN, KM, HH figés (variance a priori 0) ; BA, λ, FI appris.
- Répétitions au poids du corps : échelle directe ln Rmax (pas la masse totale : trop fragile à 20-30 répétitions).
- Fatigue intra-séance : garde = 1 − FI·Σ exp(−rir/1,5)·exp(−repos/180)·0,7^rang ; bruit ajouté ∝ dispersion 0,3 × sj × R.
- Séance : charge = quantile prudent de la charge qui donne les répétitions écrites à la réserve écrite ; part écrite du 1RM = plafond (charge écrite en semaine verrouillée, débutant, ≥ 85 % ; couloir +15 % sinon, comme 0.3.1) ; bornes de hausse 10/5/5/5 % à schéma égal (base = première série de la dernière séance, comme la mesure du banc), schéma nouveau : +10 % sur la plus lourde barre de 42 j (+2,5 %/rép. de moins).
- Séries repères (dernière série ouverte, réserve 1,5 ; 2 débutant) quand l'intervalle à 90 % dépasse ± 6 % et rien mesuré depuis 14 j ; VRAI TEST des mouvements principaux chargés = item de test inséré (slot + '.t', kind test) en montée de charge conduite par le ressenti (1 rép. avancé/élite, 3 intermédiaire, 5 débutant), note préremplie neutre.
- Tentatives : règles A8.2 de 0.3.1 avec les probabilités de Koach.
Constats sur les modèles de vérité (expliquent le plancher d'erreur) : la capacité « vraie » est une capacité fraîche idéale ; la performance du jour est en dessous de 2 à 5 % (forme AR, fatigue aiguë par groupe musculaire, B : netteté selon charge 7 j / 28 j et −2 % sans série ≥ 85 % depuis 10 j ; C : fatigue masquée, 1 jour sur 10 à −4 %) ; notes : A bruit (0,3+0,2·rir)·(1+(cap−12)/12), biais multiplicatif β (0,25 ± 0,18 ; graine 0 : 0,66 !), B notes entières plafonnées à 4 avec 8 % d'erreurs de ±2, C décalage du jour 0,6 ; notes paresseuses 10 % ; fatigue intra-séance très forte près de l'échec (A : 0,85·e^(−repos/160)·e^(−rir/1,4)·échelle individuelle).
Pistes restantes pour l'estimation : (1) garder les séries de travail des mouvements principaux près de la réserve écrite (information précise) ; (2) apprendre la sensibilité à la fatigue (performance du jour vs capacité) ; (3) ouverture des tentatives ≤ plus lourde barre réussie récente ; (4) calibrer bruits et a priori sur le banc ; (5) couverture 90 % (actuellement ~60 % : intervalles trop étroits).
Reste entier : planification (jumeau, entropie croisée, transport optimal), adhérence, BOCPD + diagnostic, contrôle dual, banc adversarial + témoin Dart sur athlètes adverses, sécurité (portage B1-B14 + outil Dart), contrat, SOURCES.md, fixtures, relectures Opus (vecteurs, code), fin de lot.

## 09/10 18:27 UTC — retour des quatre sous-agents (Opus)
- `banc/securite_banc.py` + `tests/test_securite_banc.py` (15 verts, 4 sautés en attente du nouvel export Dart) ; export Dart étendu (`km_export.dart`, `km_common.dart`, `km1.dart`) NON encore compilé par la CI.
- `koach/rupture.py`, `koach/adherence.py` (53 tests verts) ; `koach/dual.py` (26 tests verts).
- `notes/RELECTURE_VECTEURS.md` : relecture indépendante de 222 exercices, 12 corrections de règles à appliquer dans `qualites/regles.py`.
- Écarts à trancher : fenêtre BOCPD 10 séances (pas 3) ; seuils de tests assouplis (détection 86 %, adhérence 0,093 à 200 décisions, N-of-1 indéterminé 56 % sous le nul).
- Suite : CI dev pour compiler le Dart, ré-export, sécurité Dart des saisons de référence ; appliquer les corrections de vecteurs ; reprendre l'estimation ; planificateur.

## 09/10 ~19:00 UTC — Dart compilé, sécurité portée validée, vecteurs corrigés
- CI dev 37973446066 : export étendu et outils Dart compilés, formatés, analysés sans remarque ; `donnees/` mis à jour (catalogue_infos étendu, securite_dart.json.gz) ; `test_securite_banc.py` 19/19 verts (comparaison stricte avec `safetyFindings` Dart sur 240 saisons de référence). Le constat `volume_trop_vite` de street_06/changement_discipline est CONFIRMÉ par le Dart (plan de référence lui-même).
- `qualites/regles.py` : corrections de la relecture indépendante appliquées (R1-a/b, R2-a…h, R3-a, R6-a…f, R7-a…g) ; R5 (types) NON appliqué : le type doit rester celui du mode d'exécution de kalis_core (mesure du journal).
- Estimation, diagnostic : (1) les charges servies sont trop légères (réserve vraie 5-7 pour 2,5 visée ; C : ~20) → notes censurées « 4 ou plus », peu d'information ; (2) l'effet de jour vrai moyen est −2,6 % (sd 2,8 %) : fatigue chronique systémique (lente) + aiguë locale (rapide) ; régression sur le banc : rapide local 0,003, lent systémique 0,0014-0,0017, les deux autres ≈ 0 ; (3) courbe a priori trop plate de ~12 % par rapport aux vérités (→ échelle +0,10) ; (4) la montée de test s'arrête à la croyance du modèle (borne mu+2sd) → réserve finale ~4.
- Compartiments généralisés dans modele.py : chaque compartiment (rapide/lent) a une part systémique et une part locale (KN, KL, KG, KM).

## 09/10 ~19:00 UTC (horloge réelle ; les heures notées plus haut étaient décalées) — estimation v4 : dérive trouvée et corrigée
Mesure (SET9 = 9 profils chargés, saison de référence, 2 graines) : principaux chargés au rang 6 MAE 3,3 % (A 2,6 ; B 4,2 ; C 3,2), biais −1,5 %, couverture 85 % ; premier passage sous 3 % : 2,6 séances en moyenne, jamais 5 % (témoin 6,2 séances, 31 %).
Causes trouvées (banc synthétique `km1-outils/synth2.py`, un exercice, vérité A) :
1. **Relinéarisation itérée** (filtre itéré) = cause de la dérive conjointe capacité ↓ / courbe ↓ / forme → 1 quand la charge est choisie par le modèle : mises à jour dissymétriques. Corrigé : linéarisation à la moyenne a priori en UNE passe + réduction du pas par dichotomie sur la carte exacte pour les grandes surprises.
2. Bruit de la note dépendant de la réserve vraie : quadrature `numerique.category_moments` (bruit fonction de u).
3. Fatigue : régression sur le banc → rapide local (par groupe musculaire, 17 groupes = kalis_plan) 0,0047 ; lent systémique 0,00075 ; les deux autres 0 ; bilan 0,012/point (déjà). `regles.py` exporte `groupes`.
4. Paramètres communs figés aux valeurs de population (puits de dérive) : FI 0,85 (calé sur les vérités), BA 0, BP 0,25, KU 0,10 ; forme λ apprise (0,3 ± 0,3) : retrouve A ≈ 0,4, B ≈ 0, C ≈ 1.
5. Vrai test = montée de charge conduite par le ressenti : pas 7,5/5/3,5/2,5 % selon la note, confirmation en REFAISANT la même barre quand la note dit la réserve atteinte (2 notes basses), effort affiché « 2 en réserve » (sinon l'athlète simulé s'arrête avant les répétitions), pas de montée si la grille est trop grossière (cran > 10 %). Réserve vraie finale : 1,2-1,9 (débutants 2-3).
6. Part écrite du 1RM lue comme un niveau d'effort (répétitions de la courbe de population) puis convertie par la courbe de l'athlète (`Seances.charge_de_part`) → décision à écrire dans DECISIONS_CP.
7. Tenues : intervalle sur ln T sans linéarisation ; HH 0,10.
8. Note aberrante 5 % (1/10 par flamme) + note paresseuse apprise.
Reste : tenues (a priori −30 %), répétitions (11 %), écart d'effort 3,2, couverture, effet du jour (branches), planificateur, etc.

## 09/10 ~19:50 UTC — matrice complète (720 saisons, 1 graine) et douleur
Koach vs témoin 0.3.1 (toutes saisons) : principaux chargés rang 6 MAE 3,96 % (A 3,2 ; B 5,8 ; C 2,9) contre 7,1 % ; premier passage sous 3 % : 2,6 séances (jamais 8,7 %) contre 6,2 (jamais 30,7 %) ; couverture 88 % au rang 6 ; échéance chargée 0,955 contre 0,926 ; répétitions MAE 10 % contre 20 % ; tenues 30 % contre 27 % (à corriger : a priori) ; écart d'effort 2,7 contre 1,55 ; échecs 1,0 % contre 0,7 %. Dégradation en fin de saison (rang 24 : MAE 7 %, biais −5 %) à comprendre.
Douleur (scénarios douleur_coude/epaule, 162 saisons) : 120 aggravations au premier passage → 0 après correction (zone bloquante = active OU signalée depuis la dernière séance de l'exercice ; jamais plus lourd que le DERNIER PASSAGE de l'exercice : `Memoire.charge_derniere`) ; poussées (flares) 69 → 0 : paliers de reprise comptés en semaines de charge (A3.3), arrêt gardé jusqu'à une semaine de charge (A3.2), et budget hebdomadaire de séries par zone (départ 0,6 × habitude, +25 % ou +1 série par semaine de charge, 84 jours) — plus prudent que 0.3.1. Témoin : 0 aggravation, 120 poussées sur 2 592 saisons.
Ajouts : queue lourde des notes (8 %, +2 rép.), noteur entier détecté (≥ 20 notes, < 5 % de demi-notes), garde de probabilité sur la montée (0,75).

## 09/10 ~21:10 UTC — briques 4, 6, 7 par sous-agents (Opus), réponse calée
- Brique 4 : `banc/adversaire.py` (espace borné de 23 dimensions, recherche (μ+λ), export `donnees/adversaires_v1.json` + entrée Dart `km1-outils/km1_entree/adversaires.json` (98 saisons), `--comparer`). Témoin Dart sur ces adversaires : À LANCER dans la CI. Trois défauts de l'échelle de tentatives trouvés (même barre répétée après un échec même si elle dépasse le max ; saut ≤ 5 kg ; ouverture trop prudente quand douleur hors zone) → à corriger dans `seance._tentative`.
- Briques 6-7 : `banc/extensions_koach.py`, `banc/validation_koach.py`, `donnees/validation_briques_6_7.json`. BOCPD seuil 0,6 confirmé (0,77 fausse alerte / 100 séances) ; secours « résidu 5 % » inutilisable (actif 39 % des semaines) → décision à écrire ; aucun essai N-of-1 ne tient dans 16 semaines ; anti-complaisance vérifiée (54/54 saisons identiques).
- Réponse à l'entraînement calée sur le banc : rho par niveau [0,0095 ; 0,003 ; 0,0012 ; 0,0006], facteur de récupération (seuil 8, pente 0,5, plancher 0,2 sur la fatigue lente systémique), accoutumance 1/(1+semaines/40), hypothèses s0 1,5/2,5/5.
- Suite : corriger les tentatives, CI (témoin adversaires), planificateur (brique 5), contrat, sources, fixtures, relecture Opus.

## 09/10 ~22:15 UTC — brique 5 (planificateur), 8 (rejeu), contrat, fixtures : premiers résultats
- `koach/planification.py` + `banc/planification_banc.py` : jumeau (1 000 trajectoires, CRN), entropie croisée 4×64, transport 1-D, plafonds, validateur injecté (securite_banc). Replanification 0,18 s. Sans échéance le plan coupe volume/intensité (facteur de récupération calé sur le banc) : gain +5 à +34 % ; avec échéance P(toutes cibles) plate → peu de changement. λ à calibrer.
- Témoin Dart sur les adversaires (CI 37990432397) : saisons communes (42) Koach moy 0,895 pire 0,782 ; témoin moy 0,832 pire 0,691 (après correction de l'ouverture justifiée par les barres récentes ; avant : pire Koach 0,462 sur un triple échec d'ouverture). Recherche à relancer contre le Koach final.
- Rejeu du journal réel (sous-agent, `rejeu/`, agrégats `donnees/rejeu_journal_agregats.json`) : ÉCHEC en l'état (erreur moyenne 55,8 %, couverture 68 %) : cliquet des séries SANS NOTE (712/896 : borne « réserve ≥ 0 » qui pousse toujours vers le haut), BP qui dérive à 0,95, accessoires sans valeur déclarée. Sensibilités du sous-agent : sans les séries non notées + accessoires déclarés → erreur 5,2 %, couverture 89,5 %. À CORRIGER dans le moteur (porte sur les séries sans note, BP figé) et dans le convertisseur (accessoires déclarés depuis leur référence initiale).
- Critères (sous-agent, `banc/criteres_moteur.py`) : série 0,65 ms, replanification 0,18 s ; mauvais jour isolé 1,17 % juste après (> 1 %), 0,83 % une séance plus tard ; déterminisme OK. Fixtures : 8 fichiers, 2,9 Mo, `fixtures/generer.py`.
- CONTRAT_1_0.md (1 739 lignes) et SOURCES.md écrits par sous-agent ; 58 écarts relevés à traiter : eigh non portable, rejeu non exact sans les appels plan, zones_fragiles sans effet, règles 0.3.1 non reprises (poignet A4, endurance A10…), 32 clés non lues, Thompson non branché.
- kalis_bench 0.3.1 (version, CHANGELOG, test km_export_test.dart) : à compiler en CI.

## 09/10 ~22:50 UTC (horloge réelle) — corrections moteur après le premier rejeu réel
- Séries SANS note : versées seulement si la prévision les contredit, et alors la forme/échelle de courbe sont « considérées » (filtre de Schmidt, `_observer(fige=…)`), non déplacées. BP figé (0,25 ± 0). Accessoires déclarés au convertisseur depuis leur charge de travail initiale (courbe de population, réserve cible de la ligne, sd 0,12 ; tuple `declares` à 3 éléments).
- Rejeu réel : erreur moyenne 55,8 % → 5,7 % (médiane 3,5 %, biais +0,9 %), couverture 89,5 % (n = 38 séries, 11 séances) ; tests réels n = 4 : 10,3 %. Principaux hors test d'endurance et hors série d'échauffement : ~2,4 % (7 séries). Critère 3 % NON atteint au sens strict (bruit d'une série notée ≈ 3 %).
- Banc SET9 ×4 graines inchangé : rang 6 A 2,7 / B 4,5 / C 3,3 % ; couverture 87 % → `mesure.defaut_modele_sd` (à caler en campagne). `jour.mauvais_jour_proba` 0,10 (vérité C : 1 jour sur 10).
- Jumeau : Cholesky portable (`numerique.cholesky_semi`) à la place de eigh ; Thompson branché (`Planification.tirer` appelle `hypothese_pour_la_semaine` quand le contrôle dual est calibré).
- Rejeu exact : `plan()` verse un événement `plan` (contraintes canoniques JSON) ; `observe` le rejoue ; test `tests/test_rejeu_exact.py` (état bit à bit). `_observer_hors` met à jour les deux branches.
- Outils : `km1-outils/rejeu.sh`, `diag_lam_reel.py`, `diag_mj.py`.
- Reste : règles 0.3.1 non reprises (A4 poignet, A7 zones fragiles, A10 endurance), campagne complète + calage couverture, adversaire final, CI Dart, fixtures, contrat/sources, relecture Opus, livraison.

## 10/10 ~00:10 UTC — relecture Opus du code traitée (notes/RELECTURE_OPUS_CODE.md : 4 bloquants, 8 majeurs)
- Sous-agent sécurité (2 passes) : règles 0.3.1 reprises (poignet A4, zones fragiles A7.2, endurance A10, surmenage A6.2, techniques A9.2, renvoi pro, coupure…), tableau `notes/SECURITE_KOACH_COUVERTURE.md` ; accessoires et schéma changé bornés comme 0.3.1 ; pas de vrai test après coupure (B2) ; plafond des tenues exp(mu) ; bras N-of-1 sous les garde-fous (M2). Borne « dernier passage » en semaine verrouillée essayée puis RETIRÉE (coût mesuré ; 0.3.1 borne par la charge écrite).
- B1 : `mesure.porte_note_ouverte` 99 → 1,0 (note ouverte versée seulement si la prévision est à moins d'un écart-type de la borne) ; banc inchangé ou mieux, plateau synthétique (km1-outils/plateau.py) +5..14 % → +4..7 % (reste : progression a priori + séries loin de l'échec).
- B3 : BP appris (0,25 ± 0,15) ; BA reste 0 (non identifiable séparément) → décision à écrire. Rejeu réel : 4,2 % moyenne, 2,1 % médiane, couverture 97 % (n = 38).
- M4 : quadrature `category_moments` à pas choisi sur la vraisemblance (fenêtre [a−8T, b+8T], ≤ 1 200 points) ; exacte contre quadrature dense. `math.erfc` gardé dans `_category_mass` (vitesse Python ; = erfc portable à 2e-13).
- M1 : `Planification` refuse `validateur=None` (sauf `options['sans_validateur']`). M3 : import de paramètres journalisé (événement `parametres`), garde-fous figés (`rupture.FIGEES`), bornes des probabilités. m1 (Joseph avec pas raccourci), m3 (`numerique.arrondi`), m4 (repos 0 s), m5 (gardes), m9, m11, m13 faits.
- NON traités (à écrire dans la livraison) : M5 (demi-largeur rarement < 6 % : cohérent avec l'erreur mesurée ; contrôle dual rarement déclenché), M6 (crochets d'extension appliqués par l'appelant), M7 (référence de planification hors journal), M8 (résidu du secours), m6, m10, m12, m14, m15.
- `banc/campagne.py` + `tests/test_campagne.py` existent (harnais de campagne complet, cache /tmp/km1-campagne) : à lancer pour la mesure finale.
- Fixtures périmées (tests/test_fixtures.py désélectionné) : `fixtures/generer.py` à adapter (validateur obligatoire, événements `plan`) puis régénérer.

## 10/10 08:50 UTC — KM1 LIVRÉ
- `moteurs` f3801e36 (référence Koach 1.0, kalis_bench 0.3.1), `etiquettes/kalis_bench-v0.3.1`, contrôle complet vert run 38032852629.
- Campagne finale (1 440 saisons) : 6 critères sur 11 (non atteints : e1RM 4,24 %, mauvais jour 1,14 %, calibration 15 points, rejeu réel 4,3 % / 97 % ; parité : KM2) ; sécurité 0.
- `pipeline` c1bc68b9 : LIVRAISON_KM1.md, DECISIONS_CP (section KM1), ETAT_CP (ligne KM1 « livré, à valider »). Projet claude.ai : `claude/LIVRAISON_KM1.md`. Page de suivi : section KM1.
- Rien à reprendre ; suite = décision du pilotage (DECISIONS KM1.2, KM1.5, recommandation).

# KM1 CORRECTION 1 (C13.10) — session Fable du 10/10/2026, 09:15 UTC

Lancement sans ligne « Lot : » ; ETAT_CP : KM1 « à faire (correction 1, C13.10) » → « correction 1 en cours depuis 2026-10-10 09:17 UTC » (pipeline 7b2d6e2). `add_repo` absent de la session ; push vérifié par le push de `pipeline`. Worktree `/home/claude/moteurs` (branche `moteurs`, base f3801e36), outils `km1-outils/` restaurés de la sauvegarde, outils de la passe dans `km1-outils/c1/`.

## ~09:55 UTC (heure réelle) — diagnostic du critère 1 (LIRE AVANT DE REPRENDRE)
- Boucle rapide : `c1/q.sh <nom> <graines> "<SETP>" <PATCH>` (27 profils, saison de référence, 3 vérités ; ≈ 3,5 min pour 2 graines) → `c1/tmp_<nom>.pkl/.log` ; `NS=2 python3 c1/ana.py tmp_x.pkl`. Base (2 graines) : A 2,92 / B 5,73 / C 3,49 → 4,05 % (campagne KM1 : 2,97 / 5,89 / 3,86).
- **L'erreur opérationnelle (charge aux répétitions de travail) n'est que de 2,1 % ; l'erreur d'e1RM (4,0 %) vient de l'extrapolation par la courbe** (corrélation −0,7 à −0,8 avec l'écart de courbe). Oracle « courbe vraie donnée » : 2,64 % (A 2,11 ; B 3,30 ; C 2,53).
- Les trois vérités sont trois FORMES de courbe par athlète (A exponentielle à plancher ≈ log-linéaire, B = Brzycki linéaire en part du 1RM donc convexe en ln, C = Lombardi puissance) et une ÉCHELLE par exercice (sd 0,18 à 0,20, bas du corps −16 à −20 %). L'ancienne famille (mélange linéaire/log) ne couvrait pas B aux répétitions hautes.
- **Fait** : famille de Box-Cox dans `koach/modele.py` (`_g`, `_dg`, `_dg_forme`, `_reps_de` inverse fermée, `_phi`, `_phi1`, bornes LAM_MIN/LAM_MAX) ; `planification.py` et `seance.charge_de_part` branchés dessus. Ajustement à 7 équations publiées (Brzycki −0,30 ; Lander −0,29 ; O'Conner 0,14 ; Mayhew 0,25 ; Wathen 0,32 ; Epley 0,33 ; Lombardi 1,0 ; écart max 1,8 % de charge de 2 à 20 rép., `c1/fam.py`) → a priori de forme N(0,2 ; 0,45).
- Famille seule + a priori large : pas de gain net (4,17 %) : la forme est apprise dans le bon sens (A 0,1-0,2 ; B −0,3 à −0,6 ; C 0,7-0,9) mais pas assez vite, B dépasse.
- Valeur aberrante du banc : `mu-presse-cuisses-45`, graine 0, vérité B : pente tirée à +3,5 σ (0,044/rép.) → −32 à −43 % d'erreur ; répétée dans 2 profils × tous les scénarios, elle coûte ≈ 1,1 point à B (≈ 0,37 au critère).
- En cours : oracles biais de note / effet de jour (`c1/oracle_*.py`) pour le budget d'erreur.

## ~10:35 UTC (heure réelle) — critère 1 : budget d'erreur établi, itération 1 codée (LIRE)
Mesures (27 profils, saison de référence, 2 graines, rang 6, moyenne A/B/C) :
- base KM1 4,05-4,17 % ; **oracle « courbe vraie par exercice » 2,28 %** (A 1,76 ; B 2,94 ; C 2,15) ; + oracle biais de note 2,42 ; + oracle effet de jour 1,94 ; **oracle de FORME seule (forme par athlète connue, échelle par exercice à apprendre) 4,09 %** → ce qui coûte, c'est l'ÉCHELLE de courbe par exercice (sd 18-20 % dans les trois vérités), pas la forme.
- Par mesure la plus basse en répétitions (réserve vraie ≤ 3) vue avant le rang 6 (`c1/diag7.py`) : mesuré sous 8 rép. possibles → 2,0 à 3,1 % ; jamais mesuré sous 8 (débutants, lignes sans test) → 5,8 à 6,5 % (40 % des cas). Les débutants (5 puis 3 rép. à 2 en réserve dite, 1 à 2 séries de montée dans le budget de la ligne) restent à 8-9 rép. possibles.
- Vérité C, mesurée à 1 rép. : biais −3 % qui reste même forme connue (échelle de l'exercice aux basses répétitions : g(3) = 0,11 ± 20 %).
- **Conclusion : < 3 % en moyenne A/B/C n'est pas atteignable sur ce banc avec des tests à réserve gardée** (plancher ≈ 3,6-3,8 %) ; gain réel de l'itération 1 ≈ 0,2 point.
Itération 1 (codée, dans `moteurs` non poussé) :
1. Famille de Box-Cox (modele.py) + a priori de forme N(0,2 ; 0,45) tiré de 7 équations publiées.
2. Vrai test : trois horloges (`dernier_test_jour` repère/tout, `dernier_vrai_test_jour` test arrivé près de l'échec → 14 j, `derniere_rampe_jour` → `jours_min_entre_rampes` 5 j) ; une série repère ne bloque plus un vrai test ; première barre de la montée bornée par la règle A7.2 du premier passage à un schéma (+10 %, +2,5 %/rép. de moins, 4 au plus) ; durée de la montée estimée sur les séries qu'elle peut vraiment faire ; grille grossière : un cran entier permis jusqu'à 15 % après une série dite très facile (`rampe_pas_cran`, `rampe_cran_rir_marge`) ; test du débutant à 3 rép. (comme le 3RM que kalis_plan écrit pour un débutant), réserve 2 inchangée.
3. Essayé sans gain, NON retenu : fatigue intra-séance recalée sur la moyenne des trois vérités (FI 0,75, intra_rir 2,0).
Sous-ensemble après itération 1 : 3,91 % (A 2,49 ; B 5,50 ; C 3,74). À confirmer par la campagne.
Reste : critère 5 (calibration par cible : simuler l'échelle des tentatives dans le jumeau, bruit de jour commun, affûtage), critère 2 (contrefactuel apparié par rejeu du journal : base[0..j) + séance du mauvais jour + base(j..)), fixtures, campagne, tests, contrat/sources, livraison.

## 11:35 UTC — critères 5 et 2 codés et mesurés hors campagne (LIRE)
- **Critère 5** (par cible, C13.10.2.c) : données `c1/calib.py` (45 saisons à cibles × 3 vérités × graines ; `tmp_cal2.pkl` graines 0-1, `tmp_cal3.pkl` graines 2-5 ; `c1/ana_cal.py`). Constat : une cible chargée n'est JAMAIS manquée quand elle est tentée ; elle est manquée parce que l'échelle des tentatives (règles A8.2 de 0.3.1 : ouverture 91 %, sauts +5 % / +3 % et +5 kg) ne monte pas jusqu'à elle (cible ≤ max du jour 20-31 %, cible tentée 4-11 %). Nouveau modèle dans `planification.evaluer` : réussite = (échelle simulée depuis l'estimation que Koach aura le jour J atteint la cible) ET (capacité du jour ≥ cible) ; effet de jour de séance commun aux cibles ; gain d'affûtage ; pour répétitions / tenues : rendement gaussien. Paramètres MESURÉS (graines 0 à 5, pas d'ajustement par vraisemblance : il ne se généralise pas d'une graine à l'autre) : `erreur_estimation_echeance_sd` 0,040 ; `tentative_sd_jour` 0,046 ; `tentative_manque` 0,028 ; `gain_affutage` 0,007 (aussi ajouté à l'ouverture de l'échelle, comme `coachTaperGain` de 0.3.1) ; `marge_cible` 0,045 ; `rendement_test_sd` 0,055 ; `tentative_cible_proba` 0,35. Graines 2-5 (non vues) : écart ≤ 6 points sur d0-d6, 10 points sur d7 (n = 33). Graines 0-1 : sur-prédit de 6 à 18 points (à remesurer en campagne).
- **Critère 2** : `criteres_moteur.mauvais_jour_apparie_saison` (rejeu du journal : base[0..j) + séance du mauvais jour + base(j..)) ; `mesurer_mauvais_jour(apparie=True)` ; campagne : critère = apparié, saisons divergentes rapportées. Mesure appariée avant correction : 1,15 % (encore > 1 %). **Correction** : branche « mauvais jour » où les capacités sont « considérées » (`jour.mauvais_jour_fige_capacite` = true, `modele._observer(fige_alt=…)`) → 0,93 / 0,93 / 0,81 % (36 saisons) ; et l'erreur d'e1RM du sous-ensemble passe de 3,91 à 3,68 %.
- Campagne : critère 1 = moyenne des trois vérités ; critère 5 par cible (déciles ≥ 30) ; rejeu réel rapporté seulement (`campagne.py`, `tests/test_campagne.py` adaptés).
Reste : pytest complet, fixtures (13), campagne complète (cache à refaire), banc adversarial (comparaison), rejeu du journal réel (rapport), contrat/SOURCES/README/params version 1.0.1, relecture indépendante (Opus), commit moteurs, livraison, état, page de suivi, notification.
