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

