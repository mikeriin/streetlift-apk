#!/bin/bash
# Mise au point KM4 (Koach 1.0.6), run B : référence Python 1.0.6 (retour gradué réparti sur la semaine,
# priorisé par rôle, plancher des principaux) et portage Dart (kalis_adapt 1.0.5, kalis_bench 0.5.7).
#  PART 0     : tests Python de la référence ; fixtures à jour ; Dart : format, analyse de kalis_adapt et
#               kalis_bench, tests de kalis_adapt, tests km de kalis_bench (km2_banc_test, km_export_test)
#  PART 61-80 : campagne Python de la référence 1.0.6, graines 0-99, parts 1/20..20/20 (saisons de
#               kalis_plan 0.4.2 de l'arbre, témoin 0.3.1 lu)
root=$PWD
out=$root/out-packages
status=0
B=$root/packages/kalis_bench
A=$root/packages/kalis_adapt
R=$A/reference
if [ "$PART" = 0 ]; then
  (cd $R && python3 -m pytest tests -q) > $out/pytest.log 2>&1 || { echo "pytest : échec"; status=1; }
  tail -30 $out/pytest.log
  (cd $R && python3 fixtures/generer.py --verifier && python3 fixtures/generer_banc_km2.py --verifier && python3 ../test/fixtures/km2c2/generer_km2c2.py --verifier) > $out/fixtures.log 2>&1 || { echo "fixtures pas à jour"; status=1; }
  tail -5 $out/fixtures.log
  for name in kalis_adapt kalis_bench; do
    (cd packages/$name && dart pub get) > $out/$name-pub-0.log 2>&1 || { echo "pub get $name échec"; tail -30 $out/$name-pub-0.log; status=1; }
    (cd packages/$name && dart format --output=none --set-exit-if-changed .) > $out/format-$name.log 2>&1 || { echo "format $name : échec"; (cd packages/$name && dart format . >/dev/null; git diff) > $out/format-$name.patch; status=1; }
    (cd packages/$name && dart analyze --fatal-infos) > $out/analyze-$name.log 2>&1 || { echo "analyse $name : échec"; tail -40 $out/analyze-$name.log; status=1; }
  done
  (cd $A && dart test --reporter expanded) > $out/kalis_adapt-test.log 2>&1 || { echo "tests kalis_adapt : échec"; status=1; }
  grep -E "\[E\]|Some tests failed|All tests passed|Expected|Actual" $out/kalis_adapt-test.log | tail -60
  (cd $B && dart test --reporter expanded test/km2_banc_test.dart test/km_export_test.dart) > $out/kalis_bench-test.log 2>&1 || { echo "tests kalis_bench km : échec"; status=1; }
  grep -E "\[E\]|Some tests failed|All tests passed" $out/kalis_bench-test.log | tail -30
elif [ "$PART" -ge 61 ] && [ "$PART" -le 80 ]; then
  i=$((PART-60))
  cd $R
  start=$(date +%s)
  python3 -m banc.campagne --graines 100 --coeurs 4 --partie $i/20 --travail $out/py_travail > $out/py_campagne_c${i}_sur_20.log 2>&1 || { echo "campagne python $i/20 : échec"; status=1; }
  echo "durée : $(( $(date +%s) - start )) s"
  tail -3 $out/py_campagne_c${i}_sur_20.log
else
  echo "part inconnue : $PART"; status=1
fi
exit $status
