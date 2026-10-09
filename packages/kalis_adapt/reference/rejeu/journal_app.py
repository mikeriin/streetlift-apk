# -*- coding: utf-8 -*-
"""Conversion GÉNÉRIQUE d'un export de l'application Kalis Track (format 3 de
la sauvegarde des Réglages) et de son programme en événements du journal de
Koach 1.0 (`Koach.observe`). Aucune donnée personnelle ici : tout vient de
l'export passé en argument.

Règles (alignées sur kalis_core/docs/CONVERSION_JOURNAL.md, C1 à C12, et
complétées pour le moteur) :

- Séances : seules les séances du programme (`S<semaine>-J<jour>`, semaine
  >= 1) terminées (`done`) sont converties, dans l'ordre de `finishedAt` (puis
  de la clé). Jour du moteur = jours écoulés depuis le lundi du départ du
  programme (`programStart.date`, à défaut `meta.anchorMonday` du programme),
  date = jour civil de `finishedAt`. Un `semaine_fin` est versé pour chaque
  lundi passé entre deux séances. Une séance sans série convertie est écartée.
- Exercices : identifiant de ligne du programme -> nom de la ligne -> id de la
  base (`correspondance.noms`). Ligne absente du programme, nom sans
  correspondance, id absent des fiches : séries ignorées et comptées. Ordre :
  celui de la journée du programme (C5).
- Séries : seules les séries `done` ; `excluded` (écartée par l'utilisateur
  dans l'application, qui ne l'utilise plus pour ses estimations) : ignorée et
  comptée. Mesure (`reps`, texte, virgule ou point) en secondes pour une
  tenue, en répétitions sinon ; vide ou illisible : ignorée et comptée. Mesure
  0 = échec (`failed`). Charge (`kg`) = charge EXTERNE (lest, barre, haltère
  « par haltère », poulie) -> `externalLoadKg` ; vide -> None ; 0 sur un
  exercice qui n'est pas chargé -> None ; illisible ou négative : série
  ignorée et comptée.
- Note : `flames` (1 à 10) s'il est présent, sinon `Flames.fromRir(effort)`
  (RIR saisi ; même règle que kalis_core : 0 -> 10, 0,5 et 1 -> 9, puis une
  flamme par demi-répétition, 5 et plus -> 1), sinon l'ancien champ texte
  `rir` lu selon `koach.legacyScale` (rir, ou rpe : RIR = 10 - RPE, plafonné
  à 5, comme `parseLegacyEffort`), sinon None (série faite sans note).
- Rôle : lignes `test1rm` / `enduranceTest` du programme Koach -> `kind` et
  `role` = 'test' ; sinon 'work'. Cible : RIR visé (`rirTarget`) en flammes,
  répétitions (ou secondes) de l'écrit quand il est de la forme `N×R` ou
  `N×R-S` ; repos = `restSec`.
- Bilan (C11) : `koach.answers[clé]` : forme 0 à 10 (échelle de
  l'application, `SessionAnswers.form`) -> `overall` = plafond(forme / 2) borné
  à 1..5 ; sommeil -> `sleepHours`. La douleur y est notée PAR MOUVEMENT, pas
  par zone du corps : non convertie (comptée), `pains` absent (une liste vide
  dirait « aucune douleur », ce qui n'est pas su). `legacyScale` ne concerne
  que l'ancien champ texte RIR/RPE des séries, pas le bilan.
- Poids du jour : dernière pesée (`koach.weighIns`) datée au plus tard du
  jour de la séance ; sinon rien (le moteur garde le poids du profil).
- Profil : niveau = `athleteProfile.profile.experience` (beginner,
  intermediate, advanced, elite -> 0..3), à défaut 2 (avancé) ; sexe, poids du
  profil (à défaut la première pesée) ; zones fragiles = zones des
  `limitations` ; valeurs déclarées = valeurs de référence INITIALES
  (`koach.history`, source `initial`, la première par référence ; jamais les
  valeurs mises à jour ensuite) : mouvements principaux (`pilotage.mainLifts`
  du programme, 1RM en kg de lest ou kg barre = charge externe) ->
  ('one_rm_kg', valeur) sur les exercices des lignes `strength`/`test1rm` de
  cette référence ; maxima de répétitions (`pilotage.repMax`) ->
  ('max_reps', valeur) sur les exercices des lignes `endurance`/
  `enduranceTest` de type répétitions. Les références d'accessoires (charge
  de travail à N répétitions, pas un maximum) ne sont pas déclarées.
"""
import datetime as dt
import gzip
import json
import math
import re
from collections import Counter

