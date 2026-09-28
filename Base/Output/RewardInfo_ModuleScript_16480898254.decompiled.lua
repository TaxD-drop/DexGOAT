-- Decompilado por DeGOAT
-- Luau bytecode v9; tipos v3; opcodes roblox-mul227
-- Nomes semânticos exigem evidência; baixa confiança permanece como vN.
-- Trailer opaco preservado: 24 bytes (32307ced31c9460618828caae289eee642286b9900f416ec)

local module = {}
module.PremiumInterval = 21600
module.GroupInterval = 86400.0
module.EventInterval = 86400.0
module.SpinTime = 6
local v0 = {}
local v1 = {}
v1[2] = "SmallReward"
v1[3] = 300
local v2 = {}
v2[2] = "SmallReward"
v2[3] = 600
local v3 = {}
v3[2] = "SmallReward"
v3[3] = 900
local v4 = {}
v4[2] = "MediumReward"
v4[3] = 1500
local v5 = {}
v5[2] = "MediumReward"
v5[3] = 2100
local v6 = {}
v6[2] = "MediumReward"
v6[3] = 2700
local v7 = {}
v7[2] = "LargeReward"
v7[3] = 3600
local v8 = {}
v8[2] = "LargeReward"
v8[3] = 4500
local v9 = {}
v9[2] = "LargeReward"
v9[3] = 5400
v0[2] = v1
v0[3] = v2
v0[4] = v3
v0[5] = v4
v0[6] = v5
v0[7] = v6
v0[8] = v7
v0[9] = v8
v0[10] = v9
module.TimedRewards = v0
local v10 = {}
local v11 = {}
local v12 = {}
v12[2] = "Cubes"
v12[3] = 0.1
local v13 = {}
v13[2] = "Cubes"
v13[3] = 0.2
local v14 = {}
v14[2] = "Cubes"
v14[3] = 0.2
local v15 = {}
v15[2] = "Cubes"
v15[3] = 0.3
v11[2] = v12
v11[3] = v13
v11[4] = v14
v11[5] = v15
v10.SmallReward = v11
local v16 = {}
local v17 = {}
v17[2] = "Tokens"
v17[3] = 1
local v18 = {}
v18[2] = "Tokens"
v18[3] = 3
local v19 = {}
v19[2] = "Cubes"
v19[3] = 1
local v20 = {}
v20[2] = "Cubes"
v20[3] = 1
local v21 = {}
v21[2] = "Cubes"
v21[3] = 1.5
v16[2] = v17
v16[3] = v18
v16[4] = v19
v16[5] = v20
v16[6] = v21
v10.MediumReward = v16
local v22 = {}
local v23 = {}
v23[2] = "Tokens"
v23[3] = 3
local v24 = {}
v24[2] = "Tokens"
v24[3] = 5
local v25 = {}
v25[2] = "Cubes"
v25[3] = 2
local v26 = {}
v26[2] = "Cubes"
v26[3] = 3
local v27 = {}
v27[2] = "Cubes"
v27[3] = 3
v22[2] = v23
v22[3] = v24
v22[4] = v25
v22[5] = v26
v22[6] = v27
v10.LargeReward = v22
module.TimedRewardsTable = v10
local v28 = {}
local v29 = {}
v29[2] = "Tokens"
v29[3] = 1
v29[4] = "rbxassetid://17124312630"
local v30 = {}
v30[2] = "Cubes"
v30[3] = 1
v30[4] = "rbxassetid://16480960488"
local v31 = {}
v31[2] = "Tokens"
v31[3] = 3
v31[4] = "rbxassetid://17124305109"
local v32 = {}
v32[2] = "Cubes"
v32[3] = 2
v32[4] = "rbxassetid://16480986555"
local v33 = {}
v33[2] = "Tokens"
v33[3] = 10
v33[4] = "rbxassetid://17124326376"
local v34 = {}
v34[2] = "Cubes"
v34[3] = 5
v34[4] = "rbxassetid://16480972956"
v28[2] = v29
v28[3] = v30
v28[4] = v31
v28[5] = v32
v28[6] = v33
v28[7] = v34
module.SpinRewards = v28
-- função reconstruída: GetSpin
function module.GetSpin()
	local v0 = math.random()
	if 0.5 < v0 then
		local v1 = math.random()
		if 0.5 < v1 then
			return 1
		end
		return 2
	end
	if 0.85 < v0 then
		local v2 = math.random()
		if 0.5 < v2 then
			return 3
		end
		return 4
	end
	local v3 = math.random()
	if 0.5 < v3 then
		return 5
	end
	return 6
end
return module
