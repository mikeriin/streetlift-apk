// KM3 (dev7.0.0, CAHIER_KM.md, DECISIONS_CP.md C13, C17.14) — Koach 1.0
// branché sur le magasin : un seul moteur, un seul comportement.
//
// - section `koachEngine` du document : journal de Koach (source de vérité
//   du moteur, rejoué à l'identique), instantanés hors journal, date
//   d'installation et de bascule, arrêt d'urgence, récapitulatifs de bloc ;
// - KB2 (dev7.2.1, C17.32, C17.34) : bascule ouverte par dérogation du
//   propriétaire ([kKoachBasculeAutorisee]) ; prise de main immédiate, la
//   semaine de la première séance non faite du programme en cours à
//   l'ouverture (jamais une semaine d'avant le départ affiché, jamais une
//   semaine passée, jamais une séance faite), programme importé comme
//   programme créé ; plus d'attente d'un début de bloc ni du 23/11 ;
// - rattrapage du lundi (séances manquées, fin de semaine, replanification
//   hors du fil d'interface), séance du jour (`seance_debut`, diagnostic,
//   `plan(seance)`, `plan(serie)` une fois par série, `seance_fin`,
//   décisions) ;
// - arrêt d'urgence et réactivation, exports du mode dev.
//
// Aucune règle d'entraînement ici : charges, séries et raisons viennent de
// Koach ; la contrainte de charge fixe de CI1h (C15) s'applique au-dessus.
part of 'store.dart';

/// Bascule ouverte dans ce build. KB2 (dev7.2.1) : vrai par dérogation du
/// propriétaire (DECISIONS_CP.md C17.34) — le critère 10 n'est pas tenu au
/// 18/10/2026 ([kKoachCritere10]) ; re-mesure vers le 09/11/2026
/// (C17.34.3). Faux : le moteur d'avant sert tous les programmes (repli).
/// La session de test du mode dev peut forcer la bascule
/// (`koachForceBascule`).
const bool kKoachBasculeAutorisee = true;

/// Tests : bascule ouverte sans build dédié.
@visibleForTesting
bool debugKoachBasculeAutorisee = kKoachBasculeAutorisee;

/// RV2 (K4) : tests : appelé aux étapes d'un versement à la séance
/// (`plan_serie`, `fin_exercice`, `seance_fin`), après les événements
/// versés et avant l'état de la séance ; une exception y simule une panne
/// du moteur. Null dans l'application.
@visibleForTesting
void Function(String etape)? debugKoachPanne;

/// KB2 : critère 10 (rejeu du journal réel par le pilotage, 18/10/2026,
/// `pipeline/cp/donnees/rejeu_journal_agregats_kb2.json`, C17.33.3) :
/// agrégats seulement, affichés par l'inspecteur du mode dev.
const kKoachCritere10 =
    'Critère 10 (18/10) : non tenu — ouverture par dérogation · '
    'erreur 5,9 %, couverture 86,9 %';

/// Suffixe de la clé du journal de l'application d'un vrai test inséré par
/// Koach avant l'exercice de travail (emplacement « <slot>.t »).
const kKoachTestSuffix = '#t';

/// Clé de la réponse au questionnaire hors modèle dans un événement
/// `decision` (contrat de Koach, § 2.4). Clé technique, jamais affichée :
/// écrite en deux morceaux pour le contrôle des allégations du texte
/// affiché (tools/check_claims.py).
const kKoachCleDiag = 'diag${'nostic'}';

/// KB2 correction 1 : emplacement écrit d'un item servi (« <slot>.t » :
/// vrai test inséré par Koach avant la ligne <slot>).
String koachSlotEcrit(String slot) =>
    slot.endsWith('.t') ? slot.substring(0, slot.length - 2) : slot;

/// KB2 correction 1 (C17.36, point 5) — garde de la séance servie : Koach
/// ne retire ni n'ajoute jamais en silence un exercice de la séance écrite.
///
/// [ecrit] : items écrits du jour (ordre du programme) ; [servi] : items de
/// `plan(seance)` ; [raisons] : `Koach.explain()` après ce plan. Rend :
/// - `servis` : les items servis dans l'ordre écrit (un vrai test reste
///   devant sa ligne) ; un item sans ligne écrite (ajout) est écarté ;
/// - `ecrites` : lignes écrites absentes du servi sans retrait motivé,
///   servies telles qu'écrites (`{slotId, exercice, cause?}`, `cause` : code
///   de la raison de Koach sur l'exercice, s'il en a donné une) ;
/// - `retraits` : retraits motivés (`{slotId, exercice, code}`) : conduite
///   sous douleur (`koach.douleur_retrait`), course ou cardio retirés au
///   bilan bas ou sous douleur (`koach.endurance_retrait`), test reporté
///   (`koach.test_reporte` sur une ligne de test), séance bornée au temps
///   donné par l'athlète (`koach.seance_bornee`, [budgetDonne]).
///
/// KB4 (Koach 1.0.7, DECISIONS_CP.md C17.40) : la garde vaut pour **tous
/// les rôles** (règle de KB2 correction 1 ; le retrait d'un accessoire par
/// le retour gradué de KB3 est retiré) : la rampe de volume ne coupe plus
/// jamais sous l'écrit. Retraits motivés en plus de ceux de KB2 correction
/// 1 : la rampe tendineuse des tenues bras tendus (`koach.retour_gradue`
/// d'un groupe `bras_tendus_*` à 0 série, sous douleur ou non). Toute
/// autre ligne absente du servi est servie telle qu'écrite (`ecrites`,
/// avec la raison de Koach sur l'exercice) : avec 1.0.7, cela ne doit plus
/// arriver pour le volume (diagnostic du mode dev, état `garde`).
/// Pur (testé).
({List<Json> servis, List<Json> ecrites, List<Json> retraits}) koachGardeSeance(
  List<Json> ecrit,
  List<Json> servi,
  List<Json> raisons, {
  bool budgetDonne = false,
}) {
  final rang = <String, int>{};
  for (var i = 0; i < ecrit.length; i++) {
    rang.putIfAbsent('${ecrit[i]['slotId']}', () => i);
  }
  final gardes = <(int, int, Json)>[];
  for (var i = 0; i < servi.length; i++) {
    final r = rang[koachSlotEcrit('${servi[i]['slotId']}')];
    if (r != null) gardes.add((r, i, servi[i]));
  }
  gardes.sort((a, b) {
    final c = a.$1.compareTo(b.$1);
    return c != 0 ? c : a.$2.compareTo(b.$2);
  });
  final present = {for (final g in gardes) koachSlotEcrit('${g.$3['slotId']}')};
  final ecrites = <Json>[];
  final retraits = <Json>[];
  for (final w in ecrit) {
    final slot = '${w['slotId']}';
    if (present.contains(slot)) continue;
    final ex = w['exerciseId'];
    String? motif;
    String? cause;
    for (final r in raisons) {
      final p = r['params'];
      if (p is! Map || p['exercice'] != ex) continue;
      final code = '${r['code']}';
      if (code == 'koach.douleur_retrait' ||
          code == 'koach.endurance_retrait' ||
          (code == 'koach.test_reporte' && w['kind'] == 'test') ||
          (code == 'koach.seance_bornee' && budgetDonne) ||
          (code == 'koach.retour_gradue' && koachRampeTendineuse(p))) {
        motif ??= code;
      } else {
        cause ??= code;
      }
    }
    if (motif != null) {
      retraits.add({'slotId': slot, 'exercice': ex, 'code': motif});
    } else {
      ecrites.add({
        'slotId': slot,
        'exercice': ex,
        if (cause != null) 'cause': cause,
      });
    }
  }
  return (
    servis: [for (final g in gardes) g.$3],
    ecrites: ecrites,
    retraits: retraits,
  );
}

/// KB4 : raison `koach.retour_gradue` de la rampe tendineuse des tenues
/// bras tendus à 0 série ([p] : paramètres de la raison ; groupe
/// `bras_tendus_*`) : seul retour gradué que Koach 1.0.7 émet encore
/// (`koach_textes.dart`). Pur.
bool koachRampeTendineuse(Map p) =>
    '${p['groupe']}'.startsWith('bras_tendus') && p['series'] == 0;

