// Départ du programme (KT-006) et références initiales (KT-007).
//
// Décisions du 26/09/2026 : la date choisie est S1 · J1, quel que soit le jour
// de la semaine ; bornes : 280 jours dans le passé, un an dans le futur ;
// références inconnues par défaut (« Je ne sais pas ») ; une installation
// existante garde son calendrier, modifiable sans remise à zéro.
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'data_control.dart';
import 'models.dart';
import 'pilotage_screen.dart';
import 'store.dart';
import 'ui.dart';

const _weekdays = [
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];
const _months = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// « lundi 13 juillet 2026 ».
String longCivilDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day == 1 ? '1er' : d.day} ${_months[d.month - 1]} ${d.year}';

DateTime _civil(DateTime d) => DateTime(d.year, d.month, d.day);

/// Position du jour [date] pour un départ [start] : « S3 · J5 », ou l'état
/// hors programme, sans semaine 41 ni nouveau cycle.
String programPosition(DateTime start, DateTime date, int weeks) {
  final o =
      Program.civilIndex(_civil(date)) - Program.civilIndex(_civil(start));
  if (o < 0) return 'avant le départ';
  if (o >= weeks * 7) return 'programme terminé';
  return 'S${o ~/ 7 + 1} · J${o % 7 + 1}';
}

/// Références proposées au premier départ : poids du corps, 1RM de travail et
/// maxima en répétitions. Les accessoires se complètent plus tard.
List<(String ref, String label, String unit, String hint)> _startFields() {
  final p = store.program.pilotage;
  return [
    ('B4', 'Poids du corps', 'kg', 'Sert au calcul des charges lestées'),
    for (final l in p.mainLifts)
      (
        l.ref,
        '${l.name} · 1RM',
        l.unit,
        l.ref == 'B11'
            ? 'Charge totale de la barre'
            : 'Lest = charge ajoutée au poids du corps',
      ),
    for (final m in p.repMax)
      (m.ref, '${m.name} · max', 'reps', 'Répétitions strictes en une série'),
  ];
}

class ProgramStartScreen extends StatefulWidget {
  /// Date proposée à l'ouverture (tests) ; sinon le départ actuel ou
  /// aujourd'hui.
  final DateTime? initialDate;
  const ProgramStartScreen({super.key, this.initialDate});

  @override
  State<ProgramStartScreen> createState() => _ProgramStartScreenState();
}

