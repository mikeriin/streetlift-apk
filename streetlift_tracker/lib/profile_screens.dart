// L8 (KT-039 à KT-043) — démarrage court, confirmation du profil d'une
// installation existante, écran Profil, questions progressives.
// Aucune illustration : icônes existantes et texte. Contrat :
// docs/CONTRAT_L8.md.

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'program_start.dart' show longCivilDate;
import 'store.dart';
import 'ui.dart';
import 'wellbeing_screens.dart' show DisclaimerCard, MinorGate;

/// Texte d'information affiché avant la collecte des données de santé.
const kHealthInfo =
    'Les réponses de santé, tes gênes, ton sommeil et ton stress peuvent être '
    'des données de santé. Elles servent uniquement à adapter ton '
    'entraînement (mode prudent). Elles restent sur ce téléphone, figurent '
    'dans l’export de sauvegarde et sont effacées avec les données de '
    'l’application. Tu peux retirer ton accord à tout moment (Réglages → '
    'Profil) : elles sont alors effacées. Sans accord, l’application '
    'fonctionne en mode prudent.';

const kCautionAdvice =
    'Mode prudent : pas de test maximal, au moins 3 répétitions en réserve sur '
    'les mouvements principaux, charges limitées à 80 % du 1RM estimé. '
    'Demande l’avis d’un médecin avant de t’entraîner intensément.';

/// Premier écran de l'application : démarrage court (installation neuve)
/// ou confirmation du profil (installation existante), puis l'application.
class ProfileGate extends StatefulWidget {
  final Widget child;
  const ProfileGate({super.key, required this.child});

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  /// « Plus tard » : confirmation reportée pendant cette ouverture.
  bool _later = false;

  @override
  Widget build(BuildContext context) {
    if (store.isFreshInstall) {
      return ProfileFlow(onDone: () => setState(() {}));
    }
    if (store.needsProfileConfirmation && !_later) {
      return ProfileFlow(
        initial: store.ownerDraft(),
        migration: true,
        onDone: () => setState(() {}),
        onLater: () => setState(() => _later = true),
      );
    }
    // L13 (KT-075) : un profil importé de moins de 18 ans bloque
    // l'application jusqu'à correction ou suppression des données.
    return ListenableBuilder(
      listenable: store,
      builder:
          (context, _) =>
              store.profileIsMinor ? const MinorGate() : widget.child,
    );
  }
}

/// Étapes du démarrage court (KT-039).
const kFlowSteps = [
  'welcome',
  'age',
  'goals',
  'availability',
  'places',
  'level',
  'health',
  'mode',
  'recap',
];

/// Démarrage court, confirmation (migration) ou modification du profil.
/// Rien n'est écrit avant le récapitulatif confirmé.
class ProfileFlow extends StatefulWidget {
  final UserProfile? initial;
  final bool migration;
  final VoidCallback? onDone, onLater;
  const ProfileFlow({
    super.key,
    this.initial,
    this.migration = false,
    this.onDone,
    this.onLater,
  });

  @override
  State<ProfileFlow> createState() => _ProfileFlowState();
}

class _ProfileFlowState extends State<ProfileFlow> {
  int _step = 0;
  bool _minor = false;

  late final UserProfile _base;
  final _year = TextEditingController();
  final _weight = TextEditingController();
  bool? _adult18; // 18 ans cette année : déjà eu 18 ans ?

  String _primary = 'health';
  String? _secondary;
  int _goalWeight = 70;
  DateTime? _eventDate;
  final Map<String, TextEditingController> _targets = {};

  final Set<int> _days = {};
  int? _minutes;
  final Map<String, Set<String>> _places = {};
  final Map<int, String> _dayPlace = {};
  final Map<String, int> _bench = {};

  String? _consent;
  final Map<String, bool> _answers = {};
  final List<Injury> _injuries = [];

  String _autonomy = 'guided';
  String _tone = 'kind';
  bool _modeTouched = false;

  bool get _editing => widget.initial != null && !widget.migration;

  @override
  void initState() {
    super.initState();
    _base = widget.initial?.copy() ?? store.newProfileDraft();
    final p = _base;
    final by = p.intValue('birthYear');
    if (by != null) _year.text = '$by';
    final bw = store.currentBodyweight;
    if (bw != null) _weight.text = _num(bw);
    _primary = p.stringValue('goalPrimary') ?? 'health';
    _secondary = p.stringValue('goalSecondary');
    _goalWeight = p.intValue('goalWeight') ?? 70;
    final ev = p.value('eventGoal') as Map?;
    if (ev != null) {
      _eventDate = DateTime.tryParse(ev['date'] as String);
      for (final i in ev['items'] as List) {
        final t = (i as Map)['target'] as num?;
        _targets[i['id'] as String] = TextEditingController(
          text: t == null ? '' : _num(t.toDouble()),
        );
      }
    }
    _days.addAll(p.listValueInts('days'));
    _minutes = p.intValue('sessionMinutes');
    final places = p.value('places') as Map?;
    places?.forEach(
      (k, v) => _places[k as String] = {...(v as List).cast<String>()},
    );
    final dp = p.value('dayPlace') as Map?;
    dp?.forEach((k, v) => _dayPlace[int.parse('$k')] = v as String);
    _bench.addAll(p.benchmarks);
    _consent = p.health.consent == 'given' ? 'given' : p.health.consent;
    if (_consent == 'withdrawn') _consent = 'refused';
    _answers.addAll(p.health.answers);
    _injuries.addAll(p.health.injuries);
    _autonomy = p.stringValue('autonomy') ?? 'guided';
    _tone = p.stringValue('tone') ?? 'kind';
    _modeTouched = p.fields.containsKey('autonomy');
    if (_editing) _step = 1;
  }

