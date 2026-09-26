"""Calcule les images clés (angles résolus + positions) des gabarits de pose."""
import copy
import math

import kinematics as K
import pose_templates as PT


def apply_link(angles, link, view):
    a = dict(angles)
    t = a["t"]
    if isinstance(link, list):
        for l in link:
            a = apply_link(a, l, view)
        return a
    if link in ("gaine_g", "gaine_d"):
        s = link[-1]
        a[f"th_{s}"] = -t
        a[f"sh_{s}"] = -t
        a[f"ft_{s}"] = -t + 75
        return a
    if link in ("gaine", "gaine_dos", "hanche_suit_legs"):
        for s in ("g", "d"):
            a[f"th_{s}"] = -t
            a[f"sh_{s}"] = -t
            a[f"ft_{s}"] = -t + (75 if link == "gaine" else 15)
    elif link == "gaine_face":
        for s in ("g", "d"):
            a[f"th_{s}"] = -t + (0 if s == "d" else a.get("_open", 0))
            a[f"sh_{s}"] = a[f"th_{s}"]
            a[f"ft_{s}"] = a[f"th_{s}"]
    elif link == "gaine_genoux":
        for s in ("g", "d"):
            a[f"th_{s}"] = -t
            a[f"sh_{s}"] = -90
            a[f"ft_{s}"] = -75
    elif link == "debout_incline":
        for s in ("g", "d"):
            a[f"th_{s}"] = -t
            a[f"sh_{s}"] = -t
            a[f"ft_{s}"] = 60
    elif link == "hanche_suit":
        for s in ("g", "d"):
            a[f"th_{s}"] = -t
    elif link == "pike":
        pass
    return a


def place(kf, view, angles=None):
    a = apply_link(angles if angles is not None else kf["angles"], kf.get("link"), view)
    J = K.fk(a, view)
    joint, pos = kf["anchor"]
    dx, dy = pos[0] - J[joint][0], pos[1] - J[joint][1]
    J = {k: (v[0] + dx, v[1] + dy) for k, v in J.items()}
    return a, J


def _err(c, J):
    if c["kind"] == "comx":
        cx = K.com(J)[0]
        return cx - (J[c["joint"]][0] + c.get("dx", 0.0))
    if c["kind"] == "y":
        return J[c["joint"]][1] - c["value"]
    if c["kind"] == "x":
        return J[c["joint"]][0] - c["value"]
    raise ValueError(c["kind"])


def solve_kf(kf, view):
    angles = dict(kf["angles"])
    for c in kf["solve"]:
        params = [c["param"]]
        if c["param"] in ("ua", "fa", "th", "sh", "ft"):
            params = [c["param"] + "_g", c["param"] + "_d"]

        def setv(b, v):
            p0 = c["param"]
            if p0 == "bras":
                for s in "gd":
                    d = b[f"fa_{s}"] - b[f"ua_{s}"]
                    b[f"ua_{s}"] = v
                    b[f"fa_{s}"] = v + d
            elif p0 == "jambes":
                for s in "gd":
                    b[f"th_{s}"] = v
                    b[f"sh_{s}"] = v
                    b[f"ft_{s}"] = v + 75
            elif p0 in ("jambe_g", "jambe_d"):
                s = p0[-1]
                d = b[f"sh_{s}"] - b[f"th_{s}"]
                b[f"th_{s}"] = v
                b[f"sh_{s}"] = v + d
            else:
                for p in params:
                    b[p] = v

        def ev(v):
            b = dict(angles)
            setv(b, v)
            _, J = place(kf, view, b)
            return abs(_err(c, J))
        best_v, best_e = None, 1e9
        lo, hi = c["lo"], c["hi"]
        steps = int((hi - lo) / 0.5) + 1
        for i in range(steps + 1):
            v = lo + (hi - lo) * i / steps
            e = ev(v)
            if e < best_e:
                best_v, best_e = v, e
        # affinage
        span = (hi - lo) / steps
        for _ in range(3):
            a_ = best_v - span
            for i in range(41):
                v = a_ + 2 * span * i / 40
                if lo <= v <= hi:
                    e = ev(v)
                    if e < best_e:
                        best_v, best_e = v, e
            span /= 20
        setv(angles, round(best_v, 2))
        for k in list(angles):
            if isinstance(angles[k], float):
                angles[k] = round(angles[k], 2)
    a, J = place(kf, view, angles)
    return a, J


def build(name):
    tpl = PT.build_template(name)
    view = tpl["view"]
    out_kfs = []
    for kf in tpl["keyframes"]:
        a, J = solve_kf(kf, view)
        clean = {k: round(v, 2) for k, v in a.items() if k in K.ANGLE_KEYS or k == "n"}
        if "n" not in clean:
            clean["n"] = clean["t"]
        if "p" not in clean:
            clean["p"] = clean["t"]
        out_kfs.append({"label": kf["label"], "angles": clean, "pelvis": J["bassin"],
                        "anchor": {"joint": kf["anchor"][0], "pos": list(kf["anchor"][1])},
                        "hold": kf["hold"], "dur": kf["dur"], "joints": J,
                        "shrug": bool(kf["angles"].get("_shrug"))})
    # Origine x sous le centre de masse de l'image clé 0
    cx = K.com(out_kfs[0]["joints"])[0]
    for kf in out_kfs:
        kf["joints"] = {k: [round(v[0] - cx, 4), round(v[1], 4)] for k, v in kf["joints"].items()}
        kf["pelvis"] = [round(kf["pelvis"][0] - cx, 4), round(kf["pelvis"][1], 4)]
        kf["anchor"]["pos"] = [round(kf["anchor"]["pos"][0] - cx, 4), round(kf["anchor"]["pos"][1], 4)]
    props = []
    for p in tpl["props"]:
        q = copy.deepcopy(p)
        if "x" in q and q.get("static", False):
            q["x"] = round(q["x"] - cx, 4)
        props.append(q)
    return {"template": name, "view": view, "loop": tpl["loop"], "keyframes": out_kfs, "props": props,
            "contacts": tpl["contacts"], "rom_exceptions": tpl["rom_exceptions"], "note": tpl["note"]}


def build_all():
    return {n: build(n) for n in PT.REGISTRY}


if __name__ == "__main__":
    import json
    import sys
    res = build_all()
    print(len(res), "gabarits")
    if len(sys.argv) > 1:
        print(json.dumps(res[sys.argv[1]], ensure_ascii=False, indent=1)[:3000])
