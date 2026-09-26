"""Cinématique 2D du squelette Kalis Track (L9, KT-046).

Repère normalisé : unité = taille du personnage (1,0), axe y vers le haut,
sol en y = 0. Origine x placée sous le centre de masse de l'image clé 0
(voir build_poses.finalize).

Convention d'angle ABSOLU (degrés) pour chaque segment, mesurée dans le plan
de la vue :
  - segments « vers le bas » (bras, avant-bras, cuisse, jambe, pied) :
    0 = pointe vers le bas, +90 = pointe vers +x (vers l'avant en profil,
    vers la gauche du personnage en vue de face), 180 = vers le haut ;
  - segments « vers le haut » (tronc t, cou n) : 0 = vertical vers le haut,
    +90 = penché vers +x.
Le moteur JavaScript (renderer_reference/kt_pose.js) reproduit exactement ce
calcul ; toute modification doit être faite des deux côtés.
"""
import math

# Longueurs de segments (fraction de la taille) -----------------------------
L = {
    "tronc": 0.300,        # bassin -> cou (base)
    "epaule_sur_tronc": 0.265,  # position de l'épaule le long du tronc
    "cou": 0.095,          # cou -> centre de la tête
    "bras": 0.180,         # épaule -> coude
    "avant_bras": 0.190,   # coude -> centre de la prise (main incluse)
    "cuisse": 0.245,       # hanche -> genou
    "jambe": 0.245,        # genou -> cheville
    "pied_profil": 0.130,  # cheville -> pointe de pied (profil)
    "pied_face": 0.045,    # cheville -> sol (vue de face)
    "demi_epaules_face": 0.120,
    "demi_bassin_face": 0.085,
}
HEAD_R = 0.062

JOINTS = ["tete", "cou", "epaule_g", "epaule_d", "coude_g", "coude_d",
          "poignet_g", "poignet_d", "bassin", "hanche_g", "hanche_d",
          "genou_g", "genou_d", "cheville_g", "cheville_d", "pied_g", "pied_d"]

# Segments dessinés / contrôlés (nom, articulation A, articulation B)
SEGMENTS = [
    ("cou", "cou", "tete"),
    ("tronc", "bassin", "cou"),
    ("ceinture_g", "cou", "epaule_g"), ("ceinture_d", "cou", "epaule_d"),
    ("bras_g", "epaule_g", "coude_g"), ("bras_d", "epaule_d", "coude_d"),
    ("avant_bras_g", "coude_g", "poignet_g"), ("avant_bras_d", "coude_d", "poignet_d"),
    ("bassin_g", "bassin", "hanche_g"), ("bassin_d", "bassin", "hanche_d"),
    ("cuisse_g", "hanche_g", "genou_g"), ("cuisse_d", "hanche_d", "genou_d"),
    ("jambe_g", "genou_g", "cheville_g"), ("jambe_d", "genou_d", "cheville_d"),
    ("pied_g", "cheville_g", "pied_g"), ("pied_d", "cheville_d", "pied_d"),
]

# Masses segmentaires relatives (Winter, arrondies) pour le centre de masse
MASS = {"tete": 0.081, "tronc": 0.497, "bras": 0.028, "avant_bras": 0.022,
        "cuisse": 0.100, "jambe": 0.0465, "pied": 0.0145}

ANGLE_KEYS = ["t", "n", "p"] + [f"{k}_{s}" for s in ("g", "d") for k in ("ua", "fa", "th", "sh", "ft")]


def _down(theta, length):
    r = math.radians(theta)
    return (math.sin(r) * length, -math.cos(r) * length)


def _up(theta, length):
    r = math.radians(theta)
    return (math.sin(r) * length, math.cos(r) * length)


def _add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def fk(angles, view, pelvis=(0.0, 0.0)):
    """Positions des articulations à partir des angles absolus."""
    a = {k: float(angles.get(k, 0.0)) for k in ANGLE_KEYS}
    if "n" not in angles:
        a["n"] = a["t"]
    if "p" not in angles:
        a["p"] = a["t"]
    J = {"bassin": pelvis}
    t = a["t"]
    J["cou"] = _add(pelvis, _up(t, L["tronc"]))
    J["tete"] = _add(J["cou"], _up(a["n"], L["cou"]))
    sh_pt = _add(pelvis, _up(t, L["epaule_sur_tronc"]))
    if view == "face":
        # perpendiculaire au tronc, côté gauche du personnage = +x
        px, py = math.cos(math.radians(t)), -math.sin(math.radians(t))
        J["epaule_g"] = (sh_pt[0] + px * L["demi_epaules_face"], sh_pt[1] + py * L["demi_epaules_face"])
        J["epaule_d"] = (sh_pt[0] - px * L["demi_epaules_face"], sh_pt[1] - py * L["demi_epaules_face"])
        # orientation propre du bassin (p) : par défaut celle du tronc
        qx, qy = math.cos(math.radians(a["p"])), -math.sin(math.radians(a["p"]))
        J["hanche_g"] = (pelvis[0] + qx * L["demi_bassin_face"], pelvis[1] + qy * L["demi_bassin_face"])
        J["hanche_d"] = (pelvis[0] - qx * L["demi_bassin_face"], pelvis[1] - qy * L["demi_bassin_face"])
    else:
        J["epaule_g"] = J["epaule_d"] = sh_pt
        J["hanche_g"] = J["hanche_d"] = pelvis
    for s in ("g", "d"):
        J[f"coude_{s}"] = _add(J[f"epaule_{s}"], _down(a[f"ua_{s}"], L["bras"]))
        J[f"poignet_{s}"] = _add(J[f"coude_{s}"], _down(a[f"fa_{s}"], L["avant_bras"]))
        J[f"genou_{s}"] = _add(J[f"hanche_{s}"], _down(a[f"th_{s}"], L["cuisse"]))
        J[f"cheville_{s}"] = _add(J[f"genou_{s}"], _down(a[f"sh_{s}"], L["jambe"]))
        lf = L["pied_face"] if view == "face" else L["pied_profil"]
        J[f"pied_{s}"] = _add(J[f"cheville_{s}"], _down(a[f"ft_{s}"], lf))
    return J


