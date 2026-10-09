import sys, collections
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import donnees, meneur, mesures
from banc.politique_koach import PolitiqueKoach
infos=donnees.catalogue_infos()
cle=sys.argv[1]; kind=sys.argv[2]; seed=int(sys.argv[3]); exs=sys.argv[4].split(','); nmax=int(sys.argv[5]) if len(sys.argv)>5 else 16
scen=sys.argv[6] if len(sys.argv)>6 else 'reference'
s=[x for x in donnees.saisons_reference(cle) if x['scenario']==scen][0]
pol=PolitiqueKoach()
tour=meneur.simuler(s, infos, pol, kind, seed, garder_journal=True)
by=collections.defaultdict(list)
for x in tour.sets: by[x['exerciseId']].append(x)
est=collections.defaultdict(list)
for e in tour.estimates: est[e['exerciseId']].append(e)
if exs==['?']:
    for ex in by: print(ex, pol.koach.fiches[ex]['type'], len(by[ex]), 'main' if by[ex][0]['main'] else '', 'cap0=%.1f'%tour.cap0.get(ex,0), 'est=%.1f'%(est[ex][-1]['capacity'] if est[ex] else 0), 'truth=%.1f'%(est[ex][-1]['truth'] if est[ex] else 0))
    sys.exit()
for ex in exs:
    print(ex, pol.koach.fiches[ex]['type'], 'base=%.3f'%pol.koach.modele.pistes[ex].base, 'cap0', tour.cap0.get(ex))
    k=0
    for x in by[ex][:nmax]:
        print('  d%d s%d load=%s amt=%s fl=%s trueRir=%.2f want=%.1f tgt=%s-%s cap=%.1f %s%s'%(x['simDay'],x['setIndex'],x['loadKg'],x['amount'],x['flames'],x['trueRir'],x['wantRir'],x['targetLow'],x['targetHigh'],x['capacity'],'TEST ' if x['test'] else '', 'FAIL' if x['failed'] else ''), 'REPERE' if x.get('repere') else '', x.get('trace') or '')
    for e in est[ex][:nmax]: print('   est k=%d cap=%.2f truth=%.2f sd=%.3f'%(e['exerciseSession'],e['capacity'],e['truth'],e['relSd']))
p=pol.koach.posterior()
print({k:(round(v,4) if isinstance(v,float) else v) for k,v in p.items() if k in ('biais_rir','bruit_rir','courbe','fatigue_intra','part_tenue','note_paresseuse','reponse')})
