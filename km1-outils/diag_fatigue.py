# régression de l'effet de jour vrai (ln dayMax/capacity) sur les régresseurs de fatigue de Koach
import sys, collections, statistics, math
import numpy as np
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur
from banc.politique_koach import PolitiqueKoach
class P(PolitiqueKoach):
    def prochaine_serie(self, ctx, item, index, done):
        r=super().prochaine_serie(ctx,item,index,done)
        m=self.koach.modele; ex=item['exerciseId']; t=m.pistes.get(ex)
        if t is not None and index==0:
            self.notes[(ctx.sim_day,item['slotId'])]=m.fatigue_de(t)
        return r
def un(a):
    cle,kind,seed=a
    infos=donnees.catalogue_infos()
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']=='reference'][0]
    pol=P(); pol.notes={}
    tour=meneur.simuler(s, infos, pol, kind, seed)
    out=[]
    for x in tour.sets:
        if x['setIndex']!=0 or x['mode'] not in ('loaded','reps','hold') or not x['dayMax']: continue
        n=pol.notes.get((x['simDay'],x['slotId']))
        if n is None: continue
        cap=x['capacity']
        y=math.log(x['dayMax']/cap)
        out.append((kind,x['mode'],y)+tuple(n))
    return out
if __name__=='__main__':
    cles=donnees.profils() if sys.argv[1]=='tous' else sys.argv[1].split(','); seeds=int(sys.argv[2])
    jobs=[(c,k,s) for c in cles for k in 'abc' for s in range(seeds)]
    with Pool(2) as p: res=p.map(un, jobs)
    rows=[r for x in res for r in x]
    for kinds in ('a','b','c','abc'):
        for mode in ('loaded','reps','hold','all'):
            R=[r for r in rows if r[0] in kinds and (mode=='all' or r[1]==mode)]
            if len(R)<50: continue
            y=np.array([r[2] for r in R]); X=np.array([r[3:7] for r in R])
            X1=np.column_stack([X,np.ones(len(R))])
            b,res_,_,_=np.linalg.lstsq(X1,y,rcond=None)
            pred=X1@b
            # sans constante
            b0,_,_,_=np.linalg.lstsq(X,y,rcond=None)
            print(kinds,mode,'n=%d y moy %+.4f sd %.4f | coef (gn,ln,gm,lm,c) %s resid sd %.4f | sans const %s resid %.4f | moy X %s'%(len(R),y.mean(),y.std(),np.round(b,5),(y-pred).std(),np.round(b0,5),(y-X@b0).std(),np.round(X.mean(0),2)))
