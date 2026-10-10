# -*- coding: utf-8 -*-
"""CONTRAT_1_0.md et SOURCES.md décrivent exactement le fichier de
paramètres : mêmes clés, mêmes valeurs scalaires, même empreinte."""
import hashlib
import json
import os
import re

ICI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _lire(nom):
    with open(os.path.join(ICI, nom), encoding='utf-8') as f:
        return f.read()


def _params():
    return json.loads(_lire('params/koach_params_v1.json'))


def _cles(p):
    out = []
    for sec, v in p.items():
        if isinstance(v, dict):
            for k, x in v.items():
                out.append((sec, k, x))
        else:
            out.append((None, sec, v))
    return out


def test_empreinte_des_parametres():
    with open(os.path.join(ICI, 'params', 'koach_params_v1.json'), 'rb') as f:
        sha = hashlib.sha256(f.read()).hexdigest()
    assert sha in _lire('CONTRAT_1_0.md') and sha in _lire('SOURCES.md')


def test_sources_une_ligne_par_cle_et_valeurs():
    texte = _lire('SOURCES.md')
    lignes = {}
    for m in re.finditer(r'^\| `([A-Za-z0-9_]+)` \| (.*?) \| (référence publiée vérifiée|mesure sur le banc|'
                         r'repris de 0\.3\.1|choix raisonné) \|', texte, re.M):
        lignes.setdefault(m.group(1), []).append(m.group(2))
    manquantes = [k for (_, k, _) in _cles(_params()) if k not in lignes]
    assert not manquantes, manquantes
    faux = []
    for (_, k, v) in _cles(_params()):
        if isinstance(v, (int, float)) and not isinstance(v, bool):
            if not any(json.dumps(v) == val.strip() for val in lignes[k]):
                faux.append((k, v, lignes[k]))
    assert not faux, faux


def test_contrat_tableau_des_cles():
    texte = _lire('CONTRAT_1_0.md')
    vus = {}
    for m in re.finditer(r'^\| ([a-z_]+|—|racine) \| `([A-Za-z0-9_]+)` \| (.*?) \|', texte, re.M):
        vus.setdefault(m.group(2), []).append(m.group(3))
    manquantes = [k for (_, k, _) in _cles(_params()) if k not in vus]
    assert not manquantes, manquantes
    faux = []
    for (_, k, v) in _cles(_params()):
        if isinstance(v, (int, float)) and not isinstance(v, bool):
            if not any(json.dumps(v) == val.strip() for val in vus[k]):
                faux.append((k, v, vus[k]))
    assert not faux, faux
