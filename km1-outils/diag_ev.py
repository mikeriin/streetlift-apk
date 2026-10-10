import sys, math
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import donnees, meneur, mesures, extensions_koach as ek
cle, scen, kind = sys.argv[1], sys.argv[2], sys.argv[3]
s = [x for x in donnees.saisons_reference(cle) if x['scenario'] == scen][0]
p = ek.PolitiqueBriques(extensions=[ek.fabrique_surveillance()] if len(sys.argv) < 5 else [])
tour = meneur.simuler(s, donnees.catalogue_infos(), p, kind, 0)
for x in p.koach.extensions: print(type(x).__name__, getattr(x, 'journal', None))
ev = mesures.evenements(tour); print(ev)
jours = sorted({x['simDay'] for x in tour.sets if x['role'] in ('attempt', 'test') or x.get('steps')})
exs = {e[0] for e in ev}
last = max(x['simDay'] for x in tour.sets)
for x in tour.sets:
    if x['exerciseId'] in exs and x['simDay'] >= last - 21 and x['mode'] == 'loaded':
        print(x['simDay'], x['exerciseId'], x['role'], x['loadKg'], x['amount'], x['flames'], round(x['trueRir'], 1), x['failed'])
for e in tour.estimates:
    if e['exerciseId'] in exs and e['simDay'] >= last - 21: print('est', e['simDay'], e['exerciseId'], round(e['capacity'], 1), round(e['truth'], 1), round(e['relSd'], 3))
print('--- jour J')
for x in tour.sets:
    if x['eventDay'] and x['mode'] == 'loaded': print(x['simDay'], x['exerciseId'], x['role'], x['test'], x['loadKg'], x['amount'], x['flames'], round(x['trueRir'], 1), x['failed'], x.get('steps'))
print([r for r in p.koach.raisons][-12:])
