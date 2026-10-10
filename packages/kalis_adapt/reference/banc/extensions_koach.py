# -*- coding: utf-8 -*-
"""Branchement des briques 6 et 7 de Koach 1.0 sur le banc Python :
hors modèle (`koach.rupture.Surveillance`), adhérence et refus
(`koach.adherence.Adherence`), contrôle dual (`koach.dual.ControleDual`).

Chaque fabrique `f(politique) -> Extension` se passe à
`PolitiqueKoach(extensions=[...])`. Les extensions du banc sont des
sous-classes des extensions du moteur ; elles ajoutent seulement ce que le
banc doit jouer à la place de l'utilisateur (réponses au diagnostic,
acceptations et refus, propositions d'essai) et l'application des actions
aux items servis. Tout ce qu'elles décident passe par le JOURNAL du moteur
(événements `decision`) : l'état des extensions du moteur se recalcule en
rejouant le journal avec les classes de `koach` seules (`rejouer_etats`).

Crochets côté banc utilisés : `items_du_jour` (items écrits du jour, avant
la prescription), `apres_semaine` (après `semaine_fin`). Crochet ajouté par
contournement (absent de `PolitiqueKoach`) : `cible_serie`, appelé par
`PolitiqueBriques.prochaine_serie` (voir le rapport : changement minimal
demandé dans `banc/politique_koach.py`).

Aléa : uniquement `koach.numerique.Mulberry32`, graines dérivées par
`fnv1a32` de la clé de saison, du scénario, du modèle de vérité et de la
graine du banc.
"""
import math

from koach.adherence import Adherence, MOMENTS, DIM
from koach.dual import ControleDual, calibre, facteur_borne, Z90
from koach.moteur import rejouer
from koach.numerique import Mulberry32, fnv1a32, norm_cdf
from koach.rupture import Surveillance

from .politique_koach import PolitiqueKoach, vecteurs, profil_koach


# ----------------------------------------------------------------------
# Lecture de la saison
# ----------------------------------------------------------------------
def lifts_principaux(saison):
    """Mouvements principaux chargés de la saison : exercices des créneaux
    de rôle `main` dont la fiche est de type `charge` (triés)."""
    fiches = vecteurs()
    ids = set()
    for b in saison['blocks']:
        for d in b['pass1']['days']:
            for s in d['slots']:
                ex = s.get('exerciseId')
                if s.get('role') == 'main' and isinstance(ex, str):
                    f = fiches.get(ex)
                    if f is not None and f.get('type') == 'charge':
                        ids.add(ex)
    return sorted(ids)


def jours_echeance(saison):
    out = set()
    for jours in saison.get('eventDaysByWeek') or []:
        for j in jours:
            out.add(int(j))
    return sorted(out)


