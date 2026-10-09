# essai parallèle : essai2.py <profils|tous|street|autres> <scenarios|tous> <graines> [modeles]
import sys, time, statistics, json
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur, mesures
from banc.politique_koach import PolitiqueKoach
import os, json as _json
PLAN=_json.loads(os.environ['PLAN']) if os.environ.get('PLAN') else None
def _pol():
    if PLAN is None: return PolitiqueKoach()
    from banc import planification_banc
    return PolitiqueKoach(extensions=[planification_banc.fabrique(PLAN)])
def un(args):
    cle,scen,kind,seed=args
    infos=donnees.catalogue_infos()
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']==scen][0]
    tour=meneur.simuler(s, infos, _pol(), kind, seed)
    E={m:mesures.Estimations() for m in ('loadedMain','loaded','reps','hold')}
    E['loadedMain'].add(tour, lambda e:e['mode']=='loaded' and e['main'])
    E['loaded'].add(tour, lambda e:e['mode']=='loaded')
    E['reps'].add(tour, lambda e:e['mode']=='reps')
    E['hold'].add(tour, lambda e:e['mode']=='hold')
    return (cle,scen,kind,seed,{m:(E[m].rows,E[m].first_under) for m in E}, mesures.evenements(tour), mesures.effort(tour), mesures.gain_moyen(tour), tour.pain_aggravations, tour.pain_flares)
if __name__=='__main__':
    a=sys.argv
    cles=donnees.profils()
    if a[1] in ('street','autres'): cles=[c for c in cles if c.startswith(a[1])]
    elif a[1]!='tous': cles=a[1].split(',')
    scens=a[2].split(','); seeds=int(a[3]); kinds=a[4] if len(a)>4 else 'abc'
    jobs=[]
    for cle in cles:
        for s in donnees.saisons_reference(cle):
            if scens!=['tous'] and s['scenario'] not in scens: continue
            for k in kinds:
                for seed in range(seeds): jobs.append((cle,s['scenario'],k,seed))
    t0=time.time()
    with Pool(2) as p: res=p.map(un, jobs, chunksize=4)
    E={m:mesures.Estimations() for m in ('loadedMain','loaded','reps','hold')}
    EK={k:mesures.Estimations() for k in kinds}
    ev=[]; eff=[]; gains=[]; agg=fl=0
    for (cle,scen,kind,seed,rows,evs,ef,g,pa,pf) in res:
        for m in E:
            for k in range(len(rows[m][0])):
                for c in range(7): E[m].rows[k][c]+=rows[m][0][k][c]
            E[m].first_under+=rows[m][1]
        for k in range(len(rows['loadedMain'][0])):
            for c in range(7): EK[kind].rows[k][c]+=rows['loadedMain'][0][k][c]
        ev+=evs; eff.append(ef); agg+=pa; fl+=pf
        if g is not None: gains.append(g)
    print('saisons',len(res),'%.0fs'%(time.time()-t0),'gain %.5f'%statistics.mean(gains),'aggr',agg,'flares',fl)
    for m in E:
        f=E[m].first_under; nz=[x for x in f if x>0]
        print(m,'premier rang MAE<3%:',E[m].premier_rang_sous(),' premier passage: moy %.2f jamais %.3f'%(statistics.mean(nz) if nz else -1, 1-len(nz)/max(1,len(f))))
        for k in (1,3,6,12,24):
            l=E[m].ligne(k)
            if l: print('  k=%d n=%d MAE=%.4f biais=%+.4f sous3=%.3f couv=%.3f sd=%.4f'%(k,l['n'],l['mae'],l['biais'],l['sous3'],l['couverture'],l['sd']))
    for k in EK:
        l=EK[k].ligne(6)
        if l: print('modele',k,'principaux k=6 MAE=%.4f biais=%+.4f couv=%.3f'%(l['mae'],l['biais'],l['couverture']))
    ee=[e for e in eff if e['ecart_effort'] is not None]
    print('ecart effort %.3f'%statistics.mean(e['ecart_effort'] for e in ee), 'echecs %.4f'%statistics.mean(e['echecs'] for e in ee), 'hausses', sum(e['hausses_trop_fortes'] for e in eff))
    for mode in ('loaded','reps','hold'):
        x=[e for e in ev if e[1]==mode]
        if x: print('echeance',mode,len(x),'best/max %.4f'%statistics.mean(e[2]/e[4] for e in x),'best/cap0 %.4f'%statistics.mean(e[2]/e[5] for e in x if e[5]))
