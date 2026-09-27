"""Fiches biomécaniques des démonstrations (L9R, étape 4).

Chaque fiche décrit un gabarit de mouvement par ses PHASES : angles
articulaires anatomiques (voir body_model.py) au début et à la fin de chaque
phase, articulations motrices, prise et placement, contacts, trajectoire de la
charge, tempo, et les références consultées (sources/cinematique_references.json).
Les images clés sont ensuite CALCULÉES (pose_solver.py) : cinématique directe
sur des segments de longueur fixe, ancrage sur l'appui, et résolution des
paramètres déclarés libres (inclinaison du tronc, cheville…) sous contraintes
(second appui au sol, centre de masse au-dessus de l'appui, main à plat).

Valeurs de référence utilisées (consultées le 26/09/2026, détail dans le JSON) :
  squat        : genou 90-110° (parallèle) à 110-135° (profond), flexion dorsale 25-42°,
                 tronc 30-45° (IJSPT, JSSM 2021, StrengthMath) ;
  soulevé/RDL  : genou ≈ 15-20° (RDL), tronc proche de l'horizontale, tibias verticaux
                 (Physiopedia, Escamilla 2001) ;
  fente        : hanche ≈ 100°, genou ≈ 95-105°, flexion dorsale 3-14° (Frontiers 2023) ;
  pompe        : coude 90-100° en bas (mains largeur d'épaules), 0-5° en haut (UMich) ;
  développé couché : coude 87-114°, abduction 38-66° (Mausehund 2022) ;
  développé militaire : épaule 7° → 136-147° de flexion (JSHS 2014) ;
  dips         : coude 90°, humérus parallèle au sol (Wikipedia, E3 Rehab) ;
  traction     : coude 135-158° en haut, hanche 13-40°, genou 6-58° (UMich, étude pull-up) ;
  hip thrust   : genou 90°, extension complète de hanche sans extension lombaire (UCAM, Brookbush) ;
  handstand    : épaule 180°, mains largeur d'épaules (PLOS ONE 2021, Wikipedia) ;
  L-sit        : hanche 90° ; front lever : corps horizontal (Wikipedia, Coach Bachmann) ;
  swing        : hanche 80° → 0° (SHS/IJSPT) ; curl : coude 0-135°, tempo 2 s / 2 s (MDPI 2023) ;
  amplitudes   : Physiopedia « Range of Motion Normative Values ».
Les valeurs non couvertes par une référence (variantes) sont marquées « transposé » dans `sources`.
"""
import math

import body_model as B

REG = {}   # id -> fiche

BAR_Y = 1.30       # barre de traction (prise) : le personnage suspendu ne touche pas le sol
PB_Y = 0.78        # barres parallèles / station de dips (dessus des barres)
BENCH_Y = 0.25     # banc plat (dessus)
BOX_Y = 0.35
LOW_BAR_Y = 0.55   # barre basse (rowing australien)
RINGS_Y = 1.30

SRC = {
    "squat": [{"url": "https://ijspt.scholasticahq.com/article/", "valeurs": "classes de profondeur en flexion de genou, position du pied", "consulte_le": "2026-09-26"},
              {"url": "https://www.jssm.org/", "valeurs": "squat profond : genou ≈ 140°, flexion dorsale ≈ 42°", "consulte_le": "2026-09-26"},
              {"url": "https://en.wikipedia.org/wiki/Squat_(exercise)", "valeurs": "parallèle = cuisse horizontale, tronc incliné", "consulte_le": "2026-09-26"}],
    "hinge": [{"url": "https://www.physio-pedia.com/Deadlift", "valeurs": "RDL : genou ≈ 15°, tronc vers l'horizontale, barre contre les jambes", "consulte_le": "2026-09-26"},
              {"url": "https://en.wikipedia.org/wiki/Deadlift", "valeurs": "position de départ, barre au-dessus du milieu du pied", "consulte_le": "2026-09-26"}],
    "fente": [{"url": "https://www.frontiersin.org/", "valeurs": "split squat : hanche ≈ 100°, genou ≈ 100°, flexion dorsale 3-14°", "consulte_le": "2026-09-26"},
              {"url": "https://en.wikipedia.org/wiki/Lunge_(exercise)", "valeurs": "genou avant ≈ 90°, genou arrière près du sol", "consulte_le": "2026-09-26"}],
    "pompe": [{"url": "https://en.wikipedia.org/wiki/Push-up", "valeurs": "corps aligné, coudes ≈ 90° en bas", "consulte_le": "2026-09-26"},
              {"url": "https://www.acefitness.org/resources/everyone/exercise-library/41/push-up/", "valeurs": "alignement tête-talons, descente jusqu'à la poitrine près du sol", "consulte_le": "2026-09-26"}],
    "banc": [{"url": "https://en.wikipedia.org/wiki/Bench_press", "valeurs": "coude 87-114° en bas, abduction 38-66°", "consulte_le": "2026-09-26"}],
    "press": [{"url": "https://en.wikipedia.org/wiki/Overhead_press", "valeurs": "épaule ≈ 7° → 136-147° de flexion", "consulte_le": "2026-09-26"}],
    "dips": [{"url": "https://en.wikipedia.org/wiki/Dip_(exercise)", "valeurs": "coude ≈ 90°, humérus parallèle au sol", "consulte_le": "2026-09-26"}],
    "traction": [{"url": "https://en.wikipedia.org/wiki/Pull-up", "valeurs": "suspension bras tendus, menton au-dessus de la barre, coude ≈ 140-158° en haut", "consulte_le": "2026-09-26"}],
    "hip_thrust": [{"url": "https://en.wikipedia.org/wiki/Hip_thrust", "valeurs": "genou ≈ 90°, extension complète de hanche, épaules sur le banc", "consulte_le": "2026-09-26"}],
    "atr": [{"url": "https://en.wikipedia.org/wiki/Handstand", "valeurs": "épaule 180°, corps aligné, mains largeur d'épaules", "consulte_le": "2026-09-26"}],
    "lsit": [{"url": "https://en.wikipedia.org/wiki/L-sit", "valeurs": "hanche 90°, jambes horizontales, épaules abaissées", "consulte_le": "2026-09-26"}],
    "front_lever": [{"url": "https://en.wikipedia.org/wiki/Front_lever", "valeurs": "corps horizontal, bras tendus perpendiculaires au corps", "consulte_le": "2026-09-26"}],
    "back_lever": [{"url": "https://en.wikipedia.org/wiki/Back_lever", "valeurs": "corps horizontal face au sol, bras tendus derrière", "consulte_le": "2026-09-26"}],
    "planche": [{"url": "https://en.wikipedia.org/wiki/Planche_(exercise)", "valeurs": "corps horizontal en appui sur les mains, épaules en avant des mains", "consulte_le": "2026-09-26"}],
    "muscle_up": [{"url": "https://en.wikipedia.org/wiki/Muscle-up", "valeurs": "3 phases : traction haute, transition, dip", "consulte_le": "2026-09-26"}],
    "plank": [{"url": "https://en.wikipedia.org/wiki/Plank_(exercise)", "valeurs": "corps aligné, coude sous l'épaule", "consulte_le": "2026-09-26"}],
    "hollow": [{"url": "https://en.wikipedia.org/wiki/Hollow_body_position", "valeurs": "lombaires plaquées, épaules et jambes décollées", "consulte_le": "2026-09-26"}],
    "swing": [{"url": "https://ijspt.scholasticahq.com/", "valeurs": "hanche 80° → 0°, cycle ≈ 1,8-1,9 s", "consulte_le": "2026-09-26"}],
    "curl": [{"url": "https://www.mdpi.com/2075-4663/", "valeurs": "coude 0-135°, tempo 2 s / 2 s", "consulte_le": "2026-09-26"}],
    "cmj": [{"url": "https://www.mdpi.com/", "valeurs": "profondeur du contre-mouvement 0,23-0,43 × longueur de jambe", "consulte_le": "2026-09-26"}],
    "burpee": [{"url": "https://en.wikipedia.org/wiki/Burpee", "valeurs": "séquence squat, planche, squat, saut", "consulte_le": "2026-09-26"}],
    "rom": [{"url": "https://www.physio-pedia.com/Range_of_Motion_Normative_Values", "valeurs": "amplitudes articulaires normales", "consulte_le": "2026-09-26"}],
    "row": [{"url": "https://en.wikipedia.org/wiki/Bent-over_row", "valeurs": "tronc incliné vers l'horizontale, genoux légèrement fléchis, coudes tirés derrière", "consulte_le": "2026-09-26"}],
    "inverted_row": [{"url": "https://en.wikipedia.org/wiki/Inverted_row", "valeurs": "corps aligné sous la barre, poitrine à la barre", "consulte_le": "2026-09-26"}],
    "transpose": [{"url": None, "valeurs": "variante transposée du gabarit de référence (angles ajustés, pas de valeur publiée trouvée)", "consulte_le": "2026-09-26"}],
}


# ---------------------------------------------------------------- utilitaires
def A(**kw):
    """Angles anatomiques ; clés génériques (hanche, genou…) appliquées aux deux côtés sauf surcharge _g/_d."""
    a = {"t": kw.pop("t", 0.0), "n": kw.pop("n", 0.0)}
    if "p" in kw:
        a["p"] = kw.pop("p")
    for k in B.JOINT_KEYS:
        base = kw.pop(k, 0.0)
        a[f"{k}_g"] = kw.pop(f"{k}_g", base)
        a[f"{k}_d"] = kw.pop(f"{k}_d", base)
    assert not kw, kw
    return a


def on(joint, y=0.0, x=0.0):
    return (joint, (x, y + B.contact_offset(joint)))


def KF(label, angles, anchor, free=None, cons=None, hold=0.0, dur=1.0, phase=None, equilibre=True):
    return {"label": label, "angles": angles, "anchor": anchor, "free": free or [], "constraints": cons or [],
            "hold": hold, "dur": dur, "phase": phase, "equilibre": equilibre}


FLAT_FOOT_D = ("abs", "ft_d", 90)
FLAT_FOOT_G = ("abs", "ft_g", 90)
HAND_FLAT_D = ("abs", "ha_d", 90)
HAND_FLAT_G = ("abs", "ha_g", 90)
BALANCE = ("com_over", "talon_d", "pied_d")
FEET = [{"joint": "talon_d", "with": "sol"}, {"joint": "pied_d", "with": "sol"}]
FEET_BOTH = FEET + [{"joint": "talon_g", "with": "sol"}, {"joint": "pied_g", "with": "sol"}]
HANDS_BAR = [{"joint": "prise_g", "with": "barre_fixe"}, {"joint": "prise_d", "with": "barre_fixe"}]


def sheet(id_, vue, kfs, props=None, contacts=None, boucle="aller-retour", phases=None, moteurs=None, prise="",
          placement="", contacts_texte="", trajectoire="", tempo="", sources=None, rom_exceptions=None, debout=False,
          charge=None, note="", origine_fixe=False):
    REG[id_] = {"id": id_, "vue": vue, "images_cles": kfs, "accessoires": props or [], "contacts": contacts or [],
                "boucle": boucle, "phases": phases or [], "articulations_motrices": moteurs or [], "prise": prise,
                "placement": placement, "contacts_texte": contacts_texte, "trajectoire_charge": trajectoire,
                "tempo": tempo, "sources": sources or SRC["transpose"], "rom_exceptions": rom_exceptions or {},
                "debout": debout, "charge": charge, "note": note, "origine_fixe": origine_fixe}


def phase(nom, moteurs, debut, fin, texte=""):
    return {"nom": nom, "articulations": moteurs, "angles_debut": debut, "angles_fin": fin, "texte": texte}


# ================================================================ DEBOUT : SQUATS
ARMS = {
    "avant": dict(epaule=90, coude=0),
    "gobelet": dict(epaule=25, coude=140),
    "dos": dict(epaule=-40, coude=130),
    "front": dict(epaule=95, coude=150),
    "overhead": dict(epaule=178, coude=0),
    "hanches": dict(epaule=-15, coude=50),
    "bas": dict(epaule=5, coude=0),
    "zercher": dict(epaule=30, coude=150),
    "poitrine": dict(epaule=40, coude=140),
}


def squat(id_, arms="avant", genou=105, hanche=100, tronc=(15, 48), hold_bas=0.2, props=None, jump=False, box=False,
          charge=None, note="", sources=None, debout=True, deep=False):
    """Squat bipodal : haut debout, bas à la profondeur donnée. Tronc résolu par l'équilibre, cheville par le pied à plat."""
    arm = ARMS[arms]
    top = A(t=2, **arm)
    bot = A(t=tronc[0] + 10, hanche=hanche, genou=genou, cheville=25, **arm)
    kfs = [KF("haut", top, on("talon_d"), [("t", -5, 12), ("cheville", -5, 10)], [BALANCE, FLAT_FOOT_D], hold=0.3, dur=1.4, phase="descente"),
           KF("bas", bot, on("talon_d"), [("t", tronc[0], tronc[1]), ("cheville", 5, 38)], [BALANCE, FLAT_FOOT_D],
              hold=hold_bas if not box else 0.6, dur=1.0, phase="remontée")]
    pr = list(props or [])
    loop = "aller-retour"
    if jump:
        air = A(t=0, hanche=5, genou=5, cheville=-35, epaule=-25, coude=10)
        kfs.append(KF("envol", air, ("pied_d", (0.0, 0.16)), [("t", -8, 8)], [("com_x", "pied_d", 0.0)], dur=0.5, phase="réception"))
        loop = "cycle"
    if box:
        pr.append({"type": "box", "x": -0.36, "y": 0.0, "w": 0.30, "h": BOX_Y, "static": True})
    sheet(id_, "profil", kfs, pr, ([{"joint": "talon_d", "with": "sol", "kf": [0, 1]}, {"joint": "pied_d", "with": "sol", "kf": [0, 1]}] if jump else FEET), loop,
          phases=[phase("descente", ["hanche", "genou", "cheville"], {"hanche": 0, "genou": 0, "tronc": 0},
                        {"hanche": hanche, "genou": genou, "tronc": f"{tronc[0]}-{tronc[1]} (équilibre)"}, "Flexion simultanée des hanches et des genoux, talons au sol."),
                  phase("remontée", ["genou", "hanche"], {"hanche": hanche, "genou": genou}, {"hanche": 0, "genou": 0}, "Extension jusqu'à la station debout.")],
          moteurs=["hanche", "genou", "cheville"], prise=f"bras : {arms}", placement="pieds largeur d'épaules, pointes légèrement ouvertes",
          contacts_texte="pieds à plat au sol pendant tout le mouvement", trajectoire="verticale, au-dessus du milieu du pied",
          tempo="2 s descente, 1 s remontée", sources=sources or SRC["squat"], debout=debout, charge=charge, note=note)


squat("squat.pdc", "avant")
squat("squat.profond", "avant", genou=125, hanche=115, tronc=(15, 40), deep=True, note="squat complet (cuisses sous l'horizontale)")
squat("squat.dos", "dos", genou=110, hanche=105, tronc=(20, 45),
      props=[{"type": "barre_chargee", "attach": "epaule_d", "offset": [-0.03, 0.045]}], charge="barre sur les trapèzes")
squat("squat.front", "front", genou=115, hanche=100, tronc=(5, 25),
      props=[{"type": "barre_chargee", "attach": "epaule_d", "offset": [0.07, 0.03]}], charge="barre sur les clavicules, coudes hauts")
squat("squat.gobelet", "gobelet", genou=115, hanche=105, tronc=(10, 35),
      props=[{"type": "kettlebell", "attach": "prises", "offset": [0.0, 0.05]}], charge="kettlebell tenue contre la poitrine")
squat("squat.overhead", "overhead", genou=115, hanche=105, tronc=(5, 25),
      props=[{"type": "barre_chargee", "attach": "prises"}], charge="barre bras tendus au-dessus de la tête")
squat("squat.zercher", "zercher", genou=110, hanche=105, tronc=(15, 40),
      props=[{"type": "barre_chargee", "attach": "prises", "offset": [0.02, 0.0]}], charge="barre dans le pli des coudes")
squat("squat.saute", "hanches", genou=90, hanche=85, tronc=(20, 45), jump=True, sources=SRC["squat"] + SRC["cmj"])
squat("squat.box", "dos", genou=100, hanche=105, tronc=(20, 45), box=True,
      props=[{"type": "barre_chargee", "attach": "epaule_d", "offset": [-0.03, 0.045]}], charge="barre sur les trapèzes")
squat("squat.chaise", "avant", genou=95, hanche=95, tronc=(15, 40), box=True, note="squat sur chaise : la box figure la chaise")
squat("squat.assiste", "avant", genou=110, hanche=105, tronc=(10, 35),
      props=[{"type": "poteau", "x": 0.42, "static": True}], note="mains sur un support (poteau) : bras tendus devant")
squat("squat.elastique", "avant", genou=105, hanche=100, props=[{"type": "elastique", "x": 0.0, "y": 0.0, "to": ["prise_d"], "static": True}])

# wall sit : tenue statique
sheet("squat.wall_sit", "profil",
      [KF("tenue", A(t=0, hanche=90, genou=90, cheville=0, epaule=0, coude=0), on("talon_d"), [], [], hold=2.0, dur=0.5)],
      [{"type": "mur", "x": -0.32, "static": True}], FEET, "aller-retour",
      phases=[phase("tenue", ["genou", "hanche"], {"hanche": 90, "genou": 90}, {"hanche": 90, "genou": 90}, "Dos plaqué au mur, cuisses horizontales.")],
      moteurs=["genou"], placement="dos au mur, pieds avancés", contacts_texte="dos contre le mur, pieds à plat", tempo="tenue", sources=SRC["squat"], debout=False)

# squat profond tenu (mobilité)
sheet("debout.squat_profond", "profil",
      [KF("tenue", A(t=22, hanche=118, genou=128, cheville=34, epaule=110, coude=10), on("talon_d"), [("t", 10, 40), ("cheville", 20, 38)], [BALANCE, FLAT_FOOT_D], hold=2.0, dur=0.6)],
      [], FEET, "aller-retour", phases=[phase("tenue", ["hanche", "genou", "cheville"], {"genou": 135}, {"genou": 135}, "Squat complet tenu, talons au sol.")],
      moteurs=["hanche", "genou", "cheville"], tempo="tenue 30 s à 2 min", sources=SRC["squat"])


# ================================================================ DEBOUT : PISTOL, FENTES
def pistol(id_, assiste=False, box=False, shrimp=False):
    if shrimp:
        top = A(t=5, hanche_g=-5, genou_g=100, cheville_g=-20, epaule=60, coude=20)
        bot = A(t=30, hanche=95, genou_d=115, cheville_d=30, hanche_g=-15, genou_g=120, cheville_g=-30, epaule=70, coude=20)
        bot["hanche_g"] = -15
        kfs = [KF("haut", top, on("talon_d"), [("t", -5, 15)], [BALANCE, FLAT_FOOT_D], hold=0.3, dur=1.6),
               KF("bas", bot, on("talon_d"), [("t", 15, 50), ("cheville_d", 10, 38)], [BALANCE, FLAT_FOOT_D, ("y", "genou_g", 0.03)], hold=0.2, dur=1.2)]
        note = "squat crevette : jambe arrière fléchie, genou vers le sol"
    else:
        top = A(t=5, hanche_g=20, genou_g=0, cheville_g=10, epaule=70, coude=10)
        bot = A(t=35, hanche_d=120, genou_d=130, cheville_d=35, hanche_g=125, genou_g=0, cheville_g=-20, epaule=80, coude=10)
        kfs = [KF("haut", top, on("talon_d"), [("t", -5, 15)], [BALANCE, FLAT_FOOT_D], hold=0.3, dur=1.6),
               KF("bas", bot, on("talon_d"), [("t", 20, 55), ("cheville_d", 15, 38), ("hanche_g", 90, 135)], [BALANCE, FLAT_FOOT_D, ("abs", "th_g", 88)], hold=0.2, dur=1.2)]
        note = "pistol : jambe libre tendue devant"
    props = []
    if assiste:
        props.append({"type": "poteau", "x": 0.42, "static": True})
        for k in kfs:
            k["angles"]["epaule_g"] = k["angles"]["epaule_d"] = 75
    if box:
        props.append({"type": "box", "x": -0.40, "y": 0.0, "w": 0.30, "h": BOX_Y, "static": True})
    sheet(id_, "profil", kfs, props, FEET, phases=[phase("descente", ["hanche", "genou", "cheville"], {"genou": 0}, {"genou": 135 if not shrimp else 115}),
                                                   phase("remontée", ["genou", "hanche"], {}, {})],
          moteurs=["hanche", "genou", "cheville"], placement="appui sur une jambe", contacts_texte="pied d'appui à plat",
          tempo="2 s descente, 1-2 s remontée", sources=SRC["squat"], debout=True, note=note)


pistol("pistol.libre")
pistol("pistol.assiste", assiste=True)
pistol("pistol.box", box=True)
pistol("pistol.shrimp", shrimp=True)


def lunge(id_, kind="avant", bench=False, props=None, charge=None, arms=None, deficit=False):
    arm = arms or dict(epaule=5, coude=0)
    dz = 0.08 if deficit else 0.0     # déficit : pied avant sur une marche, le genou arrière descend plus bas que le pied avant
    if kind == "laterale":
        # vue de face : fente latérale (abduction de la jambe droite)
        top = A(t=0, **arm)
        bot = A(t=15, hanche_d=55, genou_d=95, hanche_g=40, genou_g=0, **arm)
        kfs = [KF("debout", top, on("pied_d"), [], [], hold=0.3, dur=1.2),
               KF("fente latérale", bot, on("pied_d", 0.0, -0.1), [("p", -15, 15)], [("y", "pied_g", 0.0)], hold=0.2, dur=1.0)]
        sheet(id_, "face", kfs, props or [], FEET_BOTH, phases=[phase("descente", ["hanche", "genou"], {"genou": 0}, {"genou": 95})],
              moteurs=["hanche", "genou"], placement="grand pas de côté, jambe opposée tendue", tempo="2 s / 1 s", sources=SRC["fente"], debout=True, charge=charge)
        return
    if bench:
        top = A(t=5, hanche_d=25, genou_d=15, cheville_d=5, hanche_g=-25, genou_g=95, cheville_g=-45, **arm)
        bot = A(t=15, hanche_d=95, genou_d=100, cheville_d=15, hanche_g=-10, genou_g=115, cheville_g=-45, **arm)
        cons_top = [FLAT_FOOT_D, ("y", "pied_g", BENCH_Y)]
        cons_bot = [FLAT_FOOT_D, ("y", "pied_g", BENCH_Y)]
        pr = [{"type": "banc", "x": -0.80, "y": BENCH_Y, "w": 0.45, "static": True}] + list(props or [])
        contacts = FEET + [{"joint": "pied_g", "with": "banc"}]
        placement = "pied arrière posé sur le banc, pied avant à un grand pas"
    else:
        top = A(t=3, hanche_d=30, genou_d=15, cheville_d=5, hanche_g=-20, genou_g=25, cheville_g=-35, **arm)
        bot = A(t=8, hanche_d=95 + (10 if deficit else 0), genou_d=95 + (10 if deficit else 0), cheville_d=8, hanche_g=-12, genou_g=95, cheville_g=-45, **arm)
        cons_top = [FLAT_FOOT_D, ("y", "pied_g", 0.0)]
        cons_bot = [FLAT_FOOT_D, ("y", "pied_g", 0.0), ("y", "genou_g", 0.05)]
        pr = list(props or [])
        if deficit:
            pr.insert(0, {"type": "marche", "x": -0.10, "y": 0.0, "w": 0.30, "h": dz, "static": True})
        contacts = ([{"joint": "talon_d", "with": "marche"}, {"joint": "pied_d", "with": "marche"}] if deficit else FEET) + [{"joint": "pied_g", "with": "sol"}]
        placement = "pas d'un mètre environ, pied arrière sur la pointe" + (" ; pied avant sur une marche (déficit)" if deficit else "")
    both = ("com_over", "pied_g", "pied_d")
    kfs = [KF("haut", top, on("talon_d", dz), [("hanche_g", -45, 20), ("genou_g", 0, 120), ("cheville_g", -60, 30), ("cheville_d", -10, 38), ("t", -5, 12)], cons_top + [both], hold=0.3, dur=1.2),
           KF("bas", bot, on("talon_d", dz), [("hanche_g", -45, 20), ("genou_g", 40, 130), ("cheville_g", -60, 30), ("cheville_d", -10, 38), ("t", 0, 25)], cons_bot + [both], hold=0.2, dur=1.0)]
    sheet(id_, "profil", kfs, pr, contacts,
          phases=[phase("descente", ["hanche", "genou"], {"genou_avant": 15, "hanche_avant": 30}, {"genou_avant": 95, "hanche_avant": 95}, "Genou avant au-dessus du pied, genou arrière vers le sol."),
                  phase("remontée", ["genou", "hanche"], {}, {})],
          moteurs=["hanche", "genou"], placement=placement, contacts_texte="pied avant à plat, pied arrière sur la pointe" + (" (banc)" if bench else ""),
          trajectoire="verticale", tempo="2 s descente, 1 s remontée", sources=SRC["fente"], debout=True, charge=charge)


