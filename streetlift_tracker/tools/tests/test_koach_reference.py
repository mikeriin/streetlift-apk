"""L7 (KT-035) : référence Python de Koach, fixtures partagées, simulations."""
import copy
import gzip
import json
from pathlib import Path
import re
import sys
import unittest

TOOLS = Path(__file__).resolve().parents[1]
ROOT = TOOLS.parent
sys.path.insert(0, str(TOOLS))
import koach_reference as kr  # noqa: E402
import koach_simulation as ks  # noqa: E402
import koach_annotate as ka  # noqa: E402

FIXTURES = ROOT / 'test' / 'fixtures' / 'koach'


def close(expected, actual, path=''):
    """Égalité profonde, nombres à 0,01 près."""
    if isinstance(expected, (int, float)) and not isinstance(expected, bool):
        assert isinstance(actual, (int, float)) and not isinstance(actual, bool), path
        assert abs(actual - expected) <= 0.01 + 1e-9, '%s : %s ≠ %s' % (path, actual, expected)
    elif isinstance(expected, dict):
        assert isinstance(actual, dict) and set(actual) == set(expected), path
        for k in expected:
            close(expected[k], actual[k], '%s.%s' % (path, k))
    elif isinstance(expected, list):
        assert isinstance(actual, list) and len(actual) == len(expected), path
        for i, (a, b) in enumerate(zip(expected, actual)):
            close(a, b, '%s[%d]' % (path, i))
    else:
        assert actual == expected, '%s : %r ≠ %r' % (path, actual, expected)


class KoachReferenceTests(unittest.TestCase):
    def test_fixtures_expected_outputs_are_current(self):
        files = sorted(FIXTURES.glob('*.json'))
        self.assertGreaterEqual(len(files), 20)
        for path in files:
            case = json.loads(path.read_text(encoding='utf-8'))
            with self.subTest(fixture=path.name):
                close(case['expected'], json.loads(json.dumps(kr.run_case(case))), path.name)

    def test_d24_examples_from_the_request(self):
        def after(kg, rir, body, grid):
            s = kr.in_session(kr.PARAMS, {'bodyweight': body}, [{'kg': kg, 'reps': 4, 'rir': rir}], 2, 4,
                              71.5 if body else None, grid, {})
            return None if s is None else s['kg']
        self.assertEqual((after(32.5, 3, True, 1.25), after(32.5, 4, True, 1.25)), (35.0, 37.5))
        self.assertEqual((after(5.0, 3, True, 1.25), after(5.0, 4, True, 1.25)), (6.25, 8.75))
        self.assertEqual((after(97.5, 3, False, 2.5), after(97.5, 4, False, 2.5)), (100.0, 102.5))
        self.assertIsNone(after(32.5, 2, True, 1.25))

    def test_incremental_cache_equals_full_replay(self):
        case = json.loads((FIXTURES / 'replay_basic.json').read_text(encoding='utf-8'))
        inp = case['input']
        cache = None
        for n in range(1, len(inp['sessions']) + 1):
            part = dict(inp, sessions=inp['sessions'][:n])
            inc = kr.replay_incremental(part, cache)
            cache = inc
            close(kr.summarize(kr.replay(part)), kr.summarize(inc), 'n=%d' % n)
        changed = copy.deepcopy(inp)
        changed['sessions'][0]['exercises'][0]['sets'][0]['reps'] = 5
        close(kr.summarize(kr.replay(changed)), kr.summarize(kr.replay_incremental(changed, cache)), 'correction')

    def test_incremental_cache_follows_context_changes(self):
        # Pesée rétroactive, repère initial ou référence modifiés : les
        # événements sont identiques mais le rejeu complet diffère.
        inp = json.loads((FIXTURES / 'replay_basic.json').read_text(encoding='utf-8'))['input']
        cache = kr.replay(inp)
        heavier = copy.deepcopy(inp)
        heavier['weighIns'][0]['kg'] = 80.0  # pesée du premier jour corrigée
        inc = kr.replay_incremental(heavier, cache)
        close(kr.summarize(kr.replay(heavier)), kr.summarize(inc), 'pesée')
        self.assertNotEqual(kr.summarize(cache), kr.summarize(inc))
        moved = copy.deepcopy(inp)
        moved['history'] = [dict(h, value=h['value'] + 5) if h['source'] == 'initial' else h
                            for h in inp.get('history') or []]
        moved['references'] = dict(inp['references'], B9=inp['references'].get('B9', 0) + 5)
        close(kr.summarize(kr.replay(moved)), kr.summarize(kr.replay_incremental(moved, cache)), 'repère')

    def test_pain_carried_to_next_bilan_and_lb_steps(self):
        # D26 : douleur > 3/10 notée à S3, rien de noté à S4 → aucune hausse
        # au bilan de S4 ; le témoin sans douleur propose une hausse.
        carry = json.loads((FIXTURES / 'pain_carry.json').read_text(encoding='utf-8'))
        control = json.loads((FIXTURES / 'pain_carry_control.json').read_text(encoding='utf-8'))
        up = [p for p in kr.run_case(control)['proposals'] if p['ref'] == 'B8']
        self.assertTrue(up and up[0]['to'] > up[0]['from'])
        self.assertFalse([p for p in kr.run_case(carry)['proposals']
                          if p['ref'] == 'B8' and p['to'] > p['from']])
        # 45 lb enregistrés au centième de kg (20,41) : le cran suivant est
        # 47,5 lb (la progression ne reste pas bloquée).
        eq = kr.DEFAULT_EQUIPMENT
        self.assertAlmostEqual(kr.grid_next(20.41, 'pulley', eq, True), 47.5 * kr.LB_KG, places=6)
        self.assertAlmostEqual(kr.grid_next(31.75, 'pulley', eq, True), 72.5 * kr.LB_KG, places=6)
        self.assertAlmostEqual(kr.grid_next(20.41, 'pulley', eq, False), 42.5 * kr.LB_KG, places=6)

    def test_simulation_criteria(self):
        rep = ks.criteria(n=30)
        for key, (name, v95, vmax, limit) in rep.items():
            with self.subTest(critère=key):
                if key in ('C5', 'C6', 'C7'):
                    self.assertLessEqual(vmax, limit, name)
                else:
                    self.assertLessEqual(v95, limit, name)


