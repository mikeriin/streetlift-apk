// G1 : horloge unique de l'application (PIPELINE_GP.md, lot G1 §3).
//
// Tout ce qui lit « l'heure de l'application » (date du jour, semaine du
// programme, horodatage des séries, exports) passe par [KalisClock.now].
// Session personnelle : heure réelle, toujours. Session de test (mode dev,
// build de développement seulement) : heure réelle décalée d'un nombre
// entier de jours (voyage dans le temps), propre à la session de test.
//
// Restent sur l'heure réelle ([KalisClock.realNow] ou DateTime.now) : les
// durées des chronos (heure murale bornée par l'horloge monotone,
// timers.dart), les identifiants techniques et l'heure des rappels
// Android (déclenchés par le système à l'heure réelle).

import 'dev/dev_flags.dart';

class KalisClock {
  KalisClock._();

  static int _offsetDays = 0;

  /// Décalage de la session de test, en jours civils (0 hors session de
  /// test).
  static int get offsetDays => _offsetDays;

  /// Heure de l'application : réelle, ou décalée de [offsetDays] jours
  /// civils (même heure murale, changements d'heure compris).
  static DateTime now() {
    final real = DateTime.now();
    final days = _offsetDays;
    if (days == 0) return real;
    return DateTime(
      real.year,
      real.month,
      real.day + days,
      real.hour,
      real.minute,
      real.second,
      real.millisecond,
      real.microsecond,
    );
  }

  /// Heure réelle, pour les usages techniques (identifiants, durées).
  static DateTime realNow() => DateTime.now();

  /// Réservé à la session de test (dev_session.dart). Sans build de
  /// développement, le décalage reste nul.
  static void setOffsetDays(int days) {
    _offsetDays = kDevBuild ? days : 0;
  }
}
