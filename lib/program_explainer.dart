// G6 correction 1 : Koach explique comment le programme est créé puis géré
// (D4, D5, D6.4), et l'accueil d'un nouveau profil sans programme n'affiche
// plus le programme de 40 semaines embarqué en attendant la création du
// programme (G7). Textes sans promesse de résultat (règles L13). G7 : la
// vue d'attente propose de créer le programme.
import 'package:flutter/material.dart';
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import 'athlete_profile_screen.dart' show ProfileScreen;
import 'dev/dev_widgets.dart' show HeaderLogo;
import 'koach/koach_bubble.dart';
import 'plan/evolution_widgets.dart' show EvolutionScreen;
import 'plan/plan_screens.dart' show openPlanCreation;
import 'plan/widgets/program_widgets.dart';
import 'program_screens.dart' show planCreateBlockedReason;
import 'store.dart';
import 'ui.dart';

/// Une étape de l'explication : titre et texte.
typedef ExplainerStep = ({String title, String text});

/// Comment le programme est créé puis géré.
const List<ExplainerStep> kProgramExplainer = [
  (
    title: '1. Les exercices de chaque séance',
    text:
        'Je choisis d’abord les exercices de chaque séance d’après ton '
        'profil : disciplines et dosage, niveau par mouvement, objectifs, '
        'jours et durée, lieux et matériel, gênes. Même profil, même '
        'programme ; « Autre proposition » en donne une autre équivalente.',
  ),
  (
    title: '2. Tu passes en revue',
    text:
        'Exercice par exercice : « Je sais faire », « Je ne sais pas '
        'faire » ou « Je n’aime pas ». Je te propose aussitôt des '
        'variantes (plus facile, équivalente, autre matériel, ou toute la '
        'liste). Tu peux aussi ajouter ou retirer un exercice. Ce que tu as '
        'validé reste fixé ; le reste est recalculé, et je te montre ce qui '
        'a bougé et pourquoi.',
  ),
  (
    title: '3. Séries, répétitions, charges',
    text:
        'Une fois les exercices validés, j’ajoute les séries, les '
        'répétitions, l’effort visé, les repos et les charges. Les charges '
        'de départ sont prudentes : tes 2 ou 3 premières séances servent à '
        'les caler. Je t’explique la logique et tu peux ajuster avant de '
        'valider.',
  ),
  (
    title: '4. Des blocs de 4 à 6 semaines',
    text:
        'Le programme n’a pas de fin : chaque bloc de 4 à 6 semaines est '
        'construit à partir du précédent et de ce que tu as réellement fait. '
        'Si tu changes de téléphone ou rates des séances, tu peux choisir où '
        'tu en es.',
  ),
  (
    title: '5. Pendant les séances',
    text:
        'Chaque série se note en flammes, de 1 (très facile) à 10 (échec). '
        'En début de séance, une question : « Comment tu te sens ? » — le '
        'détail seulement si ça ne va pas, et tout est facultatif. Une '
        'douleur me fait éviter la zone concernée.',
  ),
  (
    title: '6. Le programme évolue avec toi',
    text:
        'Peu de changements au début, puis davantage avec tes données : '
        'charges et répétitions dès la première séance, volume après 2 '
        'semaines, échange d’exercice après 4 semaines, réorganisation d’une '
        'séance après un bloc, d’un bloc après deux — et seulement quand '
        'j’ai assez de données pour être sûr de moi.',
  ),
  (
    title: '7. Assisté ou libre',
    text:
        'En mode assisté, j’applique moi-même ce que je propose, je te dis '
        'pourquoi et tu peux toujours annuler. En mode libre, je propose et '
        'tu décides : rien ne change sans ton accord. Tu changes de mode '
        'dans Évolution.',
  ),
  (
    title: '8. Ton profil',
    text:
        'Tu modifies ton profil à tout moment, rubrique par rubrique. Si un '
        'changement touche ton programme, je te le dis et je le refais avec '
        'toi.',
  ),
];

/// Destination d'une étape de l'explication (R5 : un bouton, jamais un
/// chemin écrit) : 7 → Évolution, 8 → Mon profil.
({String label, Widget Function() page})? _stepLink(int i) => switch (i) {
  6 => (label: 'Ouvrir Évolution', page: () => const EvolutionScreen()),
  7 => (label: 'Ouvrir mon profil', page: () => const ProfileScreen()),
  _ => null,
};

