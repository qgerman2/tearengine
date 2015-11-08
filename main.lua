print(_VERSION)
print(jit.version .. "\n")

utf8 = require("utf8")
mp = require("lib.luajit-msgpack-pure")
class = require("lib.middleclass")
clipper = require("lib.clipper")
lzw = require("lib.lzw")
utils = require("lib.utils")
require("lib.msquares")
require("lib.rdp")

require("src.bridge")
require("src.courier")

require("src.server")
require("src.client")

require("src.game")
require("src.game_s")
require("src.game_c")
require("src.camera")
require("src.terrain")
require("src.chunk")
require("src.level")
require("src.input")
require("src.hud")
require("src.chatbox")

require("src.event_manager")
require("src.snapshot")
require("src.entity")
require("src.unit")
require("src.unit_animator")

require("src.weapon")
require("src.rocket")
require("src.bazooka")

function love.load()
	_version = "0.1"
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setBackgroundColor(50, 50, 50)
	love.graphics.setLineStyle("rough")
	love.keyboard.setKeyRepeat(true)
end

function love.gamepadpressed(joystick, button)
	if client then client:gamepadPressed(joystick, button) end
end

function love.gamepadreleased(joystick, button)
	if client then client:gamepadReleased(joystick, button) end
end

function love.mousepressed(x, y, button)
	if client then client:mousePressed(x, y, button) end
end

function love.mousereleased(x, y, button)
	if client then client:mouseReleased(x, y, button) end
end

function love.keypressed(key)
	if client then client:keyPressed(key) end
	if not server and not client then
		if key == "s" then
			server = Server("*:27015")
		elseif key == "c" then
			client = Client("190.164.93.46:27015")
		end
	elseif client then
		if key == "r" then
			client:toggleReady()
		end
	elseif server then
		if key == "q" then
			server:startGame()
		end
	end
	if key == "v" then
		local width, height, flags = love.window.getMode()
		love.window.setMode(width, height, {vsync = not flags.vsync})
	end
end

function love.keyreleased(key)
	if client then client:keyReleased(key) end
end

function love.textinput(t)
	if client then client:textInput(t) end
end

function love.update(dt)
	if client and client.Game then client.Game.InputHandler:update(client.Game) end
	if client then client:update(dt) end
	if server then server:update(dt) end
end

function love.draw()
	if game then game:g_draw() end
	if client then client:draw() end
end