/// KB2 correction 1 : raison affichée d'une ligne écrite que Koach n'a
/// pas servie (garde de la séance) ; [cause] : code de la raison de Koach
/// sur l'exercice.
/// KB4 (Koach 1.0.7) : le volume de la semaine ne retire plus rien
/// (`koach.retour_gradue`, `koach.ajout_borne` : texte général).
String koachTexteEcrite(String? cause) => switch (cause) {
  'koach.seance_bornee' =>
    'Servi tel qu’écrit. Koach l’aurait retiré pour tenir la durée de la '
        'séance.',
  'koach.tendon' =>
    'Servi tel qu’écrit. Koach l’aurait retiré pour ménager tes tendons : '
        'écoute tes sensations.',
  _ => 'Servi tel qu’écrit : Koach garde chaque exercice du programme.',
};

/// KB3 : raisons de structure de la séance, dites sur leur carte toute la
/// séance (gardées de l'ouverture).
const kKoachRaisonsDeSeance = {
  'koach.retour_gradue',
  'koach.tendon',
  'koach.seance_bornee',
};

/// KB3 (Koach 1.0.6 change l'ordre de ses raisons) : raisons triées dans
/// l'ordre des codes du contrat (`koachCodesRaisons` : douleur d'abord),
/// codes inconnus après ; tri stable. L'affichage ne dépend donc pas de
/// l'ordre rendu par le moteur. Pur (testé).
List<Map> koachTrierRaisons(List<Map> raisons) {
  int rang(Map r) {
    final i = koachCodesRaisons.indexOf('${r['code']}');
    return i < 0 ? koachCodesRaisons.length : i;
  }

  final out = [for (var i = 0; i < raisons.length; i++) (i, raisons[i])]
    ..sort((a, b) {
      final c = rang(a.$2).compareTo(rang(b.$2));
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
  return [for (final x in out) x.$2];
}

/// KB3 : texte d'une ligne au départ chronométré servie telle qu'écrite
/// (PR8 : séries du programme) que le retour gradué de Koach 1.0.6 réduit
/// (`koach.retour_gradue`, `series` < `ecrites`) ; null pour une autre
/// raison.
String? koachTexteReduitEcrit(Map r) {
  if (r['code'] != 'koach.retour_gradue') return null;
  final p = r['params'];
  if (p is! Map) return null;
  final n = p['series'];
  final w = p['ecrites'];
  if (n is! num || w is! num || n <= 0 || n >= w) return null;
  return 'Servi tel qu’écrit (départ chronométré du programme). Koach '
      'aurait fait ${n.round()} série${n.round() > 1 ? 's' : ''} sur '
      '${w.round()} pour rester dans le volume de la semaine : écoute tes '
      'sensations.';
}

/// KB4 (Koach 1.0.7 planifie les lignes au départ chronométré à leurs
/// séries écrites) : texte d'une ligne PR8 servie telle qu'écrite quand les
/// séries que Koach a servies ([servies]) diffèrent encore de l'écrit
/// ([ecrites]) ; null quand elles sont égales. Pur (testé).
String? koachTexteEcartEcrit(int servies, int ecrites) {
  if (servies == ecrites || servies < 0 || ecrites <= 0) return null;
  final s = servies > 1 ? 's' : '';
  return servies < ecrites
      ? 'Servi tel qu’écrit (départ chronométré du programme). Koach '
            'aurait fait $servies série$s sur $ecrites : écoute tes '
            'sensations.'
      : 'Servi tel qu’écrit (départ chronométré du programme). Koach '
            'aurait fait $servies série$s au lieu de $ecrites : garde le '
            'programme, et note tes flammes au plus juste.';
}

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

  /// KB2 : première ouverture d'un build où la bascule est ouverte
  /// (dev7.2.1 ou suivant ; AAAA-MM-JJ). La date d'installation notée par
  /// dev7.0.0 à dev7.2.0 ([installedOn]) ne compte pas.
  String? openedOn;

  /// Raison d'une activation refusée (`poids` : aucun poids connu).
  String? blocked;

  /// Empreinte des blocs de la dernière référence versée (une référence
  /// nouvelle est versée quand les blocs changent : bloc suivant écrit,
  /// retour au programme d'origine).
  String? refSig;

  /// KB4 : carte « Koach ne coupe plus ton programme » vue (réactivation
  /// ou « Plus tard », AAAA-MM-JJ) ; null : à montrer tant que Koach est
  /// arrêté.
  String? annonce107;

  bool get active => snap != null && stop == null;

  /// RV1 : section lue avec un instantané illisible : gardée telle quelle
  /// et réécrite à l'identique tant que Koach n'a pas d'autre instantané,
  /// puis sous `illisible` (avant : état neuf, section omise à l'écriture
  /// suivante, journal de Koach perdu).
  Map<String, Object?>? raw;

  bool get pristine =>
      raw == null && snap == null && journal.isEmpty && forced == null;

  Map<String, Object?> toJson() {
    final r = raw;
    if (r != null && snap == null) return r;
    return {
      'v': 1,
      if (installedOn != null) 'installedOn': installedOn,
      if (openedOn != null) 'openedOn': openedOn,
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
      if (annonce107 != null) 'annonce107': annonce107,
      // RV1 : section illisible d'avant, gardée quand Koach repart d'un
      // nouvel instantané (jamais perdue).
      if (r != null) 'illisible': r,
    };
  }

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
    out.openedOn = day('openedOn');
    out.activatedOn = day('activatedOn');
    out.forced = day('forced');
    out.annonce107 = day('annonce107');
    try {
      if (m['snap'] != null) out.snap = KoachInstantane.fromJson(m['snap']);
    } catch (_) {
      // RV1 : toute erreur de lecture (un élément d'un autre type levait
      // une TypeError : application bloquée au démarrage).
      issues?.add('snap');
      out.raw = koachCopie(m) as Map<String, Object?>;
    }
    final ill = m['illisible'];
    if (out.raw == null && ill is Map) {
      out.raw = koachCopie(ill) as Map<String, Object?>;
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

  /// Jour 0 de Koach : S1·J1, jour du départ du programme ; null :
  /// programme non commencé.
  ///
  /// RV2 (K5) : avant, le lundi de la semaine du départ : pour un départ
  /// un autre jour, la semaine de Koach (`semaine_fin`, `seance_manquee`,
  /// prise de main, rattrapage) était décalée de celle du programme
  /// (`Program.dateFor` : J1 = jour du départ). Le moteur ne compte qu'en
  /// jours depuis ce jour 0 (aucun lundi attendu). Migration sans perte :
  /// un départ un lundi ne change rien (même jour 0) ; un instantané pris
  /// avant RV2 au lundi d'un départ un autre jour garde son cadre (journal
  /// versé dans ce cadre, jamais réécrit) tant que Koach n'est pas repris
  /// en main ; une nouvelle prise de main prend le jour du départ.
  kc.CivilDate? get koachLundi {
    final s = program.start;
    if (s == null) return null;
    final depart = civilOf(s);
    final snap = koachEngine.snap;
    final lundi = koachLundiDe(depart);
    if (snap != null && snap.lundi != depart.iso && snap.lundi == lundi.iso) {
      return lundi;
    }
    return depart;
  }

  /// Semaine S du programme contenant [d] (1 = S1).
  int? koachWeekOf(kc.CivilDate d) {
    final l = koachLundi;
    if (l == null) return null;
    final days = d.dayNumber - l.dayNumber;
    if (days < 0) return null;
    return days ~/ 7 + 1;
  }

  /// Premier jour de la semaine S[s] de Koach (RV2 (K5) : S[s]·J1).
  kc.CivilDate? _koachWeekStart(int s) => koachLundi?.addDays(7 * (s - 1));

  /// La bascule peut avoir lieu dans ce build (ou forcée dans la session
  /// de test).
  bool get koachBasculeOuverte =>
      debugKoachBasculeAutorisee || koachEngine.forced != null;

  static const _kInstall = 'km3_installation_v1';
  static const _kOuverture = 'kb2_ouverture_v1';

  /// Note la première ouverture d'une version avec Koach 1.0 (date
  /// d'installation, affichée par l'inspecteur) : clé locale de la
  /// session, puis section `koachEngine` ; KB2 : et la première ouverture
  /// d'un build où la bascule est ouverte ([KoachEngineData.openedOn]).
  void koachNoteInstall() {
    final e = koachEngine;
    if (e.installedOn == null) {
      final saved = _prefs.getString(_kInstall);
      if (saved != null && parseCivilDate(saved) != null) {
        e.installedOn = saved;
      } else {
        e.installedOn = _kToday.iso;
        unawaited(_prefs.setString(_kInstall, e.installedOn!));
      }
    }
    if (e.openedOn == null && debugKoachBasculeAutorisee) {
      final saved = _prefs.getString(_kOuverture);
      if (saved != null && parseCivilDate(saved) != null) {
        e.openedOn = saved;
      } else {
        e.openedOn = _kToday.iso;
        unawaited(_prefs.setString(_kOuverture, e.openedOn!));
      }
    }
  }

  /// KB2 : semaine S où Koach prendra la main sur le programme en cours
  /// (null : jamais dans ce build, ou programme absent / fini), même si
  /// elle n'a pas encore commencé : la semaine de la première séance non
  /// faite à partir de la semaine du jour, jamais avant le départ affiché
  /// (`firstShown`, PR2) ni avant le premier bloc d'un programme créé.
  /// Session de test : la semaine de la date forcée.
  int? koachTakeoverPlanned() {
    final lundi = koachLundi;
    if (lundi == null || content.catalog == null) return null;
    if (!koachBasculeOuverte) return null;
    final plan = planProgram;
    if (plan == null && importedProgram == null) return null;
    final last = math.min(
      plan?.totalWeeks ?? importedLastWeek,
      program.weeks.length,
    );
    final f = koachEngine.forced;
    if (f != null) {
      final w = koachWeekOf(kc.CivilDate.parse(f));
      return w == null || w > last ? null : w;
    }
    final today = _kToday;
    var from = math.max(program.firstShown, plan?.firstWeek ?? 1);
    from = math.max(from, koachWeekOf(today) ?? 1);
    final opened = koachEngine.openedOn == null
        ? null
        : koachWeekOf(kc.CivilDate.parse(koachEngine.openedOn!));
    if (opened != null) from = math.max(from, opened);
    for (var w = from; w <= last; w++) {
      for (final d in program.week(w).days) {
        if (d.exercises.isEmpty) continue;
        if (logs[sessionKey(w, d.j)]?.done ?? false) continue;
        return w;
      }
    }
    return null;
  }

  /// Semaine S où Koach prend la main maintenant (la semaine prévue a
  /// commencé ; session de test : la date forcée est passée), ou null.
  int? koachTakeoverWeek() {
    final w = koachTakeoverPlanned();
    if (w == null) return null;
    final today = _kToday;
    final f = koachEngine.forced;
    final start = f != null ? kc.CivilDate.parse(f) : _koachWeekStart(w)!;
    return start.compareTo(today) <= 0 ? w : null;
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

  /// KB2 : séance S[week]·J[j] commencée avant la prise de main (séries
  /// validées, servie par le moteur d'avant ou telle qu'écrite) : gardée
  /// telle quelle jusqu'à sa fin (ni réécrite, ni modulée) ; Koach la
  /// verse au journal une fois faite.
  bool koachStartedBefore(int week, int j) {
    final log = logs[sessionKey(week, j)];
    if (log == null || log.done) return false;
    if (log.adapt?['koach'] != null) return false;
    return log.ex.values.any((x) => x.sets.any((s) => s.done));
  }

  /// Koach sert la journée S[week]·J[j] du programme.
  bool koachServesDay(int week, int j) =>
      koachServesWeek(week) &&
      !koachStartedBefore(week, j) &&
      adaptPlaceOf(week, j) != null;

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

  /// Dernière erreur du moteur (rejeu, rattrapage, ressources), ou null.
  String? get koachRuntimeError => _koachRt.error;

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
    // KB4 : séance servie par Koach finie hors de lui (pendant un arrêt
    // d'urgence, ou moteur pas prêt à la fin) : fermée d'abord (séries
    // restantes, `seance_fin`), jamais versée une seconde fois.
    await _koachCloseOrphans(gen);
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
        [for (final b in r.blocks) koachBlocJson(b)],
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
      rt.error = null;
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

  /// KS1A : bloc de référence tel que Koach le lit : JSON du bloc sans le
  /// type des journées (`PlanDay.type`, `kalis_core` 0.4.4). Koach 1.0
  /// (`kalis_adapt` 1.0.2) ne lit pas ce champ ; il est retiré pour que la
  /// référence versée et sa signature restent celles de dev7.0.0 (aucune
  /// nouvelle référence à la mise à jour, programme de 40 semaines
  /// compris).
  Json koachBlocJson(kc.ProgramBlock b) {
    final j = b.toJson();
    final p1 = j['pass1'];
    if (p1 is! Map) return j;
    final days = p1['days'];
    if (days is! List || !days.any((d) => d is Map && d.containsKey('type'))) {
      return j;
    }
    return {
      ...j,
      'pass1': {
        ...p1.cast<String, Object?>(),
        'days': [
          for (final d in days)
            d is Map
                ? (Map<String, Object?>.of(d.cast<String, Object?>())
                    ..remove('type'))
                : d,
        ],
      },
    };
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
      'blocs': [for (final b in ref.blocks) koachBlocJson(b)],
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
    // KB4 : séance servie par Koach (début déjà au journal) : versée par sa
    // fermeture ([koachOnSessionDone], [_koachCloseOrphans]), jamais une
    // seconde fois ici.
    bool servie(String key) {
      final st = logs[key]?.adapt?['koach'];
      return st is Map && st['state'] == 'open' && _koachDebutOuvert(st);
    }

    void verseDone(bool Function(int jour) when) {
      for (final s in done) {
        if (e.versed.contains(s.key) || versedNow.contains(s.key)) continue;
        if (s.key == open || servie(s.key)) continue;
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
          // RV1 : séance servie par Koach ouverte passée minuit : jamais
          // déclarée manquée (avant : manquée puis faite, son volume
          // redistribué sur la semaine suivante).
          if (key == open || servie(key)) continue;
          if (programResume?.keys.contains(key) ?? false) continue;
          if (program.start == null) continue;
          final date = civilOf(program.dateFor(week, d.j));
          if (date.compareTo(today) >= 0) continue;
          // RV1 : séance commencée la veille (séries validées), finie après
          // minuit : pas manquée ; plus ancienne et abandonnée : manquée.
          if (inProgress(key) && date.dayNumber >= today.dayNumber - 1) {
            continue;
          }
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
              'items': [
                for (final it in info.items) koachItemVolume(it, info.roles),
              ],
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
    // RV2 (K3) : longueur du journal de l'instance vive au départ du calcul.
    final n0 = k.journal.length;
    ko.Koach next;
    try {
      next = await KoachCalcul.rattraper(k, steps);
    } catch (_) {
      // Instance d'avant gardée ; rejeu au prochain démarrage (RV2 (K4) :
      // calcul sur place coupé à sa longueur d'avant par `KoachCalcul`).
      if (identical(rt.live, k)) rt.live = null;
      rt.error = 'Rattrapage de Koach impossible.';
      return;
    }
    final avantAdoption = KoachCalcul.debugAvantAdoption;
    if (avantAdoption != null) await avantAdoption();
    if (gen != rt.gen) return;
    // RV2 (K3) : séries, débuts de séance… versés à l'instance vive pendant
    // le calcul : rejoués sur la copie (sinon le résultat est abandonné et
    // le rattrapage se refait au prochain passage).
    if (!_koachAdopter(k, next, n0)) return;
    rt.temps.noter('replanification', sw.elapsed);
    rt.live = next;
    rt.error = null;
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
    final roles = {
      for (final d in place.block.pass1.days)
        if (d.dayIndex == place.dayIndex)
          for (final s in d.slots) s.slotId: s.role,
    };
    final items = <kc.ExercisePrescription>[];
    for (final it in day.items) {
      final m = modules?['${place.dayIndex}|${it.slotId}'];
      var next = it;
      // KB4 (C17.40) : jamais une ligne écrite retirée de l'aperçu (une
      // modulation à 0 série garde la ligne écrite) ; une ligne au départ
      // chronométré servie telle qu'écrite (PR8) garde ses séries écrites
      // (tours du groupe).
      if (m != null &&
          m.$1 != it.sets &&
          m.$1 > 0 &&
          !adaptAsWritten(week, it.slotId)) {
        next = it.copyWith(sets: m.$1, setTargets: null);
      }
      // Correctif 20/10/2026 : accessoires servis en plage (aperçu comme
      // séance ouverte).
      items.add(_koachRange(place, next, roles[it.slotId]));
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
    // KB4 : ligne au départ chronométré servie telle qu'écrite (PR8) : pas
    // de modulation affichée ; une modulation à 0 série ne retire rien.
    if (adaptAsWritten(week, slot) || m.$1 <= 0) return null;
    final sets = m.$1;
    if (sets == it.sets && m.$2.abs() < 0.005) return null;
    return (sets: sets, written: it.sets, intensity: m.$2);
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
    final sw = Stopwatch()..start();
    await koachRefresh();
    final ok = koachStartNow(week, base, diagnostic: diagnostic);
    if (ok) _koachRt.temps.noter('debut_seance', sw.elapsed);
    return ok;
  }

  /// KB2 correction 1 (C17.36) : réponses au questionnaire hors modèle
  /// valides : chaque réponse est le code d'un choix de sa question, dans
  /// l'ordre des questions de la surveillance (cause d'abord).
  bool koachDiagnosticValid(Json reponses) {
    final sv = _koachRt.live?.surveillance;
    if (sv == null || reponses['cause'] == null) return false;
    final seen = <String>{};
    for (var step = 0; step < 3; step++) {
      final qs = sv.questions(reponses);
      if (step >= qs.length) break;
      final q = qs[step];
      final code = '${q['code']}';
      if (!reponses.containsKey(code)) break;
      final r = reponses[code];
      final codes = [
        for (final c in (q['choix'] as List? ?? const []))
          c is Map ? c['code'] : c,
      ];
      if (!codes.contains(r)) return false;
      seen.add(code);
    }
    return seen.length == reponses.length;
  }

  /// KB2 correction 1 : la réponse au questionnaire de S[week]·J[j] a été
  /// refusée (séance écrite servie, question reposée à la séance
  /// suivante).
  bool koachAnswerRefused(int week, int j) {
    final k = logs[sessionKey(week, j)]?.adapt?['koach'];
    return k is Map && k['state'] == 'ecrite' && k['refus'] == 'reponse';
  }

  /// Réponse refusée : la séance reste la séance écrite (l'aperçu, séries
  /// de la semaine et charge fixe comprises), hors de Koach ; rien n'est
  /// versé au journal de Koach pour son début (rejeu au prochain passage).
  void _koachRefuseAnswer(int week, DayPlan base, SessionAdapt a) {
    final log = sessionLog(week, base.j);
    final next = a.copyWith(
      koach: {'state': 'ecrite', 'refus': 'reponse', 'date': _kToday.iso},
    );
    log.adapt = next.toJson().cast<String, dynamic>();
    saveLogs();
    _persist();
  }

  /// [koachStart] sans attendre : le moteur doit être prêt.
  bool koachStartNow(int week, DayPlan base, {Json? diagnostic}) {
    final key = sessionKey(week, base.j);
    final a = sessionAdaptOf(key);
    final k = _koachRt.live;
    final lundi = koachLundi;
    final place = _koachPlace(week, base.j);
    final book = _adaptBook();
    // KB4 : une séance faite (ou déjà versée au journal) n'est jamais
    // commencée par Koach après coup.
    if ((logs[key]?.done ?? false) || koachEngine.versed.contains(key)) {
      return false;
    }
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
    // KB2 correction 1 (C17.36) : réponses validées avant l'envoi ; une
    // réponse refusée ne fait jamais tomber la séance en silence.
    final withAnswer = diagnostic != null && koachNeedsDiagnostic;
    if (withAnswer && !koachDiagnosticValid(diagnostic)) {
      _koachRefuseAnswer(week, base, a);
      return false;
    }
    final sw = Stopwatch()..start();
    // Longueur du journal avant le début de séance : un échec le coupe là
    // (le journal reste rejouable, aucun `seance_debut` orphelin).
    final n0 = k.journal.length;
    void couper() {
      if (k.journal.length > n0) k.journal.removeRange(n0, k.journal.length);
    }

    Json r;
    try {
      k.observe({
        'type': 'seance_debut',
        'jour': jour,
        'bilan': check == null || check.isEmpty ? null : check,
        'poids_kg': _koachPeseeAu(today),
        'contexte': contexte,
      });
      if (withAnswer) {
        try {
          k.observe({
            'type': 'decision',
            'jour': jour,
            kKoachCleDiag: diagnostic,
          });
        } catch (_) {
          // Début de séance déjà versé à l'instance : journal coupé, rejeu
          // au prochain passage.
          couper();
          _koachRt.live = null;
          _koachRefuseAnswer(week, base, a);
          return false;
        }
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
      // État du moteur partiel : journal coupé, rejeu au prochain passage.
      couper();
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
    final raisons = k.explain();
    // KB2 correction 1 (C17.36, point 5) : Koach ne retire ni n'ajoute
    // jamais en silence un exercice de la séance écrite. Ordre écrit ; un
    // exercice écrit absent du servi est servi tel qu'écrit (la ligne de
    // l'aperçu), raison affichée, sauf retrait motivé (douleur, test
    // reporté, temps donné par l'athlète).
    final garde = koachGardeSeance(
      info.items,
      [
        for (final it in (r['items'] as List? ?? const []))
          if (it is Map) koachCopie(it) as Json,
      ],
      raisons,
      budgetDonne: contexte['budget'] != null,
    );
    final served = garde.servis;
    final apercu = {for (final it in a.plan.items) it.slotId: it};
    // KB4 (C17.40) : toute ligne écrite absente du servi sans retrait
    // motivé est servie telle qu'écrite, tous rôles ; une ligne absente de
    // l'aperçu (planification à 0 série) n'est plus retirée : sa ligne
    // écrite (charge fixe C15 comprise) la remplace.
    final ecrites = {for (final x in garde.ecrites) '${x['slotId']}'};
    final retraits = garde.retraits;
    final gardees = garde.ecrites;
    // (Calculées seulement si une ligne manque à l'aperçu.)
    late final ecritesDuJour = {
      for (final it in _fixedConstrain(
        place,
        kc.SessionPlan(
          date: today,
          blockId: place.blockId,
          weekIndex: place.weekIndex,
          dayIndex: place.dayIndex,
          items: [
            for (final it
                in place.day?.items ?? const <kc.ExercisePrescription>[])
              _koachRange(
                place,
                it,
                kc.SlotRole.values
                    .where((r) => r.code == info.roles[it.slotId])
                    .firstOrNull,
              ),
          ],
          adjustments: const [],
          confidence: 1,
          reasons: const [],
          groups: place.day?.groups,
        ),
      ).items)
        it.slotId: it,
    };
    final items = <kc.ExercisePrescription>[];
    for (final w in info.items) {
      final slot = '${w['slotId']}';
      for (final it in served) {
        if (koachSlotEcrit('${it['slotId']}') != slot) continue;
        // KB3 : ligne au départ chronométré servie telle qu'écrite (PR8,
        // nombre de séries fixé par le programme) : la ligne de l'aperçu,
        // comme à l'écran. Une réduction de Koach 1.0.6 y casserait le
        // groupe (tours ≠ séries) et ferait retomber toute la séance sur
        // l'aperçu ; elle est dite sur la carte (`koachTexteReduitEcrit`).
        final pr8 = apercu[slot] ?? ecritesDuJour[slot];
        if (it['slotId'] == slot && pr8 != null && adaptAsWritten(week, slot)) {
          items.add(pr8);
          continue;
        }
        final p = _koachItemOf(it, info);
        if (p != null) {
          items.add(
            _koachRange(
              place,
              p,
              kc.SlotRole.values
                  .where((r) => r.code == info.roles[slot])
                  .firstOrNull,
            ),
          );
        }
      }
      if (!ecrites.contains(slot)) continue;
      // La ligne de l'aperçu (séries de la semaine, charge fixe) ; KB4 :
      // absente de l'aperçu, la ligne écrite du jour.
      final p = apercu[slot] ?? ecritesDuJour[slot];
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
      // KB3 : un groupe dont tous les membres sont retirés (accessoires
      // coupés par Koach 1.0.6) n'est plus déclaré.
      groups: place.day?.groups
          ?.where((g) => items.any((x) => x.groupId == g.groupId))
          .toList(),
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
        // KB3 : diagnostic (mode dev) d'une séance servie illisible, qui
        // retombe sur l'aperçu.
        if (plan.validate().isNotEmpty)
          'invalide': [
            for (final v in plan.validate()) '${v.path} ${v.code} ${v.message}',
          ],
        'state': 'open',
        'jour': jour,
        'semaine': week - 1,
        'items': served,
        'raisons': raisons,
        // KB3 : raisons de l'ouverture, gardées pour la séance (`plan(serie)`
        // remplace `raisons`) : retraits et séries réduites restent dits.
        'ouverture': raisons,
        if (gardees.isNotEmpty) 'ecrites': gardees,
        // KB4 : diagnostic du mode dev : lignes que la garde a servies
        // telles qu'écrites (avec 1.0.7, plus jamais pour le volume).
        if (gardees.isNotEmpty)
          'garde': [for (final x in gardees) '${x['slotId']}'],
        if (retraits.isNotEmpty) 'retraits': retraits,
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

  /// Correctif 20/10/2026 : ligne [it] servie en plage quand c'est un
  /// accessoire à reps fixes ([withAccessoryRange]) ; une charge fixe
  /// (C15) garde sa ligne écrite.
  kc.ExercisePrescription _koachRange(
    AdaptPlace place,
    kc.ExercisePrescription it,
    kc.SlotRole? role,
  ) {
    if (_fixedLoadAt(place, it.slotId, it.exerciseId) != null) return it;
    return withAccessoryRange(it, role);
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
      // KB3 : rôle de l'emplacement de chaque item (Koach 1.0.6).
      reste.add([for (final it in i.items) koachItemVolume(it, i.roles)]);
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
  ///
  /// RV2 (K1) : une ligne d'endurance (fiche de Koach `cardio` ou `wod`)
  /// est versée en une seule `serie` (`demand`, `doneShare`, `dose`,
  /// `fatigueSets`, [koachSerieEndurance]), comme une séance faite hors de
  /// Koach ([koachSeanceDe]) : une fois la ligne finie (toutes ses séries
  /// validées, à la place de sa dernière série) ou, [fin], à la fin de la
  /// séance ; jamais série par série (avant : chaque tour versé comme une
  /// série de force, sans demande ni dose). Une ligne d'endurance déjà
  /// versée série par série avant RV2 (séance ouverte à la mise à jour)
  /// reste versée ainsi jusqu'à sa fin (rien n'est réécrit).
  Map<String, Object?> _koachVerse(
    int week,
    DayPlan day,
    SessionAdapt a,
    ko.Koach k, {
    bool fin = false,
  }) {
    final st = Map<String, Object?>.of(a.koach ?? const {});
    final versed = [...(st['versed'] as List? ?? const [])];
    final sigs = {
      for (final v in versed)
        if (v is List && v.length >= 3) '${v[0]}|${v[1]}',
    };
    final shown = _koachDisplayDay(week, day, a);
    final done = _adaptDone(week, shown, a);
    final cibles = (st['cibles'] as Map?) ?? const {};
    bool endurance(kc.SetRecord r) =>
        r.slotId != null &&
        _koachEndurance(r.exerciseId) &&
        !_koachEnduranceAncienne(versed, r.slotId!);
    // Dernière série faite de chaque ligne d'endurance (ordre de
    // réalisation) : place de la `serie` de la ligne.
    final derniere = <String, int>{};
    for (var i = 0; i < done.length; i++) {
      if (endurance(done[i])) derniere[done[i].slotId!] = i;
    }
    for (var i = 0; i < done.length; i++) {
      final rec = done[i];
      final slot = rec.slotId;
      if (slot == null) continue;
      final id = '$slot|${rec.setIndex}';
      if (sigs.contains(id)) continue;
      if (endurance(rec)) {
        // Ligne déjà versée : la série s'y rattache (les corrections de fin
        // de séance remplacent la `serie` de la ligne).
        if (sigs.contains('$slot|E')) {
          sigs.add(id);
          versed.add([slot, rec.setIndex, '~']);
          continue;
        }
        if (derniere[slot] != i ||
            !(fin || _koachLigneFinie(week, shown, slot))) {
          continue;
        }
        final faites = [
          for (final r in done)
            if (r.slotId == slot && r.exerciseId == rec.exerciseId)
              r.toJson().cast<String, Object?>(),
        ];
        for (final r in done) {
          if (r.slotId != slot || !endurance(r)) continue;
          if (sigs.add('$slot|${r.setIndex}')) {
            versed.add([slot, r.setIndex, '~']);
          }
        }
        sigs.add('$slot|E');
        final s = _koachSerieLigne(week, day.j, a, slot, faites);
        if (s == null) {
          versed.add([slot, 'E', '-']);
          continue;
        }
        final sw = Stopwatch()..start();
        k.observe({'type': 'serie', 'serie': s});
        _koachRt.temps.noter('observe_serie', sw.elapsed);
        versed.add([slot, 'E', _koachSigLigne(s), k.journal.length - 1]);
        continue;
      }
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

  /// RV2 (K1) : l'exercice [exerciseId] est d'endurance pour Koach (fiche
  /// `cardio` ou `wod`, comme [koachSerieEndurance]).
  bool _koachEndurance(String exerciseId) {
    final t = _koachRt.res?.fiches[exerciseId]?['type'];
    return t == 'cardio' || t == 'wod';
  }

  /// RV2 (K1) : ligne d'endurance [slot] déjà versée série par série avant
  /// RV2 (une série versée à son rang) : elle finit ainsi.
  static bool _koachEnduranceAncienne(List<Object?> versed, String slot) =>
      versed.any(
        (v) => v is List && v.length >= 4 && v[0] == slot && v[1] is int,
      );

  /// RV2 (K1) : toutes les séries des exercices de la ligne [slot] de la
  /// journée affichée [shown] sont validées.
  bool _koachLigneFinie(int week, DayPlan shown, String slot) {
    final log = logs[sessionKey(week, shown.j)];
    if (log == null) return false;
    var any = false;
    for (final e in shown.exercises) {
      if ((e.slotId ?? adaptSlotOf(week, shown.j, e.id)) != slot) continue;
      final x = log.ex[e.id];
      if (x == null || x.sets.any((s) => !s.done)) return false;
      any = true;
    }
    return any;
  }

  /// RV2 (K1) : `serie` unique de la ligne d'endurance [slot] ([faites] :
  /// ses séries faites, `SetRecord.toJson()`), comparée à la ligne servie
  /// affichée (ligne de Koach, ou ligne écrite servie telle quelle : c'est
  /// ce que l'athlète avait à faire), à défaut à la ligne écrite. Même
  /// format que l'item écrit de [koachSeanceDe] (`ExercisePrescription`).
  Json? _koachSerieLigne(
    int week,
    int j,
    SessionAdapt a,
    String slot,
    List<Json> faites,
  ) {
    final res = _koachRt.res;
    if (res == null || faites.isEmpty) return null;
    final fiche = res.fiches['${faites.first['exerciseId']}'];
    if (fiche == null) return null;
    Json? item = _adaptItem(a, slot)?.toJson().cast<String, Object?>();
    if (item == null) {
      for (final it in koachJourInfo(week, j)?.items ?? const <Json>[]) {
        if (it['slotId'] == slot) item = it;
      }
    }
    return koachSerieEndurance(fiche, item, faites, res.params);
  }

  /// RV2 (K1) : signature de la `serie` d'une ligne d'endurance (tous ses
  /// champs : un tour corrigé change la durée faite).
  static String _koachSigLigne(Json s) => 'E${fnv1a32(jsonEncode(s))}';

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
    // RV1 : rien versé au moteur pendant un arrêt d'urgence.
    if (!koachEngine.active) return;
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
    // RV2 (K4) : longueur du journal avant les séries versées et la
    // demande : un échec le coupe là (avant : séries versées gardées au
    // journal sans être notées dans la séance, versées une seconde fois au
    // passage suivant).
    final n0 = k.journal.length;
    final log2 = sessionLog(week, base.j);
    final adaptAvant = log2.adapt;
    try {
      _koachEnsureTarget(week, base, a, k, slot, served, index, log2, key);
    } catch (_) {
      _koachCouper(k, n0);
      log2.adapt = adaptAvant;
      _koachRt.live = null;
      return;
    }
    _adaptQuietSave();
  }

  /// [koachEnsureTarget] : séries faites versées, `plan(serie)`, cible
  /// gardée dans la séance [log2]. Une erreur se propage (l'appelant coupe
  /// le journal).
  void _koachEnsureTarget(
    int week,
    DayPlan base,
    SessionAdapt a,
    ko.Koach k,
    String slot,
    Json served,
    int index,
    SessionLog log2,
    String key,
  ) {
    final st = _koachVerse(week, base, a, k);
    final sw = Stopwatch()..start();
    final out = k.plan({'horizon': 'serie', 'item': served, 'index': index});
    _koachRt.temps.noter('plan_serie', sw.elapsed);
    debugKoachPanne?.call('plan_serie');
    Json? cible = out is Map ? out.cast<String, Object?>() : null;
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
    log2.adapt = next.toJson().cast<String, dynamic>();
    _adaptResync(week, base, a, next, log2, key);
    koachEngine.journal = k.journal;
  }

  /// RV2 (K4) : journal de [k] ramené à [n0] événements (échec d'un calcul
  /// après des versements). Le journal gardé est la même liste que celui du
  /// moteur vivant : rien de versé à moitié n'y reste.
  static void _koachCouper(ko.Koach k, int n0) {
    if (k.journal.length > n0) k.journal.removeRange(n0, k.journal.length);
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
        // Correctif 20/10/2026 : ligne servie en plage : la cible à reps
        // fixes de Koach prend la plage de la ligne.
        accessoryRangeTarget(
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
          it,
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
    // RV1 : charge fixée par le programme (C15) : pas de suggestion d'une
    // autre charge (toutes les propositions de Koach sont des charges ;
    // avant : « Je te propose 22,5 kg » sur 20 kg fixes, et « Valider »
    // pré-remplissait 22,5).
    out.remove('proposition');
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
    // RV1 : rien versé au moteur pendant un arrêt d'urgence.
    if (!koachEngine.active || !koachOpen(week, day.j)) return null;
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
        // RV2 (K4) : un échec coupe le journal à sa longueur d'avant.
        final n0 = k.journal.length;
        try {
          final st = _koachVerse(week, day, before, k);
          debugKoachPanne?.call('fin_exercice');
          final a2 = before.copyWith(koach: st);
          sessionLog(week, day.j).adapt = a2.toJson().cast<String, dynamic>();
          koachEngine.journal = k.journal;
          _adaptQuietSave();
        } catch (_) {
          _koachCouper(k, n0);
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
    // KB2 correction 1 : ligne servie telle qu'écrite par la garde.
    final ecrites = st['ecrites'];
    if (ecrites is List) {
      // (Une ligne au départ chronométré servie telle qu'écrite, PR8, est
      // la ligne du programme : emplacement relu.)
      final slot = e.slotId ?? adaptSlotOf(week, j, e.id);
      for (final x in ecrites) {
        if (x is Map && x['slotId'] == slot) {
          return koachTexteEcrite(x['cause'] as String?);
        }
      }
    }
    final id = e.catalogId;
    List<Map> pour(Object? raisons) => [
      if (raisons is List)
        for (final r in raisons)
          if (r is Map && _koachRaisonDe(r, id)) r,
    ];
    // KB3 : ligne au départ chronométré servie telle qu'écrite (PR8, nombre
    // de séries fixé par le programme) que le retour gradué de Koach 1.0.6
    // réduit : la carte garde les séries écrites et le dit.
    final slot0 = e.slotId ?? adaptSlotOf(week, j, e.id);
    if (adaptAsWritten(week, slot0)) {
      final n = koachJourInfo(
        week,
        j,
      )?.items.where((x) => x['slotId'] == slot0).firstOrNull?['sets'];
      for (final r in [...pour(st['raisons']), ...pour(st['ouverture'])]) {
        // La raison de cette ligne (séries écrites de la ligne), pas celle
        // d'une autre ligne du même exercice.
        if ((r['params'] as Map?)?['ecrites'] != n) continue;
        final t = koachTexteReduitEcrit(r);
        if (t != null) return t;
      }
      // KB4 : séries servies par Koach différentes de l'écrit (1.0.7 les
      // planifie à l'écrit : ne devrait plus se voir) ; rien sinon.
      final served = a == null || slot0 == null
          ? null
          : _koachServed(a, slot0)?['sets'];
      if (served is num && n is num) {
        final t = koachTexteEcartEcrit(served.round(), n.round());
        if (t != null) return t;
      }
    }
    // KB3 : raison la plus importante d'abord (ordre du contrat), sans
    // dépendre de l'ordre rendu par le moteur ; à défaut, raison de
    // structure de l'ouverture (séries réduites par le retour gradué,
    // tenue raccourcie, séance bornée), que `plan(serie)` efface.
    var choix = koachTrierRaisons(pour(st['raisons']));
    if (choix.isEmpty) {
      choix = koachTrierRaisons([
        for (final r in pour(st['ouverture']))
          if (kKoachRaisonsDeSeance.contains(r['code'])) r,
      ]);
    }
    if (choix.isEmpty) return null;
    return texteRaisonKoach(
      choix.first.cast<String, Object?>(),
      nomExercice: (x) => content.byId[x]?.nom,
    );
  }

  /// Raison [r] de Koach qui porte sur l'exercice [id] (sans exercice :
  /// raison générale, pour un exercice hors catalogue seulement).
  bool _koachRaisonDe(Map r, String? id) {
    final p = r['params'];
    final ex = p is Map ? p['exercice'] : null;
    if (ex != null && ex != id) return false;
    if (ex == null && id != null) return false;
    return true;
  }

  /// Raisons de la séance (dédoublonnées, textes lisibles) : renvois et
  /// raisons générales de l'ouverture (deux au plus à l'écran).
  List<String> koachSessionReasons(int week, int j, {int max = 2}) {
    final a = sessionAdapt(week, j);
    final st = a?.koach;
    final raisons0 = st?['raisons'];
    if (raisons0 is! List) return const [];
    // KB2 correction 1 : un retrait motivé se dit d'abord ; la raison d'un
    // retrait que la garde a annulé (ligne servie telle qu'écrite) ne se
    // dit pas.
    bool match(Object? r, Object? list, String key) {
      if (r is! Map || list is! List) return false;
      final p = r['params'];
      final ex = p is Map ? p['exercice'] : null;
      return list.any(
        (x) => x is Map && x['exercice'] == ex && x[key] == r['code'],
      );
    }

    // KB3 : retraits dits d'après les raisons de l'ouverture (gardées pour
    // la séance) ; ordre du contrat, pas celui du moteur.
    final ouverture = st?['ouverture'];
    final raisons = [
      ...koachTrierRaisons([
        for (final r in ouverture is List ? ouverture : raisons0)
          if (r is Map && match(r, st?['retraits'], 'code')) r,
      ]),
      ...koachTrierRaisons([
        for (final r in [...raisons0, if (ouverture is List) ...ouverture])
          if (r is Map &&
              !match(r, st?['retraits'], 'code') &&
              !match(r, st?['ecrites'], 'cause'))
            r,
      ]),
    ];
    // KB3 : une réduction de séries sur une ligne servie telle qu'écrite
    // (PR8) se dit sur sa carte (la ligne garde ses séries écrites), pas en
    // tête de séance.
    // (exercice, séries écrites) des lignes PR8 du jour.
    final ecritsPr8 = <String>{
      for (final x in koachJourInfo(week, j)?.items ?? const <Json>[])
        if (adaptAsWritten(week, '${x['slotId']}'))
          '${x['exerciseId']}|${x['sets']}',
    };
    raisons.removeWhere((r) {
      final p = r['params'];
      return koachTexteReduitEcrit(r) != null &&
          p is Map &&
          ecritsPr8.contains('${p['exercice']}|${p['ecrites']}');
    });
    final out = <String>[];
    for (final r in raisons) {
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
    // RV2 (K4) : copie du journal avant la fermeture (les corrections le
    // modifient en place) : un échec le remet tel quel, la séance reste
    // ouverte et se ferme au passage suivant (avant : séries et fin versées
    // gardées au journal, versées une seconde fois).
    final avant = koachJournalDe(k.journal);
    final SessionAdapt next;
    final bool fixed;
    try {
      final st2 = _koachVerse(week, base, a, k, fin: true);
      // Séries versées puis corrigées (flammes, répétitions, charge) ou
      // décochées : événements remplacés ou retirés, puis rejeu (§ 2.7).
      fixed = _koachCorrections(week, base, a, st2, k);
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
      debugKoachPanne?.call('seance_fin');
      st2['state'] = 'closed';
      next = a.copyWith(koach: st2);
    } catch (_) {
      // Journal gardé remis tel qu'avant la fermeture ; rejeu au prochain
      // passage.
      koachEngine.journal = avant;
      _koachRt.live = null;
      return;
    }
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
  }

  /// Corrections des séries déjà versées de la séance : chaque série dont
  /// la saisie a changé depuis son versement est remplacée à sa place dans
  /// le journal ; une série décochée en est retirée. Vrai si le journal a
  /// changé (le moteur vivant n'est plus à jour : rejeu).
  ///
  /// RV2 (K1) : la `serie` d'une ligne d'endurance (`[slot, 'E', …]`) est
  /// recalculée sur les séries faites de la ligne : remplacée si un tour a
  /// changé (ou s'est ajouté), retirée si plus aucun tour n'est validé.
  bool _koachCorrections(
    int week,
    DayPlan base,
    SessionAdapt a,
    Map<String, Object?> st,
    ko.Koach k,
  ) {
    final versed = (st['versed'] as List?) ?? const [];
    final now = <String, Json>{};
    final lignes = <String, List<Json>>{};
    for (final rec in _adaptDone(week, _koachDisplayDay(week, base, a), a)) {
      final slot = rec.slotId;
      if (slot == null) continue;
      if (_koachEndurance(rec.exerciseId) &&
          !_koachEnduranceAncienne(versed, slot)) {
        final l = lignes.putIfAbsent(slot, () => []);
        if (l.isEmpty || l.first['exerciseId'] == rec.exerciseId) {
          l.add(rec.toJson().cast<String, Object?>());
        }
        continue;
      }
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
    for (final e in lignes.entries) {
      final s = _koachSerieLigne(week, base.j, a, e.key, e.value);
      if (s != null) now['${e.key}|E'] = s;
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
      } else if ((v[1] == 'E' ? _koachSigLigne(cur) : _koachSig(cur)) !=
          v[2]) {
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
    // KB4 : un arrêt décidé avec dev7.4.0 ou suivant ne montre pas la
    // carte de la réactivation après 1.0.7.
    e.annonce107 ??= _kToday.iso;
    e.stop = {
      'since': _kToday.iso,
      'week': g,
      'modules': {
        for (final m in modules.entries) m.key: [m.value.$1, m.value.$2],
      },
    };
    // RV1 : un calcul en cours (rattrapage, rejeu) lancé avant l'arrêt ne
    // réinstalle pas le moteur vivant à sa fin (génération changée).
    _koachRt
      ..gen += 1
      ..busy = null;
    _koachRt.live = null;
    _koachBackToWritten();
    _g9Cache.clear();
    saveLogs();
    _persist();
    notifyListeners();
  }

  /// KB2 correction 1 (C17.36, point 6) : à l'arrêt d'urgence, une séance
  /// commencée et non finie servie par Koach revient à la séance écrite :
  /// séries validées ou saisies gardées telles quelles ; les autres
  /// reprennent le nombre et les valeurs du programme (cibles de Koach
  /// retirées). L'état de Koach de la séance est gardé (réactivation).
  void _koachBackToWritten() {
    final re = RegExp(r'^S(\d+)-J(\d+)$');
    for (final entry in logs.entries) {
      final log = entry.value;
      final st = log.adapt?['koach'];
      if (log.done || st is! Map || st['state'] != 'open') continue;
      final m = re.firstMatch(entry.key);
      if (m == null) continue;
      final week = int.parse(m[1]!), j = int.parse(m[2]!);
      if (week < 1 || week > program.weeks.length) continue;
      if (!koachStoppedWeek(week)) continue;
      final base = program.week(week).day(j);
      if (base == null) continue;
      for (final e in base.exercises) {
        final x = log.ex[e.id];
        if (x == null) continue;
        for (final s in x.sets) {
          if (s.done || s.edited) continue;
          s.kg = '';
          s.reps = '';
        }
        final n = setCount(e);
        while (x.sets.length > n && !x.sets.last.done && !x.sets.last.edited) {
          x.sets.removeLast();
        }
        while (x.sets.length < n) {
          x.addSet();
        }
      }
    }
  }

  /// Réactivation : rejeu du journal gardé, puis rattrapage de tout ce
  /// qui s'est passé depuis l'arrêt (séances versées sans `plan`).
  ///
  /// KB4 (C17.40.6) : les séances faites pendant l'arrêt sont versées au
  /// journal du moteur dans l'ordre (observations, jamais réécrites) ; une
  /// séance que Koach servait à l'arrêt et finie pendant l'arrêt est fermée
  /// (`seance_fin`) ; un aperçu d'avant l'arrêt d'une séance commencée ou
  /// faite telle qu'écrite pendant l'arrêt est retiré (elle reste telle
  /// quelle, hors de Koach) ; une séance que Koach servait, pas finie,
  /// reprend ses séries servies (séries notées gardées) ; Koach reprend à
  /// la première séance non faite, la modulation figée à l'arrêt est
  /// abandonnée (planification du moteur rejoué). Jamais automatique.
  Future<void> koachResume() async {
    final e = koachEngine;
    if (e.stop == null) return;
    e.stop = null;
    e.annonce107 ??= _kToday.iso;
    _koachRt.live = null;
    _koachReprise();
    _g9Cache.clear();
    saveLogs();
    _persist();
    notifyListeners();
    await koachRefresh();
  }

  /// KB4 : carte de l'accueil au premier lancement de dev7.4.0 avec Koach
  /// arrêté (arrêt décidé avant 1.0.7) : Koach ne coupe plus le programme
  /// pour le volume, « Réactiver Koach » proposé (jamais automatique).
  bool get koachAnnonceReprise {
    final e = koachEngine;
    return e.snap != null && e.stop != null && e.annonce107 == null;
  }

  /// KB4 : « Plus tard » sur la carte de reprise : elle ne revient pas (la
  /// réactivation reste dans Réglages et l'écran Koach).
  void koachAnnonceRepriseVue() {
    if (koachEngine.annonce107 != null) return;
    koachEngine.annonce107 = _kToday.iso;
    _persist();
    notifyListeners();
  }

  /// KB4 : état des séances à la réactivation (voir [koachResume]).
  void _koachReprise() {
    final re = RegExp(r'^S(\d+)-J(\d+)$');
    for (final entry in logs.entries) {
      final log = entry.value;
      final st = log.adapt?['koach'];
      if (st is! Map) continue;
      final started =
          log.done || log.ex.values.any((x) => x.sets.any((s) => s.done));
      if (st['state'] == 'preview' && started) {
        // Hors de Koach (bilan et lieu du jour gardés).
        log.adapt = {
          ...log.adapt!,
          'koach': {'state': 'ecrite', 'refus': 'arret', 'date': _kToday.iso},
        };
        continue;
      }
      if (st['state'] != 'open' || log.done) continue;
      final m = re.firstMatch(entry.key);
      if (m == null) continue;
      final week = int.parse(m[1]!), j = int.parse(m[2]!);
      if (week < 1 || week > program.weeks.length) continue;
      final base = program.week(week).day(j);
      final a = sessionAdaptOf(entry.key);
      if (base == null || a == null) continue;
      _adaptResync(week, base, a, a, log, entry.key);
    }
  }

  /// KB4 : la séance d'état Koach [st] (`open`) a son `seance_debut` au
  /// journal, encore ouvert (le dernier début, après la dernière fin, au
  /// même jour) : sa fermeture lui revient ; sinon elle se verse hors de
  /// Koach au rattrapage.
  bool _koachDebutOuvert(Map st) {
    final j = koachEngine.journal;
    for (var i = j.length - 1; i >= 0; i--) {
      final t = j[i]['type'];
      if (t == 'seance_fin') return false;
      if (t == 'seance_debut') {
        return (j[i]['jour'] as num?)?.toInt() == (st['jour'] as num?)?.toInt();
      }
    }
    return false;
  }

  /// KB4 : séances servies par Koach (`open`, début versé au journal),
  /// finies et pas encore versées : fermées dans l'ordre (séries restantes,
  /// `seance_fin`, décisions), comme à la fin d'une séance.
  Future<void> _koachCloseOrphans(int gen) async {
    final re = RegExp(r'^S(\d+)-J(\d+)$');
    final keys = <(int, int)>[];
    for (final entry in logs.entries) {
      final log = entry.value;
      final st = log.adapt?['koach'];
      if (!log.done || st is! Map || st['state'] != 'open') continue;
      if (koachEngine.versed.contains(entry.key)) continue;
      if (!_koachDebutOuvert(st)) continue;
      final m = re.firstMatch(entry.key);
      if (m == null) continue;
      keys.add((int.parse(m[1]!), int.parse(m[2]!)));
    }
    keys.sort((a, b) {
      final c = a.$1.compareTo(b.$1);
      return c != 0 ? c : a.$2.compareTo(b.$2);
    });
    for (final (week, j) in keys) {
      if (week < 1 || week > program.weeks.length) continue;
      if (_koachRt.live == null) await _koachEnsureLive(gen);
      if (gen != _koachRt.gen || _koachRt.live == null) return;
      koachOnSessionDone(week, j);
    }
    if (_koachRt.live == null) await _koachEnsureLive(gen);
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
    final gen = _koachRt.gen;
    // RV2 (K3) : longueur du journal de l'instance vive au départ du calcul.
    final n0 = k.journal.length;
    ko.Koach next;
    try {
      next = await KoachCalcul.observer(k, ev);
    } catch (_) {
      if (identical(_koachRt.live, k)) _koachRt.live = null;
      return;
    }
    final avantAdoption = KoachCalcul.debugAvantAdoption;
    if (avantAdoption != null) await avantAdoption();
    // RV2 (K3) : arrêt pendant le calcul, ou événements versés à
    // l'instance vive pendant le calcul et impossibles à rejouer : résultat
    // abandonné (la référence se verse au prochain passage, `refSig`
    // inchangée).
    if (gen != _koachRt.gen || !_koachAdopter(k, next, n0)) return;
    _koachRt.live = next;
    e
      ..journal = next.journal
      ..refSig = _koachRefSig();
    _koachRt.temps.noter('replanification', sw.elapsed);
    _persist();
    notifyListeners();
  }

  /// RV2 (K3) : adoption de [next], calculé hors du fil sur une copie de
  /// l'instance vive [k] dont le journal comptait [n0] événements. Pendant
  /// le calcul, la séance a pu verser à [k] (début de séance, séries,
  /// `plan`, fin) : ces événements sont rejoués sur [next] dans l'ordre,
  /// après ceux du calcul, et les rangs gardés par les séances ouvertes
  /// (`versed`, lus par les corrections de fin de séance) sont décalés du
  /// nombre d'événements versés par le calcul. Faux : résultat abandonné
  /// (instance vive changée : arrêt, échec, rejeu demandé ; journal coupé
  /// ou corrigé pendant le calcul ; rejeu impossible) : l'instance vive et
  /// son journal restent tels quels, le calcul se refait au prochain
  /// passage. Vrai sans rien faire pour un calcul sur place ([next] est
  /// [k], tests).
  bool _koachAdopter(ko.Koach k, ko.Koach next, int n0) {
    if (identical(next, k)) return true;
    if (!identical(_koachRt.live, k)) return false;
    final n = k.journal.length;
    final ajout = next.journal.length - n0;
    if (n < n0 || ajout < 0) return false;
    if (n == n0) return true;
    try {
      for (var i = n0; i < n; i++) {
        next.observe(koachCopie(k.journal[i]) as Json);
      }
    } catch (_) {
      return false;
    }
    if (ajout == 0) return true;
    for (final log in logs.values) {
      final adapt = log.adapt;
      final st = adapt?['koach'];
      if (adapt == null || st is! Map) continue;
      final versed = st['versed'];
      if (versed is! List) continue;
      var moved = false;
      final out = <Object?>[];
      for (final v in versed) {
        final i = v is List && v.length >= 4 ? v[3] : null;
        if (v is List && i is int && i >= n0) {
          out.add([...v.take(3), i + ajout, ...v.skip(4)]);
          moved = true;
        } else {
          out.add(v);
        }
      }
      if (!moved) continue;
      log.adapt = {
        ...adapt,
        'koach': {...st.cast<String, Object?>(), 'versed': out},
      };
    }
    _adaptQuietSave();
    return true;
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
    // KB2 correction 1 : séance écrite après une réponse refusée, gardée le
    // jour même ; un autre jour, pas commencée, elle redevient l'aperçu
    // (Koach la sert, la question revient).
    final stale =
        st != null &&
        st['state'] == 'ecrite' &&
        !started &&
        st['date'] != _kToday.iso;
    if (st != null && st['state'] != 'preview' && !stale) return stored;
    if (started) {
      if (stored != null && st == null) return stored;
      // KB4 : une séance faite n'est jamais commencée par Koach après coup
      // (aperçu périmé d'une séance faite hors de lui).
      if (log.done) return stored;
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
      if (koachStartedBefore(week, d.j)) continue;
      final out = <Exercise>[];
      var changed = false;
      for (final e in d.exercises) {
        final slot = imp.slotOf(week, d.j, e.id);
        final m = slot == null ? null : koachWeekLine(week, d.j, slot);
        if (m == null) {
          out.add(e);
          continue;
        }
        // (KB4 : `koachWeekLine` ne rend jamais 0 série : aucune ligne
        // écrite retirée de la semaine.)
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
    // KB2 correction 1 : séance écrite (réponse refusée) : pas de résumé de
    // Koach.
    if (st['state'] == 'ecrite') return null;
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
    // KB1 : versions du moteur qui rejoue le journal (celui de ce build) ;
    // une prise de main faite par une version d'avant (session de test de
    // dev7.1.x) garde la sienne à part, le journal est rejoué par 1.0.5.
    return {
      'type': 'journal_moteur',
      'version': 1,
      'version_moteur': ko.koachVersion,
      'version_parametres': res.versionParametres,
      'sha256_parametres': ko.koachParametresSha256,
      if (snap.versionMoteur != ko.koachVersion ||
          snap.shaParametres != ko.koachParametresSha256)
        'prise_de_main': {
          'version_moteur': snap.versionMoteur,
          'version_parametres': snap.versionParametres,
          'sha256_parametres': snap.shaParametres,
        },
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
