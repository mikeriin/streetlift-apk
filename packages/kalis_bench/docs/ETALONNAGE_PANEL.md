# Étalonnage du panel de coachs virtuels (lot CR, 03/10/2026)

But : vérifier, avant tout usage, que le panel (`PANEL.md`) classe correctement des programmes de qualité connue, qu'il est répétable, et que le seuil du pipeline (9/10) est atteignable par un programme réellement signable — et seulement par lui.

## Protocole

- **Six profils** du banc : quatre avec les quatre variantes (avancé sets & reps en préparation de compétition, intermédiaire sets & reps, parc sans lest, hybride street et course) et deux avec les variantes extrêmes seulement (débutant complet, élite streetlifting), pour couvrir les deux bouts du spectre.
- **Quatre variantes** par profil :
  - (a) programme volontairement mauvais ; erreurs injectées : toutes les séries à l'échec, y compris sur les mouvements à risque ; tests maximaux répétés ; hausses de volume de 50 à 60 % en une semaine ; aucune décharge ni affûtage, test ou simulation la veille de l'échéance ; séances hors du temps donné ; techniques et figures sans prérequis ; mouvements de l'objectif absents ; douleur ignorée ; matériel que le profil n'a pas ;
  - (b) programme générique correct (répartition classique, 2 répétitions en réserve partout, progression simple, allègement périodique), sûr mais non individualisé ;
  - (c) programme expert écrit par le lot d'après le référentiel (pas une copie d'une référence) ;
  - (d) programme de référence privé le plus proche du profil, adapté au profil — ancre haute, usage interne : son texte n'est pas dans le dépôt (archive chiffrée de la branche `cp-references`).
  Les variantes (a), (b), (c) sont dans `docs/etalonnage/` (version finale de (c)).
- **Aveugle** : chaque appel reçoit un dossier isolé (règles communes, grille de son école, référentiel, programmes renommés `programme_1.md`…), jamais deux variantes d'un même profil (carré latin : chaque lot contient quatre profils, chacun dans une variante différente), jamais deux écoles.
- **Répétabilité** : deux lots sur quatre sont notés deux fois par deux appels indépendants de chaque école.
- Relecteurs : sous-agents Opus (PIPELINE_CP.md §9).

## Résultats (note d'ensemble ; deux valeurs = deux appels indépendants)

### Manche 1 (grilles initiales)

| Profil — variante | Force | Calisthénie | Hypertrophie | Santé |
|---|---|---|---|---|
| Débutant complet — (a) mauvais | 1 | 0,5 | 1 | 1 |
| Débutant complet — (c) expert | 8 | 8 | 7,5 | 8 |
| Intermédiaire sets & reps — (a) mauvais | 1 | 1 | 1 | 1 |
| Intermédiaire sets & reps — (b) générique correct | 5,5 / 5 | 5,5 / 6 | 6 / 6 | 5 / 5,5 |
| Intermédiaire sets & reps — (c) expert | 8,5 | 8 | 8 | 8,5 |
| Intermédiaire sets & reps — (c) expert, révisé | 7,5 | 6,5 | 7,5 | 7,5 |
| Intermédiaire sets & reps — (d) référence adaptée | 7,5 / 7 | 6,5 / 7 | 8 / 8 | 7 / 7 |
| Intermédiaire sets & reps — (d) révisée | 7,5 | 8 | 7 | 7,5 |
| Avancé sets & reps, compétition dans 8 semaines — (a) mauvais | 1 / 1 | 1 / 1 | 1 / 1 | 1 / 1 |
| Avancé sets & reps, compétition dans 8 semaines — (b) générique correct | 4 | 4 | 5 | 4 |
| Avancé sets & reps, compétition dans 8 semaines — (c) expert | 9 / 8,5 | 8 / 8,5 | 8,5 / 8,5 | 8,5 / 8,5 |
| Avancé sets & reps, compétition dans 8 semaines — (c) expert, révisé | 8,5 | 8 | 8 | 8 |
| Avancé sets & reps, compétition dans 8 semaines — (d) référence adaptée | 8 | 8 | 8 | 8 |
| Avancé sets & reps, compétition dans 8 semaines — (d) révisée | 8 | 8 | 8 | 7,5 |
| Élite streetlifting — (a) mauvais | 0,5 | 0,5 | 0,5 | 0,5 |
| Élite streetlifting — (c) expert | 8 | 8 | 8 | 9 |
| Parc sans lest — (a) mauvais | 1 / 1 | 0,5 / 0,5 | 1 / 1 | 0,5 / 0,5 |
| Parc sans lest — (b) générique correct | 5,5 | 6 | 6 | 6 |
| Parc sans lest — (c) expert | 8,5 / 8 | 8,5 / 8,5 | 8 / 8,5 | 8,5 / 8,5 |
| Parc sans lest — (c) expert, révisé | 8,5 | 8 | 8 | 8 |
| Parc sans lest — (d) référence adaptée | 8 | 8 | 8 | 7,5 |
| Parc sans lest — (d) révisée | 8 | 7,5 | 8 | 8 |
| Hybride street et course — (a) mauvais | 0,5 | 0,5 | 0,5 | 0 |
| Hybride street et course — (b) générique correct | 5 / 5 | 4,5 / 5 | 5 / 5 | 4 / 5 |
| Hybride street et course — (c) expert | 8,5 | 8,5 | 8,5 | 8,5 |
| Hybride street et course — (c) expert, révisé | 8 | 8 | 8 | 8 |
| Hybride street et course — (d) référence adaptée | 8 / 7,5 | 8 / 8 | 8 / 8 | 7,5 / 7,5 |
| Hybride street et course — (d) révisée | 7 | 7,5 | 7,5 | 7,5 |


