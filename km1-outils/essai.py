import sys, time, statistics
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import donnees, meneur, mesures
from banc.politique_koach import PolitiqueKoach
infos=donnees.catalogue_infos()
cles=sys.argv[1].split(',') if len(sys.argv)>1 else ['street_07_avance_streetlifting_competition']
scen=sys.argv[2].split(',') if len(sys.argv)>2 else ['reference']
seeds=int(sys.argv[3]) if len(sys.argv)>3 else 2
E={m:mesures.Estimations() for m in ('loadedMain','loaded','reps','hold')}
ev=[]; t0=time.time(); n=0; eff=[]; gains=[]; agg=0; fl=0
for cle in (donnees.profils() if cles==['tous'] else cles):
    for s in donnees.saisons_reference(cle):
        if scen!=['tous'] and s['scenario'] not in scen: continue
        for kind in 'abc':
            for seed in range(seeds):
                tour=meneur.simuler(s, infos, PolitiqueKoach(), kind, seed)
                n+=1
                E['loadedMain'].add(tour, lambda e:e['mode']=='loaded' and e['main'])
                E['loaded'].add(tour, lambda e:e['mode']=='loaded')
                E['reps'].add(tour, lambda e:e['mode']=='reps')
                E['hold'].add(tour, lambda e:e['mode']=='hold')
                ev+=mesures.evenements(tour); eff.append(mesures.effort(tour)); 
                g=mesures.gain_moyen(tour)
                if g is not None: gains.append(g)
                agg+=tour.pain_aggravations; fl+=tour.pain_flares
print('saisons',n,'%.1fs/saison'%((time.time()-t0)/max(1,n)), 'gain', statistics.mean(gains) if gains else None, 'aggr',agg,'flares',fl)
for m in E:
    print(m, 'premier<3%',E[m].premier_rang_sous())
    for k in (1,2,3,4,6,8,12,16,24):
        l=E[m].ligne(k)
        if l: print('  k=%d n=%d MAE=%.4f biais=%.4f sous3=%.3f couv=%.3f sd=%.4f'%(k,l['n'],l['mae'],l['biais'],l['sous3'],l['couverture'],l['sd']))
ee=[e for e in eff if e['ecart_effort'] is not None]
print('ecart effort', statistics.mean(e['ecart_effort'] for e in ee), 'echecs', statistics.mean(e['echecs'] for e in ee), 'hausses', sum(e['hausses_trop_fortes'] for e in eff))
for mode in ('loaded','reps','hold'):
    x=[e for e in ev if e[1]==mode]
    if x: print('echeance',mode,len(x),'best/max %.4f'%statistics.mean(e[2]/e[4] for e in x),'best/cap0 %.4f'%statistics.mean(e[2]/e[5] for e in x if e[5]))
