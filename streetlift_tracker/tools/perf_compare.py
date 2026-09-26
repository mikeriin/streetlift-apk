#!/usr/bin/env python3
"""L6 (KT-023) — Synthèse des mesures du banc hôte, base contre candidate.

Lit les fichiers JSON Lines produits par ``test/l6_perf_bench_test.dart``
(une ligne par mesure, valeurs brutes en ms) et écrit :

- ``summary.csv`` : une ligne par (scénario, profil, sous-mesure) ;
- ``summary.md``  : le même tableau lisible.

Règle de conclusion, volontairement prudente (pas de test de signification),
calibrée sur une comparaison A/A (même code des deux côtés) où des écarts de
médiane jusqu'à ~27 % sont apparus entre processus :

- « amélioration » : au moins 8 observations par côté, médiane candidate
  <= 0,80 x médiane de base, intervalles interquartiles disjoints
  (Q3 candidate < Q1 base) ET médiane candidate inférieure à la médiane de
  base dans CHAQUE manche (les manches alternent l'ordre base/candidate) ;
- « régression »   : symétrique (>= 1,25 x, Q1 candidate > Q3 base, chaque
  manche plus lente) ;
- moins de 8 observations : « non concluant (n < 8) » ;
- sinon « gain non démontré » (écart confondu avec la variabilité).

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


def conclude(base: dict, cand: dict, rounds: list[tuple[float, float]]) -> str:
    """[rounds] : (médiane base, médiane candidate) de chaque manche."""
    if base.get("n", 0) == 0 or cand.get("n", 0) == 0:
        return "non mesuré"
    if base["n"] < 8 or cand["n"] < 8:
        return "non concluant (n < 8)"
    if base["median"] <= 0:
        return "gain non démontré"
    ratio = cand["median"] / base["median"]
    faster = bool(rounds) and all(c < b for b, c in rounds)
    slower = bool(rounds) and all(c > b for b, c in rounds)
    if ratio <= 0.80 and cand["q3"] < base["q1"] and faster:
        return "amélioration"
    if ratio >= 1.25 and cand["q1"] > base["q3"] and slower:
        return "régression"
    return "gain non démontré"


def _round_of(file_name: str) -> str:
    """« base-r3.jsonl » -> « r3 »."""
    stem = file_name.rsplit(".", 1)[0]
    return stem.split("-", 1)[1] if "-" in stem else stem


per_round: dict = {}


def load(folder: Path) -> tuple[dict, list[dict], list[dict], dict]:
    """(valeurs[(scénario, profil, clé)][label] -> liste, métas, échecs,
    empreintes[profil][label] -> liste de dictionnaires)."""
    values: dict = {}
    metas: list[dict] = []
    failures: list[dict] = []
    digests: dict = {}
    global per_round
    per_round = {}
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
            if row.get("unit") == "digest":
                digests.setdefault(row["profile"], {}).setdefault(
                    row["label"], []
                ).append(row["values"])
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
                per_round.setdefault(key, {}).setdefault(
                    (row["label"], _round_of(path.name)), []
                ).extend(float(x) for x in vals)
    return values, metas, failures, digests


def compare_digests(digests: dict, base: str, cand: str) -> list[str]:
    """Lignes Markdown : empreintes identiques ou non, par profil et champ."""
    out = []
    for profile, sides in sorted(digests.items()):
        seen_b = sides.get(base, [])
        seen_c = sides.get(cand, [])
        if not seen_b or not seen_c:
            out.append(f"| {profile} | — | non mesuré |")
            continue
        stable_b = all(d == seen_b[0] for d in seen_b)
        stable_c = all(d == seen_c[0] for d in seen_c)
        for key in sorted(set(seen_b[0]) | set(seen_c[0])):
            same = seen_b[0].get(key) == seen_c[0].get(key)
            verdict = "identique" if same else "DIFFÉRENT"
            if not (stable_b and stable_c):
                verdict += " (instable entre exécutions)"
            out.append(
                f"| {profile} | {key} | {verdict} ({seen_b[0].get(key)} / {seen_c[0].get(key)}) |"
            )
    return out


def _rounds(scenario, profile, sub, args) -> list[tuple[float, float]]:
    data = per_round.get((scenario, profile, sub), {})
    names = sorted({r for (_, r) in data})
    out = []
    for r in names:
        b = data.get((args.base, r))
        c = data.get((args.cand, r))
        if b and c:
            out.append((statistics.median(b), statistics.median(c)))
    return out


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("folder")
    parser.add_argument("--base", default="base")
    parser.add_argument("--cand", default="cand")
    args = parser.parse_args(argv)
    folder = Path(args.folder)
    values, metas, failures, digests = load(folder)
    digest_lines = compare_digests(digests, args.base, args.cand)
    different = any("DIFFÉRENT" in line for line in digest_lines)
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
                    "brut (hors comparaison)"
                    if unit == "bytes"
                    else conclude(b, c, _rounds(scenario, profile, sub, args))
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
    if digest_lines:
        lines += [
            "",
            "## Résultats métier (empreintes base / candidate)",
            "",
            "| Profil | Champ | Verdict (base / candidate) |",
            "| --- | --- | --- |",
            *digest_lines,
        ]
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
    return 1 if failures or different else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
