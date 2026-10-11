#!/usr/bin/env python3
"""M7b (mannequin 3D) : animations « personnage » de Koach en mascotte.

Neuf animations du mannequin (personnage Mixamo Ch36, squelette
`mixamorig:` de 65 os), clés posées dans ce script (Blender sans
interface pour l'export), style **un peu exagéré, comme dans les anime** :
anticipation marquée, poses clés franches, dépassement puis amorti,
poses tenues de 0,2 à 0,4 s, tête / cou / clavicules / mains en décalage de
quelques images (koach_rig.DELAY). Mannequin neutre (aucun muscle allumé).

- attente (boucles) : respiration et transfert du poids ; regard qui
  balaie et épaules qui roulent ; étirement des bras puis du cou ;
- parle (boucles) : explication d'une main ; des deux mains ; montre sur
  le côté (index tendu, pour pointer plus tard un élément de l'écran) ;
- felicite (gestes qui reviennent à l'attente) : applaudissements ; poing
  levé ; pouce levé.

Toutes partent de la pose d'attente et y reviennent (transitions possibles
entre elles) ; pieds fixes (jambes par cinématique inverse).

  python3 tools/anatomy/koach_animations.py [--controle] [--fbx DOSSIER]
      [--importer] [--id koach_…]

`--controle` : contrôles automatiques (rapport JSON) ; `--fbx` : FBX
« Without Skin » (armature reconstruite depuis squelette_mixamo.json) ;
`--importer` : FBX exportés puis relus par la chaîne d'import de M7
(`import_animations.import_koach`) → clips `assets/anatomy/clips/koach/` et
registre. Les sources FBX ne sont pas suivies : ce script est la source
(décision du propriétaire, 29/09/2026 : pas de chiffrement pour Koach).
"""
import argparse
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
import koach_rig as kr  # noqa: E402
from koach_rig import Anim  # noqa: E402

FAMILLES = {'attente': 'Attente', 'parle': 'Koach parle', 'felicite': 'Koach félicite'}

# contacts voulus (applaudissements : les paumes se touchent)
CONTACTS = {'koach_felicite_applaudit': (('l_main', 'r_main'),)}

_SOLVED = {}


def solved(key, fn):
    if key not in _SOLVED:
        _SOLVED[key] = fn()
    return _SOLVED[key]


def both(ch):
    """Changements d'un côté (l_) recopiés sur l'autre (r_)."""
    out = dict(ch)
    for k, v in ch.items():
        if k.startswith('l_'):
            out['r_' + k[2:]] = v
    return out


def b(**kw):
    return kr.P(**kw)


# ======================================================== attente (idle) --
#
# Règles tenues partout (revues d'animation, passes 1 et 2) : le bassin, le
# buste et la tête participent à chaque geste, décalés de 2 à 4 images ;
# aucune pose tenue plus de 0,4 s sans relance visible ; arcs des bras
# devant le corps (jamais par l'horizontale sur le côté) ; mains hors de la
# silhouette du torse vue de face ; dépassement de 5 à 10° à chaque
# arrivée ; retour à l'attente en 0,3 à 0,4 s, amorti, avec un petit rebond.

def attente_respiration():
    a = Anim('koach_attente_respiration', 'Respire et change d’appui', 'attente', 4.0, True,
             [('Appui gauche', 1.75), ('Appui droit', 3.4), ('Revient', 4.0)],
             respirations=2, respiration_amp=1.0)
    # respiration bien visible : sternum et épaules montent d'environ 2 cm à
    # l'inspiration, la tête suit (revue d'animation)
    a.breath_weights = {'sp_p': -5.5, 'nk_p': 3.0, 'hd_p': -1.5, 'cl_up': 11.0, 'ar_dn': -3.0}
    # appui gauche : jambe gauche tendue, genou droit libre (bassin qui
    # tombe à droite), épaules en contre-inclinaison
    left = dict(px=.05, py=-.009, hip_r=7, hip_y=3, sp_r=-6.5, sp_y=-2, hd_r=5, hd_y=6,
                l_el=20, l_ar_fw=10, r_ar_dn=69, r_ar_fw=2, r_el=24)
    right = dict(px=-.05, py=-.009, hip_r=-7, hip_y=-3, sp_r=6.5, sp_y=2, hd_r=-5, hd_y=-6,
                 r_el=20, r_ar_fw=10, l_ar_dn=69, l_ar_fw=2, l_el=24)
    center = dict(px=0, py=-.03, hip_r=0, hip_y=0, sp_r=0, sp_y=0, hd_r=0, hd_y=0, hd_p=3,
                  l_el=14, l_ar_fw=6, l_ar_dn=76, r_ar_dn=76, r_ar_fw=6, r_el=14)
    a.key(.2, 'io', px=-.014, py=-.032, hip_r=-1.8, sp_r=1.2, hd_r=-1.2, hd_y=-2)  # anticipation
    a.key(.62, 'o', **left)
    a.key(.76, 'io', px=.055, py=-.012, hip_r=8, sp_r=-7.5, r_ar_dn=66)    # dépassement
    a.key(.94, 'io', **left)
    a.hold(1.2, sp_r=-5, hd_r=8, hd_y=14, hd_p=-6, r_ar_fw=4, px=.046)     # relance du regard
    a.key(1.4, 'io', hd_y=4, hd_p=1, sp_r=-6)
    a.key(1.75, 'io', **center)
    a.key(2.12, 'o', **right, hd_p=0)
    a.key(2.26, 'io', px=-.055, py=-.012, hip_r=-8, sp_r=7.5, l_ar_dn=66)
    a.key(2.44, 'io', **right)
    a.hold(2.7, sp_r=5, hd_r=-8, hd_y=-14, hd_p=-6, l_ar_fw=4, px=-.046)
    a.key(2.9, 'io', hd_y=-4, hd_p=1, sp_r=6)
    a.key(3.25, 'io5', px=.01, py=-.022, hip_r=1.4, hip_y=0, sp_r=-1, sp_y=0, hd_r=1.5,
          hd_y=0, hd_p=0, r_el=14, r_ar_fw=6, l_ar_dn=76, l_ar_fw=6, l_el=14)  # revient, dépasse
    a.key(3.55, 'io', px=-.004, py=-.016, hip_r=-.5, sp_r=.4, hd_r=-.8, hd_y=-5, hd_p=-3)
    a.key(3.8, 'io', px=.004, hip_r=.6, hd_y=4, hd_p=2, hd_r=1.5, l_ar_fw=9)
    a.back(4.0, 'l')
    return a


