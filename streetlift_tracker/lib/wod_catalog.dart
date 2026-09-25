// Catalogue de WODs, façon boutique : vitrine en tête (crédits et prochain
// gain, prochain objectif de la liste d'envies, WOD à l'affiche en essai
// offert, vitrine de la semaine à −1 crédit, sélection « à ta mesure »,
// liste d'envies), puis tout le catalogue avec recherche tolérante (accents,
// synonymes FR / EN, plusieurs termes, préfixes) classée par pertinence,
// puces rapides, panneau de filtres multi-sélection (accès, format,
// mouvements, difficulté, durée, matériel, source) et menu de tri. Dès qu'une
// recherche ou un filtre est actif, la vitrine s'efface devant les résultats.
import 'package:flutter/material.dart';

import 'arsenal_screen.dart' show WodTile;
import 'app_theme.dart';
import 'search.dart';
import 'ui.dart';
import 'store.dart';
import 'wod_generator.dart';
import 'wod_models.dart';
import 'wod_store.dart';

/// Mouvements filtrables : (libellé, motif) appliqué au texte normalisé des
/// lignes du WOD.
const movementFilters = <String, (String, String)>{
  'traction': (
    'Tractions',
    r'traction|pull-up|chin-up|chest-to-bar|rows barre|pull up',
  ),
  'dip': ('Dips', r'\bdips?\b'),
  'muscleup': ('Muscle-ups', r'muscle-up|muscle up|\bmu\b'),
  'pompe': ('Pompes', r'pompe|push-up|push up'),
  'squat': ('Squats / fentes', r'squat|lunge|fente|pistol|step-up'),
  'burpee': ('Burpees', r'burpee'),
  'core': (
    'Gainage / abdos',
    r'sit-up|v-up|hollow|toes-to-bar|leg raise|plank|dragon|crunch|abdo',
  ),
  'run': ('Course', r'\bm run\b|\bkm run\b|course|sprint|footing'),
  'erg': ('Rameur / erg', r'\brow\b|skierg|\bbike\b|\bcal\b|rameur'),
  'corde': ('Corde', r'double-under|corde'),
  'hspu': ('HSPU / ATR', r'hspu|handstand|wall walk|pike'),
  'kb': (
    'Kettlebell / wall ball',
    r'kettlebell|\bkb\b|wall ball|goblet|thruster|devil press|sandbag|farmer',
  ),
  'box': ('Box', r'\bbox\b'),
  'skill': ('Skills', r'front lever|back lever|planche|flag|l-sit'),
};

final Map<String, RegExp> _movementRes = {
  for (final e in movementFilters.entries) e.key: RegExp(e.value.$2),
};

const sortLabels = <String, String>{
  'default': 'Débloqués puis niveau',
  'relevance': 'Pertinence',
  'levelAsc': 'Niveau croissant',
  'levelDesc': 'Niveau décroissant',
  'durAsc': 'Durée croissante',
  'durDesc': 'Durée décroissante',
  'name': 'Nom A → Z',
  'newest': 'Nouveautés d\u2019abord',
};

class _Filters {
  String status = 'all'; // all | unlocked | affordable | locked
  final Set<String> types = {};
  final Set<int> bands = {}; // 1: 1-3 · 2: 4-6 · 3: 7-8 · 4: 9-10
  final Set<String> durs = {}; // short | mid | long
  final Set<String> equips = {}; // pdc | barre | lest | erg | kb | box | corde
  final Set<String> sources = {}; // curated | generated | mine
  final Set<String> moves = {}; // clés de movementFilters

  int get count =>
      (status == 'all' ? 0 : 1) +
      types.length +
      bands.length +
      durs.length +
      equips.length +
      sources.length +
      moves.length;

  void clear() {
    status = 'all';
    types.clear();
    bands.clear();
    durs.clear();
    equips.clear();
    sources.clear();
    moves.clear();
  }

  void copyFrom(_Filters o) {
    status = o.status;
    types
      ..clear()
      ..addAll(o.types);
    bands
      ..clear()
      ..addAll(o.bands);
    durs
      ..clear()
      ..addAll(o.durs);
    equips
      ..clear()
      ..addAll(o.equips);
    sources
      ..clear()
      ..addAll(o.sources);
    moves
      ..clear()
      ..addAll(o.moves);
  }

  _Filters copy() => _Filters()..copyFrom(this);

