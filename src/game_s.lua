GameServer = class("GameServer", Game)

function GameServer:initialize(mapFile, Peers, Server)
	Game.initialize(self, mapFile, 0)
	self.Server = Server
	self.Peers = Peers
	self:spawnUnits()

	self.inputBufferSize = 4
	for peerID, peer in pairs(self.Peers) do
		peer.Entities = {}
		if not peer.Players then peer.Players = {} end
		for playerID, player in pairs(peer.Players) do
			player.tick = 0
			player.inputBuffer = {}
		end
	end
end

function GameServer:broadcastMessage(msg)
	for id, peer in pairs(self.Peers) do
		peer.Courier:addMessage(msg)
	end
end

function GameServer:preTick(t)
	for peerID, peer in pairs(self.Peers) do
		for playerID, player in pairs(peer.Players) do
			if #player.inputBuffer > 0 then
				player.tick = player.inputBuffer[1].tick
				peer.tick = player.inputBuffer[1].tick
				player.unit:applyInput(player.inputBuffer[1])
				player.input = player.inputBuffer[1]
				table.remove(player.inputBuffer, 1)
			end
		end
	end
end

function GameServer:postTick(t)
	
end

function GameServer:processInput(msg, peer)
	local player = peer.Players[msg.playerID]
	if msg.tick <= player.tick then return end
	for k, v in pairs(player.inputBuffer) do
		if v.tick == msg.tick then
			return
		end
	end
	player.inputBuffer[#player.inputBuffer + 1] = msg
	table.sort(player.inputBuffer, 
		function(a, b)
			return a.tick < b.tick
		end
	)
	while #player.inputBuffer > self.inputBufferSize do
		table.remove(player.inputBuffer, #player.inputBuffer)
	end
end

function GameServer:processMessage(msg, peer)
	if msg.type == MSG.SendInput then self:processInput(msg, peer)
	elseif msg.type == MSG.ChatInput then self:processChatInput(msg, peer) end
end

function GameServer:syncEntityCreation(entity, id)
	if entity.projectile then
		self:broadcastMessage({
			[0] = MSG.ProjectileFire,
			["tick"] = self._tick,
			["peerID"] = entity.source.owner.peerID,
			["entityID"] = id,
			["kind"] = entity.class.name,
			["x"] = entity.x,
			["y"] = entity.y,
			["vx"] = entity.vx,
			["vy"] = entity.vy,
		})
	else
		self:broadcastMessage({
			[0] = MSG.SyncEntityCreate,
			["tick"] = self._tick,
			["entityID"] = id,
			["kind"] = entity.class.name,
			["x"] = entity.x,
			["y"] = entity.y,
			["vx"] = entity.vx,
			["vy"] = entity.vy,
		})
	end
end

function GameServer:syncEntityRemoval(entity, id)
	self:broadcastMessage({
		[0] = MSG.SyncEntityRemove,
		["tick"] = self._tick,
		["entityID"] = id,
	})
end

function GameServer:sendLevelSnapshot()
	self:broadcastMessage({
		[0] = MSG.SyncTick,
		["tick"] = self._tick,
	})
	for destPeerID, destPeer in pairs(self.Peers) do
		destPeer.Courier:addMessage({
			[0] = MSG.SyncTickPredict,
			["tick"] = destPeer.tick,
		})
		for entityID, entity in pairs(self.Level.Entities) do
			if entity then
				--Units
				if entity.class.name == "Unit" then
					local peerID = entity.peerID
					local playerID = entity.playerID
					local peer = entity.peer
					local player = entity.player
					local x, y = player.unit:getPosition()
					local r = player.unit:getAngle()
					local vx, vy = player.unit:getLinearVelocity()
					local vr = player.unit:getAngularVelocity()
					if peerID == destPeerID then
						destPeer.Courier:addMessage({
							[0] = MSG.SyncEntityPredict,
							["entityID"] = entityID,
							["x"] = x,
							["y"] = y,
							["r"] = r,
							["vx"] = vx,
							["vy"] = vy,
							["vr"] = vr,
						})
					else
						destPeer.Courier:addMessage({
							[0] = MSG.SyncEntity,
							["entityID"] = entityID,
							["x"] = x,
							["y"] = y,
							["r"] = r,
							["vx"] = vx,
							["vy"] = vy,
							["vr"] = vr
						})
						if player.input then
							destPeer.Courier:addMessage({
								[0] = MSG.SendInput,
								["peerID"] = peerID,
								["playerID"] = playerID,
								["tick"] = self._tick,
								["aim"] = player.input.aim,
								["jump"] = player.input.jump,
								["left"] = player.input.left,
								["right"] = player.input.right,
								["down"] = player.input.down,
								["fire1"] = player.input.fire1,
								["fire2"] = player.input.fire2,
								["cancel"] = player.input.cancel
							})
						end
					end
				elseif entity.class.name == "Rocket" then
					local x, y = entity:getPosition()
					local r = entity:getAngle()
					local vx, vy = entity:getLinearVelocity()
					local vr = entity:getAngularVelocity()
					if entity.b2Body:isAwake() then
						if entity.source.owner.peerID == destPeerID then
							destPeer.Courier:addMessage({
								[0] = MSG.SyncEntity,
								["entityID"] = entityID,
								["x"] = x,
								["y"] = y,
								["r"] = r,
								["vx"] = vx,
								["vy"] = vy,
								["vr"] = vr,
							})
						else
							destPeer.Courier:addMessage({
								[0] = MSG.SyncEntityPredict,
								["entityID"] = entityID,
								["x"] = x,
								["y"] = y,
								["r"] = r,
								["vx"] = vx,
								["vy"] = vy,
								["vr"] = vr,
							})
						end
					end
				end
			end
		end
	end
end

function GameServer:processChatInput(msg, peer)
	local text, peerID = self:parseChatInput(peer, msg.text)
	self:broadcastMessage({
		[0] = MSG.ChatOutput,
		["peerID"] = peerID,
		["text"] = text,
	})
end

function GameServer:parseChatInput(peer, text)
	local peerID = peer.id
	local commands = {
		["name"] =
			function(peer, name)
				if name then
					text = "'" .. peer.name .. "' is now known as '" .. name .. "'"
					peerID = 0
					peer.name = name
					self.Server:broadcastPeerState(peer.id)
				end
			end,
	}
	if string.sub(text, 1, 1) == "/" then
		local commandString = string.sub(text, 2)
		local args = commandString:split(" ")
		for i = #args, 1, -1 do
			if #args[i] == 0 then table.remove(args, i) end
		end
		if commands[string.lower(args[1])] then
			commands[string.lower(args[1])](peer, unpack(args, 2))
		end
	end
	return text, peerID
end

function GameServer:update(dt)
	
end

function GameServer:draw()
	
end