# Décisions en attente

## Refonte muscles et animations (4.3.1, fusionnée) — à relire (non bloquant)
- **D-MA-00 Fusion** : faite le 27/09/2026 en 4.3.1 (`7f07e2e`, build n°94), sur accord écrit, après L13.
- **D-MA-01 Vue de dos** : choisie quand les muscles principaux postérieurs sont plus nombreux que les antérieurs (latéraux non comptés). Résultat : 2 exercices (side bend, planche latérale avec abduction) ; drapeaux et planches latérales restent de face. Option : forcer le dos pour les drapeaux (dorsaux). Recommandation : garder.
- **D-MA-02 18 exercices revus** (animation fausse avec la cinématique du pack) : 11 développés en image fixe position haute, leg curl et leg extension en image fixe, 5 sans démonstration (presse à cuisses, sled push, rowing appui poitrine, transition de muscle-up pieds au sol, sauts en contrebas). Proposition pour une passe du pack : corriger la position basse des gabarits `banc.couche`, `banc.pause`, `banc.floor`, `banc.incline` (bras sous le niveau des épaules, avant-bras vertical), donner une vraie flexion à `assis.leg_curl` / `assis.leg_extension`, replacer plateau, traîneau et banc d'appui, ajouter sol et caisse ; les exercices reviendraient alors en animation.
- **D-MA-03 Générateur de programme** : il lit toujours le statut du pack, ces 18 exercices y comptent comme « animés » (références figées des tests L10). Option : lui faire lire le statut revu (programmes générés légèrement différents).
- **D-MA-04 Flanc sous le bras (profil)** : redessiné dans le style de ton illustration, visible seulement quand le bras bouge. Option : fournir une seconde image de profil bras levés.

## L13 (4.3.0) — à relire (non bloquant)
Détail : `docs/CONTRAT_L13.md` §2 (D-L13-01 à D-L13-10), `docs/GOOGLE_PLAY.md`, `docs/REGISTRE_VALIDATION.md`, `docs/TEST_FERME.md` dans le ZIP.
- **URL publique de la politique de confidentialité** : à fournir (héberger `assets/legal/confidentialite.md`) ; requise pour la fiche Google Play. Adresse de contact aussi.
- **D-L13-05 Réponses Koach par séance (sommeil, forme, douleur)** : restent hors du consentement L8 et ne sont pas effacées par « Retirer mon accord » (la douleur est une entrée de sécurité) ; effaçables à part. Option : les effacer au retrait de l'accord et ne plus demander sommeil/forme sans accord. Recommandation : garder, faire valider par un juriste.
- **D-L13-01 Avertissement** : carte sous « Commencer » au premier écran et dans « À propos », sans case à cocher. Option : carte unique sur l'accueil après la mise à jour pour les installations existantes.
- **D-L13-02 Renvoi vers un professionnel** à la 3ᵉ séance de suite avec douleur > 3/10 sur un mouvement.
- **D-L13-04 Profil importé de moins de 18 ans** : application bloquée jusqu'à correction ou suppression.
- **Sauvegarde Android** (KT-016 option A, inchangée) : les données de santé partent dans la sauvegarde Google si elle est activée. Option B : les en exclure.
- **Registre de validation** : 22 éléments, dont 11 en priorité P1 (questionnaire, mode prudent, douleur, signaux d'alerte, seuils de niveau, reprise, RGPD, finalité, réponses Google Play) ; aucune relecture professionnelle en V1 (ta décision), limite écrite.

## L12 (4.2.0) — à relire (non bloquant)
Détail : `docs/CONTRAT_L12.md` §2 (D-L12-01 à D-L12-12) et §5 (barème) dans le ZIP.
- **Barème des récompenses des étapes (proposition chiffrée, NON appliquée — invariant économie)** : record 0 crédit (déjà un bonus XP), étape de chaîne franchie 2, cycle terminé 3, régularité 4 / 8 / 12 / 26 / 52 semaines : 1 / 1 / 2 / 3 / 5 ; payé une fois au registre KT-005 (`milestone:<id>`), jamais repris. Estimation : ≈ 51 crédits sur 40 semaines pour un utilisateur régulier. Pour l'appliquer : réponds « barème L12 validé » (ou tes chiffres).
- **D-L12-08 Rappels jamais un jour de repos** : l'ancien réglage « Ignorer les jours de repos » est retiré ; 3 tests existants adaptés (280 → 240 rappels ; changement d'heure contrôlé au lundi 26/10). Recommandation : garder.
- **D-L12-07 Semaine régulière** = 3/4 des séances prévues ; jours de repos respectés comptés ; semaine sans séance prévue neutre.
- **D-L12-04 Célébration** seulement pour une étape de moins de 7 jours (pas de rafale pour l'historique).
- **D-L12-10 Parcours d'habitude** (débutant, novice) : séances compressées à 20 min les 28 premiers jours, 2 séances visées, désactivable ; pas de réécriture du générateur.

## L11 (4.1.0) — à relire (non bloquant)
Détail : `docs/CONTRAT_L11.md` §2 (D-L11-01 à D-L11-14) et §10 (registre) dans le ZIP.
- **D-L11-01 Le plan glisse sur proposition** (carte « Reprendre là où tu t'es arrêté », un tap, annulable) ; d'office seulement à la fin d'une pause vacances/maladie. Ta décision L4 (« pas de décalage automatique ») est ainsi respectée hors pause. Option : glissement automatique. Recommandation : garder.
- **D-L11-02 Ton installation reste en mode Assisté** (profil migré jamais choisi ou absent) : rien ne change sans tap. Le mode Guidé (baisses appliquées d'office, annulables) se choisit dans Réglages → Adaptation au quotidien.
- **D-L11-07 « Une séance de moins/de plus »** proposée seulement pour un programme généré ; pour le programme de 40 semaines, seule « séances 20 % plus courtes ».
- **D-L11-08 Plateau** : novice traité comme débutant ; « nouveau bloc sur le point faible » à régénérer à la main après la décharge programmée.
- **D-L11-12 Guidé au bilan** : baisses de valeur et allègement douleur acceptés d'office (annulables), hausses toujours proposées.

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
