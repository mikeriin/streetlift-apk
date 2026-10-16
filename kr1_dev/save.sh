#!/bin/bash
# usage: save.sh "étape" — sauvegarde de /home/claude/moteurs (sans .github) + /tmp/kr1/dev + SAUVEGARDE.md
set -e
cd /home/claude/moteurs
export GIT_INDEX_FILE=/tmp/kr1/saveindex; rm -f $GIT_INDEX_FILE
git add -A . >/dev/null 2>&1
git rm -r -q --cached .github >/dev/null 2>&1 || true
for f in /tmp/kr1/dev/*; do h=$(git hash-object -w $f); git update-index --add --cacheinfo 100644,$h,kr1_dev/$(basename $f); done
for f in /tmp/kr1/devcommit.sh /tmp/kr1/save.sh; do h=$(git hash-object -w $f); git update-index --add --cacheinfo 100644,$h,kr1_dev/$(basename $f); done
h=$(git hash-object -w /tmp/kr1/SAUVEGARDE.md); git update-index --add --cacheinfo 100644,$h,SAUVEGARDE.md
tree=$(git write-tree); unset GIT_INDEX_FILE
parent=$(git rev-parse -q --verify origin/cp-sauvegardes/KR1 2>/dev/null || true)
if [ -n "$parent" ]; then c=$(git commit-tree $tree -p $parent -m "Sauvegarde KR1 : $1"); else c=$(git commit-tree $tree -m "Sauvegarde KR1 : $1"); fi
git push -q origin $c:refs/heads/cp-sauvegardes/KR1 && git fetch -q origin cp-sauvegardes/KR1
echo "sauvegarde $c"
