from __future__ import annotations

import argparse
import sys
from pathlib import Path

from . import __version__
from .decompiler import decompile
from .disasm import disassemble
from .parser import BytecodeError, normalize_input, parse
from .report import report_json


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(prog="degoat", description="Decode, inspect and structurally decompile Luau bytecode")
    result.add_argument("--version", action="version", version=f"DeGOAT {__version__}")
    sub = result.add_subparsers(dest="command", required=True)
    for name, help_text in (
        ("decompile", "reconstruir código Luau"),
        ("disassemble", "listar instruções da VM"),
        ("inspect", "gerar relatório JSON do blob"),
    ):
        command = sub.add_parser(name, help=help_text)
        command.add_argument("input", type=Path, help="arquivo raw, base64, hex ou JSON {script: base64}")
        command.add_argument("-o", "--output", type=Path)
        if name == "inspect":
            command.add_argument("--corpus", type=Path, help="pasta de módulos Lua para correlacionar nomes")
    batch = sub.add_parser("batch", help="decompilar uma árvore de bytecodes")
    batch.add_argument("input", type=Path, help="pasta contendo arquivos de bytecode")
    batch.add_argument("-o", "--output", type=Path, required=True, help="pasta de destino")
    batch.add_argument("--mode", choices=("decompile", "disassemble", "inspect"), default="decompile")
    batch.add_argument("--corpus", type=Path, help="corpus usado no modo inspect")
    return result


def _render(command: str, source: bytes, corpus: Path | None = None) -> str:
    normalized = normalize_input(source)
    chunk = parse(normalized)
    if command == "decompile":
        return decompile(chunk)
    if command == "disassemble":
        return disassemble(chunk)
    return report_json(chunk, normalized, corpus)


def _batch(args: argparse.Namespace) -> int:
    if not args.input.is_dir():
        raise BytecodeError(f"pasta de entrada não encontrada: {args.input}")
    suffix = {"decompile": ".decompiled.lua", "disassemble": ".dis.txt", "inspect": ".json"}[args.mode]
    candidates = [
        path for path in args.input.rglob("*")
        if path.is_file() and ("bytecode" in path.name.lower() or path.suffix.lower() in (".luauc", ".bin"))
    ]
    if not candidates:
        raise BytecodeError("nenhum arquivo com 'bytecode', .luauc ou .bin foi encontrado")
    failures = 0
    for path in candidates:
        relative = path.relative_to(args.input)
        stem = relative.name
        if stem.lower().endswith("_bytecode.txt"):
            stem = stem[: -len("_Bytecode.txt")]
        else:
            stem = relative.stem
        destination = args.output / relative.parent / f"{stem}{suffix}"
        try:
            output = _render(args.mode, path.read_bytes(), args.corpus)
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_text(output, encoding="utf-8")
            print(f"OK  {path} -> {destination}")
        except (OSError, UnicodeError, BytecodeError) as exc:
            failures += 1
            print(f"ERRO {path}: {exc}", file=sys.stderr)
    print(f"DeGOAT: {len(candidates) - failures}/{len(candidates)} arquivo(s) processado(s)")
    return 1 if failures else 0


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        if args.command == "batch":
            return _batch(args)
        source = args.input.read_bytes()
        output = _render(args.command, source, getattr(args, "corpus", None))
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(output, encoding="utf-8")
        else:
            sys.stdout.write(output)
        return 0
    except (OSError, UnicodeError, BytecodeError) as exc:
        print(f"degoat: erro: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
