#!/usr/bin/env python3
"""Écrit docs/BASELINE_0_1.md et docs/baseline/CORRECTIONS_PANEL_0_1.md."""
import json, sys, collections, statistics, os

S = os.path.dirname(os.path.abspath(__file__))
rap = json.load(open(sys.argv[1]))
agg = json.load(open('/tmp/panel/base/agg.json'))
OUT = '/home/claude/streetlift-apk/packages/kalis_bench/docs'
prose = open(S + '/baseline_prose.md').read()

NIV = {'beginner': 'débutant', 'intermediate': 'intermédiaire', 'advanced': 'avancé', 'elite': 'élite'}
ECOLES = ['force', 'calisthenie', 'hypertrophie', 'sante']
NOM = {'force': 'Force et streetlifting', 'calisthenie': 'Calisthénie et figures',
       'hypertrophie': 'Hypertrophie', 'sante': 'Endurance, santé, kiné'}
CODES = {
    'plafond_volume': 'Volume au-dessus du plafond',
    'volume_trop_vite': 'Volume trop vite',
    'charge_trop_vite': 'Charge trop vite',
    'tendon_figures': 'Bras tendus trop vite',
    'technique_sans_prerequis': 'Technique sans prérequis',
    'seance_trop_longue': 'Séance trop longue',
    'affutage_absent': 'Pas d\'allègement avant l\'échéance',
}
CRIT = {
    'F1': 'Spécificité et fréquence', 'F2': 'Intensité', 'F3': 'Volume de force',
    'F4': 'Périodisation et progression', 'F5': 'Affûtage, pic et tests',
    'F6': 'Techniques d\'intensification', 'F7': 'Assistance, points faibles, équilibre',
    'F8': 'Sécurité et tolérance', 'F9': 'Faisabilité et clarté',
    'C1': 'Choix des figures, variantes et paliers', 'C2': 'Pratique motrice',
    'C3': 'Dosage des maintiens', 'C4': 'Charge tendineuse', 'C5': 'Force de base',
    'C6': 'Progression et critères de passage', 'C7': 'Préparation articulaire, mobilité',
    'C8': 'Structure', 'C9': 'Faisabilité et clarté',
    'H1': 'Volume par muscle', 'H2': 'Fréquence et répartition',
    'H3': 'Effort et plages de répétitions', 'H4': 'Choix des exercices', 'H5': 'Progression',
    'H6': 'Équilibre et points faibles', 'H7': 'Repos, densité, durée',
    'H8': 'Gestion de la fatigue', 'H9': 'Adéquation au profil et faisabilité',
    'S1': 'Sécurité pour ce profil', 'S2': 'Progressivité', 'S3': 'Récupération et tolérance',
    'S4': 'Endurance de force et cardio', 'S5': 'Santé articulaire et tendineuse',
    'S6': 'Effort et échec', 'S7': 'Adhésion et faisabilité',
    'S8': 'Échéance : tests, affûtage, jour J', 'S9': 'Clarté des consignes',
}
VERD = {'echecs_non_voulus': 'échecs non voulus', 'ecart_rir': 'écart au RIR visé',
        'pics_de_charge': 'pics de charge', 'performance_echeance': 'performance à l\'échéance',
        'deblocages': 'déblocages', 'douleur': 'douleur'}


def f(x):
    return ('%.1f' % x).replace('.', ',')


profs = sorted(rap['profiles'], key=lambda p: (0 if p['key'].startswith('street') else 1, p['key']))
L = []
w = L.append

# --- Panel : école × profil
w('| Profil | Niveau | Force | Calisthénie | Hypertrophie | Santé | Moyenne | Plus basse |')
w('| --- | --- | --- | --- | --- | --- | --- | --- |')
allnotes = []
for p in profs:
    n = agg['notes'][p['key']]
    v = [n[e] for e in ECOLES]
    allnotes += v
    w('| `%s` | %s | %s | %s | %s | %s | %s | **%s** |' % (
        p['key'], NIV.get(p['level'], p['level']), *[f(x) for x in v], f(sum(v) / 4), f(min(v))))
