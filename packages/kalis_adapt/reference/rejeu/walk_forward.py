# -*- coding: utf-8 -*-
"""Rejeu walk-forward d'un journal de l'application par Koach 1.0 (brique 8 du
cahier KM : « erreur d'e1RM sous 3 %, couverture 88 à 92 % »).

Tout le journal converti est rejoué dans l'ordre. Pour chaque séance évaluée
(semaine du programme >= `depuis`), la prévision est notée AVANT de verser
ses séries (après `seance_debut` : bilan et pesée du jour sont connus avant
la séance), sur une COPIE du modèle (la prévision ne perturbe pas le rejeu),
puis la séance est versée.

Mesure A, « une séance d'avance » (exercices de type `charge`) : série la
plus informative = première série de travail ou de test notée 3 en réserve
ou moins (flammes >= 5, 10 = échec), avec au moins une répétition, sans
série plus lourde avant elle dans l'exercice. e1RM réalisé = charge totale ×
exp(g(reps + réserve vraie)), g = courbe de l'exercice AVANT la séance,
réserve vraie = `rir_vrai(réserve dite)` (0 à 10 flammes). Erreur =
|e1RM prévu du jour / réalisé - 1|. Intervalle à 90 % (en ln) : ± 1,645 ×
sqrt(sd_jour² + (bruit de la note en répétitions × pente de la courbe)²).

Mesure B, « tests réels » : lignes `test1rm` (meilleure charge totale
réussie) et `enduranceTest` (meilleure mesure), contre la capacité du jour
prévue (moyenne, intervalle à 90 %).

Mesure C, calibration des notes : pour chaque série notée (sonde du
modèle, prévision juste avant la série), probabilité prévue d'une note
« ouverte » (4 en réserve et plus) contre fréquence observée ; écart moyen
note - prévision (répétitions).

Sortie : JSON d'agrégats seulement (aucune valeur individuelle, aucune date,
aucun identifiant de séance) ; détails série par série seulement avec
`--details` (dossier privé, hors du dépôt).

    python3 -m rejeu.walk_forward <export.json> --programme prog.json.gz \
        --koach-programme koach_program.json.gz --correspondance corr.json \
        --depuis 12 --sortie agregats.json [--details <dossier privé>]
"""
import argparse
import copy
import json
import math
import os
import sys
import traceback

ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.dirname(ICI)
if RACINE not in sys.path:
    sys.path.insert(0, RACINE)

from koach.moteur import Koach  # noqa: E402
from rejeu.journal_app import Programme, convertir, lire_json, rir_de_flammes  # noqa: E402

Z90 = 1.6448536269514722
SEUIL_FLAMMES = 5          # 3 en réserve ou moins
SEUIL_FIABLE = 8           # 1,5 en réserve ou moins
N_MIN_EXERCICE = 5
N_MIN_CELLULE = 3          # en dessous : seul l'effectif est publié (pas de valeur individuelle)
OBJECTIF_ERREUR = 0.03
OBJECTIF_COUVERTURE = (0.88, 0.92)


def charger_params():
    with open(os.path.join(RACINE, 'params', 'koach_params_v1.json'), encoding='utf-8') as f:
        return json.load(f)


def charger_fiches():
    with open(os.path.join(RACINE, 'qualites', 'vecteurs_qualites_v1.json'), encoding='utf-8') as f:
        return json.load(f)['exercices']


def _phi(x):
    return 0.5 * (1.0 + math.erf(x / math.sqrt(2.0)))


def copie_modele(m):
    """Copie profonde du filtre, paramètres et fiches partagés."""
    memo = {id(m.p): m.p, id(m.vecteurs): m.vecteurs, id(m.profil): m.profil}
    return copy.deepcopy(m, memo)


