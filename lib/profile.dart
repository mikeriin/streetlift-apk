// L8 (KT-038 à KT-042) — profil de l'utilisateur, questionnaire de santé
// préalable, mode prudent, consentement et questions progressives.
//
// G6 (D1.6) : le profil L8 est remplacé par le profil d'athlète v2
// (athlete_profile.dart). Ce fichier reste le lecteur de la section
// `profile` des sauvegardes (import des anciennes, valeurs validées) et
// garde le bloc santé du questionnaire L13 (consentement, réponses, accord
// du médecin) et les règles du mode prudent, inchangées. Ses écrans
// (démarrage court, confirmation, questions progressives, catalogue
// d'objectifs) sont retirés ; les champs restent lus par les anciens
// moteurs L10/L11 jusqu'à leur retrait (G10).
//
// Modèle pur (aucune dépendance Flutter) : toutes les règles sont des
// fonctions déterministes, avec l'horloge passée en paramètre.
// Contrat : docs/CONTRAT_L8.md.

/// Version du format de la section `profile` de la sauvegarde.
const int kProfileVersion = 1;

/// Source d'une réponse (KT-038).
const kProfileSources = {'declared', 'estimated', 'measured'};

final RegExp _pDayRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final RegExp _pAtRe = RegExp(
  r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2}(?:\.\d{1,6})?)?$',
);

String _two(int n) => n.toString().padLeft(2, '0');

/// Horodatage local « AAAA-MM-JJTHH:MM:SS » (même forme que Koach).
String profileAt(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}'
    'T${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

/// Date civile « AAAA-MM-JJ ».
String profileDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

bool _okAt(Object? v) =>
    v is String && _pAtRe.hasMatch(v) && DateTime.tryParse(v) != null;
bool _okDay(Object? v) =>
    v is String && _pDayRe.hasMatch(v) && DateTime.tryParse(v) != null;

// ------------------------------------------------------------- catalogues

/// Objectif du catalogue (extensible par données ; `active` = proposé en V1).
class GoalSpec {
  final String id, label, hint;
  final bool active;
  const GoalSpec(this.id, this.label, this.hint, {this.active = true});
}

/// « Forme et santé » en premier (KT-039). Prise de muscle, Figures et
/// Énergie existent dans le modèle mais sont désactivés en V1.
const kGoals = <GoalSpec>[
  GoalSpec('health', 'Forme et santé', 'Bouger régulièrement, sans excès'),
  GoalSpec('strength', 'Force', 'Soulever ou tirer plus lourd'),
  GoalSpec(
    'endurance',
    'Endurance en répétitions',
    'Enchaîner plus de répétitions',
  ),
  GoalSpec(
    'event',
    'Préparer un test ou une compétition',
    'Des épreuves, des cibles et une date',
  ),
  GoalSpec('muscle', 'Prise de muscle', 'Bientôt', active: false),
  GoalSpec('skills', 'Figures', 'Bientôt', active: false),
  GoalSpec('energy', 'Énergie', 'Bientôt', active: false),
];

GoalSpec? goalById(String? id) {
  for (final g in kGoals) {
    if (g.id == id) return g;
  }
  return null;
}

/// Épreuves proposées pour l'objectif « test ou compétition ».
const kEventItems = <(String id, String label, String unit)>[
  ('pull_1rm', 'Traction lestée (1 répétition)', 'kg de lest'),
  ('dip_1rm', 'Dip lesté (1 répétition)', 'kg de lest'),
  ('mu_1rm', 'Muscle-up lesté (1 répétition)', 'kg de lest'),
  ('squat_1rm', 'Back squat (1 répétition)', 'kg barre'),
  ('pullups_max', 'Tractions au poids du corps', 'répétitions'),
  ('dips_max', 'Dips au poids du corps', 'répétitions'),
  ('pushups_max', 'Pompes', 'répétitions'),
  ('mu_max', 'Muscle-ups au poids du corps', 'répétitions'),
];

