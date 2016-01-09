GameClient = class("GameClient", Game)

function GameClient:initialize(mapFile, Peers, peerID, Courier)
	Game.initialize(self, mapFile, peerID)
	self.Peers = Peers
	self.Courier = Courier
	self:spawnUnits()

	self.localPeer = self.Peers[peerID]

	self.EventManager = EventManager(self)
	
	self.inputRedundancy = 2
	self.inputBufferSize = 30
	self.inputBuffer = {}

	if love.system.getOS() == "Android" then
		self.Camera:setScale(3)
	end

	self.journal = {}
	self.journalSize = 30

	self._sync = false
	self._syncInputTick = 0

	self.InputHandler = Input()
	self.HUD = HUD(self)
end

function GameClient:preTick(t)
	if self._sync then
		self:fixEntitySync(self._sync)
		self._sync = false
	end
	self:processInput(t)
	self.EventManager:update()
end

function GameClient:postTick(t)
	self.Camera:update(0.01)
	self.Camera:setTarget(self.localPeer.Players[1].unit:getPosition())
	table.insert(self.journal, 1, Snapshot(self.Level))
	if #self.journal > self.journalSize then
		self.journal[self.journalSize + 1] = nil
	end
end

function GameClient:prePacket(MessageRate)
	self:sendInput(MessageRate / self.tickRate)
end

function GameClient:sendInput(snapshots)
	for id, player in pairs(self.localPeer.Players) do
		for i = utils.round(snapshots) + self.inputRedundancy, 1, -1 do
			local inputState = self.inputBuffer[i]
			if inputState then
				self.Courier:addMessage(self.inputBuffer[i][id])
			end
		end
	end
end

function GameClient:processInput(t)
	local inputSnapshot = self.InputHandler:snapshot(t + 1)
	table.insert(self.inputBuffer, 1, inputSnapshot)
	if #self.inputBuffer > self.inputBufferSize then
		self.inputBuffer[self.inputBufferSize + 1] = nil
	end
	for id, player in pairs(self.localPeer.Players) do
		player.unit:applyInput(inputSnapshot[id])
	end
end

function GameClient:processMessage(msg)
	if msg.type == MSG.SyncTick then self:setServerTick(msg)
	elseif msg.type == MSG.SyncEntityPredict then self:checkEntitySync(msg)
	elseif msg.type == MSG.SyncTickPredict then self:setPredictTick(msg)
	elseif msg.type == MSG.UnitHealth then self:updateUnitHealth(msg)
	elseif msg.type == MSG.ChatOutput then self:processChatOutput(msg)
	else
		self.EventManager:event(msg) 
	end
end

function GameClient:setServerTick(msg)
	if msg.localTime < os.clock() - 1 / 20 then return end
	self.EventManager:setServerTick(msg.tick)
end

function GameClient:setPredictTick(msg)
	if msg.localTime < os.clock() - 1 / 20 then return end
	self._syncInputTick = msg.tick
end

function GameClient:checkEntitySync(msg)
	if msg.localTime < os.clock() - 1 / 20 then return end
	local tick = self._syncInputTick
	for i = 1, #self.journal do
		local snapshotA = self.journal[i]
		if snapshotA.tick + 1 == tick then
			local entity = snapshotA.Entities[msg.entityID]
			if entity and entity.x and entity.y then
				local sync = 	utils.round(entity.x) == utils.round(msg.x) and
								utils.round(entity.y) == utils.round(msg.y) and
								utils.round(entity.r) == utils.round(msg.r) and
								utils.round(entity.vx) == utils.round(msg.vx) and
								utils.round(entity.vy) == utils.round(msg.vy) and
								utils.round(entity.vr) == utils.round(msg.vr)
				if not sync then
					self._sync = tick
					print("Prediction error, diff " .. utils.dist(entity.x, entity.y, msg.x, msg.y))
					snapshotA:overwriteEntity(msg)
					for ii = i - 1, 1, -1 do
						local snapshotB = self.journal[ii]
						snapshotB:clearSpatialData(msg.entityID)
					end
				end
			end
			break
		end
	end
end

function GameClient:fixEntitySync(tick)
	for i = 1, #self.journal do
		local snapshotA = self.journal[i]
		if snapshotA.tick + 1 == tick then
			snapshotA:apply(self.Level)
			self.Level:update(0)
			snapshotA:apply(self.Level)
			self.Level:update(self.tickRate)
			for ii = i - 1, 1, -1 do
				local snapshotB = self.journal[ii]
				snapshotB:apply(self.Level)
				self._tick = snapshotB.tick
				self.journal[ii] = Snapshot(self.Level)
				if ii ~= 1 then
					self.Level:update(self.tickRate)
				end
			end
		end
	end
	self._tick = self._tick + 1
end

function GameClient:updateUnitHealth(msg)
	local unit = self.Level.Entities[msg.entityID]
	unit.health = msg.health
end

function GameClient:processChatOutput(msg)
	local name = "Server"
	if msg.peerID ~= 0 then
		name = self.Peers[msg.peerID].name
	end
	self.HUD.Chatbox:addEntry(name .. ": " .. msg.text)
end

function GameClient:update(dt)
	self.InputHandler:update(self)
	self.HUD:update(dt)
end

function GameClient:draw()
	self.HUD:draw()
end