#!/bin/bash
# Mise au point KR1, run G (vue réalisée appariée, parité de la sécurité ; parts conservées).
#  PART 0      : formatage (patch), analyse, tests kalis_adapt, tests km de kalis_bench
#  PART 1-34   : campagne Dart du couple, groupe g = (PART+1)/2 (graines 6(g-1)..6g-1 ; 17 : 96-99),
#                part h = 1 + (PART+1)%2 sur 2 ; saisons vivantes, témoin lu
#  PART 40     : banc adversarial, six jeux, Koach 1.0.4 sans extension, témoin rejoué (saisons vivantes)
#  PART 41-42  : campagne Python graines 0-5, parts 1/8 et 2/8 (parité saison par saison)
root=$PWD
out=$root/out-packages
status=0
B=$root/packages/kalis_bench
R=$root/packages/kalis_adapt/reference
if [ "$PART" -lt 41 ]; then
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
    tail -5 $out/$name-analyze.log
  done
  git checkout -- packages
  run_tests kalis_adapt
  run_tests kalis_bench test/km2_banc_test.dart test/km_export_test.dart test/km2_adversaire_test.dart test/km2_validateur_test.dart test/km2_campagne_test.dart
elif [ "$PART" -le 34 ]; then
  g=$(( (PART + 1) / 2 )); h=$(( 2 - PART % 2 ))
  a=$(( 6 * (g - 1) )); b=$(( a + 5 )); [ $b -gt 99 ] && b=99
  cd $B
  mkdir -p $out/parts
  extra=""; [ "$g" != 1 ] && extra="--sans-determinisme"
  dart run bin/km2.dart --graines $a-$b --coeurs 4 $extra --temoin $R/donnees/temoin --partie $h/2 --sortie $out/parts/kr1_g${a}_${b}_partie_${h}_sur_2.json.gz > $out/campagne_${a}_${b}_$h.log 2>&1 || { echo "campagne $a-$b part $h : échec"; status=1; }
  tail -4 $out/campagne_${a}_${b}_$h.log
elif [ "$PART" = 40 ]; then
  cd $B
  D=docs/data/km2
  mkdir -p $out/adv
  for jeu in "km1_v1 $R/donnees/adversaires_v1.json" "km1c2 $R/donnees/adversaires_km1c2.json" "km1c3 $R/donnees/adversaires_km1c3.json" "km2_b300 $D/adversaires_km2_b300.json" "km2_complet_b600 $D/adversaires_km2_complet_b600.json" "km2_b3000 $D/adversaires_km2_b3000.json"; do
    set -- $jeu
    dart run bin/km2.dart adversaires --rejouer $2 --coeurs 4 --sortie $out/adv/comparaison_adversaires_kr1_$1.json > $out/adv/$1.log 2>&1 || { echo "adversaires $1 : échec"; tail -20 $out/adv/$1.log; status=1; }
    tail -4 $out/adv/$1.log
  done
else
  i=$((PART-40))
  cd $R
  python3 -m banc.campagne --graines 6 --coeurs 4 --partie $i/8 --travail $out/py_travail > $out/py_campagne_$i.log 2>&1 || { echo "campagne python $i : échec"; status=1; }
  tail -4 $out/py_campagne_$i.log
fi
exit $status
