local Naming = {}

local keywords = {
	["and"]=true,["break"]=true,["do"]=true,["else"]=true,["elseif"]=true,
	["end"]=true,["false"]=true,["for"]=true,["function"]=true,["goto"]=true,
	["if"]=true,["in"]=true,["local"]=true,["nil"]=true,["not"]=true,
	["or"]=true,["repeat"]=true,["return"]=true,["then"]=true,["true"]=true,
	["until"]=true,["while"]=true,["continue"]=true,
}

function Naming.identifier(value, fallback)
	value = tostring(value):gsub("[^%w_]", "_"):gsub("_+", "_"):gsub("^_+", ""):gsub("_+$", "")
	if value == "" or value:match("^%d") or keywords[value] then return fallback or "value" end
	return value
end

function Naming.callResult(functionValue, method, arguments)
	local literal = arguments and arguments[1]
	if method == "GetService" and literal and literal:match('^".*"$') then
		return literal:sub(2, -2), 100
	elseif (method == "WaitForChild" or method == "FindFirstChild") and literal and literal:match('^".*"$') then
		local value = literal:sub(2, -2)
		return value == "HumanoidRootPart" and "rootPart" or value, 86
	elseif method == "newSound" then return "sound", 98
	elseif method == "Wait" and functionValue:match("%.CharacterAdded$") then return "character", 88
	elseif method == "Create" and functionValue:match("TweenService") then return "tween", 88
	elseif functionValue:match("%.newSound$") then return "sound", 98
	elseif functionValue == "require" and arguments and arguments[1] then
		return arguments[1]:match("([%a_][%w_]*)$"), 84
	elseif functionValue == "Instance.new" and literal then
		local value = literal:match('^"(.*)"$')
		if value then return value:sub(1,1):lower() .. value:sub(2), 90 end
	elseif functionValue == "TweenInfo.new" then return "tweenInfo", 82 end
	return nil, 0
end

function Naming.tableResult(proto, instructions, position, register, mainId)
	for cursor = position + 1, #instructions do
		local item = instructions[cursor]
		if item.name == "SETTABLEKS" and item.b == register then
			local constant = proto.constants[(item.aux or 0) + 1]
			local key = constant and tostring(constant.value) or ""
			if key == "Size" or key == "Position" or key == "Orientation" or key == "Transparency" then
				return "goal", 84
			end
		elseif item.name == "RETURN" and proto.id == mainId and item.b == 2 and item.a == register then
			return "module", 92
		end
		local writes = item.a == register and (
			item.name:sub(1,4) == "LOAD" or item.name:sub(1,3) == "GET" or
			item.name == "MOVE" or item.name == "NEWTABLE" or item.name == "DUPTABLE" or
			item.name == "NEWCLOSURE" or item.name == "DUPCLOSURE" or item.name == "CALL"
		)
		if writes then break end
	end
	return nil, 0
end

return Naming
