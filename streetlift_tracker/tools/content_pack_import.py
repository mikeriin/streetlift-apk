"""Intègre le pack de contenu Kalis Track (L9R, 2.0.0) dans l'application (L9b, KT-079/080).

Entrée : le dossier `kalis_content_pack_v2/` extrait de `kalis_content_pack_v1_final.zip`.
Sorties (reproductibles, gzip sans horodatage) :
  assets/content/index.json.gz        index léger chargé au démarrage (recherche, filtres,
                                        correspondance des anciens noms et du programme)
  assets/content/details.json.gz      fiches complètes (chargées à l'ouverture d'une fiche)
  assets/content/sources.json.gz      sources consultées par exercice (fiche, section repliée)
  assets/content/poses.json.gz        gabarits de démonstration (sans les positions calculées)
  assets/content/progressions.json.gz arbres de progression
  assets/content/licences.md          mentions (écran « Sources et licences »)
  assets/content/pack.json            version et empreinte du pack intégré
  lib/atlas_data.dart                 atlas musculaire (régions polygonales) et taxonomie
  test/fixtures/l9b/*                 fixtures de migration et de concordance du rendu

Les champs de l'ancienne base (`n`, `g`, `eq`) sont conservés pour les 505 exercices v1 :
l'historique, les records, les séances personnelles et la carte de STATS gardent ainsi
exactement les mêmes clés (aucune donnée utilisateur réécrite).
"""
import argparse
import gzip
import hashlib
import json
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# Matériel du pack → libellé de l'ancienne base (`eq`) pour les exercices ajoutés.
EQ_V1 = {
    'barre_fixe': 'barre fixe', 'barre_basse': 'barre fixe', 'barres_paralleles': 'barres parallèles',
    'anneaux': 'anneaux', 'barre': 'barre', 'disques': 'barre', 'banc': 'barre', 'halteres': 'haltères',
    'kettlebell': 'kettlebell', 'elastique': 'élastique', 'lest': 'lest', 'sac_leste': 'sac lesté',
    'medecine_ball': 'médecine-ball', 'corde_a_sauter': 'corde à sauter', 'machine': 'machine',
    'poulie': 'machine, poulie', 'box': 'box',
}
EQ_ORDER = list(EQ_V1)
DETAIL_DROP = {'sources', 'provenance', 'sources_meta', 'v1', 'alias', 'nom'}
PARITY_IDS = [
    'ab-wheel', 'back-squat', 'australian-pull-ups-rows-barre-basse', 'dips', 'pompes', 'muscle-up',
    'hip-thrust', 'souleve-de-terre', 'developpe-couche', 'rowing-barre-penche', 'burpees',
    'jumping-jacks', 'fentes-avant', 'planche-advanced-tuck', 'front-lever-advanced-tuck', 'l-sit',
    'kettlebell-swing', 'atr-poitrine-au-mur-tenue', 'corde-a-sauter', 'curl-halteres',
]


def gz(path, obj):
    raw = json.dumps(obj, ensure_ascii=False, separators=(',', ':'), sort_keys=True).encode()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(gzip.compress(raw, compresslevel=9, mtime=0))
    return len(raw), path.stat().st_size


def v1_equipment(materiel):
    for key in EQ_ORDER:
        if key in materiel:
            return EQ_V1[key]
    return 'poids de corps'


def groups_of(muscle_ids, muscles, order):
    found = {muscles[m]['groupe'] for m in muscle_ids if m in muscles}
    return [g for g in order if g in found]


def build_index(ex, muscles, order, mapping):
    vocab = ex['vocabulaires']
    entries = []
    for e in ex['exercices']:
        v1 = e.get('v1')
        if v1:
            n, g, eq = v1['nom'], v1['groupe'], v1['materiel']
        else:
            n = e['nom']
            g = ', '.join(groups_of(e['muscles_primaires'], muscles, order)) or 'divers'
            eq = v1_equipment(e['materiel'])
        entries.append({
            'id': e['id'], 'nom': e['nom'], 'n': n, 'g': g, 'eq': eq, 'v1': bool(v1),
            'alias': e.get('alias') or [], 'type': e['type_mouvement'], 'lieux': e['lieux'],
            'materiel': e['materiel'], 'difficulte': e['difficulte'], 'demo': e['pose']['statut'],
            'generateur': e['generateur'], 'doublon_de': e.get('doublon_de'),
            'groupes': groups_of(e['muscles_primaires'] + e['muscles_secondaires'], muscles, order),
            'muscles': e['muscles_primaires'] + e['muscles_secondaires'],
        })
    names = [x['n'] for x in entries]
    assert len(names) == len(set(names)), 'noms en double dans la base'
    return {
        'version': ex['version'], 'schema': ex['schema'],
        'vocabulaires': {
            'types_mouvement': vocab['types_mouvement'], 'lieux': vocab['lieux'],
            'materiel': {k: v['libelle'] for k, v in vocab['materiel'].items()},
            'muscles': vocab['muscles'],
        },
        'exercices': entries,
        'base_v1': mapping['base_v1'],
        'programme_v33': {k: {'id': v['id'], 'methodes': v['methodes']} for k, v in mapping['programme_v33'].items()},
    }


