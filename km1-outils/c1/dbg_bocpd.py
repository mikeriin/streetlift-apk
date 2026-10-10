import sys,os,json
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import meneur, extensions_koach as ek, validation_koach as vk, politique_koach as pk
for _a in [x for x in os.environ.get('SETP','').split(';') if x]:
    _k,_v=_a.split('=',1); _s,_c=_k.split('.',1); pk.params()[_s][_c]=json.loads(_v)
cle,sc,kind,g=sys.argv[1],sys.argv[2],sys.argv[3],int(sys.argv[4])
s=vk.saison(cle,sc)
pol=ek.politique(g,briques=('surveillance',),parametres=vk.params_seuil(0.6))
tour=meneur.simuler(s,vk.infos(),pol,kind,g)
m=pol.koach.modele
print('maladie',s['specJson'].get('illnessFromDay'),s['specJson'].get('illnessDays'))
print(' '.join('%d:%+.2f(w%.2f)'%(h[0],h[1],h[4]) for h in m.histoire_residus))
j=ek.journaux(pol)['SurveillanceBanc']
print([ (e['type'],e.get('jour'),e.get('action'),round(e.get('p',0),2) if e.get('p') is not None else None) for e in j][:30])
