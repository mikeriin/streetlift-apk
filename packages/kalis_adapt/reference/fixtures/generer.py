# -*- coding: utf-8 -*-
"""Fixtures de parité de Koach 1.0 (lot KM1) pour le portage Dart (lot KM2,
parité à 1e-9).

    python3 fixtures/generer.py              # écrit les fichiers
    python3 fixtures/generer.py --verifier   # échoue s'ils ne sont pas à jour

(depuis `packages/kalis_adapt/reference/`). Tout est régénéré par cette
commande, sans retouche manuelle et sans valeur codée en dur qui dépende du
fichier de paramètres : le moteur ou les paramètres changent, on relance la
commande. Format détaillé : `fixtures/README.md`.

Fichiers écrits dans `fixtures/` :

* `numerique.json` : cas d'entrée/sortie des outils numériques
  (`koach/numerique.py`) ;
* `moteur_<n>.json` : scénarios tirés du banc (saisons de référence, athlète
  simulé), avec le JOURNAL complet du moteur (`Koach.journal` : événements
  versés à `observe` et appels de `plan` journalisés sous forme canonique) et
  les sorties attendues (sortie et raisons de chaque `plan`, instantanés de
  `posterior()`, état final) ;
* `planification_<n>.json` : un journal de moteur, le plan de référence
  réduit et la sortie de `Planification.replanifier`, avec les tirages
  intermédiaires (1 : avec échéance et cible ; 2 : sans).

Codage JSON : compact, clés triées, flottants en `repr` Python (le plus court
qui relit le même double, 17 chiffres significatifs au plus : sans perte).
Les flottants non finis des SORTIES sont codés par les chaînes "inf", "-inf"
et "nan" (JSON n'en a pas) ; les entrées versées au moteur sont du JSON pur
(un non-fini y est refusé).
"""
import argparse
import copy
import hashlib
import json
import math
import os
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.dirname(ICI)
if RACINE not in sys.path:
    sys.path.insert(0, RACINE)

import numpy as np  # noqa: E402

from banc import meneur  # noqa: E402
from banc import validation_koach as vk  # noqa: E402
from banc.planification_banc import cibles_du_profil, echeance_de, principaux_de  # noqa: E402
from banc.politique_koach import PolitiqueKoach, params as params_banc, vecteurs  # noqa: E402
from koach import VERSION  # noqa: E402
from koach import numerique as nu  # noqa: E402
from koach.modele import RHO, EPS, CLASSES  # noqa: E402
from koach.moteur import Koach  # noqa: E402
from koach.planification import Planification, GRILLE_INTENSITE  # noqa: E402
from koach.rupture import importer_parametres  # noqa: E402
from koach.seance import Grille  # noqa: E402

VERSION_FORMAT = 2
TOLERANCE = 1e-9
FICHIER_PARAMS = os.path.join(RACINE, 'params', 'koach_params_v1.json')
COMMANDE = 'python3 fixtures/generer.py'

# ----------------------------------------------------------------------
# Scénarios des fixtures du moteur (tirés du banc, déterministes)
# ----------------------------------------------------------------------
# Champs : cle/scenario/verite/graine/semaines (saison de référence du banc,
# tronquée), series (instantané après chaque série), spec (champs de la fiche
# d'athlète remplacés), parametres_apres_semaine (import d'un fichier de
# paramètres après la fin de cette semaine, événement `parametres`),
# bilan_bas (séances, par rang 0, dont le bilan versé au moteur est forcé au
# palier 2), bilan_bas_tests (bilan forcé au palier 2 aussi aux séances dont
# l'écrit contient un test : test reporté), techniques (aux séances à bilan
# forcé, techniques intensives substituées à celles de l'écrit, à tour de
# rôle : règles A9.2). Ces retouches ne touchent que ce que reçoit le moteur
# (l'athlète simulé du banc n'en sait rien) ; le journal les porte.
SCENARIOS = [
    {'n': 1, 'titre': 'Avancé chargé (streetlifting), instantané après chaque série',
     'cle': 'street_07_avance_streetlifting_competition', 'scenario': 'reference',
     'verite': 'a', 'graine': 0, 'semaines': 1, 'series': True},
    {'n': 2, 'titre': 'Débutant complet (poids du corps, répétitions), import de paramètres',
     'cle': 'street_01_debutant_complet', 'scenario': 'reference',
     'verite': 'b', 'graine': 1, 'semaines': 2, 'parametres_apres_semaine': 0},
    {'n': 3, 'titre': 'Intermédiaire calisthénie : tenues (front lever) et lest',
     'cle': 'street_05_inter_calisthenie_front_lever', 'scenario': 'reference',
     'verite': 'c', 'graine': 2, 'semaines': 2},
    {'n': 4, 'titre': 'Douleur au coude (5/10) avancée au jour 4, pendant 6 jours',
     'cle': 'autres_03_powerlifter_competition', 'scenario': 'douleur_coude',
     'verite': 'a', 'graine': 3, 'semaines': 2,
     'spec': {'painFromDay': 4, 'painDays': 6}},
    {'n': 5, 'titre': 'Hybride street et course (pistes cardio)',
     'cle': 'street_17_hybride_street_course', 'scenario': 'reference',
     'verite': 'b', 'graine': 4, 'semaines': 2},
    {'n': 6, 'titre': 'Antécédent au coude (zone fragile), coupure de 15 jours, semaine de décharge, '
                      'test écrit un jour de bilan bas',
     'cle': 'street_12_antecedent_coude', 'scenario': 'seances_manquees',
     'verite': 'a', 'graine': 5, 'semaines': 6,
     'spec': {'missRate': 0.0, 'breakFromDay': 8, 'breakDays': 15}, 'bilan_bas_tests': True},
    {'n': 7, 'titre': 'Douleur au poignet (5/10) du jour 4 au jour 11 : appui neutre, dose du poignet',
     'cle': 'street_13_peu_de_temps', 'scenario': 'douleur_coude',
     'verite': 'b', 'graine': 0, 'semaines': 3,
     'spec': {'painZone': 'wrist_hand', 'painFromDay': 4, 'painDays': 8}},
    {'n': 8, 'titre': 'Conditionnement (crossfit), bilans au palier 2 et techniques intensives',
     'cle': 'autres_08_crossfit_intermediaire', 'scenario': 'reference',
     'verite': 'c', 'graine': 7, 'semaines': 2,
     'bilan_bas': [0, 1, 3, 5, 7], 'techniques': ['drop_set', 'myo_reps']},
    {'n': 9, 'titre': 'Hypertrophie : surmenage d\'un mouvement principal, arrêt d\'exercice après échecs',
     'cle': 'autres_02_hypertrophie_intermediaire', 'scenario': 'maladie',
     'verite': 'b', 'graine': 0, 'semaines': 7},
    {'n': 10, 'titre': 'Semi-marathon : douleur qui dure (course retirée), bilans au palier 2 '
                       '(course raccourcie ou retirée)',
     'cle': 'autres_06_semi_marathon_intermediaire', 'scenario': 'reference',
     'verite': 'a', 'graine': 0, 'semaines': 4, 'bilan_bas': [2, 5, 8, 11]},
]

