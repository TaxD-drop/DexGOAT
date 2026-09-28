from __future__ import annotations

from dataclasses import dataclass


NAMES = [
    "NOP", "BREAK", "LOADNIL", "LOADB", "LOADN", "LOADK", "MOVE",
    "GETGLOBAL", "SETGLOBAL", "GETUPVAL", "SETUPVAL", "CLOSEUPVALS",
    "GETIMPORT", "GETTABLE", "SETTABLE", "GETTABLEKS", "SETTABLEKS",
    "GETTABLEN", "SETTABLEN", "NEWCLOSURE", "NAMECALL", "CALL", "RETURN",
    "JUMP", "JUMPBACK", "JUMPIF", "JUMPIFNOT", "JUMPIFEQ", "JUMPIFLE",
    "JUMPIFLT", "JUMPIFNOTEQ", "JUMPIFNOTLE", "JUMPIFNOTLT", "ADD", "SUB",
    "MUL", "DIV", "MOD", "POW", "ADDK", "SUBK", "MULK", "DIVK", "MODK",
    "POWK", "AND", "OR", "ANDK", "ORK", "CONCAT", "NOT", "MINUS",
    "LENGTH", "NEWTABLE", "DUPTABLE", "SETLIST", "FORNPREP", "FORNLOOP",
    "FORGLOOP", "FORGPREP_INEXT", "FASTCALL3", "FORGPREP_NEXT", "NATIVECALL",
    "GETVARARGS", "DUPCLOSURE", "PREPVARARGS", "LOADKX", "JUMPX", "FASTCALL",
    "COVERAGE", "CAPTURE", "SUBRK", "DIVRK", "FASTCALL1", "FASTCALL2",
    "FASTCALL2K", "FORGPREP", "JUMPXEQKNIL", "JUMPXEQKB", "JUMPXEQKN",
    "JUMPXEQKS", "IDIV", "IDIVK", "GETUDATAKS", "SETUDATAKS",
    "NAMECALLUDATA", "NEWCLASSMEMBER", "CALLFB", "CMPPROTO",
]

OP = {name: index for index, name in enumerate(NAMES)}

# Instructions serialized with one extra 32-bit word.
AUX_OPS = {
    OP[name]
    for name in (
        "GETGLOBAL", "SETGLOBAL", "GETIMPORT", "GETTABLEKS", "SETTABLEKS",
        "NAMECALL", "JUMPIFEQ", "JUMPIFLE", "JUMPIFLT", "JUMPIFNOTEQ",
        "JUMPIFNOTLE", "JUMPIFNOTLT", "NEWTABLE", "SETLIST", "FORGLOOP",
        "FASTCALL3", "LOADKX", "FASTCALL2", "FASTCALL2K", "JUMPXEQKNIL",
        "JUMPXEQKB", "JUMPXEQKN", "JUMPXEQKS", "GETUDATAKS", "SETUDATAKS",
        "NAMECALLUDATA", "NEWCLASSMEMBER", "CALLFB", "CMPPROTO",
    )
}

JUMP_D_OPS = {
    OP[name]
    for name in (
        "JUMP", "JUMPBACK", "JUMPIF", "JUMPIFNOT", "JUMPIFEQ", "JUMPIFLE",
        "JUMPIFLT", "JUMPIFNOTEQ", "JUMPIFNOTLE", "JUMPIFNOTLT", "FORNPREP",
        "FORNLOOP", "FORGLOOP", "FORGPREP_INEXT", "FORGPREP_NEXT", "FORGPREP",
        "JUMPXEQKNIL", "JUMPXEQKB", "JUMPXEQKN", "JUMPXEQKS", "CMPPROTO",
    )
}
JUMP_E_OPS = {OP["JUMPX"]}


def signed(value: int, bits: int) -> int:
    sign = 1 << (bits - 1)
    return value - (1 << bits) if value & sign else value


@dataclass(frozen=True)
class Instruction:
    pc: int
    word: int
    opcode: int
    name: str
    a: int
    b: int
    c: int
    d: int
    e: int
    aux: int | None
    size: int

    @property
    def target(self) -> int | None:
        if self.opcode in JUMP_D_OPS:
            return self.pc + self.d + 1
        if self.opcode in JUMP_E_OPS:
            return self.pc + self.e + 1
        return None


def decode(code: list[int]) -> list[Instruction]:
    result: list[Instruction] = []
    pc = 0
    while pc < len(code):
        word = code[pc]
        opcode = word & 0xFF
        name = NAMES[opcode] if opcode < len(NAMES) else f"OP_{opcode}"
        size = 2 if opcode in AUX_OPS else 1
        aux = code[pc + 1] if size == 2 and pc + 1 < len(code) else None
        result.append(
            Instruction(
                pc=pc,
                word=word,
                opcode=opcode,
                name=name,
                a=(word >> 8) & 0xFF,
                b=(word >> 16) & 0xFF,
                c=(word >> 24) & 0xFF,
                d=signed((word >> 16) & 0xFFFF, 16),
                e=signed((word >> 8) & 0xFFFFFF, 24),
                aux=aux,
                size=size,
            )
        )
        pc += size
    return result
