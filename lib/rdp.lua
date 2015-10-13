function RDPAlgorithm(points, epsilon)
	local firstPoint = points[1]
	local lastPoint = points[#points]
	if #points < 3 then
		return points
	end
	local index = -1
	local dist = 0
	for i = 1, #points do
		local cDist = findPerpendicularDistance(points[i], firstPoint, lastPoint)
		if cDist > dist then
			dist = cDist
			index = i
		end
	end
	if dist > epsilon then
		local l1 = table_slice(points, 1, index)
		local l2 = table_slice(points, index)
		local r1 = RDPAlgorithm(l1, epsilon)
		local r2 = RDPAlgorithm(l2, epsilon)
		local rs = array_concat(table_slice(r1, 1, #r1 - 1), r2)
		return rs
	else
		return {firstPoint, lastPoint}
	end
end

function findPerpendicularDistance(p, p1, p2)
	local result
	local slope
	local intercept
	if p1.x == p2.x then
		result = math.abs(p.x - p1.x)
	else
		slope = (p2.y - p1. y) / (p2.x - p1.x)
		intercept = p1.y - (slope * p1.x)
		result = math.abs(slope * p.x - p.y + intercept) / math.sqrt(math.pow(slope, 2) + 1)
	end
	return result
end