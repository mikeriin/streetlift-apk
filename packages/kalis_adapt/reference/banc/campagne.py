# -*- coding: utf-8 -*-
"""Campagne de mesure des critères chiffrés du cahier KM (lot KM1) :
Koach 1.0 complet (planification + surveillance + contrôle dual +
adhérence, montés comme dans `criteres_moteur.politique_complete`) contre le
témoin `kalis_adapt` 0.3.1 (export `donnees/temoin/`), sur la matrice du banc
(profils × scénarios × modèles de vérité × graines).

    python3 -m banc.campagne --profils <tous|fichier|liste> --scenarios <tous|liste>
        --verites abc --graines N --trajectoires 1000 --coeurs 2
        --sortie donnees/criteres_km1.json
        [--sans-planificateur] [--defaut-modele x] [--caler-couverture] [--rapide]
        [--temps-existants]

Critères (un bloc par critère : `mesure`, `seuil`, `respecte`, `n`,
`detail`, `methode`) :

1. erreur d'e1RM au rang 6 (6e séance de l'exercice), principaux chargés ;
2. mauvais jour isolé (`criteres_moteur.mesurer_mauvais_jour`) ;
3. vitesse de convergence (premier rang sous 3 %) contre le témoin ;
4. couverture de l'intervalle à 90 % (rangs >= 3) ;
5. calibration de P(toutes les cibles atteintes à l'échéance) par décile ;
6. performance le jour J (meilleure barre réussie / maximum vrai du jour)
   contre le témoin, saisons appariées par graine ;
7. sécurité : douleur (aggravations, poussées), validateur `securite_banc`
   sur les blocs servis (constats introduits par Koach distingués de ceux
   du plan initial de `kalis_plan`), hausses trop fortes ;
8. temps de calcul (`criteres_moteur.mesurer_temps`) ;
9. rappels, lus sans recalcul : pire cas adversarial
   (`donnees/comparaison_adversaires.json`) et rejeu du journal réel
   (`donnees/rejeu_journal_agregats.json`).

Reprise : chaque saison est écrite au fil de l'eau dans
`/tmp/km1-campagne/<empreinte>/` ; l'empreinte (SHA-256) couvre le fichier de
paramètres, les sources `koach/*.py` et la configuration (planification,
trajectoires, défaut de modèle). Une saison déjà faite n'est pas recalculée ;
une saison qui plante est comptée et rapportée (trace abrégée) sans arrêter
la campagne. Le JSON de sortie ne contient ni horodatage ni durée : même
commande (même cache ou cache neuf) = même JSON, sauf le critère 8 hors
`--rapide`/`--temps-existants` (temps mesurés, mis en cache eux aussi).
"""
import argparse
import copy
import glob
import hashlib
import json
import math
import os
import sys
import time
import traceback

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if RACINE not in sys.path:
    sys.path.insert(0, RACINE)

from banc import donnees, meneur, mesures  # noqa: E402
from banc import criteres_moteur as cm  # noqa: E402
from banc import extensions_koach as ek  # noqa: E402
from banc import planification_banc as pb  # noqa: E402
from banc import politique_koach as pk  # noqa: E402
from banc import securite_banc as sb  # noqa: E402

SCHEMA = 'kalis_adapt/criteres_km1/1'
DOSSIER_TRAVAIL = '/tmp/km1-campagne'
FICHIER_PARAMS = os.path.join(RACINE, 'params', 'koach_params_v1.json')
SET9 = '/home/claude/km1-outils/SET9'
SORTIE = os.path.join(RACINE, 'donnees', 'criteres_km1.json')

MODES = ('loadedMain', 'loaded', 'reps', 'hold')
RANG = 6
RANGS = (1, 3, 6, 12, 24)
RANG_COUVERTURE = 3
JAMAIS = mesures.K_MAX + 1          # premier passage censuré (« jamais » sous 3 %)

SEUIL_E1RM = 0.03
SEUIL_COUVERTURE = (0.88, 0.92)
SEUIL_CALIBRATION = 0.05
N_MIN_DECILE = 20
DECILES_MIN = 2                    # déciles de n >= 20 exigés par date pour juger
SEMAINES_AVANT = 4
VUES_SECURITE = ('plan_module', 'servi', 'servi_tests_faits')
EPS = 1e-9

_OPTS = None                       # options de la campagne (copiées dans les processus)


# ----------------------------------------------------------------------
# Outils
# ----------------------------------------------------------------------
def _r(x, n=6):
    if x is None:
        return None
    if isinstance(x, float):
        if math.isnan(x) or math.isinf(x):
            return None
        return round(x, n)
    return x


def _moy(xs):
    xs = [x for x in xs if x is not None]
    return sum(xs) / len(xs) if xs else None


def _mediane(xs):
    ys = sorted(x for x in xs if x is not None)
    n = len(ys)
    if n == 0:
        return None
    return ys[n // 2] if n % 2 else 0.5 * (ys[n // 2 - 1] + ys[n // 2])


def _se(xs):
    xs = [x for x in xs if x is not None]
    if len(xs) < 2:
        return None
    m = sum(xs) / len(xs)
    return math.sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1) / len(xs))


def _arrondir(o):
    if isinstance(o, dict):
        return {str(k): _arrondir(v) for k, v in o.items()}
    if isinstance(o, (list, tuple)):
        return [_arrondir(v) for v in o]
    if isinstance(o, bool) or o is None or isinstance(o, (int, str)):
        return o
    if isinstance(o, float):
        return _r(o)
    try:                                       # numpy
        return _arrondir(o.item())
    except AttributeError:
        return o


def _ecrire_json(chemin, obj):
    tmp = chemin + '.tmp%d' % os.getpid()
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(obj, f, ensure_ascii=False, sort_keys=True, default=cm._defaut)
    os.replace(tmp, chemin)


def _lire_json(chemin):
    try:
        with open(chemin, encoding='utf-8') as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def empreinte_sources():
    """SHA-256 du fichier de paramètres et des sources `koach/*.py`."""
    h = hashlib.sha256()
    fichiers = [FICHIER_PARAMS] + sorted(glob.glob(os.path.join(RACINE, 'koach', '*.py')))
    for chemin in fichiers:
        h.update(os.path.relpath(chemin, RACINE).encode('utf-8'))
        with open(chemin, 'rb') as f:
            h.update(hashlib.sha256(f.read()).digest())
    return h.hexdigest()


def config_de(opts):
    """Ce qui change le résultat d'une saison (hors code)."""
    return {'planificateur': not opts['sans_planificateur'], 'trajectoires': int(opts['trajectoires']),
            'defaut_modele_sd': opts['defaut_modele']}


def dossier_de(opts, sources):
    texte = json.dumps({'sources': sources, 'config': config_de(opts)}, sort_keys=True)
    d = os.path.join(opts['travail'], hashlib.sha256(texte.encode('utf-8')).hexdigest()[:16])
    os.makedirs(d, exist_ok=True)
    chemin = os.path.join(d, 'config.json')
    if not os.path.exists(chemin):
        _ecrire_json(chemin, {'sources': sources, 'config': config_de(opts)})
    return d


def parametres(opts):
    """Paramètres de Koach (copie), défaut de modèle surchargé si demandé."""
    p = copy.deepcopy(pk.params())
    if opts.get('defaut_modele') is not None:
        p['mesure']['defaut_modele_sd'] = float(opts['defaut_modele'])
    return p


def appliquer_parametres(opts):
    """Les mesures reprises de `criteres_moteur` construisent `PolitiqueKoach()`
    sans paramètres : la surcharge passe par le cache de `politique_koach`
    (aucun fichier n'est modifié)."""
    pk._params = None
    base = pk.params()
    if opts.get('defaut_modele') is not None:
        p = copy.deepcopy(base)
        p['mesure']['defaut_modele_sd'] = float(opts['defaut_modele'])
        pk._params = p


# ----------------------------------------------------------------------
# Politique : Koach complet, prévisions de P(réussite) exposées
# ----------------------------------------------------------------------
class PlanificationCampagne(pb.PlanificationBanc):
    """`PlanificationBanc` dont chaque prévision note aussi les cibles en
    vigueur (elles changent avec le profil, scénario
    `changement_discipline`)."""

    def _noter(self, semaine):
        n = len(self.previsions)
        pb.PlanificationBanc._noter(self, semaine)
        if len(self.previsions) > n:
            self.previsions[-1]['cibles'] = dict(self.cibles)


