local Theme = require(script.Parent.Theme)
local UserInputService = game:GetService("UserInputService")

local ContextMenu = {}
ContextMenu.__index = ContextMenu

local function create(className, properties)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do object[key] = value end
	return object
end

function ContextMenu.new(parent, viewportProvider)
	local self = setmetatable({}, ContextMenu)
	self.viewportProvider = viewportProvider
	self.frame = create("Frame", {
		Visible = false, BackgroundColor3 = Theme.PanelAlt, BorderColor3 = Theme.Border,
		Size = UDim2.fromOffset(210, 10), ZIndex = 100, Parent = parent,
	})
	self.layout = create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1), Parent = self.frame })
	create("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), Parent = self.frame })
	self.connection = UserInputService.InputBegan:Connect(function(input)
		if not self.frame.Visible then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local point, position, size = input.Position, self.frame.AbsolutePosition, self.frame.AbsoluteSize
		if point.X < position.X or point.Y < position.Y or point.X > position.X + size.X or point.Y > position.Y + size.Y then
			self:Hide()
		end
	end)
	return self
end

function ContextMenu:Show(position, actions)
	for _, child in ipairs(self.frame:GetChildren()) do
		if child ~= self.layout and not child:IsA("UIPadding") then child:Destroy() end
	end
	local visibleActions = {}
	for _, action in ipairs(actions) do if action.visible ~= false then visibleActions[#visibleActions + 1] = action end end
	local height = #visibleActions * 31 + math.max(0, #visibleActions - 1) + 6
	self.frame.Size = UDim2.fromOffset(210, height)
	local viewport = self.viewportProvider()
	self.frame.Position = UDim2.fromOffset(
		math.clamp(position.X, 0, math.max(0, viewport.X - 214)),
		math.clamp(position.Y, 0, math.max(0, viewport.Y - height - 4))
	)
	for index, action in ipairs(visibleActions) do
		local enabled = action.enabled ~= false
		local button = create("TextButton", {
			AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 31),
			LayoutOrder = index, Font = Enum.Font.Gotham, TextSize = 12,
			TextColor3 = not enabled and Theme.Muted or (action.danger and Theme.Error or Theme.Text),
			TextXAlignment = Enum.TextXAlignment.Left, Text = "   " .. action.label, ZIndex = 101, Parent = self.frame,
		})
		if enabled then
			button.MouseEnter:Connect(function() button.BackgroundTransparency = 0.35 button.BackgroundColor3 = Theme.Selected end)
			button.MouseLeave:Connect(function() button.BackgroundTransparency = 1 end)
			button.MouseButton1Click:Connect(function()
				self:Hide()
				action.callback()
			end)
		end
	end
	self.frame.Visible = true
end

function ContextMenu:Hide()
	self.frame.Visible = false
end

function ContextMenu:Destroy()
	if self.connection then self.connection:Disconnect() end
	self.frame:Destroy()
end

return ContextMenu
