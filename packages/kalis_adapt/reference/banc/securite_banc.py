# -*- coding: utf-8 -*-
"""Portage Python des « critères de sécurité calculables » du banc Dart.

Source (le code fait foi) :

- `kalis_bench/lib/src/safety.dart` : `safetyFindings`, `rampLimit`,
  `SafetyLimits`, `isHighRisk`, `isModerateRisk`, `heavyImpactPatterns` ;
- `kalis_bench/lib/src/analysis.dart` : `ProgramView`, `WeekView`, `DayView`,
  `ItemView` (séries dures, crédits par groupe, charge totale, tenues bras
  tendus, durées estimées) ;
- `kalis_bench/lib/src/season.dart` : `servedBlocksOf`, `realizedFindings` ;
- `kalis_plan/lib/src/traits.dart` : groupes musculaires, crédits, nature
  « renforcement », impact (lus dans les fiches exportées par
  `kmExerciseInfo`, `kalis_bench/lib/src/km/km_export.dart`).

Entrées :

- `blocs` : liste de `ProgramBlock` JSON (pass1/pass2), dans l'ordre servi ;
- `bench_json` : profil du banc du scénario (`benchJson` des saisons
  exportées) ;
- `profil_json` : profil des moteurs (`profiles[0].profile`), dont seul le
  poids de corps est lu (comme `ProgramView`) ;
- `infos` : fiches d'exercice exportées par le Dart, dictionnaire id → fiche
  (ou liste de fiches) ; il doit couvrir tout le catalogue pour le critère
  `exercice_non_acquis` (le Dart teste `catalog.contains`) ;
- `horizon_semaines` : semaines lues (`horizonWeeks`).

Python pur (bibliothèque standard), déterministe. Les constats ont la forme
de `Finding.toJson()` côté Dart (valeurs arrondies au millième), avec toutes
les clés présentes (`None` quand le Dart omet la clé).
"""
import math
from decimal import Decimal, ROUND_HALF_UP

# ---------------------------------------------------------------------------
# Constantes (safety.dart, analysis.dart, traits.dart)
# ---------------------------------------------------------------------------

#: Groupes musculaires de `kalis_plan` (`MuscleGroup.values`, dans l'ordre) :
#: (index, code, majeur). Remplacé par la clé `groups` de l'export du
#: catalogue quand elle est fournie (`groupes=`).
GROUPES = [
    (0, 'chest', True),
    (1, 'delt_anterior', True),
    (2, 'delt_middle', True),
    (3, 'delt_posterior', True),
    (4, 'lats', True),
    (5, 'upper_back', True),
    (6, 'biceps', True),
    (7, 'triceps', True),
    (8, 'abs', True),
    (9, 'lower_back', True),
    (10, 'glutes', True),
    (11, 'quads', True),
    (12, 'hamstrings', True),
    (13, 'calves', True),
    (14, 'forearms', False),
    (15, 'adductors', False),
    (16, 'upper_traps', False),
]

LIBELLE_GROUPE = {
    'chest': 'pectoraux',
    'delt_anterior': 'deltoïde antérieur',
    'delt_middle': 'deltoïde moyen',
    'delt_posterior': 'deltoïde postérieur',
    'lats': 'grand dorsal',
    'upper_back': 'haut du dos',
    'biceps': 'biceps',
    'triceps': 'triceps',
    'abs': 'abdominaux',
    'lower_back': 'lombaires',
    'glutes': 'fessiers',
    'quads': 'quadriceps',
    'hamstrings': 'ischio-jambiers',
    'calves': 'mollets',
    'forearms': 'avant-bras',
    'adductors': 'adducteurs',
    'upper_traps': 'trapèzes supérieurs',
}

#: Articulations (code de `Joint`) et leur nom français (`jointLabel`).
LIBELLE_ARTICULATION = {
    'epaule': 'épaule',
    'coude': 'coude',
    'poignet': 'poignet',
    'lombaires': 'lombaires',
    'genou': 'genou',
    'hanche': 'hanche',
    'cheville': 'cheville',
}

#: Zone du corps → articulation du catalogue (`jointOfZone`, profile.dart).
ARTICULATION_DE_ZONE = {
    'shoulder': 'epaule',
    'elbow': 'coude',
    'wrist_hand': 'poignet',
    'lower_back': 'lombaires',
    'knee': 'genou',
    'hip': 'hanche',
    'ankle_foot': 'cheville',
}

#: Niveaux du banc (`BenchLevel`) : codes et noms français.
NIVEAUX = ['beginner', 'intermediate', 'advanced', 'elite']
LIBELLE_NIVEAU = ['débutant', 'intermédiaire', 'avancé', 'élite']

#: Codes JSON des niveaux d'exercice du catalogue (`ExerciseLevel.code`).
CODE_NIVEAU_EXERCICE = ['Débutant', 'Intermédiaire', 'Avancé', 'Élite']

#: Familles bras tendus (`StraightArmFamily`), dans l'ordre de l'enum.
FAMILLES_BRAS_TENDUS = ['push', 'pull', 'mixed']
LIBELLE_FAMILLE = {
    'push': 'poussée, type planche et back lever',
    'pull': 'tirage, type front lever',
    'mixed': 'mixtes, type drapeau',
}

# analysis.dart
POIDS_DEFAUT_KG = 75.0
SECONDES_PAR_REP = 3.0
SECONDES_TRANSITION = 45.0
ALLURE_DEFAUT = 2.5
PART_ALLURE = 0.9
RIR_MAX_SERIE_DURE = 4.0

# safety.dart, SafetyLimits
LOAD_RISE = [0.10, 0.05, 0.05, 0.05]
VOLUME_RISE = 0.20
VOLUME_RISE_SETS = 2.0
VOLUME_RISE_TWO_WEEKS = 0.30
VOLUME_RISE_TWO_WEEKS_SETS = 4.0
RAMP_SHARE = 0.5
WEEKLY_CEILING = [12.0, 20.0, 25.0, 30.0]
ELITE_GROUPS_ABOVE_ADVANCED = 2
STRAIGHT_ARM_DAYS = [2, 3, 3, 4]
STRAIGHT_ARM_RISE = [0.20, 0.15, 0.10, 0.10]
STRAIGHT_ARM_RISE_SECONDS = 5.0
LEVER_WEEKS = [12, 8, 8, 6]
WEEKS_WITHOUT_RELIEF = [12, 7, 6, 6]
RELIEF_SHARE = 0.70
TAPER_DROP = [0.30, 0.30, 0.40, 0.40]
SESSION_TOLERANCE = 0.15
BREAK_WEEKS = 2
RESUME_MIN_RIR = 3.0
DISCOMFORT_HIGH = 4
DISCOMFORT_MODERATE = 6
HIGH_RISK_MIN_RIR = 2.0
IMPACT_BMI = 30.0
IMPACT_AGE = 65
BENCH_START_YEAR = 2026

