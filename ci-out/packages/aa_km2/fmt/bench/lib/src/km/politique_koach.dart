/// Politique du banc qui fait conduire la saison par Koach 1.0 (lot KM2) :
/// portage de `kalis_adapt/reference/banc/politique_koach.py`
/// (`PolitiqueKoach`), `extensions_koach.py` (`PolitiqueBriques`, parties
/// banc : utilisateur simulé, réponses au diagnostic, propositions d'essai,
/// journaux) et `planification_banc.py` / `campagne.py`
/// (`PlanificationBanc`, `PlanificationCampagne`).
///
/// Différence voulue avec la référence (`reference/PORTAGE_BANC.md`) : la
/// façade Dart (`package:kalis_adapt/koach.dart`) applique elle-même les
/// crochets d'extension. La politique lui passe donc les items ÉCRITS bruts
/// du jour, verse l'événement `reference` au début de la saison (à la place
/// du constructeur de `PlanificationBanc`) et `cibles` aux changements de
/// profil, met `jour_index` dans le contexte de `seance_debut` et verse la
/// réponse au diagnostic (événement `decision`) avant `plan`.
///
/// Validateur de la planification : constats de sécurité du banc
/// (`safetyFindings` sur la vue des blocs, comme `kmSafetyOfBlocks` ; port
/// Python : `securite_banc.constats_saison(saison, infos, blocs=blocs)`).
///
/// Dart pur : aucun accès disque (paramètres et fiches sont passés décodés).
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:kalis_adapt/kalis_adapt.dart' show ExerciseBook;
import 'package:kalis_adapt/koach.dart' as kc;
import 'package:kalis_core/kalis_core.dart'
    show AthleteProfile, BodyZone, Catalog, PlanLock, PlanRequest, ProgramBlock;
import 'package:kalis_plan/kalis_plan.dart' show coachPainStopHits;

import '../adapter.dart' show AdaptedProfile, benchStartDate;
import '../analysis.dart' show ProgramView;
import '../profile.dart' show BenchProfile;
import '../program.dart' show BenchProgram;
import '../safety.dart' show safetyFindings;
import 'km_export.dart' show kmServedBlocks;
import 'meneur.dart';

// ---------------------------------------------------------------------------
// Outils (sémantique Python)
// ---------------------------------------------------------------------------

/// `d.get(k, defaut)`.
Object? _pkGet(Json d, String k, Object? defaut) =>
    d.containsKey(k) ? d[k] : defaut;

/// `round(x, n)` de Python (n ≥ 0) : arrondi correct de la valeur binaire
/// exacte de [x] à [n] décimales, demi au pair, relu en double.
double _pkRound(double x, int n) {
  if (!x.isFinite || x == 0.0) {
    return x;
  }
  final b = ByteData(8)..setFloat64(0, x);
  final hi = b.getUint32(0);
  final lo = b.getUint32(4);
  final negatif = (hi >> 31) == 1;
  final e = (hi >> 20) & 0x7FF;
  var m = (BigInt.from(hi & 0xFFFFF) << 32) | BigInt.from(lo);
  int p2;
  if (e == 0) {
    p2 = -1074;
  } else {
    m = m | (BigInt.one << 52);
    p2 = e - 1075;
  }
  // |x| · 10^n = num / den exactement.
  var num0 = m * BigInt.from(10).pow(n);
  var den = BigInt.one;
  if (p2 >= 0) {
    num0 = num0 << p2;
  } else {
    den = BigInt.one << -p2;
  }
  var q = num0 ~/ den;
  final r2 = (num0 - q * den) * BigInt.two;
  if (r2 > den || (r2 == den && q.isOdd)) {
    q += BigInt.one;
  }
  final v = double.parse('${q}e-$n');
  return negatif ? -v : v;
}

/// Identifiants de course de qualité (`QUALITY_RUN_IDS` de
/// `banc/verite_endurance.py`).
const List<String> _pkQualityRunIds = <String>[
  'fractionne',
  'seuil',
  'tempo',
  '30-30',
  'sprint',
  'cotes',
  'fartlek',
  'intervalles',
  'navettes',
  'accelerations',
];

/// `prescribed_seconds` (`banc/verite_endurance.py`).
double _pkSecondesPrescrites(Json item, num sets, double speed) {
  var s = item['secondsHigh'];
  s ??= item['secondsLow'];
  if (s != null) {
    return ((s as num) * sets).toDouble();
  }
  final m = item['distanceMeters'];
  if (m != null && speed > 0) {
    return (m as num) * sets / speed;
  }
  return 0.0;
}

/// Champs d'un item écrit que Koach lit pour le volume d'une séance manquée
/// ou restante (`CHAMPS_VOLUME`).
const List<String> _pkChampsVolume = <String>[
  'slotId',
  'exerciseId',
  'kind',
  'sets',
  'targetFlames',
  'secondsLow',
  'secondsHigh',
];

/// `items_volume`.
List<Json> _pkItemsVolume(List<Object?> items) => <Json>[
  for (final it in items)
    <String, Object?>{for (final k in _pkChampsVolume) k: kc.jm(it)[k]},
];

/// Champs d'une série journalisée versés à Koach (`_serie`).
const List<String> _pkChampsSerie = <String>[
  'exerciseId',
  'slotId',
  'setIndex',
  'kind',
  'reps',
  'seconds',
  'flames',
  'failed',
  'target',
  'restSeconds',
  'technique',
  'role',
  'repere',
];

