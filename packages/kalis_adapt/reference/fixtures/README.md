# Fixtures de parité Koach 1.0 (format 2)

Générées par `python3 fixtures/generer.py` (depuis `packages/kalis_adapt/reference/`),
vérifiées par `python3 fixtures/generer.py --verifier` et `tests/test_fixtures.py`.
Ne jamais les retoucher à la main : le moteur ou `params/koach_params_v1.json`
changent, on relance la commande (unique, déterministe, ~5 s).

## Codage

JSON compact, clés triées, UTF-8. Flottants en `repr` Python (le plus court qui
relit le même double : sans perte). Non-finis des sorties : chaînes `"inf"`,
`"-inf"`, `"nan"`. Les entrées versées au moteur sont du JSON pur.
Comparaison du portage : nombres à `|a - b| <= 1e-9 · max(1, |a|, |b|)`, le reste
à l'identique. En Python, le test exige l'identité stricte.

## En-tête (toutes les fixtures)

`format`, `nature` (`numerique`, `moteur`, `planification`), `version_format`,
`version_moteur`, `titre`, `version_parametres`, `sha256_parametres` (SHA-256 du
texte canonique de `entrees.params`), `sha256_fichier_parametres` (octets du
fichier de paramètres), `tolerance`, `comparaison`, `codage`, `commande`.

## `moteur_<n>.json`

* `source` : saison du banc (profil, scénario, vérité, graine, semaines, champs
  de fiche remplacés, retouches : `bilan_bas_seances`, `bilan_bas_tests`,
  `techniques_substituees`, `parametres_apres_semaine`).
* `couverture` : compteurs des événements du journal, des raisons `explain()`
  après chaque `plan` (par code et par cause), genres de semaine, nombre
  d'événements avec douleur, zones fragiles du profil.
* `entrees` : `params`, `fiches` (celles que le moteur lit), `profil`,
  `journal` (= `Koach.journal` : événements `observe`, dont `parametres`, et
  appels `plan` sous forme canonique `{'type': 'plan', 'contraintes': ...}` ;
  grilles `{pas, minimum, halteres}`, zones `[niveaux, zones triées]`).
* `attendu.plans` : `{indice, sortie, raisons}` pour chaque événement `plan`
  (indice dans le journal) ; `attendu.instantanes` : `{indice, posterior[,
  diagnostic]}` après l'événement d'indice donné (fins de séance et de
  semaine ; après chaque série pour `moteur_1`) ; `attendu.final` : état
  après tout le journal.

Rejeu :

    k = Koach(params, fiches, profil)
    pour i, e dans journal :
      e.type == 'plan' : sortie = k.plan(e.contraintes) == plans[i].sortie ;
                         k.explain() == plans[i].raisons
      sinon            : k.observe(e)
      si i dans instantanes : k.posterior() == instantanes[i].posterior
    k.journal == journal ; état final == attendu.final
    rejouer(params, fiches, profil, journal) redonne le même état.

## `planification_<n>.json`

`entrees` comme ci-dessus (journal sans instantanés), `planification`
(options dont `sans_validateur: true`, semaine, plan de référence réduit) et
`attendu` (posterior avant/après, tirages, tirages intermédiaires `moyennes`,
`S`, `L` = `cholesky_semi(S)`, `z`, tables, évaluation de la référence, ligne
de replanification, plan, items modulés).

## `numerique.json`

Cas entrée → sortie de `koach/numerique.py` (voir `notes` dans le fichier),
dont `cholesky_semi` (matrices définies, de rang déficient, nulles) et
`arrondi`.
