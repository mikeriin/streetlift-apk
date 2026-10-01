"""Règles des champs calculés du catalogue Kalis Track (lot GC).

Chaque champ calculé d'un exercice est déduit des champs de la base v1.1 par
les règles de ce fichier : tables par catégorie ou par matériel, puis
retouches par mots-clés sur le nom normalisé. Aucune valeur n'est saisie
exercice par exercice. Les justifications et références sont dans
packages/kalis_core/CONTRAT.md (§ Catalogue) ; les valeurs qui ne sont qu'un
choix raisonné y sont dites comme telles.

Version des règles : RULES_VERSION (toute modification d'une règle la change).
"""
from __future__ import annotations

import math
import re
import unicodedata

RULES_VERSION = "1.0.0"

NIVEAUX = ["Débutant", "Intermédiaire", "Avancé", "Élite"]
JOINTS = ["epaule", "coude", "poignet", "lombaires", "genou", "hanche", "cheville"]
CONTRAINTE = {1: "faible", 2: "moyenne", 3: "forte"}
LIEUX = ["salle", "maison", "exterieur"]

# Poids du vecteur musculaire (CONTRAT.md : principal et secondaire d'après le
# comptage « fractionnaire » des séries, Pelland et al. 2024 ; stabilisateur :
# choix raisonné).
POIDS_PRINCIPAL = 1.0
POIDS_SECONDAIRE = 0.5
POIDS_STABILISATEUR = 0.2


def norm(text: str) -> str:
    """Minuscules sans accents, pour les règles par mots-clés."""
    t = unicodedata.normalize("NFD", text)
    t = "".join(c for c in t if unicodedata.category(c) != "Mn")
    return t.lower().replace("’", "'")


def has(text: str, *words: str) -> bool:
    return any(w in text for w in words)


# --------------------------------------------------------------------------
# 1. Schéma de mouvement et famille
# --------------------------------------------------------------------------

SCHEMA_PAR_CATEGORIE = {
    "Poussée horizontale": "poussee_horizontale",
    "Poussée verticale": None,  # haute (au-dessus de la tête) ou basse (dips)
    "Poussée inclinée": "poussee_inclinee",
    "Tirage horizontal": "tirage_horizontal",
    "Tirage vertical": "tirage_vertical",
    "Isolation pectoraux": "isolation_pectoraux",
    "Isolation dos": "isolation_dos",
    "Isolation épaules": "isolation_epaules",
    "Élévation scapulaire / trapèzes": "isolation_trapezes",
    "Préparation scapulaire": "preparation_scapulaire",
    "Isolation biceps": "isolation_biceps",
    "Isolation triceps": "isolation_triceps",
    "Avant-bras et préhension": "prehension",
    "Squat / dominante genou": "squat",
    "Fente / unilatéral jambes": "fente",
    "Charnière de hanche": "charniere_hanche",
    "Extension de hanche": "extension_hanche",
    "Flexion de genou (ischio-jambiers)": "flexion_genou",
    "Extension de genou": "extension_genou",
    "Adducteurs / abducteurs": "adducteurs_abducteurs",
    "Mollets et cheville": "mollets",
    "Cou": "cou",
    "Gainage anti-extension": "gainage_anti_extension",
    "Gainage anti-rotation": "gainage_anti_rotation",
    "Gainage anti-flexion latérale": "gainage_anti_flexion_laterale",
    "Flexion du tronc": "flexion_tronc",
    "Rotation du tronc": "rotation_tronc",
    "Extension du rachis": "extension_rachis",
    "Flexion de hanche / relevés de jambes": "flexion_hanche",
    "Compression": "compression",
    "Haltérophilie": "halterophilie",
    "Balistique kettlebell": "balistique",
    "Portés et strongman": "porte",
    "Pliométrie": "pliometrie",
    "Équilibre sur les mains": "equilibre_mains",
    "Figure statique poussée": "figure_statique_poussee",
    "Figure statique tirage": "figure_statique_tirage",
    "Figure statique mixte": "figure_statique_mixte",
    "Figure dynamique poussée": "figure_dynamique_poussee",
    "Figure dynamique tirage": "figure_dynamique_tirage",
    "Transition / muscle-up": "transition_muscle_up",
    "Freestyle dynamique": "freestyle",
    "Mouvement de compétition": None,  # selon le mouvement
    "Conditionnement métabolique": "conditionnement",
    "Gymnastique CrossFit": "gymnastique_crossfit",
    "Cardio continu": "cardio_continu",
    "Cardio fractionné": "cardio_fractionne",
    "Sprint et vitesse": "sprint",
    "Corde à sauter": "corde_a_sauter",
    "Marche et portage": "marche",
    "Mobilité articulaire": "mobilite_articulaire",
    "Étirement statique": "etirement_statique",
    "Étirement dynamique": "etirement_dynamique",
    "Souplesse avancée": "souplesse",
    "Auto-massage": "auto_massage",
    "Respiration et récupération": "respiration",
}

FAMILLE_PAR_SCHEMA = {
    "poussee_horizontale": "poussee",
    "poussee_inclinee": "poussee",
    "poussee_verticale_haute": "poussee",
    "poussee_verticale_basse": "poussee",
    "tirage_horizontal": "tirage",
    "tirage_vertical": "tirage",
    "isolation_pectoraux": "isolation_haut",
    "isolation_dos": "isolation_haut",
    "isolation_epaules": "isolation_haut",
    "isolation_trapezes": "isolation_haut",
    "preparation_scapulaire": "isolation_haut",
    "isolation_biceps": "isolation_bras",
    "isolation_triceps": "isolation_bras",
    "prehension": "isolation_bras",
    "squat": "jambes_genou",
    "fente": "jambes_genou",
    "extension_genou": "isolation_jambes",
    "charniere_hanche": "jambes_hanche",
    "extension_hanche": "jambes_hanche",
    "flexion_genou": "isolation_jambes",
    "adducteurs_abducteurs": "isolation_jambes",
    "mollets": "isolation_jambes",
    "cou": "cou",
    "gainage_anti_extension": "gainage",
    "gainage_anti_rotation": "gainage",
    "gainage_anti_flexion_laterale": "gainage",
    "flexion_tronc": "tronc",
    "rotation_tronc": "tronc",
    "extension_rachis": "tronc",
    "flexion_hanche": "tronc",
    "compression": "tronc",
    "halterophilie": "explosif",
    "balistique": "explosif",
    "pliometrie": "explosif",
    "porte": "porte",
    "equilibre_mains": "figure_statique",
    "figure_statique_poussee": "figure_statique",
    "figure_statique_tirage": "figure_statique",
    "figure_statique_mixte": "figure_statique",
    "figure_dynamique_poussee": "figure_dynamique",
    "figure_dynamique_tirage": "figure_dynamique",
    "transition_muscle_up": "figure_dynamique",
    "freestyle": "figure_dynamique",
    "conditionnement": "conditionnement",
    "gymnastique_crossfit": "conditionnement",
    "cardio_continu": "cardio",
    "cardio_fractionne": "cardio",
    "sprint": "cardio",
    "corde_a_sauter": "cardio",
    "marche": "cardio",
    "mobilite_articulaire": "mobilite",
    "etirement_statique": "mobilite",
    "etirement_dynamique": "mobilite",
    "souplesse": "mobilite",
    "auto_massage": "recuperation",
    "respiration": "recuperation",
}

