# Intégrer Koach 1.0 dans l'application (lot KM3)

L'application sert aujourd'hui `kalis_adapt` 0.3.1 (dev6.11.2, `main` 9ef40dad : CI1g, puis CI1h pour la charge
fixe). Ce document dit ce que KM3 doit changer pour passer à **Koach 1.0** (`kalis_adapt` 1.0.0,
`package:kalis_adapt/koach.dart`), avec un seul moteur et un seul comportement (cahier `pipeline/cp/CAHIER_KM.md`,
décisions C11, C13, C15). C'est le document que citent `CONTRAT.md` (§ K.7), `pubspec.yaml` (assets, § 3) et
`prompts/KM3.txt`.

**Mise à jour du 15/10/2026 (`kalis_adapt` 1.0.1, lot KM2c1)** : portage de la référence Koach 1.0.2 (reprise par
paliers mesurés, ouverture des tentatives selon la note des barres, dispersion à l'échéance, intervalle recalé ;
`reference/CHANGEMENTS_1_0_2.md`). L'API et le schéma du journal ne changent pas : une application intégrée sur
1.0.0 passe à 1.0.1 en montant le paquet et en remplaçant l'asset de paramètres (`koach_params_1_0_1.json` →
`koach_params_1_0_2.json`, nouvelles empreintes au § 3). Seul ajout visible : la clé `prevu_jour` dans les entrées
de `Planification.previsions` (moyenne et écart-type de ln capacité prévue le jour J, par cible).

**Mise à jour du 16/10/2026 (`kalis_adapt` 1.0.2, lot KM2c2)** : portage de la référence Koach 1.0.3 (fiabilité des
notes : l'incertitude des capacités est élargie par κ ≥ 1 chez un athlète aux notes peu fiables, jamais leur
moyenne ; prudence ciblée à l'ouverture des tentatives ; barre suivante après un échec hors compétition ; règle de
0.3.1 « aucune hausse après un échec non prévu, tout schéma » ; `reference/CHANGEMENTS_1_0_3.md`). L'API et le
schéma du journal ne changent pas : monter le paquet et remplacer l'asset de paramètres (`koach_params_1_0_2.json`
→ `koach_params_1_0_3.json`, nouvelles empreintes au § 3). Seul ajout visible : la clé `fiabilite` de `posterior()`
(`phi`, `ln_phi`, `p_phi_sup_2`, `notes`, `part_non_notee`, `elargissement`, `par_schema`), lisible par le mode dev.

**Mise à jour du 16/10/2026 (`kalis_adapt` 1.0.3, lot KR1)** : portage de la référence Koach 1.0.4 : la réponse
« rien de spécial » au diagnostic n'élargit plus l'incertitude d'une capacité au-delà de son a priori (avant : des
réponses répétées la faisaient diverger jusqu'à planter une séance, `reference/CHANGEMENTS_1_0_4.md`). API, schéma
du journal et valeurs des paramètres inchangés : monter le paquet et remplacer l'asset de paramètres
(`koach_params_1_0_3.json` → `koach_params_1_0_4.json`, version `1.0.4-ref.1`, nouvelle empreinte au § 3). Mesuré
sur le couple servi, `kalis_plan` 0.4.1 × Koach 1.0.4, 34 profils (`pipeline/cp/livraisons/LIVRAISON_KR1.md`).

