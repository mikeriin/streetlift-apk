#!/bin/bash
# q.sh <nom> <graines> [SETP] [PATCH] : lance diag6 sur tous les profils, écrit tmp_<nom>.pkl et tmp_<nom>.log
cd /home/claude/km1-outils/c1
SETP="$3" PATCH="$4" OUT=tmp_$1.pkl python3 run6.py tous $2 > tmp_$1.log 2>&1
python3 ana.py tmp_$1.pkl >> tmp_$1.log 2>&1
