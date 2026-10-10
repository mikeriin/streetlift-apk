part of 'koach.dart';

// Estimation de Koach (référence `koach/modele.py`, contrat § 4 et 5) :
// état gaussien x ~ N(m, P), deux branches par séance (jour normal,
// mauvais jour), appariement des moments de rang 1. Les vecteurs et la
// matrice sont alloués à une capacité qui double au besoin, comme les
// tableaux numpy de la référence : chaque opération parcourt la capacité
// entière (les composantes inactives valent 0).

const int nq = 10;
const int ngr = 17;
const int th = 0;
const int rho = 10;
const int eps = 11;
const int kn = 16;
const int km = 17;
const int ba = 18;
const int bp = 19;
const int lam = 20;
const int ku = 21;
const int fi = 22;
const int hh = 23;
const int ds = 24;
const int de = 25;
const int kl = 26;
const int kg = 27;
const int ng = 28;
const double cLin = 0.0265;
const double cLog = 0.0892;
const double g8 = cLin * 7.0;
final double ln8 = math.log(8.0);
const double lamMin = -0.8;
const double lamMax = 1.3;

/// `x ** y` de Python sur des flottants (pow de la bibliothèque C).
double pw(double x, double y) => math.pow(x, y).toDouble();

/// (e^x − 1)/x, série près de 0.
double phiK(double x) {
  if (-1e-2 < x && x < 1e-2) {
    return 1.0 +
        x *
            (0.5 +
                x *
                    (1.0 / 6.0 +
                        x *
                            (1.0 / 24.0 +
                                x *
                                    (1.0 / 120.0 +
                                        x * (1.0 / 720.0 + x / 5040.0)))));
  }
  return (math.exp(x) - 1.0) / x;
}

/// Dérivée de [phiK].
double phi1K(double x) {
  if (-1e-2 < x && x < 1e-2) {
    return 0.5 +
        x *
            (1.0 / 3.0 +
                x *
                    (0.125 +
                        x *
                            (1.0 / 30.0 +
                                x *
                                    (1.0 / 144.0 +
                                        x * (1.0 / 840.0 + x / 5760.0)))));
  }
  return (math.exp(x) * (x - 1.0) + 1.0) / (x * x);
}

const List<String> classesK = ['charge', 'reps', 'tenue', 'cardio', 'wod'];
const List<String> zonesTendon = [
  'epaule',
  'coude',
  'poignet',
  'lombaires',
  'genou',
  'hanche',
  'cheville',
];

/// Résidu d'une observation : (résidu normalisé, résidu relatif,
/// informatif).
typedef Residu = (double, double, bool);

/// Résumé d'une séance : (jour, résidu normalisé moyen, résidu relatif
/// moyen, nombre, poids du mauvais jour, résidu d'e1RM ou null).
typedef ResumeSeance = (int, double, double, int, double, double?);

/// Suivi d'un exercice (hors de l'état gaussien).
class Piste {
  Piste(
    this.id,
    this.type,
    this.vecteur,
    this.base,
    this.idx, {
    this.fraction = 0.0,
    this.bas = false,
    this.tendon = 0.0,
    this.zoneTendon,
    this.systemique = 1.0,
    this.locale = 1.0,
    this.declare = false,
    List<(int, double)>? groupes,
  }) : classe = classesK.contains(type) ? classesK.indexOf(type) : null,
       groupes = groupes ?? <(int, double)>[] {
    var tot = 0.0;
    for (final g in this.groupes) {
      tot += g.$2;
    }
    groupesTotal = tot;
  }

  final String id;
  final String type;
  final int? classe;
  final List<double> vecteur;
  final double base;
  final int idx;
  final double fraction;
  final bool bas;
  final double tendon;
  final String? zoneTendon;
  final double systemique;
  final double locale;
  int seances = 0;
  int? dernierJour;
  int? premierJour;
  List<double> stimSemaine = [0.0, 0.0, 0.0];
  List<(double, double)> seriesSeance = [];
  int? jourSeance;
  bool declare;
  int? dernierTestJour;
  int? dernierVraiTestJour;
  int? derniereRampeJour;
  int? dernierEchecJour;
  final List<(int, double, double)> residus = [];
  (double, int)? meilleur;
  int mesures = 0;
  final List<(int, double)> groupes;
  late final double groupesTotal;
  double? jourPrevu;
  double? jourVu;
}

/// Branche de l'état : moyenne et covariance à la capacité [cap].
class _Branche {
  _Branche(this.m, this.p, this.cap);

  Float64List m;
  Float64List p;
  int cap;
}

/// Filtre de Koach : état, compartiments de fatigue, pistes.
class Modele {
  Modele(this.p, this.vecteurs, this.profil)
    : niveau = clampD(dbl(profil['niveau'] ?? 1), 0, 3).truncate() {
    final ap = jm(p['a_priori']);
    const n0 = ng + 3 * 48;
    cap = n0;
    m = Float64List(n0);
    pm = Float64List(n0 * n0);
    n = ng;
    for (var q = 0; q < nq; q++) {
      _set(th + q, th + q, pw(dbl(ap['theta_sd']), 2));
    }
    final rhoN = jld(ap['rho_moyenne_par_niveau']);
    final r = rhoN[niveau];
    m[rho] = r;
    _set(rho, rho, pw(r * dbl(ap['rho_sd_rel']), 2));
    final epsM = jld(ap['eps_classe_moyenne']);
    for (var c = 0; c < 5; c++) {
      m[eps + c] = epsM[c] * r / rhoN[1];
      _set(eps + c, eps + c, pw(dbl(ap['eps_classe_sd']) * r / rhoN[1], 2));
    }
    for (final (i, cle) in const [
      (kn, 'k_nerveux'),
      (km, 'k_musculaire'),
      (kl, 'k_nerveux_local'),
      (kg, 'k_musculaire_systemique'),
      (ba, 'biais_rir_additif'),
      (bp, 'biais_rir_proportionnel'),
      (lam, 'courbe_forme'),
      (ku, 'courbe_echelle'),
      (fi, 'fatigue_intra'),
      (hh, 'part_tenue'),
    ]) {
      final v = jld(ap[cle]);
      m[i] = v[0];
      _set(i, i, pw(v[1], 2));
    }
    poidsKg = vrai(profil['poids_kg']) ? dbl(profil['poids_kg']) : 72.0;
    final f = jm(p['fatigue']);
    tau = [
      dbl(f['tau_nerveux_j']),
      dbl(f['tau_musculaire_j']),
      dbl(f['tau_tendineux_j']),
    ];
    for (final z in zonesTendon) {
      fTendon[z] = 0.0;
      fTendonAigu[z] = 0.0;
    }
    paresse = jld(jm(p['mesure'])['note_paresseuse_a_priori']);
    final dyn = jm(p['dynamique']);
    final stims = jl(dyn['hypotheses_stimulus']);
    final s0s = jld(dyn['hypotheses_s0']);
    for (var k = 0; k < stims.length; k++) {
      for (final s in s0s) {
        hypotheses.add((s, k));
      }
    }
    poidsHyp = List<double>.filled(hypotheses.length, 1.0 / hypotheses.length);
  }

  Json p;
  final Map<String, Json> vecteurs;
  final Json profil;
  final int niveau;
  late int cap;
  late Float64List m;
  late Float64List pm;
  late int n;
  final Map<String, Piste?> pistes = {};
  final List<String> ordre = [];
  int jour = 0;
  late double poidsKg;
  late List<double> tau;
  final List<double> fG = [0.0, 0.0];
  final List<Float64List> fL = [Float64List(ngr), Float64List(ngr)];
  final Map<String, double> fTendon = {};
  final Map<String, double> fTendonAigu = {};
  double bruitRir = 1.0;
  double z2 = 1.0;
  double z2N = 0.0;
  late List<double> paresse;
  int notesDemi = 0;
  int notesEntieres = 0;
  // Branche « mauvais jour » : moyenne, covariance, log-poids.
  _Branche? _alt;
  double altLw = 0.0;
  double logw = 0.0;
  bool enSeance = false;
  Json? bilan;
  List<(double, double, bool)> residusSeance = [];
  final List<ResumeSeance> histoireResidus = [];
  final List<(double, int)> hypotheses = [];
  late List<double> poidsHyp;
  String? _dernierEx;
  int semaines = 0;
  final List<Json> journalSemaines = [];
  int elargi = 0;

