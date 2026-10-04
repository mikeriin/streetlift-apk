# Contexte de lancement des lots CP

Le texte ajouté au lancement d'une tâche n'arrive pas toujours dans la session (constat du 03/10/2026). La conversation de pilotage écrit donc ici, avant chaque lancement, le contexte du lot (reprise, consignes ponctuelles). **Jamais la clé des références** (dépôt public) : elle est dans le document privé `claude/CLE_REFERENCES_CP.md` du projet claude.ai.

## CP1 (lancé le 03/10/2026 à 20:25 UTC, tâche « Fable 5.1, effort maximal, moteurs »)

- Cible C7 (notes proches de 10, deux jurys, jusqu'à 10 boucles guidées par recherche approfondie) : lis `DECISIONS_CP.md` C6 et C7.
- Points de départ : `packages/kalis_bench/docs/BASELINE_0_1.md` (panel : minimum 3, moyenne 4,9 ; 117 violations) et `pipeline/cp/livraisons/RELECTURE_DOCUMENTEE_M0.md` (relecture documentée : moyenne 3,8 ; mêmes notes dans la collection `notes` de la page de relecture).
- Défaut transversal à corriger en premier : % affichés ≠ charges réelles des mouvements lestés (traction +17,5 kg à 80 kg = 70 % du 1RM total, pas 77 %) ; échelle d'effort fausse (« 4 rép. en réserve » affiché 3/10).
- Références privées sur `cp-references` : `references.tar.gpg`, `analyse_CR.tar.gpg`, `transcriptions_pilotage.tar.gpg` (A3 en entier, F3 pages 1-19).
- Si la part Fable s'épuise : la conversation de pilotage reprend le lot sur la tâche Opus moteurs depuis `cp-sauvegardes/CP1` (garde SAUVEGARDE.md à jour).

## CA1 (lancé le 04/10/2026 vers 08:55 UTC, tâche « Fable 5.1, effort maximal, moteurs »)

- Tu es le seul lot « à faire » : CA1 (`prompts/CA1.txt`). CP1 est livré (`kalis_plan` 0.2.0, `kalis_core` 0.4.1, `kalis_bench` 0.1.1, `moteurs` d0d60018) : lis `livraisons/LIVRAISON_CP1.md` (parties 6 et 7) et `DECISIONS_CP.md` (section CP1).
- **Cible en vigueur : C7.5** (pas C7.1) : panel ≥ 9 pour chaque école et chaque profil street, sur les trajectoires, 0 violation de sécurité ; plus de seuil de moyenne. Relecture documentée : faite par tes sous-agents, écrite dans ta manche de la page de relecture, traitée, **sans seuil** (C7.6). Jusqu'à 10 boucles (C7.2) ; arrêt après deux boucles sans gain sur le nombre de couples à 9 et le minimum du panel.
- Programmes d'entrée : `kalis_plan` 0.2.0 existe (`etiquettes/kalis_plan-v0.2.0`) : prends ses programmes street pour les 17 profils, plus des programmes de test pour les techniques qu'il n'écrit pas. Ne touche pas `packages/kalis_plan` (le croisement réel est CX).
- Notes de la page de relecture : manches 0 et 1, auteur `relecture-documentee` (C6) ; lis celles qui touchent l'évolution (repères, tests, bloc suivant d'après le résultat réel, reprise) et traite-les.
- Clé des références : dans le document privé du projet ; passe-la à gpg par un fichier `/tmp` en mode 600 (`--passphrase-file`), **jamais sur une ligne de commande** (C7.8, écart de CP1).
- Recherche web : quota d'environ 200 recherches par session (CP1 l'a épuisé) ; répartis-les entre les boucles, WebFetch sur des adresses déjà repérées ensuite.
- Contrôle : `claude/ci-cp-b`. Sauvegardes : `cp-sauvegardes/CA1`. Si la part Fable s'épuise : la conversation de pilotage reprend le lot sur la tâche Opus moteurs depuis `cp-sauvegardes/CA1` (garde SAUVEGARDE.md à jour).

