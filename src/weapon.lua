Weapon = class("Weapon")

function Weapon:initialize(name, owner)
	self.name = name
	self.owner = owner
	self.level = owner.level

	self.timer = 0
	self.reloadTime = 2
	self.loaded = true
end

function Weapon:wep_fire(angle)
	if not self.loaded then return end
	if self.fire then self:fire(angle) end
	self.loaded = false
end

function Weapon:wep_cancel()
	if self.cancel then self:cancel() end
end

function Weapon:wep_update(dt)
	if not self.loaded then
		if self.timer <= 0 then
			self.loaded = true
			self.timer = self.reloadTime
		else
			self.timer = self.timer - dt
		end
	end
	if self.update then self:update(dt) end
end

function Weapon:wep_draw()
	if self.draw then self:draw() end
end