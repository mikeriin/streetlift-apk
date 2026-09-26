"""Tests unitaires du pack de contenu Kalis Track v1 (KT-048).

Lancement (depuis la racine du pack) :
    python3 -m unittest discover -s tools/tests -v
Variables facultatives : KT_V1_DB et KT_PROGRAMME (chemins des .json.gz de
l'application) pour contrôler les correspondances complètes.
"""
import copy
import gzip
import json
import math
import os
import shutil
import subprocess
import sys
import unittest

PACK = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TOOLS = os.path.join(PACK, "tools")
sys.path.insert(0, TOOLS)

import build_poses  # noqa: E402
import kinematics as K  # noqa: E402
import pose_checks as PC  # noqa: E402
import validate as VAL  # noqa: E402


def _opt(env, fallback):
    p = os.environ.get(env)
    if p and os.path.exists(p):
        return p
    f = os.path.join(PACK, "tools", "tests", "fixtures", fallback)
    return f if os.path.exists(f) else None


class TestKinematics(unittest.TestCase):
    def test_standing_height_is_one(self):
        J = K.fk({"t": 0, "ft_g": 70, "ft_d": 70}, "profil")
        foot = J["pied_d"][1]
        top = J["tete"][1] + K.HEAD_R
        self.assertAlmostEqual(top - foot, 1.0, delta=0.02)

    def test_segment_lengths_constant_under_any_angles(self):
        import random
        rnd = random.Random(7)
        for view in ("profil", "face"):
            ref = None
            for _ in range(50):
                a = {k: rnd.uniform(-180, 180) for k in K.ANGLE_KEYS}
                J = K.fk(a, view)
                ls = {s: math.dist(J[p], J[q]) for s, p, q in K.SEGMENTS}
                if ref is None:
                    ref = ls
                for s in ls:
                    self.assertAlmostEqual(ls[s], ref[s], places=9)

    def test_joint_angles_standing_neutral(self):
        ja = K.joint_angles({"t": 0, "ft_g": 70, "ft_d": 70}, "profil")
        self.assertEqual(ja["coude_d"], 0)
        self.assertEqual(ja["genou_d"], 0)
        self.assertEqual(ja["hanche_d"], 0)

    def test_hanging_shoulder_flexion_180(self):
        ja = K.joint_angles({"t": 0, "ua_d": 180, "fa_d": 180}, "profil")
        self.assertAlmostEqual(ja["epaule_d"], 180)


class TestPoseChecksDetectErrors(unittest.TestCase):
    """Les contrôles doivent échouer sur des poses volontairement fausses."""

    def setUp(self):
        self.pose = build_poses.build("squat.pdc")

    def test_reference_pose_is_clean(self):
        res = PC.check_pose(self.pose)
        self.assertEqual(sum(len(v) for v in res.values()), 0, res)

    def test_length_violation_detected(self):
        p = copy.deepcopy(self.pose)
        x, y = p["keyframes"][1]["joints"]["genou_d"]
        p["keyframes"][1]["joints"]["genou_d"] = (x + 0.05, y)
        self.assertTrue(PC.check_lengths(p))

    def test_rom_violation_detected(self):
        p = copy.deepcopy(self.pose)
        p["keyframes"][1]["angles"]["sh_d"] = p["keyframes"][1]["angles"]["th_d"] + 30  # genou en hyperextension
        self.assertTrue(PC.check_rom(p))

    def test_contact_violation_detected(self):
        p = copy.deepcopy(self.pose)
        for kf in p["keyframes"]:
            kf["joints"] = {k: (v[0], v[1] + 0.1) for k, v in kf["joints"].items()}
        self.assertTrue(PC.check_contacts(p))

    def test_ground_penetration_detected(self):
        p = copy.deepcopy(self.pose)
        p["keyframes"][0]["joints"]["cheville_d"] = (0.0, -0.1)
        self.assertTrue(PC.check_ground(p))

    def test_all_templates_pass(self):
        bad = {}
        for n in build_poses.PT.REGISTRY:
            res = PC.check_pose(build_poses.build(n))
            errs = [x for v in res.values() for x in v]
            if errs:
                bad[n] = errs[:3]
        self.assertEqual(bad, {})