PLANIFICATIONS = [
    # Échéance et cible : objectif = P(cible atteinte le jour J), plan
    # retenu différent de la référence.
    {'n': 1, 'cle': 'street_16_specialisation_traction_lestee', 'scenario': 'reference',
     'verite': 'a', 'graine': 5, 'semaines': 2, 'trajectoires': 200},
    # Sans échéance ni cible : progression attendue × P(continuer), échelle
    # de la référence.
    {'n': 2, 'cle': 'autres_02_hypertrophie_intermediaire', 'scenario': 'reference',
     'verite': 'b', 'graine': 6, 'semaines': 1, 'trajectoires': 100},
]

# Raisons que l'ensemble des fixtures du moteur doit couvrir (le test le
# vérifie ; l'en-tête de chaque fixture donne son compteur).
RAISONS_EXIGEES = ('koach.douleur_retrait', 'koach.douleur_persistante', 'koach.zone_fragile',
                   'koach.reprise_coupure', 'koach.vrai_test', 'koach.test_reporte',
                   'koach.poignet_dose', 'koach.poignet_appui_neutre', 'koach.tendon',
                   'koach.serie_repere', 'koach.technique_retenue', 'koach.endurance_raccourcie',
                   'koach.course_bornee', 'koach.wod_echelle', 'koach.surmenage',
                   'koach.arret_exercice', 'koach.endurance_retrait')

# Champs d'une prescription lus par `Planification` (sans validateur).
CHAMPS_ITEM_PLANIFICATION = ('slotId', 'exerciseId', 'kind', 'sets', 'targetFlames', 'test',
                             'repsLow', 'repsHigh', 'secondsLow', 'secondsHigh',
                             'percentOfOneRm', 'technique')


# ----------------------------------------------------------------------
# Codage JSON
# ----------------------------------------------------------------------
def propre(x, strict=False):
    """Valeur JSON pure : tuples -> listes, scalaires numpy -> Python, Grille
    -> {pas, minimum, halteres}, ensembles -> listes triées, non-finis ->
    "inf"/"-inf"/"nan" (refusés si [strict])."""
    if x is None or isinstance(x, (bool, str)):
        return x
    if isinstance(x, np.bool_):
        return bool(x)
    if isinstance(x, (int, np.integer)):
        return int(x)
    if isinstance(x, (float, np.floating)):
        f = float(x)
        if math.isfinite(f):
            return f
        if strict:
            raise ValueError('flottant non fini dans une entrée du moteur : %r' % (f,))
        if math.isnan(f):
            return 'nan'
        return 'inf' if f > 0 else '-inf'
    if isinstance(x, dict):
        out = {}
        for k, v in x.items():
            if isinstance(k, (bool, np.bool_)) or not isinstance(k, (str, int, np.integer)):
                raise TypeError('clé non textuelle : %r' % (k,))
            out[str(k)] = propre(v, strict)
        return out
    if isinstance(x, (list, tuple)):
        return [propre(v, strict) for v in x]
    if isinstance(x, (set, frozenset)):
        return [propre(v, strict) for v in sorted(x)]
    if isinstance(x, np.ndarray):
        return propre(x.tolist(), strict)
    if isinstance(x, Grille):
        return {'pas': propre(x.pas, strict), 'minimum': propre(x.minimum, strict),
                'halteres': bool(x.halteres)}
    raise TypeError('valeur non codable : %r' % (type(x),))


def texte(obj):
    return json.dumps(obj, sort_keys=True, separators=(',', ':'), ensure_ascii=False,
                      allow_nan=False) + '\n'


def copie_json(x):
    """Copie profonde passée par le JSON (entrées du moteur : strict)."""
    return json.loads(json.dumps(propre(x, strict=True), allow_nan=False))


def decoder_flottant(v):
    """Inverse du codage des non-finis."""
    if v == 'inf':
        return math.inf
    if v == '-inf':
        return -math.inf
    if v == 'nan':
        return math.nan
    return v


def empreinte(obj):
    """SHA-256 du texte canonique (fonction `texte`) d'une valeur JSON."""
    return hashlib.sha256(texte(obj).encode('utf-8')).hexdigest()


