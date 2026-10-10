// UI4 (refonte UI, cahier §4.1, §4.4, §4.5) : onglet Réglages au gabarit
// « menu racine » — recherche, carte Profil, groupes « Application » et
// « Plus » — et six sous-pages de menu, réglages appliqués tout de suite.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'athlete_profile_screen.dart';
import 'data_control.dart';
import 'dev/dev_flags.dart';
import 'dev/dev_widgets.dart' show HeaderLogo;
import 'engine3d.dart';
import 'exercise_screens.dart' show MentionsScreen;
import 'koach/koach_gallery_screen.dart';
import 'mannequin_3d.dart' show Display3DSettings;
import 'notification_settings.dart';
import 'program_explainer.dart' show showProgramExplainer;
import 'retired_notice_screen.dart';
import 'search.dart' show normalizeText;
import 'settings_search.dart';
import 'store.dart';
import 'store_widget.dart';
import 'ui.dart';
import 'wellbeing_screens.dart';

/// Version de l'application (pubspec sans le numéro de build).
const kVersion = '6.11.2';

/// Version affichée (D0.9) : « dev6.8.0 » dans le build de développement
/// (APK du propriétaire), « 6.8.0 » dans l’AAB du Play Store.
const kAppVersion = kDevBuild ? 'dev$kVersion' : kVersion;

/// Rubriques des Réglages (cahier §4.1) : libellé de la ligne (titre de la
/// sous-page, R3), description de la ligne, phrase de la sous-page, icône.
enum SettingsPage {
  appearance(
    'Apparence',
    'Thème, palette, contraste, anatomie 3D',
    'Thème, palette, contraste, anatomie 3D.',
    Icons.palette_outlined,
  ),
  session(
    'Séance',
    'Saisie, chronomètres, écran et unités',
    'Saisie, chronomètres, écran et unités.',
    Icons.timer_outlined,
  ),
  notifications(
    'Notifications',
    'Rappel de séance et son heure',
    'Rappel de séance et son heure.',
    Icons.notifications_none_rounded,
  ),
  progression(
    'Progression et jeu',
    'Célébrations, objectif de la semaine',
    'Célébrations, objectif de la semaine.',
    Icons.military_tech_rounded,
  ),
  data(
    'Données et confidentialité',
    'Sauvegardes, anciennes réponses, suppression',
    'Sauvegardes, anciennes réponses, suppression.',
    Icons.cloud_outlined,
  ),
  about(
    'Aide et à propos',
    'Santé et sécurité, guide, galerie de Koach, avis, licences, version',
    'Santé et sécurité, guide, avis, licences et version.',
    Icons.info_outline_rounded,
  );

  const SettingsPage(this.title, this.description, this.lead, this.icon);

  /// Libellé de la ligne de la racine et titre de la sous-page.
  final String title;

  /// Description de la ligne de la racine.
  final String description;

  /// Phrase sous le titre de la sous-page.
  final String lead;
  final IconData icon;
}

/// Durée en secondes au format C9 : jusqu'à 90 s en secondes (« 90 s »),
/// au-delà en minutes (« 2 min », « 2 min 30 »).
String settingsSecondsLabel(int seconds) {
  if (seconds <= 90) return '$seconds s';
  final m = seconds ~/ 60, s = seconds % 60;
  if (s == 0) return '$m min';
  return '$m min ${s.toString().padLeft(2, '0')}';
}

/// Objectif de la semaine (§4.3) : mêmes valeurs que Stats.
const kWeeklyGoalChoices = [0, 2, 3, 4, 5, 6];

/// Description de l'objectif de la semaine ; une valeur hors des choix
/// (1, d'avant UI4) reste affichée telle quelle, sans migration.
String weeklyGoalText(int goal) => switch (goal) {
  0 => 'Adaptatif : moyenne récente + 1',
  >= 2 && <= 6 => 'Cap personnel, sans XP',
  1 => 'Actuellement : 1 jour par semaine',
  _ => 'Actuellement : $goal jours par semaine',
};

const _profileText = 'Profil, mes références, tests guidés, santé';

void _push(BuildContext context, Widget screen) =>
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));

class SettingsScreen extends StatefulWidget {
  /// Sous-page ouverte ; null : racine des Réglages.
  final SettingsPage? page;

