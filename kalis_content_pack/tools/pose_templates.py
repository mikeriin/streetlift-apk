"""Gabarits de mouvement (KT-046) : chaque gabarit décrit 2 à 4 images clés
par angles absolus (voir kinematics.py), un ancrage (articulation fixée sur
une surface ou un accessoire), des contraintes résolues automatiquement
(équilibre, contact d'un second appui), les accessoires et les contacts à
contrôler. Contenu généré par Claude (L9) — à relire.
"""
from kinematics import contact_offset

GROUND = 0.0
BAR_Y = 1.34      # barre fixe (prise)
PB_Y = 0.62       # barres parallèles (dessus des barres)
BENCH_Y = 0.26    # banc plat (dessus)
BOX_Y = 0.40


def P(t=0, n=None, **kw):
    """Pose : angles des deux côtés, surcharges par côté avec _g / _d."""
    a = {"t": t}
    if n is not None:
        a["n"] = n
    if "p" in kw:
        a["p"] = kw.pop("p")
    base = {"ua": 0, "fa": 0, "th": 0, "sh": 0, "ft": 70}
    for k in base:
        v = kw.get(k, base[k])
        a[f"{k}_g"] = kw.get(f"{k}_g", v)
        a[f"{k}_d"] = kw.get(f"{k}_d", v)
    return a


def on(joint, surface_y=GROUND, x=0.0):
    return (joint, (x, surface_y + contact_offset(joint)))


def KF(angles, anchor, solve=None, hold=0.0, dur=1.0, label=""):
    return {"angles": angles, "anchor": anchor, "solve": solve or [], "hold": hold,
            "dur": dur, "label": label}


def balance(param="t", lo=-60, hi=80, foot="d", dx=0.03):
    return {"param": param, "kind": "comx", "joint": f"cheville_{foot}", "dx": dx, "lo": lo, "hi": hi}


def touch(param, joint, y, lo, hi):
    return {"param": param, "kind": "y", "joint": joint, "value": y + contact_offset(joint), "lo": lo, "hi": hi}


def touch_x(param, joint, x, lo, hi):
    return {"param": param, "kind": "x", "joint": joint, "value": x, "lo": lo, "hi": hi}


def T(view, kfs, props=None, contacts=None, loop="aller-retour", rom_exceptions=None, note=""):
    return {"view": view, "keyframes": kfs, "props": props or [], "contacts": contacts or [],
            "loop": loop, "rom_exceptions": rom_exceptions or {}, "note": note}


FEET = [{"joint": "pied_g", "with": "sol"}, {"joint": "pied_d", "with": "sol"}]
STAND = P(t=0, ua=0, fa=0, th=0, sh=0, ft=70)
SA = on("pied_d", GROUND, 0.12)   # ancrage debout


def feet_c(kfs="all"):
    return [{"joint": "pied_g", "with": "sol", "kf": kfs}, {"joint": "pied_d", "with": "sol", "kf": kfs}]


def hands_c(prop, kfs="all"):
    return [{"joint": "poignet_g", "with": prop, "kf": kfs}, {"joint": "poignet_d", "with": prop, "kf": kfs}]


# --------------------------------------------------------------------------
# Membres inférieurs debout
# --------------------------------------------------------------------------

def squat(arms="avant", depth=95, prop=None, jump=False, box=False):
    arm = {"avant": dict(ua=85, fa=85), "gobelet": dict(ua=15, fa=160), "dos": dict(ua=-20, fa=135),
           "front": dict(ua=80, fa=175), "overhead": dict(ua=140, fa=140), "hanches": dict(ua=-15, fa=60),
           "bas": dict(ua=0, fa=0), "zercher": dict(ua=20, fa=150), "assiste": dict(ua=70, fa=80)}[arms]
    top = P(**arm)
    shank = -32 if depth >= 90 else -22
    bot = P(th=depth, sh=shank, **arm)
    props = []
    if prop:
        props.append(prop)
    kfs = [KF(top, SA, [balance(lo=-20, hi=40)], hold=0.3, dur=1.4, label="haut"),
           KF(bot, SA, [balance(lo=-10, hi=75)], hold=0.2 if not box else 0.6, dur=1.0, label="bas")]
    loop = "aller-retour"
    if jump:
        air = P(th=0, sh=0, ft=40, ua=-20, fa=-20)
        kfs.append(KF(air, ("pied_d", (0.12, 0.15)), [balance(lo=-20, hi=30, dx=0.0)], dur=0.5, label="envol"))
        loop = "cycle"
    if box:
        props.append({"type": "box", "x": -0.20, "y": 0.0, "w": 0.26, "h": 0.30, "static": True})
    c = feet_c([0, 1])
    return T("profil", kfs, props, c, loop)


def hinge(arms="barre", depth=80, knee=18, one_leg=False, prop=None, from_floor=False):
    top = P(ua=0, fa=0)
    th = 12 if not from_floor else 55
    sh = -knee if not from_floor else -30
    bot = P(th=th, sh=sh, ua=0, fa=0)
    kfs = [KF(top, SA, [balance(lo=-10, hi=20)], hold=0.3, dur=1.4, label="haut"),
           KF(bot, SA, [balance(lo=30, hi=100)], hold=0.2, dur=1.2, label="bas")]
    if one_leg:
        bot["th_g"] = -70
        bot["sh_g"] = -75
        bot["ft_g"] = 0
        kfs[1] = KF(bot, SA, [balance(lo=40, hi=110)], hold=0.3, dur=1.2, label="bas")
    props = [prop] if prop else []
    contacts = [{"joint": "pied_d", "with": "sol"}] + ([] if one_leg else [{"joint": "pied_g", "with": "sol"}])
    return T("profil", kfs, props, contacts)


def lunge(kind="avant", rear_on_bench=False, prop=None):
    top = P(th_d=25, sh_d=-5, th_g=-25, sh_g=-30, ft_g=15, ft_d=70)
    bot = P(th_d=90, sh_d=-15, ft_d=70, th_g=-25, sh_g=-95, ft_g=-20)
    if rear_on_bench:
        top = P(th_d=30, sh_d=-10, ft_d=70, th_g=-35, sh_g=-80, ft_g=-65)
        bot = P(th_d=90, sh_d=-20, ft_d=70, th_g=-15, sh_g=-100, ft_g=-85)
        props = [{"type": "banc", "x": -0.62, "y": BENCH_Y, "w": 0.35, "static": True}]
    else:
        props = []
    if prop:
        props.append(prop)
    kfs = [KF(top, SA, [balance(lo=-15, hi=30)], hold=0.2, dur=1.2, label="haut"),
           KF(bot, SA, [balance(lo=-15, hi=40)], hold=0.2, dur=1.0, label="bas")]
    contacts = [{"joint": "pied_d", "with": "sol"}]
    if not rear_on_bench:
        # le pied arrière reste au sol : on règle la pointe via la jambe arrière
        kfs[0]["solve"].append(touch("sh_g", "pied_g", GROUND, -120, 30))
        kfs[1]["solve"].append(touch("sh_g", "pied_g", GROUND, -130, 0))
        contacts.append({"joint": "pied_g", "with": "sol"})
    return T("profil", kfs, props, contacts)


def lateral_lunge():
    a = P(ua_g=20, fa_g=20, ua_d=-20, fa_d=-20)
    a.update({"th_g": 22, "sh_g": 22, "ft_g": 0, "th_d": -22, "sh_d": -22, "ft_d": 0})
    b = P(ua_g=10, fa_g=10, ua_d=-10, fa_d=-10)
    b.update({"th_g": 60, "sh_g": 20, "ft_g": 0, "th_d": -35, "sh_d": -35, "ft_d": 0, "t": 10})
    kfs = [KF(a, on("pied_d", GROUND, -0.25), [touch("th_g", "pied_g", GROUND, 0, 40)], dur=1.2, label="écart"),
           KF(b, on("pied_d", GROUND, -0.25), [touch("t", "pied_g", GROUND, -20, 30)], dur=1.2, hold=0.2, label="fente")]
    return T("face", kfs, [], feet_c(), note="vue de face : fente latérale")


def pistol(assisted=False, box=False, prop=None):
    top = P(th_g=30, sh_g=30, ft_g=90, ua=70, fa=75)
    bot = P(th_d=115, sh_d=-38, ft_d=70, th_g=85, sh_g=85, ft_g=150, ua=80, fa=85)
    props = []
    if box:
        props.append({"type": "box", "x": -0.26, "y": 0.0, "w": 0.26, "h": 0.33, "static": True})
        bot = P(th_d=95, sh_d=-30, ft_d=70, th_g=75, sh_g=75, ft_g=150, ua=80, fa=85)
    if prop:
        props.append(prop)
    kfs = [KF(top, SA, [balance(lo=-15, hi=30)], hold=0.2, dur=1.6, label="haut"),
           KF(bot, SA, [balance(lo=0, hi=80)], hold=0.3, dur=1.2, label="bas")]
    return T("profil", kfs, props, [{"joint": "pied_d", "with": "sol"}])


def shrimp():
    top = P(th_g=-10, sh_g=-95, ft_g=-80, ua=60, fa=60)
    bot = P(th_d=94, sh_d=-35, ft_d=70, th_g=-5, sh_g=-95, ft_g=-80, ua=80, fa=85)
    kfs = [KF(top, SA, [balance(lo=-10, hi=40)], dur=1.4, label="haut"),
           KF(bot, SA, [balance(lo=0, hi=70), touch("th_g", "genou_g", GROUND, -40, 60)], hold=0.2, dur=1.2, label="bas")]
    return T("profil", kfs, [], [{"joint": "pied_d", "with": "sol"}, {"joint": "genou_g", "with": "sol", "kf": [1]}])


def step_up(high=False, prop=None):
    h = 0.30 if high else 0.20
    a = P(th_d=80, sh_d=-5, ft_d=70, ua=0, fa=0)
    b = P(th_g=45, sh_g=-40, ft_g=70)
    props = [{"type": "box", "x": 0.02, "y": 0.0, "w": 0.34, "h": h, "static": True}]
    if prop:
        props.append(prop)
    kfs = [KF(a, on("pied_g", GROUND, -0.05), [touch("th_d", "pied_d", h, 20, 130)], dur=1.2, label="pied sur la box"),
           KF(b, on("pied_d", h, 0.22), [balance(lo=-10, hi=40)], hold=0.2, dur=1.2, label="debout sur la box")]
    return T("profil", kfs, props, [{"joint": "pied_g", "with": "sol", "kf": [0]}, {"joint": "pied_d", "with": "box", "kf": "all"}])


def calf_raise(prop=None, one_leg=False):
    a = P(ft=85)
    b = P(ft=25)
    if one_leg:
        a.update({"th_g": 20, "sh_g": -60, "ft_g": -40})
        b.update({"th_g": 20, "sh_g": -60, "ft_g": -40})
    props = [prop] if prop else []
    kfs = [KF(a, SA, [balance(lo=-15, hi=15, dx=0.06)], hold=0.3, dur=0.8, label="talons bas"),
           KF(b, SA, [balance(lo=-15, hi=15, dx=0.1)], hold=0.5, dur=0.8, label="talons hauts")]
    return T("profil", kfs, props, [{"joint": "pied_d", "with": "sol"}])


