// KM3 (dev7.0.0, CAHIER_KM.md, DECISIONS_CP.md C13, C17.14) — Koach 1.0
// branché sur le magasin : un seul moteur, un seul comportement.
//
// - section `koachEngine` du document : journal de Koach (source de vérité
//   du moteur, rejoué à l'identique), instantanés hors journal, date
//   d'installation et de bascule, arrêt d'urgence, récapitulatifs de bloc ;
// - prise de main au début d'un bloc : programme créé dès le premier bloc
//   qui commence après l'installation ; programme de 40 semaines au début
//   du bloc de la bascule (23/11/2026 ou 04/01/2027), seulement si la
//   bascule est ouverte ([kKoachBasculeAutorisee] : version de Koach validée
//   et rejeu du journal réel passé, C17.13.3) ; avant, le bloc en cours
//   n'est pas coupé (INTEGRATION_KM3.md § 10, question 1 : le moteur de
//   dev6.19.0 le sert jusqu'à la bascule) ;
// - rattrapage du lundi (séances manquées, fin de semaine, replanification
//   hors du fil d'interface), séance du jour (`seance_debut`, diagnostic,
//   `plan(seance)`, `plan(serie)` une fois par série, `seance_fin`,
//   décisions) ;
// - arrêt d'urgence et réactivation, exports du mode dev.
//
// Aucune règle d'entraînement ici : charges, séries et raisons viennent de
// Koach ; la contrainte de charge fixe de CI1h (C15) s'applique au-dessus.
part of 'store.dart';

/// Bascule du programme de 40 semaines ouverte dans ce build : faux dans
/// dev7.0.0. La bascule exige la version de Koach validée la plus récente
/// (1.0.3, KM2c2) et le rejeu du journal réel sur un export neuf
/// (C17.13.3) : le lot qui monte le paquet après ces deux preuves passe
/// cette constante à vrai. La session de test du mode dev peut forcer la
/// bascule (`koachForcerBascule`).
const bool kKoachBasculeAutorisee = false;

/// Tests : bascule ouverte sans build dédié.
@visibleForTesting
bool debugKoachBasculeAutorisee = kKoachBasculeAutorisee;

/// Dernier jour d'installation qui garde la bascule du 23/11/2026
/// (cahier : APK installé au plus tard le 16/11/2026), et les deux dates.
final kKoachInstallLimite = kc.CivilDate(2026, 11, 16);
final kKoachBasculeVisee = kc.CivilDate(2026, 11, 23);
final kKoachBasculeRepli = kc.CivilDate(2027, 1, 4);

/// Suffixe de la clé du journal de l'application d'un vrai test inséré par
/// Koach avant l'exercice de travail (emplacement « <slot>.t »).
const kKoachTestSuffix = '#t';

/// Clé de la réponse au questionnaire hors modèle dans un événement
/// `decision` (contrat de Koach, § 2.4). Clé technique, jamais affichée :
/// écrite en deux morceaux pour le contrôle des allégations du texte
/// affiché (tools/check_claims.py).
const kKoachCleDiag = 'diag${'nostic'}';

/// Section `koachEngine` du document.
class KoachEngineData {
  /// Première ouverture d'une version avec Koach 1.0 (AAAA-MM-JJ).
  String? installedOn;

  /// Instantanés hors journal ; null : Koach n'a pas pris la main.
  KoachInstantane? snap;

  /// Journal de Koach (liste d'événements JSON).
  List<Map<String, Object?>> journal = [];

  /// Semaine S où Koach a pris la main ; jour de l'activation.
  int? fromWeek;
  String? activatedOn;

  /// Semaines globales g fermées (`semaine_fin` versé) : 0 .. closed − 1.
  int closed = 0;

  /// Séances de l'application versées au journal (clé `S<s>-J<j>`).
  final Set<String> versed = {};

  /// Arrêt d'urgence : {since (AAAA-MM-JJ), week (g), modules
  /// ({"dayIndex|slotId": [séries, écart]})}.
  Map<String, Object?>? stop;

  /// Récapitulatifs de fin de bloc : indice du bloc → `valide` / `refuse`.
  final Map<String, String> recaps = {};

  /// Disponibilités données au diagnostic (`duree_max_min`,
  /// `seances_par_semaine`).
  Map<String, Object?>? dispo;

  /// Séances manquées depuis la dernière séance (`contexte.manquees`).
  List<Map<String, Object?>> manquees = [];

  /// Mode dev (session de test) : date de bascule forcée.
  String? forced;

  /// Raison d'une activation refusée (`poids` : aucun poids connu).
  String? blocked;

  /// Empreinte des blocs de la dernière référence versée (une référence
  /// nouvelle est versée quand les blocs changent : bloc suivant écrit,
  /// retour au programme d'origine).
  String? refSig;

  bool get active => snap != null && stop == null;

  bool get pristine => snap == null && journal.isEmpty && forced == null;

  Map<String, Object?> toJson() => {
    'v': 1,
    if (installedOn != null) 'installedOn': installedOn,
    if (snap != null) 'snap': snap!.toJson(),
    if (journal.isNotEmpty) 'journal': journal,
    if (fromWeek != null) 'fromWeek': fromWeek,
    if (activatedOn != null) 'activatedOn': activatedOn,
    if (closed > 0) 'closed': closed,
    if (versed.isNotEmpty) 'versed': [...versed]..sort(),
    if (stop != null) 'stop': stop,
    if (recaps.isNotEmpty) 'recaps': recaps,
    if (dispo != null) 'dispo': dispo,
    if (manquees.isNotEmpty) 'manquees': manquees,
    if (forced != null) 'forced': forced,
    if (blocked != null) 'blocked': blocked,
    if (refSig != null) 'refSig': refSig,
  };

  /// Lecture tolérante (une section illisible donne un état neuf : le
  /// moteur 0.3.1 continue de servir, rien n'est perdu de l'historique de
  /// l'application). [issues] compte les champs écartés.
  static KoachEngineData fromJson(Object? raw, {List<String>? issues}) {
    final out = KoachEngineData();
    if (raw is! Map) return out;
    final m = raw.cast<String, Object?>();
    String? day(String k) {
      final v = m[k];
      return v is String && parseCivilDate(v) != null ? v : null;
    }

    out.installedOn = day('installedOn');
    out.activatedOn = day('activatedOn');
    out.forced = day('forced');
    try {
      if (m['snap'] != null) out.snap = KoachInstantane.fromJson(m['snap']);
    } on FormatException {
      issues?.add('snap');
    }
    if (out.snap != null) out.journal = koachJournalDe(m['journal']);
    final fw = m['fromWeek'];
    if (fw is int && fw >= 1 && fw <= 400) out.fromWeek = fw;
    final c = m['closed'];
    if (c is int && c >= 0 && c <= 400) out.closed = c;
    final v = m['versed'];
    if (v is List) out.versed.addAll(v.whereType<String>());
    final s = m['stop'];
    if (s is Map) out.stop = (koachCopie(s) as Map<String, Object?>);
    final r = m['recaps'];
    if (r is Map) {
      for (final e in r.entries) {
        if (e.value is String) out.recaps['${e.key}'] = e.value as String;
      }
    }
    final d = m['dispo'];
    if (d is Map) out.dispo = koachCopie(d) as Map<String, Object?>;
    final mq = m['manquees'];
    if (mq is List) {
      out.manquees = [
        for (final x in mq)
          if (x is Map) koachCopie(x) as Map<String, Object?>,
      ];
    }
    final b = m['blocked'];
    if (b is String && b.length < 40) out.blocked = b;
    final rs = m['refSig'];
    if (rs is String && rs.length < 40) out.refSig = rs;
    if (out.snap == null) {
      out.fromWeek = null;
      out.closed = 0;
      out.versed.clear();
      out.stop = null;
    }
    return out;
  }
}

/// Moteur vivant et ressources (jamais sauvegardés).
class KoachRuntime {
  KoachRessources? res;
  KoachFabrique? fab;
  ko.Koach? live;
  final temps = KoachTemps();

  /// Calcul en cours (rejeu, replanification) : la séance attend.
  Future<void>? busy;
  String? error;

  /// Dernier rejeu complet (ms) et nombre d'événements.
  ({int ms, int events})? lastReplay;

  /// Session de l'instance (les calculs d'une session de test ou d'un
  /// import n'écrivent pas dans une autre).
  int gen = 0;
}

/// Annonce de Koach à l'écran de séance après une série (null : rien).
class KoachSetNews {
  final String text;
  final bool stop;
  const KoachSetNews(this.text, {this.stop = false});
}

extension KoachStore on AppStore {
  kc.CivilDate get _kToday => civilOf(storeClock());

  // ------------------------------------------------------------ dates

  /// Lundi de la semaine S1 (jour 0 de Koach) ; null : programme non
  /// commencé.
  kc.CivilDate? get koachLundi {
    final s = program.start;
    if (s == null) return null;
    return koachLundiDe(civilOf(s));
  }

  /// Semaine S du programme contenant [d] (1 = S1).
  int? koachWeekOf(kc.CivilDate d) {
    final l = koachLundi;
    if (l == null) return null;
    final days = d.dayNumber - l.dayNumber;
    if (days < 0) return null;
    return days ~/ 7 + 1;
  }

  kc.CivilDate? _mondayOfWeek(int s) => koachLundi?.addDays(7 * (s - 1));

  /// Date de la bascule du programme de 40 semaines (cahier : 23/11/2026
  /// si l'APK est installé au plus tard le 16/11/2026, sinon 04/01/2027).
  kc.CivilDate get koachBasculeDate {
    final f = koachEngine.forced;
    if (f != null) return kc.CivilDate.parse(f);
    final inst = koachEngine.installedOn == null
        ? _kToday
        : kc.CivilDate.parse(koachEngine.installedOn!);
    return inst.compareTo(kKoachInstallLimite) <= 0
        ? kKoachBasculeVisee
        : kKoachBasculeRepli;
  }

  /// La bascule du programme de 40 semaines peut avoir lieu dans ce build
  /// (ou forcée dans la session de test).
  bool get koachBasculeOuverte =>
      debugKoachBasculeAutorisee || koachEngine.forced != null;

  static const _kInstall = 'km3_installation_v1';

  /// Note la première ouverture d'une version avec Koach 1.0 (date
  /// d'installation, qui fixe la date de bascule) : clé locale de la
  /// session, puis section `koachEngine` à la prise de main.
  void koachNoteInstall() {
    if (koachEngine.installedOn != null) return;
    final saved = _prefs.getString(_kInstall);
    if (saved != null && parseCivilDate(saved) != null) {
      koachEngine.installedOn = saved;
      return;
    }
    koachEngine.installedOn = _kToday.iso;
    unawaited(_prefs.setString(_kInstall, koachEngine.installedOn!));
  }

  /// Semaine S où Koach prend la main sur le programme en place (début de
  /// bloc), ou null : pas encore (ou jamais dans ce build).
  int? koachTakeoverWeek() {
    final lundi = koachLundi;
    if (lundi == null || content.catalog == null) return null;
    // Bascule fermée dans ce build (hors session de test forcée) : le
    // moteur de dev6.19.0 continue de servir tous les programmes.
    if (!koachBasculeOuverte) return null;
    final today = _kToday;
    final plan = planProgram;
    final starts = <int>[];
    kc.CivilDate from;
    if (plan != null) {
      for (var w = plan.firstWeek; w <= plan.totalWeeks; w++) {
        if (plan.locate(w)?.weekIndex == 0) starts.add(w);
      }
      final f = koachEngine.forced;
      from = f != null
          ? kc.CivilDate.parse(f)
          : (koachEngine.installedOn == null
                ? today
                : kc.CivilDate.parse(koachEngine.installedOn!));
    } else {
      final imp = importedProgram;
      if (imp == null) return null;
      for (final s in imp.segments) {
        starts.add(s.first);
      }
      from = koachBasculeDate;
    }
    // Session de test : prise de main forcée la semaine de la date choisie
    // (sans attendre un début de bloc).
    if (koachEngine.forced != null) {
      final w = koachWeekOf(from);
      if (w == null) return null;
      final last = plan?.totalWeeks ?? importedLastWeek;
      if (w > last) return null;
      return from.compareTo(today) <= 0 ? w : null;
    }
    final fromMonday = koachLundiDe(from);
    for (final s in starts..sort()) {
      final m = _mondayOfWeek(s)!;
      if (m.compareTo(fromMonday) < 0) continue;
      return m.compareTo(today) <= 0 ? s : null;
    }
    return null;
  }

