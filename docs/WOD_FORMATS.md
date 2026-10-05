# Kalis Track — Contrats des formats WOD (L3b, KT-008)

**Version 2.5.6+57 — 26 septembre 2026.** Source unique dans le code : `lib/wod_formats.dart` (règles, phases, libellés, records), utilisée par la fiche, le chronomètre, la saisie, l'historique, les records et l'XP de record.

Nature des preuves : **déclaration du propriétaire** (réponse écrite), **consigne du catalogue** (texte des WODs embarqués), **code** (comportement implémenté), **test automatique** (CI). Aucun essai sur téléphone à ce jour.

## 1. Décisions

| Sujet | Décision | Source |
| --- | --- | --- |
| Tabata : repos après le 8e effort | Le repos entre mouvements (60 s) **remplace** le repos de 10 s ; **fin au dernier effort** du dernier mouvement (pas de dernier repos). Bloc = 3 min 50 s | Propriétaire, 25/09/2026 |
| Tabata : score à plusieurs mouvements | Saisie **par intervalle** ; minimum de chaque mouvement ; score = **total des minimums** (plus haut = mieux), détail par mouvement affiché | Propriétaire, 25/09/2026 (et consigne « reps du plus faible intervalle, par mouvement ») |
| Routine sans règle de score écrite | **Temps noté, sans record** | Propriétaire, 25/09/2026 |
| EMOM sans règle de score écrite | **Minutes tenues sur N**, plus haut = mieux | Propriétaire, 25/09/2026 |
| For Time, rounds, AMRAP, AMRAP en blocs, Death by, E5MOM | Règle **écrite dans la consigne** ou déjà appliquée par l'application ; reprise telle quelle | Consigne / code existant |
| Égalité | Aucun départage : un score égal n'est pas un nouveau record ; le premier résultat reste affiché comme record | Code (inchangé) |

**Précision d'implémentation de la décision EMOM** (à confirmer si besoin) : « terminé » signifie que l'EMOM a été mené à son terme (chrono arrivé au bout, ou choix explicite), pas que toutes les minutes ont été tenues ; le score dit combien l'ont été (« 13/15 minutes tenues »). Un EMOM arrêté en route est « incomplet » et ne compte pas comme record. Raison : sinon aucun EMOM à une minute manquée ne serait comparable, et le compteur « WOD terminés » (badges, semaines complètes, crédits) baisserait pour ce seul format.

## 2. Inventaire du catalogue (1 000 WODs, ids inchangés)

Relevé par `tools/wod_catalog_snapshot.dart` (sortie JSON Lines, une ligne par WOD).

| Type | Nombre | Origine | Format structuré ajouté (L3b) |
| --- | --- | --- | --- |
| `fortime` | 313 | 16 préchargés, 153 `gen`, 144 `genx` (chippers, échelles) | — |
| `rounds` | 194 | 17 préchargés, 79 `gen`, 98 `genx` | — |
| `amrap` | 118 | 5 préchargés, 74 `gen`, 39 `genx` | — |
| `emom` | 170 | 4 préchargés, 67 `gen`, 99 `genx` | **21 Death by** (`death-by`), **seed29** (`emom-reps`, tractions) |
| `routine` | 205 | 8 préchargés, 77 `gen`, 120 `genx` | **40 Tabata** (`tabata`), **40 AMRAP en blocs** (`amrap-blocks`) |

Identifiants :
- **Tabata (40)** : `genx100`–`genx109`, `genx220`–`genx229`, `genx340`–`genx349`, `genx460`–`genx469`. 3 mouvements (palier 1-4) ou 4 (palier 5-10), 8 × 20 s / 10 s, 60 s entre deux.
- **AMRAP en blocs (40)** : `genx60`–`genx69`, `genx180`–`genx189`, `genx300`–`genx309`, `genx420`–`genx429`. Trois blocs de *b*, *b*+1, *b*+2 minutes (*b* = 3 ou 4), 2 min de repos.
- **Death by (21)** : `genx110`–`genx119`, `genx231`, `genx235`–`genx237`, `genx351`, `genx352`, `genx355`, `genx357`, `genx470`, `genx475`, `genx479`.
- **E5MOM compté en reps (1)** : `seed29` « E5MOM 25 min — max tractions (IPC) ».

