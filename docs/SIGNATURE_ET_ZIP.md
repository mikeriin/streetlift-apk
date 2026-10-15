> **État courant L1b — 25 septembre 2026 :** la clé et les deux secrets existants
> fonctionnent selon le propriétaire. Les conserver. Pour cette livraison,
> suivre [Validation Android L1b](VALIDATION_ANDROID_L1b.md) ; ne pas répéter
> la création des secrets ni la préparation initiale ci-dessous.
> Les procédures L1 suivantes restent une référence historique de récupération.

# L1 — Signature et livraison depuis un téléphone

Cette procédure concerne uniquement KT-001. Elle conserve l’identifiant
`fr.tchoupi.streetlift_tracker`, la clé existante et les versions des outils.
La clé privée n’est plus incluse dans le ZIP. `signing/certificate.sha256` est
une empreinte de certificat public, pas une clé ni une preuve de la signature
de l’application actuellement installée.

## Reprise L1-R2 après le second journal du 25 septembre 2026

Le run du commit `ea22cf08fa312e308267e110d4958dccd30a09be` a réussi les contrôles
ZIP/assets, l’analyse, 22 tests Python et 186 tests Flutter (1 ignoré). La clé a
été restaurée et utilisée. L’APK release a été compilé à 09:06:48 UTC, mais le
lecteur de sortie apksigner n’a reconnu aucune empreinte : publication arrêtée.
Ce message ne prouve pas un certificat différent. R1 était insuffisant.

R2 supprime ce lecteur. Le contrôleur Java lit directement les certificats via
l’API `ApkVerifier` du `lib/apksigner.jar` déjà fourni par les Android Build Tools
sélectionnés dans le workflow. Il exige une signature cryptographiquement valide,
un signataire unique et le certificat de référence pour toutes les signatures
Android vérifiées. Toute rotation est refusée. Ni la chaîne X.509 ni le Source
Stamp ne remplacent le certificat du signataire. Aucun JAR n’est ajouté au projet,
aucune version d’outil ne change et aucune clé n’est générée.

Depuis ton téléphone, dans cet ordre :

1. **Garde les deux secrets actuels et le workflow actuel.** Ils fonctionnent pour
   restaurer et utiliser la clé. L’outil HTML n’est pas nécessaire pour R2.
2. Télécharge le ZIP R2, conserve le nom exact `streetlift_tracker_v33.zip`, puis
   remplace le fichier de même nom à la racine de `main` dans GitHub :
   **Code → Add file → Upload files**, puis commit. Active « Version pour
   ordinateur » dans le navigateur si ce menu manque.
3. Suis le nouveau run déclenché par le commit. Si nécessaire : **Actions →
   Build APK → Run workflow → main**. Ne relance pas l’ancien run avec
   **Re-run jobs** : il reprendrait l’ancien commit.
4. Attends le succès de l’étape de contrôle du certificat, puis la publication de
   `kalis-track-apk`. Si cette étape échoue encore, transmets seulement son message.
   Les diagnostics n’affichent que des statuts et, si utile, les empreintes publiques.
5. Après succès complet, télécharge l’artefact et extrais `kalis-track.apk`.
   Conserve une sauvegarde des données hors de l’application et le dernier APK
   fonctionnel, puis installe comme mise à jour sans désinstaller. Si Android
   refuse, conserve son message sans désinstaller. Vérifie ensuite historique,
   séances, crédits, achats et réglages.

Le workflow séparé est inchangé et identique à la copie dans le ZIP. Les tests
locaux de R2 comprennent des vérifications cryptographiques de fixtures APK
publiques déjà signées, sans manipulation de clé. Ils ne prouvent pas encore la
conformité de l’APK Kalis du runner ou de l’installation sur ton téléphone.
Le suivi distingue ces tests des résultats du journal CI et conserve l’historique.

La suite décrit la première configuration, à conserver pour référence ; les
étapes de création de secrets et de remplacement du workflow sont déjà faites.

## Situation déclarée par le propriétaire

Sauvegarde privée de la clé et moyens d’accès : oui. Distribution : APK installé
directement. Play App Signing : non activé. ZIP/dépôt : restés privés selon le
propriétaire. Deux secrets GitHub : absents au début de L1. APK de référence :
annoncé joint, mais aucun APK accessible pendant cette passe.
Ces déclarations ne constituent pas une vérification indépendante.

## Actions sur le téléphone, dans cet ordre

