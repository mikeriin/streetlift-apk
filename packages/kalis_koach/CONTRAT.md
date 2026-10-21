# Contrat de `kalis_koach` 0.1.0 (lot GK, piste K)

Paquet Dart pur : aucune dépendance à Flutter (seulement `meta` et `collection`), aucune horloge,
aucun hasard, aucun stockage. Deux appels identiques donnent un résultat identique.
Schéma des données : `kalisKoachSchema = 1`.

## 1. Format des commandes

Chaque calque est une `List<int>` plate : un opcode suivi de ses coordonnées entières.

| Opcode | Constante | Arguments | Effet (`Path` Flutter) |
| --- | --- | --- | --- |
| 0 | `koachMoveTo` | x y | `moveTo` (début d'un sous-chemin) |
| 1 | `koachLineTo` | x y | `lineTo` |
| 2 | `koachCubicTo` | x1 y1 x2 y2 x y | `cubicTo` |
| 3 | `koachClose` | — | `close` |

- **Remplissage pair-impair** (`PathFillType.evenOdd`) pour chaque calque : les trous (K, intérieur
  du tableau…) sont des sous-chemins imbriqués.
- Chaque sous-chemin commence par 0 et se termine par 3 (contrôlé par `koachPathStats`).
- `replayKoachPath(cmds, sink, scale:, dx:, dy:)` rejoue un calque dans un `KoachPathSink` (à
  implémenter côté application : quatre méthodes qui appellent `Path.moveTo/lineTo/cubicTo/close`).
  `koachPathToSvg` écrit l'équivalent SVG (rapports).
- Repère des poses : **x = 0 au milieu des yeux, y = 0 sur la ligne des pieds** (ou la coupe d'un
  buste), y vers le bas (négatif au-dessus des pieds). Une pose en pied mesure **1 000 unités** de la
  pointe de la flamme aux pieds (`koachBodyHeight`). `koachCommonFrame` = union des 36 boîtes + 40
  unités : dessiner toute pose dans ce cadre garde Koach à la même place quand il change de pose.
- Repère des flammes : x = 0 au centre, y = 0 à la base ; la flamme 10 mesure 1 000 unités, les
  autres gardent leurs tailles relatives d'origine (`koachFlameFrame` = union des boîtes).

## 2. Calques

| Calque | Contenu | Couleur à appliquer |
| --- | --- | --- |
| `ink` (encre) | silhouette, accessoires ; **les yeux ouverts y sont remplis** | encre |
| `paper` (papier) | parties blanches dans la silhouette : K, yeux fermés, bouche, intérieur des accessoires, traits de séparation (bras devant le corps, doigts) | papier |
| `eyes` (yeux) | les deux yeux ouverts ; vide si la pose a les yeux fermés | papier |

Ordre de dessin : encre, papier, yeux. Le papier et l'encre sont tracés sur des masques
complémentaires : les dessiner l'un sur l'autre ne laisse pas de jour visible.

**Clignement** (D6.3) : `eyeBoxes` donne la boîte de chaque œil (gauche puis droite) ; l'application
écrase verticalement le calque `eyes` autour du centre de chaque boîte (échelle y de 1 à 0 puis 1)
— l'encre, remplie sous les yeux, apparaît comme une paupière. Désactivé si « Réduire les
animations ».

### Règles de couleur (D6.2, à appliquer par l'application)

| Thème | Encre | Papier (calques `paper` et `eyes`) |
| --- | --- | --- |
| Clair | quasi-noir (#141414 dans les planches de contrôle ; ou la couleur de texte du thème) | blanc #FFFFFF (ou le fond du support) |
| Sombre | texte clair **#F4F4F4** | **fond du support** (#121212 dans les planches de contrôle) |

En thème sombre, Koach est donc blanc avec les yeux et le K de la couleur du fond. Les flammes
prennent un **dégradé de la couleur dominante** (D5.5) : `koachFlameTint(niveau)` donne la position
0 (clair, flamme 1) à 1 (vif, flamme 10) ; l'application interpole ses couleurs. Le niveau ne passe
jamais par la seule couleur : `koachFlameLabel(niveau)` (« Difficulté 7 sur 10 ») pour TalkBack, et
la taille croît avec le niveau.

## 3. Catalogue des 36 poses

`KoachPose` (énumération, ordre des planches), `pose.art` (dessin), `pose.info` (fiche :
`emotion`, `usages`, `eyesOpen`, `framing` en pied / buste, `gaze` gauche / face / droite,
`bubbleSide`), `KoachPose.byId`, `KoachPose.forUsage`, `koachPoseFor(usage, occurrence:)`.

| Planche | Poses (identifiants) |
| --- | --- |
| A pédagogie | `explain_board`, `read_tip`, `anatomy`, `progress_chart`, `think`, `checklist`, `choice`\*, `idea`\*, `settings`\*, `determined`, `direction`, `analyze` |
| B émotions | `wave`, `thumbs_up`, `happy`°, `point`, `ponder`, `shrug`, `oops`, `please`, `love`, `flex`, `run`, `victory`° |
| C énergie | `thumbs_up_2`, `cheer`°, `pump`, `flag`, `fist_bump`, `heart`°, `you`, `double_biceps`, `clap`°, `sprint`, `fist_up`°, `present`° |

\* buste (coupe à la taille) ; ° yeux fermés (pas de clignement). Les 36 identifiants proposés par le
prompt ont été vérifiés sur les images : tous correspondent. Fiche complète (émotion, usages, regard,
bulle, IoU) : `docs/controle/vectorisation.md`.

- **Regard** : mesuré par l'asymétrie des aires des deux yeux (vue de trois quarts : l'œil éloigné
  est plus petit) ; |asymétrie| < 0,06 → de face. Relu sur les planches de contrôle.
- **Côté de la bulle** : côté du regard, sauf si la pose déborde de plus de 520 unités de ce côté
  (accessoire : tableau, panneau…) ; de face : le côté le plus dégagé.

## 4. Répliques

```dart
final director = KoachDirector();            // table des raisons de base
const texts = KoachTexts();                   // français
final line = director.lineFor(KoachCue(
  KoachEvent.proposalNew,
  reason: 'load_increased',                   // code de raison du moteur
  params: {'exercise': 'Pompes'},              // déjà mis en forme
  occurrence: 3,                               // nb d'affichages précédents (tenu par l'app)
  seed: 12345,                                 // graine stable de l'installation
));
texts.bubble(line);   // « Je te propose d'augmenter un peu la charge sur Pompes. »
line.pose; line.actions; line.priority; line.whyKey;
director.explain(line);   // réplique « Pourquoi ? » (ou null)
```

- **Événements** (`KoachEvent`) : accueil, profil (début, étape, fin, mise à jour nécessaire — D6.5),
  création du programme (en cours, première passe, programme prêt), revue (ouverture, modification
  appliquée), proposition de changement (nouvelle, acceptée, refusée), changement appliqué par le
  moteur, bilan santé (ouverture, tout va bien, gêne, douleur), fin de séance (réussie, difficile,
  écourtée), record, erreur, annulation, session de test (entrée, sortie), nouveauté présentée la
  première fois, et `why` (explication d'une réplique, via `explain`).
- **Réplique** (`KoachLine`) : pose, clé de message (variante), paramètres, priorité
  (`KoachPriority` : sécurité 100 > réponse 95 > erreur 90 > session 85 > santé 80 > changement
  appliqué 75 > décision 70 > record 65 > retour 60 > programme 50 > confirmation 40 > nouveauté 30 >
  accueil 20), actions proposées (`KoachAction` : nature + clé du libellé), clé « Pourquoi ? ».
- **Choix déterministe sans répétition** : variante = (occurrence + seed) mod n ; pose =
  (occurrence + seed + ⌊seed/7⌋) mod m. Deux occurrences successives n'ont jamais la même variante
  quand n ≥ 2 (testé sur 10 000 demandes).
- **Paramètres obligatoires** par règle ; un paramètre manquant lève `ArgumentError`. Ce sont des
  chaînes déjà mises en forme par l'application (`exercise`, `replacement`, `field`, `feature` :
  noms ; `remaining`, `done`, `planned`, `minutes` : nombres ; `value` : valeur avec son unité, par
  exemple « 15 répétitions » ; `weeks` : durée du programme, toujours ≥ 2). Les messages évitent
  l'accord d'un nom avec un nombre (« Questions restantes : 1 »), sauf `weeks` (« 12 semaines »).
- **Codes de raison → messages** : `KoachReasonTable.base()` contient des exemples pour les codes les
  plus probables (`load_increased`, `volume_reduced`, `exercise_replaced`, `session_shortened`,
  `deload`, `calibration`) : variantes de proposition, de changement appliqué, explication, poses,
  paramètres. `extend([...])` ajoute ou remplace des entrées sans modifier le paquet. Code inconnu →
  message générique (proposition ou ajustement) et explication générique. **Les codes définitifs sont
  ceux de `kalis_core` (GC) et `kalis_adapt` (G8) : les lots G9/G10 relieront leurs codes à cette
  table** (les exemples ci-dessus sont des choix raisonnés, pas un contrat avec les moteurs).
- **Textes** : français, tutoiement, apostrophe typographique, phrases courtes ; bulle ≤ 120
  caractères (`koachBubbleMaxChars`), explication ≤ 240 (`koachWhyMaxChars`), libellé d'action ≤ 24,
  paramètres longs compris. Aucune allégation médicale (motifs de `tools/check_claims.py`, L13),
  aucune promesse de résultat, aucun vouvoiement (tests). Une douleur signalée renvoie vers un
  professionnel de santé, priorité maximale.

## 5. Paramètres et justification

| Paramètre | Valeur | Justification |
| --- | --- | --- |
| Seuil encre/papier | luminance 128 | milieu de l'anticrénelage ; IoU encre brute ≥ 0,97 (mesuré) |
| Traits de séparation | pixels clairs (≥ 70) d'une structure < 9 px de large et ≥ 60 px², épaissis de 3 px | les liserés gris de 2 à 6 px portent le dessin (sans eux, `ponder`, `please`, `clap` deviennent des silhouettes pleines — vérifié sur les planches de contrôle) ; épaissis à ~1 % de la hauteur du corps pour rester visibles (~1,5 px pour un Koach de 150 px). **Choix raisonné**, réversible |
| Poussières | < 150 px² | aucune forme voulue n'est aussi petite (mesuré : 1 à 2 poussières d'encre et 6 à 11 de papier par planche) |
| Hauteur d'une pose en pied | 1 000 unités | ≈ 1 unité par pixel source : l'arrondi entier perd ≤ 0,5 px source |
| Bustes | tête (yeux → pointe) = médiane des poses en pied (483,9 u) | un buste n'a pas de pieds : on égalise la taille de la tête |
| potrace | alphamax 1,0, opttolerance 0,2, turdsize 100 px² | valeurs par défaut de potrace (P. Selinger, *Potrace: a polygon-based tracing algorithm*, 2003) ; IoU ≥ 0,99 (mesuré) |
| Œil ouvert | solidité ≥ 0,80 | amandes convexes ≥ 0,84, croissants ≤ 0,78 (mesuré sur les 72 yeux) |
| Regard | asymétrie des aires > 0,06 | seuil placé dans l'écart mesuré entre 0,042 (`thumbs_up_2`, relu de face sur la planche) et 0,070 (`flag`, relu de trois quarts) ; **choix raisonné** |
| Flammes | agrandies ×4 (bicubique) avant tracé | les flammes source mesurent 80 à 180 px |
| Poids | ≤ 400 000 octets de Dart généré | exigence du lot ; mesuré : voir `docs/controle/vectorisation.md` |

