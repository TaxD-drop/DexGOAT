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
node("Properties", "Core.Properties", core)
node("BytecodeProvider", "Providers.BytecodeProvider", providers)
node("Theme", "UI.Theme", ui)
node("Layout", "UI.Layout", ui)
node("IconProvider", "UI.IconProvider", ui)
node("GestureState", "UI.GestureState", ui)
node("Editor", "UI.Editor", ui)
node("Explorer", "UI.Explorer", ui)
node("ContextMenu", "UI.ContextMenu", ui)
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

local DeGOATClient={ Version="0.5.0-luau" }

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
	GestureMoveTolerance = 9,
	ScrollBarThickness = 11,
	ScrollStepRows = 5,
	AutoBytecode = true,
	UseExecutorUI = true,
	IconBaseUrl = "https://raw.githubusercontent.com/TaxD-drop/DexGOAT/refs/heads/main/DeGOATClient/Icons/",
	IconFolder = "DexGOAT/Icons",
	IconAssets = {},
	AutoClassIcons = true,
	RootServices = {
		"Workspace", "Players", "CoreGui", "Lighting", "MaterialService",
		"ReplicatedFirst", "ReplicatedStorage", "ServerScriptService", "ServerStorage",
		"StarterGui", "StarterPack", "StarterPlayer", "Teams", "SoundService",
		"TextChatService", "RobloxPluginGuiService",
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

factories["Core.Properties"] = function(script, require)
local Properties = {}

local CATEGORY_ORDER = {
	"Identification", "Data", "Transform", "Appearance", "Behavior", "Collision",
	"Assembly", "Mesh", "Audio", "Text", "Layout", "Script", "Attributes", "Other",
}

local SCHEMA = {
	Identification = { "Name", "ClassName", "Parent", "Archivable" },
	Data = {
		"Value", "ValueConstraint", "MaxValue", "MinValue", "CurrentDistance", "CurrentAngle",
		"Attachment0", "Attachment1", "Adornee", "PrimaryPart", "WorldPivot", "PivotOffset",
	},
	Transform = { "CFrame", "Position", "Orientation", "Rotation", "Size", "Scale", "StudsOffset", "StudsOffsetWorldSpace" },
	Appearance = {
		"Visible", "Transparency", "Color", "Color3", "BrickColor", "Material", "MaterialVariant",
		"Reflectance", "CastShadow", "Texture", "TextureID", "TextureId", "Image", "ImageColor3",
		"ImageTransparency", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderSizePixel",
		"Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "ExposureCompensation", "FogColor", "FogEnd",
		"FogStart", "GlobalShadows", "Technology", "DisplayOrder", "LightInfluence", "AlwaysOnTop",
	},
	Behavior = {
		"Enabled", "Disabled", "Active", "Selectable", "Draggable", "Locked", "Massless", "Anchored",
		"CanCollide", "CanQuery", "CanTouch", "CanLoadCharacterAppearance", "ResetOnSpawn", "IgnoreGuiInset",
		"AutoLocalize", "RichText", "TextEditable", "ClearTextOnFocus", "Looped", "Playing", "PlayOnRemove",
		"TimePosition", "PlaybackSpeed", "Volume", "MaxDistance", "RollOffMaxDistance", "RollOffMinDistance",
	},
	Collision = { "CollisionGroup", "CollisionGroupId", "RootPriority", "CustomPhysicalProperties" },
	Assembly = {
		"AssemblyAngularVelocity", "AssemblyCenterOfMass", "AssemblyLinearVelocity", "AssemblyMass",
		"AssemblyRootPart", "Velocity", "RotVelocity",
	},
	Mesh = { "MeshId", "MeshID", "MeshType", "Offset", "VertexColor", "DoubleSided", "RenderFidelity", "CollisionFidelity" },
	Audio = { "SoundId", "SoundGroup", "EmitterSize", "RollOffMode", "RespectFilteringEnabled" },
	Text = {
		"Text", "ContentText", "PlaceholderText", "TextColor3", "TextTransparency", "TextSize", "TextScaled",
		"TextWrapped", "TextXAlignment", "TextYAlignment", "Font", "FontFace", "LineHeight", "MaxVisibleGraphemes",
	},
	Layout = {
		"AnchorPoint", "AutomaticSize", "CanvasPosition", "CanvasSize", "Position", "Size", "LayoutOrder",
		"ZIndex", "ClipsDescendants", "ScrollBarThickness", "ScrollingDirection", "Padding", "FillDirection",
		"HorizontalAlignment", "VerticalAlignment", "SortOrder", "CellPadding", "CellSize",
	},
	Script = { "RunContext", "LinkedSource", "ScriptGuid", "Source" },
}

local READ_ONLY = {
	ClassName = true, Parent = true, ContentText = true, AbsolutePosition = true, AbsoluteSize = true,
	AssemblyCenterOfMass = true, AssemblyMass = true, AssemblyRootPart = true, CurrentDistance = true,
	CurrentAngle = true, CollisionGroupId = true, ScriptGuid = true, Source = true,
}

local EDITABLE_TYPES = {
	string = true, boolean = true, number = true, Vector2 = true, Vector3 = true,
	Color3 = true, UDim = true, UDim2 = true, CFrame = true, BrickColor = true, EnumItem = true,
}

local function envFunction(name)
	local env = _G
	if type(getgenv) == "function" then
		local ok, value = pcall(getgenv)
		if ok and type(value) == "table" then env = value end
	end
	if type(env[name]) == "function" then return env[name] end
	local ok, value = pcall(function() return _G[name] end)
	return ok and type(value) == "function" and value or nil
end

local function encode(value)
	local kind = typeof(value)
	if kind == "string" then return value end
	if kind == "Instance" then return value:GetFullName() end
	if kind == "Vector2" then return string.format("%.6g, %.6g", value.X, value.Y) end
	if kind == "Vector3" then return string.format("%.6g, %.6g, %.6g", value.X, value.Y, value.Z) end
	if kind == "Color3" then return string.format("%d, %d, %d", math.round(value.R * 255), math.round(value.G * 255), math.round(value.B * 255)) end
	if kind == "UDim" then return string.format("%.6g, %d", value.Scale, value.Offset) end
	if kind == "UDim2" then return string.format("%.6g, %d, %.6g, %d", value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset) end
	if kind == "CFrame" then
		local values = { value:GetComponents() }
		for index, item in ipairs(values) do values[index] = string.format("%.6g", item) end
		return table.concat(values, ", ")
	end
	if kind == "EnumItem" then return tostring(value) end
	return tostring(value)
end

local function numbers(text)
	local result = {}
	for value in text:gmatch("[-+]?%d*%.?%d+[eE]?[-+]?%d*") do result[#result + 1] = tonumber(value) end
	return result
end

local function parseEnum(current, text)
	local enumType = tostring(current.EnumType):match("Enum%.(.+)")
	local item = text:match("([^%.]+)$")
	if not enumType or not item then return nil, "enum inválido" end
	local ok, value = pcall(function() return Enum[enumType][item] end)
	return ok and value or nil, ok and nil or "item de enum inválido"
end

local function decode(current, text)
	local kind = typeof(current)
	if kind == "string" then return text end
	if kind == "boolean" then
		local value = text:lower()
		if value == "true" or value == "1" or value == "yes" or value == "sim" then return true end
		if value == "false" or value == "0" or value == "no" or value == "não" or value == "nao" then return false end
		return nil, "use true ou false"
	end
	if kind == "number" then return tonumber(text), tonumber(text) and nil or "número inválido" end
	local values = numbers(text)
	if kind == "Vector2" and #values >= 2 then return Vector2.new(values[1], values[2]) end
	if kind == "Vector3" and #values >= 3 then return Vector3.new(values[1], values[2], values[3]) end
	if kind == "Color3" and #values >= 3 then
		local scale = math.max(values[1], values[2], values[3]) > 1 and 255 or 1
		return Color3.new(values[1] / scale, values[2] / scale, values[3] / scale)
	end
	if kind == "UDim" and #values >= 2 then return UDim.new(values[1], values[2]) end
	if kind == "UDim2" and #values >= 4 then return UDim2.new(values[1], values[2], values[3], values[4]) end
	if kind == "CFrame" and (#values == 3 or #values == 12) then return CFrame.new(table.unpack(values)) end
	if kind == "BrickColor" then
		local ok, value = pcall(BrickColor.new, text)
		return ok and value or nil, ok and nil or "BrickColor inválida"
	end
	if kind == "EnumItem" then return parseEnum(current, text) end
	return nil, "tipo " .. kind .. " não é editável por texto"
end

local function addRow(rows, seen, instance, category, name, value, attribute)
	if seen[name] then return end
	seen[name] = true
	rows[#rows + 1] = {
		category = category, name = name, value = encode(value), raw = value,
		typeName = typeof(value), readOnly = (not attribute and READ_ONLY[name] == true) or not EDITABLE_TYPES[typeof(value)],
		attribute = attribute == true, instance = instance,
	}
end

function Properties.collect(instance)
	local rows, seen = {}, {}
	local dynamic = envFunction("getproperties")
	for _, category in ipairs(CATEGORY_ORDER) do
		for _, name in ipairs(SCHEMA[category] or {}) do
			local ok, value = pcall(function() return instance[name] end)
			if ok then addRow(rows, seen, instance, category, name, value, false) end
		end
	end
	if dynamic then
		local ok, values = pcall(dynamic, instance)
		if ok and type(values) == "table" then
			local names = {}
			for key, item in pairs(values) do
				local name = type(key) == "string" and key or (type(item) == "string" and item or nil)
				if name then names[#names + 1] = name end
			end
			table.sort(names)
			for _, name in ipairs(names) do
				local read, value = pcall(function() return instance[name] end)
				if read then addRow(rows, seen, instance, "Other", name, value, false) end
			end
		end
	end
	local attributes = instance:GetAttributes()
	local attributeNames = {}
	for name in pairs(attributes) do attributeNames[#attributeNames + 1] = name end
	table.sort(attributeNames)
	for _, name in ipairs(attributeNames) do addRow(rows, seen, instance, "Attributes", "@" .. name, attributes[name], true) end
	table.sort(rows, function(left, right)
		local li, ri = table.find(CATEGORY_ORDER, left.category) or 999, table.find(CATEGORY_ORDER, right.category) or 999
		if li ~= ri then return li < ri end
		return left.name:lower() < right.name:lower()
	end)
	return rows, dynamic and "executor + schema" or "schema local"
end

function Properties.write(entry, text)
	if entry.readOnly then return false, "propriedade somente leitura" end
	local value, reason = decode(entry.raw, text)
	if reason then return false, reason end
	local ok, err
	if entry.attribute then
		ok, err = pcall(entry.instance.SetAttribute, entry.instance, entry.name:sub(2), value)
	else
		ok, err = pcall(function() entry.instance[entry.name] = value end)
	end
	return ok, ok and nil or tostring(err)
end

return Properties
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

factories["UI.IconProvider"] = function(script, require)
local IconProvider = {}
IconProvider.__index = IconProvider

local FILES = {
	Workspace = "Workspace.png",
	Players = "Players.png",
	CoreGui = "CoreGui.png",
	Lighting = "Lighting.png",
	MaterialService = "MaterialService.png",
	ReplicatedFirst = "ReplicatedFirst.png",
	ReplicatedStorage = "ReplicatedStorage.png",
	ServerScriptService = "ServerScriptService.png",
	ServerStorage = "ServerStorage.png",
	StarterGui = "StarterGui.png",
	StarterPack = "StarterPack.png",
	StarterPlayer = "StarterPlayer.png",
	Teams = "Teams.png",
	SoundService = "SoundService.png",
	TextChatService = "TextChatService.png",
	RobloxPluginGuiService = "RobloxPluginGuiService.png",
	PluginGuiService = "PluginGuuService.png",
}

local function environment()
	if type(getgenv) == "function" then
		local ok, value = pcall(getgenv)
		if ok and type(value) == "table" then return value end
	end
	return _G
end

local function functionFrom(env, name)
	local value = env[name]
	if type(value) == "function" then return value end
	local ok, global = pcall(function() return _G[name] end)
	return ok and type(global) == "function" and global or nil
end

local function joinPath(folder, filename)
	if folder:sub(-1) == "/" then return folder .. filename end
	return folder .. "/" .. filename
end

function IconProvider.new(config)
	local self = setmetatable({}, IconProvider)
	self.config = config
	self.cache = {}
	self.waiters = {}
	self.loading = {}
	self.env = environment()
	self.asset = functionFrom(self.env, "getcustomasset") or functionFrom(self.env, "getsynasset")
	self.writefile = functionFrom(self.env, "writefile")
	self.isfile = functionFrom(self.env, "isfile")
	self.makefolder = functionFrom(self.env, "makefolder")
	self.isfolder = functionFrom(self.env, "isfolder")
	return self
end

function IconProvider:_filename(instance)
	local known = FILES[instance.ClassName] or FILES[instance.Name]
	if known then return known end
	if self.config.AutoClassIcons and instance.Parent ~= game then return instance.ClassName .. ".png" end
	return nil
end

function IconProvider:_ensureFolder()
	if not self.makefolder then return end
	local current = ""
	for part in self.config.IconFolder:gmatch("[^/]+") do
		current = current == "" and part or (current .. "/" .. part)
		local exists = false
		if self.isfolder then
			local ok, value = pcall(self.isfolder, current)
			exists = ok and value == true
		end
		if not exists then pcall(self.makefolder, current) end
	end
end

function IconProvider:_load(filename)
	local configured = self.config.IconAssets and self.config.IconAssets[filename]
	if type(configured) == "string" and configured ~= "" then return configured end
	if not self.asset or not self.writefile then return nil end
	self:_ensureFolder()
	local path = joinPath(self.config.IconFolder, filename)
	local exists = false
	if self.isfile then
		local ok, value = pcall(self.isfile, path)
		exists = ok and value == true
	end
	if not exists then
		local ok, bytes = pcall(game.HttpGet, game, self.config.IconBaseUrl .. filename)
		if not ok or type(bytes) ~= "string" or #bytes < 8 then return nil end
		local wrote = pcall(self.writefile, path, bytes)
		if not wrote then return nil end
	end
	local ok, assetId = pcall(self.asset, path)
	return ok and type(assetId) == "string" and assetId or nil
end

function IconProvider:Get(instance, callback)
	local filename = self:_filename(instance)
	if not filename then return nil end
	if self.cache[filename] ~= nil then
		local value = self.cache[filename] or nil
		if callback then callback(value) end
		return value
	end
	if callback then
		self.waiters[filename] = self.waiters[filename] or {}
		table.insert(self.waiters[filename], callback)
	end
	if self.loading[filename] then return nil end
	self.loading[filename] = true
	task.spawn(function()
		local value = self:_load(filename)
		self.cache[filename] = value or false
		self.loading[filename] = nil
		local waiters = self.waiters[filename] or {}
		self.waiters[filename] = nil
		for _, waiter in ipairs(waiters) do pcall(waiter, value) end
	end)
	return nil
end

function IconProvider:HasIcon(instance)
	return self:_filename(instance) ~= nil
end

return IconProvider
end

factories["UI.GestureState"] = function(script, require)
local GestureState = {}
GestureState.__index = GestureState

function GestureState.new(tolerance)
	return setmetatable({ tolerance = tolerance or 8, serial = 0, active = nil }, GestureState)
end

function GestureState:Begin(owner, x, y)
	self:Cancel()
	local state = {
		owner = owner, startX = x, startY = y, lastX = x, lastY = y,
		status = "pressed", token = self.serial,
	}
	self.active = state
	return state
end

function GestureState:Move(state, x, y)
	if self.active ~= state or state.status ~= "pressed" then return state.status end
	state.lastX, state.lastY = x, y
	local dx, dy = x - state.startX, y - state.startY
	if dx * dx + dy * dy > self.tolerance * self.tolerance then
		state.status = "cancelled"
		self.serial += 1
	end
	return state.status
end

function GestureState:Hold(state)
	if self.active ~= state or state.status ~= "pressed" or state.token ~= self.serial then return false end
	state.status = "held"
	return true
end

function GestureState:Release(state)
	if self.active ~= state then return "cancelled" end
	self.active = nil
	self.serial += 1
	local status = state.status
	state.status = "released"
	if status == "pressed" then return "click" end
	if status == "held" then return "held" end
	return "cancelled"
end

function GestureState:Cancel()
	self.serial += 1
	if self.active then self.active.status = "cancelled" end
	self.active = nil
end

return GestureState
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

	self.frame = create("Frame", { BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Parent = parent })
	self.tabBar = create("ScrollingFrame", {
		BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 30),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 3, Parent = self.frame,
	})
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.tabBar })

	self.code = create("ScrollingFrame", {
		BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 1, -52),
		CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.XY, ScrollBarThickness = 9, Parent = self.frame,
	})
	self.lineNumbers = create("TextLabel", {
		BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(48, 20),
		Font = Theme.Font, TextSize = 14, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Top, Text = "1", RichText = false, Parent = self.code,
	})
	create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingRight = UDim.new(0, 7), Parent = self.lineNumbers })
	self.text = create("TextBox", {
		BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Position = UDim2.fromOffset(52, 0), Size = UDim2.fromOffset(200, 20),
		ClearTextOnFocus = false, MultiLine = true, TextEditable = false, TextWrapped = false,
		Font = Theme.Font, TextSize = 14, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		Text = "-- Selecione uma instância no Explorer", Parent = self.code,
	})
	create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), Parent = self.text })

	self.properties = create("Frame", {
		Visible = false, BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 1, -52), Parent = self.frame,
	})
	self.propertySearch = create("TextBox", {
		BackgroundColor3 = Theme.PanelAlt, BorderColor3 = Theme.Border, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, 28),
		ClearTextOnFocus = false, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text,
		PlaceholderText = "Filtrar propriedades...", PlaceholderColor3 = Theme.Muted, Text = "", Parent = self.properties,
	})
	self.propertyList = create("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 10, Parent = self.properties,
	})
	self.propertyLayout = create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.propertyList })

	self.status = create("TextLabel", {
		BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -22), Size = UDim2.new(1, 0, 0, 22),
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "  Pronto", Parent = self.frame,
	})
	self.text:GetPropertyChangedSignal("Text"):Connect(function() self:_updateLines() end)
	self.code:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_updateLines() end)
	self.propertySearch:GetPropertyChangedSignal("Text"):Connect(function()
		local tab = self.tabs[self.active]
		if tab and tab.kind == "properties" then self:_renderProperties(tab) end
	end)
	self:_updateLines()
	return self
