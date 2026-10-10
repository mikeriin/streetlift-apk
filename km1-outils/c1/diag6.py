# diag6.py <profils> <graines> [scenario] : décomposition de l'erreur au rang 6 (principaux chargés)
import sys, collections, statistics, math, pickle, os
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur
from banc.politique_koach import PolitiqueKoach
from koach import modele as M
SC=sys.argv[3] if len(sys.argv)>3 else 'reference'
import os, json
from banc import politique_koach as _pk
for _a in [x for x in os.environ.get('SETP','').split(';') if x]:
    _k,_v=_a.split('=',1); _s,_c=_k.split('.',1); _pk.params()[_s][_c]=json.loads(_v)
def un(a):
    cle,kind,seed=a
    infos=donnees.catalogue_infos()
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']==SC]
    if not s: return []
    s=s[0]
    cap={}
    orig=meneur.SimAthlete
    class A(orig):
        def __init__(self,*a,**k):
            super().__init__(*a,**k); cap['ath']=self
    meneur.SimAthlete=A
    pol=PolitiqueKoach()
    snaps={}
    orig_est=pol.estimer
    def est(ex_id,n):
        r=orig_est(ex_id,n)
        m=pol.koach.modele; t=m.piste(ex_id)
        if r is not None and t is not None and t.type=='charge':
            ath=cap['ath']; tr=ath._truth.get(ex_id)
            lam,k=m.courbe(t)
            snaps[(ex_id,ath.day)]=dict(beta=ath.beta,bp=float(m.m[M.BP]),lam=lam,k=k,
                g6=m._g(lam,k,6),t6=-math.log(tr.share(6)),g3=m._g(lam,k,3),t3=-math.log(tr.share(3)),
                fs=tr.fatigue_scale,fi=m.fatigue_intra_de(t),ntest=t.dernier_test_jour,mes=t.mesures,bruit=m.bruit_rir)
        return r
    pol.estimer=est
    tour=meneur.simuler(s, infos, pol, kind, seed)
    meneur.SimAthlete=orig
    par={}; ordre=[]
    for e in tour.estimates:
        if e['mode']=='loaded' and e['main']:
            c=(e['exerciseId'],e['simDay'])
            if c not in par: ordre.append(c)
            par[c]=e
    rang={}; out=[]
    for c in ordre:
        rang[c[0]]=rang.get(c[0],0)+1
        e=par[c]; sn=snaps.get(c,{})
        out.append(dict(cle=cle,kind=kind,seed=seed,ex=c[0],day=c[1],rang=rang[c[0]],niveau=s['level'],
            err=e['capacity']/e['truth']-1, op=e['operational']/e['truthOperational']-1, sd=e['relSd'], **sn))
    return out
if __name__=='__main__':
    cles=donnees.profils() if sys.argv[1]=='tous' else sys.argv[1].split(',')
    seeds=int(sys.argv[2])
    jobs=[(c,k,s) for c in cles for k in 'abc' for s in range(seeds)]
    with Pool(2) as p: res=p.map(un, jobs, chunksize=2)
    rows=[r for x in res for r in x]
    pickle.dump(rows,open(os.environ.get('OUT','tmp_diag6.pkl'),'wb'))
    def st(S,key='err'):
        v=[r[key] for r in S]
        return 'n=%3d MAE %.4f biais %+.4f'%(len(v),statistics.mean(abs(x) for x in v),statistics.mean(v)) if v else 'n=0'
    R=[r for r in rows if r['rang']==6]
    print('tous',st(R),'| op',st(R,'op'))
    for k in 'abc':
        S=[r for r in R if r['kind']==k]
        print('vérité',k,st(S),'| op',st(S,'op'),'| sd %.3f'%statistics.mean(r['sd'] for r in S))
        for lv in range(4):
            T=[r for r in S if r['niveau']==lv]
            if T:
                print('   niv',lv,st(T),'| op',st(T,'op'),'| sd %.3f bp %.2f beta %.2f | g6 %.3f t6 %.3f | g3 %.3f t3 %.3f | fi %.2f fs %.2f'%(
                    statistics.mean(r['sd'] for r in T),statistics.mean(r['bp'] for r in T),statistics.mean(r['beta'] for r in T),
                    statistics.mean(r['g6'] for r in T),statistics.mean(r['t6'] for r in T),statistics.mean(r['g3'] for r in T),statistics.mean(r['t3'] for r in T),
                    statistics.mean(r['fi'] for r in T),statistics.mean(r['fs'] for r in T)))
    # corrélations
    import numpy as np
    for k in 'abc':
        S=[r for r in R if r['kind']==k]
        e=np.array([r['err'] for r in S])
        for nm,f in (('beta-bp',lambda r:r['beta']-r['bp']),('t6-g6',lambda r:r['t6']-r['g6']),('t3-g3',lambda r:r['t3']-r['g3']),('ln fs',lambda r:math.log(r['fs']))):
            x=np.array([f(r) for r in S]); c=np.corrcoef(x,e)[0,1]; b=np.polyfit(x,e,1)
            print('  ',k,nm,'corr %.2f pente %.3f sd_x %.3f'%(c,b[0],x.std()))
