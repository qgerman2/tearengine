Server = class("Server")

function Server:initialize(address)
	self.Bridge = Bridge()
	self.Bridge:Server(address)

	self.Peers = {}
	self.MessageRate = 1 / 30
	self.MessageTimer = 0

	math.randomseed(os.clock())
	self.hostID = tostring(math.random(10000, 99999)) --legit

	self.hostPassword = "robofortune"
	self.hostType = "dedicated"
	self.hostName = "test server"
	self.hostMOTD = "PLEASE ACCEPT MY FRIEND REQUEST"
	self.playersMax = 16
	self.playersCurrent = 0
	self.map = "rsc/map3.png"
	self.state = "lobby"
end

function Server:broadcastMessage(msg)
	for id, peer in pairs(self.Peers) do
		peer.Courier:addMessage(msg)
	end
end

function Server:onPeerConnected(id)
	--Just connected, do not trust yet
	self.Peers[id] = {
		["Courier"] = Courier(self.Bridge, id),
		["id"] = id,
		["name"] = "unnamed",
		["state"] = "handshake",
		["ready"] = true,
	}
end

function Server:onPeerDisconnected(id)

end

function Server:onPeerJoinAccepted(peer, request)
	peer.Courier:addMessage({
		[0] = MSG.AcceptJoin,
		[1] = _version,
		[2] = peer.id,
		[3] = self.hostMOTD,
	})
	peer.state = "connected"
	peer.lerp = 100
	peer.name = request.peerName
	peer.playerCount = request.peerPlayers
	--Update our new peer with other peers data
	for id, p in pairs(self.Peers) do
		if id ~= peer.id then
			peer.Courier:addMessage({
				[0] = MSG.UpdatePeer,
				[1] = p.id,
				[2] = p.name,
				[3] = p.playerCount,
				[4] = p.ready and true or false,
			})
		end
	end
	--Notify everyone
	self:broadcastPeerState(peer.id)
	print("Server: Peer " .. peer.id .. " joined the game")
end

function Server:onPeerJoinDenied(peer, reason)
	peer.Courier:addMessage({
		[0] = MSG.DenyJoin,
		[1] = reason,
	})
	print("Server: Peer " .. peer.id .. " failed to join (Reason: " .. reason .. ")")
end

function Server:broadcastPeerState(id)
	local peer = self.Peers[id]
	self:broadcastMessage({
		[0] = MSG.UpdatePeer,
		[1] = peer.id,
		[2] = peer.name,
		[3] = peer.playerCount,
		[4] = peer.ready and true or false,
	})
end

function Server:sendServerInfo(peer)
	local passworded = not (self.hostPassword == "") and true or false
	peer.Courier:addMessage({
		[0] = MSG.SendInfo,
		[1] = _version,
		[2] = self.hostName,
		[3] = self.hostID,
		[4] = self.hostType,
		[5] = passworded,
		[6] = self.map,
		[7] = self.playersMax,
		[8] = self.playersCurrent,
	})
end

function Server:processJoin(request, peer)
	if peer.state ~= "handshake" then return true end	--Already connected
	local versionCheck = false
	local idCheck = false
	local passCheck = false
	local denyReason = "unknown"
	if request.version == _version then versionCheck = true end
	if request.hostID == self.hostID then idCheck = true end
	if request.password == self.hostPassword then passCheck = true end
	if versionCheck then
		if idCheck then
			if passCheck then
				self:onPeerJoinAccepted(peer, request)
				return true
			else
				denyReason = "Incorrect password"
			end
		else
			denyReason = "Incorrect server id"
		end
	else
		denyReason = "Different game version"
	end
	self:onPeerJoinDenied(peer, denyReason)
end

function Server:toggleReady(peer)
	peer.ready = not peer.ready
	local msg = peer.ready and " ready" or " not ready"
	print("Server: Peer " .. peer.id .. msg)
	self:broadcastPeerState(peer.id)
end

function Server:startGame()
	--Check if peers are ready
	for _, peer in pairs(self.Peers) do
		if peer.state == "handshake" then return false end
		if not peer.ready then return false end
	end
	--Magic
	self.state = "ingame"
	self.Game = GameServer(self.map, self.Peers, self)
	game = self.Game
	self:broadcastMessage({
		[0] = MSG.StartGame,
		[1] = self.map,
		[2] = "default",
	})
end

function Server:processMessages(msgs, peer)
	for _, msg in pairs(msgs) do
		if msg.type == MSG.QueryInfo then self:sendServerInfo(peer)
		elseif msg.type == MSG.AttemptJoin then self:processJoin(msg, peer)
		elseif msg.type == MSG.ToggleReady then self:toggleReady(peer)
		elseif self.Game then
			self.Game:processMessage(msg, peer)
		end
	end
end

function Server:update(dt)
	local events = self.Bridge:CheckEvents()
	if events then
		for i = 1, #events do
			local event = events[i]
			--print(event.data)
			if event.type == "connect" then
				print("Server: Peer " .. event.peer .. " connected")
				self:onPeerConnected(event.peer)
			elseif event.type == "receive" then
				local peer = self.Peers[event.peer]
				local msgs = peer.Courier:readPacket(event.data, event.channel)
				self:processMessages(msgs, peer)
			elseif event.type == "disconnect" then
				self:onPeerDisconnected(event.peer)
			end
		end
	end
	if self.state == "ingame" then
		self.Game:g_update(dt)
	end
	self.MessageTimer = self.MessageTimer + dt
	while self.MessageTimer >= self.MessageRate do
		self.MessageTimer = self.MessageTimer - self.MessageRate
		if self.MessageTimer < self.MessageRate then
			if self.state == "ingame" then self.Game:sendLevelSnapshot() end
			for id, peer in pairs(self.Peers) do
				local packet = peer.Courier:buildPacket()
				peer.Courier:pushPacket(packet)
			end
		end
	end
end