  /// La branche « mauvais jour » est ouverte.
  bool get altOuverte => _alt != null;

  /// Moyenne de la branche « mauvais jour » (lecture).
  Float64List? get altM => _alt?.m;

  /// Covariance de la branche « mauvais jour » (lecture).
  Float64List? get altP => _alt?.p;

  double pget(int i, int j) => pm[i * cap + j];
  void _set(int i, int j, double v) => pm[i * cap + j] = v;

  // ------------------------------------------------------------------
  // Pistes et a priori
  // ------------------------------------------------------------------
  void _agrandir() {
    if (n + 3 <= cap) {
      return;
    }
    final n2 = cap * 2;
    _Branche grandir(Float64List m0, Float64List p0) {
      final m1 = Float64List(n2);
      final p1 = Float64List(n2 * n2);
      for (var i = 0; i < n; i++) {
        m1[i] = m0[i];
        for (var j = 0; j < n; j++) {
          p1[i * n2 + j] = p0[i * cap + j];
        }
      }
      return _Branche(m1, p1, n2);
    }

    final principal = grandir(m, pm);
    if (_alt != null) {
      final a = grandir(_alt!.m, _alt!.p);
      _alt = a;
    }
    m = principal.m;
    pm = principal.p;
    cap = n2;
  }

  double baseDe(Json fiche) {
    final ap = jm(p['a_priori']);
    final typ = fiche['type'] as String;
    if (typ == 'charge') {
      var total =
          dbl(fiche['ratio']) *
          poidsKg *
          jld(ap['niveau_echelle_charge'])[niveau];
      if (profil['sexe'] == 'female') {
        total *= dbl(ap['facteur_femme']);
      }
      final plancherC = dbl(fiche['fraction'] ?? 0.0) * poidsKg * 1.1;
      return math.log(math.max(math.max(total, plancherC), 1.0));
    }
    if (typ == 'reps' || typ == 'tenue') {
      final mn = jld(ap['marge_niveau']);
      final marge = (mn[0] + mn[1] * niveau) - dbl(fiche['difficulte'] ?? 3);
      final base = typ == 'reps'
          ? dbl(ap['reps_base'])
          : dbl(ap['tenue_base_s']);
      final bornes = typ == 'reps'
          ? jld(ap['reps_bornes'])
          : jld(ap['tenue_bornes_s']);
      return math.log(
        clampD(
          base * math.exp(dbl(ap['pente_difficulte']) * marge),
          bornes[0],
          bornes[1],
        ),
      );
    }
    if (typ == 'cardio') {
      return math.log(jld(ap['cardio_minutes_par_niveau'])[niveau]);
    }
    return 0.0;
  }

  List<_Branche> _branches() {
    final out = [_Branche(m, pm, cap)];
    if (_alt != null) {
      out.add(_alt!);
    }
    return out;
  }

  /// Piste de l'exercice (créée au besoin), ou null s'il n'est pas suivi.
  Piste? piste(String exId) {
    final t = pistes[exId];
    if (t != null || pistes.containsKey(exId)) {
      return t;
    }
    final fiche = vecteurs[exId];
    if (fiche == null ||
        !const [
          'charge',
          'reps',
          'tenue',
          'cardio',
          'wod',
        ].contains(fiche['type'])) {
      pistes[exId] = null;
      return null;
    }
    _agrandir();
    final ap = jm(p['a_priori']);
    final idx = n;
    n += 3;
    final typ = fiche['type'] as String;
    final base = baseDe(fiche);
    final sd = dbl(
      ap[const {
        'charge': 'delta_sd',
        'reps': 'reps_sd',
        'tenue': 'reps_sd',
        'cardio': 'cardio_sd',
        'wod': 'wod_sd',
      }[typ]!],
    );
    final vecteur = jld(fiche['vecteur']);
    final groupes = <(int, double)>[
      for (final g in listeOuVide(fiche['groupes']))
        (ent(jl(g)[0]), dbl(jl(g)[1])),
    ];
    final nt = Piste(
      exId,
      typ,
      vecteur,
      base,
      idx,
      fraction: dbl(fiche['fraction'] ?? 0.0),
      bas: vrai(fiche['bas'] ?? false),
      tendon: dbl(fiche['tendon'] ?? 0.0),
      zoneTendon: fiche['zone_tendon'] as String?,
      systemique: dbl(fiche['systemique'] ?? 1.0),
      locale: dbl(fiche['locale'] ?? 1.0),
      groupes: groupes,
    );
    for (final br in _branches()) {
      final c = br.cap;
      br.m[idx] = 0.0;
      var vq = 0.0;
      for (var q = 0; q < nq; q++) {
        vq += vecteur[q] * vecteur[q] * br.p[(th + q) * c + th + q];
      }
      br.p[idx * c + idx] = math.max(sd * sd - vq, pw(0.5 * sd, 2));
      br.m[idx + 2] = 0.0;
      br.p[(idx + 2) * c + idx + 2] = pw(
        dbl(ap['fatigue_intra_exercice_sd']),
        2,
      );
      if (typ == 'tenue') {
        br.m[idx + 1] = 0.0;
        br.p[(idx + 1) * c + idx + 1] = pw(
          dbl(ap['part_tenue_exercice_sd']),
          2,
        );
      } else {
        br.m[idx + 1] = nt.bas ? dbl(ap['courbe_bas_du_corps']) : 0.0;
        br.p[(idx + 1) * c + idx + 1] = pw(
          dbl(ap['courbe_echelle_exercice_sd']),
          2,
        );
      }
    }
    pistes[exId] = nt;
    ordre.add(exId);
    final d = dictOuVide(profil['declares'])[exId];
    if (d != null) {
      final dl = jl(d);
      final mesure = dl[0];
      final valeur = dbl(dl[1]);
      final sdD = (dl.length > 2 && vrai(dl[2]))
          ? dbl(dl[2])
          : dbl(ap['delta_sd_declare']);
      final voulu = const {
        'charge': 'one_rm_kg',
        'reps': 'max_reps',
        'tenue': 'max_hold_seconds',
      }[typ];
      if (mesure == voulu && valeur > 0) {
        double cible;
        if (typ == 'charge') {
          cible = math.log(valeur + nt.fraction * poidsKg);
        } else {
          cible = math.log(valeur);
        }
        final (hi, hc) = hCapacite(nt, jour: false);
        _observerHors(
          hi,
          hc,
          nt.base - cible,
          null,
          null,
          pw(sdD, 2),
          point: 0.0,
        );
        nt.declare = true;
      }
    }
    return nt;
  }

  // ------------------------------------------------------------------
  // Courbe répétitions ↔ charge (Box-Cox)
  // ------------------------------------------------------------------
  double courbeMoyenne(double reps, bool bas) {
    final ap = jm(p['a_priori']);
    final k =
        jld(ap['courbe_echelle'])[0] +
        (bas ? dbl(ap['courbe_bas_du_corps']) : 0.0);
    return gK(jld(ap['courbe_forme'])[0], k, reps);
  }

  /// −ln(part du 1RM soulevable [reps] fois).
  static double gK(double lamb, double k, double reps) {
    final r = reps < 1 ? 1.0 : reps;
    final gam = 1.0 - lamb;
    final a = math.log(r);
    return math.exp(k) * g8 * a * phiK(gam * a) / (ln8 * phiK(gam * ln8));
  }

  /// Dérivée de g par rapport aux répétitions (plancher 0,004).
  static double dgK(double lamb, double k, double reps) {
    final r = reps < 1 ? 1.0 : reps;
    final gam = 1.0 - lamb;
    final d =
        math.exp(k) *
        g8 *
        math.exp((gam - 1.0) * math.log(r)) /
        (ln8 * phiK(gam * ln8));
    return d > 0.004 ? d : 0.004;
  }

