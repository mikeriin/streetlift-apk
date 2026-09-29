#!/usr/bin/env python3
"""M56 correction 2 (mannequin 3D) : fabrique le modèle d'exécution à partir
de l'écorché acheté par le propriétaire le 29/09/2026 (« Ecorche Musclenames
Male Anatomy », archive `Archive.zip` de la release GitHub `modele-achete`,
jamais dans le dépôt : licence d'achat, 168 Mo).

Source : un seul maillage ZBrush (664 284 triangles, 332 283 sommets, pose en
A, sans normales), une texture `diffuse.jpeg` 4096² où chaque muscle est une
plage de couleur unie portant son abréviation en blanc (légende
`BonesMusclesFibers.pdf`), les os en beige, les tendons et aponévroses en gris.

Chaîne :
  1. lecture de l'OBJ (positions, UV, triangles) ;
  2. segmentation de la texture : classe de couleur par texel (palette de 16
     teintes relevée sur la texture), texte et dégradés rebouchés par le plus
     proche voisin, composantes connexes par classe → régions d'image ;
  3. triangle → région d'image (UV du centre), composantes connexes du
     maillage par région, fusion des miettes (< 150 triangles) dans la
     voisine qui partage le plus d'arêtes ;
  4. nommage : chaque étiquette de la texture (`LABELS`, position du texte
     relevée à la main, abréviation lue) désigne la composante sous son
     texte ; deux muscles de même couleur qui se touchent (grand pectoral et
     dentelé) sont séparés par plus court chemin sur le maillage depuis
     leurs étiquettes ; les composantes à cheval sur la ligne médiane
     (trapèze, fessiers) sont coupées en gauche / droite ; les composantes
     sans étiquette prennent le nom de la voisine de même couleur, sinon de
     leur symétrique, sinon leur position (tête, cou, mains, pieds) ;
  5. subdivisions du pack : deltoïde (antérieur / moyen / postérieur par
     l'angle autour de l'épaule), trapèze (supérieur / moyen / inférieur par
     C7 et l'épine de la scapula), grand pectoral (claviculaire /
     sterno-costal / abdominal par la hauteur), gastrocnémien (médial /
     latéral) ;
  6. décimation globale (fast_simplification, maillage entier : pas de
     fissure entre régions) à ≤ 60 000 triangles, régions reportées par
     plus proche centre, normales lissées sur le maillage entier ;
  7. mise à l'échelle (H = 1,70 m, pieds à y = 0), GLB : un nœud par région
     (`<clé>_<left|right>`), `os`, `tendon_<k>` (tendons et aponévroses, un
     nœud par pièce, gris translucide comme les muscles),
     `head` ; carte `assets/anatomy/muscles_map.json`.

Relançable : `pip install numpy scipy pillow fast_simplification
--break-system-packages` puis
`python3 tools/anatomy/build_model.py --zip Archive.zip [--render dossier]`.
`--check` vérifie seulement les sorties (sans la source).
"""
import argparse
import hashlib
import io
import json
import struct
import sys
import zipfile
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
from anatomy_data import (  # noqa: E402
    APP_GROUPS, FR, GROUP_OF_KEY, PACK_OF_KEY, SIDE_FR, pack_muscles,
)

OUT_GLB = ROOT / 'assets/anatomy/mannequin.glb'
OUT_MAP = ROOT / 'assets/anatomy/muscles_map.json'
REPORT = HERE / 'build_report.json'

SOURCE_NAME = 'Ecorche Musclenames Male Anatomy (écorché acheté, 29/09/2026)'
SOURCE_ZIP_SHA256 = 'REMPLACE_PAR_LE_SHA'
OBJ_IN_ZIP = 'Ecorche_Musclenames_Male_Anatomy/male_ecorche.OBJ'
TEXTURE_IN_ZIP = 'Ecorche_Musclenames_Male_Anatomy/diffuse.jpeg'

TRIANGLE_BUDGET = 60000
HEIGHT = 1.70
SEG_SIZE = 2048
MERGE_BELOW = 150

# Palette de la texture (k-means à 16 teintes sur la texture, 29/09/2026).
PALETTE = [
    (220, 155, 156), (165, 156, 219), (197, 156, 218), (159, 216, 203),
    (206, 206, 206), (218, 156, 210), (182, 218, 157), (254, 254, 254),
    (212, 197, 153), (157, 197, 218), (144, 150, 207), (218, 152, 186),
    (212, 156, 217), (158, 218, 169), (207, 195, 189), (157, 174, 218),
]
CLASS_TEXT, CLASS_GREY, CLASS_BONE, CLASS_BLEND = 7, 4, 8, 14

