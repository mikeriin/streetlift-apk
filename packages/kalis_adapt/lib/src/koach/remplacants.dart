part of 'koach.dart';

// Koach 1.0.9 (KM7, DECISIONS_CP.md C17.54) : remplaçants d'une ligne en
// séance selon la raison et le matériel du jour (référence
// `koach/remplacants.py`, mêmes règles, mêmes valeurs). Fiches : format de
// `reference/donnees/catalogue_infos.json.gz` (`koachInfosRemplacement` de
// `package:kalis_adapt/kalis_adapt.dart`).

/// Étiquettes des remplaçants.
const List<String> koachEtiquettesRemplacant = <String>[
  'equivalent',
  'plus_facile',
  'sans_materiel',
  'autre',
];

/// Ordre des étiquettes selon la raison.
const Map<String, List<String>> koachOrdreRemplacants = <String, List<String>>{
  'pas_de_materiel': <String>[
    'equivalent',
    'sans_materiel',
    'plus_facile',
    'autre',
  ],
  'douleur': <String>['equivalent', 'plus_facile', 'sans_materiel', 'autre'],
  'trop_dur': <String>['plus_facile', 'equivalent', 'autre'],
  'autre': <String>['equivalent', 'plus_facile', 'sans_materiel', 'autre'],
};

/// Matériel qui ne bloque jamais (`alwaysAvailableEquipment` de
/// kalis_core) ; le mur est lié au lieu (maison et salle).
const List<String> koachMaterielToujours = <String>[
  'aucun (sol)',
  'mur',
  'tapis',
  'magnésie',
];

const List<String> _murLieux = <String>['maison', 'salle'];

/// Transferts de charge (`coachLoadReferences` de kalis_plan 0.4.3) :
/// variante -> (référence, 1RM total de la variante / celui de la
/// référence). Sens inverse : facteur 1 (jamais de hausse par transfert).
const Map<String, (String, double)> koachTransferts =
    <String, (String, double)>{
      'sl-traction-haute-lestee': ('sl-traction-lestee', 0.85),
      'sl-dips-barre-fixe-leste': ('sl-dips-leste', 0.9),
    };

/// Rôles dont le schéma est le but de la ligne (pas d'« autre » schéma).
const List<String> koachRolesSchema = <String>['main', 'skill'];

const int _parEtiquette = 3;
const int _limite = 8;
const double _penaliteProfondeur = 0.08;
const double _partBas = 0.8;
const int _nomsMaterielMax = 3;

String _qualiteR(Json i) {
  final cm = i['contractionMode'];
  if (cm == 'explosive' || i['slotKind'] == 'power') {
    return 'explosive';
  }
  if (cm == 'isometric') {
    return 'isometrique';
  }
  if (cm == 'eccentric') {
    return 'excentrique';
  }
  return 'dynamique';
}

List<int> _groupesR(Json i, double seuil) {
  final g = listeOuVide(i['groups']);
  final w = listeOuVide(i['groupWeights']);
  final out = <int>[];
  for (var k = 0; k < g.length && k < w.length; k++) {
    if (dbl(w[k]) >= seuil - 1e-9) {
      out.add(ent(g[k]));
    }
  }
  return out;
}

bool _musclesOk(Json o, Json c) {
  final po = _groupesR(o, 1.0);
  if (po.isEmpty) {
    return false;
  }
  final gc = _groupesR(c, 0.5).toSet();
  final pc = _groupesR(c, 1.0).toSet();
  if (po.any((g) => !gc.contains(g))) {
    return false;
  }
  final need = math.max(1, (po.length / 2.0).ceil());
  return pc.intersection(po.toSet()).length >= need;
}

bool _communR(Json o, Json c) => _groupesR(
  o,
  1.0,
).toSet().intersection(_groupesR(c, 1.0).toSet()).isNotEmpty;

Map<int, double> _poidsR(Json i) {
  final g = listeOuVide(i['groups']);
  final w = listeOuVide(i['groupWeights']);
  final out = <int, double>{};
  for (var k = 0; k < g.length && k < w.length; k++) {
    out[ent(g[k])] = dbl(w[k]);
  }
  return out;
}

