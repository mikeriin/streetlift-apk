# -*- coding: utf-8 -*-
"""Vecteurs de qualités des exercices de la base v1.1 (brique 2 du lot KM1).

Chaque exercice est un item du modèle de réponse : un vecteur de charges sur
les dix qualités latentes (somme 1), un type de réponse, une charge
tendineuse. Tout est calculé PAR RÈGLES depuis les champs de la base
(discipline, catégorie, muscles, matériel, niveau, variante_de) et les champs
que kalis_core en dérive (`calc` du catalogue : schéma, régime, unité, type de
charge, part de poids de corps, contraintes articulaires, fatigue). Aucune
valeur n'est écrite à la main exercice par exercice : une correction se fait
dans une règle.

    python3 qualites/regles.py            # régénère vecteurs_qualites_v1.json
    python3 qualites/regles.py --verifier # échoue si le fichier n'est pas à jour
"""
import gzip
import json
import os
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
CATALOGUE = os.path.join(ICI, '..', '..', '..', 'kalis_core', 'data', 'catalog_v1.json.gz')
SORTIE = os.path.join(ICI, 'vecteurs_qualites_v1.json')

QUALITES = ['pousser', 'tirer', 'jambes', 'tronc', 'figures', 'endurance_force',
            'explosivite', 'aerobie', 'anaerobie', 'mobilite']
Q = {q: i for i, q in enumerate(QUALITES)}

# R1 — Muscle -> qualité de force (les quatre premières qualités).
MUSCLE = {}
for m in ['grand pectoral (faisceau claviculaire)', 'grand pectoral (faisceau sternal)',
          'grand pectoral (faisceau abdominal)', 'petit pectoral', 'deltoïde antérieur',
          'deltoïde moyen', 'dentelé antérieur', 'coraco-brachial',
          'triceps brachial (chef long)', 'triceps brachial (chefs latéral et médial)', 'anconé']:
    MUSCLE[m] = 'pousser'
for m in ['deltoïde postérieur', 'coiffe des rotateurs', 'grand dorsal', 'grand rond',
          'trapèze supérieur', 'trapèze moyen', 'trapèze inférieur', 'rhomboïdes',
          'élévateur de la scapula', 'biceps brachial', 'brachial', 'brachio-radial',
          'fléchisseurs du poignet', 'extenseurs du poignet', 'fléchisseurs des doigts',
          "pronateurs de l'avant-bras", 'supinateur', 'muscles intrinsèques de la main']:
    MUSCLE[m] = 'tirer'
for m in ['grand fessier', 'moyen fessier', 'petit fessier', 'tenseur du fascia lata',
          'rotateurs externes de hanche', 'adducteurs', 'sartorius', 'quadriceps (droit fémoral)',
          'quadriceps (vastes)', 'ischio-jambiers', 'gastrocnémiens', 'soléaire',
          'tibial antérieur', 'fibulaires', 'muscles intrinsèques du pied']:
    MUSCLE[m] = 'jambes'
for m in ['érecteurs du rachis', 'multifides', 'carré des lombes', "grand droit de l'abdomen",
          'obliques externes', 'obliques internes', "transverse de l'abdomen", 'diaphragme',
          'psoas-iliaque', 'sterno-cléido-mastoïdien', 'fléchisseurs profonds du cou',
          'extenseurs du cou']:
    MUSCLE[m] = 'tronc'

# R1-a (relecture indépendante, C.1) — Dans un tirage, depuis une épaule
# fléchie, le grand pectoral sterno-costal, le petit pectoral et le chef long
# du triceps sont extenseurs/adducteurs de l'épaule ou abaisseurs de la
# scapula, en synergie avec le grand dorsal : ils comptent pour « tirer ».
SCHEMAS_TIRAGE = ('tirage_vertical', 'tirage_horizontal', 'isolation_dos', 'preparation_scapulaire')
EXTENSEURS_EN_TIRAGE = ('grand pectoral (faisceau sternal)', 'grand pectoral (faisceau abdominal)',
                        'petit pectoral', 'triceps brachial (chef long)')
# R1-b — Là où la prise et le dos limitent la charge (charnière, porté,
# haltérophilie, balistique), les stabilisateurs de type « tirer » comptent
# pour 0,25.
SCHEMAS_STABILISATEURS = ('charniere_hanche', 'porte', 'halterophilie', 'balistique')
POIDS_STABILISATEUR = 0.25

