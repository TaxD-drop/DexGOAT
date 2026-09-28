local Properties = {}

local CATEGORY_ORDER = {
	"Identification", "Data", "Transform", "Appearance", "Behavior", "Collision",
	"Assembly", "Mesh", "Audio", "Text", "Layout", "Script", "Attributes", "Other",
}

local SCHEMA = {
	Identification = { "Name", "ClassName", "Parent", "Archivable" },
	Data = {
		"Value", "ValueConstraint", "MaxValue", "MinValue", "CurrentDistance", "CurrentAngle",
		"Attachment0", "Attachment1", "Adornee", "PrimaryPart", "WorldPivot", "PivotOffset",
	},
	Transform = { "CFrame", "Position", "Orientation", "Rotation", "Size", "Scale", "StudsOffset", "StudsOffsetWorldSpace" },
	Appearance = {
		"Visible", "Transparency", "Color", "Color3", "BrickColor", "Material", "MaterialVariant",
		"Reflectance", "CastShadow", "Texture", "TextureID", "TextureId", "Image", "ImageColor3",
		"ImageTransparency", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderSizePixel",
		"Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "ExposureCompensation", "FogColor", "FogEnd",
		"FogStart", "GlobalShadows", "Technology", "DisplayOrder", "LightInfluence", "AlwaysOnTop",
	},
	Behavior = {
		"Enabled", "Disabled", "Active", "Selectable", "Draggable", "Locked", "Massless", "Anchored",
		"CanCollide", "CanQuery", "CanTouch", "CanLoadCharacterAppearance", "ResetOnSpawn", "IgnoreGuiInset",
		"AutoLocalize", "RichText", "TextEditable", "ClearTextOnFocus", "Looped", "Playing", "PlayOnRemove",
		"TimePosition", "PlaybackSpeed", "Volume", "MaxDistance", "RollOffMaxDistance", "RollOffMinDistance",
	},
	Collision = { "CollisionGroup", "CollisionGroupId", "RootPriority", "CustomPhysicalProperties" },
	Assembly = {
		"AssemblyAngularVelocity", "AssemblyCenterOfMass", "AssemblyLinearVelocity", "AssemblyMass",
		"AssemblyRootPart", "Velocity", "RotVelocity",
	},
	Mesh = { "MeshId", "MeshID", "MeshType", "Offset", "VertexColor", "DoubleSided", "RenderFidelity", "CollisionFidelity" },
	Audio = { "SoundId", "SoundGroup", "EmitterSize", "RollOffMode", "RespectFilteringEnabled" },
	Text = {
		"Text", "ContentText", "PlaceholderText", "TextColor3", "TextTransparency", "TextSize", "TextScaled",
		"TextWrapped", "TextXAlignment", "TextYAlignment", "Font", "FontFace", "LineHeight", "MaxVisibleGraphemes",
	},
	Layout = {
		"AnchorPoint", "AutomaticSize", "CanvasPosition", "CanvasSize", "Position", "Size", "LayoutOrder",
		"ZIndex", "ClipsDescendants", "ScrollBarThickness", "ScrollingDirection", "Padding", "FillDirection",
		"HorizontalAlignment", "VerticalAlignment", "SortOrder", "CellPadding", "CellSize",
	},
	Script = { "RunContext", "LinkedSource", "ScriptGuid", "Source" },
}

local READ_ONLY = {
	ClassName = true, Parent = true, ContentText = true, AbsolutePosition = true, AbsoluteSize = true,
	AssemblyCenterOfMass = true, AssemblyMass = true, AssemblyRootPart = true, CurrentDistance = true,
	CurrentAngle = true, CollisionGroupId = true, ScriptGuid = true, Source = true,
}

local EDITABLE_TYPES = {
	string = true, boolean = true, number = true, Vector2 = true, Vector3 = true,
	Color3 = true, UDim = true, UDim2 = true, CFrame = true, BrickColor = true, EnumItem = true,
}

local function envFunction(name)
	local env = _G
	if type(getgenv) == "function" then
		local ok, value = pcall(getgenv)
		if ok and type(value) == "table" then env = value end
	end
	if type(env[name]) == "function" then return env[name] end
	local ok, value = pcall(function() return _G[name] end)
	return ok and type(value) == "function" and value or nil
end

local function encode(value)
	local kind = typeof(value)
	if kind == "string" then return value end
	if kind == "Instance" then return value:GetFullName() end
	if kind == "Vector2" then return string.format("%.6g, %.6g", value.X, value.Y) end
	if kind == "Vector3" then return string.format("%.6g, %.6g, %.6g", value.X, value.Y, value.Z) end
	if kind == "Color3" then return string.format("%d, %d, %d", math.round(value.R * 255), math.round(value.G * 255), math.round(value.B * 255)) end
	if kind == "UDim" then return string.format("%.6g, %d", value.Scale, value.Offset) end
	if kind == "UDim2" then return string.format("%.6g, %d, %.6g, %d", value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset) end
	if kind == "CFrame" then
		local values = { value:GetComponents() }
		for index, item in ipairs(values) do values[index] = string.format("%.6g", item) end
		return table.concat(values, ", ")
	end
	if kind == "EnumItem" then return tostring(value) end
	return tostring(value)
