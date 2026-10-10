# Maquettes de la refonte UI (version 3)

Canevas vivant (à regarder en priorité) : https://claude.ai/artifact/2YmgbXjKpPzX75sPccDN3J

- `Avant*.dc.html` : capture émulateur de l'écran actuel (dev6.11.1) ; `*.dc.html` sans préfixe : sa version finie.
- Les adresses `/_blob/…` ne se résolvent que dans le canevas. Correspondances locales dans `illustrations/` :
  `koach_<pose>.svg` (poses de `kalis_koach` converties en masques : encre pleine, papier et yeux évidés),
  `ci1*_*.png` (captures « avant »). Logo : `assets/icon/logo_mark.png` ; anatomie : `assets/muscles/{front,back}_*.png`
  teintés de `pleine` à `encre` de la palette (règle de `muscle_body.dart`).
- Chaque maquette porte des réglages : `palette` (les 8 palettes, rôles de `inputs/palettes_roles.json`), `capitales`, `rayon_cartes` et `rayon_menus` (valeurs retenues : 24 et 20, cahier §5.3 ; les commandes sont toujours en pilule).
- Arborescence (cahier §4) : `Arbo.dc.html` (planche « Où trouver quoi »), `Reglages.dc.html` (racine : recherche, carte Profil, 6 rubriques), `ReglagesRecherche.dc.html`, `ReglagesApparence.dc.html`, `ReglagesChrono.dc.html` (rubrique « Séance »), `Programme.dc.html` (Mon programme), `Main.dc.html` (ligne « Mon programme » en bas de l'accueil), `MenuSeance.dc.html`, `Arsenal.dc.html`.
- `canvas.json` : disposition du canevas.
