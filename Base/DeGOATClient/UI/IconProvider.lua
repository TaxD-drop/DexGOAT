local IconProvider = {}
IconProvider.__index = IconProvider

local FILES = {
	Workspace = "Workspace.png",
	Players = "Players.png",
	CoreGui = "CoreGui.png",
	Lighting = "Lighting.png",
	MaterialService = "MaterialService.png",
	ReplicatedFirst = "ReplicatedFirst.png",
	ReplicatedStorage = "ReplicatedStorage.png",
	ServerScriptService = "ServerScriptService.png",
	ServerStorage = "ServerStorage.png",
	StarterGui = "StarterGui.png",
	StarterPack = "StarterPack.png",
	StarterPlayer = "StarterPlayer.png",
	Teams = "Teams.png",
	SoundService = "SoundService.png",
	TextChatService = "TextChatService.png",
	RobloxPluginGuiService = "RobloxPluginGuiService.png",
	PluginGuiService = "PluginGuuService.png",
}

local function environment()
	if type(getgenv) == "function" then
		local ok, value = pcall(getgenv)
		if ok and type(value) == "table" then return value end
	end
	return _G
end

local function functionFrom(env, name)
	local value = env[name]
	if type(value) == "function" then return value end
	local ok, global = pcall(function() return _G[name] end)
	return ok and type(global) == "function" and global or nil
end

local function joinPath(folder, filename)
	if folder:sub(-1) == "/" then return folder .. filename end
	return folder .. "/" .. filename
end

function IconProvider.new(config)
	local self = setmetatable({}, IconProvider)
	self.config = config
	self.cache = {}
	self.waiters = {}
	self.loading = {}
	self.env = environment()
	self.asset = functionFrom(self.env, "getcustomasset") or functionFrom(self.env, "getsynasset")
	self.writefile = functionFrom(self.env, "writefile")
	self.isfile = functionFrom(self.env, "isfile")
	self.makefolder = functionFrom(self.env, "makefolder")
	self.isfolder = functionFrom(self.env, "isfolder")
	return self
end

function IconProvider:_filename(instance)
	local known = FILES[instance.ClassName] or FILES[instance.Name]
	if known then return known end
	if self.config.AutoClassIcons and instance.Parent ~= game then return instance.ClassName .. ".png" end
	return nil
end

function IconProvider:_ensureFolder()
	if not self.makefolder then return end
	local current = ""
	for part in self.config.IconFolder:gmatch("[^/]+") do
		current = current == "" and part or (current .. "/" .. part)
		local exists = false
		if self.isfolder then
			local ok, value = pcall(self.isfolder, current)
			exists = ok and value == true
		end
		if not exists then pcall(self.makefolder, current) end
	end
end

function IconProvider:_load(filename)
	local configured = self.config.IconAssets and self.config.IconAssets[filename]
	if type(configured) == "string" and configured ~= "" then return configured end
	if not self.asset or not self.writefile then return nil end
	self:_ensureFolder()
	local path = joinPath(self.config.IconFolder, filename)
	local exists = false
	if self.isfile then
		local ok, value = pcall(self.isfile, path)
		exists = ok and value == true
	end
	if not exists then
		local ok, bytes = pcall(game.HttpGet, game, self.config.IconBaseUrl .. filename)
		if not ok or type(bytes) ~= "string" or #bytes < 8 then return nil end
		local wrote = pcall(self.writefile, path, bytes)
		if not wrote then return nil end
	end
	local ok, assetId = pcall(self.asset, path)
	return ok and type(assetId) == "string" and assetId or nil
end

function IconProvider:Get(instance, callback)
	local filename = self:_filename(instance)
	if not filename then return nil end
	if self.cache[filename] ~= nil then
		local value = self.cache[filename] or nil
		if callback then callback(value) end
		return value
	end
	if callback then
		self.waiters[filename] = self.waiters[filename] or {}
		table.insert(self.waiters[filename], callback)
	end
	if self.loading[filename] then return nil end
	self.loading[filename] = true
	task.spawn(function()
		local value = self:_load(filename)
		self.cache[filename] = value or false
		self.loading[filename] = nil
		local waiters = self.waiters[filename] or {}
		self.waiters[filename] = nil
		for _, waiter in ipairs(waiters) do pcall(waiter, value) end
	end)
	return nil
end

function IconProvider:HasIcon(instance)
	return self:_filename(instance) ~= nil
end

return IconProvider
