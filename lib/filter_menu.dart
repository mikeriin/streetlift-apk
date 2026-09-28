// M4c : filtres normalisés dans toute l'application (demande du propriétaire,
// 28/09/2026), sur le modèle du menu « Filtres » de l'écran Anatomie (M4b).
//
// Un bouton « Filtres · n » (n = filtres actifs) ouvre un menu déroulant
// organisé par catégorie ; chaque catégorie se replie et porte ses cases à
// cocher, « Tout cocher » et « Tout décocher ». Aucune catégorie n'est à
// choix unique : dans une catégorie, ne rien cocher revient à tout montrer. Cases cochées d'une même catégorie : union (OU) ;
// catégories entre elles : intersection (ET). « Réinitialiser » remet les
// filtres de départ de l'écran. Sous le bouton, les filtres actifs en puces
// supprimables. Toucher en dehors du menu : il se ferme sans rien toucher
// d'autre.
import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Option d'une catégorie (clé unique dans tout le menu).
@immutable
class FilterOption {
  final String key;
  final String label;
  const FilterOption(this.key, this.label);
}

/// Catégorie du menu (Groupe musculaire, Matériel, Lieu, Difficulté…).
@immutable
class FilterCategory {
  final String id;
  final String label;
  final List<FilterOption> options;

  const FilterCategory({
    required this.id,
    required this.label,
    required this.options,
  });
}

/// Filtres choisis : clés cochées par catégorie.
@immutable
class FilterSelection {
  final Map<String, Set<String>> _values;

  const FilterSelection([Map<String, Set<String>> values = const {}])
    : _values = values;

  /// Clés cochées d'une catégorie.
  Set<String> of(String category) => _values[category] ?? const <String>{};

  bool has(String category, String key) => of(category).contains(key);

  FilterSelection withKeys(String category, Set<String> keys) =>
      FilterSelection({..._values, category: Set.unmodifiable(keys)});

  FilterSelection toggle(String category, String key) {
    final s = {...of(category)};
    if (!s.remove(key)) s.add(key);
    return withKeys(category, s);
  }

  /// Union dans la catégorie : vrai si aucune case n'est cochée ou si
  /// [accepts] accepte une des clés cochées.
  bool matches(String category, bool Function(String key) accepts) {
    final s = of(category);
    return s.isEmpty || s.any(accepts);
  }

  /// Nombre de filtres actifs dans [categories].
  int count(List<FilterCategory> categories) {
    var n = 0;
    for (final c in categories) {
      n += of(c.id).where((k) => c.options.any((o) => o.key == k)).length;
    }
    return n;
  }

  /// Filtres actifs, dans l'ordre du menu : (catégorie, option).
  List<(FilterCategory, FilterOption)> active(
    List<FilterCategory> categories,
  ) => [
    for (final c in categories)
      for (final o in c.options)
        if (has(c.id, o.key)) (c, o),
  ];

