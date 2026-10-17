# -*- coding: utf-8 -*-
"""Lot KR1 puis KM1c4 : les violations de sécurité du couple `kalis_plan`
0.4.x × Koach 1.0.4 sur les 90 600 saisons (critère 7 du cahier : 59
poussées de douleur et 4 aggravations, 25 saisons, toutes hors des graines
0 à 5 ; LIVRAISON_KR1.md § 4) sont rejouées sur les saisons qui les
portaient. Depuis Koach 1.0.5 (KM1c4, CHANGEMENTS_1_0_5.md) chaque test
vérifie que la violation a disparu ET le mécanisme qui la retire :

* poussées (tendon réactif du modèle de vérité : douze semaines après un
  épisode, une semaine qui expose la zone à plus de 1,5 fois sa tolérance
  déclenche une gêne de 2 à 3 sur 10) : l'exposition hebdomadaire de la
  zone sensible est bornée par la rampe du réalisé (`Seances.
  _budget_zone_semaine`), avec ou sans arrêt (`autres_08`), sans saut en fin
  de fenêtre (`ks_01`), au retour après des séances manquées (`street_03`) ;
* aggravations (`street_10`, poignet, dips lestés) : la douleur du tendon
  (4/10, fin de la semaine 10 du modèle de vérité) n'avait jamais été
  signalée à Koach avant la série aggravante (bilan sans douleur) ; le banc
  la tenait pour « connue » (`_pain_known` non remis à faux au début d'un
  épisode tendineux) : corrigé dans le modèle de vérité (Python ici, Dart au
  portage KM2c3) ; et dès qu'elle est signalée, Koach retire les dips
  (douleur ≥ `douleur_moyenne_contrainte` sur une sollicitation 0,5).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from banc import campagne as ca  # noqa: E402
from banc import criteres_moteur as cm  # noqa: E402
from banc import donnees, meneur, verite  # noqa: E402
from banc.verite import make_book  # noqa: E402
from banc import politique_koach as pk  # noqa: E402


class _Espion(object):
    """Relève les semaines de tendon réactif (exposition, tolérance,
    poussée), les surcharges, les aggravations et, côté Koach, le budget
    hebdomadaire de chaque zone sensible et l'exposition servie."""

    def __init__(self):
        self.semaines = []        # (semaine, zone, exposition, tolérance, poussée)
        self.surcharges = []
        self.aggravations = []
        self.budgets = {}         # (zone, semaine) -> permis de la semaine
        self.signales = []        # (jour, zone, intensité) vus par Koach au moment d'une aggravation
        self.koach = None

    def installer(self):
        A = verite.SimAthlete
        self._rw, self._ov, self._pf = A._reactive_week, A.overuse, A.perform
        self._pl = pk.PolitiqueKoach.planifier
        espion = self

        def rw(athlete):
            z = athlete._reactive_zone
            semaine = athlete._zone_week.get(z, 0.0) if z is not None else None
            tol = athlete._reactive_tolerance
            avant = athlete.pain_flares
            espion._rw(athlete)
            if z is not None:
                # `end_week` a déjà incrémenté `_weeks` : l'exposition relevée
                # est celle de la semaine `_weeks − 1` (relecture KM1c4, M5).
                espion.semaines.append((athlete._weeks - 1, z, semaine, tol, athlete.pain_flares > avant))

        def ov(athlete, zone, intensite, jours):
            espion.surcharges.append((athlete._day, zone, intensite))
            espion._ov(athlete, zone, intensite, jours)

        def pf(athlete, t, load, *args):
            avant = athlete.pain_aggravations
            precedente = t.last_load
            r = espion._pf(athlete, t, load, *args)
            if athlete.pain_aggravations > avant:
                g = espion.koach.garde if espion.koach is not None else None
                d = g.zones.get(athlete.pain_zone) if g is not None else None
                espion.aggravations.append((athlete._day, t.info.id, load, precedente, athlete.pain_zone,
                                            athlete.pain_intensity, t.info.zone_level(athlete.pain_zone),
                                            d.derniere() if d is not None else None))
            return r

        def pl(self, ctx):
            out = espion._pl(self, ctx)
            espion.koach = self.koach
            for z, b in self.koach.seances.budget_semaine.items():
                espion.budgets[(z, ctx.semaine)] = b
            return out

        A._reactive_week, A.overuse, A.perform = rw, ov, pf
        pk.PolitiqueKoach.planifier = pl

    def retirer(self):
        A = verite.SimAthlete
        A._reactive_week, A.overuse, A.perform = self._rw, self._ov, self._pf
        pk.PolitiqueKoach.planifier = self._pl


def _rejouer(cle, scenario, verite_kind, graine, espion=None, garder_journal=False):
    opts = ca.options_de([])
    ca.appliquer_parametres(opts)
    saison = cm._saison(cle, scenario, None)
    pol = ca.politique(opts, graine)
    if espion is not None:
        espion.installer()
    try:
        return meneur.simuler(saison, donnees.catalogue_infos(), pol, verite_kind, graine,
                              garder_journal=garder_journal)
    finally:
        if espion is not None:
            espion.retirer()


def _expositions_bornees(e, zone):
    """Chaque semaine réactive de [zone] : exposition ≤ 1,5 × max(4 ;
    tolérance) (aucune poussée) et, quand Koach avait un budget pour la
    semaine, exposition ≤ budget."""
    for (w, z, expo, tol, poussee) in e.semaines:
        if z != zone:
            continue
        assert not poussee, (w, expo, tol)
        assert expo <= 1.5 * max(4.0, tol) + 1e-9, (w, expo, tol)
        b = e.budgets.get((z, w))
        if b is not None:
            assert expo <= b + 1e-9, (w, expo, b)


