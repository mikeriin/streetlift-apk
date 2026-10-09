import sys, collections, statistics
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur
from banc.politique_koach import PolitiqueKoach
def un(a):
    cle,scen,kind,seed=a
    infos=donnees.catalogue_infos()
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']==scen][0]
    tour=meneur.simuler(s, infos, PolitiqueKoach(), kind, seed)
    par={}; ordre=[]
    for e in tour.estimates:
        if e['mode']=='loaded' and e['main'] and e['truth']>0:
            k=(e['exerciseId'],e['simDay'])
            if k not in par: ordre.append(k)
            par[k]=e
    rang=collections.Counter(); out=[]
    for k in ordre:
        rang[k[0]]+=1; e=par[k]
        out.append((scen,kind,rang[k[0]],e['capacity']/e['truth']-1,e['simDay']//7,cle,k[0],e['relSd']))
    return out
if __name__=='__main__':
    cles=donnees.profils() if sys.argv[1]=='tous' else sys.argv[1].split(',')
    jobs=[(c,x['scenario'],k,0) for c in cles for x in donnees.saisons_reference(c) for k in 'abc']
    with Pool(2) as p: res=p.map(un, jobs, chunksize=4)
    rows=[r for x in res for r in x]
    print('par scénario (rang 6 | rang>=18)')
    for sc in sorted(set(r[0] for r in rows)):
        A=[r for r in rows if r[0]==sc and r[2]==6]; B=[r for r in rows if r[0]==sc and r[2]>=18]
        if A: print('  %-24s k=6 n=%d MAE %.4f biais %+.4f | k>=18 n=%d MAE %.4f biais %+.4f'%(sc,len(A),statistics.mean(abs(r[3]) for r in A),statistics.mean(r[3] for r in A),len(B),statistics.mean(abs(r[3]) for r in B) if B else 0,statistics.mean(r[3] for r in B) if B else 0))
    print('par semaine (tous scénarios)')
    for w in range(0,40,2):
        A=[r for r in rows if w<=r[4]<w+2]
        if A: print('  sem %d-%d n=%d MAE %.4f biais %+.4f sd %.4f couv %.3f'%(w,w+1,len(A),statistics.mean(abs(r[3]) for r in A),statistics.mean(r[3] for r in A),statistics.mean(r[7] for r in A),statistics.mean(1 if abs(r[3])<=1.645*r[7] else 0 for r in A)))
    B=[r for r in rows if r[2]>=18]
    by=collections.defaultdict(list)
    for r in B: by[(r[5][:26],r[6])].append(r[3])
    print('pires exercices (rang>=18)')
    for k,v in sorted(by.items(), key=lambda kv:-statistics.mean(abs(x) for x in kv[1]))[:12]: print('  ',k,'n=%d MAE %.4f biais %+.4f'%(len(v),statistics.mean(abs(x) for x in v),statistics.mean(v)))
