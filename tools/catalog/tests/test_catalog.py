"""Tests de l'outil de compilation du catalogue (lot GC)."""
from __future__ import annotations

import copy
import gzip
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import compile_catalog as cc  # noqa: E402
import rules  # noqa: E402


@pytest.fixture(scope="module")
def base() -> dict:
    return cc.charger_source()[0]


@pytest.fixture(scope="module")
def catalogue(base) -> dict:
    return cc.compiler(base, cc.SHA256_SOURCE)


@pytest.fixture(scope="module")
def par_id(catalogue) -> dict:
    return {e["id"]: e for e in catalogue["exercices"]}


# --- Source et schéma de la base -------------------------------------------

def test_somme_de_controle_de_la_source():
    assert hashlib.sha256(cc.SOURCE.read_bytes()).hexdigest() == cc.SHA256_SOURCE


def test_base_valide_et_effectifs(base):
    cc.valider_base(base)
    assert len(base["exercices"]) == 1039
    assert Counter(e["discipline"] for e in base["exercices"]) == cc.NOMBRE_PAR_DISCIPLINE


@pytest.mark.parametrize("alteration, message", [
    (lambda b: b["exercices"].append(copy.deepcopy(b["exercices"][0])), "nombre"),
    (lambda b: b["exercices"][1].__setitem__("id", b["exercices"][0]["id"]), "double"),
    (lambda b: b["exercices"][0].__setitem__("discipline", "Yoga"), "discipline"),
    (lambda b: b["exercices"][0].__setitem__("categorie", "Autre"), "catégorie"),
    (lambda b: b["exercices"][0].__setitem__("niveau", "Expert"), "niveau"),
    (lambda b: b["exercices"][0]["muscles_principaux"].append("deltoïde imaginaire"), "muscle inconnu"),
    (lambda b: b["exercices"][0]["materiel"].append("trampoline"), "matériel inconnu"),
    (lambda b: b["exercices"][0].__setitem__("variante_de", "inconnu"), "variante_de"),
    (lambda b: b["exercices"][0].__setitem__("couleur", "bleu"), "champs inattendus"),
    (lambda b: b["vocabulaires"]["muscles"].pop(), "vocabulaire"),
])
def test_base_alteree_refusee(base, alteration, message):
    b = copy.deepcopy(base)
    alteration(b)
    with pytest.raises(cc.ErreurBase, match=message):
        cc.valider_base(b)


def test_muscle_dans_deux_colonnes_refuse(base):
    b = copy.deepcopy(base)
    e = b["exercices"][0]
    e["muscles_secondaires"].append(e["muscles_principaux"][0])
    with pytest.raises(cc.ErreurBase, match="dans muscles_principaux et muscles_secondaires"):
        cc.valider_base(b)


def test_cycle_variante_de_refuse(base):
    b = copy.deepcopy(base)
    a, c = b["exercices"][0], b["exercices"][1]
    a["variante_de"], c["variante_de"] = c["id"], a["id"]
    with pytest.raises(cc.ErreurBase, match="cycle"):
        cc.valider_base(b)


# --- Compilation : reproductible, à jour, base intacte ---------------------

def test_compilation_reproductible(base):
    a = cc.encoder(cc.compiler(copy.deepcopy(base), cc.SHA256_SOURCE))
    b = cc.encoder(cc.compiler(copy.deepcopy(base), cc.SHA256_SOURCE))
    assert a == b


def test_fichiers_livres_a_jour(catalogue):
    livre = json.loads(gzip.decompress(cc.SORTIE.read_bytes()).decode("utf-8"))
    assert livre == catalogue
    md, csv_ = cc.relecture(catalogue)
    assert (cc.DOCS / "RELECTURE_CATALOGUE.md").read_text(encoding="utf-8") == md
    assert (cc.DOCS / "relecture_catalogue.csv").read_text(encoding="utf-8") == csv_


def test_la_base_est_conservee_telle_quelle(base, catalogue):
    for src, out in zip(base["exercices"], catalogue["exercices"]):
        sans_calc = {k: v for k, v in out.items() if k != "calc"}
        assert sans_calc == src
    for nom, valeurs in base["vocabulaires"].items():
        assert catalogue["vocabulaires"][nom] == valeurs
    assert catalogue["source"]["sha256"] == cc.SHA256_SOURCE


# --- Champs calculés : domaines et invariants ------------------------------