  static int band(int level) =>
      level <= 3
          ? 1
          : level <= 6
          ? 2
          : level <= 8
          ? 3
          : 4;

  /// Durée estimée en minutes (null si l'estimation est inexploitable).
  static double? minutesOf(Wod w) {
    final estimate = store.wodEstimate(w);
    if (estimate.elapsed.high <= 0 ||
        (estimate.partial &&
            estimate.clock == null &&
            estimate.observed == null)) {
      return null;
    }
    return estimate.elapsed.midpoint / 60;
  }

  bool match(Wod w, SearchQuery query, SearchDoc doc) {
    if (status == 'unlocked' && !store.unlocked(w)) return false;
    if (status == 'locked' && store.unlocked(w)) return false;
    if (status == 'affordable' &&
        (store.unlocked(w) || store.wodCost(w) > store.credits)) {
      return false;
    }
    if (types.isNotEmpty && !types.contains(w.type)) return false;
    if (bands.isNotEmpty && !bands.contains(band(w.level))) return false;
    if (moves.isNotEmpty) {
      final ok = moves.any((m) => _movementRes[m]!.hasMatch(doc.body));
      if (!ok) return false;
    }
    if (durs.isNotEmpty) {
      final m = minutesOf(w);
      if (m == null) return false;
      final d =
          m < 15
              ? 'short'
              : m <= 30
              ? 'mid'
              : 'long';
      if (!durs.contains(d)) return false;
    }
    if (equips.isNotEmpty) {
      final eq = equipmentOf(w);
      final ok = equips.any(
        (e) =>
            e == 'pdc'
                ? (eq.length == 1 && eq.contains('pdc'))
                : eq.contains(e),
      );
      if (!ok) return false;
    }
    if (sources.isNotEmpty) {
      final gen = store.isGenerated(w), cat = store.isCatalog(w);
      final s =
          gen
              ? 'generated'
              : cat
              ? 'curated'
              : 'mine';
      if (!sources.contains(s)) return false;
    }
    if (!query.isEmpty && !query.matches(doc.all)) return false;
    return true;
  }
}

const _statusLabels = {
  'all': 'Tous',
  'unlocked': 'Débloqués',
  'affordable': 'Abordables',
  'locked': 'Verrouillés',
};
const _bandLabels = {
  1: 'Niv. 1-3',
  2: 'Niv. 4-6',
  3: 'Niv. 7-8',
  4: 'Niv. 9-10',
};
const _durLabels = {
  'short': '< 15 min',
  'mid': '15-30 min',
  'long': '> 30 min',
};
const _equipLabels = {
  'pdc': 'Poids de corps seul',
  'barre': 'Barre',
  'lest': 'Lest',
  'erg': 'Erg',
  'kb': 'KB / wall ball',
  'box': 'Box',
  'corde': 'Corde',
};
const _sourceLabels = {'curated': 'Sélection', 'generated': 'Séries Kalis'};

/// Puce rapide visible sous la recherche : libellé, bascule et état.
class _Quick {
  final String label;
  final void Function(_Filters f) toggle;
  final bool Function(_Filters f) active;
  const _Quick(this.label, this.toggle, this.active);
}

void _toggleSet(Set<String> s, String v) {
  if (!s.remove(v)) s.add(v);
}

final List<_Quick> _quick = [
  _Quick(
    'Abordables',
    (f) => f.status = f.status == 'affordable' ? 'all' : 'affordable',
    (f) => f.status == 'affordable',
  ),
  _Quick(
    'Poids de corps',
    (f) => _toggleSet(f.equips, 'pdc'),
    (f) => f.equips.contains('pdc'),
  ),
  for (final t in ['fortime', 'amrap', 'emom', 'rounds', 'routine'])
    _Quick(
      wodTypes[t]!,
      (f) => _toggleSet(f.types, t),
      (f) => f.types.contains(t),
    ),
  _Quick(
    '< 15 min',
    (f) => _toggleSet(f.durs, 'short'),
    (f) => f.durs.contains('short'),
  ),
];

class WodCatalogScreen extends StatefulWidget {
  const WodCatalogScreen({super.key});
  @override
  State<WodCatalogScreen> createState() => _WodCatalogScreenState();
}

