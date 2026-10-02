/// Contrats partagés entre les moteurs et l'application : profil d'athlète
/// (schémas 2 et 3), journal de séances, types d'échange de `plan`, `adapt`
/// et `quest`, prescriptions avancées, saison, compétition, figures (0.4.0),
/// registre des codes de raison.
///
/// Les types sont générés depuis `tool/contracts_spec.py` ; les invariants
/// croisés sont écrits à la main dans `custom_validation.dart`.
library;

import 'civil_date.dart';
import 'json_util.dart';

part 'custom_validation.dart';
part 'extensions.dart';
part 'generated/adapt.g.dart';
part 'generated/common.g.dart';
part 'generated/enums.g.dart';
part 'generated/journal.g.dart';
part 'generated/plan.g.dart';
part 'generated/profile.g.dart';
part 'generated/quest.g.dart';
part 'generated/reason_codes.g.dart';
part 'generated/season.g.dart';
part 'reasons.dart';
