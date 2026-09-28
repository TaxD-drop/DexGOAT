local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Theme = require(script.Parent.Theme)
local Layout = require(script.Parent.Layout)
local Explorer = require(script.Parent.Explorer)
local Editor = require(script.Parent.Editor)
local ContextMenu = require(script.Parent.ContextMenu)
local Properties = require(script.Parent.Parent.Core.Properties)
local Parser = require(script.Parent.Parent.Core.Parser)
local Decompiler = require(script.Parent.Parent.Core.Decompiler)
local BytecodeProvider = require(script.Parent.Parent.Providers.BytecodeProvider)

local App = {}
App.__index = App

local function create(className, properties)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do object[key] = value end
	return object
end

local function point2(position)
	return Vector2.new(position.X, position.Y)
end

local function environmentFunction(name)
	local env = _G
	if type(getgenv) == "function" then
		local ok, value = pcall(getgenv)
		if ok and type(value) == "table" then env = value end
	end
	if type(env[name]) == "function" then return env[name] end
	local ok, value = pcall(function() return _G[name] end)
	return ok and type(value) == "function" and value or nil
end

local function guiParent(player, config)
	if config.UseExecutorUI and type(gethui) == "function" then
		local ok, value = pcall(gethui)
		if ok and typeof(value) == "Instance" then return value end
	end
	return player:WaitForChild("PlayerGui")
end

function App:_viewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

function App:_track(connection)
	self.connections[#self.connections + 1] = connection
	return connection
end

function App:_bindCamera()
	if self.viewportConnection then self.viewportConnection:Disconnect() end
	local camera = workspace.CurrentCamera
	if camera then
		self.viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			self:_fitToViewport(false)
			self.menu:Hide()
		end)
	end
end

function App:_fitToViewport(resetSize)
	if not self.window or not self.window.Parent then return end
	local viewport = self:_viewport()
	local current = self.window.AbsoluteSize
	local result = Layout.window(viewport.X, viewport.Y, self.config, current.X, current.Y, resetSize)
	self.window.Size = UDim2.fromOffset(result.width, result.height)
	self.window.Position = UDim2.fromOffset(result.x, result.y)
	self:_applyLayout()
end

function App:_applyLayout()
	if not self.window or not self.window.Parent then return end
	local size = self.window.AbsoluteSize
	local layout = Layout.panels(size.X, size.Y, self.config, self.explorerVisible)
	local compact, narrow = layout.compact, layout.narrow
	self.compact, self.narrow = compact, narrow
	local explorerWidth = layout.explorerWidth

	self.left.Visible = layout.leftVisible
	self.left.Size = UDim2.new(0, explorerWidth, 1, 0)
	self.divider.Visible = layout.dividerVisible
	self.divider.Position = UDim2.fromOffset(explorerWidth, 0)
	self.right.Visible = layout.rightVisible
	self.right.Position = UDim2.fromOffset(layout.rightOffset, 0)
	self.right.Size = UDim2.new(1, layout.rightInset, 1, 0)
	self.title.TextSize = compact and 12 or 14
	self.explorer:SetCompact(compact)
	self.editor:SetCompact(compact)
end

function App:SetExplorerVisible(visible)
	self.explorerVisible = visible
	self.sidebar.Text = visible and "◀" or "☰"
	self:_applyLayout()
end

function App:_makePrompt()
	self.promptShade = create("Frame", {
		Visible = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35,
		BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 150, Parent = self.gui,
	})
	local dismiss = create("TextButton", {
		AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1), Text = "", ZIndex = 150, Parent = self.promptShade,
	})
	self.prompt = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(330, 150),
		BackgroundColor3 = Theme.PanelAlt, BorderColor3 = Theme.Border, ZIndex = 151, Parent = self.promptShade,
	})
	self.promptTitle = create("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 30),
		Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Ação", ZIndex = 152, Parent = self.prompt,
	})
	self.promptInput = create("TextBox", {
		BackgroundColor3 = Theme.Background, BorderColor3 = Theme.Border, Position = UDim2.fromOffset(12, 45), Size = UDim2.new(1, -24, 0, 34),
		ClearTextOnFocus = false, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text, Text = "", ZIndex = 152, Parent = self.prompt,
	})
	self.promptCancel = create("TextButton", {
		AutoButtonColor = false, BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Position = UDim2.new(1, -176, 1, -45), Size = UDim2.fromOffset(76, 32),
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, Text = "Cancelar", ZIndex = 152, Parent = self.prompt,
	})
	self.promptConfirm = create("TextButton", {
		AutoButtonColor = false, BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Position = UDim2.new(1, -92, 1, -45), Size = UDim2.fromOffset(80, 32),
		Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Text, Text = "Confirmar", ZIndex = 152, Parent = self.prompt,
	})
	self.promptCancel.MouseButton1Click:Connect(function() self.promptShade.Visible = false end)
	dismiss.MouseButton1Click:Connect(function() self.promptShade.Visible = false end)
	self.promptConfirm.MouseButton1Click:Connect(function()
		local callback, text = self.promptCallback, self.promptInput.Text
		self.promptShade.Visible = false
		if callback then callback(text) end
	end)