String? eventItemLabel(String id) {
  for (final e in kEventItems) {
    if (e.$1 == id) return e.$2;
  }
  return null;
}

String eventItemUnit(String id) {
  for (final e in kEventItems) {
    if (e.$1 == id) return e.$3;
  }
  return '';
}

/// Ancienneté d'entraînement.
const kExperience = <(String, String)>[
  ('none', 'Je débute'),
  ('lt6m', 'Moins de 6 mois'),
  ('6to24m', '6 mois à 2 ans'),
  ('2to5y', '2 à 5 ans'),
  ('gt5y', 'Plus de 5 ans'),
];

/// Lieux d'entraînement.
const kPlaces = <(String, String)>[
  ('home_none', 'Maison sans matériel'),
  ('home_equipped', 'Maison équipée'),
  ('park', 'Parc de street workout'),
  ('gym', 'Salle'),
];

String placeLabel(String id) {
  for (final p in kPlaces) {
    if (p.$1 == id) return p.$2;
  }
  return id;
}

/// Matériel normalisé (identifiants stables, à rattacher à la liste du
/// pack de contenu L9 lors de son intégration, L9b).
const kEquipment = <(String, String)>[
  ('pullup_bar', 'Barre de traction'),
  ('dip_bars', 'Barres parallèles'),
  ('rings', 'Anneaux'),
  ('bands', 'Élastiques'),
  ('dumbbells', 'Haltères'),
  ('kettlebell', 'Kettlebell'),
  ('barbell', 'Barre et disques'),
  ('rack', 'Rack ou cage'),
  ('bench', 'Banc'),
  ('weight_belt', 'Ceinture ou gilet de lest'),
  ('machines', 'Machines et poulies'),
  ('box', 'Box ou marche'),
  ('jump_rope', 'Corde à sauter'),
  ('erg', 'Ergomètre (rameur, vélo)'),
  ('mat', 'Tapis'),
];

String equipmentLabel(String id) {
  for (final e in kEquipment) {
    if (e.$1 == id) return e.$2;
  }
  return id;
}

/// Matériel proposé par défaut pour chaque lieu (modifiable).
const kPlaceDefaults = <String, List<String>>{
  'home_none': ['mat'],
  'home_equipped': ['pullup_bar', 'bands', 'dumbbells', 'mat'],
  'park': ['pullup_bar', 'dip_bars'],
  'gym': [
    'pullup_bar',
    'dip_bars',
    'dumbbells',
    'barbell',
    'rack',
    'bench',
    'machines',
  ],
};

/// Repère de niveau : question concrète par mouvement de référence (KT-039).
class BenchmarkSpec {
  final String id, question;
  final List<String> bands;
  const BenchmarkSpec(this.id, this.question, this.bands);
}

const kBenchmarks = <BenchmarkSpec>[
  BenchmarkSpec('pushups', 'Combien de pompes d’affilée, en ce moment ?', [
    '0',
    '1-9',
    '10-24',
    '25-44',
    '45 et plus',
  ]),
  BenchmarkSpec('pullups', 'Combien de tractions d’affilée ?', [
    '0',
    '1-4',
    '5-11',
    '12-19',
    '20 et plus',
  ]),
];

/// Niveaux déduits d'une tranche (0 à 4).
const kLevels = ['beginner', 'novice', 'intermediate', 'advanced', 'expert'];
const kLevelLabels = {
  'beginner': 'débutant',
  'novice': 'novice',
  'intermediate': 'intermédiaire',
  'advanced': 'avancé',
  'expert': 'expert',
};

/// Tranche d'un nombre de répétitions (utilisée pour la migration).
int benchmarkBand(String id, double reps) {
  final cuts = id == 'pullups' ? const [1, 5, 12, 20] : const [1, 10, 25, 45];
  var band = 0;
  for (final c in cuts) {
    if (reps >= c) band++;
  }
  return band;
}