  /// Identifiant de la ligne mise en évidence 1,5 s à l'ouverture (résultat
  /// de la recherche des réglages, §4.4).
  final String? highlight;
  const SettingsScreen({super.key, this.page, this.highlight});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _target = GlobalKey();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Notifications : le panneau met lui-même ses lignes en évidence ; elles
    // sont en haut de la page.
    if (widget.highlight != null && widget.page != SettingsPage.notifications) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(0));
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Amène la ligne mise en évidence à l'écran (elle peut être sous le bord,
  /// pas encore construite).
  void _reveal(int attempt) {
    if (!mounted) return;
    final target = _target.currentContext;
    if (target != null) {
      final motion = KMotion.standard;
      Scrollable.ensureVisible(
        target,
        alignment: .3,
        duration: motion.durationIn(context),
        curve: motion.curve,
      );
      return;
    }
    if (attempt >= 8 || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent) return;
    position.jumpTo(
      math.min(
        position.pixels + position.viewportDimension * .8,
        position.maxScrollExtent,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(attempt + 1));
  }

  /// Ligne [id] : mise en évidence si la recherche y mène, repérée pour
  /// être amenée à l'écran.
  Widget _mark(String id, Widget Function(bool lit) row) {
    final lit = widget.highlight == id;
    final built = row(lit);
    return lit ? KeyedSubtree(key: _target, child: built) : built;
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    // L6 : différé tant que l'onglet est masqué (voir store_widget.dart).
    return StoreBuilder(
      builder: (context) {
        final page = widget.page;
        if (page == null) return _root(context);
        return KMenuPage(
          root: false,
          title: page.title,
          lead: page.lead,
          controller: _scroll,
          groups: switch (page) {
            SettingsPage.appearance => _appearance(context),
            SettingsPage.session => _session(),
            SettingsPage.notifications => [
              NotificationSettingsPanel(highlight: widget.highlight),
            ],
            SettingsPage.progression => _progression(),
            SettingsPage.data => _data(context),
            SettingsPage.about => _about(context),
          },
        );
      },
    );
  }

  // ------------------------------------------------------------- racine

  Widget _root(BuildContext context) {
    final searching = normalizeText(_query).isNotEmpty;
    return KMenuPage(
      title: 'Réglages',
      lead: 'L’application à ta façon.',
      // G1 : gestes du mode dev (build de développement seulement).
      trailing: const HeaderLogo(),
      search: KSearchField(
        key: const ValueKey('settings-search'),
        controller: _search,
        hint: 'Rechercher un réglage',
        onChanged: (value) => setState(() => _query = value),
      ),
      header: searching ? null : _profileCard(context),
      groups: searching
          ? _results(context)
          : [
              KMenuGroup(
                title: 'Application',
                children: [
                  for (final p in const [
                    SettingsPage.appearance,
                    SettingsPage.session,
                    SettingsPage.notifications,
                    SettingsPage.progression,
                  ])
                    _pageRow(context, p),
                ],
              ),
              KMenuGroup(
                title: 'Plus',
                children: [
                  for (final p in const [SettingsPage.data, SettingsPage.about])
                    _pageRow(context, p),
                ],
              ),
            ],
    );
  }

  Widget _pageRow(BuildContext context, SettingsPage p) => KMenuRow(
    key: ValueKey('settings-page-${p.name}'),
    icon: p.icon,
    title: p.title,
    subtitle: p.description,
    onTap: () => _push(context, SettingsScreen(page: p)),
  );

  /// Carte Profil (§4.1) : prénom, ce que contient le profil, son état.
  Widget _profileCard(BuildContext context) {
    final k = KTokens.of(context);
    final name = store.athlete?.profile.displayName?.trim() ?? '';
    final state = switch ((store.athlete, store.caution.active)) {
      (null, _) => store.profile != null ? 'À refaire avec Koach' : 'À créer',
      (_, true) => 'mode prudent',
      _ => null,
    };
    final avatar = Container(
      width: KSize.menuIcon,
      height: KSize.menuIcon,
      decoration: ShapeDecoration(color: k.pleine, shape: KRadius.pill),
      alignment: Alignment.center,
      child: name.isEmpty
          ? Icon(
              Icons.person_outline_rounded,
              size: KSize.iconSmall,
              color: k.surPleine,
            )
          : Text(
              k.title(String.fromCharCodes(name.runes.take(1))),
              style: KType.corpsFort.copyWith(color: k.surPleine),
            ),
    );
    return KMenuGroup(
      children: [
        KMenuRow(
          key: const ValueKey('settings-profile'),
          leading: ExcludeSemantics(child: avatar),
          minHeight: KSize.settingRow,
          title: name.isEmpty ? 'Mon profil' : name,
          subtitle: state == null ? _profileText : '$_profileText · $state',
          onTap: () => _push(context, const ProfileScreen()),
        ),
      ],
    );
  }

  /// Résultats de la recherche (§4.4) : « Réglages » puis « Aide ».
  List<Widget> _results(BuildContext context) {
    final k = KTokens.of(context);
    final hits = searchSettings(_query);
    if (hits.isEmpty) {
      return [
        KEmpty(
          key: const ValueKey('settings-search-empty'),
          icon: Icons.search_off_rounded,
          title: 'Aucun réglage trouvé',
          message:
              'Essaie un mot plus court ou un mot proche : « repos », '
              '« thème », « sauvegarde », « rappel », « profil ».',
          action: 'Effacer la recherche',
          onAction: _clearSearch,
        ),
      ];
    }
    Widget row(SettingsSearchEntry e) => KMenuRow(
      key: ValueKey('settings-result-${e.id}'),
      title: e.label,
      subtitle: e.path,
      value: e.value?.call(),
      onTap: () => e.open(context),
    );
    final settings = [
      for (final e in hits)
        if (e.kind == SettingsSearchKind.setting) e,
    ];
    final help = [
      for (final e in hits)
        if (e.kind == SettingsSearchKind.help) e,
    ];
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: KSpacing.s4),
        child: Text(
          '${hits.length == 1 ? '1 résultat' : '${hits.length} résultats'}. '
          'Toucher un résultat ouvre sa page et met le réglage en évidence.',
          key: const ValueKey('settings-search-count'),
          style: KType.detail.copyWith(color: k.texte2),
        ),
      ),
      if (settings.isNotEmpty)
        KMenuGroup(
          title: 'Réglages',
          dividerIndent: KSpacing.s16,
          children: [for (final e in settings) row(e)],
        ),
      if (help.isNotEmpty)
        KMenuGroup(
          title: 'Aide',
          dividerIndent: KSpacing.s16,
          children: [for (final e in help) row(e)],
        ),
    ];
  }

  // ---------------------------------------------------------- Apparence

  List<Widget> _appearance(BuildContext context) {
    final s = store.settings;
    final d3 = Display3DSettings.instance..load();
    return [
      KMenuGroup(
        dividerIndent: KSpacing.s16,
        children: [
          // UI0 : segments du kit ; libellés trop longs (grand texte, écran
          // étroit) : choix l'un sous l'autre, sans mot coupé (L5, C3).
          _mark(
            'theme',
            (lit) => KSegmentedRow<String>(
              title: 'Thème',
              subtitle: switch (s.theme) {
                'light' => 'Clair : fond blanc cassé',
                'system' => 'Système : suit le thème du téléphone',
                _ => 'Sombre : fond anthracite, lisible en extérieur',
              },
              highlight: lit,
              segments: const [
                KSegment('system', 'Système'),
                KSegment('dark', 'Sombre'),
                KSegment('light', 'Clair'),
              ],
              selected: ['system', 'dark', 'light'].contains(s.theme)
                  ? s.theme
                  : 'system',
              onChanged: (selected) {
                s.theme = selected;
                store.saveSettings();
              },
            ),
          ),
          // L5-C : indépendant du thème ; appliqué tout de suite, enregistré
          // avec les autres réglages.
          _mark(
            'palette',
            (lit) => _AccentPicker(
              selected: s.accent,
              highlight: lit,
              onSelected: (id) {
                if (s.accent == id) return;
                s.accent = id;
                store.saveSettings();
              },
            ),
          ),
          // UI0 (U6) : contraste renforcé, appliqué tout de suite.
          _mark(
            'contrast',
            (lit) => KSwitchRow(
              title: 'Contraste renforcé',
              subtitle: 'Textes et repères plus marqués',
              value: s.contrast,
              highlight: lit,
              onChanged: (v) {
                s.contrast = v;
                store.saveSettings();
              },
            ),
          ),
        ],
      ),
      // M2 (mannequin 3D) : préférences de l'appareil, hors sauvegarde.
      ListenableBuilder(
        listenable: d3.listenable,
        builder: (context, _) => KMenuGroup(
          title: 'Anatomie et 3D',
          dividerIndent: KSpacing.s16,
          children: [
            _mark(
              'muscle-names',
              (lit) => KSwitchRow(
                key: const ValueKey('settings-3d-names'),
                title: 'Nom du muscle au toucher',
                subtitle:
                    'Carte des muscles et mannequin 3D : touche un muscle '
                    'pour lire son nom',
                value: d3.touchNames.value,
                highlight: lit,
                onChanged: (v) => d3.set(touchNames: v),
              ),
            ),
            // M6c : plus de réglage « Os visibles » (personnage à la peau
            // lisse, sans squelette affiché).
            _mark(
              'halo',
              (lit) => KSwitchRow(
                key: const ValueKey('settings-3d-halo'),
                title: 'Halo',
                subtitle: 'Halo flou des muscles sollicités (net si désactivé)',
                value: d3.halo.value,
                highlight: lit,
                onChanged: (v) => d3.set(halo: v),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // ------------------------------------------------------------- Séance

  Widget _switch(
    String id,
    String title,
    String? subtitle,
    bool value,
    void Function(bool v) apply,
  ) => _mark(
    id,
    (lit) => KSwitchRow(
      title: title,
      subtitle: subtitle,
      value: value,
      highlight: lit,
      onChanged: (v) {
        apply(v);
        store.saveSettings();
      },
    ),
  );

  Widget _stepper({
    required String id,
    required String title,
    required String subtitle,
    required int value,
    required String label,
    required int min,
    required int max,
    required int step,
    required void Function(int v) apply,
  }) => _mark(
    id,
    (lit) => KStepperRow(
      title: title,
      subtitle: subtitle,
      value: label,
      highlight: lit,
      decrementLabel: 'Diminuer $title',
      incrementLabel: 'Augmenter $title',
      onDecrement: value > min
          ? () {
              apply((value - step).clamp(min, max));
              store.saveSettings();
            }
          : null,
      onIncrement: value < max
          ? () {
              apply((value + step).clamp(min, max));
              store.saveSettings();
            }
          : null,
    ),
  );

  List<Widget> _session() {
    final s = store.settings;
    return [
      KMenuGroup(
        title: 'Chronomètres',
        dividerIndent: KSpacing.s16,
        children: [
          _stepper(
            id: 'rest',
            title: 'Repos par défaut',
            subtitle: 'Quand l’exercice n’en précise pas',
            value: s.defaultRest,
            label: settingsSecondsLabel(s.defaultRest),
            min: 0,
            max: 300,
            step: 15,
            apply: (v) => s.defaultRest = v,
          ),
          _stepper(
            id: 'ready',
            title: 'Décompte « Prêt »',
            subtitle: 'Avant intervalles, EMOM, AMRAP et tenues',
            value: s.prepSec,
            label: settingsSecondsLabel(s.prepSec),
            min: 0,
            max: 10,
            step: 1,
            apply: (v) => s.prepSec = v,
          ),
          _switch(
            'auto-rest',
            'Lancer le repos à la validation d’une série',
            'Le chrono part tout seul',
            s.autoTimer,
            (v) => s.autoTimer = v,
          ),
        ],
      ),
      KMenuGroup(
        title: 'Fin du repos',
        dividerIndent: KSpacing.s16,
        children: [
          _switch(
            'sound',
            'Son en fin de chrono',
            'Repos, intervalles et tenues',
            s.sound,
            (v) => s.sound = v,
          ),
          // §4.6 : ce réglage commande aussi le retour haptique de
          // validation et de record (comportement inchangé).
          _switch(
            'vibration',
            'Vibration en fin de chrono',
            'Fin de chrono, validation et records ; pré-signal léger 3 s '
                'avant la fin',
            s.vibration,
            (v) => s.vibration = v,
          ),
        ],
      ),
      KMenuGroup(
        title: 'Saisie des séries',
        dividerIndent: KSpacing.s16,
        children: [
          // G9 (D5.4) : la note en flammes, à chaque série, remplace la
          // colonne RIR / RPE (réglages `trackRir` et `rpe` gardés dans les
          // données pour les anciennes sauvegardes, sans effet).
          _switch(
            'velocity',
            'Colonne vitesse (m/s) sur les lifts',
            'Pour suivre la vitesse de tes répétitions',
            s.trackVelocity,
            (v) => s.trackVelocity = v,
          ),
          _switch(
            'prefill',
            'Pré-remplir charge suggérée et reps prévues',
            null,
            s.prefill,
            (v) => s.prefill = v,
          ),
        ],
      ),
      KMenuGroup(
        title: 'Écran et unités',
        dividerIndent: KSpacing.s16,
        children: [
          _switch(
            'wakelock',
            'Garder l’écran allumé',
            'Pendant l’exécution d’une séance',
            s.wakelock,
            (v) => s.wakelock = v,
          ),
          _switch(
            'pounds',
            'Charges suggérées en livres (lb)',
            'Les valeurs du journal et des références restent en kg',
            s.lb,
            (v) => s.lb = v,
          ),
        ],
      ),
    ];
  }

  // ------------------------------------------------- Progression et jeu

  List<Widget> _progression() {
    final s = store.settings;
    return [
      KMenuGroup(
        dividerIndent: KSpacing.s16,
        children: [
          _switch(
            'celebrations',
            'Célébrations',
            'Écran de récompenses après une séance, records en direct, '
                'cérémonie de niveau',
            s.celebrations,
            (v) => s.celebrations = v,
          ),
          // §4.3 : mêmes valeurs que la carte de Stats ; une valeur 1 déjà
          // enregistrée n'est pas migrée (aucun segment choisi).
          _mark(
            'weekly-goal',
            (lit) => KSegmentedRow<int>(
              key: const ValueKey('settings-weekly-goal'),
              title: 'Objectif de la semaine',
              subtitle: weeklyGoalText(s.weeklyGoal),
              highlight: lit,
              segments: [
                for (final g in kWeeklyGoalChoices)
                  g == 0
                      ? const KSegment(0, 'Adaptatif')
                      : KSegment(
                          g,
                          '$g',
                          semanticLabel: '$g jours par semaine',
                        ),
              ],
              selected: kWeeklyGoalChoices.contains(s.weeklyGoal)
                  ? s.weeklyGoal
                  : null,
              onChanged: (v) {
                s.weeklyGoal = v;
                store.saveSettings();
              },
            ),
          ),
        ],
      ),
    ];
  }

  // ------------------------------------------ Données et confidentialité

  List<Widget> _data(BuildContext context) {
    final k = KTokens.of(context);
    final answers = store.koach.answers.length;
    // G10 (D1.4) : Koach L7 et l'adaptation au quotidien L11 sont remplacés
    // par le moteur dynamique ; leurs données restent dans la sauvegarde,
    // en lecture seule.
    final legacy = !store.koach.pristine || !store.adapt.pristine;
    final issues = store.koachLoadIssues;
    return [
      KMenuGroup(
        title: 'Sauvegardes',
        children: [
          _mark(
            'export',
            (lit) => KMenuRow(
              icon: Icons.save_alt_rounded,
              title: 'Exporter une sauvegarde',
              subtitle: 'Un fichier à l’emplacement de ton choix, non chiffré',
              highlight: lit,
              onTap: () => exportBackupFile(context, appVersion: kAppVersion),
            ),
          ),
          _mark(
            'import',
            (lit) => KMenuRow(
              icon: Icons.file_open_outlined,
              title: 'Importer une sauvegarde',
              subtitle:
                  'Depuis un fichier : aperçu, puis confirmation avant de '
                  'remplacer tes données',
              highlight: lit,
              onTap: () => importBackupFile(context, appVersion: kAppVersion),
            ),
          ),
          _mark(
            'copy',
            (lit) => KMenuRow(
              icon: Icons.copy_rounded,
              title: 'Copier la sauvegarde',
              subtitle: 'Même contenu, en texte, dans le presse-papiers',
              highlight: lit,
              onTap: () => _copy(context),
            ),
          ),
          _mark(
            'paste',
            (lit) => KMenuRow(
              icon: Icons.content_paste_rounded,
              title: 'Coller une sauvegarde',
              subtitle:
                  'Depuis un texte copié : même aperçu, même confirmation',
              highlight: lit,
              onTap: () => _paste(context),
            ),
          ),
          // G2 (D1.1) : copie faite avant la suppression des WOD et des
          // séances perso, gardée dans l'application.
          if (store.retiredNotice != null)
            _mark(
              'retired-copy',
              (lit) => KMenuRow(
                key: const ValueKey('settings-retired-copy'),
                icon: Icons.inventory_2_outlined,
                title: 'Copie d’avant la suppression des WOD',
                subtitle:
                    'Tes données d’avant cette mise à jour (WOD, séances '
                    'perso, crédits), à partager ou enregistrer',
                highlight: lit,
                onTap: () => _push(
                  context,
                  const RetiredNoticeScreen(fromSettings: true),
                ),
              ),
            ),
        ],
      ),
      // Contenu d'une sauvegarde : texte sous le groupe (plus dans la ligne).
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: KSpacing.s4),
        child: Text(
          'Contenu : références, journal, réglages, Koach, profil (données de '
          'santé comprises si tu en as saisi).',
          key: const ValueKey('settings-backup-content'),
          style: KType.detail.copyWith(color: k.texte2),
        ),
      ),
      // Information, pas une action : bandeau sous le groupe. La recherche
      // y mène (identifiant `android-backup`, amené à l'écran).
      _mark(
        'android-backup',
        (_) => const KNotice(
          key: ValueKey('settings-android-backup'),
          icon: Icons.info_outline_rounded,
          title: 'Sauvegarde Android',
          message:
              'L’application ne désactive pas la sauvegarde du système. '
              'Si la sauvegarde Google est activée sur ton téléphone, '
              'Android peut y copier les données de l’application (au '
              'plus une fois par 24 h, en Wi-Fi, à l’arrêt) et les '
              'restaurer à la réinstallation ou lors d’un transfert vers '
              'un nouveau téléphone. L’application ne peut ni la '
              'déclencher, ni la vérifier, ni l’effacer : l’export '
              'ci-dessus est la copie que tu contrôles.',
        ),
      ),
      const KSectionTitle('Confidentialité'),
      const KNotice(
        icon: Icons.phone_android_rounded,
        message:
            'Tout est calculé et conservé sur ce téléphone, sans compte ni '
            'connexion. Les données de Koach figurent dans l’export et sont '
            'effacées avec les données de l’application.',
      ),
      KMenuGroup(
        children: [
          _mark(
            'privacy',
            (lit) => KMenuRow(
              key: const ValueKey('about-privacy'),
              icon: Icons.privacy_tip_outlined,
              title: 'Politique de confidentialité',
              subtitle: 'Données, santé, export, suppression, tes droits',
              highlight: lit,
              onTap: () => _push(context, const PrivacyPolicyScreen()),
            ),
          ),
        ],
      ),
      if (legacy || issues > 0) ...[
        const KSectionTitle('Anciennes données de Koach'),
        if (legacy)
          const KNotice(
            key: ValueKey('settings-legacy-koach'),
            icon: Icons.history_rounded,
            title: 'Tes anciennes décisions de Koach',
            message:
                'Tes décisions d’avant la nouvelle méthode restent dans ta '
                'sauvegarde, sans être modifiées.',
          ),
        if (issues > 0)
          KNotice(
            icon: Icons.report_outlined,
            tone: KTone.warning,
            title: 'Anciennes données de Koach relues en partie',
            message:
                '$issues entrée(s) illisible(s) ignorée(s) à '
                'l’ouverture ; le reste est chargé. Ton export de '
                'sauvegarde contient les données relues.',
          ),
      ],
      // C10 : actions destructrices dans le dernier groupe, confirmées.
      KMenuGroup(
        title: 'Zone sensible',
        children: [
          // KT-036 : suppression des seules réponses aux questionnaires.
          if (answers > 0)
            _mark(
              'delete-answers',
              (lit) => KMenuRow(
                key: const ValueKey('settings-delete-answers'),
                icon: Icons.delete_sweep_outlined,
                danger: true,
                title: 'Supprimer mes réponses aux anciens questionnaires',
                subtitle: '$answers séance(s) : sommeil, forme et douleur',
                highlight: lit,
                onTap: () => _clearAnswers(context),
              ),
            ),
          _mark(
            'erase',
            (lit) => KMenuRow(
              key: const ValueKey('settings-erase'),
              icon: Icons.delete_forever_outlined,
              danger: true,
              title: 'Supprimer les données de l’application',
              subtitle:
                  'Remet l’application à son état d’installation, après '
                  'confirmation. Export préalable proposé.',
              highlight: lit,
              onTap: () => eraseAppData(context, appVersion: kAppVersion),
            ),
          ),
        ],
      ),
    ];
  }

  // --------------------------------------------------- Aide et à propos

  List<Widget> _about(BuildContext context) => [
    KMenuGroup(
      title: 'Aide',
      children: [
        // « Récupération » est une ligne de Santé et sécurité (plus de
        // doublon sur cette page).
        _mark(
          'safety',
          (lit) => KMenuRow(
            key: const ValueKey('about-safety'),
            icon: Icons.health_and_safety_outlined,
            title: 'Santé et sécurité',
            subtitle:
                'Signaux d’alerte, douleur, situations particulières, '
                'récupération',
            highlight: lit,
            onTap: () => _push(context, const SafetyScreen()),
          ),
        ),
        _mark(
          'explainer',
          (lit) => KMenuRow(
            key: const ValueKey('about-explainer'),
            icon: Icons.help_outline_rounded,
            title: 'Comment marche ton programme ?',
            subtitle: 'Création avec Koach, puis évolution séance après séance',
            highlight: lit,
            onTap: () => showProgramExplainer(context),
          ),
        ),
        _mark(
          'koach-gallery',
          (lit) => KMenuRow(
            key: const ValueKey('about-koach-gallery'),
            icon: Icons.emoji_people_rounded,
            title: 'Galerie de Koach',
            subtitle: 'Toutes les poses de Koach',
            highlight: lit,
            onTap: () => _push(context, const KoachGalleryScreen()),
          ),
        ),
        _mark(
          'feedback',
          (lit) => KMenuRow(
            key: const ValueKey('about-feedback'),
            icon: Icons.rate_review_outlined,
            title: 'Donner mon avis',
            subtitle: 'Retour de test, partagé seulement si tu le choisis',
            highlight: lit,
            onTap: () =>
                _push(context, const FeedbackScreen(appVersion: kAppVersion)),
          ),
        ),
        _mark(
          'licences',
          (lit) => KMenuRow(
            key: const ValueKey('about-licences'),
            icon: Icons.menu_book_outlined,
            title: 'Sources et licences',
            subtitle: 'Fiches d’exercices, démonstrations et mannequin 3D',
            highlight: lit,
            onTap: () => _push(context, const MentionsScreen()),
          ),
        ),
        // M1 (mannequin 3D) : rendu test, compatibilité et fluidité.
        _mark(
          'compat-3d',
          (lit) => KMenuRow(
            key: const ValueKey('about-engine3d'),
            icon: Icons.view_in_ar_outlined,
            title: 'Compatibilité 3D',
            subtitle: 'Rendu test, compatibilité du téléphone et fluidité',
            highlight: lit,
            onTap: () => _push(context, const Engine3DScreen()),
          ),
        ),
      ],
    ),
    // L13 (KT-072 à KT-078) : finalité, sécurité, confidentialité, retour
    // de test.
    const KSectionTitle('Avertissement'),
    const DisclaimerCard(),
    const KSectionTitle('Version'),
    KCard(
      key: const ValueKey('about-version'),
      child: KRowLabel(
        'Kalis Track $kAppVersion',
        subtitle:
            'Programme streetlifting v3.3 · base d’exercices '
            'v${store.content.version} '
            '(${store.content.entries.length} exercices)',
      ),
    ),
    // G1 (D2.4) : visible seulement dans un build de développement.
    if (kDevBuild)
      const KCard(
        key: ValueKey('about-dev-build'),
        child: KRowLabel(
          'Build de développement',
          subtitle:
              'Mode dev disponible : 5 appuis sur le logo de l’accueil '
              'ouvrent une session de test séparée de la tienne.',
        ),
      ),
  ];
}

// ------------------------------------------------------------- actions

Future<void> _copy(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await Clipboard.setData(ClipboardData(text: store.exportCompact()));
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Sauvegarde copiée dans le presse-papiers.'),
      ),
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Impossible de copier la sauvegarde. Réessaie.'),
      ),
    );
  }
}