# ----------------------------------------------------------------------
# Choix de la série la plus informative
# ----------------------------------------------------------------------
def serie_informative(series):
    """[series] : séries d'un exercice dans la séance, dans l'ordre. Renvoie
    (rang, série) ou (None, cause)."""
    for pos, s in enumerate(series):
        if s.get('kind') not in ('work', 'test'):
            continue
        f = s.get('flames')
        if (s.get('reps') or 0) < 1 or f is None or f < SEUIL_FLAMMES:
            continue
        ext = s.get('externalLoadKg') or 0.0
        if any((p.get('externalLoadKg') or 0.0) > ext + 1e-9 for p in series[:pos]):
            return None, 'serie_plus_lourde_avant'
        return pos, s
    return None, 'aucune_serie_notee_dure'


# ----------------------------------------------------------------------
# Prévisions d'une séance (sur une copie du modèle)
# ----------------------------------------------------------------------
def prevoir_seance(m, seance, principaux, causes):
    """Mesures A et B d'une séance, avant ses séries. [m] : copie du modèle
    après `seance_debut`."""
    par_ex = {}
    for e, meta in zip(seance['series'], seance['meta']):
        par_ex.setdefault(e['serie']['exerciseId'], []).append((e['serie'], meta))
    rec_a, rec_b = [], []
    for ex in par_ex:
        lst = par_ex[ex]
        t = m.piste(ex)
        if t is None or t.type not in ('charge', 'reps', 'tenue'):
            continue
        mu_j, sd_j = m.capacite_du_jour(ex)
        mu_0, sd_0 = m.capacite(ex)
        famille = 'principal' if ex in principaux else 'autre'
        if t.type == 'charge':
            lam, k = m.courbe(t)
            pos, s = serie_informative([x[0] for x in lst])
            if pos is None:
                causes['A_exercice_sans_serie_retenue_' + s] += 1
            else:
                f = s['flames']
                dit = rir_de_flammes(f)
                vrai = 0.0 if f >= 10 else m.rir_vrai(dit)
                R = s['reps'] + vrai
                charge = m.masse(t, s.get('externalLoadKg'))
                if charge <= 0:
                    causes['A_charge_totale_nulle'] += 1
                else:
                    ln_reel = math.log(charge) + m._g(lam, k, R)
                    pente = m._dg(lam, k, R)
                    bruit = m.bruit_rir_de(vrai, s['reps'])
                    demi = Z90 * math.sqrt(sd_j ** 2 + (bruit * pente) ** 2)
                    ecart = mu_j - ln_reel
                    rec_a.append({
                        'exercice': ex, 'famille': famille, 'role': s.get('role'), 'rang': pos,
                        'flammes': f, 'reps': s['reps'], 'rir_dit': dit, 'rir_vrai': vrai,
                        'charge_totale': charge, 'e1rm_prevu': math.exp(mu_j), 'e1rm_reel': math.exp(ln_reel),
                        'e1rm_a_frais': math.exp(mu_0), 'sd_jour': sd_j, 'sd_frais': sd_0,
                        'bruit_note': bruit, 'pente': pente, 'demi_largeur_ln': demi,
                        'ecart_ln': ecart, 'erreur': math.exp(ecart) - 1.0, 'couvert': bool(abs(ecart) <= demi),
                        'seances_piste': t.seances, 'declare': bool(t.declare), 'forme_courbe': lam,
                        'echelle_courbe': k})
        # Mesure B : tests réels de cet exercice.
        for slot in sorted({x[0].get('slotId') for x in lst}, key=str):
            du_slot = [x for x in lst if x[0].get('slotId') == slot]
            cat = du_slot[0][1].get('cat')
            if cat not in ('test1rm', 'enduranceTest'):
                continue
            if cat == 'test1rm' and t.type == 'charge':
                reussies = [x[0] for x in du_slot if (x[0].get('reps') or 0) >= 1]
                if not reussies:
                    causes['B_test_sans_reussite'] += 1
                    continue
                best = max(reussies, key=lambda s_: m.masse(t, s_.get('externalLoadKg')))
                obs = m.masse(t, best.get('externalLoadKg'))
                pred = math.exp(mu_j)
                lo, hi = math.exp(mu_j - Z90 * sd_j), math.exp(mu_j + Z90 * sd_j)
                borne_basse = best.get('flames') is None or best['flames'] < 10
            elif cat == 'enduranceTest':
                champ = 'seconds' if t.type == 'tenue' else 'reps'
                faites = [x[0] for x in du_slot if x[0].get(champ) is not None]
                if not faites:
                    causes['B_test_sans_mesure'] += 1
                    continue
                best = max(faites, key=lambda s_: s_[champ])
                obs = float(best[champ])
                if obs <= 0:
                    causes['B_test_mesure_nulle'] += 1
                    continue
                if t.type == 'charge':
                    lnc = math.log(m.masse(t, best.get('externalLoadKg')))
                    pred = m.reps_a(t, mu_j - lnc)
                    lo = m.reps_a(t, mu_j - Z90 * sd_j - lnc)
                    hi = m.reps_a(t, mu_j + Z90 * sd_j - lnc)
                else:
                    pred = math.exp(mu_j)
                    lo, hi = math.exp(mu_j - Z90 * sd_j), math.exp(mu_j + Z90 * sd_j)
                borne_basse = best.get('flames') is not None and best['flames'] < 10
            else:
                causes['B_test_type_incompatible'] += 1
                continue
            rec_b.append({'exercice': ex, 'famille': famille, 'genre': cat, 'type': t.type,
                          'prevu': pred, 'bas': lo, 'haut': hi, 'observe': obs,
                          'erreur': pred / obs - 1.0, 'couvert': bool(lo <= obs <= hi),
                          'borne_basse': bool(borne_basse), 'seances_piste': t.seances})
    return rec_a, rec_b


