-- Decompilado por DeGOAT
-- Luau bytecode v9; tipos v3; opcodes roblox-mul227
-- Nomes semânticos exigem evidência; baixa confiança permanece como vN.
-- Trailer opaco preservado: 24 bytes (4eb16be96e5e1e54c1732697356825f93ea97c9d7c7501e8)

local module = {}
local Debris = game:GetService("Debris")
local v0 = game.ReplicatedStorage.Events.RagdollEvent
-- função reconstruída: explode
function module.explode(arg1, arg2, arg3, arg4)
	-- upvalues: (copy) Debris, (copy) v0
	if not (arg4) then
		arg4 = 500000.0
	end
	local explosion = Instance.new("Explosion")
	explosion.BlastRadius = arg3
	explosion.BlastPressure = arg4
	explosion.Position = arg2
	game.ServerStorage.Events.MakeCrater:Fire(arg2, arg3)
	explosion.Hit:Connect(function(arg12, arg22)
		-- upvalues: (ref) Debris, (copy) arg1, (ref) v0, (copy) arg2
		if arg12:IsDescendantOf(workspace.Map.Buildings) then
			local v1 = math.random()
			Debris:AddItem(arg12, (v1 * 10.0))
			return
		end
		if not (arg12.Parent) then
			return
		end
		if arg1 then
			if arg1.Name ~= arg12.Parent.Name then
				return
			end
		end
		if arg12.Parent == script.Parent.Parent then
			return
		end
		local Humanoid = arg12.Parent:FindFirstChild("Humanoid")
		local UpperTorso = arg12.Parent:FindFirstChild("UpperTorso")
		if Humanoid then
			if UpperTorso then
				if not (UpperTorso:FindFirstChildWhichIsA("BodyForce")) then
					if arg1 then
						game.ServerScriptService.CubeHandler.Hit:Fire(arg1, "char", arg12.Position)
					end
					local Size = arg12.Parent:FindFirstChild("Size")
					if Size then
						if arg12.Parent:FindFirstChild("LastHurtBy") then
							if arg1 then
								local v2 = arg12.Parent
								arg12.Parent:FindFirstChild("LastHurtBy").Value = arg1
							end
						end
						if arg1 then
							game.ReplicatedStorage.Events.DamageIndicator:FireClient(arg1, arg12, 50)
						end
						Humanoid.Health = (Humanoid.Health - 50)
						if 30 <= 50 then
							if game.Players:FindFirstChild(v2.Name) then
								local v3 = game.Players:FindFirstChild(v2.Name)
								v0:Fire(v3, 2)
							else
								v0:Fire(v2, 5)
							end
						end
					end
					local bodyForce = Instance.new("BodyForce")
					local v4 = CFrame.new(arg2, v2.UpperTorso.Position)
					local v5 = Vector3.new((500.0 / arg22), 0, (500.0 / arg22))
					local v6 = Vector3.new(0, ((500.0 / arg22) * 10.0), 0)
					bodyForce.Force = ((v4.LookVector * v5) + v6)
					bodyForce.Parent = v2.UpperTorso
					Debris:AddItem(bodyForce, 0.1)
				end
			end
		end
		return
	end)
	return
end
return module