end

function Editor:SetCompact(compact)
	self.compact = compact
	local fontSize, gutterWidth, lineHeight = compact and 12 or 14, compact and 40 or 48, compact and 15 or 17
	if self.fontSize == fontSize and self.gutterWidth == gutterWidth then return end
	self.fontSize, self.gutterWidth, self.lineHeight = fontSize, gutterWidth, lineHeight
	self.text.TextSize = fontSize
	self.lineNumbers.TextSize = fontSize
	self.text.Position = UDim2.fromOffset(gutterWidth + 4, 0)
	self:_updateLines()
	local tab = self.tabs[self.active]
	if tab and tab.kind == "properties" then self:_renderProperties(tab) end
end

function Editor:_updateLines()
	local count = 1
	for _ in self.text.Text:gmatch("\n") do count += 1 end
	local values = table.create(count)
	for index = 1, count do values[index] = tostring(index) end
	self.lineNumbers.Text = table.concat(values, "\n")
	local widest = 0
	for line in (self.text.Text .. "\n"):gmatch("(.-)\n") do
		widest = math.max(widest, TextService:GetTextSize(line, self.fontSize, Theme.Font, Vector2.new(100000, 20)).X)
	end
	local height = math.max(self.code.AbsoluteSize.Y, count * self.lineHeight + 10)
	local width = math.max(self.code.AbsoluteSize.X - self.gutterWidth - 4, widest + 24)
	self.lineNumbers.Size = UDim2.fromOffset(self.gutterWidth, height)
	self.text.Size = UDim2.fromOffset(width, height)
	self.code.CanvasSize = UDim2.fromOffset(self.gutterWidth + 4 + width, height)