/// `securite_banc.allure_course` : meilleure allure chronométrée × 0,9,
/// sinon 2,5 m/s.
double _pkAllureCourse(Json benchJson) {
  var best = 0.0;
  for (final r0 in kc.listeOuVide(benchJson['records'])) {
    final r = kc.jm(r0);
    final m = r['distanceMeters'];
    final v = kc.dbl(r['value']);
    if (r['measure'] == 'time_seconds' && m != null && v > 0) {
      final s = kc.dbl(m) / v;
      if (s > best) {
        best = s;
      }
    }
  }
  return best > 0 ? best * 0.9 : 2.5;
}

/// `profil_koach` : profil lu par Koach.
Json _pkProfilKoach(Json saison, Json profil) {
  final declares = <String, Object?>{};
  for (final lv0 in kc.listeOuVide(profil['movementLevels'])) {
    final lv = kc.jm(lv0);
    if (kc.vrai(lv['known']) && kc.vrai(lv['low']) && kc.vrai(lv['high'])) {
      declares[lv['exerciseId']! as String] = <Object?>[
        lv['measure'],
        math.sqrt((lv['low']! as num) * (lv['high']! as num)),
      ];
    }
  }
  final fragiles = <Object?>[];
  for (final lim0 in kc.listeOuVide(profil['limitations'])) {
    final lim = kc.jm(lim0);
    final z = lim['zone'];
    if (kc.vrai(z)) {
      fragiles.add(<String, Object?>{
        'zone': z,
        'since': lim['since'],
        'discomfort': lim['discomfort'],
      });
    }
  }
  return <String, Object?>{
    'niveau': saison['level'],
    'sexe': profil['sex'],
    'poids_kg': profil['bodyWeightKg'],
    'declares': declares,
    'zones_fragiles': fragiles,
    'allure_course': _pkAllureCourse(kc.dictOuVide(saison['benchJson'])),
  };
}

/// `cibles_du_profil` : buts de performance du profil → {exercice : valeur
/// visée} ; pour un exercice chargé, la charge TOTALE.
Json _pkCiblesDuProfil(Json profil, Map<String, Json> fiches) {
  final out = <String, Object?>{};
  final bw0 = profil['bodyWeightKg'];
  final num bw = kc.vrai(bw0) ? bw0! as num : 72.0;
  for (final g0 in kc.listeOuVide(profil['goals'])) {
    final g = kc.jm(g0);
    final ex = g['exerciseId'] as String?;
    final v = g['targetValue'] as num?;
    if (ex == null || v == null) {
      continue;
    }
    final fiche = fiches[ex];
    if (fiche == null) {
      continue;
    }
    final metrique = g['metric'];
    if (metrique == 'one_rm_kg' && fiche['type'] == 'charge') {
      out[ex] = v + (_pkGet(fiche, 'fraction', 0.0)! as num) * bw;
    } else if (metrique == 'max_reps' && fiche['type'] == 'reps') {
      out[ex] = v.toDouble();
    } else if (metrique == 'max_hold_seconds' && fiche['type'] == 'tenue') {
      out[ex] = v.toDouble();
    }
  }
  return out;
}

/// Cibles de tentative du profil : {exercice : charge visée} des buts
/// `one_rm_kg` (`PolitiqueKoach.cibles`, posées en `koachCible`).
Json _pkCiblesTentatives(Json profil) {
  final out = <String, Object?>{};
  for (final g0 in kc.listeOuVide(profil['goals'])) {
    final g = kc.jm(g0);
    if (g['metric'] == 'one_rm_kg' && kc.vrai(g['targetValue'])) {
      out[g['exerciseId']! as String] = g['targetValue'];
    }
  }
  return out;
}

/// `principaux_de` : exercices des emplacements de rôle `main`, dans
/// l'ordre.
List<String> _pkPrincipauxDe(Json saison) {
  final out = <String>[];
  for (final b in kc.jl(saison['blocks'])) {
    for (final d in kc.jl(kc.jm(kc.jm(b)['pass1'])['days'])) {
      for (final s0 in kc.jl(kc.jm(d)['slots'])) {
        final s = kc.jm(s0);
        final ex = s['exerciseId']! as String;
        if (s['role'] == 'main' && !out.contains(ex)) {
          out.add(ex);
        }
      }
    }
  }
  return out;
}

/// `echeance_de` : prochain jour d'épreuve connu à la semaine [semaine], au
/// jour [jour] ou après, ou null.
int? _pkEcheanceDe(Json saison, int semaine, [int jour = 0]) {
  final parSemaine = kc.jl(saison['eventDaysByWeek']);
  if (semaine >= parSemaine.length) {
    return null;
  }
  int? best;
  for (final d0 in kc.jl(parSemaine[semaine])) {
    final d = kc.ent(d0);
    if (d >= jour && (best == null || d < best)) {
      best = d;
    }
  }
  return best;
}

/// `lifts_principaux` : mouvements principaux chargés de la saison (triés).
List<String> _pkLiftsPrincipaux(Json saison, Map<String, Json> fiches) {
  final ids = <String>{};
  for (final b in kc.jl(saison['blocks'])) {
    for (final d in kc.jl(kc.jm(kc.jm(b)['pass1'])['days'])) {
      for (final s0 in kc.jl(kc.jm(d)['slots'])) {
        final s = kc.jm(s0);
        final ex = s['exerciseId'];
        if (s['role'] == 'main' && ex is String) {
          final f = fiches[ex];
          if (f != null && f['type'] == 'charge') {
            ids.add(ex);
          }
        }
      }
    }
  }
  return ids.toList()..sort();
}

