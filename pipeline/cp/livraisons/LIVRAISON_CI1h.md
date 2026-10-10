# Livraison CI1h — charge fixe du programme et prévision de fin de séance (dev6.11.2)

Lot CI1h du pipeline « Calibrage des programmes », voie App (tâche « Opus 5.5, effort élevé, application »), lancé le 10/10/2026 vers 21:05 UTC sur l'accord du propriétaire (DECISIONS_CP.md C15, C15.7 « fais au plus pragmatique » ; LANCEMENTS.md, section CI1h). Message sans ligne « Lot : » : seul lot de la voie App « à faire ». Validation : conversation de pilotage, puis test réel du propriétaire.

- **Version** : dev6.11.2 (`pubspec.yaml` 6.11.2+115) — UI5 n'avait pas publié sur `main` (pointe b7996b3f, dev6.11.1).
- **main** : 9ef40dad — « Kalis Track dev6.11.2 (CI1h) : charge fixe du programme, prévision de fin de séance » (parent b7996b3f, arbre d7de5656).
- **Build signé** : run 38091686005 (APK de développement + AAB), vert.
- **Contrôle complet** : `claude/ci-3d`, run 38088963446, vert (commit de contrôle cc97f610) (arbre d7de5656 identique au commit de main).
- **Paquets inchangés** : `kalis_core` 0.4.3, `kalis_plan` / `kalis_adapt` 0.3.1 ; rien dans `packages/` (C15.3).
- Accès : `add_repo` absent de la session ; push vérifié par le push de la ligne « en cours » sur `pipeline`.
- Mise au point : `claude/ci-ci1h-rapide` (essai 4 vert, run 38088619626 : formatage, analyse, tests Dart du lot et des lots CI1b à CI1g, G9, G2/G3 mode dev).

## 1. Causes confirmées

**Défaut 1 — charge fixe non tenue.** Confirmée par test (`ci1h_charge_fixe_test.dart`, « S14·J6… cause confirmée ») : sans la contrainte, le moteur seul sert le squat endurance de S14·J6 à **72,5 kg** sur un journal synthétique facile (70 kg × 15 à 4 répétitions en réserve) — 77,5 kg chez le propriétaire avec son vrai journal. La lecture du pilotage est exacte : `_importLoad` / `_importFormat` font de la charge écrite une simple `startLoadKg`, et `kalis_adapt` règle ensuite la charge pour tenir le RIR cible aux répétitions prescrites (hausse bornée). Avec la contrainte : 70 kg sur les trois séries.

**Défaut 2 — « La prochaine fois » ≠ séance servie.** Causes confirmées à la lecture du code de dev6.11.1 :
- (b) `_adaptNextGoal` prescrivait avec d'autres entrées que `adaptOpen` : sans saison (le mode coach du programme annoté lit la saison), journal jusqu'à aujourd'hui sans exclure la séance visée, et l'ouverture se faisait au jour réel (une séance future ouverte le soir même porte la fatigue de la séance qui vient de finir) alors que la prévision visait la date prévue ;
- (c) la prévision visait la prochaine journée qui contient le même exercice du catalogue (par exemple le squat lourd de S14·J3 pour le squat endurance de S13·J6) ;
- (a)/(d) l'écran est un résumé, sans proposition à accepter, et ne disait ni la séance visée ni que tout est recalculé.

## 2. Ce qui change

