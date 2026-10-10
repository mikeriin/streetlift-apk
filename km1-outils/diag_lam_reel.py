# Diagnostic privé : quelles séries déplacent la forme de courbe (LAM) au rejeu réel.
import sys, json, glob
sys.path.insert(0, '.')
from rejeu import journal_app as ja, walk_forward as wf
from koach.moteur import Koach
from koach.modele import LAM
params = wf.charger_params(); fiches = wf.charger_fiches()
import gzip
prog = ja.Programme(ja.lire_json('/tmp/km1-app/prog.json.gz'), ja.lire_json('/tmp/km1-app/koach_program.json.gz'), ja.lire_json('/tmp/km1-app/corr.json'))
conv = ja.convertir(ja.lire_json(glob.glob('/tmp/km1-journal/x/journal_*.json')[0]), prog, fiches)
k = Koach(params, fiches, conv['profil']); m = k.modele
moves = []
for s in conv['seances']:
    for e in s['avant']: k.observe(e)
    k.observe(s['debut'])
    for e in s['series']:
        l0 = m.m[LAM]; k.observe(e); d = m.m[LAM] - l0
        se = e['serie']
        if abs(d) > 0.01: moves.append((round(d,3), s['cle'], se['exerciseId'], se.get('reps'), se.get('externalLoadKg'), se.get('flames'), se.get('failed'), se.get('role')))
    for e in s.get('apres', []): k.observe(e)
    print(s["cle"], round(m.m[LAM],3), round(m.m[19],3))
for x in sorted(moves, key=lambda x:-abs(x[0]))[:40]: print(x)