# R2 — Schéma de mouvement -> parts fixes ; le reste (« force ») est réparti
# selon les muscles (principaux 1, secondaires 0,5).
FORCE = {}
for s in ['poussee_horizontale', 'poussee_inclinee', 'poussee_verticale_haute',
          'poussee_verticale_basse', 'tirage_vertical', 'tirage_horizontal',
          'isolation_pectoraux', 'isolation_dos', 'isolation_epaules', 'isolation_trapezes',
          'isolation_biceps', 'isolation_triceps', 'prehension', 'preparation_scapulaire',
          'squat', 'fente', 'charniere_hanche', 'extension_hanche', 'flexion_genou',
          'extension_genou', 'adducteurs_abducteurs', 'mollets', 'cou']:
    FORCE[s] = {}
SCHEMA = dict(FORCE)
SCHEMA.update({
    'gainage_anti_extension': {'tronc': 0.6},
    'gainage_anti_rotation': {'tronc': 0.6},
    'gainage_anti_flexion_laterale': {'tronc': 0.6},
    'flexion_tronc': {'tronc': 0.6},
    'rotation_tronc': {'tronc': 0.6},
    'extension_rachis': {'tronc': 0.6},
    'flexion_hanche': {'tronc': 0.6},
    'compression': {'tronc': 0.35, 'mobilite': 0.15, 'figures': 0.3},  # modulé par niveau (parts_fixes)
    'figure_statique_poussee': {'figures': 0.55},
    'figure_statique_tirage': {'figures': 0.55},
    'figure_statique_mixte': {'figures': 0.55},
    'equilibre_mains': {'figures': 0.6},
    'figure_dynamique_poussee': {'figures': 0.35, 'explosivite': 0.15},
    'figure_dynamique_tirage': {'figures': 0.35, 'explosivite': 0.15},
    'transition_muscle_up': {'figures': 0.15, 'tirer': 0.15, 'explosivite': 0.05},  # modulé par régime
    'freestyle': {'figures': 0.5, 'explosivite': 0.3},
    'halterophilie': {'explosivite': 0.5},
    'balistique': {'explosivite': 0.4, 'anaerobie': 0.2},
    'pliometrie': {'explosivite': 0.7},
    'porte': {'anaerobie': 0.2},
    'sprint': {'explosivite': 0.4, 'anaerobie': 0.4},
    'conditionnement': {'anaerobie': 0.4, 'aerobie': 0.2, 'endurance_force': 0.2},
    'gymnastique_crossfit': {'endurance_force': 0.3, 'anaerobie': 0.15, 'figures': 0.1},
    'cardio_continu': {'aerobie': 1.0},
    'marche': {'aerobie': 1.0},
    'cardio_fractionne': {'anaerobie': 0.55, 'aerobie': 0.45},
    'corde_a_sauter': {'aerobie': 0.5, 'anaerobie': 0.3, 'explosivite': 0.2},
    'mobilite_articulaire': {'mobilite': 1.0},
    'etirement_statique': {'mobilite': 1.0},
    'etirement_dynamique': {'mobilite': 1.0},
    'souplesse': {'mobilite': 1.0},
    'auto_massage': {'mobilite': 1.0},
    'respiration': {'mobilite': 1.0},
})

# R2 (relecture indépendante, C.2) — Parts fixes modulées par le niveau de
# l'exercice ou par son régime.
FIGURES_COMPRESSION = {'Débutant': 0.2, 'Intermédiaire': 0.3, 'Avancé': 0.4, 'Élite': 0.5}
EXPLOSIVITE_TRANSITION = {'explosif': 0.25, 'dynamique': 0.05}
FIGURES_HSPU_LIBRE = 0.25
FIGURES_HSPU_MUR = 0.10


