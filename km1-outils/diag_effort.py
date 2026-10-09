import sys, collections, statistics
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur
from banc.politique_koach import PolitiqueKoach
def un(a):
    cle,kind,seed=a
    infos=donnees.catalogue_infos()
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']=='reference'][0]
    tour=meneur.simuler(s, infos, PolitiqueKoach(), kind, seed)
    out=[]
    for x in tour.sets:
        if x['test'] or x['role']=='warmup' or x['exerciseSession']<3 or x['plannedFailure'] or not x['reachable']: continue
        tr=' '.join(x.get('trace') or [])
        cat='verrou' if 'verrou' in tr else ('part écrite' if 'part ecrite' in tr else ('allégée' if 'allegee' in tr else ('hausse bornée' if 'hausse bornee' in tr else ('douleur' if 'pas de hausse' in tr else ('repère' if x.get('repere') else 'modèle')))))
        diff=x['trueRir']-x['wantRir']
        gap=(-diff if diff<0 else 0.0) if x['openTarget'] else abs(diff)
        out.append((x['mode'],cat,min(x['setIndex'],2),diff,gap,x['main'],kind,x['failed'],x['exerciseSession'],x['wantRir']))
    return out
if __name__=='__main__':
    cles=sys.argv[1].split(','); seeds=int(sys.argv[2])
    jobs=[(c,k,s) for c in cles for k in 'abc' for s in range(1,1+seeds)]
    with Pool(2) as p: res=p.map(un, jobs)
    rows=[r for x in res for r in x]
    print('total n=%d écart %.3f'%(len(rows),statistics.mean(r[4] for r in rows)))
    for mode in ('loaded','reps','hold'):
        R=[r for r in rows if r[0]==mode]
        if not R: continue
        print(mode,'n=%d écart %.3f biais %+.3f'%(len(R),statistics.mean(r[4] for r in R),statistics.mean(r[3] for r in R)))
        c=collections.defaultdict(list)
        for r in R: c[(r[1],r[2])].append(r)
        for k in sorted(c): print('   %-14s série %d n=%5d (%.0f%%) écart %.2f biais %+.2f'%(k[0],k[1],len(c[k]),100*len(c[k])/len(R),statistics.mean(r[4] for r in c[k]),statistics.mean(r[3] for r in c[k])))
        for kind in 'abc':
            K=[r for r in R if r[6]==kind]; print('   modèle',kind,'écart %.2f biais %+.2f'%(statistics.mean(r[4] for r in K),statistics.mean(r[3] for r in K)))

    L=[r for r in rows if r[0]=='loaded' and r[1]=='modèle' and r[6] in 'ab']
    import math
    for si in (0,1,2):
        S=[r for r in L if r[2]==si]
        d=sorted(r[3] for r in S)
        q=lambda p:d[int(p*(len(d)-1))]
        print('modèle A/B série',si,'n',len(S),'quantiles 5/25/50/75/95 : %.1f %.1f %.1f %.1f %.1f'%(q(.05),q(.25),q(.5),q(.75),q(.95)),'échecs %.3f'%statistics.mean(1 if r[7] else 0 for r in S))
    for lo,hi in ((3,5),(6,10),(11,20),(21,99)):
        S=[r for r in L if lo<=r[8]<=hi and r[2]==0]
        if S: print('  séance %d-%d série 0: n=%d biais %+.2f médiane %+.2f échecs %.3f'%(lo,hi,len(S),statistics.mean(r[3] for r in S),statistics.median(r[3] for r in S),statistics.mean(1 if r[7] else 0 for r in S)))
    for main in (True,False):
        S=[r for r in L if r[5]==main and r[2]==0]
        print('  principal' if main else '  accessoire','n=%d biais %+.2f médiane %+.2f échecs %.3f'%(len(S),statistics.mean(r[3] for r in S),statistics.median(r[3] for r in S),statistics.mean(1 if r[7] else 0 for r in S)))
    for w in (1,2,3,4):
        S=[r for r in L if int(r[9])==w and r[2]==0]
        if S: print('  réserve voulue ~%d: n=%d biais %+.2f médiane %+.2f'%(w,len(S),statistics.mean(r[3] for r in S),statistics.median(r[3] for r in S)))
    F=[r for r in rows if r[0]=='loaded']; print('échecs par catégorie', collections.Counter(r[1] for r in F if r[7]), 'total', len(F))
