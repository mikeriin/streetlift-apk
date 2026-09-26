// Koach (L7, KT-033) — éléments affichés pendant la séance : difficulté
// d'une série (D8, D9), série écartée (D11), suggestion de charge (D24),
// jour de fatigue (D25), questionnaire d'avant séance (D14), incertitude
// (D29), pesée (D12). Textes : jamais « IA », aucun vocabulaire médical,
// aucune promesse ; un état est toujours écrit, jamais porté par la seule
// couleur. Rien ne change sans un tap (D4).
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'koach_engine.dart' as ke;
import 'set_validation.dart' show parseLoadKg;
import 'store.dart';
import 'ui.dart';

/// Choix fait dans la fiche de difficulté d'une série.
class EffortChoice {
  /// Difficulté en RIR (échelle D9) ; null = effacée.
  final double? rir;
  final bool excluded;
  const EffortChoice(this.rir, this.excluded);
}

/// Fiche de difficulté : six boutons (libellé + « encore N »), un tap
/// choisit. [validating] : validation d'une série qui l'exige (D8).
Future<EffortChoice?> showEffortSheet(
  BuildContext context, {
  required String title,
  double? current,
  bool excluded = false,
  bool validating = false,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<EffortChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder:
        (context) => EffortSheet(
          title: title,
          current: current,
          excluded: excluded,
          validating: validating,
        ),
  );
}

class EffortSheet extends StatelessWidget {
  final String title;
  final double? current;
  final bool excluded, validating;
  const EffortSheet({
    super.key,
    required this.title,
    this.current,
    this.excluded = false,
    this.validating = false,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          validating
              ? 'Koach a besoin de la difficulté de cette série pour la '
                  'valider : combien de répétitions aurais-tu encore pu faire ?'
              : 'Combien de répétitions aurais-tu encore pu faire ?',
          style: TextStyle(color: SL.dim),
        ),
        const SizedBox(height: 12),
        for (final level in ke.effortScale)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _EffortButton(
              level: level,
              selected: current == level.rir.toDouble(),
              onTap:
                  () => Navigator.pop(
                    context,
                    EffortChoice(level.rir.toDouble(), excluded),
                  ),
            ),
          ),
        if (!validating && current != null)
          TextButton.icon(
            key: const ValueKey('effort-clear'),
            onPressed:
                () => Navigator.pop(context, EffortChoice(null, excluded)),
            icon: const Icon(Icons.backspace_outlined),
            label: const Text('Effacer la difficulté'),
          ),
        if (!validating)
          SwitchListTile.adaptive(
            key: const ValueKey('effort-exclude'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Série écartée (incident)'),
            subtitle: const Text(
              'Elle reste au journal, XP comprise, mais ne compte pas dans '
              'les estimations de Koach.',
            ),
            value: excluded,
            onChanged: (v) => Navigator.pop(context, EffortChoice(current, v)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    ),
  );
}

class _EffortButton extends StatelessWidget {
  final ke.EffortLevel level;
  final bool selected;
  final VoidCallback onTap;
  const _EffortButton({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      children: [
        if (selected) ...[
          const Icon(Icons.check, size: 20),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            level.label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(level.more, textAlign: TextAlign.end)),
      ],
    );
    final key = ValueKey('effort-${level.rir}');
    return Semantics(
      selected: selected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child:
            selected
                ? FilledButton(key: key, onPressed: onTap, child: child)
                : OutlinedButton(key: key, onPressed: onTap, child: child),
      ),
    );
  }
}

