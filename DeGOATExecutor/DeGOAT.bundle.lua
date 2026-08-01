-- AUTO-GERADO por tools/build_executor_bundle.py.
-- Fontes editáveis: DeGOATClient/. Nenhum decompiler remoto é usado.

local factories = {}
local cache = {}
local loading = {}

local function node(name, moduleId, parent)
    local value = { Name = name, Parent = parent, __moduleId = moduleId }
    if parent then parent[name] = value end
    return value
end

local root = node("DeGOATClient", "init", nil)
local core = node("Core", nil, root)
local providers = node("Providers", nil, root)
local ui = node("UI", nil, root)
node("Config", "Config", root)
node("Base64", "Core.Base64", core)
node("Reader", "Core.Reader", core)
node("Opcodes", "Core.Opcodes", core)
node("Parser", "Core.Parser", core)
node("CFG", "Core.CFG", core)
node("Naming", "Core.Naming", core)
node("Decompiler", "Core.Decompiler", core)
node("BytecodeProvider", "Providers.BytecodeProvider", providers)
node("Theme", "UI.Theme", ui)
node("Layout", "UI.Layout", ui)
node("Editor", "UI.Editor", ui)
node("Explorer", "UI.Explorer", ui)
node("App", "UI.App", ui)

local function moduleRequire(moduleNode)
    assert(type(moduleNode) == "table" and moduleNode.__moduleId, "require interno inválido")
    local id = moduleNode.__moduleId
    if cache[id] ~= nil then return cache[id] end
    assert(not loading[id], "dependência circular no módulo " .. id)
    local factory = assert(factories[id], "módulo ausente: " .. id)
    loading[id] = true
    local result = factory(moduleNode, moduleRequire)
    loading[id] = nil
    if result == nil then result = true end
    cache[id] = result
    return result
end

factories["init"] = function(script, require)
local Config=require(script.Config)
local App=require(script.UI.App)

local DeGOATClient={ Version="0.4.0-luau" }

function DeGOATClient.start(overrides)
	local config=table.clone(Config)
	for key,value in pairs(overrides or {}) do config[key]=value end
	return App.new(script,config)
end

return DeGOATClient
end

factories["Config"] = function(script, require)
return {
	Title = "DeGOAT Explorer",
	ToggleKey = Enum.KeyCode.RightShift,
	InitialSize = UDim2.fromOffset(980, 620),
	ExplorerWidth = 330,
	RowHeight = 22,
	ScreenPadding = 12,
	MinimumWidth = 480,
	MinimumHeight = 300,
	MinimumEditorWidth = 280,
	MobileBreakpointWidth = 760,
	MobileBreakpointHeight = 520,
	StackBreakpointWidth = 620,
	MobileExplorerRatio = 0.34,
	MobileExplorerMin = 180,
	LongPressSeconds = 0.55,
	AutoBytecode = true,
	UseExecutorUI = true,
	RootServices = {
		"Workspace", "Players", "CoreGui", "Lighting", "MaterialService",
		"ReplicatedStorage", "ServerStorage", "StarterGui", "StarterPack",
		"StarterPlayer", "Teams", "SoundService", "TextChatService",
	},
	BytecodeAttribute = "DeGOATBytecode",
	BytecodeValueName = "DeGOATBytecode",
}
end

factories["Core.Base64"] = function(script, require)
local Base64 = {}

local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local decodeMap = {}
for index = 1, #alphabet do
	decodeMap[string.byte(alphabet, index)] = index - 1
end

