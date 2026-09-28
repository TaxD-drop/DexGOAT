-- Decompilado por DeGOAT
-- Luau bytecode v9; tipos v3; opcodes roblox-mul227
-- Nomes semânticos exigem evidência; baixa confiança permanece como vN.
-- Trailer opaco preservado: 24 bytes (74dc48fde578ac46d6775f59ad48eac204c45f89461822fc)

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Load = require(ReplicatedStorage.Load)
local Promise = Load("Promise")
local Network = Load("Network")
local LocalPlayerHandler = Load("LocalPlayerHandler")
local Enums = Load("Enums")
local Constants = Load("Constants")
local Databases = Load("Databases")
Databases.init()
local v0 = Databases.Get("Achievements")
local CameraHandler = Load("CameraHandler")
local CoreUIHandler = Load("CoreUIHandler")
CoreUIHandler.init()
local GuiHandler = Load("GuiHandler")
GuiHandler.init()
local CrateFrameHandler = Load("CrateFrameHandler")
local CharacterHandler = Load("CharacterHandler")
local NotificationHandler = Load("NotificationHandler")
local ClientTimerHandler = Load("ClientTimerHandler")
local ClientCarryHandler = Load("ClientCarryHandler")
local ClientTrapHandler = Load("ClientTrapHandler")
local VFXHandler = Load("VFXHandler")
local MapVotingHandler = Load("MapVotingHandler")
local VisibilityHandler = Load("VisibilityHandler")
local ClientLockerHandler = Load("ClientLockerHandler")
local MenuHandler = Load("MenuHandler")
local HUDHandler = Load("HUDHandler")
local HUDPlayerListHandler = Load("HUDPlayerListHandler")
local StatsHandler = Load("StatsHandler")
local ProfileBannerHandler = Load("ProfileBannerHandler")
local DoorVFX = Load("DoorVFX")
local AudioHandler = Load("AudioHandler")
local KnifeInput = Load("KnifeInput")
local ClientCraftingHandler = Load("ClientCraftingHandler")
local ClientQuestsHandler = Load("ClientQuestsHandler")
local InventoryHandler = Load("InventoryHandler")
local ResetHandler = Load("ResetHandler")
local SettingsHandler = Load("SettingsHandler")
local ScreenFX = Load("ScreenFX")
local ClientChatHandler = Load("ClientChatHandler")
local SoundFX = Load("SoundFX")
local PlayersHandler = Load("PlayersHandler")
local CustomProximityPromptHandler = Load("CustomProximityPromptHandler")
local PlayerListHandler = Load("PlayerListHandler")
local PurchasePromptClient = Load("PurchasePromptClient")
local ClientShopHandler = Load("ClientShopHandler")
ClientShopHandler.init()
local ClientMapReplicator = Load("ClientMapReplicator")
local ClientCutsceneHandler = Load("ClientCutsceneHandler")
local ClientCutsceneReplicator = Load("ClientCutsceneReplicator")
local RagdollHandler = Load("RagdollHandler")
local WorldNotificationHandler = Load("WorldNotificationHandler")
local ExitVFXHandler = Load("ExitVFXHandler")
local SpectateHandler = Load("SpectateHandler")
local JoinFriendHandler = Load("JoinFriendHandler")
local GiftCurrencyHandler = Load("GiftCurrencyHandler")
GiftCurrencyHandler.init()
local v1 = nil
if Constants.IS_TRADE_SERVER then
	local v2 = GuiHandler.GetScreenGui("TopBar")
	v2.DailyObjectives.Visible = false
	local v3 = GuiHandler.GetFrame("RoundTimer")
	v3.Visible = false
	local ClientCabinHandler = Load("ClientCabinHandler")
	v1 = ClientCabinHandler
	v1.init(game.Workspace._TradeServer.Cabins:WaitForChild(Players.LocalPlayer.Name))
else
	local ClientDownHandler = Load("ClientDownHandler")
	local CodeHandler = Load("CodeHandler")
	local ClientLeaderboardHandler = Load("ClientLeaderboardHandler")
	local ClientRouletteHandler = Load("ClientRouletteHandler")
	local ClientRouletteReplicator = Load("ClientRouletteReplicator")
	local ClientCabinHandler2 = Load("ClientCabinHandler")
	v1 = ClientCabinHandler2
	v1.init(game.Workspace._Lobby.Cabins:WaitForChild(Players.LocalPlayer.Name))
	local ClientObjectivesHandler = Load("ClientObjectivesHandler")
	local RoundResultsHandler = Load("RoundResultsHandler")
	local SignDisplayHandler = Load("SignDisplayHandler")
