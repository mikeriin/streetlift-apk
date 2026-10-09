# setp.py section.cle=json ... : modifie koach_params_v1.json
import sys, json
p='/home/claude/moteurs/packages/kalis_adapt/reference/params/koach_params_v1.json'
d=json.load(open(p))
for a in sys.argv[1:]:
    k,v=a.split('=',1); s,c=k.split('.',1)
    old=d[s].get(c); d[s][c]=json.loads(v); print(k,old,'->',d[s][c])
open(p,'w').write(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
