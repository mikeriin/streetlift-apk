part of 'koach.dart';

// Garde-fous de Koach 1.0 (référence `koach/securite.py`, contrat § 8) :
// les règles de sécurité de `kalis_adapt` 0.3.1 reprises comme contraintes
// dures. Ce module ne propose rien : il borne. Il tient l'état de la douleur
// par zone (seuil, zone active, arrêt, reprise graduée), lit le bilan de
// santé du jour (paliers 0, 1, 2) et donne à la prescription de séance les
// limites à respecter.

const List<String> zonesBas = [
  'hip',
  'thigh',
  'knee',
  'lower_leg',
  'ankle_foot',
];
const String poignet = 'wrist_hand';
const List<String> semainesVerrouillees = [
  'intro',
  'deload',
  'taper',
  'test',
  'competition',
  'transition',
];
const List<String?> semainesDeCharge = [
  'accumulation',
  'intensification',
  'realization',
  'intro',
  null,
  'maintenance',
];

/// `d.get(k, defaut)` de Python (défaut seulement si la clé manque).
Object? _secGet(Json d, String k, Object? defaut) =>
    d.containsKey(k) ? d[k] : defaut;

/// `min(a, b)` de Python sur des flottants (le premier sauf si le second
/// est plus petit).
double _secMin(double a, double b) => b < a ? b : a;

/// `max(a, b)` de Python sur des flottants.
double _secMax(double a, double b) => b > a ? b : a;

/// `x or defaut` de Python sur un nombre JSON facultatif.
double _secOu(Object? v, double defaut) => vrai(v) ? dbl(v) : defaut;

/// État de la douleur d'une zone : signalements datés (jour, intensité).
class Douleur {
  /// (jour, intensité max du jour).
  final List<(int, num)> signalements = [];
  int? arretDepuis;

  /// Jour de la dernière levée.
  int? arretLeve;
  int seancesDeSuite = 0;

  /// Jour du dernier renvoi vers un professionnel.
  int? renvoiJour;

  void noter(int jour, num intensite) {
    if (signalements.isNotEmpty && signalements.last.$1 == jour) {
      if (intensite > signalements.last.$2) {
        signalements[signalements.length - 1] = (jour, intensite);
      }
    } else {
      signalements.add((jour, intensite));
    }
  }

  (int, num)? derniere() => signalements.isNotEmpty ? signalements.last : null;

  num pireEntre(num debut, num fin) {
    num v = 0;
    for (final (j, i) in signalements) {
      if (debut <= j && j <= fin && i > v) {
        v = i;
      }
    }
    return v;
  }
}

class Gardefous {
  Gardefous(Json params, this.niveau, [Object? zonesFragiles])
    : s = jm(params['securite']) {
    fragiles = _zonesFragiles(zonesFragiles);
  }

  Json s;
  final int niveau;
  final Map<String, Douleur> zones = {};
  late final List<String> fragiles;
  int jour = 0;
  int? dernierJourSeance;
  int? avantDernierJourSeance;

  /// Indice de semaine -> semaine de charge.
  final Map<int, bool> semaines = {};
  int semaine = 0;

  num _n(String k) => s[k] as num;

  /// Zones fragiles du profil (règle A7.2 de 0.3.1) : antécédent de moins
  /// de 12 mois ou gêne déclarée ≥ `fragile_gene_min`. Une entrée réduite
  /// au code de la zone est tenue pour fragile. Liste triée.
  List<String> _zonesFragiles(Object? zonesIn) {
    final out = <String>{};
    for (final z in listeOuVide(zonesIn)) {
      if (z is Map<String, Object?>) {
        final code = z['zone'];
        if (!vrai(code)) {
          continue;
        }
        final gene = z['discomfort'];
        if (dans(z['since'], jl(s['fragile_anciennetes'])) ||
            (gene != null && (gene as num) >= _n('fragile_gene_min'))) {
          out.add(code as String);
        }
      } else if (vrai(z)) {
        out.add(z as String);
      }
    }
    return out.toList()..sort();
  }

