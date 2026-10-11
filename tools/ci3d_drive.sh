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
# CI1g (dev6.11.1) : avis médical avant la première séance (note
# `clearance_first` de `kalis_plan` 0.3.1) : étape à confirmer, « Pas
# encore » puis rappel, « J'ai eu l'avis ». Session personnelle sans étape ;
# session de test supprimée, session personnelle intacte. Build de
# développement, deux parties : a = sombre, rouge ; b = clair, violet.
code_ci1g=0
for part in a b; do
  cible clearance_ci1g_test "$part" dev
  c=$?
  if [ "$c" -ne 0 ] && [ ! -f "$out/ci1g_releve_$part.json" ]; then
    echo "CI1g $part sans relevé (code $c) : adb relancé, second essai."
    cp "$out/drive-clearance_ci1g_test-$part.log" "$out/drive-ci1g-$part-essai1.log"
    adb kill-server || true
    adb start-server || true
    timeout 60 adb wait-for-device || true
    cible clearance_ci1g_test "$part" dev
    c=$?
  fi
  [ "$c" -ne 0 ] && code_ci1g=$c
  tail -n 30 "$out/drive-clearance_ci1g_test-$part.log"
done
# CI1f (dev6.11.0) : myo-reps saisis mini-série par mini-série (une série
# avec ses parties) ; contraste du programme de 40 semaines affiché comme un
# groupe (tours, chrono, résultat). Session personnelle, build de
# développement, deux parties : a = sombre, rouge ; b = clair, violet.
code_ci1f=0
for part in a b; do
  cible koach_ci1f_test "$part" dev
  c=$?
  if [ "$c" -ne 0 ] && [ ! -f "$out/ci1f_releve_$part.json" ]; then
    echo "CI1f $part sans relevé (code $c) : adb relancé, second essai."
    cp "$out/drive-koach_ci1f_test-$part.log" "$out/drive-ci1f-$part-essai1.log"
    adb kill-server || true
    adb start-server || true
    timeout 60 adb wait-for-device || true
    cible koach_ci1f_test "$part" dev
    c=$?
  fi
  [ "$c" -ne 0 ] && code_ci1f=$c
  tail -n 30 "$out/drive-koach_ci1f_test-$part.log"
done
# CI1e (dev6.10.0) : programme de 40 semaines du propriétaire sous toutes
# les fonctionnalités (C11) : sauvegarde d'origine au premier lancement,
# saison et compte à rebours, séance du jour en mode coach, retour au
# programme d'origine. Session personnelle, build de développement, deux
# parties : a = sombre, rouge ; b = clair, violet.
code_ci1e=0
for part in a b; do
  cible koach_ci1e_test "$part" dev
  c=$?
  if [ "$c" -ne 0 ] && [ ! -f "$out/ci1e_releve_$part.json" ]; then
    echo "CI1e $part sans relevé (code $c) : adb relancé, second essai."
    cp "$out/drive-koach_ci1e_test-$part.log" "$out/drive-ci1e-$part-essai1.log"
    adb kill-server || true
    adb start-server || true
    timeout 60 adb wait-for-device || true
    cible koach_ci1e_test "$part" dev
    c=$?
  fi
  [ "$c" -ne 0 ] && code_ci1e=$c
  tail -n 30 "$out/drive-koach_ci1e_test-$part.log"
done
# CI1c (dev6.9.2) : ajustement de Koach accepté appliqué tout de suite
# (programme importé du propriétaire : couche par-dessus l'original ;
# programme street créé : séance ouverte à l'avance rouverte à jour) ;
# séance seulement consultée sans entrée d'historique. Build de
# développement, deux parties : a = sombre, rouge ; b = clair, violet.
code_ci1c=0
for part in a b; do
  cible koach_ci1c_test "$part" dev
  c=$?
  if [ "$c" -ne 0 ] && [ ! -f "$out/ci1c_releve_$part.json" ]; then
    echo "CI1c $part sans relevé (code $c) : adb relancé, second essai."
    cp "$out/drive-koach_ci1c_test-$part.log" "$out/drive-ci1c-$part-essai1.log"
    adb kill-server || true
    adb start-server || true
    timeout 60 adb wait-for-device || true
    cible koach_ci1c_test "$part" dev
    c=$?
  fi
  [ "$c" -ne 0 ] && code_ci1c=$c
  tail -n 30 "$out/drive-koach_ci1c_test-$part.log"
