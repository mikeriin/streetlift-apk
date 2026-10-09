# Sources de recherche — Koach 1.0 (moteur d'estimation bayésienne et de planification)

Recherche documentaire faite le 2026-10-09 (WebSearch / WebFetch).

**Comment lire les statuts**
- **vérifié (résumé)** : chiffre lu dans le résumé de l'article (page éditeur, dépôt institutionnel, PubMed/LIDA, prépublication).
- **vérifié (texte)** : chiffre lu dans le texte intégral (tableau, résultats, discussion).
- **seconde main (X)** : chiffre rapporté par une source tierce X, pas lu dans la source primaire.
- **calcul** : valeur dérivée par l'outil de lecture à partir des moyennes publiées. Ce n'est pas un chiffre des auteurs.
- **non trouvé** : aucune source fiable lue. La meilleure source voisine est proposée.

**Limites d'accès.** PubMed et PMC ont souvent renvoyé un captcha. Europe PMC a été bloqué (proxy, puis limitation de débit). Plusieurs pages Springer, arXiv et BMJ ont été refusées (limitation 429 ou permission expirée). Quand c'est arrivé, le résumé a été lu sur une page miroir (dépôt universitaire, SportRxiv, LIDA, PEDro, page éditeur), et cette page est citée.

---

## 1. Précision de l'estimation des répétitions en réserve (RIR)

Résultat principal : en moyenne, les gens **sous-estiment** de près d'une répétition ce qu'il leur reste avant l'échec (Halperin 2022). L'erreur diminue quand :
- la série est plus proche de l'échec ;
- la série compte moins de 12 répétitions ;
- on avance dans les séries (séries suivantes).

Dans la méta-analyse, l'expérience **ne modère pas** l'erreur de façon détectable. En revanche, l'étude de Steele 2017, la seule à donner une erreur-type par niveau d'expérience, montre une baisse nette : environ 4–5 répétitions chez les débutants, environ 1,3–2,3 chez les « experts ». Les bruits initiaux de 2,0 / 1,5 / 1,0 répétition (débutant / intermédiaire / avancé) se situent donc dans l'ordre de grandeur de l'écart-type entre participants de Halperin (1,45). Ils sont **plus optimistes** que les erreurs-types de Steele 2017, qui portent sur la prédiction en début de série.

| Affirmation | Chiffre | Source | Statut |
|---|---|---|---|
| Biais moyen de sous-estimation des répétitions jusqu'à l'échec | 0,95 rép. (IC95 0,17–1,73) ; 262 tailles d'effet, 12 grappes, 414 participants ; I² = 97,9 % | Halperin I, Malleron T, Har-Nir I, Androulakis-Korakakis P, Wolf M, Fisher J, Steele J. *Accuracy in predicting repetitions to task failure in resistance exercise: a scoping review and exploratory meta-analysis.* Sports Med 2022;52:377–390 (en ligne 20/09/2021). DOI 10.1007/s40279-021-01559-x | vérifié (résumé ; page Solent + prépublication SportRxiv 67) |
| Variation de la précision entre participants (écart-type) | 1,45 rép. (IC95 0,99–2,12), qualifiée de « minimale » | idem | vérifié (résumé) |
| Effet de la proximité de l'échec | β = −0,025 (IC95 −0,05 à 0,0014) : un peu plus précis près de l'échec | idem | vérifié (résumé) |
| Effet du nombre de répétitions de la série | ≤12 rép. : β = 0,06 (0,04–0,09) ; >12 rép. : β = 0,47 (0,44–0,49) | idem | vérifié (résumé) |
| Effet de l'expérience | β = −0,006 rép. (−0,02 à 0,007) : pas d'effet détectable | idem | vérifié (résumé) |
| Effet du rang de la série | β = −0,07 (−0,14 à −0,005) : un peu plus précis dans les séries suivantes | idem | vérifié (résumé) |
| Haut du corps − bas du corps | −0,58 rép. (−2,32 à 1,16) : non significatif | idem | vérifié (résumé) |
| Erreur-type de mesure (SEM) de la prédiction, échantillon combiné | 2,64 à 3,38 rép. selon l'exercice | Steele J, Endres A, Fisher J, Gentil P, Giessing J. *Ability to predict repetitions to momentary failure is not perfectly accurate, though improves with resistance training experience.* PeerJ 2017;5:e4105. DOI 10.7717/peerj.4105 | vérifié (résumé + tableau 2) |
| SEM par niveau d'expérience, développé couché machine | orientation 4,33 ; débutant 4,00 ; « experienced » 2,58 ; avancé 1,91 ; expert 1,57 | idem, tableau 2 | vérifié (texte) |
| SEM par niveau, presse à cuisses | 4,98 / 3,37 / 3,07 / 2,49 / 1,73 | idem, tableau 2 | vérifié (texte) |
| SEM par niveau, tirage vertical / rowing | tirage vertical 4,15 / 3,89 / 2,49 / 1,83 / 1,35 ; rowing 4,51 / 3,50 / 2,28 / 2,06 / 1,71 | idem, tableau 2 | vérifié (texte) |
| Sous-estimation moyenne selon le niveau (synthèse des auteurs) | groupe le plus expérimenté ≈ 1–2 rép. ; moins expérimentés ≈ 4–5 rép. | idem, discussion | vérifié (texte) |
| Sous-estimation par niveau, développé couché (réel − prédit) | orientation 5,07 ; débutant 3,90 ; « experienced » 1,86 ; avancé 1,03 ; expert 0,45 | idem, tableau 1 | calcul (outil de lecture, à partir des moyennes) |
| Sous-estimation chez des pratiquants entraînés (≥1 an), extension de genou, 70 % | 2,0 rép. (IC95 0,0–4,0) en méta-analyse de 2 expériences ; expérience 1 : 0,8 (−0,26 à 1,8) ; expérience 2 : 2,8 (1,5–4,0) | Armes C, Standish-Hunt H, Androulakis-Korakakis P, et al., Steele J. *"Just One More Rep!" – Ability to predict proximity to task failure in resistance trained persons.* **Front Psychol** 2020;11:565416. DOI 10.3389/fpsyg.2020.565416. NB : Frontiers in Psychology, pas JSCR | vérifié (résumé + résultats) |
| Erreur de l'estimation des répétitions jusqu'à l'échec (ERF), série 1 vs série 3, 1re séance | développé couché (70 %) : 2,0 → 0,6 rép. ; presse (80 %) : 3,1 → 1,6 rép. ; corrélation ERF–réel r = 0,59–0,87 | Hackett DA, Cobley SP, Halaki M. *Estimation of repetitions to failure for monitoring resistance exercise intensity: building a case for application.* J Strength Cond Res 2018;32(5):1352–1359 | vérifié (résumé) |
| Hackett 2012 (bodybuilders) et Hackett 2017 (JSCR) | — | **non trouvés** (pas ouverts). Source voisine : Hackett 2018 ci-dessus, même équipe et même méthode | non trouvé |
| Erreur par RIR cible et par série (Remmert) | différence moyenne de RIR : 1,2 à 5 RIR, 0,464 à 1 RIR ; 0,955 en série 1, 0,706 en série 3 | Remmert JF, Laurson KR, Zourdos MC. *Accuracy of predicted intraset repetitions in reserve (RIR) in single- and multi-joint resistance exercises among trained and untrained men and women.* **Percept Mot Skills** 2023;130(3):1239–1254. DOI 10.1177/00315125231169868. NB : pas JSCR | seconde main (Stronger by Science, page « reps-in-reserve ») |
| Remmert 2023 : facteurs | sexe p = 0,917 ; expérience p = 0,462 (n.s.) ; proximité de l'échec et rang de la série p < 0,01 ; exercice p = 0,688 ; 27 hommes, 31 femmes, séries à l'échec à 72,5 % du 1RM estimé | idem | vérifié (résumé, page SAGE) |
| Zourdos 2021 : effet de la proximité et du nombre total de répétitions | plus précis à 1 RIR qu'à 3 ou 5 RIR (qualitatif) | Zourdos MC, Goldsmith JA, Helms ER, et al. *Proximity to failure and total repetitions performed in a set influences accuracy of intraset repetitions in reserve-based rating of perceived exertion.* J Strength Cond Res 2021;35(Suppl 1):S158–S165. DOI 10.1519/JSC.0000000000002995 | seconde main (Casanova et al. 2025) ; chiffres du résumé non lus (captcha PubMed) |
| Zourdos 2016 : échelle RPE fondée sur les RIR | 29 sujets ; corrélation vitesse moyenne–RPE r = −0,88 (expérimentés), r = −0,77 (novices) ; RPE au 1RM plus élevé chez les expérimentés (p = 0,023) | Zourdos MC, Klemp A, Dolan C, et al. *Novel resistance training-specific rating of perceived exertion scale measuring repetitions in reserve.* J Strength Cond Res 2016;30(1):267–275. DOI 10.1519/JSC.0000000000001049 | vérifié (résumé, dépôt AUT) |
| L'erreur dépend de la charge (50 vs 75 % du 1RM) et de la cible (3 vs 1 RIR) | 50 % 1RM, 3 RIR : −3,4 à −4,7 rép. ; 50 %, 1 RIR : −1,3 à −2,4 ; 75 % : −0,09 à −1,59 | Casanova N, et al. *Accuracy in predicting repetitions in reserve during resistance training…* J Phys Educ Sport 2025;25(11):2373–2381. DOI 10.7752/jpes.2025.11262 | vérifié (texte, tableau 3) |
| Erreur absolue moyenne de RIR (entraînés) | 0,65 ± 0,78 rép. | Refalo et al. (étude citée sans référence complète) | seconde main (Stronger by Science) |

