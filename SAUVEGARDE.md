# Sauvegarde CI1d (paquets 0.2.3, dev6.9.3)

Base : main 770589ce (dev6.9.2). Branche de mise au point : claude/ci-ci1d-rapide.

Fait :
- kalis_plan 0.2.3 (9b2e9ea3) et kalis_adapt 0.2.3 (ff22faa9) copiés octet pour octet ; kalis_core 0.4.2 inchangé (les deux étiquettes portent 0.4.2) ; pubspec.lock (2 versions), version 6.9.3+111 et tests de version.
- Textes : adapt.load_held cause pain_return ; test reporté (pain_reported / pain_return) ; retrait douleur du jour ; échange appui neutre poignet ; carte d'arrêt affichée aussi les jours sans renvoi (painStopNoticeZones, consigne de consulter seulement les jours de renvoi) ; pain_reprise et wrist_spare comme notes de douleur, pain_reprise dans la carte.
- test/ci1d_paquets_test.dart.

Reste : résultats CI rapide, émulateur, contrôle complet ci-3d, main, build signé, livraison.