end
local FuseHandlerClient = Load("FuseHandlerClient")
local TradeHandlerClient = Load("TradeHandlerClient")
local TextChatHandler = Load("TextChatHandler")
local Settings = Players.LocalPlayer:WaitForChild("Settings")
-- função reconstruída: WaitForServerReady
local player = Players.LocalPlayer
-- função reconstruída: WaitForPlayerReady
-- função reconstruída: WaitForCharacterReady
-- função reconstruída: ClientIsReady
-- função reconstruída: InitHumanoidListeners
local v4 = nil
local v5 = nil
local v6 = nil
-- função reconstruída: main
local module = {}
-- função reconstruída: character_spawned
function module.character_spawned(arg1)
	-- upvalues: (copy) CharacterHandler, (copy) CameraHandler
	CharacterHandler.NewCharacter(arg1)
	CameraHandler.init()
	local v0 = CharacterHandler.GetHumanoid()
	return
end
-- função reconstruída: player_died
function module.player_died(arg1)
	-- upvalues: (copy) CameraHandler
	CameraHandler.Stop()
	return
end
-- função reconstruída: trade_proximity_prompt
function module.trade_proximity_prompt(arg1)
	arg1.Enabled = false
	return
end
module.InitSettings = SettingsHandler.StoreSettings
module.UpdatePlayerSetting = SettingsHandler.UpdateSetting
-- função reconstruída: CabinSpawned
function module.CabinSpawned(arg1)
	-- upvalues: (ref) v1
	v1.init(arg1)
	return
end
module.PopulateAchievements = v0.Populate
-- função reconstruída: PlayerAdded
function module.PlayerAdded(arg1)
	-- upvalues: (copy) player, (copy) PlayerListHandler
	if arg1 ~= player then
		PlayerListHandler.AddPlayer(arg1)
	end
	return
end
Network:BindEvents(module)
local RunService = game:GetService("RunService")
if not (RunService:IsStudio()) then
	task.wait(3)
