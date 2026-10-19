#!/bin/bash
# Mise au point KM4 (Koach 1.0.6), run A : point de départ. Campagne Dart du couple kalis_plan 0.4.2 ×
# Koach 1.0.5 (kalis_adapt 1.0.4, inchangé) sur les 90 600 saisons, avec la mesure de la rampe sur les
# principaux ajoutée au banc (`rampe` : principal retiré par la rampe de volume sans douleur, part des
# séances dont un principal est réduit, part servie) et le rôle des emplacements dans `reste_semaine`
# (sans effet sur 1.0.5).
#  PART 1-34 : groupe g = (PART+1)/2 (graines 6(g-1)..6g-1 ; 17 : 96-99), part h sur 2 ; témoin lu
root=$PWD
out=$root/out-packages
status=0
B=$root/packages/kalis_bench
R=$root/packages/kalis_adapt/reference
for name in kalis_adapt kalis_bench; do
  (cd packages/$name && dart pub get) > $out/$name-pub-$PART.log 2>&1 || { echo "pub get $name échec"; tail -30 $out/$name-pub-$PART.log; status=1; }
done
if [ "$PART" = 1 ]; then
  (cd $B && dart analyze --fatal-infos lib bin tool test) > $out/analyze-kalis_bench.log 2>&1 || { echo "analyse kalis_bench : échec"; tail -30 $out/analyze-kalis_bench.log; status=1; }
  (cd $B && dart format --output=none --set-exit-if-changed lib bin test) > $out/format-kalis_bench.log 2>&1 || { echo "format kalis_bench : échec"; cat $out/format-kalis_bench.log | tail; status=1; }
fi
if [ "$PART" -ge 1 ] && [ "$PART" -le 34 ]; then
  g=$(( (PART + 1) / 2 )); h=$(( 2 - PART % 2 ))
  a=$(( 6 * (g - 1) )); b=$(( a + 5 )); [ $b -gt 99 ] && b=99
  cd $B
  mkdir -p $out/parts
  extra=""; [ "$g" != 1 ] && extra="--sans-determinisme"
  start=$(date +%s)
  dart run bin/km2.dart --graines $a-$b --coeurs 4 $extra --temoin $R/donnees/temoin --partie $h/2 --sortie $out/parts/km4avant_g${a}_${b}_partie_${h}_sur_2.json.gz > $out/campagne_${a}_${b}_$h.log 2>&1 || { echo "campagne $a-$b part $h : échec"; status=1; }
  echo "durée : $(( $(date +%s) - start )) s"
  tail -4 $out/campagne_${a}_${b}_$h.log
fi
exit $status