SCHEMAS = sorted(FAMILLE_PAR_SCHEMA)
FAMILLES = sorted(set(FAMILLE_PAR_SCHEMA.values()))


def schema(ex: dict) -> str:
    cat = ex["categorie"]
    s = SCHEMA_PAR_CATEGORIE[cat]
    if s is not None:
        return s
    n = norm(ex["nom"] + " " + ex["id"])
    if cat == "Poussée verticale":
        # Dips : poussée vers le bas, pectoraux et triceps ; le reste pousse
        # au-dessus de la tête (deltoïdes).
        return "poussee_verticale_basse" if "dips" in n else "poussee_verticale_haute"
    # Mouvement de compétition (streetlifting).
    if "muscle-up" in n:
        return "transition_muscle_up"
    if "traction" in n:
        return "tirage_vertical"
    if "dips" in n:
        return "poussee_verticale_basse"
    if "squat" in n:
        return "squat"
    raise ValueError(f"schéma indéterminé : {ex['id']}")


# --------------------------------------------------------------------------
# 2. Régime de contraction
# --------------------------------------------------------------------------

_DYN_GAINAGE = (
    "rocks", "dead bug", "mountain", "roue", "rollout", "body saw", "stir the pot",
    "crawl", "touches", "shoulder taps", "commando", "bird dog", "pallof", "around the world",
    "avec abduction", "releves de hanche", "dynamique", "get-up", "dragon flag",
)
_ISO_MOTS = (
    "hold", "tenue", "profond tenu", "isometri", "chaise contre", "dead hang",
    "support", "statique", "gainage", "planche rkc", "copenhagen", "wall sit",
)


def regime(ex: dict, sch: str) -> str:
    n = norm(ex["nom"]) + " "
    fam = FAMILLE_PAR_SCHEMA[sch]
    if sch == "souplesse":
        if has(n, "depuis debout", "remontee", "descente"):
            return "dynamique"
        return "isometrique" if has(n, "pont", "actif") else "passif"
    if sch in ("etirement_statique", "auto_massage", "respiration"):
        return "passif"
    if fam == "cardio":
        return "explosif" if sch == "sprint" and not has(n, "educatif", "pas chasses") else "cyclique"
    if ex["discipline"] == "Calisthénie statique":
        return "isometrique"
    if has(n, "negati", "excentrique", "reception en contrebas"):
        return "excentrique"
    if fam == "gainage":
        if has(n, *_DYN_GAINAGE):
            return "excentrique" if "negatif" in n else "dynamique"
        return "isometrique"
    if sch == "porte":
        return "dynamique"
    if sch == "compression" and has(n, "l-sit", "v-sit", "manna"):
        return "isometrique"
    if (has(n, *_ISO_MOTS) or n.startswith("suspension")) and not has(n, "dynamique"):
        return "isometrique"
    if sch in ("halterophilie", "balistique", "pliometrie", "freestyle"):
        return "explosif"
    if has(n, "explosi", "claque", "saute", "kipping", "butterfly"):
        return "explosif"
    return "dynamique"


# --------------------------------------------------------------------------
# 3. Type de charge, assistance
# --------------------------------------------------------------------------

_LEST_MAT = {"ceinture de lest", "gilet lesté", "sac à dos lesté"}
_MACHINE_MAT = {
    "machine guidée", "Smith machine", "presse à cuisses", "hack squat", "machine à mollets",
}
_BARRE_MAT = {
    "barre olympique", "barre EZ", "barre hexagonale", "barre de sécurité (safety bar)",
    "landmine", "barre à grosse prise / grip épais",
}
_AUTRE_MAT = {
    "médecine-ball", "sac lesté", "traîneau", "disques", "chaînes", "corde",
    "rouleau de poignet", "pince de préhension", "harnais de nuque",
}
TYPES_CHARGE = [
    "aucune", "poids_du_corps", "lest", "barre", "halteres", "kettlebell",
    "machine", "poulie", "elastique", "autre",
]


def assiste(ex: dict) -> bool:
    return "assist" in norm(ex["nom"]) and ex["discipline"] != "Mobilité"


def type_charge(ex: dict, sch: str) -> str:
    n = norm(ex["nom"])
    mat = set(ex["materiel"])
    fam = FAMILLE_PAR_SCHEMA[sch]
    # « Sac lesté » est un engin (type « autre »), pas un lest ajouté au corps.
    leste = bool(mat & _LEST_MAT) or "lest" in n.replace("sac leste", "")
    if fam in ("mobilite", "recuperation"):
        return "aucune"
    if fam == "cardio":
        return "lest" if mat & _LEST_MAT else "aucune"
    if "poids du corps" in n:
        return "poids_du_corps"
    disc = ex["discipline"]
    if disc in ("Street workout", "Calisthénie statique", "Calisthénie dynamique"):
        return "lest" if leste else "poids_du_corps"
    if disc == "Streetlifting":
        if leste:
            return "lest"
        return "barre" if mat & _BARRE_MAT else "poids_du_corps"
    if disc == "CrossFit / WOD" and (sch == "gymnastique_crossfit" or "burpee" in n):
        return "lest" if leste else "poids_du_corps"
    if has(n, "rowing inverse", "rollout"):
        return "poids_du_corps"
    if leste:
        return "lest"
    if mat & _MACHINE_MAT:
        return "machine"
    if "poulie" in mat:
        return "poulie"
    if mat & _BARRE_MAT:
        return "barre"
    if "haltères" in mat:
        return "halteres"
    if "kettlebell" in mat:
        return "kettlebell"
    if mat & _AUTRE_MAT:
        return "autre"
    if mat & {"élastique", "bande de résistance mini (mini-band)"}:
        return "poids_du_corps" if assiste(ex) else "elastique"
    return "poids_du_corps"


