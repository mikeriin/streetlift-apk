# Livraison CI1e — le programme de 40 semaines sous toutes les fonctionnalités (dev6.10.0)

Lot CI1e du pipeline « Calibrage des programmes », voie App (tâche « Opus 5.5, effort élevé, application »), lancé le 09/10/2026 vers 06:05 UTC (DECISIONS_CP.md C11 ; LANCEMENTS.md, section CI1e), en parallèle de CY. Validation : conversation de pilotage (C8.1).

- **Version** : dev6.10.0 (`pubspec.yaml` 6.10.0+112) : changement structurant (le programme de 40 semaines devient un programme suivi par les moteurs : blocs, saison, mode coach).
- **main** : 238078ee — « Kalis Track dev6.10.0 (CI1e) : programme de 40 semaines sous toutes les fonctionnalités ».
- **Build signé** : run 37903901420 (APK de développement + AAB).
- **Contrôle complet** : `claude/ci-3d`, run 37901114754 (essai 2 ; l'essai 1, run 37896487692, avait la cible CI1 en échec sur une attente d'avant C11 — « session personnelle sans saison » — et la carte « Ton programme d'origine » restait périmée après le retour : corrigés) (formatage, analyse, suite Dart complète, mode dev, Python, paquets, émulateur CI1e a et b, puis CI1c et CI1 a et b).
- **Paquets** : inchangés (`kalis_core` 0.4.2, `kalis_plan` / `kalis_adapt` 0.2.3, `kalis_koach` 0.1.0) ; rien n'est touché dans `packages/` : aucun changement de `kalis_adapt` n'a été nécessaire (le découpage en blocs de 6 semaines au plus suffit, partie 2).
- Mise au point : `claude/ci-ci1e-rapide` (essais 1 à 7 ; essai 4 : suite complète et mode dev verts, run 37895863012).

## 1. Exclusions du programme importé (recensement) et ce qui les lève

Recensement complet fait sur `main` bd1f0c97 (63 points, sous-agent Opus). Cause racine : le programme importé était porté dans **un seul bloc de 40 semaines sans aucun champ du contrat 0.4.0** ; `kalis_adapt` le servait donc « comme en 0.1 » (`blockCoached` faux) et le tenait pour non restructurable (`BlockView.imported` = plus de 6 semaines), et l'application ajoutait ses propres gardes.

| Exclusion (avant) | Où | Levée par |
| --- | --- | --- |
| Bloc unique de 40 semaines, sans intention ni champ 0.4.0 → pas de mode coach (`blockCoached` faux) | `session_adapt_store.dart` (`_adaptBuildImported`) ; `kalis_adapt` `coach.dart`, `replay.dart` | annotation 0.4.0 (partie 2) : intentions de bloc et de semaine, RIR, tests, clusters → mode coach |
| Bloc de plus de 6 semaines « jamais restructuré » : aucune proposition de séance, de bloc ni d'échange | `kalis_adapt` `replay.dart` (`imported`), `review.dart` (`structural`) | blocs de 6 semaines au plus (partie 2) |
| Déblocage compté en semaines/6 pour le bloc importé | `kalis_adapt` `review.dart`, `evolution_store.dart` | rang du bloc (`blockIndex`) |
| Emplacements tous verrouillés (`locked: true`) : échanges et restructurations impossibles | `_adaptBuildImported` | `locked: false` |
| Propositions filtrées « ne peut pas s'appliquer jour pour jour » (carte sans « Accepter ») | `evolution_store.dart` (`evolutionReceive`, `evolutionApplicable`), `importedLayoutKept` | garde retirée ; la couche montre aussi les journées restructurées (ajout, retrait, déplacement d'un jour à l'autre) |
| Pas de saison pour le moteur (`adaptSeasonOf` nul) ; MA SAISON, compte à rebours, Jour J inaccessibles (`storeSeasonOverview` exige un programme créé) | `session_adapt_store.dart`, `plan/season_view.dart`, `program_screens.dart` | saison de l'annotation (phases, échéance fin S40) ; carte « Ta saison », MA SAISON, Jour J |
| Pas d'échéance pour le moteur (approche, affûtage, `daysToEvent`) | `kalis_adapt` `BlockView` (événements du profil) | échéance « Fin du programme (S40) » donnée au moteur tant que le programme importé est en place et que le profil n'a pas d'échéance principale (jamais écrite dans le profil) |
| Conduite sous douleur du mode coach (arrêt, carte « Arrêt pour douleur », reprise graduée, renvoi) | `kalis_adapt` `session.dart`, `pain_return.dart`, `review.dart` ; `coach_texts.dart` (`isCoachBlock`) | mode coach (testé : arrêt après deux semaines à 4/10) |
| Tests reportés (servis un autre jour) | `session_adapt_store.dart` (`adaptDay`, `adaptBlockItemFor` : `!place.imported`) | gardes retirées ; identifiant `k<S>.<J>.<emplacement>` relu |
| Résultats des tests jamais reportés au profil | `evolution_store.dart` (`evolutionRefresh`) | garde retirée |
| « Préparer le bloc suivant » impossible (exige un programme créé) | `plan_store.dart`, `program_screens.dart`, `plan/plan_screens.dart` | à la dernière semaine d'un bloc du programme (P0, B1…) ou après S40, Mon programme propose le bloc suivant du moteur calibré (jamais imposé) |
| Textes « Programme embarqué, inchangé », « jamais régénéré (D5.10) », « identique jour pour jour » | `program_screens.dart`, `profile_completion.dart`, `plan/plan_evolution.dart`, `session_adapt_store.dart` | réécrits |
| Mode 0.1 de `kalis_adapt` pour un bloc sans champ 0.4.0 | `kalis_adapt` | non touché (règle des autres programmes 0.1) : le programme importé n'y passe plus |

Non concernés (vérifiés) : tests guidés (`guided_tests.dart`, pas de garde), `legacy_adapt_data.dart` (lecture seule des anciennes adaptations L11), `keepLegacyEngine` (choix du moteur 0.1 d'un programme créé), inspecteur du mode dev (libellé « importé » seulement).

**Pour CY** (LANCEMENTS, section CY) : `kalis_adapt` n'a pas d'autre branche « bloc importé » que `BlockView.imported` (plus de 6 semaines) ; l'annotation la rend sans objet. Rien à rendre configurable.

## 2. Annotation du programme (déterministe, à la lecture)

Fichier `lib/imported_program.dart`. Le programme d'origine reste lisible et n'est jamais réécrit ; l'annotation est recalculée à la lecture.

- **Blocs** (`legacy-programme-v33/S<n>`) : un bloc par bloc du programme, coupé après une semaine allégée au-delà de 6 semaines. Programme du propriétaire : S1-3 (phase 0), S4-7 et S8-11 (hypertrophie), S12-15 et S16-19 (force), S20-25 (force max), S26-31 (endurance), S32-35 et S36-40 (peaking).
- **Intention de chaque semaine** : allégée, test (natures du programme), introduction (phase 0, familiarisation), sinon la phase du bloc d'après son titre et son cycle : hypertrophie et endurance → accumulation (« pic de volume » compris), force et réintensification → intensification, force max, peaking, singles, simulation → réalisation (montées d'un bloc de force max → intensification).
- **Intention du bloc** : phase, rang dans la saison, échéance, semaines jusqu'à l'échéance.
- **Saison** : blocs consécutifs de même phase réunis (7 phases), échéance « Fin du programme (S40) » le 18/04/2027 pour un départ le 13/07/2026.
- **Lignes** : intensité en RIR (« RIR 2 », « RIR 2-3 ») ; tests de répétitions ou de maintien max (« 1 × maximum », « N× max effort ») ; test de 1RM (« Montée en singles puis 3 tentatives ») écrit comme `kalis_plan` : une ligne par tentative, charges montantes calculées par le moteur, singles de montée hors journal ; clusters (« 6×3 en clusters (30 s intra) ») : technique `cluster`.
- **Emplacements stables** d'une semaine à l'autre (`j<J>-<exercice>`, `#2` pour une deuxième ligne du même exercice le même jour) : le moteur suit la même ligne de semaine en semaine (marques de séance, double progression).
- **Restent absents** (servis tels qu'écrits, sans cible du moteur) : myo-reps (« 1×15 puis 4×(4) », 154 lignes : le journal les note en 5 lignes, le contrat en 1), durées (« 10 min », 76), séries longues à volume calculé sans référence renseignée (« N × ? reps »), EMOM, contrastes (« 3 rounds : … », 20), HIIT (28), échelles (3), séries de référence « Note ton RIR » (laissées en séries de travail).
- Sûreté : chaque prescription et chaque bloc sont validés au contrat ; une annotation hors contrat est retirée (ligne servie comme avant), un bloc hors contrat est servi sans champ 0.4.0 plutôt que perdu.

## 3. Filets (C11.2)

- **Sauvegarde d'origine automatique** (`lib/program_origin.dart`) : prise au premier lancement de 6.10.0 (avant toute migration), à l'import d'une sauvegarde d'avant 6.10.0, ou au démarrage d'un programme importé : programme **et journal** au format d'une sauvegarde Kalis Track. Écrite dans le document de l'appli (section `programOrigin`, donc dans chaque sauvegarde exportée) et, à part, dans le stockage local ; « Exporter cette sauvegarde » (Réglages › Mon programme) l'écrit en fichier (importable telle quelle ; l'avertissement dit qu'un import remplace tout).
- **« Revenir à mon programme d'origine »** (Réglages › Mon programme, carte « Ton programme d'origine », confirmation) : départ, programme créé, « Où j'en suis », évolution rendus exactement (testé section par section) ; journal, profil, références et réglages gardés. Refusé (en clair) si un programme créé depuis a déjà des séances saisies : elles ne correspondraient plus aux journées rendues.
- **Ajustements de Koach de 6.9.2/6.9.3** (bloc unique) : ramenés sur les nouveaux blocs au premier lancement (même changement, semaine, journée et emplacement convertis ; un ajustement qui couvre plusieurs blocs est partagé) : toujours appliqués et annulables (testé).
- **Séances enregistrées par 6.9.3** (prescription du moteur dans le journal) : relues sur le bloc annoté de leur semaine, sans réécrire le journal (testé).
- Séances faites et séries validées jamais réécrites ; la couche ne touche pas une séance faite et ne déplace pas un exercice d'une séance faite. CI1c intact (Koach appliqué tout de suite, séance non commencée recalculée, consultation sans entrée : tests CI1c verts et émulateur CI1c).
- « Supprimer toutes les données » retire aussi la sauvegarde d'origine (testé).

## 4. À tester (téléphone du propriétaire, programme de 40 semaines)

1. **Mon programme** (Réglages › Mon programme) : carte « Ta saison » (phase en cours, « Fin du programme (S40) dans N semaines ») et « Voir la saison » (MA SAISON : phases, semaines du bloc, Jour J) ; carte « Ton programme d'origine » (date de la sauvegarde).
2. **Séance du jour** : servie par le moteur en mode coach (charges et répétitions du moteur, conseils entre les séries, lignes de clusters) ; ton journal d'avant est relu normalement.
3. **Koach** : Évolution montre le déblocage par blocs ; ses vraies propositions (volume, échange, séance réorganisée) s'appliquent à ton programme et restent annulables.
4. **Retour** : après un ajustement, « Revenir à mon programme d'origine » rend le programme d'avant ; tes séances faites restent.

## 5. Contrôles

| Contrôle | Résultat |
| --- | --- |
| Formatage, analyse (dont tests d'intégration) | vert |
| Suite Dart complète (788 tests) et mode dev | vert (contrôle complet, run 37901114754) |
| `test/ci1e_programme_40s_test.dart` : découpage et phases ; annotation (9 blocs valides au contrat, mode coach, aucun emplacement verrouillé, semaines allégées et de test, saison contiguë de 40 semaines, échéance 18/04/2027, emplacements stables S12-S14, clusters, 1RM, tests max, lignes absentes listées) ; migration 6.9.3 → 6.10.0 (sauvegarde d'origine prise, séances du moteur de 6.9.3 relues sur le bloc annoté, journal non réécrit, journal présenté au moteur rattaché) ; séance du jour en mode coach, saison, compte à rebours, échéance donnée au moteur ; douleur qui dure → arrêt (mode coach) ; propositions réelles (relevé) et restructuration acceptée (exercice ajouté montré et servi) puis annulée ; ajustement accepté en 6.9.3 ramené, appliqué, annulable ; effacement complet ; retour au programme d'origine (sections identiques, journal gardé, fichier exporté importable) | vert |
| Tests existants adaptés (C11 remplace D5.10) : G9 « programme du propriétaire porté tel quel » (bloc annoté de 4 semaines au lieu de 40) et bloc des séances au journal ; G9 « résumé de fin de séance » (résumé plus long en mode coach : défilement jusqu'au bouton) ; versions | vert |
| Émulateur CI1e a (sombre, rouge) et b (clair, violet), session perso : sauvegarde d'origine prise au premier lancement de 6.10.0 ; 9 blocs, bloc du jour `legacy-programme-v33/S12` (S13·J3) ; carte « Ta saison » et compte à rebours (« Fin du programme (S40) dans 27 semaines (193 jours) »), MA SAISON (7 phases, intensification en cours) ; carte « Ton programme d'origine » ; séance du jour servie en mode coach ; une série de plus appliquée (mode assisté) → « Ton programme a changé depuis » → « Revenir à mon programme d'origine » (confirmation) → carte « encore celui d'origine », aucune section différente. Relevés `ci1e_releve_a.json`, `ci1e_releve_b.json` ; captures `ci1e_01` à `ci1e_08`, sombre et clair, relues | vert |
| Émulateur CI1c a et b, CI1 a et b (non-régression) | vert (cible CI1 : la session personnelle a maintenant sa saison, attente mise à jour) |
| Paquets | inchangés, vert |
| Build signé APK + AAB | vert (run 37903901420) |

Relecture indépendante du code (sous-agent Opus) : 17 constats. Traités : ajustements de 6.9.3 qui auraient disparu (migration ajoutée, testée) ; « Supprimer toutes les données » qui gardait la sauvegarde d'origine (corrigé, testé) ; test de 1RM servi comme 6 tentatives (une ligne par tentative, comme `kalis_plan`) ; retour à l'origine marqué « changé » par une simple proposition en attente (ignorée) et dialogue complété (mode assisté, « Où j'en suis ») ; retour refusé quand un programme créé depuis a des séances ; ordre avec le filet G2 au démarrage ; coût de la comparaison (sections du programme seulement, gardée par révision) ; échéance retirée quand un programme créé suit ; bloc hors contrat servi sans champ 0.4.0 ; champs internes de la séance relue ; jours de la semaine de l'historique des blocs précédents ; bloc suivant proposé aux fins de bloc du programme seulement, texte après S40 ; avertissement d'export ; sauvegarde prise au démarrage d'un programme ; exercice d'une séance faite jamais déplacé. Restent (mineurs, consignés) : coût de l'annotation recalculée quand une référence change (synchrone, quelques millisecondes sur 40 semaines) ; profil au schéma 2 : l'échéance n'est pas donnée au moteur (refusée par le contrat), la saison s'affiche quand même.

## 6. Limites et reste à faire

- Sur le journal synthétique des tests, la revue réelle ne fait aucune proposition (déblocage « restructuration de bloc » atteint) ; l'acceptation est testée sur des propositions construites. Sur ton journal réel, les propositions viendront du moteur.
- Myo-reps, EMOM, contrastes, échelles et HIIT restent servis tels qu'écrits (format sans équivalent propre au contrat ou noté autrement par le journal).
- Après un retour à l'origine en mode assisté, Koach peut de nouveau appliquer ses propositions (C11 : toutes les fonctionnalités s'appliquent) ; en mode libre, tu décides de chacune.
- Une proposition du moteur calibré pour le bloc suivant remplace la suite du programme : proposée seulement à la fin d'un bloc du programme, jamais imposée ; retour possible pendant 7 jours (comme tout nouveau programme) et par la sauvegarde d'origine.

## 7. Recommandation (C8, le pilotage décide)

Valider dev6.10.0 et la donner au propriétaire à la place de dev6.9.3 : son programme de 40 semaines est désormais suivi par les moteurs comme un programme du moteur (mode coach, saison, tests, douleur, propositions, bloc suivant), sans rien perdre (sauvegarde d'origine, retour, ajustements et séances d'avant relus). Les paquets 0.3.0 (CP2, CA2) puis ceux de CY entreront par le lot d'application suivant.

Détail des décisions : `pipeline/cp/DECISIONS_CP.md`, section CI1e.
