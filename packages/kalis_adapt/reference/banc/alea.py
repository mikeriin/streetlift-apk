# -*- coding: utf-8 -*-
"""Générateur seedé du banc (mulberry32 et FNV-1a), identique à
`kalis_adapt/lib/src/sim/rng.dart` et `kalis_plan/lib/src/hash.dart`."""
import math

M32 = 0xFFFFFFFF


def fnv1a32(text):
    h = 0x811C9DC5
    for byte in text.encode('utf-8'):
        h ^= byte
        h = (h * 0x01000193) & M32
    return h


def fnv_mix(h, value):
    h &= M32
    v = value & M32
    for _ in range(4):
        h ^= v & 0xFF
        h = (h * 0x01000193) & M32
        v >>= 8
    return h


class SimRandom(object):
    """mulberry32 ; `SimRandom.of(seed, key)` donne un flux par clé."""

    __slots__ = ('state',)

    def __init__(self, seed):
        self.state = seed & M32

    @staticmethod
    def of(seed, key):
        return SimRandom(fnv_mix(fnv1a32(key), seed))

    def next(self):
        self.state = (self.state + 0x6D2B79F5) & M32
        t = self.state
        t = ((t ^ (t >> 15)) * (t | 1)) & M32
        t ^= (t + (((t ^ (t >> 7)) * (t | 61)) & M32)) & M32
        return ((t ^ (t >> 14)) & M32) / 4294967296.0

    def gauss(self):
        for _ in range(64):
            u = 2 * self.next() - 1
            v = 2 * self.next() - 1
            s = u * u + v * v
            if 1e-12 < s < 1:
                return u * math.sqrt(-2 * math.log(s) / s)
        return 0.0


def dart_round(x):
    """Arrondi de Dart : au plus proche, demi s'éloignant de zéro."""
    return int(math.floor(x + 0.5)) if x >= 0 else -int(math.floor(-x + 0.5))


def flames_to_rir(flames):
    return 0.0 if flames == 10 else (11 - flames) / 2.0


def flames_from_rir(rir):
    if rir >= 5:
        return 1
    halves = math.ceil(rir * 2 - 0.5)
    if halves <= 0:
        return 10
    if halves == 1:
        return 9
    return 11 - halves


def clamp(x, low, high):
    return low if x < low else (high if x > high else x)


class LoadGrid(object):
    """Grille de charges (`kalis_adapt/lib/src/grid.dart`)."""

    EPS = 1e-9
    KNEE = 10.0
    LARGE = 2.0

    def __init__(self, step, minimum, dumbbell):
        self.step = step
        self.minimum = minimum
        self.dumbbell = dumbbell

    def step_above(self, kg):
        if self.dumbbell:
            return self.step if kg < self.KNEE - self.EPS else self.LARGE
        return self.step

    def floor(self, kg):
        if self.dumbbell and kg > self.KNEE + self.EPS:
            value = self.KNEE + math.floor((kg - self.KNEE) / self.LARGE + self.EPS) * self.LARGE
        elif kg <= self.minimum:
            value = self.minimum
        else:
            value = self.minimum + math.floor((kg - self.minimum) / self.step + self.EPS) * self.step
        return self.minimum if value < self.minimum else value

    def next(self, kg, up):
        base = self.floor(kg)
        if up:
            if base > kg + self.EPS:
                return base
            return base + self.step_above(base)
        if base < kg - self.EPS:
            return base
        if self.dumbbell:
            down = self.step if base <= self.KNEE + self.EPS else self.LARGE
        else:
            down = self.step
        value = base - down
        return self.minimum if value < self.minimum else value

    def nearest(self, kg):
        low = self.floor(kg)
        high = self.next(low, True)
        return low if (kg - low) <= (high - kg) else high
