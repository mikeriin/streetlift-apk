"""Validation structurelle d'un objet JSON contre contracts_spec.py.

Sert au générateur de jeux de données (les invariants croisés sont vérifiés
par le paquet Dart en CI) : types, champs obligatoires, bornes, codes d'enum,
aucune clé inconnue, champs optionnels absents plutôt que nuls.
"""
from __future__ import annotations

import re

import contracts_spec as spec

_TYPES = {t.name: t for t in spec.TYPES}
_ENUMS = {e.name: {c for _, c in e.values} for e in spec.ENUMS}
_DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def _scalar(kind: str, name: str, v, f: spec.Field, path: str, err: list[str]) -> None:
    if kind == "int":
        if not isinstance(v, int) or isinstance(v, bool):
            err.append(f"{path} : entier attendu")
            return
    elif kind == "double":
        if not isinstance(v, (int, float)) or isinstance(v, bool):
            err.append(f"{path} : nombre attendu")
            return
    elif kind == "bool":
        if not isinstance(v, bool):
            err.append(f"{path} : booléen attendu")
        return
    elif kind == "string":
        if not isinstance(v, str):
            err.append(f"{path} : texte attendu")
            return
        mn = f.min_len if f.min_len is not None else (1 if f.ref else None)
        if mn is not None and len(v) < mn:
            err.append(f"{path} : trop court")
        if f.max_len is not None and len(v) > f.max_len:
            err.append(f"{path} : trop long")
        return
    elif kind == "date":
        if not isinstance(v, str) or not _DATE.match(v):
            err.append(f"{path} : jour civil attendu")
        return
    elif kind == "json":
        if not isinstance(v, dict):
            err.append(f"{path} : objet attendu")
        return
    elif kind == "enum":
        if v not in _ENUMS[name]:
            err.append(f"{path} : code {v!r} inconnu de {name}")
        return
    elif kind == "obj":
        validate(name, v, path, err)
        return
    if f.min is not None and v < f.min:
        err.append(f"{path} : {v} < {f.min}")
    if f.max is not None and v > f.max:
        err.append(f"{path} : {v} > {f.max}")


def validate(type_name: str, obj, path: str = "$", err: list[str] | None = None) -> list[str]:
    err = [] if err is None else err
    ty = _TYPES[type_name]
    if not isinstance(obj, dict):
        err.append(f"{path} : objet {type_name} attendu")
        return err
    connus = {f.name for f in ty.fields}
    for k in obj:
        if k not in connus:
            err.append(f"{path}.{k} : champ inconnu de {type_name}")
    for f in ty.fields:
        text = f.type
        optional = text.endswith("?")
        text = text.rstrip("?")
        is_list = text.startswith("list:")
        if is_list:
            text = text[5:]
        kind, _, name = text.partition(":")
        p = f"{path}.{f.name}"
        if f.name not in obj:
            if not optional:
                err.append(f"{p} : champ obligatoire absent")
            continue
        v = obj[f.name]
        if v is None:
            err.append(f"{p} : nul (un champ optionnel absent est omis)")
            continue
        if f.name == "schemaVersion" and isinstance(v, int) and not (
                (f.min if f.min is not None else ty.schema_version) <= v <= ty.schema_version):
            err.append(f"{p} : version {v} hors de {f.min}..{ty.schema_version}")
        if is_list:
            if not isinstance(v, list):
                err.append(f"{p} : liste attendue")
                continue
            if f.min_len is not None and len(v) < f.min_len:
                err.append(f"{p} : liste trop courte")
            if f.max_len is not None and len(v) > f.max_len:
                err.append(f"{p} : liste trop longue")
            item_field = spec.Field(f.name, text, "", ref=f.ref)
            for i, item in enumerate(v):
                _scalar(kind, name, item, item_field, f"{p}[{i}]", err)
        else:
            _scalar(kind, name, v, f, p, err)
    if ty.variants:
        disc, rules = ty.variants
        variante = obj.get(disc)
        if variante in rules:
            requis, permis = rules[variante]
            controles = {n for r, a in rules.values() for n in r + a}
            for n in sorted(controles):
                if n in obj and n not in requis and n not in permis:
                    err.append(f"{path}.{n} : champ inattendu pour {variante}")
                elif n not in obj and n in requis:
                    err.append(f"{path}.{n} : champ obligatoire pour {variante}")
    return err


def exercise_ids(type_name: str, obj, out: set[str]) -> set[str]:
    ty = _TYPES[type_name]
    for f in ty.fields:
        if f.name not in obj:
            continue
        text = f.type.rstrip("?")
        is_list = text.startswith("list:")
        if is_list:
            text = text[5:]
        kind, _, name = text.partition(":")
        v = obj[f.name]
        if f.ref == "exercise":
            out.update(v if is_list else [v])
        elif kind == "obj":
            for item in (v if is_list else [v]):
                exercise_ids(name, item, out)
    return out
