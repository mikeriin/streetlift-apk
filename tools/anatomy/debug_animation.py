#!/usr/bin/env python3
"""M7 (mannequin 3D) : animation de débogage « squat lent au poids du
corps », pour tester le lecteur (Réglages › À propos › Moteur 3D ›
Animation de test). **Réservée aux tests** : jamais montrée comme la
démonstration d'un exercice.

Produite comme le propriétaire produira les siennes : un FBX « Without
Skin » sur le squelette Mixamo du personnage Ch36 (os renommés
`mixamorig:`, préfixe des téléchargements Mixamo), 30 i/s, puis passée par
la chaîne d'import (`import_animations.py deposer` puis `importer`).

Mouvement (repère du corps, glTF : y en haut, avant = +z) : 4 phases,
descente 3 s, pause basse 1 s, montée 1 s, pause haute 1 s (boucle).
Au plus bas : cuisses à 88° de la verticale (parallèles au sol), flexion
dorsale des chevilles 33°, genoux fléchis à 121°, pieds à plat et fixes
(le bassin descend et recule : cinématique des deux jambes), bras tendus
devant à l'horizontale (contrepoids). Inclinaison du tronc calculée à
chaque image pour garder le centre de masse (segments de Winter) au-dessus
du milieu du pied (bassin 75 %, rachis 25 %) ; tête ramenée vers l'avant.
Départ et arrivée : pose d'affichage du mannequin fixe (bras abaissés).

Relançable :
  python3 tools/anatomy/debug_animation.py sortie.fbx [--rapport rapport.json]
(Blender sans interface ; le personnage déchiffré dans
assets_secure/clair/ ; la clé n'est nécessaire qu'au dépôt).
"""
import argparse
import json
import math
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
import import_animations as ia  # noqa: E402

CLIP_ID = 'debug_squat'
FPS = 30
PHASES = [('Descente', 'excentrique', 3.0), ('Pause basse', 'isometrique', 1.0),
          ('Montée', 'concentrique', 1.0), ('Pause haute', 'isometrique', 1.0)]
THIGH_DEG = 88        # cuisse depuis la verticale, au plus bas
ANKLE_DEG = 33        # flexion dorsale de la cheville (tibia incliné en avant)
PELVIS_SHARE = .75    # part du bassin dans l'inclinaison du tronc
MIDFOOT_Z = .03       # m : milieu du pied (entre la cheville et les orteils)
ARM_FORWARD = {'Left': -90, 'Right': 90}   # rotation autour de y : bras devant
ARM_DOWN = {'Left': -70, 'Right': 70}      # pose d'affichage (autour de z)
FOREARM_DOWN = {'Left': 8, 'Right': -8}


def Rx(d):
    return ia.axis_angle((1, 0, 0), d)


def smooth(x):
    x = min(1.0, max(0.0, x))
    return x * x * (3 - 2 * x)


def depth_at(t):
    """Profondeur 0 (debout) → 1 (au plus bas) au temps t (s)."""
    d, p, m, _ = (ph[2] for ph in PHASES)
    if t <= d:
        return smooth(t / d)
    if t <= d + p:
        return 1.0
    if t <= d + p + m:
        return 1 - smooth((t - d - p) / m)
    return 0.0