  /// Dérivée de g par rapport à la forme.
  static double dgFormeK(double lamb, double k, double reps) {
    final r = reps < 1 ? 1.0 : reps;
    final gam = 1.0 - lamb;
    final a = math.log(r);
    final den = ln8 * phiK(gam * ln8);
    final num = a * phiK(gam * a);
    final dGam =
        math.exp(k) *
        g8 *
        (a * a * phi1K(gam * a) * den - num * ln8 * ln8 * phi1K(gam * ln8)) /
        (den * den);
    return -dGam;
  }

  /// (forme, échelle) de la courbe de l'exercice.
  (double, double) courbe(Piste t, [Float64List? mm]) {
    final x = mm ?? m;
    return (
      clampD(x[lam], lamMin, lamMax),
      clampD(x[ku] + x[t.idx + 1], -1.0, 1.0),
    );
  }

  /// Inverse de g (forme fermée), bornée à 200 répétitions.
  static double repsDe(double lamb, double k, double logRatio) {
    final gam = 1.0 - lamb;
    final y = logRatio * ln8 * phiK(gam * ln8) / (math.exp(k) * g8);
    final u = gam * y;
    if (u <= -1.0 + 1e-12) {
      return 200.0;
    }
    double lnR;
    if (-1e-2 < u && u < 1e-2) {
      lnR =
          y *
          (1.0 +
              u *
                  (-0.5 +
                      u *
                          (1.0 / 3.0 +
                              u *
                                  (-0.25 +
                                      u *
                                          (0.2 +
                                              u * (-1.0 / 6.0 + u / 7.0))))));
    } else {
      lnR = math.log(1.0 + u) / gam;
    }
    if (lnR > 5.298317366548036) {
      return 200.0;
    }
    final r = math.exp(lnR);
    return r > 1.0 ? r : 1.0;
  }

  double repsA(Piste t, double logRatio, [Float64List? mm]) {
    final (l, k) = courbe(t, mm);
    if (logRatio <= 0) {
      return logRatio > -0.05 ? 1.0 + logRatio * 20.0 : 0.0;
    }
    return repsDe(l, k, logRatio);
  }

  // ------------------------------------------------------------------
  // Compartiments de fatigue
  // ------------------------------------------------------------------
  void avancer(int j) {
    final dt = j - jour;
    if (dt <= 0) {
      return;
    }
    for (final c in const [0, 1]) {
      final e = math.exp(-dt / tau[c]);
      fG[c] *= e;
      for (var g = 0; g < ngr; g++) {
        fL[c][g] *= e;
      }
    }
    final e = math.exp(-dt / tau[2]);
    for (final z in zonesTendon) {
      fTendon[z] = fTendon[z]! * e;
    }
    final dyn = jm(p['dynamique']);
    final q = dbl(dyn['q_delta_jour_inactif']);
    for (final exId in ordre) {
      final t = pistes[exId]!;
      pm[t.idx * cap + t.idx] += q * dt;
    }
    jour = j;
  }

  double effort(double rir, [bool echec = false]) {
    final f = jm(p['fatigue']);
    final w = 1.0 / (1.0 + (rir > 0 ? rir : 0.0) / dbl(f['effort_demi_rir']));
    return w + (echec ? dbl(f['echec_supplement']) : 0.0);
  }

  double effortIntra(double rir) =>
      math.exp(-(rir > 0 ? rir : 0.0) / dbl(jm(p['fatigue'])['intra_rir']));

  void _chargerCompartiments(Piste t, double eff, [double quantite = 1.0]) {
    for (final c in const [0, 1]) {
      fG[c] += eff * t.systemique;
      for (final (g, w) in t.groupes) {
        fL[c][g] += eff * t.locale * w;
      }
    }
    if (t.zoneTendon != null && t.tendon > 0) {
      fTendon[t.zoneTendon!] =
          fTendon[t.zoneTendon!]! + eff * t.tendon * quantite;
      fTendonAigu[t.zoneTendon!] =
          fTendonAigu[t.zoneTendon!]! + eff * t.tendon * quantite;
    }
  }

  /// (rapide systémique, rapide local, lent systémique, lent local).
  (double, double, double, double) fatigueDe(Piste t) {
    final loc = [0.0, 0.0];
    if (t.groupesTotal > 0) {
      for (final c in const [0, 1]) {
        for (final (g, w) in t.groupes) {
          loc[c] += w * fL[c][g];
        }
        loc[c] /= t.groupesTotal;
      }
    }
    return (fG[0], loc[0], fG[1], loc[1]);
  }

  double fatigueIntraDe(Piste t, [Float64List? mm]) {
    final x = mm ?? m;
    return clampD(x[fi], 0.0, 1.5) * math.exp(clampD(x[t.idx + 2], -1.5, 1.5));
  }

  double gardeDe(Piste t, [Float64List? mm]) {
    final g = 1.0 - fatigueIntraDe(t, mm) * intra(t);
    return g > 0.3 ? g : 0.3;
  }

  /// Régresseur de fatigue intra-séance de la prochaine série.
  double intra(Piste t) {
    final f = jm(p['fatigue']);
    var s = 0.0;
    final nn = t.seriesSeance.length;
    final rs = dbl(f['intra_repos_s']);
    final rep = dbl(f['intra_report']);
    for (var i = 0; i < nn; i++) {
      final (eff, repos) = t.seriesSeance[i];
      s += eff * math.exp(-repos / rs) * pw(rep, (nn - 1 - i).toDouble());
    }
    return s;
  }

  // ------------------------------------------------------------------
  // Séance
  // ------------------------------------------------------------------
  void debutSeance(int j, Json? bil, Object? poids) {
    avancer(j);
    if (vrai(poids)) {
      poidsKg = dbl(poids);
    }
    final jj = jm(p['jour']);
    var moyenne = 0.0;
    var sd = dbl(jj['sigma_seance']);
    var pMauvais = dbl(jj['mauvais_jour_proba']);
    final general = bil?['overall'];
    if (general != null) {
      moyenne =
          dbl(jj['bilan_par_point']) * (dbl(general) - dbl(jj['bilan_neutre']));
      sd = dbl(jj['sigma_seance_avec_bilan']);
      if (dbl(general) <= 2) {
        pMauvais = dbl(jj['mauvais_jour_proba_bilan_bas']);
      }
    }
    _reset(m, pm, cap, ds, moyenne, sd * sd);
    _reset(m, pm, cap, de, 0.0, pw(dbl(jj['sigma_exercice']), 2));
    final am = Float64List.fromList(m);
    final aP = Float64List.fromList(pm);
    _reset(
      am,
      aP,
      cap,
      ds,
      moyenne + dbl(jj['mauvais_jour_moyenne']),
      pw(dbl(jj['mauvais_jour_sigma']), 2),
    );
    _alt = _Branche(am, aP, cap);
    altLw = math.log(pMauvais);
    logw = math.log(1.0 - pMauvais);
    enSeance = true;
    bilan = bil;
    residusSeance = [];
    _dernierEx = null;
    for (final exId in ordre) {
      pistes[exId]!.seriesSeance = [];
    }
  }

  static void _reset(
    Float64List mm,
    Float64List pp,
    int c,
    int idx,
    double moyenne,
    double variance,
  ) {
    for (var j = 0; j < c; j++) {
      pp[idx * c + j] = 0.0;
    }
    for (var i = 0; i < c; i++) {
      pp[i * c + idx] = 0.0;
    }
    pp[idx * c + idx] = variance;
    mm[idx] = moyenne;
  }

  void debutExercice(Piste t) {
    final jj = jm(p['jour']);
    for (final br in _branches()) {
      _reset(br.m, br.p, br.cap, de, 0.0, pw(dbl(jj['sigma_exercice']), 2));
    }
    if (t.jourSeance != jour) {
      t.jourPrevu = (t.type == 'charge' && t.seances >= 3)
          ? capaciteDuJour(t.id)!.$1
          : null;
      t.jourVu = null;
      t.seriesSeance = [];
      t.jourSeance = jour;
      t.seances += 1;
      t.premierJour ??= jour;
    }
    t.dernierJour = jour;
  }

