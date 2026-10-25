#!/bin/bash
# Lot KM7, run unique : arbre figé de Koach 1.0.9 (kalis_adapt 1.0.8 ; kalis_plan 0.4.3, kalis_bench 0.5.9
# inchangés), campagne complète unique (C17.54, lot express) et variante « garde l'écrit une fois sur deux ».
#  PART 1-34    : campagne Dart du couple kalis_plan 0.4.3 × Koach 1.0.8, groupe g = (PART+1)/2 (graines
#                 6(g-1)..6g-1 ; 17 : 96-99), part h sur 2 ; témoin lu ; déterminisme vérifié sur le groupe 0-5
#  PART 41-46   : critère 7 bis, six jeux d'adversaires rejoués par Koach 1.0.8 (Dart), témoin relu
#  PART 61-64   : tests (61 : Python, format, analyse ; 62 : kalis_adapt ; 63 : kalis_bench ; 64 : kalis_plan)
#  PART 101-150 : campagne Python de la référence 1.0.9, parts 1/50..50/50
#  PART 151-174 : variante Python « garde l'écrit une fois sur deux », bilan versé (graines 0-17, parts 1/24..24/24)
#  PART 181-188 : même variante, seuls les faits du bilan (non versé ; graines 0-5, parts 1/8..8/8)
root=$PWD
out=$root/out-packages
status=0
A=$root/packages/kalis_adapt
B=$root/packages/kalis_bench
R=$A/reference
if [ "$PART" -lt 100 ]; then
  for name in kalis_plan kalis_adapt kalis_bench; do
    (cd packages/$name && dart pub get) > $out/$name-pub-$PART.log 2>&1 || { echo "pub get $name échec"; tail -30 $out/$name-pub-$PART.log; status=1; }
  done
fi
if [ "$PART" -ge 1 ] && [ "$PART" -le 34 ]; then
  g=$(( (PART + 1) / 2 )); h=$(( 2 - PART % 2 ))
  a=$(( 6 * (g - 1) )); b=$(( a + 5 )); [ $b -gt 99 ] && b=99
  cd $B
  mkdir -p $out/parts
  extra=""; [ "$g" != 1 ] && extra="--sans-determinisme"
  start=$(date +%s)
  dart run bin/km2.dart --graines $a-$b --coeurs 4 $extra --temoin $R/donnees/temoin --partie $h/2 --sortie $out/parts/km7_g${a}_${b}_partie_${h}_sur_2.json.gz > $out/campagne_${a}_${b}_$h.log 2>&1 || { echo "campagne $a-$b part $h : échec"; status=1; }
  echo "durée : $(( $(date +%s) - start )) s"
  tail -4 $out/campagne_${a}_${b}_$h.log
elif [ "$PART" -ge 41 ] && [ "$PART" -le 46 ]; then
  case $PART in
    41) jeu=km1_v1; adv=$R/donnees/adversaires_v1.json; tem=$R/donnees/adversaires_temoin.json.gz;;
    42) jeu=km1c2; adv=$R/donnees/adversaires_km1c2.json; tem=$R/donnees/adversaires_km1c2_temoin.json.gz;;
    43) jeu=km1c3; adv=$R/donnees/adversaires_km1c3.json; tem=$R/donnees/adversaires_km1c3_temoin.json.gz;;
    44) jeu=km2_b300; adv=$B/docs/data/km2/adversaires_km2_b300.json; tem=$R/donnees/temoin_adversaires/adversaires_km2_b300_temoin.json.gz;;
    45) jeu=km2_complet_b600; adv=$B/docs/data/km2/adversaires_km2_complet_b600.json; tem=$R/donnees/temoin_adversaires/adversaires_km2_complet_b600_temoin.json.gz;;
    46) jeu=km2_b3000; adv=$B/docs/data/km2/adversaires_km2_b3000.json; tem=$R/donnees/temoin_adversaires/adversaires_km2_b3000_temoin.json.gz;;
  esac
  cd $B
  mkdir -p $out/adversaires
  start=$(date +%s)
  dart run bin/km2.dart adversaires --rejouer $adv --temoin-lu $tem --coeurs 4 --sortie $out/adversaires/comparaison_adversaires_km7_$jeu.json > $out/adversaires_$jeu.log 2>&1 || { echo "adversaires $jeu : échec"; status=1; }
  echo "durée : $(( $(date +%s) - start )) s"
  tail -6 $out/adversaires_$jeu.log
elif [ "$PART" = 61 ]; then
  (cd $R && python3 -m pytest tests -q -p no:cacheprovider) > $out/pytest.log 2>&1 || { echo "pytest : échec"; status=1; }
  tail -12 $out/pytest.log
  for name in kalis_plan kalis_adapt kalis_bench; do
    (cd packages/$name && dart format --output=none --set-exit-if-changed .) > $out/format-$name.log 2>&1 || { echo "format $name : échec"; (cd packages/$name && dart format . >/dev/null; git diff --relative) > $out/format-$name.patch; status=1; }
    (cd packages/$name && git checkout -q -- . ) 2>/dev/null
    (cd packages/$name && dart analyze --fatal-infos) > $out/analyze-$name.log 2>&1 || { echo "analyse $name : échec"; tail -60 $out/analyze-$name.log; status=1; }
  done
elif [ "$PART" = 62 ]; then
  (cd $A && dart test --reporter expanded) > $out/kalis_adapt-test.log 2>&1 || { echo "tests kalis_adapt : échec"; status=1; }
  grep -E "\[E\]|Some tests failed|All tests passed|Expected|Actual" $out/kalis_adapt-test.log | tail -60
elif [ "$PART" = 63 ]; then
  (cd $B && dart test --reporter expanded) > $out/kalis_bench-test.log 2>&1 || { echo "tests kalis_bench : échec"; status=1; }
  grep -E "\[E\]|Some tests failed|All tests passed|Expected|Actual" $out/kalis_bench-test.log | tail -60
elif [ "$PART" = 64 ]; then
  (cd packages/kalis_plan && dart test --reporter expanded) > $out/kalis_plan-test.log 2>&1 || { echo "tests kalis_plan : échec"; status=1; }
  grep -E "\[E\]|Some tests failed|All tests passed|Expected|Actual" $out/kalis_plan-test.log | tail -60
elif [ "$PART" -ge 101 ] && [ "$PART" -le 150 ]; then
  i=$((PART-100))
  cd $R
  start=$(date +%s)
  python3 -m banc.campagne --graines 100 --coeurs 4 --partie $i/50 --travail $out/py_travail > $out/py_campagne_c${i}_sur_50.log 2>&1 || { echo "campagne python $i/50 : échec"; status=1; }
  echo "durée : $(( $(date +%s) - start )) s"
  tail -3 $out/py_campagne_c${i}_sur_50.log
elif [ "$PART" -ge 151 ] && [ "$PART" -le 188 ]; then
  if [ "$PART" -le 174 ]; then i=$((PART-150)); n=24; g=18; v=verse; else i=$((PART-180)); n=8; g=6; v=non_verse; fi
  cd $R
  start=$(date +%s)
  python3 -m banc.campagne --graines $g --coeurs 4 --bilan-garde $v --partie $i/$n --travail $out/py_$v > $out/py_${v}_c${i}_sur_$n.log 2>&1 || { echo "variante $v $i/$n : échec"; status=1; }
  echo "durée : $(( $(date +%s) - start )) s"
  tail -3 $out/py_${v}_c${i}_sur_8.log
fi
exit $status
