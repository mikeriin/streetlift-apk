#!/bin/bash
# Mise au point KM6, run A : données de référence sur kalis_plan 0.4.3 (crédits « chest » des tirages, KM6) et
# grille de poulie par 2,5 kg (X1), avant le portage Dart de Koach 1.0.8.
#  PART 0     : export KM1 (34 profils, témoin 16 graines) ; données neuves mises à la place des anciennes dans
#               l'arbre de la CI ; sécurité des blocs (securite_dart) ; liste des fichiers changés ; tests km de
#               kalis_bench (version de référence 0.4.3, trois tables de crédits)
#  PART 71-76 : témoin 0.3.1 (Dart) sur les six jeux d'adversaires (programmes et grilles neufs)
#  PART 62    : tests de kalis_adapt
#  PART 63    : tests de kalis_bench (sur les données d'avant : les tests de données échouent, attendu)
#  PART 64    : tests de kalis_plan ; format et analyse de kalis_plan, kalis_adapt, kalis_bench (patchs)
root=$PWD
out=$root/out-packages
status=0
A=$root/packages/kalis_adapt
B=$root/packages/kalis_bench
R=$A/reference
for name in kalis_plan kalis_adapt kalis_bench; do
  (cd packages/$name && dart pub get) > $out/$name-pub-$PART.log 2>&1 || { echo "pub get $name échec"; tail -30 $out/$name-pub-$PART.log; status=1; }
done
if [ "$PART" = 0 ]; then
  cd $B
  start=$(date +%s)
  dart run bin/km1.dart --sortie $out/km1 --sans-securite --sans-adversaires > $out/km1_export.log 2>&1 || { echo "export km1 : échec"; status=1; }
  tail -5 $out/km1_export.log; echo "export : $(( $(date +%s) - start )) s"
  rm -rf $R/donnees/reference $R/donnees/temoin
  cp -r $out/km1/reference $out/km1/temoin $R/donnees/
  cp $out/km1/catalogue_infos.json.gz $out/km1/traces_verite.json.gz $out/km1/traces_endurance.json.gz $R/donnees/
  rm -rf km1_entree/securite
  (cd $R && python3 -m banc.securite_banc --entrees-dart $B/km1_entree/securite) | tail -2
  dart run bin/km1.dart --sortie $out/km1 --outils-seuls --sans-adversaires > $out/km1_securite.log 2>&1 || { echo "sécurité de blocs : échec"; status=1; }
  tail -3 $out/km1_securite.log
  cp $out/km1/securite_dart.json.gz $R/donnees/
  cd $root
  git status --porcelain -- $R/donnees > $out/km1_diff.txt; wc -l < $out/km1_diff.txt
  (cd packages/kalis_bench && dart test --reporter expanded test/km2_banc_test.dart test/km_export_test.dart test/km6_credits_test.dart) > $out/kalis_bench-km-test.log 2>&1 || { echo "tests kalis_bench km : échec"; status=1; }
  grep -E "\[E\]|Some tests failed|All tests passed|Expected|Actual" $out/kalis_bench-km-test.log | tail -60
elif [ "$PART" -ge 71 ] && [ "$PART" -le 76 ]; then
  case $PART in
    71) jeu=adversaires_temoin; adv=$R/donnees/adversaires_v1.json;;
    72) jeu=adversaires_km1c2_temoin; adv=$R/donnees/adversaires_km1c2.json;;
    73) jeu=adversaires_km1c3_temoin; adv=$R/donnees/adversaires_km1c3.json;;
    74) jeu=adversaires_km2_b300_temoin; adv=$B/docs/data/km2/adversaires_km2_b300.json;;
    75) jeu=adversaires_km2_complet_b600_temoin; adv=$B/docs/data/km2/adversaires_km2_complet_b600.json;;
    76) jeu=adversaires_km2_b3000_temoin; adv=$B/docs/data/km2/adversaires_km2_b3000.json;;
  esac
  e=$root/entree_$PART
  mkdir -p $e $out/temoins_adversaires
  (cd $R && python3 -I -c "import sys; sys.path.insert(0, '.'); from banc.adversaire import ecrire_adversaires, lire_adversaires; ecrire_adversaires(sys.argv[2], lire_adversaires(sys.argv[1]))" $adv $e/adversaires.json) || { echo "entrée $jeu : échec"; status=1; }
  cd $B
  start=$(date +%s)
  dart run bin/km1.dart --sortie $out/tem_$PART --outils-seuls --sans-securite --entree $e > $out/temoin_$jeu.log 2>&1 || { echo "témoin $jeu : échec"; status=1; }
  tail -3 $out/temoin_$jeu.log; echo "durée : $(( $(date +%s) - start )) s"
  cp $out/tem_$PART/adversaires_temoin.json.gz $out/temoins_adversaires/$jeu.json.gz
  rm -rf $out/tem_$PART
elif [ "$PART" = 62 ]; then
  (cd $A && dart test --reporter expanded) > $out/kalis_adapt-test.log 2>&1 || { echo "tests kalis_adapt : échec"; status=1; }
  grep -E "\[E\]|Some tests failed|All tests passed|Expected|Actual" $out/kalis_adapt-test.log | tail -80
elif [ "$PART" = 63 ]; then
  (cd $B && dart test --reporter expanded) > $out/kalis_bench-test.log 2>&1 || { echo "tests kalis_bench : échec"; status=1; }
  grep -E "\[E\]|Some tests failed|All tests passed|Expected|Actual" $out/kalis_bench-test.log | tail -80
elif [ "$PART" = 64 ]; then
  (cd packages/kalis_plan && dart test --reporter expanded) > $out/kalis_plan-test.log 2>&1 || { echo "tests kalis_plan : échec"; status=1; }
  grep -E "\[E\]|Some tests failed|All tests passed|Expected|Actual" $out/kalis_plan-test.log | tail -80
  for name in kalis_plan kalis_adapt kalis_bench; do
    (cd packages/$name && dart format --output=none --set-exit-if-changed .) > $out/format-$name.log 2>&1 || { echo "format $name : échec"; (cd packages/$name && dart format . >/dev/null; git diff --relative) > $out/format-$name.patch; status=1; }
    (cd packages/$name && git checkout -q -- . ) 2>/dev/null
    (cd packages/$name && dart analyze --fatal-infos) > $out/analyze-$name.log 2>&1 || { echo "analyse $name : échec"; tail -60 $out/analyze-$name.log; status=1; }
  done
fi
exit $status
