// L13 (KT-072 à KT-078) — écrans : santé et sécurité, récupération,
// politique de confidentialité, retour de test, blocage d'un profil de
// moins de 18 ans. Icônes et texte seulement (pas d'illustration).
// Contrat : docs/CONTRAT_L13.md.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'data_control.dart' show eraseAppData;
import 'exercise_screens.dart' show markdownBlocks;
import 'profile_screens.dart' show ProfileFlow;
import 'settings_screen.dart' show kAppVersion;
import 'store.dart';
import 'ui.dart';

/// Avertissement (démarrage et « À propos »).
class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) => KCard(
    key: const ValueKey('wellness-disclaimer'),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.health_and_safety_outlined, color: SL.accent),
        const SizedBox(width: 10),
        const Expanded(child: Text(kWellnessDisclaimer)),
      ],
    ),
  );
}

Widget _title(BuildContext context, String t) =>
    Text(t, style: Theme.of(context).textTheme.titleMedium);

/// Santé et sécurité : signaux d'alerte, douleur, situations particulières.
class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final referral = store.painReferralMovements;
      return KScreen(
        appBar: AppBar(title: const Text('SANTÉ ET SÉCURITÉ')),
        body: KList(
          key: const ValueKey('safety-screen'),
          children: [
            KCard(
              key: const ValueKey('safety-alert'),
              accent: SL.accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: SL.accent),
                      const SizedBox(width: 8),
                      Expanded(child: _title(context, 'Signal d’alerte')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final s in kAlertSignals)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [const Text('•  '), Expanded(child: Text(s))],
                      ),
                    ),
                  const SizedBox(height: 6),
                  const Text(
                    kAlertAdvice,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const KSection('Douleur'),
            KCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(kPainAdvice),
                  if (referral.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      key: const ValueKey('safety-referral'),
                      '${referral.map(koachMovementName).join(', ')} : '
                      '$kPainReferral',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            const KSection('Situations particulières'),
            for (final s in kSpecialSituations)
              KCard(
                key: ValueKey('safety-situation-${s.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(context, s.title),
                    const SizedBox(height: 4),
                    Text(s.text),
                  ],
                ),
              ),
            KMenuTile(
              icon: Icons.bedtime_outlined,
              title: 'Récupération',
              subtitle: 'Sommeil, hydratation, repas, régularité',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const RecoveryScreen(),
                    ),
                  ),
            ),
            const DisclaimerCard(),
          ],
        ),
      );
    },
  );
}

