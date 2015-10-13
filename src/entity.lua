Entity = class("Entity")

function Entity:initialize(x, y)
	self.kind = "undefined"
	self.active = false
	self.shared = true
	self.x, self.y = x, y
	self.r = 0
	self.vx, self.vy = 0, 0
	self.vr = 0
end

function Entity:destroy()
	if self.b2Body then
		self.b2Body:destroy()
	end
end

function Entity:setActive(active)
	if not active then
		self.active = false
		self.b2Body:setActive(false)
		if self.lastActiveState then return end
		self.lastActiveState = {}
		local las = self.lastActiveState
		las.x, las.y = self:getPosition()
		las.r = self:getAngle()
		las.vx, las.vy = self:getLinearVelocity()
		las.vr = self:getAngularVelocity()
	else
		self.active = true
		self.b2Body:setActive(true)
		if self.lastActiveState then
			local las = self.lastActiveState
			self:setPosition(las.x, las.y)
			self:setAngle(las.r)
			self:setLinearVelocity(las.vx, las.vy)
			self:setAngularVelocity(las.vr)
			self.lastActiveState = nil
		end
	end
end

function Entity:b2Physics(b2World)
	self.b2World = b2World
	self.b2Body = love.physics.newBody(b2World, self.x, self.y, "dynamic")
	self.b2Shapes = {}
end

function Entity:b2Shape(b2Shape)
	local shape = {}
	shape._type = "EntityShape"
	shape.entity = self
	shape.contacts = {}
	shape.b2Shape = b2Shape
	shape.b2Fixture = love.physics.newFixture(self.b2Body, shape.b2Shape)
	shape.b2Fixture:setUserData(shape)
	table.insert(self.b2Shapes, shape)
	return shape
end

function Entity:b2BodyType(type)
	self.b2Body:setType(type)
end

function Entity:b2Category(t)
	self.b2Category = t
	for _, shape in pairs(self.b2Shapes) do
		shape.b2Fixture:setCategory(unpack(self.b2Category))
	end
end

function Entity:getPosition()
	return self.b2Body:getPosition()
end

function Entity:setPosition(x, y)
	self.x, self.y = x, y
	if self.b2Body then
		self.b2Body:setPosition(x, y)
	end
end

function Entity:getAngle()
	return self.b2Body:getAngle()
end

function Entity:setAngle(r)
	self.r = r
	if self.b2Body then
		self.b2Body:setAngle(r)
	end
end

function Entity:getLinearVelocity()
	return self.b2Body:getLinearVelocity()
end

function Entity:setLinearVelocity(x, y)
	self.vx, self.vy = x, y
	if self.b2Body then
		self.b2Body:setLinearVelocity(x, y)
	end
end

function Entity:getAngularVelocity()
	return self.b2Body:getAngularVelocity()
end

function Entity:setAngularVelocity(r)
	self.vr = vr
	if self.b2Body then
		self.b2Body:setAngularVelocity(r)
	end
end

function Entity:b2BeginContact(fixtureA, fixtureB, contact)
	
end

function Entity:b2EndContact(fixtureA, fixtureB, contact)

end

function Entity:e_update(t)
	if not self.active then return end
	if self.update then self:update(t) end
	local pastX, pastY = self.x, self.y
	if self.b2Body then
		self.x, self.y = self.b2Body:getPosition()
		self.r = self.b2Body:getAngle()
		self.vx, self.vy = self.b2Body:getLinearVelocity()
		self.vr = self.b2Body:getAngularVelocity()
	end
end

function Entity:e_draw(debug)
	if self.draw then self:draw() end
	if debug then
		local r, g, b, a = love.graphics.getColor()
		if self.b2Body then
			for _, shape in pairs(self.b2Shapes) do
				local b2Shape = shape.b2Shape
				local b2ShapeType = b2Shape:getType()
				love.graphics.setColor(0, 255, 0, 50)
				if b2ShapeType == "polygon" then
					love.graphics.polygon("fill", self.b2Body:getWorldPoints(b2Shape:getPoints()))
					love.graphics.setColor(0, 255, 0, 255)
					love.graphics.polygon("line", self.b2Body:getWorldPoints(b2Shape:getPoints()))
				elseif b2ShapeType == "circle" then
					local x, y = self.b2Body:getWorldPoint(b2Shape:getPoint())
					local radius = b2Shape:getRadius()
					love.graphics.circle("fill", x, y, radius)
					love.graphics.setColor(0, 255, 0, 255)
					love.graphics.circle("line", x, y, radius)
				end
			end
		else
			love.graphics.setColor(255, 0, 0, 50)
			love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
			love.graphics.setColor(255, 0, 0, 255)
			love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
		end
		love.graphics.setColor(r, g, b, a)
	end
end