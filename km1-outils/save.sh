#!/bin/bash
# Sauvegarde KM1 : arbre de travail de moteurs (sans .github) + km1-outils + SAUVEGARDE.md
# usage : save.sh "<étape>"
set -e
MSG=$1
WT=/home/claude/moteurs
REPO=/home/claude/streetlift-apk
T=/tmp/km1save
rm -rf $T && mkdir -p $T
(cd $WT && git ls-files -co --exclude-standard -z | xargs -0 cp --parents -t $T/)
rm -rf $T/.github
mkdir -p $T/km1-outils
(cd /home/claude/km1-outils && find . -type f -size -20M -not -path './tmp/*' -not -name '*.pyc' -print0 | xargs -0 cp --parents -t $T/km1-outils/)
cp /home/claude/km1-outils/SAUVEGARDE.md $T/SAUVEGARDE.md
export GIT_INDEX_FILE=/tmp/km1save.index
rm -f $GIT_INDEX_FILE
cd $REPO
git --work-tree=$T add -A . >/dev/null
TREE=$(git write-tree)
unset GIT_INDEX_FILE
PARENT=""
if git fetch -q origin cp-sauvegardes/KM1 2>/dev/null; then PARENT="-p FETCH_HEAD"; fi
C=$(git commit-tree $TREE $PARENT -m "Sauvegarde KM1 : $MSG")
git push -q origin $C:refs/heads/cp-sauvegardes/KM1
echo "sauvegardé $C"
