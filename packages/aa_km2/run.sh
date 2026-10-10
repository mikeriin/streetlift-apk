#!/bin/bash
R=$(cd "$1" && pwd)
H=$(pwd)
dart --version > "$R/version.txt" 2>&1
cd ../kalis_adapt
dart pub get > /dev/null 2>&1
dart format lib test bin tool > "$R/format.txt" 2>&1
mkdir -p "$R/fmt/lib" "$R/fmt/test"
cp -r lib/src/koach "$R/fmt/lib/"
cp lib/koach.dart "$R/fmt/lib/"
cp test/koach_*.dart "$R/fmt/test/" 2>/dev/null
if [ -d ../kalis_bench ]; then (cd ../kalis_bench && dart pub get >/dev/null 2>&1; dart format lib test bin > "$R/format_bench.txt" 2>&1; mkdir -p "$R/fmt/bench"; cp -r lib bin test "$R/fmt/bench/"); fi
if [ -f "$H/extra.sh" ]; then bash "$H/extra.sh" "$R" > "$R/extra.txt" 2>&1; fi
exit 0
