Projectile = class("Projectile", Entity)

function Projectile:initialize(x, y, owner)
	Entity.initialize(self, x, y)
	self.owner = owner
end

function Projectile:update(t)

end

function Projectile:draw()

end