def parts_fixes(e):
    c = e['calc']
    s = c['schema']
    if s == 'compression':
        fg = FIGURES_COMPRESSION[e['niveau']]
        return {'figures': fg, 'tronc': 0.65 - fg, 'mobilite': 0.15}
    if s in ('figure_dynamique_poussee', 'figure_dynamique_tirage'):
        if c['regime'] == 'explosif':
            return {'figures': 0.35, 'explosivite': 0.15}
        return {'figures': 0.45}
    if s == 'transition_muscle_up':
        return {'figures': 0.15, 'tirer': 0.15,
                'explosivite': EXPLOSIVITE_TRANSITION.get(c['regime'], 0.0)}
    if s == 'halterophilie' and c['regime'] != 'explosif':
        return {'explosivite': 0.1, 'mobilite': 0.1}
    if s == 'poussee_verticale_haute' and c['type_charge'] == 'poids_du_corps' and 'hspu' in e['id']:
        return {'figures': FIGURES_HSPU_MUR if 'mur' in e['materiel'] else FIGURES_HSPU_LIBRE}
    return dict(SCHEMA[s])


# R3 — Part d'endurance de force des mouvements de force et de tronc faits
# au poids du corps (répétitions hautes) ; nulle sous charge externe.
ENDURANCE_PDC = {'Débutant': 0.30, 'Intermédiaire': 0.20, 'Avancé': 0.10, 'Élite': 0.10}
ENDURANCE_ISO_TRONC = 0.30
SANS_CHARGE = ('poids_du_corps', 'aucune')  # l'élastique est une résistance externe réglable
SCHEMAS_TRONC = ('gainage_anti_extension', 'gainage_anti_rotation', 'gainage_anti_flexion_laterale',
                 'flexion_tronc', 'rotation_tronc', 'extension_rachis', 'flexion_hanche')

# R4 — Une variante garde 30 % du vecteur de la racine de sa chaîne.
PART_RACINE = 0.30

# R5 — Type de réponse (table du cahier, § 2).
FAMILLES_ENDURANCE = {'cardio': 'cardio', 'conditionnement': 'wod', 'mobilite': 'mobilite',
                      'recuperation': 'mobilite'}
CHARGES_EXTERNES = ('lest', 'barre', 'halteres', 'kettlebell', 'machine', 'poulie', 'autre')

# R6 — Charge tendineuse (0 à 1) et zone : plus forte contrainte articulaire
# du catalogue, majorée pour les tenues en bras tendus, l'excentrique, les
# sauts et les mouvements lestés au poids du corps.
NIVEAU_CONTRAINTE = {'faible': 0.1, 'moyenne': 0.4, 'forte': 0.8}
ORDRE_ZONES = ['coude', 'epaule', 'poignet', 'genou', 'cheville', 'hanche', 'lombaires']
SCHEMAS_BRAS_TENDUS = ('figure_statique_poussee', 'figure_statique_tirage', 'figure_statique_mixte')
SCHEMAS_SAUTS = ('pliometrie', 'sprint', 'corde_a_sauter')
# Relecture indépendante (C.6) : ordre de départage des zones par schéma,
# bonus « bras tendus » selon le niveau de la figure, assistance, plancher des
# sauts seulement s'il y a impact, étirement passif plafonné.
ORDRE_SCHEMA = {
    'equilibre_mains': ['poignet', 'epaule', 'coude'],
    'figure_statique_poussee': ['coude', 'poignet', 'epaule'],
    'pliometrie': ['genou', 'cheville'],
    'sprint': ['cheville', 'genou'],
    'corde_a_sauter': ['cheville', 'genou'],
    'balistique': ['lombaires', 'hanche'],
    'charniere_hanche': ['lombaires', 'hanche'],
    'halterophilie': ['poignet', 'genou', 'epaule'],
}
BONUS_BRAS_TENDUS = {'Débutant': 0.0, 'Intermédiaire': 0.1, 'Avancé': 0.2, 'Élite': 0.2}
ERGOMETRES = ('rameur', 'vélo / home-trainer', 'air bike (assault / echo)', 'SkiErg')
ASSISTANCE_TENDON = -0.2
ASSISTANCE_PLANCHER = 0.4
PASSIF_PLAFOND = 0.4

