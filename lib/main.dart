import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'device.dart';
import 'dev/dev_flags.dart';
import 'dev/dev_session.dart';
import 'mannequin_3d.dart' show Display3DSettings;
import 'mannequin_preload.dart';
import 'muscle_map_2d.dart' show mapPrecacheInBackground;
import 'session_host.dart';
import 'session_prefs.dart';
import 'startup.dart';
import 'app_theme.dart';
import 'kit/kit.dart';
import 'nav_bar.dart';
export 'nav_bar.dart' show AppTab, AppTabs, HeroNavBar, openTab;
export 'app_theme.dart' show SL, buildTheme;

import 'home_screen.dart';
import 'notifications.dart';
import 'persistence_alert.dart';
import 'arsenal_screen.dart';
import 'stats_screen.dart';
import 'stats_navigation.dart';
import 'settings_screen.dart';
import 'athlete_profile_flow.dart' show ProfileGate;
import 'retired_notice_screen.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // UI0 : licence des polices Barlow embarquées (Sources et licences).
  registerFontLicences();
  // Une première image Flutter immédiate permet d'animer l'ouverture pendant
  // l'initialisation, au lieu de figer l'écran natif deux secondes.
  // G1 : la session active est lue avant (quelques millisecondes) : le logo
  // de l'ouverture est rose dès la première image d'une session de test.
  if (kDevBuild) await DevSession.load();
  runApp(kalisApp());
  try {
    await enableHighRefreshRate();
  } catch (_) {}
}

/// UI0 (refonte UI) : licence SIL OFL 1.1 des polices Barlow, affichée par
/// la page des licences de l'application.
void registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Barlow'], text);
  });
}

/// Démarrage : session active (G1 : personnelle, ou session de test d'un
/// build de développement) puis chargement du magasin de cette session.
Future<void> bootSession() async {
  await DevSession.load();
  await store.init();
  // RV3 (R8) : réglages d'affichage 3D (nom au toucher, halo) lus avant le
  // premier écran. Avant : lus à la première ouverture de Réglages ›
  // Apparence ou du mannequin ; l'Anatomie et la recherche des réglages
  // montraient d'ici là les valeurs par défaut (nom au toucher coupé mais
  // affiché).
  await Display3DSettings.instance.load();
}

/// Application complète (racine de [main] et des tests d'intégration) :
/// G1, racine [SessionHost] qui sait redémarrer l'application sur une
/// autre session sans quitter le processus.
Widget kalisApp() => SessionHost(
  boot: bootSession,
  builder: (initialization) => AppStartup(
    initialization: initialization,
    appBuilder: (_) => const SLApp(profileGate: true),
    errorBuilder: (error, stack) =>
        _InitErrorApp(error: '$error', stack: '$stack'),
    isDark: () =>
        store.settings.theme == 'dark' ||
        (store.settings.theme == 'system' &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark),
    onReady: () {
      _bindNotifications();
      // M56 : mannequin préchargé en tâche de fond une fois l'application
      // prête (première image déjà affichée, initialisation faite).
      unawaited(MannequinPreload.start());
      // M8 : masques de la carte 2D des groupes préchargés (accueil,
      // STATS, fiches : pas de saut au premier affichage).
      final context = appNavigator.currentContext;
      if (context != null) mapPrecacheInBackground(context);
    },
  ),
);

void _bindNotifications() {
  // Même chemin que l'accueil : historique si la journée est faite, séance
  // sinon ; bilan de fin de séance et cérémonie de niveau compris (la séance
  // ouverte par un rappel n'affichait jamais son écran de récompenses).
  Notif.onOpen = (week, day) {
    final nav = appNavigator.currentState;
    final plan = store.program.week(week);
    final session = plan.day(day);
    if (nav != null && session != null) {
      unawaited(openProgramDay(nav, plan, session));
    }
  };
  // AppStartup appelle ce point après le rendu de l'accueil : le navigateur
  // est prêt, sans attendre une interaction pour planifier une autre frame.
  Notif.bind();
  // G1 : après un redémarrage logique, les rappels suivent le magasin de
  // la session active.
  Notif.attach(store);
}

