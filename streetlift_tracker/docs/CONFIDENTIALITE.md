# Kalis Track 3.1.0 — Cartographie des données et politique de confidentialité (préparatoire)

**Document préparatoire, 26 septembre 2026 (L8, KT-042).** Il complète `docs/CONFIDENTIALITE_KOACH.md` (données de Koach). Il ne tranche pas la qualification juridique : points à valider au §5.

## 1. Principes

- Application gratuite, sans compte, sans publicité, sans achat réel, sans serveur, sans outil d'analyse d'usage ni SDK de suivi. Tous les calculs se font sur le téléphone.
- Réservée aux adultes (18 ans et plus, déclaration de l'année de naissance). Un mineur est refusé sans qu'aucune donnée soit enregistrée.
- Minimisation : ni nom, ni adresse électronique, ni sexe, ni taille, ni date de naissance complète, ni localisation.

## 2. Cartographie

| Donnée | Quand | Finalité | Nature | Où |
| --- | --- | --- | --- | --- |
| Année de naissance | Démarrage | Contrôle 18+, mode prudent ≥ 65 ans | Identification indirecte faible | Document local `kalis_state_v3`, section `profile` |
| Objectifs, épreuves, pondération | Démarrage, Profil | Adapter le programme | Préférence | idem |
| Jours, durée, lieux, matériel, lieu par jour | Démarrage, Profil | idem | Préférence | idem |
| Repère de niveau (tranches pompes, tractions) | Démarrage | Point de départ | Donnée d'entraînement | idem |
| Ancienneté, exercices aimés/détestés, métier physique, motivation | Questions progressives (facultatives) | Adapter le programme | Préférence | idem |
| Mode et ton de Koach | Démarrage, Profil | Présentation des conseils | Préférence | idem |
| Poids (pesées datées) | Démarrage (facultatif), Pesées | Calcul poids du corps + lest | **Donnée corporelle, à qualifier** | Section `koach` (L7) |
| **Réponses au questionnaire de santé** (8 oui/non) | Démarrage, après consentement | Mode prudent | **Donnée de santé** | Section `profile.health` |
| **Accord du médecin déclaré** (date) | Profil | Lever le mode prudent | **Donnée de santé** | idem |
| **Gênes et limitations** (zone, 0-10, depuis) | Démarrage, Profil, après consentement | Mode prudent | **Donnée de santé** | idem |
| **Sommeil habituel, stress** | Questions progressives, après consentement | Adapter l'entraînement | **Donnée de santé potentielle** | Section `profile.fields` |
| Consentement (état, date) | Démarrage, Profil | Trace du choix | Preuve | Section `profile.health` |
| Historique « profil modifié » | À chaque modification | Régénération future (L10), transparence | Donnée d'usage | Section `profile.events` |
| Journal, références, WOD, réglages, Koach | Voir `SUIVI_PROJET.md` et `docs/CONFIDENTIALITE_KOACH.md` | | | |

## 3. Consentement et droits

- Information affichée **avant** toute question de santé ; choix explicite « J'accepte / Je refuse ». Refus : l'application fonctionne en mode prudent, aucune donnée de santé n'est enregistrée.
- Retrait à tout moment (Réglages → Profil → « Retirer mon accord ») : les données de santé sont effacées immédiatement ; le choix reste daté.
- « Supprimer mes réponses de santé » : efface les réponses sans changer le consentement.
- Accès et portabilité : l'export de sauvegarde contient tout le profil (fichier **non chiffré**, rangé où l'utilisateur le choisit).
- Effacement : Réglages → Zone sensible → « Supprimer les données de l'application » efface aussi le profil.

## 4. Conservation et transferts

Jusqu'à suppression par l'utilisateur. Aucun envoi par l'application. La sauvegarde Android (Google), si elle est activée sur le téléphone, peut copier les données de l'application, profil compris (décision KT-016) ; l'application ne peut ni la déclencher ni l'effacer.

## 5. À faire valider (non tranché)

1. Qualification au sens de l'art. 9 RGPD des réponses de santé, gênes, sommeil, stress et du poids, dans un usage local sans éditeur destinataire.
2. Suffisance du consentement recueilli (information, choix explicite, trace datée locale) et rôle de l'éditeur (fiche Google Play « Sécurité des données »).
3. Exclusion éventuelle de la section `profile.health` de la sauvegarde Android (`dataExtractionRules`).
4. Avertissement spécifique à l'export lorsqu'il contient des données de santé.
5. Contrôle d'âge par déclaration seule.
6. Relecture des textes d'information et du questionnaire (formulation propre, non reprise du PAR-Q+ faute de licence).
