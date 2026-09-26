# -*- coding: utf-8 -*-
"""Koach — implémentation de référence (Kalis Track 3.0.0, lot L7).

Moteur pur et déterministe : entrées = journal normalisé, programme annoté,
décisions de l'utilisateur, horloge ; sorties = estimations (1RM « système »
par mouvement, maxima d'endurance, biais de RIR), propositions et règles.
Aucune dépendance hors bibliothèque standard, aucun réseau.

Recoupée avec `lib/koach_engine.dart` sur les fixtures JSON partagées de
`test/fixtures/koach/` : mêmes sorties à 0,01 kg près (contrat L7 §9).

Usage :
    python3 tools/koach_reference.py CAS.json            # sorties d'un cas
    python3 tools/koach_reference.py --write-expected    # régénère « expected »
"""
import copy
import json
import math
import re
import sys
from datetime import datetime, timedelta
from pathlib import Path

# --------------------------------------------------------------------------
# Paramètres (docs/CONTRAT_L7.md §4). « simulation » : valeur ajoutée ou
# ajustée sur la base des simulations (contrat §8), les autres sont celles
# de la demande L7.
# --------------------------------------------------------------------------
PARAMS = {
    'q': 0.005,              # bruit de processus : 0,5 % de x par semaine (variance ∝ temps)
    'sigma_day': 0.05,       # simulation : effet de jour (écart-type d'une séance à l'autre)
    'atypical': 0.05,        # simulation : séance atypique (écart ≥ 5 %) mise en attente
    'r_base': 0.015,         # bruit de mesure d'une série : 1,5 %
    'r_rir': 0.01,           # + 1 % × RIR
    'r_rir_target': 1.0,     # simulation : 1 = RIR visé par le programme, 0 = RIR déclaré
    'r_reps': 0.003,         # + 0,3 % × max(0, n − 5)
    'r_reps_from': 5,
    'r_rank': 0.005,         # + 0,5 % × (rang − 1)
    'r_failed': 0.015,       # série ratée
    'failed_extra': 0.5,     # simulation : série ratée, capacité entre r et r + 1
    'r_test': 0.005,         # test 1RM mesuré
    'test_half_step': 1.0,   # simulation : test 1RM + ½ incrément (charge suivante non réussie)
    'r_manual': 0.01,        # valeur de pilotage modifiée à la main (D33)
    'r_prior': 0.10,         # repère initial
    'uncertain': 0.05,       # D29 : écart-type > 5 % de x
    'k_min': 15.0,
    'k_max': 45.0,
    'k_prior_sd': 4.0,       # simulation : écart-type a priori de k
    'k_min_sets': 12,        # D17
    'k_min_spread': 3,       # D17 : écart ≥ 3 répétitions jusqu'à l'échec
    'k_window': 60,
    'valid_rir_max': 4,      # D18
    'valid_n_max': 12,       # D18
    'rest_min_ratio': 0.8,   # D13
    'bias_min': -2.0,        # D19
    'bias_max': 2.0,
    'bias_prior_sd': 1.0,
    'bias_window_days': 21,  # simulation
    'bias_min_sets': 3,
    'rir_noise_sd': 1.0,
    'cap_up': 0.025,         # D20 : +2,5 % par semaine
    'cap_down': 0.05,        # D20 : −5 % par semaine
    'cap_weeks_max': 4,
    'hysteresis': 0.75,      # simulation : écart minimal (en incréments) pour proposer
    'end_base': 0.05,        # D21 : σ = 5 % + 2 % × RIR
    'end_rir': 0.02,
    'end_test': 0.02,
    'end_rir_max': 3,
    'end_dip_double_above': 30,
    'end_bound_sd': 1.0,
    'end_uncertain': 0.10,
    'fatigue_1': -0.05,      # D25
    'fatigue_2': -0.075,
    'fatigue_3': -0.10,
    'fatigue_cut_1': 0.15,
    'fatigue_cut_2': 0.25,
    'fatigue_cut_3': 0.30,
    'sleep_min': 5.0,
    'form_max': 4.0,
    'pain_threshold': 3.0,   # D26
    'pain_cut': 0.20,
    'slope_weeks': 6,        # D27
    'late': 0.8,
    'ahead': 1.2,
    'struct_min_weeks': 6,   # D28
    'struct_total_cap': 0.15,
    'deload_sets': 0.6,
    'deload_load': 0.10,
    'up_big': 0.06,          # D24
    'up_big_cap': 5.0,
    'up_small': 0.03,
    'up_small_cap': 2.5,
    'down': 0.03,
    'down_big': 0.06,
}

EPS = 1e-9
LB_KG = 0.45359237
DAY = 86400.0

DEFAULT_EQUIPMENT = {
    'dumbbell': {'small': 1.0, 'threshold': 10.0, 'large': 2.0},
    'plate': {'step': 1.25},
    'barbell': {'step': 2.5},
    'pulley': {'step': 2.5, 'unit': 'lb'},
    'machine': {'step': 2.5, 'unit': 'kg'},
}


# --------------------------------------------------------------------------
# Outils numériques (identiques en Dart)
# --------------------------------------------------------------------------
def sq(x):
    return x * x


def rnd(x):
    """Arrondi au plus proche, demi s'éloignant de zéro (Dart `round()`)."""
    return float(math.floor(x + 0.5)) if x >= 0 else -float(math.floor(-x + 0.5))


def floor_grid(v, step):
    return math.floor(v / step + EPS) * step


def ceil_grid(v, step):
    return math.ceil(v / step - EPS) * step


def near_grid(v, step):
    return rnd(v / step) * step


def r2(v):
    """Arrondi au centième (sorties, fixtures)."""
    return rnd(v * 100.0) / 100.0


def erfc(x):
    """Numerical Recipes « erfcc » : erreur relative < 1,2e-7."""
    z = abs(x)
    t = 1.0 / (1.0 + 0.5 * z)
    poly = -z * z - 1.26551223 + t * (1.00002368 + t * (0.37409196 + t * (
        0.09678418 + t * (-0.18628806 + t * (0.27886807 + t * (-1.13520398 + t * (
            1.48851587 + t * (-0.82215223 + t * 0.17087277))))))))
    ans = t * math.exp(poly)
    return ans if x >= 0 else 2.0 - ans


def norm_pdf(a):
    return math.exp(-0.5 * a * a) / math.sqrt(2.0 * math.pi)


def norm_cdf(a):
    return 0.5 * erfc(-a / math.sqrt(2.0))


def pct(n, k):
    """%1RM(n) = 1 / (1 + (n − 1) / k), n = répétitions jusqu'à l'échec."""
    return 1.0 / (1.0 + (n - 1.0) / k)


def one_rm(mass, n, k):
    return mass * (1.0 + (n - 1.0) / k)


_ISO = re.compile(r'^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,6}))?)?)?')


