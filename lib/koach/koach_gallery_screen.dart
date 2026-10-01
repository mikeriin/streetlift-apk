// G5 (D1.5, D6) : Arsenal › Anatomie › Galerie de Koach. Remplace l'écran
// « Koach (aperçu) » des animations 3D (M7b, retirées) : les 36 poses
// animées (respiration, clignement, rebond, transition), les 10 flammes de
// difficulté, le sélecteur de flammes (prêt pour la séance, G9) et des
// exemples de bulle, de feuille et de message court.
import 'package:flutter/material.dart';
import 'package:kalis_koach/kalis_koach.dart';

import '../app_theme.dart';
import '../ui.dart';
import 'flame_icon.dart';
import 'koach_bubble.dart';
import 'koach_view.dart';

/// Nom français de chaque pose (galerie, TalkBack).
const Map<KoachPose, String> kKoachPoseNames = {
  KoachPose.explainBoard: 'Explique au tableau',
  KoachPose.readTip: 'Lit une astuce',
  KoachPose.anatomy: 'Montre l’anatomie',
  KoachPose.progressChart: 'Montre la progression',
  KoachPose.think: 'Réfléchit',
  KoachPose.checklist: 'Coche la liste',
  KoachPose.choice: 'Propose un choix',
  KoachPose.idea: 'A une idée',
  KoachPose.settings: 'Règle',
  KoachPose.determined: 'Déterminé',
  KoachPose.direction: 'Montre la direction',
  KoachPose.analyze: 'Analyse',
  KoachPose.wave: 'Salue',
  KoachPose.thumbsUp: 'Pouce levé',
  KoachPose.happy: 'Content',
  KoachPose.point: 'Montre du doigt',
  KoachPose.ponder: 'Se demande',
  KoachPose.shrug: 'Hausse les épaules',
  KoachPose.oops: 'Oups',
  KoachPose.please: 'S’il te plaît',
  KoachPose.love: 'Merci',
  KoachPose.flex: 'Montre ses muscles',
  KoachPose.run: 'Court',
  KoachPose.victory: 'Victoire',
  KoachPose.thumbsUp2: 'Bravo',
  KoachPose.cheer: 'Fête ça',
  KoachPose.pump: 'Motivé',
  KoachPose.flag: 'Plante le drapeau',
  KoachPose.fistBump: 'Check du poing',
  KoachPose.heart: 'Cœur',
  KoachPose.you: 'À toi',
  KoachPose.doubleBiceps: 'Double biceps',
  KoachPose.clap: 'Applaudit',
  KoachPose.sprint: 'Sprinte',
  KoachPose.fistUp: 'Poing levé',
  KoachPose.present: 'Présente',
};

class KoachGalleryScreen extends StatefulWidget {
  const KoachGalleryScreen({super.key});

  @override
  State<KoachGalleryScreen> createState() => KoachGalleryScreenState();
}

class KoachGalleryScreenState extends State<KoachGalleryScreen> {
  KoachPose _pose = KoachPose.wave;
  int? _flames = 7;

  /// Pose affichée en grand (tests).
  KoachPose get pose => _pose;

