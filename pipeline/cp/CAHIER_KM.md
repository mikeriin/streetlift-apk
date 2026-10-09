# Cahier des charges — Méthode Koach (lots KM1 à KM3)

09/10/2026 · propriétaire : Gaël · validé par le propriétaire le 09/10/2026 (« Magnifique on part sur ça », DECISIONS_CP.md C13).
Document de travail du propriétaire (édition et commentaires) : https://claude.ai/code/artifact/c57c95c7-e308-4cfc-8133-1fe320e07d04 — ce fichier en est la copie de référence pour les sessions ; en cas d'écart, `DECISIONS_CP.md` C13 tranche.

## Contexte et décisions

Koach devient le seul moteur qui crée et fait évoluer tout programme de Kalis Track. Bascule visée le 23/11/2026 sur le programme de Gaël, au début du bloc force max.

| N° | Décision du 09/10/2026 |
| --- | --- |
| D1 | Un seul moteur, un seul comportement : `kalis_adapt` 1.0.0 devient Koach complet. Aucun moteur en parallèle, aucun mode fantôme. |
| D2 | Tout programme, généré ou importé, est un plan initial. Le moteur le replanifie intégralement dès son activation, programme 40 semaines compris. |
| D3 | Objectif optimisé : P(toutes les cibles atteintes à la deadline), sous contrainte de risque. Sans échéance : progression attendue × P(continuer). |
| D4 | Méthodes : IRT multidimensionnelle, banc adversarial, optimisation bornée, contrôle dual avec essais N-of-1 et contrôle synthétique. |
| D5 | Aucune connexion internet : tout tourne sur l'appareil, les échanges passent par des fichiers. |
| D6 | Pas de mode fantôme : le rejeu walk-forward du journal, les suggestions validées et l'arrêt d'urgence le remplacent. |
| D7 | Un refus de suggestion nourrit le modèle d'adhérence, jamais l'estimation de capacité sans raison explicite. |
| D8 | Validation par critères chiffrés automatiques, sans manche de panel. |
| D9 | Périmètre : tous les programmes du générateur, les 8 disciplines, tous les utilisateurs. |

## Architecture

`kalis_adapt` 1.0.0 est Koach complet : il lit le journal, replanifie depuis le plan initial et reste borné par `kalis_plan` et les règles de sécurité.

Flux : Journal (séries, RIR, refus, douleur) → **Estimation** (IRT multidimensionnelle, mesure du RIR, fatigue, détection de rupture) → **Planification** (objectif P(réussite), jumeau numérique, replanification hebdomadaire, depuis le plan initial généré ou importé) → **Garde-fous** (règles de sécurité 0.3.1, plafonds ±15 % / ±5 % par rapport à `kalis_plan`, structure modifiée en fin de bloc seulement) → Suggestions validées d'un tap → chaque décision retourne au journal.

- `kalis_adapt` 1.0.0 : estimation, planification, exécution des prescriptions, garde-fous.
- `kalis_plan` : structure initiale de tout programme, puis politique de référence.
- `kalis_core` : contrat de données commun, étendu seulement si le contrat 1.0 l'exige (règle `kalis_core` de PIPELINE_CP.md §0).
- `kalis_bench` : banc et rejeu, jamais dans l'application.

## Méthodes retenues

Neuf méthodes forment le moteur. Chaque valeur ci-dessous est un paramètre initial, réestimé pour chaque utilisateur et stocké dans le fichier de paramètres.

### 1. Objectif

- Avec échéance : maximiser P(toutes les cibles atteintes à la date), sous contrainte de risque de blessure.
- Sans échéance : maximiser la progression attendue × P(continuer sur 12 semaines).
- Effet attendu : l'effort va au lift le plus en retard sur sa cible.

### 2. Modèle de l'athlète : IRT multidimensionnelle

- 10 qualités latentes par utilisateur, liste figée dans le contrat de KM1.
- Chaque exercice de la base v1.1 (1 039) est un item, avec un vecteur de charges sur ces qualités. Vecteurs calculés par règles depuis les champs de la base, puis relus.
- e1RM calculé sur la masse totale (poids de corps daté + lest).

| Type d'exercice | Difficulté de l'item | Réponse observée | Modèle de réponse |
| --- | --- | --- | --- |
| Force chargée | charge totale × reps | reps + RIR | gradué (Samejima) |
| Maintien, figures | étape × durée | secondes tenues, réussite | survie (temps jusqu'à l'échec) |
| Cardio | allure × durée | réussite, effort perçu | gradué |
| WOD, densité | format × charge | temps ou tours | continu (log-normal) |
| Mobilité | amplitude visée | réussite | binaire (2PL) |

