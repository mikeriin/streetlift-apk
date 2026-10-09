#!/bin/bash
# Sauvegarde CY sur cp-sauvegardes/CY (arbre sans .github/). usage : save.sh "<étape>"
set -e
MSG=$1
WT=/home/claude/mot
REPO=/home/claude/streetlift-apk
T=/tmp/cysave
rm -rf $T && mkdir -p $T
(cd $WT && git ls-files -co --exclude-standard -z | xargs -0 cp --parents -t $T/)
rm -rf $T/.github
mkdir -p $T/cy-outils
for f in aa_fmt tools notes ci.sh fmtsync.py panel.py save.sh SAUVEGARDE.md; do
  [ -e /home/claude/cy/$f ] && cp -r /home/claude/cy/$f $T/cy-outils/ || true
done
cp /home/claude/cy/SAUVEGARDE.md $T/SAUVEGARDE.md
export GIT_INDEX_FILE=/tmp/cysave.index
rm -f $GIT_INDEX_FILE
cd $REPO
git --work-tree=$T add -A . >/dev/null
TREE=$(git write-tree)
unset GIT_INDEX_FILE
if git fetch -q origin cp-sauvegardes/CY 2>/dev/null; then
  C=$(git commit-tree $TREE -p FETCH_HEAD -m "Sauvegarde CY : $MSG")
else
  C=$(git commit-tree $TREE -m "Sauvegarde CY : $MSG")
fi
git push -q origin $C:refs/heads/cp-sauvegardes/CY
echo "sauvegarde $C"
