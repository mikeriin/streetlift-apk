"""Contrôles automatiques des poses (KT-046 / KT-048)."""
import math

import kinematics as K

LEN_TOL = 0.02       # 2 % de variation de longueur tolérée
CONTACT_TOL = 0.02   # 2 % de la taille
GROUND_TOL = 0.012


def seg_len(J, a, b):
    return math.dist(J[a], J[b])


def check_lengths(pose):
    errs = []
    ref = {s: seg_len(pose["keyframes"][0]["joints"], a, b) for s, a, b in K.SEGMENTS}
    for i, kf in enumerate(pose["keyframes"]):
        for s, a, b in K.SEGMENTS:
            l0 = ref[s]
            l1 = seg_len(kf["joints"], a, b)
            if l0 > 1e-6 and abs(l1 - l0) / l0 > LEN_TOL:
                errs.append(f"image {i} : segment {s} {l1:.3f} ≠ {l0:.3f}")
            elif l0 <= 1e-6 and l1 > 1e-3:
                errs.append(f"image {i} : segment {s} apparaît")
    # longueurs conformes à la table de référence
    J = pose["keyframes"][0]["joints"]
    expect = {"tronc": K.L["tronc"], "bras_d": K.L["bras"], "avant_bras_d": K.L["avant_bras"],
              "cuisse_d": K.L["cuisse"], "jambe_d": K.L["jambe"], "cou": K.L["cou"]}
    for s, v in expect.items():
        a, b = next((x[1], x[2]) for x in K.SEGMENTS if x[0] == s)
        if abs(seg_len(J, a, b) - v) / v > LEN_TOL:
            errs.append(f"segment {s} hors référence")
    return errs


def check_rom(pose):
    errs = []
    view = pose["view"]
    bounds = dict(K.ROM[view])
    for k, v in pose.get("rom_exceptions", {}).items():
        bounds[k] = tuple(v)
    for i, kf in enumerate(pose["keyframes"]):
        ja = K.joint_angles(kf["angles"], view)
        for j, v in ja.items():
            base = j.rsplit("_", 1)[0] if j.endswith(("_g", "_d")) else j
            lo, hi = bounds[base]
            if not (lo - 0.5 <= v <= hi + 0.5):
                errs.append(f"image {i} « {kf['label']} » : {j} = {v:.0f}° hors [{lo}, {hi}]")
    return errs


def _prop(pose, typ):
    for p in pose["props"]:
        if p["type"] == typ and p.get("static"):
            return p
    return None


def check_contacts(pose):
    errs = []
    n = len(pose["keyframes"])
    for c in pose["contacts"]:
        kfs = c.get("kf", "all")
        idx = range(n) if kfs == "all" else kfs
        for i in idx:
            J = pose["keyframes"][i]["joints"]
            x, y = J[c["joint"]]
            off = K.contact_offset(c["joint"])
            w = c["with"]
            if w == "sol":
                d = abs(y - off)
            elif w in ("banc", "box"):
                p = _prop(pose, w)
                top = p["y"] if w == "banc" else p["h"] if "h" in p else p["y"]
                if w == "box":
                    top = p["h"]
                d = abs(y - (top + off))
            elif w in ("barre_fixe", "anneaux", "barres_paralleles"):
                p = _prop(pose, w)
                if w == "barres_paralleles" and pose["view"] == "profil":
                    d = abs(y - p["y"])
                else:
                    d = math.dist((x, y), (p["x"], p["y"]))
            elif w == "mur":
                p = _prop(pose, "mur")
                d = abs(abs(x - p["x"]) - off)
            else:
                d = 0.0
            if d > CONTACT_TOL:
                errs.append(f"image {i} : contact {c['joint']}–{w} écart {d:.3f}")
    return errs


def check_ground(pose):
    errs = []
    for i, kf in enumerate(pose["keyframes"]):
        for j, (x, y) in kf["joints"].items():
            lim = -GROUND_TOL
            if j == "tete":
                lim = K.HEAD_R - GROUND_TOL - 0.02
            if y < lim:
                errs.append(f"image {i} : {j} sous le sol ({y:.3f})")
    return errs


def check_pose(pose):
    return {"longueurs": check_lengths(pose), "amplitudes": check_rom(pose),
            "contacts": check_contacts(pose), "sol": check_ground(pose)}
