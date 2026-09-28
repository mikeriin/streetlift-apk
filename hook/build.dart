// M2 (mannequin 3D) : build hook de flutter_scene. Convertit le mannequin
// anatomique (assets/anatomy/mannequin.glb, fabriqué par
// tools/anatomy/build_model.py) en .fsceneb dans flutter_scene_generated/,
// chargé par son chemin de source avec `loadScene`.
import 'package:flutter_scene/build_hooks.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    buildScenes(
      buildInput: input,
      buildOutput: output,
      inputFilePaths: const [
        'assets/anatomy/mannequin.glb',
        // M6 : matériel (tools/anatomy/build_equipment.py).
        'assets/anatomy/equipment.glb',
      ],
    );
  });
}
