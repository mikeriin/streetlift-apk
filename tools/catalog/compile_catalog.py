#!/usr/bin/env python3
"""Compile la base d'exercices v1.1 en catalogue Kalis Track (lot GC).

    python3 tools/catalog/compile_catalog.py            # écrit le catalogue et la relecture
    python3 tools/catalog/compile_catalog.py --check    # vérifie que les fichiers sont à jour

Entrée : packages/kalis_core/data/source/base_exercices_v1.1.0.json
Sorties : packages/kalis_core/data/catalog_v1.json.gz (la base + champs
calculés par tools/catalog/rules.py), packages/kalis_core/docs/
RELECTURE_CATALOGUE.md et relecture_catalogue.csv.

Python plutôt que Dart : l'outil tourne dans la session de lot (pas de SDK
Dart local) comme dans la CI (Python 3.11), ce qui permet de lire les
distributions avant de livrer ; le paquet Dart revérifie le résultat.
Reproductible : aucune horloge, aucun hasard non seedé, gzip sans date.
"""
from __future__ import annotations

import argparse
import csv
import gzip
import hashlib
import io
import json
import random
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import rules  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
SOURCE = RACINE / "packages/kalis_core/data/source/base_exercices_v1.1.0.json"
SORTIE = RACINE / "packages/kalis_core/data/catalog_v1.json.gz"
DOCS = RACINE / "packages/kalis_core/docs"
SHA256_SOURCE = "1a44c2b059389143f682b5e6b050d6382f795b446bb8ce3dae915d10c59b01f6"
CATALOG_SCHEMA = 1
GRAINE_RELECTURE = 20261001

CHAMPS = [
    "id", "nom", "alias", "discipline", "categorie", "variante_de", "niveau",
    "muscles_principaux", "muscles_secondaires", "muscles_stabilisateurs", "muscles_etires",
    "points_cles", "erreurs_frequentes", "respiration", "materiel",
]
NOMBRE_PAR_DISCIPLINE = {
    "Musculation": 448, "Street workout": 109, "Streetlifting": 61,
    "Calisthénie statique": 100, "Calisthénie dynamique": 110, "CrossFit / WOD": 54,
    "Cardio": 47, "Mobilité": 110,
}


class ErreurBase(ValueError):
    pass


def valider_base(base: dict) -> None:
    """Schéma de toute la base : vocabulaires fermés, id uniques, un muscle
    dans une seule colonne, `variante_de` existant et sans cycle."""
    voc = base["vocabulaires"]
    attendus = {"disciplines": 8, "niveaux": 4, "categories": 56, "muscles": 56, "materiel": 68}
    for nom, n in attendus.items():
        if len(voc[nom]) != n or len(set(voc[nom])) != n:
            raise ErreurBase(f"vocabulaire {nom} : {len(voc[nom])} valeurs, {n} attendues")
    exercices = base["exercices"]
    if base["nombre"] != len(exercices):
        raise ErreurBase("champ nombre incohérent")
    ids = [e.get("id") for e in exercices]
    if len(set(ids)) != len(ids):
        raise ErreurBase("id en double : " + ", ".join(k for k, v in Counter(ids).items() if v > 1))
    connus = set(ids)
    for e in exercices:
        i = e.get("id")
        if list(e.keys()) != CHAMPS:
            raise ErreurBase(f"{i} : champs inattendus {sorted(set(e) ^ set(CHAMPS))}")
        if not isinstance(i, str) or not i or i != i.strip().lower() or " " in i:
            raise ErreurBase(f"id invalide : {i!r}")
        if not e["nom"].strip():
            raise ErreurBase(f"{i} : nom vide")
        if e["discipline"] not in voc["disciplines"]:
            raise ErreurBase(f"{i} : discipline inconnue")
        if e["categorie"] not in voc["categories"]:
            raise ErreurBase(f"{i} : catégorie inconnue")
        if e["niveau"] not in voc["niveaux"]:
            raise ErreurBase(f"{i} : niveau inconnu")
        vus: dict[str, str] = {}
        for col in ("muscles_principaux", "muscles_secondaires", "muscles_stabilisateurs"):
            for m in e[col]:
                if m not in voc["muscles"]:
                    raise ErreurBase(f"{i} : muscle inconnu {m!r}")
                if m in vus:
                    raise ErreurBase(f"{i} : {m!r} dans {vus[m]} et {col}")
                vus[m] = col
        if len(set(e["muscles_etires"])) != len(e["muscles_etires"]):
            raise ErreurBase(f"{i} : muscle étiré en double")
        for m in e["muscles_etires"]:
            if m not in voc["muscles"]:
                raise ErreurBase(f"{i} : muscle étiré inconnu {m!r}")
        if not e["materiel"] or len(set(e["materiel"])) != len(e["materiel"]):
            raise ErreurBase(f"{i} : matériel vide ou en double")
        for m in e["materiel"]:
            if m not in voc["materiel"]:
                raise ErreurBase(f"{i} : matériel inconnu {m!r}")
        for col in ("alias", "points_cles", "erreurs_frequentes"):
            if not isinstance(e[col], list) or any(not isinstance(x, str) for x in e[col]):
                raise ErreurBase(f"{i} : {col} invalide")
        if not isinstance(e["respiration"], str):
            raise ErreurBase(f"{i} : respiration invalide")
        v = e["variante_de"]
        if v is not None and (v not in connus or v == i):
            raise ErreurBase(f"{i} : variante_de inconnue ou réflexive ({v!r})")
    parents = {e["id"]: e["variante_de"] for e in exercices}
    for i in ids:
        vu = set()
        j = i
        while j is not None:
            if j in vu:
                raise ErreurBase(f"cycle variante_de autour de {i}")
            vu.add(j)
            j = parents[j]