def attente_regard():
    a = Anim('koach_attente_regard', 'Regarde autour et roule les épaules', 'attente', 4.4, True,
             [('Regarde à droite', 1.2), ('Regarde à gauche', 2.55), ('Roule les épaules', 4.4)],
             respirations=2, respiration_amp=1.4)
    a.offsets = {'r_cl_': .08}                                              # épaules décalées
    look_r = dict(hd_y=-42, nk_y=-16, sp_y=-12, hip_y=-4, hip_r=-2.5, px=-.024, py=-.02,
                  sp_r=1.5, l_ar_fw=12, l_el=20, r_ar_fw=0)
    look_l = dict(hd_y=42, nk_y=16, sp_y=12, hip_y=4, hip_r=2.5, px=.024, py=-.02, sp_r=-1.5,
                  r_ar_fw=12, r_el=20, l_ar_fw=0, l_el=14)
    a.key(.22, 'io', hd_y=19, nk_y=6, sp_y=5, hd_p=6, py=-.026)            # contre-anticipation
    a.key(.48, 'o', hd_p=-4, **look_r)
    a.key(.6, 'io', hd_y=-49, nk_y=-19, sp_y=-14)                           # dépassement
    a.key(.76, 'io', hd_y=-42, nk_y=-16, sp_y=-12)
    a.key(.9, 'o', hd_y=-31, hd_p=-12, hd_r=-7, sp_y=-10)                  # « tic » franc
    a.key(1.06, 'io', hd_y=-43, hd_p=-4, hd_r=-3, sp_y=-12)
    a.key(1.24, 'io', hd_y=-54, hd_p=3, hd_r=0, sp_y=-14)                   # contre-anticipation
    a.key(1.62, 'io5', hd_p=-2, **look_l)
    a.key(1.74, 'io', hd_y=49, nk_y=19, sp_y=14)
    a.key(1.9, 'io', hd_y=42, nk_y=16, sp_y=12)
    a.key(1.98, 'o', hd_y=31, hd_p=10, hd_r=8, sp_y=10)
    a.key(2.14, 'io', hd_y=45, hd_p=-3, hd_r=2, sp_y=12)
    a.key(2.3, 'o', hd_y=37, hd_p=3, hd_r=5)
    a.key(2.55, 'io5', hd_y=0, nk_y=0, sp_y=0, hip_y=0, hip_r=0, px=0, hd_p=0, hd_r=0, sp_r=0,
          r_ar_fw=6, r_el=14, py=-.012)
    # épaules qui roulent (avant-haut, arrière-haut, arrière-bas), la tête
    # s'allonge avec elles (menton qui monte, cou visible)
    a.key(2.82, 'io', b_cl_up=15, b_cl_fw=15, sp_p=4, hd_p=-4, nk_p=-8, py=-.008)
    a.key(3.1, 'l', b_cl_up=16, b_cl_fw=-12, sp_p=-6, hd_p=-8, nk_p=-9)
    a.key(3.38, 'o', b_cl_up=-7, b_cl_fw=-15, sp_p=-4, hd_p=-1, nk_p=0, py=-.018)
    a.key(3.56, 'io', b_cl_up=3, b_cl_fw=3, sp_p=2, hd_p=3)                # rebond
    a.key(3.78, 'io', b_cl_up=0, b_cl_fw=0, sp_p=0, hd_p=0, hd_r=5, hd_y=6, py=-.014)
    a.key(3.98, 'io', hd_y=13, hd_p=-5, hd_r=6, sp_y=3, px=.008)
    a.key(4.16, 'io', hd_y=-4, hd_p=2, hd_r=-1.5, sp_y=-1, px=-.004)
    a.back(4.4, 'io')
    return a


