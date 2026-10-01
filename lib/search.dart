// Recherche plein texte tolérante du sélecteur d'exercices : minuscules, sans accents, plusieurs termes (tous
// requis), synonymes français / anglais des mouvements, préfixes et classement
// par pertinence. Aucune donnée persistée : tout se recalcule à la volée.

const _accents = <String, String>{
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'á': 'a',
  'ã': 'a',
  'å': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'î': 'i',
  'ï': 'i',
  'í': 'i',
  'ì': 'i',
  'ô': 'o',
  'ö': 'o',
  'ó': 'o',
  'ò': 'o',
  'õ': 'o',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ú': 'u',
  'ç': 'c',
  'ñ': 'n',
  'ÿ': 'y',
  'œ': 'oe',
  'æ': 'ae',
  '×': 'x',
  '’': ' ',
  '\'': ' ',
};

/// Minuscules, sans accents, ponctuation remplacée par des espaces. Les tirets
/// sont conservés pour retrouver « 21-15-9 » ou « pull-up » tels quels.
String normalizeText(String s) {
  final b = StringBuffer();
  var pendingSpace = false;
  var empty = true;
  for (final rune in s.toLowerCase().runes) {
    final raw = String.fromCharCode(rune);
    final mapped = _accents[raw] ?? raw;
    for (final c in mapped.split('')) {
      final code = c.codeUnitAt(0);
      final keep =
          (code >= 0x30 && code <= 0x39) ||
          (code >= 0x61 && code <= 0x7a) ||
          c == '-';
      if (keep) {
        if (pendingSpace && !empty) b.write(' ');
        pendingSpace = false;
        b.write(c);
        empty = false;
      } else {
        pendingSpace = true;
      }
    }
  }
  return b.toString();
}

/// Familles de synonymes (déjà normalisées). Un terme qui vaut ou commence
/// une entrée s'étend à toute la famille : « trac » trouve aussi « pull-ups ».
const synonymFamilies = <List<String>>[
  [
    'traction',
    'tractions',
    'pull-up',
    'pull-ups',
    'pullup',
    'pullups',
    'chin-up',
    'chin-ups',
    'chinup',
    'chest-to-bar',
    'c2b',
  ],
  ['pompe', 'pompes', 'push-up', 'push-ups', 'pushup', 'pushups'],
  ['dip', 'dips'],
  ['muscle-up', 'muscle-ups', 'muscleup', 'muscleups', 'mu'],
  ['squat', 'squats', 'air squat', 'pistol', 'pistols', 'goblet'],
  ['fente', 'fentes', 'lunge', 'lunges'],
  ['burpee', 'burpees'],
  [
    'abdo',
    'abdos',
    'abdominaux',
    'gainage',
    'core',
    'sit-up',
    'sit-ups',
    'situp',
    'situps',
    'crunch',
    'crunchs',
    'v-up',
    'v-ups',
    'hollow',
    'plank',
    'planche',
    'toes-to-bar',
    't2b',
    'leg raise',
    'leg raises',
    'dragon',
  ],
  ['course', 'courir', 'run', 'running', 'footing', 'sprint', 'km'],
  ['rameur', 'row', 'rowing', 'erg', 'skierg', 'ski', 'bike', 'velo', 'cal'],
  ['corde', 'double-under', 'double-unders', 'du', 'jump rope', 'skipping'],
  ['hspu', 'handstand', 'atr', 'pike', 'wall walk', 'wall walks'],
  [
    'kettlebell',
    'kb',
    'swing',
    'swings',
    'wall ball',
    'wall balls',
    'thruster',
    'devil press',
    'sandbag',
    'farmer',
    'carry',
  ],
  ['leste', 'lestee', 'lestes', 'lestees', 'weighted', 'gilet', 'kg'],
  ['box', 'box jump', 'box jumps', 'step-up', 'step-ups', 'step-over'],
  [
    'skill',
    'skills',
    'front lever',
    'back lever',
    'planche',
    'flag',
    'drapeau',
    'l-sit',
    'v-sit',
  ],
  ['biceps', 'curl', 'curls'],
  ['triceps', 'extension', 'extensions', 'kickback'],
  [
    'epaule',
    'epaules',
    'shoulder',
    'shoulders',
    'developpe',
    'press',
    'elevation',
    'elevations',
  ],
  ['dos', 'back', 'tirage', 'tirages', 'rowing', 'rows', 'row'],
  [
    'jambe',
    'jambes',
    'legs',
    'quadriceps',
    'quads',
    'fessier',
    'fessiers',
    'glutes',
    'ischios',
    'hamstrings',
  ],
  ['mollet', 'mollets', 'calf', 'calves'],
  [
    'avant-bras',
    'forearm',
    'grip',
    'poignet',
    'poignets',
    'wrist',
    'hang',
    'dead-hang',
  ],
  ['cardio', 'conditionnement', 'metcon', 'hiit', 'tabata', 'intervalles'],
  [
    'mobilite',
    'mobility',
    'etirement',
    'etirements',
    'stretching',
    'recuperation',
    'recovery',
    'prevention',
  ],
  ['amrap', 'as many'],
  ['emom', 'every minute', 'e2mom'],
  ['for time', 'fortime', 'chrono', 'chipper'],
  ['round', 'rounds', 'tour', 'tours'],
  ['echelle', 'ladder', 'pyramide', 'pyramid'],
  ['death by', 'deathby'],
  ['partner', 'binome', 'team', 'equipe'],
];

