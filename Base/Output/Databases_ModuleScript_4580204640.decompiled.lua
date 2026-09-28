-- Decompilado por DeGOAT
-- Luau bytecode v9; tipos v3; opcodes roblox-mul227
-- Nomes semânticos exigem evidência; baixa confiança permanece como vN.
-- Trailer opaco preservado: 24 bytes (6bc64cdae555dd9ea2d7ae00e070ca3e1bde5bae590226db)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Load = require(ReplicatedStorage.Load)
local Constants = Load("Constants")
local Promise = Load("Promise")
local module = {}
local v0 = {}
local v1 = false
local v2 = ReplicatedStorage.Assets.Game
-- função reconstruída: init
function module.init()
	-- upvalues: (ref) v1, (copy) v0, (copy) v2, (copy) module
	if v1 then
		return
	end
	local v3 = {}
	v0.All = v3
	local v4 = {}
	v0.Purchasable = v4
	for key, value in pairs(game.ReplicatedStorage.ItemDatabases:GetChildren()) do
		local v5 = require(value)
		v0[value.Name] = v5
		if not (value:GetAttribute("Type")) then
			error(value.Name .. " is missing a Type attribute")
		end
		local v6 = v2:FindFirstChild(value.Name)
		for key2, value2 in pairs(v0[value.Name]) do
			if type(value2) == "function" then continue end
			if key2 == "@Me" then continue end
			if key2 == "!Random" then continue end
			if v6 then
				if v6:FindFirstChild(key2) then
					value2.Object = v6:FindFirstChild(key2)
				else
					error("Object not found for '" .. key2 .. "'")
				end
			end
			value2._ID = key2
			value2.Type = value:GetAttribute("Type")
			if (value:GetAttribute("Type") == "Killer") or (value:GetAttribute("Type") == "Knife") or (value:GetAttribute("Type") == "Cabin") or (value:GetAttribute("Type") == "Loot") or (value:GetAttribute("Type") == "Title") or (value:GetAttribute("Type") == "Consumable") or (value:GetAttribute("Type") == "Recipe") or (value:GetAttribute("Type") == "ProfileBanner") then
				v0.All[key2] = value2
			end
			if (value2.CoinPrice) or (value2.GemPrice) or (value2.RobuxPrice) or (value2.LimitedType) then
				v0.Purchasable[key2] = value2
			end
		end
	end
	module._validateDatabase()
	v1 = true
	return
end
-- função reconstruída: Get
function module.Get(arg1)
	-- upvalues: (ref) v1, (copy) v0
	if v1 == false then
		repeat
			task.wait()
		until v1 == true
	end
	if v0[arg1] then
		return v0[arg1]
	end
	error("Tried to retieve non-existent database: " .. arg1)
	return
end
-- função reconstruída: _validateDatabase
function module._validateDatabase()
	-- upvalues: (copy) v0, (copy) Constants
	for key, value in pairs(Constants.InvalidIDs) do
		if not (v0.All[key]) then continue end
		error("Invalid key found in database - remove to avoid data loss")
	end
	return
end
return module