def politique(opts, graine):
    prm = parametres(opts)
    if opts['sans_planificateur']:
        return pk.PolitiqueKoach(parametres=prm)
    options = {'trajectoires': int(opts['trajectoires'])}
    fab = [lambda pol: PlanificationCampagne(pol, options, True), ek.fabrique_surveillance(),
           ek.fabrique_controle_dual(graine), ek.fabrique_adherence(graine)]
    return ek.PolitiqueBriques(parametres=prm, extensions=fab)


# ----------------------------------------------------------------------
# Mesures d'une saison
# ----------------------------------------------------------------------
def epreuves_par_jour(tour):
    """{jour: {exercice: [meilleure valeur réussie, maximum vrai du jour, mode]}}
    pour les tests des jours d'épreuve (règles de `mesures.evenements`)."""
    out = {}
    for s in tour.sets:
        if not (s['eventDay'] and s['test']):
            continue
        mx = s['dayMax']
        if mx is None or mx <= 0:
            continue
        ok = not (s['failed'] or s['amount'] < 1)
        v = ((s['totalKg'] or 0.0) if ok else 0.0) if s['mode'] == 'loaded' else float(s['amount'])
        e = out.setdefault(s['simDay'], {}).setdefault(s['exerciseId'], [0.0, mx, s['mode']])
        e[1] = mx
        if v > e[0]:
            e[0] = v
    return out


def unites_calibration(saison, tour, previsions):
    """Une unité par (saison, échéance) : prévisions de P(toutes les cibles)
    faites pour cette échéance, et réussite observée le jour J. Renvoie
    (unités, exclusions {raison: n})."""
    exclus = {}
    jours_epreuve = set()
    for jours in saison.get('eventDaysByWeek') or []:
        jours_epreuve.update(int(j) for j in jours)
    if not jours_epreuve:
        return [], {'sans_echeance': 1}
    prev = [p for p in previsions if p.get('echeance') is not None]
    if not prev:
        return [], {'sans_cible': 1}
    epreuves = epreuves_par_jour(tour)
    unites = []
    for E in sorted(set(int(p['echeance']) for p in prev)):
        ps = sorted((p for p in prev if int(p['echeance']) == E), key=lambda p: p['semaine'])
        cibles = ps[-1].get('cibles') or {}
        sem_E = E // 7
        if E not in jours_epreuve:
            exclus['echeance_deplacee'] = exclus.get('echeance_deplacee', 0) + 1
            continue
        obs = epreuves.get(E)
        if not obs:
            exclus['aucun_test_le_jour_j'] = exclus.get('aucun_test_le_jour_j', 0) + 1
            continue
        if not cibles or any(ex not in obs for ex in cibles):
            exclus['cible_non_testee'] = exclus.get('cible_non_testee', 0) + 1
            continue
        reussi = {ex: obs[ex][0] >= cibles[ex] - EPS for ex in cibles}
        capable = {ex: obs[ex][1] >= cibles[ex] - EPS for ex in cibles}
        d0 = ps[0]
        mi_cible = 0.5 * (d0['semaine'] + sem_E)
        mi = min(ps, key=lambda p: (abs(p['semaine'] - mi_cible), p['semaine']))
        m4 = [p for p in ps if p['semaine'] == sem_E - SEMAINES_AVANT]
        dates = {'debut': d0, 'mi_saison': mi, 'moins_4_semaines': m4[0] if m4 else None}
        unites.append({
            'echeance': E, 'cibles': cibles,
            'reussite': all(reussi.values()), 'reussite_capacite': all(capable.values()),
            'reussite_par_cible': reussi, 'capacite_par_cible': capable,
            'previsions': {k: (None if p is None else {'semaine': p['semaine'], 'p_tout': p.get('p_tout'),
                                                         'p': p.get('p')})
                           for k, p in dates.items()},
        })
    return unites, exclus


def blocs_servis_prescrits(saison, tour, tests_faits=False):
    """Blocs de référence où chaque séance faite est remplacée par les items
    que Koach a servis, tels que prescrits (séries prescrites, tests
    compris) ; une séance manquée garde l'écrit de `kalis_plan`.
    [tests_faits] : un item de test ajouté par Koach (créneau absent de
    l'écrit du jour, `kind` = test : test adaptatif, « vrai test ») compte
    pour les tentatives réellement faites et non pour les tentatives
    prescrites (le validateur compte chaque tentative comme une série dure)."""
    faites = {}
    toutes = {}
    if tests_faits:
        for x in tour.sets:
            k = (x['simDay'], x['slotId'])
            toutes[k] = toutes.get(k, 0) + 1
        for x in tour.sets:
            # Série dure au sens du validateur : réserve dite de 4 au plus
            # (flammes >= 3) ; les paliers faciles d'une montée de test n'en
            # sont pas (ce sont des séries d'approche).
            if x.get('flames') is not None and x['flames'] < 3 and not x.get('failed'):
                continue
            k = (x['simDay'], x['slotId'])
            faites[k] = faites.get(k, 0) + 1
    jour_de = {}
    for (g, bi, wb, di, sim_day) in saison['sessions']:
        jour_de[(g, bi, wb, di)] = sim_day
    blocs = copy.deepcopy(saison['blocks'])
    for (g, bi, wb, di, items) in tour.servi:
        for w in blocs[bi]['pass2']['weeks']:
            if w['weekIndex'] == wb:
                for d in w['days']:
                    if d['dayIndex'] == di:
                        ecrits = set(i['slotId'] for i in d['items'])
                        nouveaux = []
                        for i in items:
                            i = copy.deepcopy(i)
                            if tests_faits and i.get('kind') == 'test' and i['slotId'] not in ecrits:
                                n = faites.get((jour_de.get((g, bi, wb, di)), i['slotId']), 0)
                                if n == 0:
                                    continue
                                i['sets'] = n
                            elif tests_faits and i.get('sets') and i.get('kind') != 'warmup':
                                # Volume réellement fait (un exercice arrêté
                                # avant la fin ne compte pas ses séries non faites).
                                n = toutes.get((jour_de.get((g, bi, wb, di)), i['slotId']))
                                if n is not None and n < i['sets']:
                                    i['sets'] = n
                            nouveaux.append(i)
                        d['items'] = nouveaux
    return blocs


def _cle_constat(c):
    return (c.get('code'), c.get('week'), c.get('dayIndex'), c.get('exerciseId'))


def classer_constats(initial, servi):
    """Constats de [servi] classés contre ceux du plan initial : `deja_initial`
    (même code, semaine, jour, exercice, valeur pas plus haute), `aggrave`
    (même clé, valeur plus haute), `introduit` (absent du plan initial)."""
    reste = {}
    for c in initial:
        reste.setdefault(_cle_constat(c), []).append(c)
    out = {'deja_initial': {}, 'aggrave': {}, 'introduit': {}}
    exemples = []
    for c in sorted(servi, key=lambda c: (str(_cle_constat(c)), c.get('value') or 0.0)):
        k = _cle_constat(c)
        if reste.get(k):
            c0 = reste[k].pop(0)
            v, v0 = c.get('value'), c0.get('value')
            cat = 'aggrave' if (v is not None and v0 is not None and v > v0 + 1e-9) else 'deja_initial'
        else:
            cat = 'introduit'
        out[cat][c['code']] = out[cat].get(c['code'], 0) + 1
        if cat != 'deja_initial' and len(exemples) < 3:
            exemples.append({'categorie': cat, 'code': c['code'], 'semaine': c.get('week'),
                             'jour': c.get('dayIndex'), 'exercice': c.get('exerciseId'),
                             'valeur': c.get('value'), 'limite': c.get('limit')})
    return out, exemples