def parse_dt(s):
    """Horodatage local → secondes « murales » (le fuseau et l'heure d'été
    n'interviennent pas : durées = différences de composantes)."""
    if s is None:
        return None
    m = _ISO.match(s.strip())
    if not m:
        return None
    y, mo, d = int(m.group(1)), int(m.group(2)), int(m.group(3))
    h = int(m.group(4) or 0)
    mi = int(m.group(5) or 0)
    se = int(m.group(6) or 0)
    frac = m.group(7)
    us = int((frac + '000000')[:6]) if frac else 0
    try:
        days = (datetime(y, mo, d) - datetime(1970, 1, 1)).days
    except ValueError:
        return None
    return days * DAY + h * 3600.0 + mi * 60.0 + se + us / 1e6


def day_of(t):
    return int(math.floor(t / DAY))


def iso(t):
    d = datetime(1970, 1, 1) + timedelta(seconds=t)
    return d.strftime('%Y-%m-%dT%H:%M:%S')


# --------------------------------------------------------------------------
# Échelle de difficulté (D9) et valeurs RIR héritées
# --------------------------------------------------------------------------
SCALE = [
    (0, 'Échec', 'plus aucune rep'),
    (1, 'Très dur', 'encore 1'),
    (2, 'Dur', 'encore 2'),
    (3, 'Soutenu', 'encore 3'),
    (4, 'Modéré', 'encore 4'),
    (5, 'Facile', 'encore 5 ou plus'),
]

_EFFORT = re.compile(r'^\d{1,2}(?:[.,][05])?$')


def parse_legacy_effort(text, scale):
    """Texte libre du champ RIR/RPE (avant 3.0.0) → RIR, ou None.

    `scale` = « rir » ou « rpe » : réglage en vigueur à la mise à jour
    (figé). Acceptés : entier ou demi (« 2 », « 2,5 », « 2.5 »). RPE 1-10,
    RIR = 10 − RPE. RIR > 5 → 5 (« 5 ou plus »). Le reste (plages « 2-3 »,
    texte, « @8 ») est non interprétable : la série compte comme une borne
    inférieure (RIR ≥ 0), jamais comme une mesure.
    """
    if text is None:
        return None
    t = text.replace(' ', '').replace(' ', '').strip()
    if not t or not _EFFORT.match(t):
        return None
    v = float(t.replace(',', '.'))
    if scale == 'rpe':
        if v < 1 or v > 10:
            return None
        v = 10.0 - v
    return 5.0 if v > 5 else v


# --------------------------------------------------------------------------
# Matériel et incréments (D23)
# --------------------------------------------------------------------------
def _eq(equipment, kind):
    return (equipment or {}).get(kind) or DEFAULT_EQUIPMENT[kind]


def to_native(kg, kind, equipment):
    return kg / LB_KG if _eq(equipment, kind).get('unit') == 'lb' else kg


def from_native(v, kind, equipment):
    return v * LB_KG if _eq(equipment, kind).get('unit') == 'lb' else v


def grid_next(kg, kind, equipment, up):
    """Charge suivante (up) ou précédente sur la grille du matériel (kg)."""
    e = _eq(equipment, kind)
    if kind == 'dumbbell':
        small, thr, large = e['small'], e['threshold'], e['large']
        if up:
            if kg < thr - EPS:
                return min(floor_grid(kg, small) + small, thr)
            return thr + floor_grid(kg - thr, large) + large
        if kg > thr + EPS:
            return max(thr + ceil_grid(kg - thr, large) - large, thr)
        return max(ceil_grid(kg, small) - small, 0.0)
    step = e['step']
    native = to_native(kg, kind, equipment)
    if up:
        nxt = floor_grid(native, step) + step
    else:
        nxt = max(ceil_grid(native, step) - step, 0.0)
    return from_native(nxt, kind, equipment)


def grid_round(kg, kind, equipment):
    """Charge la plus proche sur la grille du matériel (kg → kg)."""
    e = _eq(equipment, kind)
    if kind == 'dumbbell':
        small, thr, large = e['small'], e['threshold'], e['large']
        if kg <= thr + EPS:
            v = near_grid(kg, small)
            if v <= thr + EPS:
                return v
        return thr + near_grid(kg - thr, large)
    return from_native(near_grid(to_native(kg, kind, equipment), e['step']), kind, equipment)


# --------------------------------------------------------------------------
# Poids de corps (D12)
# --------------------------------------------------------------------------
def bodyweight_at(weigh_ins, day, fallback):
    """Pesée applicable au jour `day` : la dernière ≤ ce jour ; avant la
    première pesée, la première ; sans pesée, la valeur de pilotage."""
    best = None
    first = None
    for w in weigh_ins:
        t = parse_dt(w['date'])
        if t is None:
            continue
        d = day_of(t)
        if first is None or d < first[0]:
            first = (d, w['kg'])
        if d <= day and (best is None or d >= best[0]):
            best = (d, w['kg'])
    if best is not None:
        return best[1]
    if first is not None:
        return first[1]
    return fallback


# --------------------------------------------------------------------------
# Filtre de Kalman 1D
# --------------------------------------------------------------------------
class Track:
    """État d'une grandeur : x (1RM système en kg, ou maximum de reps) et
    sa variance P."""

    def __init__(self, x, sd, t, k):
        self.x = x
        self.P = sd * sd
        self.t = t
        self.k = k
        self.k_prior = k
        self.k_personal = False
        self.k_obs = []
        self.n_min = None
        self.n_max = None
        self.valid_sets = 0
        self.valid_weeks = []
        self.series = []
        self.last_measure = None
        self.pending = None

    def predict(self, t, q):
        dt = (t - self.t) / DAY
        if dt > 0:
            self.P += sq(q * self.x) * (dt / 7.0)
            self.t = t

    def update(self, z, var):
        if var <= 0:
            return
        g = self.P / (self.P + var)
        self.x += g * (z - self.x)
        self.P *= (1.0 - g)

    def lower_bound(self, bound, s):
        """Contrainte x + ε ≥ L (ε ~ N(0, s²)) : ne peut que relever
        l'estimation, nettement seulement si elle est contredite."""
        scale = math.sqrt(self.P + s * s)
        if scale <= 0:
            return
        a = (self.x - bound) / scale
        cdf = norm_cdf(a)
        lam = -a if cdf < 1e-300 else norm_pdf(a) / cdf
        self.x += self.P * lam / scale
        self.P -= (self.P * self.P) / (scale * scale) * lam * (a + lam)
        if self.P < 1e-9:
            self.P = 1e-9

    def add_week(self, week):
        if week is not None and week not in self.valid_weeks:
            self.valid_weeks.append(week)

    def snapshot(self):
        return copy.deepcopy(self)


# --------------------------------------------------------------------------
# Entrées normalisées
# --------------------------------------------------------------------------
def params_of(inp):
    out = dict(PARAMS)
    out.update(inp.get('params') or {})
    return out


def session_time(s):
    best = None
    for ex in s['exercises']:
        for st in ex['sets']:
            if st.get('done') and st.get('at'):
                t = parse_dt(st['at'])
                if t is not None and (best is None or t < best):
                    best = t
    if best is not None:
        return best
    return parse_dt(s.get('finishedAt'))


