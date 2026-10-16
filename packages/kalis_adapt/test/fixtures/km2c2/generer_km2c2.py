#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fixtures de parité complémentaires du lot KM2c2 (portage Dart de Koach
1.0.3), produites par la référence Python sans la modifier : branches du delta
1.0.2 → 1.0.3 que les 15 fixtures de `reference/fixtures/` n'exécutent pas
(relecture indépendante de KM2c2, M1).

* `moteur_12_echec.json` : journal de `moteur_12.json` dont la deuxième
  tentative du test 1RM (semaine de test, hors compétition) est ratée — barre
  suivante sur l'estimation mise à jour, au plus `tentative_echec_baisse_part`
  sous la barre ratée (`_tentative`, CHANGEMENTS_1_0_3.md § C) ; puis la même
  variante en semaine de compétition (même barre, A8.2).
* `planification_kappa.json` : replanification d'un athlète aux notes peu
  fiables (κ > 1 : S ← D S D dans `Planification.tirer`).

    python3 test/fixtures/km2c2/generer_km2c2.py             # écrit
    python3 test/fixtures/km2c2/generer_km2c2.py --verifier  # échoue si pas à jour

(depuis `packages/kalis_adapt/`). Même format que les fixtures de la
référence (lues par `test/koach_parite_test.dart`)."""
import copy
import json
import os
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
REF = os.path.normpath(os.path.join(ICI, '..', '..', '..', 'reference'))
sys.path.insert(0, REF)
sys.path.insert(0, os.path.join(REF, 'fixtures'))
import generer as G  # noqa: E402


def _variante_echec(competition):
    f = json.load(open(os.path.join(REF, 'fixtures', 'moteur_12.json'), encoding='utf-8'))
    e = f['entrees']
    journal = copy.deepcopy(e['journal'])
    tentatives = [i for i, x in enumerate(journal)
                  if x['type'] == 'serie' and (x['serie'].get('target') or {}).get('role') == 'attempt']
    if len(tentatives) < 3:
        raise RuntimeError('moteur_12 : moins de trois tentatives')
    i2 = tentatives[1]
    s = journal[i2]['serie']
    s['reps'] = 0
    s['failed'] = True
    s['flames'] = 10
    if competition:
        # La séance des tentatives devient une semaine de compétition.
        j = max(i for i in range(i2) if journal[i]['type'] == 'seance_debut')
        ctx = journal[j]['contexte']
        ctx['genre'] = 'competition'
        ctx['intention'] = 'competition'
    i3 = tentatives[2]
    fin = min(i for i in range(i3, len(journal)) if journal[i]['type'] == 'seance_fin')
    k = G.KoachEnregistre(copy.deepcopy(e['params']), e['fiches'], copy.deepcopy(e['profil']), {})
    servi = None
    for i, x in enumerate(journal):
        if x['type'] == 'plan':
            out = k.plan(copy.deepcopy(x['contraintes']))
            if i < i3 and isinstance(out, dict) and out.get('role') == 'attempt':
                servi = out.get('loadKg')
            continue
        if i == i3:
            # Troisième tentative faite à la barre que Koach vient de servir.
            x['serie']['externalLoadKg'] = servi
            x['serie']['target']['loadKg'] = servi
        if i == fin:
            # Récapitulatif de la séance cohérent avec les séries versées.
            for st in x['seance']['sets']:
                if (st.get('target') or {}).get('role') != 'attempt' or st.get('exerciseId') != s['exerciseId']:
                    continue
                if st.get('setIndex') == s['setIndex']:
                    st.update({'reps': 0, 'failed': True, 'flames': 10, 'success': False})
                elif st.get('setIndex') == journal[i3]['serie']['setIndex']:
                    st['externalLoadKg'] = servi
                    st['target']['loadKg'] = servi
        k.observe(copy.deepcopy(x))
    if G.copie_json(k.journal) != k.entrees:
        raise RuntimeError('journal modifié après coup')
    titre = ('moteur_12, deuxième tentative ratée %s' %
             ('en semaine de compétition (même barre)' if competition else
              'hors compétition (barre suivante sur l\'estimation)'))
    out = G.entete('moteur', titre, e['params'])
    out.update({
        'source': {'base': 'moteur_12.json', 'tentative_ratee': i2, 'troisieme_barre': servi,
                   'competition': competition},
        'entrees': {'params': e['params'], 'fiches': e['fiches'], 'profil': k.profil, 'journal': k.entrees},
        'attendu': {
            'plans': k.plans,
            'instantanes': k.instantanes,
            'final': {'posterior': G.propre(k.posterior()), 'raisons': G.propre(k.explain()),
                      'diagnostic': G.diagnostic(k), 'longueur_journal': len(k.journal),
                      'sha256_parametres_finaux': G.empreinte(k.params)},
        },
    })
    return G.propre(out), k


def _tirage_intermediaire_kappa(pl, k, semaine, n):
    """`generer.tirage_intermediaire` (aide au portage de la référence, qui
    ne sert qu'à recouper `tirer` et n'est pas lue par les tests Dart) avec
    l'élargissement de 1.0.3 : S ← D S D sur les capacités avant Cholesky,
    comme `Planification.tirer`. Le recalcul de la référence l'omet (κ = 1
    dans ses deux fixtures de planification)."""
    np = G.np
    m = k.modele
    lignes = []
    moyennes = []
    for ex in pl.suivis:
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
    for i in [G.RHO] + [G.EPS + c for c in range(len(G.CLASSES))]:
        h = np.zeros(m.n)
        h[i] = 1.0
        lignes.append(h)
        moyennes.append(float(m.m[i]))
    H = np.array(lignes)
    S = H @ m.P[:m.n, :m.n] @ H.T
    S = 0.5 * (S + S.T)
    kappa = m.elargissement()
    if kappa != 1.0:
        for i in range(len(pl.suivis)):
            S[i, :] *= kappa
            S[:, i] *= kappa
    L = np.array(G.nu.cholesky_semi(S.tolist()))
    rng = G.nu.Mulberry32(G.nu.fnv1a32('koach-plan:%d:%d' % (int(pl.p['graine']), semaine)))
    kk = S.shape[0]
    z = np.empty((n, kk))
    for a in range(n):
        for b in range(kk):
            z[a, b] = rng.gauss()
    x = np.asarray(moyennes)[None, :] + z @ L.T
    return {'H': H, 'moyennes': moyennes, 'S': S, 'L': L, 'z': z, 'x': x, 'kappa': kappa}


PLANIFICATION = {'n': 'kappa', 'cle': 'street_16_specialisation_traction_lestee', 'scenario': 'reference',
                 'verite': 'b', 'graine': 2, 'semaines': 4, 'trajectoires': 100,
                 'spec': {'missRate': 0.0, 'ratingNoise': 2.3, 'skipRating': 0.35, 'lazy': 0.3}}


def fixtures():
    out = {}
    for comp, nom in ((False, 'moteur_12_echec.json'), (True, 'moteur_12_echec_competition.json')):
        f, _ = _variante_echec(comp)
        out[nom] = G.texte(f)
    kappas = []
    origine = G.tirage_intermediaire

    def inter(pl, k, semaine, n):
        r = _tirage_intermediaire_kappa(pl, k, semaine, n)
        kappas.append(r['kappa'])
        return r
    G.tirage_intermediaire = inter
    try:
        f = G.fixture_planification(PLANIFICATION)
    finally:
        G.tirage_intermediaire = origine
    if not kappas or kappas[0] <= 1.0:
        raise RuntimeError('planification_kappa : κ = 1, la fixture ne couvre pas S ← D S D')
    f['source']['kappa'] = kappas[0]
    out['planification_kappa.json'] = G.texte(f)
    return out


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    contenus = fixtures()
    ok = True
    for nom, t in contenus.items():
        chemin = os.path.join(ICI, nom)
        if '--verifier' in argv:
            a_jour = os.path.exists(chemin) and open(chemin, encoding='utf-8').read() == t
            print(('à jour : ' if a_jour else 'pas à jour : ') + nom)
            ok = ok and a_jour
        else:
            with open(chemin, 'w', encoding='utf-8', newline='\n') as f:
                f.write(t)
            print(chemin)
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