double _cosinusR(Json o, Json c) {
  final a = _poidsR(o);
  final b = _poidsR(c);
  var sa = 0.0;
  for (final v in a.values) {
    sa += v * v;
  }
  var sb = 0.0;
  for (final v in b.values) {
    sb += v * v;
  }
  final na = math.sqrt(sa);
  final nb = math.sqrt(sb);
  if (na <= 0 || nb <= 0) {
    return 0.0;
  }
  var dot = 0.0;
  for (final e in a.entries) {
    final x = b[e.key];
    if (x != null) {
      dot += e.value * x;
    }
  }
  return dot / (na * nb);
}

int _difficulte(Json i) => vrai(i['difficulty']) ? ent(i['difficulty']) : 0;

/// Proximité (0..1) d'un remplaçant : muscles 0,55 (cosinus des groupes),
/// schéma 0,20, chaîne de variantes 0,15, difficulté 0,10.
double koachScoreRemplacant(Json o, Json c) {
  var s = 0.55 * _cosinusR(o, c);
  if (c['pattern'] == o['pattern']) {
    s += 0.20;
  }
  if (c['rootId'] == o['rootId']) {
    s += 0.15;
  }
  final d = (_difficulte(c) - _difficulte(o)).abs();
  s += 0.10 * math.max(0.0, 1.0 - d / 10.0);
  return s;
}

bool _faisableR(Json c, Set<String>? dispo, Set<String> manque, String? lieu) {
  for (final x in listeOuVide(c['equipment'])) {
    final m = x as String;
    if (manque.contains(m)) {
      return false;
    }
    if (m == 'mur') {
      if (lieu == null ||
          _murLieux.contains(lieu) ||
          (dispo != null && dispo.contains(m))) {
        continue;
      }
      return false;
    }
    if (koachMaterielToujours.contains(m)) {
      continue;
    }
    if (dispo != null && !dispo.contains(m)) {
      return false;
    }
  }
  if (lieu != null && !listeOuVide(c['places']).contains(lieu)) {
    return false;
  }
  return true;
}

bool _sollicite(Json c, String zone, Object? zones) {
  final z = dictOuVide(zones)[c['id']];
  if (z != null) {
    final zl = jl(z);
    final niveaux = jm(zl[0]);
    final hits = listeOuVide(zl[1]);
    return (vrai(niveaux[zone]) ? dbl(niveaux[zone]) : 0.0) > 0.0 ||
        hits.contains(zone);
  }
  final niv = dictOuVide(c['zoneLevels'])[zone];
  return (niv == null ? 0.0 : dbl(niv)) > 0.0 ||
      listeOuVide(c['painStopHits']).contains(zone);
}

bool _memePoste(Json o, Json c) {
  final po = <String>{
    for (final m in listeOuVide(o['equipment']))
      if (!koachMaterielToujours.contains(m)) m as String,
  };
  if (po.isEmpty) {
    return true;
  }
  return listeOuVide(c['equipment']).any(po.contains);
}

String? _etiquetteR(Json o, Json c, String raison, Object? role) {
  final meme = c['pattern'] == o['pattern'];
  final muscles = _musclesOk(o, c);
  final dO = _difficulte(o);
  final dC = _difficulte(c);
  if (meme && muscles) {
    if (c['mode'] == o['mode'] &&
        _qualiteR(c) == _qualiteR(o) &&
        !vrai(c['assisted']) &&
        dO - 2 <= dC &&
        dC <= dO + 1) {
      if (raison == 'trop_dur' && dC >= dO) {
        return null;
      }
      if (raison == 'trop_dur') {
        return 'plus_facile';
      }
      return 'equivalent';
    }
    if (c['mode'] != o['mode'] || _qualiteR(c) != _qualiteR(o)) {
      if (raison == 'pas_de_materiel' && dC <= dO + 1) {
        return 'sans_materiel';
      }
      return dC < dO ? 'plus_facile' : null;
    }
    return dC < dO ? 'plus_facile' : null;
  }
  final explosif =
      c['pattern'] == 'pliometrie' &&
      o['pattern'] != 'pliometrie' &&
      muscles &&
      (c['family'] == 'explosif' || c['family'] == o['family']) &&
      _memePoste(o, c);
  if (explosif && raison == 'pas_de_materiel' && dC <= dO + 1) {
    return 'sans_materiel';
  }
  if (koachRolesSchema.contains(role)) {
    return null;
  }
  if (!meme && c['family'] == o['family'] && _communR(o, c)) {
    if (raison == 'trop_dur' && dC > dO) {
      return null;
    }
    return 'autre';
  }
  return null;
}

