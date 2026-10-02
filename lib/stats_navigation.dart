import 'package:flutter/material.dart';

enum StatsSection { overview, progression, performance, history }

/// Les raccourcis de progression rejoignent le même onglet, même depuis une route.
class StatsNavigation {
  static Object? _owner;
  static ValueChanged<StatsSection>? _open;

  static void bind(Object owner, ValueChanged<StatsSection> open) {
    _owner = owner;
    _open = open;
  }

  static void unbind(Object owner) {
    if (!identical(owner, _owner)) return;
    _owner = null;
    _open = null;
  }

  static bool open(BuildContext context, StatsSection section) {
    final action = _open;
    if (action == null) return false;
    Navigator.of(context).popUntil((route) => route.isFirst);
    action(section);
    return true;
  }
}
