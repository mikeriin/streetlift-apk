# -*- coding: utf-8 -*-
"""M6 (mannequin 3D) : matériel et animations d'exercice, vérifiés sans numpy
ni Blender (bibliothèque standard) : bibliothèque de matériel (éléments,
points de contact, GLB), registre des animations, clips (taille ≤ 5 Ko,
quaternions unitaires, chronologie, phases, vue), contacts rejoués avec la
cinématique du rig (`rig_def.py`) aux images clés ET entre elles, exactement
comme l'application les interpole (sphérique par os, os d'aide recalculés,
translation linéaire)."""
import gzip
import json
import math
import struct
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ANATOMY = ROOT / 'tools' / 'anatomy'
sys.path.insert(0, str(ANATOMY))

import rig_def  # noqa: E402

ASSETS = ROOT / 'assets' / 'anatomy'
CLIPS = ASSETS / 'clips'
EQUIPMENT_JSON = ASSETS / 'equipment.json'
EQUIPMENT_GLB = ASSETS / 'equipment.glb'
RIG = ASSETS / 'rig.json'
FICHES = ANATOMY / 'fiches'
PILOTS = ['traction-pronation', 'dips', 'back-squat']
VIEWS = {'face', 'dos', 'profil', 'troisQuarts'}
EXPECTED_EQUIPMENT = {
    'barre_traction', 'barres_paralleles', 'anneaux', 'banc_plat', 'banc_inclinable',
    'barre_olympique', 'haltere', 'kettlebell', 'elastique', 'box', 'sol',
    'ceinture_lest', 'gilet_lest'}


def slerp(a, b, t):
    d = sum(x * y for x, y in zip(a, b))
    if d < 0:
        b, d = tuple(-x for x in b), -d
    if d > .9995:
        q = tuple(x + (y - x) * t for x, y in zip(a, b))
    else:
        th = math.acos(min(1.0, d))
        s = math.sin(th)
        q = tuple((math.sin((1 - t) * th) * x + math.sin(t * th) * y) / s
                  for x, y in zip(a, b))
    return rig_def.q_normalize(q)


def load_clip(ex_id):
    return json.loads(gzip.decompress((CLIPS / f'{ex_id}.json.gz').read_bytes()))


def posture(clip, i):
    rots = {b: tuple(q) for b, q in zip(clip['os'], clip['postures'][i]['r'])}
    return rots, tuple(clip['postures'][i]['t']), clip['postures'][i].get('m', {})


def blend(clip, a, b, u):
    ra, ta, ma = posture(clip, a)
    rb, tb, mb = posture(clip, b)
    rots = rig_def.with_helpers({k: slerp(ra[k], rb[k], u) for k in ra})
    trans = tuple(x + (y - x) * u for x, y in zip(ta, tb))
    moving = {k: [x + (y - x) * u for x, y in zip(v, mb[k])] for k, v in ma.items()}
    return rots, trans, moving


class EquipmentTest(unittest.TestCase):
    def test_library(self):
        d = json.loads(EQUIPMENT_JSON.read_text(encoding='utf-8'))
        self.assertEqual(set(d['elements']), EXPECTED_EQUIPMENT)
        for item_id, item in d['elements'].items():
            self.assertTrue(item['contacts'], item_id)
            for c in item['contacts']:
                self.assertEqual(len(c['point']), 3)
                if c['type'] == 'axe':
                    self.assertAlmostEqual(math.hypot(*c['axe']), 1, places=3)
        # Dimensions demandées (m).
        e = d['elements']
        self.assertEqual(e['barre_traction']['dimensions']['diametre'], .028)
        self.assertEqual(e['barre_traction']['dimensions']['hauteur_axe'], 2.30)
        self.assertEqual(e['barres_paralleles']['dimensions']['diametre'], .045)
        self.assertEqual(e['barres_paralleles']['dimensions']['ecart_axes'], .55)
        self.assertEqual(e['barres_paralleles']['dimensions']['hauteur_axe'], 1.40)
        self.assertEqual(e['barre_olympique']['dimensions']['longueur'], 2.2)
        self.assertEqual(e['barre_olympique']['dimensions']['diametre_disques'], .45)
        box = e['barre_olympique']['boite']
        self.assertAlmostEqual(box[1][0] - box[0][0], 2.2, places=3)

    def test_glb_nodes(self):
        data = EQUIPMENT_GLB.read_bytes()
        magic, version, length = struct.unpack('<4sII', data[:12])
        self.assertEqual((magic, version, length), (b'glTF', 2, len(data)))
        jlen, _ = struct.unpack('<I4s', data[12:20])
        gltf = json.loads(data[20:20 + jlen])
        roots = {gltf['nodes'][i]['name'] for i in gltf['scenes'][0]['nodes']}
        self.assertEqual(roots, {f'eq_{k}' for k in EXPECTED_EQUIPMENT})
        d = json.loads(EQUIPMENT_JSON.read_text(encoding='utf-8'))
        self.assertEqual(d['octets_glb'], len(data))
        self.assertLess(len(data), 400_000)


class ClipsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.index = json.loads((CLIPS / 'index.json').read_text(encoding='utf-8'))
        cls.rig = json.loads(RIG.read_text(encoding='utf-8'))
        cls.equipment = json.loads(EQUIPMENT_JSON.read_text(encoding='utf-8'))['elements']

    def test_registry(self):
        entries = {e['id']: e for e in self.index['clips']}
        for ex in PILOTS:
            e = entries[ex]
            self.assertEqual(e['statut'], 'valide', ex)
            self.assertEqual(e['fichier'], f'{ex}.json.gz')
            self.assertTrue(all(c['ok'] for c in e['controles'].values()), ex)
            self.assertTrue((FICHES / f'{ex}.json').exists(), ex)
        for e in entries.values():
            if e['statut'] == 'valide':
                self.assertTrue((CLIPS / e['fichier']).exists())

    def test_clip_format(self):
        bones = {b['nom'] for b in self.rig['os']}
        for ex in PILOTS:
            raw = (CLIPS / f'{ex}.json.gz').read_bytes()
            self.assertLessEqual(len(raw), 5 * 1024, ex)
            clip = load_clip(ex)
            self.assertEqual(clip['id'], ex)
            self.assertIn(clip['vue'], VIEWS)
            self.assertTrue(set(clip['os']) <= bones)
            self.assertFalse(any(rig_def.helper_of(b) for b in clip['os']))
            for p in clip['postures']:
                self.assertEqual(len(p['r']), len(clip['os']))
                for q in p['r']:
                    self.assertAlmostEqual(math.sqrt(sum(c * c for c in q)), 1, delta=2e-4)
            times = [t for t, _ in clip['chronologie']]
            self.assertEqual(times[0], 0)
            self.assertEqual(times, sorted(times))
            self.assertLessEqual(times[-1], clip['duree'] + 1e-9)
            # La boucle revient à la posture de départ.
            self.assertEqual(clip['chronologie'][-1][1], clip['chronologie'][0][1])
            ph = clip['phases']
            self.assertEqual(ph[0]['debut'], 0)
            self.assertAlmostEqual(ph[-1]['fin'], clip['duree'])
            for a, b in zip(ph, ph[1:]):
                self.assertAlmostEqual(a['fin'], b['debut'])
            types = {p['type'] for p in ph}
            self.assertTrue({'concentrique', 'excentrique'} <= types, ex)
            for m in clip['materiel']:
                self.assertIn(m['id'], self.equipment)
            self.assertTrue(all(clip['controles'].values()), ex)

    def _check_contacts(self, clip, rots, trans, moving):
        g = rig_def.forward_kinematics(self.rig, rots, trans)
        worst = 0.0
        for c in clip['contacts']:
            # Point local : relatif à la tête de l'os (repère de repos).
            R = [row[:3] for row in g[c['os']]]
            t = [row[3] for row in g[c['os']]]
            p = [sum(R[i][k] * c['point'][k] for k in range(3)) + t[i] for i in range(3)]
            if 'cible' in c:
                target = c['cible']
            else:
                base = moving[c['element']]
                target = [base[i] + c['decalage'][i] for i in range(3)]
            worst = max(worst, math.dist(p, target))
        return worst

    def test_contacts_replayed(self):
        """Contacts à 1 cm sur les postures et entre elles (1/4, 1/2, 3/4)."""
        for ex in PILOTS:
            clip = load_clip(ex)
            self.assertTrue(clip['contacts'], ex)
            worst = 0.0
            for i in range(len(clip['postures'])):
                rots, trans, moving = posture(clip, i)
                worst = max(worst, self._check_contacts(
                    clip, rig_def.with_helpers(rots), trans, moving))
            tl = clip['chronologie']
            for (_, a), (_, b) in zip(tl, tl[1:]):
                if a == b:
                    continue
                for u in (.25, .5, .75):
                    worst = max(worst, self._check_contacts(clip, *blend(clip, a, b, u)))
            self.assertLessEqual(worst, .0101, f'{ex} : {worst * 100:.2f} cm')

    def test_amplitude_and_direction(self):
        """Mouvement ample et dans le bon sens : le bassin monte en
        concentrique et descend en excentrique (tractions, dips, squat)."""
        for ex in PILOTS:
            clip = load_clip(ex)
            tl = clip['chronologie']
            for ph in clip['phases']:
                seg = [i for t, i in tl if ph['debut'] - 1e-9 <= t <= ph['fin'] + 1e-9]
                if ph['type'] == 'isometrique':
                    self.assertEqual(len(set(seg)), 1, (ex, ph['nom']))
                    continue
                y0 = clip['postures'][seg[0]]['t'][1]
                y1 = clip['postures'][seg[-1]]['t'][1]
                want = 1 if ph['type'] == 'concentrique' else -1
                self.assertGreater(want * (y1 - y0), .2, (ex, ph['nom']))


if __name__ == '__main__':
    unittest.main()
