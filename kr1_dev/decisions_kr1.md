### KR1

Lot livré le 16/10/2026 (session Opus 5.5, effort maximal, C17.18), sans panel ni relecture documentée (C13.3),
validation par le pilotage : `kalis_adapt` 1.0.3 (Koach 1.0.4) et `kalis_bench` 0.5.3 (`moteurs` __COMMIT__,
étiquettes publiées), contrôle complet `claude/ci-cp-a` run __RUN__ vert (arbre identique). **Critère dur non tenu :
décision requise.** Détail : `pipeline/cp/livraisons/LIVRAISON_KR1.md`, `packages/kalis_bench/docs/CRITERES_KR1.md`.

- **KR1.1 Lancement** : message sans ligne « Lot : » ; KR1 seul lot moteur « à faire ». `add_repo` absent ; accès en
  écriture vérifié par `git push --dry-run` puis par le push de la ligne « en cours ». Pas de SDK Dart (proxy) :
  mise au point, campagnes et contrôle sur `claude/ci-cp-a` (commits « KR1 contrôle (dev) »). Clé des références non
  lue. Sauvegardes sur `cp-sauvegardes/KR1`.
- **KR1.2 Données de référence** : régénérées sur `kalis_plan` 0.4.1 et étendues aux 34 profils (302 saisons, 0
  constat) ; saison vivante du banc = saison lue par Python à l'égalité stricte ; saisons figées sur 0.3.1 gardées
  dans `kalis_bench/docs/data/kr1/saisons_figees_0_3_1/` (hors de la copie de l'application ; `kalis_adapt` 29,6 →
  31,1 Mo, C17.19.3).
- **KR1.3 Koach 1.0.4** (référence et Dart, parité 1e-9) : la première campagne (Koach 1.0.3) plantait 8 saisons sur
  5 436 (`ks_test_ppl6`, séances manquées : réponses « rien de spécial » répétées, variance multipliée par 4 sans
  borne). Élargissement plafonné par composante à l'a priori de population ; aucune valeur de paramètre changée
  (`1.0.4-ref.1`, asset `koach_params_1_0_4.json`). 0 saison plantée sur 90 600. Limite (relecture M1) :
  élargissement par composante, non uniforme ; à reprendre en méthode.
- **KR1.4 Campagne du couple** (`kalis_plan` 0.4.1 × Koach complet ; 34 profils × 100 graines × 3 vérités ×
  scénarios = 90 600 saisons) : critère 7 du cahier **63** (59 poussées de douleur, 4 aggravations ; 25 saisons ;
  b 48, c 15, a 0) ; **0** sur la graine 0 et sur les graines 0 à 5 ; plan initial de `kalis_plan` 0 ; « retour à
  l'écrit » 45 046 (à part, C13.10.1). Le banc classait 9 « retours à l'écrit » comme hausses introduites (bloc
  interrompu non tronqué) : corrigé dans `kalis_bench` 0.5.3 (Dart et Python).
- **KR1.5 Causes** (reproduites, `kalis_adapt/reference/tests/test_kr1_violations.py`) : poussées = zone réactive du
  modèle de vérité exposée au-delà de 1,5 fois sa tolérance, gêne de 2 à 3 sous `douleur_seuil` (3), après une
  remontée d'exposition (aucune reprise faute d'arrêt, fin de la reprise à 84 jours, retour après séances manquées) ;
  aggravations = hausse de charge sur un exercice sollicitant à 0,5 une zone douloureuse à 5, bloquée seulement à
  partir de `douleur_moyenne_contrainte`. Règles de méthode : pas de changement de conduite sous douleur dans ce
  lot ; aucune cause dans `kalis_plan` (pas de 0.4.2).
- **KR1.6 Critères KM 1 à 8 et 11** (graines 0 à 5, contre les saisons figées, bruit de 17 groupes) : aucun recul
  au-delà du bruit (e1RM 3,83 % contre 3,94 ; mauvais jour 0,88 contre 0,87 ; couverture 90,08 contre 90,21 ; jour J
  0,9453 contre 0,9449 ; 7 bis 20 contre 19 sur le jeu neuf ; temps 0,242 s et 26,6 ms). Nouveau diagnostic publié :
  saison réalisée appariée (259 646 hausses de volume réalisé au-delà de l'écrit, 62 401 saisons), sans statut de
  critère.
- **KR1.7 Relecture indépendante** (sous-agent Opus) : 0 bloquant, 3 majeurs (M1 documenté et test, M2 vue
  appariée ajoutée, M3 sécurité dans les fixtures du banc), 13 mineurs traités.
- **KR1.8 Décision requise** : (1) valider `kalis_adapt` 1.0.3 et `kalis_bench` 0.5.3 comme mesure du couple ;
  (2) critère dur C17.17.3 non tenu : soit un lot de méthode Koach (Fable, C13.9, « KM1c4 » puis portage : reprise
  graduée après tout épisode au-dessus du seuil, pas de saut en fin de reprise, exposition d'une zone sensible
  bornée par le réalisé, aucune hausse sous douleur à sollicitation ≥ 0,5, élargissement uniforme borné), soit
  critère dur « 0 sur les saisons racontées et les graines 0 à 5 » avec les 63 suivies comme indicateur ;
  (3) KB1 après cette décision (`kalis_adapt` 1.0.3 peut remplacer 1.0.2 dans l'application).

