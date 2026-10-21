# RV1 — constats bruts des sous-agents (à vérifier)

Zones : S séance · P programme/plan · K colle Koach · M magasin/sauvegarde · A adaptation 0.x/bilan · H accueil/stats/jeu · R réglages/kit/thèmes/notifs · F profil athlète · X paquets (lecture).

## Propriétaire
- O1 charge poulie 20,41 kg (grille câble 2,5 lb par défaut de kalis_adapt, aucun loadIncrements donné par l'app) ; affichages 20,41 / 20.41 / 20,5.
- O2 intervalles 8×(30/30) : 1 ligne écrite, n lignes Koach ; groupe `rounds` non recalé quand Koach coupe des tours.
- O3 minute d'EMOM ratée : indication dans `_timingHeader` et groupes emom.
- O4 EMOM volume (KB4) : à revérifier.

## Majeurs
- S1 session_screen 1123-1139 : snack Koach effacé par record / « Enchaîne ».
- S2 repos individuel dans les groupes du moteur (circuit 3, emom sans technique).
- S3 koachKg / adaptKgField « 22, » (toStringAsFixed + trim).
- S5/R2 lb : session_screen:2092 cible Koach ignorée en lb.
- P1 PR2 perdu après bloc suivant depuis instance générée.
- P2 Départ du programme ignore firstShown.
- P3 J d'un programme créé recalculé si start change de jour.
- K1 séries d'endurance servies non comptées par le modèle.
- K3 course rattrapage / séance en cours.
- K4 journal non coupé en cas d'exception (doubles versements).
- K5 koachLundi vs program.start non lundi.
- K6 séance ouverte déclarée manquée.
- K7 proposition contourne la charge fixe C15.
- M1 programInstance perdu (import strict insuffisant, pas de copie brute).
- M2 isConsultation ignore groups (AMRAP perdus).
- M3 exportCompact sans marqueur session de test.
- M4 koachEngine illisible effacé.
- A1 exercice retiré par bilan (douleur/temps) sans ajustement montré quand base null.
- A2 _adaptReprescribe remet choice/advice.
- H1 accueil : week figée → StateError (programme plus court) / semaine 0.
- H2 tenues/durées/distances comptées en reps (records, 1RM).
- H3/H4 S${n} bruts (home 287, game_widgets 1016, campagne/boss/saisons).
- R1 themeFor cache sans intensité/densité.
- R3 notifications ID > semaine 40 jamais annulés.
- R4 TextField invisible en clair (fill = fond, bordure transparente).
- R5 segment/puce choisis indiscernables Bordeaux sombre.
- F1 pesée remise à l'ancien poids en éditant une rubrique.
- F2 « Je ne sais pas » efface tous les records.
- F3 édition record/figure perd source/protocolId/assessedOn.
- F4 baisse d'expérience efface sans prévenir (voulu C1.6 : signaler).

## Mineurs (sélection)
- S6 snack lu avant startRest ; S7 « départ toutes les 1 min », « 1 tours » ; S8 titre jour de repos S${n} ; S9 bouton Repos sans effet ; S10 récup inventée intervalles ; S11 drop set palier tenue ; S12 popup flammes ; S13 arrêt d'urgence écran ouvert ; S14 setState après flush ; S15 « Repos complet » en capitales.
- K8 intervalles rounds ; K9 S${r.week} récap ; K10 koachStop sans gen++.
- M5 programResume ; M6 persistenceError répété ; M7 export retirés ; M8 texte suppression ; M9 origine périmée.
- A3 lb ignoré dans textes moteur ; A4 SafetyScreen renvoi ; A5 textes douleur périmés ; A6 double appui bilan ; A7 _removePain ; A8 saisies vidées nouveau jour ; A9 « 20,5 au lieu de 20,5 ».
- H5 deux séries de semaines ; H6 Endurance available ; H7 jauge journées masquées ; H8 Gardien du repos ; H9 accueil pas à la nouvelle semaine ; H10 merci jamais affiché ; H11 séries excluded ; H12 « 1 exercices », recherche accents, saisons 40 semaines.
- P5 textes S40 internes ; P6 Ma saison bloc à cheval ; P7 échéance de fin masquée ; P8 lignes programme créé lues en reps ; P9 « 1 exercices » ; P10 cache sans mode prudent.
- R6 prochain rappel GtG ; R7 signature replanif ; R8 Display3DSettings ; R9 clavier « Voir l'aperçu » ; R10 contraste renforcé haute ; R11 « 90 s » ; R12 lb « 137.8 » ; R13 Sources et licences ; R14 séparateurs Arsenal.
- F5 poids visé ; F6 messages techniques $.x ; F7 priorité code ; F8 mois passé ; F9 catégorie fantôme ; F10 hardSets 0 ; F11 niveaux perdus ; F12 calendrier initialDate ; F13 carte 2D périmée ; F14 controllers ; F15 saisies ignorées ; F16 test perso.

## Paquets (lecture, pour un lot moteur)
- X1 grid.dart:35/67 poulie en livres (2,5 lb) ≠ kalis_plan (2,5 kg).
- X2 Koach coupe des tours d'intervalles sans renvoyer rounds.
- X3 Koach coupe les séries sans recaler la technique (EMOM intervals, pyramide…).
- X4 test xRM verrouillé servi sous l'écrit hors grille (plancher).
- X5 proche() après plafond dépasse d'un demi-cran.
- X6 test adaptatif cran au-dessus du plafond.
