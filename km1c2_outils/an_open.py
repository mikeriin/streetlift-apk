import json,sys,statistics as st
res=json.load(open(sys.argv[1]))
rows=[]
for r in res:
    for l in r['log']:
        if not l['att']: continue
        dm=l['att'][0][3]; bw=l['bw']
        best=max([a[1] for a in l['att'] if not a[2]] or [0])
        rows.append(dict(l,job=r['job'],dm=dm,best=best/dm, open_ratio=(l['c']+bw)/dm, est_ratio=(l['c_est']+bw)/dm, est_err=l['est']/dm-1, bound=l['c']<l['c_est']-1e-9))
print('n',len(rows),'event',sum(r['ev'] for r in rows))
def desc(name,rs):
    if not rs: print(name,0);return
    print('%-28s n=%4d perf %.3f open/max %.3f est-open/max %.3f est_err mean %+.3f sd %.3f  zero %d  est-open>max %d'%(name,len(rs),st.mean(r['best'] for r in rs),st.mean(r['open_ratio'] for r in rs),st.mean(r['est_ratio'] for r in rs),st.mean(r['est_err'] for r in rs),st.pstdev([r['est_err'] for r in rs]),sum(r['best']==0 for r in rs),sum(r['est_ratio']>1 for r in rs)))
desc('all',rows)
desc('event',[r for r in rows if r['ev']])
desc('non-event',[r for r in rows if not r['ev']])
desc('bound (c<c_est)',[r for r in rows if r['bound']])
desc('bound & coupure',[r for r in rows if r['bound'] and r['coup']>0])
desc('bound & no coupure',[r for r in rows if r['bound'] and r['coup']==0])
desc('not bound',[r for r in rows if not r['bound']])
desc('coupure',[r for r in rows if r['coup']>0])
desc('palier>=1',[r for r in rows if r['pal']>=1])
desc('zone',[r for r in rows if r['zone']])
# bound, how much
import collections
b=[r for r in rows if r['bound']]
print('bound ratio c/c_est totals:',sorted(round((r['c']+r['bw'])/(r['c_est']+r['bw']),2) for r in b))
# among bound: would est-open have failed?
print('bound: est-open would exceed max:',sum(r['est_ratio']>1 for r in b),'of',len(b))
nb=[r for r in rows if not r['bound']]
print('not bound: opener failed:',sum(r['open_ratio']>1 for r in nb),' zero perf:',sum(r['best']==0 for r in nb))
for r in rows:
    if r['best']==0: print('ZERO',r['job'],r['ex'][3:20],'est_err %+.3f sd %.3f open/max %.3f bound %s coup %s'%(r['est_err'],r['sd'],r['open_ratio'],r['bound'],r['coup']))
