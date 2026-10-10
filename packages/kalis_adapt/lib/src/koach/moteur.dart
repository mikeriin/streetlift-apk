part of 'koach.dart';

// Façade du moteur (référence `koach/moteur.py`, contrat § 3) :
//   observe(evenement), posterior(), plan(contraintes), explain().
// L'état se recalcule depuis le journal (`rejouer`).

/// Module branché sur le moteur (planification, adhérence, surveillance,
/// contrôle dual). Les crochets sont appelés dans l'ordre de
/// [Koach.extensions].
abstract class Extension {
  void finSeance(Koach koach, ResumeSeance? resume, Json e) {}

  void seanceManquee(Koach koach, Json e) {}

  void finSemaine(Koach koach, Json ligne, Json e) {}

  void decision(Koach koach, Json e) {}

  Object? planSemaine(Koach koach, Json c) => null;
}

/// Extension prévenue quand la surveillance lève l'alerte hors modèle.
abstract interface class AvecAlerteHorsModele {
  void surAlerteHorsModele(Koach koach, List<String> causes);
}

/// Extension qui relit ses paramètres après un import (événement
/// `parametres`).
abstract interface class AvecParametres {
  void appliquerParametres(Json params);
}

/// Extension qui fixe l'hypothèse de dose de la semaine (tirage de
/// Thompson du contrôle dual).
abstract interface class AvecHypothese {
  int? hypothesePourLaSemaine(Koach koach, int semaine, int graine);
}

/// Le moteur Koach : estimation, prescription, garde-fous.
class Koach {
  Koach(this.params, this.fiches, this.profil)
    : modele = Modele(params, fiches, profil) {
    garde = Gardefous(params, modele.niveau, profil['zones_fragiles']);
    seances = Seances(params, modele, garde, fiches);
  }

  Json params;
  final Map<String, Json> fiches;
  final Json profil;
  final Modele modele;
  late final Gardefous garde;
  late final Seances seances;
  final List<Json> journal = [];
  List<Json> raisons = [];
  int jour = 0;
  final List<Extension> extensions = [];

  /// Verse un événement du journal (§ 2.1).
  void observe(Json e) {
    journal.add(e);
    final typ = e['type'];
    final m = modele;
    if (typ == 'seance_debut') {
      jour = ent(e['jour']);
      garde.avancer(jour);
      final bilan = jmOu(e['bilan']);
      if (bilan != null && bilan['pains'] != null) {
        garde.noterSeance(jour, jl(bilan['pains']), posee: true);
      }
      m.debutSeance(jour, bilan, e['poids_kg']);
      seances.ouvrir(jour, bilan, dictOuVide(e['contexte']));
    } else if (typ == 'serie') {
      m.observerSerie(jm(e['serie']));
      seances.serieFaite(jm(e['serie']));
    } else if (typ == 'seance_fin') {
      final douleurs = e['douleurs'];
      if (vrai(douleurs)) {
        garde.noterSeance(jour, jl(douleurs), posee: false);
      }
      seances.fermer(dictOuVide(e['seance']));
      final resume = m.finSeance();
      for (final x in extensions) {
        x.finSeance(this, resume, e);
      }
    } else if (typ == 'seance_manquee') {
      for (final x in extensions) {
        x.seanceManquee(this, e);
      }
    } else if (typ == 'semaine_fin') {
      m.avancer(ent(e['jour']));
      final ligne = m.finSemaine();
      for (final x in extensions) {
        x.finSemaine(this, ligne, e);
      }
    } else if (typ == 'cran') {
      m.changerCran(e['exerciseId'] as String, dbl(e['facteur']));
    } else if (typ == 'poids') {
      if (e['poids_kg'] != null && dbl(e['poids_kg']) > 0) {
        m.poidsKg = dbl(e['poids_kg']);
      }
    } else if (typ == 'decision') {
      for (final x in extensions) {
        x.decision(this, e);
      }
    } else if (typ == 'charge_manuelle') {
      m.observerChargeManuelle(
        e['exerciseId'] as String,
        e['loadKg'],
        e['reps'],
        e['rir'],
      );
    } else if (typ == 'parametres') {
      appliquerParametres(this, jm(e['fichier']));
    } else if (typ == 'plan') {
      _plan(jm(e['contraintes']));
    }
  }