  @override
  void dispose() {
    _year.dispose();
    _weight.dispose();
    for (final c in _targets.values) {
      c.dispose();
    }
    super.dispose();
  }

  static String _num(double v) =>
      v == v.roundToDouble()
          ? v.toInt().toString()
          : v.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');

  DateTime get _now => store.storeClock();
  int? get _birthYear => int.tryParse(_year.text.trim());
  int? get _age => _birthYear == null ? null : _now.year - _birthYear!;

  bool get _hasEvent => _primary == 'event' || _secondary == 'event';

  double? get _weightValue {
    final t = _weight.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    return v == null || v < 20 || v > 400 ? double.nan : v;
  }

  String? _stepError() {
    switch (kFlowSteps[_step]) {
      case 'age':
        final by = _birthYear;
        if (by == null || by < 1900 || by > _now.year) {
          return 'Indique ton année de naissance (4 chiffres).';
        }
        if (_age == 18 && _adult18 == null) {
          return 'Indique si tu as déjà eu 18 ans.';
        }
        final w = _weightValue;
        if (w != null && w.isNaN) return 'Poids entre 20 et 400 kg.';
        return null;
      case 'goals':
        if (_hasEvent) {
          if (_eventDate == null) return 'Choisis la date de l’épreuve.';
          if (_targets.isEmpty) return 'Choisis au moins une épreuve.';
          for (final c in _targets.values) {
            final t = c.text.trim().replaceAll(',', '.');
            if (t.isNotEmpty && (double.tryParse(t) ?? -1) < 0) {
              return 'Cible invalide.';
            }
          }
        }
        return null;
      case 'availability':
        if (_days.isEmpty) return 'Choisis au moins un jour.';
        if (_minutes == null) return 'Choisis une durée par séance.';
        return null;
      case 'places':
        if (_places.isEmpty) return 'Choisis au moins un lieu.';
        return null;
      case 'level':
        if (!_bench.containsKey('pushups')) {
          return 'Réponds à la question sur les pompes.';
        }
        return null;
      case 'health':
        if (_consent == null) return 'Choisis « J’accepte » ou « Je refuse ».';
        return null;
    }
    return null;
  }

  bool get _isMinor {
    final a = _age;
    return a != null && (a < 18 || (a == 18 && _adult18 == false));
  }

  void _next() {
    final err = _stepError();
    if (err != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (kFlowSteps[_step] == 'age' && _isMinor) {
      // Aucune donnée enregistrée : le brouillon reste en mémoire.
      setState(() => _minor = true);
      return;
    }
    if (kFlowSteps[_step] == 'level' && !_modeTouched) {
      final d = defaultsForLevel(levelFromBenchmarks(_bench));
      _autonomy = d.autonomy;
      _tone = d.tone;
    }
    if (kFlowSteps[_step] == 'recap') {
      _save();
      return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_minor) {
      setState(() => _minor = false);
    } else if (_step > (_editing ? 1 : 0)) {
      setState(() => _step--);
    } else if (_editing) {
      Navigator.of(context).maybePop();
    }
  }

  /// Construit le profil final ; conserve la source (estimée, mesurée) des
  /// valeurs pré-remplies que l'utilisateur n'a pas modifiées.
  UserProfile _build() {
    final at = profileAt(_now);
    final p = _base.copy();
    void put(String key, Object? v) {
      final old = _base.fields[key];
      if (v == null) {
        p.fields.remove(key);
      } else if (old != null && _sameJson(old.value, v)) {
        p.fields[key] = old;
      } else {
        p.setField(key, v, at);
      }
    }

    // Santé d'abord : les champs de santé dépendent du consentement.
    final h = p.health;
    if (_consent != h.consent &&
        !(h.consent == 'withdrawn' && _consent == 'refused')) {
      h
        ..consent = _consent
        ..consentAt = at;
    }
    if (h.consentGiven) {
      final complete = kHealthQuestions.every(
        (q) => _answers.containsKey(q.id),
      );
      final changed =
          _answers.length != h.answers.length ||
          _answers.entries.any((e) => h.answers[e.key] != e.value);
      if (changed) {
        h.answers
          ..clear()
          ..addAll(_answers);
        h.answeredAt = _answers.isEmpty ? null : at;
      }
      if (!complete && _answers.isEmpty) h.answeredAt = null;
      h.injuries
        ..clear()
        ..addAll(_injuries);
    } else {
      h.clearContent();
      for (final k in kHealthFields) {
        p.fields.remove(k);
      }
    }
    put('birthYear', _birthYear);
    put('goalPrimary', _primary);
    put('goalSecondary', _secondary);
    put('goalWeight', _secondary == null ? null : _goalWeight);
    put(
      'eventGoal',
      !_hasEvent
          ? null
          : {
            'date': profileDay(_eventDate!),
            'items': [
              for (final e in kEventItems)
                if (_targets.containsKey(e.$1))
                  {
                    'id': e.$1,
                    if (double.tryParse(
                          _targets[e.$1]!.text.trim().replaceAll(',', '.'),
                        )
                        case final t?)
                      'target': t,
                  },
            ],
          },
    );
    put('days', _days.toList()..sort());
    put('sessionMinutes', _minutes);
    put('places', {
      for (final pl in kPlaces)
        if (_places.containsKey(pl.$1))
          pl.$1: [
            for (final e in kEquipment)
              if (_places[pl.$1]!.contains(e.$1)) e.$1,
          ],
    });
    put('dayPlace', {
      for (final d in _days.toList()..sort()) '$d': _placeFor(d),
    });
    put('benchmarks', Map<String, int>.of(_bench));
    put('autonomy', _autonomy);
    put('tone', _tone);
    return p;
  }

  String _placeFor(int day) {
    final chosen = _dayPlace[day];
    if (chosen != null && _places.containsKey(chosen)) return chosen;
    for (final p in kPlaces) {
      if (_places.containsKey(p.$1)) return p.$1;
    }
    return 'home_none';
  }

  void _save() {
    final p = _build();
    final w = _weightValue;
    final before = store.currentBodyweight;
    store.saveProfile(p);
    if (w != null &&
        !w.isNaN &&
        (before == null || (w - before).abs() > 1e-9)) {
      store.addWeighIn(_now, w);
    }
    if (_editing) {
      Navigator.of(context).maybePop(true);
    }
    widget.onDone?.call();
  }

  // ------------------------------------------------------------ écrans

  @override
  Widget build(BuildContext context) {
    final name = kFlowSteps[_step];
    final title =
        _minor
            ? 'RÉSERVÉE AUX ADULTES'
            : switch (name) {
              'welcome' => widget.migration ? 'TON PROFIL' : 'BIENVENUE',
              'age' => 'ÂGE ET POIDS',
              'goals' => 'OBJECTIFS',
              'availability' => 'DISPONIBILITÉS',
              'places' => 'LIEUX ET MATÉRIEL',
              'level' => 'REPÈRE DE NIVEAU',
              'health' => 'SANTÉ',
              'mode' => 'MODE ET TON',
              _ => 'RÉCAPITULATIF',
            };
    final canBack = _minor || _step > (_editing ? 1 : 0) || _editing;
    return PopScope(
      canPop: _editing && _step <= 1 && !_minor,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: KScreen(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading:
              canBack
                  ? IconButton(
                    key: const ValueKey('flow-back'),
                    tooltip: 'Retour',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _back,
                  )
                  : null,
          title: Text(title),
        ),
        body: KList(
          key: ValueKey('flow-${_minor ? 'minor' : name}'),
          children: [
            if (!_minor && _step > 0)
              Semantics(
                label: 'Étape $_step sur ${kFlowSteps.length - 1}',
                child: ExcludeSemantics(
                  child: LinearProgressIndicator(
                    value: _step / (kFlowSteps.length - 1),
                  ),
                ),
              ),
            ...(_minor ? _minorStep() : _stepBody(name)),
            if (!_minor) _actions(name),
            // L13 (KT-074) : avertissement dès le premier écran, sous
            // l'action pour ne pas repousser « Commencer ».
            if (!_minor && name == 'welcome') const DisclaimerCard(),
          ],
        ),
      ),
    );
  }

