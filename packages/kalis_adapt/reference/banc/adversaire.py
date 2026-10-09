# -*- coding: utf-8 -*-
"""Banc adversarial de Koach (lot KM1, brique 4 du cahier `CAHIER_KM.md`) :
recherche bornée d'athlètes simulés RÉALISTES qui mettent Koach en
difficulté (minimax), export pour le témoin Dart et pour KM2, comparaison.

Principe
--------
- Un athlète adverse = une saison de référence existante (profil de base ×
  scénario × modèle de vérité) dont on modifie :
    * la fiche de comportement et de physiologie (`spec`, surcouche de
      `saison['specJson']`, mêmes noms que `AthleteSpec` côté Dart) ;
    * des multiplicateurs de vérité par exercice (`surcharges`, clé `*` pour
      tous les exercices, et une clé par mouvement principal), lus par
      `KmOverridePolicy` côté Dart et `meneur._surcharger` côté Python.
  Chaque dimension a des bornes écrites et justifiées (`DIMENSIONS`).
- L'espace est paramétré par un vecteur u ∈ [0, 1]^d (une coordonnée par
  dimension) : `decoder(u, cadre)` le traduit en (spec, surcharges). Le
  décodage respecte les bornes par construction.
- Recherche déterministe (Mulberry32, graine fixe), bornée en nombre de
  saisons simulées : hypercube latin, puis évolution (μ+λ) dans [0, 1]^d qui
  MAXIMISE la difficulté (= minimise la performance de Koach). Chaque
  adversaire est évalué sur plusieurs graines (≥ 2) : on retient une
  difficulté moyenne, pas un coup de chance.
- Export : `ecrire_adversaires` (entrée de `kmAdversaryRun`, une entrée par
  adversaire et par graine, le Dart ne lisant qu'une graine par entrée) et
  une copie lisible (`donnees/adversaires_v1.json`).
- Comparaison : `comparer` rejoue Koach en Python et lit la sortie du témoin
  (`adversaires_temoin.json.gz`) : performance le jour J (moyenne, PIRE CAS),
  erreur d'e1RM au rang 6, sécurité. Critère du lot : pire cas de Koach ≥ pire
  cas du témoin.

Critères de difficulté (mesurés pour chaque saison)
---------------------------------------------------
(a) performance le jour J : moyenne, sur les exercices testés à l'échéance,
    de meilleure valeur réussie / maximum du jour (`mesures.evenements`), 0 si
    aucun test réussi. Définie seulement si la saison a une échéance ET que
    l'athlète est présent ce jour-là (sinon la mesure ne dit rien de Koach :
    les graines où l'athlète manque le jour J sont écartées a priori, voir
    `graines_valides`) ;
(b) erreur absolue d'e1RM des mouvements principaux chargés au rang 6
    (`mesures.Estimations`, ligne 6 ; à défaut : tous les chargés, puis
    répétitions, puis tenues) ;
(c) sécurité : aggravations de douleur, poussées, échecs non voulus
    (`mesures.effort`), violations de sécurité du programme servi (indicatif).

La recherche porte sur (a) ; sur une saison SANS échéance (cas de
`street_06_inter_sets_reps` et `autres_01_debutant_musculation`), (a)
n'existe pas et la recherche se rabat sur (b) (champ `objectif_effectif`).
Option `objectif='b'` : (b) partout.

Le témoin Dart sait rejouer TOUTES les dimensions de l'espace (`spec` complet
via `athleteFromJson`, multiplicateurs `capacity`, `curveB`, `slope`,
`power`, `fatigueScale`, `holdShare` via `kmOverridesOf`) : Koach et le
témoin sont comparés sur les mêmes athlètes.
"""
import argparse
import copy
import gzip
import json
import math
import os
import sys
import traceback

if __package__ in (None, ''):
    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from koach.numerique import Mulberry32, fnv1a32  # noqa: E402

from banc import donnees, meneur, mesures  # noqa: E402
from banc import securite_banc as sb  # noqa: E402
from banc.alea import SimRandom  # noqa: E402
from banc.verite import make_book  # noqa: E402

SCHEMA = 1
VERSION = 'adversaires_v1'

# Cellules de recherche par défaut (profil de base, saison de référence).
PROFILS_DEFAUT = (
    'street_07_avance_streetlifting_competition',
    'autres_03_powerlifter_competition',
    'street_06_inter_sets_reps',
    'autres_01_debutant_musculation',
)
SCENARIO_DEFAUT = 'reference'
MODELES_DEFAUT = 'abc'

ICI = os.path.dirname(os.path.abspath(__file__))
SORTIE_DEFAUT = os.path.join(os.path.dirname(ICI), 'donnees', 'adversaires_v1.json')

# Recul minimal (jours) entre la fin d'un épisode (coupure, maladie,
# douleur) et la première échéance : un athlète encore absent, malade ou
# douloureux le jour J transforme (a) en question médicale ou de calendrier,
# identique pour tout entraîneur. L'épisode peut finir juste avant ce recul :
# c'est la reprise avant l'échéance qui teste Koach.
RECUL_ECHEANCE = 7
# Premier jour possible d'un épisode : laisser au moins une semaine
# d'entraînement pour que Koach ait vu l'athlète.
DEBUT_EPISODE = 7

# Zones de douleur tirées (codes `BodyZone` de kalis_core) : les plus
# fréquentes en musculation et en street workout. « aucune » est une valeur
# à part entière de la dimension.
ZONES_DOULEUR = (None, 'shoulder', 'elbow', 'wrist_hand', 'lower_back', 'knee', 'hip')

# Plancher du multiplicateur de capacité des exercices lestés au poids de
# corps. Le modèle de vérité garantit une capacité ≥ 1,15 × la part du poids
# de corps soulevée (`SimAthlete.truth_of`) : un athlète à qui l'on prescrit
# un mouvement LESTÉ sait le faire au poids du corps. Un facteur 0,80 casserait
# cette garantie (capacité sous le poids de corps : aucune répétition
# possible, quel que soit l'entraîneur — vu à la première recherche sur
# `sl-muscle-up-leste`). Avec 0,92 la capacité reste ≥ 1,06 × la part du
# poids de corps.
PLANCHER_POIDS_CORPS = 0.92


class Dimension(object):
    """Une dimension de l'espace : nom, bornes, échelle (« lin », « log »,
    « entier », « zone »), valeur nominale du modèle de vérité et
    justification de la borne."""

    __slots__ = ('nom', 'bas', 'haut', 'echelle', 'nominal', 'raison')

    def __init__(self, nom, bas, haut, echelle, nominal, raison):
        self.nom = nom
        self.bas = bas
        self.haut = haut
        self.echelle = echelle
        self.nominal = nominal
        self.raison = raison

    def valeur(self, u):
        """Valeur de la dimension pour u ∈ [0, 1]."""
        u = 0.0 if u < 0 else (1.0 if u > 1 else u)
        if self.echelle == 'log':
            return _r4(math.exp(math.log(self.bas) + u * (math.log(self.haut) - math.log(self.bas))))
        if self.echelle == 'entier':
            n = self.haut - self.bas + 1
            k = int(u * n)
            return self.bas + (n - 1 if k >= n else k)
        if self.echelle == 'zone':
            k = int(u * len(ZONES_DOULEUR))
            return ZONES_DOULEUR[len(ZONES_DOULEUR) - 1 if k >= len(ZONES_DOULEUR) else k]
        return _r4(self.bas + u * (self.haut - self.bas))


