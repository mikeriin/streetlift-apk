"""Validation du pack v2 (L9R) et rapport de couverture.

Usage : python3 tools/validate.py <dossier_pack> [--programme programme_v33.json.gz] [--v1 exercises_db.json.gz]
Écrit coverage_report.md dans le dossier du pack et renvoie un code non nul en cas d'erreur.

Contrôles :
  schema          champs, vocabulaires, identifiants, cohérence matériel/lieux, références ;
  taxonomie       tout muscle cité (primaire, secondaire, stabilisateur, étiré) existe dans muscles.json ;
  atlas           chaque région de atlas.svg correspond à un muscle superficiel de la taxonomie et réciproquement ;
  sources         au moins 2 sources concordantes (avec muscles) par exercice ;
  graphe          arbres de progression : pas de cycle, pas d'orphelin, difficulté non décroissante ;
  prerequis       prérequis atteignables, non circulaires ;
  poses           gabarits : longueurs, amplitudes, contacts, sol, appui, accessoires, interpolation, positions = cinématique(angles) ;
  statuts         chaque exercice a un statut de démonstration cohérent ;
  correspondance  505 noms v1 et intitulés du programme rattachés ;
  substitutions   au moins une substitution par lieu compatible.
"""
import gzip
import json
import math
import os
import re
import sys
from collections import Counter, defaultdict, deque

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import body_model as B  # noqa: E402
import kb_vocab as V  # noqa: E402
import pose_checks as PC  # noqa: E402

BANDS = [("1-3", 1, 3), ("4-6", 4, 6), ("7-10", 7, 10)]
BASE_TYPES = [t for t in V.TYPES_MOUVEMENT if t not in ("hors_categorie",)]
STATUTS = ("disponible", "statique", "indisponible")

REQUIRED = {
    "id": str, "nom": str, "alias": list, "origine": str, "role": str, "generateur": bool, "famille": str,
    "type_mouvement": str, "plan": str, "vue": str, "unilateral": bool, "muscles_primaires": list,
    "muscles_secondaires": list, "muscles_stabilisateurs": list, "muscles_etires": list, "sources": list,
    "sources_meta": dict, "mode_charge": str, "mesure": str, "difficulte": int, "prerequis": list,
    "progressions": list, "regressions": list, "contrainte_articulaire": dict, "precautions": list,
    "materiel": list, "lieux": list, "points_cles": list, "erreurs_frequentes": list, "respiration": str,
    "methodes": list, "substitutions": dict, "pose": dict, "non_conformites": list, "provenance": dict,
}


def load(pack):
    def j(n):
        with open(os.path.join(pack, n), encoding="utf-8") as f:
            return json.load(f)
    return j("exercises_v2.json"), j("progressions.json"), j("poses.json"), j("mapping_v1_to_v2.json"), j("muscles.json")


