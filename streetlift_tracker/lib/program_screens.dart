// Écrans du programme personnalisé (L10, KT-050 à KT-057) : « Mon
// programme » (modèle et explication, niveaux par mouvement, répartition,
// volume, régénération), aperçu « ce qui change » avant validation,
// annulation pendant 7 jours, carte de l'accueil quand le profil a changé.
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'program_generator.dart';
import 'profile_screens.dart' show ProfileScreen;
import 'store.dart';
import 'ui.dart';

const _sourceLabels = {
  'measured': 'mesuré',
  'estimated': 'estimé',
  'calibrated': 'calibrage',
  'default': 'par défaut',
};

const _splitChoices = [
  ('auto', 'Koach décide'),
  ('fullbody', 'Corps entier'),
  ('upper_lower', 'Haut / bas'),
  ('ppl', 'Poussée / tirage / jambes'),
];

const _focusChoices = [
  ('pullups', 'Tractions'),
  ('pushups', 'Pompes'),
  ('dips', 'Dips'),
  ('squats', 'Squats'),
];

const _weekdayNames = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];

const _templateExplain =
    'Le programme de 40 semaines du créateur de Kalis Track (v3.3, révisions '
    'LC1 comprises), repris à l’identique : blocs, décharges et tests.';

/// Ouvre l'aperçu d'une (ré)génération, puis l'applique si l'utilisateur
/// valide. Renvoie vrai si le programme a changé.
Future<bool> openProgramProposal(
  BuildContext context, {
  String reason = 'user',
  Map<String, String>? options,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  ProgramProposal? proposal;
  try {
    proposal = await store.proposeProgram(reason: reason, options: options);
  } catch (_) {
    proposal = null;
  }
  if (proposal == null) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Génération impossible : profil incomplet ou contenu illisible.',
        ),
      ),
    );
    return false;
  }
  final ok = await navigator.push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => ProgramPreviewScreen(proposal: proposal!),
    ),
  );
  if (ok != true) return false;
  store.applyProgram(proposal);
  messenger.showSnackBar(
    const SnackBar(content: Text('Programme mis à jour à partir d’aujourd’hui.')),
  );
  return true;
}