class _ProgramStartScreenState extends State<ProgramStartScreen> {
  late DateTime _date;
  late final bool _pending;
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pending = !store.program.scheduled;
    final today = _civil(store.storeClock());
    final proposed = _civil(
      widget.initialDate ?? store.program.start ?? today,
    );
    _date = store.startAllowed(proposed) ? proposed : today;
    if (_pending) {
      for (final f in _startFields()) {
        final v = store.values[f.$1];
        _fields[f.$1] = TextEditingController(
          text: v == null ? '' : formatReference(v),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final today = _civil(store.storeClock());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today.subtract(
        const Duration(days: AppStore.startPastDays),
      ),
      lastDate: today.add(const Duration(days: AppStore.startFutureDays)),
      helpText: 'DATE DE S1 · J1',
      cancelText: 'Annuler',
      confirmText: 'Choisir',
    );
    if (picked != null && mounted) setState(() => _date = _civil(picked));
  }

  /// Références à enregistrer : seulement ce qui a changé. Un champ vidé
  /// d'une valeur connue la rend « non renseignée » ; un champ vide inconnu
  /// reste inconnu.
  Map<String, double?> _changedReferences() {
    final out = <String, double?>{};
    _fields.forEach((ref, c) {
      final text = c.text.trim();
      if (text.isEmpty) {
        if (store.refKnown(ref)) out[ref] = null;
        return;
      }
      final v = parseReference(text, ref);
      if (v != null && (store.values[ref] != v || !store.refKnown(ref))) {
        out[ref] = v;
      }
    });
    return out;
  }

  Future<void> _confirm() async {
    if (_saving) return;
    if (!(_form.currentState?.validate() ?? true)) return;
    setState(() => _saving = true);
    final result = await store.configureStart(
      _date,
      references: _pending ? _changedReferences() : const {},
    );
    if (!mounted) return;
    if (result == StartSave.saved) {
      try {
        await rescheduleReminders();
      } catch (_) {} // Les rappels ont leur propre état d'erreur.
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Départ enregistré : S1 · J1 le ${longCivilDate(_date)}.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          StartSave.outOfRange =>
            'Date hors limites : entre 280 jours avant et un an après aujourd’hui.',
          StartSave.invalid =>
            'Une référence n’est pas valide. Corrige-la ou laisse-la vide.',
          _ =>
            'Enregistrement impossible : le départ n’a pas été modifié. Réessaie.',
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final program = store.program;
    final weeks = program.weeks.length;
    final today = _civil(store.storeClock());
    final end = DateTime(_date.year, _date.month, _date.day + weeks * 7 - 1);
    final current = program.start;
    final changed =
        current == null ||
        Program.civilIndex(current) != Program.civilIndex(_date);
    final dim = Theme.of(context).textTheme.bodySmall;
    final positionNow = programPosition(_date, today, weeks);
    return KScreen(
      appBar: AppBar(title: const Text('DÉPART DU PROGRAMME')),
      body: Form(
        key: _form,
        child: KList(
          children: [
            KCard(
              child: Text(
                'La date choisie est ta première séance (S1 · J1), quel que soit '
                'le jour de la semaine. Les $weeks semaines s’enchaînent ensuite '
                'sans décalage automatique ; aucun nouveau cycle n’est lancé à la fin.',
                style: dim,
              ),
            ),
            if (current != null)
              KCard(
                key: const ValueKey('start-current'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Départ actuel',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('S1 · J1 le ${longCivilDate(current)}'),
                    if (store.startOrigin == 'migration') ...[
                      const SizedBox(height: 4),
                      Text(
                        'Calendrier d’origine de ton installation, conservé à la mise à jour.',
                        style: dim,
                      ),
                    ],
                  ],
                ),
              ),
            KCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current == null ? 'Date de S1 · J1' : 'Nouvelle date de S1 · J1',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    longCivilDate(_date),
                    key: const ValueKey('start-date'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('start-pick'),
                    onPressed: _saving ? null : _pick,
                    icon: const Icon(Icons.event_rounded),
                    label: const Text('Choisir une autre date'),
                  ),
                  const SizedBox(height: 10),
                  Semantics(
                    container: true,
                    liveRegion: true,
                    child: Column(
                      key: const ValueKey('start-preview'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fin prévue (S$weeks · J7) : ${longCivilDate(end)}'),
                        const SizedBox(height: 4),
                        Text(switch (positionNow) {
                          'avant le départ' =>
                            'Avant le départ, l’accueil l’indique ; aucun rappel avant S1 · J1.',
                          'programme terminé' =>
                            'Avec cette date, le programme est déjà terminé aujourd’hui.',
                          _ => 'Aujourd’hui : $positionNow.',
                        }, style: dim),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (current != null && changed)
              KCard(
                key: const ValueKey('start-impact'),
                accent: SL.action,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Effet du changement',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Aujourd’hui : ${programPosition(current, today, weeks)} → $positionNow.',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tes séances faites gardent leur semaine, leur jour et leur date réelle. '
                      'Crédits, droits WOD, résultats et références ne changent pas. '
                      'Les rappels sont replanifiés sur les nouvelles dates.',
                      style: dim,
                    ),
                  ],
                ),
              ),
            if (_pending) ...[
              const KSection('Tes références (facultatif)'),
              KCard(
                child: Text(
                  'Laisse vide si tu ne sais pas : aucune valeur n’est inventée, les '
                  'charges et volumes concernés afficheront « à renseigner ». Aucun '
                  'test maximal n’est exigé. Tu pourras compléter plus tard dans '
                  'Références, avec les accessoires. Valeurs en kg.',
                  style: dim,
                ),
              ),
              for (final f in _startFields())
                _ReferenceField(
                  ref: f.$1,
                  label: f.$2,
                  unit: f.$3,
                  hint: f.$4,
                  controller: _fields[f.$1]!,
                  enabled: !_saving,
                ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: KBottomActions(
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton(
              key: const ValueKey('start-later'),
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: Text(_pending ? 'Plus tard' : 'Annuler'),
            ),
            FilledButton(
              key: const ValueKey('start-confirm'),
              onPressed: _saving || !changed && !_pending ? null : _confirm,
              child: Text(
                _saving
                    ? 'Enregistrement…'
                    : current == null
                    ? 'Confirmer le départ'
                    : 'Changer la date',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceField extends StatelessWidget {
  final String ref, label, unit, hint;
  final TextEditingController controller;
  final bool enabled;
  const _ReferenceField({
    required this.ref,
    required this.label,
    required this.unit,
    required this.hint,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) => KCard(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: TextFormField(
      key: ValueKey('start-ref-$ref'),
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator:
          (t) =>
              (t ?? '').trim().isEmpty || parseReference(t, ref) != null
                  ? null
                  : 'Nombre (ex. 72,5) ou vide',
      decoration: InputDecoration(
        labelText: label,
        helperText: '$hint · vide = je ne sais pas',
        helperMaxLines: 3,
        hintText: 'Je ne sais pas',
        suffixText: unit.startsWith('kg') ? 'kg' : unit,
      ),
    ),
  );
}

/// Bandeau de l'accueil : départ à choisir, compte à rebours avant S1 · J1,
/// programme terminé. Rien pendant le programme.
class ProgramStartBanner extends StatelessWidget {
  final DateTime now;
  const ProgramStartBanner({super.key, required this.now});

  @override
  Widget build(BuildContext context) {
    final p = store.program;
    final start = p.start;
    final String title, body;
    String? action;
    if (start == null) {
      title = 'Programme non démarré';
      body =
          'Choisis la date de ta première séance (S1 · J1). En attendant, tu peux parcourir les semaines.';
      action = 'Choisir mon départ';
    } else if (p.beforeStart(now)) {
      final days =
          Program.civilIndex(start) - Program.civilIndex(_civil(now));
      title = 'Départ le ${longCivilDate(start)}';
      body =
          'S1 · J1 dans $days jour${days > 1 ? 's' : ''}. Aucun rappel avant cette date.';
      action = 'Modifier';
    } else if (p.afterEnd(now)) {
      title = 'Programme terminé le ${longCivilDate(p.endDate!)}';
      body =
          'Les ${p.weeks.length} semaines sont passées. Ton historique reste consultable ; aucun nouveau cycle n’est lancé.';
    } else {
      return const SizedBox.shrink();
    }
    void open() => Navigator.of(context).push(
      MaterialPageRoute<bool>(builder: (_) => const ProgramStartScreen()),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(KSpace.page, 0, KSpace.page, 8),
      child: Semantics(
        container: true,
        child: KCard(
          key: const ValueKey('program-start-banner'),
          accent: SL.action,
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(body, style: Theme.of(context).textTheme.bodySmall),
              if (action != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const ValueKey('program-start-open'),
                    onPressed: open,
                    child: Text(action),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
