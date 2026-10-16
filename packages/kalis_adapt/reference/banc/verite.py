# -*- coding: utf-8 -*-
"""Portage Python du modèle de vérité de force du banc
(`kalis_adapt/lib/src/sim/truth.dart`, 0.3.1) : athlète simulé à vérité
connue, modèles A, B et C.

Ce fichier ne décide rien : il reproduit, ligne pour ligne, l'athlète
simulé du banc Dart pour que la référence Python de Koach 1.0 soit jugée
sur les MÊMES modèles de vérité que le témoin `kalis_adapt` 0.3.1. Sa
fidélité est vérifiée par `tests/test_verite.py` contre les traces
exportées par le banc Dart (`donnees/traces_verite.json.gz`) et contre les
tirages de départ exportés avec chaque saison de référence.
"""
import math

from .alea import SimRandom, LoadGrid, clamp, dart_round, flames_to_rir, flames_from_rir

exp = math.exp
ln = math.log

LEVEL_SCALE = [0.62, 1.0, 1.3, 1.5]
LEVEL_ABILITY = [3.0, 5.0, 7.0, 9.0]
WEEKS_TRAINED = [8.0, 60.0, 200.0, 400.0]
LEVEL_BIAS = [0.45, 0.30, 0.20, 0.12]
N_GROUPS = 17  # groupes musculaires de kalis_plan (indices 0 à 16)

TENDON_ZONES = ['elbow', 'shoulder', 'wrist_hand']


def ratio_of(pattern, t):
    """Rapport du 1RM de charge totale au poids du corps (`_ratioOf`)."""
    def pick(barbell, dumbbell, machine, cable):
        if t == 'barbell':
            return barbell
        if t in ('dumbbells', 'kettlebell'):
            return dumbbell
        if t == 'machine':
            return machine
        if t == 'cable':
            return cable
        return barbell
    added = t == 'addedWeight'
    if pattern == 'squat':
        return pick(1.25, 0.35, 2.2, 1.0)
    if pattern == 'charniereHanche':
        return pick(1.5, 0.42, 1.0, 0.8)
    if pattern == 'fente':
        return 1.25 if added else pick(0.8, 0.25, 0.8, 0.5)
    if pattern == 'pousseeHorizontale':
        return 1.15 if added else pick(1.0, 0.38, 0.9, 0.5)
    if pattern == 'pousseeInclinee':
        return pick(0.85, 0.33, 0.8, 0.45)
    if pattern == 'pousseeVerticaleHaute':
        return pick(0.65, 0.25, 0.6, 0.35)
    if pattern == 'pousseeVerticaleBasse':
        return 1.6 if added else 1.0
    if pattern == 'tirageVertical':
        return 1.45 if added else 0.9
    if pattern == 'tirageHorizontal':
        return 1.2 if added else pick(0.9, 0.40, 0.9, 0.8)
    if pattern == 'transitionMuscleUp':
        return 1.15
    if pattern == 'isolationBiceps':
        return pick(0.45, 0.20, 0.4, 0.35)
    if pattern == 'isolationTriceps':
        return pick(0.40, 0.15, 0.4, 0.35)
    if pattern == 'isolationEpaules':
        return pick(0.3, 0.12, 0.4, 0.12)
    if pattern == 'isolationPectoraux':
        return pick(0.5, 0.2, 0.6, 0.25)
    if pattern == 'isolationDos':
        return pick(0.5, 0.25, 0.6, 0.4)
    if pattern == 'isolationTrapezes':
        return pick(1.0, 0.4, 0.8, 0.6)
    if pattern == 'extensionGenou':
        return 0.8
    if pattern == 'flexionGenou':
        return 0.6
    if pattern == 'mollets':
        return pick(1.2, 0.4, 1.5, 0.8)
    if pattern == 'extensionHanche':
        return pick(1.4, 0.4, 0.8, 0.5)
    if pattern == 'adducteursAbducteurs':
        return 0.8
    if pattern == 'halterophilie':
        return pick(0.8, 0.3, 0.6, 0.4)
    return 1.3 if added else pick(0.5, 0.2, 0.5, 0.4)