/// Conseils généraux de récupération (KT-072).
class RecoveryScreen extends StatelessWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(title: const Text('RÉCUPÉRATION')),
    body: KList(
      key: const ValueKey('recovery-screen'),
      children: [
        const KPageIntro(
          'Récupérer',
          'Des repères généraux, sans calcul ni objectif de poids.',
        ),
        for (final t in kRecoveryTips)
          KCard(
            key: ValueKey('recovery-${t.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title(context, t.title),
                const SizedBox(height: 4),
                Text(t.text),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Politique de confidentialité (même texte que la version publiée).
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  static const asset = 'assets/legal/confidentialite.md';

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  // Chargé une fois, sans cache partagé (texte court, lu rarement).
  late final Future<String> _text = rootBundle.loadString(
    PrivacyPolicyScreen.asset,
    cache: false,
  );

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(title: const Text('CONFIDENTIALITÉ')),
    body: FutureBuilder<String>(
      future: _text,
      builder: (context, snap) {
        if (snap.hasError) {
          return const KEmpty(
            icon: Icons.error_outline,
            title: 'Politique indisponible',
            message: 'Le texte n’a pas pu être lu. Réinstalle l’application.',
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return KList(
          key: const ValueKey('privacy-screen'),
          children: markdownBlocks(context, snap.data!),
        );
      },
    ),
  );
}

/// Partage d'un texte par le menu Android (aucun serveur).
class FeedbackChannel {
  static const _channel = MethodChannel('kalis_track/share');

  /// Hook de test : remplace l'appel natif.
  static Future<String> Function(String text)? debugHook;

  static Future<String> shareText(String text) async {
    final hook = debugHook;
    if (hook != null) return hook(text);
    try {
      final r = await _channel.invokeMethod<String>('shareText', {
        'text': text,
        'subject': 'Retour de test Kalis Track',
      });
      return r ?? 'error';
    } on MissingPluginException {
      return 'unsupported';
    } on PlatformException {
      return 'error';
    }
  }
}

/// Retour de test (KT-078) : formulaire local, aperçu exact du texte,
/// partage volontaire. Rien n'est enregistré ni envoyé par l'application.
class FeedbackScreen extends StatefulWidget {
  final String appVersion;
  const FeedbackScreen({super.key, required this.appVersion});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _d = FeedbackDraft();
  final _worked = TextEditingController();
  final _blocked = TextEditingController();
  final _other = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _worked.dispose();
    _blocked.dispose();
    _other.dispose();
    super.dispose();
  }

  String get _text {
    _d
      ..worked = _worked.text
      ..blocked = _blocked.text
      ..other = _other.text;
    return feedbackText(
      _d,
      appVersion: widget.appVersion,
      level: store.feedbackLevel,
      caution: store.profile == null ? null : store.caution.active,
    );
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    final result = await FeedbackChannel.shareText(_text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result != 'shared') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Partage indisponible. Copie le texte et envoie-le toi-même.',
          ),
        ),
      );
    }
  }

  Widget _field(String key, String label, TextEditingController c) => TextField(
    key: ValueKey('feedback-$key'),
    controller: c,
    minLines: 2,
    maxLines: 6,
    maxLength: 2000,
    onChanged: (_) => setState(() {}),
    decoration: InputDecoration(labelText: label),
  );

  @override
  Widget build(BuildContext context) {
    final text = _text;
    return KScreen(
      appBar: AppBar(title: const Text('DONNER MON AVIS')),
      body: KList(
        key: const ValueKey('feedback-screen'),
        children: [
          const KPageIntro(
            'Ton avis',
            'Rien n’est envoyé automatiquement : tu choisis ce que tu '
                'partages et avec qui.',
          ),
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title(context, 'Ce que tu as testé'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in kTestScenarios)
                      ChoiceChip(
                        key: ValueKey('feedback-scenario-${s.$1}'),
                        label: Text(s.$3),
                        selected: _d.scenario == s.$1,
                        onSelected: (_) => setState(() => _d.scenario = s.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _title(context, 'Ta note (facultative)'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      ChoiceChip(
                        key: ValueKey('feedback-rating-$i'),
                        label: Text('$i'),
                        tooltip: 'Note $i sur 5',
                        selected: _d.rating == i,
                        onSelected:
                            (on) => setState(() => _d.rating = on ? i : null),
                      ),
                  ],
                ),
              ],
            ),
          ),
          _field('worked', 'Ce qui marche bien', _worked),
          _field('blocked', 'Ce qui bloque ou gêne', _blocked),
          _field('other', 'Autre remarque', _other),
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title(context, 'Ajouter (facultatif)'),
                CheckboxListTile(
                  key: const ValueKey('feedback-include-version'),
                  contentPadding: EdgeInsets.zero,
                  value: _d.includeVersion,
                  onChanged: (v) => setState(() => _d.includeVersion = v!),
                  title: Text('Version ${widget.appVersion}'),
                ),
                if (store.feedbackLevel != null)
                  CheckboxListTile(
                    key: const ValueKey('feedback-include-level'),
                    contentPadding: EdgeInsets.zero,
                    value: _d.includeLevel,
                    onChanged: (v) => setState(() => _d.includeLevel = v!),
                    title: const Text('Mon repère de niveau'),
                  ),
                if (store.profile != null)
                  CheckboxListTile(
                    key: const ValueKey('feedback-include-caution'),
                    contentPadding: EdgeInsets.zero,
                    value: _d.includeCaution,
                    onChanged: (v) => setState(() => _d.includeCaution = v!),
                    title: const Text('Mode prudent actif ou non'),
                  ),
                Text(
                  'Jamais inclus : historique, charges, poids, réponses de '
                  'santé.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const KSection('Texte qui sera partagé'),
          KCard(
            child: SelectableText(
              key: const ValueKey('feedback-preview'),
              text,
            ),
          ),
          FilledButton.icon(
            key: const ValueKey('feedback-share'),
            onPressed: _busy || _d.isEmpty ? null : _share,
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Partager mon avis'),
          ),
          OutlinedButton.icon(
            key: const ValueKey('feedback-copy'),
            onPressed:
                _d.isEmpty
                    ? null
                    : () async {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Texte copié.')),
                      );
                    },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copier le texte'),
          ),
        ],
      ),
    );
  }
}

/// Profil chargé ou importé de moins de 18 ans : application bloquée
/// jusqu'à correction de l'année de naissance ou suppression des données.
class MinorGate extends StatelessWidget {
  const MinorGate({super.key});

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text('RÉSERVÉE AUX ADULTES'),
    ),
    body: KList(
      key: const ValueKey('minor-gate'),
      children: [
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: SL.accent),
              const SizedBox(height: 8),
              const Text(
                'Kalis Track est réservée aux personnes de 18 ans et plus. '
                'L’année de naissance enregistrée indique moins de 18 ans.',
              ),
            ],
          ),
        ),
        OutlinedButton(
          key: const ValueKey('minor-gate-edit'),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ProfileFlow(initial: store.profile!.copy()),
                ),
              ),
          child: const Text('Corriger mon année de naissance'),
        ),
        TextButton(
          key: const ValueKey('minor-gate-erase'),
          onPressed: () => eraseAppData(context, appVersion: kAppVersion),
          child: const Text('Supprimer les données de l’application'),
        ),
      ],
    ),
  );
}
