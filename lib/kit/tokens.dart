// UI0 (refonte UI) : jetons du système de design (cahier §5), en trois
// couches à la manière de Fluent 2 :
// 1. globaux : valeurs des palettes (`palette.dart`), échelles d'espacement,
//    de rayon, de taille et de typographie (ce fichier) ;
// 2. alias nommés par leur fonction : `KRoles` (`fond`, `surface`, `encre`…)
//    portés par [KTokens] dans le thème ;
// 3. composants (`lib/kit/*.dart`) : seuls à lire les deux premières couches.
// Aucun écran n'utilise un global : il passe par un composant ou par un
// alias (`KTokens.of(context)`).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'palette.dart';

/// Espacements (cahier §5.3) : seules valeurs permises.
abstract final class KSpacing {
  static const double s4 = 4, s8 = 8, s12 = 12, s14 = 14, s16 = 16;
  static const double s20 = 20, s24 = 24, s32 = 32;

  /// Marge d'écran.
  static const double page = 20;

  /// Écart entre cartes.
  static const double cardGap = 12;

  /// Largeur de lecture maximale (tablette, paysage).
  static const double maxWidth = 840;
}

/// Rayons (cahier §5.3, U13) : trois familles, seules valeurs.
abstract final class KRadius {
  /// Cartes de contenu, carte du jour, tuiles de ressenti, barre de repos,
  /// haut des feuilles.
  static const double card = 24;

  /// Groupes de lignes (menus, réglages, phases, tableau des séries, lignes
  /// de jour) et lignes surlignées qu'ils contiennent.
  static const double menu = 20;

  static const cardRadius = BorderRadius.all(Radius.circular(card));
  static const menuRadius = BorderRadius.all(Radius.circular(menu));
  static const sheetRadius = BorderRadius.vertical(top: Radius.circular(card));

  /// Commandes (boutons, champs, puces, segments, interrupteurs, recherche,
  /// dock, barres, pastilles, tuiles d'icône) : pilule, moitié de la hauteur.
  static const pill = StadiumBorder();
  static const cardShape = RoundedRectangleBorder(borderRadius: cardRadius);
  static const menuShape = RoundedRectangleBorder(borderRadius: menuRadius);
}

/// Tailles (cahier §5.3, §5.4).
abstract final class KSize {
  /// Cible tactile minimale.
  static const double target = 48;

  /// Bouton principal.
  static const double primary = 56;

  /// Dock flottant et pilule de l'onglet actif.
  static const double dock = 64, dockItem = 48;

  /// Pastille d'icône d'une ligne de menu.
  static const double menuIcon = 40;

  /// Ligne de menu (une ligne de description), ligne de réglage.
  static const double menuRow = 64, settingRow = 72;

  /// Largeur maximale de la valeur d'une ligne de menu ; largeur sous
  /// laquelle le pas à pas passe sous son libellé (à 100 % de texte).
  static const double valueWidth = 140, stepperRowMin = 300;

  /// Champ de recherche.
  static const double search = 52;

  /// Contour de l'élément courant.
  static const double current = 1.5;

  /// Icônes.
  static const double icon = 22, iconSmall = 20, chevron = 18;

  /// Poignée des feuilles.
  static const double handleWidth = 36, handleHeight = 4;
}

/// Familles embarquées (`assets/fonts/`, SIL OFL 1.1).
abstract final class KFont {
  static const text = 'Barlow';
  static const title = 'BarlowSemiCondensed';
  static const figures = 'BarlowCondensed';
  static const tabular = [FontFeature.tabularFigures()];
}

/// Styles de texte (cahier §5.2). Sans couleur : la couleur vient du rôle
/// (`texte`, `texte2`…) au point d'usage. Interligne exprimé en multiple de
/// la taille, comme le veut Flutter (`height`).
abstract final class KType {
  static TextStyle _s(
    String family,
    double size,
    double line,
    FontWeight weight, {
    bool tabular = false,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    height: line / size,
    fontWeight: weight,
    letterSpacing: 0,
    fontFeatures: tabular ? KFont.tabular : null,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Titre d'un onglet (Arsenal, Réglages, Stats).
  static final titreRacine = _s(KFont.title, 30, 36, FontWeight.w600);

  /// Titre d'une sous-page ; semaine de l'accueil.
  static final titreEcran = _s(KFont.title, 22, 28, FontWeight.w600);

  /// Séance, exercice, feuille.
  static final titreSeance = _s(KFont.title, 20, 24, FontWeight.w600);

  /// Titre de carte.
  static final titreCarte = _s(KFont.title, 18, 24, FontWeight.w600);

  /// Ligne de jour.
  static final ligneJour = _s(KFont.title, 15, 20, FontWeight.w600);

  /// Titre de ligne de menu, boutons.
  static final corpsFort = _s(KFont.text, 16, 22, FontWeight.w600);

  /// Libellé d'action d'une feuille (verbe), puces actives.
  static final corpsMoyen = _s(KFont.text, 16, 22, FontWeight.w500);

  /// Texte courant.
  static final corps = _s(KFont.text, 15, 22, FontWeight.w400);

  /// Description, valeur secondaire.
  static final detail = _s(KFont.text, 13, 18, FontWeight.w400);

  /// Libellé de puce, de segment, de petit bouton.
  static final libelle = _s(KFont.text, 14, 20, FontWeight.w600);

  /// Titre de section (`texte2`, sans capitales).
  static final section = _s(KFont.text, 14, 20, FontWeight.w600);

  /// Surtitre de la carte du jour, légende.
  static final micro = _s(KFont.text, 12, 16, FontWeight.w600);

  /// Prescription (« 4 × 5 »), durée estimée.
  static final chiffre = _s(
    KFont.figures,
    36,
    38,
    FontWeight.w600,
    tabular: true,
  );

  /// Champs de saisie, pas à pas.
  static final chiffreMoyen = _s(
    KFont.figures,
    20,
    24,
    FontWeight.w600,
    tabular: true,
  );

  /// Numéro de ligne (série, jour, rang).
  static final chiffrePetit = _s(
    KFont.figures,
    16,
    20,
    FontWeight.w500,
    tabular: true,
  );

  /// Barre de repos.
  static final chrono = _s(
    KFont.figures,
    34,
    36,
    FontWeight.w600,
    tabular: true,
  );

  /// Interlettrage des titres en capitales (U3).
  static const capsSpacing = .3;
}

/// Capitales des titres (U3) : appliquées par le système aux titres
/// d'écran, de séance, de jour et à l'onglet actif ; réglables en un jeton.
const bool kCapsTitles = true;

/// Ressorts de Material 3 Expressive (cahier §5.5) : amortissement, raideur.
abstract final class KSprings {
  static final fastSpatial = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 1400,
    ratio: .9,
  );
  static final defaultSpatial = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 700,
    ratio: .9,
  );
  static final slowSpatial = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 300,
    ratio: .9,
  );
  static final fastEffects = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 3800,
    ratio: 1,
  );
  static final defaultEffects = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 1600,
    ratio: 1,
  );
  static final slowEffects = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 800,
    ratio: 1,
  );
}

