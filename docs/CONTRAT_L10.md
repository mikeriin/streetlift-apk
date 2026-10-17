# Contrat L10 — Générateur de programme personnalisé (4.0.0)

**27 septembre 2026, lot exécuté par le pipeline automatisé (sans échange en direct).** Tickets KT-050 à KT-057. Code : `lib/program_generator.dart` (générateur, fonction pure), `lib/program_instance.dart` (instance, fusion, « ce qui change », progression lue dans le journal ; fonctions pures), `lib/program_store.dart` (branchement sur le store), `lib/program_screens.dart` (écrans), `assets/program_models.json` (modèles de périodisation, données versionnées). Tests : `test/l10_generator_test.dart`, `test/l10_properties_test.dart`, `test/l10_profiles_test.dart`, `test/l10_store_test.dart`, `test/l10_screens_test.dart`, `tools/tests/test_program_models.py`.

## 1. Base et contradictions relevées

| Point | Constat | Traitement |
| --- | --- | --- |
| Base | `streetlift_tracker_v33.zip` 3.2.0+66 (L9b), `main` `6015ebc`, 2 031 485 octets, SHA-256 `699329b4824b2ceef27355c85a7310de73ec00c6a97d1984c031bed20f578f14`, racine unique `streetlift_tracker/` ; prérequis L7, L8, L9b livrés | Travail sur copie |
| Contrats lus | `CONTRAT_L7.md` (Koach), `CONTRAT_L8.md` (profil), `CONTRAT_L9b.md` (pack) | — |
| Repère du profil L8 et seuils L10 | L8 enregistre des **tranches** (pompes 0 / 1-9 / 10-24 / 25-44 / 45+, tractions 0 / 1-4 / 5-11 / 12-19 / 20+) ; L10 propose d'autres seuils (pompes 0-9 / 10-24 / 25-44 / 45-69 / 70+, tractions 0 / 1-5 / 6-12 / 13-20 / 21+) | Une tranche L8 devient la borne basse de répétitions (« estimé ») ; les références de Pilotage (B17, B19) et le calibrage priment. D-L10-01 |
| Niveau global | L8 : tranche **la plus basse** (valeurs par défaut du mode) ; L10 : **médiane** des mouvements | L10 utilise la médiane basse pour la périodisation seulement ; les valeurs par défaut du mode et du ton (L8) ne changent pas. D-L10-02 |
| « Durée dans ±10 % » | Avec 3-4 h disponibles, le plafond de volume (départ + 6 séries par groupe) empêche de remplir la séance | Séance plus courte signalée (« volume plafonné », ligne « pourquoi » et champ `capped`) ; +10 % n'est jamais dépassé. D-L10-03 |
| « Chaque exercice retenu a une démonstration animée » | Le pack a 573 démonstrations animées, 34 statiques, 18 indisponibles | Seules les 573 animées sont proposées par le générateur |
| Retour facultatif par muscle (mode Expert) | Aucune saisie de ce retour n'existe encore (L7/L8) | Ajustement ±2 séries selon la tendance de performance seulement ; retour par muscle reporté. Limite §9 |
| Fiche depuis l'écran de séance (D-L9b-09) | En attente de relecture | Non tranchée ici (un bouton dans la feuille de consignes repoussait « Fermer » hors de l'écran dans un test existant) ; reste en attente |

## 2. Décisions prises par défaut (réversibles)