  Widget _actions(String name) {
    final label = switch (name) {
      'welcome' => widget.migration ? 'Vérifier mon profil' : 'Commencer',
      'recap' =>
        widget.migration
            ? 'Confirmer mon profil'
            : _editing
            ? 'Enregistrer'
            : 'C’est parti',
      _ => 'Continuer',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          key: ValueKey('flow-next-$name'),
          onPressed: _next,
          child: Text(label),
        ),
        if (name == 'welcome' && widget.onLater != null) ...[
          const SizedBox(height: 8),
          TextButton(
            key: const ValueKey('flow-later'),
            onPressed: widget.onLater,
            child: const Text('Plus tard'),
          ),
        ],
      ],
    );
  }

  List<Widget> _minorStep() => [
    KCard(
      key: const ValueKey('minor-message'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: SL.accent),
          const SizedBox(height: 8),
          const Text(
            'Kalis Track est réservée aux personnes de 18 ans et plus. '
            'Merci de ton intérêt : l’entraînement des plus jeunes mérite un '
            'accompagnement adapté, par exemple dans un club.',
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune donnée n’a été enregistrée.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
    OutlinedButton(
      key: const ValueKey('minor-back'),
      onPressed: _back,
      child: const Text('Corriger mon année de naissance'),
    ),
  ];

  Widget _title(String t) =>
      Text(t, style: Theme.of(context).textTheme.titleMedium);
  Widget _hint(String t) =>
      Text(t, style: Theme.of(context).textTheme.bodySmall);

  Widget _chips<T>({
    required String keyPrefix,
    required List<(T, String)> options,
    required bool Function(T) selected,
    required void Function(T, bool) onSelected,
    bool multi = false,
  }) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final o in options)
        multi
            ? FilterChip(
              key: ValueKey('$keyPrefix-${o.$1}'),
              label: Text(o.$2),
              selected: selected(o.$1),
              onSelected: (v) => setState(() => onSelected(o.$1, v)),
            )
            : ChoiceChip(
              key: ValueKey('$keyPrefix-${o.$1}'),
              label: Text(o.$2),
              selected: selected(o.$1),
              onSelected: (v) => setState(() => onSelected(o.$1, v)),
            ),
    ],
  );

  List<Widget> _stepBody(String name) => switch (name) {
    'welcome' => _welcome(),
    'age' => _ageStep(),
    'goals' => _goalsStep(),
    'availability' => _availabilityStep(),
    'places' => _placesStep(),
    'level' => _levelStep(),
    'health' => _healthStep(),
    'mode' => _modeStep(),
    _ => _recapStep(),
  };

  List<Widget> _welcome() => [
    KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.fitness_center, color: SL.accent),
          const SizedBox(height: 8),
          if (widget.migration) ...[
            _title('Ton profil est pré-rempli'),
            const SizedBox(height: 6),
            const Text(
              'À partir de ta feuille Pilotage, de tes objectifs, de ton '
              'programme de 40 semaines et de ton historique. Vérifie-le en '
              'quelques écrans. Aucune date, aucune valeur et aucune séance '
              'de ton historique ne sera modifiée.',
            ),
          ] else ...[
            _title('Un programme à ta mesure'),
            const SizedBox(height: 6),
            const Text(
              'Quelques questions (2 minutes au plus) pour adapter ton '
              'entraînement. Tout reste sur ce téléphone : ni compte, ni '
              'publicité. Les autres informations te seront demandées plus '
              'tard, une à la fois, à la fin d’une séance.',
            ),
          ],
        ],
      ),
    ),
  ];

  List<Widget> _ageStep() {
    final age = _age;
    return [
      KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('Ton année de naissance'),
            const SizedBox(height: 4),
            _hint('L’application est réservée aux 18 ans et plus.'),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('flow-year'),
              controller: _year,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Année (ex. 1990)',
                counterText: '',
              ),
              onChanged:
                  (_) => setState(() {
                    _adult18 = null;
                  }),
            ),
            if (age == 18) ...[
              const SizedBox(height: 8),
              _hint('As-tu déjà fêté tes 18 ans ?'),
              const SizedBox(height: 6),
              _chips<bool>(
                keyPrefix: 'flow-adult18',
                options: const [(true, 'Oui'), (false, 'Pas encore')],
                selected: (v) => _adult18 == v,
                onSelected: (v, _) => _adult18 = v,
              ),
            ],
          ],
        ),
      ),
      KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('Ton poids (facultatif)'),
            const SizedBox(height: 4),
            _hint(
              'Sert au calcul des exercices lestés (poids du corps + lest). '
              'Modifiable à tout moment dans Pesées.',
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('flow-weight'),
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Poids (kg)'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _goalsStep() {
    final active = [
      for (final g in kGoals)
        if (g.active) (g.id, g.label),
    ];
    return [
      KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('Objectif principal'),
            const SizedBox(height: 8),
            _chips<String>(
              keyPrefix: 'flow-goal',
              options: active,
              selected: (id) => _primary == id,
              onSelected: (id, _) {
                _primary = id;
                if (_secondary == id) _secondary = null;
              },
            ),
          ],
        ),
      ),
      KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('Objectif secondaire (facultatif)'),
            const SizedBox(height: 8),
            _chips<String>(
              keyPrefix: 'flow-goal2',
              options: [
                for (final o in active)
                  if (o.$1 != _primary) o,
              ],
              selected: (id) => _secondary == id,
              onSelected: (id, v) => _secondary = v ? id : null,
            ),
            if (_secondary != null) ...[
              const SizedBox(height: 10),
              _hint('Répartition : $_goalWeight / ${100 - _goalWeight}'),
              Row(
                children: [
                  IconButton(
                    key: const ValueKey('flow-weight-minus'),
                    tooltip: 'Moins pour l’objectif principal',
                    onPressed:
                        _goalWeight > 50
                            ? () => setState(() => _goalWeight -= 10)
                            : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Text(
                      '$_goalWeight % principal · ${100 - _goalWeight} % secondaire',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('flow-weight-plus'),
                    tooltip: 'Plus pour l’objectif principal',
                    onPressed:
                        _goalWeight < 90
                            ? () => setState(() => _goalWeight += 10)
                            : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      if (_hasEvent) _eventCard(),
    ];
  }

  Widget _eventCard() => KCard(
    key: const ValueKey('flow-event'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Épreuves, cibles et date'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('flow-event-date'),
          icon: const Icon(Icons.event_rounded),
          label: Text(
            _eventDate == null
                ? 'Choisir la date'
                : 'Le ${longCivilDate(_eventDate!)}',
          ),
          onPressed: () async {
            final now = _now;
            final d = await showDatePicker(
              context: context,
              initialDate: _eventDate ?? now.add(const Duration(days: 90)),
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 5),
            );
            if (d != null) setState(() => _eventDate = d);
          },
        ),
        const SizedBox(height: 8),
        _chips<String>(
          keyPrefix: 'flow-event-item',
          multi: true,
          options: [for (final e in kEventItems) (e.$1, e.$2)],
          selected: _targets.containsKey,
          onSelected: (id, v) {
            if (v) {
              _targets[id] = TextEditingController();
            } else {
              _targets.remove(id)?.dispose();
            }
          },
        ),
        for (final e in kEventItems)
          if (_targets.containsKey(e.$1))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                key: ValueKey('flow-target-${e.$1}'),
                controller: _targets[e.$1],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: '${e.$2} : cible (${e.$3}, facultatif)',
                ),
              ),
            ),
      ],
    ),
  );

  List<Widget> _availabilityStep() => [
    KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Jours où tu peux t’entraîner'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var d = 1; d <= 7; d++)
                Semantics(
                  label: kWeekdayLong[d - 1],
                  excludeSemantics: true,
                  selected: _days.contains(d),
                  button: true,
                  child: FilterChip(
                    key: ValueKey('flow-day-$d'),
                    showCheckmark: false,
                    label: Text(kWeekdayShort[d - 1]),
                    selected: _days.contains(d),
                    onSelected:
                        (v) =>
                            setState(() => v ? _days.add(d) : _days.remove(d)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          _hint(
            _days.isEmpty
                ? 'Aucun jour choisi'
                : '${_days.length} jour${_days.length > 1 ? 's' : ''} : '
                    '${(_days.toList()..sort()).map((d) => kWeekdayLong[d - 1]).join(', ')}',
          ),
        ],
      ),
    ),
    KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Durée par séance'),
          const SizedBox(height: 8),
          _chips<int>(
            keyPrefix: 'flow-minutes',
            options: const [
              (20, '20 min'),
              (30, '30 min'),
              (45, '45 min'),
              (60, '1 h'),
              (75, '1 h 15'),
              (90, '1 h 30'),
              (120, '2 h'),
            ],
            selected: (m) => _minutes == m,
            onSelected: (m, _) => _minutes = m,
          ),
        ],
      ),
    ),
  ];

  List<Widget> _placesStep() {
    final days = _days.toList()..sort();
    return [
      KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('Où t’entraînes-tu ?'),
            const SizedBox(height: 8),
            _chips<String>(
              keyPrefix: 'flow-place',
              multi: true,
              options: kPlaces,
              selected: _places.containsKey,
              onSelected: (id, v) {
                if (v) {
                  _places[id] = {...?kPlaceDefaults[id]};
                } else {
                  _places.remove(id);
                }
              },
            ),
          ],
        ),
      ),
      for (final pl in kPlaces)
        if (_places.containsKey(pl.$1))
          KCard(
            key: ValueKey('flow-equip-card-${pl.$1}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title('Matériel : ${pl.$2.toLowerCase()}'),
                const SizedBox(height: 8),
                _chips<String>(
                  keyPrefix: 'flow-equip-${pl.$1}',
                  multi: true,
                  options: kEquipment,
                  selected: _places[pl.$1]!.contains,
                  onSelected:
                      (id, v) =>
                          v
                              ? _places[pl.$1]!.add(id)
                              : _places[pl.$1]!.remove(id),
                ),
              ],
            ),
          ),
      if (_places.length > 1 && days.isNotEmpty)
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title('Lieu habituel de chaque jour'),
              for (final d in days)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('flow-dayplace-$d'),
                    isExpanded: true,
                    value: _placeFor(d),
                    decoration: InputDecoration(
                      labelText:
                          kWeekdayLong[d - 1][0].toUpperCase() +
                          kWeekdayLong[d - 1].substring(1),
                    ),
                    items: [
                      for (final pl in kPlaces)
                        if (_places.containsKey(pl.$1))
                          DropdownMenuItem(
                            value: pl.$1,
                            child: Text(pl.$2, overflow: TextOverflow.ellipsis),
                          ),
                    ],
                    onChanged: (v) => setState(() => _dayPlace[d] = v!),
                  ),
                ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _levelStep() => [
    for (final b in kBenchmarks)
      KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(b.question),
            if (b.id != 'pushups') ...[
              const SizedBox(height: 4),
              _hint('Facultatif : laisse vide si tu ne sais pas.'),
            ],
            const SizedBox(height: 8),
            _chips<int>(
              keyPrefix: 'flow-bench-${b.id}',
              options: [
                for (var i = 0; i < b.bands.length; i++) (i, b.bands[i]),
              ],
              selected: (i) => _bench[b.id] == i,
              onSelected: (i, v) => v ? _bench[b.id] = i : _bench.remove(b.id),
            ),
          ],
        ),
      ),
    _hint(
      'Ce repère sert seulement de point de départ : Koach ajustera ensuite '
      'ton niveau mouvement par mouvement.',
    ),
  ];

  List<Widget> _healthStep() {
    final given = _consent == 'given';
    return [
      KCard(
        key: const ValueKey('flow-consent'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('Avant de continuer'),
            const SizedBox(height: 6),
            const Text(kHealthInfo),
            const SizedBox(height: 10),
            _chips<String>(
              keyPrefix: 'flow-consent',
              options: const [('given', 'J’accepte'), ('refused', 'Je refuse')],
              selected: (v) => _consent == v,
              onSelected: (v, _) => _consent = v,
            ),
          ],
        ),
      ),
      if (_consent == 'refused')
        const KCard(
          key: ValueKey('flow-refused'),
          child: Text(
            'D’accord : aucune donnée de santé ne sera enregistrée. '
            '$kCautionAdvice Tu pourras donner ton accord plus tard dans '
            'Réglages → Profil.',
          ),
        ),
      if (given) ...[
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title('Questionnaire d’aptitude'),
              const SizedBox(height: 4),
              _hint(
                'Réponds par oui ou non. Sans réponse, le mode prudent '
                's’applique par défaut.',
              ),
              for (final q in kHealthQuestions) ...[
                const SizedBox(height: 12),
                Text(q.text),
                const SizedBox(height: 6),
                _chips<bool>(
                  keyPrefix: 'flow-q-${q.id}',
                  options: const [(false, 'Non'), (true, 'Oui')],
                  selected: (v) => _answers[q.id] == v,
                  onSelected: (v, _) => _answers[q.id] = v,
                ),
              ],
            ],
          ),
        ),
        _injuriesCard(),
      ],
    ];
  }

  Widget _injuriesCard() => KCard(
    key: const ValueKey('flow-injuries'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Gênes ou limitations (facultatif)'),
        for (var i = 0; i < _injuries.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${labelOf(kZones, _injuries[i].zone)} · gêne ${_injuries[i].level}/10',
            ),
            subtitle: Text('Depuis le ${_injuries[i].since}'),
            trailing: IconButton(
              tooltip: 'Retirer',
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _injuries.removeAt(i)),
            ),
          ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          key: const ValueKey('flow-add-injury'),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une gêne'),
          onPressed: _addInjury,
        ),
      ],
    ),
  );

  Future<void> _addInjury() async {
    var zone = 'shoulder';
    var level = 2.0;
    var since = 1; // 0 : < 1 mois, 1 : 1-6 mois, 2 : > 6 mois
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, set) => SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _title('Zone'),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final z in kZones)
                              ChoiceChip(
                                key: ValueKey('injury-zone-${z.$1}'),
                                label: Text(z.$2),
                                selected: zone == z.$1,
                                onSelected: (_) => set(() => zone = z.$1),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Gêne : ${level.round()}/10'),
                        Slider(
                          key: const ValueKey('injury-level'),
                          value: level,
                          max: 10,
                          divisions: 10,
                          label: '${level.round()}/10',
                          onChanged: (v) => set(() => level = v),
                        ),
                        _title('Depuis'),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final (i, l) in const [
                              (0, 'Moins d’un mois'),
                              (1, '1 à 6 mois'),
                              (2, 'Plus de 6 mois'),
                            ])
                              ChoiceChip(
                                label: Text(l),
                                selected: since == i,
                                onSelected: (_) => set(() => since = i),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          key: const ValueKey('injury-save'),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Ajouter'),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
    if (ok != true || !mounted) return;
    final now = _now;
    final back = [15, 90, 270][since];
    setState(
      () => _injuries.add(
        Injury(
          zone,
          level.round(),
          profileDay(now.subtract(Duration(days: back))),
          profileAt(now),
        ),
      ),
    );
  }

  List<Widget> _modeStep() => [
    KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Mode'),
          const SizedBox(height: 4),
          _hint(
            'Guidé : Koach décide et explique. Assisté : Koach propose, tu '
            'choisis. Expert : tu gardes la main, Koach reste discret.',
          ),
          const SizedBox(height: 8),
          _chips<String>(
            keyPrefix: 'flow-autonomy',
            options: kAutonomy,
            selected: (v) => _autonomy == v,
            onSelected: (v, _) {
              _autonomy = v;
              _modeTouched = true;
            },
          ),
        ],
      ),
    ),
    KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Ton de Koach'),
          const SizedBox(height: 8),
          _chips<String>(
            keyPrefix: 'flow-tone',
            options: kTones,
            selected: (v) => _tone == v,
            onSelected: (v, _) {
              _tone = v;
              _modeTouched = true;
            },
          ),
        ],
      ),
    ),
  ];

  List<Widget> _recapStep() {
    final p = _build();
    final caution = evaluateCaution(p, _now);
    return [
      KCard(
        key: const ValueKey('flow-recap-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final l in profileSummary(p)) _recapLine(l.$1, l.$2)],
        ),
      ),
      CautionCard(status: caution),
      if (widget.migration)
        _hint(
          'Confirmer enregistre seulement ce profil : ton départ, tes '
          'références, tes objectifs Koach et ton historique restent tels '
          'quels.',
        ),
    ];
  }

  Widget _recapLine(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_hint(k), Text(v)],
    ),
  );
}