# --------------------------------------------------------------------------
# 4. Plan dominant
# --------------------------------------------------------------------------

_PLAN_BASE = {
    "poussee_horizontale": "transversal",
    "poussee_inclinee": "transversal",
    "poussee_verticale_haute": "frontal",
    "poussee_verticale_basse": "sagittal",
    "tirage_horizontal": "sagittal",
    "tirage_vertical": "frontal",
    "isolation_pectoraux": "transversal",
    "isolation_dos": "sagittal",
    "isolation_epaules": "frontal",
    "isolation_trapezes": "frontal",
    "preparation_scapulaire": "multiple",
    "isolation_biceps": "sagittal",
    "isolation_triceps": "sagittal",
    "prehension": "sagittal",
    "squat": "sagittal",
    "fente": "sagittal",
    "charniere_hanche": "sagittal",
    "extension_hanche": "sagittal",
    "flexion_genou": "sagittal",
    "extension_genou": "sagittal",
    "adducteurs_abducteurs": "frontal",
    "mollets": "sagittal",
    "cou": "sagittal",
    "gainage_anti_extension": "sagittal",
    "gainage_anti_rotation": "transversal",
    "gainage_anti_flexion_laterale": "frontal",
    "flexion_tronc": "sagittal",
    "rotation_tronc": "transversal",
    "extension_rachis": "sagittal",
    "flexion_hanche": "sagittal",
    "compression": "sagittal",
    "halterophilie": "sagittal",
    "balistique": "sagittal",
    "porte": "sagittal",
    "pliometrie": "sagittal",
    "equilibre_mains": "multiple",
    "figure_statique_poussee": "sagittal",
    "figure_statique_tirage": "sagittal",
    "figure_statique_mixte": "frontal",
    "figure_dynamique_poussee": "sagittal",
    "figure_dynamique_tirage": "sagittal",
    "transition_muscle_up": "sagittal",
    "freestyle": "multiple",
    "conditionnement": "multiple",
    "gymnastique_crossfit": "sagittal",
    "cardio_continu": "sagittal",
    "cardio_fractionne": "sagittal",
    "sprint": "sagittal",
    "corde_a_sauter": "sagittal",
    "marche": "sagittal",
    "mobilite_articulaire": "multiple",
    "etirement_statique": "multiple",
    "etirement_dynamique": "multiple",
    "souplesse": "sagittal",
    "auto_massage": "multiple",
    "respiration": "multiple",
}
PLANS = ["sagittal", "frontal", "transversal", "multiple"]


def plan(ex: dict, sch: str) -> str:
    n = norm(ex["nom"])
    p = _PLAN_BASE[sch]
    if sch == "tirage_vertical" and has(
        n, "supination", "neutre", "serree", "triangle", "chin", "commando", "corde",
        "un bras", "unilateral", "explosive", "claquee", "assistee", "negative", "sautee",
    ) and "large" not in n:
        return "sagittal"
    if sch == "tirage_horizontal" and has(n, "large", "visage", "face pull"):
        return "transversal"
    if sch == "poussee_verticale_haute" and has(n, "neutre", "landmine", "pike", "hspu", "arnold"):
        return "sagittal" if not has(n, "arnold") else "multiple"
    if sch == "isolation_epaules":
        if has(n, "frontale"):
            return "sagittal"
        if has(n, "oiseau", "rotation"):
            return "transversal"
        if has(n, "cuban", "lu raise"):
            return "multiple"
    if sch == "preparation_scapulaire":
        if has(n, "pull-apart", "face pull", "t raise"):
            return "transversal"
        if has(n, "traction scapulaire", "suspension active"):
            return "frontal"
        if has(n, "row scapulaire", "pompe scapulaire"):
            return "sagittal"
    if sch == "prehension":
        if has(n, "pronation au levier", "supination au levier"):
            return "transversal"
        if has(n, "inclinaison"):
            return "frontal"
    if sch in ("squat", "fente", "pliometrie", "sprint") and has(
        n, "lateral", "cossack", "croisee", "skater", "pas chasses", "sumo",
    ):
        return "frontal"
    if sch == "pliometrie" and "rotatif" in n:
        return "transversal"
    if sch == "charniere_hanche" and "windmill" in n:
        return "multiple"
    if sch == "adducteurs_abducteurs" and has(n, "clamshell", "airplane"):
        return "transversal"
    if sch == "cou":
        if "laterale" in n:
            return "frontal"
        if has(n, "isometries", "4 directions"):
            return "multiple"
    if sch == "gainage_anti_flexion_laterale" and "get-up" in n:
        return "multiple"
    if sch == "gainage_anti_rotation" and has(n, "bear crawl", "bird dog"):
        return "multiple"
    if sch == "flexion_tronc" and has(n, "oblique", "laterale", "heel touch"):
        return "frontal"
    if sch == "porte" and "suitcase" in n:
        return "frontal"
    if sch == "figure_statique_tirage" and has(n, "iron cross"):
        return "frontal"
    if sch == "figure_statique_poussee" and "maltese" in n:
        return "frontal"
    if sch == "souplesse" and "facial" in n or sch == "souplesse" and "pancake" in n:
        return "frontal"
    if sch in ("cardio_continu", "cardio_fractionne") and "natation" in n:
        return "multiple"
    return p


# --------------------------------------------------------------------------
# 5. Poly- ou mono-articulaire
# --------------------------------------------------------------------------

_POLY = {
    "poussee_horizontale", "poussee_inclinee", "poussee_verticale_haute",
    "poussee_verticale_basse", "tirage_horizontal", "tirage_vertical", "squat", "fente",
    "charniere_hanche", "halterophilie", "balistique", "pliometrie", "porte",
    "transition_muscle_up", "figure_dynamique_poussee", "figure_dynamique_tirage",
    "freestyle", "conditionnement", "gymnastique_crossfit",
}
_MONO = {
    "isolation_pectoraux", "isolation_dos", "isolation_epaules", "isolation_trapezes",
    "preparation_scapulaire", "isolation_biceps", "isolation_triceps", "prehension",
    "extension_genou", "flexion_genou", "mollets", "cou", "adducteurs_abducteurs",
    "extension_hanche", "extension_rachis", "flexion_tronc", "rotation_tronc",
    "flexion_hanche",
}
ARTICULARITES = ["polyarticulaire", "monoarticulaire", "non_applicable"]


