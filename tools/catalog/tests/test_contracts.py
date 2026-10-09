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
