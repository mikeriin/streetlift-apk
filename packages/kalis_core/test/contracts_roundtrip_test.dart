@Timeout(Duration(minutes: 30))
library;

import 'dart:convert';
import 'dart:math';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';
import 'package:test/test.dart';

/// Valeurs seedées par type (PIPELINE_GP.md §4 : au moins 10 000).
const int samples = 10000;

void main() {
  test('chaque type du contrat a son codec', () {
    expect(contractCodecs.map((c) => c.name).toSet().length,
        contractCodecs.length);
    expect(contractCodecs.length, greaterThanOrEqualTo(60));
  });

  for (var index = 0; index < contractCodecs.length; index++) {
    final codec = contractCodecs[index];
    test('${codec.name} : aller-retour JSON sur $samples valeurs seedées', () {
      final r = Random(1000 + index);
      for (var i = 0; i < samples; i++) {
        final value = codec.arbitrary(r);
        final json = codec.toJson(value);
        expect(json.values, isNot(contains(null)),
            reason: 'un champ absent est omis, jamais nul');
        final text = jsonEncode(json);
        final decoded = jsonDecode(text) as Map<String, Object?>;
        final back = codec.fromJson(decoded);
        if (back != value) {
          fail('${codec.name} : valeur différente après aller-retour\n$text');
        }
        expect(back.hashCode, value.hashCode);
        // Sérialisation identique à l'octet près.
        expect(jsonEncode(codec.toJson(back)), text);
        if (i % 50 == 0) {
          // Évolution additive : un champ inconnu est ignoré.
          decoded['champFuturInconnu'] = <String, Object?>{'x': 1};
          expect(codec.fromJson(decoded), value);
          // La validation ne lève jamais d'exception.
          codec.validate(value);
        }
      }
    });
  }

  test('même graine, mêmes valeurs (aucun hasard caché)', () {
    for (final codec in contractCodecs) {
      final a = codec.arbitrary(Random(42));
      final b = codec.arbitrary(Random(42));
      expect(jsonEncode(codec.toJson(a)), jsonEncode(codec.toJson(b)),
          reason: codec.name);
    }
  });

  test('un type racine écrit sa version de schéma', () {
    final r = Random(1);
    expect(arbitraryAthleteProfile(r).toJson()['schemaVersion'], 2);
    expect(arbitraryTrainingLog(r).toJson()['schemaVersion'], 1);
    expect(AthleteProfile.currentSchemaVersion, 2);
    expect(TrainingLog.currentSchemaVersion, 1);
    expect(Pass1Plan.currentSchemaVersion, 1);
    expect(Pass2Plan.currentSchemaVersion, 1);
    expect(ProgramBlock.currentSchemaVersion, 1);
    expect(AdaptationSummary.currentSchemaVersion, 1);
    expect(QuestState.currentSchemaVersion, 1);
  });

  test('lecture stricte : champ manquant ou de mauvais type refusé', () {
    final json = arbitraryDaySlot(Random(3)).toJson();
    expect(() => DaySlot.fromJson(<String, Object?>{'weekday': 1}),
        throwsFormatException);
    expect(
      () => DaySlot.fromJson(<String, Object?>{...json, 'minutes': '30'}),
      throwsFormatException,
    );
    expect(
      () => DaySlot.fromJson(<String, Object?>{...json, 'minutes': 30.5}),
      throwsFormatException,
    );
    expect(
      () => Limitation.fromJson(<String, Object?>{
        'zone': 'genou_gauche',
        'side': 'left',
        'discomfort': 3,
      }),
      throwsFormatException,
    );
    expect(
      () => SessionRecord.fromJson(<String, Object?>{
        'id': 's',
        'date': '2026-02-30',
        'origin': 'program',
        'resume': false,
        'completed': true,
        'sets': <Object?>[],
        'pains': <Object?>[],
      }),
      throwsFormatException,
    );
  });

  test('un nombre entier est accepté pour un champ décimal', () {
    final level = LoadIncrement.fromJson(<String, Object?>{
      'loadType': 'barre',
      'stepKg': 5,
    });
    expect(level.stepKg, 5.0);
    expect(level.minKg, isNull);
  });
}