def sorted_sessions(inp):
    out = []
    for s in inp['sessions']:
        t = session_time(s)
        if t is not None:
            out.append((t, s['key'], s, len(out)))
    out.sort(key=lambda e: (e[0], e[1], e[3]))
    return [(e[0], e[1], e[2]) for e in out]


def rest_ok(ex, i, ratio):
    """D13 : repos réel (depuis la série validée précédente du même exercice)
    ≥ 80 % du repos prescrit."""
    rest = ex.get('restSec')
    if not rest:
        return True
    t = parse_dt(ex['sets'][i].get('at'))
    if t is None:
        return True
    for j in range(i - 1, -1, -1):
        prev = ex['sets'][j]
        if prev.get('done') and prev.get('at'):
            tp = parse_dt(prev['at'])
            if tp is None:
                return True
            return (t - tp) >= ratio * rest - EPS
    return True


def is_failed(ex, st):
    planned = ex.get('plannedReps')
    return planned is not None and st.get('reps') is not None and st['reps'] < planned


def lift_mass(lift, st, bw):
    """Masse système : poids de corps + lest (tractions, dips, muscle-up),
    charge de la barre (squat)."""
    kg = st.get('kg')
    if lift['bodyweight']:
        if bw is None:
            return None
        return bw + (kg or 0.0)
    if kg is None or kg <= 0:
        return None
    return kg


def event_list(inp):
    """Séances (clé, contenu) et modifications manuelles, dans l'ordre."""
    events = []
    for t, key, s in sorted_sessions(inp):
        events.append((t, 1, key, s, len(events)))
    for h in inp.get('history', []):
        if h.get('source') != 'manual':
            continue
        th = parse_dt(h['at'])
        if th is not None:
            events.append((th, 0, h['ref'] + '@' + h['at'], h, len(events)))
    events.sort(key=lambda e: (e[0], e[1], e[2], e[4]))
    return [(e[0], e[1], e[2], e[3]) for e in events]


def event_signature(ev):
    return json.dumps([ev[0], ev[1], ev[2], ev[3]], sort_keys=True, ensure_ascii=False)


# --------------------------------------------------------------------------
# Rejeu (KT-026, KT-027) et cache incrémental (KT-034)
# --------------------------------------------------------------------------
class Context:
    """Données constantes d'un rejeu."""

    def __init__(self, inp):
        self.inp = inp
        self.P = params_of(inp)
        self.refs = inp.get('references', {})
        self.weigh = inp.get('weighIns', [])
        self.lifts = inp['lifts']
        self.lift_by_ref = {l['ref']: l for l in inp['lifts']}
        self.repmax = inp.get('repmax', [])
        self.rep_by_ref = {r['ref']: r for r in self.repmax}
        self.sessions = sorted_sessions(inp)
        raw = inp.get('history', [])
        order = sorted(range(len(raw)), key=lambda i: (parse_dt(raw[i]['at']) or 0.0, raw[i]['ref'], i))
        hist = [raw[i] for i in order]
        self.initial = {}
        for h in hist:
            if h.get('source') == 'initial' and h['ref'] not in self.initial:
                self.initial[h['ref']] = h['value']

    def bw(self, day):
        return bodyweight_at(self.weigh, day, self.refs.get('B4'))

    def prior(self, ref):
        v = self.initial.get(ref)
        return self.refs.get(ref) if v is None else v


def new_state():
    return {'bias': {'b': 0.0, 'P': None, 'updates': 0}, 'tracks': {}, 'rtracks': {},
            'fatigue': {}, 'signatures': []}


def _track_for(ctx, state, lift, t):
    tr = state['tracks'].get(lift['key'])
    if tr is not None:
        return tr
    v0 = ctx.prior(lift['ref'])
    if v0 is None:
        return None
    if lift['bodyweight']:
        bw0 = ctx.bw(day_of(t))
        if bw0 is None:
            return None
        x0 = v0 + bw0
    else:
        x0 = v0
    if x0 <= 0:
        return None
    tr = Track(x0, ctx.P['r_prior'] * x0, t, lift['k'])
    state['tracks'][lift['key']] = tr
    return tr


def _rtrack_for(ctx, state, ref, t):
    tr = state['rtracks'].get(ref)
    if tr is not None:
        return tr
    v0 = ctx.prior(ref)
    if v0 is None or v0 <= 0:
        return None
    tr = Track(float(v0), ctx.P['r_prior'] * v0, t, 1.0)
    state['rtracks'][ref] = tr
    return tr


def apply_event(ctx, state, ev):
    t, kind, key, obj = ev
    P = ctx.P
    if state['bias']['P'] is None:
        state['bias']['P'] = sq(P['bias_prior_sd'])
    if kind == 0:
        ref = obj['ref']
        lift = ctx.lift_by_ref.get(ref)
        if lift is not None:
            tr = _track_for(ctx, state, lift, t)
            if tr is not None:
                tr.predict(t, P['q'])
                bw = ctx.bw(day_of(t)) if lift['bodyweight'] else 0.0
                z = obj['value'] + (bw or 0.0)
                tr.update(z, sq(P['r_manual'] * z))
                tr.pending = None
                tr.series.append({'at': iso(t), 'x': tr.x, 'sd': math.sqrt(tr.P), 'kind': 'manual', 'session': None})
        elif ref in ctx.rep_by_ref:
            tr = _rtrack_for(ctx, state, ref, t)
            if tr is not None:
                tr.predict(t, P['q'])
                z = float(obj['value'])
                tr.update(z, sq(P['r_manual'] * z))
                tr.series.append({'at': iso(t), 'x': tr.x, 'sd': math.sqrt(tr.P), 'kind': 'manual', 'session': None})
    else:
        _process_session(ctx, state, obj, t)
    state['signatures'].append(event_signature(ev))


def replay(inp):
    ctx = Context(inp)
    state = new_state()
    for ev in event_list(inp):
        apply_event(ctx, state, ev)
    return finish(ctx, state)


def replay_incremental(inp, cached):
    """Reprend un état calculé sur un préfixe identique d'événements ;
    sinon rejeu complet. Résultat identique au rejeu complet (test)."""
    ctx = Context(inp)
    events = event_list(inp)
    sigs = [event_signature(e) for e in events]
    if cached is not None:
        old = cached['signatures']
        if len(old) <= len(sigs) and sigs[:len(old)] == old:
            state = copy.deepcopy(cached)
            for ev in events[len(old):]:
                apply_event(ctx, state, ev)
            return finish(ctx, state)
    state = new_state()
    for ev in events:
        apply_event(ctx, state, ev)
    return finish(ctx, state)


def finish(ctx, state):
    now = parse_dt(ctx.inp['now'])
    state['bw_now'] = ctx.bw(day_of(now))
    if state['bias']['P'] is None:
        state['bias']['P'] = sq(ctx.P['bias_prior_sd'])
    return state