def jump(kind="vertical"):
    crouch = P(th=80, sh=-35, ua=-40, fa=-35)
    air = P(ft=30, ua=160 if kind == "vertical" else 120, fa=160 if kind == "vertical" else 120)
    if kind == "tuck":
        air = P(th=110, sh=-20, ft=60, ua=60, fa=80)
    if kind == "box":
        air = P(th=70, sh=-10, ua=90, fa=90)
    kfs = [KF(crouch, SA, [balance(lo=0, hi=80)], hold=0.2, dur=0.35, label="appel"),
           KF(air, ("pied_d", (0.12 if kind != "longueur" else 0.35, 0.22)), [balance(lo=-30, hi=40, dx=-0.02)], dur=0.35, label="envol"),
           KF(P(th=40, sh=-20), SA if kind != "box" else ("pied_d", (0.45, BOX_Y)), [balance(lo=-10, hi=50)], dur=0.7, hold=0.3, label="réception")]
    props = []
    if kind == "box":
        props.append({"type": "box", "x": 0.30, "y": 0.0, "w": 0.34, "h": BOX_Y, "static": True})
    return T("profil", kfs, props, [{"joint": "pied_d", "with": "sol", "kf": [0]}], loop="cycle")


def wall_sit():
    a = P(th=90, sh=0, ft=90, ua=0, fa=0)
    kfs = [KF(a, SA, [touch_x("t", "bassin", -0.10, -10, 10)], hold=2.0, dur=1.0, label="tenue"),
           KF(P(th=88, sh=0, ft=90, ua=0, fa=0), SA, [], hold=2.0, dur=1.0, label="tenue")]
    props = [{"type": "mur", "x": -0.16, "static": True}]
    return T("profil", kfs, props, feet_c())


# --------------------------------------------------------------------------
# Haut du corps debout
# --------------------------------------------------------------------------

def overhead_press(seated=False, prop=None, push=False):
    a = P(ua=30, fa=175)
    b = P(ua=175, fa=178)
    props = [prop] if prop else []
    if seated:
        for s in "gd":
            a.update({f"th_{s}": 90, f"sh_{s}": 0, f"ft_{s}": 70})
            b.update({f"th_{s}": 90, f"sh_{s}": 0, f"ft_{s}": 70})
        props.append({"type": "banc", "x": -0.18, "y": BENCH_Y, "w": 0.36, "static": True})
        kfs = [KF(a, on("bassin", BENCH_Y, -0.02), [], hold=0.2, dur=1.0, label="départ"),
               KF(b, on("bassin", BENCH_Y, -0.02), [], hold=0.3, dur=1.2, label="bras tendus")]
        return T("profil", kfs, props, [{"joint": "bassin", "with": "banc"}])
    kfs = [KF(a, SA, [balance(lo=-15, hi=15)], hold=0.2, dur=1.0, label="départ")]
    if push:
        kfs.append(KF(P(th=25, sh=-20, ua=30, fa=175), SA, [balance(lo=-10, hi=30)], dur=0.3, label="impulsion"))
    kfs.append(KF(b, SA, [balance(lo=-15, hi=15)], hold=0.3, dur=1.2, label="bras tendus"))
    return T("profil", kfs, props, feet_c(), loop="cycle" if push else "aller-retour")


def curl(kind="standard", prop=None, seated=False):
    a = P(ua=5, fa=8)
    b = P(ua=15, fa=160)
    props = [prop] if prop else []
    if kind == "pupitre":
        a = P(ua=40, fa=50)
        b = P(ua=40, fa=190)
    kfs = [KF(a, SA, [balance(lo=-10, hi=15)], hold=0.2, dur=1.0, label="bras tendus"),
           KF(b, SA, [balance(lo=-10, hi=15)], hold=0.3, dur=1.4, label="contraction")]
    return T("profil", kfs, props, feet_c())


def triceps_ext(kind="nuque", prop=None):
    if kind == "nuque":
        a = P(ua=170, fa=300)
        b = P(ua=170, fa=178)
    elif kind == "poulie":
        a = P(ua=-5, fa=140)
        b = P(ua=-5, fa=-3)
    else:  # kickback
        a = P(t=45, th=20, sh=-15, ua=-90, fa=0)
        b = P(t=45, th=20, sh=-15, ua=-90, fa=-88)
    props = [prop] if prop else []
    kfs = [KF(a, SA, [balance(lo=-10, hi=70)], hold=0.2, dur=1.0, label="flexion"),
           KF(b, SA, [balance(lo=-10, hi=70)], hold=0.3, dur=1.2, label="extension")]
    return T("profil", kfs, props, feet_c())


def lateral_raise(prop=None):
    a = P(ua_g=12, ua_d=-12, fa_g=14, fa_d=-14, ft=0)
    b = P(ua_g=88, ua_d=-88, fa_g=92, fa_d=-92, ft=0)
    props = [prop] if prop else []
    kfs = [KF(a, on("pied_d", GROUND, -0.085), [], hold=0.2, dur=1.0, label="bas"),
           KF(b, on("pied_d", GROUND, -0.085), [], hold=0.4, dur=1.4, label="haut")]
    return T("face", kfs, props, feet_c())


def front_raise(prop=None, kind="frontale"):
    a = P(ua=5, fa=5)
    b = P(ua=90, fa=90)
    if kind == "oiseau":
        a = P(t=70, th=15, sh=-15, ua=-5, fa=-5)
        b = P(t=70, th=15, sh=-15, ua=-80, fa=-80)
    props = [prop] if prop else []
    par = "th" if kind == "oiseau" else "t"
    lo, hi = (0, 45) if kind == "oiseau" else (-10, 90)
    kfs = [KF(a, SA, [balance(param=par, lo=lo, hi=hi)], hold=0.2, dur=1.0, label="bas"),
           KF(b, SA, [balance(param=par, lo=lo, hi=hi)], hold=0.3, dur=1.4, label="haut")]
    return T("profil", kfs, props, feet_c())


def row_bent(prop=None, torso=55, one_arm=False):
    a = P(t=torso, th=25, sh=-22, ua=0, fa=0)
    b = P(t=torso, th=25, sh=-22, ua=-65, fa=10)
    kfs = [KF(a, SA, [balance(param="th", lo=5, hi=45)], hold=0.2, dur=1.0, label="bras tendus"),
           KF(b, SA, [balance(param="th", lo=5, hi=45)], hold=0.4, dur=1.2, label="coudes en arrière")]
    props = [prop] if prop else []
    return T("profil", kfs, props, feet_c())


def upright(kind="shrug", prop=None):
    if kind == "shrug":
        a = P(ua=0, fa=0)
        b = P(ua=0, fa=0, n=8)
        b["_shrug"] = 1
        props = [prop] if prop else []
        kfs = [KF(a, SA, [balance(lo=-10, hi=10)], hold=0.2, dur=1.0, label="épaules basses"),
               KF(b, SA, [balance(lo=-10, hi=10)], hold=0.5, dur=1.0, label="épaules hautes")]
        return T("profil", kfs, props, feet_c())
    a = P(ua_g=8, fa_g=-8, ua_d=-8, fa_d=8, ft=0)
    b = P(ua_g=105, fa_g=225, ua_d=-105, fa_d=-225, ft=0)
    props = [prop] if prop else []
    kfs = [KF(a, on("pied_d", GROUND, -0.085), [], hold=0.2, dur=1.0, label="bras tendus"),
           KF(b, on("pied_d", GROUND, -0.085), [], hold=0.4, dur=1.2, label="coudes hauts")]
    return T("face", kfs, props, feet_c())


def cable_standing(kind="face_pull", pulley_y=1.3):
    if kind == "face_pull":
        a = P(ua=90, fa=90, t=-5)
        b = P(ua=110, fa=190, t=-5)
        pul = (0.85, 1.02)
    elif kind == "pull_apart":
        a = P(ua=85, fa=85)
        b = P(ua=-20, fa=-20)
        pul = None
    elif kind == "straight_arm":
        a = P(t=25, th=10, sh=-10, ua=160, fa=160)
        b = P(t=25, th=10, sh=-10, ua=10, fa=10)
        pul = (0.75, 1.65)
    elif kind == "rotation_ext":
        a = P(ua=0, fa=95)
        b = P(ua=0, fa=40)
        pul = None
    elif kind == "woodchop":
        a = P(t=-5, ua=150, fa=150)
        b = P(t=15, th=20, sh=-20, ua=40, fa=40)
        pul = (0.8, 1.7)
    elif kind == "pallof":
        a = P(ua=20, fa=150)
        b = P(ua=90, fa=90)
        pul = None
    elif kind == "crunch":
        a = P(t=10, th=0, sh=-90, ft=-75, ua=170, fa=310)
        b = P(t=75, th=0, sh=-90, ft=-75, ua=110, fa=250)
        pul = (0.35, 1.7)
    elif kind == "pullover":
        a = P(t=30, th=15, sh=-15, ua=150, fa=155)
        b = P(t=30, th=15, sh=-15, ua=40, fa=40)
        pul = (0.8, 1.6)
    else:
        raise ValueError(kind)
    props = []
    if pul:
        props.append({"type": "poulie", "x": pul[0], "y": pul[1], "static": True, "to": ["poignet_d"]})
    elif kind in ("pull_apart", "rotation_ext", "pallof"):
        props.append({"type": "elastique", "between": ["poignet_g", "poignet_d"]} if kind == "pull_apart"
                     else {"type": "elastique", "x": 0.75, "y": 1.0, "static": True, "to": ["poignet_d"]})
    if kind == "crunch":
        kfs = [KF(a, on("genou_d", GROUND, 0.10), [], hold=0.2, dur=1.0, label="haut"),
               KF(b, on("genou_d", GROUND, 0.10), [], hold=0.3, dur=1.2, label="enroulé")]
        return T("profil", kfs, props, [{"joint": "genou_d", "with": "sol"}])
    kfs = [KF(a, SA, [balance(lo=-15, hi=40)], hold=0.2, dur=1.0, label="départ"),
           KF(b, SA, [balance(lo=-15, hi=40)], hold=0.4, dur=1.2, label="fin")]
    return T("profil", kfs, props, feet_c())


# --------------------------------------------------------------------------
# Assis / machines
# --------------------------------------------------------------------------

def seated(kind="pulldown"):
    base = dict(th=90, sh=0, ft=90)
    props = [{"type": "banc", "x": -0.18, "y": BENCH_Y, "w": 0.36, "static": True}]
    if kind == "pulldown":
        a = P(t=-8, ua=170, fa=172, **base)
        b = P(t=-12, ua=20, fa=165, **base)
        props.append({"type": "poulie", "x": 0.12, "y": 1.55, "static": True, "to": ["poignet_d"]})
    elif kind == "row":
        a = P(t=15, ua=80, fa=80, th=80, sh=80, ft=170)
        b = P(t=-5, ua=-45, fa=80, th=80, sh=80, ft=170)
        props = [{"type": "poulie", "x": 0.85, "y": 0.2, "static": True, "to": ["poignet_d"]},
                 {"type": "banc", "x": -0.3, "y": 0.22, "w": 0.5, "static": True}]
        kfs = [KF(a, on("bassin", 0.22, 0.0), [], hold=0.2, dur=1.0, label="bras tendus"),
               KF(b, on("bassin", 0.22, 0.0), [], hold=0.4, dur=1.2, label="coudes en arrière")]
        return T("profil", kfs, props, [{"joint": "bassin", "with": "banc"}])
    elif kind == "leg_extension":
        a = P(t=-5, ua=10, fa=60, th=90, sh=0, ft=90)
        b = P(t=-5, ua=10, fa=60, th=90, sh=85, ft=175)
        props.append({"type": "machine", "x": 0.25, "y": 0.2, "static": True})
    elif kind == "leg_curl":
        a = P(t=-5, ua=10, fa=60, th=90, sh=80, ft=170)
        b = P(t=-5, ua=10, fa=60, th=90, sh=-10, ft=80)
        props.append({"type": "machine", "x": 0.25, "y": 0.2, "static": True})
    elif kind == "press":
        a = P(t=-35, ua=20, fa=80, th=145, sh=40, ft=130)
        b = P(t=-35, ua=20, fa=80, th=125, sh=120, ft=210)
        props = [{"type": "machine", "x": 0.5, "y": 0.6, "static": True},
                 {"type": "banc", "x": -0.3, "y": BENCH_Y, "w": 0.4, "static": True}]
    elif kind == "calf_seated":
        a = P(th=90, sh=0, ft=110, ua=40, fa=40)
        b = P(th=90, sh=0, ft=40, ua=40, fa=40)
        props.append({"type": "machine", "x": 0.25, "y": 0.2, "static": True})
    elif kind == "adductor":
        return None
    elif kind == "pec_deck":
        a = P(t=0, ua=40, fa=120, **base)
        b = P(t=0, ua=90, fa=170, **base)
        props.append({"type": "machine", "x": 0.25, "y": 0.2, "static": True})
    else:
        raise ValueError(kind)
    kfs = [KF(a, on("bassin", BENCH_Y, -0.02), [], hold=0.2, dur=1.0, label="départ"),
           KF(b, on("bassin", BENCH_Y, -0.02), [], hold=0.3, dur=1.2, label="fin")]
    return T("profil", kfs, props, [{"joint": "bassin", "with": "banc"}])


