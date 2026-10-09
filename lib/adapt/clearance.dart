// CI1g (dev6.11.1, pipeline CP, DECISIONS_CP.md C11.7) — note de bloc
// `clearance_first` de `kalis_plan` 0.3.1 (point imposé par CY) : avis
// médical avant la première semaine (questionnaire de santé « prudent »,
// ou gêne déclarée à 5/10 ou plus). Montrée avant la première séance du
// bloc comme une étape à confirmer : « J'ai eu l'avis d'un médecin ou d'un
// kiné » (gardé pour le bloc) ou « Pas encore » (redemandé à la séance
// suivante ; en attendant, la séance rappelle de ne faire que les
// mouvements qui ne réveillent pas la douleur).
import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachUsage;

import '../app_theme.dart';
import '../koach/koach_bubble.dart';
import '../plan/coach_texts.dart' show coachText;
import '../store.dart';
import '../ui.dart';

/// Séances où « Pas encore » a été répondu depuis le lancement (clé de la
/// note et clé du journal : la session de test a ses propres blocs) : la
/// question n'y revient pas avant le prochain lancement.
final Set<String> clearanceDeferred = <String>{};

/// Consigne tant que l'avis n'est pas confirmé.
const String kClearanceWaiting =
    'En attendant l’avis, fais seulement les mouvements qui ne réveillent '
    'pas la douleur, sans forcer ; arrête un mouvement qui fait mal.';

/// Texte de la note du bloc (rédigé par `kalis_plan`).
String clearanceText(kc.Reason reason) =>
    coachText(reason, store.content.catalog) ??
    'Avant la première semaine, prends l’avis d’un médecin ou d’un '
        'kinésithérapeute et montre-lui ce programme.';

/// Étape bloquante avant la séance (S[week], J[j]) : rien si l'avis est
/// déjà confirmé pour le bloc, si le bloc ne le demande pas, ou si « Pas
/// encore » a déjà été répondu pour cette séance depuis le lancement.
Future<void> askClearance(BuildContext context, int week, int j) async {
  final pending = store.clearancePending(week, j);
  if (pending == null) return;
  final key = '${pending.key}|${store.sessionKey(week, j)}';
  if (clearanceDeferred.contains(key)) return;
  final text = clearanceText(pending.reason);
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        key: const ValueKey('clearance-dialog'),
        icon: Icon(Icons.shield_outlined, color: SL.accent),
        title: const Text('Avis médical d’abord'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text),
              const SizedBox(height: 10),
              const Text(
                'Tu as eu cet avis ?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        actionsOverflowDirection: VerticalDirection.down,
        actionsOverflowButtonSpacing: 4,
        actions: [
          TextButton(
            key: const ValueKey('clearance-not-yet'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Pas encore'),
          ),
          FilledButton(
            key: const ValueKey('clearance-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('J’ai eu l’avis d’un médecin ou d’un kiné'),
          ),
        ],
      ),
    ),
  );
  if (confirmed == true) {
    store.confirmClearance(pending.key);
  } else {
    clearanceDeferred.add(key);
  }
}

/// Rappel en tête de la séance tant que l'avis n'est pas confirmé pour le
/// bloc (après « Pas encore ») ; vide sinon.
List<Widget> clearanceCard(int week, int j) {
  final pending = store.clearancePending(week, j);
  if (pending == null) return const [];
  return [
    KCard(
      key: const ValueKey('clearance-card'),
      accent: SL.accent,
      child: KoachSays(
        pose: koachPose(KoachUsage.care),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: SL.accent),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Avis médical pas encore confirmé',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(clearanceText(pending.reason)),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(kClearanceWaiting),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('clearance-card-confirm'),
              onPressed: () => store.confirmClearance(pending.key),
              child: const Text('J’ai eu l’avis'),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 12),
  ];
}