class VeriteScenario(object):
    """Ce que l'utilisateur simulé sait de sa situation (vérité du
    scénario, `specJson` de la saison, et état de douleur de l'athlète
    simulé). Sert à répondre au diagnostic et aux mesures du banc."""

    APRES_MALADIE_J = 14   # la fatigue d'une maladie se fait encore sentir 2 semaines

    def __init__(self, saison):
        sp = saison.get('specJson') or {}
        self.scenario = saison['scenario']
        self.maladie = None
        if sp.get('illnessFromDay') is not None:
            self.maladie = (int(sp['illnessFromDay']), int(sp['illnessFromDay']) + int(sp.get('illnessDays', 0)))
        self.douleur = None
        if sp.get('painFromDay') is not None:
            self.douleur = (int(sp['painFromDay']), int(sp['painFromDay']) + int(sp.get('painDays', 0)),
                            sp.get('painZone'), sp.get('painIntensity'))
        self.lieu = None
        if sp.get('otherPlaceFromDay') is not None:
            self.lieu = (int(sp['otherPlaceFromDay']),
                         int(sp['otherPlaceFromDay']) + int(sp.get('otherPlaceDays', 0)))
        self.coupure = None
        if sp.get('breakFromDay') is not None:
            self.coupure = (int(sp['breakFromDay']), int(sp['breakFromDay']) + int(sp.get('breakDays', 0)))
        self.manques = float(sp.get('missRate', 0.08))

    def debut_rupture(self):
        """Jour de début de la rupture connue du scénario, ou None."""
        for f in (self.maladie, self.douleur, self.coupure, self.lieu):
            if f is not None:
                return f[0]
        return None

    def reponse(self, ctx):
        """Réponse au diagnostic (dictionnaire pour `Surveillance.repondre`)."""
        j = ctx.sim_day
        a = ctx.athlete
        if a is not None and a.in_pain and a.pain_zone is not None:
            return {'cause': 'douleur', 'zone': a.pain_zone, 'intensite': int(a.pain_intensity)}
        if self.maladie is not None and self.maladie[0] <= j < self.maladie[1] + self.APRES_MALADIE_J:
            return {'cause': 'fatigue'}
        temps = ctx.bilan is not None and ctx.bilan.get('minutesAvailable') is not None
        if (self.lieu is not None and self.lieu[0] <= j < self.lieu[1]) or temps:
            duree = ctx.budget
            if ctx.bilan is not None and ctx.bilan.get('minutesAvailable') is not None:
                duree = ctx.bilan['minutesAvailable']
            choix = 20
            for d in (20, 30, 45, 60, 75, 90):
                if duree is not None and d <= duree:
                    choix = d
            return {'cause': 'moins_de_temps', 'seances_par_semaine': self.seances_par_semaine(ctx),
                    'duree_max_min': choix}
        return {'cause': 'rien'}

    @staticmethod
    def seances_par_semaine(ctx):
        n = 0
        for (g, bi, wb, di, jour) in ctx.saison['sessions']:
            if g == ctx.semaine:
                n += 1
        return n if 1 <= n <= 7 else (1 if n < 1 else 7)


# ----------------------------------------------------------------------
# Hors modèle
# ----------------------------------------------------------------------
class SurveillanceBanc(Surveillance):
    """`Surveillance` conduite par le banc : à la séance qui suit une
    alerte, l'utilisateur simulé répond au diagnostic selon la vérité du
    scénario (réponse journalisée, action codée appliquée par le moteur) ;
    la semaine allégée est appliquée aux items écrits du jour."""

    def __init__(self, params, politique):
        Surveillance.__init__(self, params)
        self.politique = politique
        self.verite = VeriteScenario(politique.saison)
        self.journal = []

    def verifier(self, koach):
        avant = list(self.alertes)
        Surveillance.verifier(self, koach)
        if not any(avant) and any(self.alertes):
            self.journal.append({'type': 'alerte', 'jour': int(koach.jour), 'semaine': self.semaine,
                                 'causes': self.causes(), 'p': round(float(self.p), 6)})

    def items_du_jour(self, koach, ctx, items):
        if self.etat()['hors_modele']:
            causes = self.causes()
            rep = self.verite.reponse(ctx)
            qs = self.questions(rep)
            koach.observe({'type': 'decision', 'jour': ctx.sim_day, 'diagnostic': rep})
            self.journal.append({'type': 'diagnostic', 'jour': ctx.sim_day, 'causes': causes,
                                 'reponse': dict(sorted(rep.items())), 'questions': len(qs),
                                 'action': self.reponses[-1]['action']})
        servis = self.appliquer_allegement(items, ctx.sim_day)
        if servis is not items:
            self.journal.append({'type': 'allegement', 'jour': ctx.sim_day,
                                 'series_ecrites': sum(int(it.get('sets') or 0) for it in items
                                                       if it.get('kind', 'work') == 'work'),
                                 'series_allegees': sum(int(it.get('sets') or 0) for it in servis
                                                        if it.get('kind', 'work') == 'work')})
        return servis


