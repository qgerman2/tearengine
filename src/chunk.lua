Chunk = class("Chunk")

function Chunk:initialize(vertices, body, xCenter, yCenter)
	self.x = xCenter
	self.y = yCenter

	self.b2Shape = love.physics.newChainShape(true, unpack(vertices))
	self.b2Fixture = love.physics.newFixture(body, self.b2Shape)
	self.b2Fixture:setFriction(0.5)
	self.b2Fixture:setUserData("Terrain")
	
	self.clObject = clipper.polygon()
	for i = 1, #vertices, 2 do
		self.clObject:add(vertices[i], vertices[i + 1])
	end
end

function Chunk:destroy()
	self.clObject = nil
	self.b2Fixture:destroy()
end

function Chunk:draw()
	love.graphics.line(self.b2Shape:getPoints())
end