def _process_session(ctx, state, s, t):
    P = ctx.P
    bias = state['bias']
    bw = ctx.bw(day_of(t))
    week = s.get('week')
    anchors = []
    for lift in ctx.lifts:
        key = lift['key']
        exs = [ex for ex in s['exercises'] if ex.get('ref') == lift['ref'] and ex['cat'] in ('strength', 'test1rm')]
        if not any(st.get('done') for ex in exs for st in ex['sets']):
            continue
        tr = _track_for(ctx, state, lift, t)
        if tr is None:
            continue
        tr.predict(t, P['q'])
        x_before = tr.x
        k = tr.k
        # --- test 1RM : meilleure série, + ½ incrément (charge suivante non
        # réussie) ; jamais mis en attente.
        test_z = None
        for ex in exs:
            if ex['cat'] != 'test1rm':
                continue
            for st in ex['sets']:
                if not st.get('done') or st.get('excluded') or not st.get('reps') or st['reps'] < 1:
                    continue
                m = lift_mass(lift, st, bw)
                if m is None:
                    continue
                z = one_rm(m, st['reps'], k)
                if test_z is None or z > test_z:
                    test_z = z
        if test_z is not None:
            test_z += 0.5 * lift['grid'] * P['test_half_step']
            tr.update(test_z, sq(P['r_test'] * test_z))
            tr.pending = None
            tr.last_measure = t
            tr.add_week(week)
            anchors.append(('test', key, test_z, P['r_test']))
        # --- séries de travail
        meas = []
        bound = None
        first_set = None
        failed_anchors = []
        for ex in exs:
            if ex['cat'] != 'strength':
                continue
            for i, st in enumerate(ex['sets']):
                if not st.get('done'):
                    continue
                rank = i + 1
                if st.get('excluded') or not st.get('reps') or st['reps'] < 1:
                    continue
                m = lift_mass(lift, st, bw)
                if m is None:
                    continue
                if first_set is None:
                    first_set = (ex, st, m)
                if not rest_ok(ex, i, P['rest_min_ratio']):
                    continue
                r = st['reps']
                if ex.get('cluster'):
                    # Clusters : repos intra-série, la relation reps ↔ % ne
                    # s'applique pas ; chaque rep est au moins un single.
                    bound = m if bound is None or m > bound else bound
                    continue
                rir = st.get('rir')
                if is_failed(ex, st):
                    z = one_rm(m, r + P['failed_extra'], k)
                    meas.append((z, P['r_failed'] + P['r_rank'] * (rank - 1)))
                    if rank == 1:
                        # Ancre de biais : la série ratée reflète la forme du
                        # jour (effet de jour dans sa variance).
                        failed_anchors.append(('failed', key, z, math.sqrt(sq(P['r_failed']) + sq(P['sigma_day']))))
                    tr.valid_sets += 1
                    tr.add_week(week)
                elif rir is not None and rir <= P['valid_rir_max'] and r + rir <= P['valid_n_max']:
                    n = r + max(0.0, rir + bias['b'])
                    z = one_rm(m, n, k)
                    rs = ex.get('rirTarget')
                    if rs is None or P['r_rir_target'] < 0.5:
                        rs = rir
                    ns = r + rs
                    sig = (P['r_base'] + P['r_rir'] * rs + P['r_reps'] * max(0.0, ns - P['r_reps_from'])
                           + P['r_rank'] * (rank - 1))
                    meas.append((z, sig))
                    tr.valid_sets += 1
                    tr.add_week(week)
                elif rir is not None and rir > P['valid_rir_max'] and r <= P['valid_n_max']:
                    # « Facile » : au moins RIR − 1 en réserve (bruit ±1).
                    lb = one_rm(m, r + max(0.0, rir - 1.0 + bias['b']), k)
                    bound = lb if bound is None or lb > bound else bound
                elif r <= P['valid_n_max']:
                    lb = one_rm(m, r, k)
                    bound = lb if bound is None or lb > bound else bound
        day_z = None
        if meas:
            wsum = 0.0
            zsum = 0.0
            for z, sig in meas:
                var = sq(sig * x_before)
                wsum += 1.0 / var
                zsum += z / var
            zbar = zsum / wsum
            day_z = zbar
            R = 1.0 / wsum + sq(P['sigma_day'] * x_before)
            gap = zbar / x_before - 1.0
            pend = tr.pending
            tr.pending = None
            if pend is not None and gap * pend['gap'] > 0 and abs(gap) >= 0.5 * P['atypical']:
                # Séance atypique confirmée par la suivante : changement réel
                # probable. L'incertitude est rouverte de l'écart observé,
                # puis les deux séances comptent.
                jump = 0.5 * (pend['gap'] + gap) * x_before
                tr.P += jump * jump
                tr.update(pend['z'], pend['R'])
                if pend['bound'] is not None:
                    tr.lower_bound(pend['bound'], P['sigma_day'] * tr.x)
                tr.update(zbar, R)
                tr.last_measure = t
            elif abs(gap) >= P['atypical'] and test_z is None:
                # Séance atypique isolée : en attente de confirmation (ni
                # estimation ni biais n'en tiennent compte d'ici là).
                tr.pending = {'z': zbar, 'R': R, 'gap': gap, 'bound': bound, 'session': s['key']}
                bound = None
                failed_anchors = []
            else:
                tr.update(zbar, R)
                tr.last_measure = t
        if bound is not None:
            tr.lower_bound(bound, P['sigma_day'] * tr.x)
        anchors.extend(failed_anchors)
        if first_set is not None:
            ex, st, m = first_set
            lvl = fatigue_level(P, x_before, m, st['reps'], st.get('rir'), bias['b'], k,
                                failed=is_failed(ex, st))
            if lvl > 0:
                state['fatigue'].setdefault(s['key'], {})[key] = lvl
        tr.series.append({'at': iso(t), 'x': tr.x, 'sd': math.sqrt(tr.P), 'kind': 'session', 'session': s['key'],
                          'z': day_z})

    # --- endurance (D21)
    for spec in ctx.repmax:
        ref = spec['ref']
        exs = [ex for ex in s['exercises'] if ex.get('ref') == ref and ex['cat'] in ('endurance', 'enduranceTest')]
        if not any(st.get('done') for ex in exs for st in ex['sets']):
            continue
        tr = _rtrack_for(ctx, state, ref, t)
        if tr is None:
            continue
        tr.predict(t, P['q'])
        test_max = None
        for ex in exs:
            if ex['cat'] != 'enduranceTest':
                continue
            for st in ex['sets']:
                if st.get('done') and not st.get('excluded') and st.get('reps') is not None:
                    if test_max is None or st['reps'] > test_max:
                        test_max = st['reps']
        if test_max is not None and test_max > 0:
            # « Un test mesuré remplace l'estimation » (D21).
            tr.x = float(test_max)
            tr.P = sq(P['end_test'] * test_max)
            tr.last_measure = t
            tr.add_week(week)
            anchors.append(('endtest', ref, float(test_max), P['end_test']))
        else:
            first = None
            best = None
            for ex in exs:
                if ex['cat'] != 'endurance' or ex.get('emom'):
                    continue
                for st in ex['sets']:
                    if not st.get('done') or st.get('excluded') or not st.get('reps'):
                        continue
                    if first is None:
                        first = st
                    if best is None or st['reps'] > best:
                        best = st['reps']
            if first is not None:
                rir = first.get('rir')
                if rir is not None and rir <= P['end_rir_max']:
                    z = first['reps'] + max(0.0, rir + bias['b'])
                    sig = P['end_base'] + P['end_rir'] * rir
                    if spec.get('dips') and first['reps'] > P['end_dip_double_above']:
                        sig *= 2.0
                    tr.update(z, sq(sig * z))
                    tr.last_measure = t
                    tr.add_week(week)
            if best is not None:
                tr.lower_bound(float(best), P['end_bound_sd'])
        tr.series.append({'at': iso(t), 'x': tr.x, 'sd': math.sqrt(tr.P), 'kind': 'session', 'session': s['key']})

    for a in anchors:
        _bias_update(ctx, state, a, t, s)


