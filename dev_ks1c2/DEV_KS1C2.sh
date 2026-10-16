#!/bin/bash
# Mise au point KS1c2, run 6.
root=$PWD; out=$root/out-packages; status=0
for n in kalis_plan kalis_bench; do
  (cd packages/$n && dart pub get) > $out/pub_$n.log 2>&1 || { echo "pub get $n échec"; tail -30 $out/pub_$n.log; exit 1; }
done
for n in kalis_plan kalis_bench; do
  (cd packages/$n && dart format . > /dev/null); git diff -- packages/$n > $out/format_$n.patch
  echo "format $n : $(wc -l < $out/format_$n.patch) lignes"
  (cd packages/$n && dart analyze --fatal-infos) > $out/analyze_$n.log 2>&1 || { echo "analyse $n : échec"; status=1; }
  tail -15 $out/analyze_$n.log
done
git checkout -- packages
(cd packages/kalis_plan && dart test --reporter expanded test/ks1c2_test.dart test/coach_test.dart test/structure_test.dart test/docs_test.dart test/smoke_test.dart) > $out/tests_plan.log 2>&1 || { echo "tests kalis_plan : échec"; status=1; }
grep -E "\[E\]|Some tests failed|All tests passed|Expected|Actual|Which" $out/tests_plan.log | head -60
(cd packages/kalis_bench && dart test --reporter expanded test/ks1c2_test.dart test/structure_test.dart) > $out/tests_bench.log 2>&1 || { echo "tests kalis_bench : échec"; status=1; }
grep -E "\[E\]|Some tests failed|All tests passed|Expected|Actual|Which" $out/tests_bench.log | head -40
cd packages/kalis_bench
dart run bin/ks1c2_diag.dart $out/diag_apres.md --complet > $out/diag_apres.log 2>&1 || { echo "diag après : échec"; status=1; }
tail -5 $out/diag_apres.log
sed -n '/# Douleurs/,$p' $out/diag_apres.md
cd $root
git fetch -q --depth=1 origin eae158b82cc369ffdad76bfd9f8b835a5c762e8b && git checkout FETCH_HEAD -- packages/kalis_plan || echo "checkout 0.4.1 échec"
cd packages/kalis_bench
dart run bin/ks1c2_diag.dart $out/diag_avant.md --complet > $out/diag_avant.log 2>&1 || { echo "diag avant : échec"; status=1; }
tail -5 $out/diag_avant.log
python3 - "$out" <<'PY'
import json,sys
o=sys.argv[1]
a=json.load(open(o+'/diag_avant.md.signatures.json')); b=json.load(open(o+'/diag_apres.md.signatures.json'))
diff=[k for k in a if a[k]!=b.get(k)]
print('squelettes différents de 0.4.1 :', len(diff), diff)
PY
exit $status