for e in ECOLES:
    pass
st = [agg['notes'][p['key']][e] for p in profs if p['key'].startswith('street') for e in ECOLES]
au = [agg['notes'][p['key']][e] for p in profs if p['key'].startswith('autres') for e in ECOLES]
w('| **Moyenne** | | %s | %s | %s | %s | %s | **%s** |' % (
    *[f(statistics.mean(agg['notes'][p['key']][e] for p in profs)) for e in ECOLES],
    f(statistics.mean(allnotes)), f(min(allnotes))))
T_PANEL = '\n'.join(L)
L.clear()
SYN = 'Moyenne %s/10 ; note la plus basse %s/10 ; note la plus haute %s/10 ; street %s, autres disciplines %s. Aucun des %d programmes n\'atteint 9/10 pour une seule école ; %d notes sur %d sont à 6 ou plus.' % (
    f(statistics.mean(allnotes)), f(min(allnotes)), f(max(allnotes)), f(statistics.mean(st)),
    f(statistics.mean(au)), len(profs), sum(1 for x in allnotes if x >= 6), len(allnotes))

# --- Panel : critères par école
m = collections.defaultdict(list)
for k, v in agg['criteres'].items():
    for e, cs in v.items():
        for c, n in cs.items():
            m[c].append(n)
w('| Critère | Moyenne | Plus basse | Programmes notés |')
w('| --- | --- | --- | --- |')
for c in sorted(m, key=lambda c: ('FCHS'.index(c[0]), int(c[1:]))):
    w('| %s — %s | %s | %s | %d |' % (c, CRIT[c], f(statistics.mean(m[c])), f(min(m[c])), len(m[c])))
T_CRIT = '\n'.join(L)
L.clear()

# --- Sécurité
codes = [c for c in CODES if any(c in p['safetyByCode'] or c in p['realizedSafetyByCode'] for p in profs)]
w('| Profil | ' + ' | '.join(CODES[c] for c in codes) + ' | Total (programme créé) | Total (programme évolué) |')
w('| --- |' + ' --- |' * (len(codes) + 2))
tot = collections.Counter()
tc = tr = 0
for p in profs:
    for c in codes:
        tot[c] += p['safetyByCode'].get(c, 0)
    tc += p['safetyViolations']
    tr += p['realizedSafetyViolations']
    w('| `%s` | ' % p['key'] + ' | '.join(str(p['safetyByCode'].get(c, 0) or '·') for c in codes)
      + ' | **%d** | %d |' % (p['safetyViolations'], p['realizedSafetyViolations']))
w('| **Total** | ' + ' | '.join(str(tot[c]) for c in codes) + ' | **%d** | %d |' % (tc, tr))
T_SAFE = '\n'.join(L)
L.clear()
ZERO = [p['key'] for p in profs if p['safetyViolations'] == 0]

# --- Qualité et attentes
w('| Profil | Qualité (moyenne, 0 à 1) | Attentes tenues | Attentes non tenues (mesure) |')
w('| --- | --- | --- | --- |')
ok = total = 0
for p in profs:
    ko = ['%s : %s' % (c['label'], c['observed']) for c in p['checks'] if not c['ok']]
    ok += p['checksOk']
    total += p['checksTotal']
    w('| `%s` | %s | %d/%d | %s |' % (p['key'], ('%.2f' % p['qualityMean']).replace('.', ','),
                                    p['checksOk'], p['checksTotal'], '<br>'.join(ko) or '—'))
T_ATT = '\n'.join(L)
L.clear()
ATT = '%d attentes tenues sur %d (%d %%)' % (ok, total, round(100 * ok / total))