# ---------------------------------------------------------------------------
# Espace des athlètes adverses : bornes et justifications.
#
# Les valeurs nominales sont celles de `Spec.DEFAULTS` (banc/verite.py,
# portage de `AthleteSpec`) et des tirages de `SimAthlete.truth_of`.
# ---------------------------------------------------------------------------
DIMENSIONS = (
    # --- Notes de difficulté (RIR ressenti) --------------------------------
    Dimension('ratingNoise', 0.5, 2.5, 'log', 1.0,
              'Bruit des notes : de 0,5× (athlète très régulier) à 2,5× le '
              'nominal (note quasi aléatoire à ±2 RIR près de l\'échec) ; '
              'au-delà, plus aucune note n\'informe et aucun moteur ne peut '
              's\'en servir.'),
    Dimension('rirBias', -0.15, 0.8, 'lin', 0.25,
              'Biais multiplicatif du RIR perçu (RIR perçu = vrai / (1 + biais)) : '
              'bornes exactes du modèle de vérité (clamp [-0,15 ; 0,8] de '
              '`SimAthlete`) ; sans effet sous le modèle C (biais tiré du niveau).'),
    Dimension('rirBiasSd', 0.05, 0.36, 'lin', 0.18,
              'Dispersion du biais entre athlètes : du quart au double du '
              'nominal.'),
    Dimension('lazy', 0.0, 0.5, 'lin', 0.1,
              'Notes paresseuses (recopie la difficulté visée) : jusqu\'à une '
              'série sur deux près de la cible ; au-delà la note ne serait '
              'plus une mesure mais un écho.'),
    Dimension('skipRating', 0.0, 0.5, 'lin', 0.0,
              'Notes sautées : jusqu\'à une série sur deux sans note (Koach '
              'rend la note obligatoire sur les principaux, D8 ; 50 % est un '
              'majorant prudent pour les autres).'),
    # --- Assiduité et épisodes --------------------------------------------
    Dimension('missRate', 0.0, 0.35, 'lin', 0.08,
              'Séances manquées au hasard : au plus 35 % (le scénario « séances '
              'manquées » du banc en met 25 %) ; au-delà ce n\'est plus un '
              'programme suivi.'),
    Dimension('breakDays', 0, 14, 'entier', 0,
              'Coupure (vacances) : 0 à 14 jours d\'affilée, finie au moins '
              '7 jours avant l\'échéance.'),
    Dimension('breakFrom', 0.0, 1.0, 'lin', None,
              'Début de la coupure, en fraction de la fenêtre possible '
              '[7 ; J − 7 − durée].'),
    Dimension('illnessDays', 0, 10, 'entier', 0,
              'Maladie (forme −8 %, séances maintenues) : 0 à 10 jours, finie '
              'au moins 7 jours avant l\'échéance (le scénario du banc : 7 jours).'),
    Dimension('illnessFrom', 0.0, 1.0, 'lin', None,
              'Début de la maladie, en fraction de la fenêtre possible.'),
    Dimension('painZone', 0, 1, 'zone', None,
              'Zone de douleur : aucune, épaule, coude, poignet/main, lombaires, '
              'genou, hanche (codes `BodyZone`).'),
    Dimension('painIntensity', 3, 7, 'entier', 5,
              'Intensité de la douleur sur 10 : de 3 (gêne, seuil où le modèle '
              'garde une zone réactive) à 7 (au-delà, on arrête de s\'entraîner).'),
    Dimension('painDays', 7, 35, 'entier', 21,
              'Durée de l\'épisode douloureux : 1 à 5 semaines (le scénario du '
              'banc : 3 semaines), fini au moins 7 jours avant l\'échéance.'),
    Dimension('painFrom', 0.0, 1.0, 'lin', None,
              'Début de la douleur, en fraction de la fenêtre possible.'),
    # --- Jour, bilan, temps ------------------------------------------------
    Dimension('daySd', 0.0125, 0.0625, 'log', 0.025,
              'Dispersion de la forme du jour : de 0,5× à 2,5× le nominal '
              '(±6 % d\'un jour à l\'autre au maximum, ordre de grandeur des '
              'variations de 1RM rapportées).'),
    Dimension('healthAnswerRate', 0.1, 1.0, 'lin', 0.7,
              'Taux de réponse au bilan de forme : de 10 % (presque jamais) à '
              'toujours.'),
    Dimension('shortTimeRate', 0.0, 0.3, 'lin', 0.05,
              'Séances avec peu de temps (60 % du budget) : jusqu\'à près d\'une '
              'séance sur trois.'),
    # --- Vérité par exercice (surcharges) ---------------------------------
    Dimension('capaciteTous', 0.80, 1.20, 'log', 1.0,
              'Capacité vraie de TOUS les exercices par rapport au tirage '
              '(lui-même centré sur le déclaré, ±8 à 10 %) : ±20 %, soit '
              'environ ±25 % du déclaré à un écart-type du tirage (déclaration '
              'optimiste ou prudente).'),
    Dimension('courbeTous', 0.75, 1.33, 'log', 1.0,
              'Forme de la courbe charge-répétitions de tous les exercices '
              '(multiplie curveB, slope et power : seul le paramètre du modèle '
              'de vérité de la saison agit) : de 0,75× à 1,33× (≈ ±2 écarts-'
              'types du tirage individuel, 0,18 à 0,20 en log).'),
    Dimension('fatigueTous', 0.6, 1.67, 'log', 1.0,
              'Sensibilité à la fatigue de séance de tous les exercices : '
              '0,6× à 1,67× (≈ ±1,5 écart-type du tirage, 0,35 en log).'),
    Dimension('capacitePrincipaux', 0.80, 1.20, 'log', 1.0,
              'Capacité vraie des mouvements principaux (remplace le facteur '
              '« tous » pour eux) : ±20 %, mêmes raisons ; c\'est l\'erreur de '
              'déclaration la plus probable (1RM ancien ou estimé).'),
    Dimension('courbePrincipaux', 0.75, 1.33, 'log', 1.0,
              'Forme de courbe des mouvements principaux : mêmes bornes.'),
    Dimension('fatiguePrincipaux', 0.6, 1.67, 'log', 1.0,
              'Sensibilité à la fatigue des mouvements principaux : mêmes bornes.'),
)
NOMS = tuple(d.nom for d in DIMENSIONS)
PAR_NOM = {d.nom: d for d in DIMENSIONS}
D = len(DIMENSIONS)

