# Livraison KM2c2 — KM2 correction 2 : Koach 1.0.3 en Dart (`kalis_adapt` 1.0.2)

Lot KM2c2 du pipeline CP (méthode Koach, `CAHIER_KM.md`, décisions C13.13.2, C17.13), voie A, session Opus 5.5
effort maximal, le 16/10/2026 (04:12 → @FIN@ UTC). Prompt : `prompts/KM2c2.txt` ; contexte : `LANCEMENTS.md`,
section KM2c2. Lot sans panel ni relecture documentée (C13.3) ; validation automatique par le pilotage.

**En une phrase** : le delta de méthode de la référence Koach 1.0.3 (KM1c3 : fiabilité des notes, prudence ciblée
aux tentatives, barre suivante après un échec hors compétition, règle de 0.3.1 après un échec non prévu) est porté en
Dart à l'identique — parité sur les 15 fixtures de la référence et sur 3 fixtures complémentaires (branches du delta
qu'aucune fixture n'exécutait), traces comprises ; la campagne Dart sur six graines (4 320 saisons, Koach complet) et
les six jeux d'adversaires redonnent exactement les chiffres de la référence Python ; 0 violation ; API inchangée
(`posterior()` gagne `fiabilite`).

## 1. Livré

| Paquet | Version | Étiquette | Contenu |
| --- | --- | --- | --- |
| `kalis_adapt` | 1.0.2 | `etiquettes/kalis_adapt-v1.0.2` | Koach 1.0.3 (`lib/src/koach/`), asset `assets/koach/koach_params_1_0_3.json` (`1.0.3-ref.1`, 338 clés, SHA-256 `d129a4e9…1aa0`), `CONTRAT.md` § K, `CHANGELOG.md`, `docs/INTEGRATION_KM3.md` (mise à jour du 16/10, § 3, § 9) |
| `kalis_bench` | 0.5.1 | `etiquettes/kalis_bench-v0.5.1` | saisons figées (`--saisons-figees`, `KmBanc.saisonsFigees`) pour mesurer la parité sur les saisons que lit Python ; fixtures `test/fixtures/km2/` régénérées (1.0.3) ; `docs/CRITERES_KM2C2.md`, données `docs/data/km2c2/` |

`kalis_core` et `kalis_plan` inchangés ; rien dans l'application. `moteurs` : @COMMIT@. Référence Python
(`kalis_adapt/reference/koach/`, paramètres, fixtures) non modifiée ; seuls `reference/README.md` et
`reference/PORTAGE_DART.md` (note « fait en KM2c2 ») changent, et les copies figées de 1.0.2 (`reference/fix_dart/`,
`reference/params/koach_params_d2.json`) sont supprimées.

### 1.1 Delta porté (`reference/CHANGEMENTS_1_0_3.md`, sections A à D et H)

- `modele.dart` : classe `Fiabilite` (grille sur ln φ, normalisation `max + ln Σ exp`, oubli λ, vraisemblance de la
  catégorie de la note avec la queue lourde du filtre et le mélange aberrante / paresseuse, comptes Beta des séries
  non notées, grilles par schéma, κ plafonné, `resume`) ; appels dans `_serieForce` (séries de force faites, hors
  échauffement et échec, après la sonde et avant la porte des séries sans note ; série lourde selon `repsHigh`) ;
  `elargissement()` ; κ appliqué à `capacite` et `capaciteDuJour` sauf `brut`.
- `planification.dart` : `tirer`, lignes puis colonnes des E capacités de S multipliées par κ avant Cholesky.
- `seance.dart` : `probaReussite(…, brut)` ; `_tentative` sur σ brut, barre suivante après un échec hors semaine de
  compétition (au plus `tentative_echec_baisse_part` sous la barre ratée, cran ramené au-dessus, jamais au-dessus de
  la barre ratée ; en compétition : la même barre) ; `_palierBarres` (palier × g, marge) ; `_cibleCharge` (prudence
  des séries lourdes) ; `_bornesHausse` (`echec_sans_hausse_tout_schema`) ; `_rampe` sur σ brut.
- `rupture.dart` : `defaut_modele_sd` ∈ [0,001 ; 0,1], six bornes nouvelles, cinq clés figées, `appliquerParametres`
  repointe `modele.fiabilite.p`. `moteur.dart` : `posterior()['fiabilite']`. Versions `1.0.3-ref.1`.

