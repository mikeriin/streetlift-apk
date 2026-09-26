# Banc hôte L6 — synthèse

Mesure hôte (flutter_tester, JIT debug, sans GPU) : compare deux versions du code sur la même machine ; ce n'est pas une durée sur téléphone.

Fichiers : base-r1.jsonl, base-r2.jsonl, cand-r1.jsonl, cand-r2.jsonl

| Scénario | Profil | Unité | Base n | Base médiane [min–max] | Cand. n | Cand. médiane [min–max] | Ratio | Conclusion |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| catalog.estimate.pass2 | charge | ms | 14 | 69.393 [47.482–167.801] | 14 | 66.792 [43.832–155.434] | 0.963 | gain non démontré |
| catalog.estimate.pass2 | long | ms | 14 | 12.12 [6.453–13.641] | 14 | 12.011 [6.818–13.838] | 0.991 | gain non démontré |
| catalog.generate | - | ms | 14 | 2.212 [1.883–3.531] | 14 | 1.874 [1.756–2.612] | 0.848 | gain non démontré |
| catalog.rank | long | ms | 14 | 14.727 [14.291–16.94] | 14 | 14.684 [14.084–14.99] | 0.997 | gain non démontré |
| catalog.recommended | long | ms | 14 | 15.162 [13.495–18.542] | 14 | 14.744 [13.851–16.806] | 0.972 | gain non démontré |
| catalog.wodStats.all | long | ms | 14 | 11.44 [11.059–13.908] | 14 | 11.616 [11.082–16.985] | 1.015 | gain non démontré |
| derive.progression | charge | ms | 14 | 28.837 [27.756–40.618] | 14 | 27.743 [26.749–28.361] | 0.962 | gain non démontré |
| derive.progression | long | ms | 14 | 8.643 [8.234–9.2] | 14 | 8.909 [8.706–9.638] | 1.031 | gain non démontré |
| derive.progression | neuf | ms | 14 | 0.027 [0.022–0.041] | 14 | 0.023 [0.021–0.046] | 0.852 | gain non démontré |
| derive.progression | regulier | ms | 14 | 2.123 [1.923–2.872] | 14 | 2.195 [2.051–2.978] | 1.034 | gain non démontré |
| derive.progression+game | charge | ms | 14 | 39.978 [39.392–41.036] | 14 | 38.615 [37.183–40.121] | 0.966 | gain non démontré |
| derive.progression+game | long | ms | 14 | 14.567 [14.125–14.925] | 14 | 14.872 [14.421–15.564] | 1.021 | gain non démontré |
| derive.progression+game | neuf | ms | 14 | 0.108 [0.074–0.181] | 14 | 0.079 [0.072–0.107] | 0.724 | gain non démontré |
| derive.progression+game | regulier | ms | 14 | 3.499 [3.217–3.844] | 14 | 3.502 [3.369–3.766] | 1.001 | gain non démontré |
| import.apply | charge | ms | 10 | 576.072 [527.81–629.305] | 10 | 587.125 [542.353–629.107] | 1.019 | gain non démontré |
| import.apply | long | ms | 10 | 223.691 [158.763–240.851] | 10 | 231.87 [167.913–239.463] | 1.037 | gain non démontré |
| import.apply | regulier | ms | 10 | 74.742 [68.186–127.749] | 10 | 78.716 [71.573–130.991] | 1.053 | gain non démontré |
| import.preview | charge | ms | 10 | 291.03 [255.392–327.081] | 10 | 277.818 [249.963–302.127] | 0.955 | gain non démontré |
| import.preview | long | ms | 10 | 83.907 [77.745–108.349] | 10 | 85.846 [75.064–111.747] | 1.023 | gain non démontré |
| import.preview | regulier | ms | 10 | 32.245 [19.579–63.269] | 10 | 28.383 [24.29–51.418] | 0.88 | gain non démontré |
| save.encode.exportAll | charge | ms | 14 | 71.932 [49.714–82.22] | 14 | 63.49 [44.334–80.237] | 0.883 | gain non démontré |
| save.encode.exportAll | long | ms | 14 | 17.596 [17.199–19.193] | 14 | 17.589 [15.247–19.447] | 1.0 | gain non démontré |
| save.encode.exportAll | neuf | ms | 14 | 2.273 [2.183–2.627] | 14 | 2.568 [2.35–3.133] | 1.13 | gain non démontré |
| save.encode.exportAll | regulier | ms | 14 | 5.868 [5.335–6.781] | 14 | 6.046 [5.456–18.435] | 1.03 | gain non démontré |
| save.keystroke+flush | charge | ms | 14 | 94.3 [71.149–126.747] | 14 | 97.993 [71.214–121.824] | 1.039 | gain non démontré |
| save.keystroke+flush | long | ms | 14 | 27.988 [24.457–51.214] | 14 | 25.699 [23.577–46.298] | 0.918 | gain non démontré |
| save.keystroke+flush | neuf | ms | 14 | 2.837 [2.496–4.828] | 14 | 3.0 [2.769–5.291] | 1.057 | gain non démontré |
| save.keystroke+flush | regulier | ms | 14 | 9.65 [8.404–21.092] | 14 | 9.136 [8.782–10.188] | 0.947 | gain non démontré |
| save.toggleSet+derive+flush | charge | ms | 14 | 152.175 [140.613–173.467] | 14 | 160.079 [136.937–185.521] | 1.052 | gain non démontré |
| save.toggleSet+derive+flush | long | ms | 14 | 48.048 [43.79–79.234] | 14 | 46.772 [44.015–78.427] | 0.973 | gain non démontré |
| save.toggleSet+derive+flush | neuf | ms | 14 | 4.563 [2.729–6.58] | 14 | 4.847 [3.086–6.287] | 1.062 | gain non démontré |
| save.toggleSet+derive+flush | regulier | ms | 14 | 13.672 [12.805–14.188] | 14 | 13.3 [12.554–14.372] | 0.973 | gain non démontré |
| stats.exerciseBests | charge | ms | 14 | 9.988 [9.636–10.53] | 14 | 9.011 [8.225–9.8] | 0.902 | gain non démontré |
| stats.exerciseBests | long | ms | 14 | 4.05 [3.817–4.413] | 14 | 4.84 [4.4–5.728] | 1.195 | régression |
| stats.exerciseBests | neuf | ms | 14 | 0.0 [0.0–0.0] | 14 | 0.0 [0.0–0.0] |  | gain non démontré |
| stats.exerciseBests | regulier | ms | 14 | 1.356 [0.89–1.999] | 14 | 1.534 [0.959–2.072] | 1.131 | gain non démontré |
| stats.history | charge | ms | 14 | 3.979 [3.589–4.39] | 14 | 3.708 [3.47–4.556] | 0.932 | gain non démontré |
| stats.history | long | ms | 14 | 0.881 [0.816–1.445] | 14 | 0.857 [0.766–1.542] | 0.973 | gain non démontré |
| stats.history | neuf | ms | 14 | 0.017 [0.012–0.055] | 14 | 0.015 [0.012–0.047] | 0.882 | gain non démontré |
| stats.history | regulier | ms | 14 | 0.362 [0.343–0.404] | 14 | 0.368 [0.349–0.454] | 1.017 | gain non démontré |
| stats.weeklyMuscles | charge | ms | 14 | 24.651 [24.212–27.304] | 14 | 25.322 [22.143–57.125] | 1.027 | gain non démontré |
| stats.weeklyMuscles | long | ms | 14 | 7.733 [7.3–9.599] | 14 | 7.848 [7.302–9.083] | 1.015 | gain non démontré |
| stats.weeklyMuscles | neuf | ms | 14 | 0.023 [0.017–0.03] | 14 | 0.017 [0.016–0.02] | 0.739 | gain non démontré |
| stats.weeklyMuscles | regulier | ms | 14 | 3.098 [1.805–3.88] | 14 | 3.14 [1.828–4.573] | 1.014 | gain non démontré |
| store.init | charge | ms | 14 | 263.907 [249.359–285.723] | 14 | 261.345 [240.079–295.484] | 0.99 | gain non démontré |
| store.init | long | ms | 14 | 113.174 [103.04–161.467] | 14 | 143.916 [99.127–166.105] | 1.272 | gain non démontré |
| store.init | neuf | ms | 14 | 47.401 [40.671–105.888] | 14 | 48.817 [38.758–102.659] | 1.03 | gain non démontré |
| store.init | regulier | ms | 14 | 85.505 [60.574–128.867] | 14 | 80.274 [61.338–127.537] | 0.939 | gain non démontré |
| ui.appearance.switch | charge | ms | 10 | 339.805 [202.25–436.236] | 10 | 276.398 [202.558–413.308] | 0.813 | gain non démontré |
| ui.appearance.switch | long | ms | 10 | 177.622 [121.591–302.562] | 10 | 167.0 [115.997–291.335] | 0.94 | gain non démontré |
| ui.catalog.open | charge | ms | 10 | 59.901 [53.665–182.92] | 10 | 58.795 [54.427–62.795] | 0.982 | gain non démontré |
| ui.catalog.open | long | ms | 10 | 63.004 [57.788–69.406] | 10 | 64.557 [60.744–69.633] | 1.025 | gain non démontré |
| ui.catalog.scroll60 | charge | ms | 10 | 17.272 [13.645–22.893] | 10 | 17.563 [14.957–22.477] | 1.017 | gain non démontré |
| ui.catalog.scroll60 | long | ms | 10 | 28.841 [24.16–36.816] | 10 | 27.267 [25.778–34.292] | 0.945 | gain non démontré |
| ui.catalog.search | charge | ms | 10 | 31.701 [24.634–34.503] | 10 | 33.628 [28.378–46.581] | 1.061 | gain non démontré |
| ui.catalog.search | long | ms | 10 | 44.886 [36.884–162.412] | 10 | 41.273 [32.69–110.512] | 0.92 | gain non démontré |
| ui.firstFrame | charge | ms | 10 | 31.715 [20.902–40.618] | 10 | 31.77 [22.95–40.864] | 1.002 | gain non démontré |
| ui.firstFrame | long | ms | 10 | 57.127 [43.231–69.283] | 10 | 59.766 [39.041–66.085] | 1.046 | gain non démontré |
| ui.memory.rss10cycles | charge | bytes | 4 | 634009600.0 [617877504–661282816] | 4 | 598464512.0 [565571584–661037056] | 0.944 | brut (hors comparaison) |
| ui.memory.rss10cycles | long | bytes | 4 | 458502144.0 [437002240–477282304] | 4 | 446253056.0 [424992768–477962240] | 0.973 | brut (hors comparaison) |
| ui.nav.firstVisit.arsenal | charge | ms | 2 | 184.3 [182.776–185.825] | 2 | 183.681 [174.197–193.165] | 0.997 | gain non démontré |
| ui.nav.firstVisit.programmeReturn | charge | ms | 2 | 79.141 [77.427–80.854] | 2 | 119.834 [115.253–124.416] | 1.514 | régression |
| ui.nav.firstVisit.stats | charge | ms | 2 | 36.871 [34.461–39.282] | 2 | 36.934 [36.36–37.508] | 1.002 | gain non démontré |
| ui.nav.firstVisit.statsSections | charge | ms | 6 | 104.541 [18.69–158.861] | 6 | 60.294 [19.308–79.581] | 0.577 | gain non démontré |
| ui.nav.firstVisit.arsenal | long | ms | 2 | 258.991 [238.474–279.509] | 2 | 234.608 [221.176–248.041] | 0.906 | gain non démontré |
| ui.nav.firstVisit.programmeReturn | long | ms | 2 | 104.207 [97.571–110.842] | 2 | 168.194 [105.789–230.598] | 1.614 | gain non démontré |
| ui.nav.firstVisit.stats | long | ms | 2 | 139.951 [102.857–177.044] | 2 | 113.404 [108.279–118.53] | 0.81 | gain non démontré |
| ui.nav.firstVisit.statsSections | long | ms | 6 | 126.705 [49.743–174.38] | 6 | 110.757 [54.639–218.796] | 0.874 | gain non démontré |
| ui.session.keystroke | charge | ms | 30 | 72.331 [60.469–176.104] | 30 | 70.0 [62.508–197.432] | 0.968 | gain non démontré |
| ui.session.keystroke | long | ms | 30 | 59.951 [49.467–142.425] | 30 | 66.557 [50.817–165.958] | 1.11 | gain non démontré |
| ui.session.pop.firstFrame | charge | ms | 2 | 20.401 [18.903–21.899] | 2 | 11.832 [11.011–12.654] | 0.58 | amélioration |
| ui.session.pop.settle | charge | ms | 2 | 203.829 [203.038–204.62] | 2 | 99.061 [94.587–103.535] | 0.486 | amélioration |
| ui.session.pop.firstFrame | long | ms | 2 | 30.991 [16.919–45.063] | 2 | 16.888 [16.809–16.967] | 0.545 | gain non démontré |
| ui.session.pop.settle | long | ms | 2 | 53.438 [51.711–55.165] | 2 | 51.346 [50.922–51.769] | 0.961 | gain non démontré |
| ui.session.toggleSet | charge | ms | 20 | 119.79 [109.907–298.604] | 20 | 132.562 [110.707–321.504] | 1.107 | gain non démontré |
| ui.session.toggleSet | long | ms | 20 | 89.195 [77.994–180.229] | 20 | 84.385 [72.817–158.792] | 0.946 | gain non démontré |
| ui.stats.visibleNotify | charge | ms | 20 | 117.005 [108.531–292.907] | 20 | 114.697 [105.237–125.475] | 0.98 | gain non démontré |
| ui.stats.visibleNotify | long | ms | 20 | 100.876 [69.57–177.053] | 20 | 88.463 [73.194–188.157] | 0.877 | gain non démontré |

