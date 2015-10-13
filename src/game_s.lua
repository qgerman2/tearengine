GameServer = class("GameServer", Game)

function GameServer:initialize(mapFile, Peers)
	Game.initialize(self, mapFile, 0)
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
				player.tick = tonumber(player.inputBuffer[1].tick)
				peer.tick = tonumber(player.inputBuffer[1].tick)
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
	local player = peer.Players[tonumber(msg.playerID)]
	local tick = tonumber(msg.tick)
	if tick <= player.tick then return end
	for k, v in pairs(player.inputBuffer) do
		if tonumber(v.tick) == tick then
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
		table.remove(player.inputBuffer, 1)
	end
end

function GameServer:processMessage(msg, peer)
	if msg.type == MSG.SendInput then self:processInput(msg, peer) end
end

function GameServer:syncEntityCreation(entity, id)
	self:broadcastMessage({
		[0] = MSG.SyncEntityCreate,
		[1] = self._tick,
		[2] = id,
		[3] = entity.kind,
		[4] = entity.x,
		[5] = entity.y,
		[6] = entity.b2World and "1" or "0",
	})
end

function GameServer:syncEntityRemoval(entity, id)
	self:broadcastMessage({
		[0] = MSG.SyncEntityRemove,
		[1] = self._tick,
		[2] = id,
	})
end

function GameServer:sendLevelSnapshot()
	self:broadcastMessage({
		[0] = MSG.SyncTick,
		[1] = self._tick,
	})
	for destPeerID, destPeer in pairs(self.Peers) do
		destPeer.Courier:addMessage({
			[0] = MSG.SyncTickPredict,
			[1] = destPeer.tick,
		})
		for entityID, entity in pairs(self.Level.Entities) do
			if entity then
				--Units
				if entity.kind == "Unit" then
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
							[1] = entityID,
							[2] = x,
							[3] = y,
							[4] = r,
							[5] = vx,
							[6] = vy,
							[7] = vr,
						})
					else
						destPeer.Courier:addMessage({
							[0] = MSG.SyncEntity,
							[1] = entityID,
							[2] = self._tick,
							[3] = x,
							[4] = y,
							[5] = r,
							[6] = vx,
							[7] = vy,
							[8] = vr
						})
						if player.input then
							destPeer.Courier:addMessage({
								[0] = MSG.SendInput,
								[1] = peerID,
								[2] = playerID,
								[3] = self._tick,
								[4] = player.input.aim,
								[5] = player.input.jump,
								[6] = player.input.left,
								[7] = player.input.right,
								[8] = player.input.down,
								[9] = player.input.fire1,
								[10] = player.input.fire2,
								[11] = player.input.cancel
							})
						end
					end
				elseif entity.kind == "Box" then
					if entity.b2Body:isAwake() then
						local x, y = entity:getPosition()
						local r = entity:getAngle()
						local vx, vy = entity:getLinearVelocity()
						local vr = entity:getAngularVelocity()
						destPeer.Courier:addMessage({
							[0] = MSG.SyncEntityPredict,
							[1] = entityID,
							--[2] = self._tick,
							[2] = x,
							[3] = y,
							[4] = r,
							[5] = vx,
							[6] = vy,
							[7] = vr,
						})
					end
				end
			end
		end
	end
end

function GameServer:update(dt)
	
end

function GameServer:draw()
	
end