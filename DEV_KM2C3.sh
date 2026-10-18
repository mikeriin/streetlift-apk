#!/bin/bash
# Mise au point KM2c3, run E : critère 7 bis de la RÉFÉRENCE Python 1.0.5 recalculé sur la CI (six jeux,
# `banc.adversaire --comparer`, témoin stocké), pour la comparaison aux sorties Dart du run C (39080556198) :
# les fichiers `donnees/comparaison_adversaires_km1c4_<jeu>.json` de KM1c4 ne sont pas ceux de la référence
# livrée (relance locale de km1_v1 : identique au Dart, différente du fichier stocké).
#  PART 51-56 : un jeu par part
root=$PWD
out=$root/out-packages
status=0
B=$root/packages/kalis_bench
R=$root/packages/kalis_adapt/reference
case $PART in
  51) jeu=km1_v1; adv=$R/donnees/adversaires_v1.json; tem=$R/donnees/adversaires_temoin.json.gz;;
  52) jeu=km1c2; adv=$R/donnees/adversaires_km1c2.json; tem=$R/donnees/adversaires_km1c2_temoin.json.gz;;
  53) jeu=km1c3; adv=$R/donnees/adversaires_km1c3.json; tem=$R/donnees/adversaires_km1c3_temoin.json.gz;;
  54) jeu=km2_b300; adv=$B/docs/data/km2/adversaires_km2_b300.json; tem=$R/donnees/temoin_adversaires/adversaires_km2_b300_temoin.json.gz;;
  55) jeu=km2_complet_b600; adv=$B/docs/data/km2/adversaires_km2_complet_b600.json; tem=$R/donnees/temoin_adversaires/adversaires_km2_complet_b600_temoin.json.gz;;
  56) jeu=km2_b3000; adv=$B/docs/data/km2/adversaires_km2_b3000.json; tem=$R/donnees/temoin_adversaires/adversaires_km2_b3000_temoin.json.gz;;
esac
mkdir -p $out/adversaires_python
cd $R
start=$(date +%s)
python3 -m banc.adversaire --comparer $tem --adversaires $adv --rapport $out/adversaires_python/comparaison_adversaires_python_km2c3_$jeu.json --processus 4 > $out/adversaires_python_$jeu.log 2>&1 || { echo "adversaires python $jeu : échec"; status=1; }
echo "durée : $(( $(date +%s) - start )) s"
tail -6 $out/adversaires_python_$jeu.log
exit $status