  /// Première zone fragile du profil (ordre trié) que l'exercice sollicite
  /// (niveau ≥ `fragile_niveau_min`), ou null.
  String? fragile(Json niveauxZone) {
    for (final z in fragiles) {
      if ((_secGet(niveauxZone, z, 0.0) as num) >= _n('fragile_niveau_min')) {
        return z;
      }
    }
    return null;
  }

  /// Genre de la semaine en cours (contexte de la séance).
  void noterSemaine(int semaine, Object? genre, [Object? intention]) {
    final gg = ou(intention, genre);
    this.semaine = semaine;
    semaines[semaine] = !const [
      'deload',
      'taper',
      'test',
      'competition',
      'transition',
    ].contains(gg);
  }

  /// Nombre de semaines de charge écoulées depuis la levée d'un arrêt (hors
  /// semaine en cours), et vrai si une semaine de charge a commencé depuis.
  (int, bool) _semainesDeCharge(int leve) {
    final premiere = 7 - (leve % 7) >= 4
        ? divEnt(leve, 7)
        : divEnt(leve, 7) + 1;
    var n = 0;
    var commencee = false;
    for (var w = premiere; w < semaine + 1; w++) {
      if (semaines[w] ?? false) {
        commencee = true;
        if (w < semaine) {
          n += 1;
        }
      }
    }
    return (n, commencee);
  }

  Douleur zone(String z) {
    if (!zones.containsKey(z)) {
      zones[z] = Douleur();
    }
    return zones[z]!;
  }

  // ------------------------------------------------------------------
  // Signalements
  // ------------------------------------------------------------------

  /// Douleurs signalées (bilan et séance). Une liste vide posée met les
  /// zones suivies à 0 ; une question non posée ne change rien.
  void noterSeance(int jour, List<Object?> douleurs, {bool posee = true}) {
    this.jour = jour;
    final cites = <String, num>{};
    for (final d0 in douleurs) {
      final d = jm(d0);
      final z = d['zone'] as String;
      final intensite = d['intensity'] as num;
      if (intensite > (cites[z] ?? -1)) {
        cites[z] = intensite;
      }
    }
    for (final e in cites.entries) {
      zone(e.key).noter(jour, e.value);
    }
    if (posee) {
      for (final e in zones.entries) {
        if (!cites.containsKey(e.key)) {
          e.value.noter(jour, 0);
        }
      }
    }
    for (final d in zones.values) {
      final dern = d.derniere();
      if (dern != null && dern.$1 == jour) {
        d.seancesDeSuite = dern.$2 > _n('douleur_seuil')
            ? d.seancesDeSuite + 1
            : 0;
      }
    }
    _arrets(jour);
  }

  /// Signalements ≥ seuil de persistance de l'épisode en cours, et fin de
  /// l'épisode précédent.
  (List<(int, num)>, List<(int, num)>?) _episode(Douleur d) {
    final forts = [
      for (final e in d.signalements)
        if (e.$2 >= _n('arret_persistance_min')) e,
    ];
    if (forts.isEmpty) {
      return (<(int, num)>[], null);
    }
    final episode = <(int, num)>[forts.last];
    List<(int, num)>? precedent;
    for (var k = forts.length - 2; k > -1; k--) {
      if (episode[0].$1 - forts[k].$1 <= _n('arret_levee_j')) {
        episode.insert(0, forts[k]);
      } else {
        precedent = forts.sublist(0, k + 1);
        break;
      }
    }
    return (episode, precedent);
  }

  void _arrets(int jour) {
    for (final d in zones.values) {
      final (episode, precedent) = _episode(d);
      if (episode.isEmpty) {
        continue;
      }
      final dernier = episode.last.$1;
      if (d.arretDepuis != null) {
        if (jour - dernier >= _n('arret_levee_j')) {
          d.arretLeve = dernier + ent(s['arret_levee_j']);
          d.arretDepuis = null;
        }
        continue;
      }
      if (jour - dernier >= _n('arret_levee_j')) {
        continue;
      }
      final dure = dernier - episode[0].$1 >= _n('arret_persistance_j');
      final fortes = [
        for (final e in episode)
          if (e.$2 >= _n('arret_forte_min')) e.$1,
      ];
      final forte =
          fortes.length >= 2 && fortes.last - fortes[0] >= _n('arret_forte_j');
      var retour = false;
      if (precedent != null && precedent.isNotEmpty) {
        num pire = precedent[0].$2;
        for (final e in precedent) {
          if (e.$2 > pire) {
            pire = e.$2;
          }
        }
        final reel = precedent.length >= 2 || pire >= 4;
        retour =
            reel && episode[0].$1 - precedent.last.$1 <= _n('arret_retour_j');
      }
      final suite = d.seancesDeSuite >= _n('arret_seances_de_suite');
      if (dure || forte || retour || suite) {
        d.arretDepuis = jour;
      }
    }
  }