## Environnement (première ligne méta de chaque fichier)

- base : Dart 3.7.2 (stable) (Tue Mar 11 04:27:50 2025 -0700) on "linux_x64" ; linux Linux 6.17.0-1022-azure #22-Ubuntu SMP Mon Jul 27 17:24:03 UTC 2026 ; 2 CPU ; n=7 ; échauffement=2
- cand : Dart 3.7.2 (stable) (Tue Mar 11 04:27:50 2025 -0700) on "linux_x64" ; linux Linux 6.17.0-1022-azure #22-Ubuntu SMP Mon Jul 27 17:24:03 UTC 2026 ; 2 CPU ; n=7 ; échauffement=2

Inventaire des profils (compté sur les documents) :

- neuf : {'seances': 0, 'series': 0, 'resultatsWod': 0, 'wodPerso': 0}
- regulier : {'seances': 86, 'series': 1877, 'resultatsWod': 40, 'wodPerso': 0, 'wodModifies': 0, 'achats': 10, 'seancesPersoModeles': 20}
- long : {'seances': 320, 'series': 6587, 'resultatsWod': 300, 'wodPerso': 0, 'wodModifies': 0, 'achats': 30, 'seancesPersoModeles': 60}
- charge : {'seances': 840, 'series': 20347, 'resultatsWod': 1500, 'wodPerso': 50, 'wodModifies': 30, 'achats': 150, 'seancesPersoModeles': 150}
- Document stocké (caractères) : {'neuf': 0, 'regulier': 30511, 'long': 103911, 'charge': 283335}
