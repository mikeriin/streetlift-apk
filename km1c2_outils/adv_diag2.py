import json,sys,os,math
sys.path.insert(0,os.getcwd()); sys.path.insert(0,'/tmp/k')
from multiprocessing import get_context
from banc import adversaire as A
import adv_diag as D
if __name__=='__main__':
    f=sys.argv[1]; seuil=float(sys.argv[2])
    advs=A.lire_adversaires(f)
    jobs=[]
    for a in advs:
        for s in a['koach']['par_graine']:
            if s['perf_a'] is not None and s['perf_a']<seuil: jobs.append((a,s['seed']))
    with get_context('fork').Pool(2) as p: res=p.map(D.run,jobs,chunksize=1)
    by={a['id']:a for a in advs}
    for r in res:
        a=by[r['id']]; sp=a['spec']
        print('==',r['id'],r['seed'],a['key'][:10],a['kind'],'ech',a['echeances'],{k:sp[k] for k in sp if k in('breakDays','breakFromDay','painDays','painFromDay','painIntensity','painZone','illnessDays','illnessFromDay','ratingNoise','rirBias','missRate','daySd','skipRating')})
        for e in r['evs']:
            logs=[l for l in r['log'] if l['ex']==e[0]]
            att=[x for x in r['att'] if x[1]==e[0]]
            l0=logs[0] if logs else {}
            print('    %-20s best/max %s/%s=%s est %s sd %s coup %s pal %s zone %s sh %s dern %s | att %s'%(e[0],e[1],e[2],e[3],l0.get('est'),l0.get('sd'),l0.get('coup'),l0.get('pal'),l0.get('zone'),l0.get('sh'),l0.get('dern'),[(x[2],'F' if x[3] else '',x[5]) for x in att]))