def securite_saison(saison, infos, tour, pol):
    initial = sb.constats_saison(saison, infos)
    out = {'initial': sb.comptes(initial)}
    plan = None
    for x in pol.koach.extensions:
        if isinstance(x, pb.PlanificationBanc):
            plan = x
    if plan is not None:
        mod = sb.constats_saison(saison, infos, blocs=plan.blocs_modules())
        cl, ex = classer_constats(initial, mod)
        out['plan_module'] = cl
        out['plan_module_exemples'] = ex
    for vue, sans in (('servi', False), ('servi_tests_faits', True)):
        blocs_s = blocs_servis_prescrits(saison, tour, sans)
        serv = sb.constats_saison(saison, infos, blocs=blocs_s)
        cl, ex = classer_constats(initial, serv)
        if sans and (cl['introduit'] or cl['aggrave']):
            cl, ex = retirer_retours_a_l_ecrit(saison, infos, initial, serv, blocs_s)
        out[vue] = cl
        out[vue + '_exemples'] = ex
    return out


def retirer_retours_a_l_ecrit(saison, infos, initial, serv, blocs_s):
    """Reclasse en `retour_ecrit` les constats « introduits » d'une semaine w
    qui disparaissent quand les semaines AVANT w sont celles de l'écrit et
    que la semaine w reste celle servie : la semaine servie n'a alors rien
    de trop, c'est le passé servi (allégé par une règle de sécurité :
    douleur, bilan bas, coupure, arrêt après échecs) qui était plus bas que
    l'écrit, et le retour au plan écrit dépasse la rampe hebdomadaire
    calculée sur ce passé allégé. Les constats qui restent sont de vrais
    dépassements de la semaine servie."""
    cles_ini = {}
    for c in initial:
        cles_ini[_cle_constat(c)] = cles_ini.get(_cle_constat(c), 0) + 1
    semaines = sorted({c.get('week') for c in serv if c.get('week') is not None})
    position = {}
    g = 0
    for bi, b in enumerate(saison['blocks']):
        for w in b['pass2']['weeks']:
            position[g] = (bi, w['weekIndex'])
            g += 1
    restants = []
    retours = {}
    for c in serv:
        w = c.get('week')
        k = _cle_constat(c)
        if cles_ini.get(k) or w is None or w not in position:
            restants.append(c)
            continue
        cache = retirer_retours_a_l_ecrit.__dict__.setdefault('_c', {})
        ident = (id(blocs_s), w)
        if ident not in cache:
            hyb = copy.deepcopy(saison['blocks'])
            bi, wi = position[w]
            for j, sem in enumerate(hyb[bi]['pass2']['weeks']):
                if sem['weekIndex'] == wi:
                    for sem_s in blocs_s[bi]['pass2']['weeks']:
                        if sem_s['weekIndex'] == wi:
                            hyb[bi]['pass2']['weeks'][j] = copy.deepcopy(sem_s)
            cache[ident] = {}
            for x in sb.constats_saison(saison, infos, blocs=hyb):
                cache[ident][_cle_constat(x)] = True
        if k in cache[ident]:
            restants.append(c)
        else:
            retours[c['code']] = retours.get(c['code'], 0) + 1
    retirer_retours_a_l_ecrit.__dict__['_c'] = {}
    cl, ex = classer_constats(initial, restants)
    cl['retour_ecrit'] = retours
    return cl, ex


def mesurer_saison(cle, scenario, verite, graine, opts):
    """Simule une saison et en tire tout ce que les critères lisent
    (sérialisable)."""
    infos = donnees.catalogue_infos()
    saison = cm._saison(cle, scenario, opts.get('semaines'))
    pol = politique(opts, graine)
    tour = meneur.simuler(saison, infos, pol, verite, graine)
    est = {}
    filtres = {'loadedMain': lambda e: e['mode'] == 'loaded' and e['main'],
               'loaded': lambda e: e['mode'] == 'loaded',
               'reps': lambda e: e['mode'] == 'reps',
               'hold': lambda e: e['mode'] == 'hold'}
    for m in MODES:
        E = mesures.Estimations()
        E.add(tour, filtres[m])
        est[m] = {'rows': E.rows, 'first_under': E.first_under}
    previsions = []
    alertes = None
    for x in pol.koach.extensions:
        if isinstance(x, PlanificationCampagne):
            previsions = x.previsions
        if isinstance(x, ek.SurveillanceBanc):
            alertes = sum(1 for j in x.journal if j.get('type') == 'alerte')
    unites, exclus = unites_calibration(saison, tour, previsions) if not opts['sans_planificateur'] else ([], {})
    return {
        'saison': [cle, scenario, verite, graine], 'niveau': saison['level'],
        'echeance': any(saison.get('eventDaysByWeek') or []),
        'estimations': est,
        'evenements': [list(e) for e in mesures.evenements(tour)],
        'effort': mesures.effort(tour), 'gain': mesures.gain_moyen(tour),
        'aggravations': tour.pain_aggravations, 'poussees': tour.pain_flares,
        'seances': tour.sessions_done, 'prevues': tour.sessions_planned,
        'alertes': alertes,
        'calibration': {'unites': unites, 'exclus': exclus},
        'securite': securite_saison(saison, infos, tour, pol),
    }


def _nom(job):
    return '%s__%s__%s__%d' % job


def _tache(job):
    """Une saison dans un processus de la campagne : résultat écrit dans le
    dossier de travail (reprise)."""
    opts = _OPTS
    chemin = os.path.join(opts['dossier'], _nom(job) + '.json')
    t0 = time.perf_counter()
    try:
        r = mesurer_saison(job[0], job[1], job[2], job[3], opts)
    except Exception as exc:
        tb = traceback.format_exc().strip().splitlines()
        r = {'saison': list(job), 'plantage': '%s: %s' % (type(exc).__name__, str(exc)[:300]),
             'trace': [l.strip() for l in tb[-7:]]}
    r['duree_s'] = time.perf_counter() - t0
    _ecrire_json(chemin, r)
    return job, r


# ----------------------------------------------------------------------
# Matrice et exécution
# ----------------------------------------------------------------------
def lire_profils(arg):
    if arg in (None, 'tous'):
        return donnees.profils()
    if os.path.isfile(arg):
        with open(arg, encoding='utf-8') as f:
            texte = f.read()
        return [c.strip() for c in texte.replace('\n', ',').split(',') if c.strip()]
    return [c.strip() for c in arg.split(',') if c.strip()]


def matrice(profils, scenarios, verites, graines):
    jobs = []
    for cle in profils:
        for s in donnees.saisons_reference(cle):
            if scenarios != ['tous'] and s['scenario'] not in scenarios:
                continue
            for v in verites:
                for g in range(graines):
                    jobs.append((cle, s['scenario'], v, g))
    return jobs


