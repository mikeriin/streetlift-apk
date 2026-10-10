# Livraison KM1 correction 1 — référence Python de Koach 1.0.1

Passe « KM1 correction 1 » (DECISIONS_CP.md C13.10, `LANCEMENTS.md` section du même nom), voie A, tâche Fable moteurs,
effort maximal. Session du 10/10/2026, 09:15 à 17:00 UTC environ (lancement sans ligne « Lot : » : KM1 était le seul
lot moteur « à faire »). Base : `moteurs` f3801e36 (Koach 1.0).

**Résultat : 7 critères du cahier atteints sur 11 (6 avant). Le mauvais jour isolé passe (0,95 % pour 1 %). L'erreur
d'e1RM (3,98 % pour 3 %) et la calibration de P(réussite) par cible (22 points pour 5) ne passent pas. Parité
Python/Dart : KM2. Rejeu du journal réel : critère de bascule, non refait dans cette passe (voir § 6). 0 violation de
sécurité. Aucun critère atteint en KM1 n'a reculé.** Aucun seuil n'a été changé.

## 1. Les 11 critères, avant et après

Campagne identique à celle de KM1 : 27 profils, 240 saisons (tous les scénarios), 3 modèles de vérité, graines 0 et 1,
soit 1 440 saisons, Koach complet (planification, surveillance, contrôle dual, adhérence), témoin `kalis_adapt` 0.3.1
× `kalis_plan` 0.3.1. Fichiers : `donnees/criteres_km1.json` (après), `donnees/criteres_km1_avant_correction1.json`
(avant).

| N° | Critère du cahier | Seuil | Avant (Koach 1.0) | Après (Koach 1.0.1) | Témoin 0.3.1 | Atteint |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Erreur d'e1RM après 6 séances, moyenne des vérités A, B, C | < 3 % | 4,24 % (A 2,97 ; B 5,89 ; C 3,86) | **3,98 %** (A 2,80 ; B 5,43 ; C 3,71 ; n = 1 722) | 7,11 % | **non** |
| 2 | Effet d'un mauvais jour isolé (−6 %), contrefactuel apparié | < 1 % | 1,14 % en saisons divergentes (mesure de KM1) ; 1,15 % en mesure appariée avant la correction de la branche « mauvais jour » | **0,95 %** au pire des trois horizons (0,89 % juste après, 0,95 % une séance plus tard, 0,82 % deux séances plus tard ; médiane 0,65 % ; 36 saisons) | non mesuré | **oui** |
| 3 | Séances pour passer sous 3 % | ≤ 0.3.1 | 2,7 séances ; jamais 9,2 % | 2,8 séances ; jamais 9,2 % | 6,2 séances ; jamais 30,7 % | oui |
| 4 | Couverture de l'intervalle à 90 % | 88 à 92 % | 88,5 % | **90,4 %** (n = 23 923) | — | oui |
| 5 | Calibration de P(réussite) par cible, déciles d'au moins 30 cas | ≤ 5 points | 11,8 points (ancien modèle, déciles d'au moins 20 cas) | **22,1 points** au pire décile (voir § 3) ; erreur pondérée sur tous les cas 4,5 points | — | **non** |
| 6 | Performance le jour J (meilleure barre / maximum vrai du jour) | ≥ 0.3.1 | 0,933 | **0,941** (174 saisons appariées, écart +0,014 ± 0,002) | 0,925 | oui |
| 7 | Pire cas du banc adversarial (jour J) | ≥ 0.3.1 | 0,789 | **0,799** (moyenne 0,872 ; 18 adversaires testés par les deux ; témoin : pire 0, moyenne 0,603) | — | oui |
| 8 | Violations de sécurité | 0 | 0 | **0** : 0 aggravation, 0 poussée de douleur, 0 hausse de plus de 10 %, 0 constat du validateur introduit par le plan modulé ou par les séances servies | 20 poussées, 18 constats | oui |
| 9 | Parité Python / Dart | 1e-9 | fixtures prêtes | 13 fixtures régénérées (5,9 Mo) | — | non mesurable (KM2) |
| 10 | Rejeu du journal réel | critère de bascule (C13.10.2.d) | 4,3 % / 97 % (38 séries notées) | non refait (§ 6) | — | rapporté seulement |
| 11 | Temps de calcul | ≤ 10 s, ≤ 50 ms | 0,44 s ; 5,4 ms | 0,49 s ; 14 ms au pire (Python, machine de la session) | — | oui (à refaire en Dart, KM2) |

