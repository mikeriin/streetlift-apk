#!/bin/bash
# $1 = dossier de rapport ; PARTIE et N lus dans partie.txt
rapport=$1
set -x
python3 --version
pip install --quiet numpy 2>&1 | tail -1
python3 -c "import numpy; print(numpy.__version__)"
nproc
cd reference
read PARTIE GRAINES EXTRA < ../partie.txt
start=$(date +%s)
python3 -m banc.campagne --profils tous --scenarios tous --graines $GRAINES --coeurs 4 --partie $PARTIE $EXTRA 2>&1 | tail -n 60
echo "durée $(( $(date +%s) - start )) s"
cd /tmp/km1-campagne && for d in */; do tar cJf "$rapport/campagne_$(echo $PARTIE | tr / _)_${d%/}.tar.xz" "$d"; done
ls -la "$rapport"
