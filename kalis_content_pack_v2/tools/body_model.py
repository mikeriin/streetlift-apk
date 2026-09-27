"""Modèle corporel 2D de Kalis Track v2 (L9R, étape 4) : longueurs de segments,
cinématique directe à partir d'ANGLES ARTICULAIRES anatomiques, centre de masse.

Repère : unité = taille du personnage (H = 1), y vers le haut, sol en y = 0.
Vue de profil : le personnage regarde vers +x. Vue de face : +x = côté GAUCHE
du personnage (comme dans la v1), le personnage fait face au lecteur.

Longueurs (fractions de la taille) : proportions de Drillis & Contini (1966),
reproduites dans Winter, Biomechanics and Motor Control of Human Movement,
fig. 4.1 ; masses et centres de masse segmentaires : Winter, table 4.1 (voir
sources/cinematique_references.json, section proportions_segments).

Angles articulaires (degrés) — ce sont les valeurs de la fiche biomécanique :
  t      inclinaison absolue du tronc : 0 = vertical, + = penché vers +x (vers l'avant en profil)
  n      tête par rapport au tronc : 0 = dans l'axe, + = regard vers +x / extension
  hanche flexion de hanche : 0 = cuisse dans l'axe du tronc, + = flexion (genou vers l'avant)
  genou  flexion du genou : 0 = jambe tendue, + = flexion
  cheville flexion dorsale : 0 = pied à 90° de la jambe, + = pointe relevée, − = pointe tendue
  epaule flexion d'épaule (profil) : 0 = bras le long du tronc, 90 = bras horizontal devant, 180 = au-dessus de la tête, − = extension
         (vue de face : abduction, 0 = bras le long du corps, 180 = au-dessus de la tête)
  coude  flexion du coude : 0 = bras tendu, + = flexion (la main revient vers l'épaule)
  poignet angle main / avant-bras : 0 = dans l'axe, + = extension (dos de la main vers l'avant-bras)
  p      (vue de face) orientation absolue du bassin ; défaut : celle du tronc
Chaque angle de membre existe pour les côtés _g (gauche) et _d (droite).

Conversion en angles ABSOLUS de segment (convention v1 conservée pour le moteur
JS : segments « vers le bas » : 0 = vers le bas, +90 = vers +x ; tronc et cou :
0 = vers le haut, +90 = vers +x) :
  bras = −t + epaule ; avant_bras = bras + coude ; main = avant_bras + poignet
  cuisse = −t + hanche ; jambe = cuisse − genou ; pied = jambe + 90 + cheville
"""
import math

# ---- longueurs (H = 1) -----------------------------------------------------
L = {
    "tronc": 0.288,          # hanche -> épaule (0.818 − 0.530)
    "cou": 0.110,            # épaule -> centre de la tête
    "bras": 0.186,
    "avant_bras": 0.146,
    "main": 0.108,           # poignet -> bout des doigts
    "prise": 0.050,          # poignet -> centre de la prise (milieu de la paume)
    "cuisse": 0.245,
    "jambe": 0.246,
    "pied_talon": 0.045,     # cheville -> arrière du talon (horizontal, pied à plat)
    "pied_pointe": 0.107,    # cheville -> pointe (0.152 − 0.045)
    "pied_hauteur": 0.039,   # hauteur de la cheville au-dessus du sol, pied à plat
    "demi_epaules_face": 0.130,
    "demi_bassin_face": 0.095,
}
HEAD_R = 0.065
# Épaisseurs pour la silhouette (profil) : (proximal, distal), en fraction de H
WIDTH = {"bras": (0.052, 0.040), "avant_bras": (0.040, 0.028), "main": (0.026, 0.020),
         "cuisse": (0.082, 0.052), "jambe": (0.054, 0.030), "pied": (0.030, 0.020), "cou": (0.045, 0.045)}

JOINTS = ["tete", "cou", "epaule_g", "epaule_d", "coude_g", "coude_d", "poignet_g", "poignet_d", "main_g", "main_d",
          "prise_g", "prise_d", "bassin", "hanche_g", "hanche_d", "genou_g", "genou_d", "cheville_g", "cheville_d",
          "talon_g", "talon_d", "pied_g", "pied_d"]

SEGMENTS = [("cou", "cou", "tete"), ("tronc", "bassin", "cou"),
            ("bras_g", "epaule_g", "coude_g"), ("bras_d", "epaule_d", "coude_d"),
            ("avant_bras_g", "coude_g", "poignet_g"), ("avant_bras_d", "coude_d", "poignet_d"),
            ("main_g", "poignet_g", "main_g"), ("main_d", "poignet_d", "main_d"),
            ("cuisse_g", "hanche_g", "genou_g"), ("cuisse_d", "hanche_d", "genou_d"),
            ("jambe_g", "genou_g", "cheville_g"), ("jambe_d", "genou_d", "cheville_d"),
            ("pied_g", "talon_g", "pied_g"), ("pied_d", "talon_d", "pied_d")]
