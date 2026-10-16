#!/bin/bash
# Mise au point KS1c2, run 1 : diagnostic avant correction (kalis_plan 0.4.1).
root=$PWD; out=$root/out-packages; status=0
cd packages/kalis_bench
dart pub get > $out/pub.log 2>&1 || { echo "pub get échec"; tail -30 $out/pub.log; exit 1; }
dart analyze --fatal-infos lib bin/ks1c2_diag.dart > $out/analyze.log 2>&1 || { echo "analyse : échec"; status=1; }
tail -20 $out/analyze.log
dart format --output=none --set-exit-if-changed lib bin > $out/format.log 2>&1 || { echo "format : à corriger"; cat $out/format.log | head; }
time dart run bin/ks1c2_diag.dart $out/diag_avant.md --complet > $out/diag.log 2>&1 || { echo "diag : échec"; status=1; }
tail -40 $out/diag.log
exit $status
