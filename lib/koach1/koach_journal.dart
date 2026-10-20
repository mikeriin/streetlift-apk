// KM3 : événements du journal de Koach 1.0 construits depuis les données de
// l'application (INTEGRATION_KM3.md § 2). Fonctions pures : aucune horloge,
// aucun stockage. Le journal des séances de l'application passe d'abord par
// `convertLegacyJournal` (journal_adapter.dart, règles C1 à C12 de G3 et
// mini-séries de CI1f), puis chaque série devient l'objet `serie` du
// contrat (§ 2.5, comme `_serie` de `politique_koach.dart`).
import 'dart:math' as math;

import 'package:kalis_adapt/koach.dart' as ko;
import 'package:kalis_core/kalis_core.dart' as kc;

import 'koach_moteur.dart' show Json, koachCopie;

/// Réserve dite d'une note en flammes (10 = échec, 0).
double koachRirDeFlammes(int f) => f >= 10 ? 0.0 : (11 - f) / 2.0;

/// Jour du moteur : jours civils depuis le lundi de S1.
int koachJour(kc.CivilDate lundi, kc.CivilDate d) =>
    d.dayNumber - lundi.dayNumber;

/// Lundi de la semaine qui contient [d].
kc.CivilDate koachLundiDe(kc.CivilDate d) =>
    kc.CivilDate.fromDayNumber(d.dayNumber - (d.weekday - 1));

/// Événement de fin de la semaine globale [g] (convention du banc et du
/// contrat : indice de la semaine qui finit, INTEGRATION_KM3.md § 2.1).
Json koachSemaineFin(int g) => {
  'type': 'semaine_fin',
  'jour': 7 * (g + 1),
  'semaine': g,
};

/// Champs de volume d'un item écrit (`_pkItemsVolume`).
const kKoachChampsVolume = <String>[
  'slotId',
  'exerciseId',
  'kind',
  'sets',
  'targetFlames',
  'secondsLow',
  'secondsHigh',
];

/// KB3 (Koach 1.0.6, contrat § 8.3) : [roles] (emplacement → rôle, `roles`
/// du plan de séance) donne le champ additif `role` de l'item (`main`,
/// `secondary`, `accessory`…), lu par le retour gradué pour couper les
/// accessoires d'abord et garder le plancher des principaux ; omis quand
/// l'emplacement n'a pas de rôle connu.
Json koachItemVolume(Json it, [Map<String, Object?>? roles]) {
  final role = roles?['${it['slotId']}'];
  return {
    for (final k in kKoachChampsVolume) k: it[k],
    if (role != null) 'role': role,
  };
}

/// Cible d'une série au format du contrat (`target`).
Json koachCibleSerie(Object? target) {
  if (target is! Map) return {};
  return {
    for (final k in const [
      'repsLow',
      'repsHigh',
      'secondsLow',
      'secondsHigh',
      'flames',
      'role',
    ])
      if (target.containsKey(k)) k: target[k],
  };
}

/// Objet `serie` du contrat (§ 2.5) depuis une ligne du journal converti
/// ([rec] : `SetRecord.toJson()`). Null : série non versée (écartée, sans
/// mesure). [cible] : cible rendue par `plan(serie)` (repère gardé).
Json? koachSerie(Json rec, {Json? cible}) {
  if (rec['excluded'] == true) return null;
  final reps = rec['reps'];
  final seconds = rec['seconds'];
  final distance = rec['distanceMeters'];
  if (reps == null && seconds == null && distance == null) return null;
  final ext = rec['externalLoadKg'];
  final measure = (reps ?? seconds) as num?;
  final target = koachCibleSerie(rec['target']);
  if (cible != null) {
    for (final k in const [
      'repsLow',
      'repsHigh',
      'secondsLow',
      'secondsHigh',
    ]) {
      if (cible[k] != null) target[k] = cible[k];
    }
    if (cible['role'] != null) target['role'] = cible['role'];
  }
  final rest =
      rec['restBeforeSeconds'] ??
      (rec['target'] is Map ? (rec['target'] as Map)['restSeconds'] : null);
  return {
    'exerciseId': rec['exerciseId'],
    'slotId': rec['slotId'],
    'setIndex': rec['setIndex'],
    'kind': rec['kind'] ?? 'work',
    'reps': reps,
    'seconds': seconds,
    'flames': rec['flames'],
    // Mesure 0 (aucune répétition, tenue de 0 s), comme `journal_app.py`.
    'failed': measure != null && measure == 0,
    'target': target,
    'restSeconds': rest,
    'technique': rec['technique'],
    'role': rec['role'],
    'repere': cible?['repere'],
    'externalLoadKg': ext is num && ext >= 0 ? ext : null,
    if (distance != null) 'distanceMeters': distance,
  };
}

