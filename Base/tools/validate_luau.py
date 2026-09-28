#!/usr/bin/env python3
from __future__ import annotations

import argparse
import subprocess
import tempfile
from pathlib import Path

from degoat import decompile, parse


def main() -> int:
    parser = argparse.ArgumentParser(description="Recompila todas as saídas DeGOAT com o compilador oficial Luau")
    parser.add_argument("compiler", type=Path, help="caminho para luau-compile")
    parser.add_argument("inputs", type=Path, help="pasta com arquivos *_Bytecode.txt")
    args = parser.parse_args()

    paths = sorted(args.inputs.rglob("*_Bytecode.txt"))
    failures = 0
    for path in paths:
        source = decompile(parse(path.read_bytes()))
        with tempfile.NamedTemporaryFile("w", suffix=".luau", encoding="utf-8") as output:
            output.write(source)
            output.flush()
            result = subprocess.run(
                [str(args.compiler), output.name],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
                text=True,
            )
        if result.returncode:
            failures += 1
            print(f"ERRO {path.name}\n{result.stderr.rstrip()}")
        else:
            print(f"OK   {path.name}")
    print(f"Luau: {len(paths) - failures}/{len(paths)} saída(s) recompilaram")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
