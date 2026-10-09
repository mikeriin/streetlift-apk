import sys, math, random
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc.politique_koach import params, vecteurs
from koach.modele import Modele, BA, LAM, KU, FI, C_LIN, C_LOG
from koach.seance import flammes_de_rir
def run(seed, BA_T=1.0, K_T=0.3, LAM_T=0.1, noise=0.8, fi_t=0.08, nses=30, verbose=False):
    rnd=random.Random(seed)
    m=Modele(params(), vecteurs(), {'niveau':1,'sexe':'male','poids_kg':80})
    exs={'mu-developpe-couche-barre':(math.log(100*math.exp(rnd.gauss(0,.15))), K_T+rnd.gauss(0,.1)),
         'mu-squat-barre':(math.log(130*math.exp(rnd.gauss(0,.15))), K_T+rnd.gauss(0,.1)),
         'mu-rowing-barre-pronation':(math.log(90*math.exp(rnd.gauss(0,.15))), K_T+rnd.gauss(0,.1))}
    exs={k:v for k,v in exs.items() if k in vecteurs()}
    def g(k,R): return math.exp(k)*((1-LAM_T)*C_LIN*(R-1)+LAM_T*C_LOG*math.log(R))
    def reps_at(k,x):
        lo,hi=1.0,200.0
        for _ in range(60):
            mid=(lo+hi)/2
            if g(k,mid)<x: lo=mid
            else: hi=mid
        return lo
    for ses in range(nses):
        day=ses*3
        dayeff=rnd.gauss(0,0.02)
        m.debut_seance(day, None)
        for ex,(lc,k) in exs.items():
            de=rnd.gauss(0,0.015)
            reps=rnd.choice([3,5,8,10,12])
            sj=0.0; fat=[]
            for i in range(3):
                # load from the model itself (target RIR 3)
                t=m.piste(ex)
                mu,sd=m.capacite(ex)
                lam_m,k_m=m.courbe(t)
                L=math.exp(mu - m._g(lam_m,k_m,reps+3.0))
                L=round(L/2.5)*2.5
                keep=1-fi_t*sum(e*math.exp(-120/150)*0.7**(len(fat)-1-j) for j,e in enumerate(fat))
                R=reps_at(k, lc+dayeff+de-math.log(L))*keep
                v=R-reps
                if v<0:
                    done=int(R); rec={'exerciseId':ex,'externalLoadKg':L,'reps':done,'flames':10,'failed':True,'restSeconds':120}
                    v=R-done
                else:
                    p=(v-BA_T)/1.2+rnd.gauss(0,noise*(0.5+0.25*min(v,8))/1.0)
                    p=max(p,0)
                    rec={'exerciseId':ex,'externalLoadKg':L,'reps':reps,'flames':flammes_de_rir(p),'restSeconds':120}
                m.observer_serie(rec)
                fat.append(1/(1+max(v,0)/2))
        m.fin_seance()
        if ses%7==6: m.fin_semaine()
    err=[math.exp(m.capacite(ex)[0]-lc)-1 for ex,(lc,k) in exs.items()]
    return err, m.m[BA], m.m[LAM], m.m[KU], m.m[FI], [m.m[m.piste(ex).idx+1] for ex in exs], [k for ex,(lc,k) in exs.items()], [m.capacite(ex)[1] for ex in exs]
for seed in range(6):
    e,ba,lam,ku,fi,ke,kt,sd=run(seed)
    print('err',['%+.3f'%x for x in e],'sd',['%.3f'%x for x in sd],'BA %.2f LAM %.2f KU %.2f FI %.3f'%(ba,lam,ku,fi),'ke',['%.2f'%x for x in ke],'kT',['%.2f'%x for x in kt])
