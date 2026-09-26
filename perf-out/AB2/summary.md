# Banc hôte L6 — synthèse

Mesure hôte (flutter_tester, JIT debug, sans GPU) : compare deux versions du code sur la même machine ; ce n'est pas une durée sur téléphone.

Fichiers : base-r1.jsonl, base-r2.jsonl, base-r3.jsonl, base-r4.jsonl, base-r5.jsonl, cand-r1.jsonl, cand-r2.jsonl, cand-r3.jsonl, cand-r4.jsonl, cand-r5.jsonl

| Scénario | Profil | Unité | Base n | Base médiane [min–max] | Cand. n | Cand. médiane [min–max] | Ratio | Conclusion |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| catalog.estimate.pass2 | charge | ms | 45 | 126.718 [74.601–276.736] | 45 | 0.213 [0.165–0.543] | 0.002 | amélioration |
| catalog.estimate.pass2 | long | ms | 45 | 13.074 [12.528–37.704] | 45 | 0.219 [0.2–0.296] | 0.017 | amélioration |
| catalog.generate | - | ms | 45 | 3.267 [3.189–4.152] | 45 | 3.23 [3.154–3.951] | 0.989 | gain non démontré |
| catalog.rank | long | ms | 45 | 25.22 [23.736–28.957] | 45 | 12.329 [11.933–15.697] | 0.489 | amélioration |
| catalog.recommended | long | ms | 45 | 22.802 [22.015–25.892] | 45 | 23.082 [21.905–24.685] | 1.012 | gain non démontré |
| catalog.wodStats.all | long | ms | 45 | 21.127 [20.491–22.392] | 45 | 0.644 [0.558–0.859] | 0.03 | amélioration |
| derive.progression | charge | ms | 45 | 43.418 [39.79–67.618] | 45 | 42.214 [40.93–43.952] | 0.972 | gain non démontré |
| derive.progression | long | ms | 45 | 13.362 [12.111–15.117] | 45 | 12.898 [12.339–13.875] | 0.965 | gain non démontré |
| derive.progression | neuf | ms | 45 | 0.044 [0.04–0.638] | 45 | 0.069 [0.059–3.198] | 1.568 | gain non démontré |
| derive.progression | regulier | ms | 45 | 3.471 [3.329–4.41] | 45 | 3.4 [3.296–4.666] | 0.98 | gain non démontré |
| derive.progression+game | charge | ms | 45 | 60.896 [58.015–66.275] | 45 | 60.775 [58.587–64.284] | 0.998 | gain non démontré |
| derive.progression+game | long | ms | 45 | 22.06 [20.235–25.259] | 45 | 21.506 [20.665–24.516] | 0.975 | gain non démontré |
| derive.progression+game | neuf | ms | 45 | 0.164 [0.153–2.057] | 45 | 0.182 [0.143–2.556] | 1.11 | gain non démontré |
| derive.progression+game | regulier | ms | 45 | 5.984 [5.679–13.126] | 45 | 5.839 [5.653–6.717] | 0.976 | gain non démontré |
| import.apply | charge | ms | 25 | 842.241 [767.138–917.559] | 25 | 794.46 [752.6–863.319] | 0.943 | gain non démontré |
| import.apply | long | ms | 25 | 360.15 [254.938–366.707] | 25 | 319.022 [221.88–366.083] | 0.886 | gain non démontré |
| import.apply | regulier | ms | 25 | 118.038 [111.025–213.835] | 25 | 79.835 [75.584–169.941] | 0.676 | amélioration |
| import.preview | charge | ms | 25 | 413.959 [388.595–432.217] | 25 | 406.331 [378.483–445.615] | 0.982 | gain non démontré |
| import.preview | long | ms | 25 | 124.614 [113.196–145.482] | 25 | 122.793 [104.5–136.297] | 0.985 | gain non démontré |
| import.preview | regulier | ms | 25 | 34.176 [31.824–73.788] | 25 | 29.105 [27.26–70.328] | 0.852 | gain non démontré |
| save.encode.exportAll | charge | ms | 45 | 80.87 [64.507–92.173] | 45 | 75.662 [54.454–117.364] | 0.936 | gain non démontré |
| save.encode.exportAll | long | ms | 45 | 21.928 [20.941–44.898] | 45 | 18.605 [15.827–43.491] | 0.848 | gain non démontré |
| save.encode.exportAll | neuf | ms | 45 | 3.916 [3.766–4.697] | 45 | 0.388 [0.184–0.832] | 0.099 | amélioration |
| save.encode.exportAll | regulier | ms | 45 | 8.279 [8.04–9.892] | 45 | 4.456 [4.227–6.644] | 0.538 | amélioration |
| save.keystroke+flush | charge | ms | 45 | 133.753 [103.437–163.722] | 45 | 126.695 [96.934–154.887] | 0.947 | gain non démontré |
| save.keystroke+flush | long | ms | 45 | 39.157 [36.614–65.415] | 45 | 36.228 [31.727–54.09] | 0.925 | gain non démontré |
| save.keystroke+flush | neuf | ms | 45 | 4.109 [3.975–5.305] | 45 | 0.626 [0.333–0.725] | 0.152 | amélioration |
| save.keystroke+flush | regulier | ms | 45 | 13.113 [12.563–29.376] | 45 | 9.289 [8.762–20.762] | 0.708 | amélioration |
| save.toggleSet+derive+flush | charge | ms | 45 | 218.913 [188.453–245.718] | 45 | 207.71 [182.938–252.668] | 0.949 | gain non démontré |
| save.toggleSet+derive+flush | long | ms | 45 | 66.343 [62.122–111.163] | 45 | 59.04 [54.18–102.668] | 0.89 | gain non démontré |
| save.toggleSet+derive+flush | neuf | ms | 45 | 7.704 [4.299–9.038] | 45 | 1.149 [0.699–1.327] | 0.149 | amélioration |
| save.toggleSet+derive+flush | regulier | ms | 45 | 19.169 [18.568–23.678] | 45 | 15.193 [14.622–21.661] | 0.793 | amélioration |
| stats.exerciseBests | charge | ms | 45 | 10.801 [9.914–12.549] | 45 | 11.317 [10.213–12.745] | 1.048 | gain non démontré |
| stats.exerciseBests | long | ms | 45 | 5.723 [5.444–7.676] | 45 | 5.592 [5.445–6.334] | 0.977 | gain non démontré |
| stats.exerciseBests | neuf | ms | 45 | 0.0 [0.0–0.001] | 45 | 0.0 [0.0–0.002] |  | gain non démontré |
| stats.exerciseBests | regulier | ms | 45 | 1.555 [1.508–1.917] | 45 | 1.552 [1.503–2.08] | 0.998 | gain non démontré |
| stats.history | charge | ms | 45 | 5.217 [5.025–6.194] | 45 | 5.192 [5.028–6.056] | 0.995 | gain non démontré |
| stats.history | long | ms | 45 | 1.385 [1.228–2.667] | 45 | 1.309 [1.232–2.591] | 0.945 | gain non démontré |
| stats.history | neuf | ms | 45 | 0.043 [0.039–0.068] | 45 | 0.042 [0.037–0.066] | 0.977 | gain non démontré |
| stats.history | regulier | ms | 45 | 0.396 [0.276–0.625] | 45 | 0.402 [0.276–0.81] | 1.015 | gain non démontré |
| stats.weeklyMuscles | charge | ms | 45 | 37.301 [35.615–48.002] | 45 | 37.177 [35.708–46.586] | 0.997 | gain non démontré |
| stats.weeklyMuscles | long | ms | 45 | 11.486 [10.017–14.103] | 45 | 10.524 [10.142–11.752] | 0.916 | gain non démontré |
| stats.weeklyMuscles | neuf | ms | 45 | 0.065 [0.056–4.051] | 45 | 0.061 [0.056–0.102] | 0.938 | gain non démontré |
| stats.weeklyMuscles | regulier | ms | 45 | 2.986 [2.872–3.277] | 45 | 2.928 [2.792–3.389] | 0.981 | gain non démontré |
| store.init | charge | ms | 45 | 423.569 [390.967–476.822] | 45 | 399.687 [368.601–418.849] | 0.944 | gain non démontré |
| store.init | long | ms | 45 | 251.977 [149.498–277.889] | 45 | 214.984 [121.85–249.364] | 0.853 | gain non démontré |
| store.init | neuf | ms | 45 | 65.563 [59.136–145.577] | 45 | 45.777 [40.242–120.988] | 0.698 | gain non démontré |
| store.init | regulier | ms | 45 | 143.701 [93.538–225.079] | 45 | 89.722 [69.409–168.645] | 0.624 | gain non démontré |
| ui.appearance.switch | charge | ms | 25 | 425.011 [299.648–573.388] | 25 | 418.62 [297.348–537.333] | 0.985 | gain non démontré |
| ui.appearance.switch | long | ms | 25 | 198.977 [151.5–382.252] | 25 | 182.662 [155.977–344.537] | 0.918 | gain non démontré |
| ui.catalog.open | charge | ms | 25 | 82.463 [80.09–217.637] | 25 | 84.089 [82.284–227.487] | 1.02 | gain non démontré |
| ui.catalog.open | long | ms | 25 | 92.805 [86.039–97.898] | 25 | 103.944 [93.323–109.18] | 1.12 | gain non démontré |
| ui.catalog.scroll60 | charge | ms | 25 | 27.46 [25.816–113.652] | 25 | 27.365 [24.098–39.12] | 0.997 | gain non démontré |
| ui.catalog.scroll60 | long | ms | 25 | 39.551 [35.983–53.674] | 25 | 40.705 [34.971–100.887] | 1.029 | gain non démontré |
| ui.catalog.search | charge | ms | 25 | 39.206 [33.469–52.296] | 25 | 40.993 [35.436–44.796] | 1.046 | gain non démontré |
| ui.catalog.search | long | ms | 25 | 58.548 [45.511–154.895] | 25 | 59.882 [52.201–184.362] | 1.023 | gain non démontré |
| ui.firstFrame | charge | ms | 25 | 43.068 [39.838–46.366] | 25 | 42.342 [40.338–51.155] | 0.983 | gain non démontré |
| ui.firstFrame | long | ms | 25 | 88.226 [63.126–176.847] | 25 | 87.403 [63.878–119.477] | 0.991 | gain non démontré |
| ui.memory.rss10cycles | charge | bytes | 10 | 681017344.0 [628948992–732520448] | 10 | 697462784.0 [620253184–753057792] | 1.024 | brut (hors comparaison) |
| ui.memory.rss10cycles | long | bytes | 10 | 506161152.0 [469032960–546529280] | 10 | 482529280.0 [443822080–522088448] | 0.953 | brut (hors comparaison) |
| ui.nav.firstVisit.arsenal | charge | ms | 15 | 112.858 [102.157–255.27] | 15 | 122.171 [110.58–271.166] | 1.083 | gain non démontré |
| ui.nav.firstVisit.programmeReturn | charge | ms | 15 | 101.47 [98.173–166.726] | 15 | 120.99 [98.922–263.178] | 1.192 | gain non démontré |
| ui.nav.firstVisit.stats | charge | ms | 15 | 30.455 [25.247–67.32] | 15 | 32.18 [23.956–59.686] | 1.057 | gain non démontré |
| ui.nav.firstVisit.statsSections | charge | ms | 45 | 84.344 [20.627–220.416] | 45 | 71.799 [22.208–231.97] | 0.851 | gain non démontré |
| ui.nav.firstVisit.arsenal | long | ms | 15 | 156.59 [100.254–413.496] | 15 | 133.704 [94.743–356.423] | 0.854 | gain non démontré |
| ui.nav.firstVisit.programmeReturn | long | ms | 15 | 145.154 [88.826–176.591] | 15 | 103.389 [81.708–187.195] | 0.712 | gain non démontré |
| ui.nav.firstVisit.stats | long | ms | 15 | 120.534 [42.471–243.129] | 15 | 82.885 [37.969–170.594] | 0.688 | gain non démontré |
| ui.nav.firstVisit.statsSections | long | ms | 45 | 86.834 [36.434–312.702] | 45 | 90.832 [36.037–296.861] | 1.046 | gain non démontré |
| ui.session.keystroke | charge | ms | 100 | 93.043 [87.151–276.576] | 100 | 0.044 [0.04–0.188] | 0.0 | amélioration |
| ui.session.popFirstFrame | charge | ms | 20 | 11.606 [11.051–28.433] | 20 | 50.779 [23.4–159.78] | 4.375 | régression |
| ui.session.popSettle | charge | ms | 20 | 135.753 [127.71–262.171] | 20 | 153.163 [137.451–261.651] | 1.128 | gain non démontré |
| ui.session.toggleSet | charge | ms | 40 | 177.858 [159.965–392.625] | 40 | 0.048 [0.043–0.179] | 0.0 | amélioration |
| ui.session.keystroke | long | ms | 100 | 99.874 [58.948–215.189] | 100 | 0.093 [0.056–0.641] | 0.001 | amélioration |
| ui.session.popFirstFrame | long | ms | 20 | 17.457 [13.641–72.808] | 20 | 65.096 [32.709–129.296] | 3.729 | régression |
| ui.session.popSettle | long | ms | 20 | 60.043 [52.527–113.067] | 20 | 80.47 [69.144–113.693] | 1.34 | gain non démontré |
| ui.session.toggleSet | long | ms | 40 | 118.824 [99.667–244.695] | 40 | 0.097 [0.061–0.273] | 0.001 | amélioration |
| ui.stats.visibleNotify | charge | ms | 50 | 169.256 [154.827–392.113] | 50 | 16.205 [13.291–20.873] | 0.096 | amélioration |
| ui.stats.visibleNotify | long | ms | 50 | 108.582 [95.579–230.003] | 50 | 15.708 [13.585–25.79] | 0.145 | amélioration |

