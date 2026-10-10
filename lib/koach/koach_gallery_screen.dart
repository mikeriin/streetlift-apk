// G5 (D1.5, D6) : Arsenal › Anatomie › Galerie de Koach (UI4 : Réglages ›
// Aide et à propos ; conteneur au kit, poses et flammes inchangées).
// Remplace l'écran « Koach (aperçu) » des animations 3D (M7b, retirées) :
// les 36 poses animées (respiration, clignement, rebond, transition), les 10
// flammes de difficulté, le sélecteur de flammes (prêt pour la séance, G9)
// et des exemples de bulle, de feuille et de message court.
import 'package:flutter/material.dart';
import 'package:kalis_koach/kalis_koach.dart';

import '../kit/kit.dart';
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
    final k = KTokens.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final proposal = koachDirector.lineFor(
      const KoachCue(
        KoachEvent.proposalNew,
        reason: 'load_increased',
        params: {'exercise': 'Tractions'},
      ),
    );
    return KPage.sub(
      key: const ValueKey('koach-gallery-list'),
      title: 'Galerie de Koach',
      lead:
          'Koach, la mascotte de Kalis Track : 36 poses et 10 flammes de '
          'difficulté. Touche une pose pour la voir en grand.',
      children: [
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
          style: KType.corpsFort.copyWith(color: k.texte),
        ),
        Text(
          reduce
              ? 'Animations réduites : Koach reste immobile.'
              : 'Il respire, cligne des yeux et rebondit en arrivant ; '
                    'changer de pose se fait en douceur.',
          key: const ValueKey('koach-gallery-motion'),
          textAlign: TextAlign.center,
          style: KType.detail.copyWith(color: k.texte2),
        ),
        const KSectionTitle('Les 36 poses'),
        _grid(context),
        const KSectionTitle('Flammes de difficulté'),
        _flameRow(context),
        FlamePicker(
          key: const ValueKey('koach-gallery-picker'),
          value: _flames,
          onChanged: (v) => setState(() => _flames = v),
        ),
        const KSectionTitle('Koach parle'),
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
        // Démonstrations des composants de Koach (feuille, message court) :
        // composants de `koach_bubble.dart`, inchangés.
        Wrap(
          spacing: KSpacing.s8,
          runSpacing: KSpacing.s8,
          children: [
            KTonalButton(
              key: const ValueKey('koach-gallery-sheet'),
              label: 'Feuille de Koach',
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
            ),
            KTonalButton(
              key: const ValueKey('koach-gallery-toast'),
              label: 'Message court',
              onPressed: () => showKoachToast(
                context,
                koachTexts.bubble(
                  koachDirector.lineFor(
                    const KoachCue(KoachEvent.sessionEndGood),
                  ),
                ),
                pose: KoachPose.victory,
              ),
            ),
          ],
        ),
        Text(
          'Dessins vectoriels de Koach (kalis_koach $kalisKoachVersion). '
          'Ses messages ne sont pas des avis médicaux.',
          style: KType.detail.copyWith(color: k.texte2),
        ),
      ],
    );
  }

  Widget _grid(BuildContext context) {
    final k = KTokens.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 520 ? 6 : (c.maxWidth >= 300 ? 4 : 3);
        const gap = KSpacing.s8;
        final cell = ((c.maxWidth - (columns - 1) * gap) / columns)
            .floorToDouble();
        return Wrap(
          key: const ValueKey('koach-gallery-grid'),
          spacing: gap,
          runSpacing: gap,
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
                    customBorder: KRadius.menuShape,
                    onTap: () => select(p),
                    child: Container(
                      padding: const EdgeInsets.all(KSpacing.s4),
                      // Pose choisie : contour `encre` de l'élément courant.
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          borderRadius: KRadius.menuRadius,
                          side: p == _pose
                              ? BorderSide(color: k.encre, width: KSize.current)
                              : BorderSide(color: k.filet),
                        ),
                      ),
                      child: Column(
                        children: [
                          KoachView(
                            pose: p,
                            height: 64,
                            width: cell - 2 * KSpacing.s4,
                            seed: i,
                          ),
                          Text(
                            '${i + 1}',
                            style: KType.micro.copyWith(color: k.texte2),
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
  }

  Widget _flameRow(BuildContext context) {
    final k = KTokens.of(context);
    return Row(
      key: const ValueKey('koach-gallery-flames'),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 1; i <= 10; i++)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FlameIcon(i, size: 44),
                Text('$i', style: KType.micro.copyWith(color: k.texte2)),
              ],
            ),
          ),
      ],
    );
  }
}
