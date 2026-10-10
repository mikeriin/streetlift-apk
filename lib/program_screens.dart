// Mon programme (G7, D4 ; UI1 : gabarit de menu, cahier §4.1) : programme
// en place (créé avec Koach par `kalis_plan`, programme de 40 semaines du
// propriétaire, ou ancien programme L10 affiché tel quel) ; cartes Ma saison
// et Évolution ; groupes Calendrier (départ, « Où j'en suis »), Changer de
// programme (bloc suivant, nouveau programme, retour à un programme
// précédent, chaque retour confirmé), Aide ; en session de test,
// l'inspecteur et le journal du moteur. Carte de l'accueil
// (ProgramHomeCard) : « Où en es-tu ? », fin de bloc, retour possible.
//
// L10 (générateur, aperçu « ce qui change », régénération) est retiré par
// G7 : `kalis_plan` le remplace (D1.4).
import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import 'dart:convert' show utf8;
import 'dart:typed_data' show Uint8List;

import 'athlete_profile_screen.dart' show ProfileScreen;
import 'backup_files.dart';
import 'dev/dev_flags.dart';
import 'dev/dev_session.dart' show DevShare;
import 'koach/koach_bubble.dart';
import 'dev/engine_inspector.dart';
import 'dev/dev_simulator.dart';
import 'plan/evolution_texts.dart';
import 'plan/evolution_widgets.dart';
import 'plan/plan_inspector.dart';
import 'plan/plan_screens.dart';
import 'plan/plan_texts.dart';
import 'plan/program_position.dart';
import 'plan/season_view.dart';
import 'program_explainer.dart';
import 'program_start.dart' show ProgramStartScreen, longCivilDate;
import 'session_prefs.dart' show SessionSpace;
import 'store.dart';
import 'ui.dart';

const _templateExplain =
    'Expert streetlifting, 40 semaines : le programme du créateur de Kalis '
    'Track (version 3.3), repris à l’identique (blocs, décharges, tests). '
    'Koach le suit comme ses propres programmes (blocs, saison, tests) ; '
    'l’original reste sauvegardé.';

Future<void> _openPosition(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const ProgramPositionScreen()));

Future<void> _openNextBlock(BuildContext context) => openNextBlock(context);

Future<void> _openProfile(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));

/// Ouvre Mon programme (ligne permanente de l'accueil, §4.1).
Future<void> openMyProgram(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const ProgramScreen()));

/// Pourquoi « Créer mon programme » est indisponible (R6), null s'il l'est.
String? planCreateBlockedReason() {
  if (PlanStore(store).planCanCreate) return null;
  if (store.athlete == null) {
    return 'Il me faut d’abord ton profil : disciplines, niveau, objectifs, '
        'disponibilités, matériel.';
  }
  if (store.content.catalog == null) {
    return 'La base d’exercices n’est pas encore chargée : réessaie dans un '
        'instant.';
  }
  return 'Ton profil est incomplet pour créer un programme : complète-le '
      'dans Mon profil.';
}

/// Phrase d'en-tête : le programme en place.
String _modelText() {
  final plan = store.planProgram;
  final start = store.program.start;
  if (plan != null) {
    final last = plan.blocks.last.block;
    final days = [
      for (final d in last.pass1.days) weekdayLabel(d.weekday).toLowerCase(),
    ].join(', ');
    final since = plan.firstWeek > 1
        ? ' Commence en semaine ${plan.firstWeek} ; les semaines d’avant '
              'restent celles de ton programme précédent.'
        : start == null
        ? ''
        : ' Depuis le ${civilDateLabel(start)}.';
    return 'Programme créé avec Koach : bloc ${plan.blocks.length}, '
        '${last.pass1.weeks} semaines, ${last.pass1.days.length} séances par '
        'semaine ($days).$since';
  }
  final inst = store.programInstance;
  if (inst?.generated ?? false) {
    final label =
        '${store.programSummary['modelLabel'] ?? 'Programme personnalisé'}';
    final explain = '${store.programSummary['explanation'] ?? ''}';
    return [
      '$label.',
      if (explain.isNotEmpty) explain,
      '${inst!.weeks.length} semaines, programme généré avant la création '
          'avec Koach, affiché tel quel.',
    ].join(' ');
  }
  return _templateExplain;
}

