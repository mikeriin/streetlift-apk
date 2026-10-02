import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'models.dart';
import 'session_screen.dart';
import 'ui.dart';
import 'store.dart';

/// Même présentation que l'exécution, sur une copie détachée des saisies.
/// Consulter une archive ne crée ni série, ni séance, ni écriture en stockage.
/// Seules deux actions confirmées écrivent : rouvrir la séance pour corriger
/// ses saisies, ou la supprimer du journal (annulable depuis le message).
class SessionHistoryScreen extends StatefulWidget {
  final SessionLog log;
  final String? sessionKey;
  final WeekPlan? week;
  final DayPlan? day;
  const SessionHistoryScreen({
    super.key,
    required this.log,
    this.sessionKey,
    this.week,
    this.day,
  });

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  final _pages = PageController();
  final _unusedTimer = TimerCtl();
  late final SessionLog _snapshot;
  late final WeekPlan _week;
  late final DayPlan _day;
  late final List<List<Exercise>> _groups;
  final _unresolved = <String>{};
  String? _key;
  int _page = 0;

  /// Entrée encore présente et terminée dans le journal.
  bool get _editable => _key != null && store.logs[_key]?.done == true;

  bool get _correctable => _editable && store.correctionPlan(_key!) != null;

  String get _head => _week.n > 0 ? 'S${_week.n} · J${_day.j}' : _day.title;

  @override
  void initState() {
    super.initState();
    _snapshot = SessionLog.fromJson(widget.log.toJson());
    WeekPlan? week = widget.week;
    DayPlan? day = widget.day;
    String? key = widget.sessionKey;
    if (key == null) {
      for (final entry in store.logs.entries) {
        if (identical(entry.value, widget.log)) {
          key = entry.key;
          break;
        }
      }
    }
    _key = key;
    // Seul le programme embarqué est immuable : une séance archivée garde
    // ses propres noms d'exercices.
    final match = RegExp(r'^S([1-9]\d*)-J([1-7])$').firstMatch(key ?? '');
    if (week == null && match != null) {
      final n = int.parse(match[1]!);
      for (final candidate in store.program.weeks) {
        if (candidate.n == n) {
          week = candidate;
          day = candidate.day(int.parse(match[2]!));
          break;
        }
      }
    }
    // L11 : exercices échangés ou adaptés de la séance, retrouvés aussi.
    // G9 : séance servie par kalis_adapt, exercices du moteur.
    final served = day != null && week != null
        ? store.sessionAdapt(week.n, day.j)
        : null;
    final adapted = day != null && week != null
        ? (served != null
                  ? store.adaptDay(week.n, day, served)
                  : store.sessionDay(week.n, day))
              .exercises
        : const <Exercise>[];
    final known = {
      for (final ex in day?.exercises ?? <Exercise>[]) ex.id: ex,
      for (final ex in adapted)
        if (ex.id.contains('~') || ex.engine) ex.id: ex,
    };
    final order = <String>{
      ...known.keys.where(_snapshot.ex.containsKey),
      ..._snapshot.ex.keys,
    };
    final exercises = <Exercise>[];
    for (final id in order) {
      final source = known[id];
      final savedName = _snapshot.exerciseNames[id];
      if (source != null && (savedName == null || savedName == source.name)) {
        exercises.add(source);
      } else {
        _unresolved.add(id);
        exercises.add(
          Exercise.manual(
            id: id,
            name: savedName ?? source?.name ?? id,
            setsText: '',
            forcedSets: _snapshot.ex[id]!.sets.length,
          ),
        );
      }
    }
    _day = DayPlan.manual(
      j: day?.j ?? 1,
      title: day?.title ?? _snapshot.title ?? 'Historique',
      exercises: exercises,
    );
    _week =
        week ??
        WeekPlan.manual(
          n: 0,
          block: 'Historique',
          color: SL.accent,
          days: [_day],
        );
    _groups = store.groups(_day);
  }

  @override
  void dispose() {
    unregisterDayRoute(_route);
    _pages.dispose();
    _unusedTimer.dispose();
    super.dispose();
  }

