BazookaAnim = class("BazookaAnim")

function BazookaAnim:initialize(bazooka)
	self.bazooka = bazooka
	self.timer = 0
	self.sprites = love.graphics.newImage("rsc/weapon/bazooka/bazooka.png")

	self.frames = {
		loaded = {1},
		unloaded = {2},
	}
	self.quads = {
		love.graphics.newQuad(0, 0, 37, 11, self.sprites:getWidth(), self.sprites:getHeight()),
		love.graphics.newQuad(0, 11, 37, 11, self.sprites:getWidth(), self.sprites:getHeight())
	}
end

function BazookaAnim:update(dt)

end

function BazookaAnim:draw()
	local owner = self.bazooka.owner
	local x, y = owner.b2Body:getPosition()
	local angle = owner.input.aim
	local armyoffset = owner.anim.armyoffset
	local xscaling = owner.anim.xscaling
	local quad = self.quads[1]
	if not self.bazooka.loaded then quad = self.quads[2] end
	love.graphics.draw(self.sprites, quad, x, y - 7 + armyoffset, angle, -1, -xscaling, 22, 6)
end