def attente_etirement():
    a = Anim('koach_attente_etirement', 'S’étire les bras puis le cou', 'attente', 5.4, True,
             [('S’étire', 1.45), ('Penche', 3.2), ('Relâche le cou', 5.4)],
             respirations=2, respiration_amp=1.3)
    up = dict(b_ar_dn=-75, b_ar_fw=86, b_ar_tw=0, b_el=5, b_fist=.04, b_th_c=0, b_wr_fl=-28)
    a.key(.28, 'io', py=-.042, sp_p=11, hd_p=13, b_ar_dn=82, b_ar_fw=16, b_el=58, b_fist=.6,
          b_cl_up=-4, b_th_c=.4)                                            # se ramasse
    # bras qui montent DEVANT le corps : d'abord vers l'avant, puis en haut
    a.key(.5, 'io5', py=-.03, sp_p=4, hd_p=4, b_ar_dn=40, b_ar_fw=88, b_el=25, b_fist=.3,
          b_cl_up=4, b_th_c=.2)
    a.key(.8, 'io', py=-.008, sp_p=-12, hd_p=-18, nk_p=-4, b_cl_up=17, **up)
    a.key(.93, 'io', sp_p=-16, hd_p=-22, b_ar_dn=-83, b_cl_up=20)           # dépassement
    a.key(1.08, 'io', sp_p=-13, hd_p=-19, b_ar_dn=-77, b_cl_up=17)
    a.key(1.3, 'io', sp_p=-19, hip_p=-4, b_cl_up=21, b_wr_fl=-38, hd_p=-23, py=-.004)  # cambre
    a.key(1.72, 'io5', sp_r=25, sp_p=-9, hip_p=0, hip_r=-4.5, px=-.03, py=-.022, hd_r=9, hd_p=-12)
    a.key(1.85, 'io', sp_r=29)
    a.key(2.08, 'io', sp_r=25, hd_r=12)
    a.key(2.6, 'io5', sp_r=-25, hip_r=4.5, px=.03, hd_r=-9)
    a.key(2.73, 'io', sp_r=-29)
    a.key(2.96, 'io', sp_r=-25, hd_r=-12)
    a.key(3.2, 'i2', sp_r=0, hip_r=0, px=0, py=-.012, hd_r=0, sp_p=-10, hd_p=-12)
    # relâche : les bras redescendent devant le corps (par l'avant), les
    # épaules tombent, petit rebond
    a.key(3.46, 'io', b_ar_dn=35, b_ar_fw=88, b_el=15, b_fist=.2, b_wr_fl=0, b_cl_up=4,
          sp_p=0, hd_p=0, nk_p=0)
    a.key(3.72, 'io', b_ar_dn=78, b_ar_fw=30, b_el=14, b_fist=.3, b_wr_fl=4, b_cl_up=-7,
          sp_p=7, hd_p=9, py=-.032)
    a.key(3.86, 'io', b_ar_dn=74, b_ar_fw=10, b_el=16, b_cl_up=3, sp_p=1, hd_p=2, py=-.016)
    a.key(4.0, 'io', b_ar_dn=76, b_ar_fw=6, b_el=14, b_fist=.22, b_th_c=.15, b_wr_fl=6,
          b_cl_up=0, sp_p=0, hd_p=0, py=-.012)
    # cou : penche d'un côté (l'autre épaule descend), roule par l'avant,
    # penche de l'autre côté ; le cou s'allonge
    a.key(4.25, 'io', hd_r=-17, nk_r=-10, hd_p=5, nk_p=-4, l_cl_up=-5)
    a.key(4.38, 'io', hd_r=-19, nk_r=-11)
    a.key(4.62, 'io5', hd_r=0, nk_r=0, hd_p=20, nk_p=8, l_cl_up=0)
    a.key(4.86, 'io5', hd_r=17, nk_r=10, hd_p=5, nk_p=-4, r_cl_up=-5)
    a.key(4.98, 'io', hd_r=19, nk_r=11)
    a.back(5.26, 'io')
    return a


# ==================================================== parle (explique) --

ARM = ('ar_dn', 'ar_fw', 'ar_tw', 'el', 'wr_tw', 'fa_tw')


def solve_r(key, base, **target):
    return solved(key, lambda: kr.solve_hand(kr.P(**base), 'r_', vars=ARM, **target))


def solve_both(key, base, **target):
    r = solve_r(key, base, **target)
    return both({('l_' + k[2:]): v for k, v in r.items()})


OPEN_R = dict(r_fist=.06, r_th_c=0, r_th_o=12, r_wr_fl=-10)
OPEN_B = dict(b_fist=.06, b_th_c=0, b_th_o=12, b_wr_fl=-10)


