# Livraison G10 — Évolution du programme : propositions de Koach, modes, outils dev, retrait L7 / L11

- **Version** : dev6.7.0 (pubspec 6.7.0+106 ; AAB « 6.7.0 »)
- **Commit main** : 9f6b80b · **Build signé** : run 37048733703
- **Contrôles** : CI `claude/ci-3d` run 37041779562 (émulateur partie a au 2e essai : pilote perdu avant le test) — formatage, analyse (0 remarque), 722 tests Dart, tests du mode dev, tests Python, `verify_project.py`, `package_release.py --check`, `check_release_without_secrets.py --tree`, paquets (kalis_core, kalis_plan, kalis_adapt, kalis_koach), émulateur G10 a (sombre, rouge, assisté) + b (clair, violet, libre). Rendus `visual_capture` : échec déjà présent sur main.
- **Moteurs** : `kalis_adapt` 0.1.0, `kalis_plan` 0.1.0, `kalis_core` 0.3.0, inchangés.

## Ce qui change

1. **Propositions de Koach** (revue de `kalis_adapt` après chaque séance et à l'ouverture de l'accueil) : volume (± 1 série d'un groupe), échange d'exercice, restructuration d'une séance ou du bloc, décharge anticipée. Une carte sur l'accueil et, la semaine où le changement commence, au début de la séance concernée (« Ce qui change dans cette séance : … ») ; Koach dans une pose, une phrase courte (« Je te propose d'ajouter une série de tirage à partir de la semaine prochaine. »), « Pourquoi ? » (les raisons du moteur en clair) et « Voir le changement » (aperçu du diff comme en G7 : séries, exercice remplacé, journée déplacée…).
2. **Mode assisté** : le changement est appliqué tout de suite, Koach l'annonce ; « Annuler » reste possible jusqu'au début de la semaine concernée. **Mode libre** : « Accepter » / « Refuser » / « Plus tard » (revient le lendemain). Un refus ou une annulation est transmis au moteur, qui ne repropose pas la même chose pendant 28 jours.
3. **Réglages › Mon programme › Évolution** : bascule Assisté / Libre, ce que Koach peut déjà changer et quand le reste se débloque (D5.7 : charges et répétitions dès le début, volume après 2 semaines, échanges après 4, séances après un bloc, bloc après deux), propositions en attente, **historique** des changements (appliqués, acceptés, refusés, annulés) avec leurs raisons ; un appui ouvre le diff.
4. **Fin de bloc** : « Bloc suivant » utilise `nextBlock` avec le résumé d'adaptation de `kalis_adapt` et les décisions de l'historique ; la revue de G7 ne porte que sur les **nouveaux** exercices (les exercices connus restent fixés).
5. **Outils de test** (session de test, build de développement) : simulateur de séances (8 athlètes simulés de `kalis_adapt`, 1 à 12 semaines, graine, option « Tout accepter » ; l'horloge de la session de test avance, flammes simulées), inspecteur du moteur (état, déblocage, forme, séance du jour, charges, propositions de la dernière revue), export du journal du moteur en JSON.
6. **Retrait de L7, L11 et du reste de L10** : Koach L7 (moteur, programme, écrans, carte du jour), adaptation au quotidien L11 (échange à la volée, difficulté globale, pause), écran « bloc suivant » L10. Les décisions passées restent dans la sauvegarde, en lecture seule (section `adapt` gardée telle quelle, réglage « Ancien Koach » pour supprimer les anciennes réponses).
7. **Repères des flammes** (demande du propriétaire, correction 3 de G9) : sous la ligne des flammes, « 1 · léger » et « échec · 10 », tirés des mots des flammes.

## Correspondance des anciennes fonctions

| Ancienne fonction | Devient |
|---|---|
| Vacances / maladie (L11, pause) | Retrait assumé : le moteur voit les trous du journal (reprise après une coupure, `resume_after_break`) ; « Où j'en suis » recale le programme |
| Reprise après un arrêt (L11) | `kalis_adapt` (charges de reprise, raison « reprise ») |
| Séance compressée (L11) | « J'ai seulement… minutes » → temps disponible du bilan (G9) |
| Changement de lieu (L11) | « Je m'entraîne ailleurs » → lieu du jour du moteur (G9) |
| Plan qui glisse (L10) | « Où j'en suis » (G8) |
| Assiduité (L11) | Restructuration du bloc (`block_restructure`, raison séances manquées) |
| Plateau (L7 / L11) | Échange d'exercice (`exercise_swap`, raison plateau) |
| Prudence / douleur (L7 / L13) | Épargne de la zone (`pain_sparing`) + règle L13 (G9) |
| Échange à la volée (L11) | Retrait assumé : les échanges viennent du moteur (propositions) |
| Difficulté globale de la séance (L11) | Flammes à chaque série (G9) |
| Autorégulation des charges L7 | `kalis_adapt` (G9) |
| Questionnaires Koach L7 | Bilan santé (G9) |
| Pesées L7 | Profil + B4 (changer le poids de corps dans les Références ajoute une pesée quand il en existe déjà) |
| Écran Koach / objectifs L7 | Inspecteur du moteur (dev) ; écran Koach d'objectifs en G12 |
| Structure L7 (± 1 série, décharge) | Propositions de volume et de décharge |

## Tests

Ajoutés : `test/g10_evolution_test.dart` (modèle et sauvegarde de l'évolution, chaque type de proposition dans les deux modes — volume, décharge, échange, épargne douleur, séance, bloc —, annulation, refus et son délai, « Plus tard », fin de bloc, simulateur déterministe, déblocage, écrans), `test/g10_mode_dev_test.dart` (simulateur dans la session de test, inspecteur, export), `test/g10_seance_sans_moteur_test.dart` (séance hors moteur sans L7, repères des flammes), `tools/tests/test_koach_annotations.py`, `integration_test/evolution_g10_test.dart` (simulation dans la session de test, 10 captures × 2 thèmes). Renommé : `l7_koach_off_test` → `g10_charges_consigne_test`. **Retirés avec le code retiré** : `l7_koach_engine_test`, `l7_koach_screens_test`, `l7_koach_simulation_test`, `l7_koach_store_test`, `l11_adapt_test`, `l11_screens_test`, `l11_store_test`, `m56_koach_day_card_test`, `test/support/l10_support.dart`, `test/fixtures/koach/` (26 fichiers), `tools/tests/test_koach_reference.py` (et `tools/koach_reference.py`, `tools/koach_simulation.py`). Modifiés : `g6_profil_test`, `l13_*`, `l10_store_test`, `g5_koach_test`, versions affichées.

## À tester par le propriétaire

- **Mode dev** (5 appuis sur le logo) : Réglages › Mon programme › « Simulateur de séances », athlète « Calisthénie au parc », 8 semaines → une carte de Koach sur l'accueil ; « Pourquoi ? », « Voir le changement » ; l'historique dans Évolution ; l'inspecteur et l'export du journal.
- **Ton programme** : Réglages › Mon programme › Évolution — choisis ton mode ; les premières propositions ne viendront qu'après quelques semaines de vraies séances notées.
- **Fin de bloc** : « Bloc suivant » ne te fait revoir que les nouveaux exercices.

## Limites

- Le moteur propose peu : dans les simulations de 8 semaines, quelques propositions de volume, surtout dans le 2e bloc (seuils de confiance de `kalis_adapt`). L'émulateur part donc d'une date fixe (1er octobre 2026) pour une simulation reproductible.
- Le simulateur suit la prescription du jour sans le conseil série par série (temps de calcul sur téléphone).
- Une séance commencée avant la mise à jour avec un exercice échangé par L11 se rouvre avec l'exercice du programme.
- Les anciennes pauses (L11) ne suspendent plus les rappels.
- Contenu sportif non relu par un professionnel diplômé (registre de `kalis_adapt`).