def executer(jobs, opts, journal=print):
    """Résultats de toutes les saisons [jobs] (cache du dossier de travail,
    puis calcul parallèle des manquantes). Renvoie {job: résultat}."""
    global _OPTS
    appliquer_parametres(opts)
    sources = empreinte_sources()
    opts = dict(opts)
    opts['dossier'] = dossier_de(opts, sources)
    _OPTS = opts
    res = {}
    a_faire = []
    for job in jobs:
        r = _lire_json(os.path.join(opts['dossier'], _nom(job) + '.json'))
        if r is not None and r.get('saison') == list(job):
            res[job] = r
        else:
            a_faire.append(job)
    journal('campagne : %d saisons, %d en cache, %d à calculer (dossier %s)'
            % (len(jobs), len(jobs) - len(a_faire), len(a_faire), opts['dossier']))
    t0 = time.time()
    fait = 0
    plantees = 0
    pas = 50 if len(a_faire) > 100 else max(1, min(50, len(a_faire) // 4 or 1))
    if a_faire:
        if opts['coeurs'] <= 1 or len(a_faire) == 1:
            it = map(_tache, a_faire)
            pool = None
        else:
            from multiprocessing import get_context
            pool = get_context('fork').Pool(opts['coeurs'])
            it = pool.imap_unordered(_tache, a_faire, chunksize=1)
        try:
            for job, r in it:
                res[job] = r
                fait += 1
                if 'plantage' in r:
                    plantees += 1
                if fait % pas == 0 or fait == len(a_faire):
                    dt = time.time() - t0
                    journal('  %d/%d saisons (%d plantée(s)) — %.0f s, %.2f s/saison, reste ~%.0f s'
                            % (fait, len(a_faire), plantees, dt, dt / fait, dt / fait * (len(a_faire) - fait)))
        finally:
            if pool is not None:
                pool.close()
                pool.join()
    durees = [r['duree_s'] for r in res.values() if r.get('duree_s') is not None]
    return res, {'dossier': opts['dossier'], 'sources': sources, 'calculees': len(a_faire),
                 'duree_moyenne_s': _moy(durees), 'duree_totale_s': sum(durees)}


# ----------------------------------------------------------------------
# Témoin 0.3.1
# ----------------------------------------------------------------------
def charger_temoin(jobs):
    """Saisons du témoin correspondant aux triplets (profil, scénario,
    vérité) de [jobs] : estimations agrégées (16 graines) et runs par graine."""
    triplets = sorted(set((j[0], j[1], j[2]) for j in jobs))
    par_cle = {}
    out = {}
    for (cle, scen, v) in triplets:
        if cle not in par_cle:
            try:
                par_cle[cle] = {s['scenario']: s for s in donnees.temoin(cle)}
            except (OSError, ValueError):
                par_cle[cle] = {}
        s = par_cle[cle].get(scen)
        if s is None or v not in s['truths']:
            continue
        out[(cle, scen, v)] = s['truths'][v]
    return out


def niveau_de(cle, scen):
    for s in donnees.saisons_reference(cle):
        if s['scenario'] == scen:
            return s['level']
    return None


# ----------------------------------------------------------------------
# Agrégation
# ----------------------------------------------------------------------
def _cumul(E, rows, first_under):
    for k in range(len(rows)):
        for c in range(len(rows[k])):
            E.rows[k][c] += rows[k][c]
    E.first_under += list(first_under)


def _ligne(E, k):
    """Ligne de rang [k] ; pour le témoin (export sans écart-type), `sd` est
    omis."""
    l = E.ligne(k)
    if l is None:
        return None
    cles = ('n', 'mae', 'biais', 'rmse', 'sous3', 'couverture', 'sd')
    if getattr(E, 'temoin', False):
        cles = cles[:-1]
    return {x: l[x] for x in cles if x in l}


def _temoin_vide():
    E = mesures.Estimations()
    E.temoin = True
    return E


def _premier_passage(f):
    atteints = [x for x in f if x > 0]
    cens = [x if x > 0 else JAMAIS for x in f]
    return {'n': len(f), 'moyenne_censuree': _moy(cens), 'moyenne_atteints': _moy(atteints),
            'mediane_censuree': _mediane(cens),
            'part_jamais': (1 - len(atteints) / float(len(f))) if f else None}


def agreger_estimations(ok, temoin):
    K = {m: mesures.Estimations() for m in MODES}
    KV, KN = {}, {}
    T = {m: _temoin_vide() for m in MODES}
    TV, TN = {}, {}
    for r in ok:
        cle, scen, v, g = r['saison']
        for m in MODES:
            _cumul(K[m], r['estimations'][m]['rows'], r['estimations'][m]['first_under'])
        lm = r['estimations']['loadedMain']
        _cumul(KV.setdefault(v, mesures.Estimations()), lm['rows'], lm['first_under'])
        _cumul(KN.setdefault(str(r['niveau']), mesures.Estimations()), lm['rows'], lm['first_under'])
    for (cle, scen, v), t in sorted(temoin.items()):
        for m in MODES:
            T[m].ajouter_temoin(t['estimates'][m])
        TV.setdefault(v, _temoin_vide()).ajouter_temoin(t['estimates']['loadedMain'])
        TN.setdefault(str(niveau_de(cle, scen)), _temoin_vide()).ajouter_temoin(t['estimates']['loadedMain'])
    return K, KV, KN, T, TV, TN


def critere_e1rm(K, KV, KN, T, TV, TN):
    k = _ligne(K['loadedMain'], RANG)
    t = _ligne(T['loadedMain'], RANG)
    mesure = k['mae'] if k else None
    return {
        'mesure': mesure, 'seuil': SEUIL_E1RM, 'n': k['n'] if k else 0,
        'respecte': bool(mesure is not None and mesure < SEUIL_E1RM),
        'methode': ("MAE relative |e1RM estimé / e1RM vrai − 1| au rang 6 (6e jour d'entraînement de "
                    "l'exercice, dernière estimation du jour, `mesures.Estimations`) sur les mouvements "
                    "principaux chargés ; témoin : export 0.3.1 (16 graines) sur les mêmes saisons."),
        'detail': {
            'koach': k, 'temoin': t,
            'par_verite': {v: {'koach': _ligne(KV[v], RANG), 'temoin': _ligne(TV[v], RANG) if v in TV else None}
                           for v in sorted(KV)},
            'par_niveau': {n: {'koach': _ligne(KN[n], RANG), 'temoin': _ligne(TN[n], RANG) if n in TN else None}
                           for n in sorted(set(KN) | set(TN))},
            'autres_modes_rang_6': {m: {'koach': _ligne(K[m], RANG), 'temoin': _ligne(T[m], RANG)}
                                    for m in ('loaded', 'reps', 'hold')},
        },
    }


def critere_convergence(K, KV, T, TV):
    pk_ = _premier_passage(K['loadedMain'].first_under)
    pt = _premier_passage(T['loadedMain'].first_under)
    mk, mt = pk_['moyenne_censuree'], pt['moyenne_censuree']
    return {
        'mesure': mk, 'seuil': mt, 'n': pk_['n'],
        'respecte': bool(mk is not None and mt is not None and mk <= mt + EPS),
        'methode': ("Par exercice principal chargé et par saison, premier rang de séance où |erreur| < 3 %% "
                    "(`first_under`) ; moyenne avec « jamais » compté %d (censure), à comparer au témoin "
                    "0.3.1 sur les mêmes (profil, scénario, vérité) ; seuil = valeur du témoin." % JAMAIS),
        'detail': {
            'koach': pk_, 'temoin': pt,
            'premier_rang_mae_sous_3': {'koach': K['loadedMain'].premier_rang_sous(),
                                        'temoin': T['loadedMain'].premier_rang_sous()},
            'par_verite': {v: {'koach': _premier_passage(KV[v].first_under),
                               'temoin': _premier_passage(TV[v].first_under) if v in TV else None}
                           for v in sorted(KV)},
        },
    }


def critere_couverture(K, KV, opts):
    a = K['loadedMain'].apres(RANG_COUVERTURE)
    c = a['couverture'] if a else None
    lo, hi = SEUIL_COUVERTURE
    return {
        'mesure': c, 'seuil': [lo, hi], 'n': a['n'] if a else 0,
        'respecte': bool(c is not None and lo - EPS <= c <= hi + EPS),
        'methode': ("Part des estimations (principaux chargés, rangs >= 3) dont l'intervalle à 90 % de Koach "
                    "[exp(mu ∓ 1,645 sd)] contient la capacité vraie (à frais)."),
        'detail': {
            'defaut_modele_sd': (opts['defaut_modele'] if opts['defaut_modele'] is not None
                                 else parametres(opts)['mesure'].get('defaut_modele_sd')),
            'par_rang': {str(k): ({'n': l['n'], 'couverture': l['couverture'], 'sd': l['sd']}
                                  if l else None) for k, l in ((k, _ligne(K['loadedMain'], k)) for k in RANGS)},
            'par_mode_rangs_3_et_plus': {m: (lambda x: {'n': x['n'], 'couverture': x['couverture']} if x else None)
                                         (K[m].apres(RANG_COUVERTURE)) for m in MODES},
            'tous_modes_rangs_3_et_plus': _tous_modes(K),
            'par_verite': {v: (lambda x: {'n': x['n'], 'couverture': x['couverture']} if x else None)
                           (KV[v].apres(RANG_COUVERTURE)) for v in sorted(KV)},
        },
    }


def _tous_modes(K):
    n = cov = 0.0
    for m in ('loaded', 'reps', 'hold'):
        a = K[m].apres(RANG_COUVERTURE)
        if a:
            n += a['n']
            cov += a['couverture'] * a['n']
    return {'n': int(n), 'couverture': cov / n if n else None}


def _deciles(paires):
    out = []
    pire = None
    for d in range(10):
        sel = [(p, o) for (p, o) in paires if min(9, int(math.floor(p * 10))) == d]
        n = len(sel)
        if n == 0:
            out.append({'decile': d, 'n': 0, 'signal': 'vide'})
            continue
        pm = sum(p for p, _ in sel) / n
        om = sum(1.0 for _, o in sel if o) / n
        e = abs(pm - om)
        ligne = {'decile': d, 'n': n, 'p_prevue': pm, 'observee': om, 'ecart': e}
        if n < N_MIN_DECILE:
            ligne['signal'] = 'n < %d' % N_MIN_DECILE
        elif pire is None or e > pire:
            pire = e
        out.append(ligne)
    return out, pire


def critere_calibration(ok, sans_planificateur):
    if sans_planificateur:
        return {'mesure': None, 'seuil': SEUIL_CALIBRATION, 'n': 0, 'respecte': False,
                'methode': 'non mesuré : campagne sans planificateur (aucune prévision de P(réussite)).',
                'detail': {}}
    exclus = {}
    unites = []
    for r in ok:
        for k, v in r['calibration']['exclus'].items():
            exclus[k] = exclus.get(k, 0) + v
        for u in r['calibration']['unites']:
            unites.append((r['saison'], u))
    par_date = {}
    pires = []
    manque = {}
    insuffisant = {}
    for date in ('debut', 'mi_saison', 'moins_4_semaines'):
        paires = []
        paires_cap = []
        for (_, u) in unites:
            p = u['previsions'].get(date)
            if p is None or p.get('p_tout') is None:
                manque[date] = manque.get(date, 0) + 1
                continue
            paires.append((float(p['p_tout']), u['reussite']))
            paires_cap.append((float(p['p_tout']), u['reussite_capacite']))
        dec, pire = _deciles(paires)
        dec_cap, pire_cap = _deciles(paires_cap)
        mes = sum(1 for x in dec if x['n'] >= N_MIN_DECILE)
        if mes < DECILES_MIN:
            insuffisant[date] = mes
        par_date[date] = {'n': len(paires), 'deciles': dec, 'ecart_max_deciles_n20': pire,
                          'deciles_mesurables': mes,
                          'p_moyenne': _moy([p for p, _ in paires]),
                          'reussite_observee': _moy([1.0 if o else 0.0 for _, o in paires]),
                          'variante_capacite_du_jour': {'deciles': dec_cap, 'ecart_max_deciles_n20': pire_cap,
                                                        'reussite_observee': _moy([1.0 if o else 0.0
                                                                                   for _, o in paires_cap])}}
        pires.append(pire)
    # Calibration marginale par cible (toutes dates confondues).
    marg = []
    marg_cap = []
    for (_, u) in unites:
        for date, p in sorted(u['previsions'].items()):
            if p is None or not p.get('p'):
                continue
            for ex, pe in sorted(p['p'].items()):
                if ex in u['reussite_par_cible']:
                    marg.append((float(pe), u['reussite_par_cible'][ex]))
                if ex in (u.get('capacite_par_cible') or {}):
                    marg_cap.append((float(pe), u['capacite_par_cible'][ex]))
    dec_m, pire_m = _deciles(marg)
    dec_mc, pire_mc = _deciles(marg_cap)
    mesurable = all(x is not None for x in pires) and not insuffisant
    mesure = max(x for x in pires if x is not None) if any(x is not None for x in pires) else None
    return {
        'mesure': mesure, 'seuil': SEUIL_CALIBRATION, 'n': len(unites),
        'respecte': bool(mesurable and mesure <= SEUIL_CALIBRATION + EPS),
        'methode': ("P(toutes les cibles atteintes à l'échéance) prévue par la planification (`objectif` de la "
                    "replanification, journal `previsions` de PlanificationBanc) au début, à mi-chemin et 4 "
                    "semaines avant l'échéance, contre la réussite observée (meilleure barre réussie au test "
                    "du jour J >= cible, toutes cibles) ; déciles de probabilité prévue, écart |prévu − observé| "
                    "max sur les déciles de n >= %d, pire des trois dates ; mesurable seulement si chaque "
                    "date a au moins %d déciles de n >= %d." % (N_MIN_DECILE, DECILES_MIN, N_MIN_DECILE)),
        'detail': {
            'par_date': par_date,
            'exclusions': dict(sorted(exclus.items())),
            'unites_sans_prevision_a_la_date': manque,
            'marginale_par_cible': {'n': len(marg), 'deciles': dec_m, 'ecart_max_deciles_n20': pire_m,
                                    'variante_capacite_du_jour': {'n': len(marg_cap), 'deciles': dec_mc,
                                                                  'ecart_max_deciles_n20': pire_mc}},
            'mesurable': mesurable,
            'dates_insuffisantes': insuffisant,
        },
    }


def _ratios(evs, mode, i_best, i_max):
    return [e[i_best] / e[i_max] for e in evs if e[1] == mode and e[i_max]]


def critere_jour_j(ok, temoin):
    """Saisons appariées : même (profil, scénario, vérité, graine)."""
    runs_t = {}
    for (cle, scen, v), t in temoin.items():
        for run in t['runs']:
            runs_t[(cle, scen, v, run['seed'])] = run
    par_mode = {}
    for mode in ('loaded', 'reps', 'hold'):
        ek_, et_, dk, dt = [], [], [], []
        diffs = []
        par_scen, par_ver = {}, {}
        sans = {'koach_sans_test': 0, 'temoin_sans_test': 0, 'aucun_test': 0, 'temoin_absent': 0}
        n_saisons = 0
        for r in ok:
            if not r['echeance']:
                continue
            cle, scen, v, g = r['saison']
            run = runs_t.get((cle, scen, v, g))
            rk = _ratios(r['evenements'], mode, 2, 4)
            if run is None:
                sans['temoin_absent'] += 1
                continue
            rt = _ratios(run['events'], mode, 3, 5)
            if not rk and not rt:
                if mode == 'loaded':
                    sans['aucun_test'] += 1
                continue
            if not rk:
                sans['koach_sans_test'] += 1
                continue
            if not rt:
                sans['temoin_sans_test'] += 1
                continue
            n_saisons += 1
            ek_ += rk
            et_ += rt
            diffs.append(_moy(rk) - _moy(rt))
            for d, cle_d in ((par_scen, scen), (par_ver, v)):
                x = d.setdefault(cle_d, [[], []])
                x[0] += rk
                x[1] += rt
        par_mode[mode] = {
            'saisons_appariees': n_saisons, 'tests': [len(ek_), len(et_)],
            'koach': _moy(ek_), 'temoin': _moy(et_),
            'ecart_apparie_moyen': _moy(diffs), 'ecart_apparie_se': _se(diffs),
            'saisons_sans_test': sans,
            'par_scenario': {s: {'koach': _moy(x[0]), 'temoin': _moy(x[1]), 'n': [len(x[0]), len(x[1])]}
                             for s, x in sorted(par_scen.items())},
            'par_verite': {s: {'koach': _moy(x[0]), 'temoin': _moy(x[1]), 'n': [len(x[0]), len(x[1])]}
                           for s, x in sorted(par_ver.items())},
        }
    # Témoin sur toutes ses graines (référence, non apparié).
    tous = []
    for (cle, scen, v), t in temoin.items():
        for run in t['runs']:
            tous += _ratios(run['events'], 'loaded', 3, 5)
    L = par_mode['loaded']
    mk, mt = L['koach'], L['temoin']
    return {
        'mesure': mk, 'seuil': mt, 'n': L['saisons_appariees'],
        'respecte': bool(mk is not None and mt is not None and mk >= mt - EPS),
        'methode': ("Jour de l'échéance, mouvements chargés testés : meilleure charge totale réussie / maximum "
                    "vrai du jour (`mesures.evenements`, ligne « echeance loaded best/max » d'essai2/temoin), "
                    "moyenne sur les tests des saisons appariées (même profil, scénario, vérité et graine) où "
                    "Koach et le témoin ont tous deux un test ; seuil = moyenne du témoin."),
        'detail': {'par_mode': par_mode, 'temoin_toutes_graines': {'n': len(tous), 'moyenne': _moy(tous)}},
    }


def _somme_dicts(dicts):
    out = {}
    for d in dicts:
        for k, v in (d or {}).items():
            out[k] = out.get(k, 0) + v
    return dict(sorted(out.items()))


def critere_securite(ok, temoin, sans_planificateur):
    agg = sum(r['aggravations'] for r in ok)
    fl = sum(r['poussees'] for r in ok)
    hausses = sum(r['effort']['hausses_trop_fortes'] for r in ok)
    sec = {}
    saisons_intro = {}
    for vue in VUES_SECURITE:
        if sans_planificateur and vue == 'plan_module':
            continue
        cats = {}
        exemples = []
        for cat in ('deja_initial', 'aggrave', 'introduit', 'retour_ecrit'):
            cats[cat] = _somme_dicts(r['securite'][vue].get(cat) or {} for r in ok)
        n_intro = 0
        for r in ok:
            s = r['securite'][vue]
            if s['introduit'] or s['aggrave']:
                n_intro += 1
                if len(exemples) < 8:
                    exemples.append({'saison': r['saison'], 'constats': r['securite'][vue + '_exemples']})
        cats['saisons_touchees'] = n_intro
        cats['exemples'] = exemples
        sec[vue] = cats
        saisons_intro[vue] = n_intro
    initial = _somme_dicts(r['securite']['initial'] for r in ok)
    # Témoin : mêmes saisons (graines appariées) et toutes ses graines.
    runs_t = {}
    for (cle, scen, v), t in temoin.items():
        for run in t['runs']:
            runs_t[(cle, scen, v, run['seed'])] = run
    app = [runs_t[tuple(r['saison'])] for r in ok if tuple(r['saison']) in runs_t]
    tous = [run for t in temoin.values() for run in t['runs']]
    hausses_t = sum(t['coach'].get('schemeRisesOverLimit', 0) for t in temoin.values())

    def _t(runs):
        return {'saisons': len(runs), 'aggravations': sum(x['painAggravations'] for x in runs),
                'poussees': sum(x['painFlares'] for x in runs),
                'violations': sum(x['violations'] for x in runs),
                'codes': _somme_dicts(x.get('violationCodes') for x in runs)}

    def _intro(vue):
        if vue not in sec:
            return 0
        return sum(sec[vue]['introduit'].values()) + sum(sec[vue]['aggrave'].values())

    total = agg + fl + hausses + _intro('plan_module') + _intro('servi_tests_faits')
    return {
        'mesure': total, 'seuil': 0, 'n': len(ok), 'respecte': total == 0,
        'mesure_avec_rampes_de_test': agg + fl + hausses + _intro('plan_module') + _intro('servi'),
        'methode': ("Somme (a) des aggravations et poussées de douleur de l'athlète simulé, (b) des constats du "
                    "validateur `securite_banc` introduits ou aggravés par Koach par rapport au plan initial de "
                    "kalis_plan (sur `blocs_modules` de la planification et sur les séances servies telles que "
                    "prescrites, tests ajoutés par Koach comptés pour leurs tentatives faites), (c) des hausses de charge > 10 % "
                    "sur plusieurs crans (`mesures.effort`). La vue `servi` (rampes de test comprises) est "
                    "rapportée à part : `mesure_avec_rampes_de_test`."),
        'detail': {
            'a_douleur': {'aggravations': agg, 'poussees': fl},
            'b_validateur': {'plan_initial': initial, 'vues': sec,
                             'note': ("`plan_module` = blocs de référence + plan de la planification "
                                      "(`Planification.blocs_modules`) ; `servi` = blocs de référence où chaque "
                                      "séance faite est remplacée par les items servis par Koach (séries "
                                      "prescrites, contrôle dual et allègement compris) ; "
                                      "`servi_tests_faits` = idem, tests ajoutés par Koach comptés pour "
                                      "leurs tentatives faites (le validateur compte chaque tentative "
                                      "prescrite d'une rampe de test comme une série dure)")},
            'c_hausses_trop_fortes': hausses,
            'temoin_apparie': _t(app), 'temoin_toutes_graines': _t(tous),
            'temoin_hausses_trop_fortes': hausses_t,
        },
    }


def critere_mauvais_jour(mj):
    h = {k: {'moyenne_abs': mj['ecart_abs'][k]['moyenne'], 'mediane_abs': mj['ecart_abs'][k]['mediane'],
             'p95_abs': mj['ecart_abs'][k]['p95'], 'max_abs': mj['ecart_abs'][k]['max'],
             'n': mj['ecart_abs'][k]['n'], 'signe_moyen': mj['ecart_signe_moyen'][k]} for k in cm.HORIZONS}
    moy = [x['moyenne_abs'] for x in h.values() if x['moyenne_abs'] is not None]
    return {
        'mesure': max(moy) if moy else None, 'seuil': cm.SEUIL_MAUVAIS_JOUR,
        'n': mj['saisons_mesurees'], 'respecte': bool(mj['respecte']),
        'methode': ("`criteres_moteur.mesurer_mauvais_jour` : même saison rejouée avec une séance à −6 % de "
                    "capacité (2e moitié, après 6 séances), écart relatif des e1RM des principaux chargés juste "
                    "après, +1 et +2 séances ; mesure = pire moyenne absolue des trois horizons."),
        'detail': {'horizons': h, 'saisons': mj['saisons'], 'plantages': len(mj['plantages']),
                   'jobs': mj.get('jobs')},
    }


def critere_temps(t, source):
    return {
        'mesure': {'observe_serie_ms_max': t['observe_serie_ms']['max'],
                   'replanification_s_max': t['replanification_s']['max']},
        'seuil': {'serie_ms': cm.SEUIL_SERIE_MS, 'replanification_s': cm.SEUIL_REPLANIFICATION_S},
        'n': t['observe_serie_ms']['n'], 'respecte': bool(t['respecte']),
        'methode': ("`criteres_moteur.mesurer_temps` : `observe` série et `plan` sur une saison complète, puis "
                    "chaque replanification (validateur compris) ; indicatif (Python, cette machine)."),
        'detail': {'source': source, 'observe_serie_ms': t['observe_serie_ms'], 'plan_serie_ms': t['plan_serie_ms'],
                   'plan_seance_ms': t['plan_seance_ms'], 'replanification_s': t['replanification_s'],
                   'replanification': t.get('replanification'), 'saison': t.get('saison')},
    }


def critere_rappels():
    out = {'methode': 'lecture seule des fichiers existants, sans recalcul', 'detail': {}}
    d = _lire_json(os.path.join(RACINE, 'donnees', 'comparaison_adversaires.json'))
    if d is not None:
        c = d.get('critere') or {}
        out['detail']['pire_cas_adversarial'] = {
            'fichier': 'donnees/comparaison_adversaires.json', 'critere': c,
            'pires': (d.get('groupes') or {}).get('pires')}
    else:
        out['detail']['pire_cas_adversarial'] = None
    j = _lire_json(os.path.join(RACINE, 'donnees', 'rejeu_journal_agregats.json'))
    if j is not None:
        out['detail']['rejeu_journal'] = {
            'fichier': 'donnees/rejeu_journal_agregats.json',
            'objectif_brique_8': j.get('objectif_brique_8'), 'rejeu': j.get('rejeu'),
            'une_seance_d_avance': (j.get('A_une_seance_d_avance') or {}).get('total'),
            'series_fiables': (j.get('A_series_fiables_1_5_en_reserve_ou_moins') or {}).get('total'),
            'tests_reels': (j.get('B_tests_reels') or {}).get('total')}
    else:
        out['detail']['rejeu_journal'] = None
    respecte = {}
    if d is not None and 'respecte' in (d.get('critere') or {}):
        respecte['pire_cas_adversarial'] = bool(d['critere']['respecte'])
    if j is not None and j.get('objectif_brique_8'):
        respecte['rejeu_journal'] = bool(all(j['objectif_brique_8'].values()))
    out['respecte'] = respecte
    return out


def secondaires(ok, K, T, temoin):
    ee = [r['effort'] for r in ok if r['effort']['ecart_effort'] is not None]
    gains = [r['gain'] for r in ok if r['gain'] is not None]
    seances = sum(r['seances'] for r in ok)
    alertes = [r['alertes'] for r in ok if r['alertes'] is not None]
    gap_t = [t['coach']['effortGap']['mean'] for t in temoin.values() if t['coach']['effortGap']['n']]
    fail_t = [t['coach']['failRate']['mean'] for t in temoin.values()]
    gain_t = [run['gainMean'] for t in temoin.values() for run in t['runs'] if run.get('gainMean') is not None]
    return {
        'mae_rang_6': {m: {'koach': _ligne(K[m], RANG), 'temoin': _ligne(T[m], RANG)} for m in ('reps', 'hold')},
        'ecart_effort': {'koach': _moy([e['ecart_effort'] for e in ee]), 'temoin': _moy(gap_t)},
        'echecs': {'koach': _moy([e['echecs'] for e in ee]), 'temoin': _moy(fail_t)},
        'tentatives_reussies': {'koach': _moy([e['tentatives'] for e in ee if e['tentatives'] is not None])},
        'gain_moyen_hebdo': {'koach': _moy(gains), 'temoin': _moy(gain_t)},
        'alertes_rupture_par_100_seances': {
            'koach': (100.0 * sum(alertes) / seances) if (alertes and seances) else None, 'alertes': sum(alertes),
            'seances': seances},
        'seances_faites_sur_prevues': _moy([r['seances'] / float(r['prevues']) for r in ok if r['prevues']]),
    }


# ----------------------------------------------------------------------
# Critères 2 et 8 (repris de criteres_moteur, en cache)
# ----------------------------------------------------------------------
def jobs_mj(profils, verites, graines, rapide):
    if rapide:
        return [('street_16_specialisation_traction_lestee', 'a', 0)]
    cles = [c for c in profils if c in cm.PROFILS_CHARGES] or list(cm.PROFILS_CHARGES)
    return [(c, v, g) for c in cles for v in verites for g in range(max(1, min(graines, 2)))]


def mesure_mauvais_jour(opts, dossier, jobs):
    chemin = os.path.join(dossier, 'mauvais_jour__%s.json'
                          % hashlib.sha256(json.dumps(jobs).encode('utf-8')).hexdigest()[:12])
    r = _lire_json(chemin)
    if r is None:
        r = cm.mesurer_mauvais_jour(jobs=[tuple(j) for j in jobs], coeurs=opts['coeurs'])
        r.pop('mesures', None)
        r['jobs'] = len(jobs)
        r['plantages'] = [p.get('trace', '')[-300:] for p in r['plantages']]
        _ecrire_json(chemin, r)
    return r


def mesure_temps(opts, dossier):
    if opts['rapide'] or opts['temps_existants']:
        d = _lire_json(os.path.join(RACINE, 'donnees', 'criteres_moteur.json'))
        if d is not None and d.get('temps'):
            return d['temps'], 'donnees/criteres_moteur.json (lu, non remesuré)'
    chemin = os.path.join(dossier, 'temps.json')
    t = _lire_json(chemin)
    if t is None:
        t = cm.mesurer_temps(options={'trajectoires': int(opts['trajectoires'])})
        _ecrire_json(chemin, t)
    return t, 'mesuré (criteres_moteur.mesurer_temps, en cache dans le dossier de travail)'


# ----------------------------------------------------------------------
# Campagne
# ----------------------------------------------------------------------
def campagne(opts, journal=print):
    profils = lire_profils(opts['profils'])
    scenarios = ['tous'] if opts['scenarios'] in (None, 'tous') else opts['scenarios'].split(',')
    jobs = matrice(profils, scenarios, opts['verites'], opts['graines'])
    res, info = executer(jobs, opts, journal)
    ok = [res[j] for j in jobs if 'plantage' not in res[j]]
    plantes = [{'saison': list(j), 'erreur': res[j]['plantage'], 'trace': res[j].get('trace')}
               for j in jobs if 'plantage' in res[j]]
    temoin = charger_temoin(jobs)
    K, KV, KN, T, TV, TN = agreger_estimations(ok, temoin)
    journal('critère 2 (mauvais jour) ...')
    mj = mesure_mauvais_jour(opts, info['dossier'], jobs_mj(profils, opts['verites'], opts['graines'],
                                                             opts['rapide']))
    journal('critère 8 (temps) ...')
    tps, source = mesure_temps(opts, info['dossier'])
    criteres = {
        '1_erreur_e1rm_rang_6': critere_e1rm(K, KV, KN, T, TV, TN),
        '2_mauvais_jour_isole': critere_mauvais_jour(mj),
        '3_convergence_sous_3': critere_convergence(K, KV, T, TV),
        '4_couverture_90': critere_couverture(K, KV, opts),
        '5_calibration_p_reussite': critere_calibration(ok, opts['sans_planificateur']),
        '6_performance_jour_j': critere_jour_j(ok, temoin),
        '7_securite': critere_securite(ok, temoin, opts['sans_planificateur']),
        '8_temps_calcul': critere_temps(tps, source),
        '9_rappels': critere_rappels(),
    }
    bilan = {'respectes': sorted(k for k, c in criteres.items() if c.get('respecte') is True),
             'non_respectes': sorted(k for k, c in criteres.items() if c.get('respecte') is False)}
    sortie = {
        'schema': SCHEMA,
        'configuration': {'profils': profils, 'scenarios': scenarios, 'verites': opts['verites'],
                          'graines': opts['graines'], 'trajectoires': int(opts['trajectoires']),
                          'planificateur': not opts['sans_planificateur'],
                          'extensions': ([] if opts['sans_planificateur'] else
                                         ['PlanificationBanc', 'SurveillanceBanc', 'ControleDualBanc',
                                          'AdherenceBanc']),
                          'defaut_modele_sd': opts['defaut_modele'], 'rapide': opts['rapide'],
                          'semaines': opts.get('semaines')},
        'empreinte_sources': info['sources'],
        'saisons': {'prevues': len(jobs), 'mesurees': len(ok), 'plantees': len(plantes), 'plantages': plantes,
                    'temoin_triplets': len(temoin)},
        'criteres': criteres,
        'secondaires': secondaires(ok, K, T, temoin),
        'bilan': bilan,
    }
    return _arrondir(sortie), info


def couverture_de(opts, jobs, journal=print):
    res, _ = executer(jobs, opts, journal)
    E = mesures.Estimations()
    for j in jobs:
        r = res[j]
        if 'plantage' in r:
            continue
        lm = r['estimations']['loadedMain']
        _cumul(E, lm['rows'], lm['first_under'])
    a = E.apres(RANG_COUVERTURE)
    return a['couverture'] if a else None


def caler_couverture(opts, journal=print, cible=0.90, iterations=7):
    """Plus petite valeur de `defaut_modele_sd` donnant une couverture >= [cible]
    (dichotomie) sur SET9 × `reference` × vérités × 4 graines. N'écrit pas
    le fichier de paramètres."""
    profils = lire_profils(SET9 if os.path.isfile(SET9) else opts['profils'])
    jobs = matrice(profils, ['reference'], opts['verites'], 4)
    essais = {}

    def cov(x):
        o = dict(opts)
        o['defaut_modele'] = x
        c = couverture_de(o, jobs, journal)
        essais[x] = c
        journal('  defaut_modele_sd = %.5f -> couverture %.4f' % (x, c if c is not None else float('nan')))
        return c

    lo = 0.0
    if cov(lo) >= cible:
        return lo, essais
    hi = 0.02
    while cov(hi) < cible:
        lo = hi
        hi *= 2
        if hi > 0.64:
            return None, essais
    for _ in range(iterations):
        m = 0.5 * (lo + hi)
        if cov(m) >= cible:
            hi = m
        else:
            lo = m
    return hi, essais


def resume(s):
    c = s['criteres']
    lignes = []

    def f(x, pct=False):
        if x is None:
            return '—'
        return ('%.2f %%' % (100 * x)) if pct else ('%.4g' % x)

    def ok(k):
        r = c[k].get('respecte')
        return 'OK ' if r is True else ('NON' if r is False else ' ? ')

    sa = s['saisons']
    lignes.append('saisons : %d prévues, %d mesurées, %d plantées' % (sa['prevues'], sa['mesurees'], sa['plantees']))
    d = c['1_erreur_e1rm_rang_6']
    t = d['detail']['temoin']
    lignes.append('[%s] 1 e1RM rang 6 : Koach %s (n=%d), témoin %s ; seuil < 3 %%'
                  % (ok('1_erreur_e1rm_rang_6'), f(d['mesure'], True), d['n'], f(t['mae'] if t else None, True)))
    pv = d['detail']['par_verite']
    lignes.append('      par vérité : ' + ', '.join('%s %s/%s' % (v, f((x['koach'] or {}).get('mae'), True),
                                                            f((x['temoin'] or {}).get('mae'), True))
                                                    for v, x in sorted(pv.items())))
    d = c['2_mauvais_jour_isole']
    h = d['detail']['horizons']
    lignes.append('[%s] 2 mauvais jour : |écart| moyen %s (après) %s (+1) %s (+2), médian après %s, signé %s ; seuil < 1 %%'
                  % (ok('2_mauvais_jour_isole'), f(h['apres']['moyenne_abs'], True), f(h['plus_1']['moyenne_abs'], True),
                     f(h['plus_2']['moyenne_abs'], True), f(h['apres']['mediane_abs'], True),
                     f(h['apres']['signe_moyen'], True)))
    d = c['3_convergence_sous_3']
    k, t = d['detail']['koach'], d['detail']['temoin']
    lignes.append('[%s] 3 convergence : premier passage (censuré) Koach %s, témoin %s ; atteints %s / %s ; jamais %s / %s'
                  % (ok('3_convergence_sous_3'), f(k['moyenne_censuree']), f(t['moyenne_censuree']),
                     f(k['moyenne_atteints']), f(t['moyenne_atteints']), f(k['part_jamais'], True),
                     f(t['part_jamais'], True)))
    d = c['4_couverture_90']
    lignes.append('[%s] 4 couverture 90 %% (rangs >= 3) : %s (n=%d) ; par rang %s ; seuil 88–92 %%'
                  % (ok('4_couverture_90'), f(d['mesure'], True), d['n'],
                     ', '.join('%s:%s' % (r, f((x or {}).get('couverture'), True))
                               for r, x in sorted(d['detail']['par_rang'].items(), key=lambda y: int(y[0])))))
    d = c['5_calibration_p_reussite']
    if d['detail']:
        pd = d['detail']['par_date']
        lignes.append('[%s] 5 calibration P(réussite) : écart max %s ; unités %d ; ' % (
            ok('5_calibration_p_reussite'), f(d['mesure'], True), d['n'])
            + ', '.join('%s n=%d p=%s obs=%s' % (k, x['n'], f(x['p_moyenne'], True), f(x['reussite_observee'], True))
                        for k, x in pd.items()))
        lignes.append('      exclusions : %s' % d['detail']['exclusions'])
    else:
        lignes.append('[%s] 5 calibration : %s' % (ok('5_calibration_p_reussite'), d['methode']))
    d = c['6_performance_jour_j']
    L = d['detail']['par_mode']['loaded']
    lignes.append('[%s] 6 jour J (chargé, best/max) : Koach %s, témoin %s (%d saisons appariées, écart %s ± %s) ; sans test %s'
                  % (ok('6_performance_jour_j'), f(d['mesure']), f(d['seuil']), L['saisons_appariees'],
                     f(L['ecart_apparie_moyen']), f(L['ecart_apparie_se']), L['saisons_sans_test']))
    d = c['7_securite']
    b = d['detail']['b_validateur']['vues']
    lignes.append('[%s] 7 sécurité : douleur %s, hausses %d, validateur %s ; témoin apparié %s'
                  % (ok('7_securite'), d['detail']['a_douleur'], d['detail']['c_hausses_trop_fortes'],
                     {v: {'introduit': x['introduit'], 'aggrave': x['aggrave'], 'deja_initial': x['deja_initial']}
                      for v, x in b.items()},
                     {k: d['detail']['temoin_apparie'][k] for k in ('aggravations', 'poussees', 'violations')}))
    d = c['8_temps_calcul']
    lignes.append('[%s] 8 temps : série max %s ms, replanification max %s s (%s)'
                  % (ok('8_temps_calcul'), f(d['mesure']['observe_serie_ms_max']),
                     f(d['mesure']['replanification_s_max']), d['detail']['source']))
    d = c['9_rappels']
    lignes.append('      9 rappels : %s' % d['respecte'])
    sc = s['secondaires']
    lignes.append('secondaires : MAE6 reps %s/%s, tenues %s/%s, écart effort %s/%s, échecs %s/%s, gain %s/%s, alertes/100 séances %s'
                  % (f((sc['mae_rang_6']['reps']['koach'] or {}).get('mae'), True),
                     f((sc['mae_rang_6']['reps']['temoin'] or {}).get('mae'), True),
                     f((sc['mae_rang_6']['hold']['koach'] or {}).get('mae'), True),
                     f((sc['mae_rang_6']['hold']['temoin'] or {}).get('mae'), True),
                     f(sc['ecart_effort']['koach']), f(sc['ecart_effort']['temoin']),
                     f(sc['echecs']['koach'], True), f(sc['echecs']['temoin'], True),
                     f(sc['gain_moyen_hebdo']['koach']), f(sc['gain_moyen_hebdo']['temoin']),
                     f(sc['alertes_rupture_par_100_seances']['koach'])))
    lignes.append('bilan : respectés %s ; NON respectés %s' % (s['bilan']['respectes'], s['bilan']['non_respectes']))
    return '\n'.join(lignes)


def options_de(argv=None):
    ap = argparse.ArgumentParser(description='Campagne de mesure des critères du cahier KM (Koach 1.0 contre 0.3.1).')
    ap.add_argument('--profils', default='tous', help='tous | fichier (liste séparée par des virgules) | liste')
    ap.add_argument('--scenarios', default='tous')
    ap.add_argument('--verites', default='abc')
    ap.add_argument('--graines', type=int, default=1)
    ap.add_argument('--trajectoires', type=int, default=None, help='trajectoires du jumeau (1000 ; 100 en --rapide)')
    ap.add_argument('--coeurs', type=int, default=2)
    ap.add_argument('--sortie', default=SORTIE)
    ap.add_argument('--sans-planificateur', action='store_true',
                    help='moteur seul, sans aucune extension (comme essai2.py sans PLAN)')
    ap.add_argument('--defaut-modele', type=float, default=None,
                    help="surcharge params['mesure']['defaut_modele_sd']")
    ap.add_argument('--caler-couverture', action='store_true',
                    help='cherche la plus petite valeur de defaut_modele_sd donnant une couverture >= 0,90')
    ap.add_argument('--rapide', action='store_true')
    ap.add_argument('--temps-existants', action='store_true',
                    help='critère 8 lu dans donnees/criteres_moteur.json au lieu d\'être remesuré')
    ap.add_argument('--semaines', type=int, default=None, help='tronque les saisons (essais)')
    ap.add_argument('--travail', default=DOSSIER_TRAVAIL)
    a = ap.parse_args(argv)
    traj = a.trajectoires if a.trajectoires is not None else (100 if a.rapide else 1000)
    return {'profils': a.profils, 'scenarios': a.scenarios, 'verites': a.verites, 'graines': a.graines,
            'trajectoires': traj, 'coeurs': a.coeurs, 'sortie': a.sortie,
            'sans_planificateur': a.sans_planificateur, 'defaut_modele': a.defaut_modele,
            'caler_couverture': a.caler_couverture, 'rapide': a.rapide, 'temps_existants': a.temps_existants,
            'semaines': a.semaines, 'travail': a.travail}


def main(argv=None):
    opts = options_de(argv)
    if opts['semaines'] is not None:
        # La troncature change le résultat : elle entre dans la configuration.
        opts['travail'] = os.path.join(opts['travail'], 'semaines%d' % opts['semaines'])
    if opts['caler_couverture']:
        x, essais = caler_couverture(opts)
        print('defaut_modele_sd calé : %s (couverture >= 0,90 ; fichier de paramètres non modifié)'
              % ('introuvable (> 0,64)' if x is None else '%.5f' % x))
        for k in sorted(essais):
            print('  %.5f -> %.4f' % (k, essais[k]))
        return 0
    t0 = time.time()
    s, info = campagne(opts)
    d = os.path.dirname(os.path.abspath(opts['sortie']))
    if d and not os.path.isdir(d):
        os.makedirs(d)
    with open(opts['sortie'], 'w', encoding='utf-8') as f:
        json.dump(s, f, ensure_ascii=False, indent=1, sort_keys=True)
        f.write('\n')
    print(resume(s))
    if info['duree_moyenne_s'] is not None:
        print('durée : %.0f s ; %.2f s/saison (calcul, un cœur) ; %d calculée(s), cache %s'
              % (time.time() - t0, info['duree_moyenne_s'], info['calculees'], info['dossier']))
    return 0


if __name__ == '__main__':
    sys.exit(main())
