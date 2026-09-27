import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'session_history.dart';
import 'store.dart';
import 'ui.dart';
import 'wod_formats.dart';
import 'stats_data.dart';
import 'stats_widgets.dart';

class StatsHistory extends StatefulWidget {
  const StatsHistory({super.key});
  @override
  State<StatsHistory> createState() => _StatsHistoryState();
}

class _StatsHistoryState extends State<StatsHistory> {
  final _search = TextEditingController();
  int _filter = 0;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final all = statsHistory(store);
    final entries =
        all
            .where(
              (e) =>
                  (_filter == 0 || (_filter == 2) == e.isWod) &&
                  (query.isEmpty || e.searchText.contains(query)),
            )
            .toList();
    return KList(
      key: const PageStorageKey('stats-history-scroll'),
      children: [
        const SizedBox(height: 4),
        KWordFitText(
          'Ton journal d’entraînement',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        TextField(
          key: const ValueKey('stats-history-search'),
          controller: _search,
          decoration: InputDecoration(
            labelText: 'Rechercher dans l’historique',
            hintText: 'Séance, WOD ou note',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon:
                query.isEmpty
                    ? null
                    : IconButton(
                      tooltip: 'Effacer la recherche',
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
          ),
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final item in ['Tout', 'Séances', 'WOD'].asMap().entries)
              ChoiceChip(
                key: ValueKey('history-filter-${item.key}'),
                label: Text(item.value),
                selected: _filter == item.key,
                onSelected: (_) => setState(() => _filter = item.key),
              ),
          ],
        ),
        Text(
          '${entries.length} résultat${entries.length > 1 ? 's' : ''}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (entries.isEmpty)
          KEmpty(
            icon: Icons.history_rounded,
            title: all.isEmpty ? 'Ton histoire commence ici' : 'Aucun résultat',
            message:
                all.isEmpty
                    ? 'Tes séances terminées et tes tentatives WOD apparaîtront ici, avec leurs notes.'
                    : 'Essaie un autre mot ou un autre filtre.',
          ),
        for (final entry in entries) StatsHistoryTile(entry),
      ],
    );
  }
}

class StatsHistoryTile extends StatelessWidget {
  final StatsHistoryEntry entry;
  final bool record;
  const StatsHistoryTile(this.entry, {super.key, this.record = false});
  @override
  Widget build(BuildContext context) {
    final date = entry.at;
    final when =
        date == null
            ? 'Date non renseignée'
            : '${statsDate(date)}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final noteCount =
        entry.session?.ex.values
            .where((e) => e.note.trim().isNotEmpty)
            .length ??
        0;
    final detail =
        entry.isWod
            ? '${entry.result!.completed ? 'WOD terminé' : 'Tentative WOD'} · ${entry.result!.score}'
            : 'Séance terminée${noteCount == 0 ? '' : ' · $noteCount note${noteCount > 1 ? 's' : ''}'}';
    return KCard(
      key: ValueKey('stats-log-${entry.id}'),
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading:
            record
                ? CircleAvatar(
                  backgroundColor: SL.action,
                  foregroundColor: SL.onActionSoft,
                  child: const Icon(Icons.emoji_events_outlined),
                )
                : Icon(
                  entry.isWod ? Icons.bolt_rounded : Icons.task_alt_rounded,
                  color: entry.result?.completed == false ? SL.dim : SL.success,
                ),
        title: Text(entry.title),
        subtitle: Text('$when\n$detail'),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: () {
          if (!entry.isWod) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => SessionHistoryScreen(
                      log: entry.session!,
                      sessionKey: entry.id,
                    ),
              ),
            );
          } else {
            final result = entry.result!;
            statsSheet(context, entry.title, [
              Text(when, style: Theme.of(context).textTheme.bodySmall),
              KBadge(
                result.completed ? 'Terminé' : 'Tentative inachevée',
                color: result.completed ? SL.success : SL.dim,
              ),
              Text(
                result.score,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              for (final line in resultDetails(entry.wod!, result)) Text(line),
              const KSection('Notes'),
              Text(
                result.notes.trim().isEmpty
                    ? 'Aucune note pour ce résultat.'
                    : result.notes,
              ),
            ]);
          }
        },
      ),
    );
  }
}
