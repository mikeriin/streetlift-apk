# Assemblage du run C (KM4) : sécurité et rampe du couple kalis_plan 0.4.2 × Koach 1.0.6 (Dart) sur les 100 graines,
# graines 0 à 5 à part ; critères Dart du groupe 0-5 ; critère 5 par groupe de six graines ; comparaison saison par
# saison à la campagne Python 1.0.6 (run B, RUN_PYTHON) ; agrégats de sécurité Dart contre Python.
O=$PWD/ci-out/packages
B=$PWD/packages/kalis_bench
R=$PWD/packages/kalis_adapt/reference
mkdir -p $O/criteres $O/securite $O/comparaison $O/critere5
(cd $B && dart pub get > /dev/null 2>&1)
P=$O/parts
python3 -I $B/tool/kr1_securite.py --sortie $O/securite/securite_km4_dart_100g.json --md $O/securite/SECURITE_KM4_DART_100G.md $P
python3 -I $B/tool/kr1_securite.py --sortie $O/securite/securite_km4_dart_g0_5.json --md $O/securite/SECURITE_KM4_DART_G0_5.md $P/km4_g0_5_partie_1_sur_2.json.gz $P/km4_g0_5_partie_2_sur_2.json.gz
python3 -I $PWD/DEV_LISTE_C7.py $P $O/securite/liste_c7_km4_dart_100g.json
(cd $B && timeout 1800 dart run bin/km2.dart assembler --sortie $O/criteres/criteres_km4_dart_g0_5.json $P/km4_g0_5_partie_1_sur_2.json.gz $P/km4_g0_5_partie_2_sur_2.json.gz > $O/criteres/assembler_g0_5.log 2>&1) || echo "assembler g0_5 : échec"
grep -E "^bilan" $O/criteres/assembler_g0_5.log
for g in $(seq 1 17); do
  a=$(( 6 * (g - 1) )); b=$(( a + 5 )); [ $b -gt 99 ] && b=99
  d=/tmp/c5_$a; rm -rf $d
  python3 -I $B/tool/kr1_securite.py --extraire $d $P/km4_g${a}_${b}_partie_1_sur_2.json.gz $P/km4_g${a}_${b}_partie_2_sur_2.json.gz > /dev/null
  (cd $R && python3 -m banc.calibration_grappes $d $O/critere5/calibration_grappes_g${a}_${b}.json > $O/critere5/g${a}_${b}.log 2>&1) || echo "critère 5 groupe $a-$b : échec"
  rm -rf $d
done
python3 -I $B/tool/km2c3_comparer.py --python $PWD/artifacts_py --dart $P --sortie $O/comparaison/comparaison_saisons_km4.json --md $O/comparaison/COMPARAISON_SAISONS_KM4.md
find $P -name 'km4_g*' ! -name 'km4_g0_5_*' -delete
rm -rf $PWD/artifacts_py