# Étiquettes de la texture : abréviation lue, centre du texte (texels, 4096²).
LABELS = [
    ('A', 651, 735), ('A', 3408, 3010), ('ADM', 3078, 2079), ('ADM', 3150, 3755),
    ('ADM', 3961, 2427), ('AH', 2888, 2282), ('AH', 3001, 3991), ('AL', 1847, 1987),
    ('AL', 3613, 561), ('AM', 1699, 856), ('AM', 3710, 1699), ('AP', 325, 2116),
    ('AP', 1350, 2129), ('APB', 3471, 240), ('APL', 1005, 592), ('APL', 3330, 3415),
    ('ASIS', 479, 3419), ('ASIS', 1199, 3419), ('Apo', 599, 3388), ('Apo', 1070, 3385),
    ('B', 264, 504), ('B', 465, 980), ('B', 2917, 3027), ('B', 3105, 2700), ('BB', 291, 324),
    ('BB', 2930, 2742), ('BF', 1509, 1198), ('BF', 3447, 1404), ('Br', 640, 480),
    ('Br', 3159, 3054), ('Bu', 2245, 560), ('Bu', 2503, 560), ('C', 174, 1017),
    ('C', 1726, 403), ('C', 3571, 2490), ('C7', 2241, 3865), ('CL', 672, 2256),
    ('CL', 1000, 2260), ('Ca', 2878, 3886), ('Ca', 3032, 2380), ('D', 91, 2300),
    ('D', 1546, 2293), ('DAB', 2345, 692), ('DAB', 2399, 687), ('DPB', 2021, 549),
    ('DPB', 2702, 567), ('DS', 2350, 286), ('ECRB', 835, 593), ('ECRB', 3297, 3197),
    ('ECRL', 728, 566), ('ECRL', 3253, 3027), ('ECU', 847, 739), ('ECU', 3579, 2160),
    ('ED', 845, 649), ('ED', 3354, 3185), ('EDB', 1245, 349), ('EDB', 3802, 3566),
    ('EDL', 433, 1566), ('EDL', 2344, 1274), ('EDM', 840, 691), ('EDM', 3415, 3219),
    ('EO', 478, 3012), ('EO', 1224, 2997), ('EPB', 1063, 599), ('EPB', 3354, 3448),
    ('ES', 2161, 2742), ('ES', 2314, 2741), ('F', 2310, 230), ('F', 2440, 234),
    ('FCR', 815, 356), ('FCR', 3078, 3257), ('FCU', 790, 827), ('FCU', 3517, 3139),
    ('FDI', 3375, 2245), ('FDI', 3919, 2220), ('FDL', 187, 1224), ('FDS', 1028, 482),
    ('FDS', 1045, 425), ('FDS', 1057, 385), ('FDS', 3162, 3470), ('FDS', 3237, 3447),
    ('FH', 1009, 1453), ('FH', 2898, 1273), ('Fe', 1079, 1850), ('Fe', 2881, 845),
    ('Fe', 2986, 1154), ('G', 1472, 796), ('G', 3488, 1794), ('GMa', 2071, 2342),
    ('GMa', 2404, 2344), ('GMe', 242, 3450), ('GMe', 1435, 3454), ('GT', 1713, 2315),
    ('GT', 2760, 2309), ('GTe', 377, 1332), ('GTe', 2301, 1528), ('Ga', 724, 1241),
    ('Ga', 2663, 1533), ('I', 643, 3634), ('I', 1040, 3640), ('I', 3587, 2780),
    ('IC', 349, 3361), ('IC', 1300, 3373), ('IT', 1669, 1431), ('IT', 3552, 1143),
    ('In', 1963, 3514), ('In', 2501, 3500), ('LD', 1957, 3022), ('LD', 2501, 3019),
    ('LE', 582, 673), ('LE', 3331, 2963), ('LLSAN', 2423, 390), ('LM', 1188, 228),
    ('LM', 3715, 3451), ('LS', 594, 1994), ('LS', 1066, 2015), ('M', 927, 39),
    ('M', 1423, 138), ('M', 2302, 679), ('M', 2441, 682), ('ME', 572, 902), ('ME', 3550, 2903),
    ('MM', 3708, 3124), ('Ma', 2144, 554), ('Ma', 2592, 558), ('Man', 835, 2352),
    ('Men', 2379, 601), ('N', 2294, 541), ('N', 2462, 540), ('NA', 2406, 416), ('O', 543, 766),
    ('O', 3022, 403), ('O', 3421, 2919), ('OM', 1078, 2167), ('OO', 2380, 506),
    ('OO', 2380, 506), ('OO', 2380, 506), ('OOc', 2488, 421), ('Om', 591, 2159),
    ('Om', 761, 2077), ('Om', 907, 2075), ('P', 2378, 310), ('PB', 314, 1481),
    ('PB', 2228, 1389), ('PL', 753, 1502), ('PL', 2620, 1273), ('PLo', 775, 926),
    ('PM', 628, 2547), ('PM', 1065, 2544), ('PS', 835, 3691), ('PSIS', 2113, 2626),
    ('PSIS', 2356, 2620), ('PT', 259, 1553), ('PT', 2137, 1332), ('PTe', 679, 367),
    ('PTe', 3070, 3127), ('Pa', 1078, 1665), ('Pa', 2922, 1048), ('Pe', 726, 3839),
    ('Pe', 970, 3841), ('R', 2074, 3353), ('RA', 718, 2848), ('RA', 721, 2996),
    ('RA', 725, 3174), ('RA', 740, 3394), ('RA', 924, 3171), ('RA', 924, 3392),
    ('RA', 929, 2998), ('RA', 934, 2848), ('RF', 1688, 1704), ('RF', 3495, 880),
    ('S', 1826, 1820), ('S', 3632, 728), ('SA', 277, 2882), ('SA', 1388, 2878),
    ('SC', 1899, 607), ('SC', 2843, 601), ('SCa', 1892, 516), ('SCa', 2852, 509),
    ('SM', 603, 2124), ('SM', 1064, 2124), ('SM', 1189, 1042), ('SM', 3168, 1627),
    ('SMB', 2055, 3395), ('SMB', 2410, 3387), ('SP', 1134, 736), ('SP', 3494, 3490),
    ('SS', 1905, 3681), ('SS', 2585, 3702), ('Se', 1487, 1036), ('Se', 3455, 1564),
    ('So', 391, 1099), ('So', 495, 1446), ('So', 2376, 1744), ('So', 2390, 1390),
    ('St', 803, 2160), ('St', 862, 2159), ('Ste', 1017, 1994), ('Ste', 2025, 669),
    ('Ster', 835, 2465), ('Sty', 2202, 681), ('Sty', 2542, 689), ('T', 155, 713),
    ('T', 3280, 2516), ('TA', 627, 1626), ('TA', 2490, 1180), ('TFL', 343, 3621),
    ('TFL', 1329, 3634), ('TMa', 1871, 3378), ('TMa', 2599, 3375), ('TMi', 1847, 3492),
    ('TMi', 2628, 3495), ('TT', 362, 724), ('TT', 3335, 2747), ('Tem', 2113, 312),
    ('Tem', 2625, 309), ('Th', 771, 2119), ('Th', 896, 2118), ('Ti', 717, 1723),
    ('Ti', 1017, 1800), ('Ti', 2537, 1071), ('Ti', 2828, 922), ('Ti', 2902, 1151),
    ('Tr', 2089, 3718), ('Tr', 2394, 3717), ('U', 3471, 3200), ('VL', 1620, 1566),
    ('VL', 3476, 1026), ('VM', 1283, 1836), ('VM', 3092, 857), ('ZMa', 2232, 470),
    ('ZMa', 2519, 478),
]

HEAD = {'F', 'Tem', 'Ma', 'Bu', 'OO', 'OOc', 'ZM', 'ZMa', 'LLS', 'LLSAN', 'NA',
        'Na', 'N', 'DAO', 'DLI', 'LP', 'Men', 'DS', 'P', 'Oc', 'DAB', 'DPB', 'M',
        'Sty'}
BONE_LABELS = {'FH', 'Fe', 'Ti', 'Pa', 'Ca', 'MM', 'LM', 'GT', 'IC', 'ASIS', 'PSIS',
               'PS', 'C7', 'O', 'ME', 'LE', 'U', 'AP', 'SS', 'SMB', 'SP', 'Man',
               'Ster', 'CL'}
