#!/usr/bin/env bash
# UI0 (refonte UI) : tour de captures et relevé des parcours sur l'émulateur
# Android lancé par .github/workflows/ci-ui.yml (tâche « tour »). Joue
# integration_test/tour_ui_test.dart en quatre parties (cahier UI §6.2,
# PIPELINE_UI.md §3) :
#   a = sombre, bordeaux, session personnelle ;
#   b = clair, neon, session personnelle ;
#   c = sombre, neon, session de test (build de développement) ;
#   d = clair, bordeaux, session de test ;
#   e = sombre, bordeaux, personnelle, 320 dp de large et texte à 200 % (UI5) ;
#   f = palettes et contraste renforcé sur l'accueil et la séance (UI5).
# Sur la base b7996b3f (« avant »), les palettes bordeaux et neon sont lues
# sous leurs anciens noms (rouge, jaune). Écrit dans build/ci3d/ : captures
# tour_<partie>_<écran>.png, relevés tour_releve_<partie>.json (écrans
# ouverts, parcours en nombre d'appuis, contenu sous le dock).
set -u
out=build/ci3d
mkdir -p "$out"
adb shell wm size 540x960 || true
adb shell wm density 240 || true
adb shell svc power stayon true || true
adb shell wm dismiss-keyguard || true
parts="${UI_TOUR_PARTS:-a b c d}"
bilan="$out/tour_$(echo "$parts" | tr -d ' ').txt"
echo "cote=${UI_TOUR_COTE:-apres}" > "$bilan"
echo "ecran=$(adb shell wm size 2>/dev/null | tr -d '\r' | tail -n 1)" >> "$bilan"
code=0
for part in $parts; do
  adb shell am force-stop fr.tchoupi.streetlift_tracker || true
  if [ "$part" = e ]; then
    # 540 px à 270 dpi : 320 dp de large ; police système à 200 %.
    adb shell wm density 270 || true
    adb shell settings put system font_scale 2.0 || true
  else
    adb shell wm density 240 || true
    adb shell settings put system font_scale 1.0 || true
  fi
  timeout 900 flutter drive --no-pub \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/tour_ui_test.dart \
    --dart-define=UI_TOUR_PART=$part \
    --dart-define=KALIS_DEV=true \
    -d emulator-5554 > "$out/drive-tour-$part.log" 2>&1
  c=$?
  if [ "$c" -ne 0 ] && [ ! -f "$out/tour_releve_$part.json" ]; then
    echo "Tour $part sans relevé (code $c) : adb relancé, second essai."
    cp "$out/drive-tour-$part.log" "$out/drive-tour-$part-essai1.log"
    adb kill-server || true
    adb start-server || true
    timeout 60 adb wait-for-device || true
    timeout 900 flutter drive --no-pub \
      --driver=test_driver/integration_test.dart \
      --target=integration_test/tour_ui_test.dart \
      --dart-define=UI_TOUR_PART=$part \
      --dart-define=KALIS_DEV=true \
      -d emulator-5554 > "$out/drive-tour-$part.log" 2>&1
    c=$?
  fi
  if [ "$c" -ne 0 ] && [ ! -f "$out/tour_releve_$part.json" ]; then
    # Émulateur instable (« device offline », « Service has disappeared ») :
    # attendre qu'il soit de nouveau prêt, puis un troisième essai.
    echo "Tour $part sans relevé (code $c) : attente de l'émulateur, troisième essai."
    cp "$out/drive-tour-$part.log" "$out/drive-tour-$part-essai2.log"
    adb kill-server || true
    adb start-server || true
    timeout 120 adb wait-for-device || true
    for _ in $(seq 1 60); do
      [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] && break
      sleep 2
    done
    adb shell input keyevent 82 || true
    timeout 900 flutter drive --no-pub \
      --driver=test_driver/integration_test.dart \
      --target=integration_test/tour_ui_test.dart \
      --dart-define=UI_TOUR_PART=$part \
      --dart-define=KALIS_DEV=true \
      -d emulator-5554 > "$out/drive-tour-$part.log" 2>&1
    c=$?
  fi
  echo "tour_$part=$c" >> "$bilan"
  [ "$c" -ne 0 ] && code=$c
  tail -n 20 "$out/drive-tour-$part.log"
done
cat "$bilan"
exit "$code"
