# Livraison CI1d — paquets 0.2.3 dans l'application (dev6.9.3)

Lot CI1d du pipeline « Calibrage des programmes », voie App (tâche « Opus 5.5, effort élevé, application »), lancé le 08/10/2026 vers 23:40 UTC (DECISIONS_CP.md C10.6, C10.7 ; LANCEMENTS.md, section CI1d). Mise à jour courte, comme CI1b. Validation : conversation de pilotage (C8.1).

- **Version** : dev6.9.3 (`pubspec.yaml` 6.9.3+111).
- **main** : bd1f0c97 — « Kalis Track dev6.9.3 (CI1d) : paquets 0.2.3 ».
- **Build signé** : run 37866362064 (APK de développement + AAB).
- **Contrôle complet** : `claude/ci-3d`, run 37863940096 (arbre 6f5a1871 identique à main : formatage, analyse, suite Dart complète, mode dev, Python, paquets, émulateur CI1c a et b puis CI1 a et b).
- **Paquets** : `kalis_plan` 0.2.3 (`etiquettes/kalis_plan-v0.2.3`, 9b2e9ea3) et `kalis_adapt` 0.2.3 (`etiquettes/kalis_adapt-v0.2.3`, ff22faa9), copie complète des dossiers, identiques octet pour octet (vérifié par `git diff` contre les étiquettes). `kalis_core` reste en 0.4.2 : c'est la version que portent les deux étiquettes (0.4.3 n'est demandé que par `kalis_adapt` 0.3.0, non pris). `kalis_koach` 0.1.0 inchangé, `kalis_bench` absent, pas les 0.3.0. `pubspec.lock` : deux versions de chemin. Le commit 9b2e9ea3 de `moteurs` réunit déjà les trois (contrôle `claude/ci-cp-a` 37820965364 vert).
- Mise au point : `claude/ci-ci1d-rapide` (suite Dart complète avec 0.2.3 avant tout changement de l'application : 771 tests verts, run 37860966524 ; puis runs 37861887700 à 37863643673).

## 1. Ce qui change pour l'utilisateur depuis dev6.9.2

**Programme (écrit par `kalis_plan` 0.2.3, textes rédigés par le paquet, affichés tels quels)** : bloc de reprise après une douleur qui dure sur un mouvement de l'objectif (note « Bloc de reprise… » : ni test, ni affûtage, ni épreuve, échéance repoussée ; dans la carte de la séance et dans les règles du programme, avec le bouclier) ; poignet sensible déclaré au profil (note « Poignet sensible au profil… » sous chaque figure en appui réduite de moitié, bouclier ; parallettes ou poignées d'abord) ; zone signalée sur trois séances gardée « sensible » au bloc suivant ; 1RM seulement déclaré remplacé par l'estimation quand il est nettement plus haut (15 % de baisse au plus) ; première semaine plafonnée ; consigne d'arrêt du muscle-up ; série repère (« Série repère, aujourd'hui seulement… ») ; simulation du test (« Simulation du test… ») ; repères sur le chemin de l'objectif (« Repère sur le chemin de l'objectif… ») ; tenues vers le critère de passage ; sécurités de la cage au-delà de 85 % ; hauteur des mains de la pompe inclinée. Aucun code brut : vérifié sur chaque note de chaque programme des profils street des fixtures.

**Séance (conduite sous douleur de `kalis_adapt` 0.2.3, textes de l'application)** :
- Palier de reprise : sous l'exercice, avec le bouclier, « Zone douloureuse ou en reprise : dose prudente, 3 répétitions en réserve, pas de hausse aujourd'hui. » (raison `adapt.load_held`, cause `pain_return`, aussi émise pendant l'arrêt et pour le remplaçant d'une douleur du jour).
- Tests reportés : « Test de X reporté : pas de test tant que le poignet a été signalé au-dessus de 2 sur 10 dans la semaine. » ou « … pendant la reprise après une douleur. ».
- Retrait pour une douleur du jour : « Retiré aujourd'hui : X (douleur signalée : l'épaule). ».
- Poignet à l'arrêt : « Remplacement : Pompes → Pompes sur parallettes (appui neutre : le poignet est à l'arrêt, douleur qui dure). ».
- Renvoi vers un professionnel : le moteur ne le donne plus qu'à la première séance de l'arrêt puis une fois par semaine. La carte « Arrêt pour douleur » reste en tête de la séance tous les jours où l'arrêt retire ou remplace un mouvement (lue dans les ajustements) ; la consigne « Consulte un médecin ou un kinésithérapeute » n'y figure que les jours de renvoi, les autres jours « Arrêt en cours (poignet) : douleur qui dure. » ; même règle sous l'exercice remplaçant. Arrêt gardé (deux semaines basses acquises, levée à la prochaine semaine de charge) : dit tel quel.

Le programme de 40 semaines du propriétaire n'est ni régénéré ni servi autrement : bloc importé, pas de mode coach, aucune de ces raisons (chemin 0.1 inchangé dans les deux paquets). CI1c intact : tests `ci1c_koach_applique_test.dart` et émulateur CI1c a/b verts.

## 2. À tester (pilotage, puis propriétaire)

1. **Session perso** : Mon programme et la séance du jour identiques à dev6.9.2 ; accepter / annuler un ajustement de Koach marche comme en dev6.9.2.
2. **Poignet sensible** — session de test (5 appuis sur le logo), profil calisthénie avec une figure en appui (planche, équilibre) et une gêne au poignet à 2/10 dans le profil (consentement santé donné) : sous la figure, note « Poignet sensible au profil… » avec le bouclier, séries réduites.
3. **Douleur qui dure** (comme dev6.9.1) : poignet à 4/10 à chaque séance plus de deux semaines (voyage dans le temps) → carte « Arrêt pour douleur » avec la consigne de consulter ; séance suivante de la même semaine : carte « Arrêt en cours », sans la consigne ; pompe remplacée par un appui sur parallettes s'il y en a.

## 3. Contrôles

| Contrôle | Résultat |
| --- | --- |
| Paquets identiques aux étiquettes (`git diff`) | oui |
| Suite Dart complète avec 0.2.3, sans changement de l'application | verte (771 tests, run rapide 37860966524) |
| `test/ci1d_paquets_test.dart` : versions 0.2.3 ; 11 nouvelles notes rédigées sans code brut ; bouclier pour `pain_reprise`, `wrist_spare`, `load_held`/`pain_return` (et pas pour les autres) ; textes du test reporté, du retrait, de l'échange ; carte d'arrêt avec et sans renvoi, arrêt gardé ; programmes de tous les profils street des fixtures sans code brut ; profil de figures avec gêne du poignet → `wrist_spare` servi et rédigé | vert (run rapide 37863643673) |
| `ci1b_pain_test`, `ci1c_koach_applique_test`, `ci1_street_test`, `g9_seance_test`, `g10_evolution_test` | verts |
| Contrôle complet `claude/ci-3d` (formatage, analyse, suite Dart, mode dev, Python, paquets, émulateur CI1c a/b, CI1 a/b avec l'étape « séance suivante de l'arrêt ») | vert (run 37863940096 : `checks`, `packages`, `emulator` réussis ; relevés `ci1_releve_a/b.json` : arrêt S4-J2, retirés absents de la séance servie, séance suivante S4-J5 avec la carte (jour de renvoi, la consigne y est), session perso intacte ; captures `ci1_12_douleur_suite_{sombre,clair}.png` relues) |
| Build signé APK + AAB | vert (run 37866362064, main bd1f0c97) |
| Rendus de test « captures » (`visual_capture_test.dart`) | en échec depuis avant CU (comme CI1 à CI1c) : hors de ce lot |

Relecture indépendante du code (sous-agent Opus) : 7 constats, tous traités avant le contrôle complet : note d'arrêt du bloc (avec la consigne de consulter) qui revenait chaque jour par le filtre des zones (zones lues aussi dans les ajustements) ; renvoi répété sous l'exercice remplaçant (texte court hors des jours de renvoi) ; texte du palier trop précis (raison aussi émise pendant l'arrêt : texte prudent) ; arrêt gardé (phrase propre) ; carte attendue sur émulateur seulement si l'arrêt touche la séance suivante (séance guidée exclue) ; ligne « séries » en double avec « séries de moins » ; accords (formes sans accord). Un point accepté : un jour d'arrêt où la séance ne contient aucun mouvement de la zone, la carte n'apparaît pas (rien n'est retiré) ; la note d'arrêt du bloc la remplace quand le bloc la porte.

## 4. Limites et reste à faire

- La règle de CI1 (débutant sans ancienneté présenté « moins de 6 mois » aux moteurs, CI1.4) est **gardée** : `kalis_plan` 0.2.3 accepte désormais ce débutant, mais ne fait passer un bloc 0.1 au chemin calibré que si l'ancienneté est renseignée ; la règle garde donc le choix « Passer au moteur calibré » de fin de bloc. Recommandation : la retirer au lot CI final, avec un test de migration.
- Sur émulateur, la séance suivante de l'arrêt (S4-J5) est encore un jour de renvoi pour le moteur (consigne affichée) : la carte « Arrêt en cours » sans la consigne n'est exercée que par le test Dart (`ci1d_paquets_test.dart`).
- Les limites de CI1, CI1b et CI1c restent (tentatives du jour J au journal, mini-séries, test reporté sur un profil à 5-6 séances, revue sans proposition sur le journal du propriétaire).
- Les parties 1 de CP2 et CA2 (0.3.0, autres disciplines) n'entrent pas : CY puis CI.

## 5. Recommandation (C8, le pilotage décide)

Valider dev6.9.3 et la donner au propriétaire à la place de dev6.9.2 : moteurs street 0.2.3 (contrôle C9.8 passé), conduite sous douleur lisible, sans toucher au programme de 40 semaines ni à CI1c.

Détail des décisions : `pipeline/cp/DECISIONS_CP.md`, section CI1d.