TENDON_LABELS = {'IT', 'GTe', 'TT', 'Apo'}
HAND_LABELS = {'TE', 'APB', 'FDI'}
FOOT_LABELS = {'EDB', 'AH'}
NECK_LABELS = {'St', 'Om', 'Th', 'OM'}
# Abréviation → clé de région (les subdivisions du pack viennent après).
KEY_OF = {
    'PM': 'pectoralis_major', 'SA': 'serratus_anterior', 'D': 'deltoid',
    'BB': 'biceps_brachii', 'B': 'brachialis', 'C': 'coracobrachialis',
    'T': 'triceps_brachii', 'A': 'anconeus_muscle', 'Br': 'brachioradialis_muscle',
    'ECRL': 'extensor_carpi_radialis_longus', 'ECRB': 'extensor_carpi_radialis_brevis',
    'ECU': 'extensor_carpi_ulnaris', 'ED': 'extensor_digitorum',
    'EDM': 'extensor_digiti_minimi', 'APL': 'abductor_pollicis_longus',
    'EPB': 'extensor_pollicis_brevis', 'FCR': 'flexor_carpi_radialis',
    'FCU': 'flexor_carpi_ulnaris', 'PLo': 'palmaris_longus_muscle',
    'FDS': 'flexor_digitorum_superficialis', 'PTe': 'pronator_teres',
    'Tr': 'trapezius', 'LD': 'latissimus_dorsi', 'TMa': 'teres_major',
    'TMi': 'teres_minor', 'In': 'infraspinatus', 'R': 'rhomboids',
    'LS': 'levator_scapulae', 'SC': 'splenius_capitis', 'SCa': 'semispinalis_capitis',
    'Ste': 'sternocleidomastoid', 'ES': 'erector_spinae',
    'RA': 'rectus_abdominis', 'EO': 'external_oblique',
    'GMa': 'gluteus_maximus', 'GMe': 'gluteus_medius', 'TFL': 'tensor_fasciae_latae',
    'I': 'iliopsoas', 'Pe': 'pectineus', 'AL': 'adductor_longus',
    'AM': 'adductor_magnus', 'G': 'gracilis', 'S': 'sartorius',
    'RF': 'rectus_femoris', 'VL': 'vastus_lateralis', 'VM': 'vastus_medialis',
    'BF': 'biceps_femoris_long', 'Se': 'semitendinosus', 'SM': 'semimembranosus',
    'Ga': 'gastrocnemius', 'So': 'soleus', 'TA': 'tibialis_anterior',
    'EDL': 'extensor_digitorum_longus', 'PL': 'fibularis_longus',
    'PB': 'fibularis_brevis', 'PT': 'fibularis_tertius',
    'FDL': 'flexor_digitorum_longus',
}
NECK_KEY = 'neck_muscles'
SUBDIVIDED = {
    'deltoid': ('deltoid_anterior', 'deltoid_lateral', 'deltoid_posterior'),
    'trapezius': ('trapezius_upper', 'trapezius_middle', 'trapezius_lower'),
    'pectoralis_major': ('pectoralis_major_clavicular', 'pectoralis_major_sternocostal',
                         'pectoralis_major_abdominal'),
    'gastrocnemius': ('gastrocnemius_medial', 'gastrocnemius_lateral'),
}


def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for block in iter(lambda: f.read(1 << 20), b''):
            h.update(block)
    return h.hexdigest()


# ------------------------------------------------------------- lecture --

def read_obj(data):
    """OBJ ZBrush : v, vt, f v/vt (triangles)."""
    import numpy as np
    V, VT, F, FT = [], [], [], []
    for line in data.decode('ascii', 'ignore').splitlines():
        if line.startswith('v '):
            V.append(line.split()[1:4])
        elif line.startswith('vt '):
            VT.append(line.split()[1:3])
        elif line.startswith('f '):
            parts = [p.split('/') for p in line.split()[1:]]
            for i in range(1, len(parts) - 1):
                F.append((parts[0][0], parts[i][0], parts[i + 1][0]))
                FT.append((parts[0][1], parts[i][1], parts[i + 1][1]))
    V = np.array(V, dtype=np.float64)
    VT = np.array(VT, dtype=np.float64)
    F = np.array(F, dtype=np.int64) - 1
    FT = np.array(FT, dtype=np.int64) - 1
    return V, VT, F, FT


def load_source(zip_path, log):
    from PIL import Image
    Image.MAX_IMAGE_PIXELS = None
    with zipfile.ZipFile(zip_path) as z:
        V, VT, F, FT = read_obj(z.read(OBJ_IN_ZIP))
        tex = Image.open(io.BytesIO(z.read(TEXTURE_IN_ZIP))).convert('RGB')
    log(f'source : {len(V)} sommets, {len(F)} triangles, texture {tex.size[0]}²')
    return V, VT, F, FT, tex


# -------------------------------------------------------- segmentation --

def segment_texture(tex, log):
    """Régions d'image (SEG_SIZE²) : classe de palette par texel, texte /
    dégradés rebouchés, composantes connexes par classe."""
    import numpy as np
    from scipy import ndimage
    im = np.asarray(tex.resize((SEG_SIZE, SEG_SIZE))).astype(np.int32)
    pal = np.array(PALETTE)
    d = ((im[:, :, None, :] - pal[None, None]) ** 2).sum(-1)
    cls = d.argmin(-1)
    far = d.min(-1) > 30 ** 2
    hole = (cls == CLASS_TEXT) | (cls == CLASS_BLEND) | far
    # Lisérés gris entre deux plages (mélange des teintes voisines dans le
    # JPEG) : gris trop fin pour être un tendon, rebouché comme le texte.
    grey = cls == CLASS_GREY
    hole |= grey & ~ndimage.binary_opening(grey, iterations=3)
    idx = ndimage.distance_transform_edt(hole, return_distances=False, return_indices=True)
    cls = cls[idx[0], idx[1]]
    regions = np.zeros(cls.shape, np.int32)
    n = 0
    for c in range(len(PALETTE)):
        lab, k = ndimage.label(cls == c)
        regions[lab > 0] = lab[lab > 0] + n
        n += k
    log(f'texture : {n} régions d\'image')
    return regions, cls


def face_regions(VT, FT, regions):
    import numpy as np
    uv = VT[FT].mean(1)
    x = np.clip((uv[:, 0] * SEG_SIZE).astype(int), 0, SEG_SIZE - 1)
    y = np.clip(((1 - uv[:, 1]) * SEG_SIZE).astype(int), 0, SEG_SIZE - 1)
    return regions[y, x]