## 6. Limites connues

- Les traits de séparation sont **épaissis** par rapport aux planches : l'écart compte dans l'IoU
  « brut » (0,97 à 0,99), pas dans l'IoU de la silhouette nettoyée (≥ 0,99). Quelques petites
  encoches du dessin d'origine (jonction tête-épaules) deviennent des tirets arrondis visibles en
  gros plan seulement.
- La pose `ponder` n'a pas de K visible (bras croisés devant, comme sur la planche).
- Le regard est une mesure géométrique ; il peut être corrigé pose par pose dans
  `tools/koach/poses.json` (champs `gaze` et `bubble`, prioritaires sur la mesure).
- Les codes de raison sont des exemples (voir § 4).
- Micro-animations (respiration, rebond, transition) : à la charge de l'application (G5) ; le paquet
  fournit les boîtes des yeux et le cadre commun.

## 7. Registre de validation

| Date | Version | Contrôle | Résultat |
| --- | --- | --- | --- |
| 01/10/2026 | 0.1.0 | Vectorisation : IoU par pose relue dans le Dart généré | min 0,990 (nettoyée), 0,971 (brute) ; flammes min 0,991 |
| 01/10/2026 | 0.1.0 | Planches de contrôle (36 poses + 10 flammes, clair et sombre, gros plans) regardées en entier puis en gros plan | conformes (voir § 6) |
| 01/10/2026 | 0.1.0 | Répliques : couverture, clés, longueurs, allégations, déterminisme, 10 000 demandes seedées | verts (CI) |
| — | — | Relecture des textes par un professionnel diplômé (santé, entraînement) | **non faite** : textes rédigés sans relecture professionnelle |
