import 'package:flutter/material.dart';
import 'kit/kit.dart';
import 'session_history.dart';
import 'store.dart';
import 'stats_data.dart';
import 'stats_widgets.dart';

const _months = [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
];

/// « Octobre 2026 ».
String statsMonth(DateTime d) {
  return '${_months[d.month - 1]} ${d.year}';
}

/// Historique (UI3, cahier §4.1) : recherche, puis les séances terminées
/// groupées par mois (la plus récente en tête) ; une séance ouvre sa
/// relecture (⋮ « Corriger les saisies », « Supprimer de l'historique »).
class StatsHistory extends StatefulWidget {
  const StatsHistory({super.key});
  @override
  State<StatsHistory> createState() => _StatsHistoryState();
}

class _StatsHistoryState extends State<StatsHistory> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final query = _search.text.trim().toLowerCase();
    final all = statsHistory(store);
    final entries = all
        .where((e) => query.isEmpty || e.searchText.contains(query))
        .toList();
    // Groupes par mois, dans l'ordre du journal ; les séances sans date
    // forment le dernier groupe.
    final groups = <String, List<StatsHistoryEntry>>{};
    for (final e in entries) {
      final key = e.at == null ? 'Date non renseignée' : statsMonth(e.at!);
      groups.putIfAbsent(key, () => []).add(e);
    }
    return StatsList(
      key: const PageStorageKey('stats-history-scroll'),
      children: [
        const StatsIntro('Ton journal d’entraînement'),
        KSearchField(
          key: const ValueKey('stats-history-search'),
          controller: _search,
          hint: 'Rechercher une séance ou une note',
          onChanged: (_) => setState(() {}),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KSpacing.s4),
          child: Semantics(
            liveRegion: true,
            child: Text(
              '${entries.length} résultat${entries.length > 1 ? 's' : ''}',
              style: KType.detail.copyWith(color: k.texte2),
            ),
          ),
        ),
        if (entries.isEmpty)
          KEmpty(
            icon: Icons.history_rounded,
            title: all.isEmpty ? 'Ton histoire commence ici' : 'Aucun résultat',
            message: all.isEmpty
                ? 'Tes séances terminées apparaîtront ici, avec leurs notes.'
                : 'Essaie un autre mot.',
          ),
        for (final g in groups.entries)
          KMenuGroup(
            title: g.key,
            children: [for (final entry in g.value) StatsHistoryTile(entry)],
          ),
      ],
    );
  }
}

/// Ligne d'une séance terminée : titre, date et heure, notes ; ouvre la
/// relecture de la séance.
class StatsHistoryTile extends StatelessWidget {
  final StatsHistoryEntry entry;
  const StatsHistoryTile(this.entry, {super.key});
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final date = entry.at;
    final when = date == null
        ? 'Date non renseignée'
        : '${statsDate(date)}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final noteCount = entry.session.ex.values
        .where((e) => e.note.trim().isNotEmpty)
        .length;
    final detail =
        'Séance terminée${noteCount == 0 ? '' : ' · $noteCount note${noteCount > 1 ? 's' : ''}'}';
    return KMenuRow(
      key: ValueKey('stats-log-${entry.id}'),
      leading: KIconTile(Icons.task_alt_rounded, color: k.validation),
      title: entry.title,
      subtitle: '$when\n$detail',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SessionHistoryScreen(log: entry.session, sessionKey: entry.id),
        ),
      ),
    );
  }
}
