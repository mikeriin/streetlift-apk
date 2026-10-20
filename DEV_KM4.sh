#!/bin/bash
# Mise au point KM4, run G : la part 13/20 de la campagne Python du run E (39312132226) a dépassé la limite
# de 355 min (saisons écrites jusque-là gardées dans son artefact) ; elle est refaite en deux demi-parts
# 13/40 et 33/40 (même partition, même empreinte : arbre et fichier de paramètres du run E). La publication
# réunit les parts du run E (RUN_PRECEDENT) et celles-ci (une saison déjà calculée l'emporte, même
# contenu), puis compare saison par saison aux parts Dart de la variante P du run D (RUN_PYTHON).
#  PART 81 : 13/40 ; PART 82 : 33/40
root=$PWD
out=$root/out-packages
status=0
R=$root/packages/kalis_adapt/reference
case $PART in 81) i=13;; 82) i=33;; *) echo "part inconnue"; exit 1;; esac
cd $R
start=$(date +%s)
python3 -m banc.campagne --graines 100 --coeurs 4 --partie $i/40 --travail $out/py_travail > $out/py_campagne_c${i}_sur_40.log 2>&1 || { echo "campagne python $i/40 : échec"; status=1; }
echo "durée : $(( $(date +%s) - start )) s"
tail -3 $out/py_campagne_c${i}_sur_40.log
exit $status
