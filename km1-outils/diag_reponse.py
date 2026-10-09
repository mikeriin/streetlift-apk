# réponse à l'entraînement : gain vrai hebdomadaire (vérité) vs doses et fatigue vues par Koach
import sys, collections, statistics, math, json
import numpy as np
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur, verite
from banc.politique_koach import PolitiqueKoach
W=[]
_e=verite.SimAthlete.end_week
def ew(self):
    avant={t.info.id:t.capacity for t in self.truths}
    ch=self._chronic
    _e(self)
    W.append((self._weeks-1, ch, {t.info.id:(math.log(t.capacity/avant[t.info.id]), t.mode) for t in self.truths if t.info.id in avant}))
verite.SimAthlete.end_week=ew
def un(a):
    cle,kind,seed=a
    W.clear()
    infos=donnees.catalogue_infos()
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']=='reference'][0]
    pol=PolitiqueKoach()
    tour=meneur.simuler(s, infos, pol, kind, seed)
    js=pol.koach.modele.journal_semaines
    out=[]
    for (w,ch,gains) in W:
        if w>=len(js): continue
        l=js[w]
        for ex,(g,mode) in gains.items():
            d=l['doses'].get(ex)
            if d is None or d[0]<=0: continue
            out.append((kind,s['level'],mode,w,g,d[0],d[1],d[2],l['fatigue_lente'],ch))
    return out
if __name__=='__main__':
    cles=donnees.profils() if sys.argv[1]=='tous' else sys.argv[1].split(','); seeds=int(sys.argv[2])
    jobs=[(c,k,s) for c in cles for k in 'abc' for s in range(1,1+seeds)]
    with Pool(2) as p: res=p.map(un, jobs, chunksize=2)
    rows=[r for x in res for r in x]
    json.dump(rows, open('/tmp/reponse.json','w'))
    print('lignes',len(rows))
    for kind in 'abc':
        for lv in range(4):
            R=[r for r in rows if r[0]==kind and r[1]==lv and r[2]=='loaded']
            if R: print(kind,'niveau',lv,'n=%d gain moyen %.5f | vol %.1f eff %.1f int %.1f | fatigue lente Koach %.1f chronique vraie %.1f (corr %.2f)'%(len(R),statistics.mean(r[4] for r in R),statistics.mean(r[5] for r in R),statistics.mean(r[6] for r in R),statistics.mean(r[7] for r in R),statistics.mean(r[8] for r in R),statistics.mean(r[9] for r in R),np.corrcoef([r[8] for r in R],[r[9] for r in R])[0,1]))