Autres mesures (Koach 1.0.1 / témoin) : erreur au rang 6 des exercices en répétitions 9,9 % / 20,1 %, des tenues
15,0 % / 27,0 % ; échecs non voulus 0,64 % / 0,72 % ; progression hebdomadaire +0,28 % / +0,25 % ; écart d'effort
3,3 / 1,5 ; alertes hors modèle 2,7 pour 100 séances (2,3 en KM1). Déterminisme : identique. 224 tests verts. Rupture, adhérence et contrôle dual remesurés sur 1.0.1 (`donnees/validation_briques_6_7.json` : 0,78 fausse alerte pour 100 séances en référence au seuil 0,6).

## 2. Critère 1 — erreur d'e1RM : ce qui a été fait, et pourquoi 3 % n'est pas atteint

Deux itérations de méthode, comme prévu.

**Diagnostic (mesuré, 27 profils, saison de référence, 2 graines).**
- L'erreur sur la charge aux répétitions de travail n'est que de 2,1 %. L'erreur d'e1RM (4,0 %) vient de
  l'extrapolation vers 1 répétition par la courbe charge-répétitions.
- Avec la courbe vraie de chaque exercice donnée au moteur, l'erreur tombe à 2,3 %. Avec seulement la **forme** de
  courbe de l'athlète (ce que le pilotage proposait d'apprendre par famille), elle reste à 4,1 % : ce qui coûte est
  l'**échelle de courbe propre à chaque exercice** (écart-type de 18 à 20 % dans les trois modèles de vérité), pas la
  forme.
- Cette échelle ne s'apprend que par une mesure près de l'échec à peu de répétitions. Quand elle existe avant la
  6e séance, l'erreur est de 2,0 à 3,1 % ; quand elle n'existe pas (40 % des cas : débutants, lignes sans test),
  elle est de 5,8 à 6,5 %.
- Une valeur extrême du banc pèse à elle seule 0,37 point : un exercice dont la pente tirée est à 3,5 écarts-types
  (vérité B, graine 0), répété dans 2 profils et tous les scénarios, avec −32 à −43 % d'erreur.

**Itération 1.**
- Famille de courbe de Box-Cox à la place du mélange linéaire/logarithmique : elle couvre aussi la courbe linéaire en
  part du 1RM de la vérité B (Brzycki), que l'ancienne famille ne pouvait pas représenter aux répétitions hautes.
  A priori de forme tiré de l'ajustement à sept équations publiées (Brzycki, Lander, O'Conner, Mayhew, Wathen, Epley,
  Lombardi ; écart maximal 1,8 % de charge entre 2 et 20 répétitions).
- Vrai test : une série repère ne bloque plus un vrai test pendant 14 jours ; une montée arrêtée loin de l'échec
  peut être refaite après 5 jours ; la première barre de la montée part de plus près (règle du schéma changé de
  0.3.1) ; durée de la montée comptée pour ce qu'elle fait vraiment ; un cran entier permis sur grille grossière
  jusqu'à 15 %, seulement après une série dite très facile ; test du débutant à 3 répétitions (réserve 2 gardée),
  comme le 3RM que `kalis_plan` écrit pour un débutant.

**Itération 2.**
- Branche « mauvais jour » qui ne déplace plus les capacités (voir § 4) : elle retire aussi une part du biais.
- Correction d'un bogue de Koach 1.0 dans l'élargissement de l'incertitude après la réponse « rien de spécial »
  (voir § 5).

