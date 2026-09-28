from __future__ import annotations

import hashlib
import json
import os
from collections import Counter
from pathlib import Path

from .model import Chunk
from .opcodes import decode


def corpus_matches(chunk: Chunk, root: Path | None) -> dict[str, list[str]]:
    if root is None or not root.is_dir():
        return {}
    wanted = set(chunk.strings)
    result: dict[str, list[str]] = {}
    # Dumps tend to be flattened at the service root. Scanning with scandir and
    # a bounded depth avoids a very slow stat per file on Android shared storage
    # and avoids descending through huge asset trees unrelated to module names.
    pending = [(root, 0)]
    while pending:
        directory, depth = pending.pop()
        try:
            entries = os.scandir(directory)
        except OSError:
            continue
        with entries:
            for entry in entries:
                if entry.is_dir(follow_symlinks=False) and depth < 1:
                    pending.append((Path(entry.path), depth + 1))
                    continue
                if not entry.is_file(follow_symlinks=False) or not entry.name.endswith(".lua"):
                    continue
                stem = entry.name
                for suffix in (".module.lua", ".localscript.lua", ".script.lua", ".lua"):
                    if stem.endswith(suffix):
                        stem = stem[: -len(suffix)]
                        break
                if stem in wanted:
                    result.setdefault(stem, []).append(entry.path)
    return result


def build_report(chunk: Chunk, original: bytes, corpus: Path | None = None) -> dict:
    opcodes = Counter(item.name for proto in chunk.protos for item in decode(proto.code))
    return {
        "format": {
            "bytecode_version": chunk.version,
            "type_version": chunk.type_version,
            "opcode_encoding": chunk.opcode_encoding,
            "size": chunk.source_size,
            "sha256": hashlib.sha256(original).hexdigest(),
            "trailer_size": len(chunk.trailer),
            "trailer_hex": chunk.trailer.hex(),
        },
        "program": {
            "strings": len(chunk.strings),
            "protos": len(chunk.protos),
            "main_proto": chunk.main_id,
            "instructions": sum(len(decode(proto.code)) for proto in chunk.protos),
            "opcodes": dict(opcodes.most_common()),
            "userdata_types": chunk.userdata_types,
        },
        "corpus_matches": corpus_matches(chunk, corpus),
    }


def report_json(chunk: Chunk, original: bytes, corpus: Path | None = None) -> str:
    return json.dumps(build_report(chunk, original, corpus), ensure_ascii=False, indent=2) + "\n"