def empreinte_fichier(chemin):
    with open(chemin, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()


# ----------------------------------------------------------------------
# Enveloppes : moteur enregistré, fiches espionnées, politique du banc
# ----------------------------------------------------------------------
class FichesEspion(dict):
    """Fiches du catalogue qui retiennent les identifiants lus par le
    moteur (les fixtures n'embarquent que celles-là). Le moteur ne lit les
    fiches que par `get`, `[]` et `in` ; toute énumération est refusée."""

    def __init__(self, d):
        dict.__init__(self, d)
        self.lus = set()

    def get(self, k, defaut=None):
        self.lus.add(k)
        return dict.get(self, k, defaut)

    def __getitem__(self, k):
        self.lus.add(k)
        return dict.__getitem__(self, k)

    def __contains__(self, k):
        self.lus.add(k)
        return dict.__contains__(self, k)

    def _refus(self, *a, **k):
        raise RuntimeError('énumération des fiches : la réduction des fixtures ne vaut plus')

    __iter__ = keys = items = values = _refus

    def reduites(self):
        return {k: dict.__getitem__(self, k) for k in sorted(self.lus) if dict.__contains__(self, k)}


def diagnostic(k):
    """Vecteur d'état et diagonale de la covariance (aide au portage)."""
    m = k.modele
    return {'n': int(m.n), 'm': propre(m.m[:m.n]), 'P_diag': propre(np.diag(m.P)[:m.n]),
            'ordre': list(m.ordre)}


def fichier_parametres_derive(params):
    """Fichier de paramètres importé en cours de scénario (événement
    `parametres`) : constantes de temps de fatigue nerveuse et musculaire
    portées au haut de leur grille de réestimation. Dérivé du fichier en
    vigueur (aucune valeur codée en dur)."""
    f = copy.deepcopy(params['fatigue'])
    f['tau_nerveux_j'] = f['grille_tau_nerveux'][-1]
    f['tau_musculaire_j'] = f['grille_tau_musculaire'][-1]
    return {'schema': params['schema'], 'version': str(params['version']) + '+fixture',
            'fatigue': f}


class KoachEnregistre(Koach):
    """`Koach` qui retient ses entrées telles qu'il les reçoit (copies JSON
    prises à l'appel : le journal de la fixture) et les sorties attendues."""

    def __init__(self, params, fiches, profil, sc):
        Koach.__init__(self, params, fiches, profil)
        self.sc = sc
        self.entrees = []          # copies JSON prises à l'appel
        self.plans = []            # {indice, sortie, raisons}
        self.instantanes = []      # {indice, posterior[, diagnostic]}
        self.n_seances = -1
        self.bas = False
        self.test_ecrit = False    # l'écrit de la séance qui s'ouvre contient un test
        self.n_techniques = 0
        self.semaines_faites = 0

    # Retouches (scénario 8) -------------------------------------------
    def _retouche_bilan(self, e):
        self.n_seances += 1
        self.bas = self.n_seances in (self.sc.get('bilan_bas') or ()) or \
            bool(self.sc.get('bilan_bas_tests') and self.test_ecrit)
        if not self.bas:
            return e
        e = copy.deepcopy(e)
        b = dict(e.get('bilan') or {})
        b['overall'] = 1
        b['energy'] = 2
        b['sleepQuality'] = 2
        e['bilan'] = b
        return e

    def _retouche_techniques(self, c):
        techniques = self.sc.get('techniques')
        if not (self.bas and techniques):
            return c
        for it in c.get('items') or []:
            t = it.get('technique')
            if t and t.get('kind') not in (None, 'standard'):
                t = dict(t)
                t['kind'] = techniques[self.n_techniques % len(techniques)]
                it['technique'] = t
                self.n_techniques += 1
        return c

    # Façade -------------------------------------------------------------
    def observe(self, e):
        recu = copie_json(e)
        if recu['type'] == 'seance_debut':
            recu = self._retouche_bilan(recu)
        self.entrees.append(copie_json(recu))
        i = len(self.journal)
        Koach.observe(self, recu)
        typ = recu['type']
        if typ in ('seance_fin', 'semaine_fin') or (typ == 'serie' and self.sc.get('series')):
            inst = {'indice': i, 'posterior': propre(self.posterior())}
            if typ == 'semaine_fin':
                inst['diagnostic'] = diagnostic(self)
            self.instantanes.append(inst)
        if typ == 'semaine_fin':
            self.semaines_faites += 1
            if self.sc.get('parametres_apres_semaine') == self.semaines_faites - 1:
                r = importer_parametres(self, fichier_parametres_derive(self.params))
                if not r['ok']:
                    raise RuntimeError('import de paramètres refusé : %r' % (r['erreurs'],))
        return None

    def plan(self, c):
        cj = copie_json(Koach._canonique(c))
        if cj.get('horizon') == 'seance':
            cj = self._retouche_techniques(cj)
        self.entrees.append({'type': 'plan', 'contraintes': copie_json(cj)})
        i = len(self.journal)
        out = Koach.plan(self, cj)
        self.plans.append({'indice': i, 'sortie': propre(out), 'raisons': propre(self.explain())})
        return out


class PolitiqueEnregistree(PolitiqueKoach):
    """`PolitiqueKoach` du banc dont le moteur est remplacé, juste après
    `debut`, par un `KoachEnregistre` (mêmes paramètres, fiches espionnées,
    profil passé par le JSON). Sans extension : seul le moteur est figé."""

    nom = 'koach_1_0_fixtures'

    def __init__(self, sc):
        PolitiqueKoach.__init__(self, parametres=copie_json(params_banc()))
        self.sc = sc
        self.espion = None

    def debut(self, saison, profil, livre):
        PolitiqueKoach.debut(self, saison, profil, livre)
        self.espion = FichesEspion(vecteurs())
        self.koach = KoachEnregistre(self.parametres, self.espion, copie_json(self.koach.profil), self.sc)

    def planifier(self, ctx):
        self.koach.test_ecrit = any(it.get('kind') == 'test' for it in ctx.ecrit['items'])
        return PolitiqueKoach.planifier(self, ctx)


def conduire(sc):
    """Conduit les [semaines] premières semaines de la saison de référence."""
    saison = dict(vk.saison(sc['cle'], sc['scenario']))
    saison['weeks'] = sc['semaines']
    spec_json = None
    if sc.get('spec'):
        spec_json = dict(saison['specJson'])
        spec_json.update(sc['spec'])
    pol = PolitiqueEnregistree(sc)
    tour = meneur.simuler(saison, vk.infos(), pol, sc['verite'], sc['graine'], spec_json=spec_json)
    k = pol.koach
    # Le journal du moteur doit être exactement ce qu'il a reçu : une entrée
    # modifiée après coup par le moteur (mutation en place) rendrait le rejeu
    # faux. Le journal de la fixture est celui des copies prises à l'appel.
    if copie_json(k.journal) != k.entrees:
        ecart = next(i for i, (a, b) in enumerate(zip(copie_json(k.journal), k.entrees)) if a != b)
        raise RuntimeError('journal du moteur modifié après coup (entrée %d)' % ecart)
    return saison, pol, tour


def couverture(k):
    """Compteurs : événements du journal par type, raisons `explain()` après
    chaque `plan` par code et par (code, cause)."""
    evenements = {}
    for e in k.entrees:
        evenements[e['type']] = evenements.get(e['type'], 0) + 1
    raisons = {}
    causes = {}
    for p in k.plans:
        for r in p['raisons']:
            c = r['code']
            raisons[c] = raisons.get(c, 0) + 1
            cause = (r.get('params') or {}).get('cause')
            if cause is not None:
                d = causes.setdefault(c, {})
                d[str(cause)] = d.get(str(cause), 0) + 1
    genres = {}
    for e in k.entrees:
        if e['type'] == 'seance_debut':
            g = str((e.get('contexte') or {}).get('genre'))
            genres[g] = genres.get(g, 0) + 1
    douleurs = sum(1 for e in k.entrees if e['type'] == 'seance_fin' and e.get('douleurs')) + \
        sum(1 for e in k.entrees if e['type'] == 'seance_debut' and (e.get('bilan') or {}).get('pains'))
    return {'evenements': evenements, 'raisons': raisons, 'causes': causes,
            'genres_semaine': genres, 'evenements_avec_douleur': douleurs,
            'zones_fragiles_profil': len(k.profil.get('zones_fragiles') or [])}


def entete(nature, titre, params):
    return {'format': 'koach-parite-' + nature, 'nature': nature, 'version_format': VERSION_FORMAT,
            'version_moteur': VERSION, 'titre': titre,
            'version_parametres': params.get('version') if params else None,
            'sha256_parametres': empreinte(params) if params else None,
            'sha256_fichier_parametres': empreinte_fichier(FICHIER_PARAMS) if params else None,
            'tolerance': TOLERANCE,
            'comparaison': 'Python : identique ; portage : nombres |a - b| <= tolerance * max(1, |a|, |b|), '
                           'reste à l\'identique',
            'codage': 'flottants en repr Python (sans perte) ; non finis : chaînes "inf", "-inf", "nan"',
            'commande': COMMANDE}


# ----------------------------------------------------------------------
# moteur_<n>.json
# ----------------------------------------------------------------------
def fixture_moteur(sc):
    saison, pol, tour = conduire(sc)
    k = pol.koach
    out = entete('moteur', sc['titre'], pol.parametres)
    out.update({
        'source': {'profil': sc['cle'], 'scenario': sc['scenario'], 'verite': sc['verite'],
                   'graine': sc['graine'], 'semaines': sc['semaines'],
                   'spec_remplacee': sc.get('spec'), 'instantanes_par_serie': bool(sc.get('series')),
                   'parametres_apres_semaine': sc.get('parametres_apres_semaine'),
                   'bilan_bas_seances': sc.get('bilan_bas'), 'bilan_bas_tests': bool(sc.get('bilan_bas_tests')),
                   'techniques_substituees': sc.get('techniques'),
                   'seances_faites': tour.sessions_done, 'seances_prevues': tour.sessions_planned},
        'couverture': couverture(k),
        'entrees': {
            'params': pol.parametres,
            'fiches': pol.espion.reduites(),
            'profil': k.profil,
            'journal': k.entrees,
        },
        'attendu': {
            'plans': k.plans,
            'instantanes': k.instantanes,
            'final': {'posterior': propre(k.posterior()), 'raisons': propre(k.explain()),
                      'diagnostic': diagnostic(k), 'longueur_journal': len(k.journal),
                      'sha256_parametres_finaux': empreinte(k.params)},
        },
    })
    return propre(out)


# ----------------------------------------------------------------------
# planification_<n>.json
# ----------------------------------------------------------------------
def blocs_reduits(blocs):
    """Plan de référence réduit à ce que `Planification` lit sans
    validateur : semaines de pass2 (indice, nature, intention) et items."""
    out = []
    for b in blocs:
        semaines = []
        for w in b['pass2']['weeks']:
            jours = []
            for d in w['days']:
                items = [{c: it[c] for c in CHAMPS_ITEM_PLANIFICATION if it.get(c) is not None}
                         for it in d['items']]
                jours.append({'dayIndex': d['dayIndex'], 'items': items})
            sem = {'weekIndex': w['weekIndex'], 'days': jours}
            for c in ('kind', 'intent'):
                if w.get(c) is not None:
                    sem[c] = w[c]
            semaines.append(sem)
        out.append({'pass2': {'weeks': semaines}})
    return out


def tirage_intermediaire(pl, k, semaine, n):
    """Recalcule, comme `Planification.tirer`, la covariance des quantités
    tirées, sa racine de Cholesky semi-définie (`numerique.cholesky_semi`) et
    les tirages normaux z (aide au portage ; vérifié contre `tirer`). À
    appeler après `tirer` (pistes des exercices suivis créées)."""
    m = k.modele
    lignes = []
    moyennes = []
    for ex in pl.suivis:
        t = m.piste(ex)
        h = np.zeros(m.n)
        base = 0.0
        if t is not None:
            idx, co = m._h_capacite(t, jour=False)
            for i, c in zip(idx, co):
                h[i] += c
            base = t.base
        lignes.append(h)
        moyennes.append(base + float(h @ m.m[:m.n]))
    for i in [RHO] + [EPS + c for c in range(len(CLASSES))]:
        h = np.zeros(m.n)
        h[i] = 1.0
        lignes.append(h)
        moyennes.append(float(m.m[i]))
    H = np.array(lignes)
    S = H @ m.P[:m.n, :m.n] @ H.T
    S = 0.5 * (S + S.T)
    L = np.array(nu.cholesky_semi(S.tolist()))
    rng = nu.Mulberry32(nu.fnv1a32('koach-plan:%d:%d' % (int(pl.p['graine']), semaine)))
    kk = S.shape[0]
    z = np.empty((n, kk))
    for a in range(n):
        for b in range(kk):
            z[a, b] = rng.gauss()
    x = np.asarray(moyennes)[None, :] + z @ L.T
    return {'H': H, 'moyennes': moyennes, 'S': S, 'L': L, 'z': z, 'x': x}


def fixture_planification(pc):
    sc = dict(pc)
    saison, pol, tour = conduire(sc)
    complete = vk.saison(pc['cle'], pc['scenario'])
    k = pol.koach
    semaine = pc['semaines']
    profil = complete['profiles'][0]['profile']
    blocs = blocs_reduits(complete['blocks'])
    fiches = pol.espion        # mêmes fiches espionnées : on lit aussi celles de la planification
    reference = {
        'blocs': blocs,
        'block_weeks': list(complete.get('blockWeeks') or [0]),
        'horizon': complete['weeks'],
        'cibles': cibles_du_profil(profil, fiches),
        'echeance_jour': echeance_de(complete, semaine, 7 * semaine),
        'principaux': principaux_de(complete),
        'poids_corps': profil.get('bodyWeightKg'),
    }
    reference = copie_json(reference)
    options = {'trajectoires': pc['trajectoires'], 'sans_validateur': True}
    avant = propre(k.posterior())
    pl = Planification(k.params, fiches, None, options)
    pl.charger_reference(reference['blocs'], reference['block_weeks'], reference['horizon'],
                         cibles=reference['cibles'], echeance_jour=reference['echeance_jour'],
                         principaux=reference['principaux'], poids_corps=reference['poids_corps'])
    n = int(pl.p['trajectoires'])
    tirage = pl.tirer(k, semaine, n)
    inter = tirage_intermediaire(pl, k, semaine, n)
    E = len(pl.suivis)
    if not np.array_equal(inter['x'][:, :E], tirage['mu']) or not np.array_equal(inter['x'][:, E], tirage['rho']) \
            or not np.array_equal(inter['x'][:, E + 1:], tirage['eps']):
        raise RuntimeError('tirage intermédiaire recalculé différent de Planification.tirer : '
                           'mettre generer.tirage_intermediaire à jour')
    blocs_d, qualites = pl._dimensions(semaine)
    d = len(blocs_d) * (len(qualites) + 1)
    v0, p0, dist0, det0 = pl.evaluer(np.zeros((1, d)), tirage, semaine, blocs_d, qualites, detail=True)
    tables = {}
    for w in range(semaine, pl.horizon):
        t = pl._table(w)
        if t is not None:
            tables[str(w)] = {'stim': t['stim'], 'syst': t['syst'], 'masse': t['masse'], 'part': t['part'],
                              'tendon': t['tendon'], 'verrou': t['verrou'], 'bloc': t['bloc']}
    ligne = pl.replanifier(k, semaine)
    modules = {}
    for w in range(semaine, min(pl.horizon, semaine + 4)):
        modules[str(w)] = [[j, slot, n_s, ec] for (j, slot), (n_s, ec) in sorted(pl.items_modules(w).items())]
    out = entete('planification', 'Replanification après %d semaines (%s, %d trajectoires)'
                 % (semaine, pc['cle'], n), pol.parametres)
    out.update({
        'source': {'profil': pc['cle'], 'scenario': pc['scenario'], 'verite': pc['verite'],
                   'graine': pc['graine'], 'semaines': pc['semaines']},
        'entrees': {
            'params': pol.parametres,
            'fiches': fiches.reduites(),
            'profil': k.profil,
            'journal': k.entrees,
        },
        'planification': {
            'options': options, 'semaine': semaine, 'reference': reference,
            'sequence': 'k = rejouer(params, fiches, profil, journal) ; '
                        'pl = Planification(params, fiches, None, options) ; charger_reference(...) ; '
                        'tirer(k, semaine, trajectoires) ; replanifier(k, semaine)',
        },
        'attendu': {
            'posterior_avant': avant,
            'suivis': list(pl.suivis),
            'grille_intensite': list(GRILLE_INTENSITE),
            'hypothese_thompson': pl.hypothese_thompson,
            'tirage': {c: tirage[c] for c in ('mu', 'rho', 'eps', 'hyp', 'bruit_jour', 'bruit_proc', 'bruit_seance', 'bruit_est', 'manque',
                                               'classes', 'fatigue', 'kg', 'semaines', 'hypotheses')},
            'tirage_intermediaire': {c: inter[c] for c in ('moyennes', 'S', 'L', 'z')},
            'dimensions': {'blocs': blocs_d, 'qualites': qualites},
            'tables': tables,
            'evaluation_reference': {'valeur': v0, 'p_cibles': p0, 'distance': dist0, 'J': det0['J'],
                                     'penal': det0['penal'], 'fatigue_fin': det0['fatigue_fin'],
                                     'fatigue_echeance': det0['fatigue_echeance'], 'gains': det0['gains']},
            'ligne': ligne,
            'plan': {str(w): p for w, p in sorted(pl.plan.items())},
            'items_modules': modules,
            'posterior_apres': k.posterior(),
        },
    })
    return propre(out)


# ----------------------------------------------------------------------
# numerique.json
# ----------------------------------------------------------------------
INF = math.inf


def bruit_de(b):
    """Variance du bruit d'une note, fonction de la valeur u (forme de
    `Modele` : sd affine de la réserve bornée à [0, 8], plus un terme
    constant) : (c0 + c1 · clamp(u (1 + bp) + ba, 0, 8))² + extra."""
    def f(u):
        r = u * (1.0 + b['bp']) + b['ba']
        if r < 0.0:
            r = 0.0
        if r > 8.0:
            r = 8.0
        sd = b['c0'] + b['c1'] * r
        return sd * sd + b['extra']
    return f


def matrices_cholesky():
    """Matrices symétriques semi-définies pour `cholesky_semi` : définies,
    de rang déficient (exactement et à l'arrondi près), nulles, diagonales,
    issues de A Aᵀ avec A tirée par Mulberry32 (déterministe)."""
    rng = nu.Mulberry32(nu.fnv1a32('fixtures-cholesky'))

    def aat(k, r):
        A = [[rng.gauss() for _ in range(r)] for _ in range(k)]
        return [[sum(A[i][q] * A[j][q] for q in range(r)) for j in range(k)] for i in range(k)]

    v = [1.0, 2.0, -1.0, 0.5]
    w = [0.0, 1.0, 3.0, -2.0]
    rang2 = [[v[i] * v[j] + w[i] * w[j] for j in range(4)] for i in range(4)]
    out = [
        ([[4.0]], None),
        ([[0.0]], None),
        ([[2.0, 0.0], [0.0, 3.0]], None),
        ([[4.0, 2.0], [2.0, 3.0]], None),
        ([[1.0, 1.0], [1.0, 1.0]], None),                       # rang 1 exact
        ([[25.0, 15.0, -5.0], [15.0, 18.0, 0.0], [-5.0, 0.0, 11.0]], None),
        ([[0.0, 0.0, 0.0], [0.0, 2.0, 1.0], [0.0, 1.0, 2.0]], None),   # premier pivot nul
        (rang2, None),                                          # 4×4 de rang 2
        ([[1.0, 1.0, 0.0], [1.0, 1.0 + 1e-14, 0.0], [0.0, 0.0, 1.0]], None),   # pivot sous le seuil
        ([[1.0, 1.0, 0.0], [1.0, 1.0 + 1e-14, 0.0], [0.0, 0.0, 1.0]], 1e-16),  # même, seuil abaissé
        ([[1e-20, 0.0], [0.0, 1.0]], None),                     # petite diagonale sous le seuil
        ([[0.0] * 3 for _ in range(3)], None),                  # nulle
        (aat(6, 6), None),
        (aat(7, 3), None),                                      # 7×7 de rang 3 (à l'arrondi près)
        (aat(9, 9), None),
    ]
    return out


def cas_numerique():
    xs_erfc = [0.0, -0.0, 1e-300, 1e-10, -1e-10, 0.1, -0.1, 0.5, -0.5, 1.0, -1.0, 1.5, -1.5,
               1.9999999999, -1.9999999999, 2.0, -2.0, 2.0000000001, 2.5, -2.5, 3.0, -3.0, 4.0,
               5.0, -5.0, 6.0, 8.0, 10.0, 15.0, 20.0, 26.0, 26.5, 27.0, 27.5, 30.0, -30.0, 40.0,
               -6.0, 0.7071067811865476, 1.234567]
    xs_norm = [0.0, 0.5, -0.5, 1.0, -1.0, 1.6448536269514722, -1.6448536269514722, 1.96, -1.96,
               2.8284271247461903, -2.8284271247461903, 3.0, -3.0, 5.0, -5.0, 8.0, -8.0, 10.0, -10.0,
               20.0, -20.0, 37.0, -37.0, 38.5, -38.5, 40.0, -40.0, 1e-12, -1e-12, 0.3, -2.7]
    ps = [0.0, -0.1, 1.0, 1.5, 1e-300, 1e-100, 1e-20, 1e-12, 1e-6, 0.001, 0.01, 0.02424,
          0.02425, 0.02426, 0.05, 0.1, 0.25, 0.3, 0.5, 0.6, 0.75, 0.9, 0.95, 0.97574, 0.97575,
          0.97576, 0.99, 0.999, 0.999999, 1 - 1e-12, 0.9999999999999999]
    out = {
        'erfc': [[x, nu.erfc(x)] for x in xs_erfc],
        'norm_cdf': [[x, nu.norm_cdf(x)] for x in xs_norm],
        'norm_sf': [[x, nu.norm_sf(x)] for x in xs_norm],
        'norm_pdf': [[x, nu.norm_pdf(x)] for x in xs_norm],
        'norm_ppf': [[p, nu.norm_ppf(p)] for p in ps],
    }
    # interval_moments(m, v, s2, a, b) -> (logZ, m', v')
    cas = [
        (0.0, 1.0, 1.0, -INF, INF), (0.3, 0.2, 0.5, -INF, INF),
        (0.0, 1.0, 1.0, 0.0, INF), (0.0, 1.0, 1.0, -INF, 0.0),
        (1.0, 0.5, 0.25, 0.5, 1.5), (1.0, 0.5, 0.25, 2.5, 3.0), (1.0, 0.5, 0.25, -3.0, -2.5),
        (2.0, 0.01, 0.04, 2.0, 2.0001), (0.0, 1.0, 1.0, 5.0, INF), (0.0, 1.0, 1.0, -INF, -5.0),
        (0.0, 1.0, 1.0, 12.0, INF), (0.0, 1.0, 1.0, -INF, -12.0), (0.0, 1.0, 1.0, 12.0, 13.0),
        (0.0, 1.0, 1.0, 60.0, INF), (0.0, 1.0, 1.0, -INF, -60.0), (0.0, 1.0, 1.0, 60.0, 61.0),
        (0.0, 1.0, 1.0, -61.0, -60.0), (0.0, 1e-6, 1.0, 0.0, INF), (0.0, 100.0, 1e-4, 1.0, 1.0001),
        (-0.4, 0.09, 0.0, 0.0, INF), (3.2, 0.3, 1.2, -INF, 2.0), (3.2, 0.3, 1.2, 2.0, 4.0),
        (-1.0, 2.0, 0.5, -1.0, -0.5), (0.0, 1.0, 1.0, 0.0, 0.0),
        (0.0, 1e-20, 1.0, -0.1, 0.1), (5.0, 1.0, 1.0, -INF, 4.0),
    ]
    out['interval_moments'] = [[list(c), list(nu.interval_moments(*c))] for c in cas]
    # category_moments(m, v, a, b, bruit, steps, span, gross, gross_sd)
    bruits = [
        {'c0': 1.0, 'c1': 0.0, 'ba': 0.0, 'bp': 0.0, 'extra': 0.0},
        {'c0': 0.55, 'c1': 0.25, 'ba': 0.3, 'bp': 0.1, 'extra': 0.04},
        {'c0': 0.3, 'c1': 0.4, 'ba': -0.5, 'bp': 0.6, 'extra': 0.0},
        {'c0': 2.0, 'c1': 0.0, 'ba': 0.0, 'bp': -0.2, 'extra': 1.5},
        # Bruits petits (noteur précis) : grille choisie sur la vraisemblance.
        {'c0': 0.05, 'c1': 0.0, 'ba': 0.0, 'bp': 0.0, 'extra': 0.0},
        {'c0': 0.02, 'c1': 0.01, 'ba': 0.0, 'bp': 0.0, 'extra': 0.0},
        # Bruit nul exclu : `_category_mass` divise par l'écart-type (le
        # modèle garde un plancher de bruit > 0) ; bruit minuscule à la place.
        {'c0': 1e-3, 'c1': 0.0, 'ba': 0.0, 'bp': 0.0, 'extra': 0.0},
    ]
    cas_c = []
    bornes = [(-INF, 0.5), (0.5, 1.5), (1.5, 2.5), (3.5, INF), (2.0, 2.0), (-INF, INF),
              (-INF, -40.0), (40.0, INF), (0.0, 8.0)]
    moyennes = [(0.0, 1.0), (2.0, 0.5), (4.5, 2.0), (1.0, 0.0), (-1.0, 1e-8)]
    for bi in range(4):
        for (m, v) in moyennes:
            for (a, bb) in bornes:
                for gross, gsd in ((0.0, 0.0), (0.03, 2.5)):
                    cas_c.append((m, v, a, bb, bi, 52, 6.5, gross, gsd))
    cas_c += [(1.0, 0.8, 0.5, 1.5, 1, 20, 5.0, 0.0, 0.0), (1.0, 0.8, 0.5, 1.5, 1, 20, 5.0, 0.1, 3.0),
              (2.5, 1.2, 1.5, 2.5, 2, 80, 8.0, 0.05, 1.0), (0.0, 1.0, 30.0, 31.0, 0, 52, 6.5, 0.0, 0.0)]
    # A priori très large devant le bruit : intervalles fermés (fenêtre
    # [a − 8T, b + 8T]) et ouverts (grille plafonnée à 1 200 points), avec et
    # sans queue lourde.
    larges = [(0.0, 100.0), (3.0, 25.0), (-2.0, 1e4), (1.2, 4.0)]
    bornes_l = [(0.5, 1.5), (2.0, 2.1), (2.0, 2.0), (-INF, 1.5), (4.0, INF), (-0.25, 0.25), (150.0, 151.0)]
    for bi in (4, 5, 6, 1):
        for (m, v) in larges:
            for (a, bb) in bornes_l:
                for gross, gsd in ((0.0, 0.0), (0.03, 2.5)):
                    cas_c.append((m, v, a, bb, bi, 52, 6.5, gross, gsd))
    out['category_moments_bruits'] = bruits
    out['category_moments'] = [
        [list(c), list(nu.category_moments(c[0], c[1], c[2], c[3], bruit_de(bruits[c[4]]), steps=c[5],
                                            span=c[6], gross=c[7], gross_sd=c[8]))]
        for c in cas_c]
    cas_masse = [(-INF, 0.5, 0.0, 1.0), (0.5, INF, 0.0, 1.0), (-INF, INF, 0.0, 1.0), (0.5, 1.5, 1.0, 0.3),
                 (2.0, 3.0, 0.0, 0.5), (-3.0, -2.0, 0.0, 0.5), (10.0, 11.0, 0.0, 1.0), (-INF, -40.0, 0.0, 1.0)]
    out['category_mass'] = [[list(c), nu._category_mass(*c)] for c in cas_masse]
    cas_p = [(0.0, 1.0, 1.0, 0.5), (1.2, 0.04, 0.01, 1.3), (-3.0, 2.0, 0.5, 4.0), (0.0, 1e-9, 1.0, 100.0),
             (5.0, 0.0, 1.0, 5.5), (0.7, 3.0, 1e-6, 0.69)]
    out['point_moments'] = [[list(c), list(nu.point_moments(*c))] for c in cas_p]
    graines = [0, 1, 42, 123456789, 2147483647, 4294967295, 4294967296 + 7, 20261009,
               nu.fnv1a32('koach-plan:20261009:4')]
    mb = []
    for g in graines:
        r = nu.Mulberry32(g)
        suite_next = [r.next() for _ in range(40)]
        etat = r.state
        r2 = nu.Mulberry32(g)
        suite_gauss = [r2.gauss() for _ in range(40)]
        mb.append({'graine': g, 'next': suite_next, 'etat_apres_next': etat, 'gauss': suite_gauss,
                   'etat_apres_gauss': r2.state})
    out['mulberry32'] = mb
    textes = ['', 'a', 'abc', 'koach-plan:20261009:0', 'koach-plan:20261009:4', 'koach-cem:20261009:4',
              'koach-dual:7:3', 'koach-adherence-poids:street_07|reference|a|0', 'é', 'œuvre', 'Ünïcødé ✓',
              '🙂', 'mu-developpe-couche-barre', 'x' * 100]
    out['fnv1a32'] = [[t, nu.fnv1a32(t)] for t in textes]
    out['dart_round'] = [[x, nu.dart_round(x)] for x in (0.0, 0.5, 1.5, 2.5, -0.5, -1.5, -2.5, 2.4999999,
                                                          -2.4999999, 7.0, -7.0, 1e9 + 0.5)]
    out['clamp'] = [[[x, lo, hi], nu.clamp(x, lo, hi)] for (x, lo, hi) in
                    ((0.5, 0.0, 1.0), (-1.0, 0.0, 1.0), (2.0, 0.0, 1.0), (1.0, 1.0, 1.0))]
    # cholesky_semi(S, tol) -> L (liste de listes)
    out['cholesky_semi'] = [[[S, tol], nu.cholesky_semi(S) if tol is None else nu.cholesky_semi(S, tol)]
                            for S, tol in matrices_cholesky()]
    # arrondi(x, decimales) : demi vers le haut en flottants (≠ round de Python).
    cas_a = [(0.0, 0), (0.5, 0), (1.5, 0), (2.5, 0), (-0.5, 0), (-1.5, 0), (-2.5, 0), (0.49999999999999994, 0),
             (2.675, 2), (1.005, 2), (0.125, 2), (0.375, 2), (-0.125, 2), (12.345, 1), (0.1234565, 6),
             (99.95, 1), (1e15 + 0.5, 0), (3.14159, 4), (-7.77777, 3), (0.000049, 4), (123.456, 0),
             (2.5, 1), (1.0 / 3.0, 3), (33.333333, 2), (0.07, 2), (6.0, 2)]
    out['arrondi'] = [[[x, d], nu.arrondi(x, d)] for (x, d) in cas_a]
    o = entete('numerique', 'Outils numériques de Koach 1.0 (koach/numerique.py)', None)
    o.update({'cas': out, 'notes': {
        'interval_moments': 'entrée [m, v, s2, a, b], sortie [logZ, m2, v2]',
        'category_moments': 'entrée [m, v, a, b, indice du bruit, steps, span, gross, gross_sd], '
                            'sortie [logZ, m2, v2] ; bruit(u) = (c0 + c1 * clamp(u * (1 + bp) + ba, 0, 8))^2 '
                            '+ extra (category_moments_bruits)',
        'category_mass': 'entrée [a, b, u, t] (_category_mass, qui utilise math.erfc de la libm)',
        'point_moments': 'entrée [m, v, s2, y], sortie [logZ, m2, v2]',
        'mulberry32': 'next et gauss tirés de deux générateurs neufs de même graine (graine & 0xFFFFFFFF)',
        'cholesky_semi': 'entrée [S, tol] (tol null : défaut 1e-12), sortie L (triangulaire inférieure)',
        'arrondi': 'entrée [x, decimales], sortie floor(x * 10^d + 0.5) / 10^d',
    }})
    return propre(o)


# ----------------------------------------------------------------------
# Écriture et vérification
# ----------------------------------------------------------------------
def fixtures(noms=None):
    """Nom de fichier -> texte (dans l'ordre d'écriture) ; [noms] : sous-
    ensemble à produire (tous si None)."""
    out = {}

    def veut(nom):
        return noms is None or nom in noms

    if veut('numerique.json'):
        out['numerique.json'] = texte(cas_numerique())
    for sc in SCENARIOS:
        nom = 'moteur_%d.json' % sc['n']
        if veut(nom):
            out[nom] = texte(fixture_moteur(sc))
    for pc in PLANIFICATIONS:
        nom = 'planification_%d.json' % pc['n']
        if veut(nom):
            out[nom] = texte(fixture_planification(pc))
    return out


def ecrire(dossier=ICI):
    contenus = fixtures()
    for nom, t in contenus.items():
        with open(os.path.join(dossier, nom), 'w', encoding='utf-8', newline='\n') as f:
            f.write(t)
    return contenus


def verifier(dossier=ICI):
    """Liste des fichiers absents ou différents (vide : à jour)."""
    ecarts = []
    contenus = fixtures()
    for nom, t in contenus.items():
        chemin = os.path.join(dossier, nom)
        if not os.path.exists(chemin):
            ecarts.append(nom + ' (absent)')
            continue
        with open(chemin, encoding='utf-8') as f:
            if f.read() != t:
                ecarts.append(nom + ' (différent)')
    attendus = set(contenus)
    for nom in sorted(os.listdir(dossier)):
        if nom.endswith('.json') and nom not in attendus:
            ecarts.append(nom + ' (en trop)')
    return ecarts


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--verifier', action='store_true',
                    help='échoue si les fichiers ne sont pas à jour (rien n\'est écrit)')
    a = ap.parse_args(argv)
    if a.verifier:
        ecarts = verifier()
        if ecarts:
            sys.stderr.write('fixtures pas à jour : %s\n(relancer python3 fixtures/generer.py)\n'
                             % ', '.join(ecarts))
            return 1
        print('fixtures à jour.')
        return 0
    contenus = ecrire()
    total = 0
    for nom, t in contenus.items():
        n = len(t.encode('utf-8'))
        total += n
        print('%-24s %9d octets' % (nom, n))
    print('%-24s %9d octets' % ('total', total))
    return 0


if __name__ == '__main__':
    sys.exit(main())
