#!/bin/bash
# Pousse l'arbre de travail de moteurs sur claude/ci-cp-a (méthode
# docs/CI_PISTES.md). usage : ci.sh dev|full "<message>" [graines]
# dev : ajoute l'outil de formatage aa_fmt et réduit les graines des
# campagnes (fichiers campaign_seeds.txt et season_seeds.txt, prévus pour
# les essais rapides) ; full : l'arbre de moteurs tel quel.
set -e
MODE=$1; MSG=$2; SEEDS=${3:-4}
WT=/home/claude/moteurs
REPO=/home/claude/streetlift-apk
T=/tmp/cxci
rm -rf $T && mkdir -p $T
(cd $WT && git ls-files -co --exclude-standard -z | xargs -0 cp --parents -t $T/)
if [ "$MODE" = dev ]; then
  cp -r /home/claude/cx/aa_fmt $T/packages/aa_fmt
  echo "$SEEDS" > $T/packages/kalis_bench/campaign_seeds.txt
  echo "$SEEDS" > $T/packages/kalis_bench/season_seeds.txt
fi
export GIT_INDEX_FILE=/tmp/cxci.index
rm -f $GIT_INDEX_FILE
cd $REPO
git --work-tree=$T add -A . >/dev/null
TREE=$(git write-tree)
unset GIT_INDEX_FILE
git fetch -q origin claude/ci-cp-a
C=$(git commit-tree $TREE -p origin/claude/ci-cp-a -m "CX contrôle ($MODE) : $MSG")
git push -q origin $C:refs/heads/claude/ci-cp-a
echo "poussé $C"
