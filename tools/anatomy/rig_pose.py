"""M5 (mannequin 3D) : pose du mannequin riggé en numpy (planches, fabrication).

Même calcul que l'application : cinématique directe des os (rotations locales
sur un squelette au repos sans rotation), puis mélange linéaire de 4
influences par sommet (shader `SkinnedVertex` de flutter_scene,
`lib/mannequin_rig.dart` pour le toucher).
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
import rig_def  # noqa: E402

GLB = ROOT / 'assets/anatomy/mannequin.glb'
RIG = ROOT / 'assets/anatomy/rig.json'
SKIN = ROOT / 'assets/anatomy/mannequin_skin.bin'


def load_skin(rig, meshes, path=SKIN):
    """Influences par sommet (joints, poids 0-1) depuis le fichier de peau."""
    import numpy as np
    data = np.frombuffer(path.read_bytes(), dtype=np.uint8)
    offset = 0
    out = {}
    counts = {m['nom']: m['sommets'] for m in rig['peau']['maillages']}
    for mesh in meshes:
        n = counts[mesh['nom']]
        assert n == len(mesh['positions']), mesh['nom']
        block = data[offset:offset + 8 * n].reshape(n, 8)
        out[mesh['nom']] = (block[:, :4].astype(np.int64), block[:, 4:].astype(np.float64) / 255)
        offset += 8 * n
    assert offset == len(data)
    return out


def load_model():
    return load_model_from(GLB, RIG, SKIN)


def load_model_from(glb=None, rig=None, skin=None):
    """Modèle (maillages, rig, peau) depuis des chemins donnés (M56 :
    mesures avant / après sur des fichiers hors `assets/`)."""
    import build_rig
    meshes, _ = build_rig.read_meshes(glb or GLB)
    rig_data = json.loads((rig or RIG).read_text(encoding='utf-8'))
    return {'meshes': meshes, 'rig': rig_data, 'skin': load_skin(rig_data, meshes, skin or SKIN)}


def posture_rotations(rig, posture):
    """(rotations {os: quaternion}, translation du bassin) d'une posture
    (nom de `rig['postures']` ou dictionnaire {'angles', 'translation'})."""
    if isinstance(posture, str):
        posture = rig['postures'][posture]
    if 'rotations' in posture:
        rots = {k: tuple(v) for k, v in posture['rotations'].items()}
    else:
        angles = posture.get('angles', {})
        rots = rig_def.posture_rotations({b['nom']: b['ddl'] for b in rig['os']}, angles)
    return rots, tuple(posture.get('translation', (0.0, 0.0, 0.0)))


def skin_positions(positions, joints, weights, mats, order):
    """Mélange linéaire : Σ wᵢ Mᵢ p (numpy)."""
    import numpy as np
    m = np.array([mats[b] for b in order])            # (J, 3, 4)
    p = np.hstack([positions, np.ones((len(positions), 1))])   # (N, 4)
    out = np.zeros((len(positions), 3))
    for k in range(4):
        mk = m[joints[:, k]]                            # (N, 3, 4)
        out += weights[:, k:k + 1] * np.einsum('nij,nj->ni', mk, p)
    return out


def pose_model(model, posture):
    """Positions déformées de chaque maillage et transformations globales."""
    rig = model['rig']
    rots, trans = posture_rotations(rig, posture)
    globals_ = rig_def.forward_kinematics(rig, rots, trans)
    mats = rig_def.skinning_matrices(rig, globals_)
    order = [b['nom'] for b in rig['os']]
    out = {}
    for mesh in model['meshes']:
        joints, weights = model['skin'][mesh['nom']]
        out[mesh['nom']] = skin_positions(mesh['positions'], joints, weights, mats, order)
    return out, globals_
