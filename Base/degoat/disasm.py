from __future__ import annotations

import json

from .model import Chunk, Constant, Proto
from .opcodes import AUX_OPS, OP, Instruction, decode


def _quote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def _constant(proto: Proto, index: int) -> str:
    if not 0 <= index < len(proto.constants):
        return f"K{index}?"
    item = proto.constants[index]
    if item.kind == "string":
        return _quote(item.value or "")
    if item.kind == "nil":
        return "nil"
    if item.kind == "boolean":
        return "true" if item.value else "false"
    if item.kind in ("number", "integer"):
        return repr(item.value)
    return f"{item.kind}({item.value!r})"


def import_path(proto: Proto, iid: int) -> str:
    count = iid >> 30
    indices = [(iid >> 20) & 0x3FF, (iid >> 10) & 0x3FF, iid & 0x3FF]
    return ".".join(_constant(proto, i) for i in indices[:count])


def _operands(proto: Proto, insn: Instruction) -> str:
    a, b, c, d, aux, name = insn.a, insn.b, insn.c, insn.d, insn.aux, insn.name
    r = lambda value: f"R{value}"
    k = lambda value: _constant(proto, value)
    if name in ("NOP", "BREAK", "NATIVECALL"):
        return ""
    if name == "LOADNIL": return r(a)
    if name == "LOADB": return f"{r(a)}, {'true' if b else 'false'}, +{c}"
    if name == "LOADN": return f"{r(a)}, {d}"
    if name == "LOADK": return f"{r(a)}, K{d} [{k(d)}]"
    if name == "LOADKX": return f"{r(a)}, K{aux} [{k(aux or 0)}]"
    if name == "MOVE": return f"{r(a)}, {r(b)}"
    if name in ("GETGLOBAL", "SETGLOBAL"): return f"{r(a)}, K{aux} [{k(aux or 0)}]"
    if name in ("GETUPVAL", "SETUPVAL"): return f"{r(a)}, U{b}"
    if name == "CLOSEUPVALS": return r(a)
    if name == "GETIMPORT":
        value = proto.constants[d].value if 0 <= d < len(proto.constants) and proto.constants[d].kind == "import" else aux or 0
        return f"{r(a)}, K{d} [{import_path(proto, value)}]"
    if name in ("GETTABLE", "SETTABLE"): return f"{r(a)}, {r(b)}, {r(c)}"
    if name in ("GETTABLEKS", "SETTABLEKS", "GETUDATAKS", "SETUDATAKS"):
        index = (aux or 0) & (0xFFFF if "UDATA" in name else 0xFFFFFFFF)
        return f"{r(a)}, {r(b)}, K{index} [{k(index)}]"
    if name in ("GETTABLEN", "SETTABLEN"): return f"{r(a)}, {r(b)}, {c + 1}"
    if name == "NEWCLOSURE": return f"{r(a)}, P{proto.children[d] if 0 <= d < len(proto.children) else d}"
    if name == "DUPCLOSURE": return f"{r(a)}, K{d} [{k(d)}]"
    if name in ("NAMECALL", "NAMECALLUDATA"):
        index = (aux or 0) & (0xFFFF if name == "NAMECALLUDATA" else 0xFFFFFFFF)
        return f"{r(a)}, {r(b)}, K{index} [{k(index)}]"
    if name in ("CALL", "CALLFB"): return f"{r(a)}, args={b - 1 if b else '*'}, results={c - 1 if c else '*'}"
    if name == "RETURN": return f"{r(a)}, count={b - 1 if b else '*'}"
    if name in ("JUMP", "JUMPBACK", "JUMPX"): return f"L{insn.target}"
    if name in ("JUMPIF", "JUMPIFNOT"): return f"{r(a)}, L{insn.target}"
    if name.startswith("JUMPIF"):
        return f"{r(a)}, {r(aux or 0)}, L{insn.target}"
    if name.startswith("JUMPXEQK"):
        value = {"JUMPXEQKNIL": "nil", "JUMPXEQKB": str(bool((aux or 0) & 1)).lower()}.get(name)
        if value is None: value = k((aux or 0) & 0xFFFFFF)
        return f"{r(a)}, {value}, L{insn.target}, not={bool((aux or 0) >> 31)}"
    if name in ("ADD", "SUB", "MUL", "DIV", "MOD", "POW", "IDIV", "AND", "OR"):
        return f"{r(a)}, {r(b)}, {r(c)}"
    if name.endswith("K") and name not in ("SETTABLEKS", "GETTABLEKS", "NAMECALLUDATA"):
        return f"{r(a)}, {r(b)}, K{c} [{k(c)}]"
    if name in ("SUBRK", "DIVRK"): return f"{r(a)}, K{b} [{k(b)}], {r(c)}"
    if name == "CONCAT": return f"{r(a)}, {r(b)}..{r(c)}"
    if name in ("NOT", "MINUS", "LENGTH"): return f"{r(a)}, {r(b)}"
    if name in ("NEWTABLE",): return f"{r(a)}, hash={b}, array={aux}"
    if name == "DUPTABLE": return f"{r(a)}, K{d} [{k(d)}]"
    if name == "SETLIST": return f"{r(a)}, {r(b)}, count={c - 1 if c else '*'}, index={aux}"
    if name.startswith("FOR"):
        return f"{r(a)}, L{insn.target}" + (f", aux=0x{aux:08x}" if aux is not None else "")
    if name == "GETVARARGS": return f"{r(a)}, count={b - 1 if b else '*'}"
    if name == "PREPVARARGS": return str(a)
    if name.startswith("FASTCALL"): return f"builtin={a}, {r(b)}, skip={c}" + (f", aux=0x{aux:08x}" if aux is not None else "")
    if name == "COVERAGE": return str(insn.e)
    if name == "CAPTURE": return f"type={a}, source={b}"
    return f"A={a} B={b} C={c}" + (f" AUX=0x{aux:08x}" if aux is not None else "")


def disassemble_proto(proto: Proto) -> str:
    instructions = decode(proto.code)
    targets = {item.target for item in instructions if item.target is not None}
    out = [
        f"; proto P{proto.id} name={proto.debug_name or '<main>'!r} line={proto.line_defined}",
        f"; stack={proto.max_stack_size} params={proto.num_params} upvalues={proto.num_upvalues} vararg={proto.is_vararg}",
    ]
    for item in instructions:
        if item.pc in targets:
            out.append(f"L{item.pc}:")
        line = proto.line_info[item.pc] if item.pc < len(proto.line_info) else None
        line_text = f" line {line:4d}" if line is not None else ""
        raw = f"{item.word:08x}" + (f" {item.aux:08x}" if item.aux is not None else "")
        out.append(f"  {item.pc:04d}  {raw:<17} {item.name:<18} {_operands(proto, item)}{line_text}".rstrip())
    return "\n".join(out)


def disassemble(chunk: Chunk) -> str:
    header = [
        f"; DeGOAT Luau bytecode v{chunk.version}, types v{chunk.type_version}",
        f"; protos={len(chunk.protos)} strings={len(chunk.strings)} main=P{chunk.main_id} encoding={chunk.opcode_encoding} trailer={len(chunk.trailer)} bytes",
    ]
    return "\n\n".join(["\n".join(header)] + [disassemble_proto(p) for p in chunk.protos]) + "\n"
