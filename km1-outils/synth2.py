# banc synthétique minimal : un exercice, vérité A simplifiée, pour isoler les dérives de l'estimateur
import sys, math, random, statistics, copy
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc.politique_koach import params, vecteurs
from koach.modele import Modele, LAM, BA, FI, DS
from banc.alea import flames_from_rir
def run(seed, opts):
    rnd=random.Random(seed)
    P=copy.deepcopy(params())
    for k,v in opts.get('params',{}).items():
        s,c=k.split('.'); P[s][c]=v
    ex='mu-developpe-couche-barre'
    cap=100.0*math.exp(0.08*rnd.gauss(0,1)); a=0.30; b=0.044*math.exp(opts.get('b_sd',0.2)*rnd.gauss(0,1))
    beta=min(0.8,max(-0.15,0.25+opts.get('beta_sd',0.18)*rnd.gauss(0,1)))
    noise=opts.get('noise',1.0)
    m=Modele(P, vecteurs(), {'niveau':1,'sexe':'male','poids_kg':80.0,'declares':{ex:('one_rm_kg',100.0)}})
    errs=[]
    for sess in range(opts.get('sessions',30)):
        jour=sess*3
        day=opts.get('day_mean',-0.025)+opts.get('day_sd',0.028)*rnd.gauss(0,1)
        m.debut_seance(jour)
        fat=[]
        for si in range(opts.get('sets',3)):
            # charge : part visée aléatoire
            lo,hi=opts.get('parts',(0.6,0.92))
            part=rnd.uniform(lo,hi); load=round(cap*part/2.5)*2.5
            if opts.get('policy')=='model':
                # charge choisie par le modèle pour (reps_c, rir_c)
                reps_c=opts.get('reps_c',5); rir_c=opts.get('rir_c',2.5)
                mu,sd=m.capacite_du_jour(ex); t=m.piste(ex); lam,k=m.courbe(t)
                fi=max(0.0,min(1.5,m.m[FI])); g_=max(0.3,1-fi*m._intra(t))
                load=round(math.exp(mu-0.25*sd-m._g(lam,k,(reps_c+rir_c)/g_))/2.5)*2.5
                if si>0 and opts.get('backoff'): load=round(load0*(1-opts['backoff'])/2.5)*2.5
                if si==0: load0=load
            share=load/(cap*math.exp(day))
            R=1-(share-1)*20 if share>=1 else (100.0 if share<=a+1e-6 else min(100.0,1-math.log((share-a)/(1-a))/b))
            keep=1-min(0.8,sum(f*math.exp((len(fat)-1-i)/2*math.log(0.5)) for i,f in enumerate(fat)))
            capn=R*keep
            want=opts.get('rir',lambda r:r.choice([1,2,3,4,6]))(rnd)
            reps=max(1,int(round(capn-want)))
            if opts.get('policy')=='model':
                reps=opts.get('reps_c',5)
                if opts.get('feel'):
                    # plage au ressenti : s'arrête à la réserve visée perçue
                    lo_r,hi_r=opts['feel']; stop=capn-(opts.get('rir_c',2.5)*(1+beta)-noise*(0.3+0.2*opts.get('rir_c',2.5))*rnd.gauss(0,1))
                    reps=min(hi_r,max(lo_r,int(round(stop))))
            failed=False
            if capn<reps: reps=max(0,int(math.floor(capn))); failed=True
            true=max(0.0,capn-reps)
            longf=1+((capn-12)/12 if capn>12 else 0); bias=beta*(1+((capn-12)/24 if capn>12 else 0))
            per=true/(1+bias)+noise*(0.3+0.2*min(true,6))*longf*rnd.gauss(0,1)
            per=max(0.0,per); fl=10 if failed else flames_from_rir(per)
            if fl==10 and true>=0.75 and not failed: fl=9
            tf=None
            if opts.get('lazy'):
                from koach.seance import flammes_de_rir
                tf=flammes_de_rir(opts.get('rir_c',2.5))
                if not failed and rnd.random()<opts['lazy']*(1.0 if abs(fl-tf)<=2 else (0.5 if abs(fl-tf)<=4 else 0.25)): fl=tf
            rest=opts.get('rest',180)
            if opts.get('fatigue',True): fat.append(0.85*math.exp(-rest/160)*math.exp(-min(true,8)/1.4))
            m.observer_serie({'exerciseId':ex,'kind':'work','externalLoadKg':load,'reps':reps,'flames':fl,'failed':failed,'target':{'flames':tf},'restSeconds':rest})
        m.fin_seance()
        if (sess+1)%7==0: m.avancer(jour+1); m.fin_semaine()
        c=m.capacite(ex); errs.append(math.exp(c[0])/cap-1)
    t=m.pistes[ex]
    return errs, float(m.m[LAM]), float(m.m[t.idx+1]), math.log(b/0.044), beta
