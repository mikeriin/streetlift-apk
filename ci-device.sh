#!/usr/bin/env bash
# Branche temporaire : manches alternées base / candidate sur l'émulateur.
set -uo pipefail
root="$(pwd)"
out="$root/$DEVICE_OUT"
mkdir -p "$out"
tools="$root/streetlift_tracker/tools/perf_device"
{
  adb devices -l
  adb shell getprop ro.build.version.release
  adb shell getprop ro.product.cpu.abi
  adb shell getprop ro.kernel.qemu
  adb shell dumpsys display | grep -m3 -E "mRefreshRate|refreshRate|fps" || true
  adb shell cat /proc/cpuinfo | grep -m1 "model name" || true
  adb shell cat /proc/meminfo | head -2
} > "$out/emulator.txt" 2>&1
rounds="${DEVICE_ROUNDS:-2}"
for r in $(seq 1 "$rounds"); do
  if [ $((r % 2)) -eq 1 ]; then order="base cand"; else order="cand base"; fi
  for side in $order; do
    dir="$root/streetlift_tracker"; [ "$side" = base ] && dir="$root/baseline/streetlift_tracker"
    bash "$tools/cold_start.sh" "$root/apk/$side.apk" "$side-r$r" "$out" 10 > /dev/null 2>&1
    echo "$side r$r coldstart exit=$?" >> "$out/runs.txt"
    APK_IN="$root/apk/bench-$side.apk" timeout 1800 bash "$tools/run_device_bench.sh" "$dir" "$side-r$r" "$out"
    echo "$side r$r drive exit=$?" >> "$out/runs.txt"
  done
done
cat "$out/runs.txt"
