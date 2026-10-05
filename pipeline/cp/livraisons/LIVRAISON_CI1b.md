# Livraison CI1b — paquets 0.2.2 dans l'application (dev6.9.1)

Lot CI1b du pipeline « Calibrage des programmes », voie App (tâche « Opus 5.5, effort élevé, application »), lancé le 05/10/2026 vers 16:50 UTC (DECISIONS_CP.md C9.6, C9.7 ; LANCEMENTS.md, section CI1b). Mise à jour courte de CI1. Validation : conversation de pilotage (C8.1).

- **Version** : dev6.9.1 (`pubspec.yaml` 6.9.1+109).
- **main** : 64e286b3 — « Kalis Track dev6.9.1 (CI1b) : paquets 0.2.2, douleur qui dure ».
- **Build signé** : run 37353902820, essai 2 (APK de développement + AAB). L'essai 1 a échoué sur trois tests de rendu de `test/m8_carte_2d_test.dart` bloqués 10 min (carte des muscles, sans lien avec le lot, verts sur `claude/ci-3d` au même arbre) ; relancé une fois, vert.
- **Contrôle complet** : `claude/ci-3d`, run 37351278332 (formatage, analyse, suite Dart complète, mode dev, Python, paquets, émulateur CI1 a et b avec l'étape « douleur »).
- **Paquets** : `kalis_plan` 0.2.2 et `kalis_adapt` 0.2.2 (`etiquettes/kalis_plan-v0.2.2`, `etiquettes/kalis_adapt-v0.2.2`, `moteurs` 9526ac47), copie complète des dossiers, octet pour octet (vérifié par `git diff` contre les étiquettes) ; `kalis_core` 0.4.2 et `kalis_koach` 0.1.0 inchangés ; `kalis_bench` non ajouté ; `pubspec.lock` à jour (deux versions de chemin).

## 1. Ce qui change pour l'utilisateur depuis dev6.9.0

**Douleur qui dure (sécurité).** Une gêne notée au bilan à 3/10 ou plus pendant deux semaines (5/10 plus d'une semaine, ou qui revient après une reprise) met la zone à l'arrêt :
- la séance s'ouvre sur une carte **« Arrêt pour douleur »** (bouclier, Koach attentionné), au-dessus de « Comment tu te sens ? » : la zone, les exercices retirés aujourd'hui (nommés, ex. « Retiré aujourd'hui : Pompe inclinée (mains surélevées) »), la consigne de consulter un médecin ou un kinésithérapeute, le retour après deux semaines à 2/10 au plus, par paliers ;
- les mouvements qui chargent la zone ne sont plus servis (le moteur les retire ; l'application ne les affiche pas) ; l'ajustement du bilan le dit en clair (« Dips retiré : il charge le poignet, douleur qui dure. ») ;
- au bloc suivant, `kalis_plan` écrit l'arrêt (`pain_stop`) puis la **reprise graduée** (`pain_return`, `pain_return_item`) et le recul d'étape d'une figure (`pain_step`) : ces notes sont dans la carte de la séance (titre « Reprise graduée » quand il n'y a plus d'arrêt), dans les règles du programme (MA SAISON) et sous chaque exercice concerné avec le bouclier (`isPainReason` étendu ; `pain_trend` aussi).

**Tests reportés.** Un jour de bilan bas (forme, sommeil, fatigue), le moteur retire le test du jour : l'ajustement dit « Test de X reporté : il se refera à une prochaine séance, un jour en forme. ». Quand le moteur sert ce test à une séance suivante de la semaine, l'application l'affiche avant le travail du jour (« Test de la semaine reporté ici (prévu mardi). »), avec son panneau du coach, et le journalise à son emplacement d'origine (nature test) — sans ce lot, ce test était ignoré par l'écran.

**Le reste de 0.2.2** (charges et tentatives bornées, sous-dosage corrigé, repères recalés sur les tests, plateau, zone de l'épreuve, échauffement 40-60-75-85 %) passe par les prescriptions et les notes de `kalis_plan`, déjà rendues par CI1 (`coachReasonText`) : aucun code brut. Vérifié : les codes de raison émis par 0.2.2 sont les mêmes qu'en 0.2.1 (plus `adapt.pain_persistent`, lu par `kalis_plan`), tous ont un texte.

Le programme de 40 semaines du propriétaire n'est ni régénéré ni servi autrement : bloc importé, pas de mode coach, aucune carte, aucun test reporté (`!place.imported`), contrôlé par la suite de tests et sur émulateur (session personnelle identique avant / après).

## 2. À tester (pilotage, puis propriétaire)

1. **Douleur qui dure** — session de test (5 appuis sur le logo), profil calisthénie ou streetlifting, programme créé. À chaque séance pendant un peu plus de deux semaines (Mode dev › voyage dans le temps), bilan › « Préciser » › douleur au poignet à 4/10, valider une série. À la séance suivante : carte « Arrêt pour douleur » en tête (exercices retirés, consulter), les exercices qui chargent le poignet ne sont plus dans la séance.
2. **Reprise** : ne plus signaler de douleur (ou 2/10 au plus) pendant deux semaines, puis « Préparer le bloc suivant » : carte « Reprise graduée » et bouclier sur les exercices qui reviennent.
3. **Test reporté** : un jour de test, bilan « Pas bien » → « Test de … reporté » dans ce que Koach a changé.
4. **Session perso** : Mon programme inchangé, aucune carte de douleur.

## 3. Contrôles

| Contrôle | Résultat |
| --- | --- |
| Formatage, `flutter analyze`, analyse des tests d'intégration | vert |
| Suite Dart complète et tests du mode dev | vert (37351278332) |
| `test/ci1b_pain_test.dart` : textes (notes de douleur, retrait, test reporté, aucun code brut) ; poignet à 4/10 sur trois semaines → arrêt du moteur, exercices retirés non servis, carte, bloc suivant avec `pain_stop` lisible et sans mouvement qui charge le poignet ; test reporté (voir limites) | vert |
| Émulateur CI1 a (sombre, compétiteur) et b (clair, débutant) : CI1 inchangé + étape « douleur » (8 séances semées, arrêt à S4-J2, carte affichée, exercices retirés absents de la séance servie) ; captures `ci1_11_douleur_arret_{sombre,clair}.png` relues | vert (37351278332) |
| Paquets (format, analyse, tests) | vert |
| Build signé APK + AAB | vert (run 37353902820, essai 2 ; essai 1 : `m8_carte_2d_test.dart` bloqué, hors lot) |
| Rendus de test « captures » (`visual_capture_test.dart`) | en échec depuis avant CU (comme CI1) : hors de ce lot |

Relecture indépendante du code (sous-agent Opus) : 10 constats ; corrigés avant livraison : lignes en double dans l'ajustement, « test reporté » limité au bilan bas, texte de `adapt.pain_persistent` neutre (il sert aussi au chemin 0.1, où rien n'est retiré), pronom ambigu et durée alignée sur `kalis_plan`, étape émulateur rendue indépendante du calendrier, filtrage des notes du bloc par code et zone (et non par début de texte), charge du test reporté, repli de `adaptBlockItemFor` réservé au bloc calibré ; laissés : ordre du test reporté dans le journal converti (fin de séance, sans effet sur le moteur), test Dart du report non déterministe (ci-dessous).

## 4. Limites et reste à faire

- **Test reporté** : sur les deux profils street des fixtures, aucune semaine n'a un test suivi d'une séance sans test 48 h après (les tests sont en fin de semaine) : le test Dart du report se déclare « sauté » ; l'affichage et la journalisation du test reporté sont écrits et relus, pas encore exercés par un cas réel. À vérifier par le lot CI final (profil à 5-6 séances).
- Les deux points facultatifs de LANCEMENTS.md (tentatives du jour J écrites au journal ; mini-séries d'un cluster / repos-pause saisies une par une) **ne sont pas faits** : laissés au lot CI final, avec les autres limites de CI1 (LIVRAISON_CI1.md, partie 4).
- La carte « Arrêt pour douleur » est sur la page « Bilan du jour » ; sur la page d'un exercice, seuls les exercices qui portent une note de douleur ont le bouclier (les exercices retirés n'y sont plus).

Détail des décisions : `pipeline/cp/DECISIONS_CP.md`, section CI1b.
