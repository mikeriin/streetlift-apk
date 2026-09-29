#!/usr/bin/env bash
# M1 (CI 3D) : rendu réel de l'écran Moteur 3D (M2 : Anatomie ; M3 : fiche
# exercice ; M4 : STATS ; M4b : transparence et filtres ; M4c : zoom au
# pincement et filtres normalisés ; M5 : postures du mannequin riggé ; M56 :
# carte Koach du jour ; 5.5.2 : écorché acheté, sans posture) sur
# l'émulateur
# Android lancé
# par .github/workflows/ci-3d.yml (reactivecircus/android-emulator-runner).
# Écrit dans build/ci3d/ : captures PNG, relevé JSON, moteur de rendu
# Impeller réellement choisi, extrait du journal. Voir docs/CI_3D.md.
set -u
out=build/ci3d
mkdir -p "$out"
{
  echo "vulkan=$(adb shell getprop ro.hardware.vulkan 2>/dev/null | tr -d '\r')"
  echo "opengles=$(adb shell getprop ro.opengles.version 2>/dev/null | tr -d '\r')"
  echo "egl=$(adb shell getprop ro.hardware.egl 2>/dev/null | tr -d '\r')"
  echo "android=$(adb shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')"
  echo "modele=$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
} > "$out/emulateur.txt"
cat "$out/emulateur.txt"
# M4b (PIPELINE_3D.md §4) : résolution réduite (540 × 960, 240 ppp : écran
# de 360 × 640 dp), le rendu 3D logiciel de l'émulateur est ~5 fois plus
# court qu'en 1080 × 2400.
adb shell wm size 540x960 || true
adb shell wm density 240 || true
echo "ecran=$(adb shell wm size 2>/dev/null | tr -d '\r' | tail -n 1)" >> "$out/emulateur.txt"
adb shell svc power stayon true || true
adb shell wm dismiss-keyguard || true
adb logcat -c || true
adb logcat -v time > "$out/logcat-complet.txt" 2>&1 &
logcat_pid=$!

# Cible séparée lancée par `flutter drive` (application arrêtée avant).
# M5 : délai de 10 min par cible (la cible du lot dure ≈ 3 min) : un
# blocage laisse le temps du second essai dans les 30 min du job.
cible() {
  adb shell am force-stop fr.tchoupi.streetlift_tracker || true
  timeout "${CI3D_DELAI:-600}" flutter drive --no-pub \
    --driver=test_driver/integration_test.dart \
    --target="integration_test/$1.dart" \
    -d emulator-5554 > "$out/drive-$1.log" 2>&1
}
# M56 : lancé en premier (lot en cours) ; 5.5.2 : Anatomie (écorché acheté,
# 4 vues, groupe Dos allumé), fiches des 3 pilotes (démonstration 2D et
# mannequin fixe avec ses muscles), carte « Koach · séance du jour » et
# préchargement. Les cibles des lots précédents ne
# sont relancées que sur demande (CI3D_TOUT=1) : captures limitées aux
# écrans du lot.
cible animations_m56_test
code_m56=$?
if [ "$code_m56" -ne 0 ] && [ ! -f "$out/m56_releve.json" ]; then
  echo "M56 sans relevé (code $code_m56) : adb relancé, second essai."
  cp "$out/drive-animations_m56_test.log" "$out/drive-m56-essai1.log"
  adb kill-server || true
  adb start-server || true
  timeout 60 adb wait-for-device || true
  cible animations_m56_test
  code_m56=$?
