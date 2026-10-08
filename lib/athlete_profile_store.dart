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

  /// CU : questions du schéma 3 passées (identifiants, hors du profil :
  /// jamais reproposées d'office, PARCOURS_V3.md § 6).
  static const _kV3Skipped = 'athlete_profile_v3_skipped_v1';

  /// CU : profil créé avec le parcours v3 (jour civil de création) : ses
  /// questions reportées sont proposées après la première semaine.
  static const _kV3Created = 'athlete_profile_v3_created_v1';

  /// CU : invitation « Compléter mon profil » montrée (une seule fois).
  static const _kV3Invite = 'athlete_profile_v3_invite_v1';

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
  ///
  /// CI1 : le parcours v3 ne demande pas l'ancienneté à un débutant (la
  /// question ne s'affiche qu'à partir d'« intermédiaire ») ; le chemin
  /// calibré de `kalis_plan` 0.2 en a besoin pour servir un profil street.
  /// Pour un débutant sans ancienneté, les moteurs reçoivent « moins de
  /// 6 mois » (ce que « débutant » veut dire dans le parcours) ; le profil
  /// enregistré n'est pas modifié. Le niveau du moteur vient de
  /// l'expérience déclarée, pas de l'ancienneté.
  kc.AthleteProfile? get athleteProfileForEngines {
    final p = athlete?.profile.copyWith(healthScreening: athleteHealthRef);
    if (p != null &&
        p.isSchema3 &&
        p.experience == kc.ExperienceLevel.beginner &&
        p.trainingAge == null) {
      return p.copyWith(trainingAge: kc.TrainingAge.under6Months);
    }
    return p;
  }

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
  ///
  /// CU : profil au schéma 3 (parcours v3) ; [createdByV3] : création ou
  /// profil refait avec le parcours v3 (les questions reportées seront
  /// proposées après la première semaine).
  ({Set<String> rubrics, bool program})? saveAthleteProfile(
    ProfileDraft d, {
    bool createdByV3 = false,
  }) {
    final now = storeClock();
    final at = athleteAt(now);
    final parcours = content.questionnaire;
    // Vérifie d'abord que le profil se construit (aucune écriture sinon).
    if (d.build(
          now,
          vocabulary: content.equipmentVocabulary,
          parcours: parcours,
        ) ==
        null) {
      return null;
    }
    // 1. Santé : consentement, réponses (bloc L8, règles L8/L13).
    final before = profile;
    final hp =
        before?.copy() ?? UserProfile(origin: 'onboarding', createdAt: at);
    final h = hp.health;
    final changed = <String>{};
    final wanted = d.consent;
    if (wanted == 'given' && !h.consentGiven) {
      h
        ..consent = 'given'
        ..consentAt = at;
      changed.add('consent');
    } else if (wanted == 'refused' &&
        h.consent != 'refused' &&
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
    final built = d.build(
      now,
      vocabulary: content.equipmentVocabulary,
      parcours: parcours,
    )!;
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
    // G10 : l'activation de Koach L7 à l'enregistrement du profil (G6
    // correction 1) est retirée avec L7 ; Koach (mascotte) parle partout et
    // le moteur dynamique sert les séances.
    unawaited(saveAthleteDraft(null));
    if (createdByV3) {
      try {
        unawaited(_prefs.setString(_kV3Created, next.createdOn.iso));
      } catch (_) {}
    }
    pilotageEpoch++;
    _persist();
    notifyListeners();
    return (rubrics: rubrics, program: affects && old != null);
  }

  // ------------------------------------------- CU : compléter son profil

  /// Questions du schéma 3 passées (hors du profil).
  Set<String> get skippedProfileQuestions {
    try {
      return {...?_prefs.getStringList(_kV3Skipped)};
    } catch (_) {
      return const {};
    }
  }

  /// Retient des questions passées (« Passer », ou laissées sans réponse).
  Future<void> addSkippedProfileQuestions(Iterable<String> ids) async {
    final next = {...skippedProfileQuestions, ...ids};
    if (next.length == skippedProfileQuestions.length) return;
    try {
      await _prefs.setStringList(_kV3Skipped, next.toList()..sort());
    } catch (_) {}
  }

  /// Questions du schéma 3 encore sans réponse pour le profil
  /// (« Compléter mon profil »), passées exclues.
  List<kc.ProfileQuestion> get profilePendingQuestions {
    final p = athlete?.profile, parcours = content.questionnaire;
    if (p == null || parcours == null) return const [];
    return pendingQuestions(
      parcours,
      p,
      storeClock().year,
      skipped: skippedProfileQuestions,
    );
  }

  /// Le profil a été créé avec le parcours v3.
  bool get profileCreatedByV3 {
    try {
      return _prefs.getString(_kV3Created) != null;
    } catch (_) {
      return false;
    }
  }

  /// Questions reportées encore sans réponse (profil créé avec le parcours
  /// v3).
  List<kc.ProfileQuestion> get profileDeferredPending {
    final p = athlete?.profile, parcours = content.questionnaire;
    if (p == null || parcours == null) return const [];
    final pending = {for (final q in profilePendingQuestions) q.id};
    return [
      for (final q in parcours.deferredQuestions(
        p.toJson(),
        todayYear: storeClock().year,
      ))
        if (pending.contains(q.id)) q,
    ];
  }

  /// Invitation discrète de Koach, une seule fois (PARCOURS_V3.md § 6) :
  /// profil d'avant le parcours v3 avec des questions nouvelles à poser,
  /// ou profil créé avec le parcours v3 après sa première semaine, quand
  /// des questions reportées restent sans réponse.
  bool get profileInviteVisible {
    final a = athlete;
    if (a == null || content.questionnaire == null) return false;
    try {
      if (_prefs.getString(_kV3Invite) != null) return false;
    } catch (_) {
      return false;
    }
    if (!profileCreatedByV3) return profilePendingQuestions.isNotEmpty;
    final weekLater = a.profile.createdOn.addDays(7);
    if (civilOf(storeClock()) < weekLater) return false;
    return profileDeferredPending.isNotEmpty;
  }

  // ------------------------------------------------- CU : tests guidés

  static const _kTestsSeen = 'athlete_profile_tests_seen_v1';

  /// Propositions de tests déjà montrées sur l'accueil (clés).
  Set<String> get seenTestProposals {
    try {
      return {...?_prefs.getStringList(_kTestsSeen)};
    } catch (_) {
      return const {};
    }
  }

  void markTestProposalsSeen(Iterable<String> keys) {
    final next = {...seenTestProposals, ...keys};
    try {
      unawaited(_prefs.setStringList(_kTestsSeen, next.toList()..sort()));
    } catch (_) {}
    notifyListeners();
  }

  /// Résultat d'un test guidé ajouté aux records du profil
  /// (`source: guided_test`). Faux s'il est hors contrat (rien d'écrit).
  bool addGuidedTestResult(kc.Benchmark b) {
    final a = athlete;
    if (a == null || b.validate().isNotEmpty) return false;
    final today = civilOf(storeClock());
    final p = a.profile.copyWith(
      benchmarks: [...?a.profile.benchmarks, b],
      updatedOn: _laterDay(a.profile.createdOn, today),
    );
    if (p.validate().isNotEmpty ||
        (content.catalog?.checkProfile(p).isNotEmpty ?? false)) {
      return false;
    }
    final at = _nowAt;
    athlete = AthleteRecord(
      profile: p,
      savedAt: at,
      birthYearAt: a.birthYearAt,
      limitationsAt: a.limitationsAt,
      changes: _withChange(a.changes, ProfileChange(at, ['levels'], false)),
    );
    _athleteRaw = null;
    _persist();
    notifyListeners();
    return true;
  }

  /// CI1 : résultats que le moteur dynamique rend après les tests d'un bloc
  /// du chemin calibré (`AdaptReview.testResults`, `skillStates`) reportés
  /// au profil : records ajoutés (un même record n'est jamais ajouté deux
  /// fois), étape actuelle de chaque figure remplacée. Rien n'est retiré.
  /// Vrai si le profil a changé ; faux sinon (ou hors contrat : rien
  /// d'écrit).
  bool reportEngineResults(kc.AdaptReview review, {kc.CivilDate? since}) {
    final tests = review.testResults ?? const <kc.Benchmark>[];
    final skills = review.skillStates ?? const <kc.SkillState>[];
    if (tests.isEmpty && skills.isEmpty) return false;
    // Deux écritures séparées : un refus de l'une ne bloque pas l'autre.
    final b = _reportBenchmarks(tests, since);
    final k = _reportSkills(skills);
    return b || k;
  }

  /// Identité d'un record : mêmes exercice, nature, date, source, mesure et
  /// protocole (le poids de corps et la réserve notés ne comptent pas : le
  /// moteur relit tout le journal à chaque revue).
  static String _benchmarkKey(kc.Benchmark b) => [
    b.exerciseId,
    b.kind.code,
    b.date?.iso,
    b.source.code,
    b.externalLoadKg,
    b.reps,
    b.seconds,
    b.distanceMeters,
    b.protocolId,
  ].join('|');

  bool _reportBenchmarks(List<kc.Benchmark> tests, kc.CivilDate? since) {
    final a = athlete;
    if (a == null || tests.isEmpty) return false;
    final known = {
      for (final b in a.profile.benchmarks ?? const <kc.Benchmark>[])
        _benchmarkKey(b),
    };
    final added = <kc.Benchmark>[];
    for (final b in tests) {
      // Seulement les tests du bloc en cours : un record retiré du profil
      // à la main ne revient pas d'un ancien bloc.
      final d = b.date;
      if (since != null && (d == null || d.compareTo(since) < 0)) continue;
      if (b.validate().isNotEmpty) continue;
      if (known.add(_benchmarkKey(b))) added.add(b);
    }
    final room = 200 - (a.profile.benchmarks?.length ?? 0);
    if (added.isEmpty || room <= 0) return false;
    final kept = added.length > room
        ? added.sublist(added.length - room)
        : added;
    return _saveEngineProfile(
      a,
      a.profile.copyWith(
        benchmarks: <kc.Benchmark>[...?a.profile.benchmarks, ...kept],
      ),
    );
  }

  bool _reportSkills(List<kc.SkillState> skills) {
    final a = athlete;
    if (a == null || skills.isEmpty) return false;
    final current = [...?a.profile.skills];
    var changed = false;
    for (final st in skills) {
      if (st.validate().isNotEmpty) continue;
      final i = current.indexWhere(
        (x) => x.targetExerciseId == st.targetExerciseId,
      );
      if (i < 0) continue; // figure que le profil ne suit pas
      final old = current[i];
      final sameStep = old.currentExerciseId == st.currentExerciseId;
      int? best(int? stored, int? engine) => engine == null
          ? (sameStep ? stored : null)
          : (sameStep && stored != null && stored > engine ? stored : engine);
      // Fusion champ par champ : ce que l'utilisateur a déclaré (depuis
      // quand il est à l'étape, meilleure tenue, date) reste tant que
      // l'étape ne change pas.
      final merged = kc.SkillState(
        targetExerciseId: old.targetExerciseId,
        currentExerciseId: st.currentExerciseId,
        bestHoldSeconds: best(old.bestHoldSeconds, st.bestHoldSeconds),
        bestReps: best(old.bestReps, st.bestReps),
        assessedOn: st.assessedOn ?? (sameStep ? old.assessedOn : null),
        atStepSince: sameStep
            ? (old.atStepSince ?? st.atStepSince)
            : st.atStepSince,
      );
      if (merged.validate().isNotEmpty) continue;
      if (jsonEncode(old.toJson()) == jsonEncode(merged.toJson())) continue;
      current[i] = merged;
      changed = true;
    }
    if (!changed) return false;
    return _saveEngineProfile(a, a.profile.copyWith(skills: current));
  }

  bool _saveEngineProfile(AthleteRecord a, kc.AthleteProfile next) {
    final today = civilOf(storeClock());
    final p = next.copyWith(updatedOn: _laterDay(a.profile.createdOn, today));
    if (p.validate().isNotEmpty ||
        (content.catalog?.checkProfile(p).isNotEmpty ?? false)) {
      return false;
    }
    final at = _nowAt;
    athlete = AthleteRecord(
      profile: p,
      savedAt: at,
      birthYearAt: a.birthYearAt,
      limitationsAt: a.limitationsAt,
      changes: _withChange(a.changes, ProfileChange(at, ['levels'], false)),
    );
    _athleteRaw = null;
    _persist();
    notifyListeners();
    return true;
  }

  /// L'invitation a été vue (ouverte ou « Plus tard ») : elle ne revient
  /// pas ; « Compléter mon profil » reste dans Réglages › Profil.
  Future<void> dismissProfileInvite() async {
    try {
      await _prefs.setString(_kV3Invite, _todayKey);
    } catch (_) {}
    notifyListeners();
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