class Info(object):
    """Fiche d'un exercice (export `kmExerciseInfo` du banc Dart)."""

    def __init__(self, j, grid=None):
        self.id = j['id']
        self.mode = j['mode']  # 'loaded', 'reps', 'hold' ou None
        self.fraction = j['fraction']
        self.lower_body = j['lowerBody']
        self.groups = j['groups']
        self.group_weights = j['groupWeights']
        self.local_fatigue = j['localFatigue']
        self.systemic_fatigue = j['systemicFatigue']
        self.difficulty = j['difficulty']
        self.assisted = j['assisted']
        self.load_type = j['loadType']
        self.pattern = j['pattern']
        self.family = j['family']
        self.unit = j['unit']
        self.tendon_loaded = j['tendonLoaded']
        self.endurance_kind = j['enduranceKind']
        self.zone_levels = j['zoneLevels']
        self.pain_stop_hits = set(j['painStopHits'])
        self.grid = grid or LoadGrid(j['gridStep'], j['gridMinimum'], j['gridDumbbell'])

    def total_load(self, external, body_weight):
        return external + self.fraction * body_weight

    def zone_level(self, zone):
        return self.zone_levels.get(zone, 0.0)


class Spec(object):
    """Physiologie et comportement d'un athlète simulé (`AthleteSpec`)."""

    DEFAULTS = dict(
        ratingNoise=1.0, rirBias=0.25, rirBiasSd=0.18, lazy=0.1, skipRating=0.0,
        missRate=0.08, breakFromDay=None, breakDays=0, illnessFromDay=None,
        illnessDays=0, painZone=None, painFromDay=None, painDays=0,
        painIntensity=5, otherPlace=None, otherPlaceFromDay=None,
        otherPlaceDays=0, daySd=0.025, healthAnswerRate=0.7, shortTimeRate=0.05)

    def __init__(self, j):
        self.json = dict(j)
        self.key = j['key']
        self.level = j['level']
        self.weekly_gain = j['weeklyGain']
        d = dict(self.DEFAULTS)
        for k in d:
            if j.get(k) is not None:
                d[k] = j[k]
        self.rating_noise = d['ratingNoise']
        self.rir_bias = d['rirBias']
        self.rir_bias_sd = d['rirBiasSd']
        self.lazy = d['lazy']
        self.skip_rating = d['skipRating']
        self.miss_rate = d['missRate']
        self.break_from = d['breakFromDay']
        self.break_days = d['breakDays']
        self.illness_from = d['illnessFromDay']
        self.illness_days = d['illnessDays']
        self.pain_zone = d['painZone']
        self.pain_from = d['painFromDay']
        self.pain_days = d['painDays']
        self.pain_intensity = d['painIntensity']
        self.other_place = d['otherPlace']
        self.other_place_from = d['otherPlaceFromDay']
        self.other_place_days = d['otherPlaceDays']
        self.day_sd = d['daySd']
        self.health_answer_rate = d['healthAnswerRate']
        self.short_time_rate = d['shortTimeRate']


class TruthExercise(object):
    __slots__ = ('info', 'mode', 'capacity', 'start_capacity', 'curve_a', 'curve_b',
                 'fatigue_scale', 'hold_share', 'kind', 'slope', 'power', 'carry',
                 'day', 'set_fatigue', 'stimulus', 'last_day', 'last_load',
                 'session_load', 'sessions', 'first_day', 'first_capacity',
                 'last_capacity')

    def __init__(self, info, mode):
        self.info = info
        self.mode = mode
        self.capacity = 0.0
        self.start_capacity = 0.0
        self.curve_a = 0.3
        self.curve_b = 0.044
        self.fatigue_scale = 1.0
        self.hold_share = 0.1
        self.kind = 'a'
        self.slope = 0.0278
        self.power = 0.10
        self.carry = 0.5
        self.day = 0.0
        self.set_fatigue = []
        self.stimulus = 0.0
        self.last_day = None
        self.last_load = None
        self.session_load = None
        self.sessions = 0
        self.first_day = None
        self.first_capacity = 0.0
        self.last_capacity = 0.0

    def share(self, n):
        if self.kind == 'a':
            return self.curve_a + (1 - self.curve_a) * exp(-self.curve_b * (n - 1))
        if self.kind == 'b':
            v = 1 - self.slope * ((1 if n < 1 else n) - 1)
            return 0.3 if v < 0.3 else v
        return exp(-self.power * ln(1 if n < 1 else n))

    def reps_at_share(self, share):
        if share >= 1:
            return 1 - (share - 1) * 20
        if self.kind == 'a':
            if share <= self.curve_a + 1e-6:
                return 100.0
            n = 1 - ln((share - self.curve_a) / (1 - self.curve_a)) / self.curve_b
            return 100.0 if n > 100 else n
        if self.kind == 'b':
            n = 1 + (1 - share) / self.slope
            return 100.0 if n > 100 else n
        if share <= 0.05:
            return 100.0
        n = exp(-ln(share) / self.power)
        return 100.0 if n > 100 else n

    def fatigue_now(self):
        total = 0.0
        n = len(self.set_fatigue)
        lc = ln(self.carry)
        for i in range(n):
            total += self.set_fatigue[i] * exp((n - 1 - i) / 2 * lc)
        return 0.8 if total > 0.8 else total


