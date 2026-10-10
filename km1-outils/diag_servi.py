import sys, json, collections
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import donnees, meneur, campagne as ca, securite_banc as sb
cle, scen, ver, graine = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
opts = ca.options_de(['--sans-planificateur'] if len(sys.argv) > 5 else [])
infos = donnees.catalogue_infos()
s = [x for x in donnees.saisons_reference(cle) if x['scenario'] == scen][0]
pol = ca.politique(opts, graine)
tour = meneur.simuler(s, infos, pol, ver, graine)
ini = sb.constats_saison(s, infos)
serv = sb.constats_saison(s, infos, blocs=ca.blocs_servis_prescrits(s, tour, True))
print('initial', sb.comptes(ini)); print('servi', sb.comptes(serv))
for c in serv[:12]: print({k: v for k, v in c.items() if k in ('code','week','dayIndex','exerciseId','value','limit','group','detail')})
# comparaison écrit/servi des deux premières semaines
ec = {}
for b in s['blocks']:
    for w in b['pass2']['weeks']:
        for d in w['days']:
            for i in d['items']:
                ec[(b.get('index', s['blocks'].index(b)), w['weekIndex'], d['dayIndex'], i['slotId'])] = i
n = 0
for (g, bi, wb, di, items) in tour.servi:
    if g > 1: break
    for i in items:
        e = ec.get((bi, wb, di, i['slotId']))
        d = {k: i.get(k) for k in ('exerciseId', 'kind', 'sets', 'repsLow', 'targetFlames')}
        if e is None: print('S', g, di, 'AJOUT', d)
        elif (e.get('sets'), e.get('targetFlames'), e.get('repsLow')) != (i.get('sets'), i.get('targetFlames'), i.get('repsLow')):
            print('S', g, di, 'ecrit', {k: e.get(k) for k in ('sets', 'repsLow', 'targetFlames', 'kind')}, '-> servi', d)
