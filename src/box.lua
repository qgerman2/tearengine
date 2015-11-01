Box = class("Box", Entity)

function Box:initialize(x, y, b2World)
	Entity.initialize(self, x, y)
	self.kind = "Box"
	self:b2Physics(b2World)
	self.boxBase = self:b2Shape(love.physics.newCircleShape(5))
	self.boxBase.b2Fixture:setRestitution(0.5)
	self.projectile = true
end

function Box:b2BeginContact(fixtureA, fixtureB, contact)
	if server then
		local ShapeA = fixtureA:getUserData()
		local ShapeB = fixtureB:getUserData()
		local unit = false
		if ShapeA.entity and ShapeA.entity.kind == "Unit" then unit = ShapeA.entity
		elseif ShapeB.entity and ShapeB.entity.kind == "Unit" then unit = ShapeB.entity end
		if unit and not unit.updateHealth then
			self.Level:removeEntity(self.id)
			unit.health = unit.health - 1
			unit.updateHealth = true --fix me
		end
	end
end