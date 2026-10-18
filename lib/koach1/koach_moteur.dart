// KM3 (cahier CAHIER_KM.md, DECISIONS_CP.md C13, C17.14) : Koach 1.0
// (`kalis_adapt` 1.0.x, `package:kalis_adapt/koach.dart`) dans
// l'application. Ce fichier construit le moteur, le rejoue et le fait
// calculer hors du fil d'interface ; il ne lit ni n'écrit aucun stockage
// et ne connaît ni Flutter ni le magasin (koach1_store.dart fait le lien).
//
// Guide suivi : packages/kalis_adapt/docs/INTEGRATION_KM3.md (§ 1.2 :
// construction ; § 1.5 : fil d'exécution ; § 2.7 : instantanés gardés à
// côté du journal ; § 8 point 4 : rejeu exact).
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:kalis_adapt/koach.dart' as ko;
import 'package:kalis_adapt/validateur.dart' as kv;
import 'package:kalis_core/kalis_core.dart' as kc;

typedef Json = Map<String, Object?>;

/// Chemins des deux assets de Koach (copies à l'octet de
/// `packages/kalis_adapt/assets/koach/`, INTEGRATION_KM3.md § 3 ; KB1 :
/// Koach 1.0.5, `kalis_adapt` 1.0.4, paramètres `1.0.5-ref.1`).
const kKoachParamsAsset = 'assets/koach/koach_params_1_0_5.json';
const kKoachFichesAsset = 'assets/koach/vecteurs_qualites_v1.json';

/// Ordre des extensions (celui du banc, `PolitiqueKoach.debut`) : c'est
/// l'ordre des crochets et des modulations appliquées par `plan`.
const kKoachExtensions = <String>[
  'planification',
  'surveillance',
  'dual',
  'adherence',
];

/// Paramètres initiaux et fiches, décodés et contrôlés une fois
/// (`lireParametresKoach`, `lireFichesKoach`).
class KoachRessources {
  final Json params;
  final Map<String, Json> fiches;
  const KoachRessources(this.params, this.fiches);

  /// Lit les deux textes des assets ; [FormatException] hors contrat.
  factory KoachRessources.lire(String paramsText, String fichesText) =>
      KoachRessources(
        ko.lireParametresKoach(paramsText),
        ko.lireFichesKoach(fichesText),
      );

  String get versionParametres => '${params['version']}';
}

/// Ce qui est hors du journal et doit être repris tel quel au rejeu
/// (INTEGRATION_KM3.md § 2.7, § 8 point 4) : profil de Koach, profil
/// d'athlète du validateur et lundi de S1, mouvements principaux du
/// contrôle dual, ordre des extensions, versions et empreintes.
class KoachInstantane {
  /// Profil lu par Koach (`niveau`, `sexe`, `poids_kg`, `declares`,
  /// `zones_fragiles`).
  final Json profil;

  /// Profil d'athlète (`kalis_core`, JSON) d'où vient le profil de
  /// validation (`ProfilValidation.depuisProfil`).
  final Json athlete;

  /// Lundi de la semaine S1 (jour 0 du moteur), AAAA-MM-JJ.
  final String lundi;

  /// Mouvements principaux chargés (contrôle dual), triés.
  final List<String> lifts;
  final List<String> extensions;
  final String versionMoteur;
  final String versionParametres;
  final String shaParametres;
  final String shaFiches;

  const KoachInstantane({
    required this.profil,
    required this.athlete,
    required this.lundi,
    required this.lifts,
    this.extensions = kKoachExtensions,
    required this.versionMoteur,
    required this.versionParametres,
    required this.shaParametres,
    required this.shaFiches,
  });

  kc.CivilDate get lundiDate => kc.CivilDate.parse(lundi);

  Json toJson() => {
    'profil': profil,
    'athlete': athlete,
    'lundi': lundi,
    'lifts': lifts,
    'extensions': extensions,
    'version_moteur': versionMoteur,
    'version_parametres': versionParametres,
    'sha256_parametres': shaParametres,
    'sha256_fiches': shaFiches,
  };