/// « Coller une sauvegarde » : sous-page de saisie, puis le même aperçu et
/// la même confirmation que l'import d'un fichier.
Future<void> _paste(BuildContext context) async {
  final raw = await Navigator.push<String>(
    context,
    MaterialPageRoute<String>(builder: (_) => const PasteBackupPage()),
  );
  if (raw == null || raw.isEmpty || !context.mounted) return;
  await confirmAndImport(context, raw, appVersion: kAppVersion);
}

/// KT-036 : suppression des seules réponses aux questionnaires.
Future<void> _clearAnswers(BuildContext context) async {
  final ok = await showKConfirm(
    context,
    title: 'Supprimer tes réponses ?',
    message:
        'Sommeil, forme et douleur de toutes les séances seront effacés. '
        'Séances, séries et références ne changent pas.',
    confirmLabel: 'Supprimer',
    destructive: true,
  );
  if (ok) store.clearKoachAnswers();
}

/// Sous-page « Coller une sauvegarde » : le texte saisi est rendu par
/// `Navigator.pop` ; « Retour » n'importe rien.
class PasteBackupPage extends StatefulWidget {
  const PasteBackupPage({super.key});

  @override
  State<PasteBackupPage> createState() => _PasteBackupPageState();
}

class _PasteBackupPageState extends State<PasteBackupPage> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KPage.sub(
    title: 'Coller une sauvegarde',
    lead:
        'Un aperçu du contenu s’affichera avant tout remplacement de tes '
        'données.',
    bottom: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KSpacing.page,
          KSpacing.s8,
          KSpacing.page,
          KSpacing.s16,
        ),
        child: KPrimaryButton(
          key: const ValueKey('paste-preview'),
          label: 'Voir l’aperçu',
          onPressed: () => Navigator.pop(context, _text.text.trim()),
        ),
      ),
    ),
    children: [
      TextField(
        key: const ValueKey('paste-field'),
        controller: _text,
        minLines: 6,
        maxLines: 12,
        decoration: const InputDecoration(
          hintText: 'Colle le texte exporté ici',
        ),
      ),
    ],
  );
}

