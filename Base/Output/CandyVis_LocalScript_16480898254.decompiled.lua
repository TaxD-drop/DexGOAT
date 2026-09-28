-- Decompilado por DeGOAT
-- Luau bytecode v9; tipos v3; opcodes roblox-mul227
-- Nomes semânticos exigem evidência; baixa confiança permanece como vN.
-- Trailer opaco preservado: 24 bytes (928975918f44ac2fa317af7c98b0bb6ee29162e5a04d1f90)

local TweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, false, 0)
local tweenInfo2 = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)
local tweenInfo3 = TweenInfo.new(0.15, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut, -1, true, 0)
local tweenInfo4 = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0)
local items = {}
local v0 = {}
local attachment = Instance.new("Attachment")
attachment.Name = "CubeSpin"
attachment.Position = Vector3.new(0.0, -0.5, 0.0)
local CubeSpin = workspace:WaitForChild("CubeSpin")
attachment.Parent = CubeSpin
local goal = {["Orientation"] = Vector3.new(0.0, 359.0, 0.0)}
local tween = TweenService:Create(attachment, tweenInfo, goal)
local goal2 = {["Position"] = Vector3.new(0.0, -1.5, 0.0)}
local tween2 = TweenService:Create(attachment, tweenInfo4, goal2)
tween:Play()
tween2:Play()
local SoundModule = require(game.ReplicatedStorage.SoundModule)
local sound = SoundModule.newSound(script, "Candy")
local character = game.Players.LocalPlayer.Character
if not (character) then
	character = game.Players.LocalPlayer.CharacterAdded
	character = character:Wait()
end
local rootPart = nil
-- função reconstruída: loadChar
loadChar = function()
	-- upvalues: (ref) rootPart, (ref) character
	local rootPart2 = character:WaitForChild("HumanoidRootPart")
	rootPart = rootPart2
	return
end
game.Players.LocalPlayer.CharacterAdded:Connect(function(arg1)
	-- upvalues: (ref) character
	character = arg1
	loadChar()
	return
end)
loadChar()
local player = game.Players.LocalPlayer
game.Workspace.ChildAdded:Connect(function(arg1)
	-- upvalues: (copy) player, (copy) TweenService, (copy) tweenInfo2, (copy) tweenInfo3, (ref) rootPart, (copy) sound, (copy) items
	if arg1.Name == "Candy" then
		arg1:WaitForChild("Owner")
		arg1:WaitForChild("TimeLeft")
		arg1:WaitForChild("Visual")
		if (arg1.Owner.Value == "") or (arg1.Owner.Value == player.Name) then
			arg1.Visual.Transparency = 0
			arg1.Visual.Decal.Transparency = 0
			enableParticles(arg1.Visual, true)
			local originalSize = arg1.Visual.Size
			arg1.Visual.Size = (arg1.Visual.Size / 10.0)
			local goal = {}
			goal.Size = originalSize
			local tween = TweenService:Create(arg1.Visual, tweenInfo2, goal)
			local goal2 = {["Transparency"] = 1.0}
			local tween2 = TweenService:Create(arg1.Visual, tweenInfo3, goal2)
			local goal3 = {["Transparency"] = 1.0}
			local tween3 = TweenService:Create(arg1.Visual.Decal, tweenInfo3, goal3)
			tween:Play()
			arg1.TimeLeft.Changed:Connect(function(arg12)
				-- upvalues: (ref) rootPart, (copy) arg1, (ref) sound, (copy) tween2, (copy) tween3
				if arg12 == -1.0 then
					if arg12 == -1.0 then
						if rootPart then
							if (rootPart.Position - arg1.Position).Magnitude < rootPart.Size.Magnitude then
								sound:Play()
							end
						end
					end
				end
				if arg12 == 3.0 then
					tween2:Play()
					tween3:Play()
					if not ((arg1) and (arg1:FindFirstChild("Visual"))) then return end
					enableParticles(arg1.Visual, false)
				end
				return
			end)
			table.insert(items, arg1)
			return
		end
	end
	if string.find(arg1.Name, "Pickup") then
		arg1:WaitForChild("Owner")
		arg1:WaitForChild("TimeLeft")
		arg1:WaitForChild("Visual")
		if (arg1.Owner.Value == "") or (arg1.Owner.Value == player.Name) then
			arg1.Visual.Transparency = 0
			enableParticles(arg1.Visual, true)
			local originalSize2 = arg1.Visual.Size
			arg1.Visual.Size = (arg1.Visual.Size / 10.0)
			local goal4 = {}
			goal4.Size = originalSize2
			local tween4 = TweenService:Create(arg1.Visual, tweenInfo2, goal4)
			local goal5 = {["Transparency"] = 1.0}
			local tween5 = TweenService:Create(arg1.Visual, tweenInfo3, goal5)
			tween4:Play()
			arg1.TimeLeft.Changed:Connect(function(arg12)
				-- upvalues: (copy) tween5, (copy) arg1
				if arg12 == 3.0 then
					tween5:Play()
					if not ((arg1) and (arg1:FindFirstChild("Visual"))) then return end
					enableParticles(arg1.Visual, false)
				end
				return
			end)
			table.insert(items, arg1)
		end
	end
	return
end)
-- função reconstruída: enableParticles
enableParticles = function(arg1, arg2)
	for key, value in ipairs(arg1:GetChildren()) do
		if not (value:IsA("Attachment")) then continue end
		if value.Name == "Pickup" then continue end
		for key2, value2 in ipairs(value:GetChildren()) do
			if not (value2:IsA("ParticleEmitter")) then continue end
			value2.Enabled = arg2
		end
	end
	return
end
game["Run Service"].RenderStepped:Connect(function()
	-- upvalues: (copy) items, (copy) attachment
	for key, value in ipairs(items) do
		if value then
			if not (value:FindFirstChild("Weld")) then
				table.remove(items, key)
				continue
			end
			value.Weld.C0 = attachment.CFrame
		else
			table.remove(items, key)
		end
	end
	return
end)
return
