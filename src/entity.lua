Entity = class("Entity")

function Entity:initialize(x, y)
	self.priority = 0
	self.shared = true
	self.xInit = x
	self.yInit = y
end

function Entity:destroy()
	if self.b2Body then
		self.b2Body:destroy()
	end
end

function Entity:b2Physics(b2World)
	self.b2World = b2World
	self.b2Body = love.physics.newBody(b2World, self.xInit, self.yInit, "dynamic")
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

function Entity:b2Category(t)
	self.b2Category = t
	for _, shape in pairs(self.b2Shapes) do
		shape.b2Fixture:setCategory(unpack(self.b2Category))
	end
end

function Entity:b2Mask(t)
	self.b2Mask = t
	for _, shape in pairs(self.b2Shapes) do
		shape.b2Fixture:setMask(unpack(self.b2Mask))
	end
end

function Entity:b2BeginContact(fixtureA, fixtureB, contact)
	
end

function Entity:b2EndContact(fixtureA, fixtureB, contact)

end

function Entity:e_update(t)
	if self.update then self:update(t) end
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