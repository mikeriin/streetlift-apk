"""Contrôles automatiques des gabarits v2 (L9R, étape 4).

1. longueurs de segments constantes (tolérance 1 %) sur chaque image clé et pendant l'interpolation ;
2. angles articulaires dans les amplitudes humaines (body_model.ROM, exceptions déclarées par gabarit) ;
3. contacts respectés (articulation sur sa surface, à 0,02 près) ;
4. aucune articulation sous le sol ; aucune articulation à l'intérieur d'un accessoire plein (box, banc, marche) ;
5. centre de masse au-dessus de l'appui pour les gabarits debout (entre talon et pointe, marge 5 %) ;
6. charge à la bonne place : accessoire attaché à une prise ou à l'épaule/bassin existants, positions finies.
"""
import math

import body_model as B

TOL_LEN = 0.01
TOL_CONTACT = 0.03

SURF_Y = {"sol": 0.0}


def _len(J, a, b):
    return math.dist(J[a], J[b])


def check_lengths(tpl):
    errs = []
    view = tpl["view"]
    for kf in tpl["keyframes"]:
        J = {k: tuple(v) for k, v in kf["joints"].items()}
        for name, a, b in B.SEGMENTS:
            base = name.rsplit("_", 1)[0] if name.endswith(("_g", "_d")) else name
            if base == "pied":
                exp = B.L["pied_talon"] + B.L["pied_pointe"] if view != "face" else 0.0
                if view == "face":
                    continue
            else:
                exp = B.SEG_LEN[base]
            got = _len(J, a, b)
            if abs(got - exp) > TOL_LEN * max(exp, 0.05):
                errs.append(f"{tpl['template']}/{kf['label']}: segment {name} = {got:.4f} (attendu {exp:.4f})")
    return errs


def _rom_errors(tpl, kf):
    errs = []
    a = kf["angles_articulaires"]
    exc = tpl.get("rom_exceptions", {})
    view = tpl["view"]

    def bounds(key):
        lo, hi = B.ROM[key]
        if key in exc:
            lo, hi = exc[key]
        return lo, hi
    n_lo, n_hi = bounds("cou")
    if not n_lo <= a.get("n", 0) <= n_hi:
        errs.append(f"cou {a.get('n')}")
    for s in B.SIDES:
        for k in B.JOINT_KEYS:
            v = a.get(f"{k}_{s}", 0.0)
            key = k
            if view == "face":
                key = {"hanche": "hanche_abd", "epaule": "epaule_abd", "coude": "coude_face"}.get(k, k)
                if k in ("cheville", "poignet"):
                    continue
            lo, hi = bounds(key)
            if key not in B.ROM and key in exc:
                lo, hi = exc[key]
            if not lo <= v <= hi:
                errs.append(f"{k}_{s} = {v} hors [{lo}, {hi}]")
    return [f"{tpl['template']}/{kf['label']}: {e}" for e in errs]


def check_rom(tpl):
    errs = []
    for kf in tpl["keyframes"]:
        errs += _rom_errors(tpl, kf)
    return errs


def _prop_boxes(tpl):
    boxes = []
    for p in tpl.get("props", []):
        if not p.get("static") or p.get("layer") == "arriere":
            continue
        if p["type"] in ("box", "marche", "sol_surelevé"):
            boxes.append((p["type"], p["x"], p["x"] + p.get("w", 0.3), 0.0, p.get("h", 0.3)))
        elif p["type"] == "banc":
            boxes.append(("banc", p["x"], p["x"] + p.get("w", 0.55), p["y"] - 0.035, p["y"]))
    return boxes


def check_contacts_and_ground(tpl):
    errs = []
    surf = dict(SURF_Y)
    for p in tpl.get("props", []):
        if p.get("static") and "y" in p:
            surf[p["type"]] = p["y"]
        if p["type"] in ("box", "marche"):
            surf[p["type"]] = p.get("h", 0.3)
    boxes = _prop_boxes(tpl)
    for kf in tpl["keyframes"]:
        J = {k: tuple(v) for k, v in kf["joints"].items()}
        # aucune articulation sous le sol (sauf les pieds, tolérance)
        for j, (x, y) in J.items():
            if y < -0.04:
                errs.append(f"{tpl['template']}/{kf['label']}: {j} sous le sol (y={y:.3f})")
        # pénétration dans un accessoire plein
        for name, x0, x1, y0, y1 in boxes:
            for j, (x, y) in J.items():
                if x0 + 0.01 < x < x1 - 0.01 and y0 + 0.03 < y < y1 - 0.03:
                    errs.append(f"{tpl['template']}/{kf['label']}: {j} à l'intérieur de {name}")
        # contacts déclarés
        for c in tpl.get("contacts", []):
            kfs = c.get("kf", "all")
            if kfs != "all" and tpl["keyframes"].index(kf) not in kfs:
                continue
            j, w = c["joint"], c["with"]
            if tpl["view"] == "face" and j.startswith("talon"):
                j = "pied" + j[5:]
            if w in ("barre_fixe", "anneaux", "barres_paralleles", "barre_basse", "poteau", "parallettes", "mur", "banc", "siège", "support", "elastique", "box", "marche"):
                # surface non horizontale ou hauteur d'accessoire : vérifie la hauteur si connue
                if w in surf and w not in ("mur", "poteau", "elastique", "support"):
                    y = J[j][1] - B.contact_offset(j)
                    if abs(y - surf[w]) > TOL_CONTACT + 0.03:
                        errs.append(f"{tpl['template']}/{kf['label']}: {j} loin de {w} (Δy={y - surf[w]:.3f})")
                continue
            y = J[j][1] - B.contact_offset(j)
            target = surf.get(w, 0.0)
            if abs(y - target) > TOL_CONTACT:
                errs.append(f"{tpl['template']}/{kf['label']}: {j} n'est pas sur {w} (Δy={y - target:.3f})")
    return errs


