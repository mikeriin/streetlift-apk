"""Tests unitaires du pack de contenu Kalis Track v2 (L9R).

Lancement (depuis la racine du pack) :
    python3 -m unittest discover -s tools/tests -v
Variables facultatives : KT_V1_DB et KT_PROGRAMME (chemins des .json.gz de l'application) pour contrôler
les correspondances complètes (505 noms v1, intitulés du programme v33).
"""
import copy
import json
import math
import os
import re
import shutil
import subprocess
import sys
import unittest

PACK = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TOOLS = os.path.join(PACK, "tools")
sys.path.insert(0, TOOLS)

import biomeca as BM  # noqa: E402
import body_model as B  # noqa: E402
import kb_muscles as KM  # noqa: E402
import kb_sources as KS  # noqa: E402
import pose_checks as PC  # noqa: E402
import pose_solver as PS  # noqa: E402
import validate as VAL  # noqa: E402


def _opt(env, fallback):
    p = os.environ.get(env)
    if p and os.path.exists(p):
        return p
    f = os.path.join(PACK, "tools", "tests", "fixtures", fallback)
    return f if os.path.exists(f) else None


class TestBodyModel(unittest.TestCase):
    def test_standing_height_is_one(self):
        J = B.fk(B.anat_to_abs({"t": 0}), "profil") if hasattr(B, "anat_to_abs") else None
        A = {k: 0.0 for k in B.ABS_KEYS}
        A["ft_g"] = A["ft_d"] = 90
        J = B.fk_abs(A, "profil")
        foot = min(J["talon_d"][1], J["pied_d"][1])
        top = J["tete"][1] + B.HEAD_R
        self.assertAlmostEqual(top - foot, 1.0, delta=0.03)

    def test_segment_lengths_constant_under_any_angles(self):
        import random
        rnd = random.Random(7)
        for view in ("profil", "face"):
            ref = None
            for _ in range(50):
                a = {k: rnd.uniform(-180, 180) for k in B.ABS_KEYS}
                J = B.fk_abs(a, view)
                ls = {s: math.dist(J[p], J[q]) for s, p, q in B.SEGMENTS if not s.startswith("pied") or view == "profil"}
                if ref is None:
                    ref = ls
                for s in ls:
                    self.assertAlmostEqual(ls[s], ref[s], places=9)

    def test_mass_fractions_sum_to_one(self):
        total = B.MASS["tete"][0] + B.MASS["tronc"][0] + 2 * sum(B.MASS[k][0] for k in ("bras", "avant_bras", "main", "cuisse", "jambe", "pied"))
        self.assertAlmostEqual(total, 1.0, delta=0.01)

    def test_rom_table_is_sane(self):
        for k, (lo, hi) in B.ROM.items():
            self.assertLess(lo, hi, k)


class TestSolverAndChecks(unittest.TestCase):
    def setUp(self):
        self.tpl = PS.build_sheet(BM.REG["squat.pdc"])

    def test_reference_sheet_is_clean(self):
        self.assertEqual(PC.check_all(self.tpl), [])

    def test_residuals_small(self):
        for kf in self.tpl["keyframes"]:
            self.assertLess(kf["residu"], 0.05)

    def test_length_violation_detected(self):
        p = copy.deepcopy(self.tpl)
        x, y = p["keyframes"][1]["joints"]["genou_d"]
        p["keyframes"][1]["joints"]["genou_d"] = (x + 0.05, y)
        self.assertTrue(PC.check_lengths(p))

    def test_rom_violation_detected(self):
        p = copy.deepcopy(self.tpl)
        p["keyframes"][1]["angles_articulaires"]["genou_d"] = 170
        self.assertTrue(PC.check_rom(p))

    def test_ground_penetration_detected(self):
        p = copy.deepcopy(self.tpl)
        p["keyframes"][0]["joints"]["genou_d"] = (0.0, -0.1)
        self.assertTrue(PC.check_contacts_and_ground(p))

    def test_balance_violation_detected(self):
        p = copy.deepcopy(self.tpl)
        for kf in p["keyframes"]:
            kf["joints"] = {k: ((v[0] + 0.5, v[1]) if k not in ("talon_d", "pied_d", "talon_g", "pied_g") else v) for k, v in kf["joints"].items()}
        self.assertTrue(PC.check_balance(p))

    def test_all_sheets_pass(self):
        bad = {}
        for n, spec in BM.REG.items():
            t = PS.build_sheet(spec)
            errs = PC.check_all(t)
            if errs:
                bad[n] = errs[:3]
        self.assertEqual(bad, {})

    def test_every_sheet_has_biomech_sheet(self):
        for n, spec in BM.REG.items():
            self.assertTrue(spec["phases"], n)
            self.assertTrue(spec["sources"], n)
            self.assertTrue(spec["articulations_motrices"], n)


class TestTaxonomy(unittest.TestCase):
    def test_alias_expand_to_known_ids(self):
        ids = {m["id"] for m in KM.MUSCLES}
        for a, targets in KM.ALIAS.items():
            for t in KM.expand([a]):
                self.assertIn(t, ids, a)

    def test_every_archetype_has_two_sources(self):
        for k, v in KS.SOURCES.items():
            self.assertGreaterEqual(v.get("nb_sources_concordantes", 0), 2, k)

    def test_every_archetype_muscles_expand(self):
        for k in KS.SOURCES:
            prim, sec, stab = KS.muscles_for(k)
            self.assertTrue(prim, k)
            self.assertFalse(set(prim) & set(sec), k)


