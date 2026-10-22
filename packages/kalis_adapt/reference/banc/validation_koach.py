# -*- coding: utf-8 -*-
"""Calibrage et mesures des briques 6 et 7 de Koach 1.0 sur le banc Python
(hors modèle, diagnostic, contrôle dual, adhérence).

    python3 -m banc.validation_koach [--graines N] [--modeles abc] [--coeurs 2]

écrit `donnees/validation_briques_6_7.json`. Chaque mesure est aussi une
fonction appelable (tests, notes). Les saisons qui plantent dans le moteur
sont notées (`plantages`) et la mesure continue.

Définitions :
* séance = séance faite (les séances manquées ne versent pas de résidu) ;
* rupture connue = jour de début de la maladie, de la douleur imposée, de la
  coupure (`seances_manquees`) lu dans `specJson` ; indice de rupture = 1re
  séance faite à partir de ce jour ;
* fausse alerte BOCPD = passage de P(rupture) au-dessus du seuil sur une
  saison `reference` (BOCPD passive, jamais réinitialisée), rapportée à 100
  séances ;
* détection = premier passage au-dessus du seuil à partir de l'indice de
  rupture et au plus `FENETRE_DETECTION_J` jours après le début ; délai en
  séances (1 = première séance après le début) et en jours.
"""
import json
import math
import os
import sys
import time
import traceback
from multiprocessing import Pool

from koach.moteur import Extension
from koach.rupture import Surveillance, Bocpd, calibrer_alerte

from . import donnees, meneur
from . import extensions_koach as ek
from .politique_koach import PolitiqueKoach, params

ICI = os.path.dirname(os.path.abspath(__file__))
SORTIE = os.path.join(ICI, '..', 'donnees', 'validation_briques_6_7.json')
SEUILS = [0.4, 0.5, 0.6, 0.7, 0.8]
FENETRE_DETECTION_J = 28
RESIDU_PROPOSE = 0.20
SCENARIOS_RUPTURE = ('maladie', 'seances_manquees', 'douleur_coude', 'douleur_epaule')
_infos = None


def infos():
    global _infos
    if _infos is None:
        _infos = donnees.catalogue_infos()
    return _infos


def saison(cle, scenario):
    for s in donnees.saisons_reference(cle):
        if s['scenario'] == scenario:
            return s
    return None


def params_seuil(seuil, residu_secours=None):
    p = json.loads(json.dumps(params()))
    p.setdefault('rupture', {})['alerte'] = float(seuil)
    if residu_secours is not None:
        p['rupture']['residu_secours'] = float(residu_secours)
    return p


def balayer_residu(collectes, seuils=(0.05, 0.10, 0.15, 0.20, 0.25)):
    """Seuil de secours du résidu d'e1RM (|moyenne hebdomadaire| > seuil
    deux semaines de suite) : part des semaines actives, alertes (montées)
    par saison, détection au plus 5 semaines après la rupture, par
    scénario (collecte passive)."""
    out = []
    for seuil in seuils:
        ligne = {'seuil': seuil}
        for c in collectes:
            o = ligne.setdefault(c['scenario'], {'semaines': 0, 'actives': 0, 'montees': 0, 'saisons': 0,
                                                 'detectees': 0})
            o['saisons'] += 1
            run = 0
            prec = False
            det = False
            for w in c['semaines']:
                r = w['residu']
                run = run + 1 if (r is not None and r > seuil) else 0
                actif = run >= 2
                o['semaines'] += 1
                o['actives'] += 1 if actif else 0
                if actif and not prec:
                    o['montees'] += 1
                prec = actif
                d = c['debut_rupture']
                if actif and d is not None and not det and d <= 7 * (w['semaine'] + 1) <= d + 35:
                    o['detectees'] += 1
                    det = True
        for sc in list(ligne.keys()):
            if sc == 'seuil':
                continue
            o = ligne[sc]
            ligne[sc] = {'part_semaines': o['actives'] / o['semaines'] if o['semaines'] else None,
                         'alertes_par_saison': o['montees'] / o['saisons'],
                         'taux_detection': o['detectees'] / o['saisons']}
        out.append(ligne)
    return out