String _materielR(List<Object?> noms) {
  if (noms.isEmpty) {
    return 'ce matériel';
  }
  if (noms.length == 1) {
    return '${noms[0]}';
  }
  return '${noms.sublist(0, noms.length - 1).join(', ')} et ${noms.last}';
}

String _texteR(
  String etiquette,
  Json o,
  Json c,
  Json raison,
  String? uniteO,
  String? uniteC,
) {
  final code = raison['code'];
  final manque0 = listeOuVide(raison['materiel']);
  final manque = manque0.length > _nomsMaterielMax
      ? manque0.sublist(0, _nomsMaterielMax)
      : manque0;
  String t;
  if (etiquette == 'equivalent') {
    t = 'Même mouvement, mêmes muscles';
    if (code == 'pas_de_materiel' && manque.isNotEmpty) {
      t += ', sans ${_materielR(manque)}';
    }
    t += '.';
  } else if (etiquette == 'plus_facile') {
    t = 'Même mouvement, plus accessible.';
  } else if (etiquette == 'sans_materiel') {
    if (c['pattern'] == 'pliometrie' && o['pattern'] != 'pliometrie') {
      t = 'Version explosive du mouvement, sans ${_materielR(manque)}.';
    } else if ((uniteO == 'charge' || uniteO == 'charge_ajoutee') &&
        uniteC == 'reps') {
      t =
          'Au poids du corps, sans ${_materielR(manque)} : tempo lent ou '
          'pause en bas pour garder l’effort.';
    } else {
      t = 'Même mouvement sans ${_materielR(manque)}.';
    }
  } else {
    t = 'Autre mouvement, mêmes muscles principaux.';
  }
  if (code == 'douleur' && vrai(raison['zone'])) {
    t += ' Ne sollicite pas la zone signalée.';
  }
  return t;
}

/// Unité servie d'une fiche de remplacement : `charge_ajoutee`, `charge`,
/// `reps`, `secondes` ou null.
String? koachUniteRemplacant(Json i) {
  final m = i['mode'];
  if (m == 'loaded') {
    return (vrai(i['fraction']) && dbl(i['fraction']) > 0) ||
            i['loadType'] == 'addedWeight'
        ? 'charge_ajoutee'
        : 'charge';
  }
  if (m == 'reps') {
    return 'reps';
  }
  if (m == 'hold') {
    return 'secondes';
  }
  return null;
}

/// Unité servie d'après la fiche de Koach (type, fraction).
String? koachUniteFiche(Json f) {
  final t = f['type'];
  if (t == 'charge') {
    return (vrai(f['fraction']) && dbl(f['fraction']) > 0) ||
            f['type_charge'] == 'lest'
        ? 'charge_ajoutee'
        : 'charge';
  }
  if (t == 'reps') {
    return 'reps';
  }
  if (t == 'tenue') {
    return 'secondes';
  }
  return null;
}

Grille? _grilleR(Json i, Object? grilles) {
  final g = dictOuVide(grilles)[i['id']];
  if (g != null) {
    if (g is Grille) {
      return g;
    }
    final gg = jm(g);
    return Grille(dbl(gg['pas']), dbl(gg['minimum']), vrai(gg['halteres']));
  }
  if (i['gridStep'] == null) {
    return null;
  }
  return Grille(
    dbl(i['gridStep']),
    dbl(i['gridMinimum']),
    vrai(i['gridDumbbell']),
  );
}

/// Plage (bas, haut) d'une cible prévue [valeur] : haut = partie entière (1
/// au moins), bas = 80 % du haut.
(int, int) koachPlageConvertie(double valeur) {
  final haut = math.max(1, (valeur + 1e-9).floor());
  final bas = math.max(1, (_partBas * haut + 1e-9).floor());
  return (bas, haut);
}

