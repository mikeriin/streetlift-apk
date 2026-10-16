# Assemblage du run B : critères Dart par groupe de graines, sécurité des 100
# graines, critère 5 (grappes) du groupe 0-5, campagne Python 0-5 assemblée.
O=$PWD/ci-out/packages
R=$PWD/packages/kalis_adapt/reference
mkdir -p $O/criteres $O/securite
cd packages/kalis_bench && dart pub get > /dev/null 2>&1
for f in $O/parts/kr1_g*_partie_1_sur_1.json.gz; do
  g=$(basename $f | sed 's/kr1_\(g[0-9]*_[0-9]*\)_.*/\1/')
  dart run bin/km2.dart assembler --sortie $O/criteres/criteres_kr1_$g.json $f > $O/criteres/assembler_$g.log 2>&1 || echo "assembler $g : échec"
  grep -E "^\[|^bilan" $O/criteres/assembler_$g.log | head -12 | sed "s/^/$g /"
done
python3 -I tool/kr1_securite.py --sortie $O/securite/securite_kr1_100g.json --md $O/securite/SECURITE_KR1_100G.md $O/parts
python3 -I tool/kr1_securite.py --sortie $O/securite/securite_kr1_g0_5.json $O/parts/kr1_g0_5_partie_1_sur_1.json.gz
python3 -I tool/kr1_securite.py --extraire /tmp/ext_g05 $O/parts/kr1_g0_5_partie_1_sur_1.json.gz
pip install --quiet numpy
(cd $R && python3 -m banc.calibration_grappes /tmp/ext_g05 $O/criteres/calibration_grappes_kr1_dart_g05.json | tail -3)
# Campagne Python : dossiers de travail réunis, assemblage (sans --partie).
mkdir -p /tmp/py_travail
cp -r $O/py_travail/. /tmp/py_travail/ 2>/dev/null
(cd $R && python3 -m banc.campagne --graines 6 --coeurs 2 --temps-existants --travail /tmp/py_travail --sortie $O/criteres/criteres_kr1_python_g05.json > $O/criteres/py_assemblage.log 2>&1; tail -25 $O/criteres/py_assemblage.log)
(cd $R && python3 -m banc.calibration_grappes /tmp/py_travail $O/criteres/calibration_grappes_kr1_python_g05.json | tail -3)
python3 -I tool/kr1_comparer.py --sortie $O/criteres/parite_saisons_g05.json /tmp/py_travail $O/parts/kr1_g0_5_partie_1_sur_1.json.gz
# Les parts restent dans les artefacts ; ci-out ne garde que le groupe 0-5.
find $O/parts -name 'kr1_g*' ! -name 'kr1_g0_5_*' -delete
rm -rf $O/py_travail
