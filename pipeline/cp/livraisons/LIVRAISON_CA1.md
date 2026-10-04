# Livraison CA1 — `kalis_adapt` 0.2.0 : faire évoluer un athlète street comme un coach

Lot moteur du pipeline « Calibrage des programmes » (voie B, Fable 5.1, effort maximal), exécuté le 04/10/2026 de 08:51 UTC à la fin de journée.

**État : livré — cible non atteinte.** Le moteur est publié, ses contrôles sont verts et aucun manquement de sécurité n'est réalisé sur les 17 profils street. Mais la cible C7.5 — une note de 9 au moins pour chacune des quatre écoles du panel et chacun des 17 profils, sur les trajectoires simulées — n'est pas atteinte : 34 couples sur 68 sont à 9, le minimum est 7. Les 34 corrections que le panel demande encore portent toutes sur le programme écrit par `kalis_plan`, que ce lot n'a pas le droit de modifier. Une décision est demandée (partie 8).

## 1. Ce qui est livré

| Élément | Valeur |
| --- | --- |
| Paquets | `kalis_adapt` 0.2.0, `kalis_bench` 0.1.2 (`kalis_core` 0.4.1 et `kalis_plan` 0.2.0 inchangés) |
| Branche | `moteurs`, commit ccde1ad2 |
| Étiquettes | `etiquettes/kalis_adapt-v0.2.0`, `etiquettes/kalis_bench-v0.1.2` |
| Contrôle | `claude/ci-cp-b`, run 37215089957 (mode complet), commit e5b73d94 (`packages/` identique à `moteurs` ccde1ad2) : vert |
| Sauvegardes | `cp-sauvegardes/CA1` |

`kalis_adapt` 0.2.0 ajoute un **mode coach** pour les blocs qui portent le contrat 0.4.0 de `kalis_core` (les programmes street de `kalis_plan` 0.2.0). Un bloc sans ces champs — programmes de `kalis_plan` 0.1, programme importé de 40 semaines du propriétaire — est servi comme en 0.1.0 : la campagne de 0.1 (8 athlètes × 200 graines) redonne les mêmes tableaux, au texte de version et aux temps près.

Ce que le moteur sait faire maintenant, séance après séance :

- **respecter la phase** : allègement, affûtage, test et compétition servis tels quels, jamais de série ajoutée ; hausses seulement en semaine de charge ; décisions prudentes à 14 jours d'une échéance ;
- **piloter une charge écrite en part du 1RM** par la réserve, dans un couloir autour de la part écrite, avec une hausse bornée d'une séance à la suivante à schéma égal ;
- **exécuter les techniques** (série de tête et séries allégées calculées sur la série de tête réalisée, départs au chrono, grappes, repos-pause, dégressives, vagues, pyramides, descentes accentuées…) et ne les servir qu'au niveau qui y donne accès ;
- **lire ce que l'athlète montre** : une note d'effort loin de l'échec n'est qu'une borne ; une série repère (au ressenti) est proposée quand rien n'a mesuré le mouvement depuis deux semaines ;
- **recaler les répétitions et les maintiens** écrits en part d'un test sur le maximum mesuré, dans les deux sens ; garder la réserve du bloc en haut d'une plage ; servir des séries plus courtes et plus nombreuses quand la plage est hors de portée ;
- **conduire les tests et le jour d'échéance** : ouverture sur une barre déjà faite, deuxième et troisième barres selon l'estimation et son incertitude, rythme d'une épreuve de répétitions ; résultats de test rendus au profil (un test fait un jour de bilan nettement bas ne fait pas baisser le repère) ;
- **suivre les figures** : étape en cours, critère de passage, étape plus facile un mauvais jour, hausse des tenues bornée pour les tendons ;
- **protéger** : aucune hausse après un échec, zone douloureuse gelée (volume et charge), exercice allégé à 5 sur 10, bilan du jour bas (trois répétitions en réserve au moins), reprise graduelle après une coupure, exercice jamais fait introduit à 60 % de la charge de référence, alerte de surmenage (deux séances mesurées de suite à −5 % : une semaine à 40 % de lignes en moins).

Simulateur : deux modèles de vérité de plus (B et C), écrits pour s'éloigner des hypothèses du moteur. `kalis_bench` 0.1.2 : trajectoires sous les trois modèles, campagne street, export lisible des trajectoires (ce que le programme écrit, ce que le moteur sert, ce que l'athlète fait, les décisions en clair). Profils types, attentes, critères de sécurité et grilles du panel **inchangés**.

Documentation : `packages/kalis_adapt/CONTRAT.md` § 11 (règles, invariants C1 à C4, tableau de tous les paramètres avec leur source, limites) ; `docs/VALIDATION.md` § 9 ; `docs/CAMPAGNE_STREET.md` ; `docs/CALIBRAGE_CA1.md` (passes du panel, recherches ciblées et sources, relecture documentée traitée point par point).

