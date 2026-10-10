part of 'koach.dart';

// Hors modèle (référence `koach/rupture.py`, cahier KM § 9, contrat
// § 3.7.2 et § 7.3) :
//
// * `Bocpd` : détection bayésienne de rupture en ligne (Adams & MacKay 2007)
//   sur le flux des résidus normalisés moyens de séance ;
// * `Surveillance` : extension du moteur (BOCPD, seuils de secours,
//   diagnostic en 3 questions au plus, actions codées, dossier) ;
// * `importerParametres` / `validerParametres` / `appliquerParametres` :
//   import d'un fichier de paramètres ;
// * `calibrerAlerte` : outil du banc.
//
// Port ligne pour ligne : boucles de longueur fixe, mêmes opérations
// flottantes dans le même ordre. Aucun aléa.

const double log2Pi = 1.8378770664093453; // ln(2π)
const double logPi = 1.1447298858494002; // ln(π)

/// Valeurs par défaut des paramètres `rupture` (`DEFAUTS_RUPTURE`).
const Json defautsRupture = <String, Object?>{
  'hasard': 0.02,
  'alerte': 0.6,
  'fenetre': 3,
  'a_priori_moyenne_sd': 2.0,
  'a_priori_alpha': 2.0,
  'a_priori_beta': 1.0,
  'a_priori_alpha_nouvelle': 5.0,
  'course_max': 200,
  'min_observations': 6,
  'fenetre_seances': 10,
  'silence_semaines': 2,
  'residu_secours': 0.05,
  'residu_secours_semaines': 2,
  'assiduite_secours': 0.7,
  'assiduite_secours_semaines': 2,
  'douleur_secours': 2,
  'elargissement_rien_de_special': 4.0,
  'semaine_allegee_series': 0.6,
  'semaine_allegee_rir': 2.0,
  'journal_dossier': 60,
  'douleur_recente_j': 7,
  'residu_reps_reference': 8.0,
  'mauvais_jours_suite': 2,
  'mauvais_jour_poids': 0.5,
};

/// Causes d'alerte, dans l'ordre (`CAUSES`).
const List<String> ruptureCauses = [
  'rupture',
  'residu',
  'assiduite',
  'douleur',
];

/// Réponses admises à la première question du diagnostic (`REPONSES`).
const List<String> ruptureReponses = [
  'douleur',
  'moins_de_temps',
  'fatigue',
  'rien',
];

const int versionDossier = 1;

/// `d.get(k, defaut)` de Python (une valeur None présente est rendue telle
/// quelle). Partagé par les parts rupture, adherence et dual.
Object? _ruGet(Map<String, Object?> d, String k, Object? defaut) =>
    d.containsKey(k) ? d[k] : defaut;

Object? _ruParam(Json params, String cle) =>
    _ruGet(dictOuVide(params['rupture']), cle, defautsRupture[cle]);

// ----------------------------------------------------------------------
// Représentations textuelles à la Python (messages d'erreur de l'import)
// ----------------------------------------------------------------------

/// `repr(x)` d'un flottant Python (chiffres les plus courts, notation
/// scientifique sous 1e-4 et à partir de 1e16).
String _ruReprDouble(double x) {
  if (x.isNaN) return 'nan';
  if (x.isInfinite) return x > 0 ? 'inf' : '-inf';
  if (x == 0.0) return x.isNegative ? '-0.0' : '0.0';
  var s = x.toString();
  var signe = '';
  if (s.startsWith('-')) {
    signe = '-';
    s = s.substring(1);
  }
  var mant = s;
  var exp10 = 0;
  final ie = s.indexOf('e');
  if (ie >= 0) {
    mant = s.substring(0, ie);
    exp10 = int.parse(s.substring(ie + 1));
  }
  final ip = mant.indexOf('.');
  final entier = ip >= 0 ? mant.substring(0, ip) : mant;
  final frac = ip >= 0 ? mant.substring(ip + 1) : '';
  var chiffres = entier + frac;
  var pointPos = entier.length + exp10;
  var lead = 0;
  while (lead < chiffres.length - 1 && chiffres[lead] == '0') {
    lead++;
  }
  chiffres = chiffres.substring(lead);
  pointPos -= lead;
  var fin = chiffres.length;
  while (fin > 1 && chiffres[fin - 1] == '0') {
    fin--;
  }
  chiffres = chiffres.substring(0, fin);
  final e = pointPos - 1;
  if (e >= -4 && e < 16) {
    if (pointPos <= 0) {
      return '${signe}0.${'0' * -pointPos}$chiffres';
    }
    if (pointPos >= chiffres.length) {
      return '$signe$chiffres${'0' * (pointPos - chiffres.length)}.0';
    }
    return '$signe${chiffres.substring(0, pointPos)}.${chiffres.substring(pointPos)}';
  }
  final m = chiffres.length == 1
      ? chiffres
      : '${chiffres[0]}.${chiffres.substring(1)}';
  final es = e < 0 ? '-' : '+';
  final ea = e.abs();
  return '$signe${m}e$es${ea < 10 ? '0$ea' : '$ea'}';
}

/// `str(x)` de Python pour un scalaire JSON.
String _ruStr(Object? v) {
  if (v == null) return 'None';
  if (v is bool) return v ? 'True' : 'False';
  if (v is double) return _ruReprDouble(v);
  if (v is int) return v.toString();
  if (v is String) return v;
  if (v is List<Object?>) {
    return '[${[for (final x in v) _ruRepr(x)].join(', ')}]';
  }
  if (v is Map<Object?, Object?>) {
    return '{${[for (final e in v.entries) '${_ruRepr(e.key)}: ${_ruRepr(e.value)}'].join(', ')}}';
  }
  return v.toString();
}

/// `repr(x)` de Python pour un scalaire JSON.
String _ruRepr(Object? v) {
  if (v is String) {
    final q = (v.contains("'") && !v.contains('"')) ? '"' : "'";
    final b = StringBuffer(q);
    for (var i = 0; i < v.length; i++) {
      final ch = v[i];
      if (ch == '\\') {
        b.write(r'\\');
      } else if (ch == q) {
        b.write('\\$q');
      } else if (ch == '\n') {
        b.write(r'\n');
      } else if (ch == '\r') {
        b.write(r'\r');
      } else if (ch == '\t') {
        b.write(r'\t');
      } else {
        b.write(ch);
      }
    }
    b.write(q);
    return b.toString();
  }
  return _ruStr(v);
}

// ----------------------------------------------------------------------
// Fonction gamma
// ----------------------------------------------------------------------
const double lanczosG = 7.0;
const List<double> lanczosC = [
  0.99999999999980993,
  676.5203681218851,
  -1259.1392167224028,
  771.32342877765313,
  -176.61502916214059,
  12.507343278686905,
  -0.13857109526572012,
  9.9843695780195716e-6,
  1.5056327351493116e-7,
];