/// `jours_echeance` : jours d'épreuve de la saison (triés).
List<int> _pkJoursEcheance(Json saison) {
  final out = <int>{};
  for (final jours in kc.listeOuVide(saison['eventDaysByWeek'])) {
    for (final j in kc.jl(jours)) {
      out.add(kc.ent(j));
    }
  }
  return out.toList()..sort();
}

// ---------------------------------------------------------------------------
// Utilisateur simulé : diagnostic (VeriteScenario)
// ---------------------------------------------------------------------------

/// Ce que l'utilisateur simulé sait de sa situation (`VeriteScenario`) :
/// vérité du scénario (`specJson`) et état de douleur de l'athlète simulé.
final class _VeriteScenario {
  _VeriteScenario(Json saison) : scenario = saison['scenario'] {
    final sp = kc.dictOuVide(saison['specJson']);
    final mf = sp['illnessFromDay'];
    if (mf != null) {
      maladie = (kc.ent(mf), kc.ent(mf) + kc.ent(_pkGet(sp, 'illnessDays', 0)));
    }
    final df = sp['painFromDay'];
    if (df != null) {
      douleur = (
        kc.ent(df),
        kc.ent(df) + kc.ent(_pkGet(sp, 'painDays', 0)),
        sp['painZone'],
        sp['painIntensity'],
      );
    }
    final lf = sp['otherPlaceFromDay'];
    if (lf != null) {
      lieu = (kc.ent(lf), kc.ent(lf) + kc.ent(_pkGet(sp, 'otherPlaceDays', 0)));
    }
    final cf = sp['breakFromDay'];
    if (cf != null) {
      coupure = (kc.ent(cf), kc.ent(cf) + kc.ent(_pkGet(sp, 'breakDays', 0)));
    }
    manques = kc.dbl(_pkGet(sp, 'missRate', 0.08));
  }

  /// La fatigue d'une maladie se fait encore sentir deux semaines.
  static const int apresMaladieJ = 14;

  final Object? scenario;
  (int, int)? maladie;
  (int, int, Object?, Object?)? douleur;
  (int, int)? lieu;
  (int, int)? coupure;
  double manques = 0.08;

  /// Jour de début de la rupture connue du scénario, ou null.
  int? debutRupture() {
    final m = maladie;
    if (m != null) {
      return m.$1;
    }
    final d = douleur;
    if (d != null) {
      return d.$1;
    }
    final c = coupure;
    if (c != null) {
      return c.$1;
    }
    final l = lieu;
    if (l != null) {
      return l.$1;
    }
    return null;
  }

  /// Réponse au diagnostic (`Surveillance.repondre`).
  Json reponse(KmContexte ctx) {
    final j = ctx.simDay;
    final a = ctx.athlete;
    final zone = a.painZone;
    if (a.inPain && zone != null) {
      return <String, Object?>{
        'cause': 'douleur',
        'zone': zone.code,
        'intensite': a.painIntensity,
      };
    }
    final m = maladie;
    if (m != null && m.$1 <= j && j < m.$2 + apresMaladieJ) {
      return <String, Object?>{'cause': 'fatigue'};
    }
    final bilan = ctx.bilan;
    final temps = bilan != null && bilan['minutesAvailable'] != null;
    final l = lieu;
    if ((l != null && l.$1 <= j && j < l.$2) || temps) {
      Object? duree = ctx.budget;
      if (bilan != null && bilan['minutesAvailable'] != null) {
        duree = bilan['minutesAvailable'];
      }
      var choix = 20;
      for (final d in const <int>[20, 30, 45, 60, 75, 90]) {
        if (duree != null && d <= (duree as num)) {
          choix = d;
        }
      }
      return <String, Object?>{
        'cause': 'moins_de_temps',
        'seances_par_semaine': seancesParSemaine(ctx),
        'duree_max_min': choix,
      };
    }
    return <String, Object?>{'cause': 'rien'};
  }

  static int seancesParSemaine(KmContexte ctx) {
    var n = 0;
    for (final s in kc.jl(ctx.saison['sessions'])) {
      if (kc.ent(kc.jl(s)[0]) == ctx.semaine) {
        n += 1;
      }
    }
    return (1 <= n && n <= 7) ? n : (n < 1 ? 1 : 7);
  }
}

// ---------------------------------------------------------------------------
// Extensions du banc (sous-classes des extensions du moteur)
// ---------------------------------------------------------------------------

/// `SurveillanceBanc` : journal des alertes, des diagnostics (réponse
/// versée par la politique avant `plan`) et des semaines allégées appliquées
/// par la façade aux items écrits du jour.
final class _SurveillanceBanc extends kc.Surveillance {
  _SurveillanceBanc(super.params);

  /// Journal du banc.
  final List<Json> journal = <Json>[];

  @override
  void verifier(kc.Koach koach) {
    final avant = List<bool>.of(alertes);
    super.verifier(koach);
    if (!avant.any((x) => x) && alertes.any((x) => x)) {
      journal.add(<String, Object?>{
        'type': 'alerte',
        'jour': koach.jour,
        'semaine': semaine,
        'causes': causes(),
        'p': _pkRound(p, 6),
      });
    }
  }

  @override
  List<Json> itemsDuJour(
    kc.Koach koach,
    kc.ContexteSeance ctx,
    List<Json> items,
  ) {
    final servis = super.itemsDuJour(koach, ctx, items);
    if (!identical(servis, items)) {
      int series(List<Json> l) {
        var n = 0;
        for (final it in l) {
          if (_pkGet(it, 'kind', 'work') == 'work') {
            n += kc.ent(kc.ou(it['sets'], 0));
          }
        }
        return n;
      }

      journal.add(<String, Object?>{
        'type': 'allegement',
        'jour': ctx.jour,
        'series_ecrites': series(items),
        'series_allegees': series(servis),
      });
    }
    return servis;
  }
}

