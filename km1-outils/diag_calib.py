# calibration des notes : P(ouverte) prédit vs observé, écart moyen des notes fermées, par classe de prévision
import sys, collections, statistics, math
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur
from banc.politique_koach import PolitiqueKoach
from koach.numerique import norm_cdf
def un(a):
    cle,kind,seed=a
    infos=donnees.catalogue_infos()
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']=='reference'][0]
    pol=PolitiqueKoach()
    class Q(PolitiqueKoach):
        def debut(self, saison, profil, livre):
            super().debut(saison, profil, livre); self.koach.modele.sonde=[]
    pol=Q()
    tour=meneur.simuler(s, infos, pol, kind, seed)
    return [(kind,)+x for x in pol.koach.modele.sonde]
if __name__=='__main__':
    cles=sys.argv[1].split(','); seeds=int(sys.argv[2])
    jobs=[(c,k,s) for c in cles for k in 'abc' for s in range(seeds)]
    with Pool(2) as p: res=p.map(un, jobs)
    rows=[r for x in res for r in x if r[12]>=3]
    INF=math.inf
    for typ in ('charge','reps'):
      for kind in 'abc':
        print(typ,kind)
        for lo,hi in ((-9,1),(1,2),(2,3),(3,4),(4,5.5),(5.5,8),(8,12),(12,999)):
            S=[r for r in rows if r[0]==kind and r[2]==typ and lo<=r[3]<hi and r[6]!=-INF]
            if len(S)<20: continue
            po=statistics.mean(1-norm_cdf((3.75-r[3])/math.sqrt(r[4]+r[5])) for r in S)
            oo=statistics.mean(1.0 if r[7]==INF else 0.0 for r in S)
            F=[r for r in S if r[7]!=INF]
            d=[(0.5*(r[6]+r[7]) if r[6]>0 else 0.0)-r[3] for r in F]
            z=[x/math.sqrt(r[4]+r[5]) for x,r in zip(d,F)]
            print('  prévu p[%g,%g) n=%d  P(ouverte) prédit %.2f observé %.2f | fermées n=%d: note−prévu %+.2f, z moy %+.2f sd %.2f | sd état %.2f bruit %.2f'%(lo,hi,len(S),po,oo,len(F),statistics.mean(d) if d else 0,statistics.mean(z) if z else 0,statistics.pstdev(z) if z else 0,statistics.mean(math.sqrt(r[4]) for r in S),statistics.mean(math.sqrt(r[5]) for r in S)))
