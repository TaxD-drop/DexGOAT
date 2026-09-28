-- Decompilado por DeGOAT
-- Luau bytecode v9; tipos v3; opcodes roblox-mul227
-- Nomes semânticos exigem evidência; baixa confiança permanece como vN.
-- Trailer opaco preservado: 24 bytes (cba4350bc2fdb1a1813b65c5a400e9e5bbbc227ff9605f0a)

local module = {}
-- função reconstruída: pickTarget
function module.pickTarget(arg1, arg2)
	-- upvalues: (copy) module
	local v0 = {}
	for key, value in ipairs(game.Players:GetChildren()) do
		if not (value.Character) then continue end
		if 0 >= value.Character.Humanoid.Health then continue end
		if value.Character.Humanoid.FloorMaterial == Enum.Material.Air then continue end
		table.insert(v0, value.Character)
	end
	if not (arg2) then
		if #v0 < 1 then
			arg1.Value = nil
			return
		end
		local v1 = math.random(1, #v0)
		arg1.Value = v0[v1]
	else
		arg1.Value = arg2
	end
	local v2 = nil
	local v3 = nil
	local v4 = arg1.Value.Humanoid.Died:Connect(function()
		-- upvalues: (ref) v2, (ref) v3, (ref) module, (copy) arg1
		v2:Disconnect()
		if v3 then
			v3:Disconnect()
		end
		module.pickTarget(arg1)
		return
	end)
	if arg1.Value:FindFirstChild("DecoyEvent") then
		local v5 = arg1.Value:FindFirstChild("DecoyEvent").Event:Connect(function(arg12)
			-- upvalues: (ref) v3, (ref) module, (copy) arg1
			v3:Disconnect()
			module.pickTarget(arg1, arg12)
			return
		end)
	end
	return arg1.Value:FindFirstChild("HumanoidRootPart")
end
return module
