// UI0 (refonte UI) : catalogue des composants du kit, ouvert depuis les
// outils du mode dev (build de développement). Chaque section montre un
// composant dans la palette, le thème et le contraste choisis en tête de
// page, sans toucher aux réglages de l'utilisateur. Les mêmes sections
// servent aux captures (`test/ui0_kit_capture_test.dart`).
import 'package:flutter/material.dart';

import 'kit.dart';

/// Une section du catalogue.
@immutable
class KitSample {
  final String id, title;
  final WidgetBuilder builder;
  const KitSample(this.id, this.title, this.builder);
}

void _noop() {}

/// Sections du catalogue, dans l'ordre du cahier §5.4.
final List<KitSample> kitSamples = [
  KitSample('jetons', 'Jetons de couleur', (context) {
    final k = KTokens.of(context);
    final roles = k.roles.named.entries.toList()
      ..addAll(
        {
          'validation': k.validation,
          'danger': k.danger,
          'avertissement': k.avertissement,
          'rampe': k.roles.rampe,
        }.entries,
      );
    return Wrap(
      spacing: KSpacing.s8,
      runSpacing: KSpacing.s8,
      children: [
        for (final e in roles)
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: KSpacing.s32,
                  decoration: ShapeDecoration(
                    color: e.value,
                    shape: RoundedRectangleBorder(
                      borderRadius: KRadius.menuRadius,
                      side: BorderSide(color: k.filet),
                    ),
                  ),
                ),
                Text(e.key, style: KType.detail.copyWith(color: k.texte)),
                Text(
                  kHex(e.value),
                  style: KType.detail.copyWith(color: k.texte2),
                ),
              ],
            ),
          ),
      ],
    );
  }),
  KitSample('typo', 'Typographie', (context) {
    final k = KTokens.of(context);
    final styles = <String, TextStyle>{
      'titreRacine': k.titleStyle(KType.titreRacine),
      'titreEcran': k.titleStyle(KType.titreEcran),
      'titreSeance': k.titleStyle(KType.titreSeance),
      'titreCarte': KType.titreCarte,
      'corpsFort': KType.corpsFort,
      'corps': KType.corps,
      'detail': KType.detail,
      'section': KType.section,
      'micro': KType.micro,
      'chiffre': KType.chiffre,
      'chiffreMoyen': KType.chiffreMoyen,
      'chrono': KType.chrono,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in styles.entries)
          Text(
            e.key.startsWith('titreR') ||
                    e.key.startsWith('titreE') ||
                    e.key.startsWith('titreS')
                ? k.title('${e.key} Semaine 13')
                : e.key.startsWith('chiffre') || e.key == 'chrono'
                ? '4 × 5  2:27  34–49'
                : '${e.key} — Séance du jour, 6 exercices',
            style: e.value.copyWith(color: k.texte),
          ),
      ],
    );
  }),
  KitSample(
    'boutons',
    'Boutons',
    (context) => const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KPrimaryButton(label: 'Commencer la séance', onPressed: _noop),
        SizedBox(height: KSpacing.s12),
        Wrap(
          spacing: KSpacing.s8,
          runSpacing: KSpacing.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            KTonalButton(label: 'Voir la saison', onPressed: _noop),
            KTextButton(label: 'Pourquoi ?', onPressed: _noop),
            KIconButton(
              icon: Icons.more_vert_rounded,
              tooltip: "Plus d'actions",
              onPressed: _noop,
            ),
          ],
        ),
        SizedBox(height: KSpacing.s12),
        KPrimaryButton(label: 'Supprimer', danger: true, onPressed: _noop),
        SizedBox(height: KSpacing.s12),
        KPrimaryButton(label: 'Créer mon programme', onPressed: null),
      ],
    ),
  ),
  KitSample(
    'cartes',
    'Cartes, bandeaux, état vide',
    (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KCard.day(
          onTap: _noop,
          child: Builder(
            builder: (context) {
              final k = KTokens.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    k.title("J3, aujourd'hui"),
                    style: KType.micro.copyWith(color: k.surPleine),
                  ),
                  Text(
                    k.title('Squat et gainage'),
                    style: k.titleStyle(
                      KType.titreSeance.copyWith(color: k.surPleine),
                    ),
                  ),
                  Text(
                    '34–49 min',
                    style: KType.chiffre.copyWith(color: k.surPleine),
                  ),
                  Text(
                    '6 exercices, 19 séries, 136 rép.',
                    style: KType.detail.copyWith(color: k.surPleine),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: KSpacing.s12),
        const KCard(
          child: Text(
            'Carte de contenu : lignes, champs, puces, jamais une autre carte.',
          ),
        ),
        const SizedBox(height: KSpacing.s12),
        const KNotice(
          icon: Icons.auto_awesome_rounded,
          title: 'Nouveau',
          message: '11 questions pour affiner ton profil.',
          actionLabel: 'Compléter mon profil',
          onAction: _noop,
          onClose: _noop,
        ),
        const SizedBox(height: KSpacing.s12),
        const KNotice(
          tone: KTone.warning,
          icon: Icons.warning_amber_rounded,
          message: 'Avis médical pas encore confirmé.',
        ),
        const SizedBox(height: KSpacing.s12),
        const KEmpty(
          icon: Icons.event_busy_rounded,
          title: 'Ta saison est vide',
          message: 'Ajoute une compétition pour voir ses phases.',
          action: 'Ajouter une compétition',
          onAction: _noop,
        ),
      ],
    ),
  ),
  KitSample('menus', 'Groupes et lignes de menu', (context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KSearchField(hint: 'Rechercher un réglage'),
        KMenuGroup(
          title: 'Application',
          children: [
            KMenuRow(
              icon: Icons.palette_outlined,
              title: 'Apparence',
              subtitle: 'Thème, palette, contraste, anatomie 3D',
              onTap: _noop,
            ),
            KMenuRow(
              icon: Icons.timer_outlined,
              title: 'Séance',
              subtitle: 'Saisie, chronomètres, écran et unités',
              onTap: _noop,
              highlight: true,
            ),
            KMenuRow(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Rappel de séance et son heure',
              value: '7:30',
              onTap: _noop,
            ),
          ],
        ),
        KMenuGroup(
          title: 'Plus',
          children: [
            KMenuRow(
              icon: Icons.delete_outline_rounded,
              title: 'Supprimer les données',
              danger: true,
              onTap: _noop,
            ),
          ],
        ),
      ],
    );
  }),
  KitSample('reglages', 'Réglages en place', (context) {
    return const _SettingsSample();
  }),
  KitSample('programme', 'Programme', (context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KSeasonBar(
          blocks: [
            KSeasonBlock(3),
            KSeasonBlock(8),
            KSeasonBlock(8),
            KSeasonBlock(6),
            KSeasonBlock(6),
            KSeasonBlock(9),
          ],
          week: 13,
        ),
        SizedBox(height: KSpacing.s16),
        KDayRow(
          number: 'J1',
          title: 'Muscle-up + tirage lourd',
          state: KDayState.done,
          onTap: _noop,
        ),
        SizedBox(height: KSpacing.s8),
        KDayRow(
          number: 'J2',
          title: 'Dip lourd + poussée',
          state: KDayState.missed,
          onTap: _noop,
        ),
        SizedBox(height: KSpacing.s8),
        KDayRow(
          number: 'J6',
          title: 'Puissance MU + squat endurance',
          onTap: _noop,
          onInfo: _noop,
        ),
        SizedBox(height: KSpacing.s8),
        KDayRow(number: 'J7', title: 'Repos complet', state: KDayState.rest),
        SizedBox(height: KSpacing.s16),
        KTimeline(
          phases: [
            KPhase(
              'Reprise',
              dates: '01/09 – 21/09',
              length: '3 sem.',
              state: KPhaseState.past,
            ),
            KPhase(
              'Force',
              dates: '22/09 – 16/11',
              length: '8 sem.',
              state: KPhaseState.current,
            ),
            KPhase('Puissance', dates: '17/11 – 11/01', length: '8 sem.'),
          ],
        ),
      ],
    );
  }),
  KitSample('seance', 'Séance', (context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Wrap(
          spacing: KSpacing.s8,
          children: [
            KChip('RIR 4'),
            KChip('Difficulté 3/10'),
            KChip('Repos 4 min'),
          ],
        ),
        const SizedBox(height: KSpacing.s12),
        KSetTable(
          columns: const ['kg', 'Reps'],
          rows: [
            KSetRow(
              number: '1',
              state: KSetState.done,
              cells: const [
                KSetField('+32,5', dimmed: true),
                KSetField('5', dimmed: true),
              ],
              actions: [
                Icon(
                  Icons.check_circle_rounded,
                  color: KTokens.of(context).validation,
                ),
              ],
            ),
            const KSetRow(
              number: '2',
              state: KSetState.current,
              cells: [
                KSetField('+32,5', onSurface: true, onTap: _noop),
                KSetField('5', onSurface: true, onTap: _noop),
              ],
              actions: [
                KIconButton(
                  icon: Icons.check_rounded,
                  tooltip: 'Valider la série 2',
                  onPressed: _noop,
                ),
              ],
            ),
            const KSetRow(
              number: '3',
              cells: [KSetField('+32,5'), KSetField('5')],
              actions: [SizedBox.shrink()],
            ),
          ],
        ),
        const SizedBox(height: KSpacing.s16),
        const KSnack(
          message: 'Koach : série suivante dans 2 s',
          actionLabel: 'Annuler',
          onAction: _noop,
        ),
        const SizedBox(height: KSpacing.s8),
        const KRestBar(
          remaining: '2:27',
          progress: .98,
          onMinus: _noop,
          onPlus: _noop,
          onStop: _noop,
        ),
      ],
    );
  }),
  KitSample('feuilles', "Feuille d'actions, de liste, confirmation", (context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: KTokens.of(context).surface,
          shape: const RoundedRectangleBorder(
            borderRadius: KRadius.sheetRadius,
          ),
          child: KActionSheet<String>(
            title: 'Séance',
            subtitle: 'Corps entier, S1, J2',
            onSelected: (_) {},
            onClose: _noop,
            groups: const [
              [
                KAction(
                  icon: Icons.menu_book_outlined,
                  label: 'Consignes de séance',
                  value: 'consignes',
                ),
                KAction(
                  icon: Icons.favorite_border_rounded,
                  label: 'Bilan du jour',
                  value: 'bilan',
                ),
              ],
              [
                KAction(
                  icon: Icons.warning_amber_rounded,
                  label: 'Douleur ou malaise ?',
                  value: 'douleur',
                  tone: KActionTone.warning,
                ),
                KAction(
                  icon: Icons.tune_rounded,
                  label: 'Mes références',
                  value: 'references',
                ),
              ],
              [
                KAction(
                  icon: Icons.delete_outline_rounded,
                  label: "Supprimer l'historique de cette séance",
                  value: 'supprimer',
                  danger: true,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: KSpacing.s16),
        SizedBox(
          height: 420 * MediaQuery.textScalerOf(context).scale(1),
          child: Material(
            color: KTokens.of(context).surface,
            shape: const RoundedRectangleBorder(
              borderRadius: KRadius.sheetRadius,
            ),
            child: KListSheet(
              title: 'Dans cette séance',
              summary: '7 exercices, 22 min',
              onSelected: (_) {},
              items: const [
                KListItem(
                  'Bilan du jour',
                  detail: 'Ressenti et changements de Koach',
                  icon: Icons.favorite_border_rounded,
                ),
                KListItem(
                  'Échauffement',
                  detail: '6 min',
                  state: KListState.done,
                ),
                KListItem(
                  'Test max tractions au poids de corps',
                  detail: '1 série au maximum',
                  state: KListState.current,
                ),
                KListItem('Traction pronation', detail: '3 × 6, RIR 2'),
                KListItem('Gainage creux', detail: '3 × 30 s'),
              ],
            ),
          ),
        ),
        const SizedBox(height: KSpacing.s16),
        const KConfirm(
          title: "Supprimer l'historique de cette séance ?",
          message:
              'Les séries saisies aujourd’hui seront effacées. Le programme ne change pas.',
          confirmLabel: 'Supprimer',
          destructive: true,
          onConfirm: _noop,
          onCancel: _noop,
        ),
      ],
    );
  }),
  KitSample('palettes', 'Palette', (context) {
    final k = KTokens.of(context);
    return KPalettePicker(selectedId: k.paletteId, onSelected: (_) {});
  }),
  KitSample('dock', 'Dock', (context) {
    return _DockSample();
  }),
];

