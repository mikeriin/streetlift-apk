import pickle,statistics,sys
for f in sys.argv[1:]:
    rows=pickle.load(open(f,'rb'))
    for rk in (6,12):
        R=[r for r in rows if r['rang']==rk]
        ms=[statistics.mean(abs(r['err']) for r in R if r['kind']==k) for k in 'abc']
        print(f,'rang',rk,'MOY %.4f |'%(sum(ms)/3),' '.join('%s %.4f'%(k,m) for k,m in zip('abc',ms)),'| op %.4f'%statistics.mean(abs(r['op']) for r in R),'| couv %.3f'%statistics.mean(1 if abs(r['err'])<=1.645*r['sd'] else 0 for r in R))
        if rk==6:
            for k in 'abc':
                print('    ',k,' '.join('%d: %.4f (%+.3f)'%(lv,statistics.mean(abs(r['err']) for r in R if r['niveau']==lv and r['kind']==k),statistics.mean(r['err'] for r in R if r['niveau']==lv and r['kind']==k)) for lv in range(4)))
