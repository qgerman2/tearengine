EventManager = class("EventManager")

function EventManager:initialize(gameClient)
	self.GameClient = gameClient
	self.delay = 33.3
	self.jitterThreshold = 16.6 --ms
	self.displayTick = 0
	self.serverTick = 0
	self.skipTick = 0

	self.Events = {}

	self.EventPriority = {
		["EntityCreation"] = 1,
		["EntityDestruction"] = 2,
		["CarveTerrain"] = 3,
		["EntityUpdate"] = 4,
		["PlayerInput"] = 5
	}
end

function EventManager:setServerTick(tick)
	if tick > self.serverTick then
		self.serverTick = tick
		self:calculateDelay()
	end
end

function EventManager:event(eventData)
	local type = eventData.type
	local newEvent = false
	if type == MSG.SendInput then newEvent = self:PlayerInput(eventData)
	elseif type == MSG.SyncEntity then newEvent = self:EntityUpdate(eventData)
	elseif type == MSG.SyncEntityPredict then newEvent = self:EntityCreation(eventData)
	elseif type == MSG.SyncEntityPosition then newEvent = self:EntityUpdate(eventData)
	elseif type == MSG.SyncEntityRemove then newEvent = self:EntityDestruction(eventData)
	elseif type == MSG.ProjectileFire then newEvent = self:ProjectileFire(eventData)
	elseif type == MSG.CarveTerrain then newEvent = self:CarveTerrain(eventData) end
	if newEvent then
		table.insert(self.Events, 1, newEvent)
	end
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
	if self.serverTick <= self.displayTick then return end
	local event = {
		type = "EntityUpdate",
		tick = self.serverTick,
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

function EventManager:CarveTerrain(eventData)
	self.GameClient.Level.Terrain:carve(eventData.x, eventData.y, eventData.radius)
	self.GameClient.Level.Terrain:buildImageChunks(self.GameClient.Level.Terrain.cImageChunkSize)
end

function EventManager:EntityCreation(eventData)
	local event = {
		type = "EntityCreation",
		tick = eventData.tick,
		kind = eventData.kind,
		id = eventData.entityID,
		x = eventData.x,
		y = eventData.y,
		vx = eventData.vx,
		vy = eventData.vy
	}
	if event.tick <= self.displayTick then
		event.tick = self.displayTick + 1
	end
	return event
end

function EventManager:EntityDestruction(eventData)
	local event = {
		type = "EntityDestruction",
		tick = eventData.tick,
		id = eventData.entityID,
	}
	if event.tick <= self.displayTick then
		event.tick = self.displayTick + 1
	end
	return event
end

function EventManager:TerrainDeformation(eventData)
	local event = {
		type = "TerrainDeformation",
		tick = eventData.tick,
		kind = eventData.kind,
		x = eventData.x,
		y = eventData.y,
		mod = eventData.mod,
	}
	if event.tick <= self.displayTick then
		table.insert(self.GameClient.Level.TerrainDeformations, event)
		return false
	end
	return event
end

function EventManager:ProjectileFire(eventData)
	if eventData.peerID == self.GameClient.peerID then
		return self:EntityCreation(eventData)
	end
	local game = self.GameClient
	local tick = game._syncInputTick
	local temp = false
	for i = 1, #game.journal do
		local snapshotA = game.journal[i]
		if snapshotA.tick + 1 == tick then
			snapshotA:apply(game.Level)
			game.Level:update(0)
			snapshotA:apply(game.Level)
			game.Level:update(game.timeStep)
			local b2World = game.Level.b2World
			local entity = _G[eventData.kind](eventData.x, eventData.y, b2World)
			temp = entity
			entity.b2Body:setLinearVelocity(eventData.vx, eventData.vy)
			entity.persist = true
			game.Level:addEntity(entity, eventData.id)
			for ii = i - 1, 1, -1 do
				local snapshotB = game.journal[ii]
				snapshotB:apply(game.Level)
				game._tick = snapshotB.tick
				game.journal[ii] = Snapshot(game.Level)
				if ii ~= 1 then
					game.Level:update(game.timeStep)
				end
			end
		end
	end
	if temp then temp.persist = false end
	game._tick = game._tick + 1
end

function EventManager:getDisplayTick()
	return self.displayTick
end

function EventManager:sortEvents()
	table.sort(self.Events,
		function(a, b)
			if a and b then
				return self.EventPriority[a.type] < self.EventPriority[b.type]
			end
		end
	)
end

function EventManager:calculateDelay()
	local desiredDelay = utils.round(self.delay / (self.GameClient.tickRate * 1000))
	local currentDelay = self.serverTick - self.displayTick
	local difference = currentDelay - desiredDelay
	local tolerance = utils.round(self.jitterThreshold / (self.GameClient.tickRate * 1000))
	if difference >= tolerance / 2 then
		for i = 1, difference do
			self:update()
			if i > 120 then break end
		end
	elseif difference < -tolerance / 2 then
		self.skipTick = math.abs(difference)
		if self.skipTick > 100 then self.skipTick = 100 end
	end
end

function EventManager:update()
	if self.skipTick > 0 then self.skipTick = self.skipTick - 1; return end
	self.displayTick = self.displayTick + 1
	local level = self.GameClient.Level
	self:sortEvents()
	for i, event in pairs(self.Events) do
		if event.tick == self.displayTick then
			if event.type == "EntityUpdate" then
				local entity = level.Entities[event.entityID]
				if entity then
					entity.b2Body:setPosition(event.x, event.y)
					entity.b2Body:setAngle(event.r)
					entity.b2Body:setLinearVelocity(event.vx, event.vy)
					entity.b2Body:setAngularVelocity(event.vr)
				end
			elseif event.type == "EntityCreation" then
				local b2World = self.GameClient.Level.b2World
				local entity = _G[event.kind](event.x, event.y, b2World)
				entity.b2Body:setLinearVelocity(event.vx, event.vy)
				level:addEntity(entity, event.id)
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

