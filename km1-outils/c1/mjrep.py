# fréquence de « N mauvais jours de suite » (poids >= seuil) : fausses alertes sur référence, détection en maladie
import sys
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur
from banc.politique_koach import PolitiqueKoach
def un(a):
    cle,sc,kind,seed=a
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']==sc]
    if not s: return None
    s=s[0]; pol=PolitiqueKoach()
    meneur.simuler(s, donnees.catalogue_infos(), pol, kind, seed)
    h=pol.koach.modele.histoire_residus
    return (sc,[(x[0],x[4]) for x in h], s['specJson'].get('illnessFromDay'), s['specJson'].get('illnessDays'))
if __name__=='__main__':
    jobs=[(c,sc,k,g) for c in donnees.profils() for sc in ('reference','maladie') for k in 'abc' for g in range(2)]
    with Pool(2) as p: res=[r for r in p.map(un,jobs,chunksize=2) if r]
    for N in (2,3,4):
        for seuil in (0.5,0.7):
            for sc in ('reference','maladie'):
                nse=0;nal=0;sais=0;det=0;nm=0
                for (s,h,f,d) in res:
                    if s!=sc: continue
                    sais+=1; run=0; al=False; detecte=False
                    for (j,w) in h:
                        nse+=1
                        run=run+1 if w>=seuil else 0
                        if run==N:
                            nal+=1
                            if f is not None and f<=j<f+d+7: detecte=True
                    if f is not None: nm+=1; det+=detecte
                print('N=%d seuil %.1f %s : %d alertes / %d séances (%.2f pour 100), %d saisons%s'%(N,seuil,sc,nal,nse,100*nal/max(1,nse),sais,' ; maladie détectée %d/%d'%(det,nm) if sc=='maladie' else ''))
