# Livraison CI1g — paquets 0.3.1 de CY dans l'application (dev6.11.1)

Lot CI1g du pipeline « Calibrage des programmes », voie App (tâche « Opus 5.5, effort élevé, application »), lancé le 09/10/2026 vers 13:40 UTC (message sans ligne « Lot : » : seul lot de la voie App « à faire » ; DECISIONS_CP.md C11.7, C11.8 ; LANCEMENTS.md, section CI1g). Mise à jour courte, comme CI1d. Validation : conversation de pilotage (C8.1).

- **Version** : dev6.11.1 (`pubspec.yaml` 6.11.1+114).
- **main** : b7996b3f — « Kalis Track dev6.11.1 (CI1g) : paquets 0.3.1, avis médical avant la première séance » (parent 9dd09214, arbre 79bbe549).
- **Build signé** : run 37955793332 (APK de développement + AAB), vert.
- **Contrôle complet** : `claude/ci-3d`, run 37946602412 (essai 2 vert ; essai 1 : tout vert sauf `m8_carte_2d_test.dart`, voir plus bas) (arbre 79bbe549 identique au commit de main).
- **Paquets** : `kalis_plan` 0.3.1 (`etiquettes/kalis_plan-v0.3.1`) et `kalis_adapt` 0.3.1 (`etiquettes/kalis_adapt-v0.3.1`), copie complète des dossiers, identiques octet pour octet (`git diff` contre les étiquettes : vide). `kalis_core` 0.4.3 inchangé (identique à son étiquette, c'est celle que demandent les deux paquets), `kalis_koach` 0.1.0 inchangé, `kalis_bench` absent. `pubspec.lock` : deux versions de chemin.
- Accès : `add_repo` absent de la session ; push vérifié par `git push --dry-run origin pipeline` puis par le push de la ligne « en cours ». Push sur `main` : accepté (avance rapide 9dd09214 → b7996b3f).
- Mise au point : `claude/ci-ci1g-rapide` (runs 37939731134, 37944901032, puis tests du lot seuls, vert).

## 1. Ce qui change pour l'utilisateur depuis dev6.11.0

**Points imposés par CY (INTEGRATION_CI.md des deux paquets, § 5)** :

1. **Avis médical avant la première séance** (`clearance_first`, écrite par `kalis_plan` 0.3.1 quand le questionnaire de santé est « prudent » ou qu'une gêne est déclarée à 5/10 ou plus). À l'ouverture d'une séance pas commencée d'un bloc qui porte la note, une étape **bloquante** (la touche retour ne la ferme pas) : « Avis médical d'abord », texte rédigé par `kalis_plan` (« Gêne déclarée à 6/10 : avant la première semaine, prends l'avis d'un médecin ou d'un kinésithérapeute… »), puis « J'ai eu l'avis d'un médecin ou d'un kiné » ou « Pas encore ».
   - « J'ai eu l'avis » : gardé pour ce bloc (réglages, `medicalClearance`, clé « bloc#valeur de la note », date ; dans la sauvegarde exportée, absent tant que vide : export identique à 6.11.0 sinon).
   - « Pas encore » : la séance s'ouvre avec une carte en tête de la page du bilan, avec le bouclier (« Avis médical pas encore confirmé », le texte de la note, « En attendant l'avis, fais seulement les mouvements qui ne réveillent pas la douleur, sans forcer ; arrête un mouvement qui fait mal. », bouton « J'ai eu l'avis »), et la même consigne sous chaque exercice (une séance reprise saute la page du bilan). L'étape revient à la séance suivante (pas dans la même séance avant un nouveau lancement).
   - Choix (les paquets ne le disent pas) : confirmation **une fois par bloc** tant que la condition tient (la note est réécrite à chaque bloc) ; un bloc réécrit pour une gêne plus forte redemande (la valeur fait partie de la clé). Une séance commencée ne bloque jamais.
2. **Pompe sur barre basse pour le poignet** : quand `kalis_adapt` 0.3.1 remplace une poussée par `sw-pompe-inclinee` avec `adapt.pain_reported` zone poignet (première gêne, ou douleur du jour), la séance affiche sous l'exercice, avec le bouclier, « Mains serrées sur la barre basse, poignets droits. » ; le résumé de l'ajustement dit « Remplacement : Pompes → Pompe inclinée (mains surélevées) (gêne du poignet) : mains serrées sur la barre basse, poignets droits. » ; vers un autre appui neutre : « (gêne du poignet : appui neutre, poignets droits) ».
3. **`shoulder_history`** sous chaque développé au-dessus de la tête d'une épaule à antécédent : texte de `kalis_plan`, en tête des notes avec le bouclier (avec `clearance_first` et `knee_shallow`, choix de l'application d'après INTEGRATION_CI.md § 3.2). Vérifié sur un profil de musculation (épaule à 2, 3 et 6/10) : chaque développé écrit porte la note.
4. **Textes** : les 108 notes de `CoachNotes.all` rédigées pour toutes les valeurs testées, sans code brut ni gabarit (test) ; aucun code de raison nouveau en 0.3.1 ; la cause `cap` de `adapt.load_held` (borne à schéma changé, palier de hausse) a maintenant un texte : « Charge plafonnée : la hausse reste mesurée, pour rester sûre. » (avant : « Charge gardée cette fois. »).

**Moteurs (sans écran nouveau)** : première gêne du poignet → appui neutre tout de suite ; pas de test maximal sur une articulation douloureuse ; jour de test de tirage sans travail de tirage ensuite ; premier muscle-up testé sur une répétition ; course retirée sous une douleur du bas du corps qui dure puis reprise à 50 % ; « 2 pour 2 » à 10 % au plus ; couloir à 85 % ; borne à schéma changé ; repère de jour bas. Règles de séance appliquées dès la mise à jour ; notes de programme au prochain bloc écrit.

**C11 — programme de 40 semaines** : il reste sous toutes les fonctionnalités. Ses blocs annotés (CI1e) font six semaines au plus (vérifié par test) : `KalisAdapt(restructureImported: true)` est **sans objet** (défaut gardé pour tous). Aucune étape d'avis médical sur lui (pas de note `clearance_first` : c'est `kalis_plan` qui l'écrit, pour les blocs qu'il écrit). CI1c à CI1f intacts (suites et cibles émulateur vertes).