def _k_refit(tr, P):
    """D17, ancrée sur les tests : n − 1 = k·u + c (c absorbe le biais de
    RIR), moindres carrés rétrécis vers l'a priori du programme, bornés à
    [15 ; 45]. Hors tests, x, k et le biais ne sont pas séparables : k ne
    change pas entre deux tests (contrat §4.3)."""
    obs = tr.k_obs[-P['k_window']:]
    if len(obs) < P['k_min_sets'] or tr.n_min is None or tr.n_max - tr.n_min < P['k_min_spread']:
        return
    mu = sum(u for u, _ in obs) / len(obs)
    mn = sum(n for _, n in obs) / len(obs)
    suu = sum(sq(u - mu) for u, _ in obs)
    sun = sum((u - mu) * (n - mn) for u, n in obs)
    if suu <= 1e-12:
        return
    k_ls = sun / suu
    sig_n2 = sq(P['rir_noise_sd']) + sq(tr.k_prior * P['sigma_day'] * (1.0 + mu))
    v_ls = sig_n2 / suu
    w0 = 1.0 / sq(P['k_prior_sd'])
    k = (tr.k_prior * w0 + k_ls / v_ls) / (w0 + 1.0 / v_ls)
    tr.k = min(P['k_max'], max(P['k_min'], k))
    tr.k_personal = True


def _bias_update(ctx, state, anchor, t, s):
    """D19 : écart entre le RIR déclaré et le RIR impliqué par une ancre
    (test ou série ratée en série 1), sur les séances des 21 jours
    précédents."""
    P = ctx.P
    bias = state['bias']
    typ, key, z, sig_rel = anchor
    lo = t - P['bias_window_days'] * DAY
    diffs = []
    if typ in ('test', 'failed'):
        lift = None
        for l in ctx.lifts:
            if l['key'] == key:
                lift = l
        tr = state['tracks'][key]
        k = tr.k
        pcts = []
        k_new = []
        for ts, _, ss in ctx.sessions:
            if ts < lo or ts >= t or ss['key'] == s['key']:
                continue
            bw = ctx.bw(day_of(ts))
            for ex in ss['exercises']:
                if ex.get('ref') != lift['ref'] or ex['cat'] != 'strength' or ex.get('cluster'):
                    continue
                for st in ex['sets']:
                    if not st.get('done') or st.get('excluded') or not st.get('reps'):
                        continue
                    rir = st.get('rir')
                    if rir is None or rir > P['valid_rir_max'] or st['reps'] + rir > P['valid_n_max']:
                        continue
                    if is_failed(ex, st):
                        continue
                    m = lift_mass(lift, st, bw)
                    if m is None or m <= 0:
                        continue
                    n_imp = 1.0 + k * (z / m - 1.0)
                    diffs.append((n_imp - st['reps']) - rir)
                    pcts.append(m / z)
                    if typ == 'test':
                        k_new.append((z / m - 1.0, st['reps'] + rir))
        for u, n in k_new:
            tr.n_min = n if tr.n_min is None or n < tr.n_min else tr.n_min
            tr.n_max = n if tr.n_max is None or n > tr.n_max else tr.n_max
            tr.k_obs.append((u, n))
        if k_new:
            _k_refit(tr, P)
        if len(diffs) < P['bias_min_sets']:
            return
        p_avg = sum(pcts) / len(pcts)
        sig_n = k * sig_rel / p_avg
    else:
        for ts, _, ss in ctx.sessions:
            if ts < lo or ts >= t or ss['key'] == s['key']:
                continue
            first = None
            for ex in ss['exercises']:
                if ex.get('ref') != key or ex['cat'] != 'endurance' or ex.get('emom'):
                    continue
                for st in ex['sets']:
                    if st.get('done') and not st.get('excluded') and st.get('reps'):
                        first = st
                        break
                if first is not None:
                    break
            if first is not None:
                rir = first.get('rir')
                if rir is not None and rir <= P['end_rir_max']:
                    diffs.append((z - first['reps']) - rir)
        if len(diffs) < P['bias_min_sets']:
            return
        sig_n = sig_rel * z
    b_obs = sum(diffs) / len(diffs)
    R = sq(P['rir_noise_sd']) / len(diffs) + sig_n * sig_n
    g = bias['P'] / (bias['P'] + R)
    bias['b'] += g * (b_obs - bias['b'])
    bias['P'] *= (1.0 - g)
    bias['b'] = min(P['bias_max'], max(P['bias_min'], bias['b']))
    bias['updates'] += 1


# --------------------------------------------------------------------------
# D25 — jour de fatigue
# --------------------------------------------------------------------------
def fatigue_level(P, x_current, mass, reps, rir, b, k, failed=False, sleep=None, form=None):
    """Réduction de volume proposée : 0 (rien), 0.15, 0.25 ou 0.30."""
    level = 0.0
    if sleep is not None and sleep < P['sleep_min'] - EPS:
        level = P['fatigue_cut_3']
    if form is not None and form <= P['form_max'] + EPS:
        level = P['fatigue_cut_3']
    if mass is not None and reps and x_current:
        n = None
        if failed:
            n = reps + P['failed_extra']
        elif rir is not None:
            n = reps + max(0.0, rir + b)
        if n is not None:
            gap = one_rm(mass, n, k) / x_current - 1.0
            if gap <= P['fatigue_3'] + EPS:
                level = max(level, P['fatigue_cut_3'])
            elif gap <= P['fatigue_2'] + EPS:
                level = max(level, P['fatigue_cut_2'])
            elif gap <= P['fatigue_1'] + EPS:
                level = max(level, P['fatigue_cut_1'])
    return level


