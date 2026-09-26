"""Assemble les pages autonomes : review_tool.html et renderer_reference/index.html.

Usage : python3 tools/build_html.py <dossier_pack> [--fragment chemin]
--fragment écrit aussi la version « fragment » (sans doctype) utilisée pour la publication
comme artefact claude.ai.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import validate as VAL  # noqa: E402

DOC_HEAD = ('<!doctype html><html lang="fr"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"></head><body>')
DOC_TAIL = "</body></html>\n"


def load(pack, name):
    with open(os.path.join(pack, name), encoding="utf-8") as f:
        return json.load(f)


def review_payload(pack):
    ex = load(pack, "exercises_v2.json")
    prog = load(pack, "progressions.json")
    poses = load(pack, "poses.json")
    mapping = load(pack, "mapping_v1_to_v2.json")
    slim = []
    for e in ex["exercices"]:
        d = {k: v for k, v in e.items() if k not in ("provenance", "pose")}
        slim.append(d)
    gab = {}
    for n, g in poses["gabarits"].items():
        gab[n] = {"vue": g["vue"], "boucle": g["boucle"], "accessoires": g["accessoires"],
                  "images_cles": [{k: kf[k] for k in ("label", "angles", "bassin", "anchor", "hold", "dur")} for kf in g["images_cles"]]}
    prio = [r[1] for r in VAL.priority_list(ex, prog, mapping)]
    return {"version": ex["version"], "exercices": slim, "vocabulaires": ex["vocabulaires"], "chaines": prog["chaines"],
            "poses": {"gabarits": gab, "exercices": poses["exercices"]}, "prioritaires": prio}


def build(pack, fragment_path=None):
    with open(os.path.join(HERE, "review_template.html"), encoding="utf-8") as f:
        tpl = f.read()
    with open(os.path.join(pack, "renderer_reference", "kt_pose.js"), encoding="utf-8") as f:
        js = f.read()
    data = json.dumps(review_payload(pack), ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    page = tpl.replace("/*__RENDERER__*/", js).replace("/*__DATA__*/null", data)
    with open(os.path.join(pack, "review_tool.html"), "w", encoding="utf-8") as f:
        f.write(DOC_HEAD + page + DOC_TAIL)
    if fragment_path:
        with open(fragment_path, "w", encoding="utf-8") as f:
            f.write(page)
    # moteur de référence : page de démonstration autonome
    with open(os.path.join(HERE, "renderer_template.html"), encoding="utf-8") as f:
        rtpl = f.read()
    poses = load(pack, "poses.json")
    ex = load(pack, "exercises_v2.json")
    names = {e["id"]: e["nom"] for e in ex["exercices"]}
    rdata = json.dumps({"poses": poses, "noms": names}, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    rpage = rtpl.replace("/*__RENDERER__*/", js).replace("/*__DATA__*/null", rdata)
    with open(os.path.join(pack, "renderer_reference", "index.html"), "w", encoding="utf-8") as f:
        f.write(DOC_HEAD + rpage + DOC_TAIL)


if __name__ == "__main__":
    frag = None
    if "--fragment" in sys.argv:
        frag = sys.argv[sys.argv.index("--fragment") + 1]
    build(sys.argv[1], frag)