### 1.2 Tests (`kalis_adapt` : 343 tests verts ; `kalis_bench` km2 : 104)

- Parité (`test/koach_parite_test.dart`) : `numerique`, `moteur_1` à `moteur_12` (dont `moteur_12` : notes peu
  fiables, κ jusqu'à 1,4), `planification_1` et `_2`, à 1e-9, traces comprises.
- **Fixtures complémentaires** (`test/fixtures/km2c2/`, `generer_km2c2.py`, produites par la référence Python sans la
  modifier) pour les branches du delta qu'aucune des 15 fixtures n'exécute (relecture, M1) : `moteur_12_echec.json`
  (deuxième tentative du test 1RM ratée hors compétition : barre suivante 38,75 kg au lieu de 46,25),
  `moteur_12_echec_competition.json` (même échec en semaine de compétition : même barre 43,75), journal muté
  cohérent (série ratée, troisième barre faite à la charge servie, récapitulatif de séance à l'avenant) ;
  `planification_kappa.json` (replanification d'un athlète aux notes peu fiables, κ = 1,23 : S ← D S D).
- `test/koach_fiabilite_test.dart` (portage des tests de la référence qui ne remplacent pas `elargissement` : a
  priori et grille, notes justes et fausses, note ouverte contredite, oubli, note paresseuse, Beta, formule et plafond
  de κ, résumé, P(φ ≥ 2) au point de grille, moyenne intacte et incertitude élargie, échauffements et échecs exclus,
  φ contre le bruit de population, schéma selon `repsHigh`, `posterior`, import qui relit l'oubli et les
  coefficients) ; `koach_parametres_test.dart` : SHA, 338 clés, bornes et clés figées de 1.0.3.
- Façade, textes, propriétés, validateur : repointés vers `reference/fixtures/` et `reference/params/koach_params_v1.json`.
- `kalis_bench` : fixtures `km2` régénérées (`generer_banc_km2.py --verifier` à jour), évaluation de `adv-7ee0da71`
  (1.0.3), test des saisons figées.
- Référence Python : 261 tests verts (local, inchangés).

## 2. Mesures (`kalis_bench` `docs/CRITERES_KM2C2.md`)

**Saisons figées.** Depuis `kalis_plan` 0.4.0 (KS1), la saison vivante du banc n'est plus celle que lit la référence
(figée sur 0.3.1). Une première campagne Dart sur les saisons vivantes divergeait de la référence (12 adversaires de
`autres_03_powerlifter_competition` et les prévisions de la planification dès la première semaine, κ = 1 : sans
rapport avec le delta porté). La parité est donc mesurée sur les saisons figées et le témoin relu
(`--saisons-figees`, `--temoin`), comme la référence Python.

Campagne Dart, graines 0 à 5, 4 320 saisons, 0 plantée, déterminisme vérifié (run 38853167917) : **critères 1 à 4, 6
et 7, critères secondaires et bilan identiques à ceux de la référence Python** (`criteres_km1c3.json`) ; critère 5 :
`calibration_grappes` sur les saisons Dart **identique champ pour champ** à `calibration_grappes_km1c3.json`.

| Critère | Seuil | Koach 1.0.2 Dart (KM2c1) | Koach 1.0.3 Dart (KM2c2) = Python (KM1c3) |
| --- | --- | --- | --- |
| 1 erreur d'e1RM au rang 6 | < 3 % (écart accepté, C13.11.1) | 3,92 % | 3,94 % |
| 2 mauvais jour isolé | < 1 % | 0,91 % | 0,87 % |
| 3 convergence sous 3 % | ≤ 11,98 séances | 5,28 | 5,28 |
| 4 couverture à 90 % | 88-92 % | 89,96 % | 90,21 % |
| 5 calibration (C13.13.1, lecture C17.13.2) | biais ± 5 points ; écart max < q90 d'un modèle parfait | +0,2 ; 16,8 | −0,6 ; 24,4 contre q90 32,8 : **tenu** |
| 6 jour J | ≥ 0,9324 | 0,9450 | 0,9449 |
| 7 pire cas adversarial | ≥ témoin (0) | 0,499 | 0,450 (jeu b600) ; 0,555 (recherche de KM1c3) |
| 7 bis apparié | ≥ 90 % ; aucun sous − 0,10 | 24, 23, 22, 20 ; 17 sur 24 | 24, 22, 22, 21, 22 sur 24 ; recherche de KM1c3 19/24 (identiques à Python) |
| 8 sécurité | 0 | 0 | 0 |
| 9 parité | 1e-9 | 14 fixtures | 15 + 3 fixtures ; campagne et adversaires identiques à Python |
| 10 rejeu du journal | avant la bascule | — | — (C13.11.3, export neuf) |
| 11 temps (VM Dart) | ≤ 10 s ; ≤ 50 ms | 0,127 s ; 12,7 ms | 0,335 s ; 9,7 ms |

Critère 7 bis (six jeux, Koach sans extension, témoin relu) : KM1 24/24 (pire écart −0,018) ; b300 22/24 (1 sous le
plancher) ; complet b600 22/24 (1) ; b3000 21/24 (1) ; recherche de KM1c2 22/24 (1) ; recherche de KM1c3 contre 1.0.3
19/24 (2 non excusés). Mêmes cas que la référence (accepté comme tenue du point C13.13.2, C17.13.1).

## 3. Relecture indépendante (sous-agent Opus, deux passes)

- **Portage** : aucun écart bloquant ni majeur ; chaque changement de la référence vérifié ligne à ligne (ordre des
  opérations, défauts des clés, conditions, types, moment d'initialisation, absence de copie ou de sérialisation du
  modèle).
- **M1 (couverture, traité)** : branches du delta jamais exécutées par les 15 fixtures (barre après un échec hors
  compétition, jumeau avec κ ≠ 1, `probaReussite(brut)`, plafonnement par `_bornesHausse`, cas extrêmes de
  `_palierBarres`) → trois fixtures complémentaires (§ 1.2) ; les autres branches sont exercées par la campagne et les
  adversaires, identiques à la référence (le plafonnement `_bornesHausse` touche 30 séries sur le seul jeu b600).
- Mineurs traités : documentation (`CONTRAT.md` K, `INTEGRATION_KM3.md`, `CHANGELOG.md`), types des sous-dictionnaires
  de `resume()`, journal muté cohérent, liste des scénarios de la matrice tirée du fichier figé avec
  `--saisons-figees`. Laissés, sans effet : paramètres invalides (clé à `null`, `fiabilite_phi_points` = 1, booléen
  pour `echec_sans_hausse_tout_schema`) que la validation d'import et le fichier livré excluent ; `blocksAs` retiré
  des saisons figées côté Dart (aucun lecteur).

## 4. Contrôle

Contrôle complet sur `claude/ci-cp-a`, run @RUN@ (commit @CTRL@, arbre identique à `moteurs` @COMMIT@) : @RESULTAT@.
Mise au point : commits « KM2c2 contrôle (dev) » à arbre réduit (runs 38850637325, 38851049094, 38853167917,
38855046973, @DEVRUN@) ; workflow de mise au point propre à ces commits (formatage rendu en patch, campagne en quatre
parts parallèles), jamais sur `moteurs`.

## 5. Limites et suites

- Pas de SDK Dart dans la session (téléchargements refusés par le proxy) : compilation, formatage, tests et campagnes
  faits en CI.
- **Saison vivante ≠ saison figée** depuis KS1 : la campagne Dart sur `kalis_plan` 0.4.x mesure un autre couple que la
  référence. Régénérer les données de référence de Koach (`reference/donnees/reference/`, témoin) sur `kalis_plan`
  0.4.x (après KS1c1) est le lot suivant annoncé par le prompt ; d'ici là, comparer Dart et Python avec
  `--saisons-figees`.
- `fixtures/generer.py` : `tirage_intermediaire` (aide au portage, non lue par les tests Dart) n'applique pas κ ; sans
  effet sur les 15 fixtures (κ = 1 dans les deux planifications) ; le générateur de KM2c2 en a une variante.
- Critère 1 en écart accepté (C13.11.1) ; critère 7 bis : indicateur suivi (C17.13.1) ; critère 10 juste avant la
  bascule sur un export neuf (C13.11.3).
- KM3 peut monter de `kalis_adapt` 1.0.0/1.0.1 à 1.0.2 sans changement de code d'intégration (asset de paramètres à
  remplacer, `docs/INTEGRATION_KM3.md`).
- **Recommandation au pilotage** : valider KM2c2 comme portage de Koach 1.0.3 ; la version à intégrer par KM3 (et à
  basculer) est `kalis_adapt` 1.0.2.