  static KoachInstantane fromJson(Object? raw) {
    if (raw is! Map) throw const FormatException('Instantané de Koach.');
    final m = raw.cast<String, Object?>();
    String s(String k) {
      final v = m[k];
      if (v is! String || v.isEmpty || v.length > 200) {
        throw FormatException('Instantané de Koach : $k.');
      }
      return v;
    }

    final profil = m['profil'];
    final athlete = m['athlete'];
    final lifts = m['lifts'];
    final ext = m['extensions'];
    if (profil is! Map || athlete is! Map || lifts is! List || ext is! List) {
      throw const FormatException('Instantané de Koach.');
    }
    kc.CivilDate.parse(s('lundi'));
    return KoachInstantane(
      profil: _copie(profil) as Json,
      athlete: _copie(athlete) as Json,
      lundi: s('lundi'),
      lifts: [for (final x in lifts) x as String],
      extensions: [for (final x in ext) x as String],
      versionMoteur: s('version_moteur'),
      versionParametres: s('version_parametres'),
      shaParametres: s('sha256_parametres'),
      shaFiches: s('sha256_fiches'),
    );
  }
}

/// Copie JSON profonde (cartes et listes rendues modifiables, clés texte).
Object? _copie(Object? v) {
  if (v is Map) {
    return <String, Object?>{
      for (final e in v.entries) '${e.key}': _copie(e.value),
    };
  }
  if (v is List) return [for (final x in v) _copie(x)];
  return v;
}

/// Copie JSON profonde publique.
Object? koachCopie(Object? v) => _copie(v);

/// Temps de calcul mesurés par l'application (inspecteur du mode dev ;
/// cahier : replanification ≤ 10 s, série ≤ 50 ms).
class KoachTemps {
  final Map<String, List<int>> _us = {};

  void noter(String quoi, Duration d) {
    final l = _us.putIfAbsent(quoi, () => []);
    l.add(d.inMicroseconds);
    if (l.length > 50) l.removeAt(0);
  }

  /// Dernière mesure et maximum (millisecondes) par opération.
  Map<String, ({double dernier, double max, int n})> get resume => {
    for (final e in _us.entries)
      if (e.value.isNotEmpty)
        e.key: (
          dernier: e.value.last / 1000,
          max: e.value.reduce((a, b) => a > b ? a : b) / 1000,
          n: e.value.length,
        ),
  };

  Json toJson() => {
    for (final e in resume.entries)
      e.key: {'dernier_ms': e.value.dernier, 'max_ms': e.value.max},
  };
}

/// Fabrique du moteur : un objet `Koach` avec ses quatre extensions dans
/// l'ordre du banc, le validateur de sécurité à lecture tardive.
class KoachFabrique {
  final KoachRessources res;
  final KoachInstantane snap;
  final kc.Catalog catalog;

  KoachFabrique(this.res, this.snap, this.catalog);

  kv.ProfilValidation get _validation => kv.ProfilValidation.depuisProfil(
    kc.AthleteProfile.fromJson(snap.athlete),
    debut: snap.lundiDate,
  );

  /// Constructeurs des extensions, dans l'ordre de l'instantané.
  List<ko.Extension Function()> fabriques() {
    final validation = _validation;
    return [
      for (final nom in snap.extensions)
        switch (nom) {
          'planification' => () {
            late final ko.Planification pl;
            pl = ko.Planification(
              res.params,
              res.fiches,
              (blocs) => kv.constatsDesBlocs(
                blocs,
                catalog: catalog,
                profil: validation,
                // Lecture tardive : horizon et débuts de bloc du dernier
                // `reference` (INTEGRATION_KM3.md § 1.3).
                horizonSemaines: pl.horizon,
                blockWeeks: pl.blockWeeks,
              ),
            );
            return pl;
          },
          'surveillance' => () => ko.Surveillance(res.params),
          'dual' => () => ko.ControleDual(res.params, List.of(snap.lifts)),
          'adherence' => () => ko.Adherence(res.params),
          _ => throw FormatException('Extension inconnue : $nom'),
        },
    ];
  }