  void avancer(int jour) {
    this.jour = jour;
    _arrets(jour);
  }

  // ------------------------------------------------------------------
  // Lecture
  // ------------------------------------------------------------------
  num active(String z) {
    final d = zones[z];
    if (d == null || d.signalements.isEmpty) {
      return 0;
    }
    final (j, i) = d.signalements.last;
    if (i > _n('douleur_seuil') && jour - j <= _n('douleur_jours_actifs')) {
      return i;
    }
    return 0;
  }

  Map<String, num> actives() => {
    for (final z in zones.keys)
      if (active(z) > 0) z: active(z),
  };

  /// Zone à l'arrêt, ou arrêt gardé : levée récente sans qu'une semaine de
  /// charge ait commencé depuis (règle A3.2 de 0.3.1).
  bool arret(String z) {
    final d = zones[z];
    if (d == null) {
      return false;
    }
    if (d.arretDepuis != null) {
      return true;
    }
    final leve = d.arretLeve;
    if (leve != null &&
        0 <= jour - leve &&
        jour - leve <= _n('reprise_surveillance_j')) {
      final (_, commencee) = _semainesDeCharge(leve);
      return !commencee;
    }
    return false;
  }

  List<String> arrets() => [
    for (final z in zones.keys)
      if (arret(z)) z,
  ];

  /// Part du volume écrit pendant la reprise graduée (null hors reprise) :
  /// départ 50 %, +10 % par semaine de charge, recul si la gêne remonte.
  double? reprise(String z) {
    final d = zones[z];
    if (d == null || d.arretLeve == null || d.arretDepuis != null) {
      return null;
    }
    final leve = d.arretLeve!;
    final depuis = jour - leve;
    if (depuis > _n('reprise_surveillance_j') || depuis < 0) {
      return null;
    }
    final (n, _) = _semainesDeCharge(leve);
    var part = dbl(s['reprise_depart']) + dbl(s['reprise_pas']) * n;
    if (d.pireEntre(jour - 6, jour) > _n('reprise_douleur_max')) {
      part -= dbl(s['reprise_pas']);
    }
    if (part < dbl(s['reprise_plancher'])) {
      part = dbl(s['reprise_plancher']);
    }
    return part >= 1.0 ? null : part;
  }

  bool recente(String z) {
    final d = zones[z];
    if (d == null) {
      return false;
    }
    if (d.arretDepuis != null) {
      return true;
    }
    if (d.arretLeve != null &&
        jour - d.arretLeve! <= _n('reprise_surveillance_j')) {
      return true;
    }
    final dern = d.derniere();
    return dern != null &&
        dern.$1 == jour &&
        dern.$2 > _n('reprise_douleur_max');
  }

  bool signaleeSemaine(String z) {
    final d = zones[z];
    return d != null && d.pireEntre(jour - 6, jour) > _n('reprise_douleur_max');
  }

  // ------------------------------------------------------------------
  // Poignet (règles A4 de 0.3.1)
  // ------------------------------------------------------------------

  /// Appui qui garde le poignet neutre : parallettes ou poignées.
  bool appuiNeutre(Json? fiche) {
    final materiel = listeOuVide(dictOuVide(fiche)['materiel']);
    return jl(
      s['poignet_appui_neutre_materiel'],
    ).any((mt) => dans(mt, materiel));
  }

