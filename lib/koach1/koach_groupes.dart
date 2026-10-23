// KB5 (dev7.7.0, Koach 1.0.8, `kalis_adapt` 1.0.7 ; DECISIONS_CP.md
// C17.47, C17.48 ; INTEGRATION_KM3.md § 12) — groupes et techniques de la
// séance servie par Koach.
//
// - Groupes (X2, X7) : l'application passe les `GroupSpec` de la séance
//   écrite à `plan({'horizon': 'seance', …, 'groups': […]})` et lit les
//   `groups` recalés de la sortie (tours et durée d'un EMOM au temps sur
//   les lignes servies). Quand l'application remplace une ligne servie
//   (ligne au départ chronométré servie telle qu'écrite, PR8 ; intervalles
//   servis tels qu'écrits, C17.44.4 ; ligne écrite gardée par
//   `koachGardeSeance`), le groupe est recalé par la même règle sur les
//   lignes réellement servies ([koachGroupesServis] : `groupesServis` du
//   moteur lui-même) : chrono, tours et lignes restent d'accord.
// - Technique (X3) : Koach 1.0.8 rend une technique cohérente avec `sets` ;
//   [koachTechniqueCoherente] (`techniqueCoherente` du moteur, port de
//   `coherentTechnique` de `kalis_adapt` 0.x) reste une sécurité de
//   l'application : une séance servie n'est jamais refusée pour un nombre
//   d'intervalles d'EMOM ou de séries allégées qui ne tombe pas juste.
//
// Fonctions pures (testées : test/kb5_koach108_test.dart).
import 'package:kalis_adapt/koach.dart' as ko;
import 'package:kalis_core/kalis_core.dart' as kc;

/// Groupes [groupes] (JSON du contrat, séance écrite) recalés sur les
/// lignes [servis] (JSON des items servis), [ecrits] étant les items écrits
/// du jour : la règle du moteur lui-même (`groupesServis` de Koach 1.0.8,
/// `seance.dart`, exportée par `package:kalis_adapt/koach.dart`), pour que
/// l'application et Koach ne divergent jamais :
///
/// - un groupe sans membre servi (toutes ses lignes retirées) disparaît ;
/// - tours : quand les tours écrits valent le nombre de séries écrites des
///   membres (le plus grand ; contre la montre, le plus petit), ils
///   deviennent celui des membres servis ;
/// - EMOM au temps : une durée qui compte les lignes écrites (intervalle ×
///   lignes) devient intervalle × lignes servies ; une durée qui compte les
///   tours (E2MOM A/B : 8 tours, 960 s) suit les tours.
///
/// Les séries écrites d'un item sont `sets − koachVolume`. Pur.
List<Map<String, Object?>> koachGroupesServis(
  List<Map<String, Object?>> groupes,
  List<Map<String, Object?>> ecrits,
  List<Map<String, Object?>> servis,
) => ko.groupesServis(groupes, ecrits, servis);

/// Groupes lus d'une sortie de `plan(seance)` (`groups`) ; null : sortie
/// sans groupes (moteur d'avant 1.0.8) ou illisible.
List<kc.GroupSpec>? koachGroupesDeSortie(Object? groups) {
  if (groups is! List) return null;
  try {
    return [
      for (final g in groups)
        kc.GroupSpec.fromJson(Map<String, Object?>.from(g as Map)),
    ];
  } catch (_) {
    return null;
  }
}

/// KB5 (X2) : groupes de la séance servie. [ecrits] : groupes de la
/// journée écrite ; [moteur] : groupes recalés rendus par Koach (null :
/// non rendus) ; [itemsEcrits] : items écrits du jour (JSON) ; [servis] :
/// lignes réellement servies (après les remplacements de l'application).
///
/// Chaque groupe est recalé par [koachGroupesServis] (la règle du moteur)
/// sur les lignes réellement servies ; quand le résultat est celui que
/// Koach rend, c'est le groupe du moteur qui sert. Sinon (ligne remplacée
/// ou écartée par l'application, groupe absent de la sortie) le groupe
/// recalé sert et son identifiant est rendu dans `recales` (diagnostic du
/// mode dev). Un groupe sans membre servi n'est plus déclaré. Pur.
({List<kc.GroupSpec>? groupes, List<String> recales}) koachGroupesDeLaSeance(
  List<kc.GroupSpec>? ecrits,
  List<kc.GroupSpec>? moteur,
  List<Map<String, Object?>> itemsEcrits,
  List<kc.ExercisePrescription> servis,
) {
  if (ecrits == null) return (groupes: null, recales: const []);
  final parMoteur = {
    for (final g in moteur ?? const <kc.GroupSpec>[]) g.groupId: g,
  };
  final out = <kc.GroupSpec>[];
  final recales = <String>[];
  for (final r in koachGroupesServis(
    [for (final g in ecrits) g.toJson().cast<String, Object?>()],
    itemsEcrits,
    [for (final it in servis) it.toJson().cast<String, Object?>()],
  )) {
    final id = '${r['groupId']}';
    final m = parMoteur[id];
    if (m != null && _memeJson(m.toJson(), r)) {
      out.add(m);
      continue;
    }
    try {
      out.add(kc.GroupSpec.fromJson(r));
    } catch (_) {
      out.add(ecrits.firstWhere((g) => g.groupId == id));
    }
    recales.add(id);
  }
  return (groupes: out, recales: recales);
}

bool _memeJson(Map<String, Object?> a, Map<String, Object?> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    final v = b[e.key];
    final w = e.value;
    if (w is num && v is num ? w != v : w != v) return false;
  }
  return true;
}

/// La prescription [item] dont la technique est rendue cohérente avec son
/// nombre de lignes (`sets`) par la règle du moteur (`techniqueCoherente`
/// de Koach 1.0.8, port de `coherentTechnique` de `kalis_adapt` 0.x) :
/// séries allégées et intervalles d'un EMOM recomptés ; paliers (vagues,
/// pyramide, échelle) ou bloc au temps dont le nombre de lignes ne tient
/// plus : séries classiques ; `setTargets` ramenés à `sets` éléments.
/// Sécurité de l'application (Koach 1.0.8 rend déjà une technique
/// cohérente, X3) : [item] lui-même quand rien ne change ou si la
/// prescription recomposée est illisible. Pur.
kc.ExercisePrescription koachTechniqueCoherente(kc.ExercisePrescription item) {
  final j = item.toJson().cast<String, Object?>();
  if (!ko.techniqueCoherente(j)) return item;
  try {
    return kc.ExercisePrescription.fromJson(j);
  } catch (_) {
    return item;
  }
}