  @override
  bool operator ==(Object other) {
    if (other is! FilterSelection) return false;
    final keys = {..._values.keys, ...other._values.keys};
    for (final k in keys) {
      final a = of(k), b = other.of(k);
      if (a.length != b.length || !a.containsAll(b)) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered([
    for (final e in _values.entries)
      if (e.value.isNotEmpty)
        Object.hash(e.key, Object.hashAllUnordered(e.value)),
  ]);

  @override
  String toString() => 'FilterSelection($_values)';
}

/// Bouton « Filtres », menu par catégorie et puces des filtres actifs.
class FilterMenu extends StatefulWidget {
  /// Préfixe des clés : `<préfixe>-filters` (bouton),
  /// `<préfixe>-filter-<option>` (cases), `<préfixe>-filter-cat-<catégorie>`
  /// (en-têtes), `<préfixe>-filter-all-<catégorie>` /
  /// `<préfixe>-filter-none-<catégorie>`, `<préfixe>-filter-reset`,
  /// `<préfixe>-chip-<option>` (puces).
  final String keyPrefix;
  final List<FilterCategory> categories;
  final FilterSelection value;

  /// Filtres de départ de l'écran (« Réinitialiser »).
  final FilterSelection initial;
  final ValueChanged<FilterSelection> onChanged;

  /// Puces des filtres actifs sous le bouton.
  final bool chips;

  /// À droite du bouton (texte court, tri…).
  final Widget? trailing;

  const FilterMenu({
    super.key,
    required this.keyPrefix,
    required this.categories,
    required this.value,
    required this.onChanged,
    this.initial = const FilterSelection(),
    this.chips = true,
    this.trailing,
  });

  /// Nombre de cases.
  static int totalOf(List<FilterCategory> categories) =>
      categories.fold(0, (n, c) => n + c.options.length);

  /// Puces affichées sous le bouton, au plus.
  static const maxChips = 6;

  /// Au-delà, seules les catégories actives sont dépliées à l'ouverture.
  static const expandAllUpTo = 16;

  @override
  State<FilterMenu> createState() => FilterMenuState();
}

class FilterMenuState extends State<FilterMenu> {
  final _menu = MenuController();
  late Set<String> _expanded = _initialExpanded();

  bool get isOpen => _menu.isOpen;

  /// Catégories dépliées (tests).
  Set<String> get expanded => _expanded;

  Set<String> _initialExpanded() {
    final cats = widget.categories;
    final options = cats.fold<int>(0, (n, c) => n + c.options.length);
    if (options <= FilterMenu.expandAllUpTo) {
      return {for (final c in cats) c.id};
    }
    final active = {
      for (final c in cats)
        if (widget.value.count([c]) > 0) c.id,
    };
    return active.isEmpty && cats.isNotEmpty ? {cats.first.id} : active;
  }

  void _toggleExpanded(String id) => setState(() {
    if (!_expanded.remove(id)) _expanded = {..._expanded, id};
  });

  String _k(String rest) => '${widget.keyPrefix}-$rest';

  @override
  Widget build(BuildContext context) {
    final cats = widget.categories;
    final value = widget.value;
    final count = value.count(cats);
    final total = FilterMenu.totalOf(cats);
    final active = value.active(cats);
    final button = MenuAnchor(
      controller: _menu,
      // Toucher en dehors : ferme le menu sans toucher ce qui est dessous.
      consumeOutsideTap: true,
      menuChildren: _menuChildren(context),
      builder: (context, controller, _) => OutlinedButton.icon(
        key: ValueKey(_k('filters')),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: count > 0 ? SL.accent : null,
          side: count > 0 ? BorderSide(color: SL.accent) : null,
        ),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: Icon(count > 0 ? Icons.filter_alt : Icons.filter_alt_outlined),
        label: Semantics(
          label: 'Filtres, $count actifs sur $total',
          excludeSemantics: true,
          child: Text('Filtres · $count'),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.trailing == null)
          button
        else
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [button, widget.trailing!],
          ),
        if (widget.chips && active.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              key: ValueKey(_k('chips')),
              spacing: 6,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (c, o) in active.take(FilterMenu.maxChips))
                  InputChip(
                    key: ValueKey(_k('chip-${o.key}')),
                    label: Text(o.label),
                    tooltip: c.label,
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: SL.accent,
                    ),
                    backgroundColor: SL.accent.withValues(alpha: 0.14),
                    side: BorderSide(color: SL.accent.withValues(alpha: 0.5)),
                    deleteIcon: const Icon(Icons.cancel, size: 18),
                    deleteIconColor: SL.accent,
                    deleteButtonTooltipMessage: 'Retirer le filtre ${o.label}',
                    onDeleted: () =>
                        widget.onChanged(value.toggle(c.id, o.key)),
                  ),
                // Au-delà de maxChips puces : un rappel qui ouvre le menu (la
                // page garde sa place, même à 200 % de texte).
                if (active.length > FilterMenu.maxChips)
                  ActionChip(
                    key: ValueKey(_k('chips-more')),
                    label: Text('+ ${active.length - FilterMenu.maxChips}'),
                    tooltip: 'Voir tous les filtres actifs',
                    onPressed: () => _menu.open(),
                  ),
                if (value != widget.initial)
                  TextButton(
                    key: ValueKey(_k('chips-reset')),
                    onPressed: () => widget.onChanged(widget.initial),
                    child: const Text('Réinitialiser'),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// Contenu du menu : une colonne de largeur bornée (le texte des cases
  /// passe à la ligne en grande taille de texte au lieu de déborder).
  List<Widget> _menuChildren(BuildContext context) {
    final value = widget.value;
    final tt = Theme.of(context).textTheme;
    final width = (MediaQuery.sizeOf(context).width - 32).clamp(200.0, 380.0);
    final rows = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text('Filtres', style: tt.titleSmall),
            TextButton(
              key: ValueKey(_k('filter-reset')),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: value == widget.initial
                  ? null
                  : () => widget.onChanged(widget.initial),
              child: const Text('Réinitialiser'),
            ),
          ],
        ),
      ),
    ];
    for (final c in widget.categories) {
      final open = _expanded.contains(c.id);
      final n = value.count([c]);
      final selected = value.of(c.id);
      rows.add(const Divider(height: 1));
      rows.add(
        Semantics(
          key: ValueKey(_k('filter-cat-${c.id}')),
          button: true,
          label:
              '${c.label}, $n sur ${c.options.length} cochés, '
              '${open ? 'déplié' : 'replié'}',
          onTap: () => _toggleExpanded(c.id),
          excludeSemantics: true,
          child: InkWell(
            onTap: () => _toggleExpanded(c.id),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        n == 0 ? c.label : '${c.label} · $n',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Icon(open ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      if (!open) continue;
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Wrap(
            children: [
              TextButton.icon(
                key: ValueKey(_k('filter-all-${c.id}')),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                icon: const Icon(Icons.done_all, size: 18),
                onPressed: selected.length == c.options.length
                    ? null
                    : () => widget.onChanged(
                        value.withKeys(c.id, {
                          for (final o in c.options) o.key,
                        }),
                      ),
                label: Semantics(
                  label: 'Tout cocher, ${c.label}',
                  excludeSemantics: true,
                  child: const Text('Tout cocher'),
                ),
              ),
              TextButton.icon(
                key: ValueKey(_k('filter-none-${c.id}')),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                icon: const Icon(Icons.remove_done, size: 18),
                onPressed: selected.isEmpty
                    ? null
                    : () => widget.onChanged(value.withKeys(c.id, const {})),
                label: Semantics(
                  label: 'Tout décocher, ${c.label}',
                  excludeSemantics: true,
                  child: const Text('Tout décocher'),
                ),
              ),
            ],
          ),
        ),
      );
      for (final o in c.options) {
        rows.add(
          CheckboxListTile(
            key: ValueKey(_k('filter-${o.key}')),
            value: selected.contains(o.key),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.standard,
            onChanged: (_) => widget.onChanged(value.toggle(c.id, o.key)),
            title: Semantics(
              label: '${o.label}, ${c.label}',
              excludeSemantics: true,
              child: Text(o.label),
            ),
          ),
        );
      }
    }
    return [
      SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    ];
  }
}
