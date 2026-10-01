// G6 (D1.6, D6.5) : Réglages › Profil. Chaque rubrique du profil
// d'athlète v2 se modifie à part (même écran que la création) ; un
// changement qui touche le programme est signalé par Koach (la
// régénération arrive en G7). Santé : mode prudent, consentement, accord
// du médecin (règles L8/L13 inchangées).
import 'package:flutter/material.dart';
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import 'app_theme.dart';
import 'athlete_profile.dart';
import 'athlete_profile_flow.dart';
import 'koach/koach_bubble.dart';
import 'koach/koach_view.dart';
import 'plan/plan_screens.dart' show openPlanCreation;
import 'program_explainer.dart';
import 'program_start.dart' show longCivilDate;
import 'store.dart';
import 'ui.dart';

/// Texte d'information affiché avant la collecte des données de santé.
const kHealthInfo =
    'Les réponses de santé et tes blessures ou gênes peuvent être des '
    'données de santé. Elles servent uniquement à adapter ton '
    'entraînement (mode prudent, exercices qui épargnent une zone). Elles '
    'restent sur ce téléphone, figurent dans l’export de sauvegarde et sont '
    'effacées avec les données de l’application. Tu peux retirer ton accord '
    'à tout moment (Réglages › Profil) : elles sont alors effacées. Sans '
    'accord, l’application fonctionne en mode prudent.';

const kCautionAdvice =
    'Mode prudent : pas de test maximal, au moins 3 répétitions en réserve sur '
    'les mouvements principaux, charges limitées à 80 % du 1RM estimé. '
    'Demande l’avis d’un médecin avant de t’entraîner intensément.';

/// État du mode prudent, raisons et conseil (jamais la couleur seule).
class CautionCard extends StatelessWidget {
  final CautionStatus status;
  final List<Widget> actions;
  const CautionCard({super.key, required this.status, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final on = status.active;
    return KCard(
      key: const ValueKey('caution-card'),
      accent: on ? SL.action : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                on ? Icons.shield_outlined : Icons.check_circle_outline,
                color: on ? SL.accent : SL.success,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  on
                      ? 'Mode prudent activé'
                      : status.cleared
                      ? 'Mode prudent levé (accord du médecin déclaré)'
                      : 'Mode prudent non nécessaire',
                  key: const ValueKey('caution-state'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if (status.reasons.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final r in status.reasons)
              Text('• ${kCautionReasonLabels[r] ?? r}'),
          ],
          if (on) ...[
            const SizedBox(height: 6),
            Text(kCautionAdvice, style: Theme.of(context).textTheme.bodySmall),
          ],
          ...actions,
        ],
      ),
    );
  }
}

