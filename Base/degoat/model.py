from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass(frozen=True)
class Constant:
    kind: str
    value: Any = None


@dataclass(frozen=True)
class Local:
    name: str | None
    start_pc: int
    end_pc: int
    register: int


@dataclass
class Proto:
    id: int
    max_stack_size: int
    num_params: int
    num_upvalues: int
    is_vararg: bool
    flags: int = 0
    type_info: bytes = b""
    code: list[int] = field(default_factory=list)
    constants: list[Constant] = field(default_factory=list)
    children: list[int] = field(default_factory=list)
    line_defined: int = 0
    debug_name: str | None = None
    line_info: list[int] = field(default_factory=list)
    locals: list[Local] = field(default_factory=list)
    upvalue_names: list[str | None] = field(default_factory=list)


@dataclass
class Chunk:
    version: int
    type_version: int
    strings: list[str]
    userdata_types: dict[int, str]
    protos: list[Proto]
    main_id: int
    opcode_encoding: str = "identity"
    trailer: bytes = b""
    source_size: int = 0

    @property
    def main(self) -> Proto:
        return self.protos[self.main_id]