  /// Moteur neuf (journal vide).
  ko.Koach neuf() => rejouer(const []);

  /// Moteur reconstruit depuis [journal] (même journal = même état).
  ko.Koach rejouer(List<Json> journal) =>
      ko.rejouer(res.params, res.fiches, snap.profil, journal, fabriques());
}

/// Lecteurs commodes des extensions d'un moteur.
extension KoachExtensions on ko.Koach {
  ko.Planification? get planification =>
      extensions.whereType<ko.Planification>().firstOrNull;
  ko.Surveillance? get surveillance =>
      extensions.whereType<ko.Surveillance>().firstOrNull;
  ko.ControleDual? get dual =>
      extensions.whereType<ko.ControleDual>().firstOrNull;
  ko.Adherence? get adherence =>
      extensions.whereType<ko.Adherence>().firstOrNull;
}

/// Calcul hors du fil d'interface. Les tests remplacent [enArrierePlan]
/// par un calcul direct (même résultat : le moteur est déterministe).
class KoachCalcul {
  KoachCalcul._();

  /// Vrai : calcul dans un isolat (application) ; faux : sur place (tests).
  static bool isolat = true;

  /// Rattrapage ([koachRattraper]) sur une copie de [k] hors du fil
  /// d'interface, rendue modifiée (INTEGRATION_KM3.md § 1.5 : aucun autre
  /// événement n'est versé pendant le calcul, puis l'instance rendue
  /// remplace l'instance vive). Une erreur se propage : l'appelant garde
  /// l'instance d'avant. Les fermetures envoyées à l'isolat sont créées
  /// ici, jamais dans le magasin : leur contexte ne doit porter que des
  /// données envoyables (le magasin ne l'est pas).
  static Future<ko.Koach> rattraper(ko.Koach k, List<KoachEtape> steps) {
    if (!isolat) {
      koachRattraper(k, steps);
      return Future.value(k);
    }
    return Isolate.run(() {
      koachRattraper(k, steps);
      return k;
    });
  }

  /// Un événement [ev] versé à une copie de [k] hors du fil d'interface.
  static Future<ko.Koach> observer(ko.Koach k, Json ev) {
    if (!isolat) {
      k.observe(ev);
      return Future.value(k);
    }
    return Isolate.run(() {
      k.observe(ev);
      return k;
    });
  }

  /// Rejeu complet hors du fil d'interface.
  static Future<ko.Koach> rejouer(KoachFabrique fab, List<Json> journal) async {
    if (!isolat) return fab.rejouer(journal);
    return Isolate.run(() => fab.rejouer(journal));
  }
}

/// Journal relu depuis le document (copie JSON profonde, aller-retour
/// texte comme au banc : `rejouerJournal`).
List<Json> koachJournalDe(Object? raw) {
  if (raw is! List) return [];
  return [
    for (final e in jsonDecode(jsonEncode(raw)) as List<Object?>)
      if (e is Map) e.cast<String, Object?>(),
  ];
}

/// Étape du rattrapage du lundi : un événement à verser, ou la proposition
/// d'essai N-of-1 du contrôle dual après la fin de la semaine [semaine]
/// (INTEGRATION_KM3.md § 2.2, point 1c).
class KoachEtape {
  final Json? evenement;
  final int? semaine;
  final List<int> echeances;
  const KoachEtape.evenement(Json this.evenement)
    : semaine = null,
      echeances = const [];
  const KoachEtape.essai(int this.semaine, this.echeances) : evenement = null;
}

/// Témoins au plus d'un essai N-of-1 (`ControleDualBanc.temoinsMax`).
const kKoachTemoinsMax = 6;

/// Verse les étapes [etapes] dans l'ordre (fonction sans contexte : elle
/// tourne aussi dans un isolat).
void koachRattraper(ko.Koach k, List<KoachEtape> etapes) {
  for (final e in etapes) {
    final ev = e.evenement;
    if (ev != null) {
      k.observe(ev);
      continue;
    }
    _koachProposerEssai(k, e.semaine!, e.echeances);
  }
}

