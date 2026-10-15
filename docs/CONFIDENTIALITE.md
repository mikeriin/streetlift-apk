# Kalis Track 4.3.0 — Cartographie finale des données et confidentialité

**27 septembre 2026 (L13, KT-075), remplace la version préparatoire 3.1.0 (L8).** Complète `docs/CONFIDENTIALITE_KOACH.md` (données de Koach). Politique destinée aux utilisateurs : `assets/legal/confidentialite.md` (affichée dans Réglages → À propos → Politique de confidentialité, publiable telle quelle ; **URL publique à fournir par le propriétaire**, jamais inventée). Les points de qualification juridique restent à valider (§6).

## 1. Principes

- Application gratuite, sans compte, sans publicité, sans achat réel, sans serveur, sans outil de mesure d'audience ni SDK de suivi. Tous les calculs se font sur le téléphone.
- Le manifeste principal ne déclare pas la permission `INTERNET` (permissions : notifications, alarmes exactes, redémarrage, vibration). Les dépendances (`shared_preferences`, `wakelock_plus`, `audioplayers` — sons locaux —, `flutter_local_notifications`, `timezone`) n'envoient aucune donnée.
- Réservée aux 18 ans et plus : refus au démarrage et en modification (L8), blocage d'un profil importé plus jeune (L13).
- Minimisation : ni nom, ni adresse électronique, ni sexe, ni taille, ni date de naissance complète, ni localisation, ni identifiant publicitaire.

## 2. Cartographie

| Donnée | Saisie | Finalité | Nature | Stockage | Export | Sauvegarde Android | Transmise |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Année de naissance | Démarrage, Profil | 18+, mode prudent ≥ 65 ans | Identification indirecte faible | `profile.fields` | Oui | Oui (si activée) | Non |
| Objectifs, jours, durée, lieux, matériel, repère, préférences, mode, ton | Démarrage, Profil, questions progressives | Programme personnalisé | Préférence | `profile.fields` | Oui | Oui | Non |
| Historique « profil modifié » | Automatique | Régénération, transparence | Usage | `profile.events` | Oui | Oui | Non |
| Programme, journal des séances, séries, records, WOD, crédits, XP, réglages | Utilisation | Suivi de l'entraînement | Entraînement | Document local `kalis_state_v3` | Oui | Oui | Non |
| Poids (pesées datées) | Démarrage (facultatif), Pesées | Charges au poids du corps | Donnée corporelle | Section `koach` | Oui | Oui | Non (partage : décoché par défaut) |
| **Questionnaire de santé** (8 oui/non), **gênes** (zone, 0-10, depuis), **accord du médecin** (date), **sommeil habituel, stress** | Après information et accord explicite | Mode prudent | **Santé** (art. 9) | `profile.health`, `profile.fields` | Oui | Oui | Non |
| **Sommeil, forme, douleur par séance** (Koach) | Bilan de fin de séance, facultatif | Propositions de charge, renvoi douleur | **Santé potentielle** | `koach.answers` | Oui | Oui | Non |
| Consentement (état, date) | Démarrage, Profil | Preuve du choix | Trace | `profile.health.consent` | Oui | Oui | Non |
| Adaptation au quotidien, pauses (vacances, maladie) | L11 | Ajuster les séances | Usage ; motif « maladie » = **santé potentielle** (motif seul, sans détail) | Section `adapt` | Oui | Oui | Non |
| Motivation, célébrations vues | L12 | Progression visible | Usage | Section `motiv` | Oui | Oui | Non |
| Image de progression | Partage volontaire | Partager | Choix de l'utilisateur (poids et santé exclus par défaut) | Fichier temporaire de l'application | — | Non | Seulement vers l'application choisie |
| Retour de test | Formulaire, jamais enregistré | Test fermé | Texte libre + version (cochée), repère et mode prudent (décochés) | Aucun | — | Non | Seulement vers l'application choisie |

## 3. Consentement et droits

- Information (`kHealthInfo`) affichée **avant** toute question de santé ; choix explicite « J'accepte / Je refuse » ; refus → mode prudent, aucune réponse de santé enregistrée (testé : refus → accord → retrait, contenu de l'export à chaque étape).
- Retrait (Réglages → Programme → Profil → « Retirer mon accord ») : réponses, gênes, accord du médecin, sommeil et stress effacés immédiatement ; le choix reste daté. « Supprimer mes réponses de santé » : même effacement sans changer l'accord. Réponses Koach par séance : Réglages → Koach → « Supprimer mes réponses aux questionnaires » (non liées à l'accord L8 : D-L13-05, à relire).
- Accès et portabilité : export de sauvegarde (fichier **non chiffré**, emplacement choisi ; le libellé signale les données de santé).
- Effacement complet : Réglages → Sauvegardes → « Supprimer les données de l'application » (testé : plus aucune donnée de santé dans l'état exporté).
- L'éditeur ne reçoit aucune donnée et ne peut donc ni y accéder ni les effacer ; réclamation possible auprès de la CNIL.

## 4. Conservation

Jusqu'à suppression par l'utilisateur (ou désinstallation). Aucune conservation chez l'éditeur. Copies hors de l'application : fichiers d'export (maîtrisés par l'utilisateur) et sauvegarde Android (Google), si activée sur le téléphone.

## 5. Sauvegarde Android (décision KT-016, option A, inchangée)

`allowBackup="true"`, sans règles d'exclusion : Android peut copier les données de l'application, profil et santé compris, dans le compte Google de l'utilisateur et les restaurer. L'application ne peut ni la déclencher, ni la lire, ni l'effacer. Expliqué dans l'application (Sauvegardes) et dans la politique.

## 6. À faire valider (juriste / DPO)

1. Qualification art. 9 RGPD des réponses de santé, gênes, sommeil, stress, douleur, poids et motif « maladie », dans un traitement purement local sans destinataire.
2. Rôle de l'éditeur (responsable de traitement ou non) quand rien ne lui est transmis ; suffisance du consentement (trace locale datée).
3. Exclusion éventuelle de `profile.health` et `koach.answers` de la sauvegarde Android (option B de KT-016).
4. Consentement pour les réponses Koach par séance (D-L13-05).
5. Contrôle d'âge par déclaration seule.
6. Relecture de la politique et des textes d'information.
