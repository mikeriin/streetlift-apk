#!/bin/bash
# Contrôle complet : arbre entier de /home/claude/moteurs (workflow standard) sur claude/ci-cp-a.
set -e
cd /home/claude/moteurs
export GIT_INDEX_FILE=/tmp/kr1/ctrlindex; rm -f $GIT_INDEX_FILE
git read-tree HEAD
git add -A . >/dev/null 2>&1
tree=$(git write-tree); unset GIT_INDEX_FILE
echo "arbre $tree"
cd /home/claude/streetlift-apk && git fetch -q origin claude/ci-cp-a
c=$(git commit-tree $tree -p origin/claude/ci-cp-a -m "$1")
git push -q origin $c:refs/heads/claude/ci-cp-a && echo "poussé $c"