lunge("fente.avant")
lunge("fente.bulgare", bench=True)
lunge("fente.laterale", kind="laterale")
lunge("fente.deficit", deficit=True)
lunge("fente.marchee", props=None)
lunge("fente.halteres", props=[{"type": "halteres", "attach": "prise_d"}, {"type": "halteres", "attach": "prise_g"}], charge="haltères le long du corps")


def step(id_, h=BOX_Y, arms=None):
    arm = arms or dict(epaule=5, coude=0)
    down = A(t=8, hanche_d=(70 if h < 0.35 else 95), genou_d=(80 if h < 0.35 else 105), cheville_d=15, hanche_g=5, genou_g=5, cheville_g=0, **arm)
    up = A(t=3, hanche_d=5, genou_d=5, cheville_d=0, hanche_g=-12, genou_g=35, cheville_g=-20, **arm)
    kfs = [KF("pied sur la box", down, on("talon_g", 0.0, -0.16), [("hanche_d", 20, 125), ("genou_d", 30, 135), ("cheville_d", -20, 38), ("t", 0, 25)], [("y", "talon_d", h), ("x", "talon_d", 0.14), FLAT_FOOT_D, FLAT_FOOT_G], hold=0.2, dur=1.0),
           KF("debout sur la box", up, on("talon_d", h, 0.10), [("t", -5, 10)], [FLAT_FOOT_D, BALANCE], hold=0.3, dur=1.0)]
    sheet(id_, "profil", kfs, [{"type": "box", "x": 0.04, "y": 0.0, "w": 0.40, "h": h, "static": True}],
          [{"joint": "talon_d", "with": "box"}, {"joint": "pied_d", "with": "box"}, {"joint": "talon_g", "with": "sol", "kf": [0]}, {"joint": "pied_g", "with": "sol", "kf": [0]}], phases=[phase("montée", ["hanche", "genou"], {"genou_avant": 80}, {"genou_avant": 5}, "Pousse sur le pied posé, sans élan de la jambe arrière.")],
          moteurs=["hanche", "genou"], placement="pied entier posé sur la box", tempo="1 s montée, 2 s descente", sources=SRC["fente"], debout=True)


step("step.bas", h=0.28)
step("step.haut", h=0.42)


# ================================================================ DEBOUT : CHARNIÈRES
def hinge(id_, hanche=88, genou=18, tronc=(55, 88), props=None, charge=None, one_leg=False, from_floor=False, arms_hang=True, note="", baton=False):
    top = A(t=2, epaule=2, coude=0)
    if from_floor:
        bot = A(t=60, hanche=110, genou=60, cheville=20, epaule=60, coude=0)
        tr = (45, 75)
    else:
        bot = A(t=tronc[0] + 10, hanche=hanche, genou=genou, cheville=8, epaule=tronc[0] + 10, coude=0)
        tr = tronc
    free_top = [("t", -5, 10)]
    free_bot = [("t", tr[0], tr[1]), ("cheville", -10, 30)]
    cons_bot = [BALANCE, FLAT_FOOT_D]
    if arms_hang:
        cons_bot.append(("abs", "ua_d", 0))       # bras verticaux (la charge pend)
        free_bot.append(("epaule", 0, 120))
    if one_leg:
        bot["hanche_g"], bot["genou_g"], bot["cheville_g"] = -25, 5, -30
        contacts = FEET
    else:
        contacts = FEET_BOTH
    if baton:
        for k in (top, bot):
            k.update({"epaule_d": 165, "coude_d": 60, "epaule_g": -40, "coude_g": 100})
        cons_bot = [BALANCE, FLAT_FOOT_D]
        free_bot = [("t", tr[0], tr[1]), ("cheville", -10, 30)]
    kfs = [KF("haut", top, on("talon_d"), free_top, [BALANCE, FLAT_FOOT_D], hold=0.3, dur=1.4),
           KF("bas", bot, on("talon_d"), free_bot, cons_bot, hold=0.2, dur=1.2)]
    sheet(id_, "profil", kfs, props or [], contacts,
          phases=[phase("descente", ["hanche"], {"hanche": 0, "genou": 0}, {"hanche": hanche, "genou": genou, "tronc": f"{tr[0]}-{tr[1]}"}, "Hanches vers l'arrière, dos plat, genoux légèrement fléchis."),
                  phase("remontée", ["hanche"], {"hanche": hanche}, {"hanche": 0}, "Extension des hanches, fessiers serrés en haut.")],
          moteurs=["hanche"], placement="pieds largeur de hanches, charge contre les cuisses", contacts_texte="pieds à plat, charge au contact des jambes",
          trajectoire="verticale, le long des jambes", tempo="3 s descente, 1 s remontée", sources=SRC["hinge"], debout=True, charge=charge, note=note)


hinge("hinge.barre", props=[{"type": "barre_chargee", "attach": "prises"}], charge="barre tenue bras tendus")
hinge("hinge.sol", from_floor=True, props=[{"type": "barre_chargee", "attach": "prises"}], charge="barre au sol au départ", note="soulevé de terre depuis le sol")
hinge("hinge.halteres", props=[{"type": "halteres", "attach": "prise_d"}, {"type": "halteres", "attach": "prise_g"}], charge="haltères")
hinge("hinge.kettlebell", props=[{"type": "kettlebell", "attach": "prises"}], charge="kettlebell")
hinge("hinge.unijambe", one_leg=True, hanche=90, genou=15, tronc=(60, 90), props=[{"type": "halteres", "attach": "prise_d"}], charge="haltère", note="jambe libre tendue vers l'arrière")
hinge("hinge.pdc", arms_hang=False, note="charnière au poids de corps, mains sur les hanches")
hinge("hinge.baton", baton=True, arms_hang=False, props=[{"type": "baton", "between": ["prise_g", "prise_d"]}], note="bâton dans le dos : contact tête, dos, sacrum")
hinge("hinge.good_morning", hanche=85, genou=15, tronc=(60, 88), arms_hang=False,
      props=[{"type": "barre_chargee", "attach": "epaule_d", "offset": [-0.03, 0.045]}], charge="barre sur les trapèzes", note="good morning")
REG["hinge.good_morning"]["images_cles"][0]["angles"].update({"epaule_g": -40, "epaule_d": -40, "coude_g": 130, "coude_d": 130})
REG["hinge.good_morning"]["images_cles"][1]["angles"].update({"epaule_g": -40, "epaule_d": -40, "coude_g": 130, "coude_d": 130})
hinge("debout.jefferson", hanche=95, genou=5, tronc=(70, 95), note="enroulement vertébral segment par segment (le tronc rigide du modèle approxime l'enroulement)")


def swing(id_):
    back = A(t=55, hanche=85, genou=25, cheville=10, epaule=65, coude=5)
    top = A(t=0, hanche=0, genou=0, cheville=0, epaule=90, coude=5)
    kfs = [KF("charge entre les jambes", back, on("talon_d"), [("t", 40, 75), ("cheville", -5, 25)], [BALANCE, FLAT_FOOT_D], hold=0.0, dur=0.45),
           KF("kettlebell à hauteur d'épaule", top, on("talon_d"), [("t", -8, 6)], [BALANCE, FLAT_FOOT_D], hold=0.05, dur=0.5)]
    sheet(id_, "profil", kfs, [{"type": "kettlebell", "attach": "prises"}], FEET_BOTH,
          phases=[phase("propulsion", ["hanche"], {"hanche": 85}, {"hanche": 0}, "Extension explosive des hanches ; les bras suivent."),
                  phase("retour", ["hanche"], {"hanche": 0}, {"hanche": 85}, "La kettlebell repasse haut entre les cuisses.")],
          moteurs=["hanche"], placement="pieds un peu plus larges que les hanches", trajectoire="arc de cercle des cuisses à la hauteur des épaules",
          tempo="cycle ≈ 1,8 s", sources=SRC["swing"], debout=True, charge="kettlebell à deux mains")


swing("olympique.swing")


# ================================================================ PONTS ET HIP THRUST
def bridge(id_, bench=False, one_leg=False, props=None, charge=None, feet_up=False):
    ys = BENCH_Y + 0.07 if bench else 0.07
    fy = 0.22 if feet_up else 0.0
    if bench:
        low = A(t=-50, hanche=45, genou=90, cheville=10, epaule=-45, coude=90, n=40)
        high = A(t=-92, hanche=0, genou=90, cheville=5, epaule=-60, coude=90, n=55)
    else:
        low = A(t=-90, hanche=45, genou=95, cheville=-30, epaule=8, coude=0, n=10)
        high = A(t=-112, hanche=0, genou=90, cheville=-20, epaule=8, coude=0, n=15)
    if one_leg:
        for k in (low, high):
            k["hanche_g"] = k["hanche_d"]
            k["genou_g"] = 0
            k["cheville_g"] = -30
    if feet_up:
        for k in (low, high):
            k["hanche_d"] += 15
            k["genou_d"] = 70
    kfs = [KF("bas", low, on("epaule_d", ys - B.contact_offset("epaule_d"), 0.0), [("t", -100, -30), ("genou", 40, 120), ("cheville", -50, 38)], [("y", "talon_d", fy), FLAT_FOOT_D], hold=0.2, dur=1.0),
           KF("haut", high, on("epaule_d", ys - B.contact_offset("epaule_d"), 0.0), [("t", -125, -80), ("genou", 40, 120), ("cheville", -50, 38)], [("y", "talon_d", fy), FLAT_FOOT_D], hold=0.5, dur=1.0)]
    pr = list(props or [])
    if bench:
        pr.insert(0, {"type": "banc", "x": -0.55, "y": BENCH_Y, "w": 0.5, "static": True, "layer": "arriere"})
    if feet_up:
        pr.insert(0, {"type": "box", "x": 0.30, "y": 0.0, "w": 0.30, "h": fy, "static": True, "layer": "arriere"})
    sheet(id_, "profil", kfs, pr, [{"joint": "talon_d", "with": "box" if feet_up else "sol"}, {"joint": "epaule_d", "with": "banc" if bench else "sol"}],
          phases=[phase("montée", ["hanche"], {"hanche": 70 if bench else 55}, {"hanche": 0}, "Extension de hanche jusqu'à l'alignement genou-hanche-épaule, menton rentré."),
                  phase("descente", ["hanche"], {"hanche": 0}, {"hanche": 70 if bench else 55})],
          moteurs=["hanche"], placement="pieds à plat, genoux à 90° en haut" + (", épaules sur le banc" if bench else ", épaules au sol"),
          contacts_texte="pieds au sol ; " + ("haut du dos sur le banc" if bench else "épaules au sol"), trajectoire="verticale (charge sur les hanches)",
          tempo="1 s montée, 1 s tenue, 2 s descente", sources=SRC["hip_thrust"], debout=False, charge=charge)


bridge("pont.fessier")
bridge("pont.unijambe", one_leg=True)
bridge("pont.unijambe_pieds_hauts", one_leg=True, feet_up=True)
bridge("banc.hip_thrust", bench=True, props=[{"type": "barre_chargee", "attach": "bassin", "offset": [0.02, 0.09]}], charge="barre sur les hanches")
bridge("banc.hip_thrust_pdc", bench=True)


# ================================================================ POMPES ET PLANCHES (appui facial)
def pushup(id_, coude_bas=95, epaule_haut=88, epaule_bas=50, incline_y=0.0, decline_y=0.0, knees=False, hips=0, props=None,
           charge=None, note="", sources=None, hands_y=None, wall=False, explosive=False):
    """Appui facial : mains ancrées (sol, support ou mur), corps aligné, tronc résolu par le contact des pieds/genoux."""
    hy = hands_y if hands_y is not None else incline_y
    if wall:
        top = A(t=18, hanche=0, genou=0, cheville=8, epaule=105, coude=0)
        bot = A(t=22, hanche=0, genou=0, cheville=12, epaule=85, coude=85)
        anchor = ("prise_d", (0.0, 0.88))
        kfs = [KF("haut", top, anchor, [("t", 5, 35), ("epaule", 70, 135), ("poignet", -60, 60), ("cheville", -10, 30)], [("y", "talon_d", 0.0), FLAT_FOOT_D, ("abs", "ha_d", 180)], hold=0.3, dur=1.0),
               KF("bas", bot, anchor, [("t", 5, 40), ("epaule", 50, 120), ("poignet", -60, 60), ("cheville", -10, 30)], [("y", "talon_d", 0.0), FLAT_FOOT_D, ("abs", "ha_d", 180)], hold=0.2, dur=1.0)]
        sheet(id_, "profil", kfs, [{"type": "mur", "x": 0.0, "static": True}], [{"joint": "prise_d", "with": "mur"}, {"joint": "talon_d", "with": "sol"}],
              phases=[phase("descente", ["coude", "epaule"], {"coude": 0}, {"coude": 85}), phase("poussée", ["coude", "epaule"], {"coude": 85}, {"coude": 0})],
              moteurs=["coude", "epaule"], placement="mains au mur à hauteur d'épaules, pieds à un pas", contacts_texte="mains sur le mur, pieds au sol",
              tempo="2 s / 1 s", sources=sources or SRC["pompe"], note="pompe au mur")
        return
    foot_cons = ("y", "genou_d", 0.0) if knees else ("y", "pied_d", decline_y)
    t0 = 88 if decline_y else 65
    top = A(t=t0, hanche=hips, genou=(90 if knees else 0), cheville=(-52 if knees else (-15 if decline_y else -35)), epaule=epaule_haut, coude=0, n=20)
    bot = A(t=t0 + 8, hanche=hips, genou=(90 if knees else 0), cheville=(-52 if knees else (-10 if decline_y else -25)), epaule=epaule_bas, coude=coude_bas, n=25)
    anchor = ("prise_d", (0.0, hy))
    free = [("t", 40, 100), ("poignet", -88, 88), ("cheville", -58, 15)]
    cons = [foot_cons, HAND_FLAT_D]
    kfs = [KF("haut", top, anchor, free + [("epaule", 40, 110)], cons + ([("abs", "ua_d", 0)] if not incline_y else []), hold=0.3, dur=1.0), KF("bas", bot, anchor, free, cons, hold=0.15, dur=1.0)]
    pr = list(props or [])
    if incline_y:
        pr.insert(0, {"type": "box", "x": -0.20, "y": 0.0, "w": 0.40, "h": incline_y, "static": True})
    if decline_y:
        pr.insert(0, {"type": "box", "x": -1.12, "y": 0.0, "w": 0.34, "h": decline_y, "static": True})
    if explosive:
        air = A(t=65, hanche=hips, genou=0, cheville=-35, epaule=95, coude=0, n=20)
        kfs.append(KF("envol", air, ("prise_d", (0.0, hy + 0.08)), [("t", 40, 100), ("poignet", -88, 88), ("cheville", -58, 15)], [("y", "pied_d", decline_y)], hold=0.0, dur=0.35))
    hand_with = "sol" if hy == 0 else ("anneaux" if any(p.get("type") == "anneaux" for p in pr) else ("parallettes" if any(p.get("type") == "cale" for p in pr) else "box"))
    contacts = [{"joint": "prise_d", "with": hand_with, "kf": ([0, 1] if explosive else "all")}, {"joint": "genou_d" if knees else "pied_d", "with": "sol" if not decline_y else "box"}]
    sheet(id_, "profil", kfs, pr, contacts, "cycle" if explosive else "aller-retour",
          phases=[phase("descente", ["coude", "epaule"], {"coude": 0, "epaule": epaule_haut}, {"coude": coude_bas, "epaule": epaule_bas}, "Corps gainé en ligne, coudes à environ 45° du buste."),
                  phase("poussée", ["coude", "epaule"], {"coude": coude_bas}, {"coude": 0}, "Extension complète des coudes.")],
          moteurs=["coude", "epaule"], prise="mains à plat, largeur d'épaules" if coude_bas < 100 else "mains serrées", placement="corps aligné de la tête aux talons",
          contacts_texte="mains au sol, " + ("genoux au sol" if knees else "pointes des pieds au sol"), trajectoire="le buste descend en ligne droite",
          tempo="2 s descente, 1 s poussée", sources=sources or SRC["pompe"], charge=charge, note=note)


pushup("pompe.standard")
pushup("pompe.genoux", knees=True, coude_bas=95)
pushup("pompe.inclinee", incline_y=0.45, coude_bas=90)
pushup("pompe.declinee", decline_y=0.30, coude_bas=95, epaule_bas=55)
pushup("pompe.diamant", coude_bas=110, epaule_bas=30, note="mains rapprochées : coudes le long du corps")
pushup("pompe.pseudo", coude_bas=95, epaule_bas=15, epaule_haut=60, note="mains au niveau des hanches, épaules très en avant des mains")
pushup("pompe.mur", wall=True)
pushup("pompe.explosive", explosive=True)
pushup("pompe.lestee", props=[{"type": "disque", "attach": "epaule_d", "offset": [-0.10, 0.06]}], charge="disque posé sur le haut du dos")
pushup("pompe.poignees", hands_y=0.06, coude_bas=105, props=[{"type": "cale", "x": 0.0, "static": True}], note="poignées : amplitude augmentée")
pushup("pompe.anneaux", hands_y=0.25, coude_bas=100, props=[{"type": "anneaux", "x": 0.0, "y": 0.25, "static": True}], note="mains dans les anneaux bas")


def pike(id_, hspu=False, libre=False, deficit=False):
    if hspu:
        hy = 0.08 if deficit else 0.0
        hanche_top = 12 if libre else 0     # en équilibre libre : léger pike pour garder le centre de masse au-dessus des mains
        top = A(t=181 if not libre else 178, n=25, hanche=hanche_top, genou=0, cheville=-40, epaule=178, coude=0)
        bot = A(t=181 if not libre else 178, n=25, hanche=hanche_top + 8, genou=0, cheville=-40, epaule=150, coude=95)
        anchor = ("prise_d", (0.0, hy))
        cx = 0.0 if libre else 0.03
        head_lo = (B.HEAD_R + 0.01) if deficit else (B.HEAD_R + 0.02)
        kfs = [KF("haut", top, anchor, [("t", 168, 192), ("epaule", 168, 186), ("poignet", -88, 88)], [("com_x", "poignet_d", cx), HAND_FLAT_D], hold=0.3, dur=1.2),
               KF("bas", bot, anchor, [("t", 160, 196), ("poignet", -88, 88), ("epaule", 120, 175)], [("com_x", "poignet_d", cx), HAND_FLAT_D, ("y", "tete", head_lo)], hold=0.15, dur=1.0)]
        props = [] if libre else [{"type": "mur", "x": 0.14, "static": True}]   # dos au mur : mur côté talons (+x)
        if deficit:
            props.append({"type": "cale", "x": 0.0, "static": True})
        contacts = [{"joint": "prise_d", "with": "parallettes" if deficit else "sol"}]
        sheet(id_, "profil", kfs, props, contacts,
              phases=[phase("descente", ["coude", "epaule"], {"coude": 0}, {"coude": 95}, "Tête vers le sol, corps aligné" + ("" if libre else " le long du mur") + "."), phase("poussée", ["coude", "epaule"], {"coude": 95}, {"coude": 0})],
              moteurs=["coude", "epaule"], placement="équilibre libre, doigts actifs" if libre else ("mains sur des poignées ou des cales, à 15-20 cm du mur" if deficit else "mains à 15-20 cm du mur"),
              contacts_texte="mains au sol" if libre else ("mains sur les poignées, talons au mur" if deficit else "mains au sol, talons au mur"), tempo="2 s / 1 s",
              sources=SRC["atr"] + SRC["press"], rom_exceptions={"cou": (-60, 80)},
              note="HSPU en équilibre libre" if libre else ("HSPU en déficit : la tête descend sous le niveau des mains" if deficit else "HSPU dos au mur"))
        return
    top = A(t=125, n=30, hanche=95, genou=5, cheville=15, epaule=165, coude=0)
    bot = A(t=125, n=30, hanche=95, genou=5, cheville=15, epaule=150, coude=90)
    anchor = ("prise_d", (0.0, 0.0))
    free = [("t", 95, 150), ("poignet", -88, 88), ("cheville", -30, 38)]
    cons = [("y", "pied_d", 0.0), HAND_FLAT_D]
    kfs = [KF("haut", top, anchor, free, cons, hold=0.3, dur=1.2), KF("bas", bot, anchor, free + [("hanche", 80, 110)], cons + [("y", "tete", B.HEAD_R + 0.02)], hold=0.15, dur=1.0)]
    sheet(id_, "profil", kfs, [], [{"joint": "prise_d", "with": "sol"}, {"joint": "pied_d", "with": "sol"}],
          phases=[phase("descente", ["coude", "epaule"], {"coude": 0}, {"coude": 90}, "Hanches hautes en V inversé, la tête descend devant les mains."), phase("poussée", ["coude", "epaule"], {"coude": 90}, {"coude": 0})],
          moteurs=["coude", "epaule"], placement="hanches hautes, pieds rapprochés des mains", contacts_texte="mains et pieds au sol", tempo="2 s / 1 s",
          sources=SRC["pompe"] + SRC["press"], note="pompe piquée")


pike("pompe.pike")
pike("atr.hspu", hspu=True)
pike("atr.hspu_libre", hspu=True, libre=True)
pike("atr.hspu_deficit", hspu=True, deficit=True)


