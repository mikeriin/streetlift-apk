# Correctifs UI et UX — dev6.12.1 (11/10/2026)

Passe unique demandée par le propriétaire après essai de dev6.12.0 sur téléphone.

| Remarque | Correctif |
| --- | --- |
| Couleurs trop fades | Sombre : encre et secondaire ravivées (chroma HCT portée vers 72, teinte gardée, contraste ≥ 4,5:1 / 3:1 inchangé) ; surfaces teintées de la dominante quand le fond du propriétaire est neutre (chroma 7 au plus). Fond et dominante exacts inchangés. `lib/kit/palette.dart`, `test/fixtures/ui0_palettes_roles.json` régénéré. |
| Couleur de marque trop peu présente | Titres de section, pastilles d'icône des menus, numéros des jours, onglet actif du dock, repère de séance en `encre`. |
| Cartes trop arrondies | Rayons 24 → 16 (cartes), 20 → 12 (groupes, lignes de jour, tuiles, champs de série). |
| Dock sans identité | Plus de liseré gris en sombre ; onglet actif en pilule tonale `encre` (icône `encre`, libellé `texte`). |
| Explications de Koach de trop | « Pourquoi ? » du Bilan du jour et de l'ajustement, détail des notes de Koach, consignes des mini-séries : en mode guidé seulement. Réglages › Séance › Koach : « Mode guidé » (désactivé par défaut) et « Comprendre Koach » (toutes les explications). |
| Glissement des pages qui prend le pas sur le défilement | Vue paginée de séance (`KSessionPager`) : seuil de glissement horizontal doublé, ressort plus ferme (la page se pose plus vite), champs actifs au même seuil. |
| Boutons de forme qui font tache | Tuiles de ressenti au rayon 12 avec repère d'échelle coloré (de `danger` à `validation`), plus compactes. |
| Carte d'exercice confuse | Charge, volume et cible de réserve (« RIR 2 », difficulté sur 10) sur une ligne, cible en badge ; repos, tempo, technique en repères discrets ; une ligne de consigne de Koach (le reste dans sa feuille) ; séance précédente à la demande (icône d'historique de la barre d'outils). |
| Clusters et techniques rares | Bandeau compact : titre court (« Cluster · 3 × 1 · 15 s »), cases des mini-séries, pas à pas et bouton de validation sur une ligne ; un seul bouton de mini-repos. |
| « Exercices » partout | Bouton supprimé : l'appui (ou appui long) sur le titre de la séance ou sur « Exercice n sur N » ouvre la liste ; aussi dans le menu ⋮ (« Liste des exercices »). Même chose dans l'historique. |
| Boutons et espaces trop larges | Repère et points sur une ligne, marges de la carte d'exercice et des lignes de Koach resserrées. |

Réglage ajouté : `AppSettings.koachGuided` (écrit seulement s'il est activé ; export identique sinon).
