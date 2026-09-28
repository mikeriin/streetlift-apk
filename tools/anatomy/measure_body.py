#!/usr/bin/env python3
"""M56 (mannequin 3D) : mesures anthropométriques du mannequin (numpy, trimesh).

Tours mesurés comme au mètre ruban : périmètre de l'enveloppe convexe de la
section des muscles par un plan horizontal, limitée aux muscles du segment
mesuré (`SEGMENTS` : le bras ne compte pas le grand dorsal qu'il frôle ; les
os, la tête, les mains et les pieds ne comptent pas). Chaque tour est pris au niveau
défini ci-dessous (fraction de la longueur du segment ou hauteur fixe), en
mètres puis en fraction de la taille H du modèle.

Niveaux (repères anatomiques des tours classiques, ISAK) :
- bras : mi-distance acromion (tête humérale) → coude, bras relâché ;
- avant-bras : tour maximal, dans le tiers proximal ;
- poitrine : sous les aisselles (mésosternal), thorax sans les bras ;
- taille : ombilic (plus étroit du tronc entre côtes et crêtes iliaques) ;
- cuisse : sous le pli fessier (maximum de la cuisse entre 9 et 20 cm sous
  la tête fémorale : sans peau ni graisse, le modèle creuse le pli) ;
- mollet : tour maximal ;
- cou : sous la pomme d'Adam (larynx).
- largeur bideltoïdienne : plus grande largeur des deltoïdes ;
- tour d'épaules : périmètre à la hauteur des deltoïdes, bras compris.

Usage : `python3 tools/anatomy/measure_body.py [--glb chemin] [--json sortie]`.
"""
import argparse
import json
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
import rig_pose  # noqa: E402

# Cibles du propriétaire (fraction de H, physique de streetlifting sec,
# ~1,78 m, ~85 kg ; tolérance ± 5 %).
TARGETS = {
    'bras': .22, 'avant_bras': .175, 'poitrine': .62, 'taille': .45,
    'cuisse': .345, 'mollet': .22, 'cou': .22, 'bideltoide': .285,
}
TARGET_SHOULDER_WAIST = 1.55
TOLERANCE = .05
# Le modèle n'a ni peau ni graisse sous-cutanée : ses tours sont ceux de
# l'enveloppe musculaire. Un athlète sec porte ≈ 3 mm de peau et de graisse
# (plis cutanés de 6 à 8 mm, ISAK), soit ≈ 2 cm de tour : les cibles de
# l'enveloppe sont les cibles nominales moins cette épaisseur ; la largeur
# bideltoïdienne garde sa cible nominale (peau mince sur le deltoïde, et le
# propriétaire veut des deltoïdes pleins). Réversible.
SKIN_ALLOWANCE = {'girth': .02, 'width': 0.0}


def envelope_target(key, height):
    """Cible (fraction de H) pour l'enveloppe musculaire du modèle."""
    allowance = SKIN_ALLOWANCE['width' if key == 'bideltoide' else 'girth']
    return TARGETS[key] - allowance / height

# Muscles qui comptent pour chaque tour (clé du muscle dans la carte
# source) : le mètre ruban entoure le segment, pas les muscles voisins qui
# le frôlent (le grand dorsal ne compte pas dans le tour de bras).
ARM = ('biceps_brachii_long', 'biceps_brachii_short', 'brachialis', 'coracobrachialis',
       'triceps_long', 'triceps_lateral', 'triceps_medial', 'deltoid_anterior',
       'deltoid_lateral', 'deltoid_posterior')
FOREARM = ('abductor_pollicis_longus', 'brachioradialis_muscle', 'deep_head_of_pronator_teres',
           'extensor_carpi_radialis_brevis', 'extensor_carpi_radialis_longus',
           'extensor_digiti_minimi', 'extensor_digitorum', 'extensor_indicis',
           'extensor_pollicis_brevis', 'extensor_pollicis_longus', 'flexor_carpi_radialis',
           'flexor_digitorum_profundus', 'flexor_pollicis_longus',
           'humeral_head_of_extensor_carpi_ulnaris', 'humeral_head_of_flexor_carpi_ulnaris',
           'humero_ulnar_head_of_flexor_digitorum_superficialis', 'palmaris_longus_muscle',
           'pronator_quadratus', 'radial_head_of_flexor_digitorum_superficialis',
           'superficial_head_of_pronator_teres', 'supinator', 'ulnar_head_of_extensor_carpi_ulnaris',
           'ulnar_head_of_flexor_carpi_ulnaris', 'anconeus_muscle')
