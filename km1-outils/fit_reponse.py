import json, math, numpy as np, itertools
rows=json.load(open('/tmp/reponse.json'))
def dose(s,s0,ref=6.0): return (1-np.exp(-s/s0))/(1-math.exp(-ref/s0))
for mode in ('loaded','reps','hold'):
  for kinds in ('a','b','c','abc'):
    R=[r for r in rows if r[0] in kinds and r[2]==mode]
    if len(R)<200: continue
    g=np.array([r[4] for r in R]); lv=np.array([r[1] for r in R]); stim=np.array([[r[5],r[6],r[7]] for r in R]); F=np.array([r[8] for r in R]); wk=np.array([r[3] for r in R])
    best=None
    for k in range(3):
        for s0 in (1.5,2.5,5.0,10.0):
            d=dose(stim[:,k],s0)
            for F0 in (4,6,8,10,12):
                for kap in (0.0,0.25,0.5,0.75,1.0):
                    K=np.clip(1-kap*np.maximum(0,F-F0)/F0,0.2,1.0)
                    for tau in (1e9,40.0):
                        x=d*K/(1+wk/tau)
                        # rho par niveau : moindres carrés
                        rho=[ (g[lv==l]*x[lv==l]).sum()/max(1e-12,(x[lv==l]**2).sum()) for l in range(4)]
                        pred=np.array([rho[l] for l in lv])*x
                        sse=((g-pred)**2).sum()
                        if best is None or sse<best[0]: best=(sse,k,s0,F0,kap,tau,rho)
    sst=((g-np.array([g[lv==l].mean() for l in lv]))**2).sum()
    print(mode,kinds,'n=%d meilleur: stimulus %s s0 %.1f F0 %d kappa %.2f tau %.0f rho %s | R² au-delà du niveau %.3f'%(len(R),['volume','effort','intensité'][best[1]],best[2],best[3],best[4],best[5],[round(float(x),5) for x in best[6]],1-best[0]/sst))
    # modèle fixe de référence : volume s0=5, sans K
    for (k,s0,F0,kap) in ((0,5.0,8,0.0),(0,5.0,8,0.5),(1,2.5,8,0.5),(0,2.5,8,0.5),(0,2.5,6,0.5),(0,2.5,6,0.75)):
        d=dose(stim[:,k],s0); K=np.clip(1-kap*np.maximum(0,F-F0)/F0,0.2,1.0); x=d*K/(1+wk/40.0)
        rho=[ (g[lv==l]*x[lv==l]).sum()/max(1e-12,(x[lv==l]**2).sum()) for l in range(4)]
        pred=np.array([rho[l] for l in lv])*x
        print('    stimulus %d s0 %.1f F0 %d kappa %.2f : R² %.3f rho %s'%(k,s0,F0,kap,1-((g-pred)**2).sum()/sst,[round(float(x),5) for x in rho]))
