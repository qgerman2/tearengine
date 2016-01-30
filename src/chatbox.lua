Chatbox = class("Chatbox")

function Chatbox:initialize(GameClient, font)
	self.GameClient = GameClient
	self.font = font
	self.focus = false
	self.x = 10
	self.y = 10
	self.width = 300
	self.height = 120
	self.lines = 6
	self.canvas = love.graphics.newCanvas(self.width, self.height)
	self.buffer = {
		[1] = "Press 't' to chat!",
		[2] = "Use /name to change your name.",
	}
	self.input = ""
	self.charlimit = 48
	self.timer = 0
	self.cursor = true
end

function Chatbox:addEntry(text)
	self.buffer[#self.buffer + 1] = text
end

function Chatbox:keyPressed(key)
	if key == "return" then
		self:sendInput()
		self.input = ""
	elseif key == "backspace" then
		local byteoffset = utf8.offset(self.input, -1)
		if byteoffset then
			self.input = string.sub(self.input, 1, byteoffset - 1)
        end
        self.cursor = true
		self.timer = 0
	end
end

function Chatbox:textInput(t)
	self.input = self.input .. t
	self.cursor = true
	self.timer = 0
end

function Chatbox:sendInput()
	if #self.input > 0 then
		local courier = self.GameClient.Courier
		courier:addMessage({
			[0] = MSG.ChatInput,
			["text"] = self.input,
		})
	end
end

function Chatbox:update(dt)
	if not self.focus then
		self.timer = 0
		self.cursor = true
	else
		self.timer = self.timer + dt
		if self.timer > 1 then
			self.timer = self.timer - 1
			self.cursor = not self.cursor
		end
	end
end

function Chatbox:draw()
	--box
	love.graphics.setColor(0, 0, 0, 160)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	love.graphics.rectangle("line", self.x, self.y + self.height - 12, self.width, 12)
	--text
	love.graphics.setCanvas(self.canvas)
	love.graphics.clear()
	local _, lines = self.font:getWrap(table.concat(self.buffer, "\n"), self.width)
	if #lines > self.lines then
		love.graphics.translate(0, -self.font:getHeight() * (#lines - self.lines))
	end
	love.graphics.printf(table.concat(self.buffer, "\n"), 2, 0, self.width - 4, "left")
	love.graphics.origin()
	if self.font:getWidth(self.input .. "|") > self.width then
		love.graphics.translate(-self.font:getWidth(self.input .. "|") + self.width - 2, 0)
	end
	love.graphics.print(self.input .. (self.focus and self.cursor and "|" or ""), 2, self.height - 13)
	love.graphics.origin()
	love.graphics.setCanvas()
	love.graphics.draw(self.canvas, self.x, self.y)
end