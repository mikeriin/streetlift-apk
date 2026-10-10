import math, numpy as np
from scipy.optimize import least_squares
G8=0.0265*7
def bc(R,g):
    a=math.log(R); x=g*a
    return a*((math.exp(x)-1)/x if abs(x)>1e-6 else 1+x/2)
def g(R,lam,k):
    gam=1-lam
    return math.exp(k)*G8*bc(R,gam)/bc(8,gam)
eqs={
 'Brzycki (1993)': lambda r: (37-r)/36,
 'Epley (1985)': lambda r: 1/(1+r/30) if r>1 else 1.0,
 'Lander (1985)': lambda r: (101.3-2.67123*r)/100,
 'Lombardi (1989)': lambda r: r**-0.10,
 'Mayhew et al. (1992)': lambda r: (52.2+41.9*math.exp(-0.055*r))/100,
 "O'Conner et al. (1989)": lambda r: 1/(1+0.025*r),
 'Wathen (1994)': lambda r: (48.8+53.8*math.exp(-0.075*r))/100,
 'vérité A (haut)': lambda r: 0.3+0.7*math.exp(-0.044*(r-1)),
 'vérité A (bas)': lambda r: 0.3+0.7*math.exp(-0.036*(r-1)),
 'vérité B (haut)': lambda r: 1-0.0278*(r-1),
 'vérité B (bas)': lambda r: 1-0.0236*(r-1),
 'vérité C (haut)': lambda r: r**-0.10,
 'vérité C (bas)': lambda r: r**-0.085,
}
Rs=list(range(2,21))
for nm,f in eqs.items():
    # normalise à 1 répétition (les équations publiées ne valent pas toutes 1 à r = 1)
    y=np.array([-math.log(f(r)/f(1)) for r in Rs])
    res=least_squares(lambda p:[g(r,p[0],p[1])-yy for r,yy in zip(Rs,y)],[0.3,0.0])
    lam,k=res.x
    err=max(abs(g(r,lam,k)-yy) for r,yy in zip(Rs,y))
    print('%-24s lam %+.2f k %+.3f  écart max %.4f | g2 %.3f g4 %.3f g7 %.3f g12 %.3f g18 %.3f'%(nm,lam,k,err,*[ -math.log(f(r)/f(1)) for r in (2,4,7,12,18)]))