  double poidsMauvaisJour() {
    if (_alt == null) {
      return 0.0;
    }
    final a = logw;
    final b = altLw;
    final mx = a > b ? a : b;
    return math.exp(b - mx) / (math.exp(a - mx) + math.exp(b - mx));
  }

  /// Ferme la séance : fusion des deux branches.
  ResumeSeance? finSeance() {
    if (!enSeance) {
      return null;
    }
    final ecarts = <double>[];
    for (final exId in ordre) {
      final t = pistes[exId]!;
      if (t.jourSeance == jour && t.jourPrevu != null && t.jourVu != null) {
        ecarts.add(t.jourVu! - t.jourPrevu!);
      }
    }
    final double? e1rm = ecarts.isNotEmpty
        ? somme(ecarts) / ecarts.length
        : null;
    final w = poidsMauvaisJour();
    if (_alt != null && w > 1e-9) {
      final am = _alt!.m;
      final aP = _alt!.p;
      final nn = n;
      final mNew = Float64List(nn);
      final d0 = Float64List(nn);
      final d1 = Float64List(nn);
      for (var i = 0; i < nn; i++) {
        mNew[i] = (1 - w) * m[i] + w * am[i];
      }
      for (var i = 0; i < nn; i++) {
        d0[i] = m[i] - mNew[i];
        d1[i] = am[i] - mNew[i];
      }
      for (var i = 0; i < nn; i++) {
        for (var j = 0; j < nn; j++) {
          pm[i * cap + j] =
              (1 - w) * (pm[i * cap + j] + d0[i] * d0[j]) +
              w * (aP[i * cap + j] + d1[i] * d1[j]);
        }
      }
      for (var i = 0; i < nn; i++) {
        m[i] = mNew[i];
      }
    }
    _alt = null;
    enSeance = false;
    final jj = jm(p['jour']);
    _reset(m, pm, cap, ds, 0.0, pw(dbl(jj['sigma_seance']), 2));
    _reset(m, pm, cap, de, 0.0, pw(dbl(jj['sigma_exercice']), 2));
    ResumeSeance? resume;
    if (residusSeance.isNotEmpty) {
      final zs = [for (final r in residusSeance) r.$1];
      final rel = [for (final r in residusSeance) r.$2];
      resume = (
        jour,
        somme(zs) / zs.length,
        somme(rel) / rel.length,
        zs.length,
        w,
        e1rm,
      );
      histoireResidus.add(resume);
    }
    return resume;
  }

  // ------------------------------------------------------------------
  // Fonctionnelle linéaire d'un exercice
  // ------------------------------------------------------------------
  (List<int>, List<double>) hCapacite(Piste t, {bool jour = true}) {
    final idx = <int>[];
    final co = <double>[];
    for (var q = 0; q < nq; q++) {
      if (t.vecteur[q] != 0.0) {
        idx.add(th + q);
        co.add(t.vecteur[q]);
      }
    }
    idx.add(t.idx);
    co.add(1.0);
    if (jour) {
      final (gn, lnn, gm, lm) = fatigueDe(t);
      idx.addAll([ds, de, kn, kl, kg, km]);
      co.addAll([1.0, 1.0, -gn, -lnn, -gm, -lm]);
    }
    return (idx, co);
  }

  List<int>? _figeMauvaisJour(Piste t, [Json? s]) {
    if (!vrai(jm(p['jour'])['mauvais_jour_fige_capacite'])) {
      return null;
    }
    if (s != null &&
        ou(s['role'], dictOuVide(s['target'])['role']) == 'attempt') {
      return null;
    }
    return hCapacite(t, jour: false).$1;
  }

  /// Moyenne et variance de h·x, et le vecteur P h (capacité entière).
  static (double, double, Float64List) stats(
    Float64List mm,
    Float64List pp,
    int c,
    List<int> idx,
    List<double> co,
  ) {
    final ph = Float64List(c);
    var mu = 0.0;
    for (var k = 0; k < idx.length; k++) {
      final i = idx[k];
      final cc = co[k];
      mu += cc * mm[i];
      for (var r = 0; r < c; r++) {
        ph[r] += cc * pp[r * c + i];
      }
    }
    var v = 0.0;
    for (var k = 0; k < idx.length; k++) {
      v += co[k] * ph[idx[k]];
    }
    return (mu, v, ph);
  }

  static void _appliquer(
    Float64List mm,
    Float64List pp,
    int c,
    Float64List ph,
    double mu,
    double v,
    double mu2,
    double v2,
  ) {
    if (v <= 0) {
      return;
    }
    final g = (mu2 - mu) / v;
    for (var i = 0; i < c; i++) {
      mm[i] += ph[i] * g;
    }
    final k = (v - v2) / (v * v);
    for (var i = 0; i < c; i++) {
      for (var j = 0; j < c; j++) {
        pp[i * c + j] -= (ph[i] * ph[j]) * k;
      }
    }
  }

  static void _covariancePartielle(
    Float64List pp,
    int c,
    Float64List ph,
    Float64List pg,
    double v,
    double v2,
  ) {
    final w = (v - v2) / (v * v);
    for (var i = 0; i < c; i++) {
      for (var j = 0; j < c; j++) {
        pp[i * c + j] -= w * (pg[i] * ph[j] + ph[i] * pg[j] - pg[i] * pg[j]);
      }
    }
  }

  /// Applique une observation aux deux branches (§ 5.4).
  Residu? _observer(
    List<int> idx,
    List<double> co,
    double constante,
    double? a,
    double? b,
    double s2, {
    double? point,
    (double, double)? melange,
    double Function(double)? bruit,
    double Function(Float64List)? fonction,
    List<int>? fige,
    List<int>? figeAlt,
  }) {
    Residu? resid;
    final branches = _branches();
    for (var bi = 0; bi < branches.length; bi++) {
      final br = branches[bi];
      final mm = br.m;
      final pp = br.p;
      final c = br.cap;
      var (mu, v, ph) = stats(mm, pp, c, idx, co);
      mu += constante;
      double logz;
      double mu2;
      double v2;
      double centre;
      if (point != null) {
        (logz, mu2, v2) = pointMoments(mu, v, s2, point);
        centre = point;
      } else {
        if (bruit != null) {
          final ge = jld(jm(p['mesure'])['note_erreur_grossiere']);
          (logz, mu2, v2) = categoryMoments(
            mu,
            v,
            a!,
            b!,
            bruit,
            gross: ge[0],
            grossSd: ge[1],
          );
        } else {
          (logz, mu2, v2) = intervalMoments(mu, v, s2, a!, b!);
        }
        if (melange != null) {
          final (wMain, wNul) = melange;
          final muB = mu;
          final vB = v;
          final la = math.log(wMain) + logz;
          final lb = math.log(wNul);
          final mx = la > lb ? la : lb;
          var wa = math.exp(la - mx);
          var wb = math.exp(lb - mx);
          final tot = wa + wb;
          wa /= tot;
          wb /= tot;
          final mean = wa * mu2 + wb * muB;
          final variance =
              wa * (v2 + pw(mu2 - mean, 2)) + wb * (vB + pw(muB - mean, 2));
          logz = mx + math.log(tot);
          mu2 = mean;
          v2 = variance;
        }
        if (a == -inf) {
          centre = b;
        } else if (b == inf) {
          centre = a;
        } else {
          centre = 0.5 * (a + b);
        }
      }
      if (bi == 0) {
        final informatif = point != null || (a != -inf && b != inf);
        final dehors =
            (point == null) &&
            ((a == -inf && mu > b!) || (b == inf && mu < a!));
        if (informatif || dehors) {
          resid = (
            (centre - mu) / math.sqrt(v + s2),
            centre - mu,
            informatif && point == null,
          );
        }
      }
      if (v <= 0.0) {
        continue;
      }
      var pg = ph;
      var figeB = fige;
      if (bi == 1 && figeAlt != null && figeAlt.isNotEmpty) {
        figeB = [...?fige, ...figeAlt];
      }
      final figeVrai = figeB != null && figeB.isNotEmpty;
      if (figeVrai) {
        pg = Float64List.fromList(ph);
        for (final i in figeB) {
          pg[i] = 0.0;
        }
      }
      if (fonction != null && (mu2 - mu).abs() > 1.0) {
        final g = (mu2 - mu) / v;
        final pas = Float64List(c);
        for (var i = 0; i < c; i++) {
          pas[i] = pg[i] * g;
        }
        var alpha = 1.0;
        Float64List decale(double f) {
          final x = Float64List(c);
          for (var i = 0; i < c; i++) {
            x[i] = mm[i] + f * pas[i];
          }
          return x;
        }

        Float64List decale1() {
          final x = Float64List(c);
          for (var i = 0; i < c; i++) {
            x[i] = mm[i] + pas[i];
          }
          return x;
        }

        if ((fonction(decale1()) - mu).abs() > (mu2 - mu).abs()) {
          var loA = 0.0;
          var hiA = 1.0;
          for (var it = 0; it < 12; it++) {
            final mid = 0.5 * (loA + hiA);
            if ((fonction(decale(mid)) - mu).abs() > (mu2 - mu).abs()) {
              hiA = mid;
            } else {
              loA = mid;
            }
          }
          alpha = loA;
        }
        for (var i = 0; i < c; i++) {
          mm[i] += alpha * pas[i];
        }
        final v2a = v - (2.0 * alpha - alpha * alpha) * (v - v2);
        if (figeVrai) {
          _covariancePartielle(pp, c, ph, pg, v, v2a < v ? v2a : v);
        } else {
          final k = (v - v2a) / (v * v);
          for (var i = 0; i < c; i++) {
            for (var j = 0; j < c; j++) {
              pp[i * c + j] -= (ph[i] * ph[j]) * k;
            }
          }
        }
      } else if (figeVrai) {
        final g = (mu2 - mu) / v;
        for (var i = 0; i < c; i++) {
          mm[i] += pg[i] * g;
        }
        _covariancePartielle(pp, c, ph, pg, v, v2 < v ? v2 : v);
      } else {
        _appliquer(mm, pp, c, ph, mu - constante, v, mu2 - constante, v2);
      }
      if (bi == 0) {
        logw += logz;
      } else {
        altLw = altLw + logz;
      }
    }
    return resid;
  }