class _SettingsSample extends StatefulWidget {
  const _SettingsSample();
  @override
  State<_SettingsSample> createState() => _SettingsSampleState();
}

class _SettingsSampleState extends State<_SettingsSample> {
  bool _sound = true, _vibration = false;
  int _rest = 90;
  String _theme = 'system';
  int _goal = 0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KMenuGroup(
        title: 'Chronomètres',
        dividerIndent: KSpacing.s16,
        children: [
          KStepperRow(
            title: 'Repos par défaut',
            subtitle: 'Quand l’exercice n’en indique pas',
            value:
                '${_rest ~/ 60} min ${(_rest % 60).toString().padLeft(2, '0')}',
            onDecrement: _rest > 15 ? () => setState(() => _rest -= 15) : null,
            onIncrement: () => setState(() => _rest += 15),
            decrementLabel: 'Retirer 15 s',
            incrementLabel: 'Ajouter 15 s',
          ),
          KSwitchRow(
            title: 'Son en fin de repos',
            subtitle: 'Trois bips',
            value: _sound,
            onChanged: (v) => setState(() => _sound = v),
          ),
          KSwitchRow(
            title: 'Vibration',
            subtitle: 'Fin de chrono, validation et records',
            value: _vibration,
            onChanged: (v) => setState(() => _vibration = v),
          ),
        ],
      ),
      KMenuGroup(
        title: 'Apparence',
        dividerIndent: KSpacing.s16,
        children: [
          KSegmentedRow<String>(
            title: 'Thème',
            segments: const [
              KSegment('system', 'Système'),
              KSegment('dark', 'Sombre'),
              KSegment('light', 'Clair'),
            ],
            selected: _theme,
            onChanged: (v) => setState(() => _theme = v),
          ),
          KSegmentedRow<int>(
            title: 'Objectif de la semaine',
            segments: const [
              KSegment(0, 'Adaptatif'),
              KSegment(2, '2'),
              KSegment(3, '3'),
              KSegment(4, '4'),
              KSegment(5, '5'),
              KSegment(6, '6'),
            ],
            selected: _goal,
            onChanged: (v) => setState(() => _goal = v),
          ),
        ],
      ),
    ],
  );
}