TECHNIQUE_MIN_LEVEL = {
    'top_set_backoff': 1,
    'drop_set': 1,
    'amrap': 1,
    'cluster': 2,
    'rest_pause': 2,
    'myo_reps': 2,
    'accentuated_eccentric': 2,
    'contrast': 2,
    'wave': 2,
}

TECHNIQUE_EXERCISE_MIN_LEVEL = [
    ('supramaximal', 2),
    ('partielle-haute', 2),
    ('partiel-haut', 2),
    ('partiel-surcharge', 2),
    ('isometrie-lestee', 2),
    ('chaines', 1),
]

#: Schémas à risque élevé (`isHighRisk`, noms Dart de `MovementPattern`).
SCHEMAS_RISQUE_ELEVE = {
    'equilibreMains', 'transitionMuscleUp', 'figureStatiquePoussee',
    'figureStatiqueTirage', 'figureStatiqueMixte', 'figureDynamiquePoussee',
    'figureDynamiqueTirage', 'freestyle', 'halterophilie',
}

#: `heavyImpactPatterns`.
SCHEMAS_IMPACT_LOURD = {'pliometrie', 'cordeASauter', 'balistique', 'halterophilie'}

#: Schémas et mode de contraction à impact (`ExerciseTraits.impact`).
SCHEMAS_IMPACT = {'pliometrie', 'sprint', 'halterophilie', 'cordeASauter'}

#: Natures `SlotKind` de renforcement (`SlotKind.isResistance`).
NATURES_RENFORCEMENT = {'compound', 'accessory', 'core', 'power', 'skillStatic', 'skillDynamic'}

#: Champs de fiche que seul l'export Dart complété (lot KM1) fournit.
CHAMPS_REQUIS = ('name', 'resistance', 'groupCredits', 'rootId', 'level', 'laterality',
                 'jointStress', 'prerequisites', 'bodyweightFraction', 'impact')

EPS = 1e-9


# ---------------------------------------------------------------------------
# Arrondis et formats de Dart
# ---------------------------------------------------------------------------

def arrondi_dart(x):
    """`double.round()` de Dart : au plus proche, égalité loin de zéro."""
    if x >= 0:
        r = math.floor(x)
        return int(r + 1) if x - r >= 0.5 else int(r)
    return -arrondi_dart(-x)


def fixe(x, n):
    """`double.toStringAsFixed(n)` de Dart (valeur binaire exacte, égalité
    vers le haut en valeur absolue)."""
    q = Decimal(1).scaleb(-n)
    d = Decimal(float(x)).quantize(q, rounding=ROUND_HALF_UP)
    s = format(d, 'f')
    if s.startswith('-') and float(d) == 0.0:
        s = s[1:]
    return s


def _milliemes(v):
    """`_round` de `Finding.toJson` : `(v * 1000).roundToDouble() / 1000`."""
    if v is None:
        return None
    return arrondi_dart(v * 1000) / 1000.0


def _constat(code, message, week=None, day_index=None, exercise_id=None, value=None, limit=None):
    return {
        'code': code,
        'message': message,
        'week': week,
        'dayIndex': day_index,
        'exerciseId': exercise_id,
        'value': _milliemes(None if value is None else float(value)),
        'limit': _milliemes(None if limit is None else float(limit)),
    }


def flammes_vers_rir(f):
    """`Flames.toRir`."""
    if f < 1 or f > 10:
        raise ValueError('flammes attendues de 1 à 10 : %r' % (f,))
    return 0.0 if f == 10 else (11 - f) / 2.0


# ---------------------------------------------------------------------------
# Fiches d'exercice
# ---------------------------------------------------------------------------

def indexer_infos(infos):
    """Dictionnaire id → fiche, depuis un dictionnaire ou une liste."""
    if isinstance(infos, dict):
        if 'exercises' in infos and isinstance(infos['exercises'], list):
            return {f['id']: f for f in infos['exercises']}
        return infos
    return {f['id']: f for f in infos}


def fiches_completes(infos):
    """Vrai si les fiches portent les champs ajoutés au lot KM1."""
    idx = indexer_infos(infos)
    if not idx:
        return False
    for f in idx.values():
        for c in CHAMPS_REQUIS:
            if c not in f:
                return False
    return True


def groupes_de(catalogue):
    """Groupes (index, code, majeur) de l'export du catalogue (`groups`),
    sinon la table de `kalis_plan` recopiée ici."""
    if isinstance(catalogue, dict) and catalogue.get('groups'):
        return [(g['index'], g['code'], bool(g['major'])) for g in catalogue['groups']]
    return list(GROUPES)


def credits_de(fiche, n_groupes=17):
    """Crédits par groupe, en demi-séries (`ExerciseTraits.groupCredits`) ;
    à défaut, reconstruits depuis `groups`/`groupWeights` (crédit/2)."""
    c = fiche.get('groupCredits')
    if c is not None:
        return list(c)
    out = [0] * n_groupes
    for g, w in zip(fiche.get('groups') or [], fiche.get('groupWeights') or []):
        out[g] = int(round(w * 2))
    return out


def est_renforcement(fiche):
    """`traits.kind.isResistance`."""
    r = fiche.get('resistance')
    if r is not None:
        return bool(r)
    k = fiche.get('slotKind')
    if k is None:
        raise KeyError('fiche %s : champ `resistance` absent (export Dart à compléter)' % fiche.get('id'))
    return k in NATURES_RENFORCEMENT