## Résultats métier (empreintes base / candidate)

| Profil | Champ | Verdict (base / candidate) |
| --- | --- | --- |
| charge | bests | identique (18ce07fb35c397a9 / 18ce07fb35c397a9) |
| charge | credits | identique (-77 / -77) |
| charge | estimates | identique (77af5c98347524ab / 77af5c98347524ab) |
| charge | export | identique (63c783420526a41b / 63c783420526a41b) |
| charge | history | identique (21d0f25f63be420f / 21d0f25f63be420f) |
| charge | level | identique (92 / 92) |
| charge | muscles | identique (5acd64723970c1a3 / 5acd64723970c1a3) |
| charge | recommended | identique (-69e8b78a735b219a / -69e8b78a735b219a) |
| charge | wodLevels | identique (-34e5fae491df5f84 / -34e5fae491df5f84) |
| charge | xp | identique (220015 / 220015) |
| long | bests | identique (-12b9593e787b9f58 / -12b9593e787b9f58) |
| long | credits | identique (111 / 111) |
| long | estimates | identique (527ad85574e530f8 / 527ad85574e530f8) |
| long | export | identique (29492838ba63ce10 / 29492838ba63ce10) |
| long | history | identique (-e4f854e47a64d82 / -e4f854e47a64d82) |
| long | level | identique (51 / 51) |
| long | muscles | identique (-4adf6367afc0a2a / -4adf6367afc0a2a) |
| long | recommended | identique (-69e8b78a735b219a / -69e8b78a735b219a) |
| long | wodLevels | identique (4137b7190bb9a8f7 / 4137b7190bb9a8f7) |
| long | xp | identique (70135 / 70135) |
| neuf | bests | identique (-340d631b7bdddcdb / -340d631b7bdddcdb) |
| neuf | credits | identique (3 / 3) |
| neuf | estimates | identique (527ad85574e530f8 / 527ad85574e530f8) |
| neuf | export | identique (24e5920facda1d25 / 24e5920facda1d25) |
| neuf | history | identique (-340d631b7bdddcdb / -340d631b7bdddcdb) |
| neuf | level | identique (1 / 1) |
| neuf | muscles | identique (3a392c97dd457cb6 / 3a392c97dd457cb6) |
| neuf | recommended | identique (6fa61ffa929209a3 / 6fa61ffa929209a3) |
| neuf | wodLevels | identique (4137b7190bb9a8f7 / 4137b7190bb9a8f7) |
| neuf | xp | identique (0 / 0) |
| regulier | bests | identique (-5f40d7b655e09619 / -5f40d7b655e09619) |
| regulier | credits | identique (53 / 53) |
| regulier | estimates | identique (527ad85574e530f8 / 527ad85574e530f8) |
| regulier | export | identique (7de0eaa0935b0bb4 / 7de0eaa0935b0bb4) |
| regulier | history | identique (-4a6073a74d3adff9 / -4a6073a74d3adff9) |
| regulier | level | identique (25 / 25) |
| regulier | muscles | identique (3a392c97dd457cb6 / 3a392c97dd457cb6) |
| regulier | recommended | identique (3031c157bae209ad / 3031c157bae209ad) |
| regulier | wodLevels | identique (4137b7190bb9a8f7 / 4137b7190bb9a8f7) |
| regulier | xp | identique (17425 / 17425) |