# ------------------------------------------------------------------ schéma
def check_schema(exdoc, muscles):
    errs = []
    ids = set()
    known = {m["id"] for m in muscles["muscles"]}
    for ex in exdoc["exercices"]:
        eid = ex.get("id", "?")
        for k, t in REQUIRED.items():
            if k not in ex:
                errs.append(f"{eid} : champ manquant {k}")
            elif not isinstance(ex[k], t) or (t is int and isinstance(ex[k], bool)):
                errs.append(f"{eid} : type invalide pour {k}")
        if errs:
            continue
        if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", eid):
            errs.append(f"{eid} : identifiant non conforme (slug ASCII)")
        if eid in ids:
            errs.append(f"{eid} : identifiant dupliqué")
        ids.add(eid)
        if ex["type_mouvement"] not in V.TYPES_MOUVEMENT:
            errs.append(f"{eid} : type de mouvement inconnu")
        if ex["type_mouvement"] == "hors_categorie" and ex["generateur"]:
            errs.append(f"{eid} : hors catégorie utilisable par le générateur")
        if ex["mode_charge"] not in V.MODES_CHARGE:
            errs.append(f"{eid} : mode de charge inconnu")
        if ex["mesure"] not in V.MESURES:
            errs.append(f"{eid} : mesure inconnue")
        if not 1 <= ex["difficulte"] <= 10:
            errs.append(f"{eid} : difficulté hors 1-10")
        for m in ex["muscles_primaires"] + ex["muscles_secondaires"] + ex["muscles_stabilisateurs"] + ex["muscles_etires"]:
            if m not in known:
                errs.append(f"{eid} : muscle inconnu {m}")
        if not ex["muscles_primaires"]:
            errs.append(f"{eid} : aucun muscle primaire")
        if set(ex["muscles_primaires"]) & set(ex["muscles_secondaires"]):
            errs.append(f"{eid} : muscle à la fois primaire et secondaire")
        if set(ex["contrainte_articulaire"]) != set(V.ZONES) or \
                any(not isinstance(v, int) or not 0 <= v <= 3 for v in ex["contrainte_articulaire"].values()):
            errs.append(f"{eid} : contrainte articulaire invalide")
        for p in ex["precautions"]:
            if p not in V.PRECAUTIONS:
                errs.append(f"{eid} : précaution inconnue {p}")
        for m in ex["materiel"]:
            if m not in V.MATERIEL:
                errs.append(f"{eid} : matériel inconnu {m}")
        if not ex["materiel"]:
            errs.append(f"{eid} : matériel vide")
        for l in ex["lieux"]:
            if l not in V.LIEUX:
                errs.append(f"{eid} : lieu inconnu {l}")
        if not ex["lieux"]:
            errs.append(f"{eid} : aucun lieu compatible")
        exp = set(V.ALL_LIEUX)
        for m in ex["materiel"]:
            exp &= set(V.MATERIEL[m][1])
        if set(ex["lieux"]) != exp:
            errs.append(f"{eid} : lieux incohérents avec le matériel")
        if len(ex["points_cles"]) != 3 or any(not s.strip() for s in ex["points_cles"]):
            errs.append(f"{eid} : il faut exactement 3 points clés")
        if len(ex["erreurs_frequentes"]) != 2:
            errs.append(f"{eid} : il faut exactement 2 erreurs fréquentes")
        if set(ex["substitutions"]) != set(V.LIEUX):
            errs.append(f"{eid} : substitutions incomplètes")
        if "*" not in ex["provenance"]:
            errs.append(f"{eid} : provenance par défaut absente")
        if ex["vue"] not in ("profil", "face"):
            errs.append(f"{eid} : vue invalide")
        if ex["pose"].get("statut") not in STATUTS:
            errs.append(f"{eid} : statut de démonstration invalide")
    all_ids = ids
    for ex in exdoc["exercices"]:
        for k in ("progressions", "regressions"):
            for r in ex.get(k, []):
                if r not in all_ids:
                    errs.append(f"{ex['id']} : référence {k} inconnue {r}")
        for r in ex.get("prerequis", []):
            if r["id"] not in all_ids or not r.get("seuil"):
                errs.append(f"{ex['id']} : prérequis invalide {r}")
        for k in ("variante_de", "doublon_de"):
            if ex.get(k) and ex[k] not in all_ids:
                errs.append(f"{ex['id']} : {k} inconnu")
        for lieu, subs in ex.get("substitutions", {}).items():
            for s in subs:
                if s not in all_ids:
                    errs.append(f"{ex['id']} : substitution inconnue {s}")
    return errs


# ------------------------------------------------------------------ taxonomie et atlas
def check_taxonomy(muscles):
    errs = []
    ids = [m["id"] for m in muscles["muscles"]]
    if len(ids) != len(set(ids)):
        errs.append("taxonomie : identifiants dupliqués")
    for m in muscles["muscles"]:
        for k in ("id", "nom", "latin", "famille", "groupe", "vues", "profondeur", "actions", "regions"):
            if k not in m:
                errs.append(f"taxonomie : {m.get('id', '?')} champ manquant {k}")
        if m.get("groupe") not in muscles["groupes_app"]:
            errs.append(f"taxonomie : {m['id']} groupe applicatif inconnu {m.get('groupe')}")
        if m.get("profondeur") not in ("superficiel", "profond"):
            errs.append(f"taxonomie : {m['id']} profondeur invalide")
        if not set(m.get("vues", [])) <= {"face", "dos"}:
            errs.append(f"taxonomie : {m['id']} vues invalides")
    for alias, targets in muscles["alias"].items():
        for t in targets:
            if t not in ids:
                errs.append(f"taxonomie : alias {alias} vise un muscle inconnu {t}")
    return errs


