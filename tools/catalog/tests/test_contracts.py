"""Outils de kalis_core : types générés et jeux de données à jour, enums du
contrat alignés sur les vocabulaires du catalogue."""
from __future__ import annotations

import gzip
import json
import subprocess
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parents[3]
TOOL = RACINE / "packages/kalis_core/tool"
sys.path.insert(0, str(TOOL))
import contracts_spec as spec  # noqa: E402
import gen_fixtures  # noqa: E402
import spec_validate  # noqa: E402


def _run(script: str) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, str(TOOL / script), "--check"], capture_output=True, text=True)


def test_types_generes_a_jour():
    r = _run("gen_contracts.py")
    assert r.returncode == 0, r.stdout + r.stderr


def test_jeux_de_donnees_a_jour():
    r = _run("gen_fixtures.py")
    assert r.returncode == 0, r.stdout + r.stderr


def test_catalogue_a_jour():
    r = subprocess.run([sys.executable, str(RACINE / "tools/catalog/compile_catalog.py"), "--check"],
                       capture_output=True, text=True)
    assert r.returncode == 0, r.stdout + r.stderr


def test_enums_alignes_sur_le_catalogue():
    cat = json.loads(gzip.decompress((RACINE / "packages/kalis_core/data/catalog_v1.json.gz").read_bytes()))
    voc = cat["vocabulaires"]
    enums = {e.name: [c for _, c in e.values] for e in spec.ENUMS}
    assert enums["CatalogDiscipline"] == voc["disciplines"]
    assert enums["ExerciseLevel"] == voc["niveaux"]
    assert sorted(enums["MovementPattern"]) == sorted(voc["schemas"])
    assert sorted(enums["MovementFamily"]) == sorted(voc["familles"])
    assert enums["MovementPlane"] == voc["plans"]
    assert enums["Articularity"] == voc["articularites"]
    assert enums["ContractionMode"] == voc["regimes"]
    assert enums["Place"] == voc["lieux"]
    assert enums["Joint"] == voc["articulations"]
    assert enums["JointStress"] == voc["contraintes"]
    assert enums["LoadType"] == voc["types_charge"]
    assert enums["MeasureUnit"] == voc["unites"]
    assert enums["Laterality"] == voc["lateralites"]
    assert enums["FractionSource"] == voc["sources_fraction"]


def test_specification_coherente():
    noms = [t.name for t in spec.TYPES] + [e.name for e in spec.ENUMS]
    assert len(set(noms)) == len(noms)
    for e in spec.ENUMS:
        assert len({i for i, _ in e.values}) == len(e.values), e.name
        assert len({c for _, c in e.values}) == len(e.values), e.name
    codes = [c for c, _, _ in spec.REASONS]
    assert len(set(codes)) == len(codes)
    for t in spec.TYPES:
        assert len({f.name for f in t.fields}) == len(t.fields), t.name
        assert (t.schema_version is not None) == any(f.name == "schemaVersion" for f in t.fields), t.name
        if t.custom:
            assert t.invariants, t.name


def test_validateur_structurel():
    ok = {"weekday": 1, "minutes": 30}
    assert spec_validate.validate("DaySlot", ok) == []
    assert spec_validate.validate("DaySlot", {"weekday": 8, "minutes": 30})
    assert spec_validate.validate("DaySlot", {"weekday": 1})
    assert spec_validate.validate("DaySlot", {**ok, "inconnu": 1})
    assert spec_validate.validate("DaySlot", {"weekday": 1, "minutes": None})


def test_flammes_python_identiques_a_la_table():
    table = {10: 0, 9: 1, 8: 1.5, 7: 2, 6: 2.5, 5: 3, 4: 3.5, 3: 4, 2: 4.5, 1: 5}
    for flammes, rir in table.items():
        assert gen_fixtures.fromrir(rir) == flammes
        assert gen_fixtures.tojir(flammes) == rir
    assert gen_fixtures.fromrir(0.5) == 9
    assert gen_fixtures.fromrir(7) == 1


