# réserve vraie (vérité) vs réserve prédite par Koach AVANT la série ; biais par classe
import sys, collections, statistics, math
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur
from banc.politique_koach import PolitiqueKoach
class P(PolitiqueKoach):
    def _verser(self, done):
        while self.vus < len(done):
            rec = done[self.vus]
            self.vus += 1
            s = self._serie(rec)
            if s is None: continue
            m=self.koach.modele; ex=rec['exerciseId']; t=m.piste(ex)
            if t is not None and t.type in ('charge','reps') and (rec.get('reps') or 0)>0 and not rec.get('enduranceKind'):
                if self.koach.modele._dernier_ex != ex:
                    # l'effet d'exercice n'est pas encore remis : prédiction équivalente
                    pass
                pr=self.koach.seances.reps_prevues(ex, rec.get('externalLoadKg') if t.type=='charge' else None, 0.0)
                if pr is not None:
                    self.preds[(self.ctx.sim_day, rec['slotId'], rec['setIndex'])]=(pr-rec['reps'], t.seances, t.type, pr)
            self.koach.observe({'type': 'serie', 'serie': s})
def un(a):
    cle,kind,seed=a
    infos=donnees.catalogue_infos()
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']=='reference'][0]
    pol=P(); pol.preds={}
    tour=meneur.simuler(s, infos, pol, kind, seed)
    out=[]
    for x in tour.sets:
        p=pol.preds.get((x['simDay'],x['slotId'],x['setIndex']))
        if p is None or x['failed']: continue
        fl=x['flames']; said=None if fl is None else (0.0 if fl>=10 else (11-fl)/2.0)
        out.append((kind,p[2],x['setIndex'],x['trueRir'],p[0],said,p[1],x['amount'],x['main'],x['test']))
    return out
if __name__=='__main__':
    cles=donnees.profils() if sys.argv[1]=='tous' else sys.argv[1].split(','); seeds=int(sys.argv[2])
    jobs=[(c,k,s) for c in cles for k in 'abc' for s in range(seeds)]
    with Pool(2) as p: res=p.map(un, jobs)
    rows=[r for x in res for r in x if r[6]>=4]
    for typ in ('charge','reps'):
      for kind in 'abc':
        print(typ,kind)
        for si in (0,1,2,3):
            line='  série %d:'%si
            for lo,hi in ((0,1.5),(1.5,3),(3,5),(5,8),(8,14),(14,99)):
                S=[r for r in rows if r[0]==kind and r[1]==typ and (r[2]==si if si<3 else r[2]>=3) and lo<=r[3]<hi]
                if len(S)<8: line+='  [%g-%g) n=%d'%(lo,hi,len(S)); continue
                d=[r[4]-r[3] for r in S]
                line+='  [%g-%g) n=%d préd−vrai %+.2f (sd %.2f)'%(lo,hi,len(S),statistics.median(d),statistics.pstdev([min(max(x,-10),10) for x in d]))
            print(line)
        # par nombre de reps faites (séries 0, réserve vraie < 5)
        line='  par reps (série 0, vrai<5):'
        for lo,hi in ((1,2),(2,4),(4,7),(7,11),(11,99)):
            S=[r for r in rows if r[0]==kind and r[1]==typ and r[2]==0 and r[3]<5 and lo<=r[7]<hi]
            if len(S)<8: continue
            d=[r[4]-r[3] for r in S]
            line+='  reps[%d-%d) n=%d %+.2f (sd %.2f)'%(lo,hi,len(S),statistics.median(d),statistics.pstdev([min(max(x,-10),10) for x in d]))
        print(line)