# ----------------------------------------------------------------------
# Adhérence : utilisateur simulé
# ----------------------------------------------------------------------
# Poids vrais de l'utilisateur simulé (probit) : moyenne et écart-type de
# chaque poids, tirés une fois par saison et par graine. Choix du banc
# (aucune donnée réelle) : propositions acceptées ~ 3 fois sur 4 au départ,
# moins quand le pas est grand, le bilan bas ou les refus récents nombreux.
POIDS_MOYENS = [0.9] + [0.0] * 9 + [-0.6, -0.4, 0.2, -0.3, 0.1, -0.5]
POIDS_SD = [0.3] + [0.4] * 9 + [0.2, 0.3, 0.3, 0.3, 0.3, 0.3]


class UtilisateurSimule(object):
    """Probit à poids vrais w ~ N(POIDS_MOYENS, POIDS_SD²) tirés d'une
    graine : P(accepter | x) = Φ(w·x). Les tirages de décision viennent d'un
    second générateur, de graine dérivée."""

    def __init__(self, graine_texte):
        r = Mulberry32(fnv1a32('koach-adherence-poids:' + graine_texte))
        self.w = [POIDS_MOYENS[i] + POIDS_SD[i] * r.gauss() for i in range(DIM)]
        self.rng = Mulberry32(fnv1a32('koach-adherence-decisions:' + graine_texte))

    def proba(self, x):
        s = 0.0
        for i in range(DIM):
            s += self.w[i] * x[i]
        return norm_cdf(s)

    def decider(self, x):
        p = self.proba(x)
        return self.rng.next() < p, p


def _graine_texte(politique, graine):
    s = politique.saison
    return '%s:%s:%s' % (s['key'], s['scenario'], graine)


class AdherenceBanc(Adherence):
    """Chaque fin de semaine, les hausses et baisses de charge de la
    première série des mouvements principaux chargés (et les tests) de la
    semaine deviennent des propositions : `forme` choisit la forme (premier
    palier, moment) vers la charge servie, l'utilisateur simulé accepte ou
    refuse, la décision est versée au journal du moteur. La séance servie
    n'est pas modifiée par la décision (l'utilisateur simulé fait la séance
    servie) : sur le banc, l'adhérence n'apprend que de ses décisions.

    [raisons] : si vrai, un refus d'une hausse (baisse) porte une fois sur
    deux la raison « trop lourd » (« trop léger ») : second canal (mesure
    faible de capacité). Par défaut, aucune raison : le refus ne nourrit que
    l'adhérence (cahier § 8), ce que vérifie le test anti-complaisance."""

    def __init__(self, params, politique, graine, raisons=False):
        Adherence.__init__(self, params)
        self.politique = politique
        self.utilisateur = UtilisateurSimule(_graine_texte(politique, graine))
        self.raisons = raisons
        self.journal = []
        self._vu = 0
        self._dernier = {}

    def apres_semaine(self, koach, semaine, tour, politique):
        jour = 7 * (semaine + 1)
        lignes = tour.sets
        while self._vu < len(lignes):
            row = lignes[self._vu]
            self._vu += 1
            if row['setIndex'] != 0 or not row['main'] or row['mode'] != 'loaded' or row['loadKg'] is None:
                continue
            ex = row['exerciseId']
            if row['test']:
                self._proposer(koach, jour, ex, 'test', row, None, None)
                continue
            avant = self._dernier.get(ex)
            self._dernier[ex] = row['loadKg']
            if avant is None or abs(row['loadKg'] - avant) < 1e-9:
                continue
            self._proposer(koach, jour, ex, 'charge_plus' if row['loadKg'] > avant else 'charge_moins',
                           row, avant, row['loadKg'])

    def _proposer(self, koach, jour, ex, typ, row, depart, cible):
        grille = self.politique.grilles.get(ex)
        pas = grille.pas if (grille is not None and grille.pas > 0) else 2.5
        ctx = {'bilan_bas': False, 'semaine_allegement': row.get('weekKind') == 'deload',
               'refus_recents': self.refus_recents(jour)}
        if typ == 'test':
            forme = {'paliers': [row['loadKg']], 'moment': 'debut_de_seance', 'proba_min': None}
            ampleur = 0.0
        else:
            forme = self.forme(cible, depart, pas, typ, ctx)
            ampleur = abs(forme['paliers'][0] - depart) / pas
        c = dict(ctx)
        c['moment'] = forme['moment']
        x = self.caracteristiques(typ, ampleur, c)
        p_predite = self.proba(x)
        accepte, p_vraie = self.utilisateur.decider(x)
        raison = None
        if not accepte and self.raisons and typ in ('charge_plus', 'charge_moins'):
            if self.utilisateur.rng.next() < 0.5:
                raison = 'too_heavy' if typ == 'charge_plus' else 'too_light'
        prop = {'id': 'p%d-%s-%d' % (jour, ex, len(self.journal)), 'type': typ, 'exerciseId': ex,
                'ampleur': ampleur, 'charge_kg': row['loadKg'], 'reps': row['amount'],
                'rir': row['wantRir'], 'contexte': c}
        koach.observe({'type': 'decision', 'jour': jour, 'proposition': prop, 'accepte': accepte,
                       'raison': raison})
        self.journal.append({'jour': jour, 'exerciseId': ex, 'type': typ, 'ampleur': round(ampleur, 6),
                             'depart': depart, 'cible': cible, 'paliers': list(forme['paliers']),
                             'moment': forme['moment'], 'p_predite': round(p_predite, 9),
                             'p_vraie': round(p_vraie, 9), 'accepte': accepte, 'raison': raison})


