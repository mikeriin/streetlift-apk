#!/usr/bin/env python3
"""Export concis d'un programme pour le panel de coachs virtuels.

Entrée : un fichier `programmes/<profil>.json` du rapport du banc
(`dart run bin/kalis_bench_cli.dart --rapport <dossier>`).
Sortie (stdout ou --sortie) : le même programme qu'en Markdown complet, mais
une semaine identique ou proche d'une semaine précédente est écrite « comme
semaine N, sauf … » (PIPELINE_CP.md §9 : exports concis). Rien n'est omis :
chaque différence d'exercice, de séries × répétitions, de charge, d'effort
visé ou de repos est listée.

usage : panel_export.py programme.json [--sortie fichier.md]
"""
import json
import sys

FIELDS = (("volume", "séries × rép."), ("load", "charge"),
          ("effort", "effort"), ("rest", "repos"), ("notes", "notes"))


def rest_text(seconds):
    if seconds is None:
        return "—"
    seconds = int(seconds)
    if seconds < 120:
        return f"{seconds} s"
    minutes, rem = divmod(seconds, 60)
    return f"{minutes} min" + (f" {rem} s" if rem else "")


def item_line(item):
    return ("| " + " | ".join([
        item["name"], item["volume"], item["load"], item["effort"],
        rest_text(item.get("rest")), item.get("notes", "") or "",
    ]) + " |")


def day_title(day):
    return (f"{day['day']} — {day['focus']} ({day['minutes']} min "
            f"disponibles, {day['estimated']} min estimées)")


def day_table(day):
    lines = ["| Exercice | Séries × répétitions | Charge | Effort visé | "
             "Repos | Notes |", "| --- | --- | --- | --- | --- | --- |"]
    lines += [item_line(i) for i in day["items"]]
    return lines


def day_key(day):
    return json.dumps([[i["id"], i["volume"], i["load"], i["effort"],
                        i.get("rest"), i.get("notes")] for i in day["items"]],
                      ensure_ascii=False)


def diff_day(day, ref):
    """Différences de `day` par rapport à `ref` (même jour d'une semaine
    précédente) ; `None` si les exercices ne se correspondent pas assez."""
    ref_by_id = {}
    for item in ref["items"]:
        ref_by_id.setdefault(item["id"], []).append(item)
    out, matched = [], 0
    used = {}
    for item in day["items"]:
        candidates = ref_by_id.get(item["id"], [])
        k = used.get(item["id"], 0)
        if k < len(candidates):
            used[item["id"]] = k + 1
            matched += 1
            before = candidates[k]
            changes = []
            for field, label in FIELDS:
                a, b = before.get(field), item.get(field)
                if a != b:
                    if field == "rest":
                        a, b = rest_text(a), rest_text(b)
                    changes.append(f"{label} : {b} (au lieu de {a})")
            if changes:
                out.append(f"  - {item['name']} — " + " ; ".join(changes))
        else:
            out.append("  - ajouté : " + item_line(item).strip("| ").replace(" | ", " · "))
    for ident, items in ref_by_id.items():
        for item in items[used.get(ident, 0):]:
            out.append(f"  - retiré : {item['name']}")
    if matched * 2 < max(len(day["items"]), len(ref["items"])):
        return None
    return out


def week_cost(week, ref):
    if len(week["days"]) != len(ref["days"]):
        return None
    total = 0
    for day, other in zip(week["days"], ref["days"]):
        if day_key(day) == day_key(other):
            continue
        d = diff_day(day, other)
        if d is None:
            return None
        total += len(d)
    return total


def render(program):
    out = [f"# Programme — {program['title']}", "", program["summary"], "",
           "## Profil", ""]
    out += program["profile"]
    weeks = program["weeks"]
    out += ["", "## Vue d'ensemble", "",
            f"{len(weeks)} semaines. « Séries dures » : séries de "
            "renforcement à 4 répétitions en réserve ou moins.", "",
            "| Semaine | Bloc | Nature | Séances | Séries dures |",
            "| --- | --- | --- | --- | --- |"]
    event = program.get("eventWeek")
    for w in weeks:
        kind = w["kind"] + (" — ÉCHÉANCE" if event == w["week"] else "")
        out.append(f"| {w['week']} | {w['block']} | {kind} | "
                   f"{len(w['days'])} | {w['hardSets']} |")
    for title, key in (("Saison", "season"),
                       ("Échelles des figures", "ladders")):
        if program.get(key):
            out += ["", f"## {title}", ""] + list(program[key])
    if program.get("rules"):
        out += ["", "## Règles du programme", ""]
        out += [f"- {r}" for r in program["rules"]]
    for index, w in enumerate(weeks):
        kind = w["kind"] + (" — ÉCHÉANCE" if event == w["week"] else "")
        out += ["", f"## Semaine {w['week']} — {kind} (bloc {w['block']})", ""]
        best, best_cost = None, None
        for ref in weeks[:index]:
            cost = week_cost(w, ref)
            if cost is not None and (best_cost is None or cost <= best_cost):
                best, best_cost = ref, cost
        full_cost = sum(len(d["items"]) for d in w["days"])
        if best is None or best_cost > full_cost:
            for day in w["days"]:
                out += [f"### {day_title(day)}", ""] + day_table(day) + [""]
            continue
        if best_cost == 0:
            out.append(f"Comme la semaine {best['week']}, sans aucun "
                       "changement.")
            continue
        out.append(f"Comme la semaine {best['week']}, sauf :")
        for day, other in zip(w["days"], best["days"]):
            if day_key(day) == day_key(other):
                continue
            out.append(f"- {day['day']} ({day['estimated']} min estimées) :")
            out += diff_day(day, other)
    return "\n".join(out).rstrip() + "\n"


def main(argv):
    if len(argv) < 2 or argv[1] in ("-h", "--help"):
        print(__doc__)
        return 0 if len(argv) >= 2 else 2
    with open(argv[1], encoding="utf-8") as f:
        program = json.load(f)
    text = render(program)
    if "--sortie" in argv:
        with open(argv[argv.index("--sortie") + 1], "w", encoding="utf-8") as f:
            f.write(text)
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
