# Contrat L13 — Santé, sécurité, conformité et test fermé (4.3.0)

**27 septembre 2026, lot exécuté par le pipeline automatisé (sans échange en direct).** Tickets KT-072 à KT-078. Code : `lib/wellbeing.dart` (textes de référence et règles pures), `lib/safety_store.dart` (branchement sur le store, aucune donnée nouvelle), `lib/wellbeing_screens.dart` (écrans), partage texte natif `MainActivity.kt` (`kalis_track/share` → `shareText`), `tools/check_claims.py` (allégations interdites), `tools/generate_brand.py --play` (visuel Google Play). Politique de confidentialité embarquée : `assets/legal/confidentialite.md`. Tests : `test/l13_safety_test.dart`, `test/l13_screens_test.dart`, `tools/tests/test_l13_compliance.py`.

Documents livrés avec ce contrat : `docs/CONFIDENTIALITE.md` (cartographie finale, KT-075), `docs/GOOGLE_PLAY.md` (déclarations, KT-076), `docs/REGISTRE_VALIDATION.md` (KT-077), `docs/TEST_FERME.md` (KT-078), `docs/play/feature_graphic_1024x500.png`.

Toutes les décisions de L7 (Koach), L8 (profil, consentement, mode prudent), L10, L11 et L12 restent valables. L13 **n'ajoute aucun champ enregistré** : ni migration, ni changement du format de sauvegarde, ni changement de barème.

## 1. Base et contradictions relevées