1. Conserve l’application installée, la sauvegarde privée de la clé et son mot de
   passe. Vérifie que tu peux retrouver ces deux derniers éléments sur ton
   téléphone, sans les publier ni les envoyer. La clé est le fichier PKCS12
   existant, alias `kalis`, pas `certificate.sha256`. Si elle est seulement dans
   ta copie privée du ZIP original, extrais ce fichier localement avec ton
   gestionnaire de fichiers, en gardant l’archive source intacte. N’utilise pas
   le nouveau ZIP pour la retrouver : il n’en contient plus.
2. Dans le navigateur du téléphone, connecte-toi à ton dépôt privé GitHub.
   Active « Version pour ordinateur » si des menus manquent. Dans **Actions →
   Build APK → …**, désactive temporairement le workflow, pour éviter un build
   entre le remplacement des deux fichiers. Cela ne supprime rien.
3. Télécharge `preparer_signature.html`, ouvre le fichier local dans ton
   navigateur puis passe en mode avion. Choisis la copie privée `.p12` et
   appuie sur **Copier pour KALIS_KEYSTORE_BASE64**. L’outil n’utilise aucune
   ressource réseau, ne demande pas le mot de passe et n’affiche pas la valeur.
   Si le téléphone montre seulement le code HTML, l’aperçu ne l’exécute pas :
   utilise « Ouvrir avec » un navigateur. Si les boutons ou la copie ne
   fonctionnent pas, indique seulement le téléphone et le navigateur pour
   adapter cette étape, sans transmettre la clé. Le fonctionnement sur ton
   modèle de téléphone reste à confirmer.
4. Quitte le mode avion. Dans **Settings → Secrets and variables → Actions →
   New repository secret**, crée le nom exact `KALIS_KEYSTORE_BASE64`, colle le
   contenu dans **Secret**, puis valide **Add secret**. Ne crée pas une variable
   ordinaire. Ne colle cette valeur dans aucun fichier, commentaire ou message.
   Base64 est un encodage réversible ; ce n’est pas du chiffrement.
5. Au même endroit, crée `KALIS_KEYSTORE_PASSWORD` avec le mot de passe existant
   du keystore et de sa clé. Aucun nouveau mot de passe n’est défini par L1.
   Vérifie que les deux noms apparaissent dans la liste ; GitHub ne permet pas
   de relire leurs valeurs. Ferme l’outil local et efface les entrées sensibles
   du presse-papiers/historique du clavier après utilisation.
6. Dans **Code**, remplace à la racine du dépôt `streetlift_tracker_v33.zip`
   par le nouveau ZIP complet : **Add file → Upload files**, sélection du ZIP,
   puis commit. Si le téléchargement a ajouté un suffixe, renomme le fichier
   avant l’envoi. Ne téléverse ni la clé ni l’ancien ZIP contenant la clé.
7. Dans `.github/workflows/`, remplace `build-apk.yml` par le fichier séparé
   livré avec ce ZIP, puis commit. Utilise **Add file → Upload files** dans ce
   dossier. Les octets doivent rester identiques à la copie dans le ZIP : le
   workflow le contrôle. Ne conserve pas l’ancien workflow à mot de passe de
   secours. Les documents de suivi n’ont pas besoin d’être téléversés
   séparément : ils sont déjà dans le ZIP.
8. Réactive **Actions → Build APK**, puis **Run workflow** sur la branche où tu
   viens de remplacer les fichiers. Le workflow doit être présent sur la
   branche par défaut pour proposer le lancement manuel. Choisis cette branche
   pour les remplacements si c’est ton fonctionnement habituel.
9. Vérifie les étapes : contrôle du ZIP et identité des workflows ; assets ;
   dépendances verrouillées ; analyse et tests ; restauration et validation de
   la clé ; compilation release ; signature et certificat de l’APK. Un échec
   de secret absent, Base64 invalide, keystore illisible, mauvais mot de passe,
   alias inaccessible ou certificat différent arrête la livraison. Corrige le
   secret avec ta copie privée existante ; ne crée pas de nouvelle clé.
10. Uniquement après un workflow réussi, télécharge l’artefact
    **kalis-track-apk**, puis extrais `kalis-track.apk`. Conserve le dernier APK
    fonctionnel et une sauvegarde de tes données via la fonction actuelle de
    l’application, stockée hors de l’application. L1 ne valide ni ne modifie le
    mécanisme de sauvegarde : son examen reste un lot séparé.
