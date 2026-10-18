# Livraison KB1 — Koach 1.0.5 et `kalis_plan` 0.4.2 dans l'application, bascule fermée (dev7.2.0)

Pipeline « Calibrage des programmes », voie App (tâche « Opus 5.5, effort élevé, application »), lancé par le pilotage le 18/10/2026 vers 09:55 UTC (DECISIONS_CP.md C17.29, C17.30, option B : paquets maintenant, bascule plus tard). Délégation (C8) : validation par le pilotage.

- **Base** : `main` e5d3829b (dev7.1.9, lots PR1 à PR10 du propriétaire ; `CLAUDE.md` de `main` respecté). `main` n'a pas bougé pendant le lot. **Livré** : dev7.2.0 (7.2.0+140) sur `main` __MAIN__, build signé run __BUILD__, contrôle complet `claude/ci-3d` run __CI__ (arbre identique à `main`).
- **Couple servi** : exactement celui mesuré à 0 violation sur les 90 600 saisons (C17.17.3, C17.29) : `kalis_plan` 0.4.2 × Koach 1.0.5 (`kalis_adapt` 1.0.4). `kalis_core` 0.4.4 inchangé.
- **Bascule** : fermée (`kKoachBasculeAutorisee = false`) ; date notée à l'installation inchangée (23/11/2026 si dev7.x est installé au plus tard le 16/11/2026) ; session de test : bascule forcée et essai sur copie, désormais avec Koach 1.0.5.

## 1. Paquets et empreintes

| Paquet | Étiquette | Copié | Empreinte (fichiers, SHA-256 de la liste « chemin\0SHA-256\n » triée) |
| --- | --- | --- | --- |
| `kalis_adapt` 1.0.4 (Koach 1.0.5) | `etiquettes/kalis_adapt-v1.0.4` (9c81a201) | `lib/`, `assets/koach/`, `pubspec.yaml` **seulement** (C17.19.3, LIVRAISON_KM2c3.md § 7) | 55 fichiers, `06c8f971…16154` |
| `kalis_plan` 0.4.2 | `etiquettes/kalis_plan-v0.4.2` (bcb8422b) | paquet entier, comme avant | `lib/` + `pubspec.yaml` : 32 fichiers, `9ce7e5a0…35ace` ; arbre du paquet identique à l'étiquette (2684beef) |
| `kalis_core` 0.4.4 | `etiquettes/kalis_core-v0.4.4` | inchangé | arbre identique à l'étiquette et aux deux étiquettes ci-dessus |

- Vérifié dans la session par `git ls-tree` (objets identiques à ceux des étiquettes) et dans les tests (`test/kb1_koach105_test.dart`, empreintes recalculées sur l'arbre de l'application).
- **Asset de paramètres** : `assets/koach/koach_params_1_0_5.json` (version `1.0.5-ref.1`, SHA-256 `d8a492b7debca0e4a504ed399efee0a8a6e4e003ab99f7cbb7f49c114bfbf26d`) à la place de `koach_params_1_0_3.json` (l'application était encore en 1.0.2 / Koach 1.0.3 : KR1 n'avait pas été monté) ; déclaration `pubspec.yaml`, chemin lu par `rootBundle` (`kKoachParamsAsset`), tests d'empreinte (KM3 et KB1). `vecteurs_qualites_v1.json` inchangé (identique au paquet).
- `pubspec.lock` : versions des deux paquets de chemin (1.0.4, 0.4.2), aucune autre dépendance ne change.
- API, schéma du journal et codes de raison inchangés : aucun code de l'application à changer pour le moteur. Deux textes de raison de Koach changent (« Retour progressif : séries limitées sur … pour ménager … » ; « Je retire … : la dose du jour pour … est atteinte (retour progressif). ») : testés.

## 2. Taille de l'arbre (hors ressources chiffrées, limite 59 Mo)

| | Avant (e5d3829b) | Après |
| --- | --- | --- |
| Arbre du dépôt | 55 798 957 octets (55,80 Mo) | 28 341 835 octets (28,34 Mo) |
| `packages/kalis_adapt` | 29 646 177 octets | 2 108 918 octets |
| `packages/kalis_plan` | 2 131 737 octets | 2 170 515 octets |

Marge : 30,7 Mo. La limite de 59 Mo (`tools/release_security.py`) n'est pas baissée par ce lot (choix : un lot de l'application ne change pas une barrière de livraison sans décision ; recommandation au pilotage : la ramener à 35 Mo au prochain lot qui touche la livraison).

