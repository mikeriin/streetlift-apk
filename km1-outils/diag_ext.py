import sys, statistics
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur, mesures, extensions_koach as ek, politique_koach as pk, campagne as ca
QUI = sys.argv[3]
def pol(graine):
    fab = []
    if 'p' in QUI: fab.append(lambda pol: ca.PlanificationCampagne(pol, {'trajectoires': 200}, True))
    if 's' in QUI: fab.append(ek.fabrique_surveillance())
    if 'd' in QUI: fab.append(ek.fabrique_controle_dual(graine))
    if 'a' in QUI: fab.append(ek.fabrique_adherence(graine))
    return ek.PolitiqueBriques(extensions=fab)
def un(a):
    cle, scen, kind, seed = a
    s = [x for x in donnees.saisons_reference(cle) if x['scenario'] == scen][0]
    p = pol(seed)
    tour = meneur.simuler(s, donnees.catalogue_infos(), p, kind, seed)
    ev = mesures.evenements(tour)
    return [(e[2] / e[4]) for e in ev if e[1] == 'loaded' and e[2] and e[4]], cle, kind, {type(x).__name__: len(getattr(x, 'journal', []) or []) for x in p.koach.extensions}
if __name__ == '__main__':
    cles = sys.argv[1].split(',')
    jobs = [(c, sys.argv[2], k, 0) for c in cles for k in 'abc']
    with Pool(2) as p: res = p.map(un, jobs)
    r = [x for a in res for x in a[0]]
    print(QUI, len(r), round(statistics.mean(r), 4))
    for a in res:
        if a[0] and min(a[0]) < 0.85: print('  ', a[1], a[2], [round(x, 3) for x in a[0]], a[3])
