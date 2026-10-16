"""L6 — Règles de synthèse du banc hôte (tools/perf_compare.py)."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import perf_compare  # noqa: E402


def _write(folder: Path, name: str, rows: list[dict]) -> None:
    with (folder / name).open("w", encoding="utf-8") as f:
        for row in rows:
            f.write(json.dumps(row) + "\n")


def _row(label: str, values, scenario="s", profile="p") -> dict:
    return {
        "label": label,
        "scenario": scenario,
        "profile": profile,
        "status": "ok",
        "unit": "ms",
        "values": values,
    }


class PerfCompareTest(unittest.TestCase):
    def run_compare(self, files: dict) -> tuple[int, str]:
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            for name, rows in files.items():
                _write(folder, name, rows)
            code = perf_compare.main([str(folder)])
            return code, (folder / "summary.md").read_text(encoding="utf-8")

    def test_ecart_franc_et_constant_amelioration(self):
        files = {}
        for r in (1, 2):
            files[f"base-r{r}.jsonl"] = [_row("base", [10.0 + i * 0.1 for i in range(9)])]
            files[f"cand-r{r}.jsonl"] = [_row("cand", [5.0 + i * 0.1 for i in range(9)])]
        code, text = self.run_compare(files)
        self.assertEqual(code, 0)
        self.assertIn("| amélioration |", text)

    def test_meme_code_aucune_conclusion(self):
        files = {}
        for r in (1, 2):
            values = [10.0 + (i % 3) for i in range(9)]
            files[f"base-r{r}.jsonl"] = [_row("base", values)]
            files[f"cand-r{r}.jsonl"] = [_row("cand", values)]
        _, text = self.run_compare(files)
        self.assertIn("| gain non démontré |", text)

    def test_manche_contraire_pas_de_conclusion(self):
        files = {
            "base-r1.jsonl": [_row("base", [10.0] * 9)],
            "cand-r1.jsonl": [_row("cand", [5.0] * 9)],
            "base-r2.jsonl": [_row("base", [4.0] * 9)],
            "cand-r2.jsonl": [_row("cand", [4.5] * 9)],
        }
        _, text = self.run_compare(files)
        self.assertNotIn("| amélioration |", text)

    def test_peu_d_observations_non_concluant(self):
        files = {
            "base-r1.jsonl": [_row("base", [10.0, 11.0])],
            "cand-r1.jsonl": [_row("cand", [1.0, 1.1])],
        }
        _, text = self.run_compare(files)
        self.assertIn("non concluant (n < 8)", text)

    def test_echec_et_empreinte_differente_signales(self):
        digest = {
            "label": "base",
            "scenario": "digest",
            "profile": "long",
            "status": "ok",
            "unit": "digest",
            "values": {"export": "a"},
        }
        files = {
            "base-r1.jsonl": [digest, _row("base", [1.0] * 9)],
            "cand-r1.jsonl": [
                {**digest, "label": "cand", "values": {"export": "b"}},
                {"label": "cand", "scenario": "x", "profile": "p", "status": "echec", "error": "boom"},
            ],
        }
        code, text = self.run_compare(files)
        self.assertEqual(code, 1)
        self.assertIn("DIFFÉRENT", text)
        self.assertIn("boom", text)


if __name__ == "__main__":
    unittest.main()