end

function Editor:SetStatus(text, kind)
	self.status.Text = "  " .. text
	self.status.TextColor3 = kind == "error" and Theme.Error or kind == "success" and Theme.Success or Theme.Muted
end

function Editor:_close(key)
	local tab = self.tabs[key]
	if not tab then return end
	tab.button:Destroy()
	self.tabs[key] = nil
	if self.active ~= key then return end
	self.active = nil
	local nextKey = next(self.tabs)
	if nextKey then self:_select(nextKey) else
		self.code.Visible, self.properties.Visible = true, false
		self.text.Text = "-- Nenhuma aba aberta"
	end
end

function Editor:_makeTab(key, title)
	local holder = create("Frame", { BackgroundColor3 = Theme.PanelAlt, BorderSizePixel = 0, Size = UDim2.fromOffset(178, 30), Parent = self.tabBar })
	local selectButton = create("TextButton", {
		AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, -30, 1, 0),
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "  " .. title, Parent = holder,
	})
	local closeButton = create("TextButton", {
		AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(1, -30, 0, 0), Size = UDim2.fromOffset(30, 30),
		Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Muted, Text = "×", Parent = holder,
	})
	selectButton.MouseButton1Click:Connect(function() self:_select(key) end)
	closeButton.MouseButton1Click:Connect(function() self:_close(key) end)
	return holder, selectButton
