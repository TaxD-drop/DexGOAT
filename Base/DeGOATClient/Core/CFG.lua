local Opcodes = if script then require(script.Parent.Opcodes) else require("./Opcodes")

local CFG = {}

local conditional = {
	JUMPIF=true, JUMPIFNOT=true, JUMPIFEQ=true, JUMPIFLE=true, JUMPIFLT=true,
	JUMPIFNOTEQ=true, JUMPIFNOTLE=true, JUMPIFNOTLT=true, JUMPXEQKNIL=true,
	JUMPXEQKB=true, JUMPXEQKN=true, JUMPXEQKS=true, CMPPROTO=true,
}
local unconditional = { JUMP=true, JUMPBACK=true, JUMPX=true }
local prep = { FORNPREP=true, FORGPREP=true, FORGPREP_INEXT=true, FORGPREP_NEXT=true }

CFG.Conditional = conditional

function CFG.build(proto)
	local instructions = Opcodes.decode(proto.code)
	if #instructions == 0 then return { blocks={}, byPc={}, dominators={}, backEdges={} } end
	local positions, leaders = {}, { [instructions[1].pc] = true }
	for index, item in ipairs(instructions) do
		positions[item.pc] = index
		if item.target ~= nil then leaders[item.target] = true end
		if (item.target ~= nil or item.name == "RETURN") and instructions[index + 1] then
			leaders[instructions[index + 1].pc] = true
		end
	end
	local starts = {}
	for pc in pairs(leaders) do if positions[pc] then starts[#starts + 1] = pc end end
	table.sort(starts)
	local blocks, byPc = {}, {}
	for id, startPc in ipairs(starts) do
		local from = positions[startPc]
		local to = starts[id + 1] and positions[starts[id + 1]] - 1 or #instructions
		local items = {}
		for index = from, to do items[#items + 1] = instructions[index] end
		blocks[id] = { id=id, startPc=startPc, instructions=items, successors={}, predecessors={} }
		for _, item in ipairs(items) do byPc[item.pc] = id end
	end
	for id, block in ipairs(blocks) do
		local last = block.instructions[#block.instructions]
		if last.target and byPc[last.target] then block.successors[byPc[last.target]] = true end
		local falls = not unconditional[last.name] and last.name ~= "RETURN" and not prep[last.name]
		if falls then
			local nextId = byPc[last.pc + last.size]
			if nextId then block.successors[nextId] = true end
		end
		for successor in pairs(block.successors) do blocks[successor].predecessors[id] = true end
	end
	local all, dominators = {}, {}
	for id = 1, #blocks do all[id] = true end
	for id = 1, #blocks do dominators[id] = id == 1 and { [1]=true } or table.clone(all) end
	local changed = true
	while changed do
		changed = false
		for id = 2, #blocks do
			local value, hasIncoming = { [id]=true }, false
			for predecessor in pairs(blocks[id].predecessors) do
				if not hasIncoming then
					for candidate in pairs(dominators[predecessor]) do value[candidate] = true end
					hasIncoming = true
				else
					for candidate in pairs(value) do
						if candidate ~= id and not dominators[predecessor][candidate] then value[candidate] = nil end
					end
				end
			end
			local same = true
			for key in pairs(value) do if not dominators[id][key] then same=false break end end
			if same then for key in pairs(dominators[id]) do if not value[key] then same=false break end end end
			if not same then dominators[id], changed = value, true end
		end
	end
	local backEdges = {}
	for id, block in ipairs(blocks) do
		for successor in pairs(block.successors) do
			if dominators[id][successor] then backEdges[#backEdges + 1] = { id, successor } end
		end
	end
	return { blocks=blocks, byPc=byPc, dominators=dominators, backEdges=backEdges, instructions=instructions }
end

return CFG
