Bridge = class("Bridge")

function Bridge:initialize()
	self.CommandChannel = love.thread.getChannel("command")
	self.EventChannel = love.thread.getChannel("event")
	self.Thread = love.thread.newThread("src/bridge_thread.lua")
	self.Thread:start()
end

function Bridge:Send(data, channel, flag, peer)
	local command = {
		type = "send",
		data = data,
		channel = channel,
		flag = flag,
		peer = peer,
	}
	self.CommandChannel:push(command)
end

function Bridge:Broadcast(data, channel, flag)
	local command = {
		type = "broadcast",
		data = data,
		channel = channel,
		flag = flag,
	}
	self.CommandChannel:push(command)
end

function Bridge:Client(server)
	local command = {
		type = "client",
		data = server,
	}
	self.CommandChannel:push(command)
end

function Bridge:Server(port, listen)
	local command = {
		type = "server",
		data = port,
		listen = listen or false,
	}
	self.CommandChannel:push(command)
end

function Bridge:CheckEvents()
	local events = {}
	for i = 1, self.EventChannel:getCount() do
		local event = self.EventChannel:pop()
		table.insert(events, event)
	end
	if #events > 0 then
		return events
	end
	return nil
end