def pose(depth, lean, base):
    """Rotations globales (repère du corps) de chaque os et translation du
    bassin, pour une profondeur et une inclinaison du tronc (degrés)."""
    import numpy as np
    skel, bones, parents, heads = base
    idx = {b: i for i, b in enumerate(bones)}
    H = {b: np.array(heads[i]) for i, b in enumerate(bones)}
    G = {b: np.eye(3) for b in bones}
    phi, a = THIGH_DEG * depth, ANKLE_DEG * depth
    pelvis = lean * PELVIS_SHARE
    G['Hips'] = Rx(pelvis)
    spine = pelvis
    for b in ('Spine', 'Spine1', 'Spine2'):
        spine += lean * (1 - PELVIS_SHARE) / 3
        G[b] = Rx(spine)
    G['Neck'] = Rx(lean * .55)
    G['Head'] = G['HeadTop_End'] = Rx(lean * .3)
    for side in ('Left', 'Right'):
        G[side + 'UpLeg'] = Rx(-phi)
        G[side + 'Leg'] = Rx(a)
        # pieds à plat (identité), orteils aussi
        G[side + 'Shoulder'] = G['Spine2']
        top = ia.axis_angle((0, 0, 1), ARM_DOWN[side])
        bottom = G['Spine2'].T @ ia.axis_angle((0, 1, 0), ARM_FORWARD[side])
        arm_local = ia.quat_to_mat(ia.slerp(ia.mat_to_quat(top), ia.mat_to_quat(bottom), depth))
        G[side + 'Arm'] = G['Spine2'] @ arm_local
        fore = ia.axis_angle((0, 0, 1), FOREARM_DOWN[side] * (1 - depth))
        G[side + 'ForeArm'] = G[side + 'Arm'] @ fore
    # mains et doigts : suivent l'avant-bras (rotations locales nulles)
    for b in bones:
        if b.startswith(('LeftHand', 'RightHand')):
            p = parents[idx[b]]
            G[b] = G[p]
    # translation du bassin : chevilles fixes (moyenne des deux côtés)
    T = np.zeros(3)
    for side in ('Left', 'Right'):
        up, kn, an = H[side + 'UpLeg'], H[side + 'Leg'], H[side + 'Foot']
        posed_hip = G['Hips'] @ (up - H['Hips'])
        ankle = posed_hip + G[side + 'UpLeg'] @ (kn - up) + G[side + 'Leg'] @ (an - kn)
        T += (an - H['Hips']) - ankle
    T = T / 2
    root = T  # position du bassin = tête de repos + root
    return G, root


def to_motion(Gs, roots, base):
    import numpy as np
    skel, bones, parents, heads = base
    idx = {b: i for i, b in enumerate(bones)}
    local = np.zeros((len(Gs), len(bones), 4))
    for f, G in enumerate(Gs):
        for i, b in enumerate(bones):
            p = parents[i]
            L = G[b] if p is None else G[p].T @ G[b]
            local[f, i] = ia.mat_to_quat(L)
            if local[f, i, 3] < 0:
                local[f, i] *= -1
    for f in range(1, len(Gs)):
        flip = (local[f] * local[f - 1]).sum(axis=1) < 0
        local[f, flip] *= -1
    return ia.Motion(bones, parents, heads, FPS, local, np.array(roots))


def balanced(depth, base):
    """Inclinaison du tronc (degrés) qui place le centre de masse au-dessus
    du milieu du pied (dichotomie)."""
    lo, hi = -5.0, 80.0
    for _ in range(40):
        mid = (lo + hi) / 2
        G, root = pose(depth, mid, base)
        m = to_motion([G], [root], base)
        z = m.center_of_mass(0)[2]
        if z > MIDFOOT_Z:
            hi = mid
        else:
            lo = mid
    return (lo + hi) / 2


def generate(base=None):
    """Mouvement complet (Motion) et rapport."""
    base = base or ia.skeleton_motion_base()
    total = sum(p[2] for p in PHASES)
    n = int(round(total * FPS)) + 1
    Gs, roots, leans = [], [], []
    upright = balanced(0.0, base)
    for f in range(n):
        d = depth_at(f / FPS)
        # debout : tronc droit (inclinaison mesurée debout retirée)
        lean = balanced(d, base) - upright * (1 - d)
        G, root = pose(d, lean, base)
        Gs.append(G)
        roots.append(root)
        leans.append(lean)
    motion = to_motion(Gs, roots, base)
    bottom = int(round(PHASES[0][2] * FPS))
    com = motion.center_of_mass(bottom)
    report = {
        'images': n, 'duree_s': total,
        'bas': {'cuisse_deg': THIGH_DEG, 'cheville_deg': ANKLE_DEG,
                'genou_deg': THIGH_DEG + ANKLE_DEG,
                'tronc_deg': round(leans[bottom], 1),
                'bassin_descente_m': round(float(-roots[bottom][1]), 3),
                'bassin_recul_m': round(float(-roots[bottom][2]), 3),
                'centre_de_masse_z_m': round(float(com[2]), 3)},
    }
    return motion, report


