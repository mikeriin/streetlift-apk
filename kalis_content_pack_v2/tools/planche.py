"""Planches de contrôle visuel : rend les images clés des gabarits avec le moteur de
référence (kt_pose.js, Chromium sans interface) et assemble une grille PNG.

Usage :
  python3 tools/planche.py gabarits <sortie.png> id1 id2 ...      (gabarits de biomeca.REG)
  python3 tools/planche.py exercices <poses.json> <exercises_v2.json> <sortie.png> id1 id2 ...
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import render_png  # noqa: E402

JS = os.path.join(HERE, "..", "renderer_reference", "kt_pose.js")


def html_for(items, cols=3, cell_w=560):
    """items : liste de {id, pose, muscles, titre, sous_titre}."""
    with open(JS, encoding="utf-8") as f:
        js = f.read()
    data = json.dumps(items, ensure_ascii=False)
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
body{{margin:0;padding:10px;background:#F4F4F4;color:#121212;font:12px/1.3 sans-serif}}
.grid{{display:grid;grid-template-columns:repeat({cols},{cell_w}px);gap:10px}}
.cell{{background:#fff;border:1px solid #ccc;padding:6px}}
.cell h3{{font-size:13px;margin:0 0 4px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}}
.cell .sub{{color:#555;font-size:11px;margin:0 0 4px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}}
.kt-strip{{display:flex;gap:3px}} .kt-kf{{margin:0;flex:1 1 0;min-width:0}} .kt-kf svg{{width:100%;height:auto;display:block;border:1px solid #eee}}
.kt-kf figcaption{{font-size:10px;text-align:center;color:#333}}
</style></head><body><div class="grid" id="g"></div>
<script>{js}</script>
<script>
var ITEMS = {data};
var g = document.getElementById("g");
ITEMS.forEach(function (it) {{
  var d = document.createElement("div"); d.className = "cell";
  d.innerHTML = "<h3>" + it.titre + "</h3><p class=sub>" + (it.sous_titre || "") + "</p>";
  var holder = document.createElement("div");
  var pose = it.pose || KTPose.fromPack(it.gabarit, it.entree);
  holder.innerHTML = KTPose.staticStrip(pose, {{accent: "rouge", mode: "clair", muscles: it.muscles || pose.muscles, label: it.id}});
  d.appendChild(holder); g.appendChild(d);
}});
</script></body></html>"""


def render_items(items, out_png, cols=4, cell_w=430):
    html = html_for(items, cols, cell_w)
    tmp = out_png + ".html"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(html)
    rows = (len(items) + cols - 1) // cols
    render_png.render(tmp, out_png, width=cols * (cell_w + 12) + 30, height=max(400, rows * 300))
    os.remove(tmp)


def main():
    mode = sys.argv[1]
    if mode == "gabarits":
        import biomeca as BM
        import pose_solver as PS
        out = sys.argv[2]
        ids = sys.argv[3:]
        items = []
        for i in ids:
            t = PS.build_sheet(BM.REG[i])
            res = ", ".join(f"{kf['residu']:.3f}" for kf in t["keyframes"])
            items.append({"id": i, "pose": t, "muscles": {}, "titre": i, "sous_titre": f"résidus {res} · t={[kf['angles_articulaires']['t'] for kf in t['keyframes']]}"})
        render_items(items, out)
    else:
        poses = json.load(open(sys.argv[2], encoding="utf-8"))
        exs = json.load(open(sys.argv[3], encoding="utf-8"))
        out = sys.argv[4]
        ids = sys.argv[5:]
        by_id = {e["id"]: e for e in exs["exercices"]}
        items = []
        for i in ids:
            e = by_id[i]
            pe = poses["exercices"].get(i)
            if not pe or not pe.get("gabarit"):
                continue
            items.append({"id": i, "gabarit": poses["gabarits"][pe["gabarit"]], "entree": pe, "titre": f"{e['nom']} ({i})",
                          "sous_titre": f"{pe['gabarit']} · {pe['statut']} · {', '.join(e['materiel'])} · P: {', '.join(e['muscles_primaires'][:4])}"})
        render_items(items, out)
    print(out)


if __name__ == "__main__":
    main()