# ----------------------------------------------------------------------
# Rejeu
# ----------------------------------------------------------------------
class ErreurRejeu(RuntimeError):
    pass


def rejouer(conversion, params, fiches, depuis):
    """Rejoue tout le journal ; renvoie les enregistrements privés {A, B,
    C, causes, seances}."""
    from collections import Counter
    k = Koach(params, fiches, conversion['profil'])
    m = k.modele
    m.sonde = []
    me = params['mesure']
    out = {'A': [], 'B': [], 'C': [], 'causes': Counter(), 'seances': []}

    def verser(e):
        try:
            k.observe(e)
        except Exception as exc:  # trace sans valeur du journal
            raise ErreurRejeu('le moteur a échoué sur un événement %r : %s\n%s'
                              % (e.get('type'), type(exc).__name__, traceback.format_exc()))

    for s in conversion['seances']:
        for e in s['avant']:
            verser(e)
        verser(s['debut'])
        evalue = s['semaine'] >= depuis
        info = {'cle': s['cle'], 'semaine': s['semaine'], 'evaluee': evalue}
        if evalue:
            a, b = prevoir_seance(copie_modele(m), s, conversion['principaux'], out['causes'])
            for r in a + b:
                r['cle'] = s['cle']
            out['A'].extend(a)
            out['B'].extend(b)
        for e, meta in zip(s['series'], s['meta']):
            serie = e['serie']
            n0 = len(m.sonde)
            seuil = m.bornes_flammes(3, me['rir_ouvert'])[0]
            verser(e)
            f = serie.get('flames')
            if evalue and len(m.sonde) > n0 and f is not None and not serie.get('failed'):
                sd = m.sonde[-1]
                pred, var = sd[2], sd[3] + sd[4]
                p_ouv = 1.0 - _phi((seuil - pred) / math.sqrt(var if var > 1e-12 else 1e-12))
                out['C'].append({'cle': s['cle'], 'exercice': serie['exerciseId'], 'type': sd[1],
                                 'famille': 'principal' if serie['exerciseId'] in conversion['principaux'] else 'autre',
                                 'flammes': f, 'rir_dit': rir_de_flammes(f), 'prevu': pred, 'sd': math.sqrt(var),
                                 'p_ouverte': p_ouv, 'ouverte': f <= 3})
            del m.sonde[:]
        verser(s['fin'])
        out['seances'].append(info)
    out['modele'] = m
    return out


# ----------------------------------------------------------------------
# Agrégats
# ----------------------------------------------------------------------
def _r(x, n=4):
    return None if x is None else round(float(x), n)


def _mediane(v):
    v = sorted(v)
    if not v:
        return None
    h = len(v) // 2
    return v[h] if len(v) % 2 else 0.5 * (v[h - 1] + v[h])