def seated_face(kind="abduction"):
    a = P(th_g=0, th_d=0, sh=0, ft=0, ua_g=20, ua_d=-20, fa_g=20, fa_d=-20)
    b = P(th_g=30, th_d=-30, sh_g=30, sh_d=-30, ft=0, ua_g=20, ua_d=-20, fa_g=20, fa_d=-20)
    if kind == "adduction":
        a, b = b, a
    kfs = [KF(a, on("bassin", 0.45, 0.0), [], hold=0.2, dur=1.0, label="départ"),
           KF(b, on("bassin", 0.45, 0.0), [], hold=0.3, dur=1.0, label="fin")]
    return T("face", kfs, [{"type": "machine", "x": 0.0, "y": 0.1, "static": True}], [],
             note="vue de face, assise schématisée (cuisses vues en raccourci)")


# --------------------------------------------------------------------------
# Allongé / sol
# --------------------------------------------------------------------------

def pushup(kind="standard", prop=None):
    """Pompe : mains au sol (ancrage poignet), pieds au sol (résolution du tronc)."""
    hy, fy = GROUND, GROUND
    props = [prop] if prop else []
    if kind == "inclinee":
        hy = BENCH_Y
        props.append({"type": "banc", "x": 0.05, "y": hy, "w": 0.3, "static": True})
    if kind == "declinee":
        fy = BENCH_Y
        props.append({"type": "banc", "x": -1.15, "y": fy, "w": 0.3, "static": True})
    if kind == "mur":
        a = P(t=25, ua=100, fa=100, ft=60)
        b = P(t=30, ua=40, fa=150, ft=60)
        props = [{"type": "mur", "x": 0.55, "static": True}]
        kfs = [KF(a, SA, [touch_x("t", "poignet_d", 0.55 - 0.012, 0, 89)], hold=0.2, dur=1.0, label="bras tendus"),
               KF(b, SA, [touch_x("t", "poignet_d", 0.55 - 0.012, 0, 89)], hold=0.2, dur=1.2, label="poitrine proche du mur")]
        for kf in kfs:
            kf["link"] = "debout_incline"
        return T("profil", kfs, props, feet_c() + [{"joint": "poignet_d", "with": "mur"}])
    knees = kind == "genoux"
    up = P(t=80, ua=-5, fa=-5, th=-100, sh=-100, ft=-10)
    down = P(t=85, ua=-80, fa=5, th=-95, sh=-95, ft=-10)
    if knees:
        up.update({"sh": -175, "sh_g": -175, "sh_d": -175, "ft_g": -170, "ft_d": -170})
        down.update({"sh_g": -175, "sh_d": -175, "ft_g": -170, "ft_d": -170})
        foot_joint = "genou_d"
    else:
        foot_joint = "pied_d"
    if kind == "pike":
        up = P(t=135, ua=45, fa=45, th=-45, sh=-45, ft=30)
        down = P(t=150, ua=-100, fa=-10, th=-45, sh=-45, ft=30)
    if kind == "diamant":
        down = P(t=85, ua=-95, fa=10, th=-95, sh=-95, ft=-10)
    if kind == "pseudo":
        up = P(t=75, ua=-30, fa=-30, th=-100, sh=-100, ft=-10)
        down = P(t=85, ua=-110, fa=-5, th=-95, sh=-95, ft=-10)
    # le paramètre résolu est l'inclinaison du tronc (corps gainé, hanche = prolongement)
    def body_follow(p):
        return p
    kfs = []
    for pose, lab, hold in ((up, "bras tendus", 0.2), (down, "poitrine basse", 0.3)):
        lo, hi = (30, 130) if kind != "pike" else (100, 175)
        solve = [touch("t", foot_joint, fy, lo, hi)] if kind != "pike" else [touch("jambes", foot_joint, fy, -120, 0)]
        kfs.append(KF(pose, on("poignet_d", hy, 0.35), solve, hold=hold, dur=1.2, label=lab))
    link_body(kfs, kind)
    contacts = hands_c("sol" if hy == GROUND else "banc") + [{"joint": foot_joint, "with": "sol" if fy == GROUND else "banc"}]
    return T("profil", kfs, props, contacts)


def link_body(kfs, kind):
    """Corps gainé : cuisse et jambe suivent le tronc (hanche en extension 0)."""
    for kf in kfs:
        kf["link"] = {"pike": "pike", "genoux": "gaine_genoux"}.get(kind, "gaine")


def plank(kind="coudes", prop=None):
    if kind == "coudes":
        a = P(t=85, ua=-5, fa=85, th=-95, sh=-95, ft=-10)
        hand = "coude_d"
    elif kind == "bras_tendus":
        a = P(t=80, ua=-5, fa=-5, th=-100, sh=-100, ft=-10)
        hand = "poignet_d"
    elif kind == "genoux":
        a = P(t=75, ua=-5, fa=85, th=-105, sh=-175, ft=-170)
        hand = "coude_d"
    elif kind == "lean":
        a = P(t=78, ua=-35, fa=-35, th=-102, sh=-102, ft=-5)
        hand = "poignet_d"
    elif kind == "pseudo_hold":
        a = P(t=75, ua=-40, fa=-40, th=-105, sh=-105, ft=-5)
        hand = "poignet_d"
    else:
        raise ValueError(kind)
    foot = "genou_d" if kind == "genoux" else "pied_d"
    b = dict(a)
    kfs = [KF(a, on(hand, GROUND, 0.3), [touch("t", foot, GROUND, 40, 120)], hold=2.0, dur=0.8, label="tenue"),
           KF(b, on(hand, GROUND, 0.3), [touch("t", foot, GROUND, 40, 120)], hold=2.0, dur=0.8, label="tenue")]
    link_body(kfs, "genoux" if kind == "genoux" else "plank")
    props = [prop] if prop else []
    return T("profil", kfs, props, [{"joint": hand, "with": "sol"}, {"joint": foot, "with": "sol"}])


def side_plank(kind="standard"):
    # vue de face, allongé sur le côté droit : tête vers -x, pieds vers +x
    a = P(t=-72, ua_d=0, fa_d=-90, ua_g=72, fa_g=72)
    b = dict(a)
    b.update({"ua_g": 180, "fa_g": 180})
    kfs = [KF(a, on("coude_d", GROUND, 0.0), [touch("t", "pied_d", GROUND, -85, -50)], hold=2.0, dur=1.0, label="tenue"),
           KF(b, on("coude_d", GROUND, 0.0), [touch("t", "pied_d", GROUND, -85, -50)], hold=2.0, dur=1.0, label="bras levé")]
    for kf in kfs:
        kf["link"] = "gaine_face"
    return T("face", kfs, [], [{"joint": "coude_d", "with": "sol"}, {"joint": "pied_d", "with": "sol"}],
             note="planche latérale vue de face (appui avant-bras droit)")


def supine(kind="hollow"):
    """Allongé sur le dos : t = -90, tête vers -x, pieds vers +x.
    Jambes au sol : th = sh = 90 ; bras le long du corps : ua = 90 ;
    bras au-dessus de la tête : ua = -90 (ou 270)."""
    c = [{"joint": "bassin", "with": "sol"}]
    anchor = on("bassin", GROUND, 0.0)
    if kind == "hollow":
        a = P(t=-72, n=-60, ua=-115, fa=-115, th=110, sh=110, ft=125)
        b = P(t=-75, n=-62, ua=-120, fa=-120, th=108, sh=108, ft=123)
    elif kind == "hollow_tuck":
        a = P(t=-72, n=-60, ua=110, fa=110, th=200, sh=100, ft=115)
        b = P(t=-74, n=-62, ua=105, fa=105, th=195, sh=100, ft=115)
    elif kind == "dead_bug":
        a = P(t=-90, n=-80, ua=180, fa=180, th=180, sh=90, ft=180)
        b = P(t=-90, n=-80, ua_g=180, fa_g=180, ua_d=-95, fa_d=-95, th_g=180, sh_g=90, ft_g=180, th_d=95, sh_d=95, ft_d=175)
        c = c + [{"joint": "cou", "with": "sol"}]
    elif kind == "crunch":
        a = P(t=-90, n=-80, ua=-150, fa=-40, th=135, sh=35, ft=70)
        b = P(t=-55, n=-45, ua=-150, fa=-40, th=135, sh=35, ft=70)
        c = c + [{"joint": "pied_d", "with": "sol"}]
        kfs = [KF(a, anchor, [touch("th", "pied_d", GROUND, 100, 170)], hold=0.2, dur=1.0, label="allongé"),
               KF(b, anchor, [touch("th", "pied_d", GROUND, 100, 170)], hold=0.4, dur=1.0, label="enroulé")]
        return T("profil", kfs, [], c)
    elif kind == "situp":
        a = P(t=-90, n=-80, ua=-90, fa=-90, th=135, sh=35, ft=70)
        b = P(t=-5, n=0, ua=60, fa=60, th=135, sh=35, ft=70)
        c = c + [{"joint": "pied_d", "with": "sol"}]
        kfs = [KF(a, anchor, [touch("th", "pied_d", GROUND, 100, 170)], hold=0.2, dur=1.2, label="allongé"),
               KF(b, anchor, [touch("th", "pied_d", GROUND, 100, 170)], hold=0.3, dur=1.2, label="assis")]
        return T("profil", kfs, [], c)
    elif kind == "leg_raise":
        a = P(t=-90, n=-80, ua=90, fa=90, th=95, sh=95, ft=110)
        b = P(t=-90, n=-80, ua=90, fa=90, th=180, sh=180, ft=195)
        c = c + [{"joint": "cou", "with": "sol"}]
    elif kind == "vup":
        a = P(t=-85, n=-75, ua=-95, fa=-95, th=100, sh=100, ft=115)
        b = P(t=-35, n=-30, ua=150, fa=150, th=150, sh=150, ft=165)
    elif kind == "flutter":
        a = P(t=-80, n=-70, ua=90, fa=90, th_g=100, sh_g=100, ft_g=115, th_d=115, sh_d=115, ft_d=130)
        b = P(t=-80, n=-70, ua=90, fa=90, th_g=115, sh_g=115, ft_g=130, th_d=100, sh_d=100, ft_d=115)
    elif kind == "twist":
        a = P(t=-40, n=-35, ua=35, fa=100, th=150, sh=80, ft=95)
        b = P(t=-40, n=-35, ua=55, fa=120, th=150, sh=80, ft=95)
    elif kind == "bridge":
        # pont dorsal : mains et pieds au sol, bassin haut (rachis rigide = schéma)
        a = P(t=-90, n=-80, ua=-90, fa=-90, th=135, sh=35, ft=70)
        b = P(t=-125, n=-150, ua=-65, fa=-65, th=70, sh=5, ft=70)
        kfs = [KF(a, anchor, [touch("th", "pied_d", GROUND, 100, 170)], hold=0.3, dur=1.5, label="allongé"),
               KF(b, on("poignet_d", GROUND, -0.35), [touch("th", "pied_d", GROUND, 10, 140)], hold=1.5, dur=1.5, label="pont")]
        return T("profil", kfs, [], [{"joint": "pied_d", "with": "sol"}],
                 rom_exceptions={"epaule": [-95, 200], "cou": [-80, 60], "hanche": [-70, 150]},
                 note="rachis schématisé par un segment rigide : la cambrure réelle n'est pas représentée")
    elif kind == "dragon_flag":
        a = P(t=-150, n=-110, ua=-90, fa=-90)
        b = P(t=-100, n=-85, ua=-90, fa=-90)
        kfs = [KF(a, on("cou", GROUND, 0.0), [], hold=0.4, dur=2.0, label="corps vertical"),
               KF(b, on("cou", GROUND, 0.0), [], hold=0.4, dur=1.5, label="corps presque horizontal")]
        for kf in kfs:
            kf["link"] = "gaine_dos"
        props = [{"type": "poteau_bas", "x": -0.40, "static": True}]
        return T("profil", kfs, props, [{"joint": "cou", "with": "sol"}], rom_exceptions={"epaule": [-200, 200]},
                 note="les mains agrippent un appui fixe derrière la tête")
    else:
        raise ValueError(kind)
    kfs = [KF(a, anchor, [], hold=0.3, dur=1.2, label="départ"), KF(b, anchor, [], hold=0.4, dur=1.2, label="fin")]
    return T("profil", kfs, [], c)