def check_atlas(pack, muscles):
    errs = []
    with open(os.path.join(pack, "atlas.svg"), encoding="utf-8") as f:
        svg = f.read()
    ids = re.findall(r'id="((?:face|dos)-[a-z0-9_]+-[dg])"', svg)
    if len(ids) != len(set(ids)):
        errs.append("atlas : identifiants de région dupliqués")
    by = {m["id"]: m for m in muscles["muscles"]}
    regions = defaultdict(set)
    for rid in ids:
        vue, rest = rid.split("-", 1)
        mid, side = rest.rsplit("-", 1)
        if mid not in by:
            errs.append(f"atlas : région {rid} sans muscle dans la taxonomie")
            continue
        if by[mid]["profondeur"] != "superficiel":
            errs.append(f"atlas : région {rid} dessinée pour un muscle profond")
        if vue not in by[mid]["vues"]:
            errs.append(f"atlas : région {rid} dans une vue non prévue pour ce muscle")
        regions[mid].add(vue + "-" + side)
    for m in muscles["muscles"]:
        if m["profondeur"] == "superficiel":
            for vue in m["vues"]:
                for side in ("d", "g"):
                    if vue + "-" + side not in regions[m["id"]]:
                        errs.append(f"atlas : muscle superficiel {m['id']} sans région {vue}-{side}")
        if sorted(m["regions"]) != sorted(r for r in ids if r.split("-", 1)[1].rsplit("-", 1)[0] == m["id"]):
            errs.append(f"atlas : liste des régions de {m['id']} dans muscles.json différente du SVG")
    if "currentColor" not in svg:
        errs.append("atlas : les régions doivent utiliser currentColor")
    return errs


# ------------------------------------------------------------------ sources
def check_sources(exdoc):
    """Au moins deux sources avec muscles concordantes par exercice. Les archétypes n'ayant qu'une source
    sont renvoyés séparément (avertissement à trancher par le propriétaire, voir validation_register.md)."""
    errs, warn = [], []
    for ex in exdoc["exercices"]:
        n = ex["sources_meta"].get("nb_sources_concordantes", 0)
        if not ex["sources"]:
            errs.append(f"{ex['id']} : aucune source")
            continue
        for s in ex["sources"]:
            if not s.get("url", "").startswith("http") or not s.get("consulte_le"):
                errs.append(f"{ex['id']} : source sans URL ou sans date")
        if n < 2:
            warn.append(f"{ex['id']} (archétype {ex['sources_meta']['archetype']}) : {n} source concordante")
    return errs, warn


# ------------------------------------------------------------------ graphes
def check_graph(exdoc, prog):
    errs = []
    ids = {e["id"]: e for e in exdoc["exercices"]}
    adj = defaultdict(set)
    nodes = set()
    for c in prog["chaines"]:
        seq = [s["id"] for s in c["etapes"]]
        if len(seq) != len(set(seq)):
            errs.append(f"chaîne {c['id']} : étape répétée (cycle)")
        for i, s in enumerate(c["etapes"]):
            if s["id"] not in ids:
                errs.append(f"chaîne {c['id']} : étape inconnue {s['id']}")
            if i < len(c["etapes"]) - 1 and not (s["seuil_passage"] and s["seuil_passage"].get("texte")):
                errs.append(f"chaîne {c['id']} : seuil manquant à l'étape {s['id']}")
            if i == len(c["etapes"]) - 1 and s["suivant"] is not None:
                errs.append(f"chaîne {c['id']} : dernière étape avec suivant")
        if len(seq) < 3:
            errs.append(f"chaîne {c['id']} : moins de 3 étapes")
    for e in prog["aretes"]:
        adj[e["de"]].add(e["vers"])
        nodes |= {e["de"], e["vers"]}
    color = {}

    def dfs(u, stack):
        color[u] = 1
        for v in adj[u]:
            if color.get(v) == 1:
                errs.append(f"cycle détecté : {' > '.join(stack + [u, v])}")
            elif color.get(v) is None:
                dfs(v, stack + [u])
        color[u] = 2
    for n in sorted(nodes):
        if color.get(n) is None:
            dfs(n, [])
    indeg = Counter(v for u in adj for v in adj[u])
    entries = [n for n in nodes if indeg[n] == 0]
    for n in entries:
        if ids[n]["difficulte"] > 2:
            errs.append(f"entrée {n} de difficulté {ids[n]['difficulte']} (> 2) : pas une entrée débutant complet")
    seen = set(entries)
    dq = deque(entries)
    while dq:
        u = dq.popleft()
        for v in adj[u]:
            if v not in seen:
                seen.add(v)
                dq.append(v)
    for n in nodes - seen:
        errs.append(f"étape orpheline (non atteignable depuis une entrée débutant) : {n}")
    if sorted(entries) != sorted(prog["entrees_debutant"]):
        errs.append("liste des entrées débutant incohérente")
    for c in prog["chaines"]:
        d = [ids[s["id"]]["difficulte"] for s in c["etapes"] if s["id"] in ids]
        for a, b in zip(d, d[1:]):
            if b < a:
                errs.append(f"chaîne {c['id']} : difficulté décroissante ({a} -> {b})")
    return errs


