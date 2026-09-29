# -*- coding: utf-8 -*-
"""M7 : import des animations Mixamo du propriétaire, clips compressés,
registre et mannequin animable (tools/anatomy/import_animations.py,
build_animated.py, debug_animation.py). Sans Blender ni clé : les FBX sont
remplacés par leurs matrices d'os (ce que `read_fbx` en extrait)."""
import json
import math
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
sys.path.insert(0, str(ROOT / 'tools/anatomy'))

try:
    import numpy as np
except ImportError:  # CI sans numpy : décodage, registre et documentation
    np = None

import build_animated  # noqa: E402
import import_animations as ia  # noqa: E402

needs_numpy = unittest.skipIf(np is None, 'numpy requis (fabrication des clips)')


def fake_fbx(motion, prefix='mixamorig:', fps=30):
    """Données d'un FBX « Without Skin » tel que `read_fbx` les rend, pour
    un mouvement donné (repères d'os du personnage)."""
    skel = ia.load_skeleton()
    axes = {b['nom']: np.array(b['axes']).T for b in skel['os']}
    names = [prefix + b for b in motion.bones]
    parents = [prefix + p if p else None for p in motion.parents]
    rest = []
    for i, b in enumerate(motion.bones):
        m = np.eye(4)
        m[:3, :3] = axes[b]
        m[:3, 3] = motion.heads[i]
        rest.append(m)
    world = []
    for f in range(motion.frames):
        R, P = motion.globals(f)
        frame = []
        for i, b in enumerate(motion.bones):
            m = np.eye(4)
            m[:3, :3] = R[i] @ axes[b] * .01   # échelle de l'armature (cm)
            m[:3, 3] = P[i]
            frame.append(m)
        world.append(frame)
    return {'names': names, 'parents': parents, 'fps': fps, 'frames': (1, motion.frames),
            'rest': np.array(rest), 'world': np.array(world), 'meshes': 0}


def wave_motion(frames=91, fps=30):
    """Mouvement de test : flexion des genoux et des hanches, bras levés,
    bassin qui descend et remonte (sinus), plus une dérive horizontale."""
    _, bones, parents, heads = ia.skeleton_motion_base()
    local = np.zeros((frames, len(bones), 4))
    local[:, :, 3] = 1
    root = np.zeros((frames, 3))
    idx = {b: i for i, b in enumerate(bones)}
    for f in range(frames):
        s = math.sin(math.pi * f / (frames - 1))
        for side, sign in (('Left', 1), ('Right', -1)):
            for bone, axis, deg in ((side + 'UpLeg', (1, 0, 0), -80 * s),
                                    (side + 'Leg', (1, 0, 0), 100 * s),
                                    (side + 'Arm', (0, 1, 0), -sign * 70 * s)):
                local[f, idx[bone]] = ia.mat_to_quat(ia.axis_angle(axis, deg))
        root[f] = (0.004 * f, -.4 * s, .1 * f / frames)
    return ia.Motion(bones, parents, heads, fps, local, root)


@needs_numpy
class QuaternionTest(unittest.TestCase):
    def test_trois_plus_petites(self):
        rng = np.random.default_rng(7)
        for _ in range(200):
            q = rng.normal(size=4)
            q /= np.linalg.norm(q)
            i, vals = ia.encode_quat(q)
            back = ia.decode_quat(i, vals)
            self.assertLess(ia.angle_deg(q, back), .01)

    def test_matrice_aller_retour(self):
        R = ia.axis_angle((1, 2, 3), 73)
        self.assertTrue(np.allclose(ia.quat_to_mat(ia.mat_to_quat(R)), R, atol=1e-9))


@needs_numpy
class ImportTest(unittest.TestCase):
    def test_fichier_valide(self):
        """FBX valide : squelette accepté, rotations retrouvées, clip ≤ 5 Ko
        fidèle au mouvement."""
        m = wave_motion()
        fbx = fake_fbx(m)
        self.assertTrue(ia.check_skeleton(fbx, 'test.fbx'))
        got = ia.fbx_motion(fbx)
        err = max(ia.angle_deg(got.local[f, i], m.local[f, i])
                  for f in range(0, m.frames, 3) for i in range(len(m.bones)))
        self.assertLess(err, .01)
        self.assertLess(np.abs(got.root - m.root).max(), 1e-6)
        data, stats = ia.encode_clip(got)
        self.assertLessEqual(len(data), ia.CLIP_BUDGET)
        fps, frames, dl, dr = ia.decode_clip(data, got.bones)
        self.assertEqual((fps, frames), (30, m.frames))
        rot, pos = ia.max_error(got, dl, dr)
        self.assertLessEqual(rot, ia.TOLERANCE_DEG + .02)
        self.assertLess(pos, .01)
        # os au repos toute l'animation : aucune piste
        self.assertLess(stats['pistes'], 20)

    def test_prefixe_mixamorig1(self):
        m = wave_motion(frames=11)
        self.assertTrue(ia.check_skeleton(fake_fbx(m, prefix='mixamorig1:'), 'x.fbx'))

    def test_squelette_incompatible(self):
        m = wave_motion(frames=5)
        fbx = fake_fbx(m)
        # os absent
        bad = dict(fbx, names=fbx['names'][:-1], parents=fbx['parents'][:-1],
                   rest=fbx['rest'][:-1])
        with self.assertRaisesRegex(ia.ImportErreur, 'squelette incompatible'):
            ia.check_skeleton(bad, 'autre.fbx')
        # hiérarchie différente
        parents = list(fbx['parents'])
        parents[m.bones.index('LeftForeArm')] = 'mixamorig:Spine'
        with self.assertRaisesRegex(ia.ImportErreur, 'hiérarchie'):
            ia.check_skeleton(dict(fbx, parents=parents), 'autre.fbx')
        # proportions d'un autre personnage
        rest = fbx['rest'].copy()
        rest[:, :3, 3] *= 1.2
        with self.assertRaisesRegex(ia.ImportErreur, 'proportions'):
            ia.check_skeleton(dict(fbx, rest=rest), 'autre.fbx')

    def test_derive_retiree(self):
        m = wave_motion()
        before = m.root.copy()
        drift = ia.remove_root_drift(m)
        self.assertGreater(drift, .1)
        self.assertLess(abs(m.root[-1, 0] - m.root[0, 0]), 1e-9)
        self.assertLess(abs(m.root[-1, 2] - m.root[0, 2]), 1e-9)
        # la descente du bassin (verticale) est gardée
        self.assertTrue(np.allclose(m.root[:, 1], before[:, 1]))

    def test_reechantillonnage(self):
        m = wave_motion(frames=61, fps=60)
        r = ia.resample(m, 30)
        self.assertEqual(r.fps, 30)
        self.assertEqual(r.frames, 31)
        self.assertLess(ia.angle_deg(r.local[15, m.bones.index('LeftLeg')],
                                     m.local[30, m.bones.index('LeftLeg')]), 1e-6)

    def test_phases_detectees(self):
        m = wave_motion(frames=121)
        phases = ia.detect_phases(m)
        kinds = [p['type'] for p in phases]
        self.assertIn('excentrique', kinds)
        self.assertIn('concentrique', kinds)
        self.assertLess(kinds.index('excentrique'), kinds.index('concentrique'))
        ia.check_phases(phases, m.duration)
        with self.assertRaises(ia.ImportErreur):
            ia.check_phases([{'type': 'excentrique', 'debut_s': 0, 'fin_s': 1}], m.duration)


