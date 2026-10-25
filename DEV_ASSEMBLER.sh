# Assemblage du run KM7 b : variante « garde l'écrit une fois sur deux », bilan versé, témoin corrigé (copie du
# moteur avec ses extensions, mêmes événements avant le plan : réponse au diagnostic de la surveillance).
O=$PWD/ci-out/packages
R=$PWD/packages/kalis_adapt/reference
mkdir -p $O/km7
(cd $R && python3 -m banc.km7_garde --nom verse --sortie $O/km7/garde_verse.json $O/py_verse) || echo "garde verse : échec"
(cd $R && python3 -m banc.km7_garde --nom verse_g0_17 --graines 0-17 --sortie $O/km7/garde_verse_g0_17.json $O/py_verse) || echo "garde verse 0-17 : échec"
rm -rf $O/py_verse
