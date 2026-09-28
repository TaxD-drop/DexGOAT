from __future__ import annotations

import base64
import json
import struct
from pathlib import Path

from .model import Chunk, Constant, Local, Proto
from .opcodes import AUX_OPS, NAMES


class BytecodeError(ValueError):
    """Invalid, unsupported or truncated Luau bytecode."""


class Reader:
    def __init__(self, data: bytes):
        self.data = data
        self.offset = 0

    def take(self, size: int) -> bytes:
        if size < 0 or self.offset + size > len(self.data):
            raise BytecodeError(f"bytecode truncado no offset 0x{self.offset:x}")
        value = self.data[self.offset : self.offset + size]
        self.offset += size
        return value

    def u8(self) -> int:
        return self.take(1)[0]

    def u32(self) -> int:
        return struct.unpack("<I", self.take(4))[0]

    def i32(self) -> int:
        return struct.unpack("<i", self.take(4))[0]

    def f32(self) -> float:
        return struct.unpack("<f", self.take(4))[0]

    def f64(self) -> float:
        return struct.unpack("<d", self.take(8))[0]

    def varint(self, *, limit: int = 0xFFFFFFFF) -> int:
        value = 0
        shift = 0
        for _ in range(10):
            byte = self.u8()
            value |= (byte & 0x7F) << shift
            if not byte & 0x80:
                if value > limit:
                    raise BytecodeError(f"varint fora do limite no offset 0x{self.offset:x}")
                return value
            shift += 7
        raise BytecodeError(f"varint inválido no offset 0x{self.offset:x}")


def normalize_input(data: bytes) -> bytes:
    """Accept raw Luau, base64/hex text, or the lua.expert JSON request shape."""
    if not data:
        raise BytecodeError("entrada vazia")
    if data[0] == 0 or 3 <= data[0] <= 12:
        return data

    text = data.decode("utf-8-sig", errors="strict").strip()
    if text.startswith("{"):
        try:
            value = json.loads(text)
            text = value["script"]
        except (json.JSONDecodeError, KeyError, TypeError) as exc:
            raise BytecodeError("JSON precisa conter uma string 'script'") from exc
    compact = "".join(text.split())
    if compact.startswith("0x"):
        compact = compact[2:]
    try:
        if compact and len(compact) % 2 == 0 and all(c in "0123456789abcdefABCDEF" for c in compact):
            decoded = bytes.fromhex(compact)
        else:
            decoded = base64.b64decode(compact, validate=True)
    except (ValueError, base64.binascii.Error) as exc:
        raise BytecodeError("entrada não é bytecode Luau, hex ou base64 válido") from exc
    if not decoded or not (decoded[0] == 0 or 3 <= decoded[0] <= 12):
        raise BytecodeError("conteúdo decodificado não possui uma versão Luau reconhecida")
    return decoded


def read_file(path: str | Path) -> bytes:
    return normalize_input(Path(path).read_bytes())


def _string(r: Reader, strings: list[str]) -> str | None:
    index = r.varint(limit=len(strings))
    if index == 0:
        return None
    return strings[index - 1]


def _constant(r: Reader, strings: list[str], version: int) -> Constant:
    tag = r.u8()
    if tag == 0:
        return Constant("nil")
    if tag == 1:
        return Constant("boolean", bool(r.u8()))
    if tag == 2:
        return Constant("number", r.f64())
    if tag == 3:
        return Constant("string", _string(r, strings))
    if tag == 4:
        return Constant("import", r.u32())
    if tag == 5:
        return Constant("table", [r.varint() for _ in range(r.varint(limit=1_000_000))])
    if tag == 6:
        return Constant("closure", r.varint())
    if tag == 7:
        return Constant("vector", (r.f32(), r.f32(), r.f32(), r.f32()))
    if tag == 8 and version >= 7:
        count = r.varint(limit=1_000_000)
        return Constant("table_with_constants", [(r.varint(), r.i32()) for _ in range(count)])
    if tag == 9 and version >= 8:
        negative = r.u8()
        magnitude = r.varint(limit=0xFFFFFFFFFFFFFFFF)
        return Constant("integer", -magnitude if negative else magnitude)
    if tag == 10 and version >= 10:
        class_name = r.varint()
        properties = r.varint(limit=1_000_000)
        methods = r.varint(limit=1_000_000)
        members = [r.varint() for _ in range(properties + methods)]
        return Constant("class_shape", (class_name, properties, methods, members))
    if tag == 11 and version >= 12:
        return Constant("vector_double", (r.f64(), r.f64(), r.f64(), r.f64()))
    raise BytecodeError(f"tag de constante {tag} inválida no offset 0x{r.offset - 1:x}")


