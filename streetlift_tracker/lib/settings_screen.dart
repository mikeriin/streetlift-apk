import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'ui.dart';
import 'notifications.dart';
import 'notification_settings.dart';
import 'store.dart';

const kAppVersion = '2.5.1';

class SettingsScreen extends StatelessWidget {
  final int? section;
  const SettingsScreen({super.key, this.section});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final s = store.settings;
        void save() => store.saveSettings();
        final items = <Widget>[
          const _Sec('Apparence'),
          _Tile(
            title: 'Thème',
            subtitle: switch (s.theme) {
              'light' => 'Clair : fond blanc cassé, bordeaux conservé',
              'system' => 'Système : suit le thème du téléphone',
              _ => 'Sombre : anthracite et bordeaux, lisible en extérieur',
            },
            below: SegmentedButton<String>(
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
          const _Sec('Saisie des séries'),
          _Sw(
            'Colonne RIR / RPE par défaut',
            'Ajustable avec le menu Colonnes sous chaque exercice',
            s.trackRir,
            (v) {
              s.trackRir = v;
              save();
            },
          ),
          _Sw(
            'Colonne vitesse (m/s) sur les lifts',
            'Pour suivre la vitesse de tes répétitions',
            s.trackVelocity,
            (v) {
              s.trackVelocity = v;
              save();
            },
          ),
          _Sw('Échelle RPE au lieu de RIR', null, s.rpe, (v) {
            s.rpe = v;
            save();
          }),
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
            'Écran de récompenses après une séance ou un WOD, records en direct, cérémonie de niveau',
            s.celebrations,
            (v) {
              s.celebrations = v;
              save();
            },
          ),
          _Stepper(
            title: 'Objectif de jours actifs par semaine',
            subtitle:
                s.weeklyGoal == 0
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
            'Pendant l\u2019exécution d\u2019une séance ou d\u2019un WOD',
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
            icon: Icons.upload_rounded,
            color: SL.accent,
            title: 'Exporter une sauvegarde',
            subtitle:
                'Copie tout (pilotage, journal, séances, WODs, réglages) dans le presse-papiers',
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
            icon: Icons.download_rounded,
            color: SL.accent,
            title: 'Importer une sauvegarde',
            subtitle: 'Remplace les données actuelles par un export collé',
            onTap: () => _import(context),
          ),
          const _Sec('À propos'),
          _Tile(
            title: 'Kalis Track $kAppVersion',
            subtitle:
                'Programme streetlifting v3.3 · ${store.allExercises.length} exercices · ${execModes.length} modes · ${store.wods.length} WODs',
          ),
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
          Icons.info_outline_rounded,
        ];
        const descriptions = [
          'Bordeaux, clair ou sombre',
          'Colonnes, effort et pré-remplissage',
          'Repos, décompte et signaux',
          'Célébrations et objectif de la semaine',
          'Écran et unités de charge',
          'Rappels et alertes',
          'Exporter ou retrouver tes données',
          'Version et contenu du programme',
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
                  onTap:
                      () => Navigator.push(
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
    if (raw == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await store.importAll(raw);
    if (ok) await Notif.reschedule();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Import réussi.'
              : 'Import impossible : sauvegarde invalide ou écriture refusée. Les données actuelles sont conservées.',
        ),
      ),
    );
  }
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
            'Cette sauvegarde remplacera les données actuelles. Exporte-les d’abord si tu veux les conserver.',
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
        child: const Text('Importer'),
      ),
    ],
  );
}

// ---------- composants uniformes (mêmes marges, mêmes hauteurs) ----------

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
  const _Tile({required this.title, this.subtitle, this.below, this.trailing});
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
  const _Sw(this.title, this.subtitle, this.value, this.onChanged);
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
          onPressed:
              value > min
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
          onPressed:
              value < max
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
  const _Action({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => KCard(
    padding: EdgeInsets.zero,
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}