### 3. Mesure du RIR

- RIR ressenti = RIR vrai + biais personnel + bruit. Biais et bruit appris par utilisateur.
- Bruit initial selon le niveau déclaré : débutant 2,0 reps, intermédiaire 1,5, avancé 1,0. Biais initial 0.
- Toutes les séries servent, pondérées par leur fiabilité : plus de filtre sur le RIR.
- Série ratée = observation à RIR 0. Modification manuelle d'une charge = mesure fiable.

### 4. Fatigue et a priori

- Trois compartiments, constantes initiales : nerveux 2,5 j, musculaire 7 j, tendineux 28 j. Le compartiment tendineux est alimenté par les exercices à forte charge tendineuse (champ de la base).
- Hiérarchie : population (littérature, calibrée sur le banc) → utilisateur → qualités → exercices.

### 5. Planification

- Replanification glissante chaque lundi, de la semaine suivante jusqu'à la deadline.
- Jumeau numérique : 1 000 trajectoires tirées de l'a posteriori, nombres aléatoires communs entre plans candidats.
- Recherche de plan par entropie croisée, 256 plans évalués au plus par replanification.
- Charges et volume ajustables à chaque séance. Structure modifiable seulement aux frontières de bloc.
- Test adaptatif : charge choisie pour maximiser l'information sur le niveau, dans la zone prescrite. Vrai test programmé seulement si l'intervalle à 90 % de l'e1RM dépasse 6 % de sa valeur.

### 6. Optimisation bornée

- Politique de référence : la sortie de `kalis_plan` pour toutes les disciplines, plus les programmes de coachs de référence (branche `cp-references`, chiffrés, règles de PIPELINE_CP.md §2) pour le street.
- Pénalité : λ × distance de transport optimal entre les distributions de stimulus du plan et de la référence. λ calibré sur le banc.
- Plafonds durs par bloc, par rapport à la référence : volume par qualité ±15 %, intensité moyenne ±5 %.

### 7. Apprentissage actif

- Contrôle dual par Thompson sampling sur les paramètres de réponse.
- Déclenché seulement si le modèle est calibré : 8 semaines de journal au moins et intervalle à 90 % de l'e1RM sous 6 % sur les lifts principaux.
- Essais N-of-1 par bras de 3 semaines. Contrôle synthétique construit sur au moins 6 semaines avant l'intervention.
- Toujours à l'intérieur des plafonds de l'optimisation bornée.

### 8. Adhérence et refus

- Un refus nourrit seulement le modèle d'adhérence. Raison facultative en un tap : trop lourd, trop léger, matériel, temps, autre.
- « Trop lourd » ou « trop léger » = mesure de capacité faible, à bruit élevé. Matériel et temps = contraintes de planification.
- P(acceptation) appris selon le type de changement, son ampleur et le contexte.
- Garde-fou anti-complaisance : l'adhérence agit sur la forme des propositions (taille des paliers, moment), jamais sur les cibles ni la difficulté globale.

### 9. Hors modèle

- Détection bayésienne de rupture en ligne (BOCPD). Alerte si P(rupture) dépasse 0,6, seuil calibré sur le banc.
- Seuils de secours : résidu d'e1RM supérieur à 5 % deux semaines de suite, assiduité sous 70 % sur 2 semaines, douleur supérieure à 2/10.
- Diagnostic en 3 questions au plus, chaque réponse menant à une action codée :

| Réponse | Action |
| --- | --- |
| Douleur | conduite sous douleur existante, renvoi vers un professionnel |
| Moins de temps | replanification avec les nouvelles disponibilités |
| Fatigue, vie chargée | semaine allégée |
| Rien de spécial | incertitude élargie, réapprentissage rapide |

- Dossier hors modèle exportable depuis le mode dev, analysé avec Claude, qui renvoie un fichier de paramètres importable.

## Comportement dans l'application

Un seul comportement, identique pour tous les utilisateurs : Koach propose, l'utilisateur valide d'un tap.

- **À la séance** : charge et volume suggérés avec leur raison en une ligne, validés d'un tap. Refus possible, avec une raison facultative.
- **Chaque lundi** : replanification des semaines restantes. Seuls les changements de la semaine à venir apparaissent dans les séances.
- **En fin de bloc** : récapitulatif « ce qui change et pourquoi » pour le bloc suivant, validé d'un tap.
- **Hors modèle** : message « situation hors de mon modèle », puis le diagnostic en 3 questions au plus.
- **Arrêt d'urgence** : fige le plan à la semaine en cours, sans perte de données. La réactivation reprend depuis le journal.
- **Mode dev** (builds de dev uniquement) : inspecteur du moteur, export du journal moteur et du dossier hors modèle, import du fichier de paramètres, rejeu walk-forward.
- **Textes de Koach** : un texte lisible par code de raison, jamais un code brut.