Lecture de la manche 1. Classement correct partout ((a) ≤ 1, (b) 4 à 6, (c) et (d) 6,5 à 9) et répétabilité très bonne, mais **aucune ancre haute n'atteint 9** : chaque relecteur trouve toujours « une ou deux corrections nécessaires ». Les lignes « révisé » et « révisée » sont les mêmes programmes corrigés d'après les remarques du panel, renotés avec les règles initiales : la note ne monte pas (7 à 8,5), parce que la frontière entre « correction nécessaire » et « amélioration » n'était pas définie, et parce que les corrections ajoutées par retouches avaient créé des contradictions internes que le panel a relevées à juste titre.

Deux corrections ont donc été faites, comme le prévoit le lot (« sinon, corrige les grilles et les consignes, puis recommence ») :

1. **Règles communes** (`grilles/COMMUN.md`) : chaque remarque est classée **nécessaire** (risque nommé, objectif probablement manqué, séance infaisable ou consigne contradictoire — avec la conséquence écrite) ou **amélioration** ; la note d'ensemble découle du nombre de corrections nécessaires (9 = aucune ; 8 = une, simple ; 7 = deux ou trois). Les critères et leurs ancrages n'ont pas changé.
2. **Ancres hautes** : les quatre programmes (d) ont été réécrits d'un seul tenant (cohérence interne, fréquences et volumes recomptés, une seule échelle de douleur) ; les programmes (c) ont été nettoyés de leurs contradictions.

### Manche 2 (règles communes précisées ; grilles gelées)

| Profil — variante | Force | Calisthénie | Hypertrophie | Santé |
|---|---|---|---|---|
| Débutant complet — (a) mauvais | 1 | 0,5 | 1 | 1 |
| Débutant complet — (c) expert | 9 | 8 | 9 | 9 |
| Intermédiaire sets & reps — (a) mauvais | 1 | 1 | 1 | 1 |
| Intermédiaire sets & reps — (b) générique correct | 7 / 6 | 6 / 6,5 | 6 / 6,5 | 7 / 6 |
| Intermédiaire sets & reps — (c) expert, révisé | 9 | 9 | 8 | 8 |
| Intermédiaire sets & reps — (d) réécrite | 9 / 9 | 9 / 9 | 9 / 9 | 9 / 9 |
| Avancé sets & reps, compétition dans 8 semaines — (a) mauvais | 1 / 1 | 1 / 1 | 1 / 1 | 1 / 1 |
| Avancé sets & reps, compétition dans 8 semaines — (b) générique correct | 5 | 5 | 5 | 4 |
| Avancé sets & reps, compétition dans 8 semaines — (c) expert, révisé | 9 / 9 | 8 / 9 | 9 / 9 | 8 / 9 |
| Avancé sets & reps, compétition dans 8 semaines — (d) réécrite | 9 | 9 | 9 | 9 |
| Élite streetlifting — (a) mauvais | 0 | 1 | 0 | 0,5 |
| Élite streetlifting — (c) expert | 9 | 8 | 9 | 9 |
| Parc sans lest — (a) mauvais | 1 / 0,5 | 1 / 1 | 1 / 1 | 1 / 1 |
| Parc sans lest — (b) générique correct | 7 | 5,5 | 6 | 5,5 |
| Parc sans lest — (c) expert, révisé | 9 / 8 | 9 / 9 | 9 / 9 | 8,5 / 8 |
| Parc sans lest — (d) réécrite | 9 | 9 | 9 | 9 |
| Hybride street et course — (a) mauvais | 0,5 | 1 | 0,5 | 0,5 |
| Hybride street et course — (b) générique correct | 5,5 / 5,5 | 5 / 5 | 5 / 5 | 5 / 5 |
| Hybride street et course — (c) expert, révisé | 9 | 9 | 9 | 9 |
| Hybride street et course — (d) réécrite | 8 | 8 | 9 | 9 |
| Hybride street et course — (d) réécrite, durée corrigée | 9 | 9 | 9 | 9 |