end

function Editor:_renderProperties(tab)
	for _, child in ipairs(self.propertyList:GetChildren()) do
		if child ~= self.propertyLayout then child:Destroy() end
	end
	local query = self.propertySearch.Text:lower()
	local lastCategory, order = nil, 0
	for _, entry in ipairs(tab.rows or {}) do
		local searchable = (entry.name .. " " .. entry.category .. " " .. entry.typeName):lower()
		if query ~= "" and not searchable:find(query, 1, true) then continue end
		if entry.category ~= lastCategory then
			lastCategory, order = entry.category, order + 1
			create("TextLabel", {
				BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Size = UDim2.new(1, -10, 0, 24), LayoutOrder = order,
				Font = Enum.Font.GothamBold, TextSize = self.fontSize - 1, TextColor3 = Theme.Accent,
				TextXAlignment = Enum.TextXAlignment.Left, Text = "  " .. lastCategory, Parent = self.propertyList,
			})
		end
		order += 1
		local row = create("Frame", {
			BackgroundColor3 = order % 2 == 0 and Theme.Background or Theme.PanelAlt, BackgroundTransparency = 0.35,
			BorderSizePixel = 0, Size = UDim2.new(1, -10, 0, self.compact and 25 or 28), LayoutOrder = order, Parent = self.propertyList,
		})
		create("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(0.42, -4, 1, 0), Font = Enum.Font.Gotham,
			TextSize = self.fontSize - 2, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, Text = "  " .. entry.name, Parent = row,
		})
		local field = create("TextBox", {
			BackgroundColor3 = Theme.Panel, BackgroundTransparency = entry.readOnly and 0.7 or 0.15, BorderSizePixel = 0,
			Position = UDim2.new(0.42, 0, 0, 2), Size = UDim2.new(0.58, -4, 1, -4), ClearTextOnFocus = false,
			TextEditable = not entry.readOnly, Font = Theme.Font, TextSize = self.fontSize - 2,
			TextColor3 = entry.readOnly and Theme.Muted or Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, Text = entry.value, Parent = row,
		})
		create("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), Parent = field })
		if not entry.readOnly then
			field.FocusLost:Connect(function()
				if field.Text == entry.value then return end
				local ok, message, replacement = tab.onCommit(entry, field.Text)
				if ok then
					self:SetStatus(message or (entry.name .. " atualizado"), "success")
					if replacement then tab.rows = replacement end
					task.defer(function() if self.active == tab.key then self:_renderProperties(tab) end end)
				else
					field.Text = entry.value
					self:SetStatus(message or "não foi possível alterar", "error")
				end
			end)
		end
	end
end

function Editor:_select(key)
	local tab = self.tabs[key]
	if not tab then return end
	self.active = key
	for _, current in pairs(self.tabs) do current.button.BackgroundColor3 = current == tab and Theme.Selected or Theme.PanelAlt end
	self.code.Visible = tab.kind == "code"
	self.properties.Visible = tab.kind == "properties"
	if tab.kind == "code" then
		self.text.Text = tab.source
		self.code.CanvasPosition = Vector2.zero
		self:_updateLines()
	else
		self.propertySearch.Text = ""
		self.propertyList.CanvasPosition = Vector2.zero
		self:_renderProperties(tab)
	end
end

function Editor:OpenCode(key, title, source)
	local tab = self.tabs[key]
	if tab then
		tab.source, tab.title, tab.kind = source, title, "code"
		tab.selectButton.Text = "  " .. title
	else
		local holder, selectButton = self:_makeTab(key, title)
		tab = { key = key, button = holder, selectButton = selectButton, source = source, title = title, kind = "code" }
		self.tabs[key] = tab
	end
	self:_select(key)
end

function Editor:OpenProperties(key, title, rows, onCommit)
	local tab = self.tabs[key]
	if tab then
		tab.rows, tab.title, tab.kind, tab.onCommit = rows, title, "properties", onCommit
		tab.selectButton.Text = "  " .. title
	else
		local holder, selectButton = self:_makeTab(key, title)
		tab = { key = key, button = holder, selectButton = selectButton, rows = rows, title = title, kind = "properties", onCommit = onCommit }
		self.tabs[key] = tab
	end
	self:_select(key)
end

function Editor:Open(key, title, source)
	self:OpenCode(key, title, source)
end

function Editor:Destroy()
	self.frame:Destroy()
end

return Editor
end

factories["UI.Explorer"] = function(script, require)
local Theme = require(script.Parent.Theme)
local IconProvider = require(script.Parent.IconProvider)
local GestureState = require(script.Parent.GestureState)
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local Explorer = {}
Explorer.__index = Explorer

local function create(className, properties)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do object[key] = value end
	return object
end

local function point2(position)
	return Vector2.new(position.X, position.Y)
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
	self.iconProvider = IconProvider.new(config)
	self.gestureState = GestureState.new(config.GestureMoveTolerance)
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
		ScrollingDirection = Enum.ScrollingDirection.XY, ScrollBarThickness = config.ScrollBarThickness,
		ScrollBarImageColor3 = Theme.Muted, Parent = self.frame,
	})
	self.layout = create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.list })
	self.scrollUp = create("TextButton", {
		AutoButtonColor = false, BackgroundColor3 = Theme.PanelAlt, BackgroundTransparency = 0.08,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -config.ScrollBarThickness, 0, 41),
		Size = UDim2.fromOffset(25, 24), Font = Enum.Font.GothamBold, TextSize = 10,
		TextColor3 = Theme.Text, Text = "▲", ZIndex = 20, Parent = self.frame,
	})
	self.scrollDown = create("TextButton", {
		AutoButtonColor = false, BackgroundColor3 = Theme.PanelAlt, BackgroundTransparency = 0.08,
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -config.ScrollBarThickness, 1, -2),
		Size = UDim2.fromOffset(25, 24), Font = Enum.Font.GothamBold, TextSize = 10,
		TextColor3 = Theme.Text, Text = "▼", ZIndex = 20, Parent = self.frame,
	})
	self.connections[#self.connections + 1] = self.search:GetPropertyChangedSignal("Text"):Connect(function() self:Refresh() end)
	self.connections[#self.connections + 1] = self.list:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_scheduleRefresh() end)
	self.connections[#self.connections + 1] = game.DescendantAdded:Connect(function(instance)
		if instance.Parent == game or self.expanded[instance.Parent] then self:_scheduleRefresh() end
	end)
	self.connections[#self.connections + 1] = game.DescendantRemoving:Connect(function(instance)
		if self.rows[instance] then self:_scheduleRefresh() end
	end)
	self.connections[#self.connections + 1] = UserInputService.InputChanged:Connect(function(input) self:_gestureMoved(input) end)
	self.connections[#self.connections + 1] = UserInputService.InputEnded:Connect(function(input) self:_gestureEnded(input) end)
	self.scrollUp.MouseButton1Click:Connect(function() self:_scroll(-1) end)
	self.scrollDown.MouseButton1Click:Connect(function() self:_scroll(1) end)
	self:Refresh()
	return self
end

function Explorer:SetCompact(compact)
	local rowHeight, fontSize = compact and 22 or self.config.RowHeight, compact and 11 or 12
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

function Explorer:_fallbackIcon(instance)
	if instance:IsA("LuaSourceContainer") then return "◆" end
	if instance:IsA("BasePart") then return "▣" end
	if instance:IsA("Model") then return "◇" end
	if instance:IsA("Folder") then return "▤" end
	if instance.Parent == game then return "▧" end
	return "•"
end

function Explorer:_updateSelection()
	for instance, row in pairs(self.rows) do
		if typeof(row) == "Instance" and row.Parent then row.BackgroundTransparency = self.selected == instance and 0.25 or 1 end
	end
end

function Explorer:_cancelGesture()
	self.gestureState:Cancel()
	self.gesture = nil
end

function Explorer:_beginGesture(button, instance, input, hasChildren)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	self:_cancelGesture()
	local point = point2(input.Position)
	local gesture = self.gestureState:Begin(input, point.X, point.Y)
	gesture.button, gesture.instance, gesture.input, gesture.hasChildren = button, instance, input, hasChildren
	self.gesture = gesture
	task.delay(self.config.LongPressSeconds, function()
		if self.gesture ~= gesture or not button.Parent or not self.gestureState:Hold(gesture) then return end
		self.selected = instance
		self:_updateSelection()
		self.onContext(instance, Vector2.new(gesture.lastX + 8, gesture.lastY + 8))
	end)
end

function Explorer:_gestureMoved(input)
	local gesture = self.gesture
	if not gesture or gesture.status ~= "pressed" then return end
	local relevant = input == gesture.input
	if gesture.input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement then relevant = true end
	if not relevant then return end
	local point = point2(input.Position)
	self.gestureState:Move(gesture, point.X, point.Y)
end

function Explorer:_gestureEnded(input)
	local gesture = self.gesture
	if not gesture then return end
	local relevant = input == gesture.input
	if gesture.input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1 then relevant = true end
	if not relevant then return end
	self.gesture = nil
	local outcome = self.gestureState:Release(gesture)
	if outcome ~= "click" or not gesture.button.Parent then return end
	self.selected = gesture.instance
	if gesture.hasChildren then self.expanded[gesture.instance] = not self.expanded[gesture.instance] end
	self:Refresh()
	self.onSelected(gesture.instance)
end

function Explorer:_scroll(direction)
	local step = self.rowHeight * self.config.ScrollStepRows
	local maximum = math.max(0, self.list.AbsoluteCanvasSize.Y - self.list.AbsoluteSize.Y)
	self.list.CanvasPosition = Vector2.new(self.list.CanvasPosition.X, math.clamp(self.list.CanvasPosition.Y + direction * step, 0, maximum))
end

function Explorer:Refresh()
	self:_cancelGesture()
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
		local indent = 7 + depth * 15
		local measured = TextService:GetTextSize(instance.Name, self.fontSize, Enum.Font.Gotham, Vector2.new(100000, self.rowHeight)).X
		local rowWidth = math.max(maximumWidth, indent + 46 + measured)
		maximumWidth = math.max(maximumWidth, rowWidth)
		local selected = self.selected == instance
		local button = create("TextButton", {
			AutoButtonColor = false, BackgroundColor3 = Theme.Selected, BackgroundTransparency = selected and 0.25 or 1,
			BorderSizePixel = 0, Size = UDim2.fromOffset(rowWidth, self.rowHeight), Text = "", LayoutOrder = order, Parent = self.list,
		})
		create("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(indent, 0), Size = UDim2.fromOffset(15, self.rowHeight),
			Font = Enum.Font.GothamBold, TextSize = self.fontSize - 1, TextColor3 = Theme.Muted,
			Text = hasChildren and (self.expanded[instance] and "▼" or "▶") or "", Parent = button,
		})
		local icon = create("ImageLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(indent + 18, math.floor((self.rowHeight - 16) / 2)),
			Size = UDim2.fromOffset(16, 16), Image = "", ScaleType = Enum.ScaleType.Fit, Parent = button,
		})
		local fallback = create("TextLabel", {
			BackgroundTransparency = 1, Position = icon.Position, Size = icon.Size, Font = Enum.Font.GothamBold,
			TextSize = self.fontSize, TextColor3 = Theme.Muted, Text = self:_fallbackIcon(instance), Parent = button,
		})
		local function applyIcon(assetId)
			if not button.Parent or not assetId then return end
			icon.Image = assetId
			fallback.Visible = false
		end
		local immediate = self.iconProvider:Get(instance, applyIcon)
		if immediate then applyIcon(immediate) end
		create("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(indent + 39, 0), Size = UDim2.new(1, -indent - 39, 1, 0),
			Font = Enum.Font.Gotham, TextSize = self.fontSize, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.None, Text = instance.Name, Parent = button,
		})
		button.MouseEnter:Connect(function() button.BackgroundTransparency = 0.45 end)
		button.MouseLeave:Connect(function() button.BackgroundTransparency = self.selected == instance and 0.25 or 1 end)
		button.InputBegan:Connect(function(input) self:_beginGesture(button, instance, input, hasChildren) end)
		button.MouseButton2Click:Connect(function()
			self:_cancelGesture()
			self.selected = instance
			self:_updateSelection()
			self.onContext(instance, UserInputService:GetMouseLocation())
		end)
		self.rows[instance] = button
	end
	self.list.CanvasSize = UDim2.fromOffset(maximumWidth, #flat * self.rowHeight)
end

function Explorer:Destroy()
	self:_cancelGesture()
	for _, connection in ipairs(self.connections) do connection:Disconnect() end
	self.connections = {}
	self.frame:Destroy()
end

return Explorer
end

factories["UI.ContextMenu"] = function(script, require)
local Theme = require(script.Parent.Theme)
local UserInputService = game:GetService("UserInputService")

local ContextMenu = {}
ContextMenu.__index = ContextMenu

local function create(className, properties)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do object[key] = value end
	return object
end

function ContextMenu.new(parent, viewportProvider)
	local self = setmetatable({}, ContextMenu)
	self.viewportProvider = viewportProvider
	self.frame = create("Frame", {
		Visible = false, BackgroundColor3 = Theme.PanelAlt, BorderColor3 = Theme.Border,
		Size = UDim2.fromOffset(210, 10), ZIndex = 100, Parent = parent,
	})
	self.layout = create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1), Parent = self.frame })
	create("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), Parent = self.frame })
	self.connection = UserInputService.InputBegan:Connect(function(input)
		if not self.frame.Visible then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local point, position, size = input.Position, self.frame.AbsolutePosition, self.frame.AbsoluteSize
		if point.X < position.X or point.Y < position.Y or point.X > position.X + size.X or point.Y > position.Y + size.Y then
			self:Hide()
		end
	end)
	return self
end

function ContextMenu:Show(position, actions)
	for _, child in ipairs(self.frame:GetChildren()) do
		if child ~= self.layout and not child:IsA("UIPadding") then child:Destroy() end
	end
	local visibleActions = {}
	for _, action in ipairs(actions) do if action.visible ~= false then visibleActions[#visibleActions + 1] = action end end
	local height = #visibleActions * 31 + math.max(0, #visibleActions - 1) + 6
	self.frame.Size = UDim2.fromOffset(210, height)
	local viewport = self.viewportProvider()
	self.frame.Position = UDim2.fromOffset(
		math.clamp(position.X, 0, math.max(0, viewport.X - 214)),
		math.clamp(position.Y, 0, math.max(0, viewport.Y - height - 4))
	)
	for index, action in ipairs(visibleActions) do
		local enabled = action.enabled ~= false
		local button = create("TextButton", {
			AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 31),
			LayoutOrder = index, Font = Enum.Font.Gotham, TextSize = 12,
			TextColor3 = not enabled and Theme.Muted or (action.danger and Theme.Error or Theme.Text),
			TextXAlignment = Enum.TextXAlignment.Left, Text = "   " .. action.label, ZIndex = 101, Parent = self.frame,
		})
		if enabled then
			button.MouseEnter:Connect(function() button.BackgroundTransparency = 0.35 button.BackgroundColor3 = Theme.Selected end)
			button.MouseLeave:Connect(function() button.BackgroundTransparency = 1 end)
			button.MouseButton1Click:Connect(function()
				self:Hide()
				action.callback()
			end)
		end
	end
	self.frame.Visible = true
end

function ContextMenu:Hide()
	self.frame.Visible = false
end

function ContextMenu:Destroy()
	if self.connection then self.connection:Disconnect() end
	self.frame:Destroy()
end

return ContextMenu
end

factories["UI.App"] = function(script, require)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Theme = require(script.Parent.Theme)
local Layout = require(script.Parent.Layout)
local Explorer = require(script.Parent.Explorer)
local Editor = require(script.Parent.Editor)
local ContextMenu = require(script.Parent.ContextMenu)
local Properties = require(script.Parent.Parent.Core.Properties)
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

local function point2(position)
	return Vector2.new(position.X, position.Y)
end

local function environmentFunction(name)
	local env = _G
	if type(getgenv) == "function" then
		local ok, value = pcall(getgenv)
		if ok and type(value) == "table" then env = value end
	end
	if type(env[name]) == "function" then return env[name] end
	local ok, value = pcall(function() return _G[name] end)
	return ok and type(value) == "function" and value or nil
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
			self.menu:Hide()
		end)
	end