/// ln Γ(x) pour x > 0 (Lanczos, g = 7, 9 coefficients ; formule des
/// compléments sous 0,5).
double lgamma(double x) {
  if (x <= 0.0) {
    throw ArgumentError('lgamma : argument positif attendu');
  }
  if (x < 0.5) {
    return logPi - math.log(math.sin(math.pi * x)) - lgamma(1.0 - x);
  }
  final z = x - 1.0;
  var a = lanczosC[0];
  for (var i = 1; i < 9; i++) {
    a += lanczosC[i] / (z + i);
  }
  final t = z + lanczosG + 0.5;
  return 0.5 * log2Pi + (z + 0.5) * math.log(t) - t + math.log(a);
}

// ----------------------------------------------------------------------
// BOCPD
// ----------------------------------------------------------------------

/// Détection de rupture en ligne, modèle gaussien à moyenne et variance
/// inconnues, a priori normal-gamma (μ0, κ0, α0, β0), prédictive de
/// Student, hasard constant H (voir la référence pour les conventions).
class Bocpd {
  Bocpd({
    num hasard = 0.02,
    num fenetre = 10,
    num minObservations = 6,
    num courseMax = 200,
    num mu0 = 0.0,
    num kappa0 = 0.25,
    num alpha0 = 2.0,
    num beta0 = 1.0,
    num alphaNouvelle = 5.0,
  }) : hasard = hasard.toDouble(),
       fenetre = ent(fenetre),
       minObservations = ent(minObservations),
       courseMax = ent(courseMax),
       mu0 = mu0.toDouble(),
       kappa0 = kappa0.toDouble(),
       alpha0 = alpha0.toDouble(),
       beta0 = beta0.toDouble(),
       alphaNouvelle = alphaNouvelle.toDouble() {
    reinitialiser();
  }

  static Bocpd depuisParams(Json params) {
    final sd = dbl(_ruParam(params, 'a_priori_moyenne_sd'));
    // La fenêtre vient de `fenetre_seances` (10) et non de `fenetre` (3).
    return Bocpd(
      hasard: dbl(_ruParam(params, 'hasard')),
      fenetre: ent(_ruParam(params, 'fenetre_seances')),
      minObservations: ent(_ruParam(params, 'min_observations')),
      courseMax: ent(_ruParam(params, 'course_max')),
      mu0: 0.0,
      kappa0: 1.0 / (sd * sd),
      alpha0: dbl(_ruParam(params, 'a_priori_alpha')),
      beta0: dbl(_ruParam(params, 'a_priori_beta')),
      alphaNouvelle: dbl(_ruParam(params, 'a_priori_alpha_nouvelle')),
    );
  }

  final double hasard;
  final int fenetre;
  final int minObservations;
  final int courseMax;
  final double mu0;
  final double kappa0;
  final double alpha0;
  final double beta0;
  final double alphaNouvelle;
  int n = 0;
  List<int> longueurs = [0];
  List<double> logP = [0.0];
  List<double> mu = [];
  List<double> kappa = [];
  List<double> alpha = [];
  List<double> beta = [];
  double pRupture = 0.0;

  void reinitialiser() {
    // Avant toute observation : une seule course, vide (r = 0), à l'a priori.
    n = 0;
    longueurs = [0];
    logP = [0.0];
    mu = [mu0];
    kappa = [kappa0];
    alpha = [alpha0];
    beta = [beta0];
    pRupture = 0.0;
  }

  /// Log-densité prédictive : Student à 2α degrés de liberté, centre μ,
  /// échelle² β(κ+1)/(ακ).
  static double logStudent(
    double x,
    double mu,
    double kappa,
    double alpha,
    double beta,
  ) {
    final nu = 2.0 * alpha;
    final s2 = beta * (kappa + 1.0) / (alpha * kappa);
    final d = x - mu;
    return lgamma(alpha + 0.5) -
        lgamma(alpha) -
        0.5 * (math.log(nu * s2) + logPi) -
        (alpha + 0.5) * math.log(1.0 + d * d / (nu * s2));
  }

  /// Verse une observation, renvoie P(rupture dans les `fenetre` dernières
  /// observations) (0 avant `minObservations`).
  double ajouter(num x0) {
    final x = x0.toDouble();
    final h = hasard;
    final logH = math.log(h);
    final log1h = math.log(1.0 - h);
    final k = longueurs.length;
    // Prédictive de chaque course.
    final lpred = List<double>.filled(k, 0.0);
    for (var i = 0; i < k; i++) {
      lpred[i] = logStudent(x, mu[i], kappa[i], alpha[i], beta[i]);
    }
    // Rupture juste avant x : nouvelle course de longueur 1, prédictive a
    // priori.
    final (a0, b0) = _aPrioriVariance();
    final lp0 = logStudent(x, mu0, kappa0, a0, b0);
    final nLong = <int>[];
    final nLp = <double>[];
    final nMu = <double>[];
    final nKa = <double>[];
    final nAl = <double>[];
    final nBe = <double>[];
    // Croissance : r -> r + 1, masse (1 - H) p(r) pred(r).
    for (var i = 0; i < k; i++) {
      final r = longueurs[i];
      var lw = logP[i] + lpred[i] + log1h;
      if (r == 0) {
        // Course vide de départ : elle devient la course initiale.
        lw = logP[i] + lpred[i];
      }
      final mui = mu[i];
      final ka = kappa[i];
      final al = alpha[i];
      final be = beta[i];
      final d = x - mui;
      final mu2 = (ka * mui + x) / (ka + 1.0);
      final be2 = be + ka * d * d / (2.0 * (ka + 1.0));
      var r2 = r + 1;
      if (r2 > courseMax) {
        r2 = courseMax;
      }
      if (nLong.isNotEmpty && nLong[nLong.length - 1] == r2) {
        // Case absorbante : on additionne les masses, on garde les
        // statistiques de la course la plus ancienne (celle-ci).
        final der = nLp.length - 1;
        final a = nLp[der];
        final mxa = a > lw ? a : lw;
        nLp[der] = mxa + math.log(math.exp(a - mxa) + math.exp(lw - mxa));
        nMu[der] = mu2;
        nKa[der] = ka + 1.0;
        nAl[der] = al + 0.5;
        nBe[der] = be2;
      } else {
        nLong.add(r2);
        nLp.add(lw);
        nMu.add(mu2);
        nKa.add(ka + 1.0);
        nAl.add(al + 0.5);
        nBe.add(be2);
      }
    }
    if (n > 0) {
      // Nouvelle course de longueur 1 (en tête : longueurs croissantes).
      final d = x - mu0;
      nLong.insert(0, 1);
      nLp.insert(0, logH + lp0);
      nMu.insert(0, (kappa0 * mu0 + x) / (kappa0 + 1.0));
      nKa.insert(0, kappa0 + 1.0);
      nAl.insert(0, a0 + 0.5);
      nBe.insert(0, b0 + kappa0 * d * d / (2.0 * (kappa0 + 1.0)));
    }
    // Renormalisation (log-somme-exp).
    var mx = nLp[0];
    for (var i = 1; i < nLp.length; i++) {
      if (nLp[i] > mx) {
        mx = nLp[i];
      }
    }
    var tot = 0.0;
    for (var i = 0; i < nLp.length; i++) {
      tot += math.exp(nLp[i] - mx);
    }
    final lz = mx + math.log(tot);
    for (var i = 0; i < nLp.length; i++) {
      nLp[i] -= lz;
    }
    longueurs = nLong;
    logP = nLp;
    mu = nMu;
    kappa = nKa;
    alpha = nAl;
    beta = nBe;
    n += 1;
    pRupture = _pFenetre();
    return pRupture;
  }