| Point | Constat | Traitement |
| --- | --- | --- |
| Base | `streetlift_tracker_v33.zip` **4.2.0+69** (L12), `main` `332e292`, 2 254 226 octets, SHA-256 `71f975ab02a7ae3b08593705752c6c8c8cbf8adcbca0e9583d75efa6eb5b6335` (identique à `LIVRAISON_L12.md`), racine unique `streetlift_tracker/` | Travail sur copie |
| Contrats lus | `CONTRAT_L7.md`, `CONTRAT_L8.md`, `CONTRAT_L9b.md`, `CONTRAT_L10.md`, `CONTRAT_L11.md`, `CONTRAT_L12.md`, `CONFIDENTIALITE.md`, `CONFIDENTIALITE_KOACH.md` | — |
| Douleur : L7 D26 « jamais l'arrêt » et KT-073 « signal d'alerte » | D26 interdit à Koach d'arrêter une séance d'office | Les signaux d'alerte sont un **texte d'information** (« arrête l'effort, demande de l'aide ») : Koach n'arrête rien automatiquement. D26 inchangé |
| Douleur persistante : « plus de 2 séances » | L7 propose −20 % à la 2ᵉ séance de suite > 3/10, avec un rappel générique | Renvoi explicite vers un professionnel à partir de la **3ᵉ séance** de suite > 3/10 (§3.2). D-L13-02 |
| Sauvegarde Android et données de santé | KT-016 option A (propriétaire) : `allowBackup="true"`, ni `dataExtractionRules` ni `fullBackupContent`, contrôlé par `verify_project.py` | **Inchangé** ; la politique l'explique clairement. Exclure `profile.health` reste une option (`CONFIDENTIALITE.md` §5) |
| Réponses Koach de fin de séance (sommeil, forme, douleur) et consentement L8 | Collectées depuis L7 (avant le consentement L8), facultatives à chaque séance, utilisées pour les propositions de charge et le renvoi douleur | Non conditionnées au consentement L8 et non effacées par son retrait (la note de douleur reste une entrée de sécurité) ; documentées comme données de santé potentielles, dans l'export, supprimables seules. D-L13-05, **à relire** |
| Données figées du programme v33 | Une note (« Ischios : assurance anti-blessure sur le squat lourd ») est une allégation de prévention ; l'asset est figé (empreinte contrôlée par les tests LC1/LC1b) | Reformulée **à l'affichage** (`kWellnessWording`, `lib/models.dart`) ; asset inchangé. D-L13-06 |
| Profil importé d'un mineur | L8 refuse un mineur au démarrage et en modification, mais un fichier importé pouvait contenir une année de naissance < 18 ans | Blocage de l'application (écran « RÉSERVÉE AUX ADULTES » : corriger l'année ou supprimer les données). D-L13-04 |
| URL publique de la politique | Non fournie | **Non inventée** : champ de la fiche Google Play à remplir par le propriétaire (`GOOGLE_PLAY.md` §1) |

## 2. Décisions prises par défaut (réversibles)

| Id | Décision | Pourquoi / comment revenir |
| --- | --- | --- |
| D-L13-01 | Avertissement : carte sur le **premier écran** du démarrage (installation neuve et confirmation d'une installation existante) et dans Réglages → À propos. Pas de case à cocher bloquante | Un écran bloquant de plus alourdirait le démarrage ; une installation déjà confirmée le voit dans « À propos ». Option : carte unique sur l'accueil après la mise à jour |
| D-L13-02 | Renvoi vers un professionnel : douleur > 3/10 notée sur **3 séances consécutives** (celles où le mouvement a été noté, dans l'ordre de fin), affiché sous la note de douleur du bilan Koach et dans Santé et sécurité | `kPainReferralSessions` |
| D-L13-03 | Signaux d'alerte (poitrine, malaise, essoufflement anormal, douleur qui irradie, palpitations) : carte en tête de « Santé et sécurité », entrée « Douleur ou malaise ? » dans les options de séance, rappel sous toute douleur > 3/10. Numéros 15 et 112 cités | Texte d'information, aucune action automatique (D26) |
| D-L13-04 | Profil de moins de 18 ans (année civile − année de naissance < 18) : application bloquée jusqu'à correction ou suppression. 18 ans dans l'année : accepté (la question « déjà fêté ? » est posée au démarrage et en modification) | `profileIsMinor` |
| D-L13-05 | Réponses Koach par séance : facultatives, hors consentement L8, non effacées par le retrait de l'accord ; effacées par « Supprimer mes réponses aux questionnaires » et par la suppression complète | Option : les effacer aussi au retrait de l'accord et ne plus poser sommeil/forme sans accord (la douleur resterait) |
| D-L13-06 | Allégations dans des données figées : correction à l'affichage plutôt que réécriture de l'asset | Réécrire l'asset imposerait de refaire les empreintes LC1/LC1b |
| D-L13-07 | Retour de test : formulaire local non enregistré ; scénario, note 1-5, trois champs libres (2 000 caractères au plus) ; version cochée par défaut, repère de niveau et mode prudent décochés ; jamais d'historique, de charge, de poids ni de réponse de santé ; partage par le menu Android ou copie | `FeedbackDraft` |
| D-L13-08 | Politique de confidentialité : un seul texte (`assets/legal/confidentialite.md`), affiché dans l'application et publiable tel quel ; contact renvoyé à la fiche Google Play | À héberger par le propriétaire |
| D-L13-09 | Visuel Google Play : logo clair (#F4F4F4) centré sur fond uni #6B0C0C, 1024 × 500, PNG 24 bits sans alpha, sans texte | Un logo bordeaux sur fond bordeaux serait invisible |
| D-L13-10 | « Diagnostic » des notifications renommé « Rapport technique » (le mot ne doit pas évoquer la santé) | Texte seul |

## 3. Règles

### 3.1 Nutrition et récupération (KT-072)
Six conseils généraux (`kRecoveryTips`) : protéines réparties sur les repas, hydratation, sommeil, régularité et jours de repos, alimentation variée (sans calcul de calories ni de macronutriments, sans objectif de poids), écoute des sensations. **Aucun chiffre** (testé). Écran « RÉCUPÉRATION » (Réglages → À propos, et depuis Santé et sécurité). Koach : sommeil et forme restent **facultatifs** (L7, `SessionAnswers` vide accepté, propositions calculées sans eux).

### 3.2 Douleur et situations particulières (KT-073)
Parcours audité de bout en bout :

| Étape | Règle | Où |
| --- | --- | --- |
| Douleur notée > 3/10 | Aucune hausse de charge proposée à la séance suivante (L7 D26) ; rappel des signaux d'alerte | Bilan Koach |
| 2 séances de suite > 3/10 | Allègement −20 % proposé (mouvements principaux) + isométries (L7) | Bilan Koach |
| Gêne ou douleur ressentie | Échange d'exercice à contrainte articulaire égale ou moindre (L11) ; exercice remplacé, jamais de diagnostic | Options de séance → Échanger un exercice |
| **> 2 séances** de suite > 3/10 | **Renvoi vers un professionnel de santé** (médecin, kinésithérapeute) | Bilan Koach, Santé et sécurité |
| Signal d'alerte | Arrêter l'effort, 15 ou 112 si intense ou persistant, avis médical avant de reprendre | Santé et sécurité, options de séance |
| Gêne déclarée > 3/10 au profil | Mode prudent (L8) | Profil |

Situations particulières (`kSpecialSituations`) : grossesse ou accouchement récent, tension ou cœur, 65 ans et plus, reprise après blessure → **mode prudent L8** (testé pour chacune : raison `pregnancy`, `heart`, `age65`, `discomfort`) et avis médical conseillé ; aucun programme spécifique.

### 3.3 Vocabulaire et finalité (KT-074)
Voir §5 (termes interdits) et §6 (finalité).

### 3.4 RGPD (KT-075)
Cartographie finale : `docs/CONFIDENTIALITE.md`. Politique : `assets/legal/confidentialite.md` (Réglages → À propos → Politique de confidentialité). Export : le libellé indique désormais que le profil et les données de santé en font partie. 18 ans et plus : démarrage, modification du profil (L8) et désormais **tout profil importé** (D-L13-04).

### 3.5 Retour de test (KT-078)
Réglages → À propos → « Donner mon avis » : aperçu exact du texte avant partage ; bouton inactif tant que rien n'est rempli ; canal `kalis_track/share`, méthode `shareText` (`ACTION_SEND`, `text/plain`, sélecteur Android) ; aucune écriture.

## 4. Données, format, migration

Aucun champ, aucune section, aucune clé de préférence ajoutés ; export identique à 4.2.0 à contenu égal. Aucune permission, aucune dépendance ajoutées. Asset ajouté : `assets/legal/confidentialite.md`.

## 5. Allégations interdites (recherche automatique)

`tools/check_claims.py` (rejoué par `tools/tests/test_l13_compliance.py` en CI) parcourt les chaînes des fichiers Dart de `lib/` (littéraux adjacents concaténés, commentaires ignorés) et les textes de `assets/` (JSON, JSON compressés, Markdown : programme, pack L9, modèles, politique).

Termes (insensibles à la casse) : guérir/guérison, soigner, traitement, traiter une maladie/douleur/blessure, thérapie/thérapeutique, rééducation, réadaptation, « programme de kiné… », diagnostic/diagnostiquer, prévenir/prévention des blessures, anti-blessure, prévention d'une maladie, garanti(e)(s), perdre du poids/perte de poids, brûler les graisses, cliniquement/médicalement prouvé, « est un dispositif médical », immunité, soulager.

Tolérés uniquement dans une négation ou un renvoi (motif exact dans la même phrase) : « aucun diagnostic », « ne pose aucun diagnostic », « n'est pas un dispositif médical », « aucun traitement », « ne remplace pas », « aucune promesse », « aucun résultat garanti », « sans garantie », « objectif de poids », etc. (liste `ALLOWED`). Texte figé corrigé à l'affichage : liste `CORRECTED_AT_DISPLAY`.

État initial : 4 occurrences (« garantie de résultat » — négation coupée sur deux littéraux, corrigée par la concaténation ; « Diagnostic copié » et « Copier le diagnostic » — renommés ; note « anti-blessure » du programme — reformulée à l'affichage). État final : **0**.

## 6. Finalité : pourquoi Kalis Track reste hors du champ des dispositifs médicaux

Source : règlement (UE) 2017/745 relatif aux dispositifs médicaux, EUR-Lex (https://eur-lex.europa.eu/eli/reg/2017/745/oj?locale=fr), consulté le 27/09/2026.
- Article 2, point 1 : est un dispositif médical un produit, y compris un logiciel, **destiné par le fabricant** à des fins médicales précises (diagnostic, prévention, contrôle, prédiction, pronostic, traitement ou atténuation d'une maladie ; diagnostic, contrôle, traitement, atténuation ou compensation d'une blessure ou d'un handicap ; etc.).
- Considérant 19 : les « logiciels destinés à des usages ayant trait au mode de vie ou au bien-être » ne constituent pas des dispositifs médicaux.

Application à Kalis Track : finalité déclarée **entraînement et bien-être** (planifier, noter, ajuster des charges d'entraînement) ; aucune fin médicale revendiquée (vérifié par §5) ; le questionnaire de santé et le mode prudent ne produisent **aucun diagnostic ni pronostic** : ils limitent l'intensité par prudence et renvoient vers un médecin ; la douleur notée n'est jamais interprétée (aucune cause, aucune zone lésée), elle bloque une hausse, propose un allègement ou un échange et renvoie vers un professionnel. Avertissement visible au démarrage et dans « À propos ». **Limite** : analyse du développeur, non validée par un juriste ni par un organisme notifié ; la fiche Google Play et tout texte promotionnel doivent garder la même finalité (`GOOGLE_PLAY.md`).

## 7. Tests (TESTER SANS TRICHER)

| Test | Fichier |
| --- | --- |
| Série de douleurs et seuil du renvoi (purs) ; ordre réel des séances ; une séance sans douleur interrompt la série | `l13_safety_test.dart` |
| Signaux d'alerte présents ; conseils sans chiffre ni calcul | idem |
| Mode prudent pour chaque situation particulière (grossesse, cœur/tension, 65 ans, gêne) | idem |
| Consentement **refusé → accordé → retiré** : état, mode prudent, contenu de l'export à chaque étape | idem |
| **Export puis suppression complète** des données de santé (profil, accord du médecin, stress, douleur Koach), puis suppression totale | idem |
| 18 ans et plus : import d'un profil de 2012 bloque, 2008 accepté | idem ; écran : `l13_screens_test.dart` |
| Retour de test : **seules les données choisies** (pur et par l'écran, partage simulé) | les deux |
| Écrans à 390 × 844 et 320 × 720, texte 100/130/200 %, clair et sombre, défilement par gestes | `l13_screens_test.dart` |
| Avertissement au démarrage et dans « À propos » ; entrées À propos | idem |
| Aucune allégation (liste documentée), négations tolérées, concaténation Dart | `tools/tests/test_l13_compliance.py` |
| Visuel Google Play 1024 × 500, RGB sans alpha, fond #6B0C0C, régénération identique | idem |

Aucune assertion supprimée, aucun test désactivé. Test Python de régénération du visuel ignoré seulement si Pillow est absent de la machine (l'en-tête PNG est contrôlé dans tous les cas).

## 8. Limites

- Aucun essai sur téléphone ; TalkBack non vérifié sur appareil.
- Analyse « hors dispositif médical » et qualification RGPD faites par le développeur, sans juriste (registre de validation).
- Exigences Google Play vérifiées sur les pages d'aide le 27/09/2026 ; certaines réponses (classification IARC, public cible) sont des **préparations** à saisir dans la Play Console, non vérifiables d'ici (`GOOGLE_PLAY.md`).
- Contenu sportif non relu par un professionnel diplômé (décision du propriétaire) : `docs/REGISTRE_VALIDATION.md`.