  /// Koach sert la semaine S[week] (actif, pas d'arrêt d'urgence).
  bool koachServesWeek(int week) {
    final e = koachEngine;
    return e.active && e.fromWeek != null && week >= e.fromWeek!;
  }

  /// Arrêt d'urgence en cours sur une semaine que Koach conduisait : la
  /// séance est servie telle qu'écrite (ni Koach, ni le moteur d'avant).
  bool koachStoppedWeek(int week) {
    final e = koachEngine;
    return e.snap != null &&
        e.stop != null &&
        e.fromWeek != null &&
        week >= e.fromWeek!;
  }

  /// Koach sert la journée S[week]·J[j] du programme.
  bool koachServesDay(int week, int j) =>
      koachServesWeek(week) && adaptPlaceOf(week, j) != null;

  // ------------------------------------------------------- ressources

  Future<KoachRessources?> _koachRes() async {
    final rt = _koachRt;
    if (rt.res != null) return rt.res;
    try {
      final p = await rootBundle.loadString(kKoachParamsAsset);
      final f = await rootBundle.loadString(kKoachFichesAsset);
      rt.res = KoachRessources.lire(p, f);
    } catch (e) {
      rt.error = 'Ressources de Koach illisibles.';
    }
    return rt.res;
  }

  KoachFabrique? _koachFab() {
    final rt = _koachRt;
    final snap = koachEngine.snap;
    final res = rt.res;
    final cat = content.catalog;
    if (snap == null || res == null || cat == null) return null;
    if (rt.fab == null || !identical(rt.fab!.snap, snap)) {
      rt.fab = KoachFabrique(res, snap, cat);
    }
    return rt.fab;
  }

  /// Koach calcule (rejeu ou replanification en arrière-plan).
  bool get koachBusy => _koachRt.busy != null;

  /// Temps de calcul mesurés (inspecteur).
  KoachTemps get koachTemps => _koachRt.temps;

  /// Moteur vivant (lecture : inspecteur, exports, tests).
  ko.Koach? get koachLive => _koachRt.live;

  /// Dernier rejeu complet.
  ({int ms, int events})? get koachLastReplay => _koachRt.lastReplay;

  // --------------------------------------------------- mise en route

  /// À l'ouverture de l'application, à son retour au premier plan et
  /// avant une séance : ressources, prise de main éventuelle, moteur
  /// reconstruit, rattrapage des semaines finies. Une seule mise en route
  /// à la fois.
  Future<void> koachRefresh() {
    final running = _koachRt.busy;
    if (running != null) return running;
    final gen = _koachRt.gen;
    final f = _koachRefresh(gen).whenComplete(() {
      if (_koachRt.gen == gen) _koachRt.busy = null;
      notifyListeners();
    });
    _koachRt.busy = f;
    return f;
  }

  Future<void> _koachRefresh(int gen) async {
    koachNoteInstall();
    final e = koachEngine;
    if (e.snap == null) {
      final w = koachTakeoverWeek();
      if (w == null) return;
      final res = await _koachRes();
      if (res == null || gen != _koachRt.gen) return;
      await _koachActivate(w, gen);
      return;
    }
    final res = await _koachRes();
    if (res == null || gen != _koachRt.gen) return;
    if (e.stop != null) return;
    await _koachEnsureLive(gen);
    if (gen != _koachRt.gen) return;
    await _koachCatchUp(gen);
    if (gen != _koachRt.gen) return;
    if (koachEngine.refSig != _koachRefSig()) await koachNewReference();
  }

  /// Empreinte des blocs de référence en place.
  String _koachRefSig() {
    final r = _koachReferenceBlocks();
    return fnv1a32(
      jsonEncode([
        r.starts,
        r.horizon,
        [for (final b in r.blocks) b.toJson()],
      ]),
    ).toString();
  }

  /// Moteur vivant reconstruit depuis le journal (démarrage à froid).
  Future<void> _koachEnsureLive(int gen) async {
    final rt = _koachRt;
    if (rt.live != null) return;
    final fab = _koachFab();
    if (fab == null) return;
    final sw = Stopwatch()..start();
    final journal = koachJournalDe(koachEngine.journal);
    try {
      final k = await KoachCalcul.rejouer(fab, journal);
      if (gen != rt.gen) return;
      rt.live = k;
      // Le journal gardé est celui du moteur (même contenu).
      koachEngine.journal = k.journal;
      rt.lastReplay = (ms: sw.elapsedMilliseconds, events: journal.length);
      rt.temps.noter('rejeu', sw.elapsed);
    } catch (_) {
      rt.error = 'Rejeu du journal de Koach impossible.';
    }
  }

  /// Poids connu (profil ou pesée) : Koach en a besoin (sans poids, il
  /// prendrait 72 kg sans le dire, INTEGRATION_KM3.md § 8 point 10).
  double? get _koachPoids {
    final p = athlete?.profile.bodyWeightKg;
    if (p != null && p > 0) return p;
    final w = koach.weighIns.where((x) => x.kg > 0).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return w.isEmpty ? null : w.first.kg;
  }

  /// Dernière pesée au plus tard du jour [d] (null : aucune).
  double? _koachPeseeAu(kc.CivilDate d) {
    double? out;
    final w = [...koach.weighIns]..sort((a, b) => a.date.compareTo(b.date));
    for (final x in w) {
      if (x.date.compareTo(d.iso) <= 0 && x.kg > 0) out = x.kg;
    }
    return out;
  }

  /// Prise de main (INTEGRATION_KM3.md § 7.1) : sauvegarde d'origine,
  /// instantanés, historique déjà fait (sans `plan`), puis `reference` de
  /// la semaine de prise de main (une seule replanification).
  Future<bool> _koachActivate(int fromWeek, int gen) async {
    final res = _koachRt.res;
    final catalog = content.catalog;
    final lundi = koachLundi;
    final a = athlete;
    if (res == null || catalog == null || lundi == null || a == null) {
      return false;
    }
    if (_koachPoids == null) {
      if (koachEngine.blocked != 'poids') {
        koachEngine.blocked = 'poids';
        _persist();
      }
      return false;
    }
    koachEngine.blocked = null;
    captureProgramOrigin();
    final snap = _koachSnapshot(res, lundi, fromWeek);
    final fab = KoachFabrique(res, snap, catalog);
    final g0 = fromWeek - 1;
    final hist = _koachHistory(
      res,
      lundi,
      untilWeek: fromWeek,
      closeBefore: g0,
    );
    final journal = <Json>[...hist.events, _koachReferenceEvent(snap, g0)];
    final sw = Stopwatch()..start();
    ko.Koach k;
    try {
      k = await KoachCalcul.rejouer(fab, journal);
    } catch (_) {
      _koachRt.error = 'Prise de main de Koach impossible.';
      return false;
    }
    if (gen != _koachRt.gen) return false;
    _koachRt.temps.noter('prise_de_main', sw.elapsed);
    _koachRt
      ..fab = fab
      ..live = k
      ..lastReplay = (ms: sw.elapsedMilliseconds, events: journal.length);
    koachEngine
      ..snap = snap
      ..journal = k.journal
      ..fromWeek = fromWeek
      ..activatedOn = _kToday.iso
      ..closed = g0
      ..stop = null
      ..refSig = _koachRefSig();
    koachEngine.versed
      ..clear()
      ..addAll(hist.keys);
    _g9Cache.clear();
    _persist();
    await _koachCatchUp(gen);
    return true;
  }

  /// Instantané du profil de Koach (règles de `journal_app.profil_de` :
  /// niveau, sexe, poids, zones fragiles, valeurs déclarées initiales), du
  /// profil de validation, des mouvements principaux et des versions.
  KoachInstantane _koachSnapshot(
    KoachRessources res,
    kc.CivilDate lundi,
    int fromWeek,
  ) {
    final ap = athlete!.profile;
    final declares = _koachDeclares(res);
    return KoachInstantane(
      profil: koachProfil(
        athlete: ap,
        premierePesee: _koachPoids,
        declares: declares,
      ),
      athlete: ap.toJson().cast<String, Object?>(),
      lundi: lundi.iso,
      lifts: _koachLifts(res),
      versionMoteur: ko.koachVersion,
      versionParametres: res.versionParametres,
      shaParametres: ko.koachParametresSha256,
      shaFiches: ko.koachFichesSha256,
    );
  }

  /// Exercices de la base des lignes du programme importé de référence
  /// [ref] (catégories [cats] des annotations de `koach_program.json`).
  List<String> _koachIdsOfRef(String ref, Set<String> cats) {
    final ann = (_baseKoachJson['exercises'] as Map?) ?? const {};
    final out = <String>{};
    for (final w in program.weeks) {
      if (w.n < 1 || w.n > importedLastWeek) continue;
      for (final d in w.days) {
        for (final e in d.original.exercises) {
          final a = ann[e.id];
          final cat = a is Map ? a['cat'] : null;
          final r = (a is Map ? a['ref'] : null) ?? e.load.ref;
          if (!cats.contains(cat) || r != ref) continue;
          final id = e.catalogId ?? content.idFor(e.name);
          if (id != null) out.add(id);
        }
      }
    }
    return out.toList()..sort();
  }

  /// Valeurs déclarées initiales (`declares_initiaux` de `journal_app.py`).
  Map<String, List<Object?>> _koachDeclares(KoachRessources res) {
    final out = <String, List<Object?>>{};
    final plan = planProgram;
    if (plan != null) {
      // Programme créé : niveaux de mouvement connus du profil
      // (`_pkProfilKoach`).
      for (final lv in athlete?.profile.movementLevels ?? const []) {
        final j = lv.toJson();
        final lo = j['low'], hi = j['high'];
        if (j['known'] == true && lo is num && hi is num && lo > 0 && hi > 0) {
          out['${j['exerciseId']}'] = [j['measure'], math.sqrt(lo * hi)];
        }
      }
      return out;
    }
    final initial = <String, double>{};
    for (final h in koach.history) {
      if (h.source != 'initial' || initial.containsKey(h.ref)) continue;
      if (h.value > 0) initial[h.ref] = h.value;
    }
    final p = program.pilotage;
    final principaux = {for (final l in p.mainLifts) l.ref: l.unit};
    final maxima = {for (final m in p.repMax) m.ref};
    final acc = {for (final x in p.accessories) x.ref: x.refReps};
    final ann = (_baseKoachJson['exercises'] as Map?) ?? const {};
    const mesureDuType = {
      'charge': 'one_rm_kg',
      'reps': 'max_reps',
      'tenue': 'max_hold_seconds',
    };
    final keys = initial.keys.toList()..sort();
    for (final ref in keys) {
      final v = initial[ref]!;
      String mesure;
      Set<String> cats;
      if (principaux.containsKey(ref)) {
        if (!const {'kg de lest', 'kg barre', 'kg'}.contains(principaux[ref])) {
          continue;
        }
        mesure = 'one_rm_kg';
        cats = {'strength', 'test1rm'};
      } else if (maxima.contains(ref)) {
        mesure = 'max_reps';
        cats = {'endurance', 'enduranceTest'};
      } else if (acc.containsKey(ref)) {
        // Accessoire : charge de travail convertie en 1RM par la courbe de
        // population, à la réserve cible de la ligne (σ 0,12).
        for (final w in program.weeks) {
          if (w.n < 1 || w.n > importedLastWeek) continue;
          for (final d in w.days) {
            for (final e in d.original.exercises) {
              final a = ann[e.id];
              if (a is! Map || a['cat'] != 'accessory') continue;
              if ((a['ref'] ?? e.load.ref) != ref) continue;
              final id = e.catalogId ?? content.idFor(e.name);
              final fiche = id == null ? null : res.fiches[id];
              if (fiche == null || mesureDuType[fiche['type']] != 'one_rm_kg') {
                continue;
              }
              if (out.containsKey(id)) continue;
              final rt = a['rirTarget'];
              final rir = rt is num ? rt.toDouble() : 2.0;
              final reps = acc[ref]! + rir;
              final frac =
                  ((fiche['fraction'] as num?) ?? 0).toDouble() *
                  (_koachPoids ?? 0);
              final un =
                  (v + frac) * math.exp(koachCourbePopulation(reps)) - frac;
              if (un > 0) out[id!] = ['one_rm_kg', un, 0.12];
            }
          }
        }
        continue;
      } else {
        continue;
      }
      for (final id in _koachIdsOfRef(ref, cats)) {
        final fiche = res.fiches[id];
        if (fiche == null || mesureDuType[fiche['type']] != mesure) continue;
        if (out.containsKey(id)) continue;
        out[id] = [mesure, v];
      }
    }
    return out;
  }

