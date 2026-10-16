#!/usr/bin/env python3
"""Part de campagne (km2_partie/1) réduite aux 27 profils du banc (sans `ks_`)."""
import gzip, json, sys
src, dst = sys.argv[1], sys.argv[2]
with gzip.open(src, 'rt', encoding='utf-8') as f:
    d = json.load(f)
d['configuration']['profils'] = [p for p in d['configuration']['profils'] if not p.startswith('ks_')]
d['saisons'] = {k: v for k, v in d['saisons'].items() if not k.startswith('ks_')}
with gzip.open(dst, 'wt', encoding='utf-8') as f:
    json.dump(d, f)
print('%s : %d saisons (27 profils)' % (dst, len(d['saisons'])))
