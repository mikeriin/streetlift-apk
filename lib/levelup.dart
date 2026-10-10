// Pastille de niveau (accueil) ; l'écran de récompenses et la cérémonie de
// niveau vivent dans rewards.dart, ré-exportés ici pour les écrans existants.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'store.dart';
import 'store_widget.dart';
import 'ui.dart';
import 'progression_screen.dart';

export 'rewards.dart' show checkLevelUp;

/// Niveau et avancement vers le prochain, accessibles depuis tous les onglets.
/// Abonnée au store : elle suit un passage de niveau même instanciée en
/// `const` (en-tête de l'accueil), sans redémarrer l'application.
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
        child: Material(
          type: MaterialType.transparency,
          shape: KRadius.menuShape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openProgression(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: KSize.target,
                minHeight: KSize.primary,
              ),
              child: Align(
                widthFactor: 1,
                heightFactor: 1,
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: KSpacing.s4),
                  child: LevelProgressNumber(
                    level: store.level,
                    progress: p.need == 0 ? 0 : p.inLevel / p.need,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Niveau (maquette « Accueil ») : « Niv. » puis le chiffre, la barre
/// d'avancement dessous (`encre`). Largeur : celle du texte à la taille
/// choisie (L5 : le niveau suit la taille de texte du téléphone), 64 au
/// minimum.
class LevelProgressNumber extends StatelessWidget {
  final int level;
  final double progress;
  const LevelProgressNumber({
    super.key,
    required this.level,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final label = KType.micro.copyWith(color: k.texte2);
    final number = KType.chiffre.copyWith(color: k.texte);
    final scaler = MediaQuery.textScalerOf(context);
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final width = math.max(
      KSize.menuRow,
      measure('Niv.', label) + KSpacing.s4 + measure('$level', number),
    );
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Niv.', style: label),
              const SizedBox(width: KSpacing.s4),
              Text('$level', style: number),
            ],
          ),
          const SizedBox(height: KSpacing.s4),
          KProgressBar(
            value: progress,
            height: KSpacing.s4,
            color: k.encre,
            track: k.filet,
            semanticsLabel: 'Progression vers le niveau suivant',
          ),
        ],
      ),
    );
  }
}