def articularite(ex: dict, sch: str, reg: str) -> str:
    n = norm(ex["nom"])
    if reg in ("isometrique", "passif", "cyclique"):
        return "non_applicable"
    if FAMILLE_PAR_SCHEMA[sch] in ("mobilite", "recuperation", "cardio"):
        return "non_applicable"
    if has(n, "rowing menton", "face pull", "cuban", "glute-ham", "jefferson", "woodchop",
           "landmine rotation", "lancer rotatif", "v-up", "tuck-up", "toes-to-bar",
           "knees-to-elbows", "windshield"):
        return "polyarticulaire"
    if sch in _POLY:
        return "polyarticulaire"
    if sch in _MONO:
        return "monoarticulaire"
    # Gainage, compression, équilibre en régime dynamique : plusieurs
    # articulations bougent (épaule et hanche).
    return "polyarticulaire"


# --------------------------------------------------------------------------
# 6. Unité de mesure
# --------------------------------------------------------------------------

UNITES = ["repetitions", "secondes", "distance", "calories"]


def unite(ex: dict, sch: str, reg: str) -> str:
    n = norm(ex["nom"])
    if "calories" in n:
        return "calories"
    if reg in ("isometrique", "passif"):
        return "secondes"
    if sch in ("mobilite_articulaire", "etirement_dynamique"):
        if has(n, "routine", "squat profond tenu", "marche"):
            return "secondes"
        return "repetitions"
    if sch == "corde_a_sauter":
        return "repetitions" if has(n, "double-unders", "triple-unders", "croises") else "secondes"
    if sch == "sprint":
        return "secondes" if has(n, "rameur", "air bike", "skierg") else "distance"
    if sch in ("cardio_continu", "cardio_fractionne", "marche"):
        return "distance" if re.search(r"\d+ ?m\b", n) else "secondes"
    if sch == "porte":
        if has(n, "epaule", "sur l'epaule", "par-dessus"):
            return "repetitions"
        return "secondes" if "battle rope" in n else "distance"
    if has(n, "handstand walk", "marche laterale en appui", "bear crawl", "crab walk",
           "fente marchee", "broad jump") and "burpee" not in n:
        return "distance"
    if has(n, "mountain climbers", "jumping jacks", "plank jacks", "squat jacks",
           "montees de genoux", "pogo"):
        return "secondes"
    return "repetitions"


# --------------------------------------------------------------------------
# 7. Latéralité
# --------------------------------------------------------------------------

LATERALITES = ["bilateral", "unilateral", "alterne"]
_ALTERNE = (
    "alterne", "marchee", "fentes sautees", "bicycle", "mountain climbers", "flutter",
    "dead bug", "bird dog", "touches d'epaules", "shoulder taps", "commando", "skater jumps",
    "spiderman", "step-over", "typewriter", "cossack", "russian twist", "windshield",
    "heel touch", "essuie-glaces", "transitions 90/90", "world's greatest", "pas chasses",
    "montees de genoux", "talons-fesses", "high knees", "bear crawl", "crab walk",
    "around the world", "battle rope", "marche laterale", "handstand walk", "wall walk",
    "inchworm", "man maker", "crawl", "woodchop", "landmine rotation", "lancer rotatif",
    "cars ", "open book", "thread the needle", "rotation thoracique", "montee de corde",
    "tirage a la corde depuis", "gorilla", "oblique suspendu",
)
_UNILATERAL = (
    "unilateral", "un bras", "une jambe", "une main", "unijambiste", "unipodal", "one-arm",
    "pistol", "shrimp", "skater squat", "dragon squat", "split squat", "fente", "step-up",
    "suitcase", "copenhagen", "gainage lateral", "windmill", "get-up", "kroc", "meadows",
    "archer", "concentre", "drapeau", "clutch flag", "corbeau lateral", "hip airplane",
    "clamshell", "abduction de hanche debout", "abduction de hanche couche", "adduction de hanche debout", "bottoms-up", "kickback", "bayesian",
    "lean-away", "allonge sur le cote", "couche sur le cote", "figure 4", "pigeon",
    "couch stretch", "semi-agenouille", "sleeper", "bras croise", "pied sureleve",
    "croisee a l'haltere", "landmine debout", "par-dessus l'epaule", "sur l'epaule",
    "half split", "demi-grand ecart", "antero-posterieur", "crunch oblique", "poids decale",
    "elevateur de la scapula", "trapeze superieur", "biceps au mur", "bras tendu",
    "gastrocnemiens", "soleaire", "cadre de porte", "rotation externe", "rotation interne",
    "levier", "overhead carry", "rack carry", "ischio-jambiers debout",
    "ischio-jambiers allonge", "fente basse", "flexion laterale",
)


def lateralite(ex: dict) -> str:
    n = norm(ex["nom"])
    if has(n, *_ALTERNE):
        return "alterne"
    if has(n, *_UNILATERAL) and not has(n, "bras tendus", "deux bras", "simultane"):
        return "unilateral"
    return "bilateral"


# --------------------------------------------------------------------------
# 8. Lieux possibles (déduits du matériel)
# --------------------------------------------------------------------------

