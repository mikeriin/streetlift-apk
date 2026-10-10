# -*- coding: utf-8 -*-
"""Rejeu walk-forward d'un journal de l'application (brique 8 du cahier KM) :
conversion de l'export de l'application en événements du journal de Koach
(`journal_app`) et rejeu avec mesures de prévision (`walk_forward`).

Aucune donnée personnelle dans ce paquet : il lit un export fourni en
argument et n'écrit que des agrégats (les détails série par série ne
s'écrivent que dans un dossier privé désigné explicitement)."""
