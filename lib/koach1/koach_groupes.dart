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

typedef _Json = Map<String, Object?>;

int _ent(Object? v) => v is num ? v.round() : 0;

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
List<_Json> koachGroupesServis(
  List<_Json> groupes,
  List<_Json> ecrits,
  List<_Json> servis,
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
/// non rendus) ; [itemsEcrits] : items écrits du jour (JSON) ; [servisMoteur]
/// : items servis par Koach (JSON, avant les remplacements de
/// l'application) ; [servis] : lignes réellement servies.
///
/// Un groupe dont toutes les lignes servies sont celles du moteur (mêmes
/// séries) est pris tel que Koach le rend ; sinon (ligne remplacée par
/// l'application, groupe absent de la sortie) il est recalé par
/// [koachGroupesServis] sur les lignes servies. Rend aussi les groupes
/// recalés par l'application (diagnostic du mode dev). Pur.
({List<kc.GroupSpec>? groupes, List<String> recales}) koachGroupesDeLaSeance(
  List<kc.GroupSpec>? ecrits,
  List<kc.GroupSpec>? moteur,
  List<_Json> itemsEcrits,
  List<_Json> servisMoteur,
  List<kc.ExercisePrescription> servis,
) {
  if (ecrits == null) return (groupes: null, recales: const []);
  final servisJson = [
    for (final it in servis) it.toJson().cast<String, Object?>(),
  ];
  final recalage = {
    for (final g in koachGroupesServis(
      [for (final g in ecrits) g.toJson().cast<String, Object?>()],
      itemsEcrits,
      servisJson,
    ))
      '${g['groupId']}': g,
  };
  final parMoteur = {
    for (final g in moteur ?? const <kc.GroupSpec>[]) g.groupId: g,
  };
  final seriesMoteur = <String, int>{
    for (final it in servisMoteur)
      if (it['groupId'] != null) '${it['slotId']}': _ent(it['sets']),
  };
  final out = <kc.GroupSpec>[];
  final recales = <String>[];
  for (final g in ecrits) {
    final r = recalage[g.groupId];
    if (r == null) continue; // aucun membre servi
    final membres = [
      for (final it in servis)
        if (it.groupId == g.groupId && it.sets > 0) it,
    ];
    final m = parMoteur[g.groupId];
    final commeLeMoteur =
        m != null && membres.every((it) => seriesMoteur[it.slotId] == it.sets);
    if (commeLeMoteur) {
      out.add(m);
      continue;
    }
    try {
      out.add(kc.GroupSpec.fromJson(r));
      recales.add(g.groupId);
    } catch (_) {
      out.add(g);
    }
  }
  return (groupes: out, recales: recales);
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