def parle_une_main():
    base = dict(OPEN_R, sp_p=5, sp_y=8)
    g = solve_r('um_g', base, palm=(-.31, 1.25, .3), normal=(-.35, .9, .2),
                fingers=(-.4, .15, .9))
    beat = solve_r('um_b', base, palm=(-.3, 1.12, .37), normal=(-.3, .93, .15),
                   fingers=(-.35, -.15, .93))
    big = solve_r('um_B', base, palm=(-.29, 1.04, .38), normal=(-.25, .95, .15),
                  fingers=(-.3, -.3, .9))
    # « et voilà » : paume ouverte vers le haut, à 45° devant le corps
    out = solve_r('um_o', dict(OPEN_R, sp_p=4, sp_y=-2), palm=(-.29, 1.2, .37),
                  normal=(-.4, .85, .3), fingers=(-.5, .3, .8))
    a = Anim('koach_parle_une_main', 'Explique d’une main', 'parle', 4.2, True,
             [('Présente', .8), ('Insiste', 1.9), ('Ouvre', 2.75), ('Conclut', 4.2)])
    a.key(.22, 'io', r_el=30, r_ar_dn=84, r_ar_fw=-12, r_cl_fw=-6, sp_y=-6, hd_p=5, py=-.022,
          l_ar_fw=0)
    a.key(.5, 'o', sp_p=5, sp_y=8, hd_p=-9, hd_r=5, r_cl_up=6, r_cl_fw=0, py=-.016, px=-.014,
          l_ar_fw=12, l_el=22, **OPEN_R, **g)
    a.key(.61, 'io', r_el=g['r_el'] + 9, r_wr_fl=-22, sp_y=10, hd_p=-11)   # dépassement
    a.key(.76, 'io', r_el=g['r_el'], r_wr_fl=-10, sp_y=8, hd_p=-8)
    # temps forts : long, court, court, long (accent sur le dernier)
    for t0, amp, gap in ((.98, beat, .16), (1.24, beat, .12), (1.44, beat, .12),
                         (1.72, big, .18)):
        strong = amp is big
        a.key(t0, 'i2', sp_p=11 if strong else 8, sp_y=10 if strong else 8,
              hd_p=18 if strong else 13, nk_p=7, py=-.028 if strong else -.022,
              l_ar_fw=16, **amp, r_wr_fl=10)
        a.key(t0 + gap, 'o', sp_p=5, sp_y=8, hd_p=-6, nk_p=0, py=-.016, l_ar_fw=10, **g,
              r_wr_fl=-14)
    a.key(2.12, 'o', sp_p=4, sp_y=-2, hd_r=13, hd_p=-6, px=-.022, py=-.014, **out,
          r_wr_fl=-18)                                                     # « et voilà »
    a.key(2.24, 'io', r_ar_fw=out['r_ar_fw'] - 8, hd_r=16, sp_p=2)
    a.key(2.4, 'io', r_ar_fw=out['r_ar_fw'], hd_r=13, sp_p=4)
    a.key(2.33, 'i2', r_el=out['r_el'] - 16, hd_p=10, hd_r=14, sp_p=7, py=-.022)
    a.key(2.46, 'o', r_el=out['r_el'], hd_p=-4, sp_p=4, py=-.014)
    a.key(2.62, 'io', hd_r=15, hd_p=-2, sp_p=5)
    for t0, gap in ((2.84, .14), (3.14, .16)):
        a.key(t0, 'i2', sp_p=10, sp_y=6, hd_p=16, hd_r=4, nk_p=6, px=-.014, py=-.024, **beat,
              r_wr_fl=8)
        a.key(t0 + gap, 'o', sp_p=5, sp_y=8, hd_p=-5, nk_p=0, py=-.016, **g, r_wr_fl=-14)
    a.key(3.72, 'io5', r_ar_dn=78, r_ar_fw=12, r_el=20, r_ar_tw=0, r_wr_tw=0, r_fa_tw=0,
          r_fist=.25, r_th_c=.15, r_th_o=0, r_wr_fl=4, r_cl_up=0, sp_p=1, sp_y=-1, hd_p=6,
          hd_r=1, px=0, py=-.02, l_ar_fw=6, l_el=14)
    a.key(3.88, 'io', hd_p=-2, py=-.014, r_ar_dn=75)
    a.key(4.04, 'io', hd_p=2, hd_r=2, py=-.017)
    a.back(4.2, 'io')
    return a


