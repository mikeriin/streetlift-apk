import sys, json
sys.path.insert(0,'.')
from banc import criteres_moteur as cm
import statistics
r = cm.mesurer_mauvais_jour(coeurs=2)
print(json.dumps({k:v for k,v in r.items() if k not in ('lignes','details')}, ensure_ascii=False)[:1800])
