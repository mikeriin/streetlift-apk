"""Dérivation des rôles de couleur des 8 palettes du propriétaire (HCT, contrastes WCAG).

Règle : la valeur du propriétaire est gardée telle quelle quand elle passe le
contraste exigé par son rôle ; sinon on garde sa teinte et sa chroma (HCT) et on
déplace seulement sa tonalité, du plus petit pas qui satisfait le contraste.
"""
import json
from materialyoucolor.hct import Hct
from materialyoucolor.utils.color_utils import argb_from_rgb

PAL = {
    "bordeaux": ("Bordeaux Performance", "#551515", "#8E3030", "#D9A66C", "#181819", "#F6F2EF"),
    "obsidian": ("Obsidian Energy", "#E5484D", "#FF8566", "#FFC857", "#121316", "#F2F3F5"),
    "arctic": ("Arctic Motion", "#2563EB", "#4F9CF9", "#14B8A6", "#152238", "#F5F8FC"),
    "neon": ("Neon Athlete", "#B4F044", "#67D8C0", "#8C72FF", "#101510", "#F2F9EA"),
    "titanium": ("Titanium Pro", "#4C6474", "#8A9DA8", "#D5A24C", "#171E24", "#E8EDF0"),
    "violet": ("Violet Momentum", "#7546DB", "#AC8CFA", "#29BFB0", "#181427", "#F5F1FF"),
    "forest": ("Forest Endurance", "#236B50", "#7BAC81", "#D7B374", "#17251D", "#F4F5EE"),
    "solar": ("Solar Sprint", "#D95A27", "#FF9760", "#E8BC49", "#211B1A", "#FFF6ED"),
}


def argb(h):
    h = h.lstrip("#")
    return argb_from_rgb(int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def hexa(a):
    return "#%06X" % (a & 0xFFFFFF)


def lum(h):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    c = [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]


def cr(a, b):
    la, lb = lum(a), lum(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def hct(h):
    return Hct.from_int(argb(h))


def tone(h, t, chroma=None):
    x = hct(h)
    return hexa(Hct.from_hct(x.hue, x.chroma if chroma is None else chroma, t).to_int())


def adjust(h, against, need, direction):
    """Garde h s'il passe ; sinon déplace la tonalité (direction +1 éclaircit, -1 assombrit)."""
    if cr(h, against) >= need:
        return h
    t0 = hct(h).tone
    for step in range(1, 101):
        t = t0 + direction * step * 0.5
        if t < 0 or t > 100:
            break
        c = tone(h, t)
        if cr(c, against) >= need:
            return c
    raise SystemExit(f"impossible {h} {against} {need}")


def on_color(fill):
    w, b = cr(fill, "#FFFFFF"), cr(fill, "#121212")
    return ("#FFFFFF", w) if w >= b else ("#121212", b)


def fill_role(d, dark):
    f = d
    if dark and hct(f).tone < 35:
        f = tone(f, 35)
    on, c = on_color(f)
    if on != "#FFFFFF":
        # préférer un texte blanc si 6 points de tonalité au plus suffisent
        t0 = hct(f).tone
        for k in range(1, 13):
            g = tone(f, t0 - k * 0.5)
            if cr(g, "#FFFFFF") >= 4.5:
                f, on, c = g, "#FFFFFF", cr(g, "#FFFFFF")
                break
    if c < 4.5:
        f = adjust(f, on, 4.5, -1 if on == "#FFFFFF" else 1)
        on, c = on_color(f)
    return f, on


out = {}
for key, (name, d, s, a, fd, fc) in PAL.items():
    fdh = hct(fd)
    sd = lambda dt, ch=None: hexa(Hct.from_hct(fdh.hue, min(fdh.chroma, 16) if ch is None else ch, fdh.tone + dt).to_int())
    dark = {
        "fond": fd, "surface": sd(5), "haute": sd(10), "filet": sd(15),
        "texte": hexa(Hct.from_hct(fdh.hue, 2, 95).to_int()),
        "texte2": hexa(Hct.from_hct(fdh.hue, 4, 70).to_int()),
        "texte3": hexa(Hct.from_hct(fdh.hue, 4, 50).to_int()),
    }
    dark["pleine"], dark["surPleine"] = fill_role(d, True)
    dark["encre"] = adjust(d, dark["surface"], 4.5, 1)
    dark["second"] = adjust(s, dark["surface"], 3.0, 1)
    dark["accent"] = adjust(a, dark["surface"], 4.5, 1)
    fch = hct(fc)
    light = {
        "fond": fc, "surface": "#FFFFFF",
        "haute": fc, "filet": hexa(Hct.from_hct(fch.hue, min(fch.chroma, 8), fch.tone - 10).to_int()),
        "texte": hexa(Hct.from_hct(fch.hue, 4, 10).to_int()),
        "texte2": hexa(Hct.from_hct(fch.hue, 6, 40).to_int()),
        "texte3": hexa(Hct.from_hct(fch.hue, 6, 60).to_int()),
    }
    light["pleine"], light["surPleine"] = fill_role(d, False)
    light["encre"] = adjust(adjust(d, "#FFFFFF", 4.5, -1), fc, 4.5, -1)
    light["second"] = adjust(s, "#FFFFFF", 3.0, -1)
    light["accent"] = adjust(adjust(a, "#FFFFFF", 4.5, -1), fc, 4.5, -1)
    # contrôles
    for th in (dark, light):
        th["_c"] = {
            "texte/fond": round(cr(th["texte"], th["fond"]), 2),
            "texte2/surface": round(cr(th["texte2"], th["surface"]), 2),
            "surPleine/pleine": round(cr(th["surPleine"], th["pleine"]), 2),
            "encre/surface": round(cr(th["encre"], th["surface"]), 2),
            "accent/surface": round(cr(th["accent"], th["surface"]), 2),
            "second/surface": round(cr(th["second"], th["surface"]), 2),
        }
    out[key] = {"nom": name, "source": {"dominante": d, "secondaire": s, "accent": a, "fondSombre": fd, "fondClair": fc}, "sombre": dark, "clair": light}

print(json.dumps(out, indent=1, ensure_ascii=False))