def prone(kind="superman"):
    """Allongé sur le ventre : t = 90, tête vers +x ; jambes th = sh = -90,
    dessus du pied au sol ft = -75."""
    anc = on("bassin", GROUND, 0.0)
    c = [{"joint": "bassin", "with": "sol"}]
    if kind == "superman":
        a = P(t=90, n=90, ua=-90, fa=-90, th=-90, sh=-90, ft=-75)
        b = P(t=80, n=75, ua=-80, fa=-80, th=-100, sh=-100, ft=-85)
        kfs = [KF(a, anc, [], hold=0.3, dur=1.0, label="allongé"), KF(b, anc, [], hold=1.0, dur=1.0, label="bras et jambes levés")]
        return T("profil", kfs, [], c, rom_exceptions={"epaule": [-95, 200]})
    if kind == "ytw":
        a = P(t=55, n=60, ua=0, fa=0, th=-30, sh=-30, ft=40)
        b = P(t=55, n=60, ua=-100, fa=-100, th=-30, sh=-30, ft=40)
        props = [{"type": "banc_incline", "x": 0.0, "y": 0.0, "static": True}]
        anc = on("pied_d", GROUND, -0.55)
        kfs = [KF(a, anc, [], hold=0.3, dur=1.0, label="bras pendants"), KF(b, anc, [], hold=1.0, dur=1.2, label="bras en Y")]
        return T("profil", kfs, props, [{"joint": "pied_d", "with": "sol"}], rom_exceptions={"epaule": [-95, 200]},
                 note="buste en appui sur un banc incliné")
    if kind == "bird_dog":
        a = P(t=90, ua=0, fa=0, th=0, sh=-90, ft=-75)
        b = P(t=90, ua_g=0, fa_g=0, ua_d=-90, fa_d=-90, th_g=0, sh_g=-90, ft_g=-75, th_d=-90, sh_d=-90, ft_d=-75)
        anc = on("genou_g", GROUND, -0.1)
        c = [{"joint": "genou_g", "with": "sol"}, {"joint": "poignet_g", "with": "sol"}]
        kfs = [KF(a, anc, [touch("t", "poignet_g", GROUND, 60, 120)], hold=0.3, dur=1.2, label="quadrupédie"),
               KF(b, anc, [touch("t", "poignet_g", GROUND, 60, 120)], hold=1.0, dur=1.2, label="bras et jambe opposés tendus")]
        return T("profil", kfs, [], c, rom_exceptions={"epaule": [-95, 200]})
    if kind == "cat_cow":
        a = P(t=90, n=115, ua=0, fa=0, th=0, sh=-90, ft=-75)
        b = P(t=90, n=45, ua=0, fa=0, th=0, sh=-90, ft=-75)
        anc = on("genou_d", GROUND, -0.1)
        c = [{"joint": "genou_d", "with": "sol"}, {"joint": "poignet_d", "with": "sol"}]
        kfs = [KF(a, anc, [touch("t", "poignet_d", GROUND, 60, 120)], hold=1.0, dur=1.5, label="extension"),
               KF(b, anc, [touch("t", "poignet_d", GROUND, 60, 120)], hold=1.0, dur=1.5, label="enroulement")]
        return T("profil", kfs, [], c, note="rachis schématisé par un segment rigide : le geste se lit à la tête et au bassin")
    raise ValueError(kind)


def quadruped(kind="bear_crawl"):
    if kind == "mountain":
        a = P(t=75, ua=-5, fa=-5, th_d=70, sh_d=-70, ft_d=-40)
        b = P(t=75, ua=-5, fa=-5, th_g=70, sh_g=-70, ft_g=-40)
        kfs = [KF(a, on("poignet_d", GROUND, 0.3), [touch("t", "pied_g", GROUND, 50, 110)], dur=0.35, label="genou droit"),
               KF(b, on("poignet_d", GROUND, 0.3), [touch("t", "pied_d", GROUND, 50, 110)], dur=0.35, label="genou gauche")]
        kfs[0]["link"] = "gaine_g"
        kfs[1]["link"] = "gaine_d"
        return T("profil", kfs, [], [{"joint": "poignet_d", "with": "sol"}], loop="cycle")
    if kind == "crab":
        a = P(t=-40, n=-30, ua=-25, fa=-25, th=95, sh=5, ft=70)
        b = P(t=-45, n=-35, ua=-30, fa=-30, th=95, sh=5, ft=70)
        kfs = [KF(a, on("poignet_d", GROUND, -0.3), [touch("th", "pied_d", GROUND, 40, 140)], dur=0.6, label="pas 1"),
               KF(b, on("poignet_d", GROUND, -0.3), [touch("th", "pied_d", GROUND, 40, 140)], dur=0.6, label="pas 2")]
        return T("profil", kfs, [], [{"joint": "poignet_d", "with": "sol"}], loop="aller-retour")
    a = P(t=85, ua_g=5, fa_g=5, ua_d=-15, fa_d=-15, th_g=10, sh_g=-80, th_d=-10, sh_d=-95, ft=-5)
    b = P(t=85, ua_g=-15, fa_g=-15, ua_d=5, fa_d=5, th_g=-10, sh_g=-95, th_d=10, sh_d=-80, ft=-5)
    kfs = [KF(a, on("poignet_g", GROUND, 0.3), [touch("t", "pied_g", GROUND, 40, 130)], dur=0.6, label="pas 1"),
           KF(b, on("poignet_d", GROUND, 0.3), [touch("t", "pied_d", GROUND, 40, 130)], dur=0.6, label="pas 2")]
    return T("profil", kfs, [], [], loop="aller-retour")


def bench_lying(kind="couche", prop=None, incline=0):
    """Allongé sur le banc, tête vers -x (t = -90 + inclinaison)."""
    t = -90 + incline
    legs = dict(th=100, sh=10, ft=70)
    a = P(t=t, n=t + 10, ua=180, fa=180, **legs)
    b = P(t=t, n=t + 10, ua=100, fa=190, **legs)
    if kind == "ecarte":
        a = P(t=t, n=t + 10, ua=180, fa=180, **legs)
        b = P(t=t, n=t + 10, ua=95, fa=105, **legs)
    if kind == "barre_front":
        a = P(t=t, n=t + 10, ua=190, fa=190, **legs)
        b = P(t=t, n=t + 10, ua=190, fa=320, **legs)
    props = [{"type": "banc", "x": -0.32, "y": BENCH_Y, "w": 0.62, "static": True}]
    anc = on("bassin", BENCH_Y, 0.0)
    c = [{"joint": "bassin", "with": "banc"}, {"joint": "pied_d", "with": "sol"}]
    solve = [touch("th", "pied_d", GROUND, 60, 175)]
    if kind == "floor":
        props = []
        a = P(t=-90, n=-80, ua=180, fa=180, th=135, sh=35, ft=70)
        b = P(t=-90, n=-80, ua=90, fa=180, th=135, sh=35, ft=70)
        anc = on("bassin", GROUND, 0.0)
        c = [{"joint": "bassin", "with": "sol"}, {"joint": "pied_d", "with": "sol"}]
        solve = [touch("th", "pied_d", GROUND, 100, 170)]
    if prop:
        props.append(prop)
    kfs = [KF(a, anc, list(solve), hold=0.2, dur=1.0, label="bras tendus"),
           KF(b, anc, list(solve), hold=1.0 if kind == "pause" else 0.3, dur=1.4, label="charge basse")]
    return T("profil", kfs, props, c, rom_exceptions={"epaule": [-120, 200]})


def glute_bridge(one_leg=False):
    a = P(t=-90, n=-80, ua=90, fa=90, th=135, sh=35, ft=70)
    b = P(t=-115, n=-95, ua=90, fa=90, th=90, sh=10, ft=70)
    if one_leg:
        a.update({"th_g": 180, "sh_g": 180, "ft_g": 195})
        b.update({"th_g": 155, "sh_g": 155, "ft_g": 170})
    p = "th_d" if one_leg else "th"
    kfs = [KF(a, on("bassin", GROUND, 0.0), [touch(p, "pied_d", GROUND, 100, 170)], hold=0.2, dur=1.0, label="bassin au sol"),
           KF(b, on("epaule_d", GROUND, -0.25), [touch(p, "pied_d", GROUND, 40, 160)], hold=1.0, dur=1.0, label="bassin haut")]
    return T("profil", kfs, [], [{"joint": "pied_d", "with": "sol"}, {"joint": "epaule_d", "with": "sol", "kf": [1]}])


def kneeling(kind="ab_wheel"):
    if kind == "ab_wheel":
        a = P(t=45, n=55, ua=-45, fa=-45, th=0, sh=-90, ft=-75)
        b = P(t=80, n=85, ua=-150, fa=-150, th=-80, sh=-90, ft=-75)
        kfs = [KF(a, on("genou_d", GROUND, 0.0), [touch("bras", "poignet_d", 0.09, -80, 20)], dur=1.2, label="départ"),
               KF(b, on("genou_d", GROUND, 0.0), [touch("bras", "poignet_d", 0.09, -175, -110)], hold=0.3, dur=1.6, label="allongé")]
        kfs[1]["link"] = "hanche_suit"
        props = [{"type": "roue", "attach": "poignet_d"}]
        return T("profil", kfs, props, [{"joint": "genou_d", "with": "sol"}], rom_exceptions={"epaule": [-95, 205]})
    if kind == "nordic":
        a = P(t=0, n=0, ua=20, fa=100, th=0, sh=-90, ft=-75)
        b = P(t=65, n=65, ua=60, fa=90, th=-65, sh=-90, ft=-75)
        kfs = [KF(a, on("genou_d", GROUND, 0.0), [], dur=0.8, label="à genoux"),
               KF(b, on("genou_d", GROUND, 0.0), [], hold=0.2, dur=3.0, label="descente freinée")]
        for kf in kfs:
            kf["link"] = "hanche_suit"
        return T("profil", kfs, [{"type": "cale", "x": -0.35, "y": 0.06, "static": True}], [{"joint": "genou_d", "with": "sol"}])
    if kind == "hip_flexor":
        a = P(th_d=80, sh_d=-5, ft_d=70, th_g=-20, sh_g=-100, ft_g=-85, ua=-5, fa=-5)
        b = P(t=-5, th_d=95, sh_d=-25, ft_d=70, th_g=-35, sh_g=-100, ft_g=-85, ua=170, fa=170)
        kfs = [KF(a, on("genou_g", GROUND, -0.1), [touch("sh_d", "pied_d", GROUND, -40, 30)], hold=1.0, dur=1.5, label="départ"),
               KF(b, on("genou_g", GROUND, -0.1), [touch("sh_d", "pied_d", GROUND, -60, 30)], hold=2.0, dur=1.5, label="étirement")]
        return T("profil", kfs, [], [{"joint": "genou_g", "with": "sol"}, {"joint": "pied_d", "with": "sol"}])
    if kind == "90_90":
        a = P(t=0, ua=10, fa=40, th_d=90, sh_d=-10, ft_d=60, th_g=-40, sh_g=-120, ft_g=-100)
        b = P(t=35, ua=40, fa=40, th_d=90, sh_d=-10, ft_d=60, th_g=-40, sh_g=-120, ft_g=-100)
        kfs = [KF(a, on("bassin", GROUND, 0.0), [], hold=1.5, dur=1.5, label="assis 90/90"),
               KF(b, on("bassin", GROUND, 0.0), [], hold=2.0, dur=1.5, label="bascule avant")]
        return T("profil", kfs, [], [{"joint": "bassin", "with": "sol"}], note="posture 90/90 schématisée en profil")
    raise ValueError(kind)


