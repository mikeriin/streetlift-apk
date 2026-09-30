// M7 (mannequin 3D) : écran « Animation de test » (Réglages › À propos ›
// Moteur 3D › Animation de test).
//
// Demande du propriétaire (29/09/2026) : une animation de débogage « pour
// tester le tout » en attendant ses animations. Squat lent au poids du
// corps (4 phases : descente 3 s, pause 1 s, montée 1 s, pause 1 s),
// produit comme un FBX Mixamo « Without Skin » et passé par la chaîne
// d'import (tools/anatomy/debug_animation.py, import_animations.py). Il
// sert à vérifier sur le téléphone : fluidité (images/s), lecteur, curseur,
// phases, intensité par phase, vues, zoom, animations réduites. Libellé
// comme test ; jamais montré sur une fiche d'exercice.
import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'atlas_data.dart';
import 'exercise_mannequin.dart';
import 'mannequin_3d.dart';
import 'mannequin_clip.dart';
import 'mannequin_player.dart';
import 'ui.dart';

class AnimationTestScreen extends StatefulWidget {
  const AnimationTestScreen({super.key});

  @override
  State<AnimationTestScreen> createState() => AnimationTestScreenState();
}

class AnimationTestScreenState extends State<AnimationTestScreen> {
  ClipEntry? _clip;
  MannequinMap? _map;
  String? _error;
  final GlobalKey<MannequinPlayerState> _player = GlobalKey();

  /// Lecteur (tests d'intégration).
  MannequinPlayerState? get player => _player.currentState;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<Object>([
        ClipRegistry.load(),
        MannequinMap.load(),
      ]);
      if (!mounted) return;
      final clip = (results[0] as ClipRegistry).debugClip;
      setState(() {
        _clip = clip;
        _map = results[1] as MannequinMap;
        if (clip == null) _error = 'Aucune animation de test dans le registre.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Registre des animations illisible.');
      }
    }
  }

  String _names(List<String> ids) =>
      ids.map((m) => atlasMuscles[m]?.nom ?? m).join(', ');

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final clip = _clip, map = _map;
    final muscles = clip?.muscles;
    final mapped = clip == null || map == null || muscles == null
        ? ExerciseMuscleMap.empty
        : ExerciseMuscleMap.of(
            map,
            primaires: muscles.primaires,
            secondaires: muscles.secondaires,
            stabilisateurs: muscles.stabilisateurs,
          );
    return KScreen(
      appBar: AppBar(title: const Text('ANIMATION DE TEST')),
      body: KList(
        key: const ValueKey('animation-test-list'),
        children: [
          KCard(
            key: const ValueKey('animation-test-banner'),
            child: Row(
              children: [
                Icon(Icons.science_outlined, color: SL.dim),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Animation de test, réservée aux vérifications du lecteur '
                    '3D : ce n’est pas la démonstration d’un exercice.',
                    style: tt.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Text(_error!, key: const ValueKey('animation-test-error'))
          else if (clip == null || map == null)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            // 5.8.2 : lecteur posé sur la page, fond = page (sans carte).
            KeyedSubtree(
              key: const ValueKey('animation-test-support'),
              child: MannequinPlayer(
                key: _player,
                background: kPageColor(context),
                clip: clip,
                intensities: mapped.intensities,
                view: MannequinView.profil,
                height: 360,
                showFps: true,
                semanticLabel:
                    'Animation de test en 3D : ${clip.name}. Muscles '
                    'principaux : ${_names(muscles?.primaires ?? const [])}',
                fallback: SizedBox(
                  height: 160,
                  child: Center(
                    child: Text(
                      'Moteur 3D indisponible sur ce téléphone : '
                      'l’animation ne peut pas s’afficher.',
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium,
                    ),
                  ),
                ),
              ),
            ),
          if (clip != null) ...[
            Text(clip.name, style: tt.titleMedium),
            if (muscles != null)
              Text(
                [
                  'Principaux : ${_names(muscles.primaires)}',
                  'Secondaires : ${_names(muscles.secondaires)}',
                  'Stabilisateurs : ${_names(muscles.stabilisateurs)}',
                ].join('\n'),
                key: const ValueKey('animation-test-muscles'),
                style: tt.bodySmall,
              ),
            KCard(
              key: const ValueKey('animation-test-phases'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phases et halo', style: tt.titleMedium),
                  const SizedBox(height: 6),
                  for (final p in clip.phases)
                    Text(
                      '${p.label} — ${p.kind.label.toLowerCase()} : '
                      '${_haloOf(p.kind)}',
                      style: tt.bodySmall,
                    ),
                ],
              ),
            ),
            KCard(
              key: const ValueKey('animation-test-checklist'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('À vérifier', style: tt.titleMedium),
                  const SizedBox(height: 6),
                  for (final line in const [
                    'Fluidité : images/s affichées sous le lecteur.',
                    'Lecture / pause, et le curseur : glisser parcourt le '
                        'mouvement.',
                    'Phase et tempo affichés (« Descente · 3 s »…).',
                    'Halo : vif en montée, plus doux en descente, pulsation '
                        'lente pendant les pauses, sans clignotement.',
                    'Vues Face / Dos / Profil / 3/4, zoom au pincement, nom '
                        'du muscle au toucher.',
                    'Animations réduites (réglage Android « Supprimer les '
                        'animations ») : pas de lecture, images clés au '
                        'curseur.',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $line', style: tt.bodySmall),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _haloOf(PhaseKind kind) => switch (kind) {
    PhaseKind.concentrique => 'halo vif',
    PhaseKind.excentrique => 'halo plus doux',
    PhaseKind.isometrique => 'pulsation lente',
  };
}
