// Pastille de niveau (accueil) ; l'écran de récompenses et la cérémonie de
// niveau vivent dans rewards.dart, ré-exportés ici pour les écrans existants.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'store.dart';
import 'store_widget.dart';
import 'ui.dart';
import 'progression_screen.dart';

export 'rewards.dart' show checkLevelUp;

/// Niveau et avancement vers le prochain, accessibles depuis tous les onglets.
/// Abonnée au store : elle suit un passage de niveau même instanciée en
/// `const` (barre d'en-tête de l'accueil), sans redémarrer l'application.
class LevelPill extends StoreWidget {
  const LevelPill({super.key});
  @override
  Widget build(BuildContext context) {
    final p = store.levelProgress;
    return Semantics(
      button: true,
      label: 'Niveau ${store.level}',
      value: '${p.inLevel} sur ${p.need} XP',
      onTap: () => openProgression(context),
      excludeSemantics: true,
      child: Tooltip(
        message: 'Ouvrir ma progression',
        child: InkWell(
          onTap: () => openProgression(context),
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 56),
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              alignment: Alignment.centerLeft,
              child: LevelProgressNumber(
                level: store.level,
                progress: p.need == 0 ? 0 : p.inLevel / p.need,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LevelProgressNumber extends StatelessWidget {
  final int level;
  final double progress;
  const LevelProgressNumber({
    super.key,
    required this.level,
    required this.progress,
  });

  /// Hauteur de barre d'en-tête nécessaire à ce bloc pour une taille de
  /// texte donnée (L5 : le niveau suit la taille de texte du téléphone).
  static double headerHeight(BuildContext context) =>
      math.max(70, MediaQuery.textScalerOf(context).scale(30) + 35);

  @override
  Widget build(BuildContext context) {
    final colors = ProgrammeColors.of(context);
    // L5 : plus de réduction forcée (FittedBox, taille de texte figée) ;
    // « NIV. » reste avant le chiffre, la barre dessous, en couleur unie.
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 88),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'NIV.',
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '$level',
                  style: TextStyle(
                    color: SL.text,
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            // Couleur unie de la dominante, bord net avec la piste.
            KProgressBar(
              value: progress,
              height: 4,
              color: colors.p.action,
              semanticsLabel: 'Progression vers le niveau suivant',
            ),
          ],
        ),
      ),
    );
  }
}
