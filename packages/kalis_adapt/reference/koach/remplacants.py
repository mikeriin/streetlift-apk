# -*- coding: utf-8 -*-
"""Koach 1.0.9 (KM7, DECISIONS_CP.md C17.54) : remplaçants d'une ligne en
séance, selon la raison et le matériel du jour.

    remplacants(infos, demande, koach=None) -> {'exerciseId', 'raison',
        'remplacants': [{exerciseId, nom, etiquette, texte, unite, depart,
        score}], 'regles': {...}}

[infos] : fiches du catalogue (format de `donnees/catalogue_infos.json.gz`,
`koachInfosRemplacement` en Dart) ; [demande] : la ligne servie et la raison
(voir `remplacants`). Sans [koach], aucune cible de départ (source None).

Étiquettes (choix raisonnés, dits dans CHANGEMENTS_1_0_9.md) :

- « equivalent » : même schéma de mouvement, mêmes muscles principaux, même
  mode (charge, répétitions, tenue) et même qualité (dynamique, explosive,
  isométrique, excentrique), difficulté de −2 à +1 de la ligne, sans
  assistance ;
- « plus_facile » : même schéma et mêmes muscles principaux, difficulté plus
  basse (variantes assistées comprises) ;
- « sans_materiel » (raison `pas_de_materiel`) : même schéma (ou sa version
  explosive) et mêmes muscles principaux, autre mode ou autre qualité (le
  dip lesté sans ceinture devient un dip au poids du corps) ;
- « autre » : autre schéma de la même famille, au moins un muscle principal
  commun ; jamais pour une ligne principale (`main`) ni une figure
  (`skill`) : leur schéma est le but de la ligne.

Filtres durs : faisable avec le matériel du jour (celui du profil s'il est
donné, sinon celui de la ligne écrite moins le manquant ; sol, tapis,
magnésie toujours, mur sauf au parc), au lieu du jour, niveau au plus celui
de l'athlète (ou de la ligne), ni détesté, ni « je ne sais pas faire », ni
exclu ; douleur : **jamais** un exercice qui sollicite la zone signalée
(niveau de zone > 0 ou zone qui arrête le mouvement) ; `trop_dur` : jamais
plus difficile que la ligne.
"""
import math

from .seance import Grille, rir_de_flammes

ETIQUETTES = ('equivalent', 'plus_facile', 'sans_materiel', 'autre')

#: Ordre des étiquettes selon la raison.
ORDRE = {
    'pas_de_materiel': ('equivalent', 'sans_materiel', 'plus_facile', 'autre'),
    'douleur': ('equivalent', 'plus_facile', 'sans_materiel', 'autre'),
    'trop_dur': ('plus_facile', 'equivalent', 'autre'),
    'autre': ('equivalent', 'plus_facile', 'sans_materiel', 'autre'),
}

#: Matériel qui ne bloque jamais (`alwaysAvailableEquipment` de kalis_core) ;
#: le mur est lié au lieu (`placeBoundEquipment` : maison et salle).
TOUJOURS = ('aucun (sol)', 'mur', 'tapis', 'magnésie')
MUR_LIEUX = ('maison', 'salle')

#: Transferts de charge (`coachLoadReferences` de kalis_plan 0.4.3) :
#: variante -> (référence, 1RM total de la variante / 1RM total de la
#: référence). Sens inverse (référence servie à la place de la variante) :
#: facteur 1 (prudent, jamais de hausse par transfert).
TRANSFERTS = {
    'sl-traction-haute-lestee': ('sl-traction-lestee', 0.85),
    'sl-dips-barre-fixe-leste': ('sl-dips-leste', 0.9),
}

#: Rôles dont le schéma est le but de la ligne (pas d'« autre » schéma).
ROLES_SCHEMA = ('main', 'skill')

PAR_ETIQUETTE = 3
LIMITE = 8
#: Rang dans une étiquette : la variante de base d'une chaîne d'abord
#: (choix raisonné : 0,08 de proximité par niveau de profondeur).
PENALITE_PROFONDEUR = 0.08

