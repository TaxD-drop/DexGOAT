from __future__ import annotations

import json
import re
from contextlib import contextmanager
from dataclasses import dataclass

from .cfg import CONDITIONAL, ControlFlowGraph
from .disasm import import_path
from .model import Chunk, Constant, Proto
from .naming import identifier, infer_value_names
from .opcodes import OP, Instruction, decode


IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
BINARY = {
    "ADD": "+", "SUB": "-", "MUL": "*", "DIV": "/", "MOD": "%",
    "POW": "^", "IDIV": "//", "AND": "and", "OR": "or",
    "ADDK": "+", "SUBK": "-", "MULK": "*", "DIVK": "/", "MODK": "%",
    "POWK": "^", "IDIVK": "//", "ANDK": "and", "ORK": "or",
}
COMPARE = {
    "JUMPIFEQ": "==", "JUMPIFLE": "<=", "JUMPIFLT": "<",
    "JUMPIFNOTEQ": "~=", "JUMPIFNOTLE": ">", "JUMPIFNOTLT": ">=",
}


def quote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def field(base: str, key: str) -> str:
    return f"{base}.{key}" if IDENTIFIER.match(key) else f"{base}[{quote(key)}]"


def prefix(base: str) -> str:
    """Return an expression that is legal before Lua's ':' method syntax."""
    if IDENTIFIER.match(base) or re.match(r"^[A-Za-z_][A-Za-z0-9_]*(?:[.\[].*)?$", base):
        return base
    if base.startswith("(") and base.endswith(")"):
        return base
    return f"({base})"


def const_expr(proto: Proto, index: int) -> str:
    if not 0 <= index < len(proto.constants):
        return f"nil --[[ constante K{index} inválida ]]"
    item = proto.constants[index]
    if item.kind == "nil": return "nil"
    if item.kind == "boolean": return "true" if item.value else "false"
    if item.kind == "string": return quote(item.value or "")
    if item.kind in ("number", "integer"): return repr(item.value)
    if item.kind in ("vector", "vector_double"):
        values = ", ".join(repr(x) for x in item.value[:3])
        return f"Vector3.new({values})"
    if item.kind == "table":
        return "{}"
    if item.kind == "table_with_constants":
        entries = []
        for key_index, value_index in item.value:
            key = const_expr(proto, key_index)
            value = const_expr(proto, value_index) if value_index >= 0 else "nil"
            entries.append(f"[{key}] = {value}")
        return "{" + ", ".join(entries) + "}"
    if item.kind == "closure": return f"proto_{item.value}"
    if item.kind == "import": return import_path(proto, item.value).replace('"', "")
    return f"nil --[[ {item.kind}: {item.value!r} ]]"


@dataclass
class Register:
    value: str
    pure: bool = False
    deps: frozenset[int] = frozenset()
    binding: str | None = None
    def_pc: int = -2


@dataclass(frozen=True)
class Capture:
    name: str
    mode: str


