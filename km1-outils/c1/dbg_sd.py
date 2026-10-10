import sys,os,json,math
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import donnees, meneur, extensions_koach as ek, politique_koach as pk, campagne as C
for _a in [x for x in os.environ.get('SETP','').split(';') if x]:
    _k,_v=_a.split('=',1); _s,_c=_k.split('.',1); pk.params()[_s][_c]=json.loads(_v)
from koach import modele as M
cle,sc,kind,g,ex=sys.argv[1:6]; g=int(g)
s=[x for x in donnees.saisons_reference(cle) if x['scenario']==sc][0]
fab=[lambda pol: C.PlanificationCampagne(pol, {'trajectoires':200}, True), ek.fabrique_surveillance(), ek.fabrique_controle_dual(g), ek.fabrique_adherence(g)]
pol=ek.PolitiqueBriques(parametres=pk.params(), extensions=fab)
log=[]
of=M.Modele.fin_seance; oe=M.Modele.elargir
def fin(self):
    w=self.poids_mauvais_jour(); r=of(self)
    c=self.capacite(ex) if ex in self.pistes and self.pistes[ex] else None
    log.append((self.jour,'w=%.2f'%w,'sd=%.3f'%c[1] if c else ''))
    return r
def el(self,f):
    log.append((self.jour,'ELARGIR',f)); return oe(self,f)
M.Modele.fin_seance=fin; M.Modele.elargir=el
meneur.simuler(s, donnees.catalogue_infos(), pol, kind, g)
print(log)
