/// Bibliothèque des messages de Koach en français.
///
/// Règles (L13, D6.4) : tutoiement, phrases courtes, aucun jargon non
/// expliqué, aucune allégation médicale, aucune promesse de résultat. Les
/// paramètres s'écrivent `{nom}` et sont fournis déjà mis en forme par
/// l'application. Une bulle tient en [koachBubbleMaxChars] caractères, une
/// explication « Pourquoi ? » en [koachWhyMaxChars] (paramètres compris,
/// contrôlé par les tests avec des valeurs longues).
library;

/// Longueur maximale d'une bulle, paramètres remplacés.
const int koachBubbleMaxChars = 120;

/// Longueur maximale d'une explication « Pourquoi ? ».
const int koachWhyMaxChars = 240;

/// Longueur maximale d'un libellé d'action.
const int koachActionMaxChars = 24;

/// Messages, par clé.
// Table de données : une entrée par ligne, non reformatée.
// dart format off
const Map<String, String> koachMessagesFr = <String, String>{
  // Accueil.
  'welcome.1': 'Salut, moi c’est Koach ! Je t’accompagne à chaque séance.',
  'welcome.2': 'Bienvenue ! Je suis Koach, je vais construire ton programme avec toi.',

  // Profil.
  'profile.start.1': 'On commence par ton profil : quelques questions, et je m’occupe du reste.',
  'profile.start.2': 'Parle-moi un peu de toi : ton niveau, ton matériel, ton temps.',
  'profile.step.1': 'Plus que {remaining} questions.',
  'profile.step.2': 'Encore {remaining} questions et on passe à ton programme.',
  'profile.step.3': 'Bien noté. Il reste {remaining} questions.',
  'profile.done.1': 'Profil terminé, merci ! Je peux préparer ton programme.',
  'profile.done.2': 'C’est tout bon pour ton profil. Passons au programme !',
  'profile.update.1': 'Ton profil n’est plus à jour ({field}). On le corrige ensemble ?',
  'profile.update.2': 'Petit souci : {field} a changé ? Mets ton profil à jour pour que je suive.',

  // Programme.
  'program.generating.1': 'Je prépare ton programme, une seconde…',
  'program.generating.2': 'Je compose tes séances avec ce que tu m’as dit…',
  'program.draft.1': 'Voici une première version sur {weeks} semaines. Relis-la, change ce qui ne te va pas.',
  'program.draft.2': 'Première proposition : {weeks} semaines. Dis-moi ce qui ne te convient pas.',
  'program.ready.1': 'Ton programme de {weeks} semaines est prêt. On s’y met ?',
  'program.ready.2': 'C’est prêt : {weeks} semaines rien que pour toi. Première séance quand tu veux !',

  // Revue.
  'review.intro.1': 'Ici, tu peux tout ajuster : exercices, jours, durée des séances.',
  'review.intro.2': 'Passe en revue ton programme. Touche un élément pour le changer.',
  'review.applied.1': 'C’est noté, j’ai mis le programme à jour.',
  'review.applied.2': 'Modification faite. Tu peux l’annuler si besoin.',

  // Propositions (sans code de raison connu).
  'proposal.generic.1': 'J’ai une proposition pour ta séance. Tu veux voir ?',
  'proposal.generic.2': 'D’après tes dernières séances, je te propose un petit ajustement.',
  'proposal.accepted.1': 'Parfait, c’est appliqué !',
  'proposal.accepted.2': 'Ça marche, j’ai mis à jour ta séance.',
  'proposal.declined.1': 'Pas de souci, on garde le plan tel quel.',
  'proposal.declined.2': 'D’accord, rien ne change.',
  'applied.generic.1': 'J’ai ajusté ta séance d’après tes dernières séries.',
  'applied.generic.2': 'Petit ajustement de ta séance, d’après tes derniers retours.',

  // Raisons du moteur : propositions, changements appliqués.
  'reason.load_increased.proposal.1': 'Tu as de la marge sur {exercise} : on monte un peu la charge ?',
  'reason.load_increased.proposal.2': 'Je te propose d’augmenter un peu la charge sur {exercise}.',
  'reason.load_increased.applied.1': 'J’ai augmenté un peu la charge sur {exercise}.',
  'reason.volume_reduced.proposal.1': 'Je te propose une série de moins sur {exercise} aujourd’hui.',
  'reason.volume_reduced.proposal.2': 'On allège {exercise} d’une série ?',
  'reason.volume_reduced.applied.1': 'J’ai retiré une série sur {exercise}.',
  'reason.exercise_replaced.proposal.1': 'On remplace {exercise} par {replacement} ?',
  'reason.exercise_replaced.proposal.2': 'Je te propose {replacement} à la place de {exercise}.',
  'reason.exercise_replaced.applied.1': 'J’ai remplacé {exercise} par {replacement}.',
  'reason.session_shortened.proposal.1': 'Pas beaucoup de temps ? On fait une version de {minutes} min.',
  'reason.session_shortened.proposal.2': 'Je te propose une séance courte : {minutes} min, l’essentiel.',
  'reason.session_shortened.applied.1': 'Séance raccourcie à {minutes} min : on garde l’essentiel.',
  'reason.deload.proposal.1': 'Cette semaine, je te propose de lever le pied : semaine allégée.',
  'reason.deload.proposal.2': 'Et si on faisait une semaine plus légère ?',
  'reason.deload.applied.1': 'Semaine allégée : moins de séries, même régularité.',
  'reason.calibration.proposal.1': 'Première fois sur {exercise} : on cherche ta bonne charge ensemble ?',
  'reason.calibration.applied.1': 'Sur {exercise}, les premières séries servent à trouver ta charge.',

  // Bilan santé.
  'health.intro.1': 'Avant de commencer : comment tu te sens aujourd’hui ?',
  'health.intro.2': 'Petit bilan rapide avant la séance. Ça prend dix secondes.',
  'health.good.1': 'Super, on y va !',
  'health.good.2': 'Top. En route pour la séance !',
  'health.discomfort.1': 'Merci de me le dire. J’en tiens compte pour la séance.',
  'health.discomfort.2': 'Noté. Va à ton rythme et écoute tes sensations.',
  'health.pain.1': 'Douleur signalée : arrête ce qui fait mal. Si ça dure, demande l’avis d’un professionnel de santé.',
  'health.pain.2': 'Tu as mal : on ne force pas. Si ça persiste, parles-en à un professionnel de santé.',

  // Fin de séance.
  'session.good.1': 'Séance terminée, bien joué !',
  'session.good.2': 'Et une séance de plus. Beau travail !',
  'session.good.3': 'C’est fait ! Pense à bien récupérer.',
  'session.hard.1': 'Séance difficile, mais tu l’as terminée. Respect.',
  'session.hard.2': 'C’était dur aujourd’hui. J’en tiens compte pour la suite.',
  'session.partial.1': 'Séance écourtée : {done} séries sur {planned}. C’est déjà ça.',
  'session.partial.2': '{done} séries sur {planned} aujourd’hui. On reprend la prochaine fois.',

  // Record.
  'record.1': 'Nouveau record sur {exercise} : {value} !',
  'record.2': 'Record battu sur {exercise} : {value}. Bravo !',
  'record.3': '{value} sur {exercise}, c’est ton meilleur résultat !',

  // Erreur, annulation.
  'error.1': 'Oups, ça n’a pas marché. Réessaie dans un instant.',
  'error.2': 'Petit couac de mon côté. On réessaie ?',
  'cancelled.1': 'C’est annulé, rien n’a changé.',
  'cancelled.2': 'Annulé. Tout est comme avant.',

  // Session de test.
  'dev.enter.1': 'Session de test : tout ce que tu fais ici reste à part de tes vraies données.',
  'dev.enter.2': 'Mode test activé. Fais comme un nouvel utilisateur, rien ne touche ta session.',
  'dev.exit.1': 'Retour à ta session personnelle.',
  'dev.exit.2': 'Fin du test, te revoilà chez toi.',

  // Nouveauté.
  'feature.1': 'Nouveau : {feature}. Je te montre ?',
  'feature.2': 'Il y a du neuf : {feature}. Tu veux un tour rapide ?',

  // Explications « Pourquoi ? ».
  'why.profile_update': 'Ton programme dépend de ton profil. S’il n’est plus à jour, mes propositions risquent de tomber à côté.',
  'why.program_draft': 'Je construis le programme en deux temps : une première version que tu relis, puis la version finale avec tes retours.',
  'why.review': 'La revue te permet de changer ce qui ne te convient pas avant de commencer : exercices, jours et durée des séances.',
  'why.health_check': 'Quelques questions avant la séance pour l’adapter à ta forme du jour. Ce n’est pas un avis médical.',
  'why.health_pain': 'Une douleur est un signal à respecter. Je ne pose aucun diagnostic : en cas de doute, demande l’avis d’un professionnel de santé.',
  'why.dev_session': 'La session de test sert à essayer l’application comme un nouvel utilisateur, sans toucher à tes données.',
  'why.feature': 'Je présente chaque nouveauté une seule fois. Tu pourras la retrouver ensuite dans les réglages.',
  'why.generic_change': 'Ton programme s’ajuste à tes dernières séances : la difficulté que tu notes avec les flammes me sert de repère.',
  'why.load_increased': 'Tes dernières séries étaient en dessous de la difficulté visée : tu avais encore de la marge. On monte par petites étapes pour garder une bonne exécution.',
  'why.volume_reduced': 'Tes séries ont été plus dures que prévu. Un peu moins de volume aide à garder des répétitions de qualité.',
  'why.exercise_replaced': 'Cet exercice ne colle pas à ta situation du moment (matériel, gêne ou niveau). Le remplaçant fait travailler les mêmes muscles.',
  'why.session_shortened': 'Tu as peu de temps ou d’énergie aujourd’hui. Une séance courte et bien faite vaut mieux qu’une séance sautée.',
  'why.deload': 'Après plusieurs semaines chargées, une semaine plus légère permet de récupérer avant de repartir.',
  'why.calibration': 'Je n’ai pas encore de données sur cet exercice. Les premières séries servent à trouver une charge adaptée à ton niveau.',

  // Libellés des actions.
  'action.accept': 'Accepter',
  'action.decline': 'Non merci',
  'action.why': 'Pourquoi ?',
  'action.later': 'Plus tard',
  'action.edit_profile': 'Modifier mon profil',
  'action.retry': 'Réessayer',
  'action.undo': 'Annuler',
  'action.start': 'C’est parti',
  'action.details': 'Voir',
  'action.continue': 'Continuer',
  'action.ok': 'OK',
};
// dart format on
