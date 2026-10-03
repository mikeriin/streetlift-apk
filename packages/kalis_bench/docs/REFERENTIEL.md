# Référentiel scientifique du banc d'essai (kalis_bench 0.1.0)

Ce document dit ce qu'est un excellent programme d'entraînement, du débutant à
l'élite, principe par principe : la règle chiffrée, ce qui la fonde, son niveau
de preuve, sa traduction par niveau, et ce qu'un très bon coach fait au-delà
des données. Il sert trois usages : les critères calculables du banc
(`docs/CRITERES.md` cite les principes par leur identifiant, par exemple
`R5-P22`), les attentes de coach de chaque profil type (`profiles/`), et le
panel de coachs virtuels (`docs/PANEL.md`), qui reçoit ce document.

**Ce fichier est la synthèse.** Le texte complet de chaque principe (énoncé,
chiffres avec leur statut, discussion, liste des références avec DOI ou PMID)
est dans les six chapitres de `docs/referentiel/` :

| Chapitre | Thèmes du lot CR | Principes | Références |
|---|---|---|---|
| [R1](referentiel/R1.md) — Volume, fréquence, intensité, proximité de l'échec, repos | a, b | P1 à P18 | 28 |
| [R2](referentiel/R2.md) — Force maximale, mouvements lestés, techniques d'intensification | c, e | P1 à P22 | 57 |
| [R3](referentiel/R3.md) — Périodisation, décharges, affûtage, tests, saison | d | P1 à P21 | 42 |
| [R4](referentiel/R4.md) — Figures et skills, endurance de force, spécialisation | f, g, h | F1 à F12, G1 à G8, H1 à H4 | 67 |
| [R5](referentiel/R5.md) — Débutants et reprises, tolérance et récupération, sécurité | i, j, k | P1 à P28 | 71 |
| [R6](referentiel/R6.md) — Autres disciplines (esthétique, force athlétique, course, mobilité, CrossFit, interférence, perte de poids) | l | P1 à P32 | 78 |

Total : 145 principes, 343 entrées de références (quelques articles servent
dans plusieurs chapitres).

## Comment lire un principe

- **Règle** : l'énoncé chiffré.
- **Par niveau** : sa traduction du débutant à l'élite. Les niveaux sont ceux
  du banc : débutant (moins d'un an de pratique régulière), intermédiaire,
  avancé, élite (compétiteur national ou international).
- **Preuve** : méta-analyse, essais contrôlés, consensus d'experts, ou
  pratique de terrain — dite comme telle. « Choix raisonné » signale une règle
  prudente que les données n'établissent pas directement : le banc l'applique,
  mais elle n'est pas présentée comme un fait.
- **Au-delà des données** : ce que fait un très bon coach.

## Vérification des références

Chaque référence a été vérifiée deux fois, par deux passes indépendantes.

1. **Première passe**, à la rédaction : chaque référence citée a été cherchée
   en ligne (PubMed, page de l'éditeur, Crossref) ; celles qui n'ont pas été
   retrouvées n'ont pas été retenues comme preuves.
2. **Seconde passe**, par un relecteur indépendant par chapitre (sous-agent
   qui ne recevait que le chapitre) : auteurs, année, revue, volume, pages,
   DOI ou PMID de chaque entrée recontrôlés un par un ; les chiffres clés
   comparés au résumé publié quand il était accessible.

Résultat de la seconde passe :

| Chapitre | Entrées | Confirmées | Complétées (DOI, auteurs, pages) | Corrigées | Écartées ou non confirmées |
|---|---|---|---|---|---|
| R1 | 28 | 26 | 2 | 0 | 0 (1 prépublication gardée sous réserve, 1 méta-analyse écartée dès la rédaction) |
| R2 | 57 | 32 | 22 | 2 | 1 (formule d'Epley 1985 : source primaire introuvable, écartée des preuves) |
| R3 | 42 | 40 | 2 | 0 | 0 (5 sources secondaires listées comme non vérifiées) |
| R4 | 67 | 62 | 2 | 0 | 0 (3 études ajoutées par la seconde passe) |
| R5 | 71 | 63 | 8 | 0 | 0 |
| R6 | 78 | 71 | 7 | 0 | 2 écartées (un ouvrage d'entraînement à la course non vérifié, une référence introuvable) |

Corrections de fond issues de la seconde passe (elles sont appliquées dans
les chapitres et dans cette synthèse) : attribution de deux risques relatifs
entre deux méta-analyses sur la prévention des blessures (R6-P22) ; jours de
l'affûtage de force (R6-P11) ; délai de désentraînement (R3-P14, R3-P19 : la
force maximale baisse de 1 à 4 % dès que l'arrêt dépasse 7 jours) ; isométrie
(R2-P16 : la force progresse quelle que soit l'intensité, le seuil de 70 % ne
vaut que pour le tendon) ; taille d'effet de la charge tendineuse (R4-F8) ;
échec et endurance (R4-G3, G5, G8 : s'arrêter tôt n'a pas montré de
supériorité sur le nombre maximal de répétitions) ; ordre de deux gains
inversé (R1-P17) ; l'état de la littérature sur le streetlifting (R2, note :
trois études trouvées par la seconde passe).

**Troisième passe (03/10/2026), sur R5 seulement** : rapprochement avec la revue du profil v3 du lot CQ (`packages/kalis_core/docs/PROFIL_V3.md`) par un relecteur indépendant. Une erreur de signe corrigée (Huiberts 2024 : SMD +0,08 chez les femmes, R5-P11 et P19), une réserve levée (Hägglund 2006), quinze références ajoutées après vérification sur résumé, sept divergences de traduction en règle consignées (R5, « Compléments du 03/10/2026 »).

**Limites, dites sans détour.**

- La vérification porte sur l'existence et les métadonnées des articles, et
  sur les chiffres présents dans les **résumés**. Les textes intégraux n'ont
  en général pas été consultés : tout chiffre qui n'apparaît pas dans un
  résumé porte dans son chapitre la mention « non confirmé à la seconde
  vérification ». Ces chiffres sont à relire sur texte intégral avant d'être
  figés dans un moteur.
- Les pages ont été lues à travers un outil qui les restitue en texte ; une
  erreur de restitution reste possible sur un chiffre isolé.
- Il n'existe presque aucune étude d'intervention sur le street workout, le
  streetlifting ou les figures de calisthénie (trois études descriptives ou
  d'enquête, R2). Les règles de ces disciplines transposent des résultats de
  musculation, de gymnastique et de physiologie du tendon : c'est dit dans
  chaque principe, et la pratique des coachs y pèse plus qu'ailleurs.
- Les valeurs « élite » sont presque toujours des choix raisonnés : les
  essais portent sur des pratiquants non entraînés ou entraînés, rarement sur
  des compétiteurs.

## Règles que le banc traite comme « choix raisonnés »

Les critères de sécurité du banc reposent pour partie sur des seuils de
prudence, pas sur des faits établis ; `docs/CRITERES.md` le dit critère par
critère. Les principaux : tous les garde-fous de progression des charges et
des volumes (R5-P22 : la règle des 10 % n'a pas montré d'effet protecteur) ;
tous les seuils de douleur (R5-P23, R4-F11) ; le barème de reprise après
coupure (R5-P7) ; les classes de risque des exercices et l'interdiction de
l'échec sur les mouvements à risque (R5-P27) ; les délais par levier des
figures (R4-F9) ; la fréquence et le contenu des décharges par niveau
(R3-P9) ; l'affûtage du sets & reps (R3-P21) ; les allures de course en
pourcentage (R6-P14) ; les plafonds par séance (R1-P4, R6-P1).

---

## R1 — Volume, fréquence, intensité, proximité de l'échec, repos

28 références : 26 confirmées, 2 complétées, aucune corrigée ni non confirmée (résumés relus, textes intégraux non consultés). Aucun chiffre contredit. Les valeurs par niveau sont une traduction de coach, pas des valeurs mesurées. « Non confirmé » = chiffre absent du résumé, à relire sur texte intégral.

### R1-P1 — Volume hebdomadaire et hypertrophie
- **Règle** : chaque série hebdomadaire de plus par muscle ajoute en moyenne +0,37 % de gain (taille d'effet +0,023). 12–20 séries/muscle/semaine proposées chez l'homme jeune entraîné ; au-delà de 20, pas d'avantage net sauf triceps. L'écart entre catégories de volume (5,4 / 6,6 / 9,8 %, non confirmé) n'est qu'une tendance (p = 0,074).
- **Par niveau** : débutant 6–10 séries fractionnées (plancher 4, plafond 12) ; intermédiaire 10–16 (8 à 20) ; avancé 12–20 (10 à 25) ; élite 15–25 sur les muscles prioritaires (12 à 30 sur 1–2 muscles).
- **Preuve** : méta-analyse et méta-régression — Schoenfeld et al., 2017, J Sports Sci, 10.1080/02640414.2016.1210197 ; Baz-Valle et al., 2022, J Hum Kinet, 10.2478/hukin-2022-0017.
- **Au-delà des données** : il monte le volume sur 1 à 3 muscles prioritaires, part du bas de la fourchette et n'ajoute que si la progression stagne.

### R1-P2 — Comptage fractionné des séries
- **Règle** : volume d'un muscle = séries directes + 0,5 × séries indirectes. Pour la force, seules les séries directes du mouvement comptent.
- **Par niveau** : débutant, intermédiaire, avancé, élite : règle identique.
- **Preuve** : méta-régression unique, non répliquée — Pelland et al., 2026, Sports Med, 10.1007/s40279-025-02344-w.
- **Au-delà des données** : il module le coefficient selon l'exercice (0,25 / 0,5 / 0,75), mais seul 0,5 est appuyé.

### R1-P3 — Rendements décroissants
- **Règle** : la relation volume → gains est positive mais décroissante, nettement plus pour la force ; aucun plafond net pour l'hypertrophie dans la plage étudiée.
- **Par niveau** : seuil au-delà duquel on n'ajoute plus sans raison explicite : débutant 10 ; intermédiaire 16 ; avancé 20 ; élite 25 séries/muscle/semaine.
- **Preuve** : méta-régression + essai contrôlé — Pelland et al., 2026, Sports Med, 10.1007/s40279-025-02344-w ; Schoenfeld et al., 2019, Med Sci Sports Exerc, 10.1249/MSS.0000000000001764.
- **Au-delà des données** : il réserve les volumes très élevés à des blocs de spécialisation de 4 à 6 semaines.

### R1-P4 — Plafond de volume par séance
- **Règle** : gain supplémentaire indétectable au-delà d'environ 11 séries fractionnées par muscle et par séance (hypertrophie) et d'environ 2 séries directes par séance (force). Seuils préliminaires. Au-delà du maximum, ajouter une séance.
- **Par niveau** : débutant 3–5 (max 6) ; intermédiaire 4–7 (max 8) ; avancé 5–8 (max 10) ; élite 6–10 (max 11).
- **Preuve** : méta-régression en prépublication non évaluée par les pairs — Remmert et al., 2025, SportRxiv, 10.51224/SRXIV.537.
- **Au-delà des données** : il plafonne souvent à 6–8 séries dures, car la qualité des dernières séries chute sur les mouvements techniques.

### R1-P5 — Volume pour la force maximale
- **Règle** : volume élevé (≥ 10 séries/exercice/semaine) contre faible (≤ 5) : +0,18 (IC 95 % 0,06 à 0,30 ; p = 0,003). Effet petit ; les volumes faibles font moins bien chez les débutants et intermédiaires.
- **Par niveau** : séries directes par mouvement et par semaine : débutant 3–6 (max 8) ; intermédiaire 5–10 (max 12) ; avancé 6–12 (max 15) ; élite 8–15 sur 3 à 5 séances (max 18).
- **Preuve** : méta-analyse (9 études) — Ralston et al., 2017, Sports Med, 10.1007/s40279-017-0762-7.
- **Au-delà des données** : il répartit le volume entre le mouvement cible lourd et 1 à 2 variantes d'assistance à charge moyenne.

### R1-P6 — Dose minimale efficace pour la force
- **Règle** : hommes entraînés : 1 série de 6–12 répétitions à 70–85 % 1RM, 2–3 fois/semaine, menée à l'échec, 8–12 semaines : +12,09 kg de 1RM (IC 95 % 8,16 à 16,03), gain « sous-optimal mais significatif ». Powerlifters : 3–6 séries de 1–5 répétitions/semaine au-dessus de 80 % 1RM, RPE 7,5–9,5.
- **Par niveau** : débutant 1–2 séries × 2 séances, 6–12 répétitions, 2–3 RIR (choix de coach, hors dose étudiée) ; intermédiaire 2–3 séries sur 2 séances à 70–85 % ; avancé 3–6 séries de 1–5 répétitions, > 80 %, RPE 7,5–9,5 ; élite idem + 2–3 séries allégées à environ 80 %.
- **Preuve** : méta-analyse + série d'études, hommes uniquement — Androulakis-Korakakis et al., 2020, Sports Med, 10.1007/s40279-019-01236-0 ; Androulakis-Korakakis et al., 2021, Front Sports Act Living, 10.3389/fspor.2021.713655.
- **Au-delà des données** : il l'utilise en période chargée, pas comme régime permanent d'un athlète ambitieux.

### R1-P7 — Maintien
- **Règle** : 1/3 ou 1/9 du volume conserve l'hypertrophie 32 semaines chez les 20–35 ans, pas chez les 60–75 ans. Force et masse se maintiennent avec 1 séance/semaine et 1 série/exercice si la charge est conservée ; chez les plus âgés, la masse « peut demander jusqu'à » 2 séances et 2–3 séries. On réduit les séries, jamais la charge.
- **Par niveau** : séries par muscle et par semaine : débutant 2–3 en 1 séance ; intermédiaire 3–5 en 1–2 ; avancé 4–6 en 1–2 ; élite 6–8 en 2 ; ≥ 60 ans : au moins 1/3 du volume, 2 séances (choix prudent).
- **Preuve** : essai contrôlé (n = 70, jambes) + revue narrative — Bickel et al., 2011, Med Sci Sports Exerc, 10.1249/MSS.0b013e318207c15d ; Spiering et al., 2021, J Strength Cond Res, 10.1519/JSC.0000000000003964.
- **Au-delà des données** : il garde une exposition technique courte 2 fois/semaine, car les habiletés se perdent plus vite que la masse.

### R1-P8 — Fréquence et hypertrophie
- **Règle** : à volume égal, la fréquence compte peu : 0,49 contre 0,30 en faveur de la fréquence haute sur 10 études (p = 0,002), mais aucune différence significative sur 25 études ; effet « compatible avec négligeable » en 2026. La fréquence sert à répartir le volume : fréquence minimale = volume hebdomadaire ÷ maximum par séance.
- **Par niveau** : débutant 2–3 (corps entier) ; intermédiaire 2 ; avancé 2–3 ; élite 2–4 sur les muscles prioritaires.
- **Preuve** : méta-analyses — Schoenfeld et al., 2016, Sports Med, 10.1007/s40279-016-0543-8 ; Schoenfeld et al., 2019, J Sports Sci, 10.1080/02640414.2018.1555906.
- **Au-delà des données** : il choisit la fréquence que l'athlète tiendra vraiment.

### R1-P9 — Fréquence et force
- **Règle** : la force augmente avec la fréquence, à rendements décroissants (tailles d'effet 0,74 / 0,82 / 0,93 / 1,08 pour 1, 2, 3, 4+ séances ; p = 0,003), mais l'effet n'est plus significatif à volume égalisé (p = 0,421). Sources en partie divergentes.
- **Par niveau** : séances par mouvement et par semaine : débutant 2–3 ; intermédiaire 2–3 ; avancé 2–4 ; élite 3–5, lourdes et légères alternées.
- **Preuve** : méta-analyse et méta-régression — Grgic et al., 2018, Sports Med, 10.1007/s40279-018-0872-x.
- **Au-delà des données** : il traite les figures comme une habileté : pratique fréquente, séries courtes, loin de l'échec.

### R1-P10 — Charge et hypertrophie
- **Règle** : séries menées près de l'échec : hypertrophie similaire entre charges ≤ 60 % et > 60 % 1RM (21 études) et entre ≤ 8 RM, 9–15 RM et > 15 RM (28 études, p = 0,113 à 0,469). Borne basse d'environ 30 % 1RM : non confirmée, à traiter comme choix raisonné.
- **Par niveau** : débutant 8–15 répétitions (60–75 %) ; intermédiaire 6–15, jusqu'à 20 en isolation (60–80 %) ; avancé 5–20, jusqu'à 30 en isolation (40–85 %) ; élite 5–30 (30–85 %).
- **Preuve** : méta-analyses — Schoenfeld et al., 2017, J Strength Cond Res, 10.1519/JSC.0000000000002200 ; Lopez et al., 2021, Med Sci Sports Exerc, 10.1249/MSS.0000000000002585.
- **Au-delà des données** : il privilégie 6–15 répétitions et garde les séries longues pour l'isolation et les articulations sensibles.

### R1-P11 — Charge et force
- **Règle** : gain de 1RM plus grand avec > 60 % 1RM ; lourd contre léger 0,60–0,63 ; moyen contre léger 0,34–0,35 ; lourd contre moyen 0,26–0,28, non significatif (p = 0,068). Continuum 1–5 répétitions à 80–100 % : non confirmé.
- **Par niveau** : débutant 5–10 répétitions à 65–80 % ; intermédiaire 3–8 à 75–88 % ; avancé 1–6 à 80–95 % ; élite 1–5 à 85–100 %, plus des singles à RPE 8–9.
- **Preuve** : méta-analyses — Schoenfeld et al., 2017, J Strength Cond Res, 10.1519/JSC.0000000000002200 ; Lopez et al., 2021, Med Sci Sports Exerc, 10.1249/MSS.0000000000002585.
- **Au-delà des données** : au poids du corps, il règle la charge par la variante (levier, lest, élastique).

### R1-P12 — Pilotage par le RIR
- **Règle** : le RPE basé sur le RIR suit la vitesse de barre au squat : r = −0,88 chez les expérimentés (n = 15), r = −0,77 chez les novices (n = 14).
- **Par niveau** : débutant répétitions fixes et consigne simple, le RIR n'ajuste pas la charge ; intermédiaire RIR cible, ajustement si l'écart est ≥ 2 ; avancé autorégulation série par série ; élite série de calibration puis séries allégées.
- **Preuve** : étude de validation (n = 29) + avis d'experts — Zourdos et al., 2016, J Strength Cond Res, 10.1519/JSC.0000000000001049.
- **Au-delà des données** : il programme parfois une série à l'échec technique sur un exercice sûr pour recalibrer la perception.

### R1-P13 — Proximité de l'échec et hypertrophie
- **Règle** : l'hypertrophie augmente quand la série finit plus près de l'échec, mais l'atteindre n'apporte qu'un avantage trivial (0,19 ; IC 95 % 0,00 à 0,37), nul si l'échec est strict (0,12 ; p = 0,343). Seuil exact de RIR non établi.
- **Par niveau** : polyarticulaires / isolation : débutant 2–4 / 2–3 RIR ; intermédiaire 1–3 / 0–2 ; avancé 1–2 / 0–1, échec permis sur la dernière série ; élite 0–2 / 0–1, échec permis.
- **Preuve** : méta-analyses et méta-régression (RIR estimé après coup) — Refalo et al., 2023, Sports Med, 10.1007/s40279-022-01784-y ; Robinson et al., 2024, Sports Med, 10.1007/s40279-024-02069-2.
- **Au-delà des données** : il réserve l'échec à la dernière série d'exercices sûrs et l'interdit là où la chute est dangereuse.

### R1-P14 — Proximité de l'échec et force
- **Règle** : le gain de force a une relation négligeable avec le RIR ; échec contre non-échec : −0,09 (IC 95 % −0,22 à 0,05) ; à volume non égalisé, le non-échec fait mieux (−0,32 ; IC −0,57 à −0,07). Le rôle de la charge repose sur P11, pas sur ces sources.
- **Par niveau** : débutant 3–4 RIR ; intermédiaire 2–4 ; avancé 1–4 ; élite 1–3 ; échec interdit hors test ou compétition.
- **Preuve** : méta-analyses et méta-régression — Robinson et al., 2024, Sports Med, 10.1007/s40279-024-02069-2 ; Grgic et al., 2022, J Sport Health Sci, 10.1016/j.jshs.2021.01.007.
- **Au-delà des données** : sur les isométries, il arrête le maintien dès que la forme se dégrade, vers 70–90 % du temps maximal.

### R1-P15 — Repos et hypertrophie
- **Règle** : petit avantage à se reposer plus de 60 s (bras +0,13 ; cuisses +0,17), mais les intervalles de crédibilité incluent zéro ; pas de différence appréciable au-delà de 90 s. Plancher de 60 s : choix prudent, non seuil démontré.
- **Par niveau** : polyarticulaires / isolation, en secondes : débutant 90–120 / 60–90 ; intermédiaire 120–150 / 60–90 ; avancé 120–180 / 75–120 ; élite 150–180 / 90–120.
- **Preuve** : méta-analyse bayésienne + essai contrôlé — Singer et al., 2024, Front Sports Act Living, 10.3389/fspor.2024.1429789 ; Schoenfeld et al., 2016, J Strength Cond Res, 10.1519/JSC.0000000000001272.
- **Au-delà des données** : il utilise des supersets de muscles antagonistes pour raccourcir la séance sans réduire le repos réel.

### R1-P16 — Repos et force
- **Règle** : plus de 2 min de repos pour maximiser la force chez les sujets entraînés ; 60–120 s suffisent chez les non-entraînés. Essai : force supérieure avec 3 min qu'avec 1 min (+15,2 % contre +7,6 % au squat : non confirmé).
- **Par niveau** : travail principal / assistance, en secondes : débutant 120–180 / 90–120 ; intermédiaire 150–240 / 120 ; avancé 180–300 / 120–180 ; élite 180–300 ou plus / 120–180.
- **Preuve** : revue systématique sans méta-analyse + essai — Grgic et al., 2018, Sports Med, 10.1007/s40279-017-0788-x.
- **Au-delà des données** : il prescrit 2 à 5 minutes de repos complet sur les figures isométriques maximales (pratique gymnique, non testée).

### R1-P17 — Transposition au poids du corps
- **Règle** : à charge égale (40 % 1RM, 8 semaines), pompes et développé couché donnent des gains proches : +3,1 kg de 1RM (pompes) contre +5,0 kg (développé couché), épaisseur musculaire en hausse dans les deux groupes. Le moteur applique P1 à P16 en remplaçant le %1RM par la plage de répétitions et le RIR.
- **Par niveau** : débutant variante à 8–15 répétitions, 2–3 RIR, régression si < 5 ; intermédiaire 5–12, progression quand le haut de plage est atteint partout ; avancé lest ou levier pour 3–10 (force) ou 6–15 (hypertrophie) ; élite lest lourd 1–6, isométries de 5–15 s.
- **Preuve** : deux petits essais courts, niveau faible — Kikuchi & Nakazato, 2017, J Exerc Sci Fit, 10.1016/j.jesf.2017.06.003 ; Kotarsky et al., 2018, J Strength Cond Res, 10.1519/JSC.0000000000002345.
- **Au-delà des données** : il avance d'un seul palier de levier à la fois et garde du travail à amplitude complète.

### R1-P18 — Progression du volume et allègement
- **Règle** : aucune valeur issue des études ; pilotage individuel. Pendant l'allègement : moins de séries, même charge (P7).
- **Par niveau** : débutant aucune hausse tant que la progression continue, allègement si fatigue ; intermédiaire +1 à 2 séries/muscle au plus toutes les 2 semaines, 1 semaine sur 6–8 à 50–60 % du volume ; avancé +1 à 2 séries/muscle prioritaire/semaine sur 3–5 semaines, 1 semaine sur 4–6 à 50 % ; élite blocs de 4–6 semaines, 1 semaine sur 4–5.
- **Preuve** : pratique de terrain — aucune référence directe ; appui indirect de R1-P3 et R1-P7.
- **Au-delà des données** : il baisse le volume avant la charge, sur des signaux simples.

---

## R2 — Force maximale et techniques d'intensification

Niveaux : N0 débutant, N1–N2 intermédiaire, N3 avancé, N4 élite. Pourcentages sur la charge totale (R2-P4). Règles transposées du powerlifting : aucune étude ne porte sur la programmation du streetlifting.

### R2-P1 — Le 1RM se construit avec du lourd
- **Règle** : à effort égal, les charges > 60 % 1RM donnent plus de force que les charges légères (hypertrophie similaire) ; lourd et modéré battent léger (0,60–0,63 et 0,34–0,35) ; lourd contre modéré 0,26–0,28, non significatif.
- **Par niveau** : débutant 60–80 %, séries de 5–10, rien > 85 % ; intermédiaire 70–85 % puis au moins 1 exposition/sem ≥ 80 %, 85–90 % en fin de bloc ; avancé ≥ 85 % régulier ; élite 90–97 % en pic, reste du volume à 70–82 %.
- **Preuve** : méta-analyses — Schoenfeld et al., 2017, J Strength Cond Res, 10.1519/JSC.0000000000002200.
- **Au-delà des données** : séparer l'exposition au lourd du volume de construction ; ne pas alourdir tant que le geste se dégrade.

### R2-P2 — Zones d'intensité et table %1RM ↔ répétitions
- **Règle** : relation robuste en moyenne, variable entre individus (269 études). Table par défaut : 1 rep = 100 %, 2 = 94, 3 = 91, 5 = 86, 8 = 79, 10 = 75, 12 = 71 %. Zones : force ≥ 85 %, force/volume 75–85 %, hypertrophie 60–75 %.
- **Par niveau** : débutant zones 60–80 % ; intermédiaire jusqu'à 85 % (N1) puis toutes zones (N2) ; avancé et élite toutes zones.
- **Preuve** : méta-régression pour la relation, convention pour les zones — Nuzzo et al., 2024, Sports Med, 10.1007/s40279-023-01937-7.
- **Au-delà des données** : établir un profil par mouvement et recaler la table après chaque série maximale réelle.

### R2-P3 — Autorégulation RPE / RIR
- **Règle** : RPE 10 = 0 rep en réserve, 9 = 1, 8 = 2, 7 = 3. RPE et vitesse de barre : r = −0,88 (expérimentés), −0,77 (novices). RPE contre %1RM sur 8 semaines : squat +17,1 contre +13,9 kg, non significatif.
- **Par niveau** : débutant charges fixes, « 2–3 reps en réserve » ; intermédiaire plafond RPE 8 (N1), puis % + fourchette RPE, ±2,5 % si écart ≥ 1 point (N2) ; avancé et élite RPE pilote, top set à RPE 8–9,5.
- **Preuve** : validation + un essai contrôlé — Zourdos et al., 2016, J Strength Cond Res, 10.1519/JSC.0000000000001049.
- **Au-delà des données** : calibrer la RPE par vidéo (vitesse de la dernière rep).

### R2-P4 — Mouvements lestés : pourcentage sur la charge totale
- **Règle** : charge totale = lest + k × poids de corps ; k = 1,00 en traction, dips, muscle-up. Exemple : 80 kg, 1RM à +60 kg → total 140 kg ; 85 % = 119 kg → lest +39 kg. Squat k ≈ 0,88–0,90 : non confirmé, choix raisonné.
- **Par niveau** : identique pour tous ; débutant : lest calculé < 0 → mouvement assisté ; ensuite : progression calculée sur le total, poids de corps redemandé à chaque bloc.
- **Preuve** : mécanique, études descriptives — Sánchez-Moreno et al., 2017, Int J Sports Physiol Perform, 10.1123/ijspp.2016-0791.
- **Au-delà des données** : suivre séparément ratio lest/poids de corps et 1RM total ; figer la catégorie 3–4 semaines avant la compétition.

### R2-P5 — 1RM estimé : séries courtes seulement
- **Règle** : Epley (charge × (1 + reps/30)) ou Brzycki (charge × 36/(37 − reps)), sur la charge totale ; précision maximale à 5RM (R² 0,993 contre 0,955 à 20RM au développé) ; jamais > 10 reps. Aucune validation sur traction ou dips lestés : afficher ≥ ±3 %.
- **Par niveau** : débutant pas de 1RM vrai, estimation sur 5–8 reps ; intermédiaire estimation sur 3–5 reps, 1RM vrai en fin de bloc au plus ; avancé et élite estimation hebdomadaire sur top set, 1RM vrai en compétition.
- **Preuve** : études de validation (autres mouvements) — Reynolds et al., 2006, J Strength Cond Res, 10.1519/R-15304.1.
- **Au-delà des données** : ne comparer que des séries de même standard technique.

### R2-P6 — Top set + back-off
- **Règle** : chez des powerlifters, des simples à RPE 9–9,5 puis 2–3 back-offs à environ 80 % du simple suffisent à progresser en 6 semaines.
- **Par niveau** : débutant non ; intermédiaire 1 × 5 à RPE 8 + 2–3 séries à −10 % (N1), puis top set de 3–5 à RPE 8–9 + 2–4 back-offs à 88–92 % (N2) ; avancé et élite top set de 1–3 à RPE 8–9,5 + 2–5 back-offs à 80–90 %.
- **Preuve** : petites études, pratique de terrain — Androulakis-Korakakis et al., 2021, Front Sports Act Living, 10.3389/fspor.2021.713655.
- **Au-delà des données** : le top set sert de test du jour ; s'il est mauvais, réduire les back-offs.

### R2-P7 — Fréquence des mouvements de compétition
- **Règle** : effet sur la force 0,74 (1/sem) à 1,08 (≥ 4/sem), qui disparaît à volume égal (p = 0,421) : la fréquence sert à répartir le volume.
- **Par niveau** : débutant 2/sem ; intermédiaire 2 à 3/sem ; avancé et élite traction et dips 2–4, squat 2–3, muscle-up lesté 1–2.
- **Preuve** : méta-analyse — Grgic et al., 2018, Sports Med, 10.1007/s40279-018-0872-x.
- **Au-delà des données** : plafonner la fréquence par la tolérance tendineuse (coude, épaule), pas par la récupération musculaire.

### R2-P8 — Dose minimale et volume pour la force
- **Règle** : 1 série de 6–12 reps à 70–85 %, 2–3/sem, donne +12,1 kg de 1RM [IC 95 % 8,2–16,0] chez l'homme entraîné. Plancher powerlifters : 3–6 séries/sem de 1–5 reps à > 80 %.
- **Par niveau** (pratique de terrain) : débutant 4–8 séries/sem par mouvement ; intermédiaire 6–10 puis 8–14 ; avancé et élite 10–18, dont 3–6 à ≥ 85 %.
- **Preuve** : méta-analyse (petite) — Androulakis-Korakakis et al., 2020, Sports Med, 10.1007/s40279-019-01236-0.
- **Au-delà des données** : partir du plancher ; n'ajouter du volume que si la progression stagne.

### R2-P9 — Variantes et spécificité
- **Règle** : la force progresse surtout dans l'amplitude entraînée ; complet contre partiel : 0,12 [−0,02 ; 0,26]. Une variante ne modifie qu'une contrainte.
- **Par niveau** (part du mouvement exact) : débutant 100 % ; intermédiaire ≥ 80 % puis 60–75 % ; avancé et élite 50–70 % hors pic, ≥ 80 % les 3–4 dernières semaines.
- **Preuve** : méta-analyse + pratique de terrain — Wolf et al., 2023, Int J Strength Cond, 10.47206/ijsc.v3i1.182.
- **Au-delà des données** : supprimer une variante si, après 4–6 semaines, le mouvement de compétition ne progresse pas.

### R2-P10 — Affûtage et pic
- **Règle** : 1–2 semaines, volume −30 à −70 %, intensité maintenue ≥ 85 %, puis 2–7 jours d'arrêt (2–4 jours paraît optimal).
- **Par niveau** : débutant pas d'affûtage, semaine allégée (−30 à −40 %) avant un test ; intermédiaire 1 semaine à −40/−50 %, dernier lourd à J−5/J−4 ; avancé et élite 1–2 semaines à −50/−70 %, dernier lourd ≥ 90 % à J−7/J−5, repos 2–4 jours.
- **Preuve** : revues narratives — Travis et al., 2020, Sports, 10.3390/sports8090125.
- **Au-delà des données** : affûter plus longtemps les athlètes lourds ; rien de nouveau en semaine de pic.

### R2-P11 — Charge–vitesse en traction
- **Règle** : vitesse et charge relative r = −0,96 ; vitesse au 1RM ≈ 0,20 ± 0,05 m/s ; perte de vitesse et reps R² = 0,88. Seuil moteur ≤ 0,25 m/s ≈ 95 % : approximation.
- **Par niveau** : débutant non ; dès N2 : module optionnel, arrêt de série sur perte de vitesse ; sans capteur, RPE.
- **Preuve** : études descriptives sur la seule traction — Sánchez-Moreno et al., 2017, Int J Sports Physiol Perform, 10.1123/ijspp.2016-0791.
- **Au-delà des données** : ne pas extrapoler aux dips ; un profil par mouvement.

### Note — Littérature streetlifting
Rosaci et al., 2024 (Appl Sci, 10.3390/app14167172) : 79 athlètes ; tour de bras corrélé à la traction et aux dips (r partiel 0,47–0,60), masse grasse négativement (r = −0,42). Stranieri et al., 2026 (Nutrients, 10.3390/nu18010105) : rapport force/poids de corps déterminant, preuves spécifiques rares. Ngo et al., 2021 (Orthop J Sports Med, 10.1177/2325967121990926) : 93 pratiquants de street workout, 62,4 % blessés en 12 mois, tendinopathie 31,0 %.

### R2-P12 — Clusters
- **Règle** : en aigu, vitesse mieux préservée (0,60), effort perçu réduit (0,81) ; en chronique, force (−0,06) et hypertrophie (−0,03) identiques.
- **Par niveau** : débutant non ; intermédiaire dès N2, 4 × (2+2) à 85–88 %, 20–30 s ; avancé et élite 3–5 × (1+1+1) à 88–93 %, 15–30 s, blocs de 3–4 semaines.
- **Preuve** : méta-analyses — Jukic et al., 2020, Sports Med, 10.1007/s40279-020-01344-2.
- **Au-delà des données** : poser le lest à chaque pause et arrêter à la première rep ralentie.

### R2-P13 — Rest-pause et myo-reps
- **Règle** : 1RM équivalent ou supérieur au classique (squat, P = 0,001 sur 8 semaines), hypertrophie équivalente ; myo-reps sans étude contrôlée.
- **Par niveau** : débutant non ; intermédiaire dès N2, 1 série par groupe et par séance sur accessoires, 20 s, 2–3 relances ; avancé et élite jusqu'à 2 exercices par séance ; jamais sur muscle-up lesté ni top sets.
- **Preuve** : deux petits essais contrôlés — Prestes et al., 2019, J Strength Cond Res, 10.1519/JSC.0000000000001923 ; Enes et al., 2021, Appl Physiol Nutr Metab, 10.1139/apnm-2021-0278.
- **Au-delà des données** : compter une série rest-pause pour 2–3 séries dans le budget hebdomadaire.

### R2-P14 — Séries dégressives
- **Règle** : équivalent au classique (force 0,07 [−0,14 ; 0,29], hypertrophie 0,08) pour une séance réduite de moitié à deux tiers.
- **Par niveau** : débutant non ; intermédiaire 1 dégressif sur accessoire (N1), puis 1–2 exercices, 1–2 paliers de −20 à −25 % ; jamais en pic ni sur squat lourd.
- **Preuve** : deux méta-analyses — Coleman et al., 2022, Int J Strength Cond, 10.47206/ijsc.v2i1.135.
- **Au-delà des données** : l'employer quand la séance doit être courte, pas par défaut.

### R2-P15 — Supersets antagonistes
- **Règle** : volume équivalent, gain de temps net (1,74), effort perçu plus élevé (0,77), adaptations similaires.
- **Par niveau** : débutant oui sur accessoires, 60–90 s ; dès N2 : traction/dips lestés en paire à ≤ 85 % ; interdit sur top sets ≥ 88 % et en pic.
- **Preuve** : méta-analyse — Zhang et al., 2025, Sports Med, 10.1007/s40279-025-02176-8.
- **Au-delà des données** : vérifier que la prise ne limite pas la seconde moitié de la paire.

### R2-P16 — Isométrie
- **Règle** : la force progresse quelle que soit l'intensité ; le seuil ≥ 70 % ne vaut que pour l'adaptation du tendon ; à grande longueur musculaire, plus d'hypertrophie (0,86–1,69 contre 0,08–0,83 %/sem). Spécificité angulaire non confirmée ; doses = choix raisonné.
- **Par niveau** : débutant maintiens au poids de corps 3–5 × 10–30 s ; intermédiaire pauses de 1–3 s à 75–85 % ; avancé et élite 3–5 × 3–6 s à effort maximal, 1/sem, blocs de 3–4 semaines.
- **Preuve** : revue systématique (résumé seul) — Oranchuk et al., 2019, Scand J Med Sci Sports, 10.1111/sms.13375.
- **Au-delà des données** : plus de 8–10 % de charge perdue avec la pause désigne le point faible.

### R2-P17 — Excentriques accentués et négatives
- **Règle** : charge excentrique supérieure à la concentrique ; chez des hommes entraînés, +40 % en excentrique pendant 10 semaines donne plus de force, pas plus d'hypertrophie.
- **Par niveau** : débutant négatives au poids de corps 3–5 × 3–5 reps de 3–5 s ; intermédiaire excentrique de 4–5 s à 80–90 %, 2–3 × 3–4 ; avancé et élite 100–110 % du 1RM total, 2–4 × 1–3, 1/sem, jamais à moins de 10 jours d'une compétition.
- **Preuve** : revues + un essai contrôlé — Walker et al., 2016, Front Physiol, 10.3389/fphys.2016.00149.
- **Au-delà des données** : retirer la technique au premier signal tendineux.

### R2-P18 — Tempo
- **Règle** : excentrique contrôlée 2–3 s, concentrique aussi rapide que possible ; un tempo lent impose de réduire la charge.
- **Par niveau** : débutant descente imposée de 3 s ; intermédiaire, avancé, élite : tempo lent (4–6 s) en variante seulement, charge −10 à −20 %.
- **Preuve** : revue narrative — Wilk et al., 2021, Sports Med, 10.1007/s40279-021-01465-2.
- **Au-delà des données** : utiliser le tempo pour corriger un défaut, puis l'enlever.

### R2-P19 — Potentialisation, contrastes, vagues
- **Règle** : effet petit sur des gestes balistiques (saut 0,29, sprint 0,51) ; rien de démontré sur le 1RM ; vagues = pratique de terrain.
- **Par niveau** : débutant et intermédiaire non ; avancé et élite contraste 1–3 reps à 85–90 % puis geste explosif après 4–8 min ; vagues 3-2-1 à 85/88/91 % en pic.
- **Preuve** : méta-analyse (balistique) — Seitz & Haff, 2016, Sports Med, 10.1007/s40279-015-0415-7.
- **Au-delà des données** : réserver ces schémas à l'athlète dont la technique ne varie plus.

### R2-P20 — Séries « plus » et proximité de l'échec
- **Règle** : la force progresse autant loin que près de l'échec ; viser 1–4 reps en réserve sur le travail ≥ 80 %.
- **Par niveau** : débutant jamais d'échec ; intermédiaire série « plus » à 1 rep en réserve dès N1, 1 par mouvement et par semaine, échec vrai sur accessoires dès N2 ; pas d'échec sur muscle-up lesté ni squat lourd.
- **Preuve** : méta-régressions — Robinson et al., 2024, Sports Med, 10.1007/s40279-024-02069-2.
- **Au-delà des données** : l'échec est l'échec technique ; noter les reps validées.

### R2-P21 — Partielles en position étirée
- **Règle** : complet contre partiel : 0,12 [−0,02 ; 0,26] ; tendance incertaine pour les partielles étirées en hypertrophie (−0,28 [−0,81 ; 0,16]).
- **Par niveau** : débutant amplitude complète seulement ; intermédiaire dès N2, 4–8 partielles en fin de série sur accessoires ; mouvements de compétition toujours complets.
- **Preuve** : méta-analyse — Wolf et al., 2023, Int J Strength Cond, 10.47206/ijsc.v3i1.182.
- **Au-delà des données** : outil d'hypertrophie locale, sans transfert démontré sur le 1RM.

### R2-P22 — Matrice d'accès et budget de techniques
- **Règle** : aucune technique ne donne plus de force que le classique à volume égal (clusters −0,06 ; dégressif 0,07). Budget : 1 technique par mouvement, 2 par séance (N2), 3 (N3–N4) ; une série intensifiée compte pour 1,5–3 séries.
- **Par niveau** : débutant supersets d'accessoires, tempo, négatives ; intermédiaire série « plus », top set, dégressif (N1), puis clusters, rest-pause, partielles (N2) ; avancé et élite excentrique surchargé, contrastes, vagues.
- **Preuve** : méta-analyses + pratique de terrain — Jukic et al., 2021, Sports Med, 10.1007/s40279-020-01423-4.
- **Au-delà des données** : une technique répond à un problème nommé, puis se retire.

---

## R3 — Périodisation, décharges, affûtage et pic de forme

42 références : 40 confirmées, 2 complétées à la seconde vérification. Aucune étude ne porte sur la traction lestée, les dips lestés, le muscle-up ou le sets & reps : toute règle pour ces mouvements est une transposition. « Non confirmé » = chiffre non retrouvé à la seconde vérification (texte intégral non consulté).

### R3-P1 — Périodiser : petit gain de force, pas d'hypertrophie
- **Règle** : à volume égal, périodiser donne un peu plus de force (effet 0,31 ; IC 95 % 0,04–0,57), rien de démontré en hypertrophie (0,13 ; IC −0,10 à 0,36).
- **Par niveau** : débutant variation facultative, la surcharge progressive suffit ; intermédiaire varier les zones de répétitions ; avancé et élite périodisation obligatoire dès qu'il y a une échéance.
- **Preuve** : méta-analyse — Moesgaard et al., 2022, Sports Med, 10.1007/s40279-021-01636-1 ; Williams et al., 2017, Sports Med, 10.1007/s40279-017-0734-y.
- **Au-delà des données** : outil de gestion de la fatigue et du calendrier ; volume, effort et assiduité pèsent plus.

### R3-P2 — Débutant : progression linéaire simple
- **Règle** : chez les non entraînés, linéaire et ondulatoire se valent (0,06 ; IC −0,20 à 0,31). Cycle de 8–12 semaines en double progression, puis test.
- **Par niveau** : débutant ni blocs ni affûtage ; passage à intermédiaire après 2–3 échecs de progression malgré une décharge (critère de terrain) ; avancé et élite sans objet.
- **Preuve** : méta-analyse — Moesgaard et al., 2022 ; Harries et al., 2015, JSCR, 10.1519/JSC.0000000000000712.
- **Au-delà des données** : il garde les mêmes exercices jusqu'à ce que la technique soit stable.

### R3-P3 — Entraîné : l'ondulation fait au moins aussi bien
- **Règle** : ondulatoire contre linéaire, 0,31 (IC 0,02–0,61) tous niveaux ; 0,61 chez les entraînés mais l'intervalle touche zéro (0,00–1,22 ; p = 0,05) : avantage probable, non établi. Hypertrophie : aucune différence.
- **Par niveau** : débutant non ; intermédiaire 2–3 zones (3–5, 6–8, 8–12 répétitions), 2–3 expositions par mouvement et par semaine ; avancé et élite ondulation à l'intérieur des blocs.
- **Preuve** : méta-analyses partiellement contradictoires + essai — Moesgaard et al., 2022 ; Rhea et al., 2002, JSCR, PMID 11991778.
- **Au-delà des données** : séance lourde le jour le plus frais, jours légers consacrés à la technique.

### R3-P4 — Blocs pour les avancés avec échéance
- **Règle** : accumulation 3–6 sem. (6–12 rép.) → transmutation 3–4 sem. (2–5 rép., 80–92 %) → réalisation 1–2 sem. ; décharge à chaque jonction. Durées attribuées à Issurin non confirmées : valeurs de terrain.
- **Par niveau** : débutant jamais ; intermédiaire optionnel, 2 phases de 4–6 sem. ; avancé et élite schéma complet.
- **Preuve** : revue narrative + un essai (pas de supériorité démontrée en force) — Issurin, 2010, Sports Med, 10.2165/11319770-000000000-00000.
- **Au-delà des données** : il garde un rappel des qualités non ciblées dans chaque bloc.

### R3-P5 — Méthode conjuguée : pratique de coach
- **Règle** : aucune étude vérifiée ne l'isole ; jamais modèle par défaut, jamais présentée comme prouvée.
- **Par niveau** : débutant exclu ; intermédiaire exclu par défaut ; avancé et élite option hors période de compétition.
- **Preuve** : pratique de terrain — par analogie Afonso et al., 2019, Front Physiol, 10.3389/fphys.2019.01023.
- **Au-delà des données** : il fait tourner les variantes d'un mouvement toutes les 1–3 semaines.

### R3-P6 — Le plan est une hypothèse révisable
- **Règle** : la recherche soutient la variation, pas spécifiquement la variation périodisée ; le moteur recalcule charges et volume d'après les séances réalisées, sans promettre de gain lié au modèle.
- **Par niveau** : identique du débutant à l'élite.
- **Preuve** : revue de méta-analyses + opinion argumentée — Afonso et al., 2019 ; Kiely, 2018, Sports Med, 10.1007/s40279-017-0823-y.
- **Au-delà des données** : il change le plan dès que les séances le contredisent, et note pourquoi.

### R3-P7 — Autorégulation par RPE/RIR
- **Règle** : fait au moins aussi bien que le pourcentage fixe ; effet groupé non significatif (+2,07 kg au 1RM ; IC −0,32 à 4,46 ; première vérification seule).
- **Par niveau** : débutant charge prescrite et règle d'ajout simple ; intermédiaire fourchette de RIR (2–3 en accumulation), ajustement ±2,5–5 % ; avancé et élite RIR 1–3, série de tête puis retrait de 5–10 %, RIR 0–1 réservé aux tests.
- **Preuve** : essais + revue systématique + méta-analyse — Helms et al., 2018, Front Physiol, 10.3389/fphys.2018.00247 ; Hickmott et al., 2022, Sports Med Open, 10.1186/s40798-021-00404-9.
- **Au-delà des données** : il contrôle le RIR déclaré par des séries tests.

### R3-P8 — Vitesse d'exécution
- **Règle** : perte de vitesse ≤ 25 % associée à un meilleur gain de 1RM (+2,32 kg ; IC 0,33–4,31 ; première vérification seule). Non validé sur traction et dips lestés.
- **Par niveau** : débutant non ; intermédiaire facultatif ; avancé et élite avec capteur, arrêt à 10–20 % de perte en force, 20–30 % en accumulation (découpage de terrain).
- **Preuve** : revue + méta-analyse — Weakley et al., 2021, SCJ, 10.1519/SSC.0000000000000560 ; Hickmott et al., 2022.
- **Au-delà des données** : la vitesse sur une charge repère d'échauffement lui donne la forme du jour.

### R3-P9 — Décharge
- **Règle** : environ 7 jours toutes les 4–6 semaines (enquête : 6,4 ± 1,7 jours toutes les 5,6 ± 2,3 sem.), par baisse du volume et éloignement de l'échec. Valeurs de terrain : séries −40 à −50 %, charge maintenue ou −5 à −10 %, RIR ≥ 4.
- **Par niveau** : débutant réactive seulement ; intermédiaire toutes les 5–6 sem. ; avancé et élite toutes les 4–5 sem. (3–4 en phase très lourde).
- **Preuve** : consensus d'experts + enquête, aucun essai sur la fréquence — Bell et al., 2023, Sports Med Open, 10.1186/s40798-023-00633-0 ; Rogerson et al., 2024, Sports Med Open, 10.1186/s40798-024-00691-y.
- **Au-delà des données** : il la cale sur la vie réelle et l'avance au premier signal de P11.

### R3-P10 — Une décharge n'est pas un arrêt
- **Règle** : une semaine d'arrêt complet au milieu de 9 semaines (39 sujets) n'apporte rien et réduit les gains de force du bas du corps.
- **Par niveau** : du débutant à l'élite, la décharge garde l'entraînement ; arrêt complet réservé à la transition (P19) et à l'avant-compétition (P14).
- **Preuve** : un essai contrôlé — Coleman et al., 2024, PeerJ, 10.7717/peerj.16777.
- **Au-delà des données** : il emploie cette semaine pour la technique légère et la mobilité.

### R3-P11 — Surmenage
- **Règle** : seul marqueur établi, une baisse durable de performance. Alerte : baisse sur 2 séances consécutives ou RIR dégradé de ≥ 2 points à charge égale → décharge de 5–7 jours ; persistance après 2 semaines → professionnel de santé. Seuils de terrain ; durées de Meeusen non confirmées.
- **Par niveau** : mêmes seuils pour tous ; débutant, une stagnation est d'abord un problème de récupération ou de technique.
- **Preuve** : revue systématique + consensus — Grandou et al., 2020, Sports Med, 10.1007/s40279-019-01242-2 ; Meeusen et al., 2013, MSSE, 10.1249/MSS.0b013e318279a10a.
- **Au-delà des données** : sommeil, humeur, envie et douleurs de coude ou d'épaule précèdent souvent la baisse.

### R3-P12 — Affûtage de force maximale
- **Règle** : 1–2 semaines, volume −30 à −70 % (−30 à −50 % semble le plus efficace en force athlétique), intensité ≥ 85 % du 1RM ; méta-analyse tous sports : 2 semaines, −41 à −60 % exponentiel.
- **Par niveau** : débutant 3–5 jours allégés (−30 %) ; intermédiaire 1 sem., −30 à −40 % ; avancé 1–2 sem., −40 à −50 % puis −50 à −60 % ; élite 2 sem. (3 après surcharge), −40 à −60 % exponentiel.
- **Preuve** : méta-analyse (endurance surtout) + revue + enquêtes — Bosquet et al., 2007, MSSE, 10.1249/mss.0b013e31806010e0 ; Travis et al., 2020, Sports, 10.3390/sports8090125.
- **Au-delà des données** : plus court pour l'athlète léger, plus long pour le lourd ; il repart du pic précédent.

### R3-P13 — Garder l'intensité et la fréquence, couper les séries
- **Règle** : intensité et fréquence inchangées (fréquence −20 % au plus) ; réduire d'abord les séries (−40 à −60 %), puis les accessoires ; jamais sous 85 % sur les séries principales avant la dernière séance.
- **Par niveau** : débutant sans objet ; intermédiaire, avancé et élite au plus une séance retirée la dernière semaine.
- **Preuve** : méta-analyse + enquêtes — Bosquet et al., 2007 ; Mujika & Padilla, 2003, MSSE, 10.1249/01.MSS.0000074448.73931.11.
- **Au-delà des données** : horaires, ordre et commandements de la compétition, en répétition générale.

### R3-P14 — Dernier lourd, dernière séance, arrêt
- **Règle** : dernier lourd (≥ 90 %, sans échec) à J−7 à J−10, dernière séance à J−3 ou J−4, arrêt complet de 2–4 jours (5 au plus). Correction : la force maximale baisse de 1 à 4 % dès que l'arrêt dépasse 7 jours (Travis 2020), et non 14.
- **Par niveau** : débutant 2 jours de repos ; intermédiaire dernier lourd à J−5 à J−7, repos 2 jours ; avancé et élite comme la règle, dips lestés à J−5 à J−7 (analogie de terrain).
- **Preuve** : enquêtes + 2 petits essais + revues — Grgic & Mikulic, 2017, JSCR, 10.1519/JSC.0000000000001699 ; Pritchard et al., 2015, SCJ, 10.1519/SSC.0000000000000125 ; Travis et al., 2020.
- **Au-delà des données** : le dernier lourd fixe la première barre, il ne sert pas à battre un record.

### R3-P15 — Surcharge avant l'affûtage
- **Règle** : option d'une semaine à S−3 (volume +20 à +30 %, valeur de terrain), suivie de 2 semaines d'affûtage ; annulée si un signal de P11 est présent.
- **Par niveau** : débutant et intermédiaire jamais ; avancé pic de volume à S−5/S−6 sans surcharge ; élite option.
- **Preuve** : revue + enquêtes, preuve expérimentale faible — Travis et al., 2020 ; Bell et al., 2020, J Sports Sci, 10.1080/02640414.2020.1763077.
- **Au-delà des données** : seulement si la réponse de l'athlète est connue, jamais avant une première compétition.

### R3-P16 — Test du 1RM
- **Règle** : test fiable (corrélation intraclasse médiane 0,97 ; coefficient de variation médian 4,2 %). Progrès réel seulement au-delà d'environ 5 % ou confirmé sur 2 mesures : seuil de terrain, inférieur au changement minimal détectable (environ 11–12 % entre deux mesures). Protocole NSCA non vérifié.
- **Par niveau** : débutant 1RM estimé (série de 3–8) toutes les 4–6 sem. ; intermédiaire 1RM vrai toutes les 8–12 sem. après décharge ; avancé et élite 2–4 par an, compétitions comprises.
- **Preuve** : revue systématique — Grgic et al., 2020, Sports Med Open, 10.1186/s40798-020-00260-z.
- **Au-delà des données** : il teste dans les conditions du règlement.

### R3-P17 — Tests du sets & reps
- **Règle** : répétitions maximales toutes les 4–6 semaines ; circuit complet au plus toutes les 3–4 semaines, jamais dans les 7–10 derniers jours (P21) ; conditions standardisées.
- **Par niveau** : débutant répétitions maximales seules ; intermédiaire, avancé et élite répétitions maximales + circuit chronométré.
- **Preuve** : pratique de terrain — aucune référence vérifiée.
- **Au-delà des données** : il compte à part les répétitions refusées.

### R3-P18 — Plusieurs échéances
- **Règle** : 2–3 pics majeurs par an, espacés d'au moins 10–12 semaines ; compétition secondaire = mini-affûtage de 3–5 jours (−30 %). Effets résiduels d'Issurin non confirmés : espacement et rappels (endurance de force tous les 10–15 jours) sont des choix raisonnés.
- **Par niveau** : débutant aucun pic, 1 test par cycle ; intermédiaire 1–2 par an ; avancé et élite 2–3 par an.
- **Preuve** : revue narrative + revue des doses minimales — Issurin, 2010 ; Spiering et al., 2021, JSCR, 10.1519/JSC.0000000000003964.
- **Au-delà des données** : une échéance prioritaire choisie, les autres acceptées en dessous.

### R3-P19 — Transition après un pic
- **Règle** : 5–7 jours de repos relatif, puis 1–2 semaines actives (RIR ≥ 4, volume ~50 %). Règle corrigée : arrêt complet de 7 jours au plus par défaut (au-delà, −1 à −4 % de force maximale), 14 jours au maximum (déclin plus rapide à partir de 15 jours, Bosquet 2013 cité par Travis 2020).
- **Par niveau** : débutant une semaine légère ; intermédiaire, avancé et élite 1–2 sem. actives ; sets & reps 7–10 jours (choix raisonné).
- **Preuve** : revue + méta-analyse — Travis et al., 2020 ; Bosquet et al., 2013, Scand J Med Sci Sports, 10.1111/sms.12047.
- **Au-delà des données** : il y traite les douleurs chroniques et la technique, sans tout couper.

### R3-P20 — Construire l'endurance de force
- **Règle** : aller vers le spécifique : force de base 4–6 sem. → capacité 3–5 sem. → circuits spécifiques 2–4 sem. → affûtage. Linéaire inversé 73 % contre 56 % et 55 %, non significatif (p = 0,58).
- **Par niveau** : débutant 2–3 séries à RIR 1–2, progression en répétitions totales ; intermédiaire, avancé et élite les trois phases.
- **Preuve** : un essai non significatif, transposition de terrain — Rhea et al., 2003, JSCR, PMID 12580661.
- **Au-delà des données** : il travaille le fractionnement et les transitions, qui font le chrono.

### R3-P21 — Affûtage d'une compétition chronométrée
- **Règle** : 8–14 jours, volume −40 à −60 %, allure de compétition gardée sur fractions courtes ; dernier circuit complet à J−7 à J−10 ; repos complet 1–2 jours. Transposition non validée ; la force « sous-maximale » de Bosquet 2013 est assimilée ici à l'endurance de force.
- **Par niveau** : débutant 3–5 jours allégés ; intermédiaire 7 jours, −40 % ; avancé et élite comme la règle.
- **Preuve** : méta-analyse sur d'autres disciplines — Bosquet et al., 2007 ; Bosquet et al., 2013.
- **Au-delà des données** : il surveille la peau des mains et les tendons autant que la fatigue.

---

## R4 — Figures et skills, endurance de force, spécialisation

67 références : 62 confirmées, 2 complétées, 3 ajoutées à la seconde vérification.

### R4-F1 — Pratique distribuée
- **Règle** : juger sur la rétention (premier essai de la séance suivante), pas sur la séance ; pratique espacée > massée, d = 0,46 (63 études).
- **Par niveau** : équilibre/coordination : débutant 3–4/sem × 5–10 min ; intermédiaire 4–5 × 10–15 min ; avancé et élite 5–6 × 10–20 min, à l'état frais.
- **Preuve** : méta-analyse, transposée — Donovan & Radosevich, 1999, J Appl Psychol, 10.1037/0021-9010.84.5.795
- **Au-delà des données** : couper dès deux essais dégradés de suite.

### R4-F2 — Maintiens sous-maximaux
- **Règle** : séries à 50–70 % du max hold, arrêt à la perte de ligne. L'échec n'ajoute pas de force (ES −0,09) ; en tractions, s'arrêter tôt améliore force et vitesse, pas le max de répétitions.
- **Par niveau** : débutant 20–40 s cumulées, jamais d'échec ; intermédiaire 30–60 s, test toutes les 3–4 sem ; avancé 40–60 s ; élite 40–75 s, essai max toutes les 1–2 sem.
- **Preuve** : pratique de terrain pour les chiffres ; appui transposé — Grgic et al., 2022, J Sport Health Sci, 10.1016/j.jshs.2021.01.007 ; Sánchez-Moreno et al., 2020, JSCR, 10.1519/JSC.0000000000003500
- **Au-delà des données** : ne compter que les secondes propres.

### R4-F3 — Variabilité
- **Règle** : l'entrelacement aide la rétention en laboratoire, effet « presque négligeable » sur le terrain (54 études).
- **Par niveau** : débutant en bloc ; intermédiaire bloc + alternance de 2 skills non concurrents ; avancé et élite 20–30 % d'essais variés.
- **Preuve** : méta-analyse, transposée — Czyż et al., 2024, Sci Rep, 10.1038/s41598-024-65753-3
- **Au-delà des données** : varier l'entrée et la sortie plutôt que la position tenue.

### R4-F4 — Focus externe
- **Règle** : consignes sur l'effet du geste (« repousse le sol »), une seule par série.
- **Par niveau** : identique pour tous ; consignes internes réservées à l'explication initiale du débutant.
- **Preuve** : revue (non relue à la seconde vérification) — Wulf, 2013, Int Rev Sport Exerc Psychol, 10.1080/1750984X.2012.723728
- **Au-delà des données** : choisir la consigne d'après l'erreur vue en vidéo, la changer toutes les 2–3 sem.

### R4-F5 — Spécificité d'angle
- **Règle** : gains isométriques spécifiques à l'angle ; hypertrophie de 0,86–1,69 %/sem à grande longueur contre 0,08–0,83 à longueur courte. Entraîner la position exacte, compléter en dynamique ample.
- **Par niveau** : part dynamique/statique : débutant 60–70/30–40 ; intermédiaire 50/50 ; avancé et élite 30–40/60–70.
- **Preuve** : revue systématique et essais, transposés à l'épaule — Oranchuk et al., 2019, Scand J Med Sci Sports, 10.1111/sms.13375
- **Au-delà des données** : maintiens partiels sur l'angle faible.

### R4-F6 — Durée et intensité des contractions
- **Règle** : à 70 %, contractions longues > courtes (force +54,7 % contre +31,5 %, n = 7) ; raideur tendineuse 67,5 → 106,2 N/mm avec 4 × 20 s ; ≥ 70 % pour le tendon. Levier utile : max hold de 8–25 s.
- **Par niveau** : débutant séries de 10–20 s ; intermédiaire idem + 1 séance de 4–8 s ; avancé et élite alternance des deux.
- **Preuve** : essais de 7–8 sujets sur quadriceps, transposés — Schott et al., 1995, Eur J Appl Physiol, 10.1007/BF00240414 ; Kubo et al., 2001, J Appl Physiol, 10.1152/jappl.2001.91.1.26
- **Au-delà des données** : à 25–30 s de max hold, durcir le levier.

### R4-F7 — Progression par leviers
- **Règle** : la progression par levier fonctionne (+39,2 % tractions, +16,4 % pompes en 8 sem ; élite +3,6 à +4,1 % en 4 sem) ; aucun critère de passage validé. Passage : 3 séries propres sur 3 séances, sans douleur, par demi-pas.
- **Par niveau** : débutant et intermédiaire 3 × 10–15 s ; avancé et élite 3 × 8–10 s ; 2–3 sem de chevauchement.
- **Preuve** : essais pour le principe, pratique de terrain pour les critères — Thomas et al., 2017, Isokinet Exerc Sci, 10.3233/IES-170001 ; Schärer et al., 2019, IJERPH, 10.3390/ijerph16224571
- **Au-delà des données** : plus de demi-pas pour l'athlète grand ou lourd du bas.

### R4-F8 — Tendon et charges élevées
- **Règle** : raideur SMD 0,70 puis 0,74 ; l'effet dépend de l'intensité, plus grand à ≥ 12 sem ; forte contre faible déformation SMD 0,82 et 1,04 (et non 0,90). Protocole « 5 × 4 × 3 s à 85–90 % » non confirmé.
- **Par niveau** : bloc tendineux de 8–12 sem, 2–3 séances/sem, avant la première figure bras tendus (débutant) et avant chaque passage (intermédiaire, avancé).
- **Preuve** : méta-analyses sur le membre inférieur, transposées — Bohm et al., 2015, Sports Med Open, 10.1186/s40798-015-0009-9 ; Lazarczuk et al., 2022, Sports Med, 10.1007/s40279-022-01695-y
- **Au-delà des données** : préparer coude et biceps des mois avant supination et anneaux.

### R4-F9 — Décalage muscle–tendon
- **Règle** : force +29,6 % à 2 mois, raideur et section inchangées avant le 3ᵉ mois (n = 8). Un seul changement à la fois, au plus toutes les 2 sem ; max hold > +30 % en 4 sem → geler 4 sem.
- **Par niveau** : délai minimal par levier : débutant 12 sem ; intermédiaire 8–12 ; avancé 8 ; élite 6–8.
- **Preuve** : essai transposé + pratique de terrain ; désentraînement non confirmé — Kubo et al., 2010, JSCR, 10.1519/JSC.0b013e3181c865e2
- **Au-delà des données** : plus prudent avec les athlètes venus de la musculation et les adolescents.

### R4-F10 — Espacement des charges tendineuses
- **Règle** : synthèse de collagène élevée de 24 à 72 h ; in vitro, tissu réfractaire après 10 min, resensibilisé en 6 h. Planche et back lever partagent un budget.
- **Par niveau** : séances lourdes par zone : débutant 2/sem non consécutives ; intermédiaire 2–3 (≥ 48 h) ; avancé 3 ; élite 3–4.
- **Preuve** : observationnel + in vitro, preuve faible — Miller et al., 2005, J Physiol, 10.1113/jphysiol.2005.093690 ; Baar, 2017, Sports Med, 10.1007/s40279-017-0719-x
- **Au-delà des données** : raisonner sur 4 semaines glissantes.

### R4-F11 — Douleur tendineuse
- **Règle** : adapter la charge, ni repos complet ni forcing. 1–3/10 : maintenir ; 4–5/10 : reculer d'un levier, −30 à −50 % de volume ; > 5/10, douleur nocturne ou perte de force : arrêt et professionnel de santé. Seuils = choix raisonné (5/10 non confirmé).
- **Par niveau** : mêmes seuils pour tous.
- **Preuve** : modèle, revue systématique, petits essais sur le membre inférieur — Silbernagel et al., 2007, Am J Sports Med, 10.1177/0363546506298279 ; Rio et al., 2015, Br J Sports Med, 10.1136/bjsports-2014-094386
- **Au-delà des données** : retirer le seul déclencheur, garder l'athlète actif.

### R4-F12 — Zones à risque
- **Règle** : street workout : 62,4 % de blessés sur 12 mois, tendinopathie en tête (93 pratiquants). Gymnastes : 8,78 blessures/1000 expositions (hommes). Préparation des poignets 5 min avant handstand et planche.
- **Par niveau** : débutant ni anneaux ni supination bras tendus ; intermédiaire supination en tuck après un bloc tendineux ; avancé et élite autorisés, budget commun.
- **Preuve** : observationnel — Ngo et al., 2021, Orthop J Sports Med, 10.1177/2325967121990926 ; Westermann et al., 2015, Sports Health, 10.1177/1941738114559705
- **Au-delà des données** : la mobilité est un prérequis.

### R4-G1 — Continuum force–endurance
- **Règle** : lourd : force +20 % mais endurance relative −7 % ; répétitions élevées : +22 à +28 % ; endurance absolue +28 à +41 % partout. ≥ 50 % du bloc spécifique dans la zone de l'épreuve.
- **Par niveau** : force/endurance : débutant 70/30 ; intermédiaire 50/50 ; avancé 40/60 ; élite 25/75.
- **Preuve** : essais contrôlés — Anderson & Kearney, 1982, Res Q Exerc Sport, 10.1080/02701367.1982.10605218 ; Campos et al., 2002, Eur J Appl Physiol, 10.1007/s00421-002-0681-6
- **Au-delà des données** : densité pour le « fort mais court », lest pour l'« endurant mais faible ».

### R4-G2 — Force relative
- **Règle** : à charge absolue, les répétitions suivent la force max (r = 0,83) ; les tractions baissent avec la masse (r = −0,55), sans lien avec le 1RM absolu.
- **Par niveau** : max < 8 : priorité force ; 8–15 : mixte ; > 15–20 : endurance spécifique + 1 séance lourde/sem.
- **Preuve** : observationnel — Naclerio et al., 2009, JSCR, 10.1519/JSC.0b013e3181a4e71f ; Sánchez-Moreno et al., 2016, J Sports Med Phys Fitness
- **Au-delà des données** : suivre le rapport 1RM lesté / max de répétitions.

### R4-G3 — Échec
- **Règle** : pas plus de force (ES −0,09), récupération ralentie de 24–48 h ; il aide les répétitions pendant l'entraînement, pas pendant l'affûtage. ≥ 48 h après une séance à l'échec.
- **Par niveau** : marge : débutant 3–4 répétitions, aucun échec ; intermédiaire 2–3, ≤ 1 série ; avancé 1–3, 1–2 séries ; élite simulations 1×/sem en bloc spécifique, aucune en affûtage.
- **Preuve** : méta-analyse + essais — Grgic et al., 2022, 10.1016/j.jshs.2021.01.007 ; Izquierdo et al., 2006, J Appl Physiol, 10.1152/japplphysiol.01400.2005
- **Au-delà des données** : n'entraîner que l'échec technique.

### R4-G4 — Repos
- **Règle** : lourd 2,5–4 min ; endurance 20–90 s (borne basse non confirmée) ; changer une seule variable à la fois.
- **Par niveau** : débutant ≥ 90 s ; intermédiaire 45–90 s ; avancé et élite 15–60 s, micro-pauses 5–15 s.
- **Preuve** : revues + essai — Schoenfeld et al., 2016, JSCR, 10.1519/JSC.0000000000001272
- **Au-delà des données** : chronométrer les repos.

### R4-G5 — Sous-maximal fréquent
- **Règle** : 4–8 séries/jour à 40–60 % du max, 4–5 j/sem, blocs de 3–4 sem ; aucun essai.
- **Par niveau** : débutant et intermédiaire (max 3–12) ; avancé et élite : volume technique seulement.
- **Preuve** : pratique de terrain, appui indirect affaibli — Tsatsouline, 2003
- **Au-delà des données** : débloquer un plateau, puis passer à la densité.

### R4-G6 — Densité
- **Règle** : cluster : SMD 0,70 en aigu (analyse par charges) ; rest-pause : endurance +27 % contre +8 %, significatif à la presse à cuisses seulement ; EMOM à 30–50 % du max.
- **Par niveau** : débutant EMOM 30 % ; intermédiaire 40 %, échelles, cluster ; avancé et élite 40–50 %, rest-pause 1–2×/sem.
- **Preuve** : méta-analyse aiguë, petit essai, pratique de terrain — Latella et al., 2019, Sports Med, 10.1007/s40279-019-01172-z ; Prestes et al., 2019, JSCR, 10.1519/JSC.0000000000001923
- **Au-delà des données** : format choisi d'après le point de rupture.

### R4-G7 — Format de compétition
- **Règle** : pas d'échec avant la dernière série ; première série à 60–70 % du max ; pauses de 5–20 s planifiées ; affûtage −40 à −60 % de volume sur 5–10 j.
- **Par niveau** : simulations : débutant 3 avant toute compétition ; intermédiaire toutes les 3–4 sem ; avancé toutes les 2 sem ; élite 1/sem, dernière 7–10 j avant.
- **Preuve** : transposé + pratique de terrain — Sánchez-Moreno et al., 2017, IJSPP, 10.1123/ijspp.2016-0791
- **Au-delà des données** : plan écrit d'après les vidéos, avec plan B.

### R4-G8 — Max de tractions et de pompes
- **Règle** : non-entraînés +39,2 % en 8 sem ; entraînés +15 % en 12 sem ; séries arrêtées tôt : plus de force, max de répétitions équivalent. +10–20 % de volume par bloc.
- **Par niveau** : fréquence : débutant 2–3/sem ; intermédiaire 3 ; avancé 3–4 ; élite 4–5.
- **Preuve** : petits essais — Thomas et al., 2017, 10.3233/IES-170001 ; Sánchez-Moreno et al., 2020, 10.1519/JSC.0000000000003500
- **Au-delà des données** : standardiser la répétition dès le premier jour.

### R4-H1 — Maintien du reste
- **Règle** : 1/3 du volume conserve masse et force jusqu'à 32 sem chez les jeunes si l'intensité est gardée ; on retire des séries, pas de la difficulté.
- **Par niveau** : intermédiaire 1/2 ; avancé 1/3–1/2 ; élite 1/3 ; plus de 40–50 ans 1/2 ; plancher 1 exposition/sem.
- **Preuve** : essais + revue, transposés — Bickel et al., 2011, MSSE, 10.1249/MSS.0b013e318207c15d ; Spiering et al., 2021, JSCR, 10.1519/JSC.0000000000003964
- **Au-delà des données** : tester le maintien toutes les 4 sem.

### R4-H2 — Volume ciblé
- **Règle** : +20 % du volume antérieur de l'athlète > volume standard (1,08 cm², IC 0,04–2,11) ; plateau aux doses hautes ; volume prélevé sur le reste.
- **Par niveau** : débutant aucun ; intermédiaire +20 % ; avancé et élite +20 % puis +10–20 % toutes les 2 sem.
- **Preuve** : petits essais (hypertrophie), transposés — Scarpelli et al., 2022, JSCR, 10.1519/JSC.0000000000003558 ; Enes et al., 2024, MSSE, 10.1249/MSS.0000000000003317
- **Au-delà des données** : monter la fréquence avant les séries.

### R4-H3 — Durée du bloc
- **Règle** : aucune étude ne compare des durées ; figure bras tendus ≥ 8 sem (≥ 12 au premier passage) ; allègement toutes les 3–5 sem ; sortie par paliers de +20 %/sem.
- **Par niveau** : débutant aucune spécialisation ; intermédiaire 6–8 sem ; avancé 8–12 ; élite 8–16.
- **Preuve** : pratique de terrain bornée par les essais — Bohm et al., 2015, 10.1186/s40798-015-0009-9
- **Au-delà des données** : arrêter sur un critère, pas sur le calendrier.

### R4-H4 — Réallocation
- **Règle** : on déplace du volume, on n'en ajoute pas ; deux cibles ne chargent jamais le même maillon.
- **Par niveau** : débutant 0–1 figure bras tendus ; intermédiaire 1 cible, 2 figures de familles différentes ; avancé 1 + 1 ; élite selon la date.
- **Preuve** : consensus d'experts borné par les essais — Bickel et al., 2011, 10.1249/MSS.0b013e318207c15d
- **Au-delà des données** : exiger 8–12 sem de programme général avant de spécialiser.

---

## R5 — Débutants et retours de pause, tolérance/récupération, sécurité

71 références, aucune écartée ni contredite (63 confirmées, 8 complétées). « Choix raisonné » = règle prudente de coach, sans preuve directe ; « à relire » = chiffre non confirmé à la seconde vérification.

### R5-P1 — Dose minimale efficace
- **Règle** : 4 séries/groupe/semaine en 6–15 RM (jambes, tirage, poussée) suffisent pour progresser ; départ à 4–6 séries, RIR 3–4.
- **Par niveau** : débutant 4–6 séries, hausse si stagnation 2 sem. et assiduité ≥ 80 % ; intermédiaire plancher 6–10 ; avancé et élite : plancher de maintien seulement.
- **Preuve** : méta-analyses, seuils raisonnés — Iversen et al., 2021, Sports Med, 10.1007/s40279-021-01490-1.
- **Au-delà des données** : sous-doser 2–4 semaines pour installer l'envie de revenir.

### R5-P2 — Fréquence 2–3×/semaine
- **Règle** : chaque groupe au moins 2×/semaine (effet 0,49 contre 0,30 pour 1×) ; 3× non supérieur à 2×.
- **Par niveau** : débutant corps entier 2–3×, 48 h d'écart ; intermédiaire 2×/groupe ; avancé et élite 2–4×, fréquence au service de la technique.
- **Preuve** : méta-analyse — Schoenfeld et al., 2016, Sports Med, 10.1007/s40279-016-0543-8.
- **Au-delà des données** : habiletés en petites doses fréquentes.

### R5-P3 — Double progression
- **Règle** : +2–10 % de charge quand la cible est dépassée de 1–2 répétitions deux séances de suite.
- **Par niveau** : débutant +2–5 % haut, +5–10 % bas, ou variante plus dure ; intermédiaire +2–5 %/semaine ; avancé et élite blocs de 3–6 sem., ≤ 2,5 %.
- **Preuve** : consensus d'experts — ACSM, 2009, Med Sci Sports Exerc, 10.1249/MSS.0b013e3181915670.
- **Au-delà des données** : demi-paliers entre deux variantes au poids de corps.

### R5-P4 — Technique avant l'échec
- **Règle** : l'échec n'apporte qu'un gain trivial d'hypertrophie (ES 0,19 ; IC 0,00–0,37) ; son effet sur la blessure n'est pas étudié.
- **Par niveau** : débutant RIR 3–4 puis 2–3, échec interdit ; intermédiaire RIR 1–3, échec sur mouvements stables ; avancé et élite ponctuel, jamais sur mouvement à risque.
- **Preuve** : méta-analyse, interdictions raisonnées — Refalo et al., 2023, Sports Med, 10.1007/s40279-022-01784-y.
- **Au-delà des données** : série finie quand la dernière répétition ne ressemble plus à la première.

### R5-P5 — Désentraînement et maintien
- **Règle** : une pause ≤ 3 semaines ne coûte rien ; 1/3 du volume, intensité gardée, maintient le jeune, pas le senior.
- **Par niveau** : débutant à avancé maintien à 1/3 ; plus de 60 ans 1/3–1/2 et 2 séances ; élite exposition spécifique hebdomadaire (raisonné).
- **Preuve** : essais contrôlés — Bickel et al., 2011, Med Sci Sports Exerc, 10.1249/MSS.0b013e318207c15d.
- **Au-delà des données** : présenter la pause comme une partie du plan.

### R5-P6 — Mémoire musculaire
- **Règle** : le regain est plus rapide que le gain initial ; progression 1,5–2 fois plus rapide jusqu'à 90 % des anciens repères (raisonné).
- **Par niveau** : même règle du débutant à l'élite, après la reprise prudente de P7.
- **Preuve** : essais contrôlés, mécanisme débattu — Psilander et al., 2019, J Appl Physiol, 10.1152/japplphysiol.00917.2018.
- **Au-delà des données** : les tendons reviennent moins vite que les muscles.

### R5-P7 — Reprise après pause
- **Règle** : barème raisonné : 2–4 sem. d'arrêt = charge −10 %, volume −20 à −30 % ; 4–8 sem. = −15 à −20 % et −30 à −50 % ; 8–16 sem. = −20 à −30 % et −50 %.
- **Par niveau** : débutant à avancé barème tel quel, RIR ≥ 3 ; élite mêmes pourcentages, séances courtes et fréquentes.
- **Preuve** : effet protecteur démontré (durée à relire), barème de terrain — Hyldahl et al., 2017, Exerc Sport Sci Rev, 10.1249/JES.0000000000000095.
- **Au-delà des données** : demander la cause de la pause ; urines foncées = urgence.

### R5-P8 — Première traction
- **Règle** : aucune étude comparative ; rowing inversé, assistance, puis excentriques 3–5 s (2–3 × 2–3, plafond 15/séance).
- **Par niveau** : débutant cette séquence, passage à 3 × 5 excentriques de 5 s ; intermédiaire à élite même logique vers un bras, muscle-up, front lever.
- **Preuve** : pratique de terrain — McHugh, 2003, Scand J Med Sci Sports, 10.1034/j.1600-0838.2003.02477.x.
- **Au-delà des données** : plafonner le volume pour protéger le coude.

### R5-P9 — Surpoids et poids de corps
- **Règle** : variante permettant ≥ 6–8 répétitions à RIR ≥ 3 ; sauts exclus avant 3 × 10 squats et 3 × 8 fentes indolores.
- **Par niveau** : surtout débutant ; même principe de charge relative aux autres niveaux.
- **Preuve** : pratique de terrain — Riebe et al., 2015 (dépistage, DOI en P25).
- **Au-delà des données** : choisir des exercices où la personne se sent compétente.

### R5-P10 — Âge
- **Règle** : le senior progresse (+1,1 kg de masse maigre) à 70–79 % 1RM ; récupération plus lente non démontrée.
- **Par niveau** : tous niveaux : moins de 40 ans rien ; 40–59 ans progression ralentie ; 60 ans et plus volume −20 %, 48–72 h (raisonné) ; master élite moins de séances dures.
- **Preuve** : méta-analyses — Peterson et al., 2011, Med Sci Sports Exerc, 10.1249/MSS.0b013e3181eb6265 ; Borde et al., 2015.
- **Au-delà des données** : juger l'âge d'entraînement et les articulations, pas l'âge civil.

### R5-P11 — Sexe
- **Règle** : réponse relative identique (hypertrophie ES 0,07, p = 0,31) : aucun programme différent.
- **Par niveau** : du débutant à l'élite mêmes volumes et intensités ; incréments de +1 à 2,5 kg.
- **Preuve** : méta-analyse — Roberts et al., 2020, J Strength Cond Res, 10.1519/JSC.0000000000003521.
- **Au-delà des données** : prévoir plus de paliers vers la traction et le dip.

### R5-P12 — Cycle menstruel
- **Règle** : effet de la phase trivial (ES −0,06 ; −0,16 à 0,04) : ne pas périodiser selon le cycle.
- **Par niveau** : tous niveaux : autorégulation du jour (−1 série ou RIR +1) sur symptômes déclarés.
- **Preuve** : méta-analyse — McNulty et al., 2020, Sports Med, 10.1007/s40279-020-01319-3.
- **Au-delà des données** : écouter les régularités individuelles.

### R5-P13 — Ancienneté
- **Règle** : les gains ralentissent avec l'ancienneté ; bornes de séries raisonnées.
- **Par niveau** : débutant 4–6 → 10 séries ; intermédiaire 8–10 → 16, décharge toutes les 4–6 sem. ; avancé 10–14 → 20, toutes les 3–5 sem. ; élite individualisé.
- **Preuve** : essais contrôlés, bornes raisonnées — Petré et al., 2021, Sports Med, 10.1007/s40279-021-01426-9.
- **Au-delà des données** : cinq ans désordonnés valent un niveau intermédiaire.

### R5-P14 — Sommeil
- **Règle** : nuit courte = −7,56 % de performance (IC −11,9 à −3,13), matin épargné ; effet chronique non démontré.
- **Par niveau** : tous niveaux : moins de 6 h habituelles volume −10 à −20 %, RIR +1 ; nuit de moins de 5 h, −1 série, ni record ni figure à risque (raisonné).
- **Preuve** : méta-analyse, ajustements raisonnés — Craven et al., 2022, Sports Med, 10.1007/s40279-022-01706-y.
- **Au-delà des données** : corriger le sommeil avant le programme.

### R5-P15 — Stress psychologique
- **Règle** : le stress de vie ralentit un peu la récupération (R² = 0,05) ; stress ≥ 7/10 une semaine : volume −10 à −20 %, RIR +1.
- **Par niveau** : tous niveaux même règle, maintien 1–2 sem. si événement majeur ; élite report des tests maximaux.
- **Preuve** : essais chez des étudiants, règle raisonnée — Stults-Kolehmainen & Bartholomew, 2012, Med Sci Sports Exerc, 10.1249/MSS.0b013e31825f67a0.
- **Au-delà des données** : la capacité d'adaptation est un budget unique.

### R5-P16 — Déficit énergétique
- **Règle** : le déficit freine la masse maigre (ES −0,57), pas la force ; ne pas réduire le volume par défaut.
- **Par niveau** : tous niveaux gel du volume, −10 à −20 % si décrochage ; débutant en surpoids progression normale ; élite pas de bloc d'hypertrophie en sèche.
- **Preuve** : méta-analyse — Murphy & Koehler, 2022, Scand J Med Sci Sports, 10.1111/sms.14075 ; Roth et al., 2022.
- **Au-delà des données** : annoncer la baisse des répétitions en fin de sèche.

### R5-P17 — Protéines
- **Règle** : repère 1,6 g/kg/jour (borne 2,2 à relire) ; aucun ajustement du programme.
- **Par niveau** : tous niveaux : simple message si apport < 1,0–1,2 g/kg/jour.
- **Preuve** : méta-analyse — Morton et al., 2018, Br J Sports Med, 10.1136/bjsports-2017-097608.
- **Au-delà des données** : régler d'abord les repas et l'énergie totale.

### R5-P18 — Métier physique
- **Règle** : effet plausible, non démontré ; métier lourd : −10 à −20 % sur les zones sollicitées, réévalué à 4 semaines.
- **Par niveau** : tous niveaux même règle ; avancé et élite comptent le travail manuel dans la charge de préhension et de dos.
- **Preuve** : pratique de terrain — Holtermann et al., 2018, Br J Sports Med, 10.1136/bjsports-2017-097965.
- **Au-delà des données** : demander ce que font les mains et le dos huit heures par jour.

### R5-P19 — Interférence force/endurance
- **Règle** : interférence sur la force explosive (SMD −0,28) et chez les entraînés en même séance (ES −0,66) ; séparer d'au moins 3 h, 6 h par prudence.
- **Par niveau** : débutant rien ; intermédiaire et avancé séances séparées, jambes −20 à −30 % si endurance ≥ 3×/sem. (raisonné) ; élite une priorité par bloc.
- **Preuve** : méta-analyses — Schumann et al., 2022, Sports Med, 10.1007/s40279-021-01587-7 ; Petré et al., 2021 (DOI en P13).
- **Au-delà des données** : retirer ce que l'autre sport apporte déjà.

### R5-P20 — Antécédents de blessure
- **Règle** : un antécédent multiplie le risque par 2,7 (IC 1,7–4,3 ; football) ; antécédent < 12 mois : zone −30 à −50 %, demi-vitesse (raisonné).
- **Par niveau** : tous niveaux même règle, jamais d'exclusion définitive ; élite bilan kiné avant un bloc lourd.
- **Preuve** : cohorte, extrapolée à la musculation — Hägglund et al., 2006, Br J Sports Med, 10.1136/bjsm.2006.026609.
- **Au-delà des données** : tester le côté atteint contre le côté sain.

### R5-P21 — Variabilité individuelle
- **Règle** : même programme : taille −2 à +59 %, 1RM 0 à +250 % ; piloter sur la réponse ; cumul des réductions plafonné à −40 % (raisonné).
- **Par niveau** : tous niveaux blocs de 3–4 sem., +10–20 % ou −20–30 % ; élite historique personnel.
- **Preuve** : cohorte de 585 sujets — Hubal et al., 2005, Med Sci Sports Exerc, PMID 15947721.
- **Au-delà des données** : changer une seule variable à la fois.

### R5-P22 — Rythme de progression
- **Règle** : la règle des 10 % ne protège pas (20,8 % contre 20,3 %) ; garde-fous raisonnés : +10–20 %/sem., +30 % sur 2 sem. au plus, nouvel exercice à 50–60 %.
- **Par niveau** : débutant limite en séries ; intermédiaire garde-fous communs ; avancé et élite +5–10 %/sem. en bras tendus ; aucun ACWR affiché.
- **Preuve** : essai randomisé chez des coureurs — Buist et al., 2008, Am J Sports Med, 10.1177/0363546507307505.
- **Au-delà des données** : traquer les vrais pics (vacances, défi, stage).

### R5-P23 — Douleur
- **Règle** : 0–2 continuer ; 3–4 sans progresser ; 5 régresser ; ≥ 6 arrêter ; plafond par défaut 3–4/10 (raisonné ; seuil 5/10 à relire).
- **Par niveau** : mêmes seuils du débutant à l'élite ; consulter si ≥ 2 semaines.
- **Preuve** : essais chez des patients suivis — Silbernagel et al., 2007, Am J Sports Med, 10.1177/0363546506298279 ; Smith et al., 2017.
- **Au-delà des données** : regarder la tendance sur 2–3 semaines.

### R5-P24 — Coude et épaule douloureux
- **Règle** : aucun programme de soin ; tirage et préhension −30 à −50 %, positions extrêmes retirées, retour à 50 % puis +10–20 %/sem. (raisonné).
- **Par niveau** : tous niveaux même règle ; élite bilan kiné avant les bras tendus.
- **Preuve** : revues systématiques chez des patients — Littlewood et al., 2015, Int J Rehabil Res, 10.1097/MRR.0000000000000113.
- **Au-delà des données** : modifier la prise ou l'amplitude avant de supprimer.

### R5-P25 — Drapeaux rouges
- **Règle** : trois degrés (secours ; 24–72 h ; programmée) ; programme suspendu jusqu'à avis médical.
- **Par niveau** : identique du débutant à l'élite.
- **Preuve** : consensus clinique, non validé — Riebe et al., 2015, Med Sci Sports Exerc, 10.1249/MSS.0000000000000664.
- **Au-delà des données** : dix orientations pour rien plutôt qu'une manquée.

### R5-P26 — Dépistage
- **Règle** : activité actuelle, symptômes ou maladie connue, intensité visée ; questionnaire tous les 12 mois.
- **Par niveau** : identique à tous les niveaux ; symptômes = avis médical d'abord.
- **Preuve** : consensus d'experts — Riebe et al., 2015 (DOI en P25).
- **Au-delà des données** : reposer les questions une fois la confiance installée.

### R5-P27 — Mouvements à risque
- **Règle** : culturisme 0,24–1 blessure/1 000 h ; aucune donnée en street workout ; classes de risque raisonnées : élevé = échec interdit, RIR ≥ 2.
- **Par niveau** : débutant jamais d'échec ; intermédiaire échec technique en risque modéré ; avancé et élite idem, risque élevé toujours RIR ≥ 2.
- **Preuve** : épidémiologie descriptive — Keogh & Winwood, 2017, Sports Med, 10.1007/s40279-016-0575-0.
- **Au-delà des données** : enseigner la sortie avant la figure.

### R5-P28 — Pression artérielle
- **Règle** : pics de 320/250 mmHg à l'échec (5 sujets), danger non démontré ; hypertendu contrôlé : 40–70 % 1RM, RIR ≥ 2–3, sans apnée (raisonné).
- **Par niveau** : tous niveaux blocage bref ; hypertendu selon accord médical ; élite sans restriction hors pathologie.
- **Preuve** : mesures directes et méta-analyse — MacDougall et al., 1985, J Appl Physiol, 10.1152/jappl.1985.58.3.785.
- **Au-delà des données** : apprendre la respiration dès la première séance.

---

## R6 — Disciplines autres que le street workout

78 références confirmées à la seconde vérification, 2 écartées (ouvrage de Daniels, guide CrossFit). « NC » = chiffre non confirmé à la seconde vérification.

### R6-P1 — Volume hebdomadaire
- **Règle** : relation graduée, +0,37 % par série ; bas contre élevé 3,9 %. Seuil « ≥ 10 séries » NC (tendance, P = 0,074).
- **Par niveau** : débutant 6-10 séries/muscle/sem ; intermédiaire 10-16 ; avancé 12-20 (priorité 20-25) ; élite individualisé.
- **Preuve** : méta-analyse — Schoenfeld et al., 2017, J Sports Sci, 10.1080/02640414.2016.1210197
- **Au-delà des données** : compter les séries dures, partir bas et monter.

### R6-P2 — Charges et échec
- **Règle** : l'échec n'apporte rien de démontré (TE 0,12 ; IC -0,13 à 0,37) ; plage 30-85 % 1RM NC.
- **Par niveau** : débutant 8-15 rép., 2-4 RIR ; intermédiaire 6-10 à 1-3 RIR, isolations 10-20 ; avancé et élite : échec en dernière série d'isolation seulement.
- **Preuve** : méta-analyse — Refalo et al., 2023, Sports Med, 10.1007/s40279-022-01784-y
- **Au-delà des données** : vérifier par une série test que le RIR annoncé est réel.

### R6-P3 — Fréquence et répartition
- **Règle** : à volume égal, corps entier = fractionné (14 études, 392 sujets, p ≥ 0,29).
- **Par niveau** : débutant corps entier 2-3 fois ; intermédiaire haut/bas 3-4 fois ; avancé et élite : libre, ≤ 10 séries/muscle/séance, ≥ 2 expositions.
- **Preuve** : méta-analyse — Ramos-Campo et al., 2024, J Strength Cond Res, 10.1519/JSC.0000000000004774
- **Au-delà des données** : choisir la répartition tenable 12 semaines.

### R6-P4 — Exercices et position longue
- **Règle** : amplitude complète ≈ partielle (SMD 0,12) ; position étirée : ischios +14 % contre +9 %, triceps +19,9 % contre +13,9 %.
- **Par niveau** : débutant 1 exercice/muscle ; intermédiaire 2 dont 1 en position longue ; avancé et élite 2-4, rotation 6-12 semaines.
- **Preuve** : essais contrôlés — Maeo et al., 2021, Med Sci Sports Exerc, 10.1249/MSS.0000000000002523 ; Maeo et al., 2023, Eur J Sport Sci, 10.1080/17461391.2022.2100279
- **Au-delà des données** : garder les mêmes mouvements assez longtemps pour mesurer.

### R6-P5 — Ordre des exercices
- **Règle** : sans effet sur l'hypertrophie (TE 0,03) ; l'exercice placé en premier gagne plus de force (TE 0,32).
- **Par niveau** : débutant et intermédiaire : priorité technique ; avancé et élite : priorité au point faible.
- **Preuve** : méta-analyse — Nunes et al., 2021, Eur J Sport Sci, 10.1080/17461391.2020.1733672
- **Au-delà des données** : jamais de mouvement technique lourd après pré-fatigue.

### R6-P6 — Points faibles
- **Règle** : +30-50 % de séries (plafond 20-25), en début de séance, 6-8 semaines.
- **Par niveau** : débutant : rien avant 6-12 mois ; intermédiaire 1 muscle ; avancé et élite 1-2 par bloc.
- **Preuve** : pratique de terrain, déduite de P1 et P5.
- **Au-delà des données** : juger sur photos et mensurations.

### R6-P7 — Repères nutritionnels
- **Règle** : surplus 10-20 %, +0,25-0,5 %/sem, protéines 1,6-2,2 g/kg ; perte 0,5-1 %/sem NC. Aucune prescription.
- **Par niveau** : identique ; prise plus lente chez l'avancé et l'élite.
- **Preuve** : consensus d'experts — Iraki et al., 2019, Sports, 10.3390/sports7070154
- **Au-delà des données** : en déficit, garder l'intensité, réduire le volume de 20-33 %.

### R6-P8 — Force : fréquences
- **Règle** : enquête (401 questionnaires complets sur 548) : 4,25 séances ; squat 1,64, couché 2,48, terre 1,37 fois/sem.
- **Par niveau** : débutant 3 séances (2-3 / 2-3 / 1-2) ; intermédiaire 4 ; avancé 4-5 (2-3 / 3-4 / 1-2) ; élite 4-6.
- **Preuve** : pratique de terrain documentée — Amdi et al., 2025, J Strength Cond Res, 10.1519/JSC.0000000000005261
- **Au-delà des données** : squat et terre lourds à 48-72 h d'écart.

### R6-P9 — Force : intensité, dose minimale
- **Règle** : dose minimale 3-6 séries/sem/mouvement, 1-5 rép., > 80 % 1RM, RPE 7,5-9,5.
- **Par niveau** : débutant 70-85 %, 5-10 séries ; intermédiaire 75-90 %, 8-12 ; avancé et élite 75-85 %, pics ≥ 90 %, 10-20.
- **Preuve** : essais contrôlés + méta-analyse — Androulakis-Korakakis et al., 2021, Front Sports Act Living, 10.3389/fspor.2021.713655
- **Au-delà des données** : autoréguler par RPE.

### R6-P10 — Accessoires et variantes
- **Règle** : 1 variante en 3-6 rép., 1-3 accessoires en 6-12 ; 88,2 % ajustent avant l'échéance.
- **Par niveau** : débutant 0-1 variante ; intermédiaire 1 ; avancé et élite 1-2, moins d'accessoires avant compétition.
- **Preuve** : pratique de terrain — Amdi et al., 2025 (voir P8).
- **Au-delà des données** : choisir la variante d'après la vidéo de l'échec.

### R6-P11 — Affûtage de force
- **Règle** : 1-2 semaines, volume -30 à -50 % ; champions : -50,5 %, pic d'intensité à 8 ± 3 j, dernière séance à 3 ± 1 j.
- **Par niveau** : débutant aucun ; intermédiaire 7 j ; avancé et élite 10-14 j, séance lourde J-11 à J-5, dernière séance J-4 à J-2.
- **Preuve** : revue + étude descriptive (n = 10) — Travis et al., 2020, Sports, 10.3390/sports8090125 ; Grgic & Mikulic, 2017, J Strength Cond Res, 10.1519/JSC.0000000000001699
- **Au-delà des données** : couper le terre avant le couché.

### R6-P12 — Progression à long terme
- **Règle** : 0,12-0,15 kg de total par jour sur 15 ans ; plateau chez les plus forts.
- **Par niveau** : débutant +2,5-5 kg/séance ; intermédiaire +2-5 %/cycle ; avancé +1-3 % ; élite +0,5-2 %/an.
- **Preuve** : étude longitudinale — Latella et al., 2020, J Strength Cond Res, 10.1519/JSC.0000000000003657
- **Au-delà des données** : annoncer ces ordres de grandeur d'emblée.

### R6-P13 — Blessures en powerlifting
- **Règle** : 1,0-4,4 blessures/1 000 h ; gêne ≤ 3/10 : adapter ; > 4/10 : remplacer et orienter.
- **Par niveau** : identique ; technique validée avant charge chez le débutant.
- **Preuve** : revue systématique — Aasa et al., 2017, Br J Sports Med, 10.1136/bjsports-2016-096037
- **Au-delà des données** : surveiller épaule au couché, lombaires au terre.

### R6-P14 — Zones et allures
- **Règle** : 3 zones autour des seuils (≈ 2 et 4 mmol/L) ; pourcentages d'allures NC.
- **Par niveau** : débutant : RPE, test de la parole ; intermédiaire : allures d'un chrono ; avancé et élite : seuils mesurés.
- **Preuve** : revue — Seiler, 2010, Int J Sports Physiol Perform, 10.1123/ijspp.5.3.276
- **Au-delà des données** : imposer un footing vraiment facile.

### R6-P15 — Distribution de l'intensité
- **Règle** : 75-85 % en Z1 ; le polarisé n'améliore que la VO2pic (SMD 0,24), pas le contre-la-montre (-0,01).
- **Par niveau** : débutant : Z1 seule 6-8 semaines ; intermédiaire 1-2 séances de qualité ; avancé et élite 2-3.
- **Preuve** : méta-analyse — Silva Oliveira et al., 2024, Sports Med, 10.1007/s40279-024-02034-z
- **Au-delà des données** : compter les séances dures, protéger les jours faciles.

### R6-P16 — Progression du kilométrage
- **Règle** : séance ≤ 110 % de la plus longue sortie sur 30 j (au-delà : 1,64 ; 1,52 ; 2,28) ; hausse hebdomadaire ≤ 10-20 % (choix raisonné).
- **Par niveau** : débutant : en minutes ; intermédiaire : deux garde-fous ; avancé et élite : aussi sur l'intensité.
- **Preuve** : cohorte (5 205 coureurs) — Frandsen et al., 2025, Br J Sports Med, 10.1136/bjsports-2024-109380
- **Au-delà des données** : jamais volume et intensité la même semaine.

### R6-P17 — Marche-course
- **Règle** : programme de 9 semaines : 27,3 % terminent, 19 % blessés (OR 7,56 si antécédent).
- **Par niveau** : débutant 3 × 20-30 min, 1 min course / 1-2 min marche, 9-16 semaines ; autres niveaux : outil de reprise.
- **Preuve** : cohorte — Relph et al., 2023, Int J Environ Res Public Health, 10.3390/ijerph20176682
- **Au-delà des données** : la régularité avant la progression.

### R6-P18 — HIIT ou continu
- **Règle** : VO2max : continu +4,9, HIIT +5,5 mL/kg/min ; écart +1,2 ; 48 h entre deux HIIT.
- **Par niveau** : débutant : continu 4-8 semaines puis 1 HIIT ; intermédiaire 1-2 ; avancé et élite 2-3 (plafonds 8-10 % NC).
- **Preuve** : méta-analyse — Milanović et al., 2015, Sports Med, 10.1007/s40279-015-0365-0
- **Au-delà des données** : un circuit 20 s / 10 s n'est pas le vrai Tabata.

### R6-P19 — Semi-marathon
- **Règle** : > 32 km/sem et sortie > 21 km vont avec un meilleur temps ; sortie longue 20-30 %, ≤ 150 min (NC).
- **Par niveau** : débutant 20-30 km/sem ; intermédiaire 35-55 ; avancé 60-90 ; élite 110-180.
- **Preuve** : cohorte — Fokkema et al., 2020, Scand J Med Sci Sports, 10.1111/sms.13725
- **Au-delà des données** : la durée d'abord, l'allure ensuite.

### R6-P20 — Affûtage d'endurance
- **Règle** : 2 semaines, volume -41 à -60 % en exponentielle, intensité et fréquence inchangées.
- **Par niveau** : débutant 5-7 j ; intermédiaire 7-14 j ; avancé et élite : complet (marathon 14-21 j).
- **Preuve** : méta-analyse — Bosquet et al., 2007, Med Sci Sports Exerc, 10.1249/mss.0b013e31806010e0
- **Au-delà des données** : rappels d'allure jusqu'à J-3.

### R6-P21 — Santé publique
- **Règle** : 150-300 min modérées ou 75-150 min intenses par semaine ; renforcement ≥ 2 j (NC).
- **Par niveau** : débutant : c'est l'objectif ; autres niveaux : plancher dépassé d'office.
- **Preuve** : consensus d'experts — Bull et al., 2020, Br J Sports Med, 10.1136/bjsports-2020-102955
- **Au-delà des données** : y arriver par tranches de 10 min.

### R6-P22 — Renforcement du coureur
- **Règle** : économie +2-8 % ; blessures : RR 0,338 (2018 ; 7 738 participants), RR 0,315 (2014 ; 26 610) ; étirements sans effet.
- **Par niveau** : débutant : 2 séances légères ; intermédiaire : charges montantes ; avancé et élite : 4-8 rép. lourdes, pliométrie.
- **Preuve** : méta-analyses — Lauersen et al., 2018, Br J Sports Med, 10.1136/bjsports-2018-099078 ; Lauersen et al., 2014, Br J Sports Med, 10.1136/bjsports-2013-092538
- **Au-delà des données** : viser le maillon faible (mollet, Achille).

### R6-P23 — Dose d'étirement
- **Règle** : statique et PNF > dynamique ; dose non établie ; repère ≥ 5 min/sem/muscle sur ≥ 5 j.
- **Par niveau** : débutant 30 s, 3-4 zones ; intermédiaire 45-60 s ; avancé et élite 60-120 s chargé.
- **Preuve** : méta-analyse — Konrad et al., 2024, J Sport Health Sci, 10.1016/j.jshs.2023.06.002
- **Au-delà des données** : routines courtes et quotidiennes.

### R6-P24 — Musculation et mobilité
- **Règle** : la musculation chargée augmente l'amplitude (TE 0,73), comme l'étirement ; non significatif au seul poids du corps.
- **Par niveau** : débutant : suffit souvent ; intermédiaire : étirer les zones limitantes ; avancé et élite : fin d'amplitude chargée.
- **Preuve** : méta-analyse — Alizadeh et al., 2023, Sports Med, 10.1007/s40279-022-01804-x
- **Au-delà des données** : pause de 2-3 s en position basse.

### R6-P25 — Étirement avant l'effort
- **Règle** : statique < 60 s : -1,1 % ; ≥ 60 s : -4 à -7,5 % ; donc ≤ 30 s/muscle avant l'effort.
- **Par niveau** : débutant 8-10 min ; intermédiaire 8-15 ; avancé et élite 15-25.
- **Preuve** : revue systématique — Behm et al., 2016, Appl Physiol Nutr Metab, 10.1139/apnm-2015-0235
- **Au-delà des données** : étirements longs en fin de séance.

### R6-P26 — Seniors et chutes
- **Règle** : l'exercice réduit les chutes de 23 % (0,77 ; IC 0,71-0,83) ; équilibre ≥ 3 j/sem (NC).
- **Par niveau** : débutant : assis-debout, RPE 5-6 ; entraîné : 70-85 % 1RM (NC) ; master : règles adultes, +24 h de récupération.
- **Preuve** : méta-analyse Cochrane — Sherrington et al., 2019, 10.1002/14651858.CD012424.pub2
- **Au-delà des données** : durcir l'équilibre à chaque séance.

### R6-P27 — Formats CrossFit
- **Règle** : formats non validés ; conditionnement 8-20 min dans une séance de 60 min.
- **Par niveau** : débutant 2-3 séances ; intermédiaire 3-5 ; avancé 5-6 ; élite 1-2 séances/j.
- **Preuve** : pratique de terrain (preuve faible) — Claudino et al., 2018, Sports Med Open, 10.1186/s40798-018-0124-5
- **Au-delà des données** : annoncer l'intention de la séance.

### R6-P28 — CrossFit : blessures
- **Règle** : 0,27-2,3 blessures/1 000 h ; rhabdomyolyse rare ; première semaine ≤ 50 % du volume.
- **Par niveau** : débutant 4-8 semaines techniques, RPE ≤ 7 ; intermédiaire : mise à l'échelle ; avancé et élite : gérer la charge hebdomadaire.
- **Preuve** : études rétrospectives — Feito et al., 2018, Orthop J Sports Med, 10.1177/2325967118803100
- **Au-delà des données** : strict avant kipping.

### R6-P29 — Interférence
- **Règle** : force maximale (SMD -0,06) et hypertrophie (-0,01) préservées ; force explosive -0,28 ; entraînés -0,35.
- **Par niveau** : débutant : libre ; intermédiaire : cardio intense ≤ 2-3 ; avancé et élite : séances séparées, vélo plutôt que course.
- **Preuve** : méta-analyse — Schumann et al., 2022, Sports Med, 10.1007/s40279-021-01587-7
- **Au-delà des données** : raisonner en fatigue locale et en apport énergétique.

### R6-P30 — Ordre et délai
- **Règle** : force avant endurance : +6,91 % de force du bas du corps ; ≥ 6 h d'écart, minimum 3 h.
- **Par niveau** : débutant : ordre seul ; intermédiaire ≥ 3 h ; avancé et élite ≥ 6 h ou jours séparés.
- **Preuve** : méta-analyse — Eddens et al., 2018, Sports Med, 10.1007/s40279-017-0784-1
- **Au-delà des données** : regrouper le dur le même jour.

### R6-P31 — Musculation en déficit
- **Règle** : la force progresse en déficit ; musculation + restriction : -5,3 kg de masse grasse (114 essais).
- **Par niveau** : débutant 2-3 séances, 8-12 rép. ; intermédiaire 3-4 ; avancé et élite : intensité préservée.
- **Preuve** : méta-analyse — Lopez et al., 2022, Obes Rev, 10.1111/obr.13428
- **Au-delà des données** : suivre la force comme témoin du muscle.

### R6-P32 — Marche et attentes
- **Règle** : > 250 min/sem pour une perte nette ; mortalité HR 0,55 à 7 842 pas ; plateau 6 000-10 000 selon l'âge.
- **Par niveau** : débutant +1 000 pas/1-2 sem, faible impact ; autres niveaux 8 000-10 000 pas.
- **Preuve** : méta-analyse de cohortes — Paluch et al., 2022, Lancet Public Health, 10.1016/S2468-2667(21)00302-9
- **Au-delà des données** : jamais l'exercice comme punition calorique.

---

