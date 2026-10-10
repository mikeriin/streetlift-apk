import sys, math, random
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc.politique_koach import vecteurs, params
from koach.moteur import Koach
from koach.modele import Modele, RHO, C_LIN, C_LOG
EX='mu-back-squat-barre-haute'
lam,k=0.3,0.1-0.2   # courbe de population (bas du corps)
def reps_possibles(cap,load):
    x=math.log(cap/load); r=1.0
    for _ in range(60):
        g=math.exp(k)*((1-lam)*C_LIN*(r-1)+lam*C_LOG*math.log(r)); d=math.exp(k)*((1-lam)*C_LIN+lam*C_LOG/r)
        r-= (g-x)/d; r=max(r,1.0)
    return r
def flammes(rir):
    if rir>=5: return 1
    h=math.ceil(rir*2-0.5)
    return 10 if h<=0 else (9 if h==1 else 11-h)
for niveau,growth,seed in [(1,0.0,1),(1,0.0,2),(1,0.0,3),(1,0.004,1),(2,0.0,1)]:
  R=random.Random(seed)
  kk=Koach(params(),vecteurs(),{'niveau':niveau,'poids_kg':80,'declares':{EX:('one_rm_kg',150.0)}})
  traj=[]
  for w in range(24):
    cap=150*(1+growth)**w
    for d in (0,3):
        kk.observe({'type':'seance_debut','jour':7*w+d})
        jour=cap*math.exp(R.gauss(0,0.02)); t_=kk.modele.piste(EX); bw=t_.fraction*80
        for load,reps in [(110,5),(117.5,5),(122.5,4),(122.5,4)]:
            v=reps_possibles(jour+bw,load+bw)-reps
            per=v/1.25+R.gauss(0,0.7)
            kk.observe({'type':'serie','serie':{'exerciseId':EX,'externalLoadKg':load,'reps':reps,'flames':flammes(max(per,0)),'restSeconds':900}})
        kk.observe({'type':'seance_fin'})
    kk.observe({'type':'semaine_fin','jour':7*w+7,'semaine':w})
    traj.append((math.exp(kk.modele.capacite(EX)[0])-kk.modele.piste(EX).fraction*80)/cap-1)
  print('niveau',niveau,'croissance vraie',growth,'graine',seed,'erreur relative e1RM sem 2,6,12,18,24:',[round(traj[i],3) for i in (1,5,11,17,23)],'rho appris %.4f'%kk.modele.m[RHO])
