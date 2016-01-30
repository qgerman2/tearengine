Level = class("Level")

function Level:initialize(game, mapFile)
	self.debug = false
	self.Game = game
	self.b2World = love.physics.newWorld(0, 9.81 * 128, true)
	self.b2World:setCallbacks(self.b2BeginContact, self.b2EndContact)
	self.Terrain = Terrain(self.b2World, mapFile, self.debug)

	self.Entities = {}

	self.TerrainDeformations = {}
end

function Level:addEntity(entity, id)
	if not id then
		entity.id = #self.Entities + 1
	else
		entity.id = id
	end
	entity.Level = self
	self.Entities[entity.id] = entity
	if server and entity.shared then
		self.Game:syncEntityCreation(entity, entity.id)
	end
	return entity.id
end

function Level:removeEntity(id)
	local entity = self.Entities[id]
	if not entity then return end
	if server and entity.shared then
		self.Game:syncEntityRemoval(entity, entity.id)
	end
	self.Entities[id]:destroy()
	self.Entities[id] = false
end

function Level:carveTerrain(x, y, radius)
	local explosion = {
		kind = "carve",
		x = x,
		y = y,
		radius = radius,
	}
	table.insert(self.TerrainDeformations, explosion)
	if server then
		local eMessage = {
			[0] = MSG.CarveTerrain,
			["tick"] = self.Game.ticks,
			["x"] = x,
			["y"] = y,
			["radius"] = radius,
		}
		self.Game:broadcastMessage(eMessage)
	end
end

function Level:parseTerrainDeformations()
	local modified = false
	for k, data in pairs(self.TerrainDeformations) do
		modified = true
		self.Terrain:carve(data.x, data.y, data.radius)
		self.TerrainDeformations[k] = nil
	end
	if modified then
		self.Terrain:buildImageChunks(self.Terrain.cImageChunkSize)
	end
end

function Level:b2BeginContact(fixtureB, contact)
	local fixtureA = self --bug?
	local ShapeA = fixtureA:getUserData()
	local ShapeB = fixtureB:getUserData()
	if type(ShapeA) == "table" and ShapeA.contacts then
		ShapeA.contacts[#ShapeA.contacts + 1] = {fixtureA, fixtureB, contact}
		ShapeA.entity:b2BeginContact(fixtureA, fixtureB, contact)
	end
	if type(ShapeB) == "table" and ShapeB.contacts then
		ShapeB.contacts[#ShapeB.contacts + 1] = {fixtureA, fixtureB, contact}
		ShapeB.entity:b2BeginContact(fixtureA, fixtureB, contact)
	end
end

function Level:b2EndContact(fixtureB, contact)
	local fixtureA = self
	local ShapeA = fixtureA:getUserData()
	local ShapeB = fixtureB:getUserData()
	if type(ShapeA) == "table" and ShapeA.contacts then
		for i, collision in ipairs(ShapeA.contacts) do
			if collision[3] == contact then
				table.remove(ShapeA.contacts, i)
				break
			end
		end
		ShapeA.entity:b2EndContact(fixtureA, fixtureB, contact)
	end
	if type(ShapeB) == "table" and ShapeB.contacts then
		for i, collision in ipairs(ShapeB.contacts) do
			if collision[3] == contact then
				table.remove(ShapeB.contacts, i)
				break
			end
		end
		ShapeB.entity:b2EndContact(fixtureA, fixtureB, contact)
	end
end

function Level:update(t)
	self.b2World:update(t)
	for i, entity in pairs(self.Entities) do
		if entity then
			entity:e_update(t)
			if entity.updateHealth then
				--what the hell?
				self.Game:broadcastMessage({
					[0] = MSG.UnitHealth,
					["entityID"] = entity.id,
					["health"] = entity.health,
				})
				entity.updateHealth = false
			end
		end
	end
	self:parseTerrainDeformations()
end

function Level:draw()
	if client then
		local x, y = self.Game.Camera.x, self.Game.Camera.y
		self.Terrain:draw(x, y)
		for _, entity in pairs(self.Entities) do
			if entity then
				entity:e_draw(self.debug)
			end
		end
	end
end