**Pourquoi le seuil n'est pas atteint.** Les débutants restent à 6,7 % (7,6 % avant) : leur test s'arrête à 2 de
réserve dite, soit 7 à 9 répétitions possibles, et la montée n'a qu'une ou deux séries dans le volume écrit de la
ligne ; l'extrapolation depuis 8 répétitions porte 4 à 5 % d'incertitude d'échelle à elle seule. Intermédiaires
3,3 %, avancés 3,2 %, élite 2,6 %. Le plancher de ce banc, avec des tests à réserve gardée, est estimé à 3,6-3,8 %
en moyenne des trois vérités. Descendre sous 3 % demanderait une mesure sans réserve (répétitions jusqu'à l'échec)
ou des tests plus bas en répétitions chez le débutant : deux choix de sécurité, pas de méthode.

## 3. Critère 5 — calibration de P(réussite) par cible

**Constat sur les données du banc** (45 saisons à cibles × 3 vérités × graines 0 à 5) : une cible chargée n'est
jamais manquée quand elle est tentée ; elle est manquée parce que l'échelle des tentatives (règles de 0.3.1 :
ouverture à 91 %, sauts de 5 % puis 3 %, 5 kg au plus) ne monte pas jusqu'à elle. La cible est sous le maximum du
jour dans 20 à 31 % des cas, tentée dans 4 à 11 %.

**Nouveau modèle** dans le jumeau : la cible est atteinte si l'échelle, simulée depuis l'estimation que Koach aura
ce jour-là (capacité vraie plus erreur d'estimation), monte jusqu'à elle, et si l'athlète la soulève. S'ajoutent
l'effet de jour de la séance commun à toutes les cibles (corrélation entre cibles), le gain de l'affûtage (aussi
appliqué à l'ouverture de l'échelle, comme en 0.3.1) et, pour les cibles en répétitions, le rendement du test. Les
paramètres sont des mesures directes du banc, pas un ajustement par vraisemblance (il ne se généralise pas d'une
graine à l'autre).

**Mesure.** Graines 2 à 5, jamais vues au réglage : écart de 1 à 6 points sur les déciles peuplés, 10 points sur un
seul. Campagne (graines 0 et 1) : 22,1 points au pire décile (20-30 % prévus, 2,4 % observés, n = 169), 6,7 points
entre 10 et 20 %, 7 à 8 points entre 30 et 50 % ; erreur pondérée sur tous les cas : 4,5 points.

**Pourquoi.** Les cas ne sont pas indépendants : la même vérité d'un exercice est tirée par (exercice, graine) et se
répète dans tous les profils, scénarios et dates. Le décile fautif tient pour 40 % à un seul exercice d'une seule
graine (muscle-up lesté, graine 0, jamais réussi). Avec deux graines, la mesure par décile ne départage pas un
modèle bien calibré d'un modèle mal calibré à mieux que 10 à 20 points. Le relecteur indépendant note aussi que les
trois dates d'une même cible sont corrélées et gonflent les effectifs : la mesure avec une seule prévision par cible
(4 semaines avant) est publiée à côté (13,9 points au pire).

## 4. Critère 2 — mauvais jour isolé

- Mesure en **contrefactuel apparié** (C13.10.2.b) : le journal de la saison est rejoué deux fois, tel quel, puis avec
  la séance du mauvais jour à la place de celle du même jour, les séances suivantes restant celles de la saison telle
  quelle. Mesuré ainsi, le moteur était encore à 1,15 % avant la correction ci-dessous.
- Correction : dans la branche « mauvais jour », la séance s'explique par l'effet de jour et les capacités ne sont
  plus déplacées. Résultat : 0,95 % au pire horizon.
- Filet : deux séances de suite tenues pour de mauvais jours ne sont plus un mauvais jour isolé ; la cause
  « rupture » se lève et mène au diagnostic (0,41 alerte pour 100 séances en saison de référence ; maladie détectée
  dans 67 saisons sur 162, contre 20 % par la détection seule).

## 5. Ce que les mesures ont fait trouver d'autre

- **Bogue de Koach 1.0 corrigé** : après la réponse « rien de spécial », l'incertitude des capacités devait doubler ;
  elle était multipliée par 7 et plus (seules les diagonales de la covariance étaient élargies), et l'ouverture des
  tentatives tombait très bas après plusieurs alertes. Corrigé ; la performance le jour J passe de 0,933 à 0,941.
- **Relecture indépendante du code** (Opus) : 1 bloquant et 3 majeurs, tous traités. Le bloquant : un vrai test
  pouvait être servi juste après un échec non prévu (régression de cette passe, corrigée avant la campagne finale).
  Majeurs : première barre de la montée trop permissive (ramenée à la hausse du niveau) ; rôle d'une série lu à un
  seul endroit ; mesure du critère 5 flatteuse (compléments publiés). Mineurs traités ou déclarés à l'annexe A du
  contrat.
- Une première campagne de cette passe montrait un recul du jour J (0,915) : c'est elle qui a fait trouver le bogue
  ci-dessus. Elle n'est pas publiée ; la campagne livrée est la seconde.

## 6. Limites

- **Rejeu du journal réel non refait.** Le rejeu demande l'export du journal (déchiffré sous `/tmp`, clé par fichier
  en mode 600, supprimés ensuite) et trois fichiers d'accompagnement construits pendant KM1 sous `/tmp` (programme,
  programme annoté, correspondance des noms), qui n'ont pas été sauvegardés. Les reconstruire a été refusé par le
  contrôle d'autorisations de la session (données personnelles). `donnees/rejeu_journal_agregats.json` reste celui
  de Koach 1.0. À refaire avant la bascule (C13.10.2.d : 100 séries notées, biais sous 2 %), avec ces trois fichiers
  déposés chiffrés sur `cp-references`.