#: Fourchette d'une plage convertie (répétitions ou secondes) : bas = 80 %
#: du haut (choix raisonné : une plage de 8-10 répétitions).
PART_BAS = 0.8

NOMS_MATERIEL_MAX = 3


def _qualite(i):
    cm = i.get('contractionMode')
    if cm == 'explosive' or i.get('slotKind') == 'power':
        return 'explosive'
    if cm == 'isometric':
        return 'isometrique'
    if cm == 'eccentric':
        return 'excentrique'
    return 'dynamique'


def _groupes(i, seuil):
    return [g for g, w in zip(i.get('groups') or [], i.get('groupWeights') or []) if w >= seuil - 1e-9]


def _muscles_ok(o, c):
    """Mêmes muscles principaux : chaque muscle principal de la ligne est
    travaillé par le candidat (principal ou secondaire), et au moins la
    moitié des principaux sont aussi principaux du candidat."""
    po = _groupes(o, 1.0)
    if not po:
        return False
    gc = set(_groupes(c, 0.5))
    pc = set(_groupes(c, 1.0))
    if any(g not in gc for g in po):
        return False
    return len(pc & set(po)) >= max(1, int(math.ceil(len(po) / 2.0)))


def _commun(o, c):
    return bool(set(_groupes(o, 1.0)) & set(_groupes(c, 1.0)))


def _cosinus(o, c):
    a = {}
    for g, w in zip(o.get('groups') or [], o.get('groupWeights') or []):
        a[g] = w
    b = {}
    for g, w in zip(c.get('groups') or [], c.get('groupWeights') or []):
        b[g] = w
    na = math.sqrt(sum(v * v for v in a.values()))
    nb = math.sqrt(sum(v * v for v in b.values()))
    if na <= 0 or nb <= 0:
        return 0.0
    return sum(a[g] * b[g] for g in a if g in b) / (na * nb)


def score(o, c):
    """Proximité (0..1), poids de `Catalog.similarity` de kalis_core :
    muscles 0,55 (cosinus des groupes), schéma 0,20, chaîne de variantes
    0,15, difficulté 0,10."""
    s = 0.55 * _cosinus(o, c)
    if c.get('pattern') == o.get('pattern'):
        s += 0.20
    if c.get('rootId') == o.get('rootId'):
        s += 0.15
    d = abs((c.get('difficulty') or 0) - (o.get('difficulty') or 0))
    s += 0.10 * max(0.0, 1.0 - d / 10.0)
    return s


def _faisable(c, dispo, manque, lieu):
    for m in c.get('equipment') or []:
        if m in manque:
            return False
        if m == 'mur':
            if lieu is None or lieu in MUR_LIEUX or (dispo is not None and m in dispo):
                continue
            return False
        if m in TOUJOURS:
            continue
        if dispo is not None and m not in dispo:
            return False
    if lieu is not None and lieu not in (c.get('places') or []):
        return False
    return True


def _sollicite(c, zone, zones):
    z = (zones or {}).get(c['id'])
    if z is not None:
        niveaux, hits = z[0], z[1]
        return (niveaux.get(zone) or 0.0) > 0.0 or zone in hits
    return (c.get('zoneLevels') or {}).get(zone, 0.0) > 0.0 or zone in (c.get('painStopHits') or [])


def _etiquette(o, c, raison, role):
    meme = c.get('pattern') == o.get('pattern')
    muscles = _muscles_ok(o, c)
    do = o.get('difficulty') or 0
    dc = c.get('difficulty') or 0
    if meme and muscles:
        if c.get('mode') == o.get('mode') and _qualite(c) == _qualite(o) and not c.get('assisted') \
                and do - 2 <= dc <= do + 1:
            if raison == 'trop_dur' and dc >= do:
                return None
            if raison == 'trop_dur':
                return 'plus_facile'
            return 'equivalent'
        if c.get('mode') != o.get('mode') or _qualite(c) != _qualite(o):
            if raison == 'pas_de_materiel' and dc <= do + 1:
                return 'sans_materiel'
            return 'plus_facile' if dc < do else None
        return 'plus_facile' if dc < do else None
    explosif = c.get('pattern') == 'pliometrie' and o.get('pattern') != 'pliometrie' and muscles \
        and c.get('family') in ('explosif', o.get('family')) and _meme_poste(o, c)
    if explosif and raison == 'pas_de_materiel' and dc <= do + 1:
        return 'sans_materiel'
    if role in ROLES_SCHEMA:
        return None
    if not meme and c.get('family') == o.get('family') and _commun(o, c):
        if raison == 'trop_dur' and dc > do:
            return None
        return 'autre'
    return None


