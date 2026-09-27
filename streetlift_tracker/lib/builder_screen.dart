import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'content_pack.dart';
import 'exercise_screens.dart';
import 'ui.dart';
import 'search.dart';
import 'store.dart';

// ===================== LISTE DES SÉANCES PERSO =====================
// Corps seul (le Scaffold et le FAB appartiennent à l'onglet Perso).

void newCustomSession(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute(
    builder:
        (_) => SessionEditor(
          session: CustomSession(id: store.newSessionId(), name: ''),
        ),
  ),
);

// ===================== ÉDITEUR DE SÉANCE =====================

class SessionEditor extends StatefulWidget {
  final CustomSession session;
  const SessionEditor({super.key, required this.session});
  @override
  State<SessionEditor> createState() => _SessionEditorState();
}

class _SessionEditorState extends State<SessionEditor> {
  late CustomSession s;
  late TextEditingController nameCtl;

  @override
  void initState() {
    super.initState();
    s = CustomSession.fromJson(widget.session.toJson());
    nameCtl = TextEditingController(text: s.name);
  }

  @override
  void dispose() {
    nameCtl.dispose();
    super.dispose();
  }

  void _save() {
    s.name = nameCtl.text.trim();
    if (s.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donne un nom à la séance.')),
      );
      return;
    }
    if (s.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute au moins un exercice.')),
      );
      return;
    }
    store.upsertSession(s);
    Navigator.pop(context);
  }

  Future<void> _addExercise() async {
    final name = await pickExercise(context);
    if (name == null || !mounted) return;
    final ex = CustomExercise(name: name);
    final ok = await editParams(context, ex);
    if (ok == true && mounted) setState(() => s.items.add(ex));
  }

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(
      title: Text(
        widget.session.name.isEmpty ? 'Nouvelle séance' : 'Modifier la séance',
      ),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpace.page,
            8,
            KSpace.page,
            KControl.formGap,
          ),
          child: TextField(
            controller: nameCtl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.edit_outlined),
              labelText: 'Nom de la séance',
              hintText: 'Ex. Force du haut du corps',
            ),
          ),
        ),
        if (s.items.isEmpty)
          const Expanded(
            child: KList(
              children: [
                KEmpty(
                  icon: Icons.fitness_center,
                  title: 'Compose ta séance',
                  message:
                      'Ajoute des exercices puis ajuste les séries, les charges et les temps de repos.',
                ),
              ],
            ),
          )
        else
          Expanded(
            child: ReorderableListView(
              padding: KSpace.content,
              buildDefaultDragHandles: false,
              onReorder:
                  (a, b) => setState(() {
                    if (b > a) b--;
                    s.items.insert(b, s.items.removeAt(a));
                  }),
              children: [
                for (var i = 0; i < s.items.length; i++)
                  Padding(
                    key: ValueKey(s.items[i].uid),
                    padding: const EdgeInsets.only(bottom: KSpace.gap),
                    child: KCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(s.items[i].name),
                            subtitle: Text(
                              '${modeById(s.items[i].mode).label} · ${s.items[i].setsText()}'
                              '${s.items[i].kg != null ? ' · ${s.items[i].kg} kg' : ''}'
                              '${s.items[i].rest != null ? ' · repos ${s.items[i].rest} s' : ''}',
                            ),
                            trailing: const Icon(Icons.edit_outlined),
                            onTap: () async {
                              final ok = await editParams(context, s.items[i]);
                              if (ok == true && mounted) setState(() {});
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                            child: Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: i,
                                  child: const Tooltip(
                                    message: 'Maintenir et déplacer',
                                    child: SizedBox(
                                      width: KControl.height,
                                      height: KControl.height,
                                      child: Icon(Icons.drag_handle),
                                    ),
                                  ),
                                ),
                                Text(
                                  'Exercice ${i + 1}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Retirer ${s.items[i].name}',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed:
                                      () => setState(() => s.items.removeAt(i)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
    bottomNavigationBar: KBottomActions(
      child: KActionRow(
        children: [
          OutlinedButton.icon(
            onPressed: _addExercise,
            icon: const Icon(Icons.add),
            label: const Text('Exercice'),
          ),
          FilledButton(onPressed: _save, child: const Text('Enregistrer')),
        ],
      ),
    ),
  );
}

// ===================== SÉLECTEUR D'EXERCICES =====================

Future<String?> pickExercise(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: SL.surface,
    useSafeArea: true,
    builder: (ctx) => const _ExercisePicker(),
  );
}

class _ExercisePicker extends StatefulWidget {
  const _ExercisePicker();
  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

/// Derniers exercices choisis pendant la session (huit au plus).
final List<String> _recentExercises = [];

void _rememberExercise(String name) {
  _recentExercises.remove(name);
  _recentExercises.insert(0, name);
  if (_recentExercises.length > 8) _recentExercises.removeLast();
}

const _equipShort = <String, String>{
  'poids de corps': 'Poids de corps',
  'barre fixe': 'Barre fixe',
  'barres parallèles': 'Parallèles',
  'anneaux': 'Anneaux',
  'barre': 'Barre',
  'haltères': 'Haltères',
  'kettlebell': 'Kettlebell',
  'machine': 'Machine',
  'machine, poulie': 'Poulie',
  'élastique': 'Élastique',
  'lest': 'Lest',
  'box': 'Box',
  'corde à sauter': 'Corde',
  'ergomètre': 'Erg',
  'sac lesté': 'Sac lesté',
  'médecine-ball': 'Médecine-ball',
  'sangles': 'Sangles',
  'battle rope': 'Battle rope',
};

class _ExercisePickerState extends State<_ExercisePicker> {
  String q = '';
  String group = '';
  String equip = '';
  final searchCtl = TextEditingController();
  final _index = SearchIndex<String>();

  @override
  void dispose() {
    searchCtl.dispose();
    super.dispose();
  }

  SearchDoc _doc(Map<String, dynamic> e) {
    final n = e['n'] as String, g = e['g'] as String, eq = e['eq'] as String;
    return _index.doc(
      n,
      '$g|$eq|${e['id']}',
      () => exerciseSearchDoc(store.content, e),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final all = store.allExercises;
    final groups = <String>{};
    final equips = <String>{};
    for (final e in all) {
      for (final g in (e['g'] as String).split(',')) {
        final t = g.trim();
        if (t.isNotEmpty) groups.add(t);
      }
      final eq = (e['eq'] as String).trim();
      if (eq.isNotEmpty && eq != '—') equips.add(eq);
    }
    final gl = groups.toList()..sort();
    final el = equips.toList()..sort();
    final query = SearchQuery(q);
    final ql = query.raw;

    final scored = <(Map<String, dynamic>, double)>[];
    for (final e in all) {
      final okG = group.isEmpty || (e['g'] as String).contains(group);
      final okE = equip.isEmpty || (e['eq'] as String) == equip;
      if (!okG || !okE) continue;
      final d = _doc(e);
      if (query.isEmpty) {
        scored.add((e, 0.0));
        continue;
      }
      if (!query.matches(d.all)) continue;
      var sc = query.score(d);
      if (d.name == ql) sc += 10;
      scored.add((e, sc));
    }
    scored.sort((a, b) {
      final c = b.$2.compareTo(a.$2);
      if (c != 0) return c;
      return (a.$1['n'] as String).toLowerCase().compareTo(
        (b.$1['n'] as String).toLowerCase(),
      );
    });
    final list = [for (final s in scored) s.$1];
    final exact = list.any((e) => normalizeText(e['n'] as String) == ql);
    final recents = [
      if (query.isEmpty && group.isEmpty && equip.isEmpty)
        for (final n in _recentExercises)
          for (final e in all)
            if (e['n'] == n) e,
    ];

    Widget tile(Map<String, dynamic> e, {IconData? icon}) => ListTile(
      leading: icon == null ? null : Icon(icon, color: SL.dim, size: 20),
      title: Text(
        e['n'] as String,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        '${e['g']} · ${e['eq']}',
        style: TextStyle(fontSize: 11.5, color: SL.dim),
      ),
      trailing:
          e['id'] == null
              ? null
              : IconButton(
                tooltip: 'Fiche de l’exercice',
                icon: Icon(Icons.info_outline, color: SL.dim),
                onPressed: () => openExerciseSheet(context, e['id'] as String),
              ),
      onTap: () {
        _rememberExercise(e['n'] as String);
        Navigator.pop(context, e['n'] as String);
      },
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height:
            (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom -
                MediaQuery.paddingOf(context).top) *
            .85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KSpace.page,
                KSpace.page,
                KSpace.page,
                KControl.gap,
              ),
              child: KSearch(
                controller: searchCtl,
                hint: 'Rechercher un exercice (nom, muscle, matériel)',
                onChanged: (v) => setState(() => q = v),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip(
                    'Tous',
                    group.isEmpty,
                    () => setState(() => group = ''),
                  ),
                  for (final g in gl)
                    _chip(
                      g,
                      group == g,
                      () => setState(() => group = group == g ? '' : g),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip(
                    'Tout matériel',
                    equip.isEmpty,
                    () => setState(() => equip = ''),
                  ),
                  for (final e in el)
                    _chip(
                      _equipShort[e] ?? e,
                      equip == e,
                      () => setState(() => equip = equip == e ? '' : e),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KSpace.page,
                6,
                KSpace.page,
                2,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${list.length} exercice${list.length > 1 ? 's' : ''}'
                  '${query.isEmpty ? '' : ' · classés par pertinence'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  if (ql.isNotEmpty && !exact)
                    ListTile(
                      leading: Icon(Icons.add_circle, color: SL.accent),
                      title: Text(
                        'Créer « ${q.trim()} »',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Ajouter à ta base d\u2019exercices',
                        style: TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        store.addUserExercise(q.trim(), 'divers', '—');
                        _rememberExercise(q.trim());
                        Navigator.pop(context, q.trim());
                      },
                    ),
                  if (recents.isNotEmpty) ...[
                    const KSection('Récents'),
                    for (final e in recents) tile(e, icon: Icons.history),
                    const KSection('Tous les exercices'),
                  ],
                  if (list.isEmpty && ql.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(KSpace.page),
                      child: Text(
                        'Aucun exercice ne correspond. Essaie un synonyme (pull-up, traction) ou un muscle.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  for (final e in list) tile(e),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== PARAMÈTRES DE MODE =====================

const _fieldLabels = {
  'series': 'Séries',
  'reps': 'Reps',
  'actReps': 'Reps activation',
  'miniReps': 'Reps / mini',
  'minis': 'Mini-séries',
  'intra': 'Repos intra (s)',
  'rounds': 'Rounds',
  'interval': 'Intervalle (s)',
  'duree': 'Durée (min)',
  'hold': 'Tenue (s)',
  'work': 'Effort (s)',
  'restI': 'Repos interv. (s)',
  'pyr': 'Schéma (12-10-8-6)',
  'startReps': 'Reps de départ',
  'step': 'Reps en plus / min',
  'tempo': 'Tempo (3-1-1-0)',
  'drops': 'Paliers',
};

/// Champs saisis en texte (schéma, tempo) ; les autres sont des entiers.
const _textFields = {'pyr', 'tempo'};
const _textDefaults = {'pyr': '12-10-8-6', 'tempo': '3-1-1-0'};

const _fieldDefaults = {
  'series': 4,
  'reps': 8,
  'actReps': 12,
  'miniReps': 4,
  'minis': 4,
  'intra': 20,
  'rounds': 8,
  'interval': 60,
  'duree': 8,
  'hold': 30,
  'work': 30,
  'restI': 30,
  'startReps': 1,
  'step': 1,
  'drops': 2,
};

Future<bool?> editParams(BuildContext context, CustomExercise ex) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: SL.surface,
    useSafeArea: true,
    builder: (ctx) => _ParamSheet(ex: ex),
  );
}

class _ParamSheet extends StatefulWidget {
  final CustomExercise ex;
  const _ParamSheet({required this.ex});
  @override
  State<_ParamSheet> createState() => _ParamSheetState();
}

class _ParamSheetState extends State<_ParamSheet> {
  late String mode;
  final ctls = <String, TextEditingController>{};
  late TextEditingController kgCtl, restCtl, noteCtl;

  @override
  void initState() {
    super.initState();
    mode = widget.ex.mode;
    kgCtl = TextEditingController(
      text: widget.ex.kg == null ? '' : '${widget.ex.kg}',
    );
    restCtl = TextEditingController(
      text: widget.ex.rest == null ? '' : '${widget.ex.rest}',
    );
    noteCtl = TextEditingController(text: widget.ex.note);
  }

  TextEditingController _ctl(String f) {
    return ctls.putIfAbsent(f, () {
      final v = widget.ex.p[f];
      final d =
          _textFields.contains(f)
              ? _textDefaults[f]!
              : '${modeDefaults[mode]?[f] ?? _fieldDefaults[f]}';
      return TextEditingController(text: v == null ? d : '$v');
    });
  }

  /// Au changement de mode, les champs non renseignés prennent les valeurs
  /// propres au mode (Tabata 8 × 20 / 10, Death by 20 × 60 s…).
  void _switchMode(String next) {
    setState(() {
      mode = next;
      final d = modeDefaults[next];
      if (d != null) {
        for (final e in d.entries) {
          if (widget.ex.p[e.key] == null) _ctl(e.key).text = '${e.value}';
        }
      }
    });
  }

  @override
  void dispose() {
    for (final c in [...ctls.values, kgCtl, restCtl, noteCtl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _apply() {
    final params = <String, dynamic>{};
    String? error;
    for (final f in modeById(mode).fields) {
      final text = _ctl(f).text.trim();
      if (f == 'pyr') {
        final parts = text.split(RegExp(r'[-/ ]+'));
        if (parts.isEmpty ||
            parts.length > 100 ||
            parts.any((p) => (int.tryParse(p) ?? 0) <= 0)) {
          error = 'Saisis une pyramide valide, par exemple 12-10-8-6.';
        }
        params[f] = parts.join('-');
      } else if (f == 'tempo') {
        if (text.isEmpty || text.length > 16) {
          error = 'Saisis un tempo court, par exemple 3-1-1-0.';
        }
        params[f] = text;
      } else {
        final n = int.tryParse(text);
        final min = f == 'restI' || f == 'intra' ? 0 : 1;
        final max = ['series', 'minis'].contains(f) ? 100 : 3600;
        if (n == null || n < min || n > max) {
          error = '${_fieldLabels[f]} : entre $min et $max.';
        }
        params[f] = n;
      }
    }
    final kg = double.tryParse(kgCtl.text.replaceAll(',', '.'));
    final rest = int.tryParse(restCtl.text);
    if (kgCtl.text.trim().isNotEmpty &&
        (kg == null || !kg.isFinite || kg.abs() > 10000)) {
      error = 'Charge invalide.';
    }
    if (restCtl.text.trim().isNotEmpty &&
        (rest == null || rest < 0 || rest > 86400)) {
      error = 'Repos invalide.';
    }
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    widget.ex.mode = mode;
    widget.ex.p = params;
    widget.ex.kg = kg;
    widget.ex.rest = rest;
    widget.ex.note = noteCtl.text.trim();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final m = modeById(mode);
    return Padding(
      padding: EdgeInsets.only(
        left: KSpace.page,
        right: KSpace.page,
        top: KSpace.page,
        bottom: MediaQuery.of(context).viewInsets.bottom + KSpace.page,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ex.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: mode,
              isExpanded: true,
              style: Theme.of(context).textTheme.bodyLarge,
              iconSize: KControl.iconSize,
              dropdownColor: SL.card,
              decoration: const InputDecoration(
                labelText: 'Mode d\u2019exécution',
                contentPadding: KControl.selectPadding,
              ),
              items: [
                for (final em in execModes)
                  DropdownMenuItem(value: em.id, child: Text(em.label)),
              ],
              onChanged: (v) => _switchMode(v ?? 'classic'),
            ),
            const SizedBox(height: 6),
            Text(
              m.desc,
              style: TextStyle(color: SL.dim, fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 10),
            for (final f in m.fields.where(_textFields.contains)) ...[
              TextField(
                controller: _ctl(f),
                decoration: InputDecoration(labelText: _fieldLabels[f]),
              ),
              const SizedBox(height: KControl.formGap),
            ],
            KFieldGrid(
              children: [
                for (final f in m.fields.where((f) => !_textFields.contains(f)))
                  TextField(
                    controller: _ctl(f),
                    keyboardType: TextInputType.number,
                    style: KControl.numberStyle,
                    decoration: InputDecoration(labelText: _fieldLabels[f]),
                  ),
                TextField(
                  controller: kgCtl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: KControl.numberStyle,
                  decoration: const InputDecoration(
                    labelText: 'Charge (kg, optionnel)',
                  ),
                ),
                TextField(
                  controller: restCtl,
                  keyboardType: TextInputType.number,
                  style: KControl.numberStyle,
                  decoration: const InputDecoration(
                    labelText: 'Repos entre séries (s)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: KControl.formGap),
            TextField(
              controller: noteCtl,
              textAlign: TextAlign.left,
              decoration: const InputDecoration(
                labelText: 'Consigne (optionnel)',
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _apply,
                child: const Text('Valider'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
