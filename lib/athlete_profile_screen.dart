// G6 (D1.6, D6.5) : page Profil (carte Profil des Réglages). Chaque rubrique
// du profil d'athlète v2 se modifie à part (même écran que la création) ;
// un changement qui touche le programme est signalé (la régénération arrive
// en G7). Santé : mode prudent, consentement, accord du médecin (règles
// L8/L13 inchangées).
// UI4 (refonte UI, cahier §4.1, §4.5, R3, R5, R8) : sous-page au gabarit
// menu ; « Mes références » (page `PilotageScreen`) ; plus de rubrique
// « Mode assisté ou libre » (le mode vit dans Évolution) ; retraits et
// suppressions confirmés.
import 'package:flutter/material.dart';
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import 'athlete_profile.dart';
import 'athlete_profile_flow.dart';
import 'guided_tests.dart';
import 'koach/koach_bubble.dart';
import 'koach/koach_view.dart';
import 'pilotage_screen.dart' show PilotageScreen;
import 'plan/plan_screens.dart' show openPlanCreation;
import 'profile_completion.dart';
import 'program_explainer.dart';
import 'program_screens.dart' show ProgramScreen;
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
    'à tout moment depuis ton profil : elles sont alors effacées. Sans '
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
    final k = KTokens.of(context);
    final on = status.active;
    return KCard(
      key: const ValueKey('caution-card'),
      accent: on ? k.avertissement : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                on ? Icons.shield_outlined : Icons.check_circle_outline,
                color: on ? k.avertissement : k.validation,
              ),
              const SizedBox(width: KSpacing.s8),
              Expanded(
                child: Text(
                  on
                      ? 'Mode prudent activé'
                      : status.cleared
                      ? 'Mode prudent levé (accord du médecin déclaré)'
                      : 'Mode prudent non nécessaire',
                  key: const ValueKey('caution-state'),
                  style: KType.titreCarte.copyWith(color: k.texte),
                ),
              ),
            ],
          ),
          if (status.reasons.isNotEmpty) ...[
            const SizedBox(height: KSpacing.s8),
            for (final r in status.reasons)
              Text(
                '• ${kCautionReasonLabels[r] ?? r}',
                style: KType.corps.copyWith(color: k.texte),
              ),
          ],
          if (on) ...[
            const SizedBox(height: KSpacing.s8),
            Text(kCautionAdvice, style: KType.detail.copyWith(color: k.texte2)),
          ],
          ...actions,
        ],
      ),
    );
  }
}

/// Icône de chaque rubrique du profil dans la liste du Profil.
const _rubricIcons = <String, IconData>{
  'identity': Icons.person_outline_rounded,
  'discipline': Icons.sports_gymnastics_rounded,
  'secondary': Icons.category_outlined,
  'experience': Icons.timeline_rounded,
  'levels': Icons.fitness_center_rounded,
  'goals': Icons.flag_outlined,
  'availability': Icons.event_available_outlined,
  'places': Icons.place_outlined,
  'recovery': Icons.bedtime_outlined,
  'health': Icons.health_and_safety_outlined,
  'preferences': Icons.thumbs_up_down_outlined,
};

/// Rubriques montrées dans le Profil : toutes celles du parcours, sauf
/// « Mode assisté ou libre », qui se règle dans Évolution (cahier §4.3) ;
/// le parcours de création garde sa question.
Iterable<String> get profileRubrics =>
    kRubricTitles.keys.where((r) => r != 'mode');