class SetOutcome(object):
    __slots__ = ('amount', 'flames', 'true_rir', 'failed')

    def __init__(self, amount, flames, true_rir, failed):
        self.amount = amount
        self.flames = flames
        self.true_rir = true_rir
        self.failed = failed


class SimAthlete(object):
    """Athlète simulé (`SimAthlete`). [profile] : JSON du profil des moteurs
    (contrat de kalis_core) ; [book] : dictionnaire id -> Info."""

    def __init__(self, spec, profile, book, seed, kind='a', n_groups=N_GROUPS):
        self.spec = spec
        self.profile = profile
        self.book = book
        self.seed = seed
        self.kind = kind
        r = SimRandom.of(seed, 'athlete')
        bw = profile.get('bodyWeightKg')
        self.body_weight = 72.0 if bw is None else float(bw)
        self.sens_acute = 0.004 * exp(0.4 * r.gauss())
        self.sens_chronic = 0.0006 * exp(0.4 * r.gauss())
        draw = r.gauss()
        if kind == 'c':
            self.beta = clamp(LEVEL_BIAS[spec.level] + spec.rir_bias_sd * draw, -0.15, 0.8)
        else:
            self.beta = clamp(spec.rir_bias + spec.rir_bias_sd * draw, -0.15, 0.8)
        self.noise = spec.rating_noise * exp(0.15 * r.gauss())
        self.weeks_trained = WEEKS_TRAINED[spec.level]
        self._truth = {}
        self._acute = [0.0] * n_groups
        self._chronic = 0.0
        self._life = 0.0
        self._day = 0
        self._weeks = 0
        self.pain_until = -1
        self.pain_intensity = 0
        self.pain_aggravations = 0
        self._pain_known = False
        self._zone_week = {}
        self._zone_habit = {}
        self._zone_last_week = {}
        self._reactive_zone = None
        self._reactive_tolerance = 0.0
        self._reactive_until = -1
        self.pain_flares = 0
        self._fast = 0.0
        self._slow = 0.0
        self._last_heavy_day = None
        self._hold_week = 0.0
        self._tendon = None
        self._tendon_zone = None
        self._rating_offset = 0.0
        self._overuse_zone = None

    # ------------------------------------------------------------------
    @property
    def pain_zone(self):
        return self.spec.pain_zone or self._overuse_zone or self._tendon_zone

    @property
    def truths(self):
        return [t for t in self._truth.values() if t is not None]

    @property
    def day(self):
        return self._day

    def truth_of(self, ex_id):
        if ex_id in self._truth:
            return self._truth[ex_id]
        info = self.book.get(ex_id)
        mode = None if info is None else info.mode
        if info is None or mode is None:
            self._truth[ex_id] = None
            return None
        r = SimRandom.of(self.seed, 'truth|%s' % ex_id)
        t = TruthExercise(info, mode)
        declared = None
        for level in self.profile.get('movementLevels') or []:
            low = level.get('low')
            high = level.get('high')
            if level.get('exerciseId') != ex_id or not level.get('known') or low is None or high is None:
                continue
            wanted = 'one_rm_kg' if mode == 'loaded' else ('max_hold_seconds' if mode == 'hold' else 'max_reps')
            if level.get('measure') != wanted or low <= 0:
                continue
            center = math.sqrt(low * high)
            declared = info.total_load(center, self.body_weight) if mode == 'loaded' else center
        lower = info.lower_body
        female = self.profile.get('sex') == 'female'
        level_i = self.spec.level
        if mode == 'loaded':
            if declared is not None:
                t.capacity = declared * exp(0.08 * r.gauss())
            else:
                sex_factor = (0.75 if lower else 0.65) if female else 1.0
                total = ratio_of(info.pattern, info.load_type) * self.body_weight * LEVEL_SCALE[level_i] * sex_factor
                total *= exp(0.12 * r.gauss())
                t.capacity = total
            floor = info.fraction * self.body_weight * 1.15
            if t.capacity < floor:
                t.capacity = floor
            t.curve_b = (0.036 if lower else 0.044) * exp(0.20 * r.gauss())
            t.curve_a = clamp(0.30 + 0.04 * r.gauss(), 0.2, 0.4)
        elif mode == 'reps':
            if declared is not None:
                t.capacity = declared * exp(0.10 * r.gauss())
            else:
                margin = LEVEL_ABILITY[level_i] - info.difficulty
                t.capacity = clamp(12 * exp(margin * ln(1.35)) * exp(0.25 * r.gauss()), 2, 60)
        else:
            if declared is not None:
                t.capacity = declared * exp(0.10 * r.gauss())
            else:
                margin = LEVEL_ABILITY[level_i] - info.difficulty
                t.capacity = clamp(30 * exp(margin * ln(1.35)) * exp(0.25 * r.gauss()), 5, 180)
            t.hold_share = 0.1 * exp(0.2 * r.gauss())
        t.fatigue_scale = exp(0.35 * r.gauss())
        if self.kind != 'a':
            t.kind = self.kind
            t.slope = (0.0236 if lower else 0.0278) * exp(0.18 * r.gauss())
            t.power = (0.085 if lower else 0.10) * exp(0.2 * r.gauss())
            t.carry = 0.6 if self.kind == 'c' else 0.5
        t.start_capacity = t.capacity
        self._truth[ex_id] = t
        return t

    def advance(self, day):
        dt = day - self._day
        if dt <= 0:
            return
        r = SimRandom.of(self.seed, 'life|%d' % day)
        for _ in range(dt):
            self._life = 0.7 * self._life + self.spec.day_sd * 0.75 * 0.714 * r.gauss()
        ea = exp(-dt / 1.5)
        for i in range(len(self._acute)):
            self._acute[i] *= ea
        self._chronic *= exp(-dt / 6)
        if self.kind != 'a':
            self._fast *= exp(-dt / 7)
            self._slow *= exp(-dt / 28)
            self._rating_offset = 0.6 * r.gauss() if self.kind == 'c' else 0.0
        for t in self.truths:
            last = t.last_day
            if self.kind == 'c':
                if last is not None and day - last > 7:
                    over = dt if dt < day - last - 7 else day - last - 7
                    t.capacity *= exp(-0.0025 * over)
            elif last is not None and day - last > 21:
                over = dt if dt < day - last - 21 else day - last - 21
                t.capacity *= exp(-0.01 * over / 7)
        self._day = day
        pain_from = self.spec.pain_from
        if pain_from is not None and day >= pain_from and self.pain_until < 0:
            self.pain_until = pain_from + self.spec.pain_days
            self.pain_intensity = self.spec.pain_intensity
        if self.pain_until >= 0 and day > self.pain_until:
            zone = self.pain_zone
            if self.kind != 'a' and self.pain_intensity >= 3 and zone is not None:
                half = 0.5 * self._zone_habit.get(zone, 0.0)
                carried = self._zone_last_week.get(zone, 0.0)
                self._reactive_zone = zone
                self._reactive_until = day + 84
                self._reactive_tolerance = carried if carried > half else half
            self.pain_intensity = 0
            self._overuse_zone = None

    @property
    def ill(self):
        f = self.spec.illness_from
        return f is not None and self._day >= f and self._day < f + self.spec.illness_days

    @property
    def in_pain(self):
        return self.pain_intensity > 0 and self._day <= self.pain_until

    def overuse(self, zone, intensity, days):
        if self.in_pain or self.spec.pain_zone is not None:
            return
        self._overuse_zone = zone
        self.pain_intensity = intensity
        self.pain_until = self._day + days
        self._pain_known = False

    def _sharpness(self):
        if self.kind == 'a' or self._slow < 4:
            return 0.0
        ratio = (self._fast / 7) / (self._slow / 28)
        if self.kind == 'b':
            bonus = clamp(0.03 * (1 - ratio), -0.01, 0.025)
            heavy = self._last_heavy_day
            if heavy is not None and self._day - heavy > 10:
                late = (self._day - heavy - 10) / 10
                bonus -= 0.02 * (1 if late > 1 else late)
            return bonus
        return clamp(-0.02 * ln(0.25 if ratio < 0.25 else ratio), -0.015, 0.03)

    def global_readiness(self):
        r = self._life - self.sens_chronic * self._chronic
        if self.ill:
            r -= 0.08
        if self.kind != 'a':
            r += self._sharpness()
        return r

    def _readiness(self, info):
        a = 0.0
        total = 0.0
        for i in range(len(info.groups)):
            a += self._acute[info.groups[i]] * info.group_weights[i]
            total += info.group_weights[i]
        if total > 0:
            a /= total
        return self.global_readiness() - self.sens_acute * a

    def health_check(self, budget):
        """Bilan de santé du jour (dictionnaire au format du contrat) ou None."""
        r = SimRandom.of(self.seed, 'health|%d' % self._day)
        if r.next() > self.spec.health_answer_rate:
            return None
        readiness = self.global_readiness()
        overall = dart_round(4 + readiness / 0.02 + 0.7 * r.gauss())
        if overall < 1:
            overall = 1
        if overall > 5:
            overall = 5
        short = r.next() < self.spec.short_time_rate
        if overall > 2 and not short:
            return {'overall': overall}
        if self.in_pain and self.pain_zone is not None:
            self._pain_known = True
        out = {'overall': overall}
        if overall <= 2:
            out['sleepQuality'] = 2 if r.next() < 0.6 else 3
            out['energy'] = 2
        if short:
            out['minutesAvailable'] = dart_round(budget * 0.6)
        out['pains'] = []
        if self.in_pain and self.pain_zone is not None:
            out['pains'].append({'zone': self.pain_zone, 'side': 'both',
                                 'intensity': self.pain_intensity, 'phase': 'before'})
        return out

    def session_pains(self):
        zone = self.pain_zone
        if not self.in_pain or zone is None:
            return []
        self._pain_known = True
        return [{'zone': zone, 'side': 'both', 'intensity': self.pain_intensity, 'phase': 'during'}]

    def begin_exercise(self, t, slot_key):
        r = SimRandom.of(self.seed, 'day|%d|%s|%s' % (self._day, slot_key, t.info.id))
        if self.kind == 'a':
            t.day = self._readiness(t.info) + self.spec.day_sd * 0.66 * r.gauss()
        elif self.kind == 'b':
            t.day = self._readiness(t.info) + self.spec.day_sd * 1.3 * 0.66 * r.gauss()
        else:
            g = r.gauss()
            bad = r.next() < 0.1
            t.day = self._readiness(t.info) + self.spec.day_sd * 0.66 * g - (0.04 if bad else 0)
        t.set_fatigue = []
        t.session_load = None

    def end_exercise(self, t):
        load = t.session_load
        if load is not None:
            t.last_load = load
        if t.first_day is None:
            t.first_day = self._day
            t.first_capacity = t.capacity
        t.last_capacity = t.capacity
        t.sessions += 1

    def capacity_now(self, t, load):
        keep = 1 - t.fatigue_now()
        if t.mode == 'loaded':
            total = t.info.total_load(load or 0.0, self.body_weight)
            return t.reps_at_share(total / (t.capacity * exp(t.day))) * keep
        return t.capacity * exp(t.day) * keep

    @staticmethod
    def extended_top(high):
        a = high + (high + 2) // 3
        b = 30 if 2 * high > 30 else 2 * high
        return a if a > b else b

    def reachable(self, t, low, high, rir):
        fresh = t.capacity * exp(t.day)
        if t.mode == 'hold':
            seconds = fresh * (1 - t.hold_share * (6 if rir > 6 else rir))
            return seconds >= 0.7 * low and seconds <= 1.5 * high
        if t.mode == 'reps':
            reps = fresh - rir
            return reps >= low - 2 and reps <= self.extended_top(high)
        grid = t.info.grid
        top = self.extended_top(high)
        kg = grid.minimum
        for _ in range(2000):
            total = t.info.total_load(kg, self.body_weight)
            reps = (100.0 if total <= 0 else t.reps_at_share(total / fresh)) - rir
            if reps < low - 2:
                return False
            if reps <= top:
                return True
            nxt = grid.next(kg, True)
            if nxt <= kg:
                return False
            kg = nxt
        return False

    def self_select(self, t, reps, rir):
        r = SimRandom.of(self.seed, 'select|%s|%d' % (t.info.id, self._day))
        total = t.capacity * t.share(reps + rir + 2) * exp(0.15 * r.gauss())
        ext = total - t.info.fraction * self.body_weight
        grid = t.info.grid
        return grid.floor(grid.minimum if ext < grid.minimum else ext)

    def perform(self, t, load, low, high, flames_target, rest_seconds, noise_key):
        r = SimRandom.of(self.seed, 'set|%s' % noise_key)
        hold = t.mode == 'hold'
        capacity = self.capacity_now(t, load)

        def rir_after(amount):
            if hold:
                return 0.0 if capacity <= 0 else (1 - amount / capacity) / t.hold_share
            return capacity - amount

        def amount_at(rir):
            return capacity * (1 - t.hold_share * rir) if hold else capacity - rir

        long_ = 1.0 if hold else 1 + ((capacity - 12) / 12 if capacity > 12 else 0)
        bias = self.beta if hold else self.beta * (1 + ((capacity - 12) / 24 if capacity > 12 else 0))
        target_rir = flames_to_rir(flames_target)
        by_feel = high > low
        stop_rir = target_rir if by_feel else (0.5 if target_rir - 1.5 < 0.5 else target_rir - 1.5)
        stop_error = self.noise * (0.3 + 0.2 * stop_rir) * long_ * r.gauss()
        stop = amount_at(stop_rir * (1 + bias) - stop_error)
        wanted = dart_round(stop)
        if by_feel:
            if wanted < low:
                wanted = low
        elif wanted < 1:
            wanted = 1
        if wanted > high:
            wanted = high
        most = int(math.floor(capacity + 1e-9))
        failed = False
        if most < wanted:
            amount = 0 if most < 0 else most
            failed = True
            true_rir = rir_after(float(amount))
            if true_rir < 0:
                true_rir = 0.0
            flames = 10
        else:
            amount = wanted
            true_rir = rir_after(float(amount))
            perceived = true_rir / (1 + bias)
            capped = 6.0 if true_rir > 6 else true_rir
            if self.kind == 'a':
                perceived += self.noise * (0.3 + 0.2 * capped) * long_ * r.gauss()
            elif self.kind == 'b':
                perceived += self.noise * (0.5 + 0.25 * capped) * long_ * r.gauss()
                if r.next() < 0.08:
                    perceived += 2 if r.next() < 0.5 else -2
                perceived = float(dart_round(perceived))
                if perceived > 4:
                    perceived = 4.0
            else:
                perceived += self._rating_offset + self.noise * (0.3 + 0.2 * capped) * long_ * r.gauss()
            if perceived < 0:
                perceived = 0.0
            said = flames_from_rir(perceived)
            if said == 10 and true_rir >= 0.75:
                said = 9
            gap = abs(said - flames_target)
            q = self.spec.lazy * (1.0 if gap <= 2 else (0.5 if gap <= 4 else 0.25))
            if amount < low:
                q *= 0.5
            if r.next() < q:
                said = flames_target
            flames = None if r.next() < self.spec.skip_rating else said
        rir_capped = 8.0 if true_rir > 8 else true_rir
        if self.kind == 'a':
            base = 0.85 * exp(-rest_seconds / 160) * exp(-rir_capped / 1.4)
        elif self.kind == 'b':
            base = 0.8 / (1 + rest_seconds / 75) / (1 + rir_capped / 1.2)
        else:
            base = 0.7 * exp(-rest_seconds / 200) * exp(-rir_capped / 2)
        t.set_fatigue.append(base * t.fatigue_scale * exp(0.2 * r.gauss()))
        w = 1 - (6 if true_rir > 6 else true_rir) / 8
        if w < 0.3:
            w = 0.3
        if failed:
            w += 0.5
        info = t.info
        for i in range(len(info.groups)):
            self._acute[info.groups[i]] += w * info.group_weights[i] * info.local_fatigue / 3
        self._chronic += w * info.systemic_fatigue / 3
        heavy = True
        if t.mode == 'loaded':
            heavy = info.total_load(load or 0.0, self.body_weight) / t.capacity >= 0.5
        if self.kind == 'a':
            if amount > 0 and heavy:
                value = 1 - 0.1 * (true_rir - 2 if true_rir > 2 else 0)
                t.stimulus += 0.2 if value < 0.2 else value
        elif self.kind == 'b':
            if amount > 0:
                value = 1.0 if true_rir <= 4 else 0.6
                if t.mode == 'loaded':
                    part = info.total_load(load or 0.0, self.body_weight) / t.capacity
                    value = 1.5 if part >= 0.85 else (1.0 if part >= 0.7 else (0.6 if part >= 0.5 else 0.2))
                    if part >= 0.85:
                        self._last_heavy_day = self._day
                t.stimulus += value
        else:
            if amount > 0 and heavy:
                value = 1 - 0.15 * (true_rir - 3 if true_rir > 3 else 0)
                t.stimulus += 0.3 if value < 0.3 else value
        if self.kind != 'a' and amount > 0:
            self._fast += w
            self._slow += w
            if info.tendon_loaded:
                self._hold_week += amount
            for zone in TENDON_ZONES:
                if zone in info.pain_stop_hits:
                    self._zone_week[zone] = self._zone_week.get(zone, 0.0) + 1
        t.last_day = self._day
        if load is not None:
            before = t.session_load
            if before is None or load > before:
                t.session_load = load
            zone = self.pain_zone
            last = t.last_load
            if (self.in_pain and self.pain_intensity > 3 and self._pain_known and zone is not None
                    and last is not None and load > last + 1e-9
                    and info.zone_level(zone) >= 0.5 and before is None):
                self.pain_aggravations += 1
                self.pain_until += 7
                if self.pain_intensity < 8:
                    self.pain_intensity += 1
        return SetOutcome(amount, flames, true_rir, failed)

    def _reactive_week(self):
        zone = self._reactive_zone
        if zone is not None and self._day > self._reactive_until:
            self._reactive_zone = None
        reactive = self._reactive_zone
        for z in TENDON_ZONES:
            week = self._zone_week.get(z, 0.0)
            if z == reactive:
                tolerance = 4.0 if self._reactive_tolerance < 4 else self._reactive_tolerance
                if not self.in_pain and week > 1.5 * tolerance:
                    self.pain_flares += 1
                    self.pain_intensity = 3 if week > 2 * tolerance else 2
                    self.pain_until = self._day + 6
                    self._pain_known = False
                elif not self.in_pain and week > self._reactive_tolerance:
                    self._reactive_tolerance += (week - self._reactive_tolerance) / 2
            elif not self.in_pain or self.pain_zone != z:
                habit = self._zone_habit.get(z)
                self._zone_habit[z] = week if habit is None else habit + (week - habit) / 4
            self._zone_last_week[z] = week
            self._zone_week[z] = 0.0

    def end_week(self):
        self._weeks += 1
        if self.kind != 'a':
            self._reactive_week()
        over = (self._chronic - 14 if self._chronic > 14 else 0) / 14
        rate = self.spec.weekly_gain / (1 + self._weeks / 40)
        if self.kind != 'a':
            tolerance = self._tendon
            if tolerance is None:
                if self._hold_week > 0:
                    self._tendon = self._hold_week
            else:
                if (self.kind == 'b' and self._hold_week > 1.3 * tolerance + 10
                        and self.spec.pain_zone is None and not self.in_pain):
                    self._tendon_zone = 'wrist_hand'
                    self.pain_intensity = 4
                    self.pain_until = self._day + 10
                self._tendon = tolerance + (self._hold_week - tolerance) / 6
            self._hold_week = 0.0
        for t in self.truths:
            s = t.stimulus
            if self.kind == 'a':
                dose = 0.0 if s <= 0 else s / (s + 3) / (6 / 9)
                if dose > 1.3:
                    dose = 1.3
                fast = 1.0 if t.mode == 'loaded' else 2.0
            elif self.kind == 'b':
                dose = 0.0 if s <= 0 else ln(1 + s) / ln(9)
                if dose > 1.25:
                    dose = 1.25
                fast = 1.0 if t.mode == 'loaded' else (1.2 if t.info.tendon_loaded else 2.0)
            else:
                dose = 0.0 if s <= 0 else (1 - exp(-s / 5)) / (1 - exp(-6 / 5))
                if dose > 1.2:
                    dose = 1.2
                fast = 1.0 if t.mode == 'loaded' else (1.2 if t.info.tendon_loaded else 1.8)
            keep = 1 - 0.5 * over
            if keep < 0.2:
                keep = 0.2
            t.capacity *= exp(rate * fast * dose * keep)
            t.stimulus = 0.0

    @staticmethod
    def quality_of(outcome):
        if outcome.failed:
            return 2
        rir = outcome.true_rir
        return 5 if rir >= 2 else (4 if rir >= 1 else (3 if rir >= 0.3 else 2))

    def perform_eccentric(self, t, load, low, high, flames_target, rest_seconds, noise_key):
        before = t.day
        t.day = before + ln(1.3)
        outcome = self.perform(t, load, low, high, flames_target, rest_seconds, noise_key)
        t.day = before
        return outcome