def parle_deux_mains():
    offer = solve_both('dm_u', dict(OPEN_B, sp_p=12), palm=(-.27, 1.2, .35),
                       normal=(-.3, .93, .15), fingers=(-.3, .1, .95))
    offer_b = solve_both('dm_ub', dict(OPEN_B, sp_p=14), palm=(-.27, 1.04, .39),
                         normal=(-.25, .95, .15), fingers=(-.25, -.25, .93))
    wide = solve_both('dm_w', dict(OPEN_B, sp_p=2), palm=(-.47, 1.08, .18),
                      normal=(-.45, .85, .2), fingers=(-.8, .25, .55))
    flat = dict(b_fist=.04, b_th_c=0, b_th_o=5, b_wr_fl=0)
    chop = solve_both('dm_c', dict(flat, sp_p=12), palm=(-.24, 1.02, .44), normal=(0, -1, 0),
                      fingers=(0, 0, 1))
    chop_up = solve_both('dm_cu', dict(flat, sp_p=8), palm=(-.25, 1.14, .42),
                         normal=(0, -1, .1), fingers=(0, .1, 1))
    a = Anim('koach_parle_deux_mains', 'Explique des deux mains', 'parle', 4.3, True,
             [('Propose', 1.6), ('Écarte', 2.45), ('Pose un point', 4.3)])
    a.offsets = {'r_ar': .067, 'r_el': .067, 'r_wr': .067}  # mains désynchronisées (2 images)
    a.key(.28, 'io', b_el=30, b_ar_dn=82, b_ar_fw=-8, sp_p=-5, hd_p=-7, py=-.024, b_cl_fw=-5)
    a.key(.56, 'o', sp_p=12, hd_p=10, py=-.026, b_cl_fw=6, **OPEN_B, **offer)
    a.key(.68, 'io', sp_p=15, hd_p=13, b_el=offer['l_el'] + 8)
    a.key(.84, 'io', sp_p=12, hd_p=9, b_el=offer['l_el'])
    for t0, gap in ((1.04, .15), (1.32, .13)):
        a.key(t0, 'i2', sp_p=16, hd_p=19, nk_p=7, py=-.032, **offer_b)
        a.key(t0 + gap, 'o', sp_p=12, hd_p=5, nk_p=0, py=-.024, **offer)
    a.key(1.76, 'o', sp_p=1, hd_p=-8, hd_r=7, py=-.012, b_cl_fw=-4, b_cl_up=1, **wide,
          b_wr_fl=-16)                                                     # « voilà »
    a.key(1.88, 'io', b_ar_fw=wide['l_ar_fw'] - 8, hd_r=10, sp_p=-2, hd_p=-10)
    a.key(2.04, 'io', b_ar_fw=wide['l_ar_fw'], hd_r=7, sp_p=1, hd_p=-7)
    a.key(2.2, 'i2', hd_p=15, nk_p=6, sp_p=5, hd_r=6)                      # hoche
    a.key(2.33, 'o', hd_p=-3, nk_p=0, sp_p=2)
    a.key(2.55, 'io', sp_p=6, hd_p=-5, b_cl_fw=2, b_cl_up=-4, **chop_up, **flat, hd_r=2)  # « calme »
    for t0, gap in ((2.78, .14), (3.12, .16)):
        a.key(t0, 'i2', sp_p=13, hd_p=17, nk_p=7, py=-.032, **chop)
        a.key(t0 + gap, 'o', sp_p=8, hd_p=2, nk_p=0, py=-.02, **chop_up)
    a.key(3.6, 'io5', b_ar_dn=78, b_ar_fw=12, b_el=20, b_ar_tw=0, b_wr_tw=0, b_fa_tw=0,
          b_fist=.25, b_th_c=.15, b_th_o=0, b_wr_fl=4, b_cl_fw=0, sp_p=1, hd_p=6, hd_r=0,
          py=-.02)
    a.key(3.8, 'io', hd_p=-2, py=-.014, b_ar_dn=75, sp_p=-1)
    a.back(4.3, 'io')
    return a


def parle_montre():
    V = ('ar_dn', 'ar_fw', 'ar_tw', 'el', 'wr_tw')
    hand = dict(l_fist=1, l_idx=0, l_th_c=.1, l_th_o=-45, l_wr_fl=0, l_wr_dv=-12)
    base = kr.P(sp_y=20, hip_y=6, l_ar_fw=30, l_ar_dn=3, l_ar_tw=-60, l_wr_tw=-30, l_el=12,
                **hand)
    # index tendu dans l'axe de l'avant-bras, à l'horizontale ; main de chant
    # (paume vers l'avant), pouce replié sur le majeur : pas de « V »
    pt = dict(solved('pt_l', lambda: kr.solve_hand(base, 'l_', palm=(.72, 1.37, .3),
                                                   fingers=(.9, -.12, .44),
                                                   normal=(-.44, 0, .9), vars=V,
                                                   weights=(1, .25, .3, 0))))
    pt['l_el'] = max(pt['l_el'], 12.0)                  # coude jamais verrouillé
    pt['l_ar_dn'] += 4                                  # index à l'horizontale (0-10°)
    a = Anim('koach_parle_montre', 'Montre quelque chose sur le côté', 'parle', 3.2, True,
             [('Montre', 1.25), ('Te regarde', 2.0), ('Revient', 3.2)])
    a.offsets = {'hd_': -.16, 'nk_': -.12}               # la tête précède le bras
    a.hold(.07)                                          # départ exact sur l'attente
    a.key(.28, 'io', sp_y=-16, hip_y=-5, hd_y=-12, l_el=95, l_ar_fw=32, l_ar_dn=74, l_fist=.8,
          l_cl_fw=9, px=-.018, py=-.034)
    a.key(.6, 'o2', sp_y=20, hip_y=6, hip_r=3, hd_y=38, nk_y=12, px=.032, py=-.02, l_cl_fw=0,
          l_cl_up=5, **hand, **pt)
    a.key(.72, 'io', sp_y=25, hd_y=44, l_ar_fw=pt['l_ar_fw'] - 9)           # dépassement
    a.key(.86, 'io', sp_y=20, hd_y=38, l_ar_fw=pt['l_ar_fw'])
    for t0 in (.98, 1.22):                                                 # relances vers la cible
        a.key(t0, 'i2', l_ar_fw=pt['l_ar_fw'] - 10, l_el=pt['l_el'] + 14, sp_y=23, hd_p=10,
              sp_p=3, px=.038)
        a.key(t0 + .12, 'o', l_ar_fw=pt['l_ar_fw'], l_el=pt['l_el'], sp_y=20, hd_p=0, sp_p=0,
              px=.032)
    a.key(1.55, 'io5', hd_y=2, nk_y=5, hd_r=11, sp_y=16, l_el=pt['l_el'] + 8)  # regarde l'écran
    a.key(1.74, 'i2', hd_p=16, nk_p=6)
    a.key(1.87, 'o', hd_p=-3, nk_p=0)
    a.key(2.0, 'i2', l_ar_fw=pt['l_ar_fw'] - 8, l_el=pt['l_el'] + 12, hd_p=6, hd_r=13)
    a.key(2.12, 'o', l_ar_fw=pt['l_ar_fw'], l_el=pt['l_el'], hd_p=0)
    # sortie directe par un arc devant le corps, rebond
    a.key(2.5, 'io5', l_ar_dn=74, l_ar_fw=22, l_ar_tw=0, l_wr_tw=0, l_el=24, l_fist=.3,
          l_idx=-1, l_th_c=.15, l_th_o=0, l_wr_fl=6, l_wr_dv=0, l_cl_up=0, sp_y=-2, hip_y=0, hip_r=0,
          hd_y=-2, nk_y=0, hd_r=2, hd_p=4, px=-.006, py=-.022)
    a.key(2.68, 'io', l_ar_dn=78, l_ar_fw=6, l_el=14, sp_y=1, hd_y=1, hd_p=-2, py=-.014)
    a.back(3.2, 'io')
    return a