## CX (lancé le 04/10/2026 vers 17:20 UTC, tâche « Opus 5.5, effort maximal, moteurs »)

- Tu es le seul lot « à faire » : CX (`prompts/CX.txt`). **Modèle : Opus** (C5.1 ; le prompt du lot dit Fable, C5.1 fait foi). Contrôle : `claude/ci-cp-a`. Sauvegardes : `cp-sauvegardes/CX`.
- **Prérequis « le propriétaire a décidé de continuer »** : CP1 et CA1 sont « livré — cible non atteinte » ; la décision de continuer est `DECISIONS_CP.md` **C7.9** (prise par la conversation de pilotage sous les délégations du propriétaire, annoncée sans objection). Elle remplit ce prérequis : ne t'arrête pas « en attente du propriétaire » pour cette raison.
- Bases : `moteurs` ccde1ad2 — `kalis_plan` 0.2.0, `kalis_adapt` 0.2.0, `kalis_bench` 0.1.2, `kalis_core` 0.4.1. Lis `livraisons/LIVRAISON_CP1.md` (parties 6 et 7), `livraisons/LIVRAISON_CA1.md` (parties 3, 4, 7 et 8) et les sections CP1, CA1 et C7 de `DECISIONS_CP.md`.
- **Cible : C7.5 sur les saisons croisées** (programme écrit **et** conduite par `kalis_adapt`) : panel ≥ 9 pour chaque école et chaque profil street, 0 violation de sécurité. Jusqu'à 10 boucles (C7.2, le prompt dit 6) ; arrêt après deux boucles sans gain sur le nombre de couples à 9 et le minimum. Incertitude du panel : renote une fois un couple isolé sous 9 avant de conclure (C7.9.4).
- **À corriger dans `kalis_plan` (0.2.x), par ordre d'effet** (CA1 partie 8 point 2, CP1 partie 7) :
  1. réécrire le bloc suivant d'après le résultat réel du test, repères compris (`nextBlock` nourri par les résumés d'adaptation) ;
  2. échelle de poussée du débutant écrite comme une échelle du contrat (genoux → mains surélevées → sol) ; pompe classique dosée sur le maximum mesuré ;
  3. figures : seuil d'ouverture d'une étape à 70–75 % du maximum, critère de passage mesurable, tirage de force, dynamique et excentriques au levier visé, tenues à 75–85 % une séance sur deux ;
  4. séries allégées à −5 / −8 % ; trois séries et plus à 85 % et plus en intensification et réalisation ;
  5. bloc de réalisation spécifique (au maximum de répétitions pour le sets & reps) ; format de l'épreuve de sets & reps, catégorie de poids et pesée en streetlifting (profil) ;
  6. pas de tractions deux jours de suite ; hausses hebdomadaires de 10 à 15 % ; charge « à calibrer » chiffrée quand le 1RM est connu ; temps de séance disponible employé au travail spécifique ;
  7. test de descente (négative) sur un exercice compté en secondes ; catalogue `kalis_core` : matériel de l'appui renversé au mur et de la pompe mains surélevées (PIPELINE_CP.md §0 pour toucher `kalis_core`).
- **C7.7** : `street_08_avance_sets_reps_competition` et `street_14_parc_sans_lest` (calisthénie, 8 en CP1) doivent être à 9 à la livraison.
- Page de relecture : manches 0, 1 et 2, toutes de la relecture documentée (aucune note du propriétaire à ce jour) ; traite les remarques qui relèvent du programme ou de l'interface plan ↔ catalogue. Ta manche « street complet (CX, <date>) » sera relue par la relecture documentée indépendante du pilotage avant la validation du propriétaire (C7.6) : écris-y aussi les notes de ta propre relecture documentée.
- Hors CX (à laisser à CA2) : estimation moins prudente de `kalis_adapt`, passage d'un cran d'assistance, allures de course, constats restants de la relecture indépendante de CA1.
- Clé des références (non-ressemblance des programmes générés) : document privé du projet, passée à gpg par un fichier `/tmp` en mode 600, jamais sur une ligne de commande (C7.8). Quota d'environ 200 recherches web par session : répartis-les.
