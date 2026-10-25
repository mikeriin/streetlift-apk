// RV4 (dev7.7.2, DECISIONS_CP.md C17.51.5) — « Remplacer pour
// aujourd'hui » : choix du remplaçant d'un exercice de la séance du jour.
//
// Propositions d'abord ; en mode Libre (mode du profil, C17.51.4),
// recherche par nom (sans accents) dans toute la base d'exercices et les
// exercices personnels. En mode Assisté, les propositions seules, et une
// ligne dit que le choix libre existe en mode Libre.
//
// KB6 (dev7.8.0, Koach 1.0.9, C17.54-55) : propositions de Koach groupées
// et étiquetées (« Équivalent », « Plus facile », « Sans ce matériel »,
// « Autre »), chacune avec sa raison courte et sa cible de départ ; en
// tête, « Pourquoi ? » facultatif (pas de matériel → « Il me manque : »
// matériel de l'exercice à cocher, douleur, trop dur, autre) qui recalcule
// les propositions. La recherche de toute la base (Libre) reste en
// dessous, inchangée.
import 'package:flutter/material.dart';

import 'content_pack.dart' show ExerciseEntry;
import 'exercise_screens.dart' show ExerciseFilters, searchExercises;
import 'kit/kit.dart';
import 'search.dart' show normalizeText;
import 'store.dart';

/// Remplaçant choisi : exercice de la base ([id]) ou exercice personnel
/// ([id] null), et son nom. KB6 : raison de « Pourquoi ? » ([reason], code
/// de Koach), matériel qui manque, cible de départ de Koach ([depart],
/// vide : à choisir) et étiquette de la proposition ([label]).
typedef ReplacePick = ({
  String? id,
  String name,
  String? reason,
  List<String> missing,
  Map<String, Object?> depart,
  String? label,
});

/// KB6 : propositions recalculées pour la raison [reason] (null : aucune
/// réponse) et le matériel qui manque [missing].
typedef ReplaceOptionsOf =
    DayReplaceOptions? Function(String? reason, List<String> missing);

class ReplaceExercisePage extends StatefulWidget {
  /// Exercice remplacé (titre court).
  final String fromName;

  /// Propositions sans Koach (identifiants de la base), en tête, quand
  /// [options] est absent (RV4).
  final List<String> proposals;

  /// Mode Libre : toute la base et les exercices personnels.
  final bool free;

  /// KB6 : propositions de Koach selon la réponse à « Pourquoi ? ».
  final ReplaceOptionsOf? options;

  /// KB6 : matériel de l'exercice écrit, proposé sous « Il me manque : ».
  final List<String> missingChoices;

  /// KB6 : cible de départ d'un exercice choisi dans la recherche (null :
  /// rien, à choisir).
  final Map<String, Object?>? Function(String id)? departOf;

  /// KB6 : libellé d'une charge (cible de départ).
  final String Function(double kg)? kgLabel;
  const ReplaceExercisePage({
    super.key,
    required this.fromName,
    this.proposals = const [],
    required this.free,
    this.options,
    this.missingChoices = const [],
    this.departOf,
    this.kgLabel,
  });

  @override
  State<ReplaceExercisePage> createState() => _ReplaceExercisePageState();
}

class _ReplaceExercisePageState extends State<ReplaceExercisePage> {
  final _c = TextEditingController();
  String _q = '';
  int _shown = 40;

  /// KB6 : réponse à « Pourquoi ? » (code de Koach) et matériel coché.
  String? _reason;
  final List<String> _missing = [];
  DayReplaceOptions? _opts;

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _recompute() {
    _opts = widget.options?.call(_reason, List.of(_missing));
  }

  void _setReason(String? r) => setState(() {
    _reason = _reason == r ? null : r;
    if (_reason != 'pas_de_materiel') _missing.clear();
    _recompute();
  });

  void _toggleMissing(String m) => setState(() {
    if (!_missing.remove(m)) _missing.add(m);
    _recompute();
  });

  void _pick(
    String? id,
    String name, {
    Map<String, Object?> depart = const {},
    String? label,
  }) => Navigator.pop<ReplacePick>(context, (
    id: id,
    name: name,
    reason: _reason,
    missing: List.of(_missing),
    depart: depart,
    label: label,
  ));

  String _kg(double kg) =>
      widget.kgLabel?.call(kg) ?? '${formatDecimal(kg)} kg';

