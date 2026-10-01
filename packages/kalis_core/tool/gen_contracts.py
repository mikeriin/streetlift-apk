#!/usr/bin/env python3
"""Génère le code Dart des contrats de kalis_core depuis contracts_spec.py.

    python3 packages/kalis_core/tool/gen_contracts.py          # écrit les fichiers
    python3 packages/kalis_core/tool/gen_contracts.py --check  # vérifie qu'ils sont à jour

Sorties : lib/src/generated/*.g.dart (types, enums, registre des codes de
raison), lib/src/testing/arbitrary.g.dart (valeurs aléatoires seedées pour
les tests de propriétés), docs/TYPES.md (tableaux de référence).

Le code livré est celui-ci passé par `dart format` (CI) ; `--check` compare
donc sans tenir compte des blancs ni des virgules finales.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import contracts_spec as spec  # noqa: E402

PKG = Path(__file__).resolve().parents[1]
GEN = PKG / "lib/src/generated"
HEADER = "// GÉNÉRÉ par tool/gen_contracts.py depuis tool/contracts_spec.py — ne pas modifier à la main.\n"

SCALARS = {"int": "int", "double": "double", "bool": "bool", "string": "String",
           "date": "CivilDate", "json": "Map<String, Object?>"}


class T:
    """Type de champ décomposé."""

    def __init__(self, text: str):
        self.optional = text.endswith("?")
        t = text.rstrip("?")
        self.is_list = t.startswith("list:")
        if self.is_list:
            t = t[5:]
        self.kind, _, self.name = t.partition(":")  # int|double|…|enum|obj
        if self.is_list and self.optional:
            raise ValueError("liste optionnelle non prévue : " + text)

    @property
    def elem(self) -> str:
        return SCALARS[self.kind] if self.kind in SCALARS else self.name

    @property
    def dart(self) -> str:
        d = f"List<{self.elem}>" if self.is_list else self.elem
        return d + ("?" if self.optional else "")


def q(s: str) -> str:
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$") + "'"


def num(v) -> str:
    return str(int(v)) if float(v) == int(v) and not isinstance(v, float) else repr(float(v))


def doc_lines(doc: str, indent: str = "") -> str:
    return "".join(f"{indent}/// {l}\n" for l in wrap(doc))


def wrap(text: str, width: int = 74) -> list[str]:
    out, cur = [], ""
    for w in text.split():
        if cur and len(cur) + 1 + len(w) > width:
            out.append(cur)
            cur = w
        else:
            cur = (cur + " " + w).strip()
    return out + ([cur] if cur else [])


# ---------------------------------------------------------------- enums ----

def gen_enums() -> str:
    o = [HEADER, "part of '../contracts.dart';\n"]
    for e in spec.ENUMS:
        o.append("\n" + doc_lines(e.doc))
        o.append(f"enum {e.name} {{\n")
        for k, (ident, code) in enumerate(e.values):
            o.append(f"  {ident}({q(code)}){';' if k == len(e.values) - 1 else ','}\n")
        o.append(f"\n  const {e.name}(this.code);\n\n")
        o.append("  /// Code stable utilisé dans le JSON.\n  final String code;\n\n")
        o.append(f"  /// Valeur d'un code ; [FormatException] si le code est inconnu.\n")
        o.append(f"  static {e.name} fromCode(String code) {{\n")
        o.append(f"    for (final v in values) {{\n      if (v.code == code) {{\n        return v;\n      }}\n    }}\n")
        o.append(f"    throw FormatException('{e.name} : code inconnu', code);\n  }}\n}}\n")
    return "".join(o)


# ---------------------------------------------------------------- types ----

def from_json_expr(f: spec.Field) -> str:
    t, k = T(f.type), q(f.name)
    if t.is_list:
        conv = {
            "int": f"jsonAsInt(v, {k})", "double": f"jsonAsDouble(v, {k})",
            "bool": f"jsonAsBool(v, {k})", "string": f"jsonAsString(v, {k})",
            "date": f"CivilDate.parse(jsonAsString(v, {k}))", "json": f"jsonAsObject(v, {k})",
            "enum": f"{t.name}.fromCode(jsonAsString(v, {k}))",
            "obj": f"{t.name}.fromJson(jsonAsObject(v, {k}))",
        }[t.kind]
        return f"jsonList(json, {k}, (v) => {conv})"
    suffix = "OrNull" if t.optional else ""
    simple = {"int": "jsonInt", "double": "jsonDouble", "bool": "jsonBool", "string": "jsonString",
              "date": "jsonDate", "json": "jsonObject"}
    if t.kind in simple:
        return f"{simple[t.kind]}{suffix}(json, {k})"
    if t.kind == "enum":
        return f"jsonEnum{suffix}(json, {k}, {t.name}.fromCode)"
    return f"jsonObj{suffix}(json, {k}, {t.name}.fromJson)"


def to_json_value(t: T, var: str) -> str:
    if t.is_list:
        inner = {"enum": "e.code", "obj": "e.toJson()", "date": "e.iso"}.get(t.kind, "e")
        return f"[for (final e in {var}) {inner}]"
    return {"enum": f"{var}.code", "obj": f"{var}.toJson()", "date": f"{var}.iso"}.get(t.kind, var)


def eq_expr(f: spec.Field) -> str:
    t = T(f.type)
    if t.is_list:
        return f"jsonListEquals({f.name}, other.{f.name})"
    if t.kind == "json":
        return f"jsonDeepEquals({f.name}, other.{f.name})"
    return f"{f.name} == other.{f.name}"


def hash_expr(f: spec.Field) -> str:
    t = T(f.type)
    if t.is_list:
        return f"Object.hashAll({f.name})"
    if t.kind == "json":
        return f"jsonDeepHash({f.name})"
    return f.name


def validation(ty: spec.Type, f: spec.Field) -> list[str]:
    t, n = T(f.type), f.name
    p = f"'$path.{n}'"
    out: list[str] = []
    lo = "null" if f.min is None else num(f.min)
    hi = "null" if f.max is None else num(f.max)
    if f.name == "schemaVersion":
        return [f"checkRange(out, {p}, {n}, {lo}, currentSchemaVersion);"]

    def guarded(stmt: str) -> str:
        if t.optional:
            return f"if ({n} case final v?) {{ {stmt.replace('@', 'v')} }}"
        return stmt.replace("@", n)

    if t.is_list:
        if f.min_len is not None or f.max_len is not None:
            out.append(f"checkLength(out, {p}, {n}.length, {f.min_len if f.min_len is not None else 'null'}, {f.max_len if f.max_len is not None else 'null'});")
        if t.kind == "obj":
            out.append(f"for (var i = 0; i < {n}.length; i++) {{ {n}[i].collectViolations('$path.{n}[$i]', out); }}")
        elif t.kind == "string":
            out.append(f"for (var i = 0; i < {n}.length; i++) {{ checkLength(out, '$path.{n}[$i]', {n}[i].length, 1, null); }}")
        return out
    if t.kind in ("int", "double"):
        if f.min is not None or f.max is not None or t.kind == "double":
            out.append(guarded(f"checkRange(out, {p}, @, {lo}, {hi});"))
    elif t.kind == "string":
        mn = f.min_len if f.min_len is not None else (1 if f.ref else None)
        if mn is not None or f.max_len is not None:
            out.append(guarded(f"checkLength(out, {p}, @.length, {mn if mn is not None else 'null'}, {f.max_len if f.max_len is not None else 'null'});"))
    elif t.kind == "json":
        out.append(guarded(f"checkJson(out, {p}, @);"))
    elif t.kind == "obj":
        out.append(guarded(f"@.collectViolations({p}, out);"))
    return out


def collect_ids(f: spec.Field) -> str | None:
    t, n = T(f.type), f.name
    if f.ref == "exercise":
        if t.is_list:
            return f"out.addAll({n});"
        return f"if ({n} case final v?) {{ out.add(v); }}" if t.optional else f"out.add({n});"
    if t.kind == "obj":
        if t.is_list:
            return f"for (final e in {n}) {{ e.collectExerciseIds(out); }}"
        return f"{n}?.collectExerciseIds(out);" if t.optional else f"{n}.collectExerciseIds(out);"
    return None


def gen_type(ty: spec.Type) -> str:
    o = ["\n" + doc_lines(ty.doc)]
    if ty.invariants:
        o.append("///\n")
        for inv in ty.invariants:
            o.append(doc_lines("Invariant : " + inv))
    o.append(f"final class {ty.name} {{\n")
    # constructeur
    o.append(f"  const {ty.name}({{\n")
    for f in ty.fields:
        t = T(f.type)
        if f.name == "schemaVersion":
            o.append("    this.schemaVersion = currentSchemaVersion,\n")
        elif t.optional:
            o.append(f"    this.{f.name},\n")
        else:
            o.append(f"    required this.{f.name},\n")
    o.append("  });\n\n")
    # fromJson
    o.append(f"  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.\n")
    o.append(f"  /// Les champs inconnus sont ignorés (évolution additive).\n")
    o.append(f"  factory {ty.name}.fromJson(Map<String, Object?> json) {{\n    return {ty.name}(\n")
    for f in ty.fields:
        o.append(f"      {f.name}: {from_json_expr(f)},\n")
    o.append("    );\n  }\n\n")
    if ty.schema_version is not None:
        o.append(f"  /// Version courante du schéma JSON de ce type.\n  static const int currentSchemaVersion = {ty.schema_version};\n\n")
    for f in ty.fields:
        o.append(doc_lines(f.doc, "  "))
        o.append(f"  final {T(f.type).dart} {f.name};\n\n")
    # toJson
    o.append("  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.\n")
    o.append("  Map<String, Object?> toJson() {\n    return <String, Object?>{\n")
    for f in ty.fields:
        t = T(f.type)
        if t.optional:
            o.append(f"      if ({f.name} case final v?) {q(f.name)}: {to_json_value(t, 'v')},\n")
        else:
            o.append(f"      {q(f.name)}: {to_json_value(t, f.name)},\n")
    o.append("    };\n  }\n\n")
    # copyWith
    o.append("  /// Copie modifiée ; un champ optionnel peut être remis à `null`.\n")
    o.append(f"  {ty.name} copyWith({{\n")
    for f in ty.fields:
        t = T(f.type)
        o.append(f"    Object? {f.name} = unset,\n" if t.optional else f"    {t.dart}? {f.name},\n")
    o.append(f"  }}) {{\n    return {ty.name}(\n")
    for f in ty.fields:
        t = T(f.type)
        if t.optional:
            o.append(f"      {f.name}: identical({f.name}, unset) ? this.{f.name} : {f.name} as {t.dart},\n")
        else:
            o.append(f"      {f.name}: {f.name} ?? this.{f.name},\n")
    o.append("    );\n  }\n\n")
    # validation
    o.append("  /// Violations des invariants du contrat (liste vide = valeur valide).\n")
    o.append("  List<Violation> validate() {\n    final out = <Violation>[];\n    collectViolations(r'$', out);\n    return out;\n  }\n\n")
    o.append("  /// Ajoute à [out] les violations de cette valeur, située à [path].\n")
    o.append("  void collectViolations(String path, List<Violation> out) {\n")
    for f in ty.fields:
        for line in validation(ty, f):
            o.append(f"    {line}\n")
    if ty.custom:
        o.append(f"    _validate{ty.name}(this, path, out);\n")
    o.append("  }\n\n")
    # ids d'exercices
    o.append("  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.\n")
    o.append("  void collectExerciseIds(Set<String> out) {\n")
    for f in ty.fields:
        line = collect_ids(f)
        if line:
            o.append(f"    {line}\n")
    o.append("  }\n\n")
    # égalité
    o.append("  @override\n  bool operator ==(Object other) {\n")
    o.append(f"    return identical(this, other) || other is {ty.name}")
    for f in ty.fields:
        o.append(f" && {eq_expr(f)}")
    o.append(";\n  }\n\n")
    o.append("  @override\n  int get hashCode => Object.hashAll(<Object?>[")
    o.append(", ".join(hash_expr(f) for f in ty.fields))
    o.append("]);\n\n")
    o.append(f"  @override\n  String toString() => '{ty.name}(${{toJson()}})';\n}}\n")
    return "".join(o)


def gen_module(module: str) -> str:
    o = [HEADER, "part of '../contracts.dart';\n"]
    for ty in spec.TYPES:
        if ty.module == module:
            o.append(gen_type(ty))
    return "".join(o)


# ------------------------------------------------------- codes de raison ----

PARAM_TYPES = {"int": "integer", "double": "number", "string": "text", "bool": "flag", "exercise": "exerciseId"}


def const_name(code: str) -> str:
    return spec.camel(code.replace(".", "_"))


def gen_reasons() -> str:
    o = [HEADER, "part of '../contracts.dart';\n\n"]
    o.append("/// Codes de raison : identifiants stables, sans texte.\nabstract final class ReasonCodes {\n")
    for code, params, doc in spec.REASONS:
        o.append(doc_lines(doc, "  "))
        o.append(f"  static const String {const_name(code)} = {q(code)};\n\n")
    o.append("}\n\n/// Registre des codes de raison et de leurs paramètres typés.\n")
    o.append("const List<ReasonSpec> reasonRegistry = <ReasonSpec>[\n")
    for code, params, doc in spec.REASONS:
        ps = ", ".join(f"{q(k)}: ReasonParamType.{PARAM_TYPES[v]}" for k, v in params.items())
        o.append(f"  ReasonSpec(ReasonCodes.{const_name(code)}, <String, ReasonParamType>{{{ps}}}),\n")
    o.append("];\n")
    return "".join(o)


# ------------------------------------------------------------ arbitrary ----

def arb_scalar(ty: spec.Type, f: spec.Field, t: T) -> str:
    if f.name == "schemaVersion":
        return f"{ty.name}.currentSchemaVersion"
    if t.kind == "int":
        lo = int(f.min) if f.min is not None else 0
        hi = int(f.max) if f.max is not None else lo + 1000
        return f"arbInt(r, {lo}, {hi})"
    if t.kind == "double":
        lo = float(f.min) if f.min is not None else -1000.0
        hi = float(f.max) if f.max is not None else lo + 2000.0
        return f"arbDouble(r, {lo!r}, {hi!r})"
    if t.kind == "bool":
        return "r.nextBool()"
    if t.kind == "string":
        if f.ref == "exercise":
            return "arbId(r)"
        return f"arbString(r, {f.min_len if not t.is_list and f.min_len is not None else 0}, {f.max_len if not t.is_list and f.max_len is not None else 12})"
    if t.kind == "date":
        return "arbDate(r)"
    if t.kind == "json":
        return "arbJson(r)"
    if t.kind == "enum":
        return f"arbEnum(r, {t.name}.values)"
    return f"arbitrary{t.name}(r)"


def gen_arbitrary() -> str:
    o = [HEADER, "// Valeurs aléatoires seedées de chaque type du contrat (tests de propriétés).\n",
         "// Les bornes simples sont respectées ; les invariants croisés ne le sont pas\n",
         "// forcément : ces valeurs servent aux allers-retours JSON, pas à la validation.\n",
         "import 'dart:math';\n\nimport '../civil_date.dart';\nimport '../contracts.dart';\nimport 'arbitrary_base.dart';\n"]
    for ty in spec.TYPES:
        o.append(f"\n/// Valeur aléatoire de [{ty.name}].\n{ty.name} arbitrary{ty.name}(Random r) {{\n  return {ty.name}(\n")
        for f in ty.fields:
            t = T(f.type)
            base = arb_scalar(ty, f, t)
            if t.is_list:
                lo = f.min_len or 0
                hi = f.max_len if f.max_len is not None else max(lo, 3)
                expr = f"arbList(r, {lo}, {hi}, () => {base})"
            elif t.optional:
                expr = f"r.nextBool() ? null : {base}"
            else:
                expr = base
            o.append(f"    {f.name}: {expr},\n")
        o.append("  );\n}\n")
    o.append("\n/// Générateur, encodeur et décodeur de chaque type, pour les tests génériques.\n")
    o.append("final List<ContractCodec<Object>> contractCodecs = <ContractCodec<Object>>[\n")
    for ty in spec.TYPES:
        o.append(f"  ContractCodec<{ty.name}>({q(ty.name)}, arbitrary{ty.name}, (v) => v.toJson(), {ty.name}.fromJson, (v) => v.validate()),\n")
    o.append("];\n")
    # CivilDate import is used only through types; keep analyzer quiet.
    o.append("\n/// Jour civil aléatoire (réexporté pour les tests).\nCivilDate arbitraryCivilDate(Random r) => arbDate(r);\n")
    return "".join(o)


# ------------------------------------------------------------ TYPES.md ----

def type_label(text: str) -> str:
    t = T(text)
    base = {"date": "jour civil", "json": "objet JSON", "string": "texte", "int": "entier",
            "double": "nombre", "bool": "booléen"}.get(t.kind, f"`{t.name}`")
    return ("liste de " if t.is_list else "") + base


def constraints(f: spec.Field) -> str:
    c = []
    if f.min is not None and f.max is not None:
        c.append(f"{num(f.min)} à {num(f.max)}")
    elif f.min is not None:
        c.append(f"≥ {num(f.min)}")
    elif f.max is not None:
        c.append(f"≤ {num(f.max)}")
    if f.min_len is not None and f.max_len is not None:
        c.append(f"longueur {f.min_len} à {f.max_len}")
    elif f.min_len is not None:
        c.append(f"longueur ≥ {f.min_len}")
    elif f.max_len is not None:
        c.append(f"longueur ≤ {f.max_len}")
    if f.ref == "exercise":
        c.append("id du catalogue")
    return ", ".join(c) or "—"


def gen_types_md() -> str:
    titres = {"common": "Commun", "profile": "Profil d'athlète v2", "journal": "Journal",
              "plan": "Interface `plan` (kalis_plan, G4)", "adapt": "Interface `adapt` (kalis_adapt, G8)",
              "quest": "Interface `quest` (kalis_quest, G11)"}
    o = ["# Types des contrats de kalis_core\n\n",
         "Fichier généré par `tool/gen_contracts.py` depuis `tool/contracts_spec.py` — ne pas modifier à la main.\n\n",
         "Clé JSON = nom du champ. « Optionnel » : la clé est absente du JSON quand la valeur est nulle ",
         "(jamais de valeur par défaut). Les types racine portent `schemaVersion`.\n\n",
         "## Versions de schéma\n\n| Type | Version |\n| --- | ---: |\n"]
    for n, v in spec.SCHEMA_VERSIONS.items():
        o.append(f"| `{n}` | {v} |\n")
    for m in spec.MODULES:
        o.append(f"\n## {titres[m]}\n")
        for ty in spec.TYPES:
            if ty.module != m:
                continue
            o.append(f"\n### `{ty.name}`\n\n{ty.doc}\n\n| Champ | Type | Optionnel | Contraintes | Sens |\n| --- | --- | --- | --- | --- |\n")
            for f in ty.fields:
                o.append(f"| `{f.name}` | {type_label(f.type)} | {'oui' if f.type.endswith('?') else 'non'} | {constraints(f)} | {f.doc} |\n")
            for inv in ty.invariants:
                o.append(f"\nInvariant : {inv}\n")
    o.append("\n## Énumérations\n\nLe JSON porte le **code** ; l'ordre des valeurs est celui du contrat.\n\n| Enum | Codes | Sens |\n| --- | --- | --- |\n")
    for e in spec.ENUMS:
        o.append(f"| `{e.name}` | {', '.join('`' + c + '`' for _, c in e.values)} | {e.doc} |\n")
    o.append("\n## Registre des codes de raison\n\n| Code | Paramètres | Sens |\n| --- | --- | --- |\n")
    for code, params, doc in spec.REASONS:
        ps = ", ".join(f"`{k}` ({v})" for k, v in params.items()) or "—"
        o.append(f"| `{code}` | {ps} | {doc} |\n")
    return "".join(o)


def outputs() -> dict[Path, str]:
    out = {GEN / "enums.g.dart": gen_enums(), GEN / "reason_codes.g.dart": gen_reasons(),
           PKG / "lib/src/testing/arbitrary.g.dart": gen_arbitrary(),
           PKG / "docs/TYPES.md": gen_types_md()}
    for m in spec.MODULES:
        out[GEN / f"{m}.g.dart"] = gen_module(m)
    return out


def squeeze(text: str) -> str:
    """Forme insensible au formatage : sans blancs ni virgules finales."""
    t = re.sub(r"\s+", "", text)
    return re.sub(r",(?=[)\]}])", "", t)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    ok = True
    for path, text in outputs().items():
        if args.check:
            exact = path.suffix == ".md"
            actuel = path.read_text(encoding="utf-8") if path.exists() else ""
            if (actuel != text) if exact else (squeeze(actuel) != squeeze(text)):
                print(f"pas à jour : {path.relative_to(PKG)}")
                ok = False
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")
    print("à jour" if ok and args.check else ("écrit" if not args.check else "relancer tool/gen_contracts.py"))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