class TestPack(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        v1 = _opt("KT_V1_DB", "exercises_db.json.gz")
        prog = _opt("KT_PROGRAMME", "programme_v33.json.gz")
        (cls.exdoc, cls.prog, cls.poses, cls.mapping, cls.programme, cls.res, cls.warns,
         cls.mat, cls.gaps) = VAL.run_all(PACK, v1, prog)
        cls.has_inputs = v1 is not None and prog is not None

    def test_schema(self):
        self.assertEqual(self.res["schema"], [])

    def test_taxonomy_and_atlas(self):
        self.assertEqual(self.res["taxonomie"], [])
        self.assertEqual(self.res["atlas"], [])

    def test_sources(self):
        self.assertEqual(self.res["sources"], [])
        self.assertEqual(self.warns["sources"], [])

    def test_graph_no_cycle_no_orphan(self):
        self.assertEqual(self.res["graphe"], [])

    def test_prerequisites_reachable(self):
        self.assertEqual(self.res["prerequis"], [])

    def test_poses(self):
        self.assertEqual(self.res["poses"], [])

    def test_statuts(self):
        self.assertEqual(self.res["statuts"], [])

    def test_pose_entry_for_every_exercise(self):
        ids = {e["id"] for e in self.exdoc["exercices"]}
        self.assertEqual(ids, set(self.poses["exercices"]))

    def test_substitutions_each_compatible_place(self):
        self.assertEqual(self.res["substitutions"], [])

    def test_mapping_complete(self):
        if not self.has_inputs:
            self.skipTest("entrées v1 et programme absentes : fournir KT_V1_DB et KT_PROGRAMME")
        self.assertEqual(self.res["correspondance"], [])
        self.assertEqual(len(self.mapping["base_v1"]), 505)

    def test_versions(self):
        self.assertEqual(self.exdoc["version"], "2.0.0")
        self.assertEqual(self.poses["version"], "2.0.0")

    def test_required_chains_present(self):
        need = {"pompes", "tractions", "dips", "squat", "back_squat", "charniere", "gainage_ventral", "muscle_up",
                "front_lever", "planche", "equilibre_mains", "l_sit", "drapeau", "mobilite_epaules",
                "mobilite_hanches", "mobilite_chevilles"}
        self.assertTrue(need <= {c["id"] for c in self.prog["chaines"]})

    def test_ids_stable_slugs(self):
        for e in self.exdoc["exercices"]:
            self.assertRegex(e["id"], r"^[a-z0-9]+(-[a-z0-9]+)*$")

    def test_muscle_fields_use_taxonomy_and_sources(self):
        for e in self.exdoc["exercices"]:
            self.assertEqual(e["provenance"]["muscles_primaires"], "sources_croisees")
            self.assertGreaterEqual(len(e["sources"]), 2, e["id"])

    def test_generated_content_marked(self):
        for e in self.exdoc["exercices"]:
            self.assertIn(e["provenance"]["*"], ("genere_l9r", "genere_l9", "calcule", "kt_v1"))

    def test_no_medical_vocabulary(self):
        banned = ["tendinite", "hernie", "diagnostic", "pathologie", "lésion", "arthrose", "scoliose", "entorse",
                  "médicament", "traitement", "hypertension", "grossesse"]
        blob = json.dumps(self.exdoc, ensure_ascii=False).lower()
        for w in banned:
            self.assertNotIn(w, blob, w)

    def test_coverage_matrix_complete(self):
        self.assertEqual(len(self.mat), len(VAL.BASE_TYPES) * 4 * 3)

    def test_priority_150_have_status(self):
        rows = VAL.priority_list(self.exdoc, self.prog, self.mapping)
        self.assertEqual(len(rows), 150)
        for _, eid, _, _ in rows:
            self.assertIn(self.poses["exercices"][eid]["statut"], VAL.STATUTS)

    def test_indisponible_have_reason(self):
        for eid, p in self.poses["exercices"].items():
            if p["statut"] != "disponible":
                self.assertTrue(p["motif"], eid)


class TestRendererParity(unittest.TestCase):
    """Le moteur JS de référence reproduit la cinématique Python (mêmes positions depuis les mêmes angles)."""

    def test_js_matches_python(self):
        node = shutil.which("node")
        if not node:
            self.skipTest("node absent")
        js = os.path.join(PACK, "renderer_reference", "kt_pose.js")
        with open(os.path.join(PACK, "poses.json"), encoding="utf-8") as f:
            poses = json.load(f)
        samples = []
        for name, g in list(poses["gabarits"].items())[::5]:
            for kf in g["images_cles"]:
                samples.append({"view": g["vue"], "angles": kf["angles"], "anchor": kf["anchor"], "joints": kf["joints"]})
        script = ("const K=require(%s);const S=%s;let m=0;for(const s of S){const J=K.poseOf({angles:s.angles,anchor:s.anchor},s.view);"
                  "for(const j in s.joints){m=Math.max(m,Math.abs(J[j][0]-s.joints[j][0]),Math.abs(J[j][1]-s.joints[j][1]));}}"
                  "console.log(m)") % (json.dumps(js), json.dumps(samples))
        out = subprocess.run([node, "-e", script], capture_output=True, text=True, check=True).stdout.strip()
        self.assertLess(float(out), 2e-3)

    def test_atlas_svg_ids_unique_and_themed(self):
        with open(os.path.join(PACK, "atlas.svg"), encoding="utf-8") as f:
            svg = f.read()
        ids = re.findall(r'id="([^"]+)"', svg)
        self.assertEqual(len(ids), len(set(ids)))
        self.assertIn("currentColor", svg)


if __name__ == "__main__":
    unittest.main()