  /// (α, β) de l'a priori de variance d'une course qui commence.
  (double, double) _aPrioriVariance() {
    if (n < minObservations) {
      return (alpha0, beta0);
    }
    var j = 0;
    for (var i = 1; i < logP.length; i++) {
      if (logP[i] > logP[j]) {
        j = i;
      }
    }
    final al = alpha[j];
    final s2 = al > 1.0 ? beta[j] / (al - 1.0) : beta[j] / al;
    final a = alphaNouvelle;
    final b = a > 1.0 ? (a - 1.0) * s2 : a * s2;
    return (a, b);
  }

  double _pFenetre() {
    if (n < minObservations) {
      return 0.0;
    }
    var p = 0.0;
    for (var i = 0; i < longueurs.length; i++) {
      final r = longueurs[i];
      if (r <= fenetre && r != n) {
        p += math.exp(logP[i]);
      }
    }
    if (p > 1.0) {
      p = 1.0;
    }
    return p;
  }

  /// [(longueur, probabilité)] de la longueur de course.
  List<(int, double)> distribution() => [
    for (var i = 0; i < longueurs.length; i++)
      (longueurs[i], math.exp(logP[i])),
  ];

  Json etat() => <String, Object?>{
    'config': <Object?>[
      hasard,
      fenetre.toDouble(),
      minObservations.toDouble(),
      courseMax.toDouble(),
      mu0,
      kappa0,
      alpha0,
      beta0,
      alphaNouvelle,
    ],
    'n': n.toDouble(),
    'p_rupture': pRupture,
    'longueurs': <Object?>[for (final r in longueurs) r.toDouble()],
    'log_p': List<double>.of(logP),
    'mu': List<double>.of(mu),
    'kappa': List<double>.of(kappa),
    'alpha': List<double>.of(alpha),
    'beta': List<double>.of(beta),
  };

  static Bocpd depuisEtat(Json etat) {
    final c = jl(etat['config']);
    final b = Bocpd(
      hasard: dbl(c[0]),
      fenetre: ent(c[1]),
      minObservations: ent(c[2]),
      courseMax: ent(c[3]),
      mu0: dbl(c[4]),
      kappa0: dbl(c[5]),
      alpha0: dbl(c[6]),
      beta0: dbl(c[7]),
      alphaNouvelle: dbl(c[8]),
    );
    b.n = ent(etat['n']);
    b.pRupture = dbl(etat['p_rupture']);
    b.longueurs = [for (final r in jl(etat['longueurs'])) ent(r)];
    b.logP = jld(etat['log_p']);
    b.mu = jld(etat['mu']);
    b.kappa = jld(etat['kappa']);
    b.alpha = jld(etat['alpha']);
    b.beta = jld(etat['beta']);
    return b;
  }
}

// ----------------------------------------------------------------------
// Diagnostic : questions (3 au plus sur tout parcours)
// ----------------------------------------------------------------------
const List<(String, String)> libellesZones = [
  ('neck', 'Cou'),
  ('shoulder', 'Épaule'),
  ('elbow', 'Coude'),
  ('wrist_hand', 'Poignet, main'),
  ('upper_back', 'Haut du dos'),
  ('lower_back', 'Bas du dos'),
  ('chest', 'Poitrine'),
  ('abdomen', 'Abdomen'),
  ('hip', 'Hanche'),
  ('thigh', 'Cuisse'),
  ('knee', 'Genou'),
  ('lower_leg', 'Jambe'),
  ('ankle_foot', 'Cheville, pied'),
];

final Json questionCause = <String, Object?>{
  'code': 'cause',
  'texte': "Qu'est-ce qui a changé ces derniers temps ?",
  'choix': <Object?>[
    <String, Object?>{'code': 'douleur', 'texte': 'Une douleur'},
    <String, Object?>{'code': 'moins_de_temps', 'texte': 'Moins de temps'},
    <String, Object?>{'code': 'fatigue', 'texte': 'Fatigue ou vie chargée'},
    <String, Object?>{'code': 'rien', 'texte': 'Rien de spécial'},
  ],
};

final Json questionZone = <String, Object?>{
  'code': 'zone',
  'texte': 'Où as-tu mal ?',
  'choix': <Object?>[
    for (final (c, t) in libellesZones)
      <String, Object?>{'code': c, 'texte': t},
  ],
};

final Json questionIntensite = <String, Object?>{
  'code': 'intensite',
  'texte': 'Quelle intensité, de 0 à 10 ?',
  'choix': <Object?>[
    for (var i = 0; i < 11; i++) <String, Object?>{'code': i, 'texte': '$i'},
  ],
};

final Json questionSeances = <String, Object?>{
  'code': 'seances_par_semaine',
  'texte': 'Combien de séances par semaine peux-tu faire ?',
  'choix': <Object?>[
    for (var i = 1; i < 8; i++) <String, Object?>{'code': i, 'texte': '$i'},
  ],
};

final Json questionDuree = <String, Object?>{
  'code': 'duree_max_min',
  'texte': 'Combien de temps par séance ?',
  'choix': <Object?>[
    for (final d in const [20, 30, 45, 60, 75, 90])
      <String, Object?>{'code': d, 'texte': '$d min'},
  ],
};

// ----------------------------------------------------------------------
// Surveillance : extension du moteur
// ----------------------------------------------------------------------

/// Hors modèle (cahier § 9) : BOCPD sur les résidus normalisés moyens de
/// séance, seuils de secours, diagnostic et actions codées, dossier. Une
/// cause déclenchée reste levée tant que l'utilisateur n'a pas répondu au
/// diagnostic ; après une réponse, chaque cause levée est mise en silence
/// `silence_semaines` semaines.
class Surveillance extends Extension implements AvecParametres {
  Surveillance(Json params) {
    appliquerParametres(params);
    bocpd = Bocpd.depuisParams(params);
  }

  static const int semainesGardees = 12;
  static const int reponsesGardees = 10;

  late Json params;
  late double alerte;
  late double residuSecours;
  late int residuSemaines;
  late double assiduiteSecours;
  late int assiduiteSemaines;
  late double douleurSecours;
  late int silenceSemaines;
  late int douleurRecenteJ;
  late double residuReps;
  late int mjSuiteMax;
  late double mjPoids;

