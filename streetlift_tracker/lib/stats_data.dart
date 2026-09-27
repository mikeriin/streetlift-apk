import 'store.dart';
import 'wod_models.dart';

/// Vue en lecture seule : toutes les séances terminées et toutes les tentatives WOD.
class StatsHistoryEntry {
  final String id, title, searchText;
  final DateTime? at;
  final SessionLog? session;
  final Wod? wod;
  final WodResult? result;
  const StatsHistoryEntry({
    required this.id,
    required this.title,
    required this.searchText,
    this.at,
    this.session,
    this.wod,
    this.result,
  });
  bool get isWod => result != null;
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
        searchText:
            '$title ${log.ex.values.map((e) => e.note).join(' ')}'
                .toLowerCase(),
        at: DateTime.tryParse(log.finishedAt ?? '')?.toLocal(),
        session: log,
      ),
    );
  }
  for (final wod in source.wods) {
    for (var i = 0; i < wod.results.length; i++) {
      final result = wod.results[i];
      entries.add(
        StatsHistoryEntry(
          id: 'wod:${wod.id}:$i',
          title: wod.name,
          searchText:
              '${wod.name} ${result.score} ${result.notes}'.toLowerCase(),
          at: DateTime.tryParse(result.at)?.toLocal(),
          wod: wod,
          result: result,
        ),
      );
    }
  }
  entries.sort((a, b) {
    if (a.at == null && b.at != null) return 1;
    if (b.at == null && a.at != null) return -1;
    final date = a.at == null ? 0 : b.at!.compareTo(a.at!);
    return date != 0 ? date : a.id.compareTo(b.id);
  });
  return entries;
}