# ================================================== félicite (bravo) --

def clap_pose(gap, y=1.3, z=.46):
    """Paumes face à face devant le haut de la poitrine, mains avancées,
    coudes ouverts, épaules basses."""
    return solve_both(('clap', gap, y, z), dict(b_fist=.03, b_th_c=0, b_th_o=5, b_wr_fl=-8,
                                                 sp_p=3),
                      palm=(-gap / 2 - .0145, y, z), normal=(1, 0, 0), fingers=(.1, .72, .69))


def felicite_applaudit():
    wide, open_, shut = clap_pose(.56), clap_pose(.38), clap_pose(0.0)
    open_s, shut_s = clap_pose(.26, 1.26), clap_pose(0.0, 1.26)
    a = Anim('koach_felicite_applaudit', 'Applaudit', 'felicite', 3.2, False,
             [('Lève les mains', .55), ('Applaudit', 2.15), ('Retour', 3.2)])
    hands = dict(b_fist=.03, b_th_c=0, b_th_o=5, b_wr_fl=-8)
    a.key(.24, 'io', py=-.042, sp_p=10, hd_p=12, b_el=55, b_ar_fw=25, b_ar_dn=82, b_cl_up=2)
    a.key(.48, 'o', py=-.006, sp_p=-6, hd_p=-13, b_cl_up=-2, **hands, **wide)
    a.key(.7, 'i2', py=-.032, sp_p=6, hd_p=7, **shut)                       # grande frappe
    a.key(.86, 'o', py=-.012, sp_p=-2, hd_p=-8, **open_)
    for t0 in (1.0, 1.2, 1.4):                                              # plus rapides
        a.key(t0, 'i2', py=-.026, sp_p=4, hd_p=5, **shut_s)
        a.key(t0 + .1, 'o', py=-.014, sp_p=0, hd_p=-4, **open_s)
    a.key(1.62, 'io', py=-.008, sp_p=-5, hd_p=-10, b_cl_up=-2, **wide)                  # arme la dernière
    a.key(1.8, 'i2', py=-.034, sp_p=4, hd_p=-6, hd_r=11, nk_p=-9, b_cl_up=-6, **clap_pose(0.0, 1.2, .46))
    a.key(1.94, 'io', py=-.016, sp_p=2, hd_p=-10, nk_p=-9, hd_r=13, b_cl_up=-6)
    a.key(2.16, 'io', hd_r=15, sp_p=3, hd_p=-7, nk_p=-7, b_cl_up=-6)
    # retour : les mains s'ouvrent et descendent devant, amorti, rebond
    a.key(2.36, 'io', b_ar_fw=45, b_ar_dn=40, b_el=45, b_ar_tw=0, b_wr_tw=0, b_fa_tw=0,
          b_wr_fl=0, b_fist=.1, b_cl_up=-2, hd_r=8, hd_p=0, nk_p=0, sp_p=3, py=-.018)
    a.key(2.55, 'io', b_ar_fw=22, b_ar_dn=74, b_el=24, b_wr_fl=4, b_fist=.2, b_cl_up=-3,
          hd_r=3, hd_p=4, sp_p=3, py=-.024)
    a.key(2.7, 'io', b_ar_dn=77, b_ar_fw=6, b_el=14, b_cl_up=2, hd_r=0, hd_p=0, sp_p=0,
          py=-.01)
    a.key(2.86, 'io', hd_p=3, hd_r=-3, sp_p=1, py=-.016)
    a.back(3.02, 'io')
    return a


