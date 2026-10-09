import sys, collections, statistics
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur
from banc.politique_koach import PolitiqueKoach
def un(a):
    cle,kind,seed=a
    infos=donnees.catalogue_infos()
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']=='reference'][0]
    pol=PolitiqueKoach(); tour=meneur.simuler(s, infos, pol, kind, seed)
    tests=collections.defaultdict(list)
    for x in tour.sets:
        if x['test'] and x['mode']=='loaded': tests[x['exerciseId']].append((x['simDay'], x['trueRir'], x['amount'], x['totalKg']/x['capacity'], x['flames']))
    out=[]
    for e in tour.estimates:
        if e['mode']=='loaded' and e['main']:
            n=len(set(d for d,_,_,_,_ in tests[e['exerciseId']] if d<=e['simDay']))
            last=[t for t in tests[e['exerciseId']] if t[0]<=e['simDay']]
            out.append((kind, n, e['capacity']/e['truth']-1, e['relSd'], last[-1] if last else None, e['simDay']==(last[-1][0] if last else -1)))
    po=pol.koach.posterior()
    return out, (kind, po['biais_rir'][0], po['biais_rir'][1], po['courbe'][0], po['courbe'][1], po['fatigue_intra'], po['bruit_rir'])
if __name__=='__main__':
    cles=sys.argv[1].split(','); seeds=int(sys.argv[2])
    jobs=[(c,k,s) for c in cles for k in 'abc' for s in range(seeds)]
    with Pool(2) as p: res=p.map(un, jobs)
    by=collections.defaultdict(list); hyp=collections.defaultdict(list); day=collections.defaultdict(list)
    for rows,h in res:
        hyp[h[0]].append(h[1:])
        for (kind,n,err,sd,last,sameday) in rows:
            by[(kind,min(n,3))].append(err)
            if sameday and last: day[kind].append((err, last[1], last[3]))
    for k in sorted(by): print(k,'n=%d biais=%+.4f MAE=%.4f'%(len(by[k]),statistics.mean(by[k]),statistics.mean(abs(x) for x in by[k])))
    for k in hyp: print(k,'BA %.2f BP %.2f LAM %.2f KU %.2f FI %.2f bruit %.2f'%tuple(statistics.mean(h[i] for h in hyp[k]) for i in range(6)))
    for k in day:
        d=day[k]; print('jour de test',k,'n=%d err=%+.4f MAE=%.4f rir_final=%.2f part=%.3f'%(len(d),statistics.mean(x[0] for x in d),statistics.mean(abs(x[0]) for x in d),statistics.mean(x[1] for x in d),statistics.mean(x[2] for x in d)))
