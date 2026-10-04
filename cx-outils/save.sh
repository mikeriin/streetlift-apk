#!/bin/bash
# Sauvegarde du lot CX sur cp-sauvegardes/CX (arbre sans .github/).
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
cp -r /home/claude/cx/page /home/claude/cx/fmtsync.py /home/claude/cx/panel.py /home/claude/cx/ci.sh /home/claude/cx/save.sh /home/claude/cx/aa_fmt $T/cx-outils/
[ -d /home/claude/cx/notes ] && cp -r /home/claude/cx/notes $T/cx-outils/ || true
[ -d /home/claude/cx/docs ] && cp -r /home/claude/cx/docs $T/cx-outils/ || true
cp /home/claude/cx/SAUVEGARDE.md $T/SAUVEGARDE.md
export GIT_INDEX_FILE=/tmp/cxsave.index
rm -f $GIT_INDEX_FILE
cd $REPO
git --work-tree=$T add -A . >/dev/null
TREE=$(git write-tree)
unset GIT_INDEX_FILE
if git fetch -q origin cp-sauvegardes/CX 2>/dev/null; then
  C=$(git commit-tree $TREE -p FETCH_HEAD -m "Sauvegarde CX : $MSG")
else
  C=$(git commit-tree $TREE -m "Sauvegarde CX : $MSG")
fi
git push -q origin $C:refs/heads/cp-sauvegardes/CX
echo "sauvegarde $C"
