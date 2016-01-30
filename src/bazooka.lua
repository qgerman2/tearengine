Bazooka = class("Bazooka", Weapon)

function Bazooka:initialize(owner)
	Weapon.initialize(self, "Bazooka", owner)
	self.anim = BazookaAnim(self)
	self.reloadTime = 0.5
end

function Bazooka:fire(angle)
	if server then
		local x, y = self.owner.b2Body:getPosition()
		local vx, vy = utils.speedToVelocity(20, angle)
		local rocket = Rocket(x + vx, y - 7 + vy, self.owner.b2World, self)
		rocket.b2Body:setLinearVelocity(vx * 30, vy * 30)
		self.owner.Level:addEntity(rocket)
	end
end

function Bazooka:draw()
	self.anim:draw()
end