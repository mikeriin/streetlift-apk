"""Arbres de progression (KT-045). Généré par Claude (L9) — seuils à relire.

Chaque chaîne est une suite d'étapes ; le seuil d'une étape est le critère
mesurable pour passer à l'étape SUIVANTE. Les chaînes partagent des nœuds :
l'union forme un graphe orienté sans cycle (contrôlé par les tests).
"""


def S(series, reps, cote=False):
    return {"series": series, "repetitions": reps, "par_cote": cote,
            "texte": f"{series} × {reps}{' par côté' if cote else ''} propres"}


def T(series, secondes, cote=False):
    return {"series": series, "secondes": secondes, "par_cote": cote,
            "texte": f"{series} × {secondes} s{' par côté' if cote else ''} tenues propres"}


def L(pct, reps):
    return {"lest_pct_poids_de_corps": pct, "repetitions": reps,
            "texte": f"{reps} répétition(s) propres avec un lest de {pct} % du poids de corps"}


CHAINS = [
    ("pompes", "Pompes : du mur à la pompe à un bras", [
        ("Pompes au mur", S(3, 15)), ("Pompes inclinées (mains surélevées)", S(3, 12)),
        ("Pompes à genoux", S(3, 12)), ("Pompes", S(3, 12)), ("Pompes archer", S(3, 6, True)),
        ("Pompes une main (progression)", S(3, 5, True)), ("Pompe à un bras", None)]),
    ("pompes_lestees", "Pompes lestées", [
        ("Pompes", S(3, 20)), ("Pompes lestées", L(20, 8)), ("Pompes lestées lourdes", None)]),
    ("pompes_triceps", "Pompes orientées triceps", [
        ("Pompes", S(3, 15)), ("Pompes diamant", S(3, 12)), ("Pompes diamant surélevées", None)]),
    ("tractions", "Tractions : de la suspension aux tractions lestées", [
        ("Suspension passive pieds au sol", T(3, 30)), ("Dead-hang", T(3, 30)), ("Scapular pull-ups", S(3, 10)),
        ("Rowing australien barre haute", S(3, 12)), ("Australian pull-ups (rows barre basse)", S(3, 12)),
        ("Traction assistée élastique", S(3, 8)), ("Traction négative lente", S(3, 5)),
        ("Traction pronation", S(3, 10)), ("Traction lestée", L(25, 5)), ("Traction lestée lourde", None)]),
    ("tractions_un_bras", "Tractions : vers la traction à un bras", [
        ("Traction pronation", S(3, 12)), ("Traction poitrine-barre", S(3, 8)), ("Traction archer", S(3, 5, True)),
        ("Traction une main (négative)", S(3, 3, True)), ("Traction une main (assistée)", None)]),
    ("dips", "Dips : du banc aux dips lestés", [
        ("Dips sur banc genoux fléchis", S(3, 12)), ("Support hold aux barres", T(3, 30)),
        ("Dips sur banc (triceps)", S(3, 15)), ("Dips assistés élastique", S(3, 8)), ("Dips négatifs", S(3, 5)),
        ("Dips", S(3, 12)), ("Dips lestés", L(30, 5)), ("Dips lestés lourds", None)]),
    ("squat", "Squat : du squat assisté au pistol", [
        ("Squat assisté (appui)", S(3, 15)), ("Squat sur chaise", S(3, 15)), ("Squat au poids de corps", S(3, 20)),
        ("Fente statique (split squat)", S(3, 12, True)), ("Fentes bulgares", S(3, 10, True)),
        ("Pistol squat assisté", S(3, 6, True)), ("Pistol squat sur box", S(3, 5, True)),
        ("Pistol squat", S(3, 5, True)), ("Pistol squat lesté", None)]),
    ("squat_crevette", "Squat sur une jambe, variante crevette", [
        ("Fentes bulgares", S(3, 12, True)), ("Skater squat", S(3, 6, True)), ("Shrimp squat", None)]),
    ("back_squat", "Squat chargé : vers le back squat", [
        ("Squat au poids de corps", S(3, 20)), ("Squat gobelet", S(3, 10)), ("Box squat", S(3, 8)), ("Back squat", None)]),
    ("charniere", "Charnière de hanche : du pont fessier au soulevé de terre roumain", [
        ("Pont fessier au sol", S(3, 15)), ("Charnière de hanche au bâton", S(3, 10)),
        ("Pont fessier une jambe", S(3, 12, True)), ("Hip thrust", S(3, 10)),
        ("Soulevé de terre roumain haltères", S(3, 10)), ("Soulevé de terre roumain", None)]),
    ("gainage_ventral", "Gainage anti-extension : de la planche à la roue debout", [
        ("Planche sur les genoux", T(3, 30)), ("Planche (gainage)", T(3, 45)), ("Planche RKC (coudes)", T(3, 20)),
        ("Body saw (sliders)", S(3, 10)), ("Ab wheel à genoux (amplitude courte)", S(3, 10)),
        ("Ab wheel", S(3, 10)), ("Ab wheel debout", None)]),
    ("gainage_creux", "Gainage creux : du dead bug au dragon flag", [
        ("Dead bug", S(3, 10, True)), ("Hollow body groupé", T(3, 30)), ("Hollow body hold", T(3, 30)),
        ("Hollow rocks", S(3, 15)), ("Dragon flag (progression)", S(3, 5)), ("Dragon flag négatif", S(3, 5)),
        ("Dragon flag complet", None)]),
    ("gainage_lateral", "Gainage latéral", [
        ("Planche latérale sur les genoux", T(3, 30, True)), ("Planche latérale", T(3, 45, True)),
        ("Copenhagen plank", None)]),
    ("muscle_up", "Muscle-up", [
        ("Traction pronation", S(3, 10)), ("Traction poitrine-barre", S(3, 6)),
        ("Transitions de muscle-up à l'élastique", S(3, 5)), ("Négatifs de muscle-up", S(3, 3)),
        ("Tractions explosives poitrine-barre", S(3, 5)), ("Muscle-up kipping", S(3, 3)), ("Muscle-up strict", S(3, 3)),
        ("Muscle-up lesté", None)]),
    ("front_lever", "Front lever", [
        ("Dead-hang", T(3, 30)), ("Scapular pull-ups", S(3, 10)), ("Front lever tuck", T(3, 15)),
        ("Front lever advanced tuck", T(3, 12)), ("Front lever one leg", T(3, 10, True)),
        ("Front lever straddle", T(3, 8)), ("Front lever complet", None)]),
    ("back_lever", "Back lever", [
        ("German hang (tenue)", T(3, 20)), ("Back lever tuck", T(3, 15)), ("Back lever advanced tuck", T(3, 12)),
        ("Back lever straddle", T(3, 8)), ("Back lever complet", None)]),
    ("planche", "Planche (figure)", [
        ("Planche (gainage)", T(3, 45)), ("Planche bras tendus + taps", S(3, 10, True)), ("Planche lean", T(3, 20)), ("Pseudo-planche hold", T(3, 15)),
        ("Pompes pseudo-planche", S(3, 8)), ("Tuck planche", T(3, 12)), ("Planche advanced tuck", T(3, 10)),
        ("Planche straddle", T(3, 6)), ("Planche complète", None)]),
    ("equilibre_mains", "Équilibre sur les mains", [
        ("Pike hold (V inversé)", T(3, 30)), ("Pike push-ups", S(3, 8)), ("ATR dos au mur (tenue)", T(3, 30)),
        ("ATR poitrine au mur (tenue)", T(3, 45)), ("Shoulder taps en ATR", S(3, 5, True)),
        ("ATR (équilibre)", T(3, 20)), ("Handstand walk (marche en ATR)", None)]),
    ("hspu", "Pompes en équilibre (HSPU)", [
        ("Pike push-ups", S(3, 10)), ("Pike push-ups surélevés (pieds sur banc)", S(3, 8)),
        ("Handstand push-ups (mur)", S(3, 5)), ("HSPU stricts en déficit", S(3, 5)),
        ("HSPU freestanding (progression)", None)]),
    ("l_sit", "L-sit", [
        ("Support hold aux barres", T(3, 30)), ("L-sit tuck (tenue)", T(3, 20)), ("L-sit une jambe", T(3, 15, True)),
        ("L-sit", T(3, 20)), ("V-sit progression", T(3, 10)), ("V-sit (tenue)", T(3, 5)),
        ("Manna progression", None)]),
    ("drapeau", "Drapeau", [
        ("Planche latérale", T(3, 60, True)), ("Drapeau vertical (tenue)", T(3, 10, True)),
        ("Human flag tuck", T(3, 8, True)), ("Drapeau straddle", T(3, 5, True)), ("Human flag (drapeau)", None)]),
    ("mobilite_epaules", "Mobilité des épaules", [
        ("Cercles de bras", S(2, 10)), ("Wall slides (glissés au mur)", S(2, 12)),
        ("Dislocations épaules élastique", S(2, 12)), ("Dislocations épaules bâton", S(2, 12)),
        ("Bridge (pont dorsal)", T(3, 20)), ("German hang (tenue)", None)]),
    ("mobilite_hanches", "Mobilité des hanches", [
        ("Étirements fléchisseurs de hanche", T(2, 45, True)), ("Fente basse étirement (hanche)", T(2, 45, True)),
        ("Mobilité hanches (90/90)", T(2, 60, True)), ("Squat profond tenu", T(3, 60)), ("Squat cosaque", None)]),
    ("mobilite_chevilles", "Mobilité des chevilles", [
        ("Mobilisation cheville genou au mur", S(2, 12, True)), ("Mollets unilatéraux sur marche", S(3, 15, True)),
        ("Squat profond tenu", None)]),
]

# Prérequis transverses (en plus de l'étape précédente d'une chaîne)
EXTRA_PREREQ = {
    "Transitions de muscle-up à l'élastique": [("Dips", S(3, 10))],
    "Muscle-up kipping": [("Dips", S(3, 12))],
    "Front lever tuck": [("Traction pronation", S(3, 8)), ("Hollow body hold", T(3, 30))],
    "Tuck planche": [("Dips", S(3, 10))],
    "Handstand push-ups (mur)": [("ATR dos au mur (tenue)", T(3, 30))],
    "L-sit": [("Hollow body hold", T(3, 30))],
    "Human flag tuck": [("Traction pronation", S(3, 8)), ("Pike push-ups", S(3, 8))],
    "Back lever tuck": [("Traction pronation", S(3, 8))],
    "Ab wheel debout": [("Hollow rocks", S(3, 15))],
}