  /// Blocs de référence de la planification et débuts de bloc (semaines
  /// globales) : blocs annotés d'origine du programme importé (sans la
  /// couche CI1c ni les propositions de 0.x), ou blocs validés du programme
  /// créé, passe 2 comprise.
  ({List<kc.ProgramBlock> blocks, List<int> starts, int horizon})
  _koachReferenceBlocks() {
    final plan = planProgram;
    if (plan != null) {
      return (
        blocks: [for (final b in plan.blocks) adjustedBlock(b)],
        starts: [
          for (var k = 0; k < plan.blocks.length; k++)
            plan.blockFirstWeek(k) - 1,
        ],
        horizon: plan.totalWeeks,
      );
    }
    final imp = importedProgram;
    if (imp == null) return (blocks: const [], starts: const [], horizon: 0);
    return (
      blocks: [for (final s in imp.segments) s.block],
      starts: [for (final s in imp.segments) s.first - 1],
      horizon: importedLastWeek,
    );
  }

  /// Mouvements principaux chargés (contrôle dual) : exercices des
  /// emplacements de rôle `main` dont la fiche est de type `charge`, triés.
  List<String> _koachLifts(KoachRessources res) {
    final ids = <String>{};
    for (final b in _koachReferenceBlocks().blocks) {
      for (final d in b.pass1.days) {
        for (final s in d.slots) {
          if (s.role == kc.SlotRole.main &&
              res.fiches[s.exerciseId]?['type'] == 'charge') {
            ids.add(s.exerciseId);
          }
        }
      }
    }
    return ids.toList()..sort();
  }

  /// Échéance (jour de Koach) : jour de test de la dernière semaine du
  /// programme importé, ou épreuve principale la plus proche du profil.
  int? _koachEcheance(kc.CivilDate lundi) {
    if (planProgram == null) {
      final last = math.min(importedLastWeek, program.weeks.length);
      if (last < 1 || program.start == null) return null;
      int? best;
      for (final d in program.week(last).days) {
        if (d.exercises.isEmpty) continue;
        final date = civilOf(program.dateFor(last, d.j));
        final j = koachJour(lundi, date);
        if (best == null || j > best) best = j;
      }
      return best;
    }
    int? best;
    for (final e in athlete?.profile.events ?? const <kc.SeasonEvent>[]) {
      if (e.priority != kc.EventPriority.main) continue;
      final j = koachJour(lundi, e.date);
      if (j < 0) continue;
      if (best == null || j < best) best = j;
    }
    return best;
  }

  /// Cibles {exercice : valeur visée, charge totale pour un exercice
  /// chargé} et cibles de tentative {exercice : charge externe}.
  ({Json cibles, Json tentatives}) _koachCibles(KoachRessources res) {
    final cibles = <String, Object?>{};
    final tent = <String, Object?>{};
    final bw = _koachPoids ?? 72.0;
    final plan = planProgram;
    if (plan != null) {
      for (final g in athlete?.profile.goals ?? const <kc.Goal>[]) {
        final j = g.toJson();
        final ex = j['exerciseId'] as String?;
        final v = j['targetValue'];
        if (ex == null || v is! num) continue;
        final fiche = res.fiches[ex];
        if (fiche == null) continue;
        final metric = j['metric'];
        if (metric == 'one_rm_kg' && fiche['type'] == 'charge') {
          cibles[ex] = v + ((fiche['fraction'] as num?) ?? 0) * bw;
          tent[ex] = v;
        } else if (metric == 'max_reps' && fiche['type'] == 'reps') {
          cibles[ex] = v.toDouble();
        } else if (metric == 'max_hold_seconds' && fiche['type'] == 'tenue') {
          cibles[ex] = v.toDouble();
        }
      }
      return (cibles: cibles, tentatives: tent);
    }
    final p = program.pilotage;
    for (final l in p.mainLifts) {
      final t = koach.objectives[l.ref]?['final']?.target ?? l.target;
      if (t <= 0) continue;
      for (final id in _koachIdsOfRef(l.ref, {'strength', 'test1rm'})) {
        final fiche = res.fiches[id];
        if (fiche == null || fiche['type'] != 'charge') continue;
        cibles[id] = t + ((fiche['fraction'] as num?) ?? 0) * bw;
        tent[id] = t;
      }
    }
    for (final r in p.repMax) {
      final t = koach.objectives[r.ref]?['final']?.target ?? r.target;
      if (t <= 0) continue;
      for (final id in _koachIdsOfRef(r.ref, {'endurance', 'enduranceTest'})) {
        final fiche = res.fiches[id];
        if (fiche == null || fiche['type'] != 'reps') continue;
        cibles[id] = t;
      }
    }
    return (cibles: cibles, tentatives: tent);
  }

  /// Événement `reference` (INTEGRATION_KM3.md § 2.6).
  Json _koachReferenceEvent(KoachInstantane snap, int g) {
    final res = _koachRt.res!;
    final ref = _koachReferenceBlocks();
    final principaux = <String>[];
    for (final b in ref.blocks) {
      for (final d in b.pass1.days) {
        for (final s in d.slots) {
          if (s.role == kc.SlotRole.main &&
              !principaux.contains(s.exerciseId)) {
            principaux.add(s.exerciseId);
          }
        }
      }
    }
    final c = _koachCibles(res);
    return {
      'type': 'reference',
      'blocs': [for (final b in ref.blocks) b.toJson()],
      'block_weeks': ref.starts,
      'horizon': ref.horizon,
      'cibles': c.cibles,
      'echeance_jour': _koachEcheance(snap.lundiDate),
      'principaux': principaux,
      'poids_corps': snap.profil['poids_kg'],
      'cibles_tentatives': c.tentatives,
      'semaine': g,
    };
  }

  /// Journée S[week]·J[j] pour le contexte de Koach : semaine globale,
  /// journée écrite du bloc, nature et intention de la semaine, items
  /// écrits, rôles des emplacements.
  KoachJourInfo? koachJourInfo(int week, int j) {
    final place = _koachPlace(week, j);
    if (place == null) return KoachJourInfo(semaine: week - 1);
    kc.WeekPrescription? wk;
    for (final w in place.block.pass2.weeks) {
      if (w.weekIndex == place.weekIndex) wk = w;
    }
    final roles = <String, Object?>{
      for (final d in place.block.pass1.days)
        for (final s in d.slots) s.slotId: s.role.code,
    };
    return KoachJourInfo(
      semaine: week - 1,
      jourIndex: place.dayIndex,
      genre: wk?.kind.code,
      intention: wk?.intent?.code,
      items: [
        for (final it in place.day?.items ?? const <kc.ExercisePrescription>[])
          it.toJson().cast<String, Object?>(),
      ],
      roles: roles,
    );
  }

  /// Place d'une journée sur les blocs de référence de Koach (blocs écrits,
  /// sans la couche de 0.x).
  AdaptPlace? _koachPlace(int week, int j) {
    final plan = planProgram;
    if (plan != null && week >= plan.firstWeek) {
      final loc = plan.locate(week);
      if (loc == null) return null;
      final block = adjustedBlock(plan.blocks[loc.block]);
      final startWeekday =
          program.start?.weekday ?? block.pass1.startDate.weekday;
      for (final d in block.pass1.days) {
        if (planJ(d.weekday, startWeekday) == j) {
          return AdaptPlace(block, loc.weekIndex, d.dayIndex, false);
        }
      }
      return null;
    }
    if (week > importedLastWeek) return null;
    final seg = importedProgram?.segmentOf(week);
    if (seg == null) return null;
    for (final d in seg.block.pass1.days) {
      if (_importedJ(d.weekday) == j) {
        return AdaptPlace(seg.block, week - seg.first, d.dayIndex, true);
      }
    }
    return null;
  }

  /// Séances faites de l'application, converties (journal des moteurs,
  /// règles C1 à C12 et CI1f), en ordre chronologique.
  List<({String key, int week, int j, Json session})> _koachDoneSessions() {
    final log = adaptTrainingLog(today: _kToday);
    final out = <({String key, int week, int j, Json session})>[];
    final re = RegExp(r'^legacy-S(\d+)-J(\d+)$');
    for (final s in log.sessions) {
      if (s.resume || !s.completed) continue;
      final m = re.firstMatch(s.id);
      if (m == null) continue;
      final w = int.parse(m[1]!), j = int.parse(m[2]!);
      out.add((
        key: sessionKey(w, j),
        week: w,
        j: j,
        session: s.toJson().cast<String, Object?>(),
      ));
    }
    return out;
  }

  /// Convertit une séance faite (sans `plan`).
  KoachSeanceConvertie? _koachConvert(
    KoachRessources res,
    kc.CivilDate lundi,
    ({String key, int week, int j, Json session}) s,
  ) {
    final date = kc.CivilDate.parse('${s.session['date']}');
    return koachSeanceDe(
      s.session,
      lundi: lundi,
      cle: s.key,
      semaineS: s.week,
      info: koachJourInfo(s.week, s.j),
      fiches: res.fiches,
      params: res.params,
      poidsKg: _koachPeseeAu(date),
      metaDe: (serie) => _koachMeta(s.week, s.j, serie),
    );
  }

  /// Catégorie, référence et type d'une série (export du journal moteur).
  Json _koachMeta(int week, int j, Json serie) {
    final ann = (_baseKoachJson['exercises'] as Map?) ?? const {};
    final ex = '${serie['exerciseId']}';
    final type = _koachRt.res?.fiches[ex]?['type'];
    String? cat, ref;
    if (week >= 1 && week <= program.weeks.length) {
      for (final e
          in program.week(week).day(j)?.original.exercises ??
              const <Exercise>[]) {
        final id = e.catalogId ?? content.idFor(e.name);
        if (id != ex) continue;
        final a = ann[e.id];
        if (a is Map) {
          cat = a['cat'] as String?;
          ref = (a['ref'] ?? e.load.ref) as String?;
        }
        break;
      }
    }
    return {'cat': cat, 'ref': ref, 'type': type};
  }

  /// Historique déjà fait (séances des semaines avant [untilWeek]),
  /// converti, avec un `semaine_fin` à chaque lundi passé, et les semaines
  /// avant [closeBefore] fermées.
  ({List<Json> events, Set<String> keys}) _koachHistory(
    KoachRessources res,
    kc.CivilDate lundi, {
    required int untilWeek,
    required int closeBefore,
  }) {
    final events = <Json>[];
    final keys = <String>{};
    var next = 0;
    for (final s in _koachDoneSessions()) {
      if (s.week >= untilWeek) continue;
      final c = _koachConvert(res, lundi, s);
      if (c == null) continue;
      while (7 * (next + 1) <= c.jour && next < closeBefore) {
        events.add(koachSemaineFin(next));
        next++;
      }
      events
        ..add(c.debut)
        ..addAll(c.series)
        ..add(c.fin);
      keys.add(s.key);
    }
    while (next < closeBefore) {
      events.add(koachSemaineFin(next));
      next++;
    }
    return (events: events, keys: keys);
  }

  // ------------------------------------------------------- rattrapage

