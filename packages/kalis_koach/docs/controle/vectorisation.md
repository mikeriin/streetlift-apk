# Vectorisation de Koach — contrôle (lot GK)

Généré par `tools/koach/build_koach.py`. IoU = intersection / union entre le rendu des
commandes **relues dans le fichier Dart généré** (couverture anticrénelée 4×4) et la silhouette
source nettoyée (« IoU »), ou l’encre brute seuillée sans nettoyage (« IoU brut » : les traits
de séparation, épaissis et régularisés, y comptent comme écart), en pixels de la planche d’origine.
Exigence du lot : IoU ≥ 0,97 par pose.

- Hauteur d’une pose en pied : 1000 unités (pointe de la flamme → pieds).
- Tête de référence des bustes : 483.9 unités (médiane des poses en pied).
- Cadre commun (unités, marge 40) : [-710, -1196, 954, 41].
- Poids du Dart généré : poses 324986 o, flammes 34486 o, fiches 11350 o (total 370822 o ; plafond 400 000 o).
- Nettoyage : {"A": {"line_parts": 106, "line_seed_px": 25063, "line_px": 60741, "ink_specks": 1, "paper_specks": 6}, "B": {"line_parts": 62, "line_seed_px": 19359, "line_px": 48897, "ink_specks": 1, "paper_specks": 11}, "C": {"line_parts": 95, "line_seed_px": 33144, "line_px": 78086, "ink_specks": 2, "paper_specks": 8}}.

