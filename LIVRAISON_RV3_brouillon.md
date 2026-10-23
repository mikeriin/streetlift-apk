# Livraison RV3 — lot rapide : modulation de la semaine selon le mode, dead hang au bilan bas, mineurs restants (dev7.7.1)

Lot de la voie App du pipeline CP (DECISIONS_CP.md C17.51). Base : `main` 83a0170e (dev7.7.0, KB5). Données synthétiques seulement (C17.33.2) ; aucune clé, aucune donnée réelle. `packages/` intacts à l'octet (aucun bug de moteur trouvé).

PUBLICATION

## 1. Ce qui change pour le propriétaire

- **Mode libre (cas du propriétaire)** : quand Koach module les séries de la semaine, la séance garde les séries écrites. La carte de l'exercice dit « Koach te propose N séries au lieu de M cette semaine : il répartirait l'effort de la semaine d'après ta récupération prévue. » avec **Accepter** (passe à N séries pour cette séance) et **Garder l'écrit**. Rien n'est baissé sans action de ta part. En tête de séance : « Koach te propose N séries sur X au lieu de M cette semaine : accepte-les ou garde l'écrit sur sa carte. » ; « Mon programme » dit la proposition (« à accepter en séance »).
- **Mode assisté** : comme dev7.7.0 (ligne servie modulée, raison dite), plus **Annuler** sur la carte (séries écrites pour cette séance).
- Le choix est possible dès l'aperçu (avant le bilan), gardé à l'ouverture de la séance, et versé à Koach à la fin de la séance (accepté ou refusé).
- Le mode qui compte est celui de ton profil (Évolution › Assisté / Libre), jamais celui enregistré dans une séance (C17.51.4).
- Mineurs corrigés : prochain rappel affiché (GtG exclu), rappels replanifiés quand leur contenu change, réglages 3D lus au démarrage, contraste renforcé, licences des logiciels, profil (poids visé, messages, priorité, catégorie, fourchettes gardées, calendrier, test perso).

## 2. Point 1 — modulation de la semaine selon le mode (C17.51.1, C17.51.4)