done
# CI1b (dev6.9.1) : même cible, étape « douleur qui dure » en plus.
# CI1 (dev6.9.0) : street calibré (kalis_plan 0.2, kalis_adapt 0.2), cible
# du lot, build de développement, en deux parties : a = sombre, rouge
# Kalis, compétiteur de streetlifting ; b = clair, violet, débutant de
# calisthénie (session personnelle sans saison ; session de test : carte
# et écran de la saison, jour J, séance guidée par le mode coach ;
# suppression de la session de test, session personnelle intacte).
code_ci1=0
for part in a b; do
  cible street_ci1_test "$part" dev
  c=$?
  if [ "$c" -ne 0 ] && [ ! -f "$out/ci1_releve_$part.json" ]; then
    echo "CI1 $part sans relevé (code $c) : adb relancé, second essai."
    cp "$out/drive-street_ci1_test-$part.log" "$out/drive-ci1-$part-essai1.log"
    adb kill-server || true
    adb start-server || true
    timeout 60 adb wait-for-device || true
    cible street_ci1_test "$part" dev
    c=$?
  fi
  [ "$c" -ne 0 ] && code_ci1=$c
  tail -n 30 "$out/drive-street_ci1_test-$part.log"
done
code_cu=0
if [ "${CI3D_TOUT:-0}" = "1" ]; then
# CU (dev6.8.0) : parcours de création du profil v3, cible du lot, build
# de développement, en deux parties : a = sombre, rouge Kalis ; b = clair,
# violet (session personnelle de dev6.7.0 : profil relu au schéma 3,
# invitation et « Compléter mon profil » ; session de test : parcours
# débutant puis compétiteur, 200 % de texte, Réglages › Profil, tests
# guidés ; suppression de la session de test, session personnelle intacte).
code_cu=0
for part in a b; do
  cible profil_cu_test "$part" dev
  c=$?
  if [ "$c" -ne 0 ] && [ ! -f "$out/cu_releve_$part.json" ]; then
    echo "CU $part sans relevé (code $c) : adb relancé, second essai."
    cp "$out/drive-profil_cu_test-$part.log" "$out/drive-cu-$part-essai1.log"
    adb kill-server || true
    adb start-server || true
    timeout 60 adb wait-for-device || true
    cible profil_cu_test "$part" dev
    c=$?
  fi
  [ "$c" -ne 0 ] && code_cu=$c
  tail -n 30 "$out/drive-profil_cu_test-$part.log"
done
fi
code_g10=0
if [ "${CI3D_TOUT:-0}" = "1" ]; then
# G10 (dev6.7.0) : évolution du programme, cible du lot, build de
# développement, en deux parties : a = sombre, rouge Kalis, mode assisté ;
# b = clair, violet, mode libre (session personnelle : Mon programme,
# écran Évolution ; session de test : simulateur de séances 8 semaines,
# propositions de Koach, diff, historique, inspecteur du moteur ;
# suppression de la session de test, session personnelle intacte).
# CU : sous CI3D_TOUT=1.
for part in a b; do
  cible evolution_g10_test "$part" dev
  c=$?
  if [ "$c" -ne 0 ] && [ ! -f "$out/g10_releve_$part.json" ]; then
    echo "G10 $part sans relevé (code $c) : adb relancé, second essai."
    cp "$out/drive-evolution_g10_test-$part.log" "$out/drive-g10-$part-essai1.log"
    adb kill-server || true
    adb start-server || true
    timeout 60 adb wait-for-device || true
    cible evolution_g10_test "$part" dev
    c=$?
  fi
  [ "$c" -ne 0 ] && code_g10=$c
  tail -n 30 "$out/drive-evolution_g10_test-$part.log"
done
fi
# Cibles des lots précédents (G10 ci-dessus, G9, G7, G6, G5, G3, G2, G1, M8, M7) :
# CI3D_TOUT=1.
code_g9=0
code_g7=0
code_g6=0
code_g5=0
code_g3=0
code_g2=0
code_g1=0
code_m8=0
code_m7=0
if [ "${CI3D_TOUT:-0}" = "1" ]; then
# G9 (dev6.6.0) : séance servie par kalis_adapt, build de
# développement, en deux parties : a = sombre et rouge Kalis, b = clair et
# violet (session personnelle : copie du programme du propriétaire, bilan
# santé et détail, flammes, ajustement de Koach, fin de séance ; session de
# test : programme généré, séance complète ; suppression de la session de
# test, session personnelle intacte).
for part in a b; do
  cible seance_g9_test "$part" dev
  c=$?
  if [ "$c" -ne 0 ] && [ ! -f "$out/g9_releve_$part.json" ]; then
    echo "G9 $part sans relevé (code $c) : adb relancé, second essai."
    cp "$out/drive-seance_g9_test-$part.log" "$out/drive-g9-$part-essai1.log"
    adb kill-server || true
    adb start-server || true
    timeout 60 adb wait-for-device || true
    cible seance_g9_test "$part" dev
    c=$?
  fi
  [ "$c" -ne 0 ] && code_g9=$c
  tail -n 30 "$out/drive-seance_g9_test-$part.log"
