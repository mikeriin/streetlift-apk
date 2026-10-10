#!/bin/bash
R=$1
cd ../kalis_bench
dart pub get > /dev/null 2>&1
s=$(date +%s)
dart run bin/km2.dart --profils street_07_avance_streetlifting_competition --scenarios reference --verites a --graines 1 --coeurs 1 --sortie "$R/probe.json" --sans-determinisme > "$R/probe.log" 2>&1
echo "probe: $(( $(date +%s) - s )) s, code $?" >> "$R/probe.log"
nproc >> "$R/probe.log"
