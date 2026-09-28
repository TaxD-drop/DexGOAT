local GestureState = {}
GestureState.__index = GestureState

function GestureState.new(tolerance)
	return setmetatable({ tolerance = tolerance or 8, serial = 0, active = nil }, GestureState)
end

function GestureState:Begin(owner, x, y)
	self:Cancel()
	local state = {
		owner = owner, startX = x, startY = y, lastX = x, lastY = y,
		status = "pressed", token = self.serial,
	}
	self.active = state
	return state
end

function GestureState:Move(state, x, y)
	if self.active ~= state or state.status ~= "pressed" then return state.status end
	state.lastX, state.lastY = x, y
	local dx, dy = x - state.startX, y - state.startY
	if dx * dx + dy * dy > self.tolerance * self.tolerance then
		state.status = "cancelled"
		self.serial += 1
	end
	return state.status
end

function GestureState:Hold(state)
	if self.active ~= state or state.status ~= "pressed" or state.token ~= self.serial then return false end
	state.status = "held"
	return true
end

function GestureState:Release(state)
	if self.active ~= state then return "cancelled" end
	self.active = nil
	self.serial += 1
	local status = state.status
	state.status = "released"
	if status == "pressed" then return "click" end
	if status == "held" then return "held" end
	return "cancelled"
end

function GestureState:Cancel()
	self.serial += 1
	if self.active then self.active.status = "cancelled" end
	self.active = nil
end

return GestureState
