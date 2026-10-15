# -*- coding: utf-8 -*-
"""Meneur de saison du banc Python : portage de `simulate`
(`kalis_adapt/lib/src/sim/runner.dart`, 0.3.1) pour une politique Python.

Mêmes clés d'aléas que le meneur Dart (calendrier, effets de jour, séries) :
à graine égale, l'athlète simulé, ses absences, sa maladie et sa douleur sont
ceux que le témoin `kalis_adapt` 0.3.1 a rencontrés. La saison servie est la
saison de référence exportée par le banc Dart (`kmReferenceSeason`).
"""
import math

from .alea import SimRandom, flames_to_rir
from .verite import SimAthlete, Spec, make_book
from .verite_endurance import EnduranceTruth


class Contexte(object):
    """Ce que la politique reçoit pour une séance (`SessionContext`)."""

    def __init__(self, saison, profil, livre, bloc_index, bloc, semaine, semaine_bloc,
                 jour_index, sim_day, bilan, lieu, athlete, ecrit, genre_semaine,
                 intention, jour_evenement, budget):
        self.saison = saison
        self.profil = profil
        self.livre = livre
        self.bloc_index = bloc_index
        self.bloc = bloc
        self.semaine = semaine
        self.semaine_bloc = semaine_bloc
        self.jour_index = jour_index
        self.sim_day = sim_day
        self.bilan = bilan
        self.lieu = lieu
        self.athlete = athlete      # réservé aux mesures : la politique ne le lit pas
        self.ecrit = ecrit          # prescription écrite du jour (bloc de référence)
        self.genre_semaine = genre_semaine
        self.intention = intention
        self.jour_evenement = jour_evenement
        self.budget = budget

    def role_de(self, slot_id):
        for d in self.bloc['pass1']['days']:
            for s in d['slots']:
                if s['slotId'] == slot_id:
                    return s.get('role')
        return None


def mesure_de(item):
    if item.get('secondsHigh') is not None or item.get('secondsLow') is not None:
        return 1
    if item.get('repsHigh') is not None or item.get('repsLow') is not None:
        return 0
    return 2


def cible_de(item, index):
    """Cible de la série [index] d'une prescription (`targetOfItem`)."""
    targets = item.get('setTargets')
    if targets:
        t = targets[index if index < len(targets) else len(targets) - 1]

        def pick(k, k2=None):
            v = t.get(k)
            return item.get(k2 or k) if v is None else v
        return {
            'repsLow': pick('repsLow'), 'repsHigh': pick('repsHigh'),
            'secondsLow': pick('secondsLow'), 'secondsHigh': pick('secondsHigh'),
            'loadKg': t.get('loadKg') if t.get('loadKg') is not None else item.get('startLoadKg'),
            'flames': pick('flames', 'targetFlames'), 'role': t.get('role'),
        }
    return {
        'repsLow': item.get('repsLow'), 'repsHigh': item.get('repsHigh'),
        'secondsLow': item.get('secondsLow'), 'secondsHigh': item.get('secondsHigh'),
        'loadKg': item.get('startLoadKg'), 'flames': item.get('targetFlames'), 'role': None,
    }


class Tour(object):
    """Résultat d'une saison simulée (`SimRun`), réduit à ce que les mesures
    lisent."""

    def __init__(self, cle, scenario, kind, seed, politique):
        self.cle = cle
        self.scenario = scenario
        self.kind = kind
        self.seed = seed
        self.politique = politique
        self.sets = []        # dictionnaires (`SetRow`)
        self.estimates = []   # dictionnaires (`EstimateRow`)
        self.sessions_planned = 0
        self.sessions_done = 0
        self.pain_aggravations = 0
        self.pain_flares = 0
        self.endurance_overuse = 0
        self.worst_run_spike = 0.0
        self.gain = {}
        self.cap0 = {}
        self.cap_fin = {}
        self.journal = []     # séances (pour le rejeu et les fixtures)
        self.predictions = []  # prédictions de P(réussite) faites par la politique
        self.servi = []       # (semaine, bloc_index, semaine_bloc, jour_index, items servis)
        self.extra = {}