class Emitter:
    def __init__(self, chunk: Chunk, proto: Proto, indent: str = "", captures: list[Capture] | None = None):
        self.chunk = chunk
        self.proto = proto
        self.indent = indent
        self.instructions = decode(proto.code)
        self.by_pc = {item.pc: item for item in self.instructions}
        self.position_by_pc = {item.pc: position for position, item in enumerate(self.instructions)}
        self.targets = {item.target for item in self.instructions if item.target is not None}
        inherited = captures or [Capture(f"u{i}", "ref") for i in range(proto.num_upvalues)]
        self.upvalues = [capture.name for capture in inherited]
        self.upvalue_modes = [capture.mode for capture in inherited]
        self.cfg = ControlFlowGraph.build(proto)
        self.value_names = infer_value_names(chunk, proto)
        self.used_names = set(self.upvalues)
        self.name_counts: dict[str, int] = {}
        self.generic_counter = 0
        self.hoisted: set[str] = set()
        self.regs: list[Register] = []
        for register in range(proto.max_stack_size):
            if register < proto.num_params:
                name = self._claim_name(f"arg{register + 1}")
                self.regs.append(Register(name, pure=True, deps=frozenset({register}), binding=name, def_pc=-1))
            else:
                self.regs.append(Register(f"v{register}", deps=frozenset({register})))
        self.lines: list[str] = []
        self.last_source_line: int | None = None
        self.multret: tuple[int, str] | None = None
        self.method_calls: dict[int, tuple[str, str]] = {}
        self.level = 0
        self.force_registers: list[set[int]] = []
        self.materialized: set[int] = set()
        self.unstructured_targets: set[int] = set()
        self.current_position = 0

    def _claim_name(self, proposed: str) -> str:
        base = identifier(proposed, "value")
        if base not in self.used_names:
            self.used_names.add(base)
            self.name_counts.setdefault(base, 1)
            return base
        suffix = self.name_counts.get(base, 1) + 1
        while f"{base}{suffix}" in self.used_names:
            suffix += 1
        self.name_counts[base] = suffix
        name = f"{base}{suffix}"
        self.used_names.add(name)
        return name

    def _new_binding(self, index: int, def_pc: int | None = None) -> str:
        pc = self.current_position if def_pc is None else def_pc
        if 0 <= pc < len(self.instructions):
            pc = self.instructions[pc].pc
        hint = self.value_names.get((pc, index))
        if hint is not None and hint.confidence >= 75:
            return self._claim_name(hint.name)
        while True:
            name = f"v{self.generic_counter}"
            self.generic_counter += 1
            if name not in self.used_names:
                self.used_names.add(name)
                return name

    def reg_name(self, index: int) -> str:
        if 0 <= index < len(self.regs) and self.regs[index].binding:
            return self.regs[index].binding or f"v{index}"
        # An undefined value reaching source needs a cell visible from all
        # incoming paths.  This is the small, intentional hoist set.
        name = self._new_binding(index)
        if 0 <= index < len(self.regs):
            self.regs[index] = Register(name, deps=frozenset({index}), binding=name)
        self.hoisted.add(name)
        return name

    def reg(self, index: int) -> str:
        if 0 <= index < len(self.regs):
            current = self.regs[index]
            value = current.value
            if current.binding and value == current.binding and index >= self.proto.num_params:
                self.materialized.add(index)
            return value
        return self.reg_name(index)

    def reg_deps(self, index: int) -> frozenset[int]:
        return self.regs[index].deps if 0 <= index < len(self.regs) else frozenset()

    def setreg(
        self,
        index: int,
        value: str,
        *,
        pure: bool = False,
        emit: bool = False,
        deps: frozenset[int] = frozenset(),
        reuse: bool = False,
    ):
        # Symbolic expressions that refer to this register must be snapshotted
        # before register reuse changes what the name denotes.
        for other, current in enumerate(self.regs):
            if (other != index and current.pure and current.binding is None
                    and index in current.deps and self._live_after(other, self.current_position + 1)):
                self.materialize(other)
        self.method_calls.pop(index, None)
        old_binding = self.regs[index].binding if 0 <= index < len(self.regs) else None
        register = Register(value, pure, deps, def_pc=self.instructions[self.current_position].pc
                            if 0 <= self.current_position < len(self.instructions) else -2)
        if 0 <= index < len(self.regs):
            self.regs[index] = register
        if emit:
            self.materialized.add(index)
            name = old_binding if reuse and old_binding else self._new_binding(index)
            self.line(f"{name} = {value}" if reuse and old_binding else f"local {name} = {value}")
            if 0 <= index < len(self.regs):
                self.regs[index] = Register(name, pure=True, deps=deps, binding=name, def_pc=register.def_pc)

    def _assign_multiple(self, start: int, count: int, expression: str) -> None:
        count = min(count, len(self.regs) - start)
        if count <= 0:
            self.line(expression)
            return
        for index in range(start, start + count):
            for other, current in enumerate(self.regs):
                if (other != index and current.pure and current.binding is None
                        and index in current.deps and self._live_after(other, self.current_position + 1)):
                    self.materialize(other)
        names = [self._new_binding(index) for index in range(start, start + count)]
        self.line(f"local {', '.join(names)} = {expression}")
        pc = self.instructions[self.current_position].pc
        for index, name in zip(range(start, start + count), names):
            self.materialized.add(index)
            self.regs[index] = Register(name, pure=True, binding=name, def_pc=pc)

    def _effect_barrier(self, dependencies: frozenset[int], *, exclude: set[int] | None = None) -> None:
        """Snapshot property/index reads before a potentially aliasing write.

        A textual expression such as ``part.Size`` is not a value snapshot. If
        the bytecode reads it before mutating ``part.Size``, delaying that
        expression silently changes behavior.
        """
        excluded = exclude or set()
        for register, current in enumerate(self.regs):
            if register in excluded or current.binding is not None or not current.pure:
                continue
            looks_like_read = "." in current.value or "[" in current.value
            if (looks_like_read and current.deps & dependencies
                    and self._live_after(register, self.current_position + 1)):
                self.materialize(register)

    def materialize(self, index: int) -> str:
        """Give a symbolic value stable register identity before capture/mutation."""
        if not 0 <= index < len(self.regs):
            return self.reg_name(index)
        current = self.regs[index]
        if current.binding:
            return current.binding
        value = current.value
        name = self._new_binding(index, self.position_by_pc.get(current.def_pc, self.current_position))
        self.materialized.add(index)
        self.line(f"local {name} = {value}")
        self.regs[index] = Register(name, pure=True, deps=current.deps, binding=name, def_pc=current.def_pc)
        return name

    def upvalue(self, index: int) -> str:
        return self.upvalues[index] if 0 <= index < len(self.upvalues) else f"u{index}"

    def line(self, text: str = "", extra: str = ""):
        self.lines.append(self.indent + "\t" * self.level + extra + text)

    def source_marker(self, pc: int):
        if pc >= len(self.proto.line_info):
            return
        source_line = self.proto.line_info[pc]
        if source_line != self.last_source_line:
            self.line(f"-- linha original {source_line}")
            self.last_source_line = source_line

    def assign(
        self,
        index: int,
        value: str,
        *,
        pure: bool = True,
        deps: frozenset[int] = frozenset(),
        forceable: bool = True,
    ):
        # Pure bytecode operations can remain symbolic until a side effect uses
        # them. This removes register shuffling without reordering calls.
        # Region merge cells outrank call-chain elision: a value that survives
        # the branch must keep the same lexical binding on every path.
        forced = any(index in registers for registers in self.force_registers)
        self.setreg(index, value, pure=pure, emit=forced or not pure, deps=deps, reuse=forced)

    @contextmanager
    def nested(self, *, force: set[int] | None = None):
        self.level += 1
        self.force_registers.append(force or set())
        try:
            yield
        finally:
            self.force_registers.pop()
            self.level -= 1

    def captures(self, position: int, child: Proto) -> tuple[list[Capture], int]:
        values: list[Capture] = []
        cursor = position + 1
        while len(values) < child.num_upvalues and cursor < len(self.instructions):
            capture = self.instructions[cursor]
            if capture.name != "CAPTURE":
                break
            if capture.a == 0:
                values.append(Capture(self.materialize(capture.b), "copy"))
            elif capture.a == 1:
                values.append(Capture(self.materialize(capture.b), "ref"))
            else:
                values.append(Capture(self.upvalue(capture.b), "ref"))
            cursor += 1
        while len(values) < child.num_upvalues:
            values.append(Capture(f"u{len(values)}", "ref"))
        return values, cursor

    def closure(self, child_id: int, captures: list[Capture]) -> str:
        child = self.chunk.protos[child_id]
        current_indent = self.indent + "\t" * self.level
        nested = Emitter(self.chunk, child, current_indent + "\t", captures)
        args = ", ".join(nested.reg_name(i) for i in range(child.num_params))
        body = nested.render_body()
        if child.is_vararg:
            args = f"{args}, ..." if args else "..."
        parts = [f"function({args})"]
        if captures:
            metadata = ", ".join(f"({capture.mode}) {capture.name}" for capture in captures)
            parts.append(current_indent + "\t-- upvalues: " + metadata)
        parts.extend(body)
        parts.append(current_indent + "end")
        return "\n".join(parts)

    def call(self, item: Instruction, *, iterator: bool = False, defer_result: bool = False):
        a, b, c = item.a, item.b, item.c
        method_info = self.method_calls.get(a)
        function = self.reg(a) if method_info is None else ""
        dependencies = self.reg_deps(a)
        if b:
            arguments = [self.reg(i) for i in range(a + 1, a + b)]
            dependencies |= frozenset().union(*(self.reg_deps(i) for i in range(a + 1, a + b))) if b > 1 else frozenset()
        elif self.multret and self.multret[0] >= a + 1:
            arguments = [self.reg(i) for i in range(a + 1, self.multret[0])]
            arguments.append(self.multret[1])
            dependencies |= frozenset().union(*(self.reg_deps(i) for i in range(a + 1, self.multret[0]))) if self.multret[0] > a + 1 else frozenset()
        else:
            arguments = [self.reg(a + 1), "--[[ MULTRET ]]" ] if a + 1 < len(self.regs) else ["--[[ MULTRET ]]" ]
        if method_info is not None:
            receiver, method = method_info
            # NAMECALL places self in A+1; ':' supplies it implicitly.
            arguments = arguments[1:] if arguments else arguments
            if IDENTIFIER.match(method):
                expression = f"{prefix(receiver)}:{method}({', '.join(arguments)})"
            else:
                expression = f"{receiver}[{quote(method)}]({receiver}, {', '.join(arguments)})"
        else:
            expression = f"{prefix(function)}({', '.join(arguments)})"
            if c == 1 and function.startswith("function("):
                expression = ";" + expression
        if c == 0 or iterator:
            self.setreg(a, expression, pure=True, deps=dependencies)
            self.multret = (a, expression)
            return
        self.multret = None
        results = c - 1
        if c == 1:
            self.line(expression)
            return
        if results <= 1:
            self.assign(a, expression, pure=defer_result, deps=dependencies)
            return
        self._assign_multiple(a, results, expression)

    def emit_instruction(self, item: Instruction, position: int) -> int:
        self.current_position = position
        n, a, b, c, d, aux = item.name, item.a, item.b, item.c, item.d, item.aux or 0
        r = self.reg
        k = lambda index: const_expr(self.proto, index)
        next_item = self.instructions[position + 1] if position + 1 < len(self.instructions) else None
        prepares_call = bool(
            next_item and (
                (next_item.name in {"CALL", "CALLFB"} and next_item.a == a)
                or (next_item.name in {"NAMECALL", "NAMECALLUDATA"} and next_item.b == a)
            )
        )
        if n in ("NOP", "BREAK", "PREPVARARGS", "FASTCALL", "FASTCALL1", "FASTCALL2", "FASTCALL2K", "FASTCALL3", "COVERAGE", "CAPTURE"):
            return position + 1
        if n == "LOADNIL": self.assign(a, "nil")
        elif n == "LOADB":
            self.assign(a, "true" if b else "false")
            # LOADB's C operand skips C instruction words.  This is how Luau
            # lowers boolean comparisons into a compact two-value selection.
            if c:
                target_pc = item.pc + 1 + c
                return self.position_by_pc.get(target_pc, position + 1)
        elif n == "LOADN": self.assign(a, str(d))
        elif n == "LOADK": self.assign(a, k(d))
        elif n == "LOADKX": self.assign(a, k(aux))
        elif n == "MOVE": self.assign(a, r(b), deps=self.reg_deps(b))
        elif n == "GETGLOBAL": self.assign(a, k(aux).strip('"'), forceable=not prepares_call)
        elif n == "SETGLOBAL": self.line(f"{k(aux).strip(chr(34))} = {r(a)}")
        elif n == "GETUPVAL": self.assign(a, self.upvalue(b), forceable=not prepares_call)
        elif n == "SETUPVAL":
            upvalue = self.upvalue(b)
            # A symbolic read of an upvalue is not a snapshot. Preserve any
            # register that must retain the old value before mutating it.
            for register, current in enumerate(self.regs):
                if (register != a and current.value == upvalue
                        and self._live_after(register, self.current_position + 1)):
                    self.materialize(register)
            self.line(f"{upvalue} = {r(a)}")
        elif n == "CLOSEUPVALS": pass
        elif n == "GETIMPORT":
            iid = self.proto.constants[d].value if 0 <= d < len(self.proto.constants) and self.proto.constants[d].kind == "import" else aux
            self.assign(a, import_path(self.proto, iid).replace('"', ""), forceable=not prepares_call)
        elif n in ("GETTABLEKS", "GETUDATAKS"):
            index = aux & (0xFFFF if n == "GETUDATAKS" else 0xFFFFFFFF)
            self.assign(a, field(r(b), str(self.proto.constants[index].value)), deps=self.reg_deps(b), forceable=not prepares_call)
        elif n == "GETTABLE": self.assign(a, f"{r(b)}[{r(c)}]", deps=self.reg_deps(b) | self.reg_deps(c), forceable=not prepares_call)
        elif n == "GETTABLEN": self.assign(a, f"{r(b)}[{c + 1}]", deps=self.reg_deps(b), forceable=not prepares_call)
        elif n in ("SETTABLEKS", "SETUDATAKS"):
            index = aux & (0xFFFF if n == "SETUDATAKS" else 0xFFFFFFFF)
            self._effect_barrier(self.reg_deps(b), exclude={a, b})
            target = field(r(b), str(self.proto.constants[index].value))
            value = r(a)
            named_target = re.match(r"^[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*$", target)
            if value.startswith("function(") and named_target:
                self.line("function " + target + value[len("function"):])
            else:
                self.line(f"{target} = {value}")
        elif n == "SETTABLE":
            self._effect_barrier(self.reg_deps(b) | self.reg_deps(c), exclude={a, b, c})
            self.line(f"{r(b)}[{r(c)}] = {r(a)}")
        elif n == "SETTABLEN":
            self._effect_barrier(self.reg_deps(b), exclude={a, b})
            self.line(f"{r(b)}[{c + 1}] = {r(a)}")
        elif n in ("NEWCLOSURE", "DUPCLOSURE"):
            if n == "NEWCLOSURE":
                child_id = self.proto.children[d]
            else:
                constant = self.proto.constants[d]
                child_id = int(constant.value)
            child = self.chunk.protos[child_id]
            captured, cursor = self.captures(position, child)
            if child.debug_name:
                self.line(f"-- função reconstruída: {child.debug_name}")
            self.assign(a, self.closure(child_id, captured), pure=True)
            return cursor
        elif n in ("NAMECALL", "NAMECALLUDATA"):
            index = aux & (0xFFFF if n == "NAMECALLUDATA" else 0xFFFFFFFF)
            method = str(self.proto.constants[index].value)
            receiver = r(b)
            # NAMECALL prepares a CALL pair; it is metadata, not a real Luau
            # value that can be materialized as `@method:...` source text.
            self.method_calls[a] = (receiver, method)
            self.setreg(a + 1, receiver, pure=True, deps=self.reg_deps(b))
        elif n in ("CALL", "CALLFB"):
            defer_result = bool(next_item and next_item.name in CONDITIONAL and a in self._reads(next_item))
            self.call(
                item,
                iterator=bool(next_item and next_item.name.startswith("FORGPREP") and next_item.a == a),
                defer_result=defer_result,
            )
        elif n == "RETURN":
            if b:
                values = [r(i) for i in range(a, a + b - 1)]
            elif self.multret and self.multret[0] >= a:
                values = [r(i) for i in range(a, self.multret[0])] + [self.multret[1]]
            else:
                values = [r(a), "--[[ MULTRET desconhecido ]]"]
            self.line("return" + (" " + ", ".join(values) if values else ""))
        elif n in ("JUMP", "JUMPBACK", "JUMPX"):
            if item.target != item.pc + item.size: self.line(f"goto L{item.target}")
        elif n in ("JUMPIF", "JUMPIFNOT"):
            condition = r(a) if n == "JUMPIF" else f"not ({r(a)})"
            self.line(f"if {condition} then goto L{item.target} end")
        elif n in COMPARE:
            self.line(f"if {r(a)} {COMPARE[n]} {r(aux)} then goto L{item.target} end")
        elif n.startswith("JUMPXEQK"):
            if n == "JUMPXEQKNIL": value = "nil"
            elif n == "JUMPXEQKB": value = "true" if aux & 1 else "false"
            else: value = k(aux & 0xFFFFFF)
            operator = "~=" if aux >> 31 else "=="
            self.line(f"if {r(a)} {operator} {value} then goto L{item.target} end")
        elif n in BINARY:
            right = k(c) if n.endswith("K") else r(c)
            deps = self.reg_deps(b) | (frozenset() if n.endswith("K") else self.reg_deps(c))
            self.assign(a, f"({r(b)} {BINARY[n]} {right})", deps=deps)
        elif n in ("SUBRK", "DIVRK"):
            self.assign(a, f"({k(b)} {'-' if n == 'SUBRK' else '/'} {r(c)})", deps=self.reg_deps(c))
        elif n == "CONCAT":
            deps = frozenset().union(*(self.reg_deps(i) for i in range(b, c + 1)))
            self.assign(a, " .. ".join(r(i) for i in range(b, c + 1)), deps=deps)
        elif n == "NOT": self.assign(a, f"not ({r(b)})", deps=self.reg_deps(b))
        elif n == "MINUS": self.assign(a, f"-({r(b)})", deps=self.reg_deps(b))
        elif n == "LENGTH": self.assign(a, f"#{r(b)}", deps=self.reg_deps(b))
        elif n == "NEWTABLE": self.assign(a, "{}", pure=False)
        elif n == "DUPTABLE": self.assign(a, k(d), pure=False)
        elif n == "SETLIST":
            count = c - 1 if c else max(0, self.proto.max_stack_size - b)
            for offset in range(count): self.line(f"{r(a)}[{aux + offset + 1}] = {r(b + offset)}")
        elif n == "GETVARARGS":
            if b == 0:
                self.setreg(a, "...", pure=True)
                self.multret = (a, "...")
            else:
                count = b - 1
                self._assign_multiple(a, count, "...")
        elif n == "FORNPREP":
            for register in range(a, min(a + 4, len(self.regs))): self.materialize(register)
            self.line(f"-- FORNPREP {self.reg_name(a)}: limite={r(a)}, passo={r(a+1)}, índice={r(a+2)}")
            self.line(f"goto L{item.target}")
        elif n == "FORNLOOP":
            self.line(f"-- FORNLOOP {self.reg_name(a)}; variável visível {self.reg_name(a+3)}")
            self.line(f"if __degoat_fornloop({self.reg_name(a)}) then goto L{item.target} end")
        elif n.startswith("FORGPREP"):
            target = self.by_pc.get(item.target or -1)
            count = (target.aux or 0) & 0xff if target and target.name == "FORGLOOP" else 2
            for register in range(a, min(a + 3, len(self.regs))): self.materialize(register)
            # The VM writes iterator outputs into A+3... on FORGLOOP. Their old
            # symbolic values no longer describe those registers inside body.
            for register in range(a + 3, min(a + 3 + count, len(self.regs))):
                name = self._new_binding(register)
                self.regs[register] = Register(name, pure=True, binding=name)
            self.line(f"-- {n} {self.reg_name(a)}")
            self.line(f"goto L{item.target}")
        elif n == "FORGLOOP":
            self.line(f"-- FORGLOOP {self.reg_name(a)}; {aux & 0xff} variável(is)")
            self.line(f"if __degoat_forgloop({self.reg_name(a)}) then goto L{item.target} end")
        else:
            self.line(f"--[[ {n} A={a} B={b} C={c} AUX=0x{aux:08x} ]]" )
        return position + 1

    def jump_condition(self, item: Instruction) -> str:
        r = self.reg
        aux = item.aux or 0
        if item.name == "JUMPIF":
            return r(item.a)
        if item.name == "JUMPIFNOT":
            return self.negate(r(item.a))
        if item.name in COMPARE:
            return f"{r(item.a)} {COMPARE[item.name]} {r(aux & 0xff)}"
        if item.name.startswith("JUMPXEQK"):
            if item.name == "JUMPXEQKNIL":
                value = "nil"
            elif item.name == "JUMPXEQKB":
                value = "true" if aux & 1 else "false"
            else:
                value = const_expr(self.proto, aux & 0xFFFFFF)
            operator = "~=" if aux >> 31 else "=="
            return f"{r(item.a)} {operator} {value}"
        return f"--[[ condição {item.name} ]] true"

    @staticmethod
    def negate(condition: str) -> str:
        swaps = ((" ~= ", " == "), (" == ", " ~= "), (" <= ", " > "),
                 (" >= ", " < "), (" < ", " >= "), (" > ", " <= "))
        if condition.startswith("not (") and condition.endswith(")"):
            return condition[5:-1]
        for old, new in swaps:
            if old in condition:
                return condition.replace(old, new, 1)
        return f"not ({condition})"

    @staticmethod
    def _writes(item: Instruction) -> set[int]:
        one = {
            "LOADNIL", "LOADB", "LOADN", "LOADK", "LOADKX", "MOVE",
            "GETGLOBAL", "GETUPVAL", "GETIMPORT", "GETTABLEKS",
            "GETUDATAKS", "GETTABLE", "GETTABLEN", "NEWCLOSURE",
            "DUPCLOSURE", "ADD", "SUB",
            "MUL", "DIV", "MOD", "POW", "ADDK", "SUBK", "MULK",
            "DIVK", "MODK", "POWK", "AND", "OR", "ANDK", "ORK",
            "SUBRK", "DIVRK", "IDIV", "IDIVK", "CONCAT", "NOT",
            "MINUS", "LENGTH", "NEWTABLE", "DUPTABLE",
        }
        if item.name in one:
            return {item.a}
        if item.name in {"NAMECALL", "NAMECALLUDATA"}:
            return {item.a, item.a + 1}
        if item.name in {"CALL", "CALLFB"}:
            if item.c == 0:
                return {item.a}
            return set(range(item.a, item.a + max(item.c - 1, 0)))
        if item.name == "GETVARARGS":
            return set(range(item.a, item.a + max(item.b - 1, 1)))
        if item.name == "FORGLOOP":
            return set(range(item.a + 3, item.a + 3 + ((item.aux or 0) & 0xff)))
        if item.name == "FORNLOOP":
            return {item.a, item.a + 3}
        return set()

    @staticmethod
    def _reads(item: Instruction) -> set[int]:
        n, a, b, c = item.name, item.a, item.b, item.c
        if n == "MOVE": return {b}
        if n in {"GETTABLEKS", "GETUDATAKS", "GETTABLEN", "LENGTH", "NOT", "MINUS"}: return {b}
        if n == "GETTABLE": return {b, c}
        if n in {"SETTABLEKS", "SETUDATAKS", "SETTABLEN"}: return {a, b}
        if n == "SETTABLE": return {a, b, c}
        if n in {"SETGLOBAL", "SETUPVAL"}: return {a}
        if n == "CAPTURE" and item.a in (0, 1): return {b}
        if n in {"NAMECALL", "NAMECALLUDATA"}: return {b}
        if n in {"CALL", "CALLFB"}:
            return set(range(a, a + max(b, 1)))
        if n == "RETURN": return set(range(a, a + max(b - 1, 0)))
        if n in {"JUMPIF", "JUMPIFNOT"} or n.startswith("JUMPXEQK"): return {a}
        if n in COMPARE: return {a, (item.aux or 0) & 0xff}
        if n in BINARY:
            return {b} if n.endswith("K") else {b, c}
        if n in {"SUBRK", "DIVRK"}: return {c}
        if n == "CONCAT": return set(range(b, c + 1))
        if n == "SETLIST": return {a} | set(range(b, b + max(c - 1, 0)))
        if n in {"FORNPREP", "FORNLOOP"}: return set(range(a, a + 4))
        if n.startswith("FORGPREP") or n == "FORGLOOP": return set(range(a, a + 3))
        return set()

    def _written_between(self, start: int, end: int) -> set[int]:
        result: set[int] = set()
        for item in self.instructions[start:end]:
            result.update(register for register in self._writes(item) if register < len(self.regs))
        return result

    def _live_after(self, register: int, position: int) -> bool:
        for item in self.instructions[position:]:
            # FORGLOOP/FORNLOOP write visible iteration variables at the end
            # of the bytecode loop, but lexically those values are defined at
            # the matching PREP before the body executes.
            if item.name.startswith("FORGPREP"):
                loop = self.by_pc.get(item.target or -1)
                count = ((loop.aux or 0) & 0xff) if loop and loop.name == "FORGLOOP" else 2
                if item.a + 3 <= register < item.a + 3 + count:
                    return False
            if item.name == "FORNPREP" and register == item.a + 3:
                return False
            if register in self._reads(item):
                return True
            if register in self._writes(item):
                return False
        return False

    def _stabilize_merge(self, start: int, end: int, *, loop: bool = False) -> set[int]:
        written = self._written_between(start, end)
        live = {register for register in written if self._live_after(register, end)}
        if loop:
            for register in written:
                # Iteration-result registers of a nested loop are undefined at
                # the outer header and are defined by that nested FORGLOOP.
                # They are not outer loop-carried cells.
                if self.regs[register].def_pc == -2 and self.regs[register].binding is None:
                    continue
                for item in self.instructions[start:end]:
                    if register in self._reads(item):
                        live.add(register)
                        break
                    if register in self._writes(item):
                        break
        for register in live:
            self.materialize(register)
        return live

    def _reset_written(self, written: set[int], preserve: set[int] | None = None) -> None:
        preserved = preserve or set()
        for register in written:
            if register in preserved and self.regs[register].binding:
                name = self.regs[register].binding or self.regs[register].value
                self.regs[register] = Register(name, pure=True, binding=name)
            elif register not in preserved:
                self.regs[register] = Register(f"v{register}", deps=frozenset({register}))

    def _pure_for_condition(self, item: Instruction) -> bool:
        return item.name in {
            "LOADNIL", "LOADB", "LOADN", "LOADK", "LOADKX", "MOVE",
            "GETGLOBAL", "GETUPVAL", "GETIMPORT", "GETTABLEKS",
            "GETUDATAKS", "GETTABLE", "GETTABLEN", "ADD", "SUB", "MUL",
            "DIV", "MOD", "POW", "ADDK", "SUBK", "MULK", "DIVK",
            "MODK", "POWK", "AND", "OR", "ANDK", "ORK", "SUBRK",
            "DIVRK", "IDIV", "IDIVK", "CONCAT", "NOT", "MINUS", "LENGTH",
        }

    def _match_or_ladder(self, position: int, end: int) -> tuple[str, int, int] | None:
        first = self.instructions[position]
        body_position = self.position_by_pc.get(first.target or -1)
        if body_position is None or not position < body_position < end:
            return None

        saved_regs = list(self.regs)
        saved_multret = self.multret
        saved_lines = len(self.lines)
        saved_materialized = set(self.materialized)
        conditions: list[str] = []
        cursor = position
        join_position: int | None = None
        old_forced = self.force_registers
        self.force_registers = []
        try:
            while cursor < body_position:
                item = self.instructions[cursor]
                if item.name in CONDITIONAL:
                    if item.target == first.target:
                        conditions.append(self.jump_condition(item))
                        cursor += 1
                        continue
                    if cursor + 1 == body_position:
                        candidate = self.position_by_pc.get(item.target or -1)
                        if candidate is not None and candidate > body_position:
                            conditions.append(self.negate(self.jump_condition(item)))
                            join_position = candidate
                            cursor += 1
                            continue
                    break
                if not self._pure_for_condition(item):
                    break
                next_cursor = self.emit_instruction(item, cursor)
                if len(self.lines) != saved_lines or next_cursor <= cursor or next_cursor > body_position:
                    break
                cursor = next_cursor
        finally:
            self.force_registers = old_forced

        if cursor == body_position and join_position is not None and len(conditions) >= 2:
            return " or ".join(f"({condition})" for condition in conditions), body_position, join_position

        self.regs = saved_regs
        self.multret = saved_multret
        del self.lines[saved_lines:]
        self.materialized = saved_materialized
        return None

    def _repeat_at(self, position: int, end: int) -> tuple[int, int] | None:
        start_pc = self.instructions[position].pc
        for jumpback_position in range(position + 1, end):
            jumpback = self.instructions[jumpback_position]
            if jumpback.name != "JUMPBACK" or jumpback.target != start_pc:
                continue
            if jumpback_position > position:
                condition_position = jumpback_position - 1
                condition = self.instructions[condition_position]
                if condition.name in CONDITIONAL and condition.target == jumpback.pc + jumpback.size:
                    return condition_position, jumpback_position
            return jumpback_position, jumpback_position
        return None

    def _terminal_return(self, position: int) -> str | None:
        if not 0 <= position < len(self.instructions):
            return None
        item = self.instructions[position]
        values = {"LOADNIL": "nil", "LOADB": "true" if item.b else "false", "LOADN": str(item.d)}
        if item.name == "LOADK":
            value = const_expr(self.proto, item.d)
        else:
            value = values.get(item.name)
        if value is None or position + 1 >= len(self.instructions):
            return None
        returned = self.instructions[position + 1]
        if returned.name == "RETURN" and returned.a == item.a and returned.b == 2:
            return value
        return None

    def _direct_return(self, position: int) -> str | None:
        if not 0 <= position < len(self.instructions):
            return None
        item = self.instructions[position]
        if item.name != "RETURN":
            return None
        if item.b == 1:
            return "return"
        if item.b == 2:
            return f"return {self.reg(item.a)}"
        return None

    def _match_skip_return(self, position: int, target_position: int) -> tuple[str, int] | None:
        """Match `if A ... if B goto after_return; return` as a guard."""
        if target_position + 1 >= len(self.instructions):
            return None
        returned = self.instructions[target_position]
        if returned.name != "RETURN" or returned.b != 1 or target_position <= position + 1:
            return None
        last = self.instructions[target_position - 1]
        after_return_pc = returned.pc + returned.size
        if last.name not in CONDITIONAL or last.target != after_return_pc:
            return None

        saved_regs = list(self.regs)
        saved_multret = self.multret
        saved_lines = len(self.lines)
        saved_materialized = set(self.materialized)
        success = [self.negate(self.jump_condition(self.instructions[position]))]
        cursor = position + 1
        old_forced = self.force_registers
        self.force_registers = []
        try:
            while cursor < target_position - 1:
                item = self.instructions[cursor]
                if item.name in CONDITIONAL or item.name in {"JUMP", "JUMPX", "JUMPBACK", "RETURN"}:
                    break
                next_cursor = self.emit_instruction(item, cursor)
                if len(self.lines) != saved_lines or next_cursor <= cursor or next_cursor > target_position - 1:
                    break
                cursor = next_cursor
            if cursor == target_position - 1:
                success.append(self.jump_condition(last))
                return " and ".join(f"({part})" for part in success), target_position + 1
        finally:
            self.force_registers = old_forced

        self.regs = saved_regs
        self.multret = saved_multret
        del self.lines[saved_lines:]
        self.materialized = saved_materialized
        return None

    def render_range(
        self,
        start: int,
        end: int,
        *,
        loop_continue: int | None = None,
        loop_exit: int | None = None,
        branch_exit: int | None = None,
    ) -> None:
        position = start
        while position < end:
            item = self.instructions[position]

            repeat = self._repeat_at(position, end)
            if repeat is not None:
                condition_position, jumpback_position = repeat
                forced = self._stabilize_merge(position, jumpback_position, loop=True)
                written = self._written_between(position, jumpback_position)
                if condition_position == jumpback_position:
                    self.line("while true do")
                    with self.nested(force=forced):
                        self.render_range(position, jumpback_position, loop_continue=position, loop_exit=jumpback_position + 1)
                    self.line("end")
                else:
                    condition_item = self.instructions[condition_position]
                    self.line("repeat")
                    with self.nested(force=forced):
                        self.render_range(position, condition_position, loop_continue=position, loop_exit=jumpback_position + 1)
                    self.line(f"until {self.jump_condition(condition_item)}")
                self._reset_written(written, forced)
                position = jumpback_position + 1
                continue

            # Internal anchor removed by render_body unless a fallback edge
            # genuinely needs a Luau label at this program counter.
            self.line(f"\x00PC:{item.pc}")

            if item.name.startswith("FORGPREP"):
                loop_position = self.position_by_pc.get(item.target or -1)
                if loop_position is not None and position < loop_position < end:
                    loop = self.instructions[loop_position]
                    if loop.name == "FORGLOOP" and loop.target == item.pc + item.size:
                        count = (loop.aux or 0) & 0xff
                        variables: list[str] = []
                        for register in range(item.a + 3, item.a + 3 + count):
                            if register < len(self.regs):
                                name = self._new_binding(register, loop_position)
                                variables.append(name)
                                self.regs[register] = Register(name, pure=True, binding=name, def_pc=loop.pc)
                        iterator = self.reg(item.a)
                        self.line(f"for {', '.join(variables)} in {iterator} do")
                        forced = self._stabilize_merge(position + 1, loop_position, loop=True)
                        written = self._written_between(position + 1, loop_position)
                        with self.nested(force=forced):
                            self.render_range(
                                position + 1,
                                loop_position,
                                loop_continue=loop_position,
                                loop_exit=loop_position + 1,
                                branch_exit=branch_exit,
                            )
                        self.line("end")
                        self._reset_written(written, forced)
                        position = loop_position + 1
                        continue

            if item.name == "FORNPREP":
                loop_position = self.position_by_pc.get(item.target or -1)
                if loop_position is not None and position < loop_position < end:
                    loop = self.instructions[loop_position]
                    if loop.name == "FORNLOOP" and loop.target == item.pc + item.size:
                        variable = self._new_binding(item.a + 3, loop_position)
                        self.regs[item.a + 3] = Register(variable, pure=True, binding=variable, def_pc=loop.pc)
                        initial, limit, step = self.reg(item.a), self.reg(item.a + 1), self.reg(item.a + 2)
                        suffix = "" if step == "1" else f", {step}"
                        self.line(f"for {variable} = {initial}, {limit}{suffix} do")
                        forced = self._stabilize_merge(position + 1, loop_position, loop=True)
                        written = self._written_between(position + 1, loop_position)
                        with self.nested(force=forced):
                            self.render_range(
                                position + 1,
                                loop_position,
                                loop_continue=loop_position,
                                loop_exit=loop_position + 1,
                                branch_exit=branch_exit,
                            )
                        self.line("end")
                        self._reset_written(written, forced)
                        position = loop_position + 1
                        continue

            if item.name in CONDITIONAL and item.target is not None:
                target_position = self.position_by_pc.get(item.target)
                if target_position == loop_exit:
                    self.line(f"if {self.jump_condition(item)} then break end")
                    position += 1
                    continue
                if target_position == loop_continue:
                    self.line(f"if {self.jump_condition(item)} then continue end")
                    position += 1
                    continue
                if target_position == branch_exit:
                    forced = self._stabilize_merge(position + 1, end)
                    written = self._written_between(position + 1, end)
                    self.line(f"if {self.negate(self.jump_condition(item))} then")
                    with self.nested(force=forced):
                        self.render_range(
                            position + 1,
                            end,
                            loop_continue=loop_continue,
                            loop_exit=loop_exit,
                            branch_exit=branch_exit,
                        )
                    self.line("end")
                    self._reset_written(written, forced)
                    position = end
                    continue
                if target_position is not None and target_position > end:
                    terminal = self._terminal_return(target_position)
                    if terminal is not None:
                        self.line(f"if {self.jump_condition(item)} then return {terminal} end")
                        position += 1
                        continue
                    direct = self._direct_return(target_position)
                    if direct is not None:
                        self.line(f"if {self.jump_condition(item)} then {direct} end")
                        position += 1
                        continue
                    # The edge skips the current structured arm into a shared
                    # continuation. Duplicate that continuation inside the
                    # condition; this is preferable to emitting non-Luau goto
                    # syntax and preserves the taken path.
                    detour_end = branch_exit if branch_exit is not None and target_position < branch_exit else len(self.instructions)
                    saved_regs = list(self.regs)
                    saved_multret = self.multret
                    saved_methods = dict(self.method_calls)
                    self.line(f"if {self.jump_condition(item)} then")
                    with self.nested():
                        self.render_range(
                            target_position,
                            detour_end,
                            loop_continue=loop_continue,
                            loop_exit=loop_exit,
                            branch_exit=branch_exit,
                        )
                        if loop_continue is not None and detour_end != len(self.instructions):
                            self.line("continue")
                    self.line("end")
                    self.regs = saved_regs
                    self.multret = saved_multret
                    self.method_calls = saved_methods
                    position += 1
                    continue
                if target_position is not None and position < target_position <= end:
                    guard = self._match_skip_return(position, target_position)
                    if guard is not None:
                        success, next_position = guard
                        self.line(f"if not ({success}) then return end")
                        position = next_position
                        continue

                    # Luau's canonical boolean selection:
                    #   jump-if condition -> LOADB true
                    #   LOADB false, skip 1
                    # becomes the condition expression itself.
                    fallthrough = self.instructions[position + 1] if position + 1 < end else None
                    target_load = self.instructions[target_position] if target_position < end else None
                    if (fallthrough and target_load and fallthrough.name == target_load.name == "LOADB"
                            and fallthrough.a == target_load.a and fallthrough.c
                            and self.position_by_pc.get(fallthrough.pc + 1 + fallthrough.c) == target_position + 1):
                        condition = self.jump_condition(item)
                        jump_value = bool(target_load.b)
                        fall_value = bool(fallthrough.b)
                        if jump_value and not fall_value:
                            value = condition
                        elif fall_value and not jump_value:
                            value = self.negate(condition)
                        else:
                            value = "true" if jump_value else "false"
                        self.assign(fallthrough.a, value)
                        position = target_position + 1
                        continue

                    before_target = self.instructions[target_position - 1] if target_position > position + 1 else None

                    if before_target and before_target.name == "JUMPBACK" and before_target.target == item.pc:
                        condition = self.negate(self.jump_condition(item))
                        forced = self._stabilize_merge(position + 1, target_position - 1, loop=True)
                        written = self._written_between(position + 1, target_position - 1)
                        self.line(f"while {condition} do")
                        with self.nested(force=forced):
                            self.render_range(
                                position + 1,
                                target_position - 1,
                                loop_continue=position,
                                loop_exit=target_position,
                            )
                        self.line("end")
                        self._reset_written(written, forced)
                        position = target_position
                        continue

                    ladder = self._match_or_ladder(position, end)
                    if ladder is not None:
                        condition, body_position, join_position = ladder
                        forced = self._stabilize_merge(body_position, join_position)
                        written = self._written_between(body_position, join_position)
                        self.line(f"if {condition} then")
                        with self.nested(force=forced):
                            self.render_range(
                                body_position,
                                join_position,
                                loop_continue=loop_continue,
                                loop_exit=loop_exit,
                                branch_exit=join_position,
                            )
                        self.line("end")
                        self._reset_written(written, forced)
                        position = join_position
                        continue

                    jump_before_target = before_target if before_target and before_target.name in {"JUMP", "JUMPX"} else None
                    join_position = self.position_by_pc.get(jump_before_target.target or -1) if jump_before_target else None
                    if jump_before_target and join_position is not None and join_position > target_position:
                        forced = self._stabilize_merge(position + 1, join_position)
                        written = self._written_between(position + 1, join_position)
                        self.line(f"if {self.negate(self.jump_condition(item))} then")
                        with self.nested(force=forced):
                            self.render_range(
                                position + 1,
                                target_position - 1,
                                loop_continue=loop_continue,
                                loop_exit=loop_exit,
                                branch_exit=join_position,
                            )
                        self.line("else")
                        with self.nested(force=forced):
                            self.render_range(
                                target_position,
                                join_position,
                                loop_continue=loop_continue,
                                loop_exit=loop_exit,
                                branch_exit=join_position,
                            )
                        self.line("end")
                        self._reset_written(written, forced)
                        position = join_position
                        continue

                    forced = self._stabilize_merge(position + 1, target_position)
                    written = self._written_between(position + 1, target_position)
                    self.line(f"if {self.negate(self.jump_condition(item))} then")
                    with self.nested(force=forced):
                        self.render_range(
                            position + 1,
                            target_position,
                            loop_continue=loop_continue,
                            loop_exit=loop_exit,
                            branch_exit=branch_exit,
                        )
                    self.line("end")
                    self._reset_written(written, forced)
                    position = target_position
                    continue

            if item.name in {"JUMP", "JUMPX", "JUMPBACK"}:
                target_position = self.position_by_pc.get(item.target or -1)
                if target_position == loop_continue:
                    self.line("continue")
                    position += 1
                    continue
                if target_position == loop_exit:
                    self.line("break")
                    position += 1
                    continue
                if target_position == branch_exit:
                    position = end
                    continue
                if (loop_continue is not None and target_position is not None
                        and self.instructions[target_position].name == "JUMPBACK"
                        and self.position_by_pc.get(self.instructions[target_position].target or -1) == loop_continue):
                    position = end
                    continue
                if loop_continue is not None and target_position is not None and target_position < position:
                    self.line("continue")
                    position = end
                    continue
                self.unstructured_targets.add(item.target or -1)
                self.line(f"goto L{item.target} --[[ fluxo não estruturado ]]" )
                position += 1
                continue

            if item.name == "RETURN":
                self.emit_instruction(item, position)
                # RETURN has no fallthrough. Alternate target blocks have
                # already been structured or duplicated at their incoming
                # branch, so emitting linear bytes after it creates dead code.
                position = end
                continue

            if item.name in CONDITIONAL and item.target is not None:
                self.unstructured_targets.add(item.target)

            position = self.emit_instruction(item, position)

    def render_body(self) -> list[str]:
        self.render_range(0, len(self.instructions))
        rebuilt: list[str] = []
        for line in self.lines:
            marker = re.search(r"\x00PC:(-?\d+)$", line)
            if marker:
                pc = int(marker.group(1))
                if pc in self.unstructured_targets:
                    rebuilt.append(line[: marker.start()] + f"::L{pc}::")
                continue
            rebuilt.append(line)
        self.lines = rebuilt
        if self.hoisted:
            self.lines.insert(0, self.indent + "local " + ", ".join(sorted(self.hoisted)))
        return self.lines


def decompile(chunk: Chunk) -> str:
    proto = chunk.main
    emitter = Emitter(chunk, proto)
    body = emitter.render_body()
    header = [
        "-- Decompilado por DeGOAT",
        f"-- Luau bytecode v{chunk.version}; tipos v{chunk.type_version}; opcodes {chunk.opcode_encoding}",
        "-- Nomes semânticos exigem evidência; baixa confiança permanece como vN.",
    ]
    if chunk.trailer:
        header.append(f"-- Trailer opaco preservado: {len(chunk.trailer)} bytes ({chunk.trailer.hex()})")
    return "\n".join(header + [""] + body) + "\n"