def _meme_poste(o, c):
    """Le candidat se fait sur le même poste que la ligne (au moins un
    matériel commun hors sol, tapis, magnésie, mur), ou la ligne n'en a pas :
    la version explosive du dip se fait aux barres, pas au sol."""
    po = set(m for m in (o.get('equipment') or []) if m not in TOUJOURS)
    if not po:
        return True
    return bool(po & set(c.get('equipment') or []))


def _materiel(noms):
    noms = list(noms)
    if not noms:
        return 'ce matériel'
    if len(noms) == 1:
        return noms[0]
    return ', '.join(noms[:-1]) + ' et ' + noms[-1]


def _texte(etiquette, o, c, raison, unite_o, unite_c):
    r = raison or {}
    code = r.get('code')
    manque = r.get('materiel') or []
    if etiquette == 'equivalent':
        t = 'Même mouvement, mêmes muscles'
        if code == 'pas_de_materiel' and manque:
            t += ', sans ' + _materiel(manque[:NOMS_MATERIEL_MAX])
        t += '.'
    elif etiquette == 'plus_facile':
        t = 'Même mouvement, plus accessible.'
    elif etiquette == 'sans_materiel':
        if c.get('pattern') == 'pliometrie' and o.get('pattern') != 'pliometrie':
            t = 'Version explosive du mouvement, sans ' + _materiel(manque[:NOMS_MATERIEL_MAX]) + '.'
        elif unite_o in ('charge', 'charge_ajoutee') and unite_c == 'reps':
            t = ('Au poids du corps, sans ' + _materiel(manque[:NOMS_MATERIEL_MAX])
                 + ' : tempo lent ou pause en bas pour garder l’effort.')
        else:
            t = 'Même mouvement sans ' + _materiel(manque[:NOMS_MATERIEL_MAX]) + '.'
    else:
        t = 'Autre mouvement, mêmes muscles principaux.'
    if code == 'douleur' and r.get('zone'):
        t += ' Ne sollicite pas la zone signalée.'
    return t


def unite_de(i):
    """Unité servie : 'charge_ajoutee' (lest, poids du corps chargé),
    'charge' (barre, haltères, machine…), 'reps', 'secondes', ou None."""
    m = i.get('mode')
    if m == 'loaded':
        return 'charge_ajoutee' if (i.get('fraction') or 0.0) > 0 or i.get('loadType') == 'addedWeight' else 'charge'
    if m == 'reps':
        return 'reps'
    if m == 'hold':
        return 'secondes'
    return None


def _grille(i, grilles):
    g = (grilles or {}).get(i['id'])
    if g is not None:
        if isinstance(g, Grille):
            return g
        return Grille(g['pas'], g['minimum'], g['halteres'])
    if i.get('gridStep') is None:
        return None
    return Grille(i['gridStep'], i['gridMinimum'], bool(i.get('gridDumbbell')))


def plage_convertie(valeur):
    """Plage (bas, haut) d'une cible de répétitions ou de secondes prévue
    [valeur] : haut = partie entière (1 au moins), bas = 80 % du haut."""
    haut = max(1, int(math.floor(valeur + 1e-9)))
    bas = max(1, int(math.floor(PART_BAS * haut + 1e-9)))
    return bas, haut


