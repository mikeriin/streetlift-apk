#!/bin/bash
# Mise au point KR1, run A : PART=0 export KM1 sur kalis_plan 0.4.1 (34 profils),
# sécurité de blocs, tests ; PART 1-6 campagne vivante 34 profils graines 0-5 ;
# PART 7-12 adversaires rejoués sur les saisons vivantes (témoin vivant).
root=$PWD
out=$root/out-packages
status=0
for name in kalis_adapt kalis_bench; do
  (cd packages/$name && dart pub get) > $out/$name-pub-$PART.log 2>&1 || { echo "pub get $name échec"; tail -30 $out/$name-pub-$PART.log; status=1; }
done
B=$root/packages/kalis_bench
R=$root/packages/kalis_adapt/reference
if [ "$PART" = 0 ]; then
  d=packages/kalis_bench
  (cd $d && dart format . > /dev/null); git diff -- $d > $out/format_kalis_bench.patch
  echo "format patch: $(wc -l < $out/format_kalis_bench.patch) lignes"
  (cd $d && dart analyze --fatal-infos) > $out/kalis_bench-analyze.log 2>&1 || { echo "analyse : échec"; status=1; }
  tail -30 $out/kalis_bench-analyze.log
  cd $B
  start=$(date +%s)
  dart run bin/km1.dart --sortie $out/km1 --sans-securite --sans-adversaires > $out/km1_export.log 2>&1 || { echo "export km1 : échec"; status=1; }
  tail -5 $out/km1_export.log; echo "export : $(( $(date +%s) - start )) s"
  # Données neuves à la place des saisons figées (dans l'arbre de la CI seulement).
  mkdir -p $out/figees
  cp -r $R/donnees/reference $out/figees/reference_0_3_1 2>/dev/null
  rm -rf $R/donnees/reference $R/donnees/temoin
  cp -r $out/km1/reference $out/km1/temoin $R/donnees/
  cp $out/km1/catalogue_infos.json.gz $out/km1/traces_verite.json.gz $out/km1/traces_endurance.json.gz $R/donnees/
  rm -rf km1_entree/securite
  (cd $R && python3 -m banc.securite_banc --entrees-dart $B/km1_entree/securite) | tail -2
  dart run bin/km1.dart --sortie $out/km1 --outils-seuls --sans-adversaires > $out/km1_securite.log 2>&1 || { echo "sécurité de blocs : échec"; status=1; }
  tail -3 $out/km1_securite.log
  cp $out/km1/securite_dart.json.gz $R/donnees/
  cd $R
  python3 -m pytest tests -q > $out/pytest.log 2>&1 || echo "pytest : échec"
  tail -30 $out/pytest.log
  cd $root
  (cd packages/kalis_bench && dart test --reporter expanded test/km2_banc_test.dart test/km_export_test.dart) > $out/kalis_bench-test.log 2>&1 || { echo "tests kalis_bench km : échec (attendu avant les fixtures)"; }
  grep -E "\[E\]|Some tests failed|All tests passed" $out/kalis_bench-test.log | tail -30
elif [ "$PART" -le 6 ]; then
  cd $B
  mkdir -p $out/parts
  dart run bin/km2.dart --graines 0-5 --coeurs 4 --partie $PART/6 --sortie $out/parts/kr1v_partie_${PART}_sur_6.json.gz > $out/campagne_$PART.log 2>&1 || { echo "campagne $PART : échec"; status=1; }
  tail -20 $out/campagne_$PART.log
else
  cd $B
  D=docs/data/km2
  i=$((PART-7))
  jeux=("km1_v1 $R/donnees/adversaires_v1.json" "km1c2 $R/donnees/adversaires_km1c2.json" "km1c3 $R/donnees/adversaires_km1c3.json" "km2_b300 $D/adversaires_km2_b300.json" "km2_complet_b600 $D/adversaires_km2_complet_b600.json" "km2_b3000 $D/adversaires_km2_b3000.json")
  set -- ${jeux[$i]}
  mkdir -p $out/adv
  dart run bin/km2.dart adversaires --rejouer $2 --coeurs 4 --sortie $out/adv/comparaison_adversaires_kr1v_$1.json > $out/adv/$1.log 2>&1 || { echo "adversaires $1 : échec"; tail -20 $out/adv/$1.log; status=1; }
  tail -5 $out/adv/$1.log
fi
exit $status