def resume_erreurs(recs):
    if len(recs) < N_MIN_CELLULE:
        return {'n': len(recs)}
    ab = [abs(r['erreur']) for r in recs]
    sg = [r['erreur'] for r in recs]
    out = {'n': len(recs), 'erreur_moyenne': _r(sum(ab) / len(ab)), 'erreur_mediane': _r(_mediane(ab)),
           'biais_signe_moyen': _r(sum(sg) / len(sg)), 'biais_signe_median': _r(_mediane(sg)),
           'couverture_90': _r(sum(1 for r in recs if r['couvert']) / len(recs), 3)}
    if 'demi_largeur_ln' in recs[0]:
        out['demi_largeur_mediane_pct'] = _r(100 * (math.exp(_mediane([r['demi_largeur_ln'] for r in recs])) - 1), 2)
        out['sd_jour_median'] = _r(_mediane([r['sd_jour'] for r in recs]))
    return out


def _tranche_reps(r):
    n = r['reps']
    return '01-03' if n <= 3 else ('04-06' if n <= 6 else ('07-10' if n <= 10 else '11+'))


def _tranche_note(r):
    f = r['flammes']
    return '10 (0 en réserve)' if f >= 10 else ('8-9 (0,5 à 1,5)' if f >= 8 else '5-7 (2 à 3)')


def _par(recs, cle):
    g = {}
    for r in recs:
        g.setdefault(cle(r), []).append(r)
    return {str(c): resume_erreurs(v) for c, v in sorted(g.items(), key=lambda x: str(x[0]))}


def _par_exercice(recs):
    g = {}
    for r in recs:
        g.setdefault(r['exercice'], []).append(r)
    out, autres = {}, []
    for ex in sorted(g):
        if len(g[ex]) >= N_MIN_EXERCICE:
            out[ex] = resume_erreurs(g[ex])
        else:
            autres.extend(g[ex])
    if autres:
        out['autres (moins de %d chacun, %d exercices)' % (N_MIN_EXERCICE, len({r['exercice'] for r in autres}))] = \
            resume_erreurs(autres)
    return out


def tables_a(recs):
    return {'total': resume_erreurs(recs),
            'par_famille': _par(recs, lambda r: r['famille']),
            'par_role': _par(recs, lambda r: r['role']),
            'par_rang_dans_l_exercice': _par(recs, lambda r: 'premiere serie' if r['rang'] == 0 else 'serie suivante'),
            'par_note': _par(recs, _tranche_note),
            'par_repetitions': _par(recs, _tranche_reps),
            'par_valeur_declaree': _par(recs, lambda r: 'declare' if r['declare'] else 'a priori de population'),
            'par_famille_et_rang': _par(recs, lambda r: r['famille'] + ' / ' + ('premiere' if r['rang'] == 0 else 'suivante')),
            'par_exercice': _par_exercice(recs)}


def tables_b(recs):
    out = {'total': resume_erreurs(recs)}
    for genre in ('test1rm', 'enduranceTest'):
        v = [r for r in recs if r['genre'] == genre]
        out[genre] = resume_erreurs(v)
        out[genre]['meilleure_serie_sous_10_flammes'] = sum(1 for r in v if r['borne_basse'])
        out[genre]['par_famille'] = _par(v, lambda r: r['famille'])
    return out


