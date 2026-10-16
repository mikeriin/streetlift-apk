// KM3 (dev7.0.0) : inspecteur de Koach 1.0 et outils du mode dev (builds
// de développement, session de test ; absent de l'AAB par [kDevBuild]) :
// raisons et traces de la séance, capacités, qualités, note (biais, bruit),
// fatigue, planification, surveillance, contrôle dual, adhérence, temps de
// calcul réels ; export du journal moteur et du dossier hors modèle,
// import d'un fichier de paramètres, rejeu walk-forward, bascule forcée.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kalis_adapt/koach.dart' as ko;
import 'package:kalis_adapt/koach_textes.dart';

import '../athlete_profile.dart' show civilOf;
import '../backup_files.dart';
import '../kit/kit.dart';
import '../koach1/koach_moteur.dart' show KoachExtensions;
import '../session_prefs.dart' show SessionSpace;
import '../store.dart';
import 'dev_flags.dart';
import 'dev_session.dart' show DevShare;

/// Ouvre l'inspecteur (build de développement, session de test).
Future<void> openKoachInspector(BuildContext context) {
  if (!kDevBuild || !SessionSpace.isDev) return Future.value();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const KoachInspectorScreen()),
  );
}

String _n(Object? v, [int d = 2]) =>
    v is num ? v.toStringAsFixed(d).replaceAll('.', ',') : '—';

/// Partage un JSON par le menu du système (aucun réseau).
Future<void> _share(BuildContext context, String name, Object? json) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (json == null) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('Rien à exporter pour l’instant.')),
    );
    return;
  }
  final r = await DevShare.shareJson(
    name,
    const JsonEncoder.withIndent(' ').convert(json),
  );
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        r == 'shared' ? 'Fichier prêt : choisis où l’envoyer.' : 'Export impossible ($r).',
      ),
    ),
  );
}

class KoachInspectorScreen extends StatefulWidget {
  const KoachInspectorScreen({super.key});

  @override
  State<KoachInspectorScreen> createState() => _KoachInspectorScreenState();
}

class _KoachInspectorScreenState extends State<KoachInspectorScreen> {
  Map<String, Object?>? _wf;
  Map<String, Object?>? _import;
  bool _busy = false;

