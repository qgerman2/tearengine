Client = class("Client")

function Client:initialize(address)
	self.Bridge = Bridge()
	self.Bridge:Client(address)
	self.Courier = Courier(self.Bridge)

	self.Peers = {}
	self.MessageRate = 1 / 30
	self._MessageTimer = 0

	self.name = "swagg"
	self.id = -1
	self.ready = true
	self.state = "idle"

	self.serverInfo = {}
end

function Client:mousePressed(x, y, button)
	if self.Game then self.Game.InputHandler:mousePressed(x, y, button) end
end

function Client:mouseReleased(x, y, button)
	if self.Game then self.Game.InputHandler:mouseReleased(x, y, button) end
end

function Client:keyPressed(key)
	if self.Game then self.Game.InputHandler:keyPressed(key) end
end

function Client:keyReleased(key)
	if self.Game then self.Game.InputHandler:keyReleased(key) end
end

function Client:gamepadPressed(joystick, button)
	if self.Game then self.Game.InputHandler:gamepadPressed(joystick, button) end
end

function Client:gamepadReleased(joystick, button)
	if self.Game then self.Game.InputHandler:gamepadReleased(joystick, button) end
end

function Client:gamepadAxis(joystick, axis, value)
	if self.Game then self.Game.InputHandler:gamepadAxis(joystick, axis, value) end
end

function Client:requestServerInfo()
	self.Courier:addMessage({
		[0] = MSG.QueryInfo,
		[1] = _version,
	})
end

function Client:processServerInfo(msg)
	self.serverInfo = {
		name = msg.hostName,
		id = msg.hostID,
		type = msg.hostType,
		passworded = msg.hostPassworded == 1 or 0,
		map = msg.hostMap,
		playersMax = msg.playersMax,
		playersCurrent = msg.playersCurrent,
	}
	self:requestJoin(self.serverInfo.id, "robofortune")
end

function Client:requestJoin(hostID, password)
	local inputs = love.joystick.getJoystickCount() + 1
	self.Courier:addMessage({
		[0] = MSG.AttemptJoin,
		[1] = _version,
		[2] = hostID,
		[3] = inputs,
		[4] = self.name,
		[5] = password,
	})
end

function Client:onJoinAccepted(msg)
	self.state = "lobby"
	self.id = tonumber(msg.peerID)
	self.Peers[self.id] = {
		["id"] = self.id,
		["name"] = self.name,
		["ready"] = self.ready,
	}
	print("Client: Joined (ID: " .. msg.peerID .. ")")
	print(msg.hostMOTD)
end

function Client:onJoinDenied(msg)
	print("Client: Failed to join (Reason: " .. msg.reason .. ")")
end

function Client:processPeerState(msg)
	local peerID = tonumber(msg.peerID)
	if not self.Peers[peerID] then self.Peers[peerID] = {} end
	self.Peers[peerID].id = peerID
	self.Peers[peerID].name = msg.peerName
	self.Peers[peerID].playerCount = tonumber(msg.peerPlayers)
	self.Peers[peerID].ready = msg.ready == "1" or false
end

function Client:toggleReady()
	self.Courier:addMessage({
		[0] = MSG.ToggleReady,
		[1] = _version,
	})
end

function Client:startGame(msg)
	self.state = "ingame"
	self.Game = GameClient(msg.mapName, self.Peers, self.id, self.Courier)
	game = self.Game
end

function Client:processMessages(msgs)
	for _, msg in pairs(msgs) do
		if msg.type == MSG.SendInfo then self:processServerInfo(msg)
		elseif msg.type == MSG.AcceptJoin then self:onJoinAccepted(msg)
		elseif msg.type == MSG.DenyJoin then self:onJoinDenied(msg)
		elseif msg.type == MSG.UpdatePeer then self:processPeerState(msg)
		elseif msg.type == MSG.StartGame then self:startGame(msg)
		elseif self.Game then
			self.Game:processMessage(msg)
		end
	end
end

function Client:update(dt)
	local events = self.Bridge:CheckEvents()
	if events then
		for i = 1, #events do
			local event = events[i]
			if event.type == "connect" then
				print("Client: Connected")
				self:requestServerInfo()
			elseif event.type == "receive" then
				local msgs = self.Courier:readPacket(event.data, event.channel)
				self:processMessages(msgs)
			end
		end
	end

	if self.state == "ingame" then
		self.Game:g_update(dt)
	end
	self._MessageTimer = self._MessageTimer + dt
	while self._MessageTimer >= self.MessageRate do
		self._MessageTimer = self._MessageTimer - self.MessageRate
		if self._MessageTimer < self.MessageRate then
			if self.Game then
				self.Game:prePacket(self.MessageRate)
			end
			local packet = self.Courier:buildPacket()
			self.Courier:pushPacket(packet)
		end
	end
end

function Client:draw()
	if self.state == "ingame" then
		--self.Game:g_draw()
	end
end