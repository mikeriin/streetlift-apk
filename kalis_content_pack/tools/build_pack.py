"""Construit le pack de contenu Kalis Track v1 (L9).

Usage : python3 tools/build_pack.py <exercises_db.json.gz> <programme_v33.json.gz> <dossier_sortie>
Sorties : exercises_v2.json, progressions.json, poses.json, mapping_v1_to_v2.json.
Déterministe : mêmes entrées -> mêmes sorties (aucun horodatage variable hors meta.generated).
"""
import gzip
import json
import math
import os
import re
import sys
import unicodedata
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import build_poses  # noqa: E402
import kb_archetypes as KA  # noqa: E402
import kb_exercises as KE  # noqa: E402
import kb_progressions as KP  # noqa: E402
import kb_vocab as V  # noqa: E402

SCHEMA_VERSION = "2.0.0"
PACK_VERSION = "1.0.0"
GENERATED = "2026-09-26"

SRC_V1 = "kt_v1"          # base existante du propriétaire
SRC_GEN = "genere_l9"     # généré par Claude (L9), à relire
SRC_CALC = "calcule"
FREE_EQ = {"aucun", "sol_degage", "mur", "support_stable", "espace_exterieur", "serviette", "baton"}      # calculé par les scripts à partir des autres champs


def load_gz(path):
    with gzip.open(path, "rt", encoding="utf-8") as f:
        return json.load(f)