  /// Semaines finies depuis le dernier passage (INTEGRATION_KM3.md § 2.2,
  /// point 1) : séances faites hors de Koach versées (sans `plan`),
  /// séances manquées, `semaine_fin` (replanification), proposition
  /// d'essai N-of-1 ; puis les séances faites de la semaine en cours.
  Future<void> _koachCatchUp(int gen) async {
    final rt = _koachRt;
    final k = rt.live;
    final res = rt.res;
    final lundi = koachLundi;
    final e = koachEngine;
    if (k == null || res == null || lundi == null || !e.active) return;
    final today = _kToday;
    final gNow = koachJour(lundi, today) ~/ 7;
    final done = _koachDoneSessions();
    final steps = <KoachEtape>[];
    final versedNow = <String>[];
    final manquees = <Json>[];
    final open = _koachOpenKey();
    void verseDone(bool Function(int jour) when) {
      for (final s in done) {
        if (e.versed.contains(s.key) || versedNow.contains(s.key)) continue;
        if (s.key == open) continue;
        final c = _koachConvert(res, lundi, s);
        if (c == null || !when(c.jour)) continue;
        steps
          ..add(KoachEtape.evenement(c.debut))
          ..addAll([for (final x in c.series) KoachEtape.evenement(x)])
          ..add(KoachEtape.evenement(c.fin));
        versedNow.add(s.key);
      }
    }

    for (var g = e.closed; g < gNow; g++) {
      verseDone((jour) => jour < 7 * (g + 1));
      // Journées prévues de g non faites, date passée.
      final week = g + 1;
      if (week >= 1 && week <= program.weeks.length) {
        for (final d in program.week(week).days) {
          if (d.exercises.isEmpty) continue;
          final key = sessionKey(week, d.j);
          final log = logs[key];
          if (log?.done ?? false) continue;
          if (e.versed.contains(key) || versedNow.contains(key)) continue;
          if (programResume?.keys.contains(key) ?? false) continue;
          if (program.start == null) continue;
          final date = civilOf(program.dateFor(week, d.j));
          if (date.compareTo(today) >= 0) continue;
          final jour = koachJour(lundi, date);
          steps.add(
            KoachEtape.evenement({
              'type': 'seance_manquee',
              'jour': jour,
              'semaine': g,
            }),
          );
          final info = koachJourInfo(week, d.j);
          if (info != null && info.items.isNotEmpty) {
            manquees.add({
              'semaine': g,
              'genre': info.genre,
              'items': [for (final it in info.items) koachItemVolume(it)],
            });
          }
        }
      }
      steps
        ..add(KoachEtape.evenement(koachSemaineFin(g)))
        ..add(KoachEtape.essai(g, _koachEcheances(lundi)));
    }
    verseDone((_) => true);
    if (steps.isEmpty) return;
    final sw = Stopwatch()..start();
    ko.Koach next;
    try {
      next = await KoachCalcul.appliquer(k, (x) => koachRattraper(x, steps));
    } catch (_) {
      // Instance d'avant gardée ; rejeu au prochain démarrage.
      rt.live = null;
      rt.error = 'Rattrapage de Koach impossible.';
      return;
    }
    if (gen != rt.gen) return;
    rt.temps.noter('replanification', sw.elapsed);
    rt.live = next;
    e
      ..journal = next.journal
      ..closed = math.max(e.closed, gNow)
      ..manquees = [...e.manquees, ...manquees];
    e.versed.addAll(versedNow);
    _persist();
  }

  /// Jours d'épreuve connus (contrôle dual).
  List<int> _koachEcheances(kc.CivilDate lundi) {
    final j = _koachEcheance(lundi);
    return j == null ? const [] : [j];
  }

  /// Séance commencée et non finie servie par Koach (clé), ou null.
  String? _koachOpenKey() {
    for (final e in logs.entries) {
      if (e.value.done) continue;
      final k = e.value.adapt?['koach'];
      if (k is Map && k['state'] == 'open') return e.key;
    }
    return null;
  }

  // ------------------------------------------------- séance du jour

  /// Séance non commencée d'une journée servie par Koach : la journée
  /// écrite, avec les séries de la semaine modulée (prévision, sans
  /// appel au moteur) et la charge fixe. Koach la prescrit au début réel
  /// de la séance ([koachStart]).
  SessionAdapt? koachPreview(int week, DayPlan base, {SessionAdapt? keep}) {
    final place = _koachPlace(week, base.j);
    final day = place?.day;
    if (place == null || day == null) return null;
    final modules = _koachModules(week - 1);
    final items = <kc.ExercisePrescription>[];
    for (final it in day.items) {
      final m = modules?['${place.dayIndex}|${it.slotId}'];
      var next = it;
      if (m != null && m.$1 != it.sets && m.$1 >= 0) {
        if (m.$1 == 0) continue;
        next = it.copyWith(sets: m.$1, setTargets: null);
      }
      items.add(next);
    }
    final plan = kc.SessionPlan(
      date: _kToday,
      blockId: place.blockId,
      weekIndex: place.weekIndex,
      dayIndex: place.dayIndex,
      items: items,
      adjustments: const [],
      confidence: 1,
      reasons: const [],
      groups: day.groups,
    );
    final fixed = _fixedConstrain(place, plan);
    return SessionAdapt(
      blockId: place.blockId,
      weekIndex: place.weekIndex,
      dayIndex: place.dayIndex,
      date: _kToday.iso,
      mode: 'assisted',
      asked: keep?.asked ?? false,
      check: keep?.check,
      place: keep?.place,
      plan: fixed.validate().isEmpty ? fixed : plan,
      koach: const {'state': 'preview'},
    );
  }

  /// Séries de la semaine modulée par la planification ({"dayIndex|slot":
  /// (séries, écart d'intensité)}) : lecture pure ; en arrêt d'urgence,
  /// celles gardées à l'arrêt.
  Map<String, (int, double)>? _koachModules(int g) {
    final stop = koachEngine.stop;
    if (stop != null) {
      if (stop['week'] != g) return null;
      final m = stop['modules'];
      if (m is! Map) return null;
      return {
        for (final e in m.entries)
          if (e.value is List && (e.value as List).length == 2)
            '${e.key}': (
              ((e.value as List)[0] as num).toInt(),
              ((e.value as List)[1] as num).toDouble(),
            ),
      };
    }
    final pl = _koachRt.live?.planification;
    if (pl == null) return null;
    try {
      return {
        for (final e in pl.itemsModules(g).entries)
          '${e.key.$1}|${e.key.$2}': e.value,
      };
    } catch (_) {
      return null;
    }
  }

  /// Modulation de la semaine affichée (MON PROGRAMME, accueil) : séries
  /// servies et écart d'intensité d'une ligne écrite, null : inchangée.
  ({int sets, int written, double intensity})? koachWeekLine(
    int week,
    int j,
    String slot,
  ) {
    if (!koachServesWeek(week) && !koachStoppedWeek(week)) return null;
    final place = _koachPlace(week, j);
    if (place == null) return null;
    final m = _koachModules(week - 1)?['${place.dayIndex}|$slot'];
    if (m == null) return null;
    kc.ExercisePrescription? it;
    for (final x in place.day?.items ?? const <kc.ExercisePrescription>[]) {
      if (x.slotId == slot) it = x;
    }
    if (it == null) return null;
    if (m.$1 == it.sets && m.$2.abs() < 0.005) return null;
    return (sets: m.$1, written: it.sets, intensity: m.$2);
  }

  /// La séance de S[week]·J[j] attend son début réel (bilan réglé ou
  /// première série).
  bool koachPending(int week, int j) {
    final k = logs[sessionKey(week, j)]?.adapt?['koach'];
    return k is Map && k['state'] == 'preview';
  }

  /// Séance servie par Koach (commencée).
  bool koachOpen(int week, int j) {
    final k = logs[sessionKey(week, j)]?.adapt?['koach'];
    return k is Map && (k['state'] == 'open' || k['state'] == 'closed');
  }

  /// Alerte hors modèle levée : le diagnostic se pose avant la séance.
  bool get koachNeedsDiagnostic {
    final sv = _koachRt.live?.surveillance;
    return sv != null && sv.etat()['hors_modele'] == true;
  }

  /// Causes de l'alerte hors modèle (codes).
  List<String> get koachAlertCauses {
    final sv = _koachRt.live?.surveillance;
    if (sv == null) return const [];
    return [...sv.causes()];
  }

  /// Questions du diagnostic pour les réponses [reponses] (3 au plus).
  List<Json> koachQuestions(Json reponses) =>
      _koachRt.live?.surveillance?.questions(reponses) ?? const [];

  /// Début réel de la séance S[week]·J[j] (INTEGRATION_KM3.md § 2.2, points
  /// 2 à 5) : `seance_debut` (bilan, pesée, contexte), réponse au
  /// diagnostic, `plan(seance)` sur les items écrits. Faux : pas servie
  /// par Koach (la séance reste celle de l'aperçu).
  Future<bool> koachStart(int week, DayPlan base, {Json? diagnostic}) async {
    if (!koachPending(week, base.j)) return false;
    await koachRefresh();
    return koachStartNow(week, base, diagnostic: diagnostic);
  }

  /// [koachStart] sans attendre : le moteur doit être prêt.
  bool koachStartNow(int week, DayPlan base, {Json? diagnostic}) {
    final key = sessionKey(week, base.j);
    final a = sessionAdaptOf(key);
    final k = _koachRt.live;
    final lundi = koachLundi;
    final place = _koachPlace(week, base.j);
    final book = _adaptBook();
    if (a == null ||
        k == null ||
        lundi == null ||
        place == null ||
        book == null ||
        !koachPending(week, base.j) ||
        !koachServesWeek(week)) {
      return false;
    }
    final info = koachJourInfo(week, base.j)!;
    final today = _kToday;
    final jour = koachJour(lundi, today);
    final check = a.check?.toJson().cast<String, Object?>();
    final inputs = _koachSeanceInputs(
      week,
      base.j,
      info,
      book,
      check: check,
      place: a.place,
      minutes: a.check?.minutesAvailable,
    );
    final contexte = inputs.contexte;
    final grilles = inputs.grilles;
    final zones = inputs.zones;
    final sw = Stopwatch()..start();
    Json r;
    try {
      k.observe({
        'type': 'seance_debut',
        'jour': jour,
        'bilan': check == null || check.isEmpty ? null : check,
        'poids_kg': _koachPeseeAu(today),
        'contexte': contexte,
      });
      if (diagnostic != null && koachNeedsDiagnostic) {
        k.observe({'type': 'decision', 'jour': jour, kKoachCleDiag: diagnostic});
      }
      r =
          k.plan({
                'horizon': 'seance',
                'items': info.items,
                'grilles': grilles,
                'zones': zones,
                'roles': info.roles,
              })!
              as Json;
    } catch (_) {
      // État du moteur partiel : rejeu au prochain passage.
      _koachRt.live = null;
      _koachRt.error = 'Séance de Koach impossible : séance écrite servie.';
      return false;
    }
    _koachRt.temps.noter('plan_seance', sw.elapsed);
    koachEngine.manquees = [];
    // Capacités avant la séance (résumé de fin).
    final post = (k.posterior()['exercices'] as Map?) ?? const {};
    final avant = <String, Object?>{
      for (final it in info.items)
        if (post['${it['exerciseId']}'] != null)
          '${it['exerciseId']}': koachCopie(post['${it['exerciseId']}']),
    };
    final served = [
      for (final it in (r['items'] as List? ?? const []))
        if (it is Map) koachCopie(it) as Json,
    ];
    final items = <kc.ExercisePrescription>[];
    for (final it in served) {
      final p = _koachItemOf(it, info);
      if (p != null) items.add(p);
    }
    var plan = kc.SessionPlan(
      date: today,
      blockId: place.blockId,
      weekIndex: place.weekIndex,
      dayIndex: place.dayIndex,
      items: items,
      adjustments: const [],
      confidence: 1,
      reasons: const [],
      groups: place.day?.groups,
    );
    if (plan.validate().isNotEmpty) {
      plan = plan.copyWith(groups: null);
    }
    final next = SessionAdapt(
      blockId: place.blockId,
      weekIndex: place.weekIndex,
      dayIndex: place.dayIndex,
      date: today.iso,
      mode: 'assisted',
      asked: true,
      check: a.check,
      place: a.place,
      plan: plan.validate().isEmpty ? plan : a.plan,
      koach: {
        'state': 'open',
        'jour': jour,
        'semaine': week - 1,
        'items': served,
        'raisons': k.explain(),
        'cibles': <String, Object?>{},
        'versed': <Object?>[],
        if (check != null) 'debut': check,
        if (diagnostic != null) 'diag': diagnostic,
        'avant': avant,
      },
    );
    final log = sessionLog(week, base.j);
    log.adapt = next.toJson().cast<String, dynamic>();
    for (final x in log.ex.values) {
      for (final s in x.sets) {
        if (s.done || s.edited) continue;
        s.kg = '';
        s.reps = '';
      }
    }
    _adaptResync(week, base, a, next, log, key);
    koachEngine.journal = k.journal;
    saveLogs();
    _persist();
    return true;
  }

  /// Item servi par Koach au format du contrat de l'application : champs
  /// `koach*` retirés, nombres entiers ramenés à l'entier ; à défaut,
  /// l'item écrit avec les séries servies. Null : item illisible.
  kc.ExercisePrescription? _koachItemOf(Json it, KoachJourInfo info) {
    const ints = {
      'sets',
      'repsLow',
      'repsHigh',
      'secondsLow',
      'secondsHigh',
      'targetFlames',
      'restSeconds',
    };
    Json clean({required bool test}) => <String, Object?>{
      for (final e in it.entries)
        if (!e.key.startsWith('koach') && (test || e.key != 'test'))
          e.key: ints.contains(e.key) && e.value is num
              ? (e.value as num).round()
              : e.value,
    }..['reasons'] = const <Object?>[];
    for (final test in const [true, false]) {
      try {
        final p = kc.ExercisePrescription.fromJson(clean(test: test));
        final q = p.copyWith(setTargets: null);
        if (q.validate().isEmpty) return q;
      } catch (_) {}
    }
    for (final w in info.items) {
      if (w['slotId'] != it['slotId']) continue;
      try {
        final p = kc.ExercisePrescription.fromJson(w);
        final n = (it['sets'] as num?)?.round() ?? p.sets;
        return p.copyWith(sets: n < 1 ? 1 : n, setTargets: null);
      } catch (_) {}
    }
    return null;
  }

