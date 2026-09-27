"""Résolution des images clés à partir des fiches biomécaniques (L9R, étape 4).

Une fiche (voir biomeca.py) donne, pour chaque image clé, les angles
articulaires anatomiques, un ancrage (articulation posée sur le sol ou un
accessoire) et des contraintes (second appui au sol, centre de masse au-dessus
de l'appui, main à plat…) résolues en ajustant les paramètres déclarés libres
dans leurs bornes. Les positions ne sont jamais posées à la main : elles sont
calculées par cinématique directe (body_model.fk) puis translation d'ancrage.
"""
import math

import body_model as B


def set_param(anat, name, v):
    """Affecte un paramètre ; une clé générique (hanche, genou…) s'applique aux deux côtés."""
    if name in B.JOINT_KEYS:
        anat[f"{name}_g"] = v
        anat[f"{name}_d"] = v
    else:
        anat[name] = v


def place(anat, view, anchor):
    A, J = B.fk(anat, view)
    joint, pos = anchor
    dx, dy = pos[0] - J[joint][0], pos[1] - J[joint][1]
    return A, B.translate(J, dx, dy)


def _err(c, A, J, view):
    kind = c[0]
    if kind == "y":            # articulation à une hauteur (surface + décalage de contact)
        _, joint, value = c[:3]
        return J[joint][1] - (value + B.contact_offset(joint))
    if kind == "x":
        _, joint, value = c[:3]
        return J[joint][0] - value
    if kind == "com_over":     # centre de masse au-dessus de l'appui [jA, jB] (avec marge)
        _, ja, jb = c[:3]
        cx = B.com(J)[0]
        lo, hi = sorted((J[ja][0], J[jb][0]))
        margin = (hi - lo) * 0.25
        lo, hi = lo + margin, hi - margin
        if cx < lo:
            return cx - lo
        if cx > hi:
            return cx - hi
        return 0.0
    if kind == "com_x":        # centre de masse à une abscisse (ex. sous la prise, en suspension)
        _, joint, dx = c[0], c[1], (c[2] if len(c) > 2 else 0.0)
        return B.com(J)[0] - (J[joint][0] + dx)
    if kind == "com_between":  # centre de masse entre joint+lo et joint+hi (tolérance)
        _, joint, lo, hi = c[:4]
        cx = B.com(J)[0] - J[joint][0]
        if cx < lo:
            return cx - lo
        if cx > hi:
            return cx - hi
        return 0.0
    if kind == "abs":          # angle absolu d'un segment (ex. main à plat : ha_d = 90)
        _, key, value = c[:3]
        d = (A[key] - value + 180) % 360 - 180
        return d / 400.0
    if kind == "dist":         # distance entre deux articulations
        _, ja, jb, value = c[:4]
        return math.dist(J[ja], J[jb]) - value
    if kind == "min_y":        # aucune articulation sous une hauteur (ex. sol)
        _, value = c[:2]
        low = B.lowest_y(J)
        return min(0.0, low - value)
    raise ValueError(kind)


def _total(cs, A, J, view):
    return sum(_err(c, A, J, view) ** 2 for c in cs)


def solve_keyframe(kf, view):
    anat = dict(kf["angles"])
    free = list(kf.get("free", []))
    cons = list(kf.get("constraints", []))
    anchor = kf["anchor"]
    if free and cons:
        for _round in range(4):
            for (name, lo, hi) in free:
                best_v, best_e = anat.get(name, anat.get(name + "_d", 0.0)), None
                steps = max(8, int((hi - lo) / 1.0))
                for i in range(steps + 1):
                    v = lo + (hi - lo) * i / steps
                    a2 = dict(anat)
                    set_param(a2, name, v)
                    A, J = place(a2, view, anchor)
                    e = _total(cons, A, J, view)
                    if best_e is None or e < best_e:
                        best_v, best_e = v, e
                span = (hi - lo) / steps
                for _ in range(3):
                    a0 = best_v - span
                    for i in range(21):
                        v = a0 + 2 * span * i / 20
                        if lo <= v <= hi:
                            a2 = dict(anat)
                            set_param(a2, name, v)
                            A, J = place(a2, view, anchor)
                            e = _total(cons, A, J, view)
                            if e < best_e:
                                best_v, best_e = v, e
                    span /= 10
                set_param(anat, name, round(best_v, 2))
    A, J = place(anat, view, anchor)
    residual = math.sqrt(_total(cons, A, J, view)) if cons else 0.0
    return anat, A, J, residual


def _round_pt(p, nd=4):
    return [round(p[0], nd), round(p[1], nd)]


def build_sheet(sheet):
    """Résout toutes les images clés d'une fiche ; retourne le gabarit v2 sérialisable."""
    view = sheet["vue"]
    kfs = []
    for kf in sheet["images_cles"]:
        anat, A, J, res = solve_keyframe(kf, view)
        kfs.append({"label": kf["label"], "angles_articulaires": {k: round(float(v), 2) for k, v in anat.items()},
                    "angles": {k: round(float(v), 2) for k, v in A.items()},
                    "pelvis": J["bassin"], "anchor": {"joint": kf["anchor"][0], "pos": list(kf["anchor"][1])},
                    "hold": kf.get("hold", 0.0), "dur": kf.get("dur", 1.0), "joints": J,
                    "residu": round(res, 4), "phase": kf.get("phase"), "equilibre": kf.get("equilibre", True)})
    # origine x sous le centre de masse de l'image clé 0 (sauf si la fiche fixe l'origine)
    cx = 0.0 if sheet.get("origine_fixe") else B.com(kfs[0]["joints"])[0]
    for kf in kfs:
        kf["joints"] = {k: _round_pt((v[0] - cx, v[1])) for k, v in kf["joints"].items()}
        kf["pelvis"] = _round_pt((kf["pelvis"][0] - cx, kf["pelvis"][1]))
        kf["anchor"]["pos"] = _round_pt((kf["anchor"]["pos"][0] - cx, kf["anchor"]["pos"][1]))
    props = []
    for p in sheet.get("accessoires", []):
        q = dict(p)
        if q.get("static") and "x" in q:
            q["x"] = round(q["x"] - cx, 4)
        if "x2" in q:
            q["x2"] = round(q["x2"] - cx, 4)
        props.append(q)
    return {
        "template": sheet["id"], "view": view, "loop": sheet.get("boucle", "aller-retour"),
        "keyframes": kfs, "props": props, "contacts": sheet.get("contacts", []),
        "rom_exceptions": sheet.get("rom_exceptions", {}),
        "fiche": {k: sheet.get(k) for k in ("phases", "articulations_motrices", "prise", "placement",
                                            "contacts_texte", "trajectoire_charge", "tempo", "sources", "note")},
        "debout": bool(sheet.get("debout", False)),
        "charge": sheet.get("charge"),
    }
