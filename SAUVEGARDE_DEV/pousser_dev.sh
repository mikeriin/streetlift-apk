#!/bin/bash
# Commit de contrôle (dev) KM2c3 sur claude/ci-cp-a : arbre de travail + workflow et scripts de dev.
set -e
cd /home/claude/streetlift-apk
msg="$1"
git fetch -q origin claude/ci-cp-a
export GIT_INDEX_FILE=/tmp/claude-0/idx-dev
rm -f $GIT_INDEX_FILE
git read-tree HEAD
git add -A .
for f in DEV_KM2C3.sh DEV_PARTS DEV_ASSEMBLER.sh DEV_LISTE_C7.py; do
  h=$(git hash-object -w /tmp/claude-0/dev/$f); git update-index --add --cacheinfo 100644,$h,$f
done
h=$(git hash-object -w /tmp/claude-0/dev/ci-paquets.yml); git update-index --add --cacheinfo 100644,$h,.github/workflows/ci-paquets.yml
tree=$(git write-tree)
c=$(git commit-tree $tree -p origin/claude/ci-cp-a -m "$msg")
unset GIT_INDEX_FILE
git push -q origin $c:refs/heads/claude/ci-cp-a
echo "poussé $c"
