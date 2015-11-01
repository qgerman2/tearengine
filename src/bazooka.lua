Bazooka = class("Bazooka", Weapon)

function Bazooka:initialize(owner)
	Weapon.initialize(self, "Bazooka", owner)
	self.reloadTime = 0.1
	self.shared = true
end

function Bazooka:fire(angle)
	if server then
		local x, y = self.owner:getPosition()
		local vx, vy = utils.speedVector(25, angle)
		local rocket = Box(x + vx, y + vy, self.owner.b2World)
		rocket:setLinearVelocity(vx * 25, vy * 25)
		rocket.owner = self.owner
		self.owner.Level:addEntity(rocket)
	end
end

function Bazooka:draw()

end