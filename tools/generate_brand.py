"""Icônes et marque depuis le masque du logo (assets/icon/logo_mask.png).

5.10.0 : nouveau logo du propriétaire (30/09/2026 : poirier formant le K,
source `tools/logo_source.png`), couleur #5E1615 (Rouge Kalis). Dépendance :
Pillow."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/icon'
RES = ROOT / 'android/app/src/main/res'
ACCENT = '#5E1615'
BACKGROUND = '#F4F4F4'


def tint(mask, color=ACCENT):
    result = Image.new('RGBA', mask.size, color)
    result.putalpha(mask)
    return result


def fit_mark(mask, size, color=ACCENT, coverage=.80):
    source = tint(mask.crop(mask.getbbox()), color)
    source.thumbnail((round(size * coverage), round(size * coverage)), Image.Resampling.LANCZOS)
    result = Image.new('RGBA', (size, size))
    result.alpha_composite(source, ((size - source.width) // 2, (size - source.height) // 2))
    return result


PLAY = ROOT / 'docs/play'
LIGHT = '#F4F4F4'


def feature_graphic(output=PLAY / 'feature_graphic_1024x500.png'):
    """L13 (KT-076) : visuel Google Play 1024 × 500, fond uni bordeaux et
    logo clair centré ; ni illustration, ni texte. PNG 24 bits sans alpha."""
    mask = Image.open(ASSETS / 'logo_mask.png').convert('L')
    graphic = Image.new('RGBA', (1024, 500), ACCENT)
    mark = tint(mask.crop(mask.getbbox()), LIGHT)
    mark.thumbnail((300, 300), Image.Resampling.LANCZOS)
    graphic.alpha_composite(mark, ((1024 - mark.width) // 2, (500 - mark.height) // 2))
    output.parent.mkdir(parents=True, exist_ok=True)
    graphic.convert('RGB').save(output, optimize=True)
    return output


def main():
    import sys
    if '--play' in sys.argv[1:]:
        print(f'Visuel Google Play : {feature_graphic().relative_to(ROOT)}')
        return
    mask = Image.open(ASSETS / 'logo_mask.png').convert('L')
    foreground = tint(mask)
    foreground.save(ASSETS / 'icon_fg.png')
    tint(mask.crop(mask.getbbox())).save(ASSETS / 'logo_mark.png')
    classic = Image.new('RGBA', (1024, 1024), BACKGROUND)
    classic.alpha_composite(fit_mark(mask, 1024))
    classic.convert('RGB').save(ASSETS / 'icon.png')
    (ASSETS / 'logo.svg').unlink(missing_ok=True)
    for density, size, fg_size in [('mdpi', 48, 108), ('hdpi', 72, 162), ('xhdpi', 96, 216), ('xxhdpi', 144, 324), ('xxxhdpi', 192, 432)]:
        classic.resize((size, size), Image.Resampling.LANCZOS).convert('RGB').save(RES / f'mipmap-{density}/ic_launcher.png')
        directory = RES / f'drawable-{density}'
        directory.mkdir(parents=True, exist_ok=True)
        foreground.resize((fg_size, fg_size), Image.Resampling.LANCZOS).save(directory / 'ic_launcher_foreground.png')
        tint(mask, 'white').resize((fg_size, fg_size), Image.Resampling.LANCZOS).save(directory / 'ic_launcher_monochrome.png')
        fit_mark(mask, size // 2, 'white', .96).save(directory / 'ic_stat_kalis.png')
    (RES / 'drawable/ic_stat_kalis.xml').unlink(missing_ok=True)
    (RES / 'values/colors.xml').write_text(f'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">{BACKGROUND}</color>
    <color name="launch_background_color">#121212</color>
</resources>
''')
    print('Logo (tools/logo_source.png, 30/09/2026) teinté en #5E1615 ; icônes Android et notifications générées.')


if __name__ == '__main__':
    main()
