// G6 correction 1 : Koach explique comment le programme est créé puis géré
// (D4, D5, D6.4), et l'accueil d'un nouveau profil sans programme n'affiche
// plus le programme de 40 semaines embarqué en attendant la création du
// programme (G7). Textes sans promesse de résultat (règles L13). G7 : la
// vue d'attente propose de créer le programme.
import 'package:flutter/material.dart';
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import 'app_theme.dart';
import 'koach/koach_bubble.dart';
import 'koach/koach_view.dart';
import 'plan/plan_screens.dart' show openPlanCreation;
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
        'dans Réglages › Profil.',
  ),
  (
    title: '8. Ton profil',
    text:
        'Tu modifies ton profil à tout moment dans Réglages › Profil, '
        'rubrique par rubrique. Si un changement touche ton programme, je te '
        'le dis et je le refais avec toi.',
  ),
];

/// Feuille « Comment marche ton programme ? ».
Future<void> showProgramExplainer(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        final tt = Theme.of(ctx).textTheme;
        return KoachSurface(
          color:
              Theme.of(ctx).bottomSheetTheme.backgroundColor ??
              Theme.of(ctx).colorScheme.surfaceContainerLow,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: .85,
            maxChildSize: .95,
            builder: (ctx, scroll) => ListView(
              key: const ValueKey('program-explainer'),
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text('Comment marche ton programme', style: tt.titleLarge),
                const SizedBox(height: 12),
                const KoachBubble(
                  pose: KoachPose.explainBoard,
                  koachHeight: 96,
                  text:
                      'Je crée ton programme avec toi, en deux temps, puis je '
                      'le fais évoluer séance après séance.',
                ),
                for (final s in kProgramExplainer) ...[
                  const SizedBox(height: 14),
                  Text(s.title, style: tt.titleMedium),
                  const SizedBox(height: 4),
                  Text(s.text),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  key: const ValueKey('program-explainer-ok'),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Compris'),
                ),
              ],
            ),
          ),
        );
      },
    );

/// Bouton « Comment marche ton programme ? ».
class ProgramExplainerButton extends StatelessWidget {
  const ProgramExplainerButton({super.key});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: const ValueKey('program-explainer-open'),
    icon: const Icon(Icons.help_outline),
    label: const Text('Comment marche ton programme ?'),
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
/// propose de le créer (G7).
class ProgramPendingView extends StatelessWidget {
  const ProgramPendingView({super.key});

  @override
  Widget build(BuildContext context) => KScreen(
    // En-tête de l'accueil : logo (et gestes du mode dev) gardés.
    appBar: KTopBar(
      leading: Text(
        'TON PROGRAMME',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ),
    body: KList(
      key: const ValueKey('program-pending'),
      children: [
        KoachSurface(
          color: SL.bg,
          child: const KoachBubble(
            pose: KoachPose.checklist,
            koachHeight: 120,
            text:
                'Ton profil est prêt. On crée ton programme ensemble : '
                'd’abord les exercices de chaque séance, puis les séries et '
                'les charges.',
          ),
        ),
        FilledButton.icon(
          key: const ValueKey('program-pending-create'),
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('Créer mon programme'),
          onPressed: PlanStore(store).planCanCreate
              ? () => openPlanCreation(context)
              : null,
        ),
        const ProgramExplainerButton(),
      ],
    ),
  );
}