  /// Choisit une pose (tuiles, tests).
  void select(KoachPose p) => setState(() => _pose = p);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final proposal = koachDirector.lineFor(
      const KoachCue(
        KoachEvent.proposalNew,
        reason: 'load_increased',
        params: {'exercise': 'Tractions'},
      ),
    );
    return KScreen(
      appBar: AppBar(title: const Text('GALERIE DE KOACH')),
      body: KList(
        key: const ValueKey('koach-gallery-list'),
        gap: 10,
        children: [
          Text(
            'Koach, la mascotte de Kalis Track : 36 poses et 10 flammes de '
            'difficulté. Touche une pose pour la voir en grand.',
            style: tt.bodyMedium,
          ),
          // Pose en grand, cadre commun : la transition se voit.
          Center(
            child: KoachView(
              key: const ValueKey('koach-gallery-stage'),
              pose: _pose,
              height: 190,
              frame: KoachFrame.stage,
              seed: 3,
              semanticLabel: 'Koach : ${kKoachPoseNames[_pose]}',
            ),
          ),
          Text(
            kKoachPoseNames[_pose]!,
            key: const ValueKey('koach-gallery-name'),
            textAlign: TextAlign.center,
            style: tt.titleMedium,
          ),
          Text(
            reduce
                ? 'Animations réduites : Koach reste immobile.'
                : 'Il respire, cligne des yeux et rebondit en arrivant ; '
                      'changer de pose se fait en douceur.',
            key: const ValueKey('koach-gallery-motion'),
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(color: SL.dim),
          ),
          const KSection('Les 36 poses'),
          _grid(context),
          const KSection('Flammes de difficulté'),
          _flameRow(context),
          FlamePicker(
            key: const ValueKey('koach-gallery-picker'),
            value: _flames,
            onChanged: (v) => setState(() => _flames = v),
          ),
          const KSection('Koach parle'),
          KoachBubble.line(
            proposal,
            key: const ValueKey('koach-gallery-bubble'),
            onAction: {
              KoachActionKind.accept: () => showKoachToast(
                context,
                koachTexts.bubble(
                  koachDirector.lineFor(
                    const KoachCue(KoachEvent.proposalAccepted),
                  ),
                ),
              ),
              KoachActionKind.decline: () => showKoachToast(
                context,
                koachTexts.bubble(
                  koachDirector.lineFor(
                    const KoachCue(KoachEvent.proposalDeclined),
                  ),
                ),
                pose: KoachPose.shrug,
              ),
            },
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const ValueKey('koach-gallery-sheet'),
                onPressed: () => showKoachSheet<void>(
                  context,
                  pose: KoachPose.explainBoard,
                  title: 'Les flammes',
                  text:
                      'Après chaque série, note sa difficulté de 1 à 10 '
                      'flammes. 10, c’est l’échec : plus aucune répétition '
                      'possible.',
                  why: koachTexts.render('why.generic_change', const {}),
                ),
                child: const Text('Feuille de Koach'),
              ),
              OutlinedButton(
                key: const ValueKey('koach-gallery-toast'),
                onPressed: () => showKoachToast(
                  context,
                  koachTexts.bubble(
                    koachDirector.lineFor(
                      const KoachCue(KoachEvent.sessionEndGood),
                    ),
                  ),
                  pose: KoachPose.victory,
                ),
                child: const Text('Message court'),
              ),
            ],
          ),
          Text(
            'Dessins vectoriels de Koach (kalis_koach $kalisKoachVersion). '
            'Ses messages ne sont pas des avis médicaux.',
            style: tt.bodySmall?.copyWith(color: SL.dim),
          ),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns = c.maxWidth >= 520 ? 6 : (c.maxWidth >= 300 ? 4 : 3);
      final cell = ((c.maxWidth - (columns - 1) * 6) / columns)
          .floorToDouble();
      return Wrap(
        key: const ValueKey('koach-gallery-grid'),
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final (i, p) in KoachPose.values.indexed)
            SizedBox(
              width: cell,
              child: Semantics(
                button: true,
                selected: p == _pose,
                label: kKoachPoseNames[p],
                excludeSemantics: true,
                child: InkWell(
                  key: ValueKey('koach-pose-${p.id}'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => select(p),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(2, 6, 2, 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: p == _pose ? SL.text : SL.line,
                        width: p == _pose ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        KoachView(
                          pose: p,
                          height: 64,
                          width: cell - 8,
                          seed: i,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${i + 1}',
                          style: TextStyle(fontSize: 11, color: SL.dim),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _flameRow(BuildContext context) => Row(
    key: const ValueKey('koach-gallery-flames'),
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      for (var i = 1; i <= 10; i++)
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlameIcon(i, size: 44),
              const SizedBox(height: 2),
              Text('$i', style: TextStyle(fontSize: 12, color: SL.dim)),
            ],
          ),
        ),
    ],
  );
}