# --------------------------------------------------------------------------
# D24 — prescription pendant la séance
# --------------------------------------------------------------------------
def in_session(P, lift, sets, rir_target, planned, bw, grid, flags):
    """Charge suggérée pour les séries restantes, ou None.

    `sets` : séries validées et non écartées du jour, dans l'ordre
    ({kg, reps, rir}). `flags` : locked (verrou D6), deload / pain /
    fatigue (aucune hausse), refused = directions refusées (D7).
    """
    if flags.get('locked') or not sets or rir_target is None:
        return None
    if lift['bodyweight'] and bw is None:
        return None
    cur = sets[-1]
    kg = cur.get('kg') or 0.0
    mass = bw + kg if lift['bodyweight'] else kg
    if mass <= 0:
        return None
    refused = flags.get('refused') or []
    no_up = bool(flags.get('deload') or flags.get('pain') or flags.get('fatigue'))

    def change(delta, cap, up, reason):
        if up and (no_up or 'up' in refused):
            return None
        if not up and 'down' in refused:
            return None
        raw = mass * (1.0 + delta)
        target = raw - bw if lift['bodyweight'] else raw
        if up:
            limit = target if cap is None else min(target, kg + cap)
            new = floor_grid(limit, grid)
            if new <= kg + EPS:
                return None
        else:
            new = ceil_grid(target, grid)
            if lift['bodyweight'] and new < 0:
                new = 0.0
            if new >= kg - EPS:
                return None
        return {'kg': r2(new), 'from': r2(kg), 'delta': delta, 'direction': 'up' if up else 'down',
                'reason': reason}

    if planned is not None and cur.get('reps') is not None and cur['reps'] < planned:
        big = planned - cur['reps'] >= 2
        return change(-(P['down_big'] if big else P['down']), None, False, 'missed2' if big else 'missed')
    if len(sets) >= 2 and rir_target >= 2:
        a = sets[-2]
        if a.get('rir') is not None and cur.get('rir') is not None and a['rir'] <= 1 and cur['rir'] <= 1:
            return change(-P['down'], None, False, 'twoHard')
    if len(sets) == 1:
        rir = cur.get('rir')
        if rir is None:
            return None
        if rir >= rir_target + 2 - EPS:
            return change(P['up_big'], P['up_big_cap'], True, 'easy2')
        if rir >= rir_target + 1 - EPS:
            return change(P['up_small'], P['up_small_cap'], True, 'easy1')
    return None


# --------------------------------------------------------------------------
# Propositions de fin de séance (D5 b, D20, D21, D22, D26, D33)
# --------------------------------------------------------------------------
def weeks_since_change(inp, ref, t, P):
    last = None
    for h in inp.get('history', []):
        if h['ref'] != ref:
            continue
        th = parse_dt(h['at'])
        if th is not None and th <= t and (last is None or th > last):
            last = th
    if last is None:
        return 1
    w = int(math.ceil((t - last) / (7 * DAY) - EPS))
    return max(1, min(P['cap_weeks_max'], w))


def proposals(inp, state, session_key):
    P = params_of(inp)
    refs = inp.get('references', {})
    equipment = inp.get('equipment') or DEFAULT_EQUIPMENT
    locks = set(inp.get('locks') or [])
    pains = inp.get('pain') or {}
    sess = None
    for s in inp['sessions']:
        if s['key'] == session_key:
            sess = s
    if sess is None:
        return []
    t = session_time(sess)
    if t is None:
        return []
    now = parse_dt(inp['now'])
    bw_now = state['bw_now']
    day_bw = bodyweight_at(inp.get('weighIns', []), day_of(t), refs.get('B4'))
    here = pains.get(session_key) or {}
    out = []
    for lift in inp['lifts']:
        key, ref = lift['key'], lift['ref']
        exs = [ex for ex in sess['exercises'] if ex.get('ref') == ref and ex['cat'] in ('strength', 'test1rm')]
        if not any(st.get('done') for ex in exs for st in ex['sets']):
            continue
        tr = state['tracks'].get(key)
        cur = refs.get(ref)
        if tr is None or cur is None or ref in locks:
            continue
        if lift['bodyweight'] and bw_now is None:
            continue
        grid = lift['grid']
        bw = bw_now if lift['bodyweight'] else 0.0
        painful = (here.get(key) or 0) > P['pain_threshold']
        test_best = None
        for ex in exs:
            if ex['cat'] != 'test1rm':
                continue
            for st in ex['sets']:
                if st.get('done') and not st.get('excluded') and st.get('reps'):
                    m = lift_mass(lift, st, day_bw)
                    if m is None:
                        continue
                    z = one_rm(m, st['reps'], tr.k)
                    if test_best is None or z > test_best:
                        test_best = z
        if test_best is not None:
            # Test mesuré : proposé tel quel (source « test »), sans plafond.
            val = near_grid(test_best - (day_bw if lift['bodyweight'] else 0.0), grid)
            if lift['bodyweight'] and val < 0:
                val = 0.0
            if abs(val - cur) > EPS and not (painful and val > cur):
                out.append({'id': session_key + '|' + ref, 'ref': ref, 'kind': 'value', 'from': r2(cur),
                            'to': r2(val), 'source': 'test', 'reason': 'test'})
            continue
        if math.sqrt(tr.P) > P['uncertain'] * tr.x or tr.last_measure is None:
            continue
        target = tr.x - bw
        if abs(target - cur) < P['hysteresis'] * grid:
            continue
        w = weeks_since_change(inp, ref, now, P)
        cur_sys = cur + bw
        hi = cur_sys * (1.0 + P['cap_up'] * w) - bw
        lo = cur_sys * (1.0 - P['cap_down'] * w) - bw
        val = near_grid(target, grid)
        if val > hi + EPS:
            val = floor_grid(hi, grid)
        if val < lo - EPS:
            val = ceil_grid(lo, grid)
        if lift['bodyweight'] and val < 0:
            val = 0.0
        if painful and val > cur:
            continue
        if abs(val - cur) > EPS:
            out.append({'id': session_key + '|' + ref, 'ref': ref, 'kind': 'value', 'from': r2(cur),
                        'to': r2(val), 'source': 'koach', 'reason': 'up' if val > cur else 'down'})
    for spec in inp.get('repmax', []):
        ref = spec['ref']
        exs = [ex for ex in sess['exercises'] if ex.get('ref') == ref and ex['cat'] in ('endurance', 'enduranceTest')]
        if not any(st.get('done') for ex in exs for st in ex['sets']):
            continue
        tr = state['rtracks'].get(ref)
        cur = refs.get(ref)
        if tr is None or cur is None or ref in locks:
            continue
        test_max = None
        for ex in exs:
            if ex['cat'] == 'enduranceTest':
                for st in ex['sets']:
                    if st.get('done') and not st.get('excluded') and st.get('reps') is not None:
                        if test_max is None or st['reps'] > test_max:
                            test_max = st['reps']
        if test_max is not None and test_max > 0:
            if abs(test_max - cur) > EPS:
                out.append({'id': session_key + '|' + ref, 'ref': ref, 'kind': 'value', 'from': r2(cur),
                            'to': float(test_max), 'source': 'test', 'reason': 'test'})
            continue
        if tr.last_measure is None or math.sqrt(tr.P) > P['end_uncertain'] * tr.x:
            continue
        if abs(tr.x - cur) < 1.0:
            continue
        w = weeks_since_change(inp, ref, now, P)
        hi = cur * (1.0 + P['cap_up'] * w)
        lo = cur * (1.0 - P['cap_down'] * w)
        val = rnd(tr.x)
        if val > hi + EPS:
            val = float(math.floor(hi + EPS))
        if val < lo - EPS:
            val = float(math.ceil(lo - EPS))
        if abs(val - cur) > EPS:
            out.append({'id': session_key + '|' + ref, 'ref': ref, 'kind': 'value', 'from': r2(cur),
                        'to': val, 'source': 'koach', 'reason': 'up' if val > cur else 'down'})
    out += _accessory_proposals(inp, P, sess, session_key, equipment, locks)
    out += _pain_proposals(inp, P, session_key)
    return out


