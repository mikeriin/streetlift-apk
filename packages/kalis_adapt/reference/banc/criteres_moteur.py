# -*- coding: utf-8 -*-
"""Critères du cahier KM mesurés automatiquement sur le banc Python (lot
KM1) :

1. **temps** (indicatifs : Python, cette machine) d'un `observe` de type
   série, d'un `plan` horizon série et horizon séance sur une saison complète
   (profil avancé chargé), et d'une replanification (1 000 trajectoires,
   256 plans, validateur de sécurité du banc) ; cahier : « mise à jour après
   une série en 50 ms au plus, replanification en 10 s au plus » ;
2. **mauvais jour isolé** : la même saison rejouée avec les mêmes tirages,
   une fois telle quelle, une fois avec UNE séance (au milieu de la saison,
   après au moins 6 séances de l'exercice) où l'athlète est à −6 % de
   capacité ; écart relatif des e1RM estimés (capacité à frais) des
   mouvements principaux chargés juste après, puis 1 et 2 séances de
   l'exercice plus tard ; cahier : « effet d'un mauvais jour isolé sur
   l'estimation sous 1 % » (effet moyen) ;
3. **déterminisme** : deux exécutions de la même saison (planification et
   extensions branchées) dans deux processus distincts (graines de hachage
   différentes) -> mêmes séries servies, mêmes estimations, même
   `posterior()` final (comparés par `json.dumps(..., sort_keys=True)`).

    python3 -m banc.criteres_moteur --sortie donnees/criteres_moteur.json
        [--rapide] [--coeurs 2]
"""
import argparse
import hashlib
import json
import math
import os
import platform
import subprocess
import sys
import time

import numpy as np

from koach.moteur import Koach
from . import extensions_koach as ek
from . import meneur, planification_banc
from . import validation_koach as vk
from .politique_koach import PolitiqueKoach
from .verite import SimAthlete

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SEUIL_SERIE_MS = 50.0
SEUIL_REPLANIFICATION_S = 10.0
SEUIL_MAUVAIS_JOUR = 0.01
MAUVAIS_JOUR = 0.06          # baisse de capacité de toute la séance
SEANCES_AVANT = 6            # séances de l'exercice avant le mauvais jour
HORIZONS = ('apres', 'plus_1', 'plus_2')

SAISON_TEMPS = ('street_07_avance_streetlifting_competition', 'reference', 'a', 0)
SAISON_DETERMINISME = ('street_07_avance_streetlifting_competition', 'douleur_coude', 'b', 1)
# Profils dont les mouvements principaux sont chargés.
PROFILS_CHARGES = ('street_07_avance_streetlifting_competition', 'street_09_elite_streetlifting',
                   'street_16_specialisation_traction_lestee', 'autres_02_hypertrophie_intermediaire',
                   'autres_03_powerlifter_competition', 'autres_04_force_generale_46_ans')


