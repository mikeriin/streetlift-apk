import pickle,math,statistics,sys
import numpy as np
for f in sys.argv[1:]:
    rows=pickle.load(open(f,'rb'))
    seen={}
    for r in rows: seen[(r['cle'],r['scen'],r['kind'],r['seed'],r['ex'],r['sem_E'])]=r
    C=[r for r in seen.values() if r['type']=='charge' and r['essais']]
    y=[r['best']/r['daymax'] for r in C]
    top=[math.log(max(e[3] for e in r['essais'] if e[3] is not None)+r['essais'][0][4])-r['essais'][0][1] for r in C]
    eps=[r['essais'][0][1]-math.log(r['daymax']) for r in C]
    print(f,'n=%d best/max %.4f | top−Ê %.4f | Ê−max %+.4f (sd %.4f) | sd jour méd %.4f moy %.4f | réussite %.3f'%(len(C),statistics.mean(y),statistics.mean(top),statistics.mean(eps),statistics.pstdev(eps),statistics.median(r['essais'][0][2] for r in C),statistics.mean(r['essais'][0][2] for r in C),statistics.mean(1 if r['best']>=r['cible']-1e-9 else 0 for r in C)))