  // ------------------------------------------------------------------
  // Bruit et biais de la note
  // ------------------------------------------------------------------
  double bruitRirDe(double rir, double reps) {
    final me = jm(p['mesure']);
    final base = jld(me['bruit_rir_par_niveau'])[niveau] * bruitRir;
    final pl = dbl(me['bruit_rir_plancher']);
    final pe = dbl(me['bruit_rir_pente']);
    var s = base * (pl + pe * rir) / (pl + pe * dbl(me['bruit_rir_reference']));
    final de0 = dbl(me['bruit_rir_longue_serie_de']);
    if (reps > de0) {
      s *= 1 + dbl(me['bruit_rir_longue_serie_pente']) * (reps - de0);
    }
    return s;
  }

  void noterResolution(Object? flammes) {
    if (flammes == null || dbl(flammes) >= 10) {
      return;
    }
    if (const [2, 4, 6, 8].contains(flammes) ||
        const [2.0, 4.0, 6.0, 8.0].contains(flammes)) {
      notesDemi += 1;
    } else {
      notesEntieres += 1;
    }
  }

  bool noteurEntier() {
    final me = jm(p['mesure']);
    final nn = notesDemi + notesEntieres;
    return nn >= dbl(me['noteur_entier_notes_min']) &&
        notesDemi <= dbl(me['noteur_entier_part_max']) * nn;
  }

  /// Intervalle de réserve perçue d'une note, et son centre.
  (double, double, double) bornesFlammes(
    double flammes, [
    double ouvert = 5.0,
  ]) {
    if (flammes >= 10) {
      return (0.0, 0.25, 0.0);
    }
    final entier = noteurEntier();
    if (flammes == 9) {
      return (0.25, entier ? 1.5 : 1.25, 1.0);
    }
    final r = (11 - flammes) / 2.0;
    final demi = entier ? 0.5 : 0.25;
    if (r >= ouvert) {
      return (r - demi, inf, r);
    }
    return (r - demi, r + demi, r);
  }

  double rirVrai(double percu, [Float64List? mm]) {
    final x = mm ?? m;
    if (percu <= 0) {
      return 0.0;
    }
    final v =
        percu * (1.0 + clampD(x[bp], -0.2, 1.0)) + clampD(x[ba], -2.5, 2.5);
    return v > 0.0 ? v : 0.0;
  }

  // ------------------------------------------------------------------
  // Observation d'une série
  // ------------------------------------------------------------------
  Piste? observerSerie(Json s) {
    final t = piste(s['exerciseId'] as String);
    if (t == null) {
      return null;
    }
    if (_dernierEx != t.id) {
      debutExercice(t);
    }
    _dernierEx = t.id;
    if (!vrai(s['failed'])) {
      noterResolution(s['flames']);
    }
    final typ = t.type;
    Residu? r;
    if (typ == 'charge' || typ == 'reps') {
      r = _serieForce(t, s);
    } else if (typ == 'tenue') {
      r = _serieTenue(t, s);
    } else {
      r = _serieEndurance(t, s);
    }
    if (t.jourPrevu != null) {
      t.jourVu = capaciteDuJour(t.id)!.$1;
    }
    if (r != null) {
      residusSeance.add(r);
      t.residus.add((jour, r.$1, r.$2));
      if ((typ == 'charge' || typ == 'reps') && r.$3) {
        _apprendreBruit(r.$1);
      }
      _projeter();
    }
    return t;
  }

  void _apprendreBruit(double z) {
    final me = jm(p['mesure']);
    final l = dbl(me['apprentissage_bruit_oubli']);
    z2 = l * z2 + (1 - l) * math.min(z * z, 9.0);
    z2N = l * z2N + 1.0;
    if (z2N > 12) {
      final bornes = jld(me['apprentissage_bruit_bornes']);
      final cible = math.sqrt(z2);
      bruitRir = clampD(
        bruitRir * (1 + 0.02 * (cible - 1.0)),
        bornes[0],
        bornes[1],
      );
    }
  }

  double masse(Piste t, double? externe) {
    if (t.type == 'charge') {
      return (externe ?? 0.0) + t.fraction * poidsKg;
    }
    return 1.0;
  }

  void _projeter() {
    for (final br in _branches()) {
      final x = br.m;
      for (final i in const [kn, km, kl, kg]) {
        if (x[i] < 0.0) {
          x[i] = 0.0;
        }
      }
      if (x[lam] < lamMin) {
        x[lam] = lamMin;
      }
      if (x[lam] > lamMax) {
        x[lam] = lamMax;
      }
    }
  }

  /// Linéarisation de la réserve d'une série de force : (indices,
  /// coefficients, valeur prédite, répétitions possibles, réserve vraie).
  (List<int>, List<double>, double, double, double) _linForce(
    Piste t,
    Float64List x,
    double lnL,
    double reps,
    double sj,
    bool sansCharge,
    bool percu,
  ) {
    final (idx, co) = hCapacite(t);
    var eta = t.base;
    for (var k = 0; k < idx.length; k++) {
      eta += co[k] * x[idx[k]];
    }
    final fiv = fatigueIntraDe(t, x);
    var garde = 1.0 - fiv * sj;
    if (garde < 0.3) {
      garde = 0.3;
    }
    double r;
    double dR;
    double dlam;
    double dk;
    if (sansCharge) {
      r = math.exp(eta);
      dR = r;
      dlam = 0.0;
      dk = 0.0;
    } else {
      final (l, k) = courbe(t, x);
      final xx = eta - lnL;
      r = repsA(t, xx, x);
      if (xx <= 0) {
        dR = 20.0;
        dlam = 0.0;
        dk = 0.0;
      } else {
        final d = dgK(l, k, r);
        final r1 = r > 1 ? r : 1.0;
        dR = 1.0 / d;
        dlam = -dgFormeK(l, k, r1) / d;
        dk = -gK(l, k, r) / d;
      }
    }
    final v = r * garde - reps;
    var coefs = [for (final c in co) c * dR * garde];
    final indices = List<int>.of(idx);
    if (!sansCharge) {
      indices.addAll([lam, ku, t.idx + 1]);
      coefs.addAll([dlam * garde, dk * garde, dk * garde]);
    }
    if (sj > 0 && garde > 0.3) {
      indices.add(t.idx + 2);
      coefs.add(-r * sj * fiv);
    }
    if (!percu) {
      return (indices, coefs, v, r, v);
    }
    final bA = clampD(x[ba], -2.5, 2.5);
    final bP = clampD(x[bp], -0.2, 1.0);
    final pr = (v - bA) / (1.0 + bP);
    coefs = [for (final c in coefs) c / (1.0 + bP)];
    indices.addAll([ba, bp]);
    coefs.addAll([-1.0 / (1.0 + bP), -pr / (1.0 + bP)]);
    return (indices, coefs, pr, r, v);
  }