S, M, E = "salle", "maison", "exterieur"
LIEUX_PAR_MATERIEL = {
    "aucun (sol)": {S, M, E},
    "tapis": {S, M, E},
    "mur": {S, M, E},
    "barre fixe": {S, M, E},
    "barres parallèles": {S, E},
    "barre basse": {S, E},
    "anneaux": {S, M, E},
    "sangles de suspension": {S, M, E},
    "parallettes": {S, M, E},
    "espalier": {S},
    "poteau vertical": {S, E},
    "barre olympique": {S},
    "barre EZ": {S},
    "barre hexagonale": {S},
    "barre de sécurité (safety bar)": {S},
    "disques": {S},
    "haltères": {S, M},
    "kettlebell": {S, M},
    "médecine-ball": {S, M},
    "élastique": {S, M, E},
    "poulie": {S},
    "machine guidée": {S},
    "Smith machine": {S},
    "presse à cuisses": {S},
    "hack squat": {S},
    "machine à mollets": {S},
    "banc plat": {S, M, E},
    "banc inclinable": {S},
    "banc à lombaires": {S},
    "GHD": {S},
    "station dips / relevés de jambes": {S},
    "cage / rack": {S},
    "landmine": {S},
    "box / plinth": {S, M, E},
    "step": {S, M, E},
    "roue abdominale": {S, M},
    "ceinture de lest": {S, E},
    "gilet lesté": {S, M, E},
    "chaînes": {S},
    "harnais de nuque": {S},
    "sangles de tirage": {S, M, E},
    "rouleau de poignet": {S, M},
    "pince de préhension": {S, M, E},
    "traîneau": {S},
    "corde": {S, E},
    "sac lesté": {S, M, E},
    "barre à grosse prise / grip épais": {S},
    "magnésie": {S, M, E},
    "bande de résistance mini (mini-band)": {S, M, E},
    "pupitre (banc Larry Scott)": {S},
    "ballon de gym": {S, M},
    "serviette": {S, M, E},
    "sliders": {S, M},
    "rameur": {S},
    "vélo / home-trainer": {S, M, E},
    "air bike (assault / echo)": {S},
    "SkiErg": {S},
    "tapis de course": {S},
    "corde à sauter": {S, M, E},
    "piste ou terrain extérieur": {E},
    "côte ou escaliers": {E},
    "piscine": {S},
    "sac à dos lesté": {S, M, E},
    "rouleau de massage (foam roller)": {S, M, E},
    "balle de massage": {S, M, E},
    "bâton": {S, M, E},
    "cible murale (wall ball)": {S},
    "cônes": {S, E},
}


def lieux(ex: dict) -> list[str]:
    possibles = {S, M, E}
    for m in ex["materiel"]:
        possibles &= LIEUX_PAR_MATERIEL[m]
    return [l for l in LIEUX if l in possibles]


# --------------------------------------------------------------------------
# 9. Contraintes articulaires (1 faible, 2 moyenne, 3 forte)
#    ordre : épaule, coude, poignet, lombaires, genou, hanche, cheville
# --------------------------------------------------------------------------

_CONTRAINTES_BASE = {
    "poussee_horizontale": (2, 2, 2, 1, 1, 1, 1),
    "poussee_inclinee": (2, 2, 2, 1, 1, 1, 1),
    "poussee_verticale_haute": (3, 2, 2, 2, 1, 1, 1),
    "poussee_verticale_basse": (3, 2, 2, 1, 1, 1, 1),
    "tirage_horizontal": (2, 2, 1, 2, 1, 1, 1),
    "tirage_vertical": (2, 2, 1, 1, 1, 1, 1),
    "isolation_pectoraux": (2, 1, 1, 1, 1, 1, 1),
    "isolation_dos": (2, 1, 1, 1, 1, 1, 1),
    "isolation_epaules": (2, 1, 1, 1, 1, 1, 1),
    "isolation_trapezes": (1, 1, 1, 1, 1, 1, 1),
    "preparation_scapulaire": (1, 1, 1, 1, 1, 1, 1),
    "isolation_biceps": (1, 2, 1, 1, 1, 1, 1),
    "isolation_triceps": (1, 2, 1, 1, 1, 1, 1),
    "prehension": (1, 1, 2, 1, 1, 1, 1),
    "squat": (1, 1, 1, 2, 2, 2, 2),
    "fente": (1, 1, 1, 1, 2, 2, 2),
    "charniere_hanche": (1, 1, 1, 2, 1, 2, 1),
    "extension_hanche": (1, 1, 1, 2, 1, 2, 1),
    "flexion_genou": (1, 1, 1, 1, 2, 1, 1),
    "extension_genou": (1, 1, 1, 1, 2, 1, 1),
    "adducteurs_abducteurs": (1, 1, 1, 1, 1, 2, 1),
    "mollets": (1, 1, 1, 1, 1, 1, 2),
    "cou": (1, 1, 1, 1, 1, 1, 1),
    "gainage_anti_extension": (2, 1, 1, 2, 1, 1, 1),
    "gainage_anti_rotation": (1, 1, 1, 2, 1, 1, 1),
    "gainage_anti_flexion_laterale": (2, 1, 1, 2, 1, 1, 1),
    "flexion_tronc": (1, 1, 1, 2, 1, 2, 1),
    "rotation_tronc": (1, 1, 1, 2, 1, 1, 1),
    "extension_rachis": (1, 1, 1, 2, 1, 1, 1),
    "flexion_hanche": (2, 1, 1, 2, 1, 2, 1),
    "compression": (2, 2, 2, 1, 1, 2, 1),
    "halterophilie": (3, 2, 3, 3, 2, 2, 2),
    "balistique": (2, 1, 1, 2, 1, 2, 1),
    "porte": (2, 1, 2, 2, 1, 1, 1),
    "pliometrie": (1, 1, 1, 2, 3, 2, 3),
    "equilibre_mains": (3, 2, 3, 2, 1, 1, 1),
    "figure_statique_poussee": (3, 3, 3, 2, 1, 1, 1),
    "figure_statique_tirage": (3, 3, 1, 2, 1, 1, 1),
    "figure_statique_mixte": (3, 2, 2, 3, 1, 1, 1),
    "figure_dynamique_poussee": (3, 3, 3, 2, 1, 1, 1),
    "figure_dynamique_tirage": (3, 3, 1, 2, 1, 1, 1),
    "transition_muscle_up": (3, 3, 3, 1, 1, 1, 1),
    "freestyle": (3, 3, 3, 2, 1, 1, 1),
    "conditionnement": (2, 1, 2, 2, 2, 2, 2),
    "gymnastique_crossfit": (3, 2, 2, 2, 1, 1, 1),
    "cardio_continu": (1, 1, 1, 1, 2, 2, 2),
    "cardio_fractionne": (1, 1, 1, 1, 2, 2, 2),
    "sprint": (1, 1, 1, 1, 2, 2, 3),
    "corde_a_sauter": (1, 1, 1, 1, 2, 1, 3),
    "marche": (1, 1, 1, 1, 1, 1, 1),
    "mobilite_articulaire": (1, 1, 1, 1, 1, 1, 1),
    "etirement_statique": (1, 1, 1, 1, 1, 1, 1),
    "etirement_dynamique": (1, 1, 1, 1, 1, 1, 1),
    "souplesse": (1, 1, 1, 2, 1, 2, 1),
    "auto_massage": (1, 1, 1, 1, 1, 1, 1),
    "respiration": (1, 1, 1, 1, 1, 1, 1),
}