end

function App:_fitToViewport(resetSize)
	if not self.window or not self.window.Parent then return end
	local viewport = self:_viewport()
	local current = self.window.AbsoluteSize
	local result = Layout.window(viewport.X, viewport.Y, self.config, current.X, current.Y, resetSize)
	self.window.Size = UDim2.fromOffset(result.width, result.height)
	self.window.Position = UDim2.fromOffset(result.x, result.y)
	self:_applyLayout()
end

function App:_applyLayout()
	if not self.window or not self.window.Parent then return end
	local size = self.window.AbsoluteSize
	local layout = Layout.panels(size.X, size.Y, self.config, self.explorerVisible)
	local compact, narrow = layout.compact, layout.narrow
	self.compact, self.narrow = compact, narrow
	local explorerWidth = layout.explorerWidth

	self.left.Visible = layout.leftVisible
	self.left.Size = UDim2.new(0, explorerWidth, 1, 0)
	self.divider.Visible = layout.dividerVisible
	self.divider.Position = UDim2.fromOffset(explorerWidth, 0)
	self.right.Visible = layout.rightVisible
	self.right.Position = UDim2.fromOffset(layout.rightOffset, 0)
	self.right.Size = UDim2.new(1, layout.rightInset, 1, 0)
	self.title.TextSize = compact and 12 or 14
	self.explorer:SetCompact(compact)
	self.editor:SetCompact(compact)
