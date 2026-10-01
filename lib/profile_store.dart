// L8 (KT-038 à KT-043) — profil branché sur le store : enregistrement,
// événements « profil modifié », consentement, mode prudent.
// Sans profil, aucun de ces chemins ne modifie le comportement 3.0.x.
// Contrat : docs/CONTRAT_L8.md.
//
// G6 (D1.6) : la création du profil passe au profil d'athlète v2
// (athlete_profile_store.dart). Le démarrage court, la confirmation d'une
// installation existante (KT-043) et les questions progressives (KT-040)
// sont retirés ; le bloc santé (consentement, questionnaire, accord du
// médecin) et le mode prudent restent ici, avec l'âge et les gênes du
// profil v2 quand il existe.
part of 'store.dart';

extension ProfileStore on AppStore {
  String get _nowAt => profileAt(storeClock());

  /// Installation sans aucune donnée : la création du profil est
  /// proposée (G6).
  bool get isFreshInstall =>
      profile == null &&
      athlete == null &&
      logs.isEmpty &&
      program.start == null &&
      values.isEmpty &&
      koach.pristine;

  /// Mode prudent (KT-041). Sans aucun profil : désactivé (comportement
  /// 3.0.x). G6 : âge et gênes du profil v2 quand il existe.
  CautionStatus get caution =>
      AthleteProfileStore(this)._cautionWith(profile, athlete);

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
    final p = (profile ?? _healthHolder())?.copy();
    if (p == null) return;
    p.health
      ..consent = given
          ? 'given'
          : (p.health.consentGiven ? 'withdrawn' : 'refused')
      ..consentAt = _nowAt;
    if (!given) {
      p.health.clearContent();
      for (final k in kHealthFields) {
        p.fields.remove(k);
      }
    }
    _saveHealth(p, clearLimitations: !given);
  }

  /// Supprime les données de santé seules (le consentement reste daté).
  /// G6 : les blessures et gênes du profil v2 aussi.
  void deleteHealthData() {
    final p = (profile ?? _healthHolder())?.copy();
    if (p == null) return;
    p.health.clearContent();
    for (final k in kHealthFields) {
      p.fields.remove(k);
    }
    _saveHealth(p, clearLimitations: true);
  }

  /// Accord du médecin déclaré par l'utilisateur (daté).
  void declareDoctorClearance() {
    final p = profile?.copy();
    if (p == null || !p.health.consentGiven) return;
    p.health.clearanceAt = _nowAt;
    _saveHealth(p);
  }

  /// Retire l'accord déclaré.
  void removeDoctorClearance() {
    final p = profile?.copy();
    if (p == null) return;
    p.health.clearanceAt = null;
    _saveHealth(p);
  }

  /// G6 : un profil v2 sans bloc santé (fichier importé) en reçoit un vide
  /// pour enregistrer le consentement.
  UserProfile? _healthHolder() => athlete == null
      ? null
      : UserProfile(origin: 'onboarding', createdAt: _nowAt);

  /// Bloc santé enregistré, puis profil v2 tenu à jour (référence santé,
  /// gênes effacées avec les données de santé).
  void _saveHealth(UserProfile p, {bool clearLimitations = false}) {
    AthleteProfileStore(
      this,
    )._athleteHealthChanged(clearLimitations: clearLimitations, legacy: p);
    saveProfile(p);
  }

  /// Poids actuel (pesée la plus récente, sinon référence B4).
  double? get currentBodyweight =>
      koach.weighIns.isNotEmpty ? koach.weighIns.last.kg : values['B4'];
}
