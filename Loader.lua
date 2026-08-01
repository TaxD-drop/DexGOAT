local DEFAULT_BASE_URL = "https://raw.githubusercontent.com/TaxD-drop/DexGOAT/refs/heads/main/"

local environment = _G
if type(getgenv) == "function" then
	local ok, value = pcall(getgenv)
	if ok and type(value) == "table" then environment = value end
end

local baseUrl = environment.DEGOAT_BASE_URL or DEFAULT_BASE_URL
if baseUrl:sub(-1) ~= "/" then baseUrl ..= "/" end

if environment.DeGOATApp and type(environment.DeGOATApp.Destroy) == "function" then
	pcall(function() environment.DeGOATApp:Destroy() end)
end

local source = game:HttpGet(baseUrl .. "DeGOATExecutor/DeGOAT.bundle.lua")
local chunk, compileError = loadstring(source, "@DeGOAT.bundle.lua")
assert(chunk, compileError)
local DeGOAT = chunk()
local app = DeGOAT.start({
	IconBaseUrl = baseUrl .. "DeGOATClient/Icons/",
})
environment.DeGOATApp = app
return app