bool _sameJson(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((k) => b.containsKey(k) && _sameJson(a[k], b[k]));
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameJson(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

extension on UserProfile {
  List<int> listValueInts(String key) =>
      ((fields[key]?.value as List?) ?? const []).cast<int>();
}

/// Lignes lisibles du profil (récapitulatif, écran Profil).
List<(String, String)> profileSummary(UserProfile p) {
  final out = <(String, String)>[];
  final by = p.intValue('birthYear');
  if (by != null) out.add(('Année de naissance', '$by'));
  final g1 = goalById(p.stringValue('goalPrimary'))?.label;
  final g2 = goalById(p.stringValue('goalSecondary'))?.label;
  if (g1 != null) {
    out.add((
      'Objectifs',
      g2 == null
          ? g1
          : '$g1 (${p.intValue('goalWeight') ?? 70} %) · $g2 '
              '(${100 - (p.intValue('goalWeight') ?? 70)} %)',
    ));
  }
  final ev = p.value('eventGoal') as Map?;
  if (ev != null) {
    final items = [
      for (final i in ev['items'] as List)
        '${eventItemLabel((i as Map)['id'] as String)}'
            '${i['target'] == null ? '' : ' → ${_fmt((i['target'] as num).toDouble())} ${eventItemUnit(i['id'] as String)}'}',
    ];
    final d = DateTime.tryParse(ev['date'] as String);
    out.add((
      'Épreuves${d == null ? '' : ' le ${longCivilDate(d)}'}',
      items.join('\n'),
    ));
  }
  final days = ((p.value('days') as List?) ?? const []).cast<int>();
  final mins = p.intValue('sessionMinutes');
  if (days.isNotEmpty || mins != null) {
    out.add((
      'Disponibilités',
      [
        if (days.isNotEmpty) days.map((d) => kWeekdayLong[d - 1]).join(', '),
        if (mins != null) '$mins min par séance',
      ].join(' · '),
    ));
  }
  final places = p.value('places') as Map?;
  if (places != null && places.isNotEmpty) {
    out.add((
      'Lieux et matériel',
      [
        for (final e in places.entries)
          '${placeLabel(e.key as String)} : '
              '${(e.value as List).isEmpty ? 'aucun matériel' : (e.value as List).map((x) => equipmentLabel(x as String)).join(', ')}',
      ].join('\n'),
    ));
  }
  final b = p.benchmarks;
  if (b.isNotEmpty) {
    out.add((
      'Repère de niveau',
      [
        for (final spec in kBenchmarks)
          if (b[spec.id] != null)
            '${spec.id == 'pushups' ? 'Pompes' : 'Tractions'} : ${spec.bands[b[spec.id]!]}',
        'Point de départ : ${kLevelLabels[p.level] ?? '—'}',
      ].join('\n'),
    ));
  }
  final exp = p.stringValue('experience');
  if (exp != null) out.add(('Ancienneté', labelOf(kExperience, exp)));
  out.add((
    'Mode et ton',
    '${labelOf(kAutonomy, p.stringValue('autonomy'))} · '
        '${labelOf(kTones, p.stringValue('tone'))}',
  ));
  final h = p.health;
  out.add((
    'Santé',
    switch (h.consent) {
      'given' =>
        h.complete
            ? 'Accord donné · questionnaire rempli'
                '${h.injuries.isEmpty ? '' : ' · ${h.injuries.length} gêne(s)'}'
            : 'Accord donné · questionnaire sans réponse',
      'withdrawn' => 'Accord retiré',
      _ => 'Pas d’accord : aucune donnée de santé',
    },
  ));
  for (final k in const [
    'liked',
    'disliked',
    'physicalJob',
    'sleep',
    'stress',
    'motivation',
  ]) {
    final v = p.value(k);
    if (v == null) continue;
    out.add((
      kFieldLabels[k]!,
      switch (k) {
        'physicalJob' => v == true ? 'Oui' : 'Non',
        'sleep' => labelOf(kSleep, v as String),
        'stress' => labelOf(kStress, v as String),
        'liked' || 'disliked' => (v as List).join(', '),
        _ => '$v',
      },
    ));
  }
  return out;
}

String _fmt(double v) =>
    v == v.roundToDouble() ? '${v.toInt()}' : '$v'.replaceAll('.', ',');

/// État du mode prudent, raisons et conseil (jamais la couleur seule).
class CautionCard extends StatelessWidget {
  final CautionStatus status;
  final List<Widget> actions;
  const CautionCard({super.key, required this.status, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final on = status.active;
    return KCard(
      key: const ValueKey('caution-card'),
      accent: on ? SL.action : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                on ? Icons.shield_outlined : Icons.check_circle_outline,
                color: on ? SL.accent : SL.success,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  on
                      ? 'Mode prudent activé'
                      : status.cleared
                      ? 'Mode prudent levé (accord du médecin déclaré)'
                      : 'Mode prudent non nécessaire',
                  key: const ValueKey('caution-state'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if (status.reasons.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final r in status.reasons)
              Text('• ${kCautionReasonLabels[r] ?? r}'),
          ],
          if (on) ...[
            const SizedBox(height: 6),
            Text(kCautionAdvice, style: Theme.of(context).textTheme.bodySmall),
          ],
          ...actions,
        ],
      ),
    );
  }
}

/// Réglages → Profil : consultation, modification, santé, historique.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final p = store.profile;
      final dim = Theme.of(context).textTheme.bodySmall;
      return KScreen(
        appBar: AppBar(title: const Text('PROFIL')),
        body: KList(
          children: [
            if (p == null)
              KCard(
                key: const ValueKey('profile-missing'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Aucun profil pour l’instant. Il sert à adapter ton '
                      'entraînement ; rien d’autre ne change.',
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      key: const ValueKey('profile-create'),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder:
                                  (ctx) => ProfileFlow(
                                    initial:
                                        store.needsProfileConfirmation
                                            ? store.ownerDraft()
                                            : null,
                                    migration: store.needsProfileConfirmation,
                                    onDone: () => Navigator.pop(ctx),
                                  ),
                            ),
                          ),
                      child: Text(
                        store.needsProfileConfirmation
                            ? 'Vérifier mon profil pré-rempli'
                            : 'Créer mon profil',
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              KCard(
                key: const ValueKey('profile-summary'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final l in profileSummary(p))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Text(l.$1, style: dim), Text(l.$2)],
                        ),
                      ),
                  ],
                ),
              ),
              FilledButton.icon(
                key: const ValueKey('profile-edit'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Modifier mon profil'),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute<bool>(
                        builder: (_) => ProfileFlow(initial: p.copy()),
                      ),
                    ),
              ),
              CautionCard(
                status: store.caution,
                actions: [
                  if (store.caution.active && store.caution.clearable) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: const ValueKey('profile-clearance'),
                      onPressed: () => _confirmClearance(context),
                      child: const Text('J’ai l’accord de mon médecin'),
                    ),
                  ],
                  if (store.caution.cleared) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Accord déclaré le ${_day(p.health.clearanceAt!)}',
                      style: dim,
                    ),
                    TextButton(
                      key: const ValueKey('profile-clearance-remove'),
                      onPressed: store.removeDoctorClearance,
                      child: const Text('Retirer l’accord déclaré'),
                    ),
                  ],
                ],
              ),
              KCard(
                key: const ValueKey('profile-health'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Données de santé',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(kHealthInfo, style: dim),
                    const SizedBox(height: 8),
                    if (p.health.consentGiven) ...[
                      Text('Accord donné le ${_day(p.health.consentAt!)}'),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        key: const ValueKey('profile-consent-withdraw'),
                        onPressed: () => _confirmWithdraw(context),
                        child: const Text('Retirer mon accord'),
                      ),
                      if (p.health.hasHealthContent ||
                          kHealthFields.any(p.fields.containsKey))
                        TextButton(
                          key: const ValueKey('profile-health-delete'),
                          onPressed: store.deleteHealthData,
                          child: const Text('Supprimer mes réponses de santé'),
                        ),
                    ] else
                      FilledButton(
                        key: const ValueKey('profile-consent-give'),
                        onPressed: () => store.setHealthConsent(true),
                        child: const Text('Donner mon accord'),
                      ),
                  ],
                ),
              ),
              if (p.events.isNotEmpty)
                KCard(
                  key: const ValueKey('profile-events'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profil modifié',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Le programme s’adaptera à ces changements dans une '
                        'prochaine version.',
                        style: dim,
                      ),
                      for (final e in p.events.reversed.take(10))
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${_day(e.at)} : ${e.fields.map((f) => kFieldLabels[f] ?? f).join(', ')}',
                          ),
                        ),
                    ],
                  ),
                ),
              _sources(context, p),
            ],
          ],
        ),
      );
    },
  );

  static String _day(String at) {
    final d = DateTime.tryParse(at);
    return d == null ? at : longCivilDate(d);
  }

  Widget _sources(BuildContext context, UserProfile p) {
    final dim = Theme.of(context).textTheme.bodySmall;
    const names = {
      'declared': 'déclaré',
      'estimated': 'estimé',
      'measured': 'mesuré',
    };
    return KCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Origine des réponses'),
        children: [
          for (final e in p.fields.entries)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${kFieldLabels[e.key] ?? e.key} : ${names[e.value.source]}, '
                  'le ${_day(e.value.at)}',
                  style: dim,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmClearance(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Accord du médecin'),
            content: const Text(
              'Confirme qu’un médecin t’a donné son accord pour t’entraîner '
              'intensément, en connaissant tes réponses. Cette déclaration '
              'est datée ; une nouvelle réponse « oui » ou une nouvelle gêne '
              'remet le mode prudent.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                key: const ValueKey('clearance-confirm'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Je confirme'),
              ),
            ],
          ),
    );
    if (ok == true) store.declareDoctorClearance();
  }

  Future<void> _confirmWithdraw(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Retirer ton accord ?'),
            content: const Text(
              'Tes réponses de santé, tes gênes, ton sommeil et ton stress '
              'seront effacés de ce téléphone. Le mode prudent s’appliquera.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                key: const ValueKey('withdraw-confirm'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Retirer et effacer'),
              ),
            ],
          ),
    );
    if (ok == true) store.setHealthConsent(false);
  }
}