def racine_et_profondeur(i: str, parents: dict[str, str | None]) -> tuple[str, int]:
    p = 0
    while parents[i] is not None:
        i = parents[i]
        p += 1
    return i, p


def compiler(base: dict, sha256: str) -> dict:
    valider_base(base)
    exercices = base["exercices"]
    par_id = {e["id"]: e for e in exercices}
    parents = {e["id"]: e["variante_de"] for e in exercices}
    muscles = base["vocabulaires"]["muscles"]
    index_muscle = {m: k for k, m in enumerate(muscles)}

    calc: dict[str, dict] = {}
    for e in exercices:
        sch = rules.schema(e)
        reg = rules.regime(e, sch)
        typ = rules.type_charge(e, sch)
        art = rules.articularite(e, sch, reg)
        parent = par_id[e["variante_de"]] if e["variante_de"] else None
        racine, profondeur = racine_et_profondeur(e["id"], parents)
        vec = rules.vecteur(e)
        calc[e["id"]] = {
            "schema": sch,
            "famille": rules.FAMILLE_PAR_SCHEMA[sch],
            "plan": rules.plan(e, sch),
            "articularite": art,
            "regime": reg,
            "difficulte": rules.difficulte(e, sch, typ, parent),
            "lieux": rules.lieux(e),
            "contraintes": rules.contraintes(e, sch, typ),
            "prerequis": [],
            "fatigue": rules.fatigue(e, sch, typ, reg, art),
            "type_charge": typ,
            "assiste": rules.assiste(e),
            "fraction_pdc": rules.fraction_pdc(e, sch, typ, reg),
            "unite": rules.unite(e, sch, reg),
            "lateralite": rules.lateralite(e),
            "racine": racine,
            "profondeur": profondeur,
            "vecteur": [[index_muscle[m], vec[m]] for m in sorted(vec, key=index_muscle.get)],
        }

    # Prérequis (paliers conseillés avant l'exercice) :
    # - hors lest : jusqu'à deux exercices de la même famille `variante_de`,
    #   de difficulté strictement inférieure : les ancêtres d'abord (du
    #   parent vers la racine), puis les plus proches en difficulté ;
    # - lest : l'exercice au poids du corps non assisté de la même famille de
    #   mouvement le plus proche (cosinus des vecteurs musculaires + 0,5 si
    #   même schéma + 0,2 × recouvrement du matériel hors lest + 0,6 si le
    #   nom commence par le même mot + 0,3 si même latéralité), de
    #   difficulté inférieure ou égale ; une racine de chaîne est préférée
    #   si son score atteint 85 % du meilleur. Les variantes lestées d'un
    #   même mouvement ne sont pas des paliers les unes des autres.
    familles: dict[str, list[str]] = {}
    for i, c in calc.items():
        familles.setdefault(c["racine"], []).append(i)
    vecteurs = {e["id"]: rules.vecteur(e) for e in exercices}
    for e in exercices:
        i = e["id"]
        c = calc[i]
        if c["type_charge"] == "lest":
            candidats = [
                j for j, cj in calc.items()
                if cj["famille"] == c["famille"] and cj["type_charge"] == "poids_du_corps"
                and not cj["assiste"] and cj["difficulte"] <= c["difficulte"]
                and (cj["regime"] == "isometrique") == (c["regime"] == "isometrique")
            ]
            lests = {"ceinture de lest", "gilet lesté", "sac à dos lesté", "disques", "haltères",
                     "kettlebell", "magnésie", "chaînes", "élastique", "box / plinth"}
            mat_i = set(e["materiel"]) - lests or {"aucun (sol)"}
            premier_mot = rules.norm(e["nom"]).split()[0]

            def score(j: str) -> float:
                mat_j = set(par_id[j]["materiel"])
                jaccard = len(mat_i & mat_j) / len(mat_i | mat_j)
                meme_schema = 1.0 if calc[j]["schema"] == c["schema"] else 0.0
                meme_mot = 0.6 if rules.norm(par_id[j]["nom"]).split()[0] == premier_mot else 0.0
                meme_cote = 0.3 if calc[j]["lateralite"] == c["lateralite"] else 0.0
                return (rules.cosinus(vecteurs[i], vecteurs[j]) + 0.5 * meme_schema + 0.2 * jaccard
                        + meme_mot + meme_cote)

            sc = {j: score(j) for j in candidats}
            candidats.sort(key=lambda j: (-round(sc[j], 3), -calc[j]["difficulte"], j))
            racines = [j for j in candidats if calc[j]["profondeur"] == 0]
            if racines and sc[racines[0]] >= 0.85 * sc[candidats[0]]:
                candidats = racines
            c["prerequis"] = candidats[:1]
        else:
            ancetres = []
            a = parents[i]
            while a is not None:
                ancetres.append(a)
                a = parents[a]
            plus_faciles = [j for j in familles[c["racine"]] if calc[j]["difficulte"] < c["difficulte"]]
            plus_faciles.sort(key=lambda j: (
                ancetres.index(j) if j in ancetres else len(ancetres),
                -calc[j]["difficulte"], calc[j]["assiste"], j))
            c["prerequis"] = plus_faciles[:2]

    return {
        "schema": CATALOG_SCHEMA,
        "regles_version": rules.RULES_VERSION,
        "source": {
            "version": base["version"],
            "date": base["date"],
            "langue": base["langue"],
            "nombre": base["nombre"],
            "sha256": sha256,
        },
        "vocabulaires": {
            **base["vocabulaires"],
            "schemas": rules.SCHEMAS,
            "familles": rules.FAMILLES,
            "plans": rules.PLANS,
            "articularites": rules.ARTICULARITES,
            "regimes": ["dynamique", "isometrique", "excentrique", "explosif", "cyclique", "passif"],
            "lieux": rules.LIEUX,
            "articulations": rules.JOINTS,
            "contraintes": ["faible", "moyenne", "forte"],
            "types_charge": rules.TYPES_CHARGE,
            "unites": rules.UNITES,
            "lateralites": rules.LATERALITES,
            "sources_fraction": ["publiee", "derivee", "estimee"],
        },
        "poids_vecteur": {
            "principal": rules.POIDS_PRINCIPAL,
            "secondaire": rules.POIDS_SECONDAIRE,
            "stabilisateur": rules.POIDS_STABILISATEUR,
        },
        "references_fraction": rules.REFS_FRACTION,
        "exercices": [{**e, "calc": calc[e["id"]]} for e in exercices],
    }


