MSG = {							--Reliable
	QueryInfo			= "00",	--*
	SendInfo			= "01",
	AttemptJoin			= "02", --*
	AcceptJoin			= "03", --*
	DenyJoin			= "04",
	UpdatePeer			= "05", --*
	ToggleReady			= "06",
	StartGame			= "07", --*
	SendInput			= "08",
	SyncTick			= "09",
	SyncEntityPredict	= "10",
	SyncEntity			= "11",
	SyncEntityCreate	= "12", --*
	SyncEntityPosition	= "13", --deprecated
	SyncEntityRemove	= "14", --*
	SyncTickPredict		= "15",
	ProjectileFire		= "16", --*
	UnitHealth			= "17",
	ChatInput			= "18", --*
	ChatOutput			= "19", --*
	CarveTerrain		= "20", --*
	PeerJoined			= "21", --*
	PeerLeft			= "22", --*
}

local MessageType = {
	["00"] = {			--Request server info			(Client)
		"version",
		reliable = true,
	},		
	["01"] = {			--Send server info				(Server)
		"version",
		"hostName",
		"hostID",		--Random number (10000 - 99999)
		"hostType",		--Listen, dedicated
		"hostPassworded",
		"mapName",
		"playersMax",
		"playersCurrent",
	},
	["02"] = {			--Request join game				(Client)
		"version",
		"hostID",
		"peerPlayers",	--Multiple players per client
		"peerName",
		"password",
		reliable = true,
	},
	["03"] = {			--Accept join game request		(Server)
		"version",
		"peerID",
		"hostMOTD",
		reliable = true,
	},
	["04"] = {			--Deny join game request		(Server)
		"reason",
	},
	["05"] = {			--Update peer state				(Server)
		"peerID",
		"peerName",
		"peerPlayers",
		"ready",
		reliable = true,
	},
	["06"] = {			--Toggle ready					(Client)
		"version",
	},
	["07"] = {			--Start game					(Server)
		"mapName",
		"schemeName",
		reliable = true,
	},
	["08"] = {			--Player input					(Client)
		"peerID",
		"playerID",
		"tick",
		"aim",
		"jump",
		"left",
		"right",
		"down",
		"fire1",
		"fire2",
		"cancel",
	},
	["09"] = {			--Server tick					(Server)
		"tick",
	},
	["10"] = {			--unit snapshot			(Server)
		"entityID",
		"x",
		"y",
		"r",
		"vx",
		"vy",
		"vr",
	},
	["11"] = {			--unit snapshot			(Server)
		"entityID",
		"x",
		"y",
		"r",
		"vx",
		"vy",
		"vr",
	},
	["12"] = {			--Generic entity creation		(Server)
		"tick",
		"entityID",
		"kind",
		"x",
		"y",
		"vx",
		"vy",
		reliable = true,
	},
	["13"] = {			--Generic entity sync			(Server)
		"tick",
		"entityID",
		"x",
		"y",
	},
	["14"] = {			--Generic entity removal		(Server)
		"tick",
		"entityID",
		reliable = true,
	},
	["15"] = {
		"tick",
	},
	["16"] = {
		"tick",
		"peerID",
		"entityID",
		"kind",
		"x",
		"y",
		"vx",
		"vy",
		reliable = true,
	},
	["17"] = {
		"entityID",
		"health",
	},
	["18"] = {
		"text",
		reliable = true,
	},
	["19"] = {
		"peerID",
		"text",
		reliable = true,
	},
	["20"] = {
		"tick",
		"x",
		"y",
		"radius",
		reliable = true,
	},
	["21"] = {
		"peerID",
		reliable = true,
	},
	["22"] = {
		"peerID",
		reliable = true,
	},
}

Courier = class("Courier")

function Courier:initialize(Bridge, peerID, Vacuum)
	self.Bridge = Bridge
	self.Vacuum = Vacuum or nil
	self.peerID = peerID or nil
	self.BufferReliable = {}
	self.BufferUnreliable = {}
end

function Courier:addMessage(Message)
	local packet = {[0] = Message[0]}
	for i, v in ipairs(MessageType[Message[0]]) do
		if Message[v] ~= nil then
			packet[i] = Message[v]
		end
	end
	local encoded = mp.pack(packet)
	local reliable = MessageType[Message[0]].reliable
	if reliable then
		table.insert(self.BufferReliable, encoded)
	else
		if Message["entityID"] then
			if not self.Vacuum:check(Message["entityID"]) then return end
		end
		table.insert(self.BufferUnreliable, encoded)
	end
end

function Courier:buildPacket()
	local buffer = {
		[1] = self.BufferReliable,
		[2] = self.BufferUnreliable
	}
	local packet = {[1] = "", [2] = ""}
	for i = 1, 2 do
		for k, msg in pairs(buffer[i]) do
			packet[i] = packet[i] .. msg
			buffer[i][k] = nil
		end
	end
	return {packet[1], packet[2]}
end

function Courier:readPacket(packet, channel, time)
	local unpackedMessages = {}
	local offset = 0
	repeat
		local message = false
		offset, message = mp.unpack(packet, offset)
		if message then
			message["type"] = message[0]
			for i, v in pairs(message) do
				if type(i) == "number" and i ~= 0 then
					message[MessageType[message.type][i]] = message[i]
				end
			end
			message.localTime = time
			unpackedMessages[#unpackedMessages + 1] = message
		end
	until message == nil
	return unpackedMessages
end

function Courier:pushPacket(packets)
	for i = 1, 2 do
		if #packets[i] > 0 then
			self.Bridge:Send(packets[i], i - 1, i == 1 and "reliable" or "unreliable", self.peerID)
		end
	end
end