## 2. Mesures, avant et après, par modèle de vérité

Campagne street : 17 profils, jusqu'à l'échéance, 100 graines par modèle. « 0.1 » : `kalis_adapt` en comportement 0.1 sur les mêmes programmes. « Coach simple » : autorégulation à la note d'effort.

| Modèle | Moteur | Écart entre effort affiché et réel (rép.) | Séries ≥ 2 rép. plus dures que visé | Échecs non voulus | Progression par semaine | Tentatives réussies | Jour J ÷ maximum du jour |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A | 0.1 | 0,87 | 1,1 % | 0,22 % | 0,374 % | 100 % | 92,3 % |
| A | **0.2.0** | **0,81** | **0,3 %** | 0,20 % | 0,358 % | 79 % | **96,6 %** |
| A | coach simple | 2,61 | 1,7 % | 2,21 % | 0,315 % | 90 % | 91,7 % |
| B | 0.1 | 1,98 | 0,5 % | 0,04 % | 0,334 % | 100 % | 89,8 % |
| B | **0.2.0** | **0,97** | 0,4 % | 0,14 % | 0,341 % | 88 % | **95,5 %** |
| B | coach simple | 2,17 | 2,3 % | 1,88 % | 0,329 % | 92 % | 91,3 % |
| C | 0.1 | 1,34 | 2,1 % | 0,58 % | 0,174 % | 100 % | 89,2 % |
| C | **0.2.0** | 1,61 | **0,7 %** | 0,55 % | 0,170 % | 94 % | **94,7 %** |
| C | coach simple | 4,84 | 3,4 % | 4,24 % | 0,141 % | 86 % | 91,7 % |

Lecture honnête :

