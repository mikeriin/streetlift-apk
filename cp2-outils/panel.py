#!/usr/bin/env python3
"""Outil du panel (lot CX) : prépare des dossiers isolés et collecte les notes.

prepare <id_passe> <ecole> <fichier1.md> [<fichier2.md> ...]  -> /tmp/cp2panel/<id_passe>/<ecole>_<n>/
collect <id_passe> -> JSON de toutes les notes de la passe
"""
import json, os, shutil, sys, glob
G = '/home/claude/moteurs/packages/kalis_bench/docs'
GRILLES = {'force': 'force_streetlifting.md', 'calisthenie': 'calisthenie_figures.md',
           'hypertrophie': 'hypertrophie_esthetique.md', 'sante': 'endurance_sante_kine.md'}
ROOT = '/tmp/cp2panel'

def prepare(pid, ecole, files, tag):
    d = f'{ROOT}/{pid}/{ecole}_{tag}'
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(d)
    shutil.copy(f'{G}/grilles/COMMUN.md', f'{d}/COMMUN.md')
    shutil.copy(f'{G}/grilles/{GRILLES[ecole]}', f'{d}/GRILLE.md')
    shutil.copy(f'{G}/REFERENTIEL.md', f'{d}/REFERENTIEL.md')
    mapping = {}
    for i, f in enumerate(files, 1):
        shutil.copy(f, f'{d}/programme_{i}.md')
        mapping[f'programme_{i}.md'] = os.path.basename(f)
    json.dump(mapping, open(f'{ROOT}/{pid}/{ecole}_{tag}.map.json', 'w'))
    print(d)

def collect(pid):
    out = []
    for m in sorted(glob.glob(f'{ROOT}/{pid}/*.map.json')):
        d = m[:-len('.map.json')]
        ecole = os.path.basename(d).split('_')[0]
        mapping = json.load(open(m))
        p = f'{d}/notes.json'
        if not os.path.exists(p):
            print('manque', p, file=sys.stderr); continue
        data = json.load(open(p))
        if isinstance(data, dict):
            data = data.get('programmes') or data.get('notes') or [data]
        for o in data:
            o['ecole'] = ecole
            o['source'] = mapping.get(o.get('programme'), o.get('programme'))
            out.append(o)
    json.dump(out, open(f'{ROOT}/{pid}/toutes.json', 'w'), ensure_ascii=False, indent=1)
    print(len(out))

def build(ci, out):
    """Fichiers notés du panel : programme de la saison tel que les blocs
    l'ont réalisé (export concis), puis la saison simulée (sans redire le
    profil)."""
    import subprocess, re
    os.makedirs(out, exist_ok=True)
    tool = '/home/claude/moteurs/packages/kalis_bench/tool/panel_export.py'
    for js in sorted(glob.glob(f'{ci}/saisons/street_*.json')):
        key = os.path.basename(js)[:-5]
        concise = subprocess.run(['python3', tool, js], capture_output=True, text=True, check=True).stdout
        season = open(f'{ci}/saisons/{key}.md').read()
        season = re.sub(r'\n## Profil\n.*?(?=\n## )', '\n', season, count=1, flags=re.S)
        open(f'{out}/{key}.md', 'w').write(concise.rstrip() + '\n\n---\n\n' + season)
        print(key, len((concise + season).splitlines()))

if __name__ == '__main__':
    if sys.argv[1] == 'build':
        build(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == 'prepare':
        prepare(sys.argv[2], sys.argv[3], sys.argv[5:], sys.argv[4])
    else:
        collect(sys.argv[2])