def face_pairs(F):
    """Paires de triangles adjacents (arête commune)."""
    import numpy as np
    e = np.concatenate([F[:, [0, 1]], F[:, [1, 2]], F[:, [2, 0]]])
    e = np.sort(e, axis=1)
    f = np.tile(np.arange(len(F)), 3)
    key = e[:, 0] * (F.max() + 1) + e[:, 1]
    order = np.argsort(key, kind='stable')
    key, f = key[order], f[order]
    same = key[1:] == key[:-1]
    return np.stack([f[:-1][same], f[1:][same]], 1)


def components(F, freg, pairs, log):
    import numpy as np
    from scipy.sparse import coo_matrix
    from scipy.sparse.csgraph import connected_components
    keep = freg[pairs[:, 0]] == freg[pairs[:, 1]]
    p = pairs[keep]
    g = coo_matrix((np.ones(len(p)), (p[:, 0], p[:, 1])), shape=(len(F), len(F)))
    n, comp = connected_components(g, directed=False)
    comp = merge_small(comp, pairs, MERGE_BELOW)
    log(f'maillage : {n} composantes, {comp.max() + 1} après fusion des miettes')
    return comp


def merge_small(comp, pairs, threshold):
    """Fusionne les composantes < threshold triangles dans la voisine avec
    laquelle elles partagent le plus d'arêtes."""
    import numpy as np
    comp = comp.copy()
    for _ in range(50):
        n = comp.max() + 1
        size = np.bincount(comp, minlength=n)
        small = (size < threshold) & (size > 0)
        if not small.any():
            break
        a, b = comp[pairs[:, 0]], comp[pairs[:, 1]]
        m = a != b
        both = np.concatenate([np.stack([a[m], b[m]], 1), np.stack([b[m], a[m]], 1)])
        both = both[small[both[:, 0]]]
        if len(both) == 0:
            break
        key = both[:, 0].astype(np.int64) * n + both[:, 1]
        uk, cnt = np.unique(key, return_counts=True)
        src, dst = uk // n, uk % n
        order = np.lexsort((-cnt, small[dst].astype(int), src))
        src, dst = src[order], dst[order]
        first = np.ones(len(src), bool)
        first[1:] = src[1:] != src[:-1]
        mapping = np.arange(n)
        mapping[src[first]] = dst[first]
        for _ in range(10):
            mapping = mapping[mapping]
        comp = mapping[comp]
    return np.unique(comp, return_inverse=True)[1]


# ------------------------------------------------------------- nommage --

def raster_faces(VT, FT):
    """Triangle sous chaque texel (SEG_SIZE²), −1 hors des îlots UV."""
    import numpy as np
    from PIL import Image, ImageDraw
    uv = VT.copy()
    uv[:, 0] *= SEG_SIZE
    uv[:, 1] = (1 - uv[:, 1]) * SEG_SIZE
    im = Image.new('I', (SEG_SIZE, SEG_SIZE), -1)
    dr = ImageDraw.Draw(im)
    P = uv[FT]
    for i in range(len(FT)):
        p = P[i]
        dr.polygon([(p[0, 0], p[0, 1]), (p[1, 0], p[1, 1]), (p[2, 0], p[2, 1])], fill=i)
    return np.asarray(im).astype(np.int32)