def test_domaines_des_champs_calcules(catalogue):
    voc = catalogue["vocabulaires"]
    for e in catalogue["exercices"]:
        c = e["calc"]
        assert c["schema"] in voc["schemas"]
        assert c["famille"] == rules.FAMILLE_PAR_SCHEMA[c["schema"]]
        assert c["plan"] in voc["plans"]
        assert c["articularite"] in voc["articularites"]
        assert c["regime"] in voc["regimes"]
        assert isinstance(c["difficulte"], int) and 1 <= c["difficulte"] <= 10
        assert c["lieux"] and set(c["lieux"]) <= set(voc["lieux"])
        assert list(c["contraintes"]) == voc["articulations"]
        assert set(c["contraintes"].values()) <= set(voc["contraintes"])
        assert set(c["fatigue"]) == {"systemique", "locale"}
        assert all(isinstance(v, int) and 1 <= v <= 5 for v in c["fatigue"].values())
        assert c["type_charge"] in voc["types_charge"]
        assert isinstance(c["assiste"], bool)
        assert c["unite"] in voc["unites"]
        assert c["lateralite"] in voc["lateralites"]
        f = c["fraction_pdc"]
        if f is not None:
            assert c["type_charge"] in ("poids_du_corps", "lest")
            assert 0.3 <= f["valeur"] <= 1.0
            assert f["source"] in voc["sources_fraction"]
            assert (f["reference"] in catalogue["references_fraction"]) == (f["source"] != "estimee")


def test_toutes_les_categories_et_tout_le_materiel_sont_couverts(base):
    assert set(rules.SCHEMA_PAR_CATEGORIE) == set(base["vocabulaires"]["categories"])
    assert set(rules.LIEUX_PAR_MATERIEL) == set(base["vocabulaires"]["materiel"])
    assert set(rules._PLAN_BASE) == set(rules.SCHEMAS)
    assert set(rules._CONTRAINTES_BASE) == set(rules.SCHEMAS)
    assert set(rules._FATIGUE_SYS) == set(rules.SCHEMAS)


def test_difficulte_croissante_avec_le_niveau(catalogue):
    bornes = {}
    for e in catalogue["exercices"]:
        lo, hi = bornes.get(e["niveau"], (10, 1))
        bornes[e["niveau"]] = (min(lo, e["calc"]["difficulte"]), max(hi, e["calc"]["difficulte"]))
    niveaux = rules.NIVEAUX
    for a, b in zip(niveaux, niveaux[1:]):
        assert bornes[a][1] <= bornes[b][0], (a, b, bornes)
    assert bornes["Débutant"][0] == 1 and bornes["Élite"][1] == 10


def test_graphe_variante_de(catalogue, par_id):
    for e in catalogue["exercices"]:
        c = e["calc"]
        chemin = [e["id"]]
        while par_id[chemin[-1]]["variante_de"] is not None:
            chemin.append(par_id[chemin[-1]]["variante_de"])
            assert len(chemin) <= len(par_id)
        assert c["racine"] == chemin[-1]
        assert c["profondeur"] == len(chemin) - 1
        assert par_id[c["racine"]]["calc"]["profondeur"] == 0


def test_prerequis(catalogue, par_id):
    for e in catalogue["exercices"]:
        c = e["calc"]
        assert len(c["prerequis"]) <= 2 and len(set(c["prerequis"])) == len(c["prerequis"])
        for p in c["prerequis"]:
            assert p != e["id"] and p in par_id
            cp = par_id[p]["calc"]
            if c["type_charge"] == "lest":
                assert cp["type_charge"] == "poids_du_corps" and not cp["assiste"]
                assert cp["difficulte"] <= c["difficulte"]
                assert cp["famille"] == c["famille"]
            else:
                assert cp["racine"] == c["racine"]
                assert cp["difficulte"] < c["difficulte"]
    # Sans cycle : la difficulté décroît strictement hors lest, et un lest
    # ne renvoie que vers du poids du corps.
    for e in catalogue["exercices"]:
        vus, pile = set(), [e["id"]]
        while pile:
            i = pile.pop()
            for p in par_id[i]["calc"]["prerequis"]:
                assert p != e["id"]
                if p not in vus:
                    vus.add(p)
                    pile.append(p)


