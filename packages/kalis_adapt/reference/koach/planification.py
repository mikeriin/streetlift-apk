# -*- coding: utf-8 -*-
"""Planification de Koach 1.0 (cahier KM § 1, 5 et 6 ; CONTRAT_1_0.md § 3
`plan`, horizon « semaine »).

Chaque lundi, Koach replanifie de la semaine suivante jusqu'à l'échéance :

* **objectif** : avec échéance, P(toutes les cibles atteintes à la date) ;
  sans échéance, progression attendue × P(continuer 12 semaines) ;
* **jumeau numérique** : 1 000 trajectoires tirées de l'a posteriori
  (capacités, réponse à l'entraînement, hypothèse de dose), nombres
  aléatoires communs entre plans candidats ;
* **recherche** par entropie croisée, 256 plans évalués au plus ;
* **optimisation bornée** : le plan de référence est la sortie de
  `kalis_plan` ; pénalité λ × distance de transport optimal entre les
  distributions de stimulus du plan et de la référence ; plafonds durs par
  bloc, volume par qualité ±15 %, intensité moyenne ±5 % ;
* **sécurité** : les semaines verrouillées (allègement, affûtage, test,
  compétition, transition, introduction) ne reçoivent ni volume ni intensité
  en plus ; le rapport charge tendineuse de la semaine / charge habituelle est
  plafonné ; le plan retenu passe le validateur des critères de sécurité de
  0.3.1 (injecté), sinon il est ramené vers la référence.

Koach ne change que le volume (séries) et l'intensité (charge) du plan écrit.
La structure (exercices, jours, schémas) reste celle de la référence ; elle
ne se modifie qu'aux frontières de bloc, par le générateur de blocs.

Tout est déterministe : graine dérivée de `planification.graine` et du numéro
de semaine, générateur mulberry32.
"""
import copy
import math

import numpy as np

from .modele import NQ, RHO, EPS, KG, CLASSES, C_LIN, C_LOG
from .moteur import Extension
from .numerique import Mulberry32, fnv1a32, clamp, cholesky_semi, arrondi

SEMAINES_VERROUILLEES = ('intro', 'deload', 'taper', 'test', 'competition', 'transition')
GRILLE_INTENSITE = (-0.05, -0.025, 0.0, 0.025, 0.05)


def rir_de_flammes(f, defaut=2.5):
    if f is None:
        return defaut
    return 0.0 if f >= 10 else (11 - f) / 2.0


def semaines_de_reference(blocs, block_weeks, horizon):
    """Semaines écrites du plan de référence : liste, par semaine globale, de
    {'bloc', 'semaine_bloc', 'genre', 'intention', 'jours': [(jour, items)]}
    ou None quand la semaine n'est pas écrite."""
    out = []
    n = len(blocs)
    debuts = list(block_weeks) if block_weeks else [0]
    for w in range(horizon):
        k = 0
        for j in range(len(debuts)):
            if debuts[j] <= w:
                k = j
        if k >= n:
            out.append(None)
            continue
        wb = w - debuts[k]
        ecrite = None
        for s in blocs[k]['pass2']['weeks']:
            if s['weekIndex'] == wb:
                ecrite = s
        if ecrite is None:
            out.append(None)
            continue
        jours = [(d['dayIndex'], d['items']) for d in ecrite['days']]
        out.append({'bloc': k, 'semaine_bloc': wb, 'genre': ecrite.get('kind'),
                    'intention': ecrite.get('intent'), 'jours': jours})
    return out


def verrouillee(semaine):
    g = semaine.get('intention') or semaine.get('genre')
    return g in SEMAINES_VERROUILLEES or semaine.get('genre') in ('deload', 'test', 'intro')


