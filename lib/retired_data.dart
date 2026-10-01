// G2 (dev6.1.0, DECISIONS_GP.md D1.1 et D1.2) : données des fonctions
// retirées — WOD (catalogue, résultats, droits, crédits, vitrine, envies),
// séances manuelles (modèles et journal « S0-… ») et motivation L12.
//
// Ce fichier ne lit et n'écrit rien : il repère ces données dans un document
// d'état ou de sauvegarde (format 3, JSON décodé), les met de côté telles
// quelles et les compte pour l'écran d'annonce. Le magasin (`store.dart`)
// n'efface rien tant qu'une copie complète n'a pas été écrite et relue.

/// Sections du document que plus aucune version ne lit à partir de G2.
const kRetiredSections = <String>[
  'custom', // modèles de séances manuelles
  'catalog', // WOD : supprimés, modifiés, créés, résultats (format 3)
  'wods', // WOD : formats 1 et 2
  'unlocked', // WOD débloqués avec des crédits (KT-005)
  'legacyGrants', // droits anciens archivés (KT-014)
  'creditsEarnedMax', // plus haut total de crédits (KT-005)
  'creditGrants', // registre des gains de crédits (KT-005)
  'trialOfDay', // essai du jour
  'weeklyShowcase', // vitrine de la semaine
  'wishlist', // liste d'envies
  'motiv', // L12 : motivation et progression visible
];

/// Séance manuelle du journal : semaine 0 (« S0-J<id> », archives
/// « S0-J<id>@… » comprises).
bool isManualSessionKey(String key) => key.startsWith('S0-');

/// Ce qui disparaît, compté pour l'écran d'annonce. Les nombres viennent du
/// document lui-même ; rien n'est déduit.
class RetiredSummary {
  /// Modèles de séances manuelles.
  final int manualTemplates;

  /// Séances manuelles terminées (archives comprises).
  final int manualSessionsDone;

  /// Entrées du journal des séances manuelles (terminées ou non).
  final int manualLogs;

  /// Résultats de WOD enregistrés.
  final int wodResults;

  /// WOD créés, modifiés ou retirés du catalogue par l'utilisateur.
  final int wodsCustomized;

  /// WOD débloqués avec des crédits ou par un droit ancien.
  final int wodsUnlocked;

  /// Gains de crédits inscrits au registre (nombre d'entrées).
  final int creditEntries;

  /// WOD de la liste d'envies.
  final int wishlist;

  /// Données de motivation (L12) présentes.
  final bool motivation;

  const RetiredSummary({
    this.manualTemplates = 0,
    this.manualSessionsDone = 0,
    this.manualLogs = 0,
    this.wodResults = 0,
    this.wodsCustomized = 0,
    this.wodsUnlocked = 0,
    this.creditEntries = 0,
    this.wishlist = 0,
    this.motivation = false,
  });

  /// Des données de l'utilisateur seraient supprimées : une copie est
  /// obligatoire avant (D1.1). Un catalogue vierge, une vitrine ou un essai
  /// du jour (sélections recalculées) ne comptent pas.
  bool get hasUserData =>
      manualTemplates > 0 ||
      manualLogs > 0 ||
      wodResults > 0 ||
      wodsCustomized > 0 ||
      wodsUnlocked > 0 ||
      creditEntries > 0 ||
      wishlist > 0 ||
      motivation;

  Map<String, Object> toJson() => {
    'seancesPerso': manualTemplates,
    'seancesPersoFaites': manualSessionsDone,
    'journalPerso': manualLogs,
    'resultatsWod': wodResults,
    'wodPerso': wodsCustomized,
    'wodDebloques': wodsUnlocked,
    'credits': creditEntries,
    'envies': wishlist,
    'motivation': motivation,
  };

  static int _int(Object? v) => v is int && v >= 0 ? v : 0;