def build_details(ex):
    vocab = ex['vocabulaires']
    return {
        'vocabulaires': {k: vocab[k] for k in ('zones', 'modes_charge', 'mesures', 'precautions', 'methodes', 'muscles_familles')},
        'exercices': {e['id']: {k: v for k, v in e.items() if k not in DETAIL_DROP} for e in ex['exercices']},
    }


def build_poses(poses):
    gabarits = {}
    for name, g in poses['gabarits'].items():
        gabarits[name] = {
            'vue': g['vue'], 'boucle': g['boucle'], 'accessoires': g.get('accessoires') or [],
            'images_cles': [{
                'label': k['label'], 'angles': k['angles'], 'bassin': k['bassin'], 'anchor': k['anchor'],
                'hold': k['hold'], 'dur': k['dur'],
            } for k in g['images_cles']],
        }
    exercices = {i: {k: e.get(k) for k in ('gabarit', 'statut', 'motif', 'accessoires', 'retirer', 'muscles')}
                 for i, e in poses['exercices'].items()}
    return {'version': poses['version'], 'gabarits': gabarits, 'exercices': exercices}


def atlas_dart(svg_text, muscles_doc):
    region = re.compile(r'<path id="([^"]+)" class="(corps|muscle|repere)"([^>]*?) d="([^"]+)"')
    out = []
    for m in region.finditer(svg_text):
        rid, kind, attrs, d = m.groups()
        view = 'face' if rid.startswith('face') else 'dos'
        muscle = re.search(r'data-muscle="([^"]+)"', attrs)
        side = re.search(r'data-side="([^"]+)"', attrs)
        closed = d.strip().endswith('Z')
        nums = [float(x) for x in re.findall(r'-?\d+(?:\.\d+)?', d)]
        pts = ' '.join(f'{nums[i]:g} {nums[i + 1]:g}' for i in range(0, len(nums), 2))
        out.append((view, kind, muscle.group(1) if muscle else None, side.group(1) if side else None, closed, pts))
    assert sum(1 for r in out if r[1] == 'muscle') >= 100, 'atlas incomplet'
    lines = [
        '// GÉNÉRÉ par tools/content_pack_import.py depuis atlas.svg et muscles.json',
        f"// (pack de contenu {muscles_doc['version']}). Ne pas modifier à la main.",
        '',
        '/// Région de l\'atlas : polygone en coordonnées locales à la vue (300 × 760).',
        'class AtlasRegion {',
        '  final String view, kind;',
        '  final String? muscle, side;',
        '  final bool closed;',
        '  final String points;',
        '  const AtlasRegion(',
        '    this.view,',
        '    this.kind,',
        '    this.muscle,',
        '    this.side,',
        '    this.closed,',
        '    this.points,',
        '  );',
        '}',
        '',
        '/// Muscle de la taxonomie du pack (81 entrées).',
        'class AtlasMuscle {',
        '  final String nom, famille, groupe, profondeur;',
        '  final List<String> vues;',
        '  const AtlasMuscle(',
        '    this.nom,',
        '    this.famille,',
        '    this.groupe,',
        '    this.profondeur,',
        '    this.vues,',
        '  );',
        '}',
        '',
        'const atlasViewWidth = 300.0;',
        'const atlasViewHeight = 760.0;',
        '',
        f"const atlasGroups = <String>[{', '.join(repr_dart(g) for g in muscles_doc['groupes_app'])}];",
        '',
        'const atlasRegions = <AtlasRegion>[',
    ]
    for view, kind, muscle, side, closed, pts in out:
        lines.append(
            f"  AtlasRegion({repr_dart(view)}, {repr_dart(kind)}, {repr_dart(muscle)}, {repr_dart(side)}, "
            f"{'true' if closed else 'false'}, {repr_dart(pts)}),")
    lines.append('];')
    lines.append('')
    lines.append('const atlasMuscles = <String, AtlasMuscle>{')
    for mu in muscles_doc['muscles']:
        vues = ', '.join(repr_dart(v) for v in mu['vues'])
        lines.append(
            f"  {repr_dart(mu['id'])}: AtlasMuscle({repr_dart(mu['nom'])}, {repr_dart(mu['famille'])}, "
            f"{repr_dart(mu['groupe'])}, {repr_dart(mu['profondeur'])}, [{vues}]),")
    lines.append('};')
    return '\n'.join(lines) + '\n'


