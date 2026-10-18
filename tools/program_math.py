"""Conversions testables, indépendantes du classeur et de l'interface."""
from decimal import Decimal, ROUND_HALF_UP
import re


def round_step(value, step):
    step = Decimal(str(step))
    if step <= 0:
        raise ValueError('Le pas doit être positif')
    return float((Decimal(str(value)) / step).quantize(Decimal('1'), rounding=ROUND_HALF_UP) * step)


def rest_seconds(text):
    if not isinstance(text, str):
        return None
    text = text.strip().lower().replace('\u00a0', ' ').replace('–', '-')
    if text in ('', '-', '—') or 'après' in text or 'au total' in text:
        return None
    minutes = re.search(r'(\d+)(?:\s*-\s*(\d+))?\s*min', text)
    seconds = re.search(r'(\d+)(?:\s*-\s*(\d+))?\s*s\b', text)
    total = 0
    if minutes:
        total += int(minutes.group(2) or minutes.group(1)) * 60
    if seconds:
        total += int(seconds.group(2) or seconds.group(1))
    return total if minutes or seconds else None