def simuler(saison, infos, politique, kind, seed, spec_json=None, garder_journal=False,
            surcharges=None):
    """Simule la saison [saison] (export `kmReferenceSeason`) pour la
    politique [politique] sous le modèle de vérité [kind] et la graine [seed].

    [spec_json] remplace la fiche de l'athlète (banc adversarial) ;
    [surcharges] : id -> multiplicateurs appliqués à la vérité d'un exercice à
    sa création ({'capacity', 'curveB', 'slope', 'power', 'fatigueScale',
    'holdShare'})."""
    spec = Spec(spec_json or saison['specJson'])
    profils = saison['profiles']
    profil = profils[0]['profile']
    livre = make_book(infos, profil)
    athlete = SimAthlete(spec, profil, livre, seed, kind=kind)
    if surcharges:
        _surcharger(athlete, surcharges)
    endurance = EnduranceTruth(kind, spec.level, seed)
    tour = Tour(saison['key'], saison['scenario'], kind, seed, politique.nom)
    blocs = saison['blocks']
    exercise_sessions = {}
    band_notch = {}
    last_max_load = {}
    scheme_load = {}
    weeks = saison['weeks']
    par_semaine = {}
    for (g, bi, wb, di, sim_day) in saison['sessions']:
        par_semaine.setdefault(g, []).append((bi, wb, di, sim_day))
    politique.debut(saison, profil, livre)
    courant = profil
    for g in range(weeks):
        for ch in profils[1:]:
            if ch['week'] == g:
                courant = ch['profile']
                politique.changement_profil(g, courant)
        event_days = set(saison['eventDaysByWeek'][g])
        politique.debut_semaine(g)
        for (bi, wb, di, sim_day) in par_semaine.get(g, []):
            bloc = blocs[bi]
            semaine = None
            for w in bloc['pass2']['weeks']:
                if w['weekIndex'] == wb:
                    semaine = w
            ecrit = None
            for d in semaine['days']:
                if d['dayIndex'] == di:
                    ecrit = d
            tour.sessions_planned += 1
            calendar = SimRandom.of(seed, 'calendar|%d' % sim_day)
            bf = spec.break_from
            if bf is not None and sim_day >= bf and sim_day < bf + spec.break_days:
                politique.seance_manquee(g, sim_day)
                continue
            if calendar.next() < spec.miss_rate:
                politique.seance_manquee(g, sim_day)
                continue
            athlete.advance(sim_day)
            budget = bloc['pass1']['days'][di]['minutesBudget']
            bilan = athlete.health_check(budget)
            of = spec.other_place_from
            lieu = spec.other_place if (of is not None and sim_day >= of and sim_day < of + spec.other_place_days) else None
            ctx = Contexte(saison, courant, livre, bi, bloc, g, wb, di, sim_day, bilan, lieu,
                           athlete, ecrit, semaine.get('kind'), semaine.get('intent'),
                           sim_day in event_days, budget)
            seance = politique.planifier(ctx)
            done = []
            trained = []
            order = 0
            ecrits = ecrit['items']
            for item in seance['items']:
                ex_id = item['exerciseId']
                truth = athlete.truth_of(ex_id)
                if truth is not None and surcharges and ex_id in surcharges and not getattr(truth, '_km', False):
                    pass
                measure = mesure_de(item)
                info = livre.get(ex_id)
                e_kind = None if (truth is not None or info is None) else info.endurance_kind
                sets_n = item.get('sets', 0)
                if (truth is None and e_kind in ('run', 'conditioning')
                        and item.get('kind') != 'warmup' and sets_n > 0):
                    rates = SimRandom.of(seed, 'rate|%d|%s' % (sim_day, ex_id)).next() >= spec.lazy
                    if e_kind == 'run':
                        made, injured = endurance.run(item, sets_n, sim_day, 0, athlete.ill, rates)
                    else:
                        written = item
                        for it in ecrits:
                            if it['slotId'] == item['slotId']:
                                written = it
                        wr = written.get('repsHigh') if written.get('repsHigh') is not None else written.get('secondsHigh')
                        sr = item.get('repsHigh') if item.get('repsHigh') is not None else item.get('secondsHigh')
                        ws = 1 if written.get('sets', 0) <= 0 else written['sets']
                        share = 1.0 if (wr is None or sr is None or wr <= 0) else (sr / wr) * (sets_n / ws)
                        made, injured = endurance.wod_piece(
                            item, sets_n, sim_day, 0, athlete.ill, rates,
                            endurance.hard_streak_before(sim_day), 1.0 if share > 1 else share)
                    if injured is not None:
                        athlete.overuse(injured, 4, 14)
                    for i in range(made['sets']):
                        done.append({
                            'exerciseId': ex_id, 'exerciseOrder': order, 'setIndex': i,
                            'kind': item.get('kind') or 'work', 'reps': made['reps'],
                            'seconds': made['seconds'], 'distanceMeters': made['distanceMeters'],
                            'calories': made['calories'], 'flames': made['flames'],
                            'success': made['success'], 'slotId': item['slotId'],
                            'enduranceKind': e_kind, 'item': item,
                        })
                    order += 1
                    continue
                if truth is None or measure == 2:
                    reps = item.get('repsHigh') if item.get('repsHigh') is not None else item.get('repsLow')
                    seconds = item.get('secondsHigh') if item.get('secondsHigh') is not None else item.get('secondsLow')
                    if (reps is not None or seconds is not None or item.get('distanceMeters') is not None
                            or item.get('calories') is not None):
                        for i in range(sets_n):
                            done.append({
                                'exerciseId': ex_id, 'exerciseOrder': order, 'setIndex': i,
                                'kind': item.get('kind') or 'work', 'reps': reps,
                                'seconds': seconds if reps is None else None,
                                'flames': item.get('targetFlames'), 'success': True,
                                'slotId': item['slotId'], 'nonModelise': True,
                            })
                    order += 1
                    continue
                hold = truth.mode == 'hold'
                loaded = truth.mode == 'loaded'
                if hold != (measure == 1):
                    order += 1
                    continue
                athlete.begin_exercise(truth, item['slotId'])
                assist_kg = None
                if truth.mode == 'reps' and info.assisted:
                    notch = band_notch.get(ex_id, 3)
                    change = item.get('assistChange', 0)
                    if (change < 0 and notch > 0) or (change > 0 and notch < 6):
                        step = 0.75 * math.exp(0.12 * SimRandom.of(
                            seed, 'band|%s|%d' % (ex_id, notch if change < 0 else notch + 1)).gauss())
                        factor = step if change < 0 else 1 / step
                        truth.capacity *= factor
                        truth.start_capacity *= factor
                        truth.first_capacity *= factor
                        notch += change
                        politique.cran_change(ex_id, change)
                    band_notch[ex_id] = notch
                    assist_kg = -10.0 * notch
                basis = item
                for it in ecrits:
                    if it['slotId'] == item['slotId'] and it['exerciseId'] == ex_id:
                        basis = it
                basis_low = basis.get('secondsLow') if hold else basis.get('repsLow')
                basis_high = basis.get('secondsHigh') if hold else basis.get('repsHigh')
                count = exercise_sessions.get(ex_id, 0)
                role = ctx.role_de(item['slotId'])
                rest = item.get('restSeconds') or 90
                technique = item.get('technique')
                is_test = item.get('kind') == 'test' or basis.get('kind') == 'test'
                test_kind = ((item.get('test') or basis.get('test') or {}).get('kind')) if is_test else None
                is_attempt = test_kind in ('one_rm', 'attempt_simulation')
                performed = 0
                session_max = None
                for i in range(sets_n):
                    target = politique.prochaine_serie(ctx, item, i, done)
                    if target is None:
                        break
                    flames_target = target.get('flames')
                    if flames_target is None:
                        flames_target = item.get('targetFlames')
                    if flames_target is None:
                        flames_target = 6
                    low = target.get('secondsLow') if hold else target.get('repsLow')
                    high = target.get('secondsHigh') if hold else target.get('repsHigh')
                    if low is None:
                        low = high
                    if high is None:
                        high = low
                    if low is None or high is None:
                        break
                    load = None
                    self_selected = False
                    if loaded:
                        load = target.get('loadKg')
                        if load is None:
                            load = athlete.self_select(truth, high, flames_to_rir(flames_target))
                            self_selected = True
                    key = '%d|%s|%d' % (sim_day, item['slotId'], i)
                    line_role = target.get('role')
                    tk = None if technique is None else technique.get('kind')
                    applies = technique is not None and (technique.get('lastSetOnly') is not True or i == sets_n - 1)
                    served = tk if applies else None
                    day_max = truth.capacity * math.exp(truth.day)
                    planned_failure = flames_target >= 10
                    parts = None
                    elapsed = None
                    if line_role == 'attempt':
                        outcome = athlete.perform(truth, load, 1, 1, flames_target, rest, key)
                        planned_failure = True
                    elif line_role == 'test' and ((not loaded) or high > low) and flames_target >= 8:
                        outcome = athlete.perform(truth, load, low, high + (600 if hold else 200),
                                                  flames_target, rest, key)
                        planned_failure = True
                    elif served == 'cluster' and not hold:
                        mini = technique.get('miniSets') or 1
                        each = technique.get('miniSetReps') or high
                        intra = technique.get('intraRestSeconds') or 30
                        parts = []
                        total = 0
                        last = None
                        for k in range(mini):
                            o = athlete.perform(truth, load, each, each, flames_target,
                                                intra if k < mini - 1 else rest, '%s|%d' % (key, k))
                            last = o
                            if o.amount >= 1:
                                parts.append({'reps': o.amount})
                                total += o.amount
                            if o.failed or o.amount < each:
                                break
                        outcome = _Out(total, None if last is None else last.flames,
                                       0.0 if last is None else last.true_rir,
                                       False if last is None else last.failed)
                        low = mini * each
                        high = mini * each
                    elif served in ('rest_pause', 'myo_reps') and not hold:
                        myo = served == 'myo_reps'
                        intra = technique.get('intraRestSeconds') or (15 if myo else 20)
                        cap = technique.get('miniSets') or (5 if myo else 2)
                        each = technique.get('miniSetReps') or 3
                        goal = technique.get('totalRepsTarget')
                        first = athlete.perform(truth, load, low, high, flames_target, intra, key)
                        parts = [{'reps': first.amount}] if first.amount >= 1 else []
                        total = first.amount
                        if not first.failed:
                            for k in range(1, cap + 1):
                                if goal is not None and total >= goal:
                                    break
                                o = athlete.perform(truth, load, each if myo else 1, each if myo else high, 9,
                                                    intra if k < cap else rest, '%s|%d' % (key, k))
                                if o.amount < 1:
                                    break
                                parts.append({'reps': o.amount})
                                total += o.amount
                                if o.failed or (myo and o.amount < each):
                                    break
                        outcome = _Out(total, first.flames, first.true_rir, first.failed)
                        if not parts:
                            parts = None
                    elif served == 'drop_set' and loaded and load is not None:
                        drops = technique.get('drops') or 1
                        pct = technique.get('dropPct') or 0.2
                        first = athlete.perform(truth, load, low, high, flames_target, 10, key)
                        parts = [{'reps': first.amount, 'externalLoadKg': load}] if first.amount >= 1 else []
                        total = first.amount
                        bw = truth.info.fraction * athlete.body_weight
                        kg = load
                        if not first.failed:
                            for k in range(1, drops + 1):
                                nxt = truth.info.grid.floor((kg + bw) * (1 - pct) - bw)
                                if nxt < truth.info.grid.minimum:
                                    nxt = truth.info.grid.minimum
                                if nxt >= kg:
                                    break
                                kg = nxt
                                o = athlete.perform(truth, kg, 1, high + 10, 9, 10 if k < drops else rest,
                                                    '%s|%d' % (key, k))
                                if o.amount < 1:
                                    break
                                parts.append({'reps': o.amount, 'externalLoadKg': kg})
                                total += o.amount
                        outcome = _Out(total, first.flames, first.true_rir, first.failed)
                        if not parts:
                            parts = None
                    elif served == 'accentuated_eccentric':
                        outcome = athlete.perform_eccentric(truth, load, low, high, flames_target, rest, key)
                    elif served in ('density', 'for_time') and not hold:
                        goal = technique.get('totalRepsTarget') or high
                        limit = technique.get('durationSeconds')
                        parts = []
                        total = 0
                        seconds = 0
                        last = None
                        k = 0
                        while k < 120 and total < goal:
                            chunk = _round(athlete.capacity_now(truth, load) / 3)
                            if chunk < 1:
                                chunk = 1
                            if chunk > goal - total:
                                chunk = goal - total
                            o = athlete.perform(truth, load, chunk, chunk, 6, 20, '%s|%d' % (key, k))
                            last = o
                            if o.amount < 1:
                                break
                            parts.append({'reps': o.amount})
                            total += o.amount
                            seconds += o.amount * 3 + 20
                            if limit is not None and seconds >= limit:
                                break
                            k += 1
                        elapsed = seconds - 20 if seconds > 20 else seconds
                        outcome = _Out(total, None if last is None else last.flames,
                                       0.0 if last is None else last.true_rir, False)
                        if not parts:
                            parts = None
                        low = total if total < low else low
                    else:
                        outcome = athlete.perform(
                            truth, load, low,
                            high + 200 if (served == 'amrap' and technique.get('durationSeconds') is None) else high,
                            flames_target, rest, key)
                    quality = athlete.quality_of(outcome) if served in ('isometric_hold', 'skill_practice') else None
                    rec = {
                        'exerciseId': ex_id, 'exerciseOrder': order, 'setIndex': i,
                        'kind': item.get('kind') or 'work',
                        'externalLoadKg': load if load is not None else assist_kg,
                        'reps': None if hold else outcome.amount,
                        'seconds': outcome.amount if hold else None,
                        'flames': outcome.flames,
                        'success': (not outcome.failed) and outcome.amount >= low,
                        'failed': outcome.failed,
                        'slotId': item['slotId'],
                        'target': {'repsLow': None if hold else low, 'repsHigh': None if hold else high,
                                   'secondsLow': low if hold else None, 'secondsHigh': high if hold else None,
                                   'loadKg': None if self_selected else load, 'flames': flames_target,
                                   'role': line_role},
                        'technique': None if served == 'standard' else served,
                        'role': line_role, 'parts': parts, 'elapsedSeconds': elapsed,
                        'quality': quality, 'restSeconds': rest,
                        'selfSelected': self_selected, 'repere': bool(target.get('repere')),
                    }
                    done.append(rec)
                    rise = None
                    steps = 0
                    if i == 0 and load is not None:
                        before = last_max_load.get(ex_id)
                        if before is not None:
                            bw = truth.info.fraction * athlete.body_weight
                            rise = (load + bw) / (before + bw) - 1
                            kg = before
                            while kg < load - 1e-9 and steps < 50:
                                kg = truth.info.grid.next(kg, True)
                                steps += 1
                    scheme_rise = None
                    scheme_steps = 0
                    if i == 0 and load is not None and not is_test:
                        sk = '%s|%s|%s' % (item['slotId'], ex_id, high)
                        before = scheme_load.get(sk)
                        if before is not None:
                            bw = truth.info.fraction * athlete.body_weight
                            scheme_rise = (load + bw) / (before + bw) - 1
                            kg = before
                            while kg < load - 1e-9 and scheme_steps < 50:
                                kg = truth.info.grid.next(kg, True)
                                scheme_steps += 1
                        scheme_load[sk] = load
                    if load is not None and (session_max is None or load > session_max):
                        session_max = load
                    total_kg = truth.info.total_load(load, athlete.body_weight) if (loaded and load is not None) else None
                    tour.sets.append({
                        'week': g, 'weekKind': semaine.get('kind'), 'exerciseId': ex_id, 'mode': truth.mode,
                        'exerciseSession': count, 'setIndex': i, 'loadKg': load, 'amount': outcome.amount,
                        'flames': outcome.flames, 'trueRir': outcome.true_rir,
                        'wantRir': flames_to_rir(flames_target), 'failed': outcome.failed,
                        'plannedFailure': planned_failure, 'main': role == 'main', 'open': high > low,
                        'rise': rise, 'targetLow': low, 'targetHigh': high, 'steps': steps,
                        'reachable': athlete.reachable(
                            truth,
                            basis_low if basis_low is not None else (basis_high if basis_high is not None else low),
                            basis_high if basis_high is not None else (basis_low if basis_low is not None else high),
                            flames_to_rir(flames_target)),
                        'simDay': sim_day, 'slotId': item['slotId'], 'role': line_role, 'technique': served,
                        'schemeRise': scheme_rise, 'schemeSteps': scheme_steps, 'attempt': is_attempt,
                        'eventDay': sim_day in event_days,
                        'truePct': None if total_kg is None else total_kg / truth.capacity,
                        'totalKg': total_kg, 'dayMax': day_max, 'quality': quality, 'test': is_test,
                        'openTarget': flames_target == 1, 'capacity': truth.capacity,
                        'trace': target.get('trace'), 'repere': target.get('repere', False),
                    })
                    performed += 1
                athlete.end_exercise(truth)
                if session_max is not None:
                    last_max_load[ex_id] = session_max
                if performed > 0:
                    exercise_sessions[ex_id] = count + 1
                    trained.append((truth, item))
                    tour.cap0.setdefault(ex_id, truth.start_capacity)
                order += 1
            record = {
                'id': 'sim-%d' % sim_day, 'simDay': sim_day, 'week': g,
                'blockIndex': bi, 'weekIndex': wb, 'dayIndex': di,
                'place': lieu, 'healthCheck': bilan, 'sets': done,
                'pains': athlete.session_pains(), 'bodyWeightKg': athlete.body_weight,
                'eventDay': sim_day in event_days,
            }
            endurance.end_day(sim_day)
            politique.terminer(ctx, record)
            if garder_journal:
                tour.journal.append(record)
            tour.servi.append((g, bi, wb, di, seance['items']))
            tour.sessions_done += 1
            for truth, item in trained:
                ex_id = item['exerciseId']
                basis = item
                for it in ecrits:
                    if it['slotId'] == item['slotId'] and it['exerciseId'] == ex_id:
                        basis = it
                flames = basis.get('targetFlames')
                hold = truth.mode == 'hold'
                low = basis.get('secondsLow') if hold else basis.get('repsLow')
                high = basis.get('secondsHigh') if hold else basis.get('repsHigh')
                lo = low if low is not None else (high if high is not None else 8)
                hi = high if high is not None else (low if low is not None else 8)
                n = (lo + hi) / 2 + (3.0 if flames is None else flames_to_rir(flames))
                est = politique.estimer(ex_id, n)
                if est is None:
                    continue
                loaded = truth.mode == 'loaded'
                tour.estimates.append({
                    'week': g, 'simDay': sim_day, 'exerciseId': ex_id, 'mode': truth.mode,
                    'exerciseSession': exercise_sessions.get(ex_id, 0),
                    'capacity': est[0], 'truth': truth.capacity, 'relSd': est[1],
                    'operational': est[2],
                    'truthOperational': truth.capacity * truth.share(n) if loaded else truth.capacity,
                    'main': ctx.role_de(item['slotId']) == 'main',
                    'low': est[3] if len(est) > 3 else None, 'high': est[4] if len(est) > 4 else None,
                })
        athlete.end_week()
        politique.fin_semaine(g, tour)
    for t in athlete.truths:
        first = t.first_day
        last = t.last_day
        tour.cap_fin[t.info.id] = t.capacity
        if first is None or last is None or last - first < 21:
            continue
        tour.gain[t.info.id] = math.log(t.last_capacity / t.first_capacity) / ((last - first) / 7)
    tour.pain_aggravations = athlete.pain_aggravations
    tour.pain_flares = athlete.pain_flares
    tour.endurance_overuse = endurance.overuse
    tour.worst_run_spike = endurance.worst_spike
    tour.extra['endurance'] = (endurance.start_easy_minutes, endurance.easy_minutes,
                               endurance.start_wod, endurance.wod)
    politique.fin(tour)
    return tour


