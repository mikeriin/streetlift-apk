import sys, math
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import donnees, meneur
from banc.politique_koach import PolitiqueKoach
from koach import modele as M
cle,kind,seed,ex=sys.argv[1],sys.argv[2],int(sys.argv[3]),sys.argv[4]; nmax=int(sys.argv[5]) if len(sys.argv)>5 else 40
class P(PolitiqueKoach):
    def _verser(self, done):
        while self.vus < len(done):
            rec = done[self.vus]; self.vus += 1
            s = self._serie(rec)
            if s is None: continue
            m=self.koach.modele
            if rec['exerciseId']==ex:
                t=m.piste(ex)
                c0=m.capacite(ex); cj0=m.capacite_du_jour(ex)
                pr=self.koach.seances.reps_prevues(ex, rec.get('externalLoadKg'), 0.0)
                ds0=m.m[M.DS]; de0=m.m[M.DE]
                self.koach.observe({'type': 'serie', 'serie': s})
                c1=m.capacite(ex); cj1=m.capacite_du_jour(ex)
                self.log.append((self.ctx.sim_day, rec['setIndex'], rec.get('externalLoadKg'), rec.get('reps'), rec.get('flames'), rec.get('failed'), pr, math.exp(c0[0]), math.exp(c1[0]), c1[1], math.exp(cj0[0]), math.exp(cj1[0]), ds0, m.m[M.DS], m.m[M.DE], m.m[M.LAM], m.m[t.idx+1], m.m[M.FI], m.m[M.BA], m.poids_mauvais_jour()))
            else:
                self.koach.observe({'type': 'serie', 'serie': s})
infos=donnees.catalogue_infos()
s=[x for x in donnees.saisons_reference(cle) if x['scenario']=='reference'][0]
pol=P(); pol.log=[]
tour=meneur.simuler(s, infos, pol, kind, seed)
tr={(x['simDay'],x['setIndex'],x['loadKg'],x['amount']):x for x in tour.sets if x['exerciseId']==ex}
for l in pol.log[:nmax]:
    x=tr.get((l[0],l[1],l[2],l[3]))
    print('d%d s%d %s x%s fl=%s%s | prévu R=%.1f (rés %.1f) vrai rés %s | cap %.1f→%.1f (sd %.3f) vraie %.1f | jour %.1f→%.1f vrai %.1f | DS %+.3f→%+.3f DE %+.3f | lam %.2f k %.2f FI %.2f BA %.2f mauvais %.2f'%(l[0],l[1],l[2],l[3],l[4],' ECHEC' if l[5] else '',l[6],l[6]-l[3], '%.1f'%x['trueRir'] if x else '?', l[7],l[8],l[9], x['capacity'] if x else 0, l[10],l[11], x['dayMax'] if x and x['dayMax'] else 0, l[12],l[13],l[14],l[15],l[16],l[17],l[18],l[19]))