def _accessory_proposals(inp, P, sess, session_key, equipment, locks):
    """D22 : double progression. Toutes les séries au nombre visé avec un
    RIR ≥ cible + 1 → +1 incrément ; nombre visé manqué deux séances de
    suite → −1 incrément ; `prevention` : jamais de hausse."""
    out = []
    refs = inp.get('references', {})
    order = sorted_sessions(inp)
    t = session_time(sess)
    for a in inp.get('accessories', []):
        ref = a['ref']
        done = []
        for ex in sess['exercises']:
            if ex.get('ref') == ref and ex['cat'] == 'accessory':
                for st in ex['sets']:
                    if st.get('done') and not st.get('excluded'):
                        done.append((ex, st))
        if not done or ref in locks or refs.get(ref) is None:
            continue
        cur = refs[ref]
        success = True
        failed = False
        for ex, st in done:
            planned = ex.get('plannedReps')
            target = ex.get('rirTarget')
            if planned is None or st.get('reps') is None:
                success = False
            elif st['reps'] < planned:
                failed = True
                success = False
            elif target is None or st.get('rir') is None or st['rir'] < target + 1 - EPS:
                success = False
        if success and not a.get('prevention'):
            val = grid_next(cur, a['equipment'], equipment, True)
            out.append({'id': session_key + '|' + ref, 'ref': ref, 'kind': 'value', 'from': r2(cur),
                        'to': r2(val), 'source': 'koach', 'reason': 'accUp'})
        elif failed:
            prev_failed = False
            for i in range(len(order) - 1, -1, -1):
                ts, key, ss = order[i]
                if ts >= t or key == session_key:
                    continue
                prev = []
                for ex in ss['exercises']:
                    if ex.get('ref') == ref and ex['cat'] == 'accessory':
                        for st in ex['sets']:
                            if st.get('done') and not st.get('excluded'):
                                prev.append((ex, st))
                if not prev:
                    continue
                for ex, st in prev:
                    if is_failed(ex, st):
                        prev_failed = True
                break
            if prev_failed:
                val = grid_next(cur, a['equipment'], equipment, False)
                if val < cur - EPS:
                    out.append({'id': session_key + '|' + ref, 'ref': ref, 'kind': 'value', 'from': r2(cur),
                                'to': r2(val), 'source': 'koach', 'reason': 'accDown'})
    return out


def _pain_proposals(inp, P, session_key):
    """D26 : douleur > 3/10 deux séances de suite sur un mouvement →
    allègement de 20 % + isométries (règle 6)."""
    pains = inp.get('pain') or {}
    here = pains.get(session_key) or {}
    order = [key for _, key, _ in sorted_sessions(inp)]
    if session_key not in order:
        return []
    idx = order.index(session_key)
    active = set(inp.get('painRelief') or [])
    out = []
    for lift in inp['lifts']:
        key = lift['key']
        if (here.get(key) or 0) <= P['pain_threshold'] or key in active:
            continue
        prev = None
        for j in range(idx - 1, -1, -1):
            q = pains.get(order[j]) or {}
            if key in q:
                prev = q[key]
                break
        if prev is not None and prev > P['pain_threshold']:
            out.append({'id': session_key + '|pain|' + key, 'ref': lift['ref'], 'kind': 'pain', 'movement': key,
                        'cut': P['pain_cut'], 'source': 'koach', 'reason': 'pain'})
    return out


def pain_blocks(inp, key):
    """D26 : douleur > 3/10 à la dernière séance notée de ce mouvement →
    aucune hausse à la séance suivante."""
    P = params_of(inp)
    pains = inp.get('pain') or {}
    for _, sk, _ in reversed(sorted_sessions(inp)):
        q = pains.get(sk) or {}
        if key in q:
            return q[key] > P['pain_threshold']
    return False


# --------------------------------------------------------------------------
# D27 — objectifs, pentes, statut
# --------------------------------------------------------------------------
def estimate_at(series, t):
    last = None
    for p in series:
        tp = parse_dt(p['at'])
        if tp is not None and tp <= t + EPS:
            last = p
    return last


def slope_per_week(series, now, weeks, offset=0.0):
    """Pente (unités / semaine) des estimations des `weeks` dernières
    semaines (régression linéaire, un point par semaine)."""
    pts = []
    for i in range(weeks):
        p = estimate_at(series, now - i * 7 * DAY)
        if p is not None:
            pts.append((-float(i), p['x'] - offset))
    if len(pts) < 3:
        return None
    n = float(len(pts))
    mx = sum(p[0] for p in pts) / n
    my = sum(p[1] for p in pts) / n
    sxx = sum(sq(p[0] - mx) for p in pts)
    if sxx <= 0:
        return None
    return sum((p[0] - mx) * (p[1] - my) for p in pts) / sxx


def objective_status(P, current, slope, target, target_day, now_day):
    if target is None or target_day is None or current is None:
        return {'status': 'none'}
    if current >= target - EPS:
        return {'status': 'reached'}
    weeks_left = (target_day - now_day) / 7.0
    if weeks_left <= 0:
        return {'status': 'past'}
    required = (target - current) / weeks_left
    if slope is None:
        return {'status': 'insufficient', 'required': r2(required)}
    ratio = slope / required
    status = 'late' if ratio < P['late'] else ('ahead' if ratio > P['ahead'] else 'onTrack')
    return {'status': status, 'required': r2(required), 'observed': r2(slope), 'ratio': r2(ratio)}


def objectives(inp, state):
    P = params_of(inp)
    now = parse_dt(inp['now'])
    now_day = day_of(now)
    bw = state['bw_now'] or 0.0
    goals = inp.get('objectives') or {}
    out = {}

    def one(ref, tr, off):
        cur = tr.x - off
        slope = slope_per_week(tr.series, now, P['slope_weeks'], off)
        res = {}
        for level in ('stage', 'final'):
            o = (goals.get(ref) or {}).get(level)
            if o is None:
                continue
            d = parse_dt(o.get('date')) if o.get('date') else None
            res[level] = objective_status(P, cur, slope, o.get('target'), None if d is None else day_of(d), now_day)
        out[ref] = {'current': r2(cur), 'slope': None if slope is None else r2(slope), 'objectives': res}

    for lift in inp['lifts']:
        tr = state['tracks'].get(lift['key'])
        if tr is not None:
            one(lift['ref'], tr, bw if lift['bodyweight'] else 0.0)
    for spec in inp.get('repmax', []):
        tr = state['rtracks'].get(spec['ref'])
        if tr is not None:
            one(spec['ref'], tr, 0.0)
    return out


