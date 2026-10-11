#!/bin/bash
# $1 = dossier de rapport ; témoin 0.3.1 (Dart) sur les adversaires de entree/adversaires.json
rapport=$1
set -x
cd ../../paquets/kalis_bench
dart pub get 2>&1 | tail -2
mkdir -p km1_entree sortie_km1
cp ../../packages/aa_km1c2/entree/adversaires*.json km1_entree/ 2>/dev/null
ls -la km1_entree
for f in km1_entree/adversaires*.json; do
  nom=$(basename $f .json)
  mkdir -p e_$nom && cp $f e_$nom/adversaires.json
  start=$(date +%s)
  dart run bin/km1.dart --sortie s_$nom --outils-seuls --sans-securite --entree e_$nom 2>&1 | tail -n 8
  echo "durée $(( $(date +%s) - start )) s"
  cp s_$nom/adversaires_temoin.json.gz "$rapport/${nom}_temoin.json.gz"
done
ls -la "$rapport"
