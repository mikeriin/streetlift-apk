// UI0 (refonte UI) : sélecteur de palette avec aperçu (cahier §5.1, U5, U6),
// posé dans la rubrique « Apparence ».
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';
import 'tokens.dart';

/// Pastilles des 8 palettes (4 par ligne, cibles de 56 dp) : moitié
/// dominante, moitié accent ; la palette choisie porte un anneau `texte` et
/// une coche. Nom de la palette choisie au-dessus, aperçu dessous.
class KPalettePicker extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelected;
  final bool showPreview;
  const KPalettePicker({
    super.key,
    required this.selectedId,
    required this.onSelected,
    this.showPreview = true,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final selected = normalizePaletteId(selectedId);
    final name = paletteSource(selected).nom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                'Palette',
                style: KType.corpsFort.copyWith(color: k.texte),
              ),
            ),
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.end,
                style: KType.libelle.copyWith(
                  color: k.texte2,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: KSpacing.s8),
        LayoutBuilder(
          builder: (context, c) {
            final perRow = c.maxWidth >= 8 * KSize.primary ? 8 : 4;
            final cell = c.maxWidth / perRow;
            return Wrap(
              children: [
                for (final p in kPaletteSources)
                  SizedBox(
                    width: cell,
                    height: KSize.primary,
                    child: _Swatch(
                      palette: p,
                      dark: k.dark,
                      selected: p.id == selected,
                      onTap: () {
                        if (p.id == selected) return;
                        HapticFeedback.selectionClick();
                        onSelected(p.id);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        if (showPreview) ...[
          const SizedBox(height: KSpacing.s12),
          KPalettePreview(
            paletteId: selected,
            dark: k.dark,
            contrast: k.contrast,
          ),
        ],
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  final KPaletteSource palette;
  final bool dark, selected;
  final VoidCallback onTap;
  const _Swatch({
    required this.palette,
    required this.dark,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final r = KRoles.of(palette.id, dark: dark);
    const size = KSize.target - KSpacing.s4;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      label: palette.nom,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: palette.nom,
        child: InkWell(
          key: ValueKey('accent-${palette.id}'),
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Container(
              width: size + KSpacing.s8,
              height: size + KSpacing.s8,
              padding: const EdgeInsets.all(KSpacing.s4 / 2),
              decoration: ShapeDecoration(
                shape: CircleBorder(
                  side: BorderSide(
                    color: selected ? k.texte : Colors.transparent,
                    width: KSpacing.s4 / 2,
                  ),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(KSpacing.s4 / 2),
                decoration: ShapeDecoration(
                  shape: CircleBorder(side: BorderSide(color: k.filet)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0, .5, .5, 1],
                    colors: [r.pleine, r.pleine, r.accent, r.accent],
                  ),
                ),
                alignment: Alignment.center,
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        key: ValueKey('accent-check-${palette.id}'),
                        size: KSize.iconSmall,
                        color: r.surPleine,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aperçu d'une palette dans le thème courant : carte du jour en
/// réduction, repère `encre`, chiffre, puce de record `accent`, bouton
/// principal.
class KPalettePreview extends StatelessWidget {
  final String paletteId;
  final bool dark, contrast;
  const KPalettePreview({
    super.key,
    required this.paletteId,
    required this.dark,
    this.contrast = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = KRoles.of(paletteId, dark: dark, contrast: contrast);
    final k = KTokens.of(context);
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: r.fond,
          shape: RoundedRectangleBorder(
            borderRadius: KRadius.menuRadius,
            side: BorderSide(color: k.filet),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(KSpacing.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(KSpacing.s14),
                decoration: ShapeDecoration(
                  color: r.pleine,
                  shape: KRadius.cardShape,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      k.title("J3, aujourd'hui"),
                      style: KType.micro.copyWith(color: r.surPleine),
                    ),
                    Text(
                      k.title('Squat et gainage'),
                      style: k.titleStyle(
                        KType.titreCarte.copyWith(color: r.surPleine),
                      ),
                    ),
                    Text(
                      '34–49 min',
                      style: KType.chiffreMoyen.copyWith(color: r.surPleine),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KSpacing.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KSpacing.s14,
                  vertical: KSpacing.s8,
                ),
                decoration: ShapeDecoration(
                  color: r.surface,
                  shape: KRadius.menuShape,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '4 × 5',
                        style: KType.chiffreMoyen.copyWith(color: r.encre),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: KSpacing.s8,
                        vertical: KSpacing.s4 / 2,
                      ),
                      decoration: ShapeDecoration(
                        color: r.haute,
                        shape: KRadius.pill,
                      ),
                      child: Text(
                        'Record',
                        style: KType.detail.copyWith(color: r.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
