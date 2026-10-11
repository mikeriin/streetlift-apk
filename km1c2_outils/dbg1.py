import json,sys,os,math
sys.path.insert(0,os.getcwd())
from banc import adversaire as A, mesures
from koach import seance as S
advs=A.lire_adversaires('../../kalis_bench/docs/data/km2/adversaires_km2_b3000.json')
adv=[a for a in advs if a['id']=='adv-31c45cfb'][0]
orig=S.Seances._tentative
def tent(self,item,index,plan,t):
    out=orig(self,item,index,plan,t)
    ex=item['exerciseId']; mem=self.mem(ex)
    mu,sd=self.m.capacite_du_jour(ex)
    print('TENT day',self.jour,ex[3:20],'idx',index,'mu',round(math.exp(mu),1),'sd',round(sd,3),'coupure',self.coupure,'palier',self.palier,'cond',plan['cond']['zone'],plan['cond']['raison'],'sans_hausse',plan['sans_hausse'],'derniere',mem.charge_derniere,'seance',mem.charge_seance,'echecs',plan['echecs'],'sets',item.get('sets'),'->',out['loadKg'], 'p(next)',self.proba_reussite(ex,(mem.charge_seance or 0)+2.5,1), 'lam,k',self.m.courbe(t), [(j,c,r) for (j,c,r) in mem.charges_reussies if self.jour-j<=42][-6:])
    return out
S.Seances._tentative=tent
tour=A.rejouer(adv,0)