**Charge fixe (C15.2)**
- À l'annotation du programme importé, chaque ligne `load.type == 'fixed'` (0 kg compris) pose un indicateur par « semaine|emplacement » : `ImportedProgram.fixedLoad` (exercice écrit, charge écrite) — recalculé à chaque chargement, **jamais écrit dans la sauvegarde**.
- Couche de contrainte appliquée à **toute** prescription du moteur (`_adaptPrescribe` : séance servie, séance commencée mise à jour, séance sans l'effet du bilan, aperçu, prévision) : charge écrite à chaque série (`startLoadKg` et cibles par série ; une montée d'échauffement jamais au-dessus), répétitions et secondes jamais au-delà de la ligne écrite ; raisons de hausse, de baisse et de calibrage de la charge remplacées par « Charge fixée par ton programme : je règle seulement les répétitions. » (« Sans lest, comme l'écrit ton programme : … » pour une ligne au poids du corps ; rien pour la mobilité ou le cardio).
- Conseils entre séries : jamais de changement de charge ; série trop dure (répétitions manquées, ou au moins une répétition en réserve de moins que la cible de flammes) → répétitions de la série suivante abaissées (ce qui a été fait, ou l'écart de RIR), **jamais sous la moitié de la cible** ; série facile → rien. Arrêt de l'exercice : inchangé.
- Sécurité : la conduite sous douleur s'applique (allègement gardé quand une douleur ou une reprise graduée abaisse la charge, substitution, retrait, arrêt). Un exercice remplacé par Koach n'est plus contraint.
- Le journal enregistre ce qui a été fait ; le moteur apprend de ces séries normalement.
- **Exception** : « Dead-hang lesté ou PdC » (34 lignes) — le nom laisse le choix de la charge (règle : « ou » avec « lesté » ou « PdC » dans le nom). « Marche ou vélo très léger » reste verrouillée à 0 kg (sans effet : exercice sans charge).
- **Programmes générés** : `kalis_plan` 0.3.1 écrit des charges de départ (`startLoadKg`), jamais une charge fixe ; l'application les montre comme `load: fixed` dans le programme affiché, mais l'indicateur ne vaut que pour le programme importé (semaines d'avant un programme créé) : rien à faire.

**Prévision (C15.4)**
- **Un seul calcul** : `adaptPlannedSession(semaine, jour)` sert l'ouverture d'une séance non commencée et chaque ligne de « La prochaine fois » (bloc avec les ajustements de Koach, journal sans la séance visée, profil, saison, réglages, contrainte de charge fixe).
- **Séance future** : ouverte avant sa date prévue, prescrite à sa date prévue, sans bilan ; le jour même ou après : au jour réel. Avec un bilan donné, au jour réel ; la séance « sans l'effet du bilan » reste celle de l'ouverture.
- La prévision vise d'abord la même ligne du programme (même emplacement : squat endurance de J6 → J6 de la semaine suivante), sinon la prochaine journée avec le même exercice ; une journée déjà commencée ou faite est sautée.
- **Fin de séance** : « Squat endurance : 70 kg × 15 — S14 · J6, samedi 17/10 » ; première ligne de la section : « Prévision : je recalcule chaque séance le jour venu, avec ton bilan. »
- **Non traité** (C15.7) : une séance future **commencée** en avance garde sa prescription à la date prévue (pas de nouvelle prescription au jour réel) ; rare.

## 3. Lignes à charge fixe du programme de 40 semaines

693 lignes `fixed` ; 659 verrouillées (hors exception), dont 653 portées au moteur (les 6 « BILAN — report des résultats » ne le sont pas : servies telles qu'écrites, sans charge). « Avant » : prescription du moteur seul ; « après » : prescription servie. Base de charge : celle de l'exercice du catalogue.

| Ligne | Nombre | Charge écrite | Base de charge | Servie avant | Servie après |
| --- | --- | --- | --- | --- | --- |
| Squat endurance @ 70 kg | 33 | 70 kg | barre (externe) | 72,5 kg (journal synthétique facile ; 77,5 kg chez le propriétaire) | 70 kg chaque série |
| TEST MAX SQUAT @ 70 kg | 4 | 70 kg | barre (externe) | réglée par le moteur | 70 kg |
| Tractions, dips, pompes PdC (séries longues, clusters, séries de référence, EMOM, échelles, séries continues, très léger) | 130 | 0 kg | poids du corps (lest possible selon l'exercice) | lest possible selon le journal | jamais de lest |
| TEST MAX TRACTIONS / DIPS / POMPES / MUSCLE-UPS PdC | 15 | 0 kg | poids du corps | lest possible | jamais de lest |
| Muscle-ups PdC explosifs, négatifs et transitions de muscle-up, GtG muscle-up, tractions explosives poitrine-barre | 112 | 0 kg | poids du corps | lest possible | jamais de lest |
| Isométries max (transition MU, bas de dip), false grip hold, hollow body hold | 104 | 0 kg | poids du corps (secondes) | — | jamais de lest, secondes jamais au-delà de la ligne |
| Scapular pull-ups, ab wheel, Pallof press, YTW, contraste français (squat) | 151 | 0 kg | poids du corps ou sans charge | — | jamais de lest |
| Mobilité (épaules + poignets, complète), repos actif, marche ou vélo très léger, HIIT court | 104 | 0 kg | sans charge | — | inchangé (pas de charge) |
| BILAN — report des résultats | 6 | 0 kg | non portée | — | telle qu'écrite |
| Dead-hang lesté ou PdC | 34 | 0 kg | — | — | **non verrouillée** (exception) |

Contrôle global (une passe, toutes les semaines, journal synthétique facile, C15.7) : **679 prescriptions de lignes verrouillées, 0 série hors de sa charge écrite** (relevés `CI1H|global|…` du journal des tests).

## 4. Lignes d'écran modifiées (pour UI5)

- `lib/adapt/adapt_summary_screen.dart` : section « La prochaine fois » — première ligne « Prévision : je recalcule chaque séance le jour venu, avec ton bilan. » ; chaque ligne suivie de la séance visée (`summaryTargetText` : « — S14 · J6, samedi 17/10 »). Aucune mise en page changée.
- `lib/adapt/adapt_texts.dart` : `adapt.load_held`, causes `program` (« Charge fixée par ton programme : je règle seulement les répétitions. ») et `program_bodyweight` (« Sans lest, comme l'écrit ton programme : je règle seulement les répétitions. »).

## 5. Contrôles

| Contrôle | Résultat |
| --- | --- |
| `test/ci1h_charge_fixe_test.dart` : inventaire (693 lignes, 34 exceptions) ; S14·J6 squat à 70 kg (cause confirmée sans la contrainte : 72,5 kg), série facile → rien, série manquée → répétitions abaissées à 70 kg ; jamais sous la moitié de la cible (règle pure) ; ligne PdC facile → jamais de lest ; douleur du genou à 7/10 → squat retiré ; « lesté ou PdC » libre ; contrôle global S1-S40 ; prévision = séance ouverte juste après sur 3 séances (S13·J6 → dont S14·J6 à 70 kg ; S14·J4 ; S14·J5 : 16 exercices comparés) ; séance ouverte la veille puis le jour même → recalculée, prescrite à sa date prévue ; texte de la séance visée | vert |
| Suites CI1b, CI1c, CI1d, CI1e, CI1f, CI1g, G9 ; G2 (version) ; mode dev G2, G3 | vertes (run rapide 38088619626) |
| Contrôle complet `claude/ci-3d` (formatage, analyse, suite Dart, mode dev, Python, paquets, émulateur : cibles existantes, aucune nouvelle, C15.7) | vert (run 38088963446 : 822 tests, mode dev, paquets, Python ; émulateur, codes de toutes les cibles à 0 ; rendus « captures » en échec comme depuis avant CU) |
| Build signé APK + AAB | vert (run 38091686005, main 9ef40dad ; aussi run 38088963351 sur l'arbre de contrôle) |
| Installation par-dessus dev6.11.1 | aucune donnée nouvelle dans la sauvegarde (indicateur recalculé au chargement) ; une séance pas commencée ouverte sous 6.11.1 est represcrite à la réouverture ; tests CI1c à CI1g verts |

Relecture indépendante (sous-agent Opus) : 8 constats ; traités : reprise graduée après douleur (charge plafonnée par le moteur gardée), série d'une flamme au-dessus d'une cible de 9 flammes, texte « Sans lest » réservé aux lignes au poids du corps (rien pour la mobilité), séance « sans l'effet du bilan » calculée comme l'ouverture, lieu sans bilan à la date prévue, conseil brut jamais servi sur une ligne verrouillée, montées d'échauffement jamais au-dessus de la charge écrite ; prévision par emplacement (squat endurance → J6 et non le squat lourd de J3). Laissé : une prescription contrainte hors contrat (jamais observée) retombe sur celle du moteur ; exception « ou … lesté/PdC » large (aucune autre ligne concernée dans le programme).

## 6. À tester sur le téléphone du propriétaire

1. **S14·J6** (samedi 17/10) : squat endurance servi à **70 kg** sur chaque série ; note des flammes réelles : série facile → charge et répétitions inchangées ; série manquée → répétitions de la suivante baissées, toujours 70 kg.
2. **Fin de séance** : chaque ligne de « La prochaine fois » nomme la séance visée et sa date ; la ligne « Prévision : … » est en tête.
3. Ouvrir **en avance** la séance de la semaine suivante citée dans « La prochaine fois » : mêmes valeurs que la prévision (tant qu'aucune autre séance n'a été faite entre-temps ; le jour venu, le bilan peut les changer).

## 7. Limites et reste à faire

- Séance future commencée en avance : non represcrite au jour réel (C15.7).
- Une prévision reste une prévision : une séance faite entre-temps, le bilan du jour ou un ajustement de Koach accepté changent la séance le jour venu (c'est dit à l'écran).
- KM3 conserve la contrainte et le calcul unique (C15.3, prompt KM3).

## 8. Recommandation (C8, le pilotage décide)

Valider dev6.11.2 et la donner au propriétaire à la place de dev6.11.1 : les deux défauts signalés sont corrigés au plus court (C15.7), sans changement de paquet ni de mise en page, et le squat endurance est tenu à 70 kg partout.