  /// Pire gêne du poignet ≥ `arret_persistance_min` signalée dans les
  /// `poignet_gene_j` derniers jours, sinon 0.
  num poignetGene() {
    final d = zones[poignet];
    if (d == null) {
      return 0;
    }
    final v = d.pireEntre(jour - _n('poignet_gene_j') + 1, jour);
    return v >= _n('arret_persistance_min') ? v : 0;
  }

  /// Poignet à l'arrêt (en cours, pas gardé) et signalé
  /// ≥ `arret_persistance_min` dans les `poignet_chaud_j` derniers jours.
  bool poignetChaud() {
    final d = zones[poignet];
    if (d == null || d.arretDepuis == null) {
      return false;
    }
    return d.pireEntre(jour - _n('poignet_chaud_j') + 1, jour) >=
        _n('arret_persistance_min');
  }

  /// Appui du poignet sensible : zone fragile du profil, arrêt (en cours
  /// ou gardé), reprise graduée, ou gêne ≥ `poignet_sensible_min` dans les
  /// `poignet_sensible_j` derniers jours.
  bool poignetSensible() {
    if (fragiles.contains(poignet)) {
      return true;
    }
    final d = zones[poignet];
    if (d == null) {
      return false;
    }
    if (arret(poignet)) {
      return true;
    }
    final leve = d.arretLeve;
    if (leve != null &&
        0 <= jour - leve &&
        jour - leve <= _n('reprise_surveillance_j')) {
      return true;
    }
    return d.pireEntre(jour - _n('poignet_sensible_j') + 1, jour) >=
        _n('poignet_sensible_min');
  }

  // ------------------------------------------------------------------
  // Bas du corps (règles A2.3 et A10.2 de 0.3.1)
  // ------------------------------------------------------------------

  /// Plus forte dernière intensité des zones du bas du corps signalées
  /// depuis ≤ `douleur_jours_actifs` jours (la gêne sous le seuil compte).
  num douleurJambe() {
    num v = 0;
    for (final z in zonesBas) {
      final d = zones[z];
      if (d == null || d.signalements.isEmpty) {
        continue;
      }
      final (j, i) = d.signalements.last;
      if (jour - j <= _n('douleur_jours_actifs') && i > v) {
        v = i;
      }
    }
    return v;
  }

  /// Zones du bas du corps à l'arrêt (en cours, pas gardé), dans l'ordre de
  /// [zonesBas].
  List<String> arretsJambe() => [
    for (final z in zonesBas)
      if (zones.containsKey(z) && zones[z]!.arretDepuis != null) z,
  ];

  /// Vrai si une zone du bas du corps est en reprise graduée.
  bool repriseJambe() {
    for (final z in zonesBas) {
      if (zones.containsKey(z) && reprise(z) != null) {
        return true;
      }
    }
    return false;
  }

  /// Zones (ordre trié) dont l'arrêt appelle aujourd'hui le renvoi vers un
  /// professionnel : première séance de l'arrêt, puis première séance de
  /// chaque semaine d'arrêt. Le jour du dernier renvoi est retenu.
  List<String> renvois() {
    final out = <String>[];
    final p = ent(s['renvoi_periode_j']);
    final tri = zones.keys.toList()..sort();
    for (final z in tri) {
      final d = zones[z]!;
      final debut = d.arretDepuis;
      if (debut == null) {
        continue;
      }
      final r = d.renvoiJour;
      if (r == null ||
          r < debut ||
          divEnt(jour - debut, p) > divEnt(r - debut, p)) {
        d.renvoiJour = jour;
        out.add(z);
      }
    }
    return out;
  }

  /// Palier du bilan de santé du jour (0, 1, 2) et décalage (règle A5.1 de
  /// 0.3.1).
  (int, double) palierBilan(Json? bilan) {
    if (!vrai(bilan)) {
      return (0, 0.0);
    }
    final b = bilan!;
    final general = b['overall'] as num?;
    var decal = 0.0;
    if (general != null && general < 4) {
      decal -= 0.015 * (4 - general);
    }
    var detail = 0.0;
    final heures = b['sleepHours'] as num?;
    if (heures != null && heures < 6) {
      detail -= 0.01 * _secMin(3.0, (6 - heures).toDouble());
    }
    for (final k in const [
      'sleepQuality',
      'energy',
      'mood',
      'soreness',
      'stress',
      'motivation',
      'nutrition',
      'hydration',
    ]) {
      final v = b[k] as num?;
      if (v != null && v <= 2) {
        detail -= 0.01;
      }
    }
    decal = general != null ? decal + 0.5 * detail : detail;
    if (decal < -0.08) {
      decal = -0.08;
    }
    if (decal <= _n('bilan_palier2') || (general != null && general <= 1)) {
      return (2, decal);
    }
    if (decal <= _n('bilan_palier1') || (general != null && general <= 2)) {
      return (1, decal);
    }
    return (0, decal);
  }