| Id | Décision | Pourquoi / comment revenir |
| --- | --- | --- |
| D-L10-01 | Mesures du niveau : références de Pilotage (B19 pompes, B17 tractions, B11/B4 squat, B8/B4 et B9/B4 lests) sinon tranche du profil convertie en répétitions (borne basse, « estimé »), remplacées par le calibrage | Prudence ; `benchmarkBandReps` dans `program_models.json` |
| D-L10-02 | Niveau global = médiane basse des mouvements mesurés ; un mouvement non mesuré prend ce niveau (« par défaut ») | Entre deux niveaux, le plus bas |
| D-L10-03 | Durée : jamais au-delà de +10 % ; en deçà de −10 % seulement si le volume est plafonné (signalé), en semaine de décharge ou d'affûtage, le jour de l'épreuve et le jour de récupération active | Le volume prime sur le remplissage |
| D-L10-04 | Installation antérieure (propriétaire) : instance **implicite** « Expert streetlifting » = programme embarqué inchangé, rien n'est écrit tant qu'elle n'est pas remplacée ; l'export reste identique à 3.2.0 | Aucune donnée réécrite ; « Mon programme → Générer » la remplace, semaines passées conservées |
| D-L10-05 | Nouveau profil (démarrage court) : programme généré au choix du départ (écran Départ du programme) | Le départ fixe les jours (J1 = date choisie) |
| D-L10-06 | Modèle Expert streetlifting choisi seulement au départ (semaine 1, aucun journal) ; en cours de route le générateur prend les blocs | Le programme de 40 semaines ne se rejoint pas au milieu |
| D-L10-07 | Tests légers de calibrage : semaine 1 (et semaine 2 pour les mouvements non vus) du premier cycle ; mini-test à la dernière séance de chaque décharge ; jamais d'échec ni de maximum ; les références de Pilotage ne sont pas réécrites (mesures gardées dans l'instance) | L'utilisateur garde la main sur ses références |
| D-L10-08 | Objectif sans date : cycles de 5 à 6 semaines générés un par un ; le suivant est produit pendant la dernière semaine du cycle en cours, depuis le journal | « Jamais au milieu d'un cycle » |
| D-L10-09 | Objectif daté à plus de 40 semaines : cycles ordinaires jusqu'à ce que la date entre dans l'horizon de 40 semaines | Limite des adaptations Koach (semaine ≤ 40) |
| D-L10-10 | Matériel déduit du lieu : maison → serviette, bâton ; parc → barre basse, espace extérieur ; salle → serviette (+ barre basse avec un rack) ; partout : sol, mur, support stable | À valider (registre) |
| D-L10-11 | Répartition « Koach décide » ou choix de l'utilisateur (corps entier, haut/bas, poussée/tirage/jambes) ; le mouvement de l'objectif est ajouté en complément aux séances qui ne le travaillent pas pour garder 2 séances par semaine | Écran Mon programme |
| D-L10-12 | Endurance : mouvement ciblé choisi dans Mon programme (tractions par défaut avec une barre, sinon pompes) | Le profil L8 ne le demande pas |
| D-L10-13 | Premier programme d'un nouvel utilisateur : pas d'annulation (rien à rétablir) ; régénérations suivantes : annulables 7 jours tant qu'aucune séance régénérée n'est saisie | KT-057 |

## 3. Architecture (KT-050)

