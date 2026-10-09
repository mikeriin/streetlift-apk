#!/usr/bin/env python3
"""Compare couples 0.1 / 0.2 / 0.3 sur la saison de référence (moyennes sur profils).
usage: compare.py <saisons 0.2 (cx)> <saisons 0.3 (cy)>"""
import json, sys
M = ["effortGap", "failRate", "weeklyGain", "eventPerformance", "realizedViolations"]
def load(path):
    d = json.load(open(path))
    out = {}
    for p in d["profiles"]:
        ref = p["scenarios"].get("reference")
        if not ref: continue
        for couple, models in ref["couples"].items():
            for m, r in models.items():
                out.setdefault((couple, m), {})[p["key"]] = r
    return out
a = load(sys.argv[1]); b = load(sys.argv[2])
print("couples 0.2:", sorted({k[0] for k in a}), " 0.3:", sorted({k[0] for k in b}))
street = sorted(next(iter(a.values())).keys())
def agg(tab, keys):
    res = {}
    for k in M:
        vals = [tab[p][k]["mean"] for p in keys if p in tab and tab[p][k]["n"] > 0]
        res[k] = (sum(vals) / len(vals), len(vals)) if vals else (None, 0)
    res["pain"] = (sum(tab[p].get("painAggravations", 0) for p in keys if p in tab), 0)
    return res
for m in "abc":
    print(f"\n## modèle {m.upper()}")
    rows = []
    for label, src, couple, keys in [
        ("0.1 (v01, run CY)", b, "v01", street),
        ("0.2 (cx, CX c1)", a, "cx", street),
    ] + [(f"0.3 ({c}) street", b, c, street) for c in sorted({k[0] for k in b}) if c != "v01"] + \
        [(f"0.3 ({c}) toutes", b, c, None) for c in sorted({k[0] for k in b}) if c != "v01"]:
        tab = src.get((couple, m))
        if tab is None: continue
        r = agg(tab, keys or sorted(tab))
        print(label, len(keys or tab), " | ".join(f"{k} {v[0]:.4f}" if v[0] is not None else f"{k} —" for k, v in r.items()))