class _WodCatalogScreenState extends State<WodCatalogScreen> {
  final f = _Filters();
  String q = '';
  String sort = 'default';
  final searchCtl = TextEditingController();
  final _index = SearchIndex<String>();

  @override
  void dispose() {
    searchCtl.dispose();
    super.dispose();
  }

  SearchDoc _doc(Wod w) => _index.doc(
    w.id,
    '${w.name}\u0000${w.type}\u0000${w.scheme}\u0000${w.notes}\u0000${w.lines.join('\u0000')}',
    () => SearchDoc(
      name: w.name,
      meta: '${w.typeLabel} ${w.type} ${w.header()} ${w.scheme}',
      body: w.lines.join(' | '),
      notes: '${w.notes} ${w.source}',
    ),
  );

  /// Ordre d'arrivée dans le catalogue : WOD personnels, deuxième série,
  /// première série, puis sélection.
  int _newestKey(Wod w) {
    final m = RegExp(r'^(genx|gen|seed)(\d+)$').firstMatch(w.id);
    if (m == null) return 3000000;
    final n = int.parse(m.group(2)!);
    switch (m.group(1)) {
      case 'genx':
        return 2000000 + n;
      case 'gen':
        return 1000000 + n;
      default:
        return n;
    }
  }

  String get _effectiveSort =>
      sort == 'default' && q.trim().isNotEmpty ? 'relevance' : sort;

  List<Wod> _list() {
    final query = SearchQuery(q);
    final scored = <(Wod, double)>[];
    for (final w in store.wods) {
      if (!store.isCatalog(w)) continue;
      final d = _doc(w);
      if (!f.match(w, query, d)) continue;
      scored.add((w, query.isEmpty ? 0.0 : query.score(d)));
    }
    int byDefault(Wod a, Wod b) {
      final ua = store.unlocked(a) ? 0 : 1, ub = store.unlocked(b) ? 0 : 1;
      if (ua != ub) return ua.compareTo(ub);
      if (a.level != b.level) return a.level.compareTo(b.level);
      return a.name.compareTo(b.name);
    }

    final durations = <String, double>{};
    double dur(Wod w) =>
        durations.putIfAbsent(w.id, () => _Filters.minutesOf(w) ?? 1e9);
    final mode = _effectiveSort;
    scored.sort((a, b) {
      final wa = a.$1, wb = b.$1;
      int c;
      switch (mode) {
        case 'relevance':
          c = b.$2.compareTo(a.$2);
          return c != 0 ? c : byDefault(wa, wb);
        case 'levelAsc':
          c = wa.level.compareTo(wb.level);
          return c != 0 ? c : wa.name.compareTo(wb.name);
        case 'levelDesc':
          c = wb.level.compareTo(wa.level);
          return c != 0 ? c : wa.name.compareTo(wb.name);
        case 'durAsc':
          c = dur(wa).compareTo(dur(wb));
          return c != 0 ? c : byDefault(wa, wb);
        case 'durDesc':
          c = dur(wb).compareTo(dur(wa));
          return c != 0 ? c : byDefault(wa, wb);
        case 'name':
          return wa.name.toLowerCase().compareTo(wb.name.toLowerCase());
        case 'newest':
          c = _newestKey(wb).compareTo(_newestKey(wa));
          return c != 0 ? c : byDefault(wa, wb);
        default:
          return byDefault(wa, wb);
      }
    });
    return [for (final s in scored) s.$1];
  }

  int _countWith(_Filters draft) {
    final query = SearchQuery(q);
    var n = 0;
    for (final w in store.wods) {
      if (store.isCatalog(w) && draft.match(w, query, _doc(w))) n++;
    }
    return n;
  }

