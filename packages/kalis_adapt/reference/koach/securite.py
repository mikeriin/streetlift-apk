# -*- coding: utf-8 -*-
"""Garde-fous de Koach 1.0 : les règles de sécurité de `kalis_adapt` 0.3.1
reprises comme contraintes dures (CONTRAT_1_0.md § 8, cahier « Contraintes »).

Ce module ne propose rien : il borne. Il tient l'état de la douleur par zone
(seuil, zone active, arrêt, reprise graduée), lit le bilan de santé du jour
(paliers 0, 1, 2) et donne à la prescription de séance les limites à
respecter. Les valeurs viennent de `params['securite']`, égales à celles de
`AdaptParams.standard` de 0.3.1 (fichier:ligne du code Dart cité à chaque
règle). Règles du poignet (A4), zones fragiles du profil (A7.2), bas du
corps (A2.3, A10.2) et renvoi vers un professionnel (A2.2) comprises.
"""

ZONES_BAS = ('hip', 'thigh', 'knee', 'lower_leg', 'ankle_foot')
POIGNET = 'wrist_hand'
SEMAINES_VERROUILLEES = ('intro', 'deload', 'taper', 'test', 'competition', 'transition')
SEMAINES_DE_CHARGE = ('accumulation', 'intensification', 'realization', 'intro', None, 'maintenance')


class Douleur(object):
    """État de la douleur d'une zone : signalements datés (jour, intensité)."""

    def __init__(self):
        self.signalements = []   # (jour, intensité max du jour)
        self.arret_depuis = None
        self.arret_leve = None   # jour de la dernière levée
        self.seances_de_suite = 0
        self.renvoi_jour = None  # jour du dernier renvoi vers un professionnel

    def noter(self, jour, intensite):
        if self.signalements and self.signalements[-1][0] == jour:
            if intensite > self.signalements[-1][1]:
                self.signalements[-1] = (jour, intensite)
        else:
            self.signalements.append((jour, intensite))

    def derniere(self):
        return self.signalements[-1] if self.signalements else None

    def pire_entre(self, debut, fin):
        v = 0
        for j, i in self.signalements:
            if debut <= j <= fin and i > v:
                v = i
        return v