/// Repère global : la tranche la plus basse des mouvements renseignés
/// (prudence). Null si aucune réponse.
String? levelFromBenchmarks(Map<String, int> bands) {
  if (bands.isEmpty) return null;
  final lowest = bands.values.reduce((a, b) => a < b ? a : b);
  return kLevels[lowest.clamp(0, 4)];
}

/// Mode d'autonomie et ton de Koach.
const kAutonomy = <(String, String)>[
  ('guided', 'Guidé'),
  ('assisted', 'Assisté'),
  ('expert', 'Expert'),
];
const kTones = <(String, String)>[
  ('kind', 'Bienveillant'),
  ('demanding', 'Exigeant'),
  ('neutral', 'Neutre'),
];

String labelOf(List<(String, String)> list, String? id) {
  for (final e in list) {
    if (e.$1 == id) return e.$2;
  }
  return '—';
}

/// Zones des gênes et limitations.
const kZones = <(String, String)>[
  ('shoulder', 'Épaule'),
  ('elbow', 'Coude'),
  ('wrist', 'Poignet'),
  ('lower_back', 'Bas du dos'),
  ('neck', 'Cou'),
  ('hip', 'Hanche'),
  ('knee', 'Genou'),
  ('ankle', 'Cheville'),
  ('other', 'Autre'),
];

/// Sommeil habituel (tranches) et stress.
const kSleep = <(String, String)>[
  ('lt5', 'Moins de 5 h'),
  ('5to6', '5 à 6 h'),
  ('6to7', '6 à 7 h'),
  ('7to8', '7 à 8 h'),
  ('gt8', 'Plus de 8 h'),
];
const kStress = <(String, String)>[
  ('low', 'Faible'),
  ('medium', 'Moyen'),
  ('high', 'Élevé'),
];

// ------------------------------------------ questionnaire de santé (KT-041)

/// Question d'aptitude à l'activité physique. Formulation propre à Kalis
/// Track, **inspirée** du PAR-Q+ sans le reproduire : les conditions du
/// PAR-Q+ (eparmedx.com, « Terms and Conditions », consultées le
/// 26/09/2026) interdisent toute modification et l'intégration dans un
/// produit sans accord écrit de la PAR-Q+ Collaboration. À faire valider
/// (registre de validation, contrat L8 §6).
class HealthQuestion {
  final String id, text;

  /// Déclencheur nommé en plus du « oui » générique.
  final String? trigger;
  const HealthQuestion(this.id, this.text, {this.trigger});
}

const kHealthQuestions = <HealthQuestion>[
  HealthQuestion(
    'heart',
    'Un médecin t’a-t-il déjà parlé d’un problème de cœur ou de tension '
        'artérielle ?',
    trigger: 'heart',
  ),
  HealthQuestion(
    'chest',
    'Ressens-tu parfois une douleur dans la poitrine, au repos ou pendant un '
        'effort ?',
  ),
  HealthQuestion(
    'dizzy',
    'Au cours des 12 derniers mois, as-tu perdu connaissance ou l’équilibre à '
        'cause d’un étourdissement ?',
  ),
  HealthQuestion(
    'chronic',
    'Es-tu suivi(e) pour une maladie de longue durée (autre qu’un problème '
        'de cœur ou de tension) ?',
  ),
  HealthQuestion(
    'meds',
    'Prends-tu actuellement des médicaments prescrits pour une maladie de '
        'longue durée ?',
  ),
  HealthQuestion(
    'joint',
    'As-tu un problème d’os, d’articulation ou de muscle qui pourrait '
        's’aggraver en bougeant plus ?',
  ),
  HealthQuestion(
    'supervised',
    'Un professionnel de santé t’a-t-il conseillé de ne faire de l’activité '
        'physique que sous surveillance ?',
  ),
  HealthQuestion(
    'pregnancy',
    'Es-tu enceinte, ou as-tu accouché au cours des 6 derniers mois ?',
    trigger: 'pregnancy',
  ),
];

