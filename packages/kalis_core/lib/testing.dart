/// Outils de test partagés avec les autres paquets : valeurs aléatoires
/// seedées de chaque type du contrat et lecture des jeux de données communs
/// (`test/fixtures/`, voir `test/fixtures/README.md`).
///
/// À n'importer que depuis des tests ou des simulateurs (`bin/`).
library;

import 'src/contracts.dart';
import 'src/json_util.dart';

export 'src/testing/arbitrary.g.dart';
export 'src/testing/arbitrary_base.dart';

/// Profil type des jeux de données communs.
final class ProfileFixture {
  /// Profil [profile] de clé [key].
  const ProfileFixture(this.key, this.description, this.profile);

  /// Clé stable (`debutant_maison_2x30`).
  final String key;

  /// Ce que le profil représente.
  final String description;

  /// Le profil.
  final AthleteProfile profile;
}

/// Journal synthétique des jeux de données communs.
final class JournalFixture {
  /// Journal [log] de clé [key], simulé pour le profil [profileKey].
  const JournalFixture(
    this.key,
    this.profileKey,
    this.weeks,
    this.description,
    this.log,
  );

  /// Clé stable.
  final String key;

  /// Clé du profil simulé.
  final String profileKey;

  /// Nombre de semaines simulées.
  final int weeks;

  /// Ce que le journal illustre.
  final String description;

  /// Le journal.
  final TrainingLog log;
}

/// Lit `test/fixtures/profiles.json` (objet JSON déjà décodé).
List<ProfileFixture> readProfileFixtures(Map<String, Object?> json) {
  return jsonList(json, 'profiles', (v) {
    final item = jsonAsObject(v, 'profiles');
    return ProfileFixture(
      jsonString(item, 'key'),
      jsonString(item, 'description'),
      AthleteProfile.fromJson(jsonObject(item, 'profile')),
    );
  });
}

/// Lit `test/fixtures/journals.json` (objet JSON déjà décodé).
List<JournalFixture> readJournalFixtures(Map<String, Object?> json) {
  return jsonList(json, 'journals', (v) {
    final item = jsonAsObject(v, 'journals');
    return JournalFixture(
      jsonString(item, 'key'),
      jsonString(item, 'profileKey'),
      jsonInt(item, 'weeks'),
      jsonString(item, 'description'),
      TrainingLog.fromJson(jsonObject(item, 'log')),
    );
  });
}