NECK = ('sternocleidomastoid', 'scalenus_anterior', 'scalenus_medius', 'scalenus_posterior',
        'splenius_capitis', 'splenius_colli', 'platysma', 'levator_scapulae',
        'trapezius_lower', 'trapezius_middle')
THIGH = ('rectus_femoris', 'vastus_lateralis', 'vastus_medialis', 'vastus_intermedius',
         'biceps_femoris_long', 'biceps_femoris_short', 'semitendinosus', 'semimembranosus',
         'sartorius', 'gracilis', 'adductor_magnus', 'adductor_longus', 'adductor_brevis',
         'pectineus', 'gluteus_maximus', 'tensor_fasciae_latae', 'iliacus', 'psoas_major')
CALF = ('gastrocnemius_lateral', 'gastrocnemius_medial', 'soleus', 'plantaris',
        'tibialis_anterior', 'tibialis_posterior', 'fibularis_longus', 'fibularis_brevis',
        'fibularis_tertius', 'extensor_digitorum_longus', 'extensor_hallucis_longus',
        'flexor_digitorum_longus', 'flexor_hallucis_longus', 'popliteus')
SEGMENTS = {
    'bras': ARM, 'avant_bras': FOREARM, 'cou': NECK, 'cuisse': THIGH, 'mollet': CALF,
    # Tronc : tout ce qui n'est ni membre ni cou (pectoraux, dos, gainage,
    # coiffe, fessiers hauts…).
    'tronc': None,
}
LIMBS = set(ARM) | set(FOREARM) | set(NECK) | set(THIGH) | set(CALF)


def hull_perimeter(points):
    from scipy.spatial import ConvexHull
    h = ConvexHull(points)
    v = points[h.vertices]
    return float(np.sum(np.linalg.norm(v - np.roll(v, 1, 0), axis=1)))


