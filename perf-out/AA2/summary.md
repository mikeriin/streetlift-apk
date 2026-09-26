# Banc hôte L6 — synthèse

Mesure hôte (flutter_tester, JIT debug, sans GPU) : compare deux versions du code sur la même machine ; ce n'est pas une durée sur téléphone.

Fichiers : base-r1.jsonl

| Scénario | Profil | Unité | Base n | Base médiane [min–max] | Cand. n | Cand. médiane [min–max] | Ratio | Conclusion |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| catalog.estimate.pass2 | long | ms | 9 | 14.35 [13.718–22.276] | 0 | nan [nan–nan] |  | non mesuré |
| catalog.generate | - | ms | 9 | 3.252 [3.229–3.932] | 0 | nan [nan–nan] |  | non mesuré |
| catalog.rank | long | ms | 9 | 28.271 [27.799–28.75] | 0 | nan [nan–nan] |  | non mesuré |
| catalog.recommended | long | ms | 9 | 25.498 [24.6–29.334] | 0 | nan [nan–nan] |  | non mesuré |
| catalog.wodStats.all | long | ms | 9 | 22.538 [22.389–23.911] | 0 | nan [nan–nan] |  | non mesuré |
| derive.progression | charge | ms | 9 | 44.648 [43.96–47.469] | 0 | nan [nan–nan] |  | non mesuré |
| derive.progression | long | ms | 9 | 14.026 [13.62–14.387] | 0 | nan [nan–nan] |  | non mesuré |
| derive.progression | neuf | ms | 9 | 0.047 [0.046–0.077] | 0 | nan [nan–nan] |  | non mesuré |
| derive.progression | regulier | ms | 9 | 4.208 [4.176–4.707] | 0 | nan [nan–nan] |  | non mesuré |
| derive.progression+game | charge | ms | 9 | 64.432 [63.567–65.542] | 0 | nan [nan–nan] |  | non mesuré |
| derive.progression+game | long | ms | 9 | 22.912 [22.479–24.331] | 0 | nan [nan–nan] |  | non mesuré |
| derive.progression+game | neuf | ms | 9 | 0.176 [0.161–0.302] | 0 | nan [nan–nan] |  | non mesuré |
| derive.progression+game | regulier | ms | 9 | 7.077 [6.606–8.164] | 0 | nan [nan–nan] |  | non mesuré |
| import.apply | charge | ms | 5 | 871.08 [849.047–921.134] | 0 | nan [nan–nan] |  | non mesuré |
| import.apply | long | ms | 5 | 393.613 [282.724–411.506] | 0 | nan [nan–nan] |  | non mesuré |
| import.apply | regulier | ms | 5 | 119.569 [118.709–200.002] | 0 | nan [nan–nan] |  | non mesuré |
| import.preview | charge | ms | 5 | 430.523 [418.219–439.295] | 0 | nan [nan–nan] |  | non mesuré |
| import.preview | long | ms | 5 | 132.401 [126.711–157.976] | 0 | nan [nan–nan] |  | non mesuré |
| import.preview | regulier | ms | 5 | 36.528 [34.009–58.779] | 0 | nan [nan–nan] |  | non mesuré |
| save.encode.exportAll | charge | ms | 9 | 90.483 [74.629–113.42] | 0 | nan [nan–nan] |  | non mesuré |
| save.encode.exportAll | long | ms | 9 | 24.521 [24.357–46.526] | 0 | nan [nan–nan] |  | non mesuré |
| save.encode.exportAll | neuf | ms | 9 | 4.016 [3.942–4.44] | 0 | nan [nan–nan] |  | non mesuré |
| save.encode.exportAll | regulier | ms | 9 | 9.17 [8.796–9.835] | 0 | nan [nan–nan] |  | non mesuré |
| save.keystroke+flush | charge | ms | 9 | 137.366 [118.546–153.445] | 0 | nan [nan–nan] |  | non mesuré |
| save.keystroke+flush | long | ms | 9 | 39.571 [37.718–60.558] | 0 | nan [nan–nan] |  | non mesuré |
| save.keystroke+flush | neuf | ms | 9 | 4.527 [4.272–8.611] | 0 | nan [nan–nan] |  | non mesuré |
| save.keystroke+flush | regulier | ms | 9 | 13.854 [13.289–25.865] | 0 | nan [nan–nan] |  | non mesuré |
| save.toggleSet+derive+flush | charge | ms | 9 | 245.728 [219.933–259.981] | 0 | nan [nan–nan] |  | non mesuré |
| save.toggleSet+derive+flush | long | ms | 9 | 67.702 [65.404–114.016] | 0 | nan [nan–nan] |  | non mesuré |
| save.toggleSet+derive+flush | neuf | ms | 9 | 8.352 [4.845–10.053] | 0 | nan [nan–nan] |  | non mesuré |
| save.toggleSet+derive+flush | regulier | ms | 9 | 20.618 [19.785–25.087] | 0 | nan [nan–nan] |  | non mesuré |
| stats.exerciseBests | charge | ms | 9 | 13.074 [12.645–13.56] | 0 | nan [nan–nan] |  | non mesuré |
| stats.exerciseBests | long | ms | 9 | 6.194 [5.993–6.98] | 0 | nan [nan–nan] |  | non mesuré |
| stats.exerciseBests | neuf | ms | 9 | 0.0 [0.0–0.0] | 0 | nan [nan–nan] |  | non mesuré |
| stats.exerciseBests | regulier | ms | 9 | 2.378 [1.836–3.86] | 0 | nan [nan–nan] |  | non mesuré |
| stats.history | charge | ms | 9 | 6.14 [5.874–9.269] | 0 | nan [nan–nan] |  | non mesuré |
| stats.history | long | ms | 9 | 1.383 [1.343–2.422] | 0 | nan [nan–nan] |  | non mesuré |
| stats.history | neuf | ms | 9 | 0.028 [0.027–0.056] | 0 | nan [nan–nan] |  | non mesuré |
| stats.history | regulier | ms | 9 | 0.701 [0.482–0.732] | 0 | nan [nan–nan] |  | non mesuré |
| stats.weeklyMuscles | charge | ms | 9 | 39.384 [39.054–44.607] | 0 | nan [nan–nan] |  | non mesuré |
| stats.weeklyMuscles | long | ms | 9 | 12.107 [11.749–14.645] | 0 | nan [nan–nan] |  | non mesuré |
| stats.weeklyMuscles | neuf | ms | 9 | 0.065 [0.064–0.091] | 0 | nan [nan–nan] |  | non mesuré |
| stats.weeklyMuscles | regulier | ms | 9 | 6.165 [3.802–8.6] | 0 | nan [nan–nan] |  | non mesuré |
| store.init | charge | ms | 9 | 430.929 [422.682–746.244] | 0 | nan [nan–nan] |  | non mesuré |
| store.init | long | ms | 9 | 195.454 [174.289–281.339] | 0 | nan [nan–nan] |  | non mesuré |
| store.init | neuf | ms | 9 | 83.83 [70.797–168.642] | 0 | nan [nan–nan] |  | non mesuré |
| store.init | regulier | ms | 9 | 116.355 [107.92–236.908] | 0 | nan [nan–nan] |  | non mesuré |
| ui.firstFrame | charge | ms | 5 | 29.265 [28.735–40.102] | 0 | nan [nan–nan] |  | non mesuré |
| ui.firstFrame | long | ms | 5 | 37.236 [33.518–44.584] | 0 | nan [nan–nan] |  | non mesuré |
| ui.nav.firstVisit.arsenal | charge | ms | 1 | 62.593 [62.593–62.593] | 0 | nan [nan–nan] |  | non mesuré |
| ui.nav.firstVisit.programmeReturn | charge | ms | 1 | 44.816 [44.816–44.816] | 0 | nan [nan–nan] |  | non mesuré |
| ui.nav.firstVisit.stats | charge | ms | 1 | 44.599 [44.599–44.599] | 0 | nan [nan–nan] |  | non mesuré |
| ui.nav.firstVisit.statsSections | charge | ms | 3 | 32.128 [20.297–60.906] | 0 | nan [nan–nan] |  | non mesuré |
| ui.nav.firstVisit.arsenal | long | ms | 1 | 127.902 [127.902–127.902] | 0 | nan [nan–nan] |  | non mesuré |
| ui.nav.firstVisit.programmeReturn | long | ms | 1 | 66.259 [66.259–66.259] | 0 | nan [nan–nan] |  | non mesuré |
| ui.nav.firstVisit.stats | long | ms | 1 | 188.714 [188.714–188.714] | 0 | nan [nan–nan] |  | non mesuré |
| ui.nav.firstVisit.statsSections | long | ms | 3 | 104.72 [40.462–260.404] | 0 | nan [nan–nan] |  | non mesuré |

## Environnement (première ligne méta de chaque fichier)

- base : Dart 3.7.2 (stable) (Tue Mar 11 04:27:50 2025 -0700) on "linux_x64" ; linux Linux 6.17.0-1022-azure #22-Ubuntu SMP Mon Jul 27 17:24:03 UTC 2026 ; 2 CPU ; n=9 ; échauffement=2

Inventaire des profils (compté sur les documents) :

- neuf : {'seances': 0, 'series': 0, 'resultatsWod': 0, 'wodPerso': 0}
- regulier : {'seances': 86, 'series': 1877, 'resultatsWod': 40, 'wodPerso': 0, 'wodModifies': 0, 'achats': 10, 'seancesPersoModeles': 20}
- long : {'seances': 320, 'series': 6587, 'resultatsWod': 300, 'wodPerso': 0, 'wodModifies': 0, 'achats': 30, 'seancesPersoModeles': 60}
- charge : {'seances': 840, 'series': 20347, 'resultatsWod': 1500, 'wodPerso': 50, 'wodModifies': 30, 'achats': 150, 'seancesPersoModeles': 150}
- Document stocké (caractères) : {'neuf': 0, 'regulier': 26315, 'long': 89539, 'charge': 244583}
