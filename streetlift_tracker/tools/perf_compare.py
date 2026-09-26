#!/usr/bin/env python3
"""L6 (KT-023) — Synthèse des mesures du banc hôte, base contre candidate.

Lit les fichiers JSON Lines produits par ``test/l6_perf_bench_test.dart``
(une ligne par mesure, valeurs brutes en ms) et écrit :

- ``summary.csv`` : une ligne par (scénario, profil, sous-mesure) ;
- ``summary.md``  : le même tableau lisible.

Règle de conclusion, volontairement prudente (pas de test de signification) :

- « amélioration » : médiane candidate <= 0,90 x médiane de base ET
  intervalles interquartiles disjoints (Q3 candidate < Q1 base) ;
- « régression »   : symétrique (médiane >= 1,10 x et Q1 candidate > Q3 base) ;
- sinon « gain non démontré » (écart confondu avec la variabilité).

Avec moins de 8 observations par côté, Q1/Q3 sont remplacés par min/max
(disjonction complète exigée).

Usage :
    python3 tools/perf_compare.py DOSSIER_DES_JSONL [--base base] [--cand cand]
"""
from __future__ import annotations

import argparse
import csv
import json
import statistics
import sys
from pathlib import Path


def _quantile(sorted_values: list[float], q: float) -> float:
    if not sorted_values:
        return float("nan")
    pos = (len(sorted_values) - 1) * q
    lo = int(pos)
    hi = min(lo + 1, len(sorted_values) - 1)
    return sorted_values[lo] + (sorted_values[hi] - sorted_values[lo]) * (pos - lo)


def describe(values: list[float]) -> dict:
    v = sorted(values)
    n = len(v)
    if n == 0:
        return {"n": 0}
    return {
        "n": n,
        "median": statistics.median(v),
        "min": v[0],
        "max": v[-1],
        "q1": _quantile(v, 0.25) if n >= 8 else v[0],
        "q3": _quantile(v, 0.75) if n >= 8 else v[-1],
    }


def conclude(base: dict, cand: dict) -> str:
    if base.get("n", 0) == 0 or cand.get("n", 0) == 0:
        return "non mesuré"
    if base["median"] <= 0:
        return "gain non démontré"
    ratio = cand["median"] / base["median"]
    if ratio <= 0.90 and cand["q3"] < base["q1"]:
        return "amélioration"
    if ratio >= 1.10 and cand["q1"] > base["q3"]:
        return "régression"
    return "gain non démontré"


def load(folder: Path) -> tuple[dict, list[dict], list[dict]]:
    """(valeurs[(scénario, profil, clé)][label] -> liste, métas, échecs)."""
    values: dict = {}
    metas: list[dict] = []
    failures: list[dict] = []
    for path in sorted(folder.glob("*.jsonl")):
        for line in path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            row = json.loads(line)
            row["_file"] = path.name
            if row.get("scenario") == "meta":
                metas.append(row)
                continue
            if row.get("status") != "ok":
                failures.append(row)
                continue
            if row.get("unit") != "ms":
                # Mesures hors durée (mémoire hôte) : conservées brutes.
                key = (row["scenario"], row["profile"], "")
                values.setdefault(key, {}).setdefault(row["label"], []).extend(
                    row["values"]
                )
                continue
            data = row["values"]
            items = data.items() if isinstance(data, dict) else [("", data)]
            for sub, vals in items:
                key = (row["scenario"], row["profile"], sub)
                values.setdefault(key, {}).setdefault(row["label"], []).extend(
                    float(x) for x in vals
                )
    return values, metas, failures


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("folder")
    parser.add_argument("--base", default="base")
    parser.add_argument("--cand", default="cand")
    args = parser.parse_args(argv)
    folder = Path(args.folder)
    values, metas, failures = load(folder)
    rows = []
    for (scenario, profile, sub), sides in sorted(values.items()):
        b = describe(sides.get(args.base, []))
        c = describe(sides.get(args.cand, []))
        unit = "bytes" if scenario.startswith("ui.memory") else "ms"
        rows.append(
            {
                "scenario": scenario + (f".{sub}" if sub else ""),
                "profile": profile,
                "unit": unit,
                "base_n": b.get("n", 0),
                "base_median": round(b.get("median", float("nan")), 3),
                "base_min": round(b.get("min", float("nan")), 3),
                "base_max": round(b.get("max", float("nan")), 3),
                "cand_n": c.get("n", 0),
                "cand_median": round(c.get("median", float("nan")), 3),
                "cand_min": round(c.get("min", float("nan")), 3),
                "cand_max": round(c.get("max", float("nan")), 3),
                "ratio": (
                    round(c["median"] / b["median"], 3)
                    if b.get("n") and c.get("n") and b["median"] > 0
                    else ""
                ),
                "conclusion": (
                    "brut (hors comparaison)" if unit == "bytes" else conclude(b, c)
                ),
            }
        )
    with (folder / "summary.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()) if rows else ["scenario"])
        writer.writeheader()
        writer.writerows(rows)
    lines = [
        "# Banc hôte L6 — synthèse",
        "",
        "Mesure hôte (flutter_tester, JIT debug, sans GPU) : compare deux versions "
        "du code sur la même machine ; ce n'est pas une durée sur téléphone.",
        "",
        f"Fichiers : {', '.join(sorted(p.name for p in folder.glob('*.jsonl')))}",
        "",
        "| Scénario | Profil | Unité | Base n | Base médiane [min–max] | Cand. n | Cand. médiane [min–max] | Ratio | Conclusion |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for r in rows:
        lines.append(
            f"| {r['scenario']} | {r['profile']} | {r['unit']} | {r['base_n']} | "
            f"{r['base_median']} [{r['base_min']}–{r['base_max']}] | {r['cand_n']} | "
            f"{r['cand_median']} [{r['cand_min']}–{r['cand_max']}] | {r['ratio']} | "
            f"{r['conclusion']} |"
        )
    if failures:
        lines += ["", "## Mesures en échec", ""]
        for f in failures:
            lines.append(
                f"- {f.get('_file')} {f.get('scenario')}/{f.get('profile')} : {f.get('error')}"
            )
    if metas:
        lines += ["", "## Environnement (première ligne méta de chaque fichier)", ""]
        seen = set()
        for m in metas:
            sig = (m.get("label"), m.get("dart"))
            if sig in seen:
                continue
            seen.add(sig)
            lines.append(
                f"- {m.get('label')} : Dart {m.get('dart')} ; {m.get('os')} ; "
                f"{m.get('cpus')} CPU ; n={m.get('n')} ; échauffement={m.get('warmup')}"
            )
        lines += ["", "Inventaire des profils (compté sur les documents) :", ""]
        inv = metas[0].get("inventory", {})
        for profile, counts in inv.items():
            lines.append(f"- {profile} : {counts}")
        sizes = metas[0].get("storedBytes", {})
        lines.append(f"- Document stocké (caractères) : {sizes}")
    (folder / "summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
