Snapshot = class("Snapshot")

function Snapshot:initialize(level)
	self.tick = level.Game._tick
	self.Entities = {}
	for id, entity in pairs(level.Entities) do
		if entity then
			local x, y = entity.b2Body:getPosition()
			local r = entity.b2Body:getAngle()
			local vx, vy = entity.b2Body:getLinearVelocity()
			local vr = entity.b2Body:getAngularVelocity()
			self.Entities[id] = {
				kind = entity.class.name,
				x = x,
				y = y,
				r = r,
				vx = vx,
				vy = vy,
				vr = vr,
			}
			if entity.class.name == "Unit" then
				self.Entities[id].input = {}
				for action, state in pairs(entity.input) do
					self.Entities[id].input[action] = state
				end
			end
		end
	end
end

function Snapshot:apply(level)
	for i, ent in pairs(self.Entities) do
		local entity = level.Entities[i]
		if entity then
			if ent.x and ent.y then
				entity.b2Body:setPosition(ent.x, ent.y)
				entity.b2Body:setAngle(ent.r)
				entity.b2Body:setLinearVelocity(ent.vx, ent.vy)
				entity.b2Body:setAngularVelocity(ent.vr)
			end
			if entity.class.name == "Unit" then
				for action, state in pairs(ent.input) do
					entity.input[action] = state
				end
			end
		end
	end
end

function Snapshot:clearSpatialData(entityID)
	local entity = self.Entities[entityID]
	if not entity then return false end
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