/// Gêne ou limitation (donnée de santé potentielle).
class Injury {
  final String zone;
  final int level; // gêne 0-10
  final String since; // AAAA-MM-JJ (approximatif)
  final String at; // saisie
  const Injury(this.zone, this.level, this.since, this.at);

  Map<String, dynamic> toJson() => {
    'zone': zone,
    'level': level,
    'since': since,
    'at': at,
  };
}

/// Bloc santé : écrit seulement avec un consentement donné (KT-042).
class HealthData {
  /// `given`, `refused`, `withdrawn` ; null = jamais demandé.
  String? consent;
  String? consentAt;

  /// Réponses au questionnaire (id → oui/non) et date des réponses.
  final Map<String, bool> answers = {};
  String? answeredAt;

  /// Accord du médecin déclaré par l'utilisateur (date de la déclaration).
  String? clearanceAt;

  final List<Injury> injuries = [];

  bool get consentGiven => consent == 'given';

  /// Questionnaire complet (toutes les questions ont une réponse).
  bool get complete =>
      answeredAt != null &&
      kHealthQuestions.every((q) => answers.containsKey(q.id));

  bool get hasHealthContent =>
      answers.isNotEmpty || clearanceAt != null || injuries.isNotEmpty;

  /// Efface toutes les réponses de santé (retrait du consentement,
  /// suppression demandée). Le choix de consentement reste daté.
  void clearContent() {
    answers.clear();
    answeredAt = null;
    clearanceAt = null;
    injuries.clear();
  }

  Map<String, dynamic> toJson() => {
    if (consent != null) 'consent': {'status': consent, 'at': consentAt},
    if (answeredAt != null)
      'answers': {'at': answeredAt, 'q': Map<String, bool>.of(answers)},
    if (clearanceAt != null) 'clearance': {'at': clearanceAt},
    if (injuries.isNotEmpty) 'injuries': [for (final i in injuries) i.toJson()],
  };

  HealthData copy() {
    final h = HealthData()
      ..consent = consent
      ..consentAt = consentAt
      ..answeredAt = answeredAt
      ..clearanceAt = clearanceAt;
    h.answers.addAll(answers);
    h.injuries.addAll(injuries);
    return h;
  }
}

// -------------------------------------------------------- mode prudent

/// Raisons du mode prudent (KT-041).
const kCautionReasonLabels = {
  'no_consent': 'Données de santé non autorisées',
  'unanswered': 'Questionnaire de santé sans réponse',
  'answer_yes': 'Une réponse « oui » au questionnaire',
  'heart': 'Problème de cœur ou de tension déclaré',
  'pregnancy': 'Grossesse ou accouchement récent déclaré',
  'age65': '65 ans ou plus',
  'discomfort': 'Une gêne supérieure à 3/10',
};

/// Plafonds du mode prudent (KT-041).
const double kCautionMaxPct = 0.80;
const int kCautionMinRir = 3;

class CautionStatus {
  /// Raisons présentes (même levées par l'accord du médecin).
  final List<String> reasons;

  /// Mode prudent en vigueur.
  final bool active;

  /// Accord du médecin déclaré et encore valable.
  final bool cleared;

  /// L'accord du médecin peut lever les raisons présentes.
  final bool clearable;
  const CautionStatus(this.reasons, this.active, this.cleared, this.clearable);

  static const off = CautionStatus([], false, false, false);
}

/// Âge au plus tard cette année (année civile − année de naissance).
int? ageInYear(int? birthYear, DateTime now) =>
    birthYear == null ? null : now.year - birthYear;

