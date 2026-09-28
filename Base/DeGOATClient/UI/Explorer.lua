local Theme = require(script.Parent.Theme)
local IconProvider = require(script.Parent.IconProvider)
local GestureState = require(script.Parent.GestureState)
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local Explorer = {}
Explorer.__index = Explorer

local function create(className, properties)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do object[key] = value end
	return object
end

local function point2(position)
	return Vector2.new(position.X, position.Y)
end

local function sortChildren(children)
	table.sort(children, function(a, b)
		local left, right = a.Name:lower(), b.Name:lower()
		if left == right then return a.ClassName < b.ClassName end
		return left < right
	end)
	return children
end

function Explorer.new(parent, config, onSelected, onContext)
	local self = setmetatable({}, Explorer)
	self.config, self.onSelected, self.onContext = config, onSelected, onContext
	self.expanded, self.rows, self.connections = {}, {}, {}
	self.rowHeight, self.fontSize = config.RowHeight, 12
	self.iconProvider = IconProvider.new(config)
	self.gestureState = GestureState.new(config.GestureMoveTolerance)
	self.frame = create("Frame", { BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, ClipsDescendants = true, Size = UDim2.fromScale(1, 1), Parent = parent })
	self.search = create("TextBox", {
		BackgroundColor3 = Theme.PanelAlt, BorderColor3 = Theme.Border,
		Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, 28), ClearTextOnFocus = false,
		Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text,
		PlaceholderText = "Pesquisar instâncias...", PlaceholderColor3 = Theme.Muted, Text = "", Parent = self.frame,
	})
	self.list = create("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
		Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40), CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.XY, ScrollBarThickness = config.ScrollBarThickness,
		ScrollBarImageColor3 = Theme.Muted, Parent = self.frame,
	})
	self.layout = create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.list })
	self.scrollUp = create("TextButton", {
		AutoButtonColor = false, BackgroundColor3 = Theme.PanelAlt, BackgroundTransparency = 0.08,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -config.ScrollBarThickness, 0, 41),
		Size = UDim2.fromOffset(25, 24), Font = Enum.Font.GothamBold, TextSize = 10,
		TextColor3 = Theme.Text, Text = "▲", ZIndex = 20, Parent = self.frame,
	})
	self.scrollDown = create("TextButton", {
		AutoButtonColor = false, BackgroundColor3 = Theme.PanelAlt, BackgroundTransparency = 0.08,
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -config.ScrollBarThickness, 1, -2),
		Size = UDim2.fromOffset(25, 24), Font = Enum.Font.GothamBold, TextSize = 10,
		TextColor3 = Theme.Text, Text = "▼", ZIndex = 20, Parent = self.frame,
	})
	self.connections[#self.connections + 1] = self.search:GetPropertyChangedSignal("Text"):Connect(function() self:Refresh() end)
	self.connections[#self.connections + 1] = self.list:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_scheduleRefresh() end)
	self.connections[#self.connections + 1] = game.DescendantAdded:Connect(function(instance)
		if instance.Parent == game or self.expanded[instance.Parent] then self:_scheduleRefresh() end
	end)
	self.connections[#self.connections + 1] = game.DescendantRemoving:Connect(function(instance)
		if self.rows[instance] then self:_scheduleRefresh() end
	end)
	self.connections[#self.connections + 1] = UserInputService.InputChanged:Connect(function(input) self:_gestureMoved(input) end)
	self.connections[#self.connections + 1] = UserInputService.InputEnded:Connect(function(input) self:_gestureEnded(input) end)
	self.scrollUp.MouseButton1Click:Connect(function() self:_scroll(-1) end)
	self.scrollDown.MouseButton1Click:Connect(function() self:_scroll(1) end)
	self:Refresh()
	return self
end

function Explorer:SetCompact(compact)
	local rowHeight, fontSize = compact and 22 or self.config.RowHeight, compact and 11 or 12
	if rowHeight == self.rowHeight and fontSize == self.fontSize then return end
	self.rowHeight, self.fontSize = rowHeight, fontSize
	self.search.TextSize = compact and 12 or 13
	self:Refresh()
end

function Explorer:_roots()
	local result = {}
	for _, serviceName in ipairs(self.config.RootServices) do
		local ok, service = pcall(game.GetService, game, serviceName)
		if ok and service then result[#result + 1] = service end
	end
	return result
end

function Explorer:_children(parent)
	local ok, children = pcall(parent.GetChildren, parent)
	return ok and sortChildren(children) or {}
end

function Explorer:_ignored(instance)
	return instance == self.config.IgnoreInstance or (self.config.IgnoreInstance and instance:IsDescendantOf(self.config.IgnoreInstance))
end

function Explorer:_flattenExpanded(parent, depth, result)
	for _, child in ipairs(self:_children(parent)) do
		if self:_ignored(child) then continue end
		result[#result + 1] = { instance = child, depth = depth }
		if self.expanded[child] then self:_flattenExpanded(child, depth + 1, result) end
	end
end

function Explorer:_flattenSearch(instance, depth, result, query)
	if self:_ignored(instance) then return false end
	local descendants = {}
	for _, child in ipairs(self:_children(instance)) do self:_flattenSearch(child, depth + 1, descendants, query) end
	local matches = instance.Name:lower():find(query, 1, true) or instance.ClassName:lower():find(query, 1, true)
	if not matches and #descendants == 0 then return false end
	result[#result + 1] = { instance = instance, depth = depth }
	for _, row in ipairs(descendants) do result[#result + 1] = row end
	return true
end

function Explorer:_scheduleRefresh()
	if self.refreshPending then return end
	self.refreshPending = true
	task.defer(function()
		self.refreshPending = false
		if self.frame.Parent then self:Refresh() end
	end)
end

function Explorer:_fallbackIcon(instance)
	if instance:IsA("LuaSourceContainer") then return "◆" end
	if instance:IsA("BasePart") then return "▣" end
	if instance:IsA("Model") then return "◇" end
	if instance:IsA("Folder") then return "▤" end
	if instance.Parent == game then return "▧" end
	return "•"
end

function Explorer:_updateSelection()
	for instance, row in pairs(self.rows) do
		if typeof(row) == "Instance" and row.Parent then row.BackgroundTransparency = self.selected == instance and 0.25 or 1 end
	end
end

function Explorer:_cancelGesture()
	self.gestureState:Cancel()
	self.gesture = nil
end

function Explorer:_beginGesture(button, instance, input, hasChildren)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	self:_cancelGesture()
	local point = point2(input.Position)
	local gesture = self.gestureState:Begin(input, point.X, point.Y)
	gesture.button, gesture.instance, gesture.input, gesture.hasChildren = button, instance, input, hasChildren
	self.gesture = gesture
	task.delay(self.config.LongPressSeconds, function()
		if self.gesture ~= gesture or not button.Parent or not self.gestureState:Hold(gesture) then return end
		self.selected = instance
		self:_updateSelection()
		self.onContext(instance, Vector2.new(gesture.lastX + 8, gesture.lastY + 8))
	end)
end

function Explorer:_gestureMoved(input)
	local gesture = self.gesture
	if not gesture or gesture.status ~= "pressed" then return end
	local relevant = input == gesture.input
	if gesture.input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement then relevant = true end
	if not relevant then return end
	local point = point2(input.Position)
	self.gestureState:Move(gesture, point.X, point.Y)
end

function Explorer:_gestureEnded(input)
	local gesture = self.gesture
	if not gesture then return end
	local relevant = input == gesture.input
	if gesture.input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1 then relevant = true end
	if not relevant then return end
	self.gesture = nil
	local outcome = self.gestureState:Release(gesture)
	if outcome ~= "click" or not gesture.button.Parent then return end
	self.selected = gesture.instance
	if gesture.hasChildren then self.expanded[gesture.instance] = not self.expanded[gesture.instance] end
	self:Refresh()
	self.onSelected(gesture.instance)
end

function Explorer:_scroll(direction)
	local step = self.rowHeight * self.config.ScrollStepRows
	local maximum = math.max(0, self.list.AbsoluteCanvasSize.Y - self.list.AbsoluteSize.Y)
	self.list.CanvasPosition = Vector2.new(self.list.CanvasPosition.X, math.clamp(self.list.CanvasPosition.Y + direction * step, 0, maximum))
end

function Explorer:Refresh()
	self:_cancelGesture()
	for _, row in pairs(self.rows) do if typeof(row) == "Instance" then row:Destroy() end end
	self.rows = {}
	local flat, query = {}, self.search.Text:lower()
	if query ~= "" then
		for _, service in ipairs(self:_roots()) do self:_flattenSearch(service, 0, flat, query) end
	else
		for _, service in ipairs(self:_roots()) do
			flat[#flat + 1] = { instance = service, depth = 0 }
			if self.expanded[service] then self:_flattenExpanded(service, 1, flat) end
		end
	end

	local maximumWidth = math.max(1, self.list.AbsoluteSize.X)
	for order, node in ipairs(flat) do
		local instance, depth = node.instance, node.depth
		local hasChildren = #self:_children(instance) > 0
		local indent = 7 + depth * 15
		local measured = TextService:GetTextSize(instance.Name, self.fontSize, Enum.Font.Gotham, Vector2.new(100000, self.rowHeight)).X
		local rowWidth = math.max(maximumWidth, indent + 46 + measured)
		maximumWidth = math.max(maximumWidth, rowWidth)
		local selected = self.selected == instance
		local button = create("TextButton", {
			AutoButtonColor = false, BackgroundColor3 = Theme.Selected, BackgroundTransparency = selected and 0.25 or 1,
			BorderSizePixel = 0, Size = UDim2.fromOffset(rowWidth, self.rowHeight), Text = "", LayoutOrder = order, Parent = self.list,
		})
		create("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(indent, 0), Size = UDim2.fromOffset(15, self.rowHeight),
			Font = Enum.Font.GothamBold, TextSize = self.fontSize - 1, TextColor3 = Theme.Muted,
			Text = hasChildren and (self.expanded[instance] and "▼" or "▶") or "", Parent = button,
		})
		local icon = create("ImageLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(indent + 18, math.floor((self.rowHeight - 16) / 2)),
			Size = UDim2.fromOffset(16, 16), Image = "", ScaleType = Enum.ScaleType.Fit, Parent = button,
		})
		local fallback = create("TextLabel", {
			BackgroundTransparency = 1, Position = icon.Position, Size = icon.Size, Font = Enum.Font.GothamBold,
			TextSize = self.fontSize, TextColor3 = Theme.Muted, Text = self:_fallbackIcon(instance), Parent = button,
		})
		local function applyIcon(assetId)
			if not button.Parent or not assetId then return end
			icon.Image = assetId
			fallback.Visible = false
		end
		local immediate = self.iconProvider:Get(instance, applyIcon)
		if immediate then applyIcon(immediate) end
		create("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(indent + 39, 0), Size = UDim2.new(1, -indent - 39, 1, 0),
			Font = Enum.Font.Gotham, TextSize = self.fontSize, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.None, Text = instance.Name, Parent = button,
		})
		button.MouseEnter:Connect(function() button.BackgroundTransparency = 0.45 end)
		button.MouseLeave:Connect(function() button.BackgroundTransparency = self.selected == instance and 0.25 or 1 end)
		button.InputBegan:Connect(function(input) self:_beginGesture(button, instance, input, hasChildren) end)
		button.MouseButton2Click:Connect(function()
			self:_cancelGesture()
			self.selected = instance
			self:_updateSelection()
			self.onContext(instance, UserInputService:GetMouseLocation())
		end)
		self.rows[instance] = button
	end
	self.list.CanvasSize = UDim2.fromOffset(maximumWidth, #flat * self.rowHeight)
end

function Explorer:Destroy()
	self:_cancelGesture()
	for _, connection in ipairs(self.connections) do connection:Disconnect() end
	self.connections = {}
	self.frame:Destroy()
end

return Explorer
