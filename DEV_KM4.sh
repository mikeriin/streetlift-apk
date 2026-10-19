#!/bin/bash
# Mise au point KM4, run D : tri de deux variantes du retour gradué SANS répartition sur la semaine
# (`retour_repartition_semaines` 0 ; la répartition du run B a donné 40 constats « volume_trop_vite »
# introduits sur 90 600 saisons : coupes promises à une séance restante ensuite manquée, que le validateur
# compte à son écrit). Campagne Dart du couple kalis_plan 0.4.2 × Koach 1.0.6 sur les 90 600 saisons.
#  PART 1-34    : variante P (`retour_emprunt_plancher` 1 : planchers des principaux à la moitié, empruntés
#                 aux séances restantes)
#  PART 101-134 : variante M (`retour_emprunt_plancher` 0 : le jour paie jusqu'à une série par principal
#                 avant tout emprunt)
root=$PWD
out=$root/out-packages
status=0
B=$root/packages/kalis_bench
R=$root/packages/kalis_adapt/reference
v=P; q=$PART
if [ "$PART" -ge 101 ]; then
  v=M; q=$((PART-100))
  sed -i 's/"retour_emprunt_plancher": 1,/"retour_emprunt_plancher": 0,/' $R/params/koach_params_v1.json
  grep -n retour_emprunt_plancher $R/params/koach_params_v1.json
fi
for name in kalis_adapt kalis_bench; do
  (cd packages/$name && dart pub get) > $out/$name-pub-$PART.log 2>&1 || { echo "pub get $name échec"; tail -30 $out/$name-pub-$PART.log; status=1; }
done
g=$(( (q + 1) / 2 )); h=$(( 2 - q % 2 ))
a=$(( 6 * (g - 1) )); b=$(( a + 5 )); [ $b -gt 99 ] && b=99
cd $B
mkdir -p $out/parts
extra=""; [ "$g" != 1 ] && extra="--sans-determinisme"
start=$(date +%s)
dart run bin/km2.dart --graines $a-$b --coeurs 4 $extra --temoin $R/donnees/temoin --partie $h/2 --sortie $out/parts/km4$v\_g${a}_${b}_partie_${h}_sur_2.json.gz > $out/campagne_$v\_${a}_${b}_$h.log 2>&1 || { echo "campagne $v $a-$b part $h : échec"; status=1; }
echo "durée : $(( $(date +%s) - start )) s"
tail -4 $out/campagne_$v\_${a}_${b}_$h.log
exit $status