**Identification** : champ explicite `format` posé par le générateur (familles 6, 10, 11 de `generateWodV2`) et par la définition de `seed29`, jamais déduit du titre ni d'une phrase. Les lignes des Tabata sont désormais écrites à partir de ce champ (même texte qu'avant). Le format n'entre pas dans la « définition » modifiable : un WOD du catalogue modifié par l'utilisateur perd son format et suit la règle de son type.

**Comparaison avant/après** : les 1 000 définitions (hors `format`, résultats et niveau) sont identiques octet pour octet à celles de 2.5.5 (385 382 octets, empreinte FNV-1a `0x755f39d8`, vérifiée par test). Seule différence : la clé `format` sur les 102 WODs listés. Aucun id renuméroté, aucun WOD régénéré ; la déduplication du générateur, les niveaux (déciles) et donc l'essai du jour et la vitrine L3 sont inchangés.

## 3. Contrats par format

| Format | Exemple | Prescription affichée | Déroulement / chrono | Limite de temps | Score (champs, unité, sens) | Complet / partiel / abandonné | Comparable si |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **For Time** (`time/1`) | `seed4` IPC 100-80-60-40-20 ; `seed39` (cap 12 min) | Lignes, schéma, cap | Chrono montant ; « Valider round » facultatif ; alarme au cap | `minutes` > 0 = time cap | `seconds` (entier, s) ; plus court gagne | **Choix explicite** « Terminé en entier » / « Incomplet » (jamais supposé ; cap atteint → incomplet présélectionné) ; terminé au-delà du cap refusé | Complet, temps > 0, même règle |
| **Rounds for time** (`time/1`) | `seed1` 5 rounds bodyweight | Rounds, repos | Chrono montant ; « Valider round » ; repos entre rounds ; fin auto au dernier round | cap éventuel (HYROX `seed25/59/60/63` : 60 min) | `seconds` ; plus court gagne | Tous les rounds validés → terminé présélectionné ; sinon choix explicite | Idem For Time |
| **AMRAP** (`amrap/1`) | `seed24` Cindy 20 min | Durée | Compte à rebours | Durée = fin | `rounds` + `reps` du round en cours ; rounds puis reps, plus haut gagne | Terminé présélectionné si le compte à rebours est allé au bout ; arrêt anticipé → incomplet (pas de record) | Complet, rounds ≥ 0 |
| **EMOM générique** (`emom-minutes/1`) | `seed37` EMOM 15 ; `seed58` E2MOM 12 | N × intervalle | Minutes/intervalles, bip à chaque intervalle | N × intervalle | `rounds` = minutes tenues (0 à N), **jamais pré-rempli** ; plus haut gagne | Terminé si le chrono est allé au bout (ou choix) | Complet, même règle |
| **E5MOM tractions** (`emom-reps/1`) | `seed29` | 5 × 5 min | Idem EMOM | 25 min | `reps` = total de tractions ; plus haut gagne | Idem EMOM | Idem |
| **Death by** (`death-by/1`) | `genx110` Death by · air squats (15 min) | N × 60 s | Idem EMOM ; le chrono s'arrête à N | N minutes | `rounds` = dernière minute réussie (0 à N) ; plus haut gagne | Terminé présélectionné (l'échec est la fin normale) | Idem |
| **Tabata** (`tabata/1`) | `genx100` (3 mvts, 13 min 30 s), `genx105` (4 mvts, 18 min 20 s) | Mouvements, 8 × 20 s / 10 s, 1 min entre deux, durée | **Phases** : [préparation (réglage)] → effort 20 s / repos 10 s × 8 → repos 60 s → … → fin au dernier effort | Durée fixe | `intervals` (reps par intervalle, par mouvement ; vide ≠ 0) ; score = Σ minimums, stocké dans `reps` si complet ; plus haut gagne | Complet seulement si **tous** les intervalles sont saisis (sinon refusé) ; « Incomplet » garde la saisie partielle, minimums « — » | Complet, même format |
| **AMRAP en blocs** (`amrap-blocks/1`) | `genx60` 3 × AMRAP 4-5-6 | Blocs, repos | **Phases** : AMRAP 1/3 → repos → AMRAP 2/3 → repos → AMRAP 3/3 | Durée fixe | `rounds` = total des rounds (consigne : « score = total des rounds ») ; plus haut gagne | Terminé présélectionné si le chrono est allé au bout | Complet |
| **Routine sans règle** (`none/1`) | `seed2`, `seed12` AMRAP 3-4-5, `seed36`, routines `gen`, « Force + metcon » `genx` | Lignes | Chrono montant | cap éventuel | `seconds` facultatif (noté, jamais comparé) | Choix, terminé présélectionné (hors cap) | **Jamais** : aucun record |

