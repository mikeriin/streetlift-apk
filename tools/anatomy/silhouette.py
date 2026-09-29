#!/usr/bin/env python3
"""M56 correction 1 (mannequin 3D) : silhouette du mannequin comparée à la
référence du propriétaire (écorché d'athlète, trois vues : face, profil, dos).

La référence n'est pas un tour de mètre ruban mais une image : ce qui s'y
mesure, ce sont des **largeurs** (vue de face) et des **profondeurs** (vue de
profil) de la silhouette, en fraction de la hauteur H de la figure (sommet du
crâne → plante des pieds), à des hauteurs elles-mêmes en fraction de H. Les
valeurs `REFERENCE` ci-dessous ont été relevées sur les trois images du
29/09/2026 (segmentation du fond gris, fermeture morphologique, largeur des
plages de pixels ligne par ligne, tous les 2 % de H).

Le mannequin est mesuré de la même façon : extension en x (face) ou en z
(profil) des sommets d'une tranche horizontale de ± 5 mm, sur l'ensemble du
corps ou sur un segment (`measure_body.SEGMENTS`) quand la référence sépare
le segment (bras écartés du tronc sur l'image de face, jambes séparées).

Usage : `python3 tools/anatomy/silhouette.py [--glb chemin] [--rig chemin] [--json sortie]`.
"""
import argparse
import json
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import measure_body  # noqa: E402

# Référence (fraction de H). Vue de face : largeurs ; vue de profil :
# profondeurs de la silhouette complète (le bras pend le long du tronc).
REFERENCE = {
    # largeur, hauteur relative de la mesure sur l'image (0 = sommet du crâne)
    'tete_largeur': (.098, .08),
    'bideltoide': (.300, .22),
    'poitrine_largeur': (.203, .30),      # tronc sous les aisselles
    'taille_largeur': (.155, .38),        # plus étroit du tronc
    'hanches_largeur': (.197, .48),       # tronc + fessiers + TFL
    'cuisse_largeur': (.100, .54),        # une jambe, haut de la cuisse
    'genou_largeur': (.057, .68),
    'mollet_largeur': (.066, .80),
    'cheville_largeur': (.034, .90),
    'bras_largeur': (.062, .34),          # bras relâché, mi-biceps
    'avant_bras_largeur': (.044, .42),    # maximum
    # profondeurs (profil)
    'tete_profondeur': (.109, .08),
    'poitrine_profondeur': (.132, .30),   # thorax + bras le long du corps
    'taille_profondeur': (.120, .38),
    'fessiers_profondeur': (.141, .48),
    'cuisse_profondeur': (.105, .56),
    'genou_profondeur': (.073, .70),
    'mollet_profondeur': (.075, .78),
    'cheville_profondeur': (.055, .88),
}
TOLERANCE = .06


def slab_extent(V, y, axis, half=.005):
    sel = np.abs(V[:, 1] - y) <= half
    if not sel.any():
        return 0.0
    return float(V[sel, axis].max() - V[sel, axis].min())


