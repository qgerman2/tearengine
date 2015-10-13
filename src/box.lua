Box = class("Box", Entity)

function Box:initialize(x, y, b2World)
	Entity.initialize(self, x, y)
	self.kind = "Box"
	self:b2Physics(b2World)
	self.boxBase = self:b2Shape(love.physics.newCircleShape(10))
	self.boxBase.b2Fixture:setRestitution(0.9)
end

function Box:b2BeginContact(fixtureA, fixtureB, contact)
	if server then
		local ShapeA = fixtureA:getUserData()
		local ShapeB = fixtureB:getUserData()
		if ShapeA.entity and ShapeA.entity.kind == "Unit" or ShapeB.entity and ShapeB.entity.kind == "Unit" then
			self.Level:removeEntity(self.id)
		end
	end
end