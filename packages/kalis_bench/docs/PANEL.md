# Panel de coachs virtuels — protocole (kalis_bench 0.1.0)

Quatre relecteurs indépendants, un par école, notent chaque programme (ou chaque trajectoire) de leur point de vue. Leurs notes mesurent ce que les critères calculables ne voient pas : la pertinence, la cohérence, l'individualisation. Le seuil du pipeline est **9/10 pour chaque école et chaque profil du périmètre du lot**, avec 0 violation de sécurité aux critères calculables (PIPELINE_CP.md §2).

## Écoles et grilles (gelées)

| École | Code | Grille | Critères |
|---|---|---|---|
| Force et streetlifting | `force` | `grilles/force_streetlifting.md` | F1 à F9 |
| Calisthénie et figures | `calisthenie` | `grilles/calisthenie_figures.md` | C1 à C9 |
| Hypertrophie et esthétique | `hypertrophie` | `grilles/hypertrophie_esthetique.md` | H1 à H9 |
| Endurance, santé et kiné | `sante` | `grilles/endurance_sante_kine.md` | S1 à S9 |

Règles communes, ancrages de la note d'ensemble et format de réponse : `grilles/COMMUN.md`. Chaque école note **tous** les profils du périmètre, y compris ceux qui ne sont pas de sa spécialité (la grille dit comment : elle juge alors ce qui, dans le programme, relève de son domaine au service de l'objectif du profil).

**Gel.** Grilles et règles communes sont gelées depuis l'étalonnage (`ETALONNAGE_PANEL.md`). Les modifier pendant un calibrage pour atteindre le seuil est interdit (PIPELINE_CP.md §7). Empreintes SHA-256 :

| Fichier | SHA-256 |
|---|---|
| `grilles/COMMUN.md` | `8e8407c4c474ffcbb0f93183d9c6eb1d923a4a7ec7499e3afb6672af5bfea37e` |
| `grilles/force_streetlifting.md` | `58fd74fabda27f7604253233f2093b5d4839a427cc679de989840e55936ef126` |
| `grilles/calisthenie_figures.md` | `a0faf3afb6bc327bc94de626f4e07197b2fd4626a42d48ec7846dc2f342bd715` |
| `grilles/hypertrophie_esthetique.md` | `00e74ab98c8ab3fe6a153b5bd437882b642d61a227cacddab50fc87b271ac84c` |
| `grilles/endurance_sante_kine.md` | `84485fb3c8460accd8ce3fabed5ae3bf2c9e956e84a2dc57218aa5c07242a64c` |
| les cinq fichiers concaténés dans cet ordre | `7d337a2e8c0cf96f7e27dce10fe619b1793ae14b26694bec072e5a7ff81bd7fa` |

Vérification : `cd docs/grilles && sha256sum COMMUN.md force_streetlifting.md calisthenie_figures.md hypertrophie_esthetique.md endurance_sante_kine.md`. Un lot commence par cette vérification et la consigne dans sa livraison.

## Ce que reçoit un relecteur

Un dossier isolé, hors du dépôt, qui contient seulement :

- `COMMUN.md` et `GRILLE.md` (la grille de son école) ;
- `REFERENTIEL.md` (la synthèse ; il y cherche les principes cités) ;
- `programme_1.md` … `programme_4.md` : au plus quatre profils d'une même école par appel ; chaque fichier commence par le profil (résumé, identité, niveau, disponibilités, matériel, records, échéance, gênes) puis donne le programme (export concis : `python3 tool/panel_export.py <rapport>/programmes/<profil>.json`) ou la trajectoire (`<rapport>/trajectoires/<profil>.md`).

Il ne voit ni le code, ni les notes des autres écoles, ni les versions précédentes, ni le nom du moteur ou du lot. Jamais deux écoles dans le même appel, jamais deux versions d'un même profil dans le même appel.

## Appel type

Sous-agent (outil Agent), **`model: "opus"`** (PIPELINE_CP.md §9), avec ce message, où `<dossier>` est le dossier isolé :

> Tu es un relecteur du panel de coachs virtuels d'une application d'entraînement. Ton dossier de travail est `<dossier>`. Lis d'abord COMMUN.md (règles et format de réponse), puis GRILLE.md (ton école, ta grille), puis chaque fichier programme_*.md du dossier, en entier. REFERENTIEL.md est à ta disposition : cherche-y les principes cités par leur identifiant (par exemple R3-P12) quand tu en as besoin. Ne lis AUCUN autre fichier ni dossier, ne lance aucune commande autre que la lecture de ces fichiers et l'écriture de ta réponse. Note chaque programme indépendamment des autres : ils concernent des athlètes différents. Écris ta réponse JSON (format exact de COMMUN.md, un objet par programme, champ "programme" = nom du fichier) dans `<dossier>/notes.json`, puis réponds seulement par « fait » suivi des notes d'ensemble par fichier.

