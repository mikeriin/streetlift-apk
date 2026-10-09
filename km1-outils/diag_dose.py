import sys, collections, statistics
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import donnees, meneur, verite
from banc.politique_koach import PolitiqueKoach
W=[]
_e=verite.SimAthlete.end_week
def ew(self):
    over=(self._chronic-14 if self._chronic>14 else 0)/14
    W.append((self._weeks, self._chronic, max(0.2,1-0.5*over), {t.info.id:t.stimulus for t in self.truths if t.stimulus>0}))
    _e(self)
verite.SimAthlete.end_week=ew
infos=donnees.catalogue_infos()
for cle in sys.argv[1].split(','):
    for kind in 'a':
        W.clear()
        s=[x for x in donnees.saisons_reference(cle) if x['scenario']=='reference'][0]
        tour=meneur.simuler(s, infos, PolitiqueKoach(), kind, 1)
        mains=set(x['exerciseId'] for x in tour.sets if x['main'])
        ch=[w[1] for w in W]; kp=[w[2] for w in W]
        st=collections.defaultdict(list)
        for w in W:
            for ex in mains: st[ex].append(w[3].get(ex,0.0))
        print(cle[:30],'chronique fin de semaine: moy %.1f min %.1f max %.1f | keep moy %.2f min %.2f | stimulus/sem principaux:'%(statistics.mean(ch),min(ch),max(ch),statistics.mean(kp),min(kp)), {ex[:22]:round(statistics.mean(v),1) for ex,v in st.items()}, 'gain', {k[:18]:round(v*100,3) for k,v in list(tour.gain.items())[:3]})