// ----------------------------------------------------------- composants

/// UI0 (refonte UI) : sélecteur des 8 palettes du propriétaire, avec
/// aperçu (`KPalettePicker` du kit) ; appliqué tout de suite, enregistré
/// avec les autres réglages. Le choix se lit sans la couleur (anneau, coche,
/// nom de la palette). UI4 : ligne du groupe Apparence (plus de carte dans
/// une carte, C7).
class _AccentPicker extends StatelessWidget {
  final String selected;
  final bool highlight;
  final ValueChanged<String> onSelected;
  const _AccentPicker({
    required this.selected,
    required this.onSelected,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final current = KAccentSpec.byId(selected);
    final k = KTokens.of(context);
    return KRowFrame(
      key: const ValueKey('accent-picker'),
      highlight: highlight,
      padding: const EdgeInsets.fromLTRB(
        KSpacing.s16,
        KSpacing.s12,
        KSpacing.s16,
        KSpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KPalettePicker(selectedId: current.id, onSelected: onSelected),
          const SizedBox(height: KSpacing.s8),
          Text(
            '${current.label} : boutons, jour en cours, repères et chiffres '
            'mis en avant. Erreurs, validations et graphiques gardent leurs '
            'couleurs.',
            key: const ValueKey('accent-summary'),
            style: KType.detail.copyWith(color: k.texte2),
          ),
          ValueListenableBuilder<String?>(
            valueListenable: store.persistenceError,
            builder: (context, error, _) => error == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: KSpacing.s4),
                    child: Text(
                      'Choix affiché, mais les réglages ne sont pas '
                      'encore enregistrés : utilise « Réessayer » dans '
                      'le message d’erreur.',
                      key: const ValueKey('accent-unsaved'),
                      style: KType.detail.copyWith(color: k.danger),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
