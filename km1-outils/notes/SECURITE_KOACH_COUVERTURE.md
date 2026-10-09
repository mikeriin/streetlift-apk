# Règles de sécurité de kalis_adapt 0.3.1 dans Koach 1.0 : couverture règle par règle

Rédigé le 09/10/2026. Inventaire de référence : `notes/SECURITE_0_3_1.md` (partie A). Code Dart 0.3.1 :
`moteurs/packages/kalis_adapt/lib/src/` (« A/ » ci-dessous), lu en lecture seule. Code Python :
`moteurs/packages/kalis_adapt/reference/koach/securite.py` (`Gardefous`) et `koach/seance.py` (`Seances`).

Statuts :

- **déjà** : reprise avant ce lot (CONTRAT_1_0.md § 8.1) ;
- **ajoutée** : reprise dans ce lot (clés de paramètres dans `params/koach_params_v1.json`, section `securite`) ;
- **partielle** : reprise en partie, le reste est expliqué ;
- **non reprise** : applicable mais absente (raison donnée) ;
- **sans objet** : la règle ne peut pas s'appliquer à Koach (mode 0.1 remplacé, revue hebdomadaire absente,
  règle de hausse et non de borne, donnée que l'interface de Koach ne reçoit pas).

## Tableau

| Règle 0.3.1 | Statut | Dans Koach (fichier, fonction) | Raison, écart |
| --- | --- | --- | --- |
| A1.1 seuil 3/10, zone active 14 j, zone bloquante | déjà | `securite.active`, `conduite` | — |
| A1.2 pas de hausse, +1 RIR, lignes gelées | déjà | `conduite`, `seance._cible_*` | Plus prudent : plafond = dernier passage de l'exercice. |
| A1.3 retrait (forte ≥ 4, moyenne ≥ 5) | déjà | `conduite` | — |
| A1.4 allègement ≥ 4/10 (× 0,6, +1 RIR) | déjà | `conduite` | — |
| A1.5 remplaçant sous douleur | non reprise | — | Koach retire au lieu de remplacer (aucune charge sur la zone : plus prudent). Un remplaçant demande le matériel et le lieu du jour et `planSimilarity`, que `plan()` ne reçoit pas. `douleur_remplacant_part` reste non lue. |
| A1.6 test retiré (zone du jour, > 2/10 dans la semaine) | déjà | `conduite` | — |
| A1.7 proposition « épargner la zone » | sans objet | — | Proposition de la revue hebdomadaire de 0.3.1 à kalis_plan ; Koach n'a pas de revue de ce type. La conduite retire ou allège à chaque séance. |
| A2.1 déclenchement de l'arrêt (a)–(d) | déjà | `securite._arrets` | — |
| A2.2 pendant l'arrêt : retrait, premier palier, escalade | déjà | `conduite` | — |
| A2.2 renvoi vers un professionnel (1re séance, puis chaque semaine d'arrêt) | **ajoutée** | `securite.renvois`, `seance.ouvrir` → raison `koach.douleur_persistante` | A/session.dart:574-580, 2397-2420. Plus prudent : un arrêt déclenché en fin de séance reçoit son renvoi à la séance suivante. |
| A2.2 remplacement d'une poussée du poignet par parallettes/poignées | non reprise | — | Même raison que A1.5 (matériel du jour inconnu) : la poussée est retirée (plus prudent). |
| A2.3 course retirée pendant un arrêt du bas du corps ; retour à ≤ 50 % | **ajoutée** | `seance._endurance` (étape 0 et part de reprise), `securite.arrets_jambe`, `reprise_jambe` | A/session.dart:2527-2567, 2626-2628. |
| A3.1–A3.3 reprise graduée, arrêt gardé, paliers, recul, 67,5 % + 2,5 %/palier, tests retirés | déjà | `securite.reprise`, `arret`, `conduite` | — |
| A3.3 dose plafonnée dans la séance (reps, secondes, charge jamais au-dessus de la série précédente) | **ajoutée** | `conduite` (`dose_plafonnee`), `seance._cible_charge/_cible_reps/_cible_tenue`, `_mesure_utile` | A/session.dart:1309-1315 ; A/coach_advice.dart:109-150. Avant : seule la charge était bloquée dans la séance. |
| A4.1 première gêne du poignet → appui neutre | **partielle** | `securite._poignet`, raison `koach.poignet_appui_neutre` | A/session.dart:442-487, 2438-2460. Pas de remplacement (matériel du jour inconnu, cf. A1.5) : la ligne est gardée à la dose écrite (repli de 0.3.1 sans appui neutre) **et sans hausse** (plus prudent), l'appui neutre est conseillé par la raison. `sw-pompe-inclinee` n'est jamais tenue pour neutre (la barre basse du jour est inconnue). |
| A4.2 arrêt du poignet : charge externe d'appui retirée (arrêt gardé compris), poignet « chaud » | **ajoutée** | `securite._poignet`, `poignet_chaud` ; causes `poignet_charge`, `poignet_chaud` de `koach.douleur_retrait` | A/session.dart:552-563, 816-849, 2876-2891. Remplaçant parallettes/poignées : non (cf. A2.2). |
| A4.3 poignet sensible : dose plafonnée | **ajoutée** | `securite.poignet_sensible`, `_poignet` ; raison `koach.poignet_dose` | A/session.dart:1330-1335, 1688-1716. Plus prudent : reprise comptée sur toute la fenêtre de surveillance (84 j). |
| A5.1 lecture du bilan, paliers | déjà | `securite.palier_bilan` | — |
| A5.2 effets des paliers | déjà | `seance._item`, `_cible_charge`, `_tentative` | Capacité prévue non baissée du décalage (le bilan agit par l'a priori de l'effet de jour du modèle) : voir « Doutes ». Palier 2 sans technique d'intensification : ajouté (A9.2). Jour sans d'endurance : ajouté (A10.2). |
| A6.1 reprise après coupure ≥ 14 j : séries × 0,8 | déjà, **complétée** | `seance._coupure`, `_item` | A/session.dart:1096-1146. Ajouté : la règle vaut toute la semaine du retour (fenêtre de 7 j, `coupure_fenetre_j`) et s'applique aussi à l'échauffement. Avant, Koach ne l'appliquait qu'à la première séance (moins prudent). |
| A6.2 alerte de surmenage (−40 % des lignes, 7 j) | **ajoutée** | `seance._formes`, `_forme`, `_surmenage` ; raison `koach.surmenage` | A/model.dart:432-475, 1470-1471 ; A/coach.dart:923-958. Grandeur suivie : ln capacité à frais + effet de jour de la séance (mélange des deux branches), analogue de `f.m[0] + f.m[3]`. Toute séance avec une série faite compte comme mesurée (plus fréquent que `run.measured`). |
| A6.3 décharge anticipée (revue) | sans objet | — | Proposition de la revue hebdomadaire ; la planification de Koach est bornée (§ 8.4) et validée par le validateur injecté (critères B11, B12). |
| A6.4 récupération déclarée réduite | non reprise | — | Donnée non reçue : le profil de Koach ne porte ni sommeil habituel, ni stress, ni métier. La règle porte sur les propositions de hausse de volume de la revue ; voir « Doutes » (la planification de Koach peut monter le volume de 15 %). |
| A6.5 semaine verrouillée | déjà | `verrou` | — |
| A6.5 test chargé en semaine verrouillée ≤ charge écrite | **ajoutée** | `seance._cible_test` (test xRM) | A/coach.dart:2144-2152. Ajouté aussi : après un échec non prévu à la dernière séance, pas plus lourd que le dernier passage (`noUp`, A/coach.dart:2086, 2154-2160). |
| A6.5 échéance ≤ 14 j | partielle | `_mesure_utile` (`jours_avant_echeance`) | Le banc ne fournit que `jour_evenement`, pas `jours_avant_echeance` : la règle est inactive sur le banc (annexe A n° 43). Couloir, double progression, série au ressenti : Koach n'a pas ces hausses (sans objet). |
| A7.1 bornes du mode 0.1 | sans objet | — | Mode 0.1 remplacé par le mode coach. |
| A7.2 bornes 10/5/5/5 %, un cran, couloir, simple 92 % | déjà | `_bornes_hausse`, `_cible_charge` | Voir « Règles moins prudentes non corrigées » (accessoires × 2 ; schéma changé). |
| A7.2 zone fragile du profil (antécédent < 12 mois ou gêne ≥ 2) : hausse × 0,5, 0 répétition comptée, paliers 5 % | **ajoutée** | `securite._zones_fragiles`, `fragile`, `conduite` (`fragile`) ; `seance._bornes_hausse` ; raison `koach.zone_fragile` | A/replay.dart:42-51, 120-125 ; A/coach.dart:830-833, 1146-1149, 1218-1226. Schéma nouveau sur zone fragile : +5 % (moitié de 10 %), aucune part pour les répétitions de moins, un cran au moins. |
| A7.2 surcharge sur zone fragile ≤ `coachOverloadFragileMax` | **ajoutée** | `seance._cible_charge` | A/coach.dart:1039-1042. Appliqué aussi à une part écrite sur le 1RM de l'exercice lui-même (plus prudent). |
| A7.2 double progression « 2 pour 2 », bonification | sans objet | — | Règles de hausse, pas de borne. |
| A7.2 exercice nouveau écrit en % d'un autre mouvement (60 %, paliers 10/5 %) | non reprise | — | Koach ne lit pas la part comme une part du 1RM d'un autre mouvement : il calibre (charge choisie par l'utilisateur si σ > 0,12) puis suit son propre modèle au quantile prudent. |
| A7.3 sans charge (couloir, `coachDirectGuardRir`) | non reprise | `_cible_reps` (règles propres) | Modèle propre (prévision au quantile e^(−σ/2), verrous échec/douleur/bilan, zone récente +10 %). Voir « Doutes ». |
| A7.4 conseil : −15 %/+5 %, −7,5 % gardé, arrêt après 2 échecs | déjà | `cible`, `_cible_charge` | `stop_at_rir`, propreté, chute de répétitions : non lus (voir « Doutes »). |
| A8.1 conditions d'un test | déjà | `_item`, `conduite` | Report à 48 h : sans objet (re-service, pas une borne). Test de course plus long que la borne : ajouté (A10.3). |
| A8.2 échelle des tentatives | déjà | `_tentative` | Bonification d'affûtage : sans objet (hausse). |
| A8.3 séries repères | déjà | `_mesure_utile`, `_repere` | Ajouté : jamais sur une ligne à dose plafonnée. |
| A9.1 tendons, hausse par tenue | déjà | `_cible_tenue` | — |
| A9.1 temps total de l'emplacement | **ajoutée** | `seance._cible_tenue`, `Memoire.sec_slot` ; raison `koach.tendon` cause `total` | A/coach.dart:1895-1929. Sans le plancher de 55 % du meilleur maintien ni `_keptTotal` (plus prudent). |
| A9.2 techniques réservées au niveau ; techniques qui intensifient | **ajoutée** | `seance._technique`, `equivalent_standard` ; raison `koach.technique_retenue` | A/coach.dart:123-155, 753-790 ; A/session.dart:951-973, 1622-1686. Excentrique accentué à ≤ 10 j d'une échéance : seulement si `jours_avant_echeance` est fourni. |
| A9.3 élastique | sans objet | — | Koach ne décide pas des crans (événement `cran` fourni par l'appelant). |
| A9.4 séries fractionnées | sans objet | — | Koach n'ajoute jamais de séries (plus prudent). |
| A9.5 étapes de figures | non reprise | — | Pas de module de progression d'étapes : Koach sert l'étape écrite par le plan ; une douleur active sur l'étape relève de la conduite générale (retrait ou sans hausse). |
| A10.1 reprise après coupure (70 % / 50 %) | **ajoutée** | `seance._endurance` (étape 1), `_fermer_endurance` | A/session.dart:2569-2643. |
| A10.2 jour sans : qualité → course facile, palier 2 × 0,7 | **ajoutée** | `seance._endurance` (étape 2), `_qualite`, `_course_trop_dure` ; raisons `koach.course_facile`, `koach.endurance_retrait`, `koach.endurance_raccourcie` | A/session.dart:2577-2713 ; A/endurance.dart:240-255, 295-306, 383-390. Course facile seulement si son matériel figure dans celui de la séance écrite et si le lieu du jour le permet (Koach ne connaît pas le matériel du jour) ; sinon la séance de qualité est retirée (repli de 0.3.1). |
| A10.3 sortie bornée (+10 % sur la plus longue des 30 j), test plus long → course bornée | **ajoutée** | `seance._endurance` (étape 3) ; raison `koach.course_bornee` | A/session.dart:2716-2813. Effort borné à `flammes_de_rir(5) + 1` = 2 flammes (code 0.3.1 ; l'inventaire dit 6 : erreur de l'inventaire). |
| A10.4 conditionnement × 0,75 après jours durs ou jour sans | **ajoutée** | `seance._endurance` (étape 4), `_serie_wod` ; raison `koach.wod_echelle` | A/session.dart:2815-2846 ; A/endurance.dart:257-281. |
| A10.5 fatigue croisée (course dure la veille → −1 flamme bas du corps) | **ajoutée** | `seance._endurance` (étape 5) ; raison `koach.fatigue_croisee` | A/session.dart:2848-2871. |
| A11 propositions de volume de la revue | sans objet | — | Revue hebdomadaire absente ; plafonds de la planification et validateur injecté (B2, B3). |
| A12 débutant | déjà, **complétée** | `_cible_charge` (charge écrite), `_repere` (2 RIR), `_technique` | Techniques de niveau ≥ 1 retirées : ajouté (A9.2). |
| A13 génération kalis_plan | sans objet | — | Règles d'écriture du bloc ; restent dans le plan de référence. |

## Règles moins prudentes dans Koach que dans 0.3.1, non corrigées

1. **Hausse des accessoires doublée** (`_bornes_hausse`, rôle ni `main` ni `secondary` : 2 × 10/5/5/5 %). En mode
   coach, 0.3.1 borne la cible de toute ligne chargée à `coachRise[niveau]` (A/coach.dart:1146-1149) ; le doublement
   `riseCap` (A/session.dart:1293-1295) ne sert qu'à la règle générale de 0.1. Corrigé puis retiré : coût mesuré sur
   SET9 (voir ci-dessous).
2. **Schéma changé au même emplacement** (A7.2 règle 4, A/coach.dart:1200-1235) : 0.3.1 borne la charge sur la
   dernière séance de l'emplacement × (1 + hausse du niveau) × (1 + 2,5 %/rép.) ; Koach borne un schéma nouveau sur la
   plus lourde barre récente × 1,10 × (1 + 2,5 %/rép.) (règle 5 de 0.3.1), soit jusqu'à ≈ 5 points de plus pour un
   intermédiaire. Corrigé puis retiré : coût mesuré (voir ci-dessous). Le critère « hausse > 10 % d'un mouvement
   principal » du banc reste à 0.

Effet mesuré de ces deux corrections (SET9, 4 graines, toutes les autres règles actives ; règle 2 limitée aux
schémas nouveaux à l'emplacement, sa forme la moins coûteuse ; MAE / couverture) :

| Variante | modele a k=6 | modele b k=6 | modele c k=6 | ecart effort | echeance loaded |
| --- | --- | --- | --- | --- | --- |
| retenue (ni 1 ni 2) | 0,0251 / 0,935 | 0,0438 / 0,861 | 0,0323 / 0,824 | 3,080 | 0,9410 |
| avec 1 seule | 0,0249 / 0,935 | 0,0435 / 0,861 | 0,0326 / 0,824 | 3,117 | 0,9406 |
| avec 2 seule | 0,0252 / 0,935 | 0,0443 / 0,852 | 0,0338 / 0,815 | 3,148 | 0,9401 |
| avec 1 et 2 | 0,0251 / 0,935 | 0,0443 / 0,843 | 0,0331 / 0,815 | 3,206 | 0,9405 |

## Doutes

- A5.2 : 0.3.1 baisse la capacité prévue du décalage du bilan ; Koach ne l'applique pas (`Seances.decalage` non lu) et
  compte sur l'a priori de l'effet de jour (`modele.debut_seance`). Non prouvé équivalent.
- A6.4 : la planification de Koach peut monter le volume d'une qualité de 15 % sans connaître la récupération déclarée.
- A7.3, A7.4 : règles sans charge et conseil d'entre-séries de 0.3.1 (`coachDirectGuardRir`, `stop_at_rir`, propreté,
  chute de répétitions) remplacées par le modèle de Koach ; pas d'équivalence prouvée.
- A6.2 : la grandeur suivie (capacité à frais + effet de séance) n'est pas exactement celle de 0.3.1.
- `rejeu/journal_app.py` transmet encore les zones fragiles comme de simples codes : elles sont toutes tenues pour
  fragiles (plus prudent que 0.3.1). Le banc (`banc/politique_koach.py`) transmet désormais ancienneté et gêne.

## Mesures (km1-outils/essai2.py)

`python3 essai2.py $(cat SET9) reference 4` :

| Ligne | Avant | Après |
| --- | --- | --- |
| saisons, gain, aggr, flares | 108, 0.00076, 0, 0 | 108, 0.00077, 0, 0 |
| modele a principaux k=6 | MAE=0.0267 biais=+0.0058 couv=0.944 | MAE=0.0251 biais=+0.0050 couv=0.935 |
| modele b principaux k=6 | MAE=0.0446 biais=-0.0251 couv=0.843 | MAE=0.0438 biais=-0.0240 couv=0.861 |
| modele c principaux k=6 | MAE=0.0328 biais=-0.0112 couv=0.824 | MAE=0.0323 biais=-0.0109 couv=0.824 |
| ecart effort | 3.096 echecs 0.0231 hausses 0 | 3.080 echecs 0.0230 hausses 0 |
| echeance loaded | 144 best/max 0.9406 best/cap0 0.9274 | 144 best/max 0.9410 best/cap0 0.9278 |

`python3 essai2.py street_07…,autres_02…,street_16… douleur_coude,douleur_epaule 2` :

| Ligne | Avant | Après |
| --- | --- | --- |
| saisons, gain, aggr, flares | 36, -0.00030, **0, 0** | 36, -0.00030, **0, 0** |
| modele a/b/c principaux k=6 | 0.0308/0.917 ; 0.0348/0.917 ; 0.0324/0.875 | 0.0303/0.917 ; 0.0351/0.917 ; 0.0318/0.875 |
| ecart effort | 5.205 echecs 0.0207 | 5.215 echecs 0.0211 |
| echeance loaded | 12 best/max 0.9370 | 12 best/max 0.9383 |

La petite hausse de l'écart d'effort sous douleur vient de l'alerte de surmenage (A6.2) : sans elle, les quatre
lignes reviennent exactement aux valeurs d'avant ; sur SET9, la même règle améliore toutes les lignes (sans elle :
modele a 0.0266/0.944, ecart effort 3.095, echeance 0.9406).

Endurance (4 profils course/hybride/crossfit, 2 graines, vérités a et b ; script hors banc) : pire pic de course
2,01 → 1,10 ; blessures de surutilisation 2 → 2.
