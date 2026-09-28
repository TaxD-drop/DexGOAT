#!/usr/bin/env python3
"""Executa a porta Luau contra todos os bytecodes de teste locais."""

from __future__ import annotations

import argparse
import base64
from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
TESTS = ROOT / "DeGOATClient" / "Tests"
FIXTURES = ROOT / "Decode_Bytecode"


def validate(
    luau: Path, fixture: Path, compiler: Path | None, output_dir: Path | None
) -> tuple[bool, str]:
    encoded = base64.b64encode(fixture.read_bytes()).decode("ascii")
    hexadecimal = fixture.read_bytes().hex()
    source = (
        'local SelfTest = require("./SelfTest")\n'
        'local Parser = require("../Core/Parser")\n'
        f'assert(Parser.parse("{hexadecimal}").sourceSize > 0)\n'
        f'assert(Parser.parse(\'{{"script":"{encoded}"}}\').sourceSize > 0)\n'
        f'local result = SelfTest.run("{encoded}")\n'
        'assert(type(result) == "string" and #result > 0)\n'
        'print(result)\n'
    )
    runner: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", suffix=".luau", prefix="runtime_", dir=TESTS, delete=False
        ) as handle:
            handle.write(source)
            runner = Path(handle.name)
        result = subprocess.run(
            [str(luau), runner.name], cwd=TESTS, capture_output=True, text=True, timeout=30
        )
        if result.returncode != 0:
            return False, (result.stderr or result.stdout).strip()
        if output_dir is not None:
            output_dir.mkdir(parents=True, exist_ok=True)
            (output_dir / fixture.name.replace("_Bytecode.txt", ".client.luau")).write_text(
                result.stdout, encoding="utf-8"
            )
        if compiler is not None:
            with tempfile.NamedTemporaryFile(
                mode="w", encoding="utf-8", suffix=".luau", prefix="degoat_output_"
            ) as output:
                output.write(result.stdout)
                output.flush()
                compiled = subprocess.run(
                    [str(compiler), output.name], capture_output=True, text=True, timeout=30
                )
            if compiled.returncode != 0:
                return False, "saída Luau inválida:\n" + (compiled.stderr or compiled.stdout).strip()
        return True, ""
    finally:
        if runner is not None:
            runner.unlink(missing_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--luau", type=Path, required=True, help="caminho do executável luau")
    parser.add_argument("--compiler", type=Path, help="luau-compile para validar a sintaxe gerada")
    parser.add_argument("--output-dir", type=Path, help="salva as fontes geradas para inspeção")
    parser.add_argument("fixtures", type=Path, nargs="*")
    args = parser.parse_args()

    fixtures = args.fixtures or sorted(FIXTURES.glob("*_Bytecode.txt"))
    failures = 0
    for fixture in fixtures:
        ok, detail = validate(
            args.luau.resolve(), fixture.resolve(), args.compiler.resolve() if args.compiler else None,
            args.output_dir.resolve() if args.output_dir else None,
        )
        print(f"{'OK' if ok else 'FAIL'} {fixture.name}")
        if not ok:
            failures += 1
            print(detail)
    print(f"fixtures={len(fixtures)} failures={failures}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