class _DockSample extends StatefulWidget {
  @override
  State<_DockSample> createState() => _DockSampleState();
}

class _DockSampleState extends State<_DockSample> {
  int _index = 2;
  @override
  Widget build(BuildContext context) => KDock(
    keyPrefix: 'catalogue-nav',
    index: _index,
    onTap: (i) => setState(() => _index = i),
    items: const [
      KDockItem(Icons.grid_view_rounded, 'Arsenal'),
      KDockItem(Icons.insights_rounded, 'Stats'),
      KDockItem(Icons.fitness_center_rounded, 'Programme'),
      KDockItem(Icons.settings_outlined, 'Réglages'),
    ],
  );
}

/// Contenu d'une section du catalogue, dans le thème d'une palette.
class KitSampleView extends StatelessWidget {
  final KitSample sample;
  const KitSampleView(this.sample, {super.key});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return ColoredBox(
      color: k.fond,
      child: Padding(
        padding: const EdgeInsets.all(KSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(sample.title, style: KType.section.copyWith(color: k.texte2)),
            const SizedBox(height: KSpacing.s8),
            Builder(builder: sample.builder),
          ],
        ),
      ),
    );
  }
}

/// Écran du catalogue (mode dev).
class KitCatalogScreen extends StatefulWidget {
  const KitCatalogScreen({super.key});
  @override
  State<KitCatalogScreen> createState() => _KitCatalogScreenState();
}

