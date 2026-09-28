-- Decompilado por DeGOAT
-- Luau bytecode v9; tipos v3; opcodes roblox-mul227
-- Nomes semânticos exigem evidência; baixa confiança permanece como vN.
-- Trailer opaco preservado: 24 bytes (423a825ae35570f96bc2f074a2a386883222952e70fee85b)

local module = {}
local v0 = {}
v0["Eat Players"] = 720768665.0
v0.Magnet = 730280015.0
v0["Explosive Chunks"] = 733742262.0
module.GamePasses = v0
local v1 = {}
v1["Small Cube Pack"] = 1760706156.0
v1["Medium Cube Pack"] = 1760707045.0
v1["Large Cube Pack"] = 1760707972.0
v1["Giant Cube Pack"] = 1760709729.0
v1["Max Size"] = 1760728424.0
v1["Small Token Pack"] = 1805507066.0
v1["Medium Token Pack"] = 1805507931.0
v1["Large Token Pack"] = 1805509180.0
v1["Giant Token Pack"] = 1805509730.0
v1["Starter Pack"] = 1942042820.0
v1["Holiday Pack 2024"] = 2678435873.0
v1["Rainbow Pack"] = 2839548304.0
v1["Halloween Pack 2025"] = 3442873499.0
v1["Candy Rain"] = 3443110792.0
v1["Holiday Pack 2025"] = 3479946298.0
v1["Ornament Rain"] = 3479953907.0
module.DevProducts = v1
local v2 = {}
v2["Small Cube Pack"] = 60000.0
v2["Medium Cube Pack"] = 150000.0
v2["Large Cube Pack"] = 600000.0
v2["Giant Cube Pack"] = 2000000.0
module.CubePacks = v2
local v3 = {}
v3["Small Token Pack"] = 3
v3["Medium Token Pack"] = 5
v3["Large Token Pack"] = 15
v3["Giant Token Pack"] = 50
module.TokenPacks = v3
local v4 = {}
local v5 = {["Price"] = 400.0, ["Icon"] = nil}
v4["Holiday Nametag"] = v5
local v6 = {["Price"] = 75.0, ["Icon"] = "rbxassetid://17124332818", ["Amount"] = 50.0}
v4["Token Pack"] = v6
local v7 = {["Price"] = 100.0, ["Icon"] = "rbxassetid://16481350112"}
v4["Instant Max Size"] = v7
module.EventOffers = v4
local v8 = {}
local v9 = {}
v9.Tokens = 10
v9.Cubes = 150000.0
v8["Starter Pack"] = v9
local v10 = {}
v10.Tokens = 50
v10.Cubes = 2000000.0
v8["Holiday Pack 2024"] = v10
local v11 = {}
v11.Tokens = 50
v11.Cubes = 2000000.0
v8["Rainbow Pack"] = v11
local v12 = {}
v12.Tokens = 50
v12.Cubes = 2000000.0
v8["Halloween Pack 2025"] = v12
local v13 = {}
v13.Tokens = 50
v13.Cubes = 2000000.0
v8["Holiday Pack 2025"] = v13
module.Bundles = v8
local v14 = {}
v14["Starter Pack"] = 1
v14["Holiday Pack 2024"] = 0
v14["Rainbow Pack"] = 1
v14["Halloween Pack 2025"] = 1
v14["Holiday Pack 2025"] = 1
module.LimitedPurchases = v14
local v15 = {}
local v16 = {["name"] = "Money Rain", ["price"] = 3.0, ["image"] = "rbxassetid://17099910913", ["description"] = "Rains money from the sky!", ["message"] = "It's raining money!", ["duration"] = 60.0}
v15["Money Rain"] = v16
local v17 = {["name"] = "Money Rain", ["price"] = 5.0, ["image"] = "rbxassetid://17099910828", ["description"] = "Summon a robot to destroy the map!", ["message"] = "A robot is attacking!", ["duration"] = 60.0}
v15.Robot = v17
local v18 = {["name"] = "Money Rain", ["price"] = 10.0, ["image"] = "rbxassetid://17099911657", ["description"] = "Destroys most of the map!", ["message"] = "A NUKE IS FALLING! RUN AWAY FROM THE CENTER!", ["duration"] = 30.0}
v15.Nuke = v18
local v19 = {["name"] = "Money Rain", ["price"] = nil, ["image"] = "rbxassetid://13902932122", ["description"] = "Rains candy for everyone on the server!", ["message"] = "It's raining candy!", ["duration"] = 60.0}
v15["Candy Rain"] = v19
local v20 = {["name"] = "Money Rain", ["price"] = nil, ["image"] = "rbxassetid://13902932122", ["description"] = "Rains ornaments for everyone on the server!", ["message"] = "It's raining ornaments!", ["duration"] = 60.0}
v15["Ornament Rain"] = v20
local v21 = {["name"] = "Money Rain", ["price"] = nil, ["image"] = "rbxassetid://13902932122", ["description"] = "Rains giant food that gives extra size!", ["duration"] = 30.0}
v15["Big Food"] = v21
local v22 = {["name"] = "Money Rain", ["price"] = 5.0, ["image"] = "rbxassetid://17099910709", ["description"] = "Summon skeletons to destroy the map!", ["message"] = "Skeletons are attacking!", ["duration"] = 60.0}
v15.Skeletons = v22
local v23 = {["name"] = "Low Gravity", ["price"] = 1.0, ["image"] = "rbxassetid://17099910598", ["description"] = "Make everything float!", ["message"] = "Low gravity!", ["duration"] = 40.0}
v15["Low Gravity"] = v23
module.Events = v15
local v24 = {}
local module2 = {["price"] = 10.0, ["description"] = "98% chance to get a random color nametag, 2% chance to get a GLOWING color nametag!", ["decal"] = "rbxassetid://110003088413698", ["possibilities"] = nil, ["getCrate"] = nil}
local v25 = {}
v25[2] = "Green"
v25[3] = "Cyan"
v25[4] = "Purple"
v25[5] = "Pink"
v25[6] = "Blue"
v25[7] = "Orange"
v25[8] = "Red"
v25[9] = "Yellow"
v25[10] = "Glowing Green"
v25[11] = "Glowing Cyan"
v25[12] = "Glowing Purple"
v25[13] = "Glowing Pink"
v25[14] = "Glowing Red"
v25[15] = "Glowing Yellow"
module2.possibilities = v25
-- função reconstruída: getCrate
function module2.getCrate()
	local v0 = {}
	v0[2] = "Green"
	v0[3] = "Cyan"
	v0[4] = "Purple"
	v0[5] = "Pink"
	v0[6] = "Blue"
	v0[7] = "Orange"
	v0[8] = "Red"
	v0[9] = "Yellow"
	local v1 = {}
	v1[2] = "Glowing Green"
	v1[3] = "Glowing Cyan"
	v1[4] = "Glowing Purple"
	v1[5] = "Glowing Pink"
	v1[6] = "Glowing Red"
	v1[7] = "Glowing Yellow"
	local v2 = math.random()
	if 0.98 < v2 then
		local v3 = math.random(1, #v1)
		return v1[v3]
	end
	local v4 = math.random(1, #v0)
	return v0[v4]
end
v24["Color Crate"] = module2
local module3 = {["price"] = 25.0, ["description"] = "80% chance to get a common nametag, 18% chance to get an uncommon nametag, 2% chance to get a RARE nametag!", ["color"] = nil, ["possibilities"] = nil, ["getCrate"] = nil}
local v26 = Color3.new(1, 0.905882, 0.752941)
module3.color = v26
local v27 = {}
v27[2] = "Draw Four"
v27[3] = "Velvet"
v27[4] = "Mysterious"
v27[5] = "Sketchbook"
v27[6] = "Viscount"
v27[7] = "Lolcats"
v27[8] = "3D Movie"
v27[9] = "Fruit Salad"
v27[10] = "Bubblegum"
module3.possibilities = v27
-- função reconstruída: getCrate
function module3.getCrate()
	local v0 = {}
	v0[2] = "Draw Four"
	v0[3] = "Velvet"
	v0[4] = "Mysterious"
	v0[5] = "Sketchbook"
	v0[6] = "Viscount"
	local v1 = {}
	v1[2] = "Lolcats"
	v1[3] = "3D Movie"
	v1[4] = "Fruit Salad"
	local v2 = {}
	v2[2] = "Bubblegum"
	local v3 = math.random()
	if 0.98 < v3 then
		local v4 = math.random(1, #v2)
		return v2[v4]
	end
	if 0.8 < v3 then
		local v5 = math.random(1, #v1)
		return v1[v5]
	end
	local v6 = math.random(1, #v0)
	return v0[v6]
end
v24["Standard Crate"] = module3
local module4 = {["price"] = 25.0, ["description"] = "80% chance to get a common nametag, 18% chance to get an uncommon nametag, 2% chance to get a RARE nametag!", ["decal"] = "rbxassetid://118112669619148", ["possibilities"] = nil, ["getCrate"] = nil}
local v28 = {}
v28[2] = "Vaporwave"
v28[3] = "Nostalgia"
v28[4] = "Relaxed"
v28[5] = "Solar"
v28[6] = "Neon"
v28[7] = "Wireframe"
v28[8] = "Futuristic"
v28[9] = "Glitchcore"
module4.possibilities = v28
-- função reconstruída: getCrate
function module4.getCrate()
	local v0 = {}
	v0[2] = "Vaporwave"
	v0[3] = "Nostalgia"
	v0[4] = "Relaxed"
	local v1 = {}
	v1[2] = "Solar"
	v1[3] = "Neon"
	v1[4] = "Wireframe"
	local v2 = {}
	v2[2] = "Futuristic"
	v2[3] = "Glitchcore"
	local v3 = math.random()
	if 0.98 < v3 then
		local v4 = math.random(1, #v2)
		return v2[v4]
	end
	if 0.8 < v3 then
		local v5 = math.random(1, #v1)
		return v1[v5]
	end
	local v6 = math.random(1, #v0)
	return v0[v6]
end
v24["Digital Crate"] = module4
module.Crates = v24
local v29 = {}
local v30 = {["description"] = "", ["rarity"] = 1.0}
v29.Green = v30
local v31 = {["description"] = "", ["rarity"] = 1.0}
v29.Cyan = v31
local v32 = {["description"] = "", ["rarity"] = 1.0}
v29.Purple = v32
local v33 = {["description"] = "", ["rarity"] = 1.0}
v29.Pink = v33
local v34 = {["description"] = "", ["rarity"] = 1.0}
v29.Blue = v34
local v35 = {["description"] = "", ["rarity"] = 1.0}
v29.Orange = v35
local v36 = {["description"] = "", ["rarity"] = 1.0}
v29.Red = v36
local v37 = {["description"] = "", ["rarity"] = 1.0}
v29.Yellow = v37
local v38 = {["description"] = "", ["rarity"] = 3.0}
v29["Glowing Green"] = v38
local v39 = {["description"] = "", ["rarity"] = 3.0}
v29["Glowing Cyan"] = v39
local v40 = {["description"] = "", ["rarity"] = 3.0}
v29["Glowing Purple"] = v40
local v41 = {["description"] = "", ["rarity"] = 3.0}
v29["Glowing Pink"] = v41
local v42 = {["description"] = "", ["rarity"] = 3.0}
v29["Glowing Orange"] = v42
local v43 = {["description"] = "", ["rarity"] = 3.0}
v29["Glowing Red"] = v43
local v44 = {["description"] = "", ["rarity"] = 3.0}
v29["Glowing Yellow"] = v44
local v45 = {["description"] = "", ["rarity"] = 1.0}
v29["Draw Four"] = v45
local v46 = {["description"] = "", ["rarity"] = 1.0}
v29.Velvet = v46
local v47 = {["description"] = "", ["rarity"] = 1.0}
v29.Mysterious = v47
local v48 = {["description"] = "", ["rarity"] = 1.0}
v29.Sketchbook = v48
local v49 = {["description"] = "", ["rarity"] = 1.0}
v29.Viscount = v49
local v50 = {["description"] = "", ["rarity"] = 1.0}
v29.Diary = v50
local v51 = {["description"] = "", ["rarity"] = 2.0}
v29.Lolcats = v51
local v52 = {["description"] = "", ["rarity"] = 2.0}
v29["3D Movie"] = v52
local v53 = {["description"] = "", ["rarity"] = 2.0}
v29["Fruit Salad"] = v53
local v54 = {["description"] = "", ["rarity"] = 3.0}
v29.Bubblegum = v54
local v55 = {["description"] = "", ["rarity"] = 1.0}
v29.Vaporwave = v55
local v56 = {["description"] = "", ["rarity"] = 1.0}
v29.Nostalgia = v56
local v57 = {["description"] = "", ["rarity"] = 1.0}
v29.Relaxed = v57
local v58 = {["description"] = "", ["rarity"] = 2.0}
v29.Solar = v58
local v59 = {["description"] = "", ["rarity"] = 2.0}
v29.Neon = v59
local v60 = {["description"] = "", ["rarity"] = 2.0}
v29.Wireframe = v60
local v61 = {["description"] = "", ["rarity"] = 3.0}
v29.Futuristic = v61
local v62 = {["description"] = "", ["rarity"] = 3.0}
v29.Glitchcore = v62
local v63 = {["description"] = "Awarded to players who completed the 2024 Holiday Quest!", ["rarity"] = 4.0}
v29["Candy Cane"] = v63
local v64 = {["description"] = "Only available during the Halloween Event!", ["rarity"] = 4.0}
v29.Halloween = v64
local v65 = {["description"] = "Awarded to players who purchased the 2024 Holiday Pack!", ["rarity"] = 5.0}
v29["Festive Gold"] = v65
local v66 = {["description"] = "Awarded to players who purchased the Rainbow Pack!", ["rarity"] = 5.0}
v29.Rainbow = v66
local v67 = {["description"] = "Awarded to players who purchased the Halloween Pack!", ["rarity"] = 5.0}
v29.Bite = v67
local v68 = {["description"] = "Awarded to players who completed The Hunt: Mega Edition quest!", ["rarity"] = 4.0}
v29["Token Hunter"] = v68
local v69 = {["description"] = "Awarded to players who completed Smileys launch event!", ["rarity"] = 4.0}
v29.Smileys = v69
local v70 = {["description"] = "Only available during the Holiday Event!", ["rarity"] = 4.0}
v29["Christmas Tree"] = v70
local v71 = {["description"] = "Awarded to players who purchased the 2025 Holiday Pack!", ["rarity"] = 5.0}
v29["Festive Red"] = v71
module.Nametags = v29
local v72 = {}
local module5 = {["name"] = "Maximum Size", ["order"] = 1.0, ["initial"] = 0.5, ["maxLevel"] = 10.0, ["image"] = "rbxassetid://17151582981", ["color"] = nil, ["priceFunction"] = nil, ["growthFunction"] = nil}
local v73 = Color3.new(0.596078, 1, 0.698039)
module5.color = v73
-- função reconstruída: priceFunction
function module5.priceFunction(arg1)
	local v0 = math.floor(((arg1 ^ 3.0) / 2.0))
	return (v0 * 20.0)
end
-- função reconstruída: growthFunction
function module5.growthFunction(arg1)
	local v0 = math.floor((((((arg1 + 0.5) ^ 2.0) - 0.25) / 2.0) * 100.0))
	return v0
end
v72.MaxSize = module5
local module6 = {["name"] = "Walk Speed", ["order"] = 2.0, ["initial"] = 0.5, ["maxLevel"] = 10.0, ["image"] = "rbxassetid://17137197155", ["color"] = nil, ["priceFunction"] = nil, ["growthFunction"] = nil}
local v74 = Color3.new(0.439216, 0.541176, 1)
module6.color = v74
-- função reconstruída: priceFunction
function module6.priceFunction(arg1)
	local v0 = math.floor((((arg1 * 3.0) ^ 3.0) / 200.0))
	return (v0 * 1000.0)
end
-- função reconstruída: growthFunction
function module6.growthFunction(arg1)
	local v0 = math.floor(((arg1 * 2.0) + 10.0))
	return v0
end
v72.Speed = module6
local module7 = {["name"] = "Size Multiplier", ["order"] = 3.0, ["initial"] = 0.5, ["maxLevel"] = 10.0, ["image"] = "rbxassetid://17137197010", ["color"] = nil, ["priceFunction"] = nil, ["growthFunction"] = nil}
local v75 = Color3.new(1, 0.384314, 0.396078)
module7.color = v75
-- função reconstruída: priceFunction
function module7.priceFunction(arg1)
	local v0 = math.floor((((arg1 * 10.0) ^ 3.0) / 200.0))
	return (v0 * 1000.0)
end
-- função reconstruída: growthFunction
function module7.growthFunction(arg1)
	local v0 = math.floor(arg1)
	return v0
end
v72.Multiplier = module7
local module8 = {["name"] = "Eat Speed", ["order"] = 4.0, ["initial"] = 0.5, ["maxLevel"] = 10.0, ["image"] = "rbxassetid://16676559094", ["color"] = nil, ["priceFunction"] = nil, ["growthFunction"] = nil}
local v76 = Color3.new(1, 0.854902, 0.521569)
module8.color = v76
-- função reconstruída: priceFunction
function module8.priceFunction(arg1)
	local v0 = math.floor((((arg1 * 10.0) ^ 3.0) / 200.0))
	return (v0 * 2000.0)
end
-- função reconstruída: growthFunction
function module8.growthFunction(arg1)
	local v0 = math.floor(((1 + ((arg1 - 1.0) * 0.2)) * 10.0))
	return (v0 / 10.0)
end
v72.EatSpeed = module8
module.Upgrades = v72
local v77 = {}
module.Tools = v77
local v78 = {}
v78["Eat Players"] = "Eat players smaller than you to steal their size!"
v78.Magnet = "Automatically collect money!"
v78["Explosive Chunks"] = "Anything you throw explodes on impact, dealing more damage!"
module.Descriptions = v78
return module