# ----------------------------------------------------------------------
# Statistiques
# ----------------------------------------------------------------------
def stats(xs):
    """Moyenne, médiane, 95e centile (rang le plus proche), maximum."""
    ys = sorted(xs)
    n = len(ys)
    if n == 0:
        return {'n': 0, 'moyenne': None, 'mediane': None, 'p95': None, 'max': None}
    med = ys[n // 2] if n % 2 else 0.5 * (ys[n // 2 - 1] + ys[n // 2])
    return {'n': n, 'moyenne': sum(ys) / n, 'mediane': med,
            'p95': ys[max(0, int(math.ceil(0.95 * n)) - 1)], 'max': ys[-1]}


def _saison(cle, scenario, semaines=None):
    s = vk.saison(cle, scenario)
    if semaines is not None and semaines < s['weeks']:
        s = dict(s)
        s['weeks'] = semaines
    return s


# ----------------------------------------------------------------------
# 1. Temps
# ----------------------------------------------------------------------
class KoachChrono(Koach):
    """`Koach` qui chronomètre `observe` (séries) et `plan` (série, séance)."""

    def __init__(self, params, fiches, profil):
        Koach.__init__(self, params, fiches, profil)
        self.temps = {'observe_serie': [], 'plan_serie': [], 'plan_seance': []}

    def observe(self, e):
        if e.get('type') != 'serie':
            return Koach.observe(self, e)
        t0 = time.perf_counter()
        r = Koach.observe(self, e)
        self.temps['observe_serie'].append(time.perf_counter() - t0)
        return r

    def plan(self, c):
        cle = 'plan_' + str(c.get('horizon'))
        t0 = time.perf_counter()
        r = Koach.plan(self, c)
        if cle in self.temps:
            self.temps[cle].append(time.perf_counter() - t0)
        return r


class PolitiqueChrono(PolitiqueKoach):
    """`PolitiqueKoach` sans extension dont le moteur est remplacé, juste
    après `debut`, par un `KoachChrono`."""

    def debut(self, saison, profil, livre):
        PolitiqueKoach.debut(self, saison, profil, livre)
        k = self.koach
        self.koach = KoachChrono(k.params, k.fiches, k.profil)


class PlanificationChrono(planification_banc.PlanificationBanc):
    """Planification du banc (validateur de sécurité compris) qui
    chronomètre chaque replanification."""

    temps = None

    def replanifier(self, koach, semaine):
        t0 = time.perf_counter()
        ligne = planification_banc.PlanificationBanc.replanifier(self, koach, semaine)
        if ligne.get('plans'):
            PlanificationChrono.temps.append((time.perf_counter() - t0, ligne['plans']))
        return ligne


def mesurer_temps(saison=SAISON_TEMPS, semaines=None, options=None):
    """Temps d'un `observe` série et des `plan` (ms) sur une saison, puis des
    replanifications (s) sur la même saison avec la planification du banc
    ([options] : surcharge de `params['planification']`)."""
    cle, scenario, verite, graine = saison
    s = _saison(cle, scenario, semaines)
    pol = PolitiqueChrono()
    meneur.simuler(s, vk.infos(), pol, verite, graine)
    t = pol.koach.temps
    ms = {k: stats([1000.0 * x for x in v]) for k, v in t.items()}
    PlanificationChrono.temps = []
    pol2 = PolitiqueKoach(extensions=[lambda p: PlanificationChrono(p, options, True)])
    meneur.simuler(s, vk.infos(), pol2, verite, graine)
    replan = list(PlanificationChrono.temps)
    PlanificationChrono.temps = None
    p = dict(pol2.parametres['planification'])
    p.update(options or {})
    serie = ms['observe_serie']
    rs = stats([x[0] for x in replan])
    return {
        'saison': {'profil': cle, 'scenario': scenario, 'verite': verite, 'graine': graine,
                   'semaines': s['weeks']},
        'observe_serie_ms': serie,
        'plan_serie_ms': ms['plan_serie'],
        'plan_seance_ms': ms['plan_seance'],
        'replanification_s': rs,
        'replanification': {'trajectoires': int(p['trajectoires']), 'plans_max': int(p['plans_max']),
                            'plans_evalues': sorted(set(x[1] for x in replan)), 'validateur': True},
        'critere_serie_ms': SEUIL_SERIE_MS,
        'critere_replanification_s': SEUIL_REPLANIFICATION_S,
        'respecte': bool(serie['max'] is not None and serie['max'] <= SEUIL_SERIE_MS
                         and rs['max'] is not None and rs['max'] <= SEUIL_REPLANIFICATION_S),
        'note': 'indicatif : référence Python (numpy) sur cette machine ; le critère vaut pour le portage Dart',
    }


# ----------------------------------------------------------------------
# 2. Mauvais jour isolé
# ----------------------------------------------------------------------
def classe_mauvais_jour(jour, baisse=MAUVAIS_JOUR):
    """Athlète simulé du banc dont toute la séance du jour [jour] est à
    (1 − [baisse]) de sa capacité : l'effet de jour de chaque exercice
    (`TruthExercise.day`, tiré par `begin_exercise`) est décalé de
    ln(1 − baisse). Aucun autre tirage ne change (bilan de santé compris :
    l'athlète ne signale rien)."""
    decalage = math.log(1.0 - baisse)

    class AthleteMauvaisJour(SimAthlete):
        def begin_exercise(self, t, slot_key):
            SimAthlete.begin_exercise(self, t, slot_key)
            if self._day == jour:
                t.day += decalage

    return AthleteMauvaisJour


def simuler_mauvais_jour(saison, verite, graine, jour, baisse=MAUVAIS_JOUR):
    """Saison simulée par `PolitiqueKoach` avec un mauvais jour isolé (le
    meneur construit l'athlète : sa classe est substituée le temps de
    l'appel, `banc/verite.py` n'est pas modifié)."""
    ancienne = meneur.SimAthlete
    meneur.SimAthlete = classe_mauvais_jour(jour, baisse)
    try:
        return meneur.simuler(saison, vk.infos(), PolitiqueKoach(), verite, graine)
    finally:
        meneur.SimAthlete = ancienne


def choisir_jour(saison, tour, seances_avant=SEANCES_AVANT):
    """Première séance de la seconde moitié de la saison où un mouvement
    principal chargé a déjà au moins [seances_avant] séances : (jour,
    exercice) ou None."""
    milieu = saison['weeks'] // 2
    for s in tour.sets:
        if s['week'] >= milieu and s['main'] and s['mode'] == 'loaded' and s['exerciseSession'] >= seances_avant:
            return s['simDay'], s['exerciseId']
    return None


def _par_jour(tour):
    """exercice -> [(jour, e1RM estimé (capacité à frais))], une entrée par
    séance de l'exercice (la dernière ligne du jour : l'estimation après la
    séance), mouvements principaux chargés."""
    out = {}
    for e in tour.estimates:
        if not (e['main'] and e['mode'] == 'loaded'):
            continue
        lst = out.setdefault(e['exerciseId'], [])
        if lst and lst[-1][0] == e['simDay']:
            lst[-1] = (e['simDay'], e['capacity'])
        else:
            lst.append((e['simDay'], e['capacity']))
    return out


def _suite(base, autre, jour, n):
    """Paires (sans, avec) d'estimations : séance du jour [jour] puis les
    [n] - 1 séances suivantes de l'exercice dans la saison telle quelle,
    lues le même jour dans l'autre saison (None si l'exercice n'y est pas
    entraîné ce jour-là, ou si la saison s'arrête avant)."""
    d_autre = dict(autre)
    jours = [(j, v) for (j, v) in base if j >= jour][:n]
    out = [(v, d_autre.get(j)) for (j, v) in jours]
    return out + [(None, None)] * (n - len(out)), [j for (j, _) in jours]


def mauvais_jour_saison(cle, verite, graine, scenario='reference', baisse=MAUVAIS_JOUR):
    """Une saison, deux fois (telle quelle, puis avec le mauvais jour) :
    écarts relatifs des e1RM des mouvements principaux chargés entraînés le
    jour du mauvais jour, juste après puis 1 et 2 séances de l'exercice plus
    tard (séances de la saison telle quelle, appariées par leur jour : le
    calendrier est le même dans les deux saisons)."""
    s = _saison(cle, scenario)
    base = meneur.simuler(s, vk.infos(), PolitiqueKoach(), verite, graine)
    choix = choisir_jour(s, base)
    ligne = {'profil': cle, 'scenario': scenario, 'verite': verite, 'graine': graine}
    if choix is None:
        ligne['jour'] = None
        return ligne
    jour, exercice = choix
    mauvais = simuler_mauvais_jour(s, verite, graine, jour, baisse)
    eb = _par_jour(base)
    em = _par_jour(mauvais)
    ecarts = {}
    jours_suivants = {}
    n = len(HORIZONS)
    for ex, lst in sorted(eb.items()):
        if not any(j == jour for (j, _) in lst):
            continue
        paires, jours = _suite(lst, em.get(ex, []), jour, n)
        ecarts[ex] = [None if (x is None or y is None) else y / x - 1.0 for x, y in paires]
        jours_suivants[ex] = jours
    ligne.update({'jour': jour, 'semaine': jour // 7, 'exercice_declencheur': exercice, 'ecarts': ecarts,
                  'jours': jours_suivants})
    return ligne


# ----------------------------------------------------------------------
# 2 bis. Mauvais jour isolé, contrefactuel apparié (DECISIONS_CP.md C13.10.2.b)
# ----------------------------------------------------------------------
def _saison_et_journal(saison, verite, graine, classe=None):
    """Simule la saison avec `PolitiqueKoach` (sans extension : l'état se
    recalcule exactement depuis le journal, `tests/test_rejeu_exact.py`) ;
    renvoie (tour, moteur)."""
    pol = PolitiqueKoach()
    ancienne = meneur.SimAthlete
    if classe is not None:
        meneur.SimAthlete = classe
    try:
        tour = meneur.simuler(saison, vk.infos(), pol, verite, graine)
    finally:
        meneur.SimAthlete = ancienne
    return tour, pol.koach


def _seance_du_jour(journal, jour):
    """(i0, i1) : indices du `seance_debut` et du `seance_fin` de la séance
    du jour [jour] dans le journal, ou None."""
    i0 = None
    for i, e in enumerate(journal):
        if e['type'] == 'seance_debut' and e['jour'] == jour:
            i0 = i
        elif e['type'] == 'seance_fin' and e['jour'] == jour and i0 is not None:
            return i0, i
    return None


def _rejouer_en_suivant(koach, journal, exercices):
    """Rejoue [journal] dans un moteur neuf (mêmes paramètres, fiches et
    profil que [koach]) ; renvoie exercice -> [(jour, e1RM estimé à frais)]
    relevé à chaque fin de séance où l'exercice a été entraîné."""
    k = Koach(koach.params, koach.fiches, koach.profil)
    out = {ex: [] for ex in exercices}
    for e in journal:
        k.observe(e)
        if e['type'] == 'seance_fin':
            for ex in exercices:
                t = k.modele.pistes.get(ex)
                if t is not None and t.jour_seance == e['jour']:
                    out[ex].append((e['jour'], math.exp(k.modele.capacite(ex)[0])))
    return out


def mauvais_jour_apparie_saison(cle, verite, graine, scenario='reference', baisse=MAUVAIS_JOUR):
    """Contrefactuel apparié : la saison telle quelle donne un journal J.
    Le journal contrefactuel est J jusqu'à la veille du mauvais jour, puis
    la séance du mauvais jour telle que Koach l'a servie à l'athlète à
    (1 − [baisse]) de sa capacité (mêmes tirages), puis les séances
    SUIVANTES DE J, à l'identique (mêmes charges servies, mêmes répétitions,
    mêmes notes). Les deux journaux sont rejoués dans deux moteurs neufs :
    l'écart des e1RM mesure l'effet de l'observation du mauvais jour, et lui
    seul (la saison ne diverge pas ensuite). Écarts relatifs juste après,
    puis 1 et 2 séances de l'exercice plus tard."""
    s = _saison(cle, scenario)
    base, k_base = _saison_et_journal(s, verite, graine)
    choix = choisir_jour(s, base)
    ligne = {'profil': cle, 'scenario': scenario, 'verite': verite, 'graine': graine}
    if choix is None:
        ligne['jour'] = None
        return ligne
    jour, exercice = choix
    _, k_mauvais = _saison_et_journal(s, verite, graine, classe_mauvais_jour(jour, baisse))
    jb = json.loads(json.dumps(k_base.journal, default=_defaut))
    jm = json.loads(json.dumps(k_mauvais.journal, default=_defaut))
    sb = _seance_du_jour(jb, jour)
    sm = _seance_du_jour(jm, jour)
    if sb is None or sm is None or sb[0] != sm[0] or \
            json.dumps(jb[:sb[0]], sort_keys=True) != json.dumps(jm[:sm[0]], sort_keys=True):
        ligne.update({'jour': jour, 'erreur': 'journaux différents avant le mauvais jour'})
        return ligne
    contrefactuel = jb[:sb[0]] + jm[sm[0]:sm[1] + 1] + jb[sb[1] + 1:]
    exercices = sorted(ex for ex, lst in _par_jour(base).items() if any(j == jour for (j, _) in lst))
    eb = _rejouer_en_suivant(k_base, jb, exercices)
    ec = _rejouer_en_suivant(k_base, contrefactuel, exercices)
    ecarts = {}
    jours_suivants = {}
    n = len(HORIZONS)
    for ex in exercices:
        paires, jours = _suite(eb[ex], ec[ex], jour, n)
        ecarts[ex] = [None if (x is None or y is None) else y / x - 1.0 for x, y in paires]
        jours_suivants[ex] = jours
    ligne.update({'jour': jour, 'semaine': jour // 7, 'exercice_declencheur': exercice, 'ecarts': ecarts,
                  'jours': jours_suivants, 'series_du_jour': [sb[1] - sb[0], sm[1] - sm[0]]})
    return ligne


def jobs_mauvais_jour(cles=PROFILS_CHARGES, verites='abc', graines=(0, 1)):
    return [(cle, v, g) for cle in cles for v in verites for g in graines]


def mesurer_mauvais_jour(jobs=None, coeurs=2, baisse=MAUVAIS_JOUR, apparie=False):
    """[apparie] : contrefactuel apparié (`mauvais_jour_apparie_saison`,
    mesure du critère depuis C13.10.2.b) ; sinon les deux saisons simulées
    séparément, qui divergent après le mauvais jour (mesure de KM1)."""
    jobs = jobs_mauvais_jour() if jobs is None else jobs
    lignes, plantages = vk.paralleles(mauvais_jour_apparie_saison if apparie else mauvais_jour_saison, jobs,
                                      coeurs=coeurs, kw={'baisse': baisse})
    par = {h: [] for h in HORIZONS}
    for ligne in lignes:
        for vals in (ligne.get('ecarts') or {}).values():
            for h, v in zip(HORIZONS, vals):
                if v is not None:
                    par[h].append(v)
    ecart_abs = {h: stats([abs(v) for v in par[h]]) for h in HORIZONS}
    signe = {h: (sum(par[h]) / len(par[h]) if par[h] else None) for h in HORIZONS}
    moyennes = [ecart_abs[h]['moyenne'] for h in HORIZONS if ecart_abs[h]['moyenne'] is not None]
    return {
        'baisse': baisse,
        'seances_avant': SEANCES_AVANT,
        'saisons': len(jobs),
        'saisons_mesurees': sum(1 for x in lignes if x.get('jour') is not None and not x.get('erreur')),
        'apparie': bool(apparie),
        'erreurs': sum(1 for x in lignes if x.get('erreur')),
        'ecart_abs': ecart_abs,
        'ecart_signe_moyen': signe,
        'critere': SEUIL_MAUVAIS_JOUR,
        'respecte': bool(moyennes) and all(m < SEUIL_MAUVAIS_JOUR for m in moyennes),
        'mesures': lignes,
        'plantages': plantages,
        'note': ('écart relatif e1RM (mauvais jour / sans) − 1 par mouvement principal chargé entraîné le '
                 'jour du mauvais jour ; même graine, même calendrier, même bilan de santé'),
    }


# ----------------------------------------------------------------------
# 3. Déterminisme
# ----------------------------------------------------------------------
def _defaut(x):
    if isinstance(x, np.bool_):
        return bool(x)
    if isinstance(x, np.integer):
        return int(x)
    if isinstance(x, np.floating):
        return float(x)
    if isinstance(x, np.ndarray):
        return x.tolist()
    if isinstance(x, (set, frozenset)):
        return sorted(x)
    raise TypeError('non codable : %r' % (type(x),))


def _texte(x):
    return json.dumps(x, sort_keys=True, default=_defaut)


def politique_complete(graine, trajectoires=None):
    """Koach avec la planification du banc et les trois extensions
    (surveillance, contrôle dual, adhérence)."""
    options = None if trajectoires is None else {'trajectoires': trajectoires}
    fab = [planification_banc.fabrique(options), ek.fabrique_surveillance(),
           ek.fabrique_controle_dual(graine), ek.fabrique_adherence(graine)]
    return ek.PolitiqueBriques(extensions=fab)


def empreinte(cle, scenario, verite, graine, semaines=None, trajectoires=None):
    """Empreintes (sha256 des textes JSON triés) d'une exécution complète."""
    s = _saison(cle, scenario, semaines)
    pol = politique_complete(graine, trajectoires)
    tour = meneur.simuler(s, vk.infos(), pol, verite, graine)
    textes = {
        'servi': _texte(tour.servi),
        'series': _texte(tour.sets),
        'estimations': _texte(tour.estimates),
        'posterior': _texte(pol.koach.posterior()),
        'extensions': _texte(ek.etats(pol)),
        'journal': _texte(pol.koach.journal),
    }
    out = {k: hashlib.sha256(v.encode('utf-8')).hexdigest() for k, v in textes.items()}
    out['seances'] = tour.sessions_done
    out['series_n'] = len(tour.sets)
    return out


def _empreinte_processus(args, graine_hachage):
    """Empreinte calculée dans un interpréteur neuf (PYTHONHASHSEED fixé)."""
    code = ('import json, sys; from banc.criteres_moteur import empreinte; '
            'print(json.dumps(empreinte(*json.loads(sys.argv[1]))))')
    env = dict(os.environ)
    env['PYTHONHASHSEED'] = str(graine_hachage)
    r = subprocess.run([sys.executable, '-c', code, json.dumps(list(args))], cwd=RACINE, env=env,
                       capture_output=True, text=True, check=True)
    return json.loads(r.stdout.strip().splitlines()[-1])


def mesurer_determinisme(saison=SAISON_DETERMINISME, semaines=None, trajectoires=None):
    cle, scenario, verite, graine = saison
    args = (cle, scenario, verite, graine, semaines, trajectoires)
    e1 = _empreinte_processus(args, 1)
    e2 = _empreinte_processus(args, 2)
    identiques = {k: e1[k] == e2[k] for k in e1}
    return {
        'saison': {'profil': cle, 'scenario': scenario, 'verite': verite, 'graine': graine,
                   'semaines': semaines, 'trajectoires': trajectoires},
        'extensions': ['PlanificationBanc', 'SurveillanceBanc', 'ControleDualBanc', 'AdherenceBanc'],
        'processus': 'deux interpréteurs, PYTHONHASHSEED = 1 puis 2',
        'identiques': identiques,
        'empreintes': [e1, e2],
        'respecte': all(identiques.values()),
    }


# ----------------------------------------------------------------------
# Rapport
# ----------------------------------------------------------------------
def principal(rapide=False, coeurs=2):
    """Les trois mesures. [rapide] : une saison tronquée pour les temps,
    une saison pour le mauvais jour, déterminisme sur 6 semaines."""
    t0 = time.time()
    if rapide:
        temps = mesurer_temps(semaines=4, options={'trajectoires': 200})
        mj = mesurer_mauvais_jour(jobs=[('street_16_specialisation_traction_lestee', 'a', 0)], coeurs=1)
        det = mesurer_determinisme(semaines=6, trajectoires=200)
    else:
        temps = mesurer_temps()
        mj = mesurer_mauvais_jour(coeurs=coeurs)
        det = mesurer_determinisme()
    return {
        'version': 1,
        'commande': 'python3 -m banc.criteres_moteur --sortie donnees/criteres_moteur.json'
                    + (' --rapide' if rapide else ''),
        'rapide': rapide,
        'machine': {'python': platform.python_version(), 'numpy': np.__version__,
                    'coeurs': os.cpu_count(), 'plateforme': platform.platform()},
        'temps': temps,
        'mauvais_jour': mj,
        'determinisme': det,
        'duree_s': time.time() - t0,
    }


def main(argv=None):
    ap = argparse.ArgumentParser(description='Critères du cahier KM mesurés sur le banc Python.')
    ap.add_argument('--sortie', default=os.path.join(RACINE, 'donnees', 'criteres_moteur.json'))
    ap.add_argument('--rapide', action='store_true')
    ap.add_argument('--coeurs', type=int, default=2)
    a = ap.parse_args(argv)
    r = principal(rapide=a.rapide, coeurs=a.coeurs)
    with open(a.sortie, 'w', encoding='utf-8') as f:
        json.dump(r, f, ensure_ascii=False, indent=1, sort_keys=True, default=_defaut)
        f.write('\n')
    t = r['temps']
    print('observe série : moyenne %.2f ms, médiane %.2f ms, max %.2f ms (critère %g ms)'
          % (t['observe_serie_ms']['moyenne'], t['observe_serie_ms']['mediane'], t['observe_serie_ms']['max'],
             SEUIL_SERIE_MS))
    print('plan série : moyenne %.2f ms, max %.2f ms ; replanification : moyenne %.2f s, max %.2f s'
          % (t['plan_serie_ms']['moyenne'], t['plan_serie_ms']['max'], t['replanification_s']['moyenne'],
             t['replanification_s']['max']))
    m = r['mauvais_jour']
    for h in HORIZONS:
        s = m['ecart_abs'][h]
        if s['n']:
            print('mauvais jour (%s) : |écart| moyen %.4f %%, médian %.4f %%, p95 %.4f %%, max %.4f %% (n = %d)'
                  % (h, 100 * s['moyenne'], 100 * s['mediane'], 100 * s['p95'], 100 * s['max'], s['n']))
    print('mauvais jour : critère < 1 %% %s ; déterminisme : %s'
          % ('respecté' if m['respecte'] else 'NON respecté',
             'identique' if r['determinisme']['respecte'] else 'DIFFÉRENT'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
