#!/bin/bash
# Mise au point KM4, run H : tous les tests de kalis_bench sur l'arbre final (le contrôle complet 39363143851 a
# échoué sur km2_adversaire_test : sortie Python de evaluer_saison de adv-7ee0da71 recalculée par la référence 1.0.6).
root=$PWD
out=$root/out-packages
status=0
for name in kalis_adapt kalis_bench; do (cd packages/$name && dart pub get) > $out/$name-pub-0.log 2>&1 || { echo "pub get $name échec"; status=1; }; done
(cd packages/kalis_bench && dart format --output=none --set-exit-if-changed . && dart analyze) > $out/kalis_bench-analyse.log 2>&1 || { echo "format/analyse kalis_bench : échec"; status=1; }
(cd packages/kalis_bench && dart test --reporter expanded) > $out/kalis_bench-test.log 2>&1 || { echo "tests kalis_bench : échec"; status=1; }
tail -4 $out/kalis_bench-test.log
exit $status