  factory RetiredSummary.fromJson(Object? raw) {
    if (raw is! Map) return const RetiredSummary();
    return RetiredSummary(
      manualTemplates: _int(raw['seancesPerso']),
      manualSessionsDone: _int(raw['seancesPersoFaites']),
      manualLogs: _int(raw['journalPerso']),
      wodResults: _int(raw['resultatsWod']),
      wodsCustomized: _int(raw['wodPerso']),
      wodsUnlocked: _int(raw['wodDebloques']),
      creditEntries: _int(raw['credits']),
      wishlist: _int(raw['envies']),
      motivation: raw['motivation'] == true,
    );
  }

  /// Lignes lisibles de l'écran d'annonce (seulement ce qui existe).
  List<String> get lines {
    String n(int v, String one, String many) => '$v ${v > 1 ? many : one}';
    return [
      if (manualTemplates > 0)
        n(manualTemplates, 'séance perso créée', 'séances perso créées'),
      if (manualSessionsDone > 0)
        '${n(manualSessionsDone, 'séance perso terminée', 'séances perso terminées')} (historique)'
      else if (manualLogs > 0)
        n(manualLogs, 'séance perso commencée', 'séances perso commencées'),
      if (wodResults > 0) n(wodResults, 'résultat de WOD', 'résultats de WOD'),
      if (wodsCustomized > 0)
        n(
          wodsCustomized,
          'WOD créé, modifié ou retiré du catalogue',
          'WOD créés, modifiés ou retirés du catalogue',
        ),
      if (wodsUnlocked > 0) n(wodsUnlocked, 'WOD débloqué', 'WOD débloqués'),
      if (creditEntries > 0) 'tes crédits WOD',
      if (wishlist > 0) n(wishlist, 'WOD en envie', 'WOD en envie'),
      if (motivation) 'tes réglages et bilans « Motivation et progression »',
    ];
  }
}

/// Données retirées d'un document, gardées telles quelles (JSON décodé).
class RetiredData {
  /// Sections retirées présentes dans le document.
  final Map<String, Object?> sections;

  /// Journal des séances manuelles (clé → entrée brute).
  final Map<String, Object?> manualLogs;
  final RetiredSummary summary;

  const RetiredData._(this.sections, this.manualLogs, this.summary);

  static const empty = RetiredData._({}, {}, RetiredSummary());

  bool get isEmpty => sections.isEmpty && manualLogs.isEmpty;

  /// Repère les données retirées de [document] (non modifié).
  factory RetiredData.of(Map<String, dynamic> document) {
    final sections = <String, Object?>{
      for (final key in kRetiredSections)
        if (document.containsKey(key)) key: document[key],
    };
    final logs = document['logs'];
    final manual = <String, Object?>{
      if (logs is Map)
        for (final e in logs.entries)
          if (e.key is String && isManualSessionKey(e.key as String))
            e.key as String: e.value,
    };
    return RetiredData._(sections, manual, _summarize(sections, manual));
  }

  static int _length(Object? v) =>
      v is Map ? v.length : (v is List ? v.length : 0);

  static RetiredSummary _summarize(
    Map<String, Object?> s,
    Map<String, Object?> manual,
  ) {
    var results = 0, customized = 0;
    final catalog = s['catalog'];
    if (catalog is Map) {
      final all = catalog['results'];
      if (all is Map) {
        for (final list in all.values) {
          results += _length(list);
        }
      }
      customized =
          _length(catalog['user']) +
          _length(catalog['edits']) +
          _length(catalog['deleted']);
    }
    // Formats 1-2 : liste complète des WOD, résultats dans chaque WOD.
    final wods = s['wods'];
    if (wods is List) {
      for (final w in wods) {
        if (w is Map) results += _length(w['results']);
      }
    }
    var done = 0;
    for (final log in manual.values) {
      if (log is Map && log['done'] == true) done++;
    }
    final earnedMax = s['creditsEarnedMax'];
    final motiv = s['motiv'];
    return RetiredSummary(
      manualTemplates: _length(s['custom']),
      manualSessionsDone: done,
      manualLogs: manual.length,
      wodResults: results,
      wodsCustomized: customized,
      wodsUnlocked: _length(s['unlocked']) + _length(s['legacyGrants']),
      creditEntries:
          _length(s['creditGrants']) +
          (earnedMax is num && earnedMax > 0 ? 1 : 0),
      wishlist: _length(s['wishlist']),
      motivation: motiv is Map && motiv.isNotEmpty,
    );
  }