def write_fbx(motion, out, log=print):
    """FBX « Without Skin » : le squelette du personnage (os `mixamorig:`),
    une clé par image (30 i/s), aucun maillage."""
    import bpy
    import numpy as np
    from mathutils import Matrix
    import build_character as bc
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(bc.FBX))
    for o in [o for o in bpy.data.objects if o.type != 'ARMATURE']:
        bpy.data.objects.remove(o, do_unlink=True)
    arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    arm.name = 'Armature'
    for b in arm.data.bones:
        b.name = 'mixamorig:' + ia.canonical(b.name)
    scene = bpy.context.scene
    scene.render.fps, scene.render.fps_base = FPS, 1
    scene.frame_start, scene.frame_end = 1, motion.frames
    aw = np.array(arm.matrix_world)
    aw_inv = np.linalg.inv(aw)
    C = np.array([[1, 0, 0], [0, 0, 1], [0, -1, 0]], dtype=np.float64)   # Blender → glTF
    names = {ia.canonical(b.name): b.name for b in arm.data.bones}
    L = {c: np.array(arm.data.bones[n].matrix_local) for c, n in names.items()}
    order = [b for b in motion.bones]
    for pb in arm.pose.bones:
        pb.rotation_mode = 'QUATERNION'
    for f in range(motion.frames):
        R, P = motion.globals(f)
        posed = {}
        for i, b in enumerate(order):
            Gbl = C.T @ R[i] @ C
            head_rest = C.T @ motion.heads[i]
            head = C.T @ P[i]
            D = np.eye(4)
            D[:3, :3] = Gbl
            D[:3, 3] = head - Gbl @ head_rest
            posed[b] = aw_inv @ D @ aw @ L[b]      # repère de l'armature
        for i, b in enumerate(order):
            p = motion.parents[i]
            if p is None:
                basis = np.linalg.inv(L[b]) @ posed[b]
            else:
                basis = np.linalg.inv(L[b]) @ L[p] @ np.linalg.inv(posed[p]) @ posed[b]
            loc, rot, _ = Matrix(basis.tolist()).decompose()
            pb = arm.pose.bones[names[b]]
            pb.location = loc
            pb.rotation_quaternion = rot
            pb.scale = (1, 1, 1)
            pb.keyframe_insert('location', frame=f + 1)
            pb.keyframe_insert('rotation_quaternion', frame=f + 1)
            pb.keyframe_insert('scale', frame=f + 1)
    bpy.ops.object.select_all(action='DESELECT')
    arm.select_set(True)
    bpy.ops.export_scene.fbx(filepath=str(out), use_selection=True, object_types={'ARMATURE'},
                             add_leaf_bones=False, bake_anim=True,
                             bake_anim_use_all_actions=False, bake_anim_use_nla_strips=False,
                             bake_anim_simplify_factor=0.0, bake_anim_step=1.0)
    log(f'FBX {out} ({Path(out).stat().st_size} octets, {motion.frames} images)')


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('sortie', nargs='?', default=str(ROOT / ia.CLEAR_ANIM / f'{CLIP_ID}.fbx'))
    parser.add_argument('--rapport')
    args = parser.parse_args()
    motion, report = generate()
    print(json.dumps(report, ensure_ascii=False))
    Path(args.sortie).parent.mkdir(parents=True, exist_ok=True)
    write_fbx(motion, args.sortie)
    if args.rapport:
        Path(args.rapport).write_text(json.dumps(report, ensure_ascii=False, indent=1) + '\n',
                                      encoding='utf-8')


if __name__ == '__main__':
    main()
