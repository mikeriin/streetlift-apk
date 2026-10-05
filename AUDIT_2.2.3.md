# Kalis Track 2.2.3 — Chrono de fin d'exercice et palette appliquée

Version **2.2.3+46**. Correctifs et application complète de la palette
#6B0C0C · #A61717 · #121212 · #1E1E1E · #F4F4F4 · #8A8A8A · #388E3C.

## Bugs corrigés

- **Chrono absent après la dernière série** (signalé). `restAfterSet` retournait
  `null` dès que `i >= total - 1` : le repos n'était jamais lancé en fin
  d'exercice, et la branche « repos final » des myo-reps était inaccessible.
  Le repos se lance désormais après chaque série validée, dernière comprise ;
  myo-reps : micro-repos entre séries, repos complet en fin (repos par défaut
  quand le repos de l'exercice est « 10 s intra », sinon le repos indiqué). La
  puce « Repos final » affiche la valeur réellement lancée.
- Boutons de mode (EMOM, AMRAP, intervalles, durée, tenue) : texte `onAccent`
  (noir en sombre) sur fond coloré → illisible dès que le fond passe en
  bordeaux. Texte blanc cassé imposé.
- Boutons de suppression : fond `danger` (#F09B9B en sombre) avec texte blanc,
  contraste 1,7:1 → fond rouge d'action, texte blanc cassé (7,6:1).
- `stats_history` utilisait `headlineMedium`, non défini par le thème.
- Réglages → Thème : le sous-titre affichait « Système » quel que soit le
  choix ; il décrit maintenant le thème sélectionné.
- Sous-pages Réglages : titre affiché deux fois (barre + page) ; la barre
  porte le surtitre « RÉGLAGES », la page garde son titre, comme les onglets.
- `heat()` (carte musculaire) annonçait une rampe jaune → rouge et produisait
  du gris → blanc en sombre.

## Palette : rôles réellement appliqués

En 2.2.2, l'accent sombre (`steel`, ~60 emplacements : icônes, onglets STATS,
« Reprendre », « Tout voir », bordures de focus, `ColorScheme.primary`) valait
#F4F4F4 ; le vert servait de couleur de catégorie (lift principal, badge AMRAP,
icônes « Lancer ») et la piste des jauges (#8A8A8A) était plus claire que leur
remplissage bordeaux.

| Rôle | Couleur | Emplacements |
|---|---|---|
| Dominante | #6B0C0C | boutons pleins (Démarrer, Suivant, Terminer, Lancer, Nouvelle séance, Continuer, Valider), cartes de marque (jour actuel, niveau), base des jauges |
| Action / actif | #A61717 | navigation, segments, onglets STATS (indicateur), curseur de semaine, points d'étape de séance, branche de l'arbre, bouton Acheter, intra-cluster, médailles de record, contour d'alerte et remplissage « effort » du chrono, suppression |
| Accent texte / icônes | #E85959 sombre · #6B0C0C clair | icônes de menu et de statistiques, lift principal, records, filtres et puces sélectionnés, boutons texte, focus des champs, libellé « repos » du chrono |
| Validation | #388E3C (#64AA67 sombre · #2C7230 clair) | séries cochées, séances effectuées, badges obtenus, cibles atteintes, WOD acquis, « Terminer » WOD, chrono terminé |
| Texte | #F4F4F4 · #8A8A8A | titres, chiffres du chrono, données ; descriptions et labels |
| Jauges | #6B0C0C → #A61717 sur piste #333333 | niveau, programme, force, endurance, défis, palier suivant, repos du chrono ; graphique d'activité inchangé |

#6B0C0C et #A61717 restent sous 3:1 sur #121212 / #1E1E1E : ils ne servent
jamais de texte sur fond sombre. #E85959 est la teinte de #A61717 la plus
proche qui atteint 4,5:1 sur les deux surfaces (4,77:1 sur #1E1E1E, 5,36:1 sur
#121212). Carte musculaire : rampe bordeaux → rouge (accent en sombre).

Nouveau composant `KProgressBar` (ui.dart) : piste neutre, remplissage en
dégradé dont le bout est toujours le rouge vif, ou couleur unie (vert de
validation, blanc sur bordeaux).

## Vérification

Environnement de livraison sans SDK Flutter ni accès à pub.dev : **aucune
analyse, compilation, test ni capture n'a pu être exécuté ici.** Le workflow
GitHub exécute `flutter analyze` et `flutter test` avant de compiler l'APK ;
en cas d'échec, le journal du workflow indique le fichier concerné.

Contrôles effectués localement :
- Contraste WCAG recalculé pour chaque couple texte / surface asserté par
  `motion_test.dart` (minimum 4,77:1 ; test étendu au blanc sur rouge d'action,
  `onAccent` sur vert, bout de jauge sur piste).
- Rendu de la teinte musculaire simulé sur les masques PNG (#A61717 et #E85959).
- Équilibre des parenthèses, crochets et accolades des 20 fichiers modifiés.
- Tests ajustés : `training_estimate_test` (repos après la dernière série :
  150 s), `store_test` (myo-reps perso : 15 s puis 90 s), `level_fill_test`
  (`KProgressBar`), `motion_test` (nouveaux rôles).

Captures : celles de la 2.2.2 ne reflètent plus la palette ; le test
`visual_capture_test.dart` écrit désormais dans `validation/2.2.3` et doit
être relancé avec `--dart-define=KALIS_CAPTURE=true` pour les régénérer.

## Inchangé

Programme, calculs de charge, journal, XP, crédits, WOD, notifications,
signature Android, identifiant d'application, dépendances verrouillées.