def plank(id_, kind="coudes", side=False, hold=2.0):
    if side:
        # planche latérale : vue de face (le personnage est couché sur le côté... approximé de profil par la vue de face)
        a = A(t=-82, n=10, hanche=0, genou=0, epaule_d=92, coude_d=90, epaule_g=90, coude_g=0, p=-82)
        anc = ("coude_d", (0.0, 0.03))
        if kind == "bras_tendu":
            a = A(t=-60, n=10, hanche=0, genou=0, epaule_d=60, coude_d=0, epaule_g=90, coude_g=0, p=-60)
            anc = ("main_d", (0.0, 0.0))   # vue de face : la main prolonge l'avant-bras, on ancre le bout des doigts au sol
        kfs = [KF("tenue", a, anc, [("t", -89, -50), ("p", -89, -50)] + ([("epaule_d", 52, 68)] if kind == "bras_tendu" else []), [("y", "pied_d", 0.0)], hold=hold, dur=0.6)]
        sheet(id_, "face", kfs, [], [{"joint": anc[0], "with": "sol"}, {"joint": "pied_d", "with": "sol"}],
              phases=[phase("tenue", ["hanche (anti-flexion latérale)"], {}, {}, "Corps aligné sur le côté, coude sous l'épaule.")],
              moteurs=["tronc"], placement="coude sous l'épaule, pieds superposés", contacts_texte="coude/avant-bras et bord du pied au sol", tempo="tenue",
              sources=SRC["plank"], rom_exceptions={"epaule_abd": (-10, 190)}, note="planche latérale (vue de face du modèle)")
        return
    if kind == "coudes":
        a = A(t=80, n=15, hanche=0, genou=0, cheville=0, epaule=80, coude=90, poignet=0)
        anchor = ("coude_d", (0.0, 0.03))
        cons = [("y", "pied_d", 0.0), ("abs", "fa_d", 90)]
        free = [("t", 60, 95), ("cheville", -58, 38), ("epaule", 60, 100)]
        ct = "avant-bras et pointes des pieds au sol"
    elif kind == "genoux":
        a = A(t=80, n=15, hanche=0, genou=90, cheville=-52, epaule=80, coude=90)
        anchor = ("coude_d", (0.0, 0.03))
        cons = [("y", "genou_d", 0.0), ("abs", "fa_d", 90)]
        free = [("t", 55, 95), ("epaule", 60, 100)]
        ct = "avant-bras et genoux au sol"
    elif kind == "bras_tendus":
        a = A(t=80, n=15, hanche=0, genou=0, cheville=0, epaule=85, coude=0)
        anchor = ("prise_d", (0.0, 0.0))
        cons = [("y", "pied_d", 0.0), HAND_FLAT_D]
        free = [("t", 60, 95), ("cheville", -58, 38), ("poignet", -88, 88)]
        ct = "mains et pointes des pieds au sol"
    elif kind == "lean":
        a = A(t=80, n=15, hanche=0, genou=0, cheville=0, epaule=60, coude=0)
        anchor = ("prise_d", (0.0, 0.0))
        cons = [("y", "pied_d", 0.0), HAND_FLAT_D]
        free = [("t", 60, 95), ("cheville", -58, 38), ("poignet", -88, 88)]
        ct = "mains au sol, épaules en avant des mains, pointes des pieds au sol"
    elif kind == "pseudo_hold":
        a = A(t=80, n=15, hanche=0, genou=0, cheville=0, epaule=25, coude=0, poignet=-60)
        anchor = ("prise_d", (0.0, 0.0))
        cons = [("y", "pied_d", 0.0), ("abs", "ha_d", -90)]
        free = [("t", 60, 95), ("cheville", -58, 38), ("poignet", -88, 88)]
        ct = "mains à hauteur des hanches, pointes des pieds au sol"
    elif kind == "opposes":
        # bras droit au sol, bras gauche tendu devant dans l'axe du corps, jambe gauche levée dans l'axe
        a = A(t=80, n=15, hanche_d=0, genou_d=0, cheville_d=0, hanche_g=-12, genou_g=0, cheville_g=-30, epaule_d=85, coude_d=0, epaule_g=175, coude_g=0)
        anchor = ("prise_d", (0.0, 0.0))
        cons = [("y", "pied_d", 0.0), HAND_FLAT_D]
        free = [("t", 60, 95), ("cheville_d", -58, 38), ("poignet", -88, 88)]
        ct = "une main et une pointe de pied au sol (bras et jambe opposés levés)"
    elif kind == "un_bras":
        a = A(t=80, n=15, hanche=0, genou=0, cheville=0, epaule_d=85, coude_d=0, epaule_g=-35, coude_g=95)
        anchor = ("prise_d", (0.0, 0.0))
        cons = [("y", "pied_d", 0.0), HAND_FLAT_D]
        free = [("t", 60, 95), ("cheville", -58, 38), ("poignet", -88, 88)]
        ct = "une main au sol (l'autre dans le dos), pieds écartés au sol"
    elif kind == "levier_long":
        a = A(t=78, n=20, hanche=0, genou=0, cheville=0, epaule=118, coude=0)
        anchor = ("prise_d", (0.0, 0.0))
        cons = [("y", "pied_d", 0.0), HAND_FLAT_D]
        free = [("t", 55, 95), ("cheville", -58, 38), ("poignet", -88, 88)]
        ct = "mains au sol en avant des épaules (bras inclinés), pointes des pieds au sol"
    elif kind == "superman":
        a = A(t=85, n=25, hanche=0, genou=0, cheville=10, epaule=150, coude=0, poignet=30)
        anchor = ("prise_d", (0.0, 0.0))
        cons = [("y", "pied_d", 0.0), HAND_FLAT_D]
        free = [("t", 60, 100), ("cheville", -58, 38), ("poignet", -88, 88), ("epaule", 130, 170)]
        ct = "mains très loin devant, corps presque parallèle au sol, pointes des pieds au sol"
    else:  # rkc
        a = A(t=82, n=15, hanche=8, genou=0, cheville=0, epaule=75, coude=90)
        anchor = ("coude_d", (0.0, 0.03))
        cons = [("y", "pied_d", 0.0), ("abs", "fa_d", 90)]
        free = [("t", 60, 95), ("cheville", -58, 38), ("epaule", 55, 100)]
        ct = "avant-bras et pointes des pieds au sol, bassin en rétroversion"
    kfs = [KF("tenue", a, anchor, free, cons, hold=hold, dur=0.6)]
    sheet(id_, "profil", kfs, [], [{"joint": anchor[0], "with": "sol"}, {"joint": "genou_d" if kind == "genoux" else "pied_d", "with": "sol"}],
          phases=[phase("tenue", ["tronc (anti-extension)"], {"hanche": 0}, {"hanche": 0}, "Ligne tête-bassin-talons, bassin rentré, respiration continue.")],
          moteurs=["tronc"], placement="coude sous l'épaule" if "coude" in str(anchor) else "mains sous les épaules", contacts_texte=ct, tempo="tenue 20 s à 2 min",
          sources=SRC["plank"], note=kind)


plank("planche_gainage.coudes")
plank("planche_gainage.genoux", kind="genoux")
plank("planche_gainage.bras_tendus", kind="bras_tendus")
plank("planche_gainage.lean", kind="lean")
plank("planche_gainage.pseudo_hold", kind="pseudo_hold")
plank("planche_gainage.rkc", kind="rkc")
plank("planche_gainage.opposes", kind="opposes")
plank("planche_gainage.un_bras", kind="un_bras")
plank("planche_gainage.levier_long", kind="levier_long")
plank("planche_gainage.superman", kind="superman")
REG["planche_gainage.superman"]["rom_exceptions"] = {"epaule": (-70, 195)}
plank("planche_laterale.standard", side=True)
plank("planche_laterale.bras_tendu", side=True, kind="bras_tendu")
REG["planche_laterale.bras_tendu"]["placement"] = "main sous l'épaule, bras tendu, pieds superposés"
REG["planche_laterale.bras_tendu"]["contacts_texte"] = "main et bord du pied au sol"
plank("planche_laterale.copenhague", side=True)


def ab_wheel(id_, standing=False):
    if standing:
        top = A(t=80, n=20, hanche=90, genou=5, cheville=5, epaule=150, coude=0)
        bot = A(t=85, n=15, hanche=40, genou=0, cheville=15, epaule=175, coude=0)
        kfs = [KF("départ", top, on("talon_d"), [("t", 60, 100), ("epaule", 100, 178), ("cheville", -10, 38)], [("y", "prise_d", 0.06), FLAT_FOOT_D], hold=0.2, dur=1.4),
               KF("étendu", bot, on("talon_d"), [("t", 70, 100), ("hanche", 10, 70), ("epaule", 120, 178), ("cheville", -10, 38)], [("y", "prise_d", 0.06), FLAT_FOOT_D, ("x", "prise_d", 0.95)], hold=0.2, dur=1.4)]
        cont = [{"joint": "pied_d", "with": "sol"}]
    else:
        top = A(t=45, n=20, hanche=45, genou=90, cheville=-52, epaule=90, coude=0)
        bot = A(t=95, n=15, hanche=50, genou=90, cheville=-52, epaule=165, coude=0)
        kfs = [KF("départ", top, ("genou_d", (0.0, 0.045)), [("t", 30, 70), ("hanche", 20, 110), ("genou", 60, 140), ("epaule", 60, 120)], [("y", "prise_d", 0.06), ("abs", "sh_d", -90)], hold=0.2, dur=1.4),
               KF("étendu", bot, ("genou_d", (0.0, 0.045)), [("t", 60, 110), ("hanche", 0, 110), ("genou", 60, 140), ("epaule", 120, 178)], [("y", "prise_d", 0.06), ("abs", "sh_d", -90)], hold=0.2, dur=1.4)]
        cont = [{"joint": "genou_d", "with": "sol"}]
    sheet(id_, "profil", kfs, [{"type": "roue", "attach": "prises", "offset": [0.0, -0.0]}], cont,
          phases=[phase("déroulé", ["epaule", "hanche"], {"hanche": 95, "epaule": 90}, {"hanche": 5, "epaule": 165}, "La roue avance, le bassin reste rentré, pas de creux lombaire."),
                  phase("retour", ["epaule", "hanche"], {}, {}, "Retour en tirant avec les abdominaux.")],
          moteurs=["epaule", "tronc"], placement="genoux au sol, roue sous les épaules" if not standing else "debout, roue devant les pieds",
          contacts_texte=("genoux au sol, " if not standing else "pieds au sol, ") + "mains sur la roue", trajectoire="la roue roule vers l'avant puis revient",
          tempo="2 s aller, 2 s retour", sources=SRC["plank"], rom_exceptions={"epaule": (-70, 195)})


ab_wheel("genoux.ab_wheel")
ab_wheel("debout.ab_wheel", standing=True)


# ================================================================ SUSPENSION : TRACTIONS, MUSCLE-UP
def hang_pose(t=0, hanche=15, genou=20, cheville=-30, epaule=180, coude=0, n=5, poignet=0):
    return A(t=t, n=n, hanche=hanche, genou=genou, cheville=cheville, epaule=epaule, coude=coude, poignet=poignet)


def pullup(id_, coude_haut=150, epaule_haut=35, tronc_haut=8, hanche=15, genou=25, rings=False, props=None, note="",
           chest=False, l_sit=False, iso=None, negative=False, explosive=False, scap=False, archer=False, one_arm=False, towel=False):
    y = RINGS_Y if rings else BAR_Y
    anchor = ("prise_d", (0.0, y))
    bar = [{"type": "anneaux" if rings else "barre_fixe", "x": 0.0, "y": y, "static": True}]
    low = hang_pose(hanche=hanche, genou=genou)
    high = hang_pose(t=tronc_haut, hanche=hanche + 10, genou=genou + 15, epaule=epaule_haut, coude=coude_haut, n=10)
    if l_sit:
        low = hang_pose(hanche=90, genou=0, cheville=-40)
        high = hang_pose(t=tronc_haut, hanche=95, genou=0, cheville=-40, epaule=epaule_haut, coude=coude_haut)
    if chest:
        high = hang_pose(t=25, hanche=20, genou=35, epaule=-5, coude=155, n=15)
    if scap:
        high = hang_pose(hanche=hanche, genou=genou, epaule=172, coude=5, n=5)
        high["t"] = -4
    free = [("t", -20, 35)]
    cons = [("com_x", "prise_d", 0.0)]
    kfs = [KF("suspension", low, anchor, free, cons, hold=0.3, dur=1.0),
           KF("haut", high, anchor, free, cons, hold=0.2 if not iso else 2.0, dur=1.0)]
    if iso == "haut":
        kfs = [kfs[1]]
    elif iso == "90":
        mid = hang_pose(t=5, hanche=hanche + 5, genou=genou + 10, epaule=95, coude=90)
        kfs = [KF("tenue à 90°", mid, anchor, free, cons, hold=2.0, dur=0.6)]
    elif iso == "bas":
        kfs = [kfs[0]]
    if negative:
        kfs = [kfs[1], kfs[0]]
        kfs[0]["dur"], kfs[0]["hold"] = 3.5, 0.3
    if explosive:
        kfs[1]["dur"] = 0.5
        kfs[0]["dur"] = 0.5
        high["epaule"] = 20
    if archer or one_arm:
        for k in kfs:
            a = k["angles"]
            if archer:
                a["epaule_g"], a["coude_g"] = 178, 0    # bras gauche tendu sur la barre
            else:
                a["epaule_g"], a["coude_g"] = 30, 60    # bras libre replié (une main)
        kfs[0]["angles"]["coude_d"], kfs[0]["angles"]["epaule_d"] = 0, 180
    contacts = [{"joint": "prise_d", "with": "anneaux" if rings else "barre_fixe"}]
    if not one_arm and not archer:
        contacts.append({"joint": "prise_g", "with": "anneaux" if rings else "barre_fixe"})
    phases = [phase("traction", ["epaule", "coude"], {"coude": 0, "epaule": 180}, {"coude": coude_haut, "epaule": epaule_haut}, "Omoplates abaissées puis coudes tirés vers les côtes ; menton au-dessus de la barre."),
              phase("descente", ["epaule", "coude"], {"coude": coude_haut}, {"coude": 0}, "Retour contrôlé jusqu'aux bras tendus.")]
    sheet(id_, "profil", kfs, bar + list(props or []), contacts, "aller-retour" if not negative else "aller-retour", phases=phases,
          moteurs=["epaule", "coude"], prise="pronation, largeur d'épaules" if not rings else "anneaux, prise neutre à supination", placement="corps légèrement creux, jambes serrées",
          contacts_texte="mains sur " + ("les anneaux" if rings else "la barre") + ", pieds dans le vide", trajectoire="verticale sous la barre",
          tempo="1 s montée, 2 s descente", sources=SRC["traction"], rom_exceptions={"epaule": (-70, 195)}, note=note)


pullup("traction.standard.barre_fixe")
pullup("traction.standard.anneaux", rings=True)
pullup("traction.poitrine.barre_fixe", chest=True, note="poitrine à la barre : coudes très en arrière, tronc penché")
pullup("traction.explosive.barre_fixe", explosive=True)
pullup("traction.negative.barre_fixe", negative=True)
pullup("traction.l_sit.barre_fixe", l_sit=True)
pullup("traction.archer.barre_fixe", archer=True, note="traction archer : un bras se tend sur la barre")
pullup("traction.un_bras.barre_fixe", one_arm=True, note="traction à un bras")
pullup("traction.serviette.barre_fixe", towel=True, props=[{"type": "corde", "x": 0.0, "y": BAR_Y, "static": True}], note="prise sur une serviette (représentée par la barre)")
pullup("suspension.iso_haut.barre_fixe", iso="haut")
pullup("suspension.iso90.barre_fixe", iso="90")
pullup("suspension.passif.barre_fixe", iso="bas", hanche=5, genou=5)
pullup("suspension.passif.anneaux", iso="bas", rings=True, hanche=5, genou=5)
pullup("suspension.scap.barre_fixe", scap=True, hanche=5, genou=5, note="tractions scapulaires : bras tendus, seules les omoplates s'abaissent")
pullup("suspension.actif.barre_fixe", scap=True, hanche=5, genou=5, iso="haut", note="suspension active tenue")


def hang_feet_on_floor(id_):
    """Suspension assistée : barre plus basse (≈1,9 m pour 1,75 m), genoux fléchis, pieds à plat au sol qui portent une partie du poids."""
    y = 1.12
    anchor = ("prise_d", (0.0, y))
    pose = hang_pose(t=0, hanche=40, genou=80, cheville=10, epaule=180, coude=0, n=5)
    free = [("t", -15, 15), ("hanche", 10, 90), ("genou", 20, 130), ("cheville", -20, 35)]
    cons = [("y", "talon_d", 0.0), ("y", "pied_d", 0.0), ("com_x", "prise_d", 0.0)]
    kfs = [KF("suspension", pose, anchor, free, cons, hold=2.0, dur=1.0)]
    sheet(id_, "profil", kfs, [{"type": "barre_fixe", "x": 0.0, "y": y, "static": True}],
          HANDS_BAR + [{"joint": "talon_d", "with": "sol"}, {"joint": "talon_g", "with": "sol"}], "statique",
          phases=[phase("tenue", ["epaule"], {"epaule": 180}, {"epaule": 180}, "Bras tendus, épaules relâchées puis légèrement abaissées ; les pieds au sol allègent la prise.")],
          moteurs=["epaule"], prise="pronation, largeur d'épaules", placement="barre basse ou genoux fléchis : les pieds restent à plat au sol",
          contacts_texte="mains sur la barre, pieds à plat au sol", trajectoire="aucune (tenue)", tempo="tenue 20 à 60 s",
          sources=SRC["traction"], rom_exceptions={"epaule": (-70, 195)}, note="suspension passive assistée par les pieds")


hang_feet_on_floor("suspension.passif.pieds_sol")


def assisted_pullup(id_):
    low = hang_pose(hanche=10, genou=90, cheville=-20)
    high = hang_pose(t=8, hanche=20, genou=100, epaule=35, coude=150, n=10)
    anchor = ("prise_d", (0.0, BAR_Y))
    kfs = [KF("suspension", low, anchor, [("t", -20, 35)], [("com_x", "prise_d", 0.0)], hold=0.3, dur=1.0),
           KF("haut", high, anchor, [("t", -20, 35)], [("com_x", "prise_d", 0.0)], hold=0.2, dur=1.0)]
    sheet(id_, "profil", kfs, [{"type": "barre_fixe", "x": 0.0, "y": BAR_Y, "static": True}, {"type": "elastique", "x": 0.0, "y": BAR_Y, "to": ["genou_d"], "static": True}],
          HANDS_BAR + [{"joint": "genou_d", "with": "elastique"}], phases=REG["traction.standard.barre_fixe"]["phases"],
          moteurs=["epaule", "coude"], prise="pronation", placement="genou dans l'élastique accroché à la barre", tempo="1 s / 2 s", sources=SRC["traction"],
          rom_exceptions={"epaule": (-70, 195)}, note="traction assistée par élastique")


assisted_pullup("traction.assistee.barre_fixe")


def muscle_up(id_, rings=False, negative=False, transition_only=False, iso_transition=False):
    y = RINGS_Y if rings else BAR_Y
    anchor = ("prise_d", (0.0, y))
    hang = hang_pose(hanche=10, genou=10, cheville=-30, poignet=-10)
    high = hang_pose(t=12, hanche=30, genou=25, epaule=5, coude=150, n=15, poignet=-30)
    trans = hang_pose(t=32, hanche=45, genou=35, epaule=-45, coude=100, n=20, poignet=-45)
    top = hang_pose(t=8, hanche=15, genou=20, epaule=-15, coude=0, n=5, poignet=0)
    free = [("t", -20, 45)]
    cons = [("com_x", "prise_d", 0.0)]
    kfs = [KF("suspension", hang, anchor, free, cons, hold=0.3, dur=0.6, phase="traction haute"),
           KF("traction haute", high, anchor, free, cons, hold=0.0, dur=0.5, phase="transition"),
           KF("transition", trans, anchor, free, cons, hold=0.1, dur=0.7, phase="dip"),
           KF("appui haut", top, anchor, free, cons, hold=0.3, dur=1.0, phase="descente")]
    if transition_only:
        kfs = [kfs[1], kfs[2]]
    if iso_transition:
        kfs = [kfs[2]]
        kfs[0]["hold"] = 2.0
    if negative:
        kfs = list(reversed(kfs))
        for k in kfs:
            k["dur"] = 1.5
    bar = [{"type": "anneaux" if rings else "barre_fixe", "x": 0.0, "y": y, "static": True}]
    sheet(id_, "profil", kfs, bar, [{"joint": "prise_d", "with": "anneaux" if rings else "barre_fixe"}, {"joint": "prise_g", "with": "anneaux" if rings else "barre_fixe"}],
          "aller-retour", phases=[phase("traction haute", ["epaule", "coude"], {"coude": 0}, {"coude": 150}, "Traction explosive, barre vers le bas du sternum."),
                                  phase("transition", ["epaule", "coude", "tronc"], {"coude": 150, "epaule": 5}, {"coude": 100, "epaule": -45}, "Poignets basculés au-dessus de la barre, buste penché en avant."),
                                  phase("dip", ["coude", "epaule"], {"coude": 100}, {"coude": 0}, "Poussée jusqu'aux bras tendus en appui.")],
          moteurs=["epaule", "coude"], prise="faux grip ou pronation", placement="corps groupé pendant la transition", contacts_texte="mains sur la barre/anneaux, pieds dans le vide",
          trajectoire="verticale puis passage au-dessus de la barre", tempo="explosif, descente contrôlée 2-3 s", sources=SRC["muscle_up"],
          rom_exceptions={"epaule": (-90, 195), "poignet": (-90, 90)}, note=id_)


muscle_up("muscle_up.complet.barre_fixe")
muscle_up("muscle_up.complet.anneaux", rings=True)
muscle_up("muscle_up.negatif.barre_fixe", negative=True)
muscle_up("muscle_up.transition.barre_fixe", transition_only=True)
muscle_up("muscle_up.iso_transition.barre_fixe", iso_transition=True)


def hanging_legs(id_, kind="leg_raise", rings=False):
    anchor = ("prise_d", (0.0, BAR_Y))
    low = hang_pose(hanche=5, genou=5, cheville=-30)
    if kind == "knee_raise":
        high = hang_pose(t=-8, hanche=110, genou=120, cheville=-30)
    elif kind == "toes_to_bar":
        high = hang_pose(t=-35, hanche=150, genou=5, cheville=-30, epaule=150, n=25)
    elif kind == "l_sit_barre":
        high = hang_pose(t=-5, hanche=95, genou=0, cheville=-40)
        low = high
    elif kind == "windshield":
        pass
    else:
        high = hang_pose(t=-12, hanche=100, genou=5, cheville=-40)
    kfs = [KF("suspension", low, anchor, [("t", -20, 20)], [("com_x", "prise_d", 0.0)], hold=0.2, dur=1.0),
           KF("haut", high, anchor, [("t", -45, 20)], [("com_x", "prise_d", 0.0)], hold=0.3, dur=1.0)]
    if kind == "l_sit_barre":
        kfs = [KF("tenue", high, anchor, [("t", -20, 20)], [("com_x", "prise_d", 0.0)], hold=2.0, dur=0.6)]
    sheet(id_, "profil", kfs, [{"type": "barre_fixe", "x": 0.0, "y": BAR_Y, "static": True}], HANDS_BAR,
          phases=[phase("montée", ["hanche", "tronc"], {"hanche": 5}, {"hanche": 100 if kind != "toes_to_bar" else 150}, "Bassin qui s'enroule, sans élan."),
                  phase("descente", ["hanche"], {}, {}, "Descente contrôlée.")],
          moteurs=["hanche", "tronc"], prise="pronation", placement="suspendu, omoplates engagées", contacts_texte="mains sur la barre",
          tempo="1 s montée, 2 s descente", sources=SRC["lsit"] + SRC["traction"], rom_exceptions={"epaule": (-70, 195), "hanche": (-30, 160)})


hanging_legs("suspension.leg_raise.barre_fixe")
hanging_legs("suspension.knee_raise.barre_fixe", kind="knee_raise")
hanging_legs("suspension.toes_to_bar.barre_fixe", kind="toes_to_bar")
hanging_legs("suspension.l_sit_barre.barre_fixe", kind="l_sit_barre")


def lever(id_, kind="front", variant="full"):
    anchor = ("prise_d", (0.0, BAR_Y))
    hip = {"full": 5, "straddle": 8, "one": 5, "adv": 60, "tuck": 110}[variant]
    knee = {"full": 0, "straddle": 0, "one": 0, "adv": 100, "tuck": 130}[variant]
    if kind == "front":
        a = A(t=-90, n=-10, hanche=hip, genou=knee, cheville=-40, epaule=60, coude=0)
        if variant == "one":
            a["hanche_g"], a["genou_g"] = 110, 130
        free = [("t", -100, -80), ("epaule", 30, 90)]
        cons = [("com_x", "prise_d", 0.0)]
        rom = {"epaule": (-70, 195)}
        phases = [phase("tenue", ["epaule (extension)", "tronc"], {"tronc": "horizontal"}, {"tronc": "horizontal"}, "Corps horizontal sous la barre, bras tendus, bassin rentré.")]
        note = f"front lever {variant}"
        src = SRC["front_lever"]
    else:
        a = A(t=90, n=20, hanche=-hip * 0.3 if variant == "full" else hip, genou=knee, cheville=-40, epaule=-60, coude=0)
        free = [("t", 80, 100), ("epaule", -90, -30)]
        cons = [("com_x", "prise_d", 0.0)]
        rom = {"epaule": (-120, 195)}
        phases = [phase("tenue", ["epaule (flexion depuis l'extension)"], {"tronc": "horizontal"}, {"tronc": "horizontal"}, "Corps horizontal face au sol, bras tendus derrière le dos.")]
        note = f"back lever {variant}"
        src = SRC["back_lever"]
    kfs = [KF("tenue", a, anchor, free, cons, hold=2.0, dur=0.6)]
    sheet(id_, "profil", kfs, [{"type": "barre_fixe", "x": 0.0, "y": BAR_Y, "static": True}], HANDS_BAR, phases=phases, moteurs=["epaule", "tronc"],
          prise="pronation" if kind == "front" else "supination ou pronation", placement="corps tendu, omoplates engagées", contacts_texte="mains sur la barre",
          tempo="tenue 3 à 15 s", sources=src, rom_exceptions=rom, note=note)


for v in ("tuck", "adv", "straddle", "one", "full"):
    lever(f"levier.front_{v}", "front", v)
for v in ("tuck", "adv", "straddle", "full"):
    lever(f"levier.back_{v}", "back", v)


def lever_dyn(id_, variant="tuck"):
    hip = {"tuck": 110, "adv": 60, "straddle": 8}[variant]
    knee = {"tuck": 130, "adv": 100, "straddle": 0}[variant]
    anchor = ("prise_d", (0.0, BAR_Y))
    hang = A(t=-5, n=5, hanche=hip, genou=knee, cheville=-40, epaule=175, coude=0)
    lev = A(t=-90, n=-10, hanche=hip, genou=knee, cheville=-40, epaule=60, coude=0)
    kfs = [KF("suspension groupée", hang, anchor, [("t", -30, 20)], [("com_x", "prise_d", 0.0)], hold=0.3, dur=1.2),
           KF("levier", lev, anchor, [("t", -100, -80), ("epaule", 30, 90)], [("com_x", "prise_d", 0.0)], hold=0.5, dur=1.2)]
    sheet(id_, "profil", kfs, [{"type": "barre_fixe", "x": 0.0, "y": BAR_Y, "static": True}], HANDS_BAR,
          phases=[phase("montée", ["epaule (extension bras tendus)"], {"tronc": 0}, {"tronc": -90}, "Bras tendus, le corps bascule jusqu'à l'horizontale."), phase("descente", ["epaule"], {}, {})],
          moteurs=["epaule"], prise="pronation", tempo="2 s montée, 2 s descente", sources=SRC["front_lever"], rom_exceptions={"epaule": (-70, 195)}, note=f"front lever raises {variant}")


