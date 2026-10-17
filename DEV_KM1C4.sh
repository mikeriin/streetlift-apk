#!/bin/bash
# Mise au point KM1c4, runs E à H (export 0.4.2 (PART 0) ; campagne Python de la référence 1.0.5 après relecture sur les 100 graines, 20 parts (61-80)).
#  PART 0     : export KM1 sur kalis_plan 0.4.2 (34 profils, témoin 16 graines) ; données neuves
#               mises à la place de celles de 0.4.1 dans l'arbre de la CI ; sécurité des blocs ;
#               tests Python de la référence ; tests km de kalis_bench (version de référence 0.4.2)
#  PART 1-34  : campagne Dart du couple kalis_plan 0.4.2 × Koach 1.0.4 (kalis_adapt 1.0.3),
#               groupe g = (PART+1)/2 (graines 6(g-1)..6g-1 ; 17 : 96-99), part h = 1 + (PART+1)%2 sur 2 ;
#               saisons vivantes, témoin de 0.4.1 lu
#  PART 41-48 : campagne Python (référence 1.0.5 en cours) graines 0-5, parts 1/8..8/8, sur les saisons de
#               kalis_plan 0.4.2 (export rapide sans témoin dans la part), témoin de 0.4.1 lu
#  PART 61-80 : campagne Python (référence 1.0.5) graines 0-99, parts 1/20..20/20, mêmes saisons 0.4.2
#               (run H : règle 3 bis, rampe de retour après une coupure ; arbre portant déjà les données 0.4.2)
#  PART 81-84 : run F : les parts 13/20 et 20/20 du run E (restées en file derrière la limite de 20 jobs)
#               refaites en quatre demi-parts 13/40, 33/40, 20/40, 40/40 (même matrice, même empreinte) ;
#               la publication du run F réunit ses parts et les artefacts du run E (39016950696) — run F annulé,
#               les parts 73 et 80 ayant démarré dès l'annulation forcée des publications des runs B, C, D
#  PART 99    : run G : attend la fin du run E (gh api), ne calcule rien ; la publication du run G réunit les
#               artefacts du run E (20 parts) et les assemble sur l'arbre portant les données 0.4.2 (témoin
#               0.4.2 : les cinq saisons « douleur à l'épaule » du témoin changent avec kalis_plan 0.4.2)
root=$PWD
out=$root/out-packages
status=0
B=$root/packages/kalis_bench
R=$root/packages/kalis_adapt/reference
for name in kalis_adapt kalis_bench; do
  (cd packages/$name && dart pub get) > $out/$name-pub-$PART.log 2>&1 || { echo "pub get $name échec"; tail -30 $out/$name-pub-$PART.log; status=1; }
done
if [ "$PART" = 0 ]; then
  cd $B
  start=$(date +%s)
  dart run bin/km1.dart --sortie $out/km1 --sans-securite --sans-adversaires > $out/km1_export.log 2>&1 || { echo "export km1 : échec"; status=1; }
  tail -5 $out/km1_export.log; echo "export : $(( $(date +%s) - start )) s"
  # Données neuves à la place de celles de 0.4.1 (dans l'arbre de la CI seulement).
  rm -rf $R/donnees/reference $R/donnees/temoin
  cp -r $out/km1/reference $out/km1/temoin $R/donnees/
  cp $out/km1/catalogue_infos.json.gz $out/km1/traces_verite.json.gz $out/km1/traces_endurance.json.gz $R/donnees/
  rm -rf km1_entree/securite
  (cd $R && python3 -m banc.securite_banc --entrees-dart $B/km1_entree/securite) | tail -2
  dart run bin/km1.dart --sortie $out/km1 --outils-seuls --sans-adversaires > $out/km1_securite.log 2>&1 || { echo "sécurité de blocs : échec"; status=1; }
  tail -3 $out/km1_securite.log
  cp $out/km1/securite_dart.json.gz $R/donnees/
  # Ce qui diffère de 0.4.1 (saisons de référence et témoin) : liste des fichiers changés.
  cd $root
  git status --porcelain -- $R/donnees > $out/km1_diff_0_4_1.txt; wc -l < $out/km1_diff_0_4_1.txt
  cd $R
  python3 -m pytest tests -q > $out/pytest.log 2>&1 || echo "pytest : échec"
  tail -30 $out/pytest.log
  cd $root
  sed -i "s/const String _planReference = '0.4.1';/const String _planReference = '0.4.2';/" packages/kalis_bench/test/km2_banc_test.dart
  (cd packages/kalis_bench && dart test --reporter expanded test/km2_banc_test.dart test/km_export_test.dart) > $out/kalis_bench-test.log 2>&1 || { echo "tests kalis_bench km : échec"; status=1; }
  grep -E "\[E\]|Some tests failed|All tests passed" $out/kalis_bench-test.log | tail -30
