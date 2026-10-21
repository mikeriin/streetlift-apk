// Widgets qui lisent le store global et se reconstruisent à chaque
// notification, y compris lorsqu'ils sont instanciés en `const`.
//
// Pourquoi : un widget `const` placé sous un `ListenableBuilder` n'est jamais
// reconstruit par son parent (Flutter retrouve la même instance et saute la
// mise à jour). La pastille de niveau de l'accueil et les cartes « jeu » de l'Aperçu restaient ainsi figés jusqu'au redémarrage
// de l'application. L'abonnement vit dans l'élément lui-même : aucun widget
// n'est ajouté à l'arbre, et il est retiré au démontage.
//
// L6 (KT-023) — zones masquées. Les quatre onglets visités restent montés
// (IndexedStack) et une séance se superpose aux onglets : sans
// précaution, chaque notification du store (une frappe dans une série en
// est une) reconstruisait aussi PROGRAMME, STATS, ARSENAL et RÉGLAGES,
// invisibles. Une zone masquée (`TickerMode` désactivé : onglet non affiché
// de la navigation, section STATS non affichée, route recouverte par une
// route opaque) note seulement la notification ; elle se reconstruit une
// fois dès qu'elle redevient visible, avant d'être peinte. Une zone visible
// se comporte exactement comme avant. Le signal `TickerMode` est lu sans
// dépendance (`TickerMode.getNotifier`, comme les animations Flutter) : un
// changement d'onglet sans modification des données ne reconstruit rien.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'store.dart';

/// Nombre de reconstructions réellement provoquées par le store, et de
/// notifications différées parce que la zone était masquée. Comptés dans
/// les assertions seulement (mode debug et tests), jamais dans l'APK de
/// production. Lus par les tests : compteurs d'opérations, pas une durée.
@visibleForTesting
class StoreRebuildStats {
  static int rebuilds = 0;
  static int deferred = 0;
  static void reset() => rebuilds = deferred = 0;
}

bool _countRebuild() {
  StoreRebuildStats.rebuilds++;
  return true;
}

bool _countDeferred() {
  StoreRebuildStats.deferred++;
  return true;
}

/// Suivi de la visibilité (`TickerMode`) et des notifications différées,
/// partagé par [StoreBuilder] et [StoreWidget].
class _Deferral {
  final void Function() rebuild;
  _Deferral(this.rebuild);

  ValueListenable<TickerModeData>? _mode;
  bool _stale = false;

  bool get visible => _mode?.value.enabled ?? true;

  /// À appeler au montage, à la réactivation et quand les dépendances
  /// changent : le `TickerMode` englobant peut avoir changé.
  void attach(BuildContext context) {
    final next = TickerMode.getValuesNotifier(context);
    if (identical(next, _mode)) return;
    _mode?.removeListener(_onMode);
    _mode = next..addListener(_onMode);
    _onMode();
  }

  void detach() {
    _mode?.removeListener(_onMode);
    _mode = null;
  }

  void onStore() {
    if (visible) {
      assert(_countRebuild());
      rebuild();
    } else {
      assert(_countDeferred());
      _stale = true;
    }
  }

  void _onMode() {
    if (_stale && visible) {
      _stale = false;
      assert(_countRebuild());
      rebuild();
    }
  }

  /// La zone vient d'être reconstruite (pour une autre raison) : plus rien
  /// d'en retard.
  void built() {
    if (visible) _stale = false;
  }
}

/// Équivalent de `ListenableBuilder(listenable: store, …)` qui diffère les
/// reconstructions tant que la zone est masquée (voir l'en-tête).
class StoreBuilder extends StatefulWidget {
  final WidgetBuilder builder;
  const StoreBuilder({super.key, required this.builder});

  @override
  State<StoreBuilder> createState() => _StoreBuilderState();
}

class _StoreBuilderState extends State<StoreBuilder> {
  late final _deferral = _Deferral(() {
    if (mounted) setState(() {});
  });

  @override
  void initState() {
    super.initState();
    store.addListener(_deferral.onStore);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _deferral.attach(context);
  }

  @override
  void activate() {
    super.activate();
    _deferral.attach(context);
  }

  @override
  void dispose() {
    store.removeListener(_deferral.onStore);
    _deferral.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _deferral.built();
    return widget.builder(context);
  }
}

abstract class StoreWidget extends StatelessWidget {
  const StoreWidget({super.key});

  @override
  StatelessElement createElement() => _StoreElement(this);
}

class _StoreElement extends StatelessElement {
  _StoreElement(super.widget);

  late final _deferral = _Deferral(markNeedsBuild);

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _deferral.attach(this);
    store.addListener(_deferral.onStore);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _deferral.attach(this);
  }

  @override
  void activate() {
    super.activate();
    _deferral.attach(this);
  }

  @override
  Widget build() {
    _deferral.built();
    return super.build();
  }

  @override
  void unmount() {
    store.removeListener(_deferral.onStore);
    _deferral.detach();
    super.unmount();
  }
}