# R7 — A priori de population de la charge : 1RM de charge totale rapporté au
# poids du corps, niveau intermédiaire (ordres de grandeur de normes de
# force ; a priori large, SOURCES.md § A priori). Colonnes : barre, haltères
# ou kettlebell (par main), machine, poulie, lest (charge totale).
RATIO = {
    'squat': (1.40, 0.40, 2.20, 1.00, 1.30),
    'charniere_hanche': (1.70, 0.45, 1.00, 0.80, 1.30),
    'fente': (0.85, 0.30, 1.10, 0.50, 1.25),
    'poussee_horizontale': (1.05, 0.38, 0.90, 0.50, 1.15),
    'poussee_inclinee': (0.90, 0.33, 0.80, 0.45, 1.10),
    'poussee_verticale_haute': (0.68, 0.25, 0.60, 0.35, 1.00),
    'poussee_verticale_basse': (1.00, 0.40, 1.00, 0.60, 1.55),
    'tirage_vertical': (0.90, 0.40, 0.90, 0.90, 1.40),
    'tirage_horizontal': (0.95, 0.42, 0.90, 0.80, 1.20),
    'transition_muscle_up': (1.00, 0.40, 1.00, 1.00, 1.15),
    'isolation_biceps': (0.45, 0.20, 0.40, 0.35, 0.45),
    'isolation_triceps': (0.40, 0.15, 0.40, 0.35, 0.40),
    'isolation_epaules': (0.30, 0.12, 0.40, 0.12, 0.30),
    'isolation_pectoraux': (0.50, 0.20, 0.60, 0.25, 0.50),
    'isolation_dos': (0.50, 0.25, 0.60, 0.40, 0.50),
    'isolation_trapezes': (1.40, 0.50, 1.20, 0.80, 1.40),
    'extension_genou': (0.80, 0.30, 0.80, 0.60, 0.80),
    'flexion_genou': (0.60, 0.25, 0.60, 0.50, 0.60),
    'mollets': (1.20, 0.40, 1.50, 0.80, 1.20),
    'extension_hanche': (1.40, 0.40, 0.80, 0.50, 1.40),
    'adducteurs_abducteurs': (0.80, 0.30, 0.80, 0.50, 0.80),
    'halterophilie': (0.85, 0.30, 0.60, 0.40, 0.85),
    'balistique': (0.60, 0.35, 0.60, 0.40, 0.60),
    'prehension': (0.50, 0.15, 0.40, 0.35, 0.50),
    'cou': (0.25, 0.10, 0.30, 0.20, 0.25),
    'extension_rachis': (0.30, 0.15, 0.60, 0.40, 0.30),
    'preparation_scapulaire': (0.40, 0.20, 0.40, 0.30, 1.60),
}
RATIO_DEFAUT = (0.50, 0.20, 0.50, 0.40, 1.20)
# Relecture indépendante (C.7). Lest : part de poids de corps + lest relatif
# (charge ajoutée au 1RM rapportée au poids du corps, niveau intermédiaire).
LEST_RELATIF = {'tirage_vertical': 0.40, 'poussee_verticale_basse': 0.50, 'poussee_horizontale': 0.40,
                'transition_muscle_up': 0.15, 'fente': 0.30, 'tirage_horizontal': 0.35}
# Haltérophilie à la barre : a priori par mouvement de base (racine) et par
# variante (mot de l'identifiant) ; ordres de grandeur d'usage.
HALTERO_RACINE = {'mu-arrache': 0.78, 'mu-epaule': 1.00, 'mu-epaule-jete': 0.95, 'mu-push-press': 0.85,
                  'mu-overhead-squat': 0.85, 'cf-thruster-barre': 0.75, 'cf-sdhp-barre': 0.85}
HALTERO_VARIANTE = (('muscle', 0.70), ('power', 0.85), ('tirage', 1.10))
# Un seul membre : un peu plus de la moitié de la force des deux (déficit
# bilatéral), barre, machine et poulie des schémas bilatéraux par nature.
UNILATERAL = 0.55
SCHEMAS_UNILATERAL = ('poussee_horizontale', 'poussee_inclinee', 'poussee_verticale_haute',
                      'tirage_vertical', 'tirage_horizontal', 'squat', 'charniere_hanche',
                      'extension_genou', 'flexion_genou', 'isolation_biceps', 'isolation_triceps',
                      'isolation_dos', 'extension_hanche', 'adducteurs_abducteurs')
EXCENTRIQUE = 1.25
EXTENSEURS_POIGNET = 0.6
COLONNE = {'barre': 0, 'halteres': 1, 'kettlebell': 1, 'machine': 2, 'poulie': 3, 'lest': 4, 'autre': 0}