_HAUT = {"poussee", "tirage", "figure_statique", "figure_dynamique"}


def contraintes(ex: dict, sch: str, typ: str) -> dict[str, str]:
    n = norm(ex["nom"])
    fam = FAMILLE_PAR_SCHEMA[sch]
    c = dict(zip(JOINTS, _CONTRAINTES_BASE[sch]))

    def au_moins(joint: str, niveau: int) -> None:
        c[joint] = max(c[joint], niveau)

    def plus(joint: str) -> None:
        c[joint] = min(3, c[joint] + 1)

    if fam in ("mobilite", "recuperation"):
        if "pont" in n:
            au_moins("epaule", 2), au_moins("poignet", 2), au_moins("lombaires", 3)
        if has(n, "grand ecart", "pancake"):
            au_moins("hanche", 3)
        return {j: CONTRAINTE[v] for j, v in c.items()}
    if fam == "cardio":
        if has(n, "rameur", "skierg"):
            c.update(lombaires=2, genou=2 if "rameur" in n else 1, hanche=2, cheville=1)
            if "skierg" in n:
                au_moins("epaule", 2)
        elif has(n, "velo", "air bike"):
            c.update(genou=2, hanche=1, cheville=1)
        elif "natation" in n:
            c.update(epaule=2, genou=1, hanche=1, cheville=1)
        elif has(n, "marche"):
            c.update(genou=1, hanche=1, cheville=1)
            if "lestee" in n:
                au_moins("lombaires", 2), au_moins("genou", 2)
        return {j: CONTRAINTE[v] for j, v in c.items()}

    haut = fam in _HAUT or sch in ("transition_muscle_up", "gymnastique_crossfit")
    if sch == "pliometrie" and has(n, "pompe", "dips", "lancer", "slam"):
        c = dict(zip(JOINTS, (2, 2, 3 if has(n, "pompe", "dips") else 1, 2, 1, 1, 1)))
    if has(n, "derriere la nuque", "nuque barre", "guillotine", "bradford", "overhead", "au-dessus de la tete"):
        au_moins("epaule", 3)
    if has(n, "anneaux") and haut:
        plus("epaule")
    if has(n, "un bras", "une main", "one-arm", "archer") and haut:
        plus("epaule"), plus("coude")
    if has(n, "planche", "maltese", "pseudo"):
        au_moins("poignet", 3), au_moins("coude", 3)
    if has(n, "poings", "doigts", "false grip", "wrist"):
        au_moins("poignet", 3)
    if has(n, "barre au front", "jm press", "tate press", "sphinx", "tiger bend"):
        au_moins("coude", 3)
    if typ == "lest" and sch in ("tirage_vertical", "poussee_verticale_basse", "transition_muscle_up"):
        plus("coude")
    if has(n, "pistol", "shrimp", "sissy", "dragon squat", "reverse nordic", "skater squat"):
        au_moins("genou", 3)
    if not haut and has(n, "saute", "box jump", "broad jump", "tuck jump", "saut ", "bonds", "depth", "reception", "pogo"):
        au_moins("genou", 3), au_moins("cheville", 3)
    if sch == "halterophilie" and not has(n, "debout", "power", "muscle", "tirage", "push", "jete", "haltere"):
        au_moins("genou", 3)  # réception en squat complet
    if has(n, "good morning", "jefferson", "zercher") or (sch == "charniere_hanche" and typ == "barre"):
        au_moins("lombaires", 3)
    if sch == "squat" and typ in ("poids_du_corps", "machine") and not has(n, "pistol", "shrimp", "dragon", "skater"):
        c["lombaires"] = 1
    if sch == "squat" and typ in ("barre", "lest") and has(n, "squat"):
        au_moins("genou", 2), au_moins("lombaires", 2)
    if has(n, "front squat", "epaule", "clean") and sch in ("squat", "halterophilie"):
        au_moins("poignet", 2)
    if has(n, "nordic", "glute-ham"):
        au_moins("genou", 2)
    if sch == "flexion_hanche" and not has(n, "suspendu", "toes-to-bar", "knees-to-elbows", "station"):
        c["epaule"] = 1
    if has(n, "copenhagen"):
        au_moins("genou", 2)
    if has(n, "dragon flag", "roue abdominale debout", "body saw", "stir the pot"):
        au_moins("lombaires", 3)
    if has(n, "handstand", "hspu", "wall walk"):
        au_moins("poignet", 3), au_moins("epaule", 3)
    return {j: CONTRAINTE[v] for j, v in c.items()}


# --------------------------------------------------------------------------
# 10. Coût de fatigue (1 à 5) : systémique et local
# --------------------------------------------------------------------------

_FATIGUE_SYS = {
    "halterophilie": 4, "charniere_hanche": 3, "squat": 3, "fente": 3,
    "poussee_horizontale": 3, "poussee_inclinee": 3, "poussee_verticale_haute": 3,
    "poussee_verticale_basse": 3, "tirage_horizontal": 3, "tirage_vertical": 3,
    "conditionnement": 4, "gymnastique_crossfit": 3, "pliometrie": 3, "balistique": 3,
    "porte": 4, "cardio_fractionne": 4, "sprint": 4, "cardio_continu": 3,
    "corde_a_sauter": 3, "marche": 1, "figure_statique_poussee": 3,
    "figure_statique_tirage": 3, "figure_statique_mixte": 3,
    "figure_dynamique_poussee": 3, "figure_dynamique_tirage": 3,
    "transition_muscle_up": 3, "freestyle": 3, "equilibre_mains": 2,
    "extension_hanche": 2, "gainage_anti_extension": 2, "gainage_anti_rotation": 2,
    "gainage_anti_flexion_laterale": 2, "compression": 2, "flexion_hanche": 2,
    "flexion_tronc": 1, "rotation_tronc": 1, "extension_rachis": 2,
    "isolation_pectoraux": 1, "isolation_dos": 1, "isolation_epaules": 1,
    "isolation_trapezes": 1, "preparation_scapulaire": 1, "isolation_biceps": 1,
    "isolation_triceps": 1, "prehension": 1, "extension_genou": 1, "flexion_genou": 1,
    "adducteurs_abducteurs": 1, "mollets": 1, "cou": 1, "mobilite_articulaire": 1,
    "etirement_statique": 1, "etirement_dynamique": 1, "souplesse": 1,
    "auto_massage": 1, "respiration": 1,
}


