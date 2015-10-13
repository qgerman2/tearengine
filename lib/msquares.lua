marchingSquares = class("marchingSquares")

function marchingSquares:initialize(raw, startX, startY)
	self.raw = raw
	self.removal = {}
	self.points = {}
	if startX and startY then
		local pX, pY = startX, startY
		local stepX, stepY
		local prevX, prevY
		local closedLoop = false
		while not closedLoop do
			local squareValue = self:getSquareValue(pX, pY)
			if			squareValue == 1 or
						squareValue == 5 or
						squareValue == 13 then
							stepX = 0
							stepY = -1
			elseif	squareValue == 8 or
						squareValue == 10 or
						squareValue == 11 then
							stepX = 0
							stepY = 1
			elseif	squareValue == 4 or
						squareValue == 12 or
						squareValue ==  14 then
							stepX = -1
							stepY = 0
			elseif	squareValue == 2 or
						squareValue == 3 or
						squareValue == 7 then
							stepX = 1
							stepY = 0
			elseif	squareValue == 6 then
							if prevX == 0 and prevY == 1 then
								stepX = -1
								stepY = 0
							else
								stepX = 1
								stepY = 0
							end
			elseif squareValue == 9 then
							if prevX == -1 and prevY == 0 then
								stepX = 0
								stepY = -1
							else
								stepX = 0
								stepY = 1
							end
			end
			if squareValue == 0 or squareValue == 15 then
				print("ohshitdawg", squareValue)
				return false
			end
			pX = pX + stepX
			pY = pY + stepY
			prevX = stepX
			prevY = stepY
			table.insert(self.points, {x = pX, y = pY})
			if (pX == startX and pY == startY) then
				closedLoop = true
			end
		end
	end
end

function marchingSquares:checkPixel(imageData, x, y)
	if x < 0 or y < 0 or x > imageData:getWidth() - 1 or y > imageData:getHeight() - 1 then return false end
	local _, _, _, a = imageData:getPixel(x, y)
	if a ~= 0 then
		return true
	end
	return false
end

function marchingSquares:getSquareValue(x, y)
	local squareValue = 0
	if self:checkPixel(self.raw, x - 1, y - 1) then
		squareValue = squareValue + 1
		if not self.removal[x - 1] then self.removal[x - 1] = {} end
		self.removal[x - 1][y - 1] = true
	end
	if self:checkPixel(self.raw, x, y - 1) then
		squareValue = squareValue + 2
		if not self.removal[x] then self.removal[x] = {} end
		self.removal[x][y - 1] = true
	end
	if self:checkPixel(self.raw, x - 1, y) then
		squareValue = squareValue + 4
		if not self.removal[x - 1] then self.removal[x - 1] = {} end
		self.removal[x - 1][y] = true
	end
	if self:checkPixel(self.raw, x, y) then
		squareValue = squareValue + 8
		if not self.removal[x] then self.removal[x] = {} end
		self.removal[x][y] = true
	end
	return squareValue
end