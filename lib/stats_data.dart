import 'search.dart' show normalizeText;
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

/// Titres posés par l'application pour une journée du programme
/// (« S3 · J2 », « S3 (ancien) · J2 ») : numéros d'une numérotation qui a pu
/// changer depuis (PR2).
final _autoTitle = RegExp(r'^S\d+(?: \(ancien\))? · J\d+$');
final _programKey = RegExp(r'^S(\d+)-J(\d+)$');

/// RV2 (H5, P5) : titre d'une séance de l'historique. Une journée du
/// programme sans titre, ou au titre posé par l'application, prend le
/// libellé de la numérotation affichée (PR2 : « S1 · J2 », « S12 (ancien) ·
/// J2 » avant la première semaine affichée). Avant : « S15 · J2 » (numéro
/// interne) ou, pour une séance de l'ancien programme, « S3 · J2 », confondu
/// avec la semaine 3 affichée. Un titre choisi ailleurs reste tel quel.
String historyTitle(AppStore source, String key, String? title) {
  final m = _programKey.firstMatch(key);
  if (m != null && (title == null || _autoTitle.hasMatch(title))) {
    final n = int.parse(m[1]!), j = int.parse(m[2]!);
    if (n >= 1 && source.program.weeks.any((w) => w.n == n)) {
      return source.program.sessionLabel(n, j);
    }
  }
  return title ?? key.replaceAll('-', ' · ');
}

List<StatsHistoryEntry> statsHistory(AppStore source) {
  final entries = <StatsHistoryEntry>[];
  for (final item in source.logs.entries.where((entry) => entry.value.done)) {
    final log = item.value;
    final title = historyTitle(source, item.key, log.title);
    entries.add(
      StatsHistoryEntry(
        id: item.key,
        title: title,
        // RV1 : sans accents ni casse (« epaule » trouve « épaule »).
        searchText: normalizeText(
          '$title ${log.ex.values.map((e) => e.note).join(' ')}',
        ),
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