class ProgramScreen extends StatelessWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final inst = store.programInstance;
      final generated = inst?.generated ?? false;
      final opts = inst?.options ?? const <String, String>{};
      final summary = store.programSummary;
      final dim = Theme.of(context).textTheme.bodySmall;
      final children = <Widget>[
        KCard(
          key: const ValueKey('program-model'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                (summary['modelLabel'] as String?) ??
                    'Expert streetlifting (40 semaines)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text((summary['explanation'] as String?) ?? _templateExplain),
              const SizedBox(height: 6),
              Text(
                generated
                    ? '${inst!.weeks.length} semaines · cycle ${inst.cycle + 1}'
                        '${summary['eventDate'] != null ? ' · épreuve le ${_date(summary['eventDate'] as String)}' : ''}'
                    : 'Programme embarqué, inchangé',
                style: dim,
              ),
            ],
          ),
        ),
      ];
      if (ProgramHomeCard.visible) {
        children.add(const ProgramHomeCard(inScreen: true));
      }
      if (store.profile == null) {
        children.add(
          KCard(
            key: const ValueKey('program-no-profile'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Crée ton profil pour obtenir un programme personnalisé : '
                  'objectifs, disponibilités, lieux et matériel.',
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                  child: const Text('Mon profil'),
                ),
              ],
            ),
          ),
        );
      }
      if (generated) {
        final levels = summary['levels'] as Map?;
        final movements = (levels?['movements'] as Map?) ?? const {};
        children.add(const KSection('Niveau par mouvement'));
        children.add(
          KCard(
            key: const ValueKey('program-levels'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final mv in kRefMovements)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      '${kRefMovementLabels[mv]} : '
                      '${_levelLabel((movements[mv] as Map?)?['level'] as int?)}'
                      ' (${_sourceLabels[(movements[mv] as Map?)?['source']] ?? '—'})',
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  'Ce repère sert seulement à choisir la périodisation et les '
                  'valeurs de départ, jamais à te juger.',
                  style: dim,
                ),
              ],
            ),
          ),
        );
        children.add(const KSection('Répartition de la semaine'));
        final kinds = (summary['kinds'] as List?)?.cast<String>() ?? const [];
        final days = (summary['weekdays'] as List?)?.cast<int>() ?? const [];
        children.add(
          KCard(
            key: const ValueKey('program-split'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${summary['splitLabel'] ?? ''}'),
                const SizedBox(height: 4),
                Text(
                  [
                    for (var k = 0; k < days.length && k < kinds.length; k++)
                      '${_weekdayNames[days[k] - 1]} ${kKindTitles[kinds[k]]?.toLowerCase() ?? ''}',
                  ].join(' · '),
                  style: dim,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (id, label) in _splitChoices)
                      ChoiceChip(
                        key: ValueKey('program-split-$id'),
                        label: Text(label),
                        selected: (opts['split'] ?? 'auto') == id,
                        onSelected:
                            (_) => openProgramProposal(
                              context,
                              options: {...opts, 'split': id},
                            ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
        final goal = store.profile?.stringValue('goalPrimary');
        final second = store.profile?.stringValue('goalSecondary');
        if (goal == 'endurance' || second == 'endurance') {
          children.add(const KSection('Mouvement ciblé (endurance)'));
          children.add(
            KCard(
              key: const ValueKey('program-focus'),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (id, label) in _focusChoices)
                    ChoiceChip(
                      key: ValueKey('program-focus-$id'),
                      label: Text(label),
                      selected: opts['focus'] == id,
                      onSelected:
                          (_) => openProgramProposal(
                            context,
                            options: {...opts, 'focus': id},
                          ),
                    ),
                ],
              ),
            ),
          );
        }
        children.add(const KSection('Séries difficiles par semaine'));
        children.add(_VolumeCard(summary: summary));
      }
      if (store.profile != null) {
        children.add(
          FilledButton.icon(
            key: const ValueKey('program-generate'),
            icon: const Icon(Icons.auto_awesome_outlined),
            label: Text(
              generated
                  ? 'Régénérer la suite à partir d’aujourd’hui'
                  : 'Générer mon programme personnalisé',
            ),
            onPressed: () => openProgramProposal(context),
          ),
        );
        children.add(
          Text(
            'Ton historique n’est jamais modifié : seules les séances à '
            'venir changent, après un aperçu.',
            style: dim,
          ),
        );
      }
      return KScreen(
        appBar: AppBar(title: const Text('MON PROGRAMME')),
        body: KList(key: const ValueKey('program-list'), children: children),
      );
    },
  );
}

String _levelLabel(int? level) {
  const labels = ['débutant', 'novice', 'intermédiaire', 'avancé', 'expert'];
  if (level == null || level < 0 || level > 4) return '—';
  return labels[level];
}

String _date(String iso) {
  final d = parseCivil(iso);
  if (d == null) return iso;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}';
}

class _VolumeCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _VolumeCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final targets = (summary['targets'] as Map?)?.cast<String, dynamic>() ?? {};
    final weeks = (summary['weekVolumes'] as List?) ?? const [];
    final firstLoad = weeks.cast<Map>().where((w) => w['kind'] == 'load');
    final groups =
        firstLoad.isEmpty
            ? const <String, dynamic>{}
            : (firstLoad.first['groups'] as Map).cast<String, dynamic>();
    final dim = Theme.of(context).textTheme.bodySmall;
    final keys = targets.keys.toList();
    return KCard(
      key: const ValueKey('program-volume'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final g in keys)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '$g : ${groups[g] ?? 0} séries (repère ${targets[g]})',
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'Plafond : ${summary['ceiling'] ?? '—'} séries par groupe. Koach '
            'ajuste de ±2 séries par cycle selon ta progression.',
            style: dim,
          ),
        ],
      ),
    );
  }
}

