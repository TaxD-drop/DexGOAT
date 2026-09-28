from __future__ import annotations

import re
from dataclasses import dataclass

from .disasm import import_path
from .model import Chunk, Proto
from .opcodes import decode


LUA_KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for",
    "function", "goto", "if", "in", "local", "nil", "not", "or",
    "repeat", "return", "then", "true", "until", "while", "continue",
}


def identifier(value: str, fallback: str) -> str:
    value = re.sub(r"[^A-Za-z0-9_]", "_", value)
    value = re.sub(r"_+", "_", value).strip("_")
    if not value or value[0].isdigit() or value in LUA_KEYWORDS:
        return fallback
    return value


def camel(value: str) -> str:
    clean = identifier(value, "value")
    return clean[:1].lower() + clean[1:]


@dataclass(frozen=True)
class Hint:
    """Description of one value, not of one physical VM register."""

    site: tuple[int, int]
    kind: str
    name: str | None = None
    value: object | None = None
    producer: str | None = None


@dataclass(frozen=True)
class NameHint:
    name: str
    confidence: int
    reason: str


def _constant(proto: Proto, index: int) -> object | None:
    if 0 <= index < len(proto.constants):
        return proto.constants[index].value
    return None


def _written_registers(item) -> set[int]:
    one = {
        "LOADNIL", "LOADB", "LOADN", "LOADK", "LOADKX", "MOVE",
        "GETGLOBAL", "GETUPVAL", "GETIMPORT", "GETTABLEKS", "GETUDATAKS",
        "GETTABLE", "GETTABLEN", "NEWCLOSURE", "DUPCLOSURE", "ADD", "SUB",
        "MUL", "DIV", "MOD", "POW", "ADDK", "SUBK", "MULK", "DIVK",
        "MODK", "POWK", "AND", "OR", "ANDK", "ORK", "SUBRK", "DIVRK",
        "IDIV", "IDIVK", "CONCAT", "NOT", "MINUS", "LENGTH", "NEWTABLE",
        "DUPTABLE",
    }
    if item.name in one:
        return {item.a}
    if item.name in {"NAMECALL", "NAMECALLUDATA"}:
        return {item.a, item.a + 1}
    if item.name in {"CALL", "CALLFB"}:
        return {item.a} if item.c == 0 else set(range(item.a, item.a + max(item.c - 1, 0)))
    return set()


def _child_upvalue_names(chunk: Chunk, proto: Proto) -> dict[int, NameHint]:
    """Project strong evidence inside a child back to its capture slots."""

    hints = infer_value_names(chunk, proto)
    instructions = decode(proto.code)
    definitions: dict[int, tuple[int, int]] = {
        register: (-1, register) for register in range(proto.num_params)
    }
    result: dict[int, NameHint] = {}

    def keep(upvalue: int, hint: NameHint) -> None:
        previous = result.get(upvalue)
        if previous is None or hint.confidence > previous.confidence:
            result[upvalue] = hint

    for position, item in enumerate(instructions):
        if item.name == "GETUPVAL":
            hint = hints.get((item.pc, item.a))
            if hint:
                keep(item.b, hint)
        elif item.name == "SETUPVAL":
            hint = hints.get(definitions.get(item.a, (-999, -999)))
            if hint:
                keep(item.b, hint)
        elif item.name in {"NEWCLOSURE", "DUPCLOSURE"}:
            child_id = (proto.children[item.d] if item.name == "NEWCLOSURE" and 0 <= item.d < len(proto.children)
                        else _constant(proto, item.d))
            if isinstance(child_id, int) and 0 <= child_id < len(chunk.protos):
                nested = _child_upvalue_names(chunk, chunk.protos[child_id])
                cursor = position + 1
                slot = 0
                while cursor < len(instructions) and instructions[cursor].name == "CAPTURE":
                    capture = instructions[cursor]
                    if capture.a == 2 and slot in nested:
                        keep(capture.b, nested[slot])
                    cursor += 1
                    slot += 1
        for register in _written_registers(item):
            definitions[register] = (item.pc, register)
    return result


