# Contrat L11 — Koach étendu : adaptation au jour le jour (4.1.0)

**27 septembre 2026, lot exécuté par le pipeline automatisé (sans échange en direct).** Tickets KT-058 à KT-064. Code : `lib/koach_adapt.dart` (règles pures, sans horloge ni Flutter), `lib/adapt_store.dart` (branchement sur le store), `lib/adapt_screens.dart` (écrans). Tests : `test/l11_adapt_test.dart`, `test/l11_store_test.dart`, `test/l11_screens_test.dart`.

Toutes les décisions de L7 (Koach) restent valables : validation, verrous, plafonds, rejeu déterministe. L11 n'écrit **aucune** valeur de pilotage en dehors des chemins de L7 (proposition acceptée, saisie) et du mode Guidé décrit au §7.

## 1. Base et contradictions relevées

| Point | Constat | Traitement |
| --- | --- | --- |
| Base | `streetlift_tracker_v33.zip` 4.0.0+67 (L10), `main` `5d38177`, 2 137 835 octets, SHA-256 `2cd7c9a595bc5a3eb293b587db708c26f826865d68d9fe902dee40a94850affc`, racine unique `streetlift_tracker/` | Travail sur copie |
| Contrats lus | `CONTRAT_L7.md` (Koach), `CONTRAT_L8.md` (profil), `CONTRAT_L10.md` (générateur), `DEPART_PROGRAMME.md` (L4), `SEANCES_ET_REPRISE.md` (L4b) | — |
| « Le plan glisse » (KT-060) et L4 « pas de décalage automatique : une séance manquée ne déplace rien » | Le prompt L11 (propriétaire) demande que le plan glisse ; L4 avait décidé l'inverse | Le plan glisse **sur proposition** (un tap, annulable), et d'office seulement à la fin d'une pause déclarée (vacances, maladie). Les identifiants S·J, les dates réelles et l'historique ne changent jamais : seul le départ (S1·J1) est décalé, comme dans Réglages → Départ. D-L11-01 |
| Modes d'autonomie (KT-063) et L7 D4 « aucune valeur de pilotage modifiée sans un tap » | Le prompt demande qu'en mode Guidé les baisses soient appliquées d'office | Appliqué **seulement** en mode Guidé, avec message et annulation ; Assisté = comportement L7 inchangé. Un profil migré dont le mode n'a jamais été choisi (source « estimé ») et une installation sans profil restent en **Assisté**. D-L11-02 |
| Charge de séance (KT-064) et L7 D8 « difficulté obligatoire » | Le prompt rend le RIR facultatif pour les débutants et novices en Guidé ou Assisté | D8 ne s'applique plus à ces profils ; il reste inchangé pour les autres. D-L11-09 |
| « Adaptation à l'assiduité : ≥ 90 % pendant 2 cycles » | Les cycles varient (programme de 40 semaines, cycles L10 de 5 à 6 semaines) | Deux fenêtres glissantes de 4 semaines. D-L11-06 |
| « Une séance de moins / de plus par semaine » | Le programme de 40 semaines (modèle Expert streetlifting) a une structure fixe de 7 jours | Proposé seulement pour un programme généré (jours du profil modifiés, puis régénération L10 avec aperçu, annulable 7 jours) ; pour le programme de 40 semaines, seule l'option « séances 20 % plus courtes » est proposée. D-L11-07 |
| Plateau (KT-062) : niveau « novice » non cité | Le prompt cite débutant, intermédiaire, avancé et expert | Novice traité comme débutant (point technique). D-L11-08 |
| Rappels pendant une pause | Les rappels L4 continuent sans règle contraire | Suspendus pendant une pause, replanifiés au retour. D-L11-04 |

## 2. Décisions prises par défaut (réversibles)