def felicite_poing():
    a = Anim('koach_felicite_poing', 'Lève le poing', 'felicite', 3.0, False,
             [('Prend l’élan', .32), ('Lève le poing', 1.05), ('« Yes ! »', 1.95),
              ('Retour', 3.0)])
    fist_r = dict(r_fist=1.02, r_th_c=.3, r_th_o=-35)
    # poing vertical au-dessus de la tête, un peu sur le côté, poignet droit
    top = dict(r_ar_dn=-45, r_ar_fw=45, r_ar_tw=-20, r_el=40, r_wr_fl=-8)
    # « yes ! » : coude tiré le long du flanc, poing à hauteur de la tempe,
    # sur le côté (jamais devant le visage)
    yes = dict(r_ar_dn=45, r_ar_fw=10, r_ar_tw=-70, r_el=120, r_wr_fl=0)
    a.key(.32, 'io', py=-.07, sp_p=16, sp_y=-8, hip_y=-4, hd_p=14, r_ar_dn=84, r_ar_fw=-20,
          r_el=115, r_wr_fl=10, r_cl_up=-4, r_cl_fw=-8, l_el=40, l_ar_fw=12, l_fist=.6,
          **fist_r)
    # uppercut : le coude monte devant le torse, puis le poing passe au-dessus
    a.key(.44, 'l', py=-.035, sp_p=4, r_ar_dn=22, r_ar_fw=70, r_el=92, r_wr_fl=0, hd_p=4)
    a.key(.56, 'o', py=-.004, sp_p=-10, sp_r=8, sp_y=6, hip_y=2, hd_p=-18, hd_r=6,
          r_cl_up=12, r_cl_fw=0, l_ar_dn=80, l_ar_fw=-24, l_el=95, l_fist=.95, l_th_c=.3,
          l_th_o=-30, **top)
    a.key(.66, 'io', r_ar_dn=-55, r_el=32, sp_p=-13, hd_p=-22, r_cl_up=15)  # dépassement
    a.key(.82, 'io', r_ar_dn=-45, r_el=40, sp_p=-10, hd_p=-18, r_cl_up=12)
    a.key(.98, 'io', sp_p=-12, hd_r=9, hd_p=-20)
    for t0, gap in ((1.14, .16), (1.46, .18)):
        a.key(t0, 'i2', sp_p=7, sp_r=4, py=-.038, hd_p=4, r_cl_up=-2, l_el=110, **yes)
        a.key(t0 + gap, 'o', sp_p=-9, sp_r=8, py=-.008, hd_p=-16, r_cl_up=10, l_el=95, **top)
    a.key(1.84, 'i2', sp_p=-5, hip_p=-3, py=-.03, hd_p=-8, hd_r=6, r_cl_up=-2, l_el=112, **yes)  # dernier
    a.key(2.0, 'io', sp_p=-7, hip_p=-4, py=-.024, hd_p=-12, hd_r=9)
    # retour devant le corps, amorti, rebond
    a.key(2.2, 'io', r_ar_dn=62, r_ar_fw=22, r_ar_tw=-30, r_el=100, sp_p=0, hip_p=0, hd_p=0,
          py=-.02)                                                         # le coude descend
    a.key(2.42, 'io', r_ar_dn=74, r_ar_fw=26, r_ar_tw=0, r_el=30, r_wr_fl=4, r_fist=.35,
          r_th_c=.2, r_th_o=0, r_cl_up=-4, sp_p=3, sp_r=0, sp_y=0, hip_y=0, hd_p=6, hd_r=0,
          l_ar_dn=76, l_ar_fw=8, l_el=18, l_fist=.3, l_th_c=.15, l_th_o=0, py=-.026)
    a.key(2.58, 'io', r_ar_dn=77, r_ar_fw=6, r_el=14, r_fist=.22, r_cl_up=2, sp_p=0, hd_p=-1,
          py=-.01)
    a.back(2.86, 'io')
    return a


