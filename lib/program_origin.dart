// CI1e (dev6.10.0, DECISIONS_CP.md C11.2) — filets du passage du programme
// de 40 semaines sous toutes les fonctionnalités :
//
// - avant la première lecture par 6.10.0 (ou à l'import d'une sauvegarde
//   d'avant 6.10.0), sauvegarde complète automatique de l'état d'origine :
//   programme (départ, instance, programme créé, « Où j'en suis »,
//   évolution) et journal. Elle est écrite dans le document de l'appli
//   (donc dans chaque sauvegarde exportée, section `programOrigin`) et,
//   à part, dans le stockage local de l'appareil ; elle s'exporte en
//   fichier (Réglages › Mon programme) : c'est une sauvegarde Kalis Track
//   ordinaire, importable telle quelle ;
// - « Revenir à mon programme d'origine » (Réglages › Mon programme) rend
//   exactement le programme d'avant (sections du programme identiques à la
//   sauvegarde) ; le journal n'est jamais réécrit : les séances faites et
//   les séries validées depuis restent.
part of 'store.dart';

/// Lecture tolérante de la section `programOrigin` (null : absente ou
/// illisible ; jamais bloquante).
Map<String, dynamic>? _readProgramOrigin(Object? raw) {
  if (raw is! Map) return null;
  final backup = raw['backup'];
  if (backup is! Map || backup['kalisTrack'] != 1) return null;
  return Map<String, dynamic>.from(raw);
}

extension ProgramOriginStore on AppStore {
  /// Copie locale, hors du document (survit à l'import d'une sauvegarde
  /// d'avant 6.10.0).
  static const _kOrigin = 'program_origin_v1';

  /// Un programme importé est en place (programme de 40 semaines, ancien
  /// programme L10, semaines d'avant un programme créé) : il passe sous
  /// les fonctionnalités des moteurs (C11).
  bool get programOriginNeeded {
    if (program.start == null) return false;
    final plan = planProgram;
    return plan == null || plan.firstWeek > 1;
  }

  /// Prend la sauvegarde d'origine si elle manque et qu'un programme
  /// importé est en place. Vrai si elle vient d'être prise.
  bool captureProgramOrigin() {
    if (programOrigin != null) return false;
    final local = _readLocalOrigin();
    if (local != null) {
      programOrigin = local;
      return true;
    }
    if (!programOriginNeeded) return false;
    final backup = _backupJson(_currentBackup())..remove('programOrigin');
    programOrigin = {
      'v': 1,
      'at': storeClock().toIso8601String(),
      'backup': backup,
    };
    _writeLocalOrigin();
    return true;
  }

  /// Au démarrage : sauvegarde d'origine prise et écrite si elle manque.
  Future<void> ensureProgramOrigin() async {
    if (captureProgramOrigin()) {
      _persist();
    } else if (programOrigin != null && _readLocalOrigin() == null) {
      _writeLocalOrigin();
    }
  }

  Map<String, dynamic>? _readLocalOrigin() {
    try {
      final raw = _prefs.getString(_kOrigin);
      if (raw == null) return null;
      return _readProgramOrigin(jsonDecode(AppStore._unpack(raw) ?? raw));
    } catch (_) {
      return null;
    }
  }

  void _writeLocalOrigin() {
    final o = programOrigin;
    if (o == null) return;
    try {
      unawaited(_prefs.setString(_kOrigin, AppStore._pack(jsonEncode(o))));
    } catch (_) {
      // Copie locale impossible : celle du document reste.
    }
  }

  /// Date de la sauvegarde d'origine (null : aucune).
  DateTime? get programOriginAt {
    final at = programOrigin?['at'];
    return at is String ? DateTime.tryParse(at) : null;
  }

  /// La sauvegarde d'origine peut être rétablie.
  bool get canRestoreProgramOrigin => programOrigin?['backup'] is Map;

  /// Le programme en place diffère de la sauvegarde d'origine.
  bool get programDiffersFromOrigin {
    final b = programOrigin?['backup'];
    if (b is! Map) return false;
    final now = _backupJson(_currentBackup());
    for (final k in kProgramOriginSections) {
      if (jsonEncode(b[k]) != jsonEncode(now[k])) return true;
    }
    return false;
  }

  /// Sections du programme rendues par « Revenir à mon programme
  /// d'origine » (le journal, le profil, les références et les réglages
  /// restent ceux d'aujourd'hui).
  static const kProgramOriginSections = [
    'programStart',
    'programInstance',
    'planProgram',
    'programResume',
    'planEvolution',
  ];

  /// Rend exactement le programme de la sauvegarde d'origine ; vrai si
  /// c'est fait. Le journal n'est pas touché.
  bool restoreProgramOrigin() {
    final b = programOrigin?['backup'];
    if (b is! Map) return false;
    _BackupData o;
    try {
      o = _parseBackup(jsonEncode(b));
    } catch (_) {
      return false;
    }
    programInstance = o.programInstance;
    programLoadIssues = o.programIssues;
    planProgram = o.planProgram;
    _planRaw = o.planRaw;
    planLoadIssues = o.planIssues;
    programResume = o.programResume;
    planEvolution = o.planEvolution;
    _evoRaw = o.evolutionRaw;
    startOrigin = o.startOrigin;
    _evoRevision++;
    _evoRefreshKey = '';
    lastEvolutionReview = null;
    evolutionNotApplicable = const [];
    _g9Cache.clear();
    _materializeProgram(o.start);
    _allEx = null;
    _muscleIndex = null;
    _progression = null;
    pilotageEpoch++;
    _persist();
    notifyListeners();
    return true;
  }

  /// Sauvegarde d'origine au format d'une sauvegarde Kalis Track (fichier
  /// exportable, importable telle quelle) ; null : aucune.
  String? programOriginExport() {
    final b = programOrigin?['backup'];
    if (b is! Map) return null;
    return jsonEncode({
      ...b.cast<String, dynamic>(),
      'exportedAt': programOrigin!['at'],
      'programOriginCopy': true,
    });
  }
}