def infer_value_names(chunk: Chunk, proto: Proto) -> dict[tuple[int, int], NameHint]:
    """Infer names per definition site.

    Luau aggressively recycles registers.  Associating a name with ``R14`` for
    an entire function therefore produces actively misleading source.  This
    analysis keys every proposal by ``(definition_pc, register)`` and only
    accepts semantic evidence with a known confidence.
    """

    state: dict[int, Hint] = {}
    proposals: dict[tuple[int, int], NameHint] = {}

    def define(register: int, pc: int, kind: str, name: str | None = None,
               value: object | None = None, producer: str | None = None) -> Hint:
        result = Hint((pc, register), kind, name, value, producer)
        state[register] = result
        return result

    def propose(value: Hint | None, name: str | None, confidence: int, reason: str) -> None:
        if value is None or name is None:
            return
        clean = identifier(name, f"v{value.site[1]}")
        previous = proposals.get(value.site)
        if previous is None or confidence > previous.confidence:
            proposals[value.site] = NameHint(clean, confidence, reason)

    for register in range(proto.num_params):
        value = define(register, -1, "parameter", f"arg{register + 1}")
        propose(value, value.name, 100, "parâmetro")

    instructions = decode(proto.code)
    for position, item in enumerate(instructions):
        n, a, b, c, d, aux = item.name, item.a, item.b, item.c, item.d, item.aux or 0

        if n in {"LOADNIL", "LOADB", "LOADN"}:
            define(a, item.pc, "constant", value={"LOADNIL": None, "LOADB": bool(b), "LOADN": d}[n])
        elif n in {"LOADK", "LOADKX"}:
            define(a, item.pc, "constant", value=_constant(proto, d if n == "LOADK" else aux))
        elif n == "MOVE":
            source = state.get(b)
            define(a, item.pc, source.kind if source else "unknown",
                   source.name if source else None, source.value if source else None,
                   source.producer if source else None)
        elif n == "GETIMPORT":
            iid = _constant(proto, d)
            path = import_path(proto, iid if isinstance(iid, int) else aux).replace('"', "")
            define(a, item.pc, "path", path.rsplit(".", 1)[-1], path, path)
        elif n == "GETGLOBAL":
            name = str(_constant(proto, aux) or f"global{a}")
            define(a, item.pc, "path", name, name, name)
        elif n == "GETUPVAL":
            define(a, item.pc, "upvalue", producer="upvalue")
        elif n in {"GETTABLEKS", "GETUDATAKS"}:
            index = aux & (0xFFFF if n == "GETUDATAKS" else 0xFFFFFFFF)
            key = str(_constant(proto, index) or f"field{index}")
            base = state.get(b)
            value = define(a, item.pc, "field", key, base, key)
            if base and base.kind == "upvalue" and key in {"Position", "Size", "CFrame"}:
                propose(base, "rootPart", 80, f"upvalue usado como objeto espacial ({key})")
            # These are object identities, rather than arbitrary terminal fields.
            recognized = {
                "LocalPlayer": ("player", 92),
                "Character": ("character", 78),
                "HumanoidRootPart": ("rootPart", 82),
            }
            if key in recognized:
                name, score = recognized[key]
                propose(value, name, score, f"campo Roblox {key}")
        elif n in {"GETTABLE", "GETTABLEN"}:
            define(a, item.pc, "index", producer="index")
        elif n in {"NAMECALL", "NAMECALLUDATA"}:
            index = aux & (0xFFFF if n == "NAMECALLUDATA" else 0xFFFFFFFF)
            method = str(_constant(proto, index) or "method")
            receiver = state.get(b)
            # NAMECALL does not create the call result; it stages function/self.
            define(a, item.pc, "method", method, receiver, method)
            state[a + 1] = receiver or Hint((item.pc, a + 1), "unknown")
            if method == "Play" and receiver:
                if receiver.producer == "newSound":
                    propose(receiver, "sound", 98, "resultado de newSound usado com Play")
                elif receiver.producer == "Create":
                    propose(receiver, "tween", 88, "resultado de TweenService:Create")
        elif n in {"CALL", "CALLFB"}:
            function = state.get(a)
            args = [state.get(i) for i in range(a + 1, a + max(b, 1))]
            explicit = args[1:] if function and function.kind == "method" else args
            name: str | None = None
            confidence = 0
            reason = ""
            producer = function.name if function else None

            if function and function.kind == "method":
                first = explicit[0].value if explicit and explicit[0] else None
                if function.name == "GetService" and isinstance(first, str):
                    name, confidence, reason = first, 100, "GetService com literal"
                elif function.name in {"WaitForChild", "FindFirstChild"} and isinstance(first, str):
                    semantic = {"HumanoidRootPart": "rootPart"}.get(first, first)
                    name, confidence, reason = semantic, 86, f"{function.name} com literal"
                elif function.name == "newSound":
                    name, confidence, reason = "sound", 98, "retorno de newSound"
                elif function.name == "Create":
                    name, confidence, reason = "tween", 88, "retorno de Create usado como tween"
                    if explicit:
                        propose(explicit[-1], "goal", 84, "tabela goal passada a TweenService:Create")
                elif function.name == "Wait" and function.value and isinstance(function.value, Hint):
                    receiver = function.value
                    if receiver.name == "CharacterAdded":
                        name, confidence, reason = "character", 88, "CharacterAdded:Wait"
            elif function and function.name in {"Load", "load"} and args and args[0] and isinstance(args[0].value, str):
                name, confidence, reason = str(args[0].value), 92, "loader com nome literal"
            elif function and function.kind == "path":
                if function.name == "require" and args and args[0]:
                    module_name = args[0].name
                    if module_name:
                        name, confidence, reason = module_name, 84, "módulo requerido"
                elif function.name == "new" and function.value == "Instance.new":
                    first = args[0].value if args and args[0] else None
                    if isinstance(first, str):
                        name, confidence, reason = camel(first), 90, "Instance.new com classe literal"
                elif function.name == "new" and function.value == "TweenInfo.new":
                    name, confidence, reason = "tweenInfo", 82, "retorno de TweenInfo.new"
            elif function and function.kind == "field" and function.name == "newSound":
                name, confidence, reason = "sound", 98, "retorno de newSound"
                producer = "newSound"

            result_count = max(c - 1, 1)
            for register in range(a, a + result_count):
                value = define(register, item.pc, "result", name if register == a else None,
                               function, producer if register == a else None)
                if register == a:
                    propose(value, name, confidence, reason)

            # Use-site evidence: table.insert(list, value) names the first arg.
            if function and function.kind == "path" and function.value == "table.insert" and args:
                propose(args[0], "items", 72, "primeiro argumento de table.insert")
        elif n in {"NEWTABLE", "DUPTABLE"}:
            define(a, item.pc, "table", producer=n)
        elif n in {"NEWCLOSURE", "DUPCLOSURE"}:
            child_id = proto.children[d] if n == "NEWCLOSURE" and 0 <= d < len(proto.children) else _constant(proto, d)
            child = chunk.protos[int(child_id)] if isinstance(child_id, int) and 0 <= child_id < len(chunk.protos) else None
            value = define(a, item.pc, "closure", child.debug_name if child else None, producer="closure")
            if child and child.debug_name and child.debug_name != "<main>":
                propose(value, child.debug_name, 90, "nome de debug da closure")
            if child:
                child_hints = _child_upvalue_names(chunk, child)
                cursor = position + 1
                slot = 0
                while cursor < len(instructions) and instructions[cursor].name == "CAPTURE":
                    capture = instructions[cursor]
                    if capture.a in (0, 1) and slot in child_hints:
                        inherited = child_hints[slot]
                        propose(state.get(capture.b), inherited.name,
                                max(75, inherited.confidence - 2),
                                f"uso no upvalue {slot} de P{child.id}: {inherited.reason}")
                    cursor += 1
                    slot += 1
        elif n == "SETTABLEKS":
            key = str(_constant(proto, aux) or "")
            source, base = state.get(a), state.get(b)
            if source and source.kind == "closure":
                propose(base, "module", 88, f"tabela que recebe função {key}")
            if base and base.kind == "table" and key in {"sources", "rate_period", "is_full_wait"}:
                propose(base, "data", 86, f"tabela de estado com campo {key}")
            if base and base.kind == "table" and key in {"Size", "Position", "Orientation", "Transparency"}:
                propose(base, "goal", 84, f"tabela goal com campo {key}")
            if source and source.kind == "field" and source.name == key == "Size":
                propose(source, "originalSize", 90, "Size preservado antes da mutação")
        elif n == "RETURN" and b == 2 and proto.id == chunk.main_id:
            value = state.get(a)
            if value and value.kind == "table":
                propose(value, "module", 92, "tabela retornada pelo módulo")
        elif n == "FORGLOOP":
            count = aux & 0xFF
            if count == 1:
                value = define(a + 3, item.pc, "iteration")
                propose(value, "value", 75, "valor de iteração")
            else:
                key = define(a + 3, item.pc, "iteration")
                value = define(a + 4, item.pc, "iteration")
                propose(key, "key", 75, "chave de iteração")
                propose(value, "value", 75, "valor de iteração")
        elif n == "FORNLOOP":
            value = define(a + 3, item.pc, "iteration")
            propose(value, "index", 75, "índice numérico")

    return proposals


def infer_register_names(chunk: Chunk, proto: Proto) -> dict[int, str]:
    """Compatibility view for callers that still expect one name/register.

    The decompiler itself deliberately does not use this lossy projection.
    """

    result = {register: f"v{register}" for register in range(proto.max_stack_size)}
    scores: dict[int, int] = {}
    for (_, register), hint in infer_value_names(chunk, proto).items():
        if hint.confidence > scores.get(register, -1):
            result[register] = hint.name
            scores[register] = hint.confidence
    return result
