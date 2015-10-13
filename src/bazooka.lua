Bazooka = class("Bazooka", Weapon)

function Bazooka:initialize(owner)
	Weapon.initialize(self, "Bazooka", owner)
	self.reloadTime = 0.1
	self.shared = true
end

function Bazooka:fire(angle)
	if server then
		local x, y = self.owner:getPosition()
		local rocket = Box(x, y - 100, self.owner.b2World)
		self.owner.Level:addEntity(rocket)
	end
end

function Bazooka:draw()

end