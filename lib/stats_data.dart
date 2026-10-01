import 'store.dart';

/// Vue en lecture seule : toutes les séances terminées.
class StatsHistoryEntry {
  final String id, title, searchText;
  final DateTime? at;
  final SessionLog session;
  const StatsHistoryEntry({
    required this.id,
    required this.title,
    required this.searchText,
    required this.session,
    this.at,
  });
}

List<StatsHistoryEntry> statsHistory(AppStore source) {
  final entries = <StatsHistoryEntry>[];
  for (final item in source.logs.entries.where((entry) => entry.value.done)) {
    final log = item.value;
    final title = log.title ?? item.key.replaceAll('-', ' · ');
    entries.add(
      StatsHistoryEntry(
        id: item.key,
        title: title,
        searchText: '$title ${log.ex.values.map((e) => e.note).join(' ')}'
            .toLowerCase(),
        at: DateTime.tryParse(log.finishedAt ?? '')?.toLocal(),
        session: log,
      ),
    );
  }
  entries.sort((a, b) {
    if (a.at == null && b.at != null) return 1;
    if (b.at == null && a.at != null) return -1;
    final date = a.at == null ? 0 : b.at!.compareTo(a.at!);
    return date != 0 ? date : a.id.compareTo(b.id);
  });
  return entries;
}