def seated_floor(kind="lsit_sol"):
    if kind == "lsit_sol":
        a = P(t=0, ua=0, fa=0, th=90, sh=90, ft=160)
        kfs = [KF(a, on("poignet_d", GROUND, 0.0), [], hold=2.0, dur=0.8, label="tenue"),
               KF(dict(a), on("poignet_d", GROUND, 0.0), [], hold=2.0, dur=0.8, label="tenue")]
        return T("profil", kfs, hands_c("sol"))
    if kind == "forward_fold":
        a = P(t=10, ua=40, fa=40, th=90, sh=90, ft=170)
        b = P(t=58, ua=80, fa=80, th=90, sh=90, ft=170)
        kfs = [KF(a, on("bassin", GROUND, 0.0), [], hold=1.0, dur=2.0, label="assis"),
               KF(b, on("bassin", GROUND, 0.0), [], hold=3.0, dur=2.0, label="flexion avant")]
        return T("profil", kfs, [], [{"joint": "bassin", "with": "sol"}])
    raise ValueError(kind)


# --------------------------------------------------------------------------
# Barre fixe / anneaux / barres parallèles
# --------------------------------------------------------------------------

def hang_prop(kind):
    if kind == "anneaux":
        return {"type": "anneaux", "x": 0.0, "y": BAR_Y, "static": True}
    return {"type": "barre_fixe", "x": 0.0, "y": BAR_Y, "static": True}


def pullup(kind="standard", support="barre_fixe", prop=None):
    bar = ("poignet_d", (0.0, BAR_Y))
    hang = P(t=-3, ua=180, fa=180, th=5, sh=-5, ft=40)
    top = P(t=-10, ua=10, fa=166, th=10, sh=-20, ft=40)
    if kind == "poitrine":
        top = P(t=-25, ua=-40, fa=115, th=15, sh=-20, ft=40)
    if kind == "l_sit":
        hang = P(t=-3, ua=180, fa=180, th=90, sh=90, ft=160)
        top = P(t=-10, ua=10, fa=166, th=90, sh=90, ft=160)
    props = [hang_prop(support)]
    if prop:
        props.append(prop)
    kfs = [KF(hang, bar, [], hold=0.3, dur=1.0, label="suspendu bras tendus"),
           KF(top, bar, [], hold=0.3, dur=1.6, label="menton au-dessus")]
    return T("profil", kfs, props, hands_c(support))


def hang(kind="passif", support="barre_fixe", prop=None):
    bar = ("poignet_d", (0.0, BAR_Y))
    if kind == "passif":
        a = P(t=0, ua=180, fa=180, ft=40)
        b = P(t=0, ua=180, fa=180, ft=40)
    elif kind == "scap":
        a = P(t=0, ua=180, fa=180, ft=40)
        b = P(t=-8, ua=172, fa=176, ft=40)
    elif kind == "iso90":
        a = P(t=-5, ua=60, fa=170, th=10, sh=-20, ft=40)
        b = dict(a)
    elif kind == "iso_haut":
        a = P(t=-10, ua=10, fa=166, th=10, sh=-20, ft=40)
        b = dict(a)
    elif kind == "knee_raise":
        a = P(t=0, ua=180, fa=180, ft=40)
        b = P(t=-10, ua=172, fa=172, th=100, sh=-10, ft=40)
    elif kind == "leg_raise":
        a = P(t=0, ua=180, fa=180, ft=40)
        b = P(t=-15, ua=168, fa=168, th=100, sh=100, ft=160)
    elif kind == "toes_to_bar":
        a = P(t=0, ua=180, fa=180, ft=40)
        b = P(t=-45, ua=135, fa=135, th=125, sh=125, ft=170)
    elif kind == "german":
        a = P(t=0, ua=180, fa=180, th=0, sh=0, ft=40)
        b = P(t=-5, n=0, ua=-5, fa=-5, th=-10, sh=-10, ft=40)
        # épaules en extension extrême (figure avancée)
    elif kind == "skin_cat":
        a = P(t=0, ua=180, fa=180, th=0, sh=0, ft=40)
        b = P(t=-165, n=-170, ua=15, fa=15, th=-30, sh=-30, ft=-15)
    elif kind == "l_sit_barre":
        a = P(t=0, ua=180, fa=180, th=90, sh=90, ft=160)
        b = dict(a)
    elif kind == "windshield":
        a = P(t=-60, ua=170, fa=170, th=-160, sh=-160, ft=-145)
        b = P(t=-55, ua=172, fa=172, th=-165, sh=-165, ft=-150)
    else:
        raise ValueError(kind)
    props = [hang_prop(support)]
    if prop:
        props.append(prop)
    hold = 2.0 if kind in ("passif", "iso90", "iso_haut", "l_sit_barre") else 0.3
    kfs = [KF(a, bar, [], hold=hold, dur=1.0, label="départ"), KF(b, bar, [], hold=hold, dur=1.2, label="fin")]
    rex = {"epaule": [-200, 200], "hanche": [-40, 170]} if kind in ("german", "skin_cat") else {}
    return T("profil", kfs, props, hands_c(support), rom_exceptions=rex)


def lever(kind="front_tuck", support="barre_fixe", dynamic=False):
    """Front lever : dos vers le sol, t = -90 (tête vers -x), bras vers la barre ua = 180.
    Back lever : ventre vers le sol, t = 90, bras en arrière vers la barre ua = 180."""
    bar = ("poignet_d", (0.0, BAR_Y))
    front = {
        "front_tuck": P(t=-90, n=-80, ua=180, fa=180, th=-140, sh=90, ft=105),
        "front_adv": P(t=-90, n=-80, ua=180, fa=180, th=180, sh=90, ft=105),
        "front_one": P(t=-90, n=-80, ua=180, fa=180, th_g=90, sh_g=90, ft_g=105, th_d=180, sh_d=90, ft_d=105),
        "front_straddle": P(t=-90, n=-80, ua=180, fa=180, th=90, sh=90, ft=105),
        "front_full": P(t=-90, n=-80, ua=180, fa=180, th=90, sh=90, ft=105),
        "back_tuck": P(t=90, n=80, ua=180, fa=180, th=40, sh=-100, ft=-85),
        "back_adv": P(t=90, n=80, ua=180, fa=180, th=0, sh=-100, ft=-85),
        "back_straddle": P(t=90, n=80, ua=180, fa=180, th=-90, sh=-90, ft=-75),
        "back_full": P(t=90, n=80, ua=180, fa=180, th=-90, sh=-90, ft=-75),
    }
    hold_pose = front[kind]
    hang_pose = P(t=0, ua=180, fa=180, ft=40)
    props = [hang_prop(support)]
    if dynamic:
        kfs = [KF(hang_pose, bar, [], hold=0.2, dur=1.8, label="suspendu"),
               KF(hold_pose, bar, [], hold=0.5, dur=2.0, label="position")]
    else:
        kfs = [KF(hold_pose, bar, [], hold=2.5, dur=0.8, label="tenue"),
               KF(dict(hold_pose), bar, [], hold=2.5, dur=0.8, label="tenue")]
    rex = {"epaule": [-100, 190]}
    if kind.startswith("back"):
        rex = {"epaule": [-100, 190]}
    return T("profil", kfs, props, hands_c(support), rom_exceptions=rex)


def muscle_up(kind="complet", support="barre_fixe", prop=None):
    bar = ("poignet_d", (0.0, BAR_Y))
    hang_ = P(t=-5, ua=180, fa=180, th=5, sh=-5, ft=40)
    pull = P(t=-25, ua=-40, fa=115, th=25, sh=-10, ft=40)
    trans = P(t=35, ua=-100, fa=30, th=40, sh=0, ft=40)
    top = P(t=15, ua=-10, fa=-5, th=20, sh=-5, ft=40)
    props = [hang_prop(support)]
    if prop:
        props.append(prop)
    if kind == "negatif":
        kfs = [KF(top, bar, [], hold=0.3, dur=2.0, label="appui au-dessus"),
               KF(trans, bar, [], hold=0.1, dur=2.0, label="transition freinée"),
               KF(hang_, bar, [], hold=0.5, dur=0.8, label="suspendu")]
        return T("profil", kfs, props, hands_c(support), loop="cycle")
    if kind == "transition":
        kfs = [KF(pull, bar, [], hold=0.2, dur=0.8, label="tirage haut"),
               KF(trans, bar, [], hold=0.2, dur=0.8, label="transition"),
               KF(top, bar, [], hold=0.3, dur=1.0, label="appui")]
        return T("profil", kfs, props, hands_c(support))
    if kind == "iso_transition":
        kfs = [KF(trans, bar, [], hold=3.0, dur=0.8, label="tenue transition"),
               KF(dict(trans), bar, [], hold=3.0, dur=0.8, label="tenue transition")]
        return T("profil", kfs, props, hands_c(support))
    kfs = [KF(hang_, bar, [], hold=0.3, dur=0.6, label="suspendu"),
           KF(pull, bar, [], dur=0.35, label="tirage explosif"),
           KF(trans, bar, [], dur=0.45, label="transition"),
           KF(top, bar, [], hold=0.4, dur=1.4, label="bras tendus au-dessus")]
    return T("profil", kfs, props, hands_c(support), loop="cycle")


