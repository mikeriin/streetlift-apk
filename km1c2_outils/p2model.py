import sys,math,numpy as np,statistics as st
from statistics import NormalDist
sys.path.insert(0,'/tmp/k')
import lire
ND=NormalDist()
BASE=dict(kappa=1.0,eps=0.03,manque=0.018,sj=0.046,gain=0.0,ss=0.022,se=0.018,open_part=0.91,p1=.95,p2=.8,p3=.5,pc=.35,s2=.05,s3=.03,kg=5.0,marge=0.045,rend=0.055,biais=0.0)
rng=np.random.default_rng(12345)
Z=rng.standard_normal((6,20000)); EXPO=rng.exponential(1.0,20000)
def p_charge(m,s,lnT,P):
    frais=m+P['biais']+P['kappa']*s*Z[0]
    jour=frais+P['ss']*Z[1]+P['se']*Z[2]
    est=frais+P['eps']*Z[3]
    z1=ND.inv_cdf(P['p1']);z2=ND.inv_cdf(P['p2']);z3=ND.inv_cdf(P['p3']);zc=ND.inv_cdf(P['pc'])
    sj=P['sj']
    a1=est+min(math.log(P['open_part']),-z1*sj)
    a2=np.minimum(np.minimum(est-z2*sj,a1+math.log(1+P['s2'])),np.log(np.exp(a1)+P['kg']))
    a3=np.minimum(a2+math.log(1+P['s3']),np.log(np.exp(a2)+P['kg']))
    vise=(lnT<=a3)&(lnT<=est-zc*sj)
    haut=np.where(vise,a3,np.minimum(a3,est-z3*sj))-P['manque']*EXPO
    ok=(haut>=lnT-1e-12)&(jour>=lnT)
    return float(ok.mean())
def p_reps(m,s,lnT,P):
    frais=m+P['biais']+P['kappa']*s*Z[0]
    jour=frais+P['ss']*Z[1]+P['se']*Z[2]
    return float((jour+P['rend']*Z[3]>=lnT+P['marge']).mean())
def predire(U,P):
    out=[]
    for u in U:
        lnT=math.log(u['T'])
        out.append(p_charge(u['m'],u['s'],lnT,P) if u['mode']=='loaded' else p_reps(u['m'],u['s'],lnT,P))
    return out
def mesure(U,ps,verbose=False):
    dec,pire=lire.deciles(list(zip(ps,[u['ok'] for u in U])))
    ece=sum(n*abs(pm-om) for d,n,pm,om in dec)/len(U)
    brier=st.mean((p-(1.0 if u['ok'] else 0.0))**2 for p,u in zip(ps,U))
    if verbose:
        for d,n,pm,om in dec: print('   d%d n=%4d prévu %.3f observé %.3f %s'%(d,n,pm,om,'' if n>=30 else '(n<30)'))
    return pire,ece,brier
if __name__=='__main__':
    S=[]
    for d in sys.argv[1:]: S+=lire.saisons(d)
    U=lire.unites(S)
    ps0=[u['p'] for u in U]
    print('n',len(U),'moteur (publié)   pire %.3f ece %.4f brier %.4f'%mesure(U,ps0))
    ps=predire(U,BASE); print('réplique base      pire %.3f ece %.4f brier %.4f'%mesure(U,ps), 'écart moyen |réplique-moteur| %.4f'%st.mean(abs(a-b) for a,b in zip(ps,ps0)))
    for k in (0.9,0.8,0.7,0.64,0.6,0.5):
        P=dict(BASE,kappa=k); ps=predire(U,P); print('kappa %.2f         pire %.3f ece %.4f brier %.4f'%((k,)+mesure(U,ps)))
