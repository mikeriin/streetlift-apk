# Livraison KS1A — types de jour dans l'application (dev7.1.0)

Pipeline « Calibrage des programmes », voie App (tâche « Opus 5.5, effort élevé, application »), lancé par le pilotage le 16/10/2026 vers 14:37 UTC (DECISIONS_CP.md C17.20). Délégation (C8) : validation par le pilotage.

- **Base** : `main` dc9cbc55 (dev7.0.0). **Livré** : dev7.1.0 (7.1.0+130) sur `main` ee2b2078 (code bee07fee, suivi cdba4283, `pubspec.lock` ee2b2078), build signé run 38975466269, contrôle complet `claude/ci-3d` run 38954350551 (vert ; arbre identique à `main` hors `SUIVI_PROJET.md` et `pubspec.lock`, ce dernier tel que régénéré par ce contrôle : le premier build signé, run 38974569019, s'était arrêté sur le verrou périmé).
- **Paquets** : `kalis_core` 0.4.4 (`etiquettes/kalis_core-v0.4.4`, arbre 8278f8d9) et `kalis_plan` 0.4.1 (`etiquettes/kalis_plan-v0.4.1`, arbre d8b7de66) copiés à l'octet ; `kalis_adapt` 1.0.2 inchangé (arbre 2d1c0d96, le même que sur `moteurs` eae158b8, où les trois paquets ont été contrôlés ensemble, run 38873043566). KR1 n'a pas publié de 0.4.2 validée pendant le lot : 0.4.1 retenue (LANCEMENTS.md). `assets/catalog/parcours_v3.json` recopié (seul son numéro de version change).
- **Mesure de la montée seule** (`claude/ci-ui-ks1a0-rapide`, suite Dart complète, run 38918238797) : 1 062 tests verts, un seul échec — les textes des six nouveaux codes de raison (« Choix du moteur. » rendu à leur place), corrigé par ce lot. Aucun autre test (programmes générés, Koach, programme de 40 semaines) ne bouge avec `kalis_plan` 0.4.1.
- **Arbre du dépôt** (hors ressources chiffrées) : 55,50 Mo avant, 55,71 Mo après (limite 59 Mo, marge 3,29 Mo).
- **Bascule de Koach** : non touchée (`kKoachBasculeAutorisee` reste `false`, C17.19).

## 1. Ce qui est livré

### 1.1 Types de jour affichés (LIVRAISON_KS1.md § 6.1)

- `lib/plan/day_type.dart` : libellés « Tirage — force », « Jambes — endurance de force », « Figures + tirage — puissance », « Récupération » (schémas `pull` tirage, `push` poussée, `legs` jambes, `full` corps entier, `skill` figures, `run` course, `recovery` récupération ; qualités `force`, `volume`, `endurance` endurance de force, `power` puissance, `skill` technique, `conditioning`, `run`, `recovery` ; la qualité est omise quand elle redit le schéma).
- **Programme créé** : `PlanDay.type` écrit par `kalis_plan` 0.4 passe dans le JSON de la semaine (`type`, avec `minutes`) et dans `DayPlan.type` ; rien n'est déduit pour un bloc écrit avant 0.4.4 (aucun type affiché).
- **Où** : accueil (carte du jour, sous le titre), feuille de la semaine (« Tirage — force · 6 exercices, ≈ 50 min sur 120 disponibles »), résumé d'une journée, **tête de séance** (« Poussée — endurance de force · S14, J5 »), création du programme (carte de chaque jour, et une carte « Structure de la semaine » : gabarit retenu, objectif sans séance, jalon).
- **Lignes de jour de l'accueil** : gardées sur une ligne. Une première version y ajoutait le type en deuxième ligne ; le contrôle complet l'a refusée (`test/programme_test.dart`, L5 : la semaine entière doit tenir au-dessus du dock à 390 × 844). Le type est donc dans la carte du jour (ligne de détail, sans écart de plus, pour la même raison), la feuille de la semaine et le résumé.

### 1.2 Textes des six codes de raison et notes de coach

- `plan.split_chosen` (« Semaine construite en tirage, poussée, jambes, deux fois, pour tes 6 séances. »), `plan.day_type`, `plan.goal_uncovered`, `plan.milestone` (« Jalon le 12 décembre : on teste tes 2 objectifs… », « ton objectif » s'il n'y en a qu'un), `plan.replaced_disliked`, `plan.replaced_cannot_do` (nom de l'exercice remplacé) : textes de `reason_texts_fr_0_4.json` rendus avec les libellés de l'application (`lib/plan/reason_texts_0_4.dart`).
- Notes de coach `minimum_load` et `fixed_load` : rédigées par `kalis_plan` 0.4.1 (`coachReasonText`), affichées sous l'exercice comme les autres notes (test).

### 1.3 Programme de 40 semaines

- Types déduits du **titre écrit** de chaque journée, à la lecture (rien n'est enregistré, le programme d'origine n'est pas réécrit) : J1 à J3 force (« MUSCLE-UP + TIRAGE LOURD » → Tirage — force…), J4 et J5 endurance de force, J6 puissance (« SKILL MUSCLE-UP + POINTS FAIBLES » → Figures + tirage — puissance ; « PUISSANCE MU + SQUAT ENDURANCE », S11 à S19 → Corps entier — puissance, deux schémas chargés = corps entier comme `kalis_plan`) ; semaines de test : test de 1RM → force, test de maximum → endurance de force ; récupération active, repos actif, mobilité + bilan → Récupération. Relevé sur les 40 semaines : Tirage — force 40, Poussée — force 37, Jambes — force 37, Tirage — endurance de force 40, Poussée — endurance de force 37, Jambes — endurance de force 3, Figures + tirage — puissance 25, Corps entier — puissance 9, Récupération 12 ; chaque journée d'entraînement a un type, « REPOS COMPLET » aucun.
- **Choix sous délégation** : une seule qualité par jour au contrat ; le J6 « puissance et endurance » du prompt est servi en « puissance » (la qualité du titre qui vient en premier), l'endurance du squat de ce jour reste dans ses lignes.
- Les blocs importés portent le même `DayType` sur leurs journées (`PlanDay.type` : le plus fréquent des semaines du bloc ; à égalité, la première).
- **Koach** : `kalis_adapt` 1.0.2 ne lit pas `type`. Il est retiré de la référence versée à Koach et de sa signature (`koachBlocJson`) : référence et signature identiques à dev7.0.0, aucune nouvelle référence à la mise à jour (test : signature recalculée comme dev7.0.0 = signature du magasin, une seule référence après deux rafraîchissements).
- Séances faites, journal, sauvegarde d'origine : intacts (tests et cible émulateur).

### 1.4 Changement d'échéance (contrat `kalis_plan` § 12.9, KS1c1)

- `PlanProgram.eventsKey` : empreinte des échéances du profil (identifiant, date, priorité) à la validation de chaque bloc. Une échéance changée en cours de bloc (`planDeadlineChanged`) fait proposer « Préparer le bloc suivant » dans Mon programme (« Ton échéance a changé : Koach peut réécrire la suite dès la semaine 3 »), jamais imposé.
- Début du bloc suivant (`planNextFirstWeek`) : prochaine semaine du programme (aujourd'hui s'il en est le premier jour), après toute séance saisie, une semaine servie au moins ; `startDate` = **début du bloc en cours + semaines entières servies**, compté sur le bloc lui-même. À la validation, le bloc en cours est tronqué à ces semaines (`servedBlockOf`), comme `kalis_plan` 0.4.1 l'a lu pour écrire la suite. En fin de bloc normale, rien ne change.
- Programmes validés avant 7.1.0 : sans empreinte, la proposition anticipée n'apparaît qu'à partir de leur bloc suivant (limite).

### 1.5 Durée des séances (C17.15, option a)

- `dayDurationText` : « ≈ 50 min sur 120 disponibles » quand le temps disponible du jour (`PlanDay.minutesBudget` d'un programme créé) dépasse d'au moins 10 min la durée estimée ; carte du jour : « Estimé, repos inclus, sur 120 min disponibles ». Rien n'est ajouté à la séance. Programme importé : pas de créneau connu, rien d'affiché.
- **Constat** : sur le profil street 50 / 50 à six séances de 120 min, la semaine 1 générée par `kalis_plan` 0.4.1 est estimée à 20–33 min (J1 à J4), 13–18 min (J6) et 5–9 min (J5) sur 120 disponibles — très en dessous du créneau (semaine d'introduction, profil au questionnaire de santé non rempli : « programme prudent »). **Le J5 « Poussée — endurance de force » ne contient aucun exercice de poussée** (suspension active, relevés de jambes, cat-cow, étirement du poignet) : défaut de remplissage de `kalis_plan` 0.4.1 pour ce profil (aucun repère de dips ou de pompes déclaré), à confier au lot moteur suivant (KR1 ou KS2). C'est ce que l'option (c) (lot ultérieur, technique et mobilité dans le créneau) doit combler ; à vérifier aussi dans l'estimation de l'application pour les lignes d'endurance (§ 5).

## 2. Relecture indépendante

Sous-agent (Opus) sur le diff : trois points corrigés avant le contrôle final — (1) le bloc avancé était daté depuis le départ du programme, qui peut différer du début du bloc après « Où j'en suis » : en fin de bloc normale, la troncature aurait coupé une semaine faite ; corrigé (date comptée sur le bloc, troncature seulement après une échéance changée) ; (2) la cible émulateur ouvrait Mon programme sans faire défiler jusqu'à la ligne du bloc suivant ; (3) un commentaire de constante déplacé. Rien d'autre de bloquant.

## 3. Tests

- `test/ks1a_types_test.dart` (10 tests) : versions et copie du parcours ; six codes (phrases exactes, aucun code brut) ; notes `minimum_load` / `fixed_load` ; libellés ; programme de 40 semaines (types par titre, toutes les journées) ; blocs importés typés, rien d'enregistré, journal intact ; Koach (référence sans type, signature de dev7.0.0, aucune nouvelle référence) ; programme créé 50 / 50 à six séances (gabarit `ppl6_q`, types écrits et affichés, durées) ; durée sans créneau plus long ; changement d'échéance (début du bloc + 2 semaines servies, bloc en cours tronqué à 2 semaines, relu à l'identique).
- Cible émulateur `integration_test/types_ks1a_test.dart` (a sombre rouge, b clair violet) : verte dans les deux parties (run 38954350551). Session personnelle : journal identique au lancement, sauvegarde d'origine, Koach pas actif, S14·J5 « Poussée — endurance de force » sur la carte du jour, la feuille de la semaine et en tête de séance (« Poussée — endurance de force · S14, J5 »). Session de test : création (carte « Structure de la semaine », « Semaine construite en tirage, poussée, jambes, deux fois, pour tes 6 séances », Lundi · 120 min « Tirage — force »), gabarit `ppl6_q`, six types (tirage, poussée, jambes en force puis en endurance de force), carte du jour « Tirage — force » et « Estimé, repos inclus, sur 120 min disponibles », tête de séance « Tirage — force · S1, J1 » ; échéance avancée en S2 : Mon programme propose le bloc suivant « dès la semaine 3 », bloc suivant le 02/11/2026 (= début du bloc + 14 jours), bloc en cours tronqué à 2 semaines ; session personnelle intacte après suppression de la session de test.
- Cibles des lots précédents (KM3, BV11, CIF, CI1g, CI1f, CI1e, CI1c, CI1…) : vertes (KM3, BV11, CIF, CI1g, CI1f, CI1e, CI1c, CI1, CU, G10 à G1, M8, M7). Au premier passage du contrôle final, les cibles KM3 (partie a) et CI1e se sont arrêtées avant tout test (émulateur « device offline », connexion à la VM refusée) ; elles étaient vertes au passage précédent sur le même code (run 38941027883) ; une seule relance des tâches en échec : verte (run 38954350551, essai 2 : toutes les cibles, KS1A comprise).
- Tests existants adaptés : versions (7.1.0, `kalis_plan` 0.4.1).

## 4. À tester (propriétaire)

1. Installer dev7.1.0 par-dessus dev7.0.0 : séances, records et séance du jour comme avant ; la carte du jour et la tête de séance disent le type (« Poussée — endurance de force »).
2. Appui sur la barre des semaines : chaque journée de la feuille montre son type.
3. Session de test (5 appuis sur le logo) : créer un programme street 50 / 50 à 6 séances : carte « Structure de la semaine », types des jours, « ≈ … sur 120 disponibles ».

## 5. Limites et recommandations (C8)

- Types affichés seulement pour les blocs écrits par `kalis_plan` 0.4 (programmes créés avant : aucun) et pour le programme importé (déduits du titre).
- Estimation de durée très courte des séances générées (§ 1.5) : recommandation — mesurer dans le lot (c) de C17.15 la durée réelle des séances 0.4.1 (estimation de l'application comprise) avant de remplir le créneau.
- Proposition anticipée du bloc suivant : seulement pour un programme créé (le programme importé garde son échéance de fin S40) et validé depuis 7.1.0.
- Recommandation : valider dev7.1.0 ; la bascule de Koach reste au lot KB1.