class Body:
    """Corps du mannequin (repos) avec l'os dominant de chaque sommet."""

    def __init__(self, glb=None, rig=None):
        import build_rig
        meshes, _ = build_rig.read_meshes(glb or rig_pose.GLB)
        self._setup(meshes, json.loads((rig or rig_pose.RIG).read_text(encoding='utf-8')))

    @classmethod
    def from_meshes(cls, meshes, rig):
        """Corps déjà chargé (fabrication)."""
        self = cls.__new__(cls)
        self._setup(meshes, rig)
        return self

    def _setup(self, meshes, rig, dominant=None):
        self.meshes = meshes
        self.rig = rig
        offs = np.cumsum([0] + [len(m['positions']) for m in self.meshes])
        self.V = np.concatenate([m['positions'] for m in self.meshes]).astype(float)
        self.F = np.concatenate([m['indices'].reshape(-1, 3) + o
                                 for m, o in zip(self.meshes, offs)])
        self.owner = np.concatenate([np.full(len(m['positions']), k)
                                     for k, m in enumerate(self.meshes)])
        # Segment de mesure de chaque maillage ; seuls les muscles comptent
        # (le mètre ruban passe sur eux) : ni os, ni contexte, ni tête, ni
        # mains ou pieds.
        import build_rig
        seg = []
        for m in meshes:
            key = build_rig.region_of_mesh(m['nom'])[0]
            if key is None or key in ('head', 'hand_intrinsic', 'foot_intrinsic'):
                seg.append('')
            else:
                seg.append(next((n for n, keys in SEGMENTS.items() if keys and key in keys),
                                'tronc'))
        self.mesh_segment = np.array(seg)
        self.face_segment = self.mesh_segment[self.owner[self.F[:, 0]]]
        self.heads = {b['nom']: np.array(b['tete']) for b in self.rig['os']}
        self.height = float(self.V[:, 1].max() - self.V[:, 1].min())
        import trimesh
        self.tm = trimesh.Trimesh(self.V, self.F, process=False)

    def section(self, y, segment=None, side=None):
        """Points (x, z) de la section à la hauteur y, limités aux faces des
        muscles du segment (`SEGMENTS`), du côté `side` (signe de x) si
        donné ; `segment` None : tous les muscles."""
        import trimesh
        lines, faces = trimesh.intersections.mesh_plane(
            self.tm, plane_normal=[0, 1, 0], plane_origin=[0, y, 0], return_faces=True)
        keep = self.face_segment[faces] != ''
        if segment is not None:
            keep &= self.face_segment[faces] == segment
        lines = lines[keep]
        pts = lines.reshape(-1, 3)[:, [0, 2]]
        if side:
            pts = pts[np.sign(pts[:, 0]) == side]
        return pts

    def girth(self, y, segment, side=None):
        pts = self.section(y, segment, side)
        return hull_perimeter(pts) if len(pts) >= 3 else 0.0

    def max_girth(self, ys, segment, side=None):
        best = (0.0, ys[0])
        for y in ys:
            g = self.girth(y, segment, side)
            if g > best[0]:
                best = (g, y)
        return best

    def levels(self):
        h = self.heads
        return {
            'bras': (h['upperarm_l'][1] + h['forearm_l'][1]) / 2,
            'avant_bras': None,   # maximum
            'poitrine': None,     # sous les aisselles (mesuré)
            'taille': None,       # minimum
            'mollet': None,       # maximum
            'cou': h['neck'][1] + .045,
        }

    def armpit_level(self):
        """Hauteur du creux de l'aisselle : niveau le plus haut auquel la
        section du bras est encore séparée de celle du tronc d'au moins 4 mm
        (au-dessus, deltoïde et pectoral se rejoignent)."""
        from scipy.spatial import cKDTree
        top = self.heads['upperarm_l'][1]
        last = top - .12
        for y in np.arange(top - .12, top, .005):
            a = self.section(y, 'bras', 1)
            t = self.section(y, 'tronc', 1)
            if not len(a) or not len(t):
                continue
            if cKDTree(t).query(a)[0].min() < .004:
                return float(last)
            last = y
        return float(last)

    def measure(self):
        h = self.heads
        L = self.levels()
        out = {'H': self.height}
        out['bras'] = self.girth(L['bras'], 'bras', 1)
        out['avant_bras'], out['avant_bras_y'] = self.max_girth(
            np.arange(h['forearm_l'][1] - .12, h['forearm_l'][1] - .02, .005), 'avant_bras', 1)
        pit = self.armpit_level()
        out['aisselle_y'] = pit
        out['poitrine'] = self.girth(pit - .01, 'tronc')
        out['poitrine_y'] = pit - .01
        ws = [(self.girth(y, 'tronc'), y)
              for y in np.arange(h['lumbar'][1] + .02, h['thoracic_low'][1] + .02, .005)]
        out['taille'], out['taille_y'] = min(ws)
        # Cuisse : le modèle sans peau ni graisse creuse le pli fessier ; le
        # tour « sous le pli » est pris au maximum de la cuisse sous ce pli
        # (entre 9 et 20 cm sous la tête fémorale), là où un ruban le mesure.
        out['cuisse'], out['cuisse_y'] = self.max_girth(
            np.arange(h['thigh_l'][1] - .20, h['thigh_l'][1] - .09, .005), 'cuisse', 1)
        out['mollet'], out['mollet_y'] = self.max_girth(
            np.arange(h['shin_l'][1] - .22, h['shin_l'][1] - .06, .005), 'mollet', 1)
        out['cou'] = self.girth(L['cou'], 'cou')
        d = [m for m in self.meshes if m['nom'].startswith('deltoid')]
        out['bideltoide'] = float(max(m['positions'][:, 0].max() for m in d)
                                  - min(m['positions'][:, 0].min() for m in d))
        # Tour d'épaules : maximum à la hauteur des deltoïdes, bras compris.
        out['epaules'], out['epaules_y'] = max(
            (hull_perimeter(self.section(y)), y)
            for y in np.arange(h['upperarm_l'][1] - .06, h['upperarm_l'][1] + .04, .005))
        out['epaules_sur_taille'] = out['epaules'] / out['taille']
        out['niveaux'] = {'bras': L['bras'], 'cou': L['cou']}
        return out


def report(m, label=''):
    H = m['H']
    lines = [f'{label}H = {H:.3f} m']
    for k, target in TARGETS.items():
        v = m[k]
        ratio = v / H
        env = envelope_target(k, H)
        dev = ratio / env - 1
        ok = abs(dev) <= TOLERANCE
        lines.append(f"  {k:12s} {v * 100:6.1f} cm  {ratio:.3f} H  cible {target:.3f} H, "
                     f"enveloppe {env:.3f} H ({dev * 100:+.1f} %) "
                     f"{'OK' if ok else 'hors tolérance'}")
    lines.append(f"  épaules      {m['epaules'] * 100:6.1f} cm ; épaules / taille "
                 f"{m['epaules_sur_taille']:.2f} (cible ≥ {TARGET_SHOULDER_WAIST})")
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--glb')
    parser.add_argument('--rig')
    parser.add_argument('--json')
    args = parser.parse_args()
    body = Body(args.glb and Path(args.glb), args.rig and Path(args.rig))
    m = body.measure()
    print(report(m))
    if args.json:
        Path(args.json).write_text(json.dumps(m, indent=1) + '\n')


if __name__ == '__main__':
    main()