def check_prereq_reachable(exdoc, prog):
    errs = []
    ids = {e["id"]: e for e in exdoc["exercices"]}
    req = {e["id"]: [r["id"] for r in e["prerequis"]] for e in exdoc["exercices"]}
    state = {}

    def ok(u, path):
        if state.get(u) == "ok":
            return True
        if u in path:
            errs.append(f"prérequis circulaires : {' > '.join(path + [u])}")
            return False
        res = all(ok(v, path + [u]) for v in req[u])
        if res:
            state[u] = "ok"
        return res
    for u in ids:
        ok(u, [])
    warn = [u for u, e in ids.items() if not req[u] and e["difficulte"] >= 7 and e["generateur"]]
    return errs, warn


# ------------------------------------------------------------------ poses
def template_from_pack(name, g):
    """Reconstruit la structure attendue par pose_checks depuis poses.json."""
    return {"template": name, "view": g["vue"], "props": g["accessoires"], "contacts": g["contacts"],
            "rom_exceptions": g["exceptions_amplitude"], "debout": g["debout"],
            "keyframes": [{"label": k["label"], "angles": k["angles"], "angles_articulaires": k["angles_articulaires"],
                           "joints": k["joints"], "anchor": k["anchor"], "pelvis": k["bassin"],
                           "equilibre": k.get("equilibre", True)} for k in g["images_cles"]]}


def check_poses(exdoc, poses):
    errs = []
    for name, g in poses["gabarits"].items():
        n = len(g["images_cles"])
        if not 1 <= n <= 5:
            errs.append(f"gabarit {name} : {n} images clés (1 à 5 attendues)")
        if g["boucle"] not in ("aller-retour", "cycle", "statique"):
            errs.append(f"gabarit {name} : boucle inconnue")
        if not g.get("fiche_biomecanique", {}).get("phases"):
            errs.append(f"gabarit {name} : fiche biomécanique sans phase")
        tpl = template_from_pack(name, g)
        for e in PC.check_all(tpl):
            errs.append(f"gabarit {e}")
        # positions stockées = cinématique recalculée depuis les angles absolus + ancrage
        for i, kf in enumerate(g["images_cles"]):
            J = B.fk_abs(kf["angles"], g["vue"])
            an = kf["anchor"]
            dx = an["pos"][0] - J[an["joint"]][0]
            dy = an["pos"][1] - J[an["joint"]][1]
            for j, (x, y) in J.items():
                sx, sy = kf["joints"][j]
                if abs(x + dx - sx) > 1e-3 or abs(y + dy - sy) > 1e-3:
                    errs.append(f"gabarit {name} image {i} : position {j} incohérente avec les angles")
                    break
            if kf.get("residu_contraintes", 0) > 0.12:
                errs.append(f"gabarit {name} image {i} : résidu de contraintes élevé ({kf['residu_contraintes']})")
    return errs