def dips(kind="barres", prop=None):
    if kind in ("banc", "banc_genoux"):
        if kind == "banc":
            up = P(t=-5, ua=-10, fa=-10, th=60, sh=60, ft=150)
            down = P(t=-10, ua=-75, fa=5, th=60, sh=60, ft=150)
            param, foot = "jambes", "cheville_d"
        else:
            up = P(t=-5, ua=-10, fa=-10, th=80, sh=-5, ft=70)
            down = P(t=-8, ua=-70, fa=5, th=90, sh=-5, ft=70)
            param, foot = "th", "pied_d"
        props = [{"type": "banc", "x": -0.32, "y": BENCH_Y, "w": 0.3, "static": True}]
        kfs = [KF(up, on("poignet_d", BENCH_Y, -0.1), [touch(param, foot, GROUND, 0, 130)], hold=0.2, dur=1.0, label="bras tendus"),
               KF(down, on("poignet_d", BENCH_Y, -0.1), [touch(param, foot, GROUND, 0, 130)], hold=0.2, dur=1.4, label="coudes à 90°")]
        return T("profil", kfs, props, hands_c("banc") + [{"joint": foot, "with": "sol"}], rom_exceptions={"epaule": [-100, 195]})
    support = "anneaux" if kind == "anneaux" else "barres_paralleles"
    up = P(t=8, ua=-5, fa=-5, th=10, sh=-60, ft=10)
    down = P(t=25, ua=-85, fa=5, th=25, sh=-60, ft=10)
    if kind == "barre_fixe":
        support = "barre_fixe"
        up = P(t=15, ua=-10, fa=-5, th=25, sh=-5, ft=40)
        down = P(t=40, ua=-90, fa=10, th=45, sh=0, ft=40)
    if kind == "support":
        down = dict(up)
    if kind == "iso_bas":
        up = dict(down)
    y = PB_Y + 0.7 if support != "barre_fixe" else BAR_Y
    if support == "anneaux":
        y = BAR_Y - 0.2
    props = [{"type": support, "x": 0.0, "y": y, "static": True}]
    if prop:
        props.append(prop)
    anc = ("poignet_d", (0.0, y))
    hold = 2.0 if kind in ("support", "iso_bas") else 0.2
    kfs = [KF(up, anc, [], hold=hold, dur=1.0, label="bras tendus"), KF(down, anc, [], hold=hold, dur=1.4, label="bas")]
    return T("profil", kfs, props, hands_c(support))


def lsit(kind="l", support="barres_paralleles"):
    y = PB_Y + 0.7 if support == "barres_paralleles" else 0.0
    if kind == "tuck":
        a = P(t=0, ua=0, fa=0, th=100, sh=-40, ft=40)
    elif kind == "v":
        a = P(t=-30, ua=10, fa=10, th=145, sh=145, ft=200)
    elif kind == "one":
        a = P(t=0, ua=0, fa=0, th_g=95, sh_g=95, ft_g=160, th_d=100, sh_d=-40, ft_d=40)
    else:
        a = P(t=0, ua=0, fa=0, th=90, sh=90, ft=160)
    props = [{"type": "barres_paralleles", "x": 0.0, "y": y, "static": True}] if support == "barres_paralleles" else []
    anc = ("poignet_d", (0.0, y + (contact_offset("poignet_d") if y == 0.0 else 0.0)))
    kfs = [KF(a, anc, [], hold=2.5, dur=0.8, label="tenue"), KF(dict(a), anc, [], hold=2.5, dur=0.8, label="tenue")]
    return T("profil", kfs, props, hands_c(support if support == "barres_paralleles" else "sol"),
             rom_exceptions={"hanche": [-40, 160]} if kind == "v" else {})


def planche(kind="tuck"):
    poses = {
        "tuck": P(t=80, n=70, ua=-35, fa=-35, th=45, sh=-95, ft=-80),
        "adv": P(t=88, n=75, ua=-40, fa=-40, th=0, sh=-110, ft=-95),
        "straddle": P(t=90, n=75, ua=-45, fa=-45, th=-90, sh=-90, ft=-75),
        "full": P(t=90, n=75, ua=-48, fa=-48, th=-90, sh=-90, ft=-75),
    }
    a = poses[kind]
    anc = on("poignet_d", GROUND, 0.0)
    kfs = [KF(a, anc, [], hold=2.5, dur=0.8, label="tenue"), KF(dict(a), anc, [], hold=2.5, dur=0.8, label="tenue")]
    return T("profil", kfs, [], hands_c("sol"))


def handstand(kind="libre"):
    a = P(t=180, n=180, ua=0, fa=0, th=180, sh=180, ft=195)
    anc = on("poignet_d", GROUND, 0.0)
    props = []
    if kind == "dos_mur":
        props = [{"type": "mur", "x": -0.14, "static": True}]
        a = P(t=172, n=172, ua=0, fa=0, th=172, sh=172, ft=187)
    if kind == "poitrine_mur":
        props = [{"type": "mur", "x": 0.10, "static": True}]
        a = P(t=185, n=185, ua=0, fa=0, th=185, sh=185, ft=200)
    kfs = [KF(a, anc, [], hold=3.0, dur=0.8, label="tenue")]
    if kind == "hspu":
        props = [{"type": "mur", "x": -0.14, "static": True}]
        a = P(t=172, n=172, ua=0, fa=0, th=172, sh=172, ft=187)
        b = P(t=170, n=160, ua=-90, fa=0, th=170, sh=170, ft=185)
        kfs = [KF(a, anc, [], hold=0.3, dur=1.0, label="bras tendus"), KF(b, anc, [], hold=0.2, dur=1.6, label="tête proche du sol")]
    elif kind == "taps":
        b = dict(a)
        b.update({"ua_g": 180, "fa_g": 180})
        kfs = [KF(a, anc, [], hold=0.8, dur=0.4, label="appui deux mains"), KF(b, anc, [], hold=0.3, dur=0.4, label="main levée")]
        return T("profil", kfs, props, [{"joint": "poignet_d", "with": "sol"}], rom_exceptions={"epaule": [-95, 200]})
    elif kind == "wall_walk":
        s = P(t=80, ua=-5, fa=-5)
        kfs = [KF(s, on("poignet_d", GROUND, 0.35), [touch("t", "pied_d", GROUND, 40, 120)], hold=0.3, dur=2.5, label="planche, pieds au sol"),
               KF(P(t=185, n=185, ua=0, fa=0, th=185, sh=185, ft=200), anc, [], hold=1.0, dur=2.5, label="ATR poitrine face au mur")]
        kfs[0]["link"] = "gaine"
        props = [{"type": "mur", "x": 0.10, "static": True}]
        return T("profil", kfs, props, [{"joint": "poignet_d", "with": "sol"}])
    else:
        kfs.append(KF(dict(a), anc, [], hold=3.0, dur=0.8, label="tenue"))
    return T("profil", kfs, props, hands_c("sol"))


def flag(kind="full"):
    # vue de face ; tête vers +x, poteau vertical au niveau des mains
    if kind == "vertical":
        a = P(t=175, n=175, ua_g=0, fa_g=0, ua_d=-5, fa_d=-5, th=185, sh=185, ft=185)
        a["ua_g"], a["fa_g"] = 5, 5
    elif kind == "tuck":
        a = P(t=90, n=90, ua_g=70, fa_g=70, ua_d=110, fa_d=110, th=-40, sh=-130, ft=-130)
    elif kind == "straddle":
        a = P(t=90, n=90, ua_g=70, fa_g=70, ua_d=110, fa_d=110)
        a.update({"th_g": -60, "sh_g": -60, "ft_g": -60, "th_d": -120, "sh_d": -120, "ft_d": -120})
    else:
        a = P(t=90, n=90, ua_g=70, fa_g=70, ua_d=110, fa_d=110, th=-90, sh=-90, ft=-90)
    anc = ("poignet_g", (0.0, 0.55))
    kfs = [KF(a, anc, [], hold=2.0, dur=0.8, label="tenue"), KF(dict(a), anc, [], hold=2.0, dur=0.8, label="tenue")]
    props = [{"type": "poteau", "x": 0.0, "static": True}]
    return T("face", kfs, props, [{"joint": "poignet_g", "with": "poteau"}],
             rom_exceptions={"epaule": [-200, 200], "hanche": [-120, 120], "genou": [-160, 160]},
             note="drapeau vu de face : les mains tiennent un poteau vertical")


# --------------------------------------------------------------------------
# Locomotion, conditionnement, portés
# --------------------------------------------------------------------------

def gait(kind="marche", prop=None):
    if kind == "course" or kind == "sprint":
        a = P(t=10, ua_g=40, fa_g=120, ua_d=-40, fa_d=60, th_g=-20, sh_g=-80, ft_g=-20, th_d=70, sh_d=0, ft_d=70)
        b = P(t=10, ua_d=40, fa_d=120, ua_g=-40, fa_g=60, th_d=-20, sh_d=-80, ft_d=-20, th_g=70, sh_g=0, ft_g=70)
        kfs = [KF(a, ("bassin", (0.0, 0.53)), [], dur=0.3 if kind == "course" else 0.2, label="appui gauche"),
               KF(b, ("bassin", (0.0, 0.53)), [], dur=0.3 if kind == "course" else 0.2, label="appui droit")]
        return T("profil", kfs, [], [], loop="cycle")
    arms_a = dict(ua_g=20, fa_g=30, ua_d=-20, fa_d=-10)
    arms_b = dict(ua_g=-20, fa_g=-10, ua_d=20, fa_d=30)
    if kind == "porte":
        arms_a = arms_b = dict(ua=0, fa=0)
    if kind == "overhead":
        arms_a = arms_b = dict(ua=178, fa=178)
    a = P(th_g=-18, sh_g=-30, ft_g=40, th_d=18, sh_d=10, ft_d=85, **arms_a)
    b = P(th_d=-18, sh_d=-30, ft_d=40, th_g=18, sh_g=10, ft_g=85, **arms_b)
    props = [prop] if prop else []
    kfs = [KF(a, ("pied_d", (0.18, 0.0)), [touch("jambe_g", "pied_g", GROUND, -45, 10)], dur=0.55, label="pas droit"),
           KF(b, ("pied_g", (0.18, 0.0)), [touch("jambe_d", "pied_d", GROUND, -45, 10)], dur=0.55, label="pas gauche")]
    return T("profil", kfs, props, [], loop="cycle")


def jacks():
    a = P(ua_g=8, ua_d=-8, fa_g=8, fa_d=-8, ft=0)
    b = P(ua_g=165, ua_d=-165, fa_g=170, fa_d=-170, th_g=18, th_d=-18, sh_g=18, sh_d=-18, ft_g=18, ft_d=-18)
    kfs = [KF(a, ("pied_d", (-0.085, 0.0)), [], dur=0.35, label="pieds joints"),
           KF(b, ("pied_d", (-0.24, 0.0)), [touch("t", "pied_g", GROUND, -5, 5)], dur=0.35, label="écart")]
    return T("face", kfs, [], [], loop="aller-retour")


def burpee(kind="standard"):
    stand = P()
    squat_ = P(th=110, sh=-35, ua=5, fa=5)
    plank_ = P(t=80, ua=-5, fa=-5, th=-100, sh=-100, ft=-10)
    air = P(ua=170, fa=170, ft=30)
    kfs = [KF(stand, SA, [balance(lo=-10, hi=10)], dur=0.4, label="debout"),
           KF(squat_, SA, [balance(lo=10, hi=90)], dur=0.35, label="mains au sol"),
           KF(plank_, on("poignet_d", GROUND, 0.30), [touch("t", "pied_d", GROUND, 40, 120)], dur=0.5, label="planche"),
           KF(air, ("pied_d", (0.12, 0.18)), [balance(lo=-10, hi=10, dx=0.0)], dur=0.4, label="saut")]
    kfs[2]["link"] = "gaine"
    return T("profil", kfs, [], [{"joint": "pied_d", "with": "sol", "kf": [0, 1, 2]}], loop="cycle")