## 3. Code retiré, code gardé

| Élément | Décision | Pourquoi |
| --- | --- | --- |
| `packages/kalis_adapt/reference/` (référence Python, 21 Mo), `test/` (fixtures de parité, 5,4 Mo), `tool/`, `docs/`, `bin/`, `CONTRAT.md`, `CHANGELOG.md`, `README.md`, `analysis_options.yaml` | **retirés de l'arbre** | C17.19.3 : l'application n'embarque que le Dart et les assets ; tout est sur `moteurs` et dans l'étiquette. Le contrôle des paquets de la CI (`ci-3d.yml`, `ci-ui.yml`) saute `dart test` pour une copie sans `test/` (formatage et analyse restent ; l'analyse stricte et les tests de `kalis_adapt` tournent sur `moteurs`). |
| Code 0.x de `kalis_adapt` (`KalisAdapt`, `review`, `applyProposal`, `simulation.dart`…) | **gardé** | Il est dans `lib/` du paquet, copié à l'octet (il ne peut pas être retiré sans changer l'étiquette) et, bascule fermée, **c'est lui qui sert le bloc en cours** du propriétaire. |
| Appels de l'application au moteur 0.x | **tous gardés** | Inventaire complet (sous-agent, graphe d'appels depuis `main.dart`) : `prescribeSession` / `adviseNextSet` (séance), `review` (Évolution, bloc suivant, programme importé), `planEventDay` (jour J), `applyProposal` (propositions, couche d'ajustements), `AdaptParams` / `unlockLevelFor` (déblocage), `ExerciseBook` (partagé avec Koach et l'import du programme de 40 semaines), inspecteur et simulateur du mode dev : **tous atteignables**. Aucun symbole 0.x mort tant que la bascule est fermée. |
| Petites déclarations mortes hors moteur (`ExerciseLog.removeLastSet`, `showRirFor`, `realClock`, `openKoachInspector`, `mergeWeeks`, `diffWeeks` / `ProgramDiff`, `lib/motion.dart`, `lib/mixamo_skeleton.dart`…) | **gardées** | Hors périmètre (« code 0.x devenu mort ») et sans gain pour l'APK ; à retirer par un lot de nettoyage. |

**Quand le code 0.x devient mort** : à KB2 la constante s'ouvre, mais Koach ne prend la main qu'au début du bloc suivant la date de bascule (S20, 23/11/2026) ; jusque-là, et pour tout programme créé dont le bloc en cours a commencé avant, le moteur 0.x sert encore. Recommandation : retrait du code 0.x (application et paquet, par une étiquette `kalis_adapt` 1.1.0 sans `src/engine.dart` et ses dépendances) **après** la prise de main effective, pas à KB2.

## 4. Ce qui change dans l'application

1. **Koach 1.0.5** dans la session de test (bascule forcée) et dans l'essai sur copie du mode dev ; prise de main, séance, rejeu : versions `1.0.5-ref.1`.
2. **Export du journal moteur** (session de test › outils › inspecteur de Koach, « Exporter le journal moteur », sur la sauvegarde importée) : donne les versions du moteur qui rejoue le journal (celles de ce build) ; une prise de main faite par une version d'avant (session de test de dev7.1.x) garde la sienne dans un bloc `prise_de_main`. Avant la bascule (session personnelle), l'export est construit comme avant, au format de `walk_forward` : c'est celui dont KB2 a besoin.
3. **Carte « Structure de la semaine »** (création du programme et bloc suivant) : quand `kalis_plan` 0.4.2 change le type d'un jour faute d'exercice possible de son schéma (KS1c2, `_ensurePrincipal` / `_unservedReasons`), une ligne par jour, icône d'échange, texte secondaire du kit : « Mardi devient « Récupération » pour ménager ton poignet (gêne 6/10). », « … faute de matériel (barres parallèles). », « … faute d'exercice possible pour l'instant (Dips écarté). ». La cause est lue juste après le `plan.day_type` du jour (`lib/plan/plan_texts.dart` : `dayTypeChanges`, `dayTypeChangeText`). Pour `plan.prerequisite_missing`, texte volontairement neutre : `kalis_plan` 0.4.2 écrit ce code aussi pour un mouvement écarté par un autre motif (exclu, niveau, technique) ; « il faut d'abord maîtriser » serait faux dans ces cas (constat de la relecture, à signaler au moteur).
4. Version 7.2.0+140 (`kVersion`, tests de version).

## 5. Tests

