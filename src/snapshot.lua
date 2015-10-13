Snapshot = class("Snapshot")

function Snapshot:initialize(level)
	self.tick = level.Game._tick
	self.Entities = {}
	for id, entity in pairs(level.Entities) do
		if entity then
			local x, y = entity:getPosition()
			local r = entity:getAngle()
			local vx, vy = entity:getLinearVelocity()
			local vr = entity:getAngularVelocity()
			self.Entities[id] = {
				kind = entity.kind,
				x = x,
				y = y,
				r = r,
				vx = vx,
				vy = vy,
				vr = vr,
			}
			if entity.kind == "Unit" then
				self.Entities[id].input = {}
				for action, state in pairs(entity.input) do
					self.Entities[id].input[action] = state
				end
			end
		end
	end
end

function Snapshot:apply(level)
	--remove unnecessary entities
	for i, ent in pairs(level.Entities) do
		if ent then
			if not self.Entities[i] then
				level:removeEntity(i)
			end
		end
	end
	--apply changes
	for i, ent in pairs(self.Entities) do
		local entity = level.Entities[i]
		if not entity then
			entity = _G[ent.kind](ent.x, ent.y, level.b2World)
			level:addEntity(entity, i)
		end
		if ent.x and ent.y then
			entity:setPosition(ent.x, ent.y)
			entity:setAngle(ent.r)
			entity:setLinearVelocity(ent.vx, ent.vy)
			entity:setAngularVelocity(ent.vr)
		end
		if entity.kind == "Unit" then
			for action, state in pairs(ent.input) do
				entity.input[action] = state
			end
		end
	end
end

function Snapshot:clearSpatialData(entityID)
	local entity = self.Entities[entityID]
	entity.x, entity.y, entity.r, entity.vx, entity.vy, entity.vr = nil, nil, nil, nil, nil, nil
end

function Snapshot:setSyncError(entityID, x, y, r, t, s)
	self.Entities[entityID].syncError = {
		x = x,
		y = y,
		r = r,
		t = t,
		s = s,
	}
end

function Snapshot:overwriteEntity(entityData)
	local ignore = {["entityID"] = true, ["tick"] = true, ["type"] = true}
	local entity = self.Entities[entityData.entityID]
	for k, v in pairs(entityData) do
		if not ignore[k] then
			entity[k] = v
		end
	end
end