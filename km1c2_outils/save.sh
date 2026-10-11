#!/bin/bash
# usage: save.sh "étape"   (SAUVEGARDE.md lu depuis /tmp/k/SAUVEGARDE.md)
set -e
cd /home/claude/moteurs
cp /tmp/k/SAUVEGARDE.md SAUVEGARDE.md
mkdir -p km1c2_outils && cp /tmp/k/*.py /tmp/k/*.sh km1c2_outils/ 2>/dev/null || true; mkdir -p km1c2_outils/ci && cp /tmp/k/ci/*.sh /tmp/k/ci/*.yaml /tmp/k/ci/*.dart /tmp/k/ci/*.txt km1c2_outils/ci/ 2>/dev/null || true
export GIT_INDEX_FILE=/tmp/k/save.index
rm -f $GIT_INDEX_FILE
git read-tree HEAD
git add -A . >/dev/null 2>&1
git rm -r -q --cached .github >/dev/null 2>&1 || true
tree=$(git write-tree)
git fetch -q origin cp-sauvegardes/KM1c2 2>/dev/null && parent="-p $(git rev-parse FETCH_HEAD)" || parent=""
c=$(git -c user.name=Claude -c user.email=noreply@anthropic.com commit-tree $tree $parent -m "Sauvegarde KM1c2 : $1")
git push -q origin $c:refs/heads/cp-sauvegardes/KM1c2
unset GIT_INDEX_FILE
rm -f SAUVEGARDE.md; rm -rf km1c2_outils
echo saved $c
