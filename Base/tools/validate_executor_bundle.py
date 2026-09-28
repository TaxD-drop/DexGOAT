#!/usr/bin/env python3
"""Valida sintaxe e bootstrap interno do bundle em um runtime Luau oficial."""

from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
BUNDLE = ROOT / "DeGOATExecutor" / "DeGOAT.bundle.lua"

STUBS = """game = { GetService=function(_,name) return { Name=name } end }
Enum = {
    KeyCode={ RightShift="RightShift" },
    Font={ Code="Code", Gotham="Gotham", GothamBold="GothamBold" },
}
UDim2 = { fromOffset=function(x,y) return { x=x,y=y } end }
Color3 = { fromRGB=function(r,g,b) return { r=r,g=g,b=b } end }
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--luau", type=Path, required=True)
    parser.add_argument("--compiler", type=Path, required=True)
    args = parser.parse_args()
    source = (
        STUBS
        + "\nlocal DeGOAT = (function()\n"
        + BUNDLE.read_text(encoding="utf-8")
        + "\nend)()\n"
        + 'assert(type(DeGOAT)=="table" and type(DeGOAT.start)=="function")\n'
        + 'assert(DeGOAT.Version=="0.5.0-luau")\n'
        + 'print("DeGOAT executor bundle: OK")\n'
    )
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", suffix=".luau") as runner:
        runner.write(source)
        runner.flush()
        compiled = subprocess.run([str(args.compiler.resolve()), runner.name], capture_output=True, text=True)
        if compiled.returncode:
            print(compiled.stderr or compiled.stdout)
            return compiled.returncode
        executed = subprocess.run([str(args.luau.resolve()), runner.name], capture_output=True, text=True)
        print((executed.stdout or executed.stderr).strip())
        return executed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
