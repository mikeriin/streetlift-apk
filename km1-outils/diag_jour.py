# décompose l'erreur : offset vrai du jour (ln dayMax/capacity) vs offset prédit par Koach, par rang de série
import sys, collections, statistics, math
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur
from banc.politique_koach import PolitiqueKoach
class P(PolitiqueKoach):
    def prochaine_serie(self, ctx, item, index, done):
        r=super().prochaine_serie(ctx,item,index,done)
        m=self.koach.modele; ex=item['exerciseId']; t=m.pistes.get(ex)
        if t is not None and t.type=='charge':
            c=m.capacite(ex); cj=m.capacite_du_jour(ex)
            self.notes[(ctx.sim_day,item['slotId'],index)]=(c[0],c[1],cj[0],cj[1],m._intra(t),float(m.m[22]),m.f_nerveux,m.fatigue_de(t)[1])
        return r
def un(a):
    cle,kind,seed=a
    infos=donnees.catalogue_infos()
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']=='reference'][0]
    pol=P(); pol.notes={}
    tour=meneur.simuler(s, infos, pol, kind, seed)
    out=[]
    for x in tour.sets:
        if x['mode']!='loaded' or not x['main']: continue
        n=pol.notes.get((x['simDay'],x['slotId'],x['setIndex']))
        if n is None or not x['dayMax']: continue
        out.append((kind,x['exerciseSession'],x['setIndex'],math.log(x['dayMax']/x['capacity']), n[2]-n[0], n[0]-math.log(x['capacity']), n[2]-math.log(x['dayMax']), x['trueRir'],x['wantRir'],x['test'],n[4],n[5],n[6],n[7],x['failed']))
    return out
if __name__=='__main__':
    cles=sys.argv[1].split(','); seeds=int(sys.argv[2])
    jobs=[(c,k,s) for c in cles for k in 'abc' for s in range(seeds)]
    with Pool(2) as p: res=p.map(un, jobs)
    rows=[r for x in res for r in x]
    for kind in 'abc':
        R=[r for r in rows if r[0]==kind and r[2]==0 and not r[9]]
        for lo,hi in ((1,2),(3,5),(6,9),(10,20),(21,99)):
            S=[r for r in R if lo<=r[1]<=hi]
            if not S: continue
            f=lambda i: statistics.mean(r[i] for r in S)
            print(kind,'rang %d-%d n=%d  jour vrai %+.4f  jour prédit %+.4f  err cap fraîche %+.4f  err cap du jour %+.4f (abs %.4f) rir vrai %.2f voulu %.2f  fn %.1f fm %.1f echecs %.3f'%(lo,hi,len(S),f(3),f(4),f(5),f(6),statistics.mean(abs(r[6]) for r in S),f(7),f(8),f(12),f(13),f(14)))
