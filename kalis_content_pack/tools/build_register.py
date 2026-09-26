"""Écrit validation_register.md : points à faire valider (contenu non relu par un professionnel diplômé)."""
import json
import os
import sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kb_vocab as V  # noqa: E402


def main(pack):
    def j(n):
        with open(os.path.join(pack, n), encoding="utf-8") as f:
            return json.load(f)
    ex = j("exercises_v2.json")["exercices"]
    prog = j("progressions.json")
    poses = j("poses.json")
    by = {e["id"]: e for e in ex}
    L = ["# Registre des points à faire valider — pack Kalis Track v1 (L9)\n",
         "Le contenu de ce pack n'a pas été relu par un professionnel diplômé (décision du propriétaire). "
         "Tout ce qui suit a été produit par Claude (provenance `genere_l9`) et doit être confirmé ou corrigé lors de la "
         "relecture. Les précautions sont des consignes d'entraînement, jamais des avis médicaux.\n",
         "Priorité de relecture : **P1** = peut exposer un pratiquant débutant ou en reprise à une charge excessive ; "
         "**P2** = influence directe sur le générateur ; **P3** = qualité et confort.\n"]

    L.append("## 1. Seuils de passage des arbres de progression (P1)\n")
    L.append("| Arbre | Étape | Niveau | Seuil pour passer à l'étape suivante |\n| --- | --- | --- | --- |")
    for c in prog["chaines"]:
        for s in c["etapes"]:
            e = by[s["id"]]
            L.append(f"| {c['titre']} | {e['nom']} | {e['difficulte']} | {s['seuil_passage']['texte'] if s['seuil_passage'] else '— (dernière étape)'} |")
    L.append("\nPrérequis transverses (en plus de l'étape précédente) :\n")
    for e in prog["aretes"]:
        if e["type"] == "prerequis_transverse":
            L.append(f"- {by[e['vers']]['nom']} ← {by[e['de']]['nom']} : {e['seuil']['texte']}")
    L.append("")

    L.append("## 2. Exercices à forte contrainte articulaire (P1)\n")
    L.append("Exercices utilisables par le générateur ayant au moins une zone cotée 3/3, avec leurs précautions.\n")
    L.append("| Exercice | Niveau | Zones à 3 | Précautions |\n| --- | --- | --- | --- |")
    for e in sorted(ex, key=lambda x: (x["difficulte"], x["nom"])):
        z3 = [V.ZONES_LABELS[k] for k, v in e["contrainte_articulaire"].items() if v == 3]
        if z3 and e["generateur"]:
            L.append(f"| {e['nom']} | {e['difficulte']} | {', '.join(z3)} | {', '.join(e['precautions']) or '—'} |")
    L.append("")

    L.append("## 3. Difficultés (P2)\n")
    L.append("Échelle 1 à 10 calibrée pour un adulte non entraîné au poids de corps. Pour les exercices chargés, la cote "
             "mesure la technicité et l'accessibilité, pas la charge. Valeurs par famille de mouvement :\n")
    fam = defaultdict(list)
    for e in ex:
        fam[e["famille"]].append(e)
    L.append("| Famille | Exercices (niveau) |\n| --- | --- |")
    for k in sorted(fam):
        items = ", ".join(f"{e['nom']} ({e['difficulte']})" for e in sorted(fam[k], key=lambda x: (x["difficulte"], x["nom"])))
        L.append(f"| {k} | {items} |")
    L.append("")

    L.append("## 4. Non-conformités détectées dans la base v1 (P2)\n")
    L.append("Aucune entrée n'a été supprimée. Correction proposée : voir la fiche de l'exercice.\n")
    for e in ex:
        if e["non_conformites"]:
            L.append(f"- **{e['nom']}** (`{e['id']}`) : {' '.join(e['non_conformites'])}")
    L.append("")
    L.append("## 5. Doublons signalés (P2)\n")
    L.append("Le générateur n'utilise que l'entrée canonique ; l'entrée doublon reste pour l'historique des séances.\n")
    for e in ex:
        if e["doublon_de"]:
            L.append(f"- {e['nom']} → {by[e['doublon_de']]['nom']}")
    L.append("")

    L.append("## 6. Démonstrations animées (P3)\n")
    L.append("- Le rachis est représenté par un segment rigide : cambrures, enroulements (pont, cat-cow, Jefferson curl, "
             "dragon flag) sont schématisés.")
    L.append("- Les gestes hors du plan de la vue sont projetés : en profil, les bras écartés (squat barre sur le dos, "
             "tirage menton) sont dessinés dans le plan ; en face, les cuisses d'une position assise sont vues en raccourci.")
    L.append("- Une pose peut être partagée par plusieurs variantes (prise large, serrée, neutre) : la différence est "
             "portée par le texte, pas par l'image.")
    L.append("- Gabarits avec amplitudes étendues (figures avancées, autorisées explicitement) :")
    for n, g in sorted(poses["gabarits"].items()):
        if g["exceptions_amplitude"]:
            L.append(f"  - `{n}` : {', '.join(f'{k} {v}' for k, v in g['exceptions_amplitude'].items())}")
    for n, g in sorted(poses["gabarits"].items()):
        if g["note"]:
            L.append(f"- `{n}` : {g['note']}")
    L.append("")
    L.append("## 7. Précautions (P1)\n")
    L.append("Libellés standard utilisés (consignes d'entraînement) :\n")
    for k, v in V.PRECAUTIONS.items():
        n = sum(1 for e in ex if k in e["precautions"])
        L.append(f"- `{k}` ({n} exercices) : {v}")
    L.append("")
    with open(os.path.join(pack, "validation_register.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(L))


if __name__ == "__main__":
    main(sys.argv[1])
