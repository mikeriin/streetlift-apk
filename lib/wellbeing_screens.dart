// L13 (KT-072 à KT-078) — écrans : santé et sécurité, récupération,
// politique de confidentialité, retour de test, blocage d'un profil de
// moins de 18 ans. Icônes et texte seulement (pas d'illustration).
// Contrat : docs/CONTRAT_L13.md.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data_control.dart' show eraseAppData;
import 'exercise_screens.dart' show markdownBlocks;
import 'athlete_profile_flow.dart';
import 'settings_screen.dart' show kAppVersion;
import 'store.dart';
import 'ui.dart';

/// Avertissement (démarrage et « À propos »).
class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return KCard(
      key: const ValueKey('wellness-disclaimer'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety_outlined, color: k.encre),
          const SizedBox(width: KSpacing.s12),
          Expanded(
            child: Text(
              kWellnessDisclaimer,
              style: KType.corps.copyWith(color: k.texte),
            ),
          ),
        ],
      ),
    );
  }
}

/// Titre d'une carte (texte de santé ou de conseil).
Widget _title(BuildContext context, String t) =>
    Text(t, style: KType.titreCarte.copyWith(color: KTokens.of(context).texte));

/// Texte courant d'une carte.
Widget _text(BuildContext context, String t, {Key? key, bool strong = false}) =>
    Text(
      t,
      key: key,
      style: (strong ? KType.corpsFort : KType.corps).copyWith(
        color: KTokens.of(context).texte,
      ),
    );

/// Santé et sécurité : signaux d'alerte, douleur, situations particulières.
class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final k = KTokens.of(context);
      final referral = store.painReferralMovements;
      return KPage.sub(
        key: const ValueKey('safety-screen'),
        title: 'Santé et sécurité',
        children: [
          KCard(
            key: const ValueKey('safety-alert'),
            accent: k.avertissement,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: k.avertissement),
                    const SizedBox(width: KSpacing.s8),
                    Expanded(child: _title(context, 'Signal d’alerte')),
                  ],
                ),
                const SizedBox(height: KSpacing.s8),
                for (final s in kAlertSignals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: KSpacing.s4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _text(context, '•  '),
                        Expanded(child: _text(context, s)),
                      ],
                    ),
                  ),
                const SizedBox(height: KSpacing.s8),
                _text(context, kAlertAdvice, strong: true),
              ],
            ),
          ),
          const KSectionTitle('Douleur'),
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _text(context, kPainAdvice),
                if (referral.isNotEmpty) ...[
                  const SizedBox(height: KSpacing.s12),
                  _text(
                    context,
                    '${referral.map(koachMovementName).join(', ')} : '
                    '$kPainReferral',
                    key: const ValueKey('safety-referral'),
                    strong: true,
                  ),
                ],
              ],
            ),
          ),
          const KSectionTitle('Situations particulières'),
          for (final s in kSpecialSituations)
            KCard(
              key: ValueKey('safety-situation-${s.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(context, s.title),
                  const SizedBox(height: KSpacing.s4),
                  _text(context, s.text),
                ],
              ),
            ),
          KMenuGroup(
            children: [
              KMenuRow(
                key: const ValueKey('safety-recovery'),
                icon: Icons.bedtime_outlined,
                title: 'Récupération',
                subtitle: 'Sommeil, hydratation, repas, régularité',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const RecoveryScreen(),
                  ),
                ),
              ),
            ],
          ),
          const DisclaimerCard(),
        ],
      );
    },
  );
}

/// Conseils généraux de récupération (KT-072). UI4 (R3) : titre
/// « Récupération », comme l'entrée qui y mène ; plus d'intro « Récupérer ».
class RecoveryScreen extends StatelessWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) => KPage.sub(
    key: const ValueKey('recovery-screen'),
    title: 'Récupération',
    lead: 'Des repères généraux, sans calcul ni objectif de poids.',
    children: [
      for (final t in kRecoveryTips)
        KCard(
          key: ValueKey('recovery-${t.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title(context, t.title),
              const SizedBox(height: KSpacing.s4),
              _text(context, t.text),
            ],
          ),
        ),
    ],
  );
}