# Champs de `spec` que l'espace peut écrire (noms `AthleteSpec`).
CHAMPS_SPEC = ('ratingNoise', 'rirBias', 'rirBiasSd', 'lazy', 'skipRating', 'missRate',
               'breakFromDay', 'breakDays', 'illnessFromDay', 'illnessDays', 'painZone',
               'painFromDay', 'painDays', 'painIntensity', 'daySd', 'healthAnswerRate',
               'shortTimeRate')
# Multiplicateurs écrits (sous-ensemble de `kmOverrideFields`).
CHAMPS_SURCHARGE = ('capacity', 'curveB', 'slope', 'power', 'fatigueScale')


def _r4(x):
    return float('%.4f' % x)


def _r6(x):
    return None if x is None else float('%.6f' % x)


# ---------------------------------------------------------------------------
# Cadre d'une cellule (profil × scénario × modèle)
# ---------------------------------------------------------------------------

def saison_de(cle, scenario):
    for s in donnees.saisons_reference(cle):
        if s['scenario'] == scenario:
            return s
    raise KeyError('saison absente : %s / %s' % (cle, scenario))


def principaux_de(saison):
    """Exercices de rôle « main » dans les blocs de la saison (triés)."""
    out = set()
    for b in saison['blocks']:
        for d in b['pass1']['days']:
            for s in d['slots']:
                if s.get('role') == 'main' and s.get('exerciseId'):
                    out.add(s['exerciseId'])
    return sorted(out)


def exercices_poids_corps(saison):
    """Exercices chargés de la saison dont la charge totale comprend une part
    du poids de corps (traction lestée, dips lestés, muscle-up lesté…) :
    écrits dans les blocs (pass1 et pass2), triés."""
    livre = make_book(donnees.catalogue_infos(), saison['profiles'][0]['profile'])
    ids = set()
    for b in saison['blocks']:
        for d in b['pass1']['days']:
            for s in d['slots']:
                ids.add(s.get('exerciseId'))
        for w in b['pass2']['weeks']:
            for d in w['days']:
                for it in d['items']:
                    ids.add(it.get('exerciseId'))
    out = []
    for ex in ids:
        info = livre.get(ex)
        if info is not None and info.mode == 'loaded' and info.fraction > 0:
            out.append(ex)
    return sorted(out)


def jours_echeance(saison):
    out = []
    for jours in saison['eventDaysByWeek']:
        out += list(jours)
    return sorted(set(out))


class Cadre(object):
    """Ce que le décodage doit savoir d'une cellule de recherche."""

    def __init__(self, cle, scenario, kind):
        s = saison_de(cle, scenario)
        self.cle = cle
        self.scenario = scenario
        self.kind = kind
        self.semaines = s['weeks']
        self.echeances = jours_echeance(s)
        self.principaux = principaux_de(s)
        # Dernier jour où un épisode peut se terminer.
        fin = self.echeances[0] if self.echeances else 7 * self.semaines
        self.fin_episodes = fin - RECUL_ECHEANCE
        self.spec_base = dict(s['specJson'])
        self.poids_corps = exercices_poids_corps(s)

    @property
    def nom(self):
        return '%s|%s|%s' % (self.cle, self.scenario, self.kind)


def _episode(cadre, duree, u_debut):
    """Jour de début d'un épisode de [duree] jours, dans
    [DEBUT_EPISODE ; fin_episodes − duree] ; None si la fenêtre est vide."""
    dernier = cadre.fin_episodes - duree
    if duree <= 0 or dernier < DEBUT_EPISODE:
        return None
    n = dernier - DEBUT_EPISODE + 1
    k = int(u_debut * n)
    return DEBUT_EPISODE + (n - 1 if k >= n else k)


def decoder(u, cadre):
    """Vecteur u ∈ [0, 1]^D → (spec, surcharges, parametres lisibles)."""
    v = {d.nom: d.valeur(u[i]) for i, d in enumerate(DIMENSIONS)}
    spec = {}
    for nom in ('ratingNoise', 'rirBias', 'rirBiasSd', 'lazy', 'skipRating', 'missRate',
                'daySd', 'healthAnswerRate', 'shortTimeRate'):
        spec[nom] = v[nom]
    debut = _episode(cadre, v['breakDays'], v['breakFrom'])
    if debut is not None:
        spec['breakFromDay'] = debut
        spec['breakDays'] = v['breakDays']
    debut = _episode(cadre, v['illnessDays'], v['illnessFrom'])
    if debut is not None:
        spec['illnessFromDay'] = debut
        spec['illnessDays'] = v['illnessDays']
    if v['painZone'] is not None:
        debut = _episode(cadre, v['painDays'], v['painFrom'])
        if debut is not None:
            spec['painZone'] = v['painZone']
            spec['painFromDay'] = debut
            spec['painDays'] = v['painDays']
            spec['painIntensity'] = v['painIntensity']

    def mult(cap, courbe, fatigue):
        return {'capacity': cap, 'curveB': courbe, 'slope': courbe, 'power': courbe,
                'fatigueScale': fatigue}
    surcharges = {'*': mult(v['capaciteTous'], v['courbeTous'], v['fatigueTous'])}
    for ex in cadre.principaux:
        # Clé exacte : remplace « * » pour cet exercice (même règle en Dart et
        # en Python), d'où l'entrée complète.
        surcharges[ex] = mult(v['capacitePrincipaux'], v['courbePrincipaux'], v['fatiguePrincipaux'])
    # Plancher des exercices lestés au poids de corps (voir
    # PLANCHER_POIDS_CORPS) : entrée propre quand le facteur commun le franchit.
    for ex in cadre.poids_corps:
        m = surcharges.get(ex) or surcharges['*']
        if m['capacity'] < PLANCHER_POIDS_CORPS:
            surcharges[ex] = dict(m, capacity=PLANCHER_POIDS_CORPS)
    return spec, surcharges, v


def identifiant(cle, scenario, kind, spec, surcharges):
    """Identifiant stable : empreinte FNV-1a du contenu canonique."""
    texte = json.dumps([cle, scenario, kind, spec, surcharges], sort_keys=True,
                       separators=(',', ':'), ensure_ascii=True)
    return 'adv-%08x' % fnv1a32(texte)


