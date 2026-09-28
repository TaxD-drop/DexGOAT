-- Decompilado por DeGOAT
-- Luau bytecode v9; tipos v3; opcodes roblox-mul227
-- Nomes semânticos exigem evidência; baixa confiança permanece como vN.
-- Trailer opaco preservado: 24 bytes (f66458c3786c36af70945bc6641dc772867c4fb7c4a032c2)

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local SoundModule = require(game.ReplicatedStorage.SoundModule)
local module = {}
-- função reconstruída: IsRagdolled
function module.IsRagdolled(arg1)
	if arg1:FindFirstChild("LowerTorso") then
		if arg1.LowerTorso:FindFirstChildWhichIsA("BallSocketConstraint") then
			return true
		end
	end
	return false
end
-- função reconstruída: CanAffect
function module.CanAffect(arg1)
	if (arg1 == nil) or (arg1.Parent == nil) then
		return false
	end
	if not (arg1:IsA("BasePart")) then
		return false
	end
	if arg1.Parent.Parent then
		if arg1.Parent.Parent:FindFirstChild("UpperTorso") then
			arg1 = arg1.Parent.Parent.UpperTorso
		end
	end
	if arg1.Parent:FindFirstChild("Humanoid") then
		if not (arg1.Parent:FindFirstChild("UpperTorso")) then
			return false
		end
		if arg1.Parent:FindFirstChild("HumanoidRootPart") then
			if arg1.Parent:FindFirstChild("HumanoidRootPart").Anchored then
				return false
			end
		end
		if not (arg1.Parent.UpperTorso:FindFirstChild("AlignPosition")) then
			if not (arg1.Parent.Humanoid.PlatformStand) then
				if game.Players:FindFirstChild(arg1.Parent.Name) then
					if arg1.Parent:FindFirstChild("HipHeight") then
						if 5 < arg1.Parent.HipHeight.Value then return false end
					end
				end
				return true
			end
		end
		return false
	end
	if not (arg1:FindFirstChild("AlignPosition")) then
		if arg1.Mass >= arg1.AssemblyMass then
			if not (arg1.Anchored) then
				if not (arg1:IsGrounded()) then return true end
			end
		end
	end
	return false
end
-- função reconstruída: IsCar
function module.IsCar(arg1)
	if (not (arg1)) or (not (arg1.Parent)) then
		return nil
	end
	local v0 = arg1:FindFirstAncestor("Car")
	return v0
end
-- função reconstruída: CanDebris
function module.CanDebris(arg1)
	-- upvalues: (copy) Debris, (copy) module
	if (arg1 == nil) or (arg1.Parent == nil) then
		return true
	end
	if arg1:FindFirstChild("HingeAttachment") then
		arg1.HingeAttachment:Destroy()
	end
	if arg1.Parent.Name == "Window" then
		Debris:AddItem(arg1.Parent, 10)
		return true
	end
	if not (arg1:FindFirstChild("HoldAttachment")) then
		if not (arg1.Parent:FindFirstChild("ForceField")) then
			if not (arg1.Parent:FindFirstChild("Humanoid")) then
				if not (arg1.Parent.Parent:FindFirstChild("Humanoid")) then
					if not (arg1.Anchored) then
						if arg1.CanCollide then
							if 0.9 >= arg1.Transparency then
								if module.IsCar(arg1) then
									return false
								end
								return true
							end
							if arg1.Parent.Name == "Window" then
								if module.IsCar(arg1) then
									return false
								end
								return true
							end
						end
					end
				end
			end
		end
	end
	return false
