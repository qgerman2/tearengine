Bazooka = class("Bazooka", Weapon)

function Bazooka:initialize(owner)
	Weapon.initialize(self, "Bazooka", owner)
	self.reloadTime = 0.1
end

function Bazooka:fire(angle)
	if server then
		local x, y = self.owner:getPosition()
		local vx, vy = utils.speedVector(25, angle)
		local rocket = Rocket(x + vx, y + vy, self.owner.b2World, self)
		rocket:setLinearVelocity(vx * 25, vy * 25)
		self.owner.Level:addEntity(rocket)
	end
end

function Bazooka:draw()

end