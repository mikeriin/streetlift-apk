// UI0 (refonte UI) : champ de recherche unique (cahier §4.4) — Réglages,
// Arsenal, bibliothèque. La règle de correspondance est celle de
// `search.dart` (sans accents ni majuscules, tous les mots, débuts de mots,
// synonymes) ; ce composant ne fait que la saisie.
import 'package:flutter/material.dart';

import 'tokens.dart';

/// Champ de recherche : pilule de 52 dp, `surface` et contour `filet`,
/// loupe, bouton « Effacer la recherche ». [onTap] avec [readOnly] : le champ
/// ouvre une page de recherche au lieu de se saisir sur place.
class KSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged, onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly, autofocus;
  final FocusNode? focusNode;
  const KSearchField({
    super.key,
    this.controller,
    this.hint = 'Rechercher',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<KSearchField> createState() => _KSearchFieldState();
}

class _KSearchFieldState extends State<KSearchField> {
  TextEditingController? _own;
  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final border = StadiumBorder(side: BorderSide(color: k.filet));
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: KSize.search),
        child: TextField(
          controller: _controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          enableSuggestions: false,
          style: KType.corps.copyWith(color: k.texte),
          cursorColor: k.encre,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintMaxLines: 2,
            hintStyle: KType.corps.copyWith(color: k.texte2),
            filled: true,
            fillColor: k.surface,
            isDense: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: KSpacing.s16,
              vertical: KSpacing.s14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: k.texte2,
              size: KSize.iconSmall,
            ),
            suffixIcon: value.text.isEmpty || widget.readOnly
                ? null
                : IconButton(
                    tooltip: 'Effacer la recherche',
                    icon: Icon(Icons.close_rounded, color: k.texte2),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged?.call('');
                    },
                  ),
            border: _InputShape(border),
            enabledBorder: _InputShape(border),
            focusedBorder: _InputShape(
              StadiumBorder(
                side: BorderSide(color: k.encre, width: KSize.current),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bordure de champ en pilule (contour d'une [StadiumBorder]).
class _InputShape extends OutlineInputBorder {
  _InputShape(StadiumBorder shape)
    : super(
        borderSide: shape.side,
        borderRadius: const BorderRadius.all(Radius.circular(KSize.search / 2)),
      );
}