def test_poussees_apres_surcharge_sans_arret():
    """`autres_08` (CrossFit), référence, vérité b, graine 47 (KR1 : 7
    poussées, 38 sur sept scénarios) : surcharge à l'épaule au 4e jour,
    douleur en semaine 0 (aucune habitude mesurée) ; 1.0.5 : budget sans
    habitude (4 séries), puis +1 ou +20 % par semaine ; 0 poussée."""
    e = _Espion()
    tour = _rejouer('autres_08_crossfit_intermediaire', 'reference', 'b', 47, e)
    assert e.surcharges and e.surcharges[0][1] == 'shoulder'
    assert tour.pain_flares == 0 and tour.pain_aggravations == 0
    _expositions_bornees(e, 'shoulder')
    assert any(z == 'shoulder' for (z, w) in e.budgets)


def test_pas_de_saut_a_la_fin_de_la_reprise_graduee():
    """`ks_01`, douleur à l'épaule, vérité b, graine 38 (KR1 : 2 poussées à
    la fin de la fenêtre de reprise, 7 séries après une semaine à 0) ;
    1.0.5 : référence = dernière semaine de charge exposée, pas l'habitude ;
    0 poussée."""
    e = _Espion()
    tour = _rejouer('ks_01_streetlifting_sets_reps_4_seances', 'douleur_epaule', 'b', 38, e)
    assert tour.pain_flares == 0 and tour.pain_aggravations == 0
    _expositions_bornees(e, 'shoulder')


def test_retour_apres_des_seances_manquees():
    """`street_03`, séances manquées, vérité b, graine 19 (KR1 : 8 séries au
    poignet pour une tolérance de 4,8 après deux semaines sans exposition) ;
    1.0.5 : départ à la moitié de l'habitude (charge chronique sur quatre
    semaines) ; 0 poussée."""
    e = _Espion()
    tour = _rejouer('street_03_debutante', 'seances_manquees', 'b', 19, e)
    assert tour.pain_flares == 0 and tour.pain_aggravations == 0
    _expositions_bornees(e, 'wrist_hand')


def test_aggravation_sur_une_douleur_jamais_signalee():
    """`street_10`, séances manquées, vérité b, graine 34 (KR1 : 1
    aggravation, dips lestés 10 → 11,25 kg) : la douleur du poignet (tendon,
    4/10) n'avait pas été signalée (dernier signalement vu par Koach : 0) ;
    avec la remise à faux de `_pain_known` au début de l'épisode, aucune
    aggravation ; une fois signalée (4/10 : sans l'aggravation, elle ne monte
    plus à 5), aucune hausse de charge sur les dips lestés."""
    e = _Espion()
    tour = _rejouer('street_10_elite_figures', 'seances_manquees', 'b', 34, e, garder_journal=True)
    assert tour.pain_aggravations == 0 and tour.pain_flares == 0, e.aggravations
    g = e.koach.garde.zones['wrist_hand']
    # La douleur du tendon (4/10, sans l'aggravation qui la portait à 5) est
    # signalée après la semaine 10 (fin de la séance du jour 78, où les dips
    # lestés sont montés sans qu'elle soit connue) ; ensuite, règle 4 et
    # A1.1 : aucune charge de dips lestés servie après ce signalement ne
    # dépasse la dernière d'avant tant que la gêne dure.
    forts = [j for (j, i) in g.signalements if i >= 4 and j >= 70]
    assert forts
    j0 = forts[0]
    dips = [(r['simDay'], st.get('externalLoadKg')) for r in tour.journal for st in r['sets']
            if st['exerciseId'] == 'sl-dips-leste' and st.get('kind') != 'warmup']
    assert dips and [d for d in dips if d[0] > j0]
    avant = max(c for (j, c) in dips if j <= j0 and c is not None)
    assert all(c <= avant + 1e-9 for (j, c) in dips if j > j0 and c is not None)


def test_douleur_tendineuse_inconnue_tant_que_non_signalee():
    """Modèle de vérité : un épisode tendineux qui commence (`end_week`) et
    un épisode de la fiche (`advance`) ne sont connus du moteur qu'une fois
    signalés (comme `overuse` et les poussées) : `_pain_known` est remis à
    faux."""
    profil = {'level': 'intermediate', 'bodyWeightKg': 75.0, 'sex': 'male', 'equipment': []}
    livre = make_book(donnees.catalogue_infos(), profil)
    # Fiche : épisode de douleur imposé au jour 10 pendant 7 jours.
    base = {'key': 'test', 'level': 1, 'weeklyGain': 0.01}
    spec = verite.Spec(dict(base, painZone='elbow', painFromDay=10, painDays=7, painIntensity=5))
    a = verite.SimAthlete(spec, profil, livre, 1, kind='b')
    a._pain_known = True
    a.advance(10)
    assert a.in_pain and not a._pain_known
    # Tendons (modèle b) : tolérance de tenue dépassée en fin de semaine.
    b = verite.SimAthlete(verite.Spec(base), profil, livre, 2, kind='b')
    b._pain_known = True
    b._tendon = 10.0
    b._hold_week = 10.0 * 1.3 + 11
    b.end_week()
    assert b.in_pain and b.pain_zone == 'wrist_hand' and not b._pain_known
