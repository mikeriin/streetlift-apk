#!/bin/bash
# Mise au point KM4, run F : arbre final (Koach 1.0.6 sans répartition, variante P ; même moteur que la
# variante P du run D et le run E, seule la note du fichier de paramètres diffère).
#  PART 0     : tests Python ; Dart : format, analyse, tests de kalis_adapt et km de kalis_bench
#  PART 41-46 : critère 7 bis, six jeux d'adversaires rejoués par Koach 1.0.6 (Dart)
#  PART 99    : attend la fin du run E (campagne Python, RUN_PYTHON) pour la publication
root=$PWD
out=$root/out-packages
status=0
B=$root/packages/kalis_bench
A=$root/packages/kalis_adapt
R=$A/reference
if [ "$PART" = 0 ]; then
  (cd $R && python3 -m pytest tests -q) > $out/pytest.log 2>&1 || { echo "pytest : échec"; status=1; }
  tail -30 $out/pytest.log
  for name in kalis_adapt kalis_bench; do
    (cd packages/$name && dart pub get) > $out/$name-pub-0.log 2>&1 || { echo "pub get $name échec"; status=1; }
    (cd packages/$name && dart format --output=none --set-exit-if-changed .) > $out/format-$name.log 2>&1 || { echo "format $name : échec"; (cd packages/$name && dart format . >/dev/null; git diff) > $out/format-$name.patch; status=1; }
    (cd packages/$name && dart analyze --fatal-infos) > $out/analyze-$name.log 2>&1 || { echo "analyse $name : échec"; tail -40 $out/analyze-$name.log; status=1; }
  done
  (cd $A && dart test --reporter expanded) > $out/kalis_adapt-test.log 2>&1 || { echo "tests kalis_adapt : échec"; status=1; }
  grep -E "\[E\]|Some tests failed|All tests passed|Expected|Actual" $out/kalis_adapt-test.log | tail -60
  (cd $B && dart test --reporter expanded test/km2_banc_test.dart test/km_export_test.dart) > $out/kalis_bench-test.log 2>&1 || { echo "tests kalis_bench km : échec"; status=1; }
  grep -E "\[E\]|Some tests failed|All tests passed" $out/kalis_bench-test.log | tail -30
elif [ "$PART" -ge 41 ] && [ "$PART" -le 46 ]; then
  for name in kalis_adapt kalis_bench; do (cd packages/$name && dart pub get) > /dev/null 2>&1; done
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
  dart run bin/km2.dart adversaires --rejouer $adv --temoin-lu $tem --coeurs 4 --sortie $out/adversaires/comparaison_adversaires_km4_$jeu.json > $out/adversaires_$jeu.log 2>&1 || { echo "adversaires $jeu : échec"; status=1; }
  echo "durée : $(( $(date +%s) - start )) s"
  tail -6 $out/adversaires_$jeu.log
elif [ "$PART" = 99 ]; then
  st=""
  for k in $(seq 1 340); do
    st=$(gh api repos/$GITHUB_REPOSITORY/actions/runs/$RUN_PYTHON --jq .status 2>/dev/null)
    [ "$st" = completed ] && break
    sleep 60
  done
  echo "run $RUN_PYTHON : $st ($(date -u +%H:%M))"
  [ "$st" = completed ] || status=1
fi
exit $status