  /// Sous-titre d'une proposition : raison courte, cible de départ.
  String? _subtitle(DayReplaceProposal p) {
    final d = dayDepartText(p.depart, _kg);
    final parts = [
      if (p.text.isNotEmpty) p.text,
      d == null ? 'Cible à choisir' : 'Départ : $d',
    ];
    return parts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final content = store.content;
    final query = _q.trim();
    final koach = widget.options != null;
    final opts = _opts;
    final List<ExerciseEntry> proposals = query.isEmpty && !koach
        ? [
            for (final id in widget.proposals)
              if (content.byId[id] case final e?) e,
          ]
        : const [];
    final groups = <String, List<DayReplaceProposal>>{};
    if (query.isEmpty && opts != null) {
      for (final p in opts.proposals) {
        (groups[p.label] ??= []).add(p);
      }
    }
    final List<ExerciseEntry> found = widget.free
        ? searchExercises(content, query, const ExerciseFilters())
        : const [];
    final list = found.take(_shown).toList();
    final norm = normalizeText(query);
    final own = widget.free
        ? [
            for (final u in store.userExercises)
              if ('${u['n'] ?? ''}'.trim() case final n
                  when n.isNotEmpty &&
                      (norm.isEmpty || normalizeText(n).contains(norm)))
                n,
          ]
        : const <String>[];
    final noProposal = query.isEmpty && proposals.isEmpty && groups.isEmpty;
    return KPage.sub(
      key: const ValueKey('replace-page'),
      title: 'Remplacer pour aujourd’hui',
      lead:
          'À la place de « ${widget.fromName} », pour cette séance seulement : '
          'séries, groupe et chrono gardés ; ton programme ne change pas.',
      children: [
        if (koach && query.isEmpty) ...[
          Text(
            'Pourquoi ? (facultatif)',
            key: const ValueKey('replace-why'),
            style: KType.corpsFort.copyWith(color: k.texte),
          ),
          Wrap(
            spacing: KSpacing.s8,
            children: [
              for (final r in kDayReplaceReasons.entries)
                KChip(
                  r.value,
                  key: ValueKey('replace-why-${r.key}'),
                  selected: _reason == r.key,
                  onTap: () => _setReason(r.key),
                ),
            ],
          ),
          if (_reason == 'pas_de_materiel' &&
              widget.missingChoices.isNotEmpty) ...[
            Text(
              'Il me manque :',
              key: const ValueKey('replace-missing'),
              style: KType.corpsFort.copyWith(color: k.texte),
            ),
            Wrap(
              spacing: KSpacing.s8,
              children: [
                for (final m in widget.missingChoices)
                  KChip(
                    _capitalized(m),
                    key: ValueKey('replace-missing-$m'),
                    icon: _missing.contains(m)
                        ? Icons.check_rounded
                        : Icons.add_rounded,
                    selected: _missing.contains(m),
                    onTap: () => _toggleMissing(m),
                  ),
              ],
            ),
          ],
        ],
        for (final g in kDayReplaceLabels.entries)
          if (groups[g.key] case final ps? when ps.isNotEmpty)
            KMenuGroup(
              key: ValueKey('replace-group-${g.key}'),
              title: g.value,
              dividerIndent: KSpacing.s16,
              children: [
                for (final p in ps)
                  KMenuRow(
                    key: ValueKey('replace-proposal-${p.id}'),
                    title: p.name,
                    subtitle: _subtitle(p),
                    onTap: () =>
                        _pick(p.id, p.name, depart: p.depart, label: p.label),
                  ),
              ],
            ),
        if (proposals.isNotEmpty)
          KMenuGroup(
            title: 'Proposés',
            dividerIndent: KSpacing.s16,
            children: [
              for (final e in proposals)
                KMenuRow(
                  key: ValueKey('replace-proposal-${e.id}'),
                  title: e.nom,
                  subtitle: e.discipline,
                  onTap: () => _pick(e.id, e.nom),
                ),
            ],
          ),
        if (noProposal && (!widget.free || koach))
          Text(
            koach
                ? 'Aucune proposition de Koach pour cette raison.'
                : 'Aucune proposition pour cet exercice.',
            key: const ValueKey('replace-none'),
            style: KType.corps.copyWith(color: k.texte2),
          ),
        if (widget.free)
          KSearchField(
            key: const ValueKey('replace-search'),
            controller: _c,
            hint: 'Rechercher dans toute la base',
            onChanged: (v) => setState(() {
              _q = v;
              _shown = 40;
            }),
          )
        else
          Text(
            'En mode Libre (Évolution), tu peux choisir n’importe quel '
            'exercice de la base.',
            key: const ValueKey('replace-free-hint'),
            style: KType.detail.copyWith(color: k.texte2),
          ),
        if (own.isNotEmpty)
          KMenuGroup(
            title: 'Mes exercices',
            dividerIndent: KSpacing.s16,
            children: [
              for (final n in own)
                KMenuRow(
                  key: ValueKey('replace-own-$n'),
                  title: n,
                  onTap: () => _pick(null, n),
                ),
            ],
          ),
        if (list.isNotEmpty)
          KMenuGroup(
            title: 'Toute la base',
            dividerIndent: KSpacing.s16,
            children: [
              for (final e in list)
                KMenuRow(
                  key: ValueKey('replace-${e.id}'),
                  title: e.nom,
                  subtitle: e.discipline,
                  onTap: () => _pick(
                    e.id,
                    e.nom,
                    depart: widget.departOf?.call(e.id) ?? const {},
                  ),
                ),
            ],
          )
        else if (widget.free && query.isNotEmpty && own.isEmpty)
          Text(
            'Aucun exercice ne correspond.',
            key: const ValueKey('replace-empty'),
            style: KType.corps.copyWith(color: k.texte2),
          ),
        if (found.length > list.length)
          KTonalButton(
            key: const ValueKey('replace-more'),
            label: 'Afficher plus (${found.length - list.length} restants)',
            expand: true,
            onPressed: () => setState(() => _shown += 40),
          ),
      ],
    );
  }
}

String _capitalized(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
