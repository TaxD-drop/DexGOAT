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
