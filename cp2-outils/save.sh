#!/bin/bash
# Sauvegarde CP2 sur cp-sauvegardes/CP2 (arbre sans .github/). usage : save.sh "<étape>"
set -e
MSG=$1
WT=/home/claude/moteurs
REPO=/home/claude/streetlift-apk
T=/tmp/cp2save
rm -rf $T && mkdir -p $T
(cd $WT && git ls-files -co --exclude-standard -z | xargs -0 cp --parents -t $T/)
rm -rf $T/.github
mkdir -p $T/cp2-outils
for f in page fmtsync.py panel.py ci.sh save.sh aa_fmt notes docs; do
  [ -e /home/claude/cp2/$f ] && cp -r /home/claude/cp2/$f $T/cp2-outils/ || true
done
cp /home/claude/cp2/SAUVEGARDE.md $T/SAUVEGARDE.md
export GIT_INDEX_FILE=/tmp/cp2save.index
rm -f $GIT_INDEX_FILE
cd $REPO
git --work-tree=$T add -A . >/dev/null
TREE=$(git write-tree)
unset GIT_INDEX_FILE
if git fetch -q origin cp-sauvegardes/CP2 2>/dev/null; then
  C=$(git commit-tree $TREE -p FETCH_HEAD -m "Sauvegarde CP2 : $MSG")
else
  C=$(git commit-tree $TREE -m "Sauvegarde CP2 : $MSG")
fi
git push -q origin $C:refs/heads/cp-sauvegardes/CP2
echo "sauvegarde $C"
