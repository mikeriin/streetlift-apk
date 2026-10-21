# Contrat L8 — Profil, démarrage progressif, questionnaire de santé préalable (3.1.0)

**26 septembre 2026.** Tickets KT-038 à KT-043. Code : `lib/profile.dart` (modèle et règles, fonctions pures, horloge en paramètre), `lib/profile_store.dart` (branchement sur le store), `lib/profile_screens.dart` (écrans). Tests : `test/l8_profile_test.dart`, `test/l8_profile_screens_test.dart`.

## 1. Base et contradictions relevées

| Point | Constat | Traitement |
| --- | --- | --- |
| Base | `streetlift_tracker_v33.zip` 3.0.3+64 (L6), `main` `8e8f6d1`, SHA-256 `87b8a6bb06eadd01b5915dea9114e07323427814684a60ea880c5bacf888cf98`, racine unique `streetlift_tracker/` | Travail sur copie |
| Contrats L8 et L9 préexistants | Absents (`docs/CONTRAT_L7.md` seul) | Ce document |
| « Liste normalisée du matériel du pack L9 » | Le pack L9 n'est pas encore livré (branche `content-pack` absente) | Liste provisoire à identifiants stables (§3.3), à rattacher en L9b |
| Ordre des écrans / présélection de « Forme et santé » | Le prompt place le repère de niveau **après** les objectifs, mais demande de présélectionner « Forme et santé » selon ce repère | « Forme et santé » est présélectionné pour tous (premier de la liste) ; l'utilisateur change en un tap. Décision par défaut D-L8-1 |
| Mode prudent « si l'utilisateur ne répond pas » vs « un utilisateur existant garde ses valeurs » | Appliquer le mode prudent à une installation 3.0.x sans profil changerait ses charges sans action de sa part | Sans profil (installation existante non confirmée), comportement 3.0.x inchangé ; dès qu'un profil existe, la règle s'applique (y compris « sans réponse → prudent »). D-L8-2 |
| PAR-Q+ | Conditions (eparmedx.com, *Terms and Conditions*, consultées le 26/09/2026) : pas de modification, pas d'intégration dans un produit sans accord écrit de la PAR-Q+ Collaboration | Formulation exacte **non reprise** : 8 questions équivalentes rédigées pour Kalis Track (§5), signalées au registre de validation |

## 2. Décisions prises par défaut (réversibles)

| Id | Décision | Pourquoi / comment revenir |
| --- | --- | --- |
| D-L8-1 | « Forme et santé » présélectionné pour tous | Ordre des écrans imposé ; une constante (`_primary` initial) |
| D-L8-2 | Sans profil : aucun effet du mode prudent (installation 3.0.x) ; l'écran de confirmation est proposé à chaque ouverture (« Plus tard » possible) et dans Réglages → Profil | Aucune charge modifiée sans action ; `ProfileStore.caution` |
| D-L8-3 | Repère global = tranche la plus basse des mouvements renseignés (pompes obligatoire, tractions facultatives) | Prudence ; `levelFromBenchmarks` |
| D-L8-4 | 18 ans : année de naissance seule ; si l'âge civil de l'année vaut 18, question « As-tu déjà fêté tes 18 ans ? » ; 65 ans et plus = année courante − année de naissance ≥ 65 (inclut ceux qui les auront cette année) | Minimisation (pas de date complète) ; prudence |
| D-L8-5 | Accord du médecin : lève les raisons datées au plus tard à la déclaration (réponses « oui », âge, gênes > 3/10) ; une nouvelle réponse « oui » ou une nouvelle gêne > 3/10 le rend caduc. Ne lève ni le refus du consentement ni un questionnaire sans réponse | Levée datée sans rouvrir de trou |
| D-L8-6 | « Plus tard » d'une question progressive = reportée 7 jours ; fermer la feuille = « Plus tard » | `kQuestionSnooze` |
| D-L8-7 | Migration : objectif principal « Préparer un test ou une compétition » (épreuves = 4 mouvements lestés, cibles et date de l'objectif final Koach s'il est saisi, sinon étape « 12 mois après le départ »), secondaire « Force » 70/30 ; jours = jours de la semaine avec au moins 2 séances terminées ; durée = médiane (première série → fin) arrondie au quart d'heure ; lieux parc + salle ; repère depuis B19 (pompes) et B17 (tractions). Toutes ces valeurs sont marquées « estimé » (ou « mesuré » pour le repère si les références sont renseignées) et modifiables à l'écran de confirmation | Pré-remplissage ; rien n'est écrit avant « Confirmer » |
| D-L8-8 | Poids : saisi (facultatif) sur l'écran d'âge ; enregistré comme pesée datée L7 (`koach.weighIns`) et poids de corps B4, comme la saisie de pesée existante | Historique daté repris de L7 |
| D-L8-9 | Premier écran activé par `main()` (`SLApp(profileGate: true)`) ; `const SLApp()` des tests de parcours existants garde l'accueil direct | Les tests existants restent inchangés ; les tests L8 activent le premier écran |
| D-L8-10 | Gênes : « depuis » saisi en 3 tranches (< 1 mois, 1-6 mois, > 6 mois), date approximative enregistrée | Démarrage court |