  /// [document] sans les données retirées (copie superficielle ; le journal
  /// est recopié sans ses séances manuelles).
  static Map<String, dynamic> strip(Map<String, dynamic> document) {
    final out = Map<String, dynamic>.of(document);
    for (final key in kRetiredSections) {
      out.remove(key);
    }
    final logs = out['logs'];
    if (logs is Map) {
      out['logs'] = <String, dynamic>{
        for (final e in logs.entries)
          if (!(e.key is String && isManualSessionKey(e.key as String)))
            e.key as String: e.value,
      };
    }
    return out;
  }

  /// Remet ces données dans [document] (écriture tant que la copie n'est
  /// pas faite : rien n'est perdu). Les sections et séances déjà présentes
  /// dans [document] ne sont pas remplacées.
  void restoreInto(Map<String, dynamic> document) {
    sections.forEach((k, v) => document.putIfAbsent(k, () => v));
    if (manualLogs.isEmpty) return;
    final logs = document['logs'];
    final merged = <String, dynamic>{
      if (logs is Map)
        for (final e in logs.entries) e.key as String: e.value,
    };
    manualLogs.forEach((k, v) => merged.putIfAbsent(k, () => v));
    document['logs'] = merged;
  }
}

/// Égalité profonde de deux valeurs JSON décodées.
bool jsonDeepEquals(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (!b.containsKey(e.key) || !jsonDeepEquals(e.value, b[e.key])) {
        return false;
      }
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!jsonDeepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is num && b is num) return a == b;
  return a == b;
}

/// Empreinte FNV-1a 32 bits (contrôle de la copie relue).
int fnv1a32(String s) {
  var h = 0x811C9DC5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

/// Fiche de la copie faite avant la suppression (G2) : gardée à côté de la
/// copie, hors sauvegarde.
class RetiredNotice {
  final DateTime at;
  final int bytes;
  final int checksum;
  final RetiredSummary summary;

  /// L'utilisateur a lu l'annonce (« Compris »).
  bool seen;

  RetiredNotice({
    required this.at,
    required this.bytes,
    required this.checksum,
    required this.summary,
    this.seen = false,
  });

  Map<String, Object> toJson() => {
    'version': 1,
    'at': at.toIso8601String(),
    'octets': bytes,
    'empreinte': checksum,
    'supprime': summary.toJson(),
    'vue': seen,
  };

  factory RetiredNotice.fromJson(Object? raw) {
    if (raw is! Map ||
        raw['at'] is! String ||
        raw['octets'] is! int ||
        raw['empreinte'] is! int) {
      throw const FormatException('Fiche de copie illisible.');
    }
    final at = DateTime.tryParse(raw['at'] as String);
    if (at == null) throw const FormatException('Date de copie illisible.');
    return RetiredNotice(
      at: at,
      bytes: raw['octets'] as int,
      checksum: raw['empreinte'] as int,
      summary: RetiredSummary.fromJson(raw['supprime']),
      seen: raw['vue'] == true,
    );
  }

  /// Nom proposé au partage ou à l'enregistrement de la copie.
  String fileName({bool devSession = false}) {
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp =
        '${at.year}-${two(at.month)}-${two(at.day)}-${two(at.hour)}${two(at.minute)}';
    return devSession
        ? 'kalis-track-session-de-test-copie-avant-g2-$stamp.json'
        : 'kalis-track-copie-avant-g2-$stamp.json';
  }
}
