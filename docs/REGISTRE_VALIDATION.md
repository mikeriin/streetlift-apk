# Kalis Track 4.3.0 — Registre consolidé de validation du contenu (KT-077)

**27 septembre 2026.** Tout ce qui mériterait la relecture d'un professionnel diplômé (préparateur physique, médecin du sport, kinésithérapeute, juriste/DPO).

## Limite V1 (décision du propriétaire)

**Le propriétaire a décidé de ne pas faire relire le contenu en V1.** Rien de ce qui suit n'a été relu par un professionnel diplômé. Les règles viennent des décisions écrites du propriétaire, de sources publiques citées dans les contrats et de choix prudents du développeur.
- **Impact** : des seuils, volumes ou précautions peuvent être inadaptés pour certains profils (trop prudents ou pas assez) ; le texte de santé peut être incomplet ; la qualification juridique n'est pas confirmée. Atténuations en place : avertissement au démarrage et dans « À propos », mode prudent par défaut sans accord ou sans réponse, charges plafonnées à 80 % en mode prudent, aucune hausse avec douleur > 3/10, renvoi vers un professionnel, aucune allégation (contrôle automatique).
- **Prochaine action** : avant la mise en production (ou au plus tard avant une communication large), faire relire en priorité les lignes marquées **P1**, puis P2 ; consigner chaque relecture (qui, date, décision) dans ce registre.

## Registre

| # | Élément | Où (code / contrat) | Relecteur | Priorité |
| --- | --- | --- | --- | --- |
| 1 | Questionnaire de santé (8 questions propres, non reprises du PAR-Q+ faute de licence), déclencheurs du mode prudent | `lib/profile.dart` `kHealthQuestions`, `CONTRAT_L8.md` §5 | Médecin du sport | **P1** |
| 2 | Seuils du mode prudent : 80 % du 1RM estimé, 3 RIR, gêne > 3/10, 65 ans, pas de test maximal | `evaluateCaution`, `cautionPct`, `CONTRAT_L8.md` §5 | Médecin / préparateur | **P1** |
| 3 | Douleur : seuil 3/10, aucune hausse, −20 % à 2 séances, isométries 5 × 30-45 s, renvoi à 3 séances (L13), jamais d'arrêt automatique (D26) | `koach_engine.dart` (`pain_threshold`, `pain_cut`), `wellbeing.dart` | Kinésithérapeute / médecin du sport | **P1** |
| 4 | Signaux d'alerte et conduite à tenir (arrêt, 15/112, avis médical) | `kAlertSignals`, `kAlertAdvice` | Médecin | **P1** |
| 5 | Situations particulières (grossesse, tension/cœur, 65 ans, reprise après blessure) : mode prudent, avis médical, aucun programme spécifique | `kSpecialSituations` | Médecin / sage-femme | **P1** |
| 6 | Conseils de récupération (protéines, eau, sommeil, régularité, alimentation variée, écoute) | `kRecoveryTips` | Diététicien / médecin du sport | P2 |
| 7 | Seuils de niveau (pompes 10/25/45/70, tractions 1/6/13/21, squat 0,75-2,0 × poids, lests) et conversion des tranches du profil | `assets/program_models.json`, `CONTRAT_L10.md` §8 | Préparateur physique | **P1** |
| 8 | Volumes par groupe (6-14 séries, −2 en santé, plafond +6), périodisation, décharge × 0,6, affûtage | `program_generator.dart`, `CONTRAT_L10.md` | Préparateur physique | P2 |
| 9 | Échauffement, calibrage, règle des 48 h, séances lourdes | `CONTRAT_L10.md` | Préparateur physique | P2 |
| 10 | Contrainte articulaire en cas de gêne, exclusion des sauts en mode prudent, substituts (difficulté ±1, charge 80 %) | `CONTRAT_L10.md`, `CONTRAT_L11.md` | Kinésithérapeute | **P1** |
| 11 | Reprise après arrêt (7/14/28 jours, −10/−20/−30 %), retour de maladie (−30 %, RIR +1, 7 jours) | `koach_adapt.dart`, `CONTRAT_L11.md` §10 | Médecin / préparateur | **P1** |
| 12 | Compression, séance d'entretien, séance de 10 minutes, parcours d'habitude | `CONTRAT_L11.md`, `CONTRAT_L12.md` | Préparateur physique | P3 |
| 13 | Paramètres de Koach : estimation (Epley), bandes de fatigue, seuils sommeil < 5 h / forme ≤ 4, hausses 3-6 %, plafonds 2,5-5 kg, décharges | `koach_engine.dart` `koachParams`, `CONTRAT_L7.md` §4, §11 | Préparateur physique | P2 |
| 14 | Plateau, assiduité 60/90 %, échelle de difficulté | `CONTRAT_L11.md` | Préparateur physique | P3 |
| 15 | Semaine régulière (3/4), paliers de régularité, critères des chaînes de progression | `CONTRAT_L12.md` §9 | Préparateur physique | P3 |
| 16 | Pack de contenu L9 : attributions musculaires, difficultés (dont 70 ajouts), contraintes articulaires, précautions, consignes, démonstrations statiques/indisponibles | `assets/content/`, `validation_register.md` (branche `content-pack`), `CONTRAT_L9b.md` | Préparateur physique / kinésithérapeute | P2 |
| 17 | Programme streetlifting 40 semaines (v3.3) : charges de référence, notes d'accessoires | `assets/programme_v33.json.gz` | Préparateur physique | P2 |
| 18 | Textes de sécurité de la bibliothèque de messages (ton neutre) | `motivation.dart`, `CONTRAT_L12.md` | Médecin du sport | P2 |
| 19 | Qualification RGPD (art. 9), rôle de l'éditeur, consentement, réponses Koach hors consentement (D-L13-05), sauvegarde Android | `CONFIDENTIALITE.md` §6 | Juriste / DPO | **P1** |
| 20 | Finalité « bien-être » hors règlement (UE) 2017/745 et vocabulaire | `CONTRAT_L13.md` §5-6 | Juriste (réglementaire DM) | **P1** |
| 21 | Refus des mineurs par déclaration seule | `CONTRAT_L8.md`, `CONTRAT_L13.md` D-L13-04 | Juriste | P2 |
| 22 | Réponses Google Play (Data safety, santé, classification, public cible) | `GOOGLE_PLAY.md` | Propriétaire (Console) / juriste | **P1** avant soumission |