# ----------------------------------------------------------------------
# Contrôle dual
# ----------------------------------------------------------------------
class ControleDualBanc(ControleDual):
    """Chaque fin de semaine : journal du calibrage ; si le modèle est
    calibré (cahier § 7) et aucun essai en cours, proposition d'un essai
    N-of-1 sur le mouvement principal le mieux connu (témoins synthétiques :
    les autres exercices suivis), journalisée. Pendant un bras, la
    modulation est appliquée aux items servis : A = +volume (séries
    entières arrondies au plus proche, sans jamais dépasser +plafond_volume
    sur la semaine en cours : avec moins de 7 séries écrites dans la semaine,
    une série de plus dépasserait le plafond et le bras A ne change rien),
    B = +intensité (charge de travail, arrondie vers le bas sur la grille :
    jamais plus que +amplitude_intensite)."""

    TEMOINS_MAX = 6

    def __init__(self, params, politique, graine, options=None):
        self.politique = politique
        ControleDual.__init__(self, params, lifts_principaux(politique.saison))
        self.graine = int(graine)
        self.options = dict(options or {})
        self.echeances = jours_echeance(politique.saison)
        self.journal = []
        self.genre = None
        self.semaine_vol = None   # [semaine, séries écrites, séries servies] de l'exercice traité

    def _contexte(self, koach, semaine):
        jour = 7 * semaine
        ech = None
        if not self.options.get('ignorer_echeance'):
            for j in self.echeances:
                if j >= jour:
                    ech = int(math.ceil((j - jour) / 7.0))
                    break
        alerte = False
        for x in koach.extensions:
            if isinstance(x, Surveillance) and x.etat()['hors_modele']:
                alerte = True
        douleur = False
        actives = getattr(koach.garde, 'actives', None)
        if actives is not None:
            douleur = len(actives()) > 0
        return {'semaines_avant_echeance': ech, 'affutage': self.genre == 'taper',
                'alerte': alerte, 'douleur': douleur}

    def apres_semaine(self, koach, semaine, tour, politique):
        ok, raisons = calibre(koach, self.lifts)
        demi = {}
        for ex in self.lifts:
            c = koach.modele.capacite(ex)
            if c is not None:
                demi[ex] = round(Z90 * float(c[1]), 6)
        self.journal.append({'type': 'semaine', 'semaine': semaine,
                             'journal': len(koach.modele.journal_semaines), 'calibre': ok,
                             'demi_largeur': demi, 'entropie': round(self.reponse.entropie(), 9),
                             'poids_max': round(max(self.reponse.poids), 9)})
        if self.essai is not None or not ok or not self.lifts:
            return
        prochaine = semaine + 1
        cible = min(self.lifts, key=lambda ex: (demi.get(ex, 1.0), ex))
        recents = self.pre[-8:] if len(self.pre) >= 8 else self.pre
        temoins = []
        for ex in sorted(recents[-1]['mu'].keys()) if recents else []:
            if ex == cible:
                continue
            if all(ex in x['mu'] for x in recents):
                temoins.append(ex)
        temoins = temoins[:self.TEMOINS_MAX]
        d = {'semaine': prochaine, 'cible': {'exerciseId': cible}, 'traites': [cible],
             'temoins': temoins, 'contexte': self._contexte(koach, prochaine), 'graine': self.graine,
             'n_bras': self.options.get('n_bras')}
        koach.observe({'type': 'decision', 'jour': 7 * prochaine, 'essai': d})
        self.journal.append({'type': 'proposition', 'semaine': prochaine, 'cible': cible,
                             'demarre': self.essai is not None, 'raison': self.raisons[-1] if self.raisons else None})

    def items_du_jour(self, koach, ctx, items):
        """Bras A (volume) : séries ajoutées à l'exercice traité, le produit
        (facteur de la planification × facteur du bras) borné par le plafond
        de volume du cahier par rapport à la RÉFÉRENCE (`dual.facteur_borne`),
        cumulé sur la semaine en cours."""
        self.genre = ctx.genre_semaine
        mod = self.modulation(ctx.semaine)
        if 'bras' not in mod or mod['volume'] <= 1.0:
            return items
        ex = mod.get('exerciseId')
        if self.semaine_vol is None or self.semaine_vol[0] != ctx.semaine:
            # [semaine, séries de référence, séries planifiées, séries servies]
            self.semaine_vol = [ctx.semaine, 0, 0, 0]
        plafond = float((self.params.get('planification') or {}).get('plafond_volume', 0.15))
        reference = {}
        for it in (ctx.ecrit or {}).get('items') or []:
            if it.get('exerciseId') == ex and it.get('kind', 'work') == 'work':
                reference[it['slotId']] = int(it.get('sets') or 0)
        out = []
        for it in items:
            if it.get('exerciseId') != ex or it.get('kind', 'work') != 'work' or (it.get('sets') or 0) < 1:
                out.append(it)
                continue
            n = int(it['sets'])
            ref = self.semaine_vol[1] + reference.get(it['slotId'], n)
            planifiees = self.semaine_vol[2] + n
            servies = self.semaine_vol[3] + n
            if ref > 0:
                borne = facteur_borne(planifiees / float(ref), mod['volume'], plafond) * ref
            else:
                borne = servies
            plus = int(math.floor(borne - servies + 0.5))
            while plus > 0 and servies + plus > (1.0 + plafond) * ref + 1e-9:
                plus -= 1
            plus = plus if plus > 0 else 0
            it = dict(it)
            it['sets'] = n + plus
            self.semaine_vol[1] = ref
            self.semaine_vol[2] = planifiees
            self.semaine_vol[3] = servies + plus
            self.journal.append({'type': 'volume', 'jour': ctx.sim_day, 'semaine': ctx.semaine,
                                 'exerciseId': ex, 'ecrites': n, 'servies': n + plus,
                                 'ratio_semaine': round(self.semaine_vol[3] / float(ref), 6) if ref else 1.0})
            out.append(it)
        return out

    def cible_serie(self, koach, ctx, item, index, cible):
        """Bras B (intensité) : charge de travail montée de l'amplitude du
        bras, jamais un jour où Koach interdit la hausse et jamais au-dessus
        des bornes de hausse de la séance (`Seances.borne_externe`)."""
        if cible is None or cible.get('loadKg') is None:
            return cible
        mod = self.modulation(ctx.semaine)
        if mod.get('bras') != 'B' or item.get('exerciseId') != mod.get('exerciseId'):
            return cible
        if cible.get('role') in ('test', 'attempt') or item.get('kind') == 'test' or cible.get('repere'):
            return cible
        m = koach.modele
        t = m.pistes.get(item['exerciseId'])
        grille = self.politique.grilles.get(item['exerciseId'])
        if t is None or grille is None:
            return cible
        kg = float(cible['loadKg'])
        total = m.masse(t, kg)
        if total <= 0:
            return cible
        voulu = total * mod['intensite'] - (total - kg)
        nouveau = grille.plancher(voulu)
        if nouveau <= kg + 1e-9:
            return cible
        borne = koach.seances.borne_externe(item, index, nouveau)
        if borne is None or borne <= kg + 1e-9:
            return cible
        if nouveau > borne:
            nouveau = borne
        c = dict(cible)
        c['loadKg'] = nouveau
        self.journal.append({'type': 'intensite', 'jour': ctx.sim_day, 'semaine': ctx.semaine,
                             'exerciseId': item['exerciseId'], 'index': index,
                             'ratio': round(m.masse(t, nouveau) / total, 6)})
        return c


