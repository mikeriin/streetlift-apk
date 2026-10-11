import sys,math,statistics as st
sys.path.insert(0,'/tmp/k')
import lire
S=[]
for d in sys.argv[1:]: S+=lire.saisons(d)
U=lire.unites(S)
print('cibles',len(U),'graines',sorted(set(u['g'] for u in U)))
ch=[u for u in U if u['mode']=='loaded']; rp=[u for u in U if u['mode']!='loaded']
print('chargées',len(ch),'réussies',sum(u['ok'] for u in ch),'| reps/tenue',len(rp),'réussies',sum(u['ok'] for u in rp))
for nom,sel in (('toutes',U),('chargées',ch),('reps/tenues',rp)):
    dec,pire=lire.deciles([(u['p'],u['ok']) for u in sel])
    print(nom,'pire écart (n>=30)',pire)
    for d,n,pm,om in dec: print('   d%d n=%4d prévu %.3f observé %.3f'%(d,n,pm,om))
# chargées : anatomie
print('--- chargées : d=(m-lnT)/s ; ln(max)-m ; best/max')
e=[math.log(u['mx'])-u['m'] for u in ch]
print('ln(max du jour) - m : moyenne %+.4f sd %.4f ; s prévu moyen %.4f ; z sd %.3f'%(st.mean(e),st.pstdev(e),st.mean(u['s'] for u in ch),st.pstdev([(math.log(u['mx'])-u['m'])/u['s'] for u in ch])))
r=[u['best']/u['mx'] for u in ch]
print('best/max : moyenne %.4f sd %.4f ; zéros %d ; quantiles'%(st.mean(r),st.pstdev(r),sum(x==0 for x in r)),[round(sorted(r)[int(len(r)*q)],3) for q in (.05,.25,.5,.75,.95)])
cap=[u for u in ch if u['mx']>=u['T']]
print('cible sous le max du jour :',len(cap),'/',len(ch),' ; atteintes parmi elles',sum(u['ok'] for u in cap))
# marge = ln(max/T) vs réussite
for lo,hi in ((-9,-.1),(-.1,-.05),(-.05,-.02),(-.02,0),(0,.02),(.02,.04),(.04,.06),(.06,.1),(.1,9)):
    sel=[u for u in ch if lo<=math.log(u['mx']/u['T'])<hi]
    if sel: print('  ln(max/T) [%+.2f,%+.2f) n=%4d réussite %.3f  p moyen %.3f'%(lo,hi,len(sel),sum(u['ok'] for u in sel)/len(sel),st.mean(u['p'] for u in sel)))
print('--- chargées par d=(m-lnT)/s')
for lo,hi in ((-99,-3),(-3,-2),(-2,-1.5),(-1.5,-1),(-1,-.5),(-.5,0),(0,.5),(.5,1),(1,1.5),(1.5,2),(2,3),(3,99)):
    sel=[u for u in ch if lo<=(u['m']-math.log(u['T']))/u['s']<hi]
    if sel: print('  d [%+.1f,%+.1f) n=%4d réussite %.3f  p moyen %.3f   m-lnT moyen %+.3f'%(lo,hi,len(sel),sum(u['ok'] for u in sel)/len(sel),st.mean(u['p'] for u in sel),st.mean(u['m']-math.log(u['T']) for u in sel)))
print('--- chargées par m-lnT')
for lo,hi in ((-9,-.2),(-.2,-.1),(-.1,-.05),(-.05,0),(0,.03),(.03,.06),(.06,.09),(.09,.12),(.12,.16),(.16,.2),(.2,9)):
    sel=[u for u in ch if lo<=(u['m']-math.log(u['T']))<hi]
    if sel: print('  m-lnT [%+.2f,%+.2f) n=%4d réussite %.3f  p moyen %.3f'%(lo,hi,len(sel),sum(u['ok'] for u in sel)/len(sel),st.mean(u['p'] for u in sel)))
print('--- reps/tenues par m-lnT')
for lo,hi in ((-9,-.3),(-.3,-.15),(-.15,-.05),(-.05,0),(0,.05),(.05,.1),(.1,.2),(.2,9)):
    sel=[u for u in rp if lo<=(u['m']-math.log(u['T']))<hi]
    if sel: print('  m-lnT [%+.2f,%+.2f) n=%4d réussite %.3f  p moyen %.3f  ln(best/max) %.3f'%(lo,hi,len(sel),sum(u['ok'] for u in sel)/len(sel),st.mean(u['p'] for u in sel),st.mean(math.log(max(u['best'],1e-9)/u['mx']) for u in sel)))
