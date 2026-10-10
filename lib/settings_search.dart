// UI4 (refonte UI, cahier §4.4) : recherche des réglages. Index écrit à la
// main : chaque réglage et chaque page d'aide ou destination, avec son
// libellé, sa description, des mots proches, le chemin affiché et sa
// destination (page des Réglages et ligne mise en évidence, ou écran).
// Correspondance : règle unique de `search.dart` (sans accents ni
// majuscules, tous les mots, synonymes), résultats classés par score.
import 'package:flutter/material.dart';

import 'app_theme.dart' show KAccentSpec;
import 'athlete_profile_screen.dart' show ProfileScreen;
import 'engine3d.dart' show Engine3DScreen;
import 'exercise_screens.dart' show MentionsScreen;
import 'guided_tests.dart' show GuidedTestsScreen;
import 'koach/koach_gallery_screen.dart' show KoachGalleryScreen;
import 'mannequin_3d.dart' show Display3DSettings;
import 'pilotage_screen.dart' show PilotageScreen;
import 'program_explainer.dart' show showProgramExplainer;
import 'search.dart';
import 'settings_screen.dart';
import 'store.dart';
import 'wellbeing_screens.dart'
    show FeedbackScreen, RecoveryScreen, SafetyScreen;

/// Groupe d'un résultat : « Réglages » ou « Aide ».
enum SettingsSearchKind { setting, help }

/// Entrée de l'index de recherche des réglages.
class SettingsSearchEntry {
  /// Identifiant de la ligne (paramètre `highlight` de [SettingsScreen]).
  final String id;

  /// Libellé de la ligne, tel qu'affiché sur sa page.
  final String label;
  final String description;

  /// Mots proches (« repos », « récup », « pause »…).
  final List<String> words;

  /// Chemin affiché sous le résultat (« Séance › Chronomètres »).
  final String path;
  final SettingsSearchKind kind;

  /// Page des Réglages qui porte la ligne ; null : écran ouvert par
  /// [_open].
  final SettingsPage? page;
  final void Function(BuildContext context)? _open;

  /// Valeur actuelle d'un réglage simple, affichée à droite du résultat.
  final String? Function()? value;

  /// Faux quand la ligne n'existe pas aujourd'hui (copie des WOD absente,
  /// aucune ancienne réponse…) : le résultat n'est pas proposé.
  final bool Function()? available;

  SettingsSearchEntry.setting({
    required this.id,
    required this.label,
    required this.description,
    required this.words,
    required this.path,
    required SettingsPage this.page,
    this.value,
    this.available,
  }) : kind = SettingsSearchKind.setting,
       _open = null;

  SettingsSearchEntry.screen({
    required this.id,
    required this.label,
    required this.description,
    required this.words,
    required this.path,
    required void Function(BuildContext context) open,
    this.kind = SettingsSearchKind.help,
  }) : page = null,
       value = null,
       available = null,
       _open = open;

  /// Document indexé : libellé (titre), mots proches (métadonnées),
  /// description et chemin (corps).
  late final SearchDoc doc = SearchDoc(
    name: label,
    meta: words.join(' '),
    body: '$description $path',
  );

  bool get isAvailable => available?.call() ?? true;

  /// Ouvre la destination : la page des Réglages avec la ligne mise en
  /// évidence 1,5 s, ou l'écran d'aide.
  void open(BuildContext context) {
    final p = page;
    if (p != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => SettingsScreen(page: p, highlight: id),
        ),
      );
      return;
    }
    _open?.call(context);
  }
}

void Function(BuildContext context) _screen(Widget Function() build) =>
    (context) => Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => build()),
    );

String _onOff(bool on) => on ? 'Activé' : 'Désactivé';

String _two(int v) => v.toString().padLeft(2, '0');

