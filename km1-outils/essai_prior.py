import sys, copy, json, collections
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import donnees, meneur, mesures
from banc.politique_koach import PolitiqueKoach, params
infos=donnees.catalogue_infos()
cle=sys.argv[1]; kind=sys.argv[2]; seed=int(sys.argv[3]); over=json.loads(sys.argv[4]) if len(sys.argv)>4 else {}
p=copy.deepcopy(params())
for k,v in over.items():
    sec,key=k.split('.')
    p[sec][key]=v
s=[x for x in donnees.saisons_reference(cle) if x['scenario']=='reference'][0]
pol=PolitiqueKoach(parametres=p)
tour=meneur.simuler(s, infos, pol, kind, seed)
E=mesures.Estimations(); E.add(tour, lambda e:e['mode']=='loaded' and e['main'])
E2=mesures.Estimations(); E2.add(tour, lambda e:e['mode']=='loaded')
for nm,e in (('main',E),('loaded',E2)):
    print(nm, ' '.join('k%d:%.3f/%+.3f'%(k,e.ligne(k)['mae'],e.ligne(k)['biais']) for k in (1,3,6,12,20) if e.ligne(k)))
po=pol.koach.posterior()
print({k:(round(float(v),3) if not isinstance(v,list) else [round(float(x),3) for x in v]) for k,v in po.items() if k in ('biais_rir','bruit_rir','courbe','fatigue_intra','note_paresseuse')})
m=pol.koach.modele
import math
print('ke', {ex:round(float(m.m[m.pistes[ex].idx+1]),2) for ex in m.ordre if m.pistes[ex].type=='charge'})
