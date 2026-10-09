import json,sys,collections
d=json.load(open(sys.argv[1]))
tab=collections.defaultdict(dict)
for o in d:
  v=o['ensemble']; v=v['note'] if isinstance(v,dict) else v
  tab[o['source'][:-3]][o['ecole']]=float(v)
S=['force','calisthenie','hypertrophie','sante']
for grp in ('street','autres'):
  ks=[k for k in sorted(tab) if k.startswith(grp)]
  vals=[tab[k][e] for k in ks for e in S if e in tab[k]]
  print(f"{grp}: {sum(v>=9 for v in vals)}/{len(vals)} à 9, min {min(vals)}, moy {sum(vals)/len(vals):.2f}")
  for k in ks: print('  ',k[:28].ljust(28),' / '.join(str(tab[k].get(e,'-')) for e in S))
json.dump(tab,open(sys.argv[1].replace('.json','_tab.json'),'w'))
