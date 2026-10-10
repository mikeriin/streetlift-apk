// Départ du programme (KT-006) et références initiales (KT-007).
//
// Décisions du 26/09/2026 : la date choisie est S1 · J1, quel que soit le jour
// de la semaine ; bornes : 280 jours dans le passé, un an dans le futur ;
// références inconnues par défaut (« Je ne sais pas ») ; une installation
// existante garde son calendrier, modifiable sans remise à zéro.
import 'package:flutter/material.dart';

import 'data_control.dart';
import 'models.dart';
import 'pilotage_screen.dart';
import 'plan/plan_screens.dart' show openPlanCreation;
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
    final proposed = _civil(widget.initialDate ?? store.program.start ?? today);
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
      firstDate: today.subtract(const Duration(days: AppStore.startPastDays)),
      lastDate: today.add(const Duration(days: AppStore.startFutureDays)),
      helpText: 'Date de départ (semaine 1, jour 1)',
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
            'Départ enregistré : semaine 1, jour 1 le '
            '${longCivilDate(_date)}.',
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
    final k = KTokens.of(context);
    final program = store.program;
    final weeks = program.weeks.length;
    final today = _civil(store.storeClock());
    final end = DateTime(_date.year, _date.month, _date.day + weeks * 7 - 1);
    final current = program.start;
    final changed =
        current == null ||
        Program.civilIndex(current) != Program.civilIndex(_date);
    final dim = KType.detail.copyWith(color: k.texte2);
    final body = KType.corps.copyWith(color: k.texte);
    final cardTitle = KType.titreCarte.copyWith(color: k.texte);
    final positionNow = programPosition(_date, today, weeks);
    return Form(
      key: _form,
      child: KPage.sub(
        title: 'Départ du programme',
        lead:
            'La date choisie est ta première séance (semaine 1, jour 1), '
            'quel que soit le jour de la semaine. Les $weeks semaines '
            's’enchaînent ensuite sans décalage automatique ; aucun nouveau '
            'cycle n’est lancé à la fin.',
        bottom: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpacing.page,
              KSpacing.s8,
              KSpacing.page,
              KSpacing.s16,
            ),
            // Deux boutons de même hauteur (56) : le bouton tonal prend la
            // hauteur du bouton principal ; écran étroit ou grand texte :
            // l'un sous l'autre (`KActionRow`).
            child: KActionRow(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: KSize.primary),
                  child: KTonalButton(
                    key: const ValueKey('start-later'),
                    expand: true,
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    label: _pending ? 'Plus tard' : 'Annuler',
                  ),
                ),
                KPrimaryButton(
                  key: const ValueKey('start-confirm'),
                  onPressed: _saving || !changed && !_pending ? null : _confirm,
                  label: _saving
                      ? 'Enregistrement…'
                      : current == null
                      ? 'Confirmer le départ'
                      : 'Changer la date',
                ),
              ],
            ),
          ),
        ),
        children: [
          if (current != null)
            KCard(
              key: const ValueKey('start-current'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Départ actuel', style: cardTitle),
                  const SizedBox(height: KSpacing.s4),
                  Text(
                    'Semaine 1, jour 1 le ${longCivilDate(current)}',
                    style: body,
                  ),
                  if (store.startOrigin == 'migration') ...[
                    const SizedBox(height: KSpacing.s4),
                    Text(
                      'Calendrier d’origine de ton installation, conservé à '
                      'la mise à jour.',
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
                  current == null
                      ? 'Date de la semaine 1, jour 1'
                      : 'Nouvelle date de la semaine 1, jour 1',
                  style: cardTitle,
                ),
                const SizedBox(height: KSpacing.s8),
                Text(
                  longCivilDate(_date),
                  key: const ValueKey('start-date'),
                  style: KType.titreSeance.copyWith(color: k.encre),
                ),
                const SizedBox(height: KSpacing.s8),
                KTonalButton(
                  key: const ValueKey('start-pick'),
                  onPressed: _saving ? null : _pick,
                  icon: Icons.event_rounded,
                  label: 'Choisir une autre date',
                ),
                const SizedBox(height: KSpacing.s12),
                Semantics(
                  container: true,
                  liveRegion: true,
                  child: Column(
                    key: const ValueKey('start-preview'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fin prévue (S$weeks · J7) : ${longCivilDate(end)}',
                        style: body,
                      ),
                      const SizedBox(height: KSpacing.s4),
                      Text(switch (positionNow) {
                        'avant le départ' =>
                          'Avant le départ, l’accueil l’indique ; aucun '
                              'rappel avant la semaine 1, jour 1.',
                        'programme terminé' =>
                          'Avec cette date, le programme est déjà terminé '
                              'aujourd’hui.',
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
              outline: k.encre,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Effet du changement', style: cardTitle),
                  const SizedBox(height: KSpacing.s8),
                  Text(
                    'Aujourd’hui : ${programPosition(current, today, weeks)} '
                    '→ $positionNow.',
                    style: body,
                  ),
                  const SizedBox(height: KSpacing.s4),
                  Text(
                    'Tes séances faites gardent leur semaine, leur jour et '
                    'leur date réelle. Tes références ne changent pas. Les '
                    'rappels sont replanifiés sur les nouvelles dates.',
                    style: dim,
                  ),
                ],
              ),
            ),
          if (_pending) ...[
            // UI4 (R1, R2) : même nom que la page des références.
            const KSectionTitle('Mes références (facultatif)'),
            KCard(
              child: Text(
                'Laisse vide si tu ne sais pas : aucune valeur n’est '
                'inventée, les charges et volumes concernés afficheront « à '
                'renseigner ». Aucun test maximal n’est exigé. Tu pourras '
                'les compléter plus tard, avec les accessoires, dans Mes '
                'références. Valeurs en kg.',
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
    padding: const EdgeInsets.symmetric(
      horizontal: KSpacing.s16,
      vertical: KSpacing.s12,
    ),
    child: TextFormField(
      key: ValueKey('start-ref-$ref'),
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (t) =>
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

/// Bandeau de l'accueil : départ à choisir, compte à rebours avant la
/// semaine 1, jour 1, programme terminé. Rien pendant le programme.
/// UI4 : bandeau du kit dans le flux (`KNotice`), avec son action (R6 :
/// « Créer un nouveau programme » quand le programme est terminé).
class ProgramStartBanner extends StatelessWidget {
  final DateTime now;
  final EdgeInsetsGeometry padding;
  const ProgramStartBanner({
    super.key,
    required this.now,
    this.padding = const EdgeInsets.only(
      left: KSpacing.page,
      right: KSpacing.page,
      bottom: KSpacing.s8,
    ),
  });

  /// Le bandeau a quelque chose à dire : départ à choisir, à venir ou
  /// programme terminé.
  static bool visible(Program p, DateTime now) =>
      !p.scheduled || p.beforeStart(now) || p.afterEnd(now);

  @override
  Widget build(BuildContext context) {
    final p = store.program;
    final start = p.start;
    final String title, body, action;
    final VoidCallback onAction;
    void open() => Navigator.of(
      context,
    ).push(MaterialPageRoute<bool>(builder: (_) => const ProgramStartScreen()));
    if (start == null) {
      title = 'Programme non démarré';
      body =
          'Choisis la date de ta première séance (semaine 1, jour 1). En '
          'attendant, tu peux parcourir les semaines.';
      action = 'Choisir mon départ';
      onAction = open;
    } else if (p.beforeStart(now)) {
      final days = Program.civilIndex(start) - Program.civilIndex(_civil(now));
      title = 'Départ le ${longCivilDate(start)}';
      body =
          'Semaine 1, jour 1 dans $days jour${days > 1 ? 's' : ''}. Aucun '
          'rappel avant cette date.';
      action = 'Modifier';
      onAction = open;
    } else if (p.afterEnd(now)) {
      title = 'Programme terminé le ${longCivilDate(p.endDate!)}';
      body =
          'Les ${p.weeks.length} semaines sont passées. Ton historique reste '
          'consultable ; aucun nouveau cycle n’est lancé.';
      action = 'Créer un nouveau programme';
      onAction = () => openPlanCreation(context);
    } else {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: padding,
      child: Semantics(
        container: true,
        child: KNotice(
          key: const ValueKey('program-start-banner'),
          icon: Icons.event_rounded,
          title: title,
          message: body,
          actionLabel: action,
          onAction: onAction,
        ),
      ),
    );
  }
}
