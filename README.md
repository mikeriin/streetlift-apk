# Branche `cp-references` — programmes de référence chiffrés (pipeline CP)

Ce dépôt est **public** : les programmes de référence transmis par le propriétaire (programmes payants, protégés par le droit d'auteur) ne sont stockés ici que **chiffrés** (`references.tar.gpg`, GnuPG symétrique AES-256, S2K SHA-512).

- La clé n'est **jamais** écrite dans le dépôt, un commit, un fichier, une page ou une notification : elle est donnée seulement dans le message de lancement des lots qui en ont besoin (« Clé des références : … »).
- Déchiffrement, hors du dépôt :
  `mkdir -p /tmp/cp-references && printf '%s' "$CLE" | gpg --batch --pinentry-mode loopback --passphrase-fd 0 -d references.tar.gpg | tar -C /tmp/cp-references -xf -`
  puis lire `/tmp/cp-references/INVENTAIRE.md`.
- Tout ce qui contient une partie des programmes (analyses détaillées, séances, schémas, ancres du panel) reste dans `/tmp` ou est rajouté ici **chiffré avec la même clé** (`analyse_<LOT>.tar.gpg`) ; rien en clair sur aucune branche.
- Seules des mesures agrégées et anonymes (fourchettes) peuvent être publiées (PIPELINE_CP.md §2).
- Branche orpheline : jamais fusionnée ailleurs.
- `journal_proprietaire.tar.gpg` : export du journal du propriétaire (données de santé) pour le rejeu de KM1, même clé, mêmes règles : jamais en clair, seuls des agrégats publiés (DECISIONS_CP.md C13.6).
