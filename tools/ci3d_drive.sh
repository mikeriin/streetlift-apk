#!/usr/bin/env bash
# DIAGNOSTIC UI1 (branche de contrôle seulement, jamais sur ui/UI1) :
# CI1g seul, partie b d'abord sur émulateur neuf, puis a, puis b ;
# journal complet gardé par partie (logcat -d, sans relance d'adb).
set -u
out=build/ci3d
mkdir -p "$out"
adb shell wm size 540x960 || true
adb shell wm density 240 || true
adb shell svc power stayon true || true
adb shell wm dismiss-keyguard || true
cible() {
  adb shell am force-stop fr.tchoupi.streetlift_tracker || true
  adb logcat -c || true
  timeout "${CI3D_DELAI:-600}" flutter drive --no-pub \
    --driver=test_driver/integration_test.dart \
    --target="integration_test/$1.dart" \
    ${2:+--dart-define=M6B_PART=$2} \
    ${3:+--dart-define=KALIS_DEV=true} \
    -d emulator-5554 > "$out/drive-$1-$2-$4.log" 2>&1
  c=$?
  adb logcat -d -v time > "$out/logcat-$2-$4.txt" 2>&1 || true
  adb shell cat /proc/meminfo > "$out/meminfo-$2-$4.txt" 2>&1 || true
  adb shell ls /data/tombstones > "$out/tombstones-$2-$4.txt" 2>&1 || true
  echo "partie $2 essai $4 : code $c" | tee -a "$out/diag.txt"
  return $c
}
code_ci1g=0
cible clearance_ci1g_test b dev 1 || code_ci1g=$?
cible clearance_ci1g_test a dev 2 || true
cible clearance_ci1g_test b dev 3 || code_ci1g=$?
code=0
code_mesure=0
echo "code_ci1g=$code_ci1g code_ci1f=0 code_ci1e=0 code_ci1c=0 code_ci1=0 code_cu=0 code_g10=0 code_g9=0 code_g7=0 code_g6=0 code_g5=0 code_g3=0 code_g2=0 code_g1=0 code_m8=0 code_m7=0" > "$out/drive-code.txt"
echo "code=$code" >> "$out/drive-code.txt"
echo "code_mesure=$code_mesure" >> "$out/drive-code.txt"
[ "$code_ci1g" -eq 0 ]
