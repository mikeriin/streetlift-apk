"""Construit les gabarits v2 (images clés calculées) à partir des fiches biomécaniques."""
import json
import sys

import biomeca as BM
import pose_solver as PS


def build(name):
    return PS.build_sheet(BM.REG[name])


def build_all():
    return {n: PS.build_sheet(s) for n, s in BM.REG.items()}


if __name__ == "__main__":
    res = build_all()
    print(len(res), "gabarits")
    bad = [(n, [kf["residu"] for kf in t["keyframes"]]) for n, t in res.items() if any(kf["residu"] > 0.01 for kf in t["keyframes"])]
    print("résidus > 0,01 :", bad)
    if len(sys.argv) > 1:
        print(json.dumps(res[sys.argv[1]], ensure_ascii=False, indent=1)[:4000])