def verifier_bornes(adv):
    """Liste des écarts aux bornes d'un adversaire exporté (vide si correct)."""
    err = []
    spec = adv['spec']
    for k in spec:
        if k not in CHAMPS_SPEC:
            err.append('champ de spec inconnu : %s' % k)
    for nom in ('ratingNoise', 'rirBias', 'rirBiasSd', 'lazy', 'skipRating', 'missRate',
                'daySd', 'healthAnswerRate', 'shortTimeRate'):
        d = PAR_NOM[nom]
        x = spec.get(nom)
        if x is None or not (d.bas - 1e-9 <= x <= d.haut + 1e-9):
            err.append('%s=%r hors [%s ; %s]' % (nom, x, d.bas, d.haut))
    fin = adv['fin_episodes']
    for (champ_debut, champ_duree, nom) in (('breakFromDay', 'breakDays', 'breakDays'),
                                            ('illnessFromDay', 'illnessDays', 'illnessDays'),
                                            ('painFromDay', 'painDays', 'painDays')):
        if champ_debut in spec:
            debut, duree = spec[champ_debut], spec[champ_duree]
            d = PAR_NOM[nom]
            if not (isinstance(debut, int) and isinstance(duree, int)):
                err.append('%s/%s : entiers attendus' % (champ_debut, champ_duree))
                continue
            if not (max(1, d.bas) <= duree <= d.haut):
                err.append('%s=%d hors bornes' % (champ_duree, duree))
            if debut < DEBUT_EPISODE or debut + duree > fin:
                err.append('%s : épisode [%d ; %d] hors fenêtre [%d ; %d]'
                           % (champ_debut, debut, debut + duree, DEBUT_EPISODE, fin))
    if 'painZone' in spec:
        if spec['painZone'] not in ZONES_DOULEUR[1:]:
            err.append('painZone inconnue : %r' % spec['painZone'])
        if not (3 <= spec.get('painIntensity', 0) <= 7):
            err.append('painIntensity hors [3 ; 7]')
    bornes = {'capacity': PAR_NOM['capaciteTous'], 'curveB': PAR_NOM['courbeTous'],
              'slope': PAR_NOM['courbeTous'], 'power': PAR_NOM['courbeTous'],
              'fatigueScale': PAR_NOM['fatigueTous']}
    for ex in adv.get('poids_corps', []):
        m = adv['surcharges'].get(ex) or adv['surcharges'].get('*') or {}
        if m.get('capacity', 1.0) < PLANCHER_POIDS_CORPS - 1e-9:
            err.append('%s : capacité ×%r sous le plancher du poids de corps' % (ex, m.get('capacity')))
    for ex, m in adv['surcharges'].items():
        for champ, x in m.items():
            if champ not in bornes:
                err.append('surcharge inconnue : %s.%s' % (ex, champ))
                continue
            d = bornes[champ]
            if not (d.bas - 1e-9 <= x <= d.haut + 1e-9):
                err.append('%s.%s=%r hors [%s ; %s]' % (ex, champ, x, d.bas, d.haut))
    return err


# ---------------------------------------------------------------------------
# Graines : présence le jour J
# ---------------------------------------------------------------------------

def present_le_jour(spec_complete, seed, jour):
    """L'athlète [spec_complete] (fiche fusionnée) est-il présent le jour
    [jour] avec la graine [seed] ? Mêmes tirages que le meneur (Dart et
    Python) : coupure, puis `calendar|jour` < missRate."""
    bf = spec_complete.get('breakFromDay')
    if bf is not None and bf <= jour < bf + (spec_complete.get('breakDays') or 0):
        return False
    miss = spec_complete.get('missRate')
    miss = 0.08 if miss is None else miss
    return not (SimRandom.of(seed, 'calendar|%d' % jour).next() < miss)


def graines_valides(cadre, spec, n, depart=0):
    """Les [n] premières graines (à partir de [depart]) où l'athlète est
    présent à au moins un jour d'échéance (toutes si pas d'échéance).
    Les graines sont communes à tous les adversaires d'une cellule tant que
    la présence le permet (nombres aléatoires communs : comparaisons moins
    bruitées)."""
    complete = dict(cadre.spec_base)
    complete.update(spec)
    out = []
    g = depart
    while len(out) < n:
        if not cadre.echeances or any(present_le_jour(complete, g, j) for j in cadre.echeances):
            out.append(g)
        g += 1
    return out


# ---------------------------------------------------------------------------
# Évaluation d'une saison
# ---------------------------------------------------------------------------

_CHAINE_E1RM = (
    ('loadedMain', lambda e: e['mode'] == 'loaded' and e['main']),
    ('loaded', lambda e: e['mode'] == 'loaded'),
    ('reps', lambda e: e['mode'] == 'reps'),
    ('hold', lambda e: e['mode'] == 'hold'),
)
RANG_E1RM = 6


def erreur_e1rm(tour):
    """(erreur absolue moyenne au rang 6, famille retenue, nombre)."""
    for nom, garder in _CHAINE_E1RM:
        E = mesures.Estimations()
        E.add(tour, garder)
        ligne = E.ligne(RANG_E1RM)
        if ligne is not None:
            return ligne['mae'], nom, ligne['n']
    return None, None, 0


def perf_jour_j(evenements, echeance, present=True):
    """Critère (a) : moyenne de meilleure valeur réussie / max du jour ; 0
    si aucun test réussi ou aucun test ; None sans échéance."""
    if not echeance or not present:
        return None
    ratios = [e[2] / e[4] for e in evenements if e[4]]
    return sum(ratios) / len(ratios) if ratios else 0.0


def blocs_servis(saison, tour):
    """Blocs de la saison où chaque séance faite est remplacée par les items
    que Koach a servis, avec le nombre de séries réellement faites pour les
    exercices modélisés (une rampe de test prescrite à 9 séries n'en compte
    que les séries faites)."""
    jour_de = {}
    for (g, bi, wb, di, sim_day) in saison['sessions']:
        jour_de[(g, bi, wb, di)] = sim_day
    faites = {}
    modelises = set()
    for s in tour.sets:
        modelises.add(s['exerciseId'])
        k = (s['simDay'], s['slotId'], s['exerciseId'])
        faites[k] = faites.get(k, 0) + 1
    blocs = copy.deepcopy(saison['blocks'])
    for (g, bi, wb, di, items) in tour.servi:
        sim_day = jour_de.get((g, bi, wb, di))
        nouveaux = []
        for it in items:
            it = copy.deepcopy(it)
            if it['exerciseId'] in modelises:
                n = faites.get((sim_day, it['slotId'], it['exerciseId']), 0)
                if n == 0:
                    continue
                it['sets'] = n
            nouveaux.append(it)
        for w in blocs[bi]['pass2']['weeks']:
            if w['weekIndex'] == wb:
                for d in w['days']:
                    if d['dayIndex'] == di:
                        d['items'] = nouveaux
    return blocs


