import json,sys,os,math
sys.path.insert(0,os.getcwd())
from multiprocessing import get_context
from banc import adversaire as A, mesures
from koach import seance as S
D='../../kalis_bench/docs/data/km2/'
def charge(nom):
    advs={a['id']:a for a in A.lire_adversaires(D+'adversaires_%s.json'%nom)}
    comp=json.load(open(D+'comparaison_adversaires_%s.json'%nom))['adversaires']
    return advs,comp
def run(arg):
    adv,seed=arg
    log=[]
    orig=S.Seances._tentative
    def tent(self,item,index,plan,t):
        out=orig(self,item,index,plan,t)
        ex=item['exerciseId']; mem=self.mem(ex)
        mu,sd=self.m.capacite_du_jour(ex)
        bw=t.fraction*self.m.poids_kg
        log.append(dict(day=self.jour,ex=ex[3:22],idx=index,est=round(math.exp(mu)-bw,1),sd=round(sd,3),coup=self.coupure,pal=self.palier,zone=plan['cond']['zone'],rais=plan['cond']['raison'],sh=plan['sans_hausse'],dern=mem.charge_derniere,out=out['loadKg'],ech=mem.echec))
        return out
    S.Seances._tentative=tent
    try:
        tour=A.rejouer(adv,seed)
    finally:
        S.Seances._tentative=orig
    evs=mesures.evenements(tour)
    att=[(s['simDay'],s['exerciseId'][3:22],s['loadKg'],s['failed'],round(s['dayMax'],1),s['flames']) for s in tour.sets if s['attempt']]
    return dict(id=adv['id'],seed=seed,evs=[(e[0][3:22],e[2],round(e[4],1),round(e[2]/e[4],3) if e[4] else None) for e in evs],att=att,log=log)
if __name__=='__main__':
    nom=sys.argv[1]
    advs,comp=charge(nom)
    jobs=[];meta={}
    for c in comp:
        k=c['koach'].get('perf_a');t=c['temoin'].get('perf_a')
        if k is None or t is None or t<=0: continue
        if k-t>=-0.03: continue
        meta[c['id']]=(c['key'][:10],c['kind'],k,t)
        for s in advs[c['id']]['seeds'][:2]: jobs.append((advs[c['id']],s))
    with get_context('fork').Pool(2) as p: res=p.map(run,jobs,chunksize=1)
    json.dump(dict(meta=meta,res=res),open('/tmp/k/diag_%s.json'%nom,'w'))
    for r in res:
        a=advs[r['id']]
        sp=a['spec']
        print('==',r['id'],r['seed'],meta[r['id']],'ech',a['echeances'],{k:sp[k] for k in sp if k in('breakDays','breakFromDay','painDays','painFromDay','painIntensity','painZone','illnessDays','illnessFromDay','ratingNoise','rirBias','missRate')})
        print('   evs',r['evs'])
        for l in r['log']:
            print('   ',l)
        print('   att',r['att'])