  /// Contexte, grilles et zones d'une séance de la journée S[week]·J[j]
  /// (INTEGRATION_KM3.md § 2.4, § 1.4).
  ({Json contexte, Json grilles, Json zones}) _koachSeanceInputs(
    int week,
    int j,
    KoachJourInfo info,
    ka.ExerciseBook book, {
    Json? check,
    kc.Place? place,
    int? minutes,
  }) {
    final today = _kToday;
    final reste = <Object?>[];
    final w = program.weeks.any((x) => x.n == week) ? program.week(week) : null;
    for (final d in w?.days ?? const <DayPlan>[]) {
      if (d.j <= j || d.exercises.isEmpty) continue;
      final i = koachJourInfo(week, d.j);
      if (i == null || i.items.isEmpty) continue;
      reste.add([for (final it in i.items) koachItemVolume(it)]);
    }
    final budget =
        minutes ?? (koachEngine.dispo?['duree_max_min'] as num?)?.toInt();
    final contexte = <String, Object?>{
      ...koachContexteDe(info),
      'jour_evenement': _koachEventDay(today),
      'budget': budget,
      'lieu': place?.code,
      'manquees': koachEngine.manquees,
      'reste_semaine': reste,
    };
    final grilles = <String, Object?>{};
    final zones = <String, Object?>{};
    for (final it in info.items) {
      final id = '${it['exerciseId']}';
      final x = book.find(id);
      if (x == null) continue;
      grilles[id] = {
        'pas': x.grid.step,
        'minimum': x.grid.minimum,
        'halteres': x.grid.dumbbellRule,
      };
      zones[id] = [
        {for (final z in kc.BodyZone.values) z.code: x.zoneLevel(z)},
        [
          for (final z in kc.BodyZone.values)
            if (kp.coachPainStopHits(x.exercise, z)) z.code,
        ],
      ];
    }
    return (contexte: contexte, grilles: grilles, zones: zones);
  }

  /// Prévision de la prochaine fois (C15.4) des exercices faits dans la
  /// séance S[week]·J[j] : prochaine journée (6 semaines au plus) où
  /// l'exercice revient, pas encore commencée ; même calcul que la séance
  /// (copie du moteur, jour réel, charge fixe). Gardée dans la séance.
  Future<void> _koachForecasts(int week, int j) async {
    final k = _koachRt.live;
    final fab = _koachFab();
    final lundi = koachLundi;
    final book = _adaptBook();
    final key = sessionKey(week, j);
    final a = sessionAdaptOf(key);
    if (k == null ||
        fab == null ||
        lundi == null ||
        book == null ||
        a == null) {
      return;
    }
    final gen = _koachRt.gen;
    final base = program.week(week).day(j);
    if (base == null) return;
    final ids = <String>{
      for (final r in _adaptDone(week, _koachDisplayDay(week, base, a), a))
        r.exerciseId,
    };
    final byDay = <(int, int), List<(String, String)>>{};
    for (final id in ids) {
      found:
      for (var n = week; n <= math.min(week + 6, program.weeks.length); n++) {
        if (!koachServesWeek(n)) continue;
        for (final d in program.week(n).days) {
          if (n == week && d.j <= j) continue;
          if (d.exercises.isEmpty) continue;
          final l = logs[sessionKey(n, d.j)];
          if (l != null &&
              (l.done || l.ex.values.any((x) => x.sets.any((s) => s.done)))) {
            continue;
          }
          final info = koachJourInfo(n, d.j);
          for (final it in info?.items ?? const <Json>[]) {
            if (it['exerciseId'] == id) {
              byDay.putIfAbsent((n, d.j), () => []).add((
                id,
                '${it['slotId']}',
              ));
              break found;
            }
          }
        }
      }
    }
    final out = <String, Object?>{};
    for (final e in byDay.entries) {
      final (n, d) = e.key;
      final info = koachJourInfo(n, d)!;
      final inputs = _koachSeanceInputs(n, d, info, book);
      final p = KoachPrevision(
        {
          'type': 'seance_debut',
          'jour': koachJour(lundi, _kToday),
          'bilan': null,
          'poids_kg': _koachPeseeAu(_kToday),
          'contexte': inputs.contexte,
        },
        {
          'horizon': 'seance',
          'items': info.items,
          'grilles': inputs.grilles,
          'zones': inputs.zones,
          'roles': info.roles,
        },
        [for (final x in e.value) x.$2],
      );
      Map<String, Json?> r;
      try {
        final sw = Stopwatch()..start();
        r = await koachPrevoirCopie(k, fab, p);
        _koachRt.temps.noter('prevision', sw.elapsed);
      } catch (_) {
        continue;
      }
      final place = _koachPlace(n, d);
      for (final (id, slot) in e.value) {
        var c = r[slot];
        if (c == null) continue;
        kc.ExercisePrescription? it;
        for (final x
            in place?.day?.items ?? const <kc.ExercisePrescription>[]) {
          if (x.slotId == slot) it = x;
        }
        final kg = place == null || it == null || debugDisableFixedLoad
            ? null
            : _fixedLoadAt(place, slot, it.exerciseId);
        if (kg != null && it != null) c = _koachFixed(c, kg, it, place!, k);
        out[id] = {'week': n, 'j': d, 'cible': c};
      }
    }
    if (gen != _koachRt.gen || out.isEmpty) return;
    final now = sessionAdaptOf(key);
    if (now == null || now.koach == null) return;
    final st = Map<String, Object?>.of(now.koach!)..['prevision'] = out;
    sessionLog(week, j).adapt = now
        .copyWith(koach: st)
        .toJson()
        .cast<String, dynamic>();
    saveLogs(affectsProgression: false);
    notifyListeners();
  }

  /// Jour d'épreuve (événement principal du profil, jour de test de
  /// l'échéance du programme).
  bool _koachEventDay(kc.CivilDate d) {
    for (final e in athlete?.profile.events ?? const <kc.SeasonEvent>[]) {
      if (e.date == d) return true;
    }
    final lundi = koachLundi;
    final ech = lundi == null ? null : _koachEcheance(lundi);
    return lundi != null && ech != null && koachJour(lundi, d) == ech;
  }

  Map<String, Object?>? _koachState(SessionAdapt a) => a.koach;

  /// Item servi par Koach de l'emplacement [slot].
  Json? _koachServed(SessionAdapt a, String slot) {
    final items = _koachState(a)?['items'];
    if (items is! List) return null;
    for (final it in items) {
      if (it is Map && it['slotId'] == slot) return it.cast<String, Object?>();
    }
    return null;
  }

  /// Séries faites de la séance servie, pas encore versées, versées dans
  /// l'ordre de réalisation (§ 2.2 point 6). Rend l'état mis à jour.
  Map<String, Object?> _koachVerse(
    int week,
    DayPlan day,
    SessionAdapt a,
    ko.Koach k,
  ) {
    final st = Map<String, Object?>.of(a.koach ?? const {});
    final versed = [...(st['versed'] as List? ?? const [])];
    final sigs = {
      for (final v in versed)
        if (v is List && v.length >= 3) '${v[0]}|${v[1]}',
    };
    final done = _adaptDone(week, _koachDisplayDay(week, day, a), a);
    final cibles = (st['cibles'] as Map?) ?? const {};
    for (final rec in done) {
      final slot = rec.slotId;
      if (slot == null) continue;
      final id = '$slot|${rec.setIndex}';
      if (sigs.contains(id)) continue;
      final cible = (cibles[slot] as Map?)?['${rec.setIndex}'];
      final s = koachSerie(
        rec.toJson().cast<String, Object?>(),
        cible: cible is Map ? cible.cast<String, Object?>() : null,
      );
      if (s == null) {
        sigs.add(id);
        versed.add([slot, rec.setIndex, '-']);
        continue;
      }
      // Note préremplie affichée = flammes visées de la cible.
      final t = (s['target'] as Map?)?.cast<String, Object?>() ?? {};
      if (cible is Map && cible['flames'] != null) {
        t['flames'] = cible['flames'];
      }
      s['target'] = t;
      final sw = Stopwatch()..start();
      k.observe({'type': 'serie', 'serie': s});
      _koachRt.temps.noter('observe_serie', sw.elapsed);
      sigs.add(id);
      versed.add([slot, rec.setIndex, _koachSig(s), k.journal.length - 1]);
    }
    st['versed'] = versed;
    return st;
  }

  static String _koachSig(Json s) =>
      '${s['reps']}|${s['seconds']}|${s['externalLoadKg']}|${s['flames']}';

  /// Journée affichée de la séance servie (exercices servis, tests de
  /// Koach compris).
  DayPlan _koachDisplayDay(int week, DayPlan base, SessionAdapt a) =>
      adaptDay(week, base, a);

  /// Cible de Koach de la série [index] de [e] : demandée une fois
  /// (`plan(serie)`), juste avant de la proposer, après avoir versé les
  /// séries déjà faites ; gardée ensuite. La contrainte de charge fixe
  /// (C15) s'applique au-dessus. Rien si la série n'est pas la prochaine
  /// à faire de l'exercice.
  void koachEnsureTarget(int week, DayPlan base, Exercise e, int index) {
    final key = sessionKey(week, base.j);
    final a = sessionAdaptOf(key);
    final slot = e.slotId;
    if (a == null || slot == null || !koachOpen(week, base.j)) return;
    final st0 = a.koach!;
    if (st0['state'] != 'open') return;
    final cibles = (st0['cibles'] as Map?) ?? const {};
    final mine = cibles[slot];
    if (mine is Map && mine.containsKey('$index')) return;
    if (mine is Map && mine['stop'] == true) return;
    final log = logs[key]?.ex[e.id];
    if (log == null || index >= log.sets.length) return;
    for (var i = 0; i < index; i++) {
      if (!log.sets[i].done) return;
    }
    if (log.sets[index].done) return;
    final k = _koachRt.live;
    final served = _koachServed(a, slot);
    if (k == null || served == null) return;
    Json? cible;
    Map<String, Object?> st;
    try {
      st = _koachVerse(week, base, a, k);
      final sw = Stopwatch()..start();
      final out = k.plan({'horizon': 'serie', 'item': served, 'index': index});
      _koachRt.temps.noter('plan_serie', sw.elapsed);
      cible = out is Map ? out.cast<String, Object?>() : null;
    } catch (_) {
      _koachRt.live = null;
      return;
    }
    // Charge fixe (C15.2, INTEGRATION_KM3.md § 7.3).
    final place = _koachPlace(week, base.j);
    final it0 = _adaptItem(a, slot);
    if (cible != null &&
        place != null &&
        it0 != null &&
        !debugDisableFixedLoad) {
      final kg = _fixedLoadAt(place, slot, it0.exerciseId);
      if (kg != null) cible = _koachFixed(cible, kg, it0, place, k);
    }
    final raisons = k.explain();
    final nextCibles = Map<String, Object?>.of(
      (st['cibles'] as Map?)?.cast<String, Object?>() ?? {},
    );
    final m = Map<String, Object?>.of(
      (nextCibles[slot] as Map?)?.cast<String, Object?>() ?? {},
    );
    if (cible == null) {
      m['stop'] = true;
      m['stopAt'] = index;
    } else {
      m['$index'] = cible;
    }
    nextCibles[slot] = m;
    st['cibles'] = nextCibles;
    st['raisons'] = raisons;
    // Séance affichée : cibles par série de l'item (les suivantes au
    // niveau de la dernière cible, en attendant la leur).
    final items = <kc.ExercisePrescription>[];
    for (final it in a.plan.items) {
      if (it.slotId != slot) {
        items.add(it);
        continue;
      }
      if (cible == null) {
        // Arrêter l'exercice : plus de séries proposées.
        items.add(
          it.copyWith(
            sets: math.max(1, index),
            setTargets: _koachTargets(it, m, index),
          ),
        );
        continue;
      }
      items.add(it.copyWith(setTargets: _koachTargets(it, m, it.sets)));
    }
    final next = a.copyWith(
      plan: a.plan.copyWith(items: items),
      koach: st,
    );
    final log2 = sessionLog(week, base.j);
    log2.adapt = next.toJson().cast<String, dynamic>();
    _adaptResync(week, base, a, next, log2, key);
    koachEngine.journal = k.journal;
    _adaptQuietSave();
  }