end

function App:SetExplorerVisible(visible)
	self.explorerVisible = visible
	self.sidebar.Text = visible and "◀" or "☰"
	self:_applyLayout()
end

function App:_makePrompt()
	self.promptShade = create("Frame", {
		Visible = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35,
		BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 150, Parent = self.gui,
	})
	local dismiss = create("TextButton", {
		AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1), Text = "", ZIndex = 150, Parent = self.promptShade,
	})
	self.prompt = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(330, 150),
		BackgroundColor3 = Theme.PanelAlt, BorderColor3 = Theme.Border, ZIndex = 151, Parent = self.promptShade,
	})
	self.promptTitle = create("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 30),
		Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Ação", ZIndex = 152, Parent = self.prompt,
	})
	self.promptInput = create("TextBox", {
		BackgroundColor3 = Theme.Background, BorderColor3 = Theme.Border, Position = UDim2.fromOffset(12, 45), Size = UDim2.new(1, -24, 0, 34),
		ClearTextOnFocus = false, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, Text = "", ZIndex = 152, Parent = self.prompt,
	})
	self.promptCancel = create("TextButton", {
		AutoButtonColor = false, BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Position = UDim2.new(1, -176, 1, -45), Size = UDim2.fromOffset(76, 32),
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, Text = "Cancelar", ZIndex = 152, Parent = self.prompt,
	})
	self.promptConfirm = create("TextButton", {
		AutoButtonColor = false, BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Position = UDim2.new(1, -92, 1, -45), Size = UDim2.fromOffset(80, 32),
		Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Text, Text = "Confirmar", ZIndex = 152, Parent = self.prompt,
	})
	self.promptCancel.MouseButton1Click:Connect(function() self.promptShade.Visible = false end)
	dismiss.MouseButton1Click:Connect(function() self.promptShade.Visible = false end)
	self.promptConfirm.MouseButton1Click:Connect(function()
		local callback, text = self.promptCallback, self.promptInput.Text
		self.promptShade.Visible = false
		if callback then callback(text) end
	end)
