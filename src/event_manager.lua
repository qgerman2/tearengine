EventManager = class("EventManager")

function EventManager:initialize(gameClient)
	self.GameClient = gameClient
	self.delay = 33.3
	self.jitterThreshold = 16.6 --ms
	self.displayTick = 0
	self.serverTick = 0
	self.skipTick = 0

	self.Events = {}
end

function EventManager:setServerTick(tick)
	if tick > self.serverTick then
		self.serverTick = tick
		self:calculateDelay()
	end
end

function EventManager:event(eventData)
	local type = tonumber(eventData.type)
	--Create event
	local newEvent = false
	if type == 08 then newEvent = self:PlayerInput(eventData)
	elseif type == 11 then newEvent = self:EntityUpdate(eventData)
	elseif type == 12 then newEvent = self:EntityCreation(eventData)
	elseif type == 13 then newEvent = self:EntityUpdate(eventData)
	elseif type == 14 then newEvent = self:EntityDestruction(eventData) end
	--elseif type == 15 then newEvent = self:TerrainDeformation(eventData) end
	--Add it if necessary
	if newEvent then
		table.insert(self.Events, 1, newEvent)
	end
end

function EventManager:UnitUpdate(eventData)
	local unitanims = {
		[1] = "idle",
		[2] = "run",
	}
	local unit = self.GameClient.Level.Entities[tonumber(eventData.entityID)]
	if not unit.Interpolation then unit.Interpolation = EntityInterpolator(unit) end	
	local snapshot = {
		tick = tonumber(eventData.tick),
		x = tonumber(eventData.x),
		y = tonumber(eventData.y),
		input = {
			aim = tonumber(eventData.aim)
		},
		_runLastDirection = eventData.direction,
		anim = {
			anim = unitanims[tonumber(eventData.animation)]
		},
	}
	unit.Interpolation:addSnapshot(snapshot)
	unit.Interpolation:setDisplayTick(self.displayTick)
end

function EventManager:PlayerInput(eventData)
	if eventData.tick <= self.displayTick then return end
	local event = {
		type = "PlayerInput",
		tick = eventData.tick,
		peerID = eventData.peerID,
		playerID = eventData.playerID,
		aim = eventData.aim,
		jump = eventData.jump,
		left = eventData.left,
		right = eventData.right,
		down = eventData.down,
		fire1 = eventData.fire1,
		fire2 = eventData.fire2,
		cancel = eventData.cancel,
	}
	return event
end

function EventManager:EntityUpdate(eventData)
	if eventData.tick <= self.displayTick then return end
	local event = {
		type = "EntityUpdate",
		tick = eventData.tick,
		entityID = eventData.entityID,
		x = eventData.x,
		y = eventData.y,
		r = eventData.r,
		vx = eventData.vx,
		vy = eventData.vy,
		vr = eventData.vr,
	}
	return event
end

function EventManager:EntityCreation(eventData)
	local event = {
		type = "EntityCreation",
		tick = tonumber(eventData.tick),
		id = tonumber(eventData.entityID),
		x = tonumber(eventData.x),
		y = tonumber(eventData.y),
	}
	if event.tick <= self.displayTick then
		event.tick = self.displayTick + 1
	end
	local b2World = eventData.b2 == "1" and self.GameClient.Level.b2World or false
	event.entity = _G[eventData.kind](event.x, event.y, b2World)
	return event
end

function EventManager:EntityDestruction(eventData)
	local event = {
		type = "EntityDestruction",
		tick = tonumber(eventData.tick),
		id = tonumber(eventData.entityID),
	}
	if event.tick <= self.displayTick then
		event.tick = self.displayTick + 1
	end
	return event
end

function EventManager:TerrainDeformation(eventData)
	local event = {
		type = "TerrainDeformation",
		tick = tonumber(eventData.tick),
		kind = eventData.kind,
		x = tonumber(eventData.x),
		y = tonumber(eventData.y),
		mod = tonumber(eventData.mod),
	}
	if event.tick <= self.displayTick then
		table.insert(self.GameClient.Level.TerrainDeformations, event)
		return false
	end
	return event
end

function EventManager:getDisplayTick()
	return self.displayTick
end

function EventManager:calculateDelay()
	local desiredDelay = utils.round(self.delay / (self.GameClient.tickRate * 1000))
	local currentDelay = self.serverTick - self.displayTick
	local difference = currentDelay - desiredDelay
	local tolerance = utils.round(self.jitterThreshold / (self.GameClient.tickRate * 1000))
	if difference >= tolerance then
		for i = 1, difference do
			self:update()
			if i > 60 then break end
		end
	elseif difference < -tolerance then
		self.skipTick = math.abs(difference)
		if self.skipTick > 100 then self.skipTick = 100 end
	end
end

function EventManager:update()
	if self.skipTick > 0 then self.skipTick = self.skipTick - 1; return end
	self.displayTick = self.displayTick + 1
	local level = self.GameClient.Level
	for i, event in pairs(self.Events) do
		if event.tick == self.displayTick then
			if event.type == "EntityUpdate" then
				local entity = level.Entities[event.entityID]
				entity:setPosition(event.x, event.y)
				entity:setAngle(event.r)
				entity:setLinearVelocity(event.vx, event.vy)
				entity:setAngularVelocity(event.vr)
			elseif event.type == "EntityCreation" then
				level:addEntity(event.entity, event.id)
			elseif event.type == "EntityDestruction" then
				level:removeEntity(event.id)
			elseif event.type == "TerrainDeformation" then
				table.insert(level.TerrainDeformations, event)
			elseif event.type == "PlayerInput" then
				local unit = self.GameClient.Peers[event.peerID].Players[event.playerID].unit
				unit:applyInput(event)
			end
			self.Events[i] = nil
		end
	end
end