  /// Cibles par série d'un item depuis les cibles de Koach [m] (rang →
  /// cible), [n] séries.
  List<kc.SetTarget> _koachTargets(
    kc.ExercisePrescription it,
    Map<String, Object?> m,
    int n,
  ) {
    final out = <kc.SetTarget>[];
    Map? last;
    for (var i = 0; i < math.max(1, n); i++) {
      final c = m['$i'];
      if (c is Map) last = c;
      final t = last;
      out.add(
        kc.SetTarget(
          repsLow: t?['repsLow'] as int? ?? it.repsLow,
          repsHigh: t?['repsHigh'] as int? ?? it.repsHigh,
          secondsLow: t?['secondsLow'] as int? ?? it.secondsLow,
          secondsHigh: t?['secondsHigh'] as int? ?? it.secondsHigh,
          loadKg:
              (t?['loadKg'] as num?)?.toDouble() ??
              (t == null ? it.startLoadKg : null),
          flames: t?['flames'] as int? ?? it.targetFlames,
          role: t?['role'] == null
              ? null
              : kc.SetRole.values
                    .where((r) => r.code == t!['role'])
                    .firstOrNull,
        ),
      );
    }
    return out;
  }

  /// Charge fixe au-dessus de la cible de Koach (C15.2) : charge écrite,
  /// plage plafonnée au haut de la ligne écrite ; la cible de Koach est
  /// gardée quand elle est plus basse sous douleur (zone sollicitée
  /// active, ou raison de douleur, de reprise ou de poignet sur
  /// l'exercice).
  Json _koachFixed(
    Json cible,
    double kg,
    kc.ExercisePrescription it,
    AdaptPlace place,
    ko.Koach k,
  ) {
    final load = (cible['loadKg'] as num?)?.toDouble();
    var pain = false;
    for (final r in k.explain()) {
      final code = '${r['code']}';
      final ex = (r['params'] as Map?)?['exercice'];
      if (ex != null && ex != it.exerciseId) continue;
      if (code.startsWith('koach.douleur') ||
          code == 'koach.reprise_dose' ||
          code.startsWith('koach.poignet')) {
        pain = true;
      }
    }
    final zones = (_koachServedZones(it.exerciseId));
    final actives = k.garde.actives();
    if (zones.any(actives.containsKey)) pain = true;
    if (pain && load != null && load < kg) return cible;
    final out = Map<String, Object?>.of(cible);
    out['loadKg'] = kg;
    kc.ExercisePrescription? written;
    for (final x in place.day?.items ?? const <kc.ExercisePrescription>[]) {
      if (x.slotId == it.slotId) written = x;
    }
    final hi = written?.repsHigh;
    if (hi != null) {
      final rh = (out['repsHigh'] as int?) ?? hi;
      final rl = (out['repsLow'] as int?) ?? rh;
      out['repsHigh'] = math.min(rh, hi);
      out['repsLow'] = math.min(rl, math.min(rh, hi));
    }
    out['fixe'] = true;
    return out;
  }

  /// Zones provoquées par un exercice (règle d'arrêt sur douleur).
  List<String> _koachServedZones(String exerciseId) {
    final x = _adaptBook()?.find(exerciseId);
    if (x == null) return const [];
    return [
      for (final z in kc.BodyZone.values)
        if (kp.coachPainStopHits(x.exercise, z)) z.code,
    ];
  }