  late Bocpd bocpd;
  int semaine = 0;
  int faites = 0;
  int manquees = 0;
  double sommeRel = 0.0;
  int nRel = 0;

  /// (semaine, résidu relatif |moyen| ou null, faites, prévues).
  List<(int, double?, int, int)> semaines = [];

  /// Par cause, ordre [ruptureCauses].
  List<bool> alertes = [false, false, false, false];

  /// Semaine de fin de silence, par cause.
  List<int> silence = [-1, -1, -1, -1];
  double p = 0.0;

  /// Séances de suite tenues pour de mauvais jours.
  int mjSuite = 0;

  /// Zones au-dessus du seuil (triées).
  List<String> douleurZones = [];
  List<Json> reponses = [];

  /// Semaine allégée en cours : (jour de début, jour de fin exclu, facteur
  /// des séries, RIR ajouté) ou null.
  (int, int, double, double)? allegement;

  @override
  void appliquerParametres(Json params) {
    this.params = params;
    alerte = dbl(_ruParam(params, 'alerte'));
    residuSecours = dbl(_ruParam(params, 'residu_secours'));
    residuSemaines = ent(_ruParam(params, 'residu_secours_semaines'));
    assiduiteSecours = dbl(_ruParam(params, 'assiduite_secours'));
    assiduiteSemaines = ent(_ruParam(params, 'assiduite_secours_semaines'));
    douleurSecours = dbl(_ruParam(params, 'douleur_secours'));
    silenceSemaines = ent(_ruParam(params, 'silence_semaines'));
    douleurRecenteJ = ent(_ruParam(params, 'douleur_recente_j'));
    residuReps = dbl(_ruParam(params, 'residu_reps_reference'));
    mjSuiteMax = ent(_ruParam(params, 'mauvais_jours_suite'));
    mjPoids = dbl(_ruParam(params, 'mauvais_jour_poids'));
  }

  // ------------------------------------------------------------------
  // Événements
  // ------------------------------------------------------------------
  @override
  void finSeance(Koach koach, ResumeSeance? resume, Json e) {
    faites += 1;
    if (resume != null) {
      p = bocpd.ajouter(resume.$2);
      // len(resume) > 4 et resume[4] non None : toujours vrai pour le
      // résumé du modèle (6 éléments).
      mjSuite = resume.$5 >= mjPoids ? mjSuite + 1 : 0;
      // len(resume) > 5 : toujours vrai. Résidu d'e1RM de la séance calculé
      // par le modèle ; None vaut False (la séance ne compte pas).
      // (La branche `_residu_e1rm` de la référence, pour un résumé de moins
      // de 6 éléments, est inatteignable ici : voir [residuE1rm].)
      final r = resume.$6;
      if (r != null) {
        sommeRel += r;
        nRel += 1;
      }
    }
    verifier(koach);
  }

  /// Résidu relatif d'e1RM de la séance du jour [jour] par conversion de
  /// l'innovation de la note (`_residu_e1rm` de la référence). Renvoie null
  /// si aucune piste n'a de résidu ce jour-là, `false` si la séance n'a que
  /// des tenues ou de l'endurance, sinon un double. Utilisé par la
  /// référence seulement pour un résumé de moins de 6 éléments, ce que le
  /// modèle ne produit jamais (contrat, annexe A, M8).
  Object? residuE1rm(Koach koach, int jour) {
    final m = koach.modele;
    var vu = false;
    var sommeR = 0.0;
    var n = 0;
    for (final ex in m.ordre) {
      final t = m.pistes[ex];
      if (t == null || t.residus.isEmpty) {
        continue;
      }
      var k = t.residus.length - 1;
      while (k >= 0 && t.residus[k].$1 == jour) {
        vu = true;
        final rel = t.residus[k].$3;
        if (t.type == 'charge') {
          final (l, ku0) = m.courbe(t);
          sommeR += rel * Modele.dgK(l, ku0, residuReps);
          n += 1;
        } else if (t.type == 'reps') {
          final c = m.capacite(ex)!;
          sommeR += rel / math.exp(c.$1);
          n += 1;
        }
        k -= 1;
      }
    }
    if (!vu) {
      return null;
    }
    if (n == 0) {
      return false;
    }
    return sommeR / n;
  }

  @override
  void seanceManquee(Koach koach, Json e) {
    manquees += 1;
    verifier(koach);
  }

  @override
  void finSemaine(Koach koach, Json ligne, Json e) {
    double? residu;
    if (nRel > 0) {
      residu = (sommeRel / nRel).abs();
    }
    semaines.add((semaine, residu, faites, faites + manquees));
    if (semaines.length > semainesGardees) {
      semaines = semaines.sublist(semaines.length - semainesGardees);
    }
    semaine += 1;
    faites = 0;
    manquees = 0;
    sommeRel = 0.0;
    nRel = 0;
    verifier(koach);
  }

  /// Réponses au diagnostic (événement `decision` portant `diagnostic`).
  /// Une réponse reçue sans alerte levée est ignorée.
  @override
  void decision(Koach koach, Json e) {
    final diag = e['diagnostic'];
    if (diag != null && _horsModele()) {
      repondre(koach, jm(diag));
    }
    verifier(koach);
  }

  // ------------------------------------------------------------------
  // Causes
  // ------------------------------------------------------------------
  bool _residuActif() {
    final n = residuSemaines;
    if (n < 1 || semaines.length < n) {
      return false;
    }
    for (var i = semaines.length - n; i < semaines.length; i++) {
      final r = semaines[i].$2;
      if (r == null || !(r > residuSecours)) {
        return false;
      }
    }
    return true;
  }

  bool _assiduiteActive() {
    final n = assiduiteSemaines;
    if (n < 1 || semaines.length < n) {
      return false;
    }
    var f = 0;
    var prevues = 0;
    for (var i = semaines.length - n; i < semaines.length; i++) {
      f += semaines[i].$3;
      prevues += semaines[i].$4;
    }
    if (prevues <= 0) {
      return false;
    }
    return f < assiduiteSecours * prevues;
  }

  /// Zones dont le DERNIER signalement dépasse le seuil et date de
  /// `douleur_recente_j` jours au plus (triées).
  List<String> _douleur(Koach koach) {
    final zones = <String>[];
    final jour = koach.jour;
    final cles = koach.garde.zones.keys.toList()..sort();
    for (final z in cles) {
      final Object? dern = koach.garde.zones[z]!.derniere();
      num? dJour;
      num? dIntensite;
      if (dern case (num a, num b)) {
        dJour = a;
        dIntensite = b;
      } else if (dern case [num a, num b]) {
        dJour = a;
        dIntensite = b;
      }
      if (dJour != null &&
          dIntensite != null &&
          dIntensite > douleurSecours &&
          jour - dJour <= douleurRecenteJ) {
        zones.add(z);
      }
    }
    return zones;
  }

