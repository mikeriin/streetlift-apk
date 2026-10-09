# -*- coding: utf-8 -*-
"""Prescription de la séance et conseil série par série de Koach 1.0
(CONTRAT_1_0.md § 3 `plan`, § 8 garde-fous) : charge et volume ajustés à
chaque séance depuis l'a posteriori, test adaptatif (charge la plus
informative dans la zone prescrite), tentatives choisies par probabilité de
réussite, le tout sous les contraintes dures de sécurité.
"""
import math

from .numerique import norm_cdf, norm_ppf, clamp
from .modele import FI, HH
from .securite import SEMAINES_VERROUILLEES

INF = math.inf


def rir_de_flammes(f):
    if f is None:
        return None
    return 0.0 if f >= 10 else (11 - f) / 2.0


def flammes_de_rir(rir):
    if rir >= 5:
        return 1
    h = math.ceil(rir * 2 - 0.5)
    if h <= 0:
        return 10
    if h == 1:
        return 9
    return 11 - h


class Grille(object):
    """Grille de charges d'un exercice (pas, minimum, règle des haltères)."""

    EPS = 1e-9

    def __init__(self, pas, minimum, halteres=False):
        self.pas = pas
        self.minimum = minimum
        self.halteres = halteres

    def _pas(self, kg):
        if self.halteres:
            return self.pas if kg < 10 - self.EPS else 2.0
        return self.pas

    def plancher(self, kg):
        if self.halteres and kg > 10 + self.EPS:
            v = 10 + math.floor((kg - 10) / 2.0 + self.EPS) * 2.0
        elif kg <= self.minimum:
            v = self.minimum
        else:
            v = self.minimum + math.floor((kg - self.minimum) / self.pas + self.EPS) * self.pas
        return self.minimum if v < self.minimum else v

    def suivant(self, kg):
        b = self.plancher(kg)
        if b > kg + self.EPS:
            return b
        return b + self._pas(b)

    def precedent(self, kg):
        b = self.plancher(kg)
        if b < kg - self.EPS:
            return b
        if self.halteres:
            d = self.pas if b <= 10 + self.EPS else 2.0
        else:
            d = self.pas
        v = b - d
        return self.minimum if v < self.minimum else v

    def proche(self, kg):
        lo = self.plancher(kg)
        hi = self.suivant(lo)
        return lo if (kg - lo) <= (hi - kg) else hi


class Memoire(object):
    """Ce que la prescription retient d'un exercice (recalculé du journal)."""

    __slots__ = ('jour', 'charge_max', 'reps_max', 'sec_max', 'sec_total', 'echec', 'schemas',
                 'jours', 'cran_jour', 'haut_de_plage', 'facile', 'bas_manque', 'meilleur_sec',
                 'charge_seance', 'reps_seance', 'sec_seance', 'echec_seance', 'total_seance',
                 'faciles_seance', 'charges_reussies', 'flammes_seance', 'charge_derniere')

    def __init__(self):
        self.jour = None
        self.charge_max = None
        self.reps_max = None
        self.sec_max = None
        self.sec_total = None
        self.echec = False
        self.schemas = {}
        self.jours = []
        self.cran_jour = None
        self.haut_de_plage = 0
        self.facile = 0
        self.bas_manque = 0
        self.meilleur_sec = None
        self.charge_seance = None
        self.reps_seance = None
        self.sec_seance = None
        self.echec_seance = 0
        self.total_seance = 0.0
        self.faciles_seance = 0
        self.charges_reussies = []
        self.flammes_seance = None
        self.charge_derniere = None   # plus lourde charge du dernier passage de l'exercice


