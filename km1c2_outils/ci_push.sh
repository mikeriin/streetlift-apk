#!/bin/bash
# usage: ci_push.sh <a|b> "<message>" <run.sh> [fichiers supplémentaires à poser dans le paquet...]
set -e
voie=$1; msg=$2; run=$3; shift 3
br=claude/ci-cp-$voie
M=/home/claude/moteurs
W=/tmp/k/ci/tree
rm -rf $W; mkdir -p $W/packages/aa_km1c2/bin $W/.github/workflows
cp $M/.github/workflows/ci-paquets.yml $W/.github/workflows/
cp /tmp/k/ci/pubspec.yaml $W/packages/aa_km1c2/
cp /tmp/k/ci/cli.dart $W/packages/aa_km1c2/bin/aa_km1c2_cli.dart
cp $run $W/packages/aa_km1c2/run.sh
mkdir -p $W/packages/aa_km1c2/reference && (cd $M/packages/kalis_adapt/reference && tar cf - --exclude=__pycache__ --exclude=.pytest_cache --exclude='fixtures/*.json' .) | (cd $W/packages/aa_km1c2/reference && tar xf -)
for f in "$@"; do cp -r $f $W/packages/aa_km1c2/; done
if [ -n "$AVEC_DART" ]; then
  mkdir -p $W/paquets
  for p in kalis_core kalis_plan kalis_adapt kalis_bench kalis_quest; do mkdir -p $W/paquets/$p && (cd $M/packages/$p && tar cf - --exclude=./reference --exclude=.dart_tool .) | (cd $W/paquets/$p && tar xf -); done
fi
cd $M
git fetch -q origin $br
export GIT_INDEX_FILE=/tmp/k/ci/index; rm -f $GIT_INDEX_FILE
export GIT_WORK_TREE=$W
git add -A -f . >/dev/null
tree=$(git write-tree)
unset GIT_WORK_TREE GIT_INDEX_FILE
c=$(git -c user.name=Claude -c user.email=noreply@anthropic.com commit-tree $tree -p $(git rev-parse FETCH_HEAD) -m "KM1c2 contrôle (dev) : $msg")
git push -q origin $c:refs/heads/$br
echo "pushed $c on $br"
