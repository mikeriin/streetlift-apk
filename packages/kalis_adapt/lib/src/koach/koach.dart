/// Koach 1.0 (`kalis_adapt` 1.0.0) : portage Dart de la référence Python
/// validée par KM1 (`reference/koach/`, contrat `reference/CONTRAT_1_0.md`,
/// version 1.0.1). Mêmes entrées, mêmes sorties à 1e-9 sur les fixtures de
/// parité (`reference/fixtures/`). Dart pur : aucun accès disque, aucune
/// horloge, hasard seedé (mulberry32).
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

part 'outils.dart';
part 'numerique.dart';
part 'modele.dart';
part 'securite.dart';
part 'seance.dart';
part 'moteur.dart';
part 'planification.dart';
part 'rupture.dart';
part 'adherence.dart';
part 'dual.dart';
