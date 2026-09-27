# Contrat L12 — Motivation et progression visible (4.2.0)

**27 septembre 2026, lot exécuté par le pipeline automatisé (sans échange en direct).** Tickets KT-065 à KT-071. Code : `lib/motivation.dart` (règles pures, sans horloge ni widget), `lib/motiv_store.dart` (branchement sur le store), `lib/motivation_screens.dart` (écrans), partage natif `android/…/MainActivity.kt` + `ShareProvider.kt`. Tests : `test/l12_motivation_test.dart`, `test/l12_store_test.dart`, `test/l12_screens_test.dart`.

Toutes les décisions de L7 (Koach), L8 (profil), L10 (générateur) et L11 (adaptation) restent valables. L12 n'écrit aucune valeur de pilotage, ne modifie ni le journal, ni les records, ni le registre des gains (KT-005).

## 1. Base et contradictions relevées

| Point | Constat | Traitement |
| --- | --- | --- |
| Base | `streetlift_tracker_v33.zip` 4.1.0+68 (L11), `main` `b202121`, 2 198 067 octets, SHA-256 `e598e0fc4be71f25a198b324fcd1b25e9eedd5b0138af786621c6cfb6cf0ad78`, racine unique `streetlift_tracker/` | Travail sur copie |
| Contrats lus | `CONTRAT_L7.md`, `CONTRAT_L8.md`, `CONTRAT_L10.md`, `CONTRAT_L11.md` ; pack L9 via `assets/content/progressions.json.gz` (24 chaînes, 127 arêtes) | — |
| Récompenses des étapes (KT-067) et invariant économie | Le prompt demande des récompenses dédiées **et** interdit tout barème non validé | Célébration + liste « Étapes franchies » (récompense non économique) appliquées ; **barème en crédits proposé (§5), non appliqué** (`kMilestoneRewardsApproved = false`). D-L12-05 |
| Rappels « jamais les jours de repos » (KT-070) et réglage 2.x « Ignorer les jours de repos » (désactivable) | Le réglage permettait un rappel « Journée de récupération » | Réglage retiré de l'écran ; valeur toujours ramenée à vrai à la lecture (sauvegarde et import) ; champ conservé pour la compatibilité du format. D-L12-08 |
| « Ton de Koach » existant (profil L8, jamais utilisé) | Le champ `tone` du profil existait sans effet | Il pilote désormais la bibliothèque de messages ; sans profil, choix dans la section `motiv`. D-L12-06 |
| « Ma progression » existe déjà (XP, niveaux, rang) | Risque de confusion | Le nouvel écran s'appelle **« MES PROGRÈS »**. |
| Parcours d'habitude « 2 séances de 20 minutes » et générateur L10 | Réécrire le générateur changerait les programmes déjà générés et les profils types | Couche d'adaptation (compression L11 à 20 min, cible de régularité 2) sans réécrire le programme. D-L12-10 |

## 2. Décisions prises par défaut (réversibles)