  /// Recalcule les causes et lève celles qui ne sont pas en silence. Quand
  /// une alerte se lève, les extensions [AvecAlerteHorsModele] sont
  /// prévenues.
  void verifier(Koach koach) {
    final avant = _horsModele();
    douleurZones = _douleur(koach);
    final repetes = mjSuiteMax >= 1 && mjSuite >= mjSuiteMax;
    final actives = [
      p > alerte || repetes,
      _residuActif(),
      _assiduiteActive(),
      douleurZones.isNotEmpty,
    ];
    for (var c = 0; c < 4; c++) {
      if (actives[c] && semaine >= silence[c]) {
        alertes[c] = true;
      }
    }
    if (!avant && _horsModele()) {
      final cs = causes();
      for (final x in koach.extensions) {
        if (x is AvecAlerteHorsModele && !identical(x, this)) {
          // Pas de promotion (interface sans lien avec Extension) : cast.
          (x as AvecAlerteHorsModele).surAlerteHorsModele(koach, cs);
        }
      }
    }
  }

  /// Items écrits du jour transformés par la semaine allégée en cours.
  /// Renvoie une nouvelle liste ; les items reçus ne sont pas modifiés.
  List<Json> appliquerAllegement(List<Json> items, int jour) {
    final a = allegement;
    if (a == null || !(a.$1 <= jour && jour < a.$2)) {
      return items;
    }
    final fSeries = a.$3;
    final rir = a.$4;
    final cran = (2.0 * rir + 0.5).floor();
    final out = <Json>[];
    for (final it0 in items) {
      if (_ruGet(it0, 'kind', 'work') != 'work' ||
          (ou(it0['sets'], 0) as num) < 1) {
        out.add(it0);
        continue;
      }
      final it = Map<String, Object?>.of(it0);
      final n = (dbl(it['sets']) * fSeries + 0.5).floor();
      it['sets'] = n >= 1 ? n : 1;
      final f = it['targetFlames'];
      if (f != null) {
        final fn = f as num;
        if (fn < 10) {
          final g = fn - cran;
          it['targetFlames'] = g >= 1 ? g : 1;
        }
      }
      if (vrai(it['setTargets'])) {
        final cibles = <Object?>[];
        for (final c0 in jl(it['setTargets'])) {
          final c = Map<String, Object?>.of(jm(c0));
          final fc = c['flames'];
          if (fc != null) {
            final fcn = fc as num;
            if (fcn < 10) {
              final g = fcn - cran;
              c['flames'] = g >= 1 ? g : 1;
            }
          }
          cibles.add(c);
        }
        it['setTargets'] = cibles;
      }
      out.add(it);
    }
    return out;
  }

  List<String> causes() => [
    for (var c = 0; c < 4; c++)
      if (alertes[c]) ruptureCauses[c],
  ];

  bool _horsModele() => causes().isNotEmpty;

  Json etat() {
    final cs = causes();
    return <String, Object?>{
      'hors_modele': cs.isNotEmpty,
      'p_rupture': p,
      'causes': cs,
      'semaine': semaine,
    };
  }

  // ------------------------------------------------------------------
  // Diagnostic
  // ------------------------------------------------------------------

  /// Questions du diagnostic pour le parcours en cours (3 au plus) ; rien
  /// si aucune alerte n'est levée.
  List<Json> questions([Json? reponses]) {
    if (!_horsModele()) {
      return <Json>[];
    }
    final qs = <Json>[copieJson(questionCause)];
    final cause = dictOuVide(reponses)['cause'];
    if (cause == 'douleur') {
      qs.add(copieJson(questionZone));
      qs.add(copieJson(questionIntensite));
    } else if (cause == 'moins_de_temps') {
      qs.add(copieJson(questionSeances));
      qs.add(copieJson(questionDuree));
    }
    return qs.length > 3 ? qs.sublist(0, 3) : qs;
  }

  /// Applique la réponse au diagnostic et renvoie l'action codée.
  Json repondre(Koach koach, Json reponses) {
    final cause = reponses['cause'];
    if (!ruptureReponses.contains(cause)) {
      throw ArgumentError('réponse inconnue : ${_ruRepr(cause)}');
    }
    final pr = params;
    Json action;
    if (cause == 'douleur') {
      final zone = reponses['zone'];
      final intensite = reponses['intensite'];
      if (zone != null && intensite != null) {
        // Le signalement suit le chemin habituel des douleurs.
        koach.garde.noterSeance(koach.jour, <Object?>[
          <String, Object?>{'zone': zone, 'intensity': ent(intensite)},
        ], posee: false);
      }
      action = <String, Object?>{
        'action': 'conduite_douleur',
        'renvoi_professionnel': true,
        'zone': zone,
        'intensite': intensite,
      };
    } else if (cause == 'moins_de_temps') {
      action = <String, Object?>{
        'action': 'replanifier',
        'disponibilites': <String, Object?>{
          'seances_par_semaine': reponses['seances_par_semaine'],
          'duree_max_min': reponses['duree_max_min'],
        },
      };
    } else if (cause == 'fatigue') {
      final series = dbl(_ruParam(pr, 'semaine_allegee_series'));
      final rir = dbl(_ruParam(pr, 'semaine_allegee_rir'));
      action = <String, Object?>{
        'action': 'semaine_allegee',
        'series': series,
        'rir': rir,
      };
      final j = koach.jour;
      allegement = (j, j + 7, series, rir);
    } else {
      final facteur = dbl(_ruParam(pr, 'elargissement_rien_de_special'));
      koach.modele.elargir(facteur);
      bocpd.reinitialiser();
      p = 0.0;
      action = <String, Object?>{'action': 'elargir', 'facteur': facteur};
    }
    mjSuite = 0;
    // Acquittement : chaque cause levée se tait `silence_semaines` semaines.
    for (var c = 0; c < 4; c++) {
      if (alertes[c]) {
        silence[c] = semaine + silenceSemaines;
      }
      alertes[c] = false;
    }
    this.reponses.add(<String, Object?>{
      'semaine': semaine,
      'jour': koach.jour,
      'cause': cause,
      'action': action['action'],
    });
    if (this.reponses.length > reponsesGardees) {
      this.reponses = this.reponses.sublist(
        this.reponses.length - reponsesGardees,
      );
    }
    return action;
  }

  // ------------------------------------------------------------------
  // Sérialisation
  // ------------------------------------------------------------------
  Json etatComplet() {
    final al = allegement;
    return <String, Object?>{
      'bocpd': bocpd.etat(),
      'semaine': semaine,
      'faites': faites,
      'manquees': manquees,
      'somme_rel': sommeRel,
      'n_rel': nRel,
      'semaines': <Object?>[
        for (final s in semaines) <Object?>[s.$1, s.$2, s.$3, s.$4],
      ],
      'alertes': List<bool>.of(alertes),
      'silence': List<int>.of(silence),
      'p': p,
      'mj_suite': mjSuite,
      'douleur_zones': List<String>.of(douleurZones),
      'reponses': <Object?>[for (final r in reponses) copieJson(r)],
      'allegement': al == null ? null : <Object?>[al.$1, al.$2, al.$3, al.$4],
    };
  }