NIVEAUX = ['beginner', 'intermediate', 'advanced', 'elite']
NIVEAU_DEFAUT = 2
CATEGORIES_TEST = ('test1rm', 'enduranceTest')
UNITES_EXTERNES = ('kg de lest', 'kg barre', 'kg')
MESURE_DU_TYPE = {'charge': 'one_rm_kg', 'reps': 'max_reps', 'tenue': 'max_hold_seconds'}
_CLE = re.compile(r'^S(\d+)-J(\d+)$')
_ECRIT = re.compile(r'^\s*(\d+)\s*[×xX]\s*(\d+)(?:\s*[-–]\s*(\d+))?\s*(s)?\s*(?:/\s*\w+)?\s*$')


def lire_json(chemin):
    """JSON, compressé ou non (.gz)."""
    if str(chemin).endswith('.gz'):
        with gzip.open(chemin, 'rt', encoding='utf-8') as f:
            return json.load(f)
    with open(chemin, encoding='utf-8') as f:
        return json.load(f)


def nombre(valeur):
    """(valeur, état) d'un champ saisi : état 'ok', 'vide' ou 'illisible'.
    Texte avec virgule ou point décimal, espaces ignorées."""
    if valeur is None:
        return None, 'vide'
    if isinstance(valeur, bool):
        return None, 'illisible'
    if isinstance(valeur, (int, float)):
        v = float(valeur)
    else:
        t = str(valeur).replace(' ', '').replace(' ', '').replace(' ', '').strip()
        if not t:
            return None, 'vide'
        try:
            v = float(t.replace(',', '.'))
        except ValueError:
            return None, 'illisible'
    if not math.isfinite(v):
        return None, 'illisible'
    return v, 'ok'


def flammes_de_rir(rir):
    """`Flames.fromRir` de kalis_core (lib/src/flames.dart)."""
    if rir >= 5:
        return 1
    demis = math.ceil(rir * 2 - 0.5)
    if demis <= 0:
        return 10
    return 9 if demis == 1 else 11 - demis


def rir_de_flammes(f):
    """Réserve dite d'une note en flammes (10 = échec, 0)."""
    return 0.0 if f >= 10 else (11 - f) / 2.0


def rir_ancien(texte, echelle):
    """`parseLegacyEffort` de l'application : RIR (ou RPE -> 10 - RPE),
    plafonné à 5 ; None si illisible."""
    v, etat = nombre(texte)
    if etat != 'ok':
        return None
    if echelle == 'rpe':
        if v < 1 or v > 10:
            return None
        v = 10.0 - v
    if v < 0:
        return None
    return 5.0 if v > 5 else v


def cible_ecrite(texte):
    """(bas, haut, en secondes) de l'écrit `N×R`, `N×R-S`, `N×R s`, sinon None."""
    if not isinstance(texte, str):
        return None
    m = _ECRIT.match(texte)
    if not m:
        return None
    bas = int(m.group(2))
    haut = int(m.group(3)) if m.group(3) else bas
    return bas, haut, bool(m.group(4))


class Programme(object):
    """Programme de l'application (`prog.json`), annotations Koach
    (`koach_program.json`) et correspondance noms -> ids de la base."""

    def __init__(self, prog, kprog, correspondance):
        self.lignes = {}
        self.ordre_jour = {}
        for w in prog.get('weeks') or []:
            n = int(w['n'])
            for d in w.get('days') or []:
                j = int(d['j'])
                ids = []
                for e in d.get('exercises') or []:
                    self.lignes[e['id']] = e
                    ids.append(e['id'])
                self.ordre_jour[(n, j)] = ids
        self.annotations = (kprog or {}).get('exercises') or {}
        self.genres = (kprog or {}).get('weeks') or {}
        self.noms = (correspondance or {}).get('noms') or {}
        self.lundi = ((prog.get('meta') or {}).get('anchorMonday'))
        pil = prog.get('pilotage') or {}
        self.principaux = {m['ref']: m.get('unit') for m in pil.get('mainLifts') or [] if m.get('ref')}
        self.maxima = {m['ref'] for m in pil.get('repMax') or [] if m.get('ref')}

    def id_base(self, ligne_id):
        e = self.lignes.get(ligne_id)
        if e is None:
            return None
        return self.noms.get(e.get('name'))

    def categorie(self, ligne_id):
        return (self.annotations.get(ligne_id) or {}).get('cat')

    def ref(self, ligne_id):
        a = self.annotations.get(ligne_id) or {}
        if a.get('ref'):
            return a['ref']
        e = self.lignes.get(ligne_id) or {}
        load = e.get('load')
        return load.get('ref') if isinstance(load, dict) else None

    def ids_de_ref(self, ref, categories):
        out = set()
        for lid in self.lignes:
            if self.categorie(lid) in categories and self.ref(lid) == ref:
                i = self.id_base(lid)
                if i is not None:
                    out.add(i)
        return sorted(out)

    def ids_principaux(self):
        """Ids de la base des mouvements principaux (lignes de force ou de
        test 1RM des références `mainLifts`)."""
        out = set()
        for ref in self.principaux:
            out.update(self.ids_de_ref(ref, ('strength', 'test1rm')))
        return out

    def genre(self, semaine):
        g = self.genres.get(str(semaine))
        return g if g in ('test', 'normal', 'deload') else None