def encoder(catalogue: dict) -> bytes:
    texte = json.dumps(catalogue, ensure_ascii=False, separators=(",", ":"))
    tampon = io.BytesIO()
    with gzip.GzipFile(fileobj=tampon, mode="wb", compresslevel=9, mtime=0, filename="") as f:
        f.write(texte.encode("utf-8"))
    return tampon.getvalue()


# ---------------------------------------------------------------------------
# Relecture pour le propriétaire
# ---------------------------------------------------------------------------

def cas_ambigus(catalogue: dict) -> list[tuple[str, str, str]]:
    """(id, nom, raison) des cas que les règles tranchent sans certitude."""
    out = []
    for e in catalogue["exercices"]:
        c = e["calc"]
        n = rules.norm(e["nom"])
        def note(r: str) -> None:
            out.append((e["id"], e["nom"], r))
        if not c["lieux"]:
            note("aucun lieu commun à tout le matériel")
        if "piscine" in e["materiel"]:
            note("piscine classée « salle » (complexe sportif)")
        if c["fraction_pdc"] and c["fraction_pdc"]["source"] == "estimee":
            note(f"fraction du poids du corps estimée ({c['fraction_pdc']['valeur']})")
        if c["assiste"] and c["fraction_pdc"]:
            note("exercice assisté : la fraction est celle du mouvement non assisté")
        if c["type_charge"] == "autre":
            note("type de charge « autre » (" + ", ".join(e["materiel"]) + ")")
        if c["schema"] in ("compression",) and c["regime"] == "isometrique" and "compression" in n:
            note("compression assise : comptée en secondes (tenue), parfois travaillée en répétitions")
        if c["plan"] == "multiple" and c["famille"] not in ("mobilite", "recuperation", "conditionnement"):
            note("plan « multiple » (pas de plan dominant net)")
        if c["schema"] == "poussee_inclinee":
            note("poussée inclinée : schéma distinct, entre horizontale et verticale")
        if e["discipline"] == "Calisthénie statique" and rules.has(n, "skin the cat", "compression"):
            note("classé isométrique par la discipline (Calisthénie statique)")
        if c["difficulte"] in (3, 6, 8) and e["niveau"] in ("Intermédiaire", "Avancé", "Élite") and c["difficulte"] == {"Intermédiaire": 3, "Avancé": 6, "Élite": 8}[e["niveau"]]:
            note(f"difficulté au plancher de son niveau ({c['difficulte']})")
    return out


