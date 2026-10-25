# Livraison KM7 — Koach 1.0.9 : forme du jour versée sans être appliquée, remplaçants en séance (`kalis_adapt` 1.0.8)

Lot express KM7 du pipeline CP (lot de méthode Koach ; décision C17.54 ; prompt `prompts/KM7.txt`), voie A, session Opus 5.5 effort maximal du 24/10/2026 15:02 UTC au 25/10/2026 ~06:15 UTC (la campagne a pris l'essentiel du temps, § 6). Aucune donnée réelle, aucun déchiffrement, aucune clé (C17.33.2). Pas de panel ni de relecture documentée (C13.3). Une relecture indépendante a été faite par un sous-agent Opus, voir § 5. L'outil `add_repo` est absent de la session : l'accès en écriture a été vérifié par les pushes. Dart 3.13.7 (conda-forge), cache pub de a74f7710.

**En une phrase** : en mode Libre « Garder l'écrit » ou en Assisté « Annuler », Koach reçoit désormais la forme du jour sans s'en servir pour la séance. Le plan servi est identique, item par item, au plan sans forme : 395 364 séances sur 395 364 dans la campagne. La douleur s'applique toujours, et la forme sert à interpréter les séries. Et pour « Remplacer pour aujourd'hui », Koach propose des remplaçants classés selon la raison et le matériel (« équivalent », « plus facile », « sans ce matériel », « autre »), avec une raison et une cible de départ. Il sert le remplaçant à l'emplacement, avec ses propres cibles. Sans ces nouveaux champs, le moteur est **identique** à 1.0.8 : mêmes critères, même sécurité, mêmes adversaires, au chiffre près, sur 90 600 saisons, en Dart et en Python.

## 1. Livré

| Paquet | Version | Étiquette | Contenu |
| --- | --- | --- | --- |
| `kalis_adapt` | **1.0.8** (Koach 1.0.9, `1.0.9-ref.1`) | `etiquettes/kalis_adapt-v1.0.8` | Référence Python : `koach/moteur.py`, `modele.py`, `seance.py`, `koach/remplacants.py` (nouveau), `banc/politique_koach.py`, `banc/campagne.py`, `banc/km7_garde.py`, `tests/test_km7.py` (18 tests), `fixtures/generer_km7.py`, `CHANGEMENTS_1_0_9.md`, note datée du 24/10 au contrat (§ 2.1, 3.3, 3.5, 3.8), `SOURCES.md`. Portage Dart : `moteur.dart`, `modele.dart`, `seance.dart`, `remplacants.dart` (nouveau), `lib/src/remplacement_infos.dart` (`koachInfosRemplacement`, exporté), `koach_textes.dart` (`koach.remplacement`), `test/koach_km7_test.dart`, fixture `test/fixtures/km7/km7.json`. Asset **`assets/koach/koach_params_1_0_9.json`** : 344 clés, aucune valeur changée, SHA-256 `1a59e6756923ce348378ff356a25b0af4adc8e8114ae9ac1ba53b85c46808dc5`. Fiches `vecteurs_qualites_v1.json` inchangées (`99b0cae2…96e0`). `docs/CRITERES_KM7.md`, `docs/data/km7/`, `docs/INTEGRATION_KM3.md` § 13 |

`kalis_plan` 0.4.3, `kalis_core`, `kalis_bench` 0.5.9 : inchangés. `moteurs` : **266f9626** (étiquette sur ce commit).

Contrôles :

- **Contrôle complet** : run 40130237074 **vert** sur `claude/ci-cp-b` a3468703, arbre c7008e9 (kalis_adapt, kalis_bench, kalis_plan, kalis_core, kalis_quest, outils Python). Les deux commits suivants ne changent que deux fichiers : le banc Python (`banc/politique_koach.py`, témoin de la variante) et la documentation. Tests en session sur l'arbre livré : pytest 359, kalis_adapt 422, kalis_bench 296, format et analyse, tous verts.
- **Campagne** : run 40107907131, publié sur `claude/ci-cp-a` 32f5de2. La variante a eu son propre run, 40161629201 (fe095f1).

## 2. Point 1 — forme du jour versée sans être appliquée

**API.** Le drapeau est dans le bilan de `seance_debut`, puisque c'est là que Koach reçoit le bilan (`plan` ne le lit pas) :

```
observe({'type': 'seance_debut', 'jour': 11,
         'bilan': {'overall': 1, 'sleepHours': 5, 'energy': 2, 'pains': [], 'applique': false}, 'contexte': {…}})
plan({'horizon': 'seance', 'items': […], …})
→ items identiques à ceux du bilan {'pains': []} : dip lesté 6 séries (appliqué : 5), squat 4 (appliqué : 3),
  aucune raison du bilan
```

- **Plan servi.** Il reçoit seulement les faits du bilan : douleurs et temps disponible. Les réponses de forme sont écartées (`koachClesForme` : `overall`, `sleepHours`, `sleepQuality`, `energy`, `mood`, `soreness`, `stress`, `motivation`, `nutrition`, `hydration`). La garde, la sécurité et la douleur s'appliquent toujours.
- **Ce que Koach apprend.** L'a priori de l'effet du jour reste celui d'une séance sans forme jusqu'à la première série. Il est alors posé d'après le bilan (`_verserBilan`), ou à la fin d'une séance close sans série. L'état appris est **exactement** celui d'un bilan appliqué : vecteur, covariance, poids des branches et posterior sont égaux (testé). Les séries sont donc interprétées avec la forme versée.
- **Journal rétrocompatible.** Sans drapeau, ou avec `applique: true`, la lecture est celle de 1.0.8. Aucun journal existant n'est réinterprété. Le rejeu d'un journal avec le drapeau redonne l'état exact.
- **Choix fait après le début.** Il n'y a pas d'événement nouveau, et c'est voulu. Avant la première série, la méthode de l'application (retour au `seance_debut`, puis nouveau début avec l'autre drapeau) reste exacte. Après la première série, la forme est déjà versée dans les deux lectures : il n'y a rien à rejouer, et le service est figé. Un événement de bascule ne serait ni plus simple ni plus sûr.
- **Limite dite.** Après la première série, les cibles des séries suivantes lisent l'état appris, forme comprise : la règle du bilan ne s'applique pas, mais l'interprétation, si. Exemple de la relecture, au dip lesté série 2 : 18,75 kg avec les seuls faits, 17,5 kg avec l'écrit gardé, 10 kg avec le bilan appliqué.

## 3. Point 2 — remplaçants en séance

**API** (lecture seule, rien n'est versé au journal) :

```
infos = koachInfosRemplacement(catalog, profil)            // une fois
k.remplacants(infos, {'exerciseId': 'sl-dips-leste', 'item': <ligne servie>, 'role': 'main',
                      'raison': {'code': 'pas_de_materiel', 'materiel': ['ceinture de lest']}, 'niveau': 2})
→ {'raison': 'pas_de_materiel', 'regles': {'autre_permis': false, 'zone': null}, 'remplacants': [
   {'exerciseId': 'cd-dips-russes', 'etiquette': 'sans_materiel', 'unite': 'reps', 'depart': {'source': 'a_priori', 'repsLow': 6, 'repsHigh': 8, …},
    'texte': 'Au poids du corps, sans ceinture de lest : tempo lent ou pause en bas pour garder l’effort.'},
   {'exerciseId': 'sw-dips-barres-paralleles', 'etiquette': 'sans_materiel', 'depart': {'source': 'a_priori', 'repsLow': 16, 'repsHigh': 20, …}, …},
   {'exerciseId': 'cd-dips-explosifs', 'etiquette': 'sans_materiel', 'texte': 'Version explosive du mouvement, sans ceinture de lest.', …},
   {'exerciseId': 'sw-dips-prise-inversee', …}, {'exerciseId': 'sw-dips-negatifs', …}]}
```

Avec `materiel` = barres parallèles, disques, anneaux, les dips bulgares aux anneaux arrivent en tête.

- **Étiquettes.**
  - « Équivalent » : même schéma, mêmes muscles principaux, même mode et même qualité, difficulté de −2 à +1, sans assistance.
  - « Plus facile ».
  - « Sans ce matériel » : même schéma, ou sa version explosive au même poste ; autre mode ou autre qualité.
  - « Autre » : autre schéma de la même famille, avec un muscle principal commun.
  - Ordre selon la raison. Dans chaque étiquette, une chaîne de variantes à la fois d'abord ; poids de proximité repris de `Catalog.similarity`.
- **Règle de l'« autre » schéma.** Elle est interdite pour une ligne principale (`main`) ou une figure (`skill`), dont le schéma est le but. Le HSPU au mur n'est donc jamais proposé pour le dip lesté principal de la J5. Il reste trouvable par la recherche de l'application. Pour un accessoire, il est proposé en « autre ».
- **Filtres durs.** Le matériel du jour : celui du profil, sinon celui de la ligne écrite moins le manquant ; le sol, le tapis et la magnésie toujours, le mur sauf au parc. Le lieu et le niveau. Pour la raison `douleur`, **jamais** un exercice qui sollicite la zone. Pour `trop_dur`, jamais plus difficile que la ligne.
- **Cible de départ**, par ordre de priorité :
  1. l'historique de l'exercice ;
  2. le transfert de charge depuis l'exercice remplacé (`coachLoadReferences` de kalis_plan, arrondi vers le bas, jamais à la hausse) ;
  3. l'a priori de Koach par les qualités apprises, au quantile prudent ;
  4. rien : l'athlète choisit.
  
  Si l'unité change, la plage est convertie : le haut est la prévision, le bas 80 % du haut.
- **Remplacement versé.** L'item porte `remplace: {exerciseId: <écrit>, raison}` et `exerciseId` = remplaçant. Koach le sert à l'emplacement (groupe, format, technique, séries et repos gardés), avec ses propres cibles et la raison `koach.remplacement`. Exemple : dips aux barres dans l'E2MOM de la J5, 6 × 16-20, groupe à 6 tours. Les séries sont versées au nom de l'exercice réel ; l'exercice écrit ne reçoit aucune mesure (testé). La charge transférée n'est servie qu'un jour sans prudence (relecture M2).
- **Temps.** Médiane 2,2 ms sur 1 039 fiches.

## 4. Mesures et critères

Le détail est dans `kalis_adapt/docs/CRITERES_KM7.md`.

| Critère (graines 0-5 ; 100 graines pour la sécurité) | Seuil | 1.0.8 | **1.0.9 Dart** | **1.0.9 Python** |
| --- | --- | --- | --- | --- |
| Violations de sécurité, saisons plantées, retraits sous l'écrit par la rampe, coupes silencieuses | 0 | 0 | **0** | **0** |
| 1 e1RM | < 3 % (écart accepté) | 3,74 % | 3,74 % | 3,74 % |
| 2 mauvais jour | < 1 % | 0,86 % | 0,86 % | 0,86 % |
| 3 convergence | ≤ 11,06 | 4,809 | 4,809 | 4,809 |
| 4 couverture | 88-92 % | 91,90 % | 91,90 % | 91,90 % |
| 5 calibration (indicateur) | — | 11,95 pts | 11,95 pts | 11,95 pts |
| 6 jour J | ≥ 0,9156 | 0,9362 | 0,9362 | 0,9362 |
| 7 bis (six jeux) | ≥ 90 % | 24, 22, 19, 23, 22, 21 | identique | — |
| 11 temps | ≤ 10 s ; ≤ 50 ms | 0,124 s ; 28,6 ms | 0,114 s ; 14,0 ms | — |

- **Recul** : aucun. Les fichiers de critères, de sécurité et d'adversaires sont identiques à ceux de KM6, hors version et durées.
- **Parité** : 90 599 saisons sur 90 600 identiques une à une, la même saison qu'en KM6 différant de 1,2·10⁻¹².
- **Plan avec `applique: false` comparé au plan sans forme** : identique sur 395 364 séances sur 395 364 dans la variante « versé », graines 0-17. Un témoin tourne dans la même séance : copie du moteur avec ses extensions, mêmes événements, seuls les faits. Le premier passage avait compté 886 écarts. Ils venaient tous du témoin : une copie sans extensions ne recevait pas la réponse au diagnostic de la surveillance.

**Variante « garde l'écrit une fois sur deux »** (graines 0-5) : verser la forme, comparé à ne verser que les faits.

| Mesure | Avec la forme | Effet |
| --- | --- | --- |
| Résidu d'e1RM de la séance gardée | −7 % | réel |
| Résidu brut de la séance gardée | −3 % | réel |
| e1RM | −0,03 pt | dans le bruit |
| Convergence | −0,10 | dans le bruit |
| Jour J | +0,004 | dans le bruit |
| Séance suivante | pas mieux prédite (e1RM égal, résidu brut +2 %) | — |
| Couverture | 91,2 % → 92,2 % (bande 88-92 %, bruit 0,8 pt) | intervalle un peu large, donc prudent |

Koach apprend surtout à ne pas confondre un mauvais jour avec une baisse de capacité.

## 5. Relecture indépendante (sous-agent Opus, avant la fin de la campagne)

Vérifié sans écart :

- parité des remplaçants sur 1 218 demandes aléatoires et 18 cas limites ;
- 90 cas de `plan` avec `remplace` ;
- état complet inchangé après les aperçus ;
- `charge_manuelle` avant la première série ;
- comportement par défaut.

Corrigé, avec tests :

- **M1** : la fixture `km7.json` faisait échouer `generer.py --verifier` ; elle est déplacée dans `test/fixtures/km7/`.
- **M2** : la charge transférée court-circuitait les plafonds (part maximale de reprise, réserve, bilan). Elle n'est plus servie que sans aucune prudence ; sinon, c'est « charge à choisir ».
- **m3** : la forme n'était pas versée pour une séance close sans série.
- **m4** : la `koachCible` de tentative était retirée au remplaçant.
- **m5** : `CHANGEMENTS_1_0_9.md` manquait.

Limites dites, reprises au § 7 : 6, 7 et 8.

## 6. Incidents

- **18:12 UTC.** Le pilotage a annulé la campagne, restée en file 2 h 30, en la prenant pour un doublon du contrôle complet poussé sur la même branche. Ce contrôle a été annulé à son tour.
- **Essai 2.** Il a été forcé à l'arrêt.
- **20:18 UTC.** Le pilotage a relancé l'essai 3 (`LANCEMENTS.md`). Le contrôle complet a ensuite tourné sur `claude/ci-cp-b`.
- **Résultat** : environ 6 h de délai, sans effet sur les résultats.
- **`pytest` sur la CI** (Python 3.11), part 61 : `test_fixtures` reste rouge par arrondis (`numerique.json`, connu depuis KM4) ; `test_documents` et `km7.json` en trop sont corrigés dans l'arbre livré, qui passe 359/359 en session.

## 7. Ce que KB6 doit monter

Le détail est dans `packages/kalis_adapt/docs/INTEGRATION_KM3.md` § 13.

1. **Copier** `lib/`, `assets/koach/` et `pubspec.yaml` de `etiquettes/kalis_adapt-v1.0.8`. L'asset `koach_params_1_0_9.json` remplace `koach_params_1_0_8.json` (SHA-256 ci-dessus). Les tests d'empreinte sont à mettre à jour.
2. **« Garder l'écrit » / « Annuler »** : verser le bilan complet avec `applique: false`, au lieu de `factsOf`. **Attention** : `HealthCheck` de kalis_core n'a pas ce champ et ignore les champs inconnus. Ne pas faire passer le bilan versé par ce type (sinon le bilan est appliqué en silence) ; tester le journal.
3. **« Remplacer pour aujourd'hui »** :
   - appeler `k.remplacants(koachInfosRemplacement(catalog, profil), demande)` ;
   - grouper les propositions par `etiquette` et montrer `texte` sous « Pourquoi ? › Il me manque : … » ;
   - utiliser la cible de `depart` ;
   - garder la recherche libre en dessous.
4. **Remplacement versé** : `remplace` dans les items de `plan`, avec **`grilles` et `zones` sous l'id du remplaçant** (la conduite sous douleur en dépend). Afficher `koach.remplacement`. La ligne remplacée a désormais ses cibles.
5. **Limite** : `remplacants` ne filtre une zone douloureuse que pour la raison `douleur`. Un jour de douleur active, passer la raison `douleur` ou `zones`.

## 8. Recommandations au pilotage

1. **Valider KM7** : Koach 1.0.9 (`kalis_adapt` 1.0.8, `moteurs` 266f9626, `etiquettes/kalis_adapt-v1.0.8`). Le moteur par défaut est identique à 1.0.8 sur toute la campagne ; le plan non appliqué est identique au plan sans forme sur 395 364 séances sur 395 364. Puis lancer KB6.
2. **Règle à graver** : ne rien pousser sur la branche de contrôle d'un lot pendant que sa campagne tourne (concurrence `cancel-in-progress`). Le contrôle complet va sur l'autre branche de la voie.
3. **À suivre** : couverture de la variante 92,2 %, si le propriétaire garde souvent l'écrit en Libre. À recaler seulement si une mesure sur son journal le demande (critère 10, vers le 09/11).