  /// L'a posteriori lisible (§ 3.4).
  Json posterior() {
    final m = modele;
    final exercices = <String, Object?>{};
    for (final exId in m.ordre) {
      final t = m.pistes[exId]!;
      final (mu, sd) = m.capacite(exId)!;
      final iv = m.intervalle(exId)!;
      exercices[exId] = <String, Object?>{
        'type': t.type,
        'ln_capacite': mu,
        'ecart_type': sd,
        'valeur': m.valeur(exId),
        'intervalle_90': [iv.$1, iv.$2, iv.$3],
        'seances': t.seances,
        'mesures': t.mesures,
      };
    }
    double sdDe(int i) {
      final v = m.pget(i, i);
      return math.sqrt(v > 0.0 ? v : 0.0);
    }

    return <String, Object?>{
      'jour': m.jour,
      'qualites': [for (var q = 0; q < nq; q++) m.m[th + q]],
      'qualites_sd': [for (var q = 0; q < nq; q++) sdDe(th + q)],
      'reponse': m.m[rho],
      'reponse_sd': sdDe(rho),
      'reponse_classes': [for (var c = 0; c < 5; c++) m.m[eps + c]],
      'fatigue_sensibilite': <String, Object?>{
        'nerveux_systemique': m.m[kn],
        'nerveux_local': m.m[kl],
        'musculaire_systemique': m.m[kg],
        'musculaire_local': m.m[km],
      },
      'fatigue': <String, Object?>{
        'nerveux': <String, Object?>{
          'systemique': m.fG[0],
          'local': List<double>.of(m.fL[0]),
        },
        'musculaire': <String, Object?>{
          'systemique': m.fG[1],
          'local': List<double>.of(m.fL[1]),
        },
        'tendineux': Map<String, Object?>.of(m.fTendon),
        'tau': List<double>.of(m.tau),
      },
      'biais_rir': [m.m[ba], m.m[bp]],
      'bruit_rir': m.bruitRir,
      'courbe': [m.m[lam], m.m[ku]],
      'fatigue_intra': m.m[fi],
      'part_tenue': m.m[hh],
      'note_paresseuse': m.paresse[0] / (m.paresse[0] + m.paresse[1]),
      'hypotheses_reponse': List<double>.of(m.poidsHyp),
      'exercices': exercices,
    };
  }

  /// La séance, la série suivante ou la semaine (§ 3.3). L'appel est versé
  /// au journal (événement `plan`).
  Object? plan(Json c) {
    final cc = canonique(c);
    journal.add(<String, Object?>{'type': 'plan', 'contraintes': cc});
    return _plan(cc);
  }

  /// Forme journalisable (JSON) des contraintes.
  static Json canonique(Json c0) {
    final c = Map<String, Object?>.of(c0);
    if (c['horizon'] == 'seance') {
      final ids = <String>[];
      for (final it in listeOuVide(c['items'])) {
        final ex = jm(it)['exerciseId'] as String;
        if (!ids.contains(ex)) {
          ids.add(ex);
        }
      }
      final grilles = <String, Object?>{};
      final zones = <String, Object?>{};
      final gIn = dictOuVide(c['grilles']);
      final zIn = dictOuVide(c['zones']);
      for (final ex in ids) {
        final g = gIn[ex];
        if (g != null) {
          if (g is Grille) {
            grilles[ex] = <String, Object?>{
              'pas': g.pas,
              'minimum': g.minimum,
              'halteres': vrai(g.halteres),
            };
          } else {
            grilles[ex] = Map<String, Object?>.of(jm(g));
          }
        }
        final z = zIn[ex];
        if (z != null) {
          final Json niveaux;
          final Iterable<Object?> provoquees;
          if (z is (Json, Set<String>)) {
            niveaux = z.$1;
            provoquees = z.$2;
          } else {
            final zl = jl(z);
            niveaux = jm(zl[0]);
            provoquees = zl[1] as Iterable<Object?>;
          }
          final tri = [for (final x in provoquees) x as String]..sort();
          zones[ex] = <Object?>[Map<String, Object?>.of(niveaux), tri];
        }
      }
      final slots = [
        for (final it in listeOuVide(c['items'])) jm(it)['slotId'],
      ];
      final roles = <String, Object?>{
        for (final e in dictOuVide(c['roles']).entries)
          if (slots.contains(e.key)) e.key: e.value,
      };
      c['grilles'] = grilles;
      c['zones'] = zones;
      c['roles'] = roles;
    }
    return copieJson(c);
  }

  Object? _plan(Json c) {
    final h = c['horizon'];
    if (h == 'seance') {
      final grilles = <String, Grille>{
        for (final e in dictOuVide(c['grilles']).entries)
          e.key: Grille(
            dbl(jm(e.value)['pas']),
            dbl(jm(e.value)['minimum']),
            vrai(jm(e.value)['halteres']),
          ),
      };
      final zones = <String, (Json, Set<String>)>{
        for (final e in dictOuVide(c['zones']).entries)
          e.key: (
            Map<String, Object?>.of(jm(jl(e.value)[0])),
            {for (final z in jl(jl(e.value)[1])) z as String},
          ),
      };
      final items = seances.prescrire(
        [for (final it in jl(c['items'])) jm(it)],
        grilles,
        zones,
        dictOuVide(c['roles']),
      );
      raisons = List<Json>.of(seances.raisons);
      return <String, Object?>{'items': items, 'raisons': raisons};
    }
    if (h == 'serie') {
      final cible = seances.cible(
        jm(c['item']),
        ent(c['index']),
        listeOuVide(c['faites']),
      );
      raisons = List<Json>.of(seances.raisons);
      return cible;
    }
    if (h == 'semaine') {
      Object? out;
      for (final x in extensions) {
        final r = x.planSemaine(this, c);
        if (r != null) {
          out = r;
        }
      }
      return out;
    }
    throw ArgumentError('horizon inconnu : $h');
  }

  /// Les raisons des dernières décisions (§ 3.5).
  List<Json> explain() => List<Json>.of(raisons);
}

/// Recalcule l'état depuis le journal.
Koach rejouer(
  Json params,
  Map<String, Json> fiches,
  Json profil,
  List<Json> journal, [
  List<Extension Function()> extensions = const [],
]) {
  final k = Koach(params, fiches, profil);
  for (final f in extensions) {
    k.extensions.add(f());
  }
  for (final e in journal) {
    k.observe(e);
  }
  return k;
}