end

local function numbers(text)
	local result = {}
	for value in text:gmatch("[-+]?%d*%.?%d+[eE]?[-+]?%d*") do result[#result + 1] = tonumber(value) end
	return result
end

local function parseEnum(current, text)
	local enumType = tostring(current.EnumType):match("Enum%.(.+)")
	local item = text:match("([^%.]+)$")
	if not enumType or not item then return nil, "enum inválido" end
	local ok, value = pcall(function() return Enum[enumType][item] end)
	return ok and value or nil, ok and nil or "item de enum inválido"
end

local function decode(current, text)
	local kind = typeof(current)
	if kind == "string" then return text end
	if kind == "boolean" then
		local value = text:lower()
		if value == "true" or value == "1" or value == "yes" or value == "sim" then return true end
		if value == "false" or value == "0" or value == "no" or value == "não" or value == "nao" then return false end
		return nil, "use true ou false"
	end
	if kind == "number" then return tonumber(text), tonumber(text) and nil or "número inválido" end
	local values = numbers(text)
	if kind == "Vector2" and #values >= 2 then return Vector2.new(values[1], values[2]) end
	if kind == "Vector3" and #values >= 3 then return Vector3.new(values[1], values[2], values[3]) end
	if kind == "Color3" and #values >= 3 then
		local scale = math.max(values[1], values[2], values[3]) > 1 and 255 or 1
		return Color3.new(values[1] / scale, values[2] / scale, values[3] / scale)
	end
	if kind == "UDim" and #values >= 2 then return UDim.new(values[1], values[2]) end
	if kind == "UDim2" and #values >= 4 then return UDim2.new(values[1], values[2], values[3], values[4]) end
	if kind == "CFrame" and (#values == 3 or #values == 12) then return CFrame.new(table.unpack(values)) end
	if kind == "BrickColor" then
		local ok, value = pcall(BrickColor.new, text)
		return ok and value or nil, ok and nil or "BrickColor inválida"
	end
	if kind == "EnumItem" then return parseEnum(current, text) end
	return nil, "tipo " .. kind .. " não é editável por texto"
end

local function addRow(rows, seen, instance, category, name, value, attribute)
	if seen[name] then return end
	seen[name] = true
	rows[#rows + 1] = {
		category = category, name = name, value = encode(value), raw = value,
		typeName = typeof(value), readOnly = (not attribute and READ_ONLY[name] == true) or not EDITABLE_TYPES[typeof(value)],
		attribute = attribute == true, instance = instance,
	}
end

function Properties.collect(instance)
	local rows, seen = {}, {}
	local dynamic = envFunction("getproperties")
	for _, category in ipairs(CATEGORY_ORDER) do
		for _, name in ipairs(SCHEMA[category] or {}) do
			local ok, value = pcall(function() return instance[name] end)
			if ok then addRow(rows, seen, instance, category, name, value, false) end
		end
	end
	if dynamic then
		local ok, values = pcall(dynamic, instance)
		if ok and type(values) == "table" then
			local names = {}
			for key, item in pairs(values) do
				local name = type(key) == "string" and key or (type(item) == "string" and item or nil)
				if name then names[#names + 1] = name end
			end
			table.sort(names)
			for _, name in ipairs(names) do
				local read, value = pcall(function() return instance[name] end)
				if read then addRow(rows, seen, instance, "Other", name, value, false) end
			end
		end
	end
	local attributes = instance:GetAttributes()
	local attributeNames = {}
	for name in pairs(attributes) do attributeNames[#attributeNames + 1] = name end
	table.sort(attributeNames)
	for _, name in ipairs(attributeNames) do addRow(rows, seen, instance, "Attributes", "@" .. name, attributes[name], true) end
	table.sort(rows, function(left, right)
		local li, ri = table.find(CATEGORY_ORDER, left.category) or 999, table.find(CATEGORY_ORDER, right.category) or 999
		if li ~= ri then return li < ri end
		return left.name:lower() < right.name:lower()
	end)
	return rows, dynamic and "executor + schema" or "schema local"
end

function Properties.write(entry, text)
	if entry.readOnly then return false, "propriedade somente leitura" end
	local value, reason = decode(entry.raw, text)
	if reason then return false, reason end
	local ok, err
	if entry.attribute then
		ok, err = pcall(entry.instance.SetAttribute, entry.instance, entry.name:sub(2), value)
	else
		ok, err = pcall(function() entry.instance[entry.name] = value end)
	end
	return ok, ok and nil or tostring(err)
end

return Properties
