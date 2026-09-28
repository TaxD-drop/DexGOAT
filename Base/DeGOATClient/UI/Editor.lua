local Theme = require(script.Parent.Theme)
local TextService = game:GetService("TextService")

local Editor = {}
Editor.__index = Editor

local function create(className, properties)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do object[key] = value end
	return object
end

function Editor.new(parent)
	local self = setmetatable({}, Editor)
	self.tabs, self.active = {}, nil
	self.fontSize, self.gutterWidth, self.lineHeight = 14, 48, 17

	self.frame = create("Frame", { BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Parent = parent })
	self.tabBar = create("ScrollingFrame", {
		BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 30),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 3, Parent = self.frame,
	})
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.tabBar })

	self.code = create("ScrollingFrame", {
		BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 1, -52),
		CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.XY, ScrollBarThickness = 9, Parent = self.frame,
	})
	self.lineNumbers = create("TextLabel", {
		BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(48, 20),
		Font = Theme.Font, TextSize = 14, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Top, Text = "1", RichText = false, Parent = self.code,
	})
	create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingRight = UDim.new(0, 7), Parent = self.lineNumbers })
	self.text = create("TextBox", {
		BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Position = UDim2.fromOffset(52, 0), Size = UDim2.fromOffset(200, 20),
		ClearTextOnFocus = false, MultiLine = true, TextEditable = false, TextWrapped = false,
		Font = Theme.Font, TextSize = 14, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		Text = "-- Selecione uma instância no Explorer", Parent = self.code,
	})
	create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), Parent = self.text })

	self.properties = create("Frame", {
		Visible = false, BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 1, -52), Parent = self.frame,
	})
	self.propertySearch = create("TextBox", {
		BackgroundColor3 = Theme.PanelAlt, BorderColor3 = Theme.Border, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, 28),
		ClearTextOnFocus = false, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text,
		PlaceholderText = "Filtrar propriedades...", PlaceholderColor3 = Theme.Muted, Text = "", Parent = self.properties,
	})
	self.propertyList = create("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 10, Parent = self.properties,
	})
	self.propertyLayout = create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.propertyList })

	self.status = create("TextLabel", {
		BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -22), Size = UDim2.new(1, 0, 0, 22),
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "  Pronto", Parent = self.frame,
	})
	self.text:GetPropertyChangedSignal("Text"):Connect(function() self:_updateLines() end)
	self.code:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_updateLines() end)
	self.propertySearch:GetPropertyChangedSignal("Text"):Connect(function()
		local tab = self.tabs[self.active]
		if tab and tab.kind == "properties" then self:_renderProperties(tab) end
	end)
	self:_updateLines()
	return self
end

function Editor:SetCompact(compact)
	self.compact = compact
	local fontSize, gutterWidth, lineHeight = compact and 12 or 14, compact and 40 or 48, compact and 15 or 17
	if self.fontSize == fontSize and self.gutterWidth == gutterWidth then return end
	self.fontSize, self.gutterWidth, self.lineHeight = fontSize, gutterWidth, lineHeight
	self.text.TextSize = fontSize
	self.lineNumbers.TextSize = fontSize
	self.text.Position = UDim2.fromOffset(gutterWidth + 4, 0)
	self:_updateLines()
	local tab = self.tabs[self.active]
	if tab and tab.kind == "properties" then self:_renderProperties(tab) end
end

function Editor:_updateLines()
	local count = 1
	for _ in self.text.Text:gmatch("\n") do count += 1 end
	local values = table.create(count)
	for index = 1, count do values[index] = tostring(index) end
	self.lineNumbers.Text = table.concat(values, "\n")
	local widest = 0
	for line in (self.text.Text .. "\n"):gmatch("(.-)\n") do
		widest = math.max(widest, TextService:GetTextSize(line, self.fontSize, Theme.Font, Vector2.new(100000, 20)).X)
	end
	local height = math.max(self.code.AbsoluteSize.Y, count * self.lineHeight + 10)
	local width = math.max(self.code.AbsoluteSize.X - self.gutterWidth - 4, widest + 24)
	self.lineNumbers.Size = UDim2.fromOffset(self.gutterWidth, height)
	self.text.Size = UDim2.fromOffset(width, height)
	self.code.CanvasSize = UDim2.fromOffset(self.gutterWidth + 4 + width, height)
end

function Editor:SetStatus(text, kind)
	self.status.Text = "  " .. text
	self.status.TextColor3 = kind == "error" and Theme.Error or kind == "success" and Theme.Success or Theme.Muted
end

function Editor:_close(key)
	local tab = self.tabs[key]
	if not tab then return end
	tab.button:Destroy()
	self.tabs[key] = nil
	if self.active ~= key then return end
	self.active = nil
	local nextKey = next(self.tabs)
	if nextKey then self:_select(nextKey) else
		self.code.Visible, self.properties.Visible = true, false
		self.text.Text = "-- Nenhuma aba aberta"
	end
end

