// Reprise après interruption (L4b, KT-018) : bandeau de l'accueil.
//
// Règles du 26/09/2026 : plusieurs journées peuvent avoir un brouillon ;
// quitter un écran n'est pas abandonner.
import 'package:flutter/material.dart';

import 'home_screen.dart' show openProgramDay;
import 'store.dart';
import 'ui.dart';

class ResumeBanner extends StatelessWidget {
  const ResumeBanner({super.key});

  /// Quelque chose à reprendre ou à signaler.
  static bool get visible => store.sessionsInProgress.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final sessions = store.sessionsInProgress;
    final detail = KType.detail.copyWith(color: k.texte2);
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Semantics(
      container: true,
      child: KCard(
        key: const ValueKey('resume-banner'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.timelapse_rounded, size: KSize.icon, color: k.encre),
                const SizedBox(width: KSpacing.s8),
                Expanded(
                  child: Text(
                    'À reprendre',
                    style: KType.titreCarte.copyWith(color: k.texte),
                  ),
                ),
              ],
            ),
            for (final s in sessions.take(3))
              Padding(
                padding: const EdgeInsets.only(top: KSpacing.s8),
                child: Builder(
                  builder: (context) {
                    final text = Text(
                      '${s.title}, ${s.done}/${s.total} séries validées',
                      style: KType.corps.copyWith(color: k.texte),
                    );
                    final button = KTonalButton(
                      key: ValueKey('resume-${s.key}'),
                      label: 'Reprendre',
                      onPressed: () =>
                          openProgramDay(Navigator.of(context), s.week, s.day),
                    );
                    // Grand texte : le bouton passe sous la séance.
                    return large
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              text,
                              const SizedBox(height: KSpacing.s8),
                              button,
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: text),
                              const SizedBox(width: KSpacing.s8),
                              button,
                            ],
                          );
                  },
                ),
              ),
            if (sessions.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: KSpacing.s8),
                child: Text(
                  '+ ${sessions.length - 3} autre${sessions.length > 4 ? 's' : ''} '
                  'séance${sessions.length > 4 ? 's' : ''} en cours (« En cours » '
                  'sur la journée).',
                  style: detail,
                ),
              ),
            const SizedBox(height: KSpacing.s8),
            Text(
              'Tes séries validées sont enregistrées ; le repos n’est pas relancé.',
              style: detail,
            ),
          ],
        ),
      ),
    );
  }
}