  Route<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route ??= ModalRoute.of(context);
    // Historique d'une journée : une notification ou un second appui y
    // ramène au lieu d'empiler un autre écran (KT-018).
    if (_key != null) registerDayRoute(_key!, _route);
  }

  void _go(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _chooseExercise() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .65,
        builder: (context, controller) => ListView(
          controller: controller,
          children: [
            for (var i = 0; i < _groups.length; i++)
              ListTile(
                leading: Text('${i + 1}'),
                title: Text(
                  _groups[i]
                      .map((ex) => store.splitName(ex.name).$1)
                      .join(' + '),
                ),
                selected: i == _page,
                onTap: () => Navigator.pop(context, i),
              ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Bilan de séance'),
              selected: _page == _groups.length,
              onTap: () => Navigator.pop(context, _groups.length),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) _go(selected);
  }

  void _onMenu(String value) {
    if (value == 'correct') _correct();
    if (value == 'delete') _delete();
  }

  /// Rouvre la séance, saisies et date conservées, dans l'écran d'exécution.
  Future<void> _correct() async {
    final key = _key;
    final plan = key == null ? null : store.correctionPlan(key);
    if (key == null || plan == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Corriger cette séance ?'),
        content: Text(
          '$_head repasse en cours avec toutes ses saisies. Son XP de séance est retiré le temps de la correction et revient quand tu la termines de nouveau. Sa date reste celle d’origine.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Corriger'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (!store.reopenSession(key)) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            SessionScreen(week: plan.week, day: plan.day, resume: false),
      ),
    );
  }

  /// Supprime l'entrée du journal ; le message permet de l'annuler.
  Future<void> _delete() async {
    final key = _key;
    if (key == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer de l’historique ?'),
        content: Text(
          '$_head — séries, notes et statut « fait » seront effacés. L’XP et les bonus de cette séance sont retirés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SL.alert,
              foregroundColor: KPalette.light,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final removed = store.deleteLog(key);
    Navigator.of(context).maybePop();
    if (removed == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Séance supprimée de l’historique.'),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () => store.restoreLog(key, removed),
        ),
      ),
    );
  }

  Widget _summary() {
    final sets = _snapshot.ex.values.expand((ex) => ex.sets).toList();
    final date = DateTime.tryParse(_snapshot.finishedAt ?? '')?.toLocal();
    return KList(
      children: [
        KCard(
          accent: SL.success,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _snapshot.done ? 'SÉANCE EFFECTUÉE' : 'SÉANCE ENREGISTRÉE',
                style: TextStyle(
                  color: SL.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${sets.where((s) => s.done).length} / ${sets.length}',
                style: TextStyle(
                  fontSize: 32,
                  color: SL.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text('séries validées'),
              const SizedBox(height: 12),
              Text('${_snapshot.ex.length} exercices enregistrés'),
              if (date != null) ...[
                const SizedBox(height: 6),
                Text(
                  MaterialLocalizations.of(context).formatFullDate(date),
                  style: TextStyle(color: SL.dim),
                ),
              ],
            ],
          ),
        ),
        if (_correctable)
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Validée par erreur ?',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rouvre la séance avec toutes ses saisies pour corriger une valeur, puis termine-la de nouveau. Sa date est conservée.',
                  style: TextStyle(color: SL.dim),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _correct,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Corriger les saisies'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_day.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            '${_week.n > 0 ? 'S${_week.n} · J${_day.j} · ' : ''}Lecture seule',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: _editable ? 0 : 16),
          child: Icon(Icons.lock_outline, size: 18, color: SL.dim),
        ),
        if (_editable)
          PopupMenuButton<String>(
            tooltip: 'Options de l’historique',
            onSelected: _onMenu,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'correct',
                enabled: _correctable,
                child: const Text('Corriger les saisies'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Supprimer de l’historique'),
              ),
            ],
          ),
      ],
    ),
    body: _groups.isEmpty
        ? const Padding(
            padding: KSpace.content,
            child: KEmpty(
              icon: Icons.check_circle_outline,
              title: 'Séance effectuée',
              message: 'Aucune série enregistrée pour cette séance.',
            ),
          )
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  KSpace.page,
                  0,
                  KSpace.page,
                  4,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _page == _groups.length
                                ? 'Bilan de séance'
                                : '${_groups[_page].length > 1 ? 'Enchaînement' : 'Exercice'} ${_page + 1} / ${_groups.length}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _chooseExercise,
                          icon: const Icon(Icons.list_alt, size: 18),
                          label: const Text('Exercices'),
                        ),
                      ],
                    ),
                    SessionProgressDots(
                      count: _groups.length + 1,
                      index: _page,
                      color: SL.action,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _groups.length + 1,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, page) => page == _groups.length
                      ? _summary()
                      : SessionExercisePage(
                          key: ValueKey('history-page-$page'),
                          week: _week,
                          day: _day,
                          exs: _groups[page],
                          timer: _unusedTimer,
                          history: _snapshot,
                          unresolvedIds: _unresolved,
                        ),
                ),
              ),
            ],
          ),
    // 5.5.2 : plus de boutons Précédent / Suivant (glissement).
  );
}