  double hausseMax([bool fragile = false]) {
    final h = jld(s['hausse_par_niveau'])[niveau];
    return fragile ? h * dbl(s['hausse_fragile_facteur']) : h;
  }

  /// Conduite d'un exercice sous la douleur. [niveauxZone] : zone ->
  /// sollicitation (0, 0,5, 1) ; [stopHits] : zones que le mouvement
  /// provoque ; [depuisJour] : jour de la dernière séance de l'exercice ;
  /// [fiche] : fiche de l'exercice ; [echauffement] : ligne d'échauffement.
  /// Renvoie un dictionnaire : retire, series (facteur), rir (bonus),
  /// sans_hausse, rir_min, part_max, hausse_quantite, raison, zone,
  /// dose_plafonnee, fragile, appui_neutre, poignet_sensible.
  Json conduite(
    Json niveauxZone,
    Set<String> stopHits, {
    bool estTest = false,
    int? depuisJour,
    Json? fiche,
    bool echauffement = false,
  }) {
    final out = <String, Object?>{
      'retire': false,
      'series': 1.0,
      'rir': 0.0,
      'sans_hausse': false,
      'rir_min': null,
      'part_max': null,
      'hausse_quantite': null,
      'raison': null,
      'zone': null,
      'dose_plafonnee': false,
      'fragile': fragile(niveauxZone),
      'appui_neutre': null,
      'poignet_sensible': false,
    };

    void note(String zoneN, String raison) {
      if (out['raison'] == null) {
        out['raison'] = raison;
        out['zone'] = zoneN;
      }
    }

    for (final e in niveauxZone.entries) {
      final z = e.key;
      final niveau = e.value as num;
      if (niveau <= 0 && !stopHits.contains(z)) {
        continue;
      }
      final d = zones[z];
      if (d == null) {
        continue;
      }
      final act = active(z);
      if (arret(z)) {
        final debut = d.arretDepuis ?? jour;
        final escalade =
            jour - debut >= _n('arret_escalade_j') &&
            d.pireEntre(jour - 6, jour) >= _n('arret_persistance_min');
        if (stopHits.contains(z) || (escalade && niveau >= 0.5)) {
          out['retire'] = true;
          note(z, 'douleur_arret');
          continue;
        }
        if (niveau >= 0.5) {
          if (estTest) {
            out['retire'] = true;
            note(z, 'douleur_arret');
            continue;
          }
          out['series'] = _secMin(dbl(out['series']), dbl(s['reprise_depart']));
          out['rir_min'] = _secMax(
            _secOu(out['rir_min'], 0.0),
            dbl(s['reprise_rir']),
          );
          out['sans_hausse'] = true;
          out['part_max'] = _secMin(
            _secOu(out['part_max'], 9.9),
            dbl(s['reprise_charge_base']),
          );
          // Premier palier de la reprise : dose écrite au plus, aucune
          // hausse dans la séance.
          out['dose_plafonnee'] = true;
          note(z, 'douleur_arret');
          continue;
        }
      }
      final part = reprise(z);
      if (part != null && (niveau >= 0.5 || stopHits.contains(z))) {
        if (estTest) {
          out['retire'] = true;
          note(z, 'douleur_reprise');
          continue;
        }
        out['series'] = _secMin(dbl(out['series']), part);
        out['rir_min'] = _secMax(
          _secOu(out['rir_min'], 0.0),
          dbl(s['reprise_rir']),
        );
        out['sans_hausse'] = true;
        out['part_max'] = _secMin(
          _secOu(out['part_max'], 9.9),
          dbl(s['reprise_charge_base']) +
              dbl(s['reprise_charge_pente']) * (part - 0.5),
        );
        out['hausse_quantite'] = dbl(s['reprise_hausse_quantite']);
        out['dose_plafonnee'] = true;
        note(z, 'douleur_reprise');
      }
      if (act > 0) {
        if ((niveau >= 1 && act >= _n('douleur_forte_contrainte')) ||
            (niveau >= 0.5 && act >= _n('douleur_moyenne_contrainte'))) {
          out['retire'] = true;
          note(z, 'douleur');
          continue;
        }
        if (niveau >= 0.5) {
          if (estTest) {
            out['retire'] = true;
            note(z, 'douleur');
            continue;
          }
          out['sans_hausse'] = true;
          out['rir'] = _secMax(dbl(out['rir']), dbl(s['douleur_rir_bonus']));
          if (act >= _n('douleur_allegement')) {
            out['series'] = _secMin(
              dbl(out['series']),
              dbl(s['douleur_allegement_series']),
            );
          }
          note(z, 'douleur');
        }
      } else if (estTest && niveau >= 0.5 && signaleeSemaine(z)) {
        out['retire'] = true;
        note(z, 'douleur');
      }
      if (act <= 0 &&
          niveau >= 0.5 &&
          depuisJour != null &&
          d.pireEntre(depuisJour, jour) > _n('douleur_seuil')) {
        out['sans_hausse'] = true;
        out['rir'] = _secMax(dbl(out['rir']), dbl(s['douleur_rir_bonus']));
        note(z, 'douleur');
      }
      if (recente(z) &&
          (niveau >= 0.5 || stopHits.contains(z)) &&
          out['hausse_quantite'] == null) {
        out['hausse_quantite'] = dbl(s['reprise_hausse_quantite']);
      }
    }
    if (!vrai(out['retire'])) {
      _poignet(out, niveauxZone, stopHits, fiche, estTest, echauffement);
    }
    return out;
  }