/// Politique de confidentialité (même texte que la version publiée).
/// UI4 (R3) : titre « Politique de confidentialité », comme l'entrée.
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

  static const _title = 'Politique de confidentialité';

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _text,
    builder: (context, snap) {
      if (snap.hasError) {
        return const KPage.sub(
          title: _title,
          children: [
            KEmpty(
              icon: Icons.error_outline,
              title: 'Politique indisponible',
              message: 'Le texte n’a pas pu être lu. Réinstalle l’application.',
            ),
          ],
        );
      }
      if (!snap.hasData) {
        return const KPage.sub(
          title: _title,
          children: [Center(child: CircularProgressIndicator())],
        );
      }
      return KPage.sub(
        key: const ValueKey('privacy-screen'),
        title: _title,
        children: markdownBlocks(context, snap.data!),
      );
    },
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
      caution: store.hasAnyProfile ? store.caution.active : null,
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

  /// UI4 (R3) : titre « Donner mon avis », comme l'entrée ; plus d'intro
  /// « Ton avis ». Puces du kit, note en segments, cases en interrupteurs,
  /// « Partager mon avis » en bouton principal en bas.
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final text = _text;
    return KPage.sub(
      key: const ValueKey('feedback-screen'),
      title: 'Donner mon avis',
      lead:
          'Rien n’est envoyé automatiquement : tu choisis ce que tu '
          'partages et avec qui.',
      bottom: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpacing.page,
            KSpacing.s8,
            KSpacing.page,
            KSpacing.s16,
          ),
          child: KPrimaryButton(
            key: const ValueKey('feedback-share'),
            onPressed: _busy || _d.isEmpty ? null : _share,
            icon: Icons.ios_share_rounded,
            label: 'Partager mon avis',
          ),
        ),
      ),
      children: [
        const KSectionTitle('Ce que tu as testé'),
        Wrap(
          spacing: KSpacing.s8,
          runSpacing: KSpacing.s8,
          children: [
            for (final s in kTestScenarios)
              KChip(
                s.$3,
                key: ValueKey('feedback-scenario-${s.$1}'),
                selected: _d.scenario == s.$1,
                onTap: () => setState(() => _d.scenario = s.$1),
              ),
          ],
        ),
        const KSectionTitle('Ta note (facultative)'),
        KSegmented<int>(
          key: const ValueKey('feedback-rating'),
          semanticLabel: 'Ta note sur 5',
          segments: [
            const KSegment(0, 'Aucune', semanticLabel: 'Pas de note'),
            for (var i = 1; i <= 5; i++)
              KSegment(i, '$i', semanticLabel: 'Note $i sur 5'),
          ],
          selected: _d.rating ?? 0,
          onChanged: (v) => setState(() => _d.rating = v == 0 ? null : v),
        ),
        _field('worked', 'Ce qui marche bien', _worked),
        _field('blocked', 'Ce qui bloque ou gêne', _blocked),
        _field('other', 'Autre remarque', _other),
        KMenuGroup(
          title: 'Ajouter (facultatif)',
          children: [
            KSwitchRow(
              key: const ValueKey('feedback-include-version'),
              title: 'Version ${widget.appVersion}',
              value: _d.includeVersion,
              onChanged: (v) => setState(() => _d.includeVersion = v),
            ),
            if (store.feedbackLevel != null)
              KSwitchRow(
                key: const ValueKey('feedback-include-level'),
                title: 'Mon repère de niveau',
                value: _d.includeLevel,
                onChanged: (v) => setState(() => _d.includeLevel = v),
              ),
            if (store.hasAnyProfile)
              KSwitchRow(
                key: const ValueKey('feedback-include-caution'),
                title: 'Mode prudent actif ou non',
                value: _d.includeCaution,
                onChanged: (v) => setState(() => _d.includeCaution = v),
              ),
          ],
        ),
        Text(
          'Jamais inclus : historique, charges, poids, réponses de santé.',
          style: KType.detail.copyWith(color: k.texte2),
        ),
        const KSectionTitle('Texte qui sera partagé'),
        KCard(
          child: SelectableText(
            key: const ValueKey('feedback-preview'),
            text,
            style: KType.corps.copyWith(color: k.texte),
          ),
        ),
        KTonalButton(
          key: const ValueKey('feedback-copy'),
          expand: true,
          onPressed: _d.isEmpty
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Texte copié.')));
                },
          icon: Icons.copy_rounded,
          label: 'Copier le texte',
        ),
      ],
    );
  }
}

/// Profil chargé ou importé de moins de 18 ans : application bloquée
/// jusqu'à correction de l'année de naissance ou suppression des données.
/// UI4 : page sans retour (barrière), titre en grand comme une racine.
class MinorGate extends StatelessWidget {
  const MinorGate({super.key});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return KPage.root(
      key: const ValueKey('minor-gate'),
      title: 'Réservée aux adultes',
      children: [
        KCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: k.encre),
              const SizedBox(width: KSpacing.s12),
              Expanded(
                child: Text(
                  'Kalis Track est réservée aux personnes de 18 ans et plus. '
                  'L’année de naissance enregistrée indique moins de 18 ans.',
                  style: KType.corps.copyWith(color: k.texte),
                ),
              ),
            ],
          ),
        ),
        KPrimaryButton(
          key: const ValueKey('minor-gate-edit'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              // G6 : rubrique « Toi » du profil v2 (ou création du profil
              // v2 pour un ancien profil L8).
              builder: (ctx) => store.athlete != null
                  ? const AthleteProfileFlow(
                      mode: AthleteFlowMode.edit,
                      editStep: 'identity',
                    )
                  : AthleteProfileFlow(
                      mode: AthleteFlowMode.redo,
                      onDone: () => Navigator.pop(ctx),
                      onCancel: () => Navigator.pop(ctx),
                    ),
            ),
          ),
          label: 'Corriger mon année de naissance',
        ),
        KMenuGroup(
          children: [
            KMenuRow(
              key: const ValueKey('minor-gate-erase'),
              icon: Icons.delete_outline,
              title: 'Supprimer les données de l’application',
              danger: true,
              onTap: () => eraseAppData(context, appVersion: kAppVersion),
            ),
          ],
        ),
      ],
    );
  }
}
