# Kalis Track — Refonte UI : L5 Finition globale (3.0.2)

Mise à jour : 26 septembre 2026. Base **3.0.1+62** (LC1b, SHA-256 `615bb1b0…dd38d`) → version candidate **3.0.2+63**. Registre unique de L5 ; les checklists antérieures sont conservées plus bas.

**Autorisation en vigueur** : prompt `prompt_L5_global_tous_ecrans_kalis_track.txt` (26/09/2026, 15 h 58). Il remplace la proposition préalable (L5-A) et la validation écran par écran : finition de tous les écrans et six couleurs autorisées directement. Cette autorisation porte sur le travail, **pas** sur la validation du résultat, qui reste à faire sur téléphone.

Colonnes : **Autorisé** (demande du propriétaire) · **Codé** · **Tests** (exécutés en CI sur cette version) · **Rendu** (rendu Flutter de test vérifié ; ni capture d'APK ni essai sur appareil) · **Téléphone** (validation du propriétaire, toujours « Non » à la livraison).

## Décisions de couleur (historique conservé)

| Date | Décision | Source |
| --- | --- | --- |
| jusqu'au 25/09/2026 | Dominante rouge unique : `#6B0C0C`, `#A61717`, accent sombre `#E85959` | Charte |
| 26/09/2026 | Six dominantes au choix par utilisateur, rouge par défaut, indépendantes du thème clair/sombre/système | Prompt L5 V2 |
| 26/09/2026, 15 h 43 | Bleu remplacé par **Jaune** ; barres de progression du niveau qui suivent la dominante | Propriétaire |
| 26/09/2026, 15 h 47 | Six palettes et sélecteur de la proposition L5-A validés | Propriétaire |
| 26/09/2026, 15 h 58 | Finition globale autorisée (le prompt cite encore le Bleu : la décision explicite de 15 h 43 est conservée, Jaune) | Propriétaire |
| 26/09/2026 | Indicateur NIV. de PROGRAMME : barre **unie** de la dominante (règle « niveau sans contour ni dégradé ») ; marque K inchangée (bordeaux en clair, `#F4F4F4` en sombre), faute de décision contraire | Appliqué, documenté |

## Palettes (identifiants stables `accent`)

| Palette | Principale | Vive (sombre / clair) | Accent sombre | Texte sur la couleur |
| --- | --- | --- | --- | --- |
| Rouge Kalis `rouge` (défaut) | `#6B0C0C` | `#A61717` | `#E85959` | blanc / `#F4F4F4` |
| Jaune `jaune` | `#E6B000` | `#F5C400` / `#7A5800` | `#F5C400` | `#121212` (vive claire : blanc) |
| Vert `vert` | `#0B4D33` | `#157A4E` | `#4EC08A` | blanc / `#F4F4F4` |
| Violet `violet` | `#44146B` | `#8240C4` | `#B38CF2` | blanc / `#F4F4F4` |
| Orange `orange` | `#6E2E05` | `#A84707` | `#F2924A` | blanc / `#F4F4F4` |
| Turquoise `turquoise` | `#08494F` | `#0E7479` | `#3EC4C4` | blanc / `#F4F4F4` |

Accent en clair : principale (Jaune : `#7A5800`). Jauges : principale → vive (Jaune en clair : `#7A5800 → #8A6500`).

**Suivent la dominante** : boutons pleins, bandeaux et cartes de marque, carte du jour, sélection (dock, onglets, segments, interrupteurs, curseur de semaine, points de séance), liens et icônes d'accent, champ actif, puces choisies, actions WOD, lancement des chronos de mode, records, jauges (dont les barres de progression du niveau), décor (flamme, boss, anneau hebdo, confettis).

**Couleurs fixes** : erreurs, suppression et confirmations destructrices, avertissements écrits, validation/succès, phases de chronomètre (effort, repos, terminé, time cap), insigne de rang, rareté des badges, graphiques de données (barres STATS, radar, carte musculaire, courbe Koach), couvertures et rubans WOD, couleurs de blocs et de séances perso, marque K, icône Android et écran natif, fonds et textes neutres.

## Checklist par écran

| Zone / états | Changement | Autorisé | Codé | Tests | Rendu | Téléphone |
| --- | --- | --- | --- | --- | --- | --- |
| Palettes et thème partagés (`app_theme.dart`) | 6 palettes × clair/sombre, rôles dominante/fixes, thème Material par combinaison | Oui | Oui | Oui (12 combinaisons, contrastes calculés) | Oui (PROGRAMME et RÉGLAGES, 6 × 2) | Non |
| Application sans redémarrage (`main.dart`) | Couleur et mode indépendants ; arbre rafraîchi sans recréer routes, saisies, séance ; mode Système suivi | Oui | Oui | Oui (route empilée, saisie, semaine, journal inchangé ; bascule de luminosité) | — | Non |
| RÉGLAGES → Apparence | « Couleur dominante » : 6 options nommées, coche + contour + gras, 2 colonnes (3 sur grand écran, 1 à 150 %+), message si non enregistré ; sous-titres du Thème sans couleur ; au-delà de 150 % de texte, Thème en trois choix empilés | Oui | Oui | Oui (320/390/600 px, 100/130/200 %, sémantique, choix rapides, erreur d'écriture) | Oui | Non |
| Préférence `accent` (`store.dart`) | Réglage persistant ; absent/inconnu/mauvais type → rouge sans refuser l'import ; export/import ; suppression locale | Oui | Oui | Oui | — | Non |
| Démarrage, erreur au lancement | Conservés (couleurs neutres, K inchangé) | Oui | — | Suite complète | Non rendu | Non |
| Départ du programme | Conservé | Oui | — | Suite complète | Oui (avant = après en rouge) | Non |
| Navigation, dock, entêtes | Accents de la dominante ; `KTopBar` à hauteur réglable ; libellé du dock limité à 115 % (conservé, limite) | Oui | Oui | Suite complète | Oui | Non |
| PROGRAMME | « SEMAINE N ▾ », dates et bloc dans l'en-tête (un appui : choix de la semaine) ; au-delà de 130 % de texte, ligne pleine en tête de liste avec le bouton « Semaines » ; titres 1 ligne (référence), 2 lignes (< 360 px ou > 110 %), 3 lignes (> 150 %) ; carte du jour ≥ 12 px ; « En cours » écrit ; NIV. suit la taille du texte, barre unie | Oui | Oui | Oui (tests existants de la semaine visible entière conservés) | Oui (390, 320 × 200 %, 6 couleurs) | Non |
| Séance (programme, perso) | Chronos de série en couleurs fixes ; confirmations en rouge fixe ; textes sur fonds dominants | Oui | Oui | Suite complète | Oui (identique en rouge) | Non |
| Bilan, récompenses, cérémonie | Textes sur la couleur, confettis de la dominante | Oui | Oui | Suite complète (`reward_flow_test.dart`) | Non rendu | Non |
| Historique de séance | Conservé ; suppression en rouge fixe | Oui | Oui | Suite complète | Oui (identique) | Non |
| ARSENAL, éditeur de séance | Conservés ; suppression en rouge fixe | Oui | Oui | Suite complète | Oui (identiques) | Non |
| Boutique, catalogue, fiches WOD | Couvertures fixes ; carte de crédits : « Gagner » sous le solde au-delà de 150 % ; déficit en rouge « danger » | Oui | Oui | Suite complète (`wod_store_test.dart`) | Oui (identiques en rouge à 100 %) | Non |
| Exécution WOD | Chiffres et phases en couleurs fixes ; time cap en rouge fixe | Oui | Oui | Suite complète | Oui (identique) | Non |
| STATS | Titres sans mot coupé (grand texte) ; carte personnage : titre sous l'insigne au-delà de 150 % ; branches du parcours empilées au-delà de 150 % ; puce sélectionnée lisible en sombre ; titres de section 11 px ; radar, barres et courbes fixes | Oui | Oui | Suite complète | Oui | Non |
| Références (Pilotage) | Champ sans libellé tronqué (« — kg »), nom lu par TalkBack ; « Non renseigné » lisible (7,83:1 en sombre) | Oui | Oui | Suite complète | Oui | Non |
| Réglages (sous-pages), sauvegarde, import, suppression | Titres sans mot coupé ; tuiles sans icône décorative au-delà de 150 % ; avertissement d'import lisible | Oui | Oui | Suite complète (`l2b_data_control_test.dart`) | Oui (chronomètres) ; dialogues non rendus | Non |
| Koach | Courbe de données en rouge fixe ; accents de la dominante | Oui | Oui | Suite complète | Non rendu | Non |

## Limites connues

- Libellé du dock : réduit au-delà de 115 % (conception validée du dock flottant) ; noms complets par TalkBack et info-bulle.
- Grands chiffres (chrono WOD 72 px, charge 28 px) : `FittedBox` conservé, le nombre reste entier.
- À 200 % et 320 px, un titre de liste d'une seule longue suite de lettres peut encore passer à la ligne au milieu d'un mot (historique STATS).
- Aucun essai TalkBack réel, aucune capture d'appareil.

---

# Historique conservé — proposition L5-A (26/09/2026)

Proposition sans code (maquettes HTML, jamais présentées comme l'application) : six palettes, sélecteur, pilote PROGRAMME P1-P5, ajustements des avertissements et des puces. Remplacée par l'autorisation globale ci-dessus ; son contenu a été réalisé dans 3.0.2.

---

# Historique conservé — Refonte UI 2.5.0

Mise à jour : 24 septembre 2026. Version **2.5.0+51**.

Le catalogue de WODs devient une boutique de jeu : vitrine éditoriale, essai
du jour, remises hebdomadaires réelles, liste d'envies avec jauge, couvertures
procédurales, fiche produit et révélation au déblocage. Rien d'aléatoire,
aucun compte à rebours truqué, aucun crédit repris.

## Économie (`lib/progression.dart`, `lib/game.dart`, `lib/store.dart`)

- [x] `Progression.creditsForLevel` : 3 offerts, +2 par niveau, +3 tous les 5 niveaux ; strictement supérieur à l'ancien barème à tout niveau (aucun solde ne baisse).
- [x] `GameState` : `fullWeeks` (semaines à trois entraînements), `chapterCredits` (+3), `bossCredits` (+5), `weekCredits` (+1) ; `bonusCredits` = somme.
- [x] `basePrice` (paliers 1-4 crédits) ; `wodCost` = base − vitrine (−1) − essai terminé (−1), plancher 1 ; `discountOf`, `missingFor`, `triedAndDone`.
- [x] `unlocked` ne passe plus par `wodCost` (pas de récursion) ; le prix payé reste figé dans `unlockedWods`.
- [x] Sélections déterministes (`storeClock` remplaçable) : `trialWod` (jour, hors vitrine, niveau ±1, tenté seulement aujourd'hui), `weeklyPicks` / `weeklyIds` (semaine, trois formats, niveau −1 à +2), `recommended()` (jour, niveau ±1, hors essai et vitrine). Caches vidés par `notifyListeners()`.
- [x] `canRun` = possédé ou essai du jour ; `wod_screen.dart` l'utilise pour le chrono, le score et l'accès.
- [x] Liste d'envies : `wishlist`, `wished`, `toggleWish`, `wishedWods`, `wishTarget` ; retirée à l'achat ; sauvegardée dans le document d'état (`wishlist`, format 3, absent = vide) et validée à l'import.
- [x] `untilMidnight`, `daysUntilNewWeek` : minuteurs calculés à partir de la date réelle.

## Vitrine (`lib/wod_store.dart`, nouveau)

- [x] `tierOf` / `tierLabel` / `TierChevrons` : Standard, Avancé, Élite, Légende ; chevrons toujours accompagnés d'un libellé.
- [x] `WodCover` + `_CoverPainter` : dégradé bordeaux, motif par famille (`motifOf` : speed, stack, rings, ticks, rungs, stairs, blocks, ramp, ladder), reflet Élite / Légende, vignette, version assombrie ; `RepaintBoundary`, aucune image.
- [x] `WodPriceTag` / `storeStateOf` : possédé (record), essai offert, prix (barré si remise), « plus que 1 crédit », cadenas ; le rouge sert de fond, jamais de texte sur fond sombre.
- [x] `WodStoreCard` (rail 5:4), `StoreRail` (hauteur naturelle, `SingleChildScrollView` horizontal), `WodHero` (essai du jour 16:9, « Essayer · offert », « Voir la fiche »), `WishGoalCard` (jauge crédits / prix, distance en crédits ou en XP), `CreditsCard` (solde, prochain gain, jauge d'XP, phrase de règle), `showCreditRules` (feuille des gains).
- [x] `UnlockReveal` + `_SheenPainter` : reflet joué une fois (0 → 1), respiration d'échelle ±3,5 %, sans boucle.
- [x] Textes : `storeTagline` (accroche par famille), `storeWhy` (cible et qualité), `trialCountdown`, `weeklyCountdown`.

## Catalogue et fiches

- [x] `wod_catalog.dart` : la vitrine (crédits, prochain objectif, à l'affiche, vitrine de la semaine, à ta mesure, liste d'envies, « Tout le catalogue ») est l'en-tête de la liste sans recherche ni filtre ; un rappel du solde sinon. Titre `WODs · N`, champ unique, tri et filtres inchangés.
- [x] `wod_preview.dart` : page produit (`StatefulWidget`, un seul `ListView`) : couverture avec ruban « Essai du jour » / « Vitrine · −1 », nom, entête, chips (format, niveau et palier, durée, prix, source), Mouvements, Pourquoi ça compte (accroche, cible, record ou consigne), Volume et durée, Muscles. Barre basse : « Lancer le WOD » / « Revenir au chrono », « Essayer · offert jusqu'à minuit » + « Acheter · N crédit(s) », ou « Il te manque … ». Cœur de liste d'envies dans la barre d'app.
- [x] `arsenal_screen.dart` : `WodTile` avec couverture, chevrons, prix et cœur ; menu d'actions (aperçu, lancer ou essayer, liste d'envies) ; bannière `_Credits` avec prochain objectif ou essai du jour.
- [x] Textes de campagne et de niveau alignés sur le barème (`game_widgets.dart`, `stats_progression.dart`).

## Tests

- [x] `test/wod_store_test.dart` : dix tests (voir README).
- [x] `progression_test` (barème), `game_test` (crédits dérivés), `wod_acquisition_test` (WOD hors essai pour le cas sans crédits).
- [x] Contrats conservés : `WODs · 0` / `WODs · 1000`, champ de recherche unique, icône de fermeture unique, « Acheter · N crédit(s) » dans un `FilledButton`, « Lancer le WOD », « Il te manque », « MOUVEMENTS » visible à 320 px, un seul `ListView` sur la fiche, « Achète un WOD » à l'ouverture du catalogue, « Nouvelle séance » et « Catalogue » dans l'Arsenal.

## Validation et livraison

Voir `AUDIT_2.5.0.md`. Aucune analyse, compilation ni test Flutter n'a pu être exécuté ici.

## Historique

Les checklists 1.8.7 à 2.4.1 restent dans `docs/REFONTE_UI_*.md`.