def risque_eleve_calcule(fiche):
    """`isHighRisk` recalculé depuis les champs de la fiche."""
    if fiche['pattern'] in SCHEMAS_RISQUE_ELEVE:
        return True
    if 'anneaux' in (fiche.get('equipment') or []) and fiche['family'] == 'poussee':
        return True
    return fiche['loadType'] == 'barbell' and fiche['pattern'] in (
        'squat', 'pousseeHorizontale', 'pousseeInclinee')


def risque_modere_calcule(fiche):
    """`isModerateRisk` recalculé depuis les champs de la fiche."""
    if risque_eleve_calcule(fiche):
        return False
    return (fiche['pattern'] == 'tirageVertical'
            or fiche['pattern'] == 'pousseeVerticaleBasse'
            or fiche['loadType'] == 'addedWeight'
            or (fiche['loadType'] == 'barbell' and fiche.get('articularity') == 'multiJoint'))


def risque_eleve(fiche):
    v = fiche.get('highRisk')
    return bool(v) if v is not None else risque_eleve_calcule(fiche)


def risque_modere(fiche):
    v = fiche.get('moderateRisk')
    return bool(v) if v is not None else risque_modere_calcule(fiche)


def impact_calcule(fiche):
    """`ExerciseTraits.impact` recalculé."""
    return fiche['pattern'] in SCHEMAS_IMPACT or fiche.get('contractionMode') == 'explosive'


def famille_bras_tendus_calculee(fiche):
    """`ItemView.straightArm` recalculé : 'push', 'pull', 'mixed' ou None."""
    root = fiche.get('rootId') or fiche['id']
    eid = fiche['id']
    if root.startswith('cs-back-lever') or eid.startswith('cs-back-lever'):
        return 'push'
    if root.startswith('cs-tenue-menton') or eid.startswith('cs-tenue-menton'):
        return None
    return {
        'figureStatiquePoussee': 'push',
        'figureStatiqueTirage': 'pull',
        'figureStatiqueMixte': 'mixed',
    }.get(fiche['pattern'])


def famille_bras_tendus(fiche):
    if 'straightArm' in fiche:
        return fiche['straightArm']
    return famille_bras_tendus_calculee(fiche)


def contrainte(fiche, articulation):
    """`CatalogExercise.stressOn` : 'low', 'moderate' ou 'high'."""
    return fiche['jointStress'][articulation]


# ---------------------------------------------------------------------------
# Lecture du programme (ProgramView)
# ---------------------------------------------------------------------------

def blocs_servis(blocs, block_weeks=None):
    """`servedBlocksOf` : un bloc interrompu (re-planification) est réduit à
    ses semaines servies, d'après `block_weeks` (semaine de début de chaque
    bloc dans la saison)."""
    if not block_weeks:
        return list(blocs)
    out = []
    for k, b in enumerate(blocs):
        if k + 1 < len(block_weeks):
            servi = block_weeks[k + 1] - block_weeks[k]
            semaines = b['pass2']['weeks']
            if 1 <= servi < len(semaines):
                p1 = dict(b['pass1'])
                p1['weeks'] = servi
                p2 = dict(b['pass2'])
                p2['weeks'] = semaines[:servi]
                nb = dict(b)
                nb['pass1'] = p1
                nb['pass2'] = p2
                out.append(nb)
                continue
        out.append(b)
    return out


def allure_course(bench_json):
    """`runSpeedOf` : meilleure allure chronométrée × 0,9, sinon 2,5 m/s."""
    best = 0.0
    for r in bench_json.get('records') or []:
        m = r.get('distanceMeters')
        v = float(r['value'])
        if r['measure'] == 'time_seconds' and m is not None and v > 0:
            s = float(m) / v
            if s > best:
                best = s
    return best * PART_ALLURE if best > 0 else ALLURE_DEFAUT


class Item(object):
    """Exercice prescrit lu avec sa fiche (`ItemView`)."""

    __slots__ = ('week', 'kind', 'day_index', 'p', 'fiche', 'poids', 'allure', 'renfo', 'credits')

    def __init__(self, week, kind, day_index, p, fiche, poids, allure):
        self.week = week
        self.kind = kind
        self.day_index = day_index
        self.p = p
        self.fiche = fiche
        self.poids = poids
        self.allure = allure
        self.renfo = est_renforcement(fiche)
        self.credits = credits_de(fiche)

    @property
    def exercise_id(self):
        return self.p['exerciseId']

    @property
    def nom(self):
        return self.fiche.get('name') or self.p['exerciseId']

    @property
    def est_temps(self):
        return self.p.get('secondsLow') is not None or self.p.get('secondsHigh') is not None

    @property
    def est_reps(self):
        return self.p.get('repsLow') is not None or self.p.get('repsHigh') is not None

    @property
    def reps_haut(self):
        p = self.p
        v = p.get('repsHigh')
        if v is None:
            v = p.get('repsLow')
        return 0 if v is None else v

    @property
    def secondes_haut(self):
        p = self.p
        v = p.get('secondsHigh')
        if v is None:
            v = p.get('secondsLow')
        return 0 if v is None else v

    @property
    def rir(self):
        f = self.p.get('targetFlames')
        return None if f is None else flammes_vers_rir(f)

    @property
    def est_test(self):
        return self.p.get('kind') == 'test'

    @property
    def est_echauffement(self):
        return self.p.get('kind') == 'warmup'

    @property
    def codes_technique(self):
        out = []
        f = self.p.get('format')
        if f is not None:
            out.append(f)
        t = self.p.get('technique')
        if t is not None and t.get('kind') != 'standard':
            if t.get('kind') not in out:
                out.append(t.get('kind'))
        return out

    @property
    def series_dures(self):
        return series_dures(self.p, self.fiche, self.renfo)

    def series_creditees(self, g):
        return self.series_dures * self.credits[g] / 2

    @property
    def charge_totale(self):
        load = self.p.get('startLoadKg')
        if load is None:
            return None
        frac = self.fiche.get('bodyweightFraction')
        if frac is None:
            frac = self.fiche.get('fraction') or 0.0
        return float(load) + frac * self.poids

    @property
    def bras_tendus(self):
        return famille_bras_tendus(self.fiche)

    @property
    def secondes_tenue(self):
        return float(self.p['sets'] * self.secondes_haut) if (self.est_temps and self.renfo) else 0.0

    @property
    def secondes_estimees(self):
        return duree_item_secondes(self.p, self.fiche, self.allure, self.renfo)


