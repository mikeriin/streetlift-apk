# Assemblage du run A (KM4) : sécurité et rampe sur les principaux du couple kalis_plan 0.4.2 × Koach 1.0.5
# (Dart, point de départ), 100 graines et graines 0 à 5.
O=$PWD/ci-out/packages
B=$PWD/packages/kalis_bench
mkdir -p $O/securite
P=$O/parts
python3 -I $B/tool/kr1_securite.py --sortie $O/securite/securite_km4avant_100g.json --md $O/securite/SECURITE_KM4AVANT_100G.md $P
python3 -I $B/tool/kr1_securite.py --sortie $O/securite/securite_km4avant_g0_5.json --md $O/securite/SECURITE_KM4AVANT_G0_5.md $P/km4avant_g0_5_partie_1_sur_2.json.gz $P/km4avant_g0_5_partie_2_sur_2.json.gz
find $P -name 'km4avant_g*' ! -name 'km4avant_g0_5_*' -delete