done
# G7 (dev6.5.0) : création du programme avec kalis_plan, cible du lot,
# build de développement, en deux parties : a = sombre et rouge Kalis, b =
# clair et violet (session personnelle : Mon programme, Où j'en suis ;
# session de test : profil, passe 1, revue et diff de Koach, passe 2,
# ajustement refusé, programme actif ; suppression de la session de test).
code_g7=0
for part in a b; do
  cible programme_g7_test "$part" dev
  c=$?
  if [ "$c" -ne 0 ] && [ ! -f "$out/g7_releve_$part.json" ]; then
    echo "G7 $part sans relevé (code $c) : adb relancé, second essai."
    cp "$out/drive-programme_g7_test-$part.log" "$out/drive-g7-$part-essai1.log"
    adb kill-server || true
    adb start-server || true
    timeout 60 adb wait-for-device || true
    cible programme_g7_test "$part" dev
    c=$?
  fi
  [ "$c" -ne 0 ] && code_g7=$c
  tail -n 30 "$out/drive-programme_g7_test-$part.log"
done
# G6 (dev6.4.0) : création du profil d'athlète v2, cible du lot, build de
# développement, en deux parties : a = sombre et rouge Kalis, b = clair et
# violet (proposition de refaire son profil dans la session personnelle,
# création complète dans la session de test, 3 écrans à 200 % de texte,
# Réglages › Profil, suppression de la session de test).
for part in a b; do
  cible profil_g6_test "$part" dev
  c=$?
  # Premier lancement après le démarrage de l'émulateur : le service du
  # pilote disparaît parfois avant le premier relevé (essais G5 1, 2, 5) ;
  # adb relancé, second essai (comme M8).
  if [ "$c" -ne 0 ] && [ ! -f "$out/g6_releve_$part.json" ]; then
    echo "G6 $part sans relevé (code $c) : adb relancé, second essai."
    cp "$out/drive-profil_g6_test-$part.log" "$out/drive-g6-$part-essai1.log"
    adb kill-server || true
    adb start-server || true
    timeout 60 adb wait-for-device || true
    cible profil_g6_test "$part" dev
    c=$?
  fi
  [ "$c" -ne 0 ] && code_g6=$c
  tail -n 30 "$out/drive-profil_g6_test-$part.log"
done
# G5 (dev6.3.0) : Koach 2D, cible du lot, build de développement, en deux
# parties : a = sombre et rouge Kalis, b = clair et violet (accueil, carte
# du jour, proposition, Anatomie › Galerie de Koach, flammes, « Pourquoi ? »,
# « Réduire les animations », session de test et sa suppression).
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
echo "code_ci1g=$code_ci1g code_ci1f=$code_ci1f code_ci1e=$code_ci1e code_ci1c=$code_ci1c code_ci1=$code_ci1 code_cu=$code_cu code_g10=$code_g10 code_g9=$code_g9 code_g7=$code_g7 code_g6=$code_g6 code_g5=$code_g5 code_g3=$code_g3 code_g2=$code_g2 code_g1=$code_g1 code_m8=$code_m8 code_m7=$code_m7" > "$out/drive-code.txt"
echo "code=$code" >> "$out/drive-code.txt"
echo "code_mesure=$code_mesure" >> "$out/drive-code.txt"
[ "$code_ci1g" -eq 0 ] && [ "$code_ci1f" -eq 0 ] && [ "$code_ci1e" -eq 0 ] && [ "$code_ci1c" -eq 0 ] && [ "$code_ci1" -eq 0 ] && [ "$code_cu" -eq 0 ] && [ "$code_g10" -eq 0 ] && [ "$code_g9" -eq 0 ] && [ "$code_g7" -eq 0 ] && [ "$code_g6" -eq 0 ] && [ "$code_g5" -eq 0 ] && [ "$code_g3" -eq 0 ] && [ "$code_g2" -eq 0 ] && [ "$code_g1" -eq 0 ] && [ "$code_m8" -eq 0 ] && [ "$code_m7" -eq 0 ] && [ "$code" -eq 0 ] && [ "$code_mesure" -eq 0 ]
