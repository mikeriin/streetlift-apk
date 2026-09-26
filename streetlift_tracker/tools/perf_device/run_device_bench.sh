#!/usr/bin/env bash
# L6 (KT-023) — Banc DANS L'APPLICATION, mode profile (AOT), sur l'appareil
# ou l'émulateur Android connecté.
#
#   [MODE=apk|drive] [ABI=android-x64|android-arm64] \
#   tools/perf_device/run_device_bench.sh <dossier_projet> <libellé> <dossier_sortie> [appareil]
#
# 1. Copie <dossier_projet> dans un dossier temporaire (le projet n'est pas
#    modifié), y ajoute les dépendances de test integration_test et
#    flutter_driver (SDK Flutter) et les fichiers de ce dossier, puis analyse
#    le banc (`flutter analyze`).
# 2. MODE=apk (défaut) : construit un APK profile dont le point d'entrée est
#    le banc, l'installe (`adb install -r`), le lance et lit les résultats
#    dans logcat. Utilisable sur un émulateur, où `flutter drive --profile`
#    est refusé par l'outil Flutter.
#    MODE=drive : `flutter drive --profile` (téléphone physique conseillé).
#    BUILD_ONLY=1 APK_OUT=<fichier> : construit seulement l'APK du banc.
#    APK_IN=<fichier> : réutilise un APK déjà construit (étapes 1-2 sautées).
# 3. Écrit <sortie>/<libellé>.json (Stopwatch et FrameTiming), <libellé>.log,
#    <libellé>-pubspec.lock.diff (écart de verrouillage de la COPIE) et
#    <libellé>-meminfo.txt (mémoire du processus en fin de scénario).
#
# Données : profils synthétiques (test/support/perf_fixtures.dart) dans un
# stockage en mémoire ; les données de l'application installée ne sont ni
# lues ni modifiées par le banc. ATTENTION : en mode apk, l'APK du banc
# remplace l'application installée (même identifiant) : à réserver à un
# émulateur ou à un appareil de test, jamais au téléphone principal.
set -euo pipefail

project="$(cd "$1" && pwd)"
label="$2"
out="$(mkdir -p "$3" && cd "$3" && pwd)"
device="${4:-}"
mode="${MODE:-apk}"
abi="${ABI:-android-x64}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
package="fr.tchoupi.streetlift_tracker"
a() { adb ${device:+-s "$device"} "$@"; }

log="$out/$label.log"
if [ -n "${APK_IN:-}" ]; then
  echo "label=$label apk=$APK_IN date=$(date -u +%FT%TZ)" > "$log"
  sha256sum "$APK_IN" >> "$log"
  apk="$APK_IN"
else
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/app"
(cd "$project" && tar --exclude=./build --exclude=./.dart_tool -cf - .) | (cd "$work/app" && tar -xf -)
cd "$work/app"
cp pubspec.lock "$work/pubspec.lock.orig"
python3 - <<'PY'
from pathlib import Path
p = Path("pubspec.yaml")
s = p.read_text(encoding="utf-8")
marker = "dev_dependencies:\n"
assert marker in s, "dev_dependencies absent"
s = s.replace(marker, marker + "  integration_test:\n    sdk: flutter\n  flutter_driver:\n    sdk: flutter\n", 1)
p.write_text(s, encoding="utf-8")
PY
rm -rf integration_test test_driver
cp -r "$here/integration_test" "$here/test_driver" .

{
  echo "label=$label mode=$mode abi=$abi"
  echo "date=$(date -u +%FT%TZ)"
  flutter --version
  flutter pub get
} > "$log" 2>&1
diff -u "$work/pubspec.lock.orig" pubspec.lock > "$out/$label-pubspec.lock.diff" || true
flutter analyze --no-pub integration_test test_driver >> "$log" 2>&1 ||
  echo "analyse du banc : problèmes signalés (voir ci-dessus)" >> "$log"

status=0
if [ "$mode" = drive ]; then
  args=(drive --profile --no-pub --no-dds
    --driver=test_driver/perf_driver.dart
    --target=integration_test/l6_device_test.dart
    --dart-define=KALIS_PERF_LABEL="$label")
  if [ -n "$device" ]; then args+=(-d "$device"); fi
  KALIS_DEVICE_OUT="$out" KALIS_DEVICE_NAME="$label" flutter "${args[@]}" >> "$log" 2>&1 || status=$?
  exit "$status"
fi
flutter build apk --profile --no-pub --target-platform "$abi" \
  -t integration_test/l6_device_test.dart \
  --dart-define=KALIS_PERF_LABEL="$label" >> "$log" 2>&1 || status=$?
apk="$work/app/build/app/outputs/flutter-apk/app-profile.apk"
if [ "$status" -eq 0 ] && [ -n "${APK_OUT:-}" ]; then cp "$apk" "$APK_OUT"; fi
if [ "$status" -ne 0 ] || [ -n "${BUILD_ONLY:-}" ]; then
  echo "exit=$status" >> "$log"
  exit "$status"
fi
fi
status=0
sha256sum "$apk" >> "$log"
a install -r "$apk" >> "$log" 2>&1
a shell am force-stop "$package" || true
a logcat -c
a shell am start -W -n "$package/.MainActivity" >> "$log" 2>&1
deadline=$((SECONDS + ${DEVICE_TIMEOUT:-1500}))
finished=0
while [ $SECONDS -lt $deadline ]; do
  if a logcat -d -s flutter:I | grep -q "KALIS_DEVICE_DONE"; then finished=1; break; fi
  sleep 10
done
a logcat -d -s flutter:I > "$out/$label-logcat.txt" 2>&1 || true
if [ "$finished" -eq 1 ]; then
  python3 - "$out/$label-logcat.txt" "$out/$label.json" <<'PY' || status=65
import re, sys
chunks = {}
total = 0
for line in open(sys.argv[1], encoding="utf-8", errors="replace"):
    m = re.search(r"KALIS_DEVICE (\d+)/(\d+) (.*)$", line.rstrip("\n"))
    if m:
        chunks[int(m.group(1))] = m.group(3)
        total = int(m.group(2))
missing = [i for i in range(1, total + 1) if i not in chunks]
if missing or not total:
    raise SystemExit(f"morceaux manquants : {missing}")
open(sys.argv[2], "w", encoding="utf-8").write("".join(chunks[i] for i in range(1, total + 1)))
PY
else
  echo "délai dépassé : KALIS_DEVICE_DONE absent" >> "$log"
  status=124
fi
echo "exit=$status" >> "$log"
a shell dumpsys meminfo "$package" > "$out/$label-meminfo.txt" 2>&1 || true
a shell am force-stop "$package" || true
exit "$status"
