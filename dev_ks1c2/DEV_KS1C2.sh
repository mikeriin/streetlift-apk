#!/bin/bash
# Mise au point KS1c2, run 11 : arbre rebasé ; test KR1 de la saison de référence.
root=$PWD; out=$root/out-packages; status=0
for n in kalis_plan kalis_bench kalis_adapt; do
  (cd packages/$n && dart pub get) > $out/pub_$n.log 2>&1 || { echo "pub get $n échec"; exit 1; }
done
(cd packages/kalis_bench && dart format . >/dev/null && git diff --stat -- . ; git checkout -- .)
(cd packages/kalis_bench && dart analyze --fatal-infos) > $out/analyze_bench.log 2>&1 || { echo "analyse bench : échec"; tail -20 $out/analyze_bench.log; status=1; }
(cd packages/kalis_bench && dart test --reporter expanded test/km2_banc_test.dart test/km_export_test.dart test/ks1c2_test.dart test/bench_test.dart) > $out/tests_bench.log 2>&1 || { echo "tests bench : échec"; status=1; }
grep -E "\[E\]|Some tests failed|All tests passed|Expected|Actual" $out/tests_bench.log | cut -c1-300 | head -40
exit $status
