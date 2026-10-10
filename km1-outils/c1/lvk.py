import pickle,statistics,sys
for f in sys.argv[1:]:
    rows=pickle.load(open(f,'rb'))
    for rk in (6,12):
        R=[r for r in rows if r['rang']==rk]
        for k in sorted(set(r['kind'] for r in R)):
            S=[r for r in R if r['kind']==k]
            print(f,'rang',rk,k,'MAE %.4f biais %+.4f | op %.4f (%+.4f) |'%(statistics.mean(abs(r['err']) for r in S),statistics.mean(r['err'] for r in S),statistics.mean(abs(r['op']) for r in S),statistics.mean(r['op'] for r in S)),' '.join('%d: %.4f (%+.3f)'%(lv,statistics.mean(abs(r['err']) for r in S if r['niveau']==lv),statistics.mean(r['err'] for r in S if r['niveau']==lv)) for lv in range(4)))
