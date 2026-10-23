# Livraison RV2 — suite de la revue (dev7.6.0)

Lot de la voie App du pipeline CP (DECISIONS_CP.md C17.47) : bugs signalés par RV1 et RV1c1 et non corrigés alors. Base : `main` c6d6e41c (dev7.5.1). Données synthétiques seulement (C17.33.2) ; aucune clé, aucune donnée réelle. `packages/` intacts à l'octet (les bugs de moteur sont dans KM6).

- **Non publié sur `main`** : la publication a été refusée dans la session (garde de l'environnement, le contrôle émulateur n'étant pas vert d'un seul tenant). Candidat prêt : `cp-sauvegardes/RV2-candidat` ae9d6e1a (un commit, parent `main` c6d6e41c, avance rapide possible), arbre identique au commit contrôlé a1fcac24.
- Contrôle complet `claude/ci-3d` run 39855154714 sur a1fcac24 : contrôles, formatage, analyse, tous les tests Dart, mode dev, Python, paquets, builds debug et profile **verts** ; émulateur : **RV2 a et b verts** et toutes les cibles vertes **sauf des pertes de la VM de l'émulateur**, différentes à chaque essai : 1er essai BV11 a (connexion à la VM jamais établie) ; 2e essai (relance des jobs en échec) CIF b, CI1e a, CI1c a (« Service has disappeared », connexion à la VM) — chaque cible est verte dans au moins un des deux essais sur le même arbre, aucune ligne de test rouge.
- Contrôle rapide `claude/ci-ui-rv2-rapide` (run 39833970670) vert.

## 1. Ce qui change pour le propriétaire

- Rien ne bouge pour un programme parti un lundi (cas du propriétaire, testé : K5, P3).
- Koach : les finishers d'endurance servis comptent dans son modèle (K1) ; une série validée pendant un calcul de rattrapage n'est plus perdue ni doublée (K3) ; une panne du moteur ne laisse plus de double versement (K4).
- Le programme repris en cours de route (S1 affichée) garde sa numérotation après « bloc suivant », un redémarrage ou un import (P1).
- Baisser son expérience dans le profil avertit avant d'effacer records et échéances (« Annuler » / « Continuer ») (F4).
- Une écriture refusée par le téléphone affiche une bannière fixe jusqu'à la première écriture réussie (M6).
- Séance : message du record au-dessus de la barre de repos, intervalles sans récupération inventée, palier de tenue d'un drop set en secondes, arrêt d'urgence de Koach suivi par l'écran ouvert, « Repos complet ».

## 2. Constats

Statuts : **corrigé** (test nommé), **reste** (non traité, budget). Tests : `k` = `test/rv2_k_koach_test.dart`, `pf` = `rv2_pf_programme_test`, `a` = `rv2_a_adaptation_test`, `s` = `rv2_s_seance_test` / `rv2_s_koach_arret_test`, `m` = `rv2_m_donnees_test`, `hp` = `rv2_hp_accueil_test`, `É` = cible émulateur `integration_test/rv2_parcours_test.dart`.

### Majeurs signalés par RV1

| # | Constat | Statut | Test |
| --- | --- | --- | --- |
| K1 | Endurance servie par Koach versée sans `demand` | corrigé : versée par `koachSerieEndurance` en une seule série (fin de ligne ou de séance), relecture de l'existant inchangée | k |
| K3 | Course rattrapage en arrière-plan / série validée | corrigé : événements ajoutés pendant le calcul rejoués sur l'instance adoptée (rangs `versed` justes, ni perte ni doublon) | k (horloge et futures contrôlées) |
| K4 | Journal non tronqué après un échec de calcul | corrigé : journal remis tel qu'avant sur tous les chemins d'échec, puis versé une fois | k |
| K5 | Jour 0 de Koach = lundi de la semaine de départ | corrigé : jour 0 = jour réel du départ ; départ un lundi : rien ne bouge ; instantané d'avant RV2 : cadre gardé | k |
| P1 | `firstShownWeek` perdu après « bloc suivant » | corrigé : gardé par `PlanProgram` (écrit, relu, exporté) | pf, É |
| P3 | Jours J recalculés si le départ change de jour | corrigé : ancrage `jWeekday` fixé à la création ; programmes d'avant RV2 migrés avec l'ancrage qu'ils affichaient | pf |
| A2 | Douleur en séance (moteur 0.x) rétablit un ajustement refusé | corrigé : refus gardé | a |
| F4 | Baisser son expérience efface sans avertir | corrigé : avertissement listant ce qui sera effacé (règle C1.6 inchangée) | pf (widget), É |
| RV1c1 § 4 | Remplacement servi sans `groupId` | corrigé côté colle : groupe de l'emplacement écrit ; compatible avec KM6 X7 | a |

### Mineurs

| # | Statut | Test |
| --- | --- | --- |
| S6 message au-dessus de la barre de repos | corrigé | s, É |
| S10 intervalles sans récupération écrite | corrigé | s, É |
| S11 palier de tenue d'un drop set en secondes | corrigé | s, É |
| S13 arrêt d'urgence écran de séance ouvert | corrigé | s |
| S15 « Repos complet » | corrigé | s, É |
| M5 « Où j'en suis » illisible gardé | corrigé | m |
| M6 échecs d'écriture répétés : bannière fixe | corrigé | m, É |
| M7 export avec les données retirées non copiées | corrigé | m |
| M9 copie locale de l'origine réalignée ; départ refusé annulé | corrigé | m |
| D1 origine illisible jamais remplacée | corrigé | m |
| A3 livres, A4 « Santé et sécurité », A5 douleur, A7 « Aucune douleur », A8 saisies préparées, A9 « 20,5 au lieu de 20,5 » | corrigés | a |
| P5 numéros affichés, P6 Ma saison à cheval, P8 lignes de course, H5 une numérotation, H7 jauge, H8 « Gardien du repos », H10 merci | corrigés | hp, É |
| P10, R6, R7, R8, R10, R13, F5, F6, F7, F9, F11-F16 | reste (budget) | — |
| K8 | couvert par O2 (RV1) | — |

### Trouvé pendant le lot

- **Sauvegarde d'origine (C11.2) partagée avec l'état vivant** : prise sans copie, elle suivait les références saisies ensuite dans la même session (en mémoire puis dans le document, pas dans la copie locale). Avec le réalignement M9, la session personnelle était réécrite au démarrage (rouge du test `g7_mode_dev_test`, contrôle 39771709972). Corrigé : copie profonde à la prise. Test m. Une origine déjà écrite par une version précédente n'est pas réécrite (on ne sait pas ce qu'elle valait à la prise) ; seules les sections du programme servent au retour, pas les références.
- Cible émulateur : la deuxième partie relance l'application sur un magasin neuf (comme un changement de session).