Arrondis : le chrono stocke des **secondes entières** (troncature du temps actif, les fractions sont gardées entre les pauses) ; l'affichage `m:ss` ne modifie ni la valeur stockée ni le classement.

Saisie des nombres : chiffres uniquement (espaces autour tolérés), zéro accepté, pas de signe, de décimale, d'exposant, de texte ; bornes : 0-999 par intervalle Tabata, 0-N minutes pour un EMOM/Death by, 0-1 000 000 ailleurs. Un champ vide n'est jamais lu comme zéro.

## 4. Tabata en détail

- **Chronologie** (`phasesOf`) : pour chaque mouvement *m* : 8 efforts de 20 s séparés par 7 repos de 10 s ; puis 60 s de repos si un mouvement suit ; fin au 8e effort du dernier mouvement. 3 mouvements = 47 phases, 810 s ; 4 mouvements = 63 phases, 1 100 s. La préparation (réglage « Préparation », 0-60 s) précède et n'entre ni dans la durée ni dans le temps enregistré.
- **Chrono** (`WodClock.startPhases`) : la phase se déduit du temps actif cumulé (ms) ; un rafraîchissement tardif ne prolonge aucune phase et ne rejoue aucune transition ; pause et reprise figent la phase. Une alerte n'est jouée que si sa transition date de moins de 1,5 s : pas de rafale au retour dans l'application ; alarme de fin unique (supprimée si la fin est découverte tard). Son et vibration suivent les réglages.
- **Affichage** : nom de la phase en toutes lettres (« EFFORT », « REPOS », « REPOS ENTRE MOUVEMENTS », « PRÉPARATION »), annoncé comme région dynamique une fois par changement (les chiffres ne sont pas annoncés à chaque seconde) ; position « Mouvement 2/3 · push-ups · intervalle 5/8 » ; temps restant de la phase en grand, temps total restant dessous.
- **Fin** : la feuille de score s'ouvre, **vide** : un chrono terminé ne prouve aucune répétition.
- **Saisie** : 8 cases par mouvement, libellées pour les lecteurs d'écran (« push-ups, intervalle 3 sur 8 ») ; minimum recalculé en direct ; correction possible avant « Enregistrer ».
- **Score** : `Total 26 reps · minimums 10 · 6 · 10` ; partiel : `Partiel · minimums 4 · — · — · —`.
- **Contradictions de texte laissées telles quelles** (consigne non réécrite) : certaines notes de Tabata contiennent un conseil générique du générateur (« note ton temps par round », « +1 round ») sans rapport avec le Tabata ; la règle explicite « Score = reps du plus faible intervalle » prime.

## 5. Anciens résultats (avant 2.5.6)

Aucun ancien résultat n'est supprimé, converti ni réécrit ; date, valeurs brutes, notes, prescription, tentative restent intactes.

