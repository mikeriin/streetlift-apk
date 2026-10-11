import json,sys,os,math
sys.path.insert(0,os.getcwd())
from multiprocessing import get_context
from banc import donnees, meneur, mesures
from banc import criteres_moteur as cm
from banc import politique_koach as pk
from koach import seance as S
from koach.numerique import norm_ppf
def run(job):
    cle,scen,v,g=job
    log=[]
    orig=S.Seances._tentative
    def tent(self,item,index,plan,t):
        out=orig(self,item,index,plan,t)
        if index==0:
            s=self.s; ex=item['exerciseId']; mem=self.mem(ex)
            mu,sd=self.m.capacite_du_jour(ex)
            bw=t.fraction*self.m.poids_kg
            baisse=1.0-s['tentative_bilan_bas_part']*self.palier
            if plan['cond']['zone']: baisse-=s['tentative_bilan_bas_part']
            mu+=math.log(baisse); sd=max(sd,0.01)
            sem=(self.contexte or {}).get('semaine')
            if sem is not None and (self.genres.get(sem) in ('taper','competition') or self.genres.get(sem-1) in ('taper','competition')):
                mu+=self.p['planification']['gain_affutage']
            tot=min(math.exp(mu-norm_ppf(s['tentative_ouverture_proba'])*sd), s['tentative_ouverture_part']*math.exp(mu))
            c_est=plan['grille'].plancher(max(tot-bw,plan['grille'].minimum))
            rec=[(c,r,j) for (j,c,r) in mem.charges_reussies if self.jour-j<=42]
            log.append(dict(day=self.jour,ex=ex,est=math.exp(mu),sd=sd,bw=bw,c_est=c_est,c=out['loadKg'],coup=self.coupure,pal=self.palier,zone=bool(plan['cond']['zone']),sh=plan['sans_hausse'],dern=mem.charge_derniere,rec=rec[-60:],ev=bool((self.contexte or {}).get('jour_evenement'))))
        return out
    S.Seances._tentative=tent
    try:
        saison=cm._saison(cle,scen,None)
        tour=meneur.simuler(saison,donnees.catalogue_infos(),pk.PolitiqueKoach(),v,g)
    finally:
        S.Seances._tentative=orig
    att={}
    for s in tour.sets:
        if s['attempt']:
            att.setdefault((s['simDay'],s['exerciseId']),[]).append((s['loadKg'],s['totalKg'],bool(s['failed'] or s['amount']<1),s['dayMax'],s['flames'],s['eventDay']))
    for l in log:
        l['att']=att.get((l['day'],l['ex']),[])
    return dict(job=job,log=log)
if __name__=='__main__':
    seeds=[int(x) for x in sys.argv[1].split(',')]
    jobs=[]
    for cle in donnees.profils():
        for s in donnees.saisons_reference(cle):
            if not any(s.get('eventDaysByWeek') or []) and not True: continue
            for v in 'abc':
                for g in seeds: jobs.append((cle,s['scenario'],v,g))
    with get_context('fork').Pool(2) as p: res=p.map(run,jobs,chunksize=4)
    json.dump(res,open(sys.argv[2],'w'))
    print(len(jobs),sum(len(r['log']) for r in res))
