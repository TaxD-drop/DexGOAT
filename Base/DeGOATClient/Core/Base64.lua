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
