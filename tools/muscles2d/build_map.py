#!/usr/bin/env python3
"""M8 : carte 2D des muscles, d'après l'image détaillée du propriétaire,
réadaptée pour l'application.

5.9.1 (M8 correction 1) : nouvelle image (`tools/muscles2d/source_carte.png` :
face, dos, profil, sans légende ; chaque muscle est une zone colorée cernée
de noir).

5.10.0 (M8 correction 2, 30/09/2026 : « plusieurs passes pour quelque chose
de scientifiquement correct ») : la carte n'est plus découpée par groupe
mais **muscle par muscle** : chaque zone dessinée est une région anatomique
(`REGIONS` : grand dorsal, sous-épineux, vaste médial, soléaire…) reliée aux
muscles du pack qu'elle montre. Un exercice n'allume que les régions de ses
muscles ; les muscles profonds (psoas sous l'arcade, transverse, oblique
interne, petit pectoral, supra-épineux, vaste intermédiaire, petit fessier,
poplité…) ne sont pas dessinés : ils restent listés en texte. Chaque région
appartient à un filtre de l'écran Anatomie (16 groupes, lombaires compris)
ou à aucun (cou, psoas, couturier).

Méthode : zones colorées par couleur (k-moyennes) puis connexité (les
traits noirs séparent les muscles ; une zone = un muscle ou un morceau de
muscle ombré) ; chaque région est désignée par des **points posés à la
main** (`SEEDS`, coordonnées de l'image source, relus sur agrandissements
quadrillés) ; les zones sans point prennent la région de la zone voisine
qu'elles touchent directement (morceaux d'un même muscle ombré). Toute zone
restée sans région fait échouer la fabrication.

Sorties (`assets/muscles2d/<vue>/`) : `etiquettes.png` (niveau de gris =
rang de la région, 253 = extrémités sombres, 254 = peau / tendons),
`contour.png` (traits, masque alpha), `ombre.png` (modelé, masque alpha) ;
`assets/muscles2d/carte.json` et `lib/muscle_map_regions.dart` (table des
régions, générée). Aperçu de contrôle : `--apercu`.

  python3 tools/muscles2d/build_map.py [--apercu apercu.png]
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SRC = HERE / 'source_carte.png'
OUT = ROOT / 'assets/muscles2d'
DART = ROOT / 'lib/muscle_map_regions.dart'

# Filtres de l'écran Anatomie (15 groupes de la première image, plus
# lombaires et coiffe des rotateurs : relecture anatomique de 5.10.0).
GROUPS = [
    ('trapezes', 'Trapèzes'), ('deltoides', 'Deltoïdes'), ('coiffe', 'Coiffe des rotateurs'),
    ('pectoraux', 'Pectoraux'),
    ('dorsaux', 'Dorsaux'), ('biceps', 'Biceps'), ('triceps', 'Triceps'),
    ('avant_bras', 'Avant-bras'), ('abdominaux', 'Abdominaux'), ('obliques', 'Obliques'),
    ('lombaires', 'Lombaires'), ('fessiers', 'Fessiers'), ('quadriceps', 'Quadriceps'),
    ('ischios', 'Ischio-jambiers'), ('adducteurs', 'Adducteurs'), ('mollets', 'Mollets'),
    ('tibial', 'Tibial antérieur'),
]

# Régions dessinées : identifiant, nom, muscles du pack montrés, filtre.
# Un muscle profond (sous un autre : loge postérieure profonde de la jambe
# comprise) n'est rattaché à aucune région.
REGIONS = [
    ('trapeze_superieur', 'Trapèze supérieur', ['trapeze_superieur'], 'trapezes'),
    ('trapeze_moyen', 'Trapèze moyen', ['trapeze_moyen'], 'trapezes'),
    ('trapeze_inferieur', 'Trapèze inférieur', ['trapeze_inferieur'], 'trapezes'),
    ('rhomboides', 'Rhomboïdes', ['rhomboides'], 'trapezes'),
    ('extenseurs_cervicaux', 'Extenseurs du cou (splénius)', ['extenseurs_cervicaux'], None),
    ('sterno_cleido_mastoidien', 'Sterno-cléido-mastoïdien', ['sterno_cleido_mastoidien'],
     None),
    ('cou', 'Muscles du cou (sus- et sous-hyoïdiens, scalènes)', [], None),
    ('deltoide_anterieur', 'Deltoïde antérieur', ['deltoide_anterieur'], 'deltoides'),
    ('deltoide_moyen', 'Deltoïde moyen', ['deltoide_moyen'], 'deltoides'),
    ('deltoide_posterieur', 'Deltoïde postérieur', ['deltoide_posterieur'], 'deltoides'),
    ('sous_epineux', 'Sous-épineux et petit rond', ['infra_epineux', 'petit_rond'],
     'coiffe'),
    ('grand_rond', 'Grand rond', ['grand_rond'], 'dorsaux'),
    ('grand_dorsal', 'Grand dorsal', ['grand_dorsal'], 'dorsaux'),
    ('grand_pectoral', 'Grand pectoral',
     ['grand_pectoral_claviculaire', 'grand_pectoral_sterno_costal', 'grand_pectoral_abdominal'],
     'pectoraux'),
    ('dentele_anterieur', 'Dentelé antérieur', ['dentele_anterieur'], 'pectoraux'),
    ('biceps', 'Biceps brachial', ['biceps_chef_long', 'biceps_chef_court'], 'biceps'),
    ('brachial', 'Brachial', ['brachial'], 'biceps'),
    ('triceps_long', 'Triceps, chef long', ['triceps_chef_long'], 'triceps'),
    ('triceps_lateral', 'Triceps, chef latéral', ['triceps_chef_lateral'], 'triceps'),
    ('triceps_medial', 'Triceps, chef médial et anconé', ['triceps_chef_medial', 'ancone'],
     'triceps'),
    ('brachio_radial', 'Brachio-radial', ['brachio_radial'], 'avant_bras'),
    ('flechisseurs', 'Fléchisseurs du poignet et des doigts, rond pronateur',
     ['flechisseurs_du_poignet', 'flechisseurs_superficiels_des_doigts', 'rond_pronateur'],
     'avant_bras'),
    ('extenseurs', 'Extenseurs du poignet et des doigts',
     ['extenseurs_du_poignet', 'extenseurs_des_doigts'], 'avant_bras'),
    ('droit_abdomen', 'Grand droit de l’abdomen', ['droit_abdomen'], 'abdominaux'),
    ('oblique_externe', 'Oblique externe', ['oblique_externe'], 'obliques'),
    ('lombaires', 'Érecteurs du rachis (fascia thoraco-lombaire)',
     ['erecteurs_lombaires', 'erecteurs_thoraciques'], 'lombaires'),
    ('grand_fessier', 'Grand fessier', ['grand_fessier'], 'fessiers'),
    ('moyen_fessier', 'Moyen fessier', ['moyen_fessier'], 'fessiers'),
    ('tenseur_fascia_lata', 'Tenseur du fascia lata', ['tenseur_fascia_lata'], 'fessiers'),
    ('iliopsoas', 'Ilio-psoas', ['grand_psoas', 'iliaque'], None),
    ('couturier', 'Couturier', ['sartorius'], None),
    ('pectine', 'Pectiné', ['pectine'], 'adducteurs'),
    ('adducteurs', 'Long et grand adducteurs, gracile',
     ['long_adducteur', 'grand_adducteur', 'gracile'], 'adducteurs'),
    ('droit_femoral', 'Droit fémoral', ['droit_femoral'], 'quadriceps'),
    ('vaste_lateral', 'Vaste latéral', ['vaste_lateral'], 'quadriceps'),
    ('vaste_medial', 'Vaste médial', ['vaste_medial'], 'quadriceps'),
    ('biceps_femoral', 'Biceps fémoral', ['biceps_femoral', 'biceps_femoral_chef_court'],
     'ischios'),
    ('semi_tendineux', 'Semi-tendineux et semi-membraneux',
     ['semi_tendineux', 'semi_membraneux'], 'ischios'),
    ('gastrocnemien_medial', 'Gastrocnémien médial', ['gastrocnemien_medial'], 'mollets'),
    ('gastrocnemien_lateral', 'Gastrocnémien latéral', ['gastrocnemien_lateral'], 'mollets'),
    ('soleaire', 'Soléaire', ['soleaire'], 'mollets'),
    ('fibulaires', 'Long et court fibulaires (loge latérale)', ['fibulaires'], 'mollets'),
    ('tibial_anterieur', 'Tibial antérieur', ['tibial_anterieur'], 'tibial'),
    ('extenseurs_orteils', 'Extenseurs des orteils et de l’hallux',
     ['long_extenseur_des_orteils'], 'tibial'),
]
REGION_IDS = [r[0] for r in REGIONS]
SOMBRE, PEAU = 253, 254
K = 36  # classes de couleur (k-moyennes)
TRAP_DOS = (165, 215)  # faisceaux du trapèze de dos : limites sur l'axe (y)

# Corrections au pixel (relecture anatomique) là où deux muscles voisins
# de teintes proches forment une seule zone : dans le cadre (x0, y0, x1,
# y1), les pixels de la région `de` dont la teinte (degrés) est dans
# l'intervalle passent à la région `vers` (ou à la peau).
HUE_FIXES = [
    # flancs de face : digitations violettes du dentelé fondues dans les
    # bandes de l'oblique externe
    ((185, 255, 245, 375), 'oblique_externe', (250, 305), 'dentele_anterieur'),
    ((330, 255, 395, 375), 'oblique_externe', (250, 305), 'dentele_anterieur'),
    # coude latéral de face (côté droit du sujet) : coin rose du brachial
    ((118, 316, 132, 346), 'triceps_lateral', (300, 360), 'brachial'),
    ((118, 316, 132, 346), 'triceps_lateral', (0, 40), 'brachial'),
    # mollets de dos : bande rouge latérale = soléaire (et non fibulaires)
    ((690, 800, 712, 880), 'fibulaires', (340, 360), 'soleaire'),
    ((690, 800, 712, 880), 'fibulaires', (0, 15), 'soleaire'),
    ((850, 800, 880, 880), 'fibulaires', (340, 360), 'soleaire'),
    ((850, 800, 880, 880), 'fibulaires', (0, 15), 'soleaire'),
    # tendons de la loge postérieure profonde (cyan, en bas) : non dessinés
    ((728, 855, 750, 910), 'soleaire', (165, 205), None),
    ((820, 855, 842, 910), 'soleaire', (165, 205), None),
]

# Vues : (nom, x0, x1, axe du corps en x) ; image 1536 × 1024.
VIEWS = [('face', 0, 540, 288), ('dos', 540, 1040, 790), ('profil', 1040, 1536, None)]

# Points posés à la main (x, y de l'image source). `SYM` : côté gauche de
# l'image, recopié en miroir de l'axe (vues de face et de dos) ; `FIXE` :
# tel quel (jambes de face, colorées différemment à gauche et à droite ;
# profil).
SYM = {
    'face': {
        'trapeze_superieur': [(220, 160)],
        'sterno_cleido_mastoidien': [(265, 150), (245, 170)],
        'cou': [(288, 160), (265, 178)],
        'deltoide_moyen': [(143, 220)],
        'deltoide_anterieur': [(185, 215), (205, 195)],
        'grand_pectoral': [(235, 230), (255, 260)],
        'dentele_anterieur': [(198, 300)],
        'oblique_externe': [(228, 330), (222, 395)],
        'droit_abdomen': [(265, 300), (265, 330), (265, 365), (265, 420), (270, 450)],
        'biceps': [(165, 300), (178, 310)],
        'triceps_lateral': [(140, 290)],
        'brachial': [(165, 345)],
        'brachio_radial': [(115, 390)],
        'extenseurs': [(93, 420), (96, 400)],
        'flechisseurs': [(160, 400), (123, 430), (130, 437)],
        'tenseur_fascia_lata': [(200, 440)],
        'couturier': [(222, 450), (235, 490)],
        'iliopsoas': [(240, 450)],
        'pectine': [(258, 490)],
        'adducteurs': [(272, 560)],
        'droit_femoral': [(222, 540)],
        'vaste_lateral': [(185, 560), (186, 495)],
        'vaste_medial': [(245, 610)],
    },
    'dos': {
        'trapeze_superieur': [(775, 130), (730, 160)],
        'deltoide_moyen': [(655, 210)],
        'deltoide_posterieur': [(695, 190)],
        'sous_epineux': [(715, 220)],
        'grand_rond': [(705, 245)],
        'rhomboides': [(750, 250)],
        'grand_dorsal': [(720, 310), (760, 300)],
        'lombaires': [(770, 380)],
        'oblique_externe': [(722, 370)],
        'triceps_lateral': [(640, 300)],
        'triceps_long': [(672, 290)],
        'triceps_medial': [(655, 330)],
        'brachio_radial': [(613, 370)],
        'extenseurs': [(608, 421), (625, 407)],
        'flechisseurs': [(643, 412)],
        'moyen_fessier': [(705, 425)],
        'grand_fessier': [(740, 470)],
        'vaste_lateral': [(700, 580)],
        # loge postérieure, de dehors en dedans : biceps fémoral (fuseau
        # central et bande latérale), semi-tendineux et semi-membraneux
        # (bande médiale jusqu'au genou), grand adducteur (en haut, en
        # dedans, teinte plus sombre, s'arrête à mi-cuisse)
        'biceps_femoral': [(736, 577), (713, 634)],
        'semi_tendineux': [(755, 642)],
        'adducteurs': [(769, 554)],
        'gastrocnemien_lateral': [(705, 750)],
        'gastrocnemien_medial': [(748, 750)],
        'soleaire': [(730, 850), (743, 830)],
    },
}
FIXE = {
    'dos': {
        'extenseurs_cervicaux': [(765, 100), (806, 100)],
        # bord postérieur du sterno-cléido-mastoïdien (jusqu'au crâne)
        'sterno_cleido_mastoidien': [(759, 112), (817, 111)],
        'soleaire': [(825, 830), (708, 830)],
        'fibulaires': [(693, 840), (706, 880), (866, 843), (861, 890)],
    },
    'face': {
        # relecture anatomique (5.10.0) : zones repérées une à une
        'brachial': [(127, 338), (447, 334)],
        'flechisseurs': [(102, 439), (471, 437)],
        'dentele_anterieur': [(211, 334), (207, 289), (206, 278), (204, 308), (369, 294),
                              (381, 275)],
        'oblique_externe': [(230, 291), (346, 290), (352, 308), (347, 333)],
        'fibulaires': [(182, 740), (392, 760)],
        'tibial_anterieur': [(205, 760), (368, 760)],
        'extenseurs_orteils': [(195, 830), (203, 870), (385, 830), (358, 870)],
        'gastrocnemien_medial': [(243, 750), (333, 750)],
        'soleaire': [(240, 820), (340, 820)],
    },
    'profil': {
        'trapeze_superieur': [(1220, 150)],
        'extenseurs_cervicaux': [(1255, 140)],
        'sterno_cleido_mastoidien': [(1275, 120)],
        'cou': [(1272, 155)],
        'deltoide_posterieur': [(1215, 215)],
        'deltoide_moyen': [(1250, 210)],
        'deltoide_anterieur': [(1288, 215)],
        'grand_pectoral': [(1320, 230)],
        # pli axillaire postérieur : grand dorsal
        'grand_dorsal': [(1204, 240), (1201, 268)],
        # vue latérale : le chef latéral couvre la face externe du bras, le
        # chef long n'apparaît qu'en bord postérieur
        'triceps_lateral': [(1235, 273), (1246, 315), (1217, 264)],
        'triceps_long': [(1230, 326), (1214, 297)],
        'biceps': [(1262, 300), (1283, 300)],
        'dentele_anterieur': [(1302, 275), (1292, 325)],
        'oblique_externe': [(1315, 295), (1318, 320), (1315, 360), (1318, 395), (1318, 420)],
        'droit_abdomen': [(1337, 300), (1337, 350), (1337, 400), (1335, 450)],
        # brachio-radial : fuseau proximal antérieur (crête supracondylaire) ;
        # dessous et derrière : extenseurs (épicondyle latéral)
        'brachio_radial': [(1275, 361), (1272, 355), (1287, 395)],
        'extenseurs': [(1259, 390), (1277, 401), (1283, 424), (1287, 462), (1257, 425),
                       (1246, 374)],
        'flechisseurs': [(1310, 440)],
        'grand_fessier': [(1220, 470)],
        'vaste_lateral': [(1290, 620), (1265, 600)],
        'droit_femoral': [(1316, 615)],
        'biceps_femoral': [(1240, 600), (1242, 640)],
        'semi_tendineux': [(1225, 585)],
        'gastrocnemien_lateral': [(1215, 760)],
        'soleaire': [(1233, 770), (1222, 850)],
        'fibulaires': [(1252, 800)],
        'extenseurs_orteils': [(1264, 820)],
        'tibial_anterieur': [(1274, 800)],
    },
}


# -------------------------------------------------------- segmentation --

def segment(rgb):
    """Classes des pixels : fond, contour, sombre, peau, zones colorées."""
    from scipy import ndimage
    from scipy.cluster.vq import kmeans2
    f = rgb.astype(float)
    mx, mn = f.max(-1), f.min(-1)
    sat = mx - mn
    lum = f.mean(-1)
    # fond : clair et relié au bord de l'image (halo gris clair compris)
    light = (lum > 212) & (sat < 30)
    lab, _ = ndimage.label(light)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    background = np.isin(lab, list(border))
    colored = (sat > 42) & (mx > 95) & ~background
    contour = (mx < 62) & ~background & ~colored
    sombre = (sat < 36) & (mx >= 62) & (mx < 150) & ~background & ~colored
    peau = ~background & ~colored & ~contour & ~sombre
    # zones colorées : k-moyennes puis composantes connexes par classe
    _, lbl = kmeans2(f[colored], K, minit='++', seed=1)
    cls = np.full(colored.shape, -1)
    cls[colored] = lbl
    zones = np.zeros(colored.shape, int)
    n = 0
    # érosion d'un pixel : les liserés anticrénelés des traits ne relient
    # plus deux muscles de même couleur (pixels rendus par le voisin après)
    core = ndimage.binary_erosion(colored, iterations=1)
    for c in range(K):
        cl, k = ndimage.label((cls == c) & core)
        zones[cl > 0] = cl[cl > 0] + n
        n += k
    # petites zones (liserés) rattachées à leur voisine la plus présente
    sizes = ndimage.sum(zones > 0, zones, range(1, n + 1))
    objs = ndimage.find_objects(zones)
    for i, s in enumerate(sizes, 1):
        if s >= 150 or objs[i - 1] is None:
            continue
        sl = tuple(slice(max(0, a.start - 3), a.stop + 3) for a in objs[i - 1])
        sub = zones[sl]
        r = sub == i
        ring = ndimage.binary_dilation(r, iterations=2) & ~r & (sub > 0)
        if ring.any():
            v, cnt = np.unique(sub[ring], return_counts=True)
            sub[r] = v[cnt.argmax()]
    return background, colored, contour, sombre, peau, zones



def seeds():
    """Points de chaque vue : [(x, y, région)], miroirs compris."""
    out = {}
    for view, _, _, axis in VIEWS:
        pts = []
        for region, xs in SYM.get(view, {}).items():
            for x, y in xs:
                pts.append((x, y, region))
                if round(2 * axis - x) != x:
                    pts.append((round(2 * axis - x), y, region))
        for region, xs in FIXE.get(view, {}).items():
            pts += [(x, y, region) for x, y in xs]
        for _, _, r in pts:
            assert r in REGION_IDS, r
        out[view] = pts
    return out


def classify(partial=False):
    """Région (rang dans REGIONS, 1…), peau, sombre de chaque pixel ; modelé."""
    from scipy import ndimage
    src = np.array(Image.open(SRC).convert('RGB'))
    background, colored, contour, sombre, peau, zones = segment(src)
    lum = src.astype(float).mean(-1)
    ids = [i for i in np.unique(zones) if i]
    zone_region = {}
    problems = []
    for view, pts in seeds().items():
        for x, y, region in pts:
            z = zones[y, x]
            if z == 0:
                # point sur un trait : zone colorée la plus proche (≤ 4 px)
                win = zones[y - 4:y + 5, x - 4:x + 5]
                vals = win[win > 0]
                if not len(vals):
                    problems.append(f'{view} {region} ({x}, {y}) hors des zones')
                    continue
                z = np.bincount(vals).argmax()
            old = zone_region.get(z)
            if old and old != region:
                problems.append(f'{view} ({x}, {y}) : zone déjà {old}, pas {region}')
            zone_region[z] = region
    # propagation : une zone sans point prend la région de la zone qu'elle
    # touche directement (même muscle, autre nuance d'ombre) ; les traits
    # noirs séparent deux muscles, donc pas de contact direct entre eux
    means = np.stack([ndimage.mean(src[..., j].astype(float), zones, ids) for j in range(3)], 1)
    mean_of = dict(zip(ids, means))
    objs = ndimage.find_objects(zones)
    neighbours = {}
    for i in ids:
        sl = tuple(slice(max(0, a.start - 2), a.stop + 2) for a in objs[i - 1])
        sub = zones[sl]
        r = sub == i
        ring = ndimage.binary_dilation(r, iterations=1) & ~r & (sub > 0)
        v, cnt = np.unique(sub[ring], return_counts=True)
        neighbours[i] = dict(zip(v.tolist(), cnt.tolist()))
    changed = True
    while changed:
        changed = False
        for i in ids:
            if i in zone_region:
                continue
            best = None
            for j, cnt in neighbours[i].items():
                if j in zone_region:
                    d = np.abs(mean_of[i] - mean_of[j]).mean()
                    score = cnt / (1 + d / 20)
                    if best is None or score > best[0]:
                        best = (score, j)
            if best:
                zone_region[i] = zone_region[best[1]]
                changed = True
    sizes = dict(zip(ids, ndimage.sum(zones > 0, zones, ids)))
    for i in ids:
        if i not in zone_region:
            cy, cx = ndimage.center_of_mass(zones == i)
            if sizes[i] >= 60:
                problems.append(f'zone isolée sans région ({round(cx)}, {round(cy)}), '
                                f'{int(sizes[i])} px')
    if problems and not partial:
        raise SystemExit('Découpage incomplet :\n  ' + '\n  '.join(problems))
    lut = np.zeros(zones.max() + 1, dtype=np.uint8)
    for z, region in zone_region.items():
        lut[z] = REGION_IDS.index(region) + 1
    labels = np.zeros(src.shape[:2], dtype=np.uint8)
    labels[colored] = lut[zones[colored]]
    # trapèze de dos : les traits intérieurs de l'image ne séparent pas ses
    # trois faisceaux en zones ; partage anatomique : supérieur (occiput →
    # C7, vers la clavicule), moyen (C7 → T3, horizontal vers l'acromion et
    # l'épine de la scapula), inférieur (T4 → T12, vers la base de l'épine).
    # Limites en y, fonction de la distance à l'axe (dx).
    _, x0, x1, axis = VIEWS[1]
    trap_ids = [REGION_IDS.index(r) + 1 for r in
                ('trapeze_superieur', 'trapeze_moyen', 'trapeze_inferieur')]
    ys, xs = np.where(np.isin(labels, trap_ids))
    keep = (xs >= x0) & (xs < x1)
    ys, xs = ys[keep], xs[keep]
    dx = np.abs(xs - axis)
    b1 = TRAP_DOS[0] + 30 * np.minimum(dx / 90, 1)
    b2 = TRAP_DOS[1] + 17 * np.minimum(dx / 50, 1)
    labels[ys, xs] = np.where(ys < b1, trap_ids[0], np.where(ys < b2, trap_ids[1], trap_ids[2]))
    labels[sombre] = SOMBRE
    labels[peau] = PEAU
    # pixels sans étiquette (traits, liserés, très petites zones isolées) :
    # étiquette du pixel voisin le plus proche (aucun trou vers le support)
    # (un pixel coloré prend la région la plus proche, jamais la peau :
    # fines bandes musculaires effacées par l'érosion)
    region = (labels >= 1) & (labels <= len(REGIONS))
    todo = (labels == 0) & colored
    _, (iy, ix) = ndimage.distance_transform_edt(~region, return_indices=True)
    labels[todo] = labels[iy[todo], ix[todo]]
    todo = (labels == 0) & ~background
    _, (iy, ix) = ndimage.distance_transform_edt(labels == 0, return_indices=True)
    labels[todo] = labels[iy[todo], ix[todo]]
    # corrections au pixel (HUE_FIXES)
    f = src.astype(float) / 255
    mx, mn = f.max(-1), f.min(-1)
    d = np.where(mx - mn == 0, 1, mx - mn)
    r, g, b = f[..., 0], f[..., 1], f[..., 2]
    hue = np.where(mx == r, (g - b) / d % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4))
    hue = hue * 60 % 360
    for (x0, y0, x1, y1), src_region, (h0, h1), dst in HUE_FIXES:
        k = REGION_IDS.index(src_region) + 1
        box = np.zeros(labels.shape, bool)
        box[y0:y1, x0:x1] = True
        sel = box & (labels == k) & (hue >= h0) & (hue < h1) & colored
        labels[sel] = PEAU if dst is None else REGION_IDS.index(dst) + 1
    zone_lum = np.zeros(zones.max() + 1)
    zone_lum[ids] = ndimage.mean(lum, zones, ids)
    shade = np.zeros(lum.shape)
    shade[colored] = np.clip((zone_lum[zones[colored]] - lum[colored]) / 70, 0, 1)
    if partial:
        return labels, contour, background, shade, zones, zone_region, problems
    return labels, contour, background, shade


PREVIEW_GROUP = {
    'trapezes': (60, 110, 230), 'deltoides': (250, 140, 30), 'pectoraux': (220, 50, 50),
    'dorsaux': (150, 20, 60), 'biceps': (250, 220, 40), 'triceps': (150, 90, 220),
    'avant_bras': (40, 190, 230), 'abdominaux': (60, 180, 70), 'obliques': (250, 170, 150),
    'coiffe': (200, 120, 60),
    'lombaires': (240, 120, 200), 'fessiers': (240, 100, 20), 'quadriceps': (30, 120, 250),
    'ischios': (110, 90, 200), 'adducteurs': (230, 60, 200), 'mollets': (130, 200, 40),
    'tibial': (20, 150, 110), None: (160, 160, 160),
}


def preview_rgb(lab):
    """Aperçu : une teinte par groupe, variée d'une région à l'autre."""
    rgb = np.full(lab.shape + (3,), 255, dtype=np.uint8)
    for k, (rid, _, _, group) in enumerate(REGIONS, 1):
        base = np.array(PREVIEW_GROUP[group])
        shift = ((k * 37) % 5 - 2) * 14
        rgb[lab == k] = np.clip(base + shift, 0, 255)
    rgb[lab == SOMBRE] = (70, 70, 70)
    rgb[lab == PEAU] = (225, 225, 225)
    return rgb


def write_dart():
    lines = [
        '// GÉNÉRÉ par tools/muscles2d/build_map.py — ne pas modifier à la main.',
        '//',
        '// M8 correction 2 (5.10.0) : régions dessinées de la carte 2D (une zone',
        '// = un muscle ou un ensemble de muscles superficiels du pack), rang =',
        '// valeur de la carte des étiquettes (1…), filtre de l’écran Anatomie.',
        "import 'muscle_map_2d.dart' show MapGroup, MapRegion;",
        '',
        '// Table générée : mise en page du script (dart format ne la touche pas).',
        '// dart format off',
        f'/// Filtres de l’écran Anatomie ({len(GROUPS)} groupes).',
        'const kMapGroups = [',
    ]
    for gid, label in GROUPS:
        lines.append(f"  MapGroup('{gid}', '{label}'),")
    lines += ['];', '', '/// Régions dessinées, dans l’ordre des étiquettes (1…).',
              'const kMapRegions = [']
    for rid, label, muscles, group in REGIONS:
        g = f"'{group}'" if group else 'null'
        label = label.replace("'", "\\'")
        ms = ', '.join(f"'{m}'" for m in muscles)
        one = f"  MapRegion('{rid}', '{label}', [{ms}], {g}),"
        if len(one) <= 80:
            lines.append(one)
            continue
        # découpage du formateur Dart : un argument par ligne
        lines += ['  MapRegion(', f"    '{rid}',", f"    '{label}',"]
        lst = f'    [{ms}],'
        if len(lst) <= 80:
            lines.append(lst)
        else:
            lines += ['    ['] + [f"      '{m}'," for m in muscles] + ['    ],']
        lines += [f'    {g},', '  ),']
    lines += ['];', '// dart format on', '']
    DART.write_text('\n'.join(lines), encoding='utf-8')


def build(apercu=None):
    labels, contour, background, shade = classify()
    report = {'vues': {}}
    previews = []
    for view, x0, x1, _ in VIEWS:
        lab = labels[:, x0:x1]
        ys, xs = np.where(lab > 0)
        pad = 4
        top, bot = max(0, ys.min() - pad), min(lab.shape[0], ys.max() + pad + 1)
        left, right = max(0, xs.min() - pad), min(lab.shape[1], xs.max() + pad + 1)
        lab = lab[top:bot, left:right]
        ct = contour[top:bot, x0 + left:x0 + right]
        sh = shade[top:bot, x0 + left:x0 + right]
        H, W = lab.shape
        d = OUT / view
        d.mkdir(parents=True, exist_ok=True)
        for old in d.glob('*.png'):
            old.unlink()
        Image.fromarray(lab, 'L').save(d / 'etiquettes.png', optimize=True)
        for name, m in (('contour', ct.astype(float)), ('ombre', sh)):
            img = Image.fromarray((m * 255).astype(np.uint8), 'L')
            if name == 'contour':
                img = img.filter(ImageFilter.GaussianBlur(.5))
            rgba = Image.new('LA', (W, H), 255)
            rgba.putalpha(img)
            rgba.save(d / f'{name}.png', optimize=True)
        present = sorted({int(v) for v in np.unique(lab)} - {0, SOMBRE, PEAU})
        report['vues'][view] = {'largeur': W, 'hauteur': H,
                                'regions': [REGION_IDS[v - 1] for v in present]}
        if apercu:
            prev = preview_rgb(lab)
            prev[ct] = (15, 15, 15)
            prev = (prev * (1 - .5 * sh[..., None])).astype(np.uint8)
            previews.append(Image.fromarray(prev))
    report.update({
        'groupes': [g for g, _ in GROUPS],
        'regions': [{'id': r, 'nom': n, 'muscles': m, 'groupe': g} for r, n, m, g in REGIONS],
        'etiquettes': {'regions': '1…%d (rang dans regions)' % len(REGIONS),
                       'sombre': SOMBRE, 'peau': PEAU},
        'source': 'tools/muscles2d/source_carte.png (image détaillée du propriétaire, '
                  '30/09/2026)',
    })
    (OUT / 'carte.json').write_text(json.dumps(report, ensure_ascii=False, indent=1) + '\n',
                                    encoding='utf-8')
    write_dart()
    if apercu:
        w = sum(p.width for p in previews) + 20 * len(previews)
        h = max(p.height for p in previews)
        board = Image.new('RGB', (w, h), (255, 255, 255))
        x = 0
        for p in previews:
            board.paste(p, (x, 0))
            x += p.width + 20
        board.save(apercu)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--apercu')
    args = parser.parse_args()
    report = build(args.apercu)
    print(json.dumps(report['vues'], ensure_ascii=False))


if __name__ == '__main__':
    main()