# R8 — Groupes musculaires (fatigue locale) : les 17 groupes de kalis_plan
# (`muscleGroupOf`, traits.dart), muscle principal 1, secondaire 0,5, la
# plus forte part par groupe. Un muscle absent de la table n'est pas compté.
GROUPES = ['chest', 'delt_anterior', 'delt_middle', 'delt_posterior', 'lats', 'upper_back', 'biceps',
           'triceps', 'abs', 'lower_back', 'glutes', 'quads', 'hamstrings', 'calves', 'forearms',
           'adductors', 'upper_traps']
GROUPE_DE = {
    'grand pectoral (faisceau claviculaire)': 'chest', 'grand pectoral (faisceau sternal)': 'chest',
    'grand pectoral (faisceau abdominal)': 'chest', 'deltoïde antérieur': 'delt_anterior',
    'deltoïde moyen': 'delt_middle', 'deltoïde postérieur': 'delt_posterior', 'grand dorsal': 'lats',
    'grand rond': 'lats', 'trapèze supérieur': 'upper_traps', 'élévateur de la scapula': 'upper_traps',
    'trapèze moyen': 'upper_back', 'trapèze inférieur': 'upper_back', 'rhomboïdes': 'upper_back',
    'érecteurs du rachis': 'lower_back', 'multifides': 'lower_back', 'carré des lombes': 'lower_back',
    'biceps brachial': 'biceps', 'brachial': 'biceps', 'brachio-radial': 'biceps',
    'triceps brachial (chef long)': 'triceps', 'triceps brachial (chefs latéral et médial)': 'triceps',
    'fléchisseurs du poignet': 'forearms', 'extenseurs du poignet': 'forearms',
    'fléchisseurs des doigts': 'forearms', "grand droit de l'abdomen": 'abs', 'obliques externes': 'abs',
    'obliques internes': 'abs', "transverse de l'abdomen": 'abs', 'grand fessier': 'glutes',
    'moyen fessier': 'glutes', 'petit fessier': 'glutes', 'adducteurs': 'adductors',
    'quadriceps (droit fémoral)': 'quads', 'quadriceps (vastes)': 'quads', 'ischio-jambiers': 'hamstrings',
    'gastrocnémiens': 'calves', 'soléaire': 'calves',
}


def groupes_de(e):
    """Parts des groupes musculaires : liste creuse [[indice, part], ...]."""
    parts = {}
    for poids, liste in ((1.0, e['muscles_principaux']), (0.5, e['muscles_secondaires'])):
        for m in liste:
            g = GROUPE_DE.get(m)
            if g is not None and poids > parts.get(g, 0.0):
                parts[g] = poids
    return [[i, parts[g]] for i, g in enumerate(GROUPES) if g in parts]


# R9 — Ce que le validateur de sécurité du banc lit d'une fiche (critères
# `volume_trop_vite`, `tendon_figures`, `seance_trop_longue`, portés dans
# `koach/seance.py`, règle « retour gradué au volume ») :
# - `renforcement` : `SlotKind.isResistance` de `kalis_plan`
#   (`slotKindOf`, kalis_plan/lib/src/traits.dart:545-600) : tout exercice
#   hors mobilité, cardio et conditionnement CrossFit (l'haltérophilie
#   CrossFit est de la puissance, donc du renforcement) ;
# - `lateralite` : latéralité du catalogue (`calc.lateralite`) ; une
#   séance compte deux côtés pour tout ce qui n'est pas bilatéral
#   (`ItemView.estimatedSeconds`, kalis_bench/lib/src/analysis.dart) ;
# - `bras_tendus` : famille des tenues bras tendus (`ItemView.straightArm`,
#   même fichier) : back lever en poussée, tenue menton exclue, sinon le
#   schéma de figure statique.
DISCIPLINES_SANS_RENFORCEMENT = ('Mobilité', 'Cardio')
DISCIPLINE_CONDITIONNEMENT = 'CrossFit / WOD'
FAMILLE_BRAS_TENDUS = {'figure_statique_poussee': 'push', 'figure_statique_tirage': 'pull',
                       'figure_statique_mixte': 'mixed'}