def _date(texte):
    try:
        return dt.date.fromisoformat(str(texte)[:10])
    except (TypeError, ValueError):
        return None


def profil_de(export, programme, fiches, rapport):
    """Profil de départ du moteur : {niveau, sexe, poids_kg, declares,
    zones_fragiles}."""
    ap = ((export.get('athleteProfile') or {}).get('profile')) or {}
    exp = ap.get('experience')
    if exp in NIVEAUX:
        niveau = NIVEAUX.index(exp)
        rapport['profil_niveau_lu'] = 1
    else:
        niveau = NIVEAU_DEFAUT
        rapport['profil_niveau_par_defaut'] = 1
    pesees = sorted((w for w in (export.get('koach') or {}).get('weighIns') or []
                     if _date(w.get('date')) is not None and nombre(w.get('kg'))[1] == 'ok'),
                    key=lambda w: w['date'])
    poids, etat = nombre(ap.get('bodyWeightKg'))
    if etat != 'ok' or poids <= 0:
        poids = nombre(pesees[0]['kg'])[0] if pesees else None
        rapport['profil_poids_depuis_pesee' if poids else 'profil_poids_absent'] = 1
    fragiles = sorted({lim['zone'] for lim in ap.get('limitations') or []
                       if isinstance(lim, dict) and isinstance(lim.get('zone'), str)})
    return {'niveau': niveau, 'sexe': ap.get('sex'), 'poids_kg': poids,
            'declares': declares_initiaux(export, programme, fiches, rapport),
            'zones_fragiles': fragiles}


def declares_initiaux(export, programme, fiches, rapport):
    """Valeurs de référence INITIALES -> {id: (mesure, valeur)}."""
    initiales = {}
    for h in (export.get('koach') or {}).get('history') or []:
        if not isinstance(h, dict) or h.get('source') != 'initial':
            continue
        ref = h.get('ref')
        if ref in initiales:
            continue
        v, etat = nombre(h.get('value'))
        if etat == 'ok' and v > 0:
            initiales[ref] = v
        else:
            rapport['declare_valeur_illisible'] += 1
    out = {}
    for ref in sorted(initiales):
        v = initiales[ref]
        if ref in programme.principaux:
            if programme.principaux[ref] not in UNITES_EXTERNES:
                rapport['declare_unite_inconnue'] += 1
                continue
            mesure, cats = 'one_rm_kg', ('strength', 'test1rm')
        elif ref in programme.maxima:
            mesure, cats = 'max_reps', ('endurance', 'enduranceTest')
        else:
            rapport['declare_reference_non_maximale'] += 1
            continue
        for i in programme.ids_de_ref(ref, cats):
            fiche = fiches.get(i)
            if fiche is None or MESURE_DU_TYPE.get(fiche.get('type')) != mesure:
                rapport['declare_mesure_incompatible'] += 1
                continue
            if i in out and out[i] != (mesure, v):
                rapport['declare_conflit'] += 1
                continue
            out[i] = (mesure, v)
            rapport['declares'] += 1
    return out


