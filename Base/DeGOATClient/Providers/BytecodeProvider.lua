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