  static Surveillance depuisEtat(Json params, Json etat) {
    final s = Surveillance(params);
    s.bocpd = Bocpd.depuisEtat(jm(etat['bocpd']));
    s.semaine = ent(etat['semaine']);
    s.faites = ent(etat['faites']);
    s.manquees = ent(etat['manquees']);
    s.sommeRel = dbl(etat['somme_rel']);
    s.nRel = ent(etat['n_rel']);
    s.semaines = [
      for (final x0 in jl(etat['semaines']))
        (ent(jl(x0)[0]), dblOu(jl(x0)[1]), ent(jl(x0)[2]), ent(jl(x0)[3])),
    ];
    s.alertes = [for (final a in jl(etat['alertes'])) vrai(a)];
    s.silence = [for (final v in jl(etat['silence'])) ent(v)];
    s.p = dbl(etat['p']);
    s.mjSuite = ent(_ruGet(etat, 'mj_suite', 0));
    s.douleurZones = [for (final z in jl(etat['douleur_zones'])) z as String];
    s.reponses = [for (final r in jl(etat['reponses'])) jm(copieProfonde(r))];
    final a = etat['allegement'];
    if (a == null) {
      s.allegement = null;
    } else {
      final al = jl(a);
      s.allegement = (ent(al[0]), ent(al[1]), dbl(al[2]), dbl(al[3]));
    }
    return s;
  }

  // ------------------------------------------------------------------
  // Dossier hors modèle (mode dev)
  // ------------------------------------------------------------------

  /// Dossier exportable, JSON-sérialisable, sans donnée identifiante.
  Json dossier(Koach koach) {
    final n = ent(_ruParam(params, 'journal_dossier'));
    final debut = koach.journal.length - n;
    final journal = koach.journal.length > n
        ? (debut > koach.journal.length
              ? <Json>[]
              : koach.journal.sublist(debut))
        : koach.journal;
    final evenements = <Object?>[];
    for (final e in journal) {
      if (typesExclus.contains(e['type'])) {
        continue;
      }
      evenements.add(_ruAnonymiser(e));
    }
    return jm(
      _ruJsonPropre(<String, Object?>{
        'type': 'dossier_hors_modele',
        'version_dossier': versionDossier,
        'version_parametres': koach.params['version'],
        'parametres': koach.params,
        'posterior': koach.posterior(),
        'histoire_residus': <Object?>[
          for (final r in koach.modele.histoireResidus)
            <Object?>[r.$1, r.$2, r.$3, r.$4, r.$5, r.$6],
        ],
        'bocpd': bocpd.etat(),
        'surveillance': etatComplet(),
        'causes': causes(),
        'journal': evenements,
      }),
    );
  }
}

// ----------------------------------------------------------------------
// Import de paramètres
// ----------------------------------------------------------------------

/// Valide puis applique un fichier de paramètres. [fichierJson] : texte
/// JSON ou dictionnaire. Renvoie {'ok', 'erreurs', 'version'} ; rien n'est
/// appliqué si une erreur est trouvée.
Json importerParametres(Koach koach, Object? fichierJson) {
  final erreurs = <String>[];
  Object? nouveau;
  if (fichierJson is String) {
    try {
      nouveau = jsonDecode(fichierJson);
    } on FormatException catch (exc) {
      // Le texte du message diffère de celui de `json.loads` (Python).
      return <String, Object?>{
        'ok': false,
        'erreurs': <Object?>['json_invalide: ${exc.message}'],
        'version': null,
      };
    }
  } else {
    nouveau = copieProfonde(fichierJson);
  }
  if (nouveau is! Map<String, Object?>) {
    return <String, Object?>{
      'ok': false,
      'erreurs': <Object?>['racine_non_objet'],
      'version': null,
    };
  }
  final actuel = koach.params;
  erreurs.addAll(validerParametres(actuel, nouveau));
  if (erreurs.isNotEmpty) {
    return <String, Object?>{
      'ok': false,
      'erreurs': erreurs,
      'version': nouveau['version'],
    };
  }
  // L'import est un événement du journal : `rejouer` le réapplique.
  koach.observe(<String, Object?>{'type': 'parametres', 'fichier': nouveau});
  return <String, Object?>{
    'ok': true,
    'erreurs': <Object?>[],
    'version': koach.params['version'],
  };
}

/// Applique un fichier de paramètres déjà validé (événement `parametres`
/// du journal).
void appliquerParametres(Koach koach, Json nouveau) {
  final actuel = koach.params;
  final fusion = copieJson(actuel);
  final cles = nouveau.keys.toList()..sort();
  for (final cle in cles) {
    final v = nouveau[cle];
    if (v is Map<String, Object?>) {
      final ks = v.keys.toList()..sort();
      final sec = jm(fusion[cle]);
      for (final k in ks) {
        sec[k] = copieProfonde(v[k]);
      }
    } else {
      fusion[cle] = copieProfonde(v);
    }
  }
  // Les modules lisent leurs paramètres dans ce dictionnaire.
  koach.params = fusion;
  koach.modele.p = fusion;
  koach.garde.s = jm(fusion['securite']);
  koach.seances.p = fusion;
  koach.seances.s = jm(fusion['securite']);
  final f = jm(fusion['fatigue']);
  koach.modele.tau = [
    dbl(f['tau_nerveux_j']),
    dbl(f['tau_musculaire_j']),
    dbl(f['tau_tendineux_j']),
  ];
  for (final x in koach.extensions) {
    if (x is AvecParametres) {
      (x as AvecParametres).appliquerParametres(fusion);
    }
    // Branche `cle_params` de la référence : aucune extension ne porte cet
    // attribut (contrat § 7.3), elle n'est pas portée.
  }
}

/// Garde-fous qu'un import ne peut pas changer (`FIGEES`), en plus de toute
/// la section `securite`.
const List<(String, String)> figees = [
  ('planification', 'plafond_volume'),
  ('planification', 'plafond_intensite'),
  ('controle_dual', 'amplitude_volume'),
  ('controle_dual', 'amplitude_intensite'),
  ('controle_dual', 'plafond_volume'),
  ('controle_dual', 'plafond_intensite'),
  ('controle_dual', 'semaines_min'),
  ('controle_dual', 'intervalle_max'),
  ('controle_dual', 'synthetique_semaines_min'),
  ('controle_dual', 'bras_semaines'),
  ('test_adaptatif', 'intervalle_declenchement'),
  ('test_adaptatif', 'jours_min_entre_tests'),
  ('test_adaptatif', 'jours_min_entre_rampes'),
  ('test_adaptatif', 'rampe_pas_cran'),
  ('test_adaptatif', 'rampe_cran_rir_marge'),
  ('rupture', 'douleur_secours'),
];