  Residu? _serieForce(Piste t, Json s) {
    final me = jm(p['mesure']);
    final reps = vrai(s['reps']) ? dbl(s['reps']) : 0.0;
    final externe = dblOu(s['externalLoadKg']);
    final flammesO = s['flames'];
    final cible = dictOuVide(s['target']);
    final echec = vrai(s['failed']);
    final repos = s['restSeconds'] == null ? 90.0 : dbl(s['restSeconds']);
    final charge = masse(t, externe);
    final sansCharge = t.type == 'reps';
    if (charge <= 0 && !sansCharge) {
      return null;
    }
    final lnL = sansCharge ? 0.0 : math.log(charge);
    final sj = intra(t);
    Residu? resid;
    var rirC = 2.0;
    if (reps <= 0 && echec) {
      if (!sansCharge) {
        final (idx, co) = hCapacite(t);
        resid = _observer(
          idx,
          co,
          t.base - lnL,
          -inf,
          0.0,
          pw(dbl(me['bruit_test']), 2),
          figeAlt: _figeMauvaisJour(t, s),
        );
      }
      rirC = 0.0;
    } else {
      final percu = !(echec || flammesO == null);
      final double? flammes = dblOu(flammesO);
      double a;
      double b;
      if (echec) {
        a = 0.0;
        b = 1.0;
      } else if (flammes == null) {
        a = 0.0;
        b = inf;
      } else if (flammes >= 10) {
        a = -inf;
        b = 0.25;
      } else {
        final bf = bornesFlammes(flammes, dbl(me['rir_ouvert']));
        a = bf.$1;
        b = bf.$2;
      }
      final lin = m;
      final (idx, co, pred, rr, v) = _linForce(
        t,
        lin,
        lnL,
        reps,
        sj,
        sansCharge,
        percu,
      );
      final s2 = _bruitForce(percu, v, reps, rr, me, sj);
      var constante = pred;
      for (var k = 0; k < idx.length; k++) {
        constante -= co[k] * lin[idx[k]];
      }
      (double, double)? melange;
      final fCible = dblOu(cible['flames']);
      if (percu) {
        final e = dbl(me['note_aberrante']);
        var par = 0.0;
        if (fCible != null && flammes == fCible) {
          par = clampD(paresse[0] / (paresse[0] + paresse[1]), 0.01, 0.9);
        }
        melange = ((1.0 - e) * (1.0 - par), e * 0.1 + (1.0 - e) * par);
      }
      if (flammes == null && !echec && pred >= a) {
        resid = null;
      } else if (b == inf &&
          percu &&
          pred >= a + dbl(me['porte_note_ouverte']) * math.sqrt(s2)) {
        resid = null;
      } else {
        double Function(double)? bruit;
        if (percu) {
          final bA = clampD(m[ba], -2.5, 2.5);
          final bP = clampD(m[bp], -0.2, 1.0);
          final extra = pw(dbl(me['dispersion_fatigue_intra']) * sj * rr, 2);
          final rCap = rr;
          bruit = (double u) {
            var r = u * (1.0 + bP) + bA;
            if (r < 0.0) {
              r = 0.0;
            }
            if (r > 8.0) {
              r = 8.0;
            }
            final sd = bruitRirDe(r, rCap);
            return sd * sd + extra;
          };
        }
        double exacte(Float64List etat) =>
            _linForce(t, etat, lnL, reps, sj, sansCharge, percu).$3;
        List<int>? fige;
        if (flammes == null && !echec) {
          fige = sansCharge ? [lam] : [lam, t.idx + 1];
        }
        resid = _observer(
          idx,
          co,
          constante,
          a,
          b,
          s2,
          melange: melange,
          bruit: bruit,
          fonction: exacte,
          fige: fige,
          figeAlt: _figeMauvaisJour(t, s),
        );
      }
      if (percu && fCible != null && resid != null && resid.$2.abs() > 1.0) {
        if (flammes == fCible) {
          paresse[0] += 1.0;
        } else {
          paresse[1] += 1.0;
        }
      }
      _projeter();
      final vPost = _linForce(t, m, lnL, reps, sj, sansCharge, false).$5;
      rirC = vPost > 0 ? vPost : 0.0;
      if (echec) {
        rirC = 0.0;
      }
    }
    final eff = effort(rirC, echec);
    t.seriesSeance.add((effortIntra(rirC), repos));
    _chargerCompartiments(t, eff);
    _stimulus(t, rirC, lnL, reps > 0);
    t.mesures += 1;
    final role0 = s['role'];
    if (echec || vrai(s['repere']) || role0 == 'test' || role0 == 'attempt') {
      t.dernierTestJour = jour;
    }
    if (echec) {
      t.dernierEchecJour = jour;
    }
    final role = ou(s['role'], dictOuVide(s['target'])['role']);
    if (role == 'test' || role == 'attempt') {
      t.derniereRampeJour = jour;
      final ri = dbl(jm(p['test_adaptatif'])['vrai_test_rir_informatif']);
      final double? f = dblOu(flammesO);
      if (echec || (f != null && (f >= 10 || (11 - f) / 2.0 <= ri + 1e-9))) {
        t.dernierVraiTestJour = jour;
      }
    }
    if (reps > 0 && !echec && !sansCharge) {
      if (t.meilleur == null || charge > t.meilleur!.$1) {
        t.meilleur = (charge, jour);
      }
    }
    return resid;
  }

  double _bruitForce(
    bool percu,
    double v,
    double reps,
    double r,
    Json me, [
    double sj = 0.0,
  ]) {
    final extra = pw(dbl(me['dispersion_fatigue_intra']) * sj * r, 2);
    if (!percu) {
      return pw(0.35, 2) + extra;
    }
    var rr = v > 0 ? v : 0.0;
    if (rr > 8) {
      rr = 8.0;
    }
    return pw(bruitRirDe(rr, r), 2) + extra;
  }

  void _stimulus(Piste t, double rir, double lnL, bool fait) {
    if (!fait) {
      return;
    }
    var part = 1.0;
    if (t.type == 'charge') {
      part = math.exp(lnL - (t.base + mu(t)));
    }
    t.stimSemaine[0] += rir <= 4 ? 1.0 : 0.5;
    t.stimSemaine[1] += 1.0 / (1.0 + (rir > 1 ? rir - 1 : 0.0) / 3.0);
    t.stimSemaine[2] += clampD((part - 0.4) / 0.4, 0.2, 1.5);
  }

  double mu(Piste t, [Float64List? mm]) {
    final x = mm ?? m;
    var v = x[t.idx];
    for (var q = 0; q < nq; q++) {
      v += t.vecteur[q] * x[th + q];
    }
    return v;
  }