## 3. Modèle (KT-038)

### 3.1 Section `profile` de la sauvegarde (format 3 inchangé)

Écrite **seulement si un profil existe** : l'export d'une installation sans profil est identique à 3.0.3. Ignorée par les versions antérieures.

```json
"profile": {
  "v": 1, "origin": "onboarding|migration", "createdAt": "AAAA-MM-JJTHH:MM:SS",
  "fields": { "<clé>": { "v": <valeur>, "at": "<horodatage>", "src": "declared|estimated|measured" } },
  "health": {
    "consent": { "status": "given|refused|withdrawn", "at": "…" },
    "answers": { "at": "…", "q": { "heart": false, … } },
    "clearance": { "at": "…" },
    "injuries": [ { "zone": "knee", "level": 0-10, "since": "AAAA-MM-JJ", "at": "…" } ]
  },
  "events": [ { "at": "…", "fields": ["days", …] } ],
  "questions": { "lastSession": "S3-J1", "never": ["…"], "later": { "<question>": "…" } }
}
```

### 3.2 Champs (V1, minimisation)

| Clé | Valeur | Remarque |
| --- | --- | --- |
| `birthYear` | entier 1900-2100 | Contrôle 18+, mode prudent ≥ 65 |
| `goalPrimary`, `goalSecondary` | `health`, `strength`, `endurance`, `event` (actifs) ; `muscle`, `skills`, `energy` (catalogue, désactivés en V1) | |
| `goalWeight` | 50-100 par pas de 10 (part du principal ; défaut 70) | Seulement avec un secondaire |
| `eventGoal` | `{date, items:[{id, target?}]}` (1-10 épreuves du catalogue `kEventItems`) | |
| `experience` | `none`, `lt6m`, `6to24m`, `2to5y`, `gt5y` | Question progressive |
| `days` | jours 1 (lundi) à 7 | |
| `sessionMinutes` | 10-240 | |
| `places` | lieu → matériel (`kPlaces`, `kEquipment`) | |
| `dayPlace` | jour → lieu | |
| `benchmarks` | `pushups`, `pullups` → tranche 0-4 | Repère, pas un niveau figé |
| `liked`, `disliked` | ≤ 30 textes de ≤ 60 caractères | Questions progressives |
| `physicalJob` | booléen | Question progressive |
| `sleep`, `stress` | tranches | **Santé** : jamais sans consentement |
| `motivation` | ≤ 200 caractères | Question progressive |
| `autonomy`, `tone` | `guided/assisted/expert`, `kind/demanding/neutral` | Expert jamais par défaut |

Sexe et taille non demandés. Toute modification ajoute un événement « profil modifié » (au plus 300 conservés), affiché dans Réglages → Profil ; L10 s'en servira pour régénérer le programme.

### 3.3 Matériel normalisé (provisoire, à rattacher au pack L9)

`pullup_bar`, `dip_bars`, `rings`, `bands`, `dumbbells`, `kettlebell`, `barbell`, `rack`, `bench`, `weight_belt`, `machines`, `box`, `jump_rope`, `erg`, `mat`. Lieux : `home_none`, `home_equipped`, `park`, `gym`.

### 3.4 Lecture

