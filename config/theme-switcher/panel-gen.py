#!/usr/bin/env python3
"""Genera panel.json para el panel de Quickshell.

Uso: panel-gen.py <dir-theme-switcher> [id-activo]
"""
import json
import os
import sys

base = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/.config/theme-switcher")
current = sys.argv[2] if len(sys.argv) > 2 else ""


def load(path):
    data = {}
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            data[key.strip()] = os.path.expanduser(os.path.expandvars(value.strip().strip('"')))
    return data


def item_for(path, name):
    data = load(path)
    return {
        "id": data.get("ID", name[:-5]),
        "name": data.get("NAME", name[:-5]),
        "bg": data.get("BG", "#0b1220"),
        "panel": data.get("PANEL", "#111a2e"),
        "panel2": data.get("PANEL2", "#16223a"),
        "border": data.get("BORDER", "#1b2a44"),
        "accent": data.get("ACCENT", "#61afef"),
        "text": data.get("TEXT", "#e6e8ee"),
        "dim": data.get("DIM", "#5b6b8c"),
        "warn": data.get("WARN", "#e06c75"),
    }


themes = []
for filename in sorted(os.listdir(os.path.join(base, "themes"))):
    if filename.endswith(".conf"):
        themes.append(item_for(os.path.join(base, "themes", filename), filename))

if not current:
    try:
        with open(os.path.join(base, "current"), encoding="utf-8") as fh:
            current = fh.read().strip()
    except OSError:
        current = ""

active = next((t for t in themes if t["id"] == current), None)
if active is None and themes:
    active = themes[0]

print(json.dumps({"current": active, "themes": themes}, ensure_ascii=False))
