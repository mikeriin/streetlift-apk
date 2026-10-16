cd packages/kalis_bench && dart pub get > /dev/null 2>&1
P=../../ci-out/packages/parts
dart run bin/km2.dart assembler --sortie ../../ci-out/packages/criteres_kr1v_g05.json $P/kr1v_partie_*_sur_6.json.gz | tail -40
python3 -I tool/kr1_securite.py --sortie ../../ci-out/packages/securite_kr1v_g05.json --md ../../ci-out/packages/SECURITE_KR1V_G05.md $P
