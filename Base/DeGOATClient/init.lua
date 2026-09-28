local Config=require(script.Config)
local App=require(script.UI.App)

local DeGOATClient={ Version="0.5.0-luau" }

function DeGOATClient.start(overrides)
	local config=table.clone(Config)
	for key,value in pairs(overrides or {}) do config[key]=value end
	return App.new(script,config)
end

return DeGOATClient