class Planification(Extension):
    """Extension de planification : replanification hebdomadaire."""

    def __init__(self, params, fiches, validateur=None, options=None):
        """[validateur] : fonction(blocs) -> liste de constats de sécurité
        (critères de 0.3.1 lus sur les blocs) ; [options] : surcharge de
        `params['planification']` (banc : moins de trajectoires)."""
        self.params = params
        self.p = dict(params['planification'])
        self.p.update(options or {})
        self.fiches = fiches
        # Le validateur de sécurité est obligatoire : sans lui aucun plan
        # modulé n'est contrôlé. `options['sans_validateur']` (essais de
        # parité numérique seulement) le remplace par un refus de TOUTE
        # modulation qui s'écarte de la référence au-delà des plafonds.
        if validateur is None and not (options or {}).get('sans_validateur'):
            raise ValueError('Planification : validateur de sécurité obligatoire')
        self.validateur = validateur
        self.semaines = []
        self.blocs = None
        self.block_weeks = None
        self.horizon = 0
        self.cibles = {}          # exercice -> charge totale visée (kg) ou valeur visée
        self.echeance_jour = None
        self.suivis = []          # exercices suivis par le jumeau
        self.plan = {}            # semaine -> {'volume': [NQ facteurs], 'intensite': i}
        self.historique = []      # une ligne par replanification
        self.constats_reference = None
        self.poids_corps = 72.0

    # ------------------------------------------------------------------
    # Référence
    # ------------------------------------------------------------------
    def charger_reference(self, blocs, block_weeks, horizon, cibles=None, echeance_jour=None,
                          principaux=None, poids_corps=None):
        """Plan de référence (blocs de `kalis_plan`), cibles {exercice:
        valeur visée (charge TOTALE pour un exercice chargé)}, jour de
        l'échéance (indice de jour depuis le début) ou None."""
        self.blocs = blocs
        self.block_weeks = list(block_weeks) if block_weeks else [0]
        self.horizon = horizon
        self.semaines = semaines_de_reference(blocs, self.block_weeks, horizon)
        self.cibles = dict(cibles or {})
        self.echeance_jour = echeance_jour
        if poids_corps:
            self.poids_corps = float(poids_corps)
        suivis = [e for e in sorted(self.cibles)]
        for e in principaux or []:
            if e not in suivis:
                suivis.append(e)
        self.suivis = [e for e in suivis if e in self.fiches]
        self.plan = {}
        self.constats_reference = None
        self._tables = {}

    # ------------------------------------------------------------------
    # Stimulus d'une prescription écrite
    # ------------------------------------------------------------------
    def _courbe_population(self, bas):
        ap = self.params['a_priori']
        lam = ap['courbe_forme'][0]
        k = ap['courbe_echelle'][0] + (ap['courbe_bas_du_corps'] if bas else 0.0)
        return lam, k

    def _g(self, lam, k, r):
        r = 1.0 if r < 1 else r
        return math.exp(k) * ((1.0 - lam) * C_LIN * (r - 1.0) + lam * C_LOG * math.log(r))

    def _dg(self, lam, k, r):
        r = 1.0 if r < 1 else r
        return math.exp(k) * ((1.0 - lam) * C_LIN + lam * C_LOG / r)

    def lignes_item(self, item, ecart=0.0):
        """Séries d'une prescription sous un écart d'intensité : liste de
        (séries, réserve, part du 1RM ou None, secondes ou répétitions)."""
        if item.get('kind') == 'warmup':
            return []
        fiche = self.fiches.get(item['exerciseId'])
        if fiche is None:
            return []
        n = item.get('sets') or 0
        if n <= 0:
            return []
        test = item.get('test') or {}
        rir = rir_de_flammes(item.get('targetFlames'))
        if item.get('kind') == 'test':
            rir = test.get('targetRir', 1.0) if test.get('targetRir') is not None else 1.0
        lo = item.get('repsLow')
        hi = item.get('repsHigh')
        reps = None
        if lo is not None or hi is not None:
            reps = ((lo if lo is not None else hi) + (hi if hi is not None else lo)) / 2.0
        sec = item.get('secondsHigh') if item.get('secondsHigh') is not None else item.get('secondsLow')
        quantite = reps if reps is not None else (sec / 10.0 if sec else 1.0)
        part = None
        pente = 0.03
        if fiche['type'] == 'charge':
            lam, k = self._courbe_population(fiche.get('bas', False))
            r = (reps if reps is not None else 8.0) + rir
            part = item.get('percentOfOneRm')
            if part is None:
                part = math.exp(-self._g(lam, k, r))
            pente = self._dg(lam, k, r)
        if ecart and part is not None:
            part = part * (1.0 + ecart)
            rir = rir - ecart / pente
            if rir < 0.5:
                rir = 0.5
        tech = item.get('technique') or {}
        if tech.get('kind') == 'top_set_backoff' and n >= 2 and part is not None:
            drop = tech.get('backoffDropPct') or 0.08
            return [(1, rir, part, quantite), (n - 1, rir + drop / pente, part * (1.0 - drop), quantite)]
        return [(n, rir, part, quantite)]

    def stimulus_item(self, item, ecart=0.0):
        """(volume, effort, intensité, charge systémique, charge tendineuse)
        d'une prescription, par convention identique à `Modele._stimulus`."""
        fiche = self.fiches.get(item['exerciseId']) or {}
        f = self.params['fatigue']
        vol = eff = inten = syst = tend = 0.0
        for (n, rir, part, quantite) in self.lignes_item(item, ecart):
            vol += n * (1.0 if rir <= 4 else 0.5)
            eff += n / (1.0 + (rir - 1 if rir > 1 else 0.0) / 3.0)
            pp = 1.0 if part is None else part
            inten += n * clamp((pp - 0.4) / 0.4, 0.2, 1.5)
            effort = 1.0 / (1.0 + (rir if rir > 0 else 0.0) / f['effort_demi_rir'])
            syst += n * effort * fiche.get('systemique', 1.0)
            tend += n * effort * fiche.get('tendon', 0.0) * (quantite if fiche.get('type') == 'tenue' else 1.0)
        return vol, eff, inten, syst, tend

    def _table(self, w):
        """Tables de la semaine écrite [w] : par point de la grille
        d'intensité, stimulus des exercices suivis (par unité de facteur de
        volume), charge systémique par qualité et par jour, masse de séries
        par qualité, part moyenne du 1RM par qualité, charge tendineuse par
        zone et par qualité."""
        if w in self._tables:
            return self._tables[w]
        s = self.semaines[w] if 0 <= w < len(self.semaines) else None
        if s is None:
            self._tables[w] = None
            return None
        E = len(self.suivis)
        G = len(GRILLE_INTENSITE)
        stim = np.zeros((G, E, 3))
        syst = np.zeros((G, 7, NQ))       # par jour de la semaine
        masse = np.zeros(NQ)
        part_m = np.zeros(NQ)
        tendon = {}
        for (jour, items) in s['jours']:
            d = jour % 7
            for item in items:
                fiche = self.fiches.get(item['exerciseId'])
                if fiche is None or item.get('kind') == 'warmup':
                    continue
                v = np.asarray(fiche['vecteur'])
                lignes = self.lignes_item(item, 0.0)
                n_tot = sum(l[0] for l in lignes)
                if n_tot <= 0:
                    continue
                masse += n_tot * v
                pm = sum(l[0] * (l[2] if l[2] is not None else 0.7) for l in lignes)
                part_m += pm * v
                for gi, ecart in enumerate(GRILLE_INTENSITE):
                    vol, eff, inten, sy, te = self.stimulus_item(item, ecart)
                    if item['exerciseId'] in self.suivis:
                        e = self.suivis.index(item['exerciseId'])
                        stim[gi, e, 0] += vol
                        stim[gi, e, 1] += eff
                        stim[gi, e, 2] += inten
                    syst[gi, d, :] += sy * v
                    if gi == 2 and te > 0 and fiche.get('zone_tendon'):
                        z = fiche['zone_tendon']
                        if z not in tendon:
                            tendon[z] = np.zeros(NQ)
                        tendon[z] += te * v
        for q in range(NQ):
            if masse[q] > 0:
                part_m[q] /= masse[q]
        t = {'stim': stim, 'syst': syst, 'masse': masse, 'part': part_m, 'tendon': tendon,
             'verrou': verrouillee(s), 'bloc': s['bloc']}
        self._tables[w] = t
        return t

    # ------------------------------------------------------------------
    # Jumeau numérique
    # ------------------------------------------------------------------
    def tirer(self, koach, semaine, n):
        """Tire [n] trajectoires de l'a posteriori : ln capacité des exercices
        suivis, réponse rho, écarts par classe, hypothèse de dose, bruits
        communs (jour de l'échéance, processus)."""
        m = koach.modele
        E = len(self.suivis)
        lignes = []
        moyennes = []
        for ex in self.suivis:
            m.piste(ex)               # crée les pistes avant de figer la taille de l'état
        for ex in self.suivis:
            t = m.piste(ex)
            h = np.zeros(m.n)
            base = 0.0
            if t is not None:
                idx, co = m._h_capacite(t, jour=False)
                for i, c in zip(idx, co):
                    h[i] += c
                base = t.base
            lignes.append(h)
            moyennes.append(base + float(h @ m.m[:m.n]))
        for i in [RHO] + [EPS + c for c in range(len(CLASSES))]:
            h = np.zeros(m.n)
            h[i] = 1.0
            lignes.append(h)
            moyennes.append(float(m.m[i]))
        H = np.array(lignes)
        S = H @ m.P[:m.n, :m.n] @ H.T
        S = 0.5 * (S + S.T)
        # Racine de Cholesky en boucles explicites (portable à l'identique,
        # robuste à une covariance semi-définie).
        L = np.array(cholesky_semi(S.tolist()))
        rng = Mulberry32(fnv1a32('koach-plan:%d:%d' % (int(self.p['graine']), semaine)))
        k = S.shape[0]
        z = np.empty((n, k))
        for a in range(n):
            for b in range(k):
                z[a, b] = rng.gauss()
        x = np.asarray(moyennes)[None, :] + z @ L.T
        hyp = np.empty(n, dtype=int)
        poids = list(m.poids_hyp)
        tot = sum(poids)
        # Contrôle dual (cahier § 7) : quand le modèle est calibré, le
        # contrôle dual tire UNE hypothèse de dose pour la semaine (tirage
        # de Thompson) et le plan est optimisé sous elle ; sinon chaque
        # trajectoire tire la sienne selon les poids a posteriori. Les
        # tirages uniformes sont consommés dans les deux cas (mêmes nombres
        # aléatoires communs en aval).
        self.hypothese_thompson = None
        for x_ in koach.extensions:
            f = getattr(x_, 'hypothese_pour_la_semaine', None)
            if f is not None:
                self.hypothese_thompson = f(koach, semaine, int(self.p['graine']))
        for a in range(n):
            u = rng.next() * tot
            c = 0.0
            hyp[a] = len(poids) - 1
            for j, w in enumerate(poids):
                c += w
                if u < c:
                    hyp[a] = j
                    break
        if self.hypothese_thompson is not None:
            hyp[:] = int(self.hypothese_thompson)
        bruit_jour = np.empty((n, max(E, 1)))
        bruit_proc = np.empty((n, max(E, 1)))
        for a in range(n):
            for b in range(max(E, 1)):
                bruit_jour[a, b] = rng.gauss()
                bruit_proc[a, b] = rng.gauss()
        classes = []
        for ex in self.suivis:
            t = m.piste(ex)
            classes.append(t.classe if (t is not None and t.classe is not None) else 0)
        return {'mu': x[:, :E], 'rho': x[:, E], 'eps': x[:, E + 1:], 'hyp': hyp,
                'bruit_jour': bruit_jour, 'bruit_proc': bruit_proc, 'classes': classes,
                'fatigue': float(m.f_g[1]), 'kg': float(m.m[KG]), 'semaines': m.semaines,
                'hypotheses': list(m.hypotheses)}

    def _dimensions(self, depuis):
        """Blocs restants et qualités actives à partir de la semaine [depuis]."""
        blocs = []
        actives = np.zeros(NQ, dtype=bool)
        for w in range(depuis, self.horizon):
            t = self._table(w)
            if t is None:
                continue
            if t['bloc'] not in blocs:
                blocs.append(t['bloc'])
            actives |= t['masse'] > 0
        return blocs, [q for q in range(NQ) if actives[q]]

    def decoder(self, x, blocs, qualites):
        """Vecteur de recherche -> (volume[bloc][NQ], intensité[bloc])."""
        nq = len(qualites)
        vol = {}
        inten = {}
        pv = self.p['plafond_volume']
        pi = self.p['plafond_intensite']
        for j, b in enumerate(blocs):
            a = np.ones(NQ)
            for i, q in enumerate(qualites):
                a[q] = 1.0 + clamp(float(x[j * (nq + 1) + i]), -pv, pv)
            vol[b] = a
            inten[b] = clamp(float(x[j * (nq + 1) + nq]), -pi, pi)
        return vol, inten

    def evaluer(self, X, tirage, depuis, blocs, qualites, detail=False, echelle=None):
        """Valeur de chaque plan candidat (lignes de [X]) sous le jumeau.
        Renvoie (J, P par cible, distance de transport) ; avec [detail], un
        dictionnaire en plus pour le plan 0."""
        dyn = self.params['dynamique']
        pl = self.p
        C = X.shape[0]
        E = len(self.suivis)
        nq = len(qualites)
        pv = pl['plafond_volume']
        pi = pl['plafond_intensite']
        A = np.ones((C, len(blocs), NQ))
        I = np.zeros((C, len(blocs)))
        for j in range(len(blocs)):
            for i, q in enumerate(qualites):
                A[:, j, q] = 1.0 + np.clip(X[:, j * (nq + 1) + i], -pv, pv)
            I[:, j] = np.clip(X[:, j * (nq + 1) + nq], -pi, pi)
        V = np.array([self.fiches[ex]['vecteur'] for ex in self.suivis]) if E else np.zeros((0, NQ))
        hyps = tirage['hypotheses']
        nh = len(hyps)
        fin = self.horizon - 1
        jour_ech = self.echeance_jour
        if jour_ech is not None:
            fin = min(fin, jour_ech // 7)
        elif not self.cibles:
            fin = min(fin, depuis + int(pl['horizon_sans_echeance_sem']) - 1)
        F = np.full(C, tirage['fatigue'])
        gains = np.zeros((C, E, nh))
        transport = np.zeros(C)
        masse_ref = 0.0
        surcharge = np.zeros(C)
        penal = np.zeros(C)
        tendon_hist = {}
        f_ech = None
        ref_dose = float(dyn['dose_reference'])
        acc0 = tirage['semaines']
        for w in range(depuis, fin + 1):
            t = self._table(w)
            if t is None:
                F = F * math.exp(-7.0 / self._tau_lent())
                continue
            j = blocs.index(t['bloc'])
            a = A[:, j, :]
            i = I[:, j]
            if t['verrou']:
                a = np.minimum(a, 1.0)
                i = np.minimum(i, 0.0)
            # Interpolation linéaire sur la grille d'intensité.
            pos = (i - GRILLE_INTENSITE[0]) / (GRILLE_INTENSITE[1] - GRILLE_INTENSITE[0])
            g0 = np.clip(np.floor(pos).astype(int), 0, len(GRILLE_INTENSITE) - 2)
            fr = pos - g0
            stim = t['stim'][g0] * (1 - fr)[:, None, None] + t['stim'][g0 + 1] * fr[:, None, None]
            syst = t['syst'][g0] * (1 - fr)[:, None, None] + t['syst'][g0 + 1] * fr[:, None, None]
            fe = a @ V.T if E else np.zeros((C, 0))               # facteur de volume par exercice
            stim = stim * fe[:, :, None]
            charge_jour = np.einsum('cdq,cq->cd', syst, a)       # (C, 7)
            # Fatigue lente en fin de semaine, et au matin de l'échéance.
            decro = np.exp(-(7.0 - np.arange(7)) / self._tau_lent())
            if jour_ech is not None and w == jour_ech // 7:
                de = jour_ech % 7
                avant = np.array([math.exp(-(de - d) / self._tau_lent()) if d < de else 0.0 for d in range(7)])
                f_ech = F * math.exp(-de / self._tau_lent()) + charge_jour @ avant
            F = F * math.exp(-7.0 / self._tau_lent()) + charge_jour @ decro
            k_rec = 1.0 - dyn['recuperation_pente'] * np.maximum(F - dyn['recuperation_seuil'], 0.0) / dyn['recuperation_seuil']
            k_rec = np.maximum(k_rec, dyn['recuperation_plancher'])
            acc = 1.0 / (1.0 + (acc0 + (w - depuis)) / dyn['accoutumance_semaines'])
            for h, (s0, ks) in enumerate(hyps):
                sv = stim[:, :, ks]
                dose = (1.0 - np.exp(-sv / s0)) / (1.0 - math.exp(-ref_dose / s0))
                gains[:, :, h] += dose * (k_rec * acc)[:, None]
            # Transport optimal (1-D, par qualité) : la masse commune se
            # déplace de l'écart d'intensité, la masse créée ou retirée coûte
            # `transport_creation` par série.
            mr = t['masse']
            mp = a * mr[None, :]
            commun = np.minimum(mp, mr[None, :])
            transport += (commun * (t['part'][None, :] * np.abs(i)[:, None])).sum(axis=1) \
                + pl['transport_creation'] * np.abs(mp - mr[None, :]).sum(axis=1)
            masse_ref += float(mr.sum())
            # Charge de travail relative (sans échéance : P(continuer)).
            ref_charge = float(t['syst'][2].sum())
            if ref_charge > 0:
                surcharge += np.maximum(charge_jour.sum(axis=1) / ref_charge - 1.0, 0.0)
            # Tendons : charge de la semaine / moyenne des 4 semaines d'avant.
            for z, tq in t['tendon'].items():
                cw = a @ tq
                rw = float(tq.sum())
                hist = tendon_hist.setdefault(z, [])
                if len(hist) >= 1:
                    moy_c = sum(x[0] for x in hist[-4:]) / len(hist[-4:])
                    moy_r = sum(x[1] for x in hist[-4:]) / len(hist[-4:])
                    if moy_r >= pl['risque_tendon_plancher']:
                        limite = max(pl['risque_tendon_ratio_max'], rw / moy_r)
                        penal += (cw / np.maximum(moy_c, 1e-9) > limite + 1e-9).astype(float)
                hist.append((cw, rw))
        distance = transport / masse_ref if masse_ref > 0 else transport
        # Trajectoires.
        N = tirage['mu'].shape[0]
        hyp = tirage['hyp']
        P_cible = np.zeros((C, E))
        J = np.zeros(C)
        if E:
            taux = tirage['rho'][:, None] + tirage['eps'][:, tirage['classes']]       # (N, E)
            g_n = gains[:, :, hyp]                                                    # (C, E, N)
            semaines = max(1, fin + 1 - depuis)
            proc = math.sqrt(dyn['q_delta_semaine'] * semaines + pl['sigma_prevision_semaine'] ** 2 * semaines)
            mu_fin = tirage['mu'].T[None, :, :] + g_n * taux.T[None, :, :] + proc * tirage['bruit_proc'].T[None, :, :]
            if self.cibles and jour_ech is not None:
                j = self.params['jour']
                sd_jour = math.sqrt(j['sigma_seance'] ** 2 + j['sigma_exercice'] ** 2)
                fe = f_ech if f_ech is not None else F
                jour = mu_fin - tirage['kg'] * fe[:, None, None] + sd_jour * tirage['bruit_jour'].T[None, :, :]
                tout = np.ones((C, N), dtype=bool)
                for e, ex in enumerate(self.suivis):
                    if ex not in self.cibles:
                        continue
                    seuil = math.log(self.cibles[ex]) + pl['marge_cible']
                    ok = jour[:, e, :] >= seuil
                    P_cible[:, e] = ok.mean(axis=1)
                    tout &= ok
                J = tout.mean(axis=1)
            else:
                # Sans échéance : progression attendue (relative à celle du
                # plan de référence nul) × P(continuer).
                prog = (mu_fin - tirage['mu'].T[None, :, :]).mean(axis=(1, 2))
                p_cont = np.exp(-pl['abandon_hebdo'] * (semaines + pl['abandon_surcharge'] * surcharge))
                J = prog * p_cont
                if echelle:
                    J = J / echelle
        valeur = J - pl['lambda_transport'] * distance - penal
        if detail:
            return valeur, P_cible, distance, {'J': J, 'penal': penal, 'fatigue_fin': F,
                                               'fatigue_echeance': f_ech, 'gains': gains}
        return valeur, P_cible, distance

    def _tau_lent(self):
        return float(self.params['fatigue']['tau_musculaire_j'])

    # ------------------------------------------------------------------
    # Recherche par entropie croisée
    # ------------------------------------------------------------------
    def replanifier(self, koach, semaine):
        """Replanifie de la semaine [semaine] à l'échéance. Renvoie la ligne
        d'historique écrite."""
        pl = self.p
        blocs, qualites = self._dimensions(semaine)
        ligne = {'semaine': semaine, 'jour': koach.modele.jour, 'plans': 0}
        if not blocs or not self.suivis:
            self.historique.append(ligne)
            return ligne
        n = int(pl['trajectoires'])
        tirage = self.tirer(koach, semaine, n)
        nq = len(qualites)
        d = len(blocs) * (nq + 1)
        iters = int(pl['iterations'])
        pop = max(4, int(pl['plans_max']) // iters)
        rng = Mulberry32(fnv1a32('koach-cem:%d:%d' % (int(pl['graine']), semaine)))
        moy = np.zeros(d)
        # Départ : le plan en cours (continuité d'une semaine à l'autre).
        for j, b in enumerate(blocs):
            for w in range(semaine, self.horizon):
                t = self._table(w)
                if t is not None and t['bloc'] == b and w in self.plan:
                    for i, q in enumerate(qualites):
                        moy[j * (nq + 1) + i] = self.plan[w]['volume'][q] - 1.0
                    moy[j * (nq + 1) + nq] = self.plan[w]['intensite']
                    break
        ecart = np.empty(d)
        for j in range(len(blocs)):
            ecart[j * (nq + 1):j * (nq + 1) + nq] = pl['plafond_volume'] * 0.5
            ecart[j * (nq + 1) + nq] = pl['plafond_intensite'] * 0.5
        borne = np.empty(d)
        for j in range(len(blocs)):
            borne[j * (nq + 1):j * (nq + 1) + nq] = pl['plafond_volume']
            borne[j * (nq + 1) + nq] = pl['plafond_intensite']
        # Sans échéance, l'objectif est exprimé en part de la valeur du plan
        # de référence (comparable à la pénalité de transport).
        echelle = None
        if not (self.cibles and self.echeance_jour is not None):
            _, _, _, det0 = self.evaluer(np.zeros((1, d)), tirage, semaine, blocs, qualites, detail=True)
            echelle = float(det0['J'][0]) if float(det0['J'][0]) > 1e-9 else None
        meilleur_x = np.zeros(d)
        meilleure_v = None
        evalues = 0
        elite_n = max(2, int(arrondi(pop * pl['elite'])))
        lis = pl['lissage']
        candidats_finaux = []
        for it in range(iters):
            X = np.empty((pop, d))
            X[0, :] = 0.0                      # la référence est toujours candidate
            X[1, :] = moy
            for a in range(2, pop):
                for b in range(d):
                    X[a, b] = moy[b] + ecart[b] * rng.gauss()
            X = np.clip(X, -borne[None, :], borne[None, :])
            v, _, _ = self.evaluer(X, tirage, semaine, blocs, qualites, echelle=echelle)
            evalues += pop
            ordre = sorted(range(pop), key=lambda a: (-v[a], a))
            elite = X[ordre[:elite_n]]
            if meilleure_v is None or v[ordre[0]] > meilleure_v:
                meilleure_v = float(v[ordre[0]])
                meilleur_x = X[ordre[0]].copy()
            candidats_finaux = [X[a].copy() for a in ordre[:4]] + candidats_finaux[:4]
            moy = lis * elite.mean(axis=0) + (1 - lis) * moy
            ecart = lis * elite.std(axis=0) + (1 - lis) * ecart
            ecart = np.maximum(ecart, 1e-4)
        # Le plan retenu doit battre la référence de plus que le bruit de
        # recherche, et passer le validateur de sécurité.
        ref = np.zeros((1, d))
        v_ref, p_ref, _ = self.evaluer(ref, tirage, semaine, blocs, qualites, echelle=echelle)
        choisi = np.zeros(d)
        v_choisi = float(v_ref[0])
        essais = [meilleur_x] + candidats_finaux
        for x in essais:
            vx, _, _ = self.evaluer(x[None, :], tirage, semaine, blocs, qualites, echelle=echelle)
            if float(vx[0]) <= float(v_ref[0]) + pl['gain_min']:
                continue
            ok = False
            xx = x.copy()
            for _ in range(3):
                if self._sur(xx, semaine, blocs, qualites):
                    ok = True
                    break
                xx = 0.5 * xx                  # ramené vers la référence
            if ok:
                vxx, _, _ = self.evaluer(xx[None, :], tirage, semaine, blocs, qualites, echelle=echelle)
                if float(vxx[0]) > v_choisi + pl['gain_min']:
                    choisi = xx
                    v_choisi = float(vxx[0])
                    break
        vol, inten = self.decoder(choisi, blocs, qualites)
        for w in range(semaine, self.horizon):
            t = self._table(w)
            if t is None:
                continue
            a = vol[t['bloc']].copy()
            i = inten[t['bloc']]
            if t['verrou']:
                a = np.minimum(a, 1.0)
                i = min(i, 0.0)
            self.plan[w] = {'volume': [float(x) for x in a], 'intensite': float(i)}
        v, pc, dist, det = self.evaluer(choisi[None, :], tirage, semaine, blocs, qualites, detail=True, echelle=echelle)
        ligne.update({'plans': evalues + 2 + len(essais), 'valeur': float(v[0]), 'valeur_reference': float(v_ref[0]),
                      'objectif': float(det['J'][0]), 'transport': float(dist[0]),
                      'p_cibles': {ex: float(pc[0, e]) for e, ex in enumerate(self.suivis) if ex in self.cibles},
                      'p_cibles_reference': {ex: float(p_ref[0, e]) for e, ex in enumerate(self.suivis) if ex in self.cibles},
                      'volume': {str(b): [arrondi(float(x), 4) for x in vol[b]] for b in blocs},
                      'intensite': {str(b): arrondi(float(inten[b]), 4) for b in blocs},
                      'qualites': list(qualites)})
        self.historique.append(ligne)
        return ligne

    # ------------------------------------------------------------------
    # Application au plan écrit et sécurité
    # ------------------------------------------------------------------
    def modulation(self, semaine):
        return self.plan.get(semaine)

    def facteur_exercice(self, ex_id, mod):
        fiche = self.fiches.get(ex_id)
        if fiche is None or mod is None:
            return 1.0
        f = 0.0
        for q in range(NQ):
            f += fiche['vecteur'][q] * mod['volume'][q]
        return f

    def items_modules(self, semaine):
        """Items de la semaine [semaine] après modulation : dictionnaire
        (jour, slotId) -> (séries, écart d'intensité). L'arrondi des séries
        est une diffusion d'erreur par exercice dans l'ordre des jours
        (fonction pure de la modulation), puis le plafond de volume par
        qualité est vérifié sur les séries entières."""
        s = self.semaines[semaine] if 0 <= semaine < len(self.semaines) else None
        mod = self.plan.get(semaine)
        out = {}
        if s is None:
            return out
        reste = {}
        for (jour, items) in s['jours']:
            for item in items:
                n = item.get('sets') or 0
                if mod is None or item.get('kind') in ('warmup', 'test') or n <= 0:
                    out[(jour, item['slotId'])] = (n, 0.0)
                    continue
                ex = item['exerciseId']
                voulu = n * self.facteur_exercice(ex, mod) + reste.get(ex, 0.0)
                servi = int(math.floor(voulu + 0.5))
                if servi < 1:
                    servi = 1
                reste[ex] = voulu - servi
                out[(jour, item['slotId'])] = (servi, mod['intensite'])
        if mod is None:
            return out
        # Plafond dur par qualité sur les séries entières : on retire, dans
        # l'ordre inverse, les séries ajoutées qui font dépasser +15 %.
        pv = self.p['plafond_volume']
        ref = np.zeros(NQ)
        mod_m = np.zeros(NQ)
        ajouts = []
        retraits = []
        for (jour, items) in s['jours']:
            for item in items:
                fiche = self.fiches.get(item['exerciseId'])
                n = item.get('sets') or 0
                if fiche is None or item.get('kind') in ('warmup', 'test') or n <= 0:
                    continue
                v = np.asarray(fiche['vecteur'])
                servi = out[(jour, item['slotId'])][0]
                ref += n * v
                mod_m += servi * v
                if servi > n:
                    ajouts.append((jour, item['slotId'], v))
                if servi < n:
                    retraits.append((jour, item['slotId'], v))
        for (jour, slot, v) in reversed(ajouts):
            if not np.any(mod_m > ref * (1 + pv) + 1e-9):
                break
            n_s, ec = out[(jour, slot)]
            out[(jour, slot)] = (n_s - 1, ec)
            mod_m -= v
        for (jour, slot, v) in reversed(retraits):
            if not np.any((mod_m < ref * (1 - pv) - 1e-9) & (ref > 0)):
                break
            n_s, ec = out[(jour, slot)]
            out[(jour, slot)] = (n_s + 1, ec)
            mod_m += v
        return out

    def appliquer(self, semaine, jour, items):
        """Items du jour modulés (copie) : `sets` changé, `koachIntensite`
        posé (lu par la prescription de séance)."""
        mods = self.items_modules(semaine)
        out = []
        for item in items:
            cle = (jour, item['slotId'])
            if cle not in mods:
                out.append(item)
                continue
            n, ecart = mods[cle]
            if n == (item.get('sets') or 0) and not ecart:
                out.append(item)
                continue
            it = dict(item)
            it['sets'] = n
            if ecart:
                it['koachIntensite'] = ecart
            it['koachVolume'] = n - (item.get('sets') or 0)
            out.append(it)
        return out

    def blocs_modules(self, plan=None):
        """Copie des blocs de référence avec le plan appliqué (séries, part
        du 1RM et charge de départ) : ce que lit le validateur de sécurité."""
        garde = self.plan
        if plan is not None:
            self.plan = plan
        try:
            blocs = copy.deepcopy(self.blocs)
            for w, s in enumerate(self.semaines):
                if s is None or w not in self.plan:
                    continue
                mods = self.items_modules(w)
                for ecrite in blocs[s['bloc']]['pass2']['weeks']:
                    if ecrite['weekIndex'] != s['semaine_bloc']:
                        continue
                    for d in ecrite['days']:
                        for item in d['items']:
                            cle = (d['dayIndex'], item['slotId'])
                            if cle not in mods:
                                continue
                            n, ecart = mods[cle]
                            item['sets'] = n
                            if item.get('setTargets'):
                                item['setTargets'] = None
                            if ecart:
                                fiche = self.fiches.get(item['exerciseId']) or {}
                                bw = fiche.get('fraction', 0.0) * self.poids_corps
                                if item.get('percentOfOneRm') is not None:
                                    item['percentOfOneRm'] = arrondi(item['percentOfOneRm'] * (1 + ecart), 4)
                                inten = item.get('intensity')
                                if inten and inten.get('basis') == 'percent_one_rm' and inten.get('value') is not None:
                                    inten['value'] = arrondi(inten['value'] * (1 + ecart), 4)
                                if item.get('startLoadKg') is not None:
                                    item['startLoadKg'] = arrondi((item['startLoadKg'] + bw) * (1 + ecart) - bw, 3)
            return blocs
        finally:
            self.plan = garde

    def _cles_constats(self, constats):
        return sorted((c.get('code'), c.get('week'), c.get('dayIndex'), c.get('exerciseId')) for c in constats)

    def _sur(self, x, semaine, blocs, qualites):
        """Vrai si le plan [x] n'ajoute aucun constat de sécurité à ceux du
        plan de référence (validateur injecté ; sans validateur : vrai)."""
        if self.validateur is None:
            return True
        if self.constats_reference is None:
            self.constats_reference = self._cles_constats(self.validateur(self.blocs))
        vol, inten = self.decoder(x, blocs, qualites)
        plan = dict((w, p) for w, p in self.plan.items() if w < semaine)
        for w in range(semaine, self.horizon):
            t = self._table(w)
            if t is None:
                continue
            a = vol[t['bloc']].copy()
            i = inten[t['bloc']]
            if t['verrou']:
                a = np.minimum(a, 1.0)
                i = min(i, 0.0)
            plan[w] = {'volume': [float(v) for v in a], 'intensite': float(i)}
        trouves = self._cles_constats(self.validateur(self.blocs_modules(plan)))
        ref = list(self.constats_reference)
        for c in trouves:
            if c in ref:
                ref.remove(c)
            else:
                return False
        return True

    # ------------------------------------------------------------------
    # Crochets du moteur
    # ------------------------------------------------------------------
    def fin_semaine(self, koach, ligne, e):
        """Lundi : replanification de la semaine suivante à l'échéance."""
        self.replanifier(koach, int(e.get('semaine', 0)) + 1)

    def plan_semaine(self, koach, c):
        w = c.get('semaine')
        if c.get('replanifier'):
            self.replanifier(koach, w)
        return {'semaine': w, 'modulation': self.plan.get(w), 'items': self.items_modules(w)}

    def etat(self):
        return {'plan': {str(w): p for w, p in sorted(self.plan.items())}, 'historique': self.historique}
