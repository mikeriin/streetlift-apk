// CI1g (dev6.11.1, pipeline CP, DECISIONS_CP.md C11.7) — note de bloc
// `clearance_first` de `kalis_plan` 0.3.1 (point imposé par CY) : avis
// médical avant la première semaine (questionnaire de santé « prudent »,
// ou gêne déclarée à 5/10 ou plus). Montrée avant la première séance du
// bloc comme une étape à confirmer : « J'ai eu l'avis d'un médecin ou d'un
// kiné » (gardé pour le bloc) ou « Pas encore » (redemandé à la séance
// suivante ; en attendant, la séance rappelle de ne faire que les
// mouvements qui ne réveillent pas la douleur).
//
// UI2 (refonte UI) : étape au gabarit de confirmation du kit (bloquante,
// même logique), rappel en carte du kit ; l'état passe par `avertissement`.
import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachUsage;

import '../koach/koach_bubble.dart';
import '../plan/coach_texts.dart' show coachText;
import '../store.dart';
import '../ui.dart';
import 'widgets/session_kit.dart';

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
  final k = KTokens.of(context);
  final confirmed = await showKChoice(
    context,
    required: true,
    dialogKey: const ValueKey('clearance-dialog'),
    icon: Icons.shield_outlined,
    iconColor: k.avertissement,
    title: 'Avis médical d’abord',
    body: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text),
        const SizedBox(height: KSpacing.s12),
        Text(
          'Tu as eu cet avis ?',
          style: KType.corpsFort.copyWith(color: k.texte),
        ),
      ],
    ),
    confirmLabel: 'J’ai eu l’avis d’un médecin ou d’un kiné',
    cancelLabel: 'Pas encore',
    confirmKey: const ValueKey('clearance-confirm'),
    cancelKey: const ValueKey('clearance-not-yet'),
  );
  if (confirmed) {
    store.confirmClearance(pending.key);
  } else {
    clearanceDeferred.add(key);
  }
}

/// Rappel en tête de la séance tant que l'avis n'est pas confirmé pour le
/// bloc (après « Pas encore ») ; vide sinon. UI2 : sans écart final, la
/// page qui l'affiche espace ses cartes.
List<Widget> clearanceCard(int week, int j) {
  final pending = store.clearancePending(week, j);
  if (pending == null) return const [];
  return [
    Builder(
      builder: (context) {
        final k = KTokens.of(context);
        return KCard(
          key: const ValueKey('clearance-card'),
          accent: k.avertissement,
          child: KoachSays(
            pose: koachPose(KoachUsage.care),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: KSize.iconSmall,
                      color: k.avertissement,
                    ),
                    const SizedBox(width: KSpacing.s8),
                    Expanded(
                      child: Text(
                        'Avis médical pas encore confirmé',
                        style: KType.corpsFort.copyWith(color: k.texte),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: KSpacing.s8),
                  child: Text(
                    clearanceText(pending.reason),
                    style: KType.corps.copyWith(color: k.texte),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: KSpacing.s8),
                  child: Text(
                    kClearanceWaiting,
                    style: KType.corps.copyWith(color: k.texte),
                  ),
                ),
                const SizedBox(height: KSpacing.s12),
                KTonalButton(
                  key: const ValueKey('clearance-card-confirm'),
                  onPressed: () => store.confirmClearance(pending.key),
                  label: 'J’ai l’avis',
                ),
              ],
            ),
          ),
        );
      },
    ),
  ];
}