  /// Après la série [index] de [e] validée : cible de la série suivante
  /// (demandée tout de suite), et ce que Koach en dit (null : rien de
  /// neuf).
  KoachSetNews? koachAfterSet(int week, DayPlan day, Exercise e, int index) {
    if (!koachOpen(week, day.j)) return null;
    final key = sessionKey(week, day.j);
    final before = sessionAdaptOf(key);
    final log = logs[key]?.ex[e.id];
    if (before == null || log == null || e.slotId == null) return null;
    var next = -1;
    for (var i = 0; i < log.sets.length; i++) {
      if (!log.sets[i].done) {
        next = i;
        break;
      }
    }
    if (next < 0) {
      // Exercice fini : séries versées (le moteur en tient compte pour la
      // suite de la séance).
      final k = _koachRt.live;
      if (k != null) {
        try {
          final st = _koachVerse(week, day, before, k);
          final a2 = before.copyWith(koach: st);
          sessionLog(week, day.j).adapt = a2.toJson().cast<String, dynamic>();
          koachEngine.journal = k.journal;
          _adaptQuietSave();
        } catch (_) {
          _koachRt.live = null;
        }
      }
      return null;
    }
    final prev = adaptGoal(week, day.j, e, next);
    koachEnsureTarget(week, day, e, next);
    final a = sessionAdaptOf(key);
    final m = (a?.koach?['cibles'] as Map?)?[e.slotId];
    if (m is Map && m['stop'] == true) {
      return const KoachSetNews(
        'j’arrête cet exercice ici : plusieurs séries manquées de suite. '
        'Passe à la suite.',
        stop: true,
      );
    }
    final g = adaptGoal(week, day.j, e, next);
    if (g == null || prev == null) return null;
    if (g.kg == prev.kg && g.low == prev.low && g.high == prev.high) {
      return null;
    }
    final parts = <String>[
      if (g.kg != null && g.kg! > 0) adaptKgLabel(g.kg!),
      adaptAmount(g.low, g.high, seconds: g.seconds),
    ].where((x) => x.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return KoachSetNews('série suivante : ${parts.join(' × ')}.');
  }

  /// Ligne de raison de Koach à l'écran de séance pour [e] (une ligne au
  /// plus, texte lisible ; null : rien à dire).
  String? koachReasonLine(int week, int j, Exercise e) {
    final a = sessionAdapt(week, j);
    final st = a?.koach;
    if (st == null || st['state'] == 'preview') return null;
    final raisons = st['raisons'];
    if (raisons is! List) return null;
    final id = e.catalogId;
    for (final r in raisons) {
      if (r is! Map) continue;
      final p = r['params'];
      final ex = p is Map ? p['exercice'] : null;
      if (ex != null && ex != id) continue;
      if (ex == null && id != null) continue;
      return texteRaisonKoach(
        r.cast<String, Object?>(),
        nomExercice: (x) => content.byId[x]?.nom,
      );
    }
    return null;
  }

  /// Raisons de la séance (dédoublonnées, textes lisibles) : renvois et
  /// raisons générales de l'ouverture (deux au plus à l'écran).
  List<String> koachSessionReasons(int week, int j, {int max = 2}) {
    final a = sessionAdapt(week, j);
    final raisons = a?.koach?['raisons'];
    if (raisons is! List) return const [];
    final out = <String>[];
    for (final r in raisons) {
      if (r is! Map) continue;
      final t = texteRaisonKoach(
        r.cast<String, Object?>(),
        nomExercice: (x) => content.byId[x]?.nom,
      );
      if (!out.contains(t)) out.add(t);
      if (out.length >= max) break;
    }
    return out;
  }

  // ------------------------------------------------------ suggestions

  /// Suggestion de Koach sur la première série de [e] : changement de
  /// charge par rapport au dernier passage (`proposition`), ou vrai test
  /// inséré. Null : rien à valider (une baisse imposée par la sécurité
  /// n'est jamais une suggestion).
  ({
    String type,
    double? from,
    double? to,
    List<double> steps,
    String? decided,
  })?
  koachSuggestion(int week, int j, Exercise e) {
    final a = sessionAdapt(week, j);
    final slot = e.slotId;
    if (a == null || slot == null) return null;
    final st = a.koach;
    if (st == null || st['state'] != 'open') return null;
    final decided = (st['decisions'] as Map?)?[slot] as Map?;
    final served = _koachServed(a, slot);
    if (served != null && served['koach'] == 'vrai_test') {
      return (
        type: 'test',
        from: null,
        to: null,
        steps: const [],
        decided: decided == null
            ? null
            : (decided['accepte'] == true ? 'ok' : 'non'),
      );
    }
    final c = ((st['cibles'] as Map?)?[slot] as Map?)?['0'];
    final p = c is Map ? c['proposition'] : null;
    if (p is! Map) return null;
    return (
      type: '${p['type']}',
      from: (p['depart'] as num?)?.toDouble(),
      to: (p['cible'] as num?)?.toDouble(),
      steps: [
        for (final x in (p['paliers'] as List? ?? const []))
          if (x is num) x.toDouble(),
      ],
      decided: decided == null
          ? null
          : (decided['accepte'] == true ? 'ok' : 'non'),
    );
  }

  /// Décision sur la suggestion de [e] : [ok] (validée d'un tap) ou
  /// refusée avec une raison facultative (`too_heavy`, `too_light`,
  /// `equipment`, `time`, `other`). Versée au journal après la fin de la
  /// séance (§ 2.2 point 8). Refus d'une charge : la charge d'avant est
  /// pré-remplie ; refus d'un test : ses séries sont retirées.
  void koachDecide(
    int week,
    DayPlan day,
    Exercise e,
    bool ok, {
    String? reason,
  }) {
    final key = sessionKey(week, day.j);
    final a = sessionAdaptOf(key);
    final slot = e.slotId;
    final sugg = koachSuggestion(week, day.j, e);
    if (a == null || slot == null || sugg == null) return;
    final st = Map<String, Object?>.of(a.koach!);
    final dec = Map<String, Object?>.of(
      (st['decisions'] as Map?)?.cast<String, Object?>() ?? {},
    );
    dec[slot] = {
      'accepte': ok,
      'raison': ok ? null : reason,
      'type': sugg.type,
      'exerciseId': e.catalogId,
    };
    st['decisions'] = dec;
    var next = a.copyWith(koach: st);
    final log = sessionLog(week, day.j);
    final x = log.ex[e.id];
    if (!ok && sugg.type == 'test') {
      // Test refusé : on passe au travail ; aucune série du test.
      next = next.copyWith(
        plan: next.plan.copyWith(
          items: [
            for (final it in next.plan.items)
              if (it.slotId != slot) it,
          ],
        ),
      );
      if (x != null) x.sets.removeWhere((s) => !s.done);
    } else if (!ok && sugg.from != null && x != null) {
      final t = adaptKgField(sugg.from!);
      for (final s in x.sets) {
        if (!s.done && !s.edited) s.kg = t;
      }
    } else if (ok && sugg.to != null && x != null) {
      final t = adaptKgField(sugg.to!);
      for (final s in x.sets) {
        if (!s.done && !s.edited) s.kg = t;
      }
    }
    log.adapt = next.toJson().cast<String, dynamic>();
    saveLogs();
    notifyListeners();
  }

  // ------------------------------------------------------ fin de séance

  /// Fin de la séance S[week]·J[j] (§ 2.2 points 6 à 8) : séries restantes
  /// versées, `seance_fin` (douleurs signalées après le début), décisions
  /// de la séance. Une séance commencée avant la prise de main (ou
  /// pendant un arrêt) est versée sans `plan` au rattrapage suivant.
  void koachOnSessionDone(int week, int j) {
    final key = sessionKey(week, j);
    if (koachEngine.versed.contains(key)) return;
    final a = sessionAdaptOf(key);
    final st = a?.koach;
    final k = _koachRt.live;
    if (a == null || st == null || st['state'] != 'open' || k == null) {
      if (koachEngine.active) unawaited(koachRefresh());
      return;
    }
    final lundi = koachLundi!;
    final w = program.week(week);
    final base = w.day(j);
    if (base == null) return;
    try {
      final st2 = _koachVerse(week, base, a, k);
      // Séries versées puis corrigées (flammes, répétitions, charge) ou
      // décochées : événements remplacés ou retirés, puis rejeu (§ 2.7).
      final fixed = _koachCorrections(week, base, a, st2, k);
      final jour = (st['jour'] as num?)?.toInt() ?? koachJour(lundi, _kToday);
      // Toutes les séries versées (dans l'ordre) pour `seance.sets`.
      final sets = <Object?>[];
      for (var i = k.journal.length - 1; i >= 0; i--) {
        final ev = k.journal[i];
        if (ev['type'] == 'seance_debut') break;
        if (ev['type'] == 'serie') sets.insert(0, ev['serie']);
      }
      final debut = st['debut'];
      final now = a.check?.pains;
      Object? douleurs;
      final before = debut is Map ? debut['pains'] : null;
      final after = now == null ? null : [for (final p in now) p.toJson()];
      if (after != null && jsonEncode(after) != jsonEncode(before)) {
        douleurs = after;
      }
      k.observe({
        'type': 'seance_fin',
        'jour': jour,
        'douleurs': douleurs,
        'seance': {'sets': sets},
      });
      _koachDecisions(k, a, st2, jour);
      st2['state'] = 'closed';
      final next = a.copyWith(koach: st2);
      sessionLog(week, j).adapt = next.toJson().cast<String, dynamic>();
      koachEngine.versed.add(key);
      koachEngine.journal = k.journal;
      if (!fixed) unawaited(_koachForecasts(week, j));
      if (fixed) {
        // Journal corrigé : l'état se reconstruit par rejeu (arrière-plan).
        koachEngine.journal = koachJournalDe(k.journal);
        _koachRt.live = null;
        unawaited(koachRefresh());
      }
      _persist();
    } catch (_) {
      _koachRt.live = null;
    }
  }

  /// Corrections des séries déjà versées de la séance : chaque série dont
  /// la saisie a changé depuis son versement est remplacée à sa place dans
  /// le journal ; une série décochée en est retirée. Vrai si le journal a
  /// changé (le moteur vivant n'est plus à jour : rejeu).
  bool _koachCorrections(
    int week,
    DayPlan base,
    SessionAdapt a,
    Map<String, Object?> st,
    ko.Koach k,
  ) {
    final versed = (st['versed'] as List?) ?? const [];
    final now = <String, Json>{};
    for (final rec in _adaptDone(week, _koachDisplayDay(week, base, a), a)) {
      final slot = rec.slotId;
      if (slot == null) continue;
      final cible =
          (((st['cibles'] as Map?)?[slot]) as Map?)?['${rec.setIndex}'];
      final s = koachSerie(
        rec.toJson().cast<String, Object?>(),
        cible: cible is Map ? cible.cast<String, Object?>() : null,
      );
      if (s == null) continue;
      if (cible is Map && cible['flames'] != null) {
        (s['target'] as Map)['flames'] = cible['flames'];
      }
      now['$slot|${rec.setIndex}'] = s;
    }
    final remove = <int>[];
    var changed = false;
    for (final v in versed) {
      if (v is! List || v.length < 4 || v[2] == '-') continue;
      final i = v[3];
      if (i is! int || i < 0 || i >= k.journal.length) continue;
      final ev = k.journal[i];
      if (ev['type'] != 'serie') continue;
      final cur = now['${v[0]}|${v[1]}'];
      if (cur == null) {
        remove.add(i);
        changed = true;
      } else if (_koachSig(cur) != v[2]) {
        ev['serie'] = cur;
        changed = true;
      }
    }
    remove.sort();
    for (final i in remove.reversed) {
      k.journal.removeAt(i);
    }
    return changed;
  }

  /// Décisions de la séance (suggestions), dans l'ordre des emplacements.
  void _koachDecisions(ko.Koach k, SessionAdapt a, Json st, int jour) {
    final dec = st['decisions'];
    if (dec is! Map) return;
    var n = 0;
    for (final e in dec.entries) {
      final d = e.value;
      if (d is! Map) continue;
      final slot = '${e.key}';
      final ex = '${d['exerciseId']}';
      final type = '${d['type']}';
      final c = ((st['cibles'] as Map?)?[slot] as Map?)?['0'];
      final p = c is Map ? c['proposition'] : null;
      final grid = _adaptBook()?.find(ex)?.grid;
      final pas = (grid != null && grid.step > 0) ? grid.step : 2.5;
      final paliers = p is Map ? (p['paliers'] as List? ?? const []) : const [];
      final depart = p is Map ? (p['depart'] as num?) : null;
      final ampleur = paliers.isNotEmpty && depart != null
          ? ((paliers.first as num) - depart).abs() / pas
          : 0.0;
      final flames = c is Map ? c['flames'] as int? : null;
      k.observe({
        'type': 'decision',
        'jour': jour,
        'proposition': {
          'id': 'p$jour-$ex-${n++}',
          'type': type,
          'exerciseId': ex,
          'ampleur': ampleur,
          'charge_kg': c is Map ? c['loadKg'] : null,
          'reps': c is Map ? c['repsHigh'] : null,
          'rir': flames == null ? null : koachRirDeFlammes(flames),
          'contexte': {
            'bilan_bas': false,
            'semaine_allegement': false,
            'moment': p is Map ? p['moment'] : 'debut_de_seance',
            'refus_recents': k.adherence?.refusRecents(jour) ?? 0,
          },
        },
        'accepte': d['accepte'] == true,
        'raison': d['raison'],
      });
    }
  }

  // --------------------------------------------------------- arrêt

  /// Arrêt d'urgence (Réglages) : plus aucun événement versé ; séances
  /// servies telles qu'écrites, la semaine en cours avec ses séries déjà
  /// modulées. Rien n'est perdu.
  void koachStop() {
    final e = koachEngine;
    if (!e.active) return;
    final lundi = koachLundi;
    final g = lundi == null ? 0 : koachJour(lundi, _kToday) ~/ 7;
    final modules = _koachModules(g) ?? const {};
    e.stop = {
      'since': _kToday.iso,
      'week': g,
      'modules': {
        for (final m in modules.entries) m.key: [m.value.$1, m.value.$2],
      },
    };
    _koachRt.live = null;
    _g9Cache.clear();
    _persist();
    notifyListeners();
  }

  /// Réactivation : rejeu du journal gardé, puis rattrapage de tout ce
  /// qui s'est passé depuis l'arrêt (séances versées sans `plan`).
  Future<void> koachResume() async {
    final e = koachEngine;
    if (e.stop == null) return;
    e.stop = null;
    _koachRt.live = null;
    _g9Cache.clear();
    _persist();
    notifyListeners();
    await koachRefresh();
  }

  /// Session de test du mode dev : bascule forcée au jour [d] (null :
  /// date du cahier).
  void koachForceBascule(kc.CivilDate? d) {
    koachEngine.forced = d?.iso;
    _persist();
    notifyListeners();
  }

  /// Nouvelle référence (« Revenir à mon programme d'origine », nouveau
  /// bloc écrit, programme recréé) : `reference` complet versé.
  Future<void> koachNewReference() async {
    final e = koachEngine;
    final k = _koachRt.live;
    final snap = e.snap;
    final lundi = koachLundi;
    if (!e.active || k == null || snap == null || lundi == null) return;
    final g = koachJour(lundi, _kToday) ~/ 7;
    final ev = _koachReferenceEvent(snap, g);
    final sw = Stopwatch()..start();
    try {
      final next = await KoachCalcul.appliquer(k, (x) => x.observe(ev));
      _koachRt.live = next;
      e
        ..journal = next.journal
        ..refSig = _koachRefSig();
      _koachRt.temps.noter('replanification', sw.elapsed);
      _persist();
      notifyListeners();
    } catch (_) {
      _koachRt.live = null;
    }
  }

  // ------------------------------------------------- séance (suite)

  /// Séance d'une journée servie par Koach : aperçu tant qu'elle n'a pas
  /// commencé, séance servie ensuite (jamais recalculée). Une séance
  /// commencée avec le moteur d'avant la prise de main est finie telle
  /// qu'elle est (INTEGRATION_KM3.md § 7.2).
  SessionAdapt? _koachOpenSession(int week, DayPlan base) {
    final key = sessionKey(week, base.j);
    final log = logs[key];
    final stored = log?.adapt == null ? null : sessionAdaptOf(key);
    if (log?.adapt != null && stored == null) return null;
    final started =
        log != null &&
        (log.done || log.ex.values.any((x) => x.sets.any((s) => s.done)));
    final st = stored?.koach;
    if (st != null && st['state'] != 'preview') return stored;
    if (started) {
      if (stored != null && st == null) return stored;
      if (st != null && koachStartNow(week, base)) {
        return sessionAdaptOf(key) ?? stored;
      }
      return stored;
    }
    final today = _kToday.iso;
    final keep = stored != null && stored.date == today ? stored : null;
    final a = koachPreview(week, base, keep: keep);
    if (a == null) return stored;
    if (stored != null && jsonDeepEquals(a.toJson(), stored.toJson())) {
      return stored;
    }
    final target = sessionLog(week, base.j);
    target.adapt = a.toJson().cast<String, dynamic>();
    for (final x in target.ex.values) {
      for (final s in x.sets) {
        if (s.done) continue;
        s.kg = '';
        s.reps = '';
      }
    }
    _adaptResync(week, base, stored ?? a, a, target, key);
    _adaptQuietSave();
    return a;
  }

  /// Bilan, lieu ou temps disponible changés sur une séance de Koach :
  /// l'aperçu suit ; la séance commencée garde ce que Koach a servi (les
  /// douleurs signalées ensuite vont à `seance_fin`).
  SessionAdapt? _koachSetCheck(
    int week,
    DayPlan base,
    SessionAdapt a,
    kc.HealthCheck? check,
    kc.Place? where,
    bool asked,
  ) {
    final useCheck = check != null && check.toJson().isNotEmpty ? check : null;
    final st = a.koach;
    SessionAdapt next;
    if (st != null && st['state'] == 'preview') {
      final keep = a.copyWith(
        asked: asked,
        check: useCheck,
        clearCheck: useCheck == null,
        place: where,
        clearPlace: where == null,
      );
      next = koachPreview(week, base, keep: keep) ?? keep;
    } else {
      next = a.copyWith(
        asked: asked,
        check: useCheck,
        clearCheck: useCheck == null,
        place: where,
        clearPlace: where == null,
      );
    }
    _adaptStore(week, base, a, next);
    return next;
  }

  /// Signature de la modulation affichée (couche du programme).
  String koachOverlaySignature() {
    final e = koachEngine;
    if (!e.active && e.stop == null) return '-';
    return '${e.fromWeek}|${e.closed}|${e.journal.length}|'
        '${e.stop?['since']}|${identityHashCode(_koachRt.live)}';
  }

  /// Semaine en cours servie par Koach : lignes dont les séries ou la
  /// charge changent montrées avec la modulation (« 4 séries au lieu de
  /// 5 · charge −3 % »), l'écrit en dessous ([DayPlan.original]). Les
  /// semaines suivantes restent telles qu'écrites.
  void koachOverlayWeek() {
    final lundi = koachLundi;
    if (lundi == null || planProgram != null) return;
    final week = koachJour(lundi, _kToday) ~/ 7 + 1;
    if (!(koachServesWeek(week) || koachStoppedWeek(week)) ||
        week > program.weeks.length) {
      return;
    }
    final imp = importedProgram;
    if (imp == null) return;
    final w = program.week(week);
    for (var i = 0; i < w.days.length; i++) {
      final d = w.days[i];
      if (logs[sessionKey(week, d.j)]?.done ?? false) continue;
      final out = <Exercise>[];
      var changed = false;
      for (final e in d.exercises) {
        final slot = imp.slotOf(week, d.j, e.id);
        final m = slot == null ? null : koachWeekLine(week, d.j, slot);
        if (m == null) {
          out.add(e);
          continue;
        }
        if (m.sets == 0) {
          changed = true;
          continue;
        }
        changed = true;
        final pct = (m.intensity * 100).round();
        final why = [
          if (m.sets != m.written)
            '${m.sets} série${m.sets > 1 ? 's' : ''} au lieu de ${m.written}',
          if (pct != 0) 'charge ${pct > 0 ? '+' : '−'}${pct.abs()} %',
        ].join(' · ');
        out.add(
          Exercise.koach(
            e,
            name: e.name,
            sets: m.sets == m.written
                ? e.sets
                : (e.sets.withCount(m.sets) ?? e.sets),
            intensity: e.intensity,
            load: e.load,
            rest: e.rest,
            restSec: e.restSec,
            cue: e.cue,
            why: [
              'Koach, cette semaine : $why.',
              if (e.why.isNotEmpty) e.why,
            ].join(' '),
            catalogId: e.catalogId,
          ),
        );
      }
      if (changed) w.days[i] = DayPlan.overlay(d.original, out);
    }
  }

  // ------------------------------------------------- fin de séance

  /// Résumé de fin de séance servie par Koach : capacité estimée avant et
  /// après la séance (charge externe pour un exercice chargé), prochaine
  /// fois non prévue (Koach prescrit le jour venu).
  AdaptSessionSummary? koachSummary(int week, DayPlan base) {
    final a = sessionAdapt(week, base.j);
    final st = a?.koach;
    final k = _koachRt.live;
    if (a == null || st == null || k == null) return null;
    final avant = (st['avant'] as Map?) ?? const {};
    final post = (k.posterior()['exercices'] as Map?) ?? const {};
    final day = adaptDay(week, base, a);
    final log = logs[sessionKey(week, base.j)];
    final out = <AdaptExerciseSummary>[];
    final seen = <String>{};
    for (final e in day.exercises) {
      final id = e.catalogId;
      if (!e.engine || id == null || !seen.add(id)) continue;
      if (!(log?.ex[e.id]?.sets.any((s) => s.done) ?? false)) continue;
      out.add(
        AdaptExerciseSummary(
          exerciseId: id,
          name: _adaptNameOf(id),
          calibrating: false,
          before: _koachEstimate(id, avant[id]),
          after: _koachEstimate(id, post[id]),
          next: _koachNextGoal(st, id, e),
          nextWeek: _koachNextAt(st, id)?.$1,
          nextJ: _koachNextAt(st, id)?.$2,
          nextDate: _koachNextAt(st, id) == null || program.start == null
              ? null
              : program.dateFor(
                  _koachNextAt(st, id)!.$1,
                  _koachNextAt(st, id)!.$2,
                ),
          today: adaptGoal(week, base.j, e, 0),
        ),
      );
    }
    return AdaptSessionSummary(out, adaptPainReferralZones);
  }

  (int, int)? _koachNextAt(Map<String, Object?> st, String id) {
    final p = (st['prevision'] as Map?)?[id];
    if (p is! Map) return null;
    final w = p['week'], j = p['j'];
    return w is int && j is int ? (w, j) : null;
  }

  SetGoal? _koachNextGoal(Map<String, Object?> st, String id, Exercise e) {
    final p = (st['prevision'] as Map?)?[id];
    final c = p is Map ? p['cible'] : null;
    if (c is! Map) return null;
    final seconds = c['secondsLow'] != null || c['secondsHigh'] != null;
    return SetGoal(
      kg: (c['loadKg'] as num?)?.toDouble(),
      low: (seconds ? c['secondsLow'] : c['repsLow']) as int?,
      high: (seconds ? c['secondsHigh'] : c['repsHigh']) as int?,
      flames: c['flames'] as int?,
      seconds: seconds,
    );
  }

  /// Estimation lisible d'une entrée de `posterior().exercices` (charge
  /// totale ramenée à la charge externe pour un exercice chargé).
  kc.ExerciseEstimate? _koachEstimate(String id, Object? raw) {
    if (raw is! Map) return null;
    final typ = raw['type'];
    final v = (raw['valeur'] as num?)?.toDouble();
    final sd = (raw['ecart_type'] as num?)?.toDouble() ?? 0;
    if (v == null) return null;
    kc.CapacityUnit unit;
    var cap = v;
    if (typ == 'charge') {
      unit = kc.CapacityUnit.oneRmKg;
      final frac = ((_koachRt.res?.fiches[id]?['fraction'] as num?) ?? 0)
          .toDouble();
      cap = v - frac * (_koachPeseeAu(_kToday) ?? _koachPoids ?? 0);
      if (cap <= 0) return null;
    } else if (typ == 'reps') {
      unit = kc.CapacityUnit.maxReps;
    } else if (typ == 'tenue') {
      unit = kc.CapacityUnit.maxHoldSeconds;
    } else {
      return null;
    }
    return kc.ExerciseEstimate(
      exerciseId: id,
      unit: unit,
      capacity: cap,
      standardError: cap * sd,
      weeklyTrend: 0,
      observations: (raw['mesures'] as num?)?.toInt() ?? 0,
    );
  }

  /// Résumé d'adaptation demandé par `kalis_plan` pour écrire le bloc
  /// suivant d'un programme créé (INTEGRATION_KM3.md § 5.3) : estimations
  /// tirées de `posterior()` (capacité = charge totale, erreur type depuis
  /// l'intervalle à 90 %, observations = mesures) ; assiduité de
  /// l'application ([base]). Null : Koach ne conduit pas le programme.
  kc.AdaptationSummary? koachAdaptationSummary(kc.AdaptationSummary base) {
    final k = _koachRt.live;
    if (k == null || !koachEngine.active) return null;
    final ex = (k.posterior()['exercices'] as Map?) ?? const {};
    final estimates = <kc.ExerciseEstimate>[];
    for (final e in ex.entries) {
      final v = e.value;
      if (v is! Map) continue;
      final unit = switch (v['type']) {
        'charge' => kc.CapacityUnit.oneRmKg,
        'reps' => kc.CapacityUnit.maxReps,
        'tenue' => kc.CapacityUnit.maxHoldSeconds,
        _ => null,
      };
      final val = (v['valeur'] as num?)?.toDouble();
      final iv = v['intervalle_90'] as List?;
      if (unit == null || val == null || iv == null || iv.length < 3) continue;
      estimates.add(
        kc.ExerciseEstimate(
          exerciseId: '${e.key}',
          unit: unit,
          capacity: val,
          standardError:
              (((iv[2] as num) - (iv[0] as num)) / (2 * 1.6448536269514722))
                  .abs()
                  .toDouble(),
          weeklyTrend: 0,
          observations: (v['mesures'] as num?)?.toInt() ?? 0,
        ),
      );
    }
    return base.copyWith(estimates: estimates);
  }

  // --------------------------------------------- récapitulatif de bloc

  /// Bloc de référence (indice) qui commence à la semaine S[week], ou
  /// null.
  int? _koachBlockStartingAt(int week) {
    final ref = _koachReferenceBlocks();
    final i = ref.starts.indexOf(week - 1);
    return i < 0 ? null : i;
  }

  /// Récapitulatif « ce qui change et pourquoi » du bloc qui commence
  /// cette semaine (ou la suivante, à la dernière séance du bloc), à
  /// valider d'un tap ; null : rien à montrer (déjà validé, pas de
  /// modulation, Koach inactif).
  KoachRecap? koachRecap() {
    final lundi = koachLundi;
    final k = _koachRt.live;
    final pl = k?.planification;
    if (lundi == null || k == null || pl == null || !koachEngine.active) {
      return null;
    }
    final g = koachJour(lundi, _kToday) ~/ 7;
    for (final w in [g, g + 1]) {
      final b = _koachBlockStartingAt(w + 1);
      if (b == null || w + 1 < (koachEngine.fromWeek ?? 1)) continue;
      if (koachEngine.recaps.containsKey('$b')) return null;
      final mod = pl.plan[w];
      if (mod == null) continue;
      final hist = pl.historique.isEmpty ? null : pl.historique.last;
      final vol = [
        for (final x in (mod['volume'] as List? ?? const []))
          (x as num).toDouble(),
      ];
      final quals = [
        for (final q in (k.params['qualites'] as List? ?? const [])) '$q',
      ];
      final pc = (hist?['p_cibles'] as Map?) ?? const {};
      final pr = (hist?['p_cibles_reference'] as Map?) ?? const {};
      return KoachRecap(
        block: b,
        week: w + 1,
        volume: {
          for (var i = 0; i < vol.length && i < quals.length; i++)
            quals[i]: vol[i],
        },
        intensity: (mod['intensite'] as num?)?.toDouble() ?? 0,
        success: {
          for (final e in pc.entries)
            '${e.key}': (
              (e.value as num).toDouble(),
              (pr[e.key] as num?)?.toDouble(),
            ),
        },
        kept: hist?['plan_garde'] == true,
      );
    }
    return null;
  }

  /// Récapitulatif validé (ou refusé : noté, le plan modulé reste, D2 et
  /// garde-fou anti-complaisance).
  void koachRecapDecide(int block, bool ok) {
    koachEngine.recaps['$block'] = ok ? 'valide' : 'refuse';
    _persist();
    notifyListeners();
  }

  // ------------------------------------------------------ mode dev

  /// Export du journal moteur (INTEGRATION_KM3.md § 5.6) : journal de
  /// Koach (ou, avant la prise de main, l'historique converti), et les
  /// séances au format de `walk_forward.rejouer` ; disponible avant la
  /// bascule (critère 10). Données de santé : partage par le système
  /// seulement.
  Future<Json?> koachJournalExport() async {
    final res = await _koachRes();
    final lundi = koachLundi;
    if (res == null || lundi == null || athlete == null) return null;
    final snap =
        koachEngine.snap ??
        _koachSnapshot(res, lundi, koachWeekOf(_kToday) ?? 1);
    final seances = <Json>[];
    final principaux = <String>{};
    for (final b in _koachReferenceBlocks().blocks) {
      for (final d in b.pass1.days) {
        for (final sl in d.slots) {
          if (sl.role == kc.SlotRole.main) principaux.add(sl.exerciseId);
        }
      }
    }
    var dernier = -1;
    final rapport = <String, int>{};
    for (final s in _koachDoneSessions()) {
      final c = _koachConvert(res, lundi, s);
      if (c == null) {
        rapport['seances_vides_ecartees'] =
            (rapport['seances_vides_ecartees'] ?? 0) + 1;
        continue;
      }
      final avant = <Json>[];
      if (dernier >= 0) {
        for (var sem = dernier ~/ 7 + 1; sem <= c.jour ~/ 7; sem++) {
          avant.add({'type': 'semaine_fin', 'jour': 7 * sem, 'semaine': sem});
        }
      }
      if (c.jour > dernier) dernier = c.jour;
      seances.add({
        'cle': c.cle,
        'semaine': c.semaineS,
        'jour': c.jour,
        'avant': avant,
        'debut': c.debut,
        'series': c.series,
        'meta': c.meta,
        'fin': c.fin,
      });
      rapport['seances_converties'] = (rapport['seances_converties'] ?? 0) + 1;
      rapport['series_converties'] =
          (rapport['series_converties'] ?? 0) + c.series.length;
    }
    final journal = koachEngine.snap != null
        ? koachJournalDe(koachEngine.journal)
        : [
            for (final x in seances) ...[
              ...(x['avant'] as List).cast<Json>(),
              x['debut'] as Json,
              ...(x['series'] as List).cast<Json>(),
              x['fin'] as Json,
            ],
          ];
    return {
      'type': 'journal_moteur',
      'version': 1,
      'version_moteur': snap.versionMoteur,
      'version_parametres': snap.versionParametres,
      'sha256_parametres': snap.shaParametres,
      'profil': snap.profil,
      'extensions': snap.extensions,
      'principaux': principaux.toList()..sort(),
      'lifts': snap.lifts,
      'journal': journal,
      'seances': seances,
      'rapport': rapport,
    };
  }

  /// Dossier hors modèle (JSON anonymisé, `Surveillance.dossier`).
  Json? koachDossierExport() {
    final k = _koachRt.live;
    final sv = k?.surveillance;
    if (k == null || sv == null) return null;
    return sv.dossier(k);
  }

  /// Import d'un fichier de paramètres (mode dev) : `{ok, erreurs,
  /// version}` ; versé au journal s'il est valide.
  Map<String, Object?> koachImportParams(String text) {
    final k = _koachRt.live;
    if (k == null) {
      return {
        'ok': false,
        'erreurs': ['Koach n’a pas pris la main : rien à régler.'],
      };
    }
    final r = ko.importerParametres(k, text);
    if (r['ok'] == true) {
      koachEngine.journal = k.journal;
      _persist();
      notifyListeners();
    }
    return r;
  }

  /// Rejeu walk-forward du journal (mesure A de `walk_forward.py`) depuis
  /// la semaine S[depuis] : agrégats seulement.
  Future<Json?> koachWalkForward({int depuis = 12}) async {
    final exp = await koachJournalExport();
    final res = _koachRt.res;
    if (exp == null || res == null) return null;
    final sw = Stopwatch()..start();
    final out = koachRejeuWalkForward(
      res,
      (exp['profil'] as Map).cast<String, Object?>(),
      [
        for (final s in exp['seances'] as List)
          (s as Map).cast<String, Object?>(),
      ],
      {...(exp['principaux'] as List).cast<String>()},
      depuis: depuis,
    );
    _koachRt.temps.noter('walk_forward', sw.elapsed);
    return out;
  }
}

/// Récapitulatif de fin de bloc (« ce qui change et pourquoi »).
class KoachRecap {
  final int block;
  final int week;

  /// Facteur de volume par qualité (1 = référence).
  final Map<String, double> volume;

  /// Écart d'intensité moyen (−0,05 = −5 %).
  final double intensity;

  /// P(réussite) par cible : (avec le plan, avec la référence).
  final Map<String, (double, double?)> success;

  /// Aucun plan meilleur que la référence n'a été retenu.
  final bool kept;
  const KoachRecap({
    required this.block,
    required this.week,
    required this.volume,
    required this.intensity,
    required this.success,
    required this.kept,
  });
}