def test_jeux_de_donnees_complets():
    sorties = gen_fixtures.construire()
    profils = json.loads(sorties["profiles.json"])["profiles"]
    assert len(profils) == 40
    journaux = json.loads(gzip.decompress(sorties["journals.json.gz"]))["journals"]
    assert len(journaux) == 12
    assert min(j["weeks"] for j in journaux) == 4 and max(j["weeks"] for j in journaux) == 24
    assert gen_fixtures.construire() == sorties  # déterministe


# --- 0.4.0 (lot CQ) : additivité, variantes, parcours de questions ----------

def test_parcours_a_jour():
    r = _run("gen_parcours.py")
    assert r.returncode == 0, r.stdout + r.stderr


def test_evolution_additive_depuis_0_3_0():
    """Rien de retiré, de renommé ni de changé par rapport au contrat 0.3.0 ;
    tout champ ajouté est optionnel et placé en fin de type ; aucune valeur
    n'est ajoutée à une énumération existante ; les codes de raison existants
    gardent leur rang et leurs paramètres."""
    avant = json.loads((TOOL / "contract_surface_0_3_0.json").read_text(encoding="utf-8"))
    enums = {e.name: e for e in spec.ENUMS}
    for nom, codes in avant["enums"].items():
        assert nom in enums, nom
        assert [c for _, c in enums[nom].values] == codes, nom
        assert [i for i, _ in enums[nom].values] == avant["enumIdentifiers"][nom], nom
    types = {t.name: t for t in spec.TYPES}
    for nom, ancien in avant["types"].items():
        assert nom in types, nom
        t = types[nom]
        assert t.module == ancien["module"], nom
        champs = [{"name": f.name, "type": f.type, "min": f.min, "max": f.max, "minLen": f.min_len,
                   "maxLen": f.max_len, "ref": f.ref} for f in t.fields]
        n = len(ancien["fields"])
        assert champs[:n] == ancien["fields"], nom
        for f in t.fields[n:]:
            assert f.type.endswith("?"), f"{nom}.{f.name} : un champ ajouté est optionnel"
        if nom == "AthleteProfile":
            assert (ancien["schemaVersion"], t.schema_version) == (2, 3)
            assert t.fields[0].min == 2  # le schéma 2 reste valide
        else:
            assert t.schema_version == ancien["schemaVersion"], nom
    assert [[c, p] for c, p, _ in spec.REASONS[:len(avant["reasons"])]] == avant["reasons"]
    assert len(spec.REASONS) > len(avant["reasons"])


def test_variantes_coherentes():
    enums = {e.name: [c for _, c in e.values] for e in spec.ENUMS}
    vus = 0
    for t in spec.TYPES:
        if not t.variants:
            continue
        vus += 1
        disc, regles = t.variants
        champ = next(f for f in t.fields if f.name == disc)
        assert list(regles) == enums[champ.type.split(":")[1]], t.name
        noms = {f.name: f for f in t.fields}
        for code, (requis, permis) in regles.items():
            assert not set(requis) & set(permis), (t.name, code)
            for n in requis + permis:
                assert noms[n].type.endswith("?"), (t.name, n)
    assert vus == 7


def test_validateur_structurel_variantes_et_schema():
    ok = {"exerciseId": "sl-dips-leste", "kind": "load_reps", "source": "declared", "externalLoadKg": 40.0, "reps": 3}
    assert spec_validate.validate("Benchmark", ok) == []
    assert spec_validate.validate("Benchmark", {k: v for k, v in ok.items() if k != "reps"})
    assert spec_validate.validate("Benchmark", {**ok, "seconds": 10})
    profils = json.loads((RACINE / "packages/kalis_core/test/fixtures/profiles.json").read_text(encoding="utf-8"))["profiles"]
    p2 = profils[0]["profile"]
    assert p2["schemaVersion"] == 2 and spec_validate.validate("AthleteProfile", p2) == []
    assert spec_validate.validate("AthleteProfile", {**p2, "schemaVersion": 3}) == []
    assert spec_validate.validate("AthleteProfile", {**p2, "schemaVersion": 1})
    assert spec_validate.validate("AthleteProfile", {**p2, "schemaVersion": 4})


