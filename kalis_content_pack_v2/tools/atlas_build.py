"""Construit atlas.svg et muscles.json (L9R, étape 3).

Usage : python3 tools/atlas_build.py <dossier_sortie> [--debug planche.html]

atlas.svg : viewBox 0 0 600 760 ; groupe #vue-face (x 0..300) et #vue-dos
(x 300..600). Chaque région superficielle : <path id="{vue}-{muscle}-{cote}"
data-muscle="…" data-side="d|g" class="muscle">. Couleurs : aucune valeur de
thème dans le fichier ; le corps est en fill="currentColor" atténué et les
régions en fill="currentColor" (opacité faible) : l'hôte (moteur de rendu,
application) applique les rôles primaire / secondaire / stabilisateur.
"""
import json
import os
import sys

from shapely.geometry import Polygon
from shapely.ops import unary_union

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import atlas_geom as G  # noqa: E402
import kb_muscles as KM  # noqa: E402

VIEW_W = 300


def _clean(poly):
    if poly.is_empty:
        return []
    geoms = list(poly.geoms) if hasattr(poly, "geoms") else [poly]
    out = []
    for g in geoms:
        if g.geom_type == "Polygon" and g.area > 4:
            out.append(g)
    return out


def build_view(regions, half, base_side):
    """Découpe les régions du côté décrit (x<150) puis symétrise.

    Retourne (silhouette_polygon, [(muscle, cote, Polygon)], stats).
    """
    sil_pts = G.silhouette(half)
    sil = Polygon(sil_pts).buffer(0)
    placed = []
    occupied = None
    warnings = []
    for muscle, pts, *opt in regions:
        opt = opt[0] if opt else {}
        blob = Polygon(G.catmull_closed(pts, n=opt.get("n", 8))).buffer(0)
        clipped = blob.intersection(sil)
        if occupied is not None:
            clipped = clipped.difference(occupied)
        clipped = clipped.buffer(-G.SEP).buffer(0)
        parts = _clean(clipped)
        if not parts:
            warnings.append(f"{muscle}: région vide après découpe")
            continue
        # garde la plus grande composante (les éclats < 4 u² sont supprimés)
        parts.sort(key=lambda p: -p.area)
        main = parts[0]
        if len(parts) > 1:
            warnings.append(f"{muscle}: {len(parts)} composantes, {[round(p.area) for p in parts[1:]]} u² ignorés")
        lost = 1 - main.area / max(blob.area, 1e-6)
        if lost > 0.55:
            warnings.append(f"{muscle}: {round(lost * 100)} % de la forme perdue à la découpe")
        placed.append((muscle, main))
        occupied = main if occupied is None else unary_union([occupied, main.buffer(G.SEP)])
    other = "g" if base_side == "d" else "d"
    out = []
    for muscle, poly in placed:
        out.append((muscle, base_side, poly))
        mirrored = Polygon([(2 * G.MID - x, y) for x, y in poly.exterior.coords])
        out.append((muscle, other, mirrored))
    covered = unary_union([p for _, _, p in out]).area
    stats = {"regions": len(placed), "couverture_silhouette_pct": round(100 * covered / sil.area, 1), "avertissements": warnings}
    return sil, out, stats


def path_d(poly, dx=0.0):
    coords = list(poly.exterior.coords)
    simp = Polygon(coords).simplify(0.25, preserve_topology=True)
    coords = list(simp.exterior.coords)
    d = "M" + " L".join(f"{round(x + dx, 1)} {round(y, 1)}" for x, y in coords[:-1]) + " Z"
    return d


