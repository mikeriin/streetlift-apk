// G6 (D1.6, D3) — profil d'athlète v2 branché sur le magasin : brouillon de
// la création, enregistrement (santé du questionnaire L13, poids, profil
// v2), proposition de refaire son profil (session personnelle), référence
// santé tenue à jour. Modèle : athlete_profile.dart.
part of 'store.dart';

extension AthleteProfileStore on AppStore {
  /// Brouillon de la création du profil : clé à part de la session active
  /// (hors sauvegarde : état transitoire d'écran), effacé à
  /// l'enregistrement et par « Supprimer les données ».
  static const _kDraft = 'athlete_profile_draft_v1';

  /// « Plus tard » de la proposition de refaire son profil : jour civil.
  static const _kRedoLater = 'athlete_profile_redo_later_v1';

  /// Profil v2 (null tant qu'il n'a pas été créé).
  kc.AthleteProfile? get athleteProfile => athlete?.profile;

  /// Un profil existe (v2, ou L8 d'une installation d'avant G6).
  bool get hasAnyProfile => athlete != null || profile != null;

  String get _todayKey => profileDay(storeClock());

  // ------------------------------------------------------------- brouillon

  /// Brouillon en cours ([mode] : 'create' installation neuve, 'redo'
  /// refaire son profil) et son étape.
  ({ProfileDraft draft, String step, String mode})? get athleteDraft {
    try {
      final raw = _prefs.getString(_kDraft);
      if (raw == null) return null;
      final m = jsonDecode(raw);
      if (m is! Map || m['v'] != 1) return null;
      final d = ProfileDraft.fromJson(m['draft']);
      final step = m['step'];
      final mode = m['mode'];
      if (d == null ||
          step is! String ||
          !kAthleteSteps.contains(step) ||
          (mode != 'create' && mode != 'redo')) {
        return null;
      }
      return (draft: d, step: step, mode: mode as String);
    } catch (_) {
      return null;
    }
  }

  /// Enregistre le brouillon ([draft] null : l'efface).
  Future<void> saveAthleteDraft(
    ProfileDraft? draft, {
    String step = 'welcome',
    String mode = 'create',
  }) async {
    try {
      if (draft == null) {
        await _prefs.remove(_kDraft);
      } else {
        await _prefs.setString(
          _kDraft,
          jsonEncode({
            'v': 1,
            'mode': mode,
            'step': step,
            'draft': draft.toJson(),
          }),
        );
      }
    } catch (_) {}
  }

  // ---------------------------------------------- refaire son profil (D1.6)

  /// Session avec des données mais sans profil v2 : Koach propose de
  /// refaire la création du profil, au plus une fois par jour.
  bool get athleteRedoProposed {
    if (athlete != null || isFreshInstall) return false;
    try {
      return _prefs.getString(_kRedoLater) != _todayKey;
    } catch (_) {
      return true;
    }
  }

  /// « Plus tard » : la proposition revient le lendemain.
  Future<void> snoozeAthleteRedo() async {
    try {
      await _prefs.setString(_kRedoLater, _todayKey);
    } catch (_) {}
    notifyListeners();
  }

  /// Brouillon de départ pour refaire son profil : ce qui se reprend sans
  /// ambiguïté du profil L8 et des pesées.
  ProfileDraft athleteRedoDraft() => draftFromLegacy(
    profile,
    bodyWeight: currentBodyweight,
    now: storeClock(),
  );

  /// Brouillon d'une modification (profil v2 existant).
  ProfileDraft athleteEditDraft() =>
      ProfileDraft.of(athlete!.profile, health: profile?.health);

  // ------------------------------------------------------------------ santé

  /// Référence au questionnaire santé, à jour (âge, gênes, accord).
  kc.HealthScreeningRef get athleteHealthRef =>
      healthRefOf(profile?.health ?? HealthData(), caution);

  /// Profil v2 pour les moteurs : référence santé recalculée.
  kc.AthleteProfile? get athleteProfileForEngines =>
      athlete?.profile.copyWith(healthScreening: athleteHealthRef);

  /// Mode prudent avec le profil v2 : âge et gênes du profil v2.
  CautionStatus _cautionWith(UserProfile? legacy, AthleteRecord? a) {
    if (legacy == null && a == null) return CautionStatus.off;
    final p = legacy ?? UserProfile(origin: 'onboarding', createdAt: _nowAt);
    if (a == null) return evaluateCaution(p, storeClock());
    return evaluateCaution(
      p,
      storeClock(),
      birth: (year: a.profile.birthYear, at: a.birthYearAt),
      discomforts: [
        for (final l in a.profile.limitations)
          (level: l.discomfort, at: a.limitationAt(l)),
      ],
    );
  }

  /// Santé modifiée hors du flux (Réglages › Profil) : gênes effacées si
  /// demandé ([clearLimitations]), référence santé recalculée avec le bloc
  /// santé [legacy] qui va être enregistré.
  void _athleteHealthChanged({
    bool clearLimitations = false,
    UserProfile? legacy,
  }) {
    final health = legacy ?? profile;
    final a = athlete;
    if (a == null) return;
    final at = _nowAt;
    var p = a.profile;
    final rubrics = <String>{};
    if (clearLimitations && p.limitations.isNotEmpty) {
      p = p.copyWith(limitations: const []);
      rubrics.add('health');
    }
    final draft = AthleteRecord(
      profile: p,
      savedAt: a.savedAt,
      birthYearAt: a.birthYearAt,
      limitationsAt: clearLimitations ? const {} : a.limitationsAt,
      changes: a.changes,
    );
    final ref = healthRefOf(
      health?.health ?? HealthData(),
      _cautionWith(health, draft),
    );
    if (!kc.jsonDeepEquals(ref.toJson(), p.healthScreening?.toJson())) {
      p = p.copyWith(healthScreening: ref);
      rubrics.add('health');
    }
    if (rubrics.isEmpty) return;
    p = p.copyWith(updatedOn: _laterDay(p.createdOn, civilOf(storeClock())));
    athlete = AthleteRecord(
      profile: p,
      savedAt: at,
      birthYearAt: a.birthYearAt,
      limitationsAt: draft.limitationsAt,
      changes: _withChange(a.changes, ProfileChange(at, ['health'], true)),
    );
  }