/// Facteur de transfert de charge totale de [o] vers [c], ou null.
double? koachTransfert(String o, String c) {
  final v = koachTransferts[c];
  if (v != null && v.$1 == o) {
    return v.$2;
  }
  final w = koachTransferts[o];
  if (w != null && w.$1 == c) {
    return 1.0;
  }
  return null;
}

bool _estCharge(String? u) => u == 'charge' || u == 'charge_ajoutee';

/// Cible de départ du remplaçant [cId] sur la ligne servie [item] de
/// l'exercice [oId] (référence `depart`) : source `historique`,
/// `transfert`, `a_priori` ou null ; charge, plages.
Json koachDepart(
  Koach? koach,
  String oId,
  String? uO,
  String cId,
  String? uC,
  Json item, [
  Grille? grille,
]) {
  final out = <String, Object?>{
    'source': null,
    'loadKg': null,
    'repsLow': null,
    'repsHigh': null,
    'secondsLow': null,
    'secondsHigh': null,
  };
  Object? lo = item['repsLow'];
  Object? hi = item['repsHigh'];
  final slo = item['secondsLow'];
  final shi = item['secondsHigh'];
  final meme = (_estCharge(uO) && _estCharge(uC)) || uO == uC;
  if (_estCharge(uC) && uO == 'secondes') {
    lo = 6;
    hi = 8;
  }
  void ecrit() {
    out['repsLow'] = lo;
    out['repsHigh'] = hi;
    out['secondsLow'] = slo;
    out['secondsHigh'] = shi;
  }

  if (koach == null) {
    if (meme) {
      ecrit();
    }
    return out;
  }
  final s = koach.seances;
  final m = koach.modele;
  final t = m.piste(cId);
  final f = item['targetFlames'];
  final rir = f == null ? 2.5 : rirDeFlammes(f)!;
  if (t == null) {
    if (meme) {
      ecrit();
    }
    return out;
  }
  if (_estCharge(uC)) {
    if (lo == null && hi == null) {
      lo = 6;
      hi = 8;
    }
    lo ??= hi;
    hi ??= lo;
    out['repsLow'] = lo;
    out['repsHigh'] = hi;
    final reps = dbl(hi) == dbl(lo) ? dbl(hi) : (dbl(lo) + dbl(hi)) / 2.0;
    final pr = jld(jm(koach.params['planification'])['prudence_charge']);
    final g = grille;
    if (t.mesures > 0) {
      final voulu = s.chargePour(
        cId,
        reps,
        rir,
        t.seances > 3 ? pr[1] : pr[0],
      )!;
      out['source'] = 'historique';
      out['loadKg'] = g != null ? g.proche(math.max(voulu, g.minimum)) : voulu;
      return out;
    }
    final tr = koachTransfert(oId, cId);
    final to = m.piste(oId);
    if (tr != null && to != null && to.type == 'charge' && to.mesures > 0) {
      final total =
          (s.chargePour(oId, reps, rir, pr[0])! + to.fraction * m.poidsKg) * tr;
      final voulu = total - t.fraction * m.poidsKg;
      out['source'] = 'transfert';
      out['loadKg'] = g != null
          ? g.plancher(math.max(voulu, g.minimum))
          : voulu;
      return out;
    }
    final cap = m.capacite(cId)!;
    if (cap.$2 <= 0.12) {
      final voulu = s.chargePour(cId, reps, rir, pr[0])!;
      out['source'] = 'a_priori';
      out['loadKg'] = g != null
          ? g.plancher(math.max(voulu, g.minimum))
          : voulu;
    }
    return out;
  }
  if (uC == 'reps' && t.type == 'reps') {
    if (meme && (lo != null || hi != null)) {
      out['source'] = t.mesures > 0 ? 'historique' : null;
      out['repsLow'] = lo;
      out['repsHigh'] = hi;
      return out;
    }
    var prevu = s.repsPrevues(cId, null, rir)!;
    if (t.mesures == 0) {
      prevu *= math.exp(-0.5 * m.capaciteDuJour(cId)!.$2);
    }
    final (b, h) = koachPlageConvertie(math.min(math.max(prevu, 1.0), 30.0));
    out['source'] = t.mesures > 0 ? 'historique' : 'a_priori';
    out['repsLow'] = b;
    out['repsHigh'] = h;
    return out;
  }
  if (uC == 'secondes' && t.type == 'tenue') {
    if (meme && (slo != null || shi != null)) {
      out['source'] = t.mesures > 0 ? 'historique' : null;
      out['secondsLow'] = slo;
      out['secondsHigh'] = shi;
      return out;
    }
    var prevu = s.secondesPrevues(cId, rir)!;
    if (t.mesures == 0) {
      prevu *= math.exp(-0.5 * m.capaciteDuJour(cId)!.$2);
    }
    final (b, h) = koachPlageConvertie(math.min(math.max(prevu, 1.0), 180.0));
    out['source'] = t.mesures > 0 ? 'historique' : 'a_priori';
    out['secondsLow'] = b;
    out['secondsHigh'] = h;
    return out;
  }
  if (meme) {
    ecrit();
  }
  return out;
}

