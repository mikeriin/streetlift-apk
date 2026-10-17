# Assemblage du run A : sécurité du couple kalis_plan 0.4.2 × Koach 1.0.4 sur les 100 graines
# (point de départ de KM1c4), graines 0 à 5 à part ; critères Dart du groupe 0-5.
O=$PWD/ci-out/packages
mkdir -p $O/criteres $O/securite
cd packages/kalis_bench && dart pub get > /dev/null 2>&1
python3 -I tool/kr1_securite.py --sortie $O/securite/securite_km1c4_depart_100g.json --md $O/securite/SECURITE_KM1C4_DEPART_100G.md $O/parts
python3 -I tool/kr1_securite.py --sortie $O/securite/securite_km1c4_depart_g0_5.json --md $O/securite/SECURITE_KM1C4_DEPART_G0_5.md $O/parts/km1c4d_g0_5_partie_1_sur_2.json.gz $O/parts/km1c4d_g0_5_partie_2_sur_2.json.gz
python3 -I $PWD/../../DEV_LISTE_C7.py $O/parts $O/securite/liste_c7_km1c4_depart_100g.json
timeout 900 dart run bin/km2.dart assembler --sortie $O/criteres/criteres_km1c4_depart_g0_5.json $O/parts/km1c4d_g0_5_partie_1_sur_2.json.gz $O/parts/km1c4d_g0_5_partie_2_sur_2.json.gz > $O/criteres/assembler_g0_5.log 2>&1 || echo "assembler g0_5 : échec"
grep -E "^bilan" $O/criteres/assembler_g0_5.log
# ci-out ne garde que les parts du groupe 0-5 ; les autres restent dans les artefacts.
find $O/parts -name 'km1c4d_g*' ! -name 'km1c4d_g0_5_*' -delete
