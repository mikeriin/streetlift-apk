# Livraison L9R — pack de contenu Kalis Track v2 (candidat)

Date : 27/09/2026 · Statut : **pack v2 prêt, relecture du propriétaire requise** · Application : inchangée (aucun build) · L9b : **non lancé** (volontairement).

## Livrables
- Branche `content-pack` (commit 3307b70) : dossier `kalis_content_pack_v2/` et archive `kalis_content_pack_v2_candidat.zip` (4,4 Mo, 58 fichiers, version interne 2.0.0). `kalis_content_pack_v1_final.zip` n'est **pas** écrit (sa présence déclencherait L9b).
- Outil de relecture v2 publié **au même lien** : https://claude.ai/artifact/MfMKxQMztc1rd85LLhUn6S (version 2 de l'artefact ; relectures dans la base partagée, nouvelle collection `relectures_v2`, l'ancienne `relectures` conservée). Version autonome : `review_tool.html` dans le pack.
- Documents : `CONTRAT_L9.md` révisé, `relectures_traitees.md`, `validation_register.md`, `licences.md`, `coverage_report.md`, `README.md`, planches PNG de contrôle (`planches/`).

## Étapes du prompt L9R
1. **Relectures** : la collection `relectures` était vide au lancement (revérifié en fin de lot) ; aucune remarque par exercice. Le constat général du propriétaire a été traité comme trois défauts systémiques et vérifié exercice par exercice : 156 archétypes sur 237 portaient au moins une attribution musculaire non confirmée par les sources ; gabarits d'animation réutilisés à tort, charges fausses, murs du mauvais côté, poses placées à l'œil — tout est listé dans `relectures_traitees.md`.
2. **Données sourcées** : 974 URL consultées (free-exercise-db, wger via fixtures GitHub, Wikipédia, ACE, StrengthLevel, Calixpert, StrengthLog…), ≥ 2 sources concordantes pour les 237 archétypes, champ `sources` par exercice, aucun texte repris. 625 exercices (505 v1 + 50 L9 + 70 ajouts L9R de couverture : 79 → 22 cases sous le seuil, les 22 restantes justifiées). D-L9-01, D-L9-02, D-L9-06 tranchées.
3. **Taxonomie et atlas** : 81 muscles/chefs (51 superficiels dessinés, 30 profonds en texte), groupe de compatibilité avec la carte actuelle à 11 groupes ; `atlas.svg` original (face et dos, une région fermée par muscle superficiel, sans chevauchement par construction), rendu et vérifié : `planches/atlas_planche.png`.
4. **Démonstrations exactes** : modèle corporel (Drillis & Contini, Winter), 260 fiches biomécaniques (phases, angles début/fin, prise, contacts, trajectoire, tempo), images clés **calculées** par cinématique directe + contraintes, 8 contrôles automatiques (0 défaut), silhouette volumétrique avec muscles primaires/secondaires surlignés, 6 palettes × 2 modes, version statique. Contrôle visuel des 150 exercices prioritaires et des 70 ajouts (planches PNG regardées) ; statuts : 572 disponibles, 35 statiques, 18 indisponibles (jamais d'animation fausse).
5. **Outil de relecture v2** : fiche complète, atlas de l'exercice, animation + images clés, fiche biomécanique, sources, arbres, relecture (valider / à corriger + catégorie + commentaire) dans `relectures_v2`, filtres « non relus » et « démonstration indisponible », utilisable à 320 px. Base partagée testée (écriture puis suppression d'un document de contrôle).
6. **Validation** : `validate.py` (schéma, taxonomie, atlas, sources, graphe, poses, statuts, correspondance 505 + programme, prérequis, substitutions) : **tous OK** ; `unittest` : **36 tests, 36 OK** ; `pose_checks.py` : 260 gabarits, 0 défaut.

## Décisions prises par défaut
D-L9R-01 à D-L9R-11 (`CONTRAT_L9.md` §6) ; à confirmer : concordance par variante proche pour six archétypes (D-L9R-04) et exposition CC-BY-SA de wger (D-L9R-06, option A appliquée). Détail dans `pipeline/DECISIONS_EN_ATTENTE.md`.

## Suite
Aucun lot lancé. Le propriétaire relit la v2 dans l'outil. Ensuite (dans cette session ou par un nouveau lancement avec ses corrections) : appliquer les corrections, copier l'archive validée sous `kalis_content_pack_v1_final.zip` sur `content-pack`, puis lancer L9b (`fire_trigger trig_01XUb6PZBCvYvNbBvpQokiun`) — `main` est en 3.1.0 (620752e), condition remplie.
