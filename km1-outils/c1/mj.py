import sys,os,json,time
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import politique_koach as pk, criteres_moteur as cm
for _a in [x for x in os.environ.get('SETP','').split(';') if x]:
    _k,_v=_a.split('=',1); _s,_c=_k.split('.',1); pk.params()[_s][_c]=json.loads(_v)
r=cm.mesurer_mauvais_jour(apparie=True)
print(os.environ.get('SETP',''),'|',' '.join('%s %.4f (méd %.4f, p95 %.4f)'%(k,v['moyenne'],v['mediane'],v['p95']) for k,v in r['ecart_abs'].items()),'| signé',round(r['ecart_signe_moyen']['apres'],4))
