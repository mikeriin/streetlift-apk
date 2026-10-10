import 'package:flutter/material.dart';
import 'adapt/widgets/session_kit.dart' show showKChoice;
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
    // G9 : séance servie par kalis_adapt, exercices du moteur. (Les
    // exercices échangés par L11, retiré en G10, gardent leur nom
    // enregistré.)
    final served = day != null && week != null
        ? store.sessionAdapt(week.n, day.j)
        : null;
    final adapted = day != null && week != null && served != null
        ? store.adaptDay(week.n, day, served).exercises
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
    // CI1f : mêmes pages que la séance (groupes d'exercices enchaînés).
    _groups = store.groups(_day, week: _week.n > 0 ? _week.n : null);
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

  /// Contexte des feuilles : « Corps entier, S1, J2 » (maquette du menu).
  String get _sheetContext =>
      _week.n > 0 ? '${_day.title}, S${_week.n}, J${_day.j}' : _day.title;

  /// Feuille de liste (cahier §4.5) : groupes d'exercices numérotés, page
  /// courante en contour, « Bilan de séance » avec son icône.
  Future<void> _chooseExercise() async {
    final count = _groups.fold<int>(0, (n, g) => n + g.length);
    final selected = await showKListSheet(
      context,
      title: 'Dans cette séance',
      summary: count > 1 ? '$count exercices' : '$count exercice',
      items: [
        for (var i = 0; i < _groups.length; i++)
          KListItem(
            _groups[i].map((ex) => store.splitName(ex.name).$1).join(' + '),
            detail: _groups[i].length > 1 ? 'Exercices enchaînés' : null,
            state: i == _page ? KListState.current : KListState.todo,
          ),
        KListItem(
          'Bilan de séance',
          icon: Icons.flag_outlined,
          state: _page == _groups.length ? KListState.current : KListState.todo,
        ),
      ],
    );
    if (selected != null && mounted) _go(selected);
  }

  /// Menu ⋮ (feuille d'actions, C10) : la suppression, destructrice, dans
  /// le dernier groupe.
  Future<void> _openMenu() async {
    final value = await showKActionSheet<String>(
      context,
      title: 'Séance',
      subtitle: _sheetContext,
      groups: [
        [
          KAction(
            icon: Icons.edit_outlined,
            label: 'Corriger les saisies',
            value: 'correct',
            enabled: _correctable,
          ),
        ],
        const [
          KAction(
            icon: Icons.delete_outline_rounded,
            label: 'Supprimer de l’historique',
            value: 'delete',
            danger: true,
          ),
        ],
      ],
    );
    if (value != null && mounted) _onMenu(value);
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
    final confirmed = await showKChoice(
      context,
      title: 'Corriger cette séance ?',
      message:
          '$_head repasse en cours avec toutes ses saisies. Son XP de séance est retiré le temps de la correction et revient quand tu la termines de nouveau. Sa date reste celle d’origine.',
      confirmLabel: 'Corriger',
      confirmKey: const ValueKey('confirm-ok'),
      cancelKey: const ValueKey('confirm-cancel'),
    );
    if (!confirmed || !mounted) return;
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
    final confirmed = await showKChoice(
      context,
      title: 'Supprimer de l’historique ?',
      message:
          '$_head — séries, notes et statut « fait » seront effacés. L’XP et les bonus de cette séance sont retirés.',
      confirmLabel: 'Supprimer',
      confirmKey: const ValueKey('confirm-ok'),
      cancelKey: const ValueKey('confirm-cancel'),
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final removed = store.deleteLog(key);
    if (removed == null) {
      Navigator.of(context).maybePop();
      return;
    }
    // Message court du kit, montré sur l'écran d'où l'on venait (messager
    // de l'application, lu avant le retour).
    final nav = Navigator.of(context);
    showKSnack(
      context,
      message: 'Séance supprimée de l’historique.',
      actionLabel: 'Annuler',
      onAction: () => store.restoreLog(key, removed),
    );
    nav.maybePop();
  }

  Widget _summary() {
    final k = KTokens.of(context);
    final sets = _snapshot.ex.values.expand((ex) => ex.sets).toList();
    final date = DateTime.tryParse(_snapshot.finishedAt ?? '')?.toLocal();
    return KList(
      children: [
        KCard(
          accent: k.validation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _snapshot.done ? 'Séance effectuée' : 'Séance enregistrée',
                style: KType.titreCarte.copyWith(color: k.validation),
              ),
              const SizedBox(height: KSpacing.s12),
              Text(
                '${sets.where((s) => s.done).length} / ${sets.length}',
                style: KType.chiffre.copyWith(color: k.validation),
              ),
              Text(
                'séries validées',
                style: KType.corps.copyWith(color: k.texte2),
              ),
              const SizedBox(height: KSpacing.s12),
              Text(
                '${_snapshot.ex.length} exercices enregistrés',
                style: KType.corps.copyWith(color: k.texte),
              ),
              if (date != null) ...[
                const SizedBox(height: KSpacing.s4),
                Text(
                  MaterialLocalizations.of(context).formatFullDate(date),
                  style: KType.detail.copyWith(color: k.texte2),
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
                Text(
                  'Validée par erreur ?',
                  style: KType.titreCarte.copyWith(color: k.texte),
                ),
                const SizedBox(height: KSpacing.s4),
                Text(
                  'Rouvre la séance avec toutes ses saisies pour corriger une valeur, puis termine-la de nouveau. Sa date est conservée.',
                  style: KType.corps.copyWith(color: k.texte2),
                ),
                const SizedBox(height: KSpacing.s12),
                KTonalButton(
                  icon: Icons.edit_outlined,
                  label: 'Corriger les saisies',
                  onPressed: _correct,
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    // En-tête de sous-page (C1). « Lecture seule » seulement quand aucune
    // action n'écrit (archive hors du journal) ; sinon la séance est dite
    // enregistrée et son menu ⋮ propose la correction et la suppression.
    final where = _week.n > 0 ? '${sessionPlace(_week, _day)}, ' : '';
    // Même en-tête que la séance (C1) : retour, titre jamais coupé,
    // repère et état, une seule action.
    final header = SessionHeader(
      title: _day.title,
      subtitle: where.isEmpty
          ? (_editable ? 'Séance enregistrée' : 'Lecture seule')
          : '$where${_editable ? 'séance enregistrée' : 'lecture seule'}',
      action: _editable
          ? KIconButton(
              icon: Icons.more_vert_rounded,
              tooltip: 'Options de l’historique',
              onPressed: _openMenu,
            )
          : null,
    );
    return KScreen(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            header,
            Expanded(
              child: _groups.isEmpty
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
                          padding: const EdgeInsetsDirectional.only(
                            start: KSpacing.page,
                            end: KSpacing.s12,
                            bottom: KSpacing.s4,
                          ),
                          child: Column(
                            children: [
                              // Même repère que la séance : « Exercice 3 sur 7 »
                              // et le lien « Exercices » (passe à la ligne en
                              // grand texte).
                              SizedBox(
                                width: double.infinity,
                                child: Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: KSpacing.s8,
                                  children: [
                                    Text(
                                      _page == _groups.length
                                          ? 'Bilan de séance'
                                          : '${_groups[_page].length > 1 ? 'Enchaînement' : 'Exercice'} ${_page + 1} sur ${_groups.length}',
                                      style: KType.section.copyWith(
                                        color: k.texte2,
                                      ),
                                    ),
                                    KTextButton(
                                      icon: Icons.format_list_numbered_rounded,
                                      label: 'Exercices',
                                      onPressed: _chooseExercise,
                                    ),
                                  ],
                                ),
                              ),
                              SessionProgressDots(
                                count: _groups.length + 1,
                                index: _page,
                                color: k.encre,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pages,
                            itemCount: _groups.length + 1,
                            onPageChanged: (page) =>
                                setState(() => _page = page),
                            itemBuilder: (context, page) =>
                                page == _groups.length
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
            ),
          ],
        ),
      ),
      // 5.5.2 : plus de boutons Précédent / Suivant (glissement).
    );
  }
}