  (List<int>, List<double>, double, double) _linTenue(
    Piste t,
    Float64List x,
    double lnS,
    bool percu,
  ) {
    final (idx, co) = hCapacite(t);
    var eta = t.base;
    for (var k = 0; k < idx.length; k++) {
      eta += co[k] * x[idx[k]];
    }
    final hhe =
        clampD(x[hh], 0.03, 0.30) * math.exp(clampD(x[t.idx + 1], -1.0, 1.0));
    var part = math.exp(lnS - eta);
    if (part > 3.0) {
      part = 3.0;
    }
    final r = (1.0 - part) / hhe;
    var coefs = [for (final c in co) c * part / hhe];
    final indices = List<int>.of(idx);
    indices.add(t.idx + 1);
    coefs.add(-r);
    if (!percu) {
      return (indices, coefs, r, r);
    }
    final bA = clampD(x[ba], -2.5, 2.5);
    final bP = clampD(x[bp], -0.2, 1.0);
    final pr = (r - bA) / (1.0 + bP);
    coefs = [for (final c in coefs) c / (1.0 + bP)];
    indices.addAll([ba, bp]);
    coefs.addAll([-1.0 / (1.0 + bP), -pr / (1.0 + bP)]);
    return (indices, coefs, pr, r);
  }

  Residu? _serieTenue(Piste t, Json s) {
    final me = jm(p['mesure']);
    final sec = vrai(s['seconds']) ? dbl(s['seconds']) : 0.0;
    final double? flammes = dblOu(s['flames']);
    final echec = vrai(s['failed']);
    final repos = s['restSeconds'] == null ? 90.0 : dbl(s['restSeconds']);
    if (sec <= 0 && !echec) {
      return null;
    }
    final (idx, co) = hCapacite(t);
    final sj = intra(t);
    final garde = gardeDe(t);
    final lnS = math.log((sec > 0 ? sec : 0.5) / garde);
    final bt = dbl(me['bruit_tenue']);
    final extra = pw(dbl(me['dispersion_fatigue_intra']) * sj, 2);
    Residu? resid;
    double rirC;
    if (echec) {
      resid = _observer(
        idx,
        co,
        t.base - lnS,
        null,
        null,
        pw(bt / 2, 2) + extra,
        point: 0.0,
        figeAlt: _figeMauvaisJour(t, s),
      );
      rirC = 0.0;
    } else if (flammes == null) {
      final mu0 = stats(m, pm, cap, idx, co).$1;
      resid = null;
      if (mu0 + t.base - lnS < 0.0) {
        resid = _observer(
          idx,
          co,
          t.base - lnS,
          0.0,
          inf,
          pw(bt, 2) + extra,
          figeAlt: _figeMauvaisJour(t, s),
        );
      }
      rirC = 2.0;
    } else {
      double a;
      double b;
      if (flammes >= 10) {
        a = -inf;
        b = 0.25;
      } else {
        final bf = bornesFlammes(flammes, dbl(me['rir_ouvert']));
        a = bf.$1;
        b = bf.$2;
      }
      final (ix, cx, pred, _) = _linTenue(t, m, lnS, true);
      var constante = pred;
      for (var k = 0; k < ix.length; k++) {
        constante -= cx[k] * m[ix[k]];
      }
      final bA = clampD(m[ba], -2.5, 2.5);
      final bP = clampD(m[bp], -0.2, 1.0);
      final hh0 = clampD(m[hh], 0.03, 0.30);
      final plus =
          pw(bt / hh0, 2) / pw(1.0 + bP, 2) +
          pw(dbl(me['dispersion_fatigue_intra']) * sj / hh0, 2);
      double bruit(double u) {
        var r = u * (1.0 + bP) + bA;
        if (r < 0.0) {
          r = 0.0;
        }
        if (r > 8.0) {
          r = 8.0;
        }
        final sd = bruitRirDe(r, 6);
        return sd * sd + plus;
      }

      final fCible = dblOu(dictOuVide(s['target'])['flames']);
      final e = dbl(me['note_aberrante']);
      var par = 0.0;
      if (fCible != null && flammes == fCible) {
        par = clampD(paresse[0] / (paresse[0] + paresse[1]), 0.01, 0.9);
      }
      final melange = ((1.0 - e) * (1.0 - par), e * 0.1 + (1.0 - e) * par);
      double exacte(Float64List etat) => _linTenue(t, etat, lnS, true).$3;
      resid = _observer(
        ix,
        cx,
        constante,
        a,
        b,
        bruit(pred),
        melange: melange,
        bruit: bruit,
        fonction: exacte,
        figeAlt: _figeMauvaisJour(t, s),
      );
      _projeter();
      final r = _linTenue(t, m, lnS, false).$4;
      rirC = r > 0 ? r : 0.0;
    }
    final eff = effort(rirC, echec);
    t.seriesSeance.add((effortIntra(rirC), repos));
    _chargerCompartiments(t, eff, math.max(sec, 1) / 10.0);
    _stimulus(t, rirC, 0.0, sec > 0);
    t.mesures += 1;
    final role0 = s['role'];
    if (echec || vrai(s['repere']) || role0 == 'test' || role0 == 'attempt') {
      t.dernierTestJour = jour;
    }
    return resid;
  }

  Residu? _serieEndurance(Piste t, Json s) {
    final me = jm(p['mesure']);
    final demandeO = s['demand'];
    if (demandeO == null || dbl(demandeO) <= 0) {
      return null;
    }
    final demande = dbl(demandeO);
    final double? flammes = dblOu(s['flames']);
    final fait = dbl(s['doneShare'] ?? 1.0);
    final (idx, co) = hCapacite(t, jour: true);
    final lnD = math.log(demande);
    final pente = t.type == 'cardio'
        ? dbl(me['cardio_pente_rir'])
        : dbl(me['wod_pente_rir']);
    final neutre = t.type == 'cardio' ? dbl(me['cardio_charge_neutre']) : 1.0;
    final bruit = t.type == 'cardio'
        ? dbl(me['bruit_cardio'])
        : dbl(me['bruit_wod']);
    final double? cible = dblOu(dictOuVide(s['target'])['flames']);
    final rirCible = cible == null
        ? (t.type == 'cardio' ? 5.0 : 2.0)
        : (cible >= 10 ? 0.0 : (11 - cible) / 2.0);
    Residu? resid;
    if (fait < 0.999) {
      resid = _observer(
        idx,
        co,
        t.base - lnD,
        -inf,
        -math.log(1.3),
        pw(bruit, 2),
      );
    } else if (flammes != null) {
      double a;
      double b;
      if (flammes >= 10) {
        a = -inf;
        b = 0.25;
      } else {
        final bf = bornesFlammes(flammes, dbl(me['rir_ouvert']));
        a = bf.$1;
        b = bf.$2;
      }
      var eta = t.base;
      for (var k = 0; k < idx.length; k++) {
        eta += co[k] * m[idx[k]];
      }
      final rel = math.exp(lnD - eta);
      final pred = rirCible - pente * (rel - neutre);
      final cx = [for (final c in co) c * pente * rel];
      var constante = pred;
      for (var k = 0; k < idx.length; k++) {
        constante -= cx[k] * m[idx[k]];
      }
      resid = _observer(
        idx,
        cx,
        constante,
        a,
        b,
        pw(dbl(me['bruit_rir_endurance']), 2),
      );
    }
    final eff = flammes == null
        ? 0.6
        : effort(flammes < 10 ? (11 - flammes) / 2.0 : 0.0);
    _chargerCompartiments(
      t,
      eff * (vrai(s['fatigueSets']) ? dbl(s['fatigueSets']) : 1.0),
    );
    final dose = dbl(s['dose'] ?? 1.0);
    t.stimSemaine[0] += dose;
    t.stimSemaine[1] += dose;
    t.stimSemaine[2] += dose;
    t.mesures += 1;
    return resid;
  }

  /// Refus motivé « trop lourd » / « trop léger » : mesure faible.
  void observerRaison(
    String exId,
    Object? raison,
    Object? chargeKg,
    Object? reps,
    Object? rir,
  ) {
    final t = piste(exId);
    if (t == null ||
        t.type != 'charge' ||
        (raison != 'too_heavy' && raison != 'too_light')) {
      return;
    }
    final (l, k) = courbe(t);
    final ms = masse(t, dblOu(chargeKg));
    if (ms <= 0 || reps == null) {
      return;
    }
    final r = rir == null ? 0.0 : dbl(rir);
    final lnL = math.log(ms);
    final (idx, co) = hCapacite(t, jour: false);
    final constante = t.base - lnL - gK(l, k, dbl(reps) + r);
    final s2 = pw(dbl(jm(p['mesure'])['bruit_raison_refus']), 2);
    if (raison == 'too_heavy') {
      _observerHors(idx, co, constante, -inf, 0.0, s2);
    } else {
      _observerHors(idx, co, constante, 0.0, inf, s2);
    }
  }

