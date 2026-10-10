"""Tests des outils de vectorisation de Koach (lot GK)."""
import json
import sys
from pathlib import Path

import numpy as np
import pytest

HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))

import build_koach  # noqa: E402
import segment as seg  # noqa: E402
import vectorize as vec  # noqa: E402

REPORT = build_koach.CONTROL_DIR / 'vectorisation.json'


def test_sources_intactes():
    build_koach.check_sources()


def test_trait_de_separation_fin_conserve_et_regularise():
    lum = np.full((200, 200), 255.0)
    lum[40:160, 40:160] = 0.0
    lum[100:103, 40:160] = 230.0  # liseré clair de 3 px à travers le carré
    ink, lines, rep = seg.clean_ink(lum)
    assert rep.line_parts >= 1
    # Le trait devient du papier d'au moins 7 px d'épaisseur.
    col = lines[:, 100]
    assert col[95:108].sum() >= 7
    assert not ink[101, 100]
    # Le reste du carré reste de l'encre.
    assert ink[60, 60] and ink[140, 140]


def test_poussieres_supprimees():
    lum = np.full((100, 100), 255.0)
    lum[10:13, 10:13] = 0.0  # 9 px : poussière d'encre
    lum[40:90, 40:90] = 0.0
    lum[60:62, 60:62] = 255.0  # 4 px : poussière de papier
    ink, _, rep = seg.clean_ink(lum)
    assert not ink[11, 11]
    assert ink[61, 61]
    assert rep.ink_specks == 1


def test_decoupe_refuse_une_case_vide():
    ink = np.zeros((100, 200), bool)
    ink[10:90, 10:90] = True
    with pytest.raises(seg.SegmentationError):
        seg.split_sheet(ink, 2, 1, 'T')


def test_decoupe_rattache_les_accessoires():
    ink = np.zeros((100, 200), bool)
    ink[10:90, 10:60] = True     # silhouette case 0
    ink[20:30, 70:90] = True     # accessoire case 0
    ink[10:90, 110:160] = True   # silhouette case 1
    lab, cells = seg.split_sheet(ink, 2, 1, 'T')
    assert len(cells[0].labels) == 2
    assert len(cells[1].labels) == 1


def test_commandes_aller_retour_et_rendu_pair_impair():
    m = np.zeros((60, 60), bool)
    m[5:55, 5:55] = True
    m[20:40, 20:40] = False  # anneau
    curves = vec.trace(m, 0)
    assert sorted(vec.nesting_depths(curves)) == [0, 1]
    cmds = vec.to_commands(curves, float, float)
    subs = vec.parse_commands(cmds)
    assert len(subs) == 2
    cov = vec.render_evenodd(cmds, (60, 60), float, float)
    assert vec.iou(cov, m) > 0.97
    assert cov[30, 30] < 0.01  # le trou reste vide (pair-impair)


def test_profondeurs_d_imbrication():
    m = np.zeros((80, 80), bool)
    m[5:75, 5:75] = True
    m[15:65, 15:65] = False
    m[25:55, 25:55] = True
    depths = sorted(vec.nesting_depths(vec.trace(m, 0)))
    assert depths == [0, 1, 2]


def test_rapport_de_vectorisation():
    rep = json.loads(REPORT.read_text(encoding='utf-8'))
    assert len(rep['poses']) == 36
    assert len(rep['flames']) == 10
    assert rep['iou_min'] >= 0.97
    assert rep['iou_raw_min'] >= 0.97
    assert rep['flame_iou_min'] >= 0.97
    assert sum(rep['sizes'].values()) <= 400_000
    ids = [p['id'] for p in rep['poses']]
    assert len(set(ids)) == 36


def test_dart_genere_a_jour():
    """Régénère tout en mémoire et compare au Dart commité (déterminisme)."""
    assert build_koach.main(['--check']) == 0