def renforcement_de(e):
    if e['discipline'] in DISCIPLINES_SANS_RENFORCEMENT:
        return False
    if e['discipline'] == DISCIPLINE_CONDITIONNEMENT:
        return e['calc']['schema'] == 'halterophilie'
    return True


def bras_tendus_de(e):
    racine = e['calc']['racine'] or e['id']
    if racine.startswith('cs-back-lever') or e['id'].startswith('cs-back-lever'):
        return 'push'
    if racine.startswith('cs-tenue-menton') or e['id'].startswith('cs-tenue-menton'):
        return None
    return FAMILLE_BRAS_TENDUS.get(e['calc']['schema'])


def type_de(e):
    c = e['calc']
    if c['famille'] in FAMILLES_ENDURANCE:
        return FAMILLES_ENDURANCE[c['famille']]
    if c['unite'] in ('distance', 'calories'):
        return 'autre'
    if c['unite'] == 'secondes':
        return 'tenue'
    if c['assiste']:
        return 'reps'
    return 'charge' if c['type_charge'] in CHARGES_EXTERNES else 'reps'


def vecteur_propre(e):
    c = e['calc']
    fixe = parts_fixes(e)
    v = [0.0] * len(QUALITES)
    for q, w in fixe.items():
        v[Q[q]] += w
    reste = 1.0 - sum(fixe.values())
    if reste > 1e-9:
        if c['schema'] in FORCE or c['schema'] in SCHEMAS_TRONC or c['schema'] in ('porte',):
            if c['type_charge'] in SANS_CHARGE:
                if c['unite'] == 'repetitions' and c['regime'] in ('dynamique', 'excentrique', 'explosif'):
                    part = ENDURANCE_PDC[e['niveau']]
                elif c['unite'] == 'secondes' and c['schema'] in SCHEMAS_TRONC:
                    part = ENDURANCE_ISO_TRONC
                else:
                    part = 0.0
                v[Q['endurance_force']] += reste * part
                reste *= 1.0 - part
        masses = [0.0, 0.0, 0.0, 0.0]
        tirage = c['schema'] in SCHEMAS_TIRAGE

        def qualite(m):
            return 'tirer' if tirage and m in EXTENSEURS_EN_TIRAGE else MUSCLE[m]

        for m in e['muscles_principaux']:
            masses[Q[qualite(m)]] += 1.0
        for m in e['muscles_secondaires']:
            masses[Q[qualite(m)]] += 0.5
        if c['schema'] in SCHEMAS_STABILISATEURS:
            for m in e.get('muscles_stabilisateurs') or []:
                if MUSCLE.get(m) == 'tirer':
                    masses[Q['tirer']] += POIDS_STABILISATEUR
        total = sum(masses)
        if total <= 0:
            masses = [0.25, 0.25, 0.25, 0.25]
            total = 1.0
        for i in range(4):
            v[i] += reste * masses[i] / total
    return v


def tendon_de(e):
    c = e['calc']
    s = c['schema']
    premiers = ORDRE_SCHEMA.get(s, [])
    ordre = premiers + [z for z in ORDRE_ZONES if z not in premiers]
    zone = None
    niveau = 0.0
    for z in ordre:
        n = NIVEAU_CONTRAINTE[c['contraintes'][z]]
        if n > niveau + 1e-12:
            niveau = n
            zone = z
    if s in SCHEMAS_BRAS_TENDUS:
        niveau += BONUS_BRAS_TENDUS[e['niveau']]
    if c['regime'] == 'excentrique':
        niveau += 0.1
    if s in SCHEMAS_SAUTS and niveau < 0.7:
        principaux = e['muscles_principaux']
        jambes = sum(1 for m in principaux if MUSCLE.get(m) == 'jambes')
        impact = not (set(e['materiel']) & set(ERGOMETRES)) and \
            (s != 'pliometrie' or 2 * jambes >= len(principaux))
        if impact:
            niveau = 0.7
            if zone in (None, 'coude', 'epaule', 'poignet'):
                zone = 'genou' if s == 'pliometrie' else 'cheville'
    if c['type_charge'] == 'lest' and s in ('tirage_vertical', 'poussee_verticale_basse',
                                            'transition_muscle_up'):
        niveau += 0.1
    if c['assiste']:
        niveau = max(ASSISTANCE_PLANCHER, niveau + ASSISTANCE_TENDON)
    if c['regime'] == 'passif' and niveau > PASSIF_PLAFOND:
        niveau = PASSIF_PLAFOND
    if niveau > 1.0:
        niveau = 1.0
    if niveau <= 0.1 + 1e-9:
        zone = None
    return round(niveau, 2), zone


