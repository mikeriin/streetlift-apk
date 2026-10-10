// UI3 (refonte UI, U12) : page « Records », ouverte par Stats ›
// Performances › Records. Elle lit les meilleures performances que l'appli
// calcule déjà pour les récompenses de fin de séance (`exerciseBests`,
// game.dart) : aucun calcul nouveau, aucune donnée enregistrée. Seule la
// date du premier passage du record est cherchée ici, pour l'affichage.
import 'package:flutter/material.dart';

import 'game.dart';
import 'kit/kit.dart';
import 'search.dart' show normalizeText;
import 'store.dart';
import 'store_widget.dart';
import 'stats_widgets.dart';

/// Meilleures performances d'un exercice.
class StatsRecord {
  final String name;
  final ExerciseBests bests;
  final DateTime? weightedAt, repsAt;
  const StatsRecord(this.name, this.bests, {this.weightedAt, this.repsAt});
  bool get weighted => bests.weightedSets > 0 && bests.bestE1rm > 0;
  bool get bodyweight => bests.bodyweightSets > 0 && bests.bestReps > 0;
}

/// Records de tout le journal, par exercice (ordre alphabétique).
List<StatsRecord> statsRecords(AppStore source) {
  final bests = exerciseBests(source.logs);
  final names = <String, String>{};
  final weightedAt = <String, DateTime>{};
  final repsAt = <String, DateTime>{};
  void earliest(Map<String, DateTime> into, String key, DateTime? at) {
    if (at == null) return;
    final known = into[key];
    if (known == null || at.isBefore(known)) into[key] = at;
  }

  for (final log in source.logs.values) {
    final at = DateTime.tryParse(log.finishedAt ?? '')?.toLocal();
    for (final ex in log.ex.entries) {
      final name = log.exerciseNames[ex.key];
      if (name == null || name.isEmpty) continue;
      final key = normalizeText(name);
      final best = bests[key];
      if (best == null) continue;
      names.putIfAbsent(key, () => name);
      for (final set in ex.value.sets.where((s) => s.done)) {
        final kg = double.tryParse(set.kg.trim().replaceAll(',', '.')) ?? 0;
        final reps = int.tryParse(set.reps.trim()) ?? 0;
        if (reps <= 0) continue;
        if (kg > 0) {
          if (kg == best.bestKg && reps == best.bestKgReps) {
            earliest(weightedAt, key, at);
          }
        } else if (reps == best.bestReps) {
          earliest(repsAt, key, at);
        }
      }
    }
  }
  final out = [
    for (final e in names.entries)
      StatsRecord(
        e.value,
        bests[e.key]!,
        weightedAt: weightedAt[e.key],
        repsAt: repsAt[e.key],
      ),
  ]..removeWhere((r) => !r.weighted && !r.bodyweight);
  out.sort((a, b) => normalizeText(a.name).compareTo(normalizeText(b.name)));
  return out;
}

String _on(DateTime? at) => at == null
    ? ''
    : ' · le ${statsDate(at)}/${at.year}';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) => StoreBuilder(
    builder: (context) {
      final k = KTokens.of(context);
      final records = statsRecords(store);
      final weighted = records.where((r) => r.weighted).toList();
      final bodyweight = records.where((r) => r.bodyweight).toList();
      Widget icon() =>
          KIconTile(Icons.emoji_events_outlined, color: k.accent);
      return KPage.sub(
        title: 'Records',
        lead:
            'Tes meilleures séries, exercice par exercice, calculées depuis ton journal.',
        children: [
          if (records.isEmpty)
            const KEmpty(
              icon: Icons.emoji_events_outlined,
              title: 'Aucun record pour l’instant',
              message:
                  'Valide des séries avec une charge ou des répétitions : tes meilleures performances s’afficheront ici.',
            ),
          if (weighted.isNotEmpty)
            KMenuGroup(
              key: const ValueKey('records-weighted'),
              title: 'Avec charge',
              children: [
                for (final r in weighted)
                  KMenuRow(
                    key: ValueKey('record-kg-${normalizeText(r.name)}'),
                    leading: icon(),
                    title: r.name,
                    subtitle:
                        '${statsNumber(r.bests.bestKg)} kg × ${r.bests.bestKgReps} · 1RM estimé ${statsNumber(r.bests.bestE1rm)} kg${_on(r.weightedAt)}',
                  ),
              ],
            ),
          if (bodyweight.isNotEmpty)
            KMenuGroup(
              key: const ValueKey('records-bodyweight'),
              title: 'Au poids de corps',
              children: [
                for (final r in bodyweight)
                  KMenuRow(
                    key: ValueKey('record-reps-${normalizeText(r.name)}'),
                    leading: icon(),
                    title: r.name,
                    subtitle:
                        '${r.bests.bestReps} répétitions en une série${_on(r.repsAt)}',
                  ),
              ],
            ),
          if (weighted.isNotEmpty)
            const StatsText(
              '1RM estimé : charge × (1 + répétitions ÷ 30), la formule d’Epley qui annonce aussi les records en séance.',
              muted: true,
            ),
        ],
      );
    },
  );
}