def name_components(V, F, comp, freg, cls_img, pairs, faceimg, log):
    """Étiquette par composante (abréviation, 'os', 'contexte', 'tete',
    'main', 'pied', 'cou'), composantes coupées si besoin."""
    import numpy as np
    from scipy.sparse import coo_matrix
    from scipy.sparse.csgraph import dijkstra
    C = V[F].mean(1)
    nF = len(F)
    # classe par triangle : classe du texel du centre (après rebouchage)
    fclass = _face_class(V, F, freg, cls_img, faceimg)
    seeds = []
    for abbr, x, y in LABELS:
        f = _face_under(faceimg, x * SEG_SIZE // 4096, y * SEG_SIZE // 4096)
        if f >= 0:
            seeds.append((abbr, f))
    w = np.linalg.norm(C[pairs[:, 0]] - C[pairs[:, 1]], axis=1)
    G = coo_matrix((np.r_[w, w], (np.r_[pairs[:, 0], pairs[:, 1]],
                                   np.r_[pairs[:, 1], pairs[:, 0]])), shape=(nF, nF)).tocsr()
    label_of = np.full(nF, '', dtype=object)
    by_comp = defaultdict(list)
    for a, f in seeds:
        by_comp[comp[f]].append((a, f))
    comp = comp.copy()
    nxt = comp.max() + 1
    split = 0
    for c, lst in by_comp.items():
        names = sorted({a for a, _ in lst})
        if all(a in HEAD for a in names):
            names = [names[0]]
        m = np.nonzero(comp == c)[0]
        if len(names) == 1:
            label_of[m] = names[0]
            continue
        # plusieurs muscles de même couleur : plus court chemin depuis chaque
        # étiquette, dans la composante
        sub = G[m][:, m]
        idx = {f: i for i, f in enumerate(m)}
        chosen = [(a, f) for a, f in lst if a in names]
        D = dijkstra(sub, indices=[idx[f] for _, f in chosen])
        best = np.argmin(D, axis=0)
        for k, (a, _) in enumerate(chosen):
            sel = m[best == k]
            label_of[sel] = a
            if k > 0:
                comp[sel] = nxt
                nxt += 1
                split += 1
    # composantes à cheval sur la ligne médiane
    bilateral = 0
    for c in np.unique(comp):
        m = np.nonzero(comp == c)[0]
        xs = C[m, 0]
        if (xs > .01).sum() > 100 and (xs < -.01).sum() > 100 and abs(xs.mean()) < .05:
            comp[m[xs < 0]] = nxt
            nxt += 1
            bilateral += 1
    comp = np.unique(comp, return_inverse=True)[1]
    nc = comp.max() + 1
    clabel = [''] * nc
    for c in range(nc):
        ls = [l for l in label_of[comp == c] if l]
        if ls:
            clabel[c] = Counter(ls).most_common(1)[0][0]
    cclass = np.array([np.bincount(fclass[comp == c]).argmax() for c in range(nc)])
    ccen = np.array([C[comp == c].mean(0) for c in range(nc)])
    csize = np.bincount(comp)
    # os et tendons : par la couleur, sauf les érecteurs (gris dans la texture)
    named = KEY_OF.keys() | HAND_LABELS | FOOT_LABELS | NECK_LABELS | HEAD
    for c in range(nc):
        if clabel[c] in BONE_LABELS or (cclass[c] == CLASS_BONE and clabel[c] not in named):
            clabel[c] = 'os'
        elif clabel[c] in TENDON_LABELS or (cclass[c] == CLASS_GREY and clabel[c] not in named):
            clabel[c] = 'contexte'
        elif clabel[c] in HEAD:
            clabel[c] = 'tete'
        elif clabel[c] in HAND_LABELS:
            clabel[c] = 'main'
        elif clabel[c] in FOOT_LABELS:
            clabel[c] = 'pied'
        elif clabel[c] in NECK_LABELS:
            clabel[c] = 'cou'
        elif clabel[c] == 'ADM':
            clabel[c] = 'main' if ccen[c][1] > .8 else 'pied'
        elif clabel[c] == 'SM':
            clabel[c] = 'SMn' if ccen[c][1] > 1.4 else 'SM'
        elif clabel[c] == 'C' and ccen[c][1] > .8 * V[:, 1].max():
            clabel[c] = 'cou'  # « C » du cou, pas le coraco-brachial
    # voisines de même couleur
    a, b = comp[pairs[:, 0]], comp[pairs[:, 1]]
    m = a != b
    adj = defaultdict(Counter)
    for x, y in zip(a[m], b[m]):
        adj[x][y] += 1
        adj[y][x] += 1
    propagated = mirrored = 0
    for _ in range(5):
        for c in range(nc):
            if clabel[c]:
                continue
            cands = [(n, k) for n, k in adj[c].items()
                     if clabel[n] and cclass[n] == cclass[c] and clabel[n] in KEY_OF]
            cands = [(n, k) for n, k in cands
                     if np.sign(ccen[n][0]) == np.sign(ccen[c][0]) or abs(ccen[c][0]) < .02]
            if cands:
                clabel[c] = clabel[max(cands, key=lambda t: t[1])[0]]
                propagated += 1
    # composante plus grossière que son symétrique (deux muscles de même
    # couleur fusionnés d'un côté, séparés de l'autre par leurs étiquettes) :
    # coupée selon les étiquettes du côté opposé
    from scipy.spatial import cKDTree
    H = V[:, 1].max() - V[:, 1].min()
    resplit = 0
    nxt = nc
    for _ in range(2):
        face_label = np.array([clabel[c] for c in comp], dtype=object)
        muscles = list(KEY_OF) + ['cou', 'SMn']
        named_faces = np.nonzero(np.isin(face_label, muscles))[0]
        tree = cKDTree(C[named_faces])
        changed = False
        for c in range(nc):
            if clabel[c] not in muscles or csize[c] < 2 * MERGE_BELOW:
                continue
            m = np.nonzero(comp == c)[0]
            d, i = tree.query(C[m] * [-1, 1, 1])
            if np.median(d) > .012 * H:
                continue
            mirrored_labels = face_label[named_faces[i]]
            counts = Counter(mirrored_labels)
            major = [l for l, k in counts.items() if k >= .2 * len(m)]
            if len(major) < 2 or clabel[c] not in major:
                continue
            for l in major:
                if l == clabel[c]:
                    continue
                sel = m[mirrored_labels == l]
                comp[sel] = nxt
                clabel.append(l)
                cclass = np.append(cclass, cclass[c])
                ccen = np.vstack([ccen, C[sel].mean(0)])
                csize = np.append(csize, len(sel))
                nxt += 1
                nc += 1
                changed = True
                resplit += 1
            csize[c] = (comp == c).sum()
            ccen[c] = C[comp == c].mean(0)
        if not changed:
            break
    comp = np.unique(comp, return_inverse=True)[1]
    nc = comp.max() + 1
    # (les indices de composantes restent alignés : np.unique conserve l'ordre)
    # symétrique : chaque triangle de la composante est reflété (x → −x) et
    # prend l'étiquette du triangle nommé le plus proche ; la composante
    # reçoit la majorité si la distance médiane est petite
    face_label = np.array([clabel[c] for c in comp], dtype=object)
    named_faces = np.nonzero(np.isin(face_label, list(KEY_OF)))[0]
    tree = cKDTree(C[named_faces])
    for c in range(nc):
        if clabel[c]:
            continue
        m = np.nonzero(comp == c)[0]
        d, i = tree.query(C[m] * [-1, 1, 1])
        if np.median(d) < .012 * H:
            clabel[c] = Counter(face_label[named_faces[i]]).most_common(1)[0][0]
            mirrored += 1
    # reste : position
    positional = 0
    for c in range(nc):
        if clabel[c]:
            continue
        x, y, _ = ccen[c]
        yr = (y - V[:, 1].min()) / H
        # plus proche composante nommée de même couleur, même côté, à moins
        # de 8 % de la hauteur
        best = None
        for o in range(nc):
            if clabel[o] not in KEY_OF or cclass[o] != cclass[c]:
                continue
            if np.sign(ccen[o][0]) != np.sign(x):
                continue
            dd = np.linalg.norm(ccen[o] - ccen[c])
            if dd < .08 * H and (best is None or dd < best[0]):
                best = (dd, o)
        if best:
            clabel[c] = clabel[best[1]]
        elif yr > .86:
            clabel[c] = 'tete'
        elif yr > .79:
            clabel[c] = 'cou'
        elif abs(x) > .38 * H / 1.96 and .42 < yr < .62:
            clabel[c] = 'main'
        elif yr < .07:
            clabel[c] = 'pied'
        else:
            clabel[c] = 'contexte'
        positional += 1
    log(f'nommage : {len(seeds)} étiquettes, {split} composantes séparées par '
        f'plus court chemin, {bilateral} coupées gauche / droite, {propagated} '
        f'nommées par voisinage, {resplit} recoupées d\'après le côté opposé, '
        f'{mirrored} nommées par symétrie, {positional} par position')
    return comp, clabel, ccen, csize


def _face_class(V, F, freg, cls_img, faceimg):
    """Classe de couleur par triangle : majorité des texels du triangle."""
    import numpy as np
    valid = faceimg >= 0
    f = faceimg[valid]
    c = cls_img[valid]
    n = len(F)
    hist = np.zeros((n, len(PALETTE)), np.int32)
    np.add.at(hist, (f, c), 1)
    cls = hist.argmax(1)
    # triangles sans texel (petits) : classe du centre
    cls[hist.sum(1) == 0] = CLASS_GREY
    return cls


def _face_under(faceimg, x, y):
    f = faceimg[y, x]
    if f >= 0:
        return int(f)
    for r in range(1, 30):
        win = faceimg[max(0, y - r):y + r + 1, max(0, x - r):x + r + 1]
        w = win[win >= 0]
        if len(w):
            return int(w[0])
    return -1


# ------------------------------------------------------- régions finales --

def assign_regions(V, F, comp, clabel):
    """Nom de nœud par triangle : '<clé>_<côté>', 'os', 'contexte', 'head'."""
    import numpy as np
    C = V[F].mean(1)
    side = np.where(C[:, 0] >= 0, 'left', 'right')
    node = np.empty(len(F), dtype=object)
    landmarks = {}
    for c, lab in enumerate(clabel):
        m = comp == c
        if lab == 'os':
            node[m] = 'os'
        elif lab == 'contexte':
            node[m] = 'contexte'
        elif lab == 'tete':
            node[m] = 'head'
        elif lab == 'main':
            node[m] = np.char.add('hand_', side[m])
        elif lab == 'pied':
            node[m] = np.char.add('foot_', side[m])
        elif lab == 'cou':
            node[m] = np.char.add(NECK_KEY + '_', side[m])
        elif lab == 'SMn':
            node[m] = np.char.add('scalenus_medius_', side[m])
        else:
            key = KEY_OF[lab]
            node[m] = np.char.add(key + '_', side[m])
    return node


def subdivide(V, F, node, y_c7, y_ss, log):
    import numpy as np
    C = V[F].mean(1)
    for side in ('left', 'right'):
        sx = 1 if side == 'left' else -1
        # deltoïde : angle autour de l'axe vertical passant par son centre
        m = node == f'deltoid_{side}'
        if m.any():
            cen = C[m].mean(0)
            ang = np.degrees(np.arctan2(C[m, 2] - cen[2], (C[m, 0] - cen[0]) * sx))
            part = np.where(ang > 40, 'anterior', np.where(ang < -40, 'posterior', 'lateral'))
            node[np.nonzero(m)[0]] = np.char.add(np.char.add('deltoid_', part), '_' + side)
        # trapèze : hauteur (C7 et épine de la scapula, sinon tiers)
        m = node == f'trapezius_{side}'
        if m.any():
            y = C[m, 1]
            lo, hi = y.min(), y.max()
            top = y_c7 if y_c7 else lo + .70 * (hi - lo)
            mid = y_ss if y_ss else lo + .45 * (hi - lo)
            part = np.where(y > top, 'upper', np.where(y > mid, 'middle', 'lower'))
            node[np.nonzero(m)[0]] = np.char.add(np.char.add('trapezius_', part), '_' + side)
        # grand pectoral : hauteur
        m = node == f'pectoralis_major_{side}'
        if m.any():
            y = C[m, 1]
            lo, hi = y.min(), y.max()
            part = np.where(y > hi - .28 * (hi - lo), 'clavicular',
                            np.where(y < lo + .18 * (hi - lo), 'abdominal', 'sternocostal'))
            node[np.nonzero(m)[0]] = np.char.add(np.char.add('pectoralis_major_', part), '_' + side)
        # gastrocnémien : médial vers la ligne médiane
        m = node == f'gastrocnemius_{side}'
        if m.any():
            cx = C[m, 0].mean()
            part = np.where(np.abs(C[m, 0]) < abs(cx), 'medial', 'lateral')
            node[np.nonzero(m)[0]] = np.char.add(np.char.add('gastrocnemius_', part), '_' + side)


# ---------------------------------------------------------- décimation --

def decimate(V, F, node, log):
    """Décimation globale, régions reportées par plus proche centre de
    triangle d'origine."""
    import numpy as np
    import fast_simplification
    from scipy.spatial import cKDTree
    ratio = 1 - TRIANGLE_BUDGET / len(F) * .99
    P, Fd = fast_simplification.simplify(V.astype(np.float32), F.astype(np.int32),
                                         target_reduction=ratio)
    P = P.astype(np.float64)
    Fd = Fd.astype(np.int64)
    tree = cKDTree(V[F].mean(1))
    near = tree.query(P[Fd].mean(1))[1]
    nd = node[near]
    log(f'décimation : {len(F)} → {len(Fd)} triangles, {len(P)} sommets')
    return P, Fd, nd


def vertex_normals(P, Fd):
    import numpy as np
    n = np.zeros_like(P)
    a, b, c = P[Fd[:, 0]], P[Fd[:, 1]], P[Fd[:, 2]]
    fn = np.cross(b - a, c - a)
    for i in range(3):
        np.add.at(n, Fd[:, i], fn)
    l = np.linalg.norm(n, axis=1, keepdims=True)
    l[l == 0] = 1
    return n / l


TENDON_MIN = 20


def tendon_nodes(Fd, nd, log):
    """Tendons et aponévroses (`contexte`) : un nœud par composante connexe
    (`tendon_<k>`, gris translucide comme les muscles, jamais allumé, tri de
    transparence par nœud) ; les miettes (< TENDON_MIN triangles) rejoignent
    le nœud voisin qui partage le plus d'arêtes."""
    import numpy as np
    from scipy.sparse import coo_matrix
    from scipy.sparse.csgraph import connected_components
    nd = nd.copy()
    pairs = face_pairs(Fd)
    ctx = np.nonzero(nd == 'contexte')[0]
    if len(ctx) == 0:
        return nd
    idx = {f: i for i, f in enumerate(ctx)}
    inner = pairs[(nd[pairs[:, 0]] == 'contexte') & (nd[pairs[:, 1]] == 'contexte')]
    a = np.array([idx[f] for f in inner[:, 0]])
    b = np.array([idx[f] for f in inner[:, 1]])
    g = coo_matrix((np.ones(len(a)), (a, b)), shape=(len(ctx), len(ctx)))
    n, lab = connected_components(g, directed=False)
    size = np.bincount(lab)
    k = 0
    small = []
    for c in range(n):
        faces = ctx[lab == c]
        if size[c] >= TENDON_MIN:
            nd[faces] = f'tendon_{k}'
            k += 1
        else:
            small.append(faces)
    # miettes : voisin majoritaire (hors contexte), sinon os
    for faces in small:
        m = np.isin(pairs, faces)
        neigh = np.concatenate([pairs[m[:, 0], 1], pairs[m[:, 1], 0]])
        names = [nd[f] for f in neigh if nd[f] != 'contexte']
        nd[faces] = Counter(names).most_common(1)[0][0] if names else 'os'
    log(f'tendons : {k} nœuds, {len(small)} miettes rattachées')
    return nd


def split_meshes(P, Fd, nd, normals):
    """Une maille par nœud (sommets dupliqués), normales du maillage entier."""
    import numpy as np
    meshes = []
    for name in sorted(set(nd)):
        faces = Fd[nd == name]
        used, inv = np.unique(faces, return_inverse=True)
        meshes.append({'nom': name, 'positions': P[used], 'normales': normals[used],
                       'indices': inv.reshape(-1, 3).ravel()})
    return meshes


# ------------------------------------------------------------- sorties --

MATERIALS = [
    {'name': 'muscle', 'pbrMetallicRoughness': {'baseColorFactor': [.62, .59, .59, 1],
                                                'metallicFactor': 0, 'roughnessFactor': .78}},
    {'name': 'os', 'pbrMetallicRoughness': {'baseColorFactor': [.29, .27, .27, 1],
                                            'metallicFactor': 0, 'roughnessFactor': .85}},
    {'name': 'contexte', 'pbrMetallicRoughness': {'baseColorFactor': [.18, .16, .16, 1],
                                                  'metallicFactor': 0, 'roughnessFactor': .85}},
]


def write_glb(path, meshes):
    import numpy as np
    chunks, views, accessors = [], [], []
    offset = 0

    def add(arr, target, **acc):
        nonlocal offset
        data = np.ascontiguousarray(arr).tobytes()
        pad = (-len(data)) % 4
        views.append({'buffer': 0, 'byteOffset': offset, 'byteLength': len(data),
                      'target': target})
        chunks.append(data + b'\0' * pad)
        offset += len(data) + pad
        accessors.append(dict(bufferView=len(views) - 1, **acc))
        return len(accessors) - 1

    nodes, gl_meshes = [], []
    for k, m in enumerate(meshes):
        pos = m['positions'].astype(np.float32)
        attrs = {
            'POSITION': add(pos, 34962, componentType=5126, count=len(pos), type='VEC3',
                            min=[float(v) for v in pos.min(0)],
                            max=[float(v) for v in pos.max(0)]),
            'NORMAL': add(m['normales'].astype(np.float32), 34962, componentType=5126,
                          count=len(pos), type='VEC3'),
        }
        idx = m['indices']
        itype = 5125 if idx.max() > 65535 else 5123
        ind = add(idx.astype(np.uint32 if itype == 5125 else np.uint16), 34963,
                  componentType=itype, count=len(idx), type='SCALAR')
        mat = {'os': 1, 'head': 2}.get(m['nom'], 0)
        gl_meshes.append({'name': m['nom'], 'primitives': [
            {'attributes': attrs, 'indices': ind, 'material': mat}]})
        nodes.append({'name': m['nom'], 'mesh': k})
    gltf = {
        'asset': {'version': '2.0',
                  'generator': 'Kalis Track tools/anatomy/build_model.py (M56 correction 2)'},
        'scene': 0, 'scenes': [{'name': 'Mannequin', 'nodes': list(range(len(meshes)))}],
        'nodes': nodes, 'meshes': gl_meshes, 'materials': MATERIALS,
        'accessors': accessors, 'bufferViews': views, 'buffers': [{'byteLength': offset}],
    }
    js = json.dumps(gltf, separators=(',', ':')).encode()
    js += b' ' * ((-len(js)) % 4)
    blob = b''.join(chunks)
    with open(path, 'wb') as f:
        f.write(struct.pack('<4sII', b'glTF', 2, 12 + 8 + len(js) + 8 + len(blob)))
        f.write(struct.pack('<I4s', len(js), b'JSON'))
        f.write(js)
        f.write(struct.pack('<I4s', len(blob), b'BIN\0'))
        f.write(blob)


def region_entries(names):
    """Entrées de la carte pour les nœuds de régions."""
    pack = pack_muscles()
    out = []
    for name in names:
        if name in ('os', 'head') or name.startswith('tendon_'):
            continue
        key, side = name.rsplit('_', 1)
        # Volumes des mains et des pieds (M2) : nœuds `hand_left`…, clé des
        # muscles intrinsèques.
        key = {'hand': 'hand_intrinsic', 'foot': 'foot_intrinsic'}.get(key, key)
        packs = PACK_OF_KEY[key]
        group = pack[packs[0]][0] if packs else GROUP_OF_KEY[key]
        couche = 'volume' if key in ('hand_intrinsic', 'foot_intrinsic') else 'superficiel'
        out.append({'id': name, 'cle': key, 'cote': side, 'nom': FR[key],
                    'nom_cote': f'{FR[key]} ({SIDE_FR[side]})', 'groupe': group,
                    'pack': packs, 'couche': couche})
    return out


def glb_meshes(path):
    """Positions et indices de chaque nœud d'un GLB écrit par [write_glb]."""
    import numpy as np
    data = Path(path).read_bytes()
    json_len, _ = struct.unpack('<I4s', data[12:20])
    gltf = json.loads(data[20:20 + json_len])
    blob = data[20 + json_len + 8:]

    def read(i, dtype):
        acc = gltf['accessors'][i]
        view = gltf['bufferViews'][acc['bufferView']]
        n = {'VEC3': 3, 'SCALAR': 1}[acc['type']]
        return np.frombuffer(blob, dtype=dtype, count=acc['count'] * n,
                             offset=view['byteOffset'] + acc.get('byteOffset', 0))

    out = {}
    for node in gltf['nodes']:
        prim = gltf['meshes'][node['mesh']]['primitives'][0]
        pos = read(prim['attributes']['POSITION'], np.float32).reshape(-1, 3)
        itype = gltf['accessors'][prim['indices']]['componentType']
        idx = read(prim['indices'], np.uint32 if itype == 5125 else np.uint16)
        out[node['name']] = (pos.astype(np.float64), idx.astype(np.int64))
    return out


def mesh_area(positions, indices):
    """Aire (m²) d'un maillage de triangles."""
    import numpy as np
    t = indices.reshape(-1, 3)
    a, b, c = positions[t[:, 0]], positions[t[:, 1]], positions[t[:, 2]]
    return float(0.5 * np.linalg.norm(np.cross(b - a, c - a), axis=1).sum())


def add_areas(entries, meshes):
    """M6b : aire de chaque région (m², 5 décimales), pour la vue de départ
    de la fiche (surface des muscles principaux vus de face et de dos)."""
    for e in entries:
        pos, idx = meshes[e['id']]
        e['aire'] = round(mesh_area(pos, idx), 5)
    return entries


def update_areas(log=print):
    """M6b : ajoute ou recalcule `aire` dans la carte existante depuis le GLB
    d'exécution (sans l'archive achetée)."""
    mapping = json.loads(OUT_MAP.read_text(encoding='utf-8'))
    add_areas(mapping['regions'], glb_meshes(OUT_GLB))
    OUT_MAP.write_text(json.dumps(mapping, ensure_ascii=False, indent=1) + '\n',
                       encoding='utf-8')
    log(f'aires : {len(mapping["regions"])} régions')


def build(zip_path, render_dir=None, log=print):
    import numpy as np
    zip_path = Path(zip_path)
    digest = sha256(zip_path)
    log(f'archive : {zip_path.name}, sha256 {digest}')
    V, VT, F, FT, tex = load_source(zip_path, log)
    regions, cls_img = segment_texture(tex, log)
    freg = face_regions(VT, FT, regions)
    pairs = face_pairs(F)
    comp = components(F, freg, pairs, log)
    faceimg = raster_faces(VT, FT)
    comp, clabel, ccen, csize = name_components(V, F, comp, freg, cls_img, pairs,
                                                faceimg, log)
    y_c7 = _abbr_height(V, F, comp, clabel, faceimg, 'C7')
    y_ss = _abbr_height(V, F, comp, clabel, faceimg, 'SS')
    node = assign_regions(V, F, comp, clabel)
    subdivide(V, F, node, y_c7, y_ss, log)
    # échelle
    lo = V[:, 1].min()
    scale = HEIGHT / (V[:, 1].max() - lo)
    Vs = (V - [0, lo, 0]) * scale
    Vs[:, 0] -= (Vs[:, 0].max() + Vs[:, 0].min()) / 2
    P, Fd, nd = decimate(Vs, F, node, log)
    nd = tendon_nodes(Fd, nd, log)
    normals = vertex_normals(P, Fd)
    meshes = split_meshes(P, Fd, nd, normals)
    OUT_GLB.parent.mkdir(parents=True, exist_ok=True)
    write_glb(OUT_GLB, meshes)
    names = [m['nom'] for m in meshes]
    entries = add_areas(region_entries(names),
                        {m['nom']: (m['positions'].astype(np.float64),
                                    m['indices'].astype(np.int64)) for m in meshes})
    tris = {m['nom']: len(m['indices']) // 3 for m in meshes}
    total = sum(tris.values())
    pack = pack_muscles()
    covered = {p for e in entries for p in e['pack']}
    absent = sorted(set(pack) - covered)
    mapping = {
        'schema': 2,
        'source': {'nom': SOURCE_NAME, 'archive': zip_path.name, 'sha256': digest,
                   'licence': 'achat (licence commerciale du vendeur), non redistribuable'},
        'groupes': APP_GROUPS,
        'triangles': total,
        'regions': entries,
        'retirees': [],
        'caches_au_repos': [],
        'muscles_sans_region': absent,
    }
    OUT_MAP.write_text(json.dumps(mapping, ensure_ascii=False, indent=1) + '\n',
                       encoding='utf-8')
    report = {
        'source': mapping['source'],
        'source_triangles': int(len(F)),
        'composantes': int(len(clabel)),
        'triangles': {'total': total, 'os': tris.get('os', 0),
                      'tendons': sum(v for k, v in tris.items() if k.startswith('tendon_')),
                      'head': tris.get('head', 0), 'par_noeud': tris},
        'regions': len(entries),
        'muscles_sans_region': absent,
        'hauteur': HEIGHT,
        'poids_glb': OUT_GLB.stat().st_size,
        'etiquettes': {a: int(sum(1 for l in clabel if l == a)) for a, _, _ in LABELS},
    }
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    log(f'GLB : {OUT_GLB.stat().st_size} octets, {total} triangles, {len(entries)} régions ; '
        f'muscles du pack sans région : {len(absent)}')
    if render_dir:
        render(P, Fd, nd, Path(render_dir), log)
    return report


def _abbr_height(V, F, comp, clabel, faceimg, abbr):
    """Hauteur moyenne (y, repère source) des triangles sous les étiquettes
    d'une abréviation (repères osseux des subdivisions)."""
    ys = []
    for a, x, y in LABELS:
        if a != abbr:
            continue
        f = _face_under(faceimg, x * SEG_SIZE // 4096, y * SEG_SIZE // 4096)
        if f >= 0:
            ys.append(V[F[f]].mean(0)[1])
    return sum(ys) / len(ys) if ys else None


def render(P, Fd, nd, out, log):
    """Planches de contrôle (face, dos, profils), une couleur par nœud."""
    import numpy as np
    from PIL import Image, ImageDraw
    out.mkdir(parents=True, exist_ok=True)
    names = sorted(set(nd))
    rng = np.random.default_rng(7)
    pal = {n: rng.integers(70, 255, 3) for n in names}
    pal['os'] = np.array([120, 110, 100])
    for n in names:
        if n.startswith('tendon_'):
            pal[n] = np.array([60, 60, 60])
    pal['head'] = np.array([90, 80, 80])
    cols = np.array([pal[n] for n in nd])
    size = 1400
    for label, yaw in [('face', 0), ('dos', np.pi), ('gauche', np.pi / 2),
                       ('droite', -np.pi / 2)]:
        c, s = np.cos(yaw), np.sin(yaw)
        X = P[:, 0] * c + P[:, 2] * s
        Z = -P[:, 0] * s + P[:, 2] * c
        Y = P[:, 1]
        lo = np.array([X.min(), Y.min()])
        sc = (size - 40) / max(X.max() - lo[0], Y.max() - lo[1])
        px = (X - lo[0]) * sc + 20
        py = size - ((Y - lo[1]) * sc + 20)
        order = np.argsort(Z[Fd].mean(1))
        im = Image.new('RGB', (size, size), (20, 20, 20))
        dr = ImageDraw.Draw(im)
        pts = np.stack([px, py], 1)
        for f in order:
            t = pts[Fd[f]]
            dr.polygon([tuple(t[0]), tuple(t[1]), tuple(t[2])],
                       fill=tuple(int(v) for v in cols[f]))
        im.save(out / f'{label}.png')
    leg = Image.new('RGB', (520, 16 * len(names) + 10), (20, 20, 20))
    dr = ImageDraw.Draw(leg)
    for i, n in enumerate(names):
        dr.rectangle([5, 5 + 16 * i, 20, 17 + 16 * i], fill=tuple(int(v) for v in pal[n]))
        dr.text((26, 4 + 16 * i), n, fill=(255, 255, 255))
    leg.save(out / 'legende.png')
    log(f'planches : {out}')


def check():
    """Sorties cohérentes (sans la source)."""
    mapping = json.loads(OUT_MAP.read_text(encoding='utf-8'))
    ids = {r['id'] for r in mapping['regions']}
    assert len(ids) == len(mapping['regions'])
    assert mapping['triangles'] <= TRIANGLE_BUDGET
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--zip', help='Archive.zip de la release modele-achete')
    parser.add_argument('--render', help='dossier des planches de contrôle')
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--aires', action='store_true',
                        help='recalcule les aires des régions depuis le GLB (M6b)')
    args = parser.parse_args()
    if args.check:
        print('OK' if check() else 'KO')
        return
    if args.aires:
        update_areas()
        return
    if not args.zip:
        parser.error('--zip requis')
    build(args.zip, args.render)


if __name__ == '__main__':
    main()