def depart(koach, o_id, o_unite, c_id, c_unite, item, grille=None):
    """Cible de départ du remplaçant [c_id] sur la ligne servie [item] de
    l'exercice [o_id] : {'source', 'loadKg', 'repsLow', 'repsHigh',
    'secondsLow', 'secondsHigh'}. Sources, dans l'ordre : 'historique'
    (l'exercice a des mesures), 'transfert' (table de transfert de charge
    depuis l'exercice remplacé, s'il a des mesures), 'a_priori' (estimation
    de Koach par les qualités apprises, au quantile prudent), None (rien :
    l'athlète choisit, Koach l'apprend). Même unité que la ligne : la plage
    écrite est gardée."""
    out = {'source': None, 'loadKg': None, 'repsLow': None, 'repsHigh': None,
           'secondsLow': None, 'secondsHigh': None}
    lo, hi = item.get('repsLow'), item.get('repsHigh')
    slo, shi = item.get('secondsLow'), item.get('secondsHigh')
    meme = (o_unite in ('charge', 'charge_ajoutee') and c_unite in ('charge', 'charge_ajoutee')) or o_unite == c_unite
    if c_unite in ('charge', 'charge_ajoutee') and o_unite == 'secondes':
        lo, hi = 6, 8
    if koach is None:
        if meme:
            out.update({'repsLow': lo, 'repsHigh': hi, 'secondsLow': slo, 'secondsHigh': shi})
        return out
    s = koach.seances
    m = koach.modele
    t = m.piste(c_id)
    f = item.get('targetFlames')
    rir = 2.5 if f is None else rir_de_flammes(f)
    if t is None:
        if meme:
            out.update({'repsLow': lo, 'repsHigh': hi, 'secondsLow': slo, 'secondsHigh': shi})
        return out
    if c_unite in ('charge', 'charge_ajoutee'):
        if lo is None and hi is None:
            lo, hi = 6, 8
        if lo is None:
            lo = hi
        if hi is None:
            hi = lo
        out['repsLow'], out['repsHigh'] = lo, hi
        reps = hi if hi == lo else (lo + hi) / 2.0
        pr = koach.params['planification']['prudence_charge']
        g = grille
        if t.mesures > 0:
            voulu = s.charge_pour(c_id, reps, rir, pr[1] if t.seances > 3 else pr[0])
            out['source'] = 'historique'
            out['loadKg'] = g.proche(max(voulu, g.minimum)) if g is not None else voulu
            return out
        tr = transfert(o_id, c_id)
        to = m.piste(o_id)
        if tr is not None and to is not None and to.type == 'charge' and to.mesures > 0:
            total = (s.charge_pour(o_id, reps, rir, pr[0]) + to.fraction * m.poids_kg) * tr
            voulu = total - t.fraction * m.poids_kg
            out['source'] = 'transfert'
            out['loadKg'] = g.plancher(max(voulu, g.minimum)) if g is not None else voulu
            return out
        cap = m.capacite(c_id)
        if cap[1] <= 0.12:
            voulu = s.charge_pour(c_id, reps, rir, pr[0])
            out['source'] = 'a_priori'
            out['loadKg'] = g.plancher(max(voulu, g.minimum)) if g is not None else voulu
        return out
    if c_unite == 'reps' and t.type == 'reps':
        if meme and (lo is not None or hi is not None):
            # Même unité : la plage écrite, que Koach ajuste par l'historique.
            out.update({'source': 'historique' if t.mesures > 0 else None, 'repsLow': lo, 'repsHigh': hi})
            return out
        prevu = s.reps_prevues(c_id, None, rir)
        if t.mesures == 0:
            prevu *= math.exp(-0.5 * m.capacite_du_jour(c_id)[1])
        b, h = plage_convertie(min(max(prevu, 1.0), 30.0))
        out.update({'source': 'historique' if t.mesures > 0 else 'a_priori', 'repsLow': b, 'repsHigh': h})
        return out
    if c_unite == 'secondes' and t.type == 'tenue':
        if meme and (slo is not None or shi is not None):
            out.update({'source': 'historique' if t.mesures > 0 else None, 'secondsLow': slo, 'secondsHigh': shi})
            return out
        prevu = s.secondes_prevues(c_id, rir)
        if t.mesures == 0:
            prevu *= math.exp(-0.5 * m.capacite_du_jour(c_id)[1])
        b, h = plage_convertie(min(max(prevu, 1.0), 180.0))
        out.update({'source': 'historique' if t.mesures > 0 else 'a_priori', 'secondsLow': b, 'secondsHigh': h})
        return out
    if meme:
        out.update({'repsLow': lo, 'repsHigh': hi, 'secondsLow': slo, 'secondsHigh': shi})
    return out