class Silhouette:
    """Largeurs et profondeurs du mannequin aux repères anatomiques du modèle
    (têtes d'os du rig), les os et tendons comptés avec le segment du muscle
    le plus proche ; mains et pieds exclus (la référence les écarte du
    tronc) ; tête à part."""

    def __init__(self, body):
        import build_rig
        from scipy.spatial import cKDTree
        self.body = body
        self.top = float(body.V[:, 1].max())
        self.H = body.height
        V = body.V
        keys = [build_rig.region_of_mesh(m['nom'])[0] for m in body.meshes]
        seg = body.mesh_segment[body.owner].astype(object)
        head = np.array([k == 'head' for k in keys])[body.owner]
        extremity = np.array([k in ('hand_intrinsic', 'foot_intrinsic') for k in keys])[body.owner]
        seg[head] = 'tete'
        seg[extremity] = 'extremite'
        unassigned = seg == ''
        muscle = ~unassigned & ~head & ~extremity
        tree = cKDTree(V[muscle])
        near = tree.query(V[unassigned])[1]
        seg[unassigned] = seg[muscle][near]
        self.seg = seg
        self.h = body.heads

    def _sel(self, segments, side=None):
        sel = np.isin(self.seg, segments)
        if side:
            sel &= np.sign(self.body.V[:, 0]) == side
        return sel

    def extent(self, segments, ys, axis, side=None, best=max):
        V = self.body.V[self._sel(segments, side)]
        return best(slab_extent(V, y, axis) for y in ys)

    def measure(self):
        h = self.h
        H = self.H
        arm_mid = (h['upperarm_l'][1] + h['forearm_l'][1]) / 2
        pit = self.body.armpit_level()
        rng = lambda a, b: np.arange(a, b + 1e-9, .005)  # noqa: E731
        trunk = ['tronc', 'cou']
        legs = ['cuisse', 'mollet']
        m = {'H': H}
        m['tete_largeur'] = self.extent(['tete'], rng(h['head'][1], self.top), 0)
        d = [mm for mm in self.body.meshes if mm['nom'].startswith('deltoid')]
        m['bideltoide'] = float(max(mm['positions'][:, 0].max() for mm in d)
                                - min(mm['positions'][:, 0].min() for mm in d))
        m['poitrine_largeur'] = self.extent(trunk, [pit - .01], 0)
        m['taille_largeur'] = self.extent(trunk, rng(h['lumbar'][1] + .02, h['thoracic_low'][1] + .02), 0, best=min)
        m['hanches_largeur'] = self.extent(trunk + ['cuisse'], rng(h['thigh_l'][1] - .06, h['thigh_l'][1] + .08), 0)
        m['cuisse_largeur'] = self.extent(legs, rng(h['thigh_l'][1] - .20, h['thigh_l'][1] - .09), 0, 1)
        m['genou_largeur'] = self.extent(legs, rng(h['shin_l'][1] - .03, h['shin_l'][1] + .03), 0, 1, best=min)
        m['mollet_largeur'] = self.extent(legs, rng(h['shin_l'][1] - .22, h['shin_l'][1] - .06), 0, 1)
        m['cheville_largeur'] = self.extent(legs, rng(h['foot_l'][1] + .02, h['foot_l'][1] + .05), 0, 1, best=min)
        m['bras_largeur'] = self.extent(['bras'], rng(arm_mid - .02, arm_mid + .02), 0, 1)
        m['avant_bras_largeur'] = self.extent(['avant_bras'], rng(h['forearm_l'][1] - .12, h['forearm_l'][1] - .02), 0, 1)
        # Profil : silhouette complète sans les mains ni les pieds.
        allb = ['tronc', 'cou', 'bras', 'avant_bras', 'cuisse', 'mollet']
        m['tete_profondeur'] = self.extent(['tete'], rng(h['head'][1], self.top), 2)
        m['poitrine_profondeur'] = self.extent(allb, [pit - .01], 2)
        m['taille_profondeur'] = self.extent(trunk, rng(h['lumbar'][1] + .02, h['thoracic_low'][1] + .02), 2, best=min)
        m['fessiers_profondeur'] = self.extent(trunk + ['cuisse'], rng(h['thigh_l'][1] - .06, h['thigh_l'][1] + .08), 2)
        m['cuisse_profondeur'] = self.extent(legs, rng(h['thigh_l'][1] - .20, h['thigh_l'][1] - .09), 2)
        m['genou_profondeur'] = self.extent(legs, rng(h['shin_l'][1] - .03, h['shin_l'][1] + .03), 2, best=min)
        m['mollet_profondeur'] = self.extent(legs, rng(h['shin_l'][1] - .22, h['shin_l'][1] - .06), 2)
        m['cheville_profondeur'] = self.extent(legs, rng(h['foot_l'][1] + .02, h['foot_l'][1] + .05), 2, best=min)
        for k in list(m):
            if k != 'H':
                m[k] = m[k] / H
        # Repères de hauteur (fraction de H depuis le sommet), pour comparer
        # les proportions de longueur à la référence.
        m['reperes'] = {k: (self.top - h[b][1]) / H for k, b in
                        [('epaule', 'upperarm_l'), ('coude', 'forearm_l'), ('hanche', 'thigh_l'),
                         ('genou', 'shin_l'), ('cheville', 'foot_l')]}
        m['reperes']['aisselle'] = (self.top - pit) / H
        return m


def report(m, label=''):
    lines = [f'{label}H = {m["H"]:.3f} m  (référence : fraction de H, tolérance ± {TOLERANCE * 100:.0f} %)',
             '  repères : ' + ', '.join(f'{k} {v:.2f}' for k, v in m['reperes'].items())]
    for key, (ref, f) in REFERENCE.items():
        v = m[key]
        dev = v / ref - 1
        lines.append(f'  {key:22s} {v:.3f}  réf {ref:.3f}  ({dev * 100:+5.1f} %)'
                     f"  {'OK' if abs(dev) <= TOLERANCE else 'écart'}")
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--glb')
    parser.add_argument('--rig')
    parser.add_argument('--json')
    args = parser.parse_args()
    body = measure_body.Body(args.glb and Path(args.glb), args.rig and Path(args.rig))
    m = Silhouette(body).measure()
    print(report(m))
    if args.json:
        Path(args.json).write_text(json.dumps(m, indent=1) + '\n')


if __name__ == '__main__':
    main()
