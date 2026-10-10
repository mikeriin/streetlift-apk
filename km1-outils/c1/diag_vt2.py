import sys, collections
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
    o_mu=S.Seances._mesure_utile; o_vt=S.Seances._vrai_test; o_d=S.Seances._duree_permet_test
    etat={}
    def mu(self,item,plan,t,vrai=False):
        r=o_mu(self,item,plan,t,vrai=vrai)
        ta=self.p['test_adaptatif']; c=self.contexte or {}
        why='ok'
        if not r:
            if item.get('sets',0)<1 or plan['test'] or item.get('kind')=='warmup': why='item'
            elif plan['verrou']: why='verrou'
            elif plan['sans_hausse']: why='sans_hausse'
            elif plan['echecs']>0: why='echecs'
            elif plan['cond']['raison']: why='cond'
            elif plan.get('dose_plafonnee'): why='dose'
            elif self.coupure>0: why='coupure'
            elif self._apres_retour(self.mem(item['exerciseId'])) is not None and self._apres_retour(self.mem(item['exerciseId']))<self.s['retour_seances_avant_mesure']: why='retour'
            elif c.get('jours_avant_echeance') is not None and c['jours_avant_echeance']<=14: why='echeance'
            elif item.get('dayStress')=='light': why='light'
            elif (item.get('technique') or {}).get('kind') not in (None,'standard','top_set_backoff','isometric_hold'): why='technique:'+str((item.get('technique') or {}).get('kind'))
            elif 1.6448536269514722*self.m.capacite(item['exerciseId'])[1]<=ta['intervalle_declenchement']: why='intervalle'
            elif (t.dernier_vrai_test_jour is not None and self.jour-t.dernier_vrai_test_jour<ta['jours_min_entre_tests']) or (t.derniere_rampe_jour is not None and self.jour-t.derniere_rampe_jour<ta['jours_min_entre_rampes']): why='14j'
            elif self.g.niveau==0 and t.seances<3: why='debutant<3'
            else: why='autre'
        etat['mu']=why
        return r
    def vt(self,item,plan,t):
        etat['mu']=None
        r=o_vt(self,item,plan,t)
        if plan['role']=='main' and plan['type']=='charge' and t is not None and t.seances<=6 and item.get('kind')=='work':
            if r is not None: why='OUI'
            elif item.get('sets',0)<2: why='sets<2'
            elif t.seances<1: why='seances<1'
            elif etat['mu'] not in (None,'ok'): why='mu:'+etat['mu']
            else:
                mem=self.mem(item['exerciseId']); g=plan['grille']
                if g is None or mem.charge_max is None: why='pas de reference'
                elif not any(self.jour-j<=self.s['barre_recente_j'] for (j,c,r_) in mem.charges_reussies): why='pas de barre recente'
                else: why='grille grossiere'
            C[(t.seances,why)]+=1; C[('tot',why)]+=1
        return r
    def d(self,items,item,vt_,deja):
        r=o_d(self,items,item,vt_,deja)
        if not r: C[('tot','BUDGET refuse')]+=1
        return r
    S.Seances._mesure_utile=mu; S.Seances._vrai_test=vt; S.Seances._duree_permet_test=d
    tour=meneur.simuler(s, infos, PolitiqueKoach(), kind, seed)
    S.Seances._mesure_utile=o_mu; S.Seances._vrai_test=o_vt; S.Seances._duree_permet_test=o_d
    return C
if __name__=='__main__':
    cles=sys.argv[1].split(','); seeds=int(sys.argv[2])
    jobs=[(c,k,s) for c in cles for k in 'abc' for s in range(seeds)]
    with Pool(2) as p: res=p.map(un, jobs)
    C=collections.Counter()
    for c in res: C.update(c)
    for k in sorted(C,key=str): print(k, C[k])