## Retiré, gelé ou reporté

Tout ce qui faisait coexister plusieurs modes disparaît à KM3. `kalis_plan` continue, puisqu'il devient la politique de référence.

| Élément | Sort | Quand |
| --- | --- | --- |
| Corrections de méthode restantes du pipeline CP (estimation des capacités, allure, figures, spécialisation) | reprises par KM ; lots moteurs CP déjà terminés (C11.7) | — |
| Mode fantôme | jamais construit | — |
| Couche d'ajustement CI1c du programme importé | retirée | KM3 |
| Statut spécial du programme importé | retiré | KM3 |
| Option d'adaptation de la structure | retirée : structure toujours adaptable, aux frontières de bloc | KM3 |
| Code de décision de `kalis_adapt` 0.x | remplacé par `kalis_adapt` 1.0.0 | KM3 |
| Série AMRAP toutes les 4 semaines | remplacée par le test adaptatif | KM1 |
| Filtre des séries selon le RIR | remplacé par le modèle de mesure | KM1 |
| Escalade vers un LLM | remplacée par la détection de rupture et le diagnostic | KM1 |
| VBT de poche | reporté, gardé en mémoire | — |
| A priori collectif (V2) | reporté : demande INTERNET, consentement et déclaration de données de santé | à la distribution |

## Contraintes

Le moteur tourne entièrement sur le téléphone, de façon reproductible, sans jamais assouplir la sécurité actuelle.