Répétabilité, manche 1 : 32 couples (programme, école) notés deux fois par deux appels indépendants ; écart moyen 0.20 point, écart maximal 1 point, 20 notes identiques.
Répétabilité, manche 2 : 28 couples (programme, école) notés deux fois par deux appels indépendants ; écart moyen 0.25 point, écart maximal 1 point, 19 notes identiques.

## Conclusions

| Exigence du lot | Résultat (manche 2, grilles gelées) |
|---|---|
| Classement correct (a) < (b) < (c), (d) | oui, pour les 6 profils et les 4 écoles |
| (a) < 6 | oui : 0 à 1 partout |
| (d) ≥ 9 | oui : 9 pour les quatre profils et les quatre écoles (profil hybride : après correction d'une séance qui dépassait le créneau de 45 minutes — une correction nécessaire relevée indépendamment par deux écoles, donc fondée) |
| Répétabilité ≤ 1 point | oui : écart maximal 1 point, écart moyen 0,25 |

Ce que l'étalonnage apprend, au-delà des exigences :

- **Le panel lit vraiment les programmes.** Les corrections nécessaires relevées sont factuelles et convergentes entre écoles (séance hors créneau, tirage dur deux jours de suite, plafond écrit non tenu par les séances, règle de douleur contradictoire, test final sans affûtage).
- **9 est atteignable, 10 n'a jamais été donné.** Un programme générique correct plafonne vers 5 à 7 : atteindre 9 demande une individualisation réelle et une cohérence interne complète.
- **Incertitude à la frontière.** Trois programmes (c) ont reçu 8 d'un appel et 9 d'un autre de la même école : autour du seuil, la note d'un seul appel a une incertitude d'un point. Conséquence pratique pour les lots de calibrage, écrite dans `PANEL.md` : une note de 8 ou 8,5 se traite par sa correction nécessaire (elle est écrite, avec sa conséquence) ; si la correction est faite, ou si elle est factuellement fausse, le couple (école, profil) est renoté par un nouvel appel.
- **Les programmes de référence, tels quels, n'auraient pas 9.** L'ancre (d) n'atteint 9 qu'adaptée : individualisée aux records du profil, avec marges, échauffement, règles de douleur, allègements et tests — ce que les références n'écrivent pas (`MESURES_REFERENCES.md`, (e) et (f)). Le niveau « coach d'élite » visé par le calibrage est donc au-dessus de ces programmes sur la sécurité et l'individualisation, et à leur niveau sur la spécificité.
- **Limite.** Les six profils d'étalonnage sont tous street ; les grilles ont été écrites pour toutes les disciplines, mais leur comportement sur les profils des autres disciplines n'est vérifié que par la mesure de départ (`BASELINE_0_1.md`). CP2 et CA2 referont un étalonnage court (variantes (a) et (c)) sur deux profils non street avant leur première boucle, sans toucher aux grilles.

Coût : 84 appels (52 en manche 1, 32 en manche 2), tous sur Opus.

## Gel

Les grilles et les règles communes sont gelées à l'issue de la manche 2. Empreintes SHA-256 dans `PANEL.md`.
