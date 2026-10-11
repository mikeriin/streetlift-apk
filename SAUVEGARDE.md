# Sauvegarde KM1c2 (KM1 correction 2, référence Koach 1.0.2)

Base : `moteurs` df28b47c. Session Fable 5.1, lancée le 11/10/2026 ~05:10 UTC. `add_repo` absent de la session ; push vérifié (pipeline : ligne « en cours »).

## Fait
- Lecture : prompt, C13.10-12, cahier, LIVRAISON_KM2, CRITERES_KM2, code de `koach/seance.py` (bornes de hausse, tentatives, rampe).
- Diagnostic `adv-31c45cfb` (graine 0) : estimation correcte au jour J (147 kg pour 157) ; ouverture bornée par le « dernier passage » en semaine de retour (47,5 kg, simple d'affûtage à 65 % converti par la courbe apprise), puis sauts de tentatives de 5 %/3 % arrondis à la grille = 0 : trois barres à 47,5 kg.
- Outils : `km1c2_outils/trace.py`, `dbg1.py` (dans cette sauvegarde).

## En cours
- Point 1 (reprise par paliers mesurés).

## Reste
- Points 2 (critère 5), 3 (critère 4), 4 (fixtures, docs), campagne six graines, relecture, contrôle, livraison.