/// Aperçu « ce qui change » : rien n'est appliqué sans validation.
class ProgramPreviewScreen extends StatelessWidget {
  final ProgramProposal proposal;
  const ProgramPreviewScreen({super.key, required this.proposal});

  @override
  Widget build(BuildContext context) {
    final d = proposal.diff;
    final dim = Theme.of(context).textTheme.bodySmall;
    final s = proposal.instance.summary;
    final children = <Widget>[
      KCard(
        key: const ValueKey('preview-model'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${s['modelLabel'] ?? d.modelAfter}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text('${s['explanation'] ?? ''}'),
            const SizedBox(height: 6),
            Text(
              proposal.from.week == 1 && proposal.from.day == 1
                  ? 'À partir du départ du programme.'
                  : 'À partir d’aujourd’hui (S${proposal.from.week} · J${proposal.from.day}). Les séances passées ne changent pas.',
              style: dim,
            ),
          ],
        ),
      ),
      const KSection('Ce qui change'),
      KCard(
        key: const ValueKey('preview-summary'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Séances par semaine : ${d.sessionsBefore} → ${d.sessionsAfter}'),
            Text('Durée moyenne estimée : ${d.minutesBefore} → ${d.minutesAfter} min'),
            if (d.modelBefore != d.modelAfter)
              Text('Périodisation : ${d.modelBefore} → ${d.modelAfter}'),
            if (d.volume.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Séries difficiles par groupe (semaine type) :', style: dim),
              for (final e in d.volume.entries)
                Text('${e.key} : ${e.value.$1} → ${e.value.$2}'),
            ],
          ],
        ),
      ),
      for (final w in d.weeks)
        KCard(
          key: ValueKey('preview-week-${w.week}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Semaine ${w.week}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              if (w.lines.isEmpty)
                Text('Aucun changement', style: dim)
              else
                for (final l in w.lines) Text(l),
            ],
          ),
        ),
      FilledButton(
        key: const ValueKey('preview-apply'),
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Appliquer'),
      ),
      OutlinedButton(
        key: const ValueKey('preview-cancel'),
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Garder mon programme actuel'),
      ),
    ];
    return KScreen(
      appBar: AppBar(title: const Text('CE QUI CHANGE')),
      body: KList(key: const ValueKey('preview-list'), children: children),
    );
  }
}

/// Carte « profil modifié » ou « programme mis à jour, annulable » (accueil
/// et Mon programme).
class ProgramHomeCard extends StatelessWidget {
  final bool inScreen;
  const ProgramHomeCard({super.key, this.inScreen = false});

  static bool get visible =>
      store.programProfileChanged || store.programCanUndo;

  @override
  Widget build(BuildContext context) {
    final changed = store.programProfileChanged;
    final undo = store.programCanUndo;
    if (!changed && !undo) return const SizedBox.shrink();
    return KCard(
      key: const ValueKey('program-home-card'),
      accent: SL.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            changed
                ? 'Ton profil a changé : ton programme peut être adapté à '
                    'partir d’aujourd’hui.'
                : 'Ton programme a été mis à jour. Tu peux revenir à la '
                    'version précédente pendant 7 jours.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (changed)
                FilledButton(
                  key: const ValueKey('program-home-preview'),
                  onPressed:
                      () => openProgramProposal(context, reason: 'profile'),
                  child: const Text('Voir ce qui change'),
                ),
              if (undo)
                OutlinedButton(
                  key: const ValueKey('program-home-undo'),
                  onPressed: () {
                    final ok = store.undoProgram();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Version précédente du programme rétablie.'
                              : 'Annulation impossible : une séance du nouveau programme est déjà commencée.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Revenir à la version précédente'),
                ),
              if (!inScreen)
                TextButton(
                  key: const ValueKey('program-home-open'),
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const ProgramScreen(),
                        ),
                      ),
                  child: const Text('Mon programme'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