def olympic(kind="clean", prop=None):
    floor = P(t=45, th=70, sh=-30, ua=5, fa=5)
    ext = P(t=-5, ua=0, fa=0, ft=20)
    rack = P(t=0, th=40, sh=-25, ua=80, fa=175)
    over = P(ua=175, fa=178)
    if kind == "snatch":
        kfs = [KF(floor, SA, [balance(lo=20, hi=70)], dur=0.8, label="départ"),
               KF(ext, SA, [balance(lo=-15, hi=15, dx=0.08)], dur=0.3, label="extension"),
               KF(P(th=95, sh=-35, ua=145, fa=147), SA, [balance(lo=-10, hi=60)], hold=0.4, dur=0.8, label="réception bras tendus"),
               KF(over, SA, [balance(lo=-10, hi=15)], hold=0.6, dur=1.2, label="debout")]
    elif kind == "clean_press":
        kfs = [KF(floor, SA, [balance(lo=20, hi=70)], dur=0.8, label="départ"),
               KF(ext, SA, [balance(lo=-15, hi=15, dx=0.08)], dur=0.3, label="extension"),
               KF(rack, SA, [balance(lo=-10, hi=40)], hold=0.3, dur=0.6, label="réception"),
               KF(over, SA, [balance(lo=-10, hi=15)], hold=0.5, dur=1.2, label="bras tendus")]
    elif kind == "thruster":
        kfs = [KF(P(ua=80, fa=175), SA, [balance(lo=-10, hi=20)], dur=0.9, label="debout, barre en rack"),
               KF(P(th=95, sh=-32, ua=80, fa=175), SA, [balance(lo=-10, hi=70)], dur=0.6, label="squat"),
               KF(over, SA, [balance(lo=-10, hi=15)], hold=0.3, dur=0.9, label="poussée bras tendus")]
    elif kind == "swing":
        kfs = [KF(P(t=60, th=15, sh=-15, ua=-25, fa=-25), SA, [balance(param="th", lo=0, hi=40)], dur=0.5, label="charnière"),
               KF(P(t=-3, ua=90, fa=90), SA, [balance(lo=-15, hi=10)], hold=0.1, dur=0.5, label="hanches verrouillées")]
    else:
        kfs = [KF(floor, SA, [balance(lo=20, hi=70)], dur=0.8, label="départ"),
               KF(ext, SA, [balance(lo=-15, hi=15, dx=0.08)], dur=0.3, label="extension"),
               KF(rack, SA, [balance(lo=-10, hi=40)], hold=0.5, dur=1.2, label="réception")]
    props = [prop] if prop else []
    return T("profil", kfs, props, [{"joint": "pied_d", "with": "sol"}], loop="cycle" if kind != "swing" else "aller-retour")


def ergo(kind="rameur"):
    if kind == "rameur":
        a = P(t=20, ua=80, fa=80, th=145, sh=15, ft=100)
        b = P(t=-20, ua=-40, fa=85, th=95, sh=85, ft=170)
        props = [{"type": "rameur", "x": 0.0, "y": 0.0, "static": True}]
        kfs = [KF(a, ("bassin", (-0.15, 0.18)), [], dur=0.9, label="attaque"),
               KF(b, ("bassin", (-0.45, 0.18)), [], dur=0.6, label="fin de tirage")]
        return T("profil", kfs, props, [], loop="aller-retour",
                 rom_exceptions={"hanche": [-40, 170]})
    if kind == "velo":
        a = P(t=25, ua=55, fa=80, th_g=40, sh_g=-30, ft_g=80, th_d=95, sh_d=10, ft_d=100)
        b = P(t=25, ua=55, fa=80, th_d=40, sh_d=-30, ft_d=80, th_g=95, sh_g=10, ft_g=100)
        props = [{"type": "velo", "x": 0.0, "y": 0.0, "static": True}]
        kfs = [KF(a, ("bassin", (0.0, 0.62)), [], dur=0.35, label="pédale"), KF(b, ("bassin", (0.0, 0.62)), [], dur=0.35, label="pédale")]
        return T("profil", kfs, props, [], loop="cycle")
    if kind == "skierg":
        a = P(t=0, ua=170, fa=170, th=5, sh=-5)
        b = P(t=45, th=40, sh=-30, ua=-20, fa=-20)
        props = [{"type": "poulie", "x": 0.45, "y": 1.6, "static": True, "to": ["poignet_d"]}]
        kfs = [KF(a, SA, [balance(lo=-15, hi=15)], dur=0.5, label="bras hauts"), KF(b, SA, [balance(param="th", lo=10, hi=80)], dur=0.5, label="tirage")]
        return T("profil", kfs, props, feet_c())
    raise ValueError(kind)


def throw(kind="slam", prop=None):
    a = P(ua=175, fa=175, ft=40)
    b = P(t=55, th=60, sh=-30, ua=40, fa=40)
    kfs = [KF(a, SA, [balance(lo=-15, hi=10, dx=0.08)], dur=0.5, label="bras hauts"),
           KF(b, SA, [balance(lo=10, hi=90)], dur=0.4, label="lancer au sol")]
    if kind == "wall_ball":
        kfs = [KF(P(th=95, sh=-32, ua=15, fa=160), SA, [balance(lo=-10, hi=70)], dur=0.6, label="squat"),
               KF(P(ua=160, fa=160, ft=40), SA, [balance(lo=-15, hi=10, dx=0.08)], dur=0.5, label="lancer")]
    props = [prop] if prop else [{"type": "medecine_ball", "attach": "poignets"}]
    return T("profil", kfs, props, [{"joint": "pied_d", "with": "sol"}], loop="aller-retour")


def rope(kind="corde"):
    a = P(ua=15, fa=60, ft=40)
    b = P(ua=15, fa=60, ft=40, th=10, sh=-10)
    kfs = [KF(a, ("pied_d", (0.12, 0.06)), [], dur=0.25, label="en l'air"), KF(b, SA, [balance(lo=-10, hi=10)], dur=0.25, label="appui")]
    props = [{"type": "corde_a_sauter", "between": ["poignet_g", "poignet_d"]}] if kind == "corde" else \
        [{"type": "battle_rope", "x": 0.9, "y": 0.02, "static": True, "to": ["poignet_d"]}]
    if kind == "battle":
        kfs = [KF(P(th=40, sh=-25, t=20, ua=60, fa=100), SA, [balance(lo=0, hi=50)], dur=0.25, label="haut"),
               KF(P(th=40, sh=-25, t=20, ua=30, fa=50), SA, [balance(lo=0, hi=50)], dur=0.25, label="bas")]
    return T("profil", kfs, props, [], loop="aller-retour")


def sled(kind="push"):
    if kind == "push":
        a = P(t=55, ua=65, fa=90, th_g=-25, sh_g=-60, ft_g=10, th_d=70, sh_d=-15, ft_d=70)
        b = P(t=55, ua=65, fa=90, th_d=-25, sh_d=-60, ft_d=10, th_g=70, sh_g=-15, ft_g=70)
        props = [{"type": "traineau", "x": 0.75, "y": 0.0, "static": True}]
    else:
        a = P(t=-8, ua=50, fa=50, th_g=-25, sh_g=-60, ft_g=10, th_d=60, sh_d=-15, ft_d=70)
        b = P(t=-8, ua=50, fa=50, th_d=-25, sh_d=-60, ft_d=10, th_g=60, sh_g=-15, ft_g=70)
        props = [{"type": "traineau", "x": 0.95, "y": 0.0, "static": True, "to": ["poignet_d"]}]
    kfs = [KF(a, ("pied_g", (0.0, 0.0)), [touch("th_d", "pied_d", GROUND, 20, 110)], dur=0.5, label="pas"),
           KF(b, ("pied_d", (0.0, 0.0)), [touch("th_g", "pied_g", GROUND, 20, 110)], dur=0.5, label="pas")]
    return T("profil", kfs, props, [], loop="cycle")


def turkish():
    a = P(t=-90, n=-80, ua_d=180, fa_d=180, ua_g=90, fa_g=90, th_d=135, sh_d=35, ft_d=70, th_g=95, sh_g=95, ft_g=160)
    b = P(t=-35, n=-25, ua_d=150, fa_d=150, ua_g=-42, fa_g=-42, th_d=135, sh_d=35, ft_d=70, th_g=95, sh_g=95, ft_g=160)
    c = P(t=0, ua_d=178, fa_d=178, ua_g=0, fa_g=0)
    kfs = [KF(a, on("bassin", GROUND, 0.0), [], dur=1.5, label="allongé"),
           KF(b, on("bassin", GROUND, 0.0), [], dur=2.5, label="appui sur la main"),
           KF(c, SA, [balance(lo=-10, hi=10)], hold=0.5, dur=2.0, label="debout bras tendu")]
    return T("profil", kfs, [{"type": "kettlebell", "attach": "poignet_d"}], [], loop="aller-retour")


def standing_static(kind="respiration"):
    if kind == "respiration":
        a = P(ua=10, fa=90)
        b = P(ua=12, fa=92, n=4)
    elif kind == "etirement_post":
        a = P(ua=5, fa=5)
        b = P(t=95, n=100, ua=5, fa=5)
        kfs = [KF(a, SA, [balance(lo=-10, hi=10)], hold=1.0, dur=2.0, label="debout"),
               KF(b, SA, [balance(param="th", lo=-30, hi=30, dx=0.05)], hold=3.0, dur=2.0, label="flexion avant")]
        return T("profil", kfs, [], feet_c(), rom_exceptions={"hanche": [-40, 160]})
    elif kind == "dislocation":
        a = P(ua=5, fa=5)
        b = P(ua=180, fa=180)
        c = P(ua=-60, fa=-60)
        kfs = [KF(a, SA, [balance(lo=-10, hi=10)], dur=1.2, label="devant"), KF(b, SA, [balance(lo=-10, hi=10)], dur=1.2, label="au-dessus"),
               KF(c, SA, [balance(lo=-10, hi=10)], hold=0.3, dur=1.2, label="derrière")]
        return T("profil", kfs, [{"type": "baton", "between": ["poignet_g", "poignet_d"]}], feet_c())
    elif kind == "wall_slide":
        a = P(ua=95, fa=180, t=-2)
        b = P(ua=160, fa=175, t=-2)
        kfs = [KF(a, SA, [balance(lo=-10, hi=10)], dur=1.5, label="coudes à 90°"), KF(b, SA, [balance(lo=-10, hi=10)], hold=0.5, dur=1.5, label="bras glissés vers le haut")]
        return T("profil", kfs, [{"type": "mur", "x": -0.16, "static": True}], feet_c())
    elif kind == "poignets":
        a = P(ua=0, fa=90)
        b = P(ua=0, fa=100)
    elif kind == "grip":
        a = P(ua=0, fa=80)
        b = P(ua=0, fa=85)
    elif kind == "cheville":
        a = P(th_d=40, sh_d=-10, ft_d=70, th_g=-20, sh_g=-32, ft_g=30, ua=90, fa=90)
        b = P(th_d=70, sh_d=-35, ft_d=70, th_g=-20, sh_g=-32, ft_g=30, ua=90, fa=90)
        kfs = [KF(a, SA, [balance(lo=-10, hi=20), touch("jambe_g", "pied_g", GROUND, -70, 10)], dur=1.2, label="départ"),
               KF(b, SA, [balance(lo=-10, hi=40), touch("jambe_g", "pied_g", GROUND, -70, 10)], hold=1.0, dur=1.2, label="genou vers le mur")]
        return T("profil", kfs, [{"type": "mur", "x": 0.55, "static": True}], feet_c())
    elif kind == "squat_profond":
        a = P(th=112, sh=-42, ua=70, fa=100)
        b = P(th=114, sh=-42, ua=80, fa=110)
        kfs = [KF(a, SA, [balance(lo=0, hi=70)], hold=2.0, dur=1.0, label="tenue"), KF(b, SA, [balance(lo=0, hi=70)], hold=2.0, dur=1.0, label="tenue")]
        return T("profil", kfs, [], feet_c())
    elif kind == "rotations_bras":
        a = P(ua=90, fa=90)
        b = P(ua=180, fa=180)
        c = P(ua=-40, fa=-40)
        kfs = [KF(a, SA, [balance(lo=-10, hi=10)], dur=0.6, label="avant"), KF(b, SA, [balance(lo=-10, hi=10)], dur=0.6, label="haut"),
               KF(c, SA, [balance(lo=-10, hi=10)], dur=0.6, label="arrière")]
        return T("profil", kfs, [], feet_c(), loop="cycle")
    elif kind == "rotation_thoracique":
        a = P(ua=90, fa=160, t=0)
        b = P(ua=90, fa=160, t=-5, n=-5)
    elif kind == "jefferson":
        a = P(ua=0, fa=0)
        b = P(t=110, n=120, ua=0, fa=0)
        kfs = [KF(a, SA, [balance(lo=-10, hi=10)], hold=0.5, dur=3.0, label="debout"),
               KF(b, SA, [balance(param="th", lo=-30, hi=30, dx=0.05)], hold=1.0, dur=3.0, label="enroulé")]
        return T("profil", kfs, [], feet_c(), rom_exceptions={"hanche": [-40, 160]},
                 note="enroulement vertébral schématisé par un tronc rigide")
    else:
        raise ValueError(kind)
    kfs = [KF(a, SA, [balance(lo=-10, hi=10)], hold=1.5, dur=1.5, label="tenue"), KF(b, SA, [balance(lo=-10, hi=10)], hold=1.5, dur=1.5, label="tenue")]
    return T("profil", kfs, [], feet_c())


