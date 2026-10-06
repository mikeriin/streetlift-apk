#!/bin/bash
# Sauvegarde CA2 : arbre de travail sans .github, + SAUVEGARDE.md, sur cp-sauvegardes/CA2
set -e
cd /home/claude/streetlift-apk
MSG="$1"
SC=/tmp/claude-0/-home-claude-streetlift-apk/351397e5-88e5-569f-a8b3-9fa6fbd5e6ad/scratchpad
export GIT_INDEX_FILE=$SC/save.index
rm -f $GIT_INDEX_FILE
git read-tree HEAD
git add -A .
git rm -r -q --cached .github 2>/dev/null || true
cp $SC/SAUVEGARDE.md /tmp/SAUVEGARDE.md.tmp
blob=$(git hash-object -w /tmp/SAUVEGARDE.md.tmp)
git update-index --add --cacheinfo 100644,$blob,SAUVEGARDE.md
tree=$(git write-tree)
unset GIT_INDEX_FILE
parent=$(git rev-parse -q --verify origin/cp-sauvegardes/CA2 || true)
if [ -n "$parent" ]; then c=$(git commit-tree $tree -p $parent -m "Sauvegarde CA2 : $MSG"); else c=$(git commit-tree $tree -m "Sauvegarde CA2 : $MSG"); fi
git push -q origin $c:refs/heads/cp-sauvegardes/CA2
git fetch -q origin cp-sauvegardes/CA2:refs/remotes/origin/cp-sauvegardes/CA2
echo "saved $c"
