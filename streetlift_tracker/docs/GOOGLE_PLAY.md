# Kalis Track 4.3.0 — Déclarations Google Play (préparation, KT-076)

**27 septembre 2026.** Réponses préparées pour la Play Console ; à saisir par le propriétaire. Chaque exigence porte sa source et sa date de consultation ; « non vérifié » quand la page n'a pas pu être consultée d'ici.

## 1. Fiche du Play Store

| Élément | Valeur préparée | Source / statut |
| --- | --- | --- |
| Nom | Kalis Track | Manifeste (`android:label`) |
| Catégorie | Santé et remise en forme | Choix du propriétaire à confirmer |
| Visuel principal (feature graphic) | `docs/play/feature_graphic_1024x500.png` : 1024 × 500, PNG 24 bits sans alpha, fond uni #6B0C0C, logo clair centré, aucun texte ; régénérable par `python3 tools/generate_brand.py --play` | Exigence 1024 × 500, JPEG ou PNG 24 bits sans transparence : https://screenkit.tools/specs/google-play-feature-graphic-size (reprend l'aide Play Console), consulté le 27/09/2026. Page d'aide officielle des éléments graphiques : **non vérifié** |
| Icône 512 × 512 | À exporter depuis `assets/icon/icon.png` (1024 × 1024) | Non vérifié |
| Captures d'écran | À réaliser sur téléphone (aucune capture produite par ce lot) | — |
| Description courte / complète | À rédiger sans allégation (liste de `docs/CONTRAT_L13.md` §5) : entraînement, suivi, bien-être ; ni « guérir », ni « prévenir les blessures », ni promesse de résultat | Cohérence avec la finalité (§4) |
| **URL de la politique de confidentialité** | **Champ à fournir par le propriétaire** : héberger `assets/legal/confidentialite.md` (tel quel, ou converti en page) sur une adresse publique stable | Une politique est requise pour remplir la section Sécurité des données : https://support.google.com/googleplay/android-developer/answer/10787469, consulté le 27/09/2026 |
| Adresse de contact | À fournir par le propriétaire (la politique y renvoie) | — |

## 2. Sécurité des données (Data safety)

Source : https://support.google.com/googleplay/android-developer/answer/10787469, consulté le 27/09/2026 — « collecter » signifie transmettre des données hors de l'appareil ; les données traitées seulement sur l'appareil n'ont pas à être déclarées ; un transfert fait à l'initiative de l'utilisateur, qui s'attend raisonnablement au partage, n'est pas un partage à déclarer ; toutes les applications remplissent le formulaire, même sans collecte.

| Question | Réponse préparée | Justification |
| --- | --- | --- |
| L'application collecte-t-elle ou partage-t-elle des données utilisateur des types requis ? | **Non** | Aucune transmission hors de l'appareil (pas de serveur, pas de permission `INTERNET`, aucun SDK) ; export, image de progression et retour de test : fichiers ou textes partagés à l'initiative de l'utilisateur |
| Données chiffrées en transit | Sans objet (aucune transmission) | — |
| Suppression des données sur demande | Sans objet côté éditeur ; dans l'application : « Supprimer les données de l'application » | `CONFIDENTIALITE.md` §3 |
| Sauvegarde Android | Pas une collecte par l'éditeur (service du système, compte de l'utilisateur) | Point non traité explicitement par la page : **à confirmer** (registre de validation) |

## 3. Déclaration des applications de santé (Health apps declaration)

Source : https://support.google.com/googleplay/android-developer/answer/14738291, consultée le 27/09/2026 — toutes les applications publiées, tests compris, remplissent la déclaration ; catégories « Santé et remise en forme » (activité et remise en forme, nutrition, sommeil, stress…) et « Médical » (gestion de maladie, prévention, kinésithérapie…).

Réponses préparées :
- **Santé et remise en forme → Activité et remise en forme** : oui (programmes d'entraînement, suivi des séances, charges).
- Nutrition et poids : non (conseils généraux seulement, aucun suivi alimentaire ; le poids sert au calcul des charges). **À confirmer** : certains relecteurs rangent la pesée dans « gestion du poids ».
- Sommeil, stress : non comme fonction (questions facultatives servant à ajuster l'entraînement). À confirmer.
- **Médical : aucune catégorie** (pas de gestion de maladie, pas de prévention de maladie, pas de kinésithérapie ni d'aide à la décision clinique ; voir finalité `CONTRAT_L13.md` §6).
- Health Connect : non utilisé.

## 4. Classification du contenu (questionnaire IARC)

**Non vérifié** (questionnaire accessible seulement dans la Play Console). Réponses préparées : ni violence, ni sexualité, ni langage grossier, ni substances, ni jeux d'argent ; pas d'interaction entre utilisateurs, pas de partage de localisation, pas d'achat numérique ; partage de contenu seulement par le menu Android. Classification attendue : tout public — la cible reste **18 ans et plus** (§5).

## 5. Public cible et contenu

**Non vérifié** (page d'aide non consultée). Réponse préparée : tranche **18 ans et plus** uniquement ; l'application n'est pas destinée aux enfants ; pas de publicité ; contrôle dans l'application (démarrage, modification, import).

## 6. Autres déclarations de la Play Console (préparées, non vérifiées)

- Publicités : **non**. Accès à l'application : aucune connexion requise. Application d'actualités : non. Application gouvernementale : non. Fonctions financières : aucune.
- Permissions sensibles : `SCHEDULE_EXACT_ALARM` (rappels de séance à l’heure choisie) — une déclaration d'usage peut être demandée : **à vérifier dans la Console**.

## 7. Test fermé

Voir `docs/TEST_FERME.md` (12 testeurs pendant 14 jours consécutifs pour un compte personnel créé après le 13/11/2023).
