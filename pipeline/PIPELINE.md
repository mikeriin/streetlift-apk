# Pipeline automatisé Kalis Track — règles communes (propriétaire : Gaël, 26/09/2026)

Tu es lancé par une tâche planifiée, dans une session neuve, **sans personne pour répondre en direct**. Le propriétaire a demandé l'automatisation complète, avec une notification uniquement quand une décision de sa part est nécessaire, et une utilisation économe des crédits.

## 1. Démarrage
1. `add_repo` mikeriin/streetlift-apk en accès `push`, puis clone (commande donnée par l'outil, délai long).
2. `git fetch origin pipeline` et lis `pipeline/PIPELINE.md` (ce fichier), `pipeline/ETAT.md` et le prompt de ton lot (`pipeline/prompt_<LOT>.txt`). **Exécute ce prompt intégralement.**
3. Base : `streetlift_tracker_v33.zip` sur `main`. Vérifie la version prérequise (tableau §6). Si elle ne correspond pas : notification (§4) et arrêt.

## 2. Économie de crédits
- Lis seulement les fichiers utiles au lot ; pas d'exploration exhaustive, pas de sous-agents sauf nécessité réelle.
- Pas de SDK Flutter local (le proxy refuse storage.googleapis.com et pub.dev) : regroupe les contrôles en **un minimum de passages CI** sur la branche temporaire `claude/ci-tools` (formatage, analyse, tests, build debug), corrige, repasse seulement si nécessaire ; puis **un seul** build signé sur `main`.
- Rapports concis ; pas de captures sauf demande du prompt.

## 3. Décisions
Le propriétaire t'autorise à trancher toi-même tout choix **réversible** et compatible avec ses décisions écrites. Consigne chaque choix dans le contrat du lot, section « Décisions prises par défaut », et ajoute-le à `pipeline/DECISIONS_EN_ATTENTE.md` s'il mérite sa relecture.
Arrête-toi et notifie uniquement si :
- (a) une migration risque de perdre des données sans solution sûre ;
- (b) le prompt contredit une décision explicite du propriétaire ou l'état réel du code d'une façon qui change le résultat ;
- (c) un accès, un secret ou un outil indispensable manque ;
- (d) le build ou les tests échouent encore après 2 corrections sérieuses.
Changement de barème économique (XP, crédits, prix) : ne l'applique pas ; écris la proposition chiffrée dans `DECISIONS_EN_ATTENTE.md` et continue (non bloquant).
Pour une décision bloquante : écris la question avec 2 à 3 options et ta recommandation dans `pipeline/DECISIONS_EN_ATTENTE.md` et à la fin de ta réponse, envoie la notification, puis attends la réponse dans cette session. Si la réponse arrive, reprends et termine le lot.

## 4. Notifications (outil PushNotification, moins de 200 caractères, une ligne)
- Décision : `Kalis Track <LOT> : décision requise — <question en une phrase>`
- Livraison : `Kalis Track <LOT> livré — v<version>, run n°<n>. <suite>`
- Échec : `Kalis Track <LOT> bloqué — <cause courte>`
Aucune notification de progression intermédiaire.

## 5. Fin de lot
1. Publication et build signé selon le prompt ; vérifie le run.
2. `LIVRAISON_<LOT>.md` : dans le projet claude.ai (outil Projects, chemin `claude/LIVRAISON_<LOT>.md`) s'il est disponible, et toujours dans `pipeline/livraisons/` sur la branche `pipeline`.
3. Mets à jour `pipeline/ETAT.md` (lot, version, commit, run, date, statut, décisions en attente) et pousse la branche `pipeline` (jamais de zip sur cette branche).
4. Lance le lot suivant avec `fire_trigger` selon le §6, puis envoie la notification de livraison.
Interdits : supprimer une branche, modifier la signature ou l'identifiant, régénérer une clé, pousser un secret.

## 6. Enchaînement
| Lot | Version prérequise sur main | Produit | Suivant |
| --- | --- | --- | --- |
| L9 | toute (lecture seule de main) | pack sur la branche `content-pack` (orpheline) + outil de relecture publié comme artefact claude.ai avec une base partagée pour enregistrer les relectures (skill `artifact-capabilities`) | aucun : notification `Kalis Track L9 : pack prêt, relecture requise` avec le lien de l'artefact |
| L9-passe2 | toute | lit les relectures (outil ArtifactData, ou fichier fourni dans le texte de lancement), corrige, pousse `kalis_content_pack_v1_final.zip` sur `content-pack` | L9b **si** main est en 3.1.0 ; sinon rien (L8 lancera L9b) |
| L8 | 3.0.2 | 3.1.0 | L9b **si** `content-pack` contient `kalis_content_pack_v1_final.zip` ; sinon notification « L8 livré ; L9b attend la relecture du pack » |
| L9b | 3.1.0 + pack final | 3.2.0 | L10 ; notification : « point d'installation conseillé » |
| L10 | 3.2.0 | 4.0.0 | L11 |
| L11 | 4.0.0 | 4.1.0 | L12 |
| L12 | 4.1.0 | 4.2.0 | L13 |
| L13 | 4.2.0 | 4.3.0 | L6 |
| L6 | 4.3.0 | 4.3.1 | fin : notification « Pipeline terminé — installer 4.3.1 ; décisions en attente : N » |
