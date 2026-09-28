-- Decompilado por DeGOAT
-- Luau bytecode v9; tipos v3; opcodes roblox-mul227
-- Nomes semânticos exigem evidência; baixa confiança permanece como vN.
-- Trailer opaco preservado: 24 bytes (879cd23552df1a3b57514be29e294e16f784c541b558b834)

local Load = require(game.ReplicatedStorage.Load)
local Constants = Load("Constants")
if not (Constants.IS_TRADE_SERVER) then
	return
end
local MenuHandler = Load("MenuHandler")
local Network = Load("Network")
local TradeServer = workspace:WaitForChild("_TradeServer")
local PurchaseDisplays = TradeServer:WaitForChild("PurchaseDisplays")
local CraftingTables = TradeServer:WaitForChild("CraftingTables")
local BlackMarket = TradeServer:WaitForChild("BlackMarket")
if PurchaseDisplays:FindFirstChild("crate_smouldering") then
	PurchaseDisplays.crate_smouldering.Trigger.ProximityPrompt.Triggered:Connect(function()
		-- upvalues: (copy) Network
		Network:Fire("ShowCrateFrame", "crate_smouldering")
		return
	end)
end
if PurchaseDisplays:FindFirstChild("crate_gen_1") then
	PurchaseDisplays.crate_gen_1.ProximityPrompt.Triggered:Connect(function()
		-- upvalues: (copy) Network
		Network:Fire("ShowCrateFrame", "crate_gen_1")
		return
	end)
end
if PurchaseDisplays:FindFirstChild("space_crate") then
	PurchaseDisplays.space_crate.ProximityPrompt.Triggered:Connect(function()
		-- upvalues: (copy) Network
		Network:Fire("ShowCrateFrame", "space_crate")
		return
	end)
end
if PurchaseDisplays:FindFirstChild("pest_chest") then
	PurchaseDisplays.pest_chest.ProximityPrompt.Triggered:Connect(function()
		-- upvalues: (copy) Network
		Network:Fire("ShowCrateFrame", "pest_chest")
		return
	end)
end
if PurchaseDisplays:FindFirstChild("brass_strongbox") then
	PurchaseDisplays.brass_strongbox.ProximityPrompt.Triggered:Connect(function()
		-- upvalues: (copy) Network
		Network:Fire("ShowCrateFrame", "brass_strongbox")
		return
	end)
end
if PurchaseDisplays:FindFirstChild("mining_crate") then
	PurchaseDisplays.mining_crate.ProximityPrompt.Triggered:Connect(function()
		-- upvalues: (copy) Network
		Network:Fire("ShowCrateFrame", "mining_crate")
		return
	end)
end
for key, value in CraftingTables:GetChildren() do
	value.Attachment.ProximityPrompt.Triggered:Connect(function()
		-- upvalues: (copy) MenuHandler
		MenuHandler.OpenMenu("Crafting")
		return
	end)
end
if PurchaseDisplays:FindFirstChild("GiftCurrency") then
	PurchaseDisplays.GiftCurrency.PromptPart.ProximityPrompt.Triggered:Connect(function()
		-- upvalues: (copy) MenuHandler
		MenuHandler.OpenMenu("GiftCurrency")
		return
	end)
end
if PurchaseDisplays:FindFirstChild("GamepassVouchers") then
	PurchaseDisplays.GamepassVouchers.PromptPart.ProximityPrompt.Triggered:Connect(function()
		-- upvalues: (copy) MenuHandler
		MenuHandler.OpenSubmenu("Shop", "Consumables")
		return
	end)
end
for key2, value2 in BlackMarket.ItemDisplays:GetChildren() do
	value2.Lid.ProximityPrompt.Triggered:Connect(function()
		-- upvalues: (copy) Network, (copy) value2
		Network:Fire("ShowCrateFrame", value2.Name)
		return
	end)
end
PurchaseDisplays.TradingVIPPurchaseBoard.Proxy.ProximityPrompt.Triggered:Connect(function(arg1)
	-- upvalues: (copy) Network, (copy) PurchaseDisplays
	Network:Fire("PurchasePrompt", PurchaseDisplays.TradingVIPPurchaseBoard:GetAttribute("ItemID"))
	return
end)
PurchaseDisplays.TradingVIPPurchaseBoard2.Proxy.ProximityPrompt.Triggered:Connect(function(arg1)
	-- upvalues: (copy) Network, (copy) PurchaseDisplays
	Network:Fire("PurchasePrompt", PurchaseDisplays.TradingVIPPurchaseBoard:GetAttribute("ItemID"))
	return
end)
return
