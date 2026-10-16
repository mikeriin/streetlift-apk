// KM3 (dev7.0.0) : écrans et cartes de Koach 1.0 — suggestion de la séance
// validée d'un tap (refus avec raison facultative), diagnostic hors modèle
// en trois questions au plus, récapitulatif de fin de bloc, état de Koach
// et arrêt d'urgence. Textes : `package:kalis_adapt/koach_textes.dart`
// (jamais un code brut à l'écran).
import 'package:flutter/material.dart';
import 'package:kalis_adapt/koach_textes.dart';
import 'package:kalis_koach/kalis_koach.dart' show KoachPose, KoachUsage;

import '../adapt/adapt_texts.dart' show adaptKgLabel;
import '../kit/kit.dart';
import '../models.dart' show DayPlan, Exercise;
import '../koach/koach_bubble.dart';
import '../store.dart';
import 'koach_moteur.dart' show Json;

/// Raisons d'un refus, dans l'ordre de la feuille (null : sans raison).
const kKoachRefusals = <(String?, String)>[
  ('too_heavy', 'Trop lourd'),
  ('too_light', 'Trop léger'),
  ('equipment', 'Matériel'),
  ('time', 'Temps'),
  ('other', 'Autre'),
  (null, 'Sans raison'),
];

/// Raison d'un refus en un tap ; rend `''` si la feuille est fermée sans
/// choix, null pour « Sans raison », sinon le code.
Future<String?> showKoachRefusalSheet(BuildContext context) async {
  final i = await showKListSheet(
    context,
    title: 'Pourquoi ?',
    summary: 'Facultatif : ça m’aide à mieux te proposer.',
    items: [
      for (final r in kKoachRefusals)
        KListItem(r.$2, icon: Icons.chevron_right_rounded),
    ],
  );
  if (i == null) return '';
  return kKoachRefusals[i].$1;
}

