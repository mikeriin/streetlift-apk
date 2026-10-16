// Validateur de sécurité de Koach (lot KM2, `package:kalis_adapt/
// validateur.dart`) sur des programmes de kalis_plan écrits pour des
// profils de l'application (profils types de kalis_core). La parité avec le
// validateur du banc est vérifiée dans kalis_bench
// (`test/km2_validateur_test.dart`).
import 'dart:convert';

import 'package:kalis_adapt/koach.dart' show Planification, jl, jm, nq;
import 'package:kalis_adapt/validateur.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show KalisPlan;
import 'package:test/test.dart';

import 'support.dart';

/// Premier jour des programmes (un lundi).
final CivilDate _debut = CivilDate(2026, 10, 5);

/// Premier bloc de kalis_plan pour le profil [profil].
ProgramBlock _bloc(AthleteProfile profil) {
  final catalog = loadCatalog();
  final plan = KalisPlan();
  final request = PlanRequest(
    profile: profil,
    seed: 0,
    startDate: _debut,
    locks: const <PlanLock>[],
  );
  final pass1 = plan.createPass1(catalog, request);
  final pass2 = plan.createPass2(
    catalog,
    Pass2Request(request: request, pass1: pass1),
  );
  return ProgramBlock(pass1: pass1, pass2: pass2);
}

/// Copie JSON profonde des blocs [blocs].
List<Json> _json(List<ProgramBlock> blocs) => <Json>[
  for (final b in blocs) jm(jsonDecode(jsonEncode(b.toJson()))),
];

/// Codes des constats [constats].
Set<String> _codes(List<Json> constats) => <String>{
  for (final c in constats) c['code']! as String,
};

/// Constats bien formés : code connu, message, semaine dans l'horizon.
void _bienFormes(List<Json> constats, int horizon, String quoi) {
  for (final c in constats) {
    expect(criteresSecurite.containsKey(c['code']), isTrue, reason: quoi);
    expect(c['message'], isA<String>(), reason: quoi);
    final week = c['week'];
    if (week != null) {
      expect(week, isA<int>(), reason: quoi);
      expect(week as int, inInclusiveRange(0, horizon - 1), reason: quoi);
    }
  }
}

