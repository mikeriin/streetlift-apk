"""Recolore le logo historique sans redessiner sa silhouette. Dépendance : Pillow."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/icon'
RES = ROOT / 'android/app/src/main/res'
ACCENT = '#6B0C0C'
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


def main():
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
    print('Silhouette historique recolorée en #6B0C0C ; icônes Android et notifications générées.')


if __name__ == '__main__':
    main()