# ----------------------------------------------------------------------
# 1. Collecte passive (BOCPD et seuils de secours sans action)
# ----------------------------------------------------------------------
class SondeHorsModele(Extension):
    """Surveillance PASSIVE : personne ne répond au diagnostic (les causes
    restent levées, aucune action, BOCPD jamais réinitialisée). Note par
    séance (jour, résidu normalisé moyen, P(rupture)) et par semaine
    l'activité de chaque seuil de secours."""

    def __init__(self, params_):
        self.s = Surveillance(params_)
        self.seances = []
        self.semaines = []

    def fin_seance(self, koach, resume, e):
        self.s.fin_seance(koach, resume, e)
        if resume is not None:
            self.seances.append([int(resume[0]), float(resume[1]), float(self.s.p)])

    def seance_manquee(self, koach, e):
        self.s.seance_manquee(koach, e)

    def fin_semaine(self, koach, ligne, e):
        signe = self.s.somme_rel / self.s.n_rel if self.s.n_rel > 0 else None
        self.s.fin_semaine(koach, ligne, e)
        dern = self.s.semaines[-1]
        faites, prevues = dern[2], dern[3]
        self.semaines.append({'semaine': dern[0], 'residu': dern[1], 'residu_signe': signe,
                              'faites': faites, 'prevues': prevues,
                              'residu_actif': self.s._residu_actif(),
                              'assiduite_active': self.s._assiduite_active(),
                              'douleur_active': len(self.s._douleur(koach)) > 0})


def collecter(cle, scenario, kind, graine):
    s = saison(cle, scenario)
    p = params()
    pol = PolitiqueKoach(extensions=[lambda pol: SondeHorsModele(pol.parametres)])
    meneur.simuler(s, infos(), pol, kind, graine)
    sonde = pol.koach.extensions[0]
    v = ek.VeriteScenario(s)
    return {'cle': cle, 'scenario': scenario, 'kind': kind, 'graine': graine,
            'debut_rupture': v.debut_rupture(), 'seances': sonde.seances, 'semaines': sonde.semaines,
            'semaines_saison': s['weeks']}


def _indice_rupture(seances, debut):
    for i in range(len(seances)):
        if seances[i][0] >= debut:
            return i
    return None


def _traces_p(seances, prm):
    b = Bocpd.depuis_params(prm)
    return [b.ajouter(x[1]) for x in seances]


def mesurer_bocpd(collectes, seuils=SEUILS, prm=None):
    """Table par seuil : fausses alertes / 100 séances (reference), et par
    scénario de rupture : taux de détection dans la fenêtre, délai médian
    (séances, jours), fausses alertes avant la rupture / 100 séances."""
    prm = prm or params()
    traces = []
    for c in collectes:
        traces.append((c, _traces_p(c['seances'], prm)))
    sortie = []
    for seuil in seuils:
        ligne = {'seuil': seuil}
        alertes = 0
        n = 0
        for c, tr in traces:
            if c['scenario'] != 'reference':
                continue
            n += len(tr)
            avant = False
            for p in tr:
                haut = p > seuil
                if haut and not avant:
                    alertes += 1
                avant = haut
        hautes = sum(1 for c, tr in traces if c['scenario'] == 'reference' for p in tr if p > seuil)
        ligne['reference'] = {'seances': n, 'fausses_alertes_100': 100.0 * alertes / n if n else None,
                              'part_seances_au_dessus': hautes / n if n else None}
        for scen in SCENARIOS_RUPTURE:
            det = 0
            tot = 0
            d_s = []
            d_j = []
            pre_alertes = 0
            pre_n = 0
            for c, tr in traces:
                if c['scenario'] != scen or c['debut_rupture'] is None:
                    continue
                k = _indice_rupture(c['seances'], c['debut_rupture'])
                if k is None:
                    continue
                tot += 1
                avant = False
                for t in range(k):
                    haut = tr[t] > seuil
                    if haut and not avant:
                        pre_alertes += 1
                    avant = haut
                pre_n += k
                for t in range(k, len(tr)):
                    if c['seances'][t][0] - c['debut_rupture'] > FENETRE_DETECTION_J:
                        break
                    if tr[t] > seuil:
                        det += 1
                        d_s.append(t - k + 1)
                        d_j.append(c['seances'][t][0] - c['debut_rupture'])
                        break
            ligne[scen] = {'saisons': tot, 'taux_detection': det / tot if tot else None,
                           'delai_median_seances': _mediane(d_s), 'delai_median_jours': _mediane(d_j),
                           'fausses_alertes_avant_100': 100.0 * pre_alertes / pre_n if pre_n else None}
        sortie.append(ligne)
    return sortie