end
;(function()
	-- upvalues: (copy) Network, (copy) HUDHandler, (ref) v4, (copy) Load, (ref) v5, (copy) player, (copy) Constants, (copy) AudioHandler, (copy) SoundFX, (copy) Settings, (copy) Players, (copy) PlayerListHandler, (ref) v6, (copy) ClientTimerHandler, (copy) Workspace, (copy) GuiHandler
	Network:FireServer("PopulateAchievements")
	HUDHandler.UpdateValues()
	local v0 = Load("ClientLootHandler")
	v4 = v0
	local v1 = Load("ClientMovementHandler")
	v5 = v1
	local v2 = workspace:GetAttributeChangedSignal("ExitsOpen")
	v2:Connect(function()
		-- upvalues: (ref) player, (ref) Constants, (ref) AudioHandler
		if workspace:GetAttribute("ExitsOpen") then
			if player.Team.Name == Constants.TEAMS.Lobby.name then
				if not (player:GetAttribute("SpectatingPlayer")) then return end
			end
			AudioHandler.PlayAmbientMusic(false)
			AudioHandler.PlayEscapeMusic(true)
		end
		return
	end)
	local v3 = workspace:GetAttributeChangedSignal("Map")
	v3:Connect(function()
		-- upvalues: (ref) Constants, (ref) AudioHandler
		local v0 = workspace:GetAttribute("Map")
		local v1 = "default"
		if Constants.MAP_SETTINGS[v0] ~= nil then
			if Constants.MAP_SETTINGS[v0].GameMusic ~= nil then
				v1 = Constants.MAP_SETTINGS[v0].GameMusic
			end
		end
		AudioHandler.SetAmbientMusic(v1)
		return
	end)
	-- função reconstruída: setMusicForCurrentTeam
	;(function()
		-- upvalues: (ref) player, (ref) Constants, (ref) AudioHandler, (ref) SoundFX
		if player.Team.Name == Constants.TEAMS.Survivor.name then
			AudioHandler.PlayLobbyMusic(false)
			AudioHandler.PlayAmbientMusic(true)
			return
		end
		if player.Team.Name == Constants.TEAMS.Killer.name then
			AudioHandler.PlayLobbyMusic(false)
			AudioHandler.PlayAmbientMusic(true)
			return
		end
		AudioHandler.PlayAmbientMusic(false)
		AudioHandler.PlayEscapeMusic(false)
		task.wait(1)
		if player:GetAttribute("Escaped") then
			SoundFX.PlaySound("Escaped")
			task.delay(10, function()
				-- upvalues: (ref) AudioHandler
				AudioHandler.PlayLobbyMusic(true)
				return
			end)
			return
		end
		AudioHandler.PlayLobbyMusic(true)
		return
	end)()
	local v7 = player:GetPropertyChangedSignal("Team")
	v7:Connect(function()
		-- upvalues: (ref) player, (ref) Constants, (ref) AudioHandler, (ref) SoundFX
		if player.Team.Name == Constants.TEAMS.Survivor.name then
			AudioHandler.PlayLobbyMusic(false)
			AudioHandler.PlayAmbientMusic(true)
			return
		end
		if player.Team.Name == Constants.TEAMS.Killer.name then
			AudioHandler.PlayLobbyMusic(false)
			AudioHandler.PlayAmbientMusic(true)
			return
		end
		AudioHandler.PlayAmbientMusic(false)
		AudioHandler.PlayEscapeMusic(false)
		task.wait(1)
		if player:GetAttribute("Escaped") then
			SoundFX.PlaySound("Escaped")
			task.delay(10, function()
				-- upvalues: (ref) AudioHandler
				AudioHandler.PlayLobbyMusic(true)
				return
			end)
			return
		end
		AudioHandler.PlayLobbyMusic(true)
		return
	end)
	local v8 = player:GetAttributeChangedSignal("SpectatingPlayer")
	v8:Connect(function()
		-- upvalues: (ref) player, (ref) AudioHandler
		if player:GetAttribute("SpectatingPlayer") then
			if not (workspace:GetAttribute("ExitsOpen")) then
				AudioHandler.PlayLobbyMusic(false)
				AudioHandler.PlayAmbientMusic(true)
				AudioHandler.PlayEscapeMusic(false)
				return
			end
		end
		if player:GetAttribute("SpectatingPlayer") then
			if workspace:GetAttribute("ExitsOpen") then
				if AudioHandler.GetEscapeMusic() then
					local v0 = AudioHandler.GetEscapeMusic()
					if not (v0.Playing) then
						AudioHandler.PlayLobbyMusic(false)
						AudioHandler.PlayAmbientMusic(false)
						AudioHandler.PlayEscapeMusic(true)
						return
					end
				end
			end
		end
		if not (player:GetAttribute("SpectatingPlayer")) then
			AudioHandler.PlayLobbyMusic(true)
			AudioHandler.PlayAmbientMusic(false)
			AudioHandler.PlayEscapeMusic(false)
		end
		return
	end)
	local v9 = player:GetAttributeChangedSignal("ResetEnabled")
	v9:Connect(function()
		-- upvalues: (ref) player
		game.StarterGui:SetCore("ResetButtonCallback", player:GetAttribute("ResetEnabled"))
		return
	end)
	local v10 = Settings:GetAttributeChangedSignal("lobby_ambient")
	v10:Connect(function()
		-- upvalues: (ref) AudioHandler, (ref) Settings
		AudioHandler.SetSoundGroupEnabled("lobby_ambient", Settings:GetAttribute("lobby_ambient"))
		return
	end)
	local v11 = Settings:GetAttributeChangedSignal("lobby_music")
	v11:Connect(function()
		-- upvalues: (ref) AudioHandler, (ref) Settings
		AudioHandler.SetSoundGroupEnabled("lobby_music", Settings:GetAttribute("lobby_music"))
		return
	end)
	local v12 = Settings:GetAttributeChangedSignal("game_music")
	v12:Connect(function()
		-- upvalues: (ref) AudioHandler, (ref) Settings
		AudioHandler.SetSoundGroupEnabled("game_music", Settings:GetAttribute("game_music"))
		return
	end)
	local v13 = Settings:GetAttributeChangedSignal("game_escape_music")
	v13:Connect(function()
		-- upvalues: (ref) AudioHandler, (ref) Settings
		AudioHandler.SetSoundGroupEnabled("game_escape_music", Settings:GetAttribute("game_escape_music"))
		return
	end)
	local v14 = Settings:GetAttributeChangedSignal("escape_music")
	v14:Connect(function()
		-- upvalues: (ref) AudioHandler, (ref) Settings
		AudioHandler.SetEscapeMusic(Settings:GetAttribute("escape_music"))
		return
	end)
	for key, value in Players:GetPlayers() do
		PlayerListHandler.AddPlayer(value)
	end
	Players.PlayerRemoving:Connect(function(arg1)
		-- upvalues: (ref) PlayerListHandler
		PlayerListHandler.RemovePlayer(arg1)
		return
	end)
	local v15 = Load("DailyRewards")
	v6 = v15
	ClientTimerHandler.ToggleTimer()
	local v16 = ClientTimerHandler.ToggleTimer
	if Constants.IS_TRADE_SERVER then
		v16 = Workspace
		v16 = v16:WaitForChild("_TradeServer")
	else
		v16 = Workspace
		v16 = v16:WaitForChild("_Lobby")
	end
	if Constants.IS_MOBILE then
		pcall(function()
			-- upvalues: (copy) v16
			for key, value in v16.Trees:GetDescendants() do
				if not (value:IsA("BasePart")) then continue end
				value.CastShadow = false
			end
			return
		end)
	end
	local v17 = GuiHandler.GetScreenGui("Priority")
	local v18 = workspace:GetAttribute("ServerVersion")
	v17.ServerVersion.Text = v18
	return
end)()
return