Import d'un fichier : toute valeur hors contrat refuse l'import entier (rien n'est modifié). Démarrage : entrée illisible ignorée et comptée (`profileLoadIssues`), le reste est chargé. Un champ ou une réponse de santé sans consentement donné est refusé dans les deux cas.

## 4. Démarrage court (KT-039)

Écrans : bienvenue → âge (+ poids facultatif) → objectifs → disponibilités → lieux et matériel → repère de niveau → santé (information, consentement, questionnaire, gênes) → mode et ton → récapitulatif. **Rien n'est écrit avant le récapitulatif confirmé.** Mesuré par test : 9 écrans, 24 taps et 1 saisie pour un parcours type (3 jours, 8 réponses de santé) ; durée estimée ≈ 75 s à 3 s par geste (non chronométrée sur téléphone).

Moins de 18 ans (ou 18 ans cette année sans les avoir fêtés) : message neutre, **aucune écriture** (vérifié : aucune écriture du document, stockage identique, aucune pesée).

Valeurs par défaut du mode et du ton : débutant/novice → Guidé + Bienveillant ; intermédiaire → Assisté + Neutre ; avancé/expert → Assisté + Exigeant ; appliquées à la sortie du repère tant que l'utilisateur n'a pas choisi lui-même.

## 5. Questionnaire de santé et mode prudent (KT-041)

Questions (oui/non), rédaction propre : problème de cœur ou de tension signalé par un médecin ; douleur dans la poitrine ; perte de connaissance ou d'équilibre par étourdissement (12 mois) ; suivi pour une maladie de longue durée ; médicaments prescrits pour une maladie de longue durée ; problème d'os, d'articulation ou de muscle pouvant s'aggraver ; conseil de n'avoir une activité que sous surveillance ; grossesse ou accouchement depuis moins de 6 mois.

Déclencheurs : consentement non donné ; questionnaire incomplet ; une réponse « oui » ; 65 ans et plus ; gêne > 3/10. Effets :

| Règle | Implémentation |
| --- | --- |
| Charge ≤ 80 % du 1RM estimé (mouvements principaux) | Le pourcentage des charges `system`/`barbell` rattachées à B8-B11 est plafonné à 0,80 avant l'arrondi (chemin 2.x et chemin Koach) |
| Pas de test maximal | Les exercices « TEST … » / intensité « Maximum » affichent : « pas de test maximal ; série propre avec au moins 3 répétitions en réserve » |
| Au moins 3 RIR sur les mouvements principaux | Consigne affichée sous l'exercice |
| Conseil médical | « Demande l'avis d'un médecin avant de t'entraîner intensément » (récapitulatif, Profil) |
| Levée | « J'ai l'accord de mon médecin » (déclaration datée, D-L8-5) ; retirable |

Aucun diagnostic, aucun programme médical. Limite : la charge affichée est plafonnée, mais une série saisie plus lourde n'est pas bloquée (l'utilisateur garde la main).

## 6. Consentement (KT-042)

Information affichée avant toute question de santé (texte `kHealthInfo`), choix explicite « J'accepte / Je refuse », révocable (Réglages → Profil → « Retirer mon accord » : réponses, gênes, accord du médecin, sommeil et stress effacés). Finalité unique : adapter l'entraînement. Stockage local, inclus dans l'export et dans la suppression des données de l'application. Refus : mode prudent, sans ces champs. Cartographie et politique préparatoire : `docs/CONFIDENTIALITE.md`.

## 7. Questions progressives (KT-040)

Ordre : ancienneté → exercices détestés → exercices aimés → sommeil → stress → métier physique → motivation. Au plus une, à la fin d'une séance validée (après l'enregistrement et le bilan Koach, avant la cérémonie de niveau) ; jamais pendant une séance ni un chrono. « Plus tard » (7 jours), « Ne plus demander ». Sommeil et stress seulement avec consentement. Sans profil, jamais posées.

## 8. Migration (KT-043)

Installation existante sans profil : écran « Ton profil est pré-rempli » (D-L8-7) au lancement et dans Réglages → Profil. Confirmer ajoute seulement la section `profile` : départ, références, objectifs Koach, journal et réglages restent identiques (test : export avant = export après moins `profile`, sur un état 3.0.0 rempli de 40 semaines).

## 9. Registre de validation (à relire par un professionnel)

| Élément | Qui |
| --- | --- |
| Formulation des 8 questions de santé, équivalence avec un questionnaire reconnu | Médecin du sport ; décision sur une licence PAR-Q+ |
| Seuils du mode prudent (80 %, 3 RIR, gêne > 3/10, 65 ans) | Préparateur physique / médecin |
| Tranches du repère (pompes, tractions) et valeurs par défaut du mode | Préparateur physique |
| Qualification RGPD (art. 9), base légale, texte d'information, trace du consentement | Juriste / DPO (`docs/CONFIDENTIALITE.md` §5) |
| Refus des mineurs par déclaration seule | Juriste |

## 10. Limites

- Pas de régénération du programme (L10) : le profil est enregistré et affiché ; seul le mode prudent agit sur les charges et les consignes.
- Le mode Expert, le ton, les lieux et le matériel n'ont pas encore d'effet sur les séances (L10/L11).
- Aucun essai sur téléphone ; durée du démarrage estimée, pas chronométrée.
