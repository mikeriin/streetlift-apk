"""UI0 (refonte UI) : contrôle des jetons (tools/check_ui_tokens.py, cahier UI §6.1)."""
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
_spec = importlib.util.spec_from_file_location('check_ui_tokens', ROOT / 'tools/check_ui_tokens.py')
cut = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(cut)


class ScanTest(unittest.TestCase):
    def test_literals_counted(self):
        code = '''
        Text('a', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: .5));
        Container(color: Color(0xFF123456), padding: const EdgeInsets.fromLTRB(16, 4, 4, 4));
        BoxDecoration(borderRadius: BorderRadius.circular(16));
        Card(child: x); title.toUpperCase();
        '''
        found = cut.scan_text(code)
        for name in ['fontSize', 'fontWeight', 'couleur', 'EdgeInsets', 'rayon', 'Card', 'BoxDecoration', 'toUpperCase']:
            self.assertIn(name, found, name)
        self.assertIn('letterSpacing', found)  # « .5 » sans zéro compte aussi
        self.assertEqual(len(found['EdgeInsets']), 1)

    def test_tokens_comments_and_strings_ignored(self):
        code = '''
        // fontSize: 12, Color(0xFF000000), BorderRadius.circular(8)
        /* EdgeInsets.all(8) */
        final s = 'fontSize: 14 et Card(';
        Padding(padding: const EdgeInsets.all(KSpacing.s8), child: KCard(child: x));
        BorderRadius.circular(KRadius.card); EdgeInsets.zero;
        '''
        self.assertEqual(cut.scan_text(code), {})

    def test_menus_only_with_flag(self):
        code = 'showDialog(context: c); showModalBottomSheet(context: c); PopupMenuButton<int>();'
        self.assertEqual(cut.scan_text(code), {})
        found = cut.scan_text(code, menus=True)
        self.assertEqual(set(found), {'showDialog', 'showModalBottomSheet', 'PopupMenuButton'})

    def test_zones_and_whitelist(self):
        self.assertEqual(cut.zone_of('kit/menus.dart'), 'kit')
        self.assertEqual(cut.zone_of('ui.dart'), 'UI0')
        self.assertEqual(cut.zone_of('home_screen.dart'), 'UI1')
        self.assertEqual(cut.zone_of('adapt/clearance.dart'), 'UI2')
        self.assertEqual(cut.zone_of('stats_overview.dart'), 'UI3')
        self.assertEqual(cut.zone_of('athlete_profile_flow_v3.dart'), 'UI4')
        self.assertEqual(cut.zone_of('muscle_body.dart'), 'liste blanche')
        self.assertEqual(cut.zone_of('dev/dev_widgets.dart'), 'liste blanche')
        self.assertEqual(cut.zone_of('koach/koach_view.dart'), 'liste blanche')
        self.assertEqual(cut.zone_of('koach/koach_bubble.dart'), 'UI1')
        self.assertEqual(cut.zone_of('store.dart'), 'UI5')

    def test_zone_exit_code_and_baseline(self):
        with tempfile.TemporaryDirectory() as tmp:
            lib = Path(tmp) / 'lib'
            (lib / 'kit').mkdir(parents=True)
            (lib / 'kit' / 'tokens.dart').write_text('const x = EdgeInsets.all(8);')
            (lib / 'home_screen.dart').write_text('Text(style: TextStyle(fontSize: 13));')
            (lib / 'ui.dart').write_text('Padding(padding: EdgeInsets.all(KSpacing.s8));')
            base = Path(tmp) / 'depart.json'
            self.assertEqual(cut.main(['--lib', str(lib), '--zone', 'UI0', '--baseline', str(base)]), 0)
            self.assertEqual(cut.main(['--lib', str(lib), '--zone', 'UI1']), 1)
            self.assertEqual(cut.main(['--lib', str(lib), '--zone', 'UI5']), 1)
            self.assertEqual(cut.main(['--lib', str(lib), '--zone', 'UI9']), 2)
            data = json.loads(base.read_text())
            self.assertEqual(data['home_screen.dart']['total'], 1)
            self.assertNotIn('kit/tokens.dart', data)

    def test_shipped_baseline_is_the_base_of_the_redesign(self):
        data = json.loads((ROOT / 'tools/ui_tokens_depart.json').read_text(encoding='utf-8'))
        self.assertEqual(data['ui.dart']['total'], 30)
        self.assertEqual(sum(v['total'] for v in data.values()), 723)

    def test_ui0_zone_is_clean(self):
        self.assertEqual(cut.main(['--zone', 'UI0', '--menus']), 0)


if __name__ == '__main__':
    unittest.main()
