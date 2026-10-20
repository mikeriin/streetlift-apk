# Sauvegarde KM4 (Koach 1.0.6)

Session Opus 5.5 (19/10/2026, depuis 11:04 UTC). Base : `moteurs` 9c81a201.

## Fait
- Référence Python 1.0.6 : `koach/seance.py` (`prescrire` en deux passes, `_budgets_retour` sans réserve des groupes, `_plan_retour` réparti/priorisé, `_retour_gradue` sur le plan, `_douleur_unite`, `semaines_manquees`) ; paramètres `1.0.6-ref.1` (`retour_plancher_principal` 0,5, `retour_repartition_semaines` 4, `elargissement_rien_de_special` retirée) ; `koach/__init__.py`, `koach/rupture.py`.
- Banc Python : `items_volume(items, roles)` (rôle dans reste_semaine), `mesure_rampe` (critère KM4), `campagne.py` (`rampe`), `securite_campagne.py` (`rampe_principaux`).
- Tests : `tests/test_km4_retour.py` (11 verts).
- Échantillon local (34 profils × 9 scénarios × vérité b × graine 0, --rapide) : 1.0.5 : critère 7 = 0, principal retiré par la rampe 792 (657 séances), 5,3 % des séances avec principal réduit, part servie 6,5 %.

- Portage Dart : seance.dart (plan, BudgetsRetour, _UniteRetour), parametres (1.0.6, asset koach_params_1_0_6.json SHA 55a423cd…1dbe8, 346 clés), rupture (clé retirée), textes (« au lieu de N »), tests Dart (koach_km4_retour_test.dart, paramètres, textes) ; banc Dart (rôle, mesure rampe), kr1_securite.py ; versions kalis_adapt 1.0.5, kalis_bench 0.5.7 ; fixtures régénérées.
- Échantillon 1.0.6 réparti : c7 0, retiré 0, réduit 2,0 %, part servie 27 %, retour à l'écrit 31 → 84 (séances manquées comptées à l'écrit après répartition) ; mode prudent toujours : retour à l'écrit 49, réduit 3,8 %.
- CI : run A 39247073902 (Dart 1.0.4 avant, mesure) ; run B 89a320e9 (tests + campagne Python 1.0.6).

- Relecture indépendante (Opus) : 0 bloquant ; M2 corrigé (lignes restantes sans rôle non coupées, rang 3), mineur 4 (première ligne créditée), texte de retrait, commentaire rupture.dart ; M1 (tenues bras tendus : règle tendineuse gardée, exception documentée) ; mineurs documentés.
- CI : run A 39247073902 (avant, Dart 1.0.4) ; run B (ter) 39260047813 (tests + campagne Python 1.0.6, 20 parts) ; run C (bis) be0711bb (campagne Dart 1.0.6 + adversaires, comparaison au run B) ; format distant branche claude/fmt-km4 (033c6eda).
- Part 0 du run B : Dart compile, tests kalis_adapt verts sauf docs/PROPRIETAIRE.md (version, corrigé) ; format kalis_adapt à corriger (branche fmt) ; pytest : test_campagne (corrigé) + test_fixtures (numpy de la CI, connu).

- Run B (répartition) : critère 7 = 40 (28 saisons, autres_10 graines 48 et 96) → répartition désactivée (`retour_repartition_semaines` 0), nouveau `retour_emprunt_plancher` (1 = P).
- Run D (Dart, 39304949115) : variante P : critère 7 = 0, principal retiré 0, réduit 3,11 % (avant 4,27 %), part servie 36,2 % (avant 7,0 %), retour à l'écrit 54 064 (avant 50 828), réalisée appariée 243 277 (238 906). Variante M non mesurée (pas de Dart sur les parts ≥ 100).
- Run E (Python P, 39312132226) en cours ; run F (ea1bacf5 : tests, adversaires, comparaison D↔E, critères) en file.

## En cours / reste
- Échantillon 1.0.6 ; tests hérités (`test_securite_regles.py` retour gradué) à mettre à la sémantique 1.0.6 ; fixtures ; portage Dart ; banc Dart (rôle, mesure) ; campagnes CI (Dart avant, Python 1.0.6, Dart 1.0.6) ; documents ; livraison.

## Décisions
- Crédits de groupes : revus sur sources (sous-agent, scratchpad sources_km4.md) ; table partagée avec kalis_plan et le validateur du banc : non changée dans ce lot (recommandation dans la livraison).
- Plancher principal : max(1, ⌈écrit × 0,5⌉) ; jamais 0 sans douleur.
- Répartition seulement sans séance manquée dans les 4 dernières semaines (une séance manquée compte à son écrit au validateur).

## Point du 20/10/2026 04:00 UTC
- Paramètres finaux SHA 4156e61b…045a (347 clés ; `retour_repartition_semaines` 0, `retour_emprunt_plancher` 1).
- Run D (Dart P) : c7 = 0, principal retiré 0. Run E (Python, 89 438 saisons) : c7 = 0 ; parité D ↔ E : 89 438 identiques (run F). Critères g0-5 sans recul au-delà du bruit.
- En cours : run G 39363111472 (demi-parts 13/40, 33/40 + publication complète) ; contrôle complet 39363143851 (commit 34580a33, même code que l'arbre final).
- Reste : remplir ⟨G⟩ (CRITERES_KM4.md, livraison), push moteurs, étiquettes, livraison, ETAT_CP, page de suivi, notification.
