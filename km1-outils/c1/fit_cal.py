import pickle,math,sys
import numpy as np
from scipy.optimize import minimize
from scipy.stats import norm
rows=[r for r in pickle.load(open(sys.argv[1],'rb')) if r['prevu']]
def arr(R):
    return (np.array([r['prevu'][0] for r in R]),np.array([r['prevu'][1] for r in R]),np.array([math.log(r['cible']) for r in R]),
            np.array([1.0 if r['best']>=r['cible']-1e-9 else 0.0 for r in R]))
def dec(p,o,nmin=30):
    pire=0;out=[]
    for d in range(10):
        k=(np.minimum(9,np.floor(p*10))==d)
        if k.sum()==0: continue
        out.append('d%d n=%d %.3f/%.3f'%(d,k.sum(),p[k].mean(),o[k].mean()))
        if k.sum()>=nmin: pire=max(pire,abs(p[k].mean()-o[k].mean()))
    return pire,' '.join(out)
for typ in ('charge','reps'):
    R=[r for r in rows if r['type']==typ]
    tr=[r for r in R if r['seed']==0]; te=[r for r in R if r['seed']==1]
    def P(th,A):
        m,s,lt,o=A
        a,b,c=th
        return norm.cdf((m-lt-a)/np.sqrt((c*s)**2+b*b))
    def nll(th,A):
        p=np.clip(P(th,A),1e-6,1-1e-6); o=A[3]
        return -(o*np.log(p)+(1-o)*np.log(1-p)).sum()
    for nom,fitset,testset in (('graine 0 -> 1',tr,te),('graine 1 -> 0',te,tr),('tout',R,R)):
        A=arr(fitset); B=arr(testset)
        best=None
        for x0 in ([0.07,0.07,1.0],[0.1,0.03,0.5],[0.03,0.05,0.8]):
            r=minimize(nll,x0,args=(A,),method='Nelder-Mead',options={'xatol':1e-4,'fatol':1e-4,'maxiter':4000})
            if best is None or r.fun<best.fun: best=r
        th=best.x
        pire,txt=dec(P(th,B),B[3])
        print(typ,nom,'a=%.4f b=%.4f c=%.3f | test écart max %.3f | %s'%(th[0],abs(th[1]),abs(th[2]),pire,txt))
