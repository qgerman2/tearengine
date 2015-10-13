--Clase "UnitAnimator"
--Animaciones para las unidades!

UnitAnimator = class("UnitAnimator")

function UnitAnimator:initialize(unit)
	self.unit = unit
	self.timer = 0
	self.sprites = love.graphics.newImage("rsc/unit/skin1.png")
	
	self.frameWidth = 24
	self.frameHeight = 33
	
	self.frames = {
		idle = {"1", frameTime = 1};
		run = {"2", "3", "4", "5", "6", "7", "8", "9", frameTime = 0.1};
	}
	
	self.quads = {}
	for k, v in pairs(self.frames) do
		self.quads[k] = {}
		for i = 1, #v do
			table.insert(self.quads[k], love.graphics.newQuad(24 * (tonumber(v[i]) - 1), 0, self.frameWidth, self.frameHeight, self.sprites:getWidth(), self.sprites:getHeight()))
		end
	end
	
	self.arms = {
		{quad = love.graphics.newQuad(0, 33, 13, 8, self.sprites:getWidth(), self.sprites:getHeight())};
		{quad = love.graphics.newQuad(13, 33, 13, 8, self.sprites:getWidth(), self.sprites:getHeight())};
	}
	
	self.anim = "idle"
	self.key = 1
end

function UnitAnimator:set(anim)
	self.anim = anim
	if self.key > #self.frames[anim] then
		self.key = 1
	end
end

function UnitAnimator:update(dt)
	local input = self.unit.input
	if not self.unit.onGround or input["left"] or input["right"] then
		self:set("run")
	else
		self:set("idle")
	end
	
	self.timer = self.timer + dt
	if self.timer >= self.frames[self.anim].frameTime then
		self.key = self.key + 1
		if self.key > #self.frames[self.anim] then
			self.key = 1
		end
		self.timer = 0
	end
end

function UnitAnimator:draw()
	local x, y = self.unit.b2Body:getPosition()
	local w, h = self.unit.width, self.unit.height
	local quad = self.quads[self.anim][self.key]
	local xscaling = -1
	if self.unit.direction == "left" then xscaling = 1 else xscaling = -1 end
	local armyoffset = 0
	if self.anim == "run" then
		if self.key == 1 or self.key == 5 then armyoffset = 1 end
		if self.key == 2 or self.key == 6 then armyoffset = 2 end
		if self.key == 3 or self.key == 7 then armyoffset = 1 end
		if self.key == 4 or self.key == 8 then armyoffset = 0 end
	end
	
	local angle = self.unit.input["aim"]
	local angle2 = self.unit.input["aim"]
	--Brazo2
	love.graphics.draw(self.sprites, self.arms[2].quad, x, y - 4 + armyoffset, angle2 + math.pi, 1, xscaling, 11, 4)
	
	--Cuerpo
	love.graphics.draw(self.sprites, quad, x, y + h * 0.75, 0, xscaling, 1, self.frameWidth / 2, self.frameHeight)
	
	--Brazo1
	love.graphics.draw(self.sprites, self.arms[1].quad, x, y - 5 + armyoffset, angle + math.pi, 1, xscaling, 10, 2)
end