def calibrer_alerte_banc(collectes, seuils=SEUILS, prm=None):
    """Même calcul par `rupture.calibrer_alerte` (délai sans fenêtre, toute
    la fin de saison comptée) : contrôle croisé."""
    stables = [[x[1] for x in c['seances']] for c in collectes if c['scenario'] == 'reference']
    ruptures = []
    for c in collectes:
        if c['scenario'] in SCENARIOS_RUPTURE and c['debut_rupture'] is not None:
            k = _indice_rupture(c['seances'], c['debut_rupture'])
            if k is not None:
                ruptures.append(([x[1] for x in c['seances']], k))
    return calibrer_alerte(stables, ruptures, seuils, params=prm or params())


def mesurer_secours(collectes):
    """Seuils de secours (résidu d'e1RM > 5 % deux semaines, assiduité <
    70 % sur 2 semaines, douleur > 2/10) : part des semaines où chaque cause
    est active, par scénario ; détection (cause active au plus 4 semaines
    après la rupture) ; distribution du résidu hebdomadaire d'e1RM sur la
    référence."""
    out = {}
    residus_ref = []
    for c in collectes:
        sc = c['scenario']
        o = out.setdefault(sc, {'semaines': 0, 'residu': 0, 'assiduite': 0, 'douleur': 0,
                                'saisons': 0, 'detectees': {'residu': 0, 'assiduite': 0, 'douleur': 0}})
        o['saisons'] += 1
        for w in c['semaines']:
            o['semaines'] += 1
            o['residu'] += 1 if w['residu_actif'] else 0
            o['assiduite'] += 1 if w['assiduite_active'] else 0
            o['douleur'] += 1 if w['douleur_active'] else 0
            if sc == 'reference' and w['residu'] is not None:
                residus_ref.append(w['residu'])
        d = c['debut_rupture']
        if d is not None:
            for cause in ('residu', 'assiduite', 'douleur'):
                for w in c['semaines']:
                    fin_semaine_j = 7 * (w['semaine'] + 1)
                    if d <= fin_semaine_j <= d + FENETRE_DETECTION_J + 7 and w[cause + '_actif' if cause == 'residu' else cause + '_active']:
                        o['detectees'][cause] += 1
                        break
    for sc in out:
        o = out[sc]
        n = o['semaines']
        o['part_semaines'] = {k: (o[k] / n if n else None) for k in ('residu', 'assiduite', 'douleur')}
        o['taux_detection'] = {k: (o['detectees'][k] / o['saisons']) for k in o['detectees']}
    # Variante (hors cahier) : écart du résidu hebdomadaire signé à sa
    # moyenne sur les 4 semaines précédentes (ligne de base de
    # l'utilisateur), > 5 % deux semaines de suite.
    for c in collectes:
        o = out[c['scenario']]
        v = o.setdefault('variante_ligne_de_base', {'semaines': 0, 'actives': 0, 'detectees': 0})
        hist = []
        prec = False
        det = False
        for w in c['semaines']:
            r = w.get('residu_signe')
            actif = False
            if r is not None and len(hist) >= 2:
                base = sum(hist[-4:]) / len(hist[-4:])
                haut = abs(r - base) > 0.05
                actif = haut and prec
                prec = haut
            elif r is None:
                prec = False
            if r is not None:
                hist.append(r)
            v['semaines'] += 1
            v['actives'] += 1 if actif else 0
            d = c['debut_rupture']
            if actif and d is not None and not det and d <= 7 * (w['semaine'] + 1) <= d + FENETRE_DETECTION_J + 7:
                v['detectees'] += 1
                det = True
    for sc in out:
        v = out[sc].get('variante_ligne_de_base')
        if v:
            v['part_semaines'] = v['actives'] / v['semaines'] if v['semaines'] else None
            v['taux_detection'] = v['detectees'] / out[sc]['saisons']
    residus_ref.sort()
    q = {}
    for niveau in (0.5, 0.75, 0.9, 0.95):
        if residus_ref:
            q['q%d' % int(100 * niveau)] = residus_ref[int(niveau * (len(residus_ref) - 1))]
    out['_residu_reference_quantiles'] = q
    out['_residu_reference_part_sup_5pc'] = (sum(1 for r in residus_ref if r > 0.05) / len(residus_ref)
                                            if residus_ref else None)
    return out


