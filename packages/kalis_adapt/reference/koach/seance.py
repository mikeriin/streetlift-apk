# -*- coding: utf-8 -*-
"""Prescription de la séance et conseil série par série de Koach 1.0
(CONTRAT_1_0.md § 3 `plan`, § 8 garde-fous) : charge et volume ajustés à
chaque séance depuis l'a posteriori, test adaptatif (charge la plus
informative dans la zone prescrite), tentatives choisies par probabilité de
réussite, le tout sous les contraintes dures de sécurité.
"""
import math

from .numerique import norm_cdf, norm_ppf, clamp
from .numerique import arrondi as arrondi_decimal
from .modele import FI, HH, DS
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


def arrondi(x):
    """Arrondi au plus proche, moitié vers le haut (`round` de Dart pour
    x ≥ 0)."""
    return int(math.floor(x + 0.5))


def equivalent_standard(item):
    """L'item sans sa technique, en séries classiques au même travail
    approché (`standardEquivalent`, A/session.dart:1622-1686) : paliers
    (vagues, pyramide) au nombre médian de répétitions ; échelle au milieu ;
    densité et contre-la-montre en trois séries d'un quart du total ; cluster
    d'une traite aux deux tiers du total ; les autres gardent séries et
    plage. Les règles d'autorégulation liées à la série de tête tombent.
    Modifie [item] en place."""
    t = item.get('technique') or {}
    kind = t.get('kind')
    sets = item.get('sets')
    low = item.get('repsLow')
    high = item.get('repsHigh')

    def mediane(reps):
        r = sorted(reps)
        return r[len(r) // 2]

    if kind == 'wave' and t.get('waveReps'):
        low = high = mediane(t['waveReps'])
    elif kind == 'pyramid' and t.get('pyramidReps'):
        low = high = mediane(t['pyramidReps'])
    elif kind == 'ladder':
        if t.get('ladderStart') is not None and t.get('ladderTop') is not None:
            low = high = (t['ladderStart'] + t['ladderTop']) // 2
    elif kind in ('density', 'for_time') and low is not None and high is not None:
        total = t.get('totalRepsTarget') or high
        each = total // 4 if total // 4 >= 1 else 1
        sets = 1 if total < 4 else 3
        low = high = each
    elif kind == 'cluster':
        mini = t.get('miniSets')
        each = t.get('miniSetReps')
        if mini is not None and each is not None and low is not None and high is not None:
            whole = (2 * mini * each + 2) // 3
            low = high = whole if whole >= 1 else 1
    regles = [r for r in item.get('autoregulation') or []
              if r.get('kind') not in ('backoff_from_top_set', 'stop_on_rep_drop')]
    item['sets'] = sets
    item['repsLow'] = low
    item['repsHigh'] = high
    item['technique'] = None
    item['setTargets'] = None
    item['autoregulation'] = regles or None
    return item


def secondes_prescrites(item, sets, vitesse):
    """Durée prescrite d'une ligne d'endurance, toutes séries (secondes) ;
    0 sans durée ni distance (`prescribedSeconds`, A/endurance.dart:283-293)."""
    s = item.get('secondsHigh')
    if s is None:
        s = item.get('secondsLow')
    if s is not None:
        return float(s * sets)
    m = item.get('distanceMeters')
    if m is not None and vitesse > 0:
        return m * sets / vitesse
    return 0.0


def reduire(item, part):
    """Ligne ramenée à la part [part] de l'écrit (`scaled`,
    A/endurance.dart:310-381) : nombre de séries d'un fractionné, durée ou
    distance de chaque série d'une course continue, répétitions d'une pièce
    de conditionnement ; jamais au-dessus de l'écrit, arrondi vers le bas
    (minute au-delà de 300 s, sinon 5 s ; 100 m ; une répétition ; une
    calorie). Modifie [item] en place ; vrai si quelque chose a changé."""
    if part >= 1:
        return False
    sets = item.get('sets', 0)
    if sets > 1 and item.get('repsHigh') is None and item.get('repsLow') is None:
        n = int(math.floor(sets * part))
        if n < 1:
            n = 1
        if n == sets:
            return False
        item['sets'] = n
        return True

    def bas(v, unite, plancher):
        if v is None:
            return None
        x = int(math.floor(v * part / unite)) * unite
        if x < plancher:
            x = plancher if plancher < v else v
        return x

    def bas_reel(v, unite):
        if v is None:
            return None
        x = math.floor(v * part / unite) * unite
        return (v if v < unite else unite) if x < unite else x

    hi = item.get('secondsHigh')
    lo = item.get('secondsLow')
    rh = item.get('repsHigh')
    rl = item.get('repsLow')
    m = item.get('distanceMeters')
    cal = item.get('calories')
    n_hi = bas(hi, 60 if hi is not None and hi >= 300 else 5, 5)
    n_lo = bas(lo, 60 if lo is not None and lo >= 300 else 5, 5)
    if n_lo is not None and n_hi is not None and n_lo > n_hi:
        n_lo = n_hi
    n_rh = bas(rh, 1, 1)
    n_rl = bas(rl, 1, 1)
    if n_rl is not None and n_rh is not None and n_rl > n_rh:
        n_rl = n_rh
    n_m = bas_reel(m, 100)
    n_cal = bas_reel(cal, 1)
    if n_hi == hi and n_lo == lo and n_rh == rh and n_rl == rl and n_m == m and n_cal == cal:
        return False
    item['secondsHigh'] = n_hi
    item['secondsLow'] = n_lo
    item['repsHigh'] = n_rh
    item['repsLow'] = n_rl
    item['distanceMeters'] = n_m
    item['calories'] = n_cal
    item['setTargets'] = None
    return True


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
                 'faciles_seance', 'charges_reussies', 'flammes_seance', 'charge_derniere',
                 'marques', 'sec_slot', 'forme', 'alerte_jour', 'alerte_part', 'barres', 'barres_ratees')

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
        # slotId -> (charge de base d'une semaine de charge, charge de base,
        # répétitions du schéma) de la dernière séance de l'emplacement
        # (`SlotMark`, A/coach.dart:323-380, 605-617) : règle du schéma changé.
        self.marques = {}
        self.sec_slot = {}            # slotId -> secondes de tenue de la dernière séance de l'emplacement
        self.forme = []               # (jour, ln capacité + effet de séance), trois au plus (A6.2)
        self.alerte_jour = None       # jour de la dernière alerte de surmenage (A6.2)
        self.alerte_part = None
        self.barres = []              # (jour, charge, répétitions, flammes dites) des barres réussies (1.0.2)
        self.barres_ratees = []       # (jour, charge) des barres ratées sans une répétition faite (1.0.2)


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
        # Endurance (règles A10 de 0.3.1, `EnduranceHistory`,
        # A/endurance.dart:96-228), recalculée du journal par `fermer` :
        self.courses = []        # (jour, secondes, flammes notées max, flammes visées) d'une séance
        self.jours_durs = []     # jours de conditionnement dur (pièce notée >= endurance_dure_flammes)
        self.jours_course_dure = []  # jours de course dure (notée >= endurance_dure_flammes)
        self.jours_actifs = []   # jours d'entraînement (au moins une série hors échauffement)
        self.course_metres = 0.0     # distance et durée des courses qui disent les deux (vitesse)
        self.course_secondes = 0.0
        self.jours_seances = []  # jours des séances fermées (reprise après coupure, A6.1)
        self.retour = None       # jour de la séance de retour de la dernière coupure
        self.derniere_seance = None
        self.coupure = 0
        self.contexte = None
        self.plans = {}          # slotId -> plan de l'item servi (séance en cours)
        self.dose_zone = {}      # zone -> {semaine: séries faites des mouvements qui la provoquent}
        self.ecrit_zone = {}     # zone -> {semaine: séries écrites (séances vues et manquées)}
        self.zones_ex = {}       # id -> (niveaux de zone, zones provoquées), vu à la prescription
        self.budget_zone = {}    # zone sensible -> séries encore permises aujourd'hui (rampe du réalisé)
        self.budget_semaine = {}  # zone sensible -> séries permises cette semaine (total)
        self.rampe_zone = set()  # zones encore sous rampe après la fenêtre sensible (sortie progressive)
        # Retour gradué au volume (critères `volume_trop_vite` et
        # `tendon_figures` du banc), recalculé du journal (contexte des
        # séances, appels de plan, fins de séance) :
        self.vol_semaines = {}   # semaine -> séries dures créditées par groupe majeur (fermées + manquées)
        self.tenue_semaines = {}  # semaine -> {famille: secondes de tenue bras tendus}
        self.dures_semaines = {}  # semaine -> séries dures servies, tous groupes (allègements)
        self.ecrit_semaines = {}  # semaine -> séries dures écrites des séances vues (allègements)
        self.allegees = {}       # semaine -> semaine allégée par nature (`semaines_allegees`)
        self.genres = {}         # semaine -> intention ou genre de la semaine (affûtage, compétition…)
        self.servis = None       # items servis de la séance en cours (comptés à la fin de séance)
        self.retour_vol = None   # budgets de la séance en cours (`_budgets_retour`)

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
        # Inverse de g sur la courbe de population (forme fermée).
        r = m._reps_de(lam0, k0, x) if x > 0 else 1.0
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

    def proba_reussite(self, ex_id, externe, reps=1, brut=False):
        """P(réussir [reps] répétitions avec la charge [externe] aujourd'hui) ;
        [brut] : écart-type sans l'élargissement de la fiabilité (tentatives)."""
        t = self.m.piste(ex_id)
        if t is None or t.type != 'charge':
            return None
        mu, sd = self.m.capacite_du_jour(ex_id, brut=brut)
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
            self.genres[contexte['semaine']] = contexte.get('intention') or contexte.get('genre')
        self.palier, self.decalage = self.g.palier_bilan(bilan)
        self.coupure = self._coupure(jour)
        self.retour = self._retour(jour)
        self.raisons = []
        # A2.2 : renvoi vers un professionnel à la première séance d'un
        # arrêt, puis à la première séance de chaque semaine d'arrêt.
        for z in self.g.renvois():
            self._raison('koach.douleur_persistante', zone=z, consulter=True)
        self.plans = {}
        self.budget_zone = {}
        self.servis = None
        self.retour_vol = None
        c = contexte or {}
        legeres = self.s['semaines_allegees']
        for m in c.get('manquees') or []:
            # Séance manquée : le validateur du banc la compte à son volume
            # écrit (`blocs_servis_prescrits`) ; Koach fait de même.
            if m.get('semaine') is None:
                continue
            if 'genre' in m and m['semaine'] not in self.allegees:
                self.allegees[m['semaine']] = m.get('genre') in legeres
            self._compter(m['semaine'], m.get('items') or [])
            self.ecrit_semaines[m['semaine']] = self.ecrit_semaines.get(m['semaine'], 0.0) + \
                sum(self._series_dures(p) for p in m.get('items') or [])
            self._compter_ecrit_zone(m['semaine'], m.get('items') or [])
        if c.get('semaine') is not None:
            self.allegees[c['semaine']] = c.get('genre') in legeres
        self.budget_semaine = {}
        for z in list(self.g.zones):
            b = self._budget_zone_semaine(z)
            if b is not None:
                self.budget_semaine[z] = b
        for mem in self.memoire.values():
            mem.charge_seance = None
            mem.reps_seance = None
            mem.sec_seance = None
            mem.echec_seance = 0
            mem.total_seance = 0.0
            mem.faciles_seance = 0

    def _coupure(self, jour):
        """Durée de la coupure qui vaut encore aujourd'hui (règle A6.1 de
        0.3.1, A/session.dart:1096-1113) : au moins `coupure_j` jours depuis
        la dernière séance, ou une telle coupure dont la séance de retour
        date de `coupure_fenetre_j` jours au plus (toute la semaine du
        retour) ; 0 sinon."""
        js = self.jours_seances
        s = self.s
        if not js:
            return 0
        if jour - js[-1] >= s['coupure_j']:
            return jour - js[-1]
        for i in range(len(js) - 1, 0, -1):
            if js[i] < jour - s['coupure_fenetre_j']:
                break
            if js[i] - js[i - 1] >= s['coupure_j']:
                return js[i] - js[i - 1]
        return 0

    def _retour(self, jour):
        """Jour de la séance de retour de la dernière coupure d'au moins
        `coupure_j` jours (aujourd'hui si la coupure finit aujourd'hui), ou
        None. Sert à interdire mesures et tests tant que l'exercice n'a pas été
        refait `retour_seances_avant_mesure` fois depuis le retour (plus
        prudent que 0.3.1)."""
        js = self.jours_seances
        s = self.s
        if not js:
            return None
        if jour - js[-1] >= s['coupure_j']:
            return jour
        for i in range(len(js) - 1, 0, -1):
            if js[i] - js[i - 1] >= s['coupure_j']:
                return js[i]
        return None

    def _apres_retour(self, mem):
        """Séances de l'exercice faites depuis le retour de coupure (None hors
        retour)."""
        if self.retour is None:
            return None
        return sum(1 for j in mem.jours if j >= self.retour)

    def _dose_semaine(self, z, semaine):
        return self.dose_zone.get(z, {}).get(semaine, 0)

    def _semaines_closes(self):
        """Semaines ayant au moins une séance fermée (journal)."""
        return set(j // 7 for j in self.jours_seances)

    def _compter_ecrit_zone(self, semaine, items):
        """Séries écrites de la semaine [semaine] par zone provoquée
        (exercices déjà vus à la prescription ; échauffement compris, comme le
        réalisé de `fermer`)."""
        for p in items:
            zz = self.zones_ex.get(p['exerciseId'])
            if not zz:
                continue
            n = int(p.get('sets') or 0)
            if n <= 0:
                continue
            for z in zz[1]:
                e = self.ecrit_zone.setdefault(z, {})
                e[semaine] = e.get(semaine, 0) + n

    def _ecrit_zone(self, z, semaine):
        return self.ecrit_zone.get(z, {}).get(semaine, 0)

    def _budget_zone_semaine(self, z):
        """1.0.5 (lot KM1c4, règles 1 à 3) : séries permises cette semaine,
        tous mouvements qui provoquent la zone [z] confondus (échauffement
        compris), quand la zone est sensible (`Gardefous.sensible` : épisode
        ≥ `arret_persistance_min`, avec ou sans arrêt, douze semaines après
        son dernier signalement) ou encore sous rampe après la fenêtre (sortie
        progressive). None sinon. « Rampe du réalisé » :

        * référence = exposition RÉALISÉE de la dernière semaine de charge
          fermée (séances manquées à 0, jamais comptées à l'écrit) ; une
          semaine fermée sans exposition renvoie à la dernière semaine de
          charge exposée parmi les `rampe_zone_semaines_max` précédentes ;
        * permis = max(référence + 1 ; référence × (1 + `reprise_dose_hausse`))
          (hausse hebdomadaire bornée : Gabbett 2016, rapport aigu:chronique
          0,8-1,3, danger ≥ 1,5 ; Nielsen et al. 2014) ; pas de hausse si la
          zone a été signalée > `reprise_douleur_max` dans les 7 derniers jours
          (Silbernagel et al. 2007 : la douleur ne doit pas augmenter d'une
          semaine à l'autre) ;
        * sans référence (aucune semaine de charge exposée depuis le début de
          l'épisode, ou arrêt) : départ à `reprise_dose_depart` × habitude,
          habitude = charge chronique = somme de l'exposition réalisée des
          quatre semaines de charge précédant l'épisode / 4 (moyenne glissante
          sur quatre semaines du rapport aigu:chronique, Gabbett 2016 ; une
          semaine sans journal compte 0) ; sans habitude :
          `reprise_dose_sans_habitude` ;
        * jamais sous `reprise_dose_min`."""
        g = self.g
        s = self.s
        d = g.zones.get(z)
        if d is None:
            return None
        semaine = g.semaine
        ep = g.episode(z)
        sensible = g.sensible(z)
        if not sensible and z not in self.rampe_zone:
            return None
        closes = self._semaines_closes()

        def charge_fermee(w):
            return g.semaines.get(w, False) and w in closes

        debut = ep[0] // 7 if ep is not None else semaine
        # Référence : dernière semaine de charge fermée depuis la semaine du
        # premier signalement de l'épisode. La semaine du signalement
        # elle-même ne sert que si c'est la semaine précédente, et sans
        # hausse (ce qui a été fait cette semaine-là l'a été en partie avant
        # le signalement : on tient, on ne monte pas) ; une semaine fermée
        # sans exposition renvoie à la dernière semaine exposée parmi les
        # `rampe_zone_semaines_max` précédentes, STRICTEMENT après la
        # semaine du signalement (sinon un épisode qui a vidé une ou deux
        # semaines repartirait de l'exposition d'avant l'épisode) ; après
        # l'arrêt le cas échéant.
        ref = None
        tenir = False
        w = semaine - 1
        while w >= debut and w >= 0:
            if charge_fermee(w):
                ref = self._dose_semaine(z, w)
                if w == debut:
                    tenir = True
                elif ref <= 0:
                    for k in range(w - 1, max(debut + 1, w - s['rampe_zone_semaines_max']) - 1, -1):
                        if charge_fermee(k) and self._dose_semaine(z, k) > 0:
                            ref = self._dose_semaine(z, k)
                            break
                break
            w -= 1
        if ref is not None and ref > 0 and g.arret(z):
            ref = None
        if ref is not None and ref > 0:
            if tenir or d.pire_entre(self.jour - 6, self.jour) > s['reprise_douleur_max']:
                total = int(ref)
            else:
                total = max(int(ref) + 1, int(math.floor(ref * (1 + s['reprise_dose_hausse']) + 1e-9)))
        else:
            avant = [self._dose_semaine(z, k) for k in range(debut - 4, debut) if k >= 0 and charge_fermee(k)]
            if avant:
                habitude = sum(avant) / 4.0
                total = int(math.floor(s['reprise_dose_depart'] * habitude + 1e-9))
            else:
                total = int(s['reprise_dose_sans_habitude'])
        if total < s['reprise_dose_min']:
            total = int(s['reprise_dose_min'])
        if not sensible:
            # Sortie progressive (règle 2) : après la fenêtre, la rampe
            # continue tant que le permis n'atteint pas l'écrit de la
            # semaine de référence ; dès qu'il l'atteint, la zone sort.
            ecrit_ref = 0
            w = semaine - 1
            while w >= 0:
                if charge_fermee(w):
                    ecrit_ref = self._ecrit_zone(z, w)
                    break
                w -= 1
            if total >= ecrit_ref:
                self.rampe_zone.discard(z)
                return None
        else:
            self.rampe_zone.add(z)
        return total

    def _budgets_zone_jour(self, items):
        """Part du budget hebdomadaire de chaque zone sensible pour la séance
        du jour : reste de la semaine réparti au prorata de l'écrit du jour et
        des séances restantes de la semaine (`contexte['reste_semaine']`),
        arrondi au plus proche (demi vers le haut) ; tout le reste quand rien
        n'est écrit."""
        out = {}
        c = self.contexte or {}
        semaine = self.g.semaine
        for z, total in self.budget_semaine.items():
            reste = total - self._dose_semaine(z, semaine)
            if reste < 0:
                reste = 0
            e_jour = 0
            for p in items:
                zz = self.zones_ex.get(p['exerciseId'])
                if zz and z in zz[1]:
                    e_jour += int(p.get('sets') or 0)
            e_reste = 0
            for seance in c.get('reste_semaine') or []:
                for p in seance:
                    zz = self.zones_ex.get(p['exerciseId'])
                    if zz and z in zz[1]:
                        e_reste += int(p.get('sets') or 0)
            if e_jour + e_reste > 0:
                part = int(math.floor(reste * e_jour / float(e_jour + e_reste) + 0.5))
            else:
                part = reste
            out[z] = part
        return out

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
        self.retour_vol = self._budgets_retour(items)
        sem = (self.contexte or {}).get('semaine')
        if sem is not None:
            self.ecrit_semaines[sem] = self.ecrit_semaines.get(sem, 0.0) + sum(self._series_dures(p) for p in items)
            self._compter_ecrit_zone(sem, items)
        self.budget_zone = self._budgets_zone_jour(items)
        for item in items:
            servi = self._item(item, grilles.get(item['exerciseId']), zones.get(item['exerciseId']),
                               roles.get(item['slotId']))
            if servi is None:
                continue
            servi = self._retour_gradue(servi)
            if servi is None:
                self.plans.pop(item['slotId'], None)
                continue
            plan = self.plans.get(item['slotId'])
            ex_id = item['exerciseId']
            if plan is not None and ex_id not in testes and item.get('kind') == 'work' \
                    and not any(z in self.budget_zone for z in (zones.get(ex_id) or ({}, set()))[1]):
                # 1.0.5 : pas de vrai test (montée de charge) sur un
                # mouvement qui provoque une zone sous rampe du réalisé.
                vt = self._vrai_test(servi, plan, self.m.pistes.get(ex_id))
                if vt is not None and not self._duree_permet_test(items, item, vt, sum(
                        1 for x in out if x.get('koach') == 'vrai_test')):
                    vt = None
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
                    # Séries de la ligne avant la montée : celles servies (après
                    # douleur, bilan, surmenage, retour gradué), jamais plus que
                    # l'écrit ; montée (séries dures faites) + travail les
                    # respectent (règle « volume_test » de `cible`).
                    lignes = min(int(item.get('sets') or 0), int(servi.get('sets') or 0))
                    p2 = dict(plan)
                    p2.update({'test': True, 'rampe': vt, 'echecs': 0, 'ecrit': test, 'charge_item': None,
                               'durs': 0, 'durs_max': max(1, lignes - 1)})
                    self.plans[slot] = p2
                    self._raison('koach.vrai_test', exercice=ex_id)
                    out.append(test)
                    # Les deux séries proches de la limite de la montée (la
                    # barre finale et sa confirmation) remplacent autant de
                    # séries de travail : le volume dur du jour ne monte pas.
                    retire = min(int(ta['rampe_series_travail']), servi['sets'] - 1)
                    if retire > 0:
                        servi['sets'] -= retire
                    plan['apres_test'] = True
                    plan['slot_test'] = slot
                    plan['series_ecrites'] = lignes
            out.append(servi)
        out = self._duree_bornee(self._endurance(out), items)
        self.servis = [dict(it) for it in out]
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
        mem = self.mem(ex_id)
        cond = self.g.conduite(niveaux, hits, est_test=est_test, depuis_jour=mem.jour, fiche=fiche,
                               echauffement=echauffement)
        if cond['retire']:
            self._raison('koach.douleur_retrait', exercice=ex_id, zone=cond['zone'], cause=cond['raison'])
            return None
        if est_test and self.palier >= 1 and not evenement:
            self._raison('koach.test_reporte', exercice=ex_id, cause='bilan_bas')
            return None
        if est_test and self.coupure > 0 and not evenement and typ == 'charge' \
                and (item.get('test') or {}).get('kind') in ('one_rm', 'attempt_simulation'):
            # Semaine du retour après une coupure : pas de tentative maximale
            # (les barres « récentes » datent d'avant la coupure).
            self._raison('koach.test_reporte', exercice=ex_id, cause='coupure')
            return None
        servi = dict(item)
        plan = {'cond': cond, 'role': role, 'test': est_test, 'type': typ, 'grille': grille,
                'sans_hausse': cond['sans_hausse'] or self.palier >= 1, 'rir_bonus': cond['rir'],
                'rir_min': cond['rir_min'], 'part_max': cond['part_max'], 'echecs': 0,
                'baisse': 1.0, 'verrou': self.verrouillee(), 'ecrit': item, 'tete': None,
                'repere': False, 'dose_plafonnee': cond['dose_plafonnee'], 'fragile': cond['fragile'],
                'servi': servi}
        if self.coupure > 0 and typ in ('reps', 'tenue'):
            # Semaine du retour après une coupure : répétitions et tenues
            # jamais au-dessus de la dernière séance (plus prudent que 0.3.1,
            # qui réduit seulement les séries, A6.1) ; pas de mesure ni de
            # test (`_mesure_utile`).
            plan['sans_hausse'] = True
        if self.coupure > 0 and typ == 'charge':
            # 1.0.2 — reprise par paliers mesurés (C13.12) : la première
            # série ne dépasse pas la dernière séance du même schéma (ou les
            # barres récentes) ; chaque série faite, dite au plus aussi dure
            # que visé, autorise le palier suivant (+5 % ou un cran), jusqu'à
            # la charge que l'estimation demande. (1.0 et 1.0.1 : aucune
            # hausse au-dessus du dernier passage de l'exercice, souvent une
            # série légère — ancrage mesuré sur le banc adversarial.)
            plan['reprise'] = True
        if cond['appui_neutre'] is not None:
            self._raison('koach.poignet_appui_neutre', exercice=ex_id, intensite=cond['appui_neutre'])
        if cond['poignet_sensible'] and not echauffement:
            self._raison('koach.poignet_dose', exercice=ex_id)
        self._technique(servi, plan, cond)
        if self.palier == 1:
            plan['rir_bonus'] += self.s['bilan_rir_bonus']
        elif self.palier == 2:
            plan['rir_bonus'] += 2 * self.s['bilan_rir_bonus']
            plan['rir_min'] = max(plan['rir_min'] or 0.0, self.s['bilan_bas_rir_min'])
        series = servi.get('sets', 0)
        if not est_test and typ in ('charge', 'reps', 'tenue'):
            if not echauffement:
                f = cond['series']
                if f < 1.0:
                    series = max(1, int(math.floor(series * f + 1e-9)))
            # A6.1 : reprise après coupure, échauffement compris
            # (A/session.dart:1119-1146 ne l'excepte pas).
            if self.coupure >= self.s['coupure_j']:
                n = int(math.floor(series * self.s['coupure_series'] + 0.5))
                if 1 <= n < series:
                    series = n
                    self._raison('koach.reprise_coupure', exercice=ex_id, jours=self.coupure)
            if not echauffement:
                if self.palier == 2 and item.get('targetFlames') is not None:
                    plancher = 3 if role == 'main' else 2
                    if series > plancher:
                        series -= 1
                series = self._surmenage(ex_id, mem, role, series)
        # Rampe du réalisé (1.0.5, KM1c4) : séries de tout mouvement qui
        # provoque une zone sous budget ramenées à ce que la séance permet
        # encore, échauffement compris (chaque série expose la structure).
        for z in sorted(hits):
            if z in self.budget_zone:
                reste = self.budget_zone[z]
                if series > reste:
                    series = reste if reste > 0 else 0
                    self._raison('koach.reprise_dose', exercice=ex_id, zone=z)
        if series <= 0 and any(z in self.budget_zone for z in hits):
            self._raison('koach.douleur_retrait', exercice=ex_id, zone=cond['zone'] or sorted(hits)[0], cause='reprise_dose')
            return None
        for z in sorted(hits):
            if z in self.budget_zone:
                self.budget_zone[z] -= series
        servi['sets'] = series
        self.plans[item['slotId']] = plan
        if typ in ('charge', 'reps', 'tenue') and not echauffement:
            servi['setTargets'] = None
        return servi

    def _surmenage(self, ex_id, mem, role, series):
        """A6.2 : pendant `surmenage_jours` jours après une alerte de
        surmenage d'un mouvement principal, lignes − arrondi(lignes ×
        `surmenage_coupe`) (au moins une, jamais la dernière), intensité
        gardée, en semaine de charge seulement (A/coach.dart:923-958)."""
        s = self.s
        c = self.contexte or {}
        a = mem.alerte_jour
        if role != 'main' or a is None or series < 2:
            return series
        if not (0 < self.jour - a <= s['surmenage_jours']):
            return series
        if self.verrouillee() or (c.get('intention') or c.get('genre')) == 'maintenance':
            return series
        retire = int(math.floor(series * s['surmenage_coupe'] + 0.5))
        if retire < 1:
            retire = 1
        self._raison('koach.surmenage', exercice=ex_id, series=retire, part=arrondi_decimal(mem.alerte_part, 3))
        return series - retire

    # ------------------------------------------------------------------
    # Techniques (règle A9.2 de 0.3.1)
    # ------------------------------------------------------------------
    def _technique(self, servi, plan, cond):
        """Technique au-dessus du niveau du profil : séries classiques
        équivalentes (A/session.dart:951-973, `standardEquivalent`
        A/session.dart:1622-1686). Technique qui intensifie : non servie sur
        zone douloureuse ou en reprise, un jour de bilan au palier 2, en
        semaine verrouillée ; excentrique accentué non servi à
        `excentrique_echeance_j` jours ou moins d'une échéance, ni sur zone
        fragile du profil (`servedTechnique`, A/coach.dart:753-790)."""
        s = self.s
        tech = servi.get('technique') or {}
        kind = tech.get('kind')
        if not kind or kind == 'standard':
            return
        c = self.contexte or {}
        cause = None
        if self.g.niveau < s['technique_niveau_acces'].get(kind, 0):
            cause = 'niveau'
        elif kind in s['techniques_intensives']:
            jours = c.get('jours_avant_echeance')
            if cond['raison'] is not None:
                cause = 'douleur'
            elif self.palier >= 2:
                cause = 'bilan'
            elif plan['verrou']:
                cause = 'phase'
            elif kind == 'accentuated_eccentric' and jours is not None and jours <= s['excentrique_echeance_j']:
                cause = 'echeance'
            elif kind == 'accentuated_eccentric' and cond['fragile']:
                cause = 'antecedent'
        if cause is None:
            return
        if cause == 'niveau':
            equivalent_standard(servi)
        else:
            servi['technique'] = None
        self._raison('koach.technique_retenue', exercice=servi['exerciseId'], technique=kind, cause=cause)

    # ------------------------------------------------------------------
    # Retour gradué au volume (critères `volume_trop_vite`, `tendon_figures`
    # et `seance_trop_longue` du banc, portés comme contraintes dures)
    # ------------------------------------------------------------------
    FAMILLES_BRAS_TENDUS = ('push', 'pull', 'mixed')
    TENUE_MIN_S = 5

    def _credits(self, ex_id):
        """Crédits de la fiche sur les groupes majeurs : [(indice, séries
        créditées par série dure)], en demi-séries comme `groupCredits` de
        kalis_plan (part 1 → 1 ; part 0,5 → 0,5)."""
        n = len(self.s['volume_groupes_majeurs'])
        out = []
        for (i, w) in (self.fiches.get(ex_id) or {}).get('groupes') or []:
            if i < n:
                c = int(math.floor(w * 2 + 0.5)) / 2.0
                if c > 0:
                    out.append((i, c))
        return out

    def _series_dures(self, p):
        """Séries dures d'un item (`ItemView.hardSets` du banc) : séries
        d'un exercice de renforcement hors échauffement, à
        `serie_dure_rir_max` en réserve au plus ou sans cible."""
        fiche = self.fiches.get(p['exerciseId']) or {}
        if not fiche.get('renforcement') or p.get('kind') == 'warmup':
            return 0.0
        f = p.get('targetFlames')
        if f is not None and rir_de_flammes(f) > self.s['serie_dure_rir_max']:
            return 0.0
        return float(p.get('sets') or 0)

    def _tenue_bras_tendus(self, p):
        """(famille, secondes par série) d'une tenue bras tendus de
        renforcement (`ItemView.straightArm`, `heldSeconds` du banc :
        échauffement compris), sinon (None, 0)."""
        fiche = self.fiches.get(p['exerciseId']) or {}
        fam = fiche.get('bras_tendus')
        if fam is None or not fiche.get('renforcement'):
            return None, 0.0
        if p.get('secondsLow') is None and p.get('secondsHigh') is None:
            return None, 0.0
        sh = p.get('secondsHigh')
        if sh is None:
            sh = p.get('secondsLow')
        return fam, float(sh or 0)

    def _compter(self, semaine, items):
        """Ajoute au volume de la semaine [semaine] les séries dures
        créditées et les secondes bras tendus de [items]."""
        v = self.vol_semaines.get(semaine)
        if v is None:
            v = self.vol_semaines[semaine] = [0.0] * len(self.s['volume_groupes_majeurs'])
        t = self.tenue_semaines.setdefault(semaine, {})
        for p in items:
            dures = self._series_dures(p)
            if dures > 0:
                self.dures_semaines[semaine] = self.dures_semaines.get(semaine, 0.0) + dures
                for (g, c) in self._credits(p['exerciseId']):
                    v[g] += dures * c
            fam, sec = self._tenue_bras_tendus(p)
            if fam is not None:
                t[fam] = t.get(fam, 0.0) + float(p.get('sets') or 0) * sec

    def _limite_rampe(self, allegees, serie, index, hausse, tolerance):
        """`rampLimit` du banc : plus haute valeur admise en semaine
        [index] au vu des trois semaines précédentes ; une semaine allégée
        compte à part, et après trois semaines allégées le volume peut
        revenir à `serie / volume_reprise_part`."""
        def pas(ref):
            rel = ref * (1 + hausse)
            ab = ref + tolerance
            return rel if rel > ab else ab

        charge = 0.0
        legere = 0.0
        une_chargee = False
        for k in range(index - 3, index):
            if k < 0:
                continue
            if allegees[k]:
                if serie[k] > legere:
                    legere = serie[k]
            else:
                une_chargee = True
                if serie[k] > charge:
                    charge = serie[k]
        if une_chargee:
            return pas(charge if charge > legere else legere)
        reprise = legere / self.s['volume_reprise_part']
        p = pas(legere)
        return p if p > reprise else reprise

    def _historique(self, semaine, valeur):
        """(allégées, série) des semaines 0..[semaine] ; une semaine sans
        rien de connu compte comme semaine de charge à 0 (plus prudent :
        la limite ne peut que baisser)."""
        allegees = [self.allegees.get(k, False) for k in range(semaine + 1)]
        serie = [valeur(k) for k in range(semaine + 1)]
        return allegees, serie

    def _limite_volume(self, g, semaine):
        """Séries dures créditées admises au groupe [g] en semaine
        [semaine] ≥ 1 : règle sur trois semaines (+`volume_hausse` ou
        +`volume_hausse_series`), et règle sur deux semaines
        (+`volume_hausse_2sem` ou +`volume_hausse_2sem_series` sur la
        semaine w−2) quand les trois semaines w−2..w sont de charge et que
        w−2 a du volume (`volume_trop_vite` du banc)."""
        s = self.s
        n = len(s['volume_groupes_majeurs'])
        allegees, serie = self._historique(
            semaine, lambda k: (self.vol_semaines.get(k) or [0.0] * n)[g])
        l1 = self._limite_rampe(allegees, serie, semaine, s['volume_hausse'], s['volume_hausse_series'])
        if semaine > 1 and not allegees[semaine] and not allegees[semaine - 1] \
                and not allegees[semaine - 2] and serie[semaine - 2] > 0:
            ref = serie[semaine - 2]
            l2 = max(ref * (1 + s['volume_hausse_2sem']), ref + s['volume_hausse_2sem_series'])
            if l2 < l1:
                return l2
        return l1

    def _limite_tenue(self, fam, semaine):
        """Secondes bras tendus admises à la famille [fam] en semaine
        [semaine] (`tendon_figures` du banc : +`tenue_hausse_par_niveau`
        ou +`tenue_hausse_hebdo_s`) ; None sans tenue de la famille dans les
        trois semaines précédentes (aucune hausse contrôlée)."""
        allegees, serie = self._historique(
            semaine, lambda k: (self.tenue_semaines.get(k) or {}).get(fam, 0.0))
        ref = 0.0
        for k in range(semaine - 3, semaine):
            if k >= 0 and serie[k] > ref:
                ref = serie[k]
        if ref <= 0:
            return None
        return self._limite_rampe(allegees, serie, semaine, self.s['tenue_hausse_par_niveau'][self.g.niveau],
                           self.s['tenue_hausse_hebdo_s'])

    def _budgets_retour(self, items=()):
        """Budgets de la séance du jour : par groupe majeur (et par famille
        de tenue bras tendus), limite de la semaine − déjà fait cette
        semaine (séances fermées et manquées) − écrit des séances restantes
        de la semaine (`contexte['reste_semaine']`, réservé en entier : une
        séance restante manquée compte à son volume écrit) ; et, une semaine
        d'allègement, séries dures de la semaine tous groupes confondus. None
        la première semaine du programme ou du journal (aucune limite) ou
        sans semaine connue."""
        c = self.contexte or {}
        sem = c.get('semaine')
        if sem is None or sem < 1:
            return None
        if not any(k < sem for k in self.allegees) and not any(k < sem for k in self.vol_semaines):
            # Première semaine du journal (rien de connu avant) : pas de
            # limite, comme la première semaine du programme pour le banc.
            return None
        n = len(self.s['volume_groupes_majeurs'])
        reserve = [0.0] * n
        reserve_t = {}
        reserve_d = 0.0
        ecrit_reste = 0.0
        for seance in c.get('reste_semaine') or []:
            r_s = [0.0] * n
            r_t = {}
            r_d = 0.0
            for p in seance:
                dures = self._series_dures(p)
                r_d += dures
                if dures > 0:
                    for (g, cr) in self._credits(p['exerciseId']):
                        r_s[g] += dures * cr
                fam, sec = self._tenue_bras_tendus(p)
                if fam is not None:
                    r_t[fam] = r_t.get(fam, 0.0) + float(p.get('sets') or 0) * sec
            ecrit_reste += r_d
            reserve_d += r_d
            for g in range(n):
                reserve[g] += r_s[g]
            for fam in sorted(r_t):
                reserve_t[fam] = reserve_t.get(fam, 0.0) + r_t[fam]
        fait = self.vol_semaines.get(sem) or [0.0] * n
        fait_t = self.tenue_semaines.get(sem) or {}
        limites = [self._limite_volume(g, sem) for g in range(n)]
        budgets = [limites[g] - fait[g] - reserve[g] for g in range(n)]
        limites_t = {}
        budgets_t = {}
        for fam in self.FAMILLES_BRAS_TENDUS:
            lim = self._limite_tenue(fam, sem)
            limites_t[fam] = lim
            budgets_t[fam] = None if lim is None else lim - fait_t.get(fam, 0.0) - reserve_t.get(fam, 0.0)
        # Allègement (`decharge_absente` du banc) : une semaine allégée par
        # nature, ou dont l'écrit est un allègement au vu de l'écrit des trois
        # semaines précédentes (≤ `decharge_part` de la plus haute), reste un
        # allègement au vu du servi : séries dures de la semaine ≤
        # `decharge_part` × la plus haute des trois semaines servies d'avant.
        part = self.s['decharge_part']
        legere = self.allegees.get(sem, False)
        ecrit = self.ecrit_semaines.get(sem, 0.0) + sum(self._series_dures(p) for p in items) + ecrit_reste
        ref_e = max([self.ecrit_semaines.get(k, 0.0) for k in range(sem - 3, sem) if k >= 0] or [0.0])
        allegement = (ecrit <= part * ref_e + 1e-9) if ref_e > 0 else legere
        limite_d = None
        budget_d = None
        if allegement or legere:
            ref_s = max([self.dures_semaines.get(k, 0.0) for k in range(sem - 3, sem) if k >= 0] or [0.0])
            if ref_s > 0:
                limite_d = part * ref_s
                budget_d = limite_d - self.dures_semaines.get(sem, 0.0) - reserve_d
        return {'limites': limites, 'budgets': budgets, 'jour': [0.0] * n,
                'limites_tenue': limites_t, 'budgets_tenue': budgets_t, 'jour_tenue': {},
                'limite_dures': limite_d, 'budget_dures': budget_d, 'jour_dures': 0.0}

    def _retour_gradue(self, servi):
        """Retour gradué au volume : séries de l'item ramenées à ce que la
        semaine permet encore, pour chacun de ses groupes majeurs (séries
        dures créditées), pour le total de la semaine une semaine
        d'allègement, et pour sa famille de tenue bras tendus (secondes :
        tenues raccourcies à séries égales, 5 s au moins, puis une série de
        moins). Zéro série : item retiré. Raison `koach.retour_gradue`. Renvoie l'item ou None."""
        rv = self.retour_vol
        if rv is None:
            return servi
        series = int(servi.get('sets') or 0)
        if series <= 0:
            return servi
        par_serie = []
        dure = self._series_dures(servi) > 0
        if dure:
            par_serie = self._credits(servi['exerciseId'])
        total = dure and rv['budget_dures'] is not None
        fam, sec = self._tenue_bras_tendus(servi)
        if fam is not None and (rv['budgets_tenue'].get(fam) is None or sec <= 0):
            fam = None
        if not par_serie and fam is None and not total:
            return servi
        maxi = series
        cause = None
        if total:
            m = int(math.floor(rv['budget_dures'] - rv['jour_dures'] + 1e-9))
            if m < 0:
                m = 0
            if m < maxi:
                maxi = m
                cause = ('total', None)
        for (g, c) in par_serie:
            m = int(math.floor((rv['budgets'][g] - rv['jour'][g]) / c + 1e-9))
            if m < 0:
                m = 0
            if m < maxi:
                maxi = m
                cause = ('groupe', g)
        secondes = None
        if fam is not None and maxi > 0:
            reste_t = rv['budgets_tenue'][fam] - rv['jour_tenue'].get(fam, 0.0)
            if maxi * sec > reste_t + 1e-9:
                # Tenues trop longues pour la semaine : mêmes séries, tenues
                # raccourcies (5 s au moins, le plancher de `reduire`) ; sinon
                # une série de moins, et ainsi de suite.
                cause = ('famille', fam)
                trouve = 0
                for n in range(maxi, 0, -1):
                    h = int(math.floor(reste_t / n + 1e-9))
                    if h > sec:
                        h = int(sec)
                    if h >= self.TENUE_MIN_S:
                        trouve = n
                        if h < sec:
                            secondes = h
                        break
                maxi = trouve
        if maxi >= series and secondes is None:
            if total:
                rv['jour_dures'] += series
            for (g, c) in par_serie:
                rv['jour'][g] += series * c
            if fam is not None:
                rv['jour_tenue'][fam] = rv['jour_tenue'].get(fam, 0.0) + series * sec
            return servi
        if cause[0] == 'groupe':
            groupe = self.s['volume_groupes_majeurs'][cause[1]]
            limite = rv['limites'][cause[1]]
        elif cause[0] == 'total':
            groupe = 'allegement'
            limite = rv['limite_dures']
        else:
            groupe = 'bras_tendus_' + cause[1]
            limite = rv['limites_tenue'][cause[1]]
        self._raison('koach.retour_gradue', exercice=servi['exerciseId'], groupe=groupe,
                     limite=arrondi_decimal(limite, 1), series=maxi, secondes=secondes)
        if maxi <= 0:
            return None
        servi['sets'] = maxi
        if servi.get('setTargets'):
            servi['setTargets'] = servi['setTargets'][:maxi]
        if secondes is not None:
            servi['secondsHigh'] = secondes
            if servi.get('secondsLow') is not None and servi['secondsLow'] > secondes:
                servi['secondsLow'] = secondes
            sec = float(secondes)
        if total:
            rv['jour_dures'] += maxi
        for (g, c) in par_serie:
            rv['jour'][g] += maxi * c
        if fam is not None:
            rv['jour_tenue'][fam] = rv['jour_tenue'].get(fam, 0.0) + maxi * sec
        return servi

    def _fermer_volume(self, sets):
        """Fin de séance : volume réellement servi ajouté à la semaine, compté
        comme le validateur du banc (`blocs_servis_prescrits`, tests faits) :
        une ligne compte ses séries prescrites, ou ses séries faites si
        moins ont été faites (au moins une) ; une montée de test ajoutée par
        Koach compte ses séries dures faites (réserve dite de 4 au plus,
        ou échec)."""
        sem = (self.contexte or {}).get('semaine')
        if sem is None:
            return
        faites = {}
        dures = {}
        for x in sets:
            if x.get('nonModelise') or x.get('enduranceKind') is not None:
                continue
            k = x.get('slotId')
            faites[k] = faites.get(k, 0) + 1
            f = x.get('flames')
            if f is not None and f < 3 and not x.get('failed'):
                continue
            dures[k] = dures.get(k, 0) + 1
        if self.servis is None:
            # Séance sans prescription de Koach : les séries faites, telles
            # quelles (cible du premier passage de chaque emplacement).
            par_slot = {}
            ordre = []
            for x in sets:
                k = (x.get('slotId'), x['exerciseId'])
                if k not in par_slot:
                    ordre.append(k)
                    cible = x.get('target') or {}
                    par_slot[k] = {'slotId': k[0], 'exerciseId': k[1], 'sets': 0, 'kind': x.get('kind'),
                                   'targetFlames': cible.get('flames'),
                                   'secondsHigh': cible.get('secondsHigh') if x.get('seconds') is not None else None}
                par_slot[k]['sets'] += 1
            self._compter(sem, [par_slot[k] for k in ordre])
            return
        items = []
        for p in self.servis:
            q = dict(p)
            slot = p.get('slotId')
            if p.get('koach') == 'vrai_test':
                q['sets'] = dures.get(slot, 0)
            elif q.get('sets') and q.get('kind') != 'warmup':
                n = faites.get(slot)
                if n is not None and n < q['sets']:
                    q['sets'] = n
            items.append(q)
        self._compter(sem, items)

    def _duree_item(self, p, vitesse):
        """Durée estimée d'un item en secondes, comme le critère
        `seance_trop_longue` du banc (`ItemView.estimatedSeconds`) :
        transition 45 s, 3 s par répétition (deux côtés hors bilatéral),
        durée écrite (deux côtés en renforcement), distance à la vitesse de
        course, 6 s par calorie, repos écrit ou 60 s."""
        fiche = self.fiches.get(p['exerciseId']) or {}
        renfo = bool(fiche.get('renforcement'))
        cotes = 1 if fiche.get('lateralite', 'bilateral') == 'bilateral' else 2
        n = int(p.get('sets') or 0)
        if p.get('repsLow') is not None or p.get('repsHigh') is not None:
            rh = p.get('repsHigh') if p.get('repsHigh') is not None else p.get('repsLow')
            effort = (rh or 0) * 3.0 * cotes
        elif p.get('secondsLow') is not None or p.get('secondsHigh') is not None:
            sh = p.get('secondsHigh') if p.get('secondsHigh') is not None else p.get('secondsLow')
            effort = float(sh or 0) * (cotes if renfo else 1)
        elif p.get('distanceMeters') is not None:
            effort = float(p['distanceMeters']) / vitesse
        elif p.get('calories') is not None:
            effort = float(p['calories']) * 6
        else:
            effort = 30.0
        rest = p.get('restSeconds')
        rest = float(60 if rest is None else rest)
        return 45.0 + n * effort + (n - 1) * rest

    def _duree_seance(self, items, vitesse):
        """Durée estimée d'une séance en minutes (`DayView.estimatedMinutes` :
        5 min d'échauffement général dès qu'un exercice de renforcement)."""
        t = 0.0
        renfo = False
        for p in items:
            t += self._duree_item(p, vitesse)
            renfo = renfo or bool((self.fiches.get(p['exerciseId']) or {}).get('renforcement'))
        return (t + (300 if renfo else 0)) / 60.0

    @staticmethod
    def _jour_epreuve(items):
        """Séance d'épreuve : un contre-la-montre servi comme test et noté
        `event_day` (exempté de la règle de durée par le banc)."""
        for p in items:
            if p.get('kind') == 'test' and (p.get('test') or {}).get('kind') == 'time_trial' and \
                    any((r.get('params') or {}).get('note') == 'event_day' for r in p.get('reasons') or []):
                return True
        return False

    def _duree_bornee(self, out, items):
        """Durée de la séance servie bornée (critère `seance_trop_longue`) :
        jamais plus que budget × `seance_tolerance` + `seance_tolerance_min`
        quand l'écrit tenait dans cette durée ou était un jour d'épreuve (le
        test du jour d'épreuve servi tel quel reste exempté), jamais plus
        que l'écrit sinon. Réductions, de la plus longue ligne d'endurance à
        la dernière ligne de renforcement : une série de moins, puis course
        ou cardio ramenés à une durée (secondes à la vitesse de course du
        journal), puis ligne retirée ; jamais une montée de test. Raison
        `koach.seance_bornee`."""
        budget = (self.contexte or {}).get('budget')
        if budget is None or not out or self._jour_epreuve(out):
            return out
        # Durée d'une course : la plus lente des deux vitesses, celle du
        # journal et celle du profil (`allure_course` : meilleure allure
        # chronométrée × 0,9, règle `runSpeedOf` du banc ; 2,5 m/s sans
        # chrono), pour ne jamais sous-estimer la durée.
        vitesse = self._vitesse()
        lente = self.m.profil.get('allure_course') or self.s['duree_vitesse_defaut']
        if lente < vitesse:
            vitesse = lente
        admis = float(budget) * self.s['seance_tolerance'] + self.s['seance_tolerance_min']
        ecrit = self._duree_seance(items, vitesse)
        if ecrit <= admis or self._jour_epreuve(items):
            # Marge d'arrondi : le banc compare sans tolérance (45 × 1,15 + 3
            # vaut 54,7499… en flottants).
            limite = admis - 1e-6
        else:
            limite = ecrit
        out = list(out)
        notes = []
        garde = 0
        while self._duree_seance(out, vitesse) > limite and garde < 200:
            garde += 1
            exces = (self._duree_seance(out, vitesse) - limite) * 60.0
            endurance = [it for it in out if it.get('kind') != 'warmup' and it.get('koach') != 'vrai_test'
                         and self._nature(it['exerciseId']) in ('course', 'cardio', 'conditionnement')]
            if endurance:
                it = max(endurance, key=lambda x: (self._duree_item(x, vitesse), -out.index(x)))
            else:
                renfo = [x for x in out if x.get('kind') not in ('warmup', 'test') and x.get('koach') != 'vrai_test']
                if not renfo:
                    break
                it = renfo[-1]
            n = int(it.get('sets') or 0)
            if n > 1:
                it['sets'] = n - 1
                if it.get('setTargets'):
                    it['setTargets'] = it['setTargets'][:n - 1]
            elif endurance and (it.get('distanceMeters') is not None or it.get('secondsHigh') is not None
                                or it.get('secondsLow') is not None):
                effort = self._duree_item(it, vitesse) - 45.0 - exces
                unite = 60 if effort >= 300 else 5
                sec = int(math.floor(effort / unite + 1e-9)) * unite
                if sec < 5:
                    out.remove(it)
                else:
                    it.update({'distanceMeters': None, 'secondsHigh': sec,
                               'secondsLow': sec if (it.get('secondsLow') is None or it['secondsLow'] > sec)
                               else it['secondsLow'], 'setTargets': None})
            else:
                out.remove(it)
            if id(it) not in notes:
                notes.append(id(it))
                self._raison('koach.seance_bornee', exercice=it['exerciseId'], minutes=arrondi_decimal(limite, 2))
        return out

    # ------------------------------------------------------------------
    # Endurance et conditionnement (règles A2.3 et A10 de 0.3.1)
    # ------------------------------------------------------------------
    def _nature(self, ex_id):
        """Nature d'un exercice non modélisé (`enduranceKindOf`,
        A/endurance.dart:56-79) : 'course' (cardio avec matériel de course,
        hors marche et éducatifs), 'cardio', 'conditionnement', 'mobilite' ;
        None pour un exercice modélisé."""
        fiche = self.fiches.get(ex_id) or {}
        typ = fiche.get('type')
        if typ == 'cardio':
            if not ex_id.startswith('ca-marche') and not ex_id.startswith('ca-educatif') and \
                    any(m in self.s['endurance_materiel_course'] for m in fiche.get('materiel') or []):
                return 'course'
            return 'cardio'
        if typ == 'wod':
            return 'conditionnement'
        if typ == 'mobilite':
            return 'mobilite'
        return None

    def _vitesse(self):
        """Vitesse de course (m/s) : celle des courses du journal qui disent
        distance et durée, sinon `endurance_vitesse` (A/endurance.dart:124-145)."""
        if self.course_secondes > 0:
            return self.course_metres / self.course_secondes
        return self.s['endurance_vitesse']

    def _qualite(self, item):
        """Séance de course de qualité (`isQualityRun`, A/endurance.dart:295-306)."""
        f = item.get('targetFlames')
        if f is not None and rir_de_flammes(f) <= self.s['endurance_qualite_rir'] + 1e-9:
            return True
        if item.get('intensity') is not None or item.get('kind') == 'test':
            return True
        return any(q in item['exerciseId'] for q in self.s['endurance_qualite_ids'])

    def _course_trop_dure(self):
        """Une course des `endurance_dure_jours` jours d'avant notée au moins
        `endurance_dure_marge` flammes au-dessus de la cible, ou au moins
        `endurance_dure_flammes` + 1 sans cible (`recentRunTooHard`,
        A/endurance.dart:240-255)."""
        s = self.s
        for (j, sec, f, t) in self.courses:
            if j >= self.jour or j < self.jour - s['endurance_dure_jours'] or f is None:
                continue
            if (f - t >= s['endurance_dure_marge']) if t is not None else (f >= s['endurance_dure_flammes'] + 1):
                return True
        return False

    def _serie_wod(self):
        """Jours durs de conditionnement de suite juste avant aujourd'hui ; un
        jour sans séance ne rompt pas la suite, deux oui ; fenêtre de
        `wod_fenetre_j` jours (`conditioningStreak`, A/endurance.dart:257-281)."""
        durs = set(self.jours_durs)
        actifs = set(self.jours_actifs)
        n = 0
        d = self.jour - 1
        trou = 0
        while d >= self.jour - self.s['wod_fenetre_j']:
            if d in durs:
                n += 1
                trou = 0
            elif d not in actifs:
                trou += 1
            else:
                break
            if trou > 1:
                break
            d -= 1
        return n

    def _endurance(self, out):
        """Conduite des lignes d'endurance de la séance servie
        (`_enduranceDay`, A/session.dart:2476-2872) : jamais plus long, plus
        loin, plus de répétitions ni plus dur que l'écrit. Renvoie la liste
        des items servis (lignes retirées enlevées)."""
        s = self.s
        g = self.g
        c = self.contexte or {}
        natures = []
        for it in out:
            n = self._nature(it['exerciseId'])
            if n is not None:
                natures.append((it, n))
        if not natures and self.jour - 1 not in self.jours_course_dure:
            return out
        retires = []          # identités des items retirés
        vitesse = self._vitesse()
        facile_f = flammes_de_rir(s['endurance_facile_rir'])

        def retirer(it, **raison):
            retires.append(id(it))
            self._raison(raison.pop('code'), exercice=it['exerciseId'], **raison)

        # 0. A2.3 : douleur qui dure au bas du corps, la course est retirée
        # tant que l'arrêt tient (A/session.dart:2527-2567).
        arrets = g.arrets_jambe()
        if arrets:
            for it, n in natures:
                if n == 'course':
                    retirer(it, code='koach.douleur_retrait', zone=arrets[0], cause='douleur_arret')
        retour = g.reprise_jambe()
        # 1. A10.1 : reprise après une coupure (A/session.dart:2569-2575).
        (court_j, court_p), (long_j, long_p) = s['endurance_reprise'][0], s['endurance_reprise'][1]
        actif = self.jours_actifs[-1] if self.jours_actifs else None
        ecart = 0 if actif is None else self.jour - actif
        reprise = long_p if ecart >= long_j else (court_p if ecart >= court_j else 1.0)
        cause_reprise = 'reprise_%d' % (long_j if ecart >= long_j else court_j)
        # 2. A10.2 : jour sans (A/session.dart:2577-2613).
        if self.palier >= 2:
            sans = 'bilan_fort'
        elif self.palier >= 1:
            sans = 'bilan'
        elif g.douleur_jambe() >= s['endurance_douleur_jambe']:
            sans = 'douleur_jambe'
        elif self._course_trop_dure():
            sans = 'course_dure'
        else:
            sans = None
        pris = [it['exerciseId'] for it in out]
        for it, n in natures:
            if id(it) in retires or n == 'mobilite' or it.get('kind') == 'warmup':
                continue
            part = min(reprise, long_p) if (retour and n == 'course') else reprise
            if part < 1 and reduire(it, part):
                self._raison('koach.endurance_raccourcie', exercice=it['exerciseId'],
                             cause=('reprise_%d' % long_j) if part < reprise else cause_reprise,
                             part=arrondi(part * 100))
            if sans is None:
                continue
            if n == 'course' and self._qualite(it):
                # Qualité → course facile de la durée de travail écrite ;
                # sans course facile faisable, la séance est retirée
                # (A/session.dart:2647-2697).
                travail = secondes_prescrites(it, it.get('sets', 0), vitesse)
                fiche = self.fiches.get(it['exerciseId']) or {}
                cf = s['endurance_course_facile']
                facile = cf['tapis'] if 'tapis de course' in (fiche.get('materiel') or []) else cf['defaut']
                ff = self.fiches.get(facile)
                # Faisable : son matériel est celui de la séance écrite
                # (Koach ne connaît pas le matériel du jour : plus prudent),
                # lieu du jour compris.
                faisable = ff is not None and \
                    all(m in (fiche.get('materiel') or []) for m in ff.get('materiel') or []) and \
                    (c.get('lieu') is None or c.get('lieu') in (ff.get('lieux') or [])) and \
                    travail >= s['endurance_facile_min_s'] and facile not in pris
                if faisable:
                    minutes = int(travail // 60)
                    if minutes < 1:
                        minutes = 1
                    f = it.get('targetFlames')
                    pris.append(facile)
                    ancien = it['exerciseId']
                    it.update({'exerciseId': facile, 'sets': 1, 'repsLow': None, 'repsHigh': None,
                               'distanceMeters': None, 'calories': None,
                               'secondsLow': minutes * 60, 'secondsHigh': minutes * 60,
                               'targetFlames': facile_f if (f is None or f > facile_f) else f,
                               'intensity': None, 'setTargets': None, 'restSeconds': None,
                               'autoregulation': None, 'groupId': None,
                               'kind': 'work' if it.get('kind') == 'test' else it.get('kind'),
                               'test': None})
                    self._raison('koach.course_facile', exercice=ancien, remplacant=facile, cause=sans)
                else:
                    retirer(it, code='koach.endurance_retrait', cause=sans)
                    continue
            if self.palier >= 2 and n in ('course', 'cardio') and reduire(it, s['endurance_mauvais_jour']):
                self._raison('koach.endurance_raccourcie', exercice=it['exerciseId'], cause=sans,
                             part=arrondi(s['endurance_mauvais_jour'] * 100))
        # 3. A10.3 : course du jour bornée à la plus longue course des
        # `endurance_pic_jours` derniers jours + `endurance_pic`
        # (A/session.dart:2716-2813).
        plus_longue = 0.0
        compte = 0
        for (j, sec, f, t) in self.courses:
            if j < self.jour and j >= self.jour - s['endurance_pic_jours']:
                compte += 1
                if sec > plus_longue:
                    plus_longue = sec
        courses = [it for it, n in natures if n == 'course' and id(it) not in retires and it.get('kind') != 'warmup']

        def total():
            return sum(secondes_prescrites(it, it.get('sets', 0), vitesse) for it in courses)

        if compte >= s['endurance_pic_courses_min'] and plus_longue > 0:
            plafond = plus_longue * (1 + s['endurance_pic'])
            avant = total()
            if avant > plafond + 1e-6:
                facteur = plafond / avant
                for it in courses:
                    change = False
                    if it.get('kind') == 'test':
                        # Test plus long que la borne : course bornée à effort
                        # modéré, test reporté.
                        f = it.get('targetFlames')
                        it.update({'kind': 'work', 'test': None, 'intensity': None, 'setTargets': None,
                                   'targetFlames': None if f is None else min(f, facile_f + 1)})
                        change = True
                    if reduire(it, facteur) or change:
                        self._raison('koach.course_bornee', exercice=it['exerciseId'],
                                     part=arrondi(s['endurance_pic'] * 100))
                garde = 0
                while total() > plafond + 1e-6 and garde < 50:
                    garde += 1
                    long_it = None
                    for it in courses:
                        if long_it is None or secondes_prescrites(it, it.get('sets', 0), vitesse) > \
                                secondes_prescrites(long_it, long_it.get('sets', 0), vitesse):
                            long_it = it
                    if long_it is None:
                        break
                    if long_it.get('sets', 0) > 1:
                        long_it['sets'] -= 1
                    else:
                        essai = dict(long_it)
                        if not reduire(essai, s['endurance_bornee_reduction']) or \
                                secondes_prescrites(essai, 1, vitesse) >= secondes_prescrites(long_it, 1, vitesse):
                            break
                        long_it.clear()
                        long_it.update(essai)
        # 4. A10.4 : conditionnement mis à l'échelle (A/session.dart:2815-2846).
        cause_wod = sans if (sans is not None and sans != 'course_dure') else \
            ('jours_durs' if self._serie_wod() >= s['wod_jours_durs'] else None)
        if cause_wod is not None:
            for it, n in natures:
                if n != 'conditionnement' or id(it) in retires or it.get('kind') == 'warmup':
                    continue
                if not reduire(it, s['wod_echelle']):
                    continue
                f = it.get('targetFlames')
                if f is not None and f > facile_f + 1:
                    it['targetFlames'] = f - 1
                self._raison('koach.wod_echelle', exercice=it['exerciseId'], cause=cause_wod,
                             part=arrondi(s['wod_echelle'] * 100))
        # 5. A10.5 : course dure la veille, une flamme de moins sur le bas du
        # corps modélisé (A/session.dart:2848-2871).
        if self.jour - 1 in self.jours_course_dure:
            for it in out:
                fiche = self.fiches.get(it['exerciseId']) or {}
                f = it.get('targetFlames')
                if id(it) in retires or fiche.get('type') not in ('charge', 'reps', 'tenue') or not fiche.get('bas') \
                        or it.get('kind') in ('test', 'warmup') or f is None or f <= 1:
                    continue
                it['targetFlames'] = f - 1
                self._raison('koach.fatigue_croisee', exercice=it['exerciseId'], cause='course_dure')
        if not retires:
            return out
        return [it for it in out if id(it) not in retires]

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
        if plan.get('slot_test') is not None:
            # Après une montée de test : séries dures de la montée (réserve
            # dite de 4 au plus, ou échec) + séries de travail ne dépassent
            # jamais les séries écrites de la ligne, une série de travail au
            # moins étant gardée.
            durs = (self.plans.get(plan['slot_test']) or {}).get('durs', 0)
            if index >= 1 and durs + index >= plan['series_ecrites']:
                self._raison('koach.arret_exercice', exercice=item['exerciseId'], cause='volume_test')
                return None
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

    def _mesure_utile(self, item, plan, t, vrai=False):
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
        if plan.get('dose_plafonnee'):
            # Dose plafonnée (poignet sensible, reprise) : jamais de série
            # repère (A/coach.dart:1515-1520).
            return False
        if self.coupure > 0:
            # Coupure en cours (semaine du retour, `coupure_fenetre_j`) : ni
            # vrai test ni série repère.
            return False
        n = self._apres_retour(self.mem(item['exerciseId']))
        if n is not None and n < self.s['retour_seances_avant_mesure']:
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
        if vrai:
            # Jamais de vrai test après un échec non prévu à la dernière
            # séance de l'exercice, ni dans les 14 jours qui suivent une
            # série ratée (A8.3, A7.2.3 de 0.3.1).
            if self.mem(item['exerciseId']).echec:
                return False
            if t.dernier_echec_jour is not None and \
                    self.jour - t.dernier_echec_jour < ta['jours_min_entre_tests']:
                return False
            # Vrai test : espacé de 14 jours du dernier test arrivé près de
            # l'échec, et de `jours_min_entre_rampes` de toute montée (une
            # montée arrêtée loin de l'échec n'a rien mesuré : elle ne bloque
            # pas la suivante pendant 14 jours). Une série repère, loin du
            # maximum, ne remplace pas un vrai test.
            if t.dernier_vrai_test_jour is not None and \
                    self.jour - t.dernier_vrai_test_jour < ta['jours_min_entre_tests']:
                return False
            if t.derniere_rampe_jour is not None and \
                    self.jour - t.derniere_rampe_jour < ta['jours_min_entre_rampes']:
                return False
        elif t.dernier_test_jour is not None and self.jour - t.dernier_test_jour < ta['jours_min_entre_tests']:
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

    @staticmethod
    def _duree_item_s(p):
        """Durée estimée d'un item, comme le critère `seance_trop_longue`
        du banc (transition 45 s, 3 s par répétition, repos entre séries),
        côtés non comptés (la fiche ne dit pas la latéralité ici)."""
        n = int(p.get('sets') or 0)
        if n <= 0:
            return 0.0
        if p.get('repsHigh') is not None or p.get('repsLow') is not None:
            rh = p.get('repsHigh') if p.get('repsHigh') is not None else p.get('repsLow')
            effort = (rh or 0) * 3.0
        elif p.get('secondsHigh') is not None or p.get('secondsLow') is not None:
            sh = p.get('secondsHigh') if p.get('secondsHigh') is not None else p.get('secondsLow')
            effort = float(sh or 0)
        else:
            effort = 30.0
        rest = p.get('restSeconds')
        rest = float(60 if rest is None else rest)
        return 45.0 + n * effort + (n - 1) * rest

    def _duree_permet_test(self, items, item, vt, deja):
        """Vrai si la montée de test tient dans le budget de la séance
        (budget × `seance_tolerance` + `seance_tolerance_min` minutes, règle
        `seance_trop_longue` de 0.3.1) ; sans budget connu : un seul vrai
        test par séance."""
        ta = self.p['test_adaptatif']
        budget = (self.contexte or {}).get('budget')
        if budget is None:
            return deja == 0
        # Séries de la montée : au plus les séries dures permises (séries
        # écrites de la ligne moins une), plus une série encore facile.
        n = min(ta['rampe_series_max'] + (2 if vt[0] == 1 else 0), max(1, int(item.get('sets') or 0) - 1) + 1)
        repos = max(item.get('restSeconds') or 0, ta['repos_test_s'])
        ajout = 45.0 + n * vt[0] * 3.0 + (n - 1) * repos
        retire = min(int(ta['rampe_series_travail']), int(item.get('sets') or 0) - 1)
        if retire > 0:
            rh = item.get('repsHigh') if item.get('repsHigh') is not None else (item.get('repsLow') or 0)
            ajout -= retire * (rh * 3.0 + float(60 if item.get('restSeconds') is None else item['restSeconds']))
        total = 300.0 + ajout * (deja + 1)
        for p in items:
            total += self._duree_item_s(p)
        return total / 60.0 <= float(budget) * self.s['seance_tolerance'] + self.s['seance_tolerance_min']

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
        if t is None or t.seances < 1 or not self._mesure_utile(item, plan, t, vrai=True):
            return None
        # Grille trop grossière pour une montée (cran de plus de 10 % de la
        # charge totale) : la mesure se fait en répétitions (série repère).
        grille = plan['grille']
        mem = self.mem(item['exerciseId'])
        ref = mem.charge_max if mem.charge_max is not None else None
        if grille is None or ref is None:
            return None
        if not any(self.jour - j <= self.s['barre_recente_j'] for (j, c, r) in mem.charges_reussies):
            # Aucune barre réussie depuis `barre_recente_j` jours : pas de
            # rampe (le maximum connu est trop ancien pour borner la montée).
            return None
        bw = t.fraction * self.m.poids_kg
        if grille.suivant(ref) + bw > (ref + bw) * (1 + ta['rampe_pas_cran']) + 1e-9:
            # Cran de la grille au-delà de `rampe_pas_cran` de la charge
            # totale : pas de montée. Jusque-là, un cran reste permis (« un
            # cran toujours permis », A7.2 de 0.3.1), seulement après une
            # série dite très facile (`_rampe`).
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
        # 1.0.3 : séries lourdes (répétitions ≤ `fiabilite_schema_reps`) d'un
        # athlète aux notes peu fiables (κ > 1) : quantile plus prudent de
        # `prudence_charge_fiabilite`·(κ − 1) écarts-types (l'écart-type lui-même
        # est déjà élargi par κ) ; 0 pour κ = 1.
        kappa = m.elargissement()
        if kappa > 1.0 and hi <= self.p['mesure'].get('fiabilite_schema_reps', 5):
            prudence += self.p['planification'].get('prudence_charge_fiabilite', 0.0) * (kappa - 1.0)
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
        if part is not None and plan.get('fragile') and part > self.s['surcharge_fragile_max']:
            # A7.2 : exercice surchargé sur une zone fragile du profil, jamais
            # plus que le 1RM (`coachOverloadFragileMax`, A/coach.dart:1039-1042 ;
            # appliqué aussi à une part du 1RM de l'exercice lui-même).
            part = self.s['surcharge_fragile_max']
            self._raison('koach.zone_fragile', exercice=ex_id, zone=plan['fragile'], cause='surcharge')
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
        if index == 0 and not plan['sans_hausse'] and not plan.get('reprise') and not plan['verrou'] \
                and t.seances >= 1:
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
        if plan.get('reprise') and plan.get('reprise_plafond') is None:
            # Reprise par paliers : les paliers ne dépassent jamais ce que la
            # première série d'une séance ordinaire aurait pu atteindre
            # (bornes de hausse A7.2 sans le gel de la reprise). Calculé une
            # fois par ligne, quelle que soit la première série demandée.
            n_r = len(self.raisons)
            plan['reprise_plafond'] = self._bornes_hausse(ex_id, item, charge, plan, t, grille,
                                                          self._plages(item, 0)[1], 0, gel=False)
            del self.raisons[n_r:]
        if plan.get('reprise') and index >= 1 and plan.get('charge_item') is None and plan.get('tete') is None:
            # Série demandée avant la première (aperçu des séries à venir) :
            # bornée comme une première série de reprise.
            charge = self._bornes_hausse(ex_id, item, charge, plan, t, grille, hi, 0)
        charge = self._bornes_hausse(ex_id, item, charge, plan, t, grille, hi, index)
        if charge != avant_bornes:
            trace.append('hausse bornee %.2f -> %.2f' % (avant_bornes, charge))
        # Dans la séance : après un échec, -7,5 % gardé ; jamais plus lourd
        # un jour verrouillé.
        if plan['baisse'] < 1.0 and plan.get('charge_item') is not None:
            tete = (plan['charge_item'] + bw) * plan['baisse'] - bw
            if charge > tete:
                charge = grille.plancher(max(tete, grille.minimum))
        if index >= 1 and plan.get('charge_item') is not None and \
                (plan['sans_hausse'] or plan['echecs'] > 0 or plan.get('dose_plafonnee')):
            if charge > plan['charge_item']:
                charge = plan['charge_item']
        if index >= 1 and plan.get('reprise') and not plan.get('palier_franchi'):
            # Reprise par paliers mesurés : le palier suivant n'est permis
            # qu'après une série faite en entier, sans échec, notée, et dite
            # au plus aussi dure que visé (`serie_faite`). Sans série versée
            # au journal, la charge de la première série fait foi.
            palier = plan.get('charge_item') if plan.get('charge_item') is not None else plan.get('tete')
            if palier is not None and charge > palier:
                charge = palier
                trace.append('palier de reprise non franchi -> %.2f' % charge)
        if index >= 1 and plan.get('reprise') and plan.get('reprise_plafond') is not None \
                and charge > plan['reprise_plafond']:
            # Paliers franchis : jamais au-dessus de la borne de hausse d'une
            # séance ordinaire (A7.2 : même schéma + hausse du niveau, ou
            # barre récente + `premiere_hausse`).
            charge = plan['reprise_plafond']
            trace.append('plafond de reprise -> %.2f' % charge)
        if index >= 1 and plan.get('charge_item') is not None and tech.get('kind') != 'top_set_backoff':
            # D'une série à l'autre : -15 % / +5 % au plus, un cran permis.
            haut = (plan['charge_item'] + bw) * 1.05 - bw
            bas = (plan['charge_item'] + bw) * 0.85 - bw
            if charge > haut:
                charge = max(grille.plancher(haut), min(charge, grille.suivant(plan['charge_item'])))
            if charge < bas:
                charge = grille.proche(bas)
        # Semaine verrouillée : bornée par la charge écrite (`lockUp` de 0.3.1,
        # plus haut). La borne « dernier passage de l'exercice » a été
        # mesurée puis écartée : le dernier passage peut être un autre schéma
        # (plus de répétitions, plus léger), elle sous-charge la décharge
        # (écart d'effort 3,2 -> 3,6 ; fausses alertes de rupture 1,4 -> 4,4 %).
        if (plan['cond']['sans_hausse'] or plan['cond']['raison']) and mem.charge_derniere is not None \
                and charge > mem.charge_derniere:
            # Zone douloureuse ou en reprise : jamais plus lourd que le
            # dernier passage de l'exercice (invariant I3 de 0.3.1). Depuis
            # 1.0.2, un jour de bilan bas sans douleur n'est borné, comme en
            # 0.3.1, que par la dernière séance du même schéma
            # (`_bornes_hausse`), et la semaine du retour d'une coupure par
            # les paliers de reprise.
            charge = mem.charge_derniere
            trace.append('pas de hausse (douleur) -> %.2f' % charge)
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
            if index == 0:
                # Repère sur la première série (ligne d'une seule série) :
                # bornes de hausse d'une séance à l'autre sur le schéma ouvert
                # (même emplacement, même plage ouverte), comme une première
                # série ordinaire.
                charge_r = self._bornes_hausse(ex_id, item, charge_r, plan, t, grille,
                                               hi + self.p['test_adaptatif']['reps_ouvertes'], 0)
            return {'repsLow': lo, 'repsHigh': hi + self.p['test_adaptatif']['reps_ouvertes'],
                    'loadKg': charge_r, 'flames': flammes_de_rir(rep), 'role': None, 'repere': True,
                    'trace': ['repere %.1f (modele %.1f, plafond %.1f)' % (charge_r, voulu_r, plafond_r)]}
        return {'repsLow': lo, 'repsHigh': hi, 'loadKg': charge, 'flames': flammes, 'role': None,
                'trace': trace}

    def _bornes_hausse(self, ex_id, item, charge, plan, t, grille, hi, index, gel=None):
        """Bornes de hausse d'une séance à l'autre (règles A7.2 de 0.3.1) :
        10/5/5/5 % à schéma égal (moitié sur zone fragile, de la conduite ou
        du profil), un cran toujours permis ; aucune hausse après échec,
        douleur ou bilan bas ; schéma changé au même emplacement borné sur la
        dernière séance de l'emplacement."""
        if index > 0:
            return charge
        s = self.s
        mem = self.mem(ex_id)
        bw = t.fraction * self.m.poids_kg
        cle = (item['slotId'], hi)
        avant = mem.schemas.get(cle)
        douleur = bool(plan['cond']['zone']) or item.get('koachFragile', False)
        profil = plan.get('fragile')
        fragile = douleur or bool(profil)
        # `coachRise[niveau]` (× 0,5 sur zone fragile) pour toute ligne
        # chargée, accessoires compris : la cible du mode coach de 0.3.1 ne
        # double pas (A/coach.dart:830-833, 1146-1149 ; le doublement `riseCap`
        # ne sert qu'à la règle générale de 0.1).
        h = self.g.hausse_max(fragile)
        avant_bornes = charge
        if gel is None:
            gel = plan['sans_hausse'] or plan.get('reprise')
        # 1.0.3 (contrat § 6.3, mesuré en KM1c3) : après un échec non prévu à
        # la dernière séance de l'exercice, 0.3.1 interdit toute hausse par
        # rapport à cette séance, quel que soit le schéma (`track.noUp` →
        # `lastAny`) ; Koach 1.0.2 ne l'interdisait que sur le même schéma
        # (`avant[1]`). `echec_sans_hausse_tout_schema` : 1 = règle de 0.3.1 ;
        # 2 = seulement quand les notes ne sont pas fiables (κ > 1) ; 0 = 1.0.2.
        mode_echec = s.get('echec_sans_hausse_tout_schema', 0)
        if mem.echec and mem.charge_derniere is not None and mode_echec \
                and (mode_echec == 1 or self.m.elargissement() > 1.0):
            if charge > mem.charge_derniere:
                charge = mem.charge_derniere
        if avant is not None:
            if gel or avant[1]:
                if charge > avant[0]:
                    charge = avant[0]
            else:
                haut = (avant[0] + bw) * (1 + h) - bw
                if charge > haut:
                    cran = grille.suivant(avant[0])
                    charge = max(grille.plancher(haut), min(charge, cran))
        else:
            # Schéma nouveau à cet emplacement : pas plus de 10 % (ou un
            # cran) au-dessus de la plus lourde barre réussie des 42 derniers
            # jours, +2,5 % par répétition de moins (4 au plus). Zone fragile
            # du profil : moitié de la hausse et aucune part pour les
            # répétitions de moins (A/coach.dart:1218-1226).
            haut = None
            for (j, c, r) in mem.charges_reussies:
                if self.jour - j > s['barre_recente_j']:
                    continue
                moins = r - hi
                if moins < 0 or profil:
                    moins = 0
                if moins > s['schema_change_reps_max']:
                    moins = s['schema_change_reps_max']
                if gel or douleur:
                    borne = c
                else:
                    hp = s['premiere_hausse'] * (s['hausse_fragile_facteur'] if profil else 1.0)
                    borne = (c + bw) * (1 + hp) * (1 + s['schema_change_part'] * moins) - bw
                    borne = max(grille.plancher(borne), grille.suivant(c))
                if haut is None or borne > haut:
                    haut = borne
            if haut is None and mem.charge_derniere is not None and (gel or douleur):
                # 1.0.2 — schéma nouveau et aucune barre réussie depuis
                # `barre_recente_j` jours (retour d'une longue coupure, bloc
                # nouveau) : repli de 0.3.1 sur la dernière charge de
                # l'exercice (`recentHeavy ?? lastAny`, A/coach.dart:1236-1250),
                # sans hausse un jour gelé (reprise, bilan bas, douleur). Hors
                # gel, comme en 1.0 et 1.0.1 : la charge que l'estimation
                # demande (0.3.1 admet alors la charge écrite du bloc).
                if gel or douleur:
                    haut = mem.charge_derniere
            if haut is not None and charge > haut:
                charge = haut
        # A7.2 règle 4 : schéma différent de la dernière séance du même
        # emplacement ; charge totale au plus base × (1 + hausse) × (1 + 2,5 %
        # par répétition de moins, 4 au plus ; aucune sur zone fragile), un cran
        # au moins au-dessus de la base ; base = dernière séance d'une semaine
        # de charge, hors jour de bilan bas (A/coach.dart:605-617, 1200-1235).
        marque = mem.marques.get(item['slotId'])
        if marque is not None and marque[2] is not None and marque[2] != hi:
            base = marque[0] if marque[0] is not None else marque[1]
            if base is not None:
                ecart = marque[2] - hi
                reps = 0 if (ecart <= 0 or fragile) else min(ecart, s['schema_change_reps_max'])
                cap = grille.plancher((base + bw) * (1 + h) * (1 + s['schema_change_part'] * reps) - bw)
                pas = grille.suivant(grille.plancher(base))
                plafond = cap if cap > pas else pas
                if charge > plafond + 1e-9:
                    charge = plafond
        if profil and charge < avant_bornes:
            self._raison('koach.zone_fragile', exercice=ex_id, zone=profil, cause='hausse')
        return charge

    def borne_externe(self, item, index, charge):
        """Charge proposée hors de la prescription (bras d'intensité d'un essai
        N-of-1, par exemple) ramenée sous les garde-fous de la séance. Renvoie
        None si aucune hausse n'est permise sur cette ligne aujourd'hui (jour
        sans hausse ou bilan bas, semaine verrouillée, plafond de part, dose
        plafonnée, zone douloureuse, en reprise ou fragile, échec dans la
        séance, test), sinon la charge bornée par les bornes de hausse d'une
        séance à l'autre et, à partir de la deuxième série, par +5 % (un cran)
        sur la série précédente. Lecture seule : aucun état n'est modifié."""
        plan = self.plans.get(item.get('slotId'))
        if plan is None or plan['type'] != 'charge' or plan['test']:
            return None
        cond = plan['cond']
        if plan['sans_hausse'] or plan.get('reprise') or plan['verrou'] or plan['part_max'] is not None \
                or plan.get('dose_plafonnee') \
                or cond['zone'] or cond['raison'] or plan.get('fragile') or plan['echecs'] > 0 \
                or plan['baisse'] < 1.0 or item.get('koachFragile'):
            return None
        ex_id = item['exerciseId']
        t = self.m.pistes.get(ex_id)
        grille = plan['grille']
        if t is None or grille is None:
            return None
        lo, hi = self._plages(item, index)
        n = len(self.raisons)
        charge = self._bornes_hausse(ex_id, item, charge, plan, t, grille, hi, index)
        del self.raisons[n:]
        bw = t.fraction * self.m.poids_kg
        if index >= 1 and plan.get('charge_item') is not None:
            haut = (plan['charge_item'] + bw) * 1.05 - bw
            if charge > haut:
                charge = max(grille.plancher(haut), min(charge, grille.suivant(plan['charge_item'])))
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
        libre = not (plan['verrou'] or plan['sans_hausse'] or plan['cond']['raison'] or plan['echecs'] > 0
                     or plan.get('dose_plafonnee'))
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
        if plan.get('dose_plafonnee') and index >= 1 and mem.reps_seance is not None and haut > mem.reps_seance:
            # Dose plafonnée : jamais plus de répétitions que la série
            # précédente (`clampLocked`, A/coach_advice.dart:133-149).
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
        # Plafond des tenues sur la valeur centrale du maximum du jour, jamais
        # sur un quantile haut (`coachHoldMaxShare`, A/coach.dart:1463-1467).
        plaf = int(math.floor(self.s['tenue_part_max'] * math.exp(mu)))
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
            borne = max(int(math.floor(mem.sec_max * (1 + h))), mem.sec_max + self.s['tenue_hausse_marge_s'])
            if haut > borne:
                haut = borne
                self._raison('koach.tendon', exercice=ex_id)
        if (plan['sans_hausse'] or mem.echec) and mem.sec_max is not None and haut > mem.sec_max:
            haut = mem.sec_max
        if plan['echecs'] > 0 and mem.sec_seance is not None and haut > mem.sec_seance:
            haut = mem.sec_seance
        if plan.get('dose_plafonnee') and index >= 1 and mem.sec_seance is not None and haut > mem.sec_seance:
            # Dose plafonnée : jamais plus long que la tenue précédente
            # (`clampLocked`, A/coach_advice.dart:133-149).
            haut = mem.sec_seance
        tot = mem.sec_slot.get(item['slotId'])
        n = item.get('sets') or 0
        if bras_tendus and h is not None and tot and n > 1:
            # A9.1 : temps total sous tension de l'emplacement borné comme une
            # tenue (« un seul changement à la fois », A/coach.dart:1895-1929) ;
            # sans le plancher de 55 % du meilleur maintien (plus prudent).
            most = max(int(math.floor(tot * (1 + h))), tot + self.s['tenue_hausse_marge_s'])
            if haut * n > most:
                chacune = most // n if most // n >= 1 else 1
                if haut > chacune:
                    haut = chacune
                    self._raison('koach.tendon', exercice=ex_id, cause='total')
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
            if plan.get('durs_max') is not None and plan.get('durs', 0) >= plan['durs_max']:
                # Budget de séries dures de la montée atteint (séries écrites
                # de la ligne moins une série de travail gardée).
                return None
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
            ecrite = item.get('startLoadKg')
            if plan['verrou'] and ecrite is not None and charge > ecrite + 1e-9:
                # A6.5 : semaine allégée ou de test, jamais plus lourd que la
                # charge écrite (A/coach.dart:2144-2152).
                charge = ecrite if grille.plancher(ecrite) > ecrite else grille.plancher(ecrite)
            evenement = bool((self.contexte or {}).get('jour_evenement'))
            if (plan['sans_hausse'] or mem.echec or (plan.get('reprise') and not evenement)) \
                    and mem.charge_derniere is not None and charge > mem.charge_derniere:
                # Après un échec non prévu à la dernière séance aussi (`noUp`,
                # A/coach.dart:2086, 2154-2160) ; la semaine du retour d'une
                # coupure, hors jour d'épreuve (1.0.2 : le jour d'épreuve, le
                # test suit l'estimation, comme les tentatives).
                charge = mem.charge_derniere
            if plan.get('reprise') and evenement:
                # Jour d'épreuve en semaine de retour : le test suit
                # l'estimation, sous le palier des barres récentes ramené
                # aux répétitions du test (`_palier_barres`, comme
                # l'ouverture des tentatives).
                bw = t.fraction * self.m.poids_kg
                autorise = self._palier_barres(mem, bw)
                if autorise is not None:
                    moins = hi - 1
                    if moins > self.s['schema_change_reps_max']:
                        moins = self.s['schema_change_reps_max']
                    borne = (autorise + bw) / (1 + self.s['schema_change_part'] * (moins if moins > 0 else 0)) - bw
                    if charge > borne:
                        charge = grille.plancher(max(borne, grille.minimum))
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
        # 1.0.3 : écart-type brut (la borne large `mu + 2,5·σ` ne doit pas
        # monter avec l'élargissement de la fiabilité : il irait dans le
        # sens moins prudent).
        mu, sd = self.m.capacite_du_jour(ex_id, brut=True)
        lam, k = self.m.courbe(t)
        if index == 0:
            voulu = self.charge_pour(ex_id, n_t, rir_t + 2.0, 0.5)
            recente = None
            for (j, c, r) in mem.charges_reussies:
                if self.jour - j <= self.s['barre_recente_j'] and (recente is None or c > recente):
                    recente = c
            if recente is None:
                return None   # pas de barre récente : pas de rampe
            # Première barre de la montée : jamais plus que ce que les barres
            # réussies des 42 derniers jours justifient, avec la règle du
            # premier passage à un schéma de 0.3.1 (A7.2, déjà celle de
            # l'ouverture d'une tentative) : hausse du niveau, et +2,5 % par
            # répétition faite au-delà de celles de la montée (4 au plus). Partir de
            # +10 % sur une barre de 10 répétitions faisait commencer une
            # montée de 3 répétitions à 7 répétitions de l'échec : la montée
            # s'arrêtait, faute de séries, avant d'avoir rien mesuré.
            # (hausse du niveau, 10 % débutant et 5 % ensuite, comme A7.2.4 ;
            # jamais moins que l'ancien plafond : +10 % sur la plus lourde.)
            plafond = (recente + bw) * (1 + ta['repere_hausse']) - bw
            hausse = self.s['hausse_par_niveau'][self.g.niveau]
            for (j, c, r) in mem.charges_reussies:
                if self.jour - j > self.s['barre_recente_j']:
                    continue
                plus = r - n_t
                if plus < 0:
                    plus = 0
                if plus > self.s['schema_change_reps_max']:
                    plus = self.s['schema_change_reps_max']
                b = (c + bw) * (1 + hausse) * (1 + self.s['schema_change_part'] * plus) - bw
                if b > plafond:
                    plafond = b
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
            elif (suivant + bw) <= (plan['charge_item'] + bw) * (1 + ta['rampe_pas_cran']) + 1e-9 \
                    and dit >= rir_t + ta['rampe_cran_rir_marge'] - 1e-9:
                # Grille grossière : un cran entier, seulement après une série
                # dite très facile et si le modèle tient la barre pour faisable.
                pr = self.proba_reussite(ex_id, suivant, n_t)
                if pr is None or pr < ta['rampe_proba_min']:
                    return None
                charge = suivant
            else:
                return None
        # L'effort affiché d'une série de montée est « deux en réserve » :
        # les répétitions demandées sont faites tant qu'il reste de la marge.
        return {'repsLow': n_t, 'repsHigh': n_t, 'loadKg': charge, 'flames': flammes_de_rir(2.0),
                'role': 'test', 'repere': True, 'trace': ['vrai test %.1f' % charge]}

    def _palier_barres(self, mem, bw):
        """Palier (charge externe pour UNE répétition) que les barres des
        `barre_recente_j` derniers jours autorisent, ou None sans barre
        récente (1.0.2, C13.12). Chaque barre réussie est ramenée à une
        répétition (+`schema_change_part` par répétition faite au-delà de la
        première, `schema_change_reps_max` au plus). Le palier part de la
        plus lourde ; il ne monte au-dessus d'elle que si toutes les barres
        proches (à `tentative_palier_bande` près) ont été dites faciles : la
        hausse est celle de la note la plus dure parmi elles
        (`tentative_palier_par_rir`), nulle dès qu'une de ces barres n'est
        pas notée ou est dite à moins d'une répétition de l'échec. Il reste
        sous la plus légère barre ratée sans une répétition faite pendant la
        même période, quand elle est plus lourde que la plus lourde barre
        réussie."""
        s = self.s
        # 1.0.3 (contrat § 5.13, § 6.5 ; mesuré en KM1c3) : notes peu fiables
        # (κ > 1) : le palier accordé par la note d'une barre est réduit
        # (× max(0 ; 1 − tentative_palier_fiabilite·(κ − 1)) : nul dès que κ
        # ≥ 1 + 1/c), et chaque barre réussie ne vaut que (1 − marge) de sa
        # charge, marge = min(tentative_marge_fiabilite_max ;
        # tentative_marge_fiabilite·(κ − 1)) : chez un athlète dont les notes
        # se sont montrées peu fiables, l'estimation n'est pas une preuve, et
        # une barre réussie dans les 42 jours ne prouve le maximum
        # d'aujourd'hui qu'à la variation de jour près. κ = 1 : règle de 1.0.2.
        kappa = self.m.elargissement()
        g_pas = 1.0
        marge = 0.0
        if kappa > 1.0:
            g_pas = 1.0 - s.get('tentative_palier_fiabilite', 0.0) * (kappa - 1.0)
            if g_pas < 0.0:
                g_pas = 0.0
            marge = s.get('tentative_marge_fiabilite', 0.0) * (kappa - 1.0)
            mx = s.get('tentative_marge_fiabilite_max', 0.0)
            if marge > mx:
                marge = mx
        plus_haute = None
        ramenees = []
        for (j, c, r, f) in mem.barres:
            if self.jour - j > s['barre_recente_j']:
                continue
            plus = r - 1
            if plus > s['schema_change_reps_max']:
                plus = s['schema_change_reps_max']
            total = (c + bw) * (1 + s['schema_change_part'] * plus)
            dit = rir_de_flammes(f)
            pas = 0.0
            if dit is not None:
                for (seuil, p_) in s['tentative_palier_par_rir']:
                    if dit >= seuil - 1e-9:
                        pas = p_
                        break
            pas *= g_pas
            if marge > 0.0:
                total *= 1.0 - marge
            ramenees.append((total, pas))
            if plus_haute is None or total > plus_haute:
                plus_haute = total
        if plus_haute is None:
            return None
        pas = None
        for (total, p_) in ramenees:
            if total >= plus_haute * (1 - s['tentative_palier_bande']) - 1e-9 and (pas is None or p_ < pas):
                pas = p_
        autorise = plus_haute * (1 + pas)
        for (j, c) in mem.barres_ratees:
            if self.jour - j > s['barre_recente_j']:
                continue
            ratee = c + bw
            if ratee > plus_haute + 1e-9 and autorise > ratee * (1 - s['schema_change_part']):
                # Barre ratée récemment, plus lourde que tout ce qui a été
                # réussi : on reste un palier dessous.
                autorise = max(plus_haute, ratee * (1 - s['schema_change_part']))
        return autorise - bw

    def _tentative(self, item, index, plan, t):
        """Échelle des tentatives (règles A8.2 de 0.3.1, probabilités de
        Koach) : ouverture sûre, puis la barre la plus lourde qui garde la
        probabilité voulue ; la cible du profil est tentée à la dernière barre
        quand elle est atteignable."""
        s = self.s
        ex_id = item['exerciseId']
        grille = plan['grille']
        mem = self.mem(ex_id)
        # 1.0.3 : écart-type brut (sans l'élargissement κ de la fiabilité des
        # notes) : l'ouverture au quantile élargi a été mesurée en KM1c3
        # (coût sans gain, CHANGEMENTS_1_0_3.md § B) ; la prudence envers des
        # notes peu fiables passe par le palier des barres prouvées
        # (`_palier_barres`) et la barre suivante après un échec.
        mu, sd = self.m.capacite_du_jour(ex_id, brut=True)
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
            # A8.2 de 0.3.1 : avant la première barre seulement, le maximum
            # estimé du jour est relevé du gain de l'affûtage quand la
            # semaine du jour (ou la précédente) est d'affûtage ou de
            # compétition (`coachTaperGain` 0,02 en 0.3.1 ; ici le gain
            # mesuré sur le banc, plus petit).
            sem = (self.contexte or {}).get('semaine')
            if sem is not None and (self.genres.get(sem) in ('taper', 'competition')
                                    or self.genres.get(sem - 1) in ('taper', 'competition')):
                mu += self.p['planification']['gain_affutage']
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
            # Incertitude élargie (diagnostic « rien de spécial », coupure) :
            # le quantile prudent peut tomber très bas. Une barre déjà
            # réussie dans les 42 jours reste une ouverture sûre : elle sert
            # de plancher, sans dépasser le plafond d'ouverture, et pas un
            # jour de bilan bas ou de zone douloureuse.
            if recente is not None and recente > charge and baisse >= 1.0 \
                    and not plan['sans_hausse'] and self.coupure == 0 and not mem.echec:
                plafond = s['tentative_ouverture_part'] * math.exp(mu) - bw
                charge = grille.plancher(max(min(recente, plafond), charge))
            # 1.0.2 — paliers mesurés (C13.12). L'ouverture suit la capacité
            # estimée, sans dépasser le palier que les barres réussies des
            # 42 derniers jours autorisent selon ce que l'athlète en a dit
            # (`_palier_barres`). Une estimation plus haute que tout ce qui a
            # été soulevé ne fait donc ouvrir plus lourd que si les barres
            # les plus lourdes ont été dites faciles. (1.0 et 1.0.1 : +10 %
            # sur toute barre réussie, notée ou non, et jamais plus que le
            # dernier passage en semaine de retour de coupure — ancrage sur
            # des séries légères mesuré sur le banc adversarial.)
            autorise = self._palier_barres(mem, bw)
            if autorise is not None and charge > autorise:
                charge = grille.plancher(max(autorise, grille.minimum))
            return {'repsLow': 1, 'repsHigh': 1, 'loadKg': charge, 'flames': flammes, 'role': 'attempt'}
        derniere = mem.charge_seance
        dernier_essai = index >= n - 1
        proba = s['tentative_troisieme_proba'] if dernier_essai else s['tentative_deuxieme_proba']
        if plan['echecs'] > 0 and mem.echec_seance:
            # Règle A8.2 de 0.3.1 : la même barre après un échec (en
            # compétition, le règlement interdit de redescendre). 1.0.3
            # (contrat § 6.5, mesuré en KM1c3) : hors semaine de compétition
            # (test 1RM à l'entraînement), la barre suivante suit
            # l'estimation mise à jour par l'échec, au plus
            # `tentative_echec_baisse_part` sous la barre ratée (0 : règle
            # A8.2 partout), jamais au-dessus.
            part_baisse = s.get('tentative_echec_baisse_part', 0.0)
            sem = (self.contexte or {}).get('semaine')
            competition = sem is not None and self.genres.get(sem) == 'competition'
            if part_baisse > 0.0 and not competition:
                bas = max((derniere + bw) * (1 - part_baisse) - bw, grille.minimum)
                plancher_ = grille.plancher(bas)
                if plancher_ < bas - 1e-9:
                    plancher_ = grille.suivant(plancher_)      # au plus `part` sous la barre ratée : cran au-dessus
                c = plus_lourde(proba)
                if c < plancher_:
                    c = plancher_
                if c > derniere:
                    c = derniere
                return {'repsLow': 1, 'repsHigh': 1, 'loadKg': c, 'flames': flammes, 'role': 'attempt'}
            return {'repsLow': 1, 'repsHigh': 1, 'loadKg': derniere, 'flames': flammes, 'role': 'attempt'}
        saut = s['tentative_saut_3'] if dernier_essai else s['tentative_saut_2']
        charge = plus_lourde(proba)
        haut = min((derniere + bw) * (1 + saut) - bw, derniere + s['tentative_saut_kg'])
        cible = item.get('koachCible')
        if dernier_essai and cible is not None and derniere < cible <= haut + 1e-9:
            p = self.proba_reussite(ex_id, cible, 1, brut=True)
            if p is not None and p >= 0.35:
                charge = max(charge, cible)
        if charge > haut:
            charge = grille.plancher(haut)
        if charge < derniere:
            charge = derniere
        if charge <= derniere + 1e-9:
            charge = min(grille.suivant(derniere), max(grille.plancher(haut), derniere))
            f = mem.flammes_seance
            if charge <= derniere + 1e-9 and f is not None and f <= (7 if index == 1 else 9) \
                    and grille.suivant(derniere) - derniere <= s['tentative_saut_kg'] + 1e-9:
                # 1.0.2 : saut en pourcentage plus petit qu'un cran de la
                # grille (barre légère) — un cran reste permis (« un cran
                # toujours permis », A7.2) quand la barre précédente a été
                # dite au plus aussi dure que visé, dans la limite du saut en
                # kilos.
                charge = grille.suivant(derniere)
            p = self.proba_reussite(ex_id, charge, 1, brut=True)
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
            if plan.get('reprise'):
                # Palier de reprise franchi : série faite en entier, sans
                # échec, notée, dite au plus aussi dure que visé.
                cible = s.get('target') or {}
                f = s.get('flames')
                fc = cible.get('flames')
                bas = cible.get('repsLow')
                franchi = (not echec and f is not None and fc is not None and f <= fc
                           and bas is not None and (s.get('reps') or 0) >= bas)
                plan['palier_franchi'] = franchi
            if echec and not plan['test']:
                plan['echecs'] += 1
                plan['baisse'] = 1.0 - self.s['echec_baisse']
            elif echec:
                plan['echecs'] += 1
            if plan['test'] and 'durs' in plan:
                f = s.get('flames')
                if echec or f is None or f >= 3:
                    plan['durs'] += 1

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
                    mem.barres.append((jour, c, r, s.get('flames')))
                if c is not None and c >= 0 and s.get('failed') and not r:
                    mem.barres_ratees.append((jour, c))
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
                self._marquer(mem, slot, series, hi)
            if slot is not None:
                tot = 0
                for x in series:
                    if x.get('kind') != 'warmup' and (x.get('target') or {}).get('role') not in ('test', 'attempt'):
                        tot += x.get('seconds') or 0
                if tot > 0:
                    mem.sec_slot[slot] = tot
        self._formes(par_ex)
        self._fermer_volume(record.get('sets') or [])
        self._fermer_endurance(record.get('sets') or [])
        self.jours_seances.append(jour)
        if len(self.jours_seances) > 20:
            self.jours_seances = self.jours_seances[-20:]
        self.derniere_seance = jour

    def _marquer(self, mem, slot, series, hi):
        """Dernière séance de l'emplacement (règle du schéma changé, A7.2) :
        charge de base = la plus légère charge échouée, sinon la plus forte
        réussie ; une semaine verrouillée ou un jour de bilan bas ne remplace
        pas la base de semaine de charge (A/coach.dart:605-617)."""
        held = None
        echouee = None
        for x in series:
            c = x.get('externalLoadKg')
            if x.get('kind') == 'warmup' or c is None or c < 0:
                continue
            if x.get('failed'):
                if echouee is None or c < echouee:
                    echouee = c
            elif (x.get('reps') or 0) > 0 and (held is None or c > held):
                held = c
        base = echouee if echouee is not None else held
        avant = mem.marques.get(slot)
        if self.verrouillee() or self.palier >= 1:
            base_charge = None if avant is None else (avant[0] if avant[0] is not None else avant[1])
        else:
            base_charge = base
        mem.marques[slot] = (base_charge, base, hi)

    def _forme(self, ex_id):
        """ln capacité à frais + effet de jour de la séance (mélange des deux
        branches) : la performance mesurée de la séance, analogue de
        `f.m[0] + f.m[3]` de 0.3.1 (A/model.dart:1470-1471)."""
        m = self.m
        t = m.pistes[ex_id]
        idx, co = m._h_capacite(t, jour=False)
        idx = idx + [DS]
        co = co + [1.0]
        mu = m._stats(m.m, m.P, idx, co)[0]
        if m.alt is not None:
            w = m.poids_mauvais_jour()
            mu1 = m._stats(m.alt[0], m.alt[1], idx, co)[0]
            mu = (1 - w) * mu + w * mu1
        return t.base + mu

    def _formes(self, par_ex):
        """A6.2 : alerte de surmenage d'un mouvement principal — deux séances
        mesurées de suite au moins `surmenage_baisse` sous la séance de
        référence, les trois en `surmenage_fenetre_j` jours au plus ; la
        séance d'alerte devient la référence (`formAfter`,
        A/model.dart:432-475)."""
        s = self.s
        vus = []
        for (ex_id, slot), series in par_ex.items():
            plan = self.plans.get(slot)
            if plan is None or plan['role'] != 'main' or plan['type'] not in ('charge', 'reps', 'tenue') \
                    or ex_id in vus or self.m.pistes.get(ex_id) is None:
                continue
            if not any(x.get('kind') != 'warmup' and ((x.get('reps') or 0) > 0 or (x.get('seconds') or 0) > 0
                                                      or x.get('failed')) for x in series):
                continue
            vus.append(ex_id)
            mem = self.mem(ex_id)
            if self.m.pistes[ex_id].seances < s['surmenage_seances_min']:
                # Estimation pas encore posée : une baisse de la capacité
                # estimée pendant les premières séances est de l'apprentissage
                # (a priori trop haut), pas du surmenage.
                continue
            suite = [e for e in mem.forme if e[0] != self.jour] + [(self.jour, self._forme(ex_id))]
            while len(suite) > 3:
                suite.pop(0)
            if len(suite) == 3 and self.jour - suite[0][0] <= s['surmenage_fenetre_j']:
                limite = suite[0][1] + math.log(1 - s['surmenage_baisse'])
                if suite[1][1] <= limite and suite[2][1] <= limite:
                    meilleure = suite[1][1] if suite[1][1] > suite[2][1] else suite[2][1]
                    mem.alerte_jour = self.jour
                    mem.alerte_part = math.exp(meilleure - suite[0][1])
                    suite = [suite[2]]
            mem.forme = suite

    def _fermer_endurance(self, sets):
        """Ce que la séance dit de l'endurance (`EnduranceHistory.of`,
        A/endurance.dart:118-187) : jour d'entraînement, course (durée,
        effort noté le plus haut et sa cible), course dure, conditionnement
        dur, vitesse de course."""
        s = self.s
        jour = self.jour
        utiles = [x for x in sets if x.get('kind') != 'warmup' and not x.get('excluded')]
        for x in sets:
            if x.get('excluded') or self._nature(x['exerciseId']) != 'course':
                continue
            m_ = x.get('distanceMeters')
            t_ = x.get('seconds')
            if m_ is not None and t_ is not None and m_ > 0 and t_ > 0:
                self.course_metres += m_
                self.course_secondes += t_
        vitesse = self._vitesse()
        secondes = 0.0
        pire = None
        cible = None
        dur_wod = False
        dure = False
        for x in utiles:
            n = self._nature(x['exerciseId'])
            f = x.get('flames')
            if n == 'conditionnement' and f is not None and f >= s['endurance_dure_flammes']:
                dur_wod = True
            if n != 'course':
                continue
            t_ = x.get('seconds')
            m_ = x.get('distanceMeters')
            secondes += float(t_) if t_ is not None else (0.0 if m_ is None else m_ / vitesse)
            if f is not None and (pire is None or f > pire):
                pire = f
                cible = (x.get('target') or {}).get('flames')
                if cible is None:
                    plan = self.plans.get(x.get('slotId'))
                    if plan is not None and plan.get('servi') is not None:
                        cible = plan['servi'].get('targetFlames')
            if f is not None and f >= s['endurance_dure_flammes']:
                dure = True
        bas = jour - 60
        if utiles:
            self.jours_actifs = [j for j in self.jours_actifs if j >= bas] + [jour]
        if secondes > 0:
            self.courses = [e for e in self.courses if e[0] >= bas] + [(jour, secondes, pire, cible)]
        if dur_wod:
            self.jours_durs = [j for j in self.jours_durs if j >= bas] + [jour]
        if dure:
            self.jours_course_dure = [j for j in self.jours_course_dure if j >= bas] + [jour]