class Gardefous(object):
    def __init__(self, params, niveau, zones_fragiles=None):
        self.s = params['securite']
        self.niveau = niveau
        self.zones = {}
        self.fragiles = self._zones_fragiles(zones_fragiles)
        self.jour = 0
        self.dernier_jour_seance = None
        self.avant_dernier_jour_seance = None
        self.semaines = {}       # indice de semaine -> semaine de charge (bool)
        self.semaine = 0

    def _zones_fragiles(self, zones):
        """Zones fragiles du profil (règle A7.2 de 0.3.1, A/replay.dart:42-51) :
        antécédent de moins de 12 mois (`since` parmi `fragile_anciennetes`)
        ou gêne déclarée ≥ `fragile_gene_min`. Une entrée réduite au code de
        la zone (chaîne) est tenue pour fragile : l'appelant l'a déjà jugée
        telle (plus prudent). Tuple trié : ordre d'itération déterministe."""
        s = self.s
        out = set()
        for z in zones or []:
            if isinstance(z, dict):
                code = z.get('zone')
                if not code:
                    continue
                gene = z.get('discomfort')
                if z.get('since') in s['fragile_anciennetes'] or \
                        (gene is not None and gene >= s['fragile_gene_min']):
                    out.add(code)
            elif z:
                out.add(z)
        return tuple(sorted(out))

    def fragile(self, niveaux_zone):
        """Première zone fragile du profil (ordre trié) que l'exercice
        sollicite (niveau ≥ `fragile_niveau_min`, A/replay.dart:120-125), ou
        None."""
        for z in self.fragiles:
            if niveaux_zone.get(z, 0.0) >= self.s['fragile_niveau_min']:
                return z
        return None

    def noter_semaine(self, semaine, genre, intention=None):
        """Genre de la semaine en cours (contexte de la séance). Une semaine
        « de charge » pour la reprise graduée est une semaine non
        verrouillée ou d'introduction (`returnLoadedWeek` de 0.3.1)."""
        g = intention or genre
        self.semaine = semaine
        self.semaines[semaine] = g not in ('deload', 'taper', 'test', 'competition', 'transition')

    def _semaines_de_charge(self, leve):
        """Nombre de semaines de charge écoulées depuis la levée d'un arrêt
        (hors semaine en cours), et vrai si une semaine de charge a commencé
        depuis. Une semaine compte quand la levée lui laisse au moins 4 jours."""
        premiere = leve // 7 if 7 - (leve % 7) >= 4 else leve // 7 + 1
        n = 0
        commencee = False
        for w in range(premiere, self.semaine + 1):
            if self.semaines.get(w, False):
                commencee = True
                if w < self.semaine:
                    n += 1
        return n, commencee

    def zone(self, z):
        if z not in self.zones:
            self.zones[z] = Douleur()
        return self.zones[z]

    # ------------------------------------------------------------------
    # Signalements
    # ------------------------------------------------------------------
    def noter_seance(self, jour, douleurs, posee=True):
        """Douleurs signalées (bilan et séance). Une liste vide posée met les
        zones suivies à 0 ; une question non posée ne change rien."""
        self.jour = jour
        cites = {}
        for d in douleurs or []:
            z = d['zone']
            if d['intensity'] > cites.get(z, -1):
                cites[z] = d['intensity']
        for z, i in cites.items():
            self.zone(z).noter(jour, i)
        if posee:
            for z, d in self.zones.items():
                if z not in cites:
                    d.noter(jour, 0)
        for z, d in self.zones.items():
            dern = d.derniere()
            if dern is not None and dern[0] == jour:
                d.seances_de_suite = d.seances_de_suite + 1 if dern[1] > self.s['douleur_seuil'] else 0
        self._arrets(jour)

    def _episode(self, d):
        """Signalements >= seuil de persistance de l'épisode en cours, et
        fin de l'épisode précédent."""
        s = self.s
        forts = [(j, i) for j, i in d.signalements if i >= s['arret_persistance_min']]
        if not forts:
            return [], None
        episode = [forts[-1]]
        precedent = None
        for k in range(len(forts) - 2, -1, -1):
            if episode[0][0] - forts[k][0] <= s['arret_levee_j']:
                episode.insert(0, forts[k])
            else:
                precedent = forts[:k + 1]
                break
        return episode, precedent

    def _arrets(self, jour):
        s = self.s
        for z, d in self.zones.items():
            episode, precedent = self._episode(d)
            if not episode:
                continue
            dernier = episode[-1][0]
            if d.arret_depuis is not None:
                if jour - dernier >= s['arret_levee_j']:
                    d.arret_leve = dernier + s['arret_levee_j']
                    d.arret_depuis = None
                continue
            if jour - dernier >= s['arret_levee_j']:
                continue
            dure = dernier - episode[0][0] >= s['arret_persistance_j']
            fortes = [j for j, i in episode if i >= s['arret_forte_min']]
            forte = len(fortes) >= 2 and fortes[-1] - fortes[0] >= s['arret_forte_j']
            retour = False
            if precedent:
                reel = len(precedent) >= 2 or max(i for _, i in precedent) >= 4
                retour = reel and episode[0][0] - precedent[-1][0] <= s['arret_retour_j']
            suite = d.seances_de_suite >= s['arret_seances_de_suite']
            if dure or forte or retour or suite:
                d.arret_depuis = jour

    def avancer(self, jour):
        self.jour = jour
        self._arrets(jour)

    # ------------------------------------------------------------------
    # Lecture
    # ------------------------------------------------------------------
    def active(self, z):
        d = self.zones.get(z)
        if d is None or not d.signalements:
            return 0
        j, i = d.signalements[-1]
        if i > self.s['douleur_seuil'] and self.jour - j <= self.s['douleur_jours_actifs']:
            return i
        return 0

    def actives(self):
        return {z: self.active(z) for z in self.zones if self.active(z) > 0}

    def arret(self, z):
        """Zone à l'arrêt, ou arrêt gardé : levée récente sans qu'une semaine
        de charge ait commencé depuis (règle A3.2 de 0.3.1)."""
        d = self.zones.get(z)
        if d is None:
            return False
        if d.arret_depuis is not None:
            return True
        if d.arret_leve is not None and 0 <= self.jour - d.arret_leve <= self.s['reprise_surveillance_j']:
            _, commencee = self._semaines_de_charge(d.arret_leve)
            return not commencee
        return False

    def arrets(self):
        return [z for z in self.zones if self.arret(z)]

    def reprise(self, z):
        """Part du volume écrit pendant la reprise graduée (None hors
        reprise) : départ 50 %, +10 % par semaine, recul si la gêne remonte."""
        d = self.zones.get(z)
        s = self.s
        if d is None or d.arret_leve is None or d.arret_depuis is not None:
            return None
        depuis = self.jour - d.arret_leve
        if depuis > s['reprise_surveillance_j'] or depuis < 0:
            return None
        # Paliers comptés en semaines DE CHARGE écoulées : une semaine
        # allégée, de test ou d'affûtage garde la part de la dernière
        # semaine de charge (règle A3.3 de 0.3.1).
        n, _ = self._semaines_de_charge(d.arret_leve)
        part = s['reprise_depart'] + s['reprise_pas'] * n
        if d.pire_entre(self.jour - 6, self.jour) > s['reprise_douleur_max']:
            part -= s['reprise_pas']
        if part < s['reprise_plancher']:
            part = s['reprise_plancher']
        return None if part >= 1.0 else part

    def recente(self, z):
        d = self.zones.get(z)
        if d is None:
            return False
        if d.arret_depuis is not None:
            return True
        if d.arret_leve is not None and self.jour - d.arret_leve <= self.s['reprise_surveillance_j']:
            return True
        dern = d.derniere()
        return dern is not None and dern[0] == self.jour and dern[1] > self.s['reprise_douleur_max']

    def signalee_semaine(self, z):
        d = self.zones.get(z)
        return d is not None and d.pire_entre(self.jour - 6, self.jour) > self.s['reprise_douleur_max']

    # ------------------------------------------------------------------
    # Poignet (règles A4 de 0.3.1)
    # ------------------------------------------------------------------
    def appui_neutre(self, fiche):
        """Appui qui garde le poignet neutre : parallettes ou poignées
        (`coachWristNeutralSupport` sans matériel du jour,
        A/session.dart:2438-2450). La pompe sur barre basse n'en fait pas
        partie ici : Koach ne connaît pas le matériel du jour (plus prudent)."""
        materiel = (fiche or {}).get('materiel') or []
        return any(m in materiel for m in self.s['poignet_appui_neutre_materiel'])

    def poignet_gene(self):
        """Pire gêne du poignet ≥ `arret_persistance_min` signalée dans les
        `poignet_gene_j` derniers jours (`wristGeneRecent`,
        A/session.dart:2456-2460), sinon 0."""
        d = self.zones.get(POIGNET)
        if d is None:
            return 0
        v = d.pire_entre(self.jour - self.s['poignet_gene_j'] + 1, self.jour)
        return v if v >= self.s['arret_persistance_min'] else 0

    def poignet_chaud(self):
        """Poignet à l'arrêt (arrêt en cours, pas gardé) et signalé
        ≥ `arret_persistance_min` dans les `poignet_chaud_j` derniers jours
        (`wristStopHot`, A/session.dart:2876-2891)."""
        d = self.zones.get(POIGNET)
        if d is None or d.arret_depuis is None:
            return False
        return d.pire_entre(self.jour - self.s['poignet_chaud_j'] + 1, self.jour) >= self.s['arret_persistance_min']

    def poignet_sensible(self):
        """Appui du poignet sensible (`wristSensitive`,
        A/session.dart:1688-1716) : zone fragile du profil, arrêt (en cours
        ou gardé), reprise graduée (fenêtre de surveillance entière, plus
        prudent que la part < 1 de 0.3.1), ou gêne ≥ `poignet_sensible_min`
        dans les `poignet_sensible_j` derniers jours."""
        if POIGNET in self.fragiles:
            return True
        d = self.zones.get(POIGNET)
        if d is None:
            return False
        if self.arret(POIGNET):
            return True
        if d.arret_leve is not None and 0 <= self.jour - d.arret_leve <= self.s['reprise_surveillance_j']:
            return True
        return d.pire_entre(self.jour - self.s['poignet_sensible_j'] + 1, self.jour) >= self.s['poignet_sensible_min']

    # ------------------------------------------------------------------
    # Bas du corps (règles A2.3 et A10.2 de 0.3.1)
    # ------------------------------------------------------------------
    def douleur_jambe(self):
        """Plus forte dernière intensité des zones du bas du corps signalées
        depuis ≤ `douleur_jours_actifs` jours (A/session.dart:2579-2595 ; la
        gêne sous le seuil compte)."""
        v = 0
        for z in ZONES_BAS:
            d = self.zones.get(z)
            if d is None or not d.signalements:
                continue
            j, i = d.signalements[-1]
            if self.jour - j <= self.s['douleur_jours_actifs'] and i > v:
                v = i
        return v

    def arrets_jambe(self):
        """Zones du bas du corps à l'arrêt (arrêt en cours, pas gardé :
        `painStops`, A/session.dart:2527-2546), dans l'ordre de ZONES_BAS."""
        return [z for z in ZONES_BAS if z in self.zones and self.zones[z].arret_depuis is not None]

    def reprise_jambe(self):
        """Vrai si une zone du bas du corps est en reprise graduée
        (A/session.dart:2547-2550)."""
        return any(self.reprise(z) is not None for z in ZONES_BAS if z in self.zones)

    def renvois(self):
        """Zones (ordre trié) dont l'arrêt appelle aujourd'hui le renvoi vers
        un professionnel : première séance de l'arrêt, puis première séance
        de chaque semaine d'arrêt (`_stopNoticeDue`, A/session.dart:2397-2420).
        Le jour du dernier renvoi est retenu (appelé à l'ouverture de la
        séance, événement du journal) : un arrêt déclenché en fin de séance
        reçoit son renvoi à la séance suivante (plus prudent que 0.3.1)."""
        out = []
        p = self.s['renvoi_periode_j']
        for z in sorted(self.zones):
            d = self.zones[z]
            debut = d.arret_depuis
            if debut is None:
                continue
            r = d.renvoi_jour
            if r is None or r < debut or (self.jour - debut) // p > (r - debut) // p:
                d.renvoi_jour = self.jour
                out.append(z)
        return out

    def palier_bilan(self, bilan):
        """Palier du bilan de santé du jour (0, 1, 2) et décalage (règle
        A5.1 de 0.3.1)."""
        if not bilan:
            return 0, 0.0
        general = bilan.get('overall')
        decal = 0.0
        if general is not None and general < 4:
            decal -= 0.015 * (4 - general)
        detail = 0.0
        heures = bilan.get('sleepHours')
        if heures is not None and heures < 6:
            detail -= 0.01 * min(3.0, 6 - heures)
        for k in ('sleepQuality', 'energy', 'mood', 'soreness', 'stress', 'motivation', 'nutrition', 'hydration'):
            v = bilan.get(k)
            if v is not None and v <= 2:
                detail -= 0.01
        decal = decal + 0.5 * detail if general is not None else detail
        if decal < -0.08:
            decal = -0.08
        if decal <= self.s['bilan_palier2'] or (general is not None and general <= 1):
            return 2, decal
        if decal <= self.s['bilan_palier1'] or (general is not None and general <= 2):
            return 1, decal
        return 0, decal

    def hausse_max(self, fragile=False):
        h = self.s['hausse_par_niveau'][self.niveau]
        return h * self.s['hausse_fragile_facteur'] if fragile else h

    def conduite(self, niveaux_zone, stop_hits, est_test=False, depuis_jour=None, fiche=None,
                 echauffement=False):
        """Conduite d'un exercice sous la douleur. [niveaux_zone] : zone ->
        sollicitation (0, 0,5, 1) ; [stop_hits] : zones que le mouvement
        provoque ; [depuis_jour] : jour de la dernière séance de l'exercice
        (une zone signalée au-dessus du seuil depuis reste bloquante, même
        levée depuis : règle A1.1 de 0.3.1) ; [fiche] : fiche de l'exercice
        (type, contraintes, matériel ; règles du poignet) ; [echauffement] :
        ligne d'échauffement. Renvoie un dictionnaire : retire, series
        (facteur), rir (bonus), sans_hausse, rir_min, part_max (plafond en
        part du 1RM), hausse_quantite (plafond de hausse des répétitions ou
        secondes), dose_plafonnee (jamais au-delà de la dose écrite, aucune
        hausse dans la séance), fragile (zone fragile du profil sollicitée),
        appui_neutre (gêne du poignet qui demanderait un appui neutre),
        raison."""
        s = self.s
        out = {'retire': False, 'series': 1.0, 'rir': 0.0, 'sans_hausse': False, 'rir_min': None,
               'part_max': None, 'hausse_quantite': None, 'raison': None, 'zone': None,
               'dose_plafonnee': False, 'fragile': self.fragile(niveaux_zone), 'appui_neutre': None,
               'poignet_sensible': False}

        def note(zone, raison):
            if out['raison'] is None:
                out['raison'] = raison
                out['zone'] = zone

        for z, niveau in niveaux_zone.items():
            if niveau <= 0 and z not in stop_hits:
                continue
            d = self.zones.get(z)
            if d is None:
                continue
            act = self.active(z)
            if self.arret(z):
                debut = d.arret_depuis if d.arret_depuis is not None else self.jour
                escalade = (self.jour - debut >= s['arret_escalade_j']
                            and d.pire_entre(self.jour - 6, self.jour) >= s['arret_persistance_min'])
                if z in stop_hits or (escalade and niveau >= 0.5):
                    out['retire'] = True
                    note(z, 'douleur_arret')
                    continue
                if niveau >= 0.5:
                    if est_test:
                        out['retire'] = True
                        note(z, 'douleur_arret')
                        continue
                    out['series'] = min(out['series'], s['reprise_depart'])
                    out['rir_min'] = max(out['rir_min'] or 0.0, s['reprise_rir'])
                    out['sans_hausse'] = True
                    out['part_max'] = min(out['part_max'] or 9.9, s['reprise_charge_base'])
                    # Premier palier de la reprise : dose écrite au plus,
                    # aucune hausse dans la séance (`inReturn` → `doseCapped`,
                    # A/session.dart:1309-1315 ; A/coach_advice.dart:109-150).
                    out['dose_plafonnee'] = True
                    note(z, 'douleur_arret')
                    continue
            part = self.reprise(z)
            if part is not None and (niveau >= 0.5 or z in stop_hits):
                if est_test:
                    out['retire'] = True
                    note(z, 'douleur_reprise')
                    continue
                out['series'] = min(out['series'], part)
                out['rir_min'] = max(out['rir_min'] or 0.0, s['reprise_rir'])
                out['sans_hausse'] = True
                out['part_max'] = min(out['part_max'] or 9.9,
                                      s['reprise_charge_base'] + s['reprise_charge_pente'] * (part - 0.5))
                out['hausse_quantite'] = s['reprise_hausse_quantite']
                out['dose_plafonnee'] = True   # A/session.dart:1309-1315
                note(z, 'douleur_reprise')
            if act > 0:
                if (niveau >= 1 and act >= s['douleur_forte_contrainte']) or \
                        (niveau >= 0.5 and act >= s['douleur_moyenne_contrainte']):
                    out['retire'] = True
                    note(z, 'douleur')
                    continue
                if niveau >= 0.5:
                    if est_test:
                        out['retire'] = True
                        note(z, 'douleur')
                        continue
                    out['sans_hausse'] = True
                    out['rir'] = max(out['rir'], s['douleur_rir_bonus'])
                    if act >= s['douleur_allegement']:
                        out['series'] = min(out['series'], s['douleur_allegement_series'])
                    note(z, 'douleur')
            elif est_test and niveau >= 0.5 and self.signalee_semaine(z):
                out['retire'] = True
                note(z, 'douleur')
            if act <= 0 and niveau >= 0.5 and depuis_jour is not None \
                    and d.pire_entre(depuis_jour, self.jour) > s['douleur_seuil']:
                out['sans_hausse'] = True
                out['rir'] = max(out['rir'], s['douleur_rir_bonus'])
                note(z, 'douleur')
            if self.recente(z) and (niveau >= 0.5 or z in stop_hits) and out['hausse_quantite'] is None:
                out['hausse_quantite'] = s['reprise_hausse_quantite']
        if not out['retire']:
            self._poignet(out, niveaux_zone, stop_hits, fiche, est_test, echauffement)
        return out

    def _poignet(self, out, niveaux_zone, stop_hits, fiche, est_test, echauffement):
        """Règles du poignet de 0.3.1 (inventaire A4), après la conduite
        générale sous la douleur."""
        s = self.s
        fiche = fiche or {}
        n = niveaux_zone.get(POIGNET, 0.0)
        neutre = self.appui_neutre(fiche)
        if self.arret(POIGNET) and n >= 0.5:
            # A4.2, poignet « chaud » (arrêt en cours et gêne ≥ 3/10 dans la
            # semaine) : tout ce qui charge le poignet est retiré,
            # échauffement compris, sauf un appui parallettes ou poignées à
            # contrainte moins que forte (A/session.dart:816-849).
            if self.poignet_chaud() and (not neutre or n >= 1):
                out['retire'] = True
                out['raison'] = 'poignet_chaud'   # la cause du retrait prime sur la conduite notée avant
                out['zone'] = POIGNET
                return
            # A4.2 : toute charge externe sur un appui qui charge le poignet
            # est retirée dès l'arrêt (arrêt gardé compris), prise neutre
            # comprise ; l'échauffement reste (A/session.dart:838-849).
            if fiche.get('type') == 'charge' and not echauffement:
                out['retire'] = True
                out['raison'] = 'poignet_charge'   # la cause du retrait prime sur la conduite notée avant
                out['zone'] = POIGNET
                return
        if POIGNET in stop_hits:
            # A4.1, première gêne du poignet (≥ 3/10 dans les deux semaines,
            # avant tout arrêt) sur une poussée au poids du corps à contrainte
            # moyenne qui n'est pas déjà sur appui neutre
            # (A/session.dart:442-487). 0.3.1 la remplace par un appui neutre
            # faisable aujourd'hui ; Koach ne connaît ni le matériel du jour
            # ni de remplaçant : la ligne est gardée à la dose écrite (le
            # repli de 0.3.1 sans appui neutre) et, plus prudent, sans hausse ;
            # l'appui neutre est conseillé (raison).
            gene = self.poignet_gene()
            if gene and not self.arret(POIGNET) and not est_test and not echauffement \
                    and fiche.get('type') == 'reps' \
                    and (fiche.get('contraintes') or {}).get('poignet') == 'moyenne' and not neutre:
                out['appui_neutre'] = gene
                out['sans_hausse'] = True
                out['dose_plafonnee'] = True
            # A4.3, poignet sensible : la dose écrite au plus sur toute ligne
            # qui provoque le poignet (A/session.dart:1330-1335, 1688-1716).
            if self.poignet_sensible():
                out['dose_plafonnee'] = True
                out['poignet_sensible'] = True