# ----------------------------------------------------------------------
# 2. Banc complet (diagnostic, actions, contrôle dual, adhérence)
# ----------------------------------------------------------------------
def conduire(cle, scenario, kind, graine, seuil=None, briques=('surveillance', 'dual', 'adherence'),
             options_dual=None, raisons=False, residu_secours=None):
    """Une saison conduite par Koach + briques ; renvoie les journaux des
    extensions, l'état final du contrôle dual et les séries servies."""
    s = saison(cle, scenario)
    prm = params_seuil(seuil, residu_secours) if seuil is not None else None
    pol = ek.politique(graine, briques=briques, parametres=prm, options_dual=options_dual,
                       raisons=raisons)
    tour = meneur.simuler(s, infos(), pol, kind, graine)
    out = {'cle': cle, 'scenario': scenario, 'kind': kind, 'graine': graine,
           'journaux': ek.journaux(pol), 'seances': tour.sessions_done, 'semaines_saison': s['weeks']}
    for x in pol.koach.extensions:
        if isinstance(x, ek.ControleDual):
            out['dual'] = {'essais_passes': x.essais_passes,
                           'essai_en_cours': None if x.essai is None else x.essai.etat(),
                           'lifts': x.lifts}
    return out


def fenetre_attendue(s):
    """(début, fin exclue, action attendue) de la rupture du scénario."""
    v = ek.VeriteScenario(s)
    if v.maladie is not None:
        return v.maladie[0], v.maladie[1] + v.APRES_MALADIE_J, 'semaine_allegee'
    if v.douleur is not None:
        return v.douleur[0], v.douleur[1] + 7, 'conduite_douleur'
    if v.lieu is not None:
        return v.lieu[0], v.lieu[1], 'replanifier'
    return None


