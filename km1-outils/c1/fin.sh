#!/bin/bash
cd /home/claude/moteurs/packages/kalis_adapt/reference
python3 -m banc.adversaire --comparer donnees/adversaires_temoin.json.gz --rapport donnees/comparaison_adversaires.json > /home/claude/km1-outils/c1/fin_adv.log 2>&1
python3 -m banc.criteres_moteur --sortie donnees/criteres_moteur.json > /home/claude/km1-outils/c1/fin_cm.log 2>&1
python3 -m banc.validation_koach > /home/claude/km1-outils/c1/fin_val.log 2>&1
python3 fixtures/generer.py > /home/claude/km1-outils/c1/fin_fix.log 2>&1
python3 -m pytest tests -q > /home/claude/km1-outils/c1/fin_pytest.log 2>&1
echo FINI > /home/claude/km1-outils/c1/fin.ok
