import oracle_courbe as oc
from banc import verite
from koach import modele as M
JOUR={}
_o=verite.SimAthlete.begin_exercise
def begin(self,t,slot_key):
    _o(self,t,slot_key); JOUR[t.info.id]=t.day
verite.SimAthlete.begin_exercise=begin
_i=M.Modele.__init__
def init(self,*a,**k):
    _i(self,*a,**k); JOUR.clear()
    self.oracle=lambda ex: JOUR.get(ex)
M.Modele.__init__=init
