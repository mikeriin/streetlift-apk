// RV2 (M6) : écritures refusées signalées tant qu'elles durent.
//
// Avant : un message éphémère (8 s) au changement de `persistenceError`.
// Un échec répété garde le même texte, donc ne prévenait plus : l'athlète
// pouvait enchaîner les séries sans savoir que rien ne s'enregistrait
// toujours pas. Choix (le plus prudent sans harceler) : une bannière fixe
// en haut de l'écran, posée au premier échec et retirée seulement quand
// une écriture est acceptée. Aucun nouveau message à chaque échec (pas
// d'empilement de notifications pendant la séance) : le texte de la
// bannière se met à jour sur place et compte les échecs d'affilée. Au
// retour à la normale : « Modifications enregistrées. ».
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'kit/kit.dart';
import 'store.dart';

/// Texte de la bannière : le message de l'échec, puis, à partir du
/// deuxième échec d'affilée, leur nombre (les données ne s'enregistrent
/// toujours pas).
String persistenceAlertText(String message, int failures) => failures < 2
    ? message
    : '$message\n$failures essais refusés d’affilée : tes dernières '
          'modifications ne sont toujours pas enregistrées.';

/// Montre la bannière des écritures refusées de [store] au-dessus de
/// [child] (dans le `ScaffoldMessenger` de l'application).
class PersistenceAlert extends StatefulWidget {
  final AppStore store;
  final Widget child;
  const PersistenceAlert({super.key, required this.store, required this.child});

  @override
  State<PersistenceAlert> createState() => _PersistenceAlertState();
}

class _PersistenceAlertState extends State<PersistenceAlert> {
  ScaffoldMessengerState? _messenger;
  ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>?
  _banner;

  /// Dernier message affiché (gardé pendant la sortie de la bannière).
  String _last = '';

  @override
  void initState() {
    super.initState();
    widget.store.persistenceError.addListener(_onChange);
    // Échec antérieur à l'affichage : signalé dès la première image.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void didUpdateWidget(PersistenceAlert old) {
    super.didUpdateWidget(old);
    if (!identical(old.store, widget.store)) {
      old.store.persistenceError.removeListener(_onChange);
      widget.store.persistenceError.addListener(_onChange);
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    }
  }

  @override
  void dispose() {
    widget.store.persistenceError.removeListener(_onChange);
    super.dispose();
  }

  /// Le magasin peut prévenir pendant une construction : la bannière est
  /// alors posée après l'image.
  void _onChange() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    } else {
      _sync();
    }
  }

  void _sync() {
    final messenger = _messenger;
    if (!mounted || messenger == null || !messenger.mounted) return;
    final error = widget.store.persistenceError.value;
    if (error != null) {
      _last = error;
      if (_banner == null) {
        final shown = messenger.showMaterialBanner(_build());
        _banner = shown;
        shown.closed.then((_) {
          if (identical(_banner, shown)) _banner = null;
        });
      }
    } else if (_banner != null) {
      _banner = null;
      messenger
        ..hideCurrentMaterialBanner()
        ..showSnackBar(
          const SnackBar(content: Text('Modifications enregistrées.')),
        );
    }
  }

  Future<void> _retry() async {
    // Réussite : la bannière part d'elle-même ; échec : son texte compte
    // un essai de plus.
    await widget.store.retrySave();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  MaterialBanner _build() {
    final k = KTokens.of(context);
    final store = widget.store;
    return MaterialBanner(
      key: const ValueKey('persistence-banner'),
      backgroundColor: k.haute,
      leading: Icon(Icons.error_outline, color: k.danger),
      content: ListenableBuilder(
        listenable: Listenable.merge([
          store.persistenceError,
          store.persistenceFailures,
        ]),
        builder: (context, _) => Text(
          persistenceAlertText(
            store.persistenceError.value ?? _last,
            store.persistenceFailures.value,
          ),
          key: const ValueKey('persistence-banner-text'),
          style: TextStyle(color: k.texte),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('persistence-retry'),
          onPressed: _retry,
          child: const Text('Réessayer'),
        ),
      ],
    );
  }
}