lever_dyn("levier.front_tuck.dynamique", "tuck")
lever_dyn("levier.front_adv.dynamique", "adv")
lever_dyn("levier.front_straddle.dynamique", "straddle")


def skin_cat(id_):
    anchor = ("prise_d", (0.0, BAR_Y))
    hang = A(t=0, hanche=10, genou=10, cheville=-30, epaule=178, coude=0)
    tuck = A(t=-60, hanche=130, genou=130, cheville=-30, epaule=120, coude=0)
    inv = A(t=-175, hanche=100, genou=120, cheville=-30, epaule=30, coude=0, n=10)
    german = A(t=30, n=30, hanche=20, genou=20, cheville=-30, epaule=-150, coude=0)
    free = [("t", -200, 200)]
    kfs = [KF("suspension", hang, anchor, [("t", -20, 20)], [("com_x", "prise_d", 0.0)], hold=0.2, dur=1.0),
           KF("groupé renversé", inv, anchor, [("t", -200, -150)], [("com_x", "prise_d", 0.0)], hold=0.2, dur=1.2),
           KF("suspension allemande", german, anchor, [("t", 5, 60)], [("com_x", "prise_d", 0.0)], hold=0.6, dur=1.2)]
    sheet(id_, "profil", kfs, [{"type": "barre_fixe", "x": 0.0, "y": BAR_Y, "static": True}], HANDS_BAR,
          phases=[phase("bascule", ["epaule", "hanche"], {}, {}, "Genoux groupés, le corps bascule en arrière sous la barre jusqu'à la suspension allemande.")],
          moteurs=["epaule", "hanche"], prise="pronation", tempo="lent, 3-4 s par bascule", sources=SRC["back_lever"],
          rom_exceptions={"epaule": (-180, 195), "cou": (-60, 80)}, note="skin the cat")


skin_cat("suspension.skin_cat.barre_fixe")
sheet("suspension.german.barre_fixe", "profil",
      [KF("suspension allemande", A(t=30, n=30, hanche=20, genou=20, cheville=-30, epaule=-150, coude=0), ("prise_d", (0.0, BAR_Y)), [("t", 5, 60)], [("com_x", "prise_d", 0.0)], hold=2.0, dur=0.6)],
      [{"type": "barre_fixe", "x": 0.0, "y": BAR_Y, "static": True}], HANDS_BAR, phases=[phase("tenue", ["epaule"], {}, {}, "Suspension bras derrière le dos, épaules détendues.")],
      moteurs=["epaule"], tempo="tenue 10-30 s", sources=SRC["back_lever"], rom_exceptions={"epaule": (-180, 195), "cou": (-60, 80)}, note="german hang")


# ================================================================ APPUI : DIPS, SUPPORT, L-SIT
def dips(id_, coude_bas=92, tronc_bas=28, rings=False, bench=False, knees_bent=False, iso_bas=False, support=False, bar=False, props=None, charge=None, note=""):
    if bench:
        # dips sur banc : mains derrière sur le banc, pieds au sol
        top = A(t=-8, n=10, hanche=100, genou=(90 if knees_bent else 10), cheville=(0 if knees_bent else 20), epaule=-30, coude=0)
        bot = A(t=-8, n=10, hanche=100, genou=(90 if knees_bent else 10), cheville=(0 if knees_bent else 20), epaule=-60, coude=90)
        anchor = ("prise_d", (0.0, BENCH_Y))
        kfs = [KF("haut", top, anchor, [("t", -25, 10), ("hanche", 70, 120), ("genou", 5, 100), ("cheville", -30, 38)], [("y", "talon_d", 0.0), FLAT_FOOT_D, ("abs", "ua_d", 0)], hold=0.3, dur=1.0),
               KF("bas", bot, anchor, [("t", -25, 10), ("hanche", 70, 120), ("genou", 5, 100), ("cheville", -30, 38)], [("y", "talon_d", 0.0), FLAT_FOOT_D], hold=0.2, dur=1.0)]
        sheet(id_, "profil", kfs, [{"type": "banc", "x": -0.55, "y": BENCH_Y, "w": 0.5, "static": True, "layer": "arriere"}],
              [{"joint": "prise_d", "with": "banc"}, {"joint": "talon_d", "with": "sol"}],
              phases=[phase("descente", ["coude", "epaule"], {"coude": 0}, {"coude": 90}, "Fesses le long du banc, coudes vers l'arrière."), phase("poussée", ["coude"], {"coude": 90}, {"coude": 0})],
              moteurs=["coude", "epaule"], placement="mains sur le bord du banc, doigts vers l'avant", contacts_texte="mains sur le banc, pieds au sol",
              tempo="2 s / 1 s", sources=SRC["dips"], rom_exceptions={"epaule": (-90, 195)}, note="dips sur banc" + (" (genoux fléchis)" if knees_bent else ""))
        return
    y = RINGS_Y - 0.5 if rings else (BAR_Y if bar else PB_Y)
    anchor = ("prise_d", (0.0, y))
    top = A(t=12, n=5, hanche=25, genou=60, cheville=-30, epaule=-12, coude=0)
    bot = A(t=tronc_bas, n=5, hanche=35, genou=70, cheville=-30, epaule=-50, coude=coude_bas)
    free = [("t", -10, 45)]
    cons = [("com_x", "prise_d", 0.0)]
    kfs = [KF("haut", top, anchor, free, cons, hold=0.3, dur=1.0), KF("bas", bot, anchor, free, cons, hold=0.2, dur=1.0)]
    if iso_bas:
        kfs = [KF("tenue basse", bot, anchor, free, cons, hold=2.0, dur=0.6)]
    if support:
        kfs = [KF("appui", top, anchor, free, cons, hold=2.0, dur=0.6)]
    pr = [{"type": "anneaux" if rings else ("barre_fixe" if bar else "barres_paralleles"), "x": 0.0, "y": y, "static": True}] + list(props or [])
    cont = [{"joint": "prise_d", "with": "anneaux" if rings else ("barre_fixe" if bar else "barres_paralleles")}]
    sheet(id_, "profil", kfs, pr, cont, phases=[phase("descente", ["coude", "epaule"], {"coude": 0, "epaule": -12}, {"coude": coude_bas, "epaule": -50}, "Buste légèrement penché, coudes vers l'arrière, humérus parallèle au sol en bas."),
                                          phase("poussée", ["coude", "epaule"], {"coude": coude_bas}, {"coude": 0}, "Extension complète des coudes, épaules basses.")],
          moteurs=["coude", "epaule"], prise="neutre sur les barres" if not rings else "anneaux, rotation externe en haut", placement="épaules basses, jambes groupées ou croisées",
          contacts_texte="mains sur les barres, pieds dans le vide", trajectoire="verticale légèrement vers l'avant", tempo="2 s descente, 1 s poussée",
          sources=SRC["dips"], rom_exceptions={"epaule": (-90, 195)}, charge=charge, note=note)


dips("dips.barres")
dips("dips.anneaux", rings=True)
dips("dips.barre_fixe", bar=True, tronc_bas=35, note="dips à la barre fixe : buste très penché, corps devant la barre")
dips("dips.iso_bas", iso_bas=True)
dips("dips.support", support=True)
dips("dips.support_anneaux", support=True, rings=True)
dips("dips.banc", bench=True)
dips("dips.banc_genoux", bench=True, knees_bent=True)
dips("dips.lestes", props=[{"type": "lest", "attach": "bassin"}], charge="lest à la ceinture")


def lsit(id_, kind="l"):
    hip = {"l": 82, "tuck": 120, "one": 82, "v": 130, "sol": 82}[kind]
    knee = {"l": 0, "tuck": 120, "one": 0, "v": 0, "sol": 0}[kind]
    t = {"l": -8, "tuck": -8, "one": -8, "v": -35, "sol": -8}[kind]
    a = A(t=t, n=10, hanche=hip, genou=knee, cheville=-40, epaule=-8, coude=0, poignet=0)
    if kind == "one":
        a["hanche_g"], a["genou_g"] = 120, 120
    y = 0.0 if kind == "sol" else 0.10
    anchor = ("prise_d", (0.0, y))
    props = [] if kind == "sol" else [{"type": "cale", "x": 0.0, "static": True}]
    kfs = [KF("tenue", a, anchor, [("t", -22, 0), ("epaule", -25, 5), ("poignet", -88, 88)], [("com_between", "prise_d", -0.02, 0.07), HAND_FLAT_D, ("min_y", 0.0)], hold=2.0, dur=0.6)]
    sheet(id_, "profil", kfs, props, [{"joint": "prise_d", "with": "parallettes" if kind != "sol" else "sol"}],
          phases=[phase("tenue", ["hanche", "epaule (dépression)"], {"hanche": hip}, {"hanche": hip}, "Épaules abaissées, bras tendus, jambes horizontales.")],
          moteurs=["hanche", "epaule"], prise="mains à plat ou sur parallettes", placement="mains à hauteur des hanches", contacts_texte="mains sur l'appui, fesses et jambes décollées",
          tempo="tenue 5 à 30 s", sources=SRC["lsit"], rom_exceptions={"hanche": (-30, 150)}, note=f"L-sit {kind}")


for k in ("l", "tuck", "one", "v", "sol"):
    lsit(f"lsit.{k}", k)


# ================================================================ ATR, PLANCHE (figure), DRAPEAU
def handstand(id_, kind="libre"):
    a = A(t=180, n=25, hanche=0, genou=0, cheville=-40, epaule=178, coude=0, poignet=0)
    anchor = ("prise_d", (0.0, 0.0))
    props, note, cons = [], "équilibre sur les mains", [("com_x", "poignet_d", 0.03), HAND_FLAT_D]
    free = [("t", 168, 192), ("epaule", 168, 186), ("poignet", -88, 88)]
    # Orientation : le personnage debout regarde vers +x ; en ATR (rotation de 180° dans le plan) la face et la pointe
    # des pieds regardent vers −x, les talons et les doigts vers +x. Dos au mur = mur côté talons (+x) ;
    # poitrine au mur = mur côté pointes des pieds (−x). Vérifié numériquement (L9R).
    if kind == "dos_mur":
        props = [{"type": "mur", "x": 0.16, "static": True}]
        a["t"] = 182
        note = "ATR dos au mur : talons contre le mur"
        cons = [HAND_FLAT_D]
        free = [("poignet", -88, 88)]
    elif kind == "poitrine_mur":
        props = [{"type": "mur", "x": -0.21, "static": True}]
        a["t"] = 175
        note = "ATR poitrine au mur : corps aligné le long du mur"
        cons = [HAND_FLAT_D]
        free = [("poignet", -88, 88)]
    elif kind == "taps":
        a["epaule_g"], a["coude_g"] = 150, 60
        a["t"] = 182
        props = [{"type": "mur", "x": 0.16, "static": True}]
        cons = [HAND_FLAT_D]
        free = [("poignet", -88, 88)]
        note = "shoulder taps : dos au mur, une main touche l'épaule opposée"
    kfs = [KF("tenue", a, anchor, free, cons, hold=2.0, dur=0.6)]
    if kind == "taps":
        b = dict(a)
        b["epaule_g"], b["coude_g"] = 178, 0
        kfs = [KF("appui deux mains", b, anchor, free, cons, hold=0.4, dur=0.6), KF("main à l'épaule", a, anchor, free, cons, hold=0.4, dur=0.6)]
    sheet(id_, "profil", kfs, props, [{"joint": "prise_d", "with": "sol"}], phases=[phase("tenue", ["epaule", "poignet"], {"epaule": 180}, {"epaule": 180}, "Corps aligné des mains aux pieds, épaules ouvertes, regard entre les mains.")],
          moteurs=["epaule", "poignet"], prise="mains à plat, doigts écartés", placement="mains largeur d'épaules", contacts_texte="mains au sol" + (", talons au mur" if kind == "dos_mur" else ""),
          tempo="tenue", sources=SRC["atr"], rom_exceptions={"cou": (-60, 80)}, note=note)


handstand("atr.libre")
handstand("atr.dos_mur", "dos_mur")
handstand("atr.poitrine_mur", "poitrine_mur")
handstand("atr.taps", "taps")


def wall_walk(id_):
    """Le personnage regarde vers +x : le mur est derrière les pieds, en x = WALL. Origine fixe (les mains avancent)."""
    WALL = -0.96
    p0 = A(t=80, n=20, hanche=0, genou=0, cheville=0, epaule=85, coude=0)
    p1 = A(t=140, n=25, hanche=60, genou=0, cheville=-20, epaule=150, coude=0)
    p2 = A(t=172, n=25, hanche=8, genou=0, cheville=-30, epaule=176, coude=0)
    kfs = [KF("planche, pieds au mur", p0, ("prise_d", (0.0, 0.0)), [("t", 60, 95), ("poignet", -88, 88), ("cheville", -58, 38)], [("y", "pied_d", 0.0), HAND_FLAT_D], hold=0.2, dur=1.2),
           KF("pieds à mi-hauteur", p1, ("prise_d", (WALL + 0.50, 0.0)), [("t", 100, 175), ("epaule", 100, 178), ("poignet", -88, 100), ("hanche", 0, 110), ("cheville", -58, 30)],
              [("x", "pied_d", WALL), ("y", "pied_d", 0.45), HAND_FLAT_D, ("min_y", 0.0)], hold=0.2, dur=1.2),
           KF("poitrine au mur", p2, ("prise_d", (WALL + 0.17, 0.0)), [("t", 160, 188), ("poignet", -88, 88), ("hanche", 0, 30), ("epaule", 160, 186)], [("x", "pied_d", WALL), HAND_FLAT_D], hold=0.4, dur=1.2)]
    sheet(id_, "profil", kfs, [{"type": "mur", "x": WALL, "static": True}], [{"joint": "prise_d", "with": "sol"}, {"joint": "pied_d", "with": "mur"}],
          phases=[phase("montée", ["epaule", "hanche"], {"tronc": 80}, {"tronc": 172}, "Les pieds montent le long du mur pendant que les mains se rapprochent.")],
          moteurs=["epaule"], tempo="lent", sources=SRC["atr"], rom_exceptions={"cou": (-60, 80), "poignet": (-90, 100)}, note="wall walk", origine_fixe=True)


wall_walk("atr.wall_walk")


def planche_skill(id_, variant="tuck"):
    hip = {"tuck": 110, "adv": 60, "straddle": 5, "full": 3}[variant]
    knee = {"tuck": 130, "adv": 100, "straddle": 0, "full": 0}[variant]
    a = A(t=90, n=-25, hanche=hip, genou=knee, cheville=-40, epaule=35, coude=0, poignet=0)
    anchor = ("prise_d", (0.0, 0.0))
    kfs = [KF("tenue", a, anchor, [("epaule", 5, 70), ("t", 84, 96), ("poignet", -88, 140)], [("com_x", "poignet_d", 0.02), HAND_FLAT_D, ("min_y", 0.0)], hold=2.0, dur=0.6)]
    sheet(id_, "profil", kfs, [], [{"joint": "prise_d", "with": "sol"}],
          phases=[phase("tenue", ["epaule", "poignet"], {"tronc": "horizontal"}, {"tronc": "horizontal"}, "Épaules très en avant des mains, omoplates écartées, corps horizontal.")],
          moteurs=["epaule", "poignet"], prise="mains tournées vers l'extérieur ou l'arrière", placement="bras tendus, épaules au-delà des doigts", contacts_texte="mains au sol seulement",
          tempo="tenue 3-15 s", sources=SRC["planche"], rom_exceptions={"poignet": (-95, 140), "cou": (-60, 80)}, note=f"planche {variant} — mains tournées vers l'extérieur : l'extension apparente du poignet en 2D dépasse l'amplitude réelle")


for v in ("tuck", "adv", "straddle", "full"):
    planche_skill(f"planche_skill.{v}", v)


def flag(id_, variant="full"):
    # vue de face : poteau à gauche de l'image, personnage horizontal
    hip = {"full": 0, "straddle": 0, "tuck": 100, "vertical": 0}[variant]
    knee = {"full": 0, "straddle": 0, "tuck": 120, "vertical": 0}[variant]
    t = {"full": -90, "straddle": -90, "tuck": -80, "vertical": -30}[variant]
    a = A(t=t, n=0, p=t, hanche=hip, genou=knee, epaule_d=182, coude_d=0, epaule_g=160, coude_g=0)
    if variant == "straddle":
        a["hanche_g"], a["hanche_d"] = 35, 35
    anchor = ("prise_g", (-0.42, 0.78 if variant != "vertical" else 1.2))
    kfs = [KF("tenue", a, anchor, [("epaule_d", 150, 195), ("epaule_g", 130, 185)], [("x", "prise_d", -0.42), ("x", "prise_g", -0.42)], hold=2.0, dur=0.6)]
    sheet(id_, "face", kfs, [{"type": "poteau", "x": -0.42, "static": True}], [{"joint": "prise_d", "with": "poteau"}, {"joint": "prise_g", "with": "poteau"}],
          phases=[phase("tenue", ["epaule", "tronc (anti-flexion latérale)"], {}, {}, "Bras du bas tendu qui pousse, bras du haut qui tire, corps horizontal.")],
          moteurs=["epaule", "tronc"], prise="mains écartées sur le poteau, bras inférieur en poussée", contacts_texte="mains sur le poteau seulement", tempo="tenue 3-10 s",
          sources=SRC["front_lever"], rom_exceptions={"epaule_abd": (-10, 200), "hanche_abd": (-30, 100)}, note=f"drapeau {variant}")


for v in ("tuck", "vertical", "straddle", "full"):
    flag(f"drapeau.{v}", v)


# ================================================================ AU SOL : DOS, VENTRE, GENOUX
def supine(id_, kind="hollow"):
    """Couché sur le dos : tête vers −x, pieds vers +x ; ancrage du bassin au sol."""
    anchor = ("bassin", (0.0, B.contact_offset("bassin")))
    base = dict(t=-78, n=35, hanche=25, genou=0, cheville=-40, epaule=175, coude=0)
    if kind == "hollow":
        kfs = [KF("tenue", A(**base), anchor, [], [], hold=2.0, dur=0.6)]
        txt = "Lombaires plaquées, épaules et jambes décollées, bras tendus derrière la tête."
    elif kind == "hollow_tuck":
        kfs = [KF("tenue", A(t=-75, n=35, hanche=95, genou=120, cheville=-30, epaule=90, coude=10), anchor, [], [], hold=2.0, dur=0.6)]
        txt = "Genoux groupés, épaules décollées, lombaires au sol."
    elif kind == "hollow_rocks":
        kfs = [KF("bascule arrière", A(t=-60, n=35, hanche=40, genou=0, cheville=-40, epaule=175, coude=0), anchor, [], [], hold=0.0, dur=0.5),
               KF("bascule avant", A(t=-95, n=30, hanche=10, genou=0, cheville=-40, epaule=170, coude=0), anchor, [], [], hold=0.0, dur=0.5)]
        txt = "Bascule d'avant en arrière en gardant la forme creuse."
    elif kind == "dead_bug":
        kfs = [KF("départ", A(t=-88, n=5, hanche=90, genou=90, cheville=0, epaule=90, coude=0), anchor, [], [], hold=0.2, dur=1.0),
               KF("extension opposée", A(t=-88, n=5, hanche_d=90, genou_d=90, hanche_g=15, genou_g=5, cheville=0, epaule_d=170, coude_d=0, epaule_g=90, coude_g=0), anchor, [], [], hold=0.2, dur=1.0)]
        txt = "Bras et jambe opposés s'allongent sans que le dos ne se creuse."
    elif kind == "leg_raise":
        kfs = [KF("jambes basses", A(t=-90, n=5, hanche=15, genou=0, cheville=-40, epaule=-10, coude=0), anchor, [], [], hold=0.2, dur=1.2),
               KF("jambes à la verticale", A(t=-90, n=5, hanche=95, genou=0, cheville=-40, epaule=-10, coude=0), anchor, [], [], hold=0.2, dur=1.0)]
        txt = "Jambes tendues montées à la verticale, lombaires au sol."
    elif kind == "flutter":
        kfs = [KF("ciseau 1", A(t=-85, n=25, hanche_d=35, hanche_g=15, genou=0, cheville=-40, epaule=-10, coude=0), anchor, [], [], hold=0.0, dur=0.3),
               KF("ciseau 2", A(t=-85, n=25, hanche_d=15, hanche_g=35, genou=0, cheville=-40, epaule=-10, coude=0), anchor, [], [], hold=0.0, dur=0.3)]
        txt = "Petits battements alternés, jambes tendues."
    elif kind == "crunch":
        kfs = [KF("allongé", A(t=-90, n=10, hanche=45, genou=95, cheville=-45, epaule=95, coude=95), anchor, [("genou", 60, 130), ("cheville", -50, 38)], [("y", "talon_d", 0.0), FLAT_FOOT_D], hold=0.2, dur=1.0),
               KF("enroulé", A(t=-62, n=35, hanche=45, genou=95, cheville=-45, epaule=95, coude=95), anchor, [("genou", 30, 130), ("cheville", -50, 38)], [("y", "talon_d", 0.0), FLAT_FOOT_D], hold=0.3, dur=1.0)]
        txt = "Le haut du dos décolle en enroulant les côtes vers le bassin."
    elif kind == "situp":
        kfs = [KF("allongé", A(t=-90, n=10, hanche=45, genou=95, cheville=-45, epaule=90, coude=0), anchor, [("genou", 60, 130), ("cheville", -50, 38)], [("y", "talon_d", 0.0), FLAT_FOOT_D], hold=0.2, dur=1.0),
               KF("assis", A(t=15, n=5, hanche=125, genou=95, cheville=-45, epaule=80, coude=0), anchor, [("genou", 60, 130), ("cheville", -50, 38)], [("y", "talon_d", 0.0), FLAT_FOOT_D, ("min_y", 0.0)], hold=0.2, dur=1.0)]
        txt = "Montée complète jusqu'à la position assise, pieds au sol."
    elif kind == "vup":
        kfs = [KF("allongé", A(t=-88, n=10, hanche=10, genou=0, cheville=-40, epaule=175, coude=0), anchor, [], [], hold=0.1, dur=0.8),
               KF("V", A(t=-40, n=20, hanche=95, genou=0, cheville=-40, epaule=120, coude=0), anchor, [], [], hold=0.2, dur=0.8)]
        txt = "Bras et jambes tendus se rejoignent au-dessus du bassin."
    elif kind == "twist":
        kfs = [KF("tenue en V", A(t=-45, n=15, hanche=100, genou=90, cheville=-20, epaule=60, coude=60), anchor, [("genou", 40, 130), ("cheville", -50, 38)], [("y", "talon_d", 0.0), FLAT_FOOT_D], hold=2.0, dur=0.6)]
        txt = "Buste incliné en arrière, rotation alternée du buste (représentée de profil)."
    elif kind == "dragon_flag":
        kfs = [KF("corps levé", A(t=-128, n=20, hanche=5, genou=0, cheville=-40, epaule=40, coude=30, poignet=0), ("epaule_d", (0.0, B.contact_offset("epaule_d"))), [("epaule", -30, 120), ("coude", 0, 100), ("poignet", -88, 88)], [("y", "prise_d", 0.0), ("min_y", -0.01)], hold=0.2, dur=1.4),
               KF("corps abaissé", A(t=-97, n=25, hanche=5, genou=0, cheville=-40, epaule=70, coude=30, poignet=0), ("epaule_d", (0.0, B.contact_offset("epaule_d"))), [("epaule", -30, 140), ("coude", 0, 100), ("poignet", -88, 88)], [("y", "prise_d", 0.0), ("min_y", -0.01)], hold=0.2, dur=1.4)]
        txt = "Corps rigide des épaules aux pieds, descente sans casser aux hanches."
    elif kind == "bridge":
        kfs = [KF("pont", A(t=-115, n=45, hanche=-25, genou=80, cheville=20, epaule=-135, coude=10, poignet=90), ("prise_d", (-0.30, 0.0)), [("t", -140, -95), ("hanche", -40, 0), ("epaule", -160, -100), ("poignet", -88, 105), ("cheville", -20, 38)], [("y", "talon_d", 0.0), FLAT_FOOT_D, HAND_FLAT_D], hold=2.0, dur=0.6)]
        txt = "Pont dorsal : mains et pieds au sol, hanches poussées vers le haut."
    elif kind == "bridge_unijambe":
        a = A(t=-115, n=45, hanche_d=-25, genou_d=80, cheville_d=20, hanche_g=60, genou_g=5, cheville_g=-30, epaule=-135, coude=10, poignet=90)
        kfs = [KF("pont une jambe", a, ("prise_d", (-0.30, 0.0)), [("t", -140, -95), ("hanche_d", -40, 0), ("epaule", -160, -100), ("poignet", -88, 105), ("cheville_d", -20, 38)], [("y", "talon_d", 0.0), FLAT_FOOT_D, HAND_FLAT_D], hold=2.0, dur=0.6)]
        txt = "Pont dorsal une jambe : une jambe tendue vers le plafond, l'autre pousse au sol."
    elif kind == "situp_jambes_tendues":
        kfs = [KF("allongé", A(t=-90, n=10, hanche=5, genou=0, cheville=-40, epaule=175, coude=0), anchor, [], [], hold=0.2, dur=1.0),
               KF("assis", A(t=20, n=25, hanche=110, genou=0, cheville=-40, epaule=100, coude=0), anchor, [("hanche", 90, 125)], [("min_y", 0.0), ("y", "talon_d", 0.0)], hold=0.2, dur=1.0)]
        txt = "Jambes tendues au sol, bras au-dessus de la tête : montée complète jusqu'à toucher les pieds."
    else:
        raise ValueError(kind)
    rom = {"epaule": (-170, 195), "cou": (-60, 80), "hanche": (-45, 160), "poignet": (-95, 108)}
    cont = [{"joint": kfs[0]["anchor"][0], "with": "sol"}]
    sheet(id_, "profil", kfs, [], cont, phases=[phase("mouvement", ["tronc", "hanche"], {}, {}, txt)],
          moteurs=["tronc", "hanche"], placement="allongé sur le dos", contacts_texte="dos/bassin au sol", tempo="contrôlé", sources=SRC["hollow"], rom_exceptions=rom, note=kind)


