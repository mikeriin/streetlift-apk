import json,glob,os,sys
def saisons(dossier):
    out=[]
    for f in glob.glob(os.path.join(dossier,'*__*__*__*.json')):
        b=os.path.basename(f)
        if b.startswith('mauvais_jour'): continue
        r=json.load(open(f))
        if 'plantage' in r: continue
        out.append(r)
    return out
def unites(S):
    """une ligne par cible : dict(graine, verite, cle, scen, ex, lnT, p, m, s, best, mx, mode, ok)"""
    import math
    rows=[]
    for r in S:
        cle,scen,v,g=r['saison']
        for u in r['calibration']['unites']:
            p4=u['previsions'].get('moins_4_semaines')
            if p4 is None or not p4.get('p'): continue
            for ex,pe in p4['p'].items():
                if ex not in u['reussite_par_cible']: continue
                pj=(p4.get('prevu_jour') or {}).get(ex)
                ob=(u.get('observe') or {}).get(ex)
                rows.append(dict(g=g,v=v,cle=cle,scen=scen,ex=ex,T=u['cibles'][ex],p=pe,m=pj[0] if pj else None,s=pj[1] if pj else None,best=ob[0] if ob else None,mx=ob[1] if ob else None,mode=ob[2] if ob else None,ok=bool(u['reussite_par_cible'][ex])))
    return rows
def deciles(pairs,nmin=30):
    import math
    out=[];pire=None
    for d in range(10):
        sel=[(p,o) for p,o in pairs if min(9,int(math.floor(p*10)))==d]
        if not sel: continue
        pm=sum(p for p,_ in sel)/len(sel); om=sum(1 for _,o in sel if o)/len(sel)
        out.append((d,len(sel),pm,om))
        if len(sel)>=nmin and (pire is None or abs(pm-om)>pire): pire=abs(pm-om)
    return out,pire
