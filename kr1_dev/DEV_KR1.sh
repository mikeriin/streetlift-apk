#!/bin/bash
# Mise au point KR1, run B (Koach 1.0.4 : élargissement plafonné ; données de
# référence régénérées sur kalis_plan 0.4.1, 34 profils).
#  PART 0     : formatage (patch), analyse, tests kalis_adapt, tests km de kalis_bench
#  PART 1-17  : campagne Dart du couple, groupe de graines g (6(g-1) .. 6g-1 ; 17 : 96-99),
#               saisons vivantes, témoin lu (donnees/temoin régénéré)
#  PART 21-24 : campagne Python (référence) graines 0-5, part (PART-20)/4
root=$PWD
out=$root/out-packages
status=0
B=$root/packages/kalis_bench
R=$root/packages/kalis_adapt/reference
if [ "$PART" -lt 20 ]; then
  for name in kalis_adapt kalis_bench; do
    (cd packages/$name && dart pub get) > $out/$name-pub-$PART.log 2>&1 || { echo "pub get $name échec"; tail -30 $out/$name-pub-$PART.log; status=1; }
  done
fi
run_tests() {
  name=$1; shift
  (cd packages/$name && dart test --reporter expanded "$@") > $out/$name-test.log 2>&1 || { echo "tests $name : échec"; status=1; }
  grep -E "\[E\]|Some tests failed|All tests passed" $out/$name-test.log | tail -40
}
if [ "$PART" = 0 ]; then
  for name in kalis_adapt kalis_bench; do
    d=packages/$name
    (cd $d && dart format . > /dev/null); git diff -- $d > $out/format_$name.patch
    echo "format patch $name: $(wc -l < $out/format_$name.patch) lignes"
    (cd $d && dart analyze --fatal-infos) > $out/$name-analyze.log 2>&1 || { echo "analyse $name : échec"; status=1; }
    tail -20 $out/$name-analyze.log
  done
  git checkout -- packages
  run_tests kalis_adapt
  run_tests kalis_bench test/km2_banc_test.dart test/km_export_test.dart test/km2_adversaire_test.dart test/km2_validateur_test.dart test/km2_campagne_test.dart
elif [ "$PART" -le 17 ]; then
  a=$(( 6 * (PART - 1) )); b=$(( a + 5 )); [ $b -gt 99 ] && b=99
  cd $B
  mkdir -p $out/parts
  extra=""; [ "$PART" != 1 ] && extra="--sans-determinisme"
  dart run bin/km2.dart --graines $a-$b --coeurs 4 $extra --temoin $R/donnees/temoin --sortie $out/parts/kr1_g${a}_${b}_partie_1_sur_1.json.gz > $out/campagne_$PART.log 2>&1 || { echo "campagne $PART : échec"; status=1; }
  tail -8 $out/campagne_$PART.log
else
  i=$((PART-20))
  cd $R
  python3 -m banc.campagne --graines 6 --coeurs 4 --partie $i/4 --travail $out/py_travail > $out/py_campagne_$i.log 2>&1 || { echo "campagne python $i : échec"; status=1; }
  tail -8 $out/py_campagne_$i.log
fi
exit $status
