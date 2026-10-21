# Sauvegarde KM5 (Koach 1.0.7 : la rampe de volume ne coupe jamais sous l'écrit)

Session Opus 5.5 (20/10/2026, depuis 16:36 UTC). Base : `moteurs` 91d8ea70. Pas de SDK Dart en session.

## Fait (17:58 UTC)
- Code figé : commit local `km5` de9b769 (kalis_adapt 1.0.6, Koach 1.0.7 ; kalis_bench 0.5.8), arbre de cette sauvegarde.
- Relecture indépendante (Opus) faite et traitée : M1 (écrit servi : la douleur ne laisse pas sa place aux ajouts), M2 (allègement sur l'écrit du programme), M3 (mesure indépendante `sans_cause_*`), m1 (un seul prescrire compté), m5 (filtre une lecture) ; M4 (montée du vrai test) et m2 (groupe deviné par la valeur, prudent) dits comme limites.
- Run A (39463684069) : Dart compile ; échecs attendus corrigés (docs/contrat, sortie Python d'evaluer_saison adv-7ee0da71 : echecs 0,004093, gain −0,000389 ; format patch appliqué).
- Échantillon local Python (302 saisons, vérité b, graine 0, --rapide) : critère 7 = 0, ancienne définition 0, sous l'écrit 0, sans cause 0, ajouts bornés 27 ; retour à l'écrit 18, réalisée appariée 20. 1.0.6 sur 27 saisons : sous l'écrit 749 items / 1 388 séries. Scénario (a) en 1.0.6 : reproduit le constat (extension triceps et élévations latérales à 0, pompes 2/4, DM 1/3).
- Run B (bis) 39475063809 en cours (arbre 6f0e8d5). Contrôle complet 1 échoué au formatage (patchs `git apply` ignorés depuis un sous-dossier) ; patchs appliqués par `patch -p1` : commit local ff6cd08 (formatage seul) ; contrôle complet (2) 3d028525 poussé 22:40.

## Reste
- Attendre run B et le contrôle complet ; remplir docs/CRITERES_KM5.md, livraison ; push moteurs (rebase), étiquettes kalis_adapt-v1.0.6 et kalis_bench-v0.5.8 ; LIVRAISON_KM5 (pipeline + projet), ETAT_CP, page de suivi, notification.

## Fin (21/10 02:0x UTC)
- Contrôle complet (2) 39509091986 vert ; moteurs 737d528d poussé, étiquettes kalis_adapt-v1.0.6 et kalis_bench-v0.5.8 ; LIVRAISON_KM5 (pipeline 23e5f95 + projet), ETAT_CP « livré », page de suivi v64. Lot terminé.
