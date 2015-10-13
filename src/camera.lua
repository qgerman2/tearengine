Camera = class("Camera")

function Camera:initialize()
	self.x = 0
	self.y = 0
	self.oldX = 0
	self.oldY = 0
	
	self.scale = 1
	
	self.screenWidth, self.screenHeight = love.window.getDimensions()
	
	self.target = false
	self.targetX = 0
	self.targetY = 0
end

function Camera:setScale(scale)
	self.scale = scale
end

function Camera:setTarget(x, y)
	self.targetX = x - self.screenWidth / (self.scale * 2)
	self.targetY = y - self.screenHeight / (self.scale * 2)
end

function Camera:update(dt)
	self.screenWidth, self.screenHeight = love.window.getDimensions()
	
	self.x = self.x + ((-self.targetX - self.x) * dt * 10)
	self.y = self.y + ((-self.targetY - self.y) * dt * 10)
	
	self.oldX, self.oldY = self.x, self.y
end

function Camera:worldToScreen(x, y)
	return (x + self.x) * self.scale, (y + self.y) * self.scale
end

function Camera:screenToWorld(x, y)
	return x / self.scale - self.x, y / self.scale - self.y
end

function Camera:draw()
	love.graphics.scale(self.scale)
	love.graphics.translate(self.x, self.y)
end

function Camera:undo()
	love.graphics.origin()
end