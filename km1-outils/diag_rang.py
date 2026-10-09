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
    tests=collections.defaultdict(set); days=collections.defaultdict(list); wk={}
    for x in tour.sets:
        if x['mode']=='loaded' and x['main']:
            if x['test']: tests[x['exerciseId']].add(x['simDay'])
            if x['simDay'] not in days[x['exerciseId']]: days[x['exerciseId']].append(x['simDay'])
    out=[]; par={}
    for e in tour.estimates:
        if e['mode']=='loaded' and e['main']: par[(e['exerciseId'],e['simDay'])]=e
    for ex,ds in days.items():
        for r,d in enumerate(ds,1):
            e=par.get((ex,d))
            if e is None: continue
            nt=len([t for t in tests[ex] if t<=d])
            out.append((kind,r,nt,e['capacity']/e['truth']-1,s['level'],cle,ex,d))
    return out
if __name__=='__main__':
    cles=sys.argv[1].split(','); seeds=int(sys.argv[2])
    jobs=[(c,k,s) for c in cles for k in 'abc' for s in range(seeds)]
    with Pool(2) as p: res=p.map(un, jobs)
    rows=[r for x in res for r in x]
    for rk in (3,6,9,12):
        R=[r for r in rows if r[1]==rk]
        line='rang %d n=%d MAE %.4f |'%(rk,len(R),statistics.mean(abs(r[3]) for r in R))
        for nt in (0,1,2):
            S=[r for r in R if (r[2]==nt if nt<2 else r[2]>=2)]
            if S: line+=' tests=%d: n=%d MAE %.4f biais %+.4f |'%(nt,len(S),statistics.mean(abs(r[3]) for r in S),statistics.mean(r[3] for r in S))
        print(line)
    R=[r for r in rows if r[1]==6]
    for lv in sorted(set(r[4] for r in R)):
        S=[r for r in R if r[4]==lv]; print('niveau',lv,'n=%d MAE %.4f biais %+.4f, sans test %.2f'%(len(S),statistics.mean(abs(r[3]) for r in S),statistics.mean(r[3] for r in S),statistics.mean(1 if r[2]==0 else 0 for r in S)))
    by=collections.defaultdict(list)
    for r in R: by[(r[5][:22],r[6])].append(r)
    for k,S in sorted(by.items()): print(' ',k,'n=%d MAE %.4f biais %+.4f sans test %.2f jour~%d'%(len(S),statistics.mean(abs(r[3]) for r in S),statistics.mean(r[3] for r in S),statistics.mean(1 if r[2]==0 else 0 for r in S),statistics.mean(r[7] for r in S)))
