import sys, json, gzip, math, statistics, collections
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from banc import donnees
from banc.politique_koach import vecteurs, params, profil_koach
from koach.modele import Modele
V=vecteurs(); res=collections.defaultdict(list)
for cle in donnees.profils():
    s=donnees.saisons_reference(cle)[0]
    prof=s['profiles'][0] if isinstance(s['profiles'],list) else s['profiles']
    if isinstance(prof,dict) and 'profile' in prof: prof=prof['profile']
    for ti in s['truthInits']:
        if ti['kind']!='a': continue
        m=Modele(params(), V, profil_koach(s, prof))
        for ex,vals in ti['truths'].items():
            t=m.piste(ex)
            if t is None: continue
            c=m.capacite(ex)
            res[(t.type, 'déclaré' if t.declare else 'non', s['level'])].append((c[0]-math.log(vals[0]), c[1], cle, ex))
for k in sorted(res):
    v=res[k]; d=[x[0] for x in v]
    print(k,'n=%d écart moyen %+.3f sd %.3f |sd a priori %.3f| min %+.2f max %+.2f'%(len(v),statistics.mean(d),statistics.pstdev(d),statistics.mean(x[1] for x in v),min(d),max(d)))
for typ in ('reps','tenue','charge'):
    al=[x for k,v in res.items() if k[0]==typ and k[1]=='non' for x in v]
    al.sort(key=lambda x:-abs(x[0]))
    print(typ,'pires:',[(round(x[0],2),x[3]) for x in al[:8]])