  static kc.CivilDate _laterDay(kc.CivilDate a, kc.CivilDate b) =>
      a > b ? a : b;

  static List<ProfileChange> _withChange(
    List<ProfileChange> changes,
    ProfileChange c,
  ) {
    final out = [...changes, c];
    if (out.length > AthleteRecord.maxChanges) {
      out.removeRange(0, out.length - AthleteRecord.maxChanges);
    }
    return out;
  }

  // ---------------------------------------------------------- enregistrement

  /// Enregistre le profil du flux : d'abord le bloc santé du questionnaire
  /// (profil L8, créé au besoin), puis le poids (pesée), puis le profil v2.
  /// Renvoie les rubriques changées et si le programme est concerné (null :
  /// brouillon incomplet, rien n'est écrit).
  ({Set<String> rubrics, bool program})? saveAthleteProfile(ProfileDraft d) {
    final now = storeClock();
    final at = athleteAt(now);
    // Vérifie d'abord que le profil se construit (aucune écriture sinon).
    if (d.build(now, vocabulary: content.equipmentVocabulary) == null) {
      return null;
    }
    // 1. Santé : consentement, réponses (bloc L8, règles L8/L13).
    final before = profile;
    final hp = before?.copy() ?? UserProfile(origin: 'onboarding', createdAt: at);
    final h = hp.health;
    final changed = <String>{};
    final wanted = d.consent;
    if (wanted == 'given' && !h.consentGiven) {
      h
        ..consent = 'given'
        ..consentAt = at;
      changed.add('consent');
    } else if (wanted == 'refused' && h.consent != 'refused' &&
        h.consent != 'withdrawn') {
      h
        ..consent = h.consentGiven ? 'withdrawn' : 'refused'
        ..consentAt = at;
      changed.add('consent');
    }
    if (h.consentGiven) {
      final same =
          d.answers.length == h.answers.length &&
          d.answers.entries.every((e) => h.answers[e.key] == e.value);
      if (!same) {
        h.answers
          ..clear()
          ..addAll(d.answers);
        h.answeredAt = d.answers.isEmpty ? null : at;
        changed.add('health');
      }
    } else if (h.hasHealthContent || kHealthFields.any(hp.fields.containsKey)) {
      h.clearContent();
      for (final k in kHealthFields) {
        hp.fields.remove(k);
      }
      changed.add('health');
    }
    if (before == null || changed.isNotEmpty) {
      hp.addEvent(at, changed);
      profile = hp;
    }
    // 2. Profil v2, gênes et année datées pour le mode prudent.
    final old = athlete;
    final built = d.build(now, vocabulary: content.equipmentVocabulary)!;
    final la = <String, String>{};
    for (final l in built.limitations) {
      final key = limitationKey(l);
      kc.Limitation? prev;
      for (final x in old?.profile.limitations ?? const <kc.Limitation>[]) {
        if (limitationKey(x) == key) prev = x;
      }
      la[key] = prev != null && prev.discomfort >= l.discomfort
          ? old!.limitationAt(prev)
          : at;
    }
    final birthAt = old != null && old.profile.birthYear == built.birthYear
        ? old.birthYearAt
        : at;
    final tentative = AthleteRecord(
      profile: built,
      savedAt: at,
      birthYearAt: birthAt,
      limitationsAt: la,
    );
    final ref = healthRefOf(h, _cautionWith(hp, tentative));
    final next = built.copyWith(healthScreening: ref);
    final rubrics = changedRubrics(old?.profile, next);
    final affects =
        old == null || rubricsAffectProgram(rubrics, old.profile, next);
    athlete = AthleteRecord(
      profile: next,
      savedAt: at,
      birthYearAt: birthAt,
      limitationsAt: la,
      changes: rubrics.isEmpty
          ? (old?.changes ?? const [])
          : _withChange(
              old?.changes ?? const [],
              ProfileChange(at, rubrics.toList()..sort(), affects),
            ),
    );
    _athleteRaw = null;
    // 3. Poids : pesée du jour s'il a changé.
    final w = d.weightValue;
    final bw = currentBodyweight;
    if (w != null && !w.isNaN && (bw == null || (w - bw).abs() > 1e-9)) {
      addWeighIn(now, w);
    }
    unawaited(saveAthleteDraft(null));
    _koachAuxRevision++;
    pilotageEpoch++;
    _persist();
    notifyListeners();
    return (rubrics: rubrics, program: affects && old != null);
  }

  /// Profil d'exemple enregistré, sans accord santé (tests, sessions
  /// d'essai semées).
  @visibleForTesting
  void seedSampleAthleteProfile() => saveAthleteProfile(
    ProfileDraft.of(sampleAthleteProfile(on: civilOf(storeClock())))
      ..consent = 'refused',
  );

  // ------------------------------------------------- moteurs L10/L11 (G10)

  /// Exercices détestés du profil v2, en identifiants de l'ancien pack
  /// (L11 jusqu'à son retrait en G10).
  Set<String> get athleteDislikedLegacyIds => {
    for (final id in athlete?.profile.dislikedExerciseIds ?? const <String>[])
      ...content.legacyIdsOf(id),
  };
}