def side_bend(prop=None):
    a = P(ua_g=5, ua_d=-5, fa_g=5, fa_d=-5, ft=0, p=0)
    b = P(t=-18, n=-15, ua_g=10, ua_d=-25, fa_g=10, fa_d=-25, ft=0, p=0)
    kfs = [KF(a, on("pied_d", GROUND, -0.085), [], dur=1.2, label="droit"),
           KF(b, on("pied_d", GROUND, -0.085), [], hold=0.3, dur=1.2, label="inclinaison")]
    return T("face", kfs, [prop] if prop else [], feet_c())


def windmill():
    a = P(ua_g=178, fa_g=178, ua_d=-5, fa_d=-5, ft=0, th_g=10, sh_g=10, th_d=-10, sh_d=-10, p=0)
    b = P(t=-50, n=-40, ua_g=130, fa_g=130, ua_d=-50, fa_d=-50, th_g=10, sh_g=10, th_d=-10, sh_d=-10, ft=0, p=0)
    anc = on("pied_d", GROUND, -0.12)
    kfs = [KF(a, anc, [], dur=1.5, label="debout"), KF(b, anc, [], hold=0.4, dur=1.5, label="inclinaison")]
    return T("face", kfs, [{"type": "kettlebell", "attach": "poignet_g"}], feet_c(),
             note="inclinaison du buste schématisée par la rotation du tronc au-dessus d'un bassin horizontal")


def copenhagen():
    a = P(t=-72, ua_d=0, fa_d=-90, ua_g=72, fa_g=72)
    kfs = [KF(a, on("coude_d", GROUND, 0.0), [touch("t", "cheville_g", BENCH_Y, -85, -40)], hold=2.0, dur=0.8, label="tenue"),
           KF(dict(a), on("coude_d", GROUND, 0.0), [touch("t", "cheville_g", BENCH_Y, -85, -40)], hold=2.0, dur=0.8, label="tenue")]
    for kf in kfs:
        kf["link"] = "gaine_face"
    return T("face", kfs, [{"type": "banc", "x": 0.55, "y": BENCH_Y, "w": 0.3, "static": True}],
             [{"joint": "coude_d", "with": "sol"}], note="planche Copenhague vue de face, jambe du dessus sur le banc")


def foam():
    a = P(t=-65, n=-55, ua=-25, fa=-25, th=95, sh=95, ft=160)
    kfs = [KF(a, on("poignet_d", GROUND, -0.3), [touch("t", "cheville_d", 0.10, -85, -40)], dur=1.5, label="rouleau sous les mollets"),
           KF(dict(a), on("poignet_d", GROUND, -0.15), [touch("t", "genou_d", 0.10, -85, -40)], dur=1.5, label="rouleau sous les cuisses")]
    return T("profil", kfs, [{"type": "rouleau", "attach": "genou_d"}], [{"joint": "poignet_d", "with": "sol"}])


def hip_thrust(prop=None):
    a = P(t=-45, n=-30, ua=60, fa=60, th=100, sh=10, ft=70)
    b = P(t=-95, n=-70, ua=60, fa=60, th=95, sh=0, ft=70)
    props = [{"type": "banc", "x": -0.55, "y": BENCH_Y, "w": 0.3, "static": True}]
    if prop:
        props.append(prop)
    anc = on("epaule_d", BENCH_Y, -0.30)
    kfs = [KF(a, anc, [touch("th", "pied_d", GROUND, 20, 175)], hold=0.2, dur=1.0, label="bassin bas"),
           KF(b, anc, [touch("th", "pied_d", GROUND, 20, 175)], hold=1.0, dur=1.0, label="bassin haut")]
    return T("profil", kfs, props, [{"joint": "epaule_d", "with": "banc"}, {"joint": "pied_d", "with": "sol"}])


REGISTRY = {}


def reg(name, fn, *args, **kwargs):
    REGISTRY[name] = (fn, args, kwargs)


# Les gabarits sont nommés : <famille>.<variante>
for n, a in {"squat.pdc": ("avant",), "squat.gobelet": ("gobelet",), "squat.dos": ("dos",), "squat.front": ("front",),
             "squat.overhead": ("overhead",), "squat.zercher": ("zercher",), "squat.assiste": ("assiste",),
             "squat.bas": ("bas",)}.items():
    reg(n, squat, *a)
reg("squat.saute", squat, "hanches", jump=True)
reg("squat.box", squat, "dos", box=True)
reg("squat.chaise", squat, "avant", box=True)
reg("squat.wall_sit", wall_sit)
reg("hinge.barre", hinge)
reg("hinge.sol", hinge, from_floor=True)
reg("hinge.unijambe", hinge, one_leg=True)
reg("fente.avant", lunge)
reg("fente.bulgare", lunge, rear_on_bench=True)
reg("fente.laterale", lateral_lunge)
reg("pistol.libre", pistol)
reg("pistol.box", pistol, box=True)
reg("pistol.shrimp", shrimp)
reg("step.bas", step_up)
reg("step.haut", step_up, high=True)
reg("mollets.debout", calf_raise)
reg("mollets.unijambe", calf_raise, one_leg=True)
for k in ("vertical", "tuck", "box", "longueur"):
    reg(f"saut.{k}", jump, k)
reg("press.debout", overhead_press)
reg("press.assis", overhead_press, seated=True)
reg("press.push", overhead_press, push=True)
reg("curl.debout", curl)
reg("curl.pupitre", curl, "pupitre")
reg("triceps.nuque", triceps_ext, "nuque")
reg("triceps.poulie", triceps_ext, "poulie")
reg("triceps.kickback", triceps_ext, "kickback")
reg("elevation.laterale", lateral_raise)
reg("elevation.frontale", front_raise)
reg("elevation.oiseau", front_raise, kind="oiseau")
reg("rowing.penche", row_bent)
reg("rowing.appui", row_bent, torso=75)
reg("tirage.shrug", upright, "shrug")
reg("tirage.menton", upright, "menton")
for k in ("face_pull", "pull_apart", "straight_arm", "rotation_ext", "woodchop", "pallof", "crunch", "pullover"):
    reg(f"cable.{k}", cable_standing, k)
for k in ("pulldown", "row", "leg_extension", "leg_curl", "press", "calf_seated", "pec_deck"):
    reg(f"assis.{k}", seated, k)
reg("assis.abduction", seated_face, "abduction")
reg("assis.adduction", seated_face, "adduction")
for k in ("standard", "genoux", "inclinee", "declinee", "mur", "pike", "diamant", "pseudo"):
    reg(f"pompe.{k}", pushup, k)
for k in ("coudes", "bras_tendus", "genoux", "lean", "pseudo_hold"):
    reg(f"planche_gainage.{k}", plank, k)
reg("planche_laterale.standard", side_plank)
reg("planche_laterale.copenhague", copenhagen)
for k in ("hollow", "hollow_tuck", "dead_bug", "crunch", "situp", "leg_raise", "vup", "flutter", "twist", "bridge", "dragon_flag"):
    reg(f"dos_au_sol.{k}", supine, k)
for k in ("superman", "ytw", "bird_dog", "cat_cow"):
    reg(f"ventre.{k}", prone, k)
for k in ("bear_crawl", "mountain", "crab"):
    reg(f"quadrupedie.{k}", quadruped, k)
for k in ("couche", "ecarte", "barre_front", "hip_thrust", "floor", "pause"):
    reg(f"banc.{k}", bench_lying, k) if k != "hip_thrust" else reg("banc.hip_thrust", hip_thrust)
reg("banc.incline", bench_lying, "couche", incline=35)
reg("pont.fessier", glute_bridge)
reg("pont.unijambe", glute_bridge, one_leg=True)
for k in ("ab_wheel", "nordic", "hip_flexor"):
    reg(f"genoux.{k}", kneeling, k)
reg("assis_sol.lsit", seated_floor, "lsit_sol")
reg("assis_sol.flexion", seated_floor, "forward_fold")
for s in ("barre_fixe", "anneaux"):
    for k in ("standard", "poitrine", "l_sit"):
        reg(f"traction.{k}.{s}", pullup, k, support=s)
    for k in ("passif", "scap", "iso90", "iso_haut", "knee_raise", "leg_raise", "toes_to_bar", "german", "skin_cat", "l_sit_barre", "windshield"):
        reg(f"suspension.{k}.{s}", hang, k, support=s)
    for k in ("complet", "negatif", "transition", "iso_transition"):
        reg(f"muscle_up.{k}.{s}", muscle_up, k, support=s)
for k in ("front_tuck", "front_adv", "front_one", "front_straddle", "front_full", "back_tuck", "back_adv", "back_straddle", "back_full"):
    reg(f"levier.{k}", lever, k)
    reg(f"levier.{k}.dynamique", lever, k, dynamic=True)
for k in ("barres", "anneaux", "banc", "banc_genoux", "barre_fixe", "support", "iso_bas"):
    reg(f"dips.{k}", dips, k)
for k in ("l", "tuck", "v", "one"):
    reg(f"lsit.{k}", lsit, k)
reg("lsit.sol", lsit, "l", support="sol")
for k in ("tuck", "adv", "straddle", "full"):
    reg(f"planche_skill.{k}", planche, k)
for k in ("libre", "dos_mur", "poitrine_mur", "hspu", "taps", "wall_walk"):
    reg(f"atr.{k}", handstand, k)
for k in ("vertical", "tuck", "straddle", "full"):
    reg(f"drapeau.{k}", flag, k)
for k in ("marche", "course", "sprint", "porte", "overhead"):
    reg(f"locomotion.{k}", gait, k)
reg("cardio.jacks", jacks)
reg("cardio.burpee", burpee)
for k in ("clean", "snatch", "clean_press", "thruster", "swing"):
    reg(f"olympique.{k}", olympic, k)
for k in ("rameur", "velo", "skierg"):
    reg(f"ergo.{k}", ergo, k)
reg("lancer.slam", throw, "slam")
reg("lancer.wall_ball", throw, "wall_ball")
reg("corde.saut", rope, "corde")
reg("corde.battle", rope, "battle")
reg("traineau.push", sled, "push")
reg("traineau.pull", sled, "pull")
reg("turkish.getup", turkish)
for k in ("respiration", "etirement_post", "dislocation", "wall_slide", "poignets", "grip", "cheville", "squat_profond",
          "rotations_bras", "rotation_thoracique", "jefferson"):
    reg(f"debout.{k}", standing_static, k)
reg("face.inclinaison", side_bend)
reg("face.windmill", windmill)
reg("sol.foam", foam)


def build_template(name):
    fn, args, kwargs = REGISTRY[name]
    return fn(*args, **kwargs)