class Seances(object):
    """Prescription de séance et conseil d'entre-séries."""

    def __init__(self, params, modele, garde, fiches):
        self.p = params
        self.s = params['securite']
        self.m = modele
        self.g = garde
        self.fiches = fiches
        self.memoire = {}
        self.jour = 0
        self.palier = 0
        self.raisons = []
        self.courses = []        # (jour, secondes) des 30 derniers jours
        self.jours_durs = []     # jours de conditionnement dur
        self.derniere_seance = None
        self.coupure = 0
        self.contexte = None
        self.plans = {}          # slotId -> plan de l'item servi (séance en cours)
        self.dose_zone = {}      # zone -> {semaine: séries faites des mouvements qui la provoquent}
        self.zones_ex = {}       # id -> (niveaux de zone, zones provoquées), vu à la prescription
        self.budget_zone = {}    # zone en reprise -> séries encore permises cette semaine

    def mem(self, ex_id):
        if ex_id not in self.memoire:
            self.memoire[ex_id] = Memoire()
        return self.memoire[ex_id]

    # ------------------------------------------------------------------
    # Prévisions
    # ------------------------------------------------------------------
    def _garde_serie(self, t):
        return self.m.garde_de(t)

    def charge_pour(self, ex_id, reps, rir, prudence=0.0):
        """Charge externe (hors grille) pour [reps] répétitions à [rir] en
        réserve aujourd'hui, au quantile prudent ; None si la piste n'est pas
        une charge."""
        t = self.m.piste(ex_id)
        if t is None or t.type != 'charge':
            return None
        mu, sd = self.m.capacite_du_jour(ex_id)
        lam, k = self.m.courbe(t)
        r = (reps + rir) / self._garde_serie(t)
        total = math.exp(mu - prudence * sd - self.m._g(lam, k, r))
        return total - t.fraction * self.m.poids_kg

    def charge_de_part(self, ex_id, part, du_jour=False):
        """Charge totale qui correspond, pour CET athlète, à une part écrite
        du 1RM. Une part du 1RM est lue comme un niveau d'effort : le nombre
        de répétitions qu'elle permet sur la courbe de population (a priori
        du fichier de paramètres) ; la charge est celle que la courbe de
        l'athlète associe à ce nombre de répétitions. Pour un athlète à la
        courbe typique, c'est part × 1RM."""
        m = self.m
        t = m.piste(ex_id)
        mu = m.capacite_du_jour(ex_id)[0] if du_jour else m.capacite(ex_id)[0]
        if part >= 1.0:
            return math.exp(mu) * part
        ap = self.p['a_priori']
        lam0 = ap['courbe_forme'][0]
        k0 = ap['courbe_echelle'][0] + (ap['courbe_bas_du_corps'] if t.bas else 0.0)
        x = -math.log(part)
        # Inverse de g sur la courbe de population (Newton, pas fixes).
        r = 1.0 + x / m._dg(lam0, k0, 1.0)
        for _ in range(12):
            r -= (m._g(lam0, k0, r) - x) / m._dg(lam0, k0, r)
            if r < 1.0:
                r = 1.0
            if r > 200.0:
                r = 200.0
        lam, k = m.courbe(t)
        return math.exp(mu - m._g(lam, k, r))

    def reps_prevues(self, ex_id, externe, rir):
        """Répétitions prévues à [rir] en réserve avec la charge [externe]."""
        t = self.m.piste(ex_id)
        if t is None:
            return None
        mu, sd = self.m.capacite_du_jour(ex_id)
        if t.type == 'charge':
            masse = self.m.masse(t, externe)
            if masse <= 0:
                return None
            r = self.m.reps_a(t, mu - math.log(masse))
        elif t.type == 'reps':
            r = math.exp(mu)
        else:
            return None
        return r * self._garde_serie(t) - rir

    def secondes_prevues(self, ex_id, rir):
        t = self.m.piste(ex_id)
        if t is None or t.type != 'tenue':
            return None
        mu, sd = self.m.capacite_du_jour(ex_id)
        hh = clamp(self.m.m[HH], 0.03, 0.3) * math.exp(clamp(self.m.m[t.idx + 1], -1.0, 1.0))
        f = 1.0 - hh * rir
        if f < 0.15:
            f = 0.15
        return math.exp(mu) * self._garde_serie(t) * f

    def proba_reussite(self, ex_id, externe, reps=1):
        """P(réussir [reps] répétitions avec la charge [externe] aujourd'hui)."""
        t = self.m.piste(ex_id)
        if t is None or t.type != 'charge':
            return None
        mu, sd = self.m.capacite_du_jour(ex_id)
        lam, k = self.m.courbe(t)
        besoin = math.log(self.m.masse(t, externe)) + self.m._g(lam, k, reps / self._garde_serie(t))
        return norm_cdf((mu - besoin) / max(sd, 0.005))

    def information(self, ex_id, externe, reps):
        """Information attendue d'une série sur la capacité de l'exercice :
        variance retirée à ln capacité par l'observation de la réserve perçue
        à cette charge (test adaptatif, cahier § 5)."""
        m = self.m
        t = m.piste(ex_id)
        if t is None or t.type != 'charge':
            return 0.0
        masse = m.masse(t, externe)
        if masse <= 0:
            return 0.0
        idx, co, pr, R, v = m._lin_force(t, m.m, math.log(masse), reps, m._intra(t), False, True)
        _, var, ph = m._stats(m.m, m.P, idx, co)
        hi, hc = m._h_capacite(t, jour=False)
        cov = 0.0
        for i, c in zip(hi, hc):
            cov += c * ph[i]
        r = v if v > 0 else 0.0
        s2 = m.bruit_rir_de(r if r < 8 else 8.0, R) ** 2
        return cov * cov / (var + s2)

    # ------------------------------------------------------------------
    # Séance
    # ------------------------------------------------------------------
    def ouvrir(self, jour, bilan, contexte):
        """Début de séance : palier du bilan, coupure, verrous de semaine."""
        self.jour = jour
        self.contexte = contexte
        if contexte and contexte.get('semaine') is not None:
            self.g.noter_semaine(contexte['semaine'], contexte.get('genre'), contexte.get('intention'))
        self.palier, self.decalage = self.g.palier_bilan(bilan)
        self.coupure = 0 if self.derniere_seance is None else jour - self.derniere_seance
        self.raisons = []
        self.plans = {}
        self.budget_zone = {}
        for z in list(self.g.zones):
            dz = self.g.zones[z]
            if dz.arret_leve is not None and not self.g.arret(z) \
                    and 0 <= jour - dz.arret_leve <= self.s['reprise_surveillance_j']:
                b = self._budget_reprise(z)
                if b is not None:
                    self.budget_zone[z] = b
        for mem in self.memoire.values():
            mem.charge_seance = None
            mem.reps_seance = None
            mem.sec_seance = None
            mem.echec_seance = 0
            mem.total_seance = 0.0
            mem.faciles_seance = 0

    def _dose_semaine(self, z, semaine):
        return self.dose_zone.get(z, {}).get(semaine, 0)

    def _budget_reprise(self, z):
        """Séries encore permises cette semaine, tous mouvements qui
        provoquent la zone [z] confondus, pendant la reprise graduée. Plus
        prudent que 0.3.1 (part du volume écrit) : la dose hebdomadaire de la
        zone repart d'une fraction de l'habitude d'avant la douleur et ne
        monte pas de plus d'un quart (ou d'une série) d'une semaine de charge
        à la suivante, quel que soit le volume écrit."""
        g = self.g
        d = g.zones.get(z)
        s = self.s
        if d is None or d.arret_leve is None:
            return None
        semaine = g.semaine
        # Habitude : moyenne des 4 dernières semaines de charge avant le
        # premier signalement de l'épisode.
        debut = d.signalements[0][0] // 7 if d.signalements else semaine
        for (j, i) in d.signalements:
            if i >= s['arret_persistance_min']:
                debut = j // 7
                break
        avant = [self._dose_semaine(z, w) for w in range(debut - 4, debut) if w >= 0 and g.semaines.get(w, False)]
        habitude = sum(avant) / len(avant) if avant else None
        # Dernière semaine de charge depuis la levée.
        premiere = d.arret_leve // 7
        precedente = None
        for w in range(semaine - 1, premiere - 1, -1):
            if g.semaines.get(w, False):
                precedente = self._dose_semaine(z, w)
                break
        if precedente is None or precedente <= 0:
            if habitude is None:
                return None
            total = int(math.floor(s['reprise_dose_depart'] * habitude + 1e-9))
            if total < 1:
                total = 1
        else:
            total = max(precedente + 1, int(math.floor(precedente * (1 + s['reprise_dose_hausse']) + 1e-9)))
        return total - self._dose_semaine(z, semaine)

    def verrouillee(self):
        c = self.contexte or {}
        return (c.get('intention') or c.get('genre')) in SEMAINES_VERROUILLEES or c.get('genre') in ('deload', 'test', 'intro')

    def prescrire(self, items, grilles, zones, roles):
        """Sert la séance écrite [items] (prescriptions du plan de Koach pour
        le jour). [grilles] : id -> Grille ; [zones] : id -> (niveaux de zone,
        zones provoquées) ; [roles] : slotId -> rôle. Renvoie les items
        servis (mêmes champs, plus `koach`)."""
        out = []
        testes = set()
        for ex_id, zz in zones.items():
            self.zones_ex[ex_id] = zz
        for item in items:
            servi = self._item(item, grilles.get(item['exerciseId']), zones.get(item['exerciseId']),
                               roles.get(item['slotId']))
            if servi is None:
                continue
            plan = self.plans.get(item['slotId'])
            ex_id = item['exerciseId']
            if plan is not None and ex_id not in testes and item.get('kind') == 'work':
                vt = self._vrai_test(servi, plan, self.m.pistes.get(ex_id))
                if vt is not None:
                    # Vrai test programmé : montée de charge servie comme un
                    # test, à la place d'une série de travail.
                    testes.add(ex_id)
                    ta = self.p['test_adaptatif']
                    slot = item['slotId'] + '.t'
                    test = {'slotId': slot, 'exerciseId': ex_id, 'sets': ta['rampe_series_max'] + (2 if vt[0] == 1 else 0),
                            'repsLow': vt[0], 'repsHigh': vt[0], 'targetFlames': flammes_de_rir(vt[1]),
                            'restSeconds': max(item.get('restSeconds') or 0, ta['repos_test_s']),
                            'kind': 'test', 'test': {'kind': 'rep_max', 'targetRir': vt[1], 'attempts': ta['rampe_series_max']},
                            'loadBasis': item.get('loadBasis'), 'toCalibrate': False,
                            'reasons': [{'code': 'koach.vrai_test', 'params': {}}], 'koach': 'vrai_test'}
                    p2 = dict(plan)
                    p2.update({'test': True, 'rampe': vt, 'echecs': 0, 'ecrit': test, 'charge_item': None})
                    self.plans[slot] = p2
                    self._raison('koach.vrai_test', exercice=ex_id)
                    out.append(test)
                    if servi['sets'] >= 3:
                        servi['sets'] -= 1
                    plan['apres_test'] = True
            out.append(servi)
        return out

    def _raison(self, code, **params):
        self.raisons.append({'code': code, 'params': params})

    def _item(self, item, grille, zone, role):
        ex_id = item['exerciseId']
        fiche = self.fiches.get(ex_id) or {}
        typ = fiche.get('type')
        est_test = item.get('kind') == 'test'
        echauffement = item.get('kind') == 'warmup'
        c = self.contexte or {}
        evenement = bool(c.get('jour_evenement'))
        niveaux, hits = zone if zone else ({}, set())
        cond = self.g.conduite(niveaux, hits, est_test=est_test, depuis_jour=self.mem(ex_id).jour)
        if cond['retire']:
            self._raison('koach.douleur_retrait', exercice=ex_id, zone=cond['zone'], cause=cond['raison'])
            return None
        if est_test and self.palier >= 1 and not evenement:
            self._raison('koach.test_reporte', exercice=ex_id, cause='bilan_bas')
            return None
        servi = dict(item)
        plan = {'cond': cond, 'role': role, 'test': est_test, 'type': typ, 'grille': grille,
                'sans_hausse': cond['sans_hausse'] or self.palier >= 1, 'rir_bonus': cond['rir'],
                'rir_min': cond['rir_min'], 'part_max': cond['part_max'], 'echecs': 0,
                'baisse': 1.0, 'verrou': self.verrouillee(), 'ecrit': item, 'tete': None,
                'repere': False}
        if self.palier == 1:
            plan['rir_bonus'] += self.s['bilan_rir_bonus']
        elif self.palier == 2:
            plan['rir_bonus'] += 2 * self.s['bilan_rir_bonus']
            plan['rir_min'] = max(plan['rir_min'] or 0.0, self.s['bilan_bas_rir_min'])
        series = item.get('sets', 0)
        if not est_test and not echauffement and typ in ('charge', 'reps', 'tenue'):
            f = cond['series']
            if f < 1.0:
                series = max(1, int(math.floor(series * f + 1e-9)))
            if self.coupure >= self.s['coupure_j']:
                n = int(math.floor(series * self.s['coupure_series'] + 0.5))
                if 1 <= n < series:
                    series = n
                    self._raison('koach.reprise_coupure', exercice=ex_id, jours=self.coupure)
            if self.palier == 2 and item.get('targetFlames') is not None:
                plancher = 3 if role == 'main' else 2
                if series > plancher:
                    series -= 1
        if not echauffement:
            for z in sorted(hits):
                if z in self.budget_zone:
                    reste = self.budget_zone[z]
                    if series > reste:
                        series = reste if reste > 0 else 0
                        self._raison('koach.reprise_dose', exercice=ex_id, zone=z)
            if series <= 0:
                self._raison('koach.douleur_retrait', exercice=ex_id, zone=cond['zone'], cause='reprise_dose')
                return None
            for z in sorted(hits):
                if z in self.budget_zone:
                    self.budget_zone[z] -= series
        servi['sets'] = series
        self.plans[item['slotId']] = plan
        if typ in ('charge', 'reps', 'tenue') and not echauffement:
            servi['setTargets'] = None
        return servi

    # ------------------------------------------------------------------
    # Série suivante
    # ------------------------------------------------------------------
    def rir_cible(self, item, plan):
        f = item.get('targetFlames')
        rir = 2.5 if f is None else rir_de_flammes(f)
        rir += plan['rir_bonus']
        if plan['rir_min'] is not None and rir < plan['rir_min']:
            rir = plan['rir_min']
        if rir > 5:
            rir = 5.0
        return rir

    def cible(self, item, index, faites):
        """Cible de la série [index] de l'item servi : dictionnaire
        {repsLow, repsHigh, secondsLow, secondsHigh, loadKg, flames, role} ou
        None pour arrêter l'exercice."""
        plan = self.plans.get(item['slotId'])
        if plan is None:
            return self._ecrit(item, index)
        typ = plan['type']
        if item.get('kind') == 'warmup' or typ not in ('charge', 'reps', 'tenue'):
            return self._ecrit(item, index)
        if plan['echecs'] >= self.s['echecs_arret'] and not plan['test']:
            self._raison('koach.arret_exercice', exercice=item['exerciseId'], cause='echecs')
            return None
        if plan['test']:
            return self._cible_test(item, index, plan)
        if typ == 'charge':
            return self._cible_charge(item, index, plan)
        if typ == 'reps':
            return self._cible_reps(item, index, plan)
        return self._cible_tenue(item, index, plan)

    def _ecrit(self, item, index):
        return {'repsLow': item.get('repsLow'), 'repsHigh': item.get('repsHigh'),
                'secondsLow': item.get('secondsLow'), 'secondsHigh': item.get('secondsHigh'),
                'loadKg': item.get('startLoadKg'), 'flames': item.get('targetFlames'), 'role': None}

    def _plages(self, item, index):
        """Plage de répétitions de la série [index] (technique série de
        tête : les séries suivantes prennent la plage des séries allégées)."""
        lo = item.get('repsLow')
        hi = item.get('repsHigh')
        tech = item.get('technique') or {}
        if tech.get('kind') == 'top_set_backoff' and index >= 1:
            lo = tech.get('backoffRepsLow') or lo
            hi = tech.get('backoffRepsHigh') or hi
        if lo is None:
            lo = hi
        if hi is None:
            hi = lo
        return lo, hi

    def _mesure_utile(self, item, plan, t):
        """Vrai si une mesure près de l'échec est utile et permise : intervalle
        à 90 % de la capacité au-delà de ± 6 % (cahier § 5), rien de mesuré
        depuis 14 jours, et aucune des contre-indications de 0.3.1 (A8.3) :
        semaine verrouillée, échéance proche, jour léger, bilan bas, zone
        douloureuse ou en reprise, échec dans la séance, technique écrite."""
        ta = self.p['test_adaptatif']
        c = self.contexte or {}
        if item.get('sets', 0) < 1 or plan['test'] or item.get('kind') == 'warmup':
            return False
        if plan['verrou'] or plan['sans_hausse'] or plan['echecs'] > 0 or plan['cond']['raison']:
            return False
        if c.get('jours_avant_echeance') is not None and c['jours_avant_echeance'] <= 14:
            return False
        if item.get('dayStress') == 'light':
            return False
        if (item.get('technique') or {}).get('kind') not in (None, 'standard', 'top_set_backoff', 'isometric_hold'):
            return False
        cap = self.m.capacite(item['exerciseId'])
        if 1.6448536269514722 * cap[1] <= ta['intervalle_declenchement']:
            return False
        if t.dernier_test_jour is not None and self.jour - t.dernier_test_jour < ta['jours_min_entre_tests']:
            return False
        if self.g.niveau == 0 and t.seances < 3:
            return False
        return True

    def _repere(self, item, index, plan, t):
        """Série repère (test adaptatif) : dernière série de l'exercice
        ouverte jusqu'à la réserve de repère (1,5 ; 2 pour un débutant)."""
        if index != item.get('sets', 0) - 1 or plan.get('vrai_test'):
            return None
        if not self._mesure_utile(item, plan, t):
            return None
        return 2.0 if self.g.niveau == 0 else 1.5

    def _vrai_test(self, item, plan, t):
        """Vrai test (cahier § 5) d'un mouvement principal chargé dont
        l'intervalle dépasse ± 6 % : une montée de charge de quelques
        répétitions jusqu'à la réserve du test, avant le travail du jour.
        Renvoie (répétitions, réserve) ou None."""
        ta = self.p['test_adaptatif']
        if plan['role'] not in ('main', 'secondary') or plan['type'] != 'charge':
            return None
        if item.get('sets', 0) < 2:
            return None
        if t is None or t.seances < 1 or not self._mesure_utile(item, plan, t):
            return None
        # Grille trop grossière pour une montée (cran de plus de 10 % de la
        # charge totale) : la mesure se fait en répétitions (série repère).
        grille = plan['grille']
        mem = self.mem(item['exerciseId'])
        ref = mem.charge_max if mem.charge_max is not None else None
        if grille is None or ref is None:
            return None
        bw = t.fraction * self.m.poids_kg
        if grille.suivant(ref) + bw > (ref + bw) * (1 + ta['rampe_pas']) + 1e-9:
            return None
        if self.g.niveau == 0:
            return ta['test_reps_debutant'], ta['test_rir_debutant']
        if self.g.niveau >= 2:
            return ta['test_reps_avance'], ta['test_rir_avance']
        return ta['test_reps'], ta['test_rir']

    def _cible_charge(self, item, index, plan):
        ex_id = item['exerciseId']
        m = self.m
        t = m.piste(ex_id)
        mem = self.mem(ex_id)
        grille = plan['grille']
        lo, hi = self._plages(item, index)
        if lo is None or t is None or grille is None:
            return self._ecrit(item, index)
        rir = self.rir_cible(item, plan)
        flammes = flammes_de_rir(rir)
        cap = m.capacite(ex_id)
        tech = item.get('technique') or {}
        # Exercice jamais mesuré et a priori vague : l'utilisateur choisit sa
        # première charge (calibrage), Koach l'apprend.
        if t.mesures == 0 and cap[1] > 0.12:
            return {'repsLow': lo, 'repsHigh': hi, 'loadKg': None, 'flames': flammes, 'role': None}
        reps = hi if hi == lo else (lo + hi) / 2.0
        pr = self.p['planification']['prudence_charge']
        prudence = pr[1] if t.seances > 3 else pr[0]
        voulu = self.charge_pour(ex_id, reps, rir, prudence)
        trace = ['modele %.1f (rir %.1f)' % (voulu, rir)]
        if tech.get('kind') == 'top_set_backoff' and index >= 1 and plan['tete'] is not None:
            # Séries allégées : part de la série de tête, corrigée par ce
            # que la série de tête vient d'apprendre.
            drop = tech.get('backoffDropPct') or 0.08
            tete = plan['tete'] + t.fraction * m.poids_kg
            voulu = min(voulu, tete * (1 - drop) - t.fraction * m.poids_kg)
            trace.append('allegee %.1f' % voulu)
        # Intensité : la charge vise l'effort écrit (répétitions et réserve),
        # déplacé par la planification dans son plafond de ±5 % ; la part
        # écrite du 1RM borne par le haut comme en 0.3.1 : charge écrite en
        # semaine verrouillée, chez le débutant et à 85 % et plus, couloir de
        # +15 % sinon.
        part = item.get('percentOfOneRm')
        un_rm = math.exp(cap[0])
        bw = t.fraction * m.poids_kg
        ecart = item.get('koachIntensite', 0.0)
        if ecart and not plan['verrou']:
            plaf = self.p['planification']['plafond_intensite']
            voulu = (voulu + bw) * (1 + clamp(ecart, -plaf, plaf)) - bw
        if part is not None and not (tech.get('kind') == 'top_set_backoff' and index >= 1):
            if plan['verrou'] or self.g.niveau == 0 or part >= self.s['couloir_part_lourde']:
                haut = self.charge_de_part(ex_id, part) - bw
            else:
                haut = self.charge_de_part(ex_id, part * (1 + self.s['couloir_haut_max'])) - bw
            if voulu > haut:
                voulu = haut
                trace.append('part ecrite %.3f%s -> %.1f' % (part, ' verrou' if plan['verrou'] else '', voulu))
        if plan['part_max'] is not None and voulu > self.charge_de_part(ex_id, plan['part_max']) - bw:
            voulu = self.charge_de_part(ex_id, plan['part_max']) - bw
        if lo == hi == 1 and not plan['test']:
            plafond = self.s['simple_part_max_bilan_bas'] if self.palier >= 1 else self.s['simple_part_max']
            haut_simple = self.charge_de_part(ex_id, plafond, du_jour=True) - bw
            if voulu > haut_simple:
                voulu = haut_simple
        charge = grille.proche(max(voulu, grille.minimum))
        # Test adaptatif : parmi les charges de la zone prescrite (réserve à
        # moins de la tolérance de la cible), la plus informative.
        ta = self.p['test_adaptatif']
        if index == 0 and not plan['sans_hausse'] and not plan['verrou'] and t.seances >= 1:
            meilleur = charge
            info0 = self.information(ex_id, charge, reps)
            for cand in (grille.precedent(charge), grille.suivant(charge)):
                r_prev = self.reps_prevues(ex_id, cand, 0.0)
                if r_prev is None:
                    continue
                ecart_rir = abs((r_prev - reps) - rir)
                if ecart_rir <= ta['ecart_rir_tolere'] and cand <= voulu * 1.0 + grille._pas(charge):
                    inf = self.information(ex_id, cand, reps)
                    if inf > info0 * (1 + 0.02):
                        meilleur, info0 = cand, inf
            charge = meilleur
        avant_bornes = charge
        charge = self._bornes_hausse(ex_id, item, charge, plan, t, grille, hi, index)
        if charge != avant_bornes:
            trace.append('hausse bornee %.2f -> %.2f' % (avant_bornes, charge))
        # Dans la séance : après un échec, -7,5 % gardé ; jamais plus lourd
        # un jour verrouillé.
        if plan['baisse'] < 1.0 and plan.get('charge_item') is not None:
            tete = (plan['charge_item'] + bw) * plan['baisse'] - bw
            if charge > tete:
                charge = grille.plancher(max(tete, grille.minimum))
        if index >= 1 and plan.get('charge_item') is not None and (plan['sans_hausse'] or plan['echecs'] > 0):
            if charge > plan['charge_item']:
                charge = plan['charge_item']
        if index >= 1 and plan.get('charge_item') is not None and tech.get('kind') != 'top_set_backoff':
            # D'une série à l'autre : -15 % / +5 % au plus, un cran permis.
            haut = (plan['charge_item'] + bw) * 1.05 - bw
            bas = (plan['charge_item'] + bw) * 0.85 - bw
            if charge > haut:
                charge = max(grille.plancher(haut), min(charge, grille.suivant(plan['charge_item'])))
            if charge < bas:
                charge = grille.proche(bas)
        if (plan['sans_hausse'] or plan['cond']['raison']) and mem.charge_derniere is not None \
                and charge > mem.charge_derniere:
            # Zone douloureuse ou en reprise, bilan bas : jamais plus lourd
            # que le dernier passage de l'exercice (invariant I3 de 0.3.1).
            charge = mem.charge_derniere
            trace.append('pas de hausse (douleur ou bilan) -> %.2f' % charge)
        if charge < grille.minimum:
            charge = grille.minimum
        if index == 0:
            plan['tete'] = charge
        rep = self._repere(item, index, plan, t)
        if rep is not None:
            plan['repere'] = True
            self._raison('koach.serie_repere', exercice=ex_id)
            # Charge du repère : celle qui laisse la réserve de repère au
            # haut de la plage (la plus informative de la zone), sans
            # dépasser de plus de 10 % la plus lourde barre récente.
            voulu_r = self.charge_pour(ex_id, hi, rep, 0.5)
            recente = plan['tete'] if plan['tete'] is not None else charge
            for (j, c, r) in mem.charges_reussies:
                if self.jour - j <= 42 and c > recente:
                    recente = c
            plafond_r = (recente + bw) * (1 + self.p['test_adaptatif']['repere_hausse']) - bw
            charge_r = grille.plancher(max(min(voulu_r, plafond_r), grille.minimum))
            if charge_r < charge:
                charge_r = charge
            return {'repsLow': lo, 'repsHigh': hi + self.p['test_adaptatif']['reps_ouvertes'],
                    'loadKg': charge_r, 'flames': flammes_de_rir(rep), 'role': None, 'repere': True,
                    'trace': ['repere %.1f (modele %.1f, plafond %.1f)' % (charge_r, voulu_r, plafond_r)]}
        return {'repsLow': lo, 'repsHigh': hi, 'loadKg': charge, 'flames': flammes, 'role': None,
                'trace': trace}

    def _bornes_hausse(self, ex_id, item, charge, plan, t, grille, hi, index):
        """Bornes de hausse d'une séance à l'autre (règles A7 de 0.3.1) :
        10/5/5/5 % à schéma égal (moitié sur zone fragile), un cran toujours
        permis ; aucune hausse après échec, douleur ou bilan bas."""
        if index > 0:
            return charge
        mem = self.mem(ex_id)
        bw = t.fraction * self.m.poids_kg
        cle = (item['slotId'], hi)
        avant = mem.schemas.get(cle)
        fragile = bool(plan['cond']['zone']) or item.get('koachFragile', False)
        role = plan['role']
        if avant is not None:
            if plan['sans_hausse'] or avant[1]:
                if charge > avant[0]:
                    charge = avant[0]
            else:
                h = self.g.hausse_max(fragile)
                if role not in ('main', 'secondary'):
                    h *= 2
                haut = (avant[0] + bw) * (1 + h) - bw
                if charge > haut:
                    cran = grille.suivant(avant[0])
                    charge = max(grille.plancher(haut), min(charge, cran))
        else:
            # Schéma nouveau à cet emplacement : pas plus de 10 % (ou un
            # cran) au-dessus de la plus lourde barre réussie des 42 derniers
            # jours, +2,5 % par répétition de moins (4 au plus).
            haut = None
            for (j, c, r) in mem.charges_reussies:
                if self.jour - j > self.s['barre_recente_j']:
                    continue
                moins = r - hi
                if moins < 0:
                    moins = 0
                if moins > self.s['schema_change_reps_max']:
                    moins = self.s['schema_change_reps_max']
                if plan['sans_hausse'] or fragile:
                    borne = c
                else:
                    borne = (c + bw) * (1 + self.s['premiere_hausse']) * (1 + self.s['schema_change_part'] * moins) - bw
                    borne = max(grille.plancher(borne), grille.suivant(c))
                if haut is None or borne > haut:
                    haut = borne
            if haut is not None and charge > haut:
                charge = haut
        return charge

    def _cible_reps(self, item, index, plan):
        ex_id = item['exerciseId']
        t = self.m.piste(ex_id)
        mem = self.mem(ex_id)
        lo, hi = self._plages(item, index)
        if lo is None or t is None:
            return self._ecrit(item, index)
        rir = self.rir_cible(item, plan)
        flammes = flammes_de_rir(rir)
        if t.mesures == 0:
            return {'repsLow': lo, 'repsHigh': hi, 'loadKg': None, 'flames': flammes, 'role': None}
        prevu = self.reps_prevues(ex_id, None, rir)
        mu, sd = self.m.capacite_du_jour(ex_id)
        sur = int(math.floor(prevu * math.exp(-0.5 * sd) + 0.3))
        haut = hi
        bas = lo
        # Trop facile au haut de la plage : plage étendue (au plus le double,
        # 30 répétitions), en semaine de charge seulement.
        libre = not (plan['verrou'] or plan['sans_hausse'] or plan['cond']['raison'] or plan['echecs'] > 0)
        fiche = self.fiches.get(ex_id) or {}
        if libre and sur > hi and not item.get('technique') and fiche.get('type_charge') != 'elastique':
            haut = min(sur, 2 * hi, 30)
        if sur < bas:
            # Le bas de la plage ne laisse pas la réserve : la série s'arrête
            # à la réserve visée (cible au ressenti), sans viser l'échec.
            bas = max(1, sur)
        # Verrous : jamais au-dessus de la plus grande série de la dernière
        # séance après échec, douleur, bilan bas ; zone récente : +10 %.
        if (plan['sans_hausse'] or mem.echec) and mem.reps_max is not None and haut > max(mem.reps_max, bas):
            haut = max(mem.reps_max, 1)
        hq = plan['cond']['hausse_quantite']
        if hq is not None and mem.reps_max is not None:
            plaf = max(int(math.floor(mem.reps_max * (1 + hq))), mem.reps_max + 1)
            if haut > plaf:
                haut = plaf
        if plan['echecs'] > 0 and mem.reps_seance is not None and haut > mem.reps_seance:
            haut = max(1, mem.reps_seance)
        if bas > haut:
            bas = haut
        rep = self._repere(item, index, plan, t)
        if rep is not None:
            plan['repere'] = True
            self._raison('koach.serie_repere', exercice=ex_id)
            return {'repsLow': bas, 'repsHigh': min(max(2 * hi, haut), 60), 'loadKg': None,
                    'flames': flammes_de_rir(rep), 'role': None, 'repere': True}
        return {'repsLow': bas, 'repsHigh': haut, 'loadKg': None, 'flames': flammes, 'role': None}

    def _cible_tenue(self, item, index, plan):
        ex_id = item['exerciseId']
        t = self.m.piste(ex_id)
        mem = self.mem(ex_id)
        lo = item.get('secondsLow')
        hi = item.get('secondsHigh')
        if lo is None:
            lo = hi
        if hi is None:
            hi = lo
        if lo is None or t is None:
            return self._ecrit(item, index)
        rir = self.rir_cible(item, plan)
        flammes = flammes_de_rir(rir)
        if t.mesures == 0:
            return {'secondsLow': lo, 'secondsHigh': hi, 'loadKg': None, 'flames': flammes, 'role': None}
        prevu = self.secondes_prevues(ex_id, rir)
        mu, sd = self.m.capacite_du_jour(ex_id)
        sur = int(math.floor(prevu * math.exp(-0.5 * sd)))
        haut = hi
        plaf = int(math.floor(self.s['tenue_part_max'] * math.exp(mu + sd)))
        if haut > plaf and plaf >= 1:
            haut = plaf
        fiche = self.fiches.get(ex_id) or {}
        bras_tendus = fiche.get('schema', '').startswith('figure_statique')
        h = None
        if bras_tendus:
            h = self.s['tenue_hausse_par_niveau'][self.g.niveau]
        if plan['cond']['hausse_quantite'] is not None:
            h = plan['cond']['hausse_quantite'] if h is None else min(h, plan['cond']['hausse_quantite'])
        if h is not None and mem.sec_max is not None:
            # Tendons : hausse par tenue bornée d'une séance à l'autre.
            borne = max(int(math.floor(mem.sec_max * (1 + h))), mem.sec_max + 1)
            if haut > borne:
                haut = borne
                self._raison('koach.tendon', exercice=ex_id)
        if (plan['sans_hausse'] or mem.echec) and mem.sec_max is not None and haut > mem.sec_max:
            haut = mem.sec_max
        if plan['echecs'] > 0 and mem.sec_seance is not None and haut > mem.sec_seance:
            haut = mem.sec_seance
        if haut < 1:
            haut = 1
        # Cible au ressenti : la tenue s'arrête à la réserve visée, entre le
        # bas sûr et la durée écrite.
        bas = lo if lo <= haut else haut
        if sur < bas:
            bas = max(1, sur)
        rep = self._repere(item, index, plan, t)
        if rep is not None and not (bras_tendus and mem.sec_max is None):
            plan['repere'] = True
            self._raison('koach.serie_repere', exercice=ex_id)
            # Tenue repère : jusqu'à la durée écrite du bloc (et la borne des
            # tendons), à la réserve de repère.
            ouvert = haut if h is not None else max(haut, min(2 * hi, 180))
            return {'secondsLow': bas, 'secondsHigh': ouvert, 'loadKg': None,
                    'flames': flammes_de_rir(rep), 'role': None, 'repere': True}
        return {'secondsLow': bas, 'secondsHigh': haut, 'loadKg': None, 'flames': flammes, 'role': None}

    # ------------------------------------------------------------------
    # Tests et tentatives
    # ------------------------------------------------------------------
    def _cible_test(self, item, index, plan):
        ex_id = item['exerciseId']
        test = item.get('test') or {}
        genre = test.get('kind')
        t = self.m.piste(ex_id)
        typ = plan['type']
        if t is None:
            return self._ecrit(item, index)
        rir_test = test.get('targetRir')
        if genre in ('one_rm', 'attempt_simulation') and typ == 'charge':
            return self._tentative(item, index, plan, t)
        if plan.get('rampe') is not None and typ == 'charge':
            return self._rampe(item, index, plan, t)
        if typ == 'charge':
            # Test xRM : charge prévue pour (répétitions + réserve du test).
            lo, hi = self._plages(item, index)
            rir = 1.0 if rir_test is None else rir_test
            grille = plan['grille']
            if t.mesures == 0 or grille is None:
                return {'repsLow': lo, 'repsHigh': hi, 'loadKg': item.get('startLoadKg'),
                        'flames': flammes_de_rir(rir), 'role': 'test'}
            voulu = self.charge_pour(ex_id, hi, rir, 0.25)
            charge = grille.proche(max(voulu, grille.minimum))
            mem = self.mem(ex_id)
            if plan['sans_hausse'] and mem.charge_derniere is not None and charge > mem.charge_derniere:
                charge = mem.charge_derniere
            if index >= 1 and mem.charge_seance is not None:
                # Deuxième essai : un cran de plus si le premier a laissé
                # plus que la réserve du test, sinon la même barre.
                charge = max(charge, mem.charge_seance) if plan['echecs'] == 0 else mem.charge_seance
            return {'repsLow': lo, 'repsHigh': hi, 'loadKg': charge, 'flames': flammes_de_rir(rir), 'role': 'test'}
        rir = 0.0 if rir_test is None else rir_test
        f = flammes_de_rir(rir)
        if f < 8:
            f = 8
        if typ == 'tenue':
            lo = item.get('secondsLow')
            hi = item.get('secondsHigh')
            return {'secondsLow': lo if lo is not None else hi, 'secondsHigh': hi if hi is not None else lo,
                    'loadKg': None, 'flames': f, 'role': 'test'}
        lo, hi = self._plages(item, index)
        return {'repsLow': lo, 'repsHigh': hi, 'loadKg': None, 'flames': f, 'role': 'test'}

    def _rampe(self, item, index, plan, t):
        """Vrai test en montée de charge, conduit par le ressenti : quelques
        répétitions par série ; tant que la série est dite facile, la charge
        monte (de 10 % loin de l'échec à 3,5 % près de la réserve du test) ;
        le test s'arrête à la réserve du test, à un échec, ou quand la barre
        suivante dépasse nettement ce que le modèle croit possible."""
        ta = self.p['test_adaptatif']
        ex_id = item['exerciseId']
        mem = self.mem(ex_id)
        grille = plan['grille']
        n_t, rir_t = plan['rampe']
        bw = t.fraction * self.m.poids_kg
        mu, sd = self.m.capacite_du_jour(ex_id)
        lam, k = self.m.courbe(t)
        if index == 0:
            voulu = self.charge_pour(ex_id, n_t, rir_t + 2.0, 0.5)
            recente = None
            for (j, c, r) in mem.charges_reussies:
                if self.jour - j <= self.s['barre_recente_j'] and (recente is None or c > recente):
                    recente = c
            if recente is not None:
                plafond = (recente + bw) * (1 + ta['repere_hausse']) - bw
                if voulu > plafond:
                    voulu = plafond
        else:
            derniere = plan.get('charge_item')
            if derniere is None:
                return None
            f = plan.get('flammes_item')
            if plan.get('echec_item') or f is None or (plan.get('reps_item') or 0) < n_t:
                return None
            dit = 0.0 if f >= 10 else (11 - f) / 2.0
            if f >= 10:
                return None
            pas = 0.0
            if dit <= rir_t + 0.75:
                # La note dit que la réserve du test est atteinte. Une seule
                # note peut tromper (bruit de la note) : la même barre est
                # refaite une fois pour confirmation, sans rien ajouter.
                plan['bas'] = plan.get('bas', 0) + 1
                if plan['bas'] >= ta['rampe_confirmations']:
                    return None
                return {'repsLow': n_t, 'repsHigh': n_t, 'loadKg': derniere,
                        'flames': flammes_de_rir(2.0), 'role': 'test', 'repere': True,
                        'trace': ['vrai test, confirmation %.1f' % derniere]}
            else:
                for (seuil, p) in ta['rampe_pas_par_rir']:
                    if dit >= seuil - rir_t + 1.0 - 1e-9:
                        pas = p
                        break
                if pas <= 0:
                    pas = ta['rampe_pas_par_rir'][-1][1]
            voulu = (derniere + bw) * (1 + pas) - bw
            # Garde-fou large : le test est conduit par le ressenti, pas par
            # la croyance du modèle (qu'il vient corriger) ; la barre ne
            # dépasse jamais ce que le modèle tient pour presque impossible.
            borne = math.exp(mu + 2.5 * max(sd, ta['rampe_sd_min']) - self.m._g(lam, k, n_t)) - bw
            if voulu > borne:
                voulu = borne
        charge = grille.plancher(max(voulu, grille.minimum))
        if index >= 1 and charge > plan['charge_item'] + 1e-9:
            # Barre suivante tenue pour faisable par le modèle (qui vient de
            # lire les notes de la montée) ; sinon le plus petit pas ; sinon
            # le test s'arrête là.
            pr = self.proba_reussite(ex_id, charge, n_t)
            if pr is not None and pr < ta['rampe_proba_min']:
                petit = grille.plancher(max((plan['charge_item'] + bw) * (1 + ta['rampe_pas_par_rir'][-1][1]) - bw,
                                            grille.minimum))
                if petit <= plan['charge_item'] + 1e-9:
                    petit = grille.suivant(plan['charge_item'])
                pr2 = self.proba_reussite(ex_id, petit, n_t)
                if petit >= charge or pr2 is None or pr2 < ta['rampe_proba_min']:
                    return None
                charge = petit
        if index >= 1 and charge <= plan['charge_item'] + 1e-9:
            suivant = grille.suivant(plan['charge_item'])
            if (suivant + bw) <= (plan['charge_item'] + bw) * (1 + ta['rampe_pas']) + 1e-9:
                charge = suivant
            else:
                return None
        # L'effort affiché d'une série de montée est « deux en réserve » :
        # les répétitions demandées sont faites tant qu'il reste de la marge.
        return {'repsLow': n_t, 'repsHigh': n_t, 'loadKg': charge, 'flames': flammes_de_rir(2.0),
                'role': 'test', 'repere': True, 'trace': ['vrai test %.1f' % charge]}

    def _tentative(self, item, index, plan, t):
        """Échelle des tentatives (règles A8.2 de 0.3.1, probabilités de
        Koach) : ouverture sûre, puis la barre la plus lourde qui garde la
        probabilité voulue ; la cible du profil est tentée à la dernière barre
        quand elle est atteignable."""
        s = self.s
        ex_id = item['exerciseId']
        grille = plan['grille']
        mem = self.mem(ex_id)
        mu, sd = self.m.capacite_du_jour(ex_id)
        bw = t.fraction * self.m.poids_kg
        baisse = 1.0 - s['tentative_bilan_bas_part'] * self.palier
        if plan['cond']['zone']:
            baisse -= s['tentative_bilan_bas_part']
        mu += math.log(baisse)
        sd = max(sd, 0.01)
        n = item.get('sets', 3)
        flammes = [7, 9, 10][index if index < 3 else 2]

        def plus_lourde(proba, plafond_total=None):
            total = math.exp(mu - norm_ppf(proba) * sd)
            if plafond_total is not None and total > plafond_total:
                total = plafond_total
            return grille.plancher(max(total - bw, grille.minimum))

        if index == 0 or mem.charge_seance is None:
            charge = plus_lourde(s['tentative_ouverture_proba'], s['tentative_ouverture_part'] * math.exp(mu))
            # Règle A8.2 de 0.3.1 : une barre réussie dans les 42 derniers
            # jours, plus légère que l'ouverture calculée et à 85 % au moins
            # de l'estimation, sert d'ouverture (barre déjà connue).
            recente = None
            for (j, c, r) in mem.charges_reussies:
                if self.jour - j <= s['barre_recente_j'] and (recente is None or c > recente):
                    recente = c
            if recente is not None and recente < charge and \
                    recente + bw >= s['tentative_recente_part'] * math.exp(mu):
                charge = recente
            # Plus prudent que 0.3.1 : l'ouverture ne dépasse jamais ce que
            # les barres réussies des 42 derniers jours justifient (+10 %,
            # +2,5 % par répétition faite au-delà de la première, 4 au plus :
            # la règle du premier passage à un schéma, A7.2). Une estimation
            # trop haute ne peut pas, seule, faire ouvrir trop lourd.
            justifie = None
            for (j, c, r) in mem.charges_reussies:
                if self.jour - j > s['barre_recente_j']:
                    continue
                plus = r - 1
                if plus > s['schema_change_reps_max']:
                    plus = s['schema_change_reps_max']
                borne = (c + bw) * (1 + s['premiere_hausse']) * (1 + s['schema_change_part'] * plus) - bw
                if justifie is None or borne > justifie:
                    justifie = borne
            if justifie is not None and charge > justifie:
                charge = grille.plancher(max(justifie, grille.minimum))
            return {'repsLow': 1, 'repsHigh': 1, 'loadKg': charge, 'flames': flammes, 'role': 'attempt'}
        derniere = mem.charge_seance
        if plan['echecs'] > 0 and mem.echec_seance:
            return {'repsLow': 1, 'repsHigh': 1, 'loadKg': derniere, 'flames': flammes, 'role': 'attempt'}
        dernier_essai = index >= n - 1
        proba = s['tentative_troisieme_proba'] if dernier_essai else s['tentative_deuxieme_proba']
        saut = s['tentative_saut_3'] if dernier_essai else s['tentative_saut_2']
        charge = plus_lourde(proba)
        haut = min((derniere + bw) * (1 + saut) - bw, derniere + s['tentative_saut_kg'])
        cible = item.get('koachCible')
        if dernier_essai and cible is not None and derniere < cible <= haut + 1e-9:
            p = self.proba_reussite(ex_id, cible, 1)
            if p is not None and p >= 0.35:
                charge = max(charge, cible)
        if charge > haut:
            charge = grille.plancher(haut)
        if charge < derniere:
            charge = derniere
        if charge <= derniere + 1e-9:
            charge = min(grille.suivant(derniere), max(grille.plancher(haut), derniere))
            p = self.proba_reussite(ex_id, charge, 1)
            if p is not None and p < 0.2:
                charge = derniere
        return {'repsLow': 1, 'repsHigh': 1, 'loadKg': charge, 'flames': flammes, 'role': 'attempt'}

    # ------------------------------------------------------------------
    # Retour d'une série faite et fin de séance
    # ------------------------------------------------------------------
    def serie_faite(self, s):
        ex_id = s['exerciseId']
        mem = self.mem(ex_id)
        plan = self.plans.get(s.get('slotId'))
        charge = s.get('externalLoadKg')
        if charge is not None and charge >= 0:
            mem.charge_seance = charge
        if s.get('reps') is not None:
            mem.reps_seance = s['reps']
        if s.get('seconds') is not None:
            mem.sec_seance = s['seconds']
        echec = bool(s.get('failed'))
        mem.echec_seance = 1 if echec else 0
        mem.flammes_seance = s.get('flames')
        if plan is not None:
            if charge is not None and charge >= 0:
                plan['charge_item'] = charge
            plan['flammes_item'] = s.get('flames')
            plan['reps_item'] = s.get('reps')
            plan['echec_item'] = echec
            if echec and not plan['test']:
                plan['echecs'] += 1
                plan['baisse'] = 1.0 - self.s['echec_baisse']
            elif echec:
                plan['echecs'] += 1

    def fermer(self, record):
        """Fin de séance : mémoire par exercice (verrous de la prochaine
        séance), courses et jours durs."""
        jour = self.jour
        par_ex = {}
        semaine = self.g.semaine
        for s in record.get('sets') or []:
            par_ex.setdefault((s['exerciseId'], s.get('slotId')), []).append(s)
            if (s.get('reps') or 0) > 0 or (s.get('seconds') or 0) > 0:
                zz = self.zones_ex.get(s['exerciseId'])
                if zz:
                    for z in zz[1]:
                        dz = self.dose_zone.setdefault(z, {})
                        dz[semaine] = dz.get(semaine, 0) + 1
        vus = set()
        for (ex_id, slot), series in par_ex.items():
            mem = self.mem(ex_id)
            if ex_id not in vus:
                mem.jours.append(jour)
                mem.echec = False
                mem.charge_max = None
                mem.reps_max = None
                mem.sec_max = None
                mem.sec_total = 0
                vus.add(ex_id)
            mem.jour = jour
            derniere = None
            for s in series:
                c = s.get('externalLoadKg')
                if c is not None and c >= 0 and (derniere is None or c > derniere):
                    derniere = c
            if derniere is not None:
                # Dernier passage de l'exercice dans la séance (un test et
                # le travail sont deux passages) : référence « pas de hausse ».
                mem.charge_derniere = derniere
            for s in series:
                if s.get('kind') == 'warmup':
                    continue
                c = s.get('externalLoadKg')
                if c is not None and c >= 0 and (mem.charge_max is None or c > mem.charge_max):
                    mem.charge_max = c
                r = s.get('reps')
                if r is not None and (mem.reps_max is None or r > mem.reps_max):
                    mem.reps_max = r
                sec = s.get('seconds')
                if sec is not None:
                    if mem.sec_max is None or sec > mem.sec_max:
                        mem.sec_max = sec
                    mem.sec_total += sec
                    if mem.meilleur_sec is None or sec > mem.meilleur_sec[0]:
                        mem.meilleur_sec = (sec, jour)
                cible = s.get('target') or {}
                if s.get('failed') and (cible.get('flames') or 0) < 10 and cible.get('role') not in ('attempt', 'test'):
                    mem.echec = True
                if c is not None and r and not s.get('failed'):
                    mem.charges_reussies.append((jour, c, r))
            premier = None
            for s in series:
                if s.get('kind') != 'warmup' and s.get('externalLoadKg') is not None and (s.get('target') or {}).get('role') is None:
                    premier = s
                    break
            if premier is not None:
                cible = premier.get('target') or {}
                hi = cible.get('repsHigh')
                rate = any(x.get('failed') for x in series)
                atteint = max((x.get('reps') or 0) for x in series) >= (hi or 0)
                mem.schemas[(slot, hi)] = (premier['externalLoadKg'], rate or not atteint)
        self.derniere_seance = jour
