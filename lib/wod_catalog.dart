// Catalogue de WODs, façon boutique : vitrine en tête (crédits et prochain
// gain, prochain objectif de la liste d'envies, WOD à l'affiche en essai
// offert, vitrine de la semaine à −1 crédit, sélection « à ta mesure »,
// liste d'envies), puis tout le catalogue avec recherche tolérante (accents,
// synonymes FR / EN, plusieurs termes, préfixes) classée par pertinence,
// menu « Filtres » commun (M4c : accès, format, mouvements, difficulté,
// durée, matériel, source, à cocher par catégorie, filtres actifs en puces)
// et menu de tri. Dès qu'une recherche ou un filtre est actif, la vitrine
// s'efface devant les résultats.
import 'package:flutter/material.dart';

import 'arsenal_screen.dart' show WodTile;
import 'app_theme.dart';
import 'filter_menu.dart';
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
  final Set<String> statuses = {}; // unlocked | affordable | locked (union)
  final Set<String> types = {};
  final Set<int> bands = {}; // 1: 1-3 · 2: 4-6 · 3: 7-8 · 4: 9-10
  final Set<String> durs = {}; // short | mid | long
  final Set<String> equips = {}; // pdc | barre | lest | erg | kb | box | corde
  final Set<String> sources = {}; // curated | generated | mine
  final Set<String> moves = {}; // clés de movementFilters

  /// M4c : filtres du menu commun (clés préfixées par catégorie).
  _Filters.from(FilterSelection sel) {
    Set<String> strip(String category, String prefix) => {
      for (final k in sel.of(category))
        if (k.startsWith(prefix)) k.substring(prefix.length),
    };
    statuses.addAll(strip('acces', 'st:'));
    types.addAll(strip('format', 'ty:'));
    moves.addAll(strip('mouvements', 'mv:'));
    bands.addAll({
      for (final b in strip('niveau', 'lv:'))
        if (int.tryParse(b) != null) int.parse(b),
    });
    durs.addAll(strip('duree', 'du:'));
    equips.addAll(strip('materiel', 'eq:'));
    sources.addAll(strip('source', 'src:'));
  }

  static int band(int level) => level <= 3
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
    if (statuses.isNotEmpty) {
      final unlocked = store.unlocked(w);
      final ok = statuses.any(
        (st) => switch (st) {
          'unlocked' => unlocked,
          'locked' => !unlocked,
          'affordable' => !unlocked && store.wodCost(w) <= store.credits,
          _ => false,
        },
      );
      if (!ok) return false;
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
      final d = m < 15
          ? 'short'
          : m <= 30
          ? 'mid'
          : 'long';
      if (!durs.contains(d)) return false;
    }
    if (equips.isNotEmpty) {
      final eq = equipmentOf(w);
      final ok = equips.any(
        (e) => e == 'pdc'
            ? (eq.length == 1 && eq.contains('pdc'))
            : eq.contains(e),
      );
      if (!ok) return false;
    }
    if (sources.isNotEmpty) {
      final gen = store.isGenerated(w), cat = store.isCatalog(w);
      final s = gen
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

/// M4c : catégories du menu « Filtres » (clés uniques dans le menu).
final List<FilterCategory> wodFilterCategories = [
  FilterCategory(
    id: 'acces',
    label: 'Accès',
    options: [
      for (final e in _statusLabels.entries)
        FilterOption('st:${e.key}', e.value),
    ],
  ),
  FilterCategory(
    id: 'format',
    label: 'Format',
    options: [
      for (final e in wodTypes.entries) FilterOption('ty:${e.key}', e.value),
    ],
  ),
  FilterCategory(
    id: 'mouvements',
    label: 'Mouvements (au moins un)',
    options: [
      for (final e in movementFilters.entries)
        FilterOption('mv:${e.key}', e.value.$1),
    ],
  ),
  FilterCategory(
    id: 'niveau',
    label: 'Difficulté',
    options: [
      for (final e in _bandLabels.entries) FilterOption('lv:${e.key}', e.value),
    ],
  ),
  FilterCategory(
    id: 'duree',
    label: 'Durée estimée',
    options: [
      for (final e in _durLabels.entries) FilterOption('du:${e.key}', e.value),
    ],
  ),
  FilterCategory(
    id: 'materiel',
    label: 'Matériel',
    options: [
      for (final e in _equipLabels.entries)
        FilterOption('eq:${e.key}', e.value),
    ],
  ),
  FilterCategory(
    id: 'source',
    label: 'Source',
    options: [
      for (final e in _sourceLabels.entries)
        FilterOption('src:${e.key}', e.value),
    ],
  ),
];

class WodCatalogScreen extends StatefulWidget {
  const WodCatalogScreen({super.key});

  /// M4c : filtres gardés pendant la session (rien n'était mémorisé).
  static FilterSelection session = const FilterSelection();
  @override
  State<WodCatalogScreen> createState() => _WodCatalogScreenState();
}

class _WodCatalogScreenState extends State<WodCatalogScreen> {
  FilterSelection sel = WodCatalogScreen.session;
  _Filters f = _Filters.from(WodCatalogScreen.session);
  String q = '';

  void _setFilters(FilterSelection v) => setState(() {
    sel = v;
    f = _Filters.from(v);
    WodCatalogScreen.session = v;
  });
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
                store.credits >= 0
                    ? '${store.credits} crédit${store.credits > 1 ? 's' : ''} disponible${store.credits > 1 ? 's' : ''}'
                    : 'Solde : ${creditDeficitLabel(store.credits)}',
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
      if (trial == null)
        KCard(
          child: Text(
            'Pas d’essai du jour : aucun WOD jamais tenté ne reste à découvrir. Le prochain choix a lieu demain.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
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
        final showcase =
            q.trim().isEmpty && sel.count(wodFilterCategories) == 0;
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
                itemBuilder: (_) => [
                  for (final e in sortLabels.entries)
                    CheckedPopupMenuItem<String>(
                      value: e.key,
                      checked: _effectiveSort == e.key,
                      child: Text(e.value),
                    ),
                ],
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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  KSpace.page,
                  0,
                  KSpace.page,
                  8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilterMenu(
                    key: const ValueKey('wod-filter-menu'),
                    keyPrefix: 'wod',
                    categories: wodFilterCategories,
                    value: sel,
                    onChanged: _setFilters,
                  ),
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
                        onAction: () {
                          _setFilters(const FilterSelection());
                          setState(() {
                            searchCtl.clear();
                            q = '';
                          });
                        },
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