def test_parcours_nombre_de_questions():
    import gen_parcours
    import parcours_spec
    fx = gen_parcours.fixtures()
    assert gen_parcours.controle(fx) == []
    par_cle = {p["key"]: p["expected"] for p in fx["profiles"]}
    debutant = par_cle["v3_debutant_forme_generale"]
    elite = par_cle["v3_competiteur_elite_streetlifting"]
    # Débutant : aucune question nouvelle à la création, trois reportées après la première semaine.
    assert debutant["questions"] == 16 and debutant["newQuestions"] == 0
    assert debutant["deferredIds"] == ["sleep", "stress", "outside_load"]
    assert debutant["testIds"] == ["t8_sans_test"]
    assert elite["questions"] == 29 and elite["newQuestions"] == 12 and elite["deferredIds"] == []
    assert par_cle["v3_intermediaire_musculation"]["questions"] == 27
    assert par_cle["v3_coureuse_10km"]["questions"] == 28
    assert par_cle["v3_sets_reps_avance"]["questions"] == 29
    assert "t8_sans_test" not in elite["testIds"] and "t3_max_direct" in elite["testIds"]
    # Le parcours v3 d'un débutant est plus court que le parcours G6 (17 questions du schéma 2).
    assert sum(1 for q in parcours_spec.QUESTIONS if q["since"] == 2) == 17
    # Un brouillon vide voit le parcours le plus court ; rien ne lève.
    assert len(gen_parcours.visible({})) == 16
    assert len(gen_parcours.visible({}, include_deferred=True)) == 19
    assert gen_parcours.eligible_tests({}) == ["t8_sans_test"]
    # Le poids de corps devient obligatoire pour les disciplines au poids du corps.
    poids = next(q for q in parcours_spec.QUESTIONS if q["id"] == "body_weight")
    assert not gen_parcours.evaluate(poids["requiredWhen"], debutant_profil := fx["profiles"][0]["profile"], 2026)
    assert gen_parcours.evaluate(poids["requiredWhen"], fx["profiles"][2]["profile"], 2026)
    # Chaque test guidé dit son prérequis par mouvement.
    assert all(t["requires"] for t in parcours_spec.TESTS) and len(parcours_spec.TESTS) == 10
    # Chaque question du schéma 3 est justifiée par un facteur de la revue.
    doc = (RACINE / "packages/kalis_core/docs/PROFIL_V3.md").read_text(encoding="utf-8")
    for q in parcours_spec.QUESTIONS:
        if q["since"] >= 3:
            assert "factor" in q and "effect" in q, q["id"]
            assert f"`{q['factor']}`" in doc, q["factor"]
    # Chaque référence d'un test guidé est dans la bibliographie de la revue.
    for t in parcours_spec.TESTS:
        for ref in t["refs"]:
            assert f"`{ref}`" in doc, ref


def test_textes_des_raisons_0_4_0():
    """Chaque code de raison ajouté en 0.4.0 a un texte court de Koach, dont
    les paramètres entre accolades sont ceux du registre."""
    import re
    data = json.loads((RACINE / "packages/kalis_core/data/reason_texts_fr_0_4.json").read_text(encoding="utf-8"))
    avant = json.loads((TOOL / "contract_surface_0_3_0.json").read_text(encoding="utf-8"))
    nouveaux = spec.REASONS[len(avant["reasons"]):]
    assert [t["code"] for t in data["texts"]] == [c for c, _, _ in nouveaux]
    for t, (code, params, _) in zip(data["texts"], nouveaux):
        assert 0 < len(t["fr"]) <= 110, code
        assert set(re.findall(r"\{(\w+)\}", t["fr"])) <= set(params), code
        assert t["params"] == list(params), code
        assert re.match(r"^(plan|adapt)\.[a-z][a-z0-9_]*$", code)
