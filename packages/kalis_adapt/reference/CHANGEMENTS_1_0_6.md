# Lot KM4 — liste exacte des changements de la référence (1.0.5 → 1.0.6)

Base : `moteurs` 9c81a201 (référence 1.0.5, `kalis_adapt` 1.0.4, `kalis_plan` 0.4.2, `kalis_bench` 0.5.6). Décision : DECISIONS_CP.md C17.37 (retour gradué : garde dans l'application puis révision du moteur). Portage Dart dans le même lot (`kalis_adapt` 1.0.5).

## Constat (C17.37.1)

Séance réelle du 19/10/2026 (programme importé de six séances par semaine en PPL, plus de volume « chest » que les trois semaines d'avant) : à la séance de tirage du lundi, `koach.retour_gradue` (groupe « chest ») ramenait le muscle-up lesté et la traction lestée à 0 série, et les pompes à RIR 5 (aucune série dure) passaient en tête. Mécanisme de 1.0.5 (`_budgets_retour`, `_retour_gradue`) : budget du jour = limite de la rampe − fait − **tout l'écrit des séances restantes de la semaine** ; coupe **dans l'ordre de la séance**, sans priorité de rôle, jusqu'à **0 série = item retiré**. La première séance de la semaine payait tout, et les principaux, en tête de séance, avant les accessoires.

Sur le banc (échantillon : 34 profils × 9 scénarios × vérité b × graine 0, 302 saisons, `--rapide`), 1.0.5 retirait **792 principaux** par la rampe sans aucune douleur (657 séances) ; 5,3 % des séances avec un principal avaient un principal réduit, et un principal réduit gardait en moyenne **6,5 %** de ses séries écrites (presque toujours retiré).

## A. Plan du retour gradué de la semaine (koach/seance.py)

`prescrire` sert la séance en **deux passes** : `_item` sur toutes les lignes (douleur, bilan, coupure, surmenage, rampe du réalisé par zone), puis `_plan_retour` (nouveau), puis, ligne par ligne, `_retour_gradue` et le vrai test (ordre des raisons changé : celles de `_item` d'abord).

`_budgets_retour` ne réserve plus l'écrit restant pour les groupes et l'allègement : il rend les limites et le réalisé de la semaine (séances fermées, séances manquées à leur écrit), la limite et le réalisé des séries dures d'une semaine d'allègement, et les séances restantes (`contexte['reste_semaine']`). Les tenues bras tendus gardent la règle de 1.0.5 (écrit restant réservé, tenues raccourcies puis séries en moins).

`_plan_retour` :

1. **Lignes** : chaque groupe majeur (`volume_groupes_majeurs`), et le total des séries dures une semaine d'allègement. Excès = réalisé + séries créditées des unités − limite.
2. **Unités** : lignes dures (`_series_dures` > 0) de la séance du jour, à leurs séries après `_item`, et des séances restantes de la semaine, à leur écrit ; poids = crédits de la fiche (et 1 sur le total d'allègement).
3. **Rang** (rôle de l'emplacement) : 2 = `main` ; 1 = `secondary`, `skill`, et un principal tenu par la conduite sous douleur (raison de douleur notée par `conduite`, ou zone sensible sous la rampe du réalisé qu'il provoque ; la rampe de retour après une coupure, sans douleur connue, n'en est pas une) ; 0 = tout autre rôle (`accessory`, `core`, `conditioning`, `mobility`, `cooldown`). **Sans rôle**, la première ligne dure créditée de la séance du jour est le principal, les autres sont de rang 0 (choix raisonné : l'exercice prioritaire ouvre la séance, ACSM 2009 ; Simão et al. 2012) ; une ligne d'une séance restante sans rôle n'est **pas coupée d'avance** (rang 3 : son écrit est réservé comme en 1.0.5, son rôle réel, inconnu, pourrait la protéger le jour venu ; relecture indépendante, M2).
4. **Plancher d'un principal** : `max(1, ⌈écrit × retour_plancher_principal⌉)` (0,5), jamais au-dessus de ses séries du jour.
5. **Coupes**, une série à la fois, par étapes : (1) rang 0 jusqu'à 0 ; (2) rang 1 jusqu'à 1 ; (3) principaux jusqu'au plancher ; (4) rang 1 jusqu'à 0 ; (5) principaux jusqu'à 1. Dans une étape, la série coupée est celle de l'unité qui garde la plus grande part de son écrit (`m / n` : répartition au prorata), à égalité la séance la plus tardive, puis la ligne la plus tardive ; seules les unités qui créditent une ligne encore en excès sont coupées. Un principal n'est **jamais** ramené à 0 par la rampe sans douleur ; s'il reste un excès après (5), il est noté (`depasse`) et les planchers sont gardés.
6. **Répartition sous condition d'assiduité** (`retour_repartition_semaines` ; **désactivée dans les valeurs livrées**, 0, § E) : avec N > 0, sans séance manquée dans les quatre dernières semaines (semaine en cours comprise ; état `semaines_manquees`, tenu par `contexte['manquees']`), les étapes portent sur toutes les séances de la semaine ; sinon (prudent, et toujours avec les valeurs livrées) : avec `retour_emprunt_plancher` = 1, (1)-(3) sur la séance du jour, (1)-(3) sur les séances restantes, puis (4) et (5), jour puis reste ; avec 0, (1)-(5) sur le jour puis (1)-(5) sur le reste. Raison : le validateur du banc (vue « servi, tests faits », critère 7) compte une séance manquée à son volume écrit, comme Koach ; une coupe promise à une séance restante ne tient que si elle est faite.

`_retour_gradue` applique le plan (séries permises par slot ; les `slotId` d'une séance sont supposés uniques, échauffements compris), puis la règle des tenues bras tendus ; raison `koach.retour_gradue` avec deux paramètres additifs : `ecrites` (séries écrites de la ligne) et `douleur` (vrai si la conduite sous douleur tient l'exercice).

**Changement de programme** (point 4 du prompt) : la rampe reste mesurée sur le réalisé des semaines précédentes (aucune règle de transition ajoutée) ; la répartition, la priorité de rôle et les planchers suffisent à ne plus vider les premières séances (scénario dédié, § D).

## B. Paramètres (params/koach_params_v1.json, `1.0.6-ref.1`)

- `securite.retour_plancher_principal` = 0,5 (choix raisonné, `SOURCES.md`) ;
- `securite.retour_repartition_semaines` = 0 (répartition désactivée, mesure sur le banc, `SOURCES.md` et § E) ;
- `securite.retour_emprunt_plancher` = 1 (mesure sur le banc, § E) ;
- `rupture.elargissement_rien_de_special` retirée (non lue depuis 1.0.5 ; DECISIONS_CP.md C17.29.2) ; défauts et bornes de `rupture.py` mis à jour.

347 clés (6 à la racine, 341 dans les sections). `koach.VERSION` = `1.0.6-ref.1`.

## C. Contrat et banc

- `contexte['reste_semaine']` : champ additif `role` par item (rôle de l'emplacement) ; absent, la règle « sans rôle » s'applique.
- Banc Python (`banc/politique_koach.py`) : `items_volume(items, roles)` ajoute le rôle aux séances manquées et restantes ; `mesure_rampe` compte, par séance, les principaux écrits (`role` = `main`, hors échauffement) réduits par `koach.retour_gradue`, la part servie, et les principaux **retirés par la rampe sans douleur** ; `banc/campagne.py` écrit `rampe` par saison ; `banc/securite_campagne.py` agrège `rampe_principaux` (critère KM4 et indicateurs). Mêmes mesures dans `kalis_bench` (Dart, `kmMesureRampe`, `tool/kr1_securite.py`).
- Crédits de groupes (`qualites/vecteurs_qualites_v1.json`) : **inchangés** dans ce lot (revue sur sources dans `LIVRAISON_KM4.md` : la table est partagée avec `kalis_plan` et le validateur du banc ; un crédit plus bas dans Koach seul ferait compter à Koach moins de séries que le validateur).

## D. Tests

- `tests/test_km4_retour.py` (11 tests) : scénario C17.37 (trois semaines d'un programme A, puis programme B de six séances par semaine en PPL, +40 % « chest », séance de tirage en premier : muscle-up lesté et traction lestée servis à leur écrit, pull-over (accessoire) réduit, limite de la semaine tenue sur tous les groupes) ; même lundi en mode prudent (accessoire à 0, principaux à leur plancher 3 et 2) ; jamais 0 pour un principal ; priorité de rôle ; sans rôle ; douleur ; prorata entre séances ; mode prudent ; fenêtre d'assiduité ; paramètres.
- `tests/test_securite_regles.py` : `test_retour_gradue_reserve_les_seances_restantes_et_compte_les_manquees` réécrit (1.0.6 : répartition, principal jamais retiré, accessoire retiré).
- Fixtures régénérées (`fixtures/`, `test/fixtures/km2c2/`, `kalis_bench/test/fixtures/km2/`).