def tables_c(recs):
    def res(v):
        if len(v) < N_MIN_CELLULE:
            return {'n': len(v)}
        fermees = [r for r in v if not r['ouverte']]
        return {'n': len(v),
                'part_ouvertes_prevue': _r(sum(r['p_ouverte'] for r in v) / len(v), 3),
                'part_ouvertes_observee': _r(sum(1 for r in v if r['ouverte']) / len(v), 3),
                'ecart_moyen_note_moins_prevision': _r(sum(r['rir_dit'] - r['prevu'] for r in v) / len(v), 3),
                'n_notes_fermees': len(fermees),
                'ecart_moyen_notes_fermees': _r(sum(r['rir_dit'] - r['prevu'] for r in fermees) / len(fermees), 3)
                if len(fermees) >= N_MIN_CELLULE else None,
                'ecart_absolu_moyen_notes_fermees': _r(sum(abs(r['rir_dit'] - r['prevu']) for r in fermees)
                                                       / len(fermees), 3) if len(fermees) >= N_MIN_CELLULE else None}
    bins = {}
    for r in recs:
        p = r['p_ouverte']
        b = '0.0-0.1' if p < 0.1 else ('0.1-0.3' if p < 0.3 else ('0.3-0.6' if p < 0.6 else '0.6-1.0'))
        bins.setdefault(b, []).append(r)
    cal = {}
    for b in sorted(bins):
        v = bins[b]
        if len(v) < N_MIN_CELLULE:
            cal[b] = {'n': len(v)}
            continue
        cal[b] = {'n': len(v), 'prevue': _r(sum(r['p_ouverte'] for r in v) / len(v), 3),
                  'observee': _r(sum(1 for r in v if r['ouverte']) / len(v), 3)}
    g = {}
    for r in recs:
        g.setdefault(r['famille'] + ' / ' + r['type'], []).append(r)
    return {'total': res(recs), 'par_famille_et_type': {c: res(v) for c, v in sorted(g.items())},
            'calibration_par_tranche_de_probabilite': cal}


def agreger(conversion, res, depuis):
    a = res['A']
    fiables = [r for r in a if r['flammes'] >= SEUIL_FIABLE]
    tot = resume_erreurs(a)
    ok_err = 'erreur_moyenne' in tot and tot['erreur_moyenne'] < OBJECTIF_ERREUR
    ok_cov = 'couverture_90' in tot and OBJECTIF_COUVERTURE[0] <= tot['couverture_90'] <= OBJECTIF_COUVERTURE[1]
    ev = [s for s in res['seances'] if s['evaluee']]
    return {
        'schema': 'kalis_adapt/rejeu_journal_agregats/1',
        'description': ("Rejeu walk-forward d'un journal réel par Koach 1.0 : agrégats seulement "
                        "(aucune valeur individuelle, aucune date, aucun identifiant de séance)."),
        'parametres': {'depuis_semaine': depuis, 'seuil_flammes_A': SEUIL_FLAMMES, 'seuil_flammes_fiables': SEUIL_FIABLE,
                       'niveau_intervalle': 0.9, 'n_min_par_exercice': N_MIN_EXERCICE,
                       'n_min_par_cellule': N_MIN_CELLULE},
        'conversion': conversion['rapport'],
        'rejeu': {'seances_rejouees': len(res['seances']), 'seances_evaluees': len(ev),
                  'seances_avant_evaluation': len(res['seances']) - len(ev),
                  'exercices_suivis_par_le_moteur': sum(1 for t in res['modele'].pistes.values() if t is not None),
                  'causes': dict(sorted(res['causes'].items()))},
        'A_une_seance_d_avance': tables_a(a),
        'A_series_fiables_1_5_en_reserve_ou_moins': tables_a(fiables),
        'B_tests_reels': tables_b(res['B']),
        'C_calibration_des_notes': tables_c(res['C']),
        'objectif_brique_8': {'erreur_moyenne_sous_3_pct': ok_err, 'couverture_dans_88_92_pct': ok_cov},
    }


