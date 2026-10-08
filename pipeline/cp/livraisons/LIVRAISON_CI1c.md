# Livraison CI1c — Koach appliqué, séance à jour (dev6.9.2)

Lot CI1c du pipeline « Calibrage des programmes », voie App (tâche « Opus 5.5, effort élevé, application »), lancé le 08/10/2026 vers 13:05 UTC (DECISIONS_CP.md C10 ; LANCEMENTS.md, section CI1c). Demande du propriétaire du 08/10. Validation : conversation de pilotage (C8.1).

- **Version** : dev6.9.2 (`pubspec.yaml` 6.9.2+110).
- **main** : 770589ce — « Kalis Track dev6.9.2 (CI1c) : Koach appliqué, séance à jour ».
- **Build signé** : run 37796970346 (APK de développement + AAB).
- **Contrôle complet** : `claude/ci-3d`, run 37792900255 (essai 2 ; l'essai 1, run 37788556859, avait les mêmes résultats de code mais deux tests de version encore à 6.9.1 et un arbre sans `android/gradlew` ; arbre contrôlé d361353d identique à main) (formatage, analyse, suite Dart complète, mode dev, Python, paquets, émulateur CI1c a et b puis CI1 a et b).
- **Paquets** : inchangés (`kalis_core` 0.4.2, `kalis_plan` / `kalis_adapt` 0.2.2, `kalis_koach` 0.1.0). Aucune décision C10.1 n'a fait entrer 0.2.3 : `etiquettes/kalis_*-v0.2.3` n'existaient pas au lancement ; rien n'est touché dans `packages/`.
- Mise au point : `claude/ci-ci1c-rapide` (reproduction run 37783043662, puis runs 37784682980 et 37787601415).

## 1. Cause de chaque défaut

**Reproduction d'abord** (run rapide 37783043662, code de main 64e286b, nouveaux tests) : trois échecs, exactement les deux défauts du propriétaire — programme de 40 semaines : séance S12·J1 ouverte, proposition acceptée, séance rouverte → 5 séries au lieu de 6 ; programme street créé : 2 séries au lieu de 3 ; séance future ouverte puis fermée → entrée `S12-J3` créée dans le journal.

### Défaut 1 — un ajustement de Koach accepté ne change pas le programme

1. **La séance déjà ouverte ne relisait jamais le bloc.** `adaptOpen` (`lib/session_adapt_store.dart`) gardait telle quelle une séance prescrite le jour même (« prescription du jour : gardée telle quelle »). Accepter une proposition change bien le bloc servi au moteur (couche G10), mais une séance ouverte plus tôt dans la journée — même seulement pour voir — restait sur l'ancienne prescription jusqu'au lendemain ou jusqu'à « Supprimer l'historique ». Vrai pour le programme créé comme pour le programme importé.
2. **Programme importé (40 semaines) : par construction, rien ne se voyait hors de la séance.** G10 posait les propositions acceptées sur le bloc servi au moteur seulement (« le programme affiché ne change pas ; la séance servie, si ») : accueil et MON PROGRAMME montraient toujours l'original.
3. **Programme importé : retrait et échange mal servis.** `adaptDay` comparait la séance servie au bloc *ajusté* : un exercice retiré par Koach restait dans la séance (avec la prescription d'origine), un exercice remplacé gardait l'ancien nom.
4. Les autres chemins (« Comment tu te sens ? » / ajustement du bilan, conseils entre les séries, fin de bloc du programme créé) s'appliquaient déjà à la séance en cours ; ils étaient touchés par la cause 1 seulement à la réouverture.

**Correction.**
- `adaptOpen` : une séance **non commencée** est prescrite à nouveau à chaque ouverture, d'après l'état courant (bloc avec les ajustements en place, journal, profil, réglages) ; le bilan du jour, le lieu et la suite donnée à l'ajustement du bilan sont gardés s'ils ont été donnés le jour même. Une séance **commencée** garde ses séries validées ; si la journée du bloc a changé depuis la prescription (empreinte `src` de la journée, champ facultatif de `SessionLog.adapt`), les exercices pas encore commencés suivent la nouvelle prescription, les exercices commencés gardent la leur et leurs conseils (plan fusionné validé, sinon séance gardée).
- **Couche d'ajustements sur le programme importé** (C10.2) : `syncImportedOverlay` pose, à la lecture, une journée qui porte l'ajustement (`DayPlan.overlay`, exercices `Exercise.koach` : séries, répétitions, charge, repos, exercice remplacé ; retiré ; ajouté) par-dessus la journée d'origine, qui reste en dessous (`DayPlan.original`). Le bloc importé est toujours construit depuis l'original : rien n'est régénéré ni réécrit, rien n'entre dans la sauvegarde ; « Annuler » (Évolution) retire la couche et rend l'original. Chaque exercice ajusté dit ce qui a changé, par qui et quand : « Koach : Ajouter 1 série à … (accepté le 28/09, annulable dans Évolution). ». Les séances déjà faites ne sont jamais réécrites. Accueil, MON PROGRAMME, séance et séances suivantes lisent la même journée.
- `adaptDay` : l'exercice servi est comparé au programme affiché (échange accepté sous son nouveau nom, retrait absent de la séance).
- **Propositions pour un bloc importé** : relevé sur le journal type du propriétaire (11 semaines, S12, déblocage « séance ») : la revue réelle de `kalis_adapt` n'y fait aucune proposition aujourd'hui (aucune retenue non plus). Toute proposition du moteur porte soit un diff de prescriptions (volume, allègement, étape de figure), soit un bloc restructuré par `kalis_plan` (séance, bloc, échange, zone épargnée) : les deux s'appliquent comme couche. Garde ajoutée : une proposition qui ne change rien au bloc importé, ou qui ne peut pas se montrer jour pour jour (journées déplacées, emplacement sans exercice du programme), n'est plus proposée comme applicable ; Évolution l'écrit en clair (« J'ai repéré un changement possible (…), mais il ne peut pas s'appliquer à ton programme importé jour pour jour : ton programme reste tel quel. »), sans bouton « Accepter ».
- Refuser ou laisser sans réponse : rien ne change (testé).

### Défaut 2 — séance figée après une première ouverture

**Cause.** Ouvrir une séance l'écrivait au journal : la prescription du moteur (figée pour la journée, cause 1 ci-dessus), et les séries préparées par exercice (nombre et valeurs pré-remplies) dès l'affichage de l'exercice. À la réouverture, les séries existantes n'étaient jamais refaites (le pré-remplissage ne remplit que les cases vides), et l'entrée restait au journal comme une séance « à moitié » ; seul « Supprimer l'historique » la remettait à jour.

**Correction.**
- À l'ouverture d'une séance non commencée : séries pré-remplies refaites d'après la séance du moment (`refreshUnstartedSession`), puis prescription du moteur refaite (ci-dessus). Une valeur **saisie** par l'utilisateur sans être validée est marquée (`SetEntry.edited`, champ facultatif) et gardée telle quelle ; notes et réglages d'affichage restent.
- À la fermeture, une séance **seulement consultée** (rien de validé, aucune saisie, aucune note, aucun bilan donné, aucune décision de l'ancien Koach) est retirée du journal (`forgetConsultation`) : une consultation ne crée plus d'entrée d'historique.
- **Migration** (au chargement et à la restauration d'une sauvegarde) : dans les séances pas commencées des versions ≤ 6.9.1, toute valeur qui n'est pas celle que la séance servie pré-remplissait (ou toute valeur hors moteur) est marquée comme saisie (`_markLegacyDrafts`) ; puis les séances seulement consultées sont retirées (`_pruneConsultations`). Séances faites, séries validées, notes, bilans, saisies : rien n'est perdu (testé sur une sauvegarde au format 6.9.1).

## 2. À tester (téléphone du propriétaire, programme de 40 semaines)

1. **Accepter un ajustement de Koach** : Réglages › Mon programme › Évolution (ou la carte de Koach à l'accueil) — mode libre, « Accepter » sur une proposition. Ouvre la séance concernée : le changement y est (séries, charge, exercice remplacé ou retiré) ; l'accueil et Mon programme le montrent aussi, avec « Koach : … (accepté le …) ». « Annuler » dans Évolution rend l'original. *Si Koach n'a encore rien proposé sur ton journal, ce test attend sa première proposition ; en attendant, le test 2 vérifie la mise à jour de la séance.*
2. **Séance de demain** : ouvre-la pour voir ce qui est prévu, ferme-la ; change quelque chose (accepte un ajustement, ou change une référence dans Pilotage, ou le mode assisté / libre), rouvre-la : elle est à jour, sans rien effacer. Elle n'apparaît pas comme commencée.
3. **Séance commencée** : valide une série, ferme, rouvre : la série validée est là.

## 3. Contrôles

| Contrôle | Résultat |
| --- | --- |
| Reproduction (tests CI1c sur le code de main) | 3 échecs attendus (run rapide 37783043662) |
| Formatage, analyse (dont tests d'intégration) | vert |
| Suite Dart complète (771 tests) et mode dev | vert (run rapide 37787601415 ; contrôle complet 37792900255) |
| `test/ci1c_koach_applique_test.dart` : programme importé (accepter → séance déjà ouverte, séance servie et programme affiché à jour ; refuser → rien ; annuler → original) ; échange et retrait acceptés (affichés, servis, semaines suivantes, original intact, annulation) ; programme street créé (séance déjà ouverte à jour, programme affiché) ; séance future ouverte, ajustement et bilan, rouverte à jour, nouvelle prescription le jour venu ; séance commencée (séries validées gardées, reste à jour) ; consultation sans entrée, bilan / note / saisie gardés ; sauvegarde 6.9.1 (consultation figée retirée, note, bilan, brouillon saisi et séances faites intacts, saisie gardée à la réouverture) ; widget : fermer une séance future sans entrée, bilan répondu gardé et relu | vert |
| `test/g9_seance_test.dart` : l'attente « séance prescrite figée après relance » remplacée (C10) : après relance, aucune entrée ; rouverte, prescription identique | vert |
| Émulateur CI1c a (sombre, rouge) et b (clair, violet) : session perso (programme importé, mode libre) — réorganisation acceptée, accueil / liste des exercices / séance à jour, original intact, séance du lendemain consultée sans entrée ; session de test — programme street, séance de demain ouverte à l'avance, série de plus acceptée, rouverte à jour ; session perso intacte | vert (relevés `ci1c_releve_a.json`, `ci1c_releve_b.json` : jour S2·J4 du programme importé, 5 → 4 exercices à l'accueil, « Traction pronation » à la place de l'exercice remplacé dans la liste de la séance, original intact, retiré et remplacé aussi dans la séance servie, séance du lendemain consultée sans entrée ; session de test S1·J2 : 2 → 3 séries après acceptation, séance rouverte à jour avec la carte « Ce qui change dans cette séance : ajouter 1 série à Suspension active », sans entrée après la consultation ; session personnelle intacte). Captures `ci1c_01` à `ci1c_08`, sombre et clair, relues (la capture d'Évolution montre le haut de l'écran, pas l'historique) |
| Émulateur CI1 a et b (non-régression street, douleur) | vert (inchangé) |
| Paquets | inchangés, vert |
| Build signé APK + AAB | vert (run 37796970346) |
| Rendus de test « captures » (`visual_capture_test.dart`) | en échec depuis avant CU (comme CI1, CI1b) : hors de ce lot |

Relecture indépendante du code (sous-agent Opus) : 10 constats, corrigés avant livraison : brouillons saisis effacés à la fermeture ou à la réouverture (drapeau `edited`, migration des saisies 6.9.1) ; clé de la couche sur l'identité d'un enregistrement (non garantie en AOT : clé sur le bloc) ; une proposition ancienne non jour pour jour masquait toute la couche (couche par journée) ; plan fusionné d'une séance commencée non validé (validé, sinon séance gardée) ; règle d'échange (ancienne règle gardée en plus) ; caches tirés des exercices du programme (révision `programRevision`) ; raison prise par emplacement ; séances faites jamais réécrites ; carte « non applicable » rafraîchie. Reste : pas de sauvegarde 6.9.1 réelle versionnée (sauvegarde reconstruite au format 6.9.1 dans le test).

## 4. Limites et reste à faire

- Sur le journal type du propriétaire, la revue réelle ne fait aucune proposition aujourd'hui : l'acceptation est testée avec des propositions construites (volume, réorganisation de séance) et la restructuration réelle de `kalis_plan` n'a pas été rejouée sur le bloc importé. Le test 1 de « À tester » dépend de la première vraie proposition.
- Un emplacement **ajouté** par une restructuration n'est montré dans le programme importé que s'il porte un exercice du programme (« j<J>-<id> ») ; sinon la proposition n'est plus proposée (garde ci-dessus). Les propositions déjà en place d'avant CI1c qui ne se montrent pas jour pour jour restent servies au moteur ; leurs journées non montrables gardent l'original affiché (aucune n'existe sur les fixtures).
- Une valeur pré-remplie par 6.9.1 hors moteur (charges du programme) est gardée comme une saisie à la migration (prudence : on ne peut pas la distinguer d'une saisie) ; elle ne suit donc pas un changement de référence tant que la séance n'est pas faite ou effacée.
- Les paquets 0.2.3 (CP2, CA2) entreront par CI1d (C10.1).

## 5. Recommandation (C8, le pilotage décide)

Valider dev6.9.2 et la donner au propriétaire à la place de dev6.9.1 : elle corrige les deux défauts demandés sans toucher aux moteurs ni au programme de 40 semaines (couche annulable par-dessus l'original). Puis CI1d dès que 0.2.3 a passé le contrôle C9.8.

Détail des décisions : `pipeline/cp/DECISIONS_CP.md`, section CI1c.