/// `ControleDualBanc` (parties banc) : journal du calibrage chaque fin de
/// semaine et proposition d'un essai N-of-1 (les bras sont appliqués par la
/// façade : `ControleDual.itemsDuJour`, `ControleDual.cibleSerie`, journal
/// commun [journal]).
final class _ControleDualBanc extends kc.ControleDual {
  _ControleDualBanc(
    super.params,
    super.liftsPrincipaux,
    this.graine,
    this.options,
    this.echeances,
  );

  static const int temoinsMax = 6;

  final int graine;
  final Json options;
  final List<int> echeances;

  Json _contexte(kc.Koach koach, int semaine) {
    final jour = 7 * semaine;
    int? ech;
    if (!kc.vrai(options['ignorer_echeance'])) {
      for (final j in echeances) {
        if (j >= jour) {
          ech = ((j - jour) / 7.0).ceil();
          break;
        }
      }
    }
    var alerte = false;
    for (final Object x in koach.extensions) {
      if (x is kc.Surveillance && x.etat()['hors_modele'] == true) {
        alerte = true;
      }
    }
    final douleur = koach.garde.actives().isNotEmpty;
    return <String, Object?>{
      'semaines_avant_echeance': ech,
      'affutage': genre == 'taper',
      'alerte': alerte,
      'douleur': douleur,
    };
  }

  void apresSemaine(kc.Koach koach, int semaine) {
    final (ok, _) = kc.calibre(koach, lifts);
    final demi = <String, Object?>{};
    for (final ex in lifts) {
      final c = koach.modele.capacite(ex);
      if (c != null) {
        demi[ex] = _pkRound(kc.z90 * c.$2, 6);
      }
    }
    var poidsMax = reponse.poids[0];
    for (final p in reponse.poids) {
      if (p > poidsMax) {
        poidsMax = p;
      }
    }
    journal.add(<String, Object?>{
      'type': 'semaine',
      'semaine': semaine,
      'journal': koach.modele.journalSemaines.length,
      'calibre': ok,
      'demi_largeur': demi,
      'entropie': _pkRound(reponse.entropie(), 9),
      'poids_max': _pkRound(poidsMax, 9),
    });
    if (essai != null || !ok || lifts.isEmpty) {
      return;
    }
    final prochaine = semaine + 1;
    // min(lifts, key=(demi.get(ex, 1.0), ex)) : premier minimum.
    String? cible;
    late num cibleDemi;
    for (final ex in lifts) {
      final d = _pkGet(demi, ex, 1.0)! as num;
      if (cible == null ||
          d < cibleDemi ||
          (d == cibleDemi && ex.compareTo(cible) < 0)) {
        cible = ex;
        cibleDemi = d;
      }
    }
    final recents = pre.length >= 8 ? pre.sublist(pre.length - 8) : pre;
    final temoins = <String>[];
    if (recents.isNotEmpty) {
      final cles = kc.jm(recents.last['mu']).keys.toList()..sort();
      for (final ex in cles) {
        if (ex == cible) {
          continue;
        }
        if (recents.every((x) => kc.jm(x['mu']).containsKey(ex))) {
          temoins.add(ex);
        }
      }
    }
    final retenus = temoins.length > temoinsMax
        ? temoins.sublist(0, temoinsMax)
        : temoins;
    final d = <String, Object?>{
      'semaine': prochaine,
      'cible': <String, Object?>{'exerciseId': cible},
      'traites': <Object?>[cible],
      'temoins': retenus,
      'contexte': _contexte(koach, prochaine),
      'graine': graine,
      'n_bras': options['n_bras'],
    };
    koach.observe(<String, Object?>{
      'type': 'decision',
      'jour': 7 * prochaine,
      'essai': d,
    });
    journal.add(<String, Object?>{
      'type': 'proposition',
      'semaine': prochaine,
      'cible': cible,
      'demarre': essai != null,
      'raison': raisons.isNotEmpty ? raisons.last : null,
    });
  }
}

/// Poids vrais de l'utilisateur simulé (probit) : moyennes
/// (`POIDS_MOYENS`).
const List<double> _pkPoidsMoyens = <double>[
  0.9,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  -0.6,
  -0.4,
  0.2,
  -0.3,
  0.1,
  -0.5,
];

/// Écarts-types des poids vrais (`POIDS_SD`).
const List<double> _pkPoidsSd = <double>[
  0.3,
  0.4,
  0.4,
  0.4,
  0.4,
  0.4,
  0.4,
  0.4,
  0.4,
  0.4,
  0.2,
  0.3,
  0.3,
  0.3,
  0.3,
  0.3,
];

/// `UtilisateurSimule` : probit à poids vrais tirés d'une graine,
/// P(accepter | x) = Φ(w·x) ; décisions tirées d'un second générateur.
final class _UtilisateurSimule {
  _UtilisateurSimule(String graineTexte)
    : rng = kc.Mulberry32(
        kc.fnv1a32('koach-adherence-decisions:$graineTexte'),
      ) {
    final r = kc.Mulberry32(kc.fnv1a32('koach-adherence-poids:$graineTexte'));
    w = <double>[
      for (var i = 0; i < kc.adherenceDim; i++)
        _pkPoidsMoyens[i] + _pkPoidsSd[i] * r.gauss(),
    ];
  }

