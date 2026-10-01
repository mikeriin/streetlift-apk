import 'package:kalis_koach/kalis_koach.dart';
import 'package:test/test.dart';

/// Valeurs longues mais réalistes pour les paramètres (pire cas des bulles).
const Map<String, String> longParams = {
  'remaining': '12',
  'field': 'ton matériel disponible',
  'weeks': '40',
  'exercise': 'Tractions australiennes pronation',
  'replacement': 'Rowing inversé aux anneaux',
  'minutes': '25',
  'done': '14',
  'planned': '20',
  'value': '22 répétitions',
  'feature': 'les objectifs personnels',
};

/// Termes interdits (allégations) : mêmes motifs que tools/check_claims.py
/// (L13), plus les promesses de résultat.
final List<RegExp> forbidden = [
  RegExp(r'\bgu[ée]ri(r|t|son|ssent|sse)?\b', caseSensitive: false),
  RegExp(r'\bsoign(er|e|ent|ez)\b', caseSensitive: false),
  RegExp(r'\btraitements?\b', caseSensitive: false),
  RegExp(r'\bth[ée]rap(ie|ies|eutique|eutiques)\b', caseSensitive: false),
  RegExp(r'\br[ée][ée]ducation\b', caseSensitive: false),
  RegExp(r'\bpr[ée]v(enir|ient|iennent|ention)\s+(des|les)\s+blessures\b',
      caseSensitive: false),
  RegExp(r'\banti[- ]blessures?\b', caseSensitive: false),
  RegExp(r'\bgaranti(e|s|es)?\b', caseSensitive: false),
  RegExp(r'\b(perdre|perte\s+de)\s+(du\s+)?poids\b', caseSensitive: false),
  RegExp(r'\bbr[ûu]l(er|e)\s+(les\s+|la\s+|des\s+)?graisses?\b',
      caseSensitive: false),
  RegExp(r'\b(cliniquement|m[ée]dicalement)\s+(prouv|test|valid|approuv)',
      caseSensitive: false),
  RegExp(r'\bimmunit[ée]\b', caseSensitive: false),
  RegExp(r'\bsoulag(er|e|ent)\b', caseSensitive: false),
  // Promesses de résultat.
  RegExp(r'\btu vas (devenir|gagner|perdre|r[ée]ussir|progresser)\b',
      caseSensitive: false),
  RegExp(r'\b(à coup sûr|résultats? assurés?|100 ?%)\b', caseSensitive: false),
];

/// Diagnostic : seulement sous forme de négation (« aucun diagnostic »).
final RegExp diagnostic = RegExp(r'diagnosti', caseSensitive: false);
final RegExp diagnosticAllowed =
    RegExp(r'(aucun|pas de|ni|sans) diagnostic', caseSensitive: false);

