# Kalis Track 2.2.1 — Palette noir, rose et gris

Version **2.2.1+44**. Mise à jour limitée aux couleurs, assets de marque et documents.

Palette demandée : **#000000 / #CB2957 / #DDDDDD / #EEEEEE**. Source : [Color Hunt](https://colorhunt.co/palette/000000cb2957ddddddeeeeee).

Le noir et les gris structurent les surfaces ; le rose marque les cartes principales, sélections et actions. Des nuances neutres et un rose plus sombre pour certains petits textes assurent la lisibilité. Le K historique reste sans fond dans l’interface, gris clair en sombre et rose en clair. Les icônes Android sont recolorées.

Vérification ciblée pour limiter le travail à la demande : analyse Flutter sans problème ; quatre tests existants de transitions et de contraste réussis ; 43 captures de l’application générées en clair / sombre, avec vues compactes. Le test de contraste contrôle les rôles textuels de la palette à 4,5:1 minimum sur les principales surfaces.

Dix-huit fichiers de logique, données, dépendances et signature ont été comparés à la version 2.2.0 : tous sont identiques. Le rapport figure dans `validation/2.2.1/unchanged-from-2.2.0.json`. Séances, STATS, animations, historiques, crédits et acquisition des WOD sont inchangés. La suite complète de 152 tests avait passé sur la version 2.2.0 ; elle n’a pas été relancée pour cette modification de palette.

Aucun APK compilé ici. Utiliser le workflow GitHub habituel avec l’archive nommée `streetlift_tracker_v33.zip`. Les données de démonstration des captures restent confinées aux tests.