  late final List<double> w;
  final kc.Mulberry32 rng;

  double proba(List<double> x) {
    var s = 0.0;
    for (var i = 0; i < kc.adherenceDim; i++) {
      s += w[i] * x[i];
    }
    return kc.normCdfK(s);
  }

  (bool, double) decider(List<double> x) {
    final p = proba(x);
    return (rng.next() < p, p);
  }
}

/// `AdherenceBanc` : chaque fin de semaine, les hausses et baisses de
/// charge de la première série des mouvements principaux chargés (et les
/// tests) deviennent des propositions que l'utilisateur simulé accepte ou
/// refuse ; la décision est versée au journal du moteur.
final class _AdherenceBanc extends kc.Adherence {
  _AdherenceBanc(Json super.params, String graineTexte, this.avecRaisons)
    : utilisateur = _UtilisateurSimule(graineTexte);

  final _UtilisateurSimule utilisateur;

  /// Un refus d'une hausse (baisse) porte une fois sur deux la raison
  /// « trop lourd » (« trop léger »).
  final bool avecRaisons;

  /// Journal du banc.
  final List<Json> journal = <Json>[];
  int _vu = 0;
  final Map<String, num> _dernier = <String, num>{};

  void apresSemaine(
    kc.Koach koach,
    int semaine,
    KmTour tour,
    PolitiqueKoach politique,
  ) {
    final jour = 7 * (semaine + 1);
    final lignes = tour.sets;
    while (_vu < lignes.length) {
      final row = lignes[_vu];
      _vu += 1;
      if (row['setIndex'] != 0 ||
          !kc.vrai(row['main']) ||
          row['mode'] != 'loaded' ||
          row['loadKg'] == null) {
        continue;
      }
      final ex = row['exerciseId']! as String;
      if (kc.vrai(row['test'])) {
        _proposer(koach, jour, ex, 'test', row, null, null, politique);
        continue;
      }
      final avant = _dernier[ex];
      final charge = row['loadKg']! as num;
      _dernier[ex] = charge;
      if (avant == null || (charge - avant).abs() < 1e-9) {
        continue;
      }
      _proposer(
        koach,
        jour,
        ex,
        charge > avant ? 'charge_plus' : 'charge_moins',
        row,
        avant,
        charge,
        politique,
      );
    }
  }

  void _proposer(
    kc.Koach koach,
    int jour,
    String ex,
    String typ,
    Json row,
    num? depart,
    num? cible,
    PolitiqueKoach politique,
  ) {
    final grille = politique.grilles[ex];
    final double pas = (grille != null && grille.pas > 0) ? grille.pas : 2.5;
    final ctx = <String, Object?>{
      'bilan_bas': false,
      'semaine_allegement': row['weekKind'] == 'deload',
      'refus_recents': refusRecents(jour),
    };
    Json forme0;
    double ampleur;
    if (typ == 'test') {
      forme0 = <String, Object?>{
        'paliers': <Object?>[row['loadKg']],
        'moment': 'debut_de_seance',
        'proba_min': null,
      };
      ampleur = 0.0;
    } else {
      final num dep = depart!;
      forme0 = forme(cible!, dep, pas, typ, ctx);
      ampleur = ((kc.jl(forme0['paliers'])[0]! as num) - dep).abs() / pas;
    }
    final c = Map<String, Object?>.of(ctx);
    c['moment'] = forme0['moment'];
    final x = caracteristiques(typ, ampleur, c);
    final pPredite = proba(x);
    final (accepte, pVraie) = utilisateur.decider(x);
    String? raison;
    if (!accepte &&
        avecRaisons &&
        (typ == 'charge_plus' || typ == 'charge_moins')) {
      if (utilisateur.rng.next() < 0.5) {
        raison = typ == 'charge_plus' ? 'too_heavy' : 'too_light';
      }
    }
    final prop = <String, Object?>{
      'id': 'p$jour-$ex-${journal.length}',
      'type': typ,
      'exerciseId': ex,
      'ampleur': ampleur,
      'charge_kg': row['loadKg'],
      'reps': row['amount'],
      'rir': row['wantRir'],
      'contexte': c,
    };
    koach.observe(<String, Object?>{
      'type': 'decision',
      'jour': jour,
      'proposition': prop,
      'accepte': accepte,
      'raison': raison,
    });
    journal.add(<String, Object?>{
      'jour': jour,
      'exerciseId': ex,
      'type': typ,
      'ampleur': _pkRound(ampleur, 6),
      'depart': depart,
      'cible': cible,
      'paliers': List<Object?>.of(kc.jl(forme0['paliers'])),
      'moment': forme0['moment'],
      'p_predite': _pkRound(pPredite, 9),
      'p_vraie': _pkRound(pVraie, 9),
      'accepte': accepte,
      'raison': raison,
    });
  }
}

// ---------------------------------------------------------------------------
// Politique
// ---------------------------------------------------------------------------