/// Évaluation du mode prudent. Règles (contrat L8 §4) :
/// - consentement non donné → prudent (aucune réponse de santé possible),
///   non levable ;
/// - questionnaire incomplet → prudent, non levable (répondre le lève) ;
/// - « oui », 65 ans et plus, grossesse, problème de cœur ou de tension,
///   gêne > 3/10 → prudent, levable par l'accord du médecin daté, valable
///   pour les réponses et gênes déclarées au plus tard à cette date.
///
/// G6 : avec le profil v2, l'année de naissance ([birth]) et les gênes
/// ([discomforts]) viennent de lui, chacune avec sa date de saisie ; le
/// consentement, les réponses et l'accord restent ceux du bloc santé.
CautionStatus evaluateCaution(
  UserProfile p,
  DateTime now, {
  ({int year, String at})? birth,
  List<({int level, String at})>? discomforts,
}) {
  final reasons = <String>[];
  final h = p.health;
  final by = birth?.year ?? p.intValue('birthYear');
  final age = ageInYear(by, now);
  if (!h.consentGiven) {
    reasons.add('no_consent');
    if (age != null && age >= 65) reasons.add('age65');
    return CautionStatus(reasons, true, false, false);
  }
  if (!h.complete) {
    reasons.add('unanswered');
    if (age != null && age >= 65) reasons.add('age65');
    return CautionStatus(reasons, true, false, false);
  }
  final dated = <String>[]; // horodatages des raisons levables
  if (h.answers.values.any((v) => v)) {
    reasons.add('answer_yes');
    dated.add(h.answeredAt!);
  }
  for (final q in kHealthQuestions) {
    if (q.trigger != null && h.answers[q.id] == true) reasons.add(q.trigger!);
  }
  if (age != null && age >= 65) {
    reasons.add('age65');
    dated.add(birth?.at ?? p.fields['birthYear']?.at ?? h.answeredAt!);
  }
  final pains = [
    for (final i in discomforts ??
        [for (final i in h.injuries) (level: i.level, at: i.at)])
      if (i.level > 3) i,
  ];
  if (pains.isNotEmpty) {
    reasons.add('discomfort');
    for (final i in pains) {
      dated.add(i.at);
    }
  }
  if (reasons.isEmpty) return CautionStatus.off;
  final clear = h.clearanceAt;
  final cleared = clear != null && dated.every((d) => d.compareTo(clear) <= 0);
  return CautionStatus(reasons, !cleared, cleared, true);
}

/// Test maximal repéré dans le programme (« TEST … », intensité maximale).
bool isMaxTest(String name, String intensity) {
  final n = name.trim().toUpperCase();
  final i = intensity.trim().toLowerCase();
  return n.startsWith('TEST ') || i.startsWith('maximum') || i == 'max';
}

/// Pourcentage appliqué à une charge exprimée en % du 1RM : plafonné à
/// 80 % sur les mouvements principaux en mode prudent.
double cautionPct(double pct, {required bool mainLift, required bool active}) =>
    active && mainLift && pct > kCautionMaxPct ? kCautionMaxPct : pct;

// --------------------------------------------------------------- profil

/// Réponse datée avec sa source (KT-038).
class ProfileField {
  final Object? value;
  final String at;
  final String source;
  const ProfileField(this.value, this.at, this.source);

  Map<String, dynamic> toJson() => {'v': value, 'at': at, 'src': source};
}

/// Champs de santé potentiels : jamais écrits sans consentement.
const kHealthFields = {'sleep', 'stress'};