class _KitCatalogScreenState extends State<KitCatalogScreen> {
  String? _palette;
  bool? _dark;
  bool _contrast = false;

  @override
  Widget build(BuildContext context) {
    final current = KTokens.of(context);
    final palette = _palette ?? current.paletteId;
    final dark = _dark ?? current.dark;
    final theme = kitTheme(dark: dark, paletteId: palette, contrast: _contrast);
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) => KPage.sub(
          title: 'Catalogue du kit',
          lead: 'Composants de la refonte, dans la palette choisie ici.',
          children: [
            KMenuGroup(
              dividerIndent: KSpacing.s16,
              children: [
                KSegmentedRow<bool>(
                  title: 'Thème',
                  segments: const [
                    KSegment(true, 'Sombre'),
                    KSegment(false, 'Clair'),
                  ],
                  selected: dark,
                  onChanged: (v) => setState(() => _dark = v),
                ),
                KSwitchRow(
                  title: 'Contraste renforcé',
                  value: _contrast,
                  onChanged: (v) => setState(() => _contrast = v),
                ),
                Padding(
                  padding: const EdgeInsets.all(KSpacing.s16),
                  child: KPalettePicker(
                    selectedId: palette,
                    showPreview: false,
                    onSelected: (id) => setState(() => _palette = id),
                  ),
                ),
              ],
            ),
            for (final s in kitSamples) KitSampleView(s),
          ],
        ),
      ),
    );
  }
}
