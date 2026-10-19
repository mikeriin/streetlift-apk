# Assemblage du run B (KM4) : sécurité et rampe sur les principaux du couple kalis_plan 0.4.2 × Koach 1.0.6
# (campagne Python, agrégation en flux), 100 graines, graine 0, graines 0-5, liste complète des violations ;
# critères Python du groupe 0-5.
O=$PWD/ci-out/packages
R=$PWD/packages/kalis_adapt/reference
mkdir -p $O/criteres $O/securite
du -sh $O/py_travail 2>/dev/null
(cd $R && python3 -m banc.securite_campagne --sortie $O/securite/securite_km4_100g.json --md $O/securite/SECURITE_KM4_100G.md --liste $O/securite/liste_c7_km4_100g.json --titre "Sécurité du couple kalis_plan 0.4.2 × Koach 1.0.6, 100 graines (campagne Python)" $O/py_travail)
(cd $R && python3 -m banc.securite_campagne --graines 0-0 --sortie $O/securite/securite_km4_g0.json --md $O/securite/SECURITE_KM4_G0.md --titre "Sécurité, graine 0 (Koach 1.0.6)" $O/py_travail)
(cd $R && python3 -m banc.securite_campagne --graines 0-5 --sortie $O/securite/securite_km4_g0_5.json --md $O/securite/SECURITE_KM4_G0_5.md --titre "Sécurité, graines 0 à 5 (Koach 1.0.6)" $O/py_travail)
(cd $R && python3 -m banc.campagne --graines 6 --coeurs 4 --travail $O/py_travail --temps-existants --sortie $O/criteres/criteres_km4_python_g0_5.json > $O/criteres/py_assemblage_g0_5.log 2>&1 || echo "assemblage python g0-5 : échec")
tail -25 $O/criteres/py_assemblage_g0_5.log
rm -rf $O/py_travail