def evaluer_saison(travail):
    """Simule une saison conduite par Koach. [travail] : dictionnaire
    {cle, scenario, kind, seed, spec, surcharges}. Renvoie les mesures
    (sérialisables). Une saison qui plante dans Koach compte pour une
    performance 0 et est signalée (`plantage`)."""
    from banc.politique_koach import PolitiqueKoach
    cle, scenario, kind, seed = travail['cle'], travail['scenario'], travail['kind'], travail['seed']
    saison = copy.deepcopy(saison_de(cle, scenario))
    infos = donnees.catalogue_infos()
    echeances = jours_echeance(saison)
    spec_json = dict(saison['specJson'])
    spec_json.update(travail['spec'])
    present = (not echeances) or any(present_le_jour(spec_json, seed, j) for j in echeances)
    sortie = {'seed': seed, 'echeance': bool(echeances), 'present': present, 'plantage': None}
    try:
        tour = meneur.simuler(saison, infos, PolitiqueKoach(), kind, seed,
                              spec_json=spec_json, surcharges=travail['surcharges'])
    except Exception as exc:  # Koach est en cours de modification : on note et on continue.
        sortie.update({
            'plantage': '%s: %s | %s' % (type(exc).__name__, exc,
                                         traceback.format_exc().strip().splitlines()[-3].strip()),
            'perf_a': 0.0 if (echeances and present) else None,
            'evenements': [], 'e1rm6': None, 'e1rm_famille': None, 'e1rm_n': 0,
            'aggravations': 0, 'poussees': 0, 'echecs': None, 'violations': None,
            'codes_violations': {}, 'gain': None, 'faites': 0, 'prevues': 0,
        })
        return sortie
    evs = mesures.evenements(tour)
    mae, famille, n = erreur_e1rm(tour)
    eff = mesures.effort(tour)
    try:
        constats = sb.constats_saison(saison, infos, blocs=blocs_servis(saison, tour))
        codes = {}
        for c in constats:
            codes[c['code']] = codes.get(c['code'], 0) + 1
        nviol = len(constats)
    except Exception:
        codes, nviol = {}, None
    g = mesures.gain_moyen(tour)
    sortie.update({
        'perf_a': _r6(perf_jour_j(evs, bool(echeances), present)),
        'evenements': [[e[0], e[1], _r6(e[2]), _r6(e[4]), _r6(e[2] / e[4]) if e[4] else None] for e in evs],
        'e1rm6': _r6(mae), 'e1rm_famille': famille, 'e1rm_n': n,
        'aggravations': tour.pain_aggravations, 'poussees': tour.pain_flares,
        'echecs': _r6(eff['echecs']), 'violations': nviol, 'codes_violations': codes,
        'gain': _r6(g), 'faites': tour.sessions_done, 'prevues': tour.sessions_planned,
    })
    return sortie


def _evaluer_tous(travaux, processus):
    if processus <= 1 or len(travaux) <= 1:
        return [evaluer_saison(t) for t in travaux]
    from multiprocessing import get_context
    with get_context('fork').Pool(processus) as pool:
        return pool.map(evaluer_saison, travaux, chunksize=1)


def difficulte(saisons, objectif):
    """Difficulté d'un adversaire (à MAXIMISER) à partir de ses saisons :
    objectif (a) → 1 − moyenne des performances le jour J ; (b) → moyenne
    des erreurs d'e1RM au rang 6. Renvoie (difficulte, objectif_effectif)."""
    if objectif == 'a':
        perfs = [s['perf_a'] for s in saisons if s['perf_a'] is not None]
        if perfs:
            return _r6(1.0 - sum(perfs) / len(perfs)), 'a'
    errs = [s['e1rm6'] for s in saisons if s['e1rm6'] is not None]
    # Plantage sans mesure : difficulté maximale de l'échelle (b).
    if any(s['plantage'] for s in saisons) and not errs:
        return 1.0, 'b'
    return (_r6(sum(errs) / len(errs)) if errs else 0.0), 'b'


def _resume(saisons):
    """Mesures de Koach agrégées sur les graines d'un adversaire."""
    def moy(cle):
        xs = [s[cle] for s in saisons if s.get(cle) is not None]
        return _r6(sum(xs) / len(xs)) if xs else None
    perfs = [s['perf_a'] for s in saisons if s['perf_a'] is not None]
    return {
        'perf_a': moy('perf_a'),
        'perf_a_min': _r6(min(perfs)) if perfs else None,
        'e1rm6': moy('e1rm6'),
        'echecs': moy('echecs'),
        'aggravations': sum(s['aggravations'] for s in saisons),
        'poussees': sum(s['poussees'] for s in saisons),
        'violations': (None if any(s['violations'] is None for s in saisons)
                       else sum(s['violations'] for s in saisons)),
        'plantages': [s['plantage'] for s in saisons if s['plantage']],
        'gain': moy('gain'),
        'par_graine': saisons,
    }


# ---------------------------------------------------------------------------
# Recherche
# ---------------------------------------------------------------------------

def _hypercube(rng, n):
    """Hypercube latin de n points dans [0, 1]^D (Fisher-Yates par dimension)."""
    pts = [[0.0] * D for _ in range(n)]
    for j in range(D):
        perm = list(range(n))
        for i in range(n - 1, 0, -1):
            k = int(rng.next() * (i + 1))
            perm[i], perm[k] = perm[k], perm[i]
        for i in range(n):
            pts[i][j] = (perm[i] + rng.next()) / n
    return pts


def _reflechir(x):
    while x < 0 or x > 1:
        x = -x if x < 0 else 2 - x
    return x


def _muter(rng, parent, sigma):
    """Enfant (μ+λ) : bruit gaussien de pas [sigma] sur chaque coordonnée,
    et, avec une probabilité 1/8 par coordonnée, un nouveau tirage uniforme
    (sauts pour les dimensions discrètes : zone, durées)."""
    out = []
    for x in parent:
        if rng.next() < 0.125:
            out.append(rng.next())
        else:
            out.append(_reflechir(x + sigma * rng.gauss()))
    return out


def _adversaire(cadre, u, role, graines):
    spec, surcharges, v = decoder(u, cadre)
    seeds = graines_valides(cadre, spec, graines)
    return {
        'id': identifiant(cadre.cle, cadre.scenario, cadre.kind, spec, surcharges),
        'role': role,
        'key': cadre.cle, 'scenario': cadre.scenario, 'kind': cadre.kind,
        'seeds': seeds,
        'echeance': bool(cadre.echeances),
        'echeances': cadre.echeances,
        'fin_episodes': cadre.fin_episodes,
        'poids_corps': cadre.poids_corps,
        'spec': spec, 'surcharges': surcharges,
        'parametres': v,
        'u': [_r6(x) for x in u],
    }


def _travaux(adv):
    return [{'cle': adv['key'], 'scenario': adv['scenario'], 'kind': adv['kind'], 'seed': g,
             'spec': adv['spec'], 'surcharges': adv['surcharges']} for g in adv['seeds']]


def _evaluer_adversaires(advs, objectif, processus, journal=None):
    travaux = []
    for a in advs:
        travaux += _travaux(a)
    res = _evaluer_tous(travaux, processus)
    k = 0
    for a in advs:
        n = len(a['seeds'])
        saisons = res[k:k + n]
        k += n
        a['koach'] = _resume(saisons)
        a['difficulte'], a['objectif_effectif'] = difficulte(saisons, objectif)
    if journal is not None:
        journal(len(travaux))
    return len(travaux)


