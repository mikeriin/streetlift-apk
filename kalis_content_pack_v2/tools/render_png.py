"""Rendu PNG d'un fichier HTML (ou SVG) par Chromium sans interface (Playwright).

Usage : python3 tools/render_png.py <entree.html|svg> <sortie.png> [largeur] [hauteur]
Sert au contrôle visuel obligatoire (atlas, planches d'exercices).
"""
import os
import sys

from playwright.sync_api import sync_playwright

EXEC = "/opt/pw-browsers/chromium"


def _exe():
    for root in ("/opt/pw-browsers",):
        for d in sorted(os.listdir(root)):
            if d.startswith("chromium-"):
                for cand in ("chrome-linux/chrome", "chrome-linux64/chrome"):
                    p = os.path.join(root, d, cand)
                    if os.path.exists(p):
                        return p
    return None


def render(src, dst, width=1800, height=None, full=True):
    src = os.path.abspath(src)
    with sync_playwright() as p:
        kw = {}
        exe = _exe()
        if exe:
            kw["executable_path"] = exe
        browser = p.chromium.launch(**kw)
        page = browser.new_page(viewport={"width": width, "height": height or 1000}, device_scale_factor=1)
        page.goto("file://" + src)
        page.wait_for_timeout(150)
        page.screenshot(path=dst, full_page=full)
        browser.close()


if __name__ == "__main__":
    w = int(sys.argv[3]) if len(sys.argv) > 3 else 1800
    h = int(sys.argv[4]) if len(sys.argv) > 4 else None
    render(sys.argv[1], sys.argv[2], w, h)
    print(dst := sys.argv[2])