def transfert(o_id, c_id):
    """Facteur de transfert de charge totale de [o_id] vers [c_id], ou None."""
    v = TRANSFERTS.get(c_id)
    if v is not None and v[0] == o_id:
        return v[1]
    v = TRANSFERTS.get(o_id)
    if v is not None and v[0] == c_id:
        return 1.0
    return None


def remplacants(infos, demande, koach=None):
    """Remplaçants classés et étiquetés de la ligne [demande] :

    - `exerciseId` : exercice servi de la ligne ; `item` : la ligne servie
      (séries, plages, flammes, `groupId`, `format`) ;
    - `role` : rôle de la ligne (`main`, `secondary`, `accessory`, `skill`…) ;
    - `raison` : {'code': 'pas_de_materiel' | 'douleur' | 'trop_dur' |
      'autre', 'materiel': [matériel manquant], 'zone': code de zone} ;
    - `materiel` : matériel disponible du profil (None : celui de la ligne
      écrite, moins le manquant) ; `lieu` : lieu du jour ou None ;
    - `niveau` : niveau de l'athlète (0 à 3) ou None ; `exclus` : ids
      écartés (détestés, non sus, déjà dans la séance) ; `grilles`,
      `zones` : comme `plan('seance')` ; `limite` (8 par défaut)."""
    par_id = {i['id']: i for i in infos}
    o_id = demande['exerciseId']
    o = par_id.get(o_id)
    raison = dict(demande.get('raison') or {'code': 'autre'})
    code = raison.get('code') or 'autre'
    if code not in ORDRE:
        code = 'autre'
    role = demande.get('role')
    regles = {'autre_permis': role not in ROLES_SCHEMA, 'zone': raison.get('zone') if code == 'douleur' else None}
    out = {'exerciseId': o_id, 'raison': code, 'remplacants': [], 'regles': regles}
    if o is None:
        return out
    manque = set(raison.get('materiel') or []) if code == 'pas_de_materiel' else set()
    dispo = demande.get('materiel')
    if dispo is not None:
        dispo = set(dispo)
    else:
        dispo = set(m for m in (o.get('equipment') or []) if m not in manque)
    lieu = demande.get('lieu')
    exclus = set(demande.get('exclus') or [])
    niveau = demande.get('niveau')
    niveau_max = o.get('level') or 0
    if niveau is not None and niveau > niveau_max:
        niveau_max = niveau
    zone = raison.get('zone') if code == 'douleur' else None
    item = demande.get('item') or {}
    u_o = unite_de(o)
    etat = koach.modele.instantane() if koach is not None else None
    try:
        return _remplacants(infos, demande, koach, out, o, o_id, raison, code, role, manque, dispo, lieu,
                            exclus, niveau_max, zone, item, u_o)
    finally:
        if etat is not None:
            # Aperçu : les pistes ouvertes pour les cibles de départ sont
            # refermées (rien n'est versé au journal).
            koach.modele.restaurer(etat)


def _remplacants(infos, demande, koach, out, o, o_id, raison, code, role, manque, dispo, lieu, exclus,
                 niveau_max, zone, item, u_o):
    par = {e: [] for e in ETIQUETTES}
    for c in infos:
        cid = c['id']
        if cid == o_id or cid in exclus or c.get('mode') not in ('loaded', 'reps', 'hold'):
            continue
        if (c.get('level') or 0) > niveau_max:
            continue
        if not _faisable(c, dispo, manque, lieu):
            continue
        if zone is not None and _sollicite(c, zone, demande.get('zones')):
            continue
        if code == 'trop_dur' and (c.get('difficulty') or 0) > (o.get('difficulty') or 0):
            continue
        e = _etiquette(o, c, code, role)
        if e is None:
            continue
        par[e].append((score(o, c), cid, c))
    limite = demande.get('limite') or LIMITE
    for e in ORDRE[code]:
        for sc, cid, c in _choisir(par[e], e, demande.get('par_etiquette')):
            if len(out['remplacants']) >= limite:
                break
            u_c = unite_de(c)
            g = _grille(c, demande.get('grilles'))
            out['remplacants'].append({
                'exerciseId': cid, 'nom': c.get('name'), 'etiquette': e,
                'texte': _texte(e, o, c, raison, u_o, u_c), 'unite': u_c,
                'depart': depart(koach, o_id, u_o, cid, u_c, item, g), 'score': sc,
            })
    return out


