#!/bin/bash
# Mise au point KM4, run E : campagne Python de la référence 1.0.6 SANS répartition (variante P :
# `retour_repartition_semaines` 0, `retour_emprunt_plancher` 1), graines 0-99, 20 parts ; même moteur que
# la variante P (Dart) du run D.
#  PART 61-80 : parts 1/20..20/20
root=$PWD
out=$root/out-packages
status=0
R=$root/packages/kalis_adapt/reference
if [ "$PART" -ge 61 ] && [ "$PART" -le 80 ]; then
  i=$((PART-60))
  cd $R
  grep -n '"retour_repartition_semaines"\|"retour_emprunt_plancher"' params/koach_params_v1.json
  start=$(date +%s)
  python3 -m banc.campagne --graines 100 --coeurs 4 --partie $i/20 --travail $out/py_travail > $out/py_campagne_c${i}_sur_20.log 2>&1 || { echo "campagne python $i/20 : échec"; status=1; }
  echo "durée : $(( $(date +%s) - start )) s"
  tail -3 $out/py_campagne_c${i}_sur_20.log
else
  echo "part inconnue : $PART"; status=1
fi
exit $status
