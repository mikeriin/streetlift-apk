/// Validateur de sécurité de Koach (lot KM2) : la fonction `Validateur`
/// que demande l'extension `Planification` de Koach (bibliothèque
/// `koach.dart`), sans `kalis_bench`.
///
/// - [validateurSecurite] : validateur de la planification ;
/// - [constatsDesBlocs], [constatsSecurite] : constats de sécurité de blocs
///   (JSON ou `ProgramBlock`) ;
/// - [ProfilValidation] : les seuls champs du profil lus, depuis le profil
///   d'athlète de l'application ([ProfilValidation.depuisProfil]) ou depuis
///   le profil du banc ([ProfilValidation.depuisJsonBanc]) ;
/// - [blocsServis] : blocs réduits à leurs semaines servies.
///
/// Copie fidèle (2026-10-10) des critères de sécurité de `kalis_bench`
/// 0.3.1 (`lib/src/safety.dart`, `lib/src/analysis.dart`) : mêmes constats,
/// dans le même ordre (vérifié par `km2_validateur_test.dart` de
/// `kalis_bench`). Dart pur.
library;

export 'src/koach/koach.dart' show Json, Validateur;
export 'src/validateur/profil.dart';
export 'src/validateur/securite.dart';
export 'src/validateur/validateur.dart';
