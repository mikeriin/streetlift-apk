#!/usr/bin/env bash
# L6 (KT-023) — Lancement du processus, mesuré par Android (`am start -W`,
# TotalTime = jusqu'à la première image de l'activité).
#
#   tools/perf_device/cold_start.sh <apk> <libellé> <dossier_sortie> [répétitions] [appareil]
#
# À utiliser sur un émulateur ou un appareil de TEST seulement : le script
# installe l'APK et efface les données de l'application (`pm clear`) avant
# la première ouverture. Ne jamais l'exécuter sur le téléphone principal.
#
# Sortie <libellé>-coldstart.csv : ligne « premier » (première ouverture
# après effacement des données) puis « processus » (processus arrêté par
# `am force-stop`, données conservées), TotalTime et WaitTime en ms.
set -euo pipefail
apk="$1"; label="$2"; out="$(mkdir -p "$3" && cd "$3" && pwd)"; n="${4:-10}"; device="${5:-}"
package="fr.tchoupi.streetlift_tracker"
activity="$package/.MainActivity"
a() { adb ${device:+-s "$device"} "$@"; }
a install -r "$apk" > "$out/$label-install.log" 2>&1
a shell pm clear "$package" >> "$out/$label-install.log" 2>&1
csv="$out/$label-coldstart.csv"
echo "kind,run,total_ms,wait_ms" > "$csv"
launch() {
  local kind="$1" run="$2" text total wait
  a shell am force-stop "$package"
  sleep 2
  text="$(a shell am start -W -n "$activity" 2>&1 | tr -d '\r')"
  total="$(printf '%s\n' "$text" | awk -F': ' '/^TotalTime/{print $2}')"
  wait="$(printf '%s\n' "$text" | awk -F': ' '/^WaitTime/{print $2}')"
  echo "$kind,$run,${total:-NA},${wait:-NA}" >> "$csv"
  sleep 6
}
launch premier 0
for i in $(seq 1 "$n"); do launch processus "$i"; done
a shell dumpsys meminfo "$package" > "$out/$label-coldstart-meminfo.txt" 2>&1 || true
a shell am force-stop "$package"
cat "$csv"
