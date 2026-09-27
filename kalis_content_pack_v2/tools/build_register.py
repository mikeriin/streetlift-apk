"""Écrit validation_register.md : points à faire valider (contenu non relu par un professionnel diplômé) — pack v2 (L9R)."""
import json
import os
import sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kb_vocab as V  # noqa: E402

HEAD_SPLITS = {
    "pectoraux": "grand pectoral : chef sterno-costal + chef claviculaire (le chef abdominal n'est ajouté que pour les dips et le développé décliné)",
    "triceps": "triceps : chef long + chef latéral + chef médial",
    "quadriceps": "quadriceps : droit fémoral + vaste latéral + vaste médial + vaste intermédiaire",
    "ischios": "ischio-jambiers : biceps fémoral (chef long et chef court) + semi-tendineux + semi-membraneux",
    "deltoides": "deltoïde : faisceaux antérieur, moyen, postérieur",
    "trapezes": "trapèze : faisceaux supérieur, moyen, inférieur",
    "erecteurs": "érecteurs du rachis : lombaires + thoraciques",
    "obliques": "obliques : externe + interne",
    "adducteurs": "adducteurs : long, court, grand, gracile, pectiné",
    "mollets": "triceps sural : gastrocnémien médial + latéral + soléaire",
    "biceps": "biceps brachial : chef long + chef court",
    "prehension": "préhension : fléchisseurs superficiels et profonds des doigts, muscles intrinsèques de la main",
    "coiffe": "coiffe des rotateurs : supra-épineux, infra-épineux, petit rond, sub-scapulaire",
    "flechisseurs_hanche": "fléchisseurs de hanche : grand psoas + iliaque (+ droit fémoral)",
}