/// Écran de secours si l'initialisation échoue : l'erreur est lisible et copiable
/// au lieu d'un lancement bloqué sur l'écran de démarrage.
class _InitErrorApp extends StatelessWidget {
  final String error;
  final String stack;
  const _InitErrorApp({required this.error, required this.stack});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildTheme(true),
    home: KScaffold(
      appBar: AppBar(title: const Text('Problème au démarrage')),
      body: KPageList(
        children: [
          const KCard(
            child: Text(
              'Kalis Track n’a pas pu s’ouvrir. Tu peux conserver une copie de tes données et copier le rapport pour identifier le problème.',
            ),
          ),
          KCard(
            child: Text(error, style: TextStyle(color: SL.danger)),
          ),
          KCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              title: const Text('Détails du problème'),
              childrenPadding: const EdgeInsets.all(KSpacing.s16),
              children: [
                SelectableText(
                  stack,
                  style: KType.micro.copyWith(
                    color: SL.dim,
                    fontFamily: 'monospace',
                    fontWeight: KType.detail.fontWeight,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              // G1 : données de la session active seulement.
              final raw = jsonEncode((await KalisPrefs.active()).snapshot());
              await Clipboard.setData(ClipboardData(text: raw));
            },
            icon: const Icon(Icons.save_alt),
            label: const Text('Copier les données pour récupération'),
          ),
          FilledButton.icon(
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: '$error\n$stack')),
            icon: const Icon(Icons.copy),
            label: const Text('Copier le rapport'),
          ),
        ],
      ),
    ),
  );
}

// Thèmes construits une seule fois par palette, luminosité et contraste
// (ThemeData est coûteux à recréer), intensité des couleurs et densité.
final Map<String, ThemeData> _themes = {};

/// Thème d'une combinaison, sans modifier la palette courante de [SL]
/// ([buildTheme] la positionne pour les usages directs et les tests).
ThemeData themeFor(bool dark, KAccentSpec accent, [bool? contrast]) {
  final strong = contrast ?? SL.contrast;
  // RV1 : l'intensité des couleurs et la densité entrent dans la clé
  // (avant : « Couleurs » et « Espacements » ne changeaient le kit qu'au
  // redémarrage).
  final key = '${accent.id}-$dark-$strong-$kColorIntensity-${KDensity.factor}';
  return _themes.putIfAbsent(key, () {
    final previousDark = SL.dark,
        previousAccent = SL.accentSpec,
        previousContrast = SL.contrast;
    final theme = buildTheme(dark, accent, strong);
    SL.dark = previousDark;
    SL.accentSpec = previousAccent;
    SL.contrast = previousContrast;
    return theme;
  });
}

/// Luminosité effective : réglage de l'application, ou téléphone en mode
/// « Système ». Indépendante de la couleur dominante.
bool effectiveDark(String theme) =>
    theme == 'dark' ||
    (theme == 'system' &&
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark);

final appNavigator = GlobalKey<NavigatorState>();

/// Application : thème clair/sombre/système et couleur dominante (L5-C)
/// sont deux réglages indépendants. Un changement de l'un ou de l'autre
/// reconstruit l'arbre existant sans le recréer : navigation, routes
/// ouvertes, saisies, séance et chronos gardent leur état.
class SLApp extends StatefulWidget {
  /// L8 : démarrage court (installation neuve) ou confirmation du profil
  /// (installation existante) avant l'accueil. Activé par [main] ; les
  /// tests de parcours existants construisent l'application sans ce
  /// premier écran, les tests L8 l'activent.
  final bool profileGate;
  const SLApp({super.key, this.profileGate = false});

  @override
  State<SLApp> createState() => _SLAppState();
}

