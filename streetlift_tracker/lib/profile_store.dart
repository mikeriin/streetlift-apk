// L8 (KT-038 à KT-043) — profil branché sur le store : enregistrement,
// événements « profil modifié », consentement, mode prudent, questions
// progressives et migration d'une installation existante.
// Sans profil (installation antérieure non confirmée), aucun de ces
// chemins ne modifie le comportement 3.0.x. Contrat : docs/CONTRAT_L8.md.
part of 'store.dart';

extension ProfileStore on AppStore {
  String get _nowAt => profileAt(storeClock());

  /// Installation sans aucune donnée : le démarrage court est proposé.
  bool get isFreshInstall =>
      profile == null &&
      logs.isEmpty &&
      program.start == null &&
      values.isEmpty &&
      customSessions.isEmpty &&
      koach.pristine;

  /// Installation existante sans profil : écran de confirmation (KT-043).
  bool get needsProfileConfirmation => profile == null && !isFreshInstall;

  /// Mode prudent (KT-041). Sans profil : désactivé (comportement 3.0.x
  /// conservé jusqu'à la confirmation du profil).
  CautionStatus get caution {
    final p = profile;
    if (p == null) return CautionStatus.off;
    return evaluateCaution(p, storeClock());
  }

  bool get cautionActive => caution.active;

  /// Références des mouvements principaux (1RM de la feuille Pilotage).
  Set<String> get _mainLiftRefs => {
    for (final l in program.pilotage.mainLifts) l.ref,
  };

  /// Pourcentage du 1RM effectivement appliqué (plafond du mode prudent).
  double profilePct(LoadSpec s) => cautionPct(
    s.pct!,
    mainLift: _mainLiftRefs.contains(s.ref ?? 'B11'),
    active: cautionActive,
  );

  /// Consigne du mode prudent pour un exercice (null = aucune).
  String? cautionNote(Exercise e) {
    if (!cautionActive) return null;
    if (isMaxTest(e.name, e.intensity)) {
      return 'Mode prudent : pas de test maximal. Fais une série propre en '
          'gardant au moins $kCautionMinRir répétitions en réserve.';
    }
    final ref = e.load.ref ?? (e.load.type == 'barbell' ? 'B11' : null);
    if (e.main || (ref != null && _mainLiftRefs.contains(ref))) {
      return 'Mode prudent : garde au moins $kCautionMinRir répétitions en '
          'réserve ; charge limitée à 80 % du 1RM estimé.';
    }
    return null;
  }

  /// Enregistre un profil complet (démarrage, confirmation, modification).
  /// Les champs modifiés produisent un événement daté « profil modifié ».
  void saveProfile(UserProfile next) {
    final before = profile;
    final changed = <String>{};
    if (before == null) {
      changed.addAll(next.fields.keys);
      if (next.health.hasHealthContent) changed.add('health');
      if (next.health.consent != null) changed.add('consent');
    } else {
      for (final k in {...before.fields.keys, ...next.fields.keys}) {
        final a = before.fields[k], b = next.fields[k];
        if (a == null ||
            b == null ||
            jsonEncode(a.value) != jsonEncode(b.value) ||
            a.source != b.source) {
          changed.add(k);
        }
      }
      if (jsonEncode(before.health.answers) !=
              jsonEncode(next.health.answers) ||
          before.health.answeredAt != next.health.answeredAt) {
        changed.add('health');
      }
      if (before.health.consent != next.health.consent) changed.add('consent');
      if (before.health.clearanceAt != next.health.clearanceAt) {
        changed.add('clearance');
      }
      if (jsonEncode(before.health.injuries.map((i) => i.toJson()).toList()) !=
          jsonEncode(next.health.injuries.map((i) => i.toJson()).toList())) {
        changed.add('injuries');
      }
    }
    next.addEvent(_nowAt, changed);
    profile = next;
    _profileSave();
    // L10 : profil modifié → régénération proposée (mode Guidé : appliquée
    // tout de suite, annulable 7 jours).
    if (ProgramStore(this).programProfileChanged) {
      unawaited(
        ProgramStore(this).onProfileSavedForProgram().catchError((_) => false),
      );
    }
  }

  void _profileSave() {
    _koachAuxRevision++;
    pilotageEpoch++;
    _persist();
    notifyListeners();
  }

  /// Consentement explicite et révocable (KT-042). Retrait ou refus : les
  /// données de santé sont effacées ; le mode prudent s'applique.
  void setHealthConsent(bool given) {
    final p = profile?.copy();
    if (p == null) return;
    p.health
      ..consent =
          given ? 'given' : (p.health.consentGiven ? 'withdrawn' : 'refused')
      ..consentAt = _nowAt;
    if (!given) {
      p.health.clearContent();
      for (final k in kHealthFields) {
        p.fields.remove(k);
      }
    }
    saveProfile(p);
  }

  /// Supprime les données de santé seules (le consentement reste daté).
  void deleteHealthData() {
    final p = profile?.copy();
    if (p == null) return;
    p.health.clearContent();
    for (final k in kHealthFields) {
      p.fields.remove(k);
    }
    saveProfile(p);
  }

  /// Accord du médecin déclaré par l'utilisateur (daté).
  void declareDoctorClearance() {
    final p = profile?.copy();
    if (p == null || !p.health.consentGiven) return;
    p.health.clearanceAt = _nowAt;
    saveProfile(p);
  }