  Future<void> _walkForward() async {
    setState(() => _busy = true);
    final r = await store.koachWalkForward();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _wf = r;
    });
  }

  Future<void> _importParams() async {
    final opened = await backupFiles.open(2000000);
    if (!mounted || opened.status != FileOpenStatus.opened) return;
    final text = utf8.decode(opened.bytes!, allowMalformed: true);
    setState(() => _import = store.koachImportParams(text));
  }

  Widget _section(KTokens k, String title, List<String> lines, {Key? key}) =>
      KCard(
        key: key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: KType.titreCarte.copyWith(color: k.texte)),
            const SizedBox(height: KSpacing.s8),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: KSpacing.s4),
                child: SelectableText(
                  l,
                  style: KType.detail.copyWith(color: k.texte),
                ),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final k = KTokens.of(context);
      final e = store.koachEngine;
      final live = store.koachLive;
      final today = civilOf(store.storeClock());
      final temps = store.koachTemps.resume;
      final replay = store.koachLastReplay;
      final versions = [
        'Moteur : ${ko.koachVersion}',
        'Paramètres : ${live?.params['version'] ?? e.snap?.versionParametres ?? '—'}',
        'SHA-256 paramètres : ${ko.koachParametresSha256.substring(0, 16)}…',
        'SHA-256 fiches : ${ko.koachFichesSha256.substring(0, 16)}…',
        'Imports de paramètres : '
            '${e.journal.where((x) => x['type'] == 'parametres').length}',
      ];
      final etat = [
        e.snap == null
            ? 'Koach n’a pas pris la main.'
            : 'Actif depuis S${e.fromWeek} (${e.activatedOn}) · '
                  'semaines fermées : ${e.closed}',
        if (e.stop != null) 'Arrêt d’urgence depuis le ${e.stop!['since']}',
        'Événements au journal : ${e.journal.length}',
        'Séances versées : ${e.versed.length}',
        'Bascule : ${store.koachBasculeDate.iso}'
            ' (${store.koachBasculeOuverte ? 'ouverte' : 'fermée dans ce build'}'
            '${e.forced != null ? ', forcée' : ''})',
        'Installation : ${e.installedOn ?? '—'}',
      ];
      final tempsLines = [
        for (final t in temps.entries)
          '${t.key} : ${_n(t.value.dernier, 1)} ms (max ${_n(t.value.max, 1)} ms, '
              'n = ${t.value.n})',
        if (replay != null)
          'Dernier rejeu complet : ${replay.ms} ms pour ${replay.events} '
              'événements',
        'Cahier : replanification ≤ 10 000 ms, série ≤ 50 ms.',
      ];
      // Séance du jour (ou la dernière servie).
      final seance = <String>[];
      for (final entry in store.logs.entries.toList().reversed) {
        final raw = entry.value.adapt?['koach'];
        if (raw is! Map || raw['state'] == 'preview') continue;
        seance.add('${entry.key} (${raw['state']}, jour ${raw['jour']})');
        for (final r in (raw['raisons'] as List? ?? const [])) {
          if (r is! Map) continue;
          seance.add(
            '• ${r['code']} ${jsonEncode(r['params'])} — '
            '${texteRaisonKoach(r.cast<String, Object?>(), nomExercice: (x) => store.content.byId[x]?.nom)}',
          );
        }
        final cibles = raw['cibles'];
        if (cibles is Map) {
          for (final c in cibles.entries) {
            final m = c.value;
            if (m is! Map) continue;
            for (final x in m.entries) {
              final v = x.value;
              if (v is! Map) continue;
              seance.add(
                '${c.key} #${x.key} : ${v['loadKg'] ?? '—'} kg · '
                '${v['repsLow'] ?? v['secondsLow']}-'
                '${v['repsHigh'] ?? v['secondsHigh']} · ${v['flames']} flammes'
                '${v['trace'] == null ? '' : ' · ${v['trace']}'}',
              );
            }
          }
        }
        break;
      }
      final post = live?.posterior();
      final caps = <String>[];
      if (post != null) {
        caps.add(
          'Biais de la note : ${_n((post['biais_rir'] as List?)?.first)} · '
          'bruit × ${_n(post['bruit_rir'])} · note paresseuse '
          '${_n(post['note_paresseuse'])}',
        );
        final ex = (post['exercices'] as Map?) ?? const {};
        for (final x in ex.entries.take(40)) {
          final v = x.value as Map;
          final iv = v['intervalle_90'] as List?;
          caps.add(
            '${store.content.byId[x.key]?.nom ?? x.key} (${v['type']}) : '
            '${_n(v['valeur'], 1)} [${_n(iv?[0], 1)} ; ${_n(iv?[2], 1)}] · '
            '${v['seances']} séances, ${v['mesures']} mesures',
          );
        }
      }
      final quals = <String>[];
      if (post != null && live != null) {
        final names = (live.params['qualites'] as List? ?? const []);
        final m = post['qualites'] as List? ?? const [];
        final sd = post['qualites_sd'] as List? ?? const [];
        for (var i = 0; i < m.length && i < names.length; i++) {
          quals.add('${names[i]} : ${_n(m[i], 3)} ± ${_n(sd[i], 3)}');
        }
        final fat = post['fatigue'] as Map?;
        if (fat != null) {
          quals.add(
            'Fatigue nerveuse ${_n((fat['nerveux'] as Map?)?['systemique'], 3)} · '
            'musculaire ${_n((fat['musculaire'] as Map?)?['systemique'], 3)}',
          );
        }
      }
      final pl = live?.planification;
      final plan = <String>[];
      if (pl != null) {
        final h = pl.historique.isEmpty ? null : pl.historique.last;
        if (h != null) {
          plan.add(
            'Semaine ${h['semaine']} · plans évalués ${h['plans']} · '
            'objectif ${_n(h['objectif'], 3)} · référence '
            '${_n(h['valeur_reference'] ?? h['reference'], 3)} · '
            '${h['plan_garde'] == true ? 'plan gardé' : 'plan modulé'}',
          );
          final pc = h['p_cibles'];
          if (pc is Map) {
            for (final c in pc.entries) {
              plan.add(
                'P(${store.content.byId[c.key]?.nom ?? c.key}) = ${_n(c.value, 3)}',
              );
            }
          }
        }
        final g = e.snap == null
            ? 0
            : (today.dayNumber - e.snap!.lundiDate.dayNumber) ~/ 7;
        final mod = pl.plan[g];
        if (mod != null) plan.add('Modulation de la semaine : ${jsonEncode(mod)}');
        plan.add('Prévisions : ${pl.previsions.length}');
      }
      final sv = live?.surveillance;
      final surv = sv == null
          ? <String>[]
          : [
              'Hors modèle : ${sv.etat()['hors_modele']} · '
                  'p = ${_n(sv.etat()['p_rupture'], 3)} · causes '
                  '${(sv.etat()['causes'] as List).join(', ')}',
              'Silence : ${(sv.etatComplet()['silence'] as List).join(', ')} · '
                  'mauvais jours de suite : ${sv.etatComplet()['mj_suite']}',
            ];
      final dual = live?.dual;
      final dualLines = dual == null
          ? <String>[]
          : [
              'Calibré : ${ko.calibre(live!, dual.lifts).$1} · essai : '
                  '${dual.essai == null ? 'aucun' : 'en cours'}',
              for (final r in dual.raisons.reversed.take(5))
                texteRaisonDual(r, nomExercice: (x) => store.content.byId[x]?.nom),
            ];
      final ad = live?.adherence;
      final adLines = ad == null
          ? <String>[]
          : [
              'Refus récents : ${ad.refusRecents(live!.jour)}',
              for (final c in ad.contraintes()) jsonEncode(c),
            ];
      return KPage.sub(
        key: const ValueKey('koach-inspector'),
        title: 'Inspecteur de Koach 1.0',
        children: [
          _section(k, 'État', etat, key: const ValueKey('ki-etat')),
          _section(k, 'Versions', versions),
          _section(k, 'Temps de calcul (téléphone)', tempsLines,
              key: const ValueKey('ki-temps')),
          if (seance.isNotEmpty) _section(k, 'Séance', seance),
          if (caps.isNotEmpty) _section(k, 'Capacités', caps),
          if (quals.isNotEmpty) _section(k, 'Qualités et fatigue', quals),
          if (plan.isNotEmpty) _section(k, 'Planification', plan),
          if (surv.isNotEmpty) _section(k, 'Surveillance', surv),
          if (dualLines.isNotEmpty) _section(k, 'Contrôle dual', dualLines),
          if (adLines.isNotEmpty) _section(k, 'Adhérence', adLines),
          const KSectionTitle('Outils'),
          KTonalButton(
            key: const ValueKey('ki-export-journal'),
            icon: Icons.ios_share,
            label: 'Exporter le journal moteur',
            onPressed: () async => _share(
              context,
              'koach_journal_moteur.json',
              await store.koachJournalExport(),
            ),
          ),
          KTonalButton(
            key: const ValueKey('ki-export-dossier'),
            icon: Icons.ios_share,
            label: 'Exporter le dossier hors modèle',
            onPressed: () => _share(
              context,
              'koach_dossier_hors_modele.json',
              store.koachDossierExport(),
            ),
          ),
          KTonalButton(
            key: const ValueKey('ki-import-params'),
            icon: Icons.file_open_outlined,
            label: 'Importer un fichier de paramètres',
            onPressed: _importParams,
          ),
          if (_import != null)
            _section(k, 'Import de paramètres', [
              _import!['ok'] == true
                  ? 'Importé : version ${_import!['version']}. La '
                        'planification, le contrôle dual et la détection de '
                        'rupture gardent leurs paramètres d’origine.'
                  : 'Refusé :',
              for (final x in (_import!['erreurs'] as List? ?? const []))
                '• $x',
            ]),
          KTonalButton(
            key: const ValueKey('ki-walk-forward'),
            icon: Icons.replay_rounded,
            label: _busy ? 'Rejeu en cours…' : 'Rejeu walk-forward (depuis S12)',
            onPressed: _busy ? null : _walkForward,
          ),
          if (_wf != null)
            _section(k, 'Rejeu walk-forward', [
              'Séances rejouées : ${_wf!['seances_rejouees']}, évaluées : '
                  '${_wf!['seances_evaluees']}',
              'A : ${jsonEncode(_wf!['A_une_seance_d_avance'])}',
              'A (séries fiables) : ${jsonEncode(_wf!['A_series_fiables'])}',
              'Critère 10 : ${jsonEncode(_wf!['critere_10'])}',
            ], key: const ValueKey('ki-wf')),
          const KSectionTitle('Bascule (session de test)'),
          KTonalButton(
            key: const ValueKey('ki-force'),
            icon: Icons.bolt_rounded,
            label: e.forced == null
                ? 'Koach prend la main cette semaine'
                : 'Revenir à la date du cahier',
            onPressed: () async {
              store.koachForceBascule(e.forced == null ? today : null);
              await store.koachRefresh();
            },
          ),
        ],
      );
    },
  );
}