/// Feuille « Comment marche ton programme ? ».
Future<void> showProgramExplainer(BuildContext context) =>
    showProgramSheet<void>(
      context,
      draggable: true,
      listKey: const ValueKey('program-explainer'),
      title: 'Comment marche ton programme',
      children: (ctx) {
        final k = KTokens.of(ctx);
        return [
          const KoachBubble(
            pose: KoachPose.explainBoard,
            koachHeight: KSize.primary * 2,
            text:
                'Je crée ton programme avec toi, en deux temps, puis je '
                'le fais évoluer séance après séance.',
          ),
          for (var i = 0; i < kProgramExplainer.length; i++)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kProgramExplainer[i].title,
                  style: KType.titreCarte.copyWith(color: k.texte),
                ),
                const SizedBox(height: KSpacing.s4),
                Text(
                  kProgramExplainer[i].text,
                  style: KType.corps.copyWith(color: k.texte),
                ),
                if (_stepLink(i) case final link?)
                  KTextButton(
                    key: ValueKey('program-explainer-link-$i'),
                    label: link.label,
                    icon: Icons.chevron_right_rounded,
                    alignStart: true,
                    onPressed: () {
                      Navigator.of(ctx).push(
                        MaterialPageRoute<void>(builder: (_) => link.page()),
                      );
                    },
                  ),
              ],
            ),
          KPrimaryButton(
            key: const ValueKey('program-explainer-ok'),
            onPressed: () => Navigator.pop(ctx),
            label: 'Compris',
          ),
        ];
      },
    );

/// Bouton « Comment marche ton programme ? ».
class ProgramExplainerButton extends StatelessWidget {
  const ProgramExplainerButton({super.key});

  @override
  Widget build(BuildContext context) => KTonalButton(
    key: const ValueKey('program-explainer-open'),
    icon: Icons.help_outline_rounded,
    label: 'Comment marche ton programme ?',
    expand: true,
    onPressed: () => showProgramExplainer(context),
  );
}

/// Nouveau profil sans programme : rien du programme embarqué de 40
/// semaines n'est affiché tant que le programme n'est pas créé (G7).
bool programPendingFor(AppStore s) =>
    s.athlete != null &&
    s.program.start == null &&
    !s.programGenerated &&
    s.planProgram == null;

/// Onglet Programme d'un nouveau profil, en attendant son programme : Koach
/// propose de le créer (G7). Bouton indisponible : la raison est écrite
/// dessous (R6).
class ProgramPendingView extends StatelessWidget {
  const ProgramPendingView({super.key});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final blocked = planCreateBlockedReason();
    return Scaffold(
      backgroundColor: k.fond,
      body: SafeArea(
        bottom: false,
        child: ListView(
          key: const ValueKey('program-pending'),
          padding: EdgeInsets.fromLTRB(
            KSpacing.page,
            KSpacing.s8,
            KSpacing.page,
            KSpacing.s16 + KNavigationInset.of(context),
          ),
          children: [
            // En-tête de l'accueil : logo (et gestes du mode dev) gardés.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      k.title('Ton programme'),
                      style: k.titleStyle(
                        KType.titreRacine.copyWith(color: k.texte),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: KSpacing.s12),
                const HeaderLogo(),
              ],
            ),
            const SizedBox(height: KSpacing.s16),
            const KoachBubble(
              pose: KoachPose.checklist,
              koachHeight: KSize.primary * 2,
              text:
                  'Ton profil est prêt. On crée ton programme ensemble : '
                  'd’abord les exercices de chaque séance, puis les séries et '
                  'les charges.',
            ),
            const SizedBox(height: KSpacing.s24),
            KPrimaryButton(
              key: const ValueKey('program-pending-create'),
              icon: Icons.auto_awesome_outlined,
              label: 'Créer mon programme',
              onPressed: blocked == null
                  ? () => openPlanCreation(context)
                  : null,
            ),
            if (blocked != null)
              Padding(
                padding: const EdgeInsets.only(top: KSpacing.s8),
                child: Text(
                  blocked,
                  key: const ValueKey('program-pending-blocked'),
                  style: KType.detail.copyWith(color: k.texte2),
                ),
              ),
            const SizedBox(height: KSpacing.s12),
            const ProgramExplainerButton(),
          ],
        ),
      ),
    );
  }
}
