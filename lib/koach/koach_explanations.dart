// Correctifs UI (11/10/2026) : les explications de Koach quittent la séance
// (« Pourquoi ? », consignes répétées) et sont rassemblées ici, lisibles
// depuis Réglages › Séance › Koach › « Comprendre Koach ». Le mode guidé
// (`AppSettings.koachGuided`) les remet dans la séance.
import 'package:flutter/material.dart';

import '../kit/kit.dart';
import '../store.dart';

/// Vrai quand Koach explique ses choix pendant la séance (mode guidé).
bool get koachGuided => store.settings.koachGuided;

/// Pourquoi le Bilan du jour (en-tête « Comment tu te sens ? »).
const kHealthCheckWhy =
    'Ta réponse règle la séance d’aujourd’hui. Si ça ne va pas, je te '
    'poserai quelques questions, toutes facultatives.';

/// Explications de Koach : titre, texte.
const kKoachExplanations = <(String, String)>[
  ('Bilan du jour', kHealthCheckWhy),
  (
    'Difficulté visée et RIR',
    'La difficulté visée (sur 10) dit combien de répétitions garder en '
        'réserve à la fin d’une série : RIR 2, c’est encore 2 répétitions '
        'possibles. Note chaque série en flammes, c’est ce qui me règle.',
  ),
  (
    'Charge proposée',
    'Je pars de tes dernières séances : la charge monte quand tes séries '
        'sont plus faciles que prévu et baisse quand elles sont plus dures. '
        'Sur un exercice nouveau, je la cale sur tes 2 ou 3 premières '
        'séances (calibrage).',
  ),
  (
    'Dernière série ouverte',
    'La dernière série d’un exercice est ouverte : autant de répétitions '
        'que possible (ou aussi longtemps que possible sur un maintien) en '
        'gardant la réserve indiquée.',
  ),
  (
    'Clusters, myo-reps, rest-pause',
    'Cluster : la série est coupée en mini-séries séparées d’un mini-repos. '
        'RIR visé sur chaque bloc · note la série au bloc le plus dur. '
        'Note chaque mini-série à la fin de son effort et arrête dès qu’une '
        'mini-série n’atteint plus la cible. Myo-reps : une série '
        'd’activation, puis de courtes mini-séries. Rest-pause : une série, '
        'puis des relances après un court repos.',
  ),
  (
    'Séance précédente',
    'L’icône d’historique d’un exercice affiche ta dernière séance ; '
        '« Reprendre » recopie ses charges et ses répétitions.',
  ),
  (
    'Se déplacer dans la séance',
    'Glisse à gauche ou à droite pour changer d’exercice. Touche le titre '
        'de la séance, ou « Exercice n sur N », pour voir la liste.',
  ),
];

/// Feuille « Comprendre Koach » (Réglages › Séance › Koach).
Future<void> showKoachExplanations(BuildContext context) =>
    showKContentSheet<void>(
      context,
      title: 'Comprendre Koach',
      subtitle: 'Ce que Koach explique en mode guidé',
      children: (ctx) {
        final k = KTokens.of(ctx);
        return [
          for (final (title, text) in kKoachExplanations)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: KType.corpsFort.copyWith(color: k.encre)),
                const SizedBox(height: KSpacing.s4),
                Text(text, style: KType.corps.copyWith(color: k.texte)),
              ],
            ),
        ];
      },
    );