- **Source** : Koach 1.0.8 applique lui-même la modulation hebdomadaire dans `plan(seance)` (`Planification.appliquer`) et marque chaque ligne servie concernée (`koachModule` = séries ajoutées ou retirées par la semaine). L'application ne change pas le moteur : à l'ouverture (`koachStartNow`), pour chaque ligne servie avec `koachModule` (hors départ chronométré PR8 servi tel qu'écrit, hors test inséré), elle calcule les séries sans la modulation (baisse : jusqu'à l'écrit ; ajout : l'écrit, jamais au-dessus de ce que Koach sert, un ajout plafonné par Koach n'ajoute rien) et sert l'une ou l'autre selon le mode du profil et le choix de l'athlète. État dans `koach.volume` de la séance (séries, sans modulation, appliquée, choix, mode au moment du choix).
- **Assisté** : servie modulée ; « Annuler » → séries sans la modulation (ligne servie au moteur, plan affiché, lignes du journal, technique recalée par `techniqueCoherente`, groupe au chrono recalé par `groupesServis`). La raison `koach.volume_semaine` n'est plus dite pour une ligne annulée.
- **Libre** : servie sans la modulation ; « Accepter » → séries de Koach ; « Garder l'écrit » → choix noté. La raison du moteur (« je te propose … ») n'est pas dite comme appliquée ; la carte et l'en-tête la disent au conditionnel.
- **Ajouts** (au-dessus de l'écrit) : même règle ; un ajout appliqué est dit en tête (« Cette semaine, je te propose N séries sur X au lieu de M : … ») puisque Koach ne dit que les baisses.
- **Choix après le début** : possible tant que la ligne n'a pas plus de séries validées que la plus petite des deux propositions (aucune série validée n'est retirée).
- **Moteur** : le choix explicite est versé à la fin de la séance comme une `decision` (`volume_moins` / `volume_plus`, ampleur = écart en séries, `accepte` vrai pour « Accepter », faux pour « Annuler » / « Garder l'écrit », sans raison) ; aucun choix → rien de versé (l'API le permet : types d'adhérence du moteur). Un changement de mode du profil pendant une séance ouverte ne change rien au service (rien sans action), la carte propose alors le retour possible.
- **Quel mode décide (question du prompt)** : une session dont la séance porte `mode: assisted` (dans `adapt`) et le profil `guidanceMode: free` est **en mode libre**. Avant RV3 : toutes les séances de Koach et leurs aperçus enregistraient `mode: 'assisted'` en dur (trace sans effet sur Koach) ; le moteur 0.x lisait, lui, le mode **enregistré dans la séance** à deux endroits : bilan recalculé d'une séance commencée (`_adaptRefreshStarted` : choix par défaut de l'ajustement) et conseils pendant la séance (`status` appliqué / en attente). Corrigé : ces deux lectures prennent le mode du profil (`adaptMode`) ; les séances de Koach et les aperçus enregistrent le mode du profil comme trace. Séances non commencées : l'aperçu est recalculé à chaque ouverture (mode du profil) ; séances faites jamais réécrites (testé).
- Tests : `test/rv3_koach_mode_test.dart` (fonctions pures, textes ; programme PR2 synthétique avec la modulation forcée sur le plan de Koach : assisté + Annuler + refus versé ; libre + Accepter + acceptation versée ; libre + Garder l'écrit ; choix dans l'aperçu gardé à l'ouverture ; ajout appliqué puis annulé ; C17.51.4 avec un aperçu enregistré « assisted »). Rendus `test/ui_rv3_capture_test.dart` (carte assisté, libre, acceptée ; sombre bordeaux et clair violet, relus). Cible émulateur `integration_test/rv3_modulation_test.dart` (a = sombre, rouge, libre : Accepter ; b = clair, violet, assisté : Annuler), inscrite dans `tools/ci3d_drive.sh`.

## 3. Point 2 — dead hang de la pause du squat au bilan bas (KB5 § 6.4)

- **Relevé** (sonde sur le programme PR2 synthétique, mercredi, bilan 1/1/1) : le dead hang « Dead hang PdC — pause du squat, enchaîné » est **servi à ses 6 × 30 s**, ni retiré ni réduit ; Koach le sert à 6 (pas de raison, aucun retrait). Le squat « 6×3 · E3MOM » est servi tel qu'écrit (PR8 ; Koach l'aurait réduit à 5).
- **Cause du constat de KB5** : le dead hang n'a **jamais** été dans le `GroupSpec` écrit : l'import ne met que le squat dans le groupe `gj3-sl-squat-competition` (E3MOM, 1 080 s) ; le dead hang rejoint l'enchaînement à l'écran par son nom (« enchaîné », règle des protocoles) — jour normal comme au bilan bas. Le relevé de KB5 (« le groupe ne compte plus que le squat ») décrivait le groupe du contrat, identique les deux jours.
- Rien à corriger dans l'application ni dans le moteur ; test ajouté (bilan bas : squat puis dead hang enchaîné, 6 × 30 s, six tenues servies).

## 4. Point 3 — mineurs restants de RV2

Diagnostic et correctifs par un sous-agent Opus (zones P, R, F), relus et contrôlés par la session ; les libellés de RV1 étant succincts, chaque reproduction est établie dans le code. Tests : `test/rv3_mineurs_test.dart`.

| # | Constat (reproduction) | Correctif | Statut |
| --- | --- | --- | --- |
| P10 | Programme annoté (charges de départ plafonnées à 80 % du 1RM en mode prudent) mis en cache sans le mode prudent dans la clé : un mode prudent qui change sans nouveau profil (65 ans atteints) gardait les charges d'avant | `prudent=` dans la clé du cache | corrigé, testé |
| R6 | « Prochain rappel » des réglages : un rappel GtG (toutes les 2 h) passait avant le rappel de séance | prochain rappel de séance seulement | corrigé, testé |
| R7 | Signature de replanification limitée aux réglages, au départ et aux séances faites : `firstShown` (PR2), programme remplacé au même départ, GtG changé ne replanifiaient rien | contenu des rappels prévus dans la signature | corrigé, testé |
| R8 | Réglages 3D (nom au toucher, halo) lus seulement à l'ouverture de Réglages › Apparence ou du mannequin, remis par défaut au changement de session | lus au démarrage et au changement de session | corrigé, testé |
| R10 | Contraste renforcé en sombre : `texte2` à 7:1 sur `surface` seulement (≈ 6,4:1 sur `haute`) | 7:1 aussi sur `haute` | corrigé, testé (8 palettes × 2 thèmes × 3 intensités) |
| R13 | « Sources et licences » : aucun accès aux licences des logiciels (OFL des polices enregistrée), texte relu à chaque reconstruction, chargement sans fin sur erreur | écran à état, message d'erreur, ligne « Licences des logiciels » | corrigé, testé |
| F5 | Poids visé : perte → 70 → maintien → perte : 70 réaffiché, rien d'enregistré | champ vidé | corrigé, testé |
| F6 | Messages « … ($.reps) » | libellé du champ en mots | corrigé, testé |
| F7 | Récapitulatif : priorité en code brut | libellés partagés | corrigé, testé |
| F9 | Catégorie de poids d'un autre règlement gardée cachée | retirée au changement | corrigé, testé |
| F11 | Fourchettes de niveaux perdues au changement de discipline | gardées | corrigé, testé |
| F12 | Calendrier d'une échéance à moins de 7 jours : `initialDate` hors bornes → exception | `pickerInitialDate` (3 calendriers) | corrigé, testé |
| F13 | Carte 2D : couleurs gardées après un changement d'intensité (« Couleurs ») ; course A → B → A pendant le dessin | correctif écrit (intensité dans la clé, dessin abandonné) puis **retiré** : `lib/muscle_map_2d.dart` est une illustration intouchable (UI5, `tools/check_ui_illustrations.py`, contrôle Python rouge au run 39974553797) | reste — décision du pilotage (§ 6) |
| F14 | Contrôleurs de texte jamais libérés (lignes retirées, règlement changé) | `dispose` après l'image | corrigé (pas de test de fuite) |
| F15 | Valeur facultative illisible ignorée en silence | erreur « Une valeur saisie n'est pas lisible… » | corrigé, testé |
| F16 | Test perso sans champs (contrat : meilleur résultat, temps visé) | section « test perso » | corrigé, testé |

Effets visibles notés : une « Autre distance » illisible est désormais refusée (F15) ; en sombre avec contraste renforcé, `texte2` un peu plus clair (R10).

## 5. Contrôles

CONTROLES

## 6. Limites et recommandations au pilotage

1. **Valider dev7.7.1.**
2. Le bilan du jour sous Koach n'a pas de choix de mode (Koach l'applique toujours, comme avant) : le mode du profil gouverne la modulation de la semaine et le moteur 0.x (bloc en cours) ; si le propriétaire veut aussi un bilan « proposé » en libre sous Koach, c'est une décision de comportement (lot application).
3. Ligne à charge fixe (C15) : l'aperçu garde son volume écrit (règle existante) ; sa modulation n'est dite (et choisie) qu'à l'ouverture de la séance.
4. **F13** (carte 2D qui garde ses couleurs après un changement de « Couleurs ») : le correctif touche `lib/muscle_map_2d.dart`, fichier gelé par la refonte UI (empreintes UI5). Recommandation : autoriser ce changement de logique (clé du cache, pas le dessin) et réécrire l'empreinte de ce fichier dans un lot suivant ; correctif prêt dans le commit 2ad2f473 (parent de la sauvegarde `cp-sauvegardes/RV3`, fichier `lib/muscle_map_2d.dart` et son test F13 de `test/rv3_mineurs_test.dart`).
5. Point 2 : aucun lot moteur nécessaire. Si le propriétaire veut que le dead hang fasse partie du groupe du contrat (et non seulement de l'enchaînement à l'écran), c'est un changement de l'import (une ligne « enchaînée » au groupe au chrono de la précédente), à décider.

## 7. À tester (propriétaire)

- Installer dev7.7.1 ; profil en Libre (Évolution) : une séance où Koach propose moins (ou plus) de séries : la ligne garde l'écrit, « Accepter » / « Garder l'écrit » sur la carte.
- En Assisté : la ligne est modulée, « Annuler » revient à l'écrit.
- Mercredi au bilan bas : squat E3MOM et dead hang enchaîné, 6 tenues.
