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
