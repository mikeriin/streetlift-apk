#!/bin/bash
# Pousse l'arbre de travail de moteurs sur claude/ci-cp-a (docs/CI_PISTES.md).
# usage : ci.sh dev|full "<message>"
#  dev  : aa_fmt, sans kalis_quest, sans tests ni rapports de core/plan/adapt, banc réduit à l'export KM1
#         (tests du banc : seulement test/km_*.dart)
#  full : arbre de moteurs tel quel
set -e
MODE=$1; MSG=$2
WT=/home/claude/moteurs
REPO=/home/claude/streetlift-apk
T=/tmp/km1ci
rm -rf $T && mkdir -p $T
(cd $WT && git ls-files -co --exclude-standard -z | xargs -0 cp --parents -t $T/)
if [ "$MODE" != full ]; then
  cp -r /home/claude/km1-outils/aa_fmt $T/packages/aa_fmt
  rm -rf $T/packages/kalis_quest
  for p in kalis_core kalis_plan kalis_adapt; do
    rm -rf $T/packages/$p/test
    rm -f $T/packages/$p/bin/${p}_cli.dart
  done
  find $T/packages/kalis_bench/test -name '*_test.dart' ! -name 'km_*' -delete
  cp /home/claude/km1-outils/shim_cli.dart $T/packages/kalis_bench/bin/kalis_bench_cli.dart
  [ -n "$SEEDS" ] && echo "$SEEDS" > $T/packages/kalis_bench/km1_seeds.txt
fi
export GIT_INDEX_FILE=/tmp/km1ci.index
rm -f $GIT_INDEX_FILE
cd $REPO
git --work-tree=$T add -A . >/dev/null
TREE=$(git write-tree)
unset GIT_INDEX_FILE
git fetch -q origin claude/ci-cp-a
C=$(git commit-tree $TREE -p FETCH_HEAD -m "KM1 contrôle ($MODE) : $MSG")
git push -q origin $C:refs/heads/claude/ci-cp-a
echo "poussé $C"