void main() {
  final director = KoachDirector();
  const texts = KoachTexts();

  group('couverture', () {
    test('chaque événement a une règle (sauf « pourquoi », dérivé)', () {
      for (final e in KoachEvent.values) {
        if (e == KoachEvent.why) {
          expect(director.ruleFor(e), isNull);
          continue;
        }
        final r = director.ruleFor(e);
        expect(r, isNotNull, reason: e.name);
        expect(r!.messageKeys, isNotEmpty);
        expect(r.poses, isNotEmpty);
      }
    });

    test('une seule règle par événement', () {
      expect(koachRules.map((r) => r.event).toSet(), hasLength(koachRules.length));
    });

    test('aucune clé orpheline, aucune clé manquante', () {
      final referenced = koachReferencedKeys();
      final library = koachMessagesFr.keys.toSet();
      expect(referenced.difference(library), isEmpty,
          reason: 'clés référencées absentes de la bibliothèque');
      expect(library.difference(referenced), isEmpty,
          reason: 'messages jamais utilisés');
    });

    test('action « Pourquoi ? » si et seulement si une explication existe', () {
      for (final r in koachRules) {
        final hasWhyAction = r.actions.any((a) => a.kind == KoachActionKind.why);
        expect(hasWhyAction, r.whyKey != null, reason: r.event.name);
      }
    });

    test('table des raisons : exemples attendus présents', () {
      expect(director.reasons.codes, containsAll(<String>[
        'load_increased',
        'volume_reduced',
        'exercise_replaced',
        'session_shortened',
        'deload',
        'calibration',
      ]));
    });

    test('table des raisons extensible', () {
      final t = KoachReasonTable.base().extend([
        const KoachReason(
            code: 'rest_day_added',
            proposalKeys: ['proposal.generic.1'],
            appliedKeys: ['applied.generic.1'],
            whyKey: 'why.generic_change',
            poses: [KoachPose.love]),
      ]);
      final d = KoachDirector(reasons: t);
      final line = d.lineFor(const KoachCue(KoachEvent.proposalNew,
          reason: 'rest_day_added'));
      expect(line.pose, KoachPose.love);
      expect(KoachReasonTable.base()['rest_day_added'], isNull);
    });
  });

  group('paramètres', () {
    test('chaque message n’utilise que les paramètres déclarés', () {
      for (final r in koachRules) {
        for (final k in r.messageKeys) {
          expect(texts.placeholders(k), everyElement(isIn(r.params)),
              reason: k);
        }
        if (r.whyKey != null) {
          expect(texts.placeholders(r.whyKey!), everyElement(isIn(r.params)),
              reason: r.whyKey);
        }
      }
      for (final r in koachBaseReasons) {
        for (final k in [...r.proposalKeys, ...r.appliedKeys, r.whyKey]) {
          expect(texts.placeholders(k), everyElement(isIn(r.params)), reason: k);
        }
      }
    });

    test('paramètre manquant refusé', () {
      expect(() => director.lineFor(const KoachCue(KoachEvent.personalRecord)),
          throwsArgumentError);
      expect(
          () => director.lineFor(const KoachCue(KoachEvent.proposalNew,
              reason: 'exercise_replaced', params: {'exercise': 'Dips'})),
          throwsArgumentError);
      expect(() => director.lineFor(const KoachCue(KoachEvent.why)),
          throwsArgumentError);
      expect(
          () => director.lineFor(const KoachCue(KoachEvent.welcome, occurrence: -1)),
          throwsArgumentError);
    });
  });

  group('textes', () {
    test('longueur des bulles, explications et libellés', () {
      for (final e in koachMessagesFr.entries) {
        final text = texts.render(e.key, longParams);
        final max = e.key.startsWith('why.')
            ? koachWhyMaxChars
            : e.key.startsWith('action.')
                ? koachActionMaxChars
                : koachBubbleMaxChars;
        expect(text.length, lessThanOrEqualTo(max), reason: '${e.key} : $text');
        expect(text, isNot(contains('{')), reason: e.key);
        expect(text.trim(), text, reason: 'espaces en trop : ${e.key}');
        expect(text, isNot(contains("'")),
            reason: 'apostrophe typographique attendue : ${e.key}');
        expect(text, isNot(contains('  ')), reason: e.key);
      }
    });

    test('aucune allégation médicale ni promesse de résultat', () {
      for (final e in koachMessagesFr.entries) {
        for (final f in forbidden) {
          expect(f.hasMatch(e.value), isFalse, reason: '${e.key} : ${f.pattern}');
        }
        if (diagnostic.hasMatch(e.value)) {
          expect(diagnosticAllowed.hasMatch(e.value), isTrue, reason: e.key);
        }
      }
    });

    test('tutoiement : jamais de vouvoiement', () {
      final vous = RegExp(r'\b(vous|votre|vos)\b', caseSensitive: false);
      for (final e in koachMessagesFr.entries) {
        expect(vous.hasMatch(e.value), isFalse, reason: e.key);
      }
    });

    test('douleur : renvoi vers un professionnel de santé', () {
      for (final k in director.ruleFor(KoachEvent.healthCheckPain)!.messageKeys) {
        expect(koachMessagesFr[k], contains('professionnel de santé'));
      }
      expect(director.ruleFor(KoachEvent.healthCheckPain)!.priority,
          KoachPriority.safety);
    });
  });

  group('choix', () {
    test('déterministe', () {
      const cue = KoachCue(KoachEvent.personalRecord,
          params: {'exercise': 'Dips', 'value': '15'}, occurrence: 5, seed: 42);
      expect(director.lineFor(cue), director.lineFor(cue));
      expect(KoachDirector().lineFor(cue), director.lineFor(cue));
    });

    test('pas de répétition entre deux occurrences successives', () {
      for (final r in koachRules) {
        if (r.messageKeys.length < 2) continue;
        for (var o = 0; o < 10; o++) {
          final a = director.lineFor(KoachCue(r.event, params: longParams, occurrence: o));
          final b = director.lineFor(KoachCue(r.event, params: longParams, occurrence: o + 1));
          expect(a.messageKey, isNot(b.messageKey), reason: '${r.event.name} $o');
        }
      }
    });

    test('raison connue : messages de la raison ; inconnue : générique', () {
      final known = director.lineFor(const KoachCue(KoachEvent.proposalNew,
          reason: 'deload'));
      expect(known.messageKey, startsWith('reason.deload.proposal.'));
      expect(known.whyKey, 'why.deload');
      final applied = director.lineFor(const KoachCue(KoachEvent.changeApplied,
          reason: 'deload'));
      expect(applied.messageKey, startsWith('reason.deload.applied.'));
      final unknown = director.lineFor(const KoachCue(KoachEvent.proposalNew,
          reason: 'code_futur'));
      expect(unknown.messageKey, startsWith('proposal.generic.'));
      expect(unknown.reason, 'code_futur');
      // Une raison sur un autre événement ne change rien.
      final other = director.lineFor(const KoachCue(KoachEvent.welcome,
          reason: 'deload'));
      expect(other.messageKey, startsWith('welcome.'));
    });

    test('explication « Pourquoi ? »', () {
      final line = director.lineFor(const KoachCue(KoachEvent.proposalNew,
          reason: 'volume_reduced', params: {'exercise': 'Pompes'}));
      final why = director.explain(line)!;
      expect(why.event, KoachEvent.why);
      expect(why.messageKey, 'why.volume_reduced');
      expect(why.priority, KoachPriority.answer);
      expect(texts.bubble(why), koachMessagesFr['why.volume_reduced']);
      expect(texts.why(line), koachMessagesFr['why.volume_reduced']);
      expect(director.explain(director.lineFor(const KoachCue(KoachEvent.error))),
          isNull);
    });

    test('rendu', () {
      final line = director.lineFor(const KoachCue(KoachEvent.personalRecord,
          params: {'exercise': 'Dips', 'value': '15 répétitions'}));
      expect(texts.bubble(line), contains('Dips'));
      expect(texts.bubble(line), contains('15 répétitions'));
      expect(texts.action(KoachActions.why), 'Pourquoi ?');
      expect(() => texts.render('inconnue', const {}), throwsArgumentError);
    });
  });

  group('flammes', () {
    test('10 flammes croissantes, base commune', () {
      var previous = 0;
      for (var l = 1; l <= koachFlameLevels; l++) {
        final f = koachFlame(l);
        expect(f.level, l);
        expect(f.bounds.height, greaterThan(previous), reason: 'flamme $l');
        previous = f.bounds.height;
        expect(f.bounds.bottom, inInclusiveRange(-1, 2));
        expect(f.bounds.centerX.abs(), lessThan(8));
        for (final layer in [f.ink, f.outline, f.hollow]) {
          expect(koachPathStats(layer).allClosed, isTrue);
        }
      }
      expect(koachFlame(10).bounds.height, inInclusiveRange(995, 1002));
      expect(() => koachFlame(0), throwsRangeError);
      expect(() => koachFlame(11), throwsRangeError);
    });

    test('teinte et libellé', () {
      expect(koachFlameTint(1), 0);
      expect(koachFlameTint(10), 1);
      expect(koachFlameTint(4), closeTo(1 / 3, 1e-12));
      expect(koachFlameLabel(7), 'Difficulté 7 sur 10');
      expect(koachFlameFrame.contains(0, -500), isTrue);
    });
  });
}
