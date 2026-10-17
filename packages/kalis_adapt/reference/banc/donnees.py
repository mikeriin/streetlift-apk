# -*- coding: utf-8 -*-
"""Lecture des exports du banc Dart (`dart run bin/km1.dart`, dossier
`donnees/`)."""
import gzip
import json
import os

RACINE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'donnees')
_cache = {}


def lire(nom):
    if nom not in _cache:
        with gzip.open(os.path.join(RACINE, nom), 'rt', encoding='utf-8') as f:
            _cache[nom] = json.load(f)
    return _cache[nom]


def catalogue_infos():
    return lire('catalogue_infos.json.gz')['exercises']


def profils():
    return sorted(f[:-8] for f in os.listdir(os.path.join(RACINE, 'reference')) if f.endswith('.json.gz'))


def saisons_reference(cle):
    """Saisons de référence d'un profil : liste (une par scénario)."""
    saisons = lire('reference/%s.json.gz' % cle)
    base = None
    for s in saisons:
        if s['scenario'] == 'reference':
            base = s
    for s in saisons:
        if s.get('blocks') is None and s.get('blocksAs'):
            s['blocks'] = base['blocks']
    return saisons


def temoin(cle):
    return lire('temoin/%s.json.gz' % cle)
