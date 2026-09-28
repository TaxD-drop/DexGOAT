-- Decompilado por DeGOAT
-- Luau bytecode v9; tipos v3; opcodes roblox-mul227
-- Nomes semânticos exigem evidência; baixa confiança permanece como vN.
-- Trailer opaco preservado: 24 bytes (defa5a8845bbc01a0b18c15309f076d2aee24dfcec3e3089)

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
local module = {}
module.__index = module
local module2 = {}
module2.__index = module2
-- função reconstruída: Disconnect
function module.Disconnect(arg1)
	if arg1.is_connected == false then
		return
	end
	local v0 = arg1.signal
	arg1.is_connected = false
	v0.listener_count = (v0.listener_count - 1.0)
	if v0.head == arg1 then
		v0.head = arg1.next
		return
	end
	local v1 = v0.head
	while true do
		if v1 == nil then break end
		if v1.next == arg1 then break end
		v1 = v1.next
	end
	if v1 ~= nil then
		v1.next = arg1.next
	end
	return
end
-- função reconstruída: New
function module2.New()
	-- upvalues: (copy) module2
	local v0 = {["head"] = nil, ["listener_count"] = 0.0}
	setmetatable(v0, module2)
	return v0
end
-- função reconstruída: Connect
function module2.Connect(arg1, arg2)
	-- upvalues: (copy) module
	if type(arg2) ~= "function" then
		local v0 = typeof(arg2)
		local v1 = ("[%*]: \"listener\" must be a function; Received %*"):format(script.Name, v0)
		error(v1)
	end
	local v2 = {["listener"] = nil, ["signal"] = nil, ["next"] = nil, ["is_connected"] = true}
	v2.listener = arg2
	v2.signal = arg1
	v2.next = arg1.head
	setmetatable(v2, module)
	arg1.head = v2
	arg1.listener_count = (arg1.listener_count + 1.0)
	return v2
end
-- função reconstruída: GetListenerCount
function module2.GetListenerCount(arg1)
	return arg1.listener_count
end
local RunEventHandlerInFreeThread = function(...)
	-- upvalues: (copy) AcquireRunnerThreadAndCallEventHandler
	AcquireRunnerThreadAndCallEventHandler(...)
	while true do
		AcquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
	return
end
-- função reconstruída: Fire
function module2.Fire(arg1, ...)
	-- upvalues: (ref) v0, (copy) RunEventHandlerInFreeThread
	local v1 = arg1.head
	while true do
		if v1 == nil then break end
		if v1.is_connected == true then
			if not (v0) then
				local v2 = coroutine.create(RunEventHandlerInFreeThread)
				v0 = v2
			end
			task.spawn(v0, v1.listener, ...)
		end
		v1 = v1.next
	end
	return
end
-- função reconstruída: Wait
function module2.Wait(arg1)
	local v0 = coroutine.running()
	local v1 = nil
	local v2 = arg1:Connect(function(...)
		-- upvalues: (ref) v1, (copy) v0
		v1:Disconnect()
		task.spawn(v0, ...)
		return
	end)
	return coroutine.yield()
end
-- função reconstruída: FireUntil
function module2.FireUntil(arg1, arg2, ...)
	if type(arg2) ~= "function" then
		local v0 = typeof(arg2)
		local v1 = ("[%*]: \"continue_callback\" must be a function; Received %*"):format(script.Name, v0)
		error(v1)
	end
	local v2 = {}
	local v3 = table.pack(...)
	local v4 = arg1.head
	while true do
		if v4 == nil then break end
		table.insert(v2, v4)
		v4 = v4.next
	end
	task.spawn(function()
		-- upvalues: (copy) v2, (copy) v3, (copy) arg2
		for key, value in ipairs(v2) do
			if value.is_connected ~= true then continue end
			value.listener(table.unpack(v3))
			if arg2() == true then continue end
			return
		end
		return
	end)
	return
end
local v1 = {}
v1.New = module2.New
return table.freeze(v1)
