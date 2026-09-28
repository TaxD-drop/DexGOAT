#!/usr/bin/env python3
"""Valida a geometria responsiva e gera uma prévia SVG do DeGOAT Explorer."""

from __future__ import annotations

from html import escape
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "responsive-preview.svg"

PADDING = 12
INITIAL = (980, 620)
MINIMUM_EDITOR = 280
MOBILE_WIDTH = 760
MOBILE_HEIGHT = 520
STACK_WIDTH = 620
MOBILE_RATIO = 0.34
DESKTOP_EXPLORER = 330

VIEWPORTS = [
	("small portrait", 360, 800),
	("common portrait", 412, 915),
	("small landscape", 800, 360),
    ("captura landscape", 1024, 461),
	("laptop/tablet", 1280, 720),
    ("desktop", 1440, 900),
]


def layout(viewport_width: int, viewport_height: int) -> dict[str, int | bool]:
    width = min(INITIAL[0], viewport_width - PADDING * 2)
    height = min(INITIAL[1], viewport_height - PADDING * 2)
    compact = width <= MOBILE_WIDTH or height <= MOBILE_HEIGHT
    narrow = width <= STACK_WIDTH
    if narrow:
        explorer = width
    else:
        requested = int(width * MOBILE_RATIO) if compact else DESKTOP_EXPLORER
        explorer = min(requested, width - MINIMUM_EDITOR)
    return {"width": width, "height": height, "explorer": explorer, "compact": compact, "narrow": narrow}


def render() -> str:
    cards = []
    for index, (name, viewport_width, viewport_height) in enumerate(VIEWPORTS):
        result = layout(viewport_width, viewport_height)
        assert result["width"] <= viewport_width - PADDING * 2
        assert result["height"] <= viewport_height - PADDING * 2
        if not result["narrow"]:
            assert result["width"] - result["explorer"] >= MINIMUM_EDITOR
        column, row = index % 2, index // 2
        card_x, card_y = 24 + column * 620, 34 + row * 355
        scale = min(570 / viewport_width, 285 / viewport_height)
        viewport_x, viewport_y = card_x, card_y + 28
        vw, vh = viewport_width * scale, viewport_height * scale
        ww, wh = int(result["width"]) * scale, int(result["height"]) * scale
        wx, wy = viewport_x + (vw - ww) / 2, viewport_y + (vh - wh) / 2
        explorer_width = int(result["explorer"]) * scale
        content_x = wx if result["narrow"] else wx + explorer_width
        content_width = ww if result["narrow"] else ww - explorer_width
        cards.append(f'''<text x="{card_x}" y="{card_y+16}" class="label">{escape(name)} · {viewport_width}×{viewport_height}</text>
<rect x="{viewport_x}" y="{viewport_y}" width="{vw}" height="{vh}" rx="8" class="viewport"/>
<rect x="{wx}" y="{wy}" width="{ww}" height="{wh}" rx="6" class="window"/>
<rect x="{wx}" y="{wy}" width="{ww}" height="{34*scale}" rx="6" class="title"/>
<rect x="{wx}" y="{wy+34*scale}" width="{explorer_width}" height="{wh-34*scale}" class="explorer"/>
<rect x="{content_x}" y="{wy+34*scale}" width="{content_width}" height="{wh-34*scale}" class="editor"/>
<text x="{wx+12}" y="{wy+22*scale}" class="tiny">☰  DeGOAT Explorer</text>
<text x="{wx+10}" y="{wy+58*scale}" class="tiny">Pesquisar instâncias…</text>
<text x="{wx+12}" y="{wy+88*scale}" class="tree">▾ Workspace</text>
<text x="{wx+22}" y="{wy+108*scale}" class="tree">▤ Models</text>
<text x="{content_x+12}" y="{wy+62*scale}" class="code">1  -- DeGOAT Instance Inspector</text>
<text x="{card_x}" y="{viewport_y+vh+18}" class="meta">janela {result['width']}×{result['height']} · explorer {result['explorer']} · {'empilhado' if result['narrow'] else 'dividido'}</text>''')
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="1264" height="1099" viewBox="0 0 1264 1099">
<style>.bg{{fill:#111318}}.viewport{{fill:#20232a;stroke:#39404c}}.window{{fill:#181a1f;stroke:#485160;stroke-width:2}}.title{{fill:#262a31}}.explorer{{fill:#1f2228}}.editor{{fill:#181a1f}}.label{{fill:#e6eaf2;font:600 16px sans-serif}}.meta{{fill:#99a1b2;font:12px sans-serif}}.tiny{{fill:#dfe4ed;font:12px sans-serif}}.tree{{fill:#cbd2df;font:11px sans-serif}}.code{{fill:#dfe4ed;font:11px monospace}}</style>
<rect width="1264" height="744" class="bg"/>{''.join(cards)}</svg>'''


def main() -> int:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(render(), encoding="utf-8")
    for name, width, height in VIEWPORTS:
        result = layout(width, height)
        print(f"OK {name}: viewport={width}x{height} window={result['width']}x{result['height']} explorer={result['explorer']} narrow={result['narrow']}")
    print(f"preview: {OUTPUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
