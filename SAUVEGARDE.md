# Sauvegarde CX correction 1 (saisons street, kalis_plan 0.2.2 × kalis_adapt 0.2.2)

Session Opus 5.5 lancée le 05/10/2026 vers 05:35 UTC. Base : `moteurs` e90e33e9. Ligne d'état « en cours » poussée sur `pipeline` (32c98fa7).

## Fait
- Lectures : PIPELINE_CP, DECISIONS_CP (C5, C7, C8, section CX), LANCEMENTS (CX, CX correction 1), LIVRAISON_CX, RELECTURE_DOCUMENTEE_CX, corrections nécessaires du panel (passe finale de CX, 43 couples sous 9), 406 notes de la page (aucune du propriétaire).
- Pas de SDK Dart dans la session (pub.dev et storage.googleapis bloqués) : la CI de `claude/ci-cp-a` compile (modes quick / dev / full, cx-outils/ci.sh).
- Mesure « avant » : passe finale complète du panel de CX sur la même version (e90e33e) — notes/p0_toutes.json.
- Code écrit (non compilé) :
  - sécurité : arrêt d'une douleur qui dure / revient / forte (adapt model.dart PainState.stopAt, session 1 bis 0, review : adapt.pain_persistent + painSparing ; plan : coachPainProvokes, stopZones, pronation sous douleur au coude, reprise graduée 50 % +10 %/semaine de charge, charge 67,5 % +2,5 %/semaine, notes pain_stop / pain_return / pain_return_item, export des règles de bloc) ; douleur affichée = journal (shownIntensity).
  - moteur : chaque série jugée contre sa propre cible + note isolée non corroborée ; règle d'assistance (2 séances au haut de plage, ou première série +2) ; série au ressenti basse = borne tant qu'une 2e mesure ne concorde pas ; tentatives +5 % / +3 %, +5 kg au plus, ouverture 91 % ; −7,5 % après une série manquée ; simple ≤ 92 % (85 % jour bas) ; test jamais au-dessus de l'écrit en semaine verrouillée ; test retiré un jour de bilan bas (niveau ≥ 1) et refait 48 h plus tard ; après l'échéance, maximum du jour à mi-chemin réussie/manquée.
  - plan : repère abaissé seulement par max(test, estimation) ; tests en fin de semaine allégée + séance légère 48 h avant ; garde-fou des répétitions écrites +15 %/semaine par mouvement au poids du corps ; marge de 12 % sur les séries de tête longues ; figures 60/70/75 % selon la phase, jusqu'à 10 tenues courtes, pas de tenue de remplissage (avancé, élite) ; 2 jours d'appui lourd si poignet sensible ; montée 40-60-75-85 %, montée avant le muscle-up, consigne dips progressive (débutant) ; plateau → traction lente / archer / typewriter + note plateau ; densité : une variable à la fois.
- Versions : kalis_plan 0.2.2, kalis_adapt 0.2.2, kalis_bench 0.2.1.

## Reste à faire
- Compiler (CI quick), corriger ; tests existants à mettre à jour ; tests des nouvelles règles.
- Boucles du panel (≤ 10), relecture documentée, relecture du code, non-ressemblance, page (manche « street complet (CX correction 1, date) »), livraison, état, notification.
