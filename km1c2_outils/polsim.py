import json,sys,math,statistics as st
from statistics import NormalDist
N=NormalDist()
def load(f):
    rows=[]
    for r in json.load(open(f)):
        for l in r['log']:
            if not l['att'] or not l['ev']: continue
            l=dict(l); l['dm']=l['att'][0][3]; l['job']=r['job']
            rows.append(l)
    return rows
def floor(x,pas=2.5): return math.floor(x/pas+1e-9)*pas
def ladder(l,p_open,part,p2=0.8,p3=0.5,bars=None,stale=None):
    est,sd,bw,dm=l['est'],l['sd'],l['bw'],l['dm']
    sd_e=sd
    o=min(est*math.exp(-N.inv_cdf(p_open)*sd_e),part*est)
    if bars is not None:
        # plafond par barres prouvées : max sur barres récentes de total*(1+m)*(1+0.025*min(r-1,4))
        m=bars
        j=None
        for (c,r,d) in (l['rec'] if isinstance(l['rec'],list) else []):
            b=(c+bw)*(1+m)*(1+0.025*min(max(r-1,0),4))
            if j is None or b>j: j=b
        if j is not None and o>j: o=j
    o=floor(o-bw)+bw
    best=0.0
    cur=o
    seq=[]
    ok=cur<=dm
    seq.append((cur,ok))
    if ok: best=cur
    for (p,s) in ((p2,0.05),(p3,0.03)):
        if not seq[-1][1]:
            nxt=cur   # même barre après échec
        else:
            want=est*math.exp(-N.inv_cdf(p)*sd)
            haut=min(cur*(1+s),cur+5.0)
            nxt=min(max(want,cur),haut)
            nxt=floor(nxt-bw)+bw
            if nxt<cur: nxt=cur
        cur=nxt
        ok=cur<=dm
        seq.append((cur,ok))
        if ok and cur>best: best=cur
    return best/dm
def evalp(rows,name,**kw):
    v=[ladder(l,**kw) for l in rows]
    z=sum(1 for x in v if x==0)
    return '%-34s perf %.4f  zeros %3d/%d  p10 %.3f'%(name,st.mean(v),z,len(v),sorted(v)[len(v)//10])
if __name__=='__main__':
    for f in sys.argv[1:]:
        rows=load(f)
        print(f,len(rows))
        zs=[math.log(l['est']/l['dm'])/l['sd'] for l in rows]
        print('  z=ln(est/dm)/sd : mean %.2f sd %.2f ; P(z>1.645) %.3f ; P(ln(est/dm)>0.094) %.3f ; sd moyen %.3f'%(st.mean(zs),st.pstdev(zs),sum(z>1.645 for z in zs)/len(zs),sum(math.log(l['est']/l['dm'])>0.0943 for l in rows)/len(rows),st.mean(l['sd'] for l in rows)))
        actual=[max([a[1] for a in l['att'] if not a[2]] or [0])/l['dm'] for l in rows]
        print('  réel (1.0.1 ou mode courant)        perf %.4f  zeros %d'%(st.mean(actual),sum(a==0 for a in actual)))
        for (po,pa) in ((0.95,0.91),(0.975,0.91),(0.99,0.91),(0.995,0.91),(0.95,0.89),(0.99,0.90),(0.99,0.92),(0.975,0.92)):
            print('  '+evalp(rows,'p=%.3f part=%.2f'%(po,pa),p_open=po,part=pa))
        for m in (0.10,0.05,0.0):
            print('  '+evalp(rows,'p=.95 part=.91 barres+%d%%'%(m*100),p_open=.95,part=.91,bars=m))
            print('  '+evalp(rows,'p=.99 part=.91 barres+%d%%'%(m*100),p_open=.99,part=.91,bars=m))
