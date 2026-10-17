// Validateur de sécurité de Koach copié dans kalis_adapt (lot KM2,
// `package:kalis_adapt/validateur.dart`) contre celui du banc
// (`safetyFindings` par `KmConstatsSaison`, le validateur de
// `PolitiqueKoach`) : mêmes constats, à l'identique (JSON de
// `Finding.toJson`, message compris, même ordre), sur
// - les blocs de référence (`kmReferenceSeason`) de tous les profils du
//   banc et de tous leurs scénarios applicables, avec et sans `blockWeeks`,
//   à l'horizon de la saison et à quatre semaines ;
// - des blocs modulés par `Planification.blocsModules` aux plafonds
//   (volume ±15 %, intensité ±5 %, constants ou alternés d'une semaine à
//   l'autre).
// Le profil de validation est construit depuis les champs du banc
// (`BenchProfile`) et depuis le JSON du banc (`benchJson` de la saison).
//
// La correspondance du profil de l'application
// (`ProfilValidation.depuisProfil`) est vérifiée sur le profil adapté de
// chaque profil du banc.
import 'dart:convert';

import 'package:kalis_adapt/koach.dart' as kc;
import 'package:kalis_adapt/validateur.dart' as va;
import 'package:kalis_bench/kalis_bench.dart';
import 'package:kalis_bench/src/km/criteres_moteur.dart' show KmConstatsSaison;
import 'package:kalis_bench/src/km/km_export.dart'
    show KmSeason, kmReferenceSeason;
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show KalisPlan;
import 'package:test/test.dart';

import 'support.dart';

/// Référence Python de kalis_adapt (paquet voisin) : paramètres de Koach.
const String _reference = '../kalis_adapt/reference';

/// Profil de validation lu dans les champs du profil du banc [b] ; poids
/// de corps des charges : celui du profil des moteurs [moteurs].
va.ProfilValidation profilDuBanc(BenchProfile b, AthleteProfile moteurs) {
  final screening = b.core['healthScreening'];
  return va.ProfilValidation(
    niveau: ExperienceLevel.values[b.level.index],
    anneeNaissance: b.birthYear,
    tailleCm: b.heightCm,
    poidsCorpsKg: moteurs.bodyWeightKg,
    records: <va.RecordValidation>[
      for (final r in b.records)
        va.RecordValidation(
          exerciseId: r.exerciseId,
          mesure: r.measure,
          valeur: r.value,
          distanceMetres: r.distanceMeters,
        ),
    ],
    exercicesConnus: benchStrings(b.core, 'knownExerciseIds'),
    exercicesNonAcquis: benchStrings(b.core, 'cannotDoExerciseIds'),
    prudent:
        screening is Map<String, Object?> &&
        screening['outcome'] == HealthScreeningOutcome.cautious.code,
    genes: <va.GeneValidation>[
      for (final i in b.injuries)
        va.GeneValidation(
          zone: i.zone,
          articulation: i.joint,
          gene: i.discomfort,
          antecedent: i.status == 'history',
          moisDepuis: i.monthsAgo,
          libelle: i.label,
        ),
    ],
    semainesEcheance: b.mainEvent?.weeksOut,
    semainesPause: b.breakWeeks,
  );
}

/// Blocs JSON d'une saison exportée.
List<kc.Json> _blocs(kc.Json saison) => <kc.Json>[
  for (final b in kc.jl(saison['blocks'])) kc.jm(b),
];

/// Semaines de début des blocs d'une saison exportée.
List<int> _blockWeeks(kc.Json saison) => <int>[
  for (final w in kc.jl(saison['blockWeeks'])) kc.ent(w),
];

/// Plan de modulation de toutes les semaines : facteur de volume
/// [volume] et écart d'intensité [intensite] ; alterné : le signe de
/// l'écart s'inverse d'une semaine à l'autre.
Map<int, kc.Json> _plan(
  int semaines,
  double volume,
  double intensite, {
  bool alterne = false,
}) => <int, kc.Json>{
  for (var w = 0; w < semaines; w++)
    w: <String, Object?>{
      'volume': List<double>.filled(
        kc.nq,
        alterne && w.isOdd ? 2 - volume : volume,
      ),
      'intensite': alterne && w.isOdd ? -intensite : intensite,
    },
};

