#!/usr/bin/env python3
"""Ajustement des exposants du poids de corps des standards de rang.

    python3 packages/kalis_quest/tool/standards_fit.py

Données : lignes des tables Strength Level relevées le 01/10/2026 (voir
docs/STANDARDS_SOURCES.md). Pour chaque niveau (Beginner … Elite), une
régression log-log commune à toutes les séries donne l'exposant b tel que
seuil(poids) = seuil(référence) × (poids / référence)^b. La sortie est le
tableau recopié dans docs/STANDARDS_SOURCES.md ; les exposants arrondis
sont ceux de lib/src/standards.dart.
"""
import math

# (fraction du poids du corps, {poids: [Beginner, Novice, Intermediate, Advanced, Elite]})
LOADS = {
    "Développé couché, hommes": (0.0, {60: [37, 53, 72, 95, 119], 80: [56, 75, 98, 124, 151], 100: [73, 95, 120, 149, 179]}),
    "Développé couché, femmes": (0.0, {50: [14, 25, 40, 58, 79], 65: [21, 33, 50, 70, 92], 80: [26, 40, 59, 80, 104]}),
    "Traction lestée, hommes": (0.97, {60: [-4, 11, 27, 45, 64], 80: [-2, 14, 33, 54, 75], 100: [-3, 15, 36, 59, 82]}),
    "Traction lestée, femmes": (0.97, {50: [-14, -4, 8, 21, 35], 60: [-16, -4, 9, 23, 38], 80: [-20, -7, 8, 24, 41]}),
    "Dips lestés, hommes": (0.96, {60: [-1, 17, 39, 64, 91], 80: [5, 26, 52, 81, 111], 100: [8, 32, 61, 92, 125]}),
    "Dips lestés, femmes": (0.96, {50: [-15, -2, 14, 32, 52], 60: [-15, 0, 17, 37, 58], 80: [-17, 0, 20, 42, 66]}),
}
# {poids: [Intermediate, Elite]} en répétitions
REPS = {
    "Pompes, hommes": {60: [41, 95], 80: [38, 84], 100: [35, 74]},
    "Pompes, femmes": {50: [19, 51], 60: [18, 47], 80: [16, 40]},
    "Tractions, hommes": {60: [14, 33], 80: [13, 29], 100: [11, 25]},
    "Tractions, femmes": {50: [6, 22], 60: [6, 20], 80: [5, 16]},
    "Dips, hommes": {60: [20, 46], 80: [20, 42], 100: [19, 38]},
    "Dips, femmes": {50: [9, 31], 60: [9, 29], 80: [9, 25]},
    "Muscle-ups, hommes": {60: [6, 17], 80: [7, 16], 100: [7, 15]},
    "Muscle-ups, femmes": {50: [4, 14], 60: [5, 14], 80: [5, 13]},
}
LEVELS = ["Beginner", "Novice", "Intermediate", "Advanced", "Elite"]
CHOSEN_LOAD = [1.21, 1.04, 0.92, 0.82, 0.74]


def slope(xs, ys):
    mx, my = sum(xs) / len(xs), sum(ys) / len(ys)
    sxx = sum((x - mx) ** 2 for x in xs)
    sxy = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    return sxy, sxx


def main():
    print("| Niveau | " + " | ".join(LOADS) + " | Commun |")
    print("| --- |" + " --- |" * (len(LOADS) + 1))
    for t, level in enumerate(LEVELS):
        num = den = 0.0
        cells = []
        for fraction, rows in LOADS.values():
            xs = [math.log(bw) for bw in sorted(rows)]
            ys = [math.log(rows[bw][t] + fraction * bw) for bw in sorted(rows)]
            sxy, sxx = slope(xs, ys)
            cells.append(f"{sxy / sxx:.2f}")
            num += sxy
            den += sxx
        print(f"| {level} | " + " | ".join(cells) + f" | **{num / den:.2f}** |")
    print()
    worst = 0.0
    total = 0.0
    n = 0
    for name, (fraction, rows) in LOADS.items():
        ref = sorted(rows)[1]
        for bw in sorted(rows):
            if bw == ref:
                continue
            for t in range(5):
                want = rows[bw][t] + fraction * bw
                got = (rows[ref][t] + fraction * ref) * (bw / ref) ** CHOSEN_LOAD[t]
                err = abs(got / want - 1)
                worst = max(worst, err)
                total += err
                n += 1
    print(f"Écart relatif sur la charge totale, exposants retenus {CHOSEN_LOAD} : "
          f"moyen {100 * total / n:.1f} %, maximal {100 * worst:.1f} % ({n} cases).")
    print()
    print("| Niveau | " + " | ".join(REPS) + " | Commun |")
    print("| --- |" + " --- |" * (len(REPS) + 1))
    for t, level in enumerate(["Intermediate", "Elite"]):
        num = den = 0.0
        cells = []
        for rows in REPS.values():
            xs = [math.log(bw) for bw in sorted(rows)]
            ys = [math.log(rows[bw][t]) for bw in sorted(rows)]
            sxy, sxx = slope(xs, ys)
            cells.append(f"{sxy / sxx:.2f}")
            num += sxy
            den += sxx
        print(f"| {level} | " + " | ".join(cells) + f" | **{num / den:.2f}** |")


if __name__ == "__main__":
    main()
