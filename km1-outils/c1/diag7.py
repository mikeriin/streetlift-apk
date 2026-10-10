# diag7.py <graines> : erreur au rang 6 selon la mesure la plus basse en répétitions (réserve vraie <= 3) vue avant
import sys, collections, statistics, math, pickle, os, json
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur
from banc import politique_koach as _pk
from banc.politique_koach import PolitiqueKoach
for _a in [x for x in os.environ.get('SETP','').split(';') if x]:
    _k,_v=_a.split('=',1); _s,_c=_k.split('.',1); _pk.params()[_s][_c]=json.loads(_v)
if os.environ.get('PATCH'): __import__(os.environ['PATCH'])
def un(a):
    cle,kind,seed=a
    infos=donnees.catalogue_infos()
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']=='reference'][0]
    cap={}
    orig=meneur.SimAthlete
    class A(orig):
        def __init__(self,*a,**k):
            super().__init__(*a,**k); cap['ath']=self
    meneur.SimAthlete=A
    pol=PolitiqueKoach()
    tour=meneur.simuler(s, infos, pol, kind, seed)
    meneur.SimAthlete=orig
    ath=cap['ath']; m=pol.koach.modele
    par={}; ordre=[]
    for e in tour.estimates:
        if e['mode']=='loaded' and e['main']:
            c=(e['exerciseId'],e['simDay'])
            if c not in par: ordre.append(c)
            par[c]=e
    rang={}; out=[]
    for c in ordre:
        rang[c[0]]=rang.get(c[0],0)+1
        if rang[c[0]] not in (3,6,12): continue
        e=par[c]
        S=[x for x in tour.sets if x['exerciseId']==c[0] and x['simDay']<=c[1] and not x['failed'] and x['flames'] is not None and x['amount']>=1]
        near=[x for x in S if x['trueRir']<=3.0]
        rmin=min((x['amount']+x['trueRir'] for x in near),default=None)
        ntests=len(set(x['simDay'] for x in S if x['test']))
        tr=ath._truth[c[0]]
        out.append(dict(cle=cle,kind=kind,seed=seed,ex=c[0],rang=rang[c[0]],niveau=s['level'],err=e['capacity']/e['truth']-1,
                        op=e['operational']/e['truthOperational']-1,rmin=rmin,nnear=len(near),ntests=ntests,sd=e['relSd'],
                        gt=(-math.log(tr.share(rmin)) if rmin else None), jour=c[1]))
    return out
if __name__=='__main__':
    seeds=int(sys.argv[1])
    jobs=[(c,k,s) for c in donnees.profils() for k in os.environ.get('KINDS','abc') for s in range(seeds)]
    with Pool(2) as p: res=p.map(un, jobs, chunksize=2)
    rows=[r for x in res for r in x]
    pickle.dump(rows,open(os.environ.get('OUT','tmp_diag7.pkl'),'wb'))
    for rk in (6,12):
        R=[r for r in rows if r['rang']==rk]
        print('rang',rk,'MAE par vérité',[round(statistics.mean(abs(r['err']) for r in R if r['kind']==k),4) for k in 'abc'])
        for lo,hi in ((0,3.5),(3.5,5.5),(5.5,8),(8,11),(11,99)):
            S=[r for r in R if r['rmin'] is not None and lo<=r['rmin']<hi]
            if S: print('  Rmin [%s,%s) n=%d MAE %.4f biais %+.4f | op %.4f | tests %.2f proches %.1f'%(lo,hi,len(S),statistics.mean(abs(r['err']) for r in S),statistics.mean(r['err'] for r in S),statistics.mean(abs(r['op']) for r in S),statistics.mean(r['ntests'] for r in S),statistics.mean(r['nnear'] for r in S)))
        S=[r for r in R if r['rmin'] is None]
        if S: print('  aucune mesure proche n=%d MAE %.4f'%(len(S),statistics.mean(abs(r['err']) for r in S)))
        for lv in range(4):
            S=[r for r in R if r['niveau']==lv]
            print('  niveau',lv,'n=%d Rmin moyen %.1f (aucun %d) tests %.2f jour %.0f'%(len(S),statistics.mean(r['rmin'] for r in S if r['rmin']),sum(1 for r in S if r['rmin'] is None),statistics.mean(r['ntests'] for r in S),statistics.mean(r['jour'] for r in S)))
