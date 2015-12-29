Terrain = class("Terrain")

function Terrain:initialize(b2World, mapFile, debug)
	self.debug = debug
	self.rImage = love.image.newImageData(mapFile)
	self.cImage = love.graphics.newImage(self.rImage)

	self.b2World = b2World
	self.b2Body = love.physics.newBody(b2World, 0, 0)
	self.chunks = self:buildChunks(32)
end

function Terrain:buildChunks(size)
	local xChunks = math.ceil(self.rImage:getWidth() / size)
	local yChunks = math.ceil(self.rImage:getHeight() / size)
	local chunks = {}
	for x = 0, xChunks - 1 do
		for y = 0, yChunks - 1 do
			local tempImage = love.image.newImageData(size + 2, size + 2)
			tempImage:paste(self.rImage, 1, 1, x * size, y * size, size, size)
			local points = self:getImageContour(tempImage)
			if points and #points >= 6 then
				local newPoints = self:offsetPoints(points, (size * x) - 1, (size * y) - 1)
				local chunk = Chunk(newPoints, self.b2Body, (size * x) - 1 + size / 2, (size * y) - 1 + size / 2)
				table.insert(chunks, chunk)
			end
		end
	end
	return chunks
end

function Terrain:getImageContour(image)
	for x = 0, image:getWidth() - 1 do
		for y = 0, image:getHeight() - 1 do
			if self:checkArea(image, x - 1, y - 1, 2, 2) == "half" then
				local msquares = marchingSquares(image, x, y)
				local points = RDPAlgorithm(msquares.points, 1.2)
				local rawPoints = {}
				for i = 1, #points do
					table.insert(rawPoints, points[i].x)
					table.insert(rawPoints, points[i].y)
				end
				return rawPoints
			end
		end
	end
	return false
end

function Terrain:carve(x, y, radius)
	for mx = x - radius, x + radius do
		for my = y - radius, y + radius do
			if utils.dist(x, y, mx, my) < radius then
				self.rImage:setPixel(mx, my, 0, 0, 0, 0)
			end
		end
	end
	local circlePolygon = self:circlePolygon(x, y, radius, 16)
	local newPolygons = {}
	for ii, v in ripairs(self.chunks) do
		if utils.dist(x, y, v.x, v.y) < radius + 20 then
			local cl = clipper.new()
			cl:add_subject(v.clObject)
			cl:add_clip(circlePolygon)
			local result = cl:execute("difference")
			if result:size() >= 1 then
				for i = 1, result:size() do
					table.insert(newPolygons, {poly = result:get(i), x = v.x, y = v.y})
				end
				v:destroy()
				table.remove(self.chunks, ii)
			else
				for i = 1, v.clObject:size() do
					if utils.dist(tonumber(v.clObject:get(i).x), tonumber(v.clObject:get(i).y), x, y) < radius then
						v:destroy()
						table.remove(self.chunks, ii)
						break
					end
				end
			end
		end
	end
	for _, v in ipairs(newPolygons) do
		local vertices = {}
		for i = 1, v.poly:size() do
			vertices[#vertices + 1] = tonumber(v.poly:get(i).x)
			vertices[#vertices + 1] = tonumber(v.poly:get(i).y)
		end
		local chunk = Chunk(vertices, self.b2Body, v.x, v.y)
		table.insert(self.chunks, chunk)
	end
end

function Terrain:rebuildImage()
	self.cImage = love.graphics.newImage(self.rImage)
end

function Terrain:circlePolygon(x, y, radius, precision)
	local poly = clipper.polygon()
	local angle = 2 * math.pi / precision
	for i = 1, precision do
		poly:add(x + radius * math.cos(angle * i), y + radius * math.sin(angle * i))
	end
	poly:simplify("even_odd")
	return poly
end

function Terrain:checkPixel(imageData, x, y)
	--duct tape tier solution
	if type(imageData) == "number" then
		y = x
		x = imageData
		imageData = self.rImage
	end
	if x < 0 or y < 0 or x > imageData:getWidth() - 1 or y > imageData:getHeight() - 1 then return false end
	local _, _, _, a = imageData:getPixel(x, y)
	if a ~= 0 then
		return true
	end
	return false
end

function Terrain:offsetPoints(points, xoffset, yoffset)
	local newPoints = {}
	for i = 1, #points, 2 do
		newPoints[i] = points[i] + xoffset
		newPoints[i + 1] = points[i + 1] + yoffset
	end
	return newPoints
end


function Terrain:checkArea(imageData, x, y, width, height)
	local area = width * height
	local pixels = 0
	for x = x, x + width - 1 do
		for y = y, y + height - 1 do
			if self:checkPixel(imageData, x, y) then
				pixels = pixels + 1
			end
		end
	end
	if pixels == 0 then
		return "empty"
	elseif pixels < area then
		return "half"
	elseif pixels == area then
		return "full"
	end
end

function Terrain:draw()
	love.graphics.draw(self.cImage, 0, 0)
	if self.debug then
		local r, g, b, a = love.graphics.getColor()
		for _, chunk in pairs(self.chunks) do
			chunk:draw()
		end
		love.graphics.setColor(r, g, b, a)
	end
end