def fatigue(ex: dict, sch: str, typ: str, reg: str, art: str) -> dict[str, int]:
    n = norm(ex["nom"])
    fam = FAMILLE_PAR_SCHEMA[sch]
    niv = NIVEAUX.index(ex["niveau"])
    sys_ = _FATIGUE_SYS[sch]
    if fam in ("mobilite", "recuperation"):
        return {"systemique": 1, "locale": 2 if sch == "souplesse" else 1}
    if fam == "cardio":
        if has(n, "recuperation", "educatif", "accelerations", "pas chasses"):
            sys_ = 1 if "recuperation" in n else 2
        if has(n, "sortie longue", "seuil", "denivele", "sprints repetes"):
            sys_ = min(5, sys_ + 1)
        if sch == "marche" and has(n, "lestee", "rapide", "incline"):
            sys_ = 2 if not "denivele" in n else 3
        return {"systemique": sys_, "locale": 2 if sys_ >= 3 else 1}
    # Charge lourde possible sur un mouvement polyarticulaire : + 1.
    if art == "polyarticulaire" and typ in ("barre", "lest") and sch not in ("conditionnement", "halterophilie"):
        sys_ += 1
    if sch in ("charniere_hanche", "squat") and typ == "barre" and has(n, "souleve de terre", "squat") and not has(
        n, "roumain", "jambes tendues", "landmine", "isometri"
    ):
        sys_ = 5
    # Poids du corps, niveau débutant : coût systémique réduit.
    if typ == "poids_du_corps" and niv == 0 and sys_ >= 3:
        sys_ -= 1
    if sch == "halterophilie" and typ == "barre" and not has(n, "muscle", "tirage", "push press"):
        sys_ = 5
    if typ in ("machine", "poulie") and sys_ >= 3 and sch != "squat":
        sys_ -= 1
    if has(n, "supramaximal", "man maker", "devil press"):
        sys_ += 1
    if assiste(ex) and sys_ > 1:
        sys_ -= 1
    sys_ = max(1, min(5, sys_))

    loc = 3
    if reg == "excentrique" or has(n, "nordic", "supramaximal"):
        loc += 1  # dommages musculaires plus marqués en excentrique
    if len(ex["muscles_principaux"]) <= 1 and art != "polyarticulaire":
        loc += 1  # travail concentré sur un seul muscle
    if fam in ("conditionnement", "porte") or sch in ("preparation_scapulaire", "equilibre_mains", "cou"):
        loc -= 1
    if reg == "isometrique" and fam == "gainage":
        loc -= 1
    if niv == 3:
        loc += 1
    if assiste(ex):
        loc -= 1
    loc = max(1, min(5, loc))
    return {"systemique": sys_, "locale": loc}


# --------------------------------------------------------------------------
# 11. Fraction du poids du corps mobilisée
# --------------------------------------------------------------------------

# Masses segmentaires (fraction de la masse totale), Dempster via Winter
# (2009), Biomechanics and Motor Control of Human Movement, 4e éd., tab. 4.1.
SEG_MAIN, SEG_AVANT_BRAS, SEG_PIED, SEG_JAMBE = 0.006, 0.016, 0.0145, 0.0465

REFS_FRACTION = {
    "suprak2011": "Suprak, Dawes & Stephenson (2011), J Strength Cond Res 25(2):497-503",
    "ebben2011": "Ebben et al. (2011), J Strength Cond Res 25(10):2891-2894",
    "winter2009": "Winter (2009), Biomechanics and Motor Control of Human Movement, 4e éd., tab. 4.1 (Dempster)",
}

# Pompe classique : moyenne des positions haute (69,16 %) et basse (75,04 %)
# de Suprak et al. ; sur les genoux : 53,56 % et 61,80 %.
F_POMPE = round((0.6916 + 0.7504) / 2, 2)  # 0,72
F_POMPE_GENOUX = round((0.5356 + 0.6180) / 2, 2)  # 0,58
# Ebben et al. : 64 % (classique), 70 % et 74 % (pieds surélevés de 30,5 et
# 61 cm), 55 % et 41 % (mains surélevées de 30,5 et 61 cm). Rapports
# appliqués à la valeur de Suprak (surélévation moyenne retenue).
F_POMPE_PIEDS_SURELEVES = round(F_POMPE * ((0.70 + 0.74) / 2) / 0.64, 2)  # 0,81
F_POMPE_MAINS_SURELEVEES = round(F_POMPE * ((0.55 + 0.41) / 2) / 0.64, 2)  # 0,54
F_DIPS = round(1 - 2 * (SEG_MAIN + SEG_AVANT_BRAS), 2)  # 0,96
F_TRACTION = round(1 - 2 * SEG_MAIN - SEG_AVANT_BRAS, 2)  # 0,97
F_SQUAT = round(1 - 2 * (SEG_PIED + SEG_JAMBE), 2)  # 0,88
F_SQUAT_UNE_JAMBE = round(1 - (SEG_PIED + SEG_JAMBE), 2)  # 0,94


