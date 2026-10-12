# Export texte — refonte muscles / animations

Cet export représente les changements du projet extrait par rapport à `streetlift_tracker_v33.zip` du commit `5d38177`. **Le dossier `codex_export/` ne contient aucun fichier binaire.** Les PNG sont transportés sous forme de texte Base64.

## Contenu de l’export

- `refonte.patch` : diff unifié de tous les fichiers texte ajoutés ou modifiés, avec chemins relatifs à la racine `streetlift_tracker/`.
- `assets_base64.txt` : un bloc Base64 par binaire ajouté, avec chemin et SHA-256 dans son en-tête.
- `reconstruct.py` : reconstruction et vérification automatisées depuis le ZIP de `5d38177`.
- `muscles_profile.py` : copie autonome en texte du générateur déterministe de la vue de profil (la même version est aussi ajoutée par le patch).

## Reconstruction exacte

Depuis la racine d’un clone placé sur le commit `5d38177` :

```bash
git show 5d38177:streetlift_tracker_v33.zip > /tmp/streetlift_tracker_v33-main.zip
python3 codex_export/reconstruct.py \
  /tmp/streetlift_tracker_v33-main.zip \
  /tmp/kalis-refonte
cd /tmp/kalis-refonte/streetlift_tracker
python3 tools/package_release.py /tmp/kalis-refonte/streetlift_tracker_v33.zip
python3 tools/package_release.py --check /tmp/kalis-refonte/streetlift_tracker_v33.zip
```

`reconstruct.py` extrait l’archive, applique `refonte.patch` avec `git apply`, décode tous les blocs, refuse les chemins dangereux et compare chaque SHA-256 à l’en-tête Base64. Il compare aussi tous les fichiers reconstruits au manifeste ci-dessous.

## Vérification manuelle complémentaire

```bash
cd /tmp/kalis-refonte/streetlift_tracker
python3 -m unittest discover -s tools/tests -v
python3 tools/verify_project.py
dart format --output=none --set-exit-if-changed lib test
flutter analyze
TZ=Europe/Paris flutter test --timeout 60s --reporter expanded
```

## Manifeste des fichiers du projet modifiés ou ajoutés

