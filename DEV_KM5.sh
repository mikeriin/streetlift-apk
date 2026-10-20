#!/bin/bash
# Mise au point KM5, run A : Koach 1.0.7 (kalis_adapt 1.0.6, kalis_bench 0.5.8) — compilation et tests.
#  PART 0 : tests Python de la référence ; format (patch) et analyse de kalis_adapt et kalis_bench
#  PART 1 : dart test de kalis_adapt
#  PART 2 : dart test de kalis_bench
root=$PWD
out=$root/out-packages
status=0
A=$root/packages/kalis_adapt
B=$root/packages/kalis_bench
R=$A/reference
for name in kalis_adapt kalis_bench; do (cd packages/$name && dart pub get) > $out/$name-pub-$PART.log 2>&1 || { echo "pub get $name échec"; tail -20 $out/$name-pub-$PART.log; status=1; }; done
if [ "$PART" = 0 ]; then
  (cd $R && python3 -m pytest tests -q -p no:cacheprovider) > $out/pytest.log 2>&1 || { echo "pytest : échec"; status=1; }
  tail -30 $out/pytest.log
  for name in kalis_adapt kalis_bench; do
    (cd packages/$name && dart format --output=none --set-exit-if-changed .) > $out/format-$name.log 2>&1 || { echo "format $name : échec"; (cd packages/$name && dart format . >/dev/null; git diff --relative) > $out/format-$name.patch; status=1; }
    (cd packages/$name && git checkout -q -- . ) 2>/dev/null
    (cd packages/$name && dart analyze --fatal-infos) > $out/analyze-$name.log 2>&1 || { echo "analyse $name : échec"; tail -60 $out/analyze-$name.log; status=1; }
  done
elif [ "$PART" = 1 ]; then
  (cd $A && dart test --reporter expanded) > $out/kalis_adapt-test.log 2>&1 || { echo "tests kalis_adapt : échec"; status=1; }
  grep -E "\[E\]|Some tests failed|All tests passed|Expected|Actual|Error" $out/kalis_adapt-test.log | tail -80
elif [ "$PART" = 2 ]; then
  (cd $B && dart test --reporter expanded) > $out/kalis_bench-test.log 2>&1 || { echo "tests kalis_bench : échec"; status=1; }
  grep -E "\[E\]|Some tests failed|All tests passed|Expected|Actual|Error" $out/kalis_bench-test.log | tail -80
fi
exit $status
