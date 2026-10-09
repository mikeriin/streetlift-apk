# témoin 0.3.1 sur un sous-ensemble : temoin.py <profils|tous> <scenarios|tous> [modeles]
import sys, statistics
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import donnees, mesures
import gzip, json, os
D='/home/claude/moteurs/packages/kalis_adapt/reference/donnees/temoin/'
a=sys.argv
cles=donnees.profils() if a[1]=='tous' else a[1].split(',')
scens=a[2].split(','); kinds=a[3] if len(a)>3 else 'abc'
E={m:mesures.Estimations() for m in ('loadedMain','loaded','reps','hold')}
EK={k:mesures.Estimations() for k in kinds}
gap=[]; ev=[]; viol=0; runs=0; agg=0; fl=0; fail=[]; gains=[]
for cle in cles:
    for s in json.load(gzip.open(D+cle+'.json.gz','rt')):
        if scens!=['tous'] and s['scenario'] not in scens: continue
        for k in kinds:
            t=s['truths'][k]
            for m in E: E[m].ajouter_temoin(t['estimates'][m])
            EK[k].ajouter_temoin(t['estimates']['loadedMain'])
            c=t['coach']
            if c['effortGap']['n']: gap.append(c['effortGap']['mean'])
            fail.append(c['failRate']['mean'])
            for r in t['runs']:
                runs+=1; viol+=r['violations']; agg+=r['painAggravations']; fl+=r['painFlares']; gains.append(r['gainMean'])
                for e in r['events']:
                    if e[5]: ev.append((None, e))
print('témoin: saisons',runs,'violations',viol,'aggr',agg,'flares',fl,'gain %.5f'%statistics.mean(gains))
for m in E:
    f=E[m].first_under; nz=[x for x in f if x>0]
    print(m,'premier rang MAE<3%:',E[m].premier_rang_sous(),' premier passage: moy %.2f jamais %.3f'%(statistics.mean(nz) if nz else -1, 1-len(nz)/max(1,len(f))))
    for k in (1,3,6,12,24):
        l=E[m].ligne(k)
        if l: print('  k=%d n=%d MAE=%.4f biais=%+.4f sous3=%.3f'%(k,l['n'],l['mae'],l['biais'],l['sous3']))
for k in EK:
    l=EK[k].ligne(6)
    if l: print('modele',k,'principaux k=6 MAE=%.4f biais=%+.4f'%(l['mae'],l['biais']))
print('ecart effort %.3f'%statistics.mean(gap),'echecs %.4f'%statistics.mean(fail))
for mode in ('loaded','reps','hold'):
    x=[e for _,e in ev if e[1]==mode]
    if x: print('echeance',mode,len(x),'best/max %.4f'%statistics.mean(e[3]/e[5] for e in x),'best/cap0 %.4f'%statistics.mean(e[3]/e[6] for e in x if e[6]))
