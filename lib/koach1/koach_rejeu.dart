// KM3 : rejeu walk-forward du journal moteur dans le mode dev (portage
// Dart de la mesure A de `reference/rejeu/walk_forward.py`, « une séance
// d'avance ») : instance sans extension qui ne reçoit que `semaine_fin`,
// `seance_debut`, `serie` et `seance_fin` ; la prévision se lit après
// `seance_debut`, avant les séries, sur les pistes déjà créées seulement
// (`modele.pistes[id]`, jamais `piste(id)`). Sortie : agrégats seulement.
import 'dart:math' as math;

import 'package:kalis_adapt/koach.dart' as ko;

import 'koach_journal.dart' show koachRirDeFlammes;
import 'koach_moteur.dart';

const _z90 = 1.6448536269514722;
const _seuilFlammes = 5;
const _seuilFiable = 8;
const _nMinCellule = 3;

/// Série la plus informative d'un exercice dans la séance : première série
/// de travail ou de test notée 3 en réserve ou moins, au moins une
/// répétition, sans série plus lourde avant elle. (rang, série) ou null.
(int, Json)? _serieInformative(List<Json> series) {
  for (var pos = 0; pos < series.length; pos++) {
    final s = series[pos];
    if (s['kind'] != 'work' && s['kind'] != 'test') continue;
    final f = s['flames'];
    final reps = (s['reps'] as num?) ?? 0;
    if (reps < 1 || f is! int || f < _seuilFlammes) continue;
    final ext = (s['externalLoadKg'] as num?)?.toDouble() ?? 0.0;
    for (final p in series.sublist(0, pos)) {
      if (((p['externalLoadKg'] as num?)?.toDouble() ?? 0.0) > ext + 1e-9) {
        return null;
      }
    }
    return (pos, s);
  }
  return null;
}

double? _mediane(List<double> v) {
  if (v.isEmpty) return null;
  final x = [...v]..sort();
  final h = x.length ~/ 2;
  return x.length.isOdd ? x[h] : 0.5 * (x[h - 1] + x[h]);
}

double _r(double x, [int n = 4]) {
  final p = math.pow(10, n);
  return (x * p).round() / p;
}

/// Résumé des erreurs (`resume_erreurs`).
Json koachResumeErreurs(List<Json> recs) {
  if (recs.length < _nMinCellule) return {'n': recs.length};
  final ab = [for (final r in recs) ((r['erreur'] as num).toDouble()).abs()];
  final sg = [for (final r in recs) (r['erreur'] as num).toDouble()];
  final couverts = recs.where((r) => r['couvert'] == true).length;
  final demi = [for (final r in recs) (r['demi'] as num).toDouble()];
  return {
    'n': recs.length,
    'erreur_moyenne': _r(ab.reduce((a, b) => a + b) / ab.length),
    'erreur_mediane': _r(_mediane(ab)!),
    'biais_signe_moyen': _r(sg.reduce((a, b) => a + b) / sg.length),
    'couverture_90': _r(couverts / recs.length, 3),
    'demi_largeur_mediane_pct': _r(100 * (math.exp(_mediane(demi)!) - 1), 2),
  };
}

/// Rejeu des [seances] (format de l'export du journal moteur) avec le
/// profil [profil] ; évaluation à partir de la semaine S[depuis].
Json koachRejeuWalkForward(
  KoachRessources res,
  Json profil,
  List<Json> seances,
  Set<String> principaux, {
  int depuis = 12,
}) {
  final k = ko.Koach(res.params, res.fiches, profil);
  final m = k.modele;
  final recs = <Json>[];
  var evaluees = 0;
  for (final s in seances) {
    for (final e in (s['avant'] as List? ?? const [])) {
      k.observe((e as Map).cast<String, Object?>());
    }
    k.observe((s['debut'] as Map).cast<String, Object?>());
    final evalue = ((s['semaine'] as num?) ?? 0) >= depuis;
    final series = [
      for (final e in (s['series'] as List? ?? const []))
        ((e as Map)['serie'] as Map).cast<String, Object?>(),
    ];
    if (evalue) {
      evaluees++;
      final parEx = <String, List<Json>>{};
      for (final x in series) {
        parEx.putIfAbsent('${x['exerciseId']}', () => []).add(x);
      }
      for (final ex in parEx.keys) {
        final t = m.pistes[ex];
        if (t == null || t.type != 'charge') continue;
        final hit = _serieInformative(parEx[ex]!);
        if (hit == null) continue;
        final (pos, ser) = hit;
        final dj = m.capaciteDuJour(ex);
        if (dj == null) continue;
        final (muJ, sdJ) = dj;
        final (lam, kk) = m.courbe(t);
        final f = ser['flames'] as int;
        final dit = koachRirDeFlammes(f);
        final vrai = f >= 10 ? 0.0 : m.rirVrai(dit);
        final reps = (ser['reps'] as num).toDouble();
        final rr = reps + vrai;
        final charge = m.masse(t, (ser['externalLoadKg'] as num?)?.toDouble());
        if (charge <= 0) continue;
        final lnReel = math.log(charge) + ko.Modele.gK(lam, kk, rr);
        final pente = ko.Modele.dgK(lam, kk, rr);
        final bruit = m.bruitRirDe(vrai, reps);
        final demi = _z90 * math.sqrt(sdJ * sdJ + math.pow(bruit * pente, 2));
        final ecart = muJ - lnReel;
        recs.add({
          'famille': principaux.contains(ex) ? 'principal' : 'autre',
          'rang': pos,
          'flammes': f,
          'demi': demi,
          'erreur': math.exp(ecart) - 1.0,
          'couvert': ecart.abs() <= demi,
        });
      }
    }
    for (final x in series) {
      k.observe({'type': 'serie', 'serie': x});
    }
    k.observe((s['fin'] as Map).cast<String, Object?>());
  }
  final tot = koachResumeErreurs(recs);
  final fiables = koachResumeErreurs([
    for (final r in recs)
      if ((r['flammes'] as int) >= _seuilFiable) r,
  ]);
  final err = tot['erreur_moyenne'] as num?;
  final cov = tot['couverture_90'] as num?;
  final biais = tot['biais_signe_moyen'] as num?;
  return {
    'schema': 'kalis_track/rejeu_walk_forward/1',
    'depuis_semaine': depuis,
    'seances_rejouees': seances.length,
    'seances_evaluees': evaluees,
    'A_une_seance_d_avance': tot,
    'A_series_fiables': fiables,
    'par_famille': {
      for (final fam in const ['principal', 'autre'])
        fam: koachResumeErreurs([
          for (final r in recs)
            if (r['famille'] == fam) r,
        ]),
    },
    'critere_10': {
      'series_notees': recs.length,
      'erreur_sous_3_pct': err != null && err < 0.03,
      'couverture_88_92_pct': cov != null && cov >= 0.88 && cov <= 0.92,
      'biais_sous_2_pct': biais != null && biais.abs() < 0.02,
      'au_moins_100_series': recs.length >= 100,
    },
  };
}
