import sys, collections, statistics
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import donnees, meneur
from banc.politique_koach import PolitiqueKoach
infos=donnees.catalogue_infos()
fin=collections.defaultdict(list)
for cle in open('/home/claude/km1-outils/SET9').read().strip().split(','):
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']=='reference'][0]
    for kind in 'abc':
        tour=meneur.simuler(s, infos, PolitiqueKoach(), kind, int(sys.argv[1]) if len(sys.argv)>1 else 0)
        ramps=collections.defaultdict(list)
        for x in tour.sets:
            if x['test'] and x.get('repere') and x['mode']=='loaded': ramps[(x['exerciseId'],x['simDay'])].append(x)
        for k,v in ramps.items():
            fin[kind].append((v[-1]['trueRir'], len(v), v[-1]['failed'], s['level'], v[0]['trueRir']))
for k in fin:
    f=fin[k]; print(k,'rampes',len(f),'finale moy %.2f méd %.2f'%(statistics.mean(x[0] for x in f),statistics.median(x[0] for x in f)),'séries %.1f'%statistics.mean(x[1] for x in f),'échecs',sum(1 for x in f if x[2]), 'niveau→(finale, départ, séries)', {l: (round(statistics.mean(x[0] for x in f if x[3]==l),2), round(statistics.mean(x[4] for x in f if x[3]==l),1), round(statistics.mean(x[1] for x in f if x[3]==l),1)) for l in sorted(set(x[3] for x in f))}, '>3.5: %.2f'%statistics.mean(1 if x[0]>3.5 else 0 for x in f))