fi
code_m5=0
code_m4c=0
code_m4b=0
code=0
code_fiche=0
code_stats=0
if [ "${CI3D_TOUT:-0}" = "1" ]; then
# M5 : postures du mannequin riggé (cible retirée en 5.5.2 : écorché sans
# squelette).
# M4c : zoom au pincement et menus « Filtres » normalisés.
cible zoom_filtres_m4c_test
code_m4c=$?
# M4b : muscles profonds vus à travers les autres, écran Anatomie, fiche et
# STATS en transparence, Moteur 3D avant / après.
cible anatomie_m4b_test
code_m4b=$?
tail -n 30 "$out/drive-anatomie_m4b_test.log"
# STATS, résumé hebdomadaire sur le mannequin (semaine type et vide,
# sombre et clair, bascule Face / Dos, mesure du défilement).
cible stats_semaine_test
code_stats=$?
if [ "$code_stats" -ne 0 ] && [ ! -f "$out/m4_releve.json" ]; then
  echo "STATS sans relevé (code $code_stats) : adb relancé, second essai."
  cp "$out/drive-stats_semaine_test.log" "$out/drive-stats-essai1.log"
  adb kill-server || true
  adb start-server || true
  timeout 60 adb wait-for-device || true
  cible stats_semaine_test
  code_stats=$?
fi
drive() {
  timeout 1200 flutter drive --no-pub \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/moteur_3d_test.dart \
    -d emulator-5554 > "$out/drive.log" 2>&1
}
drive
code=$?
if [ "$code" -ne 0 ] && ! ls "$out"/m1_*.png > /dev/null 2>&1; then
  echo "Premier essai sans capture (code $code) : adb relancé, second essai."
  cp "$out/drive.log" "$out/drive-essai1.log"
  adb kill-server || true
  adb start-server || true
  timeout 60 adb wait-for-device || true
  drive
  code=$?
fi
# M3 : fiche exercice (6 fiches sombre et clair, étirés, toucher, 20 fiches
# d'affilée), cible séparée : un plantage ne fait pas perdre les captures du
# premier passage.
cible fiche_exercice_test
code_fiche=$?
if [ "$code_fiche" -ne 0 ] && [ ! -f "$out/m3_releve.json" ]; then
  echo "Fiche sans relevé (code $code_fiche) : adb relancé, second essai."
  cp "$out/drive-fiche_exercice_test.log" "$out/drive-fiche-essai1.log"
  adb kill-server || true
  adb start-server || true
  timeout 60 adb wait-for-device || true
  cible fiche_exercice_test
  code_fiche=$?
fi
tail -n 30 "$out/drive-stats_semaine_test.log"
tail -n 30 "$out/drive-fiche_exercice_test.log"
tail -n 40 "$out/drive.log"
fi
# M2 : mesure des deux organisations du modèle (a) / (b), relancée seulement
# sur demande (CI3D_MESURE=1) : la décision est prise et consignée.
code_mesure=0
if [ "${CI3D_MESURE:-0}" = "1" ]; then
  cible mannequin_mesure_test
  code_mesure=$?
  tail -n 20 "$out/drive-mannequin_mesure_test.log"
fi
tail -n 40 "$out/drive-animations_m56_test.log"
kill "$logcat_pid" 2>/dev/null || true
grep -o 'Impeller rendering backend ([^)]*)' "$out/logcat-complet.txt" | sort | uniq -c > "$out/impeller.txt" || true
grep -iE 'flutter|impeller|vulkan|gles|AndroidRuntime|FATAL|swiftshader|angle|lowmemorykiller|DEBUG|libc|tombstone|ActivityManager' "$out/logcat-complet.txt" | tail -n 3000 > "$out/logcat.txt" || true
rm -f "$out/logcat-complet.txt"
echo "code_m56=$code_m56" > "$out/drive-code.txt"
echo "code_m5=$code_m5" >> "$out/drive-code.txt"
echo "code_m4c=$code_m4c" >> "$out/drive-code.txt"
echo "code_m4b=$code_m4b" >> "$out/drive-code.txt"
echo "code=$code" >> "$out/drive-code.txt"
echo "code_fiche=$code_fiche" >> "$out/drive-code.txt"
echo "code_stats=$code_stats" >> "$out/drive-code.txt"
echo "code_mesure=$code_mesure" >> "$out/drive-code.txt"
[ "$code_m56" -eq 0 ] && [ "$code_m5" -eq 0 ] && [ "$code_m4c" -eq 0 ] && [ "$code_m4b" -eq 0 ] && [ "$code" -eq 0 ] && [ "$code_fiche" -eq 0 ] && [ "$code_stats" -eq 0 ] && [ "$code_mesure" -eq 0 ]
