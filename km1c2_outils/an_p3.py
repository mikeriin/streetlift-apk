import sys,math
sys.path.insert(0,'/tmp/k')
import lire
D=sys.argv[1]
S=lire.saisons(D)
print('saisons',len(S))
d0=0.015
def cov(pairs,x):
    n=c=0
    for e,sd in pairs:
        v=sd*sd-d0*d0+x*x
        s=math.sqrt(v) if v>0 else 0.0
        n+=1; c+= (e<=1.6448536269514722*s)
    return c/n if n else None
by={}
for r in S:
    g=r['saison'][3]
    by.setdefault(g,[]).extend(r['estimations'].get('couverture_paires') or [])
allp=[p for g in by for p in by[g]]
print('n',len(allp),{g:len(by[g]) for g in sorted(by)})
for x in (0.0,0.005,0.008,0.010,0.012,0.015,0.02):
    print('x=%.3f tout %.4f '%(x,cov(allp,x)),' '.join('g%d %.4f'%(g,cov(by[g],x)) for g in sorted(by)))
# officiel (rows) pour comparaison
n=c=0
for r in S:
    rows=r['estimations']['loadedMain']['rows']
    for k in range(3,len(rows)):
        n+=rows[k][0]; c+=rows[k][5]
print('officiel (rows)',c/n,n)
import statistics as st
print('sd moyen',st.mean(sd for e,sd in allp),'|e| moyen',st.mean(e for e,sd in allp))
def covk(pairs,x,k):
    n=c=0
    for e,sd in pairs:
        v=sd*sd-d0*d0
        s=math.sqrt((v if v>0 else 0)*k*k+x*x)
        n+=1; c+=(e<=1.6448536269514722*s)
    return c/n
print('--- échelle k sur la part du filtre, x = défaut')
for x in (0.0,0.010,0.015):
    for k in (1.0,0.95,0.9,0.85,0.8):
        print('x=%.3f k=%.2f tout %.4f '%(x,k,covk(allp,x,k)),' '.join('g%d %.4f'%(g,covk(by[g],x,k)) for g in sorted(by)))
# distribution de z=e/sd
zs=sorted(e/sd for e,sd in allp)
print('quantiles de |e|/sd : 50%% %.3f 80%% %.3f 90%% %.3f 95%% %.3f 99%% %.3f'%tuple(zs[int(len(zs)*q)] for q in (.5,.8,.9,.95,.99)))
# par tranche de sd
import statistics as st
for lo,hi in ((0,.04),(.04,.05),(.05,.06),(.06,.08),(.08,.1),(.1,.2),(.2,9)):
    sel=[(e,sd) for e,sd in allp if lo<=sd<hi]
    if sel: print('sd [%.2f,%.2f) n %5d couverture %.4f  |e| moy %.4f'%(lo,hi,len(sel),sum(e<=1.645*sd for e,sd in sel)/len(sel),st.mean(e for e,sd in sel)))
print('--- par tranche de sd (du filtre) pour des couples (x,k)')
def filt(sd): 
    v=sd*sd-d0*d0
    return math.sqrt(v) if v>0 else 0.0
bands=((0,.03),(.03,.045),(.045,.06),(.06,.08),(.08,.12),(.12,.2),(.2,9))
for (x,k) in ((0.015,1.0),(0.0,0.925),(0.005,0.92),(0.010,0.90),(0.012,0.88),(0.015,0.85),(0.0,0.90)):
    out=[]
    for lo,hi in bands:
        sel=[(e,sd) for e,sd in allp if lo<=filt(sd)<hi]
        out.append('%.3f'%(sum(e<=1.6448536269514722*math.sqrt((filt(sd)*k)**2+x*x) for e,sd in sel)/len(sel)) if sel else '  -  ')
    print('x=%.3f k=%.3f tout %.4f |'%(x,k,covk(allp,x,k)),' '.join(out), '| g:',' '.join('%.3f'%covk(by[g],x,k) for g in sorted(by)))
print('effectifs',[sum(1 for e,sd in allp if lo<=filt(sd)<hi) for lo,hi in bands])
