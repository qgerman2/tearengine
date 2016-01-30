RocketAnim = class("RocketAnim")

function RocketAnim:initialize(rocket)
	self.rocket = rocket
	self.sprite = love.graphics.newImage("rsc/weapon/bazooka/bazooka.png")
	self.quad = love.graphics.newQuad(22, 22, 15, 7, self.sprite:getWidth(), self.sprite:getHeight())
end

function RocketAnim:update(dt)

end

function RocketAnim:draw()
	local x, y = self.rocket.b2Body:getPosition()
	local vx, vy = self.rocket.b2Body:getLinearVelocity()
	local angle = utils.angle(0, 0, vx, vy)
	love.graphics.draw(self.sprite, self.quad, x, y, angle + math.pi, 1, 1, 7.5, 3.5)
end