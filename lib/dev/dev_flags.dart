// G1 (D2.4) : drapeau de compilation du mode dev. L'APK du propriétaire est
// construit avec `--dart-define=KALIS_DEV=true` ; l'AAB destiné au Play
// Store sans. Tout le code du mode dev est derrière [kDevBuild] : constante
// de compilation, le compilateur élimine les branches mortes de l'AAB.

/// Build de développement (APK construit par GitHub Actions).
const bool kDevBuild = bool.fromEnvironment('KALIS_DEV');