**ProgramInstance** (section `programInstance` de la sauvegarde, format 3 inchangé, écrite seulement si l'instance existe ; ignorée par les versions antérieures) :

```json
"programInstance": {
  "v": 1, "kind": "generated|template", "origin": "onboarding|user|profile|start|cycle|migration",
  "createdAt": "…", "updatedAt": "…", "generator": "1.0.0", "models": "1.0.0", "seed": 123,
  "inputs": { "start": "AAAA-MM-JJ", "goalPrimary": "…", "weekdays": [1,3,5], "sessionMinutes": 45,
              "places": {…}, "measures": {…}, "entries": {…}, "volumeAdjust": {…}, … },
  "weeks": [ …semaines au schéma de programme_v33 (7 journées, exercices)… ],
  "koach": { "exercises": {"g1.1.4": {"rirTarget": 2}, …}, "weeks": {"1": "normal", …} },
  "summary": { "model": "…", "modelLabel": "…", "explanation": "…", "levels": {…}, "split": "…",
               "targets": {…}, "ceiling": 16, "weekVolumes": […], "capped": […] },
  "history": [ {"at": "…", "fromWeek": 1, "toWeek": 5, "cycle": 0, "seed": 123, "reason": "onboarding", "generator": "1.0.0", "model": "…"} ],
  "cycle": 0, "options": {"split": "auto", "focus": ""},
  "undo": {"at": "…", "fromWeek": 2, "instance": {…}}, "profileKey": "…"
}
```

Champs ajoutés aux exercices générés (ignorés par `Exercise.fromJson` sauf `why`) : `why`, `role` (`warmup`, `mobility`, `ramp`, `calibration`, `main`, `accessory`, `specific`, `circuit`, `cooldown`, `test`), `exId` (identifiant du pack), `groups`, `hard` (séries difficiles), `heavy`, `family`. Journées : `why`, `kind`, `place`, `minutes`, `estimate` (s), `capped`.

- **Générateur** : `generateProgram(models, catalog, base, inputs, seed, firstWeek, cycle)` → programme + annotations Koach + résumé ; pur, sans horloge ; départage par hachage FNV-1a de la graine (aucun générateur aléatoire séquentiel). Reproductible au caractère près (tests de référence : `test/goldens/l10_reference.json`).
- **Méthode hybride** : modèles de périodisation en données (`assets/program_models.json` 1.0.0 : niveaux, difficultés, volumes, repos, échauffement, affûtage, décharge, modèles), choix des exercices et des volumes par règles.
- **Séances passées figées** : une régénération part d'aujourd'hui ; les journées antérieures et toute journée déjà saisie restent celles de l'ancienne version (`mergeWeeks`) ; le journal n'est jamais modifié.
- **Migration** : sans section `programInstance`, l'instance est implicite (modèle Expert streetlifting) : le programme affiché est l'asset embarqué, octet pour octet (LC1 comprise), avec le départ, l'historique et l'état Koach existants. Test d'égalité des 40 semaines : `test/l10_generator_test.dart` (générateur) et `test/l10_store_test.dart` (store, historique complet, export identique).
- **Koach** : programme généré → annotations `rirTarget` pour chaque exercice difficile, et `strength` (référence B8-B11, mouvement) pour les mouvements lestés quand la référence existe ; courbe et accessoires repris des annotations d'origine.

## 4. Niveaux et calibrage (KT-051)

| Mouvement | Mesure | Débutant | Novice | Intermédiaire | Avancé | Expert |
| --- | --- | --- | --- | --- | --- | --- |
| Poussée | pompes | 0-9 | 10-24 | 25-44 | 45-69 | 70+ |
| Poussée (lest) | dip lesté, % du poids du corps | — | — | — | ≥ 40 % | ≥ 75 % |
| Tirage | tractions | 0 | 1-5 | 6-12 | 13-20 | 21+ |
| Tirage (lest) | traction lestée, % du poids du corps | — | — | — | ≥ 25 % | ≥ 50 % |
| Squat | 1RM / poids du corps | < 0,75 | 0,75-1,25 | 1,25-1,6 | 1,6-2,0 | > 2,0 |
| Charnière | répétitions (pont, soulevé) | < 10 | 10-19 | 20-34 | 35-49 | 50+ |
| Gainage | planche (s) | < 30 | 30-59 | 60-89 | 90-149 | 150+ |

Niveau global = médiane basse ; il ne sert qu'au choix de la périodisation et des valeurs de départ. Calibrage : série unique « 1×5-20 » (charge : « 1×5-8 ») arrêtée à 2-3 répétitions en réserve, en tête de séance, après l'échauffement. Résultat (répétitions + RIR) : mesure `calibrated` pour les pompes et les tractions, étape de chaîne validée si le seuil du pack est atteint. Passage d'étape : seuil tenu sur **2 séances** → étape suivante au **cycle suivant**.

## 5. Périodisation, répartition, exercices, volume (KT-052 à KT-055)

- **Modèles** : débutant et novice → progression linéaire (4 semaines + décharge, +1 répétition par semaine, « +1 rép. par séance réussie ») ; intermédiaire → ondulation (séances lourde 4-6, volume 8-12, légère 12-15) ; avancé et expert → blocs (accumulation 2 sem. 8-10 RIR 2 +1 série, intensification 2 sem. 4-6, réalisation 1 sem. 2-3 RIR 1 volume −20 %, décharge) ; « Forme et santé » → corps entier, RIR 2-4, linéaire douce (3 semaines + décharge) puis ondulation ; Expert streetlifting → programme de 40 semaines. Mode prudent : RIR ≥ 3, difficulté −1, aucun saut ni élan, jamais le modèle Expert.
- **Horizon** : objectif daté (≤ 40 semaines) → cycles jusqu'à la date, simulations partielles en fin de cycle, simulation complète 2 à 3 semaines avant, affûtage de 7 jours (moins de 8 semaines) ou 14 jours (volume −50 %, intensité maintenue), jour J (« TEST — JOUR J ») ; sans date → un cycle à la fois.
- **Décharge** : volume ×0,6, RIR +1, mini-tests ; au moins toutes les 6 semaines.
- **Objectif secondaire** : pondération 70/30 (réglable 50-100) appliquée aux séances principales de tout le programme (plages endurance 10-15+, force 4-6).
- **Répartition** : 2 → corps entier ×2 ; 3 → ×3 ; 4 → haut/bas ×2 ; 5 → haut/bas + poussée/tirage/jambes ; 6 → poussée/tirage/jambes ×2 ; 7 → idem + récupération active. 48 h entre deux séances lourdes d'une même famille : la seconde devient technique (RIR + 2).
- **Durée** : estimation `training_estimate.dart` (échauffement compris), ajustée par retrait des séries puis des exercices de plus faible priorité ; le premier principal et les mouvements indispensables au minimum hebdomadaire sont gardés le plus longtemps.
- **Exercices** : matériel du lieu du jour (§2 D-L10-10), prérequis atteints (étape validée ou difficulté du prérequis ≤ plafond du niveau), position dans les chaînes (points d'entrée), exercices détestés exclus (remplacés par le suivant du même type), gêne > 3/10 → contrainte articulaire de la zone ≤ 1, démonstration animée, figures seulement pour une épreuve de muscle-up ; principaux stables d'un cycle à l'autre, accessoires renouvelés.
- **Volume** : séries difficiles (RIR ≤ 3) par groupe et par semaine : 6 / 8 / 10 / 12 / 14 selon le niveau (« Forme et santé » −2), plafond départ + 6 ; ajustement ±2 par cycle (performance en baisse de plus de 3 % → −2 ; stable → +2 ; en hausse → inchangé) ; groupes de l'objectif servis en premier. Les séries de calibrage, de simulation et les blocs chronométrés ne sont pas comptés.

## 6. Échauffement, travail spécifique, explications, régénération (KT-056, KT-057)

- Échauffement de 5 à 10 minutes : 3 minutes d'activation générale (sans impact en mode prudent), 2 à 4 minutes de mobilité des articulations du jour, montée en charge sur le premier principal (40 % × 5, 60 % × 3, 75 % × 2, 85 % × 1 un jour lourd ; 3 ou 2 paliers sinon ; 2 séries d'approche au poids du corps).
- Endurance : blocs de densité sur le mouvement ciblé (EMOM, AMRAP court, échelles). Préparation datée : simulations partielles puis complète. « Forme et santé » : circuit à faible impact de 6 à 10 minutes (sans circuit sous 25 minutes) et 5 minutes de mobilité.
- Une ligne « pourquoi » par séance (consignes de séance) et par exercice (consignes de l'exercice), simple pour débutant et novice, technique à partir d'avancé.
- Régénération : profil modifié (objectifs, lieux, matériel, jours, durée, gênes, prudence, goûts), choix de répartition ou de mouvement ciblé → aperçu « ce qui change » (séances par semaine, durée moyenne, séries par groupe, exercices ajoutés et retirés sur 2 semaines) puis application ; mode Guidé : appliquée automatiquement, annulable 7 jours.

## 7. Tests

Propriétés sur 10 000 profils aléatoires (graines 1 à 10 000) ; 13 profils types exportés (`docs/PROFILS_TYPES_L10.md`) ; égalité des 40 semaines du propriétaire ; déterminisme et références figées ; store (migration, génération, persistance, export et import, régénération, annulation, mode Guidé, cycle suivant) ; écrans à 390 × 844 et 320 × 720, texte 100/130/200 %, clair et sombre. Résultats : `SUIVI_PROJET.md` L10.3.

## 8. Registre de validation (à relire par un professionnel diplômé)

| Élément | Qui |
| --- | --- |
| Seuils de niveau (pompes, tractions, squat, lests, charnière, gainage) et conversion des tranches du profil | Préparateur physique |
| Difficulté maximale par niveau (principal 2/3/5/6/8, accessoire 2/3/4/5/6), pénalité du mode prudent | Préparateur physique |
| Modèles de périodisation (durées, plages, RIR, volumes par phase), décharge ×0,6, affûtage −50 % sur 7 ou 14 jours | Préparateur physique |
| Volumes par groupe (6 à 14 séries, −2 en santé, plafond +6, ajustement ±2 et ses seuils) | Préparateur physique |
| Échauffement (paliers 40-85 %), calibrage (1 série RIR 2-3), mini-tests | Préparateur physique |
| Règle des 48 h et définition d'une séance lourde (≤ 6 répétitions à RIR ≤ 2) | Préparateur physique |
| Circuits à faible impact, blocs de densité (EMOM, AMRAP, échelles) | Préparateur physique |
| Contrainte articulaire ≤ 1 si gêne > 3/10, exclusion des sauts en mode prudent | Kinésithérapeute / médecin du sport |
| Matériel déduit des lieux (D-L10-10) | Propriétaire |
| Pourcentages de charge (formule d'Epley) des mouvements lestés | Préparateur physique |

## 9. Limites

- Aucun essai sur téléphone ; durées estimées, pas chronométrées ; temps de génération sur téléphone non mesuré.
- Retour facultatif par muscle du mode Expert : non saisi, non utilisé.
- Les adaptations de structure de Koach restent bornées à la semaine 40 (contrat L7) : au-delà, le programme continue sans elles.
- Une régénération au milieu d'un programme de 40 semaines copie les semaines passées dans l'instance (sauvegarde plus lourde, bornée par les limites d'import).
- Le départ modifié après une séance saisie ne régénère pas le programme (les jours restent décalés) : « Mon programme → Régénérer » le fait.
- Contenu sportif non relu par un professionnel diplômé (décision du propriétaire) : aucun bénéfice de santé ni gain de performance n'est promis.
