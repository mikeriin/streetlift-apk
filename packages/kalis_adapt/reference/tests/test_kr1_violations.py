# -*- coding: utf-8 -*-
"""Lot KR1 : violations de sécurité restantes du couple `kalis_plan` 0.4.1 ×
Koach 1.0.4 sur les 90 600 saisons (34 profils, 100 graines, trois modèles de
vérité, tous les scénarios ; critère 7 du cahier : 4 aggravations et 59
poussées de douleur, toutes hors des graines 0 à 5). Chaque test rejoue une
saison qui les porte et vérifie le MÉCANISME établi (LIVRAISON_KR1.md § 4) ;
il attend la violation tant que Koach ne la corrige pas : le jour où une
correction de méthode la retire, le test échoue et doit être mis à jour.

Mécanismes :
* poussée (tendon réactif) : après un épisode douloureux, la zone reste
  réactive douze semaines dans le modèle de vérité (tolérance ≈ exposition de
  la dernière semaine ou moitié de l'habitude) ; une semaine qui y expose plus
  de 1,5 fois la tolérance déclenche une gêne de 2 à 3 sur 10, sous le seuil
  de douleur active de Koach (`securite.douleur_seuil` = 3), qui ne réagit
  donc pas ; l'exposition servie remonte d'un coup (fin de la reprise graduée
  à 84 jours, séances manquées, ou aucune reprise faute d'arrêt) ;
* aggravation : douleur connue de 5 au poignet (tenues), Koach monte la charge
  des dips lestés (sollicitation du poignet 0,5) : sa conduite ne bloque les
  hausses sur une zone douloureuse qu'à partir de
  `securite.douleur_moyenne_contrainte` (5) pour une sollicitation moyenne,
  quand le banc compte toute hausse au-dessus de 3.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from banc import campagne as ca  # noqa: E402
from banc import criteres_moteur as cm  # noqa: E402
from banc import donnees, meneur, verite  # noqa: E402


def _rejouer(cle, scenario, verite_kind, graine, espion=None):
    opts = ca.options_de([])
    ca.appliquer_parametres(opts)
    saison = cm._saison(cle, scenario, None)
    pol = ca.politique(opts, graine)
    if espion is not None:
        espion.installer()
    try:
        return meneur.simuler(saison, donnees.catalogue_infos(), pol, verite_kind, graine)
    finally:
        if espion is not None:
            espion.retirer()


class _Espion(object):
    """Relève les semaines de tendon réactif et les surcharges du modèle de vérité."""

    def __init__(self):
        self.semaines = []
        self.surcharges = []
        self.aggravations = []

    def installer(self):
        A = verite.SimAthlete
        self._rw, self._ov, self._pf = A._reactive_week, A.overuse, A.perform
        espion = self

        def rw(athlete):
            z = athlete._reactive_zone
            semaine = athlete._zone_week.get(z, 0.0) if z is not None else None
            tol = athlete._reactive_tolerance
            avant = athlete.pain_flares
            espion._rw(athlete)
            if z is not None:
                espion.semaines.append((athlete._weeks, z, semaine, tol, athlete.pain_flares > avant))

        def ov(athlete, zone, intensite, jours):
            espion.surcharges.append((athlete._day, zone, intensite))
            espion._ov(athlete, zone, intensite, jours)

        def pf(athlete, t, load, *args):
            avant = athlete.pain_aggravations
            precedente = t.last_load
            r = espion._pf(athlete, t, load, *args)
            if athlete.pain_aggravations > avant:
                espion.aggravations.append((athlete._day, t.info.id, load, precedente, athlete.pain_zone,
                                            athlete.pain_intensity, t.info.zone_level(athlete.pain_zone)))
            return r

        A._reactive_week, A.overuse, A.perform = rw, ov, pf

    def retirer(self):
        A = verite.SimAthlete
        A._reactive_week, A.overuse, A.perform = self._rw, self._ov, self._pf


def test_poussees_apres_surcharge_sans_arret():
    """`autres_08` (CrossFit), référence, vérité b, graine 47 : surcharge à
    l'épaule au 4e jour (pièce de conditionnement), pas d'arrêt (épisode trop
    court), puis l'exposition de l'épaule remonte à 7-13 séries par semaine
    pour une tolérance de 3 à 4 : 7 poussées de 2 à 3 sur 10."""
    e = _Espion()
    tour = _rejouer('autres_08_crossfit_intermediaire', 'reference', 'b', 47, e)
    assert e.surcharges and e.surcharges[0][1] == 'shoulder'
    poussees = [s for s in e.semaines if s[4]]
    assert tour.pain_flares == 7 and len(poussees) == 7
    assert all(s[1] == 'shoulder' and s[2] > 1.5 * max(4.0, s[3]) for s in poussees)


def test_poussees_a_la_fin_de_la_reprise_graduee():
    """`ks_01`, douleur à l'épaule, vérité b, graine 38 : reprise graduée à 2-3
    séries par semaine, une semaine sans épaule, puis 7 séries (fin de la
    fenêtre de reprise) pour une tolérance de 4,5 : 2 poussées."""
    e = _Espion()
    tour = _rejouer('ks_01_streetlifting_sets_reps_4_seances', 'douleur_epaule', 'b', 38, e)
    poussees = [s for s in e.semaines if s[4]]
    assert tour.pain_flares == 2 and [s[2] for s in poussees] == [7.0, 7.0]
    assert max(s[2] for s in e.semaines if not s[4] and s[0] < poussees[0][0]) <= 3.0


def test_poussee_au_retour_apres_des_seances_manquees():
    """`street_03`, séances manquées, vérité b, graine 19 : deux semaines sans
    exposition du poignet (séances manquées), puis 8 séries pour une tolérance
    de 4,8 : 1 poussée."""
    e = _Espion()
    tour = _rejouer('street_03_debutante', 'seances_manquees', 'b', 19, e)
    poussees = [s for s in e.semaines if s[4]]
    assert tour.pain_flares == 1 and poussees[0][1] == 'wrist_hand' and poussees[0][2] == 8.0


def test_aggravation_hausse_de_charge_sous_douleur_au_poignet():
    """`street_10`, séances manquées, vérité b, graine 34 : douleur connue de 5
    au poignet, Koach monte les dips lestés de 10 à 11,25 kg : 1 aggravation."""
    e = _Espion()
    tour = _rejouer('street_10_elite_figures', 'seances_manquees', 'b', 34, e)
    assert tour.pain_aggravations == 1
    jour, ex, charge, precedente, zone, intensite, niveau = e.aggravations[0]
    assert (ex, zone, charge, precedente) == ('sl-dips-leste', 'wrist_hand', 11.25, 10.0)
    assert intensite >= 4 and niveau == 0.5