/// Requête analysée : chaque terme doit être trouvé (dans une forme étendue par
/// ses synonymes) ; `score` classe les résultats par pertinence.
class SearchQuery {
  final String raw;
  final List<String> tokens;
  final List<List<String>> expansions;

  SearchQuery._(this.raw, this.tokens, this.expansions);

  factory SearchQuery(String input) {
    final norm = normalizeText(input);
    final tokens = norm.split(' ').where((t) => t.isNotEmpty).toList();
    final expansions = <List<String>>[];
    for (final t in tokens) {
      final exp = <String>{t};
      for (final family in synonymFamilies) {
        final hit = family.any(
          (v) => v == t || (t.length >= 3 && v.startsWith(t)),
        );
        if (hit) exp.addAll(family);
      }
      expansions.add(exp.toList());
    }
    return SearchQuery._(norm, tokens, expansions);
  }

  bool get isEmpty => tokens.isEmpty;

  bool _hit(String text, List<String> exp) {
    for (final v in exp) {
      if (text.contains(v)) return true;
    }
    return false;
  }

  /// Vrai si tous les termes apparaissent dans le texte normalisé.
  bool matches(String normalizedText) {
    for (final exp in expansions) {
      if (!_hit(normalizedText, exp)) return false;
    }
    return true;
  }

  /// Score de pertinence d'un document découpé en champs pondérés :
  /// titre 3 · métadonnées 2 · corps 1 · notes 0,5, plus une prime quand la
  /// requête entière figure dans le titre.
  double score(SearchDoc d) {
    if (isEmpty) return 0;
    var s = 0.0;
    for (final exp in expansions) {
      if (_hit(d.name, exp)) {
        s += 3;
      } else if (_hit(d.meta, exp)) {
        s += 2;
      } else if (_hit(d.body, exp)) {
        s += 1;
      } else if (_hit(d.notes, exp)) {
        s += .5;
      }
    }
    if (raw.isNotEmpty && d.name.contains(raw)) {
      s += d.name.startsWith(raw) ? 3 : 2;
    }
    return s;
  }
}

/// Document indexé : quatre champs normalisés et leur concaténation.
class SearchDoc {
  final String name, meta, body, notes, all;
  SearchDoc({
    required String name,
    String meta = '',
    String body = '',
    String notes = '',
  }) : name = normalizeText(name),
       meta = normalizeText(meta),
       body = normalizeText(body),
       notes = normalizeText(notes),
       all = normalizeText('$name $meta $body $notes');
}

/// Cache d'index : le document n'est reconstruit que si sa clé change.
class SearchIndex<K> {
  final Map<K, ({String key, SearchDoc doc})> _cache = {};

  SearchDoc doc(K id, String key, SearchDoc Function() build) {
    final cached = _cache[id];
    if (cached != null && cached.key == key) return cached.doc;
    if (_cache.length > 4096) _cache.clear();
    final d = build();
    _cache[id] = (key: key, doc: d);
    return d;
  }

  void clear() => _cache.clear();
}