for k in ("hollow", "hollow_tuck", "hollow_rocks", "dead_bug", "leg_raise", "flutter", "crunch", "situp", "vup", "twist", "dragon_flag", "bridge", "bridge_unijambe", "situp_jambes_tendues"):
    supine(f"dos_au_sol.{k}", k)


def prone(id_, kind="superman"):
    """Couché sur le ventre : tête vers +x ; ancrage du bassin au sol."""
    anchor = ("bassin", (0.0, B.contact_offset("bassin")))
    if kind == "superman":
        kfs = [KF("au sol", A(t=90, n=-5, hanche=0, genou=0, cheville=-58, epaule=175, coude=0), anchor, [("cheville", -60, -30)], [("min_y", 0.0)], hold=0.2, dur=1.0),
               KF("levé", A(t=72, n=-15, hanche=-18, genou=0, cheville=-58, epaule=170, coude=0), anchor, [("cheville", -60, -30)], [("min_y", 0.0)], hold=0.5, dur=1.0)]
        txt = "Bras et jambes décollés de quelques centimètres, regard vers le sol."
    elif kind == "ytw":
        kfs = [KF("Y (bras devant, décollés)", A(t=84, n=-10, hanche=0, genou=0, cheville=-58, epaule=165, coude=0), anchor, [("cheville", -60, -30)], [("min_y", 0.0)], hold=0.6, dur=0.8),
               KF("W (coudes pliés, bras décollés)", A(t=84, n=-10, hanche=0, genou=0, cheville=-58, epaule=150, coude=100), anchor, [("cheville", -60, -30)], [("min_y", 0.0)], hold=0.6, dur=0.8)]
        txt = "Bras en Y puis W (le T, bras sur les côtés, n'est pas visible de profil), pouces vers le ciel, omoplates serrées."
    elif kind == "bird_dog":
        fr = [("poignet", -88, 88), ("epaule_d", 50, 120), ("t", 70, 100), ("cheville", -60, -30)]
        kfs = [KF("quadrupédie", A(t=88, n=-10, hanche=90, genou=90, cheville=-58, epaule=80, coude=0), ("genou_d", (0.0, 0.045)), fr + [("epaule_g", 50, 120)], [("y", "prise_d", 0.0), HAND_FLAT_D, ("min_y", 0.0)], hold=0.2, dur=1.0),
               KF("bras et jambe opposés tendus", A(t=88, n=-10, hanche_d=90, genou_d=90, hanche_g=-5, genou_g=0, cheville=-58, epaule_d=80, coude_d=0, epaule_g=178, coude_g=0), ("genou_d", (0.0, 0.045)), fr, [("y", "prise_d", 0.0), HAND_FLAT_D, ("min_y", 0.0)], hold=0.5, dur=1.0)]
        txt = "Depuis la quadrupédie, bras et jambe opposés s'allongent à l'horizontale."
        anchor = ("genou_d", (0.0, 0.045))
    elif kind == "cat_cow":
        fr = [("poignet", -88, 88), ("epaule", 50, 120), ("t", 75, 100), ("cheville", -60, -30)]
        kfs = [KF("dos rond", A(t=95, n=-30, hanche=100, genou=90, cheville=-58, epaule=85, coude=0), ("genou_d", (0.0, 0.045)), fr, [("y", "prise_d", 0.0), HAND_FLAT_D, ("min_y", 0.0)], hold=0.5, dur=1.2),
               KF("dos creux", A(t=80, n=25, hanche=80, genou=90, cheville=-58, epaule=95, coude=0), ("genou_d", (0.0, 0.045)), fr, [("y", "prise_d", 0.0), HAND_FLAT_D, ("min_y", 0.0)], hold=0.5, dur=1.2)]
        txt = "Alternance dos rond / dos creux, respiration lente."
        anchor = ("genou_d", (0.0, 0.045))
    elif kind == "nordic":
        kfs = [KF("genoux, buste droit", A(t=5, n=0, hanche=0, genou=90, cheville=-52, epaule=30, coude=90), ("genou_d", (0.0, 0.045)), [], [], hold=0.2, dur=2.5),
               KF("descente", A(t=55, n=0, hanche=0, genou=40, cheville=-52, epaule=60, coude=90), ("genou_d", (0.0, 0.045)), [], [], hold=0.1, dur=1.0)]
        txt = "Chevilles bloquées, le corps descend d'un bloc en freinant avec les ischio-jambiers."
        anchor = ("genou_d", (0.0, 0.045))
    elif kind == "hip_flexor":
        kfs = [KF("fente à genou", A(t=0, n=0, hanche_d=95, genou_d=95, cheville_d=5, hanche_g=-20, genou_g=90, cheville_g=-52, epaule=0, coude=0), ("talon_d", (0.0, 0.0)), [("hanche_g", -35, 0)], [("y", "genou_g", 0.045)], hold=2.0, dur=0.6)]
        txt = "Genou arrière au sol, bassin poussé vers l'avant."
        anchor = ("talon_d", (0.0, 0.0))
    else:
        raise ValueError(kind)
    rom = {"epaule": (-70, 195), "cou": (-60, 80), "hanche": (-45, 160)}
    sheet(id_, "profil", kfs, [], [{"joint": anchor[0], "with": "sol"}], phases=[phase("mouvement", ["tronc", "epaule", "hanche"], {}, {}, txt)],
          moteurs=["tronc", "hanche", "epaule"], placement="au sol", contacts_texte="appui au sol", tempo="contrôlé", sources=SRC["hollow"], rom_exceptions=rom, note=kind)


for k in ("superman", "ytw", "bird_dog", "cat_cow"):
    prone(f"ventre.{k}", k)
prone("genoux.nordic", "nordic")
prone("genoux.hip_flexor", "hip_flexor")


# ================================================================ DEBOUT : HAUT DU CORPS
def press(id_, kind="debout", props=None, charge=None):
    if kind == "assis":
        low = A(t=0, n=0, hanche=90, genou=90, cheville=0, epaule=45, coude=135, poignet=-20)
        high = A(t=0, n=0, hanche=90, genou=90, cheville=0, epaule=175, coude=0, poignet=0)
        anchor = ("bassin", (0.0, 0.21 + B.contact_offset("bassin")))
        pr = [{"type": "banc", "x": -0.30, "y": 0.21, "w": 0.4, "static": True, "layer": "arriere"}] + list(props or [])
        kfs = [KF("bas", low, anchor, [("genou", 50, 110), ("cheville", -20, 38)], [("y", "talon_d", 0.0), FLAT_FOOT_D], hold=0.2, dur=1.0), KF("haut", high, anchor, [("genou", 50, 110), ("cheville", -20, 38)], [("y", "talon_d", 0.0), FLAT_FOOT_D], hold=0.3, dur=1.0)]
        cont = [{"joint": "bassin", "with": "banc"}, {"joint": "talon_d", "with": "sol"}]
    elif kind == "push":
        dip = A(t=2, n=0, hanche=20, genou=25, cheville=12, epaule=45, coude=135, poignet=-20)
        high = A(t=0, n=0, hanche=0, genou=0, cheville=0, epaule=175, coude=0, poignet=0)
        anchor = on("talon_d")
        pr = list(props or [])
        kfs = [KF("flexion", dip, anchor, [("t", -5, 15)], [BALANCE, FLAT_FOOT_D], hold=0.0, dur=0.4), KF("verrouillage", high, anchor, [("t", -8, 8)], [BALANCE, FLAT_FOOT_D], hold=0.4, dur=0.8)]
        cont = FEET_BOTH
    else:
        low = A(t=2, n=0, hanche=0, genou=0, cheville=0, epaule=45, coude=135, poignet=-20)
        high = A(t=-3, n=0, hanche=0, genou=0, cheville=0, epaule=175, coude=0, poignet=0)
        anchor = on("talon_d")
        pr = list(props or [])
        kfs = [KF("bas", low, anchor, [("t", -8, 8)], [BALANCE, FLAT_FOOT_D], hold=0.2, dur=1.0), KF("haut", high, anchor, [("t", -8, 8)], [BALANCE, FLAT_FOOT_D], hold=0.3, dur=1.0)]
        cont = FEET_BOTH
    sheet(id_, "profil", kfs, pr, cont, phases=[phase("poussée", ["epaule", "coude"], {"epaule": 45, "coude": 135}, {"epaule": 175, "coude": 0}, "La barre part des clavicules et monte à la verticale, tête qui recule puis passe sous la barre."),
                                          phase("descente", ["epaule", "coude"], {}, {})],
          moteurs=["epaule", "coude"], prise="pronation, un peu plus large que les épaules", placement="pieds largeur de hanches, fessiers et abdominaux serrés",
          contacts_texte="pieds au sol", trajectoire="verticale, proche du visage", tempo="1 s montée, 2 s descente", sources=SRC["press"], debout=(kind != "assis"), charge=charge)


press("press.debout", props=[{"type": "barre_chargee", "attach": "prises"}], charge="barre")
press("press.halteres", props=[{"type": "halteres", "attach": "prise_d"}, {"type": "halteres", "attach": "prise_g"}], charge="haltères")
press("press.assis", kind="assis", props=[{"type": "halteres", "attach": "prise_d"}, {"type": "halteres", "attach": "prise_g"}], charge="haltères, assis")
press("press.push", kind="push", props=[{"type": "barre_chargee", "attach": "prises"}], charge="barre")
press("assis.press", kind="assis", props=[{"type": "barre_chargee", "attach": "prises"}], charge="barre, assis")


def curl(id_, kind="debout", props=None, charge=None):
    if kind == "pupitre":
        low = A(t=0, hanche=90, genou=90, epaule=55, coude=15, poignet=0)
        high = A(t=0, hanche=90, genou=90, epaule=55, coude=130, poignet=0)
        anchor = ("bassin", (0.0, BENCH_Y + B.contact_offset("bassin")))
        pr = [{"type": "banc_incline", "x": 0.1, "static": True}, {"type": "banc", "x": -0.3, "y": BENCH_Y, "w": 0.4, "static": True, "layer": "arriere"}] + list(props or [])
        kfs = [KF("bras tendus", low, anchor, [("genou", 50, 110), ("cheville", -20, 38)], [("y", "talon_d", 0.0), FLAT_FOOT_D], hold=0.2, dur=1.0), KF("flexion", high, anchor, [("genou", 50, 110), ("cheville", -20, 38)], [("y", "talon_d", 0.0), FLAT_FOOT_D], hold=0.2, dur=1.0)]
        cont = [{"joint": "bassin", "with": "banc"}]
    else:
        low = A(t=1, hanche=0, genou=0, cheville=0, epaule=3, coude=10, poignet=0)
        high = A(t=1, hanche=0, genou=0, cheville=0, epaule=10, coude=135, poignet=0)
        anchor = on("talon_d")
        pr = list(props or [])
        kfs = [KF("bras tendus", low, anchor, [("t", -8, 8)], [BALANCE, FLAT_FOOT_D], hold=0.2, dur=1.0), KF("flexion", high, anchor, [("t", -8, 8)], [BALANCE, FLAT_FOOT_D], hold=0.2, dur=1.0)]
        cont = FEET_BOTH
    sheet(id_, "profil", kfs, pr, cont, phases=[phase("flexion", ["coude"], {"coude": 10}, {"coude": 135}, "Coudes fixes le long du corps, flexion complète."), phase("extension", ["coude"], {"coude": 135}, {"coude": 10})],
          moteurs=["coude"], prise="supination (curl), neutre (marteau) ou pronation", placement="coudes près du buste", contacts_texte="pieds au sol", trajectoire="arc de cercle autour du coude",
          tempo="2 s montée, 2 s descente", sources=SRC["curl"], debout=(kind != "pupitre"), charge=charge)


curl("curl.debout", props=[{"type": "halteres", "attach": "prise_d"}, {"type": "halteres", "attach": "prise_g"}], charge="haltères")
curl("curl.barre", props=[{"type": "barre_chargee", "attach": "prises"}], charge="barre")
curl("curl.pupitre", kind="pupitre", props=[{"type": "halteres", "attach": "prise_d"}], charge="haltère")
curl("curl.poulie", props=[{"type": "poulie", "x": 0.55, "y": 0.05, "to": ["prise_d"], "static": True}], charge="poulie basse")


def triceps(id_, kind="poulie"):
    if kind == "poulie":
        low = A(t=8, hanche=5, genou=5, cheville=5, epaule=10, coude=100, poignet=0)
        high = A(t=8, hanche=5, genou=5, cheville=5, epaule=10, coude=15, poignet=0)
        pr = [{"type": "poulie", "x": 0.30, "y": 1.10, "to": ["prise_d"], "static": True}]
        txt = "Coudes fixes le long du corps, extension complète vers le bas."
    elif kind == "nuque":
        low = A(t=2, hanche=0, genou=0, cheville=0, epaule=178, coude=125, poignet=0)
        high = A(t=2, hanche=0, genou=0, cheville=0, epaule=178, coude=10, poignet=0)
        pr = [{"type": "halteres", "attach": "prises"}]
        txt = "Bras à la verticale, l'avant-bras descend derrière la tête puis remonte."
    else:  # kickback
        low = A(t=55, hanche=60, genou=20, cheville=10, epaule_d=-25, coude_d=90, epaule_g=90, coude_g=0, poignet=0)
        high = A(t=55, hanche=60, genou=20, cheville=10, epaule_d=-25, coude_d=5, epaule_g=90, coude_g=0, poignet=0)
        pr = [{"type": "halteres", "attach": "prise_d"}, {"type": "banc", "x": 0.15, "y": BENCH_Y, "w": 0.45, "static": True}]
        txt = "Buste penché, bras collé au buste, extension du coude vers l'arrière."
    anchor = on("talon_d")
    kfs = [KF("fléchi", low, anchor, [("t", -10, 70)], [BALANCE, FLAT_FOOT_D], hold=0.2, dur=1.0), KF("tendu", high, anchor, [("t", -10, 70)], [BALANCE, FLAT_FOOT_D], hold=0.2, dur=1.0)]
    sheet(id_, "profil", kfs, pr, FEET_BOTH, phases=[phase("extension", ["coude"], {"coude": low["coude_d"]}, {"coude": high["coude_d"]}, txt), phase("retour", ["coude"], {}, {})],
          moteurs=["coude"], placement="coude fixe", contacts_texte="pieds au sol", tempo="1 s / 2 s", sources=SRC["curl"], debout=True, rom_exceptions={"epaule": (-70, 195)})


triceps("triceps.poulie")
triceps("triceps.nuque", "nuque")
triceps("triceps.kickback", "kickback")


def row(id_, kind="penche", props=None, charge=None):
    if kind == "appui":
        low = A(t=45, n=-10, hanche=45, genou=0, cheville=0, epaule=45, coude=0)
        high = A(t=45, n=-10, hanche=45, genou=0, cheville=0, epaule=-20, coude=100)
        anchor = ("bassin", (0.0, 0.7))
        pr = [{"type": "banc_incline", "x": -0.35, "static": True}] + list(props or [])
        kfs = [KF("bras tendus", low, anchor, [], [], hold=0.2, dur=1.0), KF("coudes tirés", high, anchor, [], [], hold=0.3, dur=1.0)]
        cont = [{"joint": "bassin", "with": "banc"}]
        placement = "poitrine appuyée sur un banc incliné"
    else:
        low = A(t=65, n=-15, hanche=78, genou=20, cheville=8, epaule=65, coude=0)
        high = A(t=65, n=-15, hanche=78, genou=20, cheville=8, epaule=-15, coude=110)
        anchor = on("talon_d")
        pr = list(props or [])
        free = [("t", 45, 85), ("cheville", -10, 30)]
        kfs = [KF("bras tendus", low, anchor, free + [("epaule", 30, 110)], [BALANCE, FLAT_FOOT_D, ("abs", "ua_d", 0)], hold=0.2, dur=1.0),
               KF("coudes tirés", high, anchor, free, [BALANCE, FLAT_FOOT_D], hold=0.3, dur=1.0)]
        cont = FEET_BOTH
        placement = "buste penché proche de l'horizontale, dos plat, genoux légèrement fléchis"
    sheet(id_, "profil", kfs, pr, cont, phases=[phase("tirage", ["epaule", "coude"], {"coude": 0}, {"coude": 110, "epaule": -15}, "Coudes tirés vers l'arrière le long du buste, omoplates serrées."),
                                          phase("descente", ["epaule", "coude"], {}, {})],
          moteurs=["epaule", "coude"], prise="pronation ou neutre", placement=placement, contacts_texte="pieds au sol", trajectoire="vers le bas du sternum ou le nombril",
          tempo="1 s tirage, 2 s descente", sources=SRC["row"], debout=(kind != "appui"), charge=charge)


row("rowing.penche", props=[{"type": "barre_chargee", "attach": "prises"}], charge="barre")
row("rowing.haltere", props=[{"type": "halteres", "attach": "prise_d"}], charge="haltère (unilatéral)")
row("rowing.appui", kind="appui", props=[{"type": "halteres", "attach": "prise_d"}], charge="haltères")


def inverted_row(id_, rings=False, feet_up=False, archer=False, knees=False):
    y = LOW_BAR_Y if not rings else LOW_BAR_Y + 0.05
    fy = BOX_Y if feet_up else 0.0
    hk, kk = (40, 80) if knees else (0, 0)
    low = A(t=-75, n=15, hanche=hk, genou=kk, cheville=-20 if not knees else 10, epaule=90, coude=0)
    high = A(t=-75, n=15, hanche=hk, genou=kk, cheville=-20 if not knees else 10, epaule=5, coude=120)
    anchor = ("prise_d", (0.0, y))
    free = [("t", -110, -40), ("cheville", -58, 38)] + ([("hanche", 20, 70), ("genou", 50, 110)] if knees else [])
    cons = [("y", "talon_d", fy)] + ([("y", "pied_d", 0.0)] if knees else [])
    kfs = [KF("bras tendus", low, anchor, free, cons, hold=0.2, dur=1.0), KF("poitrine à la barre", high, anchor, free, cons, hold=0.3, dur=1.0)]
    if archer:
        for k in kfs:
            k["angles"]["epaule_g"], k["angles"]["coude_g"] = 90, 0
    pr = [{"type": "anneaux" if rings else "barre_basse", "x": 0.0, "y": y, "static": True}]
    if feet_up:
        pr.append({"type": "box", "x": 0.72, "y": 0.0, "w": 0.30, "h": BOX_Y, "static": True})
    sheet(id_, "profil", kfs, pr, [{"joint": "prise_d", "with": "barre_basse"}, {"joint": "talon_d", "with": "box" if feet_up else "sol"}],
          phases=[phase("tirage", ["epaule", "coude"], {"coude": 0}, {"coude": 120}, "Corps rigide, la poitrine vient à la barre."), phase("descente", ["epaule", "coude"], {}, {})],
          moteurs=["epaule", "coude"], prise="pronation largeur d'épaules" if not rings else "anneaux, prise neutre", placement="talons au sol" + (" surélevés" if feet_up else "") + ", corps en ligne",
          contacts_texte="mains sur la barre, talons au sol", tempo="1 s / 2 s", sources=SRC["inverted_row"], rom_exceptions={"epaule": (-70, 195)}, note="rowing australien")


inverted_row("rowing.australien")
inverted_row("rowing.australien_pieds_hauts", feet_up=True)
inverted_row("rowing.anneaux", rings=True)
inverted_row("rowing.archer", archer=True)
inverted_row("rowing.australien_genoux", knees=True)
REG["rowing.australien_genoux"]["placement"] = "genoux fléchis, pieds à plat, corps en ligne des genoux aux épaules"
REG["rowing.australien_genoux"]["note"] = "rowing australien genoux fléchis (version facile)"


def lateral_raise(id_, kind="laterale"):
    if kind == "laterale":
        low = A(t=0, epaule=12, coude=12)
        high = A(t=0, epaule=90, coude=12)
        view, txt = "face", "Bras montés sur les côtés jusqu'à l'horizontale, coudes légèrement fléchis."
        pr = [{"type": "halteres", "attach": "prise_d"}, {"type": "halteres", "attach": "prise_g"}]
    elif kind == "frontale":
        low = A(t=0, epaule=8, coude=8)
        high = A(t=0, epaule=90, coude=8)
        view, txt = "profil", "Bras montés devant jusqu'à l'horizontale."
        pr = [{"type": "halteres", "attach": "prise_d"}]
    else:  # oiseau
        low = A(t=60, n=-15, hanche=70, genou=20, cheville=8, epaule=60, coude=15)
        high = A(t=60, n=-15, hanche=70, genou=20, cheville=8, epaule=-10, coude=15)
        view, txt = "profil", "Buste penché, bras écartés vers l'arrière et les côtés (vue de profil)."
        pr = [{"type": "halteres", "attach": "prise_d"}]
    anchor = on("talon_d") if view == "profil" else ("pied_d", (-0.09, 0.0))
    free = [("t", -8, 70)] if view == "profil" else []
    cons = [BALANCE, FLAT_FOOT_D] if view == "profil" else []
    kfs = [KF("bas", low, anchor, free, cons, hold=0.2, dur=1.0), KF("haut", high, anchor, free, cons, hold=0.3, dur=1.0)]
    sheet(id_, view, kfs, pr, FEET_BOTH, phases=[phase("élévation", ["epaule"], {"epaule": 10}, {"epaule": 90}, txt), phase("descente", ["epaule"], {}, {})],
          moteurs=["epaule"], placement="debout, buste stable", contacts_texte="pieds au sol", tempo="1 s / 2 s", sources=SRC["press"], debout=True, charge="haltères")


lateral_raise("elevation.laterale")
lateral_raise("elevation.frontale", "frontale")
lateral_raise("elevation.oiseau", "oiseau")


def standing_simple(id_, low, high, props=None, txt="", hold=0.2, dur=1.0, moteurs=None, view="profil", charge=None, note="", rom=None, iso=False):
    anchor = on("talon_d") if view == "profil" else ("pied_d", (-0.09, 0.0))
    free = [("t", -10, 20)] if view == "profil" else []
    cons = [BALANCE, FLAT_FOOT_D] if view == "profil" else []
    kfs = [KF("départ", low, anchor, free, cons, hold=hold, dur=dur)]
    if not iso:
        kfs.append(KF("arrivée", high, anchor, free, cons, hold=hold, dur=dur))
    else:
        kfs[0]["hold"] = 2.0
    sheet(id_, view, kfs, props or [], FEET_BOTH, phases=[phase("mouvement", moteurs or ["epaule"], {}, {}, txt)], moteurs=moteurs or ["epaule"],
          contacts_texte="pieds au sol", tempo="contrôlé", sources=SRC["transpose"], debout=True, charge=charge, note=note, rom_exceptions=rom or {})


