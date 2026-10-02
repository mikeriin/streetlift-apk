# Livraison G9 correction 2 — Flamme du curseur posée sur sa base, toutes les séries résumées

- **Version** : dev6.6.2 (pubspec 6.6.2+104 ; AAB « 6.6.2 »)
- **Commit main** : 97a8705 · **Build signé** : run 37012282440
- **Contrôles** : CI `claude/ci-3d` run 37010059604 — formatage, analyse, 859 tests Dart, 16 tests du mode dev, tests Python, paquets, émulateur G9 a (sombre, rouge) + b (clair, violet). Rendus `visual_capture` : échec déjà présent sur main.
- **Corrections du propriétaire** (02/10/2026) : « Pour le slider, la flamme doit être un peu plus haute, le centre n'est pas au centre du sprite mais au centre de la base de la flamme » ; « Résumer aussi les exercices qui n'ont pas de flammes comme les autres ».

## Ce qui change

1. **Flamme du curseur posée sur sa base** : sur la ligne des flammes, le point d'ancrage de la flamme est le centre de sa base arrondie (demi-largeur au-dessus du bas du dessin), posé sur la ligne ; la flamme s'élève au-dessus de sa position et l'agrandissement de la transition part de ce point (`FlameIcon(onBase: true)`). Lignes résumées inchangées (flamme centrée sur le texte).
2. **Exercices sans flammes résumés comme les autres** (échauffement, mobilité, durées, EMOM…) : la dernière série validée reste ouverte, les précédentes passent en une ligne, toutes en relecture (« 12 min », « 30 s », « 8 reps », sans colonne de flamme). Exercice d'archive inconnu du programme : valeurs telles quelles, sans unité inventée (« 17 · 0.42 »).

## Tests

`test/g9_seance_test.dart` : flamme de la ligne posée sur sa base ; texte des lignes résumées pour chaque type de saisie (reps, tenue, durée, archive). Adaptés à la relecture en une ligne : `lc1_programme_test`, `programme_test`, `stats_test`, `history_readonly_test`.

## À tester par le propriétaire

La ligne des flammes : la flamme repose sur la ligne par sa base. Un échauffement ou une mobilité : séries résumées comme les exercices notés ; l'historique d'une séance : toutes les séries en une ligne.

## Limites

- Contenu sportif non relu par un professionnel diplômé.
