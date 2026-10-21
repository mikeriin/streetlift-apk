// Validateur de sécurité de la planification de Koach (lot KM2) : la
// fonction `Validateur` que demande `Planification`, aux constats de
// `safetyFindings` du banc (copiés dans `securite.dart`).
//
// Au banc, le validateur est construit par `kalis_bench/lib/src/km/
// politique_koach.dart` (`_validateur`) et `criteres_moteur.dart`
// (`KmConstatsSaison`) : blocs JSON relus en `ProgramBlock`, réduits à
// leurs semaines servies (`kmServedBlocks`, copié ici le 2026-10-10 dans
// `blocsServis`), lus jusqu'à l'horizon de la saison.
import 'package:kalis_core/kalis_core.dart';

import '../koach/koach.dart' show Json, Validateur;
import 'profil.dart';
import 'securite.dart';

/// Blocs tels qu'ils ont été servis (`kmServedBlocks`, `servedBlocksOf` du
/// banc) : [blockWeeks] donne la semaine de saison où chaque bloc
/// commence ; un bloc arrêté avant son terme est réduit à ses semaines
/// servies. Sans [blockWeeks], les blocs sont pris entiers.
List<ProgramBlock> blocsServis(
  List<ProgramBlock> blocs,
  List<int>? blockWeeks,
) {
  if (blockWeeks == null) {
    return blocs;
  }
  final out = <ProgramBlock>[];
  for (var k = 0; k < blocs.length; k++) {
    final b = blocs[k];
    if (k + 1 < blockWeeks.length) {
      final served = blockWeeks[k + 1] - blockWeeks[k];
      if (served >= 1 && served < b.pass2.weeks.length) {
        out.add(
          ProgramBlock(
            pass1: b.pass1.copyWith(weeks: served),
            pass2: b.pass2.copyWith(weeks: b.pass2.weeks.sublist(0, served)),
          ),
        );
        continue;
      }
    }
    out.add(b);
  }
  return out;
}

/// Constats de sécurité des blocs JSON [blocs] (objets de
/// `ProgramBlock.toJson`), au format `Finding.toJson` du banc : blocs
/// réduits à leurs semaines servies selon [blockWeeks], lus jusqu'à
/// [horizonSemaines] semaines, pour le profil [profil].
List<Json> constatsDesBlocs(
  List<Json> blocs, {
  required Catalog catalog,
  required ProfilValidation profil,
  required int horizonSemaines,
  List<int>? blockWeeks,
}) {
  final blocks = <ProgramBlock>[
    for (final b in blocs) ProgramBlock.fromJson(b),
  ];
  return <Json>[
    for (final f in constatsSecurite(
      catalog: catalog,
      profil: profil,
      blocs: blocsServis(blocks, blockWeeks),
      horizonSemaines: horizonSemaines,
    ))
      f.toJson(),
  ];
}

/// Validateur de sécurité de `Planification` (Koach 1.0) : fonction(blocs
/// JSON) → constats `{code, message, week, dayIndex, exerciseId, value,
/// limit}`, les mêmes que ceux du banc (`safetyFindings`) pour le même
/// profil, les mêmes [blockWeeks] (semaine de début de chaque bloc ;
/// `null` : blocs entiers) et le même horizon [horizonSemaines] (semaines
/// lues au plus).
///
/// Dans l'application : `profil` vient de `ProfilValidation.depuisProfil`
/// (profil d'athlète et premier jour du programme), `blockWeeks` et
/// `horizonSemaines` sont ceux passés à `Planification.chargerReference`.
Validateur validateurSecurite({
  required Catalog catalog,
  required ProfilValidation profil,
  required int horizonSemaines,
  List<int>? blockWeeks,
}) {
  final weeks = blockWeeks == null ? null : List<int>.unmodifiable(blockWeeks);
  return (List<Json> blocs) => constatsDesBlocs(
    blocs,
    catalog: catalog,
    profil: profil,
    horizonSemaines: horizonSemaines,
    blockWeeks: weeks,
  );
}
