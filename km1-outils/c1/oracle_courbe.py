# Oracle : la courbe charge-répétitions vraie de chaque exercice est donnée au modèle (borne de ce que la courbe coûte)
import sys, math
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import meneur
from koach import modele as M
ATH={}
orig=meneur.SimAthlete
class A(orig):
    def __init__(self,*a,**k):
        super().__init__(*a,**k); ATH['a']=self
meneur.SimAthlete=A
class Tr(object):
    def __init__(s,tr): s.tr=tr
    def __rsub__(s,o): return 0.0
def courbe(self,t,m=None):
    tr=ATH['a'].truth_of(t.id) if t.type=='charge' else None
    if tr is None: return 0.0,0.0
    return Tr(tr),0.0
og=M.Modele._g; odg=M.Modele._dg
def g(lam,k,reps):
    if isinstance(lam,Tr):
        r=1.0 if reps<1 else reps
        return -math.log(lam.tr.share(r))
    return og(lam,k,reps)
def dg(lam,k,reps):
    if isinstance(lam,Tr):
        r=1.0 if reps<1 else reps
        d=(g(lam,k,r+0.01)-g(lam,k,r))/0.01
        return d if d>0.004 else 0.004
    return odg(lam,k,reps)
M.Modele.courbe=courbe; M.Modele._g=staticmethod(g); M.Modele._dg=staticmethod(dg)
orr=M.Modele._reps_de
def reps_de(lam,k,x):
    if isinstance(lam,Tr):
        r=lam.tr.reps_at_share(math.exp(-x))
        return 200.0 if r>200 else (1.0 if r<1 else r)
    return orr(lam,k,x)
odf=M.Modele._dg_forme
def dgf(lam,k,reps):
    if isinstance(lam,Tr): return 0.0
    return odf(lam,k,reps)
M.Modele._reps_de=staticmethod(reps_de); M.Modele._dg_forme=staticmethod(dgf)
