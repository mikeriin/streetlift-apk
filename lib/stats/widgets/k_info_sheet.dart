// UI3 (refonte UI) : feuille d'information — composant créé par le lot
// Stats faute d'équivalent dans le kit (cahier §7.2 : composant manquant
// créé dans `lib/<zone>/widgets/`, à promouvoir dans `lib/kit/` par UI5).
//
// Même anatomie que les gabarits de feuilles du kit (§4.5) : poignée, titre
// et contexte, contenu qui défile (lignes groupées, paragraphes, jauges),
// bouton « Fermer ». Elle sert aux feuilles de jeu de Stats (personnage,
// défis, campagne, boss, saisons, titres…), qui montrent des informations
// plutôt que des actions : rien n'y est empilé (une feuille n'en ouvre
// jamais une autre).
import 'package:flutter/material.dart';

import '../../kit/kit.dart';

/// Contenu d'une feuille d'information.
class KInfoSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String closeLabel;
  final VoidCallback onClose;
  const KInfoSheet({
    super.key,
    required this.title,
    required this.children,
    required this.onClose,
    this.subtitle,
    this.closeLabel = 'Fermer',
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: KSpacing.s16,
        right: KSpacing.s16,
        bottom: KSpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: KSpacing.s12),
          Center(
            child: Container(
              width: KSize.handleWidth,
              height: KSize.handleHeight,
              decoration: ShapeDecoration(color: k.texte3, shape: KRadius.pill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpacing.s4,
              KSpacing.s12,
              KSpacing.s4,
              KSpacing.s8,
            ),
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: KType.titreSeance.copyWith(color: k.texte),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: KType.detail.copyWith(color: k.texte2),
                    ),
                ],
              ),
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: KSpacing.s4),
              itemCount: children.length,
              separatorBuilder: (_, __) => const SizedBox(height: KSpacing.s12),
              itemBuilder: (_, i) => children[i],
            ),
          ),
          const SizedBox(height: KSpacing.s8),
          TextButton(
            key: const ValueKey('sheet-close'),
            onPressed: onClose,
            style: TextButton.styleFrom(
              foregroundColor: k.texte2,
              minimumSize: const Size.fromHeight(KSize.search),
              shape: KRadius.pill,
              textStyle: KType.corpsFort,
            ),
            child: Text(closeLabel),
          ),
        ],
      ),
    );
  }
}

/// Ouvre une feuille d'information (85 % de l'écran au plus ; le contenu
/// défile). Un contenu qui doit suivre les données se met dans un
/// `StoreWidget` ou un `StoreBuilder`.
Future<void> showKInfoSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<Widget> children,
  String closeLabel = 'Fermer',
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: false,
  sheetAnimationStyle: AnimationStyle(
    duration: KMotion.standard.durationIn(context),
    reverseDuration: KMotion.fast.durationIn(context),
    curve: KMotion.standard.curve,
  ),
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * .85,
  ),
  builder: (ctx) => KInfoSheet(
    title: title,
    subtitle: subtitle,
    closeLabel: closeLabel,
    onClose: () => Navigator.pop(ctx),
    children: children,
  ),
);
