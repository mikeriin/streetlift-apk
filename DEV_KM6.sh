#!/bin/bash
# Mise au point KM6, run B0 : cache pub des paquets (pour la mise au point locale), analyse et format de l'arbre.
#  PART 90 : dart pub get des quatre paquets, archive du cache pub (hosted) et version du SDK
#  PART 64 : format et analyse de kalis_plan, kalis_adapt, kalis_bench (patchs)
root=$PWD
out=$root/out-packages
status=0
for name in kalis_core kalis_plan kalis_adapt kalis_bench; do
  (cd packages/$name && dart pub get) > $out/$name-pub-$PART.log 2>&1 || { echo "pub get $name échec"; tail -30 $out/$name-pub-$PART.log; status=1; }
done
if [ "$PART" = 90 ]; then
  dart --version > $out/dart_version.txt 2>&1; cat $out/dart_version.txt
  c=${PUB_CACHE:-$HOME/.pub-cache}; echo "cache : $c"; ls $c
  mkdir -p $out/pubcache
  tar -czf $out/pubcache/hosted.tar.gz -C $c hosted
  ls -la $out/pubcache
  for name in kalis_core kalis_plan kalis_adapt kalis_bench; do cp packages/$name/pubspec.lock $out/pubcache/$name.pubspec.lock 2>/dev/null; done
elif [ "$PART" = 64 ]; then
  for name in kalis_plan kalis_adapt kalis_bench; do
    (cd packages/$name && dart format --output=none --set-exit-if-changed .) > $out/format-$name.log 2>&1 || { echo "format $name : échec"; (cd packages/$name && dart format . >/dev/null; git diff --relative) > $out/format-$name.patch; status=1; }
    (cd packages/$name && git checkout -q -- . ) 2>/dev/null
    (cd packages/$name && dart analyze --fatal-infos) > $out/analyze-$name.log 2>&1 || { echo "analyse $name : échec"; tail -60 $out/analyze-$name.log; status=1; }
  done
fi
exit $status
