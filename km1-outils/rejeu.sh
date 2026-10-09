#!/bin/bash
# Rejeu privé du journal (agrégats publics, détails sous /tmp).
cd /home/claude/moteurs/packages/kalis_adapt/reference
python3 -I rejeu/walk_forward.py /tmp/km1-journal/x/journal_*.json --programme /tmp/km1-app/prog.json.gz --koach-programme /tmp/km1-app/koach_program.json.gz --correspondance /tmp/km1-app/corr.json --depuis ${DEPUIS:-12} --sortie ${SORTIE:-donnees/rejeu_journal_agregats.json} --details /tmp/km1-journal/analyse/ "$@"