def chercher(budget=300, profils=PROFILS_DEFAUT, scenario=SCENARIO_DEFAUT, modeles=MODELES_DEFAUT,
             graines=2, objectif='a', n_pires=32, n_temoins=8, graine=20261009, processus=2,
             bavard=False):
    """Recherche minimax bornée. [budget] : nombre total de saisons simulées
    (témoins compris). Renvoie le dictionnaire du fichier lisible
    (`adversaires_v1.json`), dont `adversaires` = les [n_pires] plus
    difficiles (répartis entre cellules) puis [n_temoins] tirés au hasard."""
    if graines < 2:
        raise ValueError('au moins 2 graines par adversaire')
    if objectif not in ('a', 'b'):
        raise ValueError("objectif : 'a' ou 'b'")
    cadres = [Cadre(c, scenario, k) for c in profils for k in modeles]
    vus = [0]

    def journal(n):
        vus[0] += n
        if bavard:
            sys.stderr.write('  %d saisons simulées\n' % vus[0])

    # Témoins : tirages uniformes dans l'espace, cellules à tour de rôle.
    rng_t = Mulberry32(fnv1a32('%d|temoins' % graine))
    temoins = []
    for i in range(n_temoins):
        u = [rng_t.next() for _ in range(D)]
        temoins.append(_adversaire(cadres[i % len(cadres)], u, 'temoin', graines))
    reste = budget - n_temoins * graines
    par_cellule = reste // len(cadres) // graines   # adversaires par cellule
    if par_cellule < 3:
        raise ValueError('budget trop petit : %d saison(s) pour %d cellule(s) × %d graines'
                         % (budget, len(cadres), graines))
    n0 = max(2, int(math.ceil(par_cellule / 2.0)))
    n_evo = par_cellule - n0
    lam = max(1, int(math.ceil(n_evo / 3.0)))
    mu = max(2, int(math.ceil(n0 / 3.0)))
    rngs = [Mulberry32(fnv1a32('%d|%s' % (graine, c.nom))) for c in cadres]
    populations = [[] for _ in cadres]
    # 1) Tirage initial (hypercube latin) de toutes les cellules, plus les
    # témoins, évalués ensemble.
    lot = []
    for ci, c in enumerate(cadres):
        for u in _hypercube(rngs[ci], n0):
            a = _adversaire(c, u, 'pire', graines)
            a['generation'] = 0
            populations[ci].append(a)
            lot.append(a)
    _evaluer_adversaires(lot + temoins, objectif, processus, journal)
    initial = [max(a['difficulte'] for a in pop) for pop in populations]
    initial_id = [sorted(pop, key=lambda a: (-a['difficulte'], a['id']))[0]['id'] for pop in populations]
    # 2) Évolution (μ+λ) : les μ meilleurs de toute la population de la
    # cellule engendrent λ enfants ; le pas décroît de génération en
    # génération (exploration puis raffinement).
    faits = 0
    gen = 0
    sigma = 0.20
    while faits < n_evo:
        gen += 1
        n = min(lam, n_evo - faits)
        lot = []
        for ci, c in enumerate(cadres):
            # Les témoins de la cellule, déjà évalués, peuvent servir de
            # parents (ils restent des témoins dans l'export).
            locaux = [t for t in temoins if t['key'] == c.cle and t['kind'] == c.kind]
            pop = sorted(populations[ci] + locaux, key=lambda a: (-a['difficulte'], a['id']))
            parents = pop[:mu]
            deja = set(a['id'] for a in populations[ci] + locaux)
            for _ in range(n):
                for _essai in range(8):
                    p = parents[int(rngs[ci].next() * len(parents))]
                    a = _adversaire(c, _muter(rngs[ci], p['u'], sigma), 'pire', graines)
                    if a['id'] not in deja:
                        break
                a['generation'] = gen
                a['parent'] = p['id']
                deja.add(a['id'])
                populations[ci].append(a)
                lot.append(a)
        _evaluer_adversaires(lot, objectif, processus, journal)
        faits += n
        sigma *= 0.7
    # 3) Confirmation : le reste du budget (arrondi de la répartition) ajoute
    # une graine aux adversaires les plus difficiles, cellules à tour de
    # rôle ; leur difficulté est recalculée sur toutes leurs graines (un
    # adversaire chanceux redescend dans le classement).
    reste_final = budget - vus[0]
    if reste_final > 0:
        classes = [sorted(pop, key=lambda a: (-a['difficulte'], a['id'])) for pop in populations]
        ordre = []
        for rang in range(max(len(cl) for cl in classes)):
            for ci, cl in enumerate(classes):
                if rang < len(cl):
                    ordre.append((ci, cl[rang]))
        choisis = ordre[:reste_final]
        travaux = []
        for ci, a in choisis:
            g = graines_valides(cadres[ci], a['spec'], 1, depart=max(a['seeds']) + 1)[0]
            a['seeds'] = a['seeds'] + [g]
            travaux += _travaux(dict(a, seeds=[g]))
        res = _evaluer_tous(travaux, processus)
        journal(len(travaux))
        for (ci, a), s in zip(choisis, res):
            saisons = a['koach']['par_graine'] + [s]
            a['koach'] = _resume(saisons)
            a['difficulte'], a['objectif_effectif'] = difficulte(saisons, objectif)
            a['confirme'] = True
        # Le tirage initial est relu après confirmation (même échelle).
        initial = [max(a['difficulte'] for a in pop if a['generation'] == 0) for pop in populations]
        initial_id = [sorted([a for a in pop if a['generation'] == 0],
                             key=lambda a: (-a['difficulte'], a['id']))[0]['id'] for pop in populations]
    # 4) Les N pires : à tour de rôle entre cellules (les difficultés de deux
    # cellules ne sont pas sur la même échelle quand l'une n'a pas
    # d'échéance), chacune donnant son pire adversaire non encore retenu.
    classes = [sorted(pop, key=lambda a: (-a['difficulte'], a['id'])) for pop in populations]
    pires = []
    rang = 0
    while len(pires) < n_pires and rang < max(len(c) for c in classes):
        for cl in classes:
            if rang < len(cl) and len(pires) < n_pires:
                pires.append(cl[rang])
        rang += 1
    cellules = []
    for ci, c in enumerate(cadres):
        cl = classes[ci]
        cellules.append({
            'cellule': c.nom, 'echeances': c.echeances, 'principaux': c.principaux,
            'evalues': len(cl), 'difficulte_initiale_max': initial[ci],
            'pire_initial': initial_id[ci],
            'difficulte_max': cl[0]['difficulte'], 'objectif_effectif': cl[0]['objectif_effectif'],
            'pire': cl[0]['id'],
            'plantages': sum(len(a['koach']['plantages']) for a in cl),
        })
    plantages = []
    for pop in populations:
        for a in pop:
            for g, s in zip(a['seeds'], a['koach']['par_graine']):
                if s['plantage']:
                    plantages.append({'id': a['id'], 'key': a['key'], 'scenario': a['scenario'],
                                      'kind': a['kind'], 'seed': g, 'spec': a['spec'],
                                      'surcharges': a['surcharges'], 'erreur': s['plantage']})
    for a in temoins:
        for g, s in zip(a['seeds'], a['koach']['par_graine']):
            if s['plantage']:
                plantages.append({'id': a['id'], 'key': a['key'], 'scenario': a['scenario'],
                                  'kind': a['kind'], 'seed': g, 'spec': a['spec'],
                                  'surcharges': a['surcharges'], 'erreur': s['plantage']})
    return {
        'schema': SCHEMA,
        'version': VERSION,
        'recherche': {
            'budget': budget, 'saisons_simulees': vus[0], 'graines_par_adversaire': graines,
            'objectif': objectif, 'graine': graine, 'scenario': scenario,
            'profils': list(profils), 'modeles': modeles,
            'adversaires_par_cellule': par_cellule, 'tirage_initial': n0, 'mu': mu, 'lambda': lam,
            'generations': gen, 'n_pires': n_pires, 'n_temoins': n_temoins,
            'recul_echeance_jours': RECUL_ECHEANCE,
        },
        'espace': [{'nom': d.nom, 'bas': d.bas, 'haut': d.haut, 'echelle': d.echelle,
                    'nominal': d.nominal, 'raison': d.raison} for d in DIMENSIONS],
        'cellules': cellules,
        'plantages': plantages,
        'adversaires': pires + temoins,
    }


# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

def _dumps(obj):
    return json.dumps(obj, sort_keys=True, ensure_ascii=False, indent=1) + '\n'


def entrees_dart(adversaires):
    """Entrées de `kmAdversaryRun` : une par adversaire et par graine,
    `{"id", "key", "scenario", "kind", "seed", "spec", "surcharges"}` ;
    l'identifiant est `<id de l'adversaire>-g<graine>`."""
    out = []
    for a in adversaires:
        for g in a['seeds']:
            out.append({'id': '%s-g%d' % (a['id'], g), 'key': a['key'], 'scenario': a['scenario'],
                        'kind': a['kind'], 'seed': g, 'spec': a['spec'],
                        'surcharges': a['surcharges']})
    return out


def ecrire_adversaires(chemin, adversaires):
    """Écrit le fichier d'entrée de l'outil Dart (`adversaires.json`, liste
    d'objets lus par `_runKm1Tools` puis `kmAdversaryRun`)."""
    if isinstance(adversaires, dict):
        adversaires = adversaires['adversaires']
    d = os.path.dirname(os.path.abspath(chemin))
    if not os.path.isdir(d):
        os.makedirs(d)
    with open(chemin, 'w', encoding='utf-8') as f:
        f.write(_dumps(entrees_dart(adversaires)))


def ecrire_lisible(chemin, resultat):
    with open(chemin, 'w', encoding='utf-8') as f:
        f.write(_dumps(resultat))


def lire_adversaires(chemin):
    with open(chemin, encoding='utf-8') as f:
        j = json.load(f)
    return j['adversaires'] if isinstance(j, dict) else j


def rejouer(adv, seed, garder_tour=False):
    """Rejoue la saison d'un adversaire exporté avec Koach (même chemin que
    `evaluer_saison`) ; renvoie le `Tour`."""
    from banc.politique_koach import PolitiqueKoach
    saison = copy.deepcopy(saison_de(adv['key'], adv['scenario']))
    spec_json = dict(saison['specJson'])
    spec_json.update(adv['spec'])
    return meneur.simuler(saison, donnees.catalogue_infos(), PolitiqueKoach(), adv['kind'], seed,
                          spec_json=spec_json, surcharges=adv['surcharges'])


# ---------------------------------------------------------------------------
# Comparaison avec le témoin Dart
# ---------------------------------------------------------------------------

def _lire_dart(sortie_dart):
    if isinstance(sortie_dart, list):
        return sortie_dart
    ouvrir = gzip.open if sortie_dart.endswith('.gz') else open
    with ouvrir(sortie_dart, 'rt', encoding='utf-8') as f:
        return json.load(f)


def _e1rm_dart(estimates):
    """Erreur absolue moyenne au rang 6 du témoin (`KmEstimateStats` :
    `bySession[k]` = [n, Σ|err|, Σerr, Σerr², n<3 %, n couverts]), même
    chaîne de familles que Koach."""
    for nom, _ in _CHAINE_E1RM:
        e = (estimates or {}).get(nom)
        if not e:
            continue
        rows = e.get('bySession') or []
        if len(rows) > RANG_E1RM and rows[RANG_E1RM][0] > 0:
            r = rows[RANG_E1RM]
            return r[1] / r[0], nom
    return None, None


def mesures_dart(entree, echeance, present):
    """Mesures d'une saison du témoin (élément de
    `adversaires_temoin.json.gz`)."""
    run = entree['run']
    ratios = []
    for e in run.get('events') or []:
        best, day_max = e[3], e[5]
        if day_max:
            ratios.append(best / day_max)
    perf = None
    if echeance and present:
        perf = sum(ratios) / len(ratios) if ratios else 0.0
    mae, famille = _e1rm_dart(entree.get('estimates'))
    return {'seed': entree.get('seed'), 'perf_a': _r6(perf), 'e1rm6': _r6(mae), 'e1rm_famille': famille,
            'aggravations': run.get('painAggravations', 0), 'poussees': run.get('painFlares', 0),
            'violations': run.get('violations', 0), 'codes_violations': run.get('violationCodes') or {},
            'gain': run.get('gainMean')}


def _stat(valeurs):
    xs = [x for x in valeurs if x is not None]
    if not xs:
        return {'n': 0, 'moyenne': None, 'pire': None}
    return {'n': len(xs), 'moyenne': _r6(sum(xs) / len(xs)), 'pire': _r6(min(xs))}


def _stat_max(valeurs):
    xs = [x for x in valeurs if x is not None]
    if not xs:
        return {'n': 0, 'moyenne': None, 'pire': None}
    return {'n': len(xs), 'moyenne': _r6(sum(xs) / len(xs)), 'pire': _r6(max(xs))}