| Id | Décision | Pourquoi / comment revenir |
| --- | --- | --- |
| D-L11-01 | Plan qui glisse : carte « Reprendre là où tu t'es arrêté » quand la journée qui suit la dernière journée faite est passée ; « Faire glisser » décale le départ du nombre de jours de retard (annulable dans Adaptation au quotidien → Historique tant que le départ n'a pas changé). Aucune proposition tant qu'aucune séance n'a été faite. Fin de pause : glissement appliqué d'office. | Respecte L4 (identifiants et dates réelles intacts) |
| D-L11-02 | Mode effectif : champ `autonomy` du profil, sauf profil migré jamais choisi → Assisté ; sans profil → Assisté (réglable dans Adaptation au quotidien) | Aucun changement de comportement pour une installation existante |
| D-L11-03 | Reprise : épisode = dernier arrêt ≥ 7 jours entre deux jours d'entraînement (séances terminées et séries validées, séances perso comprises) ; « une séance par mouvement » = première séance de la reprise contenant ce mouvement principal ; 28 jours et plus : toute la première semaine ; au-delà de 42 jours après le début de la reprise, plus d'allègement | Déterministe, lu dans le journal |
| D-L11-04 | Pause (vacances, maladie) : rappels suspendus ; au retour, le plan glisse ; les jours de pause sont exclus du calcul d'assiduité | Réglages → Adaptation au quotidien |
| D-L11-05 | Séance d'entretien de vacances : ajoutée aux séances perso sur demande (5 exercices sans matériel ni saut, 3 séries, repos 45 s) ; aucune séance créée d'office | Supprimable comme toute séance perso |
| D-L11-06 | Assiduité sur 4 semaines glissantes (≥ 4 séances prévues, sinon rien) ; « 2 cycles » = 2 fenêtres de 4 semaines ; progression = pente positive d'au moins une estimation sur 8 semaines | Registre de validation |
| D-L11-07 | « Séances 20 % plus courtes » = compression automatique de chaque séance à venir à 80 % de sa durée estimée (règles du §3) | Interrupteur dans Adaptation au quotidien |
| D-L11-08 | Plateau : novice traité comme débutant ; « décharge puis nouveau bloc » = semaine suivante en décharge (séries principales × 0,6, charges −10 %) ; le nouveau bloc orienté sur le point faible reste à régénérer par l'utilisateur (Mon programme) | Le programme de 40 semaines ne se réécrit pas |
| D-L11-09 | Question de difficulté globale posée aux débutants et novices (niveau L10, sinon repère du profil) en Guidé ou Assisté ; durée = fin − première série (5 à 300 min), sinon estimation | « Passer » toujours possible |
| D-L11-10 | Échange : même type de mouvement, difficulté ±1, matériel disponible dans les lieux du profil, au moins un groupe musculaire principal commun, jamais un exercice détesté ; douleur : contrainte articulaire ≤ l'original pour chaque articulation (une articulation absente chez l'original compte 0) ; échange possible avant la première série de l'exercice seulement | Registre de validation |
| D-L11-11 | Charge initiale d'un substitut : 80 % de la charge prescrite de l'original si les deux se chargent de la même façon (pas de 1 kg sous 10 kg, sinon 2,5 kg, arrondi inférieur) ; sinon aucune charge proposée ; RIR visé de l'original conservé ; la première série est présentée comme un calibrage | Prudence |
| D-L11-12 | Guidé : au bilan, baisses de valeur (`down`, `accDown`) et allègement douleur acceptés d'office et annulables ; les hausses restent proposées ; une douleur notée dans le bilan lui-même reste une proposition | Annulation = valeur précédente rétablie (saisie datée) |
| D-L11-13 | Allègement proposé après un message de prudence : séries × 0,8 (au moins 1, prévention exceptée) jusqu'au dimanche de la semaine civile | Levable dans Adaptation au quotidien |
| D-L11-14 | Semaine de retour de maladie en Assisté ou Expert : proposée sur la séance (« Appliquer » / « Garder le prévu ») ; en Guidé : appliquée, « Annuler » | KT-063 |

## 3. Séance compressée (KT-058)

« J'ai seulement… » (menu de la séance) : 15, 20, 30, 45, 60, 75 ou 90 minutes, avant ou pendant la séance. Durées estimées par `training_estimate.dart` (effort et repos par série de chaque exercice, 45 s de transition entre blocs, échauffement réduit 3 min).

Ordre des étapes, chacune seulement si la durée dépasse encore le temps disponible :
1. Échauffement (montée en charge, activation, mobilité) remplacé par 3 minutes ; retour au calme retiré ; prévention ramenée à 1 série (jamais supprimée).
2. Accessoires enchaînés deux par deux, sans groupe musculaire commun (ordre du programme).
3. Retrait des exercices de plus faible priorité : circuits et travail spécifique, puis accessoires, de la fin de la séance vers le début.
4. Mouvements principaux ramenés vers 2/3 de leurs séries (arrondi supérieur), une série à la fois, le plus fourni d'abord.