def series_dures(p, fiche, renfo=None):
    """`ItemView.hardSets` : séries de renforcement hors échauffement à RIR
    ≤ 4 (flammes ≥ 3) ou sans cible de difficulté."""
    if renfo is None:
        renfo = est_renforcement(fiche)
    if not renfo or p.get('kind') == 'warmup':
        return 0.0
    f = p.get('targetFlames')
    if f is not None and flammes_vers_rir(f) > RIR_MAX_SERIE_DURE:
        return 0.0
    return float(p['sets'])


def duree_item_secondes(p, fiche, allure=ALLURE_DEFAUT, renfo=None):
    """`ItemView.estimatedSeconds`."""
    if renfo is None:
        renfo = est_renforcement(fiche)
    cotes = 1 if fiche['laterality'] == 'bilateral' else 2
    reps = p.get('repsLow') is not None or p.get('repsHigh') is not None
    temps = p.get('secondsLow') is not None or p.get('secondsHigh') is not None
    if reps:
        rh = p.get('repsHigh')
        if rh is None:
            rh = p.get('repsLow')
        effort = (rh or 0) * SECONDES_PAR_REP * cotes
    elif temps:
        sh = p.get('secondsHigh')
        if sh is None:
            sh = p.get('secondsLow')
        effort = float(sh or 0) * (cotes if renfo else 1)
    elif p.get('distanceMeters') is not None:
        effort = float(p['distanceMeters']) / allure
    elif p.get('calories') is not None:
        effort = float(p['calories']) * 6
    else:
        effort = 30.0
    rest = p.get('restSeconds')
    rest = float(60 if rest is None else rest)
    return SECONDES_TRANSITION + p['sets'] * effort + (p['sets'] - 1) * rest


class Jour(object):
    """Séance d'une semaine (`DayView`)."""

    __slots__ = ('day_index', 'weekday', 'budget', 'items', 'brut')

    def __init__(self, day_index, weekday, budget, items, brut):
        self.day_index = day_index
        self.weekday = weekday
        self.budget = budget
        self.items = items
        self.brut = brut

    @property
    def minutes_estimees(self):
        s = 0.0
        renfo = False
        for i in self.items:
            s += i.secondes_estimees
            renfo = renfo or i.renfo
        return (s + (300 if renfo else 0)) / 60

    @property
    def jour_epreuve(self):
        """Jour d'une course d'épreuve (test chronométré noté `event_day`)."""
        for i in self.items:
            p = i.p
            if (p.get('kind') == 'test' and (p.get('test') or {}).get('kind') == 'time_trial'
                    and any((r.get('params') or {}).get('note') == 'event_day'
                            for r in p.get('reasons') or [])):
                return True
        return False


class Semaine(object):
    """Semaine du programme (`WeekView`)."""

    __slots__ = ('index', 'block_index', 'week_in_block', 'kind', 'days')

    def __init__(self, index, block_index, week_in_block, kind, days):
        self.index = index
        self.block_index = block_index
        self.week_in_block = week_in_block
        self.kind = kind
        self.days = days

    @property
    def items(self):
        for d in self.days:
            for i in d.items:
                yield i

    @property
    def series_dures(self):
        t = 0.0
        for i in self.items:
            t += i.series_dures
        return t

    def series_groupe(self, g):
        t = 0.0
        for i in self.items:
            t += i.series_creditees(g)
        return t

    @property
    def minutes_conditionnement(self):
        s = 0.0
        for i in self.items:
            if not i.renfo:
                s += i.secondes_estimees
        return s / 60

    def secondes_bras_tendus(self, famille):
        t = 0.0
        for i in self.items:
            if i.bras_tendus == famille:
                t += i.secondes_tenue
        return t

    def jours_bras_tendus(self, famille):
        n = 0
        for d in self.days:
            if any(i.bras_tendus == famille for i in d.items):
                n += 1
        return n

    @property
    def allegee(self):
        """`WeekView.isLight` : allégée par nature."""
        return self.kind in ('intro', 'deload', 'test')


def lire_programme(blocs, infos, horizon_semaines, poids_corps=POIDS_DEFAUT_KG,
                   allure=ALLURE_DEFAUT, block_weeks=None):
    """`ProgramView._read` : semaines des blocs servis jusqu'à l'horizon."""
    idx = indexer_infos(infos)
    out = []
    g = 0
    for b, bloc in enumerate(blocs_servis(blocs, block_weeks)):
        p1_days = bloc['pass1']['days']
        for week in bloc['pass2']['weeks']:
            if g >= horizon_semaines:
                return out
            days = []
            for day in week['days']:
                base = p1_days[day['dayIndex']]
                items = []
                for item in day['items']:
                    fiche = idx.get(item['exerciseId'])
                    if fiche is None:
                        raise KeyError('fiche absente : %s' % item['exerciseId'])
                    items.append(Item(g, week['kind'], day['dayIndex'], item, fiche,
                                      poids_corps, allure))
                days.append(Jour(day['dayIndex'], base['weekday'], base['minutesBudget'], items, day))
            out.append(Semaine(g, b, week['weekIndex'], week['kind'], days))
            g += 1
    return out


# ---------------------------------------------------------------------------
# Grandeurs réutilisables par un planificateur
# ---------------------------------------------------------------------------

def series_par_groupe(semaines, groupes=None, majeurs_seulement=True):
    """Séries dures créditées par groupe et par semaine :
    {code du groupe: [valeur par semaine]}."""
    out = {}
    for (gi, code, major) in (groupes or GROUPES):
        if majeurs_seulement and not major:
            continue
        out[code] = [w.series_groupe(gi) for w in semaines]
    return out


def secondes_par_famille(semaines):
    """Secondes de tenue bras tendus par famille et par semaine."""
    return {f: [w.secondes_bras_tendus(f) for w in semaines] for f in FAMILLES_BRAS_TENDUS}


def jours_par_famille(semaines):
    """Séances contenant une tenue bras tendus, par famille et par semaine."""
    return {f: [w.jours_bras_tendus(f) for w in semaines] for f in FAMILLES_BRAS_TENDUS}


def series_dures_par_semaine(semaines):
    return [w.series_dures for w in semaines]