end

function App:_promptAction(title, initialValue, confirmText, callback, hideInput, danger)
	self.menu:Hide()
	self.promptTitle.Text = title
	self.promptInput.Visible = not hideInput
	self.promptInput.Text = initialValue or ""
	self.promptConfirm.Text = confirmText or "Confirmar"
	self.promptConfirm.BackgroundColor3 = danger and Theme.Error or Theme.Accent
	self.promptCallback = callback
	local viewport = self:_viewport()
	self.prompt.Size = UDim2.fromOffset(math.min(330, math.max(250, viewport.X - 32)), hideInput and 112 or 150)
	self.promptShade.Visible = true
	if not hideInput then task.defer(function() self.promptInput:CaptureFocus() end) end
end

function App:_clone(instance)
	local okArchivable, wasArchivable = pcall(function() return instance.Archivable end)
	if okArchivable and not wasArchivable then pcall(function() instance.Archivable = true end) end
	local ok, clone = pcall(instance.Clone, instance)
	if okArchivable and not wasArchivable then pcall(function() instance.Archivable = false end) end
	return ok and clone or nil, ok and nil or tostring(clone)
end

function App:_copy(instance)
	local clone, reason = self:_clone(instance)
	if not clone then self.editor:SetStatus("falha ao copiar: " .. reason, "error") return end
	self.clipboard = { template = clone, source = instance }
	self.editor:SetStatus(instance.Name .. " copiado", "success")
end

function App:_pasteInto(parent)
	if not self.clipboard or not self.clipboard.template then return end
	local clone, reason = self:_clone(self.clipboard.template)
	if not clone then self.editor:SetStatus("falha ao clonar: " .. reason, "error") return end
	local ok, err = pcall(function() clone.Parent = parent end)
	if not ok then clone:Destroy() self.editor:SetStatus("não foi possível colar: " .. tostring(err), "error") return end
	self.editor:SetStatus(clone.Name .. " colado em " .. parent.Name, "success")
	self.explorer.expanded[parent] = true
	self.explorer:Refresh()
end

function App:_copyPath(instance)
	local path = instance:GetFullName()
	local setclipboard = environmentFunction("setclipboard") or environmentFunction("toclipboard")
	if setclipboard then
		local ok, err = pcall(setclipboard, path)
		self.editor:SetStatus(ok and "caminho copiado" or ("falha no clipboard: " .. tostring(err)), ok and "success" or "error")
	else
		self.editor:OpenCode({}, "Path", path)
		self.editor:SetStatus("clipboard indisponível; caminho aberto em uma aba")
	end
end