function Base64.decode(text)
	assert(type(text) == "string", "base64 precisa ser string")
	local clean = text:gsub("%s", "")
	if #clean == 0 or #clean % 4 == 1 then error("base64 inválido", 2) end
	local out = table.create(math.floor(#clean * 3 / 4))
	local cursor = 1
	for index = 1, #clean, 4 do
		local a = decodeMap[string.byte(clean, index)]
		local b = decodeMap[string.byte(clean, index + 1)]
		local cbyte = string.byte(clean, index + 2)
		local dbyte = string.byte(clean, index + 3)
		if a == nil or b == nil then error("base64 inválido", 2) end
		local c = cbyte == 61 and nil or decodeMap[cbyte]
		local d = dbyte == 61 and nil or decodeMap[dbyte]
		if cbyte and cbyte ~= 61 and c == nil then error("base64 inválido", 2) end
		if dbyte and dbyte ~= 61 and d == nil then error("base64 inválido", 2) end
		if cbyte == 61 and dbyte ~= 61 then error("padding base64 inválido", 2) end
		if (cbyte == 61 or dbyte == 61) and index + 3 < #clean then error("padding base64 fora do final", 2) end
		out[cursor] = string.char(bit32.bor(bit32.lshift(a, 2), bit32.rshift(b, 4)))
		cursor += 1
		if c then
			out[cursor] = string.char(bit32.band(bit32.bor(bit32.lshift(b, 4), bit32.rshift(c, 2)), 255))
			cursor += 1
		end
		if d and c then
			out[cursor] = string.char(bit32.band(bit32.bor(bit32.lshift(c, 6), d), 255))
			cursor += 1
		end
	end
	return table.concat(out)
end

return Base64
end

factories["Core.Reader"] = function(script, require)
local Reader = {}
Reader.__index = Reader

function Reader.new(data)
	assert(type(data) == "string", "Reader espera byte string")
	return setmetatable({ data = data, offset = 1 }, Reader)
end

function Reader:remaining()
	return #self.data - self.offset + 1
end

function Reader:take(size)
	if size < 0 or self.offset + size - 1 > #self.data then
		error(string.format("bytecode truncado no offset 0x%x", self.offset - 1), 2)
	end
	local value = self.data:sub(self.offset, self.offset + size - 1)
	self.offset += size
	return value
end

function Reader:u8()
	local value = string.byte(self.data, self.offset)
	if value == nil then error("bytecode truncado", 2) end
	self.offset += 1
	return value
end

function Reader:u32()
	local a, b, c, d = string.byte(self:take(4), 1, 4)
	return a + b * 256 + c * 65536 + d * 16777216
end

function Reader:i32()
	local value = self:u32()
	return value >= 2147483648 and value - 4294967296 or value
end

function Reader:f32()
	local bits = self:u32()
	local sign = bit32.btest(bits, 0x80000000) and -1 or 1
	local exponent = bit32.band(bit32.rshift(bits, 23), 0xff)
	local mantissa = bit32.band(bits, 0x7fffff)
	if exponent == 255 then return mantissa == 0 and sign * math.huge or 0 / 0 end
	if exponent == 0 then return sign * math.ldexp(mantissa, -149) end
	return sign * math.ldexp(1 + mantissa / 8388608, exponent - 127)
end

function Reader:f64()
	local low, high = self:u32(), self:u32()
	local sign = high >= 2147483648 and -1 or 1
	local exponent = bit32.band(bit32.rshift(high, 20), 0x7ff)
	local mantissa = bit32.band(high, 0xfffff) * 4294967296 + low
	if exponent == 2047 then return mantissa == 0 and sign * math.huge or 0 / 0 end
	if exponent == 0 then return sign * math.ldexp(mantissa, -1074) end
	return sign * math.ldexp(1 + mantissa / 4503599627370496, exponent - 1023)
end

function Reader:varint(limit)
	limit = limit or 4294967295
	local value, multiplier = 0, 1
	for _ = 1, 10 do
		local byte = self:u8()
		value += bit32.band(byte, 0x7f) * multiplier
		if byte < 128 then
			if value > limit then error("varint fora do limite", 2) end
			return value
		end
		multiplier *= 128
	end
	error("varint inválido", 2)
end

return Reader

end

factories["Core.Opcodes"] = function(script, require)
local Opcodes = {}

Opcodes.Names = {
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
}

Opcodes.ByName = {}
for index, name in ipairs(Opcodes.Names) do Opcodes.ByName[name] = index - 1 end

local auxNames = {
	"GETGLOBAL", "SETGLOBAL", "GETIMPORT", "GETTABLEKS", "SETTABLEKS",
	"NAMECALL", "JUMPIFEQ", "JUMPIFLE", "JUMPIFLT", "JUMPIFNOTEQ",
	"JUMPIFNOTLE", "JUMPIFNOTLT", "NEWTABLE", "SETLIST", "FORGLOOP",
	"FASTCALL3", "LOADKX", "FASTCALL2", "FASTCALL2K", "JUMPXEQKNIL",
	"JUMPXEQKB", "JUMPXEQKN", "JUMPXEQKS", "GETUDATAKS", "SETUDATAKS",
	"NAMECALLUDATA", "NEWCLASSMEMBER", "CALLFB", "CMPPROTO",
}
Opcodes.Aux = {}
for _, name in ipairs(auxNames) do Opcodes.Aux[Opcodes.ByName[name]] = true end

local jumpDNames = {
	"JUMP", "JUMPBACK", "JUMPIF", "JUMPIFNOT", "JUMPIFEQ", "JUMPIFLE",
	"JUMPIFLT", "JUMPIFNOTEQ", "JUMPIFNOTLE", "JUMPIFNOTLT", "FORNPREP",
	"FORNLOOP", "FORGLOOP", "FORGPREP_INEXT", "FORGPREP_NEXT", "FORGPREP",
	"JUMPXEQKNIL", "JUMPXEQKB", "JUMPXEQKN", "JUMPXEQKS", "CMPPROTO",
}
local JumpD = {}
for _, name in ipairs(jumpDNames) do JumpD[Opcodes.ByName[name]] = true end

local function signed(value, bits)
	local sign = 2 ^ (bits - 1)
	return value >= sign and value - 2 ^ bits or value
end

function Opcodes.decode(code)
	local result = {}
	local pc = 0
	while pc < #code do
		local word = code[pc + 1]
		local opcode = bit32.band(word, 0xff)
		local size = Opcodes.Aux[opcode] and 2 or 1
		local d = signed(bit32.band(bit32.rshift(word, 16), 0xffff), 16)
		local e = signed(bit32.rshift(word, 8), 24)
		local target = nil
		if JumpD[opcode] then target = pc + d + 1
		elseif opcode == Opcodes.ByName.JUMPX then target = pc + e + 1 end
		result[#result + 1] = {
			pc = pc, word = word, opcode = opcode,
			name = Opcodes.Names[opcode + 1] or ("OP_" .. opcode),
			a = bit32.band(bit32.rshift(word, 8), 0xff),
			b = bit32.band(bit32.rshift(word, 16), 0xff),
			c = bit32.band(bit32.rshift(word, 24), 0xff),
			d = d, e = e, aux = size == 2 and code[pc + 2] or nil,
			size = size, target = target,
		}
		pc += size
	end
	return result
end

return Opcodes

end

factories["Core.Parser"] = function(script, require)
local Reader = if script then require(script.Parent.Reader) else require("./Reader")
local Base64 = if script then require(script.Parent.Base64) else require("./Base64")
local Opcodes = if script then require(script.Parent.Opcodes) else require("./Opcodes")

local Parser = {}

local function normalize(data)
	assert(type(data) == "string" and #data > 0, "entrada vazia")
	local first = string.byte(data, 1)
	if first == 0 or (first >= 3 and first <= 12) then return data end
	local text = data:gsub("^\239\187\191", ""):match("^%s*(.-)%s*$")
	if text:sub(1,1) == "{" then
		text = text:match('"script"%s*:%s*"([A-Za-z0-9+/=_%-]+)"')
		if not text then error("JSON precisa conter string 'script'", 2) end
	end
	local compact = text:gsub("%s", "")
	if compact:sub(1,2):lower() == "0x" then compact=compact:sub(3) end
	local decoded
	if #compact > 0 and #compact % 2 == 0 and compact:match("^[%da-fA-F]+$") then
		local bytes={}
		for index=1,#compact,2 do bytes[#bytes+1]=string.char(tonumber(compact:sub(index,index+1),16)) end
		decoded=table.concat(bytes)
	else
		local ok
		ok, decoded = pcall(Base64.decode, compact)
		if not ok then error("entrada não é bytecode raw, base64, hex ou JSON", 2) end
	end
	if #decoded == 0 then error("entrada decodificada vazia", 2) end
	first = string.byte(decoded, 1)
	if first ~= 0 and (first < 3 or first > 12) then
		error("conteúdo não possui versão Luau reconhecida", 2)
	end
	return decoded
end

local function readString(reader, strings)
	local index = reader:varint(#strings)
	return index == 0 and nil or strings[index]
end

local function readConstant(reader, strings, version)
	local tag = reader:u8()
	if tag == 0 then return { kind = "nil" }
	elseif tag == 1 then return { kind = "boolean", value = reader:u8() ~= 0 }
	elseif tag == 2 then return { kind = "number", value = reader:f64() }
	elseif tag == 3 then return { kind = "string", value = readString(reader, strings) }
	elseif tag == 4 then return { kind = "import", value = reader:u32() }
	elseif tag == 5 then
		local count, values = reader:varint(1000000), {}
		for index = 1, count do values[index] = reader:varint() end
		return { kind = "table", value = values }
	elseif tag == 6 then return { kind = "closure", value = reader:varint() }
	elseif tag == 7 then
		return { kind = "vector", value = { reader:f32(), reader:f32(), reader:f32(), reader:f32() } }
	elseif tag == 8 and version >= 7 then
		local count, values = reader:varint(1000000), {}
		for index = 1, count do values[index] = { reader:varint(), reader:i32() } end
		return { kind = "table_with_constants", value = values }
	elseif tag == 9 and version >= 8 then
		local negative = reader:u8() ~= 0
		local magnitude = reader:varint(9007199254740991)
		return { kind = "integer", value = negative and -magnitude or magnitude }
	elseif tag == 10 and version >= 10 then
		local className = reader:varint()
		local properties, methods = reader:varint(1000000), reader:varint(1000000)
		local members = {}
		for index = 1, properties + methods do members[index] = reader:varint() end
		return { kind = "class_shape", value = { className, properties, methods, members } }
	elseif tag == 11 and version >= 12 then
		return { kind = "vector_double", value = { reader:f64(), reader:f64(), reader:f64(), reader:f64() } }
	end
	error(string.format("tag de constante %d inválida", tag), 2)
end

local function scoreEncoding(protos, factor)
	local valid, broken = 0, 0
	for _, proto in ipairs(protos) do
		local pc = 0
		while pc < #proto.code do
			local opcode = bit32.band(bit32.band(proto.code[pc + 1], 0xff) * factor, 0xff)
			if Opcodes.Names[opcode + 1] == nil then
				broken += 1
				pc += 1
			else
				valid += 1
				pc += Opcodes.Aux[opcode] and 2 or 1
			end
		end
		if pc ~= #proto.code then broken += 1 end
	end
	return valid, -broken
end

function Parser.parse(input, maxSize)
	local data = normalize(input)
	maxSize = maxSize or 64 * 1024 * 1024
	if #data > maxSize then error("bytecode excede limite", 2) end
	local reader = Reader.new(data)
	local version = reader:u8()
	if version == 0 then error("erro do compilador: " .. reader:take(reader:remaining()), 2) end
	if version < 3 or version > 12 then error("versão Luau não suportada: " .. version, 2) end
	local typeVersion = version >= 4 and reader:u8() or 0
	if version >= 4 and typeVersion ~= 1 and typeVersion ~= 2 and typeVersion ~= 3 then
		error("versão de tipos não suportada: " .. typeVersion, 2)
	end

	local stringCount, strings = reader:varint(2000000), {}
	for index = 1, stringCount do
		strings[index] = reader:take(reader:varint(maxSize))
	end

	local userdataTypes = {}
	if typeVersion == 3 then
		local index = reader:u8()
		while index ~= 0 do
			userdataTypes[index] = readString(reader, strings) or "userdata"
			index = reader:u8()
		end
	end

	local protoCount, protos = reader:varint(1000000), {}
	if protoCount == 0 then error("chunk sem protos", 2) end
	for protoId = 0, protoCount - 1 do
		local protoSize = version >= 12 and reader:varint(maxSize) or nil
		local protoStart = reader.offset
		local proto = {
			id = protoId,
			maxStackSize = reader:u8(), numParams = reader:u8(),
			numUpvalues = reader:u8(), isVararg = reader:u8() ~= 0,
			flags = 0, typeInfo = "", code = {}, constants = {}, children = {},
			lineInfo = {}, locals = {}, upvalueNames = {},
		}
		if version >= 4 then
			proto.flags = reader:u8()
			proto.typeInfo = reader:take(reader:varint(maxSize))
		end
		local codeSize = reader:varint(16000000)
		for index = 1, codeSize do proto.code[index] = reader:u32() end
		local constCount = reader:varint(4000000)
		for index = 1, constCount do proto.constants[index] = readConstant(reader, strings, version) end
		local childCount = reader:varint(1000000)
		for index = 1, childCount do proto.children[index] = reader:varint(math.max(protoCount - 1, 0)) end
		proto.lineDefined = reader:varint()
		proto.debugName = readString(reader, strings)

		if reader:u8() ~= 0 then
			local gapLog2 = reader:u8()
			local deltas = { string.byte(reader:take(codeSize), 1, codeSize) }
			local intervalCount = codeSize == 0 and 0 or bit32.rshift(codeSize - 1, gapLog2) + 1
			local absolute = {}
			for index = 1, intervalCount do absolute[index] = reader:i32() end
			local lastDelta, lastAbs = 0, 0
			for pc = 0, codeSize - 1 do
				lastDelta = bit32.band(lastDelta + deltas[pc + 1], 0xff)
				if bit32.band(pc, 2 ^ gapLog2 - 1) == 0 then
					lastAbs += absolute[bit32.rshift(pc, gapLog2) + 1]
				end
				proto.lineInfo[pc + 1] = lastAbs + lastDelta
			end
		end

		if reader:u8() ~= 0 then
			local localCount = reader:varint(1000000)
			for index = 1, localCount do
				proto.locals[index] = {
					name = readString(reader, strings), startPc = reader:varint(),
					endPc = reader:varint(), register = reader:u8(),
				}
			end
			local upvalueCount = reader:varint(1000000)
			for index = 1, upvalueCount do proto.upvalueNames[index] = readString(reader, strings) end
			if upvalueCount ~= proto.numUpvalues then error("upvalues inconsistentes", 2) end
		end

		if version >= 11 then
			local feedbackCount = reader:varint(1000000)
			for _ = 1, feedbackCount do reader:u8(); reader:varint() end
		end
		if version >= 12 and bit32.btest(proto.flags, 1) then reader:varint(9007199254740991) end
		if protoSize then
			local expected = protoStart + protoSize
			if reader.offset > expected then error("proto ultrapassa tamanho declarado", 2) end
			reader.offset = expected
		end
		protos[protoId + 1] = proto
	end

	local mainId = reader:varint(math.max(protoCount - 1, 0))
	local plainA, plainB = scoreEncoding(protos, 1)
	-- 227^-1 mod 256 = 203
	local robloxA, robloxB = scoreEncoding(protos, 203)
	local encoding = "identity"
	if robloxA > plainA or (robloxA == plainA and robloxB > plainB) then
		encoding = "roblox-mul227"
		for _, proto in ipairs(protos) do
			local pc = 0
			while pc < #proto.code do
				local word = proto.code[pc + 1]
				local opcode = bit32.band(bit32.band(word, 0xff) * 203, 0xff)
				proto.code[pc + 1] = bit32.bor(bit32.band(word, 0xffffff00), opcode)
				pc += Opcodes.Aux[opcode] and 2 or 1
			end
		end
	end

	return {
		version = version, typeVersion = typeVersion, strings = strings,
		userdataTypes = userdataTypes, protos = protos, mainId = mainId,
		main = protos[mainId + 1], opcodeEncoding = encoding,
		trailer = reader.offset <= #data and data:sub(reader.offset) or "",
		sourceSize = #data,
	}
end

return Parser
end

factories["Core.CFG"] = function(script, require)
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
end

factories["Core.Naming"] = function(script, require)
local Naming = {}

local keywords = {
	["and"]=true,["break"]=true,["do"]=true,["else"]=true,["elseif"]=true,
	["end"]=true,["false"]=true,["for"]=true,["function"]=true,["goto"]=true,
	["if"]=true,["in"]=true,["local"]=true,["nil"]=true,["not"]=true,
	["or"]=true,["repeat"]=true,["return"]=true,["then"]=true,["true"]=true,
	["until"]=true,["while"]=true,["continue"]=true,
}

function Naming.identifier(value, fallback)
	value = tostring(value):gsub("[^%w_]", "_"):gsub("_+", "_"):gsub("^_+", ""):gsub("_+$", "")
	if value == "" or value:match("^%d") or keywords[value] then return fallback or "value" end
	return value
end

function Naming.callResult(functionValue, method, arguments)
	local literal = arguments and arguments[1]
	if method == "GetService" and literal and literal:match('^".*"$') then
		return literal:sub(2, -2), 100
	elseif (method == "WaitForChild" or method == "FindFirstChild") and literal and literal:match('^".*"$') then
		local value = literal:sub(2, -2)
		return value == "HumanoidRootPart" and "rootPart" or value, 86
	elseif method == "newSound" then return "sound", 98
	elseif method == "Wait" and functionValue:match("%.CharacterAdded$") then return "character", 88
	elseif method == "Create" and functionValue:match("TweenService") then return "tween", 88
	elseif functionValue:match("%.newSound$") then return "sound", 98
	elseif functionValue == "require" and arguments and arguments[1] then
		return arguments[1]:match("([%a_][%w_]*)$"), 84
	elseif functionValue == "Instance.new" and literal then
		local value = literal:match('^"(.*)"$')
		if value then return value:sub(1,1):lower() .. value:sub(2), 90 end
	elseif functionValue == "TweenInfo.new" then return "tweenInfo", 82 end
	return nil, 0
end

function Naming.tableResult(proto, instructions, position, register, mainId)
	for cursor = position + 1, #instructions do
		local item = instructions[cursor]
		if item.name == "SETTABLEKS" and item.b == register then
			local constant = proto.constants[(item.aux or 0) + 1]
			local key = constant and tostring(constant.value) or ""
			if key == "Size" or key == "Position" or key == "Orientation" or key == "Transparency" then
				return "goal", 84
			end
		elseif item.name == "RETURN" and proto.id == mainId and item.b == 2 and item.a == register then
			return "module", 92
		end
		local writes = item.a == register and (
			item.name:sub(1,4) == "LOAD" or item.name:sub(1,3) == "GET" or
			item.name == "MOVE" or item.name == "NEWTABLE" or item.name == "DUPTABLE" or
			item.name == "NEWCLOSURE" or item.name == "DUPCLOSURE" or item.name == "CALL"
		)
		if writes then break end
	end
	return nil, 0
end

return Naming
end

factories["Core.Decompiler"] = function(script, require)
local Opcodes = if script then require(script.Parent.Opcodes) else require("./Opcodes")
local CFG = if script then require(script.Parent.CFG) else require("./CFG")
local Naming = if script then require(script.Parent.Naming) else require("./Naming")

local Decompiler = {}

local binary = {
	ADD="+",SUB="-",MUL="*",DIV="/",MOD="%",POW="^",IDIV="//",AND="and",OR="or",
	ADDK="+",SUBK="-",MULK="*",DIVK="/",MODK="%",POWK="^",IDIVK="//",ANDK="and",ORK="or",
}
local compare = {
	JUMPIFEQ="==",JUMPIFLE="<=",JUMPIFLT="<",JUMPIFNOTEQ="~=",
	JUMPIFNOTLE=">",JUMPIFNOTLT=">=",
}

local singleWrite = {
	LOADNIL=true,LOADB=true,LOADN=true,LOADK=true,LOADKX=true,MOVE=true,
	GETGLOBAL=true,GETUPVAL=true,GETIMPORT=true,GETTABLEKS=true,GETUDATAKS=true,
	GETTABLE=true,GETTABLEN=true,NEWCLOSURE=true,DUPCLOSURE=true,ADD=true,SUB=true,
	MUL=true,DIV=true,MOD=true,POW=true,ADDK=true,SUBK=true,MULK=true,DIVK=true,
	MODK=true,POWK=true,AND=true,OR=true,ANDK=true,ORK=true,SUBRK=true,DIVRK=true,
	IDIV=true,IDIVK=true,CONCAT=true,NOT=true,MINUS=true,LENGTH=true,NEWTABLE=true,DUPTABLE=true,
}

local function writtenRegisters(item)
	local result = {}
	if singleWrite[item.name] then result[item.a] = true
	elseif item.name == "NAMECALL" or item.name == "NAMECALLUDATA" then result[item.a],result[item.a+1] = true,true
	elseif item.name == "CALL" or item.name == "CALLFB" then
		local count = item.c == 0 and 1 or math.max(item.c - 1,0)
		for register=item.a,item.a+count-1 do result[register]=true end
	elseif item.name == "GETVARARGS" then result[item.a]=true end
	return result
end

local function readsRegister(item, register)
	local n,a,b,c = item.name,item.a,item.b,item.c
	if n == "MOVE" or n == "SETGLOBAL" or n == "SETUPVAL" or n == "NOT" or n == "MINUS" or n == "LENGTH" then return b == register or (n:sub(1,3)=="SET" and a==register) end
	if n == "GETTABLEKS" or n == "GETUDATAKS" or n == "GETTABLEN" or n == "NAMECALL" or n == "NAMECALLUDATA" then return b == register end
	if n == "GETTABLE" then return b == register or c == register end
	if n == "SETTABLE" then return a == register or b == register or c == register end
	if n == "SETTABLEKS" or n == "SETUDATAKS" or n == "SETTABLEN" then return a == register or b == register end
	if n == "CALL" or n == "CALLFB" then return register >= a and register <= a + math.max(b - 1,0) end
	if binary[n] then return b == register or (n:sub(-1) ~= "K" and c == register) end
	if n == "SUBRK" or n == "DIVRK" then return c == register end
	if n == "CONCAT" then return register >= b and register <= c end
	if n == "RETURN" then return register >= a and register <= a + math.max(b - 2,-1) end
	if n == "SETLIST" then return register == a or (register >= b and register < b + math.max(c - 1,0)) end
	if n == "CAPTURE" then return a < 2 and b == register end
	if CFG.Conditional[n] then return a == register or (compare[n] ~= nil and bit32.band(item.aux or 0,255) == register) end
	if n:sub(1,3) == "FOR" then return register >= a and register <= a + 5 end
	return false
end

local function quote(value)
	value = tostring(value or "")
	return '"' .. value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r") .. '"'
end

local function numberText(value)
	if value ~= value then return "0/0" end
	if value == math.huge then return "math.huge" end
	if value == -math.huge then return "-math.huge" end
	return tostring(value)
end

local function postfixBase(value)
	if value:match("^[%a_][%w_%.]*$") or value:sub(-1) == ")" or value:sub(-1) == "]" then
		return value
	end
	return "(" .. value .. ")"
end

local function constant(proto, index)
	local item = proto.constants[index + 1]
	if not item then return "nil --[[ K" .. index .. " inválida ]]" end
	if item.kind == "nil" then return "nil"
	elseif item.kind == "boolean" then return item.value and "true" or "false"
	elseif item.kind == "string" then return quote(item.value)
	elseif item.kind == "number" or item.kind == "integer" then return numberText(item.value)
	elseif item.kind == "vector" or item.kind == "vector_double" then
		return string.format("Vector3.new(%s, %s, %s)", numberText(item.value[1]), numberText(item.value[2]), numberText(item.value[3]))
	elseif item.kind == "table" then return "{}"
	elseif item.kind == "table_with_constants" then
		local entries = {}
		for _, pair in ipairs(item.value) do
			entries[#entries + 1] = "[" .. constant(proto, pair[1]) .. "] = " .. (pair[2] >= 0 and constant(proto, pair[2]) or "nil")
		end
		return "{" .. table.concat(entries, ", ") .. "}"
	end
	return "nil --[[ " .. item.kind .. " ]]"
end

local function importPath(proto, iid)
	local count = bit32.rshift(iid, 30)
	local indices = { bit32.band(bit32.rshift(iid,20),0x3ff), bit32.band(bit32.rshift(iid,10),0x3ff), bit32.band(iid,0x3ff) }
	local parts = {}
	for index = 1, count do
		local value = constant(proto, indices[index])
		parts[index] = value:match('^"(.*)"$') or value
	end
	return table.concat(parts, ".")
end

local Emitter = {}
Emitter.__index = Emitter

function Emitter.new(chunk, proto, indent, captures)
	local self = setmetatable({}, Emitter)
	self.chunk, self.proto, self.indent = chunk, proto, indent or ""
	self.captures = captures or {}
	self.instructions = Opcodes.decode(proto.code)
	self.positions, self.byPc = {}, {}
	for index, item in ipairs(self.instructions) do self.positions[item.pc], self.byPc[item.pc] = index, item end
	self.cfg = CFG.build(proto)
	self.lines, self.level, self.used, self.counts = {}, 0, {}, {}
	self.regs, self.methods = {}, {}
	for index = 0, proto.maxStackSize - 1 do
		if index < proto.numParams then
			local name = "arg" .. index + 1
			self.used[name] = true
			self.regs[index] = { value=name, name=name }
		else self.regs[index] = { value="v" .. index } end
	end
	return self
end

function Emitter:line(text)
	self.lines[#self.lines + 1] = self.indent .. string.rep("\t", self.level) .. (text or "")
end

function Emitter:unique(base)
	base = Naming.identifier(base or "v", "v")
	local count = self.counts[base] or 0
	repeat count += 1 until not self.used[count == 1 and base or base .. count]
	self.counts[base] = count
	local result = count == 1 and base or base .. count
	self.used[result] = true
	return result
end

function Emitter:reg(index) return self.regs[index] and self.regs[index].value or ("v" .. index) end

function Emitter:assign(index, value, preferred, emit)
	local previous = self.regs[index]
	if emit then
		if previous and previous.merge and previous.name then
			self:line(previous.name .. " = " .. value)
			self.regs[index] = { value=previous.name, name=previous.name, merge=true }
			return previous.name
		end
		local name = self:unique(preferred or ("v" .. index))
		self:line("local " .. name .. " = " .. value)
		self.regs[index] = { value=name, name=name }
		return name
	end
	self.regs[index] = {
		value=value, preferred=preferred,
		name=previous and previous.merge and previous.name or nil,
		merge=previous and previous.merge or nil,
	}
	return value
end

function Emitter:materialize(index, preferred)
	local register = self.regs[index]
	if register and register.name then return register.name end
	return self:assign(index, self:reg(index), preferred or (register and register.preferred), true)
end

function Emitter:upvalue(index)
	local capture = self.captures[index + 1]
	return capture and capture.name or ("u" .. index)
end

function Emitter:branchMerges(first,last,after)
	local written,result = {},{}
	for position=first,last do
		for register in pairs(writtenRegisters(self.instructions[position])) do written[register]=true end
	end
	for register in pairs(written) do
		for position=after,#self.instructions do
			local item=self.instructions[position]
			if readsRegister(item,register) then result[#result+1]=register break end
			if writtenRegisters(item)[register] then break end
		end
	end
	table.sort(result)
	return result
end

function Emitter:readCaptures(position, child)
	local captures, cursor = {}, position + 1
	while #captures < child.numUpvalues and self.instructions[cursor] and self.instructions[cursor].name == "CAPTURE" do
		local item = self.instructions[cursor]
		local name, mode
		if item.a == 0 then name, mode = self:materialize(item.b), "copy"
		elseif item.a == 1 then name, mode = self:materialize(item.b), "ref"
		else name, mode = self:upvalue(item.b), "ref" end
		captures[#captures + 1] = { name=name, mode=mode }
		cursor += 1
	end
	return captures, cursor
end

function Emitter:closure(childId, captures)
	local child = self.chunk.protos[childId + 1]
	local nested = Emitter.new(self.chunk, child, self.indent .. string.rep("\t", self.level + 1), captures)
	local args = {}
	for index = 0, child.numParams - 1 do args[#args + 1] = nested:reg(index) end
	if child.isVararg then args[#args + 1] = "..." end
	local parts = { "function(" .. table.concat(args, ", ") .. ")" }
	if #captures > 0 then
		local values = {}
		for _, capture in ipairs(captures) do values[#values + 1] = "(" .. capture.mode .. ") " .. capture.name end
		parts[#parts + 1] = self.indent .. string.rep("\t", self.level + 1) .. "-- upvalues: " .. table.concat(values, ", ")
	end
	for _, line in ipairs(nested:render()) do parts[#parts + 1] = line end
	parts[#parts + 1] = self.indent .. string.rep("\t", self.level) .. "end"
	return table.concat(parts, "\n")
end

function Emitter:condition(item)
	local aux = item.aux or 0
	if item.name == "JUMPIF" then return self:reg(item.a)
	elseif item.name == "JUMPIFNOT" then return "not (" .. self:reg(item.a) .. ")"
	elseif compare[item.name] then return self:reg(item.a) .. " " .. compare[item.name] .. " " .. self:reg(bit32.band(aux,255))
	elseif item.name:sub(1,8) == "JUMPXEQK" then
		local value
		if item.name == "JUMPXEQKNIL" then value="nil"
		elseif item.name == "JUMPXEQKB" then value=bit32.btest(aux,1) and "true" or "false"
		else value=constant(self.proto,bit32.band(aux,0xffffff)) end
		return self:reg(item.a) .. (bit32.btest(aux,0x80000000) and " ~= " or " == ") .. value
	end
	return "true --[[ " .. item.name .. " ]]"
end

function Emitter:emit(item, position)
	local n,a,b,c,d,aux = item.name,item.a,item.b,item.c,item.d,item.aux or 0
	local k = function(index) return constant(self.proto,index) end
	if n == "NOP" or n == "PREPVARARGS" or n == "CAPTURE" or n:sub(1,8) == "FASTCALL" then return position + 1
	elseif n == "LOADNIL" then self:assign(a,"nil")
	elseif n == "LOADB" then self:assign(a,b ~= 0 and "true" or "false")
	elseif n == "LOADN" then self:assign(a,tostring(d))
	elseif n == "LOADK" then self:assign(a,k(d))
	elseif n == "LOADKX" then self:assign(a,k(aux))
	elseif n == "MOVE" then self:assign(a,self:reg(b))
	elseif n == "GETGLOBAL" then self:assign(a,(k(aux):match('^"(.*)"$') or k(aux)))
	elseif n == "SETGLOBAL" then self:line((k(aux):match('^"(.*)"$') or k(aux)) .. " = " .. self:reg(a))
	elseif n == "GETUPVAL" then self:assign(a,self:upvalue(b))
	elseif n == "SETUPVAL" then self:line(self:upvalue(b) .. " = " .. self:reg(a))
	elseif n == "GETIMPORT" then
		local itemConstant = self.proto.constants[d + 1]
		self:assign(a,importPath(self.proto,itemConstant and itemConstant.kind == "import" and itemConstant.value or aux))
	elseif n == "GETTABLEKS" or n == "GETUDATAKS" then
		local index = n == "GETUDATAKS" and bit32.band(aux,0xffff) or aux
		local key = tostring(self.proto.constants[index + 1].value)
		local preferred = ({ LocalPlayer="player",Character="character",HumanoidRootPart="rootPart" })[key]
		self:assign(a,self:reg(b) .. (key:match("^[%a_][%w_]*$") and "." .. key or "[" .. quote(key) .. "]"),preferred)
	elseif n == "GETTABLE" then self:assign(a,self:reg(b) .. "[" .. self:reg(c) .. "]")
	elseif n == "GETTABLEN" then self:assign(a,self:reg(b) .. "[" .. c + 1 .. "]")
	elseif n == "SETTABLEKS" or n == "SETUDATAKS" then
		local index = n == "SETUDATAKS" and bit32.band(aux,0xffff) or aux
		local key = tostring(self.proto.constants[index + 1].value)
		self:line(self:reg(b) .. (key:match("^[%a_][%w_]*$") and "." .. key or "[" .. quote(key) .. "]") .. " = " .. self:reg(a))
	elseif n == "SETTABLE" then self:line(self:reg(b) .. "[" .. self:reg(c) .. "] = " .. self:reg(a))
	elseif n == "SETTABLEN" then self:line(self:reg(b) .. "[" .. c + 1 .. "] = " .. self:reg(a))
	elseif n == "NEWTABLE" then
		local preferred = Naming.tableResult(self.proto,self.instructions,position,a,self.chunk.mainId)
		self:assign(a,"{}",preferred,true)
	elseif n == "DUPTABLE" then self:assign(a,k(d),"goal",true)
	elseif n == "NEWCLOSURE" or n == "DUPCLOSURE" then
		local childId = n == "NEWCLOSURE" and self.proto.children[d + 1] or self.proto.constants[d + 1].value
		local child = self.chunk.protos[childId + 1]
		local captures, cursor = self:readCaptures(position,child)
		if child.debugName then self:line("-- função reconstruída: " .. child.debugName) end
		self:assign(a,self:closure(childId,captures),child.debugName ~= "<main>" and child.debugName or nil)
		return cursor
	elseif n == "NAMECALL" or n == "NAMECALLUDATA" then
		local index = n == "NAMECALLUDATA" and bit32.band(aux,0xffff) or aux
		self.methods[a] = { receiver=postfixBase(self:reg(b)), method=tostring(self.proto.constants[index + 1].value) }
		self:assign(a + 1,self:reg(b))
	elseif n == "CALL" or n == "CALLFB" then
		local method = self.methods[a]
		local args = {}
		for index = a + 1, a + math.max(b - 1,0) do args[#args + 1] = self:reg(index) end
		local expression
		if method then
			if #args > 0 then table.remove(args,1) end
			expression = method.receiver .. ":" .. method.method .. "(" .. table.concat(args,", ") .. ")"
		else expression = postfixBase(self:reg(a)) .. "(" .. table.concat(args,", ") .. ")" end
		self.methods[a] = nil
		if c == 1 then self:line((expression:sub(1,1) == "(" and ";" or "") .. expression)
		else
			local preferred = Naming.callResult(method and method.receiver or self:reg(a),method and method.method,args)
			self:assign(a,expression,preferred,true)
		end
	elseif binary[n] then
		self:assign(a,"(" .. self:reg(b) .. " " .. binary[n] .. " " .. (n:sub(-1)=="K" and k(c) or self:reg(c)) .. ")")
	elseif n == "SUBRK" or n == "DIVRK" then self:assign(a,"(" .. k(b) .. (n=="SUBRK" and " - " or " / ") .. self:reg(c) .. ")")
	elseif n == "NOT" then self:assign(a,"not (" .. self:reg(b) .. ")")
	elseif n == "MINUS" then self:assign(a,"-(" .. self:reg(b) .. ")")
	elseif n == "LENGTH" then self:assign(a,"#" .. self:reg(b))
	elseif n == "CONCAT" then
		local values={} for index=b,c do values[#values+1]=self:reg(index) end self:assign(a,table.concat(values," .. "))
	elseif n == "RETURN" then
		local values={} for index=a,a+math.max(b-2,-1) do values[#values+1]=self:reg(index) end
		self:line("do return" .. (#values>0 and " "..table.concat(values,", ") or "") .. " end")
	elseif n == "GETVARARGS" then self:assign(a,"...")
	elseif n == "SETLIST" then
		local count=math.max(c-1,0)
		for offset=0,count-1 do
			self:line(self:reg(a).."["..tostring(aux+offset+1).."] = "..self:reg(b+offset))
		end
	elseif not CFG.Conditional[n] and n ~= "JUMP" and n ~= "JUMPX" and n ~= "JUMPBACK" and n:sub(1,3) ~= "FOR" then
		self:line("--[[ " .. n .. " A=" .. a .. " B=" .. b .. " C=" .. c .. " ]]")
	end
	return position + 1
end

function Emitter:range(first,last)
	local position=first
	while position<=last do
		local item=self.instructions[position]
		if not item then break end
		if CFG.Conditional[item.name] and item.target and self.positions[item.target] and self.positions[item.target] > position then
			local target=self.positions[item.target]
			local merges=self:branchMerges(position+1,target-1,target)
			local mergeNames={}
			for _,register in ipairs(merges) do
				mergeNames[register]=self:materialize(register)
				self.regs[register].merge=true
			end
			self:line("if not ("..self:condition(item)..") then")
			self.level+=1 self:range(position+1,math.min(target-1,last)) self.level-=1
			for _,register in ipairs(merges) do
				local name,current=mergeNames[register],self.regs[register]
				if current.value~=name then
					self.level+=1 self:line(name.." = "..current.value) self.level-=1
				end
				self.regs[register]={value=name,name=name}
			end
			self:line("end")
			position=target
		elseif item.name:sub(1,7)=="FORGPREP" and item.target and self.positions[item.target] then
			local loopPos=self.positions[item.target]
			local loop=self.instructions[loopPos]
			if loop and loop.name=="FORGLOOP" then
				local count=bit32.band(loop.aux or 2,0xff)
				local vars={} for offset=0,count-1 do vars[#vars+1]=self:unique(offset==0 and "key" or "value") self.regs[item.a+3+offset]={value=vars[#vars],name=vars[#vars]} end
				self:line("for "..table.concat(vars,", ").." in "..self:reg(item.a).." do")
				self.level+=1 self:range(position+1,loopPos-1) self.level-=1 self:line("end")
				position=loopPos+1
			else position=self:emit(item,position) end
		elseif item.name=="JUMP" or item.name=="JUMPX" or item.name=="JUMPBACK" then
			self:line("-- fluxo para PC "..tostring(item.target)) position+=1
		else position=self:emit(item,position) end
	end
end

function Emitter:render()
	self:range(1,#self.instructions)
	return self.lines
end

function Decompiler.decompile(chunk)
	local emitter=Emitter.new(chunk,chunk.main)
	local lines={
		"-- Decompilado por DeGOAT Client",
		string.format("-- Luau bytecode v%d; tipos v%d; opcodes %s",chunk.version,chunk.typeVersion,chunk.opcodeEncoding),
		"-- Nomes semânticos exigem evidência; baixa confiança permanece genérica.",
	}
	if #chunk.trailer>0 then lines[#lines+1]=string.format("-- Trailer opaco preservado: %d bytes",#chunk.trailer) end
	lines[#lines+1]=""
	for _,line in ipairs(emitter:render()) do lines[#lines+1]=line end
	return table.concat(lines,"\n").."\n"
end

return Decompiler
end

factories["Providers.BytecodeProvider"] = function(script, require)
local Base64 = require(script.Parent.Parent.Core.Base64)

local BytecodeProvider = {}
BytecodeProvider.__index = BytecodeProvider

local function environmentFunction(name)
	local environment = _G
	if type(getgenv) == "function" then
		local ok, value = pcall(getgenv)
		if ok and type(value) == "table" then environment = value end
	end
	local value = environment and rawget(environment, name)
	if type(value) ~= "function" and name == "getscriptbytecode" and type(getscriptbytecode) == "function" then
		value = getscriptbytecode
	end
	return type(value) == "function" and value or nil
end

function BytecodeProvider.new(config)
	return setmetatable({
		config = config,
		resolver = config.ResolveBytecode,
		extractor = config.AutoBytecode ~= false and environmentFunction("getscriptbytecode") or nil,
		registered = setmetatable({}, { __mode = "k" }),
	}, BytecodeProvider)
end

function BytecodeProvider:GetCapability()
	if self.extractor then return "getscriptbytecode", true end
	if self.resolver then return "resolver local", true end
	return "indisponível", false
end

function BytecodeProvider:SetResolver(resolver)
	assert(resolver == nil or type(resolver) == "function", "resolver precisa ser função ou nil")
	self.resolver = resolver
end

function BytecodeProvider:Register(instance, rawBytecode)
	assert(typeof(instance) == "Instance", "instance inválida")
	assert(type(rawBytecode) == "string", "bytecode precisa ser string")
	self.registered[instance] = rawBytecode
end

function BytecodeProvider:Unregister(instance)
	self.registered[instance] = nil
end

function BytecodeProvider:IsScript(instance)
	return typeof(instance) == "Instance" and instance:IsA("LuaSourceContainer")
end

function BytecodeProvider:GetBytecode(instance)
	if not self:IsScript(instance) then return nil, "a instância não é um script" end
	if self.registered[instance] then return self.registered[instance] end
	if self.resolver then
		local ok, value, reason = pcall(self.resolver, instance)
		if ok and type(value) == "string" and value ~= "" then return value end
		if not ok then return nil, "resolver local falhou: " .. tostring(value) end
		if reason then return nil, tostring(reason) end
	end
	if self.extractor then
		local ok, value = pcall(self.extractor, instance)
		if not ok then return nil, "getscriptbytecode falhou: " .. tostring(value) end
		if type(value) ~= "string" or value == "" then
			return nil, "getscriptbytecode não retornou bytes"
		end
		return value
	end

	local attribute = instance:GetAttribute(self.config.BytecodeAttribute)
	if type(attribute) == "string" and attribute ~= "" then
		local ok, decoded = pcall(Base64.decode, attribute)
		if ok then return decoded end
		return nil, "atributo DeGOATBytecode não contém base64 válido"
	end

	local child = instance:FindFirstChild(self.config.BytecodeValueName)
	if child and child:IsA("StringValue") and child.Value ~= "" then
		local ok, decoded = pcall(Base64.decode, child.Value)
		if ok then return decoded end
		return nil, "StringValue DeGOATBytecode não contém base64 válido"
	end

	return nil, "este cliente não expõe getscriptbytecode"
end

return BytecodeProvider
end

factories["UI.Theme"] = function(script, require)
return {
	Background = Color3.fromRGB(24, 26, 31),
	Panel = Color3.fromRGB(31, 34, 40),
	PanelAlt = Color3.fromRGB(38, 42, 49),
	Border = Color3.fromRGB(55, 60, 70),
	Text = Color3.fromRGB(222, 226, 234),
	Muted = Color3.fromRGB(145, 151, 164),
	Accent = Color3.fromRGB(72, 132, 255),
	Selected = Color3.fromRGB(50, 76, 125),
	Error = Color3.fromRGB(245, 105, 105),
	Success = Color3.fromRGB(100, 210, 145),
	Font = Enum.Font.Code,
}

end

factories["UI.Layout"] = function(script, require)
local Layout = {}

function Layout.window(viewportWidth,viewportHeight,config,currentWidth,currentHeight,resetSize)
	local padding=config.ScreenPadding
	local maximumWidth=math.max(1,viewportWidth-padding*2)
	local maximumHeight=math.max(1,viewportHeight-padding*2)
	local desiredWidth=resetSize and config.InitialSize.X.Offset or currentWidth
	local desiredHeight=resetSize and config.InitialSize.Y.Offset or currentHeight
	if desiredWidth<=1 then desiredWidth=config.InitialSize.X.Offset end
	if desiredHeight<=1 then desiredHeight=config.InitialSize.Y.Offset end
	return {
		width=math.min(desiredWidth,maximumWidth),
		height=math.min(desiredHeight,maximumHeight),
		x=viewportWidth/2,y=viewportHeight/2,
		maximumWidth=maximumWidth,maximumHeight=maximumHeight,
	}
end

function Layout.panels(width,height,config,explorerVisible)
	local compact=width<=config.MobileBreakpointWidth or height<=config.MobileBreakpointHeight
	local narrow=width<=config.StackBreakpointWidth
	local maximumExplorer=math.max(0,width-config.MinimumEditorWidth)
	local requested=compact and math.floor(width*config.MobileExplorerRatio) or config.ExplorerWidth
	local minimumExplorer=math.min(config.MobileExplorerMin,maximumExplorer)
	local explorerWidth=narrow and width or math.clamp(requested,minimumExplorer,maximumExplorer)
	if not explorerVisible then explorerWidth=0 end
	return {
		compact=compact,narrow=narrow,explorerWidth=explorerWidth,
		leftVisible=explorerVisible,
		dividerVisible=explorerVisible and not narrow,
		rightVisible=not (narrow and explorerVisible),
		rightOffset=explorerVisible and not narrow and explorerWidth+1 or 0,
		rightInset=explorerVisible and not narrow and -explorerWidth-1 or 0,
	}
end

return Layout
end

factories["UI.Editor"] = function(script, require)
local Theme = require(script.Parent.Theme)
local TextService = game:GetService("TextService")

local Editor = {}
Editor.__index = Editor

local function create(className, properties)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do object[key] = value end
	return object
end

function Editor.new(parent)
	local self = setmetatable({}, Editor)
	self.tabs, self.active = {}, nil
	self.fontSize, self.gutterWidth, self.lineHeight = 14, 48, 17

	self.frame = create("Frame", { BackgroundColor3=Theme.Background, BorderSizePixel=0, Size=UDim2.fromScale(1,1), Parent=parent })
	self.tabBar = create("ScrollingFrame", {
		BackgroundColor3=Theme.Panel, BorderSizePixel=0, Size=UDim2.new(1,0,0,30),
		CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.X,
		ScrollingDirection=Enum.ScrollingDirection.X, ScrollBarThickness=2, Parent=self.frame,
	})
	create("UIListLayout", { FillDirection=Enum.FillDirection.Horizontal, SortOrder=Enum.SortOrder.LayoutOrder, Parent=self.tabBar })
	self.code = create("ScrollingFrame", {
		BackgroundColor3=Theme.Background, BorderSizePixel=0, Position=UDim2.fromOffset(0,30), Size=UDim2.new(1,0,1,-52),
		CanvasSize=UDim2.new(), ScrollingDirection=Enum.ScrollingDirection.XY, ScrollBarThickness=7, Parent=self.frame,
	})
	self.lineNumbers = create("TextLabel", {
		BackgroundColor3=Theme.Panel, BorderSizePixel=0, Position=UDim2.fromOffset(0,0), Size=UDim2.fromOffset(48,20),
		Font=Theme.Font, TextSize=14, TextColor3=Theme.Muted, TextXAlignment=Enum.TextXAlignment.Right,
		TextYAlignment=Enum.TextYAlignment.Top, Text="1", RichText=false, Parent=self.code,
	})
	create("UIPadding", { PaddingTop=UDim.new(0,4), PaddingRight=UDim.new(0,7), Parent=self.lineNumbers })
	self.text = create("TextBox", {
		BackgroundColor3=Theme.Background, BorderSizePixel=0, Position=UDim2.fromOffset(52,0), Size=UDim2.fromOffset(200,20),
		ClearTextOnFocus=false, MultiLine=true, TextEditable=false, TextWrapped=false,
		Font=Theme.Font, TextSize=14, TextColor3=Theme.Text, PlaceholderColor3=Theme.Muted,
		TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
		Text="-- Selecione uma instância no Explorer", Parent=self.code,
	})
	create("UIPadding", { PaddingTop=UDim.new(0,4), PaddingLeft=UDim.new(0,4), Parent=self.text })
	self.status = create("TextLabel", {
		BackgroundColor3=Theme.Panel, BorderSizePixel=0, Position=UDim2.new(0,0,1,-22), Size=UDim2.new(1,0,0,22),
		Font=Enum.Font.Gotham, TextSize=12, TextColor3=Theme.Muted, TextXAlignment=Enum.TextXAlignment.Left,
		Text="  Pronto", Parent=self.frame,
	})
	self.text:GetPropertyChangedSignal("Text"):Connect(function() self:_updateLines() end)
	self.code:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_updateLines() end)
	self:_updateLines()
	return self
end

function Editor:SetCompact(compact)
	local fontSize, gutterWidth, lineHeight = compact and 12 or 14, compact and 40 or 48, compact and 15 or 17
	if self.fontSize == fontSize and self.gutterWidth == gutterWidth then return end
	self.fontSize, self.gutterWidth, self.lineHeight = fontSize, gutterWidth, lineHeight
	self.text.TextSize = fontSize
	self.lineNumbers.TextSize = fontSize
	self.text.Position = UDim2.fromOffset(gutterWidth + 4, 0)
	self:_updateLines()
end

function Editor:_updateLines()
	local count = 1
	for _ in self.text.Text:gmatch("\n") do count += 1 end
	local values = table.create(count)
	for index = 1, count do values[index] = tostring(index) end
	self.lineNumbers.Text = table.concat(values,"\n")
	local widest = 0
	for line in (self.text.Text .. "\n"):gmatch("(.-)\n") do
		widest = math.max(widest, TextService:GetTextSize(line,self.fontSize,Theme.Font,Vector2.new(100000,20)).X)
	end
	local height = math.max(self.code.AbsoluteSize.Y, count * self.lineHeight + 10)
	local width = math.max(self.code.AbsoluteSize.X - self.gutterWidth - 4, widest + 24)
	self.lineNumbers.Size = UDim2.fromOffset(self.gutterWidth,height)
	self.text.Size = UDim2.fromOffset(width,height)
	self.code.CanvasSize = UDim2.fromOffset(self.gutterWidth + 4 + width,height)
end

function Editor:SetStatus(text, kind)
	self.status.Text = "  " .. text
	self.status.TextColor3 = kind == "error" and Theme.Error or kind == "success" and Theme.Success or Theme.Muted
end

function Editor:_select(key)
	local tab = self.tabs[key]
	if not tab then return end
	self.active = key
	for _, current in pairs(self.tabs) do current.button.BackgroundColor3 = current == tab and Theme.Selected or Theme.PanelAlt end
	self.text.Text = tab.source
	self.code.CanvasPosition = Vector2.zero
	self:_updateLines()
end

function Editor:Open(key, title, source)
	local tab = self.tabs[key]
	if tab then tab.source, tab.title = source, title
	else
		local button = create("TextButton", {
			AutoButtonColor=false, BackgroundColor3=Theme.PanelAlt, BorderSizePixel=0, Size=UDim2.fromOffset(155,30),
			Font=Enum.Font.Gotham, TextSize=12, TextColor3=Theme.Text, TextTruncate=Enum.TextTruncate.AtEnd,
			Text="  "..title.."   ×", Parent=self.tabBar,
		})
		tab = { button=button, source=source, title=title }
		self.tabs[key] = tab
		button.MouseButton1Click:Connect(function() self:_select(key) end)
		button.MouseButton2Click:Connect(function()
			button:Destroy(); self.tabs[key]=nil
			if self.active==key then self.active=nil; self.text.Text="-- Aba fechada" end
		end)
	end
	self:_select(key)
end

function Editor:Destroy() self.frame:Destroy() end
return Editor
end

factories["UI.Explorer"] = function(script, require)
local Theme = require(script.Parent.Theme)
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local Explorer = {}
Explorer.__index = Explorer

local function create(className, properties)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do object[key] = value end
	return object
end

local function sortChildren(children)
	table.sort(children, function(a, b)
		local left, right = a.Name:lower(), b.Name:lower()
		if left == right then return a.ClassName < b.ClassName end
		return left < right
	end)
	return children
end

function Explorer.new(parent, config, onSelected, onContext)
	local self = setmetatable({}, Explorer)
	self.config, self.onSelected, self.onContext = config, onSelected, onContext
	self.expanded, self.rows, self.connections = {}, {}, {}
	self.rowHeight, self.fontSize = config.RowHeight, 12
	self.frame = create("Frame", { BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, ClipsDescendants = true, Size = UDim2.fromScale(1, 1), Parent = parent })
	self.search = create("TextBox", {
		BackgroundColor3 = Theme.PanelAlt, BorderColor3 = Theme.Border,
		Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, 28), ClearTextOnFocus = false,
		Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text,
		PlaceholderText = "Pesquisar instâncias...", PlaceholderColor3 = Theme.Muted, Text = "", Parent = self.frame,
	})
	self.list = create("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
		Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40), CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.XY, ScrollBarThickness = 5, Parent = self.frame,
	})
	self.layout = create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.list })
	self.connections[#self.connections + 1] = self.search:GetPropertyChangedSignal("Text"):Connect(function() self:Refresh() end)
	self.connections[#self.connections + 1] = self.list:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_scheduleRefresh() end)
	self.connections[#self.connections + 1] = game.DescendantAdded:Connect(function(instance)
		if instance.Parent == game or self.expanded[instance.Parent] then self:_scheduleRefresh() end
	end)
	self.connections[#self.connections + 1] = game.DescendantRemoving:Connect(function(instance)
		if self.rows[instance] then self:_scheduleRefresh() end
	end)
	self:Refresh()
	return self
end

function Explorer:SetCompact(compact)
	local rowHeight, fontSize = compact and 20 or self.config.RowHeight, compact and 11 or 12
	if rowHeight == self.rowHeight and fontSize == self.fontSize then return end
	self.rowHeight, self.fontSize = rowHeight, fontSize
	self.search.TextSize = compact and 12 or 13
	self:Refresh()
end

function Explorer:_roots()
	local result = {}
	for _, serviceName in ipairs(self.config.RootServices) do
		local ok, service = pcall(game.GetService, game, serviceName)
		if ok and service then result[#result + 1] = service end
	end
	return result
end

function Explorer:_children(parent)
	local ok, children = pcall(parent.GetChildren, parent)
	return ok and sortChildren(children) or {}
end

function Explorer:_ignored(instance)
	return instance == self.config.IgnoreInstance or (self.config.IgnoreInstance and instance:IsDescendantOf(self.config.IgnoreInstance))
end

function Explorer:_flattenExpanded(parent, depth, result)
	for _, child in ipairs(self:_children(parent)) do
		if self:_ignored(child) then continue end
		result[#result + 1] = { instance = child, depth = depth }
		if self.expanded[child] then self:_flattenExpanded(child, depth + 1, result) end
	end
end

function Explorer:_flattenSearch(instance, depth, result, query)
	if self:_ignored(instance) then return false end
	local descendants = {}
	for _, child in ipairs(self:_children(instance)) do self:_flattenSearch(child, depth + 1, descendants, query) end
	local matches = instance.Name:lower():find(query, 1, true) or instance.ClassName:lower():find(query, 1, true)
	if not matches and #descendants == 0 then return false end
	result[#result + 1] = { instance = instance, depth = depth }
	for _, row in ipairs(descendants) do result[#result + 1] = row end
	return true
end

function Explorer:_scheduleRefresh()
	if self.refreshPending then return end
	self.refreshPending = true
	task.defer(function()
		self.refreshPending = false
		if self.frame.Parent then self:Refresh() end
	end)
end

function Explorer:_icon(instance)
	if instance:IsA("LuaSourceContainer") then return "◆" end
	if instance:IsA("BasePart") then return "▣" end
	if instance:IsA("Model") then return "◇" end
	if instance:IsA("Folder") then return "▤" end
	if instance.Parent == game then return "▧" end
	return "•"
end

function Explorer:Refresh()
	for _, row in pairs(self.rows) do if typeof(row) == "Instance" then row:Destroy() end end
	self.rows = {}
	local flat, query = {}, self.search.Text:lower()
	if query ~= "" then
		for _, service in ipairs(self:_roots()) do self:_flattenSearch(service, 0, flat, query) end
	else
		for _, service in ipairs(self:_roots()) do
			flat[#flat + 1] = { instance = service, depth = 0 }
			if self.expanded[service] then self:_flattenExpanded(service, 1, flat) end
		end
	end

	local maximumWidth = math.max(1, self.list.AbsoluteSize.X)
	for order, node in ipairs(flat) do
		local instance, depth = node.instance, node.depth
		local hasChildren = #self:_children(instance) > 0
		local rowText = "  " .. string.rep("   ", depth) .. (hasChildren and (self.expanded[instance] and "▼ " or "▶ ") or "   ") .. self:_icon(instance) .. "  " .. instance.Name
		local measured = TextService:GetTextSize(rowText, self.fontSize, Enum.Font.Gotham, Vector2.new(100000, self.rowHeight)).X + 18
		local rowWidth = math.max(maximumWidth, measured)
		maximumWidth = math.max(maximumWidth, rowWidth)
		local selected = self.selected == instance
		local button = create("TextButton", {
			AutoButtonColor = false, BackgroundColor3 = Theme.Selected,
			BackgroundTransparency = selected and 0.25 or 1, BorderSizePixel = 0,
			Size = UDim2.fromOffset(rowWidth, self.rowHeight), Font = Enum.Font.Gotham,
			TextSize = self.fontSize, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
			Text = rowText, LayoutOrder = order, Parent = self.list,
		})
		button.MouseEnter:Connect(function() button.BackgroundTransparency = 0.45 end)
		button.MouseLeave:Connect(function() button.BackgroundTransparency = self.selected == instance and 0.25 or 1 end)
		local pressToken, longPressed = 0, false
		button.MouseButton1Down:Connect(function()
			pressToken += 1
			local token = pressToken
			longPressed = false
			task.delay(self.config.LongPressSeconds, function()
				if token == pressToken and button.Parent then
					longPressed = true
					self.selected = instance
					self.onContext(instance, button.AbsolutePosition + Vector2.new(24, self.rowHeight))
				end
			end)
		end)
		button.MouseButton1Up:Connect(function() pressToken += 1 end)
		button.MouseButton2Click:Connect(function()
			self.selected = instance
			self.onContext(instance, UserInputService:GetMouseLocation())
		end)
		button.MouseButton1Click:Connect(function()
			if longPressed then longPressed = false return end
			self.selected = instance
			if hasChildren then self.expanded[instance] = not self.expanded[instance] end
			self:Refresh()
			self.onSelected(instance)
		end)
		self.rows[instance] = button
	end
	self.list.CanvasSize = UDim2.fromOffset(maximumWidth, #flat * self.rowHeight)
end

function Explorer:Destroy()
	for _, connection in ipairs(self.connections) do connection:Disconnect() end
	self.connections = {}
	self.frame:Destroy()
end

return Explorer
end

factories["UI.App"] = function(script, require)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Theme = require(script.Parent.Theme)
local Layout = require(script.Parent.Layout)
local Explorer = require(script.Parent.Explorer)
local Editor = require(script.Parent.Editor)
local Parser = require(script.Parent.Parent.Core.Parser)
local Decompiler = require(script.Parent.Parent.Core.Decompiler)
local BytecodeProvider = require(script.Parent.Parent.Providers.BytecodeProvider)

local App = {}
App.__index = App

local function create(className, properties)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do object[key] = value end
	return object
end

local function describe(instance)
	local lines = {
		"-- DeGOAT Instance Inspector", "",
		"Name = " .. string.format("%q", instance.Name),
		"ClassName = " .. string.format("%q", instance.ClassName),
		"Path = " .. instance:GetFullName(), "", "-- Attributes",
	}
	for key, value in pairs(instance:GetAttributes()) do lines[#lines + 1] = key .. " = " .. tostring(value) end
	if #lines == 7 then lines[#lines + 1] = "-- nenhum atributo" end
	local ok, children = pcall(instance.GetChildren, instance)
	lines[#lines + 1] = ""
	lines[#lines + 1] = "Children = " .. (ok and #children or 0)
	if instance:IsA("LuaSourceContainer") then
		lines[#lines + 1] = ""
		lines[#lines + 1] = "-- Segure ou clique com o botão direito para View Script"
	end
	return table.concat(lines, "\n")
end

local function guiParent(player, config)
	if config.UseExecutorUI and type(gethui) == "function" then
		local ok, value = pcall(gethui)
		if ok and typeof(value) == "Instance" then return value end
	end
	return player:WaitForChild("PlayerGui")
end

function App:_viewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

function App:_track(connection)
	self.connections[#self.connections + 1] = connection
	return connection
end

function App:_bindCamera()
	if self.viewportConnection then self.viewportConnection:Disconnect() end
	local camera = workspace.CurrentCamera
	if camera then
		self.viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			self:_fitToViewport(false)
		end)
	end
end

function App:_fitToViewport(resetSize)
	if not self.window or not self.window.Parent then return end
	local viewport = self:_viewport()
	local current = self.window.AbsoluteSize
	local result=Layout.window(viewport.X,viewport.Y,self.config,current.X,current.Y,resetSize)
	self.window.Size = UDim2.fromOffset(result.width,result.height)
	self.window.Position = UDim2.fromOffset(result.x,result.y)
	self:_applyLayout()
end

function App:_applyLayout()
	if not self.window or not self.window.Parent then return end
	local size = self.window.AbsoluteSize
	local layout=Layout.panels(size.X,size.Y,self.config,self.explorerVisible)
	local compact,narrow=layout.compact,layout.narrow
	self.compact, self.narrow = compact, narrow
	local explorerWidth=layout.explorerWidth

	self.left.Visible = layout.leftVisible
	self.left.Size = UDim2.new(0, explorerWidth, 1, 0)
	self.divider.Visible = layout.dividerVisible
	self.divider.Position = UDim2.fromOffset(explorerWidth, 0)
	self.right.Visible = layout.rightVisible
	self.right.Position = UDim2.fromOffset(layout.rightOffset,0)
	self.right.Size = UDim2.new(1,layout.rightInset,1,0)
	self.title.TextSize = compact and 12 or 14
	self.explorer:SetCompact(compact)
	self.editor:SetCompact(compact)
end

function App:SetExplorerVisible(visible)
	self.explorerVisible = visible
	self.sidebar.Text = visible and "◀" or "☰"
	self:_applyLayout()
end

function App.new(root, config)
	local self = setmetatable({}, App)
	self.config = config
	self.cache = setmetatable({}, { __mode = "k" })
	self.connections = {}
	self.explorerVisible = true
	self.provider = BytecodeProvider.new(config)
	local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

	self.gui = create("ScreenGui", {
		Name = "DeGOATExplorer", ResetOnSpawn = false, IgnoreGuiInset = true,
		DisplayOrder = 50, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = guiParent(player, config),
	})
	config.IgnoreInstance = self.gui
	self.window = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.Background,
		BorderColor3 = Theme.Border, ClipsDescendants = true,
		Size = config.InitialSize, Position = UDim2.fromScale(0.5, 0.5), Parent = self.gui,
	})
	self.title = create("TextLabel", {
		BackgroundColor3 = Theme.PanelAlt, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 34),
		Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "           " .. config.Title, Parent = self.window,
	})
	self.sidebar = create("TextButton", {
		AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(42, 34),
		Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Text, Text = "◀", Parent = self.title,
	})
	local close = create("TextButton", {
		BackgroundTransparency = 1, Position = UDim2.new(1, -40, 0, 0), Size = UDim2.fromOffset(40, 34),
		Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Theme.Muted, Text = "×", Parent = self.title,
	})
	local body = create("Frame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 1, -34), Parent = self.window,
	})
	self.left = create("Frame", { BackgroundTransparency = 1, Parent = body })
	self.divider = create("Frame", { BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Size = UDim2.new(0, 1, 1, 0), Parent = body })
	self.right = create("Frame", { BackgroundTransparency = 1, Parent = body })
	local resize = create("TextButton", {
		AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(22, 22), Font = Enum.Font.GothamBold,
		TextSize = 12, TextColor3 = Theme.Muted, Text = "◢", ZIndex = 10, Parent = self.window,
	})

	self.editor = Editor.new(self.right)
	self.context = create("Frame", {
		Visible = false, BackgroundColor3 = Theme.PanelAlt, BorderColor3 = Theme.Border,
		Size = UDim2.fromOffset(178, 34), ZIndex = 50, Parent = self.gui,
	})
	self.contextButton = create("TextButton", {
		AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text,
		Text = "View Script", ZIndex = 51, Parent = self.context,
	})
	self.contextButton.MouseEnter:Connect(function() self.contextButton.BackgroundTransparency = 0.35 self.contextButton.BackgroundColor3 = Theme.Selected end)
	self.contextButton.MouseLeave:Connect(function() self.contextButton.BackgroundTransparency = 1 end)
	self.contextButton.MouseButton1Click:Connect(function()
		local instance = self.contextInstance
		self.context.Visible = false
		if not instance then return end
		if self.provider:IsScript(instance) then self:ViewScript(instance) else self:Select(instance) end
	end)
	self.explorer = Explorer.new(self.left, config, function(instance) self:Select(instance) end, function(instance, position) self:ShowContext(instance, position) end)

	self.sidebar.MouseButton1Click:Connect(function() self:SetExplorerVisible(not self.explorerVisible) end)
	close.MouseButton1Click:Connect(function() self.gui.Enabled = false end)
	local capability, available = self.provider:GetCapability()
	self.editor:SetStatus(available and ("bytecode local: " .. capability) or "getscriptbytecode não disponível", available and "success" or "error")

	local dragging, resizing = false, false
	local startInput, startCenter, startSize, startTopLeft
	self.title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startInput = input.Position
			startCenter = self.window.AbsolutePosition + self.window.AbsoluteSize / 2
		end
	end)
	resize.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			startInput = input.Position
			startSize = self.window.AbsoluteSize
			startTopLeft = self.window.AbsolutePosition
		end
	end)
	self:_track(UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local viewport = self:_viewport()
		local padding = config.ScreenPadding
		if dragging then
			local half = self.window.AbsoluteSize / 2
			local desired = startCenter + (input.Position - startInput)
			local x = math.clamp(desired.X, padding + half.X, math.max(padding + half.X, viewport.X - padding - half.X))
			local y = math.clamp(desired.Y, padding + half.Y, math.max(padding + half.Y, viewport.Y - padding - half.Y))
			self.window.Position = UDim2.fromOffset(x, y)
		elseif resizing then
			local delta = input.Position - startInput
			local maximumWidth = math.max(1, viewport.X - padding * 2)
			local maximumHeight = math.max(1, viewport.Y - padding * 2)
			local minimumWidth = math.min(config.MinimumWidth, maximumWidth)
			local minimumHeight = math.min(config.MinimumHeight, maximumHeight)
			local width = math.clamp(startSize.X + delta.X, minimumWidth, maximumWidth)
			local height = math.clamp(startSize.Y + delta.Y, minimumHeight, maximumHeight)
			self.window.Size = UDim2.fromOffset(width, height)
			self.window.Position = UDim2.fromOffset(startTopLeft.X + width / 2, startTopLeft.Y + height / 2)
		end
	end))
	self:_track(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging, resizing = false, false end
	end))
	self:_track(UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == config.ToggleKey then self.gui.Enabled = not self.gui.Enabled end
	end))
	self:_track(self.window:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_applyLayout() end))
	self:_track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() self:_bindCamera() self:_fitToViewport(false) end))
	self:_bindCamera()
	task.defer(function() self:_fitToViewport(true) end)
	return self
end

function App:RegisterBytecode(instance, raw) self.provider:Register(instance, raw) self.cache[instance] = nil end
function App:SetBytecodeResolver(resolver) self.provider:SetResolver(resolver) self.cache = setmetatable({}, { __mode = "k" }) end

function App:ShowContext(instance, position)
	self.contextInstance = instance
	self.contextButton.Text = self.provider:IsScript(instance) and "  View Script" or "  Inspect Instance"
	local viewport = self:_viewport()
	self.context.Position = UDim2.fromOffset(
		math.clamp(position.X, 0, math.max(0, viewport.X - 182)),
		math.clamp(position.Y, 0, math.max(0, viewport.Y - 38))
	)
	self.context.Visible = true
end

function App:Select(instance)
	self.context.Visible = false
	if self.narrow then self:SetExplorerVisible(false) end
	self.editor:Open(instance, instance.Name, describe(instance))
	self.editor:SetStatus(instance.ClassName)
end

function App:ViewScript(instance)
	self.context.Visible = false
	if self.compact then self:SetExplorerVisible(false) end
	local cached = self.cache[instance]
	if cached then self.editor:Open(instance, instance.Name, cached) self.editor:SetStatus("cache local", "success") return end
	self.editor:SetStatus("decompilando " .. instance.Name .. "...")
	task.spawn(function()
		local bytecode, reason = self.provider:GetBytecode(instance)
		if not bytecode then
			local message = "-- Não foi possível decompilar " .. instance:GetFullName() .. "\n-- " .. reason .. "\n\n-- O DeGOAT precisa de getscriptbytecode no ambiente para obter os bytes brutos."
			self.editor:Open(instance, instance.Name, message)
			self.editor:SetStatus(reason, "error")
			return
		end
		local started = os.clock()
		local ok, result = pcall(function() return Decompiler.decompile(Parser.parse(bytecode)) end)
		if ok then
			self.cache[instance] = result
			self.editor:Open(instance, instance.Name, result)
			self.editor:SetStatus(string.format("decompilado localmente em %.3fs", os.clock() - started), "success")
		else
			self.editor:Open(instance, instance.Name, "-- Falha DeGOAT\n-- " .. tostring(result))
			self.editor:SetStatus("falha no parser/decompiler", "error")
		end
	end)
end

function App:Toggle() self.gui.Enabled = not self.gui.Enabled end

function App:Destroy()
	for _, connection in ipairs(self.connections) do connection:Disconnect() end
	if self.viewportConnection then self.viewportConnection:Disconnect() end
	self.connections = {}
	self.explorer:Destroy()
	self.editor:Destroy()
	self.gui:Destroy()
end

return App
end

return moduleRequire(root)
