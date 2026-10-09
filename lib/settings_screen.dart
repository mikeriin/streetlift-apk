import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'data_control.dart';
import 'engine3d.dart';
import 'exercise_screens.dart';
import 'mannequin_3d.dart';
import 'ui.dart';
import 'wellbeing_screens.dart';
import 'notification_settings.dart';
import 'pilotage_screen.dart';
import 'program_start.dart';
import 'program_screens.dart';
import 'athlete_profile_screen.dart';
import 'retired_notice_screen.dart';
import 'store.dart';
import 'store_widget.dart';
import 'dev/dev_flags.dart';

/// Version de l'application (pubspec sans le numéro de build).
const kVersion = '6.9.3';

/// Version affichée (D0.9) : « dev6.8.0 » dans le build de développement
/// (APK du propriétaire), « 6.8.0 » dans l’AAB du Play Store.
const kAppVersion = kDevBuild ? 'dev$kVersion' : kVersion;

class SettingsScreen extends StatelessWidget {
  final int? section;
  const SettingsScreen({super.key, this.section});

  @override
  Widget build(BuildContext context) {
    // L6 : différé tant que l'onglet est masqué (voir store_widget.dart).
    return StoreBuilder(
      builder: (context) {
        final s = store.settings;
        void save() => store.saveSettings();
        final items = <Widget>[
          const _Sec('Apparence'),
          _Tile(
            title: 'Thème',
            subtitle: switch (s.theme) {
              'light' => 'Clair : fond blanc cassé',
              'system' => 'Système : suit le thème du téléphone',
              _ => 'Sombre : fond anthracite, lisible en extérieur',
            },
            // L5 : au-delà de 150 % de texte, trois choix empilés plutôt que
            // trois segments où « Système » était coupé en deux.
            below: MediaQuery.textScalerOf(context).scale(10) > 15
                ? RadioGroup<String>(
                    groupValue: ['system', 'dark', 'light'].contains(s.theme)
                        ? s.theme
                        : 'system',
                    onChanged: (selected) {
                      if (selected == null) return;
                      s.theme = selected;
                      save();
                    },
                    child: Column(
                      children: [
                        for (final (value, label) in const [
                          ('system', 'Système'),
                          ('dark', 'Sombre'),
                          ('light', 'Clair'),
                        ])
                          RadioListTile<String>(
                            key: ValueKey('theme-$value'),
                            value: value,
                            contentPadding: EdgeInsets.zero,
                            title: Text(label),
                          ),
                      ],
                    ),
                  )
                : SegmentedButton<String>(
                    expandedInsets: EdgeInsets.zero,
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'system', label: Text('Système')),
                      ButtonSegment(value: 'dark', label: Text('Sombre')),
                      ButtonSegment(value: 'light', label: Text('Clair')),
                    ],
                    selected: {
                      ['system', 'dark', 'light'].contains(s.theme)
                          ? s.theme
                          : 'system',
                    },
                    onSelectionChanged: (selected) {
                      s.theme = selected.single;
                      save();
                    },
                  ),
          ),
          // L5-C : indépendant du thème ; appliqué tout de suite, enregistré
          // avec les autres réglages.
          _AccentPicker(
            selected: s.accent,
            onSelected: (id) {
              if (s.accent == id) return;
              s.accent = id;
              save();
            },
          ),
          const _Sec('Saisie des séries'),
          // G9 (D5.4) : la note en flammes, à chaque série, remplace la
          // colonne RIR / RPE (réglages `trackRir` et `rpe` gardés dans les
          // données pour les anciennes sauvegardes, sans effet).
          _Sw(
            'Colonne vitesse (m/s) sur les lifts',
            'Pour suivre la vitesse de tes répétitions',
            s.trackVelocity,
            (v) {
              s.trackVelocity = v;
              save();
            },
          ),
          _Sw('Pré-remplir charge suggérée et reps prévues', null, s.prefill, (
            v,
          ) {
            s.prefill = v;
            save();
          }),
          const _Sec('Chronomètres'),
          _Stepper(
            title: 'Repos par défaut',
            subtitle: 'Quand l\u2019exercice n\u2019en précise pas',
            value: s.defaultRest,
            unit: 's',
            min: 0,
            max: 300,
            step: 15,
            onChanged: (v) {
              s.defaultRest = v;
              save();
            },
          ),
          _Sw(
            'Lancer le repos à la validation d\u2019une série',
            null,
            s.autoTimer,
            (v) {
              s.autoTimer = v;
              save();
            },
          ),
          _Stepper(
            title: 'Décompte « Prêt »',
            subtitle: 'Avant intervalles, EMOM, AMRAP et tenues',
            value: s.prepSec,
            unit: 's',
            min: 0,
            max: 10,
            step: 1,
            onChanged: (v) {
              s.prepSec = v;
              save();
            },
          ),
          _Sw('Son en fin de chrono', null, s.sound, (v) {
            s.sound = v;
            save();
          }),
          _Sw(
            'Vibration en fin de chrono',
            'Pré-signal léger 3 s avant la fin',
            s.vibration,
            (v) {
              s.vibration = v;
              save();
            },
          ),
          const _Sec('Progression et jeu'),
          _Sw(
            'Célébrations',
            'Écran de récompenses après une séance, records en direct, cérémonie de niveau',
            s.celebrations,
            (v) {
              s.celebrations = v;
              save();
            },
          ),
          _Stepper(
            title: 'Objectif de jours actifs par semaine',
            subtitle: s.weeklyGoal == 0
                ? 'Adaptatif : moyenne récente + 1 (0 = adaptatif)'
                : 'Cap personnel, sans XP',
            value: s.weeklyGoal,
            unit: 'j',
            min: 0,
            max: 6,
            step: 1,
            onChanged: (v) {
              s.weeklyGoal = v;
              save();
            },
          ),
          const _Sec('Pendant la séance'),
          _Sw(
            'Garder l\u2019écran allumé',
            'Pendant l\u2019exécution d\u2019une séance',
            s.wakelock,
            (v) {
              s.wakelock = v;
              save();
            },
          ),
          _Sw(
            'Charges suggérées en livres (lb)',
            'Les valeurs du journal et des références restent en kg',
            s.lb,
            (v) {
              s.lb = v;
              save();
            },
          ),
          const _Sec('Notifications'),
          const NotificationSettingsPanel(),
          const _Sec('Sauvegardes'),
          _Action(
            icon: Icons.save_alt_rounded,
            color: SL.accent,
            title: 'Exporter une sauvegarde',
            subtitle:
                'Fichier à l’emplacement de ton choix : pilotage, journal, réglages, Koach, profil (données de santé comprises si tu en as saisi). Non chiffré.',
            onTap: () => exportBackupFile(context, appVersion: kAppVersion),
          ),
          _Action(
            icon: Icons.file_open_outlined,
            color: SL.accent,
            title: 'Importer une sauvegarde',
            subtitle:
                'Depuis un fichier : aperçu du contenu, puis confirmation avant de remplacer tes données',
            onTap: () => importBackupFile(context, appVersion: kAppVersion),
          ),
          _Action(
            icon: Icons.copy_rounded,
            color: SL.accent,
            title: 'Copier la sauvegarde',
            subtitle: 'Même contenu, en texte, dans le presse-papiers',
            onTap: () async {
              try {
                await Clipboard.setData(
                  ClipboardData(text: store.exportCompact()),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Sauvegarde copiée dans le presse-papiers.',
                      ),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Impossible de copier la sauvegarde. Réessaie.',
                      ),
                    ),
                  );
                }
              }
            },
          ),
          _Action(
            icon: Icons.content_paste_rounded,
            color: SL.accent,
            title: 'Coller une sauvegarde',
            subtitle: 'Depuis un texte copié : même aperçu, même confirmation',
            onTap: () => _import(context),
          ),
          // G2 (D1.1) : copie faite avant la suppression des WOD et des
          // séances perso, gardée dans l'application.
          if (store.retiredNotice != null)
            _Action(
              key: const ValueKey('settings-retired-copy'),
              icon: Icons.inventory_2_outlined,
              color: SL.accent,
              title: 'Copie d’avant la suppression des WOD',
              subtitle:
                  'Toutes tes données d’avant cette mise à jour (WOD, séances perso, crédits) : à partager ou enregistrer',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const RetiredNoticeScreen(fromSettings: true),
                ),
              ),
            ),
          const _Tile(
            title: 'Sauvegarde Android',
            subtitle:
                'L’application ne désactive pas la sauvegarde du système. Si la sauvegarde Google est activée sur ton téléphone, Android peut y copier les données de l’application (au plus une fois par 24 h, en Wi-Fi, à l’arrêt) et les restaurer à la réinstallation ou lors d’un transfert vers un nouveau téléphone. L’application ne peut ni la déclencher, ni la vérifier, ni l’effacer : l’export ci-dessus est la copie que tu contrôles.',
          ),
          const KSection('Zone sensible'),
          _Action(
            icon: Icons.delete_forever_outlined,
            color: Theme.of(context).colorScheme.error,
            danger: true,
            title: 'Supprimer les données de l’application',
            subtitle:
                'Remet l’application à son état d’installation, après confirmation. Export préalable proposé.',
            onTap: () => eraseAppData(context, appVersion: kAppVersion),
          ),
          const _Sec('Programme'),
          // L8 puis G6 : profil d'athlète v2, santé et mode prudent.
          _Action(
            key: const ValueKey('settings-profile'),
            icon: Icons.person_outline,
            color: SL.accent,
            title: 'Profil',
            subtitle: switch ((store.athlete, store.caution.active)) {
              (null, _) =>
                store.profile != null ? 'À refaire avec Koach' : 'À créer',
              (_, true) => 'Disciplines, objectifs, matériel · mode prudent',
              _ => 'Disciplines, niveau, objectifs, disponibilités, matériel',
            },
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
          ),
          // G7 : programme créé avec Koach (kalis_plan), où j'en suis.
          _Action(
            key: const ValueKey('settings-program'),
            icon: Icons.auto_awesome_outlined,
            color: SL.accent,
            title: 'Mon programme',
            subtitle: PlanStore(store).programPlanned
                ? 'Créé avec Koach · où j’en suis, nouveau programme'
                : store.programGenerated
                ? 'Personnalisé · ${store.programSummary['modelLabel'] ?? ''}'
                : store.athlete != null && store.program.start == null
                ? 'À créer avec Koach'
                : 'Expert streetlifting (40 semaines)',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const ProgramScreen()),
            ),
          ),
          _Action(
            key: const ValueKey('settings-program-start'),
            icon: Icons.event_rounded,
            color: SL.accent,
            title: 'Départ du programme',
            subtitle: switch ((store.program.start, store.startOrigin)) {
              (null, _) => 'Non défini · choisis la date de S1 · J1',
              (final d?, 'migration') =>
                'S1 · J1 le ${longCivilDate(d)} · calendrier d’origine conservé',
              (final d?, _) => 'S1 · J1 le ${longCivilDate(d)}',
            },
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<bool>(
                builder: (_) => const ProgramStartScreen(),
              ),
            ),
          ),
          _Action(
            icon: Icons.tune_rounded,
            color: SL.accent,
            title: 'Références',
            subtitle:
                'Poids du corps, 1RM, maxima et accessoires · non renseigné accepté',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const PilotageScreen()),
            ),
          ),
          // G10 (D1.4) : Koach L7 et l'adaptation au quotidien L11 sont
          // remplacés par le moteur dynamique (Mon programme) ; leurs
          // données restent dans la sauvegarde, en lecture seule.
          const _Sec('Koach'),
          if (!store.koach.pristine || !store.adapt.pristine)
            const _Tile(
              key: ValueKey('settings-legacy-koach'),
              title: 'Ancien Koach et adaptations au quotidien',
              subtitle:
                  'Remplacés par Koach et ton programme (Mon programme : '
                  'mode assisté ou libre, historique des changements). Tes '
                  'anciennes décisions restent dans ta sauvegarde, sans être '
                  'modifiées.',
            ),
          if (store.koachLoadIssues > 0)
            _Tile(
              title: 'Données Koach partiellement relues',
              subtitle:
                  '${store.koachLoadIssues} entrée(s) illisible(s) ignorée(s) '
                  'à l’ouverture ; le reste est chargé. Ton export de '
                  'sauvegarde contient les données relues.',
            ),
          if (store.koach.answers.isNotEmpty)
            _Action(
              icon: Icons.delete_sweep_outlined,
              color: SL.accent,
              title: 'Supprimer mes réponses aux anciens questionnaires',
              subtitle:
                  '${store.koach.answers.length} séance(s) : sommeil, '
                  'forme et douleur',
              onTap: () => _clearAnswers(context),
            ),
          const _Tile(
            title: 'Confidentialité',
            subtitle:
                'Tout est calculé et conservé sur ce téléphone, sans compte '
                'ni connexion. Les données de Koach figurent dans l’export et '
                'sont effacées avec les données de l’application.',
          ),
          const _Sec('À propos'),
          _Tile(
            title: 'Kalis Track $kAppVersion',
            subtitle:
                'Programme streetlifting v3.3 · base d’exercices '
                'v${store.content.version} (${store.content.entries.length} exercices)',
          ),
          // G1 (D2.4) : visible seulement dans un build de développement.
          if (kDevBuild)
            const _Tile(
              key: ValueKey('about-dev-build'),
              title: 'Build de développement',
              subtitle:
                  'Mode dev disponible : 5 appuis sur le logo de l’accueil '
                  'ouvrent une session de test séparée de la tienne.',
            ),
          // L13 (KT-072 à KT-078) : finalité, sécurité, confidentialité,
          // retour de test.
          const DisclaimerCard(),
          KMenuTile(
            key: const ValueKey('about-safety'),
            icon: Icons.health_and_safety_outlined,
            title: 'Santé et sécurité',
            subtitle: 'Signaux d’alerte, douleur, situations particulières',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SafetyScreen()),
            ),
          ),
          KMenuTile(
            key: const ValueKey('about-recovery'),
            icon: Icons.bedtime_outlined,
            title: 'Récupération',
            subtitle: 'Sommeil, hydratation, repas, régularité',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecoveryScreen()),
            ),
          ),
          KMenuTile(
            key: const ValueKey('about-privacy'),
            icon: Icons.privacy_tip_outlined,
            title: 'Politique de confidentialité',
            subtitle: 'Données, santé, export, suppression, tes droits',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          KMenuTile(
            key: const ValueKey('about-feedback'),
            icon: Icons.rate_review_outlined,
            title: 'Donner mon avis',
            subtitle: 'Retour de test, partagé seulement si tu le choisis',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FeedbackScreen(appVersion: kAppVersion),
              ),
            ),
          ),
          KMenuTile(
            icon: Icons.menu_book_outlined,
            title: 'Sources et licences',
            subtitle: 'Fiches d’exercices, démonstrations et mannequin 3D',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MentionsScreen()),
            ),
          ),
          // M1 (mannequin 3D) : rendu test, compatibilité et fluidité.
          KMenuTile(
            key: const ValueKey('about-engine3d'),
            icon: Icons.view_in_ar_outlined,
            title: 'Moteur 3D',
            subtitle: 'Rendu test, compatibilité du téléphone et fluidité',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Engine3DScreen()),
            ),
          ),
          // M2 (mannequin 3D) : préférences de l'appareil, hors sauvegarde.
          const _Sec('Affichage 3D'),
          const _Display3D(),
        ];
        final groups = <List<Widget>>[];
        for (final item in items) {
          if (item is _Sec) groups.add(<Widget>[]);
          groups.last.add(item);
        }
        // Une entrée par section `_Sec` de `items`, dans le même ordre.
        const icons = [
          Icons.palette_outlined,
          Icons.edit_note_rounded,
          Icons.timer_outlined,
          Icons.military_tech_rounded,
          Icons.fitness_center_rounded,
          Icons.notifications_none_rounded,
          Icons.cloud_outlined,
          Icons.flag_outlined,
          Icons.insights_rounded,
          Icons.info_outline_rounded,
          Icons.view_in_ar_outlined,
        ];
        const descriptions = [
          'Couleur dominante, clair ou sombre',
          'Colonnes, effort et pré-remplissage',
          'Repos, décompte et signaux',
          'Célébrations et objectif de la semaine',
          'Écran et unités de charge',
          'Rappels et alertes',
          'Exporter, restaurer ou supprimer tes données',
          'Date de départ et références',
          'Estimations et propositions de charge',
          'Version, sécurité, confidentialité, avis',
          'Mannequin 3D : nom au toucher, os, halo',
        ];
        assert(
          groups.length == icons.length && groups.length == descriptions.length,
          'Réglages : ${groups.length} sections, ${icons.length} icônes, ${descriptions.length} descriptions',
        );
        final selected = section;
        if (selected != null) {
          final title = (groups[selected].first as _Sec).t;
          // Même grammaire que les onglets : surtitre discret, titre en page.
          return KScreen(
            appBar: AppBar(
              title: Text(
                'RÉGLAGES',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w700,
                  color: SL.dim,
                ),
              ),
            ),
            body: KList(
              children: [
                KPageIntro(title, descriptions[selected]),
                ...groups[selected].skip(1),
              ],
            ),
          );
        }
        return KScreen(
          appBar: const KTopBar(),
          body: KList(
            children: [
              const KPageIntro('Réglages', 'L’application à ta façon.'),
              ...groups.first,
              const KSection('Préférences'),
              for (var i = 1; i < groups.length; i++)
                KMenuTile(
                  icon: icons[i],
                  title: (groups[i].first as _Sec).t,
                  subtitle: descriptions[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(section: i),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'KALIS TRACK  •  $kAppVersion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SL.dim,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _import(BuildContext context) async {
    final raw = await showDialog<String>(
      context: context,
      builder: (_) => const _ImportDialog(),
    );
    if (raw == null || raw.isEmpty || !context.mounted) return;
    await confirmAndImport(context, raw, appVersion: kAppVersion);
  }
}

/// KT-036 : suppression des seules réponses aux questionnaires.
Future<void> _clearAnswers(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Supprimer tes réponses ?'),
      content: const Text(
        'Sommeil, forme et douleur de toutes les séances seront effacés. '
        'Séances, séries et valeurs de pilotage ne changent pas.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
  if (ok == true) store.clearKoachAnswers();
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog();
  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final text = TextEditingController();
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Importer une sauvegarde'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Un aperçu du contenu s’affichera avant tout remplacement de tes données.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: text,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Colle le texte exporté ici',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, text.text.trim()),
        child: const Text('Voir l’aperçu'),
      ),
    ],
  );
}