def slug(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    s = s.lower().replace("&", " et ").replace("¼", "quart")
    s = re.sub(r"[^a-z0-9]+", "-", s).strip("-")
    return s


def clean_name(n):
    letters = [c for c in n if c.isalpha()]
    up = sum(1 for c in letters if c.isupper())
    if letters and up / len(letters) > 0.6:
        words = n.lower().split()
        n = " ".join(words)
        n = n[0].upper() + n[1:]
        n = re.sub(r"\bpdc\b", "PdC", n)
    n = re.sub(r"\b1rm\b", "1RM", n, flags=re.I)
    return n


MOD_CUES = {
    "leste": "Lest fixé près du corps (ceinture ou gilet) ; progresse par paliers de 1 à 2,5 kg.",
    "tempo": "Tempo imposé : descente comptée en 3 s, sans relâcher en bas.",
    "pause": "Pause complète de 1 à 2 s en position basse, gainage maintenu.",
    "negatif": "Phase de descente seule, en 3 à 5 s ; remonte avec aide ou par un support.",
    "explosif": "Phase de poussée ou de tirage la plus rapide possible, descente contrôlée.",
    "assiste": "Assistance réglée pour garder une technique parfaite ; réduis-la progressivement.",
    "elastique_resistance": "Élastique ajouté en résistance : la difficulté augmente en fin d'amplitude.",
    "singles_lourds": "Répétitions uniques lourdes, repos complet de 3 à 5 min.",
    "test_1rm": "Protocole de test : montée en charge par paliers, arrêt au premier défaut technique.",
    "test_max_reps": "Protocole de test : maximum de répétitions propres, arrêt au premier défaut technique.",
    "clusters": "Série fractionnée : courtes pauses de 10 à 20 s à l'intérieur de la série.",
    "series_longues": "Séries longues à allure régulière, sans aller à l'échec.",
    "intervalles": "Alterne effort intense et récupération selon le protocole de la séance.",
    "sprint": "Efforts courts à intensité maximale, récupération complète.",
    "leste_optionnel": "Commence au poids de corps ; ajoute un lest seulement quand la tenue cible est acquise.",
}
MOD_METHODES = {"clusters": "clusters", "singles_lourds": "singles_lourds", "test_1rm": "test_1rm",
                "test_max_reps": "test_max_reps", "series_longues": "series_longues", "tempo": "tempo",
                "pause": "pause", "explosif": "explosif"}

# Accessoires ajoutés à la pose selon le matériel (le gabarit ne dessine que l'appui)
BAR_ON_BACK = {"squat.dos", "squat.box", "hinge.barre"}


def extra_props(ex, tpl_name):
    eq = set(ex["materiel"])
    props = []
    charge = ex["mode_charge"]
    fam = tpl_name.split(".")[0]
    if "barre" in eq and charge == "barre":
        if tpl_name in BAR_ON_BACK and ex["type_mouvement"] in ("squat", "charniere_hanche") and "roumain" not in ex["nom"].lower() \
                and "terre" not in ex["nom"].lower():
            props.append({"type": "barre_chargee", "attach": "epaule_d", "offset": [-0.04, 0.03]})
        elif tpl_name == "squat.front":
            props.append({"type": "barre_chargee", "attach": "epaule_d", "offset": [0.06, 0.02]})
        elif tpl_name == "banc.hip_thrust":
            props.append({"type": "barre_chargee", "attach": "bassin", "offset": [0.0, 0.1]})
        elif fam not in ("cable", "assis", "ergo"):
            props.append({"type": "barre_chargee", "attach": "poignets"})
    if "halteres" in eq and charge == "halteres":
        props.append({"type": "halteres", "attach": "poignet_d"})
        if not ex["unilateral"]:
            props.append({"type": "halteres", "attach": "poignet_g"})
    if "kettlebell" in eq and charge == "kettlebell" and fam not in ("turkish", "face"):
        props.append({"type": "kettlebell", "attach": "poignets" if fam in ("squat", "olympique") else "poignet_d"})
    if "lest" in eq and charge == "lest":
        props.append({"type": "lest", "attach": "bassin"})
    if charge == "assistance" and "elastique" in eq:
        props.append({"type": "elastique_assistance", "attach": "pied_d"})
    if "sac_leste" in eq:
        props.append({"type": "sac_leste", "attach": "poignets"})
    if "medecine_ball" in eq and fam not in ("lancer",):
        props.append({"type": "medecine_ball", "attach": "poignets"})
    return props


def highlight_for(ex):
    segs = []
    for m in ex["muscles_primaires"]:
        for s in V.MUSCLE_SEGMENTS.get(m, []):
            if s not in segs:
                segs.append(s)
    return segs


def pose_for(ex, arch_pose, override):
    name = override or arch_pose
    if "anneaux" in ex["materiel"] and name.endswith(".barre_fixe"):
        name = name.replace(".barre_fixe", ".anneaux")
    return name


def build(db_path, prog_path, out_dir):
    v1 = load_gz(db_path)
    prog = load_gz(prog_path)
    v1_by_name = {e["n"]: e for e in v1}
    tpl_all = build_poses.build_all()

    # ------------------------------------------------------------ exercices
    ids = {}
    used = set()
    for row in KE.EX:
        sid = slug(row["name"])
        k = 2
        while sid in used:
            sid = f"{slug(row['name'])}-{k}"
            k += 1
        used.add(sid)
        ids[row["name"]] = sid

    exercises = []
    by_name = {}
    for row in KE.EX:
        arch = KA.ARCH[row["arch"]]
        mods = row.get("mods", [])
        ex = {"id": ids[row["name"]]}
        ex["nom"] = row.get("nom") or clean_name(row["name"])
        alias = list(row.get("alias", []))
        if ex["nom"] != row["name"]:
            alias.insert(0, row["name"])
        ex["alias"] = alias
        ex["type_mouvement"] = row.get("type") or arch["type_mouvement"]
        ex["muscles_primaires"] = row["prim"].split() if "prim" in row else list(arch["muscles_primaires"])
        sec = row["sec"].split() if "sec" in row else list(arch["muscles_secondaires"])
        ex["muscles_secondaires"] = [m for m in sec if m not in ex["muscles_primaires"]]
        eq = list(row.get("eq") or arch["materiel"])
        charge = row.get("charge") or arch["mode_charge"]
        if "leste" in mods and charge == "poids_de_corps":
            charge = "lest"
        if "leste" in mods and not ({"lest", "disques", "halteres", "kettlebell", "medecine_ball", "sac_leste"} & set(eq)):
            eq.append("lest")
        if "assiste" in mods:
            charge = "assistance"
            if "elastique" not in eq and "support_stable" not in eq:
                eq.append("elastique")
        if "elastique_resistance" in mods and "elastique" not in eq:
            eq.append("elastique")
        if "aucun" in eq and len(eq) > 1:
            eq.remove("aucun")
        ex["mode_charge"] = charge
        ex["mesure"] = row.get("mesure") or arch["mesure"]
        ex["unilateral"] = bool(row.get("uni", arch["unilateral"]))
        tpl_name = pose_for({"materiel": eq}, arch["pose"], row.get("pose"))
        ex["vue"] = tpl_all[tpl_name]["view"]
        ex["plan"] = arch["plan"] or ("frontal" if ex["vue"] == "face" else "sagittal")
        ex["difficulte"] = row["diff"]
        cst = [int(c) for c in row["contrainte"]] if "contrainte" in row else list(arch["contrainte"])
        if any(m in mods for m in ("leste", "singles_lourds", "test_1rm", "explosif")):
            cst = [min(3, c + 1) if c >= 2 else c for c in cst]
        ex["contrainte_articulaire"] = dict(zip(V.ZONES, cst))
        prec = list(arch["precautions"]) + list(row.get("precautions_plus", []))
        if any(m in mods for m in ("singles_lourds", "test_1rm")) and "effort_maximal" not in prec:
            prec.append("effort_maximal")
        if "leste" in mods and ex["type_mouvement"] in ("squat",) and "charge_axiale" not in prec:
            prec.append("charge_axiale")
        ex["precautions"] = [p for i, p in enumerate(prec) if p and p not in prec[:i]]
        ex["materiel"] = eq
        lieux = set(V.ALL_LIEUX)
        for m in eq:
            lieux &= set(V.MATERIEL[m][1])
        ex["lieux"] = [l for l in V.ALL_LIEUX if l in lieux]
        cues = list(arch["points_cles"])
        extra = [MOD_CUES[m] for m in mods if m in MOD_CUES]
        if extra:
            cues = cues[:3 - min(len(extra), 2)] + extra[:2]
        ex["points_cles"] = cues[:3]
        ex["erreurs_frequentes"] = list(arch["erreurs"])[:2]
        ex["respiration"] = arch["respiration"]
        ex["methodes"] = [MOD_METHODES[m] for m in mods if m in MOD_METHODES]
        ex["role"] = row.get("role", "exercice")
        ex["_tpl"] = tpl_name
        ex["_row"] = row
        ex["famille"] = row["arch"]
        exercises.append(ex)
        by_name[row["name"]] = ex

    # doublons, variantes, non-conformités
    for ex in exercises:
        row = ex["_row"]
        ex["doublon_de"] = ids[row["doublon"]] if row.get("doublon") else None
        ex["variante_de"] = ids[row["base"]] if row.get("base") else None
        nc = []
        if row.get("nc"):
            nc.append(row["nc"])
        v1row = v1_by_name.get(row["name"])
        if v1row:
            need = [m for m in ex["materiel"] if m not in FREE_EQ]
            if v1row["eq"] == "poids de corps" and need and not any("Matériel v1" in x for x in nc):
                nc.append("Matériel v1 « poids de corps » alors que l'exercice nécessite : "
                          + ", ".join(V.MATERIEL[m][0].lower() for m in need) + ".")
        ex["non_conformites"] = nc
        ex["origine"] = "ajout_l9" if row.get("added") else "base_v1"
        ex["generateur"] = ex["role"] == "exercice" and ex["doublon_de"] is None and ex["type_mouvement"] != "hors_categorie"

    # ------------------------------------------------------------ progressions
    nodes = set()
    edges = {}
    chains_out = []
    for cid, title, steps in KP.CHAINS:
        out_steps = []
        for i, (n, seuil) in enumerate(steps):
            eid = ids[n]
            nodes.add(eid)
            nxt = ids[steps[i + 1][0]] if i + 1 < len(steps) else None
            out_steps.append({"id": eid, "seuil_passage": seuil, "suivant": nxt})
            if nxt:
                edges[(eid, nxt)] = {"de": eid, "vers": nxt, "seuil": seuil, "chaine": cid, "type": "progression"}
        chains_out.append({"id": cid, "titre": title, "etapes": out_steps})
    extra_edges = []
    for tgt, reqs in KP.EXTRA_PREREQ.items():
        for src, seuil in reqs:
            extra_edges.append({"de": ids[src], "vers": ids[tgt], "seuil": seuil, "type": "prerequis_transverse"})
    indeg = Counter(e["vers"] for e in edges.values())
    entries = sorted(n for n in nodes if indeg[n] == 0)
    progressions = {
        "version": PACK_VERSION,
        "description": "Arbres de progression : chaque étape indique le seuil mesurable pour passer à la suivante ; "
                       "les régressions sont les arêtes inverses.",
        "entrees_debutant": entries,
        "chaines": chains_out,
        "aretes": sorted(edges.values(), key=lambda e: (e["chaine"], e["de"])) + extra_edges,
        "provenance": SRC_GEN,
    }

    # prérequis et régressions par exercice
    pred = defaultdict(list)
    succ = defaultdict(list)
    for e in list(edges.values()) + extra_edges:
        pred[e["vers"]].append(e)
        if e["type"] == "progression":
            succ[e["de"]].append(e["vers"])
    ex_by_id = {e["id"]: e for e in exercises}
    for ex in exercises:
        reqs = []
        seen = set()
        for e in pred.get(ex["id"], []):
            if e["de"] not in seen:
                seen.add(e["de"])
                reqs.append({"id": e["de"], "seuil": e["seuil"]["texte"]})
        if not reqs and ex["variante_de"] and ex["variante_de"] != ex["id"]:
            base = ex_by_id[ex["variante_de"]]
            mods = ex["_row"].get("mods", [])
            if "leste" in mods or ex["role"] == "test" or ex["difficulte"] > base["difficulte"]:
                seuil = "3 × 30 s tenues propres" if base["mesure"] == "temps" else \
                    "3 × 20 min" if base["mesure"] == "distance" else "3 × 10 propres"
                if "leste" in mods and base["mesure"] == "repetitions":
                    seuil = "3 × 12 propres au poids de corps"
                reqs.append({"id": base["id"], "seuil": seuil})
        ex["prerequis"] = reqs
        ex["progressions"] = sorted(set(succ.get(ex["id"], [])))
        ex["regressions"] = sorted({e["de"] for e in pred.get(ex["id"], []) if e["type"] == "progression"})

    # ------------------------------------------------------------ substitutions
    for ex in exercises:
        sub = {}
        elargies = []
        for lieu in V.ALL_LIEUX:
            cands = []
            for o in exercises:
                if o["id"] == ex["id"] or not o["generateur"] or lieu not in o["lieux"]:
                    continue
                if o["doublon_de"] == ex["id"] or ex["doublon_de"] == o["id"]:
                    continue
                if o["type_mouvement"] != ex["type_mouvement"]:
                    continue
                d = abs(o["difficulte"] - ex["difficulte"])
                if d > 1:
                    continue
                shared = len(set(o["muscles_primaires"]) & set(ex["muscles_primaires"]))
                same_uni = o["unilateral"] == ex["unilateral"]
                score = (d, -shared, 0 if o["famille"] == ex["famille"] else 1, 0 if same_uni else 1, o["id"])
                cands.append((score, o["id"]))
            cands.sort()
            sub[lieu] = [c[1] for c in cands[:3]]
            if not sub[lieu] and lieu in ex["lieux"]:
                # repli documenté : même type, écart de difficulté 2
                wide = []
                for o in exercises:
                    if o["id"] == ex["id"] or not o["generateur"] or lieu not in o["lieux"]:
                        continue
                    if o["type_mouvement"] == ex["type_mouvement"] and abs(o["difficulte"] - ex["difficulte"]) == 2 \
                            and o["doublon_de"] != ex["id"] and ex["doublon_de"] != o["id"]:
                        shared = len(set(o["muscles_primaires"]) & set(ex["muscles_primaires"]))
                        wide.append(((-shared, o["difficulte"] > ex["difficulte"], o["id"]), o["id"]))
                wide.sort()
                sub[lieu] = [c[1] for c in wide[:2]]
                if not sub[lieu]:
                    # second repli : muscles primaires communs, écart de difficulté ≤ 3, tout type
                    wide = []
                    for o in exercises:
                        if o["id"] == ex["id"] or not o["generateur"] or lieu not in o["lieux"]:
                            continue
                        shared = len(set(o["muscles_primaires"]) & set(ex["muscles_primaires"]))
                        d = abs(o["difficulte"] - ex["difficulte"])
                        if shared and d <= 3 and o["doublon_de"] != ex["id"] and ex["doublon_de"] != o["id"]:
                            wide.append(((d, -shared, o["id"]), o["id"]))
                    wide.sort()
                    sub[lieu] = [c[1] for c in wide[:2]]
                if sub[lieu]:
                    elargies.append(lieu)
        ex["substitutions"] = sub
        ex["substitutions_elargies"] = elargies

    # ------------------------------------------------------------ poses
    templates_used = sorted({ex["_tpl"] for ex in exercises})
    pose_ex = {}
    for ex in exercises:
        pose_ex[ex["id"]] = {"gabarit": ex["_tpl"], "accessoires": extra_props(ex, ex["_tpl"]),
                             "segments_accent": highlight_for(ex)}
        ex["pose"] = {"gabarit": ex["_tpl"], "vue": ex["vue"], "reference": f"poses.json#/exercices/{ex['id']}"}
    import kinematics as K
    poses = {
        "version": PACK_VERSION,
        "repere": "unité = taille du personnage ; y vers le haut ; sol en y = 0 ; origine x sous le centre de masse de l'image clé 0",
        "squelette": {"articulations": K.JOINTS, "segments": [list(s) for s in K.SEGMENTS],
                      "longueurs": K.L, "rayon_tete": K.HEAD_R},
        "roles_couleur": {"accent": "muscles travaillés", "neutre_moyen": "corps", "neutre_contraste": "accessoires et sol"},
        "gabarits": {n: strip_template(tpl_all[n]) for n in templates_used},
        "exercices": pose_ex,
        "provenance": SRC_GEN,
    }

    # ------------------------------------------------------------ provenance et nettoyage
    for ex in exercises:
        row = ex.pop("_row")
        ex.pop("_tpl")
        v1row = v1_by_name.get(row["name"])
        ex["v1"] = {"nom": row["name"], "groupe": v1row["g"], "materiel": v1row["eq"]} if v1row else None
        ex["provenance"] = {
            "nom": SRC_V1 if v1row else SRC_GEN,
            "alias": SRC_GEN,
            "materiel": SRC_GEN, "lieux": SRC_CALC, "substitutions": SRC_CALC, "prerequis": SRC_CALC,
            "progressions": SRC_CALC, "regressions": SRC_CALC, "pose": SRC_GEN,
            "*": SRC_GEN,
        }
    order = ["id", "nom", "alias", "origine", "role", "generateur", "famille", "type_mouvement", "plan", "vue", "unilateral",
             "muscles_primaires", "muscles_secondaires", "mode_charge", "mesure", "difficulte", "prerequis",
             "progressions", "regressions", "contrainte_articulaire", "precautions", "materiel", "lieux",
             "points_cles", "erreurs_frequentes", "respiration", "methodes", "substitutions", "substitutions_elargies", "pose",
             "variante_de", "doublon_de", "non_conformites", "v1", "provenance"]
    exercises = [{k: ex[k] for k in order} for ex in exercises]

    ex_doc = {
        "version": PACK_VERSION, "schema": SCHEMA_VERSION, "generated": GENERATED,
        "licence": "Voir licences.md : noms v1 = propriété du propriétaire ; enrichissement généré par Claude (L9), "
                   "marqué « genere_l9 », à relire.",
        "sources": {SRC_V1: "Base d'exercices de l'application v1 (assets/exercises_db.json.gz)",
                    SRC_GEN: "Contenu généré par Claude pour le lot L9 (non relu par un professionnel diplômé)",
                    SRC_CALC: "Valeur calculée par tools/build_pack.py à partir des autres champs"},
        "vocabulaires": {"types_mouvement": V.TYPES_MOUVEMENT, "muscles": V.MUSCLES, "zones": V.ZONES_LABELS,
                         "modes_charge": V.MODES_CHARGE, "mesures": V.MESURES,
                         "materiel": {k: {"libelle": v[0], "lieux": v[1]} for k, v in V.MATERIEL.items()},
                         "lieux": V.LIEUX, "precautions": V.PRECAUTIONS, "methodes": V.METHODES},
        "exercices": exercises,
    }

    # ------------------------------------------------------------ correspondances
    mapping_v1 = {}
    for e in v1:
        eid = ids[e["n"]]
        exo = next(x for x in exercises if x["id"] == eid)
        mapping_v1[e["n"]] = {"id": eid, "canonique": exo["doublon_de"] or eid}
    prog_map = map_programme(prog, ids, v1_by_name)
    mapping = {"version": PACK_VERSION, "base_v1": mapping_v1, "programme_v33": prog_map,
               "note": "canonique = identifiant à utiliser quand l'entrée v1 est un doublon signalé."}

    os.makedirs(out_dir, exist_ok=True)
    dump(os.path.join(out_dir, "exercises_v2.json"), ex_doc)
    dump(os.path.join(out_dir, "progressions.json"), progressions)
    dump(os.path.join(out_dir, "poses.json"), poses, compact=True)
    dump(os.path.join(out_dir, "mapping_v1_to_v2.json"), mapping)
    return ex_doc, progressions, poses, mapping


def strip_template(t):
    kfs = []
    for kf in t["keyframes"]:
        kfs.append({"label": kf["label"], "angles": kf["angles"], "bassin": kf["pelvis"], "anchor": kf["anchor"],
                    "hold": kf["hold"], "dur": kf["dur"], "joints": kf["joints"]})
    return {"vue": t["view"], "boucle": t["loop"], "images_cles": kfs, "accessoires": t["props"],
            "contacts": t["contacts"], "exceptions_amplitude": t["rom_exceptions"], "note": t["note"]}


PROG_BASES = [
    (r"^TEST 1RM MUSCLE-UP LEST", "Test 1Rm Muscle-Up Lesté"), (r"^TEST 1RM DIP LEST", "Test 1Rm Dip Lesté"),
    (r"^TEST 1RM BACK SQUAT", "Test 1Rm Back Squat"), (r"^TEST 1RM TRACTION LEST", "Test 1Rm Traction Lestée"),
    (r"^MUSCLE-UP LESTÉ", "Muscle-up lesté"), (r"^TRACTION LESTÉE", "Traction lestée"), (r"^DIP LESTÉ", "Dips lestés"),
    (r"^BACK SQUAT", "Back squat"), (r"^Isométrie maximale — transition MU", "Isométrie de transition muscle-up"),
    (r"^Isométrie maximale — bas de dip", "Isométrie bas de dip"), (r"^Tractions PdC", "Traction pronation"),
    (r"^Dips PdC", "Dips"), (r"^Pompes PdC", "Pompes"), (r"^GtG muscle-up", "Muscle-up"),
    (r"^Contraste français — squat", "Back squat"), (r"^Contraste français — muscle-up", "Muscle-up lesté"),
    (r"^Muscle-ups PdC explosifs", "Muscle-up"), (r"^Squat pause", "Squat pause"), (r"^BILAN", "Bilan"),
    (r"^Dip — simulation", "Dips lestés"),
]
PROG_METHODS = [("cluster", "clusters"), ("séries longues", "series_longues"), ("série de référence", "serie_reference"),
                ("EMOM", "emom"), ("échelles", "echelles"), ("séries continues", "series_continues"),
                ("très léger", "tres_leger"), ("enchaîné", "enchaine"), ("GtG", "gtg"), ("Contraste", "contraste"),
                ("simulation", "simulation_competition"), ("3 angles", "isometrie_multi_angles"),
                ("explosifs", "explosif"), ("TEST 1RM", "test_1rm"), ("pause", "pause")]


def map_programme(prog, ids, v1_by_name):
    counts = Counter()
    for w in prog["weeks"]:
        for d in w["days"]:
            for x in d["exercises"]:
                counts[x["name"]] += 1
    out = {}
    for name, c in sorted(counts.items()):
        target = None
        if name in ids:
            target = name
        else:
            for pat, base in PROG_BASES:
                if re.search(pat, name):
                    target = base
                    break
        methods = [m for kw, m in PROG_METHODS if kw.lower() in name.lower()]
        out[name] = {"id": ids[target] if target else None, "methodes": methods, "occurrences": c,
                     "correspondance": "exacte" if name in ids else "analyse_du_nom"}
    return out


def dump(path, obj, compact=False):
    with open(path, "w", encoding="utf-8") as f:
        if compact:
            json.dump(obj, f, ensure_ascii=False, separators=(",", ":"))
        else:
            json.dump(obj, f, ensure_ascii=False, indent=1)
        f.write("\n")


if __name__ == "__main__":
    build(sys.argv[1], sys.argv[2], sys.argv[3])