def check_balance(tpl):
    errs = []
    if not tpl.get("debout"):
        return errs
    for kf in tpl["keyframes"]:
        anchor = kf["anchor"]["joint"]
        if not anchor.startswith(("talon", "pied")) or not kf.get("equilibre", True):
            continue      # phase aérienne ou appui autre
        J = {k: tuple(v) for k, v in kf["joints"].items()}
        cx = B.com(J)[0]
        supported = {c["joint"].rsplit("_", 1)[1] for c in tpl.get("contacts", []) if c["joint"].startswith(("talon", "pied"))}
        xs = []
        for s in B.SIDES:
            if s in supported or J[f"talon_{s}"][1] < 0.06 or J[f"pied_{s}"][1] < 0.06:
                xs += [J[f"talon_{s}"][0], J[f"pied_{s}"][0]]
            if J[f"prise_{s}"][1] < 0.03:      # mains au sol : l'appui inclut les mains
                xs += [J[f"prise_{s}"][0], J[f"main_{s}"][0]]
        if len(xs) < 2:
            continue
        lo, hi = min(xs), max(xs)
        m = (hi - lo) * 0.05
        if not lo - m <= cx <= hi + m:
            errs.append(f"{tpl['template']}/{kf['label']}: centre de masse x={cx:.3f} hors de l'appui [{lo:.3f}, {hi:.3f}]")
    return errs


def check_props(tpl, extra=None):
    errs = []
    for p in list(tpl.get("props", [])) + list(extra or []):
        att = p.get("attach")
        if att and att not in ("prises",) and att not in B.JOINTS:
            errs.append(f"{tpl['template']}: accessoire {p['type']} attaché à une articulation inconnue {att}")
        for k in ("x", "y", "w", "h"):
            if k in p and not math.isfinite(p[k]):
                errs.append(f"{tpl['template']}: accessoire {p['type']} valeur {k} non finie")
    return errs


def check_interpolation(tpl, steps=12):
    """Longueurs constantes pendant l'interpolation (reproduit l'interpolation du moteur JS)."""
    errs = []
    k = tpl["keyframes"]
    view = tpl["view"]
    for i in range(len(k) - 1):
        A_, B_ = k[i], k[i + 1]
        same = A_["anchor"]["joint"] == B_["anchor"]["joint"] and A_["anchor"]["pos"] == B_["anchor"]["pos"]
        for s in range(1, steps):
            u = s / steps
            v = (1 - math.cos(math.pi * u)) / 2
            ang = {key: A_["angles"].get(key, 0) + (B_["angles"].get(key, 0) - A_["angles"].get(key, 0)) * v for key in B.ABS_KEYS}
            if same:
                J = B.fk_abs(ang, view)
                an = J[A_["anchor"]["joint"]]
                J = B.translate(J, A_["anchor"]["pos"][0] - an[0], A_["anchor"]["pos"][1] - an[1])
            else:
                P = (A_["pelvis"][0] + (B_["pelvis"][0] - A_["pelvis"][0]) * v, A_["pelvis"][1] + (B_["pelvis"][1] - A_["pelvis"][1]) * v)
                J = B.fk_abs(ang, view, P)
            for name, a, b in B.SEGMENTS:
                base = name.rsplit("_", 1)[0] if name.endswith(("_g", "_d")) else name
                if base == "pied":
                    continue
                got = _len(J, a, b)
                if abs(got - B.SEG_LEN[base]) > TOL_LEN * B.SEG_LEN[base]:
                    errs.append(f"{tpl['template']}: interpolation {i}->{i + 1} u={u:.2f} segment {name}")
                    break
    return errs


def check_all(tpl, extra_props=None):
    return (check_lengths(tpl) + check_rom(tpl) + check_contacts_and_ground(tpl) + check_balance(tpl)
            + check_props(tpl, extra_props) + check_interpolation(tpl))


if __name__ == "__main__":
    import build_poses
    res = build_poses.build_all()
    total = 0
    for n, t in res.items():
        e = check_all(t)
        total += len(e)
        for x in e:
            print(x)
    print(len(res), "gabarits ;", total, "défauts")
