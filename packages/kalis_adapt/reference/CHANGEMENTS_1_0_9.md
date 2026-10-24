# Lot KM7 — liste exacte des changements de la référence (1.0.8 → 1.0.9)

Base : `moteurs` 25d5bfe6 (référence 1.0.8, `kalis_adapt` 1.0.7, `kalis_plan` 0.4.3, `kalis_bench` 0.5.9). Décision : DECISIONS_CP.md **C17.54** (lot express : les deux limites de RV4, C17.53.3). Portage Dart dans le même lot (`kalis_adapt` 1.0.8). Aucune clé ni valeur de paramètre changée (`1.0.9-ref.1`, 344 clés) ; aucun journal existant réinterprété ; sans les nouveaux champs, le moteur sert et apprend exactement comme 1.0.8 (fixtures `moteur_*`, `numerique`, `planification_*` : seuls la version, la date, la note et les SHA-256 des paramètres changent, vérifié champ par champ).

## A. Forme du jour versée sans être appliquée (RV4 § 5, limite)

1. **Drapeau** `seance_debut.bilan.applique` (booléen, absent = vrai) — `koach/moteur.py` `bilan_applique`, `faits_du_bilan`, `CLES_FORME` ; Dart `koachBilanApplique`, `koachFaitsDuBilan`, `koachClesForme`. Le drapeau est dans le bilan de `seance_debut` (c'est là que Koach reçoit le bilan ; `plan` ne le lit pas).
2. **Plan servi** : `applique` faux → `seances.ouvrir` reçoit les **seuls faits** du bilan (tout sauf `overall`, `sleepHours`, `sleepQuality`, `energy`, `mood`, `soreness`, `stress`, `motivation`, `nutrition`, `hydration`) : palier 0, ni réserve ajoutée, ni test reporté, ni séries ôtées par le bilan ; la séance servie est, item par item, celle d'un bilan de faits (douleurs, temps disponible).
3. **Douleur** : `bilan.pains` passe à la garde avant tout, drapeau ou non (sécurité ; inchangé).
4. **Apprentissage** (`koach/modele.py` `debut_seance(…, differe)`, `_poser_jour`, `_verser_bilan`) : l'a priori de l'effet du jour reste celui d'une séance sans forme jusqu'à la première série ; à la première série (ou à la fin d'une séance close sans série), l'a priori du bilan est posé sur les deux branches. Avant la première série, les deux branches ne diffèrent que par l'effet du jour (une piste créée, une observation hors série agissent de même) : l'état obtenu est **exactement** celui d'un bilan appliqué (testé : vecteur, covariance, poids des branches, posterior). Les séries de la séance sont donc interprétées avec la forme du jour versée (une baisse un jour de bilan bas est attribuée au jour, pas à la capacité).
5. **Après la première série** : les cibles des séries suivantes (`plan('serie')`) lisent l'état appris, forme comprise (aucune règle du bilan : palier 0). La forme pèse donc sur ces cibles, beaucoup moins que le bilan appliqué (relecture : dip lesté série 2 : 18,75 kg faits seuls, 17,5 kg gardé à l'écrit, 10 kg appliqué). C'est le sens de « versée » : l'interprétation des séries suit la forme ; la règle (réserve, séries, report) ne s'applique pas.
6. **Choix après le début** : pas d'événement nouveau. Avant la première série, la méthode de l'application (journal ramené au `seance_debut`, nouveau début avec l'autre drapeau) reste exacte ; après, la forme est déjà versée dans les deux lectures : rien à rejouer, seul le service diffère (figé).

## B. Remplaçants en séance (RV4 § 7.3)

7. **`koach/remplacants.py`** (Dart `lib/src/koach/remplacants.dart`, `koachRemplacants`, `Koach.remplacants`) : règles du contrat § 3.8 (étiquettes, filtres, ordre, cible de départ). Lecture seule : `Modele.instantane` / `restaurer` referment les pistes ouvertes pour les cibles de départ (testé : état complet et posterior inchangés).
8. **Fiches** : format de `donnees/catalogue_infos.json.gz` ; Dart `koachInfosRemplacement(catalog, [profile])` (`lib/src/remplacement_infos.dart`, exporté par `kalis_adapt.dart`), testé identique au fichier, exercice par exercice.
9. **Item remplacé** dans `plan('seance')` (`item_remplace`, Dart `koachItemRemplace`) : `remplace: {exerciseId, raison}`, `exerciseId` = remplaçant ; emplacement gardé ; charge écrite retirée ; autre unité : plage de départ ; transfert : `koachDepartKg`, servi par `_cible_charge` à un remplaçant jamais mesuré **seulement** un jour sans prudence (ni conduite sous douleur, ni reprise, ni part maximale, ni réserve ajoutée, ni semaine verrouillée, ni test, ni simple, ni échec : relecture M2) ; raison `koach.remplacement` (texte : « Aujourd’hui, « … » remplace « … » (matériel absent) : même place dans ta séance, avec ses propres cibles. »).
10. **Table de transfert** : `coachLoadReferences` de kalis_plan 0.4.3 recopiée (`TRANSFERTS`, Dart `koachTransferts`), comparée au source de kalis_plan par un test.

## C. Banc (référence Python)

11. Variante de campagne `--bilan-garde verse|non_verse` (`banc/campagne.py`, `banc/politique_koach.py`) : l'athlète garde l'écrit une séance sur deux (pile ou face déterministe par graine et jour) ; `verse` : bilan `applique: false`, avec un témoin (copie du moteur, seuls les faits) qui compare les deux plans dans la même séance ; `non_verse` : seuls les faits. Mesure `banc/km7_garde.py`. Clé `garde` des saisons seulement dans la variante (la campagne ordinaire est inchangée, comparée une à une au Dart).

## D. Tests

12. `tests/test_km7.py` (18 tests), `test/koach_km7_test.dart` (parité une à une avec `test/fixtures/km7/km7.json`, produite par `fixtures/generer_km7.py` : 7 scénarios, 300 pas ; rejeu du journal ; fiches ; transferts ; textes).
