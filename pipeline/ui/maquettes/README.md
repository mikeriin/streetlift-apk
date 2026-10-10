# Maquettes de la refonte UI (version 2)

Canevas vivant (à regarder en priorité) : https://claude.ai/artifact/2YmgbXjKpPzX75sPccDN3J

- `Avant*.dc.html` : capture émulateur de l'écran actuel (dev6.11.1) ; `*.dc.html` sans préfixe : sa version finie.
- Les adresses `/_blob/…` ne se résolvent que dans le canevas. Correspondances locales dans `illustrations/` :
  `koach_<pose>.svg` (poses de `kalis_koach` converties en masques : encre pleine, papier et yeux évidés),
  `ci1*_*.png` (captures « avant »). Logo : `assets/icon/logo_mark.png` ; anatomie : `assets/muscles/{front,back}_*.png`
  teintés de `pleine` à `encre` de la palette (règle de `muscle_body.dart`).
- Chaque maquette porte deux réglages : `palette` (les 8 palettes, rôles de `inputs/palettes_roles.json`) et `capitales`.
