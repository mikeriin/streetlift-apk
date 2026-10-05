#!/bin/bash
# Pousse l'arbre de travail de moteurs sur claude/ci-cp-a (docs/CI_PISTES.md).
# usage : ci.sh quick|dev|full "<message>" [graines]
set -e
MODE=$1; MSG=$2; SEEDS=${3:-4}
WT=/home/claude/moteurs
REPO=/home/claude/streetlift-apk
T=/tmp/cp2ci
rm -rf $T && mkdir -p $T
(cd $WT && git ls-files -co --exclude-standard -z | xargs -0 cp --parents -t $T/)
if [ "$MODE" != full ]; then
  cp -r /home/claude/cp2/aa_fmt $T/packages/aa_fmt
  echo "$SEEDS" > $T/packages/kalis_bench/campaign_seeds.txt
  echo "$SEEDS" > $T/packages/kalis_bench/season_seeds.txt
  rm -rf $T/packages/kalis_quest
fi
if [ "$MODE" = quick ]; then
  for p in kalis_core kalis_plan kalis_adapt; do
    rm -rf $T/packages/$p/test
    rm -f $T/packages/$p/bin/${p}_cli.dart
  done
fi
export GIT_INDEX_FILE=/tmp/cp2ci.index
rm -f $GIT_INDEX_FILE
cd $REPO
git --work-tree=$T add -A . >/dev/null
TREE=$(git write-tree)
unset GIT_INDEX_FILE
git fetch -q origin claude/ci-cp-a
C=$(git commit-tree $TREE -p origin/claude/ci-cp-a -m "CP2 contrôle ($MODE) : $MSG")
git push -q origin $C:refs/heads/claude/ci-cp-a
echo "poussé $C"