/// Validation d'une valeur de champ ; null = valide, sinon message.
String? validateField(String key, Object? v) {
  bool enumIn(List<(String, String)> list) =>
      v is String && list.any((e) => e.$1 == v);
  bool strList(int max, int len) =>
      v is List &&
      v.length <= max &&
      v.every((e) => e is String && e.trim().isNotEmpty && e.length <= len);
  final ok = switch (key) {
    'birthYear' => v is int && v >= 1900 && v <= 2100,
    'goalPrimary' => v is String && goalById(v) != null,
    'goalSecondary' => v is String && goalById(v) != null,
    'goalWeight' => v is int && v >= 50 && v <= 100 && v % 10 == 0,
    'eventGoal' => _okEvent(v),
    'experience' => enumIn(kExperience),
    'days' =>
      v is List &&
          v.length <= 7 &&
          v.every((d) => d is int && d >= 1 && d <= 7) &&
          v.toSet().length == v.length,
    'sessionMinutes' => v is int && v >= 10 && v <= 240,
    'places' =>
      v is Map &&
          v.length <= kPlaces.length &&
          v.entries.every(
            (e) =>
                kPlaces.any((p) => p.$1 == e.key) &&
                e.value is List &&
                (e.value as List).length <= kEquipment.length &&
                (e.value as List).every(
                  (x) => kEquipment.any((q) => q.$1 == x),
                ),
          ),
    'dayPlace' =>
      v is Map &&
          v.entries.every(
            (e) =>
                RegExp(r'^[1-7]$').hasMatch('${e.key}') &&
                kPlaces.any((p) => p.$1 == e.value),
          ),
    'liked' || 'disliked' => strList(30, 60),
    'physicalJob' => v is bool,
    'sleep' => enumIn(kSleep),
    'stress' => enumIn(kStress),
    'motivation' => v is String && v.length <= 200,
    'autonomy' => enumIn(kAutonomy),
    'tone' => enumIn(kTones),
    'benchmarks' =>
      v is Map &&
          v.entries.every(
            (e) =>
                kBenchmarks.any((b) => b.id == e.key) &&
                e.value is int &&
                (e.value as int) >= 0 &&
                (e.value as int) <= 4,
          ),
    _ => false,
  };
  return ok ? null : key;
}

bool _okEvent(Object? v) {
  if (v is! Map || !_okDay(v['date'])) return false;
  final items = v['items'];
  if (items is! List || items.isEmpty || items.length > 10) return false;
  for (final i in items) {
    if (i is! Map ||
        i['id'] is! String ||
        eventItemLabel(i['id'] as String) == null ||
        (i['target'] != null &&
            (i['target'] is! num ||
                !(i['target'] as num).isFinite ||
                (i['target'] as num) < 0 ||
                (i['target'] as num) > 10000))) {
      return false;
    }
  }
  return true;
}

/// Questions progressives (KT-040, retirées en G6) : gardées pour lire les
/// reports et refus des anciennes sauvegardes.
const kProgressiveQuestions = [
  'experience',
  'disliked',
  'liked',
  'sleep',
  'stress',
  'physicalJob',
  'motivation',
];

class UserProfile {
  int version = kProfileVersion;

  /// `onboarding` (démarrage) ou `migration` (installation existante).
  String origin;
  String createdAt;
  final Map<String, ProfileField> fields = {};
  HealthData health = HealthData();

  /// Événements « profil modifié » (L10 s'en servira pour régénérer).
  final List<({String at, List<String> fields})> events = [];

  /// Questions progressives : dernière séance où une question a été posée,
  /// questions refusées définitivement, reports datés.
  String? lastAskedSession;
  final Set<String> never = {};
  final Map<String, String> later = {};

  UserProfile({required this.origin, required this.createdAt});

  static const maxEvents = 300;

  Object? value(String key) => fields[key]?.value;
  int? intValue(String key) => fields[key]?.value as int?;
  String? stringValue(String key) => fields[key]?.value as String?;
  List<String> listValue(String key) =>
      ((fields[key]?.value as List?) ?? const []).cast<String>();

  Map<String, int> get benchmarks =>
      ((fields['benchmarks']?.value as Map?) ?? const {}).map(
        (k, v) => MapEntry(k as String, v as int),
      );

  String? get level => levelFromBenchmarks(benchmarks);

  UserProfile copy() {
    final p = UserProfile(origin: origin, createdAt: createdAt)
      ..version = version
      ..health = health.copy()
      ..lastAskedSession = lastAskedSession;
    p.fields.addAll(fields);
    p.events.addAll(events);
    p.never.addAll(never);
    p.later.addAll(later);
    return p;
  }