  Future<void> _openFilters() async {
    final draft = f.copy();
    final applied = await showModalBottomSheet<_Filters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setSheet) {
              final n = _countWith(draft);
              Widget chips<T>(Map<T, String> labels, Set<T> sel) => Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in labels.entries)
                    FilterChip(
                      label: Text(e.value),
                      selected: sel.contains(e.key),
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: sel.contains(e.key) ? SL.accent : SL.dim,
                      ),
                      selectedColor: SL.accent.withValues(alpha: 0.18),
                      backgroundColor: SL.card,
                      side: BorderSide(
                        color: sel.contains(e.key) ? SL.accent : SL.formBorder,
                      ),
                      onSelected:
                          (v) => setSheet(
                            () => v ? sel.add(e.key) : sel.remove(e.key),
                          ),
                    ),
                ],
              );
              Widget section(String t, Widget child) => Padding(
                padding: const EdgeInsets.fromLTRB(
                  KSpace.page,
                  KControl.formGap,
                  KSpace.page,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t,
                      style: TextStyle(
                        color: SL.dim,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    child,
                  ],
                ),
              );
              final moveLabels = <String, String>{
                for (final e in movementFilters.entries) e.key: e.value.$1,
              };
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.85,
                maxChildSize: 0.95,
                builder:
                    (ctx, ctl) => Column(
                      children: [
                        Expanded(
                          child: ListView(
                            controller: ctl,
                            padding: const EdgeInsets.only(bottom: 12),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  KSpace.page,
                                  0,
                                  KSpace.page,
                                  0,
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Filtres',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () => setSheet(draft.clear),
                                      child: const Text('Réinitialiser'),
                                    ),
                                  ],
                                ),
                              ),
                              section(
                                'Accès',
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final e in _statusLabels.entries)
                                      ChoiceChip(
                                        label: Text(e.value),
                                        selected: draft.status == e.key,
                                        showCheckmark: false,
                                        labelStyle: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              draft.status == e.key
                                                  ? SL.accent
                                                  : SL.dim,
                                        ),
                                        selectedColor: SL.accent.withValues(
                                          alpha: 0.18,
                                        ),
                                        backgroundColor: SL.card,
                                        side: BorderSide(
                                          color:
                                              draft.status == e.key
                                                  ? SL.accent
                                                  : SL.formBorder,
                                        ),
                                        onSelected:
                                            (_) => setSheet(
                                              () => draft.status = e.key,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              section('Format', chips(wodTypes, draft.types)),
                              section(
                                'Mouvements (au moins un)',
                                chips(moveLabels, draft.moves),
                              ),
                              section(
                                'Difficulté',
                                chips(_bandLabels, draft.bands),
                              ),
                              section(
                                'Durée estimée',
                                chips(_durLabels, draft.durs),
                              ),
                              section(
                                'Matériel',
                                chips(_equipLabels, draft.equips),
                              ),
                              section(
                                'Source',
                                chips(_sourceLabels, draft.sources),
                              ),
                            ],
                          ),
                        ),
                        KBottomActions(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(ctx, draft),
                            child: Text('Voir $n WOD${n > 1 ? 's' : ''}'),
                          ),
                        ),
                      ],
                    ),
              );
            },
          ),
    );
    if (applied != null && mounted) {
      setState(() => f.copyFrom(applied));
    }
  }

  /// Filtres actifs qui ne sont pas déjà représentés par une puce rapide.
  List<(String, VoidCallback)> _active() {
    const quickTypes = {'fortime', 'amrap', 'emom', 'rounds', 'routine'};
    return [
      if (f.status != 'all' && f.status != 'affordable')
        (_statusLabels[f.status]!, () => f.status = 'all'),
      for (final t in f.types)
        if (!quickTypes.contains(t))
          (wodTypes[t] ?? t, () => f.types.remove(t)),
      for (final m in f.moves)
        (movementFilters[m]!.$1, () => f.moves.remove(m)),
      for (final b in f.bands) (_bandLabels[b]!, () => f.bands.remove(b)),
      for (final d in f.durs)
        if (d != 'short') (_durLabels[d]!, () => f.durs.remove(d)),
      for (final e in f.equips)
        if (e != 'pdc') (_equipLabels[e]!, () => f.equips.remove(e)),
      for (final s in f.sources) (_sourceLabels[s]!, () => f.sources.remove(s)),
    ];
  }

  Widget _quickChip(_Quick k) {
    final on = k.active(f);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(k.label),
        selected: on,
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: on ? SL.accent : SL.dim,
        ),
        selectedColor: SL.accent.withValues(alpha: 0.18),
        backgroundColor: SL.card,
        side: BorderSide(color: on ? SL.accent : SL.formBorder),
        onSelected: (_) => setState(() => k.toggle(f)),
      ),
    );
  }

  /// En-tête de la liste : la vitrine complète sans recherche ni filtre,
  /// sinon un simple rappel du solde au-dessus des résultats.
  List<Widget> _leading(BuildContext context, bool showcase) {
    if (!showcase) {
      return [
        Row(
          children: [
            Icon(Icons.toll_rounded, color: SL.accent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${store.credits} crédit${store.credits > 1 ? 's' : ''} disponible${store.credits > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ];
    }
    final target = store.wishTarget;
    final trial = store.trialWod;
    final weekly = store.weeklyPicks;
    final reco = store.recommended();
    final wished = store.wishedWods;
    return [
      const CreditsCard(),
      if (target != null) WishGoalCard(wod: target),
      if (trial != null) WodHero(wod: trial),
      if (weekly.isNotEmpty)
        StoreRail(
          title: 'Vitrine de la semaine · −1 crédit',
          subtitle: weeklyCountdown(),
          cards: [
            for (final w in weekly) WodStoreCard(wod: w, ribbon: '−1 CRÉDIT'),
          ],
        ),
      if (reco.isNotEmpty)
        StoreRail(
          title: 'À ta mesure',
          subtitle:
              'Autour du niveau ${store.targetWodLevel} · sélection renouvelée chaque jour',
          cards: [for (final w in reco) WodStoreCard(wod: w)],
        ),
      if (wished.isNotEmpty)
        StoreRail(
          title: 'Ma liste d\u2019envies',
          subtitle:
              '${wished.length} WOD${wished.length > 1 ? 's' : ''} mis de côté · le moins cher en tête',
          cards: [for (final w in wished) WodStoreCard(wod: w)],
        ),
      const KSection(
        'Tout le catalogue',
        subtitle:
            'Débloqués d\u2019abord, puis par niveau. Cherche, filtre, trie.',
        topPadding: 4,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = _list();
        final active = _active();
        final showcase = q.trim().isEmpty && f.count == 0;
        final leading = _leading(context, showcase);
        return KScreen(
          appBar: AppBar(
            title: Text('WODs · ${list.length}'),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Trier',
                icon: Icon(
                  Icons.swap_vert_rounded,
                  color: sort == 'default' ? SL.text : SL.accent,
                ),
                onSelected: (v) => setState(() => sort = v),
                itemBuilder:
                    (_) => [
                      for (final e in sortLabels.entries)
                        CheckedPopupMenuItem<String>(
                          value: e.key,
                          checked: _effectiveSort == e.key,
                          child: Text(e.value),
                        ),
                    ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: f.count > 0 ? SL.accent : SL.text,
                  ),
                  onPressed: _openFilters,
                  icon: Icon(
                    f.count > 0 ? Icons.filter_alt : Icons.filter_alt_outlined,
                    size: 20,
                  ),
                  label: Text(f.count > 0 ? 'Filtres · ${f.count}' : 'Filtres'),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  KSpace.page,
                  8,
                  KSpace.page,
                  8,
                ),
                child: KSearch(
                  controller: searchCtl,
                  hint: 'Nom, mouvement, format (ex. tractions emom)',
                  onChanged: (v) => setState(() => q = v),
                ),
              ),
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: KSpace.page),
                  children: [for (final k in _quick) _quickChip(k)],
                ),
              ),
              if (active.isNotEmpty)
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: KSpace.page,
                    ),
                    children: [
                      for (final (label, remove) in active)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InputChip(
                            label: Text(label),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: SL.accent,
                            ),
                            backgroundColor: SL.accent.withValues(alpha: 0.14),
                            side: BorderSide(
                              color: SL.accent.withValues(alpha: 0.5),
                            ),
                            deleteIcon: const Icon(Icons.cancel, size: 18),
                            deleteIconColor: SL.accent,
                            onDeleted: () => setState(remove),
                          ),
                        ),
                      TextButton(
                        onPressed: () => setState(f.clear),
                        child: const Text(
                          'Tout effacer',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: KSpace.content,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: leading.length + (list.isEmpty ? 1 : list.length),
                  itemBuilder: (_, i) {
                    if (i < leading.length) return leading[i];
                    if (list.isEmpty) {
                      return KEmpty(
                        icon: Icons.search_off,
                        title: 'Aucun WOD trouvé',
                        message:
                            'Essaie un synonyme (pull-ups, tractions), un format (amrap) ou élargis les filtres.',
                        action: 'Réinitialiser',
                        onAction:
                            () => setState(() {
                              f.clear();
                              searchCtl.clear();
                              q = '';
                            }),
                      );
                    }
                    final w = list[i - leading.length];
                    return WodTile(key: ValueKey(w.id), wod: w);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