/// Proposition d'essai du contrôle dual, comme au banc
/// (`_ControleDualBanc.apresSemaine`) : seulement si le modèle est calibré
/// et qu'aucun essai ne tourne ; cible : le lift principal de plus petite
/// demi-largeur ; témoins : exercices présents dans les 8 dernières
/// semaines du contrôle synthétique ; contexte obligatoire.
void _koachProposerEssai(ko.Koach k, int semaine, List<int> echeances) {
  final dual = k.dual;
  if (dual == null || dual.essai != null || dual.lifts.isEmpty) return;
  final (ok, _) = ko.calibre(k, dual.lifts);
  if (!ok) return;
  final demi = <String, double>{};
  for (final ex in dual.lifts) {
    final c = k.modele.capacite(ex);
    if (c != null) demi[ex] = ko.z90 * c.$2;
  }
  String? cible;
  var cibleDemi = 0.0;
  for (final ex in dual.lifts) {
    final d = demi[ex] ?? 1.0;
    if (cible == null ||
        d < cibleDemi ||
        (d == cibleDemi && ex.compareTo(cible) < 0)) {
      cible = ex;
      cibleDemi = d;
    }
  }
  final pre = dual.pre;
  final recents = pre.length >= 8 ? pre.sublist(pre.length - 8) : pre;
  final temoins = <String>[];
  if (recents.isNotEmpty) {
    final cles =
        ((recents.last['mu'] as Map?)?.keys.map((x) => '$x') ?? []).toList()
          ..sort();
    for (final ex in cles) {
      if (ex == cible) continue;
      if (recents.every((x) => (x['mu'] as Map).containsKey(ex))) {
        temoins.add(ex);
      }
    }
  }
  final prochaine = semaine + 1;
  final graine =
      ((k.params['planification'] as Map?)?['graine'] as num?)?.toInt() ?? 0;
  k.observe({
    'type': 'decision',
    'jour': 7 * prochaine,
    'essai': {
      'semaine': prochaine,
      'cible': {'exerciseId': cible},
      'traites': [cible],
      'temoins': temoins.length > kKoachTemoinsMax
          ? temoins.sublist(0, kKoachTemoinsMax)
          : temoins,
      'contexte': dual.contexteEssai(k, prochaine, echeances),
      'graine': graine,
      'n_bras': null,
    },
  });
}

/// Prévision de la première série d'une séance future (C15.4,
/// INTEGRATION_KM3.md § 7.3) : sur une COPIE du moteur (jamais l'instance
/// vive : `plan` n'est pas un aperçu), `seance_debut` au jour réel,
/// `plan(seance)` sur les items écrits, puis `plan(serie)` index 0 pour
/// chaque emplacement demandé. Rend {slotId : cible}.
class KoachPrevision {
  final Json debut;
  final Json seance;
  final List<String> slots;
  const KoachPrevision(this.debut, this.seance, this.slots);
}

Map<String, Json?> koachPrevoir(ko.Koach k, KoachPrevision p) {
  k.observe(p.debut);
  final r = k.plan(p.seance)! as Map;
  final out = <String, Json?>{};
  for (final slot in p.slots) {
    Json? item;
    for (final it in (r['items'] as List? ?? const [])) {
      if (it is Map && it['slotId'] == slot) item = it.cast<String, Object?>();
    }
    if (item == null) {
      out[slot] = null;
      continue;
    }
    final c = k.plan({'horizon': 'serie', 'item': item, 'index': 0});
    out[slot] = c is Map ? c.cast<String, Object?>() : null;
  }
  return out;
}

/// Prévisions sur une copie : dans un isolat (la copie est celle du
/// passage de message), sinon par rejeu (tests).
Future<Map<String, Json?>> koachPrevoirCopie(
  ko.Koach live,
  KoachFabrique fab,
  KoachPrevision p,
) async {
  if (KoachCalcul.isolat) {
    return Isolate.run(() => koachPrevoir(live, p));
  }
  final copie = fab.rejouer(koachJournalDe(live.journal));
  return koachPrevoir(copie, p);
}
