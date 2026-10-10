import 'package:flutter/material.dart';

import 'anatomy_screen.dart';
import 'exercise_screens.dart';
import 'ui.dart';

/// Onglet Arsenal — référence : fiches d'exercices et anatomie. G2 : les
/// séances manuelles et les WOD ont été retirés (D1.1), l'application se
/// recentre sur le programme.
class ArsenalScreen extends StatelessWidget {
  const ArsenalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KScreen(
      appBar: const KTopBar(),
      body: KList(
        padding: KSpace.content,
        children: [
          const KPageIntro(
            'Arsenal',
            'Tes exercices. Tes muscles. Ta technique.',
          ),
          KMenuTile(
            key: const ValueKey('arsenal-exercises'),
            icon: Icons.menu_book_outlined,
            title: 'Exercices',
            subtitle: 'Fiches, démonstrations, muscles et progressions',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()),
            ),
          ),
          // M2 (mannequin 3D) : référence consultée avec les fiches
          // d'exercices.
          KMenuTile(
            key: const ValueKey('arsenal-anatomy'),
            icon: Icons.accessibility_new_rounded,
            title: 'Anatomie',
            subtitle: 'Muscles, groupes et vues',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnatomyScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