| Chemin relatif à `streetlift_tracker/` | SHA-256 reconstruit | Transport |
| --- | --- | --- |
| `README.md` | `0c756825c8030caad632d5f2e9b4922bbc715d88c2dc9c2428972a9d50330c7f` | texte |
| `SUIVI_PROJET.md` | `03cf8d83c200e9ff563329f863d4dd2344f02d10cfdd0ad073488e7cb2098696` | texte |
| `lib/atlas.dart` | `7889d07edb120e671654d8e6bced47483408f40c3eaa66c1766ece122b58eb71` | texte |
| `lib/muscle_body.dart` | `c8f78559fe454f16db81f6d2f16ac4273f5fca92fc43bde27194db24e8557bd4` | texte |
| `lib/pose_painter.dart` | `d7f83514c138c90fa01bffd7d93012d90d760cbbb4ce9e23eb03b972304ef5af` | texte |
| `lib/settings_screen.dart` | `b7c176a52695297574898e2aa7ffa1d07caaa0dc242242bfbfaec5d3f3e21edb` | texte |
| `pubspec.yaml` | `c445c4c03c21e247cfaa0c7f32fa1f491a66f153dfc2c74ed0a7dd63a66b9865` | texte |
| `assets/muscles/back_avant_bras.png` | `287dc57a7db7ba305733b9f888701d00060d1f76ee50bf6c703541cd94c13642` | binaire/base64 |
| `assets/muscles/back_base.png` | `19a1665ffdc73b122dd4b4a3d3c80be8b5866cd17a7af211721e93ccdc4788c5` | binaire/base64 |
| `assets/muscles/back_dos.png` | `a116488ee0e7a6cf38bf98bd3fb3fab5b13122ea8f920693f4b4ef4024815589` | binaire/base64 |
| `assets/muscles/back_epaules.png` | `b127b4c0afb76346bdada9ab1c4fc51e5fae45ce9b45fc592897bd8caf4d72e8` | binaire/base64 |
| `assets/muscles/back_fessiers.png` | `017236b06958687d65825c60642106cc834435628de2fd0e0068e75742961fed` | binaire/base64 |
| `assets/muscles/back_ischios.png` | `35b5de2f713bfa5fb81bca09fcd2607ef9198b67aaa9aed437af731f3ac05558` | binaire/base64 |
| `assets/muscles/back_mollets.png` | `282edfc9b0650c128093ae37dd6cc31ea2eee43f87d0e43199b2ca72cef6e088` | binaire/base64 |
| `assets/muscles/back_triceps.png` | `4758382a9045ac7a91ecfd99ad16f934616901c5a9ac222b01968ff5f37e65d0` | binaire/base64 |
| `assets/muscles/front_avant_bras.png` | `b433e449bf2672a37e50aff34e723489b6124cf17999f90466664645adaab9e1` | binaire/base64 |
| `assets/muscles/front_base.png` | `af6a97c8da09b85f2aa95144512b974efe00eac4cd1685fe5f00a015103eda53` | binaire/base64 |
| `assets/muscles/front_biceps.png` | `eb323dc5300f0562ca10081a7652428a693dfb65cd9787f7a05d93473fdda133` | binaire/base64 |
| `assets/muscles/front_dos.png` | `e7def515ffd52996655e529f8dcf0101ff4b4560fd4b23b1c7fa0fcdb6b118f1` | binaire/base64 |
| `assets/muscles/front_epaules.png` | `54414c2b6e391cdaf5982b6e993b5c756390ec89693f73f7336ca8123644a86a` | binaire/base64 |
| `assets/muscles/front_gainage.png` | `76002fc7fae3bada25a35ac3994c600b3d97cdb5892664002b2fc89b92c99ed3` | binaire/base64 |
| `assets/muscles/front_mollets.png` | `f020651639467a87509b9f9e9076b62269f0c57e02f410a11c8d85398551cd82` | binaire/base64 |
| `assets/muscles/front_pectoraux.png` | `cad4f5d34c010eabeffc8666ebfd23437871ae5d9f5f26c17f09ba83ed42ae44` | binaire/base64 |
| `assets/muscles/front_quadriceps.png` | `9671d12145e33ce3ab5b4e658ea77151cfa6b4a369c2a63cb7e45b3ea3ef525f` | binaire/base64 |
| `assets/muscles/profile_avant_bras.png` | `4b4520c95d07b7a7b56268189303d078030d59b09e5ef3b156bf10c4cfb92bda` | binaire/base64 |
| `assets/muscles/profile_base.png` | `10f91d42d4bdd247868f5e60178d80292331ed128ccfc94af1ec7461809e1134` | binaire/base64 |
| `assets/muscles/profile_biceps.png` | `f00023ff2532ed80c6b1ffe8524b164d6850df6c8576537c8a18223a530d8556` | binaire/base64 |
| `assets/muscles/profile_dos.png` | `bc9dd93aa74e24d24452ea91b6df2a2862dbf72ea32f5033ac19f149ba1c80d0` | binaire/base64 |
| `assets/muscles/profile_epaules.png` | `30e1dd1a2f8018938b7c630ae67ac49aa917b7283d44c08eb2879c5c2b72d458` | binaire/base64 |
| `assets/muscles/profile_fessiers.png` | `38ecce138630b4eb28f16d34cd89f1e39b6995feccafe3ed647fd08554fccbcb` | binaire/base64 |
| `assets/muscles/profile_gainage.png` | `082a68137e9f06109dbfdfc9513b144c9fda451d8ae211950cc60fa117cc85da` | binaire/base64 |
| `assets/muscles/profile_ischios.png` | `7efe519960afe64d8a00f59fa5c078ee95a12f1c426867503f00c2f8a212ac3e` | binaire/base64 |
| `assets/muscles/profile_mollets.png` | `060660e2f16fdb2bc1dd8e4ac42f47b7dd68087adc0de024b7606494f37ec3f8` | binaire/base64 |
| `assets/muscles/profile_pectoraux.png` | `e172ddbcf051e0d422c968095deafebcf617a5932810564f2cd154686161fc8a` | binaire/base64 |
| `assets/muscles/profile_quadriceps.png` | `f6701828453f78342a6e1c525a6ec69a201ffb6acd5da0fa2e1313b2934a2148` | binaire/base64 |
| `assets/muscles/profile_triceps.png` | `85cdfed34cef86cb2c250bea1a088bed31f502ed5d299cb1aee00c922f044c85` | binaire/base64 |
| `artifacts/previews/comparaison_anatomique.png` | `5316f866a0f2c8d506c602f3fdfc271cc5291b1e844ae7d73186eb5644acb3ff` | binaire/base64 |

## Méthode de production du profil

La vue de profil est produite par `tools/muscles_profile.py` avec Pillow. Après reconstruction :

```bash
python3 -m pip install pillow
cd /tmp/kalis-refonte/streetlift_tracker
python3 tools/muscles_profile.py
```

Le script écrit `profile_base.png`, les onze `profile_<groupe>.png` et complète `assets/muscles/meta.json`. Les empreintes doivent ensuite correspondre au manifeste ci-dessus.