List<(double, String, Json)> _choisirR(
  List<(double, String, Json)> cands,
  String etiquette,
  Object? par,
) {
  final n = par != null
      ? ent(par)
      : _parEtiquette + (etiquette == 'sans_materiel' ? 2 : 0);
  double rangDe((double, String, Json) x) =>
      x.$1 -
      _penaliteProfondeur *
          (vrai(x.$3['depth']) ? ent(x.$3['depth']) : 0).toDouble();
  final rang = List<(double, String, Json)>.of(cands)
    ..sort((a, b) {
      final c = (-rangDe(a)).compareTo(-rangDe(b));
      return c != 0 ? c : a.$2.compareTo(b.$2);
    });
  final pris = <(double, String, Json)>[];
  final vues = <String>{};
  for (final x in rang) {
    final r = (x.$3['rootId'] as String?) ?? x.$2;
    if (vues.add(r)) {
      pris.add(x);
    }
  }
  for (final x in rang) {
    if (!pris.contains(x)) {
      pris.add(x);
    }
  }
  return pris.length > n ? pris.sublist(0, n) : pris;
}

/// Remplaçants classés et étiquetés de la ligne [demande] (référence
/// `remplacants`) : `exerciseId`, `item`, `role`, `raison` ({code,
/// materiel, zone}), `materiel`, `lieu`, `niveau`, `exclus`, `grilles`,
/// `zones`, `limite`, `par_etiquette`. Sans [koach] : aucune cible de
/// départ. Avec [koach] : lecture seule (pistes ouvertes pour l'aperçu
/// refermées).
Json koachRemplacants(List<Json> infos, Json demande, [Koach? koach]) {
  final parId = <String, Json>{for (final i in infos) i['id'] as String: i};
  final oId = demande['exerciseId'] as String;
  final o = parId[oId];
  final raison = Map<String, Object?>.of(
    demande['raison'] == null
        ? <String, Object?>{'code': 'autre'}
        : jm(demande['raison']),
  );
  var code = (vrai(raison['code']) ? raison['code'] : 'autre') as String;
  if (!koachOrdreRemplacants.containsKey(code)) {
    code = 'autre';
  }
  final role = demande['role'];
  final out = <String, Object?>{
    'exerciseId': oId,
    'raison': code,
    'remplacants': <Object?>[],
    'regles': <String, Object?>{
      'autre_permis': !koachRolesSchema.contains(role),
      'zone': code == 'douleur' ? raison['zone'] : null,
    },
  };
  if (o == null) {
    return out;
  }
  final manque = code == 'pas_de_materiel'
      ? <String>{for (final m in listeOuVide(raison['materiel'])) m as String}
      : <String>{};
  Set<String>? dispo;
  if (demande['materiel'] != null) {
    dispo = <String>{for (final m in jl(demande['materiel'])) m as String};
  } else {
    dispo = <String>{
      for (final m in listeOuVide(o['equipment']))
        if (!manque.contains(m)) m as String,
    };
  }
  final lieu = demande['lieu'] as String?;
  final exclus = <String>{
    for (final x in listeOuVide(demande['exclus'])) x as String,
  };
  final niveau = demande['niveau'];
  var niveauMax = vrai(o['level']) ? ent(o['level']) : 0;
  if (niveau != null && ent(niveau) > niveauMax) {
    niveauMax = ent(niveau);
  }
  final zone = code == 'douleur' ? raison['zone'] as String? : null;
  final item = dictOuVide(demande['item']);
  final uO = koachUniteRemplacant(o);
  final etat = koach?.modele.instantane();
  try {
    final par = <String, List<(double, String, Json)>>{
      for (final e in koachEtiquettesRemplacant) e: [],
    };
    for (final c in infos) {
      final cid = c['id'] as String;
      if (cid == oId ||
          exclus.contains(cid) ||
          !const ['loaded', 'reps', 'hold'].contains(c['mode'])) {
        continue;
      }
      if ((vrai(c['level']) ? ent(c['level']) : 0) > niveauMax) {
        continue;
      }
      if (!_faisableR(c, dispo, manque, lieu)) {
        continue;
      }
      if (zone != null && _sollicite(c, zone, demande['zones'])) {
        continue;
      }
      if (code == 'trop_dur' && _difficulte(c) > _difficulte(o)) {
        continue;
      }
      final e = _etiquetteR(o, c, code, role);
      if (e == null) {
        continue;
      }
      par[e]!.add((koachScoreRemplacant(o, c), cid, c));
    }
    final limite = vrai(demande['limite']) ? ent(demande['limite']) : _limite;
    final liste = out['remplacants']! as List<Object?>;
    for (final e in koachOrdreRemplacants[code]!) {
      for (final (sc, cid, c) in _choisirR(
        par[e]!,
        e,
        demande['par_etiquette'],
      )) {
        if (liste.length >= limite) {
          break;
        }
        final uC = koachUniteRemplacant(c);
        final g = _grilleR(c, demande['grilles']);
        liste.add(<String, Object?>{
          'exerciseId': cid,
          'nom': c['name'],
          'etiquette': e,
          'texte': _texteR(e, o, c, raison, uO, uC),
          'unite': uC,
          'depart': koachDepart(koach, oId, uO, cid, uC, item, g),
          'score': sc,
        });
      }
    }
    return out;
  } finally {
    if (etat != null) {
      koach!.modele.restaurer(etat);
    }
  }
}