| Résultat ancien (sans `scoring`) | Lecture | Record |
| --- | --- | --- |
| For Time, rounds | Même règle (temps, complet) : **comparable** aux nouveaux, sans conversion | Oui |
| AMRAP | Même règle (rounds + reps) : **comparable** | Oui |
| Tabata (temps) | Historique : « Ancien score au temps : conservé, sans répétitions, non comparé » ; aucune répétition reconstituée, aucun zéro attribué | Non |
| AMRAP en blocs (temps) | Historique, non comparé au total des rounds | Non |
| Routine (temps) | Historique, sans record | Non |
| EMOM, Death by, E5MOM (rounds + reps) | Historique : « Ancien score (rounds + reps) : conservé, non comparé » (les rounds étaient pré-remplis par le temps écoulé : conversion non déterministe) | Non |

**Mécanisme de version** : chaque nouveau résultat porte `scoring` (`tabata/1`, `time/1`…). Deux résultats ne se comparent que sous la même règle. L'absence de `scoring` identifie un résultat antérieur ; la règle de lecture est calculée à l'affichage, sans écriture : il n'y a donc **pas de migration de données**, répéter l'import ou la lecture ne change rien. Un identifiant inconnu (fichier d'une version future) fait refuser l'import.

**XP et économie** (contrat L3 préservé) :
- L'XP de record des anciens résultats est calculée **exactement comme avant** (ancienne règle pour les groupes « historiques ») : aucun gain ni perte à la mise à jour, à l'import ou à la consultation (test oracle).
- Nouveaux résultats : +80 XP par résultat (inchangé) ; +40 XP pour le premier résultat classé et pour chaque nouveau record **sous la nouvelle règle**. Conséquences de règle, à connaître : (1) un premier Tabata, EMOM, Death by ou AMRAP en blocs saisi sous la nouvelle règle donne une première référence (+40) même si d'anciens résultats existent ; (2) un nouveau résultat de **routine sans règle** ne donne plus de bonus de record (80 XP de tentative inchangés).
- Crédits : aucune règle modifiée ; registre L3 inchangé ; aucun crédit repris ni ajouté par la mise à jour ; droits, prix payés, favoris, essai et vitrine inchangés.

## 6. Données, sauvegarde, suppression

Nouveaux champs d'un résultat : `scoring` (texte), `intervals` (tableau de tableaux d'entiers 0-999 ou `null`, ≤ 20 mouvements × 50 intervalles). Ils passent par la file d'écritures L2, l'export/import (format 3), l'aperçu, les bornes d'import et la suppression locale L2b ; aucun stockage séparé. Import refusé si : règle inconnue, intervalle hors bornes ou non entier, `format` incohérent avec le type.

## 7. Ambiguïtés du catalogue (contenu conservé)

| WOD | Ambiguïté | Traitement |
| --- | --- | --- |
| Death by (21) | Lignes « min 1-5 : 3 air squats » (valeur médiane du bloc) alors que la note dit « +1 par minute » ; « jusqu'à ne plus tenir » mais le catalogue fixe N minutes | Score = dernière minute réussie, bornée à N par le chrono ; texte inchangé |
| `seed62` HYROX EMOM 30 | « Cash in / cash out : 1000 m row » hors du chrono EMOM | Chrono = 30 minutes ; score = minutes tenues ; cash in/out non chronométrés |
| `seed12`, `seed36`, « Force + metcon » (`genx`, famille 9) | Blocs d'AMRAP sans règle de score écrite | Routine sans record (décision) |
| Time caps HYROX « 55/60 min » | Deux caps selon le niveau | Cap enregistré : 60 min |
| For Time avec cap | Aucun score « reps au cap » écrit | Résultat au-delà du cap = incomplet, sans record |
| Notes génériques des Tabata | « note ton temps par round », « +1 round » | Texte conservé ; règle explicite appliquée |
