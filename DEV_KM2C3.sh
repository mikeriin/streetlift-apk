#!/bin/bash
# Mise au point KM2c3 (portage Dart de Koach 1.0.5), run C : campagne Dart du couple kalis_plan 0.4.2 ×
# Koach 1.0.5 (kalis_adapt 1.0.4) sur les 90 600 saisons, et banc adversarial (six jeux).
#  PART 1-34  : campagne Dart, groupe g = (PART+1)/2 (graines 6(g-1)..6g-1 ; 17 : 96-99), part h sur 2 ;
#               saisons vivantes (kalis_plan 0.4.2, les mêmes que lit la référence Python), témoin 0.3.1 lu
#               (méthode de KR1 et KM1c4) ; déterminisme vérifié sur le groupe 0-5
#  PART 41-46 : critère 7 bis, six jeux d'adversaires rejoués par Koach (Dart, sans extension), témoin
#               relu (le même que lit la référence Python de KM1c4)
root=$PWD
out=$root/out-packages
status=0
B=$root/packages/kalis_bench
R=$root/packages/kalis_adapt/reference
for name in kalis_adapt kalis_bench; do
  (cd packages/$name && dart pub get) > $out/$name-pub-$PART.log 2>&1 || { echo "pub get $name échec"; tail -30 $out/$name-pub-$PART.log; status=1; }
done
if [ "$PART" -ge 1 ] && [ "$PART" -le 34 ]; then
  g=$(( (PART + 1) / 2 )); h=$(( 2 - PART % 2 ))
  a=$(( 6 * (g - 1) )); b=$(( a + 5 )); [ $b -gt 99 ] && b=99
  cd $B
  mkdir -p $out/parts
  extra=""; [ "$g" != 1 ] && extra="--sans-determinisme"
  start=$(date +%s)
  dart run bin/km2.dart --graines $a-$b --coeurs 4 $extra --temoin $R/donnees/temoin --partie $h/2 --sortie $out/parts/km2c3_g${a}_${b}_partie_${h}_sur_2.json.gz > $out/campagne_${a}_${b}_$h.log 2>&1 || { echo "campagne $a-$b part $h : échec"; status=1; }
  echo "durée : $(( $(date +%s) - start )) s"
  tail -4 $out/campagne_${a}_${b}_$h.log
elif [ "$PART" -ge 41 ] && [ "$PART" -le 46 ]; then
  case $PART in
    41) jeu=km1_v1; adv=$R/donnees/adversaires_v1.json; tem=$R/donnees/adversaires_temoin.json.gz;;
    42) jeu=km1c2; adv=$R/donnees/adversaires_km1c2.json; tem=$R/donnees/adversaires_km1c2_temoin.json.gz;;
    43) jeu=km1c3; adv=$R/donnees/adversaires_km1c3.json; tem=$R/donnees/adversaires_km1c3_temoin.json.gz;;
    44) jeu=km2_b300; adv=$B/docs/data/km2/adversaires_km2_b300.json; tem=$R/donnees/temoin_adversaires/adversaires_km2_b300_temoin.json.gz;;
    45) jeu=km2_complet_b600; adv=$B/docs/data/km2/adversaires_km2_complet_b600.json; tem=$R/donnees/temoin_adversaires/adversaires_km2_complet_b600_temoin.json.gz;;
    46) jeu=km2_b3000; adv=$B/docs/data/km2/adversaires_km2_b3000.json; tem=$R/donnees/temoin_adversaires/adversaires_km2_b3000_temoin.json.gz;;
  esac
  cd $B
  mkdir -p $out/adversaires
  start=$(date +%s)
  dart run bin/km2.dart adversaires --rejouer $adv --temoin-lu $tem --coeurs 4 --sortie $out/adversaires/comparaison_adversaires_km2c3_$jeu.json > $out/adversaires_$jeu.log 2>&1 || { echo "adversaires $jeu : échec"; status=1; }
  echo "durée : $(( $(date +%s) - start )) s"
  tail -6 $out/adversaires_$jeu.log
fi
exit $status