**Conséquence pour Koach.** Le biais est **positif** : le RIR déclaré est supérieur au RIR réel d'environ 1 rép., et ce biais croît avec le nombre de répétitions. Il faut le modéliser à part du bruit. Le bruit lui-même dépend de la longueur de la série (forte hausse au-delà de 12 rép.) et de la distance à l'échec. Pour l'expérience, les données sont contradictoires : la méta-analyse ne trouve pas d'effet, Steele 2017 en trouve un. Les bruits 2,0 / 1,5 / 1,0 doivent donc être présentés comme des a priori faibles, à apprendre par individu.

---

## 2. Répétitions et pourcentage du 1RM, et variabilité

| Affirmation | Chiffre | Source | Statut |
|---|---|---|---|
| Nombre moyen de répétitions maximales, modèle principal | 90 % ≈ 5 ; 70 % ≈ 15 (valeurs lues dans le texte ; les autres valeurs ne figurent que dans une figure) | Nuzzo JL, Pinto MD, Nosaka K, Steele J. *Maximal number of repetitions at percentages of the one repetition maximum: a meta-regression and moderator analysis of sex, age, training status, and exercise.* Sports Med 2024;54(2):303–321 (en ligne 4/10/2023). DOI 10.1007/s40279-023-01937-7 | vérifié (texte, discussion) |
| Écart-type entre individus du nombre de répétitions | 80 % : 2,51 rép. ; 60 % : 4,36 rép. (70 et 90 % : non donnés dans le texte) | idem | vérifié (texte) |
| Développé couché vs presse à cuisses | 80 % : 8,8 (IC95 7,7–10,1) vs 13,1 (9,8–17,5) ; 70 % : 14,1 (12,4–16,1) vs 19,0 (14,2–25,5) ; 90 % : ≈4 vs ≈9 | idem | vérifié (texte) |
| Sexe, âge, niveau d'entraînement comme modérateurs | « little influences » ; presque tous les rapports de contraste ont un IC qui contient 1 | idem | vérifié (résumé) |
| Composition des échantillons | 66 % d'hommes ; 60 % de groupes entraînés | idem | vérifié (résumé) |
| Formule d'Epley | 1RM = w·(1 + r/30) | Epley B. *Poundage chart.* Boyd Epley Workout. Lincoln (NE): Body Enterprises; 1985 | seconde main (Marzagao 2026, arXiv 2603.17495 ; Wikipédia « One-repetition maximum ») |
| Formule de Brzycki | 1RM = w / (1,0278 − 0,0278·r) = w·36/(37 − r) | Brzycki M. J Phys Educ Recreat Dance 1993;64(1):88–90 | seconde main (idem) |
| Formule de Lombardi | 1RM = w·r^0,10 | Lombardi VP. *Beginning Weight Training.* Wm. C. Brown; 1989 | seconde main (Wikipédia) |
| Formule de Mayhew | 1RM = 100·w / (52,2 + 41,9·e^(−0,055·r)) | Mayhew JL, et al. J Appl Sport Sci Res 1992;6(4):200–206 | seconde main (Marzagao 2026 ; Wikipédia) |
| Wathen, O'Conner | Wathen : 100·w / (48,8 + 53,8·e^(−0,075·r)) ; O'Conner : w·(1 + 0,025·r) | Wathen D. 1994 (in Baechle, *Essentials of S&C*) ; O'Conner B, et al. 1989 | seconde main |
| Cohérence interne des formules classiques sur 303 494 séries proches de l'échec | dispersion SD(log 1RM) : Brzycki 0,103 ; Epley 0,103 ; Wathen 0,102 ; Mayhew 0,108 ; formule à k variable 0,085 (−17 à −22 %) ; écart surtout sur les exercices légers d'isolation | Marzagao T. *A weight-dependent 1RM prediction equation optimized on 303,494 near-failure sets across 388 exercises.* Prépublication arXiv 2603.17495 (Fitbod) | vérifié (texte) ; non relue par des pairs |

**Remarque.** Les écarts-types inter-individus de Nuzzo (2,5 rép. à 80 %, 4,4 à 60 %) justifient un a priori **hiérarchique** sur la courbe répétitions/%1RM, avec des effets par exercice : la presse fait environ 50 % de répétitions de plus que le développé couché à charge relative égale.

---

## 3. Variabilité d'un jour à l'autre du 1RM (fiabilité test-retest)

| Affirmation | Chiffre | Source | Statut |
|---|---|---|---|
| ICC test-retest du 1RM | 0,64–0,99 ; médiane 0,97 ; 92 % des ICC ≥ 0,90 | Grgic J, Lazinica B, Schoenfeld BJ, et al. *Test–retest reliability of the one-repetition maximum (1RM) strength assessment: a systematic review.* Sports Med Open 2020;6:31. DOI 10.1186/s40798-020-00260-z | vérifié (résumé) |
| CV test-retest du 1RM | 0,5–12,1 % ; **médiane 4,2 %** | idem | vérifié (résumé) |
| Sans familiarisation / avec ≥1 séance | CV médian 5,3 % / 3,8 % | idem, résultats | vérifié (texte) |
| Haut / bas du corps | CV médian 4,1 % / 4,7 % | idem | vérifié (texte) |
| Non entraînés / entraînés | CV médian 5,5 % / 3,3 % | idem | vérifié (texte) |

