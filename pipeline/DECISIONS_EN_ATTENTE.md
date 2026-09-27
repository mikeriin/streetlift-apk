# Décisions en attente

## L10 (4.0.0) — à relire (non bloquant)
Détail : `docs/CONTRAT_L10.md` §2 (D-L10-01 à D-L10-13) et §8 (registre) dans le ZIP ; 13 profils types : `docs/PROFILS_TYPES_L10.md`.
- **D-L10-04 Ton programme actuel** reste le modèle « Expert streetlifting » implicite, identique ; rien n'est réécrit. « Mon programme → Générer » le remplace à partir d'aujourd'hui (annulable 7 jours). Recommandation : garder.
- **D-L10-01 Seuils de niveau** du prompt appliqués (pompes 10/25/45/70, tractions 1/6/13/21, squat 0,75/1,25/1,6/2,0 ; lests 25/50 % et 40/75 %) ; les tranches du profil L8 deviennent des répétitions « estimées ». À valider.
- **D-L10-03 Séances plus courtes que le temps disponible** quand le plafond de volume (départ + 6 séries par groupe) est atteint, signalées dans la séance (fréquent au-delà de 90 min). Option : relever le plafond pour les longues séances.
- **D-L10-10 Matériel déduit des lieux** (parc → barre basse ; maison → serviette, bâton ; salle → serviette, barre basse avec rack). À confirmer.
- **D-L9b-09** (fiche depuis l'écran de séance) : toujours en attente — un bouton dans la feuille de consignes cassait un test d'écran existant ; à placer ailleurs si tu le veux.


## L9b (3.2.0) — à relire (non bloquant)
Détail : `docs/CONTRAT_L9b.md` §4 dans le ZIP (D-L9b-01 à D-L9b-09).
- **D-L9b-01 Aucune migration de données** : les noms enregistrés (séances, historique, records) restent les clés ; l'identifiant v2 est résolu à la lecture. Option : réécrire les données avec les identifiants v2 (migration de schéma). Recommandation : garder.
- **D-L9b-05 Doublons v1** (22) : masqués dans la bibliothèque, leur nom mène à l'exercice canonique ; toujours visibles dans le sélecteur de séance (comme avant). Option : les masquer aussi du sélecteur.
- **D-L9b-08 Tranches de difficulté** du filtre : 1-3 accessible, 4-6 intermédiaire, 7-10 avancé.
- **D-L9b-09 Fiche depuis l'écran de séance du programme** : pas encore de bouton (écran le plus dense). Options : (a) ajouter une icône ⓘ par exercice en L10 ; (b) laisser l'accès par Arsenal. Recommandation : a.

## Tranché le 27/09/2026 (le propriétaire a validé le pack v2 et délégué ces choix)
- L9R : D-L9R-04 (a) accepté ; D-L9R-06 (a) références wger gardées dans `sources` (faits vérifiés, rien reproduit, pas d'écran de mentions) ; D-L9R-02 81 entrées suffisent ; D-L9R-05 classements confirmés ; D-L9R-07 statique / indisponible plutôt qu'une animation approximative : confirmé ; D-L9R-09 ajouts acceptés, difficultés proposées conservées (restent au registre de validation).
- L8 : 1 garder ; 2 garder ; 3 (a) questions propres à Kalis Track, relecture par un médecin inscrite comme limite ; 4 garder ; 5 garder.

(Historique ci-dessous conservé.)

## L9R — à relire (non bloquant)
Le lot L9R a tranché les décisions L9 selon le prompt (D-L9-01 sources consultées, D-L9-02 types conservés, D-L9-04 sans objet, D-L9-06 confirmée, couverture 79 → 22 manques justifiés). Décisions réversibles prises par défaut en L9R ; détail dans `CONTRAT_L9.md` §6 sur `content-pack` (dossier `kalis_content_pack_v2/`).
- **D-L9R-04 Concordance par variante proche** : six archétypes (dips à la barre droite, isométrie de transition muscle-up, manna, sandbag carry, skin the cat, respiration) n'ont qu'une source directe ; la seconde décrit une variante très proche. Options : (a) accepter (appliqué) ; (b) marquer ces exercices « à confirmer » dans l'application.
- **D-L9R-06 wger (CC-BY-SA)** : 319 entrées consultées pour vérifier des faits, rien reproduit. Options : (a) garder les références dans `sources` (appliqué, aucun écran de mentions) ; (b) les retirer — 225 archétypes gardent ≥ 2 autres sources, 12 à compléter (liste dans `licences.md` §3).
- **D-L9R-02 Taxonomie à 81 entrées** au lieu d'« environ 90 » : tous les chefs demandés sont présents ; dire si des subdivisions supplémentaires sont voulues.
- **D-L9R-05 Classement** : curl nordique et curl ischio glissé en `isolation` (flexion de genou), dragon flag en `gainage_anti_extension`, sprints répétés et bounding en `locomotion`. Confirmer.
- **D-L9R-07 Démonstrations** : 35 exercices `statique` et 18 `indisponible` (liste `validation_register.md` §6) plutôt qu'une animation approximative. Confirmer ce choix.
- **D-L9R-09 Ajouts** : 70 exercices ajoutés pour la couverture (variantes d'archétypes sourcés), difficultés à confirmer (`validation_register.md` §3.1) ; roulades et roue non ajoutées faute de source musculaire.

## L8 (3.1.0) — non bloquant

1. **« Forme et santé » présélectionné pour tous** au démarrage (le prompt voulait le présélectionner selon le repère de niveau, mais l'ordre imposé des écrans place le repère après les objectifs). Option : déplacer le repère avant les objectifs. Recommandation : garder.
2. **Installation existante sans profil confirmé : mode prudent sans effet** (charges 3.0.3 inchangées) jusqu'à la confirmation. Option : l'appliquer dès la mise à jour. Recommandation : garder (aucune charge modifiée sans action de ta part).
3. **Questionnaire de santé rédigé pour Kalis Track, non repris du PAR-Q+** : les conditions du PAR-Q+ (eparmedx.com, consultées le 26/09/2026) interdisent modification et intégration sans accord écrit. Options : a) garder les 8 questions propres et les faire relire par un médecin ; b) demander une licence à la PAR-Q+ Collaboration. Recommandation : a.
4. **Migration du profil** : objectif principal « Préparer un test ou une compétition » (4 mouvements lestés, cibles et date de l'objectif final Koach, sinon étape à 12 mois), secondaire « Force » 70/30 ; lieux parc + salle. Tout est modifiable à l'écran de confirmation.
5. **Accord du médecin** caduc après une nouvelle réponse « oui » ou une nouvelle gêne > 3/10 ; ne lève ni le refus du consentement ni un questionnaire sans réponse.

Détail : `docs/CONTRAT_L8.md` §2 (D-L8-1 à D-L8-10).