function Editor:_makeTab(key, title)
	local holder = create("Frame", { BackgroundColor3 = Theme.PanelAlt, BorderSizePixel = 0, Size = UDim2.fromOffset(178, 30), Parent = self.tabBar })
	local selectButton = create("TextButton", {
		AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, -30, 1, 0),
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "  " .. title, Parent = holder,
	})
	local closeButton = create("TextButton", {
		AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(1, -30, 0, 0), Size = UDim2.fromOffset(30, 30),
		Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Muted, Text = "×", Parent = holder,
	})
	selectButton.MouseButton1Click:Connect(function() self:_select(key) end)
	closeButton.MouseButton1Click:Connect(function() self:_close(key) end)
	return holder, selectButton
end

function Editor:_renderProperties(tab)
	for _, child in ipairs(self.propertyList:GetChildren()) do
		if child ~= self.propertyLayout then child:Destroy() end
	end
	local query = self.propertySearch.Text:lower()
	local lastCategory, order = nil, 0
	for _, entry in ipairs(tab.rows or {}) do
		local searchable = (entry.name .. " " .. entry.category .. " " .. entry.typeName):lower()
		if query ~= "" and not searchable:find(query, 1, true) then continue end
		if entry.category ~= lastCategory then
			lastCategory, order = entry.category, order + 1
			create("TextLabel", {
				BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Size = UDim2.new(1, -10, 0, 24), LayoutOrder = order,
				Font = Enum.Font.GothamBold, TextSize = self.fontSize - 1, TextColor3 = Theme.Accent,
				TextXAlignment = Enum.TextXAlignment.Left, Text = "  " .. lastCategory, Parent = self.propertyList,
			})
		end
		order += 1
		local row = create("Frame", {
			BackgroundColor3 = order % 2 == 0 and Theme.Background or Theme.PanelAlt, BackgroundTransparency = 0.35,
			BorderSizePixel = 0, Size = UDim2.new(1, -10, 0, self.compact and 25 or 28), LayoutOrder = order, Parent = self.propertyList,
		})
		create("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(0.42, -4, 1, 0), Font = Enum.Font.Gotham,
			TextSize = self.fontSize - 2, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, Text = "  " .. entry.name, Parent = row,
		})
		local field = create("TextBox", {
			BackgroundColor3 = Theme.Panel, BackgroundTransparency = entry.readOnly and 0.7 or 0.15, BorderSizePixel = 0,
			Position = UDim2.new(0.42, 0, 0, 2), Size = UDim2.new(0.58, -4, 1, -4), ClearTextOnFocus = false,
			TextEditable = not entry.readOnly, Font = Theme.Font, TextSize = self.fontSize - 2,
			TextColor3 = entry.readOnly and Theme.Muted or Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, Text = entry.value, Parent = row,
		})
		create("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), Parent = field })
		if not entry.readOnly then
			field.FocusLost:Connect(function()
				if field.Text == entry.value then return end
				local ok, message, replacement = tab.onCommit(entry, field.Text)
				if ok then
					self:SetStatus(message or (entry.name .. " atualizado"), "success")
					if replacement then tab.rows = replacement end
					task.defer(function() if self.active == tab.key then self:_renderProperties(tab) end end)
				else
					field.Text = entry.value
					self:SetStatus(message or "não foi possível alterar", "error")
				end
			end)
		end
	end
end

function Editor:_select(key)
	local tab = self.tabs[key]
	if not tab then return end
	self.active = key
	for _, current in pairs(self.tabs) do current.button.BackgroundColor3 = current == tab and Theme.Selected or Theme.PanelAlt end
	self.code.Visible = tab.kind == "code"
	self.properties.Visible = tab.kind == "properties"
	if tab.kind == "code" then
		self.text.Text = tab.source
		self.code.CanvasPosition = Vector2.zero
		self:_updateLines()
	else
		self.propertySearch.Text = ""
		self.propertyList.CanvasPosition = Vector2.zero
		self:_renderProperties(tab)
	end
end

function Editor:OpenCode(key, title, source)
	local tab = self.tabs[key]
	if tab then
		tab.source, tab.title, tab.kind = source, title, "code"
		tab.selectButton.Text = "  " .. title
	else
		local holder, selectButton = self:_makeTab(key, title)
		tab = { key = key, button = holder, selectButton = selectButton, source = source, title = title, kind = "code" }
		self.tabs[key] = tab
	end
	self:_select(key)
end

function Editor:OpenProperties(key, title, rows, onCommit)
	local tab = self.tabs[key]
	if tab then
		tab.rows, tab.title, tab.kind, tab.onCommit = rows, title, "properties", onCommit
		tab.selectButton.Text = "  " .. title
	else
		local holder, selectButton = self:_makeTab(key, title)
		tab = { key = key, button = holder, selectButton = selectButton, rows = rows, title = title, kind = "properties", onCommit = onCommit }
		self.tabs[key] = tab
	end
	self:_select(key)
end

function Editor:Open(key, title, source)
	self:OpenCode(key, title, source)
end

function Editor:Destroy()
	self.frame:Destroy()
end

return Editor