def relecture(catalogue: dict) -> tuple[str, str]:
    ex = catalogue["exercices"]
    L: list[str] = []
    w = L.append
    src = catalogue["source"]
    w("# Relecture du catalogue compilé (kalis_core, lot GC)")
    w("")
    w(f"Source : base v{src['version']} du {src['date']}, {src['nombre']} exercices, SHA-256 `{src['sha256']}`.")
    w(f"Règles : `tools/catalog/rules.py` version {catalogue['regles_version']} ; schéma du catalogue : {catalogue['schema']}.")
    w("Fichier généré par `tools/catalog/compile_catalog.py` — ne pas modifier à la main.")
    w("")
    w("Tous les champs ci-dessous sont **calculés par règles** (CONTRAT.md, § Catalogue). Le contenu")
    w("sportif n'a pas été relu par un professionnel diplômé. Pour corriger un cas : signaler l'id et le")
    w("champ ; la correction passe par une règle (jamais par une valeur saisie à la main).")
    w("")

    def distribution(titre: str, valeurs: list, ordre: list | None = None) -> None:
        w(f"## {titre}")
        w("")
        w("| Valeur | Exercices | Part |")
        w("| --- | ---: | ---: |")
        c = Counter(valeurs)
        cles = ordre if ordre is not None else sorted(c, key=lambda k: (-c[k], str(k)))
        for k in cles:
            if c.get(k, 0) == 0 and ordre is None:
                continue
            w(f"| {k} | {c.get(k, 0)} | {100 * c.get(k, 0) / len(valeurs):.1f} % |")
        w("")

    distribution("Schéma de mouvement", [e["calc"]["schema"] for e in ex])
    distribution("Famille", [e["calc"]["famille"] for e in ex])
    distribution("Plan dominant", [e["calc"]["plan"] for e in ex], rules.PLANS)
    distribution("Poly- ou mono-articulaire", [e["calc"]["articularite"] for e in ex], rules.ARTICULARITES)
    distribution("Régime de contraction", [e["calc"]["regime"] for e in ex])
    distribution("Difficulté (1-10)", [e["calc"]["difficulte"] for e in ex], list(range(1, 11)))
    w("### Difficulté par niveau de la base")
    w("")
    w("| Niveau | " + " | ".join(str(d) for d in range(1, 11)) + " |")
    w("| --- |" + " ---: |" * 10)
    for niv in rules.NIVEAUX:
        c = Counter(e["calc"]["difficulte"] for e in ex if e["niveau"] == niv)
        w(f"| {niv} | " + " | ".join(str(c.get(d, 0)) for d in range(1, 11)) + " |")
    w("")
    distribution("Lieux possibles (un exercice peut en avoir plusieurs)", [l for e in ex for l in e["calc"]["lieux"]] , rules.LIEUX)
    w("Part calculée sur le total des lieux cités. Exercices par lieu : " + ", ".join(
        f"{l} {sum(1 for e in ex if l in e['calc']['lieux'])}" for l in rules.LIEUX) + ".")
    w("")
    w("## Contraintes articulaires")
    w("")
    w("| Articulation | faible | moyenne | forte |")
    w("| --- | ---: | ---: | ---: |")
    for j in rules.JOINTS:
        c = Counter(e["calc"]["contraintes"][j] for e in ex)
        w(f"| {j} | {c['faible']} | {c['moyenne']} | {c['forte']} |")
    w("")
    w("## Coût de fatigue (1-5)")
    w("")
    w("| Coût | 1 | 2 | 3 | 4 | 5 |")
    w("| --- | ---: | ---: | ---: | ---: | ---: |")
    for k in ("systemique", "locale"):
        c = Counter(e["calc"]["fatigue"][k] for e in ex)
        w(f"| {k} | " + " | ".join(str(c.get(v, 0)) for v in range(1, 6)) + " |")
    w("")
    distribution("Type de charge", [e["calc"]["type_charge"] for e in ex], rules.TYPES_CHARGE)
    distribution("Unité", [e["calc"]["unite"] for e in ex], rules.UNITES)
    distribution("Latéralité", [e["calc"]["lateralite"] for e in ex], rules.LATERALITES)
    w("## Fraction du poids du corps")
    w("")
    fr = [e for e in ex if e["calc"]["fraction_pdc"]]
    w(f"{len(fr)} exercices ont une fraction ; {len(ex) - len(fr)} n'en ont pas (charge externe, levier, gainage, cardio, mobilité).")
    w("")
    w("| Fraction | Source | Référence | Exercices | Exemple |")
    w("| ---: | --- | --- | ---: | --- |")
    groupes: dict[tuple, list] = {}
    for e in fr:
        f = e["calc"]["fraction_pdc"]
        groupes.setdefault((f["valeur"], f["source"], f["reference"] or "—", f["note"]), []).append(e)
    for (v, s, r, note), es in sorted(groupes.items(), key=lambda kv: (-kv[0][0], kv[0][1], kv[0][3])):
        w(f"| {v:.2f} | {s} | {r} | {len(es)} | {es[0]['nom']} — {note} |")
    w("")
    w("Références : " + " ; ".join(f"`{k}` = {v}" for k, v in catalogue["references_fraction"].items()) + ".")
    w("")
    w("## Prérequis et chaînes `variante_de`")
    w("")
    racines = Counter(e["calc"]["racine"] for e in ex)
    w(f"{len(racines)} familles ; plus grande : `{racines.most_common(1)[0][0]}` ({racines.most_common(1)[0][1]} exercices) ; "
      f"profondeur maximale : {max(e['calc']['profondeur'] for e in ex)} ; "
      f"{sum(1 for e in ex if e['calc']['prerequis'])} exercices ont au moins un prérequis.")
    w("")

    rnd = random.Random(GRAINE_RELECTURE)
    echantillon = sorted(rnd.sample(range(len(ex)), 60))
    w(f"## 60 exemples tirés au hasard (graine {GRAINE_RELECTURE})")
    w("")
    w("| Id | Nom | Niveau | Schéma | Plan | Art. | Régime | Diff. | Lieux | Charge | Unité | Lat. | Fatigue S/L | Fraction | Contraintes ≥ moyenne | Prérequis |")
    w("| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |")
    abbr_art = {"polyarticulaire": "poly", "monoarticulaire": "mono", "non_applicable": "—"}
    for k in echantillon:
        e = ex[k]
        c = e["calc"]
        cont = ", ".join(f"{j} {v}" for j, v in c["contraintes"].items() if v != "faible") or "—"
        fra = f"{c['fraction_pdc']['valeur']:.2f} ({c['fraction_pdc']['source']})" if c["fraction_pdc"] else "—"
        w(f"| `{e['id']}` | {e['nom']} | {e['niveau']} | {c['schema']} | {c['plan']} | {abbr_art[c['articularite']]} | {c['regime']} | "
          f"{c['difficulte']} | {', '.join(c['lieux']) or '—'} | {c['type_charge']}{' (assisté)' if c['assiste'] else ''} | {c['unite']} | {c['lateralite']} | "
          f"{c['fatigue']['systemique']}/{c['fatigue']['locale']} | {fra} | {cont} | {', '.join('`'+p+'`' for p in c['prerequis']) or '—'} |")
    w("")
    amb = cas_ambigus(catalogue)
    w(f"## Cas ambigus ({len(amb)})")
    w("")
    w("Cas que les règles tranchent sans certitude ; à relire en priorité.")
    w("")
    par_raison: dict[str, list] = {}
    for i, nom, r in amb:
        cle = r.split(" (")[0] if r.startswith(("fraction", "type de charge", "difficulté")) else r
        par_raison.setdefault(cle, []).append((i, nom, r))
    for cle in sorted(par_raison):
        items = par_raison[cle]
        w(f"### {cle} — {len(items)}")
        w("")
        for i, nom, r in items:
            detail = r[len(cle):].strip()
            w(f"- `{i}` — {nom}{' ' + detail if detail else ''}")
        w("")

    tampon = io.StringIO()
    wr = csv.writer(tampon, lineterminator="\n")
    wr.writerow(["id", "nom", "discipline", "categorie", "niveau", "variante_de", "schema", "famille", "plan",
                 "articularite", "regime", "difficulte", "lieux", "type_charge", "assiste", "unite", "lateralite",
                 "fatigue_systemique", "fatigue_locale", "fraction_pdc", "fraction_source", *rules.JOINTS,
                 "prerequis", "racine", "profondeur"])
    for e in ex:
        c = e["calc"]
        f = c["fraction_pdc"]
        wr.writerow([e["id"], e["nom"], e["discipline"], e["categorie"], e["niveau"], e["variante_de"] or "",
                     c["schema"], c["famille"], c["plan"], c["articularite"], c["regime"], c["difficulte"],
                     " ".join(c["lieux"]), c["type_charge"], int(c["assiste"]), c["unite"], c["lateralite"],
                     c["fatigue"]["systemique"], c["fatigue"]["locale"], f["valeur"] if f else "", f["source"] if f else "",
                     *[c["contraintes"][j] for j in rules.JOINTS], " ".join(c["prerequis"]), c["racine"], c["profondeur"]])
    return "\n".join(L) + "\n", tampon.getvalue()