Pendant la séance : les séries validées restent, aucun échauffement n'est ajouté, un exercice commencé n'est pas retiré. Si le temps demandé ne suffit pas même avec les principaux aux 2/3, la durée minimale est affichée. Aperçu des différences avant validation ; « Séance complète » rétablit les séries. Seules les prescriptions « N×… » sont réduites (pas les myo-reps, montées, EMOM).

## 4. Matériel absent et échange (KT-059)

- **Je m'entraîne ailleurs** (menu de la séance) : lieu choisi → chaque exercice dont le matériel manque est remplacé par le premier substitut (§2 D-L11-10) ; sans équivalent, il est signalé « à passer ou à remplacer toi-même ».
- **Échanger un exercice** : motif (matériel pris, gêne ou douleur, envie) → 3 propositions classées (groupes communs, écart de difficulté, même mode de charge, démonstration animée, puis identifiant) ; « Exercice d'origine » annule.
- Le substitut est journalisé sous l'identifiant `origine~pack` avec son nom (historique, records) ; Koach ne l'utilise pas pour ses estimations.

## 5. Séances manquées, vacances, maladie (KT-060)

| Arrêt | Mouvements principaux | Durée |
| --- | --- | --- |
| 7 à 13 jours | charges −10 %, −1 série | 1 séance par mouvement |
| 14 à 27 jours | charges −20 %, série 1 = calibrage (arrêt à 2-3 répétitions en réserve) | 1 séance par mouvement |
| 28 jours et plus | charges −30 %, semaine de calibrage (tests légers de L10) | 7 jours |

- Charges arrondies au pas inférieur (2,5 kg ; accessoire : pas du programme). Le plan glisse, aucune séance n'est doublée (§2 D-L11-01).
- **Vacances** : calendrier en pause, rappels suspendus, séances d'entretien facultatives (2 × 20 minutes sans matériel par semaine).
- **Maladie** : pause ; au retour, première semaine à volume −30 % (séries × 0,7) et RIR visé +1 (Koach) ; message « si les symptômes persistent, parles-en à un professionnel de santé ». Aucune question sur la maladie.

## 6. Assiduité (KT-061) et plateau (KT-062)