def fraction_pdc(ex: dict, sch: str, typ: str, reg: str) -> dict | None:
    """Fraction de la masse du corps déplacée (ou soutenue) par les membres
    moteurs ; null quand la notion n'a pas de sens (levier, gainage, cardio)."""
    if typ not in ("poids_du_corps", "lest"):
        return None
    if reg == "isometrique" and typ != "lest":
        return None  # tenue au poids du corps : difficulté de levier, pas de charge
    n = norm(ex["nom"])

    def f(v: float, source: str, ref: str | None, note: str) -> dict:
        return {"valeur": v, "source": source, "reference": ref, "note": note}

    if sch in ("poussee_horizontale", "poussee_inclinee") or (sch == "pliometrie" and "pompe" in n) or (
        sch == "isolation_triceps" and "pompe" in n
    ):
        if "pompe" not in n and "dips" not in n:
            return None
        if "genoux" in n:
            return f(F_POMPE_GENOUX, "publiee", "suprak2011", "pompe sur les genoux, moyenne haut et bas")
        if has(n, "murale", "contre le mur"):
            return f(0.36, "estimee", None, "corps incliné d'environ 60° : estimation statique")
        if has(n, "mains surelevees", "inclinee"):
            return f(F_POMPE_MAINS_SURELEVEES, "derivee", "ebben2011", "rapport mains surélevées / classique appliqué à Suprak 2011")
        if has(n, "pieds sureleves", "declinee"):
            return f(F_POMPE_PIEDS_SURELEVES, "derivee", "ebben2011", "rapport pieds surélevés / classique appliqué à Suprak 2011")
        if has(n, "planche push-up", "maltese", "90"):
            return f(round(1 - 2 * SEG_MAIN, 2), "derivee", "winter2009", "pieds décollés : tout le corps sauf les mains")
        if "pseudo" in n:
            return f(0.80, "estimee", None, "épaules en avant des mains : report de poids vers les mains")
        return f(F_POMPE, "publiee", "suprak2011", "pompe classique, moyenne haut et bas ; variantes de prise assimilées")
    if sch == "poussee_verticale_basse" or (sch == "pliometrie" and "dips" in n):
        if "banc" in n:
            return f(0.50, "estimee", None, "pieds au sol : estimation statique")
        if "machine" in n:
            return None
        return f(F_DIPS, "derivee", "winter2009", "corps entier moins mains et avant-bras")
    if sch == "poussee_verticale_haute":
        if "pike" in n:
            return f(0.70, "estimee", None, "hanches fléchies, pieds en appui : estimation statique")
        if has(n, "hspu", "handstand"):
            return f(F_DIPS, "derivee", "winter2009", "corps entier moins mains et avant-bras")
        return None
    if sch in ("tirage_vertical", "transition_muscle_up") or (
        sch == "figure_dynamique_tirage" and "traction" in n
    ) or (
        sch == "gymnastique_crossfit" and has(n, "traction", "chest-to-bar", "corde") and "burpee" not in n
    ):
        if has(n, "pieds au sol", "barre basse", "saute", "box", "depuis le sol", "balancier", "skin the cat", "german"):
            return None
        return f(F_TRACTION, "derivee", "winter2009", "corps entier moins mains et moitié des avant-bras")
    if sch == "tirage_horizontal":
        if "genoux flechis" in n:
            return f(0.50, "estimee", None, "pieds à plat, genoux fléchis : estimation statique")
        if "pieds sureleves" in n:
            return f(0.70, "estimee", None, "pieds à hauteur des mains : estimation statique")
        return f(0.60, "estimee", None, "corps gainé, talons au sol : estimation statique")
    if sch in ("squat", "fente") or (sch == "pliometrie" and has(n, "squat", "fente", "jump", "saut", "bond")):
        if reg == "isometrique":
            return None
        if has(n, "pistol", "shrimp", "skater", "dragon", "step-up", "unipodal", "unijambiste"):
            return f(F_SQUAT_UNE_JAMBE, "derivee", "winter2009", "corps entier moins jambe et pied d'appui")
        return f(F_SQUAT, "derivee", "winter2009", "corps entier moins jambes et pieds")
    return None


# --------------------------------------------------------------------------
# 12. Difficulté 1-10
# --------------------------------------------------------------------------

_DIFF_BASE = {0: 2, 1: 4, 2: 7, 3: 9}
_DIFF_BORNES = {0: (1, 3), 1: (3, 6), 2: (6, 8), 3: (8, 10)}
_CAT_PLUS = {
    "figure_statique_poussee", "figure_statique_tirage", "figure_statique_mixte",
    "figure_dynamique_poussee", "figure_dynamique_tirage", "freestyle", "halterophilie",
    "transition_muscle_up", "equilibre_mains",
}
_CAT_MOINS = {
    "auto_massage", "respiration", "mobilite_articulaire", "etirement_statique",
    "etirement_dynamique",
}
_REGRESSION = (
    "assist", "negati", "genoux", "partiel", "amplitude reduite", "tuck", "groupe",
    "pieds au sol", "saute", "murale", "contre le mur", "mains surelevees", "inclinee",
    "lean", "au mur", "pieds sur box", "depuis blocs", "suspendu", "levier court",
    "kipping", "recuperation", "banc",
)
_PROGRESSION = (
    "leste", "deficit", "un bras", "une jambe", "une main", "pieds sureleves", "pause",
    "rto", "anneaux", "supramaximal", "chaines", "explosi", "claque", "360", "540",
    "lent", "avance", "declinee", "libre", "straddle", "half-lay", "unilateral",
    "l-sit", "en l", "large", "archer", "typewriter", "debout", "dynamique",
)


def difficulte(ex: dict, sch: str, typ: str, parent: dict | None) -> int:
    niv = NIVEAUX.index(ex["niveau"])
    d = _DIFF_BASE[niv]
    if sch in _CAT_PLUS or ex["categorie"] == "Mouvement de compétition":
        d += 1
    if sch in _CAT_MOINS or typ == "machine":
        d -= 1
    # Position dans la chaîne : à niveau égal avec l'exercice de référence,
    # une régression retire 1, une progression ajoute 1.
    if parent is not None and parent["niveau"] == ex["niveau"]:
        n = norm(ex["nom"])
        np_ = norm(parent["nom"])
        reg = [w for w in _REGRESSION if w in n and w not in np_]
        pro = [w for w in _PROGRESSION if w in n and w not in np_]
        if reg and not pro:
            d -= 1
        elif pro and not reg:
            d += 1
    lo, hi = _DIFF_BORNES[niv]
    return max(lo, min(hi, d))


# --------------------------------------------------------------------------
# 13. Vecteur musculaire et proximité
# --------------------------------------------------------------------------

def vecteur(ex: dict) -> dict[str, float]:
    v: dict[str, float] = {}
    for m in ex["muscles_stabilisateurs"]:
        v[m] = POIDS_STABILISATEUR
    for m in ex["muscles_secondaires"]:
        v[m] = POIDS_SECONDAIRE
    for m in ex["muscles_principaux"]:
        v[m] = POIDS_PRINCIPAL
    return v


def cosinus(a: dict[str, float], b: dict[str, float]) -> float:
    dot = sum(w * b.get(m, 0.0) for m, w in a.items())
    na = math.sqrt(sum(w * w for w in a.values()))
    nb = math.sqrt(sum(w * w for w in b.values()))
    return 0.0 if na == 0 or nb == 0 else dot / (na * nb)
