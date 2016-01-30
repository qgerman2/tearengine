Rocket = class("Rocket", Entity)

function Rocket:initialize(x, y, b2World, source)
	Entity.initialize(self, x, y)
	self.anim = RocketAnim(self)
	self.source = source
	self.projectile = true
	self:b2Physics(b2World)
	self.b2Body:setGravityScale(0)
	self.boxBase = self:b2Shape(love.physics.newCircleShape(5))
	self.boxBase.b2Fixture:setRestitution(0.75)
	self:b2Category({3})
end

function Rocket:b2BeginContact(fixtureA, fixtureB, contact)
	if server then
		local ShapeA = fixtureA:getUserData()
		local ShapeB = fixtureB:getUserData()
		local unit = false
		if ShapeA.entity and ShapeA.entity.class.name == "Unit" then unit = ShapeA.entity
		elseif ShapeB.entity and ShapeB.entity.class.name == "Unit" then unit = ShapeB.entity end
		if unit == self.source.owner then contact:setEnabled(false); return false end
		if unit and not unit.updateHealth then
			self.Level:removeEntity(self.id)
			unit.health = unit.health - 1
			unit.updateHealth = true --fix me
		end
		local x, y = self.b2Body:getPosition()
		self.Level:carveTerrain(x, y, 50)
		self.Level:removeEntity(self.id)
	end
end

function Rocket:update(t)
	self.anim:update(t)
end

function Rocket:draw()
	self.anim:draw()
end