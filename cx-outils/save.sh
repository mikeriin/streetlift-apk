#!/bin/bash
# Sauvegarde de CX correction 1 sur cp-sauvegardes/CX-c1 (arbre sans .github/).
# usage : save.sh "<étape>"
set -e
MSG=$1
WT=/home/claude/moteurs
REPO=/home/claude/streetlift-apk
T=/tmp/cxsave
rm -rf $T && mkdir -p $T
(cd $WT && git ls-files -co --exclude-standard -z | xargs -0 cp --parents -t $T/)
rm -rf $T/.github
mkdir -p $T/cx-outils
for f in page fmtsync.py panel.py ci.sh save.sh aa_fmt notes docs; do
  [ -e /home/claude/cx/$f ] && cp -r /home/claude/cx/$f $T/cx-outils/ || true
done
cp /home/claude/cx/SAUVEGARDE.md $T/SAUVEGARDE.md
export GIT_INDEX_FILE=/tmp/cxsave.index
rm -f $GIT_INDEX_FILE
cd $REPO
git --work-tree=$T add -A . >/dev/null
TREE=$(git write-tree)
unset GIT_INDEX_FILE
if git fetch -q origin cp-sauvegardes/CX-c1 2>/dev/null; then
  C=$(git commit-tree $TREE -p FETCH_HEAD -m "Sauvegarde CX-c1 : $MSG")
else
  C=$(git commit-tree $TREE -m "Sauvegarde CX-c1 : $MSG")
fi
git push -q origin $C:refs/heads/cp-sauvegardes/CX-c1
echo "sauvegarde $C"