standing_simple("tirage.menton", A(epaule=5, coude=5), A(epaule=60, coude=120), [{"type": "barre_chargee", "attach": "prises"}], "Coudes tirés vers le haut et l'extérieur, barre le long du buste.", moteurs=["epaule", "coude"], charge="barre")
standing_simple("tirage.shrug", A(epaule=3, coude=0), A(epaule=3, coude=0, n=-5), [{"type": "halteres", "attach": "prise_d"}, {"type": "halteres", "attach": "prise_g"}], "Haussement d'épaules vers les oreilles, bras tendus (l'élévation de la ceinture scapulaire n'est pas modélisée : seule la charge bouge).", moteurs=["epaule (élévation)"], charge="haltères", note="shrug : représentation limitée")
standing_simple("debout.poignets", A(epaule=5, coude=90, poignet=45), A(epaule=5, coude=90, poignet=-45), [{"type": "halteres", "attach": "prise_d"}], "Avant-bras horizontal, flexion puis extension du poignet.", moteurs=["poignet"], charge="haltère", note="travail du poignet")
standing_simple("debout.grip", A(epaule=3, coude=0, poignet=0), A(epaule=3, coude=0, poignet=0), [{"type": "halteres", "attach": "prise_d"}, {"type": "halteres", "attach": "prise_g"}], "Tenue statique de la charge, bras le long du corps.", moteurs=["main (préhension)"], charge="haltères ou kettlebells", iso=True)
standing_simple("debout.dislocation", A(epaule=20, coude=0), A(epaule=200, coude=0), [{"type": "baton", "between": ["prise_g", "prise_d"]}], "Bâton tenu large : passage devant, au-dessus puis derrière, bras tendus.", moteurs=["epaule"], rom={"epaule": (-70, 215)}, note="dislocations à l'élastique ou au bâton")
standing_simple("debout.rotations_bras", A(epaule=0, coude=0), A(epaule=180, coude=0), [], "Cercles de bras complets, lents.", moteurs=["epaule"])
standing_simple("debout.wall_slide", A(epaule=90, coude=90), A(epaule=170, coude=10), [{"type": "mur", "x": -0.14, "static": True}], "Dos au mur, les bras glissent vers le haut en gardant le contact.", moteurs=["epaule"])
standing_simple("debout.respiration", A(epaule=5, coude=0), A(epaule=5, coude=0), [], "Respiration diaphragmatique debout ou assis.", moteurs=["diaphragme"], iso=True)
hinge("debout.etirement_post", hanche=115, genou=8, tronc=(85, 125), arms_hang=True, note="flexion avant jambes tendues, mains vers les pieds")
REG["debout.etirement_post"]["rom_exceptions"] = {"hanche": (-30, 150)}
# mobilité de cheville « genou au mur » : pied avant à ~8 cm du mur, le genou avance jusqu'au mur talon au sol, jambe arrière en fente
WALL_X = 0.085   # distance pointe du pied → mur (l'ancre est la pointe du pied avant)
_ank_free = [("t", -8, 30), ("hanche_g", -30, -5), ("genou_g", 0, 45), ("cheville_g", -45, 5), ("epaule", 60, 100), ("coude", 0, 120)]
_ank_cons = [("y", "talon_d", 0.0), ("y", "pied_g", 0.0), ("x", "prise_d", WALL_X - 0.02)]
sheet("debout.cheville", "profil",
      [KF("départ", A(t=0, hanche_d=15, genou_d=20, cheville_d=5, hanche_g=-12, genou_g=10, cheville_g=-25, epaule=80, coude=20), on("pied_d"), _ank_free, _ank_cons, hold=0.3, dur=1.2),
       KF("genou au mur", A(t=20, hanche_d=40, genou_d=55, cheville_d=35, hanche_g=-12, genou_g=12, cheville_g=-35, epaule=75, coude=80), on("pied_d"), _ank_free, _ank_cons + [("x", "genou_d", WALL_X - 0.015)], hold=0.8, dur=1.2)],
      [{"type": "mur", "x": WALL_X, "static": True}], FEET + [{"joint": "pied_g", "with": "sol"}, {"joint": "prise_d", "with": "mur"}], "aller-retour",
      phases=[phase("avancée du genou", ["cheville", "genou"], {"cheville": 5}, {"cheville": 35}, "Le genou avance dans l'axe du pied jusqu'à toucher le mur, le talon reste plaqué au sol."), phase("retour", ["cheville"], {}, {})],
      moteurs=["cheville"], placement="pied avant à 8-10 cm du mur, mains sur le mur, jambe arrière en fente", contacts_texte="pied avant à plat, mains sur le mur", tempo="2 s / 2 s",
      sources=SRC["transpose"], debout=True, note="mobilité de cheville genou au mur", rom_exceptions={"cheville": (-60, 45)})


# ================================================================ BANC : DÉVELOPPÉS COUCHÉS
def bench(id_, kind="couche", props=None, charge="barre", incline=False):
    """Couché sur le dos sur un banc, tête vers −x ; pieds au sol ; le bassin est ancré sur le banc."""
    ys = BENCH_Y + B.contact_offset("bassin")
    t = -90 if not incline else -55
    base = dict(t=t, n=0, hanche=(-25 if not incline else 0), genou=90, cheville=10)
    if kind == "couche":
        low = A(epaule=105, coude=95, poignet=0, **base)
        high = A(epaule=90, coude=0, poignet=0, **base)
        txt = "Barre descendue au bas du sternum, coudes à environ 45° du buste, puis poussée verticale."
    elif kind == "barre_front":
        low = A(epaule=100, coude=110, poignet=0, **base)
        high = A(epaule=100, coude=5, poignet=0, **base)
        txt = "Bras fixes à la verticale, seuls les coudes fléchissent ; la barre descend vers le front."
    elif kind == "ecarte":
        low = A(epaule=100, coude=15, poignet=0, **base)
        high = A(epaule=95, coude=15, poignet=0, **base)
        txt = "Bras presque tendus, ouverture large puis rapprochement au-dessus de la poitrine (vue de profil : le mouvement se fait dans le plan frontal)."
    elif kind == "floor":
        ys = B.contact_offset("bassin")
        base = dict(t=-90, n=0, hanche=45, genou=90, cheville=10)
        low = A(epaule=100, coude=90, poignet=0, **base)
        high = A(epaule=90, coude=0, poignet=0, **base)
        txt = "Développé au sol : les coudes s'arrêtent au contact du sol."
    else:
        raise ValueError(kind)
    anchor = ("bassin", (0.0, ys))
    fr = [("hanche", -45, 60), ("genou", 60, 125), ("cheville", -20, 38)]
    cs = [("y", "talon_d", 0.0), FLAT_FOOT_D]
    kfs = [KF("bas", low, anchor, fr, cs, hold=0.2 if kind != "pause" else 1.0, dur=1.0),
           KF("haut", high, anchor, fr, cs, hold=0.2, dur=1.0)]
    pr = list(props or [])
    if incline:
        pr.insert(0, {"type": "banc_incline", "x": -0.35, "static": True, "layer": "arriere"})
    elif kind != "floor":
        pr.insert(0, {"type": "banc", "x": -0.62, "y": BENCH_Y, "w": 0.75, "static": True, "layer": "arriere"})
    sheet(id_, "profil", kfs, pr, [{"joint": "bassin", "with": "banc" if kind != "floor" else "sol"}, {"joint": "talon_d", "with": "sol"}],
          phases=[phase("descente", ["epaule", "coude"], {"coude": high["coude_d"]}, {"coude": low["coude_d"]}, txt), phase("poussée", ["epaule", "coude"], {}, {})],
          moteurs=["epaule", "coude"], prise="pronation, un peu plus large que les épaules", placement="omoplates serrées, pieds au sol", contacts_texte="dos sur le banc, pieds au sol",
          trajectoire="légèrement oblique vers la tête", tempo="2 s descente, 1 s poussée", sources=SRC["banc"], rom_exceptions={"epaule": (-70, 195)}, charge=charge, note=kind)


bench("banc.couche", props=[{"type": "barre_chargee", "attach": "prises"}])
bench("banc.pause", props=[{"type": "barre_chargee", "attach": "prises"}], charge="barre (pause en bas)")
bench("banc.incline", incline=True, props=[{"type": "barre_chargee", "attach": "prises"}])
bench("banc.barre_front", kind="barre_front", props=[{"type": "barre_chargee", "attach": "prises"}])
bench("banc.ecarte", kind="ecarte", props=[{"type": "halteres", "attach": "prise_d"}], charge="haltères")
bench("banc.floor", kind="floor", props=[{"type": "barre_chargee", "attach": "prises"}])


# ================================================================ ASSIS : POULIES ET MACHINES
def seated(id_, low, high, props, txt, moteurs, prise="", charge=None, rom=None, seat_y=BENCH_Y):
    anchor = ("bassin", (0.0, seat_y + B.contact_offset("bassin")))
    legs = [("genou", 50, 110), ("cheville", -20, 38)] if seat_y > 0 else []
    lc = [("y", "talon_d", 0.0), FLAT_FOOT_D] if seat_y > 0 else []
    kfs = [KF("départ", low, anchor, legs, lc, hold=0.2, dur=1.0), KF("arrivée", high, anchor, legs, lc, hold=0.3, dur=1.0)]
    pr = [{"type": "banc", "x": -0.28, "y": seat_y, "w": 0.42, "static": True, "layer": "arriere"}] + list(props)
    sheet(id_, "profil", kfs, pr, [{"joint": "bassin", "with": "siège"}], phases=[phase("mouvement", moteurs, {}, {}, txt)], moteurs=moteurs, prise=prise,
          placement="assis, dos droit", contacts_texte="assis, pieds au sol ou calés", tempo="1 s effort, 2 s retour", sources=SRC["transpose"], rom_exceptions=rom or {}, charge=charge)


SEAT = dict(hanche=90, genou=90, cheville=0)
seated("assis.pulldown", A(t=-10, epaule=170, coude=5, **SEAT), A(t=-15, epaule=40, coude=130, **SEAT),
       [{"type": "poulie", "x": 0.15, "y": 1.35, "to": ["prise_d"], "static": True}], "Tirage de la barre vers le haut de la poitrine, coudes vers le bas et l'arrière.", ["epaule", "coude"], "pronation large", "poulie haute", {"epaule": (-70, 195)})
seated("assis.row", A(t=5, epaule=80, coude=5, **dict(hanche=85, genou=25, cheville=15)), A(t=0, epaule=-20, coude=110, **dict(hanche=85, genou=25, cheville=15)),
       [{"type": "poulie", "x": 0.9, "y": 0.35, "to": ["prise_d"], "static": True}], "Tirage horizontal vers le ventre, omoplates serrées, buste stable.", ["epaule", "coude"], "neutre", "poulie basse", seat_y=0.25)
seated("assis.leg_extension", A(t=-5, epaule=-10, coude=20, hanche=95, genou=90, cheville=0), A(t=-5, epaule=-10, coude=20, hanche=95, genou=5, cheville=0),
       [{"type": "machine", "x": -0.22, "y": 0.4, "static": True, "layer": "arriere"}], "Extension complète des genoux, dos plaqué au dossier.", ["genou"], "", "machine")
seated("assis.leg_curl", A(t=-5, epaule=-10, coude=20, hanche=95, genou=5, cheville=0), A(t=-5, epaule=-10, coude=20, hanche=95, genou=110, cheville=0),
       [{"type": "machine", "x": -0.22, "y": 0.4, "static": True, "layer": "arriere"}], "Flexion des genoux contre la résistance, bassin plaqué.", ["genou"], "", "machine")
seated("assis.calf_seated", A(t=0, epaule=20, coude=90, hanche=90, genou=90, cheville=15), A(t=0, epaule=20, coude=90, hanche=90, genou=90, cheville=-35),
       [{"type": "machine", "x": 0.3, "y": 0.3, "static": True, "layer": "arriere"}], "Genoux à 90°, montée sur la pointe des pieds sous la charge.", ["cheville"], "", "machine")
seated("assis.abduction", A(t=0, epaule=-10, coude=20, **SEAT), A(t=0, epaule=-10, coude=20, **SEAT), [{"type": "machine", "x": -0.22, "y": 0.4, "static": True, "layer": "arriere"}],
       "Écartement des cuisses contre les coussins (mouvement dans le plan frontal, non visible de profil).", ["hanche"], "", "machine")
seated("assis.adduction", A(t=0, epaule=-10, coude=20, **SEAT), A(t=0, epaule=-10, coude=20, **SEAT), [{"type": "machine", "x": -0.22, "y": 0.4, "static": True, "layer": "arriere"}],
       "Serrage des cuisses contre les coussins (mouvement dans le plan frontal, non visible de profil).", ["hanche"], "", "machine")
seated("assis.pec_deck", A(t=0, epaule=95, coude=20, **SEAT), A(t=0, epaule=90, coude=20, **SEAT), [{"type": "machine", "x": -0.22, "y": 0.4, "static": True, "layer": "arriere"}],
       "Bras à l'horizontale, rapprochement devant la poitrine (plan frontal).", ["epaule"], "", "machine")
seated("assis_sol.flexion", A(t=15, epaule=90, coude=0, hanche=100, genou=0, cheville=10), A(t=60, epaule=150, coude=0, hanche=140, genou=5, cheville=15), [],
       "Assis jambes tendues, flexion du buste vers les pieds.", ["hanche"], "", None, {"hanche": (-30, 160)}, seat_y=0.0)
REG["assis_sol.flexion"]["accessoires"] = []
for k in REG["assis_sol.flexion"]["images_cles"]:
    k["free"], k["constraints"] = [("genou", 0, 40), ("cheville", -30, 38)], [("y", "talon_d", 0.0), ("min_y", 0.0)]


def cable(id_, low, high, pulley, txt, moteurs, view="profil", charge="poulie", stance=None, rom=None, iso=False):
    st = stance or dict(hanche=5, genou=8, cheville=5)
    lo = A(**{**st, **low})
    hi = A(**{**st, **high})
    anchor = on("talon_d") if view == "profil" else ("pied_d", (-0.09, 0.0))
    free = [("t", -10, 20)] if view == "profil" else []
    cons = [BALANCE, FLAT_FOOT_D] if view == "profil" else []
    kfs = [KF("départ", lo, anchor, free, cons, hold=0.2 if not iso else 2.0, dur=1.0)]
    if not iso:
        kfs.append(KF("arrivée", hi, anchor, free, cons, hold=0.3, dur=1.0))
    sheet(id_, view, kfs, [pulley], FEET_BOTH, phases=[phase("mouvement", moteurs, {}, {}, txt)], moteurs=moteurs, placement="debout, pieds stables",
          contacts_texte="pieds au sol", tempo="1 s / 2 s", sources=SRC["transpose"], debout=True, charge=charge, rom_exceptions=rom or {})


cable("cable.face_pull", dict(t=5, epaule=95, coude=10), dict(t=5, epaule=80, coude=120), {"type": "poulie", "x": 0.85, "y": 0.95, "to": ["prise_d"], "static": True},
      "Tirage de la corde vers le visage, coudes hauts et vers l'arrière, rotation externe en fin de course.", ["epaule", "coude"])
cable("cable.pallof", dict(t=0, epaule=90, coude=0), dict(t=0, epaule=40, coude=120), {"type": "poulie", "x": -0.75, "y": 0.85, "to": ["prise_d"], "static": True},
      "Poulie sur le côté (représentée derrière) : bras tendus devant puis ramenés à la poitrine sans rotation du buste.", ["tronc (anti-rotation)", "epaule"])
cable("cable.rotation_ext", dict(t=0, epaule=0, coude=90, poignet=0), dict(t=0, epaule=0, coude=90, poignet=0), {"type": "poulie", "x": 0.6, "y": 0.6, "to": ["prise_d"], "static": True},
      "Coude collé au corps à 90°, rotation externe de l'avant-bras vers l'extérieur (mouvement horizontal, non visible de profil).", ["epaule (rotation externe)"], iso=True)
cable("cable.woodchop", dict(t=-5, epaule=150, coude=10), dict(t=25, hanche=40, genou=20, epaule=30, coude=10), {"type": "poulie", "x": -0.6, "y": 1.2, "to": ["prise_d"], "static": True},
      "Tirage en diagonale du haut vers le bas avec rotation du buste (représentée de profil).", ["tronc (rotation)", "hanche"])
cable("cable.crunch", dict(t=10, hanche=100, genou=100, cheville=-30, epaule=150, coude=120), dict(t=60, hanche=110, genou=100, cheville=-30, epaule=140, coude=120),
      {"type": "poulie", "x": 0.15, "y": 1.35, "to": ["prise_d"], "static": True}, "À genoux face à la poulie haute, enroulement du buste vers les genoux.", ["tronc"], stance=dict(hanche=100, genou=100, cheville=-52))
REG["cable.crunch"]["images_cles"][0]["anchor"] = ("genou_d", (0.0, 0.045)); REG["cable.crunch"]["images_cles"][1]["anchor"] = ("genou_d", (0.0, 0.045))
for k in REG["cable.crunch"]["images_cles"]:
    k["free"], k["constraints"] = [("hanche", 40, 130), ("genou", 60, 140)], [("abs", "sh_d", -90)]
REG["cable.crunch"]["contacts"] = [{"joint": "genou_d", "with": "sol"}]
cable("cable.pullover", dict(t=25, hanche=25, genou=10, epaule=150, coude=10), dict(t=25, hanche=25, genou=10, epaule=20, coude=10), {"type": "poulie", "x": 0.7, "y": 1.35, "to": ["prise_d"], "static": True},
      "Bras tendus, abaissement de la barre de la hauteur de la tête jusqu'aux cuisses.", ["epaule"])
cable("cable.straight_arm", dict(t=25, hanche=25, genou=10, epaule=150, coude=10), dict(t=25, hanche=25, genou=10, epaule=20, coude=10), {"type": "poulie", "x": 0.7, "y": 1.35, "to": ["prise_d"], "static": True},
      "Tirage bras tendus, coudes fixes, jusqu'aux cuisses.", ["epaule"])
cable("cable.pull_apart", dict(t=0, epaule=90, coude=5), dict(t=0, epaule=90, coude=5), {"type": "elastique", "x": 0.0, "y": 0.0, "to": [], "static": True},
      "Élastique tenu devant, bras tendus, écartement des mains jusqu'à la poitrine (plan frontal).", ["epaule", "omoplates"], charge="élastique", iso=True)
REG["cable.pull_apart"]["accessoires"] = [{"type": "baton", "between": ["prise_g", "prise_d"]}]


# ================================================================ HALTÉROPHILIE, SWING, LANCERS
def olympic(id_, kind="clean"):
    if kind == "clean":
        kfs = [KF("départ", A(t=48, hanche=105, genou=75, cheville=25, epaule=48, coude=0), on("talon_d"), [("t", 30, 60), ("cheville", 0, 38)], [BALANCE, FLAT_FOOT_D, ("abs", "ua_d", 0)], hold=0.3, dur=0.6),
               KF("extension", A(t=-5, hanche=-5, genou=5, cheville=-30, epaule=10, coude=20), ("pied_d", (0.05, 0.0)), [("t", -10, 5)], [("com_x", "pied_d", 0.0)], hold=0.0, dur=0.3),
               KF("réception", A(t=15, hanche=110, genou=115, cheville=30, epaule=95, coude=150), on("talon_d"), [("t", 5, 30), ("cheville", 10, 38)], [BALANCE, FLAT_FOOT_D], hold=0.2, dur=0.6),
               KF("debout", A(t=0, epaule=95, coude=150), on("talon_d"), [("t", -8, 8)], [BALANCE, FLAT_FOOT_D], hold=0.3, dur=0.6)]
        props = [{"type": "barre_chargee", "attach": "prises"}]
        txt = "Tirage depuis le sol, extension complète, réception en squat avant, relevé."
        note = "épaulé (clean)"
    elif kind == "snatch":
        kfs = [KF("départ", A(t=50, hanche=110, genou=80, cheville=25, epaule=50, coude=0), on("talon_d"), [("t", 30, 60), ("cheville", 0, 38)], [BALANCE, FLAT_FOOT_D, ("abs", "ua_d", 0)], hold=0.3, dur=0.6),
               KF("extension", A(t=-5, hanche=-5, genou=5, cheville=-30, epaule=10, coude=20), ("pied_d", (0.05, 0.0)), [("t", -10, 5)], [("com_x", "pied_d", 0.0)], hold=0.0, dur=0.3),
               KF("réception", A(t=15, hanche=115, genou=120, cheville=32, epaule=178, coude=0), on("talon_d"), [("t", 0, 30), ("cheville", 10, 38)], [BALANCE, FLAT_FOOT_D], hold=0.2, dur=0.6),
               KF("debout", A(t=0, epaule=178, coude=0), on("talon_d"), [("t", -8, 8)], [BALANCE, FLAT_FOOT_D], hold=0.3, dur=0.6)]
        props = [{"type": "barre_chargee", "attach": "prises"}]
        txt = "Tirage large depuis le sol, extension, réception bras tendus au-dessus de la tête en squat, relevé."
        note = "arraché (snatch)"
    elif kind == "clean_press":
        kfs = [KF("départ", A(t=45, hanche=100, genou=70, cheville=25, epaule=45, coude=0), on("talon_d"), [("t", 30, 60), ("cheville", 0, 38)], [BALANCE, FLAT_FOOT_D, ("abs", "ua_d", 0)], hold=0.3, dur=0.7),
               KF("épaulé", A(t=0, epaule=45, coude=135), on("talon_d"), [("t", -8, 8)], [BALANCE, FLAT_FOOT_D], hold=0.2, dur=0.8),
               KF("développé", A(t=-3, epaule=175, coude=0), on("talon_d"), [("t", -8, 8)], [BALANCE, FLAT_FOOT_D], hold=0.3, dur=0.8)]
        props = [{"type": "barre_chargee", "attach": "prises"}]
        txt = "Épaulé puis développé au-dessus de la tête."
        note = "épaulé-développé"
    else:  # thruster
        kfs = [KF("squat avant", A(t=15, hanche=110, genou=115, cheville=30, epaule=95, coude=150), on("talon_d"), [("t", 5, 30), ("cheville", 10, 38)], [BALANCE, FLAT_FOOT_D], hold=0.1, dur=0.7),
               KF("verrouillage", A(t=-3, epaule=175, coude=0), on("talon_d"), [("t", -8, 8)], [BALANCE, FLAT_FOOT_D], hold=0.2, dur=0.7)]
        props = [{"type": "barre_chargee", "attach": "prises"}]
        txt = "Squat avant enchaîné avec une poussée au-dessus de la tête."
        note = "thruster"
    oc = [{"joint": "pied_d", "with": "sol"}, {"joint": "pied_g", "with": "sol"}] + ([{"joint": "talon_d", "with": "sol", "kf": [0, 2, 3]}] if kind in ("clean", "snatch") else [{"joint": "talon_d", "with": "sol"}])
    sheet(id_, "profil", kfs, props, oc, "cycle" if kind in ("clean", "snatch") else "aller-retour", phases=[phase("séquence", ["hanche", "genou", "epaule", "coude"], {}, {}, txt)],
          moteurs=["hanche", "genou", "epaule"], prise="pronation", placement="pieds largeur de hanches", contacts_texte="pieds au sol", trajectoire="verticale proche du corps",
          tempo="explosif", sources=SRC["hinge"] + SRC["press"], debout=True, charge="barre", note=note, rom_exceptions={"cheville": (-60, 45)})


for k in ("clean", "snatch", "clean_press", "thruster"):
    olympic(f"olympique.{k}", k)


def turkish(id_):
    anchor = ("bassin", (0.0, B.contact_offset("bassin")))
    kfs = [KF("allongé", A(t=-90, n=10, hanche_d=45, genou_d=90, hanche_g=10, genou_g=0, cheville=0, epaule_d=90, coude_d=0, epaule_g=-10, coude_g=0), anchor, [], [], hold=0.3, dur=1.2),
           KF("sur le coude puis la main", A(t=-45, n=0, hanche_d=70, genou_d=90, hanche_g=25, genou_g=0, cheville=0, epaule_d=135, coude_d=0, epaule_g=-70, coude_g=0, poignet_g=-45), ("prise_g", (-0.35, 0.0)), [("t", -70, -20), ("hanche_d", 40, 110), ("hanche_g", 0, 50), ("genou_d", 60, 120), ("cheville", -30, 38), ("epaule_g", -110, -40)], [("y", "talon_d", 0.0), ("min_y", 0.0), FLAT_FOOT_D], hold=0.3, dur=1.2),
           KF("debout", A(t=0, epaule_d=178, coude_d=0, epaule_g=5, coude_g=0), on("talon_d"), [("t", -8, 8)], [BALANCE, FLAT_FOOT_D], hold=0.5, dur=1.2)]
    sheet(id_, "profil", kfs, [{"type": "kettlebell", "attach": "prise_d", "offset": [0.0, 0.11]}], [{"joint": "bassin", "with": "sol", "kf": [0]}, {"joint": "prise_g", "with": "sol", "kf": [1]}, {"joint": "talon_d", "with": "sol", "kf": [1, 2]}],
          phases=[phase("relevé", ["epaule", "tronc", "hanche"], {}, {}, "Kettlebell bras tendu vers le plafond du début à la fin ; relevé par étapes jusqu'à la station debout (représentation simplifiée en 3 positions).")],
          moteurs=["epaule", "tronc", "hanche"], prise="kettlebell verrouillée au-dessus de l'épaule", tempo="lent, 3 s par étape", sources=SRC["transpose"], rom_exceptions={"epaule": (-90, 195), "poignet": (-95, 95)}, charge="kettlebell", note="relevé turc")