end
-- função reconstruída: CanDestroy
function module.CanDestroy(arg1)
	-- upvalues: (copy) module, (copy) Players
	if module.IsPickup(arg1) then
		return false
	end
	if module.IsMeteorite(arg1) then
		return false
	end
	if arg1.Parent == nil then
		return true
	end
	if arg1:FindFirstChild("ForceField") then
		if arg1.Name == "Sticky Bomb" then
			if arg1:IsGrounded() then
				if Players:GetPlayerFromCharacter(arg1.Parent) then
					return false
				end
				if arg1.Parent.Parent == nil then
					return true
				end
				if arg1.Parent.Name == "KnightNPC" then
					return false
				end
				if arg1.Parent.Parent.Name == "KnightNPC" then
					return false
				end
				if arg1.Parent.Parent then
					if arg1.Parent.Parent:FindFirstChild("Humanoid") then
						if Players:GetPlayerFromCharacter(arg1.Parent.Parent) then
							return false
						end
					end
				end
				if module.IsCar(arg1) then
					return false
				end
				return true
			end
			local v0 = arg1:GetMass()
			if v0 == arg1.AssemblyMass then
				if Players:GetPlayerFromCharacter(arg1.Parent) then
					return false
				end
				if arg1.Parent.Parent == nil then
					return true
				end
				if arg1.Parent.Name == "KnightNPC" then
					return false
				end
				if arg1.Parent.Parent.Name == "KnightNPC" then
					return false
				end
				if arg1.Parent.Parent then
					if arg1.Parent.Parent:FindFirstChild("Humanoid") then
						if Players:GetPlayerFromCharacter(arg1.Parent.Parent) then
							return false
						end
					end
				end
				if module.IsCar(arg1) then
					return false
				end
				return true
			end
		end
		return false
	end
	if Players:GetPlayerFromCharacter(arg1.Parent) then
		return false
	end
	if arg1.Parent.Parent == nil then
		return true
	end
	if arg1.Parent.Name == "KnightNPC" then
		return false
	end
	if arg1.Parent.Parent.Name == "KnightNPC" then
		return false
	end
	if arg1.Parent.Parent then
		if arg1.Parent.Parent:FindFirstChild("Humanoid") then
			if Players:GetPlayerFromCharacter(arg1.Parent.Parent) then
				return false
			end
		end
	end
	if module.IsCar(arg1) then
		return false
	end
	return true
end
-- função reconstruída: IsPickup
function module.IsPickup(arg1)
	if not (arg1) then
		return false
	end
	if arg1.Name ~= "Gem" then
		if arg1.Name ~= "Visual" then
			if arg1.Name ~= "ForceField" then
				if arg1.Name ~= "GemEdge" then
					if not (string.find(arg1.Name, "Pickup")) then return false end
				end
			end
		end
	end
	return true
end
-- função reconstruída: IsMeteorite
function module.IsMeteorite(arg1)
	if not (arg1) then
		return nil
	end
	if not (arg1.Parent) then
		return nil
	end
	if arg1.Parent.Name == "Meteorite" then
		return arg1.Parent
	end
	if arg1.Name == "Meteorite" then
		return arg1
	end
	return nil
end
-- função reconstruída: DamageMeteorite
function module.DamageMeteorite(arg1, arg2)
	-- upvalues: (copy) module
	if module.IsMeteorite(arg1) then
		module.IsMeteorite(arg1).MeteoriteScript.Health.Value = (module.IsMeteorite(arg1).MeteoriteScript.Health.Value - arg2)
	end
	return
end
-- função reconstruída: Interact
function module.Interact(arg1, arg2, arg3)
	if arg1.Name == "Barrel" then
		if arg1:FindFirstChild("ImpactScript") then
			if arg1.ImpactScript.Disabled == true then
				arg1.ImpactScript.DontHit.Value = arg2
				if arg2:FindFirstChild("HumanoidRootPart") then
					arg1.ImpactScript.Direction.Value = arg2.HumanoidRootPart.CFrame.LookVector
				end
				arg1.ImpactScript.Power.Value = -1
				arg1.ImpactScript.Disabled = false
				return true
			end
		end
	end
	if arg1.Parent then
		if (arg1.Parent.Name == "Car") or (arg1.Parent.Parent.Name == "Car") then
			if arg1.Parent.Parent.Name == "Car" then
				arg1 = arg1.Parent
			end
			if arg1.Parent.Cooldown.Value then
				return false
			end
			arg1.Parent.Cooldown.Value = true
			spawn(function()
				-- upvalues: (ref) arg1
				wait(1)
				arg1.Parent.Cooldown.Value = false
				return
			end)
			if arg3 then
				arg1.Parent.Health.Value = (arg1.Parent.Health.Value - arg3)
			else
				arg1.Parent.Health.Value = (arg1.Parent.Health.Value - 50.0)
			end
			return true
		end
	end
	return false