def texte_court(ag):
    a = ag['A_une_seance_d_avance']['total']
    f = ag['A_series_fiables_1_5_en_reserve_ou_moins']['total']
    b = ag['B_tests_reels']['total']
    c = ag['C_calibration_des_notes']['total']

    def pc(x):
        return 'n/d' if x is None else '%.1f %%' % (100 * x)
    lignes = ['Rejeu walk-forward (depuis S%d) : %d séances rejouées, %d évaluées.'
              % (ag['parametres']['depuis_semaine'], ag['rejeu']['seances_rejouees'], ag['rejeu']['seances_evaluees'])]
    if a.get('erreur_moyenne') is not None:
        lignes.append('A (une séance d\'avance, e1RM) : n=%d, erreur moyenne %s, médiane %s, biais %s, couverture 90 %% : %s.'
                      % (a['n'], pc(a['erreur_moyenne']), pc(a['erreur_mediane']), pc(a['biais_signe_moyen']),
                         pc(a['couverture_90'])))
    if f.get('erreur_moyenne') is not None:
        lignes.append('A, séries à 1,5 en réserve ou moins : n=%d, erreur moyenne %s, couverture %s.'
                      % (f['n'], pc(f['erreur_moyenne']), pc(f['couverture_90'])))
    if b.get('erreur_moyenne') is not None:
        lignes.append('B (tests réels) : n=%d, erreur moyenne %s, biais %s, couverture %s.'
                      % (b['n'], pc(b['erreur_moyenne']), pc(b['biais_signe_moyen']), pc(b['couverture_90'])))
    if c.get('part_ouvertes_prevue') is not None:
        lignes.append('C (notes) : n=%d, notes ouvertes prévues %s / observées %s, écart moyen note - prévision %+.2f rép.'
                      % (c['n'], pc(c['part_ouvertes_prevue']), pc(c['part_ouvertes_observee']),
                         c['ecart_moyen_note_moins_prevision']))
    o = ag['objectif_brique_8']
    lignes.append('Objectif brique 8 : erreur < 3 %% %s ; couverture 88-92 %% %s.'
                  % ('atteint' if o['erreur_moyenne_sous_3_pct'] else 'non atteint',
                     'atteint' if o['couverture_dans_88_92_pct'] else 'non atteint'))
    return '\n'.join(lignes)


def ecrire_json(chemin, obj):
    with open(chemin, 'w', encoding='utf-8') as f:
        f.write(json.dumps(obj, ensure_ascii=False, indent=1, sort_keys=True))
        f.write('\n')


def ecrire_details(dossier, conversion, res):
    """Détails privés série par série (jamais dans le dépôt)."""
    dossier = os.path.abspath(dossier)
    if dossier == RACINE or dossier.startswith(RACINE + os.sep) or dossier.startswith(
            os.path.dirname(os.path.dirname(os.path.dirname(RACINE))) + os.sep):
        raise SystemExit('refus : les détails privés ne s\'écrivent pas dans le dépôt (%s)' % dossier)
    os.makedirs(dossier, exist_ok=True)
    try:
        os.chmod(dossier, 0o700)
    except OSError:
        pass
    for cle in ('A', 'B', 'C', 'seances'):
        with open(os.path.join(dossier, 'details_%s.jsonl' % cle), 'w', encoding='utf-8') as f:
            for r in res[cle]:
                f.write(json.dumps({k: (_r(v, 6) if isinstance(v, float) else v) for k, v in r.items()},
                                   ensure_ascii=False, sort_keys=True) + '\n')
    ecrire_json(os.path.join(dossier, 'profil_converti.json'),
                {k: v for k, v in conversion['profil'].items()})


def executer(chemin_export, programme, koach_programme, correspondance, depuis, bilan=True):
    params = charger_params()
    fiches = charger_fiches()
    prog = Programme(lire_json(programme), lire_json(koach_programme), lire_json(correspondance))
    conv = convertir(lire_json(chemin_export), prog, fiches, bilan=bilan)
    res = rejouer(conv, params, fiches, depuis)
    return conv, res, agreger(conv, res, depuis)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('export')
    ap.add_argument('--programme', required=True)
    ap.add_argument('--koach-programme', required=True)
    ap.add_argument('--correspondance', required=True)
    ap.add_argument('--depuis', type=int, default=12)
    ap.add_argument('--sortie', required=True)
    ap.add_argument('--details')
    ap.add_argument('--sans-bilan', action='store_true', help='ne pas verser les bilans (sensibilité)')
    a = ap.parse_args(argv)
    conv, res, ag = executer(a.export, a.programme, a.koach_programme, a.correspondance, a.depuis,
                             bilan=not a.sans_bilan)
    ecrire_json(a.sortie, ag)
    if a.details:
        ecrire_details(a.details, conv, res)
    print(texte_court(ag))
    return 0


if __name__ == '__main__':
    sys.exit(main())