# --------------------------------------------------------------------------
# D28 — option « Koach adapte la structure »
# --------------------------------------------------------------------------
def structure(inp, state, week):
    """Propositions pour la semaine `week` : ±1 série par mouvement selon
    l'objectif (≥ 6 semaines de données), total ≤ 15 % du volume de la
    semaine, jamais en décharge ni en tests ; décharge anticipée."""
    P = params_of(inp)
    info = None
    for w in inp.get('weeks', []):
        if w['n'] == week:
            info = w
    if info is None or info.get('type') in ('deload', 'test'):
        return []
    total = info.get('totalSets', 0)
    cap = int(math.floor(P['struct_total_cap'] * total + EPS))
    objs = objectives(inp, state)
    out = []
    used = 0
    for lift in inp['lifts']:
        key, ref = lift['key'], lift['ref']
        tr = state['tracks'].get(key)
        main = (info.get('main') or {}).get(key)
        if tr is None or not main or len(tr.valid_weeks) < P['struct_min_weeks']:
            continue
        o = (objs.get(ref) or {}).get('objectives') or {}
        st = o.get('stage')
        if st is None or st.get('status') in ('none', 'reached', 'past'):
            st = o.get('final')
        if st is None:
            continue
        status = st.get('status')
        delta = 1 if status == 'late' else (-1 if status == 'ahead' else 0)
        if delta == 0 or used + 1 > cap:
            continue
        used += 1
        out.append({'id': 'W%d|sets|%s' % (week, key), 'week': week, 'kind': 'sets', 'movement': key,
                    'exercise': main, 'delta': delta, 'reason': status})
    now = parse_dt(inp['now'])
    fat = state.get('fatigue') or {}
    quest = inp.get('questionnaires') or {}
    for lift in inp['lifts']:
        key = lift['key']
        tr = state['tracks'].get(key)
        if tr is None:
            continue
        measured = [p for p in tr.series if p.get('z') is not None]
        p0 = estimate_at(measured, now)
        p1 = estimate_at(measured, now - 7 * DAY)
        p2 = estimate_at(measured, now - 14 * DAY)
        if p0 is None or p1 is None or p2 is None:
            continue
        if p0['session'] == p1['session'] or p1['session'] == p2['session']:
            continue
        if not (p2['z'] > p1['z'] + EPS and p1['z'] > p0['z'] + EPS):
            continue
        lo = now - 14 * DAY
        signal = False
        for p in tr.series:
            tp = parse_dt(p['at'])
            if tp is None or tp < lo or p.get('kind') != 'session':
                continue
            sk = p.get('session')
            if key in (fat.get(sk) or {}):
                signal = True
            q = quest.get(sk) or {}
            if q.get('sleep') is not None and q['sleep'] < P['sleep_min'] - EPS:
                signal = True
            if q.get('form') is not None and q['form'] <= P['form_max'] + EPS:
                signal = True
        if signal:
            out.append({'id': 'W%d|deload' % week, 'week': week, 'kind': 'deload', 'movement': key,
                        'sets': P['deload_sets'], 'load': P['deload_load'], 'reason': 'decline'})
            break
    return out


# --------------------------------------------------------------------------
# Sorties (fixtures)
# --------------------------------------------------------------------------
def summarize(state):
    out = {'bias': r2(state['bias']['b']), 'biasUpdates': state['bias']['updates'], 'lifts': {}, 'repmax': {},
           'bwNow': None if state.get('bw_now') is None else r2(state['bw_now'])}
    for key in sorted(state['tracks']):
        tr = state['tracks'][key]
        out['lifts'][key] = {
            'x': r2(tr.x), 'sd': r2(math.sqrt(tr.P)), 'k': r2(tr.k), 'kPersonal': tr.k_personal,
            'validSets': tr.valid_sets, 'validWeeks': len(tr.valid_weeks),
            'pending': tr.pending is not None,
            'series': [r2(p['x']) for p in tr.series],
        }
    for ref in sorted(state['rtracks']):
        tr = state['rtracks'][ref]
        out['repmax'][ref] = {'x': r2(tr.x), 'sd': r2(math.sqrt(tr.P)), 'validWeeks': len(tr.valid_weeks),
                              'series': [r2(p['x']) for p in tr.series]}
    return out


def run_case(case):
    out = {}
    if 'input' in case:
        inp = case['input']
        state = replay(inp)
        out['state'] = summarize(state)
        if 'proposalsFor' in case:
            out['proposals'] = proposals(inp, state, case['proposalsFor'])
        if case.get('objectives'):
            out['objectives'] = objectives(inp, state)
        if 'structureWeek' in case:
            out['structure'] = structure(inp, state, case['structureWeek'])
        if case.get('painBlocks'):
            out['painBlocks'] = {k: pain_blocks(inp, k) for k in case['painBlocks']}
    P = dict(PARAMS)
    if 'inSession' in case:
        out['inSession'] = [in_session(P, c['lift'], c['sets'], c.get('rirTarget'), c.get('planned'),
                                       c.get('bw'), c['grid'], c.get('flags') or {}) for c in case['inSession']]
    if 'fatigue' in case:
        out['fatigue'] = [fatigue_level(P, c['x'], c.get('mass'), c.get('reps'), c.get('rir'), c.get('b', 0.0),
                                        c['k'], failed=c.get('failed', False), sleep=c.get('sleep'),
                                        form=c.get('form')) for c in case['fatigue']]
    if 'legacyEffort' in case:
        out['legacyEffort'] = [parse_legacy_effort(c['text'], c['scale']) for c in case['legacyEffort']]
    if 'grid' in case:
        eq = case.get('equipment') or DEFAULT_EQUIPMENT
        out['grid'] = [r2(grid_next(c['kg'], c['kind'], eq, c['up'])) if 'up' in c
                       else r2(grid_round(c['kg'], c['kind'], eq)) for c in case['grid']]
    return out


def main(argv):
    if len(argv) >= 2 and argv[1] == '--write-expected':
        root = Path(argv[2]) if len(argv) > 2 else Path(__file__).resolve().parents[1] / 'test' / 'fixtures' / 'koach'
        for path in sorted(root.glob('*.json')):
            case = json.loads(path.read_text(encoding='utf-8'))
            case['expected'] = run_case(case)
            path.write_text(json.dumps(case, ensure_ascii=False, indent=1, sort_keys=True) + '\n', encoding='utf-8')
            print('écrit', path.name)
        return 0
    for p in argv[1:]:
        case = json.loads(Path(p).read_text(encoding='utf-8'))
        print(json.dumps(run_case(case), ensure_ascii=False, indent=1, sort_keys=True))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
