// CU (dev6.8.0, PIPELINE_CP) : « Compléter mon profil » (profil v3).
//
// Utilisateurs existants : les questions du schéma 3 qui comptent pour eux,
// et une invitation discrète de Koach sur l'accueil, une seule fois.
// Profil créé avec le parcours v3 : les questions reportées (récupération
// d'un débutant…) proposées après la première semaine, une seule fois. Le
// programme en cours n'est pas régénéré (CI1e, C11 : le programme du
// propriétaire suit les mêmes règles que les autres).
import 'package:flutter/material.dart';
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import 'athlete_profile_flow.dart';
import 'athlete_profile_screen.dart' show ProfileScreen;
import 'koach/koach_bubble.dart';
import 'koach/koach_view.dart';
import 'store.dart';
import 'kit/kit.dart';

/// Ouvre « Compléter mon profil » ([deferredOnly] : seulement les
/// questions reportées).
///
/// RV2 (H10) : le remerciement passe par la zone de messages prise avant
/// l'ouverture. Depuis l'invitation de l'accueil, la carte disparaît dès
/// l'appui (invitation vue) : son contexte n'existait plus au retour et le
/// « Merci ! » n'était jamais affiché.
Future<void> openProfileCompletion(
  BuildContext context, {
  bool deferredOnly = false,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final colors = KoachToastColors.of(context);
  final large = koachLargeText(context);
  final res = await Navigator.of(context)
      .push<({Set<String> rubrics, bool program})>(
        MaterialPageRoute(
          builder: (_) => AthleteProfileFlow(
            mode: AthleteFlowMode.complete,
            deferredOnly: deferredOnly,
          ),
        ),
      );
  if (res == null || messenger == null || !messenger.mounted) return;
  messenger.showSnackBar(
    koachSnackBar(
      colors,
      'Merci ! Ton profil est à jour. Ton programme ne change pas.',
      pose: KoachPose.thumbsUp,
      large: large,
    ),
  );
}

/// Invitation de Koach sur l'accueil (une seule fois).
class ProfileCompletionCard extends StatelessWidget {
  const ProfileCompletionCard({super.key});

  static bool get visible => store.profileInviteVisible;

  @override
  Widget build(BuildContext context) {
    final deferred = store.profileCreatedByV3;
    final n = deferred
        ? store.profileDeferredPending.length
        : store.profilePendingQuestions.length;
    return KoachSurface(
      key: const ValueKey('profile-invite'),
      color: KTokens.of(context).fond,
      child: KoachBubble(
        pose: deferred ? KoachPose.think : KoachPose.idea,
        koachHeight: 76,
        text: deferred
            ? 'Ta première semaine est passée. $n question'
                  '${n > 1 ? 's' : ''} rapide${n > 1 ? 's' : ''} sur ta '
                  'récupération, pour mieux doser la suite ?'
            : 'Nouveau : $n question${n > 1 ? 's' : ''} pour mieux régler '
                  'ton entraînement (expérience, records, récupération…). '
                  'Tout est facultatif.',
        // UI4 (R5) : plus de chemin écrit ; « Mon profil » ouvre la page
        // Profil, où ces questions restent dans « Compléter mon profil ».
        why:
            'Ton programme actuel ne change pas. Tu retrouves ces questions '
            'dans ton profil, rubrique « Compléter mon profil ».',
        actions: [
          KoachBubbleAction(
            'Compléter mon profil',
            () {
              store.dismissProfileInvite();
              openProfileCompletion(context, deferredOnly: deferred);
            },
            primary: true,
            key: const ValueKey('profile-invite-open'),
          ),
          KoachBubbleAction(
            'Mon profil',
            () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
            key: const ValueKey('profile-invite-profile'),
          ),
          KoachBubbleAction(
            'Plus tard',
            store.dismissProfileInvite,
            key: const ValueKey('profile-invite-later'),
          ),
        ],
      ),
    );
  }
}
