// Widget sans état qui lit le store global et se reconstruit à chaque
// notification, y compris lorsqu'il est instancié en `const`.
//
// Pourquoi : un widget `const` placé sous un `ListenableBuilder` n'est jamais
// reconstruit par son parent (Flutter retrouve la même instance et saute la
// mise à jour). La pastille de niveau de l'accueil, les crédits de l'Arsenal
// et les cartes « jeu » de l'Aperçu restaient ainsi figés jusqu'au redémarrage
// de l'application. L'abonnement vit dans l'élément lui-même : aucun widget
// n'est ajouté à l'arbre, et il est retiré au démontage.
import 'package:flutter/widgets.dart';

import 'store.dart';

abstract class StoreWidget extends StatelessWidget {
  const StoreWidget({super.key});

  @override
  StatelessElement createElement() => _StoreElement(this);
}

class _StoreElement extends StatelessElement {
  _StoreElement(super.widget);

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    store.addListener(markNeedsBuild);
  }

  @override
  void unmount() {
    store.removeListener(markNeedsBuild);
    super.unmount();
  }
}