def _choisir(cands, etiquette, par=None):
    """Candidats retenus d'une étiquette : au plus `PAR_ETIQUETTE` (4 pour
    « sans_materiel »), le meilleur de chaque chaîne de variantes d'abord
    (diversité : un dip au poids du corps, un dip russe, un dip explosif
    plutôt que trois variantes d'une même chaîne), puis les suivants ; rang
    = proximité moins 0,08 par niveau de profondeur dans la chaîne (la
    variante de base d'abord). Égalités : identifiant."""
    n = par if par is not None else PAR_ETIQUETTE + (2 if etiquette == 'sans_materiel' else 0)
    rang = sorted(cands, key=lambda x: (-(x[0] - PENALITE_PROFONDEUR * (x[2].get('depth') or 0)), x[1]))
    pris = []
    vues = set()
    for x in rang:
        r = x[2].get('rootId') or x[1]
        if r not in vues:
            vues.add(r)
            pris.append(x)
    for x in rang:
        if x not in pris:
            pris.append(x)
    return pris[:n]


def item_remplace(koach, item, grille=None):
    """1.0.9 (KM7) : ligne écrite [item] servie avec son remplaçant
    `item['remplace']` = {'exerciseId': exercice écrit, 'raison': code} et
    `item['exerciseId']` = remplaçant (C17.51.5 : emplacement, séries,
    groupe, format, repos gardés). Les champs propres à l'exercice écrit
    sont retirés (charge écrite) ; une autre unité reçoit la plage de
    départ de Koach (`depart`) ; un transfert de charge devient la charge
    de départ d'un exercice jamais mesuré (`koachDepartKg`)."""
    rem = item.get('remplace') or {}
    o_id = rem.get('exerciseId')
    c_id = item['exerciseId']
    fiches = koach.fiches
    fo = fiches.get(o_id) or {}
    fc = fiches.get(c_id) or {}
    u_o = unite_fiche(fo)
    u_c = unite_fiche(fc)
    out = dict(item)
    for k in ('startLoadKg', 'loadKg', 'koachCible', 'koachDepartKg'):
        out.pop(k, None)
    if u_c is None or u_o is None:
        return out
    d = depart(koach, o_id, u_o, c_id, u_c, item, grille)
    if u_c in ('charge', 'charge_ajoutee'):
        if u_o not in ('charge', 'charge_ajoutee'):
            out.pop('percentOfOneRm', None)
            out['secondsLow'] = None
            out['secondsHigh'] = None
            out['repsLow'], out['repsHigh'] = d['repsLow'], d['repsHigh']
        if d['source'] == 'transfert':
            out['koachDepartKg'] = d['loadKg']
    elif u_c == 'reps':
        out.pop('percentOfOneRm', None)
        if u_o != 'reps' and d['repsHigh'] is not None:
            out['repsLow'], out['repsHigh'] = d['repsLow'], d['repsHigh']
            out['secondsLow'] = None
            out['secondsHigh'] = None
    elif u_c == 'secondes':
        out.pop('percentOfOneRm', None)
        if u_o != 'secondes' and d['secondsHigh'] is not None:
            out['secondsLow'], out['secondsHigh'] = d['secondsLow'], d['secondsHigh']
            out['repsLow'] = None
            out['repsHigh'] = None
    return out


def unite_fiche(f):
    """Unité servie d'après la fiche de Koach (type, fraction)."""
    t = f.get('type')
    if t == 'charge':
        return 'charge_ajoutee' if (f.get('fraction') or 0.0) > 0 or f.get('type_charge') == 'lest' else 'charge'
    if t == 'reps':
        return 'reps'
    if t == 'tenue':
        return 'secondes'
    return None