/// Bornes simples (`BORNES`) : (section, clé) -> (min, max) inclus. Les
/// entiers restent des entiers (texte des messages d'erreur).
final Map<(String, String), (num, num)> bornes = {
  ('jour', 'mauvais_jour_proba'): (1e-6, 0.999),
  ('jour', 'mauvais_jour_proba_bilan_bas'): (1e-6, 0.999),
  ('mesure', 'note_aberrante'): (1e-6, 0.5),
  ('mesure', 'porte_note_ouverte'): (0.0, 3.0),
  ('dynamique', 'recuperation_seuil'): (1e-6, 1e6),
  ('rupture', 'hasard'): (1e-6, 0.5),
  ('rupture', 'alerte'): (0.05, 0.999),
  ('rupture', 'residu_secours'): (0.0, 1.0),
  ('rupture', 'assiduite_secours'): (0.0, 1.0),
  ('rupture', 'douleur_secours'): (0.0, 10.0),
  ('rupture', 'elargissement_rien_de_special'): (1.0, 100.0),
  ('rupture', 'semaine_allegee_series'): (0.1, 1.0),
  ('rupture', 'semaine_allegee_rir'): (0.0, 5.0),
  ('rupture', 'course_max'): (10, 1000),
  ('rupture', 'fenetre_seances'): (1, 100),
  ('rupture', 'min_observations'): (1, 100),
  ('rupture', 'a_priori_alpha'): (0.5, 1000.0),
  ('rupture', 'a_priori_beta'): (1e-6, 1000.0),
  ('rupture', 'a_priori_alpha_nouvelle'): (0.5, 1000.0),
  ('rupture', 'douleur_recente_j'): (0, 60),
  ('rupture', 'residu_reps_reference'): (1.0, 30.0),
  ('adherence', 'proba_cible'): (0.05, 0.99),
  ('adherence', 'a_priori_poids_sd'): (1e-3, 100.0),
  ('adherence', 'biais_initial'): (-5.0, 5.0),
  ('adherence', 'pas_min'): (1e-6, 1e6),
  ('adherence', 'paliers_max'): (1, 20),
};

/// Nombre Python (int ou float, pas bool).
bool _ruNombre(Object? v) => v is num;

/// Valeur numérique Python d'un scalaire comparé (bool -> 0/1 ; sinon
/// échec comme la comparaison Python).
num _ruNum(Object? v) => v is bool ? (v ? 1 : 0) : v as num;

void _ruVerifierValeur(
  String chemin,
  Object? ancien,
  Object? v,
  List<String> erreurs,
) {
  if (_ruNombre(ancien)) {
    if (!_ruNombre(v)) {
      erreurs.add('type: $chemin');
    } else if (v is double && (v.isNaN || v.isInfinite)) {
      erreurs.add('non_fini: $chemin');
    }
  } else if (ancien is bool) {
    if (v is! bool) {
      erreurs.add('type: $chemin');
    }
  } else if (ancien is String) {
    if (v is! String) {
      erreurs.add('type: $chemin');
    }
  } else if (ancien is List<Object?>) {
    if (v is! List<Object?> || v.length != ancien.length) {
      erreurs.add('liste: $chemin');
    } else {
      for (var i = 0; i < v.length; i++) {
        _ruVerifierValeur('$chemin[$i]', ancien[i], v[i], erreurs);
      }
    }
  } else if (ancien is Map<String, Object?>) {
    if (v is! Map<String, Object?>) {
      erreurs.add('type: $chemin');
    } else {
      final ks = v.keys.toList()..sort();
      for (final k in ks) {
        if (!ancien.containsKey(k)) {
          erreurs.add('cle_inconnue: $chemin.$k');
        } else {
          _ruVerifierValeur('$chemin.$k', ancien[k], v[k], erreurs);
        }
      }
    }
  }
}

/// Schéma, version, types, bornes simples ; la section `securite` ne peut
/// pas changer.
List<String> validerParametres(Json actuel, Json nouveau) {
  final erreurs = <String>[];
  if (!egalJson(nouveau['schema'], actuel['schema'])) {
    erreurs.add('schema: attendu ${_ruRepr(actuel['schema'])}');
  }
  final version = nouveau['version'];
  final va = _ruStr(_ruGet(actuel, 'version', ''));
  if (version is! String || version.split('.')[0] != va.split('.')[0]) {
    erreurs.add('version: majeure attendue ${_ruRepr(va.split('.')[0])}');
  }
  final defauts = <String, Json>{
    'rupture': defautsRupture,
    'adherence': defautsAdherence,
  };
  final cles = nouveau.keys.toList()..sort();
  for (final cle in cles) {
    final v = nouveau[cle];
    if (const ['schema', 'version', 'date', 'note'].contains(cle)) {
      if ((cle == 'date' || cle == 'note') && v is! String) {
        erreurs.add('type: $cle');
      }
      continue;
    }
    if (!actuel.containsKey(cle)) {
      erreurs.add('section_inconnue: $cle');
      continue;
    }
    if (cle == 'securite') {
      if (!egalJson(v, actuel['securite'])) {
        erreurs.add('securite: modification interdite');
      }
      continue;
    }
    final ancien = actuel[cle];
    if (ancien is Map<String, Object?> &&
        v is Map<String, Object?> &&
        defauts.containsKey(cle)) {
      // Les clés nouvelles connues des modules sont admises.
      final ks = v.keys.toList()..sort();
      for (final k in ks) {
        final ref = ancien.containsKey(k) ? ancien[k] : defauts[cle]![k];
        if (ref == null && !ancien.containsKey(k)) {
          erreurs.add('cle_inconnue: $cle.$k');
        } else {
          _ruVerifierValeur('$cle.$k', ref, v[k], erreurs);
        }
      }
    } else {
      _ruVerifierValeur(cle, ancien, v, erreurs);
    }
  }
  for (final (sec, k) in figees) {
    final sv = nouveau[sec];
    final asec = actuel[sec];
    if (sv is Map<String, Object?> &&
        sv.containsKey(k) &&
        asec is Map<String, Object?> &&
        asec.containsKey(k) &&
        !egalJson(sv[k], asec[k])) {
      erreurs.add('fige: $sec.$k (garde-fou, modification interdite)');
    }
  }
  if (erreurs.isEmpty) {
    final cb = bornes.keys.toList()
      ..sort((x, y) {
        final c = x.$1.compareTo(y.$1);
        return c != 0 ? c : x.$2.compareTo(y.$2);
      });
    for (final cleB in cb) {
      final (sec, k) = cleB;
      final sv = nouveau[sec];
      if (sv is Map<String, Object?> && sv.containsKey(k)) {
        final (lo, hi) = bornes[cleB]!;
        final x = _ruNum(sv[k]);
        if (!(lo <= x && x <= hi)) {
          erreurs.add('borne: $sec.$k hors de [${_ruStr(lo)}, ${_ruStr(hi)}]');
        }
      }
    }
    final secs = nouveau.keys.toList()..sort();
    for (final sec in secs) {
      final sv = nouveau[sec];
      if (sv is! Map<String, Object?>) {
        continue;
      }
      final ks = sv.keys.toList()..sort();
      for (final k in ks) {
        final x = sv[k];
        if (x is num &&
            (k.endsWith('_sd') ||
                k.startsWith('sigma') ||
                k.startsWith('tau') ||
                k.startsWith('bruit')) &&
            !(x > 0)) {
          erreurs.add('borne: $sec.$k doit être > 0');
        }
      }
    }
  }
  return erreurs;
}

