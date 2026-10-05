// L13 (KT-072 à KT-078) — santé, sécurité, conformité et test fermé :
// textes de référence et règles pures (sans horloge implicite, sans état).
// Bien-être et entraînement uniquement : aucune allégation médicale,
// aucun diagnostic, aucune promesse de résultat. Contrat :
// docs/CONTRAT_L13.md.

/// Avertissement affiché au démarrage (premier écran) et dans « À propos ».
const kWellnessDisclaimer =
    'Kalis Track est une application d’entraînement et de bien-être. Elle '
    'n’est pas un dispositif médical : elle ne pose aucun diagnostic, ne '
    'remplace pas l’avis d’un médecin ou d’un kinésithérapeute et ne promet '
    'aucun résultat. Les estimations sont des repères d’entraînement, pas '
    'des mesures de santé. En cas de doute sur ta santé, demande l’avis d’un '
    'professionnel avant de t’entraîner.';

// ------------------------------------------------ KT-072 récupération

/// Conseil général de récupération (titre, texte). Aucun calcul de
/// calories ni de macronutriments, aucun objectif de poids, aucune
/// restriction.
class WellnessTip {
  final String id, title, text;
  const WellnessTip(this.id, this.title, this.text);
}

const kRecoveryTips = <WellnessTip>[
  WellnessTip(
    'protein',
    'Des protéines à chaque repas',
    'Répartis les aliments riches en protéines (œufs, poisson, viande, '
        'laitages, légumineuses, tofu) sur tes repas de la journée plutôt que '
        'de tout concentrer sur un seul.',
  ),
  WellnessTip(
    'water',
    'Boire régulièrement',
    'Bois de l’eau tout au long de la journée, un peu plus quand il fait '
        'chaud ou quand la séance est longue. Garde une gourde à portée de '
        'main pendant l’entraînement.',
  ),
  WellnessTip(
    'sleep',
    'Dormir suffisamment',
    'Le sommeil fait partie de l’entraînement : des horaires réguliers et '
        'des nuits complètes aident à récupérer. Après une mauvaise nuit, une '
        'séance plus légère reste une bonne séance.',
  ),
  WellnessTip(
    'regularity',
    'La régularité avant l’intensité',
    'Mieux vaut des séances raisonnables chaque semaine que des séances '
        'épuisantes de temps en temps. Les jours de repos du programme sont '
        'prévus pour récupérer : respecte-les.',
  ),
  WellnessTip(
    'food',
    'Manger varié',
    'Fruits, légumes, féculents et protéines : une alimentation variée suffit '
        'pour s’entraîner. Kalis Track ne calcule ni calories ni '
        'macronutriments et ne fixe aucun objectif de poids.',
  ),
  WellnessTip(
    'listen',
    'Écouter ses sensations',
    'Fatigue inhabituelle, courbatures qui durent, envie qui baisse : allège '
        'la séance ou prends un jour de repos. Tu peux le signaler à Koach en '
        'fin de séance (sommeil, forme), c’est facultatif.',
  ),
];

// ------------------------------------------------ KT-073 douleur et alertes

/// Signes qui imposent d'arrêter l'effort (liste fermée, sans diagnostic).
const kAlertSignals = <String>[
  'douleur ou gêne dans la poitrine',
  'malaise, étourdissement ou vision trouble',
  'essoufflement anormal, hors de proportion avec l’effort',
  'douleur qui irradie (bras, épaule, mâchoire, dos, jambe)',
  'palpitations inhabituelles',
];

const kAlertAdvice =
    'Arrête l’effort immédiatement et ne reprends pas la séance. Si le signe '
    'est intense ou ne passe pas au repos, appelle le 15 (ou le 112). Dans '
    'tous les cas, parles-en à un médecin avant de t’entraîner de nouveau.';

const kPainAdvice =
    'Une douleur pendant un exercice n’est pas un signal à ignorer. Note-la '
    'de 0 à 10 dans le bilan Koach : au-dessus de 3/10, aucune hausse de '
    'charge n’est proposée ; deux séances de suite, un allègement de 20 % '
    'est proposé sur les mouvements principaux ; tu peux aussi échanger l’exercice (Options de '
    'séance → Échanger un exercice). Kalis Track ne dit pas d’où vient une '
    'douleur.';

/// Seuil du renvoi vers un professionnel : douleur > 3/10 notée sur plus de
/// 2 séances de suite pour un même mouvement.
const kPainReferralThreshold = 3;
const kPainReferralSessions = 3;

const kPainReferral =
    'Cette douleur dure depuis plus de 2 séances : demande l’avis d’un '
    'professionnel de santé (médecin, kinésithérapeute) avant de continuer ce '
    'mouvement.';