turkish("turkish.getup")


def throw(id_, kind="slam"):
    if kind == "slam":
        kfs = [KF("ballon au-dessus de la tête", A(t=-5, hanche=0, genou=5, cheville=0, epaule=175, coude=10), on("talon_d"), [("t", -10, 5), ("cheville", -10, 20)], [BALANCE, FLAT_FOOT_D], hold=0.1, dur=0.4),
               KF("lancer au sol", A(t=45, hanche=95, genou=60, cheville=20, epaule=30, coude=10), on("talon_d"), [("t", 30, 60), ("cheville", 0, 38)], [BALANCE, FLAT_FOOT_D], hold=0.1, dur=0.4)]
        props = [{"type": "medecine_ball", "attach": "prises"}]
        txt = "Ballon levé bras tendus puis projeté au sol avec tout le corps."
    else:
        kfs = [KF("squat ballon à la poitrine", A(t=15, hanche=110, genou=115, cheville=30, epaule=60, coude=140), on("talon_d"), [("t", 5, 30), ("cheville", 10, 38)], [BALANCE, FLAT_FOOT_D], hold=0.1, dur=0.6),
               KF("lancer vers la cible", A(t=-5, hanche=0, genou=0, cheville=-20, epaule=160, coude=20), ("pied_d", (0.05, 0.0)), [("t", -10, 5)], [("com_x", "pied_d", 0.0)], hold=0.1, dur=0.6)]
        props = [{"type": "medecine_ball", "attach": "prises"}, {"type": "mur", "x": 0.55, "static": True}]
        txt = "Squat complet puis lancer du ballon vers la cible haute du mur."
    sheet(id_, "profil", kfs, props, [{"joint": "pied_d", "with": "sol"}, {"joint": "talon_d", "with": "sol", "kf": [0]}], "aller-retour", phases=[phase("lancer", ["hanche", "genou", "epaule"], {}, {}, txt)], moteurs=["hanche", "genou", "epaule"],
          contacts_texte="pieds au sol", tempo="explosif", sources=SRC["transpose"], debout=True, charge="médecine-ball", rom_exceptions={"cheville": (-60, 45)})


throw("lancer.slam")
throw("lancer.wall_ball", "wall_ball")


# ================================================================ LOCOMOTION, SAUTS, CARDIO
def gait(id_, kind="marche"):
    if kind == "marche":
        f1 = A(t=2, hanche_d=25, genou_d=5, cheville_d=5, hanche_g=-15, genou_g=10, cheville_g=-15, epaule_d=-20, coude_d=20, epaule_g=20, coude_g=20)
        f2 = A(t=2, hanche_d=-15, genou_d=10, cheville_d=-15, hanche_g=25, genou_g=5, cheville_g=5, epaule_d=20, coude_d=20, epaule_g=-20, coude_g=20)
        kfs = [KF("pas droit", f1, on("talon_d"), [("cheville_g", -40, 20)], [("y", "pied_g", 0.0)], hold=0.0, dur=0.55),
               KF("pas gauche", f2, on("talon_g"), [("cheville_d", -40, 20)], [("y", "pied_d", 0.0)], hold=0.0, dur=0.55)]
        txt, tempo = "Marche à allure régulière, bras opposés.", "≈ 110 pas/min"
        heel = True
    elif kind == "course":
        f1 = A(t=6, hanche_d=35, genou_d=25, cheville_d=-12, hanche_g=-15, genou_g=60, cheville_g=-25, epaule_d=-25, coude_d=90, epaule_g=30, coude_g=90)
        f2 = A(t=6, hanche_d=-15, genou_d=60, cheville_d=-25, hanche_g=35, genou_g=25, cheville_g=-12, epaule_d=30, coude_d=90, epaule_g=-25, coude_g=90)
        kfs = [KF("appui droit", f1, ("pied_d", (0.0, 0.0)), [], [], hold=0.0, dur=0.32), KF("appui gauche", f2, ("pied_g", (0.0, 0.0)), [], [], hold=0.0, dur=0.32)]
        txt, tempo = "Course : genou avant levé, jambe arrière repliée, bras à 90°.", "≈ 170-180 pas/min"
    elif kind == "sprint":
        f1 = A(t=12, hanche_d=70, genou_d=80, cheville_d=5, hanche_g=-20, genou_g=100, cheville_g=-30, epaule_d=-40, coude_d=90, epaule_g=60, coude_g=90)
        f2 = A(t=12, hanche_d=-20, genou_d=100, cheville_d=-30, hanche_g=70, genou_g=80, cheville_g=5, epaule_d=60, coude_d=90, epaule_g=-40, coude_g=90)
        kfs = [KF("appui droit", f1, ("pied_d", (0.0, 0.0)), [], [], hold=0.0, dur=0.22), KF("appui gauche", f2, ("pied_g", (0.0, 0.0)), [], [], hold=0.0, dur=0.22)]
        txt, tempo = "Sprint : genoux hauts, talon vers la fesse, bras énergiques.", "cadence maximale"
    elif kind == "genoux_hauts":
        f1 = A(t=0, hanche_d=95, genou_d=100, cheville_d=-10, hanche_g=0, genou_g=5, cheville_g=-15, epaule_d=-30, coude_d=90, epaule_g=40, coude_g=90)
        f2 = A(t=0, hanche_g=95, genou_g=100, cheville_g=-10, hanche_d=0, genou_d=5, cheville_d=-15, epaule_g=-30, coude_g=90, epaule_d=40, coude_d=90)
        kfs = [KF("genou droit haut", f1, ("pied_g", (0.0, 0.0)), [], [], hold=0.0, dur=0.28), KF("genou gauche haut", f2, ("pied_d", (0.0, 0.0)), [], [], hold=0.0, dur=0.28)]
        txt, tempo = "Montées de genoux sur place, cuisse à l'horizontale.", "rapide"
    elif kind == "porte":
        f1 = A(t=3, hanche_d=20, genou_d=5, cheville_d=3, hanche_g=-10, genou_g=10, cheville_g=-10, epaule=3, coude=0)
        f2 = A(t=3, hanche_g=20, genou_g=5, cheville_g=3, hanche_d=-10, genou_d=10, cheville_d=-10, epaule=3, coude=0)
        kfs = [KF("pas droit", f1, on("talon_d"), [("cheville_g", -40, 20)], [("y", "pied_g", 0.0)], hold=0.0, dur=0.6),
               KF("pas gauche", f2, on("talon_g"), [("cheville_d", -40, 20)], [("y", "pied_d", 0.0)], hold=0.0, dur=0.6)]
        txt, tempo = "Marche du fermier : charges le long du corps, épaules basses, pas courts.", "pas courts et réguliers"
    elif kind == "overhead":
        f1 = A(t=0, hanche_d=20, genou_d=5, cheville_d=3, hanche_g=-10, genou_g=10, cheville_g=-10, epaule=178, coude=0)
        f2 = A(t=0, hanche_g=20, genou_g=5, cheville_g=3, hanche_d=-10, genou_d=10, cheville_d=-10, epaule=178, coude=0)
        kfs = [KF("pas droit", f1, on("talon_d"), [("cheville_g", -40, 20)], [("y", "pied_g", 0.0)], hold=0.0, dur=0.6),
               KF("pas gauche", f2, on("talon_g"), [("cheville_d", -40, 20)], [("y", "pied_d", 0.0)], hold=0.0, dur=0.6)]
        txt, tempo = "Marche charge au-dessus de la tête, bras verrouillés, côtes basses.", "pas courts"
    else:
        raise ValueError(kind)
    heel = kind in ("marche", "porte", "overhead")
    props = []
    if kind == "porte":
        props = [{"type": "kettlebell", "attach": "prise_d"}, {"type": "kettlebell", "attach": "prise_g"}]
    if kind == "overhead":
        props = [{"type": "kettlebell", "attach": "prise_d", "offset": [0.0, 0.11]}]
    sheet(id_, "profil", kfs, props, [{"joint": k["anchor"][0], "with": "sol", "kf": [i]} for i, k in enumerate(kfs)], "cycle", phases=[phase("cycle", ["hanche", "genou", "cheville"], {}, {}, txt)], moteurs=["hanche", "genou", "cheville"],
          contacts_texte="appuis alternés", tempo=tempo, sources=SRC["transpose"], debout=True, charge=("kettlebells" if kind in ("porte", "overhead") else None), origine_fixe=True)


for k in ("marche", "course", "sprint", "porte", "overhead"):
    gait(f"locomotion.{k}", k)
gait("cardio.genoux_hauts", "genoux_hauts")


def jump(id_, kind="vertical"):
    crouch = A(t=30, hanche=80, genou=80, cheville=22, epaule=-40, coude=10)
    if kind == "vertical":
        air = A(t=0, hanche=5, genou=5, cheville=-35, epaule=170, coude=5)
        land = A(t=25, hanche=60, genou=60, cheville=18, epaule=20, coude=10)
        air_anchor = ("pied_d", (0.0, 0.30))
    elif kind == "box":
        air = A(t=10, hanche=90, genou=90, cheville=-10, epaule=60, coude=20)
        land = A(t=15, hanche=70, genou=70, cheville=15, epaule=30, coude=10)
        air_anchor = ("pied_d", (0.45, BOX_Y + 0.10))
    elif kind == "longueur":
        air = A(t=20, hanche=60, genou=40, cheville=-20, epaule=120, coude=10)
        land = A(t=30, hanche=90, genou=90, cheville=20, epaule=40, coude=10)
        air_anchor = ("pied_d", (0.55, 0.28))
    else:  # tuck
        air = A(t=15, hanche=120, genou=130, cheville=-20, epaule=80, coude=90)
        land = A(t=25, hanche=60, genou=60, cheville=18, epaule=20, coude=10)
        air_anchor = ("pied_d", (0.0, 0.32))
    kfs = [KF("contre-mouvement", crouch, on("talon_d"), [("t", 15, 45), ("cheville", 0, 38)], [BALANCE, FLAT_FOOT_D], hold=0.1, dur=0.3),
           KF("envol", air, air_anchor, [("t", -10, 30)], [("com_x", "pied_d", -0.05)], hold=0.0, dur=0.35)]
    props = []
    if kind == "box":
        kfs.append(KF("réception sur la box", land, ("talon_d", (0.55, BOX_Y)), [("t", 0, 30), ("cheville", 0, 38)], [BALANCE, FLAT_FOOT_D], hold=0.3, dur=0.5))
        props = [{"type": "box", "x": 0.35, "y": 0.0, "w": 0.45, "h": BOX_Y, "static": True}]
    else:
        lx = 0.0 if kind in ("vertical", "tuck") else 0.7
        kfs.append(KF("réception", land, ("talon_d", (lx, 0.0)), [("t", 0, 40), ("cheville", 0, 38)], [BALANCE, FLAT_FOOT_D], hold=0.3, dur=0.5))
    cont = [{"joint": "talon_d", "with": "sol", "kf": [0]}, {"joint": "pied_d", "with": "sol", "kf": [0]}, {"joint": "talon_g", "with": "sol", "kf": [0]}, {"joint": "pied_g", "with": "sol", "kf": [0]}]
    sheet(id_, "profil", kfs, props, cont, "cycle", phases=[phase("impulsion", ["hanche", "genou", "cheville"], {"genou": 80}, {"genou": 5}, "Contre-mouvement puis extension explosive des hanches, genoux et chevilles ; réception amortie genoux fléchis.")],
          moteurs=["hanche", "genou", "cheville"], contacts_texte="pieds au sol au départ et à la réception", tempo="explosif", sources=SRC["cmj"], debout=True, note=kind, origine_fixe=True,
          rom_exceptions={"cheville": (-60, 45)})


for k in ("vertical", "box", "longueur", "tuck"):
    jump(f"saut.{k}", k)


def burpee(id_):
    stand = A(t=0, epaule=5, coude=0)
    crouch = A(t=70, hanche=125, genou=128, cheville=30, epaule=110, coude=10, poignet=0, n=-10)
    plank = A(t=65, n=20, hanche=0, genou=0, cheville=-35, epaule=88, coude=0, poignet=0)
    jumpa = A(t=0, hanche=5, genou=5, cheville=-35, epaule=170, coude=5)
    kfs = [KF("debout", stand, on("talon_d"), [("t", -8, 8)], [BALANCE, FLAT_FOOT_D], hold=0.1, dur=0.4),
           KF("accroupi, mains au sol", crouch, on("pied_d"), [("t", 40, 85), ("epaule", 60, 140), ("coude", 0, 40), ("poignet", -88, 88), ("genou", 90, 145), ("cheville", -40, 38)], [("y", "prise_d", 0.0), ("x", "prise_d", 0.30), HAND_FLAT_D, ("min_y", 0.0)], hold=0.0, dur=0.4, equilibre=False),
           KF("planche", plank, ("prise_d", (0.30, 0.0)), [("t", 40, 100), ("poignet", -88, 88), ("cheville", -58, 15), ("epaule", 40, 110)], [("y", "pied_d", 0.0), HAND_FLAT_D, ("abs", "ua_d", 0)], hold=0.1, dur=0.4),
           KF("retour accroupi", crouch, on("pied_d"), [("t", 40, 85), ("epaule", 60, 140), ("coude", 0, 40), ("poignet", -88, 88), ("genou", 90, 145), ("cheville", -40, 38)], [("y", "prise_d", 0.0), ("x", "prise_d", 0.30), HAND_FLAT_D, ("min_y", 0.0)], hold=0.0, dur=0.4, equilibre=False),
           KF("saut", jumpa, ("pied_d", (0.0, 0.22)), [("t", -8, 8)], [("com_x", "pied_d", -0.05)], hold=0.0, dur=0.5)]
    sheet(id_, "profil", kfs, [], [{"joint": "talon_d", "with": "sol", "kf": [0]}, {"joint": "pied_d", "with": "sol", "kf": [0, 1, 2, 3]}, {"joint": "prise_d", "with": "sol", "kf": [1, 2, 3]}], "cycle", phases=[phase("séquence", ["hanche", "genou", "epaule", "coude"], {}, {}, "Accroupi mains au sol, jambes lancées en planche, retour accroupi, saut bras levés.")],
          moteurs=["hanche", "genou", "epaule"], contacts_texte="pieds puis mains au sol", tempo="≈ 3 s par cycle", sources=SRC["burpee"], debout=True, note="burpee", origine_fixe=True)


burpee("cardio.burpee")


def jacks(id_):
    closed = A(t=0, epaule=10, coude=5, hanche=3)
    opened = A(t=0, epaule=165, coude=10, hanche=25)
    kfs = [KF("pieds joints", closed, ("pied_d", (-0.09, 0.0)), [], [], hold=0.0, dur=0.3), KF("pieds écartés, bras levés", opened, ("pied_d", (-0.25, 0.0)), [], [], hold=0.0, dur=0.3)]
    sheet(id_, "face", kfs, [], [{"joint": "pied_d", "with": "sol"}, {"joint": "pied_g", "with": "sol"}], "aller-retour", phases=[phase("cycle", ["hanche (abduction)", "epaule (abduction)"], {}, {}, "Saut avec écartement des jambes et élévation des bras, puis retour.")],
          moteurs=["hanche", "epaule"], contacts_texte="pieds au sol", tempo="rapide", sources=SRC["transpose"], debout=True, note="jumping jacks", rom_exceptions={"hanche_abd": (-30, 100)})


jacks("cardio.jacks")


def rope(id_, kind="saut"):
    if kind == "saut":
        low = A(t=0, hanche=3, genou=10, cheville=5, epaule=15, coude=90)
        air = A(t=0, hanche=3, genou=5, cheville=-30, epaule=15, coude=90)
        kfs = [KF("appui", low, on("talon_d"), [("t", -5, 5)], [BALANCE, FLAT_FOOT_D], hold=0.0, dur=0.2), KF("envol", air, ("pied_d", (0.0, 0.06)), [], [], hold=0.0, dur=0.25)]
        props = [{"type": "corde_a_sauter", "between": ["prise_g", "prise_d"]}]
        txt = "Petits sauts sur l'avant du pied, coudes près du corps, la corde tourne aux poignets."
    else:
        low = A(t=15, hanche=40, genou=40, cheville=15, epaule=30, coude=60)
        high = A(t=15, hanche=40, genou=40, cheville=15, epaule=80, coude=60)
        kfs = [KF("bas", low, on("talon_d"), [("t", 0, 30)], [BALANCE, FLAT_FOOT_D], hold=0.0, dur=0.25), KF("haut", high, on("talon_d"), [("t", 0, 30)], [BALANCE, FLAT_FOOT_D], hold=0.0, dur=0.25)]
        props = [{"type": "battle_rope", "x": 0.9, "y": 0.02, "to": ["prise_d", "prise_g"], "static": True}]
        txt = "Position de demi-squat, ondulations alternées ou simultanées des cordes."
    sheet(id_, "profil", kfs, props, [{"joint": "talon_d", "with": "sol", "kf": [0]}, {"joint": "pied_d", "with": "sol", "kf": [0]}] if kind == "saut" else FEET_BOTH, "cycle" if kind == "saut" else "aller-retour", phases=[phase("cycle", ["cheville", "epaule"], {}, {}, txt)],
          moteurs=["cheville", "epaule"], contacts_texte="pieds au sol", tempo="rapide", sources=SRC["transpose"], debout=True, note=kind)


rope("corde.saut")
rope("corde.battle", "battle")


def ergo(id_, kind="rameur"):
    if kind == "rameur":
        catch = A(t=25, n=-10, hanche=120, genou=125, cheville=25, epaule=85, coude=5)
        finish = A(t=-15, n=5, hanche=75, genou=10, cheville=-15, epaule=-10, coude=110)
        kfs = [KF("attaque", catch, ("bassin", (-0.05, 0.13 + B.contact_offset("bassin"))), [], [], hold=0.0, dur=0.8),
               KF("fin de coup", finish, ("bassin", (-0.55, 0.13 + B.contact_offset("bassin"))), [], [], hold=0.1, dur=0.9)]
        props = [{"type": "rameur", "x": 0.0, "static": True}]
        txt = "Jambes puis dos puis bras ; retour dans l'ordre inverse."
    elif kind == "velo":
        p1 = A(t=25, n=-15, hanche_d=55, genou_d=40, cheville_d=5, hanche_g=100, genou_g=110, cheville_g=-5, epaule=60, coude=20)
        p2 = A(t=25, n=-15, hanche_g=55, genou_g=40, cheville_g=5, hanche_d=100, genou_d=110, cheville_d=-5, epaule=60, coude=20)
        kfs = [KF("pédale droite basse", p1, ("bassin", (0.0, 0.55 + B.contact_offset("bassin"))), [], [], hold=0.0, dur=0.5),
               KF("pédale gauche basse", p2, ("bassin", (0.0, 0.55 + B.contact_offset("bassin"))), [], [], hold=0.0, dur=0.5)]
        props = [{"type": "velo", "x": 0.0, "static": True}]
        txt = "Pédalage régulier, selle à hauteur de hanche."
    else:  # skierg
        top = A(t=5, hanche=10, genou=10, cheville=5, epaule=170, coude=20)
        bot = A(t=45, hanche=80, genou=40, cheville=15, epaule=-20, coude=40)
        kfs = [KF("bras hauts", top, on("talon_d"), [("t", -5, 15)], [BALANCE, FLAT_FOOT_D], hold=0.0, dur=0.5),
               KF("tirage bas", bot, on("talon_d"), [("t", 30, 60), ("cheville", 0, 38)], [BALANCE, FLAT_FOOT_D], hold=0.0, dur=0.6)]
        props = [{"type": "poulie", "x": 0.45, "y": 1.45, "to": ["prise_d"], "static": True}]
        txt = "Tirage des poignées du haut vers le bas avec flexion des hanches, retour bras hauts."
    sheet(id_, "profil", kfs, props, [], "aller-retour" if kind != "velo" else "cycle", phases=[phase("cycle", ["hanche", "genou", "epaule", "coude"], {}, {}, txt)],
          moteurs=["hanche", "genou", "epaule"], tempo="régulier", sources=SRC["transpose"], debout=(kind == "skierg"), note=kind, rom_exceptions={"epaule": (-70, 195)})


for k in ("rameur", "velo", "skierg"):
    ergo(f"ergo.{k}", k)


def sled(id_, kind="push"):
    if kind == "push":
        f1 = A(t=50, hanche_d=70, genou_d=40, cheville_d=25, hanche_g=-10, genou_g=20, cheville_g=-30, epaule=80, coude=10)
        f2 = A(t=50, hanche_g=70, genou_g=40, cheville_g=25, hanche_d=-10, genou_d=20, cheville_d=-30, epaule=80, coude=10)
        kfs = [KF("poussée droite", f1, ("pied_d", (0.0, 0.0)), [], [], hold=0.0, dur=0.5), KF("poussée gauche", f2, ("pied_g", (0.0, 0.0)), [], [], hold=0.0, dur=0.5)]
        props = [{"type": "traineau", "x": 0.75, "static": True}]
        txt = "Corps incliné, bras tendus sur les montants, poussée alternée des jambes."
    else:
        f1 = A(t=-15, hanche_d=40, genou_d=30, cheville_d=15, hanche_g=-5, genou_g=15, cheville_g=-15, epaule=-10, coude=0)
        f2 = A(t=-15, hanche_g=40, genou_g=30, cheville_g=15, hanche_d=-5, genou_d=15, cheville_d=-15, epaule=-10, coude=0)
        kfs = [KF("pas droit", f1, on("talon_d"), [("hanche_g", -30, 30), ("genou_g", 0, 60), ("cheville_g", -40, 30), ("cheville_d", -10, 38)], [("y", "pied_g", 0.0), FLAT_FOOT_D], hold=0.0, dur=0.6),
               KF("pas gauche", f2, on("talon_g"), [("hanche_d", -30, 30), ("genou_d", 0, 60), ("cheville_d", -40, 30), ("cheville_g", -10, 38)], [("y", "pied_d", 0.0), FLAT_FOOT_G], hold=0.0, dur=0.6)]
        props = [{"type": "traineau", "x": -0.9, "to": ["prise_d"], "static": True}]
        txt = "Marche arrière ou avant en tirant le traîneau par les sangles, buste incliné."
    sheet(id_, "profil", kfs, props, [{"joint": k["anchor"][0], "with": "sol", "kf": [i]} for i, k in enumerate(kfs)], "cycle", phases=[phase("cycle", ["hanche", "genou", "cheville"], {}, {}, txt)], moteurs=["hanche", "genou"], tempo="régulier",
          sources=SRC["transpose"], debout=(kind == "push"), note=f"traîneau {kind}", origine_fixe=True)


sled("traineau.push")
sled("traineau.pull", "pull")


