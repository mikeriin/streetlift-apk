import sys, collections
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur, verite
from banc.politique_koach import PolitiqueKoach
LOG=[]
_p=verite.SimAthlete.perform
def perform(self, t, load, low, high, flames_target, rest_seconds, noise_key):
    a0=self.pain_aggravations
    last=t.last_load; before=t.session_load
    out=_p(self, t, load, low, high, flames_target, rest_seconds, noise_key)
    if self.pain_aggravations>a0: LOG.append(('AGGR', self._day, t.info.id, load, last, self.pain_intensity, self.pain_zone, noise_key))
    return out
verite.SimAthlete.perform=perform
_r=verite.SimAthlete._reactive_week
def rw(self):
    f0=self.pain_flares; zw=dict(self._zone_week); tol=self._reactive_tolerance; z=self._reactive_zone; hab=dict(self._zone_habit); lw=dict(self._zone_last_week)
    _r(self)
    if self.pain_flares>f0: LOG.append(('FLARE', self._day, z, zw.get(z), tol, hab.get(z), lw.get(z)))
verite.SimAthlete._reactive_week=rw
def un(a):
    cle,scen,kind,seed=a
    LOG.clear()
    infos=donnees.catalogue_infos()
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']==scen][0]
    tour=meneur.simuler(s, infos, PolitiqueKoach(), kind, seed)
    return [(cle,scen,kind)+tuple(l) for l in LOG]
if __name__=='__main__':
    jobs=[(c,sc,k,0) for c in donnees.profils() for sc in ('douleur_coude','douleur_epaule') for k in 'abc' if any(x['scenario']==sc for x in donnees.saisons_reference(c))]
    with Pool(2) as p: res=p.map(un, jobs, chunksize=4)
    rows=[r for x in res for r in x]
    for r in rows:
        if r[3]=='AGGR': print(r)
    fl=[r for r in rows if r[3]=='FLARE']
    print('flares',len(fl)); c=collections.Counter((r[0][:20],r[1]) for r in fl)
    for k,v in c.most_common(12): print(k,v)
    for r in fl[:12]: print(r)