def mesurer_diagnostic(runs):
    """Part des alertes dont la réponse simulée mène à l'action attendue,
    par scénario : alertes répondues dans la fenêtre de la rupture (action
    attendue = celle du scénario) et hors fenêtre (action attendue :
    `elargir`, « rien de spécial », sauf douleur réelle) ; nombre de
    questions ; effet de la semaine allégée sur les séries."""
    par = {}
    for r in runs:
        s = saison(r['cle'], r['scenario'])
        f = fenetre_attendue(s)
        o = par.setdefault(r['scenario'], {'alertes': 0, 'dans_fenetre': 0, 'dans_fenetre_ok': 0,
                                           'hors_fenetre': 0, 'actions': {}, 'questions_max': 0,
                                           'questions': {}, 'causes': {}, 'seances': 0,
                                           'allegement_jours': 0, 'series_ecrites': 0,
                                           'series_allegees': 0, 'saisons': 0,
                                           'saisons_avec_action_attendue': 0})
        o['saisons'] += 1
        o['seances'] += r['seances']
        vu_attendue = False
        for e in r['journaux'].get('SurveillanceBanc') or []:
            if e['type'] == 'alerte':
                o['alertes'] += 1
                for c in e['causes']:
                    o['causes'][c] = o['causes'].get(c, 0) + 1
            elif e['type'] == 'diagnostic':
                o['actions'][e['action']] = o['actions'].get(e['action'], 0) + 1
                o['questions_max'] = max(o['questions_max'], e['questions'])
                o['questions'][str(e['questions'])] = o['questions'].get(str(e['questions']), 0) + 1
                if f is not None and f[0] <= e['jour'] < f[1]:
                    o['dans_fenetre'] += 1
                    if e['action'] == f[2]:
                        o['dans_fenetre_ok'] += 1
                        vu_attendue = True
                else:
                    o['hors_fenetre'] += 1
            elif e['type'] == 'allegement':
                o['allegement_jours'] += 1
                o['series_ecrites'] += e['series_ecrites']
                o['series_allegees'] += e['series_allegees']
        if vu_attendue:
            o['saisons_avec_action_attendue'] += 1
    for sc, o in par.items():
        o['alertes_100_seances'] = 100.0 * o['alertes'] / o['seances'] if o['seances'] else None
        o['part_action_attendue_dans_fenetre'] = (o['dans_fenetre_ok'] / o['dans_fenetre']
                                                  if o['dans_fenetre'] else None)
        o['ratio_series_allegees'] = (o['series_allegees'] / o['series_ecrites']
                                      if o['series_ecrites'] else None)
    return par


