"""Assemble les pages autonomes du pack v2 :
  - review_tool.html : outil de relecture (fiche, atlas, animation, sources, arbres, relecture par exercice) ;
  - renderer_reference/index.html : page de démonstration du moteur (6 palettes × 2 modes, version statique).

Usage : python3 tools/build_html.py <dossier_pack> [--fragment chemin]
--fragment écrit aussi la version « fragment » (sans doctype, sans <html>/<head>/<body>) publiée comme artefact claude.ai.
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


def read(pack, name):
    with open(os.path.join(pack, name), encoding="utf-8") as f:
        return f.read()


def js_json(obj):
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")


def slim_gabarit(g, full=True):
    out = {"vue": g["vue"], "boucle": g["boucle"], "accessoires": g["accessoires"],
           "images_cles": [{k: kf[k] for k in ("label", "angles", "bassin", "anchor", "hold", "dur")} for kf in g["images_cles"]]}
    if full:
        out["fiche"] = g["fiche_biomecanique"]
        out["note"] = g.get("note")
        out["charge"] = g.get("charge")
        out["angles"] = [{"label": kf["label"], "a": kf["angles_articulaires"], "residu": kf.get("residu_contraintes")} for kf in g["images_cles"]]
        out["exceptions"] = g.get("exceptions_amplitude", {})
    return out


def review_payload(pack):
    ex = load(pack, "exercises_v2.json")
    prog = load(pack, "progressions.json")
    poses = load(pack, "poses.json")
    mapping = load(pack, "mapping_v1_to_v2.json")
    muscles = load(pack, "muscles.json")
    slim = []
    for e in ex["exercices"]:
        d = {k: v for k, v in e.items() if k not in ("provenance", "pose", "substitutions_elargies")}
        slim.append(d)
    gab = {n: slim_gabarit(g) for n, g in poses["gabarits"].items()}
    prio = [r[1] for r in VAL.priority_list(ex, prog, mapping)]
    return {"version": ex["version"], "schema": ex["schema"], "generated": ex["generated"], "exercices": slim,
            "vocabulaires": ex["vocabulaires"], "chaines": prog["chaines"], "aretes": prog["aretes"],
            "poses": {"gabarits": gab, "exercices": poses["exercices"], "statuts": poses["statuts"]},
            "muscles": muscles["muscles"], "groupes_app": muscles["groupes_app"], "prioritaires": prio}


CSS = r"""
:root{
  --bg:#F4F4F4;--surface:#FFFFFF;--surface2:#ECEBEA;--line:#DAD8D6;--text:#121212;--dim:#5E5B59;
  --accent:#8E1414;--accent-soft:rgba(142,20,20,.09);--ok:#2C7230;--ok-soft:rgba(44,114,48,.12);
  --warn:#9A5B00;--warn-soft:rgba(154,91,0,.13);--focus:#1F5FBF;--corps:#8A8A8A;
  --display:"Barlow Condensed","Arial Narrow",Arial,sans-serif;--body:"IBM Plex Sans",system-ui,-apple-system,"Segoe UI",sans-serif;
  --mono:"IBM Plex Mono",ui-monospace,Menlo,Consolas,monospace;
}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){color-scheme:dark;
  --bg:#121212;--surface:#1C1B1B;--surface2:#262424;--line:#363333;--text:#F2F0EF;--dim:#A19C99;
  --accent:#E85959;--accent-soft:rgba(232,89,89,.14);--ok:#64AA67;--ok-soft:rgba(100,170,103,.16);
  --warn:#E0A64A;--warn-soft:rgba(224,166,74,.16);--focus:#7FB0FF;}}
:root[data-theme="dark"]{color-scheme:dark;
  --bg:#121212;--surface:#1C1B1B;--surface2:#262424;--line:#363333;--text:#F2F0EF;--dim:#A19C99;
  --accent:#E85959;--accent-soft:rgba(232,89,89,.14);--ok:#64AA67;--ok-soft:rgba(100,170,103,.16);
  --warn:#E0A64A;--warn-soft:rgba(224,166,74,.16);--focus:#7FB0FF;}
*{box-sizing:border-box}
html,body{height:100%}
body{margin:0;background:var(--bg);color:var(--text);font:15px/1.45 var(--body);padding-block:0}
button,select,input,textarea{font:inherit;color:inherit}
a{color:var(--accent)}
:focus-visible{outline:2px solid var(--focus);outline-offset:2px}
h1,h2,h3{font-family:var(--display);text-wrap:balance;margin:0;font-weight:700;letter-spacing:.01em}
h1{font-size:26px;line-height:1}
h2{font-size:20px;text-transform:uppercase;letter-spacing:.06em;color:var(--dim);font-weight:600;margin-bottom:8px}
h3{font-size:18px}
.mono{font-family:var(--mono);font-size:12.5px}
.top{position:sticky;top:env(safe-area-inset-top,0px);z-index:5;background:var(--surface);border-bottom:1px solid var(--line);padding:10px 16px;display:flex;flex-wrap:wrap;gap:8px 16px;align-items:center}
.top .ver{font-family:var(--mono);font-size:12px;color:var(--dim)}
.pills{display:flex;flex-wrap:wrap;gap:6px;align-items:center;margin-left:auto}
.pill{font-family:var(--mono);font-size:12px;padding:3px 8px;border-radius:999px;background:var(--surface2);border:1px solid var(--line);white-space:nowrap}
.pill.ok{background:var(--ok-soft);color:var(--ok);border-color:transparent}
.pill.todo{background:var(--warn-soft);color:var(--warn);border-color:transparent}
.pill.acc{background:var(--accent-soft);color:var(--accent);border-color:transparent}
.sync{font-size:12.5px;color:var(--dim);flex-basis:100%}
.filters{padding:10px 16px;display:flex;flex-wrap:wrap;gap:8px;align-items:center;border-bottom:1px solid var(--line);background:var(--surface)}
.filters input[type=search]{flex:1 1 180px;min-width:0;padding:7px 10px;border:1px solid var(--line);border-radius:6px;background:var(--bg)}
.filters select{padding:7px 8px;border:1px solid var(--line);border-radius:6px;background:var(--bg);max-width:100%}
.filters label.chk{display:inline-flex;gap:6px;align-items:center;font-size:13.5px}
.btn{padding:7px 12px;border:1px solid var(--line);border-radius:6px;background:var(--surface2);cursor:pointer}
.btn.primary{background:var(--accent);color:#fff;border-color:var(--accent)}
.btn.ok{background:var(--ok);color:#fff;border-color:var(--ok)}
.btn.warn{background:var(--warn);color:#fff;border-color:var(--warn)}
.btn:disabled{opacity:.5;cursor:default}
.layout{display:grid;grid-template-columns:minmax(240px,320px) 1fr;min-height:0}
.list{border-right:1px solid var(--line);background:var(--surface);overflow:auto;max-height:calc(100vh - 130px);position:sticky;top:0}
.list ul{list-style:none;margin:0;padding:0}
.list li{border-bottom:1px solid var(--line)}
.list button{width:100%;text-align:left;background:none;border:0;padding:9px 12px;cursor:pointer;display:grid;gap:3px}
.list button:hover{background:var(--surface2)}
.list li.sel button{background:var(--accent-soft);box-shadow:inset 3px 0 0 var(--accent)}
.list .nm{font-weight:500;line-height:1.25}
.list .meta{display:flex;flex-wrap:wrap;gap:4px;font-family:var(--mono);font-size:11px;color:var(--dim)}
.tag{padding:1px 6px;border-radius:4px;background:var(--surface2);border:1px solid var(--line)}
.tag.v{background:var(--ok-soft);color:var(--ok);border-color:transparent}
.tag.c{background:var(--warn-soft);color:var(--warn);border-color:transparent}
.tag.ind{background:var(--accent-soft);color:var(--accent);border-color:transparent}
.tag.sta{border-style:dashed}
.count{padding:8px 12px;font-size:12.5px;color:var(--dim);border-bottom:1px solid var(--line)}
.detail{padding:16px;min-width:0;display:grid;gap:18px;align-content:start;max-width:1100px}
.card{background:var(--surface);border:1px solid var(--line);border-radius:8px;padding:14px 16px;min-width:0}
.card.review{border-color:var(--accent)}
.head .chips{display:flex;flex-wrap:wrap;gap:6px;margin-top:8px}
.head .alias{color:var(--dim);font-size:13.5px;margin-top:4px}
.chip{font-size:12.5px;padding:3px 8px;border-radius:999px;background:var(--surface2);border:1px solid var(--line)}
.chip.ind{background:var(--accent-soft);color:var(--accent);border-color:transparent}
.chip.sta{background:var(--warn-soft);color:var(--warn);border-color:transparent}
.chip.dispo{background:var(--ok-soft);color:var(--ok);border-color:transparent}
.demo-wrap{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:14px;align-items:start}
.demo-wrap>div{min-width:0}
.player svg{width:100%;height:auto;display:block;border-radius:6px;max-height:420px}
.ctl{display:flex;flex-wrap:wrap;gap:6px;align-items:center;margin-top:8px}
.ctl select{padding:5px 6px;border:1px solid var(--line);border-radius:6px;background:var(--bg)}
.kt-strip{display:flex;gap:6px;overflow-x:auto;padding-bottom:4px}
.kt-kf{margin:0;flex:0 0 auto;width:min(46%,220px)}
.kt-kf svg{width:100%;height:auto;display:block;border-radius:4px}
.kt-kf figcaption{font-size:11.5px;color:var(--dim);text-align:center;margin-top:2px}
.motif{padding:10px 12px;border-radius:6px;background:var(--accent-soft);color:var(--accent);font-size:14px}
.atlas-wrap{display:grid;grid-template-columns:minmax(0,1.1fr) minmax(0,1fr);gap:14px;align-items:start}
.atlas-wrap>div{min-width:0}
.atlas svg{width:100%;height:auto;display:block;color:var(--corps)}
.atlas .muscle{transition:fill .15s}
.atlas .muscle.prim{fill:var(--accent);fill-opacity:1}
.atlas .muscle.sec{fill:var(--accent);fill-opacity:.42}
.atlas .muscle.stab{fill-opacity:.32;stroke:var(--accent);stroke-width:2.2;stroke-dasharray:4 3}
.atlas .muscle.eti{fill-opacity:.32;stroke:var(--focus);stroke-width:2}
.legend{display:flex;flex-wrap:wrap;gap:10px;font-size:12.5px;color:var(--dim);margin-top:6px}
.legend i{display:inline-block;width:14px;height:14px;border-radius:3px;vertical-align:-2px;margin-right:4px;background:var(--corps);opacity:.6}
.legend i.p{background:var(--accent);opacity:1}.legend i.s{background:var(--accent);opacity:.42}
.legend i.t{border:2px dashed var(--accent);background:transparent;opacity:1}.legend i.e{border:2px solid var(--focus);background:transparent;opacity:1}
.mlist{display:grid;gap:8px}
.mlist dt{font-family:var(--mono);font-size:11.5px;text-transform:uppercase;letter-spacing:.06em;color:var(--dim)}
.mlist dd{margin:2px 0 0}
.mlist .deep{color:var(--dim)}
table{border-collapse:collapse;width:100%;font-size:13.5px}
th,td{text-align:left;padding:5px 8px;border-bottom:1px solid var(--line);vertical-align:top}
th{font-family:var(--mono);font-size:11.5px;text-transform:uppercase;letter-spacing:.05em;color:var(--dim);font-weight:500}
.tbl{overflow-x:auto}
.kv{display:grid;grid-template-columns:max-content 1fr;gap:4px 12px;font-size:14px}
.kv dt{color:var(--dim)}
.kv dd{margin:0;min-width:0}
ul.plain{margin:0;padding-left:18px}
.cols{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:14px}
.cst{display:flex;flex-wrap:wrap;gap:6px}
.cst span{font-size:12px;padding:2px 7px;border-radius:4px;border:1px solid var(--line);font-family:var(--mono)}
.cst span[data-n="2"]{border-color:var(--warn);color:var(--warn)}.cst span[data-n="3"]{border-color:var(--accent);color:var(--accent);font-weight:600}
.chain{display:flex;flex-wrap:wrap;gap:6px;align-items:center;margin:6px 0 10px}
.chain .step{padding:4px 8px;border:1px solid var(--line);border-radius:6px;background:var(--surface2);font-size:13px;cursor:pointer}
.chain .step.cur{background:var(--accent);color:#fff;border-color:var(--accent)}
.chain .arrow{color:var(--dim);font-size:12px}
.chain .seuil{font-size:11px;color:var(--dim);display:block}
.src li{margin-bottom:4px;word-break:break-word}
.src .t{font-family:var(--mono);font-size:11px;color:var(--dim);margin-right:4px}
.review .row{display:flex;flex-wrap:wrap;gap:8px;align-items:center;margin-top:8px}
.review textarea{width:100%;min-height:72px;padding:8px;border:1px solid var(--line);border-radius:6px;background:var(--bg);resize:vertical}
.review select{padding:7px 8px;border:1px solid var(--line);border-radius:6px;background:var(--bg)}
.review .cur{font-size:14px;margin-top:6px}
.review .msg{font-size:13px;color:var(--dim);margin-top:6px;min-height:1.2em}
.export{margin-top:8px}
.export textarea{width:100%;min-height:120px;font-family:var(--mono);font-size:11.5px}
.empty{padding:40px 16px;color:var(--dim);text-align:center}
.small{font-size:12.5px;color:var(--dim)}
.mobile-nav{display:none}
@media (max-width:820px){
  .layout{grid-template-columns:1fr}
  .list{position:static;max-height:none;border-right:0;border-bottom:1px solid var(--line)}
  .list[hidden]{display:none}
  .mobile-nav{display:flex;gap:8px;padding:8px 16px;border-bottom:1px solid var(--line);background:var(--surface);align-items:center}
  .demo-wrap,.atlas-wrap{grid-template-columns:1fr}
  .detail{padding:12px 16px}
  h1{font-size:22px}
}
@media (prefers-reduced-motion:reduce){.atlas .muscle{transition:none}}
"""

JS = r"""
(function(){
  "use strict";
  var D = JSON.parse(document.getElementById("kt-data").textContent);
  var EX = D.exercices, BY = {}; EX.forEach(function(e){ BY[e.id] = e; });
  var V = D.vocabulaires, POSES = D.poses, CH = D.chaines, PRIO = {}; D.prioritaires.forEach(function(i, k){ PRIO[i] = k + 1; });
  var MUS = {}; D.muscles.forEach(function(m){ MUS[m.id] = m; });
  var CHAIN_OF = {}; CH.forEach(function(c){ c.etapes.forEach(function(s){ (CHAIN_OF[s.id] = CHAIN_OF[s.id] || []).push(c); }); });
  var CATS = ["données", "muscles", "difficulté", "progression", "animation", "vocabulaire", "autre"];
  var LS = "kt-l9r-relectures-v2", LSF = "kt-l9r-filtres";
  function lsGet(k){ try { return localStorage.getItem(k); } catch (e) { return null; } }
  function lsSet(k, v){ try { localStorage.setItem(k, v); } catch (e) {} }
  var reviews = {}; try { reviews = JSON.parse(lsGet(LS) || "{}") || {}; } catch (e) { reviews = {}; }
  var state = { q: "", type: "", lieu: "", relu: "", demo: "", prio: false, sel: null, accent: "rouge", mode: (matchMedia("(prefers-color-scheme: dark)").matches ? "sombre" : "clair"), fixe: matchMedia("(prefers-reduced-motion: reduce)").matches, tab: "ex" };
  try { Object.assign(state, JSON.parse(lsGet(LSF) || "{}") || {}); } catch (e) {}
  var db = null, dl = null, storeMode = "local", player = null;
  function $(id){ return document.getElementById(id); }
  function esc(s){ return String(s == null ? "" : s).replace(/[&<>"]/g, function(c){ return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]; }); }
  function label(voc, k){ var v = V[voc]; if (!v) return k; var x = v[k]; if (x == null) return k; return typeof x === "string" ? x : (x.libelle || x.nom || k); }
  function mname(id){ var m = MUS[id]; return m ? m.nom : id; }
  function statusOf(id){ var r = reviews[id]; return r ? r.statut : ""; }
  function demoOf(id){ var p = POSES.exercices[id]; return p ? p.statut : "indisponible"; }

  /* ---------- filtres et liste ---------- */
  function filtered(){
    var q = state.q.trim().toLowerCase();
    return EX.filter(function(e){
      if (state.type && e.type_mouvement !== state.type) return false;
      if (state.lieu && e.lieux.indexOf(state.lieu) < 0) return false;
      if (state.relu === "non_relu" && statusOf(e.id)) return false;
      if (state.relu === "valide" && statusOf(e.id) !== "valide") return false;
      if (state.relu === "a_corriger" && statusOf(e.id) !== "a_corriger") return false;
      if (state.demo && demoOf(e.id) !== state.demo) return false;
      if (state.prio && !PRIO[e.id]) return false;
      if (q) { var hay = (e.nom + " " + e.id + " " + (e.alias || []).join(" ") + " " + e.famille).toLowerCase(); if (hay.indexOf(q) < 0) return false; }
      return true;
    }).sort(function(a, b){ var pa = PRIO[a.id] || 9999, pb = PRIO[b.id] || 9999; return pa - pb || a.nom.localeCompare(b.nom, "fr"); });
  }
  function renderList(){
    var rows = filtered(), ul = $("lst"), out = [];
    $("cnt").textContent = rows.length + " exercice" + (rows.length > 1 ? "s" : "") + " sur " + EX.length;
    rows.forEach(function(e){
      var s = statusOf(e.id), d = demoOf(e.id);
      out.push('<li' + (e.id === state.sel ? ' class="sel"' : "") + '><button type="button" data-id="' + esc(e.id) + '"><span class="nm">' + esc(e.nom) + '</span><span class="meta">' +
        (PRIO[e.id] ? '<span class="tag">P' + PRIO[e.id] + '</span>' : "") + '<span class="tag">niv ' + e.difficulte + '</span><span class="tag">' + esc(label("types_mouvement", e.type_mouvement)) + '</span>' +
        (d === "indisponible" ? '<span class="tag ind">sans démo</span>' : d === "statique" ? '<span class="tag sta">statique</span>' : "") +
        (s === "valide" ? '<span class="tag v">validé</span>' : s === "a_corriger" ? '<span class="tag c">à corriger</span>' : '<span class="tag">non relu</span>') + "</span></button></li>");
    });
    ul.innerHTML = out.join("") || '<li class="empty">Aucun exercice ne correspond aux filtres.</li>';
  }
  function renderProgress(){
    var v = 0, c = 0, ind = 0;
    EX.forEach(function(e){ var s = statusOf(e.id); if (s === "valide") v++; else if (s === "a_corriger") c++; if (demoOf(e.id) === "indisponible") ind++; });
    $("pills").innerHTML = '<span class="pill ok">validés ' + v + '</span><span class="pill todo">à corriger ' + c + '</span><span class="pill">non relus ' + (EX.length - v - c) + '</span><span class="pill acc">sans démo ' + ind + '</span>';
    $("sync").textContent = storeMode === "partage" ? "Base partagée : les relectures sont enregistrées en ligne (collection relectures_v2)." : "Mode local : les relectures restent dans ce navigateur ; exporte-les avant de fermer.";
  }

  /* ---------- fiche ---------- */
  function chips(e){
    var d = demoOf(e.id), p = POSES.exercices[e.id] || {};
    var c = ['<span class="chip">' + esc(label("types_mouvement", e.type_mouvement)) + '</span>', '<span class="chip">difficulté ' + e.difficulte + '/10</span>',
      '<span class="chip">' + esc(label("modes_charge", e.mode_charge)) + '</span>', '<span class="chip">' + esc(e.mesure) + (e.unilateral ? " · unilatéral" : "") + '</span>',
      '<span class="chip">vue ' + esc(e.vue) + ' · plan ' + esc(e.plan) + '</span>', '<span class="chip">' + esc(e.origine) + (e.role !== "exercice" ? " · " + esc(e.role) : "") + (e.generateur ? "" : " · hors générateur") + '</span>',
      '<span class="chip ' + (d === "indisponible" ? "ind" : d === "statique" ? "sta" : "dispo") + '">démonstration ' + d + '</span>'];
    if (PRIO[e.id]) c.push('<span class="chip">priorité ' + PRIO[e.id] + '/150</span>');
    if (e.doublon_de) c.push('<span class="chip">doublon de <a href="#' + esc(e.doublon_de) + '">' + esc(BY[e.doublon_de].nom) + '</a></span>');
    if (e.variante_de) c.push('<span class="chip">variante de <a href="#' + esc(e.variante_de) + '">' + esc(BY[e.variante_de].nom) + '</a></span>');
    return c.join("");
  }
  function musclesHtml(e){
    function li(ids){ return ids.length ? ids.map(function(m){ var x = MUS[m]; return '<span' + (x && x.profondeur === "profond" ? ' class="deep" title="muscle profond : listé en texte"' : "") + '>' + esc(mname(m)) + (x && x.profondeur === "profond" ? " (profond)" : "") + '</span>'; }).join(", ") : "—"; }
    return '<dl class="mlist"><div><dt>Primaires</dt><dd>' + li(e.muscles_primaires) + '</dd></div><div><dt>Secondaires</dt><dd>' + li(e.muscles_secondaires) + '</dd></div>' +
      '<div><dt>Stabilisateurs</dt><dd>' + li(e.muscles_stabilisateurs || []) + '</dd></div>' + ((e.muscles_etires || []).length ? '<div><dt>Étirés</dt><dd>' + li(e.muscles_etires) + '</dd></div>' : "") + "</dl>";
  }
  function atlasHtml(e){
    var svg = $("atlas-src").innerHTML;
    return '<div class="atlas" id="atlas">' + svg + '</div><div class="legend"><span><i class="p"></i>primaire</span><span><i class="s"></i>secondaire</span><span><i class="t"></i>stabilisateur</span><span><i class="e"></i>étiré</span><span><i></i>autres muscles</span></div>';
  }
  function paintAtlas(e){
    var root = $("atlas"); if (!root) return;
    var cls = {};
    (e.muscles_etires || []).forEach(function(m){ cls[m] = "eti"; });
    (e.muscles_stabilisateurs || []).forEach(function(m){ cls[m] = "stab"; });
    e.muscles_secondaires.forEach(function(m){ cls[m] = "sec"; });
    e.muscles_primaires.forEach(function(m){ cls[m] = "prim"; });
    var nodes = root.querySelectorAll("path.muscle");
    for (var i = 0; i < nodes.length; i++) { var n = nodes[i], m = n.getAttribute("data-muscle"); n.setAttribute("class", "muscle" + (cls[m] ? " " + cls[m] : "")); }
  }
  function ficheHtml(g, p){
    if (!g) return "";
    var f = g.fiche || {}, rows = (f.phases || []).map(function(ph){
      function ang(o){ return Object.keys(o || {}).map(function(k){ return k + " " + o[k] + "°"; }).join(", ") || "—"; }
      return "<tr><td>" + esc(ph.nom) + "</td><td>" + esc((ph.articulations || []).join(", ")) + "</td><td>" + esc(ang(ph.angles_debut)) + " → " + esc(ang(ph.angles_fin)) + "</td><td>" + esc(ph.texte || "") + "</td></tr>";
    }).join("");
    var kf = (g.angles || []).map(function(k){ var a = k.a || {}; var keys = ["t", "hanche_d", "genou_d", "cheville_d", "epaule_d", "coude_d"]; return "<tr><td>" + esc(k.label) + "</td>" + keys.map(function(x){ return "<td>" + (a[x] == null ? "—" : Math.round(a[x])) + "</td>"; }).join("") + "</tr>"; }).join("");
    return '<div class="tbl"><table><thead><tr><th>Phase</th><th>Articulations motrices</th><th>Angles début → fin</th><th>Repère</th></tr></thead><tbody>' + rows + '</tbody></table></div>' +
      '<dl class="kv" style="margin-top:10px"><dt>Prise</dt><dd>' + esc(f.prise || "—") + '</dd><dt>Placement</dt><dd>' + esc(f.placement || "—") + '</dd><dt>Contacts</dt><dd>' + esc(f.contacts_texte || "—") + '</dd><dt>Trajectoire</dt><dd>' + esc(f.trajectoire_charge || "—") + '</dd><dt>Tempo</dt><dd>' + esc(f.tempo || "—") + '</dd>' +
      (g.charge ? '<dt>Charge</dt><dd>' + esc(g.charge) + '</dd>' : "") + (g.note ? '<dt>Note</dt><dd>' + esc(g.note) + '</dd>' : "") + (p && p.retirer && p.retirer.length ? '<dt>Accessoires retirés</dt><dd>' + esc(p.retirer.join(", ")) + '</dd>' : "") + '</dl>' +
      '<details style="margin-top:8px"><summary class="small">Angles articulaires calculés par image clé (degrés, côté droit)</summary><div class="tbl"><table><thead><tr><th>Image</th><th>tronc</th><th>hanche</th><th>genou</th><th>cheville</th><th>épaule</th><th>coude</th></tr></thead><tbody>' + kf + '</tbody></table></div></details>';
  }
  function chainsHtml(e){
    var cs = CHAIN_OF[e.id] || [], out = [];
    cs.forEach(function(c){
      out.push('<h3>' + esc(c.titre) + '</h3><div class="chain">' + c.etapes.map(function(s, i){
        var x = BY[s.id]; return '<span class="step' + (s.id === e.id ? " cur" : "") + '" data-go="' + esc(s.id) + '" role="link" tabindex="0">' + esc(x ? x.nom : s.id) + ' <span class="small">(' + (x ? x.difficulte : "?") + ')</span>' + (s.seuil_passage ? '<span class="seuil">→ ' + esc(s.seuil_passage.texte) + '</span>' : "") + '</span>' + (i < c.etapes.length - 1 ? '<span class="arrow">▸</span>' : "");
      }).join("") + "</div>");
    });
    function links(ids){ return ids.length ? ids.map(function(i){ return '<a href="#' + esc(i) + '">' + esc(BY[i] ? BY[i].nom : i) + '</a>'; }).join(", ") : "—"; }
    out.push('<dl class="kv"><dt>Prérequis</dt><dd>' + ((e.prerequis || []).length ? e.prerequis.map(function(r){ return '<a href="#' + esc(r.id) + '">' + esc(BY[r.id] ? BY[r.id].nom : r.id) + '</a> (' + esc(r.seuil && r.seuil.texte || "") + ')'; }).join(" ; ") : "—") + '</dd><dt>Progressions</dt><dd>' + links(e.progressions || []) + '</dd><dt>Régressions</dt><dd>' + links(e.regressions || []) + '</dd></dl>');
    return out.join("");
  }
  function sourcesHtml(e){
    var m = e.sources_meta || {};
    return '<ul class="plain src">' + (e.sources || []).map(function(s){ return '<li><span class="t">' + esc(s.type || "") + '</span><a href="' + esc(s.url) + '" target="_blank" rel="noopener">' + esc(s.entree || s.url) + '</a> <span class="small">(' + esc(s.consulte_le) + ')</span></li>'; }).join("") + '</ul>' +
      '<dl class="kv" style="margin-top:8px"><dt>Archétype</dt><dd class="mono">' + esc(m.archetype || e.famille) + '</dd><dt>Sources concordantes</dt><dd>' + (m.nb_sources_concordantes != null ? m.nb_sources_concordantes : "—") + (m.surcharge_exercice ? " · muscles surchargés pour cet exercice" : "") + '</dd>' +
      (m.desaccord ? '<dt>Désaccord</dt><dd>' + esc(m.desaccord) + '</dd>' : "") + (m.note_concordance ? '<dt>Concordance</dt><dd>' + esc(m.note_concordance) + '</dd>' : "") + (m.difficulte_reference ? '<dt>Niveau de référence</dt><dd>' + esc(m.difficulte_reference) + '</dd>' : "") + '<dt>Stabilisateurs</dt><dd>' + esc(m.stabilisateurs_origine === "raisonnement" ? "déduits par raisonnement anatomique" : "d'après les sources") + '</dd></dl>';
  }
  function consignesHtml(e){
    var zones = e.contrainte_articulaire || {};
    return '<div class="cols"><div><h3>Points clés</h3><ul class="plain">' + e.points_cles.map(function(x){ return "<li>" + esc(x) + "</li>"; }).join("") + '</ul></div>' +
      '<div><h3>Erreurs fréquentes</h3><ul class="plain">' + e.erreurs_frequentes.map(function(x){ return "<li>" + esc(x) + "</li>"; }).join("") + '</ul><h3 style="margin-top:8px">Respiration</h3><p style="margin:2px 0">' + esc(e.respiration) + '</p></div>' +
      '<div><h3>Précautions</h3><ul class="plain">' + (e.precautions.length ? e.precautions.map(function(x){ return "<li><b>" + esc(x) + "</b> : " + esc(label("precautions", x)) + "</li>"; }).join("") : "<li>—</li>") + '</ul></div>' +
      '<div><h3>Contrainte articulaire (0–3)</h3><div class="cst">' + Object.keys(zones).map(function(z){ return '<span data-n="' + zones[z] + '">' + esc(label("zones", z)) + ' ' + zones[z] + '</span>'; }).join("") + '</div>' +
      '<h3 style="margin-top:8px">Matériel et lieux</h3><p style="margin:2px 0">' + esc(e.materiel.map(function(m){ return label("materiel", m); }).join(", ")) + '<br><span class="small">' + esc(e.lieux.map(function(l){ return label("lieux", l); }).join(" · ")) + '</span></p>' +
      (e.methodes && e.methodes.length ? '<p class="small">Méthodes : ' + esc(e.methodes.join(", ")) + '</p>' : "") + '</div></div>' +
      '<h3 style="margin-top:10px">Substitutions par lieu</h3><dl class="kv">' + Object.keys(e.substitutions || {}).map(function(l){ var ids = e.substitutions[l]; return '<dt>' + esc(label("lieux", l)) + '</dt><dd>' + (ids.length ? ids.map(function(i){ return '<a href="#' + esc(i) + '">' + esc(BY[i] ? BY[i].nom : i) + '</a>'; }).join(", ") : "—") + '</dd>'; }).join("") + '</dl>' +
      (e.non_conformites && e.non_conformites.length ? '<p class="small"><b>Non-conformités v1 :</b> ' + esc(e.non_conformites.join(" ")) + '</p>' : "");
  }
  function reviewHtml(e){
    var r = reviews[e.id];
    return '<h2>Relecture</h2><div class="cur">' + (r ? (r.statut === "valide" ? '<span class="tag v">validé</span>' : '<span class="tag c">à corriger</span>') + (r.categorie ? ' · ' + esc(r.categorie) : "") + (r.commentaire ? ' — ' + esc(r.commentaire) : "") + ' <span class="small">(' + esc((r.maj || "").slice(0, 16).replace("T", " ")) + ')</span>' : '<span class="tag">non relu</span>') + '</div>' +
      '<div class="row"><label for="rcat" class="small">Catégorie</label><select id="rcat">' + CATS.map(function(c){ return '<option' + (r && r.categorie === c ? " selected" : "") + '>' + c + '</option>'; }).join("") + '</select></div>' +
      '<textarea id="rcom" placeholder="Commentaire (ce qui est faux, ce qu\'il faudrait)">' + esc(r ? r.commentaire : "") + '</textarea>' +
      '<div class="row"><button type="button" class="btn ok" id="rok">Valider</button><button type="button" class="btn warn" id="rko">À corriger</button><button type="button" class="btn" id="rclr"' + (r ? "" : " disabled") + '>Effacer</button><button type="button" class="btn" id="rnext">Suivant non relu ▸</button></div><div class="msg" id="rmsg"></div>';
  }
  function renderDetail(){
    var e = BY[state.sel];
    if (player) { player.destroy(); player = null; }
    if (!e) { $("det").innerHTML = '<div class="empty">Choisis un exercice dans la liste.</div>'; return; }
    var p = POSES.exercices[e.id] || { statut: "indisponible", motif: "aucune entrée de pose" }, g = p.gabarit ? POSES.gabarits[p.gabarit] : null;
    var demo;
    if (p.statut === "indisponible" || !g) {
      demo = '<div class="motif">Démonstration indisponible : ' + esc(p.motif || "") + '. L\'application affichera l\'atlas et les consignes.</div>';
    } else {
      demo = '<div class="demo-wrap"><div><div class="player" id="player"></div><div class="ctl">' +
        '<button type="button" class="btn" id="pplay">' + (state.fixe ? "Images fixes" : "Lecture") + '</button><select id="pacc" aria-label="Couleur dominante">' + Object.keys(KTPose.ACCENTS).map(function(k){ return '<option value="' + k + '"' + (k === state.accent ? " selected" : "") + '>' + esc(KTPose.ACCENTS[k].label) + '</option>'; }).join("") + '</select>' +
        '<select id="pmode" aria-label="Mode"><option value="sombre"' + (state.mode === "sombre" ? " selected" : "") + '>sombre</option><option value="clair"' + (state.mode === "clair" ? " selected" : "") + '>clair</option></select>' +
        '<label class="small" style="display:inline-flex;gap:4px;align-items:center"><input type="checkbox" id="pfixe"' + (state.fixe ? " checked" : "") + '> réduction des animations</label></div>' +
        (p.statut === "statique" ? '<p class="motif" style="margin-top:8px">Position de départ seulement : ' + esc(p.motif || "") + '</p>' : "") +
        '<p class="small">Gabarit <span class="mono">' + esc(p.gabarit) + '</span> · boucle ' + esc(g.boucle) + ' · contrôles automatiques : ' + esc(p.controles_automatiques || "ok") + '</p></div>' +
        '<div><h3>Images clés</h3><div id="strip"></div></div></div>';
    }
    $("det").innerHTML =
      '<div class="card head"><h1>' + esc(e.nom) + '</h1><div class="alias"><span class="mono">' + esc(e.id) + '</span>' + (e.alias && e.alias.length ? ' · ' + esc(e.alias.join(" · ")) : "") + '</div><div class="chips">' + chips(e) + '</div></div>' +
      '<div class="card review" id="revcard">' + reviewHtml(e) + '</div>' +
      '<div class="card"><h2>Démonstration</h2>' + demo + '</div>' +
      '<div class="card"><h2>Muscles</h2><div class="atlas-wrap"><div>' + atlasHtml(e) + '</div><div>' + musclesHtml(e) + '</div></div></div>' +
      (g ? '<div class="card"><h2>Fiche biomécanique</h2>' + ficheHtml(g, p) + '</div>' : "") +
      '<div class="card"><h2>Consignes et données</h2>' + consignesHtml(e) + '</div>' +
      '<div class="card"><h2>Progression</h2>' + chainsHtml(e) + '</div>' +
      '<div class="card"><h2>Sources consultées</h2>' + sourcesHtml(e) + '</div>';
    paintAtlas(e);
    if (g && p.statut !== "indisponible") {
      var pose = KTPose.fromPack(g, p), opts = { accent: state.accent, mode: state.mode, muscles: p.muscles, label: e.nom, reduceMotion: state.fixe || p.statut === "statique" };
      player = new KTPose.Player($("player"), pose, opts);
      if (!opts.reduceMotion) player.play();
      $("strip").innerHTML = KTPose.staticStrip(pose, { accent: state.accent, mode: state.mode, muscles: p.muscles, label: e.nom });
      $("pplay").onclick = function(){ if (player.opts.reduceMotion) return; if (player.playing) { player.pause(); this.textContent = "Lecture"; } else { player.play(); this.textContent = "Pause"; } };
      if (!opts.reduceMotion) $("pplay").textContent = "Pause";
      $("pacc").onchange = function(){ state.accent = this.value; saveF(); player.set({ accent: state.accent }); $("strip").innerHTML = KTPose.staticStrip(pose, { accent: state.accent, mode: state.mode, muscles: p.muscles, label: e.nom }); };
      $("pmode").onchange = function(){ state.mode = this.value; saveF(); player.set({ mode: state.mode }); $("strip").innerHTML = KTPose.staticStrip(pose, { accent: state.accent, mode: state.mode, muscles: p.muscles, label: e.nom }); };
      $("pfixe").onchange = function(){ state.fixe = this.checked; saveF(); player.pause(); player.set({ reduceMotion: state.fixe || p.statut === "statique" }); if (!player.opts.reduceMotion) { player.play(); $("pplay").textContent = "Pause"; } else $("pplay").textContent = "Images fixes"; };
    }
    $("rok").onclick = function(){ setReview(e.id, "valide"); };
    $("rko").onclick = function(){ setReview(e.id, "a_corriger"); };
    $("rclr").onclick = function(){ setReview(e.id, null); };
    $("rnext").onclick = function(){ var rows = filtered(), i = rows.findIndex(function(x){ return x.id === e.id; }); for (var k = 1; k <= rows.length; k++) { var c = rows[(i + k) % rows.length]; if (!statusOf(c.id)) { go(c.id); return; } } $("rmsg").textContent = "Tout est relu dans cette sélection."; };
    var steps = $("det").querySelectorAll("[data-go]");
    for (var i = 0; i < steps.length; i++) steps[i].addEventListener("click", function(){ go(this.getAttribute("data-go")); });
  }
  function saveF(){ lsSet(LSF, JSON.stringify({ accent: state.accent, mode: state.mode, fixe: state.fixe, prio: state.prio })); }
  function go(id){ if (!BY[id]) return; state.sel = id; if (location.hash !== "#" + id) history.replaceState(null, "", "#" + id); renderList(); renderDetail(); if (matchMedia("(max-width:820px)").matches) { $("lstwrap").hidden = true; $("tgl").textContent = "Afficher la liste"; window.scrollTo(0, 0); } }

  /* ---------- relectures ---------- */
  function setReview(id, statut){
    if (statut) reviews[id] = { statut: statut, categorie: $("rcat").value, commentaire: $("rcom").value.trim(), maj: new Date().toISOString() };
    else delete reviews[id];
    lsSet(LS, JSON.stringify(reviews));
    persist(id);
    renderProgress(); renderList();
    $("revcard").innerHTML = reviewHtml(BY[id]);
    $("rok").onclick = function(){ setReview(id, "valide"); }; $("rko").onclick = function(){ setReview(id, "a_corriger"); }; $("rclr").onclick = function(){ setReview(id, null); };
    $("rnext").onclick = function(){ var rows = filtered(), i = rows.findIndex(function(x){ return x.id === id; }); for (var k = 1; k <= rows.length; k++) { var c = rows[(i + k) % rows.length]; if (!statusOf(c.id)) { go(c.id); return; } } $("rmsg").textContent = "Tout est relu dans cette sélection."; };
    $("rmsg").textContent = statut ? (statut === "valide" ? "Validé." : "Marqué à corriger.") + (storeMode === "partage" ? " Enregistré dans la base partagée." : " Enregistré dans ce navigateur ; pense à exporter.") : "Relecture effacée.";
  }
  var pending = Promise.resolve();
  function persist(id){
    if (!db) return;
    var r = reviews[id], ref = db.collection("relectures_v2").doc(id);
    pending = pending.then(function(){
      return r ? ref.set({ cible: "exercice", id: id, nom: BY[id] ? BY[id].nom : id, statut: r.statut, categorie: r.categorie || "", commentaire: r.commentaire || "", maj: r.maj, version_pack: D.version }) : ref.delete();
    }).catch(function(e){ var m = $("rmsg"); if (m) m.textContent = "Échec d'enregistrement partagé (" + (e && e.code || "erreur") + ") : la relecture reste dans ce navigateur."; });
  }
  function exportObj(){
    var list = Object.keys(reviews).sort().map(function(k){ var r = reviews[k]; return { id: k, nom: BY[k] ? BY[k].nom : k, statut: r.statut, categorie: r.categorie || "", commentaire: r.commentaire || "", maj: r.maj }; });
    return { format: "kalis-relectures-v2", version_pack: D.version, exporte_le: new Date().toISOString(), total_exercices: EX.length, relectures: list };
  }
  function doExport(){
    var data = JSON.stringify(exportObj(), null, 1), name = "kalis_relectures_v2_" + new Date().toISOString().slice(0, 10) + ".json";
    var box = $("expbox"); box.hidden = false; $("exptxt").value = data;
    if (dl) { dl.save({ filename: name, data: data }).then(function(){ $("expmsg").textContent = "Fichier proposé au téléchargement."; }, function(){ $("expmsg").textContent = "Téléchargement refusé : copie le texte ci-dessous."; }); }
    else $("expmsg").textContent = "Copie le texte ci-dessous et enregistre-le en " + name + ".";
  }

  /* ---------- montage ---------- */
  function fillSelect(id, voc, first){
    var s = $(id), keys = Object.keys(V[voc] || {});
    s.innerHTML = '<option value="">' + first + '</option>' + keys.map(function(k){ return '<option value="' + esc(k) + '">' + esc(label(voc, k)) + '</option>'; }).join("");
  }
  fillSelect("ftype", "types_mouvement", "Tous les types"); fillSelect("flieu", "lieux", "Tous les lieux");
  $("fprio").checked = !!state.prio;
  $("fq").addEventListener("input", function(){ state.q = this.value; renderList(); });
  ["ftype", "flieu", "frelu", "fdemo"].forEach(function(id){ $(id).addEventListener("change", function(){ state[{ ftype: "type", flieu: "lieu", frelu: "relu", fdemo: "demo" }[id]] = this.value; renderList(); }); });
  $("fprio").addEventListener("change", function(){ state.prio = this.checked; saveF(); renderList(); });
  $("fexp").addEventListener("click", doExport);
  $("expclose").addEventListener("click", function(){ $("expbox").hidden = true; });
  $("expcopy").addEventListener("click", function(){ var t = $("exptxt"); t.select(); if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(t.value).then(function(){ $("expmsg").textContent = "Copié."; }, function(){ $("expmsg").textContent = "Sélectionne le texte et copie-le."; }); });
  $("lst").addEventListener("click", function(ev){ var b = ev.target.closest("button[data-id]"); if (b) go(b.getAttribute("data-id")); });
  $("tgl").addEventListener("click", function(){ var w = $("lstwrap"); w.hidden = !w.hidden; this.textContent = w.hidden ? "Afficher la liste" : "Masquer la liste"; });
  window.addEventListener("hashchange", function(){ var id = (location.hash || "").slice(1); if (BY[id] && id !== state.sel) go(id); });
  renderProgress(); renderList();
  var first = (location.hash || "").slice(1);
  state.sel = BY[first] ? first : (D.prioritaires[0] || EX[0].id);
  renderList(); renderDetail();
  if (matchMedia("(max-width:820px)").matches && BY[first]) { $("lstwrap").hidden = true; $("tgl").textContent = "Afficher la liste"; }

  /* ---------- base partagée (page publiée avec la capacité db) ---------- */
  if (window.claude && typeof window.claude.use === "function") {
    window.claude.use("downloads").then(function(d){ dl = d; }, function(){});
    window.claude.use("db").then(function(d){
      if (!d) return;
      db = d; storeMode = "partage"; renderProgress();
      d.collection("relectures_v2").limit(1000).onSnapshot(function(snap){
        var remote = {};
        snap.docs.forEach(function(doc){ var x = doc.data(); if (x && x.statut) remote[doc.id] = { statut: x.statut, categorie: x.categorie || "", commentaire: x.commentaire || "", maj: x.maj }; });
        Object.keys(reviews).forEach(function(k){ if (!remote[k]) persist(k); });
        Object.keys(remote).forEach(function(k){ if (!reviews[k] || (remote[k].maj || "") >= (reviews[k].maj || "")) reviews[k] = remote[k]; });
        lsSet(LS, JSON.stringify(reviews));
        renderProgress(); renderList();
        if (state.sel && $("revcard")) $("revcard").innerHTML = reviewHtml(BY[state.sel]), renderDetail();
      }, function(){ storeMode = "local"; db = null; renderProgress(); });
    }, function(){});
  }
})();
"""

BODY = """<title>Relecture Kalis Track v2</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:wght@600;700&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500&display=swap">
<style>%(css)s</style>
<header class="top"><h1>Relecture Kalis Track</h1><span class="ver">pack %(version)s · schéma %(schema)s · %(generated)s</span><div class="pills" id="pills"></div><div class="sync" id="sync"></div></header>
<div class="filters">
  <input type="search" id="fq" placeholder="Rechercher un exercice, un id, un alias" aria-label="Rechercher">
  <select id="ftype" aria-label="Type de mouvement"></select>
  <select id="flieu" aria-label="Lieu"></select>
  <select id="frelu" aria-label="État de relecture"><option value="">Relecture : tous</option><option value="non_relu">Non relus</option><option value="valide">Validés</option><option value="a_corriger">À corriger</option></select>
  <select id="fdemo" aria-label="Statut de démonstration"><option value="">Démonstration : toutes</option><option value="indisponible">Démonstration indisponible</option><option value="statique">Statiques</option><option value="disponible">Disponibles</option></select>
  <label class="chk"><input type="checkbox" id="fprio"> 150 prioritaires</label>
  <button type="button" class="btn" id="fexp">Exporter les relectures</button>
</div>
<div class="card export" id="expbox" hidden style="margin:10px 16px"><div class="row" style="display:flex;gap:8px;flex-wrap:wrap;align-items:center"><b>Export JSON</b><button type="button" class="btn" id="expcopy">Copier</button><button type="button" class="btn" id="expclose">Fermer</button><span class="small" id="expmsg"></span></div><textarea id="exptxt" aria-label="Export JSON des relectures"></textarea></div>
<div class="mobile-nav"><button type="button" class="btn" id="tgl">Masquer la liste</button><span class="small">Filtres ci-dessus · fiche ci-dessous</span></div>
<div class="layout">
  <aside class="list" id="lstwrap"><div class="count" id="cnt"></div><ul id="lst"></ul></aside>
  <main class="detail" id="det"></main>
</div>
<template id="atlas-src">%(atlas)s</template>
<script id="kt-data" type="application/json">%(data)s</script>
<script>%(ktjs)s</script>
<script>%(js)s</script>
"""

DEMO_BODY = """<title>Moteur Kalis Track v2</title>
<style>%(css)s
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:10px;padding:16px}
.cell{background:var(--surface);border:1px solid var(--line);border-radius:8px;padding:8px}
.cell h3{font-size:14px;font-family:var(--mono);font-weight:500;color:var(--dim);margin-bottom:4px}
.cell svg{width:100%%;height:auto;display:block;border-radius:6px}
.bar{padding:12px 16px;display:flex;flex-wrap:wrap;gap:8px;align-items:center;border-bottom:1px solid var(--line);background:var(--surface)}
.bar select{padding:6px 8px;border:1px solid var(--line);border-radius:6px;background:var(--bg);max-width:100%%}
.strip{padding:0 16px 16px}
</style>
<header class="top"><h1>Moteur de rendu de référence</h1><span class="ver">kt_pose.js %(jsver)s · pack %(version)s</span></header>
<div class="bar"><label for="sel">Exercice</label><select id="sel"></select><label class="small" style="display:inline-flex;gap:4px;align-items:center"><input type="checkbox" id="fixe"> réduction des animations</label><span class="small">6 couleurs dominantes × 2 modes ; muscles primaires en accent, secondaires atténués.</span></div>
<div class="grid" id="grid"></div>
<div class="strip"><h2>Version statique (images clés)</h2><div id="strip"></div></div>
<script id="kt-data" type="application/json">%(data)s</script>
<script>%(ktjs)s</script>
<script>
(function(){
  var D = JSON.parse(document.getElementById("kt-data").textContent), players = [];
  var sel = document.getElementById("sel"), grid = document.getElementById("grid"), fixe = document.getElementById("fixe");
  var ids = Object.keys(D.exercices).filter(function(i){ return D.exercices[i].gabarit; }).sort(function(a, b){ return D.noms[a].localeCompare(D.noms[b], "fr"); });
  sel.innerHTML = ids.map(function(i){ return '<option value="' + i + '"' + (i === "pompes" ? " selected" : "") + '>' + D.noms[i] + '</option>'; }).join("");
  function show(){
    players.forEach(function(p){ p.destroy(); }); players = []; grid.innerHTML = "";
    var id = sel.value, e = D.exercices[id], g = D.gabarits[e.gabarit], pose = KTPose.fromPack(g, e);
    Object.keys(KTPose.ACCENTS).forEach(function(acc){ ["sombre", "clair"].forEach(function(mode){
      var cell = document.createElement("div"); cell.className = "cell"; cell.innerHTML = "<h3>" + KTPose.ACCENTS[acc].label + " · " + mode + "</h3><div></div>"; grid.appendChild(cell);
      var p = new KTPose.Player(cell.lastChild, pose, { accent: acc, mode: mode, muscles: e.muscles, label: D.noms[id], reduceMotion: fixe.checked }); if (!fixe.checked) p.play(); players.push(p);
    }); });
    document.getElementById("strip").innerHTML = KTPose.staticStrip(pose, { accent: "rouge", mode: "clair", muscles: e.muscles, label: D.noms[id] });
  }
  sel.onchange = show; fixe.onchange = show; show();
})();
</script>
"""


def build(pack, fragment=None):
    payload = review_payload(pack)
    ktjs = read(pack, os.path.join("renderer_reference", "kt_pose.js"))
    atlas = read(pack, "atlas.svg")
    body = BODY % {"css": CSS, "version": payload["version"], "schema": payload["schema"], "generated": payload["generated"],
                   "atlas": atlas, "data": js_json(payload), "ktjs": ktjs.replace("</script", "<\\/script"), "js": JS}
    with open(os.path.join(pack, "review_tool.html"), "w", encoding="utf-8") as f:
        f.write(DOC_HEAD + body + DOC_TAIL)
    if fragment:
        with open(fragment, "w", encoding="utf-8") as f:
            f.write(body)
    # page de démonstration du moteur
    poses = load(pack, "poses.json")
    ex = load(pack, "exercises_v2.json")
    demo = {"version": ex["version"], "noms": {e["id"]: e["nom"] for e in ex["exercices"]},
            "gabarits": {n: slim_gabarit(g, full=False) for n, g in poses["gabarits"].items()}, "exercices": poses["exercices"]}
    jsver = "2.0.0"
    for line in ktjs.splitlines():
        if 'version: "' in line:
            jsver = line.split('version: "')[1].split('"')[0]
            break
    with open(os.path.join(pack, "renderer_reference", "index.html"), "w", encoding="utf-8") as f:
        f.write(DOC_HEAD + DEMO_BODY % {"css": CSS, "jsver": jsver, "version": ex["version"], "data": js_json(demo), "ktjs": ktjs.replace("</script", "<\\/script")} + DOC_TAIL)


if __name__ == "__main__":
    frag = None
    if "--fragment" in sys.argv:
        frag = sys.argv[sys.argv.index("--fragment") + 1]
    build(sys.argv[1], frag)
    print("review_tool.html et renderer_reference/index.html écrits")