/// Réglages › Profil : rubriques du profil v2, santé et mode prudent.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final a = store.athlete;
      final legacy = store.profile;
      final dim = Theme.of(context).textTheme.bodySmall;
      final draft = a == null ? null : store.athleteEditDraft();
      String name(String id) => store.content.byId[id]?.nom ?? id;
      return KScreen(
        appBar: AppBar(title: const Text('PROFIL')),
        body: KList(
          key: const ValueKey('profile-screen'),
          children: [
            if (a == null)
              KCard(
                key: const ValueKey('profile-missing'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KoachSays(
                      pose: KoachPose.wave,
                      child: Text(
                        legacy == null
                            ? 'Aucun profil pour l’instant. On le crée '
                                  'ensemble en 5 minutes environ ?'
                            : 'Ton profil date de l’ancienne version. On le '
                                  'refait ensemble ? Ton programme, ton '
                                  'historique et tes réglages ne changent pas.',
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      key: const ValueKey('profile-create'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (ctx) => AthleteProfileFlow(
                            mode: AthleteFlowMode.redo,
                            onDone: () => Navigator.pop(ctx),
                            onCancel: () => Navigator.pop(ctx),
                          ),
                        ),
                      ),
                      child: Text(
                        legacy == null
                            ? 'Créer mon profil'
                            : 'Refaire mon profil',
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              KoachSurface(
                color: SL.bg,
                child: KoachBubble(
                  key: const ValueKey('profile-koach'),
                  pose: a.programChangePending
                      ? KoachPose.settings
                      : KoachPose.present,
                  text: a.programChangePending
                      ? 'Tu as changé des choses qui touchent ton programme. '
                            'On peut le refaire ensemble dans Réglages › Mon '
                            'programme ; en attendant, il ne change pas.'
                      : 'Touche une rubrique pour la modifier. Si un '
                            'changement touche ton programme, je te le dirai.',
                ),
              ),
              const ProgramExplainerButton(),
              for (final r in kRubricTitles.keys)
                KCard(
                  key: ValueKey('profile-rubric-$r'),
                  onTap: () => _edit(context, r),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(kRubricTitles[r]!, style: dim),
                            const SizedBox(height: 2),
                            Text(rubricSummary(r, draft!, name)),
                          ],
                        ),
                      ),
                      IconButton(
                        key: ValueKey('profile-edit-$r'),
                        tooltip: 'Modifier : ${kRubricTitles[r]}',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _edit(context, r),
                      ),
                    ],
                  ),
                ),
            ],
            if (store.hasAnyProfile) ...[
              CautionCard(
                status: store.caution,
                actions: [
                  if (store.caution.active && store.caution.clearable) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: const ValueKey('profile-clearance'),
                      onPressed: () => _confirmClearance(context),
                      child: const Text('J’ai l’accord de mon médecin'),
                    ),
                  ],
                  if (store.caution.cleared &&
                      legacy?.health.clearanceAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Accord déclaré le ${_day(legacy!.health.clearanceAt!)}',
                      style: dim,
                    ),
                    TextButton(
                      key: const ValueKey('profile-clearance-remove'),
                      onPressed: store.removeDoctorClearance,
                      child: const Text('Retirer l’accord déclaré'),
                    ),
                  ],
                ],
              ),
              _healthCard(context, legacy, a),
            ],
          ],
        ),
      );
    },
  );

  Widget _healthCard(BuildContext context, UserProfile? p, AthleteRecord? a) {
    final dim = Theme.of(context).textTheme.bodySmall;
    final given = p?.health.consentGiven ?? false;
    final content =
        (p?.health.hasHealthContent ?? false) ||
        (p != null && kHealthFields.any(p.fields.containsKey)) ||
        (a?.profile.limitations.isNotEmpty ?? false);
    return KCard(
      key: const ValueKey('profile-health'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Données de santé',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(kHealthInfo, style: dim),
          const SizedBox(height: 8),
          if (given) ...[
            Text('Accord donné le ${_day(p!.health.consentAt!)}'),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('profile-consent-withdraw'),
              onPressed: () => _confirmWithdraw(context),
              child: const Text('Retirer mon accord'),
            ),
            if (content)
              TextButton(
                key: const ValueKey('profile-health-delete'),
                onPressed: store.deleteHealthData,
                child: const Text('Supprimer mes réponses de santé'),
              ),
          ] else
            FilledButton(
              key: const ValueKey('profile-consent-give'),
              onPressed: () => store.setHealthConsent(true),
              child: const Text('Donner mon accord'),
            ),
        ],
      ),
    );
  }

  static String _day(String at) {
    final d = DateTime.tryParse(at);
    return d == null ? at : longCivilDate(d);
  }

  Future<void> _edit(BuildContext context, String rubric) async {
    final res = await Navigator.push<({Set<String> rubrics, bool program})>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AthleteProfileFlow(mode: AthleteFlowMode.edit, editStep: rubric),
      ),
    );
    if (res == null || !context.mounted) return;
    if (res.program) {
      final redo = await showKoachSheet<bool>(
        context,
        pose: KoachPose.settings,
        title: 'Ton programme',
        text:
            'Ce changement touche ton programme. On le refait ensemble ? Ton '
            'programme actuel ne change pas tant que tu n’as pas validé le '
            'nouveau.',
        actions: [
          KoachBubbleAction(
            'Créer un nouveau programme',
            () => Navigator.of(context).pop(true),
            primary: true,
            key: const ValueKey('profile-program-redo'),
          ),
          KoachBubbleAction(
            'Plus tard',
            () => Navigator.of(context).pop(false),
            key: const ValueKey('profile-program-later'),
          ),
        ],
      );
      if (redo == true && context.mounted) await openPlanCreation(context);
    } else if (res.rubrics.isNotEmpty) {
      showKoachToast(context, 'Profil enregistré.');
    }
  }

  Future<void> _confirmClearance(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accord du médecin'),
        content: const Text(
          'Confirme qu’un médecin t’a donné son accord pour t’entraîner '
          'intensément, en connaissant tes réponses. Cette déclaration '
          'est datée ; une nouvelle réponse « oui » ou une nouvelle gêne '
          'remet le mode prudent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const ValueKey('clearance-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Je confirme'),
          ),
        ],
      ),
    );
    if (ok == true) store.declareDoctorClearance();
  }

  Future<void> _confirmWithdraw(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer ton accord ?'),
        content: const Text(
          'Tes réponses de santé et tes blessures ou gênes seront effacées '
          'de ce téléphone. Le mode prudent s’appliquera.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const ValueKey('withdraw-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirer et effacer'),
          ),
        ],
      ),
    );
    if (ok == true) store.setHealthConsent(false);
  }
}