/// Question progressive à la fin d'une séance validée (KT-040) : au plus
/// une, jamais pendant une séance ; « Plus tard » et « Ne plus demander ».
Future<void> showProgressiveQuestion(
  BuildContext context,
  String question,
  String sessionKey,
) async {
  Object? value;
  final text = TextEditingController();
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder:
        (ctx) => StatefulBuilder(
          builder: (ctx, set) {
            Widget chips(List<(Object, String)> options) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in options)
                  ChoiceChip(
                    key: ValueKey('pq-${o.$1}'),
                    label: Text(o.$2),
                    selected: value == o.$1,
                    onSelected: (_) => set(() => value = o.$1),
                  ),
              ],
            );
            final (title, body) = switch (question) {
              'experience' => (
                'Depuis combien de temps t’entraînes-tu ?',
                chips(kExperience),
              ),
              'sleep' => ('Combien dors-tu en général ?', chips(kSleep)),
              'stress' => (
                'Ton niveau de stress en ce moment ?',
                chips(kStress),
              ),
              'physicalJob' => (
                'Ton métier est-il physique ?',
                chips(const [(true, 'Oui'), (false, 'Non')]),
              ),
              'motivation' => (
                'Pourquoi t’entraînes-tu ? (en quelques mots)',
                TextField(
                  key: const ValueKey('pq-text'),
                  controller: text,
                  maxLength: 200,
                ),
              ),
              _ => (
                question == 'liked'
                    ? 'Quels exercices aimes-tu ?'
                    : 'Quels exercices n’aimes-tu pas du tout ?',
                TextField(
                  key: const ValueKey('pq-text'),
                  controller: text,
                  decoration: const InputDecoration(
                    helperText: 'Sépare-les par des virgules',
                  ),
                ),
              ),
            };
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: Column(
                  key: const ValueKey('progressive-question'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Une question de Koach',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(title, style: Theme.of(ctx).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    body,
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const ValueKey('pq-save'),
                      onPressed: () => Navigator.pop(ctx, 'save'),
                      child: const Text('Enregistrer'),
                    ),
                    TextButton(
                      key: const ValueKey('pq-later'),
                      onPressed: () => Navigator.pop(ctx, 'later'),
                      child: const Text('Plus tard'),
                    ),
                    TextButton(
                      key: const ValueKey('pq-never'),
                      onPressed: () => Navigator.pop(ctx, 'never'),
                      child: const Text('Ne plus demander'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
  );
  final raw = text.text.trim();
  text.dispose();
  if (question == 'motivation' && raw.isNotEmpty) value = raw;
  if ((question == 'liked' || question == 'disliked') && raw.isNotEmpty) {
    value =
        [
          for (final s in raw.split(','))
            if (s.trim().isNotEmpty)
              s.trim().length > 60 ? s.trim().substring(0, 60) : s.trim(),
        ].take(30).toList();
  }
  if (result == 'never') {
    store.answerProgressive(question, sessionKey, never: true);
  } else if (result == 'save' && value != null) {
    store.answerProgressive(question, sessionKey, value: value);
  } else {
    // Fermée, « Plus tard » ou rien de choisi : reportée.
    store.answerProgressive(question, sessionKey, later: true);
  }
}
