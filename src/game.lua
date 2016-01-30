Game = class("Game")

function Game:initialize(mapFile, peerID)
	self.Camera = Camera()

	self.timeStep = 1 / 60
	self.tickRate = 1 / 60
	self.tickRateTimer = 0

	self._tick = 0

	self.peerID = peerID

	self.Level = Level(self, mapFile)
end

function Game:g_tick(t)
	self:preTick(self._tick)
	self.Level:update(t)
	self:postTick(self._tick)
end

function Game:spawnUnits()
	for id, peer in pairs(self.Peers) do
		for i = 1, peer.playerCount do
			if not peer.Players then peer.Players = {} end
			if not peer.Players[i] then
				peer.Players[i] = {
					unit = Unit(240 + 10 * i, 200, self.Level.b2World),
				}
				peer.Players[i].unit.peer = peer
				peer.Players[i].unit.player = peer.Players[i]
				peer.Players[i].unit.peerID = id
				peer.Players[i].unit.playerID = i
				self.Level:addEntity(peer.Players[i].unit)
				if peer == self.localPeer then
					peer.Players[i].unit:b2Mask({3})
				end
			end
		end
	end
end

function Game:g_update(dt)
	self.tickRateTimer = self.tickRateTimer + dt
	if self.update then self:update(dt) end
	local tickCount = 0
	while self.tickRateTimer >= self.tickRate do
		self._tick = self._tick + 1
		tickCount = tickCount + 1
		self:g_tick(self.timeStep)
		self.tickRateTimer = self.tickRateTimer - self.tickRate
		if tickCount >= 4 then
			--dt too high
			self.tickRateTimer = 0
		end
	end
end

function Game:g_draw()
	self.Camera:draw()
	self.Level:draw()
	self.Camera:undo()
	if self.draw then self:draw() end
end