// ---------- composants uniformes (mêmes marges, mêmes hauteurs) ----------

/// Couleur dominante (L5-C) : six options nommées, choix unique. La sélection
/// se lit sans la couleur (coche, contour, graisse) ; grille de 3, 2 ou 1
/// colonnes selon la largeur et la taille du texte.
class _AccentPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  const _AccentPicker({required this.selected, required this.onSelected});

  // 2 colonnes sur téléphone (320 à 400 px), 3 sur grand écran ; 1 colonne
  // dès 150 % de texte à 320 px. Un nom tient sans coupure de mot.
  static const double _minOptionWidth = 118, _spacing = 8;

  @override
  Widget build(BuildContext context) {
    final current = KAccentSpec.byId(selected);
    final text = Theme.of(context).textTheme;
    return KCard(
      key: const ValueKey('accent-picker'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Couleur dominante', style: text.titleMedium),
          const SizedBox(height: 2),
          Text(
            '${current.label} · boutons, sélection et accents. Erreurs, '
            'validations, chronos, rangs et graphiques gardent leurs couleurs.',
            key: const ValueKey('accent-summary'),
            style: text.bodySmall,
          ),
          ValueListenableBuilder<String?>(
            valueListenable: store.persistenceError,
            builder: (context, error, _) => error == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Choix affiché, mais les réglages ne sont pas '
                      'encore enregistrés : utilise « Réessayer » dans '
                      'le message d’erreur.',
                      key: const ValueKey('accent-unsaved'),
                      style: TextStyle(color: SL.danger, fontSize: 12.5),
                    ),
                  ),
          ),
          const SizedBox(height: KSpace.gap),
          LayoutBuilder(
            builder: (context, constraints) {
              final minWidth = MediaQuery.textScalerOf(
                context,
              ).scale(_minOptionWidth);
              final columns =
                  ((constraints.maxWidth + _spacing) / (minWidth + _spacing))
                      .floor()
                      .clamp(1, 3);
              final width =
                  (constraints.maxWidth - (columns - 1) * _spacing) / columns;
              return Wrap(
                spacing: _spacing,
                runSpacing: _spacing,
                children: [
                  for (final spec in KAccentSpec.all)
                    SizedBox(
                      width: width,
                      child: _AccentOption(
                        spec: spec,
                        selected: spec.id == current.id,
                        onTap: () => onSelected(spec.id),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AccentOption extends StatelessWidget {
  final KAccentSpec spec;
  final bool selected;
  final VoidCallback onTap;
  const _AccentOption({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Semantics(
      key: ValueKey('accent-${spec.id}'),
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      selected: selected,
      label: spec.label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: SL.faint,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? SL.text : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: spec.vivid,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: SL.dim.withValues(alpha: .45),
                        width: 1,
                      ),
                    ),
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            key: ValueKey('accent-check-${spec.id}'),
                            size: 16,
                            color: spec.onVivid ?? Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      spec.label,
                      style: TextStyle(
                        color: SL.text,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Réglages › Affichage 3D (M2) : nom du muscle au toucher, os visibles,
/// halo. Tous activés par défaut.
class _Display3D extends StatelessWidget {
  const _Display3D();

  @override
  Widget build(BuildContext context) {
    final settings = Display3DSettings.instance;
    settings.load();
    return ListenableBuilder(
      listenable: settings.listenable,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Sw(
            'Nom du muscle au toucher',
            'Touche un muscle du mannequin pour lire son nom',
            settings.touchNames.value,
            (v) => settings.set(touchNames: v),
            key: const ValueKey('settings-3d-names'),
          ),
          // M6c : plus de réglage « Os visibles » (personnage à la peau
          // lisse, sans squelette affiché).
          _Sw(
            'Halo',
            'Halo flou des muscles sollicités (net si désactivé)',
            settings.halo.value,
            (v) => settings.set(halo: v),
            key: const ValueKey('settings-3d-halo'),
          ),
        ],
      ),
    );
  }
}

class _Sec extends StatelessWidget {
  final String t;
  const _Sec(this.t);
  @override
  Widget build(BuildContext context) => KSection(t);
}

class _Tile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? below, trailing;
  const _Tile({
    super.key,
    required this.title,
    this.subtitle,
    this.below,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => KCard(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final inline =
            trailing != null &&
            constraints.maxWidth >= 330 &&
            MediaQuery.textScalerOf(context).scale(14) <= 16;
        final label = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (inline)
              Row(
                children: [
                  Expanded(child: label),
                  const SizedBox(width: 12),
                  trailing!,
                ],
              )
            else
              label,
            if (trailing != null && !inline) ...[
              const SizedBox(height: KSpace.gap),
              Align(alignment: Alignment.centerRight, child: trailing!),
            ],
            if (below != null) ...[const SizedBox(height: KSpace.gap), below!],
          ],
        );
      },
    ),
  );
}

class _Sw extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Sw(this.title, this.subtitle, this.value, this.onChanged, {super.key});
  @override
  Widget build(BuildContext context) => KCard(
    padding: EdgeInsets.zero,
    child: SwitchListTile.adaptive(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: value,
      onChanged: onChanged,
    ),
  );
}

class _Stepper extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int value;
  final String unit;
  final int min, max, step;
  final ValueChanged<int> onChanged;
  const _Stepper({
    required this.title,
    this.subtitle,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => _Tile(
    title: title,
    subtitle: subtitle,
    trailing: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: value > min
              ? () => onChanged((value - step).clamp(min, max))
              : null,
          tooltip: 'Diminuer $title',
          icon: const Icon(Icons.remove),
          color: SL.accent,
        ),
        SizedBox(
          width: MediaQuery.textScalerOf(context).scale(64),
          child: Text(
            '$value\u00A0$unit',
            textAlign: TextAlign.center,
            style: KControl.numberStyle,
          ),
        ),
        IconButton(
          onPressed: value < max
              ? () => onChanged((value + step).clamp(min, max))
              : null,
          tooltip: 'Augmenter $title',
          icon: const Icon(Icons.add),
          color: SL.accent,
        ),
      ],
    ),
  );
}

class _Action extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Action destructive : bordure de la couleur d'erreur, séparée des
  /// opérations courantes.
  final bool danger;
  const _Action({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });
  @override
  Widget build(BuildContext context) => KCard(
    padding: EdgeInsets.zero,
    outline: danger ? color : null,
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}
