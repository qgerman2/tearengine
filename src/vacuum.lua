Vacuum = class("Vaccum")

function Vacuum:initialize()
	self.Entities = {}

	self.accumulator = 10
	self.checked = 0
	self.checkedLimit = 30
end

function Vacuum:addEntity(entity)
	self.Entities[entity.id] = {object = entity, priority = 0, reset = false,
		flags = {
			["skip"] = false,
		}
	}
	return self.Entities[entity.id]
end

function Vacuum:removeEntity(entity)
	for i, entity in pairs(self.Entities) do
		if entity.object == entity then
			table.remove(self.Entities, i)
			break
		end
	end
end

function Vacuum:check(entityID)
	--flag
	if self.Entities[entityID].flags["skip"] then
		return true
	end
	--priority
	if self.checked < self.checkedLimit and self.Entities[entityID].priority > 100 then
		self.checked = self.checked + 1
		self.Entities[entityID].reset = true
		return true
	end
	return false
end

function Vacuum:update()
	self.checked = 0
	for _, entity in pairs(self.Entities) do
		if entity.reset then
			entity.priority = 0
			entity.reset = false
		else
			entity.priority = entity.priority + self.accumulator
		end
	end
end