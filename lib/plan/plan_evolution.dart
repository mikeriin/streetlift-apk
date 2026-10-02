// G10 (D5.1, D5.6, D5.7, D5.11) : évolution du programme — propositions du
// moteur dynamique (`kalis_adapt`) et suites données, telles que
// l'application les garde.
//
// Section `planEvolution` (v1, facultative) de la sauvegarde : une entrée
// par proposition reçue, avec la proposition du moteur telle quelle
// (`Proposal`, relue par `fromJson`) et sa suite (appliquée par le mode
// assisté, acceptée, refusée, annulée, en attente). Les blocs du programme
// ne sont jamais réécrits : une proposition appliquée est une couche posée
// sur son bloc à la lecture ([evolvedBlock]), dans l'ordre des décisions ;
// l'annuler retire la couche. Le programme personnel du propriétaire
// (bloc importé) reste ainsi identique jour pour jour.
//
// Fonctions pures : aucune horloge (« aujourd'hui » passé en paramètre),
// aucune règle d'entraînement (le moteur décide, `applyProposal` applique).
import 'package:kalis_adapt/kalis_adapt.dart' as ka show applyProposal;
import 'package:kalis_core/kalis_core.dart' as kc;

const kPlanEvolutionVersion = 1;

/// Entrées gardées au plus (les plus anciennes sont retirées d'abord,
/// jamais une entrée appliquée).
const kEvolutionMaxEntries = 400;

/// Suites possibles d'une proposition.
abstract final class EvoStatus {
  /// Reçue en mode libre, sans réponse.
  static const pending = 'pending';

  /// Appliquée automatiquement (mode assisté).
  static const applied = 'applied';

  /// Acceptée par l'utilisateur (mode libre).
  static const accepted = 'accepted';

  /// Refusée (mode libre) : le moteur ne la repropose pas avant un délai.
  static const refused = 'refused';

  /// Appliquée puis annulée.
  static const undone = 'undone';

  static const all = {pending, applied, accepted, refused, undone};
}

final RegExp _dayRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');

bool _okDay(Object? v) =>
    v is String && _dayRe.hasMatch(v) && DateTime.tryParse(v) != null;

/// Une proposition du moteur et la suite donnée.
class EvolutionEntry {
  /// Proposition telle que le moteur l'a rendue (`id` = famille@semaine).
  final kc.Proposal proposal;

  /// Bloc concerné (`pass1.blockId` du bloc donné au moteur).
  final String blockId;

  /// Suite donnée ([EvoStatus]).
  final String status;

  /// Jour de la suite (AAAA-MM-JJ) ; null tant qu'elle est en attente.
  final String? decidedOn;

  /// Mode du profil au moment de la suite (`assisted`, `free`).
  final String mode;

  /// « Plus tard » : cachée jusqu'à ce jour exclu (AAAA-MM-JJ).
  final String? laterUntil;

  /// Message de Koach lu (« Compris ») : la carte de l'accueil ne la
  /// montre plus.
  final bool seen;

  const EvolutionEntry({
    required this.proposal,
    required this.blockId,
    required this.status,
    this.decidedOn,
    required this.mode,
    this.laterUntil,
    this.seen = false,
  });

  String get id => proposal.id;

  /// Semaine du bloc à partir de laquelle le changement s'applique (fin de
  /// l'identifiant `famille@semaine`) ; 0 si illisible.
  int get fromWeek {
    final i = id.lastIndexOf('@');
    return i < 0 ? 0 : int.tryParse(id.substring(i + 1)) ?? 0;
  }

  /// En place dans le programme (appliquée ou acceptée).
  bool get inEffect =>
      status == EvoStatus.applied || status == EvoStatus.accepted;

  EvolutionEntry copyWith({
    kc.Proposal? proposal,
    String? status,
    String? decidedOn,
    String? mode,
    String? laterUntil,
    bool clearLater = false,
    bool? seen,
  }) => EvolutionEntry(
    proposal: proposal ?? this.proposal,
    blockId: blockId,
    status: status ?? this.status,
    decidedOn: decidedOn ?? this.decidedOn,
    mode: mode ?? this.mode,
    laterUntil: clearLater ? null : (laterUntil ?? this.laterUntil),
    seen: seen ?? this.seen,
  );

  /// La proposition sans son bloc résultant (gardé seulement tant qu'il
  /// peut servir : en attente ou en place).
  EvolutionEntry slim() {
    if (inEffect || status == EvoStatus.pending) return this;
    if (proposal.block == null) return this;
    return copyWith(
      proposal: kc.Proposal.fromJson(
        Map<String, Object?>.of(proposal.toJson())..remove('block'),
      ),
    );
  }

  /// Suite donnée, au format du moteur (null : en attente).
  kc.ProposalDecision? get decision {
    final on = decidedOn;
    if (on == null) return null;
    final s = switch (status) {
      EvoStatus.applied => kc.ProposalStatus.autoApplied,
      EvoStatus.accepted => kc.ProposalStatus.accepted,
      EvoStatus.refused => kc.ProposalStatus.refused,
      EvoStatus.undone => kc.ProposalStatus.undone,
      _ => null,
    };
    if (s == null) return null;
    return kc.ProposalDecision(
      proposalId: id,
      date: kc.CivilDate.parse(on),
      status: s,
    );
  }