# ----------------------------------------------------------------------
# Politique et fabriques
# ----------------------------------------------------------------------
class PolitiqueBriques(PolitiqueKoach):
    """`PolitiqueKoach` + crochet `cible_serie(koach, ctx, item, index,
    cible)` des extensions (contournement : ce crochet manque dans
    `PolitiqueKoach.prochaine_serie`)."""

    def prochaine_serie(self, ctx, item, index, done):
        cible = PolitiqueKoach.prochaine_serie(self, ctx, item, index, done)
        for x in self.koach.extensions:
            f = getattr(x, 'cible_serie', None)
            if f is not None:
                cible = f(self.koach, ctx, item, index, cible)
        return cible


def fabrique_surveillance():
    return lambda pol: SurveillanceBanc(pol.parametres, pol)


def fabrique_adherence(graine, raisons=False):
    return lambda pol: AdherenceBanc(pol.parametres, pol, graine, raisons)


def fabrique_controle_dual(graine, options=None):
    return lambda pol: ControleDualBanc(pol.parametres, pol, graine, options)


def politique(graine, briques=('surveillance', 'dual', 'adherence'), parametres=None,
              options_dual=None, raisons=False):
    """Politique Koach avec les briques demandées, dans cet ordre fixe."""
    fab = []
    if 'surveillance' in briques:
        fab.append(fabrique_surveillance())
    if 'dual' in briques:
        fab.append(fabrique_controle_dual(graine, options_dual))
    if 'adherence' in briques:
        fab.append(fabrique_adherence(graine, raisons))
    return PolitiqueBriques(parametres=parametres, extensions=fab)


