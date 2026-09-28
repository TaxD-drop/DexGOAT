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