  /// Écrit un champ ; renvoie vrai si la valeur a changé. Un champ de santé
  /// est refusé sans consentement.
  bool setField(
    String key,
    Object? v,
    String at, {
    String source = 'declared',
  }) {
    if (kHealthFields.contains(key) && !health.consentGiven) return false;
    if (v == null) return fields.remove(key) != null;
    if (validateField(key, v) != null) {
      throw ArgumentError('Champ de profil invalide : $key');
    }
    final old = fields[key];
    if (old != null && _same(old.value, v) && old.source == source) {
      return false;
    }
    fields[key] = ProfileField(v, at, source);
    return true;
  }

  void addEvent(String at, Iterable<String> changed) {
    final list = changed.toSet().toList()..sort();
    if (list.isEmpty) return;
    events.add((at: at, fields: list));
    if (events.length > maxEvents) {
      events.removeRange(0, events.length - maxEvents);
    }
  }

  Map<String, dynamic> toJson() => {
    'v': version,
    'origin': origin,
    'createdAt': createdAt,
    'fields': {for (final e in fields.entries) e.key: e.value.toJson()},
    if (health.toJson().isNotEmpty) 'health': health.toJson(),
    if (events.isNotEmpty)
      'events': [
        for (final e in events) {'at': e.at, 'fields': e.fields},
      ],
    if (lastAskedSession != null || never.isNotEmpty || later.isNotEmpty)
      'questions': {
        if (lastAskedSession != null) 'lastSession': lastAskedSession,
        if (never.isNotEmpty) 'never': (never.toList()..sort()),
        if (later.isNotEmpty) 'later': later,
      },
  };

  /// Lecture de la section `profile`. [strict] (import d'un fichier) :
  /// toute valeur hors contrat refuse l'import. Sinon (démarrage) : une
  /// entrée illisible est ignorée et comptée dans [issues].
  static UserProfile? fromJson(
    Object? raw, {
    bool strict = false,
    List<String>? issues,
  }) {
    if (raw == null) return null;
    void bad(String what) {
      if (strict) throw FormatException('Profil : $what invalide.');
      issues?.add(what);
    }

    if (raw is! Map ||
        raw['v'] is! int ||
        (raw['v'] as int) < 1 ||
        (raw['v'] as int) > kProfileVersion ||
        (raw['origin'] != 'onboarding' && raw['origin'] != 'migration') ||
        !_okAt(raw['createdAt'])) {
      bad('profil');
      return null;
    }
    final p = UserProfile(
      origin: raw['origin'] as String,
      createdAt: raw['createdAt'] as String,
    );
    // Santé d'abord : les champs de santé dépendent du consentement.
    final h = raw['health'];
    if (h != null) {
      if (h is! Map) {
        bad('santé');
      } else {
        final c = h['consent'];
        if (c != null) {
          if (c is Map &&
              ['given', 'refused', 'withdrawn'].contains(c['status']) &&
              _okAt(c['at'])) {
            p.health
              ..consent = c['status'] as String
              ..consentAt = c['at'] as String;
          } else {
            bad('consentement');
          }
        }
        final given = p.health.consentGiven;
        final a = h['answers'];
        if (a != null) {
          final q = a is Map ? a['q'] : null;
          if (given &&
              a is Map &&
              _okAt(a['at']) &&
              q is Map &&
              q.length <= kHealthQuestions.length &&
              q.entries.every(
                (e) =>
                    kHealthQuestions.any((x) => x.id == e.key) &&
                    e.value is bool,
              )) {
            p.health.answeredAt = a['at'] as String;
            q.forEach((k, v) => p.health.answers[k as String] = v as bool);
          } else {
            bad('questionnaire');
          }
        }
        final cl = h['clearance'];
        if (cl != null) {
          if (given && cl is Map && _okAt(cl['at'])) {
            p.health.clearanceAt = cl['at'] as String;
          } else {
            bad('accord');
          }
        }
        final inj = h['injuries'];
        if (inj != null) {
          if (!given || inj is! List || inj.length > 20) {
            bad('gênes');
          } else {
            for (final i in inj) {
              if (i is Map &&
                  kZones.any((z) => z.$1 == i['zone']) &&
                  i['level'] is int &&
                  (i['level'] as int) >= 0 &&
                  (i['level'] as int) <= 10 &&
                  _okDay(i['since']) &&
                  _okAt(i['at'])) {
                p.health.injuries.add(
                  Injury(
                    i['zone'] as String,
                    i['level'] as int,
                    i['since'] as String,
                    i['at'] as String,
                  ),
                );
              } else {
                bad('gêne');
              }
            }
          }
        }
      }
    }
    final f = raw['fields'];
    if (f is! Map) {
      bad('champs');
    } else {
      for (final e in f.entries) {
        final k = e.key, x = e.value;
        if (k is! String ||
            x is! Map ||
            !_okAt(x['at']) ||
            !kProfileSources.contains(x['src']) ||
            validateField(k, x['v']) != null ||
            (kHealthFields.contains(k) && !p.health.consentGiven)) {
          bad('champ $k');
          continue;
        }
        p.fields[k] = ProfileField(
          _copyJson(x['v']),
          x['at'] as String,
          x['src'] as String,
        );
      }
    }
    final ev = raw['events'];
    if (ev != null) {
      if (ev is! List || ev.length > maxEvents) {
        bad('événements');
      } else {
        for (final e in ev) {
          if (e is Map &&
              _okAt(e['at']) &&
              e['fields'] is List &&
              (e['fields'] as List).length <= 40 &&
              (e['fields'] as List).every(
                (x) => x is String && x.length <= 40,
              )) {
            p.events.add((
              at: e['at'] as String,
              fields: (e['fields'] as List).cast<String>(),
            ));
          } else {
            bad('événement');
          }
        }
      }
    }
    final qs = raw['questions'];
    if (qs != null) {
      if (qs is! Map) {
        bad('questions');
      } else {
        final last = qs['lastSession'];
        if (last != null) {
          if (last is String && last.length <= 64) {
            p.lastAskedSession = last;
          } else {
            bad('question posée');
          }
        }
        for (final n in (qs['never'] as List?) ?? const []) {
          if (kProgressiveQuestions.contains(n)) {
            p.never.add(n as String);
          } else {
            bad('question refusée');
          }
        }
        final l = qs['later'];
        if (l != null) {
          if (l is! Map) {
            bad('reports');
          } else {
            l.forEach((k, v) {
              if (kProgressiveQuestions.contains(k) && _okAt(v)) {
                p.later[k as String] = v as String;
              } else {
                bad('report');
              }
            });
          }
        }
      }
    }
    return p;
  }
}