def test_vecteur_musculaire(catalogue):
    muscles = catalogue["vocabulaires"]["muscles"]
    assert catalogue["poids_vecteur"] == {"principal": 1.0, "secondaire": 0.5, "stabilisateur": 0.2}
    for e in catalogue["exercices"]:
        attendu = {}
        for col, w in (("muscles_stabilisateurs", 0.2), ("muscles_secondaires", 0.5), ("muscles_principaux", 1.0)):
            for m in e[col]:
                attendu[muscles.index(m)] = w
        assert e["calc"]["vecteur"] == [[k, attendu[k]] for k in sorted(attendu)]


def test_lieux_deduits_du_materiel(catalogue):
    for e in catalogue["exercices"]:
        attendu = {"salle", "maison", "exterieur"}
        for m in e["materiel"]:
            attendu &= rules.LIEUX_PAR_MATERIEL[m]
        assert set(e["calc"]["lieux"]) == attendu


def test_unite_coherente_avec_le_regime(catalogue):
    for e in catalogue["exercices"]:
        c = e["calc"]
        if c["regime"] in ("isometrique", "passif"):
            assert c["unite"] == "secondes", e["id"]
        if c["articularite"] != "non_applicable":
            assert c["regime"] in ("dynamique", "excentrique", "explosif"), e["id"]


# --- Cas types relus (une valeur attendue par règle importante) ------------

CAS_TYPES = {
    "sw-pompe": dict(schema="poussee_horizontale", type_charge="poids_du_corps", unite="repetitions",
                     articularite="polyarticulaire", lateralite="bilateral", regime="dynamique"),
    "sw-pompe-genoux": dict(type_charge="poids_du_corps"),
    "sw-dips-barres-paralleles": dict(schema="poussee_verticale_basse", plan="sagittal"),
    "mu-developpe-militaire-barre-debout": dict(schema="poussee_verticale_haute", type_charge="barre", lieux=["salle"]),
    "sl-traction-lestee": dict(schema="tirage_vertical", type_charge="lest", prerequis=["sw-traction-pronation"]),
    "sl-dips-leste": dict(schema="poussee_verticale_basse", type_charge="lest", prerequis=["sw-dips-barres-paralleles"]),
    "sl-muscle-up-leste": dict(schema="transition_muscle_up", type_charge="lest", prerequis=["cd-muscle-up-barre-strict"]),
    "sl-squat-competition": dict(schema="squat", type_charge="barre"),
    "sl-pistol-squat-leste": dict(prerequis=["sw-pistol-squat"]),
    "cs-planche": dict(schema="figure_statique_poussee", regime="isometrique", unite="secondes",
                       articularite="non_applicable", difficulte=10),
    "cs-front-lever-tuck": dict(regime="isometrique", unite="secondes"),
    "sw-traction-assistee-elastique": dict(type_charge="poids_du_corps", assiste=True),
    "mu-traction-assistee-machine-pronation": dict(type_charge="machine", assiste=True),
    "mu-developpe-couche-barre-elastiques": dict(type_charge="barre", assiste=False),
    "mu-curl-elastique": dict(type_charge="elastique"),
    "mu-rowing-inverse-smith-machine": dict(type_charge="poids_du_corps"),
    "mu-porte-sac-leste": dict(type_charge="autre"),
    "mu-leg-extension": dict(schema="extension_genou", articularite="monoarticulaire", type_charge="machine", difficulte=1),
    "mu-souleve-de-terre-conventionnel": dict(schema="charniere_hanche", fatigue={"systemique": 5, "locale": 3}),
    "mu-nordic-hamstring-curl-negatif": dict(regime="excentrique"),
    "mu-gainage-ventral-coudes": dict(regime="isometrique", unite="secondes", articularite="non_applicable"),
    "mu-mountain-climbers": dict(regime="dynamique", unite="secondes", lateralite="alterne"),
    "mu-farmer-walk": dict(schema="porte", unite="distance"),
    "mu-split-squat-bulgare-halteres": dict(lateralite="unilateral", type_charge="halteres"),
    "mu-fente-marchee-halteres": dict(lateralite="alterne", unite="distance"),
    "ca-footing-endurance-fondamentale": dict(regime="cyclique", unite="secondes", type_charge="aucune", lieux=["exterieur"]),
    "ca-sprint": dict(unite="distance", regime="explosif"),
    "ca-air-bike-calories": dict(unite="calories"),
    "ca-fractionne-400m": dict(unite="distance"),
    "ca-corde-double-unders": dict(unite="repetitions"),
    "mo-pigeon-sol": dict(regime="passif", unite="secondes", type_charge="aucune", difficulte=1, lateralite="unilateral"),
    "mo-coherence-cardiaque": dict(schema="respiration", famille="recuperation", fatigue={"systemique": 1, "locale": 1}),
    "mu-elevation-laterale-halteres": dict(plan="frontal", articularite="monoarticulaire"),
    "mu-developpe-couche-barre": dict(plan="transversal", lieux=["salle"]),
    "sw-traction-supination": dict(plan="sagittal"),
    "sw-traction-pronation": dict(plan="frontal", lieux=["salle", "maison", "exterieur"]),
    "mu-good-morning-barre": dict(contraintes_min={"lombaires": "forte"}),
    "sw-pistol-squat": dict(contraintes_min={"genou": "forte"}, lateralite="unilateral"),
    "mu-developpe-nuque-barre": dict(contraintes_min={"epaule": "forte"}),
    "mu-barre-au-front-ez": dict(contraintes_min={"coude": "forte"}),
    "cs-handstand": dict(contraintes_min={"poignet": "forte", "epaule": "forte"}),
    "mu-box-jump": dict(contraintes_min={"genou": "forte", "cheville": "forte"}, regime="explosif"),
    "sw-traction-sautee": dict(contraintes_min={"genou": "faible"}),
}