- `test/kb1_koach105_test.dart` (11 tests) : versions et empreintes des paquets ; arbre de `kalis_adapt` (aucun `reference/`, `test/`, `tool/`, `docs/`, `bin/`) ; asset 1.0.5 (SHA-256, déclaration, chemin, version) ; deux textes de raison ; bascule fermée (moteur d'avant au bloc en cours, date 23/11) ; export avant la bascule (versions 1.0.5, séances au format de walk_forward) ; prise de main forcée par 1.0.5 ; **journal d'une version d'avant** (instantané 1.0.3) relu : journal et séances versées identiques, état rejoué par 1.0.5 identique à un rejeu neuf, export avec `prise_de_main` ; **migration depuis dev7.1.9** (programme de 40 semaines, S1 à S14 : mêmes séances, séries et records après relancement, `logs`, `programStart` et `programOrigin` identiques, bloc en cours servi par le moteur d'avant) ; carte : lecture des causes, phrases exactes, et profil street 50 / 50 à six séances poignet gêné 6/10 (consentement santé donné) : jours de poussée changés de type, cause `plan.joint_limitation`.
- Tests existants adaptés : versions (7.2.0, `kalis_plan` 0.4.2, `kalis_adapt` 1.0.4) et nom de l'asset (KM3).
- Suite complète : __TESTS__.
- **Cible émulateur** `integration_test/koach_kb1_test.dart` (a sombre rouge, b clair violet) : session personnelle (migration S1 à S14 : journal identique, sauvegarde d'origine, Koach pas actif, date de bascule ; écran de l'inspecteur ouvert directement — dans l'application il est dans les outils de la session de test —, « Exporter le journal moteur » touché, fichier capté : `journal_moteur`, 1.0.5) ; session de test (création, carte « Structure de la semaine » avec la raison, bascule forcée par 1.0.5, inspecteur, export) ; session personnelle intacte. __EMU__
- Cibles des lots précédents (KS1A, KM3, BV11, CIF, CI1g… et PR1 à PR10 par la suite Dart) : __CIBLES__

## 6. Relecture indépendante

Sous-agent (Opus) sur le diff de l'application : rien de bloquant. Corrigés avant le contrôle final : phrases de la carte (deux-points en série, article de l'articulation), texte neutre pour `plan.prerequisite_missing`, jour retrouvé par `dayIndex` et clés uniques, précompilation de la cible KB1 dans `ci-3d.yml`. Notés : l'explication reste celle de la proposition si l'utilisateur ajoute ensuite un exercice de poussée au jour (le type affiché reste cohérent) ; analyse de `kalis_adapt` moins stricte dans l'application (stricte sur `moteurs`).

## 7. Limites

- Code 0.x encore dans l'APK (§ 3).
- La cause « prérequis » de `kalis_plan` 0.4.2 couvre plusieurs motifs : texte neutre côté application ; une cause précise demanderait un code par motif dans le moteur (lot moteur).
- Démarrage à froid inchangé (rejeu du journal de Koach dans un isolat à l'ouverture, session de test).
- Délai du job émulateur de la CI porté à 125 min (cible KB1 en plus).

## 8. Ce que KB2 aura à faire

1. Export neuf du journal moteur par le propriétaire (dev7.2.0 : sauvegarde importée dans la session de test, inspecteur de Koach › « Exporter le journal moteur », avant de forcer la bascule), au moins 100 séries notées depuis S12.
2. Critère 10 sur cet export (rejeu de la référence, clé des références si besoin).
3. Si tenu : `kKoachBasculeAutorisee = true` (une constante, `lib/koach1_store.dart`) et la version ; rien d'autre (paquets déjà montés). Avant le 16/11/2026 pour garder la bascule au 23/11.

## 9. À tester (propriétaire)

1. Installer dev7.2.0 par-dessus dev7.1.9 : séances, records et séance du jour comme avant (bascule fermée).
2. Session de test (5 appuis sur le logo) : importer ta sauvegarde ; appui long sur l'étiquette DEV › Inspecteur de Koach 1.0 › « Exporter le journal moteur » : le fichier `koach_journal_moteur.json` se partage (c'est l'export que KB2 demandera vers le 10/11 ; versions 1.0.5).
3. Toujours dans la session de test : « Koach prend la main cette semaine » : Koach 1.0.5 (« Moteur : 1.0.5-ref.1 ») ; faire une séance.
4. Session de test : créer un programme avec une gêne forte (poignet 6/10, consentement santé donné) : la carte « Structure de la semaine » dit quel jour change de type et pourquoi.