  /// Charge modifiée à la main : mesure fiable.
  void observerChargeManuelle(
    String exId,
    Object? chargeKg,
    Object? reps,
    Object? rir,
  ) {
    final t = piste(exId);
    if (t == null || t.type != 'charge') {
      return;
    }
    final (l, k) = courbe(t);
    final ms = masse(t, dblOu(chargeKg));
    if (ms <= 0 || reps == null) {
      return;
    }
    final r = rir == null ? 0.0 : dbl(rir);
    final lnL = math.log(ms);
    final (idx, co) = hCapacite(t, jour: false);
    final constante = t.base - lnL - gK(l, k, dbl(reps) + r);
    _observerHors(
      idx,
      co,
      constante,
      null,
      null,
      pw(dbl(jm(p['mesure'])['bruit_charge_manuelle']), 2),
      point: 0.0,
    );
  }

  void _observerHors(
    List<int> idx,
    List<double> co,
    double constante,
    double? a,
    double? b,
    double s2, {
    double? point,
  }) {
    final lw = logw;
    final la = altLw;
    _observer(idx, co, constante, a, b, s2, point: point);
    logw = lw;
    altLw = la;
  }

  void changerCran(String exId, double facteur) {
    final t = piste(exId);
    if (t == null) {
      return;
    }
    final sd = dbl(jm(p['dynamique'])['changement_cran_elastique_sd']);
    for (final br in _branches()) {
      br.m[t.idx] += math.log(facteur);
      br.p[t.idx * br.cap + t.idx] += sd * sd;
    }
  }

  // ------------------------------------------------------------------
  // Fin de semaine : réponse à l'entraînement
  // ------------------------------------------------------------------
  double dose(List<double> stim, (double, int) hyp) {
    final (s0, k) = hyp;
    final ref = dbl(jm(p['dynamique'])['dose_reference']);
    final s = stim[k];
    if (s <= 0) {
      return 0.0;
    }
    return (1 - math.exp(-s / s0)) / (1 - math.exp(-ref / s0));
  }

  double doseMoyenne(List<double> stim) {
    var d = 0.0;
    for (var i = 0; i < poidsHyp.length && i < hypotheses.length; i++) {
      d += poidsHyp[i] * dose(stim, hypotheses[i]);
    }
    return d;
  }

  double recuperation(double fatigueLente) {
    final dyn = jm(p['dynamique']);
    final f0 = dbl(dyn['recuperation_seuil']);
    final k =
        1.0 -
        dbl(dyn['recuperation_pente']) *
            (fatigueLente > f0 ? fatigueLente - f0 : 0.0) /
            f0;
    final pl = dbl(dyn['recuperation_plancher']);
    return k > pl ? k : pl;
  }

  double accoutumance(num sem) =>
      1.0 / (1.0 + sem / dbl(jm(p['dynamique'])['accoutumance_semaines']));

  /// Lundi : progression des exercices travaillés, désentraînement, bruit.
  Json finSemaine() {
    final dyn = jm(p['dynamique']);
    final nn = n;
    final c = cap;
    final doses = <String, Object?>{};
    final mus = <String, Object?>{};
    final ligne = <String, Object?>{
      'semaine': semaines,
      'doses': doses,
      'mu': mus,
      'fatigue_lente': fG[1],
      'fatigue_rapide': fG[0],
    };
    final facteur = recuperation(fG[1]) * accoutumance(semaines);
    ligne['facteur'] = facteur;
    for (final exId in ordre) {
      final t = pistes[exId]!;
      final g = doseMoyenne(t.stimSemaine) * facteur;
      doses[exId] = List<double>.of(t.stimSemaine);
      if (g > 0) {
        final e = eps + t.classe!;
        for (var j = 0; j < nn; j++) {
          pm[t.idx * c + j] += g * (pm[rho * c + j] + pm[e * c + j]);
        }
        final col = Float64List(nn);
        for (var i = 0; i < nn; i++) {
          col[i] = g * (pm[i * c + rho] + pm[i * c + e]);
        }
        for (var i = 0; i < nn; i++) {
          pm[i * c + t.idx] += col[i];
        }
        m[t.idx] += g * (m[rho] + m[e]);
      } else {
        final inactif = jour - (t.dernierJour ?? jour);
        if (inactif > dbl(dyn['desentrainement_grace_j'])) {
          m[t.idx] -= dbl(dyn['desentrainement_par_semaine']);
          pm[t.idx * c + t.idx] += pw(
            0.5 * dbl(dyn['desentrainement_par_semaine']),
            2,
          );
        }
      }
      pm[t.idx * c + t.idx] += dbl(dyn['q_delta_semaine']);
      mus[exId] = t.base + mu(t);
      t.stimSemaine = [0.0, 0.0, 0.0];
    }
    for (var q = 0; q < nq; q++) {
      pm[(th + q) * c + th + q] += dbl(dyn['q_theta_semaine']);
    }
    pm[rho * c + rho] += dbl(dyn['q_reponse_semaine']);
    for (final z in zonesTendon) {
      fTendonAigu[z] = 0.0;
    }
    semaines += 1;
    journalSemaines.add(ligne);
    return ligne;
  }

  /// « Rien de spécial » : variance de toute capacité × [facteur].
  void elargir(double facteur) {
    final r = math.sqrt(facteur);
    final idx = [
      for (var q = 0; q < nq; q++) th + q,
      for (final e in ordre) pistes[e]!.idx,
    ];
    final c = cap;
    for (final i in idx) {
      for (var j = 0; j < c; j++) {
        pm[i * c + j] *= r;
      }
      for (var j = 0; j < c; j++) {
        pm[j * c + i] *= r;
      }
    }
    elargi += 1;
  }

  // ------------------------------------------------------------------
  // Lecture de l'a posteriori
  // ------------------------------------------------------------------
  (double, double)? capacite(String exId) {
    final t = piste(exId);
    if (t == null) {
      return null;
    }
    final (idx, co) = hCapacite(t, jour: false);
    final (mu0, v, _) = stats(m, pm, cap, idx, co);
    final me = jm(p['mesure']);
    final d = dbl(me['defaut_modele_sd'] ?? 0.0);
    return (t.base + mu0, math.sqrt((v > 0 ? v : 0.0) + d * d));
  }

  (double, double)? capaciteDuJour(String exId) {
    final t = piste(exId);
    if (t == null) {
      return null;
    }
    final (idx, co) = hCapacite(t);
    var (mu0, v, _) = stats(m, pm, cap, idx, co);
    if (_alt != null) {
      final w = poidsMauvaisJour();
      final (mu1, v1, _) = stats(_alt!.m, _alt!.p, _alt!.cap, idx, co);
      final mean = (1 - w) * mu0 + w * mu1;
      v = (1 - w) * (v + pw(mu0 - mean, 2)) + w * (v1 + pw(mu1 - mean, 2));
      mu0 = mean;
    }
    return (t.base + mu0, math.sqrt(v > 0 ? v : 0.0));
  }

  (double, double, double)? intervalle(String exId, [double niv = 0.90]) {
    final c = capacite(exId);
    if (c == null) {
      return null;
    }
    final z = niv == 0.90 ? 1.6448536269514722 : normPpfK(0.5 + 0.5 * niv);
    return (
      math.exp(c.$1 - z * c.$2),
      math.exp(c.$1),
      math.exp(c.$1 + z * c.$2),
    );
  }

  double? valeur(String exId) {
    piste(exId);
    final c = capacite(exId);
    if (c == null) {
      return null;
    }
    return math.exp(c.$1);
  }
}