## 2. À tester (pilotage, puis propriétaire)

1. **Session perso** : séance du jour comme en dev6.11.0, sans étape d'avis médical (myo-reps, enchaînements, Koach appliqué).
2. **Session de test** (5 appuis sur le logo) : profil avec une gêne déclarée à 5/10 ou plus (consentement santé donné), créer le programme, ouvrir la première séance → « Avis médical d'abord » ; « Pas encore » → carte en tête et consigne sous chaque exercice ; « J'ai eu l'avis » → plus rien, même en rouvrant.
3. Optionnel : poignet signalé à 3/10 au bilan sur un programme street avec pompes et `barre basse` au matériel → pompe inclinée avec la consigne « mains serrées sur la barre basse ».

## 3. Contrôles

| Contrôle | Résultat |
| --- | --- |
| Paquets identiques aux étiquettes (`git diff`) | oui |
| `test/ci1g_paquets_test.dart` : versions 0.3.1, défaut `restructureImported` ; toutes les notes rédigées ; bouclier ; consigne de la pompe ; `cap` ; `clearance_first` (note du bloc, confirmation par bloc, sauvegarde exportée puis relue) ; sans gêne aucune étape ; `shoulder_history` sous les développés ; écran : étape bloquante (retour sans effet), « Pas encore » → carte et consigne, réouverture sans étape, « J'ai eu l'avis » → plus rien (sombre et clair) ; programme de 40 semaines en blocs de 6 semaines au plus, sans étape | vert |
| Suites CI1c, CI1d, CI1e, CI1f, G9 | vertes |
| Contrôle complet `claude/ci-3d` (formatage, analyse, suite Dart, mode dev, Python, paquets, émulateur CI1g a/b puis CI1f, CI1e, CI1c, CI1 et les cibles précédentes) | vert (run 37946602412, essai 2 : 806 tests, mode dev, paquets, émulateur ; codes de toutes les cibles à 0) |
| Émulateur CI1g (a sombre rouge, b clair violet) : session perso sans étape ; session de test, gêne de l'épaule à 6/10 : étape, « Pas encore » → rappel, « J'ai eu l'avis » → plus rien ; session de test supprimée, session perso intacte clé par clé | vert (relevés `ci1g_releve_a/b.json` tous vrais ; captures relues) |
| Build signé APK + AAB | vert (run 37955793332, main b7996b3f) |
| Rendus de test « captures » (`visual_capture_test.dart`) | en échec depuis avant CU (comme CI1 à CI1f) : hors de ce lot |

`m8_carte_2d_test.dart` (étiquettes, toucher, légende) : dépassement de délai de 10 min dans la suite complète au premier essai (chargement d'image sous `runAsync`), vert seul ; même échec intermittent sur les essais 3 et 4 de CI1f, vert à l'essai 5 sans changement de ces fichiers. Relancé une fois : vert à l'essai 2 (806 tests, aucun échec).

Relecture indépendante du code (sous-agent Opus) : 9 constats, traités : valeurs de la note `cue` (1 à 12) dans le test ; assertion sur `shoulder_history` (profil de musculation) ; consigne aussi sous chaque exercice (séance reprise) ; clé du « Pas encore » liée à la note (session de test et session perso séparées) ; clé de confirmation « bloc#valeur » (gêne plus forte → redemandée) ; en-tête de fichier ; paramètre inutilisé. Vérifié sans changement : aucun profil des tests existants n'a `clearance_first` (consentement refusé ou gênes ≤ 4/10).

## 4. Limites et reste à faire

- La carte « Pas encore » répète « En attendant… » quand le texte de la note (gêne ≥ 5/10) le dit déjà : cosmétique, à resserrer au lot CI.
- L'étape ne retire aucun mouvement : les paquets ne disent pas lesquels « réveillent la douleur » ; la règle de douleur du moteur (bilan, zones) reste celle qui retire ou remplace.
- Points « non déterminés » des notes d'intégration non traités ici (lot CI) : résultat d'un contre-la-montre à écrire au profil, jour J d'une course, pompe inclinée écrite par le bloc (consigne non déclenchée), test de course borné.
- Les limites de CI1 à CI1f restent (règle CI1.4 du débutant, plage d'un myo-rep, techniques à mini-séries à partir d'« avancé »).

## 5. Recommandation (C8, le pilotage décide)

Valider dev6.11.1 et la donner au propriétaire à la place de dev6.11.0 : couple 0.3.1 × 0.3.1 validé par C11.7, points de sécurité de CY visibles (avis médical avant la première séance, consigne du poignet, épaule), programme de 40 semaines inchangé dans ses fonctionnalités. Suite : lot CI final (limites restantes de CI1 à CI1g).

Détail des décisions : `pipeline/cp/DECISIONS_CP.md`, section CI1g.
