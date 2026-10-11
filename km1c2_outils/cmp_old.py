import sys,os,json
sys.path.insert(0,os.getcwd())
from banc import adversaire as A
D='../../kalis_bench/docs/data/km2/'
for nom,f,t in (('km2_b3000',D+'adversaires_km2_b3000.json','donnees/temoin_adversaires/adversaires_km2_b3000_temoin.json.gz'),
                ('km2_complet_b600',D+'adversaires_km2_complet_b600.json','donnees/temoin_adversaires/adversaires_km2_complet_b600_temoin.json.gz'),
                ('km2_b300',D+'adversaires_km2_b300.json','donnees/temoin_adversaires/adversaires_km2_b300_temoin.json.gz'),
                ('km1_v1','donnees/adversaires_v1.json','donnees/adversaires_temoin.json.gz')):
    c=A.comparer(f,t,rejouer_koach=True,processus=2)
    c['moteur']={'koach':'référence Python 1.0.2 (koach/), sans extension (PolitiqueKoach())','temoin':'kalis_adapt 0.3.1 (Dart, bin/km1.dart --outils-seuls), fichier '+t,'adversaires':f}
    A.ecrire_lisible('donnees/comparaison_adversaires_km1c2_%s.json'%nom,c)
    b=c['critere_7_bis']
    print(nom,'pire koach',c['critere']['pire_koach'],'temoin',c['critere']['pire_temoin'],'| 7bis n',b['n'],'tenus',b['tenus'],'part',b['part'],'sous plancher',len(b['sous_plancher']),'non excusés',b['sous_plancher_non_excuses'],'pire écart',b['pire_ecart'],'| témoin avec barre',b['temoin_avec_barre']['n'],b['temoin_avec_barre']['tenus'],'| sécurité koach',c['groupes']['tous']['securite']['koach'],flush=True)