/// Ligne écrite [item] servie avec son remplaçant (`item['remplace']` =
/// {exerciseId écrit, raison} ; `item['exerciseId']` = remplaçant) :
/// emplacement, séries, groupe, format, repos gardés ; charge écrite
/// retirée ; autre unité : plage de départ de Koach ; transfert : charge
/// de départ (`koachDepartKg`).
Json koachItemRemplace(Koach koach, Json item, [Grille? grille]) {
  final rem = dictOuVide(item['remplace']);
  final oId = rem['exerciseId'] as String?;
  final cId = item['exerciseId'] as String;
  final fo = (oId == null ? null : koach.fiches[oId]) ?? <String, Object?>{};
  final fc = koach.fiches[cId] ?? <String, Object?>{};
  final uO = koachUniteFiche(fo);
  final uC = koachUniteFiche(fc);
  final out = Map<String, Object?>.of(item);
  for (final k in const [
    'startLoadKg',
    'loadKg',
    'koachCible',
    'koachDepartKg',
  ]) {
    out.remove(k);
  }
  if (uC == null || uO == null) {
    return out;
  }
  final d = koachDepart(koach, oId!, uO, cId, uC, item, grille);
  if (_estCharge(uC)) {
    if (!_estCharge(uO)) {
      out.remove('percentOfOneRm');
      out['secondsLow'] = null;
      out['secondsHigh'] = null;
      out['repsLow'] = d['repsLow'];
      out['repsHigh'] = d['repsHigh'];
    }
    if (d['source'] == 'transfert') {
      out['koachDepartKg'] = d['loadKg'];
    }
  } else if (uC == 'reps') {
    out.remove('percentOfOneRm');
    if (uO != 'reps' && d['repsHigh'] != null) {
      out['repsLow'] = d['repsLow'];
      out['repsHigh'] = d['repsHigh'];
      out['secondsLow'] = null;
      out['secondsHigh'] = null;
    }
  } else if (uC == 'secondes') {
    out.remove('percentOfOneRm');
    if (uO != 'secondes' && d['secondsHigh'] != null) {
      out['secondsLow'] = d['secondsLow'];
      out['secondsHigh'] = d['secondsHigh'];
      out['repsLow'] = null;
      out['repsHigh'] = null;
    }
  }
  return out;
}