function App.new(root, config)
	local self = setmetatable({}, App)
	self.config = config
	self.cache = setmetatable({}, { __mode = "k" })
	self.propertyKeys = setmetatable({}, { __mode = "k" })
	self.scriptKeys = setmetatable({}, { __mode = "k" })
	self.connections = {}
	self.explorerVisible = true
	self.provider = BytecodeProvider.new(config)
	local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

	self.gui = create("ScreenGui", {
		Name = "DeGOATExplorer", ResetOnSpawn = false, IgnoreGuiInset = true,
		DisplayOrder = 50, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = guiParent(player, config),
	})
	config.IgnoreInstance = self.gui
	self.window = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.Background,
		BorderColor3 = Theme.Border, ClipsDescendants = true,
		Size = config.InitialSize, Position = UDim2.fromScale(0.5, 0.5), Parent = self.gui,
	})
	self.title = create("TextLabel", {
		BackgroundColor3 = Theme.PanelAlt, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 34),
		Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "           " .. config.Title, Parent = self.window,
	})
	self.sidebar = create("TextButton", {
		AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(42, 34),
		Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Text, Text = "◀", Parent = self.title,
	})
	local close = create("TextButton", {
		BackgroundTransparency = 1, Position = UDim2.new(1, -40, 0, 0), Size = UDim2.fromOffset(40, 34),
		Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Theme.Muted, Text = "×", Parent = self.title,
	})
	local body = create("Frame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 1, -34), Parent = self.window,
	})
	self.left = create("Frame", { BackgroundTransparency = 1, Parent = body })
	self.divider = create("Frame", { BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Size = UDim2.new(0, 1, 1, 0), Parent = body })
	self.right = create("Frame", { BackgroundTransparency = 1, Parent = body })
	local resize = create("TextButton", {
		AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(22, 22), Font = Enum.Font.GothamBold,
		TextSize = 12, TextColor3 = Theme.Muted, Text = "◢", ZIndex = 10, Parent = self.window,
	})

	self.editor = Editor.new(self.right)
	self.menu = ContextMenu.new(self.gui, function() return self:_viewport() end)
	self:_makePrompt()
	self.explorer = Explorer.new(self.left, config, function(instance) self:Select(instance) end, function(instance, position) self:ShowContext(instance, position) end)

	self.sidebar.MouseButton1Click:Connect(function() self:SetExplorerVisible(not self.explorerVisible) end)
	close.MouseButton1Click:Connect(function() self.gui.Enabled = false self.menu:Hide() end)
	local capability, available = self.provider:GetCapability()
	self.editor:SetStatus(available and ("bytecode local: " .. capability) or "getscriptbytecode não disponível", available and "success" or "error")

	local dragMode, dragInput, startInput, startCenter, startSize, startTopLeft
	self.title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragMode, dragInput, startInput = "move", input, point2(input.Position)
			startCenter = self.window.AbsolutePosition + self.window.AbsoluteSize / 2
		end
	end)
	resize.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragMode, dragInput, startInput = "resize", input, point2(input.Position)
			startSize, startTopLeft = self.window.AbsoluteSize, self.window.AbsolutePosition
		end
	end)
	self:_track(UserInputService.InputChanged:Connect(function(input)
		if not dragMode then return end
		local relevant = input == dragInput or (dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)
		if not relevant then return end
		local viewport, padding = self:_viewport(), config.ScreenPadding
		if dragMode == "move" then
			local half = self.window.AbsoluteSize / 2
			local desired = startCenter + (point2(input.Position) - startInput)
			local x = math.clamp(desired.X, padding + half.X, math.max(padding + half.X, viewport.X - padding - half.X))
			local y = math.clamp(desired.Y, padding + half.Y, math.max(padding + half.Y, viewport.Y - padding - half.Y))
			self.window.Position = UDim2.fromOffset(x, y)
		else
			local delta = point2(input.Position) - startInput
			local maximumWidth, maximumHeight = math.max(1, viewport.X - padding * 2), math.max(1, viewport.Y - padding * 2)
			local minimumWidth, minimumHeight = math.min(config.MinimumWidth, maximumWidth), math.min(config.MinimumHeight, maximumHeight)
			local width = math.clamp(startSize.X + delta.X, minimumWidth, maximumWidth)
			local height = math.clamp(startSize.Y + delta.Y, minimumHeight, maximumHeight)
			self.window.Size = UDim2.fromOffset(width, height)
			self.window.Position = UDim2.fromOffset(startTopLeft.X + width / 2, startTopLeft.Y + height / 2)
		end
	end))
	self:_track(UserInputService.InputEnded:Connect(function(input)
		if not dragMode then return end
		if input == dragInput or (dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1) then
			dragMode, dragInput = nil, nil
		end
	end))
	self:_track(UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == config.ToggleKey then self.gui.Enabled = not self.gui.Enabled end
	end))
	self:_track(self.window:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_applyLayout() end))
	self:_track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() self:_bindCamera() self:_fitToViewport(false) end))
	self:_bindCamera()
	task.defer(function() self:_fitToViewport(true) end)
	return self
end

function App:RegisterBytecode(instance, raw) self.provider:Register(instance, raw) self.cache[instance] = nil end
function App:SetBytecodeResolver(resolver) self.provider:SetResolver(resolver) self.cache = setmetatable({}, { __mode = "k" }) end