void main() {
  final catalog = loadCatalog();
  final plan = KalisPlan();
  final parametres = readJsonObject('$_reference/params/koach_params_d4.json');
  final vecteurs = readJsonObject(
    '$_reference/qualites/vecteurs_qualites_v1.json',
  );
  final fiches = <String, kc.Json>{
    for (final e in kc.jm(vecteurs['exercices']).entries) e.key: kc.jm(e.value),
  };
  final profils = <String, Map<String, Object?>>{
    for (final p in loadBenchProfiles())
      p.key: readJsonObject('profiles/${p.key}.json'),
  };
  final cles = profils.keys.toList()..sort();

  test('27 profils du banc', () {
    expect(cles, hasLength(27));
  });

  // Codes, semaines, jours et exercices des constats hors du plan de
  // référence, cumulés sur toutes les saisons (les plans modulés doivent en
  // produire : sinon la comparaison ne dirait rien).
  var ajoutsModules = 0;
  var saisonsVues = 0;

  for (final cle in cles) {
    test('$cle : mêmes constats que le banc (référence et blocs modulés)', () {
      final json = profils[cle]!;
      for (final scenario in SeasonScenario.values) {
        if (!seasonScenarioApplies(json, scenario)) {
          continue;
        }
        final saison = kc.jm(
          jsonDecode(
            jsonEncode(
              kmReferenceSeason(catalog, plan, json, scenario, truthSeeds: 0),
            ),
          ),
        );
        final quoi = '$cle / ${scenario.code}';
        saisonsVues++;
        final banc = KmConstatsSaison(catalog, json, saison);
        final season = KmSeason(catalog, json, scenario);
        final moteurs = season.adapted.profile;
        // Le poids des charges (profil des moteurs) est celui de l'indice
        // de masse corporelle (profil du banc) : un seul champ suffit.
        expect(season.bench.bodyWeightKg, moteurs.bodyWeightKg, reason: quoi);
        final parChamps = profilDuBanc(season.bench, moteurs);
        final profil0 = AthleteProfile.fromJson(
          kc.jm(kc.jm(kc.jl(saison['profiles'])[0])['profile']),
        );
        final parJson = va.ProfilValidation.depuisJsonBanc(
          kc.jm(saison['benchJson']),
          poidsCorpsKg: profil0.bodyWeightKg,
        );
        final weeks = kc.ent(saison['weeks']);
        final blockWeeks = _blockWeeks(saison);
        final blocs = _blocs(saison);

        // Blocs de référence, servis et entiers, deux horizons.
        final attendu = jsonEncode(banc.constats());
        for (final profil in <va.ProfilValidation>[parChamps, parJson]) {
          final valider = va.validateurSecurite(
            catalog: catalog,
            profil: profil,
            blockWeeks: blockWeeks,
            horizonSemaines: weeks,
          );
          expect(jsonEncode(valider(blocs)), attendu, reason: quoi);
        }
        for (final horizon in <int>[weeks, 4]) {
          for (final servis in <List<int>?>[blockWeeks, null]) {
            final view = ProgramView(
              catalog,
              BenchProgram(
                bench: season.bench,
                adapted: season.adapted,
                request: PlanRequest(
                  profile: moteurs,
                  seed: 0,
                  startDate: benchStartDate,
                  locks: const <PlanLock>[],
                ),
                blocks: va.blocsServis(<ProgramBlock>[
                  for (final b in blocs) ProgramBlock.fromJson(b),
                ], servis),
                horizonWeeks: horizon,
              ),
            );
            final duBanc = <kc.Json>[
              for (final f in safetyFindings(view, season.bench)) f.toJson(),
            ];
            final copie = va.constatsDesBlocs(
              blocs,
              catalog: catalog,
              profil: parChamps,
              horizonSemaines: horizon,
              blockWeeks: servis,
            );
            expect(
              jsonEncode(copie),
              jsonEncode(duBanc),
              reason: '$quoi, horizon $horizon, blockWeeks $servis',
            );
          }
        }

        // Blocs modulés aux plafonds de la planification.
        final valider = va.validateurSecurite(
          catalog: catalog,
          profil: parChamps,
          blockWeeks: blockWeeks,
          horizonSemaines: weeks,
        );
        final planification = kc.Planification(
          parametres,
          fiches,
          banc.validateur,
          <String, Object?>{'trajectoires': 10},
        );
        planification.chargerReference(
          blocs,
          blockWeeks,
          weeks,
          poidsCorps: moteurs.bodyWeightKg,
        );
        final reference = <String>{
          for (final c in banc.constats())
            jsonEncode(<Object?>[
              c['code'],
              c['week'],
              c['dayIndex'],
              c['exerciseId'],
            ]),
        };
        final n = planification.semaines.length;
        final plans = <String, Map<int, kc.Json>>{
          'plus': _plan(n, 1.15, 0.05),
          'moins': _plan(n, 0.85, -0.05),
          'alterne': _plan(n, 1.15, 0.05, alterne: true),
          'alterne_inverse': _plan(n, 0.85, -0.05, alterne: true),
        };
        for (final entry in plans.entries) {
          final modules = planification.blocsModules(entry.value);
          final duBanc = banc.validateur(modules);
          expect(
            jsonEncode(valider(modules)),
            jsonEncode(duBanc),
            reason: '$quoi, plan ${entry.key}',
          );
          for (final c in duBanc) {
            final k = jsonEncode(<Object?>[
              c['code'],
              c['week'],
              c['dayIndex'],
              c['exerciseId'],
            ]);
            if (!reference.contains(k)) {
              ajoutsModules++;
            }
          }
        }
      }
    }, timeout: const Timeout(Duration(minutes: 10)));
  }

  test('les plans modulés ajoutent des constats (comparaison utile)', () {
    if (saisonsVues == 0) {
      markTestSkipped('aucune saison comparée (tests filtrés)');
      return;
    }
    expect(ajoutsModules, greaterThan(0));
  });

  test('depuisProfil : correspondance des champs sur les profils adaptés', () {
    for (final cle in cles) {
      final bench = BenchProfile.fromJson(profils[cle]!);
      final adapted = adaptProfile(bench, catalog: catalog);
      final duBanc = profilDuBanc(bench, adapted.profile);
      final app = va.ProfilValidation.depuisProfil(
        adapted.profile,
        debut: benchStartDate,
      );
      expect(app.niveau, duBanc.niveau, reason: cle);
      expect(app.anneeNaissance, duBanc.anneeNaissance, reason: cle);
      expect(app.anneeReference, duBanc.anneeReference, reason: cle);
      expect(app.age, duBanc.age, reason: cle);
      expect(app.tailleCm, duBanc.tailleCm, reason: cle);
      expect(app.poidsCorpsKg, duBanc.poidsCorpsKg, reason: cle);
      expect(
        app.indiceMasseCorporelle,
        duBanc.indiceMasseCorporelle,
        reason: cle,
      );
      expect(
        <Object?>[
          for (final r in app.records)
            <Object?>[r.exerciseId, r.mesure, r.valeur, r.distanceMetres],
        ],
        <Object?>[
          for (final r in duBanc.records)
            <Object?>[r.exerciseId, r.mesure, r.valeur, r.distanceMetres],
        ],
        reason: cle,
      );
      expect(app.exercicesConnus, duBanc.exercicesConnus, reason: cle);
      expect(app.exercicesNonAcquis, duBanc.exercicesNonAcquis, reason: cle);
      expect(app.prudent, duBanc.prudent, reason: cle);
      expect(app.semainesEcheance, duBanc.semainesEcheance, reason: cle);
      // Pause : borne basse de la tranche ; seul le seuil de deux
      // semaines compte (une semaine d'arrêt est lue comme deux :
      // prudent).
      expect(
        app.semainesPause >= 2,
        duBanc.semainesPause >= 2 || duBanc.semainesPause == 1,
        reason: cle,
      );
      expect(app.genes, hasLength(duBanc.genes.length), reason: cle);
      for (var k = 0; k < app.genes.length; k++) {
        final a = app.genes[k];
        final b = duBanc.genes[k];
        expect(a.articulationCatalogue, b.articulationCatalogue, reason: cle);
        expect(a.gene, b.gene, reason: cle);
        // Gêne récente : l'application ne distingue pas gêne présente et
        // antécédent ; elle est au moins aussi prudente que le banc.
        if (b.recente) {
          expect(a.recente, isTrue, reason: cle);
        }
      }
    }
  });
}