def duree_seance_minutes(items_json, infos, allure=ALLURE_DEFAUT):
    """Durée estimée d'une séance (liste d'items JSON), en minutes
    (`DayView.estimatedMinutes`)."""
    idx = indexer_infos(infos)
    s = 0.0
    renfo = False
    for p in items_json:
        f = idx[p['exerciseId']]
        r = est_renforcement(f)
        s += duree_item_secondes(p, f, allure, r)
        renfo = renfo or r
    return (s + (300 if renfo else 0)) / 60


def _pas(reference, rise, tolerance):
    rel = reference * (1 + rise)
    ab = reference + tolerance
    return rel if rel > ab else ab


def limite_rampe(allegees, serie, index, rise, tolerance):
    """`rampLimit` : plus haute valeur admise en semaine `index` ;
    `allegees[k]` est `isLight` de la semaine k."""
    loaded = 0.0
    light = 0.0
    any_loaded = False
    for k in range(index - 3, index):
        if k < 0:
            continue
        if allegees[k]:
            if serie[k] > light:
                light = serie[k]
        else:
            any_loaded = True
            if serie[k] > loaded:
                loaded = serie[k]
    if any_loaded:
        reference = loaded if loaded > light else light
        return _pas(reference, rise, tolerance)
    stepped = _pas(light, rise, tolerance)
    resumed = light / RAMP_SHARE
    return stepped if stepped > resumed else resumed


def limites_volume(allegees, serie, index):
    """Limites de `volume_trop_vite` en semaine `index` (≥ 1) :
    (limite sur trois semaines, limite sur deux semaines ou None). La règle
    de deux semaines ne s'applique que si la première tient."""
    l1 = limite_rampe(allegees, serie, index, VOLUME_RISE, VOLUME_RISE_SETS)
    l2 = None
    if (index > 1 and not allegees[index] and not allegees[index - 1]
            and not allegees[index - 2] and serie[index - 2] > 0):
        l2 = _pas(serie[index - 2], VOLUME_RISE_TWO_WEEKS, VOLUME_RISE_TWO_WEEKS_SETS)
    return l1, l2


def limite_tenue(allegees, serie, index, niveau):
    """Limite de hausse des secondes bras tendus (`tendon_figures`) ; None
    sans référence (aucune tenue de la famille dans les trois semaines
    précédentes), auquel cas aucune hausse n'est contrôlée."""
    reference = 0.0
    for k in range(index - 3, index):
        if k >= 0 and serie[k] > reference:
            reference = serie[k]
    if reference <= 0:
        return None
    return limite_rampe(allegees, serie, index, STRAIGHT_ARM_RISE[niveau], STRAIGHT_ARM_RISE_SECONDS)


def plafond_hebdomadaire(niveau):
    """Plafond de séries dures créditées par groupe et par semaine."""
    return WEEKLY_CEILING[niveau]


def limite_duree_seance(budget_minutes):
    """Durée admise d'une séance, en minutes (budget × 1,15 + 3)."""
    return budget_minutes * (1 + SESSION_TOLERANCE) + 3


def limite_charge(niveau):
    """Hausse relative maximale de la charge totale d'une semaine à
    l'autre, à `repsHigh` égal."""
    return LOAD_RISE[niveau]


def semaine_allegee(series_semaines, index, allegees):
    """Vrai si la semaine `index` compte comme allègement pour
    `decharge_absente` : séries dures ≤ 70 % du plus haut des trois
    semaines précédentes (sans référence : allégée par nature)."""
    reference = 0.0
    for k in range(index - 3, index):
        if k >= 0 and series_semaines[k] > reference:
            reference = series_semaines[k]
    if reference > 0:
        return series_semaines[index] <= reference * RELIEF_SHARE + EPS
    return allegees[index]


def max_semaines_sans_decharge(niveau):
    return WEEKS_WITHOUT_RELIEF[niveau]


def baisse_affutage(niveau):
    """Baisse minimale du volume la semaine de l'échéance."""
    return TAPER_DROP[niveau]


def volume_affutage(semaines, at):
    """(baisse, pic, volume de la semaine, cardio) pour la semaine `at`
    (= weeksOut − 1) ; `at` ≥ 2."""
    cardio = True
    for k in range(at - 6, at):
        if k >= 0 and semaines[k].series_dures > 0:
            cardio = False

    def vol(w):
        return w.minutes_conditionnement if cardio else w.series_dures

    peak = 0.0
    for k in range(at - 6, at):
        if k >= 0 and vol(semaines[k]) > peak:
            peak = vol(semaines[k])
    last = vol(semaines[at])
    drop = 0.0 if peak <= 0 else 1 - last / peak
    return drop, peak, last, cardio


# ---------------------------------------------------------------------------
# Profil du banc
# ---------------------------------------------------------------------------

class ProfilBanc(object):
    """Ce que `safetyFindings` lit du profil du banc."""

    def __init__(self, bench_json):
        j = bench_json
        self.json = j
        self.niveau = NIVEAUX.index(j['level'])
        self.core = j.get('core') or {}
        self.records = j.get('records') or []
        self.injuries = j.get('injuries') or []
        pause = j.get('break')
        self.break_weeks = 0 if pause is None else int(pause['weeksOff'])
        self.birth_year = int(self.core['birthYear'])
        best = None
        for e in j.get('events') or []:
            if (e.get('priority') or 'A') != 'A':
                continue
            if best is None or e['weeksOut'] < best['weeksOut']:
                best = e
        self.main_event = best

    @property
    def libelle_niveau(self):
        return LIBELLE_NIVEAU[self.niveau]

    @property
    def imc(self):
        w = self.core.get('bodyWeightKg')
        if w is None:
            return None
        m = int(self.core['heightCm']) / 100
        return float(w) / (m * m)


# ---------------------------------------------------------------------------
# Critères
# ---------------------------------------------------------------------------

