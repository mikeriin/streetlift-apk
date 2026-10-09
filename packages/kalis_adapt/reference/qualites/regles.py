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
    'compression': {'tronc': 0.5, 'mobilite': 0.3, 'figures': 0.2},
    'figure_statique_poussee': {'figures': 0.55},
    'figure_statique_tirage': {'figures': 0.55},
    'figure_statique_mixte': {'figures': 0.55},
    'equilibre_mains': {'figures': 0.6},
    'figure_dynamique_poussee': {'figures': 0.35, 'explosivite': 0.15},
    'figure_dynamique_tirage': {'figures': 0.35, 'explosivite': 0.15},
    'transition_muscle_up': {'explosivite': 0.25, 'figures': 0.15},
    'freestyle': {'figures': 0.5, 'explosivite': 0.3},
    'halterophilie': {'explosivite': 0.5},
    'balistique': {'explosivite': 0.4, 'anaerobie': 0.2},
    'pliometrie': {'explosivite': 0.7},
    'porte': {'anaerobie': 0.2},
    'sprint': {'explosivite': 0.4, 'anaerobie': 0.4, 'jambes': 0.2},
    'conditionnement': {'anaerobie': 0.5, 'aerobie': 0.25, 'endurance_force': 0.25},
    'gymnastique_crossfit': {'figures': 0.3, 'endurance_force': 0.2},
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

# R3 — Part d'endurance de force des mouvements de force et de tronc faits
# au poids du corps (répétitions hautes) ; nulle sous charge externe.
ENDURANCE_PDC = {'Débutant': 0.30, 'Intermédiaire': 0.20, 'Avancé': 0.10, 'Élite': 0.10}
ENDURANCE_ISO_TRONC = 0.30
SANS_CHARGE = ('poids_du_corps', 'aucune', 'elastique')
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

# R7 — A priori de population de la charge : 1RM de charge totale rapporté au
# poids du corps, niveau intermédiaire (ordres de grandeur de normes de
# force ; a priori large, SOURCES.md § A priori). Colonnes : barre, haltères
# ou kettlebell (par main), machine, poulie, lest (charge totale).
RATIO = {
    'squat': (1.40, 0.40, 2.20, 1.00, 1.30),
    'charniere_hanche': (1.70, 0.45, 1.00, 0.80, 1.30),
    'fente': (0.85, 0.30, 0.80, 0.50, 1.25),
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
    'isolation_trapezes': (1.00, 0.40, 0.80, 0.60, 1.00),
    'extension_genou': (0.80, 0.30, 0.80, 0.60, 0.80),
    'flexion_genou': (0.60, 0.25, 0.60, 0.50, 0.60),
    'mollets': (1.20, 0.40, 1.50, 0.80, 1.20),
    'extension_hanche': (1.40, 0.40, 0.80, 0.50, 1.40),
    'adducteurs_abducteurs': (0.80, 0.30, 0.80, 0.50, 0.80),
    'halterophilie': (0.85, 0.30, 0.60, 0.40, 0.85),
}
RATIO_DEFAUT = (0.50, 0.20, 0.50, 0.40, 1.20)
COLONNE = {'barre': 0, 'halteres': 1, 'kettlebell': 1, 'machine': 2, 'poulie': 3, 'lest': 4, 'autre': 0}


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
    fixe = dict(SCHEMA[c['schema']])
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
        for m in e['muscles_principaux']:
            masses[Q[MUSCLE[m]]] += 1.0
        for m in e['muscles_secondaires']:
            masses[Q[MUSCLE[m]]] += 0.5
        total = sum(masses)
        if total <= 0:
            masses = [0.25, 0.25, 0.25, 0.25]
            total = 1.0
        for i in range(4):
            v[i] += reste * masses[i] / total
    return v


def tendon_de(e):
    c = e['calc']
    zone = None
    niveau = 0.0
    for z in ORDRE_ZONES:
        n = NIVEAU_CONTRAINTE[c['contraintes'][z]]
        if n > niveau + 1e-12:
            niveau = n
            zone = z
    if c['schema'] in SCHEMAS_BRAS_TENDUS:
        niveau += 0.2
    if c['regime'] == 'excentrique':
        niveau += 0.1
    if c['schema'] in SCHEMAS_SAUTS and niveau < 0.7:
        niveau = 0.7
    if c['type_charge'] == 'lest' and c['schema'] in ('tirage_vertical', 'poussee_verticale_basse',
                                                       'transition_muscle_up'):
        niveau += 0.1
    if niveau > 1.0:
        niveau = 1.0
    return round(niveau, 2), zone


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
            ratio = RATIO.get(c['schema'], RATIO_DEFAUT)[COLONNE[c['type_charge']]]
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
        }
    return {
        'schema': 1,
        'version': '1.0.0',
        'source': catalogue['source'],
        'qualites': QUALITES,
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