const _appearance = 'Apparence';
const _anatomy = 'Apparence › Anatomie et 3D';
const _timers = 'Séance › Chronomètres';
const _restEnd = 'Séance › Fin du repos';
const _input = 'Séance › Saisie des séries';
const _screenUnits = 'Séance › Écran et unités';
const _notifications = 'Notifications';
const _progression = 'Progression et jeu';
const _backups = 'Données et confidentialité › Sauvegardes';
const _privacy = 'Données et confidentialité › Confidentialité';
const _danger = 'Données et confidentialité › Zone sensible';
const _about = 'Aide et à propos';

/// Index de la recherche (§4.4), dans l'ordre des pages.
final List<SettingsSearchEntry> settingsSearchIndex = [
  // ------------------------------------------------------------ Apparence
  SettingsSearchEntry.setting(
    id: 'theme',
    label: 'Thème',
    description: 'Système, sombre ou clair',
    words: ['theme', 'sombre', 'clair', 'nuit', 'jour', 'mode', 'dark'],
    path: _appearance,
    page: SettingsPage.appearance,
    value: () => switch (store.settings.theme) {
      'light' => 'Clair',
      'system' => 'Système',
      _ => 'Sombre',
    },
  ),
  SettingsSearchEntry.setting(
    id: 'palette',
    label: 'Palette',
    description: 'Couleur dominante de l’application',
    words: ['couleur', 'couleurs', 'palette', 'accent', 'teinte'],
    path: _appearance,
    page: SettingsPage.appearance,
    value: () => KAccentSpec.byId(store.settings.accent).label,
  ),
  SettingsSearchEntry.setting(
    id: 'contrast',
    label: 'Contraste renforcé',
    description: 'Textes et repères plus marqués',
    words: ['contraste', 'lisibilite', 'accessibilite', 'vue'],
    path: _appearance,
    page: SettingsPage.appearance,
    value: () => _onOff(store.settings.contrast),
  ),
  SettingsSearchEntry.setting(
    id: 'muscle-names',
    label: 'Nom du muscle au toucher',
    description: 'Carte des muscles et mannequin 3D',
    words: ['muscle', 'anatomie', 'mannequin', '3d', 'nom', 'toucher'],
    path: _anatomy,
    page: SettingsPage.appearance,
    value: () => _onOff(Display3DSettings.instance.touchNames.value),
  ),
  SettingsSearchEntry.setting(
    id: 'halo',
    label: 'Halo',
    description: 'Halo flou des muscles sollicités',
    words: ['halo', 'flou', 'lueur', 'mannequin', '3d', 'anatomie'],
    path: _anatomy,
    page: SettingsPage.appearance,
    value: () => _onOff(Display3DSettings.instance.halo.value),
  ),
  // --------------------------------------------------------------- Séance
  SettingsSearchEntry.setting(
    id: 'rest',
    label: 'Repos par défaut',
    description: 'Quand l’exercice n’en précise pas',
    words: ['repos', 'recup', 'recuperation', 'pause', 'chrono', 'minuteur'],
    path: _timers,
    page: SettingsPage.session,
    value: () => settingsSecondsLabel(store.settings.defaultRest),
  ),
  SettingsSearchEntry.setting(
    id: 'ready',
    label: 'Décompte « Prêt »',
    description: 'Avant intervalles, EMOM, AMRAP et tenues',
    words: ['decompte', 'pret', 'compte a rebours', 'emom', 'amrap'],
    path: _timers,
    page: SettingsPage.session,
    value: () => settingsSecondsLabel(store.settings.prepSec),
  ),
  SettingsSearchEntry.setting(
    id: 'auto-rest',
    label: 'Lancer le repos à la validation d’une série',
    description: 'Le chrono part tout seul',
    words: ['automatique', 'repos', 'pause', 'chrono', 'demarrer'],
    path: _timers,
    page: SettingsPage.session,
    value: () => _onOff(store.settings.autoTimer),
  ),
  SettingsSearchEntry.setting(
    id: 'sound',
    label: 'Son en fin de chrono',
    description: 'Repos, intervalles et tenues',
    words: ['son', 'bip', 'sonnerie', 'alarme', 'fin du repos', 'audio'],
    path: _restEnd,
    page: SettingsPage.session,
    value: () => _onOff(store.settings.sound),
  ),
  SettingsSearchEntry.setting(
    id: 'vibration',
    label: 'Vibration en fin de chrono',
    description: 'Fin de chrono, validation et records',
    words: ['vibration', 'vibreur', 'vibrer', 'haptique', 'fin du repos'],
    path: _restEnd,
    page: SettingsPage.session,
    value: () => _onOff(store.settings.vibration),
  ),
  SettingsSearchEntry.setting(
    id: 'velocity',
    label: 'Colonne vitesse (m/s) sur les lifts',
    description: 'Pour suivre la vitesse de tes répétitions',
    words: ['vitesse', 'vbt', 'colonne', 'saisie', 'lift'],
    path: _input,
    page: SettingsPage.session,
    value: () => _onOff(store.settings.trackVelocity),
  ),
  SettingsSearchEntry.setting(
    id: 'prefill',
    label: 'Pré-remplir charge suggérée et reps prévues',
    description: 'Saisie des séries',
    words: ['preremplir', 'pre-remplir', 'suggestion', 'charge', 'saisie'],
    path: _input,
    page: SettingsPage.session,
    value: () => _onOff(store.settings.prefill),
  ),
  SettingsSearchEntry.setting(
    id: 'wakelock',
    label: 'Garder l’écran allumé',
    description: 'Pendant l’exécution d’une séance',
    words: ['ecran', 'veille', 'allume', 'luminosite', 'eteint'],
    path: _screenUnits,
    page: SettingsPage.session,
    value: () => _onOff(store.settings.wakelock),
  ),
  SettingsSearchEntry.setting(
    id: 'pounds',
    label: 'Charges suggérées en livres (lb)',
    description: 'Les valeurs du journal et des références restent en kg',
    words: ['livres', 'lb', 'lbs', 'kg', 'kilos', 'unite', 'unites', 'poids'],
    path: _screenUnits,
    page: SettingsPage.session,
    value: () => _onOff(store.settings.lb),
  ),
  // -------------------------------------------------------- Notifications
  SettingsSearchEntry.setting(
    id: 'reminder',
    label: 'Rappels de séance',
    description: 'La séance du programme à l’heure choisie',
    words: ['rappel', 'rappels', 'notification', 'notifications', 'heure'],
    path: _notifications,
    page: SettingsPage.notifications,
    value: () => _onOff(store.settings.notifOn),
  ),
  SettingsSearchEntry.setting(
    id: 'reminder-time',
    label: 'Heure du rappel',
    description: 'Jours d’entraînement prévus uniquement',
    words: ['heure', 'horaire', 'rappel', 'notification', 'reveil'],
    path: _notifications,
    page: SettingsPage.notifications,
    value: () =>
        '${_two(store.settings.notifHour)}:${_two(store.settings.notifMinute)}',
    // La ligne n'existe que si les rappels sont activés.
    available: () => store.settings.notifOn,
  ),
  // --------------------------------------------------- Progression et jeu
  SettingsSearchEntry.setting(
    id: 'celebrations',
    label: 'Célébrations',
    description: 'Écran de récompenses, records en direct, cérémonie de niveau',
    words: ['celebration', 'recompenses', 'animation', 'niveau', 'jeu'],
    path: _progression,
    page: SettingsPage.progression,
    value: () => _onOff(store.settings.celebrations),
  ),
  SettingsSearchEntry.setting(
    id: 'weekly-goal',
    label: 'Objectif de la semaine',
    description: 'Jours actifs par semaine, adaptatif ou cap personnel',
    words: ['objectif', 'jours', 'semaine', 'hebdomadaire', 'frequence'],
    path: _progression,
    page: SettingsPage.progression,
    value: () => switch (store.settings.weeklyGoal) {
      0 => 'Adaptatif',
      1 => '1 jour',
      final g => '$g jours',
    },
  ),
  // ------------------------------------------- Données et confidentialité
  SettingsSearchEntry.setting(
    id: 'export',
    label: 'Exporter une sauvegarde',
    description: 'Fichier à l’emplacement de ton choix',
    words: ['sauvegarde', 'export', 'exporter', 'fichier', 'backup'],
    path: _backups,
    page: SettingsPage.data,
  ),
  SettingsSearchEntry.setting(
    id: 'import',
    label: 'Importer une sauvegarde',
    description: 'Depuis un fichier, avec aperçu et confirmation',
    words: ['sauvegarde', 'import', 'importer', 'restaurer', 'backup'],
    path: _backups,
    page: SettingsPage.data,
  ),
  SettingsSearchEntry.setting(
    id: 'copy',
    label: 'Copier la sauvegarde',
    description: 'Même contenu, en texte, dans le presse-papiers',
    words: ['sauvegarde', 'copier', 'presse-papiers', 'export', 'texte'],
    path: _backups,
    page: SettingsPage.data,
  ),
  SettingsSearchEntry.setting(
    id: 'paste',
    label: 'Coller une sauvegarde',
    description: 'Depuis un texte copié : même aperçu, même confirmation',
    words: ['sauvegarde', 'coller', 'import', 'restaurer', 'texte'],
    path: _backups,
    page: SettingsPage.data,
  ),
  SettingsSearchEntry.setting(
    id: 'retired-copy',
    label: 'Copie d’avant la suppression des WOD',
    description: 'Tes données d’avant cette mise à jour',
    words: ['wod', 'copie', 'sauvegarde', 'ancienne', 'seances perso'],
    path: _backups,
    page: SettingsPage.data,
    available: () => store.retiredNotice != null,
  ),
  SettingsSearchEntry.setting(
    id: 'android-backup',
    label: 'Sauvegarde Android',
    description: 'Sauvegarde Google du téléphone',
    words: ['android', 'google', 'sauvegarde', 'cloud', 'transfert'],
    path: _backups,
    page: SettingsPage.data,
  ),
  SettingsSearchEntry.setting(
    id: 'privacy',
    label: 'Politique de confidentialité',
    description: 'Données, santé, export, suppression, tes droits',
    words: ['confidentialite', 'vie privee', 'donnees', 'rgpd', 'droits'],
    path: _privacy,
    page: SettingsPage.data,
  ),
  SettingsSearchEntry.setting(
    id: 'delete-answers',
    label: 'Supprimer mes réponses aux anciens questionnaires',
    description: 'Sommeil, forme et douleur',
    words: ['questionnaire', 'reponses', 'effacer', 'supprimer', 'koach'],
    path: _danger,
    page: SettingsPage.data,
    available: () => store.koach.answers.isNotEmpty,
  ),
  SettingsSearchEntry.setting(
    id: 'erase',
    label: 'Supprimer les données de l’application',
    description: 'Remet l’application à son état d’installation',
    words: ['supprimer', 'effacer', 'reinitialiser', 'reset', 'donnees'],
    path: _danger,
    page: SettingsPage.data,
  ),
  // ---------------------------------------------- Profil et destinations
  SettingsSearchEntry.screen(
    id: 'profile',
    label: 'Profil',
    description: 'Prénom, poids, taille, disciplines, objectifs, santé',
    words: ['profil', 'poids', 'taille', 'age', 'prenom', 'disciplines'],
    path: 'Réglages',
    kind: SettingsSearchKind.setting,
    open: _screen(() => const ProfileScreen()),
  ),
  SettingsSearchEntry.screen(
    id: 'references',
    label: 'Mes références',
    description: 'Poids du corps, 1RM, maxima et accessoires',
    words: ['references', '1rm', 'max', 'maxima', 'charges', 'poids'],
    path: 'Profil',
    kind: SettingsSearchKind.setting,
    open: _screen(() => const PilotageScreen()),
  ),
  SettingsSearchEntry.screen(
    id: 'guided-tests',
    label: 'Tests guidés',
    description: 'Mesurer ton niveau sur un exercice',
    words: ['test', 'tests', 'evaluation', 'max', 'niveau'],
    path: 'Profil',
    kind: SettingsSearchKind.setting,
    open: _screen(() => const GuidedTestsScreen()),
  ),
  // ------------------------------------------------------ Aide et à propos
  SettingsSearchEntry.screen(
    id: 'safety',
    label: 'Santé et sécurité',
    description: 'Signaux d’alerte, douleur, situations particulières',
    words: ['sante', 'securite', 'douleur', 'blessure', 'alerte'],
    path: _about,
    open: _screen(() => const SafetyScreen()),
  ),
  SettingsSearchEntry.screen(
    id: 'recovery',
    label: 'Récupération',
    description: 'Sommeil, hydratation, repas, régularité',
    words: ['repos', 'recup', 'sommeil', 'hydratation', 'repas'],
    path: '$_about › Santé et sécurité',
    open: _screen(() => const RecoveryScreen()),
  ),
  SettingsSearchEntry.screen(
    id: 'explainer',
    label: 'Comment marche ton programme ?',
    description: 'Création avec Koach, puis évolution séance après séance',
    words: ['guide', 'aide', 'programme', 'explication', 'fonctionnement'],
    path: _about,
    open: showProgramExplainer,
  ),
  SettingsSearchEntry.screen(
    id: 'koach-gallery',
    label: 'Galerie de Koach',
    description: 'Toutes les poses de Koach',
    words: ['koach', 'mascotte', 'poses', 'galerie', 'personnage'],
    path: _about,
    open: _screen(() => const KoachGalleryScreen()),
  ),
  SettingsSearchEntry.screen(
    id: 'feedback',
    label: 'Donner mon avis',
    description: 'Retour de test, partagé seulement si tu le choisis',
    words: ['avis', 'retour', 'contact', 'bug', 'suggestion'],
    path: _about,
    open: _screen(() => const FeedbackScreen(appVersion: kAppVersion)),
  ),
  SettingsSearchEntry.screen(
    id: 'licences',
    label: 'Sources et licences',
    description: 'Fiches d’exercices, démonstrations et mannequin 3D',
    words: ['licence', 'licences', 'sources', 'credits', 'mentions'],
    path: _about,
    open: _screen(() => const MentionsScreen()),
  ),
  SettingsSearchEntry.screen(
    id: 'compat-3d',
    label: 'Compatibilité 3D',
    description: 'Rendu test, compatibilité du téléphone et fluidité',
    words: ['3d', 'moteur', 'rendu', 'compatibilite', 'fluidite'],
    path: _about,
    open: _screen(() => const Engine3DScreen()),
  ),
];

/// Entrées trouvées pour [input], de la plus pertinente à la moins
/// pertinente (ordre de l'index à score égal) ; vide si la requête l'est.
List<SettingsSearchEntry> searchSettings(String input) {
  final q = SearchQuery(input);
  if (q.isEmpty) return const <SettingsSearchEntry>[];
  final hits = <({SettingsSearchEntry entry, double score, int order})>[];
  for (var i = 0; i < settingsSearchIndex.length; i++) {
    final e = settingsSearchIndex[i];
    if (!e.isAvailable || !q.matches(e.doc.all)) continue;
    hits.add((entry: e, score: q.score(e.doc), order: i));
  }
  hits.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    return byScore != 0 ? byScore : a.order.compareTo(b.order);
  });
  return [for (final h in hits) h.entry];
}