- **Hors ligne** : aucune permission INTERNET, manifeste vérifié à chaque build.
- **Déterminisme** : graines fixes (mulberry32, comme L7). Même journal + mêmes décisions = même état. L'état se recalcule depuis le journal et les décisions de l'utilisateur.
- **Parité** : référence Python et Dart identiques à 1e-9 près, sur des fixtures JSON partagées.
- **Paramètres externalisés** : a priori, modèles de mesure et seuils dans un fichier JSON versionné, importable depuis le mode dev.
- **Calcul** : replanification hebdomadaire en 10 s au plus, en arrière-plan ; mise à jour après une série en 50 ms au plus. Mesuré sur la VM Dart de la CI (KM2), puis sur émulateur (KM3) ; l'inspecteur du mode dev affiche le temps réel sur le téléphone de Gaël.
- **Sécurité** : les règles de `kalis_adapt` 0.3.1 (couple validé de l'application) restent des contraintes dures : conduite sous douleur, poignet, tendons, plafond de volume de la 1re semaine, feu vert médical. Zéro violation.
- **Données** : aucun nouveau champ de santé. La raison de refus n'en est pas un. Le journal de Gaël n'apparaît jamais en clair sur le dépôt public : chiffré comme les références, seuls des agrégats sont publiés.
- **Mises à jour** : installation par-dessus l'app existante sans perte, clé de signature inchangée. Publication sur `main`, build signé et run vérifié avant livraison.

## Validation et critères de bascule

La bascule n'a lieu que si tous les critères passent, vérifiés automatiquement. Un critère en échec bloque la bascule et renvoie à la brique fautive dans le lot en cours.

| Critère | Seuil | Vérifié sur |
| --- | --- | --- |
| Erreur d'e1RM après 6 séances | sous 3 % | banc |
| Effet d'un mauvais jour isolé sur l'estimation | sous 1 % | banc |
| Vitesse de convergence (séances pour passer sous 3 %) | au plus celle de `kalis_adapt` 0.3.1 | banc |
| Couverture de l'intervalle à 90 % | 88 à 92 % | banc et rejeu |
| Calibration de P(réussite) | écart prédit / observé de 5 points au plus par tranche de 10 % | banc |
| Performance le jour J, en moyenne | au moins égale à `kalis_adapt` 0.3.1 | banc, toutes saisons |
| Pire cas du banc adversarial | au moins égal à `kalis_adapt` 0.3.1 | banc adversarial |
| Violations de sécurité | 0 | banc |
| Parité Python / Dart | écart de 1e-9 au plus | fixtures |
| Rejeu walk-forward du journal de Gaël depuis S12 | erreur d'e1RM sous 3 %, couverture 88 à 92 % | journal réel |
| Temps de calcul | replanification 10 s au plus, série 50 ms au plus | VM Dart de la CI, puis émulateur |

## Lots à lancer

Trois lots, un seul APK. Toute l'itération se fait dans KM1, sur le banc, sans toucher à l'app. KM2 et KM3 ne traversent la boucle coûteuse qu'une fois. Conventions des pipelines : celles de `PIPELINE_CP.md` (état, décisions, lancements, livraisons, sauvegardes), avec les écarts de C13.

### KM1 — Méthode Koach : référence Python et banc

- **Modèle** : Fable 5.1, effort maximal. Validation automatique sur les critères de la section précédente.
- **Prérequis** : aucun. Tourne en parallèle des lots d'application (CI1g, puis lot CI final et base v1.1).
- **Entrées** : `base_exercices.json` v1.1, `kalis_bench`, `kalis_adapt` 0.3.1 comme témoin, export du journal de Gaël (sauvegarde de l'app, déposée chiffrée par le pilotage avant la brique 8).
- **Branches** : travail sur `moteurs` (référence dans `packages/kalis_adapt/reference`, ajouts dans `packages/kalis_bench`), sauvegardes `cp-sauvegardes/KM1`.
- **Contenu**, dans l'ordre, une sauvegarde par brique :
    1. Contrat 1.0 gelé : API `observe(série)`, `posterior()`, `plan(contraintes)`, `explain()`, schéma du journal, modèles de mesure, fichier de paramètres.
    2. Vecteurs de qualités des 1 039 exercices, par règles puis relecture.
    3. IRT multidimensionnelle, mesure du RIR, fatigue, test adaptatif.
    4. Banc adversarial, construit avec la brique 3 et utilisé comme oracle.
    5. Objectif, replanification glissante, jumeau numérique, optimisation bornée.
    6. Adhérence, détection de rupture, diagnostic.
    7. Contrôle dual, essais N-of-1, contrôle synthétique.
    8. Rejeu walk-forward du journal de Gaël.
- **Livrables** : `LIVRAISON_KM1.md` (mesure par critère, limites), fixtures JSON de parité, fichier de paramètres v1.
- **Jalon** : 30/10/2026.

### KM2 — Portage Dart : `kalis_adapt` 1.0.0

- **Modèle** : Fable 5.1, effort maximal.
- **Prérequis** : KM1 validé.
- **Contenu** : portage complet ; règles de sécurité de 0.3.1 intégrées comme contraintes dures ; tests de parité à 1e-9 ; athlètes adversariaux ajoutés au banc Dart ; mesure des temps de calcul.
- **Livraison** : branche fixe `etiquettes/kalis_adapt-v1.0.0`, `LIVRAISON_KM2.md`.
- **Jalon** : 09/11/2026.

### KM3 — Intégration dans l'application (dev7.0.0)

- **Modèle** : Opus 5.5.
- **Prérequis** : KM2 validé, lot CI final et base v1.1 intégrés.
- **Contenu** : remplacement du moteur de décision ; retraits listés plus haut ; comportement unique ; programme 40 semaines traité comme plan initial ; outils du mode dev ; textes de Koach pour chaque nouveau code de raison.
- **Bascule** : programmée au prochain début de bloc si tous les critères passent, soit le 23/11/2026, sinon le 04/01/2027.
- **Publication** : push sur `main`, build signé, run vérifié, `LIVRAISON_KM3.md`, liens au point d'avancement.
- **Jalon** : APK installé au plus tard le 16/11/2026.

## Calendrier

Bascule visée le 23/11/2026, au début du bloc force max (S20, 23/11/2026 → 03/01/2027). Si un jalon glisse, bascule de repli le 04/01/2027 (début du bloc endurance), sans couper le bloc 3.

| Étape | Dates |
| --- | --- |
| KM1 | 12/10 → 30/10/2026 |
| KM2 | 31/10 → 09/11/2026 |
| KM3 | 10/11 → 16/11/2026 (APK installé) |
| Bascule visée | 23/11/2026 |
| Tests de fin de bloc 3 | 28/12/2026 → 03/01/2027 |
| Bascule de repli | 04/01/2027 |
| Bloc 4 endurance (essais N-of-1) | 04/01 → 14/02/2027 |
| Bloc 5 peaking | 15/02 → 18/04/2027 |
| Deadline des cibles | 18/04/2027 |

Premier effet mesuré aux tests de fin de bloc 3. Essais N-of-1 pendant le bloc endurance, une fois le modèle calibré. Jugement final sur les cibles le 18/04/2027.
