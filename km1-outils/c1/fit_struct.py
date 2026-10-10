import pickle,math,sys
import numpy as np
from scipy.optimize import minimize
from scipy.stats import norm
rows0=[r for f in sys.argv[1].split(',') for r in pickle.load(open(f,'rb')) if r['prevu']]
# trois dates du critère par unité (début, mi-saison, 4 semaines avant)
import collections
_u=collections.defaultdict(list)
for r in rows0: _u[(r['cle'],r['scen'],r['kind'],r['seed'],r['ex'],r['sem_E'])].append(r)
rows=[]
for k,L in _u.items():
    L.sort(key=lambda r:r['semaine']); d0=L[0]; mi_c=0.5*(d0['semaine']+k[5])
    mi=min(L,key=lambda r:(abs(r['semaine']-mi_c),r['semaine'])); m4=[r for r in L if r['semaine']==k[5]-4]
    rows+= [d0,mi]+m4[:1]
print(len(rows0),'->',len(rows),'lignes aux trois dates')
GA=float(sys.argv[2]) if len(sys.argv)>2 else 0.011   # gain d'affûtage déjà dans prevu
rng=np.random.default_rng(1)
K=800
Z=rng.standard_normal((6,K))
U=-np.log(1-rng.random(K))
def dec(p,o,nmin=30):
    pire=0;out=[]
    for d in range(10):
        k=(np.minimum(9,np.floor(p*10))==d)
        if k.sum()==0: continue
        out.append('d%d n=%d %.3f/%.3f'%(d,k.sum(),p[k].mean(),o[k].mean()))
        if k.sum()>=nmin: pire=max(pire,abs(p[k].mean()-o[k].mean()))
    return pire,' '.join(out)
def arr(R): return (np.array([r['prevu'][0] for r in R]),np.array([r['prevu'][1] for r in R]),np.array([math.log(r['cible']) for r in R]),np.array([1.0 if r['best']>=r['cible']-1e-9 else 0.0 for r in R]))
SE,SX=0.022,0.018
def P_charge(th,A):
    m,s,lt,o=A
    sig_est,sj,manq,ga,cs=np.abs(th[0]),np.abs(th[1]),np.abs(th[2]),th[3],np.abs(th[4])
    x=m[:,None]-GA+ga+cs*s[:,None]*Z[0][None,:]
    jour=x+SE*Z[1][None,:]+SX*Z[2][None,:]
    est=x+sig_est*Z[3][None,:]
    a1=est+min(math.log(.91),-1.645*sj)
    a2=np.minimum(np.minimum(est-0.8416*sj,a1+math.log(1.05)),np.log(np.exp(a1)+5))
    a3=np.minimum(a2+math.log(1.03),np.log(np.exp(a2)+5))
    L=lt[:,None]
    vise=(L<=a3)&(L<=est+0.3853*sj)
    haut=np.where(vise,a3,np.minimum(a3,est))-manq*U[None,:]
    ok=(haut>=L)&(jour>=L)
    return ok.mean(axis=1)
def P_reps(th,A):
    m,s,lt,o=A
    marge,sr,cs=th[0],abs(th[1]),abs(th[2])
    return norm.cdf((m-GA-lt-marge)/np.sqrt((cs*s)**2+SE**2+SX**2+sr**2))
def nll(th,A,P):
    p=np.clip(P(th,A),1e-4,1-1e-4); o=A[3]
    return -(o*np.log(p)+(1-o)*np.log(1-p)).sum()
for typ,P,x0s in (('charge',P_charge,([0.036,0.06,0.03,0.007,1.0],[0.03,0.08,0.02,0.0,0.8])),('reps',P_reps,([0.03,0.06,1.0],[0.0,0.03,1.3]))):
    R=[r for r in rows if r['type']==typ]
    for nom,fa,fb in (('pairs->impairs',[r for r in R if r['seed']%2==0],[r for r in R if r['seed']%2==1]),('impairs->pairs',[r for r in R if r['seed']%2==1],[r for r in R if r['seed']%2==0]),('tout',R,R)):
        A=arr(fa);B=arr(fb);best=None
        for x0 in x0s:
            r=minimize(nll,x0,args=(A,P),method='Nelder-Mead',options={'xatol':1e-4,'fatol':1e-3,'maxiter':3000})
            if best is None or r.fun<best.fun: best=r
        pire,txt=dec(P(best.x,B),B[3])
        print(typ,nom,np.round(np.abs(best.x) if typ=='charge' else best.x,4),'| écart max %.3f |'%pire,txt)
    A=arr(R); print(typ,'paramètres en place :',dec(P(x0s[0],A),A[3]))
