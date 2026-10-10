import sys,json
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import validation_koach as vk
jobs=vk.jobs(['reference','maladie'],'abc',2)
res,ko=vk.paralleles(vk.collecter,jobs,coeurs=2)
t=vk.mesurer_bocpd(res,seuils=[0.6,0.7,0.8,0.9])
for l in t: print(l['seuil'],'réf : %.2f alertes/100 séances, %.2f %% au-dessus | maladie : détection %.3f, avant %.2f'%(l['reference']['fausses_alertes_100'],100*l['reference']['part_seances_au_dessus'],l['maladie']['taux_detection'],l['maladie']['fausses_alertes_avant_100']))
