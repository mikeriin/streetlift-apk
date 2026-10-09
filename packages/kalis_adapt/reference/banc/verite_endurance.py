# -*- coding: utf-8 -*-
"""Portage Python du modèle de vérité d'endurance et de conditionnement du
banc (`kalis_adapt/lib/src/sim/endurance_truth.dart`, 0.3.1). Vérifié par
`tests/test_verite.py` contre `donnees/traces_endurance.json.gz`."""
import math

from .alea import SimRandom, clamp, dart_round, flames_to_rir, flames_from_rir

QUALITY_RUN_IDS = ['fractionne', 'seuil', 'tempo', '30-30', 'sprint', 'cotes',
                   'fartlek', 'intervalles', 'navettes', 'accelerations']


def prescribed_seconds(item, sets, speed):
    s = item.get('secondsHigh')
    if s is None:
        s = item.get('secondsLow')
    if s is not None:
        return float(s * sets)
    m = item.get('distanceMeters')
    if m is not None and speed > 0:
        return m * sets / speed
    return 0.0


def flames_of_rir(rir):
    return flames_from_rir(0.0 if rir < 0 else rir)


class EnduranceTruth(object):
    def __init__(self, kind, level, seed):
        self.kind = kind
        self.level = level
        self.seed = seed
        r = SimRandom.of(seed, 'endurance')
        base = [30.0, 70.0, 100.0, 130.0]
        lv = int(clamp(level, 0, 3))
        self.easy_minutes = base[lv] * math.exp(0.2 * r.gauss())
        self.start_easy_minutes = self.easy_minutes
        self.wod = math.exp(0.15 * r.gauss())
        self.start_wod = self.wod
        self.speed = (2.4 + 0.35 * lv) * math.exp(0.06 * r.gauss())
        self.start_speed = self.speed
        self.run_seconds = {}
        self.hard_wod_days = set()
        self.overuse = 0
        self.worst_spike = 0.0
        self._week_dose = 0.0
        self._week_start = 0

    def _longest(self, day):
        longest = 0.0
        count = 0
        for k, v in self.run_seconds.items():
            if k < day and k >= day - 30:
                count += 1
                if v > longest:
                    longest = v
        return longest, count

    def _week_run(self, frm, to):
        s = 0.0
        for k in sorted(self.run_seconds):
            if frm <= k < to:
                s += self.run_seconds[k]
        return s

    def end_day(self, day):
        if day - self._week_start >= 7:
            dose = self._week_dose / 60
            ratio = dose / (self.easy_minutes * 3)
            if self.kind == 'a':
                gain = 0.035 * (1 - math.exp(-ratio))
            else:
                gain = 0.02 * math.log(1 + ratio)
            ceiling = self.start_easy_minutes * (2.5 - 0.3 * self.level)
            if self.easy_minutes < ceiling:
                self.easy_minutes *= 1 + gain
            self.speed *= 1 + gain * 0.25
            if dose < 1e-9:
                self.easy_minutes *= 0.97
            self._week_dose = 0.0
            self._week_start = day

    def run(self, item, sets, day, readiness, ill, rates):
        r = SimRandom.of(self.seed, 'run|%d|%s' % (day, item['exerciseId']))
        written = prescribed_seconds(item, sets, self.speed)
        f0 = item.get('targetFlames')
        quality = ((f0 is not None and flames_to_rir(f0) <= 3 + 1e-9)
                   or item.get('intensity') is not None
                   or any(q in item['exerciseId'] for q in QUALITY_RUN_IDS))
        cap = self.easy_minutes * 60 * math.exp(readiness * 3 + (-0.4 if ill else 0))
        load = written * (2.0 if quality else 1.0) / (cap * (1.6 if quality else 1.0))
        done_share = 1.0
        if load > 1.35:
            done_share = 1.35 / load
        target_rir = 5.0 if f0 is None else flames_to_rir(f0)
        rir = target_rir - 4 * (load - 0.8) + 0.6 * r.gauss()
        if self.kind != 'a':
            rir -= 0.5
        if rir < 0:
            rir = 0.0
        flames = flames_of_rir(rir)
        if self.kind != 'a':
            flames = int(clamp(flames, 2, 9))
        done_s = written * done_share
        longest, count = self._longest(day)
        injured = None
        if count >= 3 and longest > 0 and written > 0:
            spike = done_s / longest
            if spike > self.worst_spike:
                self.worst_spike = spike
            risk = 0.003
            if spike > 2.0:
                risk *= 2.28
            elif spike > 1.3:
                risk *= 1.52
            elif spike > 1.1:
                risk *= 1.64
            if self.kind != 'a':
                week = self._week_run(day - 6, day) + done_s
                before = self._week_run(day - 20, day - 6) / 2
                if before > 0 and week > 1.3 * before:
                    risk *= 1.5
            if r.next() < risk:
                injured = 'knee' if r.next() < 0.5 else 'ankle_foot'
                self.overuse += 1
        self.run_seconds[day] = self.run_seconds.get(day, 0.0) + done_s
        self._week_dose += done_s * 1.5 if quality else done_s
        per_set = 0.0 if sets <= 0 else done_s / sets
        distance = item.get('distanceMeters')
        done = {
            'sets': sets,
            'seconds': dart_round(per_set),
            'distanceMeters': None if distance is None else dart_round(distance * done_share / 10) * 10.0,
            'reps': None,
            'calories': None,
            'flames': flames if rates else None,
            'success': done_share >= 0.999,
        }
        return done, injured

    def wod_piece(self, item, sets, day, readiness, ill, rates, hard_days_before, written_share=1.0):
        r = SimRandom.of(self.seed, 'wod|%d|%s' % (day, item['exerciseId']))
        form = self.wod * math.exp(readiness * 2 + (-0.3 if ill else 0))
        if hard_days_before >= 2:
            form *= 0.95 if self.kind == 'a' else 0.9
        ratio = written_share / form
        f0 = item.get('targetFlames')
        target_rir = 2.0 if f0 is None else flames_to_rir(f0)
        rir = target_rir - 4 * (ratio - 1) + 0.6 * r.gauss()
        if rir < 0:
            rir = 0.0
        share = 1.25 / ratio if ratio > 1.25 else 1.0
        flames = flames_of_rir(rir)
        if flames >= 8:
            self.hard_wod_days.add(day)
        injured = None
        risk = 0.002
        if hard_days_before >= 2:
            risk *= 2
        if ratio > 1.15:
            risk *= 1.5
        if r.next() < risk:
            injured = 'shoulder' if r.next() < 0.52 else 'lower_back'
            self.overuse += 1
        self.wod *= 1 + (0.004 if self.kind == 'a' else 0.003)
        reps = item.get('repsHigh')
        if reps is None:
            reps = item.get('repsLow')
        seconds = item.get('secondsHigh')
        if seconds is None:
            seconds = item.get('secondsLow')
        distance = item.get('distanceMeters')
        cal = item.get('calories')
        done = {
            'sets': sets,
            'reps': None if reps is None else int(math.floor(reps * share)),
            'seconds': dart_round(seconds * share) if (reps is None and seconds is not None) else None,
            'distanceMeters': distance if (reps is None and seconds is None) else None,
            'calories': float(math.floor(cal * share)) if (reps is None and seconds is None and distance is None and cal is not None) else None,
            'flames': flames if rates else None,
            'success': share >= 0.999,
        }
        return done, injured

    def hard_streak_before(self, day):
        n = 0
        rest = 0
        d = day - 1
        while d >= day - 7:
            if d in self.hard_wod_days:
                n += 1
                rest = 0
            else:
                rest += 1
                if rest > 1:
                    break
            d -= 1
        return n

    def seconds_by_week(self):
        out = {}
        for k, v in self.run_seconds.items():
            w = k // 7
            out[w] = out.get(w, 0.0) + v
        return out
