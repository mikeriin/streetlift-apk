# Oracle de FORME : la forme (par athlète) et l'échelle moyenne sont données ; l'échelle par exercice reste à apprendre
import sys
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import meneur
from koach import modele as M
ATH={}
orig=meneur.SimAthlete
class A(orig):
    def __init__(self,*a,**k):
        super().__init__(*a,**k); ATH['a']=self
meneur.SimAthlete=A
F={'a':(0.11,0.105),'b':(-0.28,0.14),'c':(1.0,0.115)}
_i=M.Modele.__init__
def init(self,*a,**k):
    _i(self,*a,**k)
    lam,ku=F[ATH['a'].kind]
    self.m[M.LAM]=lam; self.P[M.LAM,M.LAM]=0.0; self.m[M.KU]=ku
M.Modele.__init__=init