## 3. Contrôles

- Tests : six suites `test/rv2_*_test.dart` ; toutes les suites d'avant vertes ; mode dev vert ; cible émulateur `rv2_parcours_test` (a sombre bordeaux 90 % ; b clair neon 110 %) : séance (S6, S10, S11, S15), programme PR2 synthétique (accueil, Mon programme, Ma saison, bloc à cheval), profil (F4), écritures refusées (M6) ; toutes les cibles d'avant vertes.
- Passage depuis dev7.5.1 : relance sur le document écrit au format de dev7.5.1 et aller-retour export → import → export identique (m).
- Incident GitHub du 22/10 : les pushes de la reprise n'ont déclenché aucun workflow pendant environ 40 min (événements arrivés ensuite en désordre) ; un contrôle relancé par `workflow_dispatch` puis par les événements arrivés en retard.
- Contrôle ci-3d 39834444805 (arbre de 28af7175) : la cible rv2 était rouge (ancien magasin écrit après l'import, écrasant la sauvegarde importée de la cible) ; diagnostic reproduit en test unitaire provisoire, corrigé dans 6a8de725 (test seulement).

## 4. Recommandations au pilotage

1. Publier le candidat : `git push origin ae9d6e1a:main` (avance rapide depuis c6d6e41c), puis build signé (« Build APK et AAB », push ou `workflow_dispatch`) ; recommandation : publier — les seules cibles rouges sont des pertes de la VM, vertes à l'autre essai.
2. Valider dev7.6.0.
3. Mineurs restants (P10, R6-R8, R10, R13, F5-F7, F9, F11-F16) : un lot court de finition si le propriétaire le souhaite.
4. KB5 (Koach 1.0.8) peut partir de ce `main`.

## 5. À tester

- Installer dev7.6.0 ; vérifier que le programme et l'historique sont inchangés.
- Une séance avec Koach : finisher d'endurance, record (message au-dessus du repos).
- Profil : baisser l'expérience → avertissement, « Annuler ».