def charger_source() -> tuple[dict, str]:
    octets = SOURCE.read_bytes()
    sha = hashlib.sha256(octets).hexdigest()
    if sha != SHA256_SOURCE:
        raise ErreurBase(f"somme de contrôle de la source inattendue : {sha}")
    return json.loads(octets.decode("utf-8")), sha


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true", help="vérifie que les sorties sont à jour")
    args = ap.parse_args()
    base, sha = charger_source()
    catalogue = compiler(base, sha)
    md, csv_ = relecture(catalogue)
    if args.check:
        ok = True
        actuel = json.loads(gzip.decompress(SORTIE.read_bytes()).decode("utf-8")) if SORTIE.exists() else None
        if actuel != catalogue:
            print("catalog_v1.json.gz n'est pas à jour"); ok = False
        for chemin, attendu in ((DOCS / "RELECTURE_CATALOGUE.md", md), (DOCS / "relecture_catalogue.csv", csv_)):
            if not chemin.exists() or chemin.read_text(encoding="utf-8") != attendu:
                print(f"{chemin.name} n'est pas à jour"); ok = False
        print("à jour" if ok else "relancer tools/catalog/compile_catalog.py")
        return 0 if ok else 1
    SORTIE.parent.mkdir(parents=True, exist_ok=True)
    DOCS.mkdir(parents=True, exist_ok=True)
    SORTIE.write_bytes(encoder(catalogue))
    (DOCS / "RELECTURE_CATALOGUE.md").write_text(md, encoding="utf-8")
    (DOCS / "relecture_catalogue.csv").write_text(csv_, encoding="utf-8")
    print(f"{len(catalogue['exercices'])} exercices → {SORTIE.relative_to(RACINE)} ({SORTIE.stat().st_size} octets)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
