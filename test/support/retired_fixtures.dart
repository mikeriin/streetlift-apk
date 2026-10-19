// G2 : données des fonctions retirées (WOD, séances manuelles, crédits,
// motivation L12) telles que 6.0.x les écrivait dans son document d'état et
// dans ses sauvegardes (format 3). JSON brut : plus aucune classe de
// l'application ne les lit. Aucune donnée réelle.

/// Journal d'une séance manuelle terminée (clé « S0-J<id> »).
Map<String, dynamic> manualSessionLog(String id, {String day = '10'}) => {
  'done': true,
  'finishedAt': '2026-08-${day}T19:00:00.000',
  'title': 'Perso $id',
  'customId': id,
  'exerciseNames': {'CU-u$id': 'Tractions'},
  'ex': {
    'CU-u$id': {
      'sets': [
        for (var i = 0; i < 3; i++)
          {
            'kg': '',
            'reps': '10',
            'rir': '',
            'v': '',
            'done': true,
            'completedAt': '2026-08-${day}T18:5$i:00.000',
          },
      ],
      'note': '',
      'showKg': null,
      'showRir': null,
      'showV': null,
    },
  },
};

/// Sections retirées d'un utilisateur de 6.0.x : 2 séances perso (dont une
/// répétée, donc archivée), 3 résultats de WOD, 1 WOD créé, 1 WOD retiré du
/// catalogue, 1 WOD modifié, 2 WOD débloqués, crédits, envie, vitrine,
/// motivation.
Map<String, dynamic> retiredSections() => {
  'custom': [
    {
      'id': '1',
      'name': 'Perso 1',
      'items': [
        {
          'uid': 'u1',
          'name': 'Tractions',
          'mode': 'classic',
          'p': {'series': 3, 'reps': 10},
          'kg': null,
          'rest': 90,
          'note': '',
        },
      ],
    },
    {'id': '2', 'name': 'Perso 2', 'items': <Object?>[]},
  ],
  'catalog': {
    'deleted': ['seed3'],
    'edits': {
      'seed4': {'id': 'seed4', 'name': 'Fran modifié', 'type': 'fortime'},
    },
    'user': [
      {'id': 'u-wod-1', 'name': 'Mon WOD', 'type': 'fortime', 'lines': []},
    ],
    'results': {
      'seed1': [
        {
          'at': '2026-08-01T07:00:00',
          'score': '12:00',
          'seconds': 720,
          'completed': true,
          'notes': 'Bon souvenir',
        },
        {
          'at': '2026-08-08T07:00:00',
          'score': '11:40',
          'seconds': 700,
          'completed': true,
          'notes': '',
        },
      ],
      'u-wod-1': [
        {
          'at': '2026-08-15T07:00:00',
          'score': '5 tours',
          'rounds': 5,
          'completed': false,
          'notes': '',
        },
      ],
    },
  },
  'unlocked': {'seed1': 3, 'seed2': 0},
  'legacyGrants': {'seed9': 'credits_v1'},
  'creditsEarnedMax': 21,
  'creditGrants': {'level:2': 2, 'level:3': 2, 'chapter:b1': 3},
  'trialOfDay': {'day': '2026-09-30', 'wod': 'seed5'},
  'weeklyShowcase': {
    'week': '2026-09-28',
    'ids': ['seed6', 'seed7', 'seed8'],
  },
  'wishlist': ['seed2'],
  'motiv': {
    'showAll': true,
    'reviews': {'2026-09-21': 'vu'},
  },
};

/// Catalogue vierge d'une installation 6.0.x qui n'a jamais servi aux WOD :
/// aucune donnée de l'utilisateur (pas de copie, pas d'annonce).
Map<String, dynamic> pristineRetiredSections() => {
  'custom': <Object?>[],
  'catalog': {
    'deleted': <Object?>[],
    'edits': <String, Object?>{},
    'user': <Object?>[],
    'results': <String, Object?>{},
  },
  'unlocked': <String, Object?>{},
  'trialOfDay': {'day': '2026-09-30', 'wod': 'seed5'},
  'wishlist': <Object?>[],
};

/// [document] (format 3) complété des données retirées de 6.0.x : sections,
/// séances manuelles au journal et chrono WOD local.
Map<String, dynamic> withRetiredData(
  Map<String, dynamic> document, {
  bool activeWod = true,
}) {
  final out = Map<String, dynamic>.of(document)..addAll(retiredSections());
  out['logs'] = {
    ...(document['logs'] as Map<String, dynamic>? ?? const {}),
    'S0-J1': manualSessionLog('1'),
    'S0-J1@a1': manualSessionLog('1', day: '03'),
  };
  if (activeWod) {
    out['activeWod'] = {
      'attempt': 'a-1',
      'wod': 'seed1',
      'definition': 12345,
      'startedAt': '2026-09-30T07:00:00.000',
      'savedAt': '2026-09-30T07:05:00.000',
      'ms': 300000,
    };
  }
  return out;
}
