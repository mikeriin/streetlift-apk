# kalis_koach

Koach, la mascotte de Kalis Track, en **Dart pur** (lot GK du pipeline « Génération et
progression », piste K) :

- **36 poses vectorisées** depuis les planches du propriétaire (`tools/koach/sources/`), en trois
  calques (encre, papier, yeux) de commandes numériques prêtes à devenir un `Path` Flutter ;
- **10 flammes de difficulté** (D5.3), tailles relatives conservées, avec silhouette et creux ;
- **répliques** : pour chaque événement de l'application, choix déterministe de la pose, du message
  français, des actions et de l'explication « Pourquoi ? » ; table « code de raison du moteur →
  message » extensible.

Aucune dépendance à Flutter. L'application (lot G5) récupère le paquet par étiquette
(`git checkout kalis_koach-v0.1.0 -- packages/kalis_koach`) et ne fait que dessiner et animer.

```dart
import 'package:kalis_koach/kalis_koach.dart';

final art = KoachPose.thumbsUp.art;            // calques ink / paper / eyes
replayKoachPath(art.ink, monSink, scale: 0.2);  // KoachPathSink -> Path Flutter

final line = KoachDirector().lineFor(const KoachCue(KoachEvent.sessionEndGood, occurrence: 2));
const KoachTexts().bubble(line);                // « C’est fait ! Pense à bien récupérer. »
```

- Contrat (format, calques, couleurs D6.2, catalogue, API des répliques, paramètres, limites,
  registre de validation) : [CONTRAT.md](CONTRAT.md).
- Contrôle de la vectorisation (IoU par pose, planches clair/sombre, gros plans) :
  [docs/controle/](docs/controle/vectorisation.md).
- Cas types des répliques, relus : [docs/cas_types.md](docs/cas_types.md).
- Régénérer les dessins : `pip install -r tools/koach/requirements.txt` puis
  `python3 tools/koach/build_koach.py --controle` (depuis la racine du dépôt) ; `--check` vérifie
  que le Dart commité est à jour.
- Simulateur : `dart run bin/kalis_koach_cli.dart --rapport <dossier>` (inventaire JSON/texte, cas
  types, SVG de chaque pose et flamme).
