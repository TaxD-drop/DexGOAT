-- Decompilado por DeGOAT
-- Luau bytecode v9; tipos v3; opcodes roblox-mul227
-- Nomes semânticos exigem evidência; baixa confiança permanece como vN.
-- Trailer opaco preservado: 24 bytes (f16611d913e0a65954ef1f7675b73020817e06adc3a27bd8)

local v0 = {}
v0[2] = 3265580279142030.0
v0[3] = 2452047400854996.0
v0[4] = 3201386206402976.0
v0[5] = 1260097836104865.0
v0[6] = 700281813358906.0
v0[7] = 1979817500247421.0
v0[8] = 728948143754802.0
v0[9] = 3700915409354647.0
v0[10] = 3528222050539673.0
v0[11] = 1431656239018158.0
local module = {}
-- função reconstruída: GetTodaysNumber
function module.GetTodaysNumber()
	local v0 = os.time()
	return (v0 // 86400.0)
end
-- função reconstruída: GetTodaysBadgeId
function module.GetTodaysBadgeId()
	-- upvalues: (copy) v0
	local v1 = os.time()
	local v2 = math.clamp(((v1 // 86400.0) - 20320.0), 1, #v0)
	return v0[v2]
end
return module
