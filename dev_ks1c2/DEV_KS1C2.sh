#!/bin/bash
# Mise au point KS1c2, run 12 : violations des saisons sous douleur, 0.4.2 contre 0.4.1.
root=$PWD; out=$root/out-packages; status=0
for n in kalis_plan kalis_bench kalis_adapt; do
  (cd packages/$n && dart pub get) > $out/pub_$n.log 2>&1 || { echo "pub get $n échec"; exit 1; }
done
cd packages/kalis_bench
dart run bin/ks1c2_vol.dart $out/vol_042.json > $out/vol_042.log 2>&1 || { echo "vol 0.4.2 échec"; tail -30 $out/vol_042.log; status=1; }
cat $out/vol_042.log | tail -8
cd $root
git fetch -q --depth=1 origin eae158b82cc369ffdad76bfd9f8b835a5c762e8b && git checkout FETCH_HEAD -- packages/kalis_plan
cd packages/kalis_bench
dart run bin/ks1c2_vol.dart $out/vol_041.json > $out/vol_041.log 2>&1 || { echo "vol 0.4.1 échec"; tail -30 $out/vol_041.log; status=1; }
cat $out/vol_041.log | tail -8
exit $status