11. Installe le nouvel APK comme mise à jour, **sans désinstaller l’application**.
    Si Android refuse la mise à jour, arrête-toi et conserve le message d’erreur.
    Ne désinstalle pas pour contourner un refus. Vérifie ensuite historique,
    séances, crédits, achats et réglages. Ce contrôle sur ton téléphone n’a pas
    été exécuté pendant L1 et reste nécessaire avant de valider la continuité.

Le nouveau certificat est comparé à la référence locale dans la CI. Comparer
aussi le certificat du dernier APK réellement utilisé, dès que celui-ci est
disponible. Sans cet APK ou une preuve provenant de l’installation, l’égalité
avec la référence locale ne prouve pas la signature de l’APK installé.

## Fonctionnement technique et contrôles sans secrets

À la racine extraite, ces commandes ne demandent aucun secret :

```sh
python3 tools/verify_project.py
python3 -m unittest discover -s tools/tests -v
python3 tools/package_release.py ../streetlift_tracker_v33.zip
python3 tools/package_release.py --check ../streetlift_tracker_v33.zip
flutter pub get --enforce-lockfile
flutter analyze --no-pub
TZ=Europe/Paris flutter test --no-pub --timeout 60s --reporter expanded
```

Sur le téléphone, c’est GitHub Actions qui les exécute. Flutter/Dart/Android
doivent être disponibles pour les trois dernières commandes ; un contrôle
Python ne remplace jamais leur exécution.

Pour une release, les deux variables d’environnement doivent être injectées
depuis un gestionnaire de secrets, sans les mettre dans la ligne de commande :

```sh
python3 tools/signing.py restore
python3 tools/verify_project.py --signing
flutter build apk --release --no-pub
```

La restauration crée le dossier nécessaire, valide une copie temporaire privée
avant de la déplacer, vérifie le certificat et l’accès à la clé privée existante.
Elle refuse d’écraser une copie locale différente. Les erreurs des outils tiers
sont capturées sans recopier leur sortie. Gradle refuse toute tâche de production
release avec secrets absents/invalides, clé non restaurée, mot de passe incorrect
ou certificat différent. Aucun repli sur la signature debug, mot de passe de
secours ou génération de clé n’est prévu. Les tâches sans production release
restent configurables sans secrets. Les journaux fournis prouvent une compilation
réussie avec les secrets valides. Le refus Gradle sans secrets reste à exécuter
en CI ; aucune compilation Android n’a été effectuée localement.

Les secrets sont transmis uniquement aux étapes de restauration et de build.
La copie temporaire du runner est supprimée en fin de workflow. Les sauvegardes
du propriétaire et l’archive source ne sont pas modifiées. Seuls l’APK et son
SHA-256 sont publiés comme artefact Actions, jamais le keystore.

Le contrôle APK final ne reçoit aucun des deux secrets. Java 17 exécute
`tools/VerifyApkCertificate.java` avec la bibliothèque du SDK ; son résultat est
transmis à Python via un protocole fixe propre au projet. Bibliothèque absente,
API incompatible, échec Java, protocole incomplet, signature invalide, signataires
multiples, rotation ou certificat différent : aucun APK publié. Aucun repli vers
une extraction non vérifiée du certificat n’est prévu.

## Protection des prochains ZIP

Le packaging exclut les conteneurs de clé, fichiers de secrets locaux, caches,
APK/AAB et archives imbriquées. Il conserve le wrapper Gradle et la référence
publique. Il refuse les liens symboliques, les chemins ZIP dangereux et les
copies détectées de clés privées PEM, keystores renommés/encodés en Base64 et
mots de passe littéraux. Le ZIP est rescanné après sa création avant remplacement
de l’archive de destination. Un refus laisse l’archive précédente intacte.

Ce contrôle ciblé n’est pas une détection universelle de tout secret arbitraire
ou obfusqué. Le contrôle de cette livraison vérifie aussi l’absence des octets
de la clé originale, de sa représentation Base64 et du mot de passe historique,
sans en afficher les valeurs. Aucun secret ne figure dans les fixtures des tests.

La confidentialité passée est déclarée par le propriétaire. Si une exposition
ancienne est découverte ou devient incertaine, ce sujet doit rester ouvert :
nettoyer ce ZIP n’efface ni l’historique Git ni des copies antérieures. Une
rotation éventuelle est une décision séparée, jamais automatique, notamment
pour cette distribution directe où la continuité dépend de la clé existante.

Référence GitHub :
https://docs.github.com/fr/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets
