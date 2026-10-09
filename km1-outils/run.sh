#!/bin/bash
# run.sh [graines] : évaluation courte SET9 + tests
S=${1:-2}
python3 essai2.py $(cat SET9) reference $S 2>&1 | grep -E "loadedMain|k=6|modele|ecart|echeance" | head -9
python3 diag_tests.py $(cat SET9) 1 | tail -6
