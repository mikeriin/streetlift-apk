# Assemblage du run B (KM6) : campagne complète de Koach 1.0.8 en Dart (parts 1-34) et en Python (parts 101-150)
# dans le même run : sécurité (nouvelle et ancienne définition), rampe et critère KM6 (100 graines, graine 0,
# graines 0-5) dans les deux langages ; critères 0-5 (Dart et Python) ; critère 5 par groupe ; comparaison saison par
# saison Dart ↔ Python ; listes complètes des violations.
O=$PWD/ci-out/packages
B=$PWD/packages/kalis_bench
R=$PWD/packages/kalis_adapt/reference
mkdir -p $O/criteres $O/securite $O/comparaison $O/critere5
(cd $B && dart pub get > /dev/null 2>&1)
P=$O/parts
ls $P | wc -l; find $O/py_travail -name '*__*.json' | wc -l
python3 -I $B/tool/kr1_securite.py --sortie $O/securite/securite_km6_dart_100g.json --md $O/securite/SECURITE_KM6_DART_100G.md $P
python3 -I $B/tool/kr1_securite.py --sortie $O/securite/securite_km6_dart_g0_5.json --md $O/securite/SECURITE_KM6_DART_G0_5.md $P/km6_g0_5_partie_1_sur_2.json.gz $P/km6_g0_5_partie_2_sur_2.json.gz
python3 -I $PWD/DEV_LISTE_C7.py $P $O/securite/liste_c7_km6_dart_100g.json
(cd $R && python3 -m banc.securite_campagne --sortie $O/securite/securite_km6_python_100g.json --md $O/securite/SECURITE_KM6_PYTHON_100G.md --liste $O/securite/liste_c7_km6_python_100g.json --titre "Sécurité du couple kalis_plan 0.4.3 × Koach 1.0.8, 100 graines (campagne Python)" $O/py_travail)
(cd $R && python3 -m banc.securite_campagne --graines 0-0 --sortie $O/securite/securite_km6_python_g0.json --md $O/securite/SECURITE_KM6_PYTHON_G0.md --titre "Sécurité, graine 0 (Koach 1.0.8)" $O/py_travail)
(cd $R && python3 -m banc.securite_campagne --graines 0-5 --sortie $O/securite/securite_km6_python_g0_5.json --md $O/securite/SECURITE_KM6_PYTHON_G0_5.md --titre "Sécurité, graines 0 à 5 (Koach 1.0.8)" $O/py_travail)
(cd $R && python3 -m banc.campagne --graines 6 --coeurs 4 --travail $O/py_travail --temps-existants --sortie $O/criteres/criteres_km6_python_g0_5.json > $O/criteres/py_assemblage_g0_5.log 2>&1 || echo "assemblage python g0-5 : échec")
tail -25 $O/criteres/py_assemblage_g0_5.log
(cd $B && timeout 1800 dart run bin/km2.dart assembler --sortie $O/criteres/criteres_km6_dart_g0_5.json $P/km6_g0_5_partie_1_sur_2.json.gz $P/km6_g0_5_partie_2_sur_2.json.gz > $O/criteres/assembler_g0_5.log 2>&1) || echo "assembler g0_5 : échec"
grep -E "^bilan" $O/criteres/assembler_g0_5.log
for g in $(seq 1 17); do
  a=$(( 6 * (g - 1) )); b=$(( a + 5 )); [ $b -gt 99 ] && b=99
  d=/tmp/c5_$a; rm -rf $d
  python3 -I $B/tool/kr1_securite.py --extraire $d $P/km6_g${a}_${b}_partie_1_sur_2.json.gz $P/km6_g${a}_${b}_partie_2_sur_2.json.gz > /dev/null
  (cd $R && python3 -m banc.calibration_grappes $d $O/critere5/calibration_grappes_g${a}_${b}.json > $O/critere5/g${a}_${b}.log 2>&1) || echo "critère 5 groupe $a-$b : échec"
  rm -rf $d
done
python3 -I $B/tool/km2c3_comparer.py --python $O/py_travail --dart $P --sortie $O/comparaison/comparaison_saisons_km6.json --md $O/comparaison/COMPARAISON_SAISONS_KM6.md
find $P -name 'km6_g*' ! -name 'km6_g0_5_*' -delete
rm -rf $O/py_travail