/// Koach 1.0 complet sur le banc (`campagne.politique` : planification,
/// surveillance, contrôle dual, adhérence, dans cet ordre).
final class PolitiqueKoach implements KmPolitique {
  /// [parametres] : fichier de paramètres de Koach décodé
  /// (`params/koach_params_v1.json`) ; [fiches] : champ `exercices` de
  /// `qualites/vecteurs_qualites_v1.json` ; [graine] : graine du banc (essais
  /// du contrôle dual, utilisateur simulé de l'adhérence) ; [briques] :
  /// extensions montées (parmi `planification`, `surveillance`, `dual`,
  /// `adherence`, toujours dans cet ordre) ; [trajectoires] : trajectoires
  /// du jumeau de la planification ; [raisons] : refus motivés de
  /// l'utilisateur simulé ; [optionsDual] : `n_bras`, `ignorer_echeance`.
  PolitiqueKoach({
    required this.catalog,
    required this.parametres,
    required this.fiches,
    this.graine = 0,
    this.briques = const <String>[
      'planification',
      'surveillance',
      'dual',
      'adherence',
    ],
    this.trajectoires = 1000,
    this.raisons = false,
    Json? optionsDual,
  }) : optionsDual = Map<String, Object?>.of(
         optionsDual ?? const <String, Object?>{},
       );

  final Catalog catalog;
  final Json parametres;
  final Map<String, Json> fiches;
  final int graine;
  final List<String> briques;
  final int trajectoires;
  final bool raisons;
  final Json optionsDual;

  @override
  String get nom => 'koach_1_0';

  /// Moteur de la saison en cours (créé par [debut]).
  late kc.Koach koach;

  late Json _saison;
  final Map<String, kc.Grille> _grilles = <String, kc.Grille>{};
  final Map<String, (Json, Set<String>)> _zones =
      <String, (Json, Set<String>)>{};
  int _vus = 0;
  Json _cibles = <String, Object?>{};
  final Map<int, (int, Object?, List<Json>)> _ecrits =
      <int, (int, Object?, List<Json>)>{};
  final Map<int, List<int>> _parSemaine = <int, List<int>>{};
  List<Object?> _manquees = <Object?>[];
  kc.Planification? _planification;
  _SurveillanceBanc? _surveillance;
  _VeriteScenario? _verite;

  /// Grilles de charge du profil, par exercice.
  Map<String, kc.Grille> get grilles => _grilles;

  /// Planification de la saison (null sans planificateur).
  kc.Planification? get planification => _planification;

  /// Prévisions de P(réussite) de la planification (`[]` sans elle).
  List<Json> get previsions => _planification?.previsions ?? const <Json>[];

  /// Validateur de sécurité de la saison : constats de `safetyFindings` sur
  /// les blocs (servis jusqu'à `blockWeeks`, horizon de la saison), comme
  /// `securite_banc.constats_saison(saison, infos, blocs=blocs)`.
  kc.Validateur _validateur(Json saison) {
    final bench = BenchProfile.fromJson(kc.jm(saison['benchJson']));
    final profil0 = AthleteProfile.fromJson(
      kc.jm(kc.jm(kc.jl(saison['profiles'])[0])['profile']),
    );
    final adapted = AdaptedProfile(profil0, const <String>[]);
    final request = PlanRequest(
      profile: profil0,
      seed: 0,
      startDate: benchStartDate,
      locks: const <PlanLock>[],
    );
    final bw0 = saison['blockWeeks'];
    final List<int>? blockWeeks = bw0 == null
        ? null
        : <int>[for (final w in kc.jl(bw0)) kc.ent(w)];
    final horizon = kc.ent(saison['weeks']);
    return (List<Json> blocs) {
      final blocks = <ProgramBlock>[
        for (final b in blocs) ProgramBlock.fromJson(b),
      ];
      final view = ProgramView(
        catalog,
        BenchProgram(
          bench: bench,
          adapted: adapted,
          request: request,
          blocks: kmServedBlocks(blocks, blockWeeks),
          horizonWeeks: horizon,
        ),
      );
      return <Json>[for (final f in safetyFindings(view, bench)) f.toJson()];
    };
  }

  @override
  void debut(Json saison, Json profil, ExerciseBook livre) {
    _saison = saison;
    koach = kc.Koach(parametres, fiches, _pkProfilKoach(saison, profil));
    _planification = null;
    _surveillance = null;
    _verite = null;
    for (final b in const <String>[
      'planification',
      'surveillance',
      'dual',
      'adherence',
    ]) {
      if (!briques.contains(b)) {
        continue;
      }
      if (b == 'planification') {
        final pl = kc.Planification(
          parametres,
          koach.fiches,
          _validateur(saison),
          <String, Object?>{'trajectoires': trajectoires},
        );
        _planification = pl;
        koach.extensions.add(pl);
      } else if (b == 'surveillance') {
        final sv = _SurveillanceBanc(parametres);
        _surveillance = sv;
        _verite = _VeriteScenario(saison);
        koach.extensions.add(sv);
      } else if (b == 'dual') {
        koach.extensions.add(
          _ControleDualBanc(
            parametres,
            _pkLiftsPrincipaux(saison, koach.fiches),
            graine,
            optionsDual,
            _pkJoursEcheance(saison),
          ),
        );
      } else {
        koach.extensions.add(
          _AdherenceBanc(
            parametres,
            '${saison['key']}:${saison['scenario']}:$graine',
            raisons,
          ),
        );
      }
    }
    _grilles.clear();
    _zones.clear();
    for (final e in catalog.exercises) {
      final info = livre.find(e.id);
      if (info == null) {
        continue;
      }
      _grilles[e.id] = kc.Grille(
        info.grid.step,
        info.grid.minimum,
        info.grid.dumbbellRule,
      );
      _zones[e.id] = (
        <String, Object?>{
          for (final z in BodyZone.values) z.code: info.zoneLevel(z),
        },
        <String>{
          for (final z in BodyZone.values)
            if (coachPainStopHits(info.exercise, z)) z.code,
        },
      );
    }
    _vus = 0;
    _cibles = _pkCiblesTentatives(profil);
    _ecrits.clear();
    _parSemaine.clear();
    for (final s0 in kc.listeOuVide(saison['sessions'])) {
      final s = kc.jl(s0);
      final g = kc.ent(s[0]);
      final bi = kc.ent(s[1]);
      final wb = s[2];
      final di = s[3];
      final simDay = kc.ent(s[4]);
      final bloc = kc.jm(kc.jl(saison['blocks'])[bi]);
      for (final w0 in kc.jl(kc.jm(bloc['pass2'])['weeks'])) {
        final w = kc.jm(w0);
        if (w['weekIndex'] == wb) {
          for (final d0 in kc.jl(w['days'])) {
            final d = kc.jm(d0);
            if (d['dayIndex'] == di) {
              _ecrits[simDay] = (
                g,
                w['kind'],
                _pkItemsVolume(kc.jl(d['items'])),
              );
            }
          }
        }
      }
      _parSemaine.putIfAbsent(g, () => <int>[]).add(simDay);
    }
    _manquees = <Object?>[];
    // Plan de référence de la planification (à la place du constructeur de
    // `PlanificationBanc`) : semaine 0.
    koach.observe(<String, Object?>{
      'type': 'reference',
      'blocs': saison['blocks'],
      'block_weeks': saison['blockWeeks'],
      'horizon': saison['weeks'],
      'cibles': _pkCiblesDuProfil(profil, koach.fiches),
      'echeance_jour': _pkEcheanceDe(saison, 0),
      'echeances_par_semaine': saison['eventDaysByWeek'],
      'principaux': _pkPrincipauxDe(saison),
      'poids_corps': profil['bodyWeightKg'],
      'cibles_tentatives': Map<String, Object?>.of(_cibles),
      'semaine': 0,
    });
  }

