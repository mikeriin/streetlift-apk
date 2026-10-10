// Reprise après interruption (L4b, KT-018) : bandeau de l'accueil.
//
// Règles du 26/09/2026 : plusieurs journées peuvent avoir un brouillon ;
// quitter un écran n'est pas abandonner.
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'home_screen.dart' show openProgramDay;
import 'store.dart';
import 'ui.dart';

class ResumeBanner extends StatelessWidget {
  const ResumeBanner({super.key});

  /// Quelque chose à reprendre ou à signaler.
  static bool get visible => store.sessionsInProgress.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final sessions = store.sessionsInProgress;
    final small = Theme.of(context).textTheme.bodySmall;
    Widget line(String text, String action, VoidCallback onTap, Key key) =>
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(child: Text(text)),
              const SizedBox(width: 8),
              TextButton(key: key, onPressed: onTap, child: Text(action)),
            ],
          ),
        );
    return Semantics(
      container: true,
      child: KCard(
        key: const ValueKey('resume-banner'),
        accent: SL.action,
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('À reprendre', style: Theme.of(context).textTheme.titleMedium),
            for (final s in sessions.take(3))
              line(
                '${s.title} · ${s.done}/${s.total} séries validées',
                'Reprendre',
                () => openProgramDay(Navigator.of(context), s.week, s.day),
                ValueKey('resume-${s.key}'),
              ),
            if (sessions.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${sessions.length - 3} autre${sessions.length > 4 ? 's' : ''} '
                  'séance${sessions.length > 4 ? 's' : ''} en cours (badge sur la journée).',
                  style: small,
                ),
              ),
            Text(
              'Tes séries validées sont enregistrées ; le repos n’est pas relancé.',
              style: small,
            ),
          ],
        ),
      ),
    );
  }
}
