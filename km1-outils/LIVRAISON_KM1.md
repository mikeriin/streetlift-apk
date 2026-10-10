# Livraison KM1 — référence Python de Koach 1.0

Lot moteur KM1 (voie A, tâche Fable moteurs, effort maximal ; C13). Session du 09/10/2026 16:14 UTC au 10/10/2026
@@FIN@@ UTC (lancement sans ligne « Lot : » : KM1 était le seul lot moteur « à faire »). Prompt
`pipeline/cp/prompts/KM1.txt`, cahier `pipeline/cp/CAHIER_KM.md`, DECISIONS_CP.md C13 et section KM1.

**Résultat : 6 critères du cahier atteints sur 11, 4 non atteints, 1 non mesurable dans ce lot (parité Python/Dart :
c'est KM2). 0 violation de sécurité.** Aucun seuil du cahier n'a été changé. Le cahier dit qu'un critère en échec
bloque la bascule : la référence est livrée pour décision du pilotage (C8.1), pas comme une bascule acquise.

## 1. Ce qui est livré

| Objet | Où | État |
| --- | --- | --- |
| Référence Python de Koach 1.0 | `moteurs` @@COMMIT@@, `packages/kalis_adapt/reference/` | 224 tests verts |
| `kalis_bench` **0.3.1** (ajouts seulement) | `etiquettes/kalis_bench-v0.3.1` | contrôle complet run @@RUN@@ (`claude/ci-cp-a`), 5 paquets verts |
| `kalis_adapt` | inchangé (0.3.1) ; `lib/` non touché | aucune étiquette (elle viendra de KM2) |

Dans `packages/kalis_adapt/reference/` (voir son `README.md`) :

1. **Contrat gelé** `CONTRAT_1_0.md` : API `observe(événement)`, `posterior()`, `plan(contraintes)`, `explain()` ;
   schéma du journal ; modèles de mesure ; règles de sécurité règle par règle ; 306 paramètres ; portage Dart ;
   annexe A des écarts au cahier et des limites connues.
2. **Vecteurs de qualités** des 1 039 exercices (`qualites/`), posés par règles, relus par un sous-agent Opus.
3. **Estimation** (`koach/modele.py`) : état gaussien sur dix qualités, un écart par exercice, mesure du RIR en
   flammes (bruit qui dépend de la réserve, note aberrante, note paresseuse apprise, biais proportionnel appris),
   e1RM sur la masse totale, fatigue par compartiments, branche « mauvais jour », a priori par niveau, vrai test
   seulement quand l'intervalle à 90 % dépasse ± 6 %.
4. **Banc adversarial** (`banc/adversaire.py`) : recherche bornée dans un espace de 23 dimensions autour des
   athlètes du banc, export `donnees/adversaires_v1.json` pour KM2.
5. **Planification** (`koach/planification.py`) : P(toutes les cibles) avec le rendement d'un test, jumeau de
   1 000 trajectoires à nombres aléatoires communs, entropie croisée (256 plans), transport optimal contre le plan de
   `kalis_plan`, plafonds ± 15 % (volume par qualité) et ± 5 % (intensité), validateur de sécurité obligatoire.
6. **Adhérence, rupture, diagnostic, dossier hors modèle, import de paramètres** (`koach/adherence.py`,
   `koach/rupture.py`).
7. **Contrôle dual** (`koach/dual.py`) : tirage de Thompson, essais N-of-1 par bras de 3 semaines, contrôle
   synthétique.
8. **Rejeu walk-forward** du journal réel (`rejeu/`), agrégats seulement.

Avec : `SOURCES.md` (une ligne par paramètre : 1 référence publiée vérifiée, 27 mesures sur le banc, 116 valeurs
reprises de 0.3.1, 162 choix raisonnés dont 23 valeurs fixées par le cahier), 13 fixtures de parité (5,9 Mo,
`fixtures/`), la campagne de mesure (`banc/campagne.py`), le port Python des modèles de vérité et des critères de
sécurité du banc Dart (vérifié sur les traces et sur 240 saisons).

`kalis_bench` 0.3.1 : exports pour la référence (modèles de vérité, saisons de référence, fiches, témoin 0.3.1,
sécurité de blocs écrits ailleurs, saisons du témoin sur des athlètes adversariaux). Critères, profils, grilles et
rapport du banc inchangés.

## 2. Critères du cahier, mesurés

Témoin : `kalis_adapt` 0.3.1 × `kalis_plan` 0.3.1, mesuré par `kalis_bench` (Dart) sur les mêmes profils, scénarios,
modèles de vérité et graines. Campagne finale : 27 profils, 240 saisons (tous les scénarios du banc), 3 modèles de
vérité, 2 graines, soit **1 440 saisons**, Koach complet (planification, surveillance, contrôle dual, adhérence).
Fichier : `donnees/criteres_km1.json`.

| N° | Critère du cahier | Seuil | Koach 1.0 | Témoin 0.3.1 | Atteint |
| --- | --- | --- | --- | --- | --- |
| 1 | Erreur d'e1RM après 6 séances (mouvements principaux chargés) | < 3 % | **4,24 %** (vérité A 2,97 ; B 5,89 ; C 3,86 ; n = 1 722) | 7,11 % (4,91 ; 10,51 ; 5,91) | **non** |
| 2 | Effet d'un mauvais jour isolé (−6 %) sur l'estimation | < 1 % | **1,14 %** juste après (médiane 0,82 %), 1,00 % une séance plus tard | non mesuré | **non** |
| 3 | Séances pour passer sous 3 % d'erreur | ≤ 0.3.1 | 2,7 séances quand c'est atteint ; jamais dans 9,2 % des cas | 6,2 séances ; jamais dans 30,7 % | oui |
| 4 | Couverture de l'intervalle à 90 % (banc) | 88 à 92 % | **88,5 %** (n = 23 974) | — | oui (banc) |
| 5 | Calibration de P(réussite), par tranche de 10 % | ≤ 5 points | **15 points** au pire (par cible : 0,9 ; 10,2 ; 11,8 ; 8,2 ; 8,5 points sur les cinq tranches peuplées) | — | **non** |
| 6 | Performance le jour J (meilleure barre / maximum vrai du jour) | ≥ 0.3.1 | **0,933** (174 saisons appariées, écart +0,004 ± 0,004) | 0,925 | oui |
| 7 | Pire cas du banc adversarial (jour J) | ≥ 0.3.1 | **0,789** (moyenne 0,864 ; 18 adversaires testés par les deux) | 0,264 (moyenne 0,799) | oui |
| 8 | Violations de sécurité | 0 | **0** : 0 aggravation, 0 poussée de douleur, 0 hausse de plus de 10 %, 0 constat du validateur introduit par le plan modulé ou par les séances servies | 20 poussées de douleur, 18 constats sur les mêmes saisons | oui |
| 9 | Parité Python / Dart | 1e-9 | fixtures prêtes (13 fichiers) ; pas de moteur Dart dans ce lot | — | non mesurable (KM2) |
| 10 | Rejeu du journal réel depuis S12 | erreur < 3 %, couverture 88 à 92 % | erreur moyenne **4,3 %** (médiane 2,2 %), couverture **97 %** (38 séries notées, 11 séances) | — | **non** |
| 11 | Temps de calcul | replanification ≤ 10 s, série ≤ 50 ms | 0,44 s et 5,4 ms au pire (Python, machine de la session) | — | oui (à refaire sur la VM Dart en KM2) |

Autres mesures de la campagne (Koach / témoin) : erreur au rang 6 des exercices en répétitions 9,8 % / 20,1 %, des
tenues 14,3 % / 27,0 % ; échecs non voulus 0,69 % / 0,72 % ; progression hebdomadaire +0,28 % / +0,25 % ; écart
d'effort (réserve servie contre réserve écrite) 3,3 / 1,5 : Koach s'écarte plus de la réserve écrite que 0.3.1 (tests
en montée, lignes allégées par les règles de sécurité).

### Pourquoi quatre critères ne passent pas

- **Erreur d'e1RM (4,24 % pour 3 %).** Atteint sur le modèle de vérité A, pas sur B ni C. B a une courbe
  charge-répétitions très linéaire et un biais de notation fort ; les débutants restent les plus mal estimés. Les
  règles de sécurité ajoutées en fin de lot (montée de test dans le budget de séries et de durée, pas de test au
  retour d'une coupure, retour gradué du volume) ont coûté environ 0,3 point : 3,9 % avant elles. Piste : forme de
  courbe par famille d'exercices plutôt qu'une seule par athlète ; a priori du débutant.
- **Mauvais jour (1,14 % pour 1 %).** La branche « mauvais jour » absorbe la plus grande part de l'écart ; le reste
  vient de ce que la saison simulée diverge après le mauvais jour (charges servies différentes). Médiane 0,82 %.
- **Calibration de P(réussite).** Les cibles des profils du banc ne sont presque jamais toutes atteintes (1 saison
  sur 225) : seules les tranches basses sont peuplées, et la probabilité par cible reste trop haute de 8 à 12 points
  entre 10 et 50 %. Le rendement d'un test (la barre réussie vaut en moyenne 93,7 % du maximum du jour) est maintenant
  dans le modèle ; il manque la corrélation entre cibles et l'effet de l'affûtage.
- **Rejeu du journal réel.** 35 séances exploitables (S8 à S13), 896 séries dont 712 sans note ; 38 séries notées
  évaluées depuis S12. Une série notée isolée porte à elle seule environ 3 % de bruit : l'erreur moyenne de 4,3 %
  (médiane 2,2 %) et la couverture de 97 % (37 séries sur 38) sont jugées sur trop peu de points pour conclure. Sur
  les mouvements principaux à 6 répétitions ou moins, l'erreur est de 1,5 % sur 7 séries ; une huitième, légère (6 répétitions bien en dessous de la charge de travail), est à 24 % et le test de 25 répétitions à 7 %.
  Le premier rejeu donnait 55,8 % d'erreur : il a révélé le cliquet des séries sans note, corrigé (§ 4).

## 3. Sécurité

- Règles de `kalis_adapt` 0.3.1 reprises en contraintes dures, tableau règle par règle au contrat § 8.1 : douleur du
  jour, arrêt et renvoi vers un professionnel, reprise graduée, poignet, zones fragiles du profil, bilan de santé,
  coupure, surmenage, semaines verrouillées, bornes de hausse, tests et tentatives, tendons, techniques, endurance et
  conditionnement. Non reprises, avec la raison : remplaçant sous douleur (Koach retire la ligne), récupération
  déclarée réduite (donnée non reçue), étapes de figures, exercice nouveau écrit en part d'un autre mouvement.
- Plus prudent que 0.3.1 : sous douleur ou en reprise, jamais plus lourd que le dernier passage ; budget hebdomadaire
  de séries par zone en reprise ; **retour gradué au volume** par groupe musculaire (mêmes formules que le critère
  `volume_trop_vite` du banc) ; durée de séance bornée ; montée de test comptée dans les séries et la durée de la
  ligne ; pas de test maximal ni de vrai test au retour d'une coupure ; ouverture d'une tentative jamais au-dessus de
  ce que les barres récentes justifient.
- Mesure : 1 440 saisons, dont 324 avec une douleur imposée. **0 aggravation et 0 poussée** (témoin : 20 poussées).
  Validateur du banc sur le plan modulé et sur les séances servies : 0 constat introduit.
- **Classé à part, à trancher (DECISIONS KM1.5)** : 284 constats « retour à l'écrit » (265 de volume, 19 de tenues).
  Le banc compte une séance manquée à son volume écrit ; ce volume écrit dépasse la rampe calculée sur des semaines
  que Koach avait allégées. Koach n'y sert rien de plus que le plan.

## 4. Ce que les mesures ont fait changer

- Rejeu réel : les séries sans note, versées comme « au moins n répétitions », faisaient monter la capacité sans fin.
  Elles ne sont plus versées que si la prévision les contredit, sans déplacer la forme de la courbe.
- Plateau simulé : les notes ouvertes (« 4 en réserve ou plus ») faisaient dériver l'estimation vers le haut ; elles
  ne comptent plus que près de la borne.
- Séances servies passées au validateur du banc : les montées de test ajoutaient du volume et de la durée ; le plan
  modulé revenait d'un coup à la référence ; le volume revenait trop vite après une douleur. Trois règles ajoutées.
- Banc adversarial : ouverture trop prudente après un diagnostic « rien de spécial » (64 % du maximum), puis
  ouverture à la moitié du maximum un jour de bilan bas ; les deux corrigées.
- Deux relectures indépendantes du code (Opus) : 4 bloquants et 8 majeurs, puis 3 majeurs ; traités ou déclarés à
  l'annexe A du contrat.

## 5. Limites (annexe A du contrat)

- Les crochets d'extension (semaine allégée, modulation hebdomadaire, bras d'essai, forme d'adhérence) sont appliqués
  par l'appelant : `plan()` seul ne les applique pas. KM2 devra les brancher dans la façade.
- La référence de planification n'est pas un événement du journal : le rejeu exact vaut pour l'estimation et les
  séances (testé bit à bit), pas pour la planification sans que l'appelant recharge la référence.
- La demi-largeur de l'intervalle passe rarement sous 6 % : le contrôle dual se déclenchera peu, et le vrai test reste
  souvent éligible (tous les 14 jours au plus, dans le budget de la ligne).
- Aucun essai N-of-1 ne tient dans une saison de 16 semaines du banc : code testé sur cas construits seulement.
- Le « résidu d'e1RM » du secours de rupture est le déplacement de la capacité du jour, moins sensible que le texte
  du cahier ; la détection principale (BOCPD, alerte à 0,6) est validée : 2,3 alertes pour 100 séances sur tous les scénarios de la campagne finale ; sur les saisons de référence, 0,77 fausse alerte pour 100 séances dans la validation du 09/10 (`donnees/validation_briques_6_7.json`, état antérieur du moteur, non refaite ; le test réduit du moteur final reste sous 3 %).
- La structure du programme n'est jamais modifiée (volume et intensité seulement).
- Sur un plateau avec des séries toujours loin de l'échec, l'estimation dérive de +4 à +7 % en 24 semaines (elle suit
  la progression a priori) ; l'intervalle s'élargit et un vrai test corrige.
- Biais du RIR : la part additive n'est pas apprise. 18 clés de paramètres ne sont pas lues par le moteur.
- Le témoin Dart du banc adversarial a été mesuré sur les adversaires trouvés avant la dernière correction (vitesse de
  course pour la durée d'une séance), sans effet sur des athlètes de force.

## 6. Données privées

Le journal du propriétaire a été déchiffré sous `/tmp` (clé par fichier en mode 600, supprimé après usage) et n'a
jamais été copié dans le dépôt. Sont publiés des agrégats seulement (`donnees/rejeu_journal_agregats.json` : aucune
cellule de moins de 3 séries, aucune date, aucun identifiant d'exercice ou de séance). Les détails par série n'ont pas
été conservés : ils se recalculent avec `rejeu/walk_forward.py --details`.

## 7. Ce qui reste

1. Décisions du pilotage : lectures du cahier (DECISIONS KM1.2), classement des « retours à l'écrit » (KM1.5),
   suite à donner aux quatre critères non atteints (nouveau tour de KM1 sur l'estimation, ou KM2 sur cette base).
2. KM2 : portage Dart à l'identique (fixtures), façade avec les crochets d'extension, référence de planification au
   journal, temps sur la VM Dart, validateur de sécurité côté Dart (il existe dans `kalis_bench`).
3. Estimation : forme de courbe par famille d'exercices, débutants, calibration de P(réussite).

## 8. Budget et sauvegardes (PIPELINE_CP.md § 9)

Tous les sous-agents sur Opus (aucun sur Fable). Sauvegardes complètes sur `cp-sauvegardes/KM1` à chaque étape
(arbre sans `.github/`, avec `SAUVEGARDE.md` et les outils de travail `km1-outils/`). Aucune tâche planifiée créée,
modifiée ou lancée.
