#!/bin/bash
# récupère les archives de campagne des deux branches de contrôle dans /tmp/km1-campagne
cd /home/claude/moteurs
for v in a b; do
  git fetch -q origin claude/ci-cp-$v
  git log --oneline -1 FETCH_HEAD
  for f in $(git ls-tree -r --name-only FETCH_HEAD ci-out/packages/aa_km1c2 2>/dev/null | grep "tar.xz$"); do
    git show FETCH_HEAD:$f > /tmp/k/$(basename $f)
    (cd /tmp/km1-campagne && tar xJf /tmp/k/$(basename $f)) && echo "extrait $f"
  done
  git show FETCH_HEAD:ci-out/packages/aa_km1c2.log 2>/dev/null | grep -E "partie|durée|plant" | tail -3
done