  @override
  void changementProfil(int semaine, Json profil) {
    _cibles = _pkCiblesTentatives(profil);
    koach.observe(<String, Object?>{
      'type': 'cibles',
      'semaine': semaine,
      'cibles': _pkCiblesDuProfil(profil, koach.fiches),
      'cibles_tentatives': Map<String, Object?>.of(_cibles),
    });
  }

  @override
  void debutSemaine(int semaine) {}

  @override
  void seanceManquee(int semaine, int simDay) {
    koach.observe(<String, Object?>{
      'type': 'seance_manquee',
      'jour': simDay,
      'semaine': semaine,
    });
    final e = _ecrits[simDay];
    if (e != null) {
      _manquees.add(<String, Object?>{
        'semaine': e.$1,
        'genre': e.$2,
        'items': kc.copieProfonde(e.$3),
      });
    }
  }

  @override
  Json planifier(KmContexte ctx) {
    _vus = 0;
    final jours = List<int>.of(_parSemaine[ctx.semaine] ?? const <int>[])
      ..sort();
    final reste = <Object?>[
      for (final j in jours)
        if (j > ctx.simDay && _ecrits.containsKey(j))
          kc.copieProfonde(_ecrits[j]!.$3),
    ];
    final contexte = <String, Object?>{
      'genre': ctx.genreSemaine,
      'intention': ctx.intention,
      'jour_evenement': ctx.jourEvenement,
      'budget': ctx.budget,
      'lieu': ctx.lieu,
      'semaine': ctx.semaine,
      'manquees': _manquees,
      'reste_semaine': reste,
      'jour_index': ctx.jourIndex,
    };
    _manquees = <Object?>[];
    koach.observe(<String, Object?>{
      'type': 'seance_debut',
      'jour': ctx.simDay,
      'bilan': ctx.bilan,
      'poids_kg': null,
      'contexte': contexte,
    });
    // Réponse au diagnostic de l'utilisateur simulé, avant la prescription
    // (`SurveillanceBanc.items_du_jour`).
    final sv = _surveillance;
    final verite = _verite;
    if (sv != null && verite != null && sv.etat()['hors_modele'] == true) {
      final causes = sv.causes();
      final rep = verite.reponse(ctx);
      final qs = sv.questions(rep);
      koach.observe(<String, Object?>{
        'type': 'decision',
        'jour': ctx.simDay,
        'diagnostic': rep,
      });
      final cles = rep.keys.toList()..sort();
      sv.journal.add(<String, Object?>{
        'type': 'diagnostic',
        'jour': ctx.simDay,
        'causes': causes,
        'reponse': <String, Object?>{for (final k in cles) k: rep[k]},
        'questions': qs.length,
        'action': sv.reponses.last['action'],
      });
    }
    final roles = <String, Object?>{};
    for (final d in kc.jl(kc.jm(ctx.bloc['pass1'])['days'])) {
      for (final s0 in kc.jl(kc.jm(d)['slots'])) {
        final s = kc.jm(s0);
        roles[s['slotId']! as String] = s['role'];
      }
    }
    final r = kc.jm(
      koach.plan(<String, Object?>{
        'horizon': 'seance',
        'items': ctx.ecrit['items'],
        'grilles': _grilles,
        'zones': _zones,
        'roles': roles,
      }),
    );
    return <String, Object?>{'items': r['items']};
  }

  void _verser(List<Json> done) {
    while (_vus < done.length) {
      final rec = done[_vus];
      _vus += 1;
      final s = _serie(rec);
      if (s != null) {
        koach.observe(<String, Object?>{'type': 'serie', 'serie': s});
      }
    }
  }

