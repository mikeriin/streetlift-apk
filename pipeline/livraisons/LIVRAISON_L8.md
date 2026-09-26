# Livraison L8 — Kalis Track 3.1.0 (profil, démarrage court, questionnaire de santé)

**26 septembre 2026 — lot exécuté par le pipeline automatisé.** Tickets KT-038 à KT-043.

## 1. Publication

| Élément | Valeur |
| --- | --- |
| Base | 3.0.3+64 (L6), `main` `8e8f6d1` |
| ZIP publié | `streetlift_tracker_v33.zip`, 1 990 987 octets, 452 fichiers (4 941 496 octets extraits), SHA-256 `517f28af939476851125af74a479f046de7a3bd4e9d7e047ab4d60d3361be5c0`, racine `streetlift_tracker/`, contrôlé par `tools/package_release.py --check` |
| Commit `main` | `620752e` |
| Build signé | Run **n° 85** (id 36265833693) **réussi** le 26/09/2026 19:22-19:37 UTC : contrôle du ZIP et du workflow, formatage, analyse, tests Dart et Python, refus sans secrets, clé existante restaurée et contrôlée, APK et AAB signés avec le même numéro, artefacts vérifiés. Artefacts : `kalis-track-apk` (28 061 930 octets), `kalis-track-aab` (28 732 765), `kalis-track-validation` — https://github.com/mikeriin/streetlift-apk/actions/runs/36265833693 |
| Workflow `build-apk.yml` | Inchangé (copie du projet identique à `.github/workflows/`) |

## 2. Ce qui change pour toi

- Au premier lancement de 3.1.0 sur ton téléphone, l'écran **« Ton profil est pré-rempli »** s'affiche : objectifs repris de Koach (épreuves et date), lieux parc + salle, repère depuis tes maxima pompes et tractions, jours et durée estimés depuis ton historique. Indique ton année de naissance, réponds au questionnaire de santé (ou refuse), puis **« Confirmer mon profil »**. « Plus tard » est possible : l'application reste alors exactement 3.0.3.
- **Aucune date, valeur ni séance n'est modifiée** par la confirmation (vérifié sur un état 3.0.0 rempli de 40 semaines).
- Si tu réponds « oui » à une question, refuses le consentement ou déclares une gêne au-dessus de 3/10, le **mode prudent** s'applique : charges des 4 mouvements lestés/squat plafonnées à 80 % du 1RM, consignes « pas de test maximal » et « 3 répétitions en réserve ». « J'ai l'accord de mon médecin » (Réglages → Profil) le lève.
- Réglages → **Profil** : modifier, voir l'origine de chaque réponse, retirer ton accord santé (effacement).

## 3. Installation

1. **Avant** : Réglages → Sauvegardes → « Exporter une sauvegarde » (fichier gardé hors du téléphone).
2. Télécharger l'artefact `kalis-track-apk` du run ci-dessus ; installer **par-dessus** la version actuelle (même signature, pas de désinstallation).
3. Ouvrir : écran de confirmation du profil.

## 4. Vérifications sur téléphone (à faire, rien n'est vérifié sur appareil)

1. Après mise à jour : l'accueil, la semaine en cours, l'historique et les références sont ceux d'avant.
2. Écran de confirmation : « Plus tard » ramène à l'accueil ; Réglages → Profil le rouvre.
3. Confirmer avec toutes les réponses « Non » : les charges du jour sont inchangées.
4. Dans Profil → « Modifier », répondre « Oui » à une question : une séance de S1 (tests) affiche « pas de test maximal » ; une charge de traction lestée à plus de 80 % baisse. Puis « J'ai l'accord de mon médecin » : les charges reviennent.
5. Terminer une séance : au plus une question de Koach s'affiche après le bilan, avec « Plus tard » et « Ne plus demander ».
6. Export : la section `profile` y figure ; « Retirer mon accord » efface les réponses de santé.
7. Grand texte (200 %) et TalkBack sur les écrans du profil.

## 5. Statut

| Statut | Éléments |
| --- | --- |
| Corrigé dans le code | KT-038 à KT-043 |
| Testé automatiquement | CI `claude/ci-tools` commit `0facb5d` : format 0 changement, analyse sans problème, **598 réussis / 12 ignorés** (28 nouveaux), Python 63/63, `verify_project.py` ; build debug ; démarrage mesuré 9 écrans / 24 taps / 1 saisie |
| Vérifié sur appareil | Rien |
| Reste à valider | §4 ; registre `docs/CONTRAT_L8.md` §9 (questions de santé rédigées sans le PAR-Q+, seuils du mode prudent, tranches du repère, qualification RGPD) |

## 6. Décisions prises par défaut

Voir `docs/CONTRAT_L8.md` §2 (D-L8-1 à D-L8-10). Les plus visibles : « Forme et santé » présélectionné pour tous (l'ordre des écrans place le repère après les objectifs) ; sans profil confirmé, aucun effet du mode prudent ; accord du médecin caduc après une nouvelle gêne ou un nouveau « oui ».

## 7. Fichiers modifiés

Nouveaux : `lib/profile.dart`, `lib/profile_store.dart`, `lib/profile_screens.dart`, `test/l8_profile_test.dart`, `test/l8_profile_screens_test.dart`, `docs/CONTRAT_L8.md`, `docs/CONFIDENTIALITE.md`. Modifiés : `lib/store.dart`, `lib/koach_store.dart`, `lib/main.dart`, `lib/settings_screen.dart`, `lib/session_screen.dart`, `pubspec.yaml` (3.1.0+65), `README.md`, `SUIVI_PROJET.md`.