def check_statuts(exdoc, poses):
    errs = []
    ids = {e["id"] for e in exdoc["exercices"]}
    missing = ids - set(poses["exercices"])
    for m in sorted(missing):
        errs.append(f"entrée de pose manquante : {m}")
    for eid, p in poses["exercices"].items():
        if p["statut"] not in STATUTS:
            errs.append(f"{eid} : statut inconnu")
        if p["statut"] == "indisponible":
            if not p.get("motif"):
                errs.append(f"{eid} : démonstration indisponible sans motif")
            continue
        if not p.get("gabarit") or p["gabarit"] not in poses["gabarits"]:
            errs.append(f"{eid} : gabarit inconnu {p.get('gabarit')}")
            continue
        if p["statut"] == "statique" and not p.get("motif"):
            errs.append(f"{eid} : statut statique sans motif")
        if not p.get("muscles", {}).get("primaires"):
            errs.append(f"{eid} : aucun muscle primaire à surligner")
        allowed = {q["type"] for q in poses["gabarits"][p["gabarit"]].get("accessoires", [])}
        for r in p.get("retirer", []):
            if r not in allowed:
                errs.append(f"{eid} : accessoire à retirer {r} absent du gabarit")
    return errs


# ------------------------------------------------------------------ couverture
def coverage(exdoc):
    exs = [e for e in exdoc["exercices"] if e["generateur"]]
    mat = {}
    gaps = []
    for t in BASE_TYPES:
        for l in V.ALL_LIEUX:
            for band, lo, hi in BANDS:
                n = [e["id"] for e in exs if e["type_mouvement"] == t and l in e["lieux"] and lo <= e["difficulte"] <= hi]
                mat[(t, l, band)] = n
                if len(n) < 3:
                    gaps.append((t, l, band, len(n)))
    return mat, gaps


def check_substitutions(exdoc):
    missing = []
    for e in exdoc["exercices"]:
        if not e["generateur"]:
            continue
        for l in e["lieux"]:
            if not e["substitutions"].get(l):
                missing.append((e["id"], l))
    return missing


def check_mapping(exdoc, mapping, v1=None, programme=None):
    errs = []
    ids = {e["id"] for e in exdoc["exercices"]}
    if v1 is not None:
        names = [e["n"] for e in v1]
        for n in names:
            m = mapping["base_v1"].get(n)
            if not m or m["id"] not in ids or m["canonique"] not in ids:
                errs.append(f"exercice v1 non rattaché : {n}")
        if len(mapping["base_v1"]) != len(names):
            errs.append("table v1 : nombre d'entrées différent de la base v1")
    if programme is not None:
        names = {x["name"] for w in programme["weeks"] for d in w["days"] for x in d["exercises"]}
        for n in sorted(names):
            m = mapping["programme_v33"].get(n)
            if not m or m["id"] not in ids:
                errs.append(f"exercice du programme non rattaché : {n}")
    return errs


def run_all(pack, v1_path=None, prog_path=None):
    exdoc, prog, poses, mapping, muscles = load(pack)
    v1 = programme = None
    if v1_path:
        with gzip.open(v1_path, "rt", encoding="utf-8") as f:
            v1 = json.load(f)
    if prog_path:
        with gzip.open(prog_path, "rt", encoding="utf-8") as f:
            programme = json.load(f)
    serr, swarn = check_sources(exdoc)
    res = {
        "schema": check_schema(exdoc, muscles),
        "taxonomie": check_taxonomy(muscles),
        "atlas": check_atlas(pack, muscles),
        "sources": serr,
        "graphe": check_graph(exdoc, prog),
        "poses": check_poses(exdoc, poses),
        "statuts": check_statuts(exdoc, poses),
        "correspondance": check_mapping(exdoc, mapping, v1, programme),
    }
    perr, pwarn = check_prereq_reachable(exdoc, prog)
    res["prerequis"] = perr
    subs_missing = check_substitutions(exdoc)
    res["substitutions"] = [f"{a} : aucune substitution à {b}" for a, b in subs_missing]
    mat, gaps = coverage(exdoc)
    return exdoc, prog, poses, mapping, programme, res, {"prerequis": pwarn, "sources": swarn}, mat, gaps


