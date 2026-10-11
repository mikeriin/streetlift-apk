import json,sys,os,math
sys.path.insert(0,os.getcwd()); sys.path.insert(0,'/tmp/k')
from multiprocessing import get_context
from banc import adversaire as A, mesures
from koach import seance as S
from koach.numerique import norm_ppf
import openers as O
D='../../kalis_bench/docs/data/km2/'
def run(arg):
    adv,seed=arg
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
            rec=[(c,r,j) for (j,c,r) in mem.charges_reussies if self.jour-j<=42]
            log.append(dict(day=self.jour,ex=ex,est=math.exp(mu),sd=sd,bw=bw,c=out['loadKg'],coup=self.coupure,pal=self.palier,zone=bool(plan['cond']['zone']),rec=rec[-40:],pas=plan['grille'].pas if hasattr(plan['grille'],'pas') else None,ev=bool((self.contexte or {}).get('jour_evenement')),seances=t.seances))
        return out
    S.Seances._tentative=tent
    try: tour=A.rejouer(adv,seed)
    finally: S.Seances._tentative=orig
    att={}
    for s in tour.sets:
        if s['attempt']:
            att.setdefault((s['simDay'],s['exerciseId']),[]).append((s['loadKg'],s['totalKg'],bool(s['failed'] or s['amount']<1),s['dayMax'],s['flames'],s['eventDay']))
    for l in log: l['att']=att.get((l['day'],l['ex']),[])
    return dict(job=(adv['id'],seed),log=log)
if __name__=='__main__':
    jobs=[];vus=set()
    for nom in sys.argv[2:]:
        f=D+'adversaires_%s.json'%nom if not nom.endswith('.json') else nom
        for a in A.lire_adversaires(f):
            if a['id'] in vus: continue
            vus.add(a['id'])
            for s in a['seeds']: jobs.append((a,s))
    with get_context('fork').Pool(2) as p: res=p.map(run,jobs,chunksize=2)
    json.dump(res,open(sys.argv[1],'w'))
    print(len(jobs),sum(len(r['log']) for r in res))
