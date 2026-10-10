# diag_vt.py : pourquoi le vrai test n'est pas servi dans les 6 premières séances
import sys, collections, statistics
sys.path.insert(0,'/home/claude/moteurs/packages/kalis_adapt/reference')
from multiprocessing import Pool
from banc import donnees, meneur
from banc.politique_koach import PolitiqueKoach
from koach import seance as S
def un(a):
    cle,kind,seed=a
    infos=donnees.catalogue_infos()
    s=[x for x in donnees.saisons_reference(cle) if x['scenario']=='reference'][0]
    C=collections.Counter()
    orig_mu=S.Seances._mesure_utile; orig_vt=S.Seances._vrai_test
    def mu(self,item,plan,t):
        r=orig_mu(self,item,plan,t)
        if plan['role'] in ('main','secondary') and plan['type']=='charge' and item.get('kind')=='work' and t is not None and t.seances<=6:
            ta=self.p['test_adaptatif']; c=self.contexte or {}
            why='ok'
            if not r:
                if plan['verrou']: why='verrou'
                elif plan['sans_hausse']: why='sans_hausse'
                elif plan['echecs']>0: why='echecs'
                elif plan['cond']['raison']: why='cond'
                elif plan.get('dose_plafonnee'): why='dose'
                elif self.coupure>0: why='coupure'
                elif c.get('jours_avant_echeance') is not None and c['jours_avant_echeance']<=14: why='echeance'
                elif item.get('dayStress')=='light': why='light'
                elif (item.get('technique') or {}).get('kind') not in (None,'standard','top_set_backoff','isometric_hold'): why='technique'
                elif 1.6448536269514722*self.m.capacite(item['exerciseId'])[1]<=ta['intervalle_declenchement']: why='intervalle'
                elif t.dernier_test_jour is not None and self.jour-t.dernier_test_jour<ta['jours_min_entre_tests']: why='14j'
                elif self.g.niveau==0 and t.seances<3: why='debutant<3'
                else: why='autre'
            C[('mu',t.seances,why)]+=1
        return r
    def vt(self,item,plan,t):
        r=orig_vt(self,item,plan,t)
        if plan['role'] in ('main','secondary') and plan['type']=='charge' and t is not None and t.seances<=6:
            C[('vt',t.seances,'oui' if r else 'non')]+=1
        return r
    S.Seances._mesure_utile=mu; S.Seances._vrai_test=vt
    tour=meneur.simuler(s, infos, PolitiqueKoach(), kind, seed)
    S.Seances._mesure_utile=orig_mu; S.Seances._vrai_test=orig_vt
    nt=sum(1 for x in tour.sets if x.get('test') and x['mode']=='loaded')
    return C,nt
if __name__=='__main__':
    cles=sys.argv[1].split(','); seeds=int(sys.argv[2])
    jobs=[(c,k,s) for c in cles for k in 'abc' for s in range(seeds)]
    with Pool(2) as p: res=p.map(un, jobs)
    C=collections.Counter(); nt=0
    for c,n in res: C.update(c); nt+=n
    print('séries de test', nt)
    for k in sorted(C): print(k, C[k])