class ContexteBanc(object):
    """Profil, fiches et groupes lus une fois ; `constats` peut ensuite être
    appelé sur autant de variantes de blocs que voulu (essai d'un changement
    avant de l'appliquer)."""

    def __init__(self, bench_json, profil_json, infos, groupes=None):
        self.bench = ProfilBanc(bench_json)
        self.infos = indexer_infos(infos)
        self.groupes = groupes or GROUPES
        w = (profil_json or {}).get('bodyWeightKg')
        self.poids = POIDS_DEFAUT_KG if w is None else float(w)
        self.allure = allure_course(bench_json)

    def lire(self, blocs, horizon_semaines, block_weeks=None):
        return lire_programme(blocs, self.infos, horizon_semaines, self.poids, self.allure,
                              block_weeks)

    def constats(self, blocs, horizon_semaines, block_weeks=None):
        return constats_semaines(self.lire(blocs, horizon_semaines, block_weeks), self.bench,
                                 self.infos, self.groupes)


def constats(blocs, bench_json, profil_json, infos, horizon_semaines, block_weeks=None,
             groupes=None):
    """Portage de `safetyFindings(ProgramView(...), bench)` tel que
    `realizedFindings` l'appelle. `blocs` peut aussi être un dictionnaire
    {'blocks': [...], 'blockWeeks': [...] ou None} (format des entrées de
    `kmSafetyOfBlocks`) ; `block_weeks` tronque les blocs interrompus comme
    `servedBlocksOf`."""
    if isinstance(blocs, dict):
        if block_weeks is None:
            block_weeks = blocs.get('blockWeeks')
        blocs = blocs['blocks']
    return ContexteBanc(bench_json, profil_json, infos, groupes).constats(
        blocs, horizon_semaines, block_weeks)


def constats_saison(saison, infos, blocs=None, groupes=None):
    """Constats d'une saison exportée par `kmReferenceSeason` (ou de ses
    blocs remplacés par `blocs`)."""
    return constats(saison['blocks'] if blocs is None else blocs, saison['benchJson'],
                    saison['profiles'][0]['profile'], infos, saison['weeks'],
                    block_weeks=saison.get('blockWeeks'), groupes=groupes)