if __name__=='__main__':
    import json
    cases={
     'base':{},
     'sans bruit, beta 0.25':{'noise':0.05,'beta_sd':0.0},
     'sans effet de jour':{'day_sd':0.0,'day_mean':0.0},
     'sans fatigue':{'fatigue':False},
     'près de l échec seulement':{'rir':lambda r:r.choice([0.5,1,1.5,2])},
     'loin seulement':{'rir':lambda r:r.choice([4,6,8])},
     'politique modèle 5@2.5':{'policy':'model'},
     'politique modèle + allégées 8%':{'policy':'model','backoff':0.08},
     'politique modèle + paresse':{'policy':'model','lazy':0.1},
     'politique modèle ressenti 4-6':{'policy':'model','feel':(4,6)},
     'politique modèle, jour 0':{'policy':'model','day_sd':0.0},
     'politique modèle, beta fixe':{'policy':'model','beta_sd':0.0},
     'politique modèle, sans bruit':{'policy':'model','noise':0.05},
     'politique modèle, sans fatigue':{'policy':'model','fatigue':False},
     'pm lam figé':{'policy':'model','params':{'a_priori.courbe_forme':[0.3,0.0]}},
     'pm lam et k figés':{'policy':'model','params':{'a_priori.courbe_forme':[0.3,0.0],'a_priori.courbe_echelle_exercice_sd':0.001}},
     'pm lam figé, b vrai fixe':{'policy':'model','b_sd':0.0,'params':{'a_priori.courbe_forme':[0.3,0.0]}},
     'pm lam figé sans bruit':{'policy':'model','noise':0.05,'params':{'a_priori.courbe_forme':[0.3,0.0]}},
     'pmf bruit homogène (modèle)':{'policy':'model','params':{'a_priori.courbe_forme':[0.3,0.0],'mesure.bruit_rir_pente':0.0}},
     'pmf rir_ouvert 6':{'policy':'model','params':{'a_priori.courbe_forme':[0.3,0.0],'mesure.rir_ouvert':6.0}},
     'pmf rir 1 visé':{'policy':'model','rir_c':1.0,'params':{'a_priori.courbe_forme':[0.3,0.0]}},
     'pmf rir 4 visé':{'policy':'model','rir_c':4.0,'params':{'a_priori.courbe_forme':[0.3,0.0]}},
     'pmf 1 série':{'policy':'model','sets':1,'params':{'a_priori.courbe_forme':[0.3,0.0]}},
     'pmf reps 2':{'policy':'model','reps_c':2,'params':{'a_priori.courbe_forme':[0.3,0.0]}},
     'pmf reps 10':{'policy':'model','reps_c':10,'params':{'a_priori.courbe_forme':[0.3,0.0]}},
     'pmf 1 passe':{'policy':'model','params':{'a_priori.courbe_forme':[0.3,0.0],'mesure.passes_linearisation':1}},
     'pm lam libre 1 passe':{'policy':'model','params':{'mesure.passes_linearisation':1}},
     'tout propre':{'noise':0.05,'beta_sd':0.0,'day_sd':0.0,'day_mean':0.0,'fatigue':False,'b_sd':0.0},
    }
    which=sys.argv[1:] or list(cases)
    for name in which:
        R=[run(s,cases[name]) for s in range(40)]
        e6=[r[0][5] for r in R]; e30=[r[0][-1] for r in R]
        print('%-28s err k=6 biais %+.4f MAE %.4f | k=30 biais %+.4f MAE %.4f | LAM %.2f | k_e−vrai %+.3f'%(name,statistics.mean(e6),statistics.mean(abs(x) for x in e6),statistics.mean(e30),statistics.mean(abs(x) for x in e30),statistics.mean(r[1] for r in R),statistics.mean(r[2]-r[3] for r in R)))