def parse(data: bytes, *, max_size: int = 64 * 1024 * 1024) -> Chunk:
    data = normalize_input(data)
    if len(data) > max_size:
        raise BytecodeError(f"bytecode excede o limite de {max_size} bytes")
    r = Reader(data)
    version = r.u8()
    if version == 0:
        raise BytecodeError("erro do compilador: " + data[1:].decode("utf-8", errors="replace"))
    if version < 3 or version > 12:
        raise BytecodeError(f"versão Luau {version} não suportada (esperado 3..12)")
    type_version = r.u8() if version >= 4 else 0
    if version >= 4 and type_version not in (1, 2, 3):
        raise BytecodeError(f"versão de tipos Luau {type_version} não suportada")

    string_count = r.varint(limit=2_000_000)
    strings = []
    for _ in range(string_count):
        length = r.varint(limit=max_size)
        strings.append(r.take(length).decode("utf-8", errors="surrogateescape"))

    userdata_types: dict[int, str] = {}
    if type_version == 3:
        index = r.u8()
        while index:
            userdata_types[index] = _string(r, strings) or "userdata"
            index = r.u8()

    proto_count = r.varint(limit=1_000_000)
    if proto_count == 0:
        raise BytecodeError("chunk Luau não contém protos")
    protos: list[Proto] = []
    for proto_id in range(proto_count):
        proto_size = r.varint(limit=max_size) if version >= 12 else None
        proto_start = r.offset
        proto = Proto(
            id=proto_id,
            max_stack_size=r.u8(),
            num_params=r.u8(),
            num_upvalues=r.u8(),
            is_vararg=bool(r.u8()),
        )
        if version >= 4:
            proto.flags = r.u8()
            type_size = r.varint(limit=max_size)
            proto.type_info = r.take(type_size)

        code_size = r.varint(limit=16_000_000)
        proto.code = [r.u32() for _ in range(code_size)]
        const_count = r.varint(limit=4_000_000)
        proto.constants = [_constant(r, strings, version) for _ in range(const_count)]
        child_count = r.varint(limit=1_000_000)
        proto.children = [r.varint(limit=max(proto_count - 1, 0)) for _ in range(child_count)]
        proto.line_defined = r.varint()
        proto.debug_name = _string(r, strings)

        if r.u8():
            gap_log2 = r.u8()
            deltas = list(r.take(code_size))
            intervals = ((code_size - 1) >> gap_log2) + 1 if code_size else 0
            absolute = [r.i32() for _ in range(intervals)]
            last_delta = 0
            last_abs = 0
            for pc, delta in enumerate(deltas):
                last_delta = (last_delta + delta) & 0xFF
                if pc & ((1 << gap_log2) - 1) == 0:
                    last_abs += absolute[pc >> gap_log2]
                proto.line_info.append(last_abs + last_delta)

        if r.u8():
            local_count = r.varint(limit=1_000_000)
            for _ in range(local_count):
                proto.locals.append(Local(_string(r, strings), r.varint(), r.varint(), r.u8()))
            upvalue_count = r.varint(limit=1_000_000)
            proto.upvalue_names = [_string(r, strings) for _ in range(upvalue_count)]
            if upvalue_count != proto.num_upvalues:
                raise BytecodeError(f"proto {proto_id}: contagem de upvalues inconsistente")

        if version >= 11:
            feedback_count = r.varint(limit=1_000_000)
            for _ in range(feedback_count):
                r.u8()
                r.varint()
        if version >= 12 and proto.flags & 1:
            r.varint(limit=0xFFFFFFFFFFFFFFFF)
        if proto_size is not None:
            expected = proto_start + proto_size
            if r.offset > expected:
                raise BytecodeError(f"proto {proto_id} ultrapassa o tamanho declarado")
            r.offset = expected
        protos.append(proto)

    main_id = r.varint(limit=max(proto_count - 1, 0))

    # Roblox serializes the same Luau instruction words but transforms the low
    # opcode byte with encodeOp(op) = op * 227 (mod 256). The official open
    # source compiler leaves the byte untouched. Select the representation that
    # makes the complete chunk most plausible, then normalize to official ops.
    inverse_227 = pow(227, -1, 256)

    def encoding_score(factor: int) -> tuple[int, int]:
        valid = 0
        broken = 0
        for proto in protos:
            pc = 0
            while pc < len(proto.code):
                opcode = ((proto.code[pc] & 0xFF) * factor) & 0xFF
                if opcode >= len(NAMES):
                    broken += 1
                    pc += 1
                    continue
                valid += 1
                pc += 2 if opcode in AUX_OPS else 1
            if pc != len(proto.code):
                broken += 1
        return valid, -broken

    plain_score = encoding_score(1)
    roblox_score = encoding_score(inverse_227)
    opcode_encoding = "identity"
    if roblox_score > plain_score:
        opcode_encoding = "roblox-mul227"
        for proto in protos:
            pc = 0
            while pc < len(proto.code):
                word = proto.code[pc]
                opcode = ((word & 0xFF) * inverse_227) & 0xFF
                proto.code[pc] = (word & ~0xFF) | opcode
                pc += 2 if opcode in AUX_OPS else 1
    return Chunk(
        version=version,
        type_version=type_version,
        strings=strings,
        userdata_types=userdata_types,
        protos=protos,
        main_id=main_id,
        opcode_encoding=opcode_encoding,
        trailer=data[r.offset :],
        source_size=len(data),
    )