/// Ce que l'application sait d'une journée du programme pour le contexte
/// de Koach (§ 2.4).
class KoachJourInfo {
  /// Semaine globale g (S − 1).
  final int semaine;
  final int? jourIndex;
  final String? genre;
  final String? intention;

  /// Items écrits de la journée (JSON `ExercisePrescription`).
  final List<Json> items;

  /// Rôles des emplacements du bloc.
  final Json roles;
  const KoachJourInfo({
    required this.semaine,
    this.jourIndex,
    this.genre,
    this.intention,
    this.items = const [],
    this.roles = const {},
  });
}

/// Contexte de `seance_debut` (§ 2.4) sans les clés propres à la séance
/// servie (manquées, reste de la semaine, budget, lieu).
Json koachContexteDe(KoachJourInfo i) => {
  'semaine': i.semaine,
  'jour_index': i.jourIndex,
  'genre': i.genre,
  'intention': i.intention,
};

/// Lignes d'endurance (course, conditionnement) : une seule `serie` par
/// ligne, avec `demand`, `doneShare`, `dose`, `fatigueSets` (§ 2.5,
/// `_serie` de `politique_koach.dart`). [fiche] : fiche de Koach ; [item] :
/// item écrit ; [faites] : séries de la ligne. Null : pas une ligne
/// d'endurance.
Json? koachSerieEndurance(
  Json fiche,
  Json? item,
  List<Json> faites,
  Json params,
) {
  final typ = fiche['type'];
  if (typ != 'cardio' && typ != 'wod') return null;
  if (faites.isEmpty || item == null) return null;
  final first = koachSerie(faites.first);
  if (first == null) return null;
  final setsW = (item['sets'] as num?) ?? 1;
  final num sets = setsW > 1 ? setsW : 1;
  if (typ == 'cardio') {
    const vitesse = 2.6;
    num? s = item['secondsHigh'] as num? ?? item['secondsLow'] as num?;
    double ecrit;
    if (s != null) {
      ecrit = (s * sets).toDouble();
    } else if (item['distanceMeters'] is num) {
      ecrit = (item['distanceMeters'] as num) * sets / vitesse;
    } else {
      ecrit = 0;
    }
    final f0 = item['targetFlames'] as num?;
    final exId = '${item['exerciseId']}';
    const qualiteIds = [
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
    final qualite =
        (f0 != null && (f0 >= 10 ? 0.0 : (11 - f0) / 2.0) <= 3 + 1e-9) ||
        item['intensity'] != null ||
        qualiteIds.any(exId.contains);
    final poids = qualite
        ? ((params['mesure'] as Map?)?['cardio_poids_qualite'] as num? ?? 1.0)
        : 1.0;
    var fait = 0.0;
    for (final f in faites) {
      fait += ((f['seconds'] as num?) ?? 0).toDouble();
    }
    final reussi = faites.every((f) => f['success'] == true);
    first['demand'] = ecrit * poids / 60.0;
    first['doneShare'] = reussi
        ? 1.0
        : (ecrit > 0 ? math.min(1.0, fait / ecrit) : 1.0);
    first['dose'] = fait * (qualite ? 1.5 : 1.0) / 3600.0;
    first['fatigueSets'] = math.min(6.0, fait / 600.0);
    first['target'] = {'flames': f0};
  } else {
    final reussi = faites.every((f) => f['success'] == true);
    first['demand'] = 1.0;
    first['doneShare'] = reussi ? 1.0 : 0.9;
    first['dose'] = 1.0;
    first['fatigueSets'] = sets.toDouble();
    first['target'] = {'flames': item['targetFlames']};
  }
  first['setIndex'] = 0;
  return first;
}

/// Une séance faite de l'application, convertie en événements (sans
/// `plan` : séance servie hors de Koach, comme l'historique et le
/// walk-forward).
class KoachSeanceConvertie {
  /// Clé du journal de l'application (`S<s>-J<j>`).
  final String cle;
  final int semaineS;
  final int jour;
  final Json debut;
  final List<Json> series;

  /// Par série : catégorie, référence et type de la ligne (export du
  /// journal moteur, mesure B du walk-forward).
  final List<Json> meta;
  final Json fin;
  const KoachSeanceConvertie({
    required this.cle,
    required this.semaineS,
    required this.jour,
    required this.debut,
    required this.series,
    required this.meta,
    required this.fin,
  });
}

/// Convertit une séance du journal (`SessionRecord.toJson()`) : [info] :
/// journée du programme ; [fiches] : fiches de Koach (type des lignes) ;
/// [metaDe] : catégorie, référence et type d'une ligne ; [cibles] : cibles
/// de Koach par (emplacement, rang) quand la séance a été servie par lui ;
/// [douleursFin] : douleurs signalées après l'ouverture.
KoachSeanceConvertie? koachSeanceDe(
  Json session, {
  required kc.CivilDate lundi,
  required String cle,
  required int semaineS,
  required KoachJourInfo? info,
  required Map<String, Json> fiches,
  required Json params,
  Json Function(Json serie)? metaDe,
  Json? Function(String slot, int index)? cibles,
  List<Json>? douleursFin,
  num? poidsKg,
}) {
  final date = kc.CivilDate.parse('${session['date']}');
  final jour = koachJour(lundi, date);
  final sets = [
    for (final s in (session['sets'] as List? ?? const []))
      if (s is Map) s.cast<String, Object?>(),
  ];
  final items = {
    for (final it in info?.items ?? const <Json>[]) '${it['slotId']}': it,
  };
  final series = <Json>[];
  final meta = <Json>[];
  // Lignes d'endurance : une série par ligne.
  final enduranceVue = <String>{};
  for (final rec in sets) {
    final ex = '${rec['exerciseId']}';
    final fiche = fiches[ex];
    if (fiche == null) continue;
    final slot = rec['slotId'] as String?;
    final typ = fiche['type'];
    Json? s;
    if (typ == 'cardio' || typ == 'wod') {
      final cle0 = '$ex|$slot';
      if (!enduranceVue.add(cle0)) continue;
      s = koachSerieEndurance(fiche, slot == null ? null : items[slot], [
        for (final r in sets)
          if (r['exerciseId'] == ex && r['slotId'] == slot) r,
      ], params);
    } else {
      final idx = rec['setIndex'];
      s = koachSerie(
        rec,
        cible: slot != null && idx is int ? cibles?.call(slot, idx) : null,
      );
    }
    if (s == null) continue;
    series.add({'type': 'serie', 'serie': s});
    meta.add(metaDe?.call(s) ?? {'cat': null, 'ref': null, 'type': typ});
  }
  if (series.isEmpty) return null;
  final hc = session['healthCheck'];
  final bilan = hc is Map && hc.isNotEmpty ? koachCopie(hc) as Json : null;
  final debut = <String, Object?>{
    'type': 'seance_debut',
    'jour': jour,
    'bilan': bilan,
    'poids_kg': poidsKg ?? session['bodyWeightKg'],
    'contexte': info == null
        ? {'semaine': semaineS - 1}
        : koachContexteDe(info),
  };
  final fin = <String, Object?>{
    'type': 'seance_fin',
    'jour': jour,
    'douleurs': douleursFin,
    'seance': {
      'sets': [for (final e in series) e['serie']],
    },
  };
  return KoachSeanceConvertie(
    cle: cle,
    semaineS: semaineS,
    jour: jour,
    debut: debut,
    series: series,
    meta: meta,
    fin: fin,
  );
}

/// Profil de Koach du programme importé (`journal_app.profil_de`,
/// correspondance de référence du critère 10) et des programmes créés
/// (`_pkProfilKoach` : niveaux de mouvement connus).
Json koachProfil({
  required kc.AthleteProfile? athlete,
  required double? premierePesee,
  required Map<String, List<Object?>> declares,
}) {
  final levels = ['beginner', 'intermediate', 'advanced', 'elite'];
  final exp = athlete?.experience?.code;
  final niveau = exp != null && levels.contains(exp) ? levels.indexOf(exp) : 2;
  var poids = athlete?.bodyWeightKg;
  if (poids == null || poids <= 0) poids = premierePesee;
  final fragiles = <Object?>[];
  for (final lim in athlete?.limitations ?? const <kc.Limitation>[]) {
    final j = lim.toJson();
    final z = j['zone'];
    if (z is String && z.isNotEmpty) {
      fragiles.add({
        'zone': z,
        'since': j['since'],
        'discomfort': j['discomfort'],
      });
    }
  }
  return {
    'niveau': niveau,
    'sexe': athlete?.sex.code,
    'poids_kg': poids,
    'declares': declares,
    'zones_fragiles': fragiles,
  };
}

/// Courbe de population du moteur (`Modele.gK` avec les constantes de
/// `journal_app.py` : forme 0,2, échelle 0,10), pour convertir une charge
/// de travail en 1RM (`declares_initiaux`).
double koachCourbePopulation(double reps) => ko.Modele.gK(0.2, 0.10, reps);