  /// Retire l'accord déclaré.
  void removeDoctorClearance() {
    final p = profile?.copy();
    if (p == null) return;
    p.health.clearanceAt = null;
    saveProfile(p);
  }

  // ------------------------------------------------ questions progressives

  /// Question à poser après la séance [sessionKey] (au plus une).
  String? progressiveQuestionFor(String sessionKey) =>
      nextProgressiveQuestion(profile, sessionKey, storeClock());

  /// Réponse ([value] non nul), « plus tard » ou « ne plus demander ».
  void answerProgressive(
    String question,
    String sessionKey, {
    Object? value,
    bool later = false,
    bool never = false,
  }) {
    final p = profile?.copy();
    if (p == null) return;
    p.lastAskedSession = sessionKey;
    if (value != null) {
      p.setField(question, value, _nowAt);
      p.later.remove(question);
    } else if (never) {
      p.never.add(question);
      p.later.remove(question);
    } else if (later) {
      p.later[question] = _nowAt;
    }
    saveProfile(p);
  }

  // --------------------------------------------------- migration (KT-043)

  /// Profil pré-rempli d'une installation existante, à confirmer. Rien
  /// n'est écrit : dates, valeurs et historique restent inchangés.
  UserProfile ownerDraft() {
    final at = _nowAt;
    final p = UserProfile(origin: 'migration', createdAt: at);
    // Objectifs L7 : étape (12 mois après le départ) et objectif final.
    final items = <Map<String, dynamic>>[];
    DateTime? date;
    const ids = {
      'B8': 'pull_1rm',
      'B9': 'dip_1rm',
      'B10': 'mu_1rm',
      'B11': 'squat_1rm',
    };
    for (final l in program.pilotage.mainLifts) {
      final id = ids[l.ref];
      if (id == null) continue;
      final fin = KoachStore(this).koachObjective(l.ref, 'final');
      final stage = KoachStore(this).koachObjective(l.ref, 'stage');
      final o = fin.target != null && fin.date != null ? fin : stage;
      if (o.date != null && (date == null || o.date!.isAfter(date))) {
        date = o.date;
      }
      items.add({'id': id, if (o.target != null) 'target': o.target});
    }
    if (date != null && items.isNotEmpty) {
      p.setField('goalPrimary', 'event', at, source: 'estimated');
      p.setField(
        'eventGoal',
        {'date': profileDay(date), 'items': items},
        at,
        source: 'estimated',
      );
      p.setField('goalSecondary', 'strength', at, source: 'estimated');
      p.setField('goalWeight', 70, at, source: 'estimated');
    } else {
      p.setField('goalPrimary', 'strength', at, source: 'estimated');
    }
    // Jours : jours de la semaine des séances terminées (au moins 2 fois).
    final counts = <int, int>{};
    final durations = <int>[];
    for (final log in logs.values) {
      final end = DateTime.tryParse(log.finishedAt ?? '');
      if (!log.done || end == null) continue;
      counts[end.weekday] = (counts[end.weekday] ?? 0) + 1;
      DateTime? first;
      for (final ex in log.ex.values) {
        for (final s in ex.sets) {
          final t = DateTime.tryParse(s.completedAt ?? '');
          if (t != null && (first == null || t.isBefore(first))) first = t;
        }
      }
      if (first != null) {
        final m = end.difference(first).inMinutes;
        if (m >= 10 && m <= 240) durations.add(m);
      }
    }
    final days = [
      for (final e in counts.entries)
        if (e.value >= 2) e.key,
    ]..sort();
    if (days.isNotEmpty) p.setField('days', days, at, source: 'estimated');
    if (durations.isNotEmpty) {
      durations.sort();
      final med = durations[durations.length ~/ 2];
      final rounded = ((med / 15).round() * 15).clamp(15, 240);
      p.setField('sessionMinutes', rounded, at, source: 'estimated');
    }
    // Lieux : parc (lest) et salle (back squat) pour le programme 40 semaines.
    p.setField(
      'places',
      {
        'park': ['pullup_bar', 'dip_bars', 'weight_belt'],
        'gym': [
          'pullup_bar',
          'dip_bars',
          'barbell',
          'rack',
          'bench',
          'weight_belt',
        ],
      },
      at,
      source: 'estimated',
    );
    // Repère : maxima de la feuille Pilotage (pompes B19, tractions B17).
    final bands = <String, int>{};
    final push = values['B19'], pull = values['B17'];
    if (push != null) bands['pushups'] = benchmarkBand('pushups', push);
    if (pull != null) bands['pullups'] = benchmarkBand('pullups', pull);
    if (bands.isNotEmpty) {
      final measured =
          (push == null || refStatus['B19'] == 'set') &&
          (pull == null || refStatus['B17'] == 'set');
      p.setField(
        'benchmarks',
        bands,
        at,
        source: measured ? 'measured' : 'estimated',
      );
    }
    final d = defaultsForLevel(levelFromBenchmarks(bands));
    p.setField('autonomy', d.autonomy, at, source: 'estimated');
    p.setField('tone', d.tone, at, source: 'estimated');
    return p;
  }

  /// Nouveau profil vide (démarrage court).
  UserProfile newProfileDraft() =>
      UserProfile(origin: 'onboarding', createdAt: _nowAt);

  /// Poids actuel (pesée la plus récente, sinon référence B4).
  double? get currentBodyweight =>
      koach.weighIns.isNotEmpty ? koach.weighIns.last.kg : values['B4'];
}
