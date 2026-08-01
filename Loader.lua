-- Troque somente esta URL depois de publicar o projeto.
local DEFAULT_BASE_URL = "https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPOSITORIO/main/GOATDecode/"

local environment = _G
if type(getgenv) == "function" then
	local ok, value = pcall(getgenv)
	if ok and type(value) == "table" then environment = value end
end

local baseUrl = environment.DEGOAT_BASE_URL or DEFAULT_BASE_URL
assert(not baseUrl:find("SEU_USUARIO",1,true), "configure DEFAULT_BASE_URL em Loader.lua")
if baseUrl:sub(-1) ~= "/" then baseUrl ..= "/" end

if environment.DeGOATApp and type(environment.DeGOATApp.Destroy) == "function" then
	pcall(function() environment.DeGOATApp:Destroy() end)
end

local source = game:HttpGet(baseUrl .. "DeGOATExecutor/DeGOAT.bundle.lua")
local chunk, compileError = loadstring(source, "@DeGOAT.bundle.lua")
assert(chunk, compileError)
local DeGOAT = chunk()
local app = DeGOAT.start()
environment.DeGOATApp = app
return app
