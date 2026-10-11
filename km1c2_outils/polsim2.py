import json,sys,math,statistics as st
from polsim import load,floor,N
def ladder(l,p_open,part,m=None,per=0.025,rmax=4,p2=0.8,p3=0.5,sdx=0.0,stale=None):
    est,sd,bw,dm=l['est'],l['sd'],l['bw'],l['dm']
    sd_e=math.sqrt(sd*sd+sdx*sdx)
    o=min(est*math.exp(-N.inv_cdf(p_open)*sd_e),part*est)
    if m is not None and isinstance(l['rec'],list) and l['rec']:
        j=max((c+bw)*(1+m)*(1+per*min(max(r-1,0),rmax)) for (c,r,d) in l['rec'])
        if o>j: o=j
    o=floor(o-bw)+bw
    best=0.0;cur=o;ok=cur<=dm
    if ok: best=cur
    last_ok=ok
    for (p,s) in ((p2,0.05),(p3,0.03)):
        if last_ok:
            want=est*math.exp(-N.inv_cdf(p)*sd)
            haut=min(cur*(1+s),cur+5.0)
            nxt=floor(min(max(want,cur),haut)-bw)+bw
            if nxt<cur: nxt=cur
            cur=nxt
        last_ok=cur<=dm
        if last_ok and cur>best: best=cur
    return best/dm
B=load('openers_g01.json'); A=load('openers_adv.json')
def ev(rows,**kw):
    v=[ladder(l,**kw) for l in rows]
    return st.mean(v),sum(x==0 for x in v),v
print('%-46s %8s %8s %6s'%('politique','banc','adv','zeros'))
base=None
for kw in [dict(p_open=.95,part=.91),dict(p_open=.975,part=.91),dict(p_open=.99,part=.91),
           dict(p_open=.95,part=.91,sdx=0.03),dict(p_open=.95,part=.91,sdx=0.04),dict(p_open=.95,part=.91,sdx=0.05),
           dict(p_open=.95,part=.91,m=0.0),dict(p_open=.95,part=.91,m=0.025),dict(p_open=.95,part=.91,m=0.05),
           dict(p_open=.95,part=.91,m=0.0,rmax=10),dict(p_open=.95,part=.91,m=0.0,per=0.0333,rmax=10),
           dict(p_open=.95,part=.91,m=0.025,rmax=10),dict(p_open=.95,part=.91,m=0.05,rmax=10),
           dict(p_open=.975,part=.91,m=0.0,rmax=10),dict(p_open=.975,part=.91,m=0.025,rmax=10),dict(p_open=.975,part=.91,m=0.05,rmax=10),
           dict(p_open=.95,part=.91,m=-0.025,rmax=10),dict(p_open=.99,part=.91,m=0.0,rmax=10)]:
    b=ev(B,**kw); a=ev(A,**kw)
    print('%-46s %8.4f %8.4f %3d %s'%(str({k:v for k,v in kw.items()}),b[0],a[0],a[1],b[1]))
# quels adversaires à zéro avec m=0,rmax=10
a=ev(A,p_open=.95,part=.91,m=0.0,rmax=10)[2]
for l,x in zip(A,a):
    if x==0: print('ZERO',l['job'],l['ex'][3:22],'est/dm %.3f sd %.3f seances %s rec max %s dm %.1f bw %.0f'%(l['est']/l['dm'],l['sd'],l.get('seances'),max((c for c,r,d in l['rec']),default=None),l['dm'],l['bw']))
a0=ev(A,p_open=.95,part=.91)[2]
for l,x in zip(A,a0):
    if x==0: print('ZERO0',l['job'],l['ex'][3:22],'est/dm %.3f sd %.3f rec %s dm %.1f bw %.0f'%(l['est']/l['dm'],l['sd'],sorted(set((c,r) for c,r,d in l['rec']),reverse=True)[:4],l['dm'],l['bw']))
print('---- m=0 vs est : pertes > 0.03')
for rows,nom in ((B,'banc'),(A,'adv')):
    a0=ev(rows,p_open=.95,part=.91)[2]; a1=ev(rows,p_open=.95,part=.91,m=0.0,rmax=4)[2]
    d=[y-x for x,y in zip(a0,a1)]
    print(nom,'n',len(d),'lie',sum(1 for x in d if abs(x)>1e-9),'pertes>0.03',sum(1 for x in d if x<-0.03),'pertes>0.10',sum(1 for x in d if x<-0.10),'gains>0.03',sum(1 for x in d if x>0.03), 'moy pertes',st.mean([x for x in d if x<0] or [0]))
    for l,x,y in zip(rows,a0,a1):
        if y-x<-0.08:
            recm=max(((c+l['bw'])*(1+0.025*min(max(r-1,0),4)) for c,r,dd in l['rec']),default=0)
            print('   ',l['job'],l['ex'][3:22],'est %.3f->m0 %.3f ; prouve/est %.2f ; est/dm %.2f bw %.0f'%(x,y,recm/l['est'],l['est']/l['dm'],l['bw']))