def quadruped(id_, kind="bear_crawl"):
    if kind == "bear_crawl":
        f1 = A(t=70, n=-15, hanche_d=100, genou_d=110, cheville_d=-20, hanche_g=70, genou_g=80, cheville_g=-30, epaule_d=60, coude_d=0, epaule_g=100, coude_g=0)
        f2 = A(t=70, n=-15, hanche_g=100, genou_g=110, cheville_g=-20, hanche_d=70, genou_d=80, cheville_d=-30, epaule_g=60, coude_g=0, epaule_d=100, coude_d=0)
        kfs = [KF("pas 1", f1, ("prise_d", (0.0, 0.0)), [("t", 50, 90), ("poignet", -88, 88)], [("y", "pied_d", 0.0), HAND_FLAT_D], hold=0.0, dur=0.5),
               KF("pas 2", f2, ("prise_g", (0.0, 0.0)), [("t", 50, 90), ("poignet", -88, 88)], [("y", "pied_g", 0.0), HAND_FLAT_G], hold=0.0, dur=0.5)]
        txt = "Quadrupédie genoux décollés, main et pied opposés avancent ensemble."
    elif kind == "mountain":
        f1 = A(t=65, n=15, hanche_d=110, genou_d=120, cheville_d=-20, hanche_g=0, genou_g=0, cheville_g=-35, epaule=85, coude=0)
        f2 = A(t=65, n=15, hanche_g=110, genou_g=120, cheville_g=-20, hanche_d=0, genou_d=0, cheville_d=-35, epaule=85, coude=0)
        kfs = [KF("genou droit", f1, ("prise_d", (0.0, 0.0)), [("t", 40, 95), ("poignet", -88, 88), ("cheville_g", -58, 15), ("cheville_d", -58, 38), ("genou_d", 60, 140)], [("y", "pied_g", 0.0), HAND_FLAT_D, ("abs", "ua_d", 0), ("min_y", 0.0)], hold=0.0, dur=0.3),
               KF("genou gauche", f2, ("prise_d", (0.0, 0.0)), [("t", 40, 95), ("poignet", -88, 88), ("cheville_d", -58, 15), ("cheville_g", -58, 38), ("genou_g", 60, 140)], [("y", "pied_d", 0.0), HAND_FLAT_D, ("abs", "ua_d", 0), ("min_y", 0.0)], hold=0.0, dur=0.3)]
        txt = "Position de planche bras tendus, genoux ramenés alternativement vers la poitrine."
    else:  # crab
        f1 = A(t=-30, n=10, hanche_d=90, genou_d=90, cheville_d=5, hanche_g=70, genou_g=100, cheville_g=-10, epaule=-45, coude=0, poignet=-40)
        f2 = A(t=-30, n=10, hanche_g=90, genou_g=90, cheville_g=5, hanche_d=70, genou_d=100, cheville_d=-10, epaule=-45, coude=0, poignet=-40)
        kfs = [KF("pas 1", f1, ("prise_d", (0.0, 0.0)), [("t", -50, -10), ("poignet", -88, 88), ("genou", 40, 130), ("cheville", -30, 38)], [("y", "talon_d", 0.0), FLAT_FOOT_D, HAND_FLAT_D, ("min_y", 0.0)], hold=0.0, dur=0.5),
               KF("pas 2", f2, ("prise_d", (0.0, 0.0)), [("t", -50, -10), ("poignet", -88, 88), ("genou", 40, 130), ("cheville", -30, 38)], [("y", "talon_g", 0.0), FLAT_FOOT_G, HAND_FLAT_D, ("min_y", 0.0)], hold=0.0, dur=0.5)]
        txt = "Assis mains derrière, bassin décollé, déplacement en crabe."
    sheet(id_, "profil", kfs, [], [{"joint": "prise_d", "with": "sol"}], "cycle", phases=[phase("cycle", ["hanche", "epaule"], {}, {}, txt)], moteurs=["hanche", "epaule", "tronc"],
          contacts_texte="mains et pieds au sol", tempo="régulier", sources=SRC["transpose"], note=kind, rom_exceptions={"poignet": (-95, 95), "epaule": (-90, 195)})


for k in ("bear_crawl", "mountain", "crab"):
    quadruped(f"quadrupedie.{k}", k)


# ================================================================ DIVERS AU SOL ET DEBOUT
sheet("sol.foam", "profil",
      [KF("rouleau sous la cuisse", A(t=-70, n=20, hanche_d=30, genou_d=0, hanche_g=60, genou_g=90, cheville=0, epaule=-60, coude=0, poignet=-50), ("prise_d", (-0.35, 0.0)), [("t", -85, -50), ("poignet", -88, 88)], [HAND_FLAT_D, ("y", "genou_d", 0.10)], hold=1.0, dur=1.0),
       KF("rouleau sous le mollet", A(t=-70, n=20, hanche_d=40, genou_d=0, hanche_g=60, genou_g=90, cheville=0, epaule=-60, coude=0, poignet=-50), ("prise_d", (-0.35, 0.0)), [("t", -85, -50), ("poignet", -88, 88)], [HAND_FLAT_D, ("y", "cheville_d", 0.13)], hold=1.0, dur=1.0)],
      [{"type": "rouleau", "attach": "genou_d", "offset": [0.0, -0.05]}], [{"joint": "prise_d", "with": "sol"}], "aller-retour",
      phases=[phase("roulement", ["hanche"], {}, {}, "Assis, mains derrière, le rouleau glisse lentement le long de l'arrière de la cuisse et du mollet.")],
      moteurs=["hanche"], tempo="lent", sources=SRC["transpose"], rom_exceptions={"poignet": (-95, 95), "epaule": (-90, 195)}, note="rouleau de massage")
sheet("face.windmill", "profil",
      [KF("debout", A(t=0, epaule_d=178, coude_d=0, epaule_g=5, coude_g=0), on("talon_d"), [("t", -8, 8)], [BALANCE, FLAT_FOOT_D], hold=0.3, dur=1.4),
       KF("inclinaison", A(t=70, hanche=85, genou=10, cheville=5, epaule_d=178, coude_d=0, epaule_g=60, coude_g=0), on("talon_d"), [("t", 50, 90), ("cheville", -10, 30)], [BALANCE, FLAT_FOOT_D], hold=0.3, dur=1.4)],
      [{"type": "kettlebell", "attach": "prise_d", "offset": [0.0, 0.11]}], FEET_BOTH, "aller-retour",
      phases=[phase("inclinaison", ["hanche", "tronc"], {}, {}, "Kettlebell bras tendu au-dessus de la tête, hanches poussées de côté, l'autre main descend le long de la jambe (représenté de profil).")],
      moteurs=["hanche", "tronc"], tempo="lent", sources=SRC["transpose"], debout=True, charge="kettlebell", rom_exceptions={"hanche": (-30, 150)}, note="windmill")
sheet("face.inclinaison", "face",
      [KF("droit", A(t=0, epaule_d=5, coude_d=0, epaule_g=5, coude_g=0), ("pied_d", (-0.09, 0.0)), [], [], hold=0.2, dur=1.0),
       KF("incliné", A(t=25, p=0, epaule_d=5, coude_d=0, epaule_g=5, coude_g=0), ("pied_d", (-0.09, 0.0)), [], [], hold=0.3, dur=1.0)],
      [{"type": "halteres", "attach": "prise_d"}], [{"joint": "pied_d", "with": "sol"}, {"joint": "pied_g", "with": "sol"}], "aller-retour", phases=[phase("inclinaison", ["tronc (flexion latérale)"], {"tronc": 0}, {"tronc": 25}, "Inclinaison latérale du buste, haltère le long de la jambe.")],
      moteurs=["tronc"], tempo="2 s / 2 s", sources=SRC["transpose"], debout=True, charge="haltère", note="side bend")
sheet("suspension.windshield.barre_fixe", "profil",
      [KF("jambes à la verticale", A(t=-30, n=20, hanche=150, genou=5, cheville=-40, epaule=150, coude=0), ("prise_d", (0.0, BAR_Y)), [("t", -45, 0)], [("com_x", "prise_d", 0.0)], hold=0.3, dur=0.8),
       KF("bascule latérale", A(t=-20, n=20, hanche=130, genou=5, cheville=-40, epaule=160, coude=0), ("prise_d", (0.0, BAR_Y)), [("t", -45, 0)], [("com_x", "prise_d", 0.0)], hold=0.3, dur=0.8)],
      [{"type": "barre_fixe", "x": 0.0, "y": BAR_Y, "static": True}], HANDS_BAR, "aller-retour",
      phases=[phase("bascule", ["tronc (rotation)", "hanche"], {}, {}, "Jambes tendues à la verticale sous la barre, bascule d'un côté à l'autre (rotation représentée par une variation de flexion de profil).")],
      moteurs=["tronc", "hanche"], tempo="lent", sources=SRC["lsit"], rom_exceptions={"hanche": (-30, 160), "epaule": (-70, 195)}, note="essuie-glaces")


def calf(id_, one_leg=False):
    low = A(cheville=10, hanche_g=(10 if one_leg else 0), genou_g=(60 if one_leg else 0), cheville_g=(-20 if one_leg else 10))
    high = A(cheville=-38, hanche_g=(10 if one_leg else 0), genou_g=(60 if one_leg else 0), cheville_g=(-20 if one_leg else -38))
    anchor = ("pied_d", (0.0, 0.08))
    kfs = [KF("talons bas", low, anchor, [("t", -5, 8)], [("com_x", "pied_d", -0.02)], hold=0.3, dur=1.0), KF("sur la pointe", high, anchor, [("t", -5, 8)], [("com_x", "pied_d", -0.02)], hold=0.5, dur=1.0)]
    sheet(id_, "profil", kfs, [{"type": "marche", "x": -0.07, "y": 0.0, "w": 0.35, "h": 0.08, "static": True}], [{"joint": "pied_d", "with": "marche"}],
          phases=[phase("montée", ["cheville"], {"cheville": 10}, {"cheville": -38}, "Avant du pied sur une marche, talons descendus puis montée complète sur la pointe."), phase("descente", ["cheville"], {}, {})],
          moteurs=["cheville"], placement="avant des pieds sur le bord d'une marche", contacts_texte="avant-pied sur la marche", tempo="1 s montée, 2 s descente", sources=SRC["transpose"], debout=True, note="mollets" + (" une jambe" if one_leg else ""))


calf("mollets.debout")
calf("mollets.unijambe", one_leg=True)

# copenhague : planche latérale, jambe du dessus sur un banc
REG.pop("planche_laterale.copenhague", None)
sheet("planche_laterale.copenhague", "face",
      [KF("tenue", A(t=-88, n=10, p=-88, hanche_g=0, genou_g=0, hanche_d=-15, genou_d=0, epaule_d=92, coude_d=90, epaule_g=20, coude_g=90), ("coude_d", (0.0, 0.03)), [("t", -92, -80), ("p", -92, -80)], [("y", "pied_g", 0.30)], hold=2.0, dur=0.6)],
      [{"type": "box", "x": 0.55, "y": 0.0, "w": 0.4, "h": 0.30, "static": True, "layer": "arriere"}], [{"joint": "coude_d", "with": "sol"}, {"joint": "pied_g", "with": "box"}], "aller-retour",
      phases=[phase("tenue", ["adducteurs", "tronc (anti-flexion latérale)"], {}, {}, "Coude au sol, jambe du dessus posée sur le banc, bassin haut, jambe du dessous libre.")],
      moteurs=["hanche (adduction)", "tronc"], placement="coude sous l'épaule, pied ou genou du dessus sur le banc", contacts_texte="avant-bras au sol, jambe du dessus sur le banc", tempo="tenue 10-30 s",
      sources=SRC["plank"], rom_exceptions={"epaule_abd": (-10, 190), "hanche_abd": (-40, 100)}, note="planche de Copenhague")


# ================================================================ compléments L9R (gabarits manquants en v1)
sheet("mollets.tibial", "profil",
      [KF("pointes au sol", A(t=-8, hanche=5, genou=5, cheville=0, epaule=-10, coude=0), on("talon_d"), [("t", -15, 0)], [FLAT_FOOT_D], hold=0.2, dur=0.8),
       KF("pointes relevées", A(t=-8, hanche=5, genou=5, cheville=28, epaule=-10, coude=0), on("talon_d"), [("t", -15, 0)], [], hold=0.4, dur=0.8)],
      [{"type": "mur", "x": -0.2, "static": True}], [{"joint": "talon_d", "with": "sol"}], "aller-retour",
      phases=[phase("relevé", ["cheville (flexion dorsale)"], {"cheville": 0}, {"cheville": 28}, "Dos au mur, talons au sol, les pointes se relèvent le plus haut possible.")],
      moteurs=["cheville"], placement="dos et fessiers contre le mur, pieds à un pas", contacts_texte="talons au sol, dos au mur", tempo="1 s / 2 s", sources=SRC["rom"], debout=False, note="tibialis raises")

sheet("sol.inchworm", "profil",
      [KF("flexion avant", A(t=95, n=20, hanche=115, genou=10, cheville=10, epaule=100, coude=0, poignet=60), on("talon_d"), [("t", 70, 120), ("epaule", 60, 140), ("poignet", -88, 88), ("cheville", -10, 38), ("genou", 5, 45), ("hanche", 90, 130)], [("y", "prise_d", 0.0), HAND_FLAT_D, FLAT_FOOT_D], hold=0.2, dur=1.2),
       KF("planche bras tendus", A(t=65, n=20, hanche=0, genou=0, cheville=-35, epaule=88, coude=0, poignet=80), ("prise_d", (0.55, 0.0)), [("t", 40, 100), ("epaule", 40, 110), ("poignet", -88, 88), ("cheville", -58, 15)], [("y", "pied_d", 0.0), HAND_FLAT_D, ("abs", "ua_d", 0)], hold=0.3, dur=1.4)],
      [], [{"joint": "prise_d", "with": "sol"}, {"joint": "pied_d", "with": "sol"}], "aller-retour",
      phases=[phase("marche des mains", ["epaule", "hanche"], {}, {}, "Depuis la flexion avant, les mains avancent jusqu'à la planche puis reviennent (ou les pieds rejoignent les mains).")],
      moteurs=["epaule", "hanche", "tronc"], contacts_texte="mains et pieds au sol", tempo="lent", sources=SRC["plank"], rom_exceptions={"hanche": (-30, 150)}, note="inchworm", origine_fixe=True)

sheet("assis.leg_press", "profil",
      [KF("genoux fléchis", A(t=-40, n=0, hanche=110, genou=105, cheville=15, epaule=-20, coude=90), ("bassin", (0.0, 0.35)), [], [], hold=0.2, dur=1.0),
       KF("jambes tendues", A(t=-40, n=0, hanche=65, genou=10, cheville=5, epaule=-20, coude=90), ("bassin", (0.0, 0.35)), [], [], hold=0.2, dur=1.0)],
      [{"type": "banc_incline", "x": -0.35, "static": True, "layer": "arriere"}, {"type": "machine", "x": 0.75, "y": 0.6, "static": True}], [{"joint": "bassin", "with": "siège"}], "aller-retour",
      phases=[phase("poussée", ["genou", "hanche"], {"genou": 105}, {"genou": 10}, "Dos plaqué au dossier, les pieds poussent la plateforme sans verrouiller brutalement les genoux.")],
      moteurs=["genou", "hanche"], placement="assis incliné, pieds largeur d'épaules sur la plateforme", contacts_texte="dos sur le dossier, pieds sur la plateforme", tempo="2 s / 1 s",
      sources=SRC["squat"], rom_exceptions={"hanche": (-30, 150)}, note="presse à cuisses (la plateforme est figurée par le montant)")

sheet("squat.sissy", "profil",
      [KF("debout", A(t=0, hanche=0, genou=5, cheville=0, epaule=60, coude=0), on("pied_d", 0.0, 0.0), [("t", -10, 5)], [("com_x", "pied_d", -0.02)], hold=0.3, dur=1.2),
       KF("genoux avancés, buste en arrière", A(t=-30, hanche=8, genou=110, cheville=-40, epaule=60, coude=0), on("pied_d", 0.0, 0.0), [("t", -45, -10), ("cheville", -58, -20)], [("com_x", "pied_d", -0.02)], hold=0.2, dur=1.2)],
      [{"type": "poteau", "x": 0.45, "static": True}], [{"joint": "pied_d", "with": "sol"}], "aller-retour",
      phases=[phase("descente", ["genou"], {"genou": 5}, {"genou": 110}, "Hanches ouvertes, les genoux avancent et le buste s'incline en arrière sur les pointes de pieds ; une main tient un support.")],
      moteurs=["genou"], placement="talons levés, une main sur un support", contacts_texte="avant-pieds au sol", tempo="2 s / 2 s", sources=SRC["squat"], debout=False, note="sissy squat")

sheet("banc.hyperextension", "profil",
      [KF("buste bas", A(t=150, n=-20, hanche=100, genou=5, cheville=-20, epaule=90, coude=90), ("bassin", (0.0, 0.62)), [], [], hold=0.2, dur=1.0),
       KF("buste aligné", A(t=48, n=-10, hanche=0, genou=5, cheville=-20, epaule=90, coude=90), ("bassin", (0.0, 0.62)), [], [], hold=0.4, dur=1.0)],
      [{"type": "banc_incline", "x": -0.55, "static": True, "layer": "arriere"}], [{"joint": "bassin", "with": "banc"}], "aller-retour",
      phases=[phase("extension", ["hanche", "rachis"], {"hanche": 100}, {"hanche": 0}, "Bassin sur le coussin, chevilles calées ; le buste remonte jusqu'à l'alignement avec les jambes, sans hyper-extension.")],
      moteurs=["hanche"], placement="banc à 45°, coussin sous les hanches", contacts_texte="cuisses sur le coussin, chevilles calées", tempo="2 s / 1 s", sources=SRC["hinge"],
      rom_exceptions={"hanche": (-30, 150), "cou": (-60, 80)}, note="extensions lombaires sur banc à 45° (le banc est schématisé)")

sheet("planche_gainage.body_saw", "profil",
      [KF("coudes sous les épaules", A(t=80, n=15, hanche=0, genou=0, cheville=-30, epaule=80, coude=90), ("coude_d", (0.0, 0.03)), [("t", 60, 95), ("cheville", -58, 38), ("epaule", 60, 100)], [("y", "pied_d", 0.0), ("abs", "fa_d", 90)], hold=0.2, dur=1.2),
       KF("corps reculé", A(t=80, n=15, hanche=0, genou=0, cheville=-45, epaule=115, coude=90), ("coude_d", (0.0, 0.03)), [("t", 60, 95), ("cheville", -58, 38), ("epaule", 100, 135)], [("y", "pied_d", 0.0), ("abs", "fa_d", 90)], hold=0.2, dur=1.2)],
      [], [{"joint": "coude_d", "with": "sol"}, {"joint": "pied_d", "with": "sol"}], "aller-retour",
      phases=[phase("va-et-vient", ["epaule", "tronc (anti-extension)"], {"epaule": 80}, {"epaule": 115}, "En planche sur les coudes, le corps recule d'un bloc (pieds sur serviette ou disques glissants) puis revient.")],
      moteurs=["epaule", "tronc"], contacts_texte="avant-bras au sol, pieds glissants", tempo="2 s / 2 s", sources=SRC["plank"], note="body saw")


# planche latérale étoile (bras et jambe du dessus levés) et pieds surélevés — vue de face comme la planche latérale standard
sheet("planche_laterale.etoile", "face",
      [KF("tenue", A(t=-82, n=10, p=-82, hanche_d=0, genou_d=0, hanche_g=45, genou_g=0, epaule_d=92, coude_d=90, epaule_g=95, coude_g=0), ("coude_d", (0.0, 0.03)), [("t", -89, -70), ("p", -89, -70)], [("y", "pied_d", 0.0)], hold=2.0, dur=0.6)],
      [], [{"joint": "coude_d", "with": "sol"}, {"joint": "pied_d", "with": "sol"}], "aller-retour",
      phases=[phase("tenue", ["hanche (anti-flexion latérale, abduction)"], {}, {}, "Planche latérale, bras du dessus vers le plafond et jambe du dessus levée : le corps forme une étoile.")],
      moteurs=["tronc", "hanche"], placement="coude sous l'épaule", contacts_texte="avant-bras et bord du pied du dessous au sol", tempo="tenue 10-30 s",
      sources=SRC["plank"], rom_exceptions={"epaule_abd": (-10, 190), "hanche_abd": (-40, 100)}, note="planche latérale étoile")
sheet("planche_laterale.pieds_sureleves", "face",
      [KF("tenue", A(t=-86, n=10, p=-86, hanche=0, genou=0, epaule_d=92, coude_d=90, epaule_g=90, coude_g=0), ("pied_d", (0.0, 0.22)), [("t", -95, -75), ("p", -95, -75)], [("y", "coude_d", 0.0)], hold=2.0, dur=0.6)],
      [{"type": "box", "x": -0.12, "y": 0.0, "w": 0.24, "h": 0.22, "static": True, "layer": "arriere"}], [{"joint": "coude_d", "with": "sol"}, {"joint": "pied_d", "with": "box"}], "aller-retour",
      phases=[phase("tenue", ["hanche (anti-flexion latérale)"], {}, {}, "Pieds posés sur un support (chaise, marche), coude au sol : le bras de levier augmente.")],
      moteurs=["tronc"], placement="coude sous l'épaule, pieds superposés sur le support", contacts_texte="avant-bras au sol, pieds sur le support", tempo="tenue 15-45 s",
      sources=SRC["plank"], rom_exceptions={"epaule_abd": (-10, 190)}, note="planche latérale pieds surélevés")

lsit("lsit.tuck_sol", "tuck")
REG["lsit.tuck_sol"]["images_cles"][0]["anchor"] = ("prise_d", (0.0, 0.0))
REG["lsit.tuck_sol"]["accessoires"] = []
REG["lsit.tuck_sol"]["images_cles"][0]["angles"] = A(t=-12, n=10, hanche=125, genou=75, cheville=-45, epaule=-10, coude=0, poignet=0)
REG["lsit.tuck_sol"]["images_cles"][0]["free"] = [("t", -25, 0), ("epaule", -25, 5), ("poignet", -88, 88), ("hanche", 105, 140), ("genou", 55, 100)]
REG["lsit.tuck_sol"]["images_cles"][0]["constraints"] = [("com_between", "prise_d", -0.02, 0.07), HAND_FLAT_D, ("min_y", 0.03)]
REG["lsit.tuck_sol"]["contacts"] = [{"joint": "prise_d", "with": "sol"}]
REG["lsit.tuck_sol"]["note"] = "L-sit groupé mains à plat au sol"
REG["lsit.tuck_sol"]["prise"] = "mains à plat au sol, doigts vers l'avant ou légèrement tournés"

# frog stand (crow) : mains au sol, coudes fléchis, genoux posés sur l'arrière des bras, pieds décollés
sheet("atr.frog", "profil",
      [KF("tenue", A(t=55, n=35, hanche=120, genou=130, cheville=-30, epaule=60, coude=70, poignet=20), ("prise_d", (0.0, 0.0)),
          [("t", 35, 75), ("hanche", 90, 140), ("genou", 100, 150), ("epaule", 30, 90), ("coude", 40, 110), ("poignet", -88, 88), ("cheville", -50, 20)],
          [HAND_FLAT_D, ("dist", "genou_d", "coude_d", 0.045), ("com_x", "poignet_d", 0.01), ("min_y", 0.05)], hold=2.0, dur=0.6)],
      [], [{"joint": "prise_d", "with": "sol"}], "aller-retour",
      phases=[phase("tenue", ["epaule", "coude"], {}, {}, "Accroupi, mains au sol largeur d'épaules, genoux calés sur l'arrière des bras, le poids bascule vers l'avant jusqu'à décoller les pieds.")],
      moteurs=["epaule", "coude", "poignet"], prise="mains à plat, doigts écartés", placement="regard légèrement devant les mains", contacts_texte="mains au sol, genoux sur les bras",
      tempo="tenue 5 à 30 s", sources=SRC["atr"], rom_exceptions={"cou": (-60, 80), "hanche": (-30, 150), "genou": (-5, 160)}, note="frog stand / crow")

# extension triceps au poids de corps : planche bras tendus → avant-bras au sol (coudes vers l'avant) → poussée
sheet("sol.triceps_extension", "profil",
      [KF("haut", A(t=78, n=15, hanche=0, genou=0, cheville=0, epaule=110, coude=0, poignet=20), ("prise_d", (0.0, 0.0)), [("t", 55, 95), ("cheville", -58, 38), ("poignet", -88, 88)], [("y", "pied_d", 0.0), HAND_FLAT_D], hold=0.3, dur=1.2),
       KF("bas", A(t=76, n=15, hanche=0, genou=0, cheville=14, epaule=125, coude=90, poignet=-10), ("coude_d", (-0.196, 0.014)), [("t", 55, 100), ("cheville", -58, 38), ("poignet", -88, 88), ("epaule", 60, 165), ("coude", 50, 140)], [("y", "pied_d", 0.0), ("y", "prise_d", 0.0), HAND_FLAT_D, ("abs", "fa_d", 90), ("abs", "ua_d", 35)], hold=0.2, dur=1.0)],
      [], [{"joint": "prise_d", "with": "sol"}, {"joint": "pied_d", "with": "sol"}, {"joint": "coude_d", "with": "sol", "kf": [1]}], "aller-retour",
      phases=[phase("descente", ["coude"], {"coude": 0}, {"coude": 100}, "Depuis la planche bras tendus, les coudes se plient vers l'avant jusqu'à poser les avant-bras."),
              phase("extension", ["coude"], {"coude": 100}, {"coude": 0}, "Poussée des triceps pour revenir bras tendus, corps gainé.")],
      moteurs=["coude"], prise="mains à plat, largeur d'épaules", placement="épaules légèrement en arrière des mains", contacts_texte="mains puis avant-bras au sol, pointes des pieds au sol",
      tempo="2 s / 1 s", sources=SRC["pompe"], rom_exceptions={"epaule": (-70, 195)}, note="extension triceps au poids de corps (bodyweight skull crusher)", origine_fixe=True)