class TestPack(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        v1 = _opt("KT_V1_DB", "exercises_db.json.gz")
        prog = _opt("KT_PROGRAMME", "programme_v33.json.gz")
        (cls.exdoc, cls.prog, cls.poses, cls.mapping, cls.programme, cls.res, cls.pwarn,
         cls.mat, cls.gaps) = VAL.run_all(PACK, v1, prog)
        cls.has_inputs = v1 is not None and prog is not None

    def test_schema(self):
        self.assertEqual(self.res["schema"], [])

    def test_graph_no_cycle_no_orphan(self):
        self.assertEqual(self.res["graphe"], [])

    def test_prerequisites_reachable(self):
        self.assertEqual(self.res["prerequis"], [])

    def test_poses_lengths_rom_contacts(self):
        self.assertEqual(self.res["poses"], [])

    def test_interpolation_stable(self):
        self.assertEqual(self.res["interpolation"], [])

    def test_pose_coverage_100_percent(self):
        ids = {e["id"] for e in self.exdoc["exercices"]}
        self.assertEqual(ids, set(self.poses["exercices"]))

    def test_substitutions_each_compatible_place(self):
        self.assertEqual(self.res["substitutions"], [])

    def test_mapping_complete(self):
        if not self.has_inputs:
            self.skipTest("entrées v1 et programme absentes : fournir KT_V1_DB et KT_PROGRAMME")
        self.assertEqual(self.res["correspondance"], [])
        self.assertEqual(len(self.mapping["base_v1"]), 505)

    def test_required_chains_present(self):
        need = {"pompes", "tractions", "dips", "squat", "back_squat", "charniere", "gainage_ventral", "muscle_up",
                "front_lever", "planche", "equilibre_mains", "l_sit", "drapeau", "mobilite_epaules",
                "mobilite_hanches", "mobilite_chevilles"}
        self.assertTrue(need <= {c["id"] for c in self.prog["chaines"]})

    def test_push_chain_bounds(self):
        c = next(c for c in self.prog["chaines"] if c["id"] == "pompes")
        self.assertEqual(c["etapes"][0]["id"], "pompes-au-mur")
        self.assertEqual(c["etapes"][-1]["id"], "pompe-a-un-bras")

    def test_ids_stable_slugs(self):
        for e in self.exdoc["exercices"]:
            self.assertRegex(e["id"], r"^[a-z0-9]+(-[a-z0-9]+)*$")

    def test_generated_content_marked(self):
        for e in self.exdoc["exercices"]:
            self.assertIn(e["provenance"]["*"], ("genere_l9", "calcule", "kt_v1"))

    def test_no_medical_vocabulary(self):
        banned = ["tendinite", "hernie", "diagnostic", "pathologie", "lésion", "arthrose", "scoliose", "entorse",
                  "médicament", "traitement", "hypertension", "grossesse"]
        blob = json.dumps(self.exdoc, ensure_ascii=False).lower()
        for w in banned:
            self.assertNotIn(w, blob, w)

    def test_coverage_matrix_complete(self):
        self.assertEqual(len(self.mat), len(VAL.BASE_TYPES) * 4 * 3)


class TestRendererParity(unittest.TestCase):
    """Le moteur JS de référence reproduit la cinématique Python."""

    def test_js_matches_python_exact(self):
        node = shutil.which("node")
        if not node:
            self.skipTest("node absent")
        js = os.path.join(PACK, "renderer_reference", "kt_pose.js")
        with open(os.path.join(PACK, "poses.json"), encoding="utf-8") as f:
            poses = json.load(f)
        samples = []
        for name, g in list(poses["gabarits"].items())[::7]:
            for kf in g["images_cles"]:
                samples.append({"view": g["vue"], "angles": kf["angles"], "anchor": kf["anchor"], "joints": kf["joints"]})
        script = ("const K=require(%s);const S=%s;let m=0;for(const s of S){const J=K.poseOf({angles:s.angles,anchor:s.anchor},s.view);"
                  "for(const j in s.joints){m=Math.max(m,Math.abs(J[j][0]-s.joints[j][0]),Math.abs(J[j][1]-s.joints[j][1]));}}"
                  "console.log(m)") % (json.dumps(js), json.dumps(samples))
        out = subprocess.run([node, "-e", script], capture_output=True, text=True, check=True).stdout.strip()
        self.assertLess(float(out), 2e-3)


if __name__ == "__main__":
    unittest.main()
