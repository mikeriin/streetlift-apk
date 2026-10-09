/// Koach, la mascotte de Kalis Track, en Dart pur (lot GK).
///
/// - Dessins : [KoachPose] (36 poses, calques encre / papier / yeux en
///   commandes numériques, [replayKoachPath] pour construire un `Path`),
///   flammes de difficulté ([koachFlame]).
/// - Répliques : [KoachDirector] choisit pose, message, actions et
///   explication pour un [KoachCue] ; [KoachTexts] rend le français.
///
/// Aucune dépendance à Flutter, aucune horloge, aucun hasard. Contrat :
/// CONTRAT.md.
library;

export 'src/koach_art.dart';
export 'src/koach_flames.dart';
export 'src/koach_pose.dart';
export 'src/lines/koach_director.dart';
export 'src/lines/koach_event.dart';
export 'src/lines/koach_messages_fr.dart';
export 'src/lines/koach_rules.dart';

/// Version du paquet.
const String kalisKoachVersion = '0.1.0';

/// Numéro de schéma des données exportées (rapport JSON, format des
/// commandes).
const int kalisKoachSchema = 1;
