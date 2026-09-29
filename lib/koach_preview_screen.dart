// M7b (mannequin 3D) : écran « Koach (aperçu) » (Arsenal › Anatomie ›
// Koach (aperçu)).
//
// Demande du propriétaire (28/09/2026, style précisé le 29/09/2026) : une
// petite bibliothèque d'animations « personnage » du mannequin, pour que
// Koach devienne plus tard une mascotte qui apparaît quand c'est pertinent.
// Ce lot ne fait que les animations et cet aperçu : Koach n'apparaît encore
// nulle part ailleurs dans l'application.
//
// Neuf animations en trois familles (tools/anatomy/koach_animations.py,
// passées par la chaîne d'import de M7) : attente (respiration et
// changement d'appui, regard et épaules, étirement), Koach parle (une main,
// deux mains, montre sur le côté), Koach félicite (applaudit, poing levé,
// pouce levé). Style un peu exagéré, comme dans les anime. Chacune se joue
// au choix, en boucle, avec le lecteur de M7 ; mannequin neutre (aucun
// muscle allumé).
//
// Placé dans l'écran Anatomie (et non dans Réglages › À propos › Moteur 3D,
// réservé aux tests techniques) : c'est un aperçu du personnage, que le
// propriétaire consulte avec le mannequin. Manipulation : boutons Face /
// Dos / Profil / 3/4 et zoom au pincement ; pas de rotation au doigt
// (décision du propriétaire du 29/09/2026, PIPELINE_3D.md §2).
import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'mannequin_3d.dart';
import 'mannequin_clip.dart';
import 'mannequin_player.dart';
import 'ui.dart';

class KoachPreviewScreen extends StatefulWidget {
  /// Animation choisie à l'ouverture (identifiant du registre).
  final String? initialClip;
  const KoachPreviewScreen({super.key, this.initialClip});

  @override
  State<KoachPreviewScreen> createState() => KoachPreviewScreenState();
}

class KoachPreviewScreenState extends State<KoachPreviewScreen> {
  List<ClipEntry>? _clips;
  ClipEntry? _selected;
  String? _error;
  // Nouvelle clé à chaque animation : lecteur recréé (départ au début,
  // cadrage propre au clip).
  GlobalKey<MannequinPlayerState> _player = GlobalKey();

  /// Lecteur (tests d'intégration).
  MannequinPlayerState? get player => _player.currentState;

  /// Animations de Koach du registre (tests).
  List<ClipEntry> get clips => _clips ?? const [];

  /// Animation en cours (tests).
  ClipEntry? get selected => _selected;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final registry = await ClipRegistry.load();
      if (!mounted) return;
      final clips = registry.koachClips;
      setState(() {
        _clips = clips;
        _selected = clips.isEmpty
            ? null
            : clips.firstWhere(
                (c) => c.id == widget.initialClip,
                orElse: () => clips.first,
              );
        if (clips.isEmpty) _error = 'Aucune animation de Koach dans le registre.';
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Registre des animations illisible.');
    }
  }

  /// Choisit une animation (puces, tests).
  void select(String id) {
    final c = clips.where((c) => c.id == id);
    if (c.isEmpty || identical(c.first, _selected)) return;
    setState(() {
      _selected = c.first;
      _player = GlobalKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final clip = _selected;
    return KScreen(
      appBar: AppBar(title: const Text('KOACH (APERÇU)')),
      body: KList(
        key: const ValueKey('koach-preview-list'),
        gap: 10,
        children: [
          Text(
            'Aperçu des animations de Koach, future mascotte de '
            'l’application : il n’apparaît pas encore ailleurs. Choisis une '
            'animation, elle se joue en boucle.',
            key: const ValueKey('koach-preview-intro'),
            style: tt.bodyMedium,
          ),
          if (_error != null)
            Text(_error!, key: const ValueKey('koach-preview-error'))
          else if (clip == null)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _chips(context, clip),
            KCard(
              key: const ValueKey('koach-preview-card'),
              child: MannequinPlayer(
                key: _player,
                clip: clip,
                view: MannequinView.face,
                height: 380,
                semanticLabel:
                    'Koach en 3D, animation « ${clip.name} » '
                    '(${kKoachFamilies[clip.family] ?? ''})',
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
            Text(
              clip.name,
              key: const ValueKey('koach-preview-name'),
              style: tt.titleMedium,
            ),
            Text(
              [
                kKoachFamilies[clip.family] ?? '',
                playerSeconds(clip.duration),
                clip.loop ? 'boucle' : 'revient à la pose d’attente',
              ].join(' · '),
              key: const ValueKey('koach-preview-info'),
              style: tt.bodySmall?.copyWith(color: SL.dim),
            ),
            Text(
              'Boutons Face, Dos, Profil, 3/4 pour tourner Koach, pince pour '
              'zoomer. Toutes les animations partent de la même pose '
              'd’attente et y reviennent.',
              style: tt.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _chips(BuildContext context, ClipEntry selected) {
    final tt = Theme.of(context).textTheme;
    final byFamily = <String, List<ClipEntry>>{};
    for (final c in clips) {
      byFamily.putIfAbsent(c.family ?? '', () => []).add(c);
    }
    return Column(
      key: const ValueKey('koach-preview-chips'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in byFamily.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(kKoachFamilies[e.key] ?? e.key, style: tt.labelLarge),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final c in e.value)
                ChoiceChip(
                  key: ValueKey('koach-chip-${c.id}'),
                  label: Text(c.name),
                  selected: identical(c, selected),
                  onSelected: (_) => select(c.id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