**Conséquence.** Bruit d'observation de la performance maximale d'un jour à l'autre : ≈ 3–5 % (CV). Il est plus élevé chez le débutant et en l'absence de familiarisation. Les sous-groupes se recoupent, ils ne sont pas indépendants.

---

## 4. Dose-réponse du volume (et proximité de l'échec)

| Affirmation | Chiffre | Source | Statut |
|---|---|---|---|
| Hypertrophie : gain par série hebdomadaire supplémentaire | ES +0,023 par série ; +0,37 % par série | Schoenfeld BJ, Ogborn D, Krieger JW. *Dose-response relationship between weekly resistance training volume and increases in muscle mass: a systematic review and meta-analysis.* J Sports Sci 2017 (en ligne 2016 ; vol. 35(11):1073–1082 cité de mémoire, non lu). DOI 10.1080/02640414.2016.1210197 | vérifié (résumé) |
| Hypertrophie par catégorie de volume | <5 séries/sem : ES 0,307 (5,4 %) ; 5–9 : 0,378 (6,6 %) ; 10+ : 0,520 (9,8 %) ; tendance p = 0,074 | idem, résultats | vérifié (texte) |
| Force : volume faible / moyen / élevé (LWS/MWS/HWS) | HWS vs LWS : ES 0,18 (0,06–0,30) ; MWS vs LWS : 0,15 (0,01–0,30) ; 1RM seul HWS vs LWS : 0,14 (−0,01 à 0,29 ; p = 0,06) | Ralston GW, Kilgore JL, Wyatt FB, Baker JS. *The effect of weekly set volume on strength gain: a meta-analysis.* Sports Med 2017;47(12):2585–2601. DOI 10.1007/s40279-017-0762-7 | vérifié (résumé) ; les seuils des catégories (≈<5, 5–9, 10+ séries) ne figurent pas dans le résumé lu |
| Méta-régression bayésienne : forme de la relation volume → hypertrophie | **racine carrée** (rendements décroissants) ; pente marginale 0,24 % par série (ICr 0,15–0,33), évaluée à 12,25 séries | Pelland JC, Remmert JF, Robinson ZP, Hinson S, Zourdos MC. *The resistance training dose-response: meta-regressions exploring the effects of weekly volume and frequency on muscle hypertrophy and strength gain.* Prépublication SportRxiv 460, v2 (2024). 67 études, 2 058 participants | vérifié (résumé + texte) |
| Volume → force | forme **réciproque** (rendements décroissants « nettement plus prononcés ») ; 0,21 % par série (0,16–0,26) | idem | vérifié (résumé + texte) |
| Fréquence → force / hypertrophie | force : +3,27 % par séance (2,74–3,84), P(pente > 0) = 100 % ; hypertrophie : 0,32 % (−0,14 à 0,82), P = 91,3 % | idem | vérifié (texte) |
| Dose minimale efficace | hypertrophie : 4 séries fractionnaires/sem ; force : 1 série. Plus petit effet détectable : 2,05 % (hypertrophie), 3,96 % (force) | idem | vérifié (texte) |
| Décompte fractionnaire | série indirecte = 0,5 série | idem | vérifié (texte) |
| Version publiée de Pelland | — | non trouvée (seule la prépublication a été lue) | non trouvé |
| Proximité de l'échec → hypertrophie | pente négative en fonction du RIR estimé (plus près de l'échec, plus d'hypertrophie) ; SMC −0,019 g par RIR (−0,035 à −0,004) ; rapport de réponse −0,48 (−0,78 à −0,18) | Robinson ZP, Pelland JC, Remmert JF, Refalo MC, Jukic I, Steele J, Zourdos MC. *Exploring the dose–response relationship between estimated resistance training proximity to failure, strength gain, and muscle hypertrophy: a series of meta-regressions.* Sports Med 2024;54(9):2209–2231. DOI 10.1007/s40279-024-02069-2 | résumé vérifié (direction) ; pentes vérifiées dans la prépublication SportRxiv 295 |
| Proximité de l'échec → force | relation négligeable (les IC contiennent 0) ; SMC +0,003 par RIR (−0,012 à 0,018) | idem | idem |
| Échec vs non-échec (hypertrophie) | ES 0,19 (0,00–0,37), p = 0,045 ; échec musculaire momentané : 0,12 (−0,13 à 0,37) ; volume et charge non modérateurs | Refalo MC, Helms ER, Trexler ET, Hamilton DL, Fyfe JJ. *Influence of resistance training proximity-to-failure on skeletal muscle hypertrophy: a systematic review with meta-analysis.* Sports Med 2023;53(3):649–665. DOI 10.1007/s40279-022-01784-y | vérifié (résumé) |

**Forme fonctionnelle conseillée.** Gain(V) ∝ √V pour l'hypertrophie, et une saturation de type a − b/(V + c) pour la force (Pelland). Ordres de grandeur : environ 0,2–0,4 % de gain par série hebdomadaire autour de 10–12 séries. Fréquence importante pour la force.

---

## 5. Vitesse de progression de la force selon le niveau

