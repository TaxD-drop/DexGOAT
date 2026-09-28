from __future__ import annotations

from dataclasses import dataclass, field

from .model import Proto
from .opcodes import Instruction, decode


UNCONDITIONAL = {"JUMP", "JUMPBACK", "JUMPX"}
CONDITIONAL = {
    "JUMPIF", "JUMPIFNOT", "JUMPIFEQ", "JUMPIFLE", "JUMPIFLT",
    "JUMPIFNOTEQ", "JUMPIFNOTLE", "JUMPIFNOTLT", "JUMPXEQKNIL",
    "JUMPXEQKB", "JUMPXEQKN", "JUMPXEQKS", "CMPPROTO",
}
LOOP_BRANCHES = {
    "FORNPREP", "FORNLOOP", "FORGLOOP", "FORGPREP_INEXT",
    "FORGPREP_NEXT", "FORGPREP",
}
TERMINATORS = UNCONDITIONAL | CONDITIONAL | LOOP_BRANCHES | {"RETURN"}


@dataclass
class BasicBlock:
    id: int
    start_pc: int
    end_pc: int
    instructions: list[Instruction]
    successors: set[int] = field(default_factory=set)
    predecessors: set[int] = field(default_factory=set)


@dataclass
class ControlFlowGraph:
    blocks: list[BasicBlock]
    by_pc: dict[int, int]
    dominators: dict[int, set[int]]
    back_edges: set[tuple[int, int]]

    @classmethod
    def build(cls, proto: Proto) -> "ControlFlowGraph":
        instructions = decode(proto.code)
        if not instructions:
            return cls([], {}, {}, set())

        pc_to_position = {item.pc: i for i, item in enumerate(instructions)}
        leaders = {instructions[0].pc}
        for position, item in enumerate(instructions):
            if item.target in pc_to_position:
                leaders.add(item.target)
            if item.name in TERMINATORS and position + 1 < len(instructions):
                leaders.add(instructions[position + 1].pc)

        starts = sorted(leaders)
        blocks: list[BasicBlock] = []
        by_pc: dict[int, int] = {}
        for block_id, start in enumerate(starts):
            start_pos = pc_to_position[start]
            end_pos = pc_to_position[starts[block_id + 1]] if block_id + 1 < len(starts) else len(instructions)
            items = instructions[start_pos:end_pos]
            block = BasicBlock(block_id, start, items[-1].pc + items[-1].size, items)
            blocks.append(block)
            for item in items:
                by_pc[item.pc] = block_id

        for block in blocks:
            last = block.instructions[-1]
            if last.target in by_pc:
                block.successors.add(by_pc[last.target])
            falls_through = last.name not in UNCONDITIONAL and last.name not in {"RETURN", "FORNPREP", "FORGPREP", "FORGPREP_INEXT", "FORGPREP_NEXT"}
            if falls_through:
                next_pc = last.pc + last.size
                if next_pc in by_pc:
                    block.successors.add(by_pc[next_pc])
            for successor in block.successors:
                blocks[successor].predecessors.add(block.id)

        all_ids = set(range(len(blocks)))
        dominators = {block.id: ({block.id} if block.id == 0 else set(all_ids)) for block in blocks}
        changed = True
        while changed:
            changed = False
            for block in blocks[1:]:
                incoming = [dominators[pred] for pred in block.predecessors]
                value = {block.id} | (set.intersection(*incoming) if incoming else set())
                if value != dominators[block.id]:
                    dominators[block.id] = value
                    changed = True

        back_edges = {
            (block.id, successor)
            for block in blocks
            for successor in block.successors
            if successor in dominators[block.id]
        }
        return cls(blocks, by_pc, dominators, back_edges)

    def is_loop_header(self, pc: int) -> bool:
        block_id = self.by_pc.get(pc)
        return block_id is not None and any(target == block_id for _, target in self.back_edges)