def com(J):
    def mid(a, b):
        return ((J[a][0] + J[b][0]) / 2, (J[a][1] + J[b][1]) / 2)
    parts = [(J["tete"], MASS["tete"]), (mid("bassin", "cou"), MASS["tronc"])]
    for s in ("g", "d"):
        parts += [(mid(f"epaule_{s}", f"coude_{s}"), MASS["bras"]),
                  (mid(f"coude_{s}", f"poignet_{s}"), MASS["avant_bras"]),
                  (mid(f"hanche_{s}", f"genou_{s}"), MASS["cuisse"]),
                  (mid(f"genou_{s}", f"cheville_{s}"), MASS["jambe"]),
                  (mid(f"cheville_{s}", f"pied_{s}"), MASS["pied"])]
    m = sum(w for _, w in parts)
    return (sum(p[0] * w for p, w in parts) / m, sum(p[1] * w for p, w in parts) / m)


def norm180(x):
    x = (x + 180.0) % 360.0 - 180.0
    return 180.0 if x == -180.0 else x


WINDOWS = {"cou": -150, "epaule": -150, "coude": -100, "hanche": -110, "genou": -100, "cheville": -110}


def wrap(x, lo):
    """Ramène x dans la fenêtre [lo, lo + 360)."""
    return (x - lo) % 360.0 + lo


def joint_angles(angles, view):
    """Angles articulaires RELATIFS (degrés) utilisés par les contrôles d'amplitude.

    Profil : flexion positive (épaule, hanche = segment relatif à la direction
    « bas du tronc », qui vaut -t) ; vue de face : abduction positive.
    """
    a = {k: float(angles.get(k, 0.0)) for k in ANGLE_KEYS}
    n = float(angles.get("n", a["t"]))
    t = a["t"]
    W = WINDOWS
    out = {"cou": wrap(n - t, W["cou"])}
    for s, k in (("g", 1), ("d", -1)):
        if view == "face":
            out[f"epaule_{s}"] = wrap(k * (a[f"ua_{s}"] + t), W["epaule"])
            out[f"coude_{s}"] = wrap(k * (a[f"fa_{s}"] - a[f"ua_{s}"]), -180)
            out[f"hanche_{s}"] = wrap(k * (a[f"th_{s}"] + float(angles.get("p", t))), W["hanche"])
            out[f"genou_{s}"] = wrap(-k * (a[f"sh_{s}"] - a[f"th_{s}"]), -180)
            out[f"cheville_{s}"] = wrap(k * (a[f"ft_{s}"] - a[f"sh_{s}"]), -180)
        else:
            out[f"epaule_{s}"] = wrap(a[f"ua_{s}"] + t, W["epaule"])
            out[f"coude_{s}"] = wrap(a[f"fa_{s}"] - a[f"ua_{s}"], W["coude"])
            out[f"hanche_{s}"] = wrap(a[f"th_{s}"] + t, W["hanche"])
            out[f"genou_{s}"] = wrap(a[f"th_{s}"] - a[f"sh_{s}"], W["genou"])
            out[f"cheville_{s}"] = wrap(a[f"ft_{s}"] - a[f"sh_{s}"], W["cheville"])
    return out


# Bornes d'amplitude plausibles (degrés) --------------------------------------
ROM = {
    "profil": {"cou": (-50, 60), "epaule": (-95, 195), "coude": (-5, 160),
               "hanche": (-40, 150), "genou": (-5, 160), "cheville": (5, 135)},
    "face": {"cou": (-45, 45), "epaule": (-30, 190), "coude": (-160, 160),
             "hanche": (-30, 90), "genou": (-40, 125), "cheville": (-40, 40)},
}

# Décalage de contact : hauteur du point articulaire au-dessus de la surface
CONTACT_OFFSET = {"pied": 0.0, "cheville": 0.045, "genou": 0.045, "poignet": 0.012,
                  "coude": 0.035, "bassin": 0.075, "hanche": 0.075, "cou": 0.07,
                  "epaule": 0.065, "tete": HEAD_R}


def contact_offset(joint):
    return CONTACT_OFFSET.get(joint.rsplit("_", 1)[0] if joint.endswith(("_g", "_d")) else joint, 0.0)
