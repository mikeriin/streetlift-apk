# Assemblage du run B : critères Python (graines 0-5, 34 profils) de la référence 1.0.5 préliminaire, sécurité des parts Python.
O=$PWD/ci-out/packages
R=$PWD/packages/kalis_adapt/reference
mkdir -p $O/criteres
pip install --quiet numpy
ls $O/py_travail 2>/dev/null | head
(cd $R && python3 -m banc.campagne --graines 6 --coeurs 4 --travail $O/py_travail --temps-existants --sortie $O/criteres/criteres_km1c4_python_g0_5.json > $O/criteres/py_assemblage.log 2>&1 || echo "assemblage python : échec")
tail -25 $O/criteres/py_assemblage.log
rm -rf $O/py_travail
