#!/bin/bash
# Mise au point KM2c3 (portage Dart de Koach 1.0.5), run D : compilation, format, tests (après relecture ; trois saisons du banc ajoutées).
#  PART 0 : dart format (le correctif de format est publié dans format.patch), analyse
#           --fatal-infos de kalis_adapt et kalis_bench, tests koach_* et km2c3_* de kalis_adapt
#  PART 1 : tests km2_* de kalis_bench (parité du banc sur les fixtures régénérées, validateur, adversaires)
#  PART 2 : tous les tests de kalis_adapt
root=$PWD
out=$root/out-packages
status=0
for name in kalis_adapt kalis_bench; do
  (cd packages/$name && dart pub get) > $out/$name-pub-$PART.log 2>&1 || { echo "pub get $name échec"; tail -30 $out/$name-pub-$PART.log; status=1; }
done
if [ "$PART" = 0 ]; then
  for name in kalis_adapt kalis_bench; do
    (cd packages/$name && dart format .) > $out/format-$name.log 2>&1
    tail -3 $out/format-$name.log
  done
  git diff -- packages > $out/format.patch; wc -l < $out/format.patch
  for name in kalis_adapt kalis_bench; do
    (cd packages/$name && dart analyze --fatal-infos) > $out/analyze-$name.log 2>&1 || { echo "analyse $name : échec"; status=1; }
    tail -40 $out/analyze-$name.log
  done
  cd packages/kalis_adapt
  dart test --reporter expanded $(ls test/koach_*_test.dart test/km2c3_*_test.dart test/validateur_test.dart) > $out/kalis_adapt-koach.log 2>&1 || { echo "tests koach : échec"; status=1; }
  grep -E "\[E\]|Some tests failed|All tests passed|Expected|Actual|Which" $out/kalis_adapt-koach.log | head -80
elif [ "$PART" = 1 ]; then
  cd packages/kalis_bench
  dart format . > /dev/null 2>&1
  dart test --reporter expanded test/km2_banc_test.dart test/km2_validateur_test.dart test/km2_adversaire_test.dart > $out/kalis_bench-km2.log 2>&1 || { echo "tests km2 : échec"; status=1; }
  grep -E "\[E\]|Some tests failed|All tests passed|Expected|Actual|Which" $out/kalis_bench-km2.log | head -80
elif [ "$PART" = 2 ]; then
  cd packages/kalis_adapt
  dart format . > /dev/null 2>&1
  start=$(date +%s)
  dart test --reporter expanded > $out/kalis_adapt-tout.log 2>&1 || { echo "tests kalis_adapt : échec"; status=1; }
  echo "durée : $(( $(date +%s) - start )) s"
  grep -E "\[E\]|Some tests failed|All tests passed" $out/kalis_adapt-tout.log | head -60
fi
exit $status