Sources lues : `CONTRAT.md` § K ; `reference/CONTRAT_1_0.md` (§ 2, 3, 3.7, 7, 9.5, 10, annexe A) ;
`reference/rejeu/journal_app.py` et `walk_forward.py` ; `lib/src/koach/moteur.dart`, `planification.dart`,
`rupture.dart`, `adherence.dart`, `dual.dart`, `parametres.dart`, `seance.dart`, `securite.dart` ;
`lib/validateur.dart`, `lib/src/validateur/profil.dart`, `validateur.dart` ; `kalis_bench`
`lib/src/km/politique_koach.dart` (l'appelant de référence) et `meneur.dart` ; côté application (`main`) :
`lib/session_adapt_store.dart`, `imported_program.dart`, `journal_adapter.dart`, `store.dart`, `koach_data.dart`,
`program_origin.dart`, `plan_store.dart`, `evolution_store.dart`, `adapt/session_adapt.dart`,
`dev/engine_inspector.dart`, `dev/dev_flags.dart`. Quand une chose vient du code et non d'un document, c'est dit
(« d'après le code »). Les références `fichier:fonction` sans chemin sont dans `lib/src/koach/`.

Textes des raisons : `package:kalis_adapt/koach_textes.dart` (§ 4), testé par `test/koach_textes_test.dart`.

---

## 0. En bref

1. Un objet `Koach` vivant par utilisateur, construit depuis les deux assets, avec quatre extensions dans cet
   ordre : `Planification`, `Surveillance`, `ControleDual`, `Adherence`. Le validateur de sécurité est obligatoire.
2. Le **journal de Koach** (`koach.journal`, liste d'événements JSON) est la source de vérité du moteur : il est
   persisté tel quel, exporté dans la sauvegarde, et `rejouer` le reconstruit à l'identique (même journal = même
   état, extensions et planification comprises, `CONTRAT.md` K.6).
3. Chaque appel de `plan` est lui-même un événement du journal. Donc : un appel par décision réelle (ouverture de
   la séance, cible d'une série), jamais pour un aperçu, une prévision ou un rafraîchissement d'écran.
4. La structure du programme n'est jamais modifiée par Koach ; il module séries et charges, borne les séances et
   applique les garde-fous de 0.3.1. Le programme de 40 semaines devient la référence (`reference`) de la
   planification (D2) ; la charge fixe de CI1h reste une contrainte de l'application, au-dessus de Koach (C15).
5. Aucun code brut à l'écran : `texteRaisonKoach` pour chaque raison, `texteQuestionKoach` /
   `texteChoixKoach` pour le diagnostic.

---

## 1. API

### 1.1 Paquet et imports

- Copie complète, octet pour octet, de `etiquettes/kalis_adapt-v1.0.0` dans `packages/kalis_adapt` ; `kalis_bench`
  n'entre jamais dans l'application. `kalis_core` 0.4.3 et `kalis_plan` 0.3.1 ne changent pas (Koach ne demande
  aucun type nouveau).
- Imports de l'application :
  - `package:kalis_adapt/koach.dart` : `Koach`, `rejouer`, `Planification`, `Surveillance`, `ControleDual`,
    `Adherence`, `importerParametres`, `lireParametresKoach`, `lireFichesKoach`, `koachVersion`,
    `koachParametresSha256`, `koachFichesSha256`, `Grille`, `Json` ;
  - `package:kalis_adapt/validateur.dart` : `constatsDesBlocs` (validateur à lecture tardive, § 1.2),
    `validateurSecurite`, `ProfilValidation` ;
  - `package:kalis_adapt/koach_textes.dart` : `texteRaisonKoach`, `texteRaisonDual`, `texteQuestionKoach`,
    `texteChoixKoach`.
- `package:kalis_adapt/kalis_adapt.dart` (0.3.1 : `KalisAdapt`, `applyProposal`, `unlockLevelFor`) ne doit plus
  être importé par le code de décision de l'application (§ 6). Seule exception admise, comme au banc
  (`politique_koach.dart`, `debut`) : `ExerciseBook` pour lire la grille de charges et les niveaux de zone d'un
  exercice (c'est une lecture de la base, pas une décision) ; si KM3 préfère s'en passer, il recopie ces deux
  lectures.

### 1.2 Construction

```dart
final params = lireParametresKoach(await rootBundle.loadString('assets/koach/koach_params_1_0_4.json'));
final fiches = lireFichesKoach(await rootBundle.loadString('assets/koach/vecteurs_qualites_v1.json'));
final koach = Koach(params, fiches, profilKoach);           // profilKoach : § 2.6, figé (instantané)
final validation = ProfilValidation.depuisProfil(athleteProfile, debut: lundiS1);
late final Planification planification;
planification = Planification(params, fiches, (blocs) => constatsDesBlocs(blocs,
    catalog: catalog, profil: validation,
    // Lecture tardive : l'horizon et les débuts de bloc sont ceux du dernier `reference`.
    horizonSemaines: planification.horizon, blockWeeks: planification.blockWeeks));
koach.extensions
  ..add(planification)
  ..add(Surveillance(params))
  ..add(ControleDual(params, liftsPrincipaux))
  ..add(Adherence(params));
```

- `params` : le fichier **initial** (l'asset), jamais un fichier importé (les imports sont des événements
  `parametres`, § 3). `Planification` et `ControleDual` gardent une copie de `params` à la construction : un import
  ne les change pas (contrat § 7.3, limite connue).
- `Planification(params, fiches, validateur, [options])` : sans validateur, `ArgumentError` (d'après le code,
  `planification.dart`, constructeur). Aucune `options` dans l'application (le banc passe `trajectoires` pour
  aller plus vite ; l'application garde les 1 000 trajectoires du fichier).
- `ControleDual(params, liftsPrincipaux)` : exercices des emplacements de rôle `main` dont la fiche est de type
  `charge`, triés (`_pkLiftsPrincipaux` de `politique_koach.dart`).
- `Adherence([params])`, `Surveillance(params)` : sans autre argument.
- L'ordre des extensions est celui du banc (`PolitiqueKoach.debut`) et compte : c'est l'ordre des crochets et
  celui des modulations appliquées par `plan` (planification, puis semaine allégée, puis bras d'essai,
  `moteur.dart`, `_plan`).

### 1.3 Validateur de sécurité

`validateurSecurite(catalog:, profil:, horizonSemaines:, blockWeeks:)` rend la fonction `Validateur` (blocs JSON →
constats `{code, message, week, dayIndex, exerciseId, value, limit}`), copie fidèle des critères du banc
(`lib/src/validateur/validateur.dart`). Dans l'application :

- `catalog` : le `Catalog` de la base v1.1 déjà chargé (`content.catalog`) ;
- `profil` : `ProfilValidation.depuisProfil(profil, debut: lundiS1)` (`profil.dart`) : niveau, âge, taille, poids,
  records connus, gênes du profil, échéance `main` la plus proche, semaines de pause ;
- `horizonSemaines` et `blockWeeks` : **lus au moment de l'appel** dans la planification (`planification.horizon`,
  `planification.blockWeeks`, posés par le dernier `reference`), comme dans l'exemple du § 1.2 : un validateur
  construit une fois avec des valeurs figées ne verrait pas les semaines d'un nouveau bloc (sous-détection, relecture
  indépendante de KM2, M3).

Le validateur n'est pas dans le journal : pour un rejeu exact, il doit être reconstruit avec les mêmes entrées.
Comme l'horizon et les débuts de bloc viennent du journal (lecture tardive), seul le profil de validation reste hors
journal : KM3 garde à côté du journal l'instantané du `ProfilValidation` (et de `lundiS1`) utilisé, et le
reprend tel quel au rejeu (§ 8, point 4).

### 1.4 Appels

| Appel | Quand | Ce qu'il fait |
| --- | --- | --- |
| `koach.observe(e)` | chaque fait du journal (§ 2) | ajoute `e` à `koach.journal`, puis le traite (`moteur.dart`, `observe`) |
| `koach.plan({'horizon': 'seance', 'items', 'grilles', 'zones', 'roles'})` | une fois, à l'ouverture réelle de la séance, après `seance_debut` | séance servie `{items, raisons}` ; les modulations des extensions sont appliquées par la façade (`AvecItemsDuJour`) : l'application passe les items **écrits** |
| `koach.plan({'horizon': 'serie', 'item', 'index'})` | une fois par série, juste avant de la proposer | cible `{repsLow, repsHigh, secondsLow, secondsHigh, loadKg, flames, role, repere?, proposition?, trace?}` ou `null` (« arrêter l'exercice ») |
| `koach.plan({'horizon': 'semaine', 'semaine', 'replanifier'?})` | jamais en usage normal | journalisé ; pour lire la semaine, utiliser `Planification.itemsModules(w)` (lecture pure, d'après le code) |
| `koach.posterior()` | lecture | capacités `exercices{id: {valeur, ecart_type, intervalle_90, …}}` (charge **totale** pour un exercice chargé) |
| `koach.explain()` | après chaque `plan` | raisons `{code, params}` de la séance en cours (doublons possibles : une raison de `cible` est réémise à chaque série, contrat A.3 n° 24) |
| `rejouer(params, fiches, profil, journal, fabriques)` | démarrage, réactivation, correction d'une saisie | reconstruit l'état ; `fabriques` = les quatre constructeurs du § 1.2, dans le même ordre |

Règles d'appel :

- **`plan` ne sert jamais d'aperçu.** Un appel de `plan` change l'état (pistes créées, mémoire de séance, budgets,
  `_derniereCharge` de la forme d'adhérence) et entre au journal. La cible d'une série est demandée une fois et
  gardée (dans `SessionLog.adapt` ou son successeur) ; un nouvel affichage relit la valeur gardée.
- **`grilles`** : `{exerciseId: {pas, minimum, halteres}}` (ou `Grille`), lues comme au banc dans
  `ExerciseBook.find(id).grid` (`step`, `minimum`, `dumbbellRule`). **`zones`** : `{exerciseId: ({zone: niveau 0,
  0,5 ou 1}, {zones provoquées})}` : `info.zoneLevel(z)` et `coachPainStopHits(info.exercise, z)` de `kalis_plan`
  (`politique_koach.dart`, `debut`). **`roles`** : `{slotId: role}` des emplacements de `pass1.days[].slots[]`.
  `Koach.canonique` ne garde que les exercices et emplacements des items (le journal reste petit).
- **`item` d'une série** : l'item **servi** (sortie de `plan(seance)`), tel quel ; `index` = rang de la série
  dans cet item, à partir de 0. Un vrai test arrive comme un item à part, inséré avant l'item de travail
  (`slotId` + `.t`, `kind: 'test'`, `koach: 'vrai_test'`, contrat § 3.3).
- Une cible `null` arrête l'exercice (raison `koach.arret_exercice`) : les séries restantes ne sont plus
  proposées.
- `setTargets` vaut `null` sur les items de travail chargés, en répétitions ou en tenue : la charge et la plage
  de chaque série viennent de `plan(serie)`. L'écran de séance ne lit plus les cibles par série de l'item.

### 1.5 Temps de calcul et fil d'exécution

- Mesures de la référence Python (`reference/donnees/criteres_moteur.json`, saison de 16 semaines, 1 000
  trajectoires, validateur) : `observe(serie)` 1,0 ms médiane, `plan(serie)` 0,15 ms, `plan(seance)` 0,7 ms,
  replanification 0,40 s médiane (0,54 s max). Sur la VM Dart de la CI (KM2, après chauffe JIT, `kalis_bench` `docs/CRITERES_KM2.md`) : replanification
  0,21 s au plus, `observe(serie)` + `plan(serie)` suivant 21,5 ms au plus (p95 ≈ 1,3 ms) ; KM3 les mesure sur
  émulateur (cahier : replanification ≤ 10 s, série ≤ 50 ms).
- Une replanification part de trois événements : `reference` (`Planification.surReference`), chaque `semaine_fin`
  (`Planification.finSemaine`, semaine suivante) et `plan` à l'horizon `semaine` avec `replanifier`. `observe`
  est synchrone : ces trois événements se versent hors du fil d'interface (`Isolate.run` sur une copie reconstruite par
  `rejouer`, aucun autre événement versé pendant le calcul, puis l'instance rendue remplace l'instance vive ; ou
  travail différé avec un indicateur « Koach prépare ta semaine »). Si `observe` ou `plan` lève une exception,
  l'événement est retiré du journal (`moteur.dart`) mais l'état de l'instance peut être partiel : reconstruire
  l'instance par `rejouer`. Les autres événements se versent sur le fil principal.
- Un rejeu complet refait toutes les replanifications du journal (une par semaine écoulée). Sur 40 semaines, il
  faut compter plusieurs dizaines de secondes : garder l'instance vivante pendant la vie de l'application et ne
  rejouer qu'au démarrage à froid (en arrière-plan, séance servie seulement une fois l'état prêt), à la
  réactivation après un arrêt d'urgence et après la correction d'une saisie passée (§ 2.7).

---

## 2. Journal

### 2.1 Échelles de temps

| Grandeur | Définition dans l'application | Lue par |
| --- | --- | --- |
| `jour` | jours civils depuis le **lundi de la semaine S1** du programme (`program.start` ramené au lundi, comme `journal_app.convertir` : `lundi = depart - weekday`) | toute la séance, les douleurs, l'échéance |
| semaine globale `g` | `g = S - 1` (S1 → 0), indice de la semaine du programme ; mêmes indices que `block_weeks` | `seance_debut.contexte.semaine`, `semaine_fin.semaine`, `reference.semaine`, `seance_manquee.semaine` |
| `jour_index` | `dayIndex` de la journée dans la semaine écrite du bloc (`pass2.weeks[].days[].dayIndex`), pas le J de l'application ; pour le programme importé, `ImportedSegment.dayOfJ[J]` | modulation de la planification (`itemsModules` est indexé par `(dayIndex, slotId)`) |

Écart voulu avec `rejeu/journal_app.py` : ce convertisseur met `contexte.semaine = S` (à partir de 1) et
`semaine_fin {jour: 7·s, semaine: s}` (indice de la semaine qui **commence**). Il ne sert qu'au rejeu sans
extension, où ces champs ne changent rien. Avec la planification, il faut la convention du banc et du contrat
(§ 2.1 : « indice de la semaine qui finit ») : à la fin de la semaine `g`, `{type: 'semaine_fin', jour:
7·(g + 1), semaine: g}` (`politique_koach.dart`, `finSemaine`). Sinon chaque lundi replanifierait la mauvaise
semaine (`Planification.finSemaine` replanifie `semaine + 1`).

### 2.2 Ordre des événements

Les événements sont versés dans l'ordre chronologique des jours ; `seance_debut.jour` ne recule jamais.

1. **Rattrapage** (à l'ouverture de l'application, et au plus tard avant toute séance) : pour chaque semaine `g`
   finie depuis le dernier événement, dans l'ordre :
   a. un `seance_manquee {jour, semaine: g}` par journée prévue de `g` (avec des exercices, non « reprise »,
      non faite) dont la date est passée, au jour prévu ; ses items écrits (champs de volume) sont gardés pour le
      `contexte.manquees` de la prochaine séance ;
   b. `semaine_fin {jour: 7·(g + 1), semaine: g}` (replanification de `g + 1`, hors du fil d'interface) ;
   c. la proposition d'essai N-of-1 du contrôle dual, comme au banc (`_ControleDualBanc.apresSemaine`) : si
      `calibre(koach, lifts)` est vrai et qu'aucun essai ne tourne, `decision {jour: 7·(g + 1), essai: {semaine:
      g + 1, cible: {exerciseId}, traites, temoins, contexte, graine, n_bras}}` (cible : le lift principal de plus
      petite demi-largeur ; témoins : au plus 6 exercices présents dans les 8 dernières semaines de
      `ControleDual.pre` ; `graine` = `planification.graine` du fichier ; `contexte` =
      `ControleDual.contexteEssai(koach, g + 1, joursEcheance)`, **obligatoire** : un contexte vide laisserait
      démarrer un essai en affûtage, sous douleur ou près de l'échéance). En pratique le modèle n'est presque
      jamais calibré (M5, § 8) : l'appel coûte peu.
2. `poids {poids_kg}` quand une pesée nouvelle existe (ou `seance_debut.poids_kg`, § 2.3).
3. `seance_debut {jour, bilan, poids_kg, contexte}` (§ 2.4).
4. Si `Surveillance.etat()['hors_modele']` est vrai : message et diagnostic (§ 5.4), réponse versée en
   `decision {jour, diagnostic}` **avant** `plan` (comme `politique_koach.dart`, `planifier`).
5. `plan(seance)` (items écrits de la journée).
6. Pour chaque série, dans l'ordre réel : `plan(serie)` → l'utilisateur fait la série → `serie`. Un changement de
   cran d'élastique se verse (`cran`) avant la série concernée.
7. `seance_fin {jour, douleurs, seance: {sets: [séries versées]}}`.
8. Les décisions prises pendant la séance (suggestions acceptées ou refusées, § 5.1), en `decision`, dans l'ordre
   des taps, avec le `jour` de la séance. Les verser après `seance_fin` garde le modèle hors de la séance quand
   un refus motivé devient une mesure (`Modele.observerRaison`), comme au banc où elles arrivent en fin de semaine.

### 2.3 Correspondance des données de l'application

| Donnée de l'application | Événement de Koach | Champs |
| --- | --- | --- |
| Séance du programme commencée (`SessionLog`, clé `S<s>-J<j>`) | `seance_debut` | `jour` (date réelle), `bilan`, `poids_kg`, `contexte` (§ 2.4) |
| Série validée (`SetEntry.done`, non `excluded`, mesure lisible) | `serie` | objet du § 2.5 |
| Série écartée (`excluded`), non validée, sans mesure | rien | comme `journal_app.py` (le modèle ne filtre pas `excluded` lui-même : `Modele.observerSerie`, d'après le code) |
| Fin de séance (`done`, `finishedAt`) | `seance_fin` | `douleurs` : douleurs signalées pendant ou après la séance (`PainReport` de phase `during` / `after`), `[{zone, intensity}]`, `null` si aucune question n'a été posée ; `seance.sets` : les objets `serie` versés |
| Flammes de la série (`SetEntry.flames`, 1 à 10) | `serie.flames` | « Je ne sais pas » (`flamesUnknown`) → `null` ; ancienne saisie : `Flames.fromRir(effort)`, sinon `rir` texte selon `koach.legacyScale` (règles de `journal_app.py`) |
| Note préremplie affichée | `serie.target.flames` | sert à repérer la note « paresseuse » (laissée telle quelle) : mettre la valeur **affichée**, pas la cible théorique |
| Bilan du début de séance (`SessionAdapt.check`, `kalis_core` `HealthCheck`) | `seance_debut.bilan` | même clés (`overall`, `sleepHours`, `sleepQuality`, `energy`, `mood`, `soreness`, `stress`, `motivation`, `nutrition`, `hydration`, `pains`) ; `pains` absent = question non posée, `[]` = aucune douleur. Avant G9 (`koach.answers`) : `overall = plafond(forme / 2)` borné à 1..5, `sleepHours` ; la douleur « par mouvement » n'est pas convertie (`journal_app.py`) |
| Temps disponible du bilan (`minutesAvailable`) | `seance_debut.contexte.budget` | pas dans `bilan` (Koach ne le lit pas là) |
| Lieu du jour (`adaptSetPlace`, `kc.Place`) | `contexte.lieu` | `Place.code` (`salle`, `maison`, `exterieur`) = valeurs `lieux` des fiches |
| Pesée (`koach.weighIns`) | `poids {poids_kg}` ou `seance_debut.poids_kg` | dernière pesée au plus tard du jour (`journal_app.py`) ; sans pesée ni poids de profil, Koach prend 72 kg sans le dire (m14) |
| Charge changée à la main **pendant** une série | rien de plus que la `serie` | la série porte la charge réelle ; le banc ne verse jamais `charge_manuelle` (d'après le code) : la verser en plus compterait la même mesure deux fois |
| Valeur de référence changée à la main hors séance (`koach.history`, source `manual` ; charge de travail d'un accessoire, 1RM d'un mouvement principal) | `charge_manuelle {exerciseId, loadKg, reps, rir}` | `loadKg` = charge **externe** ; 1RM : `reps` 1, `rir` 0 ; accessoire : `reps` = `refReps`, `rir` = réserve cible de la ligne (2 à défaut, comme `declares_initiaux`). Exercices `charge` seulement (contrat § 5.11) |
| Suggestion refusée avec raison (§ 5.1) | `decision {jour, proposition, accepte: false, raison}` | `raison` ∈ `too_heavy`, `too_light`, `equipment`, `time`, `other` ou `null` (un code inconnu de l'adhérence est sans effet, d'après le code) |
| Suggestion acceptée | `decision {…, accepte: true, raison: null}` | |
| Cran d'élastique changé (exercice assisté) | `cran {exerciseId, facteur}` | élastique plus fin (moins d'aide) : `0,75` ; plus épais : `1/0,75` (convention du banc, hors fichier de paramètres, contrat A.3 n° 29). L'application n'a pas aujourd'hui de champ « cran » (§ 10, question 6) |
| Journée prévue non faite, date passée | `seance_manquee {jour, semaine}` | + items écrits dans `contexte.manquees` de la séance suivante |
| Fin de semaine (lundi passé) | `semaine_fin {jour, semaine}` | § 2.1 |
| Réponse au diagnostic | `decision {jour, diagnostic: {cause, zone?, intensite?, seances_par_semaine?, duree_max_min?}}` | § 5.4 |
| Proposition d'essai N-of-1 | `decision {jour, essai: {…}}` | § 2.2, 1c |
| Import de paramètres (mode dev) | `parametres {fichier}` | par `importerParametres` seulement (§ 3) |
| Plan de référence, cibles | `reference`, `cibles` | § 2.6 |
| Séance « reprise » (`isResume`), séance libre (`S0-…`) | rien | comme `journal_app.py` (séances manuelles ignorées) ; § 10, question 9 |

### 2.4 `seance_debut.contexte`

Toutes les clés sont lues par la séance ou les extensions (contrat § 2.1, `moteur.dart`). Le banc les remplit dans
`politique_koach.dart`, `planifier`.

| Clé | Valeur dans l'application |
| --- | --- |
| `semaine` | `g` (§ 2.1). Sans elle, ni le volume de la semaine (retour gradué) ni les modulations ne s'appliquent |
| `jour_index` | `dayIndex` de la journée écrite (§ 2.1) |
| `genre` | `kind` de la semaine écrite du bloc (`pass2.weeks[weekIndex].kind` : `intro`, `normal`, `deload`, `test`, `taper`…) |
| `intention` | `intent` de la même semaine (`WeekIntent`, annoté par CI1e pour le programme importé) |
| `jour_evenement` | vrai si le jour est un jour d'épreuve (événement `main` du profil ou jour de test de l'échéance du programme) : un test écrit n'est alors pas reporté pour un bilan bas |
| `jours_avant_echeance` | jours jusqu'à l'échéance (même date que `reference.echeance_jour`) ; le banc ne la passe pas (contrat A.3 n° 28) : la passer active la règle A6.5 de 0.3.1 (ni mesure à 14 jours ou moins, ni excentrique accentué près de l'échéance) — § 10, question 7 |
| `lieu` | `Place.code` du jour, ou absent |
| `budget` | minutes disponibles (bilan, ou disponibilités données au diagnostic, § 5.4), ou absent |
| `manquees` | `[{semaine, genre, items}]` des journées manquées depuis la séance précédente ; `items` réduits aux champs de volume `slotId, exerciseId, kind, sets, targetFlames, secondsLow, secondsHigh` (`_pkItemsVolume`) ; vidé après chaque `seance_debut` |
| `reste_semaine` | items écrits (mêmes champs) de chaque journée restante de la semaine après celle du jour, dans l'ordre |

### 2.5 Objet `serie`

Le plus simple est de partir de l'`SetRecord` que `convertLegacyJournal` (`journal_adapter.dart`) produit déjà, puis
de faire ce que fait `politique_koach.dart` (`_serie`) :

| Champ de Koach | Source |
| --- | --- |
| `exerciseId`, `slotId`, `setIndex`, `kind`, `reps`, `seconds`, `flames`, `technique`, `role` | mêmes champs de `SetRecord` (`kind` : `work`, `warmup`, `test` ; `role` : `test` ou `attempt` marquent une mesure) |
| `externalLoadKg` | charge **externe** (`kg` saisi) ; `null` si vide ; une valeur négative n'est pas versée (`journal_app.py`) |
| `failed` | **mesure 0** (aucune répétition, tenue de 0 s), comme `journal_app.py`. Ne pas prendre `!success` : `success` de l'application est faux aussi sous le bas de la plage (`journal_adapter.dart`, règle C10), ce qui ferait lire un échec à chaque série courte |
| `target` | la cible rendue par `plan(serie)` pour cette série : `{repsLow, repsHigh, secondsLow, secondsHigh, flames, role}`, avec `flames` = note **préremplie à l'écran** |
| `repere` | `repere` de la cible (série repère ou de montée) |
| `restSeconds` | repos réel avant la série (`restBeforeSeconds`), sinon le repos écrit ; absent = 90 s pour le modèle |
| `distanceMeters`, `excluded` | course : distance si connue ; `excluded` n'est jamais vrai (série non versée) |
| Lignes d'endurance (course, cardio, conditionnement) | une seule `serie` par ligne (`setIndex` 0), avec `demand`, `doneShare`, `dose`, `fatigueSets` calculés comme `_serie` de `politique_koach.dart` (course : `demand` = durée écrite × poids de qualité / 60, `cardio_poids_qualite` pour une course de qualité ; conditionnement : `demand` = part écrite) ; sans `demand`, le modèle l'ignore |
| Mini-séries (`parts`) | `reps` = total ; `parts` n'est pas lu par Koach (contrat § 2.2) : une série à mini-séries compte comme une série d'une traite (§ 8) |
| Lignes servies telles qu'écrites (contrastes, échelles, `ImportedProgram.asWritten`) | pas de `serie` (comme `nonModelise` au banc) |

### 2.6 Événements `reference` et `cibles`

`reference` remplace l'appel hors journal `charger_reference` de la référence Python (constat M7, `CONTRAT.md`
K.3) : `Planification.surReference` le lit, recharge la référence et replanifie la semaine `semaine`.

| Champ | Programme de 40 semaines (importé) | Programme créé par `kalis_plan` |
| --- | --- | --- |
| `blocs` | `[seg.block.toJson() for seg in importedProgram.segments]` : blocs **annotés d'origine** (CI1e), **sans** la couche CI1c ni les propositions 0.x (`seg.block`, pas `_importedEvolved(seg)`) | `ProgramBlock.toJson()` des blocs validés, passe 2 comprise |
| `block_weeks` | `[seg.first - 1 for seg]` (semaine globale de début de chaque bloc) | semaine globale de début de chaque bloc (`plan.blockFirstWeek(k) - 1`) |
| `horizon` | `importedLastWeek` (40) | `plan.totalWeeks` |
| `cibles` | buts des mouvements principaux en charge **totale** : `target` des `mainLifts` (kg externe) + `fraction` de la fiche × poids du corps ; `max_reps` des `repMax` ; objectifs changés par l'utilisateur (`koach.objectives`) d'abord | `_pkCiblesDuProfil` : `goals` du profil (`one_rm_kg` → + fraction × poids ; `max_reps`, `max_hold_seconds` tels quels) |
| `echeance_jour` | `jour` du jour de test de la dernière semaine (S40, 18/04/2027 au plus tard) | jour de l'événement `main` le plus proche (`_pkEcheanceDe`) |
| `echeances_par_semaine` | facultatif : à l'indice `g`, **tous** les jours d'épreuve connus à la semaine `g` (pas ceux qui tombent dans `g`) ; chaque lundi `w`, l'échéance devient le plus petit de ces jours ≥ 7·w. Pour le programme importé : `[jourS40]` à chaque indice 0 à 39, ou champ omis (l'échéance reste `echeance_jour`). Une liste vide à un indice coupe l'échéance (planification « sans échéance ») | à chaque indice, les jours de tous les événements connus du profil à cette semaine (`eventDaysByWeek` au banc) |
| `principaux` | exercices des emplacements `main` des blocs (`_pkPrincipauxDe`) | idem |
| `poids_corps` | poids du profil (ou dernière pesée) | idem |
| `cibles_tentatives` | `{exerciseId: charge externe visée}` des buts 1RM (posée en `koachCible` sur les items de test) | `_pkCiblesTentatives` |
| `semaine` | `g` de la semaine où Koach prend la main (§ 7) | `g` de la semaine en cours |

Verser un nouveau `reference` complet à chaque changement de référence : nouveau bloc écrit par `kalis_plan`,
programme recréé, « Revenir à mon programme d'origine » (C11.2). `reference` remet le plan à zéro (`plan = {}`) et
replanifie. Quand seuls les buts changent : `cibles {semaine, cibles, cibles_tentatives}` (`surCibles`, pas de
replanification immédiate ; la suivante a lieu au lundi).

Items de `plan(seance)` : ceux des blocs du dernier `reference` (même `slotId`, même `dayIndex`) :
`Planification.appliquer` remplace les séries d'un item par celles de la référence modulée dès que
`(jour_index, slotId)` y figure (d'après le code).

Identifiants : `exerciseId` partout est celui de la base v1.1 (clé des fiches). Les cibles et `principaux` sans
fiche sont ignorés par la planification (`chargerReference`, d'après le code).

### 2.7 Stockage, corrections, rejeu

- Le journal de Koach se garde **tel quel** (liste JSON) dans une section du document de l'application (exportée
  avec la sauvegarde, compressée comme les autres), avec à côté : `koachVersion`, la version et le SHA-256 du
  fichier de paramètres initial, l'instantané du profil de Koach (§ 2.6 et § 7), l'instantané du validateur
  (§ 1.3), la liste ordonnée des extensions et `liftsPrincipaux`. Il ne se reconstruit pas depuis les séances de
  l'application seules : les appels de `plan`, les décisions, les réponses au diagnostic et les imports n'y sont
  pas.
- Rejeu : `rejouer(params, fiches, profil, journal, [() => Planification(…), () => Surveillance(params),
  () => ControleDual(params, lifts), () => Adherence(params)])` avec les **mêmes** entrées (contrat § 9.5 ; la
  condition 3 sur la référence de planification est levée par l'événement `reference`). Test à écrire dans
  l'application : journal → JSON → rejeu → `posterior()`, `explain()`, `Planification.etat()`,
  `Surveillance.etatComplet()`, `ControleDual.etat()`, `Adherence.etat()` identiques.
- Correction d'une saisie passée (charge, répétitions, flammes) ou suppression d'une séance : remplacer
  l'événement `serie` (et la copie dans `seance_fin.seance.sets`) à sa place, ou le retirer, puis rejouer en
  arrière-plan. Un journal modifié reste déterministe (même journal = même état), mais les décisions déjà servies
  ne sont pas réécrites (§ 10, question 8).

---

## 3. Paramètres

- **Assets.** Copier dans l'application, octet pour octet, `packages/kalis_adapt/assets/koach/koach_params_1_0_4.json`
  et `vecteurs_qualites_v1.json` dans `assets/koach/`, déclarés dans `pubspec.yaml` de l'application comme
  `assets/catalog/catalog_v1.json.gz` (copie de l'asset de `kalis_core`). Le paquet est du Dart pur et ne déclare
  aucun asset Flutter (son `pubspec.yaml` n'a pas de section `flutter`) : ne pas utiliser `koachAssetParametres` /
  `koachAssetFiches` (clés `packages/kalis_adapt/…`), qui supposent un asset déclaré par le paquet. Lecture :
  `rootBundle.loadString('assets/koach/…')`, puis `lireParametresKoach` / `lireFichesKoach` (`parametres.dart`),
  qui contrôlent schéma, version, types, bornes et positivité et lèvent `FormatException`.
- **Empreintes.** Paramètres : version `1.0.4-ref.1`, 338 clés, SHA-256
  `2d023854612110d0c3a925c79efeab6a34ac886f3be05089fac228845a2a9016` (`koachParametresSha256`). Fiches : version
  `1.0.0`, 1 039 fiches, SHA-256 `71454d2d6fcc6df8823b23cb640eec5293f40e91822bda9afa75f5ca0098ba6c`
  (`koachFichesSha256`). Un test de l'application compare les octets de `assets/koach/` à ceux du paquet et leur
  SHA-256 aux constantes (comme `test/koach_parametres_test.dart` du paquet).
- **Initial et importé.** Le fichier initial n'est jamais modifié ni sauvegardé : c'est l'asset. Un fichier
  importé est versé au journal et rejoué au même endroit.
- **Import depuis le mode dev** (builds de dev seulement, `kDevBuild` et session de test, comme
  `openEngineInspector`) : choisir un fichier JSON (sélecteur de fichiers, aucune permission réseau), puis
  `importerParametres(koach, texte)` (`rupture.dart`). Résultat `{ok, erreurs, version}` : si `ok` est faux, rien
  n'est appliqué ; afficher les erreurs telles quelles (écran de développement). Si `ok`, l'événement
  `parametres {fichier}` est déjà dans le journal : sauvegarder. Refusé par la validation (contrat § 7.3) : toute
  la section `securite`, les clés figées (`plafond_volume`, `plafond_intensite`, essais, tests, `douleur_secours`…),
  une clé inconnue, un type différent, une valeur hors bornes. Rien n'est relu dans `Planification.p`,
  `ControleDual.params`, la BOCPD ni les hypothèses de dose (limite connue, contrat § 7.3) : l'écran le dit.
- Afficher dans l'inspecteur la version des paramètres en vigueur (`koach.params['version']`) et la liste des
  imports du journal.

---

## 4. Codes de raison et textes

`package:kalis_adapt/koach_textes.dart` (Dart pur) donne une phrase française par code, au registre de
`kalis_core/data/reason_texts_fr_0_4.json` (tutoiement, Koach dit « je ») :

- `texteRaisonKoach(raison, {nomExercice})` : `raison` = `{code, params}` de `explain()` ou des `reasons` d'un
  item servi. Couvre les 22 codes `koach.*` du contrat § 3.5 (`koachCodesRaisons`) avec toutes leurs causes
  (`koachCausesRaisons`, relevées dans `seance.dart` et `securite.dart` : `koach.test_reporte` émet aussi
  `coupure`, absent du contrat) ; les causes de l'alerte hors modèle (`rupture`, `residu`, `assiduite`, `douleur`,
  préfixe `surveillance.` permis) et le message d'entrée (`surveillance.hors_modele`) ; les actions de
  `Surveillance.repondre` (l'objet rendu tel quel, ou code `surveillance.action.<action>`) ; les raisons texte du
  contrôle dual (`essai_demarre:…`, `essai_refuse:…` avec toutes les raisons de refus, `essai_interrompu:…`,
  `synthetique_impossible:…`), aussi par `texteRaisonDual(texte)`. Code inconnu : phrase générique
  (`texteRaisonKoachGenerique`), jamais le code.
- `nomExercice` : fonction `id → nom affiché` (base v1.1) ; elle rend `null` pour un identifiant inconnu (et non
  l'identifiant, comme `adaptExerciseName` aujourd'hui) ; sans nom, la phrase dit « cet exercice ».
- `texteQuestionKoach(code)`, `texteChoixKoach(question, choix)` : textes des questions (`cause`, `zone`,
  `intensite`, `seances_par_semaine`, `duree_max_min`) et de leurs choix (`Surveillance.questions`). Les objets de
  question portent aussi un `texte` (`rupture.dart`, `questionCause`…) ; utiliser ces fonctions pour un registre
  unique.
- Les semaines des raisons du contrôle dual sont l'indice `g` du moteur ; le texte affiche `g + 1`.
- Une ligne par raison, au plus deux à l'écran de séance : dédoublonner `explain()` (codes réémis à chaque série).
  Les raisons `plan.*` des items (écrites par `kalis_plan`) gardent les textes actuels (`reason_texts_0_4.dart`,
  `plan_texts.dart`).
- Les causes sans code (« pas de hausse sur douleur », « bilan bas », « borne de hausse », « part écrite »,
  « séries × 0,6 sur douleur ») ne sont que dans `trace` (contrat § 3.5), hors contrat : ne pas les afficher en
  production ; l'inspecteur peut montrer `trace` brute.

Test : `test/koach_textes_test.dart` (chaque raison des 10 fixtures `moteur_*.json` et des items servis, chaque
code du tableau du contrat, chaque cause, zones, groupes, techniques, questions, choix, actions réelles de
`repondre`, raisons du contrôle dual : phrase non vide, sans `koach.`, sans accolade, sans identifiant).

---

## 5. Comportement unique (cahier, « Comportement dans l'application »)

Un seul comportement pour tous : Koach propose, l'utilisateur valide d'un tap. Plus de mode « assisté » ni
« libre » (`GuidanceMode` : le champ du profil reste lu pour la compatibilité, sans effet), plus de choix
« garder le moteur d'avant » (`PlanProgram.keepLegacyEngine`).

### 5.1 À la séance : suggestion validée d'un tap

- L'écran montre, pour chaque série, la cible de `plan(serie)` (charge, plage, flammes) et **une ligne** de raison
  (`texteRaisonKoach` sur la première raison utile de `explain()`, sinon rien).
- **Suggestion** = changement de charge de la première série de travail d'un emplacement (même exercice, même
  `slotId` ; ni test, ni rampe, ni repère, ni tentative) par rapport à son dernier passage : la cible porte alors
  `proposition {type: charge_plus | charge_moins, depart, cible, pas, ampleur, paliers, moment, proba_min}`
  (`Koach._proposition`, `moteur.dart`, d'après le code). **Aucune baisse imposée par la sécurité** (douleur active,
  bilan bas, raison `koach.douleur_*`, `koach.reprise_*`, `koach.poignet_*`, `koach.zone_fragile`,
  `koach.retour_gradue`, `koach.surmenage` sur l'exercice) n'est présentée comme une suggestion : elle n'a pas de
  `proposition` et ne se refuse pas (la série est servie à la charge baissée). La charge servie (`loadKg`) reste la cible
  (anti-complaisance, cahier § 8) ; `proposition` règle la présentation : `paliers` (étapes jusqu'à la cible, la
  dernière = la cible) et `moment` (`debut_de_seance` : avant la première série ; `entre_series` : après
  l'échauffement ou la première série ; `prochaine_seance` : annoncé au récapitulatif de fin de séance).
- **Valider** (un tap) : la charge proposée est préremplie. **Refuser** : un tap, puis une raison facultative en
  un tap (trop lourd → `too_heavy`, trop léger → `too_light`, matériel → `equipment`, temps → `time`, autre →
  `other`) ; la charge précédente (`depart`) est préremplie et la série faite est versée telle qu'elle est.
- Décision versée après `seance_fin` (§ 2.2) : `{type: 'decision', jour, accepte, raison, proposition: {id,
  type, exerciseId, ampleur, charge_kg, reps, rir, contexte: {bilan_bas, semaine_allegement, moment,
  refus_recents}}}` avec `id` stable (par exemple `p<jour>-<exerciseId>-<n>`), `ampleur = |paliers[0] − depart| /
  pas de la grille` (`_AdherenceBanc._proposer`), `charge_kg` = charge proposée, `reps` = haut de la plage
  proposée, `rir` = réserve des flammes visées, `refus_recents` = `Adherence.refusRecents(jour)`. Un refus
  « trop lourd » / « trop léger » avec `charge_kg`, `reps` et `rir` devient en plus une mesure faible de capacité
  (D7) ; sans raison, il ne nourrit que l'adhérence.
- Un **vrai test** inséré (`koach: 'vrai_test'`) est aussi une suggestion : refusé, l'application passe à l'item
  de travail et verse `decision` de type `test`, `accepte: false`.
- Charge fixe (C15) : § 7.3.

### 5.2 Chaque lundi : replanification

- Le `semaine_fin` du lundi replanifie, hors du fil d'interface, de la semaine suivante jusqu'à l'échéance
  (§ 1.5). Seule la semaine à venir se montre : pour chaque journée de la semaine `g`, les séries servies et
  l'écart d'intensité se lisent dans `Planification.itemsModules(g)` (`(dayIndex, slotId) → (séries, écart)`) ;
  MON PROGRAMME et l'accueil affichent ces séries et « charge ±x % » sur les lignes changées, avec l'écrit en
  dessous. Les semaines suivantes restent affichées telles qu'écrites. Rien à valider (cahier).
- Ce que la séance sert vraiment vient de `plan(seance)` le jour même (la planification module les items écrits
  passés par l'application) : l'affichage de la semaine est une prévision.
- Une semaine verrouillée (intro, allègement, affûtage, test, compétition, transition) n'est ni chargée ni
  augmentée (`verrouillee`, `planification.dart`).

### 5.3 Récapitulatif de fin de bloc

- À la dernière séance d'un bloc (ou au lundi qui ouvre le suivant), l'écran « ce qui change et pourquoi » compare
  le bloc suivant modulé à sa référence : facteurs de volume par qualité (`plan[w]['volume']`, 10 qualités,
  libellés à écrire dans l'application) et intensité (`plan[w]['intensite']`), P(réussite) par cible
  (`historique.last['p_cibles']`, `objectif`) et sa valeur de référence (`p_cibles_reference`), une ligne
  `plan_garde` quand aucun plan meilleur n'a été retenu. Validé d'un tap.
- Programme créé : la structure du bloc suivant reste écrite par `kalis_plan` (`nextBlock`), qui demande un
  `AdaptationSummary` aujourd'hui calculé par `KalisAdapt.review` (0.3.1, `plan_store.dart`) : KM3 le construit
  depuis `koach.posterior()` (`ExerciseEstimate.capacity` = `valeur`, charge totale ; `standardError` depuis
  `intervalle_90` ; `observations` = `mesures`) et l'assiduité de l'application ; puis nouveau `reference`.
- Un refus du récapitulatif n'a pas d'équivalent dans le moteur (§ 10, question 3).

### 5.4 Hors modèle et diagnostic en 3 questions

- Après chaque `seance_fin`, `semaine_fin` et `seance_manquee`, `Surveillance.etat()` dit `hors_modele`, `causes`
  (`rupture`, `residu`, `assiduite`, `douleur`) et `p_rupture`.
- À l'ouverture de la séance suivante (après `seance_debut`, avant `plan`) : message « Cette situation sort de mon
  modèle » (`texteHorsModeleKoach`, plus la cause : `texteRaisonKoach({'code': cause})`), puis les questions de
  `Surveillance.questions(reponses)`, rappelée après chaque réponse (3 au plus) :

| Question (`code`) | Choix (`code`) | Suite |
| --- | --- | --- |
| `cause` | `douleur`, `moins_de_temps`, `fatigue`, `rien` | selon le choix |
| `zone` (si `douleur`) | les 13 zones `kalis_core` (`neck`, `shoulder`, `elbow`, `wrist_hand`, `upper_back`, `lower_back`, `chest`, `abdomen`, `hip`, `thigh`, `knee`, `lower_leg`, `ankle_foot`) | puis `intensite` |
| `intensite` | 0 à 10 | fin |
| `seances_par_semaine` (si `moins_de_temps`) | 1 à 7 | puis `duree_max_min` |
| `duree_max_min` | 20, 30, 45, 60, 75, 90 | fin |

- Réponse versée : `decision {jour, diagnostic: {cause, zone?, intensite?, seances_par_semaine?, duree_max_min?}}`
  (et non `repondre` directement : seul l'événement entre au journal). Une réponse sans alerte levée est ignorée.
  Action prise (`Surveillance.decision` → `repondre`, `rupture.dart`) :
  - `douleur` → douleur notée comme un signalement de fin de séance, conduite sous douleur, renvoi vers un
    professionnel (`conduite_douleur`) ;
  - `fatigue` → semaine allégée de 7 jours (séries × 0,6, 2 de réserve en plus) appliquée par `plan` ;
  - `rien` → incertitude élargie (× 4 sur les variances), BOCPD remise à zéro ;
  - `moins_de_temps` → action `replanifier` seulement : le moteur ne fait rien d'autre. L'application garde les
    disponibilités et passe `duree_max_min` en `contexte.budget` des séances suivantes (Koach borne alors la durée,
    `koach.seance_bornee`) ; le nombre de séances par semaine n'a pas d'effet possible sans changer la structure
    (§ 10, question 4).
- Texte de l'action : `texteRaisonKoach(action)` avec l'objet `{action, …}` lu dans
  `Surveillance.reponses.last['action']` complété des réponses (l'objet entier de `repondre` n'est pas gardé par
  l'extension ; l'application le reconstitue depuis les réponses, le contenu est fixe, contrat § 3.7.2).
- Chaque cause répondue se tait 2 semaines (`silence_semaines`).

### 5.5 Arrêt d'urgence

Koach n'en a pas (contrat § 10.2) : c'est un état de l'application, hors du journal.

- **Arrêter** (Réglages, une confirmation) : date de l'arrêt et semaine `g` gardées ; plus aucun événement versé au
  journal de Koach ; l'instance est relâchée. Les séances suivantes sont servies **telles qu'écrites** (le chemin
  « hors moteur » que l'application a déjà, `adaptOpen` → `null`), la semaine en cours avec les séries modulées
  déjà affichées (`itemsModules(g)` gardé en mémoire à l'arrêt) ; l'application journalise tout comme d'habitude.
  Rien n'est perdu ni réécrit.
- **Réactiver** : rejouer le journal gardé (§ 2.7), puis verser, dans l'ordre chronologique, tout ce qui s'est
  passé depuis l'arrêt et qui est dans le journal de l'application (séances, séries, douleurs, pesées, semaines,
  séances manquées), sans événement `plan` pour ces séances (elles n'ont pas été servies par Koach, comme dans
  `walk_forward.py`). La première séance après la réactivation est servie par Koach normalement.
- Pendant l'arrêt, les garde-fous de séance de Koach (conduite sous douleur, poignet, bilan bas) ne s'appliquent
  pas : l'écran d'arrêt le dit, et un signalement de douleur pendant l'arrêt garde l'avis de consulter
  (§ 10, question 5).

### 5.6 Mode dev (builds de dev seulement, `kDevBuild`, session de test)

- **Inspecteur** (remplace `engine_inspector.dart`) : séance du jour, items servis et écrits côte à côte, raisons
  (`explain()` : code, paramètres, texte), `trace` des cibles ; capacités (`posterior().exercices` : valeur,
  intervalle à 90 %, séances, mesures), qualités, biais et bruit de la note, fatigue ; planification
  (`historique.last` : valeur, référence, objectif, `p_cibles`, transport, plans évalués, `plan_garde`,
  `prevu_jour` ; modulation par semaine) ; surveillance (`etatComplet()` : p, causes, silence, `mj_suite`) ;
  contrôle dual (`etat()` : calibré, essai, raisons texte) ; adhérence (`etat()`, `contraintes()`) ; **temps de
  calcul réels** mesurés par l'application (`Stopwatch` autour de `observe`, `plan(serie)`, `plan(seance)`, de
  chaque replanification et du dernier rejeu complet) ; versions (`koachVersion`, paramètres, SHA-256).
- **Export du journal moteur** (remplace `shareEngineJournal`) : un JSON `{type: 'journal_moteur', version: 1,
  version_moteur, version_parametres, sha256_parametres, profil, extensions, principaux, journal, seances}`
  — `journal` : le journal de Koach complet ; `seances` : pour chaque séance versée, le bloc attendu par
  `walk_forward.rejouer` (`{cle, semaine (S, à partir de 1), jour, avant: [semaine_fin…], debut, series, meta:
  [{cat, ref, type}…], fin}`, avec `cat` = `test1rm` / `enduranceTest` / `strength` / `accessory` / … de
  `koach_program.json` pour le programme importé). C'est l'export que le critère 10 utilise (C13.11.3) : le
  pilotage le rejoue avec `walk_forward.py` sans fichier de correspondance. Il contient des données de santé
  (douleurs, bilan, poids) : partage par le menu système seulement, jamais versé au dépôt en clair (C13.6).
- **Export du dossier hors modèle** : `Surveillance.dossier(koach)` (JSON anonymisé : 60 derniers événements, clés
  identifiantes retirées, textes gardés seulement s'ils sont des codes ; `rupture.dart`).
- **Import du fichier de paramètres** : § 3.
- **Rejeu walk-forward** : sur le journal moteur, un portage Dart de la mesure A de `walk_forward.py` (série la
  plus informative, e1RM réalisé, intervalle à 90 %, erreur, couverture, biais) sur une instance **sans
  extension** qui ne reçoit que `seance_debut`, `serie`, `seance_fin`, `semaine_fin` ; la prévision se lit après
  `seance_debut` et avant les séries, sur les pistes déjà créées seulement (lire `modele.pistes[id]`, jamais
  `piste(id)`, qui en crée une et changerait l'ordre des pistes). Résultat : agrégats seulement (comme
  `walk_forward.agreger`). Un test de l'application compare ses agrégats à ceux de `walk_forward.py` sur un
  journal synthétique.

---

## 6. Retraits (cahier, « Retiré, gelé ou reporté »)

| Élément | Où dans l'application (`main`) | À faire |
| --- | --- | --- |
| Couche d'ajustements CI1c du programme importé | `SessionAdaptStore.syncImportedOverlay`, `_overlaySegment`, `_overlayWhy`, `DayPlan.overlay` / `original`, `Exercise.koach`, `_importedEvolved` | retirée : le programme affiché est l'écrit, plus la semaine à venir modulée (§ 5.2). Les journées d'origine sont déjà en dessous (`DayPlan.source`) : rien à migrer |
| Statut spécial du programme importé | `AdaptPlace.imported`, `importedEndEvent` / `_withImportedEvent`, `planImportedNextBlockOffered`, `_proposeAfterImported`, `adaptSeasonOf` | retiré : le programme importé est une `reference` comme une autre (D2). `ImportedProgram` (annotation CI1e) reste : il fournit les blocs et `fixedLoad` |
| Option d'adaptation de la structure | `KalisAdapt(restructureImported:)` (0.3.1), niveaux de déblocage (`UnlockLevel`, `ka.unlockLevelFor` dans `evolution_store.dart`, `kUnlockCan` de l'inspecteur), ancien drapeau `KoachData.structure` (L7, en lecture seule) | retirée de l'interface ; le drapeau reste lu et réécrit à l'identique (sauvegarde stable). La structure ne change qu'à la frontière de bloc, par `kalis_plan` (§ 8, point 1) |
| Code de décision de `kalis_adapt` 0.x | `kalisAdaptEngine` (`session_adapt_store.dart`), `prescribeSession`, `adviseNextSet`, `review`, `estimates`, `applyProposal` (`plan_evolution.dart`), `EvolutionStore` (propositions de 0.x), `SessionAdapt.advice` (conseils entre séries), `dev_simulator.dart` (simulateur 0.x) | remplacé par Koach ; les données écrites restent lisibles (§ 7.2) |
| Série AMRAP toutes les 4 semaines, filtre des séries selon le RIR | dans 0.3.1 (séries repères, `adapt.benchmark_set`, filtre de capacité) | partent avec le code 0.x ; Koach sert ses séries repères et son vrai test. Vérifier que l'application n'applique pas d'elle-même `autoregulation` (`stop_at_rir`, `backoff_from_top_set`) des items : Koach donne la cible de chaque série |
| Modes coexistants | `GuidanceMode` (assisté, libre ; `adaptMode`, statuts `applied` / `pending`), `keepLegacyEngine` | un seul comportement (§ 5) |

---

## 7. Migration du programme de 40 semaines

### 7.1 Plan initial (D2)

- Au moment où Koach prend la main (§ 7.4), l'application :
  1. fait la sauvegarde complète d'origine si elle n'existe pas (`program_origin.dart`, C11.2) ;
  2. construit le profil de Koach (instantané gardé, § 2.7) : pour le programme importé, les règles de
     `journal_app.profil_de` (correspondance de référence, celle que le critère 10 mesure) : `niveau` =
     `experience` (`beginner` … `elite` → 0 … 3, 2 à défaut), `sexe`, `poids_kg` (profil, sinon première
     pesée), `zones_fragiles` (zones des `limitations` ; objets `{zone, since, discomfort}` permis, contrat § 2.5),
     `declares` = valeurs de référence **initiales** (`koach.history`, source `initial`) : 1RM des `mainLifts` sur
     les lignes `strength` / `test1rm`, maxima des `repMax` sur les lignes `endurance` / `enduranceTest`,
     accessoires convertis en 1RM par la courbe de population à la réserve cible (écart-type 0,12,
     `declares_initiaux`). Sans programme importé : `_pkProfilKoach` (niveaux de mouvement connus du profil :
     moyenne géométrique de `low` et `high`) ;
  3. verse **tout l'historique déjà fait** (séances du programme terminées depuis S1, dans l'ordre de
     `finishedAt`), converti au § 2.3 : `semaine_fin` de chaque lundi passé, `seance_debut` (bilan, pesée,
     contexte), `serie`, `seance_fin`, sans événement `plan` (ces séances n'ont pas été servies par Koach) et sans
     décision ;
  4. verse `reference` (§ 2.6) avec `semaine` = `g` de la semaine de bascule : une seule replanification, de cette
     semaine jusqu'à l'échéance. Verser l'historique **avant** `reference` évite une replanification par semaine
     passée (sans référence, `replanifier` rend tout de suite une ligne vide, d'après le code).
- L'historique passe par la surveillance : une alerte peut se lever dès l'activation (assiduité des deux dernières
  semaines, douleur récente). C'est voulu : le diagnostic sera posé à la première séance.

### 7.2 Ce qui se passe de l'historique déjà fait

- Les séances faites et les séries validées ne sont jamais réécrites (C11.2) : Koach les lit, il ne les change pas.
- `SessionLog.adapt` des séances passées (prescriptions et conseils de 0.x), `koach.decisions`, `planEvolution`
  (propositions et décisions de 0.x, ajustements acceptés CI1c) restent dans la sauvegarde, lus et réécrits à
  l'identique, en lecture seule (comme les données de L7 depuis G10). Ils ne sont pas versés à Koach : les types
  de proposition de 0.x ne sont pas ceux de l'adhérence, et un ajustement de 0.x accepté n'est plus en vigueur
  (D2 : le plan repart de la référence). L'historique de l'écran Évolution les montre, datés.
- Séance commencée au moment de la mise à jour : finie avec sa prescription 0.x telle qu'elle est (séries
  validées gardées) ; versée à Koach à sa fin, sans `plan`.
- « Revenir à mon programme d'origine » reste (C11.2) : sections du programme rendues à l'identique, puis nouveau
  `reference` ; le journal de Koach n'est pas effacé.
- Test de migration (prompt KM3) : une sauvegarde réelle simulée au format de dev6.11.2 (programme de 40 semaines
  commencé, séances faites avec 0.x, ajustements CI1c acceptés, décisions) → mise à jour → aucune séance ni série
  changée, sauvegarde d'origine présente, journal de Koach rejouable, retour au programme d'origine possible.

### 7.3 Charge fixe (C15), au-dessus de Koach

- Les lignes `load.type == 'fixed'` du programme de 40 semaines (`ImportedProgram.fixedLoad`, « semaine|emplacement »
  → (exercice, kg), `importedFixedLoadKg`, sauf « … lesté ou PdC ») restent servies à leur charge écrite. CI1h le
  fait aujourd'hui sur la sortie de 0.3.1 (`_fixedConstrain`, `fixedLoadItem`, `fixedLoadAdvice`,
  `adapt/session_adapt.dart`) ; avec Koach, la contrainte s'applique à la cible de `plan(serie)` : `loadKg` ←
  charge écrite, plage plafonnée au haut de la ligne écrite, pour toute série et pour toute prévision.
- La sécurité prime (C15.2) : sous conduite de douleur, la charge peut descendre sous l'écrit. Koach ne dit pas
  par un code qu'une charge plus basse vient de la douleur (les causes « pas de hausse sur douleur » n'ont pas de
  code, contrat § 3.5) : garder la cible de Koach quand elle est plus basse **et** qu'une zone sollicitée par
  l'exercice est active (`koach.garde.actives()` croisé avec les zones provoquées de l'exercice), ou qu'une raison
  `koach.douleur_*`, `koach.reprise_dose`, `koach.poignet_*` vise l'exercice ; sinon la charge écrite. Un item
  retiré par Koach reste retiré.
- Ce qui est versé : la série telle qu'elle a été faite, à sa charge réelle (Koach apprend de la charge fixe). La
  planification ne connaît pas la contrainte : son écart d'intensité sur ces lignes n'est pas servi (§ 8,
  point 7).
- Prévision de fin de séance et séance future ouverte en avance (C15.4) : un seul calcul, mais `plan` n'est pas
  un aperçu (§ 1.4). La prévision se calcule sur une **copie** (rejeu du journal dans une instance à part, ou
  instance de prévision tenue à jour en arrière-plan) avec un `seance_debut` à la date prévue, puis `plan(seance)`
  et `plan(serie)` index 0 ; la séance du jour venu est prescrite sur l'instance vive. L'écran dit que c'est une
  prévision recalculée le jour venu (C15.4) ; les tests de CI1h (`test/ci1h_charge_fixe_test.dart`) sont repris
  sur ce calcul.

### 7.4 Bascule

- Koach prend les commandes au début d'un bloc du programme du propriétaire, si tous les critères du cahier sont
  passés : 23/11/2026 (S20, début du bloc force max) si l'APK est installé au plus tard le 16/11/2026, sinon
  04/01/2027. La date de bascule est une donnée de l'application (réglable en mode dev pour la session de test).
- Avant la bascule, le bloc en cours n'est pas coupé (prompt KM3) ; ce qui sert les séances d'ici là est à
  trancher (§ 10, question 1). L'export « journal moteur » doit fonctionner **avant** la bascule (critère 10) : il
  se construit depuis l'historique (§ 7.1, étapes 2 et 3) sans instance vivante.

---

## 8. Points de vigilance et limites héritées

1. **Structure jamais modifiée** (contrat § 10.1, A.1 n° 7). Koach module séries et charges et peut retirer une
   ligne (douleur, retour gradué, durée bornée) ; il ne change ni exercices, ni jours, ni schémas, ni ordre. Le
   cahier (« structure modifiable aux frontières de bloc ») n'est tenu que par `kalis_plan` pour un programme créé ;
   pour le programme de 40 semaines, la structure reste celle de l'écrit.
2. **M5 : intervalle presque jamais sous 6 %.** Le contrôle dual ne se calibre pratiquement jamais : tirage de
   Thompson et essais N-of-1 restent inactifs ; le vrai test revient tous les 14 jours (5 après une montée arrêtée
   loin de l'échec) sur les mouvements principaux et secondaires chargés. L'écran doit le présenter comme un test
   court, refusable (§ 5.1).
3. **M8 : le « résidu d'e1RM » du secours n'est pas un résidu** (déplacement de la capacité du jour pendant la
   séance) : la cause `residu` se lève très rarement. Ne pas promettre à l'utilisateur une alerte sur un écart de
   5 %.
4. **Rejeu exact** : il dépend de tout ce qui est hors journal — fichier de paramètres initial, fiches, profil de
   Koach, liste et ordre des extensions, `liftsPrincipaux`, entrées du validateur. Les garder en instantané avec le
   journal (§ 2.7) ; un profil modifié ensuite (gêne, poids, niveau) ne change pas l'instantané : le poids passe
   par `poids`, la douleur par le journal ; une nouvelle gêne déclarée au profil n'atteint Koach qu'au prochain
   `reference` (§ 10, question 2).
5. **Critère 10 avant la bascule** (cahier, C13.10.2 d, C13.11.3) : rejeu walk-forward du journal du propriétaire
   depuis S12, au moins 100 séries notées, erreur d'e1RM sous 3 %, couverture 88 à 92 %, biais sous 2 % en valeur
   absolue, sur l'export « journal moteur » (§ 5.6). KM3 livre l'export et vérifie sur un journal synthétique que
   `walk_forward.rejouer` le lit ; la mesure est faite par le pilotage. Pour que le critère soit mesurable, chaque
   série doit être notée (C13.10.5) : la note reste demandée à chaque validation.
6. **Critère 1** : écart documenté (3,6 à 3,8 % de plancher du banc, C13.11.1) ; ne doit pas reculer.
7. **Charge fixe hors du jumeau** : la planification croit servir l'écart d'intensité sur les lignes à charge
   fixe ; l'application ne le sert pas. P(réussite) de ces cibles est donc un peu optimiste.
8. **Mini-séries, `parts`** non lues : une série à mini-séries (myo-reps, cluster, rest-pause) est lue comme une
   série d'une traite de `reps` répétitions.
9. **Séries sans note** : versées seulement si la prévision les contredit (A.1 n° 1) ; une note ouverte (« 4 et
   plus ») n'est versée que près de la prévision. Normal : ne pas compenser côté application.
10. **72 kg par défaut** sans poids (m14) : exiger un poids au profil ou une pesée avant l'activation.
11. **`jours_avant_echeance`** jamais passé au banc (A.3 n° 28) : le passer active une règle de sécurité non
    mesurée au banc (§ 10, question 7).
12. **Import partiel** : un import de paramètres ne change ni la planification ni le contrôle dual (contrat § 7.3) ;
    `porte_note_ouverte` est bornée à 3 par la validation du portage Dart (`bornes`, `rupture.dart`, d'après le
    code ; le contrat de référence disait 100).
13. **Doublons de raisons** : `explain()` répète les raisons de `cible` à chaque série (A.3 n° 24).
14. **Temps** : une replanification bloque `observe` ; un rejeu complet en refait autant qu'il y a de semaines
    (§ 1.5).
15. **Permissions** : aucune permission INTERNET (manifeste vérifié) ; l'import de paramètres et les exports passent
    par le sélecteur et le partage du système.

---

## 9. Liste de contrôle KM3

- [ ] `packages/kalis_adapt` = la dernière étiquette **validée** de `kalis_adapt` (1.0.3 si le lot KR1 est validé, sinon 1.0.2) à l'octet ;
      `kalis_bench` absent ; `kalis_core` 0.4.3, `kalis_plan` 0.3.1 inchangés (`kalis_plan` 0.4.1 entre par le lot court
      de KS1 ; le couple `kalis_plan` 0.4.1 × Koach est celui que mesure KR1).
- [ ] Assets `assets/koach/koach_params_1_0_4.json` et `vecteurs_qualites_v1.json` copiés, déclarés, SHA-256
      vérifiés par un test ; lus par `lireParametresKoach` / `lireFichesKoach`.
- [ ] Construction : `Koach` + `Planification` (validateur `validateurSecurite` + `ProfilValidation.depuisProfil`),
      `Surveillance`, `ControleDual`, `Adherence`, dans cet ordre ; même ordre pour `rejouer`.
- [ ] Échelles : `jour` depuis le lundi de S1, `g = S − 1`, `jour_index` = `dayIndex` écrit, `semaine_fin` au
      format du banc.
- [ ] Journal : tous les événements du § 2.3 ; contexte complet (§ 2.4) ; objet `serie` du § 2.5 (`failed` =
      mesure 0, `target.flames` = note préremplie, pas de série écartée) ; décisions après `seance_fin`.
- [ ] `plan` appelé une fois par séance et une fois par série, jamais pour un aperçu ; cibles gardées.
- [ ] `reference` à l'activation et à chaque changement de référence ; `cibles` aux changements de buts.
- [ ] Journal persisté dans la sauvegarde avec ses instantanés ; rejeu exact testé (JSON aller-retour, états des
      extensions identiques) ; correction d'une saisie passée → remplacement et rejeu.
- [ ] Replanification et rejeu hors du fil d'interface ; temps mesurés sur émulateur (replanification ≤ 10 s,
      série ≤ 50 ms) et affichés dans l'inspecteur.
- [ ] Textes : `texteRaisonKoach` partout où une raison s'affiche ; aucun code brut (test d'interface sur les 22
      codes et les codes des extensions) ; questions et choix par `texteQuestionKoach` / `texteChoixKoach`.
- [ ] Suggestion à la séance validée d'un tap ; refus avec raison facultative (cinq choix) ; décision versée.
- [ ] Lundi : semaine à venir modulée affichée (`itemsModules`) ; semaines suivantes telles qu'écrites.
- [ ] Récapitulatif de fin de bloc validé d'un tap ; `AdaptationSummary` de `nextBlock` construit depuis
      `posterior()`.
- [ ] Hors modèle : message, 3 questions au plus, réponse en `decision`, action affichée ; `budget` des
      disponibilités.
- [ ] Arrêt d'urgence : plan figé, rien perdu ; réactivation par rejeu et rattrapage.
- [ ] Mode dev (absent de l'AAB) : inspecteur, export du journal moteur (format du § 5.6, lu par
      `walk_forward.rejouer`), dossier hors modèle, import de paramètres, rejeu walk-forward.
- [ ] Retraits du § 6 ; données 0.x et CI1c gardées en lecture seule ; migration d'une sauvegarde de dev6.11.2
      testée sans perte ; « Revenir à mon programme d'origine » testé.
- [ ] Charge fixe C15 au-dessus de Koach, prévision par le même calcul sur une copie ; tests de CI1h repris.
- [ ] Bascule datée (23/11/2026 ou 04/01/2027) ; avant, bloc en cours non coupé ; export « journal moteur »
      disponible avant la bascule.
- [ ] Manifeste sans INTERNET ; installation par-dessus sans perte ; signature intouchée.

---

## 10. Questions que KM3 doit trancher (ou faire trancher par le pilotage)

1. **Avant la bascule**, qui sert le bloc en cours ? (a) 0.3.1 encore, jusqu'à la date (deux moteurs dans l'APK
   pendant au plus une semaine, ou sept si la bascule glisse au 04/01/2027) ; (b) le programme tel qu'écrit, hors
   moteur, avec la charge fixe. (b) respecte D1 mais retire d'ici là les garde-fous de séance de 0.3.1.
2. **Profil de Koach hors journal** : une gêne ajoutée au profil, un niveau changé, n'atteignent pas Koach (le
   profil est figé pour le rejeu). Verser un `reference` (même blocs) avec un profil nouveau ne suffit pas : le
   profil est un argument du constructeur. Accepter la limite, ou ajouter un événement au paquet dans un lot
   moteur ?
3. **Refus du récapitulatif de fin de bloc** : servir la référence non modulée pour ce bloc (et comment le dire au
   moteur, qui replanifiera le lundi suivant), ou seulement noter le refus ?
4. **« Moins de temps »** : `duree_max_min` passe par `budget` ; `seances_par_semaine` sous l'écrit n'a pas d'effet
   sans changer la structure. Proposer à l'utilisateur quelles journées sauter (versées en `seance_manquee`) ?
5. **Arrêt d'urgence** : garder les garde-fous de séance pendant l'arrêt (servir par Koach sans planification
   demanderait de ne pas passer `contexte.semaine`, ce qui coupe aussi le retour gradué) ou servir l'écrit (§ 5.5) ?
6. **Crans d'élastique** : l'application ne garde pas de cran par exercice assisté. Ajouter le champ (et le
   versement `cran`), ou laisser Koach sans cette information ?
7. **`jours_avant_echeance`** : le passer (règle A6.5 de 0.3.1 active) ou rester comme au banc ?
8. **Corrections a posteriori** : remplacement de l'événement et rejeu (§ 2.7), ou journal en ajout seul (la
   correction ne compte plus pour Koach) ?
9. **Séances libres** (`S0-…`) : ignorées comme dans `journal_app.py`, ou versées (mesures utiles, sans contexte de
   semaine) ? Le critère 10 a été défini sans elles.
10. **Échéance du programme importé** : jour de test de S40 (recommandé) ou fin de S40 (`importedEndEvent`
    aujourd'hui) ; et `cibles` : `mainLifts.target` du programme ou objectifs du profil quand les deux existent ?
11. **Données 0.x** : afficher l'historique de l'écran Évolution tel quel, ou le replier dans un écran « Avant
    Koach 1.0 » ?