def convertir(export, programme, fiches, bilan=True):
    """Export de l'application -> {profil, seances, principaux, rapport}.
    `seances` : liste chronologique de blocs {cle, semaine, jour, date,
    avant (semaine_fin), debut, series (événements), meta (par série : cat,
    ref, type), fin} ; `cle` et `date` restent en mémoire (jamais écrites
    dans les agrégats)."""
    rapport = Counter()
    if export.get('format') not in (3, None):
        rapport['format_inattendu'] += 1
    profil = profil_de(export, programme, fiches, rapport)
    k = export.get('koach') or {}
    echelle = k.get('legacyScale') if k.get('legacyScale') in ('rir', 'rpe') else 'rir'
    if k.get('legacyScale') not in ('rir', 'rpe'):
        rapport['echelle_ancienne_absente'] += 1
    reponses = k.get('answers') or {}
    pesees = sorted(((_date(w.get('date')), nombre(w.get('kg'))[0]) for w in k.get('weighIns') or []
                     if isinstance(w, dict) and _date(w.get('date')) is not None and nombre(w.get('kg'))[1] == 'ok'),
                    key=lambda x: x[0])
    depart = _date((export.get('programStart') or {}).get('date')) or _date(programme.lundi)
    if depart is None:
        raise ValueError('départ du programme inconnu')
    lundi = depart - dt.timedelta(days=depart.weekday())

    retenues = []
    for cle, s in (export.get('logs') or {}).items():
        rapport['seances_lues'] += 1
        m = _CLE.match(cle)
        if not m or int(m.group(1)) == 0:
            rapport['seances_manuelles_ignorees'] += 1
            continue
        if not isinstance(s, dict) or s.get('done') is not True:
            rapport['seances_non_terminees_ignorees'] += 1
            for ex in (s.get('ex') or {}).values() if isinstance(s, dict) else []:
                rapport['series_faites_de_seances_non_terminees'] += sum(
                    1 for x in ex.get('sets') or [] if isinstance(x, dict) and x.get('done') is True)
            continue
        w, j = int(m.group(1)), int(m.group(2))
        horo = s.get('finishedAt')
        date = _date(horo)
        if date is None:
            rapport['seances_sans_finishedAt'] += 1
            date = lundi + dt.timedelta(days=7 * (w - 1) + (j - 1))
            horo = date.isoformat()
        retenues.append((str(horo), cle, w, j, date, s))
    retenues.sort(key=lambda x: (x[0], x[1]))

    seances = []
    dernier_jour = None
    for horo, cle, w, j, date, s in retenues:
        jour = (date - lundi).days
        ordre = programme.ordre_jour.get((w, j), [])
        lignes = sorted(s.get('ex') or {}, key=lambda lid: (ordre.index(lid) if lid in ordre else len(ordre), lid))
        series, meta = [], []
        for lid in lignes:
            ex = s['ex'][lid] or {}
            toutes = [x for x in ex.get('sets') or [] if isinstance(x, dict)]
            faites = [x for x in toutes if x.get('done') is True]
            rapport['series_lues'] += len(toutes)
            rapport['series_non_faites'] += len(toutes) - len(faites)
            if not faites:
                continue
            ligne = programme.lignes.get(lid)
            if ligne is None:
                rapport['series_ligne_hors_programme'] += len(faites)
                continue
            cid = programme.id_base(lid)
            if cid is None:
                rapport['series_sans_correspondance'] += len(faites)
                continue
            fiche = fiches.get(cid)
            if fiche is None:
                rapport['series_hors_base'] += len(faites)
                continue
            typ = fiche.get('type')
            cat = programme.categorie(lid)
            ann = programme.annotations.get(lid) or {}
            sets_ecrits = ligne.get('sets')
            ecrit = cible_ecrite(sets_ecrits.get('value') if isinstance(sets_ecrits, dict) else sets_ecrits)
            cible = {}
            rt = ann.get('rirTarget')
            if isinstance(rt, (int, float)) and not isinstance(rt, bool) and rt >= 0:
                cible['flames'] = flammes_de_rir(float(rt))
            if ecrit is not None:
                bas, haut, en_s = ecrit
                if typ == 'tenue' and en_s:
                    cible['secondsLow'], cible['secondsHigh'] = bas, haut
                elif not en_s:
                    cible['repsLow'], cible['repsHigh'] = bas, haut
            role = 'test' if cat in CATEGORIES_TEST else 'work'
            repos = ligne.get('restSec')
            idx = 0
            for x in faites:
                if x.get('excluded'):
                    rapport['series_exclues_par_l_utilisateur'] += 1
                    continue
                mesure, etat = nombre(x.get('reps'))
                if etat != 'ok' or mesure < 0:
                    rapport['series_mesure_vide' if etat == 'vide' else 'series_mesure_illisible'] += 1
                    continue
                if abs(mesure - round(mesure)) > 1e-9:
                    rapport['mesures_non_entieres_arrondies'] += 1
                mesure = int(round(mesure))
                kg, ek = nombre(x.get('kg'))
                if ek == 'illisible':
                    rapport['series_charge_illisible'] += 1
                    continue
                if kg is not None and kg < 0:
                    rapport['series_charge_negative'] += 1
                    continue
                if typ == 'charge':
                    externe = kg
                    if kg is None:
                        rapport['charges_vides_exercice_charge'] += 1
                elif kg is None or kg == 0:
                    externe = None
                else:
                    externe = kg
                    rapport['charges_sur_exercice_non_charge'] += 1
                flammes, source = None, None
                f = x.get('flames')
                eff, eeff = nombre(x.get('effort')) if x.get('effort') is not None else (None, 'vide')
                if isinstance(f, int) and not isinstance(f, bool) and 1 <= f <= 10:
                    flammes, source = f, 'flames'
                    if eeff == 'ok' and eff >= 0 and flammes_de_rir(eff) != f:
                        rapport['notes_flames_effort_incoherentes'] += 1
                elif f is not None:
                    rapport['notes_flames_illisibles'] += 1
                if flammes is None and eeff == 'ok' and eff >= 0:
                    flammes, source = flammes_de_rir(eff), 'effort'
                elif flammes is None and eeff == 'illisible':
                    rapport['notes_effort_illisibles'] += 1
                if flammes is None and isinstance(x.get('rir'), str) and x['rir'].strip():
                    r = rir_ancien(x['rir'], echelle)
                    if r is None:
                        rapport['notes_rir_texte_illisibles'] += 1
                    else:
                        flammes, source = flammes_de_rir(r), 'rir_texte'
                rapport['notes_depuis_' + (source or 'aucune')] += 1
                serie = {'exerciseId': cid, 'slotId': lid, 'setIndex': idx, 'kind': role,
                         'externalLoadKg': externe, 'reps': None, 'seconds': None,
                         'flames': flammes, 'failed': mesure == 0, 'target': dict(cible),
                         'restSeconds': repos, 'role': role, 'repere': None}
                if typ == 'tenue':
                    serie['seconds'] = mesure
                else:
                    serie['reps'] = mesure
                idx += 1
                series.append({'type': 'serie', 'serie': serie})
                meta.append({'cat': cat, 'ref': programme.ref(lid), 'type': typ})
                rapport['series_converties'] += 1
                rapport['series_converties_type_' + str(typ)] += 1
        if not series:
            rapport['seances_vides_ecartees'] += 1
            continue
        avant = []
        if dernier_jour is not None:
            for sem in range(dernier_jour // 7 + 1, jour // 7 + 1):
                avant.append({'type': 'semaine_fin', 'jour': 7 * sem, 'semaine': sem})
        dernier_jour = jour if dernier_jour is None or jour > dernier_jour else dernier_jour
        b = None
        rep = reponses.get(cle) if bilan else None
        if isinstance(rep, dict):
            b = {}
            forme, ef = nombre(rep.get('form'))
            if ef == 'ok' and 0 <= forme <= 10:
                b['overall'] = int(min(5, max(1, math.ceil(forme / 2.0))))
            elif ef != 'vide':
                rapport['bilan_forme_illisible'] += 1
            som, es = nombre(rep.get('sleep'))
            if es == 'ok' and 0 <= som <= 24:
                b['sleepHours'] = som
            elif es != 'vide':
                rapport['bilan_sommeil_illisible'] += 1
            if isinstance(rep.get('pain'), dict) and rep['pain']:
                rapport['douleurs_par_mouvement_non_converties'] += len(rep['pain'])
            if b:
                rapport['bilans_convertis'] += 1
            else:
                b = None
        elif not bilan and reponses.get(cle):
            rapport['bilans_non_passes'] += 1
        poids = None
        for dp, kg in pesees:
            if dp <= date:
                poids = kg
        if poids is not None:
            rapport['seances_avec_pesee'] += 1
        debut = {'type': 'seance_debut', 'jour': jour, 'bilan': b, 'poids_kg': poids,
                 'contexte': {'genre': programme.genre(w), 'intention': None, 'semaine': w}}
        fin = {'type': 'seance_fin', 'jour': jour, 'douleurs': None,
               'seance': {'sets': [e['serie'] for e in series]}}
        seances.append({'cle': cle, 'semaine': w, 'jour': jour, 'date': date.isoformat(),
                        'avant': avant, 'debut': debut, 'series': series, 'meta': meta, 'fin': fin})
        rapport['seances_converties'] += 1
    return {'profil': profil, 'seances': seances, 'principaux': programme.ids_principaux(),
            'rapport': dict(sorted(rapport.items()))}


def evenements(conversion):
    """Journal complet de Koach (liste d'événements, ordre chronologique)."""
    out = []
    for s in conversion['seances']:
        out.extend(s['avant'])
        out.append(s['debut'])
        out.extend(s['series'])
        out.append(s['fin'])
    return out
