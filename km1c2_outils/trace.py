import json,sys,os
sys.path.insert(0,os.getcwd())
from banc import adversaire as A, mesures
f=sys.argv[1]; aid=sys.argv[2]; seed=int(sys.argv[3]); exf=sys.argv[4] if len(sys.argv)>4 else None
advs=A.lire_adversaires(f)
adv=[a for a in advs if a['id']==aid][0]
print(json.dumps({k:adv[k] for k in ('key','kind','spec','surcharges','echeances','seeds')},indent=0)[:3000])
tour=A.rejouer(adv,seed)
print('events',mesures.evenements(tour))
print(tour.sets[0].keys())
last=None
for s in tour.sets:
    if exf and exf not in s['exerciseId']: continue
    if s['simDay']!=last: print('--- day',s['simDay'],'wk',s['week'],s['weekKind']); last=s['simDay']
    print(' ',s['exerciseId'][3:22], s['role'] or '', 'T' if s['test'] else '', 'A' if s['attempt'] else '', 'L',s['loadKg'],'x',s['amount'],'fl',s['flames'],'rir',round(s['trueRir'],1) if s['trueRir'] is not None else None,'F' if s['failed'] else '', 'tgt',s['targetLow'],s['targetHigh'],'max',round(s['dayMax'],1) if s['dayMax'] else None, '|', '; '.join(s['trace'] or []) if isinstance(s['trace'],list) else s['trace'])