  Map<String, Object?> toJson() => {
    'proposal': proposal.toJson(),
    'blockId': blockId,
    'status': status,
    if (decidedOn != null) 'decidedOn': decidedOn,
    'mode': mode,
    if (laterUntil != null) 'laterUntil': laterUntil,
    if (seen) 'seen': true,
  };

  static EvolutionEntry fromJson(Object? raw) {
    if (raw is! Map) throw const FormatException('Proposition invalide.');
    final m = raw.cast<String, Object?>();
    final p = m['proposal'];
    if (p is! Map) throw const FormatException('Proposition invalide.');
    final proposal = kc.Proposal.fromJson(p.cast<String, Object?>());
    if (proposal.validate().isNotEmpty) {
      throw const FormatException('Proposition hors contrat.');
    }
    final blockId = m['blockId'];
    final status = m['status'];
    final mode = m['mode'];
    final decided = m['decidedOn'];
    final later = m['laterUntil'];
    final seen = m['seen'];
    if (blockId is! String ||
        blockId.isEmpty ||
        blockId.length > 80 ||
        status is! String ||
        !EvoStatus.all.contains(status) ||
        (mode != 'assisted' && mode != 'free') ||
        (decided != null && !_okDay(decided)) ||
        (status != EvoStatus.pending && decided == null) ||
        (later != null && !_okDay(later)) ||
        (seen != null && seen is! bool)) {
      throw const FormatException('Proposition invalide.');
    }
    return EvolutionEntry(
      proposal: proposal,
      blockId: blockId,
      status: status,
      decidedOn: decided as String?,
      mode: mode as String,
      laterUntil: later as String?,
      seen: seen == true,
    );
  }
}

/// Section `planEvolution` : propositions reçues et suites données.
class PlanEvolution {
  final int version;
  final List<EvolutionEntry> entries;
  const PlanEvolution({
    this.version = kPlanEvolutionVersion,
    this.entries = const [],
  });

  static const empty = PlanEvolution();

  bool get isEmpty => entries.isEmpty;

  EvolutionEntry? byId(String id, String blockId) {
    for (final e in entries) {
      if (e.id == id && e.blockId == blockId) return e;
    }
    return null;
  }

  /// Propositions en place sur le bloc [blockId], dans l'ordre où elles
  /// ont été appliquées.
  List<EvolutionEntry> inEffect(String blockId) => [
    for (final e in entries)
      if (e.blockId == blockId && e.inEffect) e,
  ];

  /// Suites données, pour le moteur (refus et annulations compris).
  List<kc.ProposalDecision> get decisions => [
    for (final e in entries)
      if (e.decision case final d?) d,
  ];

  PlanEvolution withEntries(List<EvolutionEntry> next) {
    var list = [for (final e in next) e.slim()];
    if (list.length > kEvolutionMaxEntries) {
      // Les plus anciennes d'abord, jamais une proposition en place ou en
      // attente.
      var drop = list.length - kEvolutionMaxEntries;
      final out = <EvolutionEntry>[];
      for (final e in list) {
        if (drop > 0 && !e.inEffect && e.status != EvoStatus.pending) {
          drop--;
          continue;
        }
        out.add(e);
      }
      list = out;
    }
    return PlanEvolution(version: version, entries: list);
  }

  Map<String, Object?> toJson() => {
    'v': version,
    'entries': [for (final e in entries) e.toJson()],
  };

  /// Lecture ; [FormatException] hors contrat.
  static PlanEvolution fromJson(Object? raw) {
    if (raw is! Map) throw const FormatException('Évolution : section.');
    final v = raw['v'];
    if (v is! int || v < 1 || v > kPlanEvolutionVersion) {
      throw const FormatException('Évolution : version non prise en charge.');
    }
    final list = raw['entries'];
    if (list is! List || list.length > kEvolutionMaxEntries * 25) {
      throw const FormatException('Évolution : propositions invalides.');
    }
    final entries = [for (final e in list) EvolutionEntry.fromJson(e)];
    final seen = <String>{};
    for (final e in entries) {
      if (!seen.add('${e.blockId}|${e.id}')) {
        throw const FormatException('Évolution : proposition en double.');
      }
    }
    return PlanEvolution(version: v, entries: entries);
  }
}

/// Bloc [base] avec les propositions en place de [entries] (dans l'ordre),
/// jusqu'à la semaine [atWeek] du bloc comprise (null : toutes). Une
/// restructuration rend les semaines d'avant son départ à l'identique
/// (contrat de kalis_plan) : la mise en forme d'une semaine passée prend
/// le bloc tel qu'il était alors ([atWeek]).
kc.ProgramBlock evolvedBlock(
  kc.ProgramBlock base,
  List<EvolutionEntry> entries, {
  int? atWeek,
}) {
  var block = base;
  for (final e in entries) {
    if (!e.inEffect) continue;
    if (atWeek != null && e.fromWeek > atWeek) continue;
    block = ka.applyProposal(block, e.proposal);
  }
  return block;
}
