# calib.py <graines> : données de calibration de P(réussite) par cible (saisons à cibles et échéance)
import sys, os, json, math, pickle, collections
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur, campagne as C, planification_banc as pb, extensions_koach as ek
from banc import politique_koach as pk
from koach import seance as S
for _a in [x for x in os.environ.get('SETP','').split(';') if x]:
    _k,_v=_a.split('=',1); _s,_c=_k.split('.',1); pk.params()[_s][_c]=json.loads(_v)
TRAJ=int(os.environ.get('TRAJ','300'))
class Plan(C.PlanificationCampagne):
    def _noter(self, semaine):
        n=len(self.previsions)
        C.PlanificationCampagne._noter(self, semaine)
        if len(self.previsions)>n:
            l=self.historique[-1]
            self.previsions[-1]['prevu_jour']=dict(l.get('prevu_jour') or {})
def un(a):
    cle,scen,kind,seed=a
    infos=donnees.catalogue_infos()
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']==scen][0]
    prm=pk.params()
    fab=[lambda pol: Plan(pol, {'trajectoires':TRAJ}, True), ek.fabrique_surveillance(), ek.fabrique_controle_dual(seed), ek.fabrique_adherence(seed)]
    pol=ek.PolitiqueBriques(parametres=prm, extensions=fab)
    essais=[]
    o_t=S.Seances._tentative
    def tent(self,item,index,plan,t):
        r=o_t(self,item,index,plan,t)
        mu,sd=self.m.capacite_du_jour(item['exerciseId'])
        essais.append((self.jour,item['exerciseId'],index,mu,sd,None if r is None else r.get('loadKg'),t.fraction*self.m.poids_kg,item.get('koachCible')))
        return r
    S.Seances._tentative=tent
    try:
        tour=meneur.simuler(s, infos, pol, kind, seed)
    finally:
        S.Seances._tentative=o_t
    prev=[]
    for x in pol.koach.extensions:
        if hasattr(x,'previsions'): prev=x.previsions
    ep=C.epreuves_par_jour(tour)
    fiches=pol.koach.fiches
    rows=[]
    for p in prev:
        E=p.get('echeance')
        if E is None or int(E) not in ep: continue
        obs=ep[int(E)]
        for ex,pe in (p.get('p') or {}).items():
            if ex not in obs: continue
            cib=(p.get('cibles') or {}).get(ex)
            if cib is None: continue
            pj=(p.get('prevu_jour') or {}).get(ex)
            es=[e for e in essais if e[0]==int(E) and e[1]==ex]
            rows.append(dict(cle=cle,scen=scen,kind=kind,seed=seed,ex=ex,type=fiches[ex]['type'],semaine=p['semaine'],sem_E=int(E)//7,
                p=pe,cible=cib,best=obs[ex][0],daymax=obs[ex][1],prevu=pj,essais=[(e[2],e[3],e[4],e[5],e[6]) for e in es],niveau=s['level']))
    return rows
if __name__=='__main__':
    seeds=int(sys.argv[1])
    jobs=[]
    V=pk.vecteurs()
    for cle in donnees.profils():
        for s in donnees.saisons_reference(cle):
            ev=[j for js in s.get('eventDaysByWeek') or [] for j in js]
            if ev and pb.cibles_du_profil(s['profiles'][0]['profile'],V):
                if os.environ.get('SCEN') and s['scenario'] not in os.environ['SCEN'].split(','): continue
                for k in 'abc':
                    for g in range(int(os.environ.get('SEED0','0')),int(os.environ.get('SEED0','0'))+seeds): jobs.append((cle,s['scenario'],k,g))
    print(len(jobs),'saisons',flush=True)
    with Pool(2) as p: res=p.map(un, jobs, chunksize=1)
    rows=[r for x in res for r in x]
    pickle.dump(rows,open(os.environ.get('OUT','tmp_calib.pkl'),'wb'))
    print(len(rows),'prévisions')
