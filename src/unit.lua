Unit = class("Unit", Entity)

function Unit:initialize(x, y, b2World)
	Entity.initialize(self, x, y)
	self.anim = UnitAnimator(self)

	self.width = 10
	self.height = 30

	self:b2Physics(b2World)
	self:b2Category({2})
	self.b2Body:setLinearDamping(0.1)
	self.b2Body:setFixedRotation(true)
	self.topShape = self:b2Shape(love.physics.newRectangleShape(0, -(self.height / 2 - self.height / 3), self.width, (self.height / 3) * 2))
	self.topShape.b2Fixture:setFriction(0.5)
	self.topShape.b2Fixture:setRestitution(0.2)
	self.topShape.b2Fixture:setDensity(1)
	self.feetShape = self:b2Shape(love.physics.newRectangleShape(0, self.height / 3, self.width - 2, self.height / 3))
	self.feetShape.b2Fixture:setSensor(true)
	self.leftSensor = self:b2Shape(love.physics.newRectangleShape(-self.width / 2 - 1, -(self.height / 2 - self.height / 3), 2, (self.height / 3) * 2))
	self.rightSensor = self:b2Shape(love.physics.newRectangleShape(self.width / 2 + 1, -(self.height / 2 - self.height / 3), 2, (self.height / 3) * 2))
	self.leftSensor.b2Fixture:setSensor(true)
	self.leftSensor.b2Fixture:setDensity(0)
	self.rightSensor.b2Fixture:setSensor(true)
	self.rightSensor.b2Fixture:setDensity(0)

	self.b2Body:resetMassData()

	self.onGround = false
	self.onGroundExtraTicks = 10
	self.roping = false
	self.ropingSpeed = 7
	self.ropingBounce = 1.1
	self.walkSpeed = 150
	self.jumpImpulse = 350
	self.airAcceleration = 10
	self.direction = "right"

	self.weapons = {["Bazooka"] = Bazooka(self)}

	self.equipped = {
		[1] = self.weapons["Bazooka"],
		[2] = self.weapons["Rope"],
	}

	self.input = {
		aim = 0,
		jump = false,
		down = false,
		left = false,
		right = false,
		fire1 = false,
		fire2 = false,
		cancel = false,
	}

	self.health = 100
	self._onGroundExtraTicks = 0
end

function Unit:applyInput(input)
	local sequence = {
		[1] = "aim",
		[2] = "jump",
		[3] = "left",
		[4] = "right",
		[5] = "down",
		[6] = "fire1",
		[7] = "fire2",
		[8] = "cancel",
	}
	for i = 1, #sequence do
		self.input[sequence[i]] = input[i + 3] or tonumber(input[sequence[i]])
		if self.input[sequence[i]] == 0 and sequence[i] ~= "aim" then self.input[sequence[i]] = false end
	end
	self.input["aim"] = math.rad(self.input["aim"])
end

function Unit:b2BeginContact(fixtureA, fixtureB, b2Contact)
	if fixtureA == self.feetShape.b2Fixture or fixtureB == self.feetShape.b2Fixture then
		
	end
end

function Unit:update(t)
	self.feetShape.b2Fixture:setRestitution(0)
	self.topShape.b2Fixture:setRestitution(0)

	self.equipped[1]:wep_update(t)

	local mass = self.b2Body:getMass()
	local vx, vy = self.b2Body:getLinearVelocity()
	local aimAngle = self.input["aim"]
	local walkSpeed = self.walkSpeed
	local canWalk = false
	if #self.feetShape.contacts >= 1 then
		self._onGroundExtraTicks = self.onGroundExtraTicks
		self.onGround = true
		if vy >= 0 then
			self.b2Body:setGravityScale(0)
		end
		local x, y = self.b2Body:getPosition()
		local hy = -1
		self.b2World:rayCast(x - self.width / 2 + 1, y, x - self.width / 2 + 1, y + self.height / 2 - 1,
			function(b2Fixture, xx, yy)
				if b2Fixture:getUserData() ~= "Terrain" then return -1 end
				if yy < hy or hy == -1 then hy = yy end
				return -1
			end
		)
		self.b2World:rayCast(x + self.width / 2 - 1, y, x + self.width / 2 - 1, y + self.height / 2 - 1,
			function(b2Fixture, xx, yy)
				if b2Fixture:getUserData() ~= "Terrain" then return -1 end
				if yy < hy or hy == -1 then hy = yy end
				return -1
			end
		)
		if hy ~= -1 then
			self.b2Body:setPosition(x, utils.round(hy - self.height / 2))
			self.b2Body:setLinearVelocity(vx, 0)
		end
	else
		if self._onGroundExtraTicks > 0 then
			self._onGroundExtraTicks = self._onGroundExtraTicks - 1
		end
		self.onGround = false
		self.b2Body:setGravityScale(1)
	end
	if self.input["right"] then
		self.direction = "right"
		if #self.rightSensor.contacts == 0 then canWalk = true end
	elseif self.input["left"] then
		self.direction = "left"
		walkSpeed = -walkSpeed
		if #self.leftSensor.contacts == 0 then canWalk = true end
	else
		if self.onGround and not self.roping then
			self.b2Body:applyLinearImpulse(mass * (0 - vx), 0)
		end
	end
	walkSpeed = walkSpeed * math.abs(self.input["right"] or self.input["left"] or 1)
	if canWalk then
		if self.onGround then
			self.b2Body:applyLinearImpulse(mass * (walkSpeed - vx), 0)
		else
			if math.abs(walkSpeed) > vx * utils.sign(walkSpeed) then
				self.b2Body:applyLinearImpulse(mass * walkSpeed * t * self.airAcceleration, 0)
			end
		end
	end
	if self.input["jump"] then
		if self.onGround or not self.onGround and self._onGroundExtraTicks > 0 then
			self._onGroundExtraTicks = 0
			self.b2Body:applyLinearImpulse(0, mass * (-self.jumpImpulse - vy))
		end
	end
	if self.input["fire1"] then
		self.equipped[1]:wep_fire(self.input["aim"])
	end
	self.anim:update(t)
end

function Unit:draw()
	self.anim:draw()
end