| Affirmation | Chiffre | Source | Statut |
|---|---|---|---|
| Entraînement à dose minimale (1 séance/sem, 6 exercices, 1 série à l'échec), 14 690 personnes, âge moyen 48 ans | ≈ +30–50 % la 1re année ; ≈ +50–60 % du niveau initial vers 6 ans ; relation linéaire-log, quasi-plateau en 1–2 ans | Steele J, Fisher J, Giessing J, Androulakis-Korakakis P, Wolf M, Kroeske B, Reuters R. *Long-term time-course of strength adaptation to minimal dose resistance training through retrospective longitudinal growth modeling.* Res Q Exerc Sport 2023;94(4):913–930 (en ligne 2022). DOI 10.1080/02701367.2022.2070592 | vérifié (résumé) |
| Powerlifters en compétition (Australie) | gain ≈ 0,12 ± 0,69 kg/jour (femmes) et 0,15 ± 0,44 kg/jour (hommes) sur le total ; quartile le plus fort 0,102 vs le plus faible 0,211 kg/jour (hommes) ; ≈ 10,7 % au total chez les hommes ; 642 ± 609 jours entre première et dernière compétition | Latella C, Teo W-P, Spathis J, van den Hoek D. *Long-term strength adaptation: a 15-year analysis of powerlifting athletes.* J Strength Cond Res 2020;34(9):2412–2418 | vérifié (texte) |
| Powerlifters, modèles de croissance longitudinaux | ≈ +7,5–12,5 % la 1re année ; ≈ +12,5–20 % après 10 ans ; femmes plus rapides ; hommes Masters 4 (>69 ans) ≈ −0,35 %/an | Latella C, van den Hoek D, Wolf M, Androulakis-Korakakis P, Fisher JP, Steele J. *Longitudinal growth modelling of strength adaptations in powerlifting athletes across ages in males and females.* Prépublication SportRxiv 218 (DOI 10.51224/SRXIV.218) | vérifié (résumé) ; version publiée non trouvée |
| Athlètes élites (rugby, football américain) : gain par semaine | force +0,9 %/sem (2 séances par région musculaire), +1,8 % (3), +1,3 % (4) ; +0,42 % par séance | McMaster DT, Gill N, Cronin J, McGuigan M. *The development, retention and decay rates of strength and power in elite rugby union, rugby league and American football.* Sports Med 2013;43(5):367–384. DOI 10.1007/s40279-013-0031-3 | vérifié (résumé) |
| Élites, long terme | +7,1 % en 12 mois ; +8,5 % en 24 mois ; +12,5 % en 48 mois (≈ 0,6 → 0,26 %/mois) | idem | vérifié (résumé) ; taux mensuels = calcul |
| Débutant vs entraîné : doses optimales | non entraînés : 60 % 1RM, 3 j/sem, 4 séries ; entraînés : 80 %, 2 j/sem, 4 séries. ES par séance-type : non entraînés ≈ 2,3–2,8 ; entraînés ≈ 1,2–1,8 | Rhea MR, Alvar BA, Burkett LN, Ball SD. *A meta-analysis to determine the dose response for strength development.* Med Sci Sports Exerc 2003;35(3):456–464. DOI 10.1249/01.MSS.0000053727.63505.D4 | vérifié (résumé + tableaux) |
| Progression de charge recommandée (ACSM) | +2–10 % quand le sujet fait 1–2 rép. de plus que la cible ; fréquence novice 2–3 j/sem, intermédiaire 3–4, avancé 4–5 | Ratamess NA, Alvar BA, Evetoch TK, Housh TJ, Kibler WB, Kraemer WJ, Triplett NT. *ACSM position stand: Progression models in resistance training for healthy adults.* Med Sci Sports Exerc 2009;41(3):687–708. DOI 10.1249/MSS.0b013e3181915670 | vérifié (texte) |
| « Gains ≈ 40 % non entraînés, 20 % modérément entraînés, 16 % entraînés, 10 % avancés, 2 % élites » | — | **non trouvé** : absent des parties lues de l'ACSM 2009. Il s'agit peut-être de l'ACSM 2002 (Kraemer et al.), non lu. Source voisine : Rhea 2003 (ci-dessus), McMaster 2013 | non trouvé |

**Synthèse pour des a priori de pente (à présenter comme ordres de grandeur).**

| Niveau | Gain de force | Sources |
|---|---|---|
| Débutant | plusieurs % par mois au départ (30–50 % la 1re année) | Steele 2023 |
| Intermédiaire (powerlifter débutant en compétition) | ≈ 7–12 % par an | Latella prépublication |
| Élite | ≈ 0,3–0,6 % par mois | McMaster 2013 |

Dans tous les cas, la forme est log-linéaire et tend vers un plateau.

---

## 6. Modèles forme-fatigue, récupération et tendon

| Affirmation | Chiffre | Source | Statut |
|---|---|---|---|
| Modèle de réponse impulsionnelle d'origine (deux composantes) | — (références) | Banister EW, Calvert TW, Savage MV, Bach T. *A systems model of training for athletic performance.* Aust J Sports Med 1975;7:57–61 ; Calvert TW, Banister EW, Savage MV, Bach T. *A systems model of the effects of training on physical performance.* IEEE Trans Syst Man Cybern 1976;6:94–102 | seconde main (références citées par Busso 2003) |
| Constantes du modèle à dose-réponse variable | τ1 (forme) = 30,8 ± 1,6 j ; τ2 (fatigue) = 16,8 ± 3,3 j ; τ3 (décroissance du gain de fatigue k2) = 2,3 ± 1,0 j (n = 6) | Busso T. *Variable dose-response relationship between exercise training and performance.* Med Sci Sports Exerc 2003;35(7):1188–1195. DOI 10.1249/01.MSS.0000074465.13621.37 | vérifié (texte, tableau 2) |
| Délai de récupération selon la dose (simulation) | 400 u.e./j : retour à la ligne de base 5,9 j, pic 28,2 j ; 500 u.e./j : 15,1 j et 37,4 j | idem, tableau 4 | vérifié (texte) |
| Constantes classiques (Busso et al. 1991, cycloergomètre) | τ1 = 38 j ; τ2 = 1,9 j ; k1 = 0,048 ; k2 = 0,117 | Busso T, Carasso C, Lacour JR. *Adequacy of a systems structure in the modeling of training effects on performance.* J Appl Physiol 1991 | seconde main (Ceddia, Bondell, Taylor 2025, arXiv 2505.20859) |
| Récupération neuromusculaire après séance à l'échec (3×10 à l'échec) | saut vertical (CMJ) sous la ligne de base à 0, 6, 24 et 48 h, retour vers **72 h** ; sans échec (3×5 ou 6×5 avec la charge du 10RM) : récupéré dès 6 h ; vitesse au développé couché encore réduite à 48 h | Morán-Navarro R, Pérez CE, Mora-Rodríguez R, et al., Pallarés JG. *Time course of recovery following resistance training leading or not to failure.* Eur J Appl Physiol 2017;117:2387–2399. DOI 10.1007/s00421-017-3725-7 | vérifié (texte) |
| Synthèse du collagène tendineux après effort | pic vers **24 h**, élévation ≈ 3 jours ; dégradation à pic plus précoce | Magnusson SP, Langberg H, Kjaer M. *The pathogenesis of tendinopathy: balancing the response to loading.* Nat Rev Rheumatol 2010;6(5):262–268. DOI 10.1038/nrrheum.2010.43 (la page du dépôt écrit « Henning Langberg Jørgensen ») | vérifié (résumé) |
| Bilan net du collagène : négatif puis positif | bilan négatif ≈ **18–36 h**, puis positif jusqu'à ≈ 72 h ; synthèse ×2–3 | idem (figure de la revue) | seconde main (lettre SportsMed U « How much rest do tendons need? ») ; non lu dans le résumé |
| Adaptation du tendon à la charge (méta-analyse) | raideur SMD 0,70 (0,51–0,88) ; module de Young 0,69 (0,36–1,03) ; section transversale 0,24 (0,07–0,42) | Bohm S, Mersmann F, Arampatzis A. *Human tendon adaptation in response to mechanical loading: a systematic review and meta-analysis of exercise intervention studies on healthy adults.* Sports Med Open 2015;1:7. DOI 10.1186/s40798-015-0009-9 | vérifié (texte) |
| Intensité nécessaire | >70 % de la CMV ou du RM : raideur ES 0,90 vs 0,04 en dessous | idem | vérifié (texte) |
| Durée des interventions | 35/37 interventions de 8–14 semaines ; ≥12 sem : ES 0,91 vs 8–12 sem : 0,81 (n.s.) ; raideur pas encore accrue à 2 mois mais accrue à 3 mois (Kubo) | idem | vérifié (texte) |
| Délai de réponse des protéoglycanes et du collagène dans le tendon | grands protéoglycanes : minutes à quelques jours ; précurseurs du collagène I : pic ≈ 3 j après une séance intense ; petits protéoglycanes ≈ 20 j | Cook JL, Purdam CR. 2009 (voir §7) | vérifié (texte) |