def mesurer_dual(runs):
    """Calibrage (semaines de journal, demi-largeur à 90 % des lifts
    principaux), essais lancés / interrompus / conclus / en cours en fin de
    saison, amplitudes servies contre les plafonds."""
    pl = params()['planification']
    o = {'saisons': 0, 'saisons_calibrees': 0, 'premiere_semaine_calibree': [],
         'semaines_calibrees': 0, 'semaines': 0, 'demi_largeur_max_fin': [],
         'propositions': 0, 'refus': {}, 'lances': 0, 'interrompus': 0, 'conclus': 0, 'en_cours_fin': 0,
         'raisons_interruption': {}, 'decisions': {}, 'ratio_volume_semaine_max': None,
         'ratio_intensite_max': None, 'plafond_volume': pl['plafond_volume'],
         'plafond_intensite': pl['plafond_intensite'], 'series_servies_bras': 0,
         'entropie_fin': [], 'poids_max_fin': [], 'sans_lift_principal': 0}
    for r in runs:
        j = r['journaux'].get('ControleDualBanc') or []
        o['saisons'] += 1
        sem = [e for e in j if e['type'] == 'semaine']
        if not r.get('dual', {}).get('lifts'):
            o['sans_lift_principal'] += 1
        cal = [e['semaine'] for e in sem if e['calibre']]
        o['semaines'] += len(sem)
        o['semaines_calibrees'] += len(cal)
        if cal:
            o['saisons_calibrees'] += 1
            o['premiere_semaine_calibree'].append(cal[0])
        if sem and sem[-1]['demi_largeur']:
            o['demi_largeur_max_fin'].append(max(sem[-1]['demi_largeur'].values()))
        if sem:
            o['entropie_fin'].append(sem[-1]['entropie'])
            o['poids_max_fin'].append(sem[-1]['poids_max'])
        for e in j:
            if e['type'] == 'proposition':
                o['propositions'] += 1
                if e['demarre']:
                    o['lances'] += 1
                else:
                    raison = (e['raison'] or '').split(':')[-1] or 'inconnue'
                    for rr in raison.split(','):
                        cle = rr.split(':')[0]
                        o['refus'][cle] = o['refus'].get(cle, 0) + 1
            elif e['type'] == 'volume':
                v = e['ratio_semaine']
                o['series_servies_bras'] += 1
                if o['ratio_volume_semaine_max'] is None or v > o['ratio_volume_semaine_max']:
                    o['ratio_volume_semaine_max'] = v
            elif e['type'] == 'intensite':
                v = e['ratio']
                if o['ratio_intensite_max'] is None or v > o['ratio_intensite_max']:
                    o['ratio_intensite_max'] = v
        d = r.get('dual') or {}
        for x in d.get('essais_passes') or []:
            st = x['essai']['statut']
            if st == 'interrompu':
                o['interrompus'] += 1
                rf = x['essai']['raison_fin']
                o['raisons_interruption'][rf] = o['raisons_interruption'].get(rf, 0) + 1
            elif st == 'termine':
                o['conclus'] += 1
                dec = x['analyse']['decision']
                o['decisions'][dec] = o['decisions'].get(dec, 0) + 1
        if d.get('essai_en_cours') is not None:
            o['en_cours_fin'] += 1
    o['premiere_semaine_calibree_mediane'] = _mediane(o['premiere_semaine_calibree'])
    o['demi_largeur_max_fin_mediane'] = _mediane(o['demi_largeur_max_fin'])
    o['entropie_fin_moyenne'] = _moyenne(o['entropie_fin'])
    o['entropie_max'] = math.log(9)
    o['poids_max_fin_moyen'] = _moyenne(o['poids_max_fin'])
    for k in ('premiere_semaine_calibree', 'demi_largeur_max_fin', 'entropie_fin', 'poids_max_fin'):
        del o[k]
    o['dans_plafonds'] = ((o['ratio_volume_semaine_max'] is None
                           or o['ratio_volume_semaine_max'] <= 1 + o['plafond_volume'] + 1e-9)
                          and (o['ratio_intensite_max'] is None
                               or o['ratio_intensite_max'] <= 1 + o['plafond_intensite'] + 1e-9))
    return o


def mesurer_adherence(runs):
    """Apprentissage de l'adhérence en conditions de banc : calibration
    (prédit / observé par tranche de 20 %), écart moyen |p prédite − p
    vraie| par quart de saison, formes (le dernier palier vaut toujours la
    cible), moments choisis."""
    tranches = [[0, 0.0, 0] for _ in range(5)]
    quarts = [[0.0, 0] for _ in range(4)]
    n = 0
    acc = 0
    cibles_ok = True
    n_paliers = {}
    moments = {}
    for r in runs:
        j = r['journaux'].get('AdherenceBanc') or []
        L = len(j)
        for i, e in enumerate(j):
            n += 1
            acc += 1 if e['accepte'] else 0
            k = min(4, int(e['p_predite'] * 5))
            tranches[k][0] += 1
            tranches[k][1] += e['p_predite']
            tranches[k][2] += 1 if e['accepte'] else 0
            q = min(3, int(4 * i / max(1, L)))
            quarts[q][0] += abs(e['p_predite'] - e['p_vraie'])
            quarts[q][1] += 1
            if e['cible'] is not None and e['paliers'][-1] != e['cible']:
                cibles_ok = False
            n_paliers[str(len(e['paliers']))] = n_paliers.get(str(len(e['paliers'])), 0) + 1
            moments[e['moment']] = moments.get(e['moment'], 0) + 1
    return {'decisions': n, 'part_acceptees': acc / n if n else None,
            'calibration': [{'tranche': [0.2 * k, 0.2 * (k + 1)], 'n': t[0],
                             'predit': t[1] / t[0] if t[0] else None,
                             'observe': t[2] / t[0] if t[0] else None} for k, t in enumerate(tranches)],
            'ecart_p_vraie_par_quart': [q[0] / q[1] if q[1] else None for q in quarts],
            'dernier_palier_egal_cible': cibles_ok, 'paliers': n_paliers, 'moments': moments}


