// M2 (mannequin 3D) : build hook de flutter_scene. Convertit le mannequin
// (assets/anatomy/mannequin.glb ; M6c : personnage Mixamo fabriqué par
// tools/anatomy/build_character.py, chiffré dans assets_secure/ et déchiffré
// avant le build par tools/secure_assets.py) en .fsceneb dans
// flutter_scene_generated/, chargé par son chemin de source avec `loadScene`.
import 'package:flutter_scene/build_hooks.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    buildScenes(
      buildInput: input,
      buildOutput: output,
      inputFilePaths: const [
        'assets/anatomy/mannequin.glb',
        // M7 : mannequin animable (squelette Mixamo et peau), lecteur
        // d'animations (tools/anatomy/build_animated.py, chiffré).
        'assets/anatomy/mannequin_anime.glb',
      ],
    );
  });
}