class _SLAppState extends State<SLApp> with WidgetsBindingObserver {
  late final Listenable _appearance = Listenable.merge([
    store.themeMode,
    store.accentMode,
    store.contrastMode,
    store.displaySizeMode,
    store.colorIntensityMode,
    store.spacingMode,
  ]);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appearance.addListener(_onAppearance);
  }

  @override
  void dispose() {
    _appearance.removeListener(_onAppearance);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _sync() {
    // 6.14.0 : intensité des couleurs et espacements, avant le thème.
    kColorIntensity = store.colorIntensityMode.value;
    KDensity.factor = store.spacingMode.value / 100;
    SL.accentSpec = KAccentSpec.byId(store.accentMode.value);
    SL.contrast = store.contrastMode.value;
    SL.dark = effectiveDark(store.themeMode.value);
  }

  void _onAppearance() {
    if (!mounted) return;
    setState(_sync);
    _refreshDescendants();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (mounted && store.themeMode.value == 'system') _onAppearance();
  }

  /// Une partie des écrans lit la palette par [SL] sans dépendre du thème :
  /// on les marque à reconstruire (routes empilées comprises). Aucun
  /// élément n'est recréé, aucun état n'est perdu.
  void _refreshDescendants() {
    void mark(Element element) {
      element.markNeedsBuild();
      element.visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    final t = store.themeMode.value;
    final accent = SL.accentSpec;
    final contrast = SL.contrast;
    final mode = t == 'dark'
        ? ThemeMode.dark
        : t == 'light'
        ? ThemeMode.light
        : ThemeMode.system;
    return MaterialApp(
      navigatorKey: appNavigator,
      title: 'Kalis Track',
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: themeFor(false, accent, contrast),
      darkTheme: themeFor(true, accent, contrast),
      builder: (context, child) {
        SL.dark = Theme.of(context).brightness == Brightness.dark;
        SL.accentSpec = accent;
        SL.contrast = contrast;
        // 6.13.0 : taille d'affichage choisie dans les Réglages (textes et
        // cadres), par-dessus le réglage du téléphone.
        return KDisplayScale(
          scale: store.displaySizeMode.value / 100,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: widget.profileGate
          ? const ProfileGate(child: RootNav())
          : const RootNav(),
    );
  }
}

/// Racine des quatre onglets ([AppTab] : Arsenal, Stats, Programme,
/// Réglages), ouverte sur Programme. UI5 : se lie à [AppTabs] pour que
/// [openTab] change d'onglet depuis n'importe quel écran.
class RootNav extends StatefulWidget {
  final DateTime? referenceDate;
  const RootNav({super.key, this.referenceDate});
  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> with WidgetsBindingObserver {
  int _tabIndex = AppTab.program.index;
  final Set<int> _visited = {AppTab.program.index};
  final _statsKey = GlobalKey<StatsScreenState>();
  @override
  void initState() {
    super.initState();
    StatsNavigation.bind(this, _openStats);
    AppTabs.bind(this, (tab) => _selectTab(tab.index));
    WidgetsBinding.instance.addObserver(this);
    store.themeMode.addListener(_onTheme);
    store.accentMode.addListener(_onTheme);
    store.contrastMode.addListener(_onTheme);
    // KM3 : Koach 1.0 (prise de main, rejeu, rattrapage) en arrière-plan.
    unawaited(store.koachRefresh());
    // G2 (D1.1) : annonce de la suppression des WOD et des séances perso,
    // une fois, dès que l'accueil est affiché.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = appNavigator.currentState;
      if (mounted && navigator != null) {
        unawaited(showRetiredNoticeIfNeeded(navigator));
      }
    });
  }

  @override
  void dispose() {
    StatsNavigation.unbind(this);
    AppTabs.unbind(this);
    WidgetsBinding.instance.removeObserver(this);
    store.themeMode.removeListener(_onTheme);
    store.accentMode.removeListener(_onTheme);
    store.contrastMode.removeListener(_onTheme);
    super.dispose();
  }

  /// Sélectionne l'onglet [index] (dock ou [openTab]).
  void _selectTab(int index) {
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _tabIndex = index;
      _visited.add(index);
    });
  }

  void _openStats(StatsSection section) {
    if (!mounted) return;
    setState(() {
      _tabIndex = AppTab.stats.index;
      _visited.add(AppTab.stats.index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _statsKey.currentState?.selectSection(section);
    });
  }

  void _onTheme() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      store.flush();
    }
    if (state == AppLifecycleState.resumed) {
      store.notifyListeners();
      Notif.reschedule();
      // KM3 : Koach 1.0 rattrape les semaines finies (replanification du
      // lundi, hors du fil d'interface).
      unawaited(store.koachRefresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Synchronise la palette runtime avec le thème effectif (système compris).
    final t = store.settings.theme;
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    SL.dark = t == 'dark' || (t == 'system' && platformDark);
    SL.accentSpec = KAccentSpec.byId(store.settings.accent);
    SL.contrast = store.settings.contrast;
    // Reconstruit aussi les composants historiques qui lisent la palette SL.
    final pages = [
      // ignore: prefer_const_constructors
      ArsenalScreen(),
      StatsScreen(key: _statsKey),
      // ignore: prefer_const_constructors
      HomeScreen(referenceDate: widget.referenceDate),
      // ignore: prefer_const_constructors
      SettingsScreen(),
    ];
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final inset = keyboard
        ? 0.0
        : HeroNavBar.extent + MediaQuery.viewPaddingOf(context).bottom;
    // RV2 (M6) : écritures refusées signalées par une bannière fixe tant
    // qu'elles durent (persistence_alert.dart).
    return PersistenceAlert(
      store: store,
      child: Scaffold(
        extendBody: true,
        body: KNavigationInset(
          bottom: inset,
          child: KContentTransition(
            key: const ValueKey('navigation-transition'),
            position: _tabIndex,
            child: IndexedStack(
              index: _tabIndex,
              children: [
                for (var i = 0; i < pages.length; i++)
                  _visited.contains(i)
                      ? TickerMode(
                          enabled: i == _tabIndex,
                          child: KeyedSubtree(
                            key: ValueKey('tab-$i'),
                            child: pages[i],
                          ),
                        )
                      : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: keyboard
            ? null
            : HeroNavBar(index: _tabIndex, onTap: _selectTab),
      ),
    );
  }
}
