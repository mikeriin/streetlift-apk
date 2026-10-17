# Assemblage du run C (KM2c3) : sécurité du couple kalis_plan 0.4.2 × Koach 1.0.5 (Dart) sur les 100 graines,
# graines 0 à 5 à part ; critères Dart du groupe 0-5 ; critère 5 par groupe de six graines (bruit) ;
# comparaison saison par saison à la campagne Python de KM1c4 (run 39041787498) ; adversaires contre Python.
O=$PWD/ci-out/packages
B=$PWD/packages/kalis_bench
R=$PWD/packages/kalis_adapt/reference
mkdir -p $O/criteres $O/securite $O/comparaison $O/critere5
(cd $B && dart pub get > /dev/null 2>&1)
P=$O/parts
python3 -I $B/tool/kr1_securite.py --sortie $O/securite/securite_km2c3_100g.json --md $O/securite/SECURITE_KM2C3_100G.md $P
python3 -I $B/tool/kr1_securite.py --sortie $O/securite/securite_km2c3_g0_5.json --md $O/securite/SECURITE_KM2C3_G0_5.md $P/km2c3_g0_5_partie_1_sur_2.json.gz $P/km2c3_g0_5_partie_2_sur_2.json.gz
python3 -I $PWD/DEV_LISTE_C7.py $P $O/securite/liste_c7_km2c3_100g.json
(cd $B && timeout 1800 dart run bin/km2.dart assembler --sortie $O/criteres/criteres_km2c3_g0_5.json $P/km2c3_g0_5_partie_1_sur_2.json.gz $P/km2c3_g0_5_partie_2_sur_2.json.gz > $O/criteres/assembler_g0_5.log 2>&1) || echo "assembler g0_5 : échec"
grep -E "^bilan" $O/criteres/assembler_g0_5.log
# Critère 5 par groupe de six graines (indicateur, bruit entre les 17 groupes).
for g in $(seq 1 17); do
  a=$(( 6 * (g - 1) )); b=$(( a + 5 )); [ $b -gt 99 ] && b=99
  d=/tmp/c5_$a; rm -rf $d
  python3 -I $B/tool/kr1_securite.py --extraire $d $P/km2c3_g${a}_${b}_partie_1_sur_2.json.gz $P/km2c3_g${a}_${b}_partie_2_sur_2.json.gz > /dev/null
  (cd $R && python3 -m banc.calibration_grappes $d $O/critere5/calibration_grappes_g${a}_${b}.json > $O/critere5/g${a}_${b}.log 2>&1) || echo "critère 5 groupe $a-$b : échec"
  rm -rf $d
done
# Saison par saison contre la campagne Python de KM1c4 (artefacts du run 39041787498).
python3 -I $B/tool/km2c3_comparer.py --python $PWD/artifacts_py --dart $P --sortie $O/comparaison/comparaison_saisons_km2c3.json --md $O/comparaison/COMPARAISON_SAISONS_KM2C3.md
# Agrégats de sécurité contre ceux de la référence (docs/data/km1c4/securite/securite_km1c4_100g.json).
python3 -I - $O/securite/securite_km2c3_100g.json $B/docs/data/km1c4/securite/securite_km1c4_100g.json $O/comparaison/agregats_securite.txt <<'PY'
import json, sys
d = json.load(open(sys.argv[1])); p = json.load(open(sys.argv[2]))
for x in (d, p):
    for k in ('duree_totale_s', 'dossiers', 'parts', 'sources'):
        x.pop(k, None)
sys.path.insert(0, 'packages/kalis_bench/tool')
import km2c3_comparer as kc
e = []
kc.comparer(d, p, '', e)
with open(sys.argv[3], 'w') as f:
    f.write('écarts : %d\n' % len(e))
    for c, x, y in e[:200]:
        f.write('%s : Dart %s ; Python %s\n' % (c, kc._court(x), kc._court(y)))
print('agrégats de sécurité Dart contre Python : %d écarts' % len(e))
PY
# Adversaires : Dart contre Python (comparaison_adversaires_km1c4_<jeu>.json).
for jeu in km1_v1 km1c2 km1c3 km2_b300 km2_complet_b600 km2_b3000; do
  python3 -I - $O/adversaires/comparaison_adversaires_km2c3_$jeu.json $R/donnees/comparaison_adversaires_km1c4_$jeu.json $O/comparaison/adversaires_$jeu.txt <<'PY'
import json, sys
sys.path.insert(0, 'packages/kalis_bench/tool')
import km2c3_comparer as kc
try:
    d = json.load(open(sys.argv[1])); p = json.load(open(sys.argv[2]))
except Exception as exc:
    print('adversaires %s : %s' % (sys.argv[1], exc)); sys.exit(0)
e = []
kc.comparer(d, p, '', e)
with open(sys.argv[3], 'w') as f:
    f.write('écarts : %d\n' % len(e))
    for c, x, y in e[:300]:
        f.write('%s : Dart %s ; Python %s\n' % (c, kc._court(x), kc._court(y)))
print('adversaires %s : %d écarts' % (sys.argv[1].split('_km2c3_')[-1], len(e)))
PY
done
# ci-out ne garde que les parts du groupe 0-5 ; les autres restent dans les artefacts.
find $P -name 'km2c3_g*' ! -name 'km2c3_g0_5_*' -delete
rm -rf $PWD/artifacts_py