def main(pack):
    def j(n):
        with open(os.path.join(pack, n), encoding="utf-8") as f:
            return json.load(f)
    ex = j("exercises_v2.json")["exercices"]
    prog = j("progressions.json")
    poses = j("poses.json")
    srcs = j(os.path.join("sources", "archetypes_sources.json"))
    by = {e["id"]: e for e in ex}
    L = ["# Registre des points à faire valider — pack Kalis Track v2 (L9R)\n",
         "Le contenu de ce pack n'a pas été relu par un professionnel diplômé (décision du propriétaire). "
         "Les faits anatomiques (muscles, type de mouvement) ont été vérifiés sur au moins deux sources publiques "
         "concordantes par archétype (voir `sources/archetypes_sources.json` et le champ `sources` de chaque exercice) ; "
         "les textes, difficultés, seuils, contraintes, précautions et démonstrations ont été produits par Claude "
         "(provenance `genere_l9r`). Les précautions sont des consignes d'entraînement, jamais des avis médicaux.\n",
         "Priorité de relecture : **P1** = peut exposer un pratiquant débutant ou en reprise à une charge excessive ; "
         "**P2** = influence directe sur le générateur ou sur l'affichage anatomique ; **P3** = qualité et confort.\n"]

    # ---------------------------------------------------------------- 0. sources et anatomie
    L.append("## 0. Sources et attributions anatomiques (P2)\n")
    L.append("### 0.1 Concordance établie par une source de variante proche\n")
    L.append("Pour ces archétypes, la seconde source décrit une variante très proche (même schéma moteur) et non "
             "l'exercice exact. Le propriétaire décide si cette concordance suffit ; sinon les muscles restent ceux de la "
             "source directe et l'exercice est marqué « à confirmer » dans l'application.\n")
    for k, v in sorted(srcs.items()):
        if v.get("note_concordance"):
            L.append(f"- **{k}** : {v['note_concordance']}")
    L.append("")
    L.append("### 0.2 Désaccords entre sources (arbitrage retenu)\n")
    L.append("Quand les sources divergent, le pack retient l'attribution majoritaire ou, à égalité, la source la plus "
             "détaillée (Wikipédia / organisme) ; le désaccord est conservé ici et dans `sources_meta.desaccord`.\n")
    for k, v in sorted(srcs.items()):
        if v.get("desaccord"):
            L.append(f"- **{k}** : {v['desaccord']}")
    L.append("")
    L.append("### 0.3 Découpage en chefs par raisonnement anatomique\n")
    L.append("Les sources nomment le muscle ; le découpage en chefs ou faisceaux (utile à l'atlas) est un raisonnement "
             "anatomique de Claude, appliqué uniformément :\n")
    for k, v in HEAD_SPLITS.items():
        L.append(f"- `{k}` → {v}")
    L.append("")
    L.append("### 0.4 Stabilisateurs déduits par raisonnement\n")
    reas = sorted(k for k, v in srcs.items() if str(v.get("stab_source", "")).startswith("raisonnement"))
    L.append(f"{len(reas)} archétypes sur {len(srcs)} ont des stabilisateurs déduits (aucune source ne les listait) : "
             + ", ".join(f"`{k}`" for k in reas) + ".\n")
    L.append("### 0.5 Surcharges par exercice\n")
    L.append("Exercices dont les muscles diffèrent de leur archétype (variante de prise, d'angle ou de cible) :\n")
    for e in ex:
        if e["sources_meta"].get("surcharge_exercice"):
            L.append(f"- {e['nom']} (`{e['id']}`, archétype `{e['famille']}`) : primaires = {', '.join(e['muscles_primaires'])}")
    L.append("")
    L.append("### 0.6 Erreurs de la v1 corrigées par les sources\n")
    n = 0
    for k, v in sorted(srcs.items()):
        if v.get("v1_erreur"):
            L.append(f"- **{k}** : {v['v1_erreur']}")
            n += 1
    if not n:
        L.append("- aucune")
    L.append("")

    # ---------------------------------------------------------------- 1. seuils
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

    # ---------------------------------------------------------------- 2. contraintes
    L.append("## 2. Exercices à forte contrainte articulaire (P1)\n")
    L.append("Exercices utilisables par le générateur ayant au moins une zone cotée 3/3, avec leurs précautions.\n")
    L.append("| Exercice | Niveau | Zones à 3 | Précautions |\n| --- | --- | --- | --- |")
    for e in sorted(ex, key=lambda x: (x["difficulte"], x["nom"])):
        z3 = [V.ZONES_LABELS[k] for k, v in e["contrainte_articulaire"].items() if v == 3]
        if z3 and e["generateur"]:
            L.append(f"| {e['nom']} | {e['difficulte']} | {', '.join(z3)} | {', '.join(e['precautions']) or '—'} |")
    L.append("")

    # ---------------------------------------------------------------- 3. difficultés
    L.append("## 3. Difficultés (P2)\n")
    L.append("Échelle 1 à 10 calibrée pour un adulte non entraîné au poids de corps. Pour les exercices chargés, la cote "
             "mesure la technicité et l'accessibilité, pas la charge. Quand une source donne un niveau de référence "
             "(free-exercise-db, ACE, StrengthLevel), il est rappelé pour comparaison.\n")
    fam = defaultdict(list)
    for e in ex:
        fam[e["famille"]].append(e)
    L.append("| Archétype | Référence externe | Exercices (niveau) |\n| --- | --- | --- |")
    for k in sorted(fam):
        ref = (srcs.get(k, {}).get("difficulte_reference") or "—").replace("|", "/")
        items = ", ".join(f"{e['nom']} ({e['difficulte']})" for e in sorted(fam[k], key=lambda x: (x["difficulte"], x["nom"])))
        L.append(f"| {k} | {ref} | {items} |")
    L.append("")
    L.append("### 3.1 Exercices ajoutés en L9R (couverture de la matrice)\n")
    L.append("Variantes d'archétypes sourcés ; leur difficulté suit la progression usuelle de la variante et mérite confirmation :\n")
    for e in sorted(ex, key=lambda x: (x["type_mouvement"], x["difficulte"])):
        if e["origine"] == "ajout_l9r":
            L.append(f"- {e['nom']} (`{e['id']}`) : type {V.TYPES_MOUVEMENT[e['type_mouvement']]}, niveau {e['difficulte']}, matériel {', '.join(e['materiel'])}")
    L.append("")

    # ---------------------------------------------------------------- 4-5. NC, doublons
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

    # ---------------------------------------------------------------- 6. démonstrations
    L.append("## 6. Démonstrations (P3)\n")
    L.append("Chaque image clé est calculée par cinématique directe depuis des angles articulaires de référence, puis "
             "contrôlée automatiquement (longueurs, amplitudes, contacts, sol, appui, accessoires, interpolation) et "
             "visuellement (planches `planches/*.png`). Limites du modèle à connaître :\n")
    L.append("- Le rachis est un segment rigide : cambrures et enroulements (pont, cat-cow, Jefferson curl, dragon flag) sont schématisés.")
    L.append("- Vue de profil ou de face uniquement : les gestes hors du plan sont projetés ou réduits à une position de départ (statut `statique`).")
    L.append("- Les épaules ne s'élèvent pas et les omoplates ne bougent pas : shrugs, tractions scapulaires et dépression d'épaule sont représentés par le déplacement de la charge ou du corps.")
    L.append("- La main est un segment rigide : en vue de face elle prolonge l'avant-bras (planche latérale bras tendu).")
    L.append("- La longueur bras + main du modèle place l'épaule à 0,33 de la taille au-dessus d'un appui manuel : les L-sit au sol montrent le bassin très près du sol.")
    L.append("")
    L.append("### 6.1 Démonstrations indisponibles\n")
    for eid, p in sorted(poses["exercices"].items()):
        if p["statut"] == "indisponible":
            L.append(f"- {by[eid]['nom']} (`{eid}`) : {p['motif']}")
    L.append("")
    L.append("### 6.2 Démonstrations statiques (position de départ seulement)\n")
    for eid, p in sorted(poses["exercices"].items()):
        if p["statut"] == "statique":
            L.append(f"- {by[eid]['nom']} (`{eid}`) : {p['motif']}")
    L.append("")
    L.append("### 6.3 Gabarits avec amplitudes étendues (figures avancées, autorisées explicitement)\n")
    for n, g in sorted(poses["gabarits"].items()):
        if g["exceptions_amplitude"]:
            L.append(f"- `{n}` : {', '.join(f'{k} {v}' for k, v in g['exceptions_amplitude'].items())}")
    L.append("")
    L.append("### 6.4 Notes des gabarits\n")
    for n, g in sorted(poses["gabarits"].items()):
        if g["note"]:
            L.append(f"- `{n}` : {g['note']}")
    L.append("")

    # ---------------------------------------------------------------- 7. précautions
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