// ----------------------------------------------------------------------
// Anonymisation et nettoyage JSON
// ----------------------------------------------------------------------
const List<String> typesExclus = ['profil'];
const List<String> clesInterdites = [
  'nom', 'name', 'prenom', 'firstName', 'lastName', 'email', 'mail', //
  'telephone', 'phone', 'adresse', 'address', 'note', 'notes', 'commentaire',
  'comment', 'texte', 'text', 'userId', 'user_id', 'user', 'utilisateur', 'uid',
  'deviceId',
  'appareil',
  'device',
  'date',
  'dateIso',
  'timestamp',
  'horodatage',
  'naissance', 'birthDate', 'age', 'sexe', 'sex', 'profil', 'profile', 'photo',
  'localisation', 'location', 'gps', 'id_utilisateur', 'createdAt', 'updatedAt',
];
const String caracteresCode =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-';

bool _ruChiffres(String t) {
  if (t.isEmpty) return false;
  for (var i = 0; i < t.length; i++) {
    final c = t.codeUnitAt(i);
    if (c < 0x30 || c > 0x39) return false;
  }
  return true;
}

/// Chaîne courte faite de caractères de code (pas de texte libre, pas de
/// date ISO).
bool _ruEstCode(String s) {
  if (s.isEmpty || s.length > 64) {
    return false;
  }
  for (var i = 0; i < s.length; i++) {
    if (!caracteresCode.contains(s[i])) {
      return false;
    }
  }
  if (s.length >= 10 &&
      _ruChiffres(s.substring(0, 4)) &&
      s[4] == '-' &&
      _ruChiffres(s.substring(5, 7)) &&
      s[7] == '-') {
    return false;
  }
  return true;
}

class _RuRetire {
  const _RuRetire();
}

const _RuRetire _ruRetire = _RuRetire();

Object? _ruAnonymiser(Object? v) {
  if (v is Map<Object?, Object?>) {
    final out = <String, Object?>{};
    final cles = <String>[
      for (final k in v.keys)
        if (k is String) k,
    ]..sort();
    for (final k in cles) {
      if (clesInterdites.contains(k)) {
        continue;
      }
      final x = _ruAnonymiser(v[k]);
      if (!identical(x, _ruRetire)) {
        out[k] = x;
      }
    }
    return out;
  }
  if (v is List<Object?>) {
    final out = <Object?>[];
    for (final x in v) {
      final y = _ruAnonymiser(x);
      if (!identical(y, _ruRetire)) {
        out.add(y);
      }
    }
    return out;
  }
  if (v is String) {
    return _ruEstCode(v) ? v : _ruRetire;
  }
  return v;
}

/// Types JSON purs : flottants non finis -> null, clés -> chaînes.
Object? _ruJsonPropre(Object? v) {
  if (v == null || v is bool || v is String) {
    return v;
  }
  if (v is int) {
    return v;
  }
  if (v is double) {
    return (v == v && v != inf && v != -inf) ? v : null;
  }
  if (v is Map<Object?, Object?>) {
    final out = <String, Object?>{};
    for (final k in v.keys) {
      out[_ruStr(k)] = _ruJsonPropre(v[k]);
    }
    return out;
  }
  if (v is List<Object?>) {
    return <Object?>[for (final x in v) _ruJsonPropre(x)];
  }
  return v.toString();
}

// ----------------------------------------------------------------------
// Calibrage du seuil d'alerte (banc)
// ----------------------------------------------------------------------
num? _ruMediane(List<num> xs) {
  final ys = List<num>.of(xs)..sort();
  final n = ys.length;
  if (n == 0) {
    return null;
  }
  num m;
  if (n % 2 == 1) {
    m = ys[n ~/ 2];
  } else {
    m = 0.5 * (ys[n ~/ 2 - 1] + ys[n ~/ 2]);
  }
  return m == inf ? null : m;
}

/// Pour chaque seuil : fausses alertes par 100 séances sur les séries
/// stables et délai médian de détection sur les séries avec rupture.
/// [seriesAvecRupture] : liste de [valeurs, indice] ou de {'valeurs',
/// 'rupture'}. [bocpd] : fabrique (défaut : `Bocpd.depuisParams(params)`
/// ou `Bocpd()`).
List<Json> calibrerAlerte(
  List<List<num>> seriesStables,
  List<Object?> seriesAvecRupture,
  List<num> seuils, {
  Json? params,
  Bocpd Function()? bocpd,
}) {
  Bocpd Function() fabrique;
  if (bocpd != null) {
    fabrique = bocpd;
  } else if (params != null) {
    fabrique = () => Bocpd.depuisParams(params);
  } else {
    fabrique = Bocpd.new;
  }
  final tracesStables = <List<double>>[];
  for (final s in seriesStables) {
    final b = fabrique();
    tracesStables.add([for (final x in s) b.ajouter(x)]);
  }
  final tracesRupture = <(List<double>, int)>[];
  for (final item in seriesAvecRupture) {
    List<Object?> valeurs;
    int k;
    if (item is Map<String, Object?>) {
      valeurs = jl(item['valeurs']);
      k = ent(item['rupture']);
    } else {
      final l = jl(item);
      valeurs = jl(l[0]);
      k = ent(l[1]);
    }
    final b = fabrique();
    tracesRupture.add(([for (final x in valeurs) b.ajouter(x as num)], k));
  }
  var total = 0;
  for (final tr in tracesStables) {
    total += tr.length;
  }
  final sortie = <Json>[];
  for (final seuil in seuils) {
    var alertes = 0;
    for (final tr in tracesStables) {
      var avant = false;
      for (final p in tr) {
        final haut = p > seuil;
        if (haut && !avant) {
          alertes += 1;
        }
        avant = haut;
      }
    }
    final delais = <num>[];
    var detectees = 0;
    for (final (tr, k) in tracesRupture) {
      num d = inf;
      for (var t = k; t < tr.length; t++) {
        if (tr[t] > seuil) {
          d = t - k + 1;
          break;
        }
      }
      if (d != inf) {
        detectees += 1;
      }
      delais.add(d);
    }
    sortie.add(<String, Object?>{
      'seuil': seuil,
      'fausses_alertes_100': total > 0 ? 100.0 * alertes / total : null,
      'delai_median': _ruMediane(delais),
      'taux_detection': tracesRupture.isNotEmpty
          ? detectees / tracesRupture.length
          : null,
    });
  }
  return sortie;
}