| Id | Décision | Pourquoi / comment revenir |
| --- | --- | --- |
| D-L12-01 | Niveau = niveau global L10, sinon repère du profil, sinon intermédiaire (même règle que L11). Débutant/novice → victoires ; intermédiaire → records et courbes ; avancé/expert → statistiques complètes | Réglage « Afficher toutes les statistiques » pour tous |
| D-L12-02 | Écran de victoires : au plus 3 chiffres sur tout l'écran défilé (le bouton « 10 minutes, ça compte » en compte un) ; la vue STATS d'un débutant est remplacée par ces victoires | Même réglage |
| D-L12-03 | Étape de chaîne franchie = critère du pack atteint dans une séance (séries validées, répétitions ou secondes lues dans le champ « répétitions », lest ≥ % du poids de corps) ; une étape plus avancée pratiquée valide les précédentes **sans célébration** | Évite une avalanche de célébrations |
| D-L12-04 | Étapes réelles : record (une par exercice et par semaine), étape de chaîne, cycle terminé (bloc du programme terminé avec au moins une séance), régularité (4, 8, 12, 26, 52 semaines régulières d'affilée). Célébrées si elles datent de moins de 7 jours et n'ont jamais été vues ; une installation mise à jour ne reçoit donc pas de célébration pour un historique ancien | Liste complète dans « Étapes franchies » |
| D-L12-05 | Barème proposé (§5) non appliqué ; la célébration est marquée vue une fois (`motiv.seen`) | Validation du propriétaire |
| D-L12-06 | Ton par défaut : bienveillant (débutant, novice), neutre (intermédiaire), exigeant (avancé, expert) — valeurs L8. Messages de sécurité (douleur, mode prudent, maladie) : texte neutre unique | Réglages → Motivation et progression |
| D-L12-07 | Semaine régulière : au moins 3/4 des séances prévues (arrondi supérieur, 1 au moins ; 2 au plus pendant le parcours d'habitude) ; toute séance compte (programme, perso, 10 minutes) ; jours de pause exclus ; une semaine sans séance prévue ne casse ni n'allonge la série ; un jour de repos sans entraînement est compté « respecté », s'entraîner un jour de repos n'est jamais pénalisé | Registre de validation |
| D-L12-08 | Rappels : uniquement les jours d'entraînement prévus non faits, jamais un jour de repos ni pendant une pause ; heure = heure choisie (réglage existant) ; permissions refusées : règles existantes | — |
| D-L12-09 | Bilan hebdomadaire : semaine civile précédente, visible du lundi au dimanche suivant, s'il y a eu au moins une séance dans cette semaine ou les 3 précédentes ; « Vu » le range. Bilan de fin de cycle : du lendemain du dernier jour du cycle, 14 jours, si le cycle contient au moins une séance | Évite de relancer un utilisateur arrêté (L11 s'en charge) |
| D-L12-10 | Parcours d'habitude : débutant et novice, 28 premiers jours après le départ ; séances compressées à 20 minutes (ou la durée du profil si plus courte, 10 min au moins) par la compression L11 ; les séances au-delà de 2 par semaine sont « en bonus » ; désactivable | Réglages → Motivation et progression |
| D-L12-11 | Séance « 10 minutes, ça compte » : séance perso créée à la demande (4 exercices sans matériel ni saut du pack, 2 séries, repos 30 s) | Supprimable comme toute séance perso |
| D-L12-12 | Partage : image PNG générée sur l'appareil (fond #121212, bordure bordeaux), contenu coché par l'utilisateur ; poids décoché par défaut ; aucune donnée de santé proposée ; fichier temporaire dans le cache de l'application servi en lecture seule au destinataire choisi | — |

## 3. Affichage progressif (KT-065)

| Niveau | « MES PROGRÈS » |
| --- | --- |
| Débutant, novice | Victoires concrètes (« +6 répétitions en pompes depuis ton départ », « Première traction ! », « 5 semaines régulières »), liens Mes figures / Étapes franchies / Partager, séance de 10 minutes |
| Intermédiaire | + records récents (5), courbes simples (estimation hebdomadaire L11 des mouvements principaux), assiduité, poids facultatif |
| Avancé, expert | + statistiques de Koach (1RM estimé ± incertitude, rythme observé par semaine), totaux |

Accès : STATS → « Mes progrès » (débutant : STATS affiche directement les victoires), Réglages → Motivation et progression. Poids : affiché seulement s'il est connu, sans jugement ni objectif, bouton « Masquer ».

## 4. Arbre de figures (KT-066)

« MES FIGURES » : chaînes utiles à l'objectif en tête (forme et santé → pompes, tractions, squat, charnière, gainage, mobilité ; force → tractions, dips, pompes lestées, back squat… ; épreuves datées → chaînes des épreuves), autres chaînes repliées. Détail : chaque étape avec icône **et** libellé (atteinte, en cours, suivante, à venir), date de passage, critère de passage de l'étape en cours et de la suivante.

## 5. Barème PROPOSÉ des récompenses (non appliqué)

| Étape | Crédits proposés | Raison |
| --- | --- | --- |
| Record | 0 | déjà récompensé par le bonus XP « record » existant |
| Étape de chaîne franchie | 2 | ≈ semaine complète × 2 ; rare (quelques par an) |
| Cycle terminé | 3 | égal à un chapitre bouclé |
| Régularité 4 / 8 / 12 / 26 / 52 semaines | 1 / 1 / 2 / 3 / 5 | paliers croissants, jamais repris |

Application après validation : passer `kMilestoneRewardsApproved` à vrai, ajouter la clé `milestone:<id>` au registre des gains KT-005 (payé une fois, jamais repris). Estimation pour un utilisateur régulier sur 40 semaines : ≈ 10 étapes de chaîne + 8 cycles + 4 paliers → ≈ 51 crédits.

## 6. Ton de Koach (KT-068)

Bibliothèque : 12 contextes (séance faite, record, étape, cycle, semaine régulière, reprise, bonne semaine, semaine calme, séance courte, jour de repos, parcours d'habitude, progrès) × 3 tons × 3 groupes de niveau. « Entraînement difficile, guerre facile » réservé au ton exigeant. Test automatique : aucun mot d'une liste interdite (humiliation, culpabilisation, vocabulaire médical, « malgré », « ignorer », « fatigue », « douleur » hors sécurité).

## 7. Bilans (KT-069)

- Hebdomadaire (3 éléments) : une victoire (étape de la semaine, sinon semaine régulière, sinon séances faites), l'assiduité (séances prévues faites et jours de repos respectés), le cap (séances prévues de la semaine suivante ; 2 courtes pendant le parcours ; « une première séance, même de 10 minutes » après une semaine calme).
- Fin de cycle : progrès (meilleure évolution d'estimation du cycle, sinon séances faites), point fort, point à travailler (palier L11 ou évolution la plus faible), prochain objectif (cycle suivant ou régénération), projection Koach (statut de l'objectif final ou rythme observé), toujours présentés comme repères.

## 8. Données et migration

Section optionnelle **`motiv`** (format 3 inchangé), écrite seulement si elle sert (export identique à 4.1.0 sinon), ignorée par les versions antérieures, remise à neuf par l'effacement L2b :

```json
"motiv": {"v": 1, "tone": "kind|demanding|neutral",   // sans profil seulement
  "showAll": true, "hideBody": true, "habitOff": true,
  "seen": {"chain:pompes": "2026-09-27"},              // étapes célébrées
  "reviews": {"week:2026-09-21": "2026-09-28", "cycle:2:5": "…"}}
```

Bornes : 2 000 étapes vues, 500 bilans. Import : valeur hors contrat → import refusé ; démarrage : entrée illisible ignorée et comptée. **Aucune migration** : tout est calculé à la lecture du journal.

## 9. Registre de validation (à relire par un professionnel diplômé)

| Élément | Qui |
| --- | --- |
| Critères de passage des chaînes (pack L9) appliqués automatiquement, lecture des secondes dans le champ répétitions | Préparateur physique |
| Semaine régulière = 3/4 des séances ; paliers 4-52 semaines | Préparateur physique |
| Parcours d'habitude : 4 semaines, 2 × 20 min, compression automatique | Préparateur physique |
| Séance de 10 minutes (4 exercices, 2 séries, 30 s) | Préparateur physique |
| Textes de la bibliothèque de messages et messages de sécurité | Préparateur physique / médecin du sport |
| Barème des récompenses (§5) | Propriétaire |

## 10. Limites

- Aucun essai sur téléphone ; partage Android non essayé sur appareil.
- Les étapes de chaîne ne sont détectées que pour des exercices reconnus par le pack (nom du journal) ; une tenue saisie en secondes doit l'être dans le champ « répétitions ».
- Les courbes simples utilisent l'estimation hebdomadaire L11 (mouvements principaux du programme seulement).
- Récompenses en crédits non appliquées (en attente de validation).
- Contenu sportif non relu par un professionnel diplômé : repères d'entraînement, aucune promesse de résultat ni bénéfice de santé.