| # | Pose | Planche | IoU | IoU brut | Yeux (solidité) | Regard (calculé) | Bulle | Cadrage | Tête (u) | Entiers encre/papier/yeux |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `explain_board` | A 1.1 | 0.9902 | 0.9877 | open (1.01/1.01) | right (right, 0.184) | left | full | 503.1 | 1679/505/119 |
| 2 | `read_tip` | A 1.2 | 0.9929 | 0.9837 | open (1.01/1.01) | front (front, -0.041) | left | full | 489.1 | 1490/859/119 |
| 3 | `anatomy` | A 1.3 | 0.9903 | 0.9769 | open (1.01/1.01) | right (right, 0.142) | left | full | 480.1 | 2570/1529/106 |
| 4 | `progress_chart` | A 2.1 | 0.9932 | 0.9909 | open (1.01/1.01) | right (right, 0.081) | left | full | 501.8 | 1289/446/111 |
| 5 | `think` | A 2.2 | 0.9943 | 0.9881 | open (1.01/1.01) | front (front, 0.009) | left | full | 503.1 | 1136/630/105 |
| 6 | `checklist` | A 2.3 | 0.9923 | 0.9867 | open (1.01/1.01) | right (right, 0.143) | left | full | 499.9 | 1595/1067/126 |
| 7 | `choice` | A 3.1 | 0.9934 | 0.9921 | open (1.01/1.01) | front (front, 0.012) | left | bust | 483.9 | 1194/582/106 |
| 8 | `idea` | A 3.2 | 0.9934 | 0.9877 | open (1.01/1.01) | right (right, 0.163) | left | bust | 483.9 | 1315/681/120 |
| 9 | `settings` | A 3.3 | 0.9939 | 0.9908 | open (1.01/1.01) | right (right, 0.214) | left | bust | 483.9 | 1244/587/125 |
| 10 | `determined` | A 4.1 | 0.9936 | 0.9826 | open (1.01/1.01) | right (right, 0.187) | right | full | 488.2 | 1221/712/119 |
| 11 | `direction` | A 4.2 | 0.9937 | 0.9895 | open (1.01/1.01) | right (right, 0.155) | left | full | 500.1 | 1493/744/125 |
| 12 | `analyze` | A 4.3 | 0.9933 | 0.9898 | open (1.01/1.01) | right (right, 0.202) | left | full | 517.3 | 1168/554/98 |
| 13 | `wave` | B 1.1 | 0.9933 | 0.9898 | open (1.01/1.01) | left (left, -0.085) | left | full | 476.1 | 1094/489/99 |
| 14 | `thumbs_up` | B 1.2 | 0.9932 | 0.9867 | open (1.01/1.01) | left (left, -0.094) | left | full | 496.5 | 1091/556/113 |
| 15 | `happy` | B 1.3 | 0.9930 | 0.9917 | closed (0.76/0.72) | front (front, 0.007) | right | full | 490.8 | 1204/436/0 |
| 16 | `point` | B 2.1 | 0.9933 | 0.9892 | open (1.01/1.01) | right (right, 0.102) | left | full | 491.4 | 993/493/113 |
| 17 | `ponder` | B 2.2 | 0.9927 | 0.9707 | open (1.01/1.01) | front (front, 0.002) | left | full | 465.0 | 929/522/113 |
| 18 | `shrug` | B 2.3 | 0.9937 | 0.9934 | open (1.01/1.01) | front (front, 0.009) | left | full | 493.5 | 887/167/105 |
| 19 | `oops` | B 3.1 | 0.9921 | 0.9744 | open (1.01/1.01) | left (left, -0.313) | left | full | 528.7 | 1281/782/97 |
| 20 | `please` | B 3.2 | 0.9929 | 0.9755 | open (0.84/0.86) | front (front, 0.014) | left | full | 505.3 | 1065/684/120 |
| 21 | `love` | B 3.3 | 0.9923 | 0.9794 | open (1.01/1.01) | front (front, -0.01) | left | full | 483.9 | 1229/659/112 |
| 22 | `flex` | B 4.1 | 0.9934 | 0.9901 | open (1.01/1.01) | right (right, 0.207) | right | full | 462.5 | 932/366/106 |
| 23 | `run` | B 4.2 | 0.9930 | 0.9901 | open (1.01/1.01) | right (right, 0.259) | right | full | 449.2 | 1133/205/113 |
| 24 | `victory` | B 4.3 | 0.9931 | 0.9915 | closed (0.75/0.78) | front (front, 0.004) | left | full | 461.0 | 1215/482/0 |
| 25 | `thumbs_up_2` | C 1.1 | 0.9942 | 0.9888 | open (1.01/1.01) | front (front, -0.042) | right | full | 464.9 | 1270/620/127 |
| 26 | `cheer` | C 1.2 | 0.9940 | 0.9889 | closed (0.69/0.68) | front (front, 0.01) | right | full | 432.7 | 1320/630/0 |
| 27 | `pump` | C 1.3 | 0.9947 | 0.9901 | open (1.01/1.01) | front (front, -0.001) | left | full | 505.1 | 1189/612/117 |
| 28 | `flag` | C 1.4 | 0.9939 | 0.9900 | open (1.01/1.01) | right (right, 0.07) | left | full | 483.6 | 1353/656/110 |
| 29 | `fist_bump` | C 2.1 | 0.9935 | 0.9812 | open (1.01/1.01) | right (right, 0.111) | right | full | 477.1 | 1576/928/133 |
| 30 | `heart` | C 2.2 | 0.9938 | 0.9829 | closed (0.77/0.74) | front (front, -0.017) | left | full | 465.4 | 1454/1001/0 |
| 31 | `you` | C 2.3 | 0.9930 | 0.9821 | open (1.01/1.01) | left (left, -0.194) | left | full | 479.3 | 1648/1118/99 |
| 32 | `double_biceps` | C 2.4 | 0.9950 | 0.9929 | open (1.01/1.01) | front (front, 0.023) | right | full | 470.7 | 907/337/96 |
| 33 | `clap` | C 3.1 | 0.9941 | 0.9840 | closed (0.75/0.76) | right (right, 0.11) | right | full | 423.2 | 1494/829/0 |
| 34 | `sprint` | C 3.2 | 0.9937 | 0.9907 | open (1.01/1.01) | right (right, 0.253) | right | full | 440.6 | 1218/478/112 |
| 35 | `fist_up` | C 3.3 | 0.9948 | 0.9916 | closed (0.74/0.76) | front (front, 0.004) | right | full | 440.2 | 1149/583/0 |
| 36 | `present` | C 3.4 | 0.9946 | 0.9900 | closed (0.67/0.7) | front (front, 0.0) | right | full | 485.0 | 1309/805/0 |

| Flamme | IoU | Hauteur source (px) | Part du creux | Boîte (unités) |
| --- | --- | --- | --- | --- |
| 1 | 0.9908 | 80.2 | 0.094 | [-149, -411, 149, 0] |
| 2 | 0.9924 | 94.2 | 0.09 | [-179, -482, 179, 0] |
| 3 | 0.9932 | 105.2 | 0.094 | [-207, -538, 207, 0] |
| 4 | 0.9930 | 118.0 | 0.106 | [-233, -604, 233, 0] |
| 5 | 0.9939 | 130.2 | 0.109 | [-260, -667, 260, 0] |
| 6 | 0.9942 | 141.8 | 0.11 | [-283, -726, 283, 0] |
| 7 | 0.9947 | 154.0 | 0.125 | [-300, -787, 301, 0] |
| 8 | 0.9947 | 166.2 | 0.133 | [-323, -851, 323, 0] |
| 9 | 0.9957 | 179.5 | 0.125 | [-344, -919, 345, 0] |
| 10 | 0.9957 | 195.5 | 0.135 | [-386, -1000, 386, 0] |
