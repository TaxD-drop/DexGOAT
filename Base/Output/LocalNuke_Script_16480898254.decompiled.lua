-- Decompilado por DeGOAT
-- Luau bytecode v9; tipos v3; opcodes roblox-mul227
-- Nomes semânticos exigem evidência; baixa confiança permanece como vN.
-- Trailer opaco preservado: 24 bytes (58e2402da4d592ec7056851c974a26c028fa57596a262a2c)

local Root = script.Parent:WaitForChild("Root")
local Debris = game:GetService("Debris")
local BodyVelocity = Root:WaitForChild("BodyVelocity", 1)
local SoundModule = require(game.ReplicatedStorage.SoundModule)
local sound = SoundModule.newSound(script, "NukeAlarm")
sound.Looped = true
sound:Play()
local sound2 = SoundModule.newSound(Root, "NukeExplosion")
local TweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false, 0)
local tweenInfo2 = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, false, 0)
local Radius = script.Parent:WaitForChild("Radius")
local v0 = BodyVelocity:GetPropertyChangedSignal("Velocity")
local v1 = script.Parent
local v2 = Radius.Value
local player = game.Players.LocalPlayer
v0:Once(function()
	-- upvalues: (copy) sound, (copy) sound2, (copy) Root, (copy) v1, (copy) TweenService, (copy) tweenInfo, (copy) v2, (copy) tweenInfo2, (copy) player
	sound:Stop()
	sound2:Play()
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.Size = Vector3.new(1.0, 1.0, 1.0)
	part.Position = Root.Position
	local v0 = Color3.new(1, 0.701961, 0)
	part.Color = v0
	part.Material = Enum.Material.Neon
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Parent = v1
	local goal = {}
	goal.Size = ((Vector3.new(1.0, 1.0, 1.0) * v2) * 2.0)
	local tween = TweenService:Create(part, tweenInfo, goal)
	local goal2 = {["Transparency"] = 1.0}
	local tween2 = TweenService:Create(part, tweenInfo2, goal2)
	if player.Character then
		if (player.Character.HumanoidRootPart.Position - Root.Position).Magnitude < v1.Radius.Value then
			player.Character.UpperTorso:WaitForChild("BallSocketConstraint")
			local v3 = Vector3.new((30.0 - (29 * ((player.Character.HumanoidRootPart.Position - Root.Position).Magnitude / v1.Radius.Value))), 0, (30.0 - (29 * ((player.Character.HumanoidRootPart.Position - Root.Position).Magnitude / v1.Radius.Value))))
			local v4 = Vector3.new(0, (30.0 - (29 * ((player.Character.HumanoidRootPart.Position - Root.Position).Magnitude / v1.Radius.Value))), 0)
			player.Character.HumanoidRootPart:ApplyImpulse(((((player.Character.HumanoidRootPart.Position - Root.Position) * v3) + v4) * player.Character.HumanoidRootPart.AssemblyMass))
			wait()
			local v5 = Vector3.new((30.0 - (29 * ((player.Character.HumanoidRootPart.Position - Root.Position).Magnitude / v1.Radius.Value))), 0, (30.0 - (29 * ((player.Character.HumanoidRootPart.Position - Root.Position).Magnitude / v1.Radius.Value))))
			local v6 = Vector3.new(0, (30.0 - (29 * ((player.Character.HumanoidRootPart.Position - Root.Position).Magnitude / v1.Radius.Value))), 0)
			player.Character.HumanoidRootPart:ApplyImpulse(((((player.Character.HumanoidRootPart.Position - Root.Position) * v5) + v6) * player.Character.HumanoidRootPart.AssemblyMass))
		end
	end
	tween:Play()
	tween.Completed:Wait()
	tween2:Play()
	return
end)
Debris:AddItem(sound, 100)
return