Object? _copyJson(Object? v) {
  if (v is Map) {
    return {for (final e in v.entries) '${e.key}': _copyJson(e.value)};
  }
  if (v is List) return [for (final e in v) _copyJson(e)];
  return v;
}

bool _same(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || !_same(a[k], b[k])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_same(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// Libellés des questions progressives et des champs.
const kFieldLabels = {
  'birthYear': 'Année de naissance',
  'goalPrimary': 'Objectif principal',
  'goalSecondary': 'Objectif secondaire',
  'goalWeight': 'Pondération',
  'eventGoal': 'Épreuves et date',
  'experience': 'Ancienneté d’entraînement',
  'days': 'Jours disponibles',
  'sessionMinutes': 'Durée par séance',
  'places': 'Lieux et matériel',
  'dayPlace': 'Lieu de chaque jour',
  'liked': 'Exercices aimés',
  'disliked': 'Exercices détestés',
  'physicalJob': 'Métier physique',
  'sleep': 'Sommeil habituel',
  'stress': 'Stress',
  'motivation': 'Pourquoi je m’entraîne',
  'autonomy': 'Mode',
  'tone': 'Ton de Koach',
  'benchmarks': 'Repère de niveau',
  'health': 'Questionnaire de santé',
  'consent': 'Consentement santé',
  'clearance': 'Accord du médecin',
  'injuries': 'Gênes et limitations',
};

const kWeekdayShort = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
const kWeekdayLong = [
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];
