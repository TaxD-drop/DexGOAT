-- Decompilado por DeGOAT
-- Luau bytecode v9; tipos v3; opcodes roblox-mul227
-- Nomes semânticos exigem evidência; baixa confiança permanece como vN.
-- Trailer opaco preservado: 24 bytes (49703e4d8a3ea7c4d0b97021c8cea7a6396829397bb4544c)

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local v0 = RunService:IsStudio()
local v1 = RunService:IsServer()
local v2 = {}
local v3 = nil
local v4 = nil
if v1 == true then
	local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	v3 = RemoteEvents
	if v3 ~= nil then
		if v0 == true then
			local v5 = ("[%*]: ReplicatedStorage \"RemoteEvents\" container was already defined"):format(script.Name)
			warn(v5)
		end
	else
		local folder = Instance.new("Folder")
		v3 = folder
		v3.Name = "RemoteEvents"
		v3.Parent = ReplicatedStorage
	end
else
	local RemoteEvents2 = ReplicatedStorage:FindFirstChild("RemoteEvents")
	v3 = RemoteEvents2
	if v3 == nil then
		local bindableEvent = Instance.new("BindableEvent")
		v4 = bindableEvent
		task.spawn(function()
			-- upvalues: (ref) v3, (copy) ReplicatedStorage, (ref) v4
			while true do
				if not (task.wait()) then break end
				local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
				v3 = RemoteEvents
				if v3 ~= nil then
					v4:Fire()
					return
				end
			end
			return
		end)
	end
end
local module = {}
module.__index = module
-- função reconstruída: New
function module.New(arg1)
	-- upvalues: (copy) module
	local v0 = {["fn"] = nil, ["is_disconnected"] = false, ["real_connection"] = nil}
	v0.fn = arg1
	local v1 = setmetatable(v0, module)
	return v1
end
-- função reconstruída: Disconnect
function module.Disconnect(arg1)
	arg1.is_disconnected = true
	if arg1.real_connection ~= nil then
		arg1.real_connection:Disconnect()
	end
	return
end
local module2 = {}
module2.__index = module2
-- função reconstruída: New
function module2.New(arg1, arg2)
	-- upvalues: (copy) v1, (copy) v2, (ref) v3, (copy) module, (copy) module2, (ref) v4
	if type(arg1) ~= "string" then
		local v0 = ("[%*]: name must be a string"):format(script.Name)
		error(v0)
	end
	if v1 == true then
		if v2[arg1] ~= nil then
			local v5 = ("[%*]: RemoteEvent %* was already defined"):format(script.Name, arg1)
			error(v5)
		end
		v2[arg1] = true
		local v6 = true
		if arg2 == true then
			v6 = "UnreliableRemoteEvent"
		else
			v6 = "RemoteEvent"
		end
		local remoteEvent = Instance.new(v6)
		remoteEvent.Name = arg1
		remoteEvent.Parent = v3
		return remoteEvent
	end
	local v7 = v3
	if v7 then
		v7 = v3
		v7 = v7:FindFirstChild(arg1)
	end
	if v7 ~= nil then
		return v7
	end
	local items = {}
	local v8 = {["OnClientEvent"] = nil, ["OnServerEvent"] = nil, ["RemoteEvent"] = nil}
	local module3 = {}
	-- função reconstruída: Connect
	function module3.Connect(arg1, arg2)
		-- upvalues: (ref) v7, (ref) module, (ref) items
		if v7 ~= nil then
			return v7.OnClientEvent:Connect(arg2)
		end
		local v0 = module.New(arg2)
		table.insert(items, v0)
		return v0
	end
	v8.OnClientEvent = module3
	local module4 = {}
	-- função reconstruída: Connect
	function module4.Connect()
		local v0 = ("[%*]: Can't connect to \"OnServerEvent\" client-side"):format(script.Name)
		error(v0)
		return
	end
	v8.OnServerEvent = module4
	local v9 = setmetatable(v8, module2)
	-- função reconstruída: on_container_ready
	if v3 ~= nil then
		task.spawn(function()
		-- upvalues: (ref) v7, (ref) v3, (copy) arg1, (ref) items, (copy) v9
		local v0 = os.clock()
		while true do
			local v1 = v3:FindFirstChild(arg1)
			v7 = v1
			if v7 ~= nil then break end
			if v0 ~= nil then
				local v2 = os.clock()
				if 20 < (v2 - v0) then
					v0 = nil
					local v4 = ("[%*]: RemoteEvent \"%*\" hasn't been defined server-side"):format(script.Name, arg1)
					warn(v4)
				end
			end
			task.wait()
		end
		for key, value in ipairs(items) do
			if value.is_disconnected ~= false then continue end
			local v5 = v7.OnClientEvent:Connect(value.fn)
			value.real_connection = v5
		end
		v9.RemoteEvent = v7
		items = nil
		return
	end)
	else
		local v10 = nil
		local on_container_ready = function()
		-- upvalues: (ref) v7, (ref) v3, (copy) arg1, (ref) items, (copy) v9
		local v0 = os.clock()
		while true do
			local v1 = v3:FindFirstChild(arg1)
			v7 = v1
			if v7 ~= nil then break end
			if v0 ~= nil then
				local v2 = os.clock()
				if 20 < (v2 - v0) then
					v0 = nil
					local v4 = ("[%*]: RemoteEvent \"%*\" hasn't been defined server-side"):format(script.Name, arg1)
					warn(v4)
				end
			end
			task.wait()
		end
		for key, value in ipairs(items) do
			if value.is_disconnected ~= false then continue end
			local v5 = v7.OnClientEvent:Connect(value.fn)
			value.real_connection = v5
		end
		v9.RemoteEvent = v7
		items = nil
		return
	end
		local v11 = v4.Event:Connect(function()
			-- upvalues: (ref) v10, (copy) on_container_ready
			v10:Disconnect()
			on_container_ready()
			return
		end)
	end
	return v9
end
-- função reconstruída: FireServer
function module2.FireServer(arg1, ...)
	if arg1.RemoteEvent ~= nil then
		arg1.RemoteEvent:FireServer(...)
	end
	return
end
-- função reconstruída: FireClient
function module2.FireClient(arg1)
	local v0 = ("[%*]: Can't use \"FireClient\" client-side"):format(script.Name)
	error(v0)
	return
end
-- função reconstruída: FireAllClients
function module2.FireAllClients(arg1)
	local v0 = ("[%*]: Can't use \"FireAllClients\" client-side"):format(script.Name)
	error(v0)
	return
end
return module2