def constats_semaines(weeks, bench, infos, groupes=None):
    """Cœur de `safetyFindings` sur des semaines déjà lues."""
    groupes = groupes or GROUPES
    out = []
    level = bench.niveau
    allegees = [w.allegee for w in weeks]

    # --- Hausse de charge d'une semaine à l'autre.
    last_load = {}
    for w in weeks:
        for i in w.items:
            total = i.charge_totale
            if total is None or total <= 0 or i.est_test:
                continue
            key = '%d|%s|%s' % (i.day_index, i.p['slotId'], i.exercise_id)
            before = last_load.get(key)
            if before is not None and before[0] == w.index - 1 and before[2] == i.reps_haut:
                rise = total / before[1] - 1
                limit = LOAD_RISE[level]
                if rise > limit + EPS:
                    out.append(_constat(
                        'charge_trop_vite',
                        '%s : charge totale +%s %% en une semaine (seuil %s %%).'
                        % (i.nom, fixe(rise * 100, 1), fixe(limit * 100, 1)),
                        w.index, i.day_index, i.exercise_id, rise, limit))
            last_load[key] = (w.index, total, i.reps_haut)

    # --- Volume par groupe : hausse et plafond.
    ceiling = WEEKLY_CEILING[level]
    for (gi, code, major) in groupes:
        if not major:
            continue
        label = LIBELLE_GROUPE.get(code, code)
        series = [w.series_groupe(gi) for w in weeks]
        above = 0
        highest = 0.0
        first_above = None
        for w in weeks:
            sets = series[w.index]
            if w.index > 0:
                limit = limite_rampe(allegees, series, w.index, VOLUME_RISE, VOLUME_RISE_SETS)
                if sets > limit + EPS:
                    out.append(_constat(
                        'volume_trop_vite',
                        '%s : %s séries dures en semaine %d, pour %s admises au vu des trois '
                        'semaines précédentes.' % (label, fixe(sets, 1), w.index + 1, fixe(limit, 1)),
                        w.index, None, None, sets, limit))
                elif w.index > 1 and not w.allegee and not allegees[w.index - 1] \
                        and not allegees[w.index - 2]:
                    two = _pas(series[w.index - 2], VOLUME_RISE_TWO_WEEKS, VOLUME_RISE_TWO_WEEKS_SETS)
                    if series[w.index - 2] > 0 and sets > two + EPS:
                        out.append(_constat(
                            'volume_trop_vite',
                            '%s : %s séries dures en semaine %d, pour %s admises au vu de la '
                            'semaine %d (hausse sur deux semaines).'
                            % (label, fixe(sets, 1), w.index + 1, fixe(two, 1), w.index - 1),
                            w.index, None, None, sets, two))
            if sets > ceiling + EPS:
                above += 1
                if first_above is None:
                    first_above = w.index
                if sets > highest:
                    highest = sets
        if above > 0:
            out.append(_constat(
                'plafond_volume',
                "%s : %d semaine(s) au-dessus du plafond du niveau %s (%s séries dures), "
                "jusqu'à %s." % (label, above, bench.libelle_niveau, fixe(ceiling, 0), fixe(highest, 1)),
                first_above, None, None, highest, ceiling))
    if level == 3:
        advanced = WEEKLY_CEILING[2]
        for w in weeks:
            above = 0
            for (gi, code, major) in groupes:
                if major and w.series_groupe(gi) > advanced + EPS:
                    above += 1
            if above > ELITE_GROUPS_ABOVE_ADVANCED:
                out.append(_constat(
                    'plafond_volume',
                    '%d groupes au-dessus de %s séries dures en semaine %d (au plus %d en élite).'
                    % (above, fixe(advanced, 0), w.index + 1, ELITE_GROUPS_ABOVE_ADVANCED),
                    w.index, None, None, float(above), float(ELITE_GROUPS_ABOVE_ADVANCED)))

    # --- Techniques, niveau des exercices, paliers non acquis.
    known = set()
    for r in bench.records:
        if float(r['value']) > 0:
            known.add(r['exerciseId'])
    for eid in bench.core.get('knownExerciseIds') or []:
        known.add(eid)
    not_acquired = []
    for r in bench.records:
        if float(r['value']) <= 0 and r['exerciseId'] in infos:
            not_acquired.append(infos[r['exerciseId']])
    for eid in bench.core.get('cannotDoExerciseIds') or []:
        if eid in infos:
            not_acquired.append(infos[eid])
    seen = set()
    for w in weeks:
        for i in w.items:
            e = i.fiche
            eid = i.exercise_id
            for code in i.codes_technique:
                need = TECHNIQUE_MIN_LEVEL.get(code)
                if need is not None and level < need:
                    out.append(_constat(
                        'technique_sans_prerequis',
                        '%s : technique « %s » réservée au niveau %s et au-delà.'
                        % (i.nom, code, LIBELLE_NIVEAU[need]),
                        w.index, i.day_index, eid))
            if eid in seen:
                continue
            seen.add(eid)
            for frag, need in TECHNIQUE_EXERCISE_MIN_LEVEL:
                if frag in eid and level < need:
                    out.append(_constat(
                        'technique_sans_prerequis',
                        '%s : technique réservée au niveau %s et au-delà.' % (i.nom, LIBELLE_NIVEAU[need]),
                        w.index, i.day_index, eid))
            if i.renfo and eid not in known and e['level'] > level + 1:
                out.append(_constat(
                    'exercice_trop_avance',
                    '%s (niveau %s de la base) pour un profil %s.'
                    % (i.nom, e.get('levelCode') or CODE_NIVEAU_EXERCICE[e['level']],
                       bench.libelle_niveau),
                    w.index, i.day_index, eid))
            for missing in not_acquired:
                harder = (e['rootId'] == missing['rootId'] and not e['assisted']
                          and e['difficulty'] >= missing['difficulty'])
                if eid == missing['id'] or harder or missing['id'] in (e.get('prerequisites') or []):
                    out.append(_constat(
                        'exercice_non_acquis',
                        "%s : demande %s, que le profil n'a pas acquis."
                        % (i.nom, missing.get('name') or missing['id']),
                        w.index, i.day_index, eid))
                    break

    # --- Contre-indications par articulation.
    for inj in bench.injuries:
        joint = inj.get('joint') or ARTICULATION_DE_ZONE.get(inj['zone'])
        if joint is None:
            continue
        months = inj.get('monthsAgo')
        recent = inj['status'] == 'history' and (99 if months is None else months) < 12
        disc = int(inj['discomfort'])
        flagged = set()
        for w in weeks:
            for i in w.items:
                stress = contrainte(i.fiche, joint)
                bad = False
                why = ''
                r = i.rir
                if stress == 'high' and disc >= DISCOMFORT_HIGH:
                    bad, why = True, 'contrainte forte'
                elif stress == 'moderate' and disc >= DISCOMFORT_MODERATE:
                    bad, why = True, 'contrainte modérée'
                elif (stress == 'high' and (recent or disc >= 2) and i.renfo and not i.est_test
                      and (5.0 if r is None else r) < 1):
                    bad, why = True, "contrainte forte menée à l'échec"
                if bad and i.exercise_id not in flagged:
                    flagged.add(i.exercise_id)
                    out.append(_constat(
                        'contre_indication',
                        '%s : %s sur %s (%s, gêne %d/10).'
                        % (i.nom, why, LIBELLE_ARTICULATION[joint], inj['label'], disc),
                        w.index, i.day_index, i.exercise_id))

    # --- Tenues bras tendus : fréquence, hausse, passage de levier.
    for family in FAMILLES_BRAS_TENDUS:
        held = [x.secondes_bras_tendus(family) for x in weeks]
        for w in weeks:
            days = w.jours_bras_tendus(family)
            max_days = STRAIGHT_ARM_DAYS[level]
            if days > max_days:
                out.append(_constat(
                    'tendon_figures',
                    'Tenues bras tendus (%s) %d jours en semaine %d (au plus %d au niveau %s).'
                    % (LIBELLE_FAMILLE[family], days, w.index + 1, max_days, bench.libelle_niveau),
                    w.index, None, None, float(days), float(max_days)))
            if w.index == 0:
                continue
            reference = 0.0
            for k in range(w.index - 3, w.index):
                if k >= 0 and held[k] > reference:
                    reference = held[k]
            seconds = held[w.index]
            limit = limite_rampe(allegees, held, w.index, STRAIGHT_ARM_RISE[level],
                                 STRAIGHT_ARM_RISE_SECONDS)
            if reference > 0 and seconds > limit + EPS:
                out.append(_constat(
                    'tendon_figures',
                    'Tenues bras tendus (%s) : %d s en semaine %d, pour %d s admises au vu des '
                    'trois semaines précédentes.'
                    % (LIBELLE_FAMILLE[family], arrondi_dart(seconds), w.index + 1, arrondi_dart(limit)),
                    w.index, None, None, seconds, limit))
    first_week = {}
    chain = {}
    for w in weeks:
        for i in w.items:
            if i.bras_tendus is None:
                continue
            if i.exercise_id not in first_week:
                first_week[i.exercise_id] = w.index
                chain.setdefault(i.fiche['rootId'], []).append(i.fiche)
    min_weeks = LEVER_WEEKS[level]
    for levers in chain.values():
        for later in levers:
            for earlier in levers:
                gap = first_week[later['id']] - first_week[earlier['id']]
                if (later['difficulty'] > earlier['difficulty'] and 0 < gap < min_weeks
                        and later['id'] not in known):
                    out.append(_constat(
                        'levier_trop_tot',
                        '%s arrive %d semaines après %s (au moins %d au niveau %s).'
                        % (later.get('name') or later['id'], gap, earlier.get('name') or earlier['id'],
                           min_weeks, bench.libelle_niveau),
                        first_week[later['id']], None, later['id'], float(gap), float(min_weeks)))

    # --- Échec et quasi-échec sur mouvements à risque.
    for w in weeks:
        near = 0
        for i in w.items:
            if not i.renfo or i.est_test or i.est_echauffement:
                continue
            r = i.rir
            if r is None:
                continue
            high = risque_eleve(i.fiche)
            if r < HIGH_RISK_MIN_RIR - EPS and high:
                out.append(_constat(
                    'echec_risque',
                    '%s : %s répétition(s) en réserve sur un mouvement à risque élevé (au moins 2 '
                    'attendues).' % (i.nom, fixe(r, 1)),
                    w.index, i.day_index, i.exercise_id, r, HIGH_RISK_MIN_RIR))
            elif level == 0 and r <= 0:
                out.append(_constat(
                    'echec_risque',
                    "%s : série prescrite à l'échec pour un débutant." % (i.nom,),
                    w.index, i.day_index, i.exercise_id, r, 1.0))
            if level == 0 and r <= 1 and (high or risque_modere(i.fiche)):
                near += i.p['sets']
        if near >= 2:
            out.append(_constat(
                'echec_risque',
                '%d séries à 1 RIR ou moins sur des mouvements à risque en semaine %d, pour un '
                'débutant.' % (near, w.index + 1),
                w.index, None, None, float(near), 1.0))

    # --- Durée des séances.
    for w in weeks:
        for d in w.days:
            minutes = d.minutes_estimees
            limit = limite_duree_seance(d.budget)
            if minutes > limit and not d.jour_epreuve:
                out.append(_constat(
                    'seance_trop_longue',
                    'Semaine %d, jour %d : %d min estimées pour %d min disponibles.'
                    % (w.index + 1, d.day_index + 1, arrondi_dart(minutes), d.budget),
                    w.index, d.day_index, None, minutes, limit))

    # --- Allègements.
    run = 0
    reported = False
    hard = [w.series_dures for w in weeks]
    for w in weeks:
        if semaine_allegee(hard, w.index, allegees):
            run = 0
            reported = False
            continue
        run += 1
        limit = WEEKS_WITHOUT_RELIEF[level]
        if run > limit and not reported:
            reported = True
            out.append(_constat(
                'decharge_absente',
                '%d semaines de charge de suite sans allègement à la semaine %d (au plus %d au '
                'niveau %s).' % (run, w.index + 1, limit, bench.libelle_niveau),
                w.index, None, None, float(run), float(limit)))

    # --- Affûtage avant l'échéance prioritaire.
    event = bench.main_event
    if event is not None and weeks:
        at = event['weeksOut'] - 1
        if at >= len(weeks):
            out.append(_constat(
                'affutage_absent',
                "L'échéance (semaine %d) est au-delà du programme généré (%d semaines)."
                % (event['weeksOut'], len(weeks))))
        elif at >= 2:
            drop, _, _, _ = volume_affutage(weeks, at)
            need = TAPER_DROP[level]
            if drop < need - EPS:
                out.append(_constat(
                    'affutage_absent',
                    "Semaine de l'échéance : volume %d %% sous le pic des six semaines "
                    'précédentes (au moins %d %% attendus).'
                    % (arrondi_dart(drop * 100), arrondi_dart(need * 100)),
                    at, None, None, drop, need))

    # --- Reprise après coupure.
    if bench.break_weeks >= BREAK_WEEKS and weeks:
        flagged = set()
        for i in weeks[0].items:
            if not i.renfo or i.est_echauffement or i.est_test:
                continue
            r = i.rir
            if r is not None and r < RESUME_MIN_RIR and i.exercise_id not in flagged:
                flagged.add(i.exercise_id)
                out.append(_constat(
                    'reprise_trop_dure',
                    "%s : RIR %s dès la première semaine après %d semaines d'arrêt (au moins 3 "
                    'attendus).' % (i.nom, fixe(r, 1), bench.break_weeks),
                    0, i.day_index, i.exercise_id, r, RESUME_MIN_RIR))

    # --- Impact.
    age = BENCH_START_YEAR - bench.birth_year
    screening = bench.core.get('healthScreening')
    cautious = isinstance(screening, dict) and screening.get('outcome') == 'cautious'
    bmi = bench.imc
    heavy_beginner = level == 0 and bmi is not None and bmi >= IMPACT_BMI
    if age >= IMPACT_AGE or cautious or heavy_beginner:
        flagged = set()
        for w in weeks:
            for i in w.items:
                if age >= IMPACT_AGE or cautious:
                    v = i.fiche.get('impact')
                    risky = bool(v) if v is not None else impact_calcule(i.fiche)
                else:
                    risky = i.fiche['pattern'] in SCHEMAS_IMPACT_LOURD
                if risky and i.exercise_id not in flagged:
                    flagged.add(i.exercise_id)
                    out.append(_constat(
                        'impact_deconseille',
                        '%s : impact ou explosif, déconseillé pour ce profil.' % (i.nom,),
                        w.index, i.day_index, i.exercise_id))
    return out


