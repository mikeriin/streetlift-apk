#!/bin/bash
# Contrôle CA2 sur claude/ci-cp-b. Usage : ci.sh dev|full "message"
set -e
cd /home/claude/streetlift-apk
MODE="$1"; MSG="$2"
SC=/tmp/claude-0/-home-claude-streetlift-apk/fb3f5782-2059-511f-a7e8-9d18405dd101/scratchpad
export GIT_INDEX_FILE=$SC/ci.index
rm -f $GIT_INDEX_FILE
git read-tree HEAD
git add -A .
git rm -r -q --cached ci-out 2>/dev/null || true
git rm -r -q --cached ca2-outils 2>/dev/null || true
if [ "$MODE" = dev ]; then
  git rm -r -q --cached packages/kalis_quest 2>/dev/null || true
  for f in $(git ls-tree -r --name-only 6da3c852 packages/aa_fmt); do
    git update-index --add --cacheinfo 100644,$(git rev-parse 6da3c852:$f),$f
  done
  four=$(printf '4\n' | git hash-object -w --stdin)
  git update-index --add --cacheinfo 100644,$four,packages/kalis_bench/season_seeds.txt
  git update-index --add --cacheinfo 100644,$four,packages/kalis_bench/campaign_seeds.txt
fi
tree=$(git write-tree)
unset GIT_INDEX_FILE
git fetch -q origin claude/ci-cp-b
c=$(git commit-tree $tree -p origin/claude/ci-cp-b -m "CA2 contrôle ($MODE) : $MSG")
git push -q origin $c:refs/heads/claude/ci-cp-b
echo "pushed $c"
