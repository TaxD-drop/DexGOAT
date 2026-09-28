-- Decompilado por DeGOAT
-- Luau bytecode v9; tipos v3; opcodes roblox-mul227
-- Nomes semânticos exigem evidência; baixa confiança permanece como vN.
-- Trailer opaco preservado: 24 bytes (5050a90c38963b37fad2afe5d1556aba2048be786294c30d)

if not (game.Players.LocalPlayer.Character) then
	local character = game.Players.LocalPlayer.CharacterAdded:Wait()
end
for key, value in ipairs(workspace.Map:GetDescendants()) do
	if not (value:IsA("Part")) then continue end
	value.Material = Enum.Material.Wood
	wait()
end
return
