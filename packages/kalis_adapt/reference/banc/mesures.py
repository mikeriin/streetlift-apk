# -*- coding: utf-8 -*-
"""Mesures du banc Python, alignées sur celles que le banc Dart exporte pour
le témoin (`kmRunSummary`, `KmEstimateStats`, `CoachMetrics`)."""
import math

K_MAX = 24


class Estimations(object):
    """Erreurs d'estimation par rang de séance de l'exercice (comme
    `KmEstimateStats`), plus la couverture de l'intervalle à 90 % de Koach."""

    def __init__(self):
        self.rows = [[0.0] * 7 for _ in range(K_MAX + 1)]
        self.first_under = []

    def add(self, tour, keep):
        seen = {}
        ids = set()
        # Rang de séance = rang du jour d'entraînement de l'exercice (un test
        # et le travail du même jour comptent pour une séance ; dernière
        # estimation du jour).
        par_jour = {}
        ordre = []
        for e in tour.estimates:
            if not keep(e) or e['truth'] <= 0:
                continue
            cle = (e['exerciseId'], e['simDay'])
            if cle not in par_jour:
                ordre.append(cle)
            par_jour[cle] = e
        rang = {}
        for cle in ordre:
            e = par_jour[cle]
            rang[e['exerciseId']] = rang.get(e['exerciseId'], 0) + 1
            ids.add(e['exerciseId'])
            k = rang[e['exerciseId']]
            err = e['capacity'] / e['truth'] - 1
            a = abs(err)
            if a < 0.03:
                seen.setdefault(e['exerciseId'], k)
            if k < 1 or k > K_MAX:
                continue
            r = self.rows[k]
            r[0] += 1
            r[1] += a
            r[2] += err
            r[3] += err * err
            if a < 0.03:
                r[4] += 1
            if e.get('low') is not None:
                if e['low'] <= e['truth'] <= e['high']:
                    r[5] += 1
            elif a <= 1.6449 * e['relSd']:
                r[5] += 1
            r[6] += e['relSd']
        for i in ids:
            self.first_under.append(seen.get(i, 0))

    def ajouter_temoin(self, j):
        for k in range(K_MAX + 1):
            for c in range(6):
                self.rows[k][c] += j['bySession'][k][c]
        self.first_under += j['firstUnder3']

    def ligne(self, k):
        n, sa, ss, sq, u3, cov, sd = self.rows[k]
        if n == 0:
            return None
        return {'n': int(n), 'mae': sa / n, 'biais': ss / n, 'rmse': math.sqrt(sq / n),
                'sous3': u3 / n, 'couverture': cov / n, 'sd': sd / n}

    def apres(self, k0):
        """Agrégat des rangs >= k0."""
        tot = [0.0] * 7
        for k in range(k0, K_MAX + 1):
            for c in range(7):
                tot[c] += self.rows[k][c]
        n = tot[0]
        if n == 0:
            return None
        return {'n': int(n), 'mae': tot[1] / n, 'biais': tot[2] / n, 'sous3': tot[4] / n,
                'couverture': tot[5] / n}

    def premier_rang_sous(self, seuil=0.03):
        """Premier rang où l'erreur absolue moyenne passe sous le seuil."""
        for k in range(1, K_MAX + 1):
            n = self.rows[k][0]
            if n > 0 and self.rows[k][1] / n < seuil:
                return k
        return None


def evenements(tour):
    """Jour de l'échéance : (exercice, mode, meilleure valeur, max du jour,
    capacité de départ) par exercice testé (règles de
    `CoachMetrics.eventPerformance`)."""
    best = {}
    best_ext = {}
    day_max = {}
    modes = {}
    for s in tour.sets:
        if not (s['eventDay'] and s['test']):
            continue
        mx = s['dayMax']
        if mx is None or mx <= 0:
            continue
        ex = s['exerciseId']
        day_max[ex] = mx
        modes[ex] = s['mode']
        ok = not (s['failed'] or s['amount'] < 1)
        value = ((s['totalKg'] or 0.0) if ok else 0.0) if s['mode'] == 'loaded' else float(s['amount'])
        if value > best.get(ex, 0):
            best[ex] = value
            if s['mode'] == 'loaded':
                best_ext[ex] = s['loadKg'] or 0.0
        best.setdefault(ex, 0.0)
    return [(ex, modes[ex], best[ex], best_ext.get(ex), day_max[ex], tour.cap0.get(ex)) for ex in best]


def effort(tour):
    """Écart d'effort, échecs non voulus (comme `CoachMetrics`)."""
    gap_sum = 0.0
    n = 0
    work = 0
    failed = 0
    tries = 0
    good = 0
    hausses = 0
    for s in tour.sets:
        if s['attempt']:
            tries += 1
            if not s['failed'] and s['amount'] >= 1:
                good += 1
        if s['test'] or s['role'] == 'warmup':
            continue
        rise = s['schemeRise']
        if rise is not None and s['main'] and rise > 0.10 + 1e-9 and s['schemeSteps'] > 1:
            hausses += 1
        if s['exerciseSession'] < 3:
            continue
        work += 1
        if s['failed'] and not s['plannedFailure']:
            failed += 1
        if s['plannedFailure'] or not s['reachable']:
            continue
        diff = s['trueRir'] - s['wantRir']
        gap = (-diff if diff < 0 else 0.0) if s['openTarget'] else abs(diff)
        gap_sum += gap
        n += 1
    return {'ecart_effort': gap_sum / n if n else None, 'echecs': failed / work if work else None,
            'tentatives': good / tries if tries else None, 'hausses_trop_fortes': hausses, 'series': work}


def gain_moyen(tour):
    if not tour.gain:
        return None
    return sum(tour.gain.values()) / len(tour.gain)