  Json? _serie(Json rec) {
    if (kc.vrai(rec['nonModelise'])) {
      return null;
    }
    final s = <String, Object?>{for (final k in _pkChampsSerie) k: rec[k]};
    final charge = rec['externalLoadKg'];
    s['externalLoadKg'] = (charge != null && (charge as num) >= 0)
        ? charge
        : null;
    final ek = rec['enduranceKind'];
    if (ek != null) {
      final item = kc.jm(rec['item']);
      final sets0 = _pkGet(item, 'sets', 1)! as num;
      // max(1, sets) : le premier maximum.
      final num sets = sets0 > 1 ? sets0 : 1;
      if (rec['setIndex'] != 0) {
        return null;
      }
      if (ek == 'run') {
        const vitesse = 2.6;
        final ecrit = _pkSecondesPrescrites(item, sets, vitesse);
        final f0 = item['targetFlames'] as num?;
        final exId = item['exerciseId']! as String;
        final qualite =
            (f0 != null && (f0 >= 10 ? 0.0 : (11 - f0) / 2.0) <= 3 + 1e-9) ||
            item['intensity'] != null ||
            _pkQualityRunIds.any(exId.contains);
        final num poids = qualite
            ? kc.jm(parametres['mesure'])['cardio_poids_qualite']! as num
            : 1.0;
        final fait = (kc.ou(rec['seconds'], 0)! as num) * sets;
        s['demand'] = ecrit * poids / 60.0;
        s['doneShare'] = kc.vrai(rec['success'])
            ? 1.0
            : (ecrit > 0 ? fait / ecrit : 1.0);
        s['dose'] = fait * (qualite ? 1.5 : 1.0) / 3600.0;
        final fs = fait / 600.0;
        s['fatigueSets'] = fs < 6.0 ? fs : 6.0;
        s['target'] = <String, Object?>{'flames': f0};
      } else {
        s['demand'] = _pkGet(rec, 'writtenShare', 1.0);
        s['doneShare'] = kc.vrai(rec['success']) ? 1.0 : 0.9;
        s['dose'] = 1.0;
        s['fatigueSets'] = sets.toDouble();
        s['target'] = <String, Object?>{'flames': item['targetFlames']};
      }
    }
    return s;
  }

  @override
  Json? prochaineSerie(KmContexte ctx, Json item, int index, List<Json> done) {
    _verser(done);
    return kc.jmOu(
      koach.plan(<String, Object?>{
        'horizon': 'serie',
        'item': item,
        'index': index,
      }),
    );
  }

  @override
  void cranChange(String exId, int change) {
    koach.observe(<String, Object?>{
      'type': 'cran',
      'exerciseId': exId,
      'facteur': change < 0 ? 0.75 : 1 / 0.75,
    });
  }

  @override
  void terminer(KmContexte ctx, Json record) {
    _verser(<Json>[for (final s in kc.jl(record['sets'])) kc.jm(s)]);
    koach.observe(<String, Object?>{
      'type': 'seance_fin',
      'jour': ctx.simDay,
      'douleurs': record['pains'],
      'seance': record,
    });
  }

  @override
  List<double>? estimer(String exId, double n) {
    final m = koach.modele;
    final t = m.piste(exId);
    if (t == null ||
        !const <String>['charge', 'reps', 'tenue'].contains(t.type)) {
      return null;
    }
    final (mu, sd) = m.capacite(exId)!;
    final cap = math.exp(mu);
    double op;
    if (t.type == 'charge') {
      final (lam, k) = m.courbe(t);
      op = math.exp(mu - kc.Modele.gK(lam, k, n));
    } else {
      op = cap;
    }
    return <double>[
      cap,
      sd,
      op,
      math.exp(mu - 1.6448536269514722 * sd),
      math.exp(mu + 1.6448536269514722 * sd),
    ];
  }

  @override
  void finSemaine(int semaine, KmTour tour) {
    koach.observe(<String, Object?>{
      'type': 'semaine_fin',
      'jour': 7 * (semaine + 1),
      'semaine': semaine,
    });
    for (final Object x in List<Object>.of(koach.extensions)) {
      if (x is _ControleDualBanc) {
        x.apresSemaine(koach, semaine);
      } else if (x is _AdherenceBanc) {
        x.apresSemaine(koach, semaine, tour, this);
      }
    }
  }

  @override
  void fin(KmTour tour) {}

  /// Journaux des extensions du banc, par nom de classe de la référence
  /// Python (`extensions_koach.journaux`).
  Map<String, Object?> journaux() {
    final out = <String, Object?>{};
    for (final Object x in koach.extensions) {
      if (x is kc.Planification) {
        out['PlanificationCampagne'] = null;
      } else if (x is _SurveillanceBanc) {
        out['SurveillanceBanc'] = x.journal;
      } else if (x is _ControleDualBanc) {
        out['ControleDualBanc'] = x.journal;
      } else if (x is _AdherenceBanc) {
        out['AdherenceBanc'] = x.journal;
      }
    }
    return out;
  }

  /// États exportés des extensions du moteur (`extensions_koach.etats`) et
  /// de la planification (`Planification.etat`).
  Map<String, Object?> etats() {
    final out = <String, Object?>{};
    for (final Object x in koach.extensions) {
      if (x is kc.Surveillance) {
        out['Surveillance'] = x.etatComplet();
      } else if (x is kc.ControleDual) {
        out['ControleDual'] = x.etat();
      } else if (x is kc.Adherence) {
        out['Adherence'] = x.etat();
      }
    }
    final pl = _planification;
    if (pl != null) {
      out['Planification'] = pl.etat();
    }
    return out;
  }

  /// Saison en cours.
  Json get saison => _saison;
}
