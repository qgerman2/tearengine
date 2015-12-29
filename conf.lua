function love.conf(t)
	t.identity = "TearEngine"
	t.version = "0.10.0"
	t.console = true

	t.window.title = "Tear Engine Pre-Alpha"
	t.window.vsync = false

	t.modules.audio = true
	t.modules.event = true
	t.modules.graphics = true
	t.modules.image = true
	t.modules.joystick = true
	t.modules.keyboard = true
	t.modules.math = true
	t.modules.mouse = true
	t.modules.physics = true
	t.modules.sound = true
	t.modules.system = true
	t.modules.timer = true
	t.modules.window = true
	t.modules.thread = true
end