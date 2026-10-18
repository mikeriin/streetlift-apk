# Assemblage du run E (KM2c3) : parts Dart du run C (39080556198, artefacts réunis) contre la campagne Python de
# KM1c4 (run 39041787498), saison par saison (outil corrigé : temps ignoré, `first_under` comparé trié) ; adversaires
# Dart (run C) contre la référence Python recalculée ici.
O=$PWD/ci-out/packages
B=$PWD/packages/kalis_bench
mkdir -p $O/comparaison
P=$O/parts
python3 -I $B/tool/km2c3_comparer.py --python $PWD/artifacts_py --dart $P --sortie $O/comparaison/comparaison_saisons_km2c3.json --md $O/comparaison/COMPARAISON_SAISONS_KM2C3.md
for jeu in km1_v1 km1c2 km1c3 km2_b300 km2_complet_b600 km2_b3000; do
  python3 -I - $O/adversaires/comparaison_adversaires_km2c3_$jeu.json $O/adversaires_python/comparaison_adversaires_python_km2c3_$jeu.json $O/comparaison/adversaires_$jeu.txt <<'PY'
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
print('adversaires %s : %d écarts (Dart run C contre Python recalculé)' % (sys.argv[1].split('_km2c3_')[-1], len(e)))
PY
done
find $P -name 'km2c3_g*' ! -name 'km2c3_g0_5_*' -delete
find $O -maxdepth 1 -name 'campagne_*.log' -delete
rm -rf $PWD/artifacts_py
