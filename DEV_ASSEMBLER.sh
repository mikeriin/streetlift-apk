# Assemblage du run G (KM4) : campagne Python complète de la référence 1.0.6 sans répartition (parts du run E
# et demi-parts 13/40, 33/40) : sécurité et rampe (100 graines, graine 0, graines 0-5, liste complète), critères
# Python 0-5 ; comparaison saison par saison aux parts Dart de la variante P du run D (artifacts_py).
O=$PWD/ci-out/packages
B=$PWD/packages/kalis_bench
R=$PWD/packages/kalis_adapt/reference
mkdir -p $O/criteres $O/securite $O/comparaison
ls $O/py_travail; find $O/py_travail -name '*__*.json' | wc -l
(cd $R && python3 -m banc.securite_campagne --sortie $O/securite/securite_km4_python_100g.json --md $O/securite/SECURITE_KM4_PYTHON_100G.md --liste $O/securite/liste_c7_km4_python_100g.json --titre "Sécurité du couple kalis_plan 0.4.2 × Koach 1.0.6 (sans répartition), 100 graines (campagne Python)" $O/py_travail)
(cd $R && python3 -m banc.securite_campagne --graines 0-0 --sortie $O/securite/securite_km4_python_g0.json --md $O/securite/SECURITE_KM4_PYTHON_G0.md --titre "Sécurité, graine 0 (Koach 1.0.6)" $O/py_travail)
(cd $R && python3 -m banc.securite_campagne --graines 0-5 --sortie $O/securite/securite_km4_python_g0_5.json --md $O/securite/SECURITE_KM4_PYTHON_G0_5.md --titre "Sécurité, graines 0 à 5 (Koach 1.0.6)" $O/py_travail)
(cd $R && python3 -m banc.campagne --graines 6 --coeurs 4 --travail $O/py_travail --temps-existants --sortie $O/criteres/criteres_km4_python_g0_5.json > $O/criteres/py_assemblage_g0_5.log 2>&1 || echo "assemblage python g0-5 : échec")
tail -25 $O/criteres/py_assemblage_g0_5.log
D=$PWD/artifacts_dart
mkdir -p $D && find $PWD/artifacts_py -name 'km4P_g*.json.gz' -exec mv {} $D/ \;
ls $D | wc -l
python3 -I $B/tool/km2c3_comparer.py --python $O/py_travail --dart $D --sortie $O/comparaison/comparaison_saisons_km4.json --md $O/comparaison/COMPARAISON_SAISONS_KM4.md
rm -rf $O/py_travail $PWD/artifacts_py $D
