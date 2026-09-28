#!/usr/bin/env python3
"""Confere os ícones de serviço e os contratos de carregamento do Explorer."""

from __future__ import annotations

from pathlib import Path
import re
import struct


ROOT = Path(__file__).resolve().parents[1]
ICONS = ROOT / "DeGOATClient" / "Icons"
PROVIDER = ROOT / "DeGOATClient" / "UI" / "IconProvider.lua"
CONFIG = ROOT / "DeGOATClient" / "Config.lua"
LOADER = ROOT / "Loader.lua"


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise AssertionError(f"PNG inválido: {path.name}")
    return struct.unpack(">II", data[16:24])


def main() -> int:
    provider = PROVIDER.read_text(encoding="utf-8")
    config = CONFIG.read_text(encoding="utf-8")
    loader = LOADER.read_text(encoding="utf-8")
    mappings = dict(re.findall(r'^\s*([A-Za-z][A-Za-z0-9_]*)\s*=\s*"([^"]+\.png)"', provider, re.MULTILINE))
    roots_match = re.search(r"RootServices\s*=\s*\{(.*?)\}", config, re.DOTALL)
    assert roots_match, "RootServices não encontrado"
    roots = re.findall(r'"([A-Za-z][A-Za-z0-9_]*)"', roots_match.group(1))
    failures: list[str] = []
    for service in roots:
        filename = mappings.get(service)
        if not filename:
            failures.append(f"sem associação: {service}")
            continue
        path = ICONS / filename
        if not path.exists():
            failures.append(f"arquivo ausente: {filename}")
            continue
        try:
            width, height = png_size(path)
            assert width > 0 and height > 0
            print(f"OK {service}: {filename} {width}x{height}")
        except (AssertionError, struct.error) as error:
            failures.append(str(error))
    assert 'IconBaseUrl = baseUrl .. "DeGOATClient/Icons/"' in loader, "Loader não encaminha a URL dos ícones"
    assert "getcustomasset" in provider and "getsynasset" in provider, "fallbacks de custom asset ausentes"
    print(f"roots={len(roots)} failures={len(failures)}")
    for failure in failures:
        print("FAIL", failure)
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
