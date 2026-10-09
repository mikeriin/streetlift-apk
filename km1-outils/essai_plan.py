import sys, time, json
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import donnees, meneur, mesures, planification_banc
from banc.politique_koach import PolitiqueKoach
infos=donnees.catalogue_infos()
for cle in sys.argv[1].split(','):
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']=='reference'][0]
    for opts in (None, {'trajectoires':int(sys.argv[2]) if len(sys.argv)>2 else 1000}):
        t=time.time()
        pol=PolitiqueKoach(extensions=[planification_banc.fabrique(opts)] if opts else None)
        tour=meneur.simuler(s, infos, pol, 'a', 1)
        ev=mesures.evenements(tour)
        print(cle[:20], 'plan' if opts else 'sans', '%.1fs'%(time.time()-t), 'gain %.5f'%mesures.gain_moyen(tour), 'jour J', [round(e[2]/e[4],3) for e in ev], 'best', [round(e[2],1) for e in ev])
        if opts:
            pl=pol.koach.extensions[0]
            print('   cibles',pl.cibles,'echeance',pl.echeance_jour)
            for l in pl.historique[:2]+pl.historique[6:8]+pl.historique[-1:]: print('   ', {k:(v if not isinstance(v,float) else round(v,4)) for k,v in l.items() if k not in ('qualites',)})
