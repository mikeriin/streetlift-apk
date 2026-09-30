# Livraison 5.10.0 — Nouveau logo ; M8 correction 2 (carte muscle par muscle)

Demandes du propriétaire (30/09/2026) :
- « Nouveau logo, changer la couleur Rouge Kalis, elle s'appelle toujours pareil mais prend la couleur du logo. »
- « Refais aussi plusieurs passes sur la surbrillance des groupes musculaires pour avoir quelque chose de scientifiquement correct, j'ai constaté pas mal de petites erreurs. »

## Logo et Rouge Kalis
- Logo (appui renversé formant le K, `tools/logo_source.png`) : masque refait à la place et à la hauteur de l'ancien ; en-tête, icône de l'application (classique, adaptative, monochrome), icône des notifications, visuel Google Play régénérés (`tools/generate_brand.py`).
- Rouge Kalis = couleur du logo **#5E1615** (au lieu de #6B0C0C) ; rouge d'action **#9E2A28** et rouge clair **#D96968**, même teinte, clartés d'avant (contrastes de la charte tenus, test des 12 combinaisons). Couleurs des blocs du générateur de programme inchangées (références figées du générateur).

## Surbrillance scientifiquement correcte (trois passes)
1. **Carte muscle par muscle** : 44 régions anatomiques (au lieu de 15 groupes) posées à la main sur agrandissements quadrillés ; trapèze de dos partagé en faisceaux supérieur / moyen / inférieur selon leurs insertions ; un exercice n'allume que les régions de ses muscles. Muscles profonds non dessinés (transverse, oblique interne, petit pectoral, supra-épineux, sous-scapulaire, coraco-brachial, vaste intermédiaire, petit fessier, rotateurs de hanche, court adducteur, poplité, multifides, carré des lombes, fléchisseur profond des doigts, élévateur de la scapula, loge postérieure profonde de la jambe) : listés en texte (« Non dessinés sur la carte » sur la fiche).
2. **Relecture anatomique indépendante** (deux tours) : dentelé / oblique externe des flancs, chefs du triceps de profil, brachio-radial / extenseurs de profil, fléchisseurs distaux, brachial du coude, soléaire latéral et tendons profonds de dos, bord postérieur du SCM, pli axillaire postérieur (grand dorsal), loge postérieure de la cuisse (biceps fémoral, semi-tendineux et semi-membraneux, grand adducteur) ; filtres : lombaires et coiffe des rotateurs ajoutés (17), sous-épineux sorti de « Deltoïdes ».
3. **Relecture biomécanique des rôles du pack** (625 exercices, 255 profils) : 80 corrections nettes sur 79 exercices (`tools/sources/corrections_muscles.json`, appliquées par `tools/content_corrections.py`, contrôlées en test) — grand pectoral sterno-costal dans les tractions (Youdas 2010), grand fessier au gainage des pompes, dentelé en stabilisateur dans les tractions scapulaires, deltoïde postérieur en stabilisateur dans les pompes en ATR, droit fémoral retiré du hip thrust, biceps principal au tirage vertical supination, profils recopiés corrigés (crow, clean, windmill, zercher, extensions triceps, L-sit, support). Laissés : levier dorsal (discutable), bilan et contraste (pas des exercices ; rien de dessiné).

## Contrôles
- Tests Dart : régions et filtres, profonds jamais dessinés, exercices de référence (squat, soulevé de terre, traction), chaque région allumée montre un muscle de la fiche (625 fiches), étiquettes et toucher. Tests Python : table générée identique au script, muscles dessinés une seule fois, corrections appliquées, fabrication reproductible.
- Émulateur (sombre, clair) : couleur lue au cœur du grand dorsal, pectoraux gris, toucher → « Grand dorsal · Dorsaux », démarcation 0,0, aucune vue 3D.
- CI 3D run 36745077241 (essai H vert après A à G : références figées du générateur — couleurs de blocs laissées à l'ancien rouge —, lints, table générée hors `dart format`, tests d'étiquettes et de toucher sans attente asynchrone) : 1013 tests Dart, 150 Python.
- main 0a3f17f ; build signé n° 191 (36747182764).
