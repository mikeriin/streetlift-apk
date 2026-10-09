// Réglages › Mon programme (G7, D4) : programme en place (créé avec Koach
// par `kalis_plan`, programme de 40 semaines du propriétaire, ou ancien
// programme L10 affiché tel quel), « Créer un nouveau programme », « Où
// j'en suis », retour à l'ancien programme (7 jours), bloc suivant, et en
// session de test l'inspecteur et le journal du moteur. Carte de l'accueil
// (ProgramHomeCard) : « Où en es-tu ? », fin de bloc, retour possible.
//
// L10 (générateur, aperçu « ce qui change », régénération) est retiré par
// G7 : `kalis_plan` le remplace (D1.4).
import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import 'dart:convert' show utf8;
import 'dart:typed_data' show Uint8List;

import 'app_theme.dart';
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
import 'session_prefs.dart' show SessionSpace;
import 'store.dart';
import 'ui.dart';

const _templateExplain =
    'Le programme de 40 semaines du créateur de Kalis Track (v3.3, révisions '
    'LC1 comprises), repris à l’identique : blocs, décharges et tests.';

Future<void> _openPosition(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const ProgramPositionScreen()));

Future<void> _openNextBlock(BuildContext context) => openNextBlock(context);

class ProgramScreen extends StatelessWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final plan = store.planProgram;
      final inst = store.programInstance;
      final generated = inst?.generated ?? false;
      final dim = Theme.of(context).textTheme.bodySmall;
      final start = store.program.start;
      final children = <Widget>[];
      if (plan != null) {
        final last = plan.blocks.last.block;
        children.add(
          KCard(
            key: const ValueKey('program-model'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Programme créé avec Koach',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Bloc ${plan.blocks.length} · ${last.pass1.weeks} semaines · '
                  '${last.pass1.days.length} séances par semaine '
                  '(${[for (final d in last.pass1.days) weekdayLabel(d.weekday).toLowerCase()].join(', ')}).',
                ),
                const SizedBox(height: 4),
                Text(
                  plan.firstWeek > 1
                      ? 'Commence en semaine ${plan.firstWeek} ; les semaines '
                            'd’avant restent celles de ton programme précédent.'
                      : start == null
                      ? ''
                      : 'Depuis le ${civilDateLabel(start)}.',
                  style: dim,
                ),
              ],
            ),
          ),
        );
      } else {
        children.add(
          KCard(
            key: const ValueKey('program-model'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  generated
                      ? '${store.programSummary['modelLabel'] ?? 'Programme personnalisé'}'
                      : 'Expert streetlifting (40 semaines)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  generated
                      ? '${store.programSummary['explanation'] ?? ''}'
                      : _templateExplain,
                ),
                const SizedBox(height: 6),
                Text(
                  generated
                      ? '${inst!.weeks.length} semaines · programme généré '
                            'avant la création avec Koach, affiché tel quel'
                      : 'Programme embarqué, suivi par Koach comme un '
                            'programme du moteur (blocs, saison, tests) ; '
                            'l’original reste sauvegardé',
                  style: dim,
                ),
              ],
            ),
          ),
        );
      }
      // CI1 : saison du chemin calibré (phases, échéance, semaines
      // particulières du bloc) ; CI1e : saison du programme importé.
      if (storeSeasonOverview() case final season?) {
        children.add(SeasonCard(view: season));
      }
      // CI1e (C11.2) : programme d'origine sauvegardé, retour possible.
      if (store.canRestoreProgramOrigin) {
        children.add(const ProgramOriginCard());
      }
      // G10 (D5.6, D5.7) : évolution du programme — mode, déblocage,
      // historique des changements.
      if (store.athlete != null) {
        final u = store.evolutionUnlock;
        final n = store.evolutionHistory.length;
        final pending = store.evolutionPending.length;
        children.add(
          KCard(
            key: const ValueKey('program-evolution'),
            onTap: () => openEvolutionScreen(context),
            child: KoachSays(
              pose: KoachPose.progressChart,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Évolution de ton programme',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mode ${store.adaptMode == 'free' ? 'libre : je propose, tu décides' : 'assisté : j’applique et je t’explique'}.',
                  ),
                  Text(
                    unlockNextText(
                          next: u.next,
                          weeks: u.weeksToNext,
                          blocks: u.blocksToNext,
                        ) ??
                        'Tout est débloqué.',
                    style: dim,
                  ),
                  Text(
                    '${pending == 0 ? '' : '$pending proposition${pending > 1 ? 's' : ''} en attente · '}'
                    '$n changement${n > 1 ? 's' : ''} dans l’historique',
                    style: dim,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const ValueKey('program-evolution-open'),
                      onPressed: () => openEvolutionScreen(context),
                      child: const Text('Mode, historique, déblocage'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      if (PlanStore(store).planCanUndo) {
        children.add(const ProgramHomeCard(inScreen: true));
      }
      if (start != null) {
        children.add(
          OutlinedButton.icon(
            key: const ValueKey('program-position'),
            icon: const Icon(Icons.my_location),
            label: const Text('Où j’en suis'),
            onPressed: () => _openPosition(context),
          ),
        );
      }
      if (PlanStore(store).planBlockEnding ||
          PlanStore(store).planImportedNextBlockOffered) {
        children.add(
          FilledButton.icon(
            key: const ValueKey('program-next-block'),
            icon: const Icon(Icons.skip_next_outlined),
            label: const Text('Préparer le bloc suivant'),
            onPressed: () => _openNextBlock(context),
          ),
        );
      }
      if (store.athlete == null) {
        children.add(
          KCard(
            key: const ValueKey('program-no-profile'),
            child: KoachSays(
              pose: KoachPose.you,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Pour créer ton programme, j’ai d’abord besoin de ton '
                    'profil : disciplines, niveau, objectifs, disponibilités, '
                    'matériel.',
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileScreen(),
                      ),
                    ),
                    child: const Text('Mon profil'),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        children.add(
          KCard(
            key: const ValueKey('program-create'),
            child: KoachSays(
              pose: KoachPose.checklist,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    start == null
                        ? 'On crée ton programme ensemble : d’abord les '
                              'exercices, puis les séries et les charges.'
                        : 'Tu peux créer un nouveau programme à partir de ton '
                              'profil. Rien ne change tant que tu ne l’as pas '
                              'validé, et ton historique reste tel quel.',
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    key: const ValueKey('program-create-open'),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: Text(
                      start == null
                          ? 'Créer mon programme'
                          : 'Créer un nouveau programme',
                    ),
                    onPressed: PlanStore(store).planCanCreate
                        ? () => openPlanCreation(context)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }
      if (kDevBuild && SessionSpace.isDev) {
        children.add(const KSection('Outils de test'));
        // G10 (D2.5) : simulateur de séances, inspecteur et journal du
        // moteur dynamique.
        children.add(
          OutlinedButton.icon(
            key: const ValueKey('program-simulator'),
            icon: const Icon(Icons.fast_forward_outlined),
            label: const Text('Simulateur de séances'),
            onPressed: () => openDevSimulator(context),
          ),
        );
        children.add(
          OutlinedButton.icon(
            key: const ValueKey('program-adapt-inspector'),
            icon: const Icon(Icons.insights_outlined),
            label: const Text('Inspecteur du moteur dynamique'),
            onPressed: () => openEngineInspector(context),
          ),
        );
        children.add(
          OutlinedButton.icon(
            key: const ValueKey('program-inspector'),
            icon: const Icon(Icons.manage_search),
            label: const Text('Inspecteur du moteur'),
            onPressed: plan == null || store.athleteProfileForEngines == null
                ? null
                : () {
                    final b = plan.blocks.last;
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
        );
        children.add(
          OutlinedButton.icon(
            key: const ValueKey('program-journal'),
            icon: const Icon(Icons.ios_share),
            label: const Text('Exporter le journal du moteur (JSON)'),
            onPressed: PlanStore(store).planJournalText == null
                ? null
                : () async {
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
        );
      }
      return KScreen(
        appBar: AppBar(title: const Text('MON PROGRAMME')),
        body: KList(key: const ValueKey('program-list'), children: children),
      );
    },
  );
}

/// Carte de l'accueil : « Où en es-tu ? » (programme sans journal récent),
/// fin de bloc, retour possible à l'ancien programme (7 jours).
class ProgramHomeCard extends StatelessWidget {
  final bool inScreen;
  const ProgramHomeCard({super.key, this.inScreen = false});

  static bool get visible =>
      PlanStore(store).planCanUndo ||
      PlanStore(store).planBlockEnding ||
      PlanStore(store).planPositionProposed;

  @override
  Widget build(BuildContext context) {
    final undo = PlanStore(store).planCanUndo;
    final ending = !inScreen && PlanStore(store).planBlockEnding;
    final position = !inScreen && PlanStore(store).planPositionProposed;
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
      accent: SL.accent,
      child: KoachSays(
        pose: ending
            ? KoachPose.progressChart
            : position
            ? KoachPose.direction
            : KoachPose.settings,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (ending)
                  FilledButton(
                    key: const ValueKey('program-home-next'),
                    onPressed: () => _openNextBlock(context),
                    child: const Text('Voir le bloc suivant'),
                  ),
                if (position && !ending) ...[
                  FilledButton(
                    key: const ValueKey('program-home-position'),
                    onPressed: () => _openPosition(context),
                    child: const Text('Où j’en suis'),
                  ),
                  TextButton(
                    key: const ValueKey('program-home-later'),
                    onPressed: () => PlanStore(store).snoozePlanPosition(),
                    child: const Text('Plus tard'),
                  ),
                ],
                if (undo && !ending && !position)
                  OutlinedButton(
                    key: const ValueKey('program-home-undo'),
                    onPressed: () {
                      final ok = PlanStore(store).undoPlanProgram();
                      showKoachToast(
                        context,
                        ok
                            ? 'Ton ancien programme est rétabli.'
                            : 'Retour impossible : une séance du nouveau '
                                  'programme est déjà saisie.',
                        pose: ok ? KoachPose.thumbsUp : KoachPose.oops,
                      );
                    },
                    child: const Text('Revenir à l’ancien programme'),
                  ),
                if (!inScreen)
                  TextButton(
                    key: const ValueKey('program-home-open'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ProgramScreen(),
                      ),
                    ),
                    child: const Text('Mon programme'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// CI1e (C11.2) : programme d'origine sauvegardé automatiquement avant que
/// le programme de 40 semaines passe sous toutes les fonctionnalités ;
/// « Revenir à mon programme d'origine » et export de la sauvegarde.
class ProgramOriginCard extends StatelessWidget {
  const ProgramOriginCard({super.key});

  // La carte suit elle-même le magasin : instance constante, elle n'est
  // pas reconstruite avec l'écran.
  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: store, builder: (context, _) => _card(context));

  Widget _card(BuildContext context) {
    final at = store.programOriginAt;
    final differs = store.programDiffersFromOrigin;
    final blocked = differs && store.programOriginBlocked;
    final dim = Theme.of(context).textTheme.bodySmall;
    return KCard(
      key: const ValueKey('program-origin'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ton programme d’origine',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Sauvegardé automatiquement'
            '${at == null ? '' : ' le ${civilDateLabel(at)}'}, avant que '
            'Koach suive ton programme comme un programme du moteur : '
            'programme et journal tels qu’ils étaient.',
          ),
          const SizedBox(height: 4),
          Text(
            blocked
                ? 'Ton programme a changé depuis, et tu as déjà fait des '
                      'séances du programme écrit ensuite : le retour à '
                      'l’origine n’est plus possible (ces séances ne '
                      'correspondraient plus à ton programme).'
                : differs
                ? 'Ton programme a changé depuis (propositions de Koach, '
                      'nouveau bloc…). Revenir à l’origine rend le programme '
                      'd’avant ; tes séances faites restent dans ton journal.'
                : 'Ton programme est encore celui d’origine.',
            key: const ValueKey('program-origin-state'),
            style: dim,
          ),
          Text(
            'Le fichier exporté est une sauvegarde complète : l’importer '
            'remplace toutes tes données, journal compris.',
            style: dim,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const ValueKey('program-origin-restore'),
                onPressed: differs && !blocked
                    ? () => _confirmRestore(context)
                    : null,
                child: const Text('Revenir à mon programme d’origine'),
              ),
              TextButton(
                key: const ValueKey('program-origin-export'),
                onPressed: () => _export(context),
                child: const Text('Exporter cette sauvegarde'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revenir à ton programme d’origine ?'),
        content: const Text(
          'Ton programme redevient exactement celui d’avant : les '
          'propositions de Koach acceptées depuis, un bloc écrit par le '
          'moteur et tes réponses à « Où j’en suis » sont retirés. Ton '
          'journal ne change pas : les séances faites et les séries '
          'validées restent. Koach continue de suivre ton programme : en '
          'mode assisté, il pourra de nouveau l’ajuster (en mode libre, '
          'tu décides de chaque changement).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const ValueKey('program-origin-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revenir à l’origine'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final done = store.restoreProgramOrigin();
    showKoachToast(
      context,
      done
          ? 'Ton programme d’origine est rétabli.'
          : 'Retour impossible : la sauvegarde d’origine est illisible.',
      pose: done ? KoachPose.thumbsUp : KoachPose.oops,
    );
  }

  Future<void> _export(BuildContext context) async {
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
}
