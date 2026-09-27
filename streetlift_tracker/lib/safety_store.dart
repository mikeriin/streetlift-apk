// L13 (KT-073, KT-075, KT-078) — sécurité branchée sur le store : douleur
// persistante (renvoi vers un professionnel), contrôle 18 ans et plus
// appliqué à tout profil chargé ou importé, informations du retour de
// test. Aucune donnée nouvelle n'est enregistrée (pas de migration).
// Règles pures : lib/wellbeing.dart. Contrat : docs/CONTRAT_L13.md.
part of 'store.dart';

extension SafetyStore on AppStore {
  /// Douleurs notées pour [movement] (0-10), de la séance terminée la plus
  /// ancienne à la plus récente ; séances sans note exclues.
  List<int> painHistory(String movement) {
    final rows = <(DateTime, String, int)>[];
    koach.answers.forEach((k, a) {
      final v = a.pain[movement];
      if (v == null) return;
      final t =
          DateTime.tryParse(logs[k]?.finishedAt ?? '') ?? DateTime(1970);
      rows.add((t, k, v));
    });
    rows.sort((a, b) {
      final c = a.$1.compareTo(b.$1);
      return c != 0 ? c : a.$2.compareTo(b.$2);
    });
    return [for (final r in rows) r.$3];
  }

  /// Douleur > 3/10 sur plus de 2 séances de suite : renvoi vers un
  /// professionnel de santé (KT-073).
  bool painNeedsReferralFor(String movement) =>
      painNeedsReferral(painHistory(movement));

  /// Mouvements concernés par le renvoi, triés.
  List<String> get painReferralMovements {
    final all = <String>{
      for (final a in koach.answers.values) ...a.pain.keys,
    };
    return [
      for (final m in all.toList()..sort())
        if (painNeedsReferralFor(m)) m,
    ];
  }

  /// Profil chargé ou importé dont l'année de naissance indique moins de
  /// 18 ans (18 ans dans l'année : accepté, la question a été posée au
  /// démarrage). L'application est alors bloquée jusqu'à correction ou
  /// suppression des données (KT-075).
  bool get profileIsMinor {
    final age = ageInYear(profile?.intValue('birthYear'), storeClock());
    return age != null && age < 18;
  }

  /// Repère de niveau du profil (libellé) pour le retour de test.
  String? get feedbackLevel => kLevelLabels[profile?.level];
}