/// Ligne Koach sous une série validée : difficulté et série écartée ; un
/// tap ouvre la fiche. [onTap] null : lecture seule (historique).
class KoachSetLine extends StatelessWidget {
  final String setLabel;
  final String? effort;
  final bool excluded;
  final VoidCallback? onTap;
  const KoachSetLine({
    super.key,
    required this.setLabel,
    this.effort,
    this.excluded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = [
      effort ?? 'Difficulté non notée',
      if (excluded) 'série écartée',
    ].join(' · ');
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          excluded ? Icons.block_rounded : Icons.speed_rounded,
          size: 16,
          color: SL.dim,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: effort == null && onTap != null ? SL.accent : SL.dim,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.edit_outlined, size: 14, color: SL.dim),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          button: onTap != null,
          label: 'Série $setLabel : $text${onTap == null ? '' : '. Modifier'}',
          excludeSemantics: true,
          onTap: onTap,
          child: InkWell(
            key: ValueKey('koach-set-$setLabel'),
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: onTap == null ? 24 : 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: row,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _overline() => TextStyle(
  color: SL.dim,
  fontSize: 11,
  fontWeight: FontWeight.w700,
  letterSpacing: .8,
);

Widget _koachHeader(String text, {IconData icon = Icons.insights_rounded}) =>
    Row(
      children: [
        Icon(icon, size: 18, color: SL.accent),
        const SizedBox(width: 6),
        Expanded(child: Text(text.toUpperCase(), style: _overline())),
      ],
    );

/// Règle D24 appliquée, en une phrase (fiche au tap).
String koachRuleText(ke.KSuggestion sug) => switch (sug.reason) {
  'easy2' =>
    'Série 1 plus facile que visé d’au moins deux niveaux : +6 % de la masse '
        'soulevée, arrondi à l’incrément inférieur de ton matériel, plafond '
        '+5 kg.',
  'easy1' =>
    'Série 1 plus facile que visé d’un niveau : +3 % de la masse soulevée, '
        'arrondi à l’incrément inférieur, plafond +2,5 kg.',
  'twoHard' =>
    'Deux séries de suite à Très dur ou Échec alors que le programme vise '
        'au moins Dur : −3 %, arrondi à l’incrément supérieur.',
  'missed' =>
    'Série ratée (moins de répétitions que prévu) : −3 %, arrondi à '
        'l’incrément supérieur.',
  'missed2' =>
    'Série ratée de deux répétitions ou plus : −6 %, arrondi à l’incrément '
        'supérieur.',
  _ => '',
};

/// Suggestion pour les séries restantes (D24) : raison en une ligne,
/// « Appliquer » / « Garder ma charge », fiche au tap (D30).
class KoachSuggestionCard extends StatelessWidget {
  final String load, from, reason;
  final VoidCallback onApply, onKeep, onDetails;
  const KoachSuggestionCard({
    super.key,
    required this.load,
    required this.from,
    required this.reason,
    required this.onApply,
    required this.onKeep,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: KCard(
      key: const ValueKey('koach-suggestion'),
      accent: SL.accent,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      onTap: onDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _koachHeader('Koach · séries restantes')),
              Tooltip(
                message: 'Détail de la suggestion',
                child: Icon(Icons.info_outline, size: 18, color: SL.dim),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$load au lieu de $from',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: SL.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(reason, style: TextStyle(color: SL.dim, fontSize: 13)),
          const SizedBox(height: 10),
          KActionRow(
            minButtonWidth: 120,
            children: [
              FilledButton(
                key: const ValueKey('koach-apply'),
                onPressed: onApply,
                child: const Text('Appliquer'),
              ),
              OutlinedButton(
                key: const ValueKey('koach-keep'),
                onPressed: onKeep,
                child: const Text('Garder ma charge'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Fiche d'une suggestion : règle, estimation, rappel que tu décides.
void showKoachDetails(
  BuildContext context, {
  required String title,
  required List<String> lines,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder:
        (context) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final line in lines)
                if (line.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(line),
                  ),
              Text(
                'Estimation d’entraînement calculée sur ton téléphone, sans '
                'garantie de résultat : tu restes seul juge de ta charge.',
                style: TextStyle(color: SL.dim, fontSize: 12.5),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
  );
}

/// Jour de fatigue probable (D25) : volume réduit, charges maintenues.
class KoachFatigueCard extends StatelessWidget {
  final double level;

  /// Séries non validées retirées si la proposition est acceptée.
  final int sets;
  final VoidCallback onAccept, onRefuse;
  const KoachFatigueCard({
    super.key,
    required this.level,
    required this.sets,
    required this.onAccept,
    required this.onRefuse,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: KCard(
      key: const ValueKey('koach-fatigue'),
      accent: SL.bordeaux,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _koachHeader(
            'Koach · jour de fatigue probable',
            icon: Icons.battery_3_bar_rounded,
          ),
          const SizedBox(height: 6),
          Text(
            'Retirer $sets série${sets > 1 ? 's' : ''} non validée'
            '${sets > 1 ? 's' : ''} (−${(level * 100).round()} % de volume) ?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: SL.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Séries retirées en fin d’exercice, de la fin de la séance vers le '
            'début ; charges maintenues, aucune tentative lourde aujourd’hui. '
            'Tu peux aussi continuer comme prévu.',
            style: TextStyle(color: SL.dim, fontSize: 13),
          ),
          const SizedBox(height: 10),
          KActionRow(
            minButtonWidth: 120,
            children: [
              FilledButton(
                key: const ValueKey('koach-fatigue-accept'),
                onPressed: onAccept,
                child: const Text('Réduire le volume'),
              ),
              OutlinedButton(
                key: const ValueKey('koach-fatigue-refuse'),
                onPressed: onRefuse,
                child: const Text('Continuer comme prévu'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Tranches de sommeil (valeur centrale enregistrée, en heures).
const koachSleepOptions = <(String, double)>[
  ('moins de 5 h', 4.5),
  ('5 à 6 h', 5.5),
  ('6 à 7 h', 6.5),
  ('7 à 8 h', 7.5),
  ('plus de 8 h', 8.5),
];

/// Questionnaire facultatif d'avant séance (D14) : sommeil, forme /10.
class KoachQuestionsCard extends StatelessWidget {
  final String sessionKey;
  const KoachQuestionsCard({super.key, required this.sessionKey});

  @override
  Widget build(BuildContext context) {
    final a = store.koach.answers[sessionKey];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: KCard(
        key: const ValueKey('koach-questions'),
        radius: 20,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _koachHeader(
              'Koach · avant de commencer (facultatif)',
              icon: Icons.checklist_rounded,
            ),
            const SizedBox(height: 8),
            Text(
              'Sommeil de la nuit',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (label, value) in koachSleepOptions)
                  ChoiceChip(
                    label: Text(label),
                    selected: a?.sleep == value,
                    onSelected:
                        (on) => store.setKoachAnswers(
                          sessionKey,
                          sleep: on ? value : null,
                          form: a?.form,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Forme du jour : 0 au plus bas, 10 excellente',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i <= 10; i++)
                  ChoiceChip(
                    label: Text('$i'),
                    tooltip: 'Forme $i sur 10',
                    selected: a?.form == i,
                    onSelected:
                        (on) => store.setKoachAnswers(
                          sessionKey,
                          sleep: a?.sleep,
                          form: on ? i : null,
                        ),
                  ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('koach-questions-skip'),
                onPressed: () => store.koachSkipQuestions(sessionKey),
                child: const Text('Passer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estimation trop incertaine (D29) : série de calibrage.
class KoachCalibrationNote extends StatelessWidget {
  const KoachCalibrationNote({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.tune_rounded, size: 16, color: SL.dim),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Koach : estimation encore incertaine pour ce mouvement. Fais le '
            'format du jour et note la difficulté de chaque série : elles '
            'serviront de calibrage.',
            key: const ValueKey('koach-calibration'),
            style: TextStyle(color: SL.dim, fontSize: 12.5),
          ),
        ),
      ],
    ),
  );
}

/// Saisie d'une pesée datée (D12) ; renvoie true si enregistrée.
Future<bool> showWeighInDialog(BuildContext context, {DateTime? date}) async {
  final result = await showDialog<(DateTime, double)>(
    context: context,
    builder: (_) => _WeighInDialog(initial: date ?? store.storeClock()),
  );
  if (result == null) return false;
  store.addWeighIn(result.$1, result.$2);
  return true;
}

class _WeighInDialog extends StatefulWidget {
  final DateTime initial;
  const _WeighInDialog({required this.initial});
  @override
  State<_WeighInDialog> createState() => _WeighInDialogState();
}

class _WeighInDialogState extends State<_WeighInDialog> {
  final _kg = TextEditingController();
  late DateTime _date = widget.initial;
  String? _error;

  @override
  void initState() {
    super.initState();
    final bw = store.koachBodyweightNow;
    if (bw != null) _kg.text = koachKg(bw);
  }

  @override
  void dispose() {
    _kg.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = store.storeClock();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(today.year - 2),
      lastDate: today,
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _save() {
    final v = parseLoadKg(_kg.text);
    if (v == null || v < 20 || v > 400) {
      setState(() => _error = 'Poids en kg, de 20 à 400 (ex. 72,5).');
      return;
    }
    Navigator.pop(context, (_date, v));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Pesée'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('weigh-in-kg'),
            controller: _kg,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Poids du corps (kg)',
              errorText: _error,
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_rounded),
            label: Text(
              MaterialLocalizations.of(context).formatMediumDate(_date),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        key: const ValueKey('weigh-in-save'),
        onPressed: _save,
        child: const Text('Enregistrer'),
      ),
    ],
  );
}

/// Rappel de pesée hebdomadaire sur l'accueil (D12, jamais notifié).
class KoachWeighInBanner extends StatelessWidget {
  const KoachWeighInBanner({super.key});

  @override
  Widget build(BuildContext context) => KCard(
    key: const ValueKey('koach-weigh-in-banner'),
    radius: 20,
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _koachHeader(
          'Koach · pesée de la semaine',
          icon: Icons.monitor_weight_outlined,
        ),
        const SizedBox(height: 6),
        Text(
          'Ton poids du corps sert au calcul des mouvements lestés. Dernière '
          'pesée : ${store.koach.weighIns.isEmpty ? 'aucune' : '${koachKg(store.koach.weighIns.last.kg)} kg'}.',
          style: TextStyle(color: SL.dim, fontSize: 13),
        ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          children: [
            TextButton(
              onPressed: store.koachWeighInSnooze,
              child: const Text('Plus tard'),
            ),
            FilledButton(
              key: const ValueKey('koach-weigh-in-now'),
              onPressed: () => showWeighInDialog(context),
              child: const Text('Noter mon poids'),
            ),
          ],
        ),
      ],
    ),
  );
}