SEG_LEN = {"cou": L["cou"], "tronc": L["tronc"], "bras": L["bras"], "avant_bras": L["avant_bras"], "main": L["main"],
           "cuisse": L["cuisse"], "jambe": L["jambe"], "pied": L["pied_talon"] + L["pied_pointe"]}

# masses relatives et position du centre de masse depuis l'extrémité proximale (Winter, table 4.1)
MASS = {"tete": (0.081, None), "tronc": (0.497, 0.50), "bras": (0.028, 0.436), "avant_bras": (0.016, 0.430),
        "main": (0.006, 0.506), "cuisse": (0.100, 0.433), "jambe": (0.0465, 0.433), "pied": (0.0145, 0.50)}

SIDES = ("g", "d")
JOINT_KEYS = ["hanche", "genou", "cheville", "epaule", "coude", "poignet"]
ABS_KEYS = ["t", "n", "p"] + [f"{k}_{s}" for s in SIDES for k in ("ua", "fa", "ha", "th", "sh", "ft")]

# amplitudes normales (degrés) : Physiopedia « Range of Motion Normative Values » (consulté le 26/09/2026),
# élargies de 10° pour les gestes sportifs ; les figures avancées déclarent leurs exceptions.
ROM = {
    "hanche": (-30, 135), "genou": (-5, 155), "cheville": (-60, 40), "epaule": (-70, 190),
    "coude": (-5, 155), "poignet": (-90, 90), "cou": (-60, 70),
    # vue de face
    "hanche_abd": (-30, 100), "epaule_abd": (-10, 190), "coude_face": (-5, 155),
}


def _down(theta, length):
    r = math.radians(theta)
    return (math.sin(r) * length, -math.cos(r) * length)


def _up(theta, length):
    r = math.radians(theta)
    return (math.sin(r) * length, math.cos(r) * length)


def _add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def anat_to_abs(a):
    """Angles articulaires anatomiques -> angles absolus de segments (profil)."""
    t = float(a.get("t", 0.0))
    out = {"t": t, "n": t + float(a.get("n", 0.0))}
    for s in SIDES:
        sh = float(a.get(f"epaule_{s}", a.get("epaule", 0.0)))
        el = float(a.get(f"coude_{s}", a.get("coude", 0.0)))
        wr = float(a.get(f"poignet_{s}", a.get("poignet", 0.0)))
        hip = float(a.get(f"hanche_{s}", a.get("hanche", 0.0)))
        kn = float(a.get(f"genou_{s}", a.get("genou", 0.0)))
        an = float(a.get(f"cheville_{s}", a.get("cheville", 0.0)))
        out[f"ua_{s}"] = -t + sh
        out[f"fa_{s}"] = out[f"ua_{s}"] + el
        out[f"ha_{s}"] = out[f"fa_{s}"] + wr
        out[f"th_{s}"] = -t + hip
        out[f"sh_{s}"] = out[f"th_{s}"] - kn
        out[f"ft_{s}"] = out[f"sh_{s}"] + 90 + an
    out["p"] = float(a.get("p", t))
    return out


def anat_to_abs_face(a):
    """Vue de face : abductions (bras, jambes) ; le coude et le genou fléchissent dans le plan frontal
    (avant-bras vers le haut / vers la ligne médiane)."""
    t = float(a.get("t", 0.0))
    out = {"t": t, "n": t + float(a.get("n", 0.0)), "p": float(a.get("p", t))}
    for s, k in (("g", 1), ("d", -1)):
        abd = float(a.get(f"epaule_{s}", a.get("epaule", 0.0)))
        el = float(a.get(f"coude_{s}", a.get("coude", 0.0)))
        habd = float(a.get(f"hanche_{s}", a.get("hanche", 0.0)))
        kn = float(a.get(f"genou_{s}", a.get("genou", 0.0)))
        out[f"ua_{s}"] = -t + k * abd
        # coude : la flexion ramène l'avant-bras vers le haut (bras horizontal) / vers l'axe
        out[f"fa_{s}"] = out[f"ua_{s}"] + k * el
        out[f"ha_{s}"] = out[f"fa_{s}"]
        out[f"th_{s}"] = -out["p"] + k * habd
        out[f"sh_{s}"] = out[f"th_{s}"] - k * kn
        out[f"ft_{s}"] = out[f"sh_{s}"]
    return out


