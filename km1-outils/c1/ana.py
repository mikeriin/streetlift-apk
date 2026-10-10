import pickle,sys,statistics
def st(S,key='err'):
    v=[r[key] for r in S]
    return 'n=%3d MAE %.4f biais %+.4f'%(len(v),statistics.mean(abs(x) for x in v),statistics.mean(v)) if v else 'n=0'
for f in sys.argv[1:]:
    rows=[r for r in pickle.load(open(f,'rb')) if r['seed']<int(__import__('os').environ.get('NS','99'))]
    rk=6
    R=[r for r in rows if r['rang']==rk]
    ms=[]
    print('==',f)
    for k in 'abc':
        S=[r for r in R if r['kind']==k]
        ms.append(statistics.mean(abs(r['err']) for r in S))
        print(' vérité',k,st(S),'| op',st(S,'op'),'| sd %.3f'%statistics.mean(r['sd'] for r in S), '| couv %.2f'%statistics.mean(1 if abs(r['err'])<=1.645*r['sd'] else 0 for r in S))
        for lv in range(4):
            T=[r for r in S if r['niveau']==lv]
            if T and not __import__('os').environ.get('COURT'): print('    niv',lv,st(T),'| op',st(T,'op'))
    print(' MOYENNE A,B,C rang 6 : %.4f'%(sum(ms)/3), ' rang 3: %.4f rang 12: %.4f'%tuple(statistics.mean(abs(r['err']) for r in rows if r['rang']==q) for q in (3,12)))