class RegistreTest(unittest.TestCase):
    def test_nom_inconnu(self):
        with self.assertRaisesRegex(ia.ImportErreur, 'nom inconnu'):
            ia.deposit([ROOT / 'pas-un-exercice-du-pack.fbx'], log=lambda *_: None)
        with self.assertRaisesRegex(ia.ImportErreur, r'\.fbx est attendu'):
            ia.deposit([ROOT / 'back-squat.bvh'], log=lambda *_: None)

    def test_registre_et_clips(self):
        index = ia.verify(log=lambda *_: None)
        self.assertTrue(index['clips'])
        for c in index['clips']:
            self.assertLessEqual(c['octets'], ia.CLIP_BUDGET, c['id'])
            self.assertEqual(c['fps'], 30)
            ia.check_phases(c['phases'], c['duree_s'])

    def test_animation_de_test(self):
        index = ia.load_index()
        debug = [c for c in index['clips'] if c['debogage']]
        self.assertEqual(len(debug), 1)
        c = debug[0]
        self.assertEqual(c['id'], 'debug_squat')
        self.assertEqual(c['exercices'], [])   # jamais sur une fiche
        self.assertEqual([(p['nom'], p['type'], p['fin_s'] - p['debut_s']) for p in c['phases']],
                         [('Descente', 'excentrique', 3), ('Pause basse', 'isometrique', 1),
                          ('Montée', 'concentrique', 1), ('Pause haute', 'isometrique', 1)])
        pack = ia.pack_exercises()
        self.assertIn('squat-au-poids-de-corps', pack)
        muscles = set(sum(c['muscles'].values(), []))
        atlas = (ROOT / 'lib/atlas_data.dart').read_text(encoding='utf-8')
        for m in muscles:
            self.assertIn(f"'{m}':", atlas, m)
        rig = json.loads(ia.RIG.read_text(encoding='utf-8'))
        fps, frames, local, root = ia.decode_clip((ROOT / c['fichier']).read_bytes(),
                                                  [b['nom'] for b in rig['os']])
        self.assertEqual(frames, 181)
        # boucle : première et dernière image identiques
        self.assertLess(max(ia.angle_deg(local[0][i], local[-1][i]) for i in range(65)), .3)
        self.assertLess(root[90][1], -.4)   # bassin descendu au plus bas (3 s)
        if np is None:
            return
        # au plus bas (3 s) : bassin descendu de plus de 40 cm, pieds fixes
        m = ia.Motion([b['nom'] for b in rig['os']], [b['parent'] for b in rig['os']],
                      [b['tete'] for b in rig['os']], fps, local, root)
        _, P0 = m.globals(0)
        _, P = m.globals(90)
        hips = m.index['Hips']
        self.assertGreater(P0[hips][1] - P[hips][1], .4)
        for foot in ('LeftFoot', 'RightFoot', 'LeftToeBase', 'RightToeBase'):
            self.assertLess(np.linalg.norm(P[m.index[foot]] - P0[m.index[foot]]), .01, foot)

    def test_mannequin_animable(self):
        self.assertTrue(build_animated.check())

    def test_documentation(self):
        doc = (ROOT / 'docs/ANIMATIONS_PROPRIETAIRE.md').read_text(encoding='utf-8')
        for mot in ('Without Skin', '30', 'Keyframe Reduction', 'back-squat',
                    'traction-pronation'):
            self.assertIn(mot, doc)
        law = (ROOT / 'docs/ANIMATION_3D.md').read_text(encoding='utf-8')
        for mot in ('concentrique', 'excentrique', 'isométri'):
            self.assertIn(mot, law)


if __name__ == '__main__':
    unittest.main()
