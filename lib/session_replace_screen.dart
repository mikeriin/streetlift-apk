// RV4 (dev7.7.2, DECISIONS_CP.md C17.51.5) — « Remplacer pour
// aujourd'hui » : choix du remplaçant d'un exercice de la séance du jour.
//
// Propositions d'abord (les exercices de la base les plus proches) ; en mode
// Libre (mode du profil, C17.51.4), recherche par nom (sans accents) dans
// toute la base d'exercices et les exercices personnels. En mode Assisté,
// les propositions seules, et une ligne dit que le choix libre existe en
// mode Libre.
import 'package:flutter/material.dart';

import 'content_pack.dart' show ExerciseEntry;
import 'exercise_screens.dart' show ExerciseFilters, searchExercises;
import 'kit/kit.dart';
import 'search.dart' show normalizeText;
import 'store.dart';

/// Remplaçant choisi : exercice de la base ([id]) ou exercice personnel
/// ([id] null), et son nom.
typedef ReplacePick = ({String? id, String name});

class ReplaceExercisePage extends StatefulWidget {
  /// Exercice remplacé (titre court).
  final String fromName;

  /// Propositions (identifiants de la base), en tête.
  final List<String> proposals;

  /// Mode Libre : toute la base et les exercices personnels.
  final bool free;
  const ReplaceExercisePage({
    super.key,
    required this.fromName,
    required this.proposals,
    required this.free,
  });

  @override
  State<ReplaceExercisePage> createState() => _ReplaceExercisePageState();
}

class _ReplaceExercisePageState extends State<ReplaceExercisePage> {
  final _c = TextEditingController();
  String _q = '';
  int _shown = 40;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _pick(ReplacePick p) => Navigator.pop(context, p);

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final content = store.content;
    final query = _q.trim();
    final List<ExerciseEntry> proposals = query.isEmpty
        ? [
            for (final id in widget.proposals)
              if (content.byId[id] case final e?) e,
          ]
        : const [];
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
    return KPage.sub(
      key: const ValueKey('replace-page'),
      title: 'Remplacer pour aujourd’hui',
      lead:
          'À la place de « ${widget.fromName} », pour cette séance seulement : '
          'séries, groupe et chrono gardés ; ton programme ne change pas.',
      children: [
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
                  onTap: () => _pick((id: e.id, name: e.nom)),
                ),
            ],
          )
        else if (!widget.free)
          Text(
            'Aucune proposition pour cet exercice.',
            key: const ValueKey('replace-none'),
            style: KType.corps.copyWith(color: k.texte2),
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
                  onTap: () => _pick((id: null, name: n)),
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
                  onTap: () => _pick((id: e.id, name: e.nom)),
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