def svg_view(name, sil, regions, lines, dx, debug=False):
    parts = [f'<g id="vue-{name}" transform="translate({dx} 0)">']
    parts.append(f'<path id="{name}-corps" class="corps" d="{path_d(sil)}" fill="currentColor" fill-opacity="0.18"/>')
    for i, (muscle, side, poly) in enumerate(regions):
        style = f' fill="hsl({(i * 47) % 360} 70% 55%)" fill-opacity="0.85"' if debug else ' fill="currentColor" fill-opacity="0.32"'
        parts.append(f'<path id="{name}-{muscle}-{side}" class="muscle" data-muscle="{muscle}" data-side="{side}" '
                     f'd="{path_d(poly)}"{style}><title>{KM.BY_ID[muscle]["nom"]} ({"droite" if side == "d" else "gauche"})</title></path>')
    for lid, pts in lines:
        d = "M" + " L".join(f"{x} {y}" for x, y in pts)
        parts.append(f'<path id="{name}-repere-{lid}" class="repere" d="{d}" fill="none" stroke="currentColor" stroke-opacity="0.35" stroke-width="1"/>')
        mir = [(2 * G.MID - x, y) for x, y in pts]
        if mir != pts:
            d2 = "M" + " L".join(f"{x} {y}" for x, y in mir)
            parts.append(f'<path id="{name}-repere-{lid}-2" class="repere" d="{d2}" fill="none" stroke="currentColor" stroke-opacity="0.35" stroke-width="1"/>')
    parts.append("</g>")
    return "\n".join(parts)


def build(out_dir, debug_html=None, planche_html=None):
    sil_f, reg_f, st_f = build_view(G.FACE_REGIONS, G.FACE_HALF, "d")
    sil_d, reg_d, st_d = build_view(G.DOS_REGIONS, G.DOS_HALF, "g")
    # vérification de complétude : chaque muscle superficiel a une région dans chacune de ses vues
    present = {"face": {m for m, _, _ in reg_f}, "dos": {m for m, _, _ in reg_d}}
    missing = []
    extra = []
    for m in KM.MUSCLES:
        if m["profondeur"] == "superficiel":
            for v in m["vues"]:
                if m["id"] not in present[v]:
                    missing.append((m["id"], v))
    for v, ids in present.items():
        for i in ids:
            mm = KM.BY_ID[i]
            if mm["profondeur"] != "superficiel" or v not in mm["vues"]:
                extra.append((i, v))
    profonds = {"face": [m["id"] for m in KM.MUSCLES if m["profondeur"] == "profond" and "face" in m["vues"]],
                "dos": [m["id"] for m in KM.MUSCLES if m["profondeur"] == "profond" and "dos" in m["vues"]]}

    def doc(debug):
        head = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 760" role="img" '
                'aria-label="Atlas musculaire Kalis Track : vue de face à gauche, vue de dos à droite ; '
                'une région par muscle superficiel, identifiée par son attribut data-muscle">\n'
                '<title>Atlas musculaire Kalis Track (v2, L9R)</title>\n'
                '<desc>Dessin original. Régions : path.muscle[data-muscle][data-side]. Muscles profonds (non dessinés) — face : '
                + ", ".join(profonds["face"]) + " ; dos : " + ", ".join(profonds["dos"]) + '.</desc>\n')
        body = svg_view("face", sil_f, reg_f, G.FACE_LINES, 0, debug) + "\n" + svg_view("dos", sil_d, reg_d, G.DOS_LINES, VIEW_W, debug)
        return head + body + "\n</svg>\n"

    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "atlas.svg"), "w", encoding="utf-8") as f:
        f.write(doc(False))
    if debug_html:
        labels = []
        for dx, regs in ((0, reg_f), (VIEW_W, reg_d)):
            for muscle, side, poly in regs:
                if side == ("d" if dx == 0 else "g"):
                    c = poly.representative_point()
                    labels.append(f'<text x="{round(c.x + dx, 1)}" y="{round(c.y, 1)}" font-size="5" text-anchor="middle" fill="#000">{muscle}</text>')
        svg = doc(True).replace("</svg>", "\n".join(labels) + "\n</svg>")
        html = ('<!doctype html><html><head><meta charset="utf-8"><style>body{margin:0;background:#fff;color:#222}'
                'svg{width:1800px;height:auto;display:block}</style></head><body>' + svg + "</body></html>")
        with open(debug_html, "w", encoding="utf-8") as f:
            f.write(html)

    if planche_html:
        # planche de contrôle : face, dos, numéros et légende des ids (superficiels), muscles profonds en texte
        sup = [m for m in KM.MUSCLES if m["profondeur"] == "superficiel"]
        num = {m["id"]: i + 1 for i, m in enumerate(sup)}
        labels = []
        for dx, regs in ((0, reg_f), (VIEW_W, reg_d)):
            for muscle, side, poly in regs:
                c = poly.representative_point()
                labels.append(f'<text x="{round(c.x + dx, 1)}" y="{round(c.y + 2, 1)}" font-size="5.5" font-family="sans-serif" '
                              f'text-anchor="middle" fill="#111">{num[muscle]}</text>')
        svg = doc(False).replace('fill="currentColor" fill-opacity="0.32"', 'fill="#A61717" fill-opacity="0.55"') \
            .replace('fill="currentColor" fill-opacity="0.18"', 'fill="#8A8A8A" fill-opacity="0.35"') \
            .replace("</svg>", "\n".join(labels) + "\n</svg>")
        col1 = [m for m in sup if num[m["id"]] <= 26]
        col2 = [m for m in sup if num[m["id"]] > 26]
        li = lambda ms: "".join(f'<li><b>{num[m["id"]]}</b> {m["nom"]} <code>{m["id"]}</code> <small>({"/".join(m["vues"])})</small></li>' for m in ms)
        prof = ", ".join(f'{m["nom"]} <code>{m["id"]}</code>' for m in KM.MUSCLES if m["profondeur"] == "profond")
        html = ('<!doctype html><html><head><meta charset="utf-8"><style>body{margin:0;padding:16px;background:#fff;color:#121212;'
                'font:12px/1.35 sans-serif}h1{font:700 20px sans-serif;margin:0 0 8px}.row{display:flex;gap:16px}svg{width:1000px;height:auto}'
                'ul{list-style:none;padding:0;margin:0;columns:1;font-size:11.5px}li{margin:0 0 2px}code{font-size:10.5px;color:#555}'
                '.leg{width:760px;display:flex;gap:12px}.leg ul{flex:1}p{max-width:1780px}</style></head><body>'
                '<h1>Atlas musculaire Kalis Track v2 — planche de contrôle (L9R)</h1>'
                '<div class="row">' + svg + '<div class="leg"><ul>' + li(col1) + '</ul><ul>' + li(col2) + '</ul></div></div>'
                '<p><b>Muscles profonds (listés en texte, non dessinés) :</b> ' + prof + '</p></body></html>')
        with open(planche_html, "w", encoding="utf-8") as f:
            f.write(html)

    muscles = []
    for m in KM.MUSCLES:
        regions = []
        for v in m["vues"]:
            if m["id"] in present[v]:
                regions += [f"{v}-{m['id']}-d", f"{v}-{m['id']}-g"]
        muscles.append({**m, "regions": regions})
    doc_m = {
        "version": "2.0.0", "generated": "2026-09-27",
        "description": "Taxonomie musculaire Kalis Track v2 : muscles et chefs utiles à l'entraînement, "
                       "groupe de compatibilité avec la carte musculaire actuelle (11 groupes), vues de l'atlas, profondeur.",
        "groupes_app": KM.GROUPES_APP,
        "alias": KM.ALIAS,
        "atlas": {"fichier": "atlas.svg", "viewBox": "0 0 600 760", "vues": {"face": {"x": 0, "largeur": 300}, "dos": {"x": 300, "largeur": 300}},
                  "selecteur_region": "path.muscle[data-muscle=<id>][data-side=d|g]",
                  "roles_couleur": {"corps": "neutre (currentColor atténué)", "primaire": "couleur dominante active (accent)",
                                    "secondaire": "même teinte atténuée (opacité 0,45)", "stabilisateur": "contour accent, sans remplissage"},
                  "muscles_profonds_par_vue": profonds},
        "muscles": muscles,
    }
    with open(os.path.join(out_dir, "muscles.json"), "w", encoding="utf-8") as f:
        json.dump(doc_m, f, ensure_ascii=False, indent=1)
    report = {"face": st_f, "dos": st_d, "manquants": missing, "hors_taxonomie": extra}
    return report


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    dbg = sys.argv[sys.argv.index("--debug") + 1] if "--debug" in sys.argv else None
    pl = sys.argv[sys.argv.index("--planche") + 1] if "--planche" in sys.argv else None
    rep = build(out, dbg, pl)
    print(json.dumps(rep, ensure_ascii=False, indent=1))
