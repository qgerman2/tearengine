Input = class("Input")

function Input:initialize()
	self.inputMethod = {
		[1] = "m&k",
	}
	local joysticks = love.joystick.getJoysticks()
	for i, joystick in ipairs(joysticks) do
		if joystick:isGamepad() then
			print("ID: " .. i .. ", " .. joystick:getName() .. ", " .. tostring(joystick:isGamepad()))
			self.inputMethod[i + 1] = joystick
		end
	end
	self.actionSequence = {
		[1] = "aim",
		[2] = "jump",
		[3] = "left",
		[4] = "right",
		[5] = "down",
		[6] = "fire1",
		[7] = "fire2",
		[8] = "cancel",
	}

	self.gamepadBindings = {
		["dpleft"] = "left",
		["dpright"] = "right",
		["leftx"] = {"left", "right", deadzone = 0.4},
		["rightx"] = {"aim", deadzone = 0.15},
		["righty"] = {"aim", deadzone = 0.15},
		["leftshoulder"] = "jump",
		["rightshoulder"] = "cancel",
		["triggerleft"] = "fire2",
		["triggerright"] = "fire1",
	}

	self.keyboardBindings = {
		["w"]	= "jump",
		["s"]	= "down",
		["a"]	= "left",
		["d"]	= "right",
		[" "]	= "fire2",
	}

	self.mouseBindings = {
		[1]	= "fire1",
		["r"]	= "cancel",
	}

	self.inputState = {}
	for i = 1, 4 do
		self.inputState[i] = {
			aim 	= 0,
			jump 	= 0,
			down	= 0,
			left	= 0,
			right 	= 0,
			fire1	= 0,
			fire2	= 0,
			cancel	= 0,
		}
	end
end

function Input:snapshot(tick)
	local IS = {}
	for i = 1, #self.inputState do
		IS[i] = {
			[0] = MSG.SendInput,
			["peerID"] = client.id,
			["playerID"] = i,
			["tick"] = tick,
		}
		for ii = 1, #self.actionSequence do
			IS[i][self.actionSequence[ii]] = self.inputState[i][self.actionSequence[ii]]
		end
	end
	return IS
end

function Input:mousePressed(x, y, button)
	local action = self.mouseBindings[button]
	if action then
		for i, method in pairs(self.inputMethod) do
			if method == "m&k" then
				self.inputState[i][action] = 1
			end
		end
	end
end

function Input:mouseReleased(x, y, button)
	local action = self.mouseBindings[button]
	if action then
		for i, method in pairs(self.inputMethod) do
			if method == "m&k" then
				self.inputState[i][action] = 0
			end
		end
	end
end

function Input:keyPressed(key)
	local action = self.keyboardBindings[key]
	if action then
		for i, method in pairs(self.inputMethod) do
			if method == "m&k" then
				self.inputState[i][action] = 1
			end
		end
	end
end

function Input:keyReleased(key)
	local action = self.keyboardBindings[key]
	if action then
		for i, method in pairs(self.inputMethod) do
			if method == "m&k" then
				self.inputState[i][action] = 0
			end
		end
	end
end

function Input:gamepadPressed(joystick, button)
	if love.system.getOS() == "Android" then return end
	local action = self.gamepadBindings[button]
	if action then
		for i, method in pairs(self.inputMethod) do
			if method == joystick then
				self.inputState[i][action] = 1
			end
		end
	end
end

function Input:gamepadReleased(joystick, button)
	if love.system.getOS() == "Android" then return end
	local action = self.gamepadBindings[button]
	if action then
		for i, method in pairs(self.inputMethod) do
			if method == joystick then
				self.inputState[i][action] = 0
			end
		end
	end
end

function Input:gamepadAxis(joystick, axis, value)
	if love.system.getOS() == "Android" then return end
	local action = self.gamepadBindings[axis]
	if action then
		for i, method in pairs(self.inputMethod) do
			if method == joystick then
				if action[1] and action[2] then
					if math.abs(value) > action.deadzone then
						if value < 0 then
							self.inputState[i][action[1]] = value
							self.inputState[i][action[2]] = 0
						elseif value > 0 then
							self.inputState[i][action[1]] = 0
							self.inputState[i][action[2]] = value
						end
					else
						self.inputState[i][action[1]] = 0
						self.inputState[i][action[2]] = 0
					end
				elseif action[1] then
					if action[1] == "aim" then
						local xaxis = joystick:getGamepadAxis("rightx")
						local yaxis = joystick:getGamepadAxis("righty")
						local angle = utils.angle(0, 0, xaxis, yaxis)
						self.inputState[i]["aim"] = math.deg(angle)
					end
				else
					self.inputState[i][action] = value
				end
			end
		end
	end
end

function Input:update(game)
	local peer = game.localPeer; if not peer then return end
	local players = peer.Players
	local camera = game.Camera
	if players then
		for id, device in ipairs(self.inputMethod) do
			if players[id] then
				if device == "m&k" then
					if love.keyboard.isDown("lshift") then
						if self.inputState[id]["left"] ~= 0 then
							self.inputState[id]["left"] = 0.4
						elseif self.inputState[id]["right"] ~= 0 then
							self.inputState[id]["right"] = 0.4
						end
					else
						if self.inputState[id]["left"] ~= 0 then
							self.inputState[id]["left"] = 1
						elseif self.inputState[id]["right"] ~= 0 then
							self.inputState[id]["right"] = 1
						end
					end
					local x, y = players[id].unit.b2Body:getPosition()
					local px, py = camera:worldToScreen(x, y)
					local mx, my = 0, 0
					if love.system.getOS() == "Android" then
						local width, height = love.window.getDimensions()
						if love.touch.getTouchCount() > 0 then
							_, mx, my = love.touch.getTouch(1)
							mx, my = mx * width, my * height
						end
					else
						mx, my = love.mouse.getPosition()
					end
					self.inputState[id]["aim"] = utils.round(math.deg(utils.angle(px, py, mx, my)))
				end
			end
		end
	end
end

function Input:draw()

end