# ------------------------------------------------------------------ priorité et rapport
def priority_list(exdoc, prog, mapping, n=150):
    ids = {e["id"]: e for e in exdoc["exercices"]}
    usage = Counter()
    for name, m in mapping["programme_v33"].items():
        tgt = ids[m["id"]]
        usage[tgt["doublon_de"] or tgt["id"]] += m["occurrences"]
    chain_nodes = Counter()
    for c in prog["chaines"]:
        for s in c["etapes"]:
            chain_nodes[s["id"]] += 1
    rows = []
    for e in exdoc["exercices"]:
        if not e["generateur"]:
            continue
        u = usage[e["id"]]
        ch = chain_nodes[e["id"]]
        fund = e["difficulte"] <= 4 and e["type_mouvement"] not in ("isolation", "mobilite")
        free = "maison_sans_materiel" in e["lieux"] or "parc_street_workout" in e["lieux"]
        score = 10 * math.log1p(u) + 6 * min(ch, 2) + (4 if fund else 0) + (3 if free else 0) + (2 if len(e["lieux"]) >= 3 else 0)
        why = []
        if u:
            why.append(f"{u} occurrence(s) dans le programme v33")
        if ch:
            why.append(f"étape de {ch} arbre(s) de progression")
        if fund:
            why.append("mouvement fondamental accessible")
        if free:
            why.append("réalisable sans salle")
        rows.append((round(score, 2), e["id"], e["nom"], "; ".join(why) or "polyvalence (lieux multiples)"))
    rows.sort(key=lambda r: (-r[0], r[1]))
    return rows[:n]


# Cases de la matrice sans exercice réel connu (décision D-L9R-08) : documentées, non comblées artificiellement.
GAP_RATIONALE = {
    ("tirage_vertical", "maison_sans_materiel"): "un tirage vertical exige un point d'accroche au-dessus de la tête (barre, anneaux, élastique) ; les tractions sur un haut de porte sont exclues pour des raisons de sécurité.",
    ("portes", "maison_sans_materiel"): "un porté exige une charge à porter ; un sac chargé relève du matériel « sac lesté » (maison équipée, parc, salle).",
    ("charniere_hanche", "maison_sans_materiel"): "au-delà du soulevé de terre unijambe au poids de corps, une charnière de niveau 7+ exige une charge ; le curl nordique est classé en isolation.",
    ("flexion_tronc", "maison_sans_materiel"): "les flexions du tronc de niveau 7+ exigent une suspension (barre) ou un lest ; le dragon flag est classé en gainage anti-extension.",
    ("tirage_horizontal", "maison_sans_materiel"): "sans barre ni anneaux, seul le rowing inversé à un bras sous une table atteint le niveau 7.",
    ("fente", "maison_sans_materiel"): "au poids de corps, seules les fentes bulgares sautées atteignent le niveau 7 ; les autres variantes lourdes exigent une charge.",
    ("figure_dynamique", "maison_sans_materiel"): "les figures dynamiques de niveau 1-3 sans matériel se limitent au kick-up et aux wall walks partiels ; les roulades, sans source musculaire concordante, ne sont pas ajoutées (règle des deux sources).",
    ("figure_dynamique", "maison_equipee"): "voir maison sans matériel : les figures dynamiques faciles se font au mur.",
    ("figure_dynamique", "parc_street_workout"): "voir maison sans matériel.",
    ("figure_dynamique", "salle"): "voir maison sans matériel.",
    ("mobilite", "maison_sans_materiel"): "la mobilité de niveau 7+ se limite au pont une jambe et à la descente en pont ; les autres exercices avancés (grand écart) sont écartés (précaution).",
    ("mobilite", "maison_equipee"): "voir maison sans matériel.",
    ("mobilite", "parc_street_workout"): "voir maison sans matériel.",
    ("mobilite", "salle"): "voir maison sans matériel.",
    ("conditionnement", "maison_sans_materiel"): "sans matériel, seuls les burpees avancés atteignent le niveau 7 ; les sprints répétés sont classés en locomotion.",
    ("gainage_anti_rotation", "maison_sans_materiel"): "les gainages anti-rotation de niveau 7+ sans matériel se limitent à la planche à un bras et à la planche bras-jambe opposés.",
    ("gainage_anti_flexion_laterale", "maison_sans_materiel"): "niveau 7+ sans matériel : planche latérale étoile et Copenhague à levier long ; le drapeau est une figure statique.",
    ("charniere_hanche", "maison_equipee"): "niveau 7+ : soulevé de terre roumain unijambe lourd et swing lourd ; le reste exige une barre.",
    ("charniere_hanche", "parc_street_workout"): "niveau 7+ : hip thrust unijambe lesté ; le reste exige une charge lourde.",
    ("fente", "parc_street_workout"): "niveau 7+ : fentes bulgares sautées et fentes lestées au gilet.",
    ("portes", "maison_equipee"): "niveau 7+ : porté de sac lourd et farmer walk haltères lourds.",
    ("portes", "parc_street_workout"): "les portés au parc reposent sur le sac lesté (suitcase, bear hug, zercher, overhead, farmer).",
}


