#!/bin/bash
# Mise au point KM5, run C : formatage (patch) et analyse de kalis_adapt et kalis_bench ; échecs pytest listés.
root=$PWD
out=$root/out-packages
status=0
for name in kalis_adapt kalis_bench; do (cd packages/$name && dart pub get) > $out/$name-pub.log 2>&1; done
for name in kalis_adapt kalis_bench; do
  (cd packages/$name && dart format --output=none --set-exit-if-changed .) > $out/format-$name.log 2>&1 || { echo "format $name : échec"; (cd packages/$name && dart format . >/dev/null; git diff --relative) > $out/format-$name.patch; cat $out/format-$name.patch; status=1; }
  (cd packages/$name && git checkout -q -- . ) 2>/dev/null
  (cd packages/$name && dart analyze --fatal-infos) > $out/analyze-$name.log 2>&1 || { echo "analyse $name : échec"; tail -60 $out/analyze-$name.log; status=1; }
done
(cd packages/kalis_adapt/reference && python3 -m pytest tests -q -p no:cacheprovider -x --deselect tests/test_fixtures.py) > $out/pytest.log 2>&1 || { echo "pytest : échec"; status=1; }
tail -5 $out/pytest.log
exit $status