## Environnement (première ligne méta de chaque fichier)

- base : Dart 3.7.2 (stable) (Tue Mar 11 04:27:50 2025 -0700) on "linux_x64" ; linux Linux 6.17.0-1022-azure #22-Ubuntu SMP Mon Jul 27 17:24:03 UTC 2026 ; 2 CPU ; n=9 ; échauffement=2
- cand : Dart 3.7.2 (stable) (Tue Mar 11 04:27:50 2025 -0700) on "linux_x64" ; linux Linux 6.17.0-1022-azure #22-Ubuntu SMP Mon Jul 27 17:24:03 UTC 2026 ; 2 CPU ; n=9 ; échauffement=2

Inventaire des profils (compté sur les documents) :

- neuf : {'seances': 0, 'series': 0, 'resultatsWod': 0, 'wodPerso': 0}
- regulier : {'seances': 86, 'series': 1877, 'resultatsWod': 40, 'wodPerso': 0, 'wodModifies': 0, 'achats': 10, 'seancesPersoModeles': 20}
- long : {'seances': 320, 'series': 6587, 'resultatsWod': 300, 'wodPerso': 0, 'wodModifies': 0, 'achats': 30, 'seancesPersoModeles': 60}
- charge : {'seances': 840, 'series': 20347, 'resultatsWod': 1500, 'wodPerso': 50, 'wodModifies': 30, 'achats': 150, 'seancesPersoModeles': 150}
- Document stocké (caractères) : {'neuf': 0, 'regulier': 30511, 'long': 103911, 'charge': 283335}