end
-- função reconstruída: CanFight
function module.CanFight(arg1, arg2)
	return (arg1.Preferences.pvp.Value and arg2.Preferences.pvp.Value)
end
-- função reconstruída: canGrabPlayer
function module.canGrabPlayer(arg1, arg2)
	return
end
local v0 = game.ServerStorage.Events.QuestEvent
local v1 = game.ServerScriptService.GemHandler.Hit
local v2 = game.ReplicatedStorage.Events.RagdollEvent
-- função reconstruída: Explode
function module.Explode(arg1, arg2, arg3, arg4, arg5)
	-- upvalues: (copy) SoundModule, (copy) module, (copy) Debris, (copy) v0, (copy) v1, (copy) Players, (copy) v2
	local sound = SoundModule.newSound(arg1, "Explosion")
	sound:Play()
	DangerEvent:Fire(arg1.Position, 40)
	local explosion = Instance.new("Explosion")
	explosion.Visible = not (arg5)
	explosion.Parent = arg1
	explosion.BlastRadius = (arg3 or 15.0)
	explosion.Position = arg1.Position
	local v3 = 2
	if arg1.Name == "Snow Missile" then
		v3 = 0.8
	end
	explosion.Hit:Connect(function(arg12, arg22)
		-- upvalues: (ref) module, (copy) arg2, (ref) Debris, (ref) v0, (ref) v1, (ref) Players, (ref) v2, (ref) v3, (copy) arg1
		if arg12.Parent then
			if not (arg12.Parent:FindFirstChild("Humanoid")) then
				if not ((not (arg12.Parent.Parent:FindFirstChild("Humanoid"))) and (not (arg12.Anchored))) then return end
				module.Interact(arg12, arg2.Character)
				if not (module.CanDebris(arg12)) then return end
				if arg12.Material == Enum.Material.Sand then return end
				Debris:AddItem(arg12, 10)
				local v4 = {}
				v4[2] = "Explosive"
				v4[3] = "Bricks"
				v0:Fire(arg2, v4, 1)
				v1:Fire(arg2, "brick", arg12.Position)
				return
			end
			if not (arg12.Parent.UpperTorso:FindFirstChildWhichIsA("BodyForce")) then
				v1:Fire(arg2, "char", arg12.Position)
				if Players:FindFirstChild(arg12.Parent.Name) then
					local v5 = Players:FindFirstChild(arg12.Parent.Name)
					v2:Fire(v5, v3)
					local v6 = {}
					v6[2] = "Explosive"
					v6[3] = "Player"
					v0:Fire(arg2, v6, 1)
				else
					v2:Fire(arg12.Parent, 5)
					local v7 = {}
					v7[2] = "Explosive"
					v7[3] = "NPC"
					v0:Fire(arg2, v7, 1)
				end
				local bodyForce = Instance.new("BodyForce")
				local v8 = CFrame.new(arg1.Position, arg12.Parent.UpperTorso.Position)
				local v9 = Vector3.new((500.0 / arg22), 0, (500.0 / arg22))
				local v10 = Vector3.new(0, ((500.0 / arg22) * 10.0), 0)
				bodyForce.Force = ((v8.LookVector * v9) + v10)
				bodyForce.Parent = arg12.Parent.UpperTorso
				Debris:AddItem(bodyForce, 0.1)
			end
		end
		return
	end)
	return
end
return module
