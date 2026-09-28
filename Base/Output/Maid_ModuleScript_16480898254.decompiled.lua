-- Decompilado por DeGOAT
-- Luau bytecode v9; tipos v3; opcodes roblox-mul227
-- Nomes semânticos exigem evidência; baixa confiança permanece como vN.
-- Trailer opaco preservado: 24 bytes (0b0012f952f650d7cf6cafa6379169f07b18058d39c478f8)

local v0 = nil
-- função reconstruída: AcquireRunnerThreadAndCallEventHandler
local AcquireRunnerThreadAndCallEventHandler = function(arg1, ...)
	-- upvalues: (ref) v0
	local v1 = v0
	v0 = nil
	arg1(...)
	v0 = v1
	return
end
-- função reconstruída: RunEventHandlerInFreeThread
-- função reconstruída: Cleanup
local RunEventHandlerInFreeThread = function(...)
	-- upvalues: (copy) AcquireRunnerThreadAndCallEventHandler
	AcquireRunnerThreadAndCallEventHandler(...)
	while true do
		AcquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
	return
end
local Cleanup = function(arg1, ...)
	if typeof(arg1) == "function" then
		arg1(...)
		return
	end
	if typeof(arg1) == "RBXScriptConnection" then
		arg1:Disconnect()
		return
	end
	if typeof(arg1) == "Instance" then
		arg1:Destroy()
		return
	end
	if typeof(arg1) == "table" then
		if type(arg1.Destroy) == "function" then
			arg1:Destroy()
			return
		end
		if type(arg1.Disconnect) == "function" then
			arg1:Disconnect()
		end
	end
	return
end
-- função reconstruída: CleanupInThread
local module = {}
module.__index = module
-- função reconstruída: New
function module.New(arg1, arg2)
	-- upvalues: (copy) module
	local v0 = {}
	v0.maid = arg1
	v0.object = arg2
	setmetatable(v0, module)
	return v0
end
-- função reconstruída: Destroy
function module.Destroy(arg1)
	arg1.maid.tokens[arg1] = nil
	return
end
local CleanupInThread = function(...)
	-- upvalues: (ref) v0, (copy) RunEventHandlerInFreeThread, (copy) Cleanup
	if not (v0) then
		local v1 = coroutine.create(RunEventHandlerInFreeThread)
		v0 = v1
	end
	local v2 = assert(v0)
	task.spawn(v2, Cleanup, ...)
	return
end
-- função reconstruída: Cleanup
function module.Cleanup(arg1, ...)
	-- upvalues: (copy) CleanupInThread
	if arg1.object == nil then
		return
	end
	arg1.maid.tokens[arg1] = nil
	CleanupInThread(arg1.object, ...)
	arg1.object = nil
	return
end
local module2 = {}
module2.__index = module2
-- função reconstruída: New
function module2.New(arg1)
	-- upvalues: (copy) module2
	local v0 = {["tokens"] = nil, ["is_cleaned"] = false, ["key"] = nil}
	local v1 = {}
	v0.tokens = v1
	v0.key = arg1
	setmetatable(v0, module2)
	return v0
end
-- função reconstruída: IsActive
function module2.IsActive(arg1)
	return not (arg1.is_cleaned)
end
-- função reconstruída: Add
function module2.Add(arg1, arg2)
	-- upvalues: (copy) CleanupInThread, (copy) module
	if arg1.is_cleaned == true then
		CleanupInThread(arg2)
	end
	if typeof(arg2) == "table" then
		if type(arg2.Destroy) ~= "function" then
			if type(arg2.Disconnect) ~= "function" then
				local v0 = ("[%*]: Received table as cleanup object, but couldn't detect a :Destroy() or :Disconnect() method"):format(script.Name)
				error(v0)
			end
		end
	else
		if typeof(arg2) ~= "function" then
			if typeof(arg2) ~= "RBXScriptConnection" then
				if typeof(arg2) ~= "Instance" then
					local v1 = ("[%*]: Cleanup of type \"%*\" not supported"):format(script.Name, typeof(arg2))
					error(v1)
				end
			end
		end
	end
	local v2 = module.New(arg1, arg2)
	arg1.tokens[v2] = true
	return v2
end
-- função reconstruída: Cleanup
function module2.Cleanup(arg1, ...)
	if arg1.key ~= nil then
		local v0 = ("[%*]: \"Cleanup()\" is locked for this Maid"):format(script.Name)
		error(v0)
	end
	arg1.is_cleaned = true
	for value in pairs(arg1.tokens) do
		value:Cleanup(...)
	end
	return
end
-- função reconstruída: Unlock
function module2.Unlock(arg1, arg2)
	if arg1.key ~= nil then
		if arg1.key ~= arg2 then
			local v0 = ("[%*]: Invalid lock key"):format(script.Name)
			error(v0)
		end
	end
	arg1.key = nil
	return
end
return module2