- **Mieux que 0.1** : exactitude sous A et B (deux fois plus juste sous B), moins de séries nettement plus dures que visé sous les trois modèles, et surtout le jour de l'échéance (95 à 97 % du maximum réel du jour contre 89 à 92 %).
- **Moins bien que 0.1** : exactitude sous C (1,61 contre 1,34 ; la cible d'une répétition n'y est pas tenue) ; tentatives réussies moins souvent (0.1 ouvre et finit bas : 100 % de réussite, mais 5 points de moins le jour J) ; progression un peu plus faible sous A et C (moins de 5 % d'écart) ; échecs non voulus plus nombreux sous B (0,14 % contre 0,04 %).
- **Mieux que le coach simple** sur toutes les mesures et les trois modèles.
- Sécurité du programme tel qu'il a évolué (trajectoire racontée, modèle B) : **0 manquement** aux critères calculables sur les 17 profils. Dans la campagne : deux hausses sur une zone douloureuse en 100 simulations de `street_10` sous B, non expliquées ; le repère « aucune hausse de plus de 10 % en plusieurs crans » n'est pas tenu au sens de la mesure (202, 187 et 139 hausses pour 1 700 simulations ; 0.1 : 311, 211, 316), parce qu'elle compte le retour à la charge du programme après une séance allégée.
- Temps de calcul (machine de contrôle) : décision de séance 0,04 ms en médiane, conseil après une série 0,04 ms en médiane, maximum 9,3 ms (cible de 5 ms tenue en médiane).

## 3. Panel et relecture documentée

Panel : quatre écoles, en aveugle, sur le programme et sa trajectoire simulée (modèle B). Passe 3, complète, sur la version livrée aux corrections de la boucle 4 près (0 à 8 % des lignes d'export, sous le seuil de 10 %, non renotées). Relecture documentée : quatre relecteurs Opus, sources du web seulement.

| Profil | Force | Calisthénie | Hypertrophie | Santé | Relecture documentée |
| --- | --- | --- | --- | --- | --- |
| `street_01_debutant_complet` | 8 | 8 | 8 | 9 | 6 |
| `street_02_debutant_surpoids` | 9 | 9 | 9 | 9 | 6 |
| `street_03_debutante` | 7 | 7 | 7 | 7 | 5 |
| `street_04_reprise_longue_pause` | 9 | 7 | 9 | 8 | 7 |
| `street_05_inter_calisthenie_front_lever` | 7 | 7 | 7 | 9 | 6 |
| `street_06_inter_sets_reps` | 8 | 9 | 7,5 | 9 | 6 |
| `street_07_avance_streetlifting_competition` | 9 | 9 | 9 | 9 | 7 |
| `street_08_avance_sets_reps_competition` | 9 | 9 | 9 | 8 | 6 |
| `street_09_elite_streetlifting` | 8 | 8 | 8 | 9 | 6 |
| `street_10_elite_figures` | 8 | 8 | 8 | 8 | 5 |
| `street_11_master_51_ans` | 9 | 9 | 9 | 9 | 6 |
| `street_12_antecedent_coude` | 8 | 9 | 9 | 9 | 6 |
| `street_13_peu_de_temps` | 9 | 8 | 8 | 9 | 6 |
| `street_14_parc_sans_lest` | 9 | 8 | 9 | 9 | 6 |
| `street_15_travail_physique_sommeil_court` | 9 | 8 | 8 | 8 | 7 |
| `street_16_specialisation_traction_lestee` | 8 | 8 | 9 | 9 | 7 |
| `street_17_hybride_street_course` | 9 | 7 | 7 | 8 | 6 |

- **Panel** : 34 couples sur 68 à 9 ou plus, minimum 7, moyenne 8,35. Passes complètes précédentes : 29 sur 68 et minimum 6 (avant calibrage et après la boucle 1). À 9 partout : `street_02`, `street_07`, `street_11`. L'incertitude du panel est d'un point : entre deux passes, sur un export presque identique, une même note a varié de 8 à 4 puis à 9.
- **Ce que le panel demande encore** (34 corrections nécessaires, lues en entier) : toutes sur le programme écrit — échelle de poussée du débutant et pompe dosée au-dessus du maximum, critère et seuil d'ouverture d'une étape de figure, bloc suivant écrit sur un repère supposé, séries allégées à −15 %, bloc de réalisation non spécifique, tractions deux jours de suite, hausses hebdomadaires trop fortes, charge « à calibrer ». Le moteur recale ces chiffres en séance ; il ne réécrit pas le programme.
- **Relecture documentée** : 5 à 7, moyenne 6,1 (sans seuil, C7.6). Plus sévère, et tournée vers la conduite : estimations trop prudentes (maxima sous-estimés, séries allégées servies trop faciles), échelle d'assistance jamais franchie, test d'un mauvais jour reporté au profil.

## 4. Remarques de la page de relecture, traitées

La page ne porte aucune note du propriétaire ; toutes viennent de la relecture documentée. Celles de la manche 1 (CP1) qui touchent le suivi sont traitées par le mode coach : cibles qui suivent le test réel (répétitions et maintiens recalés sur le maximum mesuré), charge par la réserve quand le 1RM déclaré ne tient pas (couloir), ouverture sur une barre déjà faite, critère de passage d'une figure lu dans le journal, bilan du jour et nuit courte, douleur, reprise graduelle après une coupure. Celles de cette manche (manche 2), une par une :

| Remarque | Suite |
| --- | --- |
| Maxima sous-estimés, charges et séries allégées trop faciles (8 profils) | expliqué, non corrigé : records déclarés au-dessus du maximum réel, notes bruitées du modèle B, le moteur ne lit que ce que l'athlète montre ; estimation 3 à 5 % sous le maximum réel en fin de cycle ; à reprendre en CA2 |
| Échelle d'assistance jamais franchie (pompes sur les genoux, élastique) | expliqué : l'échelle de poussée est un texte du programme, pas une échelle du contrat ; à écrire par `kalis_plan` |
| Test d'un jour de bilan bas reporté au profil | **corrigé** |
| Simples sur la pompe, 4-4-4 près de l'échec | expliqué : séries à la réserve du bloc, demandées par le panel ; le choix d'une variante plus facile revient au programme |
| Test de descente rendu en répétitions | non corrigé : test de maintien écrit sur un exercice compté en répétitions ; interface plan ↔ catalogue, pour CX |
| Douleur au poignet cinq semaines, dips gardés | expliqué : progression et volume gelés, exercices les plus sollicitants remplacés ; l'arrêt et l'avis médical sont une consigne du programme |
| Barre retentée après un échec, saut de 5 kg à 54 % | expliqué : règle de compétition ; probabilité d'une troisième barre « record », paramètre à revoir avec le propriétaire |
| Répétitions figées quand la réserve dépasse la cible | expliqué : profils à récupération limitée, aucune hausse au-delà du programme ; limite notée |
| Allures de course non pilotées | hors périmètre (CA2) |
| Traction lestée servie à 2,5 kg | expliqué : charge écrite « à calibrer » ; à chiffrer par `kalis_plan` |

## 5. Calibrage

Trois boucles, quatre passes de notation (0 à 3 ; la passe 2 partielle), chaque boucle avec une recherche ciblée (sources vérifiées et consignées dans `docs/CALIBRAGE_CA1.md` ; ce qui n'a été lu qu'en résumé est dit).

| Passe | Couples à 9 | Minimum | Moyenne | Ce que la boucle a changé |
| --- | --- | --- | --- | --- |
| 0 (complète) | 29 / 68 | 6 | 8,23 | — |
| 1 (complète) | 29 / 68 | 6 | 8,21 | lecture des notes en bornes, séries repère, recalage sur le maximum mesuré, assistance, entrée graduée, export « servi par le moteur » |
| 2 (39 couples) | 43 / 68 | 4 | 8,48 | haut de plage à la réserve du bloc, maintiens trop faciles |
| 3 (complète) | 34 / 68 | 7 | 8,35 | plage avec part de test, séries fractionnées, alerte de surmenage, maximum réel dans l'export |

J'ai arrêté après la boucle 3 sur mon jugement : la règle « deux boucles de suite sans gain » n'est pas remplie à la lettre, mais plus aucune correction du panel n'est à la portée de `kalis_adapt`. Une quatrième boucle a ensuite corrigé ce que la relecture documentée et la relecture indépendante du code ont trouvé ; elle n'a pas été renotée (moins de 10 % des lignes).

Écart signalé : la règle des séries fractionnées, écrite à la boucle 1, était coupée par l'assemblage de la séance et n'a servi qu'à partir de la boucle 3.

## 6. Contrôles

| Contrôle | Résultat |
| --- | --- |
| Formatage, analyse, tests des cinq paquets (mode complet) | vert (run 37215089957) |
| Invariants I1 à I8 sur 10 240 journaux aléatoires de 0.1 | tenus |
| Invariants du mode coach (C1 à C4, I2 à I8) sur 10 240 journaux aux champs de 0.4.0, 17 programmes street × 3 modèles, techniques injectées | tenus |
| Règles du calibrage (`coach_rules_test.dart`) | tenues |
| Campagne de 0.1 (8 athlètes × 200 graines) sous le moteur 0.2.0 | tableaux identiques, aux temps près |
| Relecture indépendante du code et du contrat (Opus, lecture seule) | 20 constats : 8 corrigés, 5 portés au contrat, 7 non corrigés et écrits comme limites (`docs/VALIDATION.md` § 9.5) |
| Références privées | non utilisées par ce lot (aucun programme généré) : pas de calcul de non-ressemblance, clé jamais lue |
| Programme importé du propriétaire | rejoué, inchangé (`docs/PROPRIETAIRE.md`) |

## 7. Limites

- Le moteur ne réécrit pas le programme (volume, fréquence, répartition, exercices, seuils des figures).
- Tout est mesuré sur des athlètes simulés ; les modèles B et C ont été écrits par ce lot.
- Estimation prudente : 3 à 5 % sous le maximum réel en fin de cycle sous le modèle B ; exactitude sous la cible sous le modèle C.
- Alerte de surmenage et séries fractionnées : règles raisonnées, sans validation publiée ; l'alerte ne s'est déclenchée sur aucun mouvement principal des trajectoires racontées.
- Sept constats de la relecture indépendante non corrigés, dont : le conseil d'entre-séries ne reprend pas tous les ajustements d'un jour de bilan bas ; un manque sur une série de tête plus courte que ses séries allégées ne bloque pas la hausse ; les tests de l'alerte de surmenage ne portent que sur sa fonction de détection.
- Deux hausses sur une zone douloureuse en 100 simulations d'un profil, non expliquées.
- Le contenu sportif n'a pas été relu par un professionnel diplômé.

## 8. Décision demandée et suite proposée

La cible « 9 partout » n'est pas atteinte, et ce qui manque est du ressort de `kalis_plan`. Je recommande :

1. d'accepter `kalis_adapt` 0.2.0 comme base du suivi street pour CX (statut inchangé : « livré — cible non atteinte ») ;
2. de faire porter par CX, ou par une passe de correction de CP1, les corrections du programme écrit, par ordre d'effet attendu : réécrire le bloc suivant d'après le résultat réel du test ; échelle de poussée du débutant écrite comme une échelle du contrat et pompe dosée sur le maximum mesuré ; seuil d'ouverture d'une étape de figure à 70–75 % du maximum, tirage de force pour les figures ; séries allégées à −5 / −8 % et trois séries et plus à 85 % en intensification ; bloc de réalisation spécifique au maximum de répétitions ; pas de tractions deux jours de suite, hausses hebdomadaires de 10 à 15 %, charge « à calibrer » chiffrée quand le 1RM est connu ; test de descente sur un exercice compté en secondes ;
3. pour `kalis_adapt` 0.3 (CA2) : estimation moins prudente (série repère après un échec, repère sur les meilleurs simples récents), passage d'un cran d'une échelle d'assistance, allures de course, constats restants de la relecture indépendante, hausses sur zone douloureuse à expliquer.

Pages : relecture (manche 2, 17 programmes street avec le bilan de leur trajectoire, notes et commentaires de la relecture documentée) https://claude.ai/artifact/48CYFBy75Xykohm674vLNq ; suivi https://claude.ai/artifact/7tr7vJvnnn85KzVx5qYRw5.