void main() {
  final catalog = loadCatalog();

  test('depuisProfil : champs lus dans le profil de l\'application', () {
    final senior = profileOf('senior_65_forme_generale_3x40');
    final s = ProfilValidation.depuisProfil(senior, debut: _debut);
    // Sans `experience` : débutant (prudent).
    expect(senior.experience, isNull);
    expect(s.niveau, ExperienceLevel.beginner);
    expect(s.prudent, isTrue);
    expect(s.anneeReference, 2026);
    expect(s.age, 2026 - senior.birthYear);
    expect(s.tailleCm, senior.heightCm);
    expect(s.poidsCorpsKg, senior.bodyWeightKg);
    expect(s.genes, hasLength(senior.limitations.length));
    expect(s.semainesEcheance, isNull);
    expect(s.semainesPause, 0);
    expect(
      ProfilValidation.depuisProfil(
        senior,
        debut: _debut,
        niveau: ExperienceLevel.intermediate,
        semainesPause: 4,
      ),
      isA<ProfilValidation>()
          .having((p) => p.niveau, 'niveau', ExperienceLevel.intermediate)
          .having((p) => p.semainesPause, 'semainesPause', 4),
    );

    final avance = profileOf('proprietaire_streetlifting_avance');
    final a = ProfilValidation.depuisProfil(avance, debut: _debut);
    expect(a.niveau, ExperienceLevel.advanced);
    expect(a.prudent, isFalse);
    expect(a.exercicesNonAcquis, avance.cannotDoExerciseIds);
    expect(a.genes, hasLength(avance.limitations.length));
    expect(a.records.length, lessThanOrEqualTo(avance.movementLevels.length));
  });

  for (final cle in const <String>[
    'debutant_forme_generale_maison_2x30',
    'senior_65_forme_generale_3x40',
    'proprietaire_streetlifting_avance',
    'six_jours_musculation_avance_6x75',
    'blessure_epaule_musculation_3x60',
  ]) {
    test('$cle : constats bien formés, déterministes, ceux des blocs', () {
      final profil = profileOf(cle);
      final bloc = _bloc(profil);
      final horizon = bloc.pass1.weeks;
      final validation = ProfilValidation.depuisProfil(profil, debut: _debut);
      final valider = validateurSecurite(
        catalog: catalog,
        profil: validation,
        blockWeeks: const <int>[0],
        horizonSemaines: horizon,
      );
      final blocs = _json(<ProgramBlock>[bloc]);
      final premiers = valider(blocs);
      _bienFormes(premiers, horizon, cle);
      expect(jsonEncode(valider(blocs)), jsonEncode(premiers));
      expect(
        jsonEncode(premiers),
        jsonEncode(<Json>[
          for (final c in constatsSecurite(
            catalog: catalog,
            profil: validation,
            blocs: <ProgramBlock>[bloc],
            horizonSemaines: horizon,
          ))
            c.toJson(),
        ]),
      );
      // Horizon d'une semaine : seule la première semaine est lue.
      for (final c in validateurSecurite(
        catalog: catalog,
        profil: validation,
        horizonSemaines: 1,
      )(blocs)) {
        final week = c['week'];
        expect(week == null || week == 0, isTrue, reason: '$cle : $c');
      }
    });
  }

  test('échec prescrit à un débutant : echec_risque', () {
    final profil = profileOf('debutant_forme_generale_maison_2x30');
    final bloc = _bloc(profil);
    final horizon = bloc.pass1.weeks;
    final valider = validateurSecurite(
      catalog: catalog,
      profil: ProfilValidation.depuisProfil(profil, debut: _debut),
      horizonSemaines: horizon,
    );
    final blocs = _json(<ProgramBlock>[bloc]);
    // Toutes les séries de travail à l'échec (10 flammes : RIR 0).
    for (final w in jl(jm(blocs.first['pass2'])['weeks'])) {
      for (final d in jl(jm(w)['days'])) {
        for (final i in jl(jm(d)['items'])) {
          final item = jm(i);
          if (item['kind'] != 'warmup' && item['kind'] != 'test') {
            item['targetFlames'] = 10;
          }
        }
      }
    }
    final apres = valider(blocs);
    _bienFormes(apres, horizon, 'échec');
    expect(_codes(apres), contains('echec_risque'));
  });

  test('branché sur Planification : blocs modulés validés', () {
    final params = readJsonObject('reference/params/koach_params_v1.json');
    final vecteurs = readJsonObject(
      'reference/qualites/vecteurs_qualites_v1.json',
    );
    final fiches = <String, Json>{
      for (final e in jm(vecteurs['exercices']).entries) e.key: jm(e.value),
    };
    final profil = profileOf('proprietaire_streetlifting_avance');
    final bloc = _bloc(profil);
    final horizon = bloc.pass1.weeks;
    final validation = ProfilValidation.depuisProfil(profil, debut: _debut);
    final valider = validateurSecurite(
      catalog: catalog,
      profil: validation,
      blockWeeks: const <int>[0],
      horizonSemaines: horizon,
    );
    final planification = Planification(
      params,
      fiches,
      valider,
      <String, Object?>{'trajectoires': 10},
    );
    final blocs = _json(<ProgramBlock>[bloc]);
    planification.chargerReference(
      blocs,
      const <int>[0],
      horizon,
      poidsCorps: profil.bodyWeightKg,
    );
    final modules = planification.blocsModules(<int, Json>{
      for (var w = 0; w < planification.semaines.length; w++)
        w: <String, Object?>{
          'volume': List<double>.filled(nq, 1.15),
          'intensite': w.isOdd ? -0.05 : 0.05,
        },
    });
    final constats = valider(modules);
    _bienFormes(constats, horizon, 'modulés');
    expect(
      jsonEncode(constats),
      jsonEncode(
        constatsDesBlocs(
          modules,
          catalog: catalog,
          profil: validation,
          horizonSemaines: horizon,
          blockWeeks: const <int>[0],
        ),
      ),
    );
  });
}
