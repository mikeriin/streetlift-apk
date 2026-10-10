import sys,json,math
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import criteres_moteur as cm
from koach.moteur import Koach
from koach import modele as M
cle,ver,gr=sys.argv[1],sys.argv[2],int(sys.argv[3])
s=cm._saison(cle,'reference')
base,kb=cm._saison_et_journal(s,ver,gr)
jour,ex=cm.choisir_jour(s,base)
_,km=cm._saison_et_journal(s,ver,gr,cm.classe_mauvais_jour(jour,0.06))
jb=json.loads(json.dumps(kb.journal,default=cm._defaut)); jm=json.loads(json.dumps(km.journal,default=cm._defaut))
sb=cm._seance_du_jour(jb,jour); sm=cm._seance_du_jour(jm,jour)
for nom,J,(i0,i1) in (('BASE',jb,sb),('MAUVAIS',jm,sm)):
    k=Koach(kb.params,kb.fiches,kb.profil)
    for e in J[:i0]: k.observe(e)
    print('==',nom,'jour',jour)
    for e in J[i0:i1+1]:
        if e['type']=='seance_fin':
            print('   poids mauvais jour avant fusion %.3f'%k.modele.poids_mauvais_jour())
        k.observe(e)
        if e['type']=='serie':
            x=e['serie']; t=k.modele.pistes.get(x['exerciseId'])
            if t is not None and t.type=='charge':
                print('   %s L=%s reps=%s fl=%s cible=%s ech=%s role=%s | w=%.3f e1RM=%.1f (alt %.1f) DS=%.4f'%(x['exerciseId'][:18],x.get('externalLoadKg'),x.get('reps'),x.get('flames'),(x.get('target') or {}).get('flames'),x.get('failed'),x.get('role'),k.modele.poids_mauvais_jour(),math.exp(k.modele.capacite(x['exerciseId'])[0]),math.exp(t.base+sum(c*k.modele.alt[0][i] for i,c in zip(*k.modele._h_capacite(t,jour=False)))) if k.modele.alt else 0,k.modele.m[M.DS]))
    for exo in sorted(set(e['serie']['exerciseId'] for e in J[i0:i1+1] if e['type']=='serie')):
        c=k.modele.capacite(exo)
        if c and k.modele.pistes[exo].type=='charge': print('   fin',exo,'%.2f'%math.exp(c[0]))