elif [ "$PART" -ge 41 ] && [ "$PART" -le 48 ]; then
  i=$((PART-40))
  cd $B
  start=$(date +%s)
  dart run bin/km1.dart --sortie $out/km1s --sans-temoin --sans-securite --sans-adversaires > $out/km1_export_$i.log 2>&1 || { echo "export km1 (saisons) : échec"; status=1; }
  echo "export saisons : $(( $(date +%s) - start )) s"; tail -2 $out/km1_export_$i.log
  rm -rf $R/donnees/reference && cp -r $out/km1s/reference $R/donnees/
  cp $out/km1s/catalogue_infos.json.gz $out/km1s/traces_verite.json.gz $out/km1s/traces_endurance.json.gz $R/donnees/
  rm -rf $out/km1s
  cd $R
  python3 -m banc.campagne --graines 6 --coeurs 4 --partie $i/8 --travail $out/py_travail > $out/py_campagne_$i.log 2>&1 || { echo "campagne python $i : échec"; status=1; }
  tail -4 $out/py_campagne_$i.log
elif [ "$PART" -ge 61 ] && [ "$PART" -le 84 ]; then
  if [ "$PART" -le 80 ]; then i=$((PART-60)); n=20; else case $PART in 81) i=13;; 82) i=33;; 83) i=20;; 84) i=40;; esac; n=40; fi
  cd $B
  start=$(date +%s)
  dart run bin/km1.dart --sortie $out/km1s --sans-temoin --sans-securite --sans-adversaires > $out/km1_export_c$i.log 2>&1 || { echo "export km1 (saisons) : échec"; status=1; }
  echo "export saisons : $(( $(date +%s) - start )) s"; tail -2 $out/km1_export_c$i.log
  rm -rf $R/donnees/reference && cp -r $out/km1s/reference $R/donnees/
  cp $out/km1s/catalogue_infos.json.gz $out/km1s/traces_verite.json.gz $out/km1s/traces_endurance.json.gz $R/donnees/
  rm -rf $out/km1s
  cd $R
  python3 -m banc.campagne --graines 100 --coeurs 4 --partie $i/$n --travail $out/py_travail > $out/py_campagne_c${i}_sur_$n.log 2>&1 || { echo "campagne python 100 graines $i/$n : échec"; status=1; }
  tail -3 $out/py_campagne_c${i}_sur_$n.log
elif [ "$PART" = 99 ]; then
  st=""
  for k in $(seq 1 330); do
    st=$(gh api repos/$GITHUB_REPOSITORY/actions/runs/$RUN_PRECEDENT --jq .status 2>/dev/null)
    [ "$st" = completed ] && break
    sleep 60
  done
  echo "run $RUN_PRECEDENT : $st ($(date -u +%H:%M))"
  [ "$st" = completed ] || status=1
elif [ "$PART" -le 34 ]; then
  g=$(( (PART + 1) / 2 )); h=$(( 2 - PART % 2 ))
  a=$(( 6 * (g - 1) )); b=$(( a + 5 )); [ $b -gt 99 ] && b=99
  cd $B
  mkdir -p $out/parts
  extra=""; [ "$g" != 1 ] && extra="--sans-determinisme"
  dart run bin/km2.dart --graines $a-$b --coeurs 4 $extra --temoin $R/donnees/temoin --partie $h/2 --sortie $out/parts/km1c4d_g${a}_${b}_partie_${h}_sur_2.json.gz > $out/campagne_${a}_${b}_$h.log 2>&1 || { echo "campagne $a-$b part $h : échec"; status=1; }
  tail -4 $out/campagne_${a}_${b}_$h.log
fi
exit $status