def repr_dart(value):
    if value is None:
        return 'null'
    return "'" + str(value).replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"


def parity_fixture(pack, poses_doc, out):
    """Positions de référence calculées par le moteur JS du pack (20 exercices × 5 instants)."""
    ids = [i for i in PARITY_IDS if i in poses_doc['exercices'] and poses_doc['exercices'][i]['statut'] == 'disponible']
    for i, e in poses_doc['exercices'].items():  # complète jusqu'à 20 si un id manque
        if len(ids) >= 20:
            break
        if e['statut'] == 'disponible' and i not in ids:
            ids.append(i)
    script = r"""
const P = require(process.argv[1]);
const poses = require(process.argv[2]);
const ids = JSON.parse(process.argv[3]);
const out = [];
for (const id of ids) {
  const e = poses.exercices[id];
  const g = poses.gabarits[e.gabarit];
  const pose = P.fromPack(g, e);
  const total = P.duration(pose);
  const instants = [0, 0.13, 0.37, 0.61, 0.89].map((f) => +(f * total).toFixed(4));
  out.push({ id, gabarit: e.gabarit, view: pose.view, duration: total, bbox: P.bbox(pose),
    samples: instants.map((t) => ({ t, joints: P.jointsAt(pose, t) })) });
}
process.stdout.write(JSON.stringify(out));
"""
    res = subprocess.run(
        ['node', '-e', script, str(pack / 'renderer_reference/kt_pose.js'), str(pack / 'poses.json'), json.dumps(ids)],
        check=True, capture_output=True, text=True)
    data = json.loads(res.stdout)
    assert len(data) == 20, len(data)
    out.write_text(json.dumps({'reference': 'renderer_reference/kt_pose.js 2.0.0', 'exercices': data},
                              ensure_ascii=False, separators=(',', ':')) + '\n')


def main(pack, root=ROOT, pack_sha=None, with_parity=True):
    pack = Path(pack)
    ex = json.loads((pack / 'exercises_v2.json').read_text())
    muscles_doc = json.loads((pack / 'muscles.json').read_text())
    mapping = json.loads((pack / 'mapping_v1_to_v2.json').read_text())
    poses = json.loads((pack / 'poses.json').read_text())
    progressions = json.loads((pack / 'progressions.json').read_text())
    muscles = {m['id']: m for m in muscles_doc['muscles']}
    order = muscles_doc['groupes_app']
    content = root / 'assets/content'
    report = {}
    report['index'] = gz(content / 'index.json.gz', build_index(ex, muscles, order, mapping))
    report['details'] = gz(content / 'details.json.gz', build_details(ex))
    report['sources'] = gz(content / 'sources.json.gz', {e['id']: e['sources'] for e in ex['exercices']})
    poses_app = build_poses(poses)
    report['poses'] = gz(content / 'poses.json.gz', poses_app)
    report['progressions'] = gz(content / 'progressions.json.gz', progressions)
    shutil.copyfile(pack / 'licences.md', content / 'licences.md')
    meta = {
        'pack': '2.0.0', 'archive': 'kalis_content_pack_v1_final.zip', 'sha256': pack_sha,
        'schema_exercice': ex['schema'], 'exercices': len(ex['exercices']), 'muscles': len(muscles),
        'gabarits': len(poses['gabarits']), 'progressions': len(progressions['chaines']),
    }
    (content / 'pack.json').write_text(json.dumps(meta, ensure_ascii=False, indent=1) + '\n')
    (root / 'lib/atlas_data.dart').write_text(atlas_dart((pack / 'atlas.svg').read_text(), muscles_doc))
    fixtures = root / 'test/fixtures/l9b'
    fixtures.mkdir(parents=True, exist_ok=True)
    if with_parity:
        parity_fixture(pack, poses, fixtures / 'pose_parity.json')
    # Positions calculées par le pack pour chaque image clé (test de concordance complet).
    keyframes = {name: [k['joints'] for k in g['images_cles']] for name, g in poses['gabarits'].items()}
    gz(fixtures / 'keyframe_joints.json.gz', keyframes)
    return report, meta


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('pack', type=Path, help='dossier kalis_content_pack_v2 extrait')
    parser.add_argument('--zip', type=Path, help='archive du pack (empreinte enregistrée)')
    parser.add_argument('--no-parity', action='store_true', help='sans Node : ne régénère pas pose_parity.json')
    args = parser.parse_args()
    sha = hashlib.sha256(args.zip.read_bytes()).hexdigest() if args.zip else None
    rep, meta = main(args.pack, pack_sha=sha, with_parity=not args.no_parity)
    for k, (raw, packed) in rep.items():
        print(f'{k}: {raw} -> {packed} octets')
    print(json.dumps(meta, ensure_ascii=False))