def ratio_de(e):
    c = e['calc']
    s = c['schema']
    tc = c['type_charge']
    col = 0 if 'Smith machine' in e['materiel'] else COLONNE[tc]
    r = RATIO.get(s, RATIO_DEFAUT)[col]
    if s == 'halterophilie' and tc == 'barre':
        r = HALTERO_RACINE.get(c['racine'], 0.85)
        for mot, f in HALTERO_VARIANTE:
            if mot in e['id']:
                r *= f
    if s == 'prehension' and 'extenseurs du poignet' in e['muscles_principaux']:
        r *= EXTENSEURS_POIGNET
    if tc == 'lest' and c['fraction_pdc'] and s in LEST_RELATIF:
        r = c['fraction_pdc']['valeur'] + LEST_RELATIF[s]
    if c['lateralite'] == 'unilateral' and col in (0, 2, 3) and s in SCHEMAS_UNILATERAL:
        r *= UNILATERAL
    if c['regime'] == 'excentrique' and tc in ('lest', 'barre', 'machine'):
        r *= EXCENTRIQUE
    return round(r, 2)


def generer(catalogue):
    exercices = catalogue['exercices']
    par_id = {e['id']: e for e in exercices}
    propres = {e['id']: vecteur_propre(e) for e in exercices}
    out = {}
    for e in exercices:
        c = e['calc']
        v = propres[e['id']]
        racine = c['racine']
        if e['variante_de'] and racine in par_id and racine != e['id'] \
                and par_id[racine]['calc']['schema'] == c['schema']:
            r = propres[racine]
            v = [(1 - PART_RACINE) * a + PART_RACINE * b for a, b in zip(v, r)]
        s = sum(v)
        v = [round(x / s, 4) for x in v]
        # La somme vaut exactement 1 : l'arrondi est porté par la plus forte charge.
        i = max(range(len(v)), key=lambda k: (v[k], -k))
        v[i] = round(v[i] + 1.0 - sum(v), 4)
        typ = type_de(e)
        tendon, zone = tendon_de(e)
        frac = c['fraction_pdc']['valeur'] if c['fraction_pdc'] else 0.0
        ratio = None
        if typ == 'charge':
            ratio = ratio_de(e)
        out[e['id']] = {
            'type': typ,
            'vecteur': v,
            'tendon': tendon,
            'zone_tendon': zone,
            'fraction': frac,
            'ratio': ratio,
            'difficulte': c['difficulte'],
            'bas': c['articularite'] == 'polyarticulaire' and c['famille'] in ('jambes_genou', 'jambes_hanche'),
            'systemique': round(c['fatigue']['systemique'] / 3.0, 4),
            'locale': round(c['fatigue']['locale'] / 3.0, 4),
            'schema': c['schema'],
            'niveau': e['niveau'],
            'lieux': c['lieux'],
            'materiel': e['materiel'],
            'racine': racine,
            'profondeur': c['profondeur'],
            'unite': c['unite'],
            'type_charge': c['type_charge'],
            'contraintes': c['contraintes'],
            'groupes': groupes_de(e),
            'renforcement': renforcement_de(e),
            'lateralite': c['lateralite'],
            'bras_tendus': bras_tendus_de(e),
        }
    return {
        'schema': 1,
        'version': '1.0.0',
        'source': catalogue['source'],
        'qualites': QUALITES,
        'groupes': GROUPES,
        'exercices': out,
    }


def texte(catalogue):
    return json.dumps(generer(catalogue), ensure_ascii=False, sort_keys=True, indent=0) + '\n'


def main(argv):
    with gzip.open(CATALOGUE, 'rt', encoding='utf-8') as f:
        catalogue = json.load(f)
    t = texte(catalogue)
    if '--verifier' in argv:
        with open(SORTIE, encoding='utf-8') as f:
            if f.read() != t:
                print('vecteurs_qualites_v1.json n\'est pas à jour')
                return 1
        return 0
    with open(SORTIE, 'w', encoding='utf-8') as f:
        f.write(t)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
