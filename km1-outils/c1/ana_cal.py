import pickle,math,statistics,sys,collections
import numpy as np
rows=pickle.load(open(sys.argv[1],'rb'))
def dec(pairs,nmin=30):
    out=[];pire=0
    for d in range(10):
        S=[(p,o) for p,o in pairs if min(9,int(p*10))==d]
        if not S: continue
        pm=sum(p for p,_ in S)/len(S); om=sum(1 for _,o in S if o)/len(S)
        out.append('d%d n=%d p %.3f obs %.3f%s'%(d,len(S),pm,om,'' if len(S)>=nmin else ' (n<30)'))
        if len(S)>=nmin: pire=max(pire,abs(pm-om))
    return out,pire
for typ in ('charge','reps',None):
    R=[r for r in rows if (typ is None or r['type']==typ)]
    if not R: continue
    o,p=dec([(r['p'],r['best']>=r['cible']-1e-9) for r in R])
    print('==',typ or 'tous','n',len(R),'écart max %.3f'%p); print('  '+' | '.join(o))
R=[r for r in rows if r['prevu']]
for typ in ('charge','reps'):
    for lo,hi in ((0,3),(3,7),(7,20)):
        S=[r for r in R if r['type']==typ and lo<=r['sem_E']-r['semaine']<hi]
        if not S: continue
        d=[math.log(r['daymax'])-r['prevu'][0] for r in S]
        z=[(math.log(r['daymax'])-r['prevu'][0])/math.sqrt(r['prevu'][1]**2+0.028**2) for r in S]
        print(typ,'semaines avant [%d,%d) n=%d : ln daymax − prévu : moy %+.4f sd %.4f | sd prévu moyen %.4f | z moy %+.2f sd %.2f'%(lo,hi,len(S),statistics.mean(d),statistics.pstdev(d),statistics.mean(r['prevu'][1] for r in S),statistics.mean(z),statistics.pstdev(z)))
    for k in 'abc':
        S=[r for r in R if r['type']==typ and r['kind']==k]
        d=[math.log(r['daymax'])-r['prevu'][0] for r in S]
        if d: print('   vérité',k,'moy %+.4f sd %.4f'%(statistics.mean(d),statistics.pstdev(d)))
# unités distinctes (dernière prévision) pour la structure du test
seen={}
for r in rows:
    seen[(r['cle'],r['scen'],r['kind'],r['seed'],r['ex'],r['sem_E'])]=r
U=list(seen.values())
C=[r for r in U if r['type']=='charge' and r['essais']]
print('unités charge avec tentatives',len(C),'| sans',len([r for r in U if r['type']=='charge' and not r['essais']]),'| reps',len([r for r in U if r['type']!='charge']))
e0=[r['essais'][0][1]-math.log(r['daymax']) for r in C]
print('Ê(1er essai) − ln max du jour : moy %+.4f sd %.4f'%(statistics.mean(e0),statistics.pstdev(e0)))
top=[math.log(max(e[3] for e in r['essais'] if e[3] is not None)+r['essais'][0][4])-r['essais'][0][1] for r in C]
print('ln(barre la plus lourde tentée) − Ê : moy %+.4f sd %.4f min %+.3f max %+.3f'%(statistics.mean(top),statistics.pstdev(top),min(top),max(top)))
y=[math.log(r['best']/r['daymax']) for r in C if r['best']>0]
print('rendement ln(best/daymax) : moy %+.4f sd %.4f, zéro barre %d'%(statistics.mean(y),statistics.pstdev(y),len([r for r in C if r['best']<=0])))
print('réussite cible %.3f ; cible ≤ max du jour %.3f ; cible ≤ barre tentée max %.3f'%(statistics.mean(1 if r['best']>=r['cible']-1e-9 else 0 for r in C),statistics.mean(1 if r['daymax']>=r['cible'] else 0 for r in C),statistics.mean(1 if max(e[3] for e in r['essais'] if e[3] is not None)+r['essais'][0][4]>=r['cible']-1e-9 else 0 for r in C)))
Rp=[r for r in U if r['type']!='charge']
if Rp:
    y=[math.log(max(r['best'],0.5)/r['daymax']) for r in Rp]
    print('reps : rendement ln(best/daymax) moy %+.4f sd %.4f ; réussite %.3f ; capable %.3f'%(statistics.mean(y),statistics.pstdev(y),statistics.mean(1 if r['best']>=r['cible']-1e-9 else 0 for r in Rp),statistics.mean(1 if r['daymax']>=r['cible'] else 0 for r in Rp)))
print('écart cible : ln(cible) − ln(max du jour) quantiles', np.round(np.quantile([math.log(r['cible']/r['daymax']) for r in U],[.05,.25,.5,.75,.95]),3))
