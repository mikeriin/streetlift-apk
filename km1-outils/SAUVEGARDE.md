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