  /// Règles du poignet de 0.3.1 (inventaire A4), après la conduite générale
  /// sous la douleur.
  void _poignet(
    Json out,
    Json niveauxZone,
    Set<String> stopHits,
    Json? fiche0,
    bool estTest,
    bool echauffement,
  ) {
    final fiche = dictOuVide(fiche0);
    final n = _secGet(niveauxZone, poignet, 0.0) as num;
    final neutre = appuiNeutre(fiche);
    if (arret(poignet) && n >= 0.5) {
      // A4.2, poignet « chaud » : tout ce qui charge le poignet est
      // retiré, échauffement compris, sauf un appui neutre à contrainte
      // moins que forte.
      if (poignetChaud() && (!neutre || n >= 1)) {
        out['retire'] = true;
        out['raison'] = 'poignet_chaud';
        out['zone'] = poignet;
        return;
      }
      // A4.2 : toute charge externe sur un appui qui charge le poignet est
      // retirée dès l'arrêt ; l'échauffement reste.
      if (fiche['type'] == 'charge' && !echauffement) {
        out['retire'] = true;
        out['raison'] = 'poignet_charge';
        out['zone'] = poignet;
        return;
      }
    }
    if (stopHits.contains(poignet)) {
      // A4.1, première gêne du poignet sur une poussée au poids du corps à
      // contrainte moyenne qui n'est pas déjà sur appui neutre : dose écrite,
      // sans hausse ; l'appui neutre est conseillé.
      final gene = poignetGene();
      if (vrai(gene) &&
          !arret(poignet) &&
          !estTest &&
          !echauffement &&
          fiche['type'] == 'reps' &&
          dictOuVide(fiche['contraintes'])['poignet'] == 'moyenne' &&
          !neutre) {
        out['appui_neutre'] = gene;
        out['sans_hausse'] = true;
        out['dose_plafonnee'] = true;
      }
      // A4.3, poignet sensible : la dose écrite au plus sur toute ligne qui
      // provoque le poignet.
      if (poignetSensible()) {
        out['dose_plafonnee'] = true;
        out['poignet_sensible'] = true;
      }
    }
  }
}