function App:ShowContext(instance, position)
	local isScript = self.provider:IsScript(instance)
	local canDelete = instance.Parent ~= game
	self.menu:Show(position, {
		{ label = "View Script", visible = isScript, callback = function() self:ViewScript(instance) end },
		{ label = "Properties", callback = function() self:Select(instance) end },
		{ label = "Copy Path", callback = function() self:_copyPath(instance) end },
		{ label = "Rename", callback = function()
			self:_promptAction("Renomear " .. instance.Name, instance.Name, "Renomear", function(value)
				if value == "" then self.editor:SetStatus("o nome não pode ficar vazio", "error") return end
				local ok, err = pcall(function() instance.Name = value end)
				self.editor:SetStatus(ok and "instância renomeada" or tostring(err), ok and "success" or "error")
				if ok then self.explorer:Refresh() self:Select(instance) end
			end)
		end },
		{ label = "Copy", callback = function() self:_copy(instance) end },
		{ label = "Paste Into", enabled = self.clipboard ~= nil, callback = function() self:_pasteInto(instance) end },
		{ label = "Duplicate", enabled = canDelete, callback = function()
			local clone, reason = self:_clone(instance)
			if not clone then self.editor:SetStatus("falha ao duplicar: " .. reason, "error") return end
			local ok, err = pcall(function() clone.Parent = instance.Parent end)
			if not ok then clone:Destroy() end
			self.editor:SetStatus(ok and (instance.Name .. " duplicado") or tostring(err), ok and "success" or "error")
		end },
		{ label = "Delete", enabled = canDelete, danger = true, callback = function()
			self:_promptAction("Excluir " .. instance.Name .. "?", "", "Excluir", function()
				local ok, err = pcall(instance.Destroy, instance)
				self.editor:SetStatus(ok and "instância excluída do cliente" or tostring(err), ok and "success" or "error")
			end, true, true)
		end },
	})
end

function App:Select(instance)
	self.menu:Hide()
	if self.narrow then self:SetExplorerVisible(false) end
	local key = self.propertyKeys[instance]
	if not key then key = {} self.propertyKeys[instance] = key end
	local rows, source = Properties.collect(instance)
	self.editor:OpenProperties(key, instance.Name, rows, function(entry, text)
		local ok, reason = Properties.write(entry, text)
		if not ok then return false, reason end
		self.explorer:Refresh()
		local replacement = Properties.collect(instance)
		return true, entry.name .. " atualizado", replacement
	end)
	self.editor:SetStatus(string.format("%s · %d propriedades · %s", instance.ClassName, #rows, source))
end

function App:ViewScript(instance)
	self.menu:Hide()
	if self.compact then self:SetExplorerVisible(false) end
	local key = self.scriptKeys[instance]
	if not key then key = {} self.scriptKeys[instance] = key end
	local cached = self.cache[instance]
	if cached then self.editor:OpenCode(key, instance.Name .. " · Source", cached) self.editor:SetStatus("cache local", "success") return end
	self.editor:SetStatus("decompilando " .. instance.Name .. "...")
	task.spawn(function()
		local bytecode, reason = self.provider:GetBytecode(instance)
		if not bytecode then
			local message = "-- Não foi possível decompilar " .. instance:GetFullName() .. "\n-- " .. reason .. "\n\n-- O DeGOAT precisa de getscriptbytecode no ambiente para obter os bytes brutos."
			self.editor:OpenCode(key, instance.Name .. " · Source", message)
			self.editor:SetStatus(reason, "error")
			return
		end
		local started = os.clock()
		local ok, result = pcall(function() return Decompiler.decompile(Parser.parse(bytecode)) end)
		if ok then
			self.cache[instance] = result
			self.editor:OpenCode(key, instance.Name .. " · Source", result)
			self.editor:SetStatus(string.format("decompilado localmente em %.3fs", os.clock() - started), "success")
		else
			self.editor:OpenCode(key, instance.Name .. " · Source", "-- Falha DeGOAT\n-- " .. tostring(result))
			self.editor:SetStatus("falha no parser/decompiler", "error")
		end
	end)
end

function App:Toggle() self.gui.Enabled = not self.gui.Enabled end

function App:Destroy()
	for _, connection in ipairs(self.connections) do connection:Disconnect() end
	if self.viewportConnection then self.viewportConnection:Disconnect() end
	self.connections = {}
	if self.clipboard and self.clipboard.template then pcall(self.clipboard.template.Destroy, self.clipboard.template) end
	self.menu:Destroy()
	self.explorer:Destroy()
	self.editor:Destroy()
	self.gui:Destroy()
end

return App