class ProgramScreen extends StatelessWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final plan = store.planProgram;
      final start = store.program.start;
      final children = <Widget>[
        KeyedSubtree(
          key: const ValueKey('program-model'),
          child: KLead(_modelText()),
        ),
      ];
      // CI1 : saison du chemin calibré (phases, échéance, semaines
      // particulières du bloc) ; CI1e : saison du programme importé.
      if (storeSeasonOverview() case final season?) {
        children.add(SeasonCard(view: season));
      }
      // G10 (D5.6, D5.7) : évolution du programme — mode, déblocage,
      // historique des changements.
      if (store.athlete != null) children.add(const _EvolutionCard());

      final position = PlanStore(store).programPosition;
      children.add(
        KMenuGroup(
          title: 'Calendrier',
          children: [
            KMenuRow(
              key: const ValueKey('program-start'),
              icon: Icons.event_outlined,
              title: 'Départ du programme',
              subtitle: start == null
                  ? 'Pas encore choisi : choisis ta première séance'
                  : 'S1 · J1 le ${longCivilDate(start)}',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProgramStartScreen(),
                ),
              ),
            ),
            if (start != null)
              KMenuRow(
                key: const ValueKey('program-position'),
                icon: Icons.my_location_outlined,
                title: 'Où j’en suis',
                subtitle: position == null
                    ? 'Choisis ta semaine et ta séance'
                    : 'Semaine ${position.week}, jour ${position.day}',
                onTap: () => _openPosition(context),
              ),
          ],
        ),
      );

      final canUndo = PlanStore(store).planCanUndo;
      final canOrigin = store.canRestoreProgramOrigin;
      final blocked = planCreateBlockedReason();
      final originAt = store.programOriginAt;
      children.add(
        KMenuGroup(
          title: 'Changer de programme',
          children: [
            if (PlanStore(store).planBlockEnding ||
                PlanStore(store).planImportedNextBlockOffered)
              KMenuRow(
                key: const ValueKey('program-next-block'),
                icon: Icons.skip_next_outlined,
                title: 'Préparer le bloc suivant',
                subtitle: PlanStore(store).planBlockEnding
                    ? 'Ton bloc arrive à son terme : Koach prépare le '
                          'suivant avec toi'
                    : 'Fin d’un bloc de ton programme : Koach peut écrire '
                          'le suivant',
                onTap: () => _openNextBlock(context),
              ),
            if (store.athlete == null)
              KMenuRow(
                key: const ValueKey('program-no-profile'),
                icon: Icons.person_outline_rounded,
                title: 'Créer mon profil',
                subtitle:
                    'Pour créer ton programme, il me faut d’abord ton '
                    'profil : disciplines, niveau, objectifs, '
                    'disponibilités, matériel',
                onTap: () => _openProfile(context),
              )
            else ...[
              KMenuRow(
                key: const ValueKey('program-create-open'),
                icon: Icons.auto_awesome_outlined,
                title: start == null
                    ? 'Créer mon programme'
                    : 'Créer un nouveau programme',
                subtitle:
                    blocked ??
                    (start == null
                        ? 'D’abord les exercices, puis les séries et les '
                              'charges'
                        : 'Koach repart de ton profil ; rien ne change '
                              'avant ta validation, ton historique reste'),
                enabled: blocked == null,
                onTap: () => openPlanCreation(context),
              ),
              if (blocked != null && store.content.catalog != null)
                KMenuRow(
                  key: const ValueKey('program-complete-profile'),
                  icon: Icons.person_outline_rounded,
                  title: 'Mon profil',
                  subtitle: 'Compléter ce qui manque pour créer un programme',
                  onTap: () => _openProfile(context),
                ),
            ],
            if (canUndo || canOrigin)
              KMenuRow(
                key: const ValueKey('program-revert'),
                icon: Icons.history_rounded,
                title: 'Revenir à un programme précédent',
                subtitle: [
                  if (canUndo) 'Ancien programme, pendant 7 jours',
                  if (canOrigin)
                    'Programme d’origine'
                        '${originAt == null ? '' : ', sauvegardé le ${civilDateLabel(originAt)}'}',
                ].join(' ; '),
                onTap: () => showProgramRevert(context),
              ),
          ],
        ),
      );
      children.add(
        KMenuGroup(
          title: 'Aide',
          children: [
            KMenuRow(
              key: const ValueKey('program-explainer-open'),
              icon: Icons.help_outline_rounded,
              title: 'Comment marche ton programme ?',
              subtitle: 'Création, séances et évolution, en 8 étapes',
              onTap: () => showProgramExplainer(context),
            ),
          ],
        ),
      );
      if (kDevBuild && SessionSpace.isDev) {
        children.add(_devTools(context, hasPlan: plan != null));
      }
      return KPage.sub(
        key: const ValueKey('program-list'),
        title: 'Mon programme',
        children: children,
      );
    },
  );

  /// G10 (D2.5) : simulateur de séances, inspecteurs et journal du moteur
  /// (session de test seulement).
  Widget _devTools(BuildContext context, {required bool hasPlan}) {
    final journal = PlanStore(store).planJournalText;
    return KMenuGroup(
      title: 'Outils de test',
      children: [
        KMenuRow(
          key: const ValueKey('program-simulator'),
          icon: Icons.fast_forward_outlined,
          title: 'Simulateur de séances',
          onTap: () => openDevSimulator(context),
        ),
        KMenuRow(
          key: const ValueKey('program-adapt-inspector'),
          icon: Icons.insights_outlined,
          title: 'Inspecteur du moteur dynamique',
          onTap: () => openEngineInspector(context),
        ),
        KMenuRow(
          key: const ValueKey('program-inspector'),
          icon: Icons.manage_search,
          title: 'Inspecteur du moteur',
          enabled: hasPlan && store.athleteProfileForEngines != null,
          onTap: () {
            final b = store.planProgram!.blocks.last;
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlanInspectorScreen(
                  plan: b.block.pass1,
                  request: kc.PlanRequest(
                    profile: store.athleteProfileForEngines!,
                    seed: b.seed,
                    startDate: b.block.pass1.startDate,
                    locks: b.locks,
                  ),
                  journal: PlanStore(store).planJournalText,
                ),
              ),
            );
          },
        ),
        KMenuRow(
          key: const ValueKey('program-journal'),
          icon: Icons.ios_share,
          title: 'Exporter le journal du moteur (JSON)',
          enabled: journal != null,
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            final r = await DevShare.shareJson(
              'kalis_plan_journal.json',
              PlanStore(store).planJournalText!,
            );
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  r == 'shared'
                      ? 'Journal du moteur prêt : choisis où l’envoyer.'
                      : 'Export impossible ($r).',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Carte Évolution de Mon programme : mode, déblocage, propositions et
/// historique ; toute la carte ouvre l'écran Évolution.
class _EvolutionCard extends StatelessWidget {
  const _EvolutionCard();

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final u = store.evolutionUnlock;
    final n = store.evolutionHistory.length;
    final pending = store.evolutionPending.length;
    final detail = KType.detail.copyWith(color: k.texte2);
    return KeyedSubtree(
      key: const ValueKey('program-evolution'),
      child: KCard(
        key: const ValueKey('program-evolution-open'),
        onTap: () => openEvolutionScreen(context),
        semanticsLabel: 'Évolution',
        child: Row(
          children: [
            Expanded(
              child: KoachSays(
                pose: KoachPose.progressChart,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Évolution',
                      style: KType.titreCarte.copyWith(color: k.texte),
                    ),
                    const SizedBox(height: KSpacing.s4),
                    Text(
                      store.adaptMode == 'free'
                          ? 'Mode libre : je propose, tu décides.'
                          : 'Mode assisté : j’applique et je t’explique.',
                      style: KType.corps.copyWith(color: k.texte),
                    ),
                    Text(
                      unlockNextText(
                            next: u.next,
                            weeks: u.weeksToNext,
                            blocks: u.blocksToNext,
                          ) ??
                          'Tout est débloqué.',
                      style: detail,
                    ),
                    Text(
                      '${pending == 0 ? '' : '$pending proposition${pending > 1 ? 's' : ''} en attente, '}'
                      '$n changement${n > 1 ? 's' : ''} dans l’historique',
                      style: detail,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: KSpacing.s8),
            Icon(
              Icons.chevron_right_rounded,
              size: KSize.icon,
              color: k.texte2,
            ),
          ],
        ),
      ),
    );
  }
}

/// « Revenir à un programme précédent » (§4.3, R8) : feuille d'actions des
/// retours possibles (ancien programme pendant 7 jours, programme
/// d'origine) et export de la sauvegarde d'origine ; chaque retour est
/// confirmé.
Future<void> showProgramRevert(BuildContext context) async {
  final undo = PlanStore(store).planCanUndo;
  final origin = store.canRestoreProgramOrigin;
  if (!undo && !origin) return;
  final at = store.programOriginAt;
  final differs = store.programDiffersFromOrigin;
  final blocked = differs && store.programOriginBlocked;
  final originState = blocked
      ? 'Plus possible : ton programme a changé depuis, et tu as déjà fait '
            'des séances du programme écrit ensuite (elles ne '
            'correspondraient plus à ton programme).'
      : differs
      ? 'Ton programme a changé depuis (propositions de Koach, nouveau '
            'bloc…) ; tes séances faites restent dans ton journal.'
      : 'Ton programme est encore celui d’origine.';
  final choice = await showKActionSheet<String>(
    context,
    title: 'Revenir à un programme précédent',
    subtitle: origin
        ? 'Programme d’origine sauvegardé automatiquement'
              '${at == null ? '' : ' le ${civilDateLabel(at)}'}, avant que '
              'Koach suive ton programme : programme et journal tels qu’ils '
              'étaient.'
        : 'Ton nouveau programme est en place ; tu peux revenir à l’ancien.',
    groups: [
      [
        if (undo)
          const KAction(
            icon: Icons.undo_rounded,
            label: 'Revenir à l’ancien programme',
            value: 'undo',
            detail:
                'Pendant 7 jours, tant que tu n’as saisi aucune séance du '
                'nouveau programme.',
          ),
        if (origin)
          KAction(
            icon: Icons.restore_rounded,
            label: 'Revenir à mon programme d’origine',
            value: 'origin',
            enabled: differs && !blocked,
            detail: originState,
          ),
      ],
      if (origin)
        const [
          KAction(
            icon: Icons.save_alt_rounded,
            label: 'Exporter la sauvegarde d’origine',
            value: 'export',
            detail:
                'Sauvegarde complète : l’importer remplace toutes tes '
                'données, journal compris.',
          ),
        ],
    ],
  );
  if (!context.mounted || choice == null) return;
  switch (choice) {
    case 'undo':
      await confirmUndoPlan(context);
    case 'origin':
      await _confirmRestoreOrigin(context);
    case 'export':
      await _exportOrigin(context);
  }
}

/// Retour à l'ancien programme, confirmé (R8).
Future<void> confirmUndoPlan(BuildContext context) async {
  final ok = await showKConfirm(
    context,
    title: 'Revenir à l’ancien programme ?',
    message:
        'Ton programme d’avant est rétabli. Ton journal ne change pas : les '
        'séances faites et les séries validées restent.',
    confirmLabel: 'Revenir',
  );
  if (!ok || !context.mounted) return;
  final done = PlanStore(store).undoPlanProgram();
  showKoachToast(
    context,
    done
        ? 'Ton ancien programme est rétabli.'
        : 'Retour impossible : une séance du nouveau programme est déjà '
              'saisie.',
    pose: done ? KoachPose.thumbsUp : KoachPose.oops,
  );
}

Future<void> _confirmRestoreOrigin(BuildContext context) async {
  final ok = await showKConfirm(
    context,
    title: 'Revenir à ton programme d’origine ?',
    message:
        'Ton programme redevient exactement celui d’avant : les '
        'propositions de Koach acceptées depuis, un bloc écrit par Koach et '
        'tes réponses à « Où j’en suis » sont retirés. Ton journal ne change '
        'pas : les séances faites et les séries validées restent. Koach '
        'continue de suivre ton programme : en mode assisté, il pourra de '
        'nouveau l’ajuster (en mode libre, tu décides de chaque changement).',
    confirmLabel: 'Revenir',
  );
  if (!ok || !context.mounted) return;
  final done = store.restoreProgramOrigin();
  showKoachToast(
    context,
    done
        ? 'Ton programme d’origine est rétabli.'
        : 'Retour impossible : la sauvegarde d’origine est illisible.',
    pose: done ? KoachPose.thumbsUp : KoachPose.oops,
  );
}

Future<void> _exportOrigin(BuildContext context) async {
  final text = store.programOriginExport();
  if (text == null) return;
  final messenger = ScaffoldMessenger.of(context);
  final at = store.programOriginAt ?? store.storeClock();
  String two(int v) => v.toString().padLeft(2, '0');
  final r = await backupFiles.save(
    'kalis-track-programme-origine-${at.year}-${two(at.month)}-'
    '${two(at.day)}.json',
    Uint8List.fromList(utf8.encode(text)),
  );
  messenger.showSnackBar(
    SnackBar(
      content: Text(switch (r.status) {
        FileSaveStatus.saved => 'Sauvegarde d’origine exportée.',
        FileSaveStatus.unverified =>
          'Sauvegarde d’origine écrite, relecture impossible.',
        FileSaveStatus.cancelled => 'Export annulé.',
        FileSaveStatus.failed => 'Export impossible.',
      }),
    ),
  );
}

/// Carte de l'accueil : « Où en es-tu ? » (programme sans journal récent),
/// fin de bloc, retour possible à l'ancien programme (7 jours). Une action
/// tonale, « Plus tard » en lien (C2).
class ProgramHomeCard extends StatelessWidget {
  const ProgramHomeCard({super.key});

  static bool get visible =>
      PlanStore(store).planCanUndo ||
      PlanStore(store).planBlockEnding ||
      PlanStore(store).planPositionProposed;

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final undo = PlanStore(store).planCanUndo;
    final ending = PlanStore(store).planBlockEnding;
    final position = PlanStore(store).planPositionProposed;
    if (!undo && !ending && !position) return const SizedBox.shrink();
    final text = ending
        ? 'Ton bloc arrive à son terme : je prépare le suivant avec toi ?'
        : position
        ? 'Ça fait un moment que tu n’as rien saisi. Tu me dis où tu en es '
              'dans ton programme ?'
        : 'Ton nouveau programme est en place. Tu peux revenir à l’ancien '
              'pendant 7 jours, tant que tu n’as saisi aucune séance du '
              'nouveau.';
    return KCard(
      key: const ValueKey('program-home-card'),
      child: KoachSays(
        pose: ending
            ? KoachPose.progressChart
            : position
            ? KoachPose.direction
            : KoachPose.settings,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text, style: KType.corps.copyWith(color: k.texte)),
            const SizedBox(height: KSpacing.s12),
            Wrap(
              spacing: KSpacing.s8,
              runSpacing: KSpacing.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (ending)
                  KTonalButton(
                    key: const ValueKey('program-home-next'),
                    label: 'Voir le bloc suivant',
                    onPressed: () => _openNextBlock(context),
                  ),
                if (position && !ending) ...[
                  KTonalButton(
                    key: const ValueKey('program-home-position'),
                    label: 'Où j’en suis',
                    onPressed: () => _openPosition(context),
                  ),
                  KTextButton(
                    key: const ValueKey('program-home-later'),
                    label: 'Plus tard',
                    onPressed: () => PlanStore(store).snoozePlanPosition(),
                  ),
                ],
                if (undo && !ending && !position)
                  KTonalButton(
                    key: const ValueKey('program-home-undo'),
                    label: 'Revenir à l’ancien programme',
                    onPressed: () => confirmUndoPlan(context),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
