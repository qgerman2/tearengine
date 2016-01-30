require("enet")

print("Bridge: Initialized")
local CommandChannel = love.thread.getChannel("command")
local EventChannel = love.thread.getChannel("event")

local Host = false
local Server = false

while true do
	local command = CommandChannel:pop()
	if command then
		if command.type == "client" then
			Host = enet.host_create(nil, 16, 2)
			Host:compress_with_range_coder()
			Server = Host:connect(command.data, 3)
			print("Bridge: Client")
		elseif command.type == "server" then
			Host = enet.host_create(command.data, 16, 2)
			Host:compress_with_range_coder()
			if command.listen then
				print("Bridge: Listen Server")
			else
				print("Bridge: Dedicated Server")
			end
		elseif command.type == "send" then
			local Peer = Server or false
			if command.peer then
				Peer = Host:get_peer(command.peer)
			end
			if Peer then
				Peer:send(command.data, command.channel, command.flag)
			end
		elseif command.type == "broadcast" then
			Host:broadcast(command.data, command.channel, command.flag)
		elseif command.type == "kill" then
			break
		end
	end
	if Host then
		local event = Host:service(1)
		if event then
			local t = {
				channel = event.channel,
				type = event.type,
				data = event.data,
				peer = event.peer:index(),
				time = os.clock(),
			}
			EventChannel:push(t)
		end
	end
end