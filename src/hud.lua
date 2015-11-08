HUD = class("HUD")

function HUD:initialize(game)
	self.GameClient = game
	self.colors = {
		[0] = {r = 255, g = 255, b = 255},
		[1] = {r = 255, g = 255, b = 0},
		[2] = {r = 255, g = 0, b = 0},
		[3] = {r = 0, g = 255, b = 0},
	}
	self.font = love.graphics.newFont("rsc/munro_small.ttf", 10)
	self.Chatbox = Chatbox(game, self.font)
	love.graphics.setFont(self.font)
end

function HUD:update(dt)
	self.Chatbox:update(dt)
end

function HUD:draw()
	local clientPeerID = self.GameClient._peerID
	local Camera = self.GameClient.Camera
	for peerID, peer in pairs(self.GameClient.Peers) do
		for playerID, player in pairs(peer.Players) do
			local x, y = Camera:worldToScreen(player.unit:getPosition())
			local color = self.colors[peerID]
			if not color then color = self.colors[0] end
			love.graphics.printf(peer.name, x - 100, y - 35, 200, "center")
			love.graphics.setColor(color.r, color.g, color.b)
			love.graphics.printf(player.unit.health, x - 50, y - 28, 100, "center")
			love.graphics.setColor(255, 255, 255)
		end
	end
	self.Chatbox:draw()
end