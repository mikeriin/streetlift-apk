// M3 (mannequin 3D) : mannequin fixe de la fiche exercice.
//
// Les muscles du pack de l'exercice sont posés sur les régions du mannequin
// (`assets/anatomy/muscles_map.json`) avec les intensités du propriétaire :
// principal 1, secondaire 0,62, stabilisateur 0,35 (rampe historique
// bordeaux → rouge) ; étiré 0,25 dans une teinte froide distincte
// ([mannequinStretch]). La vue de départ montre au mieux les muscles
// principaux ([exerciseStartView]). Sans Flutter GPU, la carte 2D historique
// de la fiche (`ExerciseAtlas`) reste affichée. La liste des muscles en texte
// reste toujours sous le mannequin (fiche exercice).
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'atlas.dart';
import 'atlas_data.dart';
import 'engine3d.dart';
import 'mannequin_3d.dart';

/// Face du corps où un muscle du pack se voit le mieux.
enum MuscleFace { anterieur, posterieur, lateral }

/// Face de chacun des 81 muscles du pack (repère anatomique : un muscle
/// latéral, ou partagé entre l'avant et l'arrière, ne décide pas de la vue).
const muscleFaces = <String, MuscleFace>{
  'sterno_cleido_mastoidien': MuscleFace.anterieur,
  'extenseurs_cervicaux': MuscleFace.posterieur,
  'flechisseurs_cervicaux_profonds': MuscleFace.anterieur,
  'deltoide_anterieur': MuscleFace.anterieur,
  'deltoide_moyen': MuscleFace.lateral,
  'deltoide_posterieur': MuscleFace.posterieur,
  'supra_epineux': MuscleFace.posterieur,
  'infra_epineux': MuscleFace.posterieur,
  'petit_rond': MuscleFace.posterieur,
  'sous_scapulaire': MuscleFace.anterieur,
  'trapeze_superieur': MuscleFace.posterieur,
  'trapeze_moyen': MuscleFace.posterieur,
  'trapeze_inferieur': MuscleFace.posterieur,
  'elevateur_scapula': MuscleFace.posterieur,
  'rhomboides': MuscleFace.posterieur,
  'dentele_anterieur': MuscleFace.lateral,
  'petit_pectoral': MuscleFace.anterieur,
  'grand_pectoral_claviculaire': MuscleFace.anterieur,
  'grand_pectoral_sterno_costal': MuscleFace.anterieur,
  'grand_pectoral_abdominal': MuscleFace.anterieur,
  'grand_dorsal': MuscleFace.posterieur,
  'grand_rond': MuscleFace.posterieur,
  'biceps_chef_long': MuscleFace.anterieur,
  'biceps_chef_court': MuscleFace.anterieur,
  'brachial': MuscleFace.anterieur,
  'coraco_brachial': MuscleFace.anterieur,
  'triceps_chef_long': MuscleFace.posterieur,
  'triceps_chef_lateral': MuscleFace.posterieur,
  'triceps_chef_medial': MuscleFace.posterieur,
  'ancone': MuscleFace.posterieur,
  'brachio_radial': MuscleFace.anterieur,
  'extenseurs_du_poignet': MuscleFace.posterieur,
  'extenseurs_des_doigts': MuscleFace.posterieur,
  'flechisseurs_du_poignet': MuscleFace.anterieur,
  'flechisseurs_superficiels_des_doigts': MuscleFace.anterieur,
  'flechisseurs_profonds_des_doigts': MuscleFace.anterieur,
  'rond_pronateur': MuscleFace.anterieur,
  'supinateur': MuscleFace.posterieur,
  'carre_pronateur': MuscleFace.anterieur,
  'muscles_intrinseques_main': MuscleFace.lateral,
  'droit_abdomen': MuscleFace.anterieur,
  'oblique_externe': MuscleFace.lateral,
  'oblique_interne': MuscleFace.lateral,
  'transverse_abdomen': MuscleFace.anterieur,
  'carre_des_lombes': MuscleFace.posterieur,
  'erecteurs_lombaires': MuscleFace.posterieur,
  'erecteurs_thoraciques': MuscleFace.posterieur,
  'multifides': MuscleFace.posterieur,
  'diaphragme': MuscleFace.lateral,
  'plancher_pelvien': MuscleFace.lateral,
  'grand_psoas': MuscleFace.anterieur,
  'iliaque': MuscleFace.anterieur,
  'tenseur_fascia_lata': MuscleFace.lateral,
  'sartorius': MuscleFace.anterieur,
  'grand_fessier': MuscleFace.posterieur,
  'moyen_fessier': MuscleFace.lateral,
  'petit_fessier': MuscleFace.lateral,
  'rotateurs_lateraux_hanche': MuscleFace.posterieur,
  'pectine': MuscleFace.anterieur,
  'long_adducteur': MuscleFace.anterieur,
  'court_adducteur': MuscleFace.anterieur,
  'grand_adducteur': MuscleFace.posterieur,
  'gracile': MuscleFace.anterieur,
  'droit_femoral': MuscleFace.anterieur,
  'vaste_lateral': MuscleFace.anterieur,
  'vaste_medial': MuscleFace.anterieur,
  'vaste_intermediaire': MuscleFace.anterieur,
  'biceps_femoral': MuscleFace.posterieur,
  'biceps_femoral_chef_court': MuscleFace.posterieur,
  'semi_tendineux': MuscleFace.posterieur,
  'semi_membraneux': MuscleFace.posterieur,
  'poplite': MuscleFace.posterieur,
  'gastrocnemien_medial': MuscleFace.posterieur,
  'gastrocnemien_lateral': MuscleFace.posterieur,
  'soleaire': MuscleFace.posterieur,
  'tibial_anterieur': MuscleFace.anterieur,
  'long_extenseur_des_orteils': MuscleFace.anterieur,
  'fibulaires': MuscleFace.lateral,
  'tibial_posterieur': MuscleFace.posterieur,
  'flechisseurs_profonds_des_orteils': MuscleFace.posterieur,
  'muscles_intrinseques_pied': MuscleFace.lateral,
};

/// Vue de départ de la fiche : principaux tous postérieurs → Dos, tous
/// antérieurs → Face, mixtes → 3/4. Les muscles latéraux ne comptent pas ;
/// sans principal orienté, les secondaires décident ; sans aucun, 3/4 (la
/// vue qui montre à la fois l'avant et le côté).
MannequinView exerciseStartView(
  List<String> primaires, [
  List<String> secondaires = const [],
]) {
  for (final muscles in [primaires, secondaires]) {
    final faces = {
      for (final m in muscles)
        if (muscleFaces[m] case final MuscleFace f)
          if (f != MuscleFace.lateral) f,
    };
    if (faces.length == 2) return MannequinView.troisQuarts;
    if (faces.length == 1) {
      return faces.single == MuscleFace.anterieur
          ? MannequinView.face
          : MannequinView.dos;
    }
  }
  return MannequinView.troisQuarts;
}

/// Muscles du pack sans région sur le mannequin, avec la raison. Ils restent
/// dans la liste en texte de la fiche. 5.5.2 (M56 correction 2) : l'écorché
/// acheté ne montre que la couche superficielle ; les muscles profonds
/// couverts par d'autres n'ont pas de région (jusqu'à 5.5.1, le modèle
/// Z-Anatomy les portait en transparence).
const musclesSansRegion = <String, String>{
  'flechisseurs_cervicaux_profonds':
      'profonds, devant les vertèbres du cou (absents du modèle)',
  'diaphragme': 'interne, sous les côtes (absent du modèle)',
  'plancher_pelvien': 'interne, au fond du bassin (absent du modèle)',
  'biceps_femoral_chef_court': 'profond, sous le chef long (écorché)',
  'carre_des_lombes': 'profond, sous les érecteurs (écorché)',
  'carre_pronateur': 'profond, sous les fléchisseurs (écorché)',
  'court_adducteur': 'profond, sous le long adducteur (écorché)',
  'flechisseurs_profonds_des_doigts':
      'profonds, sous les fléchisseurs superficiels (écorché)',
  'multifides': 'profonds, sous les érecteurs (écorché)',
  'oblique_interne': 'profond, sous l’oblique externe (écorché)',
  'petit_fessier': 'profond, sous le moyen fessier (écorché)',
  'petit_pectoral': 'profond, sous le grand pectoral (écorché)',
  'poplite': 'profond, derrière le genou (écorché)',
  'rotateurs_lateraux_hanche': 'profonds, sous le grand fessier (écorché)',
  'sous_scapulaire': 'profond, sous la scapula (écorché)',
  'supinateur': 'profond, sous les extenseurs (écorché)',
  'supra_epineux': 'profond, sous le trapèze (écorché)',
  'tibial_posterieur': 'profond, sous le soléaire (écorché)',
  'transverse_abdomen': 'profond, sous les obliques (écorché)',
  'vaste_intermediaire': 'profond, sous le droit fémoral (écorché)',
};

/// Muscles d'un exercice posés sur le mannequin.
///
/// Un muscle listé « étiré » est montré étiré même s'il figure aussi parmi
/// les principaux, secondaires ou stabilisateurs : dans le pack, la cible
/// d'un étirement (mobilité, windmill) est aussi listée en principal ; la
/// montrer en rouge la ferait lire comme contractée. Une région garde le
/// rouge si un autre de ses muscles du pack, non étiré, est sollicité.
class ExerciseMuscleMap {
  /// Intensité par région (principal, secondaire, stabilisateur).
  final Map<String, double> intensities;

  /// Régions étirées (non sollicitées par ailleurs).
  final Set<String> stretched;

  /// Muscles de l'exercice sans région sur le mannequin (ordre du pack).
  final List<String> hidden;

  const ExerciseMuscleMap(this.intensities, this.stretched, this.hidden);

  static const empty = ExerciseMuscleMap({}, {}, []);

  factory ExerciseMuscleMap.of(
    MannequinMap map, {
    List<String> primaires = const [],
    List<String> secondaires = const [],
    List<String> stabilisateurs = const [],
    List<String> etires = const [],
  }) {
    final pack = <String, double>{};
    final stretchedPack = etires.toSet();
    void add(Iterable<String> ids, double v) {
      for (final id in ids) {
        if (stretchedPack.contains(id)) continue;
        if ((pack[id] ?? 0) < v) pack[id] = v;
      }
    }

    add(stabilisateurs, kIntensityStabilizer);
    add(secondaires, kIntensitySecondary);
    add(primaires, kIntensityPrimary);
    final intensities = map.fromPack(pack);
    final stretched = {
      for (final id in map.fromPack({for (final e in etires) e: 1}).keys)
        if (!intensities.containsKey(id)) id,
    };
    final covered = {for (final r in map.regions) ...r.pack};
    final hidden = <String>[];
    for (final m in [
      ...primaires,
      ...secondaires,
      ...stabilisateurs,
      ...etires,
    ]) {
      if (!covered.contains(m) && !hidden.contains(m)) hidden.add(m);
    }
    return ExerciseMuscleMap(intensities, stretched, hidden);
  }
}

/// Mannequin 3D de la fiche exercice (repli : carte 2D historique), vue de
/// départ selon les principaux, légende des rôles.
class ExerciseMannequin extends StatefulWidget {
  final List<String> primaires, secondaires, stabilisateurs, etires;
  final double height;

  const ExerciseMannequin({
    super.key,
    this.primaires = const [],
    this.secondaires = const [],
    this.stabilisateurs = const [],
    this.etires = const [],
    this.height = 380,
  });

  @override
  State<ExerciseMannequin> createState() => ExerciseMannequinState();
}

class ExerciseMannequinState extends State<ExerciseMannequin> {
  MannequinMap? _map;
  ExerciseMuscleMap _muscles = ExerciseMuscleMap.empty;
  bool _ready3d = false;

  /// Muscles posés sur le mannequin (contrôles).
  ExerciseMuscleMap get muscles => _muscles;

  /// Vue de départ retenue (contrôles).
  MannequinView get startView =>
      exerciseStartView(widget.primaires, widget.secondaires);

  @override
  void initState() {
    super.initState();
    _setMap(MannequinMap.loaded);
    // Téléphone reconnu incompatible : la carte 2D suffit, rien à charger.
    if (_map == null && engine3DSupportKnown?.compatible != false) {
      MannequinMap.load().then((m) {
        if (mounted) setState(() => _setMap(m));
      }, onError: (Object _) {});
    }
  }

  @override
  void didUpdateWidget(ExerciseMannequin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaires != widget.primaires ||
        oldWidget.secondaires != widget.secondaires ||
        oldWidget.stabilisateurs != widget.stabilisateurs ||
        oldWidget.etires != widget.etires) {
      _setMap(_map);
    }
  }

  void _setMap(MannequinMap? map) {
    _map = map;
    _muscles = map == null
        ? ExerciseMuscleMap.empty
        : ExerciseMuscleMap.of(
            map,
            primaires: widget.primaires,
            secondaires: widget.secondaires,
            stabilisateurs: widget.stabilisateurs,
            etires: widget.etires,
          );
  }

  String _names(List<String> ids) =>
      ids.map((m) => atlasMuscles[m]?.nom ?? m).join(', ');

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final label = [
      if (widget.primaires.isNotEmpty)
        'Principaux : ${_names(widget.primaires)}',
      if (widget.secondaires.isNotEmpty)
        'Secondaires : ${_names(widget.secondaires)}',
      if (widget.stabilisateurs.isNotEmpty)
        'Stabilisateurs : ${_names(widget.stabilisateurs)}',
      if (widget.etires.isNotEmpty) 'Étirés : ${_names(widget.etires)}',
    ].join('. ');
    final hidden = _muscles.hidden;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Mannequin3D(
          key: const ValueKey('fiche-mannequin'),
          intensities: _muscles.intensities,
          stretched: _muscles.stretched,
          view: startView,
          height: widget.height,
          horizontalDragOnly: true,
          semanticLabel:
              'Mannequin anatomique en 3D, muscles de l’exercice. $label',
          onReady: (ok) {
            if (mounted && ok != _ready3d) setState(() => _ready3d = ok);
          },
          fallback: ExerciseAtlas(
            primaires: widget.primaires,
            secondaires: widget.secondaires,
            stabilisateurs: widget.stabilisateurs,
            etires: widget.etires,
          ),
        ),
        if (_ready3d && hidden.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Absents du mannequin (profonds ou internes) : '
              '${_names(hidden)}.',
              key: const ValueKey('fiche-mannequin-profonds'),
              style: TextStyle(fontSize: 12, color: SL.dim),
            ),
          ),
        const SizedBox(height: 12),
        AtlasRoleLegend(stretchColor: _ready3d ? mannequinStretch(dark) : null),
      ],
    );
  }
}
