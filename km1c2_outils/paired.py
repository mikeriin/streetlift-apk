import json,sys,os
sys.path.insert(0,os.getcwd())
from banc import adversaire as A
D='../../kalis_bench/docs/data/km2/'
def paired(nom, proc=2, complet=False):
    advs={a['id']:a for a in A.lire_adversaires(D+'adversaires_%s.json'%nom)}
    comp=json.load(open(D+'comparaison_adversaires_%s.json'%nom))['adversaires']
    sel=[c for c in comp if c['koach'].get('perf_a') is not None and c['temoin'].get('perf_a') is not None]
    trav=[]
    for c in sel:
        a=advs[c['id']]
        trav+=A._travaux(a)
    res=A._evaluer_tous(trav,proc)
    k=0;rows=[]
    for c in sel:
        a=advs[c['id']]; n=len(a['seeds'])
        ss=res[k:k+n];k+=n
        r=A._resume(ss)
        rows.append(dict(id=c['id'],key=c['key'][:10],kind=c['kind'],avant=c['koach']['perf_a'],apres=r['perf_a'],temoin=c['temoin']['perf_a'],tmin=c['temoin']['perf_a_min'],tviol=c['temoin']['violations'],aggr=r['aggravations'],pouss=r['poussees'],viol=r['violations'],plant=r['plantages'],seeds=[(s['seed'],s['perf_a']) for s in ss]))
    return rows
def resume(rows,nom):
    pr=[r for r in rows if r['temoin']>0]
    ok=sum(1 for r in pr if r['apres']>=r['temoin']-0.03)
    bad=[r for r in pr if r['apres']<r['temoin']-0.10]
    print('%s: apparies (temoin>0) %d ; >= temoin-0.03 : %d (%.0f %%) ; < temoin-0.10 : %d ; pire koach %.3f ; moy koach %.3f temoin %.3f ; aggr %d pouss %d plant %d'%(nom,len(pr),ok,100.0*ok/max(1,len(pr)),len(bad),min(r['apres'] for r in rows),sum(r['apres'] for r in pr)/len(pr),sum(r['temoin'] for r in pr)/len(pr),sum(r['aggr'] for r in rows),sum(r['pouss'] for r in rows),sum(len(r['plant']) for r in rows)))
    for r in sorted(pr,key=lambda r:r['apres']-r['temoin'])[:14]:
        print('   %s %s %s avant %.3f apres %.3f temoin %.3f (min %.3f, viol %s) ecart %+.3f %s'%(r['id'],r['key'],r['kind'],r['avant'],r['apres'],r['temoin'],r['tmin'],r['tviol'],r['apres']-r['temoin'],r['seeds']))
if __name__=='__main__':
    out={}
    for nom in sys.argv[2:]:
        rows=paired(nom); out[nom]=rows; resume(rows,nom)
    json.dump(out,open(sys.argv[1],'w'))