/// Suggestion de Koach sur la première série d'un exercice : charge
/// proposée par rapport au dernier passage, ou vrai test court. Validée
/// d'un tap ; refusée avec une raison facultative.
class KoachSuggestionCard extends StatelessWidget {
  final int week;
  final DayPlan day;
  final Exercise exercise;
  final VoidCallback onChanged;
  const KoachSuggestionCard({
    super.key,
    required this.week,
    required this.day,
    required this.exercise,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = store.koachSuggestion(week, day.j, exercise);
    if (s == null) return const SizedBox.shrink();
    final k = KTokens.of(context);
    final id = exercise.id;
    String kg(double? v) => v == null ? '' : adaptKgLabel(v);
    final String text;
    final String? detail;
    final String okLabel;
    final String noLabel;
    if (s.type == 'test') {
      text =
          'Je te propose un test court avant le travail : une montée '
          'jusqu’à la dernière série propre.';
      detail = 'Il me dit où tu en es aujourd’hui. Tu peux le passer.';
      okLabel = 'Faire le test';
      noLabel = 'Passer';
    } else {
      final up = s.type == 'charge_plus';
      text = up
          ? 'Je te propose ${kg(s.to)} (dernière fois ${kg(s.from)}).'
          : 'Je te propose de redescendre à ${kg(s.to)} (dernière fois '
                '${kg(s.from)}).';
      detail = s.steps.length > 1
          ? 'Par étapes : ${s.steps.map(kg).join(' puis ')}.'
          : null;
      okLabel = 'Valider';
      noLabel = 'Refuser';
    }
    if (s.decided != null) {
      final done = s.type == 'test'
          ? (s.decided == 'ok' ? 'Test accepté.' : 'Test passé.')
          : (s.decided == 'ok'
                ? 'Validé : ${kg(s.to)}.'
                : 'Refusé : ${kg(s.from)} gardés.');
      return Padding(
        key: ValueKey('koach-suggestion-done-$id'),
        padding: const EdgeInsets.only(top: KSpacing.s8),
        child: Text(done, style: KType.detail.copyWith(color: k.texte2)),
      );
    }
    Future<void> refuse() async {
      final reason = await showKoachRefusalSheet(context);
      if (reason == '') return;
      store.koachDecide(week, day, exercise, false, reason: reason);
      onChanged();
    }

    return Padding(
      key: ValueKey('koach-suggestion-$id'),
      padding: const EdgeInsets.only(top: KSpacing.s8),
      child: Material(
        color: k.surface,
        shape: RoundedRectangleBorder(
          borderRadius: KRadius.menuRadius,
          side: BorderSide(color: k.filet),
        ),
        child: Padding(
          padding: const EdgeInsets.all(KSpacing.s12),
          child: KoachSays(
            pose: koachPose(KoachUsage.proposal),
            koachHeight: KSize.menuIcon + KSpacing.s4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: KType.corpsFort.copyWith(color: k.texte)),
                if (detail != null)
                  Text(detail, style: KType.detail.copyWith(color: k.texte2)),
                const SizedBox(height: KSpacing.s8),
                Wrap(
                  spacing: KSpacing.s8,
                  runSpacing: KSpacing.s8,
                  children: [
                    KPrimaryButton(
                      key: ValueKey('koach-accept-$id'),
                      label: okLabel,
                      expand: false,
                      onPressed: () {
                        store.koachDecide(week, day, exercise, true);
                        onChanged();
                      },
                    ),
                    KTonalButton(
                      key: ValueKey('koach-refuse-$id'),
                      label: noLabel,
                      onPressed: refuse,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Diagnostic hors modèle (trois questions au plus) : message de Koach,
/// puis les questions de la surveillance, chacune en un tap. Rend les
/// réponses, ou null (passé).
Future<Json?> showKoachDiagnostic(BuildContext context) async {
  final causes = store.koachAlertCauses;
  final reponses = <String, Object?>{};
  final intro = [
    texteHorsModeleKoach,
    for (final c in causes) texteRaisonKoach({'code': c}),
  ].join(' ');
  final go = await showKoachSheet<bool>(
    context,
    pose: KoachPose.think,
    title: 'Avant de commencer',
    text: intro,
    actions: [
      KoachBubbleAction(
        'Répondre (3 questions au plus)',
        () => Navigator.of(context).pop(true),
        primary: true,
        key: const ValueKey('koach-diag-start'),
      ),
      KoachBubbleAction(
        'Plus tard',
        () => Navigator.of(context).pop(false),
        key: const ValueKey('koach-diag-later'),
      ),
    ],
  );
  if (go != true || !context.mounted) return null;
  for (var step = 0; step < 3; step++) {
    final qs = store.koachQuestions(reponses);
    if (step >= qs.length) break;
    final q = qs[step];
    final code = '${q['code']}';
    final choix = [for (final c in (q['choix'] as List? ?? const [])) c];
    if (choix.isEmpty) break;
    final i = await showKListSheet(
      context,
      title: texteQuestionKoach(code),
      items: [for (final c in choix) KListItem(texteChoixKoach(code, c))],
    );
    if (i == null || !context.mounted) return null;
    reponses[code] = choix[i];
  }
  return reponses.isEmpty ? null : reponses;
}

/// État de Koach (Évolution, Réglages) : depuis quand il conduit le
/// programme, prochaine replanification, arrêt d'urgence ou réactivation.
class KoachEngineCard extends StatelessWidget {
  const KoachEngineCard({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final k = KTokens.of(context);
      final e = store.koachEngine;
      final body = KType.corps.copyWith(color: k.texte);
      final detail = KType.detail.copyWith(color: k.texte2);
      String date(String? iso) {
        final d = iso == null ? null : parseCivilDate(iso);
        return d == null ? '' : civilDateLabel(d);
      }

      final List<Widget> rows;
      if (e.snap == null) {
        final b = store.koachBasculeDate;
        rows = [
          Text(
            store.koachBasculeOuverte
                ? 'Je prendrai les commandes de ton programme au début de '
                      'ton prochain bloc, à partir du '
                      '${civilDateLabel(DateTime(b.year, b.month, b.day))}.'
                : 'Koach 1.0 est installé. Il prendra les commandes au '
                      'début d’un bloc, une fois sa version validée '
                      '(date visée : ${civilDateLabel(DateTime(b.year, b.month, b.day))}). '
                      'D’ici là, ton bloc en cours continue comme avant.',
            key: const ValueKey('koach-engine-waiting'),
            style: body,
          ),
          if (e.blocked == 'poids')
            Text(
              'Il me faut ton poids (profil ou pesée) avant de commencer.',
              style: detail,
            ),
        ];
      } else if (e.stop != null) {
        rows = [
          Text(
            'Koach est arrêté depuis le ${date(e.stop!['since'] as String?)} : '
            'tes séances sont servies telles qu’écrites. Rien n’est perdu.',
            key: const ValueKey('koach-engine-stopped'),
            style: body,
          ),
          const SizedBox(height: KSpacing.s4),
          Text(
            'Sans Koach, pas de conduite sous douleur ni d’ajustement au '
            'bilan : si une douleur dure, consulte un professionnel.',
            style: detail,
          ),
          const SizedBox(height: KSpacing.s8),
          KPrimaryButton(
            key: const ValueKey('koach-resume'),
            label: 'Réactiver Koach',
            expand: false,
            onPressed: () => store.koachResume(),
          ),
        ];
      } else {
        rows = [
          Text(
            'Koach conduit ton programme depuis S${e.fromWeek} '
            '(${date(e.activatedOn)}) : il propose, tu valides d’un tap. '
            'Chaque lundi, il replanifie la semaine qui vient.',
            key: const ValueKey('koach-engine-active'),
            style: body,
          ),
          if (store.koachBusy) Text('Koach prépare ta semaine…', style: detail),
          if (store.koachNeedsDiagnostic)
            Text(
              'Quelque chose sort de mon modèle : je te poserai trois '
              'questions au plus au début de ta prochaine séance.',
              style: detail,
            ),
          const SizedBox(height: KSpacing.s8),
          KTonalButton(
            key: const ValueKey('koach-stop'),
            label: 'Arrêt d’urgence',
            onPressed: () async {
              final ok = await showKConfirm(
                context,
                title: 'Arrêter Koach ?',
                message:
                    'Ton plan est figé à la semaine en cours et tes séances '
                    'sont servies telles qu’écrites. Rien n’est perdu : '
                    'tu peux le réactiver ici.',
                confirmLabel: 'Arrêter',
                destructive: true,
              );
              if (ok) store.koachStop();
            },
          ),
        ];
      }
      return KCard(
        key: const ValueKey('koach-engine-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Koach 1.0', style: KType.titreCarte.copyWith(color: k.texte)),
            const SizedBox(height: KSpacing.s8),
            ...rows,
          ],
        ),
      );
    },
  );
}

/// Carte « Bloc suivant : ce qui change et pourquoi » (accueil, Mon
/// programme) ; rien quand il n'y a rien à valider.
class KoachRecapCard extends StatelessWidget {
  const KoachRecapCard({super.key});

  @override
  Widget build(BuildContext context) {
    final r = store.koachRecap();
    if (r == null) return const SizedBox.shrink();
    final k = KTokens.of(context);
    return KCard(
      key: const ValueKey('koach-recap-card'),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const KoachRecapScreen())),
      child: KoachSays(
        pose: koachPose(KoachUsage.analysis),
        child: Text(
          'Nouveau bloc en S${r.week} : ce qui change et pourquoi. '
          'Touche pour voir et valider.',
          style: KType.corpsFort.copyWith(color: k.texte),
        ),
      ),
    );
  }
}

/// Libellés des dix qualités latentes de Koach.
const kKoachQualites = <String, String>{
  'pousser': 'poussée',
  'tirer': 'tirage',
  'jambes': 'jambes',
  'tronc': 'gainage',
  'figures': 'figures',
  'endurance_force': 'endurance de force',
  'explosivite': 'explosivité',
  'aerobie': 'endurance',
  'anaerobie': 'capacité anaérobie',
  'mobilite': 'mobilité',
};

String _qualite(String code) =>
    kKoachQualites[code] ?? code.replaceAll('_', ' ');

/// Récapitulatif de fin de bloc : volume par qualité et intensité du bloc
/// suivant par rapport au plan écrit, chances d'atteindre chaque cible ;
/// validé d'un tap.
class KoachRecapScreen extends StatelessWidget {
  const KoachRecapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = store.koachRecap();
    final k = KTokens.of(context);
    final body = KType.corps.copyWith(color: k.texte);
    if (r == null) {
      return const KPage.sub(
        key: ValueKey('koach-recap'),
        title: 'Bloc suivant',
        children: [Text('Rien à valider pour l’instant.')],
      );
    }
    String pct(double x) {
      final v = (x * 100).round();
      return '${v > 0 ? '+' : (v < 0 ? '−' : '')}${v.abs()} %';
    }

    final changes = [
      for (final e in r.volume.entries)
        if ((e.value - 1).abs() >= 0.01)
          'Volume ${_qualite(e.key)} : ${pct(e.value - 1)}.',
      if (r.intensity.abs() >= 0.005)
        'Charges : ${pct(r.intensity)} en moyenne.',
    ];
    return KPage.sub(
      key: const ValueKey('koach-recap'),
      title: 'Bloc suivant (S${r.week})',
      children: [
        KCard(
          child: KoachSays(
            pose: koachPose(KoachUsage.analysis),
            child: Text(
              r.kept || changes.isEmpty
                  ? 'Je garde ton bloc tel qu’il est écrit : aucun plan ne '
                        'fait mieux pour tes objectifs.'
                  : 'Voici ce que je change par rapport au bloc écrit, pour '
                        'te donner plus de chances d’atteindre tes '
                        'objectifs à la date prévue.',
              style: KType.corpsFort.copyWith(color: k.texte),
            ),
          ),
        ),
        if (changes.isNotEmpty) ...[
          const KSectionTitle('Ce qui change'),
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final c in changes) Text(c, style: body)],
            ),
          ),
        ],
        if (r.success.isNotEmpty) ...[
          const KSectionTitle('Tes objectifs'),
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in r.success.entries)
                  Text(
                    '${store.content.byId[e.key]?.nom ?? 'Objectif'} : '
                    '${(e.value.$1 * 100).round()} % de chances'
                    '${e.value.$2 == null || (e.value.$2! * 100).round() == (e.value.$1 * 100).round() ? '' : ' (plan écrit : ${(e.value.$2! * 100).round()} %)'}.',
                    style: body,
                  ),
              ],
            ),
          ),
        ],
        KPrimaryButton(
          key: const ValueKey('koach-recap-ok'),
          label: 'Valider',
          onPressed: () {
            store.koachRecapDecide(r.block, true);
            Navigator.of(context).pop();
          },
        ),
        KTextButton(
          key: const ValueKey('koach-recap-no'),
          label: 'Je préfère le bloc écrit',
          onPressed: () {
            store.koachRecapDecide(r.block, false);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