**Justification des trois compartiments de fatigue (2,5 j / 7 j / 28 j).**
- **Nerveux, 2,5 j** : cohérent avec la récupération du CMJ en ≈ 72 h après une séance à l'échec (Morán-Navarro 2017) et avec τ3 = 2,3 j chez Busso 2003.
- **Musculaire, 7 j** : la littérature lue donne τ_fatigue entre 1,9 j (Busso 1991) et 16,8 j (Busso 2003). 7 j est une valeur centrale, mais aucune source lue ne donne « 7 j » telle quelle (le 7,0 ± 1,9 j cité par Busso 2003 est ambigu). Statut : **à présenter comme hypothèse**.
- **Tendineux, 28 j** : aucune constante de temps publiée n'a été trouvée. On peut la rattacher indirectement à trois éléments : (a) bilan collagène négatif sur 18–36 h, mais remodelage sur plusieurs semaines ; (b) adaptation de raideur mesurable en 8–12 semaines (Bohm 2015) ; (c) réponse des petits protéoglycanes ≈ 20 j (Cook & Purdam 2009). **Constante de temps tendineuse en jours : non trouvée.**

---

## 7. Charge, blessures, tendinopathie, progression en course

| Affirmation | Chiffre | Source | Statut |
|---|---|---|---|
| Paradoxe entraînement–prévention ; rapport de charge aiguë/chronique (ACWR) présenté comme meilleur prédicteur | — | Gabbett TJ. *The training-injury prevention paradox: should athletes be training smarter and harder?* Br J Sports Med 2016;50(5):273–280. DOI 10.1136/bjsports-2015-095788 | vérifié (résumé, base IAT Leipzig) |
| Zone « optimale » 0,8–1,3 ; risque accru au-delà de 1,5 | 0,8–1,3 / >1,5 | Gabbett 2016 (figure de l'article) | seconde main (Pogo Physio, sans attribution explicite) ; **non lu dans la source primaire** (captcha PMC, refus BMJ) |
| Consensus du CIO : mauvaise gestion de la charge = facteur de risque majeur | aucun seuil chiffré dans le résumé | Soligard T, Schwellnus M, Alonso JM, Bahr R, Clarsen B, Dijkstra HP, et al. *How much is too much? (Part 1) International Olympic Committee consensus statement on load in sport and risk of injury.* Br J Sports Med 2016;50:1030–1041. DOI 10.1136/bjsports-2016-096581 | vérifié (résumé) |
| Critique de l'ACWR | aucun effet causal estimé ; problèmes propres aux ratios ; relation incohérente et non unidirectionnelle ; « no evidence » pour l'utiliser dans la gestion de la charge | Impellizzeri FM, Tenan MS, Kempton T, Novak A, Coutts AJ. *Acute:chronic workload ratio: conceptual issues and fundamental pitfalls.* Int J Sports Physiol Perform 2020;15(6):907–913. DOI 10.1123/ijspp.2019-0864 | vérifié (résumé) |
| Continuum de la tendinopathie | 3 stades : réactive (réversible si la charge baisse) → désorganisation (« dysrepair », réversibilité partielle) → dégénérative (peu réversible) ; laisser 1–2 jours entre les charges élevées | Cook JL, Purdam CR. *Is tendon pathology a continuum? A pathology model to explain the clinical presentation of load-induced tendinopathy.* Br J Sports Med 2009;43:409–416. DOI 10.1136/bjsm.2008.051193 | vérifié (texte) |
| Modèle de surveillance de la douleur (tendinopathie d'Achille) | ECR, n = 38 ; pas de différence entre activité poursuivie et repos actif ; VISA-A 57 → 85 vs 57 → 91 à 12 mois | Silbernagel KG, Thomeé R, Eriksson BI, Karlsson J. *Continued sports activity, using a pain-monitoring model, during rehabilitation in patients with Achilles tendinopathy: a randomized controlled study.* Am J Sports Med 2007;35(6):897–906. DOI 10.1177/0363546506298279 | vérifié (résumé, PEDro) |
| Règles du modèle | douleur pendant l'activité < 5/10 (EVA) ; jusqu'à 5/10 tolérée après, mais résolue le lendemain matin ; pas d'aggravation d'une semaine à l'autre | idem | seconde main (Physical Therapy First) |
| Progression hebdomadaire >30 % chez le coureur débutant | pas de différence globale entre groupes ; blessures liées à la distance, >30 % vs <10 % : HR 1,59 (0,96–2,66 ; p = 0,07) ; 874 coureurs, 202 blessés | Nielsen RØ, Parner ET, Nohr EA, Sørensen H, Lind M, Rasmussen S. *Excessive progression in weekly running distance and risk of running-related injuries.* J Orthop Sports Phys Ther 2014;44(10):739–747. DOI 10.2519/jospt.2014.5164 | vérifié (résumé) |
| « Règle des 10 % » testée en essai randomisé | programme gradué (10 %) : 20,8 % de blessés vs standard 20,3 % (p = 0,90) | Buist I, Bredeweg SW, van Mechelen W, Lemmink KA, Pepping GJ, Diercks RL. *No effect of a graded training program on the number of running-related injuries in novice runners: a randomized controlled trial.* Am J Sports Med 2008;36(1):33–39 | vérifié (résumé, PEDro) |
| Pic de distance d'une séance vs plus longue sortie des 30 jours précédents | +10–30 % : HRR 1,64 (1,31–2,05) ; +30–100 % : 1,52 (1,16–2,00) ; >100 % : 2,28 (1,50–3,48) ; ACWR : relation dose-réponse **négative** ; ratio d'une semaine à l'autre : aucune relation ; 5 205 coureurs, 588 071 séances | Frandsen JSB, Hulme A, Parner ET, et al., Nielsen RO. *How much running is too much? Identifying high-risk running sessions in a 5200-person cohort study.* Br J Sports Med 2025;59(17):1203–1210. DOI 10.1136/bjsports-2024-109380 | vérifié (résumé) |

**Conséquence.** Pour la course, plafonner la **séance** à ≤ +10 % de la plus longue sortie des 30 derniers jours est mieux étayé (Frandsen 2025) que la règle hebdomadaire des 10 % (Buist 2008 : pas d'effet). L'ACWR peut servir d'indicateur, pas de garde-fou causal (Impellizzeri 2020).

---

## 8. Affûtage (taper)

| Affirmation | Chiffre | Source | Statut |
|---|---|---|---|
| Affûtage optimal (endurance surtout) | durée **2 semaines** ; réduction de volume **41–60 %** ; intensité et fréquence maintenues ; décroissance exponentielle | Bosquet L, Montpetit J, Arvisais D, Mujika I. *Effects of tapering on performance: a meta-analysis.* Med Sci Sports Exerc 2007;39(8):1358–1365. DOI 10.1249/mss.0b013e31806010e0 | vérifié (résumé de la communication ACSM 2007, page SDSU Coaching Science) ; taille d'effet globale **non lue** |
| Affûtage pour la force (revue) | réduire le volume en gardant ou en augmentant un peu l'intensité ; arrêt de l'entraînement < 1 semaine pour maintenir ; ≈ 2–4 jours d'arrêt pour améliorer la force maximale | Pritchard H, Keogh J, Barnes M, McGuigan M. *Effects and mechanisms of tapering in maximizing muscular strength.* Strength Cond J 2015;37(2):72–83. DOI 10.1519/SSC.0000000000000125 | vérifié (résumé, paraphrasé) |
| Powerlifting : affûtage | 1–2 semaines (exponentiel ou par paliers) ; volume −30 à −70 % (au moins −30–35 %, risqué au-delà de −70 %) ; intensité ≥ 85 % 1RM | Travis SK, Mujika I, Gentles JA, Stone MH, Bazyler CD. *Tapering and peaking maximal strength for powerlifting performance: a review.* Sports 2020;8(9):125. DOI 10.3390/sports8090125 | vérifié (texte) |
| Gains obtenus par affûtage chez des powerlifters | squat +2,3–5,9 % ; développé couché +1,8–6,4 % | idem | vérifié (texte) |
| Arrêt avant compétition | 2–7 j d'arrêt : performance maintenue ou améliorée ; >7 j : −1 à −4 % de force maximale | idem | vérifié (texte) |
| Pratiques réelles (364 powerlifters nord-américains) | affûtage par paliers sur 7–10 j ; volume −41–50 % ; dernière séance lourde (>85 %) : squat et soulevé de terre 7–10 j avant, développé couché < 7 j ; arrêt complet 2,8 ± 1,1 j avant | Travis SK, Pritchard HJ, Mujika I, Gentles JA, Stone MH, Bazyler CD. *Characterizing the tapering practices of United States and Canadian raw powerlifters.* J Strength Cond Res 2021;35(12S):S26–S35. DOI 10.1519/JSC.0000000000004177 | vérifié (résumé) |

---

## 9. Désentraînement

| Affirmation | Chiffre | Source | Statut |
|---|---|---|---|
| Effet de l'arrêt de l'entraînement de force | force sous-maximale SMD −0,62 (−0,80 à −0,45) ; force maximale −0,46 (−0,54 à −0,37) ; puissance maximale −0,20 (−0,28 à −0,13) ; dose-réponse avec la durée d'arrêt ; effet plus grand après 65 ans et chez les inactifs | Bosquet L, Berryman N, Dupuy O, Mekary S, Arvisais D, Bherer L, Mujika I. *Effect of training cessation on muscular performance: a meta-analysis.* Scand J Med Sci Sports 2013;23(3):e140–e149. DOI 10.1111/sms.12047 | vérifié (résumé) ; liste d'auteurs non affichée sur la page lue (citée de mémoire, **à vérifier**) |
| Élites : perte de force à l'arrêt | −14,5 % (ES −0,64) sur 7,2 ± 5,8 semaines en moyenne ; force **maintenue ≈ 3 semaines**, puis déclin accéléré (5–16 semaines) | McMaster et al. 2013 (voir §5) | vérifié (résumé) |
| Perte par semaine | ≈ 2 %/sem sur 7 semaines | McMaster 2013 | **calcul** (14,5 % / 7,2 sem) ; pas un chiffre des auteurs |
| Arrêt > 7 j avant une compétition | −1 à −4 % de force maximale | Travis et al. 2020 (voir §8) | vérifié (texte) |

---

## 10. Endurance

| Affirmation | Chiffre | Source | Statut |
|---|---|---|---|
| Loi de puissance temps-distance t = a·x^b | course, hommes **b = 1,07732** ; femmes 1,08283 (≈1,08) ; hommes de 40–70 ans 1,05–1,06 ; plage de validité ≈ 3,5–230 min | Riegel PS. *Athletic records and human endurance.* Am Sci 1981;69(3):285–290. JSTOR 27850427 | vérifié (texte, tableau 1) |
| L'exposant « 1,06 » | n'est **pas** la valeur du tableau de 1981 pour les coureurs élites (1,077) ; il correspond aux catégories vétérans (1,05–1,06). Il est repris par les calculateurs grand public | idem | vérifié (texte) — **à corriger dans Koach si 1,06 est attribué à Riegel 1981 sans nuance** |
| Vitesse ou puissance critique ≈ limite haute de l'état stable | puissance critique tenable ≈ 20–30 min au plus ; MLSS un peu en dessous de la puissance critique | *The maximal metabolic steady state: redefining the "gold standard".* Physiol Rep 2019 (Jones AM, Burnley M, Black MI, Poole DC, Vanhatalo A, d'après les résultats de recherche) | vérifié (résumé) ; volume et DOI non lus |
| Jones et al. 2010 (MSSE, puissance critique) | — | non ouvert ; seule une vidéo du symposium ACSM 2009 a été identifiée | non trouvé (bibliographie non vérifiée) |
| session-RPE | charge = RPE (CR-10, recueilli ≈ 30 min après la séance) × durée (min) ; relation régulière avec un score de FC par zones (5 zones pondérées de 1 à 5) ; aucun r rapporté | Foster C, Florhaug JA, Franklin J, Gottschall L, Hrovatin LA, Parker S, Doleshal P, Dodge C. *A new approach to monitoring exercise training.* J Strength Cond Res 2001;15(1):109–115 | vérifié (texte) |
| TRIMP à 3 zones (Lucia) | zones : < seuil ventilatoire / entre seuil ventilatoire et point de compensation respiratoire / > point de compensation ; durée × coefficient par zone (coefficients 1-2-3 **non lus**) | Lucia A, Hoyos J, Santalla A, Earnest CP, Chicharro JL. *Tour de France versus Vuelta a España: which is harder?* Med Sci Sports Exerc 2003;35(5):872–878 | vérifié (résumé) ; coefficients : non trouvé |
| TRIMP de Banister (formule exponentielle à la FC de réserve) | — | non lu | non trouvé |
| Distribution « polarisée » | ≈ 80 % des séances à basse intensité (≈ 2 mM de lactate) ; ≈ 20 % à haute intensité (≈ 90 % de la VO2max) | Seiler S. *What is best practice for training intensity and duration distribution in endurance athletes?* Int J Sports Physiol Perform 2010;5(3):276–291. DOI 10.1123/ijspp.5.3.276 | vérifié (résumé) |

---

## 11. Tenues isométriques jusqu'à l'échec : RPE et fraction du temps limite

| Affirmation | Chiffre | Source | Statut |
|---|---|---|---|
| Le RPE croît linéairement avec le temps ; sa pente prédit la durée | « RPE rose linearly throughout each trial » ; pente du RPE vs durée de l'essai : r = 0,83 (relation inverse) — **cyclisme à puissance fixe** | Crewe H, Tucker R, Noakes TD. *The rate of increase in rating of perceived exertion predicts the duration of exercise to fatigue at a fixed power output in different environmental conditions.* Eur J Appl Physiol 2008;103:569–577. DOI 10.1007/s00421-008-0741-7 | vérifié (résumé) |
| RPE linéaire en fonction de la **proportion** du temps jusqu'à l'épuisement | R² ≥ 0,88 ; écart de pente entre intensités sur le temps absolu, qui disparaît sur le temps relatif — **pédalage à bras** (dynamique) | Al-Rahamneh H, Eston R. *Rating of perceived exertion during two different constant-load exercise intensities during arm cranking in paraplegic and able-bodied participants.* Eur J Appl Physiol 2011;111(6):1055–1062. DOI 10.1007/s00421-010-1722-1 | vérifié (résumé) |
| RPE linéaire avec le pourcentage de durée effectuée (marche/course à 80 % VO2max) | RPE identique à l'épuisement quelle que soit la durée | Noakes TD. *Rating of perceived exertion as a predictor of the duration of exercise that remains until exhaustion.* Br J Sports Med 2008;42(7):623–624 (lettre), qui cite Cymerman A et al. 1979 | vérifié (texte de la lettre) ; Cymerman : seconde main |
| Isométrique soutenu (fléchisseurs du coude, 20 % CMV) : RPE à l'échec | RPE semblable à l'échec chez jeunes et âgés ; temps limite 22,6 ± 7,4 vs 13,0 ± 5,2 min ; évolution temporelle du RPE non rapportée dans le résumé | Hunter SK, Critchlow A, Enoka RM. *Muscle endurance is greater for old men compared with strength-matched young men.* J Appl Physiol 2005;99(3):890–897. DOI 10.1152/japplphysiol.00243.2005 | vérifié (résumé) |
| Linéarité du RPE en fonction de la fraction du temps limite **en contraction isométrique** | — | **non trouvé** dans une source lue. Pistes non ouvertes (accès refusé) : *The relationship between voluntary electromyogram, endurance time and intensity of effort in isometric handgrip exercise*, Eur J Appl Physiol (DOI 10.1007/BF00240408) ; Pincivero ; Smirmaul | non trouvé |

**Conséquence.** Le modèle « RPE(t) ≈ RPE0 + (10 − RPE0)·t/Tlim » est étayé pour l'exercice **dynamique** à charge constante (R² ≥ 0,88 sur le temps relatif). Pour l'isométrique, c'est une extrapolation à signaler comme hypothèse.

---

## 12. Adhérence et abandon

| Affirmation | Chiffre | Source | Statut |
|---|---|---|---|
| Abandon en salle de sport (5 240 membres, Brésil) | la plupart abandonnent **dans les 3 mois** ; **< 5 %** restent actifs plus de 12 mois | Sperandei S, Vieira MC, Reis AC. *Adherence to physical activity in an unsupervised setting: explanatory variables for high attrition rates among fitness center members.* J Sci Med Sport 2016;19(11):916–920 | seconde main (Sperandei et al. 2019, Athens J Sports 6(2):95–108, DOI 10.30958/ajspo.6-2-3, discussion) ; le chiffre de 63 % à 3 mois parfois cité n'a **pas** été vérifié |
| « Au moins 50 % des adultes abandonnent dans l'année » | ≥ 50 % à 1 an | Dishman et al. 1985 ; Sperandei 2016 | seconde main (Sperandei 2019, introduction) |
| Abandon des programmes supervisés ≈ 50 % | « 50 » (unité et délai non précisés dans le résumé indexé) | Dishman RK. *Exercise compliance: a new view for public health.* Phys Sportsmed 1986;14(5):127–145 | vérifié (résumé), mais chiffre ambigu |
| Retour après abandon | 38 % des personnes qui abandonnent reviennent dans les 12 mois, plus de la moitié dans le 1er mois | Sperandei 2019 (ci-dessus) | vérifié (résumé) |
| Intensité prescrite et adhérence (ECR, 379 sédentaires, 6 mois) | adhérence (% du prescrit) meilleure à intensité modérée (45–55 % de la FC de réserve) qu'élevée (65–75 %) (p = 0,02) ; plus de volume total à fréquence élevée (5–7 j) et à intensité modérée | Perri MG, Anton SD, Durning PE, et al. *Adherence to exercise prescriptions: effects of prescribing moderate versus higher levels of intensity and frequency.* Health Psychol 2002;21(5):452–458. DOI 10.1037/0278-6133.21.5.452 | vérifié (résumé) |
| Réponse affective et activité future | 24 études ; une hausse de l'affect **pendant** l'exercice modéré prédit l'activité future ; l'affect **après** l'exercice : relation nulle | Rhodes RE, Kates A. *Can the affective response to exercise predict future motives and physical activity behavior? A systematic review of published evidence.* Ann Behav Med 2015;49(5):715–731. DOI 10.1007/s12160-015-9704-5 | vérifié (résumé) |
| Facteurs interpersonnels et motivationnels | soutien à l'autonomie positif dans 11/11 études ; motivation intrinsèque positive dans 24/27 ; régulation externe négative dans 15/27 ; 35 études, 10 482 pratiquants | Rodrigues F, Bento T, Cid L, Neiva HP, Teixeira D, Moutão J, Marinho DA, Monteiro D. *Can interpersonal behavior influence the persistence and adherence to physical exercise practice in adults? A systematic review.* Front Psychol 2018;9:2141. DOI 10.3389/fpsyg.2018.02141 | vérifié (texte) |
| Taux d'abandon à 12 semaines d'un programme structuré ; effet de la **durée des séances** | — | **non trouvé** | non trouvé |

---

## 13. Méthodes statistiques (vérification bibliographique seulement)

| Référence | Détails vérifiés | Statut |
|---|---|---|
| Samejima F. *Estimation of latent ability using a response pattern of graded scores.* Psychometrika Monograph Supplement No. 17, 1969 | titre, autrice, n° 17, année | vérifié (PDF de la Psychometric Society) |
| Reckase MD. *Multidimensional Item Response Theory.* New York: Springer; 2009. DOI 10.1007/978-0-387-89976-3 | éditeur, DOI du livre | vérifié (résultat de recherche Springer) |
| Adams RP, MacKay DJC. *Bayesian online changepoint detection.* arXiv:0710.3742, 19 oct. 2007 | titre, auteurs, date | vérifié (page arXiv) |
| Thompson WR. *On the likelihood that one unknown probability exceeds another in view of the evidence of two samples.* Biometrika 1933;25(3/4):285–294 | titre et auteur vérifiés (PDF) ; pages 286–294 visibles ; revue et volume non imprimés sur l'extrait | partiellement vérifié |
| Russo DJ, Van Roy B, Kazerouni A, Osband I, Wen Z. *A tutorial on Thompson sampling.* Found Trends Mach Learn 2018;11(1):1–96. DOI 10.1561/2200000070 | tout | vérifié (now publishers) |
| Rubinstein RY. *The cross-entropy method for combinatorial and continuous optimization.* Methodol Comput Appl Probab 1999;1(2):127–190. DOI 10.1023/A:1010091220143 | tout | vérifié (IDEAS/RePEc) |
| de Boer P-T, Kroese DP, Mannor S, Rubinstein RY. *A tutorial on the cross-entropy method.* Ann Oper Res 2005;134:19–67 | tout | vérifié |
| Abadie A, Diamond A, Hainmueller J. *Synthetic control methods for comparative case studies: estimating the effect of California's tobacco control program.* J Am Stat Assoc 2010;105(490):493–505 | tout | vérifié (Harvard Kennedy School) |
| Lillie EO, Patay B, Diamant J, Issell B, Topol EJ, Schork NJ. *The n-of-1 clinical trial: the ultimate strategy for individualizing medicine?* Pers Med 2011;8(2):161–173. PMID 21695041 | titre et PMID (résultat PubMed) ; volume et pages non lus | partiellement vérifié |
| Duan N, Kravitz RL, Schmid CH. *Single-patient (n-of-1) trials: a pragmatic clinical decision methodology for patient-centered comparative effectiveness research.* J Clin Epidemiol 2013 (66(8 Suppl):S21–S28 non lu) | auteurs, année, revue (page Northwestern CEPIM) | partiellement vérifié |
| Villani C. *Optimal Transport: Old and New.* Grundlehren der mathematischen Wissenschaften 338. Berlin: Springer; 2009 | tout | vérifié (catalogue UiTM) |
| Peyré G, Cuturi M. *Computational Optimal Transport.* Found Trends Mach Learn 2019;11(5–6):355–607. arXiv:1803.00567 | titre, auteurs, volume 11 n° 5–6 (résultat now publishers) ; pages non affichées | partiellement vérifié |
| Minka TP. *Expectation propagation for approximate Bayesian inference.* UAI 2001:362–369 ; et *A family of algorithms for approximate Bayesian inference* (thèse MIT 2001, rapport technique Media Lab TR-533) | UAI : tout ; thèse : titre (résultats de recherche) | vérifié / partiellement vérifié |
| Feldbaum AA. *Dual control theory, Part I.* Automation and Remote Control 1960 (trad. 1961);21(9):874–880 ; Part II : 21(11):1033–1039 | tout | seconde main (Wikipédia « Dual control theory ») |
| Kalman RE. *A new approach to linear filtering and prediction problems.* Trans ASME J Basic Eng (Series D) 1960;82:35–45 | tout | vérifié (page UNC) |

---

## 14. Choix des tentatives en compétition de powerlifting

| Affirmation | Chiffre | Source | Statut |
|---|---|---|---|
| Taux de réussite par tentative (données OpenPowerlifting, **développé couché**, 15–69 ans) | sans équipement : 1re **0,86**, 2e **0,72**, 3e **0,40** (n = 175 983) ; mono-couche : 0,77 / 0,65 / 0,40 ; multi-couches : 0,70 / 0,57 / 0,35 | Nishihata M, Otani S. *Reference points, risk-taking behavior, and competitive outcomes in sequential settings.* Prépublication arXiv 2409.13333 (v4, 2026), tableau 2 | vérifié (texte) ; non relu par des pairs |
| Pression des concurrents | viser à dépasser un concurrent mieux classé fait baisser la réussite à la 3e tentative (≈ −0,038) | idem | vérifié (texte) |
| Taille du saut entre tentatives et réussite (IPF, 93 333 athlètes) | hommes squat/soulevé de terre : sauts de 5–20 kg favorables, déclin au-delà de 20 kg ; hommes développé couché : déclin marqué au-delà de 10 kg ; femmes squat ≤ 8 kg ; femmes développé couché : chute au-delà de 4 kg à la 3e ; 3e tentative toujours moins réussie que la 2e | Darragh IAJ, Egan B, Nolan D, Bennett KE. *Predicting a successful attempt in raw powerlifting: a nonlinear mixed logistic regression analysis.* J Strength Cond Res 2025 | vérifié (résumé, page DCU) ; taux en % non donnés dans le résumé |
| Stratégie d'ouverture (% du 1RM de l'ouverture) | — | **non trouvé** (Travis 2021 ne donne pas de % d'ouverture dans le résumé). Voisin : intensités des dernières séances lourdes, 90–92,5 % 1RM (Travis 2021, §8) | non trouvé |

---

## 15. Auto-régulation par RIR/RPE vs pourcentage

| Affirmation | Chiffre | Source | Statut |
|---|---|---|---|
| RPE vs %1RM, programmes à séries et répétitions égales (21 hommes entraînés, 8 semaines) | squat +17,05 ± 5,44 kg (RPE) vs +13,91 ± 5,89 kg (%1RM), ES 0,50 ± 0,63 ; développé couché +10,70 vs +9,64 kg, ES 0,28 ; différences entre groupes n.s. ; « both loading-types are effective » | Helms ER, Byrnes RK, Cooke DM, et al., Zourdos MC. *RPE vs. percentage 1RM loading in periodized programs matched for sets and repetitions.* Front Physiol 2018;9:247. DOI 10.3389/fphys.2018.00247 | vérifié (résumé) |
| RIR auto-régulé vs charge fixe (31 hommes entraînés, 12 semaines, squat 2×/sem) | squat avant +11,7 % vs +8,3 % (p = 0,004, ηp² = 0,255) ; squat arrière +10,8 % vs +7,1 % (p = 0,006, ηp² = 0,233) | Graham T, Cleather DJ. *Autoregulation by "repetitions in reserve" leads to greater improvements in strength over a 12-week training program than fixed loading.* J Strength Cond Res (en ligne 2019 ; numéro de 2021 non vérifié). DOI 10.1519/JSC.0000000000003164 | vérifié (texte, manuscrit accepté St Mary's) |
| Méta-analyse : auto-régulation de la charge vs charge standard | 1RM : MD 2,07 kg (−0,32 à 4,46), p = 0,09, SMD 0,21 (n.s.) ; volume auto-régulé par perte de vitesse ≤ 25 % vs > 25 % : force +2,32 kg (p = 0,02) mais hypertrophie moindre (0,61 cm², p = 0,03) | Hickmott LM, Chilibeck PD, Shaw KA, Butcher SJ. *The effect of load and volume autoregulation on muscular strength and hypertrophy: a systematic review and meta-analysis.* Sports Med Open 2022;8:9. DOI 10.1186/s40798-021-00404-9 | vérifié (résumé) |
| Méta-analyse chez des athlètes : auto-régulation vs charge fixe | SMD global 0,64 (0,43–0,85 ; I² = 0 %) ; APRE 0,78 ; RPE 0,17 (−0,33 à 0,67, n.s.) ; VBT 0,43 (n.s.) ; squat MD 4,65 kg ; développé couché 3,21 kg | Zhang X, Li H, Bi S, Luo Y, Cao Y, Zhang G. *Auto-regulation method vs. fixed-loading method in maximum strength training for athletes: a systematic review and meta-analysis.* Front Physiol 2021;12:651112. DOI 10.3389/fphys.2021.651112 | vérifié (texte) ; incohérence interne sur l'attribution court/long terme des SMD 0,87/0,32 |

**Conséquence.** L'auto-régulation par RIR est **au moins équivalente** au pourcentage, avec un petit avantage possible (Helms 2018, Graham & Cleather). Les méta-analyses divergent : Hickmott n'a pas d'effet significatif, Zhang a un effet modéré porté par l'APRE et non par le RPE seul.

---

## Corrections et alertes pour le cahier Koach

1. **Riegel 1981** : l'exposant du tableau pour la course est 1,077 (hommes) et 1,083 (femmes). « 1,06 » ne correspond qu'aux vétérans de 40–70 ans.
2. **Armes 2020** est paru dans *Frontiers in Psychology* et **Remmert 2023** dans *Perceptual and Motor Skills*, pas dans JSCR.
3. **Halperin** : volume 52 de *Sports Medicine*, daté de 2022, mis en ligne en 2021.
4. **Magnusson, Langberg, Kjaer 2010** : la fenêtre de bilan négatif du collagène est de **18–36 h** selon la source secondaire lue, et non 24–36 h. Le résumé ne donne que « pic de synthèse vers 24 h, élévation ≈ 3 jours ».
5. **Gabbett 0,8–1,3 / 1,5** : chiffres non relus dans la source primaire. Frandsen 2025 trouve une relation ACWR–blessure **négative** en course.
6. Les **constantes de 7 j (musculaire) et 28 j (tendineuse)** n'ont pas de source directe. Ce sont des choix de modélisation, encadrés par Busso (τ_fatigue 1,9–16,8 j) et par l'adaptation du tendon en 8–12 semaines (Bohm 2015).