/// Courbe d'un ressort de 0 à 1 (vitesse initiale nulle), étalée sur sa
/// durée d'établissement ([settle]) : utilisable par toute animation
/// implicite (`AnimatedContainer`, `TweenAnimationBuilder`…).
class KSpringCurve extends Curve {
  final SpringDescription spring;
  const KSpringCurve(this.spring);

  static final Map<SpringDescription, Duration> _settle = {};

  /// Durée au bout de laquelle le ressort reste à sa
  /// cible à 0,5 % près (calculée une fois par ressort).
  Duration get settle => _settle.putIfAbsent(spring, () {
    final sim = SpringSimulation(spring, 0, 1, 0);
    var last = 0.0;
    for (var ms = 0; ms <= 2000; ms += 4) {
      if ((sim.x(ms / 1000) - 1).abs() > .005) last = ms / 1000;
    }
    return Duration(milliseconds: math.max(16, (last * 1000).ceil() + 4));
  });

  @override
  double transformInternal(double t) =>
      SpringSimulation(spring, 0, 1, 0).x(t * settle.inMicroseconds / 1e6);
}

/// Mouvement prêt à l'emploi : courbe et durée d'un ressort, nulles quand
/// le téléphone demande de réduire les animations.
class KMotion {
  final Curve curve;
  final Duration duration;
  const KMotion._(this.curve, this.duration);

  static final Map<SpringDescription, KMotion> _cache = {};

  static KMotion _of(SpringDescription s) => _cache.putIfAbsent(s, () {
    final c = KSpringCurve(s);
    return KMotion._(c, c.settle);
  });

  /// Choix, boutons (spatial rapide).
  static KMotion get fast => _of(KSprings.fastSpatial);

  /// Feuilles (spatial par défaut).
  static KMotion get standard => _of(KSprings.defaultSpatial);

  /// Pages (spatial lent).
  static KMotion get slow => _of(KSprings.slowSpatial);

  /// Couleur, opacité (effets).
  static KMotion get effect => _of(KSprings.defaultEffects);

  /// Durée effective dans ce contexte (zéro si « réduire les animations »).
  Duration durationIn(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false
      ? Duration.zero
      : duration;
}

/// Jetons du thème courant (`ThemeExtension`) : rôles de couleur de la
/// palette choisie, capitales des titres, contraste renforcé.
@immutable
class KTokens extends ThemeExtension<KTokens> {
  final KRoles roles;
  final bool capsTitles;
  const KTokens({required this.roles, this.capsTitles = kCapsTitles});

  bool get dark => roles.dark;
  bool get contrast => roles.contrast;
  String get paletteId => roles.paletteId;

  // Raccourcis des alias les plus lus.
  Color get fond => roles.fond;
  Color get surface => roles.surface;
  Color get haute => roles.haute;
  Color get filet => roles.filet;
  Color get texte => roles.texte;
  Color get texte2 => roles.texte2;
  Color get texte3 => roles.texte3;
  Color get pleine => roles.pleine;
  Color get surPleine => roles.surPleine;
  Color get encre => roles.encre;
  Color get second => roles.second;
  Color get accent => roles.accent;
  Color get validation => roles.validation;
  Color get danger => roles.danger;
  Color get avertissement => roles.avertissement;

  /// Jetons du thème de [context] ; à défaut (widget hors d'un thème de
  /// l'application), ceux de la palette par défaut en sombre.
  static KTokens of(BuildContext context) =>
      Theme.of(context).extension<KTokens>() ?? fallback;

  static final KTokens fallback = KTokens(
    roles: KRoles.of(kDefaultPaletteId, dark: true),
  );

  /// Titre mis en capitales selon le jeton (U3). Seul endroit de
  /// l'application où un texte affiché passe en capitales.
  String title(String text) => capsTitles ? text.toUpperCase() : text;

  /// Style d'un titre en capitales : interlettrage léger (U3).
  TextStyle titleStyle(TextStyle style) => capsTitles
      ? style.copyWith(letterSpacing: KType.capsSpacing)
      : style;

  @override
  KTokens copyWith({KRoles? roles, bool? capsTitles}) => KTokens(
    roles: roles ?? this.roles,
    capsTitles: capsTitles ?? this.capsTitles,
  );

  @override
  KTokens lerp(covariant KTokens? other, double t) =>
      other == null || t < .5 ? this : other;
}