def write_report(pack, exdoc, prog, mapping, res, warns, mat, gaps, programme):
    L = []
    L.append("# Rapport de couverture et de validation — pack de contenu Kalis Track v2 (L9R)\n")
    L.append("Généré par `tools/validate.py`. Statistiques calculées sur `exercises_v2.json`, `poses.json`, `muscles.json`, `atlas.svg`.\n")
    exs = exdoc["exercices"]
    gen = [e for e in exs if e["generateur"]]
    with open(os.path.join(pack, "poses.json"), encoding="utf-8") as f:
        poses = json.load(f)
    st = Counter(p["statut"] for p in poses["exercices"].values())
    L.append("## 1. Synthèse\n")
    L.append(f"- Exercices dans le pack : **{len(exs)}** ({sum(e['origine'] == 'base_v1' for e in exs)} issus de la base v1, "
             f"{sum(e['origine'] == 'ajout_l9' for e in exs)} ajoutés en L9, {sum(e['origine'] == 'ajout_l9r' for e in exs)} ajoutés en L9R pour la couverture).")
    L.append(f"- Utilisables par le générateur : **{len(gen)}** ; doublons signalés : {sum(1 for e in exs if e['doublon_de'])} ; "
             f"tests : {sum(e['role'] == 'test' for e in exs)} ; hors générateur : {sum(e['role'] == 'hors_generateur' for e in exs)}.")
    L.append(f"- Sources : {sum(len(e['sources']) for e in exs)} références au total ; exercices avec ≥ 2 sources concordantes pour les muscles : "
             f"{sum(1 for e in exs if e['sources_meta']['nb_sources_concordantes'] >= 2)} / {len(exs)}.")
    L.append(f"- Chaînes de progression : {len(prog['chaines'])} ; entrées « débutant complet » : {len(prog['entrees_debutant'])}.")
    L.append(f"- Gabarits de pose : {len(poses['gabarits'])} ; démonstrations : {st.get('disponible', 0)} disponibles, "
             f"{st.get('statique', 0)} statiques (position de départ seulement), {st.get('indisponible', 0)} indisponibles.")
    L.append("")
    L.append("## 2. Contrôles automatiques\n")
    L.append("| Contrôle | Résultat |\n| --- | --- |")
    for k, v in res.items():
        L.append(f"| {k} | {'OK' if not v else f'{len(v)} anomalie(s)'} |")
    L.append("")
    for k, v in res.items():
        if v:
            L.append(f"### Anomalies : {k}\n")
            L += [f"- {x}" for x in v[:200]]
            L.append("")
    if warns.get("sources"):
        L.append("### Avertissements : sources (une seule source concordante)\n")
        L.append("Décision attendue du propriétaire (voir `validation_register.md` §0) :\n")
        L += [f"- {w}" for w in warns["sources"]]
        L.append("")
    if warns.get("prerequis"):
        L.append("### Avertissements : prérequis (non bloquants)\n")
        L.append("Exercices de difficulté ≥ 7 sans prérequis explicite (le générateur doit les réserver aux profils avancés) :\n")
        L.append(", ".join(f"`{w}`" for w in sorted(warns["prerequis"])))
        L.append("")
    L.append("## 3. Matrice de couverture pour le générateur\n")
    L.append("Nombre d'exercices utilisables par type de mouvement, lieu et tranche de difficulté (seuil : 3). "
             "Une case en **gras** signale un manque.\n")
    hdr = "| Type | " + " | ".join(f"{V.LIEUX[l]} {b}" for l in V.ALL_LIEUX for b, _, _ in BANDS) + " |"
    L.append(hdr)
    L.append("| --- " * (1 + len(V.ALL_LIEUX) * len(BANDS)) + "|")
    for t in BASE_TYPES:
        cells = []
        for l in V.ALL_LIEUX:
            for b, _, _ in BANDS:
                n = len(mat[(t, l, b)])
                cells.append(f"**{n}**" if n < 3 else str(n))
        L.append(f"| {V.TYPES_MOUVEMENT[t]} | " + " | ".join(cells) + " |")
    L.append("")
    L.append(f"### Manques restants ({len(gaps)} cases sous le seuil)\n")
    L.append("Règle L9R : au moins 3 exercices par case dès qu'un exercice réel existe. Les cases ci-dessous n'ont pas été "
             "comblées par des variantes artificielles ; la justification est donnée pour chacune (décision D-L9R-08).\n")
    L.append("| Type | Lieu | Difficulté | Nombre | Justification |\n| --- | --- | --- | --- | --- |")
    for t, l, b, n in gaps:
        why = GAP_RATIONALE.get((t, l), "—")
        L.append(f"| {V.TYPES_MOUVEMENT[t]} | {V.LIEUX[l]} | {b} | {n} | {why} |")
    L.append("")
    L.append("## 4. Substitutions\n")
    miss = res["substitutions"]
    L.append(f"Substitutions calculées : même type de mouvement, difficulté ±1, par lieu (3 au plus, "
             f"classées par écart de difficulté puis muscles primaires communs). Exercices du générateur sans "
             f"substitution dans un de leurs lieux compatibles : **{len(miss)}**.\n")
    L.append("## 5. Correspondances\n")
    L.append(f"- Base v1 : {len(mapping['base_v1'])} noms rattachés sur 505.")
    pm = mapping["programme_v33"]
    L.append(f"- Programme de 40 semaines : {len(pm)} intitulés distincts rattachés "
             f"({sum(1 for v in pm.values() if v['correspondance'] == 'exacte')} exacts, "
             f"{sum(1 for v in pm.values() if v['correspondance'] != 'exacte')} par analyse du nom, avec méthodes).")
    L.append("")
    L.append("## 6. Liste prioritaire des 150 exercices (démonstrations contrôlées visuellement en premier)\n")
    L.append("Score = 10·ln(1 + occurrences dans le programme v33) + 6 × arbres de progression (max 2) + 4 si "
             "mouvement fondamental de difficulté ≤ 4 + 3 si réalisable sans salle + 2 si au moins 3 lieux. "
             "Seuls les exercices utilisables par le générateur sont classés. Les planches de contrôle correspondantes "
             "sont dans `planches/prioritaires_XX.png`.\n")
    L.append("| Rang | Exercice | Score | Statut démo | Justification |\n| --- | --- | --- | --- | --- |")
    for i, (s, eid, nom, why) in enumerate(priority_list(exdoc, prog, mapping), 1):
        L.append(f"| {i} | {nom} (`{eid}`) | {s} | {poses['exercices'][eid]['statut']} | {why} |")
    L.append("")
    with open(os.path.join(pack, "coverage_report.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(L))


if __name__ == "__main__":
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("pack")
    ap.add_argument("--v1")
    ap.add_argument("--programme")
    a = ap.parse_args()
    exdoc, prog, poses, mapping, programme, res, warns, mat, gaps = run_all(a.pack, a.v1, a.programme)
    write_report(a.pack, exdoc, prog, mapping, res, warns, mat, gaps, programme)
    bad = {k: len(v) for k, v in res.items() if v}
    print("Contrôles :", {k: ("OK" if not v else len(v)) for k, v in res.items()})
    print("Manques de couverture :", len(gaps), "; avertissements :", {k: len(v) for k, v in warns.items()})
    sys.exit(1 if bad else 0)
