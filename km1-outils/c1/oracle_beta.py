import oracle_courbe as oc
from koach import modele as M
_i=M.Modele.__init__
def init(self,*a,**k):
    _i(self,*a,**k)
    self.m[M.BP]=oc.ATH['a'].beta; self.P[M.BP,M.BP]=0.0
M.Modele.__init__=init