- Taux sur 4 semaines glissantes (séance faite = terminée ou au moins une série validée) : < 60 % → « une séance de moins par semaine » (programme généré) ou « séances 20 % plus courtes » ; 60 à 89 % → rien ; ≥ 90 % sur deux fenêtres de 4 semaines avec progression → « une séance de plus » si tu le souhaites. Textes sans culpabilisation.
- Plateau : estimation hebdomadaire par mouvement principal (meilleure série de la semaine du programme, formule d'Epley sur la masse soulevée — poids du corps + lest pour les mouvements lestés au poids du corps —, sinon répétitions + RIR) ; pente < +0,5 %/semaine sur 4 semaines (3 points au moins, dont la semaine en cours ou la précédente), assiduité ≥ 80 %, aucun signal de fatigue (jour de fatigue Koach, ou deux séances notées ≥ 9/10), aucune semaine de décharge dans la fenêtre → proposition selon le niveau : débutant et novice → point technique et variation des répétitions ; intermédiaire → plage de répétitions ou variante ; avancé et expert → décharge puis nouveau bloc.

## 7. Modes d'autonomie (KT-063)

| Mode | Pendant la séance (D24) | Jour de fatigue (D25) | Bilan (D5 b) | Reprise, maladie (L11) |
| --- | --- | --- | --- | --- |
| Guidé | baisses appliquées d'office ; hausse seulement si RIR ≥ visé + 2 ; message + « Annuler » ; rien à valider | appliqué d'office, « Annuler » | baisses et allègement douleur acceptés d'office, « Annuler » ; hausses proposées | appliqué, « Annuler » |
| Assisté | L7 inchangé (proposé, un tap) | proposé | proposé | proposé (« Appliquer » / « Garder le prévu ») |
| Expert | suggestion visible, sans bouton | proposé | proposé | information, « Appliquer quand même » |

Changement de mode à tout moment : Réglages → Adaptation au quotidien (ou profil).

## 8. Charge de séance simplifiée (KT-064)

Débutants et novices en Guidé ou Assisté : une question en fin de séance, difficulté globale 1-10 (Très facile … Maximal), « Passer » possible. Charge = difficulté × durée (minutes). Semaine civile > 1,5 × moyenne des 4 semaines précédentes (semaines sans séance notée = 0, au moins 2 semaines renseignées) → carte « Semaine chargée » (simple repère, pas une prédiction de blessure) et proposition d'alléger (§2 D-L11-13). Signaux combinés : la carte mentionne aussi un jour de fatigue relevé par Koach dans la semaine ; les deux signaux alimentent le contrôle de fatigue du plateau.

## 9. Données et migration

Section optionnelle **`adapt`** de la sauvegarde (format 3 inchangé), écrite seulement si elle sert (export identique à 4.0.0 sinon), ignorée par les versions antérieures, remise à neuf par l'effacement L2b :

```json
"adapt": {
  "v": 1,
  "autonomy": "guided|assisted|expert",            // sans profil seulement
  "sessions": {"S3-J1": {"minutes": 30, "at": "…", "sets": {"P0-85": 3},
      "removed": ["P0-90"], "pairs": [["P0-86", "P0-88"]], "warmup": true,
      "swaps": {"P0-87": {"to": "id-pack", "name": "…", "motive": "busy|pain|wish|place", "kg": 20}},
      "place": "park", "resume": "applied|refused"}},
  "pause": {"kind": "vacation|illness", "from": "AAAA-MM-JJ"},
  "pauses": [{"kind": "illness", "from": "…", "to": "…"}],
  "shorter": "horodatage", "lighten": {"from": "…", "to": "…"},
  "difficulty": {"S3-J1": {"rpe": 6, "minutes": 55}},
  "events": [{"at": "…", "kind": "slide", "status": "applied|undone", "detail": {…}}],
  "dismissed": {"slide|S3-J2": "horodatage"}
}
```

Bornes : 400 séances, 2 000 difficultés, 500 événements et pauses, 500 propositions écartées ; minutes 5-600, difficulté 0-10, séries 1-100. Import d'un fichier : toute valeur hors contrat refuse l'import (règle L2) ; démarrage : entrée illisible ignorée et comptée. **Aucune migration** : rien n'est réécrit dans le journal, les références ou le programme ; les adaptations sont une couche lue à l'affichage, le journal garde ce qui a été fait.

## 10. Registre de validation (à relire par un professionnel diplômé)

| Élément | Qui |
| --- | --- |
| Compression : échauffement 3 min, principaux ≥ 2/3, prévention 1 série, ordre de retrait, transitions 45 s | Préparateur physique |
| Critères d'équivalence d'un substitut (type, difficulté ±1, groupes), charge initiale 80 % | Préparateur physique |
| Contrainte articulaire ≤ l'original en cas de douleur | Kinésithérapeute / médecin du sport |
| Reprise : seuils 7/14/28 jours, −10/−20/−30 %, −1 série, calibrage, horizon 42 jours | Préparateur physique |
| Retour de maladie : volume −30 %, RIR +1 pendant 7 jours ; message de consultation | Médecin |
| Séance d'entretien (5 exercices, 3 séries, 45 s) | Préparateur physique |
| Seuils d'assiduité 60 / 90 %, fenêtres de 4 semaines, séances 20 % plus courtes | Préparateur physique |
| Plateau : pente < 0,5 %/semaine sur 3 semaines, assiduité ≥ 80 %, interventions par niveau, décharge × 0,6 / −10 % | Préparateur physique |
| Échelle de difficulté 0-10 et libellés, seuil 1,5 × moyenne 4 semaines, allègement × 0,8 | Préparateur physique |
| Mode Guidé : baisses appliquées d'office | Propriétaire |

## 11. Limites

- Aucun essai sur téléphone ; durées estimées, pas chronométrées.
- Un exercice échangé n'alimente pas l'estimation Koach du mouvement (il reste au journal, aux records et aux statistiques).
- Le plateau utilise une estimation propre (meilleure série de la semaine), distincte du filtre Koach ; il ne détecte que les exercices principaux du programme.
- « Nouveau bloc orienté sur le point faible » : non généré automatiquement (programme de 40 semaines fixe ; programme généré : régénération manuelle).
- Les séries de WOD ne comptent pas comme jours d'entraînement pour la reprise.
- Contenu sportif non relu par un professionnel diplômé : repères d'entraînement, aucune promesse de résultat ni bénéfice de santé.