class _Out(object):
    __slots__ = ('amount', 'flames', 'true_rir', 'failed')

    def __init__(self, amount, flames, true_rir, failed):
        self.amount = amount
        self.flames = flames
        self.true_rir = true_rir
        self.failed = failed


def _round(x):
    return int(math.floor(x + 0.5)) if x >= 0 else -int(math.floor(-x + 0.5))


def _surcharger(athlete, surcharges):
    """Banc adversarial : multiplicateurs appliqués à la vérité d'un
    exercice au moment où elle est tirée (les mêmes champs publics que la
    politique enveloppe du banc Dart modifie)."""
    origine = athlete.truth_of

    def truth_of(ex_id):
        connu = ex_id in athlete._truth
        t = origine(ex_id)
        if t is not None and not connu:
            m = surcharges.get(ex_id) or surcharges.get('*')
            if m:
                t.capacity *= m.get('capacity', 1.0)
                t.start_capacity = t.capacity
                t.curve_b *= m.get('curveB', 1.0)
                t.slope *= m.get('slope', 1.0)
                t.power *= m.get('power', 1.0)
                t.fatigue_scale *= m.get('fatigueScale', 1.0)
                t.hold_share *= m.get('holdShare', 1.0)
        return t
    athlete.truth_of = truth_of


class Politique(object):
    """Interface d'une politique du banc Python (`SimPolicy`)."""

    nom = 'abstraite'

    def debut(self, saison, profil, livre):
        pass

    def changement_profil(self, semaine, profil):
        pass

    def debut_semaine(self, semaine):
        pass

    def seance_manquee(self, semaine, sim_day):
        pass

    def planifier(self, ctx):
        return {'items': ctx.ecrit['items']}

    def prochaine_serie(self, ctx, item, index, done):
        return cible_de(item, index)

    def cran_change(self, ex_id, change):
        pass

    def terminer(self, ctx, record):
        pass

    def estimer(self, ex_id, n):
        return None

    def fin_semaine(self, semaine, tour):
        pass

    def fin(self, tour):
        pass
