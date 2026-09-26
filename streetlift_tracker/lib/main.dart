import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'device.dart';
import 'startup.dart';
import 'app_theme.dart';
import 'ui.dart';
import 'motion.dart';
import 'nav_bar.dart';
export 'nav_bar.dart' show HeroNavBar;
export 'app_theme.dart' show SL, buildTheme, logDeco;

import 'home_screen.dart';
import 'notifications.dart';
import 'arsenal_screen.dart';
import 'stats_screen.dart';
import 'stats_navigation.dart';
import 'settings_screen.dart';
import 'profile_screens.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Une première image Flutter immédiate permet d'animer l'ouverture pendant
  // l'initialisation, au lieu de figer l'écran natif deux secondes.
  runApp(
    AppStartup(
      initialization: store.init(),
      appBuilder: (_) => const SLApp(profileGate: true),
      errorBuilder:
          (error, stack) => _InitErrorApp(error: '$error', stack: '$stack'),
      isDark:
          () =>
              store.settings.theme == 'dark' ||
              (store.settings.theme == 'system' &&
                  WidgetsBinding
                          .instance
                          .platformDispatcher
                          .platformBrightness ==
                      Brightness.dark),
      onReady: _bindNotifications,
    ),
  );
  try {
    await enableHighRefreshRate();
  } catch (_) {}
}

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
    home: KScreen(
      appBar: AppBar(title: const Text('Problème au démarrage')),
      body: KList(
        children: [
          const KCard(
            child: Text(
              'Kalis Track n’a pas pu s’ouvrir. Tu peux conserver une copie de tes données et copier le rapport pour identifier le problème.',
            ),
          ),
          KCard(child: Text(error, style: TextStyle(color: SL.danger))),
          KCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              title: const Text('Détails du problème'),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                SelectableText(
                  stack,
                  style: TextStyle(
                    color: SL.dim,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final raw = jsonEncode({
                for (final key in prefs.getKeys()) key: prefs.get(key),
              });
              await Clipboard.setData(ClipboardData(text: raw));
            },
            icon: const Icon(Icons.save_alt),
            label: const Text('Copier les données pour récupération'),
          ),
          FilledButton.icon(
            onPressed:
                () => Clipboard.setData(ClipboardData(text: '$error\n$stack')),
            icon: const Icon(Icons.copy),
            label: const Text('Copier le rapport'),
          ),
        ],
      ),
    ),
  );
}

// Thèmes construits une seule fois par couleur dominante et luminosité
// (ThemeData est coûteux à recréer) : 12 combinaisons au plus.
final Map<String, ThemeData> _themes = {};

/// Thème d'une combinaison, sans modifier la palette courante de [SL]
/// ([buildTheme] la positionne pour les usages directs et les tests).
ThemeData themeFor(bool dark, KAccentSpec accent) =>
    _themes.putIfAbsent('${accent.id}-$dark', () {
      final previousDark = SL.dark, previousAccent = SL.accentSpec;
      final theme = buildTheme(dark, accent);
      SL.dark = previousDark;
      SL.accentSpec = previousAccent;
      return theme;
    });

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
    SL.accentSpec = KAccentSpec.byId(store.accentMode.value);
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
    final mode =
        t == 'dark'
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
      theme: themeFor(false, accent),
      darkTheme: themeFor(true, accent),
      builder: (context, child) {
        SL.dark = Theme.of(context).brightness == Brightness.dark;
        SL.accentSpec = accent;
        return child ?? const SizedBox.shrink();
      },
      home: widget.profileGate ? const ProfileGate(child: RootNav()) : const RootNav(),
    );
  }
}

class RootNav extends StatefulWidget {
  final DateTime? referenceDate;
  const RootNav({super.key, this.referenceDate});
  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> with WidgetsBindingObserver {
  int _tabIndex = 2;
  final Set<int> _visited = {2};
  final _statsKey = GlobalKey<StatsScreenState>();
  @override
  void initState() {
    super.initState();
    StatsNavigation.bind(this, _openStats);
    WidgetsBinding.instance.addObserver(this);
    store.themeMode.addListener(_onTheme);
    store.accentMode.addListener(_onTheme);
    store.persistenceError.addListener(_onPersistenceError);
  }

  @override
  void dispose() {
    StatsNavigation.unbind(this);
    WidgetsBinding.instance.removeObserver(this);
    store.themeMode.removeListener(_onTheme);
    store.accentMode.removeListener(_onTheme);
    store.persistenceError.removeListener(_onPersistenceError);
    super.dispose();
  }

  void _openStats(StatsSection section) {
    if (!mounted) return;
    setState(() {
      _tabIndex = 1;
      _visited.add(1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _statsKey.currentState?.selectSection(section);
    });
  }

  void _onTheme() => setState(() {});
  void _onPersistenceError() {
    final message = store.persistenceError.value;
    if (message != null && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Réessayer',
            onPressed: () async {
              if (await store.retrySave()) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Modifications enregistrées.')),
                );
              }
            },
          ),
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      store.flush();
    }
    if (state == AppLifecycleState.resumed) {
      store.notifyListeners();
      Notif.reschedule();
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
    final inset =
        keyboard
            ? 0.0
            : HeroNavBar.extent + MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
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
      bottomNavigationBar:
          keyboard
              ? null
              : HeroNavBar(
                index: _tabIndex,
                onTap: (i) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  setState(() {
                    _tabIndex = i;
                    _visited.add(i);
                  });
                },
              ),
    );
  }
}