end

function App:_promptAction(title, initialValue, confirmText, callback, hideInput, danger)
	self.menu:Hide()
	self.promptTitle.Text = title
	self.promptInput.Visible = not hideInput
	self.promptInput.Text = initialValue or ""
	self.promptConfirm.Text = confirmText or "Confirmar"
	self.promptConfirm.BackgroundColor3 = danger and Theme.Error or Theme.Accent
	self.promptCallback = callback
	local viewport = self:_viewport()
	self.prompt.Size = UDim2.fromOffset(math.min(330, math.max(250, viewport.X - 32)), hideInput and 112 or 150)
	self.promptShade.Visible = true
	if not hideInput then task.defer(function() self.promptInput:CaptureFocus() end) end
end

function App:_clone(instance)
	local okArchivable, wasArchivable = pcall(function() return instance.Archivable end)
	if okArchivable and not wasArchivable then pcall(function() instance.Archivable = true end) end
	local ok, clone = pcall(instance.Clone, instance)
	if okArchivable and not wasArchivable then pcall(function() instance.Archivable = false end) end
	return ok and clone or nil, ok and nil or tostring(clone)
end

function App:_copy(instance)
	local clone, reason = self:_clone(instance)
	if not clone then self.editor:SetStatus("falha ao copiar: " .. reason, "error") return end
	self.clipboard = { template = clone, source = instance }
	self.editor:SetStatus(instance.Name .. " copiado", "success")
end

function App:_pasteInto(parent)
	if not self.clipboard or not self.clipboard.template then return end
	local clone, reason = self:_clone(self.clipboard.template)
	if not clone then self.editor:SetStatus("falha ao clonar: " .. reason, "error") return end
	local ok, err = pcall(function() clone.Parent = parent end)
	if not ok then clone:Destroy() self.editor:SetStatus("não foi possível colar: " .. tostring(err), "error") return end
	self.editor:SetStatus(clone.Name .. " colado em " .. parent.Name, "success")
	self.explorer.expanded[parent] = true
	self.explorer:Refresh()
end

function App:_copyPath(instance)
	local path = instance:GetFullName()
	local setclipboard = environmentFunction("setclipboard") or environmentFunction("toclipboard")
	if setclipboard then
		local ok, err = pcall(setclipboard, path)
		self.editor:SetStatus(ok and "caminho copiado" or ("falha no clipboard: " .. tostring(err)), ok and "success" or "error")
	else
		self.editor:OpenCode({}, "Path", path)
		self.editor:SetStatus("clipboard indisponível; caminho aberto em uma aba")
	end
end

