"""DeGOAT: parser, disassembler and structural decompiler for Luau bytecode."""

from .decompiler import decompile
from .disasm import disassemble
from .parser import BytecodeError, parse

__all__ = ["BytecodeError", "decompile", "disassemble", "parse"]
__version__ = "0.3.0"
