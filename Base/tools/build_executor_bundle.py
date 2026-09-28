#!/usr/bin/env python3
"""Gera o chunk único usado pelo Loader.lua a partir dos módulos Luau."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
CLIENT = ROOT / "DeGOATClient"
OUTPUT = ROOT / "DeGOATExecutor" / "DeGOAT.bundle.lua"

MODULES = {
    "init": CLIENT / "init.lua",
    "Config": CLIENT / "Config.lua",
    "Core.Base64": CLIENT / "Core" / "Base64.lua",
    "Core.Reader": CLIENT / "Core" / "Reader.lua",
    "Core.Opcodes": CLIENT / "Core" / "Opcodes.lua",
    "Core.Parser": CLIENT / "Core" / "Parser.lua",
    "Core.CFG": CLIENT / "Core" / "CFG.lua",
    "Core.Naming": CLIENT / "Core" / "Naming.lua",
    "Core.Decompiler": CLIENT / "Core" / "Decompiler.lua",
    "Core.Properties": CLIENT / "Core" / "Properties.lua",
    "Providers.BytecodeProvider": CLIENT / "Providers" / "BytecodeProvider.lua",
    "UI.Theme": CLIENT / "UI" / "Theme.lua",
    "UI.Layout": CLIENT / "UI" / "Layout.lua",
    "UI.IconProvider": CLIENT / "UI" / "IconProvider.lua",
    "UI.GestureState": CLIENT / "UI" / "GestureState.lua",
    "UI.Editor": CLIENT / "UI" / "Editor.lua",
    "UI.Explorer": CLIENT / "UI" / "Explorer.lua",
    "UI.ContextMenu": CLIENT / "UI" / "ContextMenu.lua",
    "UI.App": CLIENT / "UI" / "App.lua",
}

PRELUDE = """-- AUTO-GERADO por tools/build_executor_bundle.py.
-- Fontes editáveis: DeGOATClient/. Nenhum decompiler remoto é usado.

local factories = {}
local cache = {}
local loading = {}

local function node(name, moduleId, parent)
    local value = { Name = name, Parent = parent, __moduleId = moduleId }
    if parent then parent[name] = value end
    return value
end

local root = node("DeGOATClient", "init", nil)
local core = node("Core", nil, root)
local providers = node("Providers", nil, root)
local ui = node("UI", nil, root)
node("Config", "Config", root)
node("Base64", "Core.Base64", core)
node("Reader", "Core.Reader", core)
node("Opcodes", "Core.Opcodes", core)
node("Parser", "Core.Parser", core)
node("CFG", "Core.CFG", core)
node("Naming", "Core.Naming", core)
node("Decompiler", "Core.Decompiler", core)
node("Properties", "Core.Properties", core)
node("BytecodeProvider", "Providers.BytecodeProvider", providers)
node("Theme", "UI.Theme", ui)
node("Layout", "UI.Layout", ui)
node("IconProvider", "UI.IconProvider", ui)
node("GestureState", "UI.GestureState", ui)
node("Editor", "UI.Editor", ui)
node("Explorer", "UI.Explorer", ui)
node("ContextMenu", "UI.ContextMenu", ui)
node("App", "UI.App", ui)

local function moduleRequire(moduleNode)
    assert(type(moduleNode) == "table" and moduleNode.__moduleId, "require interno inválido")
    local id = moduleNode.__moduleId
    if cache[id] ~= nil then return cache[id] end
    assert(not loading[id], "dependência circular no módulo " .. id)
    local factory = assert(factories[id], "módulo ausente: " .. id)
    loading[id] = true
    local result = factory(moduleNode, moduleRequire)
    loading[id] = nil
    if result == nil then result = true end
    cache[id] = result
    return result
end

"""


def render() -> str:
    pieces = [PRELUDE]
    for module_id, path in MODULES.items():
        source = path.read_text(encoding="utf-8")
        pieces.append(f'factories["{module_id}"] = function(script, require)\n')
        pieces.append(source)
        if not source.endswith("\n"):
            pieces.append("\n")
        pieces.append("end\n\n")
    pieces.append("return moduleRequire(root)\n")
    return "".join(pieces)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    result = render()
    if args.check:
        if not OUTPUT.exists() or OUTPUT.read_text(encoding="utf-8") != result:
            print("bundle desatualizado; execute tools/build_executor_bundle.py", file=sys.stderr)
            return 1
        print("bundle atualizado")
        return 0
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(result, encoding="utf-8")
    print(f"bundle: {OUTPUT.relative_to(ROOT)} ({len(result)} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