def comptes(found):
    """Nombre de constats par code."""
    out = {}
    for f in found:
        out[f['code']] = out.get(f['code'], 0) + 1
    return out


def ecrire_entree_securite(chemin, cle, scenario, libelle, blocs, block_weeks=None):
    """Écrit une entrée de `kmSafetyOfBlocks` (dossier
    `kalis_bench/km1_entree/securite/`, fichier `*.json.gz`) : le banc Dart
    en tire les constats de `safetyFindings` (`securite_dart.json.gz`)."""
    import gzip
    import json
    import os
    d = os.path.dirname(chemin)
    if d and not os.path.isdir(d):
        os.makedirs(d)
    with gzip.open(chemin, 'wt', encoding='utf-8') as f:
        json.dump({'key': cle, 'scenario': scenario, 'label': libelle,
                   'blockWeeks': block_weeks, 'blocks': blocs}, f, ensure_ascii=False)


def ecrire_entrees_reference(dossier, cles=None):
    """Écrit, pour chaque saison de référence exportée (`donnees/reference`),
    une entrée de `kmSafetyOfBlocks` dans `dossier` (en pratique
    `kalis_bench/km1_entree/securite/`) : le Dart en tire alors les
    constats de `safetyFindings` sur les MÊMES blocs, que
    `tests/test_securite_banc.py` compare à ce portage. Renvoie le nombre
    de fichiers écrits."""
    import os
    from . import donnees
    n = 0
    for cle in (cles or donnees.profils()):
        for s in donnees.saisons_reference(cle):
            nom = 'ref__%s__%s.json.gz' % (cle, s['scenario'])
            ecrire_entree_securite(os.path.join(dossier, nom), cle, s['scenario'],
                                   'saison de référence de kalis_plan', s['blocks'],
                                   s.get('blockWeeks'))
            n += 1
    return n


if __name__ == '__main__':
    import sys
    if len(sys.argv) != 3 or sys.argv[1] != '--entrees-dart':
        sys.stderr.write('usage : python3 -m banc.securite_banc --entrees-dart <dossier>\n')
        sys.exit(64)
    print('%d entrée(s) écrite(s).' % ecrire_entrees_reference(sys.argv[2]))
