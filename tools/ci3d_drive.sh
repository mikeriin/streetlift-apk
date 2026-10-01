#!/usr/bin/env bash
# M1 (CI 3D) : rendu réel de l'écran Moteur 3D (M2 : Anatomie ; M3 : fiche
# exercice ; M4 : STATS ; M4b : transparence et filtres ; M4c : zoom au
# pincement et filtres normalisés ; M5 : postures du mannequin riggé ; M56 :
# carte Koach du jour ; 5.5.2 : écorché acheté, sans posture ; M6b :
# audit des écrans du mannequin fixe ; M6c : personnage Mixamo ; M7 :
# lecteur d'animation ; M7b : animations de Koach, retirées en G5 ; M8 :
# carte 2D des groupes musculaires ; G5 : Koach 2D) sur
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
# $2 (facultatif) : suffixe du journal et partie jouée (M6B_PART).
# $3 (facultatif) : « dev » = build de développement (G1, KALIS_DEV=true).
# $4 (facultatif) : « garder » = application laissée installée à la fin
# (sans --keep-app-running, flutter drive la désinstalle : ses données
# seraient perdues pour la partie suivante).
cible() {
  adb shell am force-stop fr.tchoupi.streetlift_tracker || true
  timeout "${CI3D_DELAI:-600}" flutter drive --no-pub \
    --driver=test_driver/integration_test.dart \
    --target="integration_test/$1.dart" \
    ${2:+--dart-define=M6B_PART=$2} \
    ${3:+--dart-define=KALIS_DEV=true} \
    ${4:+--keep-app-running} \
    -d emulator-5554 > "$out/drive-$1${2:+-$2}.log" 2>&1
}
# G5 (dev6.3.0) : Koach 2D, cible du lot, build de développement, en deux
# parties : a = sombre et rouge Kalis, b = clair et violet (accueil, carte
# du jour, proposition, Anatomie › Galerie de Koach, flammes, « Pourquoi ? »,
# « Réduire les animations », session de test et sa suppression).
code_g5=0
for part in a b; do
  cible koach_g5_test "$part" dev
  c=$?
  # Premier lancement après le démarrage de l'émulateur : le service du
  # pilote disparaît parfois avant le premier relevé (essais G5 1, 2, 5) ;
  # adb relancé, second essai (comme M8).
  if [ "$c" -ne 0 ] && [ ! -f "$out/g5_releve_$part.json" ]; then
    echo "G5 $part sans relevé (code $c) : adb relancé, second essai."
    cp "$out/drive-koach_g5_test-$part.log" "$out/drive-g5-$part-essai1.log"
    adb kill-server || true
    adb start-server || true
    timeout 60 adb wait-for-device || true
    cible koach_g5_test "$part" dev
    c=$?
  fi
  [ "$c" -ne 0 ] && code_g5=$c
  tail -n 30 "$out/drive-koach_g5_test-$part.log"
done
# Cibles des lots précédents (G3, G2, G1, M8, M7) : CI3D_TOUT=1.
code_g3=0
code_g2=0
code_g1=0
code_m8=0
code_m7=0
if [ "${CI3D_TOUT:-0}" = "1" ]; then
# G3 (dev6.2.0) : base d'exercices v1.1, build de développement, a = sombre,
# b = clair.
for part in a b; do
  cible catalogue_g3_test "$part" dev
  c=$?
  [ "$c" -ne 0 ] && code_g3=$c
  tail -n 30 "$out/drive-catalogue_g3_test-$part.log"
done
# G2 (dev6.1.0) : suppression des WOD, des séances perso et de L12, en
# deux parties : a = sombre, b = clair (annonce et copie, accueil, Arsenal,
# STATS, Réglages › Sauvegardes).
for part in a b; do
  cible retrait_g2_test "$part"
  c=$?
  [ "$c" -ne 0 ] && code_g2=$c
  tail -n 30 "$out/drive-retrait_g2_test-$part.log"
done
# G1 (6.0.0) : mode dev, en deux lancements de l'application
# (b = redémarrage à froid de a, application arrêtée entre les deux) :
# a = sombre (5 appuis, installation neuve, outils, voyage d'une semaine),
# b = clair (toujours en session de test, appui long annulé puis 3 s,
# retour à la session personnelle identique).
for part in a b; do
  garder=""
  [ "$part" = a ] && garder=garder
  cible mode_dev_g1_test "$part" dev $garder
  c=$?
  [ "$c" -ne 0 ] && code_g1=$c
  tail -n 30 "$out/drive-mode_dev_g1_test-$part.log"
done
# M8 (5.9.0) : carte 2D des 15 groupes musculaires, cible du lot, en deux
# parties : a = sombre, b = clair (Anatomie, fiches, STATS, accueil).
# Les cibles 3D d'écrans passés à la carte 2D (M3, M4, M4b, M4c, M56, M6b,
# M6c) sont retirées : ces écrans n'ont plus de 3D.
code_m8=0
for part in a b; do
  cible carte_2d_m8_test "$part"
  c=$?
  if [ "$c" -ne 0 ] && [ ! -f "$out/m8_releve_$part.json" ]; then
    echo "M8 $part sans relevé (code $c) : adb relancé, second essai."
    cp "$out/drive-carte_2d_m8_test-$part.log" "$out/drive-m8-$part-essai1.log"
    adb kill-server || true
    adb start-server || true
    timeout 60 adb wait-for-device || true
    cible carte_2d_m8_test "$part"
    c=$?
  fi
  [ "$c" -ne 0 ] && code_m8=$c
done
# 3D restante : démonstration (animation de test, parties a à c). G5 :
# animations 3D de Koach (M7b) retirées.
m7_parts="a b c"
for part in $m7_parts; do
  cible animation_m7_test "$part"
  c=$?
  [ "$c" -ne 0 ] && code_m7=$c
done
fi
code=0
if [ "${CI3D_TOUT:-0}" = "1" ]; then
drive() {
  timeout 1200 flutter drive --no-pub \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/moteur_3d_test.dart \
    -d emulator-5554 > "$out/drive.log" 2>&1
}
drive
code=$?
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
if [ "${CI3D_TOUT:-0}" = "1" ]; then
  for part in a b; do
    tail -n 30 "$out/drive-carte_2d_m8_test-$part.log"
  done
fi
kill "$logcat_pid" 2>/dev/null || true
grep -o 'Impeller rendering backend ([^)]*)' "$out/logcat-complet.txt" | sort | uniq -c > "$out/impeller.txt" || true
grep -iE 'flutter|impeller|vulkan|gles|AndroidRuntime|FATAL|swiftshader|angle|lowmemorykiller|DEBUG|libc|tombstone|ActivityManager' "$out/logcat-complet.txt" | tail -n 3000 > "$out/logcat.txt" || true
rm -f "$out/logcat-complet.txt"
echo "code_g5=$code_g5 code_g3=$code_g3 code_g2=$code_g2 code_g1=$code_g1 code_m8=$code_m8 code_m7=$code_m7" > "$out/drive-code.txt"
echo "code=$code" >> "$out/drive-code.txt"
echo "code_mesure=$code_mesure" >> "$out/drive-code.txt"
[ "$code_g5" -eq 0 ] && [ "$code_g3" -eq 0 ] && [ "$code_g2" -eq 0 ] && [ "$code_g1" -eq 0 ] && [ "$code_m8" -eq 0 ] && [ "$code_m7" -eq 0 ] && [ "$code" -eq 0 ] && [ "$code_mesure" -eq 0 ]
