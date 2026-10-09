# expérience : Koach avec l'effet de jour VRAI imposé (borne de ce que l'inférence du jour peut gagner)
import sys, statistics
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur, mesures, verite
from banc.politique_koach import PolitiqueKoach
JOUR={}
_orig=verite.SimAthlete.begin_exercise
def begin(self, t, slot_key):
    _orig(self, t, slot_key); JOUR[t.info.id]=t.day
verite.SimAthlete.begin_exercise=begin
class Q(PolitiqueKoach):
    def debut(self, saison, profil, livre):
        super().debut(saison, profil, livre)
        self.koach.modele.oracle=lambda ex: JOUR.get(ex)
def un(a):
    cle,kind,seed=a
    JOUR.clear()
    infos=donnees.catalogue_infos()
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']=='reference'][0]
    tour=meneur.simuler(s, infos, Q(), kind, seed)
    E=mesures.Estimations(); E.add(tour, lambda e:e['mode']=='loaded' and e['main'])
    return kind,E.rows
if __name__=='__main__':
    cles=sys.argv[1].split(','); seeds=int(sys.argv[2])
    jobs=[(c,k,s) for c in cles for k in 'abc' for s in range(seeds)]
    with Pool(2) as p: res=p.map(un, jobs)
    for kind in 'abc':
        E=mesures.Estimations()
        for k,rows in res:
            if k!=kind: continue
            for i in range(len(rows)):
                for c in range(7): E.rows[i][c]+=rows[i][c]
        for k in (3,6,12):
            l=E.ligne(k); print(kind,'k=%d MAE=%.4f biais=%+.4f couv=%.3f sd=%.4f'%(k,l['mae'],l['biais'],l['couverture'],l['sd']))
