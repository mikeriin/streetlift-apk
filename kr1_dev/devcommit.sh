#!/bin/bash
# usage: devcommit.sh "message"  — commit de mise au point sur claude/ci-cp-a :
# arbre = packages/ de /home/claude/moteurs + /tmp/kr1/dev (workflow, scripts).
set -e
msg="$1"
W=/tmp/kr1/ci
cd /home/claude/streetlift-apk
git fetch -q origin claude/ci-cp-a
rm -rf $W; mkdir -p $W
export GIT_INDEX_FILE=/tmp/kr1/devindex; rm -f $GIT_INDEX_FILE
# packages depuis l'arbre de travail de moteurs (fichiers suivis + nouveaux non ignorés)
cd /home/claude/moteurs
git add -A packages >/dev/null 2>&1 || true
treeP=$(git write-tree --prefix=packages/)
unset GIT_INDEX_FILE
cd /home/claude/streetlift-apk
export GIT_INDEX_FILE=/tmp/kr1/devindex2; rm -f $GIT_INDEX_FILE
git read-tree --prefix=packages/ $treeP
for f in DEV_KR1.sh DEV_ASSEMBLER.sh DEV_PARTS; do
  h=$(git hash-object -w ${DEVDIR:-/tmp/kr1/dev}/$f); git update-index --add --cacheinfo 100644,$h,$f
done
h=$(git hash-object -w ${DEVDIR:-/tmp/kr1/dev}/ci-paquets.yml); git update-index --add --cacheinfo 100644,$h,.github/workflows/ci-paquets.yml
tree=$(git write-tree)
unset GIT_INDEX_FILE
c=$(git commit-tree $tree -p origin/claude/ci-cp-a -m "$msg")
git push -q origin $c:refs/heads/claude/ci-cp-a
echo "poussé $c"