def fk_abs(A, view, pelvis=(0.0, 0.0)):
    """Positions des articulations à partir des angles absolus."""
    t, n, p = A["t"], A.get("n", A["t"]), A.get("p", A["t"])
    P = pelvis
    J = {"bassin": P}
    J["cou"] = _add(P, _up(t, L["tronc"]))
    J["tete"] = _add(J["cou"], _up(n, L["cou"]))
    if view == "face":
        px, py = math.cos(math.radians(t)), -math.sin(math.radians(t))
        J["epaule_g"] = (J["cou"][0] + px * L["demi_epaules_face"], J["cou"][1] + py * L["demi_epaules_face"])
        J["epaule_d"] = (J["cou"][0] - px * L["demi_epaules_face"], J["cou"][1] - py * L["demi_epaules_face"])
        qx, qy = math.cos(math.radians(p)), -math.sin(math.radians(p))
        J["hanche_g"] = (P[0] + qx * L["demi_bassin_face"], P[1] + qy * L["demi_bassin_face"])
        J["hanche_d"] = (P[0] - qx * L["demi_bassin_face"], P[1] - qy * L["demi_bassin_face"])
    else:
        J["epaule_g"] = J["epaule_d"] = J["cou"]
        J["hanche_g"] = J["hanche_d"] = P
    for s in SIDES:
        J[f"coude_{s}"] = _add(J[f"epaule_{s}"], _down(A[f"ua_{s}"], L["bras"]))
        J[f"poignet_{s}"] = _add(J[f"coude_{s}"], _down(A[f"fa_{s}"], L["avant_bras"]))
        J[f"main_{s}"] = _add(J[f"poignet_{s}"], _down(A[f"ha_{s}"], L["main"]))
        J[f"prise_{s}"] = _add(J[f"poignet_{s}"], _down(A[f"ha_{s}"], L["prise"]))
        J[f"genou_{s}"] = _add(J[f"hanche_{s}"], _down(A[f"th_{s}"], L["cuisse"]))
        J[f"cheville_{s}"] = _add(J[f"genou_{s}"], _down(A[f"sh_{s}"], L["jambe"]))
        if view == "face":
            # pied vu de face : petit segment vers le bas (hauteur du pied) ; talon = cheville
            J[f"pied_{s}"] = _add(J[f"cheville_{s}"], _down(A[f"sh_{s}"], L["pied_hauteur"]))
            J[f"talon_{s}"] = J[f"cheville_{s}"]
        else:
            # pied de profil : la plante va du talon à la pointe ; la cheville est au-dessus de la plante
            ft = A[f"ft_{s}"]
            sole_dir = _down(ft, 1.0)                       # direction talon -> pointe
            perp = (sole_dir[1], -sole_dir[0])              # normale « vers le bas » de la plante (pied à plat : (0,-1))
            base = (J[f"cheville_{s}"][0] + perp[0] * L["pied_hauteur"], J[f"cheville_{s}"][1] + perp[1] * L["pied_hauteur"])
            J[f"talon_{s}"] = (base[0] - sole_dir[0] * L["pied_talon"], base[1] - sole_dir[1] * L["pied_talon"])
            J[f"pied_{s}"] = (base[0] + sole_dir[0] * L["pied_pointe"], base[1] + sole_dir[1] * L["pied_pointe"])
    return J


def fk(anat, view, pelvis=(0.0, 0.0)):
    A = anat_to_abs_face(anat) if view == "face" else anat_to_abs(anat)
    return A, fk_abs(A, view, pelvis)


def com(J):
    def lerp(a, b, f):
        return (J[a][0] + (J[b][0] - J[a][0]) * f, J[a][1] + (J[b][1] - J[a][1]) * f)
    parts = [(J["tete"], MASS["tete"][0]), (lerp("cou", "bassin", MASS["tronc"][1]), MASS["tronc"][0])]
    for s in SIDES:
        parts += [(lerp(f"epaule_{s}", f"coude_{s}", MASS["bras"][1]), MASS["bras"][0]),
                  (lerp(f"coude_{s}", f"poignet_{s}", MASS["avant_bras"][1]), MASS["avant_bras"][0]),
                  (lerp(f"poignet_{s}", f"main_{s}", MASS["main"][1]), MASS["main"][0]),
                  (lerp(f"hanche_{s}", f"genou_{s}", MASS["cuisse"][1]), MASS["cuisse"][0]),
                  (lerp(f"genou_{s}", f"cheville_{s}", MASS["jambe"][1]), MASS["jambe"][0]),
                  (lerp(f"talon_{s}", f"pied_{s}", MASS["pied"][1]), MASS["pied"][0])]
    m = sum(w for _, w in parts)
    return (sum(p[0] * w for p, w in parts) / m, sum(p[1] * w for p, w in parts) / m)


def translate(J, dx, dy):
    return {k: (v[0] + dx, v[1] + dy) for k, v in J.items()}


def lowest_y(J):
    return min(v[1] for v in J.values())


# décalage de contact : hauteur du point articulaire au-dessus de la surface d'appui
CONTACT_OFFSET = {"pied": 0.0, "talon": 0.0, "cheville": L["pied_hauteur"], "genou": 0.045, "poignet": 0.014,
                  "prise": 0.0, "main": 0.0, "coude": 0.03, "bassin": 0.085, "hanche": 0.085, "cou": 0.07,
                  "epaule": 0.07, "tete": HEAD_R}


def contact_offset(joint):
    base = joint.rsplit("_", 1)[0] if joint.endswith(("_g", "_d")) else joint
    return CONTACT_OFFSET.get(base, 0.0)