# ----------------------------------------------------------------------
# Grilles de charge du profil (`LoadGrid.of`) et carnet d'exercices
# ----------------------------------------------------------------------
LOAD_TYPE_CODES = {
    'barre': 'barbell', 'halteres': 'dumbbells', 'machine': 'machine',
    'poulie': 'cable', 'kettlebell': 'kettlebell', 'lest': 'addedWeight',
    'poids_du_corps': 'bodyweight', 'elastique': 'band', 'aucune': 'none',
    'autre': 'other',
}
POUND_KG = 0.45359237


def _default_minimum(t):
    return {'barbell': 20.0, 'dumbbells': 1.0, 'machine': 5.0, 'kettlebell': 4.0,
            'cable': 2.5 * POUND_KG}.get(t, 0.0)


def grid_of(load_type, profile):
    if profile is not None:
        for inc in profile.get('loadIncrements') or []:
            if LOAD_TYPE_CODES.get(inc.get('loadType'), inc.get('loadType')) == load_type:
                least = inc.get('minKg')
                return LoadGrid(inc['stepKg'], _default_minimum(load_type) if least is None else least, False)
    if load_type == 'dumbbells':
        return LoadGrid(1.0, 1.0, True)
    if load_type == 'barbell':
        return LoadGrid(2.5, 20.0, False)
    if load_type == 'cable':
        return LoadGrid(2.5 * POUND_KG, 2.5 * POUND_KG, False)
    if load_type == 'machine':
        return LoadGrid(5.0, 5.0, False)
    if load_type == 'kettlebell':
        return LoadGrid(4.0, 4.0, False)
    if load_type == 'addedWeight':
        return LoadGrid(1.25, 0.0, False)
    return LoadGrid(1.0, 0.0, False)


def make_book(catalog_infos, profile):
    """Carnet id -> Info pour un profil (`ExerciseBook`), grilles du profil."""
    book = {}
    for j in catalog_infos:
        g = grid_of(j['loadType'], profile)
        if not j['fraction'] > 0 and not g.minimum > 0:
            g = LoadGrid(g.step, g.step, g.dumbbell)
        book[j['id']] = Info(j, g)
    return book