@pytest.mark.parametrize("ident", sorted(CAS_TYPES))
def test_cas_types(par_id, ident):
    c = par_id[ident]["calc"]
    for champ, attendu in CAS_TYPES[ident].items():
        if champ == "contraintes_min":
            for j, v in attendu.items():
                assert c["contraintes"][j] == v, (ident, j)
        else:
            assert c[champ] == attendu, (ident, champ, c[champ])


def test_fractions_publiees(par_id):
    f = lambda i: par_id[i]["calc"]["fraction_pdc"]  # noqa: E731
    # Suprak et al. 2011 : 69,16 % (haut) et 75,04 % (bas) ; genoux 53,56 % et 61,80 %.
    assert f("sw-pompe")["valeur"] == 0.72 and f("sw-pompe")["source"] == "publiee"
    assert f("sw-pompe-genoux")["valeur"] == 0.58
    # Ebben et al. 2011 : pieds surélevés 70-74 %, mains surélevées 55-41 %, classique 64 %.
    assert f("sw-pompe-declinee")["valeur"] == 0.81 and f("sw-pompe-declinee")["source"] == "derivee"
    assert f("sw-pompe-inclinee")["valeur"] == 0.54
    # Masses segmentaires (Winter 2009) : mains 0,6 %, avant-bras 1,6 %, pied 1,45 %, jambe 4,65 %.
    assert f("sw-dips-barres-paralleles")["valeur"] == 0.96
    assert f("sw-traction-pronation")["valeur"] == 0.97
    assert f("mu-air-squat")["valeur"] == 0.88
    assert f("sw-pistol-squat")["valeur"] == 0.94
    assert f("sl-traction-lestee")["valeur"] == 0.97
    # Ordre physique : mains surélevées < genoux < classique < pieds surélevés < dips.
    assert f("sw-pompe-inclinee")["valeur"] < f("sw-pompe-genoux")["valeur"] < f("sw-pompe")["valeur"] \
        < f("sw-pompe-declinee")["valeur"] < f("sw-dips-barres-paralleles")["valeur"]
    assert f("mu-developpe-couche-barre") is None and f("cs-planche") is None
    assert f("ca-sprint") is None and f("mu-gainage-ventral-coudes") is None


def test_norm():
    assert rules.norm("Élévation latérale à l’haltère") == "elevation laterale a l'haltere"


def test_cosinus():
    a, b = {"x": 1.0, "y": 0.5}, {"x": 1.0, "y": 0.5}
    assert abs(rules.cosinus(a, b) - 1.0) < 1e-12
    assert rules.cosinus(a, {"z": 1.0}) == 0.0
    assert rules.cosinus(a, {}) == 0.0


def test_relecture_60_exemples_et_cas_ambigus(catalogue):
    md, csv_ = cc.relecture(catalogue)
    assert "## 60 exemples tirés au hasard" in md
    bloc = md.split("## 60 exemples tirés au hasard")[1].split("## Cas ambigus")[0]
    assert sum(1 for l in bloc.splitlines() if l.startswith("| `")) == 60
    assert csv_.count("\n") == 1040