def comparer(adversaires, sortie_dart, rejouer_koach=True, processus=2):
    """Compare Koach (rejoué en Python, ou mesures stockées si
    [rejouer_koach] est faux) et le témoin (sortie Dart) sur les mêmes
    adversaires. [adversaires] : liste (ou chemin du fichier lisible) ;
    [sortie_dart] : chemin de `adversaires_temoin.json.gz` (ou liste déjà
    lue). Renvoie un dictionnaire sérialisable."""
    if isinstance(adversaires, str):
        adversaires = lire_adversaires(adversaires)
    dart = {e['id']: e for e in _lire_dart(sortie_dart)}
    if rejouer_koach:
        travaux = []
        for a in adversaires:
            travaux += _travaux(a)
        res = _evaluer_tous(travaux, processus)
    lignes = []
    k = 0
    for a in adversaires:
        if rejouer_koach:
            saisons = res[k:k + len(a['seeds'])]
            k += len(a['seeds'])
        else:
            saisons = a['koach']['par_graine']
        rk = _resume(saisons)
        temoin = []
        manquants = []
        for g, s in zip(a['seeds'], saisons):
            e = dart.get('%s-g%d' % (a['id'], g))
            if e is None:
                manquants.append(g)
                continue
            temoin.append(mesures_dart(e, a['echeance'], s['present']))
        perfs_t = [t['perf_a'] for t in temoin if t['perf_a'] is not None]
        errs_t = [t['e1rm6'] for t in temoin if t['e1rm6'] is not None]
        lignes.append({
            'id': a['id'], 'role': a.get('role'), 'key': a['key'], 'scenario': a['scenario'],
            'kind': a['kind'], 'seeds': a['seeds'], 'echeance': a['echeance'],
            'koach': {kk: rk[kk] for kk in ('perf_a', 'perf_a_min', 'e1rm6', 'echecs', 'aggravations',
                                            'poussees', 'violations', 'plantages')},
            'temoin': {
                'perf_a': _r6(sum(perfs_t) / len(perfs_t)) if perfs_t else None,
                'perf_a_min': _r6(min(perfs_t)) if perfs_t else None,
                'e1rm6': _r6(sum(errs_t) / len(errs_t)) if errs_t else None,
                'aggravations': sum(t['aggravations'] for t in temoin),
                'poussees': sum(t['poussees'] for t in temoin),
                'violations': sum(t['violations'] for t in temoin),
                'manquants': manquants,
            },
        })

    def synthese(sel):
        return {
            'n': len(sel),
            'perf_a': {'koach': _stat([l['koach']['perf_a'] for l in sel]),
                       'temoin': _stat([l['temoin']['perf_a'] for l in sel])},
            'perf_a_par_saison': {'koach': _stat([l['koach']['perf_a_min'] for l in sel]),
                                  'temoin': _stat([l['temoin']['perf_a_min'] for l in sel])},
            'e1rm6': {'koach': _stat_max([l['koach']['e1rm6'] for l in sel]),
                      'temoin': _stat_max([l['temoin']['e1rm6'] for l in sel])},
            'securite': {
                'koach': {'aggravations': sum(l['koach']['aggravations'] for l in sel),
                          'poussees': sum(l['koach']['poussees'] for l in sel),
                          'violations_indicatives': sum(l['koach']['violations'] or 0 for l in sel),
                          'plantages': sum(len(l['koach']['plantages']) for l in sel)},
                'temoin': {'aggravations': sum(l['temoin']['aggravations'] for l in sel),
                           'poussees': sum(l['temoin']['poussees'] for l in sel),
                           'violations': sum(l['temoin']['violations'] for l in sel)},
            },
        }
    groupes = {
        'tous': synthese(lignes),
        'pires': synthese([l for l in lignes if l['role'] == 'pire']),
        'temoins': synthese([l for l in lignes if l['role'] == 'temoin']),
    }
    pk = groupes['tous']['perf_a']['koach']['pire']
    pt = groupes['tous']['perf_a']['temoin']['pire']
    return {
        'schema': SCHEMA,
        'adversaires': lignes,
        'groupes': groupes,
        'critere': {
            'libelle': 'pire cas de Koach >= pire cas du témoin (performance le jour J, moyenne par adversaire)',
            'pire_koach': pk, 'pire_temoin': pt,
            'respecte': None if (pk is None or pt is None) else bool(pk >= pt - 1e-12),
            'saisons_temoin_manquantes': sum(len(l['temoin']['manquants']) for l in lignes),
        },
    }


# ---------------------------------------------------------------------------
# Ligne de commande
# ---------------------------------------------------------------------------

def _resume_texte(res, n=10):
    lignes = []
    r = res['recherche']
    lignes.append('saisons simulées : %d (budget %d), %d adversaires par cellule, %d générations'
                  % (r['saisons_simulees'], r['budget'], r['adversaires_par_cellule'], r['generations']))
    for c in res['cellules']:
        lignes.append('  %-60s initial %.4f -> %.4f (%s)%s'
                      % (c['cellule'], c['difficulte_initiale_max'], c['difficulte_max'],
                         c['objectif_effectif'], ('  plantages %d' % c['plantages']) if c['plantages'] else ''))
    pires = sorted([a for a in res['adversaires'] if a['role'] == 'pire'],
                   key=lambda a: (a['objectif_effectif'], -a['difficulte'], a['id']))
    lignes.append('pires adversaires :')
    for a in pires[:n]:
        k = a['koach']
        lignes.append('  %s %s %s %s d=%.4f perf_a=%s e1rm6=%s aggr=%d pouss=%d echecs=%s'
                      % (a['id'], a['key'][:22], a['kind'], a['objectif_effectif'], a['difficulte'],
                         k['perf_a'], k['e1rm6'], k['aggravations'], k['poussees'], k['echecs']))
    return '\n'.join(lignes)


def main(argv=None):
    p = argparse.ArgumentParser(prog='python3 -m banc.adversaire',
                                description='Banc adversarial de Koach (KM1, brique 4).')
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument('--chercher', action='store_true', help='lance la recherche minimax bornée')
    g.add_argument('--comparer', metavar='SORTIE_DART', help='adversaires_temoin.json.gz du témoin')
    p.add_argument('--budget', type=int, default=300, help='saisons simulées au total (défaut 300)')
    p.add_argument('--sortie', default=SORTIE_DEFAUT, help='fichier lisible (adversaires_v1.json)')
    p.add_argument('--entree-dart', default=None, help='fichier d\'entrée Dart (adversaires.json)')
    p.add_argument('--objectif', choices=('a', 'b'), default='a')
    p.add_argument('--graines', type=int, default=2)
    p.add_argument('--n-pires', type=int, default=32)
    p.add_argument('--temoins', type=int, default=8)
    p.add_argument('--profils', default=','.join(PROFILS_DEFAUT))
    p.add_argument('--scenario', default=SCENARIO_DEFAUT)
    p.add_argument('--modeles', default=MODELES_DEFAUT)
    p.add_argument('--graine', type=int, default=20261009)
    p.add_argument('--processus', type=int, default=2)
    p.add_argument('--adversaires', default=SORTIE_DEFAUT, help='(--comparer) fichier lisible relu')
    p.add_argument('--sans-rejeu', action='store_true', help='(--comparer) mesures de Koach stockées')
    p.add_argument('--rapport', default=None, help='(--comparer) écrit la comparaison en JSON')
    a = p.parse_args(argv)
    if a.chercher:
        res = chercher(budget=a.budget, profils=tuple(a.profils.split(',')), scenario=a.scenario,
                       modeles=a.modeles, graines=a.graines, objectif=a.objectif, n_pires=a.n_pires,
                       n_temoins=a.temoins, graine=a.graine, processus=a.processus, bavard=True)
        ecrire_lisible(a.sortie, res)
        if a.entree_dart:
            ecrire_adversaires(a.entree_dart, res['adversaires'])
        print(_resume_texte(res))
        if res['plantages']:
            print('PLANTAGES DE KOACH : %d saison(s), voir « plantages » dans %s'
                  % (len(res['plantages']), a.sortie))
        return 0
    cmp_ = comparer(a.adversaires, a.comparer, rejouer_koach=not a.sans_rejeu, processus=a.processus)
    if a.rapport:
        ecrire_lisible(a.rapport, cmp_)
    for nom, gsyn in cmp_['groupes'].items():
        pa = gsyn['perf_a']
        print('%-8s n=%d  jour J koach moy %s pire %s | témoin moy %s pire %s'
              % (nom, gsyn['n'], pa['koach']['moyenne'], pa['koach']['pire'],
                 pa['temoin']['moyenne'], pa['temoin']['pire']))
    print('critère :', json.dumps(cmp_['critere'], ensure_ascii=False))
    return 0


if __name__ == '__main__':
    sys.exit(main())