- **Banc adversarial** : comparaison refaite sur les adversaires trouvés contre Koach 1.0 ; pas de nouvelle recherche
  contre 1.0.1 (elle demande le témoin Dart par le contrôle).
- Le jumeau ajoute le gain d'affûtage sans condition de semaine ; la séance ne l'ajoute qu'à l'ouverture, en semaine
  d'affûtage ou de compétition.
- Une montée de test qui n'arrive jamais près de l'échec peut revenir tous les 5 jours ; sa durée peut être
  sous-estimée si des séries sont dites très faciles.
- Les limites de KM1 restent (annexe A du contrat) : crochets d'extension appliqués par l'appelant, référence de
  planification hors journal, contrôle dual non validé sur 16 semaines, structure du programme jamais modifiée.

## 7. Ce qui est livré

| Objet | Où | État |
| --- | --- | --- |
| Référence Python de Koach **1.0.1** | `moteurs` 17df8ca, `packages/kalis_adapt/reference/` (liste des changements : `CHANGEMENTS_1_0_1.md`) | 224 tests verts |
| Fichier de paramètres `1.0.1-ref.1` | `params/koach_params_v1.json` | 317 clés, une ligne par clé dans `SOURCES.md` |
| 13 fixtures de parité | `fixtures/` | régénérées, vérifiées |
| Contrat | `CONTRAT_1_0.md` | note datée du 10/10/2026 (10 points), annexe A à jour |
| `kalis_bench` | inchangé (0.3.1) | pas de contrôle à relancer |

Pour KM2 : lire la note datée en tête du contrat avant de porter ; la courbe, l'inverse et les séries près de 0 sont
écrites sans fonction absente de `dart:math` ; trois horloges de piste nouvelles ; tirages du jumeau ajoutés à la fin.

## 8. Recommandation (C8, le pilotage décide)

1. Lancer KM2 sur cette référence (C13.10.4).
2. Critère 1 : trancher entre un écart documenté (plancher du banc avec des tests à réserve gardée) et un choix de
   sécurité à faire prendre au propriétaire (test du débutant plus bas, ou série jusqu'à l'échec chez l'avancé).
3. Critère 5 : avant toute correction 2, mesurer sur plus de graines (au moins 6) ; avec deux graines la mesure ne
   peut pas conclure.
4. Déposer chiffrés sur `cp-references` les trois fichiers d'accompagnement du rejeu réel.

## 9. Budget et sauvegardes

Sous-agents sur Opus seulement (une relecture du code, trois mises à jour des documents). Sauvegardes sur
`cp-sauvegardes/KM1` à chaque étape. Aucune tâche planifiée créée, modifiée ou lancée.
