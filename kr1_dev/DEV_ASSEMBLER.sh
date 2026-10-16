# Assemblage du run F : critères Dart par groupe de graines (34 profils et 27),
# sécurité des 100 graines, critère 5 (grappes) du groupe 0-5, parité saison par saison.
O=$PWD/ci-out/packages
F=$PWD/DEV_FILTRE.py
R=$PWD/packages/kalis_adapt/reference
mkdir -p $O/criteres $O/securite /tmp/p27
cd packages/kalis_bench && dart pub get > /dev/null 2>&1
pip install --quiet numpy
for f1 in $O/parts/kr1_g*_partie_1_sur_2.json.gz; do
  g=$(basename $f1 | sed 's/kr1_\(g[0-9]*_[0-9]*\)_.*/\1/')
  f2=${f1/partie_1_sur_2/partie_2_sur_2}
  timeout 900 dart run bin/km2.dart assembler --sortie $O/criteres/criteres_kr1_$g.json $f1 $f2 > $O/criteres/assembler_$g.log 2>&1 || echo "assembler $g : échec"
  python3 -I $F $f1 /tmp/p27/${g}_1.json.gz > /dev/null; python3 -I $F $f2 /tmp/p27/${g}_2.json.gz > /dev/null
  timeout 900 dart run bin/km2.dart assembler --sortie $O/criteres/criteres_kr1_27p_$g.json /tmp/p27/${g}_1.json.gz /tmp/p27/${g}_2.json.gz > $O/criteres/assembler_27p_$g.log 2>&1 || echo "assembler 27p $g : échec"
  grep -E "^bilan" $O/criteres/assembler_$g.log | sed "s/^/$g /"
done
python3 -I tool/kr1_securite.py --sortie $O/securite/securite_kr1_100g.json --md $O/securite/SECURITE_KR1_100G.md $O/parts
python3 -I tool/kr1_securite.py --sortie $O/securite/securite_kr1_g0_5.json --md $O/securite/SECURITE_KR1_G0_5.md $O/parts/kr1_g0_5_partie_1_sur_2.json.gz $O/parts/kr1_g0_5_partie_2_sur_2.json.gz
python3 -I tool/kr1_securite.py --extraire /tmp/ext_g05 $O/parts/kr1_g0_5_partie_1_sur_2.json.gz $O/parts/kr1_g0_5_partie_2_sur_2.json.gz
(cd $R && python3 -m banc.calibration_grappes /tmp/ext_g05 $O/criteres/calibration_grappes_kr1_dart_g05.json | tail -3)
python3 -I tool/kr1_securite.py --extraire /tmp/ext_g05_27 /tmp/p27/g0_5_1.json.gz /tmp/p27/g0_5_2.json.gz
(cd $R && python3 -m banc.calibration_grappes /tmp/ext_g05_27 $O/criteres/calibration_grappes_kr1_dart_27p_g05.json | tail -3)
python3 -I tool/kr1_comparer.py --sortie $O/criteres/parite_saisons_g05.json $O/py_travail $O/parts/kr1_g0_5_partie_1_sur_2.json.gz $O/parts/kr1_g0_5_partie_2_sur_2.json.gz
# ci-out ne garde que les parts du groupe 0-5 ; les autres restent dans les artefacts.
find $O/parts -name 'kr1_g*' ! -name 'kr1_g0_5_*' -delete
rm -rf $O/py_travail