class KoachAnnotationTests(unittest.TestCase):
    def setUp(self):
        self.program, self.digest = ka.load_program()
        self.data = json.loads(gzip.decompress(ka.TARGET.read_bytes()))

    def test_shipped_annotations_are_current(self):
        self.assertEqual(ka.encode(ka.annotate(self.program, self.digest)), ka.TARGET.read_bytes())
        self.assertEqual(self.data['source']['sha256'], self.digest)

    def test_rir_target_equals_label_on_every_exercise(self):
        count = 0
        for week in self.program['weeks']:
            for day in week['days']:
                for ex in day['exercises']:
                    count += 1
                    m = re.search(r'RIR\s*(\d)(?:\s*-\s*(\d))?', ex['intensity'])
                    entry = self.data['exercises'].get(ex['id'], {})
                    if m:
                        self.assertEqual(entry.get('rirTarget'), int(m.group(1)), ex['id'])
                        self.assertEqual(entry.get('rirTargetMax'), int(m.group(2)) if m.group(2) else None, ex['id'])
                    else:
                        self.assertNotIn('rirTarget', entry, ex['id'])
        self.assertEqual(count, 1812)  # LC1b : 1 818 − 7 + 1

    def test_curve_prior_and_incoherent_singles_excluded(self):
        self.assertEqual(self.data['curve']['mu']['k'], 28.0)
        for key in ('pull', 'dip', 'squat'):
            self.assertEqual(self.data['curve'][key]['k'], 22.4)
        # « RIR 0 · ~95-97 % » en single : n = 1 = 100 % par définition, écarté.
        self.assertLess(kr.pct(1, 22.4), 1.0000001)

    def test_categories_weeks_and_equipment(self):
        cats = {}
        for e in self.data['exercises'].values():
            if 'cat' in e:
                cats[e['cat']] = cats.get(e['cat'], 0) + 1
        self.assertEqual(cats, {'accessory': 918, 'endurance': 151, 'strength': 136, 'enduranceTest': 19, 'test1rm': 12})
        weeks = self.data['weeks']
        self.assertEqual(sorted(int(n) for n, t in weeks.items() if t == 'deload'), [7, 11, 15, 19, 23, 30, 35])
        self.assertEqual(sorted(int(n) for n, t in weeks.items() if t == 'test'), [1, 2, 12, 25, 31, 39, 40])
        self.assertTrue(self.data['accessories']['B43']['prevention'])
        self.assertEqual(self.data['accessories']['B30']['equipment'], 'dumbbell')
        self.assertEqual(self.data['accessories']['B34']['equipment'], 'pulley')

    def test_programme_asset_untouched(self):
        # Asset LC1 puis LC1b (empreintes vérifiées par test_lc1_revision et test_lc1b_s11_j6).
        raw = gzip.decompress((ROOT / 'assets' / 'programme_v33.json.gz').read_bytes())
        self.assertNotIn(b'rirTarget', raw)


if __name__ == '__main__':
    unittest.main()
