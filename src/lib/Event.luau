local Types = require(script.Parent.Types)

-- base event impl

local function Connection(tag: string?, event: Types.Event<any, ...any>, func): Types.Connection
	local conn = {}::Types.Connection
	conn.Tag = tag

	function conn:IsConnected()
		return event.Connections[self] ~= nil
	end

	function conn:Disconnect()
		event.Connections[self] = nil
	end

	table.freeze(conn)
	return conn
end

local function Signal<O, A...>(event: Types.Event<O, A...>): Types.Signal<O, A...>
	local signal = {}::Types.Signal<O, A...>
	
	function signal:Connect(tag, func: (Types.SenderParams<O>, A...) -> ())
		local sp = {}::Types.SenderParams<O>
		sp.Sender = event.Owner
		local conn = Connection(tag, event, func)
		sp.Connection = conn

		event.Connections[conn] = {
			f = func,
			sp = sp
		}
		return conn
	end

	table.freeze(signal)
	return signal
end

return function<O, A...>(sender: O): Types.Event<O, A...>
	local event = {} :: Types.Event<O, A...>
	event.Owner = sender
	event.Connections = {}
	event.Signal = Signal(event)
	
	function event:Fire(...: A...)
		for _, connData in self.Connections do
			task.defer(connData.f, connData.sp, ...)
		end
	end

	function event:DisconnectAll()
		table.clear(self.Connections)
	end

	table.freeze(event)
	return event
end