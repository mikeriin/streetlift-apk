// 6.13.0 : taille d'affichage de l'application (Réglages › Apparence).
//
// Toute l'interface — textes, cadres, marges, boutons, feuilles et boîtes
// de dialogue — est dessinée sur un écran virtuel plus petit (ou plus
// grand) puis mise à l'échelle de l'écran réel : les proportions restent
// celles du cahier, à l'image du réglage « Taille d'affichage » d'Android.
// Les gestes suivent la mise à l'échelle (transformation de [FittedBox]).
import 'package:flutter/widgets.dart';

/// Met [child] à l'échelle [scale] (1 : taille d'origine).
class KDisplayScale extends StatelessWidget {
  final double scale;
  final Widget child;
  const KDisplayScale({super.key, required this.scale, required this.child});

  @override
  Widget build(BuildContext context) {
    if ((scale - 1).abs() < .001) return child;
    final media = MediaQuery.of(context);
    final data = media.copyWith(
      size: media.size / scale,
      devicePixelRatio: media.devicePixelRatio * scale,
      padding: media.padding / scale,
      viewPadding: media.viewPadding / scale,
      viewInsets: media.viewInsets / scale,
      systemGestureInsets: media.systemGestureInsets / scale,
    );
    return MediaQuery(
      data: data,
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: data.size.width,
          height: data.size.height,
          child: child,
        ),
      ),
    );
  }
}