def journaux(pol):
    """Journaux des extensions du banc (dictionnaire, ordre fixe)."""
    out = {}
    for x in pol.koach.extensions:
        out[type(x).__name__] = getattr(x, 'journal', None)
    return out


def etats(pol):
    """États exportés des extensions du moteur (classes de `koach`)."""
    out = {}
    for x in pol.koach.extensions:
        if isinstance(x, Surveillance):
            out['Surveillance'] = x.etat_complet()
        elif isinstance(x, ControleDual):
            out['ControleDual'] = x.etat()
        elif isinstance(x, Adherence):
            out['Adherence'] = x.etat()
    return out


def rejouer_etats(pol, saison):
    """Rejoue le journal du moteur avec les seules classes de `koach`
    (aucun code du banc) et renvoie leurs états exportés."""
    fab = []
    params = pol.parametres
    for x in pol.koach.extensions:
        if isinstance(x, Surveillance):
            fab.append(lambda: Surveillance(params))
        elif isinstance(x, ControleDual):
            lifts = list(x.lifts)
            fab.append(lambda lifts=lifts: ControleDual(params, lifts))
        elif isinstance(x, Adherence):
            fab.append(lambda: Adherence(params))
    k = rejouer(params, vecteurs(), pol.koach.profil, pol.koach.journal, fab)
    out = {}
    for x in k.extensions:
        if isinstance(x, Surveillance):
            out['Surveillance'] = x.etat_complet()
        elif isinstance(x, ControleDual):
            out['ControleDual'] = x.etat()
        elif isinstance(x, Adherence):
            out['Adherence'] = x.etat()
    return out
