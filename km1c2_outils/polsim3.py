import json,sys,math,statistics as st
from polsim import load,floor,N
TAB=[[4.0,0.10],[3.0,0.075],[2.0,0.05],[1.0,0.025]]
def rir(f): return None if f is None else (0.0 if f>=10 else (11-f)/2.0)
def pas(f,tab=TAB):
    d=rir(f)
    if d is None: return 0.0
    for s,p in tab:
        if d>=s-1e-9: return p
    return 0.0
def ceiling(l,var,tab=TAB):
    bw=l['bw']; rec=l['rec'] if isinstance(l['rec'],list) else []
    if not rec: return None
    T=lambda c,r:(c+bw)*(1+0.025*min(max(r-1,0),4))
    if var=='V1':   # max sur toutes les barres
        return max(T(c,r)*(1+pas(f,tab)) for c,r,d,f in rec)
    if var=='V0':   # m=0
        return max(T(c,r) for c,r,d,f in rec)
    if var=='V3':   # la plus lourde barre (équivalent 1 rép) seulement, et sa note ; à égalité la note la plus dure
        best=max(T(c,r) for c,r,d,f in rec)
        ps=[pas(f,tab) for c,r,d,f in rec if T(c,r)>=best*(1-1e-9)]
        return best*(1+min(ps))
    if var=='V4':   # barres à moins de 5 % de la plus lourde : palier le plus prudent parmi elles appliqué à la plus lourde ; sinon V1 borné
        best=max(T(c,r) for c,r,d,f in rec)
        ps=[pas(f,tab) for c,r,d,f in rec if T(c,r)>=best*0.95]
        return best*(1+min(ps))
    if var=='V5':   # médiane des paliers des barres à moins de 5 %
        best=max(T(c,r) for c,r,d,f in rec)
        ps=sorted(pas(f,tab) for c,r,d,f in rec if T(c,r)>=best*0.95)
        return best*(1+ps[(len(ps)-1)//2])
    if var=='V6':   # V1 mais une barre dite dure (RIR<=1 ou échec?) plafonne les barres plus légères : max_i min(T_i(1+p_i), min_{j: T_j>=T_i, dur} T_j*(1+p_j))
        vals=[]
        durs=[(T(c,r),pas(f,tab)) for c,r,d,f in rec if f is not None and rir(f)<=1.0]
        for c,r,d,f in rec:
            v=T(c,r)*(1+pas(f,tab))
            for (tj,pj) in durs:
                if tj>=T(c,r)-1e-9: v=min(v,tj*(1+pj))
            vals.append(v)
        return max(vals)
def ladder(l,var,p_open=.95,part=.91,tab=TAB):
    est,sd,bw,dm=l['est'],l['sd'],l['bw'],l['dm']
    o=min(est*math.exp(-N.inv_cdf(p_open)*sd),part*est)
    if var!='E':
        j=ceiling(l,var,tab)
        if j is not None and o>j: o=j
    o=floor(o-bw)+bw
    best=0.0;cur=o;ok=cur<=dm
    if ok: best=cur
    for (p,s) in ((.8,0.05),(.5,0.03)):
        if ok:
            want=est*math.exp(-N.inv_cdf(p)*sd)
            nxt=floor(min(max(want,cur),min(cur*(1+s),cur+5.0))-bw)+bw
            cur=max(nxt,cur)
        ok=cur<=dm
        if ok and cur>best: best=cur
    return best/dm
A=load('openers_adv2.json')
try: B=load('openers_g01b.json')
except Exception: B=[]
def by_adv(rows,v):
    d={}
    for l,x in zip(rows,v): d.setdefault(tuple(l['job']),[]).append(x)
    return d
print('%-6s %8s %8s %6s %6s'%('var','banc','adv','zeros','<.75'))
for var in ['E','V0','V1','V3','V4','V5','V6']:
    a=[ladder(l,var) for l in A]; b=[ladder(l,var) for l in B] or [0]
    print('%-6s %8.4f %8.4f %6d %6d'%(var,st.mean(b),st.mean(a),sum(x==0 for x in a),sum(x<.75 for x in a)))
T2=[[4.0,0.075],[3.0,0.05],[2.0,0.025]]
for var in ['V1','V4','V6']:
    a=[ladder(l,var,tab=T2) for l in A]; b=[ladder(l,var,tab=T2) for l in B] or [0]
    print('%-6s %8.4f %8.4f %6d %6d  (table réduite)'%(var,st.mean(b),st.mean(a),sum(x==0 for x in a),sum(x<.75 for x in a)))
actual=[max([a[1] for a in l['att'] if not a[2]] or [0])/l['dm'] for l in A]
print('réel adv',st.mean(actual),sum(a==0 for a in actual))