/// Nombre de séances consécutives, les plus récentes, où la douleur notée
/// dépasse [kPainReferralThreshold]. [chronological] : valeurs notées pour un
/// mouvement, de la plus ancienne à la plus récente (séances sans note
/// exclues en amont).
int painStreak(List<int> chronological) {
  var n = 0;
  for (var i = chronological.length - 1; i >= 0; i--) {
    if (chronological[i] > kPainReferralThreshold) {
      n++;
    } else {
      break;
    }
  }
  return n;
}

bool painNeedsReferral(List<int> chronological) =>
    painStreak(chronological) >= kPainReferralSessions;

/// Situation particulière → mode prudent (L8) et avis médical conseillé,
/// sans programme spécifique.
class SpecialSituation {
  final String id, title, text;

  /// Raison du mode prudent (L8, `evaluateCaution`) qui la couvre.
  final String cautionReason;
  const SpecialSituation(this.id, this.title, this.text, this.cautionReason);
}

const kSpecialSituations = <SpecialSituation>[
  SpecialSituation(
    'pregnancy',
    'Grossesse ou accouchement récent',
    'Réponds « oui » à la question du questionnaire de santé : le mode prudent '
        's’applique. Demande l’avis de ton médecin ou de ta sage-femme avant '
        'de continuer. Kalis Track ne propose pas de programme de grossesse.',
    'pregnancy',
  ),
  SpecialSituation(
    'heart',
    'Tension artérielle ou problème de cœur',
    'Réponds « oui » à la première question du questionnaire : le mode '
        'prudent s’applique (pas de test maximal, charges limitées). Demande '
        'l’avis de ton médecin avant de t’entraîner intensément.',
    'heart',
  ),
  SpecialSituation(
    'age65',
    '65 ans et plus',
    'Le mode prudent s’applique d’office selon ton année de naissance. Un avis '
        'médical est conseillé avant de reprendre un entraînement intense.',
    'age65',
  ),
  SpecialSituation(
    'injury',
    'Reprise après une blessure ou une longue pause',
    'Déclare ta gêne (zone et intensité) dans Réglages → Programme → Profil : '
        'au-dessus de 3/10, le mode prudent s’applique. Reprends '
        'progressivement ; si un professionnel te suit, suis son avis.',
    'discomfort',
  ),
];

// ------------------------------------------------ KT-078 retour de test

/// Scénarios du test fermé (identifiant, profil, libellé).
const kTestScenarios = <(String, String, String)>[
  ('onboarding', 'tous', 'Démarrage : profil, santé, premier programme'),
  ('first_session', 'débutant', 'Première séance guidée'),
  ('week', 'intermédiaire', 'Une semaine complète avec Koach'),
  ('heavy', 'expert', 'Séance lourde, estimations et propositions'),
  ('caution', 'senior', 'Mode prudent (65 ans et plus)'),
  ('pain', 'tous', 'Douleur notée, allègement, échange d’exercice'),
  ('backup', 'tous', 'Export puis import d’une sauvegarde'),
  ('other', 'tous', 'Autre'),
];

/// Formulaire de retour, rempli localement. Rien n'est envoyé par
/// l'application : le texte est partagé volontairement (menu Android).
class FeedbackDraft {
  String scenario = 'other';
  int? rating; // 1-5, facultatif
  String worked = '', blocked = '', other = '';

  /// Informations techniques ajoutées seulement si cochées.
  bool includeVersion = true;
  bool includeLevel = false;
  bool includeCaution = false;

  bool get isEmpty =>
      rating == null &&
      worked.trim().isEmpty &&
      blocked.trim().isEmpty &&
      other.trim().isEmpty;
}

/// Texte partagé : uniquement les champs remplis et les informations
/// cochées. Aucune donnée de santé, d'historique ou d'identification.
String feedbackText(
  FeedbackDraft d, {
  required String appVersion,
  String? level,
  bool? caution,
}) {
  String clip(String s) {
    final t = s.trim();
    return t.length > 2000 ? t.substring(0, 2000) : t;
  }

  final scenario = kTestScenarios.firstWhere(
    (s) => s.$1 == d.scenario,
    orElse: () => kTestScenarios.last,
  );
  final lines = <String>['Retour de test — Kalis Track'];
  lines.add('Scénario : ${scenario.$3}');
  if (d.rating != null) lines.add('Note : ${d.rating}/5');
  if (d.worked.trim().isNotEmpty) {
    lines.add('Ce qui marche : ${clip(d.worked)}');
  }
  if (d.blocked.trim().isNotEmpty) {
    lines.add('Ce qui bloque : ${clip(d.blocked)}');
  }
  if (d.other.trim().isNotEmpty) lines.add('Autre : ${clip(d.other)}');
  if (d.includeVersion) lines.add('Version : $appVersion');
  if (d.includeLevel && level != null) lines.add('Niveau : $level');
  if (d.includeCaution && caution != null) {
    lines.add('Mode prudent : ${caution ? 'oui' : 'non'}');
  }
  return lines.join('\n');
}