# --- Trajectoires
w('| Profil | Séances faites | Écart au RIR visé | Cibles atteignables | Gain réel (%/sem) | Performance à l\'échéance | Propositions appliquées | Repères non tenus |')
w('| --- | --- | --- | --- | --- | --- | --- | --- |')
gaps = []
for p in profs:
    t = p['trajectory']
    if t['reachableShare'] > 0:
        gaps.append(t['rirGapReachable'])
    ko = [VERD.get(k, k) for k, v in t['verdicts'].items() if v is False]
    pa = ', '.join('%s × %d' % (k, v) for k, v in (t.get('proposalsApplied') or {}).items()) or 'aucune'
    perf = t.get('meanEventPerformance')
    g = t.get('meanWeeklyGainPercent')
    w('| `%s` | %d/%d | %s | %d %% | %s | %s | %s | %s |' % (
        p['key'], t['sessionsDone'], t['sessionsPlanned'], ('%.2f' % t['rirGapReachable']).replace('.', ','),
        round(100 * t['reachableShare']), '—' if g is None else ('%.2f' % g).replace('.', ','),
        '—' if perf is None else '%d %%' % round(100 * perf), pa, ', '.join(ko) or 'aucun'))
T_TRAJ = '\n'.join(L)
L.clear()
TRAJ = 'Écart moyen au RIR visé : %s répétitions (de %s à %s, hors course) ; %d trajectoires sur %d hors du repère d\'écart au RIR.' % (
    ('%.2f' % statistics.mean(gaps)).replace('.', ','), ('%.2f' % min(gaps)).replace('.', ','),
    ('%.2f' % max(gaps)).replace('.', ','),
    sum(1 for p in profs if p['trajectory']['verdicts'].get('ecart_rir') is False), len(profs))

nb_corr = sum(len(v) for v in agg['necessaires'].values())
out = (prose.replace('{{T_PANEL}}', T_PANEL).replace('{{SYN}}', SYN).replace('{{T_CRIT}}', T_CRIT)
       .replace('{{T_SAFE}}', T_SAFE).replace('{{T_ATT}}', T_ATT).replace('{{ATT}}', ATT)
       .replace('{{T_TRAJ}}', T_TRAJ).replace('{{TRAJ}}', TRAJ).replace('{{NB_CORR}}', str(nb_corr))
       .replace('{{TOTAL_SAFE}}', str(tc)).replace('{{TOTAL_REAL}}', str(tr))
       .replace('{{ZERO}}', ', '.join('`%s`' % z for z in ZERO)).replace('{{NZERO}}', str(len(ZERO))))
out = out.replace('{{T_JAC}}', '\n'.join(l for l in open(S + '/jaccard_public.md').read().replace('.', ',').splitlines() if l.startswith('|')))
assert '{{' not in out, out[out.index('{{'):][:60]
open(OUT + '/BASELINE_0_1.md', 'w').write(out)

# --- Corrections nécessaires, par profil
os.makedirs(OUT + '/baseline', exist_ok=True)
w('# Corrections jugées nécessaires par le panel — moteurs 0.1')
w('')
w('Passe complète du panel du 03/10/2026 sur `kalis_plan` 0.1.0 et `kalis_adapt` 0.1.0 (grilles gelées, `docs/PANEL.md`). '
  'Pour chaque profil : la note d\'ensemble de chaque école, puis chaque correction nécessaire et sa conséquence si elle n\'est pas faite, '
  'telles que les relecteurs les ont écrites. %d corrections au total. Les renvois « R1-P4 » pointent vers `docs/REFERENTIEL.md`.' % nb_corr)
for p in profs:
    k = p['key']
    n = agg['notes'][k]
    w('')
    w('## `%s` — %s' % (k, p['title']))
    w('')
    w('Notes d\'ensemble : ' + ' ; '.join('%s %s' % (NOM[e].lower(), f(n[e])) for e in ECOLES) + '.')
    for e in ECOLES:
        rows = [r for r in agg['necessaires'][k] if r[0] == e]
        if not rows:
            continue
        w('')
        w('**%s**' % NOM[e])
        w('')
        for r in rows:
            w('- %s — *Sinon :* %s' % (r[1].strip().replace('\n', ' '), r[2].strip().replace('\n', ' ')))
open(OUT + '/baseline/CORRECTIONS_PANEL_0_1.md', 'w').write('\n'.join(L) + '\n')
print(SYN); print(ATT); print(TRAJ); print(tc, tr, ZERO)