/// Profil (carte Profil des Réglages) : rubriques du profil v2, références,
/// tests guidés, santé et mode prudent.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final k = KTokens.of(context);
      final a = store.athlete;
      final legacy = store.profile;
      final dim = KType.detail.copyWith(color: k.texte2);
      final draft = a == null ? null : store.athleteEditDraft();
      String name(String id) => store.content.byId[id]?.nom ?? id;
      final pending = store.profilePendingQuestions.length;
      return KMenuPage(
        key: const ValueKey('profile-screen'),
        root: false,
        title: 'Profil',
        lead:
            'Ce que Koach sait de toi : tes rubriques, tes références, tes '
            'tests et tes données de santé.',
        header: a == null
            ? KCard(
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
                        style: KType.corps.copyWith(color: k.texte),
                      ),
                    ),
                    const SizedBox(height: KSpacing.s12),
                    KPrimaryButton(
                      key: const ValueKey('profile-create'),
                      label: legacy == null
                          ? 'Créer mon profil'
                          : 'Refaire mon profil',
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
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KoachSurface(
                    color: k.fond,
                    child: KoachBubble(
                      key: const ValueKey('profile-koach'),
                      pose: a.programChangePending
                          ? KoachPose.settings
                          : KoachPose.present,
                      text: a.programChangePending
                          ? 'Tu as changé des choses qui touchent ton '
                                'programme. On peut le refaire ensemble dans '
                                'Mon programme ; en attendant, il ne change '
                                'pas.'
                          : 'Touche une rubrique pour la modifier. Si un '
                                'changement touche ton programme, je te le '
                                'dirai.',
                    ),
                  ),
                  // R5 : la destination est un bouton, pas un chemin écrit.
                  if (a.programChangePending)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: KTonalButton(
                        key: const ValueKey('profile-open-program'),
                        label: 'Ouvrir Mon programme',
                        icon: Icons.calendar_month_outlined,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const ProgramScreen(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
        groups: [
          KMenuGroup(
            children: [
              // CU : questions du profil v3 encore sans réponse.
              if (a != null && pending > 0)
                KMenuRow(
                  key: const ValueKey('profile-complete'),
                  icon: Icons.playlist_add_check_rounded,
                  title: 'Compléter mon profil',
                  subtitle:
                      '$pending question${pending > 1 ? 's' : ''} '
                      'facultative${pending > 1 ? 's' : ''}',
                  onTap: () => openProfileCompletion(context),
                ),
              KMenuRow(
                key: const ValueKey('profile-references'),
                icon: Icons.straighten_rounded,
                title: 'Mes références',
                subtitle: 'Poids du corps, 1RM, maxima et accessoires',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PilotageScreen(),
                  ),
                ),
              ),
              if (a != null)
                KMenuRow(
                  key: const ValueKey('profile-tests'),
                  icon: Icons.timer_outlined,
                  title: 'Tests guidés',
                  subtitle: 'Mesurer tes niveaux pas à pas',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const GuidedTestsScreen(),
                    ),
                  ),
                ),
            ],
          ),
          if (a != null)
            KMenuGroup(
              title: 'Rubriques du profil',
              children: [
                for (final r in profileRubrics)
                  // Deux clés historiques : la rubrique et son « Modifier ».
                  KeyedSubtree(
                    key: ValueKey('profile-rubric-$r'),
                    child: KMenuRow(
                      key: ValueKey('profile-edit-$r'),
                      icon: _rubricIcons[r] ?? Icons.tune_rounded,
                      title: kRubricTitles[r]!,
                      subtitle: rubricSummary(r, draft!, name),
                      onTap: () => _edit(context, r),
                    ),
                  ),
              ],
            ),
          if (store.hasAnyProfile) ...[
            const KSectionTitle('Santé et accords'),
            CautionCard(
              status: store.caution,
              actions: [
                if (store.caution.active && store.caution.clearable) ...[
                  const SizedBox(height: KSpacing.s12),
                  KTonalButton(
                    key: const ValueKey('profile-clearance'),
                    label: 'J’ai l’accord de mon médecin',
                    onPressed: () => _confirmClearance(context),
                  ),
                ],
                if (store.caution.cleared &&
                    legacy?.health.clearanceAt != null) ...[
                  const SizedBox(height: KSpacing.s8),
                  Text(
                    'Accord déclaré le ${_day(legacy!.health.clearanceAt!)}',
                    style: dim,
                  ),
                  const SizedBox(height: KSpacing.s8),
                  KTonalButton(
                    key: const ValueKey('profile-clearance-remove'),
                    label: 'Retirer l’accord déclaré',
                    onPressed: () => _confirmClearanceRemoval(context),
                  ),
                ],
              ],
            ),
            _healthCard(context, legacy, a),
          ],
          if (a != null)
            KMenuGroup(
              title: 'Aide',
              children: [
                KMenuRow(
                  key: const ValueKey('program-explainer-open'),
                  icon: Icons.help_outline_rounded,
                  title: 'Comment marche ton programme ?',
                  onTap: () => showProgramExplainer(context),
                ),
              ],
            ),
        ],
      );
    },
  );

  Widget _healthCard(BuildContext context, UserProfile? p, AthleteRecord? a) {
    final k = KTokens.of(context);
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
            style: KType.titreCarte.copyWith(color: k.texte),
          ),
          const SizedBox(height: KSpacing.s8),
          Text(kHealthInfo, style: KType.detail.copyWith(color: k.texte2)),
          const SizedBox(height: KSpacing.s12),
          if (given) ...[
            Text(
              'Accord donné le ${_day(p!.health.consentAt!)}',
              style: KType.corps.copyWith(color: k.texte),
            ),
            const SizedBox(height: KSpacing.s8),
            KTonalButton(
              key: const ValueKey('profile-consent-withdraw'),
              label: 'Retirer mon accord',
              onPressed: () => _confirmWithdraw(context),
            ),
            if (content) ...[
              const SizedBox(height: KSpacing.s8),
              KTonalButton(
                key: const ValueKey('profile-health-delete'),
                label: 'Supprimer mes réponses de santé',
                onPressed: () => _confirmHealthDelete(context),
              ),
            ],
          ] else
            KTonalButton(
              key: const ValueKey('profile-consent-give'),
              label: 'Donner mon accord',
              onPressed: () => store.setHealthConsent(true),
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
      final redo = await showKConfirm(
        context,
        title: 'Refaire ton programme ?',
        message:
            'Ce changement touche ton programme. On le refait ensemble ? Ton '
            'programme actuel ne change pas tant que tu n’as pas validé le '
            'nouveau.',
        confirmLabel: 'Créer un nouveau programme',
        cancelLabel: 'Plus tard',
      );
      if (redo && context.mounted) await openPlanCreation(context);
    } else if (res.rubrics.isNotEmpty) {
      showKoachToast(context, 'Profil enregistré.');
    }
  }

  Future<void> _confirmClearance(BuildContext context) async {
    final ok = await showKConfirm(
      context,
      title: 'Accord du médecin',
      message:
          'Confirme qu’un médecin t’a donné son accord pour t’entraîner '
          'intensément, en connaissant tes réponses. Cette déclaration '
          'est datée ; une nouvelle réponse « oui » ou une nouvelle gêne '
          'remet le mode prudent.',
      confirmLabel: 'Je confirme',
    );
    if (ok) store.declareDoctorClearance();
  }

  Future<void> _confirmClearanceRemoval(BuildContext context) async {
    final ok = await showKConfirm(
      context,
      title: 'Retirer l’accord déclaré ?',
      message:
          'L’accord du médecin ne sera plus pris en compte : le mode prudent '
          's’appliquera de nouveau. Tu pourras le déclarer encore plus tard.',
      confirmLabel: 'Retirer',
    );
    if (ok) store.removeDoctorClearance();
  }

  Future<void> _confirmWithdraw(BuildContext context) async {
    final ok = await showKConfirm(
      context,
      title: 'Retirer ton accord ?',
      message:
          'Tes réponses de santé et tes blessures ou gênes seront effacées '
          'de ce téléphone. Le mode prudent s’appliquera.',
      confirmLabel: 'Retirer et effacer',
      destructive: true,
    );
    if (ok) store.setHealthConsent(false);
  }

  Future<void> _confirmHealthDelete(BuildContext context) async {
    final ok = await showKConfirm(
      context,
      title: 'Supprimer tes réponses de santé ?',
      message:
          'Tes réponses de santé et tes blessures ou gênes seront effacées '
          'de ce téléphone. Ton accord reste enregistré.',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (ok) store.deleteHealthData();
  }
}
