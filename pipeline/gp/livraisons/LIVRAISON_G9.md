# Livraison G9 — Séance : bilan santé, flammes à chaque série, charges par `kalis_adapt`

- **Version** : dev6.6.0 (pubspec 6.6.0+102 ; AAB « 6.6.0 »)
- **Commit main** : 642468d · **Build signé** : run 36980042502
- **Contrôles** : CI `claude/ci-3d` run 36978010650 — formatage, analyse (0 remarque), 857 tests Dart, 16 tests du mode dev, tests Python, `verify_project.py`, `package_release.py --check`, `check_release_without_secrets.py --tree`, paquets (kalis_core, kalis_plan, kalis_adapt, kalis_koach), émulateur G9 a (sombre, rouge) + b (clair, violet). Rendus `visual_capture` : échec déjà présent sur main.
- **Moteurs intégrés** : `kalis_adapt` 0.1.0 (branche fixe `etiquettes/kalis_adapt-v0.1.0`) + `kalis_core` 0.3.0 (`etiquettes/kalis_core-v0.3.0`) ; `kalis_plan` 0.1.0 inchangé. Aucune modification des paquets.

## Ce qui change

1. **Bilan du jour** (première page de la séance) : Koach demande « Comment tu te sens ? » — 5 niveaux montrés par Koach (Pas bien, Bof, Correct, Bien, En forme). Moyen ou haut → séance ; bas → détail sur un seul écran (sommeil, énergie, humeur, courbatures, douleur par zone sur la carte et 0-10, stress, motivation, temps disponible, alimentation, hydratation). « Passer » partout ; une question sans réponse ne compte pas.
2. **Ajustement** : assisté → appliqué, Koach liste ce qui change, « Annuler » ; libre → « Accepter » / « Garder ma séance ». Le temps disponible et l'épargne d'une zone douloureuse restent même si l'ajustement est annulé. Règle L13 : douleur > 3/10 sur plus de 2 séances de suite → avis d'un professionnel.
3. **Charges du jour** par `kalis_adapt` (plus Koach L7) ; « Calibrage » sur les premières séances d'un exercice, expliqué par Koach.
4. **Flammes à chaque série** : sélecteur des 10 flammes pré-rempli avec la flamme visée ; un appui valide, glisser corrige, « Je ne sais pas » discret ; libellé « 7 flammes · RIR 2 » ; phrase d'explication au premier usage. Remplace la colonne RIR / RPE partout ; anciennes séances affichées en flammes.
5. **Après chaque série**, la série suivante est ajustée (charge ou répétitions) : appliquée avec « Annuler » (assisté) ou proposée (libre).
6. **Fin de séance** : Koach résume le calibrage, ce qui a progressé (capacité estimée avant / après), ce qui changera la prochaine fois.
7. **Programme personnel** (D5.10) : même séance, même structure, porté tel quel dans un bloc importé ; « J'ai seulement… minutes » et « Je m'entraîne ailleurs » passent par le moteur.

## Tests

Ajoutés : `test/g9_seance_test.dart` (bilan partiel sans valeur injectée, modes assisté / libre, flammes obligatoires, conversion de l'historique, conseil dans les deux modes, programme du propriétaire servi par le moteur, journal des moteurs, prescription d'un autre jour, sauvegarde et import strict, résumé, écrans), `integration_test/seance_g9_test.dart` (11 captures × 2 thèmes). Modifiés (aucun retiré) : `l7_koach_screens_test` (sélecteur des flammes au lieu de la fiche L7), `l4b_seances_test`, `ui_refactor_test`, versions affichées.

## À tester par le propriétaire

Une vraie séance de ton programme : bilan santé (essaie une réponse basse pour voir le détail), flammes après chaque série, charges proposées cohérentes avec ton ressenti, ajustements pendant la séance (« Annuler »), résumé de fin. Ton profil v2 doit exister (refait en G6) ; son mode (assisté / libre) décide si Koach applique ou propose.

## Limites

- Sans profil v2, la séance reste celle d'avant (Koach L7), avec les flammes.
- « Échanger un exercice » (L11) n'est pas proposé dans une séance servie par le moteur (G10 apporte les échanges du moteur).
- Formats sans plage du programme personnel (montées, myo-reps, clusters, échelles, EMOM, durées) : hors moteur, charges de la consigne.
- Un ancien RIR saisi en échelle RPE est lu comme un RIR (règle C9 de kalis_core).
- Avec un bilan très bas, une douleur et le calibrage, le moteur peut viser une marge très large (1 flamme, RIR 5+) : décision du moteur, à revoir avec tes vrais journaux.
- Contenu sportif non relu par un professionnel diplômé (registre de `kalis_adapt`).