Le lot lit ensuite chaque `notes.json` **en entier** (notes par critère, points perdus, corrections nécessaires et améliorations).

## Note retenue et décision

- Note retenue par école et par profil : la **note d'ensemble**. Le minimum sur les quatre écoles et tous les profils du périmètre est la note « panel (min) » du lot.
- Une note d'ensemble sous 9 est toujours accompagnée d'au moins une **correction nécessaire**, écrite avec sa conséquence : c'est la feuille de route de la boucle suivante. Le lot corrige le moteur (jamais la grille ni le profil), régénère, et fait renoter.
- **Incertitude** (mesurée à l'étalonnage) : deux appels indépendants de la même école sur le même programme diffèrent de 0,25 point en moyenne et de 1 point au plus ; autour du seuil, un programme peut recevoir 8 d'un appel et 9 d'un autre. Règle de traitement d'une note de 8 ou 8,5 : (1) si la correction nécessaire est fondée, la faire et renoter ; (2) si elle est factuellement fausse (le relecteur a mal lu le programme ou le profil), le consigner dans la livraison avec la preuve et renoter par un nouvel appel — sans changer l'export pour « expliquer » au relecteur. Une note n'est jamais moyennée avec une autre pour passer le seuil ; la dernière notation fait foi.
- Les notes et commentaires du **propriétaire** (page de relecture) priment sur ceux du panel.

## Économie (PIPELINE_CP.md §9)

- Passe complète (toutes les écoles, tous les profils du périmètre) seulement au départ (mesure avant) et à la fin (avant livraison). Entre les deux, chaque boucle recalcule les critères calculables sur tous les profils et ne fait renoter que les couples (école, profil) sous 9 à la boucle précédente et ceux dont l'export a changé de plus de 10 % des lignes.
- Au plus 6 boucles par lot. Une régression trouvée par la passe finale ouvre une boucle de plus, dans cette limite.
- Ordre de grandeur : un appel de quatre programmes coûte 70 000 à 100 000 jetons sur Opus et dure 1 à 3 minutes ; une passe complète sur les 17 profils street représente 20 appels, sur les 27 profils 28 appels.

## Trajectoires (CA1, CX, CA2, CY)

Même protocole : le fichier noté est l'export de trajectoire (`trajectoires/<profil>.md` : bilan, semaine par semaine, décisions du moteur et leurs raisons), précédé du programme de départ en export concis. Les relecteurs jugent alors les décisions du moteur d'évolution (progression, réaction aux séances manquées ou trop dures, allègements, affûtage réel) avec la même grille.

## Dérive du panel

Les modèles changent. Avant sa première boucle, chaque lot renote deux ancres publiques de `docs/etalonnage/` (une variante (a), une variante (c)) par école (un appel par école) et vérifie : (a) ≤ 2, (c) ≥ 8. Sinon : arrêt, notification « décision requise — dérive du panel », aucune modification des grilles.

## Relecture du propriétaire

Page « Relecture Kalis Track » : lien dans `pipeline/cp/ETAT_CP.md` (ligne « Page de relecture ») et ci-dessous.

- Lien : https://claude.ai/artifact/48CYFBy75Xykohm674vLNq (privée : seul le propriétaire l'ouvre ; les lots la lisent et la republient avec l'outil Artifact et cette URL).
- Manche 0 (« moteurs 0.1, 03/10/2026 ») : dix programmes de `kalis_plan` 0.1.0 — street 01, 03, 05, 06, 07, 08, 09, 10 (du débutant complet à l'élite) et autres 02 (hypertrophie), 05 (course, 10 km).
- Collection `notes` de la base partagée de la page : un document par note ou commentaire, `{manche, profil, critere, note, commentaire, date}`, d'identifiant `m<manche>_<profil>_<critere>`. `critere` vaut `ensemble`, `adapte_au_profil`, `progression`, `volume_intensite`, `choix_exercices`, `faisable_sur` (note de 1 à 10, `commentaire` vide), `commentaire` (commentaire libre du programme, `note` nulle) ou `seance_S<semaine>_<jour>` (commentaire d'une séance, `note` nulle).
- **Lire les notes** (début de chaque lot moteur) : outil ArtifactData, action `list` (ou `query`) sur la collection `notes` avec l'URL de la page ; lire toutes les notes et tous les commentaires, de toutes les manches ; traiter chaque commentaire (corrigé, ou expliqué dans la livraison).
- **Ajouter une manche** (lots qui republient la page) : créer `manches/<id>.json` avec `tool/relecture/build_manche.py` à partir des exports JSON du banc, ajouter son entrée à `manches/index.json` (`{id, titre, sous_titre, fichier}` ; la dernière entrée est celle qui s'ouvre), puis republier `tool/relecture/relecture-kalis-track.html` à la même URL avec ces fichiers, sans retirer les manches précédentes ni toucher à la collection `notes` (ne pas repasser `capabilities` : la déclaration `db` est conservée). Aucun extrait ni nom de programme de référence sur la page.