def felicite_pouce():
    # bras ouvert devant et sur le côté, coude à peine cassé, main à hauteur
    # d'épaule, pouce en haut détaché de la tête
    tu = dict(r_ar_dn=6, r_ar_fw=40, r_ar_tw=-60, r_wr_tw=-30, r_el=20, r_fa_tw=0, r_wr_fl=0)
    hand = dict(r_fist=1.02, r_th_c=-.4, r_th_o=30)
    a = Anim('koach_felicite_pouce', 'Pouce levé', 'felicite', 3.0, False,
             [('Prend l’élan', .3), ('Pouce levé', 2.2), ('Retour', 3.0)])
    a.key(.3, 'io', r_el=100, r_ar_fw=10, r_ar_dn=84, r_fist=.9, r_th_c=.3, sp_y=-10, sp_p=-5,
          hd_r=-6, hd_p=-3, py=-.03, r_cl_fw=-6)
    a.key(.5, 'o', sp_y=8, sp_p=7, sp_r=-6, hd_r=10, hd_p=5, hd_y=-8, py=-.016, px=-.02,
          r_cl_fw=9, **hand, **tu)
    a.key(.6, 'io', sp_p=10, sp_r=-8, hd_r=13, r_cl_fw=12, r_ar_fw=tu['r_ar_fw'] + 10, r_el=8)
    a.key(.76, 'io', sp_p=7, sp_r=-6, hd_r=10, r_cl_fw=9, r_ar_fw=tu['r_ar_fw'], r_el=20)
    a.key(.92, 'i2', hd_p=19, nk_p=6, sp_p=10)                              # hoche
    a.key(1.06, 'o', hd_p=0, nk_p=0, sp_p=7)
    a.key(1.22, 'i2', r_ar_fw=tu['r_ar_fw'] + 22, r_ar_dn=0, r_el=0, sp_p=14, r_cl_fw=15,
          hd_p=10, px=-.03, py=-.024)                                      # coup de pouce
    a.key(1.36, 'o', r_ar_fw=tu['r_ar_fw'], r_ar_dn=6, r_el=20, sp_p=7, r_cl_fw=9, hd_p=0, px=-.02,
          py=-.016)
    a.key(1.52, 'io', hd_r=17, sp_r=-10, hd_p=-4, px=-.028, hip_r=-2.5, r_el=26, l_ar_dn=70,
          l_ar_fw=12, l_el=22)                                            # penché complice
    a.key(1.66, 'i2', r_ar_fw=tu['r_ar_fw'] + 12, r_el=8, hd_p=8, sp_p=9)
    a.key(1.78, 'o', r_ar_fw=tu['r_ar_fw'], r_el=20, hd_p=-2, sp_p=7)
    a.key(2.1, 'io', l_ar_dn=76, l_ar_fw=6, l_el=14, r_el=30, r_ar_fw=26, r_ar_dn=74, r_ar_tw=0, r_wr_tw=0, r_fist=.3,
          r_th_c=.2, r_th_o=0, r_cl_fw=-3, sp_y=0, sp_p=3, sp_r=0, hip_r=0, hd_r=0, hd_p=5,
          hd_y=0, px=0, py=-.024)
    a.key(2.28, 'io', r_el=14, r_ar_fw=6, r_ar_dn=77, r_cl_fw=1, sp_p=0, hd_p=-1, py=-.01)
    a.key(2.48, 'io', hd_p=4, hd_r=4, sp_p=1, py=-.017)
    a.key(2.66, 'io', hd_p=-2, hd_r=-1, py=-.011)
    a.back(2.84, 'io')
    return a


BUILDERS = [attente_respiration, attente_regard, attente_etirement,
            parle_une_main, parle_deux_mains, parle_montre,
            felicite_applaudit, felicite_poing, felicite_pouce]


def all_anims():
    out = []
    for fn in BUILDERS:
        a = fn()
        t_end, ch, e = a.keys[-1]
        if a.boucle and t_end >= a.duree - 1e-9:
            # pose d'attente atteinte 0,12 s avant la fin : la tête (décalée
            # de 0,1 s) y arrive aussi, la boucle se referme sans écart
            a.keys[-1] = (a.duree - .12, ch, e)
        if a.keys[-1][0] < a.duree:
            a.back(a.duree, 'l')                    # pose d'attente tenue jusqu'au bout
        out.append(a)
    return out


def registry_fields(anim):
    return {'famille': anim.famille, 'boucle': anim.boucle, 'mascotte': True}


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--controle', action='store_true')
    parser.add_argument('--fbx')
    parser.add_argument('--importer', action='store_true')
    parser.add_argument('--id', action='append')
    parser.add_argument('--rapport')
    args = parser.parse_args()
    reports = []
    motions = {}
    for anim in all_anims():
        if args.id and anim.id not in args.id:
            continue
        m = anim.motion()
        motions[anim.id] = (anim, m)
        rep = kr.check(anim, m, CONTACTS.get(anim.id, ()))
        reports.append(rep)
        print(json.dumps({k: rep[k] for k in ('id', 'ok', 'defauts', 'glissement_pieds_mm',
                                               'interpenetration_mm', 'ecart_attente_deg')},
                         ensure_ascii=False))
    if args.rapport:
        Path(args.rapport).write_text(json.dumps(reports, ensure_ascii=False, indent=1) + '\n',
                                      encoding='utf-8')
    if args.fbx or args.importer:
        import import_animations as ia
        out = Path(args.fbx or ROOT / 'build/koach_fbx')
        for ident, (anim, m) in motions.items():
            kr.write_fbx(m, out / f'{ident}.fbx')
        if args.importer:
            ia.import_koach([(anim, out / f'{ident}.fbx') for ident, (anim, _) in motions.items()])
    if not all(r['ok'] for r in reports):
        sys.exit(1)


if __name__ == '__main__':
    main()