def anti_complaisance(cle, scenario, kind, graine):
    """Saison conduite par Koach seul, puis par Koach + adhérence (refus
    sans raison) : items servis et séries réalisées identiques (json)."""
    s = saison(cle, scenario)
    t1 = meneur.simuler(s, infos(), PolitiqueKoach(), kind, graine)
    pol = ek.politique(graine, briques=('adherence',))
    t2 = meneur.simuler(s, infos(), pol, kind, graine)
    a = json.dumps(t1.servi, sort_keys=True)
    b = json.dumps(t2.servi, sort_keys=True)
    sa = json.dumps([(x['exerciseId'], x['loadKg'], x['amount'], x['targetLow'], x['targetHigh'])
                     for x in t1.sets])
    sb = json.dumps([(x['exerciseId'], x['loadKg'], x['amount'], x['targetLow'], x['targetHigh'])
                     for x in t2.sets])
    j = ek.journaux(pol)['AdherenceBanc']
    return {'servis_identiques': a == b, 'series_identiques': sa == sb, 'decisions': len(j),
            'refus': sum(1 for e in j if not e['accepte'])}


# ----------------------------------------------------------------------
# Outils
# ----------------------------------------------------------------------
def _mediane(xs):
    ys = sorted(x for x in xs if x is not None)
    if not ys:
        return None
    n = len(ys)
    return ys[n // 2] if n % 2 else 0.5 * (ys[n // 2 - 1] + ys[n // 2])


def _moyenne(xs):
    return sum(xs) / len(xs) if xs else None


def _appel(args):
    f, a, kw = args
    try:
        return ('ok', f(*a, **kw))
    except Exception:
        return ('plantage', {'appel': f.__name__, 'args': list(a), 'trace': traceback.format_exc()[-800:]})


def paralleles(f, jobs, coeurs=2, kw=None):
    """Applique f(*args) à chaque job sur [coeurs] processus ; renvoie
    (résultats, plantages) dans l'ordre des jobs."""
    lots = [(f, tuple(a), kw or {}) for a in jobs]
    if coeurs <= 1:
        res = [_appel(x) for x in lots]
    else:
        with Pool(coeurs) as p:
            res = p.map(_appel, lots, chunksize=2)
    ok = [r[1] for r in res if r[0] == 'ok']
    ko = [r[1] for r in res if r[0] == 'plantage']
    return ok, ko


def jobs(scenarios, kinds='abc', graines=1, cles=None):
    out = []
    for cle in cles or donnees.profils():
        for s in donnees.saisons_reference(cle):
            if s['scenario'] not in scenarios:
                continue
            for k in kinds:
                for g in range(graines):
                    out.append((cle, s['scenario'], k, g))
    return out


def principal(graines=2, kinds='abc', coeurs=2, seuil_retenu=None):
    t0 = time.time()
    rapport = {'graines': graines, 'modeles': kinds, 'plantages': []}
    # 1. Collecte passive.
    scen = ('reference',) + SCENARIOS_RUPTURE + ('parc_seulement',)
    coll, ko = paralleles(collecter, jobs(scen, kinds, graines), coeurs)
    rapport['plantages'] += ko
    rapport['bocpd'] = mesurer_bocpd(coll)
    rapport['bocpd_calibrer_alerte'] = calibrer_alerte_banc(coll)
    rapport['secours'] = mesurer_secours(coll)
    rapport['secours_residu_balayage'] = balayer_residu(coll)
    rapport['collecte'] = {'saisons': len(coll), 'secondes': round(time.time() - t0, 1)}
    if seuil_retenu is None:
        seuil_retenu = choisir_seuil(rapport['bocpd'])
    rapport['seuil_retenu'] = seuil_retenu
    # 2. Banc complet au seuil retenu.
    t1 = time.time()
    scen2 = ('reference', 'maladie', 'seances_manquees', 'douleur_coude', 'douleur_epaule',
             'parc_seulement')
    runs, ko = paralleles(conduire, jobs(scen2, kinds, graines), coeurs, {'seuil': seuil_retenu})
    rapport['plantages'] += ko
    rapport['diagnostic'] = mesurer_diagnostic(runs)
    rapport['dual'] = mesurer_dual(runs)
    rapport['adherence'] = mesurer_adherence(runs)
    rapport['banc_complet'] = {'saisons': len(runs), 'secondes': round(time.time() - t1, 1)}
    # 2 bis. Même banc avec le seuil de secours du résidu proposé (0,20 au
    # lieu de 0,05 : voir `secours_residu_balayage`).
    t2 = time.time()
    runs_p, ko = paralleles(conduire, jobs(scen2, kinds, graines), coeurs,
                            {'seuil': seuil_retenu, 'residu_secours': RESIDU_PROPOSE})
    rapport['plantages'] += ko
    rapport['residu_propose'] = RESIDU_PROPOSE
    rapport['diagnostic_residu_propose'] = mesurer_diagnostic(runs_p)
    rapport['dual_residu_propose'] = mesurer_dual(runs_p)
    rapport['banc_complet_residu_propose'] = {'saisons': len(runs_p), 'secondes': round(time.time() - t2, 1)}
    # 3. Contrôle dual en configuration de diagnostic (hors cahier : 2 bras,
    # échéance ignorée) pour exercer la mécanique et les plafonds.
    runs_d, ko = paralleles(conduire, jobs(('reference',), kinds, graines), coeurs,
                            {'seuil': seuil_retenu, 'briques': ('surveillance', 'dual'),
                             'options_dual': {'n_bras': 2, 'ignorer_echeance': True},
                             'residu_secours': RESIDU_PROPOSE})
    rapport['plantages'] += ko
    rapport['dual_diagnostic_2_bras_sans_echeance'] = mesurer_dual(runs_d)
    # 4. Anti-complaisance.
    ac, ko = paralleles(anti_complaisance, jobs(('reference', 'maladie'), 'abc', 1,
                                                cles=donnees.profils()[::3]), coeurs)
    rapport['plantages'] += ko
    rapport['anti_complaisance'] = {
        'saisons': len(ac), 'servis_identiques': sum(1 for x in ac if x['servis_identiques']),
        'series_identiques': sum(1 for x in ac if x['series_identiques']),
        'decisions': sum(x['decisions'] for x in ac), 'refus': sum(x['refus'] for x in ac)}
    rapport['secondes'] = round(time.time() - t0, 1)
    return rapport


def choisir_seuil(table, fa_max=1.0):
    """Plus petit seuil (donc la meilleure détection) dont les fausses
    alertes sur la référence restent sous [fa_max] pour 100 séances
    (1 / 100 séances ≈ 0,7 fausse alerte par saison de 16 semaines)."""
    for ligne in table:
        fa = ligne['reference']['fausses_alertes_100']
        if fa is not None and fa <= fa_max:
            return ligne['seuil']
    return table[-1]['seuil']


if __name__ == '__main__':
    a = sys.argv[1:]

    def opt(nom, defaut):
        if nom in a:
            return a[a.index(nom) + 1]
        return defaut
    r = principal(graines=int(opt('--graines', 2)), kinds=opt('--modeles', 'abc'),
                  coeurs=int(opt('--coeurs', 2)),
                  seuil_retenu=None if opt('--seuil', None) is None else float(opt('--seuil', None)))
    with open(SORTIE, 'w', encoding='utf-8') as f:
        json.dump(r, f, ensure_ascii=False, indent=1, sort_keys=True)
    print(json.dumps({k: r[k] for k in ('seuil_retenu', 'secondes', 'collecte', 'banc_complet')},
                     ensure_ascii=False))
    print('plantages :', len(r['plantages']))
