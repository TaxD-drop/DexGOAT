-- Decompilado por DeGOAT
-- Luau bytecode v9; tipos v3; opcodes roblox-mul227
-- Nomes semânticos exigem evidência; baixa confiança permanece como vN.
-- Trailer opaco preservado: 24 bytes (6821580643d9d27bb08b9957697b8ccc18394f725ae53207)

local Players = game:GetService("Players")
local v0 = {}
local v1 = {}
local module = {}
module.__index = module
-- função reconstruída: New
function module.New(arg1, arg2)
	-- upvalues: (copy) module, (copy) v1
	if arg1 <= 0 then
		error("[RateLimit]: Invalid rate")
	end
	local data = {}
	local v0 = {}
	data.sources = v0
	data.rate_period = (1.0 / arg1)
	data.is_full_wait = arg2 == true
	setmetatable(data, module)
	v1[data] = true
	return data
end
-- função reconstruída: CheckRate
function module.CheckRate(arg1, arg2)
	-- upvalues: (copy) v0
	local v1 = os.clock()
	if arg2 == nil then
		arg2 = "nil"
	end
	if arg1.sources[arg2] ~= nil then
		local v2 = arg1.sources[arg2]
		if arg1.is_full_wait ~= true then
			local v3 = math.max(v1, (v2 + arg1.rate_period))
			v2 = v3
			if (v2 - v1) < 1 then
				arg1.sources[arg2] = v2
				return true
			end
			return false
		end
		if v2 <= v1 then
			arg1.sources[arg2] = (v1 + arg1.rate_period)
			return true
		end
		return false
	end
	if typeof(arg2) == "Instance" then
		if arg2:IsA("Player") then
			if v0[arg2] == nil then
				return false
			end
		end
	end
	arg1.sources[arg2] = (v1 + arg1.rate_period)
	return true
end
-- função reconstruída: CleanSource
function module.CleanSource(arg1, arg2)
	arg1.sources[arg2] = nil
	return
end
-- função reconstruída: Cleanup
function module.Cleanup(arg1)
	local v0 = {}
	arg1.sources = v0
	return
end
-- função reconstruída: Destroy
function module.Destroy(arg1)
	-- upvalues: (copy) v1
	v1[arg1] = nil
	return
end
for key, value in ipairs(Players:GetPlayers()) do
	v0[value] = true
end
Players.PlayerAdded:Connect(function(arg1)
	-- upvalues: (copy) v0
	v0[arg1] = true
	return
end)
Players.PlayerRemoving:Connect(function(arg1)
	-- upvalues: (copy) v0, (copy) v1
	v0[arg1] = nil
	for value in pairs(v1) do
		value.sources[arg1] = nil
	end
	return
end)
return module