function App.new(root, config)
	local self = setmetatable({}, App)
	self.config = config
	self.cache = setmetatable({}, { __mode = "k" })
	self.propertyKeys = setmetatable({}, { __mode = "k" })
	self.scriptKeys = setmetatable({}, { __mode = "k" })
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
	self.menu = ContextMenu.new(self.gui, function() return self:_viewport() end)
	self:_makePrompt()
	self.explorer = Explorer.new(self.left, config, function(instance) self:Select(instance) end, function(instance, position) self:ShowContext(instance, position) end)

	self.sidebar.MouseButton1Click:Connect(function() self:SetExplorerVisible(not self.explorerVisible) end)
	close.MouseButton1Click:Connect(function() self.gui.Enabled = false self.menu:Hide() end)
	local capability, available = self.provider:GetCapability()
	self.editor:SetStatus(available and ("bytecode local: " .. capability) or "getscriptbytecode não disponível", available and "success" or "error")

	local dragMode, dragInput, startInput, startCenter, startSize, startTopLeft
	self.title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragMode, dragInput, startInput = "move", input, point2(input.Position)
			startCenter = self.window.AbsolutePosition + self.window.AbsoluteSize / 2
		end
	end)
	resize.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragMode, dragInput, startInput = "resize", input, point2(input.Position)
			startSize, startTopLeft = self.window.AbsoluteSize, self.window.AbsolutePosition
		end
	end)
	self:_track(UserInputService.InputChanged:Connect(function(input)
		if not dragMode then return end
		local relevant = input == dragInput or (dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)
		if not relevant then return end
		local viewport, padding = self:_viewport(), config.ScreenPadding
		if dragMode == "move" then
			local half = self.window.AbsoluteSize / 2
			local desired = startCenter + (point2(input.Position) - startInput)
			local x = math.clamp(desired.X, padding + half.X, math.max(padding + half.X, viewport.X - padding - half.X))
			local y = math.clamp(desired.Y, padding + half.Y, math.max(padding + half.Y, viewport.Y - padding - half.Y))
			self.window.Position = UDim2.fromOffset(x, y)
		else
			local delta = point2(input.Position) - startInput
			local maximumWidth, maximumHeight = math.max(1, viewport.X - padding * 2), math.max(1, viewport.Y - padding * 2)
			local minimumWidth, minimumHeight = math.min(config.MinimumWidth, maximumWidth), math.min(config.MinimumHeight, maximumHeight)
			local width = math.clamp(startSize.X + delta.X, minimumWidth, maximumWidth)
			local height = math.clamp(startSize.Y + delta.Y, minimumHeight, maximumHeight)
			self.window.Size = UDim2.fromOffset(width, height)
			self.window.Position = UDim2.fromOffset(startTopLeft.X + width / 2, startTopLeft.Y + height / 2)
		end
	end))
	self:_track(UserInputService.InputEnded:Connect(function(input)
		if not dragMode then return end
		if input == dragInput or (dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1) then
			dragMode, dragInput = nil, nil
		end
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
	local isScript = self.provider:IsScript(instance)
	local canDelete = instance.Parent ~= game
	self.menu:Show(position, {
		{ label = "View Script", visible = isScript, callback = function() self:ViewScript(instance) end },
		{ label = "Properties", callback = function() self:Select(instance) end },
		{ label = "Copy Path", callback = function() self:_copyPath(instance) end },
		{ label = "Rename", callback = function()
			self:_promptAction("Renomear " .. instance.Name, instance.Name, "Renomear", function(value)
				if value == "" then self.editor:SetStatus("o nome não pode ficar vazio", "error") return end
				local ok, err = pcall(function() instance.Name = value end)
				self.editor:SetStatus(ok and "instância renomeada" or tostring(err), ok and "success" or "error")
				if ok then self.explorer:Refresh() self:Select(instance) end
			end)
		end },
		{ label = "Copy", callback = function() self:_copy(instance) end },
		{ label = "Paste Into", enabled = self.clipboard ~= nil, callback = function() self:_pasteInto(instance) end },
		{ label = "Duplicate", enabled = canDelete, callback = function()
			local clone, reason = self:_clone(instance)
			if not clone then self.editor:SetStatus("falha ao duplicar: " .. reason, "error") return end
			local ok, err = pcall(function() clone.Parent = instance.Parent end)
			if not ok then clone:Destroy() end
			self.editor:SetStatus(ok and (instance.Name .. " duplicado") or tostring(err), ok and "success" or "error")
		end },
		{ label = "Delete", enabled = canDelete, danger = true, callback = function()
			self:_promptAction("Excluir " .. instance.Name .. "?", "", "Excluir", function()
				local ok, err = pcall(instance.Destroy, instance)
				self.editor:SetStatus(ok and "instância excluída do cliente" or tostring(err), ok and "success" or "error")
			end, true, true)
		end },
	})
end

function App:Select(instance)
	self.menu:Hide()
	if self.narrow then self:SetExplorerVisible(false) end
	local key = self.propertyKeys[instance]
	if not key then key = {} self.propertyKeys[instance] = key end
	local rows, source = Properties.collect(instance)
	self.editor:OpenProperties(key, instance.Name, rows, function(entry, text)
		local ok, reason = Properties.write(entry, text)
		if not ok then return false, reason end
		self.explorer:Refresh()
		local replacement = Properties.collect(instance)
		return true, entry.name .. " atualizado", replacement
	end)
	self.editor:SetStatus(string.format("%s · %d propriedades · %s", instance.ClassName, #rows, source))
end

function App:ViewScript(instance)
	self.menu:Hide()
	if self.compact then self:SetExplorerVisible(false) end
	local key = self.scriptKeys[instance]
	if not key then key = {} self.scriptKeys[instance] = key end
	local cached = self.cache[instance]
	if cached then self.editor:OpenCode(key, instance.Name .. " · Source", cached) self.editor:SetStatus("cache local", "success") return end
	self.editor:SetStatus("decompilando " .. instance.Name .. "...")
	task.spawn(function()
		local bytecode, reason = self.provider:GetBytecode(instance)
		if not bytecode then
			local message = "-- Não foi possível decompilar " .. instance:GetFullName() .. "\n-- " .. reason .. "\n\n-- O DeGOAT precisa de getscriptbytecode no ambiente para obter os bytes brutos."
			self.editor:OpenCode(key, instance.Name .. " · Source", message)
			self.editor:SetStatus(reason, "error")
			return
		end
		local started = os.clock()
		local ok, result = pcall(function() return Decompiler.decompile(Parser.parse(bytecode)) end)
		if ok then
			self.cache[instance] = result
			self.editor:OpenCode(key, instance.Name .. " · Source", result)
			self.editor:SetStatus(string.format("decompilado localmente em %.3fs", os.clock() - started), "success")
		else
			self.editor:OpenCode(key, instance.Name .. " · Source", "-- Falha DeGOAT\n-- " .. tostring(result))
			self.editor:SetStatus("falha no parser/decompiler", "error")
		end
	end)
end

function App:Toggle() self.gui.Enabled = not self.gui.Enabled end

function App:Destroy()
	for _, connection in ipairs(self.connections) do connection:Disconnect() end
	if self.viewportConnection then self.viewportConnection:Disconnect() end
	self.connections = {}
	if self.clipboard and self.clipboard.template then pcall(self.clipboard.template.Destroy, self.clipboard.template) end
	self.menu:Destroy()
	self.explorer:Destroy()
	self.editor:Destroy()
	self.gui:Destroy()
end

return App
end

return moduleRequire(root)
