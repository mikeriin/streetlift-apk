# Assemblage du run D (KM4) : sécurité et rampe des variantes P et M (Dart), 100 graines et graines 0-5,
# listes complètes des violations du critère 7.
O=$PWD/ci-out/packages
B=$PWD/packages/kalis_bench
mkdir -p $O/securite
P=$O/parts
for v in P M; do
  mkdir -p /tmp/parts_$v && mv $P/km4${v}_g* /tmp/parts_$v/ 2>/dev/null
  python3 -I $B/tool/kr1_securite.py --sortie $O/securite/securite_km4${v}_dart_100g.json --md $O/securite/SECURITE_KM4${v}_DART_100G.md /tmp/parts_$v
  python3 -I $B/tool/kr1_securite.py --sortie $O/securite/securite_km4${v}_dart_g0_5.json /tmp/parts_$v/km4${v}_g0_5_partie_1_sur_2.json.gz /tmp/parts_$v/km4${v}_g0_5_partie_2_sur_2.json.gz
  python3 -I $PWD/DEV_LISTE_C7.py /tmp/parts_$v $O/securite/liste_c7_km4${v}_dart_100g.json
done
rm -rf $P
