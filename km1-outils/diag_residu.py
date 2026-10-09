import sys, statistics, collections
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur
from banc.politique_koach import PolitiqueKoach
def un(a):
    cle,scen,kind,seed=a
    infos=donnees.catalogue_infos()
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']==scen][0]
    pol=PolitiqueKoach(); tour=meneur.simuler(s, infos, pol, kind, seed)
    h=pol.koach.modele.histoire_residus
    par=collections.defaultdict(list)
    for r in h:
        if r[5] is not None: par[r[0]//7].append(r[5])
    sem={w:sum(v)/len(v) for w,v in par.items()}
    sp=s['specJson']; deb=sp.get('illnessFromDay')
    return scen, sem, (deb//7 if deb is not None else None), s['weeks']
if __name__=='__main__':
    cles=sys.argv[1].split(',') if sys.argv[1]!='tous' else donnees.profils()
    jobs=[(c,sc,k,sd) for c in cles for sc in ('reference','maladie') for k in 'abc' for sd in (1,2) if any(x['scenario']==sc for x in donnees.saisons_reference(c))]
    with Pool(2) as p: res=p.map(un, jobs, chunksize=4)
    for scen in ('reference','maladie'):
        R=[r for r in res if r[0]==scen and r[1]]
        vals=sorted(abs(v) for r in R for v in r[1].values())
        q=lambda p:vals[int(p*(len(vals)-1))]
        print(scen,'saisons',len(R),'|résidu hebdo| médiane %.4f q90 %.4f q99 %.4f'%(q(.5),q(.9),q(.99)))
        for seuil in (0.03,0.04,0.05):
            act=0; tot=0; alertes=0; det=0
            for r in R:
                sem=r[1]; ws=sorted(sem); prev=False; a=0; d=False
                for w in ws:
                    cur=abs(sem[w])>seuil
                    two=cur and (w-1 in sem and abs(sem[w-1])>seuil)
                    tot+=1; act+=two
                    if two: a+=1
                    if two and r[2] is not None and r[2]<=w<=r[2]+3: d=True
                alertes+= 1 if a else 0; det+=d
            print('   seuil %.2f : semaines actives %.4f, saisons avec alerte %.3f, détection (maladie, ≤3 sem) %.3f'%(seuil,act/tot,alertes/len(R),det/len(R)))
        if scen=='maladie':
            # résidu la semaine de la maladie
            v=[r[1].get(r[2]) for r in R if r[2] in r[1]]; v2=[r[1].get(r[2]+1) for r in R if r[2]+1 in r[1]]
            print('   résidu semaine de maladie: moy %+.4f ; semaine suivante %+.4f'%(statistics.mean(v),statistics.mean(v2) if v2 else 0))
