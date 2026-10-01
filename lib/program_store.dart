// L10 (KT-050 à KT-057) puis G7 — programme en place côté magasin.
//
// G7 retire le générateur L10 (D1.4) : `kalis_plan` crée désormais le
// programme (plan_store.dart). Restent ici : le catalogue de l'ancien pack
// (L11 jusqu'à son retrait en G10) et la lecture des instances L10
// existantes (« generated »), affichées telles quelles. Sans instance, le
// programme embarqué reste exactement celui de 3.2.0 : modèle « Expert
// streetlifting » implicite.
part of 'store.dart';

/// Catalogue de l'ancien pack (L11), chargé une fois à la demande.
class ProgramAssets {
  final GenCatalog catalog;
  const ProgramAssets(this.catalog);

  static Future<ProgramAssets>? _pending;
  static ProgramAssets? loaded;

  static Future<ProgramAssets> load([AssetBundle? bundle]) =>
      _pending ??= _load(bundle ?? rootBundle).catchError((Object e) {
        _pending = null;
        throw e;
      });

  static Future<ProgramAssets> _load(AssetBundle b) async {
    Future<Map<String, dynamic>> gz(String asset) async {
      final bytes = await b.load(asset);
      return jsonDecode(utf8.decode(gzip.decode(bytes.buffer.asUint8List())))
          as Map<String, dynamic>;
    }

    final catalog = GenCatalog.fromContent(
      index: await gz('assets/content/index.json.gz'),
      details: await gz('assets/content/details.json.gz'),
      progressions: await gz('assets/content/progressions.json.gz'),
    );
    return loaded = ProgramAssets(catalog);
  }
}

extension ProgramStore on AppStore {
  /// Un programme L10 (« generated ») est en place.
  bool get programGenerated => programInstance?.generated ?? false;

  /// Identifiant du modèle de périodisation L10 en place.
  String get programModel =>
      programInstance?.summary['model'] as String? ?? 'expert_streetlifting';

  /// Résumé de la génération L10 (vide pour le modèle implicite).
  Map<String, dynamic> get programSummary =>
      programInstance?.summary ?? const {'model': 